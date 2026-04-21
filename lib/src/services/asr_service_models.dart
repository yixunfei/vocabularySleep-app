part of 'asr_service.dart';

extension AsrServiceModels on AsrService {
  Future<void> _downloadAndExtractModel({
    required _OfflineModelProfile profile,
    required Directory modelsRoot,
    AsrProgressCallback? onProgress,
  }) async {
    await modelsRoot.create(recursive: true);
    final archivePath = p.join(
      modelsRoot.path,
      '${profile.dirName}.download.tar.bz2',
    );
    final archiveFile = File(archivePath);
    final stagingDir = Directory(
      p.join(modelsRoot.path, '${profile.dirName}.tmp'),
    );
    final modelDir = Directory(p.join(modelsRoot.path, profile.dirName));

    try {
      await _safeDeleteDirectory(stagingDir);

      bool downloaded = false;
      try {
        downloaded = await _downloadFromS3(
          remoteKey: profile.remoteKey,
          destination: archiveFile,
          onProgress: onProgress,
        );
      } catch (_) {
        // S3 download failed, will try GitHub fallback below
      }

      if (!downloaded) {
        await _downloadFile(
          sourceUrl: profile.archiveUrl,
          destination: archiveFile,
          onProgress: onProgress,
        );
      }

      _checkCanceled();
      await _extractArchive(
        archiveFile: archiveFile,
        outputDir: stagingDir,
        onProgress: onProgress,
      );
      _checkCanceled();

      final nested = Directory(p.join(stagingDir.path, profile.dirName));
      final extractedModelDir = nested.existsSync() ? nested : stagingDir;
      if (!_hasModelFiles(profile, extractedModelDir)) {
        throw StateError('asrModelExtractionIncomplete');
      }

      await _safeDeleteDirectory(modelDir);
      await extractedModelDir.rename(modelDir.path);
      if (nested.existsSync()) {
        await _safeDeleteDirectory(stagingDir);
      }
    } finally {
      if (await archiveFile.exists()) {
        await archiveFile.delete();
      }
      if (await stagingDir.exists()) {
        await _safeDeleteDirectory(stagingDir);
      }
    }
  }

  Future<bool> _downloadFromS3({
    required String remoteKey,
    required File destination,
    AsrProgressCallback? onProgress,
  }) async {
    onProgress?.call(
      const AsrProgress(
        stage: 'download',
        messageKey: 'asrProgressDownloading',
        progress: 0,
      ),
    );

    try {
      final file = await _cacheService.ensureFileDownloaded(
        remoteKey,
        cacheRelativePath: remoteKey,
        onProgress: onProgress != null
            ? (progress) {
                onProgress(
                  AsrProgress(
                    stage: 'download',
                    messageKey: 'asrProgressDownloading',
                    progress: progress.progress,
                  ),
                );
              }
            : null,
      );

      await file.copy(destination.path);
      onProgress?.call(
        const AsrProgress(
          stage: 'download',
          messageKey: 'asrProgressDownloadDone',
          progress: 1,
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _downloadFile({
    required String sourceUrl,
    required File destination,
    AsrProgressCallback? onProgress,
  }) async {
    onProgress?.call(
      const AsrProgress(
        stage: 'download',
        messageKey: 'asrProgressDownloading',
        progress: 0,
      ),
    );

    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(sourceUrl));
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('asrDownloadFailedHttp:${response.statusCode}');
      }

      await destination.parent.create(recursive: true);
      final sink = destination.openWrite();
      try {
        var received = 0;
        final total = response.contentLength;
        await for (final chunk in response) {
          _checkCanceled();
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) {
            onProgress?.call(
              AsrProgress(
                stage: 'download',
                messageKey: 'asrProgressDownloading',
                progress: received / total,
              ),
            );
          }
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      onProgress?.call(
        const AsrProgress(
          stage: 'download',
          messageKey: 'asrProgressDownloadDone',
          progress: 1,
        ),
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _extractArchive({
    required File archiveFile,
    required Directory outputDir,
    AsrProgressCallback? onProgress,
  }) async {
    onProgress?.call(
      const AsrProgress(
        stage: 'extract',
        messageKey: 'asrProgressExtracting',
        progress: 0,
      ),
    );

    final compressed = await archiveFile.readAsBytes();
    _checkCanceled();
    final tarBytes = BZip2Decoder().decodeBytes(compressed);
    _checkCanceled();
    final archive = TarDecoder().decodeBytes(tarBytes);

    var processed = 0;
    final total = archive.isEmpty ? 1 : archive.length;
    for (final file in archive.files) {
      _checkCanceled();
      final relativePath = _safeRelativePath(file.name);
      if (relativePath == null) {
        processed += 1;
        continue;
      }

      final outputPath = p.join(outputDir.path, relativePath);
      if (file.isFile) {
        final bytes = _archiveContentToBytes(file.content);
        final outputFile = File(outputPath);
        await outputFile.parent.create(recursive: true);
        await outputFile.writeAsBytes(bytes, flush: true);
      } else {
        await Directory(outputPath).create(recursive: true);
      }

      processed += 1;
      onProgress?.call(
        AsrProgress(
          stage: 'extract',
          messageKey: 'asrProgressExtracting',
          progress: processed / total,
        ),
      );
    }

    onProgress?.call(
      const AsrProgress(
        stage: 'extract',
        messageKey: 'asrProgressExtractDone',
        progress: 1,
      ),
    );
  }

  Future<Directory> _ensureModelsRoot() async {
    final supportDir = await getApplicationSupportDirectory();
    final root = Directory(p.join(supportDir.path, 'asr-models'));
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    return root;
  }

  Future<Directory> _ensureScoringPacksRoot() async {
    final supportDir = await getApplicationSupportDirectory();
    final root = Directory(p.join(supportDir.path, 'asr-scoring-packs'));
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    return root;
  }

  Future<Map<String, Object?>> _loadModelManifest(Directory modelsRoot) async {
    final file = File(p.join(modelsRoot.path, AsrService._manifestName));
    if (!await file.exists()) return <String, Object?>{};

    try {
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is Map) {
        return decoded.cast<String, Object?>();
      }
    } catch (_) {
      // Ignore malformed manifest and rebuild it on next write.
    }
    return <String, Object?>{};
  }

  Future<void> _saveModelManifest(
    Directory modelsRoot,
    Map<String, Object?> manifest,
  ) async {
    final file = File(p.join(modelsRoot.path, AsrService._manifestName));
    await file.writeAsString(jsonEncode(manifest), flush: true);
  }

  bool _shouldRefreshModelCache({
    required _OfflineModelProfile profile,
    Object? manifestEntry,
  }) {
    if (manifestEntry is! Map) return false;
    final entry = manifestEntry.cast<String, Object?>();
    final version = (entry['version'] as num?)?.toInt() ?? 0;
    final archiveUrl = entry['archiveUrl']?.toString() ?? '';
    if (version != AsrService._modelCacheVersion) return true;
    if (archiveUrl != profile.archiveUrl) return true;
    return false;
  }

  Future<void> _updateModelManifest(
    Directory modelsRoot,
    _OfflineModelProfile profile,
    Map<String, Object?> fileMetadata,
  ) async {
    final manifest = await _loadModelManifest(modelsRoot);
    manifest['manifestVersion'] = AsrService._modelCacheVersion;
    manifest[profile.variant] = <String, Object?>{
      'version': AsrService._modelCacheVersion,
      'modelVersion': AsrService._modelCacheVersion,
      'archiveUrl': profile.archiveUrl,
      'dirName': profile.dirName,
      'encoderFile': profile.encoderFile,
      'decoderFile': profile.decoderFile,
      'tokensFile': profile.tokensFile,
      'files': fileMetadata,
      'verifiedAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await _saveModelManifest(modelsRoot, manifest);
  }

  Future<Map<String, Object?>> _collectModelFileMetadata(
    _OfflineModelProfile profile,
    Directory modelDir,
  ) async {
    final result = <String, Object?>{};
    for (final filename in _requiredModelFiles(profile)) {
      final file = File(p.join(modelDir.path, filename));
      if (!await file.exists()) continue;
      final stat = await file.stat();
      final hash = await _sha256OfFile(file);
      result[filename] = <String, Object?>{
        'size': stat.size,
        'modifiedMs': stat.modified.millisecondsSinceEpoch,
        'sha256': hash,
      };
    }
    return result;
  }

  Future<bool> _validateModelIntegrity({
    required _OfflineModelProfile profile,
    required Directory modelDir,
    required Object? manifestEntry,
  }) async {
    if (!_hasModelFiles(profile, modelDir)) return false;
    if (manifestEntry is! Map) return true;

    final entry = manifestEntry.cast<String, Object?>();
    final filesMetaRaw = entry['files'];
    if (filesMetaRaw is! Map) return true;
    final filesMeta = filesMetaRaw.cast<String, Object?>();
    for (final fileName in _requiredModelFiles(profile)) {
      final metaRaw = filesMeta[fileName];
      if (metaRaw is! Map) return false;
      final meta = metaRaw.cast<String, Object?>();
      final expectedSize = (meta['size'] as num?)?.toInt();
      final expectedHash = meta['sha256']?.toString() ?? '';
      if (expectedSize == null || expectedSize <= 0 || expectedHash.isEmpty) {
        return false;
      }

      final file = File(p.join(modelDir.path, fileName));
      if (!await file.exists()) return false;
      final stat = await file.stat();
      if (stat.size != expectedSize) return false;
      final actualHash = await _sha256OfFile(file);
      if (actualHash != expectedHash) return false;
    }
    return true;
  }

  Future<void> _pruneTemporaryArtifacts(Directory modelsRoot) async {
    await for (final entity in modelsRoot.list()) {
      final name = p.basename(entity.path);
      if (entity is Directory && name.endsWith('.tmp')) {
        await _safeDeleteDirectory(entity);
      } else if (entity is File && name.endsWith('.download.tar.bz2')) {
        await entity.delete();
      }
    }
  }

  Future<void> _pruneUnknownModelDirs(Directory modelsRoot) async {
    final expectedDirs = AsrService._offlineProfiles.values
        .map((profile) => profile.dirName)
        .toSet();
    await for (final entity in modelsRoot.list()) {
      if (entity is! Directory) continue;
      final name = p.basename(entity.path);
      if (!name.startsWith('sherpa-onnx-whisper-')) continue;
      if (expectedDirs.contains(name)) continue;
      await _safeDeleteDirectory(entity);
    }
  }

  Future<void> _safeDeleteDirectory(Directory dir) async {
    if (!await dir.exists()) return;
    await dir.delete(recursive: true);
  }

  Future<int> _directorySize(Directory dir) async {
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final stat = await entity.stat();
      total += stat.size;
    }
    return total;
  }

  List<String> _requiredModelFiles(_OfflineModelProfile profile) => <String>[
    profile.encoderFile,
    profile.decoderFile,
    profile.tokensFile,
  ];

  bool _hasModelFiles(_OfflineModelProfile profile, Directory modelDir) {
    if (!modelDir.existsSync()) return false;
    for (final filename in _requiredModelFiles(profile)) {
      final file = File(p.join(modelDir.path, filename));
      if (!file.existsSync()) return false;
    }
    return true;
  }

  Future<String> _sha256OfFile(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  String? _safeRelativePath(String rawPath) {
    final normalized = p.normalize(rawPath.replaceAll('\\', '/'));
    if (normalized.isEmpty || normalized == '.') return null;
    if (p.isAbsolute(normalized)) return null;
    if (normalized == '..' ||
        normalized.startsWith('../') ||
        normalized.startsWith('..\\')) {
      return null;
    }
    return normalized;
  }

  List<int> _archiveContentToBytes(dynamic content) {
    if (content is Uint8List) return content;
    if (content is List<int>) return content;
    if (content is String) return utf8.encode(content);
    return <int>[];
  }

  void _checkCanceled() {
    if (_stopRequested) {
      throw const _CanceledAsrException();
    }
  }

  AsrResult? _mapKnownOfflineError(Object error) {
    if (error is StateError) {
      final message = error.message.toString();
      if (message == 'asrModelMissingAfterExtract') {
        return const AsrResult(
          success: false,
          error: 'asrModelMissingAfterExtract',
        );
      }
      if (message == 'asrModelExtractionIncomplete') {
        return const AsrResult(
          success: false,
          error: 'asrModelExtractionIncomplete',
        );
      }
    }

    if (error is HttpException &&
        error.message.startsWith('asrDownloadFailedHttp:')) {
      final rawCode = error.message.split(':').last.trim();
      final statusCode = int.tryParse(rawCode);
      final errorParams = <String, Object?>{};
      if (statusCode != null) {
        errorParams['code'] = statusCode;
      }
      return AsrResult(
        success: false,
        error: 'asrDownloadFailedHttp',
        errorParams: errorParams,
      );
    }

    return null;
  }
}

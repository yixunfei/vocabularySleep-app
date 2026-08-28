import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'cstcloud_s3_compat_client.dart';
import 's3_bucket_probe.dart';

class ResourceDownloadProgress {
  const ResourceDownloadProgress({
    required this.receivedBytes,
    required this.totalBytes,
  });

  final int receivedBytes;
  final int totalBytes;

  double? get progress =>
      totalBytes <= 0 ? null : (receivedBytes / totalBytes).clamp(0.0, 1.0);
}

typedef ResourceDownloadProgressCallback =
    void Function(ResourceDownloadProgress progress);
typedef ResourceFileValidator = FutureOr<bool> Function(File file);

class CstCloudResourceCacheService {
  CstCloudResourceCacheService({
    CstCloudS3CompatClient? client,
    this.cacheDirectory,
  }) : _client = client ?? CstCloudS3CompatClient();

  final CstCloudS3CompatClient _client;
  final Directory? cacheDirectory;
  final Map<String, Future<File>> _downloadFutures = <String, Future<File>>{};
  final Map<String, Future<File>> _validatedDownloadFutures =
      <String, Future<File>>{};

  Future<List<S3ObjectSummary>> listObjects(
    String prefix, {
    int maxKeys = 1000,
  }) {
    return _client.listPrefix(prefix, maxKeys: maxKeys);
  }

  Future<Uint8List> readBytes(
    String remoteKey, {
    String? cacheRelativePath,
    ResourceDownloadProgressCallback? onProgress,
  }) async {
    final file = await ensureFileDownloaded(
      remoteKey,
      cacheRelativePath: cacheRelativePath,
      onProgress: onProgress,
    );
    try {
      return await file.readAsBytes();
    } catch (error, stackTrace) {
      try {
        await deleteCachedFile(remoteKey, cacheRelativePath: cacheRelativePath);
      } catch (_) {}
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<String> readText(
    String remoteKey, {
    String? cacheRelativePath,
    ResourceDownloadProgressCallback? onProgress,
  }) async {
    final bytes = await readBytes(
      remoteKey,
      cacheRelativePath: cacheRelativePath,
      onProgress: onProgress,
    );
    final normalized = remoteKey.toLowerCase();
    try {
      final decodedBytes = normalized.endsWith('.gz')
          ? const GZipDecoder().decodeBytes(bytes)
          : bytes;
      return utf8.decode(decodedBytes);
    } catch (error, stackTrace) {
      try {
        await deleteCachedFile(remoteKey, cacheRelativePath: cacheRelativePath);
      } catch (_) {}
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<File> ensureFileDownloaded(
    String remoteKey, {
    String? cacheRelativePath,
    ResourceDownloadProgressCallback? onProgress,
  }) {
    final normalizedTargetPath = _normalizedTargetPath(
      remoteKey,
      cacheRelativePath,
    );
    final inFlight = _downloadFutures[normalizedTargetPath];
    if (inFlight != null) {
      _notifyInFlightProgress(inFlight, onProgress);
      return inFlight;
    }

    final future = _ensureCachedFile(
      remoteKey,
      normalizedTargetPath,
      onProgress: onProgress,
    );
    late final Future<File> tracked;
    tracked = future.whenComplete(() {
      if (identical(_downloadFutures[normalizedTargetPath], tracked)) {
        _downloadFutures.remove(normalizedTargetPath);
      }
    });
    _downloadFutures[normalizedTargetPath] = tracked;
    return tracked;
  }

  Future<File> _ensureCachedFile(
    String remoteKey,
    String normalizedTargetPath, {
    ResourceDownloadProgressCallback? onProgress,
  }) async {
    final baseDir = await _cacheBaseDir();
    final targetFile = File(p.join(baseDir.path, normalizedTargetPath));

    if (await targetFile.exists()) {
      try {
        final existingBytes = await targetFile.length();
        if (existingBytes > 0) {
          // A previous process may have left a partial artifact beside a
          // usable cache entry. It is never needed once the target is valid.
          await _deletePartialArtifact(targetFile);
          onProgress?.call(
            ResourceDownloadProgress(
              receivedBytes: existingBytes,
              totalBytes: existingBytes,
            ),
          );
          return targetFile;
        }
      } catch (_) {
        // Treat an unreadable cache entry as unavailable and replace it.
      }
      await _deleteCacheArtifacts(targetFile);
    }

    return _ensureFileDownloadedImpl(
      remoteKey,
      targetFile,
      onProgress: onProgress,
    );
  }

  void _notifyInFlightProgress(
    Future<File> inFlight,
    ResourceDownloadProgressCallback? onProgress,
  ) {
    if (onProgress == null) {
      return;
    }
    unawaited(
      inFlight
          .then<void>((file) async {
            final size = await file.length();
            onProgress(
              ResourceDownloadProgress(receivedBytes: size, totalBytes: size),
            );
          })
          .catchError((_) {
            // Surface the original error through the awaited future only.
          }),
    );
  }

  /// Returns a cached file only after [validator] accepts it.
  ///
  /// An invalid existing entry is deleted and downloaded once more. If the
  /// replacement is also invalid, both the target and its partial file are
  /// removed and the returned future fails so callers can use a fallback.
  Future<File> ensureValidFileDownloaded(
    String remoteKey, {
    String? cacheRelativePath,
    ResourceDownloadProgressCallback? onProgress,
    required ResourceFileValidator validator,
  }) {
    final normalizedTargetPath = _normalizedTargetPath(
      remoteKey,
      cacheRelativePath,
    );
    final inFlight = _validatedDownloadFutures[normalizedTargetPath];
    if (inFlight != null) {
      _notifyInFlightProgress(inFlight, onProgress);
      return inFlight;
    }

    final future = _ensureValidFileDownloadedImpl(
      remoteKey,
      cacheRelativePath: cacheRelativePath,
      onProgress: onProgress,
      validator: validator,
    );
    late final Future<File> tracked;
    tracked = future.whenComplete(() {
      if (identical(_validatedDownloadFutures[normalizedTargetPath], tracked)) {
        _validatedDownloadFutures.remove(normalizedTargetPath);
      }
    });
    _validatedDownloadFutures[normalizedTargetPath] = tracked;
    return tracked;
  }

  /// Removes a cached resource and any interrupted-download artifact.
  Future<bool> deleteCachedFile(
    String remoteKey, {
    String? cacheRelativePath,
  }) async {
    final normalizedTargetPath = _normalizedTargetPath(
      remoteKey,
      cacheRelativePath,
    );
    final baseDir = await _cacheBaseDir();
    return _deleteCacheArtifacts(
      File(p.join(baseDir.path, normalizedTargetPath)),
    );
  }

  Future<bool> hasCachedFilesUnderPrefix(String prefix) async {
    final normalized = prefix.trim();
    if (normalized.isEmpty) return false;
    final baseDir = await _cacheBaseDir();
    final targetDir = Directory(
      p.join(baseDir.path, normalized.replaceAll('\\', '/')),
    );
    if (!await targetDir.exists()) {
      return false;
    }
    await for (final entity in targetDir.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File && !entity.path.endsWith('.part')) {
        return true;
      }
    }
    return false;
  }

  Future<Directory> _cacheBaseDir() async {
    final configuredDirectory = cacheDirectory;
    if (configuredDirectory != null) {
      if (!await configuredDirectory.exists()) {
        await configuredDirectory.create(recursive: true);
      }
      return configuredDirectory;
    }
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(supportDir.path, 'remote_resource_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _ensureFileDownloadedImpl(
    String remoteKey,
    File targetFile, {
    ResourceDownloadProgressCallback? onProgress,
  }) async {
    await targetFile.parent.create(recursive: true);
    final tempFile = File('${targetFile.path}.part');

    try {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      await _client.downloadObjectToFile(
        remoteKey,
        tempFile,
        onProgress: onProgress == null
            ? null
            : (receivedBytes, totalBytes) {
                onProgress(
                  ResourceDownloadProgress(
                    receivedBytes: receivedBytes,
                    totalBytes: totalBytes,
                  ),
                );
              },
      );
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await tempFile.rename(targetFile.path);
      final size = await targetFile.length();
      if (size <= 0) {
        await _deleteCacheArtifacts(targetFile);
        throw StateError('Downloaded resource is empty: $remoteKey');
      }
      onProgress?.call(
        ResourceDownloadProgress(receivedBytes: size, totalBytes: size),
      );
      return targetFile;
    } catch (_) {
      try {
        await _deleteCacheArtifacts(targetFile);
      } catch (_) {}
      rethrow;
    }
  }

  Future<File> _ensureValidFileDownloadedImpl(
    String remoteKey, {
    String? cacheRelativePath,
    ResourceDownloadProgressCallback? onProgress,
    required ResourceFileValidator validator,
  }) async {
    for (var attempt = 0; attempt < 2; attempt += 1) {
      late final File file;
      try {
        file = await ensureFileDownloaded(
          remoteKey,
          cacheRelativePath: cacheRelativePath,
          onProgress: onProgress,
        );
      } catch (error, stackTrace) {
        if (attempt == 1) {
          Error.throwWithStackTrace(error, stackTrace);
        }
        // Empty or interrupted downloads are invalid resources too. The
        // bounded second attempt gives the remote object one chance to be
        // fetched again without creating an unbounded retry loop.
        continue;
      }

      if (await _passesValidation(file, validator)) {
        return file;
      }

      if (!await _deleteCacheArtifacts(file)) {
        throw StateError('Unable to remove invalid resource: $remoteKey');
      }
      if (attempt == 1) {
        throw StateError('Downloaded resource failed validation: $remoteKey');
      }
    }

    throw StateError('Downloaded resource failed validation: $remoteKey');
  }

  Future<bool> _passesValidation(
    File file,
    ResourceFileValidator validator,
  ) async {
    try {
      return await validator(file);
    } catch (_) {
      return false;
    }
  }

  String _normalizedTargetPath(String remoteKey, String? cacheRelativePath) {
    final targetPath = cacheRelativePath?.trim().isNotEmpty == true
        ? cacheRelativePath!.trim()
        : remoteKey;
    return targetPath.replaceAll('\\', '/');
  }

  Future<bool> _deleteCacheArtifacts(File targetFile) async {
    var success = true;
    for (final file in <File>[targetFile, File('${targetFile.path}.part')]) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        success = false;
      }
    }
    return success;
  }

  Future<void> _deletePartialArtifact(File targetFile) async {
    try {
      final partialFile = File('${targetFile.path}.part');
      if (await partialFile.exists()) {
        await partialFile.delete();
      }
    } catch (_) {
      // A stale partial file must not make an otherwise usable cache miss.
    }
  }
}

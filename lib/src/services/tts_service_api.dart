part of 'tts_service.dart';

extension TtsServiceApi on TtsService {
  Future<void> _ensureApiAudioConfigured() async {
    if (_apiAudioConfigured) {
      return;
    }
    await _runOp<void>(
      'api.setAudioContext',
      () => _apiPlayer.setAudioContext(TtsService._spokenAudioContext),
      swallowError: true,
    );
    _apiAudioConfigured = true;
  }

  Future<void> _speakByApi(
    String text,
    TtsConfig config, {
    bool preCacheOnly = false,
  }) async {
    await _ensureApiAudioConfigured();
    final speakToken = ++_apiSpeakToken;
    final model = (config.model?.trim().isNotEmpty ?? false)
        ? config.model!.trim()
        : TtsService._defaultApiModel;
    final voice = config.remoteVoice.trim().isNotEmpty
        ? config.remoteVoice.trim()
        : TtsService._defaultApiVoice;
    final endpointPreview = config.provider == TtsProviderType.customApi
        ? (config.baseUrl?.trim().isEmpty ?? true)
              ? 'custom_api_missing_base_url'
              : _resolveApiEndpoint(config)
        : TtsService._defaultApiEndpoint;
    final cacheKey = _buildApiCacheKey(
      config: config,
      model: model,
      voice: voice,
      text: text,
    );
    final requestBody = <String, Object?>{
      'model': model,
      'input': text,
      'voice': '$model:$voice',
      'response_format': 'mp3',
      'speed': config.speed,
    };
    await _runOp<dynamic>(
      'local.stop.beforeApi',
      () => _flutterTts.stop(),
      swallowError: true,
    );
    await _runOp<void>(
      'api.stop.beforeApi',
      () => _apiPlayer.stop(),
      swallowError: true,
    );
    _activeApiClient?.close();

    final cachedFile = await _lookupApiCacheFile(cacheKey, config);
    if (cachedFile != null) {
      final cachedBytes = await _runOp<int>(
        'api.cache.length',
        () => cachedFile.length(),
        data: <String, Object?>{'path': cachedFile.path},
      );
      _throwIfApiInterrupted(speakToken, stage: 'before_cache_play');
      try {
        await _playApiSource(
          source: DeviceFileSource(cachedFile.path),
          config: config,
          speakToken: speakToken,
          bytes: cachedBytes ?? 0,
          sourceLabel: 'cache_file',
          endpoint: endpointPreview,
          model: model,
          voice: voice,
        );
        return;
      } catch (error, stackTrace) {
        if (error is _ApiSpeakInterrupted) {
          rethrow;
        }
        _log.w(
          'tts',
          'api cache playback failed, fallback to network',
          data: <String, Object?>{
            'path': cachedFile.path,
            'error': '$error',
            'stackTrace': '$stackTrace',
          },
        );
        await _runOp<void>(
          'api.cache.delete.invalid',
          () => cachedFile.delete(),
          data: <String, Object?>{'path': cachedFile.path},
          swallowError: true,
        );
      }
    }

    final apiKey = config.apiKey?.trim() ?? '';
    if (apiKey.isEmpty) {
      throw StateError('TTS API key is missing.');
    }
    if (config.provider == TtsProviderType.customApi &&
        (config.baseUrl == null || config.baseUrl!.trim().isEmpty)) {
      throw StateError('Custom API base URL is missing.');
    }

    final endpoint = _resolveApiEndpoint(config);
    final client = http.Client();
    _activeApiClient = client;

    final response = await _postApiSpeech(
      client: client,
      endpoint: endpoint,
      apiKey: apiKey,
      requestBody: requestBody,
      config: config,
      model: model,
      voice: voice,
      speakToken: speakToken,
    );
    _throwIfApiInterrupted(speakToken, stage: 'after_http');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'TTS API request failed: ${response.statusCode}, body=${_preview(response.body)}',
      );
    }
    final contentType = (response.headers['content-type'] ?? '')
        .toLowerCase()
        .trim();
    if (contentType.contains('application/json') ||
        contentType.contains('text/plain')) {
      throw StateError(
        'TTS API returned non-audio content-type: $contentType, body=${_preview(response.body)}',
      );
    }

    final audioBytes = response.bodyBytes;
    final cacheFile = await _writeApiCacheFile(
      cacheKey: cacheKey,
      bytes: audioBytes,
      config: config,
    );
    _throwIfApiInterrupted(speakToken, stage: 'before_play');

    try {
      await _playApiSource(
        source: cacheFile != null
            ? DeviceFileSource(cacheFile.path)
            : BytesSource(audioBytes),
        config: config,
        speakToken: speakToken,
        bytes: audioBytes.length,
        sourceLabel: cacheFile != null
            ? 'network_cached_file'
            : 'network_bytes',
        endpoint: endpoint,
        model: model,
        voice: voice,
      );
    } finally {
      if (identical(_activeApiClient, client)) {
        _activeApiClient = null;
      }
      client.close();
    }
  }

  Future<void> _playApiSource({
    required Source source,
    required TtsConfig config,
    required int speakToken,
    required int bytes,
    required String sourceLabel,
    required String endpoint,
    required String model,
    required String voice,
  }) async {
    final completer = Completer<void>();
    _apiCompletionCompleter = completer;
    _apiCompletionToken = speakToken;
    late final StreamSubscription<void> sub;
    sub = _apiPlayer.onPlayerComplete.listen((_) {
      if (_apiCompletionToken != speakToken) return;
      _completeApiSpeak();
      sub.cancel();
    });

    await _runOp<void>(
      'api.player.play',
      () => AudioPlayerSourceHelper.play(
        _apiPlayer,
        source,
        volume: config.volume.clamp(0.0, 1.0),
        tag: 'tts_audio',
        data: <String, Object?>{
          'speakToken': speakToken,
          'source': sourceLabel,
        },
      ),
      data: <String, Object?>{
        'speakToken': speakToken,
        'bytes': bytes,
        'volume': config.volume.clamp(0.0, 1.0),
        'source': sourceLabel,
      },
    );

    try {
      await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          _log.e(
            'tts',
            'api playback timeout',
            data: <String, Object?>{
              'speakToken': speakToken,
              'provider': config.provider.name,
              'endpoint': endpoint,
              'model': model,
              'voice': voice,
              'source': sourceLabel,
            },
          );
          unawaited(
            _runOp<void>(
              'api.stop.timeout',
              () => _apiPlayer.stop(),
              swallowError: true,
            ),
          );
          throw TimeoutException('API TTS playback timeout.');
        },
      );
    } finally {
      await sub.cancel();
      if (_apiCompletionToken == speakToken) {
        _completeApiSpeak();
      }
    }
  }

  bool _shouldUseApiCache(TtsConfig config) =>
      config.provider != TtsProviderType.local && config.enableApiCache;

  String _buildApiCacheKey({
    required TtsConfig config,
    required String model,
    required String voice,
    required String text,
  }) {
    final payload = jsonEncode(<String, Object?>{
      'provider': config.provider.name,
      'baseUrl': config.baseUrl?.trim() ?? '',
      'model': model,
      'voice': voice,
      'speed': config.speed,
      'text': text,
    });
    return sha256.convert(utf8.encode(payload)).toString();
  }

  Future<File?> _lookupApiCacheFile(String cacheKey, TtsConfig config) async {
    if (!_shouldUseApiCache(config)) {
      return null;
    }
    final dir = await _getApiCacheDirectory();
    final file = File(path.join(dir.path, '$cacheKey.mp3'));
    final exists = await _runOp<bool>(
      'api.cache.exists',
      () => file.exists(),
      data: <String, Object?>{'path': file.path},
      swallowError: true,
    );
    if (exists != true) {
      return null;
    }
    await _touchApiCacheFile(file);
    return file;
  }

  Future<File?> _writeApiCacheFile({
    required String cacheKey,
    required List<int> bytes,
    required TtsConfig config,
  }) async {
    if (!_shouldUseApiCache(config) || bytes.isEmpty) {
      return null;
    }
    final dir = await _getApiCacheDirectory();
    final file = File(path.join(dir.path, '$cacheKey.mp3'));
    final written = await _runOp<File>(
      'api.cache.write',
      () async {
        await file.writeAsBytes(bytes, flush: true);
        return file;
      },
      data: <String, Object?>{'path': file.path, 'bytes': bytes.length},
      swallowError: true,
    );
    if (written == null) {
      return null;
    }
    await _touchApiCacheFile(written);
    await _trimApiCacheIfNeeded(_normalizedApiCacheMb(config.maxApiCacheMb));
    return written;
  }

  Future<void> _touchApiCacheFile(File file) async {
    await _runOp<void>(
      'api.cache.touch',
      () => file.setLastModified(DateTime.now()),
      data: <String, Object?>{'path': file.path},
      swallowError: true,
    );
  }

  Future<Directory> _getApiCacheDirectory() async {
    final cached = _apiCacheDirectory;
    if (cached != null) {
      if (!await cached.exists()) {
        await cached.create(recursive: true);
      }
      return cached;
    }

    final root = await getApplicationSupportDirectory();
    final dir = Directory(path.join(root.path, 'tts_api_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _apiCacheDirectory = dir;
    return dir;
  }

  int _normalizedApiCacheMb(int value) =>
      value.clamp(TtsService._minApiCacheMb, TtsService._maxApiCacheMb).toInt();

  Future<int> _computeDirectoryBytes(Directory dir) async {
    var totalBytes = 0;
    if (!await dir.exists()) {
      return totalBytes;
    }
    await for (final entity in dir.list()) {
      if (entity is! File) {
        continue;
      }
      final stat = await _runOp<FileStat>(
        'api.cache.stat',
        () => entity.stat(),
        data: <String, Object?>{'path': entity.path},
        swallowError: true,
      );
      if (stat == null || stat.type != FileSystemEntityType.file) {
        continue;
      }
      totalBytes += stat.size;
    }
    return totalBytes;
  }

  Future<void> _trimApiCacheIfNeeded(int maxCacheMb) async {
    final dir = await _getApiCacheDirectory();
    final files = <({File file, FileStat stat})>[];
    var totalBytes = 0;

    await for (final entity in dir.list()) {
      if (entity is! File) {
        continue;
      }
      final stat = await _runOp<FileStat>(
        'api.cache.stat',
        () => entity.stat(),
        data: <String, Object?>{'path': entity.path},
        swallowError: true,
      );
      if (stat == null || stat.type != FileSystemEntityType.file) {
        continue;
      }
      totalBytes += stat.size;
      files.add((file: entity, stat: stat));
    }

    final maxBytes = _normalizedApiCacheMb(maxCacheMb) * 1024 * 1024;
    if (totalBytes <= maxBytes) {
      return;
    }

    files.sort(
      (left, right) => left.stat.modified.compareTo(right.stat.modified),
    );
    final targetBytes = totalBytes ~/ 2;
    var remainingBytes = totalBytes;
    for (final item in files) {
      if (remainingBytes <= targetBytes) {
        break;
      }
      await _runOp<void>(
        'api.cache.delete.trim',
        () => item.file.delete(),
        data: <String, Object?>{
          'path': item.file.path,
          'bytes': item.stat.size,
        },
        swallowError: true,
      );
      remainingBytes -= item.stat.size;
    }
  }

  String _resolveApiEndpoint(TtsConfig config) {
    if (config.provider == TtsProviderType.customApi) {
      final value = config.baseUrl?.trim() ?? '';
      if (value.isNotEmpty) {
        var normalized = value.replaceAll(RegExp(r'/+$'), '');
        if (normalized.toLowerCase().contains('/audio/speech')) {
          return normalized;
        }
        if (normalized.toLowerCase().endsWith('/v1')) {
          return '$normalized/audio/speech';
        }
        normalized = normalized.replaceAll(RegExp(r'/+$'), '');
        return '$normalized/v1/audio/speech';
      }
    }
    return TtsService._defaultApiEndpoint;
  }

  void _completeLocalSpeak({Object? error}) {
    final completer = _localCompletionCompleter;
    if (completer == null) return;
    if (!completer.isCompleted) {
      if (error == null) {
        completer.complete();
      } else {
        completer.completeError(error);
      }
    }
    _localCompletionCompleter = null;
  }

  void _completeApiSpeak({Object? error}) {
    final completer = _apiCompletionCompleter;
    if (completer == null) return;
    if (!completer.isCompleted) {
      if (error == null) {
        completer.complete();
      } else {
        completer.completeError(error);
      }
    }
    _apiCompletionCompleter = null;
    _apiCompletionToken = null;
  }

  void _interruptApiRequest({required String reason}) {
    _apiSpeakToken += 1;
    final client = _activeApiClient;
    _activeApiClient = null;
    if (client != null) {
      client.close();
    }
  }

  void _throwIfApiInterrupted(int speakToken, {required String stage}) {
    if (speakToken == _apiSpeakToken) return;
    throw _ApiSpeakInterrupted(stage);
  }

  bool _isApiSpeakTokenActive(int speakToken) => speakToken == _apiSpeakToken;

  Future<http.Response> _postApiSpeech({
    required http.Client client,
    required String endpoint,
    required String apiKey,
    required Map<String, Object?> requestBody,
    required TtsConfig config,
    required String model,
    required String voice,
    required int speakToken,
  }) async {
    final watch = Stopwatch()..start();
    final data = <String, Object?>{
      'provider': config.provider.name,
      'endpoint': endpoint,
      'model': model,
      'voice': voice,
      'speed': config.speed,
      'speakToken': speakToken,
    };
    try {
      final response = await client
          .post(
            Uri.parse(endpoint),
            headers: <String, String>{
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));
      return response;
    } catch (error, stackTrace) {
      final interrupted = !_isApiSpeakTokenActive(speakToken);
      if (interrupted) {
        throw const _ApiSpeakInterrupted('http_post_interrupted');
      }
      _log.e(
        'tts',
        'api.http.post.failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          ...data,
          'elapsedMs': watch.elapsedMilliseconds,
        },
      );
      rethrow;
    }
  }
}

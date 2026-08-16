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
    if (!preCacheOnly) {
      validateForPlayback(config);
      await _ensureApiAudioConfigured();
    }
    final speakToken = preCacheOnly ? _apiSpeakToken : ++_apiSpeakToken;
    final model = (config.model?.trim().isNotEmpty ?? false)
        ? config.model!.trim()
        : defaultTtsModelForProvider(config.provider);
    final voice = selectTtsVoiceForModelLanguage(
      provider: config.provider,
      model: model,
      currentVoice: config.remoteVoice,
      language: config.language,
      includeSavedVoices: false,
    );
    final endpointPreview = config.provider == TtsProviderType.customApi
        ? (config.baseUrl?.trim().isEmpty ?? true)
              ? 'custom_api_missing_base_url'
              : _resolveApiEndpoint(config, model: model)
        : _resolveApiEndpoint(config, model: model);
    final cacheKey = _buildApiCacheKey(
      config: config,
      model: model,
      voice: voice,
      text: text,
    );
    final requestBody = _buildApiSpeechRequestBody(
      text: text,
      config: config,
      model: model,
      voice: voice,
    );
    if (!preCacheOnly) {
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
      for (final client in List<http.Client>.of(_activeApiClients)) {
        client.close();
      }
      _activeApiClients.clear();
    }

    final cachedFile = await _lookupApiCacheFile(cacheKey, config);
    if (cachedFile != null) {
      if (preCacheOnly) {
        return;
      }
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
      throw const TtsConfigurationException('TTS API key is missing.');
    }
    if (config.provider == TtsProviderType.customApi &&
        (config.baseUrl == null || config.baseUrl!.trim().isEmpty)) {
      throw const TtsConfigurationException('Custom API base URL is missing.');
    }
    if (config.provider == TtsProviderType.doubao &&
        (config.appId?.trim().isEmpty ?? true)) {
      throw const TtsConfigurationException('Doubao App ID is missing.');
    }

    final endpoint = _resolveApiEndpoint(config, model: model);
    final client = _apiClientFactory();
    _activeApiClients.add(client);

    try {
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
          contentType.contains('event-stream') ||
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
      _throwIfApiInterrupted(
        speakToken,
        stage: preCacheOnly ? 'after_cache_write' : 'before_play',
      );
      if (preCacheOnly) {
        return;
      }

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
      _activeApiClients.remove(client);
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
    final appId = config.appId?.trim() ?? '';
    final data = <String, Object?>{
      'provider': config.provider.name,
      'baseUrl': config.baseUrl?.trim() ?? '',
      'model': model,
      'voice': voice,
      'speed': config.speed,
      'text': text,
    };
    if (appId.isNotEmpty) {
      data['appId'] = appId;
    }
    final stylePrompt = config.stylePrompt?.trim() ?? '';
    if (stylePrompt.isNotEmpty) {
      data['stylePrompt'] = stylePrompt;
    }
    final payload = jsonEncode(data);
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

  String _resolveApiEndpoint(TtsConfig config, {String? model}) {
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
    if (config.provider == TtsProviderType.aliyunBailian) {
      final selectedModel = (model?.trim().isNotEmpty ?? false)
          ? model!.trim()
          : defaultTtsModelForProvider(config.provider);
      return defaultAliyunTtsEndpointForModel(selectedModel);
    }
    if (config.provider == TtsProviderType.doubao) {
      return defaultTtsEndpointForProvider(config.provider);
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
    final clients = List<http.Client>.of(_activeApiClients);
    _activeApiClients.clear();
    for (final client in clients) {
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
      if (config.provider == TtsProviderType.doubao) {
        final response = await client
            .post(
              Uri.parse(endpoint),
              headers: <String, String>{
                'Authorization': 'Bearer;$apiKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(requestBody),
            )
            .timeout(const Duration(seconds: 30));
        _throwIfApiInterrupted(speakToken, stage: 'after_http_post');
        return _normalizeDoubaoSpeechResponse(response);
      }

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
      _throwIfApiInterrupted(speakToken, stage: 'after_http_post');
      if (config.provider == TtsProviderType.aliyunBailian) {
        return _normalizeAliyunSpeechResponse(
          client: client,
          response: response,
        );
      }
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

  Map<String, Object?> _buildApiSpeechRequestBody({
    required String text,
    required TtsConfig config,
    required String model,
    required String voice,
  }) {
    final stylePrompt = config.stylePrompt?.trim() ?? '';
    if (config.provider == TtsProviderType.aliyunBailian) {
      return isAliyunCosyVoiceTtsModel(model)
          ? _buildAliyunCosyVoiceSpeechRequestBody(
              text: text,
              config: config,
              model: model,
              voice: voice,
              stylePrompt: stylePrompt,
            )
          : _buildAliyunQwenSpeechRequestBody(
              text: text,
              config: config,
              model: model,
              voice: voice,
              stylePrompt: stylePrompt,
            );
    }
    if (config.provider == TtsProviderType.doubao) {
      final appId = config.appId?.trim() ?? '';
      return <String, Object?>{
        'app': <String, Object?>{
          'appid': appId,
          'token': config.apiKey?.trim() ?? '',
          'cluster': model,
        },
        'user': <String, Object?>{'uid': 'vocabulary_sleep_app'},
        'audio': <String, Object?>{
          'voice_type': voice,
          'encoding': 'mp3',
          'speed_ratio': config.speed.clamp(0.5, 1.5),
          'volume_ratio': 1.0,
          'pitch_ratio': 1.0,
          if (stylePrompt.isNotEmpty) 'emotion': stylePrompt,
          if (_doubaoLanguage(config.language) != null)
            'language': _doubaoLanguage(config.language),
        },
        'request': <String, Object?>{
          'reqid': 'tts_${DateTime.now().microsecondsSinceEpoch}',
          'text': text,
          'text_type': 'plain',
          'operation': 'query',
        },
      };
    }
    return <String, Object?>{
      'model': model,
      'input': text,
      'voice': '$model:$voice',
      'response_format': 'mp3',
      'speed': config.speed,
      if (stylePrompt.isNotEmpty) 'instructions': stylePrompt,
    };
  }

  Map<String, Object?> _buildAliyunQwenSpeechRequestBody({
    required String text,
    required TtsConfig config,
    required String model,
    required String voice,
    required String stylePrompt,
  }) {
    final input = <String, Object?>{'text': text, 'voice': voice};
    final languageType = _aliyunLanguageType(config.language);
    if (languageType != null) {
      input['language_type'] = languageType;
    }
    final instruction = _aliyunSpeechInstruction(
      speed: config.speed,
      language: config.language,
      model: model,
      stylePrompt: stylePrompt,
    );
    if (instruction != null) {
      input[_aliyunInstructionField(model)] = instruction;
    }
    return <String, Object?>{'model': model, 'input': input};
  }

  Map<String, Object?> _buildAliyunCosyVoiceSpeechRequestBody({
    required String text,
    required TtsConfig config,
    required String model,
    required String voice,
    required String stylePrompt,
  }) {
    final input = <String, Object?>{
      'text': text,
      'voice': voice,
      'format': 'mp3',
      'sample_rate': 24000,
      'volume': (config.volume.clamp(0.0, 1.0) * 100).round(),
      'rate': config.speed.clamp(0.5, 2.0),
    };
    final languageHint = _aliyunCosyVoiceLanguageHint(config.language);
    if (languageHint != null) {
      input['language_hints'] = <String>[languageHint];
    }
    if (stylePrompt.isNotEmpty) {
      input['instruction'] = stylePrompt;
    }
    return <String, Object?>{'model': model, 'input': input};
  }

  Future<http.Response> _normalizeAliyunSpeechResponse({
    required http.Client client,
    required http.Response response,
  }) async {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return response;
    }
    final decoded = _decodeAliyunSpeechPayload(response.body);
    if (decoded == null) {
      return response;
    }
    final bytes = _extractAliyunAudioBytes(decoded);
    if (bytes != null && bytes.isNotEmpty) {
      return http.Response.bytes(
        bytes,
        200,
        headers: const <String, String>{'content-type': 'audio/mpeg'},
      );
    }
    final audioUrl = _extractAliyunAudioUrl(decoded);
    if (audioUrl == null || audioUrl.isEmpty) {
      return response;
    }
    final audioResponse = await client
        .get(Uri.parse(audioUrl))
        .timeout(const Duration(seconds: 30));
    if (audioResponse.statusCode < 200 || audioResponse.statusCode >= 300) {
      return http.Response(
        'Aliyun TTS audio download failed: ${audioResponse.statusCode}',
        audioResponse.statusCode,
      );
    }
    return http.Response.bytes(
      audioResponse.bodyBytes,
      200,
      headers: <String, String>{
        'content-type': audioResponse.headers['content-type'] ?? 'audio/mpeg',
      },
    );
  }

  http.Response _normalizeDoubaoSpeechResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return response;
    }
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      return response;
    }
    final bytes = _extractDoubaoAudioBytes(decoded);
    if (bytes == null || bytes.isEmpty) {
      return response;
    }
    return http.Response.bytes(
      bytes,
      200,
      headers: const <String, String>{'content-type': 'audio/mpeg'},
    );
  }

  Object? _decodeAliyunSpeechPayload(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {}

    final events = <Object?>[];
    for (final line in body.split(RegExp(r'\r?\n'))) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('data:')) {
        continue;
      }
      final payload = trimmed.substring(5).trim();
      if (payload.isEmpty || payload == '[DONE]') {
        continue;
      }
      try {
        events.add(jsonDecode(payload));
      } catch (_) {}
    }
    return events.isEmpty ? null : events;
  }

  List<int>? _extractAliyunAudioBytes(Object? decoded) {
    final candidates = <Object?>[];

    void visit(Object? value) {
      if (value is List) {
        for (final item in value) {
          visit(item);
        }
        return;
      }
      if (value is! Map) {
        return;
      }
      candidates.add(value['audio']);
      candidates.add(value['data']);
      candidates.add(value['base64']);
      final output = value['output'];
      if (output != null && !identical(output, value)) {
        visit(output);
      }
      final audio = value['audio'];
      if (audio != null && !identical(audio, value)) {
        visit(audio);
      }
    }

    visit(decoded);
    final chunks = <int>[];
    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isEmpty) continue;
      final base64Payload = value.contains(',')
          ? value.substring(value.indexOf(',') + 1)
          : value;
      try {
        chunks.addAll(base64Decode(base64Payload));
      } catch (_) {}
    }
    return chunks.isEmpty ? null : chunks;
  }

  String? _extractAliyunAudioUrl(Object? decoded) {
    final urls = <Object?>[];

    void visit(Object? value) {
      if (value is List) {
        for (final item in value) {
          visit(item);
        }
        return;
      }
      if (value is! Map) {
        return;
      }
      urls.add(value['url']);
      urls.add(value['audio_url']);
      final output = value['output'];
      if (output != null && !identical(output, value)) {
        visit(output);
      }
      final audio = value['audio'];
      if (audio is Map) {
        visit(audio);
      } else {
        urls.add(audio);
      }
    }

    visit(decoded);
    for (final url in urls) {
      final value = url?.toString().trim() ?? '';
      if (value.startsWith('http://') || value.startsWith('https://')) {
        return value;
      }
    }
    return null;
  }

  List<int>? _extractDoubaoAudioBytes(Object? decoded) {
    if (decoded is! Map) return null;
    final code = decoded['code'];
    if (code is num && code != 3000 && code != 0) return null;
    final candidates = <Object?>[
      decoded['data'],
      decoded['audio'],
      decoded['result'],
    ];
    final response = decoded['response'];
    if (response is Map) {
      candidates.add(response['data']);
      candidates.add(response['audio']);
    }
    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isEmpty) continue;
      final base64Payload = value.contains(',')
          ? value.substring(value.indexOf(',') + 1)
          : value;
      try {
        return base64Decode(base64Payload);
      } catch (_) {}
    }
    return null;
  }

  String? _aliyunLanguageType(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty || value == 'auto' || value == 'system') return null;
    if (value.startsWith('zh')) return 'Chinese';
    if (value.startsWith('en')) return 'English';
    if (value.startsWith('ja')) return 'Japanese';
    if (value.startsWith('ko')) return 'Korean';
    if (value.startsWith('de')) return 'German';
    if (value.startsWith('fr')) return 'French';
    if (value.startsWith('es')) return 'Spanish';
    if (value.startsWith('ru')) return 'Russian';
    if (value.startsWith('it')) return 'Italian';
    if (value.startsWith('pt')) return 'Portuguese';
    return null;
  }

  String? _aliyunCosyVoiceLanguageHint(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty || value == 'auto' || value == 'system') return null;
    if (value.startsWith('zh')) return 'zh';
    if (value.startsWith('en')) return 'en';
    if (value.startsWith('ja')) return 'ja';
    if (value.startsWith('ko')) return 'ko';
    if (value.startsWith('de')) return 'de';
    if (value.startsWith('fr')) return 'fr';
    if (value.startsWith('es')) return 'es';
    if (value.startsWith('ru')) return 'ru';
    return value.split('-').first;
  }

  String? _doubaoLanguage(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty || value == 'auto' || value == 'system') return null;
    if (value.startsWith('zh')) return 'zh';
    if (value.startsWith('en')) return 'en';
    if (value.startsWith('ja')) return 'ja';
    if (value.startsWith('ko')) return 'ko';
    return value.split('-').first;
  }

  String? _aliyunSpeechInstruction({
    required double speed,
    required String language,
    required String model,
    required String stylePrompt,
  }) {
    final trimmedStyle = stylePrompt.trim();
    if (!_aliyunSupportsInstruction(model) && trimmedStyle.isEmpty) {
      return null;
    }
    final normalizedSpeed = speed.clamp(0.5, 1.5).toDouble();
    final zh = language.trim().toLowerCase().startsWith('zh');
    final parts = <String>[];
    if (normalizedSpeed <= 0.75) {
      parts.add(zh ? '请用较慢语速朗读。' : 'Read at a slower pace.');
    } else if (normalizedSpeed >= 1.25) {
      parts.add(zh ? '请用较快语速朗读。' : 'Read at a faster pace.');
    } else if (_aliyunSupportsInstruction(model)) {
      parts.add(zh ? '请用自然语速朗读。' : 'Read at a natural pace.');
    }
    if (trimmedStyle.isNotEmpty) {
      parts.add(trimmedStyle);
    }
    return parts.isEmpty ? null : parts.join(zh ? ' ' : ' ');
  }

  bool _aliyunSupportsInstruction(String model) {
    final lower = model.toLowerCase();
    return lower.contains('instruct') || lower.contains('cosyvoice');
  }

  String _aliyunInstructionField(String model) {
    return model.toLowerCase().contains('cosyvoice')
        ? 'instruction'
        : 'instructions';
  }
}

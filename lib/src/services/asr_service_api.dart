part of 'asr_service.dart';

extension AsrServiceApi on AsrService {
  Future<AsrResult> _transcribeByApi({
    required String audioPath,
    required AsrConfig config,
    required String? expectedText,
    required TtsConfig? ttsConfig,
    required String? debugRunDir,
  }) async {
    if (config.provider == AsrProviderType.customApi &&
        (config.baseUrl == null || config.baseUrl!.trim().isEmpty)) {
      return const AsrResult(success: false, error: 'asrApiBaseUrlMissing');
    }
    final apiKey = config.apiKey?.trim() ?? '';
    if (apiKey.isEmpty) {
      return const AsrResult(success: false, error: 'asrApiKeyMissing');
    }
    final endpoint = _resolveApiEndpoint(config);

    final requestToken = ++_apiRequestToken;
    _activeApiClient?.close();
    final client = http.Client();
    _activeApiClient = client;
    String? processedAudioPath;
    try {
      processedAudioPath = await _prepareAudioForApi(
        audioPath,
        expectedText: expectedText,
      );
      await _writeProcessedDebugFile(
        debugRunDir,
        sourcePath: processedAudioPath,
        stem: '${config.provider.name}_processed',
      );
      final language = _normalizeApiLanguage(config.language);
      final prompt = config.provider == AsrProviderType.api
          ? _buildApiPrompt(expectedText)
          : '';
      final response = await _sendApiTranscriptionRequest(
        client: client,
        endpoint: endpoint,
        apiKey: apiKey,
        model: config.model,
        language: language,
        audioPath: processedAudioPath,
        includePrompt: prompt.isNotEmpty,
        prompt: prompt,
        requestToken: requestToken,
      );
      if (!_isApiRequestActive(requestToken) || _stopRequested) {
        return const AsrResult(
          success: false,
          error: 'asrRecognitionCancelled',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AsrResult(
          success: false,
          error: 'asrApiRequestFailed',
          errorParams: <String, Object?>{
            'code': response.statusCode,
            'body': _preview(response.body),
          },
        );
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = response.body;
      }
      var text = decoded is Map
          ? decoded['text']?.toString()
          : decoded?.toString();
      if (text == null || text.trim().isEmpty) {
        return const AsrResult(success: false, error: 'asrEmptyResult');
      }
      text = text.trim();
      final expected = (expectedText ?? '').trim();
      double? acousticSimilarity;
      String? activeScoringMethod;
      Map<String, double> scoringBreakdown = const <String, double>{};
      var engine = 'api';
      if (expected.isNotEmpty && ttsConfig != null) {
        final textSimilarity = _estimateTextSimilarity(expected, text);
        if (textSimilarity < 0.62) {
          final fallback = await _estimateAcousticFallbackForApi(
            audioPath: audioPath,
            config: config,
            expectedText: expected,
            ttsConfig: ttsConfig,
            debugRunDir: debugRunDir,
          );
          if (fallback != null) {
            acousticSimilarity = fallback.similarity?.clamp(0.0, 1.0);
            activeScoringMethod = fallback.activeScoringMethod;
            scoringBreakdown = fallback.scoringBreakdown;
            engine = 'api_with_similarity';
            if (acousticSimilarity != null &&
                _shouldAlignTranscriptByAcoustics(
                  expected: expected,
                  recognized: text,
                  acousticSimilarity: acousticSimilarity,
                )) {
              text = expected;
              engine = 'api_target_aligned';
            }
          }
        }
      }

      return AsrResult(
        success: true,
        text: text,
        similarity: acousticSimilarity,
        similarityFromAcoustic: acousticSimilarity != null,
        engine: engine,
        activeScoringMethod: activeScoringMethod,
        scoringBreakdown: scoringBreakdown,
      );
    } on TimeoutException {
      if (_stopRequested) {
        return const AsrResult(
          success: false,
          error: 'asrRecognitionCancelled',
        );
      }
      return const AsrResult(success: false, error: 'asrApiTimeout');
    } catch (error) {
      if (_stopRequested) {
        return const AsrResult(
          success: false,
          error: 'asrRecognitionCancelled',
        );
      }
      return AsrResult(
        success: false,
        error: 'asrRequestFailed',
        errorParams: <String, Object?>{'error': error},
      );
    } finally {
      if (processedAudioPath != null && processedAudioPath != audioPath) {
        try {
          final tempFile = File(processedAudioPath);
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (_) {}
      }
      if (identical(_activeApiClient, client)) {
        _activeApiClient = null;
      }
      client.close();
    }
  }

  Future<AsrResult> _transcribeBySimilarity({
    required String audioPath,
    required AsrConfig config,
    required String? expectedText,
    required TtsConfig? ttsConfig,
    required String? debugRunDir,
  }) async {
    final expected = (expectedText ?? '').trim();
    if (expected.isEmpty) {
      return const AsrResult(
        success: false,
        error: 'asrSimilarityExpectedTextMissing',
      );
    }
    if (ttsConfig == null) {
      return const AsrResult(success: false, error: 'asrSimilarityTtsMissing');
    }

    late final dynamic waveData;
    try {
      _ensureSherpaBindings();
      waveData = readWave(audioPath);
    } catch (error) {
      return AsrResult(
        success: false,
        error: 'asrSimilarityFailed',
        errorParams: <String, Object?>{'error': '$error'},
      );
    }
    if (waveData.samples.isEmpty || waveData.sampleRate <= 0) {
      return const AsrResult(success: false, error: 'asrInvalidWav');
    }
    final preparedUser = _prepareWaveData(
      samples: waveData.samples,
      sampleRate: waveData.sampleRate,
      targetSampleRate: AsrService._targetSampleRate,
    );
    await _writePreparedDebugWav(
      debugRunDir,
      stem: 'local_similarity_processed',
      prepared: preparedUser,
    );
    if (preparedUser.samples.isEmpty) {
      return const AsrResult(success: false, error: 'asrNoSpeechDetected');
    }
    final minSeconds = _minDurationForExpected(expectedText);
    if (preparedUser.samples.length <
        (AsrService._targetSampleRate * minSeconds).round()) {
      return const AsrResult(success: false, error: 'asrRecordingTooShort');
    }
    if (preparedUser.peak < _minPeakForExpected(expectedText)) {
      return const AsrResult(success: false, error: 'asrNoSpeechDetected');
    }

    final requestToken = ++_apiRequestToken;
    _activeApiClient?.close();
    final client = http.Client();
    _activeApiClient = client;
    String? referencePath;

    try {
      final referenceWavBytes = await _requestSimilarityReferenceWav(
        client: client,
        requestToken: requestToken,
        expected: expected,
        ttsConfig: ttsConfig,
      );
      if (!_isApiRequestActive(requestToken) || _stopRequested) {
        return const AsrResult(
          success: false,
          error: 'asrRecognitionCancelled',
        );
      }

      final tempDir = await getTemporaryDirectory();
      referencePath = p.join(
        tempDir.path,
        'asr_similarity_ref_${DateTime.now().microsecondsSinceEpoch}.wav',
      );
      await File(referencePath).writeAsBytes(referenceWavBytes, flush: true);
      await _writeProcessedDebugFile(
        debugRunDir,
        sourcePath: referencePath,
        stem: 'local_similarity_reference',
      );
      final refWave = readWave(referencePath);
      final preparedRef = _prepareWaveData(
        samples: refWave.samples,
        sampleRate: refWave.sampleRate,
        targetSampleRate: AsrService._targetSampleRate,
      );
      if (preparedRef.samples.isEmpty || preparedRef.peak <= 0) {
        return const AsrResult(
          success: false,
          error: 'asrSimilarityReferenceInvalid',
        );
      }

      final userFeatures = _extractAcousticFeatures(
        preparedUser.samples,
        sampleRate: preparedUser.sampleRate,
      );
      final refFeatures = _extractAcousticFeatures(
        preparedRef.samples,
        sampleRate: preparedRef.sampleRate,
      );
      if (userFeatures.isEmpty || refFeatures.isEmpty) {
        return const AsrResult(
          success: false,
          error: 'asrSimilarityFeatureInsufficient',
        );
      }

      final dtwDistance = _dtwDistance(refFeatures, userFeatures);
      final userDurationSec =
          preparedUser.samples.length / AsrService._targetSampleRate;
      final refDurationSec =
          preparedRef.samples.length / AsrService._targetSampleRate;
      final similarity = _distanceToSimilarity(
        dtwDistance,
        userDurationSec: userDurationSec,
        refDurationSec: refDurationSec,
        expectedLength: expected.runes.length,
      );
      final scoringMethods = await _resolveReadyScoringMethods(config);
      if (scoringMethods.isEmpty) {
        return AsrResult(
          success: true,
          similarity: similarity.clamp(0.0, 1.0),
          similarityFromAcoustic: true,
          engine: 'local_similarity',
        );
      }
      final scoring = _scoreByMethods(
        methods: scoringMethods,
        expectedText: expected,
        recognizedText: null,
        acousticSimilarity: similarity,
        userDurationSec: userDurationSec,
        refDurationSec: refDurationSec,
      );

      return AsrResult(
        success: true,
        similarity: scoring.total,
        similarityFromAcoustic: true,
        engine: 'local_similarity',
        activeScoringMethod: scoringMethods.first.name,
        scoringBreakdown: scoring.breakdown.map(
          (key, value) => MapEntry(key.name, value),
        ),
      );
    } on _CanceledAsrException {
      return const AsrResult(success: false, error: 'asrRecognitionCancelled');
    } on TimeoutException {
      if (_stopRequested) {
        return const AsrResult(
          success: false,
          error: 'asrRecognitionCancelled',
        );
      }
      return const AsrResult(success: false, error: 'asrApiTimeout');
    } catch (error) {
      if (_stopRequested) {
        return const AsrResult(
          success: false,
          error: 'asrRecognitionCancelled',
        );
      }
      if (error is StateError) {
        final message = error.message.toString();
        if (message == 'asrSimilarityTtsApiKeyMissing') {
          return const AsrResult(
            success: false,
            error: 'asrSimilarityTtsApiKeyMissing',
          );
        }
        if (message == 'asrSimilarityTtsBaseUrlMissing') {
          return const AsrResult(
            success: false,
            error: 'asrSimilarityTtsBaseUrlMissing',
          );
        }
        if (message == 'asrSimilarityReferenceInvalid') {
          return const AsrResult(
            success: false,
            error: 'asrSimilarityReferenceInvalid',
          );
        }
        if (message == 'asrSimilarityLocalSynthesisUnsupported') {
          return const AsrResult(
            success: false,
            error: 'asrSimilarityLocalSynthesisUnsupported',
          );
        }
        if (message.startsWith('asrSimilarityReferenceFailedHttp:')) {
          final payload = message.split(':');
          final code = payload.length > 1 ? int.tryParse(payload[1]) : null;
          final body = payload.length > 2 ? payload.sublist(2).join(':') : '';
          return AsrResult(
            success: false,
            error: 'asrSimilarityReferenceFailedHttp',
            errorParams: <String, Object?>{
              'code': ?code,
              if (body.trim().isNotEmpty) 'body': body.trim(),
            },
          );
        }
      }
      return AsrResult(
        success: false,
        error: 'asrSimilarityFailed',
        errorParams: <String, Object?>{'error': '$error'},
      );
    } finally {
      if (referencePath != null) {
        final refFile = File(referencePath);
        if (await refFile.exists()) {
          await refFile.delete();
        }
      }
      if (identical(_activeApiClient, client)) {
        _activeApiClient = null;
      }
      client.close();
    }
  }

  Future<AsrResult?> _estimateAcousticFallbackForApi({
    required String audioPath,
    required AsrConfig config,
    required String expectedText,
    required TtsConfig ttsConfig,
    required String? debugRunDir,
  }) async {
    final similarityResult = await _transcribeBySimilarity(
      audioPath: audioPath,
      config: config.copyWith(provider: AsrProviderType.localSimilarity),
      expectedText: expectedText,
      ttsConfig: ttsConfig,
      debugRunDir: debugRunDir,
    );
    if (!similarityResult.success || similarityResult.similarity == null) {
      return null;
    }
    return similarityResult;
  }

  bool _shouldAlignTranscriptByAcoustics({
    required String expected,
    required String recognized,
    required double acousticSimilarity,
  }) {
    if (expected.trim().isEmpty) return false;
    if (expected.runes.length > 32) return false;
    final textSimilarity = _estimateTextSimilarity(expected, recognized);
    if (textSimilarity >= 0.38) return false;
    return acousticSimilarity >= 0.90;
  }

  Future<Uint8List> _requestSimilarityReferenceWav({
    required http.Client client,
    required int requestToken,
    required String expected,
    required TtsConfig ttsConfig,
  }) async {
    if (ttsConfig.provider == TtsProviderType.local) {
      return _synthesizeLocalReferenceWav(
        expected: expected,
        ttsConfig: ttsConfig,
      );
    }

    final apiKey = ttsConfig.apiKey?.trim() ?? '';
    if (apiKey.isEmpty) {
      final fallback = await _trySynthesizeLocalReferenceFallback(
        expected: expected,
        ttsConfig: ttsConfig,
      );
      if (fallback != null) {
        return fallback;
      }
      throw StateError('asrSimilarityTtsApiKeyMissing');
    }
    if (ttsConfig.provider == TtsProviderType.customApi &&
        (ttsConfig.baseUrl == null || ttsConfig.baseUrl!.trim().isEmpty)) {
      final fallback = await _trySynthesizeLocalReferenceFallback(
        expected: expected,
        ttsConfig: ttsConfig,
      );
      if (fallback != null) {
        return fallback;
      }
      throw StateError('asrSimilarityTtsBaseUrlMissing');
    }
    final endpoint = _resolveTtsEndpoint(ttsConfig);
    final model = (ttsConfig.model?.trim().isNotEmpty ?? false)
        ? ttsConfig.model!.trim()
        : AsrService._defaultTtsModel;
    final voice = ttsConfig.remoteVoice.trim().isNotEmpty
        ? ttsConfig.remoteVoice.trim()
        : AsrService._defaultTtsVoice;
    final response = await client
        .post(
          Uri.parse(endpoint),
          headers: <String, String>{
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(<String, Object?>{
            'model': model,
            'input': expected,
            'voice': '$model:$voice',
            'response_format': 'wav',
            'speed': 1.0,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (!_isApiRequestActive(requestToken) || _stopRequested) {
      throw const _CanceledAsrException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'asrSimilarityReferenceFailedHttp:${response.statusCode}:${_preview(response.body)}',
      );
    }
    if (response.bodyBytes.isEmpty) {
      throw StateError('asrSimilarityReferenceInvalid');
    }
    final bytes = response.bodyBytes;
    if (bytes.length < 12 ||
        bytes[0] != 0x52 ||
        bytes[1] != 0x49 ||
        bytes[2] != 0x46 ||
        bytes[3] != 0x46) {
      throw StateError('asrSimilarityReferenceInvalid');
    }
    return bytes;
  }

  Future<Uint8List?> _trySynthesizeLocalReferenceFallback({
    required String expected,
    required TtsConfig ttsConfig,
  }) async {
    try {
      return await _synthesizeLocalReferenceWav(
        expected: expected,
        ttsConfig: ttsConfig.copyWith(provider: TtsProviderType.local),
      );
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> _synthesizeLocalReferenceWav({
    required String expected,
    required TtsConfig ttsConfig,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      throw StateError('asrSimilarityLocalSynthesisUnsupported');
    }
    final tts = FlutterTts();
    final tempDir = await getTemporaryDirectory();
    final outputPath = p.join(
      tempDir.path,
      'asr_similarity_local_ref_${DateTime.now().microsecondsSinceEpoch}.wav',
    );
    final outputFile = File(outputPath);

    try {
      await tts.awaitSynthCompletion(true);
      final language =
          _normalizeTtsLanguage(ttsConfig.language) ??
          _inferLocalReferenceLanguage(expected);
      if (language != null) {
        await tts.setLanguage(language);
      }
      // Keep follow-along reference speed stable for acoustic comparison.
      await tts.setSpeechRate(1.0);
      await tts.setVolume(1.0);
      await tts.setPitch(1.0);
      final localVoice = ttsConfig.localVoice.trim();
      if (localVoice.isNotEmpty) {
        await tts.setVoice(<String, String>{'name': localVoice});
      }
      final result = await tts.synthesizeToFile(expected, outputPath, true);
      if (!_isTtsInvokeSuccess(result)) {
        throw StateError('asrSimilarityReferenceInvalid');
      }
      final ready = await _waitForFileReady(outputFile);
      if (!ready) {
        throw StateError('asrSimilarityReferenceInvalid');
      }
      final bytes = await outputFile.readAsBytes();
      if (!_isWavBytes(bytes)) {
        throw StateError('asrSimilarityReferenceInvalid');
      }
      return bytes;
    } on MissingPluginException {
      throw StateError('asrSimilarityLocalSynthesisUnsupported');
    } catch (error) {
      if (error is StateError) rethrow;
      throw StateError('asrSimilarityReferenceInvalid');
    } finally {
      try {
        await tts.stop();
      } catch (_) {}
      if (await outputFile.exists()) {
        await outputFile.delete();
      }
    }
  }

  bool _isTtsInvokeSuccess(dynamic result) {
    if (result == null) return true;
    if (result is bool) return result;
    if (result is int) return result == 1;
    return true;
  }

  Future<bool> _waitForFileReady(File file) async {
    for (var i = 0; i < 30; i++) {
      if (await file.exists()) {
        final stat = await file.stat();
        if (stat.size > 44) return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    return false;
  }

  bool _isWavBytes(List<int> bytes) {
    return bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x41 &&
        bytes[10] == 0x56 &&
        bytes[11] == 0x45;
  }

  String? _normalizeTtsLanguage(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value.toLowerCase() == 'auto') return null;
    final tag = value.replaceAll('_', '-').toLowerCase();
    if (tag == 'en') return 'en-US';
    if (tag == 'zh') return 'zh-CN';
    if (tag == 'ja') return 'ja-JP';
    if (tag == 'fr') return 'fr-FR';
    if (tag == 'de') return 'de-DE';
    if (tag == 'es') return 'es-ES';
    return value;
  }

  String _resolveTtsEndpoint(TtsConfig config) {
    if (config.provider == TtsProviderType.customApi) {
      final value = config.baseUrl?.trim() ?? '';
      if (value.isNotEmpty) {
        var normalized = value.replaceAll(RegExp(r'/+$'), '');
        final lower = normalized.toLowerCase();
        if (lower.contains('/audio/speech')) {
          return normalized;
        }
        if (lower.endsWith('/v1')) {
          return '$normalized/audio/speech';
        }
        return '$normalized/v1/audio/speech';
      }
    }
    return AsrService._defaultTtsApiEndpoint;
  }

  void _interruptApiRequest({required String reason}) {
    _apiRequestToken += 1;
    final client = _activeApiClient;
    _activeApiClient = null;
    if (client != null) {
      client.close();
    }
  }

  bool _isApiRequestActive(int token) => token == _apiRequestToken;

  String _resolveApiEndpoint(AsrConfig config) {
    if (config.provider == AsrProviderType.customApi) {
      final value = config.baseUrl?.trim() ?? '';
      if (value.isNotEmpty) {
        var normalized = value.replaceAll(RegExp(r'/+$'), '');
        final lower = normalized.toLowerCase();
        if (lower.contains('/audio/transcriptions')) {
          return normalized;
        }
        if (lower.endsWith('/v1')) {
          return '$normalized/audio/transcriptions';
        }
        return '$normalized/v1/audio/transcriptions';
      }
    }
    return AsrService._defaultApiEndpoint;
  }

  String? _normalizeApiLanguage(String raw) {
    final normalized = normalizeAsrLanguageTag(raw).toLowerCase();
    if (normalized == 'auto') return null;
    if (normalized.startsWith('zh')) return 'zh';
    if (normalized.startsWith('en')) return 'en';
    if (normalized.startsWith('ja')) return 'ja';
    if (normalized.startsWith('ko')) return 'ko';
    if (normalized.startsWith('de')) return 'de';
    if (normalized.startsWith('fr')) return 'fr';
    if (normalized.startsWith('es')) return 'es';
    if (normalized.startsWith('pt')) return 'pt';
    if (normalized.startsWith('it')) return 'it';
    if (normalized.startsWith('ru')) return 'ru';
    return normalized.split('-').first;
  }

  String _preview(String value) {
    final compact = value.replaceAll('\n', ' ').replaceAll('\r', ' ').trim();
    if (compact.length <= 120) return compact;
    return '${compact.substring(0, 120)}...';
  }

  Future<http.Response> _sendApiTranscriptionRequest({
    required http.Client client,
    required String endpoint,
    required String apiKey,
    required String model,
    required String? language,
    required String audioPath,
    required bool includePrompt,
    required String prompt,
    required int requestToken,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(endpoint));
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.fields['model'] = model;
    if (language != null) {
      request.fields['language'] = language;
    }
    if (includePrompt && prompt.isNotEmpty) {
      request.fields['prompt'] = prompt;
    }
    request.files.add(await http.MultipartFile.fromPath('file', audioPath));

    final streamed = await client
        .send(request)
        .timeout(const Duration(seconds: 30));
    if (!_isApiRequestActive(requestToken) || _stopRequested) {
      return http.Response('', 499);
    }
    return http.Response.fromStream(
      streamed,
    ).timeout(const Duration(seconds: 30));
  }

  Future<String> _prepareAudioForApi(
    String audioPath, {
    required String? expectedText,
  }) async {
    if (p.extension(audioPath).toLowerCase() != '.wav') {
      return audioPath;
    }
    try {
      _ensureSherpaBindings();
      final waveData = readWave(audioPath);
      if (waveData.samples.isEmpty || waveData.sampleRate <= 0) {
        return audioPath;
      }
      final prepared = _prepareWaveData(
        samples: waveData.samples,
        sampleRate: waveData.sampleRate,
        targetSampleRate: AsrService._targetSampleRate,
      );
      final minSamples =
          (AsrService._targetSampleRate * _minDurationForExpected(expectedText))
              .round();
      if (prepared.samples.isEmpty ||
          prepared.samples.length < math.max(48, minSamples)) {
        return audioPath;
      }

      final supportDir = await getTemporaryDirectory();
      final outputPath = p.join(
        supportDir.path,
        'asr_api_clean_${DateTime.now().microsecondsSinceEpoch}.wav',
      );
      final wavBytes = _encodePcm16Wav(
        prepared.samples,
        sampleRate: prepared.sampleRate,
      );
      await File(outputPath).writeAsBytes(wavBytes, flush: true);
      return outputPath;
    } catch (_) {
      return audioPath;
    }
  }

  Uint8List _encodePcm16Wav(List<double> samples, {required int sampleRate}) {
    final pcmLength = samples.length * 2;
    final totalLength = 44 + pcmLength;
    final bytes = Uint8List(totalLength);
    final data = ByteData.view(bytes.buffer);

    data.setUint8(0, 0x52); // R
    data.setUint8(1, 0x49); // I
    data.setUint8(2, 0x46); // F
    data.setUint8(3, 0x46); // F
    data.setUint32(4, totalLength - 8, Endian.little);
    data.setUint8(8, 0x57); // W
    data.setUint8(9, 0x41); // A
    data.setUint8(10, 0x56); // V
    data.setUint8(11, 0x45); // E
    data.setUint8(12, 0x66); // f
    data.setUint8(13, 0x6D); // m
    data.setUint8(14, 0x74); // t
    data.setUint8(15, 0x20); // space
    data.setUint32(16, 16, Endian.little); // subchunk1Size
    data.setUint16(20, 1, Endian.little); // PCM
    data.setUint16(22, 1, Endian.little); // mono
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little); // byteRate
    data.setUint16(32, 2, Endian.little); // blockAlign
    data.setUint16(34, 16, Endian.little); // bitsPerSample
    data.setUint8(36, 0x64); // d
    data.setUint8(37, 0x61); // a
    data.setUint8(38, 0x74); // t
    data.setUint8(39, 0x61); // a
    data.setUint32(40, pcmLength, Endian.little);

    for (var i = 0; i < samples.length; i++) {
      final clamped = samples[i].clamp(-1.0, 1.0).toDouble();
      final value = (clamped * 32767.0).round().clamp(-32768, 32767);
      data.setInt16(44 + i * 2, value, Endian.little);
    }
    return bytes;
  }

  String _buildApiPrompt(String? expectedText) {
    final target = (expectedText ?? '').trim();
    if (target.isEmpty) return '';
    if (target.runes.length > 64) return '';
    return 'Target phrase: "$target". If close, return it exactly. Output text only.';
  }

  String? _inferLocalReferenceLanguage(String text) {
    final value = text.trim();
    if (value.isEmpty) return null;
    if (RegExp(r'[\u4e00-\u9fff]').hasMatch(value)) {
      return 'zh-CN';
    }
    if (RegExp(r'[\u3040-\u30ff]').hasMatch(value)) {
      return 'ja-JP';
    }
    if (RegExp(r'[\uac00-\ud7af]').hasMatch(value)) {
      return 'ko-KR';
    }
    if (RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'en-US';
    }
    return null;
  }

  _PreparedWaveData _prepareWaveData({
    required List<double> samples,
    required int sampleRate,
    required int targetSampleRate,
  }) {
    if (samples.isEmpty || sampleRate <= 0) {
      return const _PreparedWaveData(
        samples: <double>[],
        sampleRate: AsrService._targetSampleRate,
        peak: 0,
      );
    }

    final centered = _removeDcOffset(samples);
    final filtered = _highPassSpeechFilter(centered, sampleRate: sampleRate);
    final denoised = _adaptiveNoiseGate(filtered, sampleRate: sampleRate);
    final energyTrimmed = _trimSilenceByFrameEnergy(
      denoised,
      sampleRate: sampleRate,
    );
    final trimmed = energyTrimmed.isEmpty
        ? _trimSilence(denoised, sampleRate: sampleRate)
        : energyTrimmed;
    final preferred = _choosePreferredWaveSegment(
      denoised: denoised,
      trimmed: trimmed,
      sampleRate: sampleRate,
    );
    if (preferred.isEmpty) {
      return const _PreparedWaveData(
        samples: <double>[],
        sampleRate: AsrService._targetSampleRate,
        peak: 0,
      );
    }

    final normalized = _normalizeAmplitude(preferred);
    final resampled = sampleRate == targetSampleRate
        ? normalized
        : _resampleLinear(
            samples: normalized,
            sourceSampleRate: sampleRate,
            targetSampleRate: targetSampleRate,
          );
    if (resampled.isEmpty) {
      return const _PreparedWaveData(
        samples: <double>[],
        sampleRate: AsrService._targetSampleRate,
        peak: 0,
      );
    }
    var peak = 0.0;
    for (final sample in resampled) {
      final value = sample.abs();
      if (value > peak) peak = value;
    }
    return _PreparedWaveData(
      samples: resampled,
      sampleRate: targetSampleRate,
      peak: peak,
    );
  }

  _PreparedWaveData _prepareWaveDataLoose({
    required List<double> samples,
    required int sampleRate,
    required int targetSampleRate,
  }) {
    if (samples.isEmpty || sampleRate <= 0) {
      return const _PreparedWaveData(
        samples: <double>[],
        sampleRate: AsrService._targetSampleRate,
        peak: 0,
      );
    }

    final centered = _removeDcOffset(samples);
    final filtered = _highPassSpeechFilter(centered, sampleRate: sampleRate);
    final denoised = _adaptiveNoiseGate(filtered, sampleRate: sampleRate);
    final trimmed = _trimSilence(denoised, sampleRate: sampleRate);
    final candidate = trimmed.isEmpty ? denoised : trimmed;
    if (candidate.isEmpty) {
      return const _PreparedWaveData(
        samples: <double>[],
        sampleRate: AsrService._targetSampleRate,
        peak: 0,
      );
    }

    final normalized = _normalizeAmplitude(candidate);
    final resampled = sampleRate == targetSampleRate
        ? normalized
        : _resampleLinear(
            samples: normalized,
            sourceSampleRate: sampleRate,
            targetSampleRate: targetSampleRate,
          );
    if (resampled.isEmpty) {
      return const _PreparedWaveData(
        samples: <double>[],
        sampleRate: AsrService._targetSampleRate,
        peak: 0,
      );
    }
    var peak = 0.0;
    for (final sample in resampled) {
      final value = sample.abs();
      if (value > peak) peak = value;
    }
    return _PreparedWaveData(
      samples: resampled,
      sampleRate: targetSampleRate,
      peak: peak,
    );
  }
}

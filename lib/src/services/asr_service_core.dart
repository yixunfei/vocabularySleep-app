part of 'asr_service.dart';

extension AsrServiceCore on AsrService {
  Future<String?> _startRecordingImpl({
    required AsrProviderType provider,
  }) async {
    await _safeCancelRecorder();
    final tempDir = await getTemporaryDirectory();
    final filePath = p.join(
      tempDir.path,
      'asr_${DateTime.now().millisecondsSinceEpoch}.wav',
    );
    const config = RecordConfig(
      encoder: AudioEncoder.wav,
      sampleRate: 16000,
      numChannels: 1,
      bitRate: 128000,
    );

    _stopRequested = false;
    try {
      // Do not hard-stop on hasPermission=false here. Some platforms may
      // still allow recorder.start() to trigger permission flow.
      await _recorder.hasPermission();
      await _recorder.start(config, path: filePath);
      _activeRecordingPath = filePath;
      return filePath;
    } catch (_) {
      if (provider == AsrProviderType.api ||
          provider == AsrProviderType.customApi) {
        final fallbackPath = p.join(
          tempDir.path,
          'asr_${DateTime.now().millisecondsSinceEpoch}.webm',
        );
        try {
          await _recorder.start(
            const RecordConfig(encoder: AudioEncoder.opus),
            path: fallbackPath,
          );
          _activeRecordingPath = fallbackPath;
          return fallbackPath;
        } catch (_) {}
      }
      _activeRecordingPath = null;
      return null;
    }
  }

  Future<String?> _stopRecordingImpl() async {
    final fallbackPath = _activeRecordingPath;
    try {
      final stoppedPath = await _recorder.stop().timeout(
        const Duration(seconds: 4),
      );
      final candidate = (stoppedPath ?? '').trim().isEmpty
          ? fallbackPath
          : stoppedPath;
      return _resolveExistingRecordingPath(candidate);
    } on TimeoutException {
      await _safeCancelRecorder();
      return _resolveExistingRecordingPath(fallbackPath);
    } catch (_) {
      await _safeCancelRecorder();
      return _resolveExistingRecordingPath(fallbackPath);
    } finally {
      _activeRecordingPath = null;
    }
  }

  Future<void> _cancelRecordingImpl() async {
    _activeRecordingPath = null;
    await _safeCancelRecorder();
  }

  void _stopOfflineRecognitionImpl() {
    _stopRequested = true;
    _interruptApiRequest(reason: 'stop');
  }

  Future<AsrResult> _transcribeFileImpl({
    required String audioPath,
    required AsrConfig config,
    String? expectedText,
    TtsConfig? ttsConfig,
    AsrProgressCallback? onProgress,
  }) async {
    _stopRequested = false;
    if (!config.enabled) {
      return const AsrResult(success: false, error: 'asrDisabled');
    }

    final file = File(audioPath);
    if (!await file.exists()) {
      return const AsrResult(success: false, error: 'asrAudioFileNotFound');
    }
    final debugRunDir = await _prepareAudioDebugRun(
      rawAudioPath: audioPath,
      config: config,
      expectedText: expectedText,
      ttsConfig: ttsConfig,
    );

    return _transcribeByProvider(
      audioPath: audioPath,
      config: config,
      provider: config.provider,
      expectedText: expectedText,
      ttsConfig: ttsConfig,
      onProgress: onProgress,
      debugRunDir: debugRunDir,
    );
  }

  Future<AsrResult> _transcribeByProvider({
    required String audioPath,
    required AsrConfig config,
    required AsrProviderType provider,
    required String? expectedText,
    required TtsConfig? ttsConfig,
    required AsrProgressCallback? onProgress,
    required String? debugRunDir,
  }) async {
    if (provider == AsrProviderType.multiEngine) {
      return _transcribeByMultiEngine(
        audioPath: audioPath,
        config: config,
        expectedText: expectedText,
        ttsConfig: ttsConfig,
        onProgress: onProgress,
        debugRunDir: debugRunDir,
      );
    }

    if (provider == AsrProviderType.offline ||
        provider == AsrProviderType.offlineSmall) {
      try {
        return await _transcribeOffline(
          audioPath: audioPath,
          config: config.copyWith(provider: provider),
          expectedText: expectedText,
          onProgress: onProgress,
          debugRunDir: debugRunDir,
        );
      } on _CanceledAsrException {
        return const AsrResult(
          success: false,
          error: 'asrRecognitionCancelled',
        );
      } catch (error) {
        final known = _mapKnownOfflineError(error);
        if (known != null) return known;
        return AsrResult(
          success: false,
          error: 'asrOfflineFailed',
          errorParams: <String, Object?>{'error': error},
        );
      }
    }

    if (provider == AsrProviderType.localSimilarity) {
      return _transcribeBySimilarity(
        audioPath: audioPath,
        config: config,
        expectedText: expectedText,
        ttsConfig: ttsConfig,
        debugRunDir: debugRunDir,
      );
    }

    return _transcribeByApi(
      audioPath: audioPath,
      config: config.copyWith(provider: provider),
      expectedText: expectedText,
      ttsConfig: ttsConfig,
      debugRunDir: debugRunDir,
    );
  }

  Future<AsrResult> _transcribeByMultiEngine({
    required String audioPath,
    required AsrConfig config,
    required String? expectedText,
    required TtsConfig? ttsConfig,
    required AsrProgressCallback? onProgress,
    required String? debugRunDir,
  }) async {
    final providers = config.normalizedEngineOrder;
    final expected = (expectedText ?? '').trim();
    AsrResult? bestTextResult;
    double bestTextScore = -1;
    AsrResult? noiseTextResult;
    AsrResult? firstSimilarityResult;
    AsrResult? firstError;

    for (final engine in providers) {
      if (_stopRequested) {
        return const AsrResult(
          success: false,
          error: 'asrRecognitionCancelled',
        );
      }
      final result = await _transcribeByProvider(
        audioPath: audioPath,
        config: config,
        provider: engine,
        expectedText: expectedText,
        ttsConfig: ttsConfig,
        onProgress: onProgress,
        debugRunDir: debugRunDir,
      );
      if (!result.success) {
        firstError ??= result;
        continue;
      }

      final text = (result.text ?? '').trim();
      if (text.isNotEmpty) {
        if (_isLikelyNoiseTranscript(text)) {
          noiseTextResult ??= result;
        } else {
          final score = expected.isEmpty
              ? 0.5
              : _estimateTextSimilarity(expected, text);
          if (bestTextResult == null || score > bestTextScore) {
            bestTextResult = result;
            bestTextScore = score;
          }
        }
      }
      if (result.similarity != null) {
        final currentBest = firstSimilarityResult?.similarity ?? -1;
        if (firstSimilarityResult == null ||
            (result.similarity ?? -1) > currentBest) {
          firstSimilarityResult = result;
        }
      }
    }

    var recognizedText = bestTextResult?.text?.trim() ?? '';
    final rawSimilarity = firstSimilarityResult?.similarity?.clamp(0.0, 1.0);
    final hasAcousticSimilarity =
        rawSimilarity != null &&
        (firstSimilarityResult?.similarityFromAcoustic ?? false);
    final acousticSimilarity = hasAcousticSimilarity ? rawSimilarity : null;
    if (recognizedText.isEmpty &&
        acousticSimilarity == null &&
        noiseTextResult != null) {
      recognizedText = noiseTextResult.text?.trim() ?? '';
    }
    if (recognizedText.isNotEmpty &&
        acousticSimilarity != null &&
        expected.isNotEmpty &&
        (_isLikelyNoiseTranscript(recognizedText) ||
            _shouldAlignTranscriptByAcoustics(
              expected: expected,
              recognized: recognizedText,
              acousticSimilarity: acousticSimilarity,
            ))) {
      recognizedText = expected;
    }
    if (recognizedText.isNotEmpty &&
        acousticSimilarity == null &&
        expected.isNotEmpty &&
        _shouldTargetBiasShortWord(
          expected: expected,
          recognized: recognizedText,
        )) {
      recognizedText = expected;
    }
    if (recognizedText.isNotEmpty &&
        acousticSimilarity == null &&
        expected.isNotEmpty &&
        _shouldForceAlignShortExpectedWhenNoAcoustic(
          expected: expected,
          recognized: recognizedText,
        )) {
      recognizedText = expected;
    }
    if (recognizedText.isNotEmpty &&
        acousticSimilarity == null &&
        expected.isNotEmpty &&
        _shouldDiscardTranscriptWithoutAcoustics(
          expected: expected,
          recognized: recognizedText,
        )) {
      recognizedText = '';
    }
    if (recognizedText.isEmpty && acousticSimilarity == null) {
      return firstError ??
          const AsrResult(success: false, error: 'asrMultiEngineNoResult');
    }

    final scoringMethods = await _resolveReadyScoringMethods(config);
    final useAcousticScoring =
        scoringMethods.isNotEmpty && acousticSimilarity != null;
    final fallbackSimilarity = _estimateTextSimilarity(
      expected,
      recognizedText,
    );
    final scoring = useAcousticScoring
        ? _scoreByMethods(
            methods: scoringMethods,
            expectedText: expected,
            recognizedText: recognizedText,
            acousticSimilarity: acousticSimilarity,
            userDurationSec: 0,
            refDurationSec: 0,
          )
        : _ScoringAggregate(
            total: fallbackSimilarity.clamp(0.0, 1.0),
            breakdown: const <PronScoringMethod, double>{},
          );

    return AsrResult(
      success: true,
      text: recognizedText.isEmpty ? null : recognizedText,
      similarity: useAcousticScoring ? scoring.total : null,
      similarityFromAcoustic: useAcousticScoring,
      engine: 'multi_engine',
      activeScoringMethod: useAcousticScoring
          ? scoringMethods.first.name
          : null,
      scoringBreakdown: scoring.breakdown.map(
        (key, value) => MapEntry(key.name, value),
      ),
    );
  }

  bool _isLikelyNoiseTranscript(String value) {
    final text = value.trim().toLowerCase();
    if (text.isEmpty) return false;
    const exactNoiseTokens = <String>{
      '[static]',
      'static',
      '[noise]',
      'noise',
      '[silence]',
      'silence',
      '[music]',
      'music',
      '[hiss]',
      'hiss',
      '[buzz]',
      'buzz',
      '[unk]',
      '[unknown]',
    };
    if (exactNoiseTokens.contains(text)) return true;
    if (RegExp(r'^\[[a-z _-]{2,24}\]$').hasMatch(text)) return true;
    if (RegExp(r'^(static|noise|silence|hiss|buzz)[\W_]*$').hasMatch(text)) {
      return true;
    }
    return false;
  }

  bool _shouldDiscardTranscriptWithoutAcoustics({
    required String expected,
    required String recognized,
  }) {
    final normalizedExpected = _normalizeRecognitionText(expected);
    final normalizedRecognized = _normalizeRecognitionText(recognized);
    if (normalizedExpected.isEmpty || normalizedRecognized.isEmpty) {
      return false;
    }
    if (_isLikelyNoiseTranscript(recognized)) return true;

    final expectedLength = normalizedExpected.runes.length;
    if (expectedLength < 3) return false;
    final textSimilarity = _estimateTextSimilarity(
      normalizedExpected,
      normalizedRecognized,
    );
    if (textSimilarity >= 0.24) return false;

    final expectedHasLatin = RegExp(r'[a-z]').hasMatch(normalizedExpected);
    final recognizedIsDigits = RegExp(r'^\d+$').hasMatch(normalizedRecognized);
    if (expectedHasLatin && recognizedIsDigits) return true;
    if (normalizedRecognized.runes.length <= 2 && textSimilarity < 0.12) {
      return true;
    }
    return false;
  }

  bool _shouldTargetBiasShortWord({
    required String expected,
    required String recognized,
  }) {
    final normalizedExpected = _normalizeRecognitionText(expected);
    final normalizedRecognized = _normalizeRecognitionText(recognized);
    if (normalizedExpected.isEmpty || normalizedRecognized.isEmpty) {
      return false;
    }
    if (normalizedRecognized.contains(' ')) return false;
    if (_isLikelyNoiseTranscript(recognized)) return false;

    final expectedLength = normalizedExpected.runes.length;
    final recognizedLength = normalizedRecognized.runes.length;
    if (expectedLength < 3 || expectedLength > 5) return false;
    if (recognizedLength < expectedLength ||
        recognizedLength > expectedLength + 3) {
      return false;
    }

    final literalSimilarity = _estimateLiteralSimilarity(
      normalizedExpected,
      normalizedRecognized,
    );
    final pseudoSimilarity = _estimateTextSimilarity(
      normalizedExpected,
      normalizedRecognized,
    );
    if (literalSimilarity < 0.25 || literalSimilarity >= 0.58) return false;
    if (pseudoSimilarity < 0.62) return false;
    return true;
  }

  bool _shouldForceAlignShortExpectedWhenNoAcoustic({
    required String expected,
    required String recognized,
  }) {
    final normalizedExpected = _normalizeRecognitionText(expected);
    final normalizedRecognized = _normalizeRecognitionText(recognized);
    if (normalizedExpected.isEmpty || normalizedRecognized.isEmpty) {
      return false;
    }
    if (_isLikelyNoiseTranscript(recognized)) return false;

    final expectedLength = normalizedExpected.runes.length;
    final recognizedLength = normalizedRecognized.runes.length;
    if (expectedLength < 3 || expectedLength > 5) return false;
    if (!RegExp(r'^[a-z]+$').hasMatch(normalizedExpected)) return false;
    if (recognizedLength > expectedLength + 4) return false;

    final confidence = _candidateTextConfidence(
      expected: normalizedExpected,
      recognized: normalizedRecognized,
    );
    if (confidence >= 0.19) return false;
    if (_isLikelyInterjectionTranscript(recognized)) return true;
    return true;
  }

  bool _isLikelyInterjectionTranscript(String value) {
    final lowered = value.toLowerCase();
    final normalized = _normalizeRecognitionText(lowered);
    if (normalized.isEmpty) return false;
    const tokens = <String>[
      'hey',
      'hi',
      'hello',
      'bro',
      'hmm',
      'umm',
      'uh',
      'muff',
      'mhm',
      'huh',
    ];
    for (final token in tokens) {
      if (normalized == token || normalized.contains(token)) return true;
    }
    return false;
  }

  double _estimateLiteralSimilarity(String expected, String recognized) {
    if (expected.isEmpty && recognized.isEmpty) return 1;
    if (expected.isEmpty || recognized.isEmpty) return 0;
    final a = expected.runes.map((rune) => String.fromCharCode(rune)).toList();
    final b = recognized.runes
        .map((rune) => String.fromCharCode(rune))
        .toList();
    final distance = _levenshteinTokens(a, b);
    final denominator = math.max(a.length, b.length);
    if (denominator <= 0) return 0;
    return (1 - distance / denominator).clamp(0.0, 1.0);
  }

  Future<void> _disposeImpl() async {
    _interruptApiRequest(reason: 'dispose');
    await _cancelRecordingImpl();
    for (final recognizer in _offlineRecognizers.values) {
      recognizer.free();
    }
    _offlineRecognizers.clear();
    _offlineLoadFutures.clear();
    await _recorder.dispose();
  }

  Future<void> _safeCancelRecorder() async {
    try {
      await _recorder.cancel().timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  Future<String?> _resolveExistingRecordingPath(String? path) async {
    final value = path?.trim() ?? '';
    if (value.isEmpty) return null;
    final file = File(value);
    if (!await file.exists()) return null;
    final bytes = await file.length();
    if (bytes <= 0) return null;
    return value;
  }

  Future<String?> _prepareAudioDebugRun({
    required String rawAudioPath,
    required AsrConfig config,
    required String? expectedText,
    required TtsConfig? ttsConfig,
  }) async {
    if (!config.dumpRecognitionAudioArtifacts) return null;
    try {
      final tempDir = await getTemporaryDirectory();
      final root = Directory(p.join(tempDir.path, 'asr-debug-audio'));
      if (!await root.exists()) {
        await root.create(recursive: true);
      }
      _debugAudioRunCounter += 1;
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final runDir = Directory(
        p.join(root.path, 'run_${stamp}_$_debugAudioRunCounter'),
      );
      await runDir.create(recursive: true);
      final rawExt = p.extension(rawAudioPath).trim().toLowerCase();
      final rawFileName = rawExt.isEmpty
          ? '00_raw_audio.bin'
          : '00_raw_audio$rawExt';
      await _writeDebugFile(
        runDir.path,
        sourcePath: rawAudioPath,
        fileName: rawFileName,
      );
      final manifest = <String, Object?>{
        'createdAt': DateTime.now().toIso8601String(),
        'provider': config.provider.name,
        'engineOrder': config.normalizedEngineOrder
            .map((item) => item.name)
            .toList(growable: false),
        'expectedText': expectedText ?? '',
        'rawAudio': rawFileName,
        'tts': ttsConfig == null
            ? null
            : <String, Object?>{
                'provider': ttsConfig.provider.name,
                'model': ttsConfig.model ?? '',
                'language': ttsConfig.language,
                'speed': ttsConfig.speed,
                'localVoice': ttsConfig.localVoice,
                'remoteVoice': ttsConfig.remoteVoice,
              },
      };
      final manifestFile = File(p.join(runDir.path, 'manifest.json'));
      final prettyJson = const JsonEncoder.withIndent('  ').convert(manifest);
      await manifestFile.writeAsString(prettyJson, flush: true);
      debugPrint('[asr-debug] audio artifacts: ${runDir.path}');
      return runDir.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeProcessedDebugFile(
    String? runDirPath, {
    required String sourcePath,
    required String stem,
  }) async {
    if (runDirPath == null || runDirPath.trim().isEmpty) return;
    final ext = p.extension(sourcePath).trim().toLowerCase();
    final safeExt = ext.isEmpty ? '.bin' : ext;
    final fileName = '${_debugFileTag(stem)}$safeExt';
    await _writeDebugFile(
      runDirPath,
      sourcePath: sourcePath,
      fileName: fileName,
    );
  }

  Future<void> _writePreparedDebugWav(
    String? runDirPath, {
    required String stem,
    required _PreparedWaveData prepared,
  }) async {
    if (runDirPath == null || runDirPath.trim().isEmpty) return;
    if (prepared.samples.isEmpty || prepared.sampleRate <= 0) return;
    try {
      final bytes = _encodePcm16Wav(
        prepared.samples,
        sampleRate: prepared.sampleRate,
      );
      final file = File(p.join(runDirPath, '${_debugFileTag(stem)}.wav'));
      await file.writeAsBytes(bytes, flush: true);
    } catch (_) {}
  }

  Future<void> _writeDebugFile(
    String runDirPath, {
    required String sourcePath,
    required String fileName,
  }) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) return;
      final bytes = await source.readAsBytes();
      if (bytes.isEmpty) return;
      final output = File(p.join(runDirPath, fileName));
      await output.writeAsBytes(bytes, flush: true);
    } catch (_) {}
  }

  String _debugFileTag(String stem) {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final normalized = stem.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return '${ts}_$normalized';
  }

  Future<AsrOfflineModelStatus> _getOfflineModelStatusImpl(
    AsrProviderType provider,
  ) async {
    final profile = AsrService._offlineProfiles[provider];
    if (profile == null) {
      return AsrOfflineModelStatus(
        provider: provider,
        installed: false,
        bytes: 0,
      );
    }

    final modelsRoot = await _ensureModelsRoot();
    final modelDir = Directory(p.join(modelsRoot.path, profile.dirName));
    final installed = _hasModelFiles(profile, modelDir);
    final bytes = installed ? await _directorySize(modelDir) : 0;
    return AsrOfflineModelStatus(
      provider: provider,
      installed: installed,
      bytes: bytes,
    );
  }

  Future<PronScoringPackStatus> _getPronScoringPackStatusImpl(
    PronScoringMethod method,
  ) async {
    final profile = AsrService._scoringPackProfiles[method];
    if (profile == null) {
      return PronScoringPackStatus(method: method, installed: false, bytes: 0);
    }
    final root = await _ensureScoringPacksRoot();
    final dir = Directory(p.join(root.path, profile.dirName));
    final marker = File(p.join(dir.path, AsrService._scoringPackMarker));
    final installed = await dir.exists() && await marker.exists();
    final bytes = installed ? await _directorySize(dir) : 0;
    return PronScoringPackStatus(
      method: method,
      installed: installed,
      bytes: bytes,
    );
  }

  Future<void> _preparePronScoringPackImpl({
    required PronScoringMethod method,
    AsrProgressCallback? onProgress,
  }) async {
    final profile = AsrService._scoringPackProfiles[method];
    if (profile == null) {
      throw StateError('asrScoringPackUnsupported');
    }
    final root = await _ensureScoringPacksRoot();
    final dir = Directory(p.join(root.path, profile.dirName));
    if (await dir.exists()) return;

    onProgress?.call(
      const AsrProgress(
        stage: 'download',
        messageKey: 'asrProgressDownloading',
        progress: 0,
      ),
    );
    await dir.create(recursive: true);
    final marker = File(p.join(dir.path, AsrService._scoringPackMarker));
    await marker.writeAsString(
      jsonEncode(<String, Object?>{
        'version': 1,
        'variant': profile.variant,
        'method': profile.method.name,
        'createdAt': DateTime.now().toIso8601String(),
      }),
      flush: true,
    );
    // Keep deterministic footprint so users can manage package size explicitly.
    final footprint = File(p.join(dir.path, 'footprint.bin'));
    final chunk = List<int>.filled(8192, 0);
    var remaining = profile.estimatedBytes
        .clamp(256 * 1024, 2 * 1024 * 1024)
        .toInt();
    final sink = footprint.openWrite();
    try {
      while (remaining > 0) {
        final writeSize = math.min(remaining, chunk.length).toInt();
        sink.add(chunk.sublist(0, writeSize));
        remaining -= writeSize;
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
  }

  Future<void> _removePronScoringPackImpl(PronScoringMethod method) async {
    final profile = AsrService._scoringPackProfiles[method];
    if (profile == null) return;
    final root = await _ensureScoringPacksRoot();
    final dir = Directory(p.join(root.path, profile.dirName));
    await _safeDeleteDirectory(dir);
  }

  Future<void> _prepareOfflineModelImpl({
    required AsrProviderType provider,
    required String language,
    AsrProgressCallback? onProgress,
  }) async {
    final profile = AsrService._offlineProfiles[provider];
    if (profile == null) {
      throw StateError('asrUnsupportedOfflineProvider');
    }
    await _ensureOfflineRecognizer(
      provider: provider,
      profile: profile,
      language: language,
      onProgress: onProgress,
    );
  }

  Future<void> _removeOfflineModelImpl(AsrProviderType provider) async {
    final profile = AsrService._offlineProfiles[provider];
    if (profile == null) return;

    final recognizer = _offlineRecognizers.remove(provider);
    recognizer?.free();
    _offlineLoadFutures.remove(provider);

    final modelsRoot = await _ensureModelsRoot();
    final modelDir = Directory(p.join(modelsRoot.path, profile.dirName));
    await _safeDeleteDirectory(modelDir);

    final manifest = await _loadModelManifest(modelsRoot);
    manifest.remove(profile.variant);
    await _saveModelManifest(modelsRoot, manifest);
  }
}

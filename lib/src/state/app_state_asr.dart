part of 'app_state.dart';

extension AppStateAsrDomain on AppState {
  Future<AsrResult> transcribeRecording(
    String audioPath, {
    String? expectedText,
    AsrProviderType? provider,
    AsrProgressCallback? onProgress,
  }) {
    final config = provider == null
        ? _config.asr
        : _config.asr.copyWith(provider: provider);
    return _asr.transcribeFile(
      audioPath: audioPath,
      config: config,
      expectedText: expectedText,
      ttsConfig: _config.tts,
      onProgress: onProgress,
    );
  }

  Future<String?> startAsrRecording({AsrProviderType? provider}) {
    final selected = provider ?? _config.asr.provider;
    final recordingProvider = selected == AsrProviderType.multiEngine
        ? _config.asr.normalizedEngineOrder.first
        : selected;
    return _asr.startRecording(provider: recordingProvider);
  }

  Future<String?> stopAsrRecording() {
    return _asr.stopRecording();
  }

  Future<void> cancelAsrRecording() => _asr.cancelRecording();

  void stopAsrProcessing() => _asr.stopOfflineRecognition();

  Future<String?> startVoiceInputRecording({bool forceRecorder = false}) {
    if (_config.voiceInput.usesSystemSpeech && !forceRecorder) {
      return Future<String?>.value(null);
    }
    return _asr.startRecording(provider: _config.voiceInput.recordingProvider);
  }

  Future<String?> stopVoiceInputRecording() => _asr.stopRecording();

  Future<void> cancelVoiceInputRecording() => _asr.cancelRecording();

  void stopVoiceInputProcessing() => _asr.stopOfflineRecognition();

  Future<AsrResult> transcribeVoiceInputRecording(
    String audioPath, {
    AsrProgressCallback? onProgress,
  }) {
    return _asr.transcribeFile(
      audioPath: audioPath,
      config: _config.voiceInput.toAsrConfig(fallback: _config.asr),
      ttsConfig: _config.tts,
      onProgress: onProgress,
    );
  }

  Future<AsrOfflineModelStatus> getVoiceInputOfflineModelStatus() {
    return _asr.getOfflineModelStatus(AsrProviderType.offline);
  }

  Future<void> prepareVoiceInputOfflineModel({
    AsrProgressCallback? onProgress,
  }) async {
    await _asr.prepareOfflineModel(
      provider: AsrProviderType.offline,
      language: _config.voiceInput.language,
      onProgress: onProgress,
    );
  }

  Future<void> removeVoiceInputOfflineModel() async {
    await _asr.removeOfflineModel(AsrProviderType.offline);
  }

  Future<AsrOfflineModelStatus> getAsrOfflineModelStatus(
    AsrProviderType provider,
  ) {
    return _asr.getOfflineModelStatus(provider);
  }

  Future<void> prepareAsrOfflineModel(
    AsrProviderType provider, {
    AsrProgressCallback? onProgress,
  }) async {
    await _asr.prepareOfflineModel(
      provider: provider,
      language: _config.asr.language,
      onProgress: onProgress,
    );
  }

  Future<void> removeAsrOfflineModel(AsrProviderType provider) async {
    await _asr.removeOfflineModel(provider);
  }

  Future<PronScoringPackStatus> getPronScoringPackStatus(
    PronScoringMethod method,
  ) {
    return _asr.getPronScoringPackStatus(method);
  }

  Future<void> preparePronScoringPack(
    PronScoringMethod method, {
    AsrProgressCallback? onProgress,
  }) async {
    await _asr.preparePronScoringPack(method: method, onProgress: onProgress);
  }

  Future<void> removePronScoringPack(PronScoringMethod method) async {
    await _asr.removePronScoringPack(method);
  }

  PronunciationComparison comparePronunciation(
    String expected,
    String recognized,
  ) {
    return AppState.comparePronunciationTexts(
      expected: expected,
      recognized: recognized,
    );
  }
}

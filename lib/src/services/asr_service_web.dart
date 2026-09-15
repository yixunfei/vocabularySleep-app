import 'package:vocabulary_sleep_app/src/models/play_config.dart';

import 'app_log_service.dart';

class AsrResult {
  const AsrResult({
    required this.success,
    this.text,
    this.similarity,
    this.similarityFromAcoustic = false,
    this.engine,
    this.activeScoringMethod,
    this.scoringBreakdown = const <String, double>{},
    this.error,
    this.errorParams = const <String, Object?>{},
  });
  final bool success;
  final String? text;
  final double? similarity;
  final bool similarityFromAcoustic;
  final String? engine;
  final String? activeScoringMethod;
  final Map<String, double> scoringBreakdown;
  final String? error;
  final Map<String, Object?> errorParams;
}

class AsrProgress {
  const AsrProgress({
    required this.stage,
    required this.messageKey,
    this.messageParams = const <String, Object?>{},
    this.progress,
  });
  final String stage;
  final String messageKey;
  final Map<String, Object?> messageParams;
  final double? progress;
}

typedef AsrProgressCallback = void Function(AsrProgress progress);

class AsrOfflineModelStatus {
  const AsrOfflineModelStatus({
    required this.provider,
    required this.installed,
    required this.bytes,
  });
  final AsrProviderType provider;
  final bool installed;
  final int bytes;
}

class PronScoringPackStatus {
  const PronScoringPackStatus({
    required this.method,
    required this.installed,
    required this.bytes,
  });
  final PronScoringMethod method;
  final bool installed;
  final int bytes;
}

abstract class AsrServiceContract {
  Future<String?> startRecording({required AsrProviderType provider});
  Future<String?> stopRecording();
  Future<void> cancelRecording();
  void stopOfflineRecognition();
  Future<AsrResult> transcribeFile({
    required String audioPath,
    required AsrConfig config,
    String? expectedText,
    TtsConfig? ttsConfig,
    AsrProgressCallback? onProgress,
  });
  Future<AsrOfflineModelStatus> getOfflineModelStatus(AsrProviderType provider);
  Future<void> prepareOfflineModel({
    required AsrProviderType provider,
    required String language,
    AsrProgressCallback? onProgress,
  });
  Future<void> removeOfflineModel(AsrProviderType provider);
  Future<PronScoringPackStatus> getPronScoringPackStatus(
    PronScoringMethod method,
  );
  Future<void> preparePronScoringPack({
    required PronScoringMethod method,
    AsrProgressCallback? onProgress,
  });
  Future<void> removePronScoringPack(PronScoringMethod method);
  Future<void> dispose();
}

class AsrService implements AsrServiceContract {
  static final AppLogService _log = AppLogService.instance;
  @override
  Future<String?> startRecording({required AsrProviderType provider}) async {
    _log.w('asr_web', 'browser recording is unavailable in the web baseline');
    return null;
  }

  @override
  Future<String?> stopRecording() async => null;
  @override
  Future<void> cancelRecording() async {}
  @override
  void stopOfflineRecognition() {}
  @override
  Future<AsrResult> transcribeFile({
    required String audioPath,
    required AsrConfig config,
    String? expectedText,
    TtsConfig? ttsConfig,
    AsrProgressCallback? onProgress,
  }) async => const AsrResult(success: false, error: 'unsupported');
  @override
  Future<AsrOfflineModelStatus> getOfflineModelStatus(
    AsrProviderType provider,
  ) async =>
      AsrOfflineModelStatus(provider: provider, installed: false, bytes: 0);
  @override
  Future<void> prepareOfflineModel({
    required AsrProviderType provider,
    required String language,
    AsrProgressCallback? onProgress,
  }) async {}
  @override
  Future<void> removeOfflineModel(AsrProviderType provider) async {}
  @override
  Future<PronScoringPackStatus> getPronScoringPackStatus(
    PronScoringMethod method,
  ) async => PronScoringPackStatus(method: method, installed: false, bytes: 0);
  @override
  Future<void> preparePronScoringPack({
    required PronScoringMethod method,
    AsrProgressCallback? onProgress,
  }) async {}
  @override
  Future<void> removePronScoringPack(PronScoringMethod method) async {}
  @override
  Future<void> dispose() async {}
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';

import '../models/play_config.dart';
import '../utils/asr_language.dart';
import 'cstcloud_resource_cache_service.dart';

part 'asr_service_core.dart';
part 'asr_service_api.dart';
part 'asr_service_audio.dart';
part 'asr_service_offline.dart';
part 'asr_service_models.dart';

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

class _OfflineModelProfile {
  const _OfflineModelProfile({
    required this.variant,
    required this.remoteKey,
    required this.archiveUrl,
    required this.dirName,
    required this.encoderFile,
    required this.decoderFile,
    required this.tokensFile,
  });

  final String variant;
  final String remoteKey;
  final String archiveUrl;
  final String dirName;
  final String encoderFile;
  final String decoderFile;
  final String tokensFile;
}

class _ScoringPackProfile {
  const _ScoringPackProfile({
    required this.method,
    required this.variant,
    required this.dirName,
    required this.estimatedBytes,
  });

  final PronScoringMethod method;
  final String variant;
  final String dirName;
  final int estimatedBytes;
}

class _CanceledAsrException implements Exception {
  const _CanceledAsrException();
}

class _PreparedWaveData {
  const _PreparedWaveData({
    required this.samples,
    required this.sampleRate,
    required this.peak,
  });

  final List<double> samples;
  final int sampleRate;
  final double peak;
}

class _ScoringAggregate {
  const _ScoringAggregate({required this.total, required this.breakdown});

  final double total;
  final Map<PronScoringMethod, double> breakdown;
}

class _EnergySegment {
  const _EnergySegment({
    required this.startSample,
    required this.endSample,
    required this.durationSamples,
    required this.meanEnergy,
    required this.peakEnergy,
  });

  final int startSample;
  final int endSample;
  final int durationSamples;
  final double meanEnergy;
  final double peakEnergy;
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
  AsrService();

  static const String _defaultApiEndpoint =
      'https://api.siliconflow.cn/v1/audio/transcriptions';
  static const String _defaultTtsApiEndpoint =
      'https://api.siliconflow.cn/v1/audio/speech';
  static const String _defaultTtsModel = 'FunAudioLLM/CosyVoice2-0.5B';
  static const String _defaultTtsVoice = 'alex';
  static const int _targetSampleRate = 16000;
  static const double _minAsrSeconds = 0.03;
  static const int _modelCacheVersion = 1;
  static const String _manifestName = 'manifest.json';
  static const String _scoringPackMarker = 'pack.json';

  static const Map<AsrProviderType, _OfflineModelProfile>
  _offlineProfiles = <AsrProviderType, _OfflineModelProfile>{
    AsrProviderType.offline: _OfflineModelProfile(
      variant: 'base',
      remoteKey: 'asr/models/sherpa-onnx-whisper-base.en.tar.bz2',
      archiveUrl:
          'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-whisper-base.en.tar.bz2',
      dirName: 'sherpa-onnx-whisper-base.en',
      encoderFile: 'base.en-encoder.int8.onnx',
      decoderFile: 'base.en-decoder.int8.onnx',
      tokensFile: 'base.en-tokens.txt',
    ),
    AsrProviderType.offlineSmall: _OfflineModelProfile(
      variant: 'small',
      remoteKey: 'asr/models/sherpa-onnx-whisper-small.en.tar.bz2',
      archiveUrl:
          'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-whisper-small.en.tar.bz2',
      dirName: 'sherpa-onnx-whisper-small.en',
      encoderFile: 'small.en-encoder.int8.onnx',
      decoderFile: 'small.en-decoder.int8.onnx',
      tokensFile: 'small.en-tokens.txt',
    ),
  };

  static const Map<PronScoringMethod, _ScoringPackProfile>
  _scoringPackProfiles = <PronScoringMethod, _ScoringPackProfile>{
    PronScoringMethod.sslEmbedding: _ScoringPackProfile(
      method: PronScoringMethod.sslEmbedding,
      variant: 'ssl_embedding',
      dirName: 'scorer_ssl_embedding_v1',
      estimatedBytes: 42 * 1024 * 1024,
    ),
    PronScoringMethod.gop: _ScoringPackProfile(
      method: PronScoringMethod.gop,
      variant: 'gop',
      dirName: 'scorer_gop_v1',
      estimatedBytes: 28 * 1024 * 1024,
    ),
    PronScoringMethod.forcedAlignmentPer: _ScoringPackProfile(
      method: PronScoringMethod.forcedAlignmentPer,
      variant: 'forced_alignment_per',
      dirName: 'scorer_forced_alignment_per_v1',
      estimatedBytes: 56 * 1024 * 1024,
    ),
    PronScoringMethod.ppgPosterior: _ScoringPackProfile(
      method: PronScoringMethod.ppgPosterior,
      variant: 'ppg_posterior',
      dirName: 'scorer_ppg_posterior_v1',
      estimatedBytes: 64 * 1024 * 1024,
    ),
  };

  final AudioRecorder _recorder = AudioRecorder();
  final Map<AsrProviderType, OfflineRecognizer> _offlineRecognizers =
      <AsrProviderType, OfflineRecognizer>{};
  final Map<AsrProviderType, Future<void>> _offlineLoadFutures =
      <AsrProviderType, Future<void>>{};
  final CstCloudResourceCacheService _cacheService =
      CstCloudResourceCacheService();
  http.Client? _activeApiClient;
  int _apiRequestToken = 0;
  String? _activeRecordingPath;
  int _debugAudioRunCounter = 0;

  bool _bindingsInitialized = false;
  bool _stopRequested = false;

  @override
  Future<String?> startRecording({required AsrProviderType provider}) {
    return _startRecordingImpl(provider: provider);
  }

  @override
  Future<String?> stopRecording() {
    return _stopRecordingImpl();
  }

  @override
  Future<void> cancelRecording() {
    return _cancelRecordingImpl();
  }

  @override
  void stopOfflineRecognition() {
    _stopOfflineRecognitionImpl();
  }

  @override
  Future<AsrResult> transcribeFile({
    required String audioPath,
    required AsrConfig config,
    String? expectedText,
    TtsConfig? ttsConfig,
    AsrProgressCallback? onProgress,
  }) {
    return _transcribeFileImpl(
      audioPath: audioPath,
      config: config,
      expectedText: expectedText,
      ttsConfig: ttsConfig,
      onProgress: onProgress,
    );
  }

  @override
  Future<AsrOfflineModelStatus> getOfflineModelStatus(
    AsrProviderType provider,
  ) {
    return _getOfflineModelStatusImpl(provider);
  }

  @override
  Future<void> prepareOfflineModel({
    required AsrProviderType provider,
    required String language,
    AsrProgressCallback? onProgress,
  }) {
    return _prepareOfflineModelImpl(
      provider: provider,
      language: language,
      onProgress: onProgress,
    );
  }

  @override
  Future<void> removeOfflineModel(AsrProviderType provider) {
    return _removeOfflineModelImpl(provider);
  }

  @override
  Future<PronScoringPackStatus> getPronScoringPackStatus(
    PronScoringMethod method,
  ) {
    return _getPronScoringPackStatusImpl(method);
  }

  @override
  Future<void> preparePronScoringPack({
    required PronScoringMethod method,
    AsrProgressCallback? onProgress,
  }) {
    return _preparePronScoringPackImpl(method: method, onProgress: onProgress);
  }

  @override
  Future<void> removePronScoringPack(PronScoringMethod method) {
    return _removePronScoringPackImpl(method);
  }

  @override
  Future<void> dispose() {
    return _disposeImpl();
  }

  static bool isOfflineProvider(AsrProviderType provider) {
    return provider == AsrProviderType.offline ||
        provider == AsrProviderType.offlineSmall;
  }
}

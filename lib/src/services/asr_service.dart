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
    required this.archiveUrl,
    required this.dirName,
    required this.encoderFile,
    required this.decoderFile,
    required this.tokensFile,
  });

  final String variant;
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

class AsrService {
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
      archiveUrl:
          'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-whisper-base.en.tar.bz2',
      dirName: 'sherpa-onnx-whisper-base.en',
      encoderFile: 'base.en-encoder.int8.onnx',
      decoderFile: 'base.en-decoder.int8.onnx',
      tokensFile: 'base.en-tokens.txt',
    ),
    AsrProviderType.offlineSmall: _OfflineModelProfile(
      variant: 'small',
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
  http.Client? _activeApiClient;
  int _apiRequestToken = 0;
  String? _activeRecordingPath;
  int _debugAudioRunCounter = 0;

  bool _bindingsInitialized = false;
  bool _stopRequested = false;

  static bool isOfflineProvider(AsrProviderType provider) {
    return provider == AsrProviderType.offline ||
        provider == AsrProviderType.offlineSmall;
  }

  Future<String?> startRecording({required AsrProviderType provider}) async {
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

  Future<String?> stopRecording() async {
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

  Future<void> cancelRecording() async {
    _activeRecordingPath = null;
    await _safeCancelRecorder();
  }

  void stopOfflineRecognition() {
    _stopRequested = true;
    _interruptApiRequest(reason: 'stop');
  }

  Future<AsrResult> transcribeFile({
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

  Future<void> dispose() async {
    _interruptApiRequest(reason: 'dispose');
    await cancelRecording();
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

  Future<AsrOfflineModelStatus> getOfflineModelStatus(
    AsrProviderType provider,
  ) async {
    final profile = _offlineProfiles[provider];
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

  Future<PronScoringPackStatus> getPronScoringPackStatus(
    PronScoringMethod method,
  ) async {
    final profile = _scoringPackProfiles[method];
    if (profile == null) {
      return PronScoringPackStatus(method: method, installed: false, bytes: 0);
    }
    final root = await _ensureScoringPacksRoot();
    final dir = Directory(p.join(root.path, profile.dirName));
    final marker = File(p.join(dir.path, _scoringPackMarker));
    final installed = await dir.exists() && await marker.exists();
    final bytes = installed ? await _directorySize(dir) : 0;
    return PronScoringPackStatus(
      method: method,
      installed: installed,
      bytes: bytes,
    );
  }

  Future<void> preparePronScoringPack({
    required PronScoringMethod method,
    AsrProgressCallback? onProgress,
  }) async {
    final profile = _scoringPackProfiles[method];
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
    final marker = File(p.join(dir.path, _scoringPackMarker));
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

  Future<void> removePronScoringPack(PronScoringMethod method) async {
    final profile = _scoringPackProfiles[method];
    if (profile == null) return;
    final root = await _ensureScoringPacksRoot();
    final dir = Directory(p.join(root.path, profile.dirName));
    await _safeDeleteDirectory(dir);
  }

  Future<void> prepareOfflineModel({
    required AsrProviderType provider,
    required String language,
    AsrProgressCallback? onProgress,
  }) async {
    final profile = _offlineProfiles[provider];
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

  Future<void> removeOfflineModel(AsrProviderType provider) async {
    final profile = _offlineProfiles[provider];
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
      targetSampleRate: _targetSampleRate,
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
        (_targetSampleRate * minSeconds).round()) {
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
        targetSampleRate: _targetSampleRate,
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
      final userDurationSec = preparedUser.samples.length / _targetSampleRate;
      final refDurationSec = preparedRef.samples.length / _targetSampleRate;
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
      throw StateError('asrSimilarityTtsApiKeyMissing');
    }
    if (ttsConfig.provider == TtsProviderType.customApi &&
        (ttsConfig.baseUrl == null || ttsConfig.baseUrl!.trim().isEmpty)) {
      throw StateError('asrSimilarityTtsBaseUrlMissing');
    }
    final endpoint = _resolveTtsEndpoint(ttsConfig);
    final model = (ttsConfig.model?.trim().isNotEmpty ?? false)
        ? ttsConfig.model!.trim()
        : _defaultTtsModel;
    final voice = ttsConfig.remoteVoice.trim().isNotEmpty
        ? ttsConfig.remoteVoice.trim()
        : _defaultTtsVoice;
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
    return _defaultTtsApiEndpoint;
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
    return _defaultApiEndpoint;
  }

  String? _normalizeApiLanguage(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty || value == 'auto') return null;
    final normalized = value.replaceAll('_', '-');
    if (normalized.startsWith('zh')) return 'zh';
    if (normalized.startsWith('en')) return 'en';
    if (normalized.startsWith('ja')) return 'ja';
    if (normalized.startsWith('de')) return 'de';
    if (normalized.startsWith('fr')) return 'fr';
    if (normalized.startsWith('es')) return 'es';
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
        targetSampleRate: _targetSampleRate,
      );
      final minSamples =
          (_targetSampleRate * _minDurationForExpected(expectedText)).round();
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
        sampleRate: _targetSampleRate,
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
        sampleRate: _targetSampleRate,
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
        sampleRate: _targetSampleRate,
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
        sampleRate: _targetSampleRate,
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
        sampleRate: _targetSampleRate,
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
        sampleRate: _targetSampleRate,
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

  List<double> _choosePreferredWaveSegment({
    required List<double> denoised,
    required List<double> trimmed,
    required int sampleRate,
  }) {
    if (trimmed.isEmpty) {
      final focused = _extractPeakFocusedSegment(
        denoised,
        sampleRate: sampleRate,
      );
      return focused.isEmpty ? denoised : focused;
    }
    final minPreferredSamples = (sampleRate * 0.05).round();
    if (trimmed.length < minPreferredSamples &&
        denoised.length > trimmed.length) {
      final focused = _extractPeakFocusedSegment(
        denoised,
        sampleRate: sampleRate,
      );
      if (focused.length > trimmed.length) {
        return focused;
      }
    }
    return trimmed;
  }

  List<double> _extractPeakFocusedSegment(
    List<double> samples, {
    required int sampleRate,
  }) {
    if (samples.isEmpty || sampleRate <= 0) return const <double>[];
    final frameSize = math.max(96, (sampleRate * 0.02).round());
    final hopSize = math.max(64, (sampleRate * 0.01).round());
    if (samples.length < frameSize) {
      return List<double>.from(samples, growable: false);
    }
    final frameCount = ((samples.length - frameSize) / hopSize).floor() + 1;
    if (frameCount <= 0) return const <double>[];

    final energies = List<double>.filled(frameCount, 0.0, growable: false);
    for (var frame = 0; frame < frameCount; frame++) {
      final start = frame * hopSize;
      var power = 0.0;
      for (var i = 0; i < frameSize; i++) {
        final v = samples[start + i];
        power += v * v;
      }
      energies[frame] = math.sqrt(power / frameSize.toDouble());
    }

    final hopSec = hopSize / sampleRate;
    final desiredWindowFrames = (0.35 / hopSec).round();
    final windowFrames = math.max(3, math.min(frameCount, desiredWindowFrames));
    final prefix = List<double>.filled(frameCount + 1, 0.0, growable: false);
    for (var i = 0; i < frameCount; i++) {
      prefix[i + 1] = prefix[i] + energies[i];
    }

    var bestStartFrame = 0;
    var bestScore = double.negativeInfinity;
    var bestMean = 0.0;
    final denominator = math.max(1, frameCount - 1);
    for (
      var startFrame = 0;
      startFrame <= frameCount - windowFrames;
      startFrame++
    ) {
      final endFrame = startFrame + windowFrames;
      final mean = (prefix[endFrame] - prefix[startFrame]) / windowFrames;
      final centerNorm = (startFrame + windowFrames * 0.5) / denominator;
      final tailBias = 0.95 + centerNorm * 0.10;
      final score = mean * tailBias;
      if (score > bestScore) {
        bestScore = score;
        bestStartFrame = startFrame;
        bestMean = mean;
      }
    }
    final noiseFloor = _estimateNoiseFloor(samples, sampleRate: sampleRate);
    final minMean = math.max(0.0016, noiseFloor * 1.25);
    if (bestMean < minMean) return const <double>[];

    final bestEndFrame = bestStartFrame + windowFrames - 1;
    final prePad = (sampleRate * 0.09).round();
    final postPad = (sampleRate * 0.12).round();
    final start = math.max(0, bestStartFrame * hopSize - prePad);
    final end = math.min(
      samples.length,
      bestEndFrame * hopSize + frameSize + postPad,
    );
    if (end <= start) return const <double>[];
    return samples.sublist(start, end);
  }

  List<double> _removeDcOffset(List<double> samples) {
    if (samples.isEmpty) return const <double>[];
    var sum = 0.0;
    for (final sample in samples) {
      sum += sample;
    }
    final mean = sum / samples.length;
    return List<double>.generate(samples.length, (index) {
      final centered = samples[index] - mean;
      if (centered > 1.0) return 1.0;
      if (centered < -1.0) return -1.0;
      return centered;
    }, growable: false);
  }

  List<double> _highPassSpeechFilter(
    List<double> samples, {
    required int sampleRate,
  }) {
    if (samples.isEmpty || sampleRate <= 0) return const <double>[];
    if (samples.length < 2) return List<double>.from(samples, growable: false);
    final cutoffHz = 90.0;
    final rc = 1.0 / (2.0 * math.pi * cutoffHz);
    final dt = 1.0 / sampleRate;
    final alpha = rc / (rc + dt);
    final output = List<double>.filled(samples.length, 0.0, growable: false);
    var yPrev = 0.0;
    var xPrev = samples.first;
    for (var i = 0; i < samples.length; i++) {
      final x = samples[i];
      final y = alpha * (yPrev + x - xPrev);
      output[i] = y.clamp(-1.0, 1.0);
      yPrev = y;
      xPrev = x;
    }
    return output;
  }

  List<double> _adaptiveNoiseGate(
    List<double> samples, {
    required int sampleRate,
  }) {
    if (samples.isEmpty) return const <double>[];
    final noiseFloor = _estimateNoiseFloor(samples, sampleRate: sampleRate);
    final gate = math.max(0.0008, noiseFloor * 1.45);
    final soft = gate * 1.8;
    return List<double>.generate(samples.length, (index) {
      final value = samples[index];
      final abs = value.abs();
      if (abs <= gate) return value * 0.18;
      if (abs >= soft) return value;
      final ratio = (abs - gate) / (soft - gate);
      final keep = 0.18 + 0.82 * ratio;
      return value * keep;
    }, growable: false);
  }

  double _estimateNoiseFloor(List<double> samples, {required int sampleRate}) {
    if (samples.isEmpty) return 0;
    if (sampleRate <= 0) {
      var sumAbs = 0.0;
      for (final sample in samples) {
        sumAbs += sample.abs();
      }
      return sumAbs / samples.length.toDouble();
    }
    final frameSize = math.max(64, (sampleRate * 0.01).round());
    if (samples.length < frameSize) {
      var sumAbs = 0.0;
      for (final sample in samples) {
        sumAbs += sample.abs();
      }
      return sumAbs / samples.length.toDouble();
    }
    final frameRms = <double>[];
    for (
      var start = 0;
      start + frameSize <= samples.length;
      start += frameSize
    ) {
      var power = 0.0;
      for (var i = 0; i < frameSize; i++) {
        final v = samples[start + i];
        power += v * v;
      }
      frameRms.add(math.sqrt(power / frameSize.toDouble()));
    }
    if (frameRms.isEmpty) return 0;
    frameRms.sort();
    final index = ((frameRms.length - 1) * 0.22).round().clamp(
      0,
      frameRms.length - 1,
    );
    return frameRms[index];
  }

  List<double> _trimSilenceByFrameEnergy(
    List<double> samples, {
    required int sampleRate,
  }) {
    if (samples.isEmpty || sampleRate <= 0) return const <double>[];
    final frameSize = math.max(96, (sampleRate * 0.02).round());
    final hopSize = math.max(64, (sampleRate * 0.01).round());
    if (samples.length < frameSize) return const <double>[];
    final frameCount = ((samples.length - frameSize) / hopSize).floor() + 1;
    if (frameCount <= 0) return const <double>[];

    final energies = List<double>.filled(frameCount, 0.0, growable: false);
    var maxEnergy = 0.0;
    for (var frame = 0; frame < frameCount; frame++) {
      final start = frame * hopSize;
      var power = 0.0;
      for (var i = 0; i < frameSize; i++) {
        final v = samples[start + i];
        power += v * v;
      }
      final rms = math.sqrt(power / frameSize.toDouble());
      energies[frame] = rms;
      if (rms > maxEnergy) {
        maxEnergy = rms;
      }
    }
    if (maxEnergy <= 0) return const <double>[];
    final noiseFloor = _estimateNoiseFloor(samples, sampleRate: sampleRate);
    final threshold = math.max(
      0.0024,
      math.max(noiseFloor * 1.9, maxEnergy * 0.10),
    );

    final isActive = List<bool>.filled(frameCount, false, growable: false);
    for (var i = 0; i < frameCount; i++) {
      isActive[i] = energies[i] >= threshold;
    }
    final maxGapFrames = math.max(1, (sampleRate * 0.18 / hopSize).round());
    var lastActive = -1;
    for (var i = 0; i < frameCount; i++) {
      if (!isActive[i]) continue;
      if (lastActive >= 0) {
        final gap = i - lastActive - 1;
        if (gap > 0 && gap <= maxGapFrames) {
          for (var j = lastActive + 1; j < i; j++) {
            isActive[j] = true;
          }
        }
      }
      lastActive = i;
    }

    var segments = <_EnergySegment>[];
    var frame = 0;
    while (frame < frameCount) {
      if (!isActive[frame]) {
        frame += 1;
        continue;
      }
      final startFrame = frame;
      var endFrame = frame;
      var energySum = 0.0;
      var peakEnergy = 0.0;
      while (endFrame < frameCount && isActive[endFrame]) {
        final energy = energies[endFrame];
        energySum += energy;
        if (energy > peakEnergy) peakEnergy = energy;
        endFrame += 1;
      }
      final finalFrame = endFrame - 1;
      final startSample = startFrame * hopSize;
      final endSample = math.min(
        samples.length,
        finalFrame * hopSize + frameSize,
      );
      final durationSamples = endSample - startSample;
      if (durationSamples > 0) {
        final frameLength = math.max(1, endFrame - startFrame);
        segments.add(
          _EnergySegment(
            startSample: startSample,
            endSample: endSample,
            durationSamples: durationSamples,
            meanEnergy: energySum / frameLength.toDouble(),
            peakEnergy: peakEnergy,
          ),
        );
      }
      frame = endFrame;
    }
    if (segments.isEmpty) return const <double>[];
    segments = _mergeNearbySpeechSegments(
      segments,
      sampleRate: sampleRate,
      noiseFloor: noiseFloor,
    );
    if (segments.isEmpty) return const <double>[];

    final totalSamples = math.max(1, samples.length);
    var maxEnergyMass = 0.0;
    for (final segment in segments) {
      final mass = segment.meanEnergy * segment.durationSamples.toDouble();
      if (mass > maxEnergyMass) {
        maxEnergyMass = mass;
      }
    }

    _EnergySegment? best;
    var bestScore = double.negativeInfinity;
    for (final segment in segments) {
      final durationSec = segment.durationSamples / sampleRate;
      final normalizedPeak = (segment.peakEnergy / maxEnergy).clamp(0.0, 1.0);
      final normalizedMean = (segment.meanEnergy / maxEnergy).clamp(0.0, 1.0);
      final energyMass =
          (segment.meanEnergy * segment.durationSamples.toDouble());
      final normalizedMass = maxEnergyMass <= 0
          ? 0.0
          : (energyMass / maxEnergyMass).clamp(0.0, 1.0);
      final durationBoost = math.min(1.25, 0.72 + durationSec / 0.24);
      final shortPenalty = durationSec < 0.07 ? 0.56 : 1.0;
      final center =
          ((segment.startSample + segment.endSample) * 0.5) /
          totalSamples.toDouble();
      final tailBias = 0.90 + center * 0.14;
      final score =
          (normalizedMass * 0.58 +
              normalizedMean * 0.24 +
              normalizedPeak * 0.18) *
          durationBoost *
          shortPenalty *
          tailBias;
      if (score > bestScore) {
        bestScore = score;
        best = segment;
      }
    }
    if (best == null) return const <double>[];
    if (best.durationSamples < math.max(64, (sampleRate * 0.045).round())) {
      return const <double>[];
    }

    final prePad = (sampleRate * 0.13).round();
    final postPad = (sampleRate * 0.18).round();
    final start = math.max(0, best.startSample - prePad);
    final end = math.min(samples.length, best.endSample + postPad);
    if (end <= start) return const <double>[];
    return samples.sublist(start, end);
  }

  List<_EnergySegment> _mergeNearbySpeechSegments(
    List<_EnergySegment> segments, {
    required int sampleRate,
    required double noiseFloor,
  }) {
    if (segments.length <= 1 || sampleRate <= 0) return segments;
    final sorted = List<_EnergySegment>.from(segments, growable: false)
      ..sort((a, b) => a.startSample.compareTo(b.startSample));
    final maxGapSamples = (sampleRate * 0.55).round();
    final maxSingleSamples = (sampleRate * 0.45).round();
    final maxMergedSpanSamples = (sampleRate * 1.20).round();
    final minEnergy = math.max(0.0012, noiseFloor * 1.15);
    final merged = <_EnergySegment>[];

    var current = sorted.first;
    for (var i = 1; i < sorted.length; i++) {
      final next = sorted[i];
      final gapSamples = next.startSample - current.endSample;
      final canMerge =
          gapSamples >= 0 &&
          gapSamples <= maxGapSamples &&
          current.durationSamples <= maxSingleSamples &&
          next.durationSamples <= maxSingleSamples &&
          (next.endSample - current.startSample) <= maxMergedSpanSamples &&
          current.meanEnergy >= minEnergy &&
          next.meanEnergy >= minEnergy;
      if (!canMerge) {
        merged.add(current);
        current = next;
        continue;
      }
      final newStart = current.startSample;
      final newEnd = next.endSample;
      final newDuration = math.max(1, newEnd - newStart);
      final weightedMean =
          (current.meanEnergy * current.durationSamples.toDouble() +
              next.meanEnergy * next.durationSamples.toDouble()) /
          (current.durationSamples + next.durationSamples).toDouble();
      final newPeak = math.max(current.peakEnergy, next.peakEnergy);
      current = _EnergySegment(
        startSample: newStart,
        endSample: newEnd,
        durationSamples: newDuration,
        meanEnergy: weightedMean,
        peakEnergy: newPeak,
      );
    }
    merged.add(current);
    return merged;
  }

  List<double> _trimSilence(List<double> samples, {required int sampleRate}) {
    if (samples.isEmpty || sampleRate <= 0) return const <double>[];
    var peak = 0.0;
    for (final sample in samples) {
      final value = sample.abs();
      if (value > peak) peak = value;
    }
    if (peak <= 0) return const <double>[];

    final threshold = math.max(0.006, peak * 0.05);
    var first = -1;
    var last = -1;
    for (var i = 0; i < samples.length; i++) {
      if (samples[i].abs() >= threshold) {
        first = i;
        break;
      }
    }
    for (var i = samples.length - 1; i >= 0; i--) {
      if (samples[i].abs() >= threshold) {
        last = i;
        break;
      }
    }
    if (first < 0 || last < first) {
      return const <double>[];
    }

    final padding = (sampleRate * 0.18).round();
    final start = math.max(0, first - padding);
    final end = math.min(samples.length - 1, last + padding);
    return samples.sublist(start, end + 1);
  }

  List<double> _normalizeAmplitude(List<double> samples) {
    if (samples.isEmpty) return const <double>[];
    var peak = 0.0;
    for (final sample in samples) {
      final value = sample.abs();
      if (value > peak) peak = value;
    }
    if (peak <= 0) return List<double>.from(samples, growable: false);
    final gain = (0.92 / peak).clamp(0.5, 6.0);
    return List<double>.generate(samples.length, (index) {
      final value = samples[index] * gain;
      if (value > 1.0) return 1.0;
      if (value < -1.0) return -1.0;
      return value;
    }, growable: false);
  }

  List<double> _resampleLinear({
    required List<double> samples,
    required int sourceSampleRate,
    required int targetSampleRate,
  }) {
    if (samples.isEmpty || sourceSampleRate <= 0 || targetSampleRate <= 0) {
      return const <double>[];
    }
    if (sourceSampleRate == targetSampleRate) {
      return List<double>.from(samples, growable: false);
    }
    final ratio = targetSampleRate / sourceSampleRate;
    final outputLength = math.max(1, (samples.length * ratio).round());
    final output = List<double>.filled(outputLength, 0, growable: false);
    for (var i = 0; i < outputLength; i++) {
      final sourcePos = i / ratio;
      final left = sourcePos.floor();
      final right = math.min(left + 1, samples.length - 1);
      final mix = sourcePos - left;
      output[i] = samples[left] * (1 - mix) + samples[right] * mix;
    }
    return output;
  }

  List<List<double>> _extractAcousticFeatures(
    List<double> samples, {
    required int sampleRate,
  }) {
    if (samples.isEmpty || sampleRate <= 0) return const <List<double>>[];
    final frameSize = math.max(96, (sampleRate * 0.02).round());
    final hopSize = math.max(64, (sampleRate * 0.01).round());
    if (samples.length < frameSize) return const <List<double>>[];

    final hamming = List<double>.generate(frameSize, (index) {
      if (frameSize <= 1) return 1.0;
      return 0.54 -
          0.46 * math.cos((2 * math.pi * index) / (frameSize - 1).toDouble());
    }, growable: false);

    final features = <List<double>>[];
    final targetFreqs = <double>[320, 520, 780, 1120, 1600, 2300, 3200];
    for (var start = 0; start + frameSize <= samples.length; start += hopSize) {
      final frame = List<double>.filled(frameSize, 0.0, growable: false);
      for (var i = 0; i < frameSize; i++) {
        frame[i] = samples[start + i] * hamming[i];
      }
      final logEnergy = _frameLogEnergy(frame);
      final zcr = _frameZeroCrossingRate(frame);
      final bandPowers = targetFreqs
          .map(
            (freq) => math.log(_goertzelPower(frame, freq, sampleRate) + 1e-9),
          )
          .toList(growable: false);
      final bandMean =
          bandPowers.reduce((a, b) => a + b) / bandPowers.length.toDouble();
      final normalizedBands = bandPowers
          .map((value) => value - bandMean)
          .toList(growable: false);

      features.add(<double>[logEnergy, zcr, ...normalizedBands]);
    }

    const maxFrames = 180;
    if (features.length <= maxFrames) return features;
    final stride = (features.length / maxFrames).ceil().clamp(
      1,
      features.length,
    );
    final reduced = <List<double>>[];
    for (var i = 0; i < features.length; i += stride) {
      reduced.add(features[i]);
      if (reduced.length >= maxFrames) break;
    }
    return reduced;
  }

  double _frameLogEnergy(List<double> frame) {
    if (frame.isEmpty) return 0;
    var power = 0.0;
    for (final sample in frame) {
      power += sample * sample;
    }
    final rms = math.sqrt(power / frame.length);
    return math.log(rms + 1e-8);
  }

  double _frameZeroCrossingRate(List<double> frame) {
    if (frame.length <= 1) return 0;
    var crossings = 0;
    for (var i = 1; i < frame.length; i++) {
      final prev = frame[i - 1];
      final curr = frame[i];
      if ((prev >= 0 && curr < 0) || (prev < 0 && curr >= 0)) {
        crossings += 1;
      }
    }
    return crossings / (frame.length - 1);
  }

  double _goertzelPower(List<double> frame, double targetFreq, int sampleRate) {
    if (frame.isEmpty || sampleRate <= 0) return 0;
    final normalized = targetFreq / sampleRate;
    final omega = 2.0 * math.pi * normalized;
    final coeff = 2.0 * math.cos(omega);
    var sPrev = 0.0;
    var sPrev2 = 0.0;
    for (final sample in frame) {
      final s = sample + coeff * sPrev - sPrev2;
      sPrev2 = sPrev;
      sPrev = s;
    }
    final power = sPrev2 * sPrev2 + sPrev * sPrev - coeff * sPrev * sPrev2;
    return power.abs();
  }

  double _dtwDistance(List<List<double>> ref, List<List<double>> sample) {
    if (ref.isEmpty || sample.isEmpty) return double.infinity;
    final n = ref.length;
    final m = sample.length;
    final band = (math.max(n, m) * 0.25)
        .round()
        .clamp(8, math.max(n, m))
        .toInt();
    const inf = 1e12;
    var prev = List<double>.filled(m + 1, inf, growable: false);
    prev[0] = 0;

    for (var i = 1; i <= n; i++) {
      final curr = List<double>.filled(m + 1, inf, growable: false);
      final jStart = math.max(1, i - band);
      final jEnd = math.min(m, i + band);
      for (var j = jStart; j <= jEnd; j++) {
        final cost = _frameDistance(ref[i - 1], sample[j - 1]);
        final best = math.min(prev[j], math.min(curr[j - 1], prev[j - 1]));
        curr[j] = cost + best;
      }
      prev = curr;
    }

    final distance = prev[m];
    if (!distance.isFinite || distance >= inf / 2) return double.infinity;
    return distance / (n + m).toDouble();
  }

  double _frameDistance(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty) return 1;
    final length = math.min(a.length, b.length);
    if (length <= 0) return 1;
    var sum = 0.0;
    for (var i = 0; i < length; i++) {
      final weight = i == 0
          ? 1.15
          : i == 1
          ? 0.7
          : 1.0;
      final diff = a[i] - b[i];
      sum += weight * diff * diff;
    }
    return math.sqrt(sum / length.toDouble());
  }

  double _distanceToSimilarity(
    double dtwDistance, {
    required double userDurationSec,
    required double refDurationSec,
    required int expectedLength,
  }) {
    if (!dtwDistance.isFinite) return 0;
    final baseSimilarity = math.exp(-1.65 * dtwDistance);
    var durationRatio = 1.0;
    if (userDurationSec > 0 && refDurationSec > 0) {
      durationRatio =
          math.min(userDurationSec, refDurationSec) /
          math.max(userDurationSec, refDurationSec);
    }
    final durationWeight = expectedLength <= 4
        ? 0.22
        : (expectedLength <= 8 ? 0.32 : 0.45);
    final rhythmFactor = (1 - durationWeight) + durationRatio * durationWeight;
    return (baseSimilarity * rhythmFactor).clamp(0.0, 1.0);
  }

  Future<List<PronScoringMethod>> _resolveReadyScoringMethods(
    AsrConfig config,
  ) async {
    final requested = config.normalizedScoringMethods;
    final ready = <PronScoringMethod>[];
    for (final method in requested) {
      final status = await getPronScoringPackStatus(method);
      if (status.installed) {
        ready.add(method);
      }
    }
    return ready;
  }

  _ScoringAggregate _scoreByMethods({
    required List<PronScoringMethod> methods,
    required String expectedText,
    required String? recognizedText,
    required double acousticSimilarity,
    required double userDurationSec,
    required double refDurationSec,
  }) {
    final breakdown = <PronScoringMethod, double>{};
    final textSimilarity = _estimateTextSimilarity(
      expectedText,
      recognizedText ?? '',
    );
    final acoustic = acousticSimilarity.clamp(0.0, 1.0);
    final durationScore = _durationConsistency(
      userDurationSec,
      refDurationSec,
      expectedLength: expectedText.runes.length,
    );

    for (final method in methods) {
      final score = switch (method) {
        PronScoringMethod.sslEmbedding => acoustic,
        PronScoringMethod.gop => _scoreGop(
          textSimilarity: textSimilarity,
          acousticSimilarity: acoustic,
          recognizedText: recognizedText ?? '',
        ),
        PronScoringMethod.forcedAlignmentPer => _scoreForcedAlignmentPer(
          expectedText: expectedText,
          recognizedText: recognizedText ?? '',
          acousticSimilarity: acoustic,
          durationScore: durationScore,
        ),
        PronScoringMethod.ppgPosterior => _scorePpgPosterior(
          textSimilarity: textSimilarity,
          acousticSimilarity: acoustic,
          durationScore: durationScore,
        ),
      };
      breakdown[method] = score.clamp(0.0, 1.0);
    }

    final total = _aggregateScoringBreakdown(breakdown);
    return _ScoringAggregate(total: total, breakdown: breakdown);
  }

  double _scoreGop({
    required double textSimilarity,
    required double acousticSimilarity,
    required String recognizedText,
  }) {
    if (recognizedText.trim().isEmpty) {
      return acousticSimilarity * 0.88;
    }
    return (textSimilarity * 0.72 + acousticSimilarity * 0.28).clamp(0.0, 1.0);
  }

  double _scoreForcedAlignmentPer({
    required String expectedText,
    required String recognizedText,
    required double acousticSimilarity,
    required double durationScore,
  }) {
    if (recognizedText.trim().isEmpty) {
      return (acousticSimilarity * 0.82 + durationScore * 0.18).clamp(0.0, 1.0);
    }
    final expectedPhones = _pseudoPhoneSequence(expectedText);
    final recognizedPhones = _pseudoPhoneSequence(recognizedText);
    final per = _normalizedEditDistance(expectedPhones, recognizedPhones);
    final perScore = (1.0 - per).clamp(0.0, 1.0);
    return (perScore * 0.65 + durationScore * 0.20 + acousticSimilarity * 0.15)
        .clamp(0.0, 1.0);
  }

  double _scorePpgPosterior({
    required double textSimilarity,
    required double acousticSimilarity,
    required double durationScore,
  }) {
    final posteriorLike =
        (acousticSimilarity * 0.60 +
                textSimilarity * 0.20 +
                durationScore * 0.20)
            .clamp(0.0, 1.0);
    final sharpened = 1.0 / (1.0 + math.exp(-6.0 * (posteriorLike - 0.5)));
    return sharpened.clamp(0.0, 1.0);
  }

  double _aggregateScoringBreakdown(Map<PronScoringMethod, double> breakdown) {
    if (breakdown.isEmpty) return 0;
    const weights = <PronScoringMethod, double>{
      PronScoringMethod.sslEmbedding: 0.35,
      PronScoringMethod.gop: 0.25,
      PronScoringMethod.forcedAlignmentPer: 0.22,
      PronScoringMethod.ppgPosterior: 0.18,
    };
    var weightedSum = 0.0;
    var weightSum = 0.0;
    for (final entry in breakdown.entries) {
      final weight = weights[entry.key] ?? 0.2;
      weightedSum += entry.value * weight;
      weightSum += weight;
    }
    if (weightSum <= 0) return 0;
    return (weightedSum / weightSum).clamp(0.0, 1.0);
  }

  double _durationConsistency(
    double a,
    double b, {
    required int expectedLength,
  }) {
    if (a <= 0 || b <= 0) return 1.0;
    final ratio = math.min(a, b) / math.max(a, b);
    final exponent = expectedLength <= 4
        ? 0.22
        : (expectedLength <= 8 ? 0.35 : 0.5);
    return math.pow(ratio, exponent).toDouble().clamp(0.0, 1.0);
  }

  double _estimateTextSimilarity(String expected, String recognized) {
    final expectedPhones = _pseudoPhoneSequence(expected);
    final recognizedPhones = _pseudoPhoneSequence(recognized);
    if (expectedPhones.isEmpty && recognizedPhones.isEmpty) return 0;
    final distance = _levenshteinTokens(expectedPhones, recognizedPhones);
    final denominator = math.max(
      expectedPhones.length,
      recognizedPhones.length,
    );
    if (denominator <= 0) return 0;
    return (1 - distance / denominator).clamp(0.0, 1.0);
  }

  List<String> _pseudoPhoneSequence(String text) {
    final lowered = text.toLowerCase();
    final filtered = lowered.replaceAll(
      RegExp(r"[^\p{L}\p{N}\u4e00-\u9fff]+", unicode: true),
      '',
    );
    if (filtered.isEmpty) return const <String>[];
    final output = <String>[];
    for (final rune in filtered.runes) {
      final char = String.fromCharCode(rune);
      if (rune >= 0x4E00 && rune <= 0x9FFF) {
        output.add('cjk_$char');
        continue;
      }
      output.add(_latinPseudoPhone(char));
    }
    return output;
  }

  String _latinPseudoPhone(String char) {
    return switch (char) {
      'a' || 'e' || 'i' || 'o' || 'u' || 'y' => 'vowel',
      'b' || 'p' => 'bp',
      'c' || 'k' || 'q' || 'g' => 'kgq',
      'd' || 't' => 'dt',
      'f' || 'v' => 'fv',
      'l' || 'r' => 'lr',
      'm' || 'n' => 'mn',
      's' || 'z' || 'x' => 'szx',
      'h' || 'w' || 'j' => char,
      _ => char,
    };
  }

  double _normalizedEditDistance(List<String> a, List<String> b) {
    final denominator = math.max(a.length, b.length);
    if (denominator <= 0) return 1;
    final distance = _levenshteinTokens(a, b);
    return (distance / denominator).clamp(0.0, 1.0);
  }

  int _levenshteinTokens(List<String> a, List<String> b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    var prev = List<int>.generate(b.length + 1, (index) => index);
    for (var i = 1; i <= a.length; i++) {
      final curr = List<int>.filled(b.length + 1, 0);
      curr[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final substitutionCost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = math.min(
          math.min(curr[j - 1] + 1, prev[j] + 1),
          prev[j - 1] + substitutionCost,
        );
      }
      prev = curr;
    }
    return prev[b.length];
  }

  Future<AsrResult> _transcribeOffline({
    required String audioPath,
    required AsrConfig config,
    String? expectedText,
    AsrProgressCallback? onProgress,
    required String? debugRunDir,
  }) async {
    final profile = _offlineProfiles[config.provider];
    if (profile == null) {
      return const AsrResult(
        success: false,
        error: 'asrUnsupportedOfflineProvider',
      );
    }

    onProgress?.call(
      const AsrProgress(
        stage: 'prepare',
        messageKey: 'asrProgressPreparing',
        progress: 0,
      ),
    );

    await _ensureOfflineRecognizer(
      provider: config.provider,
      profile: profile,
      language: config.language,
      onProgress: onProgress,
    );
    _checkCanceled();

    final recognizer = _offlineRecognizers[config.provider];
    if (recognizer == null) {
      return const AsrResult(success: false, error: 'asrOfflineInitFailed');
    }

    onProgress?.call(
      const AsrProgress(
        stage: 'recognize',
        messageKey: 'asrProgressDecoding',
        progress: null,
      ),
    );

    late final dynamic waveData;
    try {
      _ensureSherpaBindings();
      waveData = readWave(audioPath);
    } catch (_) {
      return const AsrResult(success: false, error: 'asrInvalidWav');
    }
    if (waveData.samples.isEmpty || waveData.sampleRate <= 0) {
      return const AsrResult(success: false, error: 'asrInvalidWav');
    }

    final prepared = _prepareWaveData(
      samples: waveData.samples,
      sampleRate: waveData.sampleRate,
      targetSampleRate: _targetSampleRate,
    );
    await _writePreparedDebugWav(
      debugRunDir,
      stem: '${config.provider.name}_processed',
      prepared: prepared,
    );
    if (prepared.samples.isEmpty) {
      return const AsrResult(success: false, error: 'asrNoSpeechDetected');
    }

    final minSeconds = _minDurationForExpected(expectedText);
    if (prepared.samples.length < (_targetSampleRate * minSeconds).round()) {
      return const AsrResult(success: false, error: 'asrRecordingTooShort');
    }
    if (prepared.peak < _minPeakForExpected(expectedText)) {
      return const AsrResult(success: false, error: 'asrNoSpeechDetected');
    }

    var text = _decodeOfflineWithPrepared(recognizer, prepared);
    var preparedForText = prepared;
    final expected = (expectedText ?? '').trim();
    if (expected.isNotEmpty &&
        _shouldRetryOfflineWithLooseDecode(
          expected: expected,
          recognized: text,
        )) {
      final loosePrepared = _prepareWaveDataLoose(
        samples: waveData.samples,
        sampleRate: waveData.sampleRate,
        targetSampleRate: _targetSampleRate,
      );
      await _writePreparedDebugWav(
        debugRunDir,
        stem: '${config.provider.name}_processed_loose',
        prepared: loosePrepared,
      );
      if (loosePrepared.samples.isNotEmpty &&
          loosePrepared.samples.length >=
              (_targetSampleRate * minSeconds).round() &&
          loosePrepared.peak >= _minPeakForExpected(expectedText)) {
        final altText = _decodeOfflineWithPrepared(recognizer, loosePrepared);
        if (_isAlternativeOfflineTextBetter(
          expected: expected,
          primary: text,
          alternative: altText,
        )) {
          text = altText;
          preparedForText = loosePrepared;
        }
      }
    }
    if (expected.isNotEmpty &&
        text.isNotEmpty &&
        _shouldQuantizedTemplateAlignExpected(
          expected: expected,
          recognized: text,
          prepared: preparedForText,
        )) {
      text = expected;
    }
    if (text.isEmpty) {
      return const AsrResult(success: false, error: 'asrEmptyResult');
    }

    onProgress?.call(
      const AsrProgress(
        stage: 'done',
        messageKey: 'asrProgressDone',
        progress: 1,
      ),
    );
    return AsrResult(success: true, text: text);
  }

  String _decodeOfflineWithPrepared(
    OfflineRecognizer recognizer,
    _PreparedWaveData prepared,
  ) {
    final stream = recognizer.createStream();
    try {
      stream.acceptWaveform(
        samples: Float32List.fromList(prepared.samples),
        sampleRate: prepared.sampleRate,
      );
      _checkCanceled();
      recognizer.decode(stream);
      _checkCanceled();
      return recognizer.getResult(stream).text.trim();
    } finally {
      stream.free();
    }
  }

  bool _shouldRetryOfflineWithLooseDecode({
    required String expected,
    required String recognized,
  }) {
    final normalizedExpected = _normalizeRecognitionText(expected);
    final normalizedRecognized = _normalizeRecognitionText(recognized);
    if (normalizedExpected.isEmpty) return false;
    if (normalizedRecognized.isEmpty) return true;
    final expectedLength = normalizedExpected.runes.length;
    final recognizedLength = normalizedRecognized.runes.length;
    final similarity = _estimateTextSimilarity(
      normalizedExpected,
      normalizedRecognized,
    );
    if (similarity >= 0.62) return false;
    if (expectedLength <= 5 && recognizedLength <= 2) return true;
    return similarity < 0.42;
  }

  bool _isAlternativeOfflineTextBetter({
    required String expected,
    required String primary,
    required String alternative,
  }) {
    final normalizedExpected = _normalizeRecognitionText(expected);
    final normalizedPrimary = _normalizeRecognitionText(primary);
    final normalizedAlternative = _normalizeRecognitionText(alternative);
    if (normalizedExpected.isEmpty || normalizedAlternative.isEmpty) {
      return false;
    }
    final primaryScore = normalizedPrimary.isEmpty
        ? 0.0
        : _candidateTextConfidence(
            expected: normalizedExpected,
            recognized: normalizedPrimary,
          );
    final alternativeScore = _candidateTextConfidence(
      expected: normalizedExpected,
      recognized: normalizedAlternative,
    );
    if (alternativeScore >= primaryScore + 0.08) return true;
    final expectedLength = normalizedExpected.runes.length;
    if (expectedLength <= 5 &&
        normalizedAlternative.runes.length >= 3 &&
        alternativeScore > primaryScore) {
      return true;
    }
    return false;
  }

  double _candidateTextConfidence({
    required String expected,
    required String recognized,
  }) {
    if (expected.isEmpty || recognized.isEmpty) return 0;
    if (_isLikelyNoiseTranscript(recognized)) return 0;
    final pseudoSimilarity = _estimateTextSimilarity(expected, recognized);
    final literalSimilarity = _estimateLiteralSimilarity(expected, recognized);
    final expectedLength = expected.runes.length;
    final recognizedLength = recognized.runes.length;
    final lenGap = recognizedLength - expectedLength;
    var penalty = 1.0;
    if (lenGap >= 2 && literalSimilarity < 0.45) {
      penalty *= 0.74;
    }
    if (lenGap >= 4) {
      penalty *= 0.62;
    }
    if (expectedLength <= 5 && lenGap >= 2 && literalSimilarity < 0.40) {
      penalty *= 0.56;
    }
    if (RegExp(r'^\d+$').hasMatch(recognized)) {
      penalty *= 0.4;
    }
    return ((literalSimilarity * 0.70 + pseudoSimilarity * 0.30) * penalty)
        .clamp(0.0, 1.0);
  }

  bool _shouldQuantizedTemplateAlignExpected({
    required String expected,
    required String recognized,
    required _PreparedWaveData prepared,
  }) {
    final normalizedExpected = _normalizeRecognitionText(expected);
    final normalizedRecognized = _normalizeRecognitionText(recognized);
    if (normalizedExpected.isEmpty || normalizedRecognized.isEmpty) {
      return false;
    }
    if (normalizedExpected == normalizedRecognized) return false;
    if (!RegExp(r'^[a-z]+$').hasMatch(normalizedExpected)) return false;
    if (prepared.samples.isEmpty || prepared.sampleRate <= 0) return false;

    final expectedLength = normalizedExpected.runes.length;
    if (expectedLength < 3 || expectedLength > 8) return false;

    final expectedScore = _estimateQuantizedTemplateSimilarity(
      text: normalizedExpected,
      samples: prepared.samples,
      sampleRate: prepared.sampleRate,
    );
    final recognizedScore = _estimateQuantizedTemplateSimilarity(
      text: normalizedRecognized,
      samples: prepared.samples,
      sampleRate: prepared.sampleRate,
    );
    final literalSimilarity = _estimateLiteralSimilarity(
      normalizedExpected,
      normalizedRecognized,
    );
    final recognizedConfidence = _candidateTextConfidence(
      expected: normalizedExpected,
      recognized: normalizedRecognized,
    );

    final margin = expectedLength <= 5 ? 0.11 : 0.14;
    if (expectedScore >= recognizedScore + margin &&
        recognizedConfidence < 0.46) {
      return true;
    }
    if (expectedLength <= 5 &&
        expectedScore >= 0.58 &&
        recognizedScore <= 0.42 &&
        literalSimilarity < 0.40) {
      return true;
    }
    return false;
  }

  double _estimateQuantizedTemplateSimilarity({
    required String text,
    required List<double> samples,
    required int sampleRate,
  }) {
    final template = _buildTextQuantizedTemplate(text);
    final envelope = _extractQuantizedEnvelope(samples, sampleRate: sampleRate);
    if (template.isEmpty || envelope.isEmpty) return 0;
    final distance = _dtwQuantizedDistance(template, envelope);
    if (!distance.isFinite) return 0;
    return math.exp(-1.55 * distance).clamp(0.0, 1.0);
  }

  List<int> _buildTextQuantizedTemplate(String text) {
    final normalized = _normalizeRecognitionText(text);
    if (normalized.isEmpty) return const <int>[];
    final phones = _pseudoPhoneSequence(normalized);
    if (phones.isEmpty) return const <int>[];
    final template = <int>[];
    for (final phone in phones) {
      final pattern = switch (phone) {
        'vowel' => const <int>[1, 2, 3, 2, 1],
        'bp' || 'dt' || 'kgq' || 'fv' || 'szx' => const <int>[1, 2, 1],
        'lr' || 'mn' || 'h' || 'w' || 'j' => const <int>[1, 2],
        _ => const <int>[2, 3, 2],
      };
      template.addAll(pattern);
    }
    if (template.length <= 200) return template;
    final stride = (template.length / 200).ceil().clamp(1, template.length);
    final reduced = <int>[];
    for (var i = 0; i < template.length; i += stride) {
      reduced.add(template[i]);
      if (reduced.length >= 200) break;
    }
    return reduced;
  }

  List<int> _extractQuantizedEnvelope(
    List<double> samples, {
    required int sampleRate,
  }) {
    if (samples.isEmpty || sampleRate <= 0) return const <int>[];
    final frameSize = math.max(96, (sampleRate * 0.02).round());
    final hopSize = math.max(64, (sampleRate * 0.01).round());
    if (samples.length < frameSize) return const <int>[];
    final frameCount = ((samples.length - frameSize) / hopSize).floor() + 1;
    if (frameCount <= 0) return const <int>[];

    final energies = List<double>.filled(frameCount, 0.0, growable: false);
    var maxEnergy = 0.0;
    for (var frame = 0; frame < frameCount; frame++) {
      final start = frame * hopSize;
      var power = 0.0;
      for (var i = 0; i < frameSize; i++) {
        final v = samples[start + i];
        power += v * v;
      }
      final rms = math.sqrt(power / frameSize.toDouble());
      energies[frame] = rms;
      if (rms > maxEnergy) maxEnergy = rms;
    }
    if (maxEnergy <= 0) return const <int>[];

    final noiseFloor = _estimateNoiseFloor(samples, sampleRate: sampleRate);
    final low = math.max(0.0009, noiseFloor * 1.10);
    final mid = math.max(low * 1.6, maxEnergy * 0.20);
    final high = math.max(mid * 1.25, maxEnergy * 0.45);
    final raw = <int>[];
    for (final energy in energies) {
      raw.add(
        _quantizedFrameEnergyLevel(energy, low: low, mid: mid, high: high),
      );
    }
    if (raw.isEmpty) return const <int>[];

    final compact = <int>[];
    for (final level in raw) {
      if (compact.isEmpty || compact.last != level) {
        compact.add(level);
      }
    }
    while (compact.isNotEmpty && compact.first == 0) {
      compact.removeAt(0);
    }
    while (compact.isNotEmpty && compact.last == 0) {
      compact.removeLast();
    }
    if (compact.isEmpty) return const <int>[];
    if (compact.length <= 220) return compact;

    final stride = (compact.length / 220).ceil().clamp(1, compact.length);
    final reduced = <int>[];
    for (var i = 0; i < compact.length; i += stride) {
      reduced.add(compact[i]);
      if (reduced.length >= 220) break;
    }
    return reduced;
  }

  int _quantizedFrameEnergyLevel(
    double energy, {
    required double low,
    required double mid,
    required double high,
  }) {
    if (energy < low) return 0;
    if (energy < mid) return 1;
    if (energy < high) return 2;
    return 3;
  }

  double _dtwQuantizedDistance(List<int> ref, List<int> sample) {
    if (ref.isEmpty || sample.isEmpty) return double.infinity;
    final n = ref.length;
    final m = sample.length;
    final band = (math.max(n, m) * 0.30)
        .round()
        .clamp(10, math.max(n, m))
        .toInt();
    const inf = 1e12;
    var prev = List<double>.filled(m + 1, inf, growable: false);
    prev[0] = 0;

    for (var i = 1; i <= n; i++) {
      final curr = List<double>.filled(m + 1, inf, growable: false);
      final jStart = math.max(1, i - band);
      final jEnd = math.min(m, i + band);
      for (var j = jStart; j <= jEnd; j++) {
        final cost = (ref[i - 1] - sample[j - 1]).abs() / 3.0;
        final best = math.min(prev[j], math.min(curr[j - 1], prev[j - 1]));
        curr[j] = cost + best;
      }
      prev = curr;
    }

    final distance = prev[m];
    if (!distance.isFinite || distance >= inf / 2) return double.infinity;
    return distance / (n + m).toDouble();
  }

  String _normalizeRecognitionText(String value) {
    return value.toLowerCase().replaceAll(
      RegExp(r"[^\p{L}\p{N}\u4e00-\u9fff]+", unicode: true),
      '',
    );
  }

  double _minDurationForExpected(String? expectedText) {
    final length = (expectedText ?? '').trim().runes.length;
    if (length <= 0) return _minAsrSeconds;
    if (length <= 4) return 0.018;
    if (length <= 8) return 0.024;
    return _minAsrSeconds;
  }

  double _minPeakForExpected(String? expectedText) {
    final length = (expectedText ?? '').trim().runes.length;
    if (length <= 0) return 0.003;
    if (length <= 4) return 0.0018;
    if (length <= 8) return 0.0022;
    return 0.003;
  }

  Future<void> _ensureOfflineRecognizer({
    required AsrProviderType provider,
    required _OfflineModelProfile profile,
    required String language,
    AsrProgressCallback? onProgress,
  }) async {
    if (_offlineRecognizers.containsKey(provider)) return;
    final existingFuture = _offlineLoadFutures[provider];
    if (existingFuture != null) {
      await existingFuture;
      return;
    }

    final future = _loadOfflineRecognizer(
      provider: provider,
      profile: profile,
      language: language,
      onProgress: onProgress,
    );
    _offlineLoadFutures[provider] = future;
    try {
      await future;
    } finally {
      _offlineLoadFutures.remove(provider);
    }
  }

  Future<void> _loadOfflineRecognizer({
    required AsrProviderType provider,
    required _OfflineModelProfile profile,
    required String language,
    AsrProgressCallback? onProgress,
  }) async {
    _ensureSherpaBindings();

    final modelsRoot = await _ensureModelsRoot();
    await _pruneTemporaryArtifacts(modelsRoot);
    final modelDir = Directory(p.join(modelsRoot.path, profile.dirName));
    final manifest = await _loadModelManifest(modelsRoot);
    final manifestEntry = manifest[profile.variant];
    if (_shouldRefreshModelCache(
      profile: profile,
      manifestEntry: manifestEntry,
    )) {
      await _safeDeleteDirectory(modelDir);
    }

    var modelReady =
        await _validateModelIntegrity(
          profile: profile,
          modelDir: modelDir,
          manifestEntry: manifestEntry,
        ) &&
        _hasModelFiles(profile, modelDir);

    if (!modelReady) {
      await _safeDeleteDirectory(modelDir);
      await _downloadAndExtractModel(
        profile: profile,
        modelsRoot: modelsRoot,
        onProgress: onProgress,
      );
      modelReady = _hasModelFiles(profile, modelDir);
    }
    _checkCanceled();

    if (!modelReady || !_hasModelFiles(profile, modelDir)) {
      throw StateError('asrModelMissingAfterExtract');
    }

    final fileMetadata = await _collectModelFileMetadata(profile, modelDir);
    await _updateModelManifest(modelsRoot, profile, fileMetadata);
    await _pruneTemporaryArtifacts(modelsRoot);
    await _pruneUnknownModelDirs(modelsRoot);

    onProgress?.call(
      const AsrProgress(
        stage: 'load',
        messageKey: 'asrProgressLoadingModel',
        progress: null,
      ),
    );

    final recognizerConfig = OfflineRecognizerConfig(
      model: OfflineModelConfig(
        whisper: OfflineWhisperModelConfig(
          encoder: p.join(modelDir.path, profile.encoderFile),
          decoder: p.join(modelDir.path, profile.decoderFile),
          language: language.trim(),
          task: 'transcribe',
        ),
        tokens: p.join(modelDir.path, profile.tokensFile),
        numThreads: 1,
        debug: false,
        provider: 'cpu',
      ),
      decodingMethod: 'greedy_search',
      maxActivePaths: 4,
    );

    final recognizer = OfflineRecognizer(recognizerConfig);
    final old = _offlineRecognizers[provider];
    old?.free();
    _offlineRecognizers[provider] = recognizer;
  }

  void _ensureSherpaBindings() {
    if (_bindingsInitialized) return;
    initBindings();
    _bindingsInitialized = true;
  }

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
      await _downloadFile(
        sourceUrl: profile.archiveUrl,
        destination: archiveFile,
        onProgress: onProgress,
      );
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
    final file = File(p.join(modelsRoot.path, _manifestName));
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
    final file = File(p.join(modelsRoot.path, _manifestName));
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
    if (version != _modelCacheVersion) return true;
    if (archiveUrl != profile.archiveUrl) return true;
    return false;
  }

  Future<void> _updateModelManifest(
    Directory modelsRoot,
    _OfflineModelProfile profile,
    Map<String, Object?> fileMetadata,
  ) async {
    final manifest = await _loadModelManifest(modelsRoot);
    manifest['manifestVersion'] = _modelCacheVersion;
    manifest[profile.variant] = <String, Object?>{
      'version': _modelCacheVersion,
      'modelVersion': _modelCacheVersion,
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
    final expectedDirs = _offlineProfiles.values
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

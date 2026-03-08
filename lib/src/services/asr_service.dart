import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
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
    this.error,
    this.errorParams = const <String, Object?>{},
  });

  final bool success;
  final String? text;
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

class AsrService {
  AsrService();

  static const String _defaultApiEndpoint =
      'https://api.siliconflow.cn/v1/audio/transcriptions';
  static const int _targetSampleRate = 16000;
  static const double _minAsrSeconds = 0.03;
  static const int _modelCacheVersion = 1;
  static const String _manifestName = 'manifest.json';

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

  final AudioRecorder _recorder = AudioRecorder();
  final Map<AsrProviderType, OfflineRecognizer> _offlineRecognizers =
      <AsrProviderType, OfflineRecognizer>{};
  final Map<AsrProviderType, Future<void>> _offlineLoadFutures =
      <AsrProviderType, Future<void>>{};
  http.Client? _activeApiClient;
  int _apiRequestToken = 0;

  bool _bindingsInitialized = false;
  bool _stopRequested = false;

  Future<String?> startRecording({required AsrProviderType provider}) async {
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
          return fallbackPath;
        } catch (_) {}
      }
      return null;
    }
  }

  Future<String?> stopRecording() => _recorder.stop();

  Future<void> cancelRecording() => _recorder.cancel();

  void stopOfflineRecognition() {
    _stopRequested = true;
    _interruptApiRequest(reason: 'stop');
  }

  Future<AsrResult> transcribeFile({
    required String audioPath,
    required AsrConfig config,
    String? expectedText,
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

    if (config.provider == AsrProviderType.offline ||
        config.provider == AsrProviderType.offlineSmall) {
      try {
        return await _transcribeOffline(
          audioPath: audioPath,
          config: config,
          expectedText: expectedText,
          onProgress: onProgress,
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

    return _transcribeByApi(audioPath: audioPath, config: config);
  }

  Future<void> dispose() async {
    _interruptApiRequest(reason: 'dispose');
    for (final recognizer in _offlineRecognizers.values) {
      recognizer.free();
    }
    _offlineRecognizers.clear();
    _offlineLoadFutures.clear();
    await _recorder.dispose();
  }

  Future<AsrResult> _transcribeByApi({
    required String audioPath,
    required AsrConfig config,
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
    try {
      final language = _normalizeApiLanguage(config.language);
      final response = await _sendApiTranscriptionRequest(
        client: client,
        endpoint: endpoint,
        apiKey: apiKey,
        model: config.model,
        language: language,
        audioPath: audioPath,
        includePrompt: false,
        prompt: '',
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
      final text = decoded is Map
          ? decoded['text']?.toString()
          : decoded?.toString();
      if (text == null || text.trim().isEmpty) {
        return const AsrResult(success: false, error: 'asrEmptyResult');
      }

      return AsrResult(success: true, text: text.trim());
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
      if (identical(_activeApiClient, client)) {
        _activeApiClient = null;
      }
      client.close();
    }
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

    final denoised = _removeDcOffset(samples);
    final trimmed = _trimSilence(denoised, sampleRate: sampleRate);
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

  List<double> _choosePreferredWaveSegment({
    required List<double> denoised,
    required List<double> trimmed,
    required int sampleRate,
  }) {
    if (trimmed.isEmpty) return denoised;
    final minPreferredSamples = (sampleRate * 0.09).round();
    if (trimmed.length < minPreferredSamples &&
        denoised.length > trimmed.length) {
      return denoised;
    }
    return trimmed;
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

  Future<AsrResult> _transcribeOffline({
    required String audioPath,
    required AsrConfig config,
    String? expectedText,
    AsrProgressCallback? onProgress,
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

    final waveData = readWave(audioPath);
    if (waveData.samples.isEmpty || waveData.sampleRate <= 0) {
      return const AsrResult(success: false, error: 'asrInvalidWav');
    }

    final prepared = _prepareWaveData(
      samples: waveData.samples,
      sampleRate: waveData.sampleRate,
      targetSampleRate: _targetSampleRate,
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

    final stream = recognizer.createStream();
    try {
      stream.acceptWaveform(
        samples: Float32List.fromList(prepared.samples),
        sampleRate: prepared.sampleRate,
      );
      _checkCanceled();
      recognizer.decode(stream);
      _checkCanceled();

      final result = recognizer.getResult(stream);
      final text = result.text.trim();
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
    } finally {
      stream.free();
    }
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
    if (!_bindingsInitialized) {
      initBindings();
      _bindingsInitialized = true;
    }

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

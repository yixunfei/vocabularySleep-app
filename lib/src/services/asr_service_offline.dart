part of 'asr_service.dart';

extension AsrServiceOffline on AsrService {
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
      RegExp(r'[^\p{L}\p{N}\u4e00-\u9fff]+', unicode: true),
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
    final profile = AsrService._offlineProfiles[config.provider];
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
      targetSampleRate: AsrService._targetSampleRate,
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
    if (prepared.samples.length <
        (AsrService._targetSampleRate * minSeconds).round()) {
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
        targetSampleRate: AsrService._targetSampleRate,
      );
      await _writePreparedDebugWav(
        debugRunDir,
        stem: '${config.provider.name}_processed_loose',
        prepared: loosePrepared,
      );
      if (loosePrepared.samples.isNotEmpty &&
          loosePrepared.samples.length >=
              (AsrService._targetSampleRate * minSeconds).round() &&
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
      RegExp(r'[^\p{L}\p{N}\u4e00-\u9fff]+', unicode: true),
      '',
    );
  }

  double _minDurationForExpected(String? expectedText) {
    final length = (expectedText ?? '').trim().runes.length;
    if (length <= 0) return AsrService._minAsrSeconds;
    if (length <= 4) return 0.018;
    if (length <= 8) return 0.024;
    return AsrService._minAsrSeconds;
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
          language: normalizeOfflineAsrLanguage(
            language,
            englishOnlyModel:
                profile.variant.endsWith('.en') ||
                profile.dirName.endsWith('.en'),
          ),
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
}

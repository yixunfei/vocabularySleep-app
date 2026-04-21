part of 'asr_service.dart';

extension AsrServiceAudio on AsrService {
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
}

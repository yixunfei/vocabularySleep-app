part of 'toolbox_audio_service.dart';

Uint8List _buildClick(
  double primaryFrequency, {
  required double overtone,
  required double durationSeconds,
}) {
  const sampleRate = 24000;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0);
  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final envelope = (1 - math.exp(-110 * t)) * math.exp(-38 * t);
    final noise = (math.sin(i * 12.9898) + math.cos(i * 78.233)) * 0.025;
    final value =
        math.sin(math.pi * 2 * primaryFrequency * t) * 0.7 +
        math.sin(math.pi * 2 * overtone * t + 0.3) * 0.24 +
        noise;
    samples[i] = value * envelope;
  }
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.98);
}

Uint8List _buildFocusBeatClick({
  required String style,
  required int layer,
  required int variant,
}) {
  const sampleRate = 32000;
  final normalizedLayer = layer.clamp(0, 3);
  final styleSeed = switch (style) {
    'hypno' => 0.9,
    'dew' => 1.8,
    'gear' => 2.7,
    'steps' => 3.6,
    _ => 0.2,
  };
  final (
    baseFreq,
    brightness,
    airMix,
    bodyMix,
    ringDecay,
    fmDepth,
    baseDuration,
  ) = switch (style) {
    'hypno' => (840.0, 0.56, 0.09, 0.15, 8.6, 0.022, 0.11),
    'dew' => (1720.0, 0.74, 0.06, 0.07, 9.8, 0.018, 0.095),
    'gear' => (650.0, 0.48, 0.14, 0.24, 7.8, 0.035, 0.13),
    'steps' => (460.0, 0.42, 0.12, 0.28, 6.4, 0.016, 0.14),
    _ => (1030.0, 0.64, 0.08, 0.17, 8.9, 0.024, 0.105),
  };
  final variantId = variant.clamp(0, 31).toInt();
  double vrand(int salt) =>
      _variantRandom(variant: variantId, seed: styleSeed, salt: salt);

  final brightnessVar = (brightness + (vrand(1) - 0.5) * 0.08)
      .clamp(0.0, 1.0)
      .toDouble();
  final baseFreqVar = baseFreq * (0.986 + vrand(2) * 0.028);
  final airMixVar = airMix * (0.9 + vrand(3) * 0.2);
  final bodyMixVar = bodyMix * (0.9 + vrand(4) * 0.2);
  final ringDecayVar = ringDecay * (0.94 + vrand(5) * 0.14);
  final fmDepthVar = fmDepth * (0.86 + vrand(6) * 0.24);
  final baseHarmonicRatios = switch (normalizedLayer) {
    0 => const <double>[1.0, 2.02, 3.01, 4.4],
    1 => const <double>[1.0, 1.92, 2.85],
    2 => const <double>[1.0, 1.5],
    _ => const <double>[1.0],
  };
  final harmonicRatios = <double>[
    for (var i = 0; i < baseHarmonicRatios.length; i += 1)
      baseHarmonicRatios[i] * (1 + (vrand(10 + i) - 0.5) * 0.016),
  ];
  final layerGain = switch (normalizedLayer) {
    0 => 1.0,
    1 => 0.84,
    2 => 0.67,
    _ => 0.48,
  };
  final pitchMul = switch (normalizedLayer) {
    0 => 1.08,
    1 => 1.0,
    2 => 0.95,
    _ => 0.90,
  };
  final attackSec = switch (normalizedLayer) {
    0 => 0.0026,
    1 => 0.0022,
    2 => 0.0018,
    _ => 0.0012,
  };
  final decaySec = switch (normalizedLayer) {
    0 => 0.030,
    1 => 0.026,
    2 => 0.021,
    _ => 0.015,
  };
  final sustainLevel = switch (normalizedLayer) {
    0 => 0.34,
    1 => 0.24,
    2 => 0.14,
    _ => 0.08,
  };
  final releaseSec = switch (normalizedLayer) {
    0 => 0.064,
    1 => 0.050,
    2 => 0.040,
    _ => 0.030,
  };
  final durationSec = baseDuration + (3 - normalizedLayer) * 0.006 + releaseSec;
  final totalSamples = (sampleRate * durationSec).round();
  final samples = List<double>.filled(totalSamples, 0);
  final harmonicWeights = <double>[
    for (var i = 0; i < harmonicRatios.length; i += 1)
      math.pow(i + 1, -(1.05 + brightnessVar * 0.22)).toDouble(),
  ];
  final attackPhase = vrand(20) * math.pi * 2;

  double adsr(double t) {
    if (t <= 0) {
      return 0;
    }
    if (t < attackSec) {
      return (t / attackSec).clamp(0.0, 1.0);
    }
    final decayT = t - attackSec;
    if (decayT < decaySec) {
      final progress = (decayT / decaySec).clamp(0.0, 1.0);
      return 1.0 + (sustainLevel - 1.0) * progress;
    }
    final releaseStart = durationSec - releaseSec;
    if (t < releaseStart) {
      return sustainLevel;
    }
    final releaseT = ((t - releaseStart) / releaseSec).clamp(0.0, 1.0);
    return sustainLevel * (1 - _smoothStep(releaseT));
  }

  var airState = 0.0;
  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final envelope = adsr(t);
    if (envelope <= 0.00001) {
      continue;
    }

    // 2ms downward FM sweep to simulate a struck body transient.
    final fmHead = (1.0 - (t / 0.002).clamp(0.0, 1.0));
    final fmEnv = fmHead * math.exp(-420 * t);
    final fm =
        fmDepthVar *
        fmEnv *
        math.sin(math.pi * 2 * (baseFreqVar * 2.8) * t + 0.13 + attackPhase);

    var tone = 0.0;
    for (var h = 0; h < harmonicRatios.length; h += 1) {
      final ratio = harmonicRatios[h];
      final detune = 1 + h * 0.0032 + fm * (0.85 + h * 0.12);
      final harmonicFreq = baseFreqVar * pitchMul * ratio * detune;
      tone +=
          math.sin(
            math.pi * 2 * harmonicFreq * t + h * 0.21 + attackPhase * 0.18,
          ) *
          harmonicWeights[h];
    }
    tone *= (0.62 + brightnessVar * 0.28);

    final strikeFreq = baseFreqVar * (3.2 + 0.24 * brightnessVar);
    final strikeSweep = 1.0 + 1.2 * fmHead;
    final impact =
        math.sin(math.pi * 2 * strikeFreq * strikeSweep * t + 0.07) *
        math.exp(-1300 * t) *
        (0.24 + 0.06 * (3 - normalizedLayer));
    final impactNoise =
        (math.sin(i * 67.31 + attackPhase) + math.cos(i * 21.17 + styleSeed)) *
        0.5 *
        math.exp(-1600 * t) *
        (0.016 + brightnessVar * 0.018);

    final body =
        math.sin(math.pi * 2 * baseFreqVar * 0.52 * t + 0.86) *
        bodyMixVar *
        math.exp(-ringDecayVar * t);

    final noiseRaw =
        (math.sin(i * 12.9898 + baseFreqVar * 0.0012 + attackPhase) +
            math.cos(i * 78.233 + baseFreqVar * 0.00073 + attackPhase * 0.4)) *
        0.5;
    // High-pass-ish filtered noise for "air" texture.
    airState += (noiseRaw - airState) * 0.78;
    final airy = (noiseRaw - airState) * airMixVar * math.exp(-26 * t);

    final sample =
        (tone + impact + impactNoise + body + airy) *
        envelope *
        layerGain *
        1.16;
    samples[i] = _softClip(sample);
  }

  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.97);
}

part of 'toolbox_audio_service.dart';

Uint8List _buildFreeChimeLayer(
  String layer, {
  required double intensity,
  required int variant,
}) {
  return switch (layer) {
    'shaker' => _buildFreeChimeNoise(
      intensity: intensity,
      variant: variant,
      durationSeconds: 0.34,
      grainRate: 92,
      brightness: 0.72,
      bodyFrequency: 980,
    ),
    'water' => _buildFreeChimeNoise(
      intensity: intensity,
      variant: variant,
      durationSeconds: 0.62,
      grainRate: 42,
      brightness: 0.38,
      bodyFrequency: 420,
      liquid: true,
    ),
    'wind_chime' => _buildFreeChimeBell(
      intensity: intensity,
      variant: variant,
      baseFrequency: 1046.5,
      tail: 0.9,
      bright: true,
    ),
    'leaves' => _buildFreeChimeNoise(
      intensity: intensity,
      variant: variant,
      durationSeconds: 0.42,
      grainRate: 64,
      brightness: 0.28,
      bodyFrequency: 520,
      papery: true,
    ),
    'bubbles' => _buildFreeChimeBubbles(intensity: intensity, variant: variant),
    'rain' => _buildFreeChimeNoise(
      intensity: intensity,
      variant: variant,
      durationSeconds: 0.52,
      grainRate: 110,
      brightness: 0.54,
      bodyFrequency: 760,
      rain: true,
    ),
    'impact' => _buildFreeChimeImpact(intensity: intensity, variant: variant),
    'kuaiban' => _buildFreeChimeKuaiban(intensity: intensity, variant: variant),
    'gong_drum' => _buildFreeChimeGongDrum(
      intensity: intensity,
      variant: variant,
    ),
    'marble' => _buildFreeChimeMarble(intensity: intensity, variant: variant),
    _ => _buildFreeChimeBell(
      intensity: intensity,
      variant: variant,
      baseFrequency: 880,
      tail: 0.82,
      bright: true,
    ),
  };
}

Uint8List _buildFreeChimeNoise({
  required double intensity,
  required int variant,
  required double durationSeconds,
  required double grainRate,
  required double brightness,
  required double bodyFrequency,
  bool liquid = false,
  bool papery = false,
  bool rain = false,
}) {
  const sampleRate = 24000;
  final normalizedIntensity = intensity.clamp(0.0, 1.0).toDouble();
  final variantId = variant.clamp(0, 31).toInt();
  final duration = durationSeconds + normalizedIntensity * 0.18;
  final totalSamples = (sampleRate * duration).round();
  final samples = List<double>.filled(totalSamples, 0);
  final seed =
      (liquid
          ? 2.1
          : papery
          ? 3.4
          : rain
          ? 4.7
          : 1.0) +
      normalizedIntensity;

  double vrand(int salt) =>
      _variantRandom(variant: variantId, seed: seed, salt: salt);

  var lowState = 0.0;
  var highState = 0.0;
  final phase = vrand(1) * math.pi * 2;
  final sweep = 0.82 + vrand(2) * 0.36;
  final grains = <double>[
    for (
      var t = vrand(3) * 0.018;
      t < duration;
      t += 1 / (grainRate * (0.75 + vrand(20 + (t * 100).floor()) * 0.6))
    )
      t,
  ];
  var grainIndex = 0;

  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final progress = (t / duration).clamp(0.0, 1.0);
    final fade = _smoothStep((1 - progress).clamp(0.0, 1.0));
    final motion =
        0.72 + 0.28 * math.sin(math.pi * 2 * (1.2 + sweep) * t + phase);
    final rawNoise =
        (math.sin((i + 1) * (13.17 + brightness * 9.0) + phase) +
            math.cos((i + 1) * (47.71 + brightness * 21.0) + phase * 0.31) +
            math.sin((i + 1) * (91.13 + vrand(4) * 8.0))) /
        3;
    lowState += (rawNoise - lowState) * (liquid ? 0.08 : 0.22);
    highState += (rawNoise - highState) * (rain ? 0.62 : 0.42);
    final filtered = liquid
        ? lowState * 0.74 + (rawNoise - highState) * 0.22
        : papery
        ? (rawNoise - lowState) * 0.64 + lowState * 0.24
        : rain
        ? (rawNoise - lowState) * 0.72
        : (rawNoise - lowState) * 0.5 + rawNoise * 0.22;

    var grainsValue = 0.0;
    while (grainIndex + 1 < grains.length && grains[grainIndex + 1] < t) {
      grainIndex += 1;
    }
    for (var offset = 0; offset < 3; offset += 1) {
      final index = grainIndex + offset;
      if (index >= grains.length) break;
      final local = t - grains[index];
      if (local < 0 || local > 0.034) continue;
      final popEnvelope = math.exp(-80 * local) * (1 - math.exp(-220 * local));
      grainsValue +=
          math.sin(
            math.pi *
                2 *
                (bodyFrequency * (0.72 + offset * 0.18 + vrand(30 + index))) *
                local,
          ) *
          popEnvelope *
          (0.36 + brightness * 0.18);
    }

    final body =
        math.sin(math.pi * 2 * bodyFrequency * (0.36 + brightness * 0.18) * t) *
        (liquid
            ? 0.05
            : papery
            ? 0.025
            : 0.035) *
        math.exp(-3.8 * t);
    samples[i] = _softClip(
      (filtered * (0.26 + brightness * 0.22) + grainsValue + body) *
          fade *
          motion *
          (0.56 + normalizedIntensity * 0.62),
    );
  }

  _applyOnePoleLowPass(
    samples,
    sampleRate: sampleRate,
    cutoffHz: liquid
        ? 3400
        : papery
        ? 5200
        : rain
        ? 7200
        : 6400,
  );
  _applySchroederReverb(
    samples,
    sampleRate: sampleRate,
    amount: liquid
        ? 0.18
        : rain
        ? 0.08
        : 0.12,
  );
  _applyDcBlock(samples, pole: 0.995);
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.88);
}

Uint8List _buildFreeChimeBell({
  required double intensity,
  required int variant,
  required double baseFrequency,
  required double tail,
  required bool bright,
}) {
  const sampleRate = 32000;
  final normalizedIntensity = intensity.clamp(0.0, 1.0).toDouble();
  final variantId = variant.clamp(0, 31).toInt();
  double vrand(int salt) => _variantRandom(
    variant: variantId,
    seed: baseFrequency * 0.001 + normalizedIntensity,
    salt: salt,
  );

  final frequency = baseFrequency * (0.86 + vrand(1) * 0.34);
  final durationSeconds = 0.68 + tail * 1.28 + normalizedIntensity * 0.28;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0);
  final ratios = bright
      ? const <double>[1, 2.4, 3.8, 5.7]
      : const <double>[1, 1.98, 3.02];
  final phase = vrand(2) * math.pi * 2;

  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final attack = 1 - math.exp(-180 * t);
    final fade = (1 - t / durationSeconds).clamp(0.0, 1.0);
    var value = 0.0;
    for (var partial = 0; partial < ratios.length; partial += 1) {
      final partialDecay = (0.58 + partial * 0.42) / tail;
      value +=
          math.sin(
            math.pi *
                    2 *
                    frequency *
                    ratios[partial] *
                    (1 + (vrand(10 + partial) - 0.5) * 0.006) *
                    t +
                phase +
                partial * 0.37,
          ) *
          (0.68 / (partial + 1)) *
          math.exp(-partialDecay * t);
    }
    final strike =
        (math.sin((i + 1) * 39.7 + phase) +
            math.cos((i + 1) * 71.1 + phase * 0.4)) *
        0.028 *
        math.exp(-96 * t);
    samples[i] = _softClip(
      (value + strike) * attack * fade * (0.52 + normalizedIntensity * 0.56),
    );
  }

  _applySchroederReverb(
    samples,
    sampleRate: sampleRate,
    amount: bright ? 0.34 : 0.24,
  );
  _applyDcBlock(samples, pole: 0.996);
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.86);
}

Uint8List _buildFreeChimeBubbles({
  required double intensity,
  required int variant,
}) {
  const sampleRate = 24000;
  final normalizedIntensity = intensity.clamp(0.0, 1.0).toDouble();
  final variantId = variant.clamp(0, 31).toInt();
  double vrand(int salt) => _variantRandom(
    variant: variantId,
    seed: 5.8 + normalizedIntensity,
    salt: salt,
  );
  final durationSeconds = 0.46 + normalizedIntensity * 0.2;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0);
  final popCount = 2 + (normalizedIntensity * 5).round();

  for (var pop = 0; pop < popCount; pop += 1) {
    final start = (vrand(10 + pop) * durationSeconds * 0.8 * sampleRate)
        .round();
    final freq = 620 + vrand(30 + pop) * 1280 + normalizedIntensity * 460;
    final length = (sampleRate * (0.055 + vrand(50 + pop) * 0.07)).round();
    for (var j = 0; j < length && start + j < totalSamples; j += 1) {
      final t = j / sampleRate;
      final sweep = 1 + 0.7 * math.exp(-34 * t);
      final envelope = (1 - math.exp(-180 * t)) * math.exp(-22 * t);
      samples[start + j] +=
          math.sin(math.pi * 2 * freq * sweep * t) *
          envelope *
          (0.32 + normalizedIntensity * 0.18);
    }
  }
  _applySchroederReverb(samples, sampleRate: sampleRate, amount: 0.16);
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.9);
}

Uint8List _buildFreeChimeImpact({
  required double intensity,
  required int variant,
}) {
  final tone = (0.32 + intensity * 0.54).clamp(0.0, 1.0).toDouble();
  final tail = (0.18 + intensity * 0.35).clamp(0.0, 1.0).toDouble();
  return _buildDrumHit(
    variant.isEven ? 'snare' : 'tom',
    'acoustic',
    tone,
    tail,
    variant % 3 == 0 ? 'metal' : 'wood',
  );
}

Uint8List _buildFreeChimeKuaiban({
  required double intensity,
  required int variant,
}) {
  const sampleRate = 32000;
  final normalizedIntensity = intensity.clamp(0.0, 1.0).toDouble();
  final variantId = variant.clamp(0, 31).toInt();
  final durationSeconds = 0.2 + normalizedIntensity * 0.08;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0);
  double vrand(int salt) => _variantRandom(
    variant: variantId,
    seed: 8.6 + normalizedIntensity,
    salt: salt,
  );

  final strikeCount = 2 + (variantId % 3 == 0 ? 1 : 0);
  final spacing = 0.032 + vrand(1) * 0.022;
  for (var strike = 0; strike < strikeCount; strike += 1) {
    final start = (sampleRate * (0.008 + strike * spacing)).round();
    final bodyFrequency = 760 + vrand(10 + strike) * 360 + strike * 55;
    final slapFrequency = 1550 + vrand(20 + strike) * 900;
    final length = (sampleRate * (0.09 + normalizedIntensity * 0.025)).round();
    final strikeGain =
        (0.58 + normalizedIntensity * 0.42) * (1 - strike * 0.18);
    final phase = vrand(30 + strike) * math.pi * 2;
    for (var j = 0; j < length && start + j < totalSamples; j += 1) {
      final t = j / sampleRate;
      final attack = 1 - math.exp(-900 * t);
      final bodyEnvelope = attack * math.exp(-58 * t);
      final clickEnvelope = math.exp(-230 * t);
      final woodTone =
          math.sin(math.pi * 2 * bodyFrequency * t + phase) * 0.42 +
          math.sin(math.pi * 2 * slapFrequency * t + phase * 0.4) * 0.26;
      final dryClick =
          (math.sin((j + 1) * 83.7 + phase) +
              math.cos((j + 1) * 143.9 + phase * 0.2)) *
          0.16 *
          clickEnvelope;
      samples[start + j] += _softClip(
        (woodTone * bodyEnvelope + dryClick) * strikeGain,
      );
    }
  }

  _applyOnePoleLowPass(samples, sampleRate: sampleRate, cutoffHz: 7800);
  _applyDcBlock(samples, pole: 0.995);
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.95);
}

Uint8List _buildFreeChimeGongDrum({
  required double intensity,
  required int variant,
}) {
  const sampleRate = 24000;
  final normalizedIntensity = intensity.clamp(0.0, 1.0).toDouble();
  final durationSeconds = 0.9 + normalizedIntensity * 0.7;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0);
  final base = 88 + normalizedIntensity * 52 + (variant % 4) * 7;
  final phase =
      _variantRandom(variant: variant, seed: 6.7, salt: 1) * math.pi * 2;

  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final drumEnv = math.exp(-(5.0 - normalizedIntensity * 1.8) * t);
    final gongEnv = (1 - math.exp(-34 * t)) * math.exp(-1.7 * t);
    final drum =
        math.sin(math.pi * 2 * (base * (1 + math.exp(-20 * t) * 0.42)) * t) *
        0.72 *
        drumEnv;
    final gong =
        (math.sin(math.pi * 2 * base * 3.1 * t + phase) * 0.24 +
            math.sin(math.pi * 2 * base * 4.7 * t + phase * 0.3) * 0.14) *
        gongEnv;
    final strike =
        (math.sin((i + 1) * 42.3 + phase) + math.cos((i + 1) * 77.8)) *
        0.035 *
        math.exp(-100 * t);
    samples[i] = _softClip((drum + gong + strike) * (0.68 + intensity * 0.42));
  }

  _applySchroederReverb(samples, sampleRate: sampleRate, amount: 0.32);
  _applyDcBlock(samples, pole: 0.996);
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.9);
}

Uint8List _buildFreeChimeMarble({
  required double intensity,
  required int variant,
}) {
  const sampleRate = 32000;
  final normalizedIntensity = intensity.clamp(0.0, 1.0).toDouble();
  final durationSeconds = 0.5 + normalizedIntensity * 0.26;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0);
  final bounceCount = 3 + (normalizedIntensity * 5).round();
  double vrand(int salt) => _variantRandom(
    variant: variant,
    seed: 7.9 + normalizedIntensity,
    salt: salt,
  );

  for (var bounce = 0; bounce < bounceCount; bounce += 1) {
    final progress = bounce / math.max(1, bounceCount - 1);
    final start = (sampleRate * durationSeconds * progress * 0.78).round();
    final freq = 1180 + vrand(10 + bounce) * 1300 + bounce * 120;
    final length = (sampleRate * (0.06 + progress * 0.025)).round();
    final gain = (1 - progress * 0.68) * (0.34 + normalizedIntensity * 0.22);
    for (var j = 0; j < length && start + j < totalSamples; j += 1) {
      final t = j / sampleRate;
      final envelope = (1 - math.exp(-220 * t)) * math.exp(-36 * t);
      final roll =
          math.sin(math.pi * 2 * freq * t) * 0.62 +
          math.sin(math.pi * 2 * freq * 1.78 * t + 0.3) * 0.2;
      final click =
          (math.sin((j + 1) * 88.3) + math.cos((j + 1) * 131.9)) *
          0.018 *
          math.exp(-140 * t);
      samples[start + j] += _softClip((roll + click) * envelope * gain);
    }
  }

  _applySchroederReverb(samples, sampleRate: sampleRate, amount: 0.18);
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.88);
}

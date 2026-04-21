part of 'toolbox_audio_service.dart';

({
  double body,
  double edge,
  double air,
  double vibratoDepth,
  double vibratoRate,
  double bowNoise,
  double warmth,
})
_resolveViolinProfile(String style, String variant) {
  final styleProfile = switch (style) {
    'warm' => (
      body: 0.7,
      edge: 0.22,
      air: 0.12,
      vibratoDepth: 0.0038,
      vibratoRate: 5.2,
      bowNoise: 0.1,
      warmth: 1.14,
    ),
    'glass' => (
      body: 0.56,
      edge: 0.34,
      air: 0.17,
      vibratoDepth: 0.0028,
      vibratoRate: 6.1,
      bowNoise: 0.08,
      warmth: 0.86,
    ),
    _ => (
      body: 0.63,
      edge: 0.27,
      air: 0.14,
      vibratoDepth: 0.0033,
      vibratoRate: 5.6,
      bowNoise: 0.09,
      warmth: 1.0,
    ),
  };

  final variantMod = variant == 'b'
      ? (
          body: 0.93,
          edge: 1.22,
          air: 1.14,
          vibratoDepth: 0.88,
          vibratoRate: 1.08,
          bowNoise: 1.12,
          warmth: 0.92,
        )
      : (
          body: 1.08,
          edge: 0.92,
          air: 0.96,
          vibratoDepth: 1.03,
          vibratoRate: 0.96,
          bowNoise: 0.94,
          warmth: 1.06,
        );

  return (
    body: (styleProfile.body * variantMod.body).clamp(0.2, 1.3),
    edge: (styleProfile.edge * variantMod.edge).clamp(0.06, 0.8),
    air: (styleProfile.air * variantMod.air).clamp(0.04, 0.6),
    vibratoDepth: (styleProfile.vibratoDepth * variantMod.vibratoDepth).clamp(
      0.001,
      0.02,
    ),
    vibratoRate: (styleProfile.vibratoRate * variantMod.vibratoRate).clamp(
      3.5,
      8.2,
    ),
    bowNoise: (styleProfile.bowNoise * variantMod.bowNoise).clamp(0.01, 0.3),
    warmth: (styleProfile.warmth * variantMod.warmth).clamp(0.7, 1.4),
  );
}

int _violinVariantSeed(String variant, double frequency) {
  final base = variant == 'b' ? 17 : 5;
  return (base + (frequency * 0.07).round()).clamp(0, 31);
}

Uint8List _buildViolinNote({
  required double frequency,
  required String style,
  required String variant,
  required double bow,
  required double reverb,
}) {
  const sampleRate = 32000;
  final normalizedBow = bow.clamp(0.15, 1.0).toDouble();
  final profile = _resolveViolinProfile(style, variant);
  final durationSeconds = 2.2 + normalizedBow * 0.9;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0.0);

  final seed = _violinVariantSeed(variant, frequency);
  final phaseShift =
      _variantRandom(variant: seed, seed: frequency * 0.0019, salt: 1) *
      math.pi *
      2;
  final attackTime = (0.025 + (1 - normalizedBow) * 0.09).clamp(0.02, 0.16);
  final releaseTime = (0.34 + reverb * 0.72).clamp(0.24, 0.95);

  var bowNoiseState = 0.0;
  var tonalState = 0.0;
  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final contour = _violinContour(
      t: t,
      durationSeconds: durationSeconds,
      attackTime: attackTime,
      releaseTime: releaseTime,
    );

    final vibratoRamp = _smoothStep(
      ((t - attackTime * 0.85) / (0.28 + normalizedBow * 0.24)).clamp(0.0, 1.0),
    );
    final drift = _violinDrift(
      t: t,
      phaseShift: phaseShift,
      bow: normalizedBow,
    );
    final vibrato =
        math.sin(math.pi * 2 * profile.vibratoRate * t + phaseShift) *
        profile.vibratoDepth *
        (0.55 + normalizedBow * 0.7) *
        vibratoRamp;
    final instantFrequency = frequency * (1 + vibrato + drift);

    var harmonic =
        math.sin(math.pi * 2 * instantFrequency * t) *
        (0.58 + profile.body * 0.2);
    harmonic +=
        math.sin(math.pi * 2 * instantFrequency * 2 * t + 0.18) *
        (0.17 + profile.warmth * 0.08);
    harmonic +=
        math.sin(math.pi * 2 * instantFrequency * 3 * t + 0.74) *
        (0.11 + profile.edge * 0.13);
    harmonic +=
        math.sin(math.pi * 2 * instantFrequency * 4.02 * t + 1.12) *
        (0.05 + profile.edge * 0.12);
    harmonic +=
        math.sin(math.pi * 2 * instantFrequency * 5.35 * t + 1.76) *
        (0.03 + profile.air * 0.09);

    var bodyRes =
        math.sin(math.pi * 2 * instantFrequency * 0.52 * t + 0.31) *
        (0.05 + profile.body * 0.05);
    bodyRes +=
        math.sin(math.pi * 2 * instantFrequency * 0.97 * t + 1.07) *
        (0.025 + profile.warmth * 0.035);

    final rawNoise =
        (math.sin((i + 1) * 31.77 + phaseShift) +
            math.cos((i + 1) * 52.41 + phaseShift * 0.6)) *
        0.5;
    bowNoiseState += (rawNoise - bowNoiseState) * (0.04 + normalizedBow * 0.08);
    final bowNoise =
        bowNoiseState *
        profile.bowNoise *
        (0.16 + normalizedBow * 0.54) *
        (0.55 + contour * 0.9);

    final attackScrape =
        math.exp(-42 * t) *
        (0.025 + profile.edge * 0.07 + normalizedBow * 0.035);
    final rosin =
        math.sin(
          math.pi * 2 * (8.2 + normalizedBow * 3.6) * t + phaseShift * 0.2,
        ) *
        (0.01 + profile.edge * 0.043);

    final target = _softClip(
      (harmonic + bodyRes + bowNoise + rosin + attackScrape) * contour * 0.94,
    );
    tonalState += (target - tonalState) * (0.28 + profile.body * 0.08);
    samples[i] = tonalState;
  }

  final cutoffHz = switch (style) {
    'warm' => 7600.0,
    'glass' => 9200.0,
    _ => 8400.0,
  };
  _applyOnePoleLowPass(
    samples,
    sampleRate: sampleRate,
    cutoffHz: cutoffHz + normalizedBow * 900,
  );
  _applyDcBlock(samples, pole: 0.996);
  _applySchroederReverb(
    samples,
    sampleRate: sampleRate,
    amount: (0.1 + reverb * 0.68).clamp(0.06, 0.58),
  );
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.88);
}

Uint8List _buildViolinSustainCore({
  required double frequency,
  required String style,
  required String variant,
  required double bow,
}) {
  const sampleRate = 32000;
  const durationSeconds = 2.8;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0.0);
  final normalizedBow = bow.clamp(0.15, 1.0).toDouble();
  final profile = _resolveViolinProfile(style, variant);

  var bowNoiseState = 0.0;
  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final attack = _smoothStep((t / 0.2).clamp(0.0, 1.0));
    final release = _smoothStep(((durationSeconds - t) / 0.3).clamp(0.0, 1.0));
    final envelope = attack * release;
    final vibrato =
        math.sin(math.pi * 2 * profile.vibratoRate * t) *
        profile.vibratoDepth *
        (0.5 + normalizedBow * 0.8);
    final instantFrequency = frequency * (1 + vibrato);

    var core =
        math.sin(math.pi * 2 * instantFrequency * t) *
        (0.66 + profile.body * 0.2);
    core +=
        math.sin(math.pi * 2 * instantFrequency * 2 * t + 0.16) *
        (0.2 + profile.warmth * 0.08);
    core +=
        math.sin(math.pi * 2 * instantFrequency * 3 * t + 0.62) *
        (0.1 + profile.edge * 0.08);

    final rawNoise =
        (math.sin((i + 1) * 19.87) + math.cos((i + 1) * 47.11)) * 0.5;
    bowNoiseState += (rawNoise - bowNoiseState) * 0.06;
    final bowNoise =
        bowNoiseState *
        profile.bowNoise *
        (0.1 + normalizedBow * 0.3) *
        (0.35 + envelope * 0.75);

    samples[i] = _softClip((core + bowNoise) * envelope * 0.9);
  }

  _applyOnePoleLowPass(samples, sampleRate: sampleRate, cutoffHz: 7800);
  _applyDcBlock(samples, pole: 0.996);
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.88);
}

Uint8List _buildViolinBowAttack({
  required double frequency,
  required String style,
  required String variant,
  required double bow,
}) {
  const sampleRate = 32000;
  const durationSeconds = 0.48;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0.0);
  final normalizedBow = bow.clamp(0.15, 1.0).toDouble();
  final profile = _resolveViolinProfile(style, variant);
  final seed = _violinVariantSeed(variant, frequency);

  var raspState = 0.0;
  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final onset = (1 - math.exp(-48 * t)) * math.exp(-8.5 * t);
    final rasp =
        (math.sin((i + 1) * 24.12 + seed) + math.cos((i + 1) * 39.87 + seed)) *
        0.5;
    raspState += (rasp - raspState) * 0.22;
    final bowScrape =
        raspState * (0.05 + profile.bowNoise * 1.1 * normalizedBow);

    var harmonic =
        math.sin(math.pi * 2 * frequency * t) * (0.38 + profile.body * 0.1);
    harmonic +=
        math.sin(math.pi * 2 * frequency * 2.1 * t + 0.35) *
        (0.18 + profile.edge * 0.12);
    harmonic +=
        math.sin(math.pi * 2 * frequency * 3.3 * t + 1.1) *
        (0.08 + profile.air * 0.1);

    final click = math.exp(-80 * t) * (0.045 + normalizedBow * 0.04);
    samples[i] = _softClip((harmonic + bowScrape + click) * onset * 1.2);
  }

  _applyOnePoleLowPass(samples, sampleRate: sampleRate, cutoffHz: 9800);
  _applyDcBlock(samples, pole: 0.996);
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.86);
}

Uint8List _buildViolinRoomTail({
  required double frequency,
  required String style,
  required String variant,
  required double bow,
  required double reverb,
}) {
  const sampleRate = 32000;
  const durationSeconds = 1.8;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0.0);
  final normalizedBow = bow.clamp(0.15, 1.0).toDouble();
  final profile = _resolveViolinProfile(style, variant);

  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final decay = math.exp(-t * (2.1 - normalizedBow * 0.5));
    var tone =
        math.sin(math.pi * 2 * frequency * t) * (0.26 + profile.body * 0.08);
    tone +=
        math.sin(math.pi * 2 * frequency * 2.0 * t + 0.42) *
        (0.1 + profile.edge * 0.08);
    tone +=
        math.sin(math.pi * 2 * frequency * 3.0 * t + 1.3) *
        (0.05 + profile.air * 0.08);
    final shimmer =
        math.sin(math.pi * 2 * frequency * 4.4 * t + 0.8) *
        (0.02 + profile.air * 0.05);
    samples[i] = _softClip((tone + shimmer) * decay * 0.72);
  }

  _applySchroederReverb(
    samples,
    sampleRate: sampleRate,
    amount: (0.28 + reverb * 0.6).clamp(0.2, 0.78),
  );
  _applyOnePoleLowPass(samples, sampleRate: sampleRate, cutoffHz: 7000);
  _applyDcBlock(samples, pole: 0.996);
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.84);
}

double _violinContour({
  required double t,
  required double durationSeconds,
  required double attackTime,
  required double releaseTime,
}) {
  final attack = _smoothStep((t / attackTime).clamp(0.0, 1.0));
  final release = _smoothStep(
    ((durationSeconds - t) / releaseTime).clamp(0.0, 1.0),
  );
  return attack * release;
}

double _violinDrift({
  required double t,
  required double phaseShift,
  required double bow,
}) {
  final slow = math.sin(
    math.pi * 2 * (0.31 + bow * 0.09) * t + phaseShift * 0.5,
  );
  final secondary = math.sin(
    math.pi * 2 * (0.83 + bow * 0.12) * t + phaseShift * 0.1,
  );
  return slow * 0.0013 + secondary * 0.0007;
}

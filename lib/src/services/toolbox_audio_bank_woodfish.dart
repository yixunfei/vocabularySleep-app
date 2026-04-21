part of 'toolbox_audio_service.dart';

Uint8List _buildWoodfishClick({
  required String style,
  required double resonance,
  required double brightness,
  required double pitch,
  required double strike,
  required bool accent,
  required int variant,
}) {
  const sampleRate = 44100;
  final styleSeed = switch (style) {
    'sandal' => 0.9,
    'bright' => 1.8,
    'hollow' => 2.6,
    'night' => 3.4,
    _ => 0.2,
  };
  final (
    bodyFreq,
    shellFreq,
    overtoneFreq,
    highShellFreq,
    bodyDecayRate,
    shellDecayRate,
    bodyMix,
    shellMix,
    overtoneMix,
    noiseMix,
    airPuffMix,
  ) = switch (style) {
    'sandal' => (
      258.0,
      726.0,
      1290.0,
      1840.0,
      7.8,
      13.2,
      0.60,
      0.40,
      0.30,
      0.042,
      0.065,
    ),
    'bright' => (
      318.0,
      892.0,
      1560.0,
      2340.0,
      11.0,
      18.0,
      0.42,
      0.54,
      0.40,
      0.050,
      0.035,
    ),
    'hollow' => (
      224.0,
      632.0,
      1140.0,
      1580.0,
      6.2,
      10.8,
      0.68,
      0.32,
      0.20,
      0.028,
      0.10,
    ),
    'night' => (
      248.0,
      678.0,
      1210.0,
      1680.0,
      7.2,
      12.0,
      0.64,
      0.34,
      0.22,
      0.024,
      0.055,
    ),
    _ => (
      278.0,
      782.0,
      1380.0,
      1980.0,
      8.6,
      14.8,
      0.54,
      0.48,
      0.34,
      0.044,
      0.06,
    ),
  };

  final variantId = variant.clamp(0, 31).toInt();
  double vrand(int salt) {
    final x =
        math.sin((variantId + 1) * 17.231 + styleSeed * 9.173 + salt * 13.97) *
        43758.5453;
    return x - x.floorToDouble();
  }

  final pitchMul = math.pow(2.0, pitch / 12.0).toDouble();
  final accentLift = accent ? 1.14 : 1.0;
  final strikeBoost = 0.66 + strike * 0.74;
  final resonanceLift = 0.80 + resonance * 0.52;
  final brightnessLift = 0.70 + brightness * 0.62;

  final bodyFreqVar = bodyFreq * (1.0 + (vrand(1) - 0.5) * 0.035);
  final shellFreqVar = shellFreq * (1.0 + (vrand(2) - 0.5) * 0.045);
  final overtoneFreqVar = overtoneFreq * (1.0 + (vrand(3) - 0.5) * 0.060);
  final highShellFreqVar = highShellFreq * (1.0 + (vrand(4) - 0.5) * 0.075);
  final stickFreq =
      2850.0 + brightness * 1720.0 + strike * 760.0 + (vrand(5) - 0.5) * 420.0;

  final bodyDecay =
      bodyDecayRate *
      (1.13 - resonance * 0.33) *
      (accent ? 0.90 : 1.0) *
      (0.96 + vrand(7) * 0.10);
  final shellDecay =
      shellDecayRate *
      (1.07 - resonance * 0.22) *
      (accent ? 0.92 : 1.0) *
      (0.95 + vrand(8) * 0.12);
  final transientDecay = (330.0 + strike * 280.0 + (vrand(9) - 0.5) * 60.0)
      .clamp(280.0, 680.0);

  final durationSeconds =
      (0.42 + resonance * 0.30 + (accent ? 0.04 : 0.0) + vrand(11) * 0.02)
          .clamp(0.38, 0.88);
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0);
  final reflectionDelaySamples = math.max(
    2,
    (sampleRate * (0.0065 + vrand(12) * 0.0045)).round(),
  );
  final reflectionBuffer = List<double>.filled(reflectionDelaySamples, 0.0);
  var reflectionIndex = 0;
  var tokNoiseState = 0.0;
  var airNoiseState = 0.0;
  var knockNoiseState = 0.0;
  final shimmerPhase = vrand(14) * math.pi * 2;

  double prand(int idx) {
    final x =
        math.sin(
          idx * 12.9898 + 78.233 + variantId * 1.111 + styleSeed * 0.717,
        ) *
        43758.5453;
    return x - x.floorToDouble();
  }

  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final attack = 1.0 - math.exp(-(520.0 + strike * 320.0) * t);
    final fastEnv = math.exp(-transientDecay * t);
    final bodyEnv = attack * math.exp(-bodyDecay * t);
    final shellEnv = attack * math.exp(-shellDecay * t);
    final noiseRaw =
        (prand(i) * 2.0 - 1.0) * 0.55 +
        (prand(i + 7919) * 2.0 - 1.0) * 0.35 +
        (prand(i + 3571) * 2.0 - 1.0) * 0.10;
    tokNoiseState += (noiseRaw - tokNoiseState) * (0.28 + brightness * 0.18);
    final tokEnv = math.exp(
      -(760.0 + strike * 420.0 + (1.0 - brightness) * 120.0) * t,
    );
    final contactNoise = (prand(i + 1024) * 2.0 - 1.0) * math.exp(-2500.0 * t);
    final tokBurst =
        (contactNoise * 0.22) +
        (tokNoiseState *
            tokEnv *
            (0.38 + strike * 0.46) *
            strikeBoost *
            (0.88 + brightness * 0.24));

    final sweepFactor = 1.0 + (0.20 + strike * 0.06) * math.exp(-210.0 * t);
    final bodyTone =
        math.sin(math.pi * 2 * bodyFreqVar * pitchMul * sweepFactor * t) *
        bodyMix *
        resonanceLift;
    final shellTone =
        math.sin(
          math.pi * 2 * shellFreqVar * pitchMul * sweepFactor * t + 0.34,
        ) *
        shellMix *
        brightnessLift;
    final overtoneTone =
        math.sin(
          math.pi * 2 * overtoneFreqVar * pitchMul * t + 0.52 + strike * 0.08,
        ) *
        overtoneMix *
        brightnessLift;
    final highShellTone =
        math.sin(
          math.pi * 2 * highShellFreqVar * pitchMul * t +
              0.91 +
              brightness * 0.16,
        ) *
        (overtoneMix * 0.38) *
        (0.80 + brightness * 0.40) *
        math.exp(-(shellDecay * 1.5) * t);

    final stickTone =
        math.sin(
          math.pi * 2 * stickFreq * pitchMul * t + 0.13 + strike * 0.14,
        ) *
        (0.16 + strike * 0.34) *
        fastEnv *
        strikeBoost *
        (0.84 + brightness * 0.32);

    final airNoise =
        (prand(i + 4231) * 2.0 - 1.0) * 0.5 +
        math.sin(math.pi * 2 * (bodyFreqVar * 0.38) * pitchMul * t) * 0.5;
    airNoiseState += (airNoise - airNoiseState) * 0.16;
    final airEnv =
        math.exp(-(48.0 + (1.0 - resonance) * 32.0) * t) *
        (1.0 - math.exp(-360.0 * t));
    final airPuff = airNoiseState * airPuffMix * airEnv * resonanceLift;

    final sympathetic2 =
        math.sin(math.pi * 2 * bodyFreqVar * 2.0 * pitchMul * t + 0.18) *
        0.065 *
        resonanceLift *
        math.exp(-(bodyDecay * 0.75) * t);
    final sympathetic3 =
        math.sin(math.pi * 2 * bodyFreqVar * 3.0 * pitchMul * t + 0.42) *
        0.038 *
        brightnessLift *
        math.exp(-(bodyDecay * 1.05) * t);
    final sympathetic5 =
        math.sin(math.pi * 2 * bodyFreqVar * 5.0 * pitchMul * t + 0.71) *
        0.020 *
        brightnessLift *
        math.exp(-(shellDecay * 1.25) * t);

    final woodBloom =
        math.sin(math.pi * 2 * bodyFreqVar * 0.5 * pitchMul * t + 0.78) *
        (0.07 + resonance * 0.12) *
        math.exp(-(5.8 + (1.0 - resonance) * 4.2) * t);

    final modal2 =
        math.sin(
          math.pi *
                  2 *
                  (shellFreqVar * (1.82 + (vrand(16) - 0.5) * 0.08)) *
                  pitchMul *
                  t +
              0.28,
        ) *
        (0.032 + brightness * 0.044) *
        math.exp(-(shellDecay * 1.16) * t);
    final modal3 =
        math.sin(
          math.pi *
                  2 *
                  (shellFreqVar * (2.47 + (vrand(17) - 0.5) * 0.12)) *
                  pitchMul *
                  t +
              0.63,
        ) *
        (0.018 + brightness * 0.03) *
        math.exp(-(shellDecay * 1.34) * t);

    final knockNoise =
        (math.sin(i * 12.9898 + bodyFreq * 0.003) +
            math.cos(i * 78.233 + shellFreq * 0.0018)) *
        noiseMix *
        (0.80 + brightness * 0.52) *
        fastEnv;
    knockNoiseState += (knockNoise - knockNoiseState) * 0.24;

    final reflectionIn = bodyTone * bodyEnv + shellTone * shellEnv * 0.68;
    final reflectionOut = reflectionBuffer[reflectionIndex];
    reflectionBuffer[reflectionIndex] = reflectionIn;
    reflectionIndex += 1;
    if (reflectionIndex >= reflectionBuffer.length) {
      reflectionIndex = 0;
    }
    final roomReflection =
        reflectionOut *
        (0.046 + resonance * 0.036) *
        math.exp(-(bodyDecay * 0.9) * t);

    final shimmer =
        (0.988 +
        0.012 * math.sin(math.pi * 2 * (3.2 + vrand(18)) * t + shimmerPhase));
    final tonal =
        (bodyTone * bodyEnv +
            shellTone * shellEnv +
            overtoneTone * shellEnv * 0.82 +
            highShellTone * attack) *
        accentLift *
        shimmer;
    final transients =
        (tokBurst + stickTone + knockNoiseState * 0.86) * accentLift;
    final resonances =
        (sympathetic2 + sympathetic3 + sympathetic5 + modal2 + modal3) *
        bodyEnv *
        accentLift;
    final ambients =
        (airPuff + woodBloom * bodyEnv * 0.58 + roomReflection) * accentLift;

    samples[i] = _softClip(tonal + transients + resonances + ambients);
  }
  _applySchroederReverb(
    samples,
    sampleRate: sampleRate,
    amount: (0.045 + resonance * 0.065 + brightness * 0.02).clamp(0.03, 0.18),
  );
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.90);
}

part of 'toolbox_audio_service.dart';

Uint8List _buildPluckNote({
  required double frequency,
  required double durationSeconds,
  required String style,
  required double reverb,
  required double decay,
  required int variant,
}) {
  const sampleRate = 32000;
  final tone = _pluckTone(style);
  final sustain = decay.clamp(0.55, 1.35).toDouble();
  final effectiveDuration = durationSeconds * (0.46 + sustain * 0.54);
  final totalSamples = (sampleRate * effectiveDuration).round();
  final samples = List<double>.filled(totalSamples, 0);
  final styleSeed = switch (style) {
    'warm' => 0.9,
    'crystal' => 1.7,
    'bright' => 2.5,
    'nylon' => 3.3,
    'glass' => 4.1,
    'concert' => 4.9,
    'steel' => 5.7,
    _ => 0.2,
  };
  final variantId = variant.clamp(0, 31).toInt();
  double vrand(int salt) => _variantRandom(
    variant: variantId,
    seed: styleSeed + frequency * 0.0013,
    salt: salt,
  );

  final delaySamples = math.max(18, (sampleRate / frequency).round());
  final brightnessWindow = (tone.brightness * (0.92 + vrand(1) * 0.16))
      .clamp(0.08, 0.98)
      .toDouble();
  final feedback =
      (tone.feedback *
              (0.986 + sustain * 0.012) *
              (0.998 + (vrand(2) - 0.5) * 0.006))
          .clamp(0.965, 0.9988)
          .toDouble();
  final transientGain = tone.transient * (0.92 + vrand(3) * 0.22);
  final noiseGain = tone.noise * (0.88 + vrand(4) * 0.28);
  final shimmerGain = tone.shimmer * (0.88 + vrand(5) * 0.24);
  final bodyDetune = tone.bodyDetune + (vrand(6) - 0.5) * 0.006;
  final outputGain = tone.outputGain * (0.97 + vrand(7) * 0.06);
  final ringPhase = vrand(8) * math.pi * 2;
  final bodyPhaseShift = frequency * 0.0003 + (vrand(9) - 0.5) * 0.35;
  final ring = List<double>.generate(delaySamples, (i) {
    final phase = i / delaySamples;
    final noise =
        (math.sin((i + 1) * 12.9898 + frequency * 0.005 + ringPhase) +
            math.cos((i + 1) * 78.233 + frequency * 0.0017 + ringPhase * 0.6)) *
        0.5;
    final brightMask = phase < brightnessWindow ? 1.0 : 0.72 + vrand(10) * 0.12;
    return noise * brightMask;
  });
  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final env =
        (1 - math.exp(-tone.attack * t)) *
        math.exp(-(tone.decay / sustain) * t) *
        (1 - t / effectiveDuration).clamp(0.0, 1.0);

    final idx = i % delaySamples;
    final next = (idx + 1) % delaySamples;
    final averaged = (ring[idx] + ring[next]) * 0.5;
    final lowpass = averaged * (0.86 + tone.brightness * 0.11);
    ring[idx] = lowpass * feedback;
    final stringSample = ring[idx];

    final pickTransient =
        (math.sin(
                  math.pi * 2 * frequency * (4.6 + vrand(11) * 0.5) * t +
                      bodyPhaseShift,
                ) *
                0.55 +
            math.sin(
                  math.pi * 2 * frequency * (7.0 + vrand(12) * 0.7) * t +
                      0.45 +
                      vrand(13) * 0.35,
                ) *
                0.45) *
        math.exp(-45 * t) *
        transientGain;
    final pickNoise =
        (math.sin((i + 1) * 11.173 + frequency * 0.002 + ringPhase * 0.8) +
            math.cos((i + 1) * 63.917 + frequency * 0.004 + ringPhase * 0.45)) *
        noiseGain *
        math.exp(-34 * t);
    final bodyResonance =
        math.sin(math.pi * 2 * frequency * t) * (0.16 + tone.bodyMix * 0.08) +
        math.sin(math.pi * 2 * frequency * (2.0 + bodyDetune) * t + 0.36) *
            tone.overtoneMix +
        math.sin(
              math.pi * 2 * frequency * (3.05 + bodyDetune * 1.7) * t + 1.1,
            ) *
            (0.03 + tone.brightness * 0.05);
    final octaveBloom =
        math.sin(math.pi * 2 * frequency * 0.5 * t + 0.12) *
        tone.octaveBloom *
        math.exp(-(tone.bodyDecay / sustain) * t);
    final shimmer =
        math.sin(math.pi * 2 * frequency * 5.2 * t + 0.7) *
        shimmerGain *
        math.exp(-(3.4 / (0.8 + sustain * 0.24)) * t);
    final air =
        math.sin(
          math.pi *
                  2 *
                  frequency *
                  (6.2 + tone.brightness + (vrand(14) - 0.5) * 0.4) *
                  t +
              0.24,
        ) *
        tone.air *
        math.exp(-(5.2 / (0.82 + sustain * 0.22)) * t);

    final value =
        (stringSample +
            pickTransient +
            pickNoise +
            bodyResonance * tone.bodyMix +
            octaveBloom +
            shimmer +
            air) *
        env;
    samples[i] = _softClip(value * outputGain);
  }
  _applySchroederReverb(
    samples,
    sampleRate: sampleRate,
    amount: (reverb * (0.92 + sustain * 0.12)).clamp(0.0, 0.8),
  );
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.92);
}

Uint8List _buildPianoNote(
  double frequency,
  String style, {
  required double reverb,
  required double decay,
  required double velocity,
  required int variant,
}) {
  const sampleRate = 32000;
  final durationSeconds = 2.0 + decay * 1.0;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0);
  final styleSeed = switch (style) {
    'bright' => 0.9,
    'felt' => 1.8,
    'upright' => 2.7,
    _ => 0.2,
  };
  final variantId = variant.clamp(0, 31).toInt();
  double vrand(int salt) => _variantRandom(
    variant: variantId,
    seed: styleSeed + frequency * 0.0019,
    salt: salt,
  );

  final detuneA = frequency * (0.9969 + (vrand(1) - 0.5) * 0.0016);
  final detuneB = frequency * (1.0031 + (vrand(2) - 0.5) * 0.0016);
  final harmonicMix = switch (style) {
    'bright' => 1.2,
    'felt' => 0.78,
    'upright' => 1.06,
    _ => 1.0,
  };
  final decayMul =
      switch (style) {
        'bright' => 1.1,
        'felt' => 0.82,
        'upright' => 0.92,
        _ => 1.0,
      } /
      decay;
  final hammerNoise =
      (switch (style) {
        'bright' => 0.058,
        'felt' => 0.022,
        'upright' => 0.046,
        _ => 0.04,
      }) *
      (0.92 + vrand(3) * 0.18);
  final duplexMul =
      (switch (style) {
        'bright' => 0.1,
        'felt' => 0.035,
        'upright' => 0.07,
        _ => 0.06,
      }) *
      (0.9 + vrand(4) * 0.2);
  final inharmonicity =
      1 + (frequency / 440.0) * (0.00045 + (vrand(5) - 0.5) * 0.00006);
  final hammerPhase = vrand(6) * math.pi * 2;
  final strikeBrightness = 0.94 + vrand(7) * 0.14;
  final normalizedVelocity = velocity.clamp(0.2, 1.0).toDouble();
  final brightnessByVelocity = math.pow(normalizedVelocity, 1.45).toDouble();
  final hammerNoiseBoost = 0.52 + normalizedVelocity * 1.42;
  final attackTightness = 84 - normalizedVelocity * 28;
  final upperHarmonicLift = 0.34 + brightnessByVelocity * 0.86;
  final lowerHarmonicLift = 0.78 + normalizedVelocity * 0.28;
  final stringBloom = 0.06 + brightnessByVelocity * 0.07;
  final duplexAttack = 0.88 + normalizedVelocity * 0.28;
  final tensionNudge = 1 + (normalizedVelocity - 0.55) * 0.0024;

  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final env =
        (1 - math.exp(-140 * t)) *
        math.exp(-(3.4 * decayMul) * t) *
        (1 - t / durationSeconds).clamp(0.0, 1.0);
    final hammer =
        (math.sin((i + 1) * 12.9898 + hammerPhase) +
            math.cos((i + 1) * 78.233 + hammerPhase * 0.7)) *
        hammerNoise *
        hammerNoiseBoost *
        math.exp(-(attackTightness + vrand(8) * 18) * t);
    var value = 0.0;
    for (var partial = 1; partial <= 6; partial += 1) {
      final partialFreq =
          frequency *
          partial *
          tensionNudge *
          (1 + (partial - 1) * 0.0005 + (vrand(10 + partial) - 0.5) * 0.0002);
      final partialVariance = 0.96 + vrand(20 + partial) * 0.08;
      var amplitude = switch (partial) {
        1 => 0.56,
        2 => 0.22 * harmonicMix,
        3 => 0.12 * harmonicMix,
        4 => 0.07 * harmonicMix,
        5 => 0.038 * harmonicMix,
        _ => 0.024 * harmonicMix,
      };
      if (partial <= 2) {
        amplitude *= lowerHarmonicLift;
      } else {
        amplitude *= upperHarmonicLift;
      }
      value +=
          math.sin(math.pi * 2 * partialFreq * inharmonicity * t) *
          amplitude *
          partialVariance *
          strikeBrightness;
    }
    value += math.sin(math.pi * 2 * detuneA * t + 0.07) * 0.16;
    value += math.sin(math.pi * 2 * detuneB * t - 0.06) * 0.16;
    value +=
        math.sin(math.pi * 2 * frequency * 6.7 * t + 0.5) *
        duplexMul *
        duplexAttack *
        math.exp(-5.8 * t);
    value +=
        math.sin(math.pi * 2 * frequency * 8.2 * t + 1.1) *
        (duplexMul * 0.7) *
        math.exp(-7.2 * t);
    final sympathetic =
        math.sin(math.pi * 2 * frequency * 0.5 * t + 0.8 + vrand(30) * 0.35) *
        (0.06 + harmonicMix * 0.02 + stringBloom) *
        math.exp(-2.8 * t);
    samples[i] = _softClip((value + hammer + sympathetic) * env * 1.38);
  }

  final baseReverb = switch (style) {
    'bright' => 0.1,
    'felt' => 0.17,
    'upright' => 0.13,
    _ => 0.12,
  };
  _applySchroederReverb(
    samples,
    sampleRate: sampleRate,
    amount: ((baseReverb + reverb) / 2).clamp(0.0, 0.55),
  );
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.92);
}

_HarpPluckTone _pluckTone(String style) {
  return switch (style) {
    'warm' => const _HarpPluckTone(
      attack: 28,
      decay: 1.7,
      feedback: 0.9946,
      brightness: 0.34,
      transient: 0.14,
      bodyMix: 1.02,
      shimmer: 0.01,
      noise: 0.012,
      overtoneMix: 0.072,
      octaveBloom: 0.07,
      air: 0.008,
      bodyDetune: 0.008,
      bodyDecay: 2.1,
      outputGain: 1.46,
    ),
    'crystal' => const _HarpPluckTone(
      attack: 60,
      decay: 3.35,
      feedback: 0.9908,
      brightness: 0.9,
      transient: 0.44,
      bodyMix: 0.58,
      shimmer: 0.11,
      noise: 0.03,
      overtoneMix: 0.17,
      octaveBloom: 0.016,
      air: 0.052,
      bodyDetune: 0.034,
      bodyDecay: 4.6,
      outputGain: 1.64,
    ),
    'bright' => const _HarpPluckTone(
      attack: 48,
      decay: 3.05,
      feedback: 0.9919,
      brightness: 0.76,
      transient: 0.34,
      bodyMix: 0.7,
      shimmer: 0.075,
      noise: 0.026,
      overtoneMix: 0.14,
      octaveBloom: 0.022,
      air: 0.04,
      bodyDetune: 0.028,
      bodyDecay: 4.0,
      outputGain: 1.6,
    ),
    'nylon' => const _HarpPluckTone(
      attack: 30,
      decay: 2.1,
      feedback: 0.994,
      brightness: 0.38,
      transient: 0.12,
      bodyMix: 0.98,
      shimmer: 0.008,
      noise: 0.01,
      overtoneMix: 0.064,
      octaveBloom: 0.055,
      air: 0.006,
      bodyDetune: 0.01,
      bodyDecay: 2.4,
      outputGain: 1.44,
    ),
    'glass' => const _HarpPluckTone(
      attack: 64,
      decay: 3.5,
      feedback: 0.9899,
      brightness: 0.97,
      transient: 0.52,
      bodyMix: 0.46,
      shimmer: 0.14,
      noise: 0.04,
      overtoneMix: 0.21,
      octaveBloom: 0.008,
      air: 0.072,
      bodyDetune: 0.04,
      bodyDecay: 5.4,
      outputGain: 1.68,
    ),
    'concert' => const _HarpPluckTone(
      attack: 36,
      decay: 2.85,
      feedback: 0.9936,
      brightness: 0.52,
      transient: 0.24,
      bodyMix: 0.92,
      shimmer: 0.026,
      noise: 0.016,
      overtoneMix: 0.1,
      octaveBloom: 0.04,
      air: 0.016,
      bodyDetune: 0.018,
      bodyDecay: 3.0,
      outputGain: 1.52,
    ),
    'steel' => const _HarpPluckTone(
      attack: 52,
      decay: 3.1,
      feedback: 0.9914,
      brightness: 0.82,
      transient: 0.39,
      bodyMix: 0.62,
      shimmer: 0.082,
      noise: 0.034,
      overtoneMix: 0.18,
      octaveBloom: 0.014,
      air: 0.048,
      bodyDetune: 0.032,
      bodyDecay: 4.4,
      outputGain: 1.66,
    ),
    _ => const _HarpPluckTone(
      attack: 34,
      decay: 2.45,
      feedback: 0.9931,
      brightness: 0.5,
      transient: 0.18,
      bodyMix: 0.9,
      shimmer: 0.02,
      noise: 0.014,
      overtoneMix: 0.086,
      octaveBloom: 0.048,
      air: 0.012,
      bodyDetune: 0.014,
      bodyDecay: 2.8,
      outputGain: 1.48,
    ),
  };
}

class _HarpPluckTone {
  const _HarpPluckTone({
    required this.attack,
    required this.decay,
    required this.feedback,
    required this.brightness,
    required this.transient,
    required this.bodyMix,
    required this.shimmer,
    required this.noise,
    required this.overtoneMix,
    required this.octaveBloom,
    required this.air,
    required this.bodyDetune,
    required this.bodyDecay,
    required this.outputGain,
  });

  final double attack;
  final double decay;
  final double feedback;
  final double brightness;
  final double transient;
  final double bodyMix;
  final double shimmer;
  final double noise;
  final double overtoneMix;
  final double octaveBloom;
  final double air;
  final double bodyDetune;
  final double bodyDecay;
  final double outputGain;
}

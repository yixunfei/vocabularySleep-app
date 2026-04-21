part of 'toolbox_audio_service.dart';

void _applySingingBowlSpace(
  List<double> samples, {
  required int sampleRate,
  required double amount,
}) {
  final mix = amount.clamp(0.0, 0.6).toDouble();
  if (mix <= 0.001) return;
  final input = List<double>.from(samples, growable: false);
  final wet = List<double>.filled(samples.length, 0);
  final taps = <(int, double, double)>[
    ((sampleRate * 0.031).round(), 0.18 + mix * 0.12, 0.22),
    ((sampleRate * 0.057).round(), 0.14 + mix * 0.1, 0.16),
    ((sampleRate * 0.093).round(), 0.12 + mix * 0.08, 0.11),
    ((sampleRate * 0.146).round(), 0.08 + mix * 0.06, 0.08),
  ];

  for (final (delay, gain, smoothing) in taps) {
    if (delay <= 1) continue;
    var state = 0.0;
    for (var i = delay; i < samples.length; i += 1) {
      state += (input[i - delay] - state) * smoothing;
      wet[i] += state * gain;
    }
  }

  final smearDelay = (sampleRate * (0.079 + mix * 0.026)).round();
  if (smearDelay > 1) {
    final smeared = List<double>.from(wet);
    final feedback = 0.14 + mix * 0.16;
    for (var i = smearDelay; i < wet.length; i += 1) {
      smeared[i] += smeared[i - smearDelay] * feedback;
    }
    for (var i = 0; i < wet.length; i += 1) {
      wet[i] = wet[i] * 0.7 + smeared[i] * 0.3;
    }
  }

  final dryMix = 1.0 - mix * 0.32;
  final wetMix = 0.55 + mix * 0.65;
  for (var i = 0; i < samples.length; i += 1) {
    samples[i] = _softClip(input[i] * dryMix + wet[i] * wetMix);
  }
}

Uint8List _buildSingingBowlTone({
  required double frequency,
  required String style,
  required int variant,
}) {
  const sampleRate = 32000;
  final styleSeed = switch (style) {
    'brass' => 1.1,
    'deep' => 2.2,
    'pure' => 3.3,
    _ => 0.2,
  };
  final (
    List<double> harmonics,
    List<double> gains,
    List<String> waveforms,
    double decaySeconds,
    double attackSeconds,
    double lfoFrequency,
    double lfoDepth,
    double transientMix,
    double airMix,
    double bloomMix,
    double spaceAmount,
    double reverbAmount,
  ) = switch (style) {
    'brass' => (
      <double>[1, 2, 3, 4.5],
      <double>[0.8, 0.5, 0.3, 0.1],
      <String>['sine', 'triangle', 'sine', 'sine'],
      13.8,
      0.11,
      0.24,
      0.022,
      0.032,
      0.018,
      0.18,
      0.22,
      0.26,
    ),
    'deep' => (
      <double>[0.5, 1, 1.5],
      <double>[0.6, 1.0, 0.2],
      <String>['triangle', 'sine', 'sine'],
      14.8,
      0.36,
      0.18,
      0.024,
      0.022,
      0.020,
      0.22,
      0.26,
      0.30,
    ),
    'pure' => (
      <double>[1],
      <double>[1.0],
      <String>['sine'],
      8.4,
      0.14,
      0.34,
      0.015,
      0.014,
      0.010,
      0.08,
      0.15,
      0.18,
    ),
    _ => (
      <double>[1, 2.7, 4.2],
      <double>[1.0, 0.3, 0.1],
      <String>['sine', 'triangle', 'sine'],
      10.2,
      0.16,
      0.28,
      0.020,
      0.024,
      0.016,
      0.16,
      0.20,
      0.23,
    ),
  };

  final variantId = variant.clamp(0, 31).toInt();
  double vrand(int salt) => _variantRandom(
    variant: variantId,
    seed: styleSeed + frequency * 0.01,
    salt: salt,
  );

  double waveSample(String waveform, double phase) {
    return switch (waveform) {
      'triangle' => 2 / math.pi * math.asin(math.sin(phase)),
      _ => math.sin(phase),
    };
  }

  final durationSeconds = (decaySeconds * 1.24 + 2.4 + vrand(1) * 0.9)
      .clamp(8.0, 20.0)
      .toDouble();
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0);
  final partialPhaseA = List<double>.generate(
    harmonics.length,
    (int index) => vrand(10 + index) * math.pi * 2,
    growable: false,
  );
  final partialPhaseB = List<double>.generate(
    harmonics.length,
    (int index) => vrand(30 + index) * math.pi * 2,
    growable: false,
  );
  final lfoPhase = vrand(80) * math.pi * 2;
  final slowPhase = vrand(81) * math.pi * 2;
  final bloomPhase = vrand(82) * math.pi * 2;
  final strikePhase = vrand(83) * math.pi * 2;
  var transientNoiseState = 0.0;
  var airNoiseState = 0.0;

  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final attackProgress = (t / math.max(attackSeconds, 0.02)).clamp(0.0, 1.0);
    final attackEnvelope = _smoothStep(attackProgress);
    final amplitudeMod =
        (1 +
                lfoDepth * math.sin(math.pi * 2 * lfoFrequency * t + lfoPhase) +
                0.011 *
                    math.sin(
                      math.pi * 2 * (lfoFrequency * 0.38) * t + slowPhase,
                    ))
            .clamp(0.90, 1.09);

    var tonal = 0.0;
    for (var h = 0; h < harmonics.length; h += 1) {
      final harmonic = harmonics[h];
      final harmonicGain = gains[h];
      final partialFrequency =
          frequency * harmonic * (0.997 + vrand(100 + h) * 0.006);
      final detuneSpread = 0.0007 + h * 0.00035;
      final detune = 1 + (vrand(120 + h) - 0.5) * detuneSpread * 2;
      final drift =
          1 +
          0.00065 *
              math.sin(
                math.pi * 2 * (0.06 + vrand(140 + h) * 0.12) * t +
                    partialPhaseA[h] * 0.6,
              );
      final partialDecay =
          decaySeconds * (1.02 + h * 0.22) * (0.94 + vrand(160 + h) * 0.12);
      final envelope = attackEnvelope * math.exp(-t / partialDecay);
      final toneA = waveSample(
        waveforms[h],
        math.pi * 2 * partialFrequency * detune * drift * t + partialPhaseA[h],
      );
      final toneB = math.sin(
        math.pi * 2 * partialFrequency * (2 - detune) * t + partialPhaseB[h],
      );
      tonal += (toneA * 0.72 + toneB * 0.28) * harmonicGain * envelope;
    }

    final bloom =
        math.sin(
          math.pi * 2 * frequency * (style == 'deep' ? 0.46 : 0.68) * t +
              bloomPhase,
        ) *
        bloomMix *
        attackEnvelope *
        math.exp(-t / (decaySeconds * 1.5));
    final halo =
        math.sin(
          math.pi * 2 * frequency * (style == 'pure' ? 2.1 : 2.85) * t +
              bloomPhase * 0.72,
        ) *
        (0.04 + bloomMix * 0.26) *
        attackEnvelope *
        math.exp(-t / (decaySeconds * 2.4));

    final noiseSource =
        (math.sin(i * 12.9898 + strikePhase) +
            math.cos(i * 78.233 + styleSeed * 1.5 + strikePhase * 0.4)) *
        0.5;
    transientNoiseState += (noiseSource - transientNoiseState) * 0.12;
    airNoiseState += (noiseSource - airNoiseState) * 0.02;

    final transientEnvelope =
        math.exp(-(8.5 + vrand(200) * 2.4) * t) * (1 - math.exp(-48 * t));
    final strike =
        (math.sin(
                  math.pi * 2 * frequency * (2.05 + vrand(220) * 0.32) * t +
                      strikePhase,
                ) *
                0.38 +
            transientNoiseState * 0.08) *
        transientMix *
        transientEnvelope *
        (0.58 + attackEnvelope * 0.42);

    final air =
        (noiseSource - airNoiseState) *
        airMix *
        math.exp(-t / (decaySeconds * 0.76 + 1.1)) *
        (0.24 + attackEnvelope * 0.76);

    samples[i] = _softClip(
      (tonal * amplitudeMod + bloom + halo + strike + air) * 0.78,
    );
  }

  _applySingingBowlSpace(samples, sampleRate: sampleRate, amount: spaceAmount);
  _applySchroederReverb(samples, sampleRate: sampleRate, amount: reverbAmount);

  final fadeSamples = math.min((sampleRate * 0.9).round(), samples.length);
  for (var i = 0; i < fadeSamples; i += 1) {
    final index = samples.length - fadeSamples + i;
    final fade = 1.0 - _smoothStep(i / fadeSamples);
    samples[index] *= fade;
  }

  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.86);
}

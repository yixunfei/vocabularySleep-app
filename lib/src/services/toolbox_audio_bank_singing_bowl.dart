part of 'toolbox_audio_service.dart';

class _SingingBowlToneWorkerRequest {
  const _SingingBowlToneWorkerRequest({
    required this.frequency,
    required this.style,
    required this.variant,
  });

  final double frequency;
  final String style;
  final int variant;
}

TransferableTypedData _buildSingingBowlToneInWorker(
  _SingingBowlToneWorkerRequest request,
) {
  return TransferableTypedData.fromList(<Uint8List>[
    _buildSingingBowlTone(
      frequency: request.frequency,
      style: request.style,
      variant: request.variant,
    ),
  ]);
}

class _SingingBowlPartial {
  _SingingBowlPartial({
    required this.phaseA,
    required this.phaseB,
    required this.driftPhase,
    required this.phaseStepA,
    required this.phaseStepB,
    required this.driftStep,
    required this.envelopeStep,
    required this.gain,
    required this.triangle,
  });

  double phaseA;
  double phaseB;
  double driftPhase;
  final double phaseStepA;
  final double phaseStepB;
  final double driftStep;
  final double envelopeStep;
  final double gain;
  final bool triangle;
  double envelope = 1.0;
}

void _applySingingBowlSpace(
  List<double> samples, {
  required int sampleRate,
  required double amount,
}) {
  final mix = amount.clamp(0.0, 0.35).toDouble();
  if (mix <= 0.001 || samples.isEmpty) {
    return;
  }

  // Early reflections plus one filtered feedback line use one scratch buffer.
  // This keeps the tail smooth without the comb-filter ringing of the previous
  // multi-stage Schroeder network.
  final wet = Float32List(samples.length);
  const tapGains = <double>[0.20, 0.14, 0.095, 0.06];
  const tapSmoothing = <double>[0.20, 0.16, 0.12, 0.08];
  const tapSeconds = <double>[0.027, 0.049, 0.078, 0.113];
  for (var tap = 0; tap < tapSeconds.length; tap += 1) {
    final delay = (sampleRate * tapSeconds[tap]).round();
    var state = 0.0;
    for (var i = delay; i < samples.length; i += 1) {
      state += (samples[i - delay] - state) * tapSmoothing[tap];
      wet[i] += state * tapGains[tap];
    }
  }

  final feedbackDelay = (sampleRate * 0.071).round();
  final feedback = 0.08 + mix * 0.16;
  for (var i = feedbackDelay; i < wet.length; i += 1) {
    wet[i] += wet[i - feedbackDelay] * feedback;
  }

  var wetState = 0.0;
  final wetAlpha = (sampleRate * 0.0015).clamp(0.01, 0.22).toDouble();
  final dryMix = 1.0 - mix * 0.24;
  final wetMix = 0.42 + mix * 0.34;
  for (var i = 0; i < samples.length; i += 1) {
    wetState += (wet[i] - wetState) * wetAlpha;
    samples[i] = _softClip(samples[i] * dryMix + wetState * wetMix);
  }
}

Uint8List _buildSingingBowlTone({
  required double frequency,
  required String style,
  required int variant,
}) {
  // 24 kHz still leaves ample headroom for the highest bowl partial while
  // reducing the generated PCM and native decoder footprint by 25%.
  const sampleRate = 24000;
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
  ) = switch (style) {
    'brass' => (
      <double>[1, 2, 3, 4.5],
      <double>[0.78, 0.46, 0.24, 0.08],
      <String>['sine', 'triangle', 'sine', 'sine'],
      11.2,
      0.12,
      0.22,
      0.018,
      0.018,
      0.010,
      0.13,
      0.13,
    ),
    'deep' => (
      <double>[0.5, 1, 1.5],
      <double>[0.56, 0.92, 0.16],
      <String>['triangle', 'sine', 'sine'],
      12.4,
      0.30,
      0.16,
      0.020,
      0.016,
      0.012,
      0.16,
      0.16,
    ),
    'pure' => (
      <double>[1],
      <double>[1.0],
      <String>['sine'],
      7.2,
      0.16,
      0.30,
      0.012,
      0.010,
      0.006,
      0.06,
      0.07,
    ),
    _ => (
      <double>[1, 2.7, 4.2],
      <double>[0.96, 0.26, 0.075],
      <String>['sine', 'triangle', 'sine'],
      9.0,
      0.17,
      0.25,
      0.016,
      0.016,
      0.009,
      0.10,
      0.10,
    ),
  };

  final variantId = variant.clamp(0, 31).toInt();
  double vrand(int salt) => _variantRandom(
    variant: variantId,
    seed: styleSeed + frequency * 0.01,
    salt: salt,
  );

  final durationSeconds = (decaySeconds * 1.08 + 1.8 + vrand(1) * 0.45)
      .clamp(6.5, 14.0)
      .toDouble();
  final totalSamples = (sampleRate * durationSeconds).round();
  // Float32 is more than sufficient before 16-bit WAV quantization and keeps
  // the synthesis plus spatial scratch buffers compact on memory-constrained
  // phones.
  final samples = Float32List(totalSamples);
  final partials = <_SingingBowlPartial>[];
  final twoPi = math.pi * 2;

  for (var h = 0; h < harmonics.length; h += 1) {
    final baseFrequency =
        frequency * harmonics[h] * (0.997 + vrand(100 + h) * 0.006);
    final detuneSpread = 0.0007 + h * 0.00035;
    final detune = 1 + (vrand(120 + h) - 0.5) * detuneSpread * 2;
    final partialDecay =
        decaySeconds * (1.02 + h * 0.22) * (0.94 + vrand(160 + h) * 0.12);
    partials.add(
      _SingingBowlPartial(
        phaseA: vrand(10 + h) * twoPi,
        phaseB: vrand(30 + h) * twoPi,
        driftPhase: vrand(40 + h) * twoPi,
        phaseStepA: twoPi * baseFrequency * detune / sampleRate,
        phaseStepB: twoPi * baseFrequency * (2 - detune) / sampleRate,
        driftStep: twoPi * (0.06 + vrand(140 + h) * 0.12) / sampleRate,
        envelopeStep: math.exp(-1 / (sampleRate * partialDecay)),
        gain: gains[h],
        triangle: waveforms[h] == 'triangle',
      ),
    );
  }

  var lfoPhase = vrand(80) * twoPi;
  var slowPhase = vrand(81) * twoPi;
  var bloomPhase = vrand(82) * twoPi;
  var strikePhase = vrand(83) * twoPi;
  final lfoStep = twoPi * lfoFrequency / sampleRate;
  final slowStep = twoPi * (lfoFrequency * 0.38) / sampleRate;
  final bloomFrequency = frequency * (style == 'deep' ? 0.46 : 0.68);
  final haloFrequency = frequency * (style == 'pure' ? 2.1 : 2.85);
  final bloomStep = twoPi * bloomFrequency / sampleRate;
  final haloStep = twoPi * haloFrequency / sampleRate;
  final strikeStep =
      twoPi * frequency * (2.05 + vrand(220) * 0.32) / sampleRate;
  final bloomDecayStep = math.exp(-1 / (sampleRate * (decaySeconds * 1.5)));
  final haloDecayStep = math.exp(-1 / (sampleRate * (decaySeconds * 2.4)));
  final airDecayStep = math.exp(
    -1 / (sampleRate * (decaySeconds * 0.76 + 1.1)),
  );
  final transientDecay = 8.5 + vrand(200) * 2.4;
  final transientDecayStep = math.exp(-transientDecay / sampleRate);
  var bloomEnvelope = 1.0;
  var haloEnvelope = 1.0;
  var airEnvelope = 1.0;
  var transientEnvelope = 1.0;
  var transientNoiseState = 0.0;
  var airNoiseState = 0.0;
  var noiseSeed = ((vrand(500) * 2147483646).round() | 1) & 0x7fffffff;
  final attackSamples = math.max((sampleRate * attackSeconds).round(), 1);
  final transientAttackSamples = math.max((sampleRate * 0.045).round(), 1);

  for (var i = 0; i < totalSamples; i += 1) {
    final attack = _smoothStep((i / attackSamples).clamp(0.0, 1.0));
    final amplitudeMod =
        (1 + lfoDepth * math.sin(lfoPhase) + 0.009 * math.sin(slowPhase)).clamp(
          0.92,
          1.07,
        );

    var tonal = 0.0;
    for (final partial in partials) {
      final drift = 1 + 0.00055 * math.sin(partial.driftPhase);
      final toneA = partial.triangle
          ? _triangleWave(partial.phaseA)
          : math.sin(partial.phaseA);
      final toneB = math.sin(partial.phaseB);
      tonal +=
          (toneA * 0.72 + toneB * 0.28) *
          partial.gain *
          attack *
          partial.envelope;
      partial.phaseA += partial.phaseStepA * drift;
      partial.phaseB += partial.phaseStepB;
      partial.driftPhase += partial.driftStep;
      partial.envelope *= partial.envelopeStep;
    }

    final bloom = math.sin(bloomPhase) * bloomMix * attack * bloomEnvelope;
    final halo =
        math.sin(haloStep * i + bloomPhase * 0.72) *
        (0.035 + bloomMix * 0.20) *
        attack *
        haloEnvelope;

    noiseSeed = (noiseSeed * 1664525 + 1013904223) & 0x7fffffff;
    final noiseSource = noiseSeed / 1073741823.5 - 1.0;
    transientNoiseState += (noiseSource - transientNoiseState) * 0.075;
    airNoiseState += (noiseSource - airNoiseState) * 0.012;
    final transientAttack = _smoothStep(
      (i / transientAttackSamples).clamp(0.0, 1.0),
    );
    final strike =
        (math.sin(strikePhase) * 0.30 + transientNoiseState * 0.055) *
        transientMix *
        transientAttack *
        transientEnvelope *
        (0.58 + attack * 0.42);
    final air =
        (transientNoiseState - airNoiseState) * airMix * attack * airEnvelope;

    samples[i] = _softClip(
      (tonal * amplitudeMod + bloom + halo + strike + air) * 0.78,
    );
    lfoPhase += lfoStep;
    slowPhase += slowStep;
    bloomPhase += bloomStep;
    strikePhase += strikeStep;
    bloomEnvelope *= bloomDecayStep;
    haloEnvelope *= haloDecayStep;
    airEnvelope *= airDecayStep;
    transientEnvelope *= transientDecayStep;
  }

  _applyDcBlock(samples, pole: 0.997);
  _applyOnePoleLowPass(
    samples,
    sampleRate: sampleRate,
    cutoffHz: math.min(7600.0, sampleRate * 0.38),
  );
  _applySingingBowlSpace(samples, sampleRate: sampleRate, amount: spaceAmount);

  final fadeSamples = math.min((sampleRate * 0.72).round(), samples.length);
  for (var i = 0; i < fadeSamples; i += 1) {
    final index = samples.length - fadeSamples + i;
    samples[index] *= 1.0 - _smoothStep(i / fadeSamples);
  }

  return _encodeWav(
    samples,
    sampleRate: sampleRate,
    gain: 0.78,
    maxNormalization: 1.35,
  );
}

double _triangleWave(double phase) {
  final cycle = phase / (math.pi * 2);
  final fraction = cycle - cycle.floorToDouble();
  return 1.0 - 4.0 * (fraction - 0.5).abs();
}

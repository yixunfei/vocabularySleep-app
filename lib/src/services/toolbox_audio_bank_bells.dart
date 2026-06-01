part of 'toolbox_audio_service.dart';

Uint8List _buildKalimbaNote({
  required double frequency,
  required String style,
  required double resonance,
  required double reverb,
  required int variant,
}) {
  const sampleRate = 32000;
  final normalizedResonance = resonance.clamp(0.2, 1.0).toDouble();
  final durationSeconds = 1.35 + normalizedResonance * 1.45;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0);
  final styleSeed = switch (style) {
    'bright' => 1.3,
    'music_box' => 2.2,
    _ => 0.4,
  };
  final variantId = variant.clamp(0, 31).toInt();
  double vrand(int salt) => _variantRandom(
    variant: variantId,
    seed: styleSeed + frequency * 0.0021,
    salt: salt,
  );

  final attack = switch (style) {
    'music_box' => 120.0,
    'bright' => 96.0,
    _ => 72.0,
  };
  final brightness = switch (style) {
    'music_box' => 1.18,
    'bright' => 1.06,
    _ => 0.82,
  };
  final body = switch (style) {
    'music_box' => 0.58,
    'bright' => 0.74,
    _ => 1.0,
  };
  final decay = (2.2 - normalizedResonance * 0.82).clamp(1.1, 2.2).toDouble();
  final phase = vrand(1) * math.pi * 2;
  final tineDetune = (vrand(2) - 0.5) * 0.0035;
  final secondDetune = (vrand(3) - 0.5) * 0.006;

  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final envelope =
        (1 - math.exp(-attack * t)) *
        math.exp(-decay * t) *
        (1 - t / durationSeconds).clamp(0.0, 1.0);
    final click =
        (math.sin((i + 1) * 18.311 + phase) +
            math.cos((i + 1) * 41.711 + phase * 0.37)) *
        (0.035 + brightness * 0.018) *
        math.exp(-72 * t);
    var tone =
        math.sin(math.pi * 2 * frequency * (1 + tineDetune) * t + phase) *
        (0.54 + body * 0.12);
    tone +=
        math.sin(math.pi * 2 * frequency * (2.01 + secondDetune) * t + 0.3) *
        (0.16 + brightness * 0.05);
    tone +=
        math.sin(math.pi * 2 * frequency * 3.92 * t + 0.8) *
        (0.05 + brightness * 0.045);
    tone +=
        math.sin(math.pi * 2 * frequency * 0.5 * t + 1.2) *
        (0.05 + body * 0.04) *
        math.exp(-0.9 * t);
    final shimmer =
        math.sin(math.pi * 2 * frequency * 6.1 * t + 0.5) *
        (style == 'music_box' ? 0.075 : 0.032) *
        math.exp(-4.2 * t);
    samples[i] = _softClip((tone + shimmer + click) * envelope * 1.2);
  }

  _applyOnePoleLowPass(
    samples,
    sampleRate: sampleRate,
    cutoffHz: switch (style) {
      'music_box' => 10400,
      'bright' => 9400,
      _ => 7800,
    },
  );
  _applySchroederReverb(
    samples,
    sampleRate: sampleRate,
    amount: (0.06 + reverb * 0.62).clamp(0.0, 0.48),
  );
  _applyDcBlock(samples, pole: 0.996);
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.9);
}

Uint8List _buildChimeNote({
  required double frequency,
  required String style,
  required double tail,
  required double reverb,
  required int variant,
}) {
  const sampleRate = 32000;
  final normalizedTail = tail.clamp(0.2, 1.0).toDouble();
  final durationSeconds = 2.0 + normalizedTail * 3.2;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0);
  final styleSeed = switch (style) {
    'soft' => 1.2,
    'bright' => 2.0,
    _ => 0.5,
  };
  final variantId = variant.clamp(0, 31).toInt();
  double vrand(int salt) => _variantRandom(
    variant: variantId,
    seed: styleSeed + frequency * 0.0015,
    salt: salt,
  );

  final strikeBrightness = switch (style) {
    'soft' => 0.72,
    'bright' => 1.18,
    _ => 0.96,
  };
  final decayScale = switch (style) {
    'soft' => 0.82,
    'bright' => 1.12,
    _ => 1.0,
  };
  final phase = vrand(1) * math.pi * 2;
  final ratios = const <double>[1.0, 2.76, 5.4, 8.93, 13.34];
  final amplitudes = const <double>[0.62, 0.31, 0.2, 0.12, 0.07];

  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final attack = (1 - math.exp(-180 * t));
    final bodyEnvelope =
        attack *
        math.exp(-(0.72 + decayScale * 0.58) / normalizedTail * t) *
        (1 - t / durationSeconds).clamp(0.0, 1.0);
    var tone = 0.0;
    for (var partial = 0; partial < ratios.length; partial += 1) {
      final ratio = ratios[partial] * (1 + (vrand(10 + partial) - 0.5) * 0.004);
      final partialDecay =
          (0.58 + partial * 0.34 + decayScale * 0.22) / normalizedTail;
      tone +=
          math.sin(
            math.pi * 2 * frequency * ratio * t + phase + partial * 0.43,
          ) *
          amplitudes[partial] *
          math.exp(-partialDecay * t) *
          (partial < 2 ? 1.0 : strikeBrightness);
    }
    final strike =
        (math.sin((i + 1) * 22.13 + phase) +
            math.cos((i + 1) * 51.77 + phase * 0.7)) *
        0.035 *
        strikeBrightness *
        math.exp(-84 * t);
    final lowBloom =
        math.sin(math.pi * 2 * frequency * 0.5 * t + 0.9) *
        0.07 *
        math.exp(-0.62 * t);
    samples[i] = _softClip((tone + strike + lowBloom) * bodyEnvelope * 1.08);
  }

  _applySchroederReverb(
    samples,
    sampleRate: sampleRate,
    amount: (0.16 + reverb * 0.72).clamp(0.12, 0.72),
  );
  _applyOnePoleLowPass(
    samples,
    sampleRate: sampleRate,
    cutoffHz: switch (style) {
      'soft' => 6200,
      'bright' => 10600,
      _ => 8200,
    },
  );
  _applyDcBlock(samples, pole: 0.996);
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.86);
}

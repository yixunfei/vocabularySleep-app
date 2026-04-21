part of 'toolbox_audio_service.dart';

Uint8List _buildGuitarNote({
  required double frequency,
  required String style,
  required double resonance,
  required double pickPosition,
  required double velocity,
  required bool palmMute,
}) {
  const sampleRate = 32000;
  final durationSeconds = palmMute ? 0.6 : 2.9;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0);
  final styleBrightness = switch (style) {
    'nylon' => 0.72,
    'ambient' => 0.84,
    'twelve' => 1.2,
    _ => 1.0,
  };
  final styleDecay = switch (style) {
    'nylon' => 0.92,
    'ambient' => 1.24,
    'twelve' => 1.06,
    _ => 1.0,
  };
  final styleBody = switch (style) {
    'nylon' => 0.82,
    'ambient' => 0.96,
    'twelve' => 0.76,
    _ => 0.9,
  };
  final resonantBody = 0.38 + resonance * 0.62;
  final pickColor = (0.25 + pickPosition * 1.25).clamp(0.25, 1.35);
  final doubledFrequency = frequency * 2.0;
  final normalizedVelocity = velocity.clamp(0.2, 1.0).toDouble();
  final tensionTransientAmount = normalizedVelocity > 0.6
      ? (normalizedVelocity - 0.6) * 0.03
      : 0.0;
  final muteDecayMul = palmMute ? 18.0 : 1.0;
  final muteBodyMul = palmMute ? 0.28 : 1.0;
  final sympatheticMul = palmMute ? 0.18 : 1.0;

  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final env =
        (1 - math.exp(-44 * t)) *
        math.exp(-(2.25 / styleDecay) * muteDecayMul * t) *
        (1 - t / durationSeconds).clamp(0.0, 1.0);
    final dynamicFrequency =
        frequency * (1.0 + tensionTransientAmount * math.exp(-25 * t));
    var tone = 0.0;
    for (var partial = 1; partial <= 8; partial += 1) {
      final harmonicFreq = dynamicFrequency * partial;
      final comb = math.sin(math.pi * pickPosition * partial).abs();
      final velocityBrightness = partial > 3
          ? math.pow(normalizedVelocity, 1.5).toDouble()
          : math.pow(normalizedVelocity, 0.82).toDouble();
      final muteDampening = palmMute
          ? math.max(0.1, 1.0 - partial * 0.15)
          : 1.0;
      final amp =
          (1 / math.pow(partial, 1.12)) *
          (0.75 + comb * 1.05) *
          styleBrightness *
          velocityBrightness *
          muteDampening;
      final partialDecay = math.exp(
        -(0.7 + partial * 0.22 / styleDecay) * (palmMute ? 3.0 : 1.0) * t,
      );
      tone +=
          math.sin(math.pi * 2 * harmonicFreq * t + partial * 0.09) *
          amp *
          partialDecay *
          0.52;
    }
    if (style == 'twelve') {
      tone +=
          math.sin(math.pi * 2 * doubledFrequency * 0.996 * t + 0.16) *
          0.24 *
          math.exp(-1.85 * t);
      tone +=
          math.sin(math.pi * 2 * doubledFrequency * 1.004 * t - 0.09) *
          0.22 *
          math.exp(-1.8 * t);
    }
    final bridgeClick =
        (math.sin((i + 1) * 18.17) + math.cos((i + 1) * 63.41)) *
        (0.03 + pickColor * 0.02) *
        normalizedVelocity *
        math.exp(-44 * t);
    final fretNoise =
        (math.sin((i + 1) * 137.0) + math.cos((i + 1) * 96.5)) *
        (0.008 + pickColor * 0.01) *
        (0.75 + normalizedVelocity * 0.85) *
        math.exp(-(palmMute ? 26.0 : 18.0) * t);
    final bodyModeA =
        math.sin(math.pi * 2 * dynamicFrequency * 0.5 * t + 0.7) *
        resonantBody *
        styleBody *
        muteBodyMul *
        0.18 *
        math.exp(-2.8 * t);
    final bodyModeB =
        math.sin(math.pi * 2 * dynamicFrequency * 0.77 * t + 1.1) *
        resonantBody *
        styleBody *
        muteBodyMul *
        0.12 *
        math.exp(-3.2 * t);
    final sympathetic =
        math.sin(math.pi * 2 * dynamicFrequency * 1.01 * t + 0.5) *
        (0.06 + resonance * 0.08) *
        sympatheticMul *
        math.exp(-1.9 * t);
    samples[i] = _softClip(
      (tone + bridgeClick + fretNoise + bodyModeA + bodyModeB + sympathetic) *
          env *
          (palmMute ? 1.08 : 1.28),
    );
  }

  final reverb = switch (style) {
    'nylon' => 0.16 + resonance * 0.11,
    'ambient' => 0.28 + resonance * 0.15,
    'twelve' => 0.2 + resonance * 0.12,
    _ => 0.18 + resonance * 0.12,
  };
  _applySchroederReverb(samples, sampleRate: sampleRate, amount: reverb);
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.9);
}

Uint8List _buildGuqinNote({
  required double frequency,
  required String style,
  required double resonance,
  required double slide,
}) {
  const sampleRate = 32000;
  const durationSeconds = 4.6;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0);
  final toneBrightness = switch (style) {
    'bright' => 1.16,
    'hollow' => 0.74,
    _ => 0.92,
  };
  final bodyMul = switch (style) {
    'bright' => 0.9,
    'hollow' => 1.12,
    _ => 1.0,
  };
  final decayBase = switch (style) {
    'bright' => 1.5,
    'hollow' => 1.22,
    _ => 1.34,
  };
  final slideSemitone = slide.clamp(-1.0, 1.0) * 2.4;
  final slideSign = slideSemitone.sign;
  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final attack = (1 - math.exp(-38 * t));
    final decay = math.exp(-(decayBase - resonance * 0.42) * t);
    final tail = (1 - t / durationSeconds).clamp(0.0, 1.0).toDouble();
    final env = (attack * decay * tail).clamp(0.0, 1.0).toDouble();
    final slideProgress = (1 - math.exp(-6.5 * t)) * math.exp(-0.82 * t);
    final slideCurve = math.pow(slideProgress, 1.05).toDouble();
    final slideOffset = slideSemitone * slideCurve;
    final microVibrato =
        1 + 0.0018 * math.sin(math.pi * 2 * (4.2 + resonance) * t);
    final shiftedFrequency =
        frequency * math.pow(2.0, slideOffset / 12.0).toDouble() * microVibrato;
    final stringFriction =
        (math.sin((i + 1) * 19.31) + math.cos((i + 1) * 57.11)) *
        (0.012 + resonance * 0.016) *
        math.exp(-24 * t);
    final slideRustle =
        (math.sin((i + 1) * 103.9) + math.cos((i + 1) * 77.4)) *
        (0.007 + slideSign.abs() * 0.012) *
        math.exp(-8.6 * math.max(0.0, t - 0.09));
    var tone = math.sin(math.pi * 2 * shiftedFrequency * t) * 0.66;
    tone +=
        math.sin(math.pi * 2 * shiftedFrequency * 2 * t + 0.2) *
        (0.2 * toneBrightness);
    tone +=
        math.sin(math.pi * 2 * shiftedFrequency * 3.1 * t + 0.68) *
        (0.1 * toneBrightness);
    tone +=
        math.sin(math.pi * 2 * shiftedFrequency * 4.8 * t + 1.18) *
        (0.045 * toneBrightness);
    final harmonicChime =
        math.sin(math.pi * 2 * shiftedFrequency * 2.0 * t + 0.42) *
        (0.1 + resonance * 0.1) *
        math.exp(-1.9 * t);
    final body =
        math.sin(math.pi * 2 * shiftedFrequency * 0.5 * t + 0.9) *
        (0.1 + resonance * 0.08) *
        bodyMul *
        math.exp(-2.2 * t);
    samples[i] = _softClip(
      (tone + harmonicChime + body + stringFriction + slideRustle) * env * 1.22,
    );
  }
  _applySchroederReverb(
    samples,
    sampleRate: sampleRate,
    amount: 0.2 + resonance * 0.24,
  );
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.88);
}

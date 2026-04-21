part of 'toolbox_audio_service.dart';

Uint8List _buildPrayerBeadClick({
  required String style,
  required bool accent,
  required int variant,
}) {
  const sampleRate = 32000;
  final styleSeed = switch (style) {
    'jade' => 0.9,
    'lapis' => 1.8,
    'bodhi' => 2.7,
    'obsidian' => 3.6,
    _ => 0.2,
  };
  final (
    primary,
    overtone,
    ring,
    body,
    decay,
    lowDecay,
    noiseMix,
    transient,
  ) = switch (style) {
    'jade' => (1320.0, 2050.0, 2910.0, 420.0, 21.0, 10.0, 0.055, 0.34),
    'lapis' => (940.0, 1540.0, 2280.0, 330.0, 18.0, 9.5, 0.08, 0.3),
    'bodhi' => (710.0, 1160.0, 1660.0, 280.0, 16.2, 8.6, 0.12, 0.24),
    'obsidian' => (620.0, 1020.0, 1510.0, 250.0, 14.0, 8.2, 0.06, 0.2),
    _ => (560.0, 890.0, 1380.0, 220.0, 15.5, 8.8, 0.11, 0.24),
  };
  final variantId = variant.clamp(0, 31).toInt();
  double vrand(int salt) =>
      _variantRandom(variant: variantId, seed: styleSeed, salt: salt);

  final primaryVar = primary * (0.986 + vrand(1) * 0.028);
  final overtoneVar = overtone * (0.978 + vrand(2) * 0.044);
  final ringVar = ring * (0.97 + vrand(3) * 0.05);
  final bodyVar = body * (0.98 + vrand(4) * 0.03);
  final decayVar = decay * (0.94 + vrand(5) * 0.12);
  final lowDecayVar = lowDecay * (0.94 + vrand(6) * 0.12);
  final noiseMixVar = noiseMix * (0.88 + vrand(7) * 0.24);
  final transientVar = transient * (0.92 + vrand(8) * 0.2);
  final pitchMul = (accent ? 1.08 : 1.0) * (0.992 + vrand(9) * 0.016);
  final totalSamples =
      (sampleRate * ((accent ? 0.32 : 0.24) + vrand(10) * 0.018)).round();
  final samples = List<double>.filled(totalSamples, 0);
  final impactPhase = vrand(11) * math.pi * 2;
  var noiseState = 0.0;
  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final attack = 1 - math.exp(-150 * t);
    final toneEnv =
        attack * math.exp(-(accent ? decayVar * 0.88 : decayVar) * t);
    final bodyEnv =
        attack * math.exp(-(accent ? lowDecayVar * 0.82 : lowDecayVar) * t);
    final noiseEnv = math.exp(-(accent ? 74.0 : 88.0) * t);
    final sweep = 1.0 + 0.14 * math.exp(-180 * t);
    final tone =
        math.sin(math.pi * 2 * primaryVar * pitchMul * sweep * t) * 0.70 +
        math.sin(math.pi * 2 * overtoneVar * pitchMul * t + 0.18) * 0.22 +
        math.sin(math.pi * 2 * ringVar * pitchMul * t + 0.74) * 0.12;
    final bodyTone =
        math.sin(math.pi * 2 * bodyVar * pitchMul * t + 0.42) * 0.22;
    final click =
        math.sin(math.pi * 2 * (primaryVar * 2.4) * pitchMul * t + 0.08) *
        transientVar *
        math.exp(-96 * t);
    final contactNoise =
        (math.sin(i * 14.231 + impactPhase) +
            math.cos(i * 71.917 + styleSeed + impactPhase * 0.6)) *
        0.5 *
        math.exp(-720 * t) *
        (0.018 + transientVar * 0.06);
    final noiseRaw =
        (math.sin(i * 12.9898 + primaryVar * 0.001 + impactPhase) +
            math.cos(i * 78.233 + overtoneVar * 0.0008 + impactPhase * 0.4)) *
        noiseMixVar;
    noiseState += (noiseRaw - noiseState) * 0.34;
    final noise = noiseState * noiseEnv;
    samples[i] =
        (tone * toneEnv + bodyTone * bodyEnv + click + contactNoise + noise) *
        (accent ? 1.08 : 0.98);
  }
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.95);
}

part of 'toolbox_audio_service.dart';

String _normalizeFluteStyle(String style) {
  return switch (style) {
    'lead' => 'lead',
    'alto' => 'alto',
    'bamboo' => 'bamboo',
    _ => 'airy',
  };
}

String _normalizeFluteMaterial(String material) {
  return switch (material) {
    'metal_short' => 'metal_short',
    'jade' => 'jade',
    _ => 'wood',
  };
}

({
  double attack,
  double release,
  double bodyMix,
  double edgeMix,
  double breathNoise,
  double vibratoDepth,
  double vibratoRate,
  double brightness,
})
_resolveFluteProfile({required String style, required String material}) {
  final styleProfile = switch (style) {
    'lead' => (
      attack: 0.05,
      release: 1.55,
      bodyMix: 0.54,
      edgeMix: 0.32,
      breathNoise: 0.11,
      vibratoDepth: 0.004,
      vibratoRate: 6.2,
      brightness: 0.74,
    ),
    'alto' => (
      attack: 0.09,
      release: 1.75,
      bodyMix: 0.66,
      edgeMix: 0.22,
      breathNoise: 0.09,
      vibratoDepth: 0.006,
      vibratoRate: 5.3,
      brightness: 0.56,
    ),
    'bamboo' => (
      attack: 0.08,
      release: 1.68,
      bodyMix: 0.69,
      edgeMix: 0.18,
      breathNoise: 0.1,
      vibratoDepth: 0.005,
      vibratoRate: 5.1,
      brightness: 0.5,
    ),
    _ => (
      attack: 0.07,
      release: 1.7,
      bodyMix: 0.6,
      edgeMix: 0.24,
      breathNoise: 0.1,
      vibratoDepth: 0.005,
      vibratoRate: 5.8,
      brightness: 0.62,
    ),
  };

  final materialMod = switch (material) {
    'metal_short' => (
      body: 0.92,
      edge: 1.32,
      breath: 0.84,
      brightness: 1.18,
      release: 0.88,
      vibratoDepth: 0.85,
      vibratoRate: 1.14,
    ),
    'jade' => (
      body: 1.02,
      edge: 1.06,
      breath: 0.92,
      brightness: 1.02,
      release: 0.95,
      vibratoDepth: 0.95,
      vibratoRate: 1.0,
    ),
    _ => (
      body: 1.08,
      edge: 0.9,
      breath: 1.1,
      brightness: 0.92,
      release: 1.0,
      vibratoDepth: 1.05,
      vibratoRate: 0.96,
    ),
  };

  return (
    attack: styleProfile.attack,
    release: styleProfile.release * materialMod.release,
    bodyMix: (styleProfile.bodyMix * materialMod.body).clamp(0.2, 1.0),
    edgeMix: (styleProfile.edgeMix * materialMod.edge).clamp(0.06, 0.7),
    breathNoise: (styleProfile.breathNoise * materialMod.breath).clamp(
      0.02,
      0.3,
    ),
    vibratoDepth: (styleProfile.vibratoDepth * materialMod.vibratoDepth).clamp(
      0.001,
      0.02,
    ),
    vibratoRate: (styleProfile.vibratoRate * materialMod.vibratoRate).clamp(
      3.5,
      8.5,
    ),
    brightness: (styleProfile.brightness * materialMod.brightness).clamp(
      0.2,
      1.4,
    ),
  );
}

Uint8List _buildFluteNote(
  double frequency,
  String style, {
  required String material,
  required double breath,
  required double reverb,
  required double tail,
  required bool sustained,
}) {
  const sampleRate = 32000;
  final profile = _resolveFluteProfile(style: style, material: material);
  final normalizedBreath = breath.clamp(0.18, 1.0).toDouble();
  final normalizedTail = tail.clamp(0.15, 1.0).toDouble();
  final durationSeconds = sustained
      ? 2.8 + normalizedTail * 1.6
      : 1.0 + normalizedTail * 1.3;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0.0);

  final variantSeed = style.hashCode * 0.00017 + material.hashCode * 0.000041;
  final variantId = (variantSeed * 1000).round().abs() % 31;
  final vibratoPhase =
      _variantRandom(variant: variantId, seed: frequency * 0.0023, salt: 1) *
      math.pi *
      2;
  final edgeDetune = (normalizedBreath - 0.5) * 0.0045;
  final attackTime = (profile.attack * (0.78 + (1 - normalizedBreath) * 0.55))
      .clamp(0.03, 0.2);
  final releaseTime = (0.18 + normalizedTail * 0.36 + (sustained ? 0.25 : 0.1))
      .clamp(0.18, 0.7);

  var breathState = 0.0;
  var toneState = 0.0;
  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final contour = _fluteNoteEnvelope(
      t: t,
      durationSeconds: durationSeconds,
      attackTime: attackTime,
      releaseTime: releaseTime,
    );

    final vibratoRamp = _smoothStep(
      ((t - attackTime * 0.7) / (0.32 + normalizedBreath * 0.2)).clamp(
        0.0,
        1.0,
      ),
    );
    final slowDrift =
        math.sin(
          math.pi * 2 * (0.21 + normalizedBreath * 0.11) * t +
              vibratoPhase * 0.7,
        ) *
        0.0015;
    final vibrato =
        math.sin(math.pi * 2 * profile.vibratoRate * t + vibratoPhase) *
        profile.vibratoDepth *
        (0.45 + normalizedBreath * 0.7) *
        vibratoRamp;
    final instantFrequency = frequency * (1 + vibrato + slowDrift);

    var core =
        math.sin(math.pi * 2 * instantFrequency * t) *
        (0.62 + profile.brightness * 0.08);
    core +=
        math.sin(math.pi * 2 * instantFrequency * 2 * t + 0.42) *
        (0.18 + profile.brightness * 0.14);
    core +=
        math.sin(math.pi * 2 * instantFrequency * 3.02 * t + 1.04) *
        (0.08 + profile.brightness * 0.1);

    var bore =
        math.sin(math.pi * 2 * instantFrequency * 1.95 * t + 0.25) *
        (0.09 + profile.bodyMix * 0.07);
    bore +=
        math.sin(math.pi * 2 * instantFrequency * 2.9 * t + 1.1) *
        (0.03 + profile.bodyMix * 0.04);

    var edge =
        math.sin(
          math.pi * 2 * instantFrequency * (4.3 + edgeDetune) * t + 0.5,
        ) *
        (0.05 + profile.edgeMix * 0.22);
    edge +=
        math.sin(
          math.pi * 2 * instantFrequency * (5.4 + edgeDetune * 0.6) * t + 1.3,
        ) *
        (0.02 + profile.edgeMix * 0.12);

    final rawBreath =
        (math.sin((i + 1) * 17.38 + variantSeed) +
            math.cos((i + 1) * 41.73 + variantSeed * 1.7)) *
        0.5;
    breathState +=
        (rawBreath - breathState) * (0.055 + normalizedBreath * 0.06);
    final breathNoise =
        breathState * (profile.breathNoise * (0.35 + normalizedBreath * 0.95));

    final attackBurstWindow = (1 - (t / 0.055)).clamp(0.0, 1.0);
    final attackBurst = attackBurstWindow > 0
        ? attackBurstWindow * breathNoise * (0.35 + profile.edgeMix * 0.22)
        : 0.0;

    final airFlutter =
        math.sin(
          math.pi * 2 * (7.4 + normalizedBreath * 3.2) * t + vibratoPhase,
        ) *
        0.02 *
        normalizedBreath;

    final mixed =
        core * profile.bodyMix +
        bore +
        edge +
        breathNoise * (0.38 + normalizedBreath * 0.48) +
        attackBurst +
        airFlutter * profile.edgeMix;
    final target = _softClip(mixed * contour * 0.93);
    toneState += (target - toneState) * (0.24 + profile.brightness * 0.08);
    samples[i] = toneState;
  }

  _applyOnePoleLowPass(
    samples,
    sampleRate: sampleRate,
    cutoffHz: 8200 + profile.brightness * 2600,
  );
  _applyDcBlock(samples, pole: 0.996);
  _applySchroederReverb(
    samples,
    sampleRate: sampleRate,
    amount: (0.08 + reverb * 0.72 + normalizedTail * 0.14).clamp(0.05, 0.68),
  );
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.9);
}

Uint8List _buildFluteSustainLayer(
  double frequency,
  String style, {
  required String material,
  required String layer,
}) {
  const sampleRate = 32000;
  const durationSeconds = 2.6;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0.0);
  final profile = _resolveFluteProfile(style: style, material: material);

  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final attackEnv = (t / 0.14).clamp(0.0, 1.0);
    final releaseEnv = ((durationSeconds - t) / 0.28).clamp(0.0, 1.0);
    final envelope = _smoothStep(attackEnv) * _smoothStep(releaseEnv);

    final sample = switch (layer) {
      'core' => _buildFluteCoreLayerSample(
        frequency: frequency,
        t: t,
        profile: profile,
      ),
      'air' => _buildFluteAirLayerSample(
        frequency: frequency,
        t: t,
        profile: profile,
        index: i,
      ),
      'edge' => _buildFluteEdgeLayerSample(
        frequency: frequency,
        t: t,
        profile: profile,
      ),
      _ => 0.0,
    };

    samples[i] = _softClip(sample * envelope * 0.86);
  }

  final cutoffHz = switch (layer) {
    'air' => 4200.0,
    'edge' => 9000.0,
    _ => 6800.0,
  };
  _applyOnePoleLowPass(samples, sampleRate: sampleRate, cutoffHz: cutoffHz);
  _applyDcBlock(samples, pole: 0.996);
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.9);
}

double _buildFluteCoreLayerSample({
  required double frequency,
  required double t,
  required ({
    double attack,
    double release,
    double bodyMix,
    double edgeMix,
    double breathNoise,
    double vibratoDepth,
    double vibratoRate,
    double brightness,
  })
  profile,
}) {
  final vibrato =
      math.sin(math.pi * 2 * profile.vibratoRate * t) * profile.vibratoDepth;
  final instantFrequency = frequency * (1 + vibrato);
  var core =
      math.sin(math.pi * 2 * instantFrequency * t) *
      (0.66 + profile.bodyMix * 0.16);
  core +=
      math.sin(math.pi * 2 * instantFrequency * 2 * t + 0.4) *
      (0.2 + profile.brightness * 0.08);
  core +=
      math.sin(math.pi * 2 * instantFrequency * 3 * t + 1.1) *
      (0.08 + profile.brightness * 0.04);
  return core;
}

double _buildFluteAirLayerSample({
  required double frequency,
  required double t,
  required int index,
  required ({
    double attack,
    double release,
    double bodyMix,
    double edgeMix,
    double breathNoise,
    double vibratoDepth,
    double vibratoRate,
    double brightness,
  })
  profile,
}) {
  final breath =
      (math.sin((index + 1) * 12.53) + math.cos((index + 1) * 27.17)) *
      0.5 *
      (0.05 + profile.breathNoise * 0.85);
  final shimmer =
      math.sin(math.pi * 2 * frequency * 5.2 * t + 0.74) *
      (0.02 + profile.edgeMix * 0.08);
  return breath + shimmer;
}

double _buildFluteEdgeLayerSample({
  required double frequency,
  required double t,
  required ({
    double attack,
    double release,
    double bodyMix,
    double edgeMix,
    double breathNoise,
    double vibratoDepth,
    double vibratoRate,
    double brightness,
  })
  profile,
}) {
  var edge =
      math.sin(math.pi * 2 * frequency * 4.8 * t + 0.2) *
      (0.05 + profile.edgeMix * 0.3);
  edge +=
      math.sin(math.pi * 2 * frequency * 6.4 * t + 1.6) *
      (0.02 + profile.edgeMix * 0.2);
  edge +=
      math.sin(math.pi * 2 * frequency * 7.9 * t + 2.1) *
      (0.01 + profile.edgeMix * 0.16);
  return edge;
}

double _fluteNoteEnvelope({
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

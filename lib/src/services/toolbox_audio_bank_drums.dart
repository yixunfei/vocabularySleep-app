part of 'toolbox_audio_service.dart';

double _drumMaterialBrightness(String material) {
  return switch (material) {
    'metal' => 1.22,
    'hybrid' => 1.06,
    _ => 0.9,
  };
}

Uint8List _buildDrumHit(
  String kind,
  String kit,
  double tone,
  double tail,
  String material,
) {
  return switch (kind) {
    'snare' => _buildSnareHit(kit, tone, tail, material),
    'hihat' => _buildHiHatHit(kit, tone, tail, material),
    'openhat' => _buildOpenHatHit(kit, tone, tail, material),
    'clap' => _buildClapHit(kit, tone, tail, material),
    'tom' => _buildTomHit(kit, tone, tail, material),
    _ => _buildKickHit(kit, tone, tail, material),
  };
}

Uint8List _buildKickHit(String kit, double tone, double tail, String material) {
  const sampleRate = 24000;
  const durationSeconds = 0.62;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0);
  final bodyMul = switch (kit) {
    'electro' => 1.3,
    'lofi' => 0.9,
    _ => 1.04,
  };
  final clickMul = switch (kit) {
    'electro' => 1.34,
    'lofi' => 0.66,
    _ => 0.92,
  };
  final materialMul = _drumMaterialBrightness(material);
  final tailDecay = 10.8 - tail * 5.6;
  final startSweep = 118 + tone * 48;
  final endSweep = 34 + tone * 22;
  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final sweep =
        startSweep -
        (startSweep - endSweep) *
            math.pow((t / durationSeconds).clamp(0.0, 1.0), 0.88);
    final env = math.exp(-tailDecay * t);
    final sub = math.sin(math.pi * 2 * sweep * t) * (0.86 * bodyMul);
    final subTail =
        math.sin(math.pi * 2 * (sweep * 0.52) * t + 0.2) *
        (0.19 + tail * 0.18) *
        math.exp(-4.6 * t);
    final shell =
        math.sin(math.pi * 2 * (sweep * 1.04) * t + 0.18) *
        (0.08 + tail * 0.06) *
        math.exp(-6.4 * t);
    final airPush =
        math.sin(math.pi * 2 * (sweep * 0.24) * t + 0.64) *
        (0.06 + materialMul * 0.02) *
        math.exp(-3.5 * t);
    final click = math.exp(-115 * t) * (0.09 * clickMul * materialMul);
    final beaterNoise =
        (math.sin((i + 1) * 30.41) + math.cos((i + 1) * 51.22)) *
        (0.018 + tone * 0.014) *
        math.exp(-46 * t);
    samples[i] = _softClip(
      (sub + subTail + shell + airPush + click + beaterNoise) * env * 1.28,
    );
  }
  if (kit != 'electro') {
    _applySchroederReverb(
      samples,
      sampleRate: sampleRate,
      amount: 0.018 + tail * 0.05,
    );
  }
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.93);
}

Uint8List _buildSnareHit(
  String kit,
  double tone,
  double tail,
  String material,
) {
  const sampleRate = 24000;
  const durationSeconds = 0.42;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0);
  final toneMul = switch (kit) {
    'electro' => 0.92,
    'lofi' => 0.78,
    _ => 1.0,
  };
  final noiseMul = switch (kit) {
    'electro' => 1.24,
    'lofi' => 0.9,
    _ => 1.0,
  };
  final materialMul = _drumMaterialBrightness(material);
  final toneFrequency = 154 + tone * 98;
  final decay = 17.4 - tail * 7.2;
  final wireDecay = 32 - tail * 13.5;
  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final env = math.exp(-decay * t);
    final shell =
        math.sin(math.pi * 2 * toneFrequency * t) *
        (0.36 * toneMul) *
        math.exp(-(9.8 - tail * 3.2) * t);
    final overtone =
        math.sin(math.pi * 2 * toneFrequency * 2.02 * t + 0.16) *
        0.12 *
        math.exp(-12.5 * t);
    final wireNoise =
        (math.sin((i + 1) * 91.7) +
            math.cos((i + 1) * 67.3) +
            math.sin((i + 1) * 121.9)) *
        (0.3 * noiseMul * (0.86 + materialMul * 0.2)) *
        math.exp(-wireDecay * t);
    final snap =
        math.sin(math.pi * 2 * (4100 + tone * 1100) * t) *
        (0.04 * materialMul) *
        math.exp(-80 * t);
    final roomBody =
        math.sin(math.pi * 2 * toneFrequency * 0.52 * t + 0.72) *
        (0.05 + tail * 0.04) *
        math.exp(-5.8 * t);
    samples[i] = _softClip(
      (shell + overtone + wireNoise + snap + roomBody) * env * 1.04,
    );
  }
  _applySchroederReverb(
    samples,
    sampleRate: sampleRate,
    amount: kit == 'electro' ? (0.06 + tail * 0.04) : (0.025 + tail * 0.035),
  );
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.93);
}

Uint8List _buildHiHatHit(
  String kit,
  double tone,
  double tail,
  String material,
) {
  const sampleRate = 24000;
  const durationSeconds = 0.3;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0);
  final noiseMul = switch (kit) {
    'electro' => 1.34,
    'lofi' => 0.8,
    _ => 1.0,
  };
  final materialMul = _drumMaterialBrightness(material);
  final decay = 31 - tail * 12;
  final modes = <double>[
    4700 + tone * 2200,
    6350 + tone * 2700,
    8120 + tone * 3000,
  ];
  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final env = math.exp(-decay * t);
    final noise =
        (math.sin((i + 1) * 211.3) +
            math.sin((i + 1) * 139.7) +
            math.cos((i + 1) * 97.1)) *
        (0.21 * noiseMul) *
        math.exp(-18 * t);
    var metal = 0.0;
    for (var mode = 0; mode < modes.length; mode += 1) {
      metal +=
          math.sin(math.pi * 2 * modes[mode] * t + mode * 0.41) *
          (0.042 + mode * 0.012) *
          materialMul;
    }
    final stick =
        math.sin(math.pi * 2 * (9500 + tone * 2000) * t) *
        0.014 *
        math.exp(-120 * t);
    final airTail =
        math.sin(math.pi * 2 * 3100 * t + 0.4) * 0.012 * math.exp(-20 * t);
    samples[i] = _softClip((noise + metal + stick + airTail) * env * 1.0);
  }
  if (kit != 'electro') {
    _applySchroederReverb(
      samples,
      sampleRate: sampleRate,
      amount: 0.008 + tail * 0.012,
    );
  }
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.9);
}

Uint8List _buildOpenHatHit(
  String kit,
  double tone,
  double tail,
  String material,
) {
  const sampleRate = 24000;
  const durationSeconds = 0.62;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0);
  final noiseMul = switch (kit) {
    'electro' => 1.26,
    'lofi' => 0.84,
    _ => 1.0,
  };
  final materialMul = _drumMaterialBrightness(material);
  final decay = 8.9 - tail * 3.8;
  final modes = <double>[
    3720 + tone * 1560,
    5180 + tone * 2140,
    6810 + tone * 2560,
    8720 + tone * 2820,
  ];
  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final env = math.exp(-decay * t);
    final washNoise =
        (math.sin((i + 1) * 173.2) +
            math.cos((i + 1) * 117.6) +
            math.sin((i + 1) * 87.9)) *
        (0.18 * noiseMul) *
        math.exp(-(6.8 + (1 - tail) * 4.2) * t);
    var metal = 0.0;
    for (var mode = 0; mode < modes.length; mode += 1) {
      metal +=
          math.sin(math.pi * 2 * modes[mode] * t + mode * 0.36) *
          (0.032 + mode * 0.01) *
          materialMul *
          math.exp(-(11.5 - tail * 3.5) * t);
    }
    final sizzle =
        math.sin(math.pi * 2 * (9800 + tone * 1400) * t) *
        (0.014 + materialMul * 0.005) *
        math.exp(-44 * t);
    final shimmer =
        math.sin(math.pi * 2 * 2560 * t + 0.5) * 0.014 * math.exp(-8.5 * t);
    samples[i] = _softClip((washNoise + metal + sizzle + shimmer) * env * 1.06);
  }
  if (kit != 'electro') {
    _applySchroederReverb(
      samples,
      sampleRate: sampleRate,
      amount: 0.018 + tail * 0.05,
    );
  }
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.91);
}

Uint8List _buildClapHit(String kit, double tone, double tail, String material) {
  const sampleRate = 24000;
  const durationSeconds = 0.34;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0);
  final airMul = switch (kit) {
    'electro' => 1.14,
    'lofi' => 0.88,
    _ => 1.0,
  };
  final materialMul = _drumMaterialBrightness(material);
  final decay = 17.2 - tail * 6.4;
  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final env = math.exp(-decay * t);
    final burstA = math.exp(-math.pow((t - 0.0) / 0.0048, 2).toDouble());
    final burstB = math.exp(-math.pow((t - 0.011) / 0.0055, 2).toDouble());
    final burstC = math.exp(-math.pow((t - 0.023) / 0.0065, 2).toDouble());
    final burstEnv = burstA + burstB * 0.84 + burstC * 0.68;
    final noise =
        (math.sin((i + 1) * 153.7) +
            math.cos((i + 1) * 101.8) +
            math.sin((i + 1) * 69.4)) *
        (0.24 * airMul) *
        burstEnv;
    final body =
        math.sin(math.pi * 2 * (920 + tone * 340) * t) *
        (0.09 + materialMul * 0.02) *
        math.exp(-26 * t);
    final snap =
        math.sin(math.pi * 2 * (3400 + tone * 1600) * t) *
        (0.032 * materialMul) *
        math.exp(-72 * t);
    final palmBody =
        math.sin(math.pi * 2 * (560 + tone * 180) * t + 0.8) *
        0.04 *
        math.exp(-14 * t);
    samples[i] = _softClip((noise + body + snap + palmBody) * env * 1.12);
  }
  _applySchroederReverb(
    samples,
    sampleRate: sampleRate,
    amount: kit == 'lofi' ? (0.026 + tail * 0.04) : (0.016 + tail * 0.028),
  );
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.91);
}

Uint8List _buildTomHit(String kit, double tone, double tail, String material) {
  const sampleRate = 24000;
  const durationSeconds = 0.52;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0);
  final bodyMul = switch (kit) {
    'electro' => 1.12,
    'lofi' => 0.84,
    _ => 1.0,
  };
  final materialMul = _drumMaterialBrightness(material);
  final rootStart = 122 + tone * 68;
  final rootEnd = 92 + tone * 48;
  final decay = 11.2 - tail * 4.2;
  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final pitch =
        rootStart -
        (rootStart - rootEnd) * (t / durationSeconds).clamp(0.0, 1.0);
    final env = math.exp(-decay * t);
    final fundamental = math.sin(math.pi * 2 * pitch * t) * (0.64 * bodyMul);
    final overtone =
        math.sin(math.pi * 2 * pitch * 2.03 * t + 0.18) *
        (0.25 * materialMul) *
        math.exp(-7.5 * t);
    final shell =
        math.sin(math.pi * 2 * pitch * 0.52 * t + 0.7) *
        0.16 *
        math.exp(-3.8 * t);
    final bloom =
        math.sin(math.pi * 2 * pitch * 1.48 * t + 0.44) *
        0.08 *
        math.exp(-5.4 * t);
    final knock =
        (math.sin((i + 1) * 32.7) + math.cos((i + 1) * 53.2)) *
        (0.048 + tone * 0.018) *
        math.exp(-40 * t);
    samples[i] = _softClip(
      (fundamental + overtone + shell + bloom + knock) * env * 1.1,
    );
  }
  if (kit != 'electro') {
    _applySchroederReverb(
      samples,
      sampleRate: sampleRate,
      amount: 0.012 + tail * 0.026,
    );
  }
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.92);
}

Uint8List _buildTriangleHit(
  String style,
  String material,
  double strike,
  double damping,
) {
  const sampleRate = 32000;
  const durationSeconds = 2.9;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0);
  final styleHighMul = switch (style) {
    'bright' => 1.3,
    'soft' => 0.68,
    _ => 1.0,
  };
  final styleDecayMul = switch (style) {
    'bright' => 1.1,
    'soft' => 0.82,
    _ => 1.0,
  };
  final materialHighMul = switch (material) {
    'brass' => 0.88,
    'aluminum' => 1.16,
    _ => 1.0,
  };
  final strikeEdge = strike.clamp(0.0, 1.0);
  final decay = (2.15 + damping * 1.75) * styleDecayMul;
  final modes = <double>[
    980 + strikeEdge * 230,
    1410 + strikeEdge * 320,
    2010 + strikeEdge * 430,
    2780 + strikeEdge * 570,
    3520 + strikeEdge * 690,
  ];
  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final env = (1 - math.exp(-130 * t)) * math.exp(-decay * t);
    var value = 0.0;
    for (var mode = 0; mode < modes.length; mode += 1) {
      value +=
          math.sin(math.pi * 2 * modes[mode] * t + mode * 0.37) *
          (0.36 / (mode + 1)) *
          styleHighMul *
          materialHighMul;
    }
    final click =
        (math.sin((i + 1) * 102.5) + math.cos((i + 1) * 44.1)) *
        (0.018 + strikeEdge * 0.012) *
        math.exp(-130 * t);
    samples[i] = _softClip((value + click) * env * 1.1);
  }
  final reverb = switch (style) {
    'bright' => 0.22 + (1 - damping) * 0.09,
    'soft' => 0.28 + (1 - damping) * 0.05,
    _ => 0.25 + (1 - damping) * 0.08,
  };
  _applySchroederReverb(samples, sampleRate: sampleRate, amount: reverb);
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.9);
}

import 'dart:math' as math;

enum ToolboxFreeChimeLayer {
  shaker,
  water,
  windChime,
  leaves,
  bubbles,
  rain,
  impact,
  kuaiban,
  gongDrum,
  marble,
}

extension ToolboxFreeChimeLayerInfo on ToolboxFreeChimeLayer {
  String get id {
    return switch (this) {
      ToolboxFreeChimeLayer.shaker => 'shaker',
      ToolboxFreeChimeLayer.water => 'water',
      ToolboxFreeChimeLayer.windChime => 'wind_chime',
      ToolboxFreeChimeLayer.leaves => 'leaves',
      ToolboxFreeChimeLayer.bubbles => 'bubbles',
      ToolboxFreeChimeLayer.rain => 'rain',
      ToolboxFreeChimeLayer.impact => 'impact',
      ToolboxFreeChimeLayer.kuaiban => 'kuaiban',
      ToolboxFreeChimeLayer.gongDrum => 'gong_drum',
      ToolboxFreeChimeLayer.marble => 'marble',
    };
  }

  bool get isRhythmic {
    return switch (this) {
      ToolboxFreeChimeLayer.impact ||
      ToolboxFreeChimeLayer.kuaiban ||
      ToolboxFreeChimeLayer.gongDrum ||
      ToolboxFreeChimeLayer.marble => true,
      _ => false,
    };
  }
}

enum ToolboxFreeChimeIntensityBand { idle, gentle, flowing, lively, strong }

enum ToolboxFreeChimePlayMode { free, allegro }

class ToolboxFreeChimeLayerMix {
  const ToolboxFreeChimeLayerMix({required this.layer, required this.amount});

  final ToolboxFreeChimeLayer layer;
  final double amount;

  ToolboxFreeChimeLayerMix copyWith({double? amount}) {
    return ToolboxFreeChimeLayerMix(
      layer: layer,
      amount: amount ?? this.amount,
    );
  }
}

class ToolboxFreeChimeMotionSample {
  const ToolboxFreeChimeMotionSample({
    required this.timestamp,
    required this.x,
    required this.y,
    required this.z,
  });

  final DateTime timestamp;
  final double x;
  final double y;
  final double z;

  double get magnitude => math.sqrt(x * x + y * y + z * z);

  double get axisBias {
    final total = x.abs() + y.abs() + z.abs();
    if (total <= 0.001) return 0;
    return ((x - y) / total).clamp(-1.0, 1.0).toDouble();
  }
}

class ToolboxFreeChimeHit {
  const ToolboxFreeChimeHit({
    required this.layer,
    required this.volume,
    required this.playbackRate,
    required this.variant,
    this.pan = 0,
  });

  final ToolboxFreeChimeLayer layer;
  final double volume;
  final double playbackRate;
  final int variant;
  final double pan;
}

class ToolboxFreeChimeTrigger {
  const ToolboxFreeChimeTrigger({
    required this.timestamp,
    required this.band,
    required this.intensity,
    required this.magnitude,
    required this.hits,
    this.tempoBpm,
  });

  final DateTime timestamp;
  final ToolboxFreeChimeIntensityBand band;
  final double intensity;
  final double magnitude;
  final List<ToolboxFreeChimeHit> hits;
  final double? tempoBpm;
}

class ToolboxFreeChimePlaybackLimiter {
  ToolboxFreeChimePlaybackLimiter({required this.maxSlots})
    : assert(maxSlots > 0);

  final int maxSlots;
  int _activeSlots = 0;

  int get activeSlots => _activeSlots;

  int claim(int requestedSlots) {
    if (requestedSlots <= 0) return 0;
    final available = maxSlots - _activeSlots;
    if (available <= 0) return 0;
    final claimed = math.min(requestedSlots, available);
    _activeSlots += claimed;
    return claimed;
  }

  void release(int slots) {
    if (slots <= 0) return;
    _activeSlots = math.max(0, _activeSlots - slots);
  }

  void reset() {
    _activeSlots = 0;
  }
}

class ToolboxFreeChimeController {
  DateTime? _lastTriggerAt;
  DateTime? _lastDirectionChangeAt;
  DateTime? _lastFreeDirectionChangeAt;
  ToolboxFreeChimeMotionSample? _lastSample;
  double _smoothedIntensity = 0;
  double _allegroTempoBpm = 120;
  int _lastDirectionCode = 0;
  int _lastFreeDirectionCode = 0;
  int _sequence = 0;

  static const List<ToolboxFreeChimeLayerMix>
  defaultMixes = <ToolboxFreeChimeLayerMix>[
    ToolboxFreeChimeLayerMix(layer: ToolboxFreeChimeLayer.shaker, amount: 0),
    ToolboxFreeChimeLayerMix(layer: ToolboxFreeChimeLayer.water, amount: 0),
    ToolboxFreeChimeLayerMix(
      layer: ToolboxFreeChimeLayer.windChime,
      amount: 0.82,
    ),
    ToolboxFreeChimeLayerMix(layer: ToolboxFreeChimeLayer.leaves, amount: 0),
    ToolboxFreeChimeLayerMix(layer: ToolboxFreeChimeLayer.bubbles, amount: 0),
    ToolboxFreeChimeLayerMix(layer: ToolboxFreeChimeLayer.rain, amount: 0),
    ToolboxFreeChimeLayerMix(layer: ToolboxFreeChimeLayer.impact, amount: 0),
    ToolboxFreeChimeLayerMix(layer: ToolboxFreeChimeLayer.kuaiban, amount: 0),
    ToolboxFreeChimeLayerMix(layer: ToolboxFreeChimeLayer.gongDrum, amount: 0),
    ToolboxFreeChimeLayerMix(layer: ToolboxFreeChimeLayer.marble, amount: 0),
  ];

  double intensityForMagnitude(
    double magnitude, {
    required double sensitivity,
  }) {
    return normalizedIntensityForMagnitude(magnitude, sensitivity: sensitivity);
  }

  static double normalizedIntensityForMagnitude(
    double magnitude, {
    required double sensitivity,
  }) {
    final normalizedSensitivity = sensitivity.clamp(0.55, 1.65).toDouble();
    final activeMagnitude = math.max(0.0, magnitude - 0.22);
    return (activeMagnitude / (7.2 / normalizedSensitivity))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  ToolboxFreeChimeIntensityBand bandForIntensity(double intensity) {
    return _bandForIntensity(intensity);
  }

  ToolboxFreeChimeTrigger? evaluate(
    ToolboxFreeChimeMotionSample sample, {
    required Iterable<ToolboxFreeChimeLayerMix> mixes,
    required double sensitivity,
    ToolboxFreeChimePlayMode mode = ToolboxFreeChimePlayMode.free,
  }) {
    if (!_hasAudibleMixes(mixes)) {
      return null;
    }
    if (mode == ToolboxFreeChimePlayMode.allegro) {
      return _evaluateAllegro(sample, mixes: mixes, sensitivity: sensitivity);
    }
    final previousSample = _lastSample;
    _lastSample = sample;
    final rawIntensity = normalizedIntensityForMagnitude(
      sample.magnitude,
      sensitivity: sensitivity,
    );
    final motionDelta = _motionDelta(sample, previousSample);
    final swingSpeedAccent = _swingSpeedAccent(sample, previousSample);
    final directionCode = _dominantDirectionCode(sample);
    final directionChanged =
        _lastFreeDirectionCode != 0 &&
        directionCode != 0 &&
        directionCode != _lastFreeDirectionCode;
    final directionFlip =
        directionChanged && directionCode == -_lastFreeDirectionCode;
    final previousDirectionChangeAt = _lastFreeDirectionChangeAt;
    final quickTurnAccent =
        directionChanged && previousDirectionChangeAt != null
        ? _quickTurnAccent(sample.timestamp, previousDirectionChangeAt)
        : 0.0;
    if (directionCode != 0 && directionCode != _lastFreeDirectionCode) {
      _lastFreeDirectionChangeAt = sample.timestamp;
      _lastFreeDirectionCode = directionCode;
    }
    final motionAccent = (motionDelta / 9.5).clamp(0.0, 1.0).toDouble();
    final turnWeight = directionFlip ? 1.0 : 0.62;
    final collisionAccent = directionChanged
        ? (turnWeight *
                  (0.22 +
                      motionAccent * 0.3 +
                      swingSpeedAccent * 0.34 +
                      quickTurnAccent * 0.18))
              .clamp(0.0, 1.0)
              .toDouble()
        : 0.0;
    _smoothedIntensity = _smoothedIntensity * 0.55 + rawIntensity * 0.45;
    final intensity = math
        .max(
          math.max(
            rawIntensity * 0.68 +
                collisionAccent * 0.28 +
                swingSpeedAccent * 0.08,
            rawIntensity * 0.78,
          ),
          _smoothedIntensity,
        )
        .clamp(0.0, 1.0)
        .toDouble();
    if (intensity < 0.06) return null;

    final band = _bandForIntensity(intensity);
    final cooldown = _dynamicCooldownFor(
      band,
      directionChanged: directionChanged,
      motionAccent: motionAccent,
      swingSpeedAccent: swingSpeedAccent,
      quickTurnAccent: quickTurnAccent,
    );
    final previous = _lastTriggerAt;
    if (previous != null && sample.timestamp.difference(previous) < cooldown) {
      return null;
    }
    _lastTriggerAt = sample.timestamp;
    return _buildTrigger(
      timestamp: sample.timestamp,
      magnitude: sample.magnitude,
      intensity: intensity,
      band: band,
      axisBias: sample.axisBias,
      mixes: mixes,
      motionAccent: motionAccent,
      collisionAccent: collisionAccent,
      swingSpeedAccent: swingSpeedAccent,
    );
  }

  ToolboxFreeChimeTrigger preview({
    required DateTime timestamp,
    required double intensity,
    required Iterable<ToolboxFreeChimeLayerMix> mixes,
    ToolboxFreeChimePlayMode mode = ToolboxFreeChimePlayMode.free,
  }) {
    final normalizedIntensity = intensity.clamp(0.08, 1.0).toDouble();
    final safeMixes = _hasAudibleMixes(mixes)
        ? mixes
        : const <ToolboxFreeChimeLayerMix>[];
    return _buildTrigger(
      timestamp: timestamp,
      magnitude: normalizedIntensity * 7.2,
      intensity: normalizedIntensity,
      band: _bandForIntensity(normalizedIntensity),
      axisBias: 0,
      mixes: safeMixes,
      allegroBeat: mode == ToolboxFreeChimePlayMode.allegro,
      tempoBpm: mode == ToolboxFreeChimePlayMode.allegro
          ? (96 + normalizedIntensity * 112)
          : null,
    );
  }

  void resetTiming() {
    _lastTriggerAt = null;
    _lastDirectionChangeAt = null;
    _lastFreeDirectionChangeAt = null;
    _lastSample = null;
    _lastDirectionCode = 0;
    _lastFreeDirectionCode = 0;
    _smoothedIntensity = 0;
    _allegroTempoBpm = 120;
  }

  ToolboxFreeChimeTrigger? _evaluateAllegro(
    ToolboxFreeChimeMotionSample sample, {
    required Iterable<ToolboxFreeChimeLayerMix> mixes,
    required double sensitivity,
  }) {
    if (!_hasAudibleMixes(mixes)) {
      return null;
    }
    final rawIntensity = normalizedIntensityForMagnitude(
      sample.magnitude,
      sensitivity: sensitivity,
    );
    _smoothedIntensity = _smoothedIntensity * 0.5 + rawIntensity * 0.5;
    final intensity = math
        .max(rawIntensity, _smoothedIntensity * 0.88)
        .clamp(0.0, 1.0)
        .toDouble();
    if (intensity < 0.08) return null;

    final directionCode = _dominantDirectionCode(sample);
    if (directionCode == 0) return null;
    if (_lastDirectionCode == 0) {
      _lastDirectionCode = directionCode;
      return null;
    }
    if (directionCode == _lastDirectionCode) {
      return null;
    }
    _lastDirectionCode = directionCode;

    final previousChange = _lastDirectionChangeAt;
    _lastDirectionChangeAt = sample.timestamp;
    var tempoBpm = _allegroTempoBpm;
    if (previousChange != null) {
      final intervalMs = sample.timestamp
          .difference(previousChange)
          .inMilliseconds
          .clamp(120, 900);
      final measuredBpm = (60000 / intervalMs).clamp(68.0, 220.0).toDouble();
      tempoBpm = _allegroTempoBpm * 0.56 + measuredBpm * 0.44;
      _allegroTempoBpm = tempoBpm;
    }

    final beatCooldown = Duration(
      milliseconds: (60000 / tempoBpm * 0.28).round().clamp(82, 280),
    );
    final previousTrigger = _lastTriggerAt;
    if (previousTrigger != null &&
        sample.timestamp.difference(previousTrigger) < beatCooldown) {
      return null;
    }
    _lastTriggerAt = sample.timestamp;

    final band = intensity >= 0.62
        ? ToolboxFreeChimeIntensityBand.strong
        : ToolboxFreeChimeIntensityBand.lively;
    return _buildTrigger(
      timestamp: sample.timestamp,
      magnitude: sample.magnitude,
      intensity: intensity,
      band: band,
      axisBias: sample.axisBias,
      mixes: mixes,
      allegroBeat: true,
      tempoBpm: tempoBpm,
    );
  }

  ToolboxFreeChimeTrigger _buildTrigger({
    required DateTime timestamp,
    required double magnitude,
    required double intensity,
    required ToolboxFreeChimeIntensityBand band,
    required double axisBias,
    required Iterable<ToolboxFreeChimeLayerMix> mixes,
    bool allegroBeat = false,
    double? tempoBpm,
    double motionAccent = 0,
    double collisionAccent = 0,
    double swingSpeedAccent = 0,
  }) {
    final activeMixes = mixes
        .where((mix) => mix.amount > 0.02)
        .toList(growable: false);
    if (activeMixes.isEmpty) {
      return ToolboxFreeChimeTrigger(
        timestamp: timestamp,
        band: ToolboxFreeChimeIntensityBand.idle,
        intensity: 0,
        magnitude: 0,
        hits: const <ToolboxFreeChimeHit>[],
        tempoBpm: tempoBpm,
      );
    }
    final sourceMixes = activeMixes;
    final soft = sourceMixes
        .where((mix) => !mix.layer.isRhythmic)
        .toList(growable: false);
    final rhythmic = sourceMixes
        .where((mix) => mix.layer.isRhythmic)
        .toList(growable: false);
    final kuaiban = rhythmic
        .where((mix) => mix.layer == ToolboxFreeChimeLayer.kuaiban)
        .toList(growable: false);
    final rhythmWithoutKuaiban = rhythmic
        .where((mix) => mix.layer != ToolboxFreeChimeLayer.kuaiban)
        .toList(growable: false);

    final selected = <ToolboxFreeChimeLayerMix>[];
    if (allegroBeat) {
      selected.addAll(_pick(kuaiban, 1));
      selected.addAll(
        _pick(
          rhythmWithoutKuaiban.isEmpty
              ? (rhythmic.isEmpty ? sourceMixes : rhythmic)
              : rhythmWithoutKuaiban,
          1,
        ),
      );
      selected.addAll(_pick(soft, 1));
    } else {
      switch (band) {
        case ToolboxFreeChimeIntensityBand.idle:
          break;
        case ToolboxFreeChimeIntensityBand.gentle:
          selected.addAll(_pick(soft.isEmpty ? sourceMixes : soft, 1));
          break;
        case ToolboxFreeChimeIntensityBand.flowing:
          selected.addAll(_pick(soft.isEmpty ? sourceMixes : soft, 2));
          break;
        case ToolboxFreeChimeIntensityBand.lively:
          selected.addAll(_pick(soft.isEmpty ? sourceMixes : soft, 2));
          selected.addAll(
            _pick(
              rhythmic.isEmpty && collisionAccent > 0.26
                  ? sourceMixes
                  : rhythmic,
              1,
            ),
          );
          break;
        case ToolboxFreeChimeIntensityBand.strong:
          selected.addAll(
            _pick(
              rhythmic.isEmpty && collisionAccent > 0.26
                  ? sourceMixes
                  : rhythmic,
              2,
            ),
          );
          selected.addAll(_pick(soft.isEmpty ? sourceMixes : soft, 2));
          break;
      }
    }
    if (selected.isEmpty) {
      selected.addAll(_pick(sourceMixes, 1));
    }

    final hitLimit = allegroBeat
        ? 3
        : switch (band) {
            ToolboxFreeChimeIntensityBand.strong => 4,
            ToolboxFreeChimeIntensityBand.lively => 3,
            _ => 2,
          };
    final cappedSelected = selected.take(hitLimit).toList(growable: false);
    final hits = <ToolboxFreeChimeHit>[];
    for (var i = 0; i < cappedSelected.length; i += 1) {
      final mix = cappedSelected[i];
      final layerBias = _layerVolumeBias(mix.layer);
      final bandBias = _bandVolumeBias(band);
      final amount = mix.amount.clamp(0.0, 1.0).toDouble();
      final collisionLayerBoost =
          collisionAccent > 0 &&
              (mix.layer.isRhythmic ||
                  mix.layer == ToolboxFreeChimeLayer.windChime)
          ? 1 + collisionAccent * 0.22
          : 1.0;
      final volume =
          amount *
          layerBias *
          bandBias *
          collisionLayerBoost *
          (0.56 +
                  intensity * 0.4 +
                  motionAccent * 0.08 +
                  swingSpeedAccent * 0.14 +
                  collisionAccent * 0.08)
              .clamp(0.0, 1.14);
      final variant =
          (_sequence +
              i * 3 +
              (magnitude * 2).round() +
              (motionAccent * 5).round()) %
          8;
      final rateJitter = (variant - 3.5) * 0.006;
      final tempoRate = tempoBpm == null
          ? 0.0
          : ((tempoBpm - 120) / 220).clamp(-0.12, 0.28).toDouble();
      final playbackRate =
          (0.965 +
                  intensity * 0.052 +
                  axisBias * 0.026 +
                  motionAccent * 0.018 +
                  collisionAccent * 0.028 +
                  swingSpeedAccent * 0.036 +
                  tempoRate +
                  rateJitter)
              .clamp(0.92, 1.1)
              .toDouble();
      hits.add(
        ToolboxFreeChimeHit(
          layer: mix.layer,
          volume: volume.clamp(0.0, 1.0).toDouble(),
          playbackRate: playbackRate,
          variant: variant,
          pan: axisBias,
        ),
      );
    }
    _sequence = (_sequence + 1) % 1024;
    return ToolboxFreeChimeTrigger(
      timestamp: timestamp,
      band: band,
      intensity: intensity,
      magnitude: magnitude,
      hits: hits,
      tempoBpm: tempoBpm,
    );
  }

  bool _hasAudibleMixes(Iterable<ToolboxFreeChimeLayerMix> mixes) {
    for (final mix in mixes) {
      if (mix.amount > 0.02) {
        return true;
      }
    }
    return false;
  }

  int _dominantDirectionCode(ToolboxFreeChimeMotionSample sample) {
    final ax = sample.x.abs();
    final ay = sample.y.abs();
    final az = sample.z.abs();
    if (ax < 0.18 && ay < 0.18 && az < 0.18) {
      return 0;
    }
    if (ax >= ay && ax >= az) {
      return sample.x >= 0 ? 1 : -1;
    }
    if (ay >= ax && ay >= az) {
      return sample.y >= 0 ? 2 : -2;
    }
    return sample.z >= 0 ? 3 : -3;
  }

  double _motionDelta(
    ToolboxFreeChimeMotionSample sample,
    ToolboxFreeChimeMotionSample? previous,
  ) {
    if (previous == null) {
      return 0;
    }
    final dx = sample.x - previous.x;
    final dy = sample.y - previous.y;
    final dz = sample.z - previous.z;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  double _swingSpeedAccent(
    ToolboxFreeChimeMotionSample sample,
    ToolboxFreeChimeMotionSample? previous,
  ) {
    if (previous == null) {
      return 0;
    }
    final elapsedMs = sample.timestamp
        .difference(previous.timestamp)
        .inMilliseconds;
    if (elapsedMs <= 0) {
      return 0;
    }
    final seconds = elapsedMs / 1000;
    final swingSpeed = _motionDelta(sample, previous) / seconds;
    return (swingSpeed / 112).clamp(0.0, 1.0).toDouble();
  }

  double _quickTurnAccent(DateTime timestamp, DateTime previousTurnAt) {
    final intervalMs = timestamp
        .difference(previousTurnAt)
        .inMilliseconds
        .clamp(55, 420);
    return ((420 - intervalMs) / 365).clamp(0.0, 1.0).toDouble();
  }

  List<ToolboxFreeChimeLayerMix> _pick(
    List<ToolboxFreeChimeLayerMix> candidates,
    int count,
  ) {
    if (count <= 0 || candidates.isEmpty) {
      return const <ToolboxFreeChimeLayerMix>[];
    }
    final selected = <ToolboxFreeChimeLayerMix>[];
    final start = _sequence % candidates.length;
    for (var offset = 0; offset < candidates.length; offset += 1) {
      if (selected.length >= count) break;
      selected.add(candidates[(start + offset) % candidates.length]);
    }
    return selected;
  }

  ToolboxFreeChimeIntensityBand _bandForIntensity(double intensity) {
    if (intensity < 0.06) return ToolboxFreeChimeIntensityBand.idle;
    if (intensity < 0.22) return ToolboxFreeChimeIntensityBand.gentle;
    if (intensity < 0.48) return ToolboxFreeChimeIntensityBand.flowing;
    if (intensity < 0.72) return ToolboxFreeChimeIntensityBand.lively;
    return ToolboxFreeChimeIntensityBand.strong;
  }

  Duration _cooldownFor(ToolboxFreeChimeIntensityBand band) {
    return switch (band) {
      ToolboxFreeChimeIntensityBand.idle => const Duration(milliseconds: 680),
      ToolboxFreeChimeIntensityBand.gentle => const Duration(milliseconds: 520),
      ToolboxFreeChimeIntensityBand.flowing => const Duration(
        milliseconds: 330,
      ),
      ToolboxFreeChimeIntensityBand.lively => const Duration(milliseconds: 210),
      ToolboxFreeChimeIntensityBand.strong => const Duration(milliseconds: 130),
    };
  }

  Duration _directionChangeCooldownFor(ToolboxFreeChimeIntensityBand band) {
    return switch (band) {
      ToolboxFreeChimeIntensityBand.idle => const Duration(milliseconds: 420),
      ToolboxFreeChimeIntensityBand.gentle => const Duration(milliseconds: 240),
      ToolboxFreeChimeIntensityBand.flowing => const Duration(
        milliseconds: 170,
      ),
      ToolboxFreeChimeIntensityBand.lively => const Duration(milliseconds: 105),
      ToolboxFreeChimeIntensityBand.strong => const Duration(milliseconds: 80),
    };
  }

  Duration _dynamicCooldownFor(
    ToolboxFreeChimeIntensityBand band, {
    required bool directionChanged,
    required double motionAccent,
    required double swingSpeedAccent,
    required double quickTurnAccent,
  }) {
    final base = directionChanged
        ? _directionChangeCooldownFor(band)
        : _cooldownFor(band);
    final reduction = directionChanged
        ? (swingSpeedAccent * 0.36 +
                  quickTurnAccent * 0.2 +
                  motionAccent * 0.16)
              .clamp(0.0, 0.46)
              .toDouble()
        : (swingSpeedAccent * 0.16).clamp(0.0, 0.18).toDouble();
    final minimumMs = directionChanged
        ? switch (band) {
            ToolboxFreeChimeIntensityBand.idle => 240,
            ToolboxFreeChimeIntensityBand.gentle => 128,
            ToolboxFreeChimeIntensityBand.flowing => 92,
            ToolboxFreeChimeIntensityBand.lively => 62,
            ToolboxFreeChimeIntensityBand.strong => 58,
          }
        : switch (band) {
            ToolboxFreeChimeIntensityBand.idle => 560,
            ToolboxFreeChimeIntensityBand.gentle => 420,
            ToolboxFreeChimeIntensityBand.flowing => 270,
            ToolboxFreeChimeIntensityBand.lively => 170,
            ToolboxFreeChimeIntensityBand.strong => 105,
          };
    final milliseconds = math.max(
      minimumMs,
      (base.inMilliseconds * (1 - reduction)).round(),
    );
    return Duration(milliseconds: milliseconds);
  }

  double _bandVolumeBias(ToolboxFreeChimeIntensityBand band) {
    return switch (band) {
      ToolboxFreeChimeIntensityBand.idle => 0,
      ToolboxFreeChimeIntensityBand.gentle => 0.46,
      ToolboxFreeChimeIntensityBand.flowing => 0.58,
      ToolboxFreeChimeIntensityBand.lively => 0.76,
      ToolboxFreeChimeIntensityBand.strong => 0.95,
    };
  }

  double _layerVolumeBias(ToolboxFreeChimeLayer layer) {
    return switch (layer) {
      ToolboxFreeChimeLayer.shaker => 0.78,
      ToolboxFreeChimeLayer.water => 0.64,
      ToolboxFreeChimeLayer.windChime => 0.72,
      ToolboxFreeChimeLayer.leaves => 0.52,
      ToolboxFreeChimeLayer.bubbles => 0.58,
      ToolboxFreeChimeLayer.rain => 0.5,
      ToolboxFreeChimeLayer.impact => 0.78,
      ToolboxFreeChimeLayer.kuaiban => 0.88,
      ToolboxFreeChimeLayer.gongDrum => 0.86,
      ToolboxFreeChimeLayer.marble => 0.68,
    };
  }
}

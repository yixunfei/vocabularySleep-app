import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import 'audio_player_source_helper.dart';

enum ZenSandSoundKind { rake, finger, water, shovel, gravel, smooth, stone }

class ToolboxZenSandSoundService {
  ToolboxZenSandSoundService() {
    unawaited(_loopPlayer.setReleaseMode(ReleaseMode.loop));
    for (final player in _impactPlayers) {
      unawaited(player.setReleaseMode(ReleaseMode.stop));
    }
  }

  final AudioPlayer _loopPlayer = AudioPlayer();
  final List<AudioPlayer> _impactPlayers = List<AudioPlayer>.generate(
    3,
    (_) => AudioPlayer(),
    growable: false,
  );
  final Map<String, Uint8List> _loopCache = <String, Uint8List>{};
  final Map<String, Uint8List> _impactCache = <String, Uint8List>{};

  String? _activeLoopCacheKey;
  ZenSandSoundKind? _activeLoopKind;
  bool _loopRunning = false;
  int _loopToken = 0;
  int _impactToken = 0;
  DateTime _lastImpactAt = DateTime.fromMillisecondsSinceEpoch(0);
  int _impactPlayerCursor = 0;
  Timer? _loopStopTimer;
  Timer? _queuedLoopVolumeTimer;
  double? _queuedLoopVolume;
  double _lastLoopVolume = 0;
  DateTime _lastLoopVolumeAt = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> dispose() async {
    _cancelLoopStop();
    _cancelQueuedLoopVolume();
    await stopLoop(immediate: true);
    for (final player in _impactPlayers) {
      await player.dispose();
    }
    await _loopPlayer.dispose();
  }

  Future<void> startLoop(
    ZenSandSoundKind kind, {
    required double brushSize,
    double intensity = 0.7,
  }) async {
    if (kind == ZenSandSoundKind.stone) {
      tap(kind, brushSize: brushSize, intensity: intensity);
      return;
    }
    final normalizedBrush = brushSize.clamp(14.0, 96.0).toDouble();
    final normalizedIntensity = intensity.clamp(0.0, 1.0).toDouble();
    final cacheKey = _loopCacheKey(kind, normalizedBrush);
    final wavBytes = _loopCache.putIfAbsent(
      cacheKey,
      () => _buildLoopWav(kind: kind, brushSize: normalizedBrush),
    );
    final token = ++_loopToken;
    _cancelLoopStop();
    try {
      await _loopPlayer.setReleaseMode(ReleaseMode.loop);
      if (_activeLoopCacheKey != cacheKey) {
        _cancelQueuedLoopVolume();
        _queuedLoopVolume = null;
        await _loopPlayer.stop();
        await AudioPlayerSourceHelper.setSource(
          _loopPlayer,
          BytesSource(wavBytes, mimeType: 'audio/wav'),
          tag: 'zen_sand_sfx_loop',
          data: <String, Object?>{
            'kind': kind.name,
            'bytes': wavBytes.length,
            'cacheKey': cacheKey,
          },
        );
        _activeLoopCacheKey = cacheKey;
      }
      if (token != _loopToken) {
        return;
      }
      final targetVolume = _loopVolumeFor(
        kind,
        brushSize: normalizedBrush,
        intensity: normalizedIntensity,
      );
      await _setLoopVolumeImmediate(targetVolume);
      if (!_loopRunning || _activeLoopKind != kind) {
        await _loopPlayer.resume();
      }
      _activeLoopKind = kind;
      _loopRunning = true;
    } catch (_) {}
  }

  Future<void> updateLoop(
    ZenSandSoundKind kind, {
    required double brushSize,
    double intensity = 0.7,
  }) async {
    _cancelLoopStop();
    if (!_loopRunning || _activeLoopKind != kind) {
      await startLoop(kind, brushSize: brushSize, intensity: intensity);
      return;
    }
    _queueLoopVolume(
      _loopVolumeFor(
        kind,
        brushSize: brushSize.clamp(14.0, 96.0).toDouble(),
        intensity: intensity.clamp(0.0, 1.0).toDouble(),
      ),
    );
  }

  Future<void> stopLoop({bool immediate = false}) async {
    if (immediate) {
      _loopToken += 1;
      _cancelLoopStop();
      _cancelQueuedLoopVolume();
      _activeLoopKind = null;
      _loopRunning = false;
      try {
        await _loopPlayer.pause();
      } catch (_) {}
      return;
    }
    if (!_loopRunning) {
      return;
    }
    _cancelLoopStop();
    _loopStopTimer = Timer(
      const Duration(milliseconds: 140),
      () => unawaited(_pauseLoopSoft()),
    );
  }

  void tap(
    ZenSandSoundKind kind, {
    required double brushSize,
    double intensity = 0.75,
  }) {
    final now = DateTime.now();
    if (now.difference(_lastImpactAt) < _minTapGapFor(kind)) {
      return;
    }
    _lastImpactAt = now;
    final normalizedBrush = brushSize.clamp(14.0, 96.0).toDouble();
    final normalizedIntensity = intensity.clamp(0.0, 1.0).toDouble();
    final cacheKey = _impactCacheKey(
      kind,
      normalizedBrush,
      normalizedIntensity,
    );
    final wavBytes = _impactCache.putIfAbsent(
      cacheKey,
      () => _buildImpactWav(
        kind: kind,
        brushSize: normalizedBrush,
        intensity: normalizedIntensity,
      ),
    );
    final token = ++_impactToken;
    unawaited(
      _playImpactBytes(
        kind,
        wavBytes,
        volume: _impactVolumeFor(
          kind,
          brushSize: normalizedBrush,
          intensity: normalizedIntensity,
        ),
        token: token,
      ),
    );
  }

  String _loopCacheKey(ZenSandSoundKind kind, double brushSize) {
    final brushBucket = ((brushSize - 14.0) / 10).round().clamp(0, 8);
    return 'loop:${kind.name}:$brushBucket';
  }

  String _impactCacheKey(
    ZenSandSoundKind kind,
    double brushSize,
    double intensity,
  ) {
    final brushBucket = ((brushSize - 14.0) / 10).round().clamp(0, 8);
    final intensityBucket = (intensity * 10).round().clamp(0, 10);
    return 'impact:${kind.name}:$brushBucket:$intensityBucket';
  }

  Duration _minTapGapFor(ZenSandSoundKind kind) {
    return switch (kind) {
      ZenSandSoundKind.rake => const Duration(milliseconds: 84),
      ZenSandSoundKind.finger => const Duration(milliseconds: 96),
      ZenSandSoundKind.water => const Duration(milliseconds: 138),
      ZenSandSoundKind.shovel => const Duration(milliseconds: 92),
      ZenSandSoundKind.gravel => const Duration(milliseconds: 70),
      ZenSandSoundKind.smooth => const Duration(milliseconds: 126),
      ZenSandSoundKind.stone => const Duration(milliseconds: 92),
    };
  }

  double _loopVolumeFor(
    ZenSandSoundKind kind, {
    required double brushSize,
    required double intensity,
  }) {
    final brushFactor = ((brushSize - 14.0) / 82.0).clamp(0.0, 1.0);
    final base = switch (kind) {
      ZenSandSoundKind.rake => 0.17,
      ZenSandSoundKind.finger => 0.13,
      ZenSandSoundKind.water => 0.18,
      ZenSandSoundKind.shovel => 0.19,
      ZenSandSoundKind.gravel => 0.16,
      ZenSandSoundKind.smooth => 0.11,
      ZenSandSoundKind.stone => 0.18,
    };
    return (base + brushFactor * 0.05 + intensity * 0.08)
        .clamp(0.06, 0.3)
        .toDouble();
  }

  double _impactVolumeFor(
    ZenSandSoundKind kind, {
    required double brushSize,
    required double intensity,
  }) {
    final brushFactor = ((brushSize - 14.0) / 82.0).clamp(0.0, 1.0);
    final base = switch (kind) {
      ZenSandSoundKind.stone => 0.24,
      ZenSandSoundKind.smooth => 0.12,
      ZenSandSoundKind.water => 0.13,
      ZenSandSoundKind.finger => 0.12,
      _ => 0.15,
    };
    return (base + brushFactor * 0.04 + intensity * 0.05)
        .clamp(0.08, 0.28)
        .toDouble();
  }

  void _cancelLoopStop() {
    _loopStopTimer?.cancel();
    _loopStopTimer = null;
  }

  void _cancelQueuedLoopVolume() {
    _queuedLoopVolumeTimer?.cancel();
    _queuedLoopVolumeTimer = null;
    _queuedLoopVolume = null;
  }

  Future<void> _pauseLoopSoft() async {
    _loopStopTimer = null;
    _loopRunning = false;
    _queuedLoopVolume = null;
    _cancelQueuedLoopVolume();
    try {
      if (_lastLoopVolume > 0.02) {
        final fadedVolume = (_lastLoopVolume * 0.45).clamp(0.0, 1.0).toDouble();
        await _loopPlayer.setVolume(fadedVolume);
        _lastLoopVolume = fadedVolume;
        _lastLoopVolumeAt = DateTime.now();
      }
      await _loopPlayer.pause();
    } catch (_) {}
  }

  void _queueLoopVolume(double volume) {
    final clamped = volume.clamp(0.0, 1.0).toDouble();
    _queuedLoopVolume = clamped;
    if (_queuedLoopVolumeTimer != null) {
      return;
    }
    final elapsed = DateTime.now().difference(_lastLoopVolumeAt);
    final delay = elapsed >= const Duration(milliseconds: 42)
        ? Duration.zero
        : const Duration(milliseconds: 42) - elapsed;
    _queuedLoopVolumeTimer = Timer(delay, () {
      _queuedLoopVolumeTimer = null;
      final nextVolume = _queuedLoopVolume;
      _queuedLoopVolume = null;
      if (nextVolume == null) {
        return;
      }
      unawaited(_setLoopVolumeImmediate(nextVolume));
    });
  }

  Future<void> _setLoopVolumeImmediate(double volume) async {
    final clamped = volume.clamp(0.0, 1.0).toDouble();
    if ((clamped - _lastLoopVolume).abs() < 0.012) {
      return;
    }
    try {
      await _loopPlayer.setVolume(clamped);
      _lastLoopVolume = clamped;
      _lastLoopVolumeAt = DateTime.now();
    } catch (_) {}
  }

  AudioPlayer _takeImpactPlayer() {
    final player = _impactPlayers[_impactPlayerCursor];
    _impactPlayerCursor = (_impactPlayerCursor + 1) % _impactPlayers.length;
    return player;
  }

  Future<void> _playImpactBytes(
    ZenSandSoundKind kind,
    Uint8List wavBytes, {
    required double volume,
    required int token,
  }) async {
    final player = _takeImpactPlayer();
    try {
      await AudioPlayerSourceHelper.play(
        player,
        BytesSource(wavBytes, mimeType: 'audio/wav'),
        volume: volume,
        tag: 'zen_sand_sfx_impact',
        data: <String, Object?>{
          'kind': kind.name,
          'bytes': wavBytes.length,
          'token': token,
        },
      );
    } catch (_) {}
  }

  Uint8List _buildLoopWav({
    required ZenSandSoundKind kind,
    required double brushSize,
  }) {
    const sampleRate = 22050;
    const durationMs = 880;
    final sampleCount = (sampleRate * durationMs / 1000).round();
    final pcm = Int16List(sampleCount);
    final brushFactor = ((brushSize - 14.0) / 82.0).clamp(0.0, 1.0);

    for (var i = 0; i < sampleCount; i += 1) {
      final phase = i / sampleCount;
      final t = i / sampleRate;
      final hiss =
          math.sin(
                math.pi *
                    2 *
                    (47 * phase + 0.07 * math.sin(math.pi * 2 * 7 * phase)),
              ) *
              0.34 +
          math.sin(
                math.pi *
                    2 *
                    (83 * phase + 0.05 * math.sin(math.pi * 2 * 11 * phase)),
              ) *
              0.24 +
          math.sin(
                math.pi *
                    2 *
                    (121 * phase + 0.04 * math.cos(math.pi * 2 * 5 * phase)),
              ) *
              0.14;
      final rustle =
          math.sin(
                math.pi *
                    2 *
                    (59 * phase + 0.09 * math.sin(math.pi * 2 * 4 * t)),
              ) *
              0.24 +
          math.sin(
                math.pi *
                    2 *
                    (97 * phase + 0.05 * math.cos(math.pi * 2 * 6 * t)),
              ) *
              0.18;
      final grain =
          math.sin(math.pi * 2 * (9 + kind.index * 1.8) * phase + brushFactor) *
          0.22;
      final low =
          math.sin(math.pi * 2 * (1.6 + kind.index * 0.24) * phase + 0.4) *
          0.18;
      final shimmer =
          math.sin(
            math.pi *
                2 *
                (17 * phase + 0.08 * math.sin(math.pi * 2 * 3 * phase)),
          ) *
          0.18;
      final crackle =
          math.sin(math.pi * 2 * (137 * phase + 0.6)) * 0.12 +
          math.sin(math.pi * 2 * (181 * phase + brushFactor * 0.5)) * 0.06;
      final motion = math.sin(math.pi * 2 * (2.4 + brushFactor * 0.9) * t);
      final wash =
          math.sin(math.pi * 2 * (5.4 + brushFactor * 0.5) * t + 0.4) * 0.16 +
          math.cos(math.pi * 2 * (3.2 + kind.index * 0.24) * t) * 0.08;

      final sample = switch (kind) {
        ZenSandSoundKind.rake =>
          hiss * 0.66 +
              rustle * 0.28 +
              grain * 0.2 +
              low * 0.08 +
              crackle * 0.06 +
              motion * 0.06,
        ZenSandSoundKind.finger =>
          hiss * 0.34 +
              rustle * 0.2 +
              grain * 0.14 +
              low * 0.14 +
              shimmer * 0.08 +
              motion * 0.08,
        ZenSandSoundKind.water =>
          hiss * 0.18 +
              rustle * 0.08 +
              grain * 0.04 +
              low * 0.2 +
              shimmer * 0.26 +
              wash * 0.18 +
              motion * 0.14,
        ZenSandSoundKind.shovel =>
          hiss * 0.42 +
              rustle * 0.24 +
              grain * 0.22 +
              low * 0.22 +
              crackle * 0.08 +
              motion * 0.06,
        ZenSandSoundKind.gravel =>
          hiss * 0.34 +
              rustle * 0.12 +
              grain * 0.24 +
              crackle * 0.22 +
              low * 0.06,
        ZenSandSoundKind.smooth =>
          hiss * 0.18 +
              rustle * 0.08 +
              grain * 0.08 +
              low * 0.14 +
              shimmer * 0.16 +
              wash * 0.14,
        ZenSandSoundKind.stone => hiss * 0.2 + low * 0.2,
      };

      final loopWindow =
          0.92 +
          0.08 * math.sin(math.pi * 2 * phase) * math.sin(math.pi * 4 * phase);
      final shaped = sample * loopWindow * (0.48 + brushFactor * 0.1);
      pcm[i] = (shaped * 32767).round().clamp(-32768, 32767).toInt();
    }

    return _wrapPcmAsWav(pcm, sampleRate: sampleRate);
  }

  Uint8List _buildImpactWav({
    required ZenSandSoundKind kind,
    required double brushSize,
    required double intensity,
  }) {
    const sampleRate = 22050;
    final durationMs = switch (kind) {
      ZenSandSoundKind.rake => 120,
      ZenSandSoundKind.finger => 105,
      ZenSandSoundKind.water => 240,
      ZenSandSoundKind.shovel => 180,
      ZenSandSoundKind.gravel => 125,
      ZenSandSoundKind.stone => 130,
      ZenSandSoundKind.smooth => 160,
    };
    final sampleCount = (sampleRate * durationMs / 1000).round();
    final pcm = Int16List(sampleCount);
    final brushFactor = ((brushSize - 14.0) / 82.0).clamp(0.0, 1.0);
    final seed =
        kind.index * 157 + brushSize.round() * 23 + (intensity * 100).round();
    final random = math.Random(seed);

    for (var i = 0; i < sampleCount; i += 1) {
      final t = i / sampleRate;
      final progress = i / math.max(1, sampleCount - 1);
      final envelope = _impactEnvelope(kind, progress);
      final noise = random.nextDouble() * 2 - 1;
      final bass = math.sin(math.pi * 2 * (74 + brushFactor * 24) * t);
      final grit = math.sin(math.pi * 2 * (240 + brushFactor * 80) * t);
      final shimmer = math.sin(
        math.pi * 2 * (760 + intensity * 220 + brushFactor * 100) * t,
      );
      final click = math.sin(
        math.pi * 2 * (980 + intensity * 260 + brushFactor * 120) * t,
      );
      final chirpBase = switch (kind) {
        ZenSandSoundKind.water => 320.0,
        ZenSandSoundKind.smooth => 220.0,
        ZenSandSoundKind.stone => 180.0,
        _ => 260.0,
      };
      final chirp = math.sin(
        math.pi *
            2 *
            (chirpBase +
                intensity * 140 +
                brushFactor * 80 +
                (1 - progress) * 120) *
            t,
      );
      final rumble = math.sin(math.pi * 2 * (36 + brushFactor * 14) * t);

      final sample = switch (kind) {
        ZenSandSoundKind.stone =>
          bass * 0.3 + rumble * 0.18 + grit * 0.16 + click * 0.08 + noise * 0.1,
        ZenSandSoundKind.smooth =>
          noise * 0.12 + bass * 0.08 + shimmer * 0.12 + chirp * 0.08,
        ZenSandSoundKind.water =>
          noise * 0.08 +
              bass * 0.06 +
              shimmer * 0.18 +
              chirp * 0.18 +
              click * 0.06,
        ZenSandSoundKind.rake =>
          noise * 0.24 + bass * 0.08 + grit * 0.16 + click * 0.12,
        ZenSandSoundKind.finger =>
          noise * 0.16 + bass * 0.06 + grit * 0.1 + shimmer * 0.08,
        ZenSandSoundKind.shovel =>
          noise * 0.18 + bass * 0.22 + rumble * 0.16 + grit * 0.12,
        ZenSandSoundKind.gravel =>
          noise * 0.22 + grit * 0.12 + click * 0.16 + shimmer * 0.04,
      };

      final shaped =
          sample * envelope * (0.42 + intensity * 0.24 + brushFactor * 0.12);
      pcm[i] = (shaped * 32767).round().clamp(-32768, 32767).toInt();
    }

    return _wrapPcmAsWav(pcm, sampleRate: sampleRate);
  }

  double _impactEnvelope(ZenSandSoundKind kind, double progress) {
    final attack = switch (kind) {
      ZenSandSoundKind.stone => 0.03,
      ZenSandSoundKind.water => 0.12,
      ZenSandSoundKind.smooth => 0.08,
      ZenSandSoundKind.gravel => 0.04,
      _ => 0.05,
    };
    final release = switch (kind) {
      ZenSandSoundKind.water => 0.42,
      ZenSandSoundKind.smooth => 0.48,
      ZenSandSoundKind.stone => 0.62,
      ZenSandSoundKind.shovel => 0.34,
      ZenSandSoundKind.gravel => 0.22,
      _ => 0.28,
    };
    final attackGain = progress < attack ? progress / attack : 1.0;
    final releaseStart = (1.0 - release).clamp(0.0, 1.0);
    final releaseGain = progress <= releaseStart
        ? 1.0
        : ((1.0 - progress) / release).clamp(0.0, 1.0);
    return (attackGain * releaseGain).clamp(0.0, 1.0).toDouble();
  }

  Uint8List _wrapPcmAsWav(Int16List pcm, {required int sampleRate}) {
    final dataLength = pcm.length * 2;
    final byteRate = sampleRate * 2;
    final bytes = ByteData(44 + dataLength);

    void writeAscii(int offset, String value) {
      for (var i = 0; i < value.length; i += 1) {
        bytes.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    writeAscii(0, 'RIFF');
    bytes.setUint32(4, 36 + dataLength, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, 1, Endian.little);
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, byteRate, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    writeAscii(36, 'data');
    bytes.setUint32(40, dataLength, Endian.little);

    for (var i = 0; i < pcm.length; i += 1) {
      bytes.setInt16(44 + i * 2, pcm[i], Endian.little);
    }

    return bytes.buffer.asUint8List();
  }
}

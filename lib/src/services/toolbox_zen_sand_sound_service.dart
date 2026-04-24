import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'audio_player_source_helper.dart';
import 'app_log_service.dart';

enum ZenSandSoundKind { rake, finger, water, shovel, gravel, smooth, stone }

const int _zenSandLoopSampleRate = 22050;
const int _zenSandLoopDurationMs = 4800;

class ToolboxZenSandSoundService {
  ToolboxZenSandSoundService() {
    unawaited(_loopPlayer.setReleaseMode(ReleaseMode.loop));
    for (final player in _impactPlayers) {
      unawaited(player.setReleaseMode(ReleaseMode.stop));
    }
  }

  final AudioPlayer _loopPlayer = AudioPlayer();
  final AppLogService _log = AppLogService.instance;
  final List<AudioPlayer> _impactPlayers = List<AudioPlayer>.generate(
    3,
    (_) => AudioPlayer(),
    growable: false,
  );
  final List<String?> _impactPlayerCacheKeys = List<String?>.filled(
    3,
    null,
    growable: false,
  );
  final Map<String, Uint8List> _loopCache = <String, Uint8List>{};
  final Map<String, String> _loopFilePathCache = <String, String>{};
  final Map<String, Uint8List> _impactCache = <String, Uint8List>{};

  String? _activeLoopCacheKey;
  ZenSandSoundKind? _activeLoopKind;
  bool _loopRunning = false;
  int _loopToken = 0;
  int _impactToken = 0;
  int? _loopStartToken;
  String? _pendingLoopCacheKey;
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

  Future<void> prewarm(
    ZenSandSoundKind kind, {
    required double brushSize,
    double impactIntensity = 0.52,
  }) async {
    final normalizedBrush = brushSize.clamp(14.0, 96.0).toDouble();
    final normalizedImpact = impactIntensity.clamp(0.0, 1.0).toDouble();
    if (kind != ZenSandSoundKind.stone) {
      final loopCacheKey = _loopCacheKey(kind, normalizedBrush);
      final loopBytes = _loopCache.putIfAbsent(
        loopCacheKey,
        () => _buildLoopWav(kind: kind, brushSize: normalizedBrush),
      );
      await _cacheLoopTempFile(loopCacheKey, loopBytes);
      if (!_loopRunning || _activeLoopCacheKey == loopCacheKey) {
        try {
          await _ensureLoopSourcePrepared(
            kind,
            cacheKey: loopCacheKey,
            wavBytes: loopBytes,
          );
        } catch (_) {}
      }
    }
    await _preloadImpactSource(
      kind,
      brushSize: normalizedBrush,
      intensity: normalizedImpact,
    );
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
    await _cacheLoopTempFile(cacheKey, wavBytes);
    final token = ++_loopToken;
    _cancelLoopStop();
    _loopStartToken = token;
    _pendingLoopCacheKey = cacheKey;
    try {
      if (_activeLoopCacheKey != cacheKey) {
        await _ensureLoopSourcePrepared(
          kind,
          cacheKey: cacheKey,
          wavBytes: wavBytes,
        );
      } else {
        await _waitForLoopReady(cacheKey: cacheKey);
      }
      if (token != _loopToken) {
        return;
      }
      await _loopPlayer.setReleaseMode(ReleaseMode.loop);
      final targetVolume = _loopVolumeFor(
        kind,
        brushSize: normalizedBrush,
        intensity: normalizedIntensity,
      );
      await _setLoopVolumeImmediate(targetVolume);
      if (token != _loopToken) {
        return;
      }
      final shouldRestart =
          !_loopRunning ||
          _activeLoopKind != kind ||
          _loopPlayer.state != PlayerState.playing;
      if (shouldRestart) {
        await _resumeLoopPlayback(
          kind,
          cacheKey: cacheKey,
          wavBytes: wavBytes,
          token: token,
          reason: shouldRestart
              ? 'state=${_loopPlayer.state.name},running=$_loopRunning,activeKind=${_activeLoopKind?.name}'
              : 'startup',
        );
      }
      if (token != _loopToken) {
        return;
      }
      final started = await _waitForLoopPlaybackAdvance(token: token);
      if (!started) {
        _log.w(
          'zen_sand_sfx_loop',
          'loop playback failed to advance',
          data: <String, Object?>{
            'playerId': _loopPlayer.playerId,
            'kind': kind.name,
            'cacheKey': cacheKey,
            'state': _loopPlayer.state.name,
          },
        );
        _loopRunning = false;
        return;
      }
      _activeLoopKind = kind;
      _loopRunning = true;
    } catch (error, stackTrace) {
      _log.e(
        'zen_sand_sfx_loop',
        'startLoop failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'playerId': _loopPlayer.playerId,
          'kind': kind.name,
          'cacheKey': cacheKey,
        },
      );
    } finally {
      if (_loopStartToken == token) {
        _loopStartToken = null;
        if (_pendingLoopCacheKey == cacheKey) {
          _pendingLoopCacheKey = null;
        }
      }
    }
  }

  Future<void> updateLoop(
    ZenSandSoundKind kind, {
    required double brushSize,
    double intensity = 0.7,
  }) async {
    _cancelLoopStop();
    final normalizedBrush = brushSize.clamp(14.0, 96.0).toDouble();
    final cacheKey = _loopCacheKey(kind, normalizedBrush);
    if (_loopStartToken != null && _pendingLoopCacheKey == cacheKey) {
      _queueLoopVolume(
        _loopVolumeFor(
          kind,
          brushSize: normalizedBrush,
          intensity: intensity.clamp(0.0, 1.0).toDouble(),
        ),
      );
      return;
    }
    if (!_loopRunning ||
        _activeLoopKind != kind ||
        _loopPlayer.state != PlayerState.playing) {
      await startLoop(kind, brushSize: brushSize, intensity: intensity);
      return;
    }
    _queueLoopVolume(
      _loopVolumeFor(
        kind,
        brushSize: normalizedBrush,
        intensity: intensity.clamp(0.0, 1.0).toDouble(),
      ),
    );
  }

  Future<void> stopLoop({bool immediate = false}) async {
    if (immediate) {
      _loopToken += 1;
      _cancelLoopStop();
      _cancelQueuedLoopVolume();
      _loopStartToken = null;
      _pendingLoopCacheKey = null;
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
      const Duration(milliseconds: 420),
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
        cacheKey: cacheKey,
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
    final motion = intensity.clamp(0.0, 1.0).toDouble();
    if (motion <= 0.01) {
      return 0;
    }
    final brushFactor = ((brushSize - 14.0) / 82.0).clamp(0.0, 1.0);
    final base = switch (kind) {
      ZenSandSoundKind.rake => 0.13,
      ZenSandSoundKind.finger => 0.105,
      ZenSandSoundKind.water => 0.09,
      ZenSandSoundKind.shovel => 0.14,
      ZenSandSoundKind.gravel => 0.145,
      ZenSandSoundKind.smooth => 0.078,
      ZenSandSoundKind.stone => 0.08,
    };
    final volume = (base + brushFactor * 0.018) * (0.32 + motion * 0.82);
    return volume.clamp(0.0, 0.22).toDouble();
  }

  static ({double intensity, double speed, double smoothedSpeed})
  _sandMotionIntensityFor({
    required ZenSandSoundKind kind,
    required double distance,
    required double elapsedMs,
    required double previousSpeed,
    required double smoothedSpeed,
  }) {
    final safeElapsedMs = elapsedMs.clamp(8.0, 96.0).toDouble();
    final safeDistance = math.max(0.0, distance);
    final speed = safeDistance / safeElapsedMs;
    if (safeDistance < 0.65 || speed < 0.012) {
      return (intensity: 0, speed: speed, smoothedSpeed: smoothedSpeed * 0.54);
    }
    final nextSmoothedSpeed = smoothedSpeed <= 0
        ? speed
        : smoothedSpeed * 0.68 + speed * 0.32;
    final speedLevel = (nextSmoothedSpeed / 0.9).clamp(0.0, 1.0).toDouble();
    final accelerationLevel = ((speed - previousSpeed) / 0.55)
        .clamp(0.0, 1.0)
        .toDouble();
    final toolSensitivity = switch (kind) {
      ZenSandSoundKind.rake => 0.82,
      ZenSandSoundKind.finger => 0.74,
      ZenSandSoundKind.water => 0.56,
      ZenSandSoundKind.shovel => 0.86,
      ZenSandSoundKind.gravel => 0.9,
      ZenSandSoundKind.smooth => 0.5,
      ZenSandSoundKind.stone => 0.0,
    };
    final intensity =
        (0.1 + speedLevel * 0.36 + accelerationLevel * 0.1) * toolSensitivity;
    return (
      intensity: intensity.clamp(0.0, 0.58).toDouble(),
      speed: speed,
      smoothedSpeed: nextSmoothedSpeed,
    );
  }

  @visibleForTesting
  static ({double intensity, double speed, double smoothedSpeed})
  debugMotionIntensitySnapshot({
    required ZenSandSoundKind kind,
    required double distance,
    required double elapsedMs,
    required double previousSpeed,
    required double smoothedSpeed,
  }) {
    return _sandMotionIntensityFor(
      kind: kind,
      distance: distance,
      elapsedMs: elapsedMs,
      previousSpeed: previousSpeed,
      smoothedSpeed: smoothedSpeed,
    );
  }

  Future<void> setLoopMotion(
    ZenSandSoundKind kind, {
    required double brushSize,
    required double distance,
    required double elapsedMs,
    required double previousSpeed,
    required double smoothedSpeed,
    required void Function(double speed, double smoothedSpeed) onMotionState,
  }) async {
    final motion = _sandMotionIntensityFor(
      kind: kind,
      distance: distance,
      elapsedMs: elapsedMs,
      previousSpeed: previousSpeed,
      smoothedSpeed: smoothedSpeed,
    );
    onMotionState(motion.speed, motion.smoothedSpeed);
    await updateLoop(kind, brushSize: brushSize, intensity: motion.intensity);
  }

  Future<void> muteLoopMotion(
    ZenSandSoundKind kind, {
    required double brushSize,
  }) {
    return updateLoop(kind, brushSize: brushSize, intensity: 0);
  }

  @visibleForTesting
  static double debugSoftLoopVolumeFor(
    ZenSandSoundKind kind, {
    required double brushSize,
    required double intensity,
  }) {
    final brushFactor = ((brushSize.clamp(14.0, 96.0).toDouble() - 14.0) / 82.0)
        .clamp(0.0, 1.0);
    final motion = intensity.clamp(0.0, 1.0).toDouble();
    if (motion <= 0.01) {
      return 0;
    }
    final base = switch (kind) {
      ZenSandSoundKind.rake => 0.13,
      ZenSandSoundKind.finger => 0.105,
      ZenSandSoundKind.water => 0.09,
      ZenSandSoundKind.shovel => 0.14,
      ZenSandSoundKind.gravel => 0.145,
      ZenSandSoundKind.smooth => 0.078,
      ZenSandSoundKind.stone => 0.08,
    };
    return ((base + brushFactor * 0.018) * (0.32 + motion * 0.82))
        .clamp(0.0, 0.22)
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
      ZenSandSoundKind.smooth => 0.08,
      ZenSandSoundKind.water => 0.08,
      ZenSandSoundKind.finger => 0.07,
      _ => 0.09,
    };
    return (base + brushFactor * 0.02 + intensity * 0.03)
        .clamp(0.04, 0.24)
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
    _loopStartToken = null;
    _pendingLoopCacheKey = null;
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
    if (_loopRunning && (clamped - _lastLoopVolume).abs() < 0.012) {
      return;
    }
    try {
      await _loopPlayer.setVolume(clamped);
      _lastLoopVolume = clamped;
      _lastLoopVolumeAt = DateTime.now();
    } catch (_) {}
  }

  Future<void> _ensureLoopSourcePrepared(
    ZenSandSoundKind kind, {
    required String cacheKey,
    required Uint8List wavBytes,
    bool forceReload = false,
  }) async {
    if (!forceReload && _activeLoopCacheKey == cacheKey) {
      return;
    }
    _cancelQueuedLoopVolume();
    _queuedLoopVolume = null;
    await _loopPlayer.stop();
    final loopFilePath = await _cacheLoopTempFile(cacheKey, wavBytes);
    await AudioPlayerSourceHelper.setSource(
      _loopPlayer,
      DeviceFileSource(loopFilePath, mimeType: 'audio/wav'),
      tag: 'zen_sand_sfx_loop',
      data: <String, Object?>{
        'kind': kind.name,
        'bytes': wavBytes.length,
        'cacheKey': cacheKey,
        'path': loopFilePath,
        'preparedOnly': true,
      },
    );
    await _waitForLoopReady(cacheKey: cacheKey);
    _activeLoopCacheKey = cacheKey;
    _activeLoopKind = null;
    _loopRunning = false;
  }

  Future<void> _waitForLoopReady({required String cacheKey}) async {
    await AudioPlayerSourceHelper.waitForDuration(
      _loopPlayer,
      tag: 'zen_sand_sfx_loop',
      data: <String, Object?>{
        'playerId': _loopPlayer.playerId,
        'cacheKey': cacheKey,
        'waitFor': 'duration_before_resume',
      },
      timeout: const Duration(milliseconds: 420),
      pollInterval: const Duration(milliseconds: 42),
    );
  }

  Future<String> _cacheLoopTempFile(String cacheKey, Uint8List wavBytes) async {
    final cached = _loopFilePathCache[cacheKey];
    if (cached != null) {
      return cached;
    }
    final path = await AudioPlayerSourceHelper.tempFilePathForBytes(
      wavBytes,
      mimeType: 'audio/wav',
      data: <String, Object?>{
        'cacheKey': cacheKey,
        'sourcePath': '$cacheKey.wav',
      },
    );
    _loopFilePathCache[cacheKey] = path;
    return path;
  }

  Future<void> _resumeLoopPlayback(
    ZenSandSoundKind kind, {
    required String cacheKey,
    required Uint8List wavBytes,
    required int token,
    required String reason,
  }) async {
    try {
      await _loopPlayer.seek(Duration.zero);
    } catch (_) {}
    await _loopPlayer.resume();
    final started = await _waitForLoopPlaybackAdvance(token: token);
    if (started || token != _loopToken) {
      return;
    }
    _log.w(
      'zen_sand_sfx_loop',
      'loop playback stalled after resume, reloading source',
      data: <String, Object?>{
        'playerId': _loopPlayer.playerId,
        'kind': kind.name,
        'cacheKey': cacheKey,
        'reason': reason,
        'state': _loopPlayer.state.name,
      },
    );
    await _ensureLoopSourcePrepared(
      kind,
      cacheKey: cacheKey,
      wavBytes: wavBytes,
      forceReload: true,
    );
    if (token != _loopToken) {
      return;
    }
    await _loopPlayer.setReleaseMode(ReleaseMode.loop);
    try {
      await _loopPlayer.seek(Duration.zero);
    } catch (_) {}
    await _loopPlayer.resume();
  }

  Future<bool> _waitForLoopPlaybackAdvance({
    required int token,
    Duration timeout = const Duration(milliseconds: 260),
    Duration pollInterval = const Duration(milliseconds: 52),
    int minimumPositionMs = 0,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (token == _loopToken && DateTime.now().isBefore(deadline)) {
      final position = await _loopPlayer.getCurrentPosition();
      if (_loopPlayer.state == PlayerState.playing &&
          (position == null || position.inMilliseconds >= minimumPositionMs)) {
        return true;
      }
      await Future<void>.delayed(pollInterval);
    }
    if (token != _loopToken) {
      return false;
    }
    final finalPosition = await _loopPlayer.getCurrentPosition();
    return _loopPlayer.state == PlayerState.playing &&
        (finalPosition == null ||
            finalPosition.inMilliseconds >= minimumPositionMs);
  }

  Future<void> _preloadImpactSource(
    ZenSandSoundKind kind, {
    required double brushSize,
    required double intensity,
  }) async {
    final cacheKey = _impactCacheKey(kind, brushSize, intensity);
    if (_impactPlayerCacheKeys.first == cacheKey) {
      return;
    }
    final wavBytes = _impactCache.putIfAbsent(
      cacheKey,
      () => _buildImpactWav(
        kind: kind,
        brushSize: brushSize,
        intensity: intensity,
      ),
    );
    final player = _impactPlayers.first;
    try {
      await player.stop();
    } catch (_) {}
    try {
      await AudioPlayerSourceHelper.setSource(
        player,
        BytesSource(wavBytes, mimeType: 'audio/wav'),
        tag: 'zen_sand_sfx_impact',
        data: <String, Object?>{
          'kind': kind.name,
          'bytes': wavBytes.length,
          'cacheKey': cacheKey,
          'preparedOnly': true,
        },
      );
      _impactPlayerCacheKeys[0] = cacheKey;
      _impactPlayerCursor = 0;
    } catch (_) {}
  }

  int _takeImpactPlayerIndex() {
    final index = _impactPlayerCursor;
    _impactPlayerCursor = (_impactPlayerCursor + 1) % _impactPlayers.length;
    return index;
  }

  Future<void> _playImpactBytes(
    ZenSandSoundKind kind,
    Uint8List wavBytes, {
    required String cacheKey,
    required double volume,
    required int token,
  }) async {
    final playerIndex = _takeImpactPlayerIndex();
    final player = _impactPlayers[playerIndex];
    try {
      final clampedVolume = volume.clamp(0.0, 1.0).toDouble();
      await player.setVolume(clampedVolume);
      if (_impactPlayerCacheKeys[playerIndex] == cacheKey) {
        final reused = await _restartLoadedImpact(player);
        if (reused) {
          return;
        }
      }
      try {
        await player.stop();
      } catch (_) {}
      await AudioPlayerSourceHelper.setSource(
        player,
        BytesSource(wavBytes, mimeType: 'audio/wav'),
        tag: 'zen_sand_sfx_impact',
        data: <String, Object?>{
          'kind': kind.name,
          'bytes': wavBytes.length,
          'token': token,
          'cacheKey': cacheKey,
        },
      );
      _impactPlayerCacheKeys[playerIndex] = cacheKey;
      await player.resume();
    } catch (_) {}
  }

  Future<bool> _restartLoadedImpact(AudioPlayer player) async {
    try {
      await player.seek(Duration.zero);
      await player.resume();
      return true;
    } catch (_) {
      return false;
    }
  }

  Uint8List _buildLoopWav({
    required ZenSandSoundKind kind,
    required double brushSize,
  }) {
    final modernPcm = _tryBuildModernZenSandLoopPcm(
      kind: kind,
      brushSize: brushSize,
    );
    if (modernPcm != null) {
      return _wrapPcmAsWav(modernPcm, sampleRate: _zenSandLoopSampleRate);
    }
    const sampleRate = 22050;
    const durationMs = 3200;
    final sampleCount = (sampleRate * durationMs / 1000).round();
    final pcm = Int16List(sampleCount);
    final brushFactor = ((brushSize - 14.0) / 82.0).clamp(0.0, 1.0);

    // [风险] 这段合成原先混用了 `phase`（0→1 循环）与 `t`（绝对秒）两套自变量，
    // 在 phase=1 处以 `t` 为参数的波形不会闭合，叠加的 loopWindow 还在 phase
    // 的四个相位点周期性压 8% 音量，体感上表现为"一笔绘制时隔一会儿就掉一下"。
    // 现改为全 `phase` 基、整数频率倍数，保证周期严格首尾闭合；loopWindow 去除。
    for (var i = 0; i < sampleCount; i += 1) {
      final phase = i / sampleCount;
      final tau = math.pi * 2 * phase;
      final hiss =
          math.sin(tau * 47 + 0.07 * math.sin(tau * 7)) * 0.34 +
          math.sin(tau * 83 + 0.05 * math.sin(tau * 11)) * 0.24 +
          math.sin(tau * 121 + 0.04 * math.cos(tau * 5)) * 0.14;
      final rustle =
          math.sin(tau * 59 + 0.09 * math.sin(tau * 4)) * 0.24 +
          math.sin(tau * 97 + 0.05 * math.cos(tau * 6)) * 0.18;
      final grain = math.sin(tau * (9 + kind.index * 2) + brushFactor) * 0.22;
      final low = math.sin(tau * (2 + kind.index) + 0.4) * 0.18;
      final shimmer = math.sin(tau * 17 + 0.08 * math.sin(tau * 3)) * 0.18;
      final crackle =
          math.sin(tau * 137 + 0.6) * 0.12 +
          math.sin(tau * 181 + brushFactor * 0.5) * 0.06;
      // motion/wash 用整数倍 phase 周期，避免相位跳变；节奏与原 `t` 基相似。
      final motion = math.sin(tau * (8 + (brushFactor * 3).round()));
      final wash =
          math.sin(tau * 18 + 0.4) * 0.16 +
          math.cos(tau * (10 + kind.index)) * 0.08;

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

      final shaped = sample * (0.48 + brushFactor * 0.1);
      pcm[i] = (shaped * 32767).round().clamp(-32768, 32767).toInt();
    }
    // 保险带：即便所有分量都是 phase 整周期，轻量拼接也能吞掉浮点误差。
    _seamBlendLoopPcm(pcm, sampleRate: sampleRate, blendMs: 48);

    return _wrapPcmAsWav(pcm, sampleRate: sampleRate);
  }

  void _seamBlendLoopPcm(
    Int16List pcm, {
    required int sampleRate,
    int blendMs = 96,
  }) {
    if (pcm.length < 8) {
      return;
    }
    final rawBlendSamples = ((sampleRate * blendMs) / 1000).round();
    final blendSamples = rawBlendSamples.clamp(8, pcm.length ~/ 2);
    if (blendSamples <= 1) {
      return;
    }

    for (var i = 0; i < blendSamples; i += 1) {
      final tailIndex = pcm.length - blendSamples + i;
      final head = pcm[i] / 32768.0;
      final tail = pcm[tailIndex] / 32768.0;
      final t = i / (blendSamples - 1);
      final blended = tail * (1.0 - t) + head * t;
      final sample = (blended * 32767).round().clamp(-32768, 32767).toInt();
      pcm[i] = sample;
      pcm[tailIndex] = sample;
    }

    pcm[pcm.length - 1] = pcm[0];
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

Int16List? _tryBuildModernZenSandLoopPcm({
  required ZenSandSoundKind kind,
  required double brushSize,
}) {
  try {
    final sampleCount = (_zenSandLoopSampleRate * _zenSandLoopDurationMs / 1000)
        .round();
    final pcm = Int16List(sampleCount);
    final brushFactor = ((brushSize - 14.0) / 82.0).clamp(0.0, 1.0).toDouble();
    final brushBucket = ((brushSize - 14.0) / 10).round().clamp(0, 8).toInt();
    final random = math.Random(0x5EED + kind.index * 997 + brushBucket * 131);
    final profile = _zenSandLoopProfileFor(kind);
    final grainSpacing = (64 - profile.grainDensity * 38 - brushFactor * 10)
        .round()
        .clamp(14, 72)
        .toInt();

    var midBand = 0.0;
    var slowBand = 0.0;
    var fineBand = 0.0;
    var airSmooth = 0.0;
    var bodySmooth = 0.0;
    var pressure = 0.72 + random.nextDouble() * 0.08;
    var grainBurst = 0.0;
    var grainSign = 1.0;

    for (var i = 0; i < sampleCount; i += 1) {
      final phase = i / sampleCount;
      final white = random.nextDouble() * 2 - 1;
      final air = random.nextDouble() * 2 - 1;
      final body = random.nextDouble() * 2 - 1;

      pressure += (random.nextDouble() - 0.5) * 0.006;
      pressure = pressure.clamp(0.58, 0.92).toDouble();

      // Sand should sound like material friction, not a pitched synth. This is
      // a light offline version of the reference WebAudio approach: smoothed
      // random grains through a broad mid band, with tiny transient particles.
      midBand += (white - midBand) * profile.midAlpha;
      slowBand += (white - slowBand) * profile.slowAlpha;
      fineBand += (white - fineBand) * profile.fineAlpha;
      airSmooth += (air - airSmooth) * profile.airAlpha;
      bodySmooth += (body - bodySmooth) * profile.bodyAlpha;

      if (i % grainSpacing == 0 && random.nextDouble() < profile.grainDensity) {
        grainBurst += 0.16 + random.nextDouble() * 0.22;
        grainSign = random.nextBool() ? 1.0 : -1.0;
      }
      grainBurst *= profile.grainDecay;

      final contact = (midBand - slowBand) * profile.contact;
      final dryEdge = (fineBand - midBand) * profile.dryEdge;
      final softAir = (air - airSmooth) * profile.air;
      final bodyRub = bodySmooth * profile.body;
      final grains = grainBurst * grainSign * profile.grain;
      final handMotion =
          0.82 +
          0.1 * math.sin(math.pi * 2 * (phase * 1.0 + profile.phase)) +
          0.04 * math.sin(math.pi * 2 * (phase * 3.0 + brushFactor));
      final sample =
          (contact + dryEdge + softAir + bodyRub + grains) *
          pressure *
          handMotion *
          profile.gain *
          (0.82 + brushFactor * 0.18);
      final softened = sample / (1.0 + sample.abs() * 0.72);
      pcm[i] = (softened * 32767).round().clamp(-32768, 32767).toInt();
    }

    _blendZenSandLoopEdges(pcm, sampleRate: _zenSandLoopSampleRate);
    _normalizeZenSandLoopPcm(pcm, targetPeak: profile.targetPeak);
    return pcm;
  } catch (_) {
    return null;
  }
}

class _ZenSandLoopProfile {
  const _ZenSandLoopProfile({
    required this.contact,
    required this.dryEdge,
    required this.air,
    required this.body,
    required this.grain,
    required this.grainDensity,
    required this.grainDecay,
    required this.midAlpha,
    required this.slowAlpha,
    required this.fineAlpha,
    required this.airAlpha,
    required this.bodyAlpha,
    required this.gain,
    required this.phase,
    required this.targetPeak,
  });

  final double contact;
  final double dryEdge;
  final double air;
  final double body;
  final double grain;
  final double grainDensity;
  final double grainDecay;
  final double midAlpha;
  final double slowAlpha;
  final double fineAlpha;
  final double airAlpha;
  final double bodyAlpha;
  final double gain;
  final double phase;
  final double targetPeak;
}

_ZenSandLoopProfile _zenSandLoopProfileFor(ZenSandSoundKind kind) {
  return switch (kind) {
    ZenSandSoundKind.rake => const _ZenSandLoopProfile(
      contact: 1.08,
      dryEdge: 0.42,
      air: 0.1,
      body: 0.08,
      grain: 0.24,
      grainDensity: 0.82,
      grainDecay: 0.86,
      midAlpha: 0.12,
      slowAlpha: 0.018,
      fineAlpha: 0.44,
      airAlpha: 0.08,
      bodyAlpha: 0.01,
      gain: 0.33,
      phase: 0.2,
      targetPeak: 0.42,
    ),
    ZenSandSoundKind.finger => const _ZenSandLoopProfile(
      contact: 0.92,
      dryEdge: 0.22,
      air: 0.08,
      body: 0.16,
      grain: 0.14,
      grainDensity: 0.52,
      grainDecay: 0.89,
      midAlpha: 0.095,
      slowAlpha: 0.014,
      fineAlpha: 0.34,
      airAlpha: 0.065,
      bodyAlpha: 0.008,
      gain: 0.34,
      phase: 0.7,
      targetPeak: 0.36,
    ),
    ZenSandSoundKind.water => const _ZenSandLoopProfile(
      contact: 0.62,
      dryEdge: 0.12,
      air: 0.18,
      body: 0.2,
      grain: 0.08,
      grainDensity: 0.34,
      grainDecay: 0.92,
      midAlpha: 0.07,
      slowAlpha: 0.012,
      fineAlpha: 0.22,
      airAlpha: 0.04,
      bodyAlpha: 0.006,
      gain: 0.32,
      phase: 1.1,
      targetPeak: 0.34,
    ),
    ZenSandSoundKind.shovel => const _ZenSandLoopProfile(
      contact: 1.14,
      dryEdge: 0.32,
      air: 0.08,
      body: 0.26,
      grain: 0.18,
      grainDensity: 0.58,
      grainDecay: 0.88,
      midAlpha: 0.085,
      slowAlpha: 0.012,
      fineAlpha: 0.3,
      airAlpha: 0.055,
      bodyAlpha: 0.007,
      gain: 0.37,
      phase: 1.6,
      targetPeak: 0.4,
    ),
    ZenSandSoundKind.gravel => const _ZenSandLoopProfile(
      contact: 0.88,
      dryEdge: 0.48,
      air: 0.12,
      body: 0.06,
      grain: 0.36,
      grainDensity: 0.9,
      grainDecay: 0.82,
      midAlpha: 0.13,
      slowAlpha: 0.02,
      fineAlpha: 0.5,
      airAlpha: 0.09,
      bodyAlpha: 0.012,
      gain: 0.34,
      phase: 2.2,
      targetPeak: 0.44,
    ),
    ZenSandSoundKind.smooth => const _ZenSandLoopProfile(
      contact: 0.72,
      dryEdge: 0.1,
      air: 0.08,
      body: 0.22,
      grain: 0.06,
      grainDensity: 0.24,
      grainDecay: 0.93,
      midAlpha: 0.06,
      slowAlpha: 0.01,
      fineAlpha: 0.2,
      airAlpha: 0.04,
      bodyAlpha: 0.006,
      gain: 0.3,
      phase: 2.8,
      targetPeak: 0.3,
    ),
    ZenSandSoundKind.stone => const _ZenSandLoopProfile(
      contact: 0.38,
      dryEdge: 0.08,
      air: 0.04,
      body: 0.28,
      grain: 0.04,
      grainDensity: 0.12,
      grainDecay: 0.94,
      midAlpha: 0.045,
      slowAlpha: 0.008,
      fineAlpha: 0.16,
      airAlpha: 0.035,
      bodyAlpha: 0.004,
      gain: 0.26,
      phase: 3.1,
      targetPeak: 0.24,
    ),
  };
}

void _blendZenSandLoopEdges(
  Int16List pcm, {
  required int sampleRate,
  int blendMs = 96,
}) {
  if (pcm.length < 16) {
    return;
  }
  final blendSamples = ((sampleRate * blendMs) / 1000)
      .round()
      .clamp(8, pcm.length ~/ 2)
      .toInt();
  for (var i = 0; i < blendSamples; i += 1) {
    final tailIndex = pcm.length - blendSamples + i;
    final t = i / (blendSamples - 1);
    final fade = t * t * (3 - 2 * t);
    final head = pcm[i] / 32768.0;
    final tail = pcm[tailIndex] / 32768.0;
    final blended = tail * (1 - fade) + head * fade;
    final sample = (blended * 32767).round().clamp(-32768, 32767).toInt();
    pcm[i] = sample;
    pcm[tailIndex] = sample;
  }
  pcm[pcm.length - 1] = pcm[0];
}

void _normalizeZenSandLoopPcm(Int16List pcm, {required double targetPeak}) {
  var peak = 0;
  for (final sample in pcm) {
    peak = math.max(peak, sample.abs());
  }
  if (peak <= 0) {
    return;
  }
  final scale = (targetPeak * 32767 / peak).clamp(0.1, 2.2).toDouble();
  for (var i = 0; i < pcm.length; i += 1) {
    pcm[i] = (pcm[i] * scale).round().clamp(-32768, 32767).toInt();
  }
}

@immutable
class ZenSandWaveformSnapshot {
  const ZenSandWaveformSnapshot({
    required this.sampleRate,
    required this.durationMs,
    required this.rms,
    required this.peak,
    required this.minWindowRms,
    required this.maxWindowRms,
    required this.leadingQuietMs,
    required this.trailingQuietMs,
    required this.longestQuietMs,
    required this.zeroCrossingRate,
  });

  final int sampleRate;
  final double durationMs;
  final double rms;
  final double peak;
  final double minWindowRms;
  final double maxWindowRms;
  final double leadingQuietMs;
  final double trailingQuietMs;
  final double longestQuietMs;
  final double zeroCrossingRate;
}

@visibleForTesting
abstract final class ZenSandSoundDebug {
  static ZenSandWaveformSnapshot analyzeLoop(
    ZenSandSoundKind kind, {
    double brushSize = 32,
  }) {
    return _analyzeZenSandWaveform(
      _buildDebugZenSandLoopWav(kind: kind, brushSize: brushSize),
    );
  }

  static ZenSandWaveformSnapshot analyzeImpact(
    ZenSandSoundKind kind, {
    double brushSize = 32,
    double intensity = 0.52,
  }) {
    return _analyzeZenSandWaveform(
      _buildDebugZenSandImpactWav(
        kind: kind,
        brushSize: brushSize,
        intensity: intensity,
      ),
    );
  }
}

Uint8List _buildDebugZenSandLoopWav({
  required ZenSandSoundKind kind,
  required double brushSize,
}) {
  final modernPcm = _tryBuildModernZenSandLoopPcm(
    kind: kind,
    brushSize: brushSize,
  );
  if (modernPcm != null) {
    return _wrapDebugZenSandPcmAsWav(
      modernPcm,
      sampleRate: _zenSandLoopSampleRate,
    );
  }
  const sampleRate = 22050;
  const durationMs = 3200;
  final sampleCount = (sampleRate * durationMs / 1000).round();
  final pcm = Int16List(sampleCount);
  final brushFactor = ((brushSize - 14.0) / 82.0).clamp(0.0, 1.0);

  for (var i = 0; i < sampleCount; i += 1) {
    final phase = i / sampleCount;
    final tau = math.pi * 2 * phase;
    final hiss =
        math.sin(tau * 47 + 0.07 * math.sin(tau * 7)) * 0.34 +
        math.sin(tau * 83 + 0.05 * math.sin(tau * 11)) * 0.24 +
        math.sin(tau * 121 + 0.04 * math.cos(tau * 5)) * 0.14;
    final rustle =
        math.sin(tau * 59 + 0.09 * math.sin(tau * 4)) * 0.24 +
        math.sin(tau * 97 + 0.05 * math.cos(tau * 6)) * 0.18;
    final grain = math.sin(tau * (9 + kind.index * 2) + brushFactor) * 0.22;
    final low = math.sin(tau * (2 + kind.index) + 0.4) * 0.18;
    final shimmer = math.sin(tau * 17 + 0.08 * math.sin(tau * 3)) * 0.18;
    final crackle =
        math.sin(tau * 137 + 0.6) * 0.12 +
        math.sin(tau * 181 + brushFactor * 0.5) * 0.06;
    final motion = math.sin(tau * (8 + (brushFactor * 3).round()));
    final wash =
        math.sin(tau * 18 + 0.4) * 0.16 +
        math.cos(tau * (10 + kind.index)) * 0.08;

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

    final shaped = sample * (0.48 + brushFactor * 0.1);
    pcm[i] = (shaped * 32767).round().clamp(-32768, 32767).toInt();
  }

  _seamBlendDebugZenSandLoopPcm(pcm, sampleRate: sampleRate, blendMs: 48);
  return _wrapDebugZenSandPcmAsWav(pcm, sampleRate: sampleRate);
}

void _seamBlendDebugZenSandLoopPcm(
  Int16List pcm, {
  required int sampleRate,
  int blendMs = 96,
}) {
  if (pcm.length < 8) {
    return;
  }
  final rawBlendSamples = ((sampleRate * blendMs) / 1000).round();
  final blendSamples = rawBlendSamples.clamp(8, pcm.length ~/ 2);
  if (blendSamples <= 1) {
    return;
  }

  for (var i = 0; i < blendSamples; i += 1) {
    final tailIndex = pcm.length - blendSamples + i;
    final head = pcm[i] / 32768.0;
    final tail = pcm[tailIndex] / 32768.0;
    final t = i / (blendSamples - 1);
    final blended = tail * (1.0 - t) + head * t;
    final sample = (blended * 32767).round().clamp(-32768, 32767).toInt();
    pcm[i] = sample;
    pcm[tailIndex] = sample;
  }

  pcm[pcm.length - 1] = pcm[0];
}

Uint8List _buildDebugZenSandImpactWav({
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
    final envelope = _debugZenSandImpactEnvelope(kind, progress);
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

  return _wrapDebugZenSandPcmAsWav(pcm, sampleRate: sampleRate);
}

double _debugZenSandImpactEnvelope(ZenSandSoundKind kind, double progress) {
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

Uint8List _wrapDebugZenSandPcmAsWav(Int16List pcm, {required int sampleRate}) {
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

ZenSandWaveformSnapshot _analyzeZenSandWaveform(Uint8List wavBytes) {
  final data = ByteData.sublistView(wavBytes);
  final sampleRate = data.getUint32(24, Endian.little);
  final sampleCount = data.getUint32(40, Endian.little) ~/ 2;
  final samples = List<double>.generate(sampleCount, (index) {
    return data.getInt16(44 + index * 2, Endian.little) / 32768.0;
  }, growable: false);
  final rms = _debugZenSandRms(samples);
  final peak = samples.fold<double>(
    0,
    (current, value) => math.max(current, value.abs()),
  );
  var crossings = 0;
  for (var index = 1; index < samples.length; index += 1) {
    final previous = samples[index - 1];
    final current = samples[index];
    if ((previous < 0 && current >= 0) || (previous >= 0 && current < 0)) {
      crossings += 1;
    }
  }
  final windowSamples = math.max(1, (sampleRate * 0.02).round());
  final windowRms = <double>[];
  for (var start = 0; start < samples.length; start += windowSamples) {
    final end = math.min(start + windowSamples, samples.length);
    windowRms.add(_debugZenSandRms(samples.sublist(start, end)));
  }
  final quietThreshold = math.max(0.0025, rms * 0.18);
  final windowMs = windowSamples * 1000 / sampleRate;
  final leadingQuietMs =
      _debugZenSandEdgeQuietWindowCount(windowRms, quietThreshold) * windowMs;
  final trailingQuietMs =
      _debugZenSandEdgeQuietWindowCount(
        windowRms.reversed.toList(growable: false),
        quietThreshold,
      ) *
      windowMs;
  final longestQuietMs =
      _debugZenSandLongestQuietWindowCount(windowRms, quietThreshold) *
      windowMs;

  return ZenSandWaveformSnapshot(
    sampleRate: sampleRate,
    durationMs: samples.length * 1000 / sampleRate,
    rms: rms,
    peak: peak,
    minWindowRms: windowRms.isEmpty
        ? 0
        : windowRms.reduce((left, right) => math.min(left, right)),
    maxWindowRms: windowRms.isEmpty
        ? 0
        : windowRms.reduce((left, right) => math.max(left, right)),
    leadingQuietMs: leadingQuietMs,
    trailingQuietMs: trailingQuietMs,
    longestQuietMs: longestQuietMs,
    zeroCrossingRate: samples.length <= 1 ? 0 : crossings / samples.length,
  );
}

double _debugZenSandRms(List<double> samples) {
  if (samples.isEmpty) {
    return 0;
  }
  var sum = 0.0;
  for (final sample in samples) {
    sum += sample * sample;
  }
  return math.sqrt(sum / samples.length);
}

int _debugZenSandEdgeQuietWindowCount(List<double> windows, double threshold) {
  var count = 0;
  for (final value in windows) {
    if (value > threshold) {
      break;
    }
    count += 1;
  }
  return count;
}

int _debugZenSandLongestQuietWindowCount(
  List<double> windows,
  double threshold,
) {
  var longest = 0;
  var current = 0;
  for (final value in windows) {
    if (value <= threshold) {
      current += 1;
      if (current > longest) {
        longest = current;
      }
      continue;
    }
    current = 0;
  }
  return longest;
}

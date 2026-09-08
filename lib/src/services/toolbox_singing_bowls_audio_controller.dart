import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'toolbox_audio_service.dart';

/// Coordinates generated bowl tones without allowing stale builds or native
/// player commands to race one another.
class ToolboxSingingBowlsAudioController {
  ToolboxSingingBowlsAudioController({
    this.variantIds = const <int>[0, 1],
    this.maxVoicesPerVariant = 2,
    this.volumeJitter = 0.012,
  }) : assert(variantIds.isNotEmpty),
       assert(maxVoicesPerVariant >= 1);

  final List<int> variantIds;
  final int maxVoicesPerVariant;
  final double volumeJitter;

  final _SingingBowlOperationLock _operationLock = _SingingBowlOperationLock();
  final math.Random _random = math.Random();
  ToolboxRealisticEffectPlayer? _activePlayer;
  _SingingBowlTarget? _pendingTarget;
  Completer<bool>? _pendingResult;
  Future<void>? _buildLoopFuture;
  int _generation = 0;
  bool _playQueued = false;
  bool _disposed = false;

  bool get hasReadyTone => _activePlayer != null;

  /// Requests the latest tone. A superseded request completes with `false`.
  Future<bool> setTone({required double frequency, required String style}) {
    if (_disposed) {
      return Future<bool>.value(false);
    }
    _generation += 1;
    _pendingTarget = _SingingBowlTarget(frequency: frequency, style: style);
    final previousResult = _pendingResult;
    if (previousResult != null && !previousResult.isCompleted) {
      previousResult.complete(false);
    }
    final result = Completer<bool>();
    _pendingResult = result;
    _ensureBuildLoop();
    return result.future;
  }

  Future<void> play({required double baseVolume}) async {
    if (_disposed || _playQueued) {
      return;
    }
    _playQueued = true;
    try {
      await _operationLock.synchronized(() async {
        final player = _activePlayer;
        if (_disposed || player == null) {
          return;
        }
        final playbackRate = 0.994 + _random.nextDouble() * 0.012;
        await player.play(baseVolume: baseVolume, playbackRate: playbackRate);
      });
    } finally {
      _playQueued = false;
    }
  }

  Future<void> stop() async {
    await _operationLock.synchronized(() async {
      try {
        await _activePlayer?.stop();
      } catch (_) {}
    });
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _generation += 1;
    _pendingTarget = null;
    final pendingResult = _pendingResult;
    _pendingResult = null;
    if (pendingResult != null && !pendingResult.isCompleted) {
      pendingResult.complete(false);
    }

    final buildLoop = _buildLoopFuture;
    if (buildLoop != null) {
      try {
        await buildLoop;
      } catch (_) {}
    }
    await _operationLock.synchronized(() async {
      final player = _activePlayer;
      _activePlayer = null;
      if (player == null) {
        return;
      }
      try {
        await player.stop();
      } catch (_) {}
      try {
        await player.dispose();
      } catch (_) {}
    });
  }

  void _ensureBuildLoop() {
    if (_buildLoopFuture != null || _disposed) {
      return;
    }
    final future = _runBuildLoop();
    _buildLoopFuture = future;
    future.then<void>(
      (_) {
        _finishBuildLoop(future);
      },
      onError: (Object error, StackTrace stackTrace) {
        _finishBuildLoop(future);
      },
    );
  }

  void _finishBuildLoop(Future<void> future) {
    if (!identical(_buildLoopFuture, future)) {
      return;
    }
    _buildLoopFuture = null;
    if (!_disposed && _pendingTarget != null) {
      _ensureBuildLoop();
    }
  }

  Future<void> _runBuildLoop() async {
    while (!_disposed) {
      final target = _pendingTarget;
      if (target == null) {
        return;
      }
      _pendingTarget = null;
      final generation = _generation;
      ToolboxRealisticEffectPlayer? candidate;
      try {
        candidate = await _buildPlayer(target, generation);
      } catch (_) {
        candidate = null;
      }

      if (candidate == null) {
        if (!_disposed && generation == _generation) {
          _completePending(false);
        }
        continue;
      }

      final installed = await _installPlayer(candidate, generation);
      if (!installed) {
        await candidate.dispose();
      } else if (!_disposed && generation == _generation) {
        _completePending(true);
      }
    }
  }

  Future<ToolboxRealisticEffectPlayer> _buildPlayer(
    _SingingBowlTarget target,
    int generation,
  ) async {
    final bytes = <Uint8List>[];
    for (final variant in variantIds) {
      if (!_isCurrentGeneration(generation)) {
        throw const _StaleSingingBowlBuild();
      }
      bytes.add(
        await ToolboxAudioBank.singingBowlToneAsync(
          frequency: target.frequency,
          style: target.style,
          variant: variant,
        ),
      );
    }
    if (!_isCurrentGeneration(generation)) {
      throw const _StaleSingingBowlBuild();
    }
    final player = ToolboxRealisticEffectPlayer(
      bytes,
      maxPlayers: maxVoicesPerVariant,
      volumeJitter: volumeJitter,
      allowOverflow: false,
    );
    try {
      final ready = await player.preload(voicesPerVariant: 1);
      if (!ready) {
        throw StateError('Singing bowl audio preload did not prepare a voice.');
      }
      return player;
    } catch (_) {
      await player.dispose();
      rethrow;
    }
  }

  bool _isCurrentGeneration(int generation) {
    return !_disposed && generation == _generation;
  }

  Future<bool> _installPlayer(
    ToolboxRealisticEffectPlayer candidate,
    int generation,
  ) async {
    var installed = false;
    await _operationLock.synchronized(() async {
      if (_disposed || generation != _generation) {
        return;
      }
      final previous = _activePlayer;
      _activePlayer = candidate;
      installed = true;
      if (previous == null) {
        return;
      }
      try {
        await previous.stop();
      } catch (_) {}
      try {
        await previous.dispose();
      } catch (_) {}
    });
    return installed;
  }

  void _completePending(bool value) {
    final result = _pendingResult;
    _pendingResult = null;
    if (result != null && !result.isCompleted) {
      result.complete(value);
    }
  }
}

class _SingingBowlTarget {
  const _SingingBowlTarget({required this.frequency, required this.style});

  final double frequency;
  final String style;
}

class _StaleSingingBowlBuild implements Exception {
  const _StaleSingingBowlBuild();
}

class _SingingBowlOperationLock {
  Future<void> _tail = Future<void>.value();

  Future<T> synchronized<T>(FutureOr<T> Function() operation) {
    final previous = _tail;
    final release = Completer<void>();
    _tail = release.future;
    return previous
        .then<void>((_) {}, onError: (Object error, StackTrace stackTrace) {})
        .then<T>((_) => operation())
        .whenComplete(() {
          if (!release.isCompleted) {
            release.complete();
          }
        });
  }
}

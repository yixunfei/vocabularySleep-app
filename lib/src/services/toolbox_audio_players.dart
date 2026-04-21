part of 'toolbox_audio_service.dart';

final AudioContext _toolboxAudioContext = AudioContextConfig(
  focus: AudioContextConfigFocus.mixWithOthers,
).build();

class ToolboxLoopController {
  final AudioPlayer _player = AudioPlayer();
  bool _audioContextConfigured = false;
  Uint8List? _activeBytes;
  String? _activePath;

  Future<void> _ensureAudioContext() async {
    if (_audioContextConfigured) return;
    await _player.setAudioContext(_toolboxAudioContext);
    _audioContextConfigured = true;
  }

  Future<void> play(
    Uint8List bytes, {
    double volume = 0.7,
    double playbackRate = 1.0,
  }) async {
    await _ensureAudioContext();
    if (!identical(_activeBytes, bytes)) {
      final sourcePath = await _ToolboxAudioTempStore.instance.pathFor(bytes);
      if (_activePath != sourcePath) {
        await AudioPlayerSourceHelper.setSource(
          _player,
          DeviceFileSource(sourcePath, mimeType: 'audio/wav'),
          tag: 'toolbox_loop_audio',
          data: <String, Object?>{
            'bytes': bytes.length,
            'playerId': _player.playerId,
          },
        );
        _activePath = sourcePath;
      }
      _activeBytes = bytes;
    }
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(volume.clamp(0.0, 1.0));
    await _player.setPlaybackRate(playbackRate.clamp(0.92, 1.08));
    await AudioPlayerSourceHelper.waitForDuration(
      _player,
      tag: 'toolbox_loop_audio',
      data: <String, Object?>{
        'bytes': bytes.length,
        'playerId': _player.playerId,
      },
      timeout: const Duration(seconds: 5),
    );
    await _player.resume();
  }

  Future<void> setVolume(double value) {
    return _player.setVolume(value.clamp(0.0, 1.0));
  }

  Future<void> setPlaybackRate(double value) {
    return _player.setPlaybackRate(value.clamp(0.92, 1.08));
  }

  Future<void> stop() => _player.stop();

  Future<void> dispose() => _player.dispose();
}

class ToolboxEffectPlayer {
  ToolboxEffectPlayer(this.bytes, {this.maxPlayers = 6});

  final Uint8List bytes;
  final int maxPlayers;
  final AppLogService _log = AppLogService.instance;

  final _ToolboxAsyncLock _voiceLock = _ToolboxAsyncLock();
  final List<_ToolboxReusableEffectVoice> _voices =
      <_ToolboxReusableEffectVoice>[];
  final Set<AudioPlayer> _overflowPlayers = <AudioPlayer>{};
  Future<String>? _sourcePathFuture;

  Future<void> play({double volume = 1.0, double playbackRate = 1.0}) async {
    try {
      final normalizedVolume = volume.clamp(0.0, 1.0);
      final normalizedPlaybackRate = playbackRate.clamp(0.92, 1.08);
      final sourcePath = await _ensureSourcePath();
      final voice = await _acquireVoice(sourcePath: sourcePath);
      if (voice != null) {
        await voice.play(
          volume: normalizedVolume,
          playbackRate: normalizedPlaybackRate,
        );
        return;
      }
      await _playOverflow(
        volume: normalizedVolume,
        playbackRate: normalizedPlaybackRate,
        sourcePath: sourcePath,
      );
    } catch (error, stackTrace) {
      _log.e(
        'toolbox_audio',
        'toolbox effect playback failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'bytes': bytes.length,
          'strategy': 'reusable_voice_pool',
        },
      );
    }
  }

  Future<void> warmUp() async {
    try {
      await _ensureSourcePath();
    } catch (error, stackTrace) {
      _log.w(
        'toolbox_audio',
        'toolbox effect warm-up skipped after failure',
        data: <String, Object?>{
          'error': '$error',
          'strategy': 'reusable_voice_pool',
        },
      );
      _log.e(
        'toolbox_audio',
        'toolbox effect warm-up detail',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'bytes': bytes.length,
          'strategy': 'reusable_voice_pool',
        },
      );
    }
  }

  Future<void> stop() async {
    final voices = _voices.toList(growable: false);
    for (final voice in voices) {
      await voice.stop();
    }
    final overflowPlayers = _overflowPlayers.toList(growable: false);
    for (final player in overflowPlayers) {
      try {
        await player.stop();
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    final voices = _voices.toList(growable: false);
    _voices.clear();
    for (final voice in voices) {
      await voice.dispose();
    }
    final overflowPlayers = _overflowPlayers.toList(growable: false);
    _overflowPlayers.clear();
    for (final player in overflowPlayers) {
      await player.dispose();
    }
  }

  Future<_ToolboxReusableEffectVoice?> _acquireVoice({
    required String sourcePath,
    bool allowOverflow = true,
  }) async {
    return _voiceLock.synchronized(() async {
      for (final voice in _voices) {
        if (!voice.isBusy) {
          voice.reserve();
          try {
            await voice.prepare(sourcePath);
            return voice;
          } catch (_) {
            voice.release();
            if (!allowOverflow) {
              rethrow;
            }
            return null;
          }
        }
      }
      if (_voices.length >= maxPlayers) {
        return null;
      }
      final created = _ToolboxReusableEffectVoice(bytes);
      _voices.add(created);
      created.reserve();
      try {
        await created.prepare(sourcePath);
        return created;
      } catch (_) {
        created.release();
        _voices.remove(created);
        await created.dispose();
        if (!allowOverflow) {
          rethrow;
        }
        return null;
      }
    });
  }

  Future<String> _ensureSourcePath() {
    final existing = _sourcePathFuture;
    if (existing != null) {
      return existing;
    }
    final future = _ToolboxAudioTempStore.instance.pathFor(bytes);
    _sourcePathFuture = future;
    return future;
  }

  Future<void> _playOverflow({
    required double volume,
    required double playbackRate,
    required String sourcePath,
  }) async {
    final player = AudioPlayer();
    _overflowPlayers.add(player);
    try {
      await player.setAudioContext(_toolboxAudioContext);
      await player.setReleaseMode(ReleaseMode.stop);
      await AudioPlayerSourceHelper.setSource(
        player,
        DeviceFileSource(sourcePath, mimeType: 'audio/wav'),
        tag: 'toolbox_audio',
        data: <String, Object?>{
          'bytes': bytes.length,
          'playerId': player.playerId,
          'path': sourcePath,
          'strategy': 'overflow',
        },
      );
      await player.setVolume(volume);
      await player.setPlaybackRate(playbackRate);
      await AudioPlayerSourceHelper.waitForDuration(
        player,
        tag: 'toolbox_audio',
        data: <String, Object?>{
          'bytes': bytes.length,
          'playerId': player.playerId,
          'path': sourcePath,
          'strategy': 'overflow',
        },
        timeout: const Duration(seconds: 5),
      );
      unawaited(
        _waitForPlayerCompletionOrTimeout(
          player,
        ).whenComplete(() => _disposeOverflowPlayer(player)),
      );
      await player.resume();
    } catch (_) {
      await _disposeOverflowPlayer(player);
      rethrow;
    }
  }

  Future<void> _disposeOverflowPlayer(AudioPlayer player) async {
    if (!_overflowPlayers.remove(player)) {
      return;
    }
    await player.dispose();
  }

  Future<void> _waitForPlayerCompletionOrTimeout(AudioPlayer player) async {
    final completer = Completer<void>();
    StreamSubscription<void>? subscription;
    Timer? timer;

    void complete() {
      if (completer.isCompleted) {
        return;
      }
      timer?.cancel();
      unawaited(subscription?.cancel() ?? Future<void>.value());
      completer.complete();
    }

    subscription = player.onPlayerComplete.listen(
      (_) => complete(),
      onError: (Object error, StackTrace stackTrace) => complete(),
      onDone: complete,
      cancelOnError: true,
    );
    timer = Timer(const Duration(seconds: 20), complete);
    return completer.future;
  }
}

/// Round-robin multi-variant effect player with light humanization.
class ToolboxRealisticEffectPlayer {
  ToolboxRealisticEffectPlayer(
    this.bytesVariants, {
    this.maxPlayers = 6,
    this.volumeJitter = 0.08,
  }) {
    assert(
      bytesVariants.isNotEmpty,
      'Must provide at least one audio variant.',
    );
    _players = bytesVariants
        .map((bytes) => ToolboxEffectPlayer(bytes, maxPlayers: maxPlayers))
        .toList(growable: false);
  }

  factory ToolboxRealisticEffectPlayer.build({
    required List<int> variants,
    required Uint8List Function(int variant) bytesForVariant,
    int maxPlayers = 6,
    double volumeJitter = 0.08,
  }) {
    assert(variants.isNotEmpty, 'Must provide at least one audio variant.');
    return ToolboxRealisticEffectPlayer(
      <Uint8List>[for (final variant in variants) bytesForVariant(variant)],
      maxPlayers: maxPlayers,
      volumeJitter: volumeJitter,
    );
  }

  final List<Uint8List> bytesVariants;
  final int maxPlayers;
  final double volumeJitter;

  late final List<ToolboxEffectPlayer> _players;
  final math.Random _random = math.Random();
  int _roundRobinIndex = 0;

  Future<void> play({
    double baseVolume = 1.0,
    double? volume,
    double playbackRate = 1.0,
  }) async {
    if (_players.isEmpty) {
      return;
    }
    final requestedVolume = (volume ?? baseVolume).clamp(0.0, 1.0).toDouble();
    final requestedPlaybackRate = playbackRate.clamp(0.92, 1.08).toDouble();
    final player = _players[_roundRobinIndex];
    _roundRobinIndex = (_roundRobinIndex + 1) % _players.length;

    final jitter = volumeJitter.clamp(0.0, 0.5).toDouble();
    final volumeScale = 1 + ((_random.nextDouble() * 2.0 - 1.0) * jitter);
    final finalVolume = (requestedVolume * volumeScale).clamp(0.0, 1.0);
    await player.play(
      volume: finalVolume.toDouble(),
      playbackRate: requestedPlaybackRate,
    );
  }

  Future<void> warmUp() async {
    await Future.wait<void>(_players.map((player) => player.warmUp()));
  }

  Future<void> stop() async {
    await Future.wait<void>(_players.map((player) => player.stop()));
  }

  Future<void> dispose() async {
    await Future.wait<void>(_players.map((player) => player.dispose()));
  }
}

class _ToolboxReusableEffectVoice {
  _ToolboxReusableEffectVoice(this.bytes);

  final Uint8List bytes;
  final AudioPlayer _player = AudioPlayer();
  bool _disposed = false;
  bool _busy = false;
  bool _prepared = false;
  String? _preparedPath;
  Future<void>? _prepareFuture;

  bool get isBusy => _busy;

  void reserve() {
    _busy = true;
  }

  void release() {
    _busy = false;
  }

  Future<void> prepare(String sourcePath) {
    final existing = _prepareFuture;
    if (existing != null) {
      return existing;
    }
    if (_prepared && _preparedPath == sourcePath) {
      return Future<void>.value();
    }
    final future = _doPrepare(sourcePath).whenComplete(() {
      _prepareFuture = null;
    });
    _prepareFuture = future;
    return future;
  }

  Future<void> play({
    required double volume,
    required double playbackRate,
  }) async {
    final preparedPath = _preparedPath;
    if (preparedPath == null) {
      throw StateError('Attempted to play an unprepared toolbox voice.');
    }
    await prepare(preparedPath);
    if (_disposed) {
      throw StateError('Attempted to play a disposed toolbox voice.');
    }
    try {
      await _player.setVolume(volume);
      await _player.setPlaybackRate(playbackRate);
      await AudioPlayerSourceHelper.waitForDuration(
        _player,
        tag: 'toolbox_audio',
        data: <String, Object?>{
          'playerId': _player.playerId,
          'path': preparedPath,
        },
        timeout: const Duration(seconds: 5),
      );
      unawaited(
        _waitForPlaybackEndOrTimeout().whenComplete(() async {
          release();
          if (_disposed) {
            return;
          }
          try {
            await _player.stop();
          } catch (_) {}
        }),
      );
      await _player.resume();
    } catch (_) {
      release();
      _prepared = false;
      _preparedPath = null;
      rethrow;
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    release();
    await _player.dispose();
  }

  Future<void> stop() async {
    if (_disposed) {
      return;
    }
    release();
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> _waitForPlaybackEndOrTimeout() async {
    final completer = Completer<void>();
    StreamSubscription<void>? subscription;
    Timer? timer;

    void complete() {
      if (completer.isCompleted) {
        return;
      }
      timer?.cancel();
      unawaited(subscription?.cancel() ?? Future<void>.value());
      completer.complete();
    }

    subscription = _player.onPlayerComplete.listen(
      (_) => complete(),
      onError: (Object error, StackTrace stackTrace) => complete(),
      onDone: complete,
      cancelOnError: true,
    );
    timer = Timer(const Duration(seconds: 20), complete);
    return completer.future;
  }

  Future<void> _doPrepare(String sourcePath) async {
    if (_disposed) {
      return;
    }
    await _player.setAudioContext(_toolboxAudioContext);
    await _player.setReleaseMode(ReleaseMode.stop);
    await AudioPlayerSourceHelper.setSource(
      _player,
      DeviceFileSource(sourcePath, mimeType: 'audio/wav'),
      tag: 'toolbox_audio',
      data: <String, Object?>{
        'bytes': bytes.length,
        'playerId': _player.playerId,
        'path': sourcePath,
        'strategy': 'voice_prepare',
      },
    );
    _prepared = true;
    _preparedPath = sourcePath;
  }
}

class _ToolboxAsyncLock {
  Future<void> _tail = Future<void>.value();

  Future<T> synchronized<T>(Future<T> Function() operation) {
    final previous = _tail;
    final release = Completer<void>();
    _tail = release.future;
    return previous.whenComplete(() {}).then((_) => operation()).whenComplete(
      () {
        if (!release.isCompleted) {
          release.complete();
        }
      },
    );
  }
}

class _ToolboxAudioTempStore {
  _ToolboxAudioTempStore._();

  static final _ToolboxAudioTempStore instance = _ToolboxAudioTempStore._();

  final Map<String, Future<String>> _pathFutures = <String, Future<String>>{};

  Future<String> pathFor(Uint8List bytes) {
    final digest = sha1.convert(bytes).toString();
    final existing = _pathFutures[digest];
    if (existing != null) {
      return existing;
    }
    final future = _writeBytes(digest, bytes);
    _pathFutures[digest] = future;
    return future.catchError((Object error) {
      _pathFutures.remove(digest);
      throw error;
    });
  }

  Future<String> _writeBytes(String digest, Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory(p.join(tempDir.path, 'toolbox_audio_cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    final file = File(p.join(cacheDir.path, '$digest.wav'));
    if (!await file.exists() || await file.length() != bytes.length) {
      await file.writeAsBytes(bytes, flush: true);
    }
    return file.path;
  }
}

part of 'toolbox_audio_service.dart';

abstract class ToolboxNotePlayer {
  Future<void> play({double volume = 1.0, double playbackRate = 1.0});
  Future<void> warmUp();
  Future<void> stop();
  Future<void> dispose();
}

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

class ToolboxEffectPlayer implements ToolboxNotePlayer {
  ToolboxEffectPlayer(
    this.bytes, {
    this.maxPlayers = 6,
    this.allowOverflow = true,
  });

  final Uint8List bytes;
  final int maxPlayers;
  final bool allowOverflow;
  final AppLogService _log = AppLogService.instance;

  final _ToolboxAsyncLock _voiceLock = _ToolboxAsyncLock();
  final List<_ToolboxReusableEffectVoice> _voices =
      <_ToolboxReusableEffectVoice>[];
  final Set<AudioPlayer> _overflowPlayers = <AudioPlayer>{};
  Future<String>? _sourcePathFuture;
  bool _disposed = false;

  @override
  Future<void> play({double volume = 1.0, double playbackRate = 1.0}) async {
    if (_disposed) {
      return;
    }
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
      if (_disposed || !allowOverflow) {
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
          'allowOverflow': allowOverflow,
        },
      );
    }
  }

  @override
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
          'allowOverflow': allowOverflow,
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
          'allowOverflow': allowOverflow,
        },
      );
    }
  }

  /// Prepares a bounded number of native voices before the first interaction.
  ///
  /// [warmUp] intentionally keeps its historical file-only behavior for other
  /// toolbox instruments. The bowl controller opts into this stronger form so
  /// the first strike does not pay MediaPlayer preparation latency.
  Future<bool> preload({int voices = 1}) async {
    if (_disposed) {
      return false;
    }
    var preparedAny = false;
    try {
      final sourcePath = await _ensureSourcePath();
      final count = voices.clamp(0, maxPlayers).toInt();
      for (var index = 0; index < count; index += 1) {
        if (_disposed) {
          return preparedAny;
        }
        final voice = await _acquireVoice(
          sourcePath: sourcePath,
          allowOverflow: false,
        );
        preparedAny = preparedAny || voice != null;
        voice?.release();
      }
    } catch (error, stackTrace) {
      _log.w(
        'toolbox_audio',
        'toolbox effect voice preload skipped after failure',
        data: <String, Object?>{
          'error': '$error',
          'strategy': 'bounded_voice_preload',
          'bytes': bytes.length,
        },
      );
      _log.e(
        'toolbox_audio',
        'toolbox effect voice preload detail',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'strategy': 'bounded_voice_preload',
          'bytes': bytes.length,
        },
      );
    }
    return preparedAny;
  }

  @override
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

  @override
  Future<void> dispose() async {
    _disposed = true;
    final voices = await _voiceLock.synchronized(() {
      final snapshot = _voices.toList(growable: false);
      _voices.clear();
      return snapshot;
    });
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
      if (_disposed) {
        return null;
      }
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
class ToolboxRealisticEffectPlayer implements ToolboxNotePlayer {
  ToolboxRealisticEffectPlayer(
    this.bytesVariants, {
    this.maxPlayers = 6,
    this.volumeJitter = 0.08,
    this.allowOverflow = true,
  }) {
    assert(
      bytesVariants.isNotEmpty,
      'Must provide at least one audio variant.',
    );
    _players = bytesVariants
        .map(
          (bytes) => ToolboxEffectPlayer(
            bytes,
            maxPlayers: maxPlayers,
            allowOverflow: allowOverflow,
          ),
        )
        .toList(growable: false);
  }

  factory ToolboxRealisticEffectPlayer.build({
    required List<int> variants,
    required Uint8List Function(int variant) bytesForVariant,
    int maxPlayers = 6,
    double volumeJitter = 0.08,
    bool allowOverflow = true,
  }) {
    assert(variants.isNotEmpty, 'Must provide at least one audio variant.');
    return ToolboxRealisticEffectPlayer(
      <Uint8List>[for (final variant in variants) bytesForVariant(variant)],
      maxPlayers: maxPlayers,
      volumeJitter: volumeJitter,
      allowOverflow: allowOverflow,
    );
  }

  final List<Uint8List> bytesVariants;
  final int maxPlayers;
  final double volumeJitter;
  final bool allowOverflow;

  late final List<ToolboxEffectPlayer> _players;
  final math.Random _random = math.Random();
  int _roundRobinIndex = 0;

  @override
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

  @override
  Future<void> warmUp() async {
    await Future.wait<void>(_players.map((player) => player.warmUp()));
  }

  Future<bool> preload({int voicesPerVariant = 1}) async {
    final count = voicesPerVariant.clamp(0, maxPlayers).toInt();
    final readiness = await Future.wait<bool>(
      _players.map((player) => player.preload(voices: count)),
    );
    return readiness.every((ready) => ready);
  }

  @override
  Future<void> stop() async {
    await Future.wait<void>(_players.map((player) => player.stop()));
  }

  @override
  Future<void> dispose() async {
    await Future.wait<void>(_players.map((player) => player.dispose()));
  }
}

class _ToolboxReusableEffectVoice {
  _ToolboxReusableEffectVoice(this.bytes);

  final Uint8List bytes;
  final AudioPlayer _player = AudioPlayer();
  final _ToolboxAsyncLock _commandLock = _ToolboxAsyncLock();
  bool _disposed = false;
  bool _busy = false;
  bool _prepared = false;
  String? _preparedPath;
  Future<void>? _prepareFuture;
  StreamSubscription<void>? _completionSubscription;
  Timer? _completionTimer;
  int _playbackGeneration = 0;

  bool get isBusy => _busy;

  void reserve() {
    _busy = true;
  }

  void release() {
    _busy = false;
  }

  Future<void> prepare(String sourcePath) {
    return _commandLock.synchronized(() => _prepareUnlocked(sourcePath));
  }

  Future<void> _prepareUnlocked(String sourcePath) {
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

  Future<void> play({required double volume, required double playbackRate}) {
    return _commandLock.synchronized(() async {
      final preparedPath = _preparedPath;
      if (preparedPath == null) {
        throw StateError('Attempted to play an unprepared toolbox voice.');
      }
      await _prepareUnlocked(preparedPath);
      if (_disposed) {
        throw StateError('Attempted to play a disposed toolbox voice.');
      }
      try {
        _invalidatePlaybackWatcher();
        final playbackGeneration = _playbackGeneration;
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
        _watchPlaybackEnd(playbackGeneration);
        await _player.resume();
      } catch (_) {
        _invalidatePlaybackWatcher();
        release();
        _prepared = false;
        _preparedPath = null;
        rethrow;
      }
    });
  }

  Future<void> dispose() {
    return _commandLock.synchronized(() async {
      if (_disposed) {
        return;
      }
      _disposed = true;
      _invalidatePlaybackWatcher();
      release();
      try {
        await _player.dispose();
      } catch (_) {}
    });
  }

  Future<void> stop() {
    return _commandLock.synchronized(() async {
      if (_disposed) {
        return;
      }
      _invalidatePlaybackWatcher();
      release();
      try {
        await _player.stop();
      } catch (_) {}
    });
  }

  Future<void> _finishPlayback(int playbackGeneration) {
    return _commandLock.synchronized(() async {
      if (playbackGeneration != _playbackGeneration) {
        return;
      }
      _invalidatePlaybackWatcher();
      release();
      if (_disposed) {
        return;
      }
      try {
        await _player.stop();
      } catch (_) {}
    });
  }

  void _watchPlaybackEnd(int playbackGeneration) {
    _completionSubscription = _player.onPlayerComplete.listen(
      (_) => unawaited(_finishPlayback(playbackGeneration)),
      onError: (Object error, StackTrace stackTrace) {
        unawaited(_finishPlayback(playbackGeneration));
      },
      onDone: () => unawaited(_finishPlayback(playbackGeneration)),
      cancelOnError: true,
    );
    _completionTimer = Timer(
      const Duration(seconds: 20),
      () => unawaited(_finishPlayback(playbackGeneration)),
    );
  }

  void _invalidatePlaybackWatcher() {
    _playbackGeneration += 1;
    _completionTimer?.cancel();
    _completionTimer = null;
    final subscription = _completionSubscription;
    _completionSubscription = null;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
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

class _ToolboxAudioTempStore {
  _ToolboxAudioTempStore._();

  static final _ToolboxAudioTempStore instance = _ToolboxAudioTempStore._();

  static const int _maxPathIndexEntries = 256;
  final LinkedHashMap<String, Future<String>> _pathFutures =
      LinkedHashMap<String, Future<String>>();

  Future<String> pathFor(Uint8List bytes) {
    final digest = sha1.convert(bytes).toString();
    final existing = _pathFutures.remove(digest);
    if (existing != null) {
      _pathFutures[digest] = existing;
      return existing;
    }
    final future = _writeBytes(digest, bytes);
    _pathFutures[digest] = future;
    while (_pathFutures.length > _maxPathIndexEntries) {
      _pathFutures.remove(_pathFutures.keys.first);
    }
    return future.catchError((Object error) {
      if (identical(_pathFutures[digest], future)) {
        _pathFutures.remove(digest);
      }
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

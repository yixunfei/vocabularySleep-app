import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'audio_player_source_helper.dart';
import 'app_log_service.dart';

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

  Future<void> play(Uint8List bytes, {double volume = 0.7}) async {
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

  Future<void> play({double volume = 1.0}) async {
    try {
      final normalizedVolume = volume.clamp(0.0, 1.0);
      final sourcePath = await _ensureSourcePath();
      final voice = await _acquireVoice(sourcePath: sourcePath);
      if (voice != null) {
        await voice.play(volume: normalizedVolume);
        return;
      }
      await _playOverflow(volume: normalizedVolume, sourcePath: sourcePath);
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

  Future<void> play({required double volume}) async {
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

class ToolboxAudioBank {
  ToolboxAudioBank._();

  static final Map<String, Uint8List> _cache = <String, Uint8List>{};

  static Uint8List soothingLoop(String presetId) {
    return _cache.putIfAbsent(
      'soothing:$presetId',
      () => _buildSoothingLoop(presetId),
    );
  }

  static Uint8List soothingSceneLoop(String sceneId) {
    return _cache.putIfAbsent(
      'scene:$sceneId',
      () => _buildSoothingSceneLoop(sceneId),
    );
  }

  static Uint8List harpNote(
    double frequency, {
    String style = 'silk',
    double reverb = 0.24,
  }) {
    final normalizedStyle = switch (style) {
      'warm' => 'warm',
      'crystal' => 'crystal',
      'bright' => 'bright',
      'nylon' => 'nylon',
      'glass' => 'glass',
      'concert' => 'concert',
      'steel' => 'steel',
      _ => 'silk',
    };
    final normalizedReverb = reverb.clamp(0.0, 0.8).toDouble();
    final key =
        'harp:${frequency.toStringAsFixed(2)}:$normalizedStyle:${normalizedReverb.toStringAsFixed(2)}';
    return _cache.putIfAbsent(
      key,
      () => _buildPluckNote(
        frequency: frequency,
        durationSeconds: 2.4,
        style: normalizedStyle,
        reverb: normalizedReverb,
      ),
    );
  }

  static Uint8List pianoNote(
    double frequency, {
    String style = 'concert',
    double reverb = 0.12,
    double decay = 1.0,
  }) {
    final normalizedStyle = switch (style) {
      'bright' => 'bright',
      'felt' => 'felt',
      'upright' => 'upright',
      _ => 'concert',
    };
    final normalizedReverb = (reverb.clamp(0.0, 0.55) * 20).round() / 20;
    final normalizedDecay = (decay.clamp(0.7, 1.8) * 20).round() / 20;
    final key =
        'piano:${frequency.toStringAsFixed(2)}:$normalizedStyle:'
        '${normalizedReverb.toStringAsFixed(2)}:'
        '${normalizedDecay.toStringAsFixed(2)}';
    return _cache.putIfAbsent(
      key,
      () => _buildPianoNote(
        frequency,
        normalizedStyle,
        reverb: normalizedReverb.toDouble(),
        decay: normalizedDecay.toDouble(),
      ),
    );
  }

  static Uint8List fluteNote(
    double frequency, {
    String style = 'airy',
    String material = 'wood',
    double breath = 0.6,
    double reverb = 0.22,
    double tail = 0.5,
    bool sustained = false,
  }) {
    final normalizedStyle = _normalizeFluteStyle(style);
    final normalizedMaterial = _normalizeFluteMaterial(material);
    final normalizedBreath = (breath.clamp(0.18, 1.0) * 20).round() / 20;
    final normalizedReverb = (reverb.clamp(0.0, 0.5) * 20).round() / 20;
    final normalizedTail = (tail.clamp(0.15, 1.0) * 20).round() / 20;
    final key =
        'flute:${frequency.toStringAsFixed(2)}:$normalizedStyle:'
        '$normalizedMaterial:${normalizedBreath.toStringAsFixed(2)}:'
        '${normalizedReverb.toStringAsFixed(2)}:'
        '${normalizedTail.toStringAsFixed(2)}:${sustained ? 'sus' : 'shot'}';
    return _cache.putIfAbsent(
      key,
      () => _buildFluteNote(
        frequency,
        normalizedStyle,
        material: normalizedMaterial,
        breath: normalizedBreath.toDouble(),
        reverb: normalizedReverb.toDouble(),
        tail: normalizedTail.toDouble(),
        sustained: sustained,
      ),
    );
  }

  static Uint8List fluteSustainCore(
    double frequency, {
    String style = 'airy',
    String material = 'wood',
  }) {
    final normalizedStyle = _normalizeFluteStyle(style);
    final normalizedMaterial = _normalizeFluteMaterial(material);
    final key =
        'flute:sustain:core:${frequency.toStringAsFixed(2)}:$normalizedStyle:$normalizedMaterial';
    return _cache.putIfAbsent(
      key,
      () => _buildFluteSustainLayer(
        frequency,
        normalizedStyle,
        material: normalizedMaterial,
        layer: 'core',
      ),
    );
  }

  static Uint8List fluteSustainAir(
    double frequency, {
    String style = 'airy',
    String material = 'wood',
  }) {
    final normalizedStyle = _normalizeFluteStyle(style);
    final normalizedMaterial = _normalizeFluteMaterial(material);
    final key =
        'flute:sustain:air:${frequency.toStringAsFixed(2)}:$normalizedStyle:$normalizedMaterial';
    return _cache.putIfAbsent(
      key,
      () => _buildFluteSustainLayer(
        frequency,
        normalizedStyle,
        material: normalizedMaterial,
        layer: 'air',
      ),
    );
  }

  static Uint8List fluteSustainEdge(
    double frequency, {
    String style = 'airy',
    String material = 'wood',
  }) {
    final normalizedStyle = _normalizeFluteStyle(style);
    final normalizedMaterial = _normalizeFluteMaterial(material);
    final key =
        'flute:sustain:edge:${frequency.toStringAsFixed(2)}:$normalizedStyle:$normalizedMaterial';
    return _cache.putIfAbsent(
      key,
      () => _buildFluteSustainLayer(
        frequency,
        normalizedStyle,
        material: normalizedMaterial,
        layer: 'edge',
      ),
    );
  }

  static Uint8List guitarNote(
    double frequency, {
    String style = 'steel',
    double resonance = 0.5,
    double pickPosition = 0.55,
  }) {
    final normalizedStyle = switch (style) {
      'nylon' => 'nylon',
      'ambient' => 'ambient',
      'twelve' => 'twelve',
      _ => 'steel',
    };
    final normalizedResonance = (resonance.clamp(0.0, 1.0) * 10).round() / 10;
    final normalizedPickPosition =
        (pickPosition.clamp(0.05, 0.95) * 10).round() / 10;
    final key =
        'guitar:${frequency.toStringAsFixed(2)}:$normalizedStyle:'
        '${normalizedResonance.toStringAsFixed(1)}:'
        '${normalizedPickPosition.toStringAsFixed(1)}';
    return _cache.putIfAbsent(
      key,
      () => _buildGuitarNote(
        frequency: frequency,
        style: normalizedStyle,
        resonance: normalizedResonance.toDouble(),
        pickPosition: normalizedPickPosition.toDouble(),
      ),
    );
  }

  static Uint8List drumHit(
    String kind, {
    String kit = 'acoustic',
    double tone = 0.5,
    double tail = 0.42,
    String material = 'wood',
  }) {
    final normalizedKind = switch (kind) {
      'kick' => 'kick',
      'snare' => 'snare',
      'hihat' => 'hihat',
      'tom' => 'tom',
      _ => 'kick',
    };
    final normalizedKit = switch (kit) {
      'electro' => 'electro',
      'lofi' => 'lofi',
      _ => 'acoustic',
    };
    final normalizedTone = (tone.clamp(0.0, 1.0) * 10).round() / 10;
    final normalizedTail = (tail.clamp(0.0, 1.0) * 10).round() / 10;
    final normalizedMaterial = switch (material) {
      'metal' => 'metal',
      'hybrid' => 'hybrid',
      _ => 'wood',
    };
    final key =
        'drum:$normalizedKind:$normalizedKit:'
        '${normalizedTone.toStringAsFixed(1)}:'
        '${normalizedTail.toStringAsFixed(1)}:$normalizedMaterial';
    return _cache.putIfAbsent(
      key,
      () => _buildDrumHit(
        normalizedKind,
        normalizedKit,
        normalizedTone.toDouble(),
        normalizedTail.toDouble(),
        normalizedMaterial,
      ),
    );
  }

  static Uint8List triangleHit({
    String style = 'orchestral',
    String material = 'steel',
    double strike = 0.65,
    double damping = 0.2,
  }) {
    final normalizedStyle = switch (style) {
      'soft' => 'soft',
      'bright' => 'bright',
      _ => 'orchestral',
    };
    final normalizedMaterial = switch (material) {
      'brass' => 'brass',
      'aluminum' => 'aluminum',
      _ => 'steel',
    };
    final normalizedStrike = (strike.clamp(0.0, 1.0) * 10).round() / 10;
    final normalizedDamping = (damping.clamp(0.0, 1.0) * 10).round() / 10;
    final key =
        'triangle:hit:$normalizedStyle:$normalizedMaterial:'
        '${normalizedStrike.toStringAsFixed(1)}:'
        '${normalizedDamping.toStringAsFixed(1)}';
    return _cache.putIfAbsent(
      key,
      () => _buildTriangleHit(
        normalizedStyle,
        normalizedMaterial,
        normalizedStrike.toDouble(),
        normalizedDamping.toDouble(),
      ),
    );
  }

  static Uint8List guqinNote(
    double frequency, {
    String style = 'silk',
    double resonance = 0.62,
    double slide = 0,
  }) {
    final normalizedStyle = switch (style) {
      'bright' => 'bright',
      'hollow' => 'hollow',
      _ => 'silk',
    };
    final normalizedResonance = (resonance.clamp(0.0, 1.0) * 10).round() / 10;
    final normalizedSlide = (slide.clamp(-1.0, 1.0) * 10).round() / 10;
    final key =
        'guqin:${frequency.toStringAsFixed(2)}:$normalizedStyle:'
        '${normalizedResonance.toStringAsFixed(1)}:'
        '${normalizedSlide.toStringAsFixed(1)}';
    return _cache.putIfAbsent(
      key,
      () => _buildGuqinNote(
        frequency: frequency,
        style: normalizedStyle,
        resonance: normalizedResonance.toDouble(),
        slide: normalizedSlide.toDouble(),
      ),
    );
  }

  static Uint8List violinNote(
    double frequency, {
    String style = 'solo',
    double bow = 0.65,
    double reverb = 0.24,
  }) {
    final normalizedStyle = switch (style) {
      'warm' => 'warm',
      'glass' => 'glass',
      _ => 'solo',
    };
    final normalizedBow = (bow.clamp(0.15, 1.0) * 20).round() / 20;
    final normalizedReverb = (reverb.clamp(0.0, 0.5) * 20).round() / 20;
    final key =
        'violin:${frequency.toStringAsFixed(2)}:$normalizedStyle:'
        '${normalizedBow.toStringAsFixed(2)}:'
        '${normalizedReverb.toStringAsFixed(2)}';
    return _cache.putIfAbsent(
      key,
      () => _buildViolinNote(
        frequency: frequency,
        style: normalizedStyle,
        bow: normalizedBow.toDouble(),
        reverb: normalizedReverb.toDouble(),
      ),
    );
  }

  static Uint8List metronomeClick({required bool accent}) {
    final key = accent ? 'metronome:accent' : 'metronome:regular';
    return _cache.putIfAbsent(
      key,
      () => _buildClick(
        accent ? 1560.0 : 1080.0,
        overtone: accent ? 1960.0 : 1420.0,
        durationSeconds: accent ? 0.11 : 0.085,
      ),
    );
  }

  static Uint8List woodfishClick() {
    return _cache.putIfAbsent('woodfish', _buildWoodfishClick);
  }

  static Uint8List _buildSoothingLoop(String presetId) {
    final chords = switch (presetId) {
      'mist' => const <List<double>>[
        <double>[196.00, 293.66, 392.00],
        <double>[220.00, 293.66, 440.00],
        <double>[174.61, 261.63, 392.00],
        <double>[196.00, 293.66, 392.00],
      ],
      'harbor' => const <List<double>>[
        <double>[220.00, 329.63, 493.88],
        <double>[246.94, 369.99, 440.00],
        <double>[196.00, 293.66, 440.00],
        <double>[220.00, 329.63, 493.88],
      ],
      _ => const <List<double>>[
        <double>[174.61, 261.63, 392.00],
        <double>[196.00, 293.66, 440.00],
        <double>[220.00, 329.63, 493.88],
        <double>[174.61, 261.63, 392.00],
      ],
    };
    final brightness = switch (presetId) {
      'mist' => 0.18,
      'harbor' => 0.28,
      _ => 0.22,
    };
    return _buildPadLoop(chords: chords, brightness: brightness);
  }

  static Uint8List _buildSoothingSceneLoop(String sceneId) {
    return switch (sceneId) {
      'motion' => _buildMotionLoop(),
      'harp_scene' => _buildHarpLoop(),
      'music_box' => _buildMusicBoxLoop(),
      _ => _buildSoothingLoop(sceneId),
    };
  }

  static Uint8List _buildPadLoop({
    required List<List<double>> chords,
    required double brightness,
  }) {
    const sampleRate = 22050;
    const chordDuration = 3.0;
    final totalDuration = chordDuration * chords.length;
    final totalSamples = (sampleRate * totalDuration).round();
    final samples = List<double>.filled(totalSamples, 0);

    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final chordIndex = (t / chordDuration).floor().clamp(
        0,
        chords.length - 1,
      );
      final chord = chords[chordIndex];
      final localT = t - chordIndex * chordDuration;
      final attack = (localT / 0.55).clamp(0.0, 1.0);
      final release = ((chordDuration - localT) / 0.95).clamp(0.0, 1.0);
      final envelope = _smoothStep(attack) * _smoothStep(release);
      final pulse = 0.9 + 0.1 * math.sin(math.pi * 2 * 0.15 * t);

      var value = 0.0;
      for (final note in chord) {
        value += math.sin(math.pi * 2 * note * t) * 0.24;
        value +=
            math.sin(math.pi * 2 * note * 2 * t + 0.35) *
            (0.08 + brightness * 0.07);
        value +=
            math.sin(math.pi * 2 * note * 3 * t + 1.2) *
            (0.03 + brightness * 0.04);
      }

      final globalFadeIn = (t / 0.8).clamp(0.0, 1.0);
      final globalFadeOut = ((totalDuration - t) / 0.8).clamp(0.0, 1.0);
      samples[i] =
          value *
          envelope *
          pulse *
          _smoothStep(globalFadeIn) *
          _smoothStep(globalFadeOut);
    }

    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.9);
  }

  static Uint8List _buildPluckNote({
    required double frequency,
    required double durationSeconds,
    required String style,
    required double reverb,
  }) {
    const sampleRate = 32000;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    final tone = _pluckTone(style);
    final delaySamples = math.max(18, (sampleRate / frequency).round());
    final ring = List<double>.generate(delaySamples, (i) {
      final phase = i / delaySamples;
      final noise =
          (math.sin((i + 1) * 12.9898 + frequency * 0.005) +
              math.cos((i + 1) * 78.233 + frequency * 0.0017)) *
          0.5;
      final brightMask = phase < tone.brightness ? 1.0 : 0.76;
      return noise * brightMask;
    });
    final bodyPhaseShift = frequency * 0.0003;
    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final env =
          (1 - math.exp(-tone.attack * t)) *
          math.exp(-tone.decay * t) *
          (1 - t / durationSeconds).clamp(0.0, 1.0);

      final idx = i % delaySamples;
      final next = (idx + 1) % delaySamples;
      final averaged = (ring[idx] + ring[next]) * 0.5;
      final lowpass = averaged * (0.86 + tone.brightness * 0.11);
      ring[idx] = lowpass * tone.feedback;
      final stringSample = ring[idx];

      final pickTransient =
          (math.sin(math.pi * 2 * frequency * 4.8 * t + bodyPhaseShift) * 0.55 +
              math.sin(math.pi * 2 * frequency * 7.4 * t + 0.65) * 0.45) *
          math.exp(-45 * t) *
          tone.transient;
      final pickNoise =
          (math.sin((i + 1) * 11.173 + frequency * 0.002) +
              math.cos((i + 1) * 63.917 + frequency * 0.004)) *
          tone.noise *
          math.exp(-34 * t);
      final bodyResonance =
          math.sin(math.pi * 2 * frequency * t) * (0.16 + tone.bodyMix * 0.08) +
          math.sin(math.pi * 2 * frequency * (2.0 + tone.bodyDetune) * t + 0.36) *
              tone.overtoneMix +
          math.sin(math.pi * 2 * frequency * (3.05 + tone.bodyDetune * 1.7) * t + 1.1) *
              (0.03 + tone.brightness * 0.05);
      final octaveBloom =
          math.sin(math.pi * 2 * frequency * 0.5 * t + 0.12) *
          tone.octaveBloom *
          math.exp(-tone.bodyDecay * t);
      final shimmer =
          math.sin(math.pi * 2 * frequency * 5.2 * t + 0.7) *
          tone.shimmer *
          math.exp(-3.4 * t);
      final air =
          math.sin(math.pi * 2 * frequency * (6.4 + tone.brightness) * t + 0.24) *
          tone.air *
          math.exp(-5.2 * t);

      final value =
          (stringSample +
              pickTransient +
              pickNoise +
              bodyResonance * tone.bodyMix +
              octaveBloom +
              shimmer +
              air) *
          env;
      samples[i] = _softClip(value * tone.outputGain);
    }
    _applySchroederReverb(samples, sampleRate: sampleRate, amount: reverb);
    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.92);
  }

  static Uint8List _buildPianoNote(
    double frequency,
    String style, {
    required double reverb,
    required double decay,
  }) {
    const sampleRate = 32000;
    final durationSeconds = 2.0 + decay * 1.0;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    final detuneA = frequency * 0.9972;
    final detuneB = frequency * 1.0028;
    final harmonicMix = switch (style) {
      'bright' => 1.2,
      'felt' => 0.78,
      'upright' => 1.06,
      _ => 1.0,
    };
    final decayMul =
        switch (style) {
          'bright' => 1.1,
          'felt' => 0.82,
          'upright' => 0.92,
          _ => 1.0,
        } /
        decay;
    final hammerNoise = switch (style) {
      'bright' => 0.058,
      'felt' => 0.022,
      'upright' => 0.046,
      _ => 0.04,
    };
    final duplexMul = switch (style) {
      'bright' => 0.1,
      'felt' => 0.035,
      'upright' => 0.07,
      _ => 0.06,
    };
    final inharmonicity = 1 + (frequency / 440.0) * 0.00045;

    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final env =
          (1 - math.exp(-140 * t)) *
          math.exp(-(3.4 * decayMul) * t) *
          (1 - t / durationSeconds).clamp(0.0, 1.0);
      final hammer =
          (math.sin((i + 1) * 12.9898) + math.cos((i + 1) * 78.233)) *
          hammerNoise *
          math.exp(-92 * t);
      var value = 0.0;
      for (var partial = 1; partial <= 6; partial += 1) {
        final partialFreq = frequency * partial * (1 + (partial - 1) * 0.0005);
        final amplitude = switch (partial) {
          1 => 0.56,
          2 => 0.22 * harmonicMix,
          3 => 0.12 * harmonicMix,
          4 => 0.07 * harmonicMix,
          5 => 0.038 * harmonicMix,
          _ => 0.024 * harmonicMix,
        };
        value +=
            math.sin(math.pi * 2 * partialFreq * inharmonicity * t) * amplitude;
      }
      value += math.sin(math.pi * 2 * detuneA * t + 0.07) * 0.16;
      value += math.sin(math.pi * 2 * detuneB * t - 0.06) * 0.16;
      value +=
          math.sin(math.pi * 2 * frequency * 6.7 * t + 0.5) *
          duplexMul *
          math.exp(-5.8 * t);
      value +=
          math.sin(math.pi * 2 * frequency * 8.2 * t + 1.1) *
          (duplexMul * 0.7) *
          math.exp(-7.2 * t);
      final sympathetic =
          math.sin(math.pi * 2 * frequency * 0.5 * t + 0.9) *
          (0.06 + harmonicMix * 0.02) *
          math.exp(-2.8 * t);
      samples[i] = _softClip((value + hammer + sympathetic) * env * 1.38);
    }

    final baseReverb = switch (style) {
      'bright' => 0.1,
      'felt' => 0.17,
      'upright' => 0.13,
      _ => 0.12,
    };
    _applySchroederReverb(
      samples,
      sampleRate: sampleRate,
      amount: ((baseReverb + reverb) / 2).clamp(0.0, 0.55),
    );
    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.92);
  }

  static Uint8List _buildFluteNote(
    double frequency,
    String style, {
    required String material,
    required double breath,
    required double reverb,
    required double tail,
    required bool sustained,
  }) {
    const sampleRate = 32000;
    final durationSeconds = sustained ? 4.8 : 2.85;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    final breathEnergy = breath.clamp(0.18, 1.0).toDouble();

    final materialVibratoMul = switch (material) {
      'metal_short' => 0.82,
      'metal_long' => 1.08,
      'jade' => 0.92,
      'clay' => 0.74,
      _ => 1.0,
    };
    final vibratoDepth = (switch (style) {
      'lead' => 0.0028,
      'alto' => 0.0048,
      'bamboo' => 0.0032,
      _ => 0.004,
    }) * materialVibratoMul;
    final vibratoRate = switch (style) {
      'lead' => 5.8,
      'alto' => 4.9,
      'bamboo' => 5.1,
      _ => 5.2,
    };
    final materialBreathMul = switch (material) {
      'metal_short' => 0.76,
      'metal_long' => 0.72,
      'jade' => 0.64,
      'clay' => 0.44,
      _ => 1.0,
    };
    final breathNoise = (switch (style) {
      'lead' => 0.012,
      'alto' => 0.024,
      'bamboo' => 0.028,
      _ => 0.018,
    }) * materialBreathMul * (0.75 + breath * 0.6);
    final materialOvertoneMul = switch (material) {
      'metal_short' => 1.34,
      'metal_long' => 1.18,
      'jade' => 0.9,
      'clay' => 0.72,
      _ => 1.0,
    };
    final overtoneMul = (switch (style) {
      'lead' => 1.3,
      'alto' => 0.84,
      'bamboo' => 0.9,
      _ => 1.0,
    }) * materialOvertoneMul * (0.84 + breath * 0.34);
    final attackSeconds = (switch (style) {
      'lead' => 0.03,
      'alto' => 0.055,
      'bamboo' => 0.062,
      _ => 0.048,
    }) * (sustained ? 1.16 : 1.0) * (1.05 - breath * 0.18);
    final bodyMul = switch (material) {
      'metal_short' => 0.86,
      'metal_long' => 0.92,
      'jade' => 1.02,
      'clay' => 1.18,
      _ => 0.98,
    };
    final steadyDecay =
        (switch (style) {
          'lead' => 0.98,
          'alto' => 0.72,
          'bamboo' => 0.78,
          _ => 0.84,
        }) /
        (0.72 + tail * 0.86 + (sustained ? 0.36 : 0.0));
    final releaseStartBase = switch (style) {
      'lead' => durationSeconds * 0.66,
      'alto' => durationSeconds * 0.6,
      'bamboo' => durationSeconds * 0.58,
      _ => durationSeconds * 0.62,
    };
    final releaseStart = (releaseStartBase + tail * 0.28).clamp(
      durationSeconds * 0.5,
      durationSeconds * 0.9,
    );
    final tailFloor =
        ((switch (style) {
                  'lead' => 0.09,
                  'alto' => 0.16,
                  'bamboo' => 0.14,
                  _ => 0.12,
                }) *
                (0.7 + tail * 1.05))
            .clamp(0.05, 0.3);

    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final attack = (t / attackSeconds).clamp(0.0, 1.0).toDouble();
      final sustain = math.exp(-steadyDecay * t);
      final releaseNorm =
          ((durationSeconds - t) / (durationSeconds - releaseStart))
              .clamp(0.0, 1.0)
              .toDouble();
      final releaseCurve = math.pow(releaseNorm, 1.35).toDouble();
      final tailBlend = t >= releaseStart ? releaseCurve : 1.0;
      final env = (attack * sustain * tailBlend + tailFloor * (1 - releaseNorm))
          .clamp(0.0, 1.0)
          .toDouble();

      final vibLfo = math.sin(
        math.pi * 2 * vibratoRate * t + math.sin(math.pi * 2 * 0.38 * t) * 0.34,
      );
      final pitched = frequency * (1 + vibratoDepth * vibLfo);
      final embouchureJet =
          math.sin(math.pi * 2 * pitched * (1.02 + breathEnergy * 0.02) * t + 0.07) *
          (0.12 + breathEnergy * 0.08) *
          math.exp(-2.6 * t);
      final airColumn =
          math.sin(math.pi * 2 * pitched * (0.5 + tail * 0.08) * t + 0.52) *
          (0.06 + tail * 0.05) *
          math.exp(-0.9 * t);

      final jetNoise =
          (math.sin((i + 1) * 23.17) +
              math.sin((i + 1) * 47.31 + 0.9) +
              math.cos((i + 1) * 61.11)) *
          breathNoise *
          math.exp(-2.15 * t);
      final chiff =
          (math.sin((i + 1) * 111.3) + math.cos((i + 1) * 87.7)) *
          (0.016 + breathNoise * 0.45) *
          math.exp(-58 * t);

      var tone = math.sin(math.pi * 2 * pitched * t) * (0.56 + breathEnergy * 0.18);
      tone +=
          math.sin(math.pi * 2 * pitched * 2.01 * t + 0.11) *
          (0.17 * overtoneMul);
      tone +=
          math.sin(math.pi * 2 * pitched * 2.98 * t + 0.36) *
          (0.08 * overtoneMul);
      tone +=
          math.sin(math.pi * 2 * pitched * 4.07 * t + 0.63) *
          (0.04 * overtoneMul);
      final formantA =
          math.sin(math.pi * 2 * (pitched * 1.96) * t + 0.18) *
          (0.05 + breathEnergy * 0.05) *
          (switch (material) {
            'metal_short' => 1.14,
            'metal_long' => 1.08,
            'jade' => 0.9,
            'clay' => 0.72,
            _ => 0.96,
          });
      final formantB =
          math.sin(math.pi * 2 * (pitched * 3.84) * t + 0.47) *
          (0.028 + breathEnergy * 0.032) *
          (switch (style) {
            'lead' => 1.16,
            'alto' => 0.88,
            'bamboo' => 0.82,
            _ => 1.0,
          });
      final bodyResonance =
          math.sin(math.pi * 2 * pitched * 0.5 * t + 0.28) *
              (0.032 + tail * 0.05) *
              bodyMul *
              math.exp(-1.1 * t) +
          math.sin(math.pi * 2 * pitched * 1.48 * t + 0.76) *
              (0.018 + breath * 0.03) *
              bodyMul *
              math.exp(-1.8 * t);
      final edge =
          math.sin(math.pi * 2 * pitched * (5.4 + breath * 0.8) * t + 0.19) *
          (switch (material) {
            'metal_short' => 0.03,
            'metal_long' => 0.024,
            'jade' => 0.014,
            'clay' => 0.008,
            _ => 0.018,
          }) *
          math.exp(-3.4 * t);

      final tailResonance =
          math.sin(math.pi * 2 * pitched * 0.5 * t + 0.82) *
          (0.05 + tailFloor * 0.18) *
          math.exp(-1.55 * math.max(0.0, t - releaseStart));
      samples[i] = _softClip(
        (embouchureJet +
                airColumn +
                tone +
                formantA +
                formantB +
                jetNoise +
                chiff +
                bodyResonance +
                edge +
                tailResonance) *
            env *
            (1.02 + breathEnergy * 0.22),
      );
    }

    final baseReverb = (switch (style) {
      'lead' => 0.16,
      'alto' => 0.27,
      'bamboo' => 0.24,
      _ => 0.22,
    }) +
        (switch (material) {
          'metal_short' => 0.02,
          'metal_long' => 0.03,
          'jade' => 0.01,
          'clay' => -0.03,
          _ => 0.0,
        });
    _applySchroederReverb(
      samples,
      sampleRate: sampleRate,
      amount: ((baseReverb + reverb) / 2).clamp(0.0, 0.42),
    );
    return _encodeWav(
      samples,
      sampleRate: sampleRate,
      gain: sustained ? 0.82 : 0.86,
    );
  }

  static String _normalizeFluteStyle(String style) {
    return switch (style) {
      'lead' => 'lead',
      'alto' => 'alto',
      'bamboo' => 'bamboo',
      _ => 'airy',
    };
  }

  static String _normalizeFluteMaterial(String material) {
    return switch (material) {
      'metal_short' => 'metal_short',
      'metal_long' => 'metal_long',
      'jade' => 'jade',
      'clay' => 'clay',
      _ => 'wood',
    };
  }

  static Uint8List _buildFluteSustainLayer(
    double frequency,
    String style, {
    required String material,
    required String layer,
  }) {
    const sampleRate = 32000;
    const durationSeconds = 6.0;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    final loopFrequency = (frequency * durationSeconds).round() / durationSeconds;
    final vibratoRate = switch (style) {
      'lead' => 5.0,
      'alto' => 4.0,
      'bamboo' => 4.0,
      _ => 4.0,
    };
    final vibratoDepth = switch (layer) {
      'core' => 0.0016,
      'air' => 0.0004,
      _ => 0.0009,
    };
    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final loopPhase = t / durationSeconds;
      final loopEnv =
          0.9 + 0.1 * math.cos(math.pi * 2 * loopPhase);
      final vib =
          math.sin(math.pi * 2 * vibratoRate * loopPhase) * vibratoDepth;
      final pitched = loopFrequency * (1 + vib);
      samples[i] = switch (layer) {
        'air' => _buildFluteAirLayerSample(t, pitched, style, material),
        'edge' => _buildFluteEdgeLayerSample(t, pitched, style, material),
        _ => _buildFluteCoreLayerSample(t, pitched, style, material),
      } *
      loopEnv;
    }
    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.78);
  }

  static double _buildFluteCoreLayerSample(
    double t,
    double pitched,
    String style,
    String material,
  ) {
    final bodyMul = switch (material) {
      'metal_short' => 0.88,
      'metal_long' => 0.92,
      'jade' => 1.0,
      'clay' => 1.08,
      _ => 0.96,
    };
    final overtone = switch (style) {
      'lead' => 0.18,
      'alto' => 0.1,
      'bamboo' => 0.09,
      _ => 0.13,
    };
    return math.sin(math.pi * 2 * pitched * t) * 0.62 +
        math.sin(math.pi * 2 * pitched * 2.0 * t + 0.12) * overtone +
        math.sin(math.pi * 2 * pitched * 3.0 * t + 0.38) * 0.06 * bodyMul +
        math.sin(math.pi * 2 * pitched * 0.5 * t + 0.84) * 0.04 * bodyMul;
  }

  static double _buildFluteAirLayerSample(
    double t,
    double pitched,
    String style,
    String material,
  ) {
    final breathMul = switch (material) {
      'metal_short' => 0.68,
      'metal_long' => 0.62,
      'jade' => 0.52,
      'clay' => 0.4,
      _ => 0.84,
    };
    final jetMul = switch (style) {
      'lead' => 0.1,
      'alto' => 0.08,
      'bamboo' => 0.11,
      _ => 0.09,
    };
    final pseudoNoise =
        math.sin(math.pi * 2 * pitched * 5.0 * t + 0.31) * 0.04 +
        math.sin(math.pi * 2 * pitched * 7.0 * t + 0.57) * 0.03 +
        math.sin(math.pi * 2 * pitched * 11.0 * t + 0.18) * 0.015;
    return pseudoNoise * breathMul +
        math.sin(math.pi * 2 * pitched * 1.02 * t + 0.08) * jetMul;
  }

  static double _buildFluteEdgeLayerSample(
    double t,
    double pitched,
    String style,
    String material,
  ) {
    final edgeMul = switch (material) {
      'metal_short' => 0.1,
      'metal_long' => 0.08,
      'jade' => 0.05,
      'clay' => 0.03,
      _ => 0.06,
    };
    final formantMul = switch (style) {
      'lead' => 0.11,
      'alto' => 0.07,
      'bamboo' => 0.06,
      _ => 0.08,
    };
    return math.sin(math.pi * 2 * pitched * 1.92 * t + 0.16) * formantMul +
        math.sin(math.pi * 2 * pitched * 3.86 * t + 0.43) * (formantMul * 0.56) +
        math.sin(math.pi * 2 * pitched * 5.35 * t + 0.22) * edgeMul;
  }

  static Uint8List _buildGuitarNote({
    required double frequency,
    required String style,
    required double resonance,
    required double pickPosition,
  }) {
    const sampleRate = 32000;
    const durationSeconds = 2.9;
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

    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final env =
          (1 - math.exp(-44 * t)) *
          math.exp(-(2.25 / styleDecay) * t) *
          (1 - t / durationSeconds).clamp(0.0, 1.0);
      var tone = 0.0;
      for (var partial = 1; partial <= 8; partial += 1) {
        final harmonicFreq = frequency * partial;
        final comb = math.sin(math.pi * pickPosition * partial).abs();
        final amp =
            (1 / math.pow(partial, 1.12)) *
            (0.75 + comb * 1.05) *
            styleBrightness;
        final partialDecay = math.exp(-(0.7 + partial * 0.22 / styleDecay) * t);
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
          math.exp(-44 * t);
      final fretNoise =
          (math.sin((i + 1) * 137.0) + math.cos((i + 1) * 96.5)) *
          (0.008 + pickColor * 0.01) *
          math.exp(-18 * t);
      final bodyModeA =
          math.sin(math.pi * 2 * frequency * 0.5 * t + 0.7) *
          resonantBody *
          styleBody *
          0.18 *
          math.exp(-2.8 * t);
      final bodyModeB =
          math.sin(math.pi * 2 * frequency * 0.77 * t + 1.1) *
          resonantBody *
          styleBody *
          0.12 *
          math.exp(-3.2 * t);
      final sympathetic =
          math.sin(math.pi * 2 * frequency * 1.01 * t + 0.5) *
          (0.06 + resonance * 0.08) *
          math.exp(-1.9 * t);
      samples[i] = _softClip(
        (tone + bridgeClick + fretNoise + bodyModeA + bodyModeB + sympathetic) *
            env *
            1.28,
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

  static Uint8List _buildGuqinNote({
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
          frequency *
          math.pow(2.0, slideOffset / 12.0).toDouble() *
          microVibrato;
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
        (tone + harmonicChime + body + stringFriction + slideRustle) *
            env *
            1.22,
      );
    }
    _applySchroederReverb(
      samples,
      sampleRate: sampleRate,
      amount: 0.2 + resonance * 0.24,
    );
    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.88);
  }

  static double _drumMaterialBrightness(String material) {
    return switch (material) {
      'metal' => 1.22,
      'hybrid' => 1.06,
      _ => 0.9,
    };
  }

  static Uint8List _buildDrumHit(
    String kind,
    String kit,
    double tone,
    double tail,
    String material,
  ) {
    return switch (kind) {
      'snare' => _buildSnareHit(kit, tone, tail, material),
      'hihat' => _buildHiHatHit(kit, tone, tail, material),
      'tom' => _buildTomHit(kit, tone, tail, material),
      _ => _buildKickHit(kit, tone, tail, material),
    };
  }

  static Uint8List _buildKickHit(
    String kit,
    double tone,
    double tail,
    String material,
  ) {
    const sampleRate = 24000;
    const durationSeconds = 0.58;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    final bodyMul = switch (kit) {
      'electro' => 1.26,
      'lofi' => 0.86,
      _ => 1.0,
    };
    final clickMul = switch (kit) {
      'electro' => 1.42,
      'lofi' => 0.72,
      _ => 1.0,
    };
    final materialMul = _drumMaterialBrightness(material);
    final tailDecay = 10.4 - tail * 5.1;
    final startSweep = 124 + tone * 52;
    final endSweep = 33 + tone * 24;
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
      final click = math.exp(-115 * t) * (0.09 * clickMul * materialMul);
      final beaterNoise =
          (math.sin((i + 1) * 30.41) + math.cos((i + 1) * 51.22)) *
          (0.018 + tone * 0.014) *
          math.exp(-46 * t);
      samples[i] = _softClip(
        (sub + subTail + click + beaterNoise) * env * 1.34,
      );
    }
    if (kit != 'electro') {
      _applySchroederReverb(
        samples,
        sampleRate: sampleRate,
        amount: 0.02 + tail * 0.06,
      );
    }
    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.95);
  }

  static Uint8List _buildSnareHit(
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
    final toneFrequency = 146 + tone * 110;
    final decay = 16.8 - tail * 7.8;
    final wireDecay = 30 - tail * 13;
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
      samples[i] = _softClip(
        (shell + overtone + wireNoise + snap) * env * 1.06,
      );
    }
    _applySchroederReverb(
      samples,
      sampleRate: sampleRate,
      amount: kit == 'electro' ? (0.08 + tail * 0.05) : (0.03 + tail * 0.04),
    );
    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.95);
  }

  static Uint8List _buildHiHatHit(
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
    final decay = 30 - tail * 14;
    final modes = <double>[
      5100 + tone * 2600,
      6800 + tone * 3100,
      8600 + tone * 3600,
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
      samples[i] = _softClip((noise + metal + stick) * env * 1.08);
    }
    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.95);
  }

  static Uint8List _buildTomHit(
    String kit,
    double tone,
    double tail,
    String material,
  ) {
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
    final rootStart = 126 + tone * 74;
    final rootEnd = 94 + tone * 52;
    final decay = 10.8 - tail * 4.6;
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
      final knock =
          (math.sin((i + 1) * 32.7) + math.cos((i + 1) * 53.2)) *
          (0.048 + tone * 0.018) *
          math.exp(-40 * t);
      samples[i] = _softClip(
        (fundamental + overtone + shell + knock) * env * 1.14,
      );
    }
    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.95);
  }

  static Uint8List _buildTriangleHit(
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

  static Uint8List _buildViolinNote({
    required double frequency,
    required String style,
    required double bow,
    required double reverb,
  }) {
    const sampleRate = 32000;
    const durationSeconds = 3.8;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    final brightness = switch (style) {
      'warm' => 0.82,
      'glass' => 1.18,
      _ => 1.0,
    };
    final body = switch (style) {
      'warm' => 1.12,
      'glass' => 0.78,
      _ => 0.94,
    };
    final vibratoDepth = switch (style) {
      'warm' => 0.0048,
      'glass' => 0.0034,
      _ => 0.004,
    };
    final vibratoRate = switch (style) {
      'warm' => 5.0,
      'glass' => 6.2,
      _ => 5.6,
    };

    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final attack = (1 - math.exp(-(18 + bow * 22) * t));
      final sustain = math.exp(-(0.42 + (1 - bow) * 0.34) * t);
      final release = ((durationSeconds - t) / 0.9).clamp(0.0, 1.0).toDouble();
      final env = (attack * sustain * math.pow(release, 1.2)).clamp(0.0, 1.0);
      final vibrato =
          math.sin(
            math.pi * 2 * vibratoRate * t +
                math.sin(math.pi * 2 * 0.28 * t) * 0.24,
          ) *
          vibratoDepth;
      final bowedFrequency = frequency * (1 + vibrato);
      var tone = math.sin(math.pi * 2 * bowedFrequency * t) * 0.54;
      tone +=
          math.sin(math.pi * 2 * bowedFrequency * 2.01 * t + 0.18) *
          (0.22 * brightness);
      tone +=
          math.sin(math.pi * 2 * bowedFrequency * 3.03 * t + 0.44) *
          (0.11 * brightness);
      tone +=
          math.sin(math.pi * 2 * bowedFrequency * 4.08 * t + 0.82) *
          (0.06 * brightness);
      final bowNoise =
          (math.sin((i + 1) * 24.71) +
              math.cos((i + 1) * 41.33) +
              math.sin((i + 1) * 73.19 + 0.5)) *
          (0.012 + bow * 0.024) *
          math.exp(-0.55 * t);
      final bodyResonance =
          math.sin(math.pi * 2 * bowedFrequency * 0.5 * t + 0.7) *
          (0.08 + body * 0.04) *
          math.exp(-1.6 * t);
      final scrape =
          math.sin(math.pi * 2 * bowedFrequency * 6.7 * t + 0.3) *
          (0.018 + bow * 0.016) *
          math.exp(-4.2 * t);
      samples[i] = _softClip(
        (tone + bowNoise + bodyResonance + scrape) * env * 1.28,
      );
    }

    _applySchroederReverb(samples, sampleRate: sampleRate, amount: reverb);
    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.9);
  }

  static _HarpPluckTone _pluckTone(String style) {
    return switch (style) {
      'warm' => const _HarpPluckTone(
        attack: 28,
        decay: 1.7,
        feedback: 0.9946,
        brightness: 0.34,
        transient: 0.14,
        bodyMix: 1.02,
        shimmer: 0.01,
        noise: 0.012,
        overtoneMix: 0.072,
        octaveBloom: 0.07,
        air: 0.008,
        bodyDetune: 0.008,
        bodyDecay: 2.1,
        outputGain: 1.46,
      ),
      'crystal' => const _HarpPluckTone(
        attack: 60,
        decay: 3.35,
        feedback: 0.9908,
        brightness: 0.9,
        transient: 0.44,
        bodyMix: 0.58,
        shimmer: 0.11,
        noise: 0.03,
        overtoneMix: 0.17,
        octaveBloom: 0.016,
        air: 0.052,
        bodyDetune: 0.034,
        bodyDecay: 4.6,
        outputGain: 1.64,
      ),
      'bright' => const _HarpPluckTone(
        attack: 48,
        decay: 3.05,
        feedback: 0.9919,
        brightness: 0.76,
        transient: 0.34,
        bodyMix: 0.7,
        shimmer: 0.075,
        noise: 0.026,
        overtoneMix: 0.14,
        octaveBloom: 0.022,
        air: 0.04,
        bodyDetune: 0.028,
        bodyDecay: 4.0,
        outputGain: 1.6,
      ),
      'nylon' => const _HarpPluckTone(
        attack: 30,
        decay: 2.1,
        feedback: 0.994,
        brightness: 0.38,
        transient: 0.12,
        bodyMix: 0.98,
        shimmer: 0.008,
        noise: 0.01,
        overtoneMix: 0.064,
        octaveBloom: 0.055,
        air: 0.006,
        bodyDetune: 0.01,
        bodyDecay: 2.4,
        outputGain: 1.44,
      ),
      'glass' => const _HarpPluckTone(
        attack: 64,
        decay: 3.5,
        feedback: 0.9899,
        brightness: 0.97,
        transient: 0.52,
        bodyMix: 0.46,
        shimmer: 0.14,
        noise: 0.04,
        overtoneMix: 0.21,
        octaveBloom: 0.008,
        air: 0.072,
        bodyDetune: 0.04,
        bodyDecay: 5.4,
        outputGain: 1.68,
      ),
      'concert' => const _HarpPluckTone(
        attack: 36,
        decay: 2.85,
        feedback: 0.9936,
        brightness: 0.52,
        transient: 0.24,
        bodyMix: 0.92,
        shimmer: 0.026,
        noise: 0.016,
        overtoneMix: 0.1,
        octaveBloom: 0.04,
        air: 0.016,
        bodyDetune: 0.018,
        bodyDecay: 3.0,
        outputGain: 1.52,
      ),
      'steel' => const _HarpPluckTone(
        attack: 52,
        decay: 3.1,
        feedback: 0.9914,
        brightness: 0.82,
        transient: 0.39,
        bodyMix: 0.62,
        shimmer: 0.082,
        noise: 0.034,
        overtoneMix: 0.18,
        octaveBloom: 0.014,
        air: 0.048,
        bodyDetune: 0.032,
        bodyDecay: 4.4,
        outputGain: 1.66,
      ),
      _ => const _HarpPluckTone(
        attack: 34,
        decay: 2.45,
        feedback: 0.9931,
        brightness: 0.5,
        transient: 0.18,
        bodyMix: 0.9,
        shimmer: 0.02,
        noise: 0.014,
        overtoneMix: 0.086,
        octaveBloom: 0.048,
        air: 0.012,
        bodyDetune: 0.014,
        bodyDecay: 2.8,
        outputGain: 1.48,
      ),
    };
  }

  static void _applySchroederReverb(
    List<double> samples, {
    required int sampleRate,
    required double amount,
  }) {
    final mix = amount.clamp(0.0, 0.8).toDouble();
    if (mix <= 0.001) return;
    final input = List<double>.from(samples, growable: false);
    final combDelays = <int>[
      (sampleRate * 0.0297).round(),
      (sampleRate * 0.0371).round(),
      (sampleRate * 0.0411).round(),
      (sampleRate * 0.0437).round(),
    ];
    final allpassDelays = <int>[
      (sampleRate * 0.005).round(),
      (sampleRate * 0.0017).round(),
    ];
    final combFeedback = 0.74 + mix * 0.2;
    final allpassFeedback = 0.5;
    final wet = List<double>.filled(samples.length, 0);

    for (final delay in combDelays) {
      if (delay <= 1) continue;
      final buffer = List<double>.filled(delay, 0);
      var bufferIndex = 0;
      for (var i = 0; i < samples.length; i += 1) {
        final delayed = buffer[bufferIndex];
        final value = input[i] + delayed * combFeedback;
        buffer[bufferIndex] = value;
        wet[i] += delayed;
        bufferIndex += 1;
        if (bufferIndex >= delay) {
          bufferIndex = 0;
        }
      }
    }

    for (var i = 0; i < samples.length; i += 1) {
      wet[i] /= combDelays.length;
    }

    var processed = wet;
    for (final delay in allpassDelays) {
      if (delay <= 1) continue;
      final buffer = List<double>.filled(delay, 0);
      var bufferIndex = 0;
      final output = List<double>.filled(samples.length, 0);
      for (var i = 0; i < samples.length; i += 1) {
        final delayed = buffer[bufferIndex];
        final current = processed[i];
        final value = -allpassFeedback * current + delayed;
        buffer[bufferIndex] = current + delayed * allpassFeedback;
        output[i] = value;
        bufferIndex += 1;
        if (bufferIndex >= delay) {
          bufferIndex = 0;
        }
      }
      processed = output;
    }

    final wetMix = mix * 0.92;
    final dryMix = 1.0 - wetMix * 0.72;
    for (var i = 0; i < samples.length; i += 1) {
      samples[i] = input[i] * dryMix + processed[i] * wetMix;
    }
  }

  static Uint8List _buildClick(
    double primaryFrequency, {
    required double overtone,
    required double durationSeconds,
  }) {
    const sampleRate = 24000;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final envelope = (1 - math.exp(-110 * t)) * math.exp(-38 * t);
      final noise = (math.sin(i * 12.9898) + math.cos(i * 78.233)) * 0.025;
      final value =
          math.sin(math.pi * 2 * primaryFrequency * t) * 0.7 +
          math.sin(math.pi * 2 * overtone * t + 0.3) * 0.24 +
          noise;
      samples[i] = value * envelope;
    }
    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.98);
  }

  static Uint8List _buildWoodfishClick() {
    const sampleRate = 24000;
    const durationSeconds = 0.26;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final attack = (1 - math.exp(-95 * t));
      final envelope = attack * math.exp(-11.5 * t);
      final resonance = math.sin(math.pi * 2 * 248 * t) * 0.64;
      final overtone = math.sin(math.pi * 2 * 516 * t + 0.28) * 0.24;
      final shell = math.sin(math.pi * 2 * 820 * t + 0.95) * 0.08;
      samples[i] = (resonance + overtone + shell) * envelope;
    }
    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.96);
  }

  static Uint8List _buildMotionLoop() {
    const sampleRate = 24000;
    const durationSeconds = 8.0;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    final pulseSpacing = 60 / 108;
    final chord = <double>[110.0, 220.0, 329.63];

    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      var value = 0.0;
      for (final note in chord) {
        value += math.sin(math.pi * 2 * note * t) * 0.18;
        value += math.sin(math.pi * 2 * note * 2 * t + 0.18) * 0.08;
      }

      var pulse = 0.0;
      for (var beat = 0.0; beat < durationSeconds; beat += pulseSpacing) {
        final local = t - beat;
        if (local < 0 || local > 0.18) continue;
        pulse +=
            math.sin(math.pi * 2 * 74 * local) *
            (1 - math.exp(-80 * local)) *
            math.exp(-13 * local) *
            0.75;
      }

      final shimmer =
          math.sin(math.pi * 2 * 659.25 * t) *
          (0.04 + 0.02 * math.sin(math.pi * 2 * 0.5 * t));
      samples[i] = (value + pulse + shimmer) * 0.72;
    }
    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.9);
  }

  static Uint8List _buildHarpLoop() {
    return _buildSequenceLoop(
      durationSeconds: 8,
      events: const <_LoopEvent>[
        _LoopEvent(0.0, 261.63, 1.9, 0.84, _LoopTimbre.pluck),
        _LoopEvent(0.35, 329.63, 1.8, 0.72, _LoopTimbre.pluck),
        _LoopEvent(0.7, 392.0, 1.9, 0.76, _LoopTimbre.pluck),
        _LoopEvent(1.1, 523.25, 1.8, 0.68, _LoopTimbre.pluck),
        _LoopEvent(2.0, 293.66, 1.8, 0.82, _LoopTimbre.pluck),
        _LoopEvent(2.35, 349.23, 1.8, 0.72, _LoopTimbre.pluck),
        _LoopEvent(2.7, 440.0, 1.9, 0.76, _LoopTimbre.pluck),
        _LoopEvent(3.05, 587.33, 1.8, 0.66, _LoopTimbre.pluck),
        _LoopEvent(4.0, 261.63, 1.9, 0.84, _LoopTimbre.pluck),
        _LoopEvent(4.35, 329.63, 1.8, 0.72, _LoopTimbre.pluck),
        _LoopEvent(4.7, 392.0, 1.9, 0.76, _LoopTimbre.pluck),
        _LoopEvent(5.1, 659.25, 1.9, 0.62, _LoopTimbre.pluck),
        _LoopEvent(6.0, 220.0, 1.8, 0.78, _LoopTimbre.pluck),
        _LoopEvent(6.35, 293.66, 1.8, 0.7, _LoopTimbre.pluck),
        _LoopEvent(6.7, 392.0, 1.9, 0.76, _LoopTimbre.pluck),
        _LoopEvent(7.05, 523.25, 1.8, 0.64, _LoopTimbre.pluck),
      ],
    );
  }

  static Uint8List _buildMusicBoxLoop() {
    return _buildSequenceLoop(
      durationSeconds: 8,
      events: const <_LoopEvent>[
        _LoopEvent(0.0, 659.25, 1.2, 0.82, _LoopTimbre.bell),
        _LoopEvent(0.55, 783.99, 1.2, 0.74, _LoopTimbre.bell),
        _LoopEvent(1.1, 880.0, 1.15, 0.7, _LoopTimbre.bell),
        _LoopEvent(1.7, 783.99, 1.2, 0.7, _LoopTimbre.bell),
        _LoopEvent(2.25, 659.25, 1.25, 0.8, _LoopTimbre.bell),
        _LoopEvent(3.0, 587.33, 1.1, 0.74, _LoopTimbre.bell),
        _LoopEvent(3.55, 659.25, 1.2, 0.78, _LoopTimbre.bell),
        _LoopEvent(4.1, 783.99, 1.2, 0.72, _LoopTimbre.bell),
        _LoopEvent(4.7, 987.77, 1.15, 0.62, _LoopTimbre.bell),
        _LoopEvent(5.35, 880.0, 1.2, 0.68, _LoopTimbre.bell),
        _LoopEvent(6.0, 783.99, 1.2, 0.7, _LoopTimbre.bell),
        _LoopEvent(6.65, 659.25, 1.2, 0.78, _LoopTimbre.bell),
      ],
    );
  }

  static Uint8List _buildSequenceLoop({
    required double durationSeconds,
    required List<_LoopEvent> events,
  }) {
    const sampleRate = 24000;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);

    for (final event in events) {
      final startIndex = (event.startSeconds * sampleRate).round();
      final endIndex =
          ((event.startSeconds + event.durationSeconds) * sampleRate).round();
      for (var i = startIndex; i < endIndex && i < totalSamples; i += 1) {
        final t = (i - startIndex) / sampleRate;
        final normalizedT = t / event.durationSeconds;
        final sample = switch (event.timbre) {
          _LoopTimbre.pluck => _pluckSample(
            frequency: event.frequency,
            t: t,
            normalizedT: normalizedT,
          ),
          _LoopTimbre.bell => _bellSample(
            frequency: event.frequency,
            t: t,
            normalizedT: normalizedT,
          ),
        };
        samples[i] += sample * event.volume;
      }
    }

    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.92);
  }

  static double _pluckSample({
    required double frequency,
    required double t,
    required double normalizedT,
  }) {
    final envelope =
        (1 - math.exp(-34 * t)) *
        math.exp(-2.9 * t) *
        (1 - normalizedT).clamp(0.0, 1.0);
    var value = math.sin(math.pi * 2 * frequency * t) * 0.72;
    value += math.sin(math.pi * 2 * frequency * 2 * t + 0.4) * 0.22;
    value += math.sin(math.pi * 2 * frequency * 3.2 * t + 0.86) * 0.1;
    return value * envelope;
  }

  static double _bellSample({
    required double frequency,
    required double t,
    required double normalizedT,
  }) {
    final envelope =
        (1 - math.exp(-55 * t)) *
        math.exp(-3.6 * t) *
        (1 - normalizedT * 0.3).clamp(0.0, 1.0);
    var value = math.sin(math.pi * 2 * frequency * t) * 0.58;
    value += math.sin(math.pi * 2 * frequency * 2.76 * t + 0.2) * 0.24;
    value += math.sin(math.pi * 2 * frequency * 4.12 * t + 0.9) * 0.12;
    value += math.sin(math.pi * 2 * frequency * 5.43 * t + 1.8) * 0.06;
    return value * envelope;
  }

  static Uint8List _encodeWav(
    List<double> samples, {
    required int sampleRate,
    required double gain,
  }) {
    var peak = 0.000001;
    for (final sample in samples) {
      peak = math.max(peak, sample.abs());
    }
    final normalization = gain / peak;

    final byteData = ByteData(44 + samples.length * 2);
    void writeString(int offset, String value) {
      for (var i = 0; i < value.length; i += 1) {
        byteData.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    writeString(0, 'RIFF');
    byteData.setUint32(4, 36 + samples.length * 2, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little);
    byteData.setUint16(22, 1, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little);
    byteData.setUint16(34, 16, Endian.little);
    writeString(36, 'data');
    byteData.setUint32(40, samples.length * 2, Endian.little);

    var offset = 44;
    for (final sample in samples) {
      final normalized = (sample * normalization).clamp(-1.0, 1.0);
      byteData.setInt16(
        offset,
        (normalized * 32767).round().clamp(-32768, 32767),
        Endian.little,
      );
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }

  static double _smoothStep(double value) {
    final x = value.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  static double _softClip(double value) {
    final x = value.clamp(-3.0, 3.0);
    return x / (1 + x.abs());
  }
}

class _LoopEvent {
  const _LoopEvent(
    this.startSeconds,
    this.frequency,
    this.durationSeconds,
    this.volume,
    this.timbre,
  );

  final double startSeconds;
  final double frequency;
  final double durationSeconds;
  final double volume;
  final _LoopTimbre timbre;
}

enum _LoopTimbre { pluck, bell }

class _HarpPluckTone {
  const _HarpPluckTone({
    required this.attack,
    required this.decay,
    required this.feedback,
    required this.brightness,
    required this.transient,
    required this.bodyMix,
    required this.shimmer,
    required this.noise,
    required this.overtoneMix,
    required this.octaveBloom,
    required this.air,
    required this.bodyDetune,
    required this.bodyDecay,
    required this.outputGain,
  });

  final double attack;
  final double decay;
  final double feedback;
  final double brightness;
  final double transient;
  final double bodyMix;
  final double shimmer;
  final double noise;
  final double overtoneMix;
  final double octaveBloom;
  final double air;
  final double bodyDetune;
  final double bodyDecay;
  final double outputGain;
}

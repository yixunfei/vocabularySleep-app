import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:uuid/uuid.dart';

final AudioContext _ambientPlaybackContext = AudioContextConfig(
  focus: AudioContextConfigFocus.mixWithOthers,
  stayAwake: true,
).build();

class AmbientSource {
  const AmbientSource({
    required this.id,
    required this.name,
    this.assetPath,
    this.filePath,
    this.enabled = false,
    this.volume = 0.5,
  });

  final String id;
  final String name;
  final String? assetPath;
  final String? filePath;
  final bool enabled;
  final double volume;

  bool get isAsset => assetPath != null;

  AmbientSource copyWith({
    String? id,
    String? name,
    String? assetPath,
    String? filePath,
    bool? enabled,
    double? volume,
  }) {
    return AmbientSource(
      id: id ?? this.id,
      name: name ?? this.name,
      assetPath: assetPath ?? this.assetPath,
      filePath: filePath ?? this.filePath,
      enabled: enabled ?? this.enabled,
      volume: volume ?? this.volume,
    );
  }
}

typedef AmbientLoopPlayerFactory = AmbientLoopPlayer Function();

abstract class AmbientLoopPlayer {
  Future<void> setSource(Source source);
  Future<Duration?> getDuration();
  Future<void> setReleaseMode(ReleaseMode releaseMode);
  Future<void> setVolume(double volume);
  Future<void> resume();
  Future<void> stop();
  Future<void> dispose();
}

class AudioPlayerAmbientLoopPlayer implements AmbientLoopPlayer {
  AudioPlayerAmbientLoopPlayer([AudioPlayer? player])
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  bool _audioContextConfigured = false;

  Future<void> _ensureAudioContext() async {
    if (_audioContextConfigured) {
      return;
    }
    await _player.setAudioContext(_ambientPlaybackContext);
    _audioContextConfigured = true;
  }

  @override
  Future<void> setSource(Source source) async {
    await _ensureAudioContext();
    await _player.setSource(source);
  }

  @override
  Future<Duration?> getDuration() => _player.getDuration();

  @override
  Future<void> setReleaseMode(ReleaseMode releaseMode) {
    return _player.setReleaseMode(releaseMode);
  }

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

/// Keeps two preloaded players leapfrogging so ambient loops do not pause
/// audibly at the wraparound point.
class SeamlessAmbientLoop {
  SeamlessAmbientLoop({
    required this.source,
    required double initialVolume,
    AmbientLoopPlayerFactory? playerFactory,
    this.overlap = const Duration(milliseconds: 180),
    this.fadeInterval = const Duration(milliseconds: 45),
  }) : _playerFactory = playerFactory ?? (() => AudioPlayerAmbientLoopPlayer()),
       _targetVolume = initialVolume.clamp(0.0, 1.0);

  final Source source;
  final AmbientLoopPlayerFactory _playerFactory;
  final Duration overlap;
  final Duration fadeInterval;

  AmbientLoopPlayer? _firstPlayer;
  AmbientLoopPlayer? _secondPlayer;
  Duration? _trackDuration;
  Duration _effectiveOverlap = Duration.zero;
  double _targetVolume;
  int _activeIndex = 0;
  bool _disposed = false;
  bool _started = false;
  bool _usingNativeLoopFallback = false;
  int _runToken = 0;
  Timer? _handoffTimer;
  Timer? _fadeTimer;
  int? _fadeFromIndex;
  int? _fadeToIndex;
  double _fadeProgress = 0;

  Future<void> start() async {
    if (_disposed || _started) {
      return;
    }
    _started = true;
    _runToken += 1;
    final runToken = _runToken;

    final firstPlayer = _playerFactory();
    await _preparePlayer(firstPlayer);
    if (!_isRunActive(runToken)) {
      await firstPlayer.dispose();
      return;
    }

    final duration = await firstPlayer.getDuration();
    if (!_isRunActive(runToken)) {
      await firstPlayer.dispose();
      return;
    }

    _firstPlayer = firstPlayer;
    _trackDuration = duration;

    if (!_canUseSeamlessLoop(duration)) {
      _usingNativeLoopFallback = true;
      await firstPlayer.setReleaseMode(ReleaseMode.loop);
      await firstPlayer.setVolume(_targetVolume);
      await firstPlayer.resume();
      return;
    }

    final secondPlayer = _playerFactory();
    await _preparePlayer(secondPlayer);
    if (!_isRunActive(runToken)) {
      await firstPlayer.dispose();
      await secondPlayer.dispose();
      return;
    }

    _secondPlayer = secondPlayer;
    _effectiveOverlap = _resolveEffectiveOverlap(duration!);

    await firstPlayer.setVolume(_targetVolume);
    await secondPlayer.setVolume(0);
    await firstPlayer.resume();
    _scheduleNextHandoff(runToken);
  }

  Future<void> setTargetVolume(double value) async {
    _targetVolume = value.clamp(0.0, 1.0);
    if (_disposed || !_started) {
      return;
    }
    await _syncVolumes();
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _runToken += 1;
    _handoffTimer?.cancel();
    _fadeTimer?.cancel();
    _handoffTimer = null;
    _fadeTimer = null;
    _fadeFromIndex = null;
    _fadeToIndex = null;
    _fadeProgress = 0;

    final players = <AmbientLoopPlayer>[
      ...<AmbientLoopPlayer?>[_firstPlayer, _secondPlayer].nonNulls,
    ];
    _firstPlayer = null;
    _secondPlayer = null;
    _trackDuration = null;

    for (final player in players) {
      await player.stop();
      await player.dispose();
    }
  }

  bool _canUseSeamlessLoop(Duration? duration) {
    if (duration == null) {
      return false;
    }
    final minimumDurationMs =
        overlap.inMilliseconds * 2 + fadeInterval.inMilliseconds;
    return duration.inMilliseconds > minimumDurationMs;
  }

  Duration _resolveEffectiveOverlap(Duration duration) {
    final cappedOverlap = duration.inMilliseconds ~/ 4;
    final overlapMs = overlap.inMilliseconds.clamp(1, cappedOverlap);
    return Duration(milliseconds: overlapMs);
  }

  Future<void> _preparePlayer(AmbientLoopPlayer player) async {
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(source);
  }

  void _scheduleNextHandoff(int runToken) {
    final duration = _trackDuration;
    final secondPlayer = _secondPlayer;
    if (!_isRunActive(runToken) || duration == null || secondPlayer == null) {
      return;
    }

    final handoffDelay = duration - _effectiveOverlap;
    _handoffTimer?.cancel();
    _handoffTimer = Timer(handoffDelay, () {
      unawaited(_performHandoff(runToken));
    });
  }

  Future<void> _performHandoff(int runToken) async {
    if (!_isRunActive(runToken)) {
      return;
    }
    final fromIndex = _activeIndex;
    final toIndex = fromIndex == 0 ? 1 : 0;
    final fromPlayer = _playerByIndex(fromIndex);
    final toPlayer = _playerByIndex(toIndex);
    if (fromPlayer == null || toPlayer == null) {
      return;
    }

    await toPlayer.setVolume(0);
    await toPlayer.resume();
    if (!_isRunActive(runToken)) {
      return;
    }

    _activeIndex = toIndex;
    _fadeFromIndex = fromIndex;
    _fadeToIndex = toIndex;
    _fadeProgress = 0;
    _scheduleNextHandoff(runToken);
    _startFade(runToken);
  }

  void _startFade(int runToken) {
    final totalMs = _effectiveOverlap.inMilliseconds;
    final tickMs = fadeInterval.inMilliseconds.clamp(1, totalMs);
    final step = tickMs / totalMs;

    _fadeTimer?.cancel();
    _fadeTimer = Timer.periodic(Duration(milliseconds: tickMs), (timer) {
      _fadeProgress = (_fadeProgress + step).clamp(0.0, 1.0);
      unawaited(_syncVolumes());
      if (_fadeProgress >= 1) {
        timer.cancel();
        _fadeTimer = null;
        unawaited(_completeFade(runToken));
      }
    });
  }

  Future<void> _completeFade(int runToken) async {
    final fromPlayer = _fadeFromIndex == null
        ? null
        : _playerByIndex(_fadeFromIndex!);
    _fadeFromIndex = null;
    _fadeToIndex = null;
    _fadeProgress = 0;

    if (fromPlayer != null) {
      await fromPlayer.stop();
    }
    if (_isRunActive(runToken)) {
      await _syncVolumes();
    }
  }

  Future<void> _syncVolumes() async {
    final firstPlayer = _firstPlayer;
    if (firstPlayer == null) {
      return;
    }

    if (_usingNativeLoopFallback || _secondPlayer == null) {
      await firstPlayer.setVolume(_targetVolume);
      return;
    }

    final secondPlayer = _secondPlayer!;
    final fadeFromIndex = _fadeFromIndex;
    final fadeToIndex = _fadeToIndex;

    if (fadeFromIndex != null && fadeToIndex != null) {
      final fromVolume = _targetVolume * (1 - _fadeProgress);
      final toVolume = _targetVolume * _fadeProgress;
      final fromPlayer = _playerByIndex(fadeFromIndex);
      final toPlayer = _playerByIndex(fadeToIndex);
      if (fromPlayer != null) {
        await fromPlayer.setVolume(fromVolume);
      }
      if (toPlayer != null) {
        await toPlayer.setVolume(toVolume);
      }
      return;
    }

    if (_activeIndex == 0) {
      await firstPlayer.setVolume(_targetVolume);
      await secondPlayer.setVolume(0);
    } else {
      await firstPlayer.setVolume(0);
      await secondPlayer.setVolume(_targetVolume);
    }
  }

  AmbientLoopPlayer? _playerByIndex(int index) {
    return switch (index) {
      0 => _firstPlayer,
      1 => _secondPlayer,
      _ => null,
    };
  }

  bool _isRunActive(int runToken) {
    return !_disposed && _started && runToken == _runToken;
  }
}

class AmbientService {
  AmbientService({
    AmbientLoopPlayerFactory? playerFactory,
    Duration seamlessLoopOverlap = const Duration(milliseconds: 180),
  }) : _playerFactory = playerFactory ?? (() => AudioPlayerAmbientLoopPlayer()),
       _seamlessLoopOverlap = seamlessLoopOverlap {
    _sources = List<AmbientSource>.from(_builtInPresets);
  }

  final _uuid = const Uuid();
  final AmbientLoopPlayerFactory _playerFactory;
  final Duration _seamlessLoopOverlap;
  final Map<String, SeamlessAmbientLoop> _loops =
      <String, SeamlessAmbientLoop>{};

  double _masterVolume = 0.7;
  List<AmbientSource> _sources = <AmbientSource>[];

  static const List<AmbientSource> _builtInPresets = <AmbientSource>[
    AmbientSource(
      id: 'noise_white',
      name: 'White Noise',
      assetPath: 'ambient/noise/white-noise.wav',
      volume: 0.36,
    ),
    AmbientSource(
      id: 'noise_pink',
      name: 'Pink Noise',
      assetPath: 'ambient/noise/pink-noise.wav',
      volume: 0.34,
    ),
    AmbientSource(
      id: 'noise_brown',
      name: 'Brown Noise',
      assetPath: 'ambient/noise/brown-noise.wav',
      volume: 0.38,
    ),
    AmbientSource(
      id: 'nature_wind',
      name: 'Wind',
      assetPath: 'ambient/nature/wind.mp3',
      volume: 0.42,
    ),
    AmbientSource(
      id: 'nature_forest',
      name: 'Wind in Trees',
      assetPath: 'ambient/nature/wind-in-trees.mp3',
      volume: 0.42,
    ),
    AmbientSource(
      id: 'nature_fire',
      name: 'Campfire',
      assetPath: 'ambient/nature/campfire.mp3',
      volume: 0.45,
    ),
    AmbientSource(
      id: 'nature_ocean',
      name: 'Waves',
      assetPath: 'ambient/nature/waves.mp3',
      volume: 0.45,
    ),
    AmbientSource(
      id: 'rain_light',
      name: 'Light Rain',
      assetPath: 'ambient/rain/light-rain.mp3',
      volume: 0.4,
    ),
    AmbientSource(
      id: 'rain_heavy',
      name: 'Heavy Rain',
      assetPath: 'ambient/rain/heavy-rain.mp3',
      volume: 0.36,
    ),
    AmbientSource(
      id: 'focus_library',
      name: 'Library',
      assetPath: 'ambient/places/library.mp3',
      volume: 0.45,
    ),
    AmbientSource(
      id: 'focus_cafe',
      name: 'Cafe',
      assetPath: 'ambient/places/cafe.mp3',
      volume: 0.44,
    ),
    AmbientSource(
      id: 'focus_night',
      name: 'Night Village',
      assetPath: 'ambient/places/night-village.mp3',
      volume: 0.4,
    ),
  ];

  List<AmbientSource> get sources => List<AmbientSource>.from(_sources);
  double get masterVolume => _masterVolume;

  void setMasterVolume(double value) {
    _masterVolume = value.clamp(0.0, 1.0);
    for (final source in _sources.where((item) => item.enabled)) {
      final loop = _loops[source.id];
      if (loop == null) {
        continue;
      }
      unawaited(loop.setTargetVolume(_resolvedVolume(source)));
    }
  }

  void setSourceEnabled(String sourceId, bool enabled) {
    _sources = _sources.map((source) {
      if (source.id != sourceId) return source;
      return source.copyWith(enabled: enabled);
    }).toList();
  }

  void setSourceVolume(String sourceId, double value) {
    final volume = value.clamp(0.0, 1.0);
    _sources = _sources.map((source) {
      if (source.id != sourceId) return source;
      return source.copyWith(volume: volume);
    }).toList();
    final loop = _loops[sourceId];
    final source = _sources
        .where((item) => item.id == sourceId)
        .cast<AmbientSource?>()
        .firstOrNull;
    if (loop != null && source != null) {
      unawaited(loop.setTargetVolume(_resolvedVolume(source)));
    }
  }

  void addFileSource(String path, {String? name}) {
    final fileName = name ?? path.split(RegExp(r'[\\/]')).last;
    _sources = <AmbientSource>[
      ..._sources,
      AmbientSource(
        id: 'file_${_uuid.v4()}',
        name: fileName,
        filePath: path,
        enabled: true,
        volume: 0.5,
      ),
    ];
  }

  void removeSource(String sourceId) {
    _sources = _sources.where((source) => source.id != sourceId).toList();
    final loop = _loops.remove(sourceId);
    if (loop != null) {
      unawaited(loop.dispose());
    }
  }

  Future<void> syncPlayback() async {
    final enabledSources = _sources.where((source) => source.enabled).toList();
    final enabledIds = enabledSources.map((source) => source.id).toSet();

    for (final entry in _loops.entries.toList()) {
      if (enabledIds.contains(entry.key)) {
        continue;
      }
      await entry.value.dispose();
      _loops.remove(entry.key);
    }

    for (final source in enabledSources) {
      final targetVolume = _resolvedVolume(source);
      final existingLoop = _loops[source.id];
      if (existingLoop != null) {
        await existingLoop.setTargetVolume(targetVolume);
        continue;
      }

      final playbackSource = _toPlaybackSource(source);
      if (playbackSource == null) {
        continue;
      }

      final loop = SeamlessAmbientLoop(
        source: playbackSource,
        initialVolume: targetVolume,
        playerFactory: _playerFactory,
        overlap: _seamlessLoopOverlap,
      );
      await loop.start();
      _loops[source.id] = loop;
    }
  }

  Future<void> stopAll() async {
    for (final loop in _loops.values) {
      await loop.dispose();
    }
    _loops.clear();
  }

  Future<void> reset() async {
    await stopAll();
    _masterVolume = 0.7;
    _sources = List<AmbientSource>.from(_builtInPresets);
  }

  Source? _toPlaybackSource(AmbientSource source) {
    if (source.assetPath != null) {
      return AssetSource(source.assetPath!);
    }
    if (source.filePath != null) {
      return DeviceFileSource(source.filePath!);
    }
    return null;
  }

  double _resolvedVolume(AmbientSource source) {
    final merged = source.volume * _masterVolume;
    return merged.clamp(0.0, 1.0);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}

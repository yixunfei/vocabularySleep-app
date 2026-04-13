import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'audio_player_source_helper.dart';
import 'app_log_service.dart';
import 'cstcloud_resource_cache_service.dart';

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
    this.remoteUrl,
    this.remoteKey,
    this.categoryKey,
    this.builtIn = false,
    this.enabled = false,
    this.volume = 0.5,
  });

  final String id;
  final String name;
  final String? assetPath;
  final String? filePath;
  final String? remoteUrl;
  final String? remoteKey;
  final String? categoryKey;
  final bool builtIn;
  final bool enabled;
  final double volume;

  bool get isAsset => assetPath != null;
  bool get isFile => filePath != null;
  bool get isRemote => remoteUrl != null;
  bool get isBuiltIn => builtIn;

  AmbientSource copyWith({
    String? id,
    String? name,
    String? assetPath,
    String? filePath,
    String? remoteUrl,
    String? remoteKey,
    String? categoryKey,
    bool? builtIn,
    bool? enabled,
    double? volume,
  }) {
    return AmbientSource(
      id: id ?? this.id,
      name: name ?? this.name,
      assetPath: assetPath ?? this.assetPath,
      filePath: filePath ?? this.filePath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      remoteKey: remoteKey ?? this.remoteKey,
      categoryKey: categoryKey ?? this.categoryKey,
      builtIn: builtIn ?? this.builtIn,
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
    await AudioPlayerSourceHelper.setSource(
      _player,
      source,
      tag: 'ambient_audio',
      data: <String, Object?>{'playerId': _player.playerId},
    );
  }

  @override
  Future<Duration?> getDuration() async {
    final duration = await AudioPlayerSourceHelper.waitForDuration(
      _player,
      tag: 'ambient_audio',
      data: <String, Object?>{'playerId': _player.playerId},
    );
    return duration;
  }

  @override
  Future<void> setReleaseMode(ReleaseMode releaseMode) {
    return _player.setReleaseMode(releaseMode);
  }

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> resume() async {
    await _player.resume();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
  }
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
    AppLogService.instance.d(
      'ambient_audio',
      'seamless loop start',
      data: <String, Object?>{
        'runToken': runToken,
        'sourceType': source.runtimeType.toString(),
        'initialVolume': _targetVolume,
      },
    );

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
    AppLogService.instance.d(
      'ambient_audio',
      'first ambient player prepared',
      data: <String, Object?>{
        'runToken': runToken,
        'durationMs': duration?.inMilliseconds,
      },
    );

    if (!_canUseSeamlessLoop(duration)) {
      _usingNativeLoopFallback = true;
      AppLogService.instance.w(
        'ambient_audio',
        'ambient loop falling back to native loop',
        data: <String, Object?>{
          'runToken': runToken,
          'durationMs': duration?.inMilliseconds,
        },
      );
      await firstPlayer.setReleaseMode(ReleaseMode.loop);
      await firstPlayer.setVolume(_targetVolume);
      // CRITICAL FIX: Wait for player to be ready before resuming
      await _playerReady(firstPlayer);
      if (!_isRunActive(runToken)) {
        await firstPlayer.dispose();
        return;
      }
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
    AppLogService.instance.d(
      'ambient_audio',
      'second ambient player prepared',
      data: <String, Object?>{
        'runToken': runToken,
        'durationMs': duration.inMilliseconds,
        'effectiveOverlapMs': _effectiveOverlap.inMilliseconds,
      },
    );

    await firstPlayer.setVolume(_targetVolume);
    await secondPlayer.setVolume(0);

    // CRITICAL FIX: Wait for player to be ready before resuming.
    // Without this, resume() may be called before the audio source is loaded,
    // causing no sound output, especially on Windows.
    await _playerReady(firstPlayer);
    if (!_isRunActive(runToken)) {
      await firstPlayer.dispose();
      await secondPlayer.dispose();
      return;
    }

    await firstPlayer.resume();
    _scheduleNextHandoff(runToken);
  }

  Future<void> setTargetVolume(double value) async {
    _targetVolume = value.clamp(0.0, 1.0);
    AppLogService.instance.d(
      'ambient_audio',
      'ambient loop target volume updated',
      data: <String, Object?>{'targetVolume': _targetVolume},
    );
    if (_disposed || !_started) {
      return;
    }
    await _syncVolumes();
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    AppLogService.instance.d('ambient_audio', 'seamless loop dispose start');
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
    AppLogService.instance.d('ambient_audio', 'seamless loop dispose complete');
  }

  bool _canUseSeamlessLoop(Duration? duration) {
    if (duration == null) {
      return false;
    }
    final minimumDurationMs =
        overlap.inMilliseconds * 2 + fadeInterval.inMilliseconds;
    return duration.inMilliseconds > minimumDurationMs;
  }

  /// Check if a player is ready for playback by verifying duration is available.
  /// This is critical for Windows where audio initialization takes longer.
  Future<bool> _playerReady(AmbientLoopPlayer player) async {
    try {
      final duration = await player.getDuration();
      final ready = duration != null && duration.inMilliseconds > 0;
      AppLogService.instance.d(
        'ambient_audio',
        'player ready check',
        data: <String, Object?>{
          'ready': ready,
          'durationMs': duration?.inMilliseconds,
        },
      );
      return ready;
    } catch (error) {
      AppLogService.instance.w(
        'ambient_audio',
        'player ready check failed',
        data: <String, Object?>{'error': '$error'},
      );
      return false;
    }
  }

  Duration _resolveEffectiveOverlap(Duration duration) {
    final cappedOverlap = duration.inMilliseconds ~/ 4;
    final overlapMs = overlap.inMilliseconds.clamp(1, cappedOverlap);
    return Duration(milliseconds: overlapMs);
  }

  Future<void> _preparePlayer(AmbientLoopPlayer player) async {
    AppLogService.instance.d('ambient_audio', 'prepare ambient player start');
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(source);
    AppLogService.instance.d(
      'ambient_audio',
      'prepare ambient player complete',
    );
  }

  void _scheduleNextHandoff(int runToken) {
    final duration = _trackDuration;
    final secondPlayer = _secondPlayer;
    if (!_isRunActive(runToken) || duration == null || secondPlayer == null) {
      return;
    }

    final handoffDelay = duration - _effectiveOverlap;
    AppLogService.instance.d(
      'ambient_audio',
      'schedule ambient handoff',
      data: <String, Object?>{
        'runToken': runToken,
        'handoffDelayMs': handoffDelay.inMilliseconds,
        'effectiveOverlapMs': _effectiveOverlap.inMilliseconds,
      },
    );
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
    AppLogService.instance.d(
      'ambient_audio',
      'ambient handoff started',
      data: <String, Object?>{
        'runToken': runToken,
        'fromIndex': fromIndex,
        'toIndex': toIndex,
      },
    );
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
    AppLogService.instance.d(
      'ambient_audio',
      'ambient fade complete',
      data: <String, Object?>{
        'runToken': runToken,
        'activeIndex': _activeIndex,
      },
    );
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
    CstCloudResourceCacheService? resourceCache,
  }) : _playerFactory = playerFactory ?? (() => AudioPlayerAmbientLoopPlayer()),
       _seamlessLoopOverlap = seamlessLoopOverlap,
       _resourceCache = resourceCache {
    _sources = List<AmbientSource>.from(_builtInPresets);
  }

  final _uuid = const Uuid();
  final AmbientLoopPlayerFactory _playerFactory;
  final Duration _seamlessLoopOverlap;
  final CstCloudResourceCacheService? _resourceCache;
  final AppLogService _log = AppLogService.instance;
  final Map<String, SeamlessAmbientLoop> _loops =
      <String, SeamlessAmbientLoop>{};

  bool _enabled = true;
  double _masterVolume = 0.7;
  List<AmbientSource> _sources = <AmbientSource>[];
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    await _scanDownloadedAmbientSources();
    _initialized = true;
  }

  Future<void> _scanDownloadedAmbientSources() async {
    final resourceCache = _resourceCache;
    if (resourceCache == null) {
      return;
    }
    try {
      final hasDownloaded = await resourceCache.hasCachedFilesUnderPrefix(
        'ambient/moodist',
      );
      if (!hasDownloaded) {
        return;
      }
      final ambientRoot = 'ambient/moodist/noise';
      final noiseDir = Directory(await _getCachePath(ambientRoot));
      if (await noiseDir.exists()) {
        await for (final entity in noiseDir.list(
          recursive: false,
          followLinks: false,
        )) {
          if (entity is! File) {
            continue;
          }
          final fileName = p.basename(entity.path);
          if (!fileName.endsWith('.wav') && !fileName.endsWith('.mp3')) {
            continue;
          }
          final slug = fileName.replaceFirst(RegExp(r'\.(wav|mp3)$'), '');
          final id = 'downloaded_noise_$slug';
          if (_sources.any((s) => s.id == id)) {
            continue;
          }
          _sources = <AmbientSource>[
            ..._sources,
            AmbientSource(
              id: id,
              name: _humanizeSlug(slug),
              filePath: entity.path,
              enabled: false,
              volume: 0.5,
              categoryKey: 'ambientCategoryNoise',
            ),
          ];
        }
      }
    } catch (error, stackTrace) {
      _log.w(
        'ambient',
        'failed to scan downloaded ambient sources: $error',
        data: <String, Object?>{'error': '$error', 'stackTrace': '$stackTrace'},
      );
    }
  }

  Future<String> _getCachePath(String relativePath) async {
    final supportDir = await getApplicationSupportDirectory();
    return p.join(supportDir.path, 'remote_resource_cache', relativePath);
  }

  String _humanizeSlug(String slug) {
    return slug
        .split('-')
        .where((part) => part.trim().isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  static const List<AmbientSource> _builtInPresets = <AmbientSource>[
    AmbientSource(
      id: 'noise_white',
      name: 'White noise',
      assetPath: 'ambient/noise/white-noise.wav',
      remoteKey: 'ambient/moodist/noise/white-noise.wav',
      categoryKey: 'ambientCategoryNoise',
      builtIn: true,
      volume: 0.36,
    ),
    AmbientSource(
      id: 'noise_pink',
      name: 'Pink noise',
      assetPath: 'ambient/noise/pink-noise.wav',
      remoteKey: 'ambient/moodist/noise/pink-noise.wav',
      categoryKey: 'ambientCategoryNoise',
      builtIn: true,
      volume: 0.36,
    ),
    AmbientSource(
      id: 'noise_brown',
      name: 'Brown noise',
      assetPath: 'ambient/noise/brown-noise.wav',
      remoteKey: 'ambient/moodist/noise/brown-noise.wav',
      categoryKey: 'ambientCategoryNoise',
      builtIn: true,
      volume: 0.34,
    ),
    AmbientSource(
      id: 'nature_wind',
      name: 'Wind',
      assetPath: 'ambient/nature/wind.wav',
      remoteKey: 'ambient/moodist/nature/wind.wav',
      categoryKey: 'ambientCategoryNature',
      builtIn: true,
      volume: 0.42,
    ),
    AmbientSource(
      id: 'nature_forest',
      name: 'Forest',
      assetPath: 'ambient/nature/wind-in-trees.wav',
      remoteKey: 'ambient/moodist/nature/wind-in-trees.wav',
      categoryKey: 'ambientCategoryNature',
      builtIn: true,
      volume: 0.42,
    ),
    AmbientSource(
      id: 'nature_fire',
      name: 'Campfire',
      assetPath: 'ambient/nature/campfire.wav',
      remoteKey: 'ambient/moodist/nature/campfire.wav',
      categoryKey: 'ambientCategoryNature',
      builtIn: true,
      volume: 0.4,
    ),
    AmbientSource(
      id: 'nature_ocean',
      name: 'Waves',
      assetPath: 'ambient/nature/waves.wav',
      remoteKey: 'ambient/moodist/nature/waves.wav',
      categoryKey: 'ambientCategoryNature',
      builtIn: true,
      volume: 0.42,
    ),
    AmbientSource(
      id: 'rain_light',
      name: 'Light rain',
      assetPath: 'ambient/rain/light-rain.wav',
      remoteKey: 'ambient/moodist/rain/light-rain.wav',
      categoryKey: 'ambientCategoryRain',
      builtIn: true,
      volume: 0.38,
    ),
    AmbientSource(
      id: 'rain_heavy',
      name: 'Heavy rain',
      assetPath: 'ambient/rain/heavy-rain.wav',
      remoteKey: 'ambient/moodist/rain/heavy-rain.wav',
      categoryKey: 'ambientCategoryRain',
      builtIn: true,
      volume: 0.38,
    ),
    AmbientSource(
      id: 'focus_library',
      name: 'Library',
      assetPath: 'ambient/places/library.wav',
      remoteKey: 'ambient/moodist/places/library.wav',
      categoryKey: 'ambientCategoryFocus',
      builtIn: true,
      volume: 0.4,
    ),
    AmbientSource(
      id: 'focus_cafe',
      name: 'Cafe',
      assetPath: 'ambient/places/cafe.wav',
      remoteKey: 'ambient/moodist/places/cafe.wav',
      categoryKey: 'ambientCategoryFocus',
      builtIn: true,
      volume: 0.4,
    ),
    AmbientSource(
      id: 'focus_night',
      name: 'Night road',
      assetPath: 'ambient/urban/road.wav',
      remoteKey: 'ambient/moodist/urban/road.wav',
      categoryKey: 'ambientCategoryFocus',
      builtIn: true,
      volume: 0.4,
    ),
  ];

  List<AmbientSource> get sources => List<AmbientSource>.from(_sources);
  bool get isEnabled => _enabled;
  double get masterVolume => _masterVolume;

  void setEnabled(bool value) {
    _enabled = value;
  }

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
    addFileSourceWithMetadata(path, name: fileName);
  }

  void addFileSourceWithMetadata(
    String path, {
    String? id,
    String? name,
    String? categoryKey,
    double volume = 0.5,
    bool enabled = true,
  }) {
    final fileName = name ?? path.split(RegExp(r'[\\/]')).last;
    final sourceId = id ?? 'file_${_uuid.v4()}';
    final source = AmbientSource(
      id: sourceId,
      name: fileName,
      filePath: path,
      categoryKey: categoryKey,
      enabled: enabled,
      volume: volume.clamp(0.0, 1.0),
    );
    final existingIndex = _sources.indexWhere((item) => item.id == sourceId);
    if (existingIndex < 0) {
      _sources = <AmbientSource>[..._sources, source];
      return;
    }
    final updated = List<AmbientSource>.from(_sources);
    updated[existingIndex] = source;
    _sources = updated;
  }

  void addRemoteSource({
    required String id,
    required String name,
    required String remoteUrl,
    required String categoryKey,
    double volume = 0.5,
  }) {
    final normalizedVolume = volume.clamp(0.0, 1.0);
    final existingIndex = _sources.indexWhere((source) => source.id == id);
    final nextSource = AmbientSource(
      id: id,
      name: name,
      remoteUrl: remoteUrl,
      categoryKey: categoryKey,
      enabled: true,
      volume: normalizedVolume,
    );
    if (existingIndex < 0) {
      _sources = <AmbientSource>[..._sources, nextSource];
      return;
    }
    final updated = List<AmbientSource>.from(_sources);
    updated[existingIndex] = nextSource;
    _sources = updated;
  }

  void removeSource(String sourceId) {
    _sources = _sources.where((source) => source.id != sourceId).toList();
    final loop = _loops.remove(sourceId);
    if (loop != null) {
      unawaited(loop.dispose());
    }
  }

  Future<void> syncPlayback() async {
    if (!_enabled) {
      await stopAll();
      return;
    }

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

      final playbackSource = await _toPlaybackSource(source);
      if (playbackSource == null) {
        _log.w(
          'ambient',
          'ambient source skipped because no playback source was resolved',
          data: <String, Object?>{
            'sourceId': source.id,
            'assetPath': source.assetPath,
            'filePath': source.filePath,
            'remoteUrl': source.remoteUrl,
            'remoteKey': source.remoteKey,
          },
        );
        continue;
      }

      final loop = SeamlessAmbientLoop(
        source: playbackSource,
        initialVolume: targetVolume,
        playerFactory: _playerFactory,
        overlap: _seamlessLoopOverlap,
      );
      try {
        await loop.start().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException(
              'Ambient loop start timed out after 15 seconds',
              const Duration(seconds: 15),
            );
          },
        );
        _loops[source.id] = loop;
      } on TimeoutException catch (error, stackTrace) {
        await loop.dispose();
        _log.e(
          'ambient',
          'ambient source start timed out - file may be corrupted or incompatible',
          error: error,
          stackTrace: stackTrace,
          data: <String, Object?>{
            'sourceId': source.id,
            'assetPath': source.assetPath,
            'filePath': source.filePath,
            'timeoutSeconds': 15,
          },
        );
      } catch (error, stackTrace) {
        await loop.dispose();
        _log.e(
          'ambient',
          'ambient source start failed',
          error: error,
          stackTrace: stackTrace,
          data: <String, Object?>{
            'sourceId': source.id,
            'assetPath': source.assetPath,
            'filePath': source.filePath,
            'remoteUrl': source.remoteUrl,
            'remoteKey': source.remoteKey,
          },
        );
      }
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
    _enabled = true;
    _masterVolume = 0.7;
    _sources = List<AmbientSource>.from(_builtInPresets);
  }

  Future<Source?> _toPlaybackSource(AmbientSource source) async {
    final remoteKey = source.remoteKey?.trim();
    final resourceCache = _resourceCache;
    if ((remoteKey ?? '').isNotEmpty && resourceCache != null) {
      try {
        final file = await resourceCache.ensureFileDownloaded(
          remoteKey!,
          cacheRelativePath: remoteKey,
        );
        if (await file.exists() && await file.length() > 0) {
          final filePath = file.path;
          _rememberResolvedFilePath(source.id, filePath);
          return DeviceFileSource(filePath);
        } else {
          _log.w(
            'ambient',
            'downloaded file does not exist or is empty',
            data: <String, Object?>{
              'sourceId': source.id,
              'path': file.path,
              'exists': await file.exists(),
              'length': await file.length(),
            },
          );
        }
      } catch (error, stackTrace) {
        _log.w(
          'ambient',
          'built-in ambient download failed; using fallback if available',
          data: <String, Object?>{
            'sourceId': source.id,
            'remoteKey': remoteKey,
            'error': '$error',
          },
        );
        _log.e(
          'ambient',
          'built-in ambient remote load detail',
          error: error,
          stackTrace: stackTrace,
          data: <String, Object?>{
            'sourceId': source.id,
            'remoteKey': remoteKey,
            'temporaryDiagnostic': 'remove_after_ambient_s3_rollout_stabilizes',
          },
        );
      }
    }
    if (source.filePath != null) {
      final file = File(source.filePath!);
      final exists = await file.exists();
      final length = exists ? await file.length() : 0;
      if (exists && length > 0) {
        return DeviceFileSource(source.filePath!);
      } else {
        _log.w(
          'ambient',
          'local file does not exist or is empty',
          data: <String, Object?>{
            'sourceId': source.id,
            'path': source.filePath,
            'exists': exists,
            'length': length,
          },
        );
      }
    }
    if (source.assetPath != null) {
      return AssetSource(source.assetPath!);
    }
    if (source.remoteUrl != null) {
      return UrlSource(source.remoteUrl!);
    }
    _log.e(
      'ambient',
      'ambient source could not be resolved to any source type',
      data: <String, Object?>{
        'sourceId': source.id,
        'assetPath': source.assetPath,
        'filePath': source.filePath,
        'remoteUrl': source.remoteUrl,
        'remoteKey': source.remoteKey,
      },
    );
    return null;
  }

  void _rememberResolvedFilePath(String sourceId, String path) {
    final index = _sources.indexWhere((source) => source.id == sourceId);
    if (index < 0) {
      return;
    }
    final current = _sources[index];
    if ((current.filePath ?? '').trim() == path.trim()) {
      return;
    }
    final updated = List<AmbientSource>.from(_sources);
    updated[index] = current.copyWith(filePath: path);
    _sources = updated;
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

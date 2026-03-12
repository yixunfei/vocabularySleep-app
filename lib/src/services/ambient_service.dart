import 'package:audioplayers/audioplayers.dart';
import 'package:uuid/uuid.dart';

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

class AmbientService {
  AmbientService() {
    _sources = List<AmbientSource>.from(_builtInPresets);
  }

  final _uuid = const Uuid();
  final Map<String, AudioPlayer> _players = <String, AudioPlayer>{};

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
      final player = _players[source.id];
      if (player == null) continue;
      player.setVolume(_resolvedVolume(source));
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
    final player = _players[sourceId];
    final source = _sources
        .where((item) => item.id == sourceId)
        .cast<AmbientSource?>()
        .firstOrNull;
    if (player != null && source != null) {
      player.setVolume(_resolvedVolume(source));
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
    final player = _players.remove(sourceId);
    player?.stop();
    player?.dispose();
  }

  Future<void> syncPlayback() async {
    final enabledSources = _sources.where((source) => source.enabled).toList();
    final enabledIds = enabledSources.map((source) => source.id).toSet();

    for (final entry in _players.entries.toList()) {
      if (enabledIds.contains(entry.key)) continue;
      await entry.value.stop();
      await entry.value.dispose();
      _players.remove(entry.key);
    }

    for (final source in enabledSources) {
      if (_players.containsKey(source.id)) {
        await _players[source.id]!.setVolume(_resolvedVolume(source));
        continue;
      }
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(_resolvedVolume(source));
      if (source.assetPath != null) {
        await player.play(AssetSource(source.assetPath!));
      } else if (source.filePath != null) {
        await player.play(DeviceFileSource(source.filePath!));
      }
      _players[source.id] = player;
    }
  }

  Future<void> stopAll() async {
    for (final player in _players.values) {
      await player.stop();
      await player.dispose();
    }
    _players.clear();
  }

  Future<void> reset() async {
    await stopAll();
    _masterVolume = 0.7;
    _sources = List<AmbientSource>.from(_builtInPresets);
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

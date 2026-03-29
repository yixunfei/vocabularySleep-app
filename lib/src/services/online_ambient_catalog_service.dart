import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'cstcloud_resource_cache_service.dart';

class OnlineAmbientSoundOption {
  const OnlineAmbientSoundOption({
    required this.id,
    required this.name,
    required this.categoryKey,
    required this.relativePath,
    required this.remoteKey,
    this.defaultVolume = 0.5,
  });

  final String id;
  final String name;
  final String categoryKey;
  final String relativePath;
  final String remoteKey;
  final double defaultVolume;
}

class OnlineAmbientCatalogService {
  OnlineAmbientCatalogService({CstCloudResourceCacheService? cacheService})
    : _cacheService = cacheService ?? CstCloudResourceCacheService();

  static const String remotePrefix = 'ambient/moodist/';
  final CstCloudResourceCacheService _cacheService;
  List<OnlineAmbientSoundOption>? _cachedCatalog;

  static const List<OnlineAmbientSoundOption> fallbackOptions =
      <OnlineAmbientSoundOption>[
        OnlineAmbientSoundOption(
          id: 'ambient_noise_white_noise',
          name: 'White Noise',
          categoryKey: 'ambientCategoryNoise',
          relativePath: 'noise/white-noise.wav',
          remoteKey: '${remotePrefix}noise/white-noise.wav',
          defaultVolume: 0.36,
        ),
        OnlineAmbientSoundOption(
          id: 'ambient_noise_pink_noise',
          name: 'Pink Noise',
          categoryKey: 'ambientCategoryNoise',
          relativePath: 'noise/pink-noise.wav',
          remoteKey: '${remotePrefix}noise/pink-noise.wav',
          defaultVolume: 0.34,
        ),
        OnlineAmbientSoundOption(
          id: 'ambient_noise_brown_noise',
          name: 'Brown Noise',
          categoryKey: 'ambientCategoryNoise',
          relativePath: 'noise/brown-noise.wav',
          remoteKey: '${remotePrefix}noise/brown-noise.wav',
          defaultVolume: 0.38,
        ),
        OnlineAmbientSoundOption(
          id: 'ambient_rain_rain_on_window',
          name: 'Rain on Window',
          categoryKey: 'ambientCategoryRain',
          relativePath: 'rain/rain-on-window.mp3',
          remoteKey: '${remotePrefix}rain/rain-on-window.mp3',
          defaultVolume: 0.38,
        ),
        OnlineAmbientSoundOption(
          id: 'ambient_nature_waterfall',
          name: 'Waterfall',
          categoryKey: 'ambientCategoryNature',
          relativePath: 'nature/waterfall.mp3',
          remoteKey: '${remotePrefix}nature/waterfall.mp3',
          defaultVolume: 0.42,
        ),
        OnlineAmbientSoundOption(
          id: 'ambient_places_airport',
          name: 'Airport',
          categoryKey: 'ambientCategoryFocus',
          relativePath: 'places/airport.mp3',
          remoteKey: '${remotePrefix}places/airport.mp3',
          defaultVolume: 0.4,
        ),
      ];

  Future<List<OnlineAmbientSoundOption>> fetchCatalog({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedCatalog != null) {
      return _cachedCatalog!;
    }

    try {
      final remoteOptions = await _fetchCatalogFromS3();
      if (remoteOptions.isNotEmpty) {
        _cachedCatalog = remoteOptions;
        return remoteOptions;
      }
    } catch (_) {
      // Fall through to bundled fallback list.
    }

    _cachedCatalog = fallbackOptions;
    return fallbackOptions;
  }

  Future<String> localPathFor(OnlineAmbientSoundOption option) async {
    final targetDirectory = await _ensureCacheRootDirectory();
    return p.join(
      targetDirectory.path,
      option.remoteKey.replaceAll('/', Platform.pathSeparator),
    );
  }

  Future<bool> isDownloaded(OnlineAmbientSoundOption option) async {
    final targetPath = await localPathFor(option);
    final file = File(targetPath);
    return await file.exists() && await file.length() > 0;
  }

  Future<void> deleteLocal(OnlineAmbientSoundOption option) async {
    final targetPath = await localPathFor(option);
    final file = File(targetPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Set<String>> listDownloadedRelativePaths() async {
    final root = await _ensureCacheRootDirectory();
    final ambientRoot = Directory(
      p.join(root.path, remotePrefix.replaceAll('/', Platform.pathSeparator)),
    );
    if (!await ambientRoot.exists()) {
      return <String>{};
    }
    if (!await root.exists()) {
      return <String>{};
    }
    final output = <String>{};
    await for (final entity in ambientRoot.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) {
        continue;
      }
      final relative = p.relative(entity.path, from: ambientRoot.path);
      if (relative.trim().isEmpty) {
        continue;
      }
      output.add(relative.replaceAll(Platform.pathSeparator, '/'));
    }
    return output;
  }

  Future<String> downloadToLocal(OnlineAmbientSoundOption option) async {
    final file = await _cacheService.ensureFileDownloaded(
      option.remoteKey,
      cacheRelativePath: option.remoteKey,
    );
    return file.path;
  }

  Future<List<OnlineAmbientSoundOption>> _fetchCatalogFromS3() async {
    final objects = await _cacheService.listObjects(remotePrefix);
    final options = <OnlineAmbientSoundOption>[];
    for (final item in objects) {
      final path = item.key.trim();
      if (path.isEmpty ||
          path.endsWith('/') ||
          !path.startsWith(remotePrefix) ||
          !(path.endsWith('.mp3') || path.endsWith('.wav'))) {
        continue;
      }
      final relativePath = path.substring(remotePrefix.length);
      final parts = relativePath.split('/');
      if (parts.length < 2) {
        continue;
      }
      final categorySlug = parts.first.trim();
      final fileName = parts.last.trim();
      if (categorySlug.isEmpty || fileName.isEmpty) {
        continue;
      }
      final slug = fileName.replaceFirst(RegExp(r'\.(mp3|wav)$'), '');
      options.add(
        OnlineAmbientSoundOption(
          id: 'ambient_${categorySlug}_$slug',
          name: _humanizeSlug(slug),
          categoryKey: _categoryKeyForSlug(categorySlug),
          relativePath: relativePath,
          remoteKey: path,
          defaultVolume: _defaultVolumeForCategory(categorySlug),
        ),
      );
    }
    options.sort((a, b) => a.relativePath.compareTo(b.relativePath));
    return options;
  }

  String _categoryKeyForSlug(String categorySlug) {
    return switch (categorySlug) {
      'nature' => 'ambientCategoryNature',
      'rain' => 'ambientCategoryRain',
      'noise' => 'ambientCategoryNoise',
      'animals' => 'ambientCategoryAnimals',
      'urban' => 'ambientCategoryUrban',
      'places' => 'ambientCategoryPlaces',
      'transport' => 'ambientCategoryTransport',
      'things' => 'ambientCategoryThings',
      'binaural' => 'ambientCategoryBinaural',
      _ => 'ambientCategoryFocus',
    };
  }

  double _defaultVolumeForCategory(String categorySlug) {
    return switch (categorySlug) {
      'noise' => 0.36,
      'rain' => 0.38,
      'nature' => 0.42,
      _ => 0.4,
    };
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

  Future<Directory> _ensureCacheRootDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    final cacheDir = Directory(
      p.join(supportDir.path, 'remote_resource_cache'),
    );
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }
}

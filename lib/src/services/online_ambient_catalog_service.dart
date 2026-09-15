import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

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
  Future<List<OnlineAmbientSoundOption>>? _catalogRequest;
  bool _disposed = false;

  static const List<OnlineAmbientSoundOption> fallbackOptions =
      <OnlineAmbientSoundOption>[];

  void _checkActive() {
    if (_disposed) {
      throw StateError('Online ambient catalog service is disposed.');
    }
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _cachedCatalog = null;
    unawaited(
      _cacheService.close().catchError((Object _) {
        // Disposal must not surface an unhandled asynchronous close error.
      }),
    );
  }

  Future<List<OnlineAmbientSoundOption>> fetchCatalog({
    bool forceRefresh = false,
  }) {
    _checkActive();
    if (!forceRefresh && _cachedCatalog != null) {
      return Future<List<OnlineAmbientSoundOption>>.value(_cachedCatalog);
    }
    final existing = _catalogRequest;
    if (existing != null) {
      return existing;
    }
    final request = _fetchCatalogAndCache();
    _catalogRequest = request;
    return request.whenComplete(() {
      if (identical(_catalogRequest, request)) {
        _catalogRequest = null;
      }
    });
  }

  Future<List<OnlineAmbientSoundOption>> _fetchCatalogAndCache() async {
    try {
      final remoteOptions = await _fetchCatalogFromS3();
      _checkActive();
      if (remoteOptions.isNotEmpty) {
        _cachedCatalog = remoteOptions;
        return remoteOptions;
      }
    } catch (_) {
      if (_disposed) {
        rethrow;
      }
    }
    _checkActive();
    _cachedCatalog = fallbackOptions;
    return fallbackOptions;
  }

  Future<String> localPathFor(OnlineAmbientSoundOption option) async {
    _checkActive();
    final relativePath = _cacheService.normalizeCacheRelativePath(
      option.remoteKey,
      cacheRelativePath: option.remoteKey,
    );
    final targetDirectory = await _cacheService.resolveCacheDirectory();
    _checkActive();
    return p.join(targetDirectory.path, relativePath);
  }

  Future<bool> isDownloaded(OnlineAmbientSoundOption option) async {
    _checkActive();
    final targetPath = await localPathFor(option);
    _checkActive();
    final file = File(targetPath);
    return await file.exists() && await file.length() > 0;
  }

  Future<void> deleteLocal(OnlineAmbientSoundOption option) async {
    _checkActive();
    final targetPath = await localPathFor(option);
    _checkActive();
    final file = File(targetPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Set<String>> listDownloadedRelativePaths() async {
    _checkActive();
    final root = await _cacheService.resolveCacheDirectory();
    _checkActive();
    final ambientRoot = Directory(
      p.join(root.path, remotePrefix.replaceAll('/', Platform.pathSeparator)),
    );
    if (!await ambientRoot.exists()) {
      return <String>{};
    }
    final output = <String>{};
    await for (final entity in ambientRoot.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File || entity.path.endsWith('.part')) {
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
    return downloadToLocalWithProgress(option, null);
  }

  Future<String> downloadToLocalWithProgress(
    OnlineAmbientSoundOption option,
    void Function(ResourceDownloadProgress progress)? onProgress,
  ) async {
    _checkActive();
    final file = await _cacheService.ensureFileDownloaded(
      option.remoteKey,
      cacheRelativePath: option.remoteKey,
      onProgress: onProgress,
    );
    _checkActive();
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
}

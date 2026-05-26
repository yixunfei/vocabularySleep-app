part of '../toolbox_life_tools.dart';

class _WallpaperCachedItems {
  const _WallpaperCachedItems({required this.items, required this.savedAt});

  final List<_WallpaperItem> items;
  final DateTime? savedAt;
}

class _WallpaperCacheStatus {
  const _WallpaperCacheStatus({
    required this.sourceSnapshots,
    required this.imageFiles,
    required this.totalBytes,
  });

  final int sourceSnapshots;
  final int imageFiles;
  final int totalBytes;

  bool get hasData => sourceSnapshots > 0 || imageFiles > 0 || totalBytes > 0;
}

class _WallpaperCacheStore {
  _WallpaperCacheStore._();

  static final _WallpaperCacheStore instance = _WallpaperCacheStore._();

  Future<_WallpaperCachedItems?> readItems({
    required _WallpaperSource source,
    required String query,
  }) async {
    final index = await _readIndex();
    final sources = index['sources'];
    if (sources is! Map) {
      return null;
    }
    final record = sources[_sourceCacheKey(source: source, query: query)];
    if (record is! Map) {
      return null;
    }
    final items = (record['items'] as List<dynamic>? ?? const <dynamic>[])
        .map(_WallpaperItem.fromJson)
        .whereType<_WallpaperItem>()
        .toList(growable: false);
    if (items.isEmpty) {
      return null;
    }
    return _WallpaperCachedItems(
      items: items,
      savedAt: DateTime.tryParse(record['savedAt']?.toString() ?? ''),
    );
  }

  Future<void> saveItems({
    required _WallpaperSource source,
    required String query,
    required List<_WallpaperItem> items,
  }) async {
    if (items.isEmpty) {
      return;
    }
    final index = await _readIndex();
    final rawSources = index['sources'];
    final sources = rawSources is Map
        ? Map<String, Object?>.from(rawSources)
        : <String, Object?>{};
    sources[_sourceCacheKey(source: source, query: query)] = <String, Object?>{
      'sourceId': source.id,
      'sourceName': source.name,
      'query': query.trim(),
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(growable: false),
    };
    index['sources'] = sources;
    await _writeIndex(index);
  }

  Future<String?> cachedImagePath(String url, String extension) async {
    final imageDirectory = await _imageDirectory();
    if (!await imageDirectory.exists()) {
      return null;
    }
    final hash = _hash(url);
    final preferred = File(
      path.join(imageDirectory.path, '$hash.${_normalizeExtension(extension)}'),
    );
    if (await preferred.exists() && await preferred.length() > 0) {
      return preferred.path;
    }
    await for (final entity in imageDirectory.list()) {
      if (entity is File &&
          path.basenameWithoutExtension(entity.path) == hash &&
          await entity.length() > 0) {
        return entity.path;
      }
    }
    return null;
  }

  Future<String> cacheImage(
    String url,
    String extension, {
    Map<String, String>? headers,
  }) async {
    final existing = await cachedImagePath(url, extension);
    if (existing != null) {
      return existing;
    }
    final imageDirectory = await _imageDirectory();
    await imageDirectory.create(recursive: true);
    final file = File(
      path.join(
        imageDirectory.path,
        '${_hash(url)}.${_normalizeExtension(extension)}',
      ),
    );
    final response = await http
        .get(Uri.parse(url), headers: headers ?? _wallpaperHeadersForUrl(url))
        .timeout(_wallpaperImageTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('HTTP ${response.statusCode}');
    }
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    if (contentType.isNotEmpty && !contentType.startsWith('image/')) {
      throw StateError('HTTP ${response.statusCode} $contentType');
    }
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file.path;
  }

  Future<Uint8List> cachedImageBytes(
    String url,
    String extension, {
    Map<String, String>? headers,
  }) async {
    final cachedPath = await cacheImage(url, extension, headers: headers);
    return File(cachedPath).readAsBytes();
  }

  Future<_WallpaperCacheStatus> status() async {
    final root = await _rootDirectory();
    if (!await root.exists()) {
      return const _WallpaperCacheStatus(
        sourceSnapshots: 0,
        imageFiles: 0,
        totalBytes: 0,
      );
    }
    var imageFiles = 0;
    var totalBytes = 0;
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final length = await entity.length();
        totalBytes += length;
        if (path.basename(path.dirname(entity.path)) == 'images') {
          imageFiles += 1;
        }
      }
    }
    final index = await _readIndex();
    final sources = index['sources'];
    return _WallpaperCacheStatus(
      sourceSnapshots: sources is Map ? sources.length : 0,
      imageFiles: imageFiles,
      totalBytes: totalBytes,
    );
  }

  Future<void> clear() async {
    final root = await _rootDirectory();
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  }

  Future<Map<String, Object?>> _readIndex() async {
    final indexFile = await _indexFile();
    if (!await indexFile.exists()) {
      return <String, Object?>{'version': 1, 'sources': <String, Object?>{}};
    }
    try {
      final decoded = jsonDecode(await indexFile.readAsString());
      if (decoded is Map) {
        return Map<String, Object?>.from(decoded);
      }
    } catch (_) {
      // Corrupt cache metadata is non-critical; image files remain clearable.
    }
    return <String, Object?>{'version': 1, 'sources': <String, Object?>{}};
  }

  Future<void> _writeIndex(Map<String, Object?> index) async {
    final indexFile = await _indexFile();
    await indexFile.parent.create(recursive: true);
    await indexFile.writeAsString(jsonEncode(index), flush: true);
  }

  Future<File> _indexFile() async {
    final root = await _rootDirectory();
    return File(path.join(root.path, 'cache_index.json'));
  }

  Future<Directory> _imageDirectory() async {
    final root = await _rootDirectory();
    return Directory(path.join(root.path, 'images'));
  }

  Future<Directory> _rootDirectory() async {
    try {
      final support = await getApplicationSupportDirectory();
      return Directory(path.join(support.path, 'wallpaper_helper'));
    } catch (_) {
      return Directory(
        path.join(
          Directory.systemTemp.path,
          'vocabulary_sleep_wallpaper_helper',
        ),
      );
    }
  }

  String _sourceCacheKey({
    required _WallpaperSource source,
    required String query,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    return '${source.id}:${_hash(normalizedQuery)}';
  }

  String _hash(String value) => sha1.convert(utf8.encode(value)).toString();

  String _normalizeExtension(String extension) {
    final clean = extension.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return switch (clean) {
      'jpeg' => 'jpg',
      'jpg' || 'png' || 'webp' || 'avif' => clean,
      _ => 'jpg',
    };
  }
}

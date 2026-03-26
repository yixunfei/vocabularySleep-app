import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class OnlineAmbientSoundOption {
  const OnlineAmbientSoundOption({
    required this.id,
    required this.name,
    required this.categoryKey,
    required this.relativePath,
    required this.primaryUrl,
    required this.fallbackUrl,
    this.defaultVolume = 0.5,
  });

  final String id;
  final String name;
  final String categoryKey;
  final String relativePath;
  final String primaryUrl;
  final String fallbackUrl;
  final double defaultVolume;

  String get streamUrl => primaryUrl;
}

class OnlineAmbientCatalogService {
  OnlineAmbientCatalogService({http.Client? client}) : _client = client;

  static const String baseSiteUrl = 'https://moodist.mvze.net';
  static const String baseSiteContentUrl = '$baseSiteUrl/sounds';
  static const String baseGithubContentUrl =
      'https://raw.githubusercontent.com/remvze/moodist/main/public/sounds';

  final http.Client? _client;
  List<OnlineAmbientSoundOption>? _cachedCatalog;

  static const List<OnlineAmbientSoundOption> fallbackOptions =
      <OnlineAmbientSoundOption>[
        OnlineAmbientSoundOption(
          id: 'remote_moodist_noise_white',
          name: 'White Noise',
          categoryKey: 'ambientCategoryNoise',
          relativePath: 'noise/white-noise.wav',
          primaryUrl: '$baseSiteContentUrl/noise/white-noise.wav',
          fallbackUrl: '$baseGithubContentUrl/noise/white-noise.wav',
          defaultVolume: 0.36,
        ),
        OnlineAmbientSoundOption(
          id: 'remote_moodist_noise_pink',
          name: 'Pink Noise',
          categoryKey: 'ambientCategoryNoise',
          relativePath: 'noise/pink-noise.wav',
          primaryUrl: '$baseSiteContentUrl/noise/pink-noise.wav',
          fallbackUrl: '$baseGithubContentUrl/noise/pink-noise.wav',
          defaultVolume: 0.34,
        ),
        OnlineAmbientSoundOption(
          id: 'remote_moodist_noise_brown',
          name: 'Brown Noise',
          categoryKey: 'ambientCategoryNoise',
          relativePath: 'noise/brown-noise.wav',
          primaryUrl: '$baseSiteContentUrl/noise/brown-noise.wav',
          fallbackUrl: '$baseGithubContentUrl/noise/brown-noise.wav',
          defaultVolume: 0.38,
        ),
        OnlineAmbientSoundOption(
          id: 'remote_moodist_rain_window',
          name: 'Rain on Window',
          categoryKey: 'ambientCategoryRain',
          relativePath: 'rain/rain-on-window.mp3',
          primaryUrl: '$baseSiteContentUrl/rain/rain-on-window.mp3',
          fallbackUrl: '$baseGithubContentUrl/rain/rain-on-window.mp3',
          defaultVolume: 0.38,
        ),
        OnlineAmbientSoundOption(
          id: 'remote_moodist_nature_waterfall',
          name: 'Waterfall',
          categoryKey: 'ambientCategoryNature',
          relativePath: 'nature/waterfall.mp3',
          primaryUrl: '$baseSiteContentUrl/nature/waterfall.mp3',
          fallbackUrl: '$baseGithubContentUrl/nature/waterfall.mp3',
          defaultVolume: 0.42,
        ),
        OnlineAmbientSoundOption(
          id: 'remote_moodist_focus_airport',
          name: 'Airport',
          categoryKey: 'ambientCategoryFocus',
          relativePath: 'places/airport.mp3',
          primaryUrl: '$baseSiteContentUrl/places/airport.mp3',
          fallbackUrl: '$baseGithubContentUrl/places/airport.mp3',
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
      final siteOptions = await _fetchCatalogFromSite();
      if (siteOptions.isNotEmpty) {
        _cachedCatalog = siteOptions;
        return siteOptions;
      }
    } catch (_) {
      // Fall through to GitHub and local fallback.
    }

    try {
      final githubOptions = await _fetchCatalogFromGitHub();
      if (githubOptions.isNotEmpty) {
        _cachedCatalog = githubOptions;
        return githubOptions;
      }
    } catch (_) {
      // Fall through to bundled fallback list.
    }

    _cachedCatalog = fallbackOptions;
    return fallbackOptions;
  }

  Future<String> resolvePlaybackUrl(OnlineAmbientSoundOption option) async {
    if (await _urlSeemsReachable(option.primaryUrl)) {
      return option.primaryUrl;
    }
    return option.fallbackUrl;
  }

  Future<String> downloadToLocal(OnlineAmbientSoundOption option) async {
    final client = _client ?? http.Client();
    final targetDirectory = await _ensureDownloadDirectory();
    final targetPath = p.join(
      targetDirectory.path,
      option.relativePath.replaceAll('/', Platform.pathSeparator),
    );
    final targetFile = File(targetPath);
    if (await targetFile.exists() && await targetFile.length() > 0) {
      return targetFile.path;
    }
    await targetFile.parent.create(recursive: true);

    final preferredUrl = await resolvePlaybackUrl(option);
    final response = await client.get(Uri.parse(preferredUrl));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Failed to download online ambient sound (${response.statusCode})',
        uri: Uri.parse(preferredUrl),
      );
    }

    await targetFile.writeAsBytes(response.bodyBytes, flush: true);
    return targetFile.path;
  }

  Future<List<OnlineAmbientSoundOption>> _fetchCatalogFromSite() async {
    final client = _client ?? http.Client();
    final response = await client.get(
      Uri.parse(baseSiteUrl),
      headers: const <String, String>{'User-Agent': 'Codex'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Failed to fetch Moodist site (${response.statusCode})',
        uri: Uri.parse(baseSiteUrl),
      );
    }

    final html = utf8.decode(response.bodyBytes, allowMalformed: true);
    final categoryMatches = RegExp(
      r'id="category-([a-z-]+)"',
      caseSensitive: false,
    ).allMatches(html).toList(growable: false);
    if (categoryMatches.isEmpty) {
      return const <OnlineAmbientSoundOption>[];
    }

    final options = <OnlineAmbientSoundOption>[];
    for (var index = 0; index < categoryMatches.length; index += 1) {
      final match = categoryMatches[index];
      final categorySlug = match.group(1)?.trim() ?? '';
      if (categorySlug.isEmpty || categorySlug == 'favorites') {
        continue;
      }
      final start = match.end;
      final end = index + 1 < categoryMatches.length
          ? categoryMatches[index + 1].start
          : html.length;
      final segment = html.substring(start, end);
      final soundMatches = RegExp(
        r'<div class="_label_[^"]+" id="([^"]+)">([^<]+)</div>',
        caseSensitive: false,
      ).allMatches(segment);

      for (final soundMatch in soundMatches) {
        final slug = soundMatch.group(1)?.trim() ?? '';
        final name = soundMatch.group(2)?.trim() ?? '';
        if (slug.isEmpty || name.isEmpty) {
          continue;
        }
        final extension = categorySlug == 'noise' ? 'wav' : 'mp3';
        final relativePath = '$categorySlug/$slug.$extension';
        options.add(
          OnlineAmbientSoundOption(
            id: 'remote_moodist_${categorySlug}_$slug',
            name: name,
            categoryKey: _categoryKeyForSlug(categorySlug),
            relativePath: relativePath,
            primaryUrl: '$baseSiteContentUrl/$relativePath',
            fallbackUrl: '$baseGithubContentUrl/$relativePath',
            defaultVolume: _defaultVolumeForCategory(categorySlug),
          ),
        );
      }
    }

    return options;
  }

  Future<List<OnlineAmbientSoundOption>> _fetchCatalogFromGitHub() async {
    final client = _client ?? http.Client();
    final response = await client.get(
      Uri.parse(
        'https://api.github.com/repos/remvze/moodist/git/trees/main?recursive=1',
      ),
      headers: const <String, String>{'User-Agent': 'Codex'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Failed to fetch Moodist tree (${response.statusCode})',
        uri: Uri.parse(
          'https://api.github.com/repos/remvze/moodist/git/trees/main?recursive=1',
        ),
      );
    }

    final decoded = jsonDecode(
      utf8.decode(response.bodyBytes, allowMalformed: true),
    );
    if (decoded is! Map || decoded['tree'] is! List) {
      return const <OnlineAmbientSoundOption>[];
    }

    final options = <OnlineAmbientSoundOption>[];
    for (final item in decoded['tree'] as List) {
      if (item is! Map) {
        continue;
      }
      final type = '${item['type'] ?? ''}'.trim();
      final path = '${item['path'] ?? ''}'.trim();
      if (type != 'blob' ||
          !path.startsWith('public/sounds/') ||
          !(path.endsWith('.mp3') || path.endsWith('.wav'))) {
        continue;
      }
      final relativePath = path.substring('public/sounds/'.length);
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
          id: 'remote_moodist_${categorySlug}_$slug',
          name: _humanizeSlug(slug),
          categoryKey: _categoryKeyForSlug(categorySlug),
          relativePath: relativePath,
          primaryUrl: '$baseSiteContentUrl/$relativePath',
          fallbackUrl: '$baseGithubContentUrl/$relativePath',
          defaultVolume: _defaultVolumeForCategory(categorySlug),
        ),
      );
    }
    return options;
  }

  Future<bool> _urlSeemsReachable(String url) async {
    final client = _client ?? http.Client();
    try {
      final response = await client.get(
        Uri.parse(url),
        headers: const <String, String>{'Range': 'bytes=0-0'},
      );
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  String _categoryKeyForSlug(String categorySlug) {
    return switch (categorySlug) {
      'nature' => 'ambientCategoryNature',
      'rain' => 'ambientCategoryRain',
      'noise' => 'ambientCategoryNoise',
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

  Future<Directory> _ensureDownloadDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    final downloadDir = Directory(
      p.join(supportDir.path, 'ambient_downloads', 'moodist'),
    );
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }
}

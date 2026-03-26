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
    this.defaultVolume = 0.5,
  });

  final String id;
  final String name;
  final String categoryKey;
  final String relativePath;
  final double defaultVolume;

  String get streamUrl =>
      '${OnlineAmbientCatalogService.baseContentUrl}/$relativePath';
}

class OnlineAmbientCatalogService {
  OnlineAmbientCatalogService({http.Client? client}) : _client = client;

  static const String baseContentUrl =
      'https://raw.githubusercontent.com/remvze/moodist/main/public/sounds';

  final http.Client? _client;

  static const List<OnlineAmbientSoundOption> options =
      <OnlineAmbientSoundOption>[
        OnlineAmbientSoundOption(
          id: 'remote_moodist_noise_white',
          name: 'White Noise',
          categoryKey: 'ambientCategoryNoise',
          relativePath: 'noise/white-noise.wav',
          defaultVolume: 0.36,
        ),
        OnlineAmbientSoundOption(
          id: 'remote_moodist_noise_pink',
          name: 'Pink Noise',
          categoryKey: 'ambientCategoryNoise',
          relativePath: 'noise/pink-noise.wav',
          defaultVolume: 0.34,
        ),
        OnlineAmbientSoundOption(
          id: 'remote_moodist_noise_brown',
          name: 'Brown Noise',
          categoryKey: 'ambientCategoryNoise',
          relativePath: 'noise/brown-noise.wav',
          defaultVolume: 0.38,
        ),
        OnlineAmbientSoundOption(
          id: 'remote_moodist_rain_window',
          name: 'Rain on Window',
          categoryKey: 'ambientCategoryRain',
          relativePath: 'rain/rain-on-window.mp3',
          defaultVolume: 0.38,
        ),
        OnlineAmbientSoundOption(
          id: 'remote_moodist_rain_tent',
          name: 'Rain on Tent',
          categoryKey: 'ambientCategoryRain',
          relativePath: 'rain/rain-on-tent.mp3',
          defaultVolume: 0.38,
        ),
        OnlineAmbientSoundOption(
          id: 'remote_moodist_rain_umbrella',
          name: 'Rain on Umbrella',
          categoryKey: 'ambientCategoryRain',
          relativePath: 'rain/rain-on-umbrella.mp3',
          defaultVolume: 0.36,
        ),
        OnlineAmbientSoundOption(
          id: 'remote_moodist_rain_thunder',
          name: 'Thunder',
          categoryKey: 'ambientCategoryRain',
          relativePath: 'rain/thunder.mp3',
          defaultVolume: 0.32,
        ),
        OnlineAmbientSoundOption(
          id: 'remote_moodist_nature_waterfall',
          name: 'Waterfall',
          categoryKey: 'ambientCategoryNature',
          relativePath: 'nature/waterfall.mp3',
          defaultVolume: 0.42,
        ),
        OnlineAmbientSoundOption(
          id: 'remote_moodist_nature_river',
          name: 'River',
          categoryKey: 'ambientCategoryNature',
          relativePath: 'nature/river.mp3',
          defaultVolume: 0.42,
        ),
        OnlineAmbientSoundOption(
          id: 'remote_moodist_nature_waves',
          name: 'Waves',
          categoryKey: 'ambientCategoryNature',
          relativePath: 'nature/waves.mp3',
          defaultVolume: 0.44,
        ),
        OnlineAmbientSoundOption(
          id: 'remote_moodist_nature_trees',
          name: 'Wind in Trees',
          categoryKey: 'ambientCategoryNature',
          relativePath: 'nature/wind-in-trees.mp3',
          defaultVolume: 0.4,
        ),
        OnlineAmbientSoundOption(
          id: 'remote_moodist_focus_cafe',
          name: 'Cafe',
          categoryKey: 'ambientCategoryFocus',
          relativePath: 'places/cafe.mp3',
          defaultVolume: 0.42,
        ),
        OnlineAmbientSoundOption(
          id: 'remote_moodist_focus_library',
          name: 'Library',
          categoryKey: 'ambientCategoryFocus',
          relativePath: 'places/library.mp3',
          defaultVolume: 0.42,
        ),
        OnlineAmbientSoundOption(
          id: 'remote_moodist_focus_office',
          name: 'Office',
          categoryKey: 'ambientCategoryFocus',
          relativePath: 'places/office.mp3',
          defaultVolume: 0.4,
        ),
        OnlineAmbientSoundOption(
          id: 'remote_moodist_focus_train',
          name: 'Inside a Train',
          categoryKey: 'ambientCategoryFocus',
          relativePath: 'transport/inside-a-train.mp3',
          defaultVolume: 0.38,
        ),
      ];

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

    final response = await client.get(Uri.parse(option.streamUrl));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Failed to download online ambient sound (${response.statusCode})',
        uri: Uri.parse(option.streamUrl),
      );
    }

    await targetFile.writeAsBytes(response.bodyBytes, flush: true);
    return targetFile.path;
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

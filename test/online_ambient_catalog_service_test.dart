import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/services/cstcloud_resource_cache_service.dart';
import 'package:vocabulary_sleep_app/src/services/online_ambient_catalog_service.dart';
import 'package:vocabulary_sleep_app/src/services/s3_bucket_probe.dart';

class _FakeAmbientCatalogCacheService extends CstCloudResourceCacheService {
  _FakeAmbientCatalogCacheService({
    required this.objects,
    required this.tempDir,
  });

  final List<S3ObjectSummary> objects;
  final Directory tempDir;

  @override
  Future<List<S3ObjectSummary>> listObjects(
    String prefix, {
    int maxKeys = 1000,
  }) async {
    return objects
        .where((item) => item.key.startsWith(prefix))
        .take(maxKeys)
        .toList(growable: false);
  }

  @override
  Future<File> ensureFileDownloaded(
    String remoteKey, {
    String? cacheRelativePath,
    ResourceDownloadProgressCallback? onProgress,
  }) async {
    final relative = cacheRelativePath ?? remoteKey;
    final file = File(
      '${tempDir.path}/${relative.replaceAll('/', Platform.pathSeparator)}',
    );
    await file.parent.create(recursive: true);
    if (!await file.exists()) {
      await file.writeAsBytes(const <int>[1, 2, 3], flush: true);
    }
    final size = await file.length();
    onProgress?.call(
      ResourceDownloadProgress(receivedBytes: size, totalBytes: size),
    );
    return file;
  }
}

void main() {
  test('fetchCatalog parses S3 ambient moodist directory', () async {
    final tempDir = await Directory.systemTemp.createTemp('ambient_catalog_');
    addTearDown(() => tempDir.delete(recursive: true));

    final service = OnlineAmbientCatalogService(
      cacheService: _FakeAmbientCatalogCacheService(
        tempDir: tempDir,
        objects: const <S3ObjectSummary>[
          S3ObjectSummary(
            key: 'ambient/moodist/noise/white-noise.wav',
            size: 1676232,
          ),
          S3ObjectSummary(
            key: 'ambient/moodist/places/library.mp3',
            size: 3825455,
          ),
          S3ObjectSummary(key: 'ambient/moodist/nature/', size: 0),
        ],
      ),
    );

    final options = await service.fetchCatalog();

    expect(options, hasLength(2));
    expect(options.first.relativePath, 'noise/white-noise.wav');
    expect(options.first.remoteKey, 'ambient/moodist/noise/white-noise.wav');
    expect(options.first.categoryKey, 'ambientCategoryNoise');
    expect(options.last.relativePath, 'places/library.mp3');
    expect(options.last.categoryKey, 'ambientCategoryPlaces');
  });
}

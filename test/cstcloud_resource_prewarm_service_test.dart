import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/services/cstcloud_resource_cache_service.dart';
import 'package:vocabulary_sleep_app/src/services/cstcloud_resource_prewarm_service.dart';
import 'package:vocabulary_sleep_app/src/services/s3_bucket_probe.dart';

/// 只覆写预热用到的三个入口，避免测试触网。
class _FakePrewarmCacheService extends CstCloudResourceCacheService {
  _FakePrewarmCacheService(this.objects);

  final List<S3ObjectSummary> objects;
  final List<String> downloadedKeys = <String>[];
  void Function(String key)? onDownload;

  @override
  Future<List<S3ObjectSummary>> listObjects(
    String prefix, {
    int maxKeys = 1000,
  }) async {
    return objects
        .where((item) => item.key.startsWith(prefix))
        .toList(growable: false);
  }

  @override
  Future<File> ensureFileDownloaded(
    String remoteKey, {
    String? cacheRelativePath,
    ResourceDownloadProgressCallback? onProgress,
  }) async {
    downloadedKeys.add(remoteKey);
    onDownload?.call(remoteKey);
    return File('');
  }

  @override
  Future<bool> hasCachedFilesUnderPrefix(String prefix) async => false;
}

void main() {
  test('downloads all remote objects when allowed and uncapped', () async {
    final cache = _FakePrewarmCacheService(const <S3ObjectSummary>[
      S3ObjectSummary(key: 'music/a.bin', size: 10),
      S3ObjectSummary(key: 'ambient/b.bin', size: 20),
      S3ObjectSummary(key: 'ambient/', size: 0),
    ]);
    final service = CstCloudResourcePrewarmService(cache);

    final result = await service.prewarm(
      onProgress: (_) {},
      networkGate: () async => true,
    );

    expect(result.fullyDownloaded, isTrue);
    expect(result.plannedCount, 2);
    expect(result.downloadedCount, 2);
    expect(result.plannedBytes, 30);
    expect(cache.downloadedKeys, <String>['music/a.bin', 'ambient/b.bin']);
  });

  test('stops at maxTotalBytes and reports capped', () async {
    final cache = _FakePrewarmCacheService(const <S3ObjectSummary>[
      S3ObjectSummary(key: 'music/small.bin', size: 10),
      S3ObjectSummary(key: 'music/fit.bin', size: 20),
      S3ObjectSummary(key: 'ambient/too-big.bin', size: 1000),
    ]);
    final service = CstCloudResourcePrewarmService(cache);

    final result = await service.prewarm(
      onProgress: (_) {},
      maxTotalBytes: 30,
      networkGate: () async => true,
    );

    expect(result.stopReason, CstCloudResourcePrewarmStopReason.capped);
    expect(result.fullyDownloaded, isFalse);
    expect(cache.downloadedKeys, <String>['music/small.bin', 'music/fit.bin']);
    expect(result.downloadedBytes, 30);
  });

  test('cancellation stops before the next download', () async {
    final cache = _FakePrewarmCacheService(const <S3ObjectSummary>[
      S3ObjectSummary(key: 'music/a.bin', size: 10),
      S3ObjectSummary(key: 'music/b.bin', size: 10),
      S3ObjectSummary(key: 'music/c.bin', size: 10),
    ]);
    final service = CstCloudResourcePrewarmService(cache);
    final cancellation = CstCloudResourcePrewarmCancellation();
    // 第一个文件下载完成后立刻取消：后续对象不得再触发下载。
    cache.onDownload = (_) => cancellation.cancel();

    final result = await service.prewarm(
      onProgress: (_) {},
      cancellation: cancellation,
      networkGate: () async => true,
    );

    expect(result.stopReason, CstCloudResourcePrewarmStopReason.cancelled);
    expect(cache.downloadedKeys, <String>['music/a.bin']);
    expect(result.downloadedCount, 1);
  });

  test('network gate denies without listing or downloading', () async {
    final cache = _FakePrewarmCacheService(const <S3ObjectSummary>[
      S3ObjectSummary(key: 'music/a.bin', size: 10),
    ]);
    final service = CstCloudResourcePrewarmService(cache);

    final result = await service.prewarm(
      onProgress: (_) {},
      networkGate: () async => false,
    );

    expect(
      result.stopReason,
      CstCloudResourcePrewarmStopReason.skippedByNetworkGate,
    );
    expect(cache.downloadedKeys, isEmpty);
  });

  test('default network gate allows only unmetered results', () {
    expect(
      CstCloudResourcePrewarmService.isNetworkResultAllowed([
        ConnectivityResult.wifi,
      ]),
      isTrue,
    );
    expect(
      CstCloudResourcePrewarmService.isNetworkResultAllowed([
        ConnectivityResult.ethernet,
      ]),
      isTrue,
    );
    expect(
      CstCloudResourcePrewarmService.isNetworkResultAllowed([
        ConnectivityResult.mobile,
      ]),
      isFalse,
    );
    expect(CstCloudResourcePrewarmService.isNetworkResultAllowed([]), isFalse);
  });
}

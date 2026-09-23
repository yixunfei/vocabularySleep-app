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
  final List<String> listedPrefixes = [];
  final Set<String> cachedKeys = {};
  void Function()? onList;

  @override
  Future<List<S3ObjectSummary>> listObjects(
    String prefix, {
    int maxKeys = 1000,
  }) async {
    listedPrefixes.add(prefix);
    onList?.call();
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
    cachedKeys.add(remoteKey);
    onDownload?.call(remoteKey);
    return File('');
  }

  @override
  Future<bool> hasCachedFilesUnderPrefix(String prefix) async => false;

  @override
  Future<bool> isFileCached(String remoteKey, {int? expectedBytes}) async =>
      cachedKeys.contains(remoteKey);

  @override
  Future<File> ensureValidFileDownloaded(
    String remoteKey, {
    String? cacheRelativePath,
    ResourceDownloadProgressCallback? onProgress,
    required ResourceFileValidator validator,
  }) => ensureFileDownloaded(remoteKey);
}

void main() {
  test('capped retries progress past objects already in cache', () async {
    final cache = _FakePrewarmCacheService(const [
      S3ObjectSummary(key: 'music/a.bin', size: 10),
      S3ObjectSummary(key: 'ambient/b.bin', size: 10),
    ]);
    final service = CstCloudResourcePrewarmService(cache);
    await service.prewarm(
      onProgress: (_) {},
      maxTotalBytes: 10,
      networkGate: () async => true,
    );
    final result = await service.prewarm(
      onProgress: (_) {},
      maxTotalBytes: 10,
      networkGate: () async => true,
    );
    expect(cache.downloadedKeys, ['music/a.bin', 'ambient/b.bin']);
    expect(result.fullyDownloaded, isTrue);
    expect(result.downloadedBytes, 10);
  });

  test('an oversized object does not starve later small objects', () async {
    final cache = _FakePrewarmCacheService(const [
      S3ObjectSummary(key: 'music/large.bin', size: 100),
      S3ObjectSummary(key: 'ambient/small.bin', size: 10),
    ]);
    final result = await CstCloudResourcePrewarmService(cache).prewarm(
      onProgress: (_) {},
      maxTotalBytes: 10,
      networkGate: () async => true,
    );
    expect(cache.downloadedKeys, ['ambient/small.bin']);
    expect(result.stopReason, CstCloudResourcePrewarmStopReason.capped);
  });

  test('unavailable network information denies optional prewarm', () async {
    final cache = _FakePrewarmCacheService([]);
    final service = CstCloudResourcePrewarmService(cache);
    final result = await service.prewarm(
      onProgress: (_) {},
      networkGate: () async => throw StateError('network unavailable'),
    );
    expect(cache.listedPrefixes, isEmpty);
    expect(
      result.stopReason,
      CstCloudResourcePrewarmStopReason.skippedByNetworkGate,
    );
  });

  test('already cancelled prewarm does not list remote objects', () async {
    final cache = _FakePrewarmCacheService([]);
    final service = CstCloudResourcePrewarmService(cache);
    final cancellation = CstCloudResourcePrewarmCancellation()..cancel();
    final result = await service.prewarm(
      onProgress: (_) {},
      cancellation: cancellation,
      networkGate: () async => true,
    );
    expect(cache.listedPrefixes, isEmpty);
    expect(result.stopReason, CstCloudResourcePrewarmStopReason.cancelled);
  });

  test('cancellation while listing prevents further requests', () async {
    final cache = _FakePrewarmCacheService([]);
    final cancellation = CstCloudResourcePrewarmCancellation();
    cache.onList = cancellation.cancel;
    final result = await CstCloudResourcePrewarmService(cache).prewarm(
      onProgress: (_) {},
      cancellation: cancellation,
      networkGate: () async => true,
    );
    expect(cache.listedPrefixes, ['music/']);
    expect(result.stopReason, CstCloudResourcePrewarmStopReason.cancelled);
  });

  test('network change stops the next file download', () async {
    final cache = _FakePrewarmCacheService(const [
      S3ObjectSummary(key: 'music/a.bin', size: 10),
      S3ObjectSummary(key: 'music/b.bin', size: 10),
    ]);
    var allowed = true;
    cache.onDownload = (_) => allowed = false;
    final result = await CstCloudResourcePrewarmService(
      cache,
    ).prewarm(onProgress: (_) {}, networkGate: () async => allowed);
    expect(cache.downloadedKeys, ['music/a.bin']);
    expect(
      result.stopReason,
      CstCloudResourcePrewarmStopReason.skippedByNetworkGate,
    );
  });

  test('VPN alone does not prove an unmetered connection', () {
    expect(
      CstCloudResourcePrewarmService.isNetworkResultAllowed([
        ConnectivityResult.vpn,
        ConnectivityResult.mobile,
      ]),
      isFalse,
    );
    expect(
      CstCloudResourcePrewarmService.isNetworkResultAllowed([
        ConnectivityResult.vpn,
      ]),
      isFalse,
    );
  });

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

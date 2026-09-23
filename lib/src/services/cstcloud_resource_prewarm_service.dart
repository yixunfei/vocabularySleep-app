import 'package:connectivity_plus/connectivity_plus.dart';

import 'cstcloud_resource_cache_service.dart';

class CstCloudResourcePrewarmProgress {
  const CstCloudResourcePrewarmProgress({
    required this.completed,
    required this.total,
    required this.currentLabel,
  });

  final int completed;
  final int total;
  final String currentLabel;

  double get progress => total <= 0 ? 0 : completed / total;
}

/// [风险] PERF-03: 预热是一次可能持续很久的网络活动，必须可中途取消。
/// 句柄由调用方持有；`cancel()` 立即生效，`prewarm` 在每个对象下载前检查。
class CstCloudResourcePrewarmCancellation {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

enum CstCloudResourcePrewarmStopReason {
  /// 全部计划对象下载完成（或无事可做）。
  none,

  /// 调用方取消。
  cancelled,

  /// 计划总量超过 maxTotalBytes，仅下载了前缀内一部分。
  capped,

  /// 网络门控拒绝（如移动网络），未发生任何下载。
  skippedByNetworkGate,
}

class CstCloudResourcePrewarmResult {
  const CstCloudResourcePrewarmResult({
    required this.stopReason,
    required this.plannedCount,
    required this.downloadedCount,
    required this.plannedBytes,
    required this.downloadedBytes,
  });

  final CstCloudResourcePrewarmStopReason stopReason;
  final int plannedCount;

  /// Completed objects, including those already present in the cache.
  final int downloadedCount;
  final int plannedBytes;

  /// Bytes newly downloaded by this run; cache hits do not consume its budget.
  final int downloadedBytes;

  bool get fullyDownloaded =>
      stopReason == CstCloudResourcePrewarmStopReason.none &&
      downloadedCount >= plannedCount;
}

class CstCloudResourcePrewarmService {
  CstCloudResourcePrewarmService(
    this._cacheService, {
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  final CstCloudResourceCacheService _cacheService;
  final Connectivity _connectivity;

  static const List<String> _resourcePrefixes = <String>['music/', 'ambient/'];

  /// [风险] 预热总量上限：远程目录可能增长到任意规模，
  /// 一次性全量下载会打爆流量与磁盘；默认 96 MiB 起步。
  static const int defaultMaxTotalBytes = 96 * 1024 * 1024;

  /// 网络门控的默认判定：只允许不计费/宽裕网络。
  static bool isNetworkResultAllowed(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return false;
    }
    const allowed = <ConnectivityResult>{
      ConnectivityResult.wifi,
      ConnectivityResult.ethernet,
    };
    return results.any(allowed.contains);
  }

  Future<bool> isPrewarmNetworkAllowed({
    Future<bool> Function()? networkGate,
  }) async {
    try {
      if (networkGate != null) return await networkGate();
      return isNetworkResultAllowed(await _connectivity.checkConnectivity());
    } catch (_) {
      // Unknown network cost must not trigger optional background downloads.
      return false;
    }
  }

  Future<bool> shouldPrewarmMusic() async {
    for (final prefix in _resourcePrefixes) {
      final objects = await _cacheService.listObjects(prefix);
      final remoteTargets = objects
          .where((item) => item.key.startsWith(prefix))
          .where((item) => !item.key.endsWith('/'))
          .toList(growable: false);
      if (remoteTargets.isEmpty) {
        continue;
      }
      for (final target in remoteTargets.where((item) => item.size > 0)) {
        if (!await _cacheService.isFileCached(
          target.key,
          expectedBytes: target.size,
        )) {
          return true;
        }
      }
    }
    return false;
  }

  Future<CstCloudResourcePrewarmResult> prewarm({
    required void Function(CstCloudResourcePrewarmProgress progress) onProgress,
    CstCloudResourcePrewarmCancellation? cancellation,
    int maxTotalBytes = defaultMaxTotalBytes,
    Future<bool> Function()? networkGate,
  }) async {
    if (maxTotalBytes < 0) throw ArgumentError.value(maxTotalBytes);
    final targets = <_PrewarmTarget>[];
    var stopReason = CstCloudResourcePrewarmStopReason.none;
    for (final prefix in _resourcePrefixes) {
      stopReason = await _stopReason(cancellation, networkGate);
      if (stopReason != CstCloudResourcePrewarmStopReason.none) break;
      final objects = await _cacheService.listObjects(prefix);
      for (final item in objects) {
        if (!item.key.startsWith(prefix) ||
            item.key.endsWith('/') ||
            item.size <= 0) {
          continue;
        }
        targets.add(_PrewarmTarget(key: item.key, size: item.size));
      }
    }
    final plannedBytes = targets.fold<int>(0, (sum, item) => sum + item.size);

    var downloadedCount = 0;
    var downloadedBytes = 0;
    var capped = false;
    for (final target in targets) {
      if (stopReason != CstCloudResourcePrewarmStopReason.none) break;
      stopReason = await _stopReason(cancellation, networkGate);
      if (stopReason != CstCloudResourcePrewarmStopReason.none) break;
      final cached = await _cacheService.isFileCached(
        target.key,
        expectedBytes: target.size,
      );
      if (!cached && downloadedBytes + target.size > maxTotalBytes) {
        capped = true;
        continue;
      }
      onProgress(
        CstCloudResourcePrewarmProgress(
          completed: downloadedCount,
          total: targets.length,
          currentLabel: target.key,
        ),
      );
      if (cancellation?.isCancelled ?? false) {
        stopReason = CstCloudResourcePrewarmStopReason.cancelled;
        break;
      }
      if (!cached) {
        await _cacheService.ensureValidFileDownloaded(
          target.key,
          cacheRelativePath: target.key,
          validator: (file) async => await file.length() == target.size,
        );
        downloadedBytes += target.size;
      }
      downloadedCount += 1;
      onProgress(
        CstCloudResourcePrewarmProgress(
          completed: downloadedCount,
          total: targets.length,
          currentLabel: target.key,
        ),
      );
    }

    if (cancellation?.isCancelled ?? false) {
      stopReason = CstCloudResourcePrewarmStopReason.cancelled;
    } else if (capped && stopReason == CstCloudResourcePrewarmStopReason.none) {
      stopReason = CstCloudResourcePrewarmStopReason.capped;
    }
    return CstCloudResourcePrewarmResult(
      stopReason: stopReason,
      plannedCount: targets.length,
      downloadedCount: downloadedCount,
      plannedBytes: plannedBytes,
      downloadedBytes: downloadedBytes,
    );
  }

  Future<CstCloudResourcePrewarmStopReason> _stopReason(
    CstCloudResourcePrewarmCancellation? cancellation,
    Future<bool> Function()? networkGate,
  ) async {
    if (cancellation?.isCancelled ?? false) {
      return CstCloudResourcePrewarmStopReason.cancelled;
    }
    final allowed = await isPrewarmNetworkAllowed(networkGate: networkGate);
    if (cancellation?.isCancelled ?? false) {
      return CstCloudResourcePrewarmStopReason.cancelled;
    }
    return allowed
        ? CstCloudResourcePrewarmStopReason.none
        : CstCloudResourcePrewarmStopReason.skippedByNetworkGate;
  }
}

class _PrewarmTarget {
  const _PrewarmTarget({required this.key, required this.size});

  final String key;
  final int size;
}

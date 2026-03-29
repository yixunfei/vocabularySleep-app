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

class CstCloudResourcePrewarmService {
  CstCloudResourcePrewarmService(this._cacheService);

  final CstCloudResourceCacheService _cacheService;
  static const List<String> _resourcePrefixes = <String>['music/', 'ambient/'];

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
      final hasLocal = await _cacheService.hasCachedFilesUnderPrefix(
        prefix.replaceFirst(RegExp(r'/$'), ''),
      );
      if (!hasLocal) {
        return true;
      }
    }
    return false;
  }

  Future<void> prewarm({
    required void Function(CstCloudResourcePrewarmProgress progress) onProgress,
  }) async {
    final targets = <String>[];
    for (final prefix in _resourcePrefixes) {
      final objects = await _cacheService.listObjects(prefix);
      targets.addAll(
        objects
            .where((item) => !item.key.endsWith('/'))
            .map((item) => item.key),
      );
    }

    for (var index = 0; index < targets.length; index += 1) {
      final key = targets[index];
      onProgress(
        CstCloudResourcePrewarmProgress(
          completed: index,
          total: targets.length,
          currentLabel: key,
        ),
      );
      await _cacheService.ensureFileDownloaded(key, cacheRelativePath: key);
      onProgress(
        CstCloudResourcePrewarmProgress(
          completed: index + 1,
          total: targets.length,
          currentLabel: key,
        ),
      );
    }
  }
}

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

  Future<bool> shouldPrewarmMusic() async {
    final music = await _cacheService.listObjects('music/');
    final remoteTargets = music
        .where((item) => item.key.startsWith('music/'))
        .where((item) => !item.key.endsWith('/'))
        .toList(growable: false);
    if (remoteTargets.isEmpty) {
      return false;
    }
    final hasLocal = await _cacheService.hasCachedFilesUnderPrefix('music');
    return !hasLocal;
  }

  Future<void> prewarm({
    required void Function(CstCloudResourcePrewarmProgress progress) onProgress,
  }) async {
    final music = await _cacheService.listObjects('music/');
    final targets = <String>[
      ...music.where((item) => !item.key.endsWith('/')).map((item) => item.key),
    ];

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

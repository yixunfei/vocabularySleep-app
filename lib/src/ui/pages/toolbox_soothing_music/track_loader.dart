import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../../services/app_log_service.dart';
import '../../../services/cstcloud_resource_cache_service.dart';
import 'track_catalog.dart';

class SoothingMusicTrackLoadProgress {
  const SoothingMusicTrackLoadProgress({
    required this.receivedBytes,
    required this.totalBytes,
  });

  final int receivedBytes;
  final int totalBytes;

  double? get progress =>
      totalBytes <= 0 ? null : (receivedBytes / totalBytes).clamp(0.0, 1.0);
}

typedef SoothingMusicTrackLoadProgressCallback =
    void Function(SoothingMusicTrackLoadProgress progress);

class SoothingMusicTrackLoader {
  SoothingMusicTrackLoader({
    CstCloudResourceCacheService? remoteResourceCache,
    AppLogService? log,
  }) : _remoteResourceCache = remoteResourceCache,
       _log = log ?? AppLogService.instance;

  final CstCloudResourceCacheService? _remoteResourceCache;
  final AppLogService _log;
  final Map<String, Uint8List> _cache = <String, Uint8List>{};

  Future<void> preloadMode(String modeId) async {
    for (final track in SoothingMusicTrackCatalog.tracksForMode(modeId)) {
      try {
        await load(track);
      } catch (_) {
        // Ignore warmup failures and let interactive playback surface them.
      }
    }
  }

  Future<Uint8List> load(
    SoothingMusicTrack track, {
    SoothingMusicTrackLoadProgressCallback? onProgress,
  }) async {
    if (_cache[track.assetPath] case final Uint8List cached) {
      onProgress?.call(
        SoothingMusicTrackLoadProgress(
          receivedBytes: cached.length,
          totalBytes: cached.length,
        ),
      );
      return cached;
    }

    if (_remoteResourceCache != null) {
      final remoteResourceCache = _remoteResourceCache;
      try {
        final bytes = await remoteResourceCache.readBytes(
          track.assetPath,
          cacheRelativePath: track.assetPath,
          onProgress: onProgress == null
              ? null
              : (progress) {
                  onProgress(
                    SoothingMusicTrackLoadProgress(
                      receivedBytes: progress.receivedBytes,
                      totalBytes: progress.totalBytes,
                    ),
                  );
                },
        );
        _cache[track.assetPath] = bytes;
        return bytes;
      } catch (error, stackTrace) {
        _log.w(
          'soothing_track_loader',
          'remote soothing track download failed; attempting local fallback',
          data: <String, Object?>{
            'track': track.assetPath,
            'temporaryDiagnostic': 'remove_after_s3_music_rollout_stabilizes',
          },
        );
        _log.e(
          'soothing_track_loader',
          'remote soothing track failure detail',
          error: error,
          stackTrace: stackTrace,
          data: <String, Object?>{
            'track': track.assetPath,
            'temporaryDiagnostic': 'remove_after_s3_music_rollout_stabilizes',
          },
        );
      }
    }

    final desktopFallback = await _tryLoadDesktopWorkspaceFile(track.assetPath);
    if (desktopFallback != null) {
      _cache[track.assetPath] = desktopFallback;
      onProgress?.call(
        SoothingMusicTrackLoadProgress(
          receivedBytes: desktopFallback.length,
          totalBytes: desktopFallback.length,
        ),
      );
      return desktopFallback;
    }

    final bundleData = await rootBundle.load(track.assetPath);
    final bytes = bundleData.buffer.asUint8List();
    _cache[track.assetPath] = bytes;
    onProgress?.call(
      SoothingMusicTrackLoadProgress(
        receivedBytes: bytes.length,
        totalBytes: bytes.length,
      ),
    );
    return bytes;
  }

  Future<Uint8List?> _tryLoadDesktopWorkspaceFile(String relativePath) async {
    if (kIsWeb) return null;
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return null;
    }
    try {
      final candidate = File(
        p.join(
          Directory.current.path,
          relativePath.replaceAll('/', Platform.pathSeparator),
        ),
      );
      if (!await candidate.exists()) {
        return null;
      }
      final bytes = await candidate.readAsBytes();
      if (bytes.isEmpty) {
        return null;
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }
}

import 'dart:io';

import 'package:audioplayers/audioplayers.dart';

import 'cstcloud_resource_cache_service.dart';
import 'toolbox_breathing_catalog.dart';

enum BreathingCueSourceKind { asset, remote }

class BreathingResolvedCue {
  const BreathingResolvedCue({
    required this.cue,
    required this.source,
    required this.kind,
    required this.location,
  });

  final BreathingCueSpec cue;
  final Source source;
  final BreathingCueSourceKind kind;
  final String location;
}

class ToolboxBreathingAudioRepository {
  ToolboxBreathingAudioRepository(this._resourceCache);

  final CstCloudResourceCacheService? _resourceCache;
  final Map<String, Future<BreathingResolvedCue?>> _resolvedCache =
      <String, Future<BreathingResolvedCue?>>{};

  static const Map<String, String> _exactRemoteFileNameByCueId =
      <String, String>{
        'inhale_soft': '\u5438\u6c14.wav',
        'exhale_soft': '\u547c\u6c14.wav',
        'hold_soft': '\u5c4f\u606f.wav',
        'nose_inhale': '\u9f3b\u5b50\u5438\u6c14.wav',
        'nose_exhale': '\u9f3b\u5b50\u547c\u6c14.wav',
        'mouth_inhale': '\u5634\u5438\u6c14.wav',
        'mouth_exhale': '\u5634\u547c\u6c14.wav',
        'preview_relax': '\u653e\u677e.wav',
        'preview_intro_1': '\u547c\u5438\u5f15\u5bfc1.wav',
        'preview_intro_2': '\u547c\u5438\u5f15\u5bfc2.wav',
        'preview_nose_slow':
            '\u5f00\u59cb\u7528\u9f3b\u5b50\u7f13\u7f13\u5438\u6c14.wav',
        'preview_parasym': '\u526f\u4ea4\u611f\u4ea4\u66ff.wav',
        'preview_altitude': '\u5feb\u901f\u5634\u5438\u6c14\u5c4f\u6c14.wav',
      };

  Future<BreathingResolvedCue?> resolve(
    String cueId, {
    List<String> languageTags = const <String>[],
  }) {
    final normalizedTags = _normalizedLanguageTags(languageTags);
    final cacheKey = '$cueId|${normalizedTags.join(",")}';
    return _resolvedCache.putIfAbsent(
      cacheKey,
      () => _resolveInternal(cueId, normalizedTags),
    );
  }

  Future<List<BreathingResolvedCue>> warmUpCueIds(
    Iterable<String> cueIds, {
    List<String> languageTags = const <String>[],
  }) async {
    final results = <BreathingResolvedCue>[];
    for (final cueId in cueIds) {
      final resolved = await resolve(cueId, languageTags: languageTags);
      if (resolved != null) {
        results.add(resolved);
      }
    }
    return results;
  }

  Duration? effectiveCueDuration(String cueId, {double playbackRate = 1.0}) {
    final cue = BreathingExperienceCatalog.cues[cueId];
    if (cue == null || cue.approxDurationMs <= 0) {
      return null;
    }
    final normalizedRate = playbackRate.clamp(0.75, 2.0).toDouble();
    final durationMs = (cue.approxDurationMs / normalizedRate).round();
    return Duration(milliseconds: durationMs);
  }

  bool canPlayCueWithinStage(
    String cueId, {
    required Duration stageDuration,
    double playbackRate = 1.0,
    Duration safetyPadding = const Duration(milliseconds: 220),
  }) {
    final cueDuration = effectiveCueDuration(cueId, playbackRate: playbackRate);
    if (cueDuration == null) {
      return false;
    }
    return stageDuration.inMilliseconds >=
        cueDuration.inMilliseconds + safetyPadding.inMilliseconds;
  }

  List<String> candidateRemoteKeysForCue(
    String cueId, {
    List<String> languageTags = const <String>[],
  }) {
    final cue = BreathingExperienceCatalog.cues[cueId];
    if (cue == null) {
      return const <String>[];
    }
    // Keep the API shape stable; language tags are intentionally ignored because
    // breathing cue files are mapped to exact Chinese file names under one
    // fixed S3 prefix.
    final candidates = <String>{};
    final mappedName = _exactRemoteFileNameByCueId[cueId];
    final sourceNames = (mappedName ?? '').trim().isNotEmpty
        ? <String>[mappedName!]
        : cue.remoteFileNames;
    for (final fileName in sourceNames) {
      final normalized = _normalizeFileName(fileName);
      if (normalized.isEmpty) {
        continue;
      }
      candidates.add('${BreathingExperienceCatalog.remotePrefix}/$normalized');
    }
    return candidates.toList(growable: false);
  }

  Future<BreathingResolvedCue?> _resolveInternal(
    String cueId,
    List<String> languageTags,
  ) async {
    final cue = BreathingExperienceCatalog.cues[cueId];
    if (cue == null) {
      return null;
    }

    final resourceCache = _resourceCache;
    if (resourceCache != null) {
      for (final remoteKey in candidateRemoteKeysForCue(
        cueId,
        languageTags: languageTags,
      )) {
        final file = await _tryDownload(resourceCache, remoteKey);
        if (file == null) {
          continue;
        }
        return BreathingResolvedCue(
          cue: cue,
          source: DeviceFileSource(file.path),
          kind: BreathingCueSourceKind.remote,
          location: remoteKey,
        );
      }
    }

    final assetPath = cue.assetPath?.trim() ?? '';
    if (assetPath.isNotEmpty) {
      return BreathingResolvedCue(
        cue: cue,
        source: AssetSource(assetPath),
        kind: BreathingCueSourceKind.asset,
        location: assetPath,
      );
    }
    return null;
  }

  String _normalizeFileName(String fileName) {
    final normalized = fileName.trim().replaceAll('\\', '/');
    if (normalized.isEmpty) {
      return '';
    }
    final segments = normalized
        .split('/')
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (segments.isEmpty) {
      return '';
    }
    return segments.last;
  }

  List<String> _normalizedLanguageTags(List<String> tags) {
    final normalized = <String>{};
    for (final tag in tags) {
      final value = tag.trim().toLowerCase();
      if (value.isEmpty) {
        continue;
      }
      normalized.add(value.replaceAll('_', '-'));
      normalized.add(value.replaceAll('-', '_'));
    }
    normalized.remove('');
    return normalized.toList(growable: false);
  }

  Future<File?> _tryDownload(
    CstCloudResourceCacheService resourceCache,
    String remoteKey,
  ) async {
    try {
      final file = await resourceCache.ensureFileDownloaded(
        remoteKey,
        cacheRelativePath: remoteKey,
      );
      if (!await file.exists()) {
        return null;
      }
      if (await file.length() <= 0) {
        return null;
      }
      return file;
    } catch (_) {
      return null;
    }
  }
}

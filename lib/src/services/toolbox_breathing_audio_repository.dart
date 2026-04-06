import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'cstcloud_resource_cache_service.dart';
import 'toolbox_breathing_catalog.dart';

enum BreathingCueSourceKind { asset, remote }

class BreathingResolvedCue {
  const BreathingResolvedCue({
    required this.cue,
    required this.source,
    required this.kind,
    required this.location,
    this.duration,
  });

  final BreathingCueSpec cue;
  final Source source;
  final BreathingCueSourceKind kind;
  final String location;
  final Duration? duration;
}

class ToolboxBreathingAudioRepository {
  ToolboxBreathingAudioRepository(this._resourceCache);

  final CstCloudResourceCacheService? _resourceCache;
  final Map<String, Future<BreathingResolvedCue?>> _resolvedCache =
      <String, Future<BreathingResolvedCue?>>{};
  final Map<String, Future<Duration?>> _durationCache =
      <String, Future<Duration?>>{};
  final Map<String, Future<ByteData?>> _assetDataCache =
      <String, Future<ByteData?>>{};
  final Map<String, Future<Uint8List?>> _assetBytesCache =
      <String, Future<Uint8List?>>{};

  static const Map<String, String> _exactRemoteFileNameByCueId =
      <String, String>{
        'inhale_soft': '吸气.wav',
        'exhale_soft': '呼气.wav',
        'hold_soft': '屏息.wav',
        'nose_inhale': '鼻子吸气.wav',
        'nose_exhale': '鼻子呼气.wav',
        'mouth_inhale': '嘴吸气.wav',
        'mouth_exhale': '嘴呼气.wav',
        'preview_relax': '放松.wav',
        'preview_intro_1': '呼吸引导1.wav',
        'preview_intro_2': '呼吸引导2.wav',
        'preview_nose_slow': '开始用鼻子缓缓吸气.wav',
        'preview_parasym': '副交感交替.wav',
        'preview_altitude': '快速嘴吸气屏气.wav',
        'bolt_prepare': 'breathing_bolt_prepare.wav',
        'bolt_start': 'breathing_bolt_start.wav',
        'bolt_stop': 'breathing_bolt_stop.wav',
        'bolt_recover': 'breathing_bolt_recover.wav',
        'session_start': 'breathing_session_start.wav',
        'session_complete': 'breathing_session_complete.wav',
        'altitude_warning_short': 'breathing_altitude_warning_short.wav',
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

  Future<BreathingResolvedCue?> resolveScenarioStage(
    String scenarioId, {
    required int stageIndex,
    required BreathingStageKind stageKind,
    String? fallbackCueId,
    List<String> languageTags = const <String>[],
  }) {
    final normalizedTags = _normalizedLanguageTags(languageTags);
    final normalizedFallback = fallbackCueId?.trim() ?? '';
    final cacheKey =
        'stage|$scenarioId|$stageIndex|${stageKind.name}|$normalizedFallback|'
        '${normalizedTags.join(",")}';
    return _resolvedCache.putIfAbsent(
      cacheKey,
      () => _resolveScenarioStageInternal(
        scenarioId,
        stageIndex: stageIndex,
        stageKind: stageKind,
        fallbackCueId: normalizedFallback,
        languageTags: normalizedTags,
      ),
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

  List<String> candidateRemoteKeysForScenarioStage(
    String scenarioId, {
    required int stageIndex,
    required BreathingStageKind stageKind,
  }) {
    final normalizedScenarioId = scenarioId.trim();
    final normalizedPrefix = BreathingExperienceCatalog.remotePrefix.trim();
    if (normalizedScenarioId.isEmpty ||
        normalizedPrefix.isEmpty ||
        stageIndex < 0) {
      return const <String>[];
    }
    final stepToken = (stageIndex + 1).toString().padLeft(2, '0');
    final stageSuffix = _scenarioStageFileSuffix(stageKind);
    return <String>[
      '$normalizedPrefix/breathing_${normalizedScenarioId}_'
          '${stepToken}_$stageSuffix.wav',
    ];
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
        return _resolvedRemoteCue(cue, remoteKey, file);
      }
    }

    final assetPath = cue.assetPath?.trim() ?? '';
    if (assetPath.isEmpty) {
      return null;
    }
    final duration =
        await _durationForAsset(assetPath, cacheKey: assetPath) ??
        _approxCueDuration(cue);
    final assetBytes = await _assetBytesFor(assetPath);
    if (assetBytes == null || assetBytes.isEmpty) {
      return null;
    }
    return BreathingResolvedCue(
      cue: cue,
      source: BytesSource(assetBytes, mimeType: _mimeTypeForAsset(assetPath)),
      kind: BreathingCueSourceKind.asset,
      location: assetPath,
      duration: duration,
    );
  }

  Future<BreathingResolvedCue?> _resolveScenarioStageInternal(
    String scenarioId, {
    required int stageIndex,
    required BreathingStageKind stageKind,
    required String fallbackCueId,
    required List<String> languageTags,
  }) async {
    final fallbackCue = fallbackCueId.isEmpty
        ? null
        : BreathingExperienceCatalog.cues[fallbackCueId];
    final resourceCache = _resourceCache;
    if (resourceCache != null && fallbackCue != null) {
      for (final remoteKey in candidateRemoteKeysForScenarioStage(
        scenarioId,
        stageIndex: stageIndex,
        stageKind: stageKind,
      )) {
        final file = await _tryDownload(resourceCache, remoteKey);
        if (file == null) {
          continue;
        }
        return _resolvedRemoteCue(fallbackCue, remoteKey, file);
      }
    }

    if (fallbackCueId.isEmpty) {
      return null;
    }
    return _resolveInternal(fallbackCueId, languageTags);
  }

  Future<BreathingResolvedCue> _resolvedRemoteCue(
    BreathingCueSpec cue,
    String remoteKey,
    File file,
  ) async {
    final duration =
        await _durationForFile(file, cacheKey: remoteKey) ??
        _approxCueDuration(cue);
    return BreathingResolvedCue(
      cue: cue,
      source: DeviceFileSource(file.path),
      kind: BreathingCueSourceKind.remote,
      location: remoteKey,
      duration: duration,
    );
  }

  String _scenarioStageFileSuffix(BreathingStageKind stageKind) {
    return switch (stageKind) {
      BreathingStageKind.inhale => 'inhale',
      BreathingStageKind.hold => 'hold',
      BreathingStageKind.exhale => 'exhale',
      BreathingStageKind.rest => 'rest',
    };
  }

  Duration? _approxCueDuration(BreathingCueSpec cue) {
    if (cue.approxDurationMs <= 0) {
      return null;
    }
    return Duration(milliseconds: cue.approxDurationMs);
  }

  Future<Duration?> _durationForFile(File file, {required String cacheKey}) {
    return _durationCache.putIfAbsent('file|$cacheKey', () async {
      try {
        final totalLength = await file.length();
        if (totalLength <= 0) {
          return null;
        }
        final headerLength = totalLength < 4096 ? totalLength : 4096;
        final buffer = BytesBuilder(copy: false);
        await for (final chunk in file.openRead(0, headerLength)) {
          buffer.add(chunk);
        }
        return _tryParseWavDuration(
          buffer.takeBytes(),
          totalLength: totalLength,
        );
      } catch (_) {
        return null;
      }
    });
  }

  Future<Duration?> _durationForAsset(
    String assetPath, {
    required String cacheKey,
  }) {
    return _durationCache.putIfAbsent('asset|$cacheKey', () async {
      final data = await _assetDataFor(assetPath);
      if (data == null) {
        return null;
      }
      return _tryParseWavDuration(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        totalLength: data.lengthInBytes,
      );
    });
  }

  Future<ByteData?> _assetDataFor(String assetPath) {
    return _assetDataCache.putIfAbsent(assetPath, () async {
      for (final bundleKey in _candidateBundleKeysForAsset(assetPath)) {
        try {
          return await rootBundle.load(bundleKey);
        } catch (_) {
          continue;
        }
      }
      return null;
    });
  }

  Future<Uint8List?> _assetBytesFor(String assetPath) {
    return _assetBytesCache.putIfAbsent(assetPath, () async {
      final data = await _assetDataFor(assetPath);
      if (data == null) {
        return null;
      }
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    });
  }

  Iterable<String> _candidateBundleKeysForAsset(String assetPath) sync* {
    final normalizedPath = assetPath.trim().replaceAll('\\', '/');
    if (normalizedPath.isEmpty) {
      return;
    }

    final withPrefix = normalizedPath.startsWith('assets/')
        ? normalizedPath
        : 'assets/$normalizedPath';
    final segments = withPrefix
        .split('/')
        .where((segment) => segment.trim().isNotEmpty)
        .toList(growable: false);
    final candidates = <String>{withPrefix};
    if (segments.isNotEmpty) {
      candidates.add(segments.map(Uri.encodeComponent).join('/'));
      if (segments.length > 1) {
        candidates.add(
          <String>[
            ...segments.take(segments.length - 1),
            Uri.encodeComponent(segments.last),
          ].join('/'),
        );
      }
    }
    candidates.add(Uri.encodeFull(withPrefix));

    for (final candidate in candidates) {
      final key = candidate.trim();
      if (key.isNotEmpty) {
        yield key;
      }
    }
  }

  String _mimeTypeForAsset(String assetPath) {
    final normalized = assetPath.trim().toLowerCase();
    if (normalized.endsWith('.wav')) {
      return 'audio/wav';
    }
    if (normalized.endsWith('.mp3')) {
      return 'audio/mpeg';
    }
    if (normalized.endsWith('.m4a')) {
      return 'audio/mp4';
    }
    return 'application/octet-stream';
  }

  Duration? _tryParseWavDuration(Uint8List bytes, {int? totalLength}) {
    if (bytes.length < 12 ||
        _readAscii(bytes, 0, 4) != 'RIFF' ||
        _readAscii(bytes, 8, 4) != 'WAVE') {
      return null;
    }

    var offset = 12;
    int? byteRate;
    int? dataSize;
    while (offset + 8 <= bytes.length) {
      final chunkId = _readAscii(bytes, offset, 4);
      final chunkSize = _readUint32LE(bytes, offset + 4);
      final chunkDataOffset = offset + 8;
      final paddedChunkSize = chunkSize + (chunkSize.isOdd ? 1 : 0);
      final nextOffset = chunkDataOffset + paddedChunkSize;
      if (chunkId == 'fmt ' && chunkDataOffset + 16 <= bytes.length) {
        byteRate = _readUint32LE(bytes, chunkDataOffset + 8);
      } else if (chunkId == 'data') {
        dataSize = chunkSize;
        break;
      }
      if (nextOffset <= offset) {
        break;
      }
      offset = nextOffset;
    }

    final resolvedByteRate = byteRate;
    if (resolvedByteRate == null || resolvedByteRate <= 0) {
      return null;
    }
    final resolvedDataSize = dataSize ?? _fallbackDataSize(totalLength);
    if (resolvedDataSize == null || resolvedDataSize <= 0) {
      return null;
    }
    final durationMs = ((resolvedDataSize / resolvedByteRate) * 1000).round();
    if (durationMs <= 0) {
      return null;
    }
    return Duration(milliseconds: durationMs);
  }

  int? _fallbackDataSize(int? totalLength) {
    if (totalLength == null || totalLength <= 44) {
      return null;
    }
    return totalLength - 44;
  }

  String _readAscii(Uint8List bytes, int start, int length) {
    if (start < 0 || start + length > bytes.length) {
      return '';
    }
    return String.fromCharCodes(bytes.sublist(start, start + length));
  }

  int _readUint32LE(Uint8List bytes, int start) {
    if (start < 0 || start + 4 > bytes.length) {
      return 0;
    }
    return ByteData.sublistView(
      bytes,
      start,
      start + 4,
    ).getUint32(0, Endian.little);
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

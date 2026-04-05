import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'cstcloud_resource_cache_service.dart';
import 's3_bucket_probe.dart';

class BuiltInWordbookConfig {
  const BuiltInWordbookConfig({
    required this.path,
    required this.name,
    required this.sourcePath,
  });

  final String path;
  final String name;
  final String sourcePath;
}

abstract class BuiltInWordbookSource {
  Future<List<BuiltInWordbookConfig>> listBuiltInWordbooks();
  Future<Stream<List<int>>> openBuiltInWordbookByteStream(
    BuiltInWordbookConfig config, {
    ResourceDownloadProgressCallback? onProgress,
  });
  Future<String> loadBuiltInWordbookContent(
    BuiltInWordbookConfig config, {
    ResourceDownloadProgressCallback? onProgress,
  });
}

class AssetBuiltInWordbookSource implements BuiltInWordbookSource {
  const AssetBuiltInWordbookSource({
    this.dictAssetPrefix = 'assets/wordbooks/',
    this.dictBuiltinPathPrefix = 'builtin:dict:',
  });

  final String dictAssetPrefix;
  final String dictBuiltinPathPrefix;

  @override
  Future<List<BuiltInWordbookConfig>> listBuiltInWordbooks() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets =
          manifest
              .listAssets()
              .where(
                (path) =>
                    path.startsWith(dictAssetPrefix) &&
                    _isBuiltInWordbookAsset(path),
              )
              .toList(growable: false)
            ..sort();
      return assets.map(_buildConfigFromAsset).toList(growable: false);
    } catch (_) {
      return const <BuiltInWordbookConfig>[];
    }
  }

  @override
  Future<String> loadBuiltInWordbookContent(
    BuiltInWordbookConfig config, {
    ResourceDownloadProgressCallback? onProgress,
  }) async {
    final bundleData = await rootBundle.load(config.sourcePath);
    final bytes = bundleData.buffer.asUint8List();
    onProgress?.call(
      ResourceDownloadProgress(
        receivedBytes: bytes.length,
        totalBytes: bytes.length,
      ),
    );
    return decodeBuiltInWordbookBytes(config.sourcePath, bytes);
  }

  @override
  Future<Stream<List<int>>> openBuiltInWordbookByteStream(
    BuiltInWordbookConfig config, {
    ResourceDownloadProgressCallback? onProgress,
  }) async {
    final bundleData = await rootBundle.load(config.sourcePath);
    final bytes = bundleData.buffer.asUint8List();
    onProgress?.call(
      ResourceDownloadProgress(
        receivedBytes: bytes.length,
        totalBytes: bytes.length,
      ),
    );
    return Stream<List<int>>.value(bytes);
  }

  BuiltInWordbookConfig _buildConfigFromAsset(String assetPath) {
    final filename = p.basename(assetPath).trim();
    final normalizedFilename = filename.toLowerCase().endsWith('.json.gz')
        ? filename.substring(0, filename.length - '.json.gz'.length)
        : p.basenameWithoutExtension(filename);
    final baseName = normalizedFilename.trim().isEmpty
        ? 'dict'
        : normalizedFilename.trim();
    return BuiltInWordbookConfig(
      path: '$dictBuiltinPathPrefix$baseName',
      name: baseName,
      sourcePath: assetPath,
    );
  }

  bool _isBuiltInWordbookAsset(String assetPath) {
    final normalized = assetPath.toLowerCase();
    return normalized.endsWith('.json') || normalized.endsWith('.json.gz');
  }
}

class CstCloudBuiltInWordbookSource implements BuiltInWordbookSource {
  CstCloudBuiltInWordbookSource(
    this._cacheService, {
    BuiltInWordbookSource? fallback,
    this.remotePrefix = 'wordbooks/',
    this.dictBuiltinPathPrefix = 'builtin:dict:',
  }) : _fallback = fallback;

  final CstCloudResourceCacheService _cacheService;
  final BuiltInWordbookSource? _fallback;
  final String remotePrefix;
  final String dictBuiltinPathPrefix;

  @override
  Future<List<BuiltInWordbookConfig>> listBuiltInWordbooks() async {
    try {
      final objects = await _cacheService.listObjects(remotePrefix);
      final files =
          objects
              .where((item) => item.key.startsWith(remotePrefix))
              .where((item) => !item.key.endsWith('/'))
              .where((item) => _isBuiltInWordbookRemoteObject(item.key))
              .toList(growable: false)
            ..sort((a, b) => a.key.compareTo(b.key));
      return files.map(_buildConfigFromRemoteObject).toList(growable: false);
    } catch (_) {
      if (_fallback != null) {
        return _fallback.listBuiltInWordbooks();
      }
      return const <BuiltInWordbookConfig>[];
    }
  }

  @override
  Future<String> loadBuiltInWordbookContent(
    BuiltInWordbookConfig config, {
    ResourceDownloadProgressCallback? onProgress,
  }) async {
    try {
      return await _cacheService.readText(
        config.sourcePath,
        cacheRelativePath: config.sourcePath,
        onProgress: onProgress,
      );
    } catch (_) {
      if (_fallback != null) {
        return _fallback.loadBuiltInWordbookContent(
          config,
          onProgress: onProgress,
        );
      }
      rethrow;
    }
  }

  @override
  Future<Stream<List<int>>> openBuiltInWordbookByteStream(
    BuiltInWordbookConfig config, {
    ResourceDownloadProgressCallback? onProgress,
  }) async {
    try {
      final file = await _cacheService.ensureFileDownloaded(
        config.sourcePath,
        cacheRelativePath: config.sourcePath,
        onProgress: onProgress,
      );
      return file.openRead();
    } catch (_) {
      if (_fallback != null) {
        return _fallback.openBuiltInWordbookByteStream(
          config,
          onProgress: onProgress,
        );
      }
      rethrow;
    }
  }

  BuiltInWordbookConfig _buildConfigFromRemoteObject(S3ObjectSummary object) {
    final filename = p.basename(object.key).trim();
    final normalizedFilename = filename.toLowerCase().endsWith('.json.gz')
        ? filename.substring(0, filename.length - '.json.gz'.length)
        : p.basenameWithoutExtension(filename);
    final baseName = normalizedFilename.trim().isEmpty
        ? 'dict'
        : normalizedFilename.trim();
    return BuiltInWordbookConfig(
      path: '$dictBuiltinPathPrefix$baseName',
      name: baseName,
      sourcePath: object.key,
    );
  }

  bool _isBuiltInWordbookRemoteObject(String key) {
    final normalized = key.toLowerCase();
    return normalized.endsWith('.json') || normalized.endsWith('.json.gz');
  }
}

String decodeBuiltInWordbookBytes(String sourcePath, List<int> bytes) {
  final normalized = sourcePath.toLowerCase();
  final decodedBytes = normalized.endsWith('.json.gz')
      ? GZipCodec().decode(bytes)
      : bytes;
  return utf8.decode(decodedBytes);
}

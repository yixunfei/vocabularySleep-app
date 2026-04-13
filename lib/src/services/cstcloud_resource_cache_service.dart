import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'cstcloud_s3_compat_client.dart';
import 's3_bucket_probe.dart';

class ResourceDownloadProgress {
  const ResourceDownloadProgress({
    required this.receivedBytes,
    required this.totalBytes,
  });

  final int receivedBytes;
  final int totalBytes;

  double? get progress =>
      totalBytes <= 0 ? null : (receivedBytes / totalBytes).clamp(0.0, 1.0);
}

typedef ResourceDownloadProgressCallback =
    void Function(ResourceDownloadProgress progress);

class CstCloudResourceCacheService {
  CstCloudResourceCacheService({CstCloudS3CompatClient? client})
    : _client = client ?? CstCloudS3CompatClient();

  final CstCloudS3CompatClient _client;
  final Map<String, Future<File>> _downloadFutures = <String, Future<File>>{};

  Future<List<S3ObjectSummary>> listObjects(
    String prefix, {
    int maxKeys = 1000,
  }) {
    return _client.listPrefix(prefix, maxKeys: maxKeys);
  }

  Future<Uint8List> readBytes(
    String remoteKey, {
    String? cacheRelativePath,
    ResourceDownloadProgressCallback? onProgress,
  }) async {
    final file = await ensureFileDownloaded(
      remoteKey,
      cacheRelativePath: cacheRelativePath,
      onProgress: onProgress,
    );
    return file.readAsBytes();
  }

  Future<String> readText(
    String remoteKey, {
    String? cacheRelativePath,
    ResourceDownloadProgressCallback? onProgress,
  }) async {
    final bytes = await readBytes(
      remoteKey,
      cacheRelativePath: cacheRelativePath,
      onProgress: onProgress,
    );
    final normalized = remoteKey.toLowerCase();
    final decodedBytes = normalized.endsWith('.gz')
        ? const GZipDecoder().decodeBytes(bytes)
        : bytes;
    return utf8.decode(decodedBytes);
  }

  Future<File> ensureFileDownloaded(
    String remoteKey, {
    String? cacheRelativePath,
    ResourceDownloadProgressCallback? onProgress,
  }) async {
    final targetPath = cacheRelativePath?.trim().isNotEmpty == true
        ? cacheRelativePath!.trim()
        : remoteKey;
    final normalizedTargetPath = targetPath.replaceAll('\\', '/');
    final baseDir = await _cacheBaseDir();
    final targetFile = File(p.join(baseDir.path, normalizedTargetPath));
    if (await targetFile.exists()) {
      final existingBytes = await targetFile.length();
      onProgress?.call(
        ResourceDownloadProgress(
          receivedBytes: existingBytes,
          totalBytes: existingBytes,
        ),
      );
      return targetFile;
    }

    final inFlight = _downloadFutures[normalizedTargetPath];
    if (inFlight != null) {
      if (onProgress != null) {
        inFlight
            .then((file) async {
              final size = await file.length();
              onProgress(
                ResourceDownloadProgress(receivedBytes: size, totalBytes: size),
              );
            })
            .catchError((_) {
              // Surface the original error through the awaited future only.
            });
      }
      return inFlight;
    }

    final future = _ensureFileDownloadedImpl(
      remoteKey,
      targetFile,
      onProgress: onProgress,
    );
    _downloadFutures[normalizedTargetPath] = future;
    return future.whenComplete(() {
      _downloadFutures.remove(normalizedTargetPath);
    });
  }

  Future<bool> hasCachedFilesUnderPrefix(String prefix) async {
    final normalized = prefix.trim();
    if (normalized.isEmpty) return false;
    final baseDir = await _cacheBaseDir();
    final targetDir = Directory(
      p.join(baseDir.path, normalized.replaceAll('\\', '/')),
    );
    if (!await targetDir.exists()) {
      return false;
    }
    await for (final entity in targetDir.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) {
        return true;
      }
    }
    return false;
  }

  Future<Directory> _cacheBaseDir() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(supportDir.path, 'remote_resource_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _ensureFileDownloadedImpl(
    String remoteKey,
    File targetFile, {
    ResourceDownloadProgressCallback? onProgress,
  }) async {
    await targetFile.parent.create(recursive: true);
    final tempFile = File('${targetFile.path}.part');
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    try {
      await _client.downloadObjectToFile(
        remoteKey,
        tempFile,
        onProgress: onProgress == null
            ? null
            : (receivedBytes, totalBytes) {
                onProgress(
                  ResourceDownloadProgress(
                    receivedBytes: receivedBytes,
                    totalBytes: totalBytes,
                  ),
                );
              },
      );
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await tempFile.rename(targetFile.path);
      final size = await targetFile.length();
      onProgress?.call(
        ResourceDownloadProgress(receivedBytes: size, totalBytes: size),
      );
      return targetFile;
    } catch (_) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }
}

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

  double? get progress => totalBytes <= 0
      ? null
      : (receivedBytes / totalBytes).clamp(0.0, 1.0);
}

typedef ResourceDownloadProgressCallback =
    void Function(ResourceDownloadProgress progress);

class CstCloudResourceCacheService {
  CstCloudResourceCacheService({CstCloudS3CompatClient? client})
    : _client = client ?? CstCloudS3CompatClient();

  final CstCloudS3CompatClient _client;

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
        ? GZipDecoder().decodeBytes(bytes)
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
    final baseDir = await _cacheBaseDir();
    final targetFile = File(p.join(baseDir.path, targetPath));
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
    await targetFile.parent.create(recursive: true);
    final bytes = await _client.getObjectBytes(
      remoteKey,
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
    await targetFile.writeAsBytes(bytes, flush: true);
    onProgress?.call(
      ResourceDownloadProgress(
        receivedBytes: bytes.length,
        totalBytes: bytes.length,
      ),
    );
    return targetFile;
  }

  Future<Directory> _cacheBaseDir() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(supportDir.path, 'remote_resource_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}

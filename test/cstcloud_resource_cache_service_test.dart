import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:vocabulary_sleep_app/src/services/cstcloud_resource_cache_service.dart';
import 'package:vocabulary_sleep_app/src/services/cstcloud_s3_compat_client.dart';
import 'package:vocabulary_sleep_app/src/services/s3_bucket_probe.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('resource_cache_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('reuses a valid cached file without downloading', () async {
    final target = File(p.join(tempDir.path, 'audio', 'cue.bin'));
    await target.parent.create(recursive: true);
    await target.writeAsBytes(<int>[7, 8], flush: true);
    final client = _FakeResourceClient(<Uint8List>[
      Uint8List.fromList(<int>[1, 2]),
    ]);
    final service = CstCloudResourceCacheService(
      client: client,
      cacheDirectory: tempDir,
    );

    final resolved = await service.ensureValidFileDownloaded(
      'audio/cue.bin',
      validator: _markerFileValidator,
    );

    expect(await resolved.exists(), isTrue);
    expect(client.downloadCalls, 0);
  });

  test('deletes an invalid cache entry and downloads a replacement', () async {
    final target = File(p.join(tempDir.path, 'audio', 'cue.bin'));
    await target.parent.create(recursive: true);
    await target.writeAsBytes(<int>[0], flush: true);
    final client = _FakeResourceClient(<Uint8List>[
      Uint8List.fromList(<int>[7, 8]),
    ]);
    final service = CstCloudResourceCacheService(
      client: client,
      cacheDirectory: tempDir,
    );

    final resolved = await service.ensureValidFileDownloaded(
      'audio/cue.bin',
      validator: _markerFileValidator,
    );

    expect(await resolved.readAsBytes(), <int>[7, 8]);
    expect(client.downloadCalls, 1);
  });

  test('removes a replacement that still fails validation', () async {
    final client = _FakeResourceClient(<Uint8List>[
      Uint8List.fromList(<int>[1]),
      Uint8List.fromList(<int>[2]),
    ]);
    final service = CstCloudResourceCacheService(
      client: client,
      cacheDirectory: tempDir,
    );

    await expectLater(
      service.ensureValidFileDownloaded(
        'audio/cue.bin',
        validator: _markerFileValidator,
      ),
      throwsA(isA<StateError>()),
    );

    final target = File(p.join(tempDir.path, 'audio', 'cue.bin'));
    expect(await target.exists(), isFalse);
    expect(await File('${target.path}.part').exists(), isFalse);
    expect(client.downloadCalls, 2);
  });

  test('cleans an empty existing file before a normal download', () async {
    final target = File(p.join(tempDir.path, 'audio', 'cue.bin'));
    await target.parent.create(recursive: true);
    await target.writeAsBytes(const <int>[], flush: true);
    final client = _FakeResourceClient(<Uint8List>[
      Uint8List.fromList(<int>[3]),
    ]);
    final service = CstCloudResourceCacheService(
      client: client,
      cacheDirectory: tempDir,
    );

    final resolved = await service.ensureFileDownloaded('audio/cue.bin');

    expect(await resolved.readAsBytes(), <int>[3]);
    expect(client.downloadCalls, 1);
  });

  test('removes a stale partial artifact beside a valid cache entry', () async {
    final target = File(p.join(tempDir.path, 'audio', 'cue.bin'));
    final partial = File('${target.path}.part');
    await target.parent.create(recursive: true);
    await target.writeAsBytes(<int>[3], flush: true);
    await partial.writeAsBytes(<int>[4], flush: true);
    final service = CstCloudResourceCacheService(cacheDirectory: tempDir);

    final resolved = await service.ensureFileDownloaded('audio/cue.bin');

    expect(await resolved.readAsBytes(), <int>[3]);
    expect(await partial.exists(), isFalse);
  });

  test('removes the partial file when a download fails', () async {
    final client = _FakeResourceClient(<Uint8List>[
      Uint8List.fromList(<int>[9, 9]),
    ], failAfterWrite: true);
    final service = CstCloudResourceCacheService(
      client: client,
      cacheDirectory: tempDir,
    );

    await expectLater(
      service.ensureFileDownloaded('audio/cue.bin'),
      throwsA(isA<StateError>()),
    );

    final target = File(p.join(tempDir.path, 'audio', 'cue.bin'));
    expect(await target.exists(), isFalse);
    expect(await File('${target.path}.part').exists(), isFalse);
  });

  test('cleans a cached file when text decoding fails', () async {
    final client = _FakeResourceClient(<Uint8List>[
      Uint8List.fromList(<int>[1, 2, 3]),
    ]);
    final service = CstCloudResourceCacheService(
      client: client,
      cacheDirectory: tempDir,
    );

    await expectLater(
      service.readText('data/catalog.json.gz'),
      throwsA(isA<Object>()),
    );

    final target = File(p.join(tempDir.path, 'data', 'catalog.json.gz'));
    expect(await target.exists(), isFalse);
  });

  test(
    'deleteCachedFile removes both the target and partial artifacts',
    () async {
      final target = File(p.join(tempDir.path, 'audio', 'cue.bin'));
      final partial = File('${target.path}.part');
      await target.parent.create(recursive: true);
      await target.writeAsBytes(<int>[1], flush: true);
      await partial.writeAsBytes(<int>[2], flush: true);
      final service = CstCloudResourceCacheService(cacheDirectory: tempDir);

      expect(await service.deleteCachedFile('audio/cue.bin'), isTrue);
      expect(await target.exists(), isFalse);
      expect(await partial.exists(), isFalse);
    },
  );

  test('only one validated download runs for concurrent callers', () async {
    final client = _FakeResourceClient(<Uint8List>[
      Uint8List.fromList(<int>[7, 8]),
    ]);
    final service = CstCloudResourceCacheService(
      client: client,
      cacheDirectory: tempDir,
    );

    final first = service.ensureValidFileDownloaded(
      'audio/cue.bin',
      validator: _markerFileValidator,
    );
    final second = service.ensureValidFileDownloaded(
      'audio/cue.bin',
      validator: _markerFileValidator,
    );
    final files = await Future.wait(<Future<File>>[first, second]);

    expect(files[0].path, files[1].path);
    expect(client.downloadCalls, 1);
  });

  test('retries once when the first validated download fails', () async {
    final file = File(p.join(tempDir.path, 'audio', 'cue.bin'));
    final cache = _FailOnceCacheService(file);

    final resolved = await cache.ensureValidFileDownloaded(
      'audio/cue.bin',
      validator: _markerFileValidator,
    );

    expect(await resolved.readAsBytes(), <int>[7, 8]);
    expect(cache.calls, 2);
  });

  test(
    'retries after a failed network write and removes the partial file',
    () async {
      final client = _FailOnceResourceClient(Uint8List.fromList(<int>[7, 8]));
      final service = CstCloudResourceCacheService(
        client: client,
        cacheDirectory: tempDir,
      );

      final resolved = await service.ensureValidFileDownloaded(
        'audio/cue.bin',
        validator: _markerFileValidator,
      );

      expect(await resolved.readAsBytes(), <int>[7, 8]);
      expect(client.downloadCalls, 2);
      expect(
        await File(p.join(tempDir.path, 'audio', 'cue.bin.part')).exists(),
        isFalse,
      );
    },
  );

  test('partial artifacts do not count as cached resources', () async {
    final partial = File(p.join(tempDir.path, 'audio', 'cue.bin.part'));
    await partial.parent.create(recursive: true);
    await partial.writeAsBytes(<int>[1], flush: true);
    final service = CstCloudResourceCacheService(cacheDirectory: tempDir);

    expect(await service.hasCachedFilesUnderPrefix('audio'), isFalse);
  });

  test(
    'S3 client removes a file when the reported write count is wrong',
    () async {
      final target = File(p.join(tempDir.path, 'audio', 'cue.bin'));
      final client = CstCloudS3CompatClient(
        probeClient: _FakeProbeClient(
          result: const S3DownloadObjectResult(
            contentType: 'audio/wav',
            contentLength: 4,
            writtenBytes: 4,
          ),
          bytesToWrite: <int>[1, 2],
        ),
      );

      await expectLater(
        client.downloadObjectToFile('audio/cue.bin', target),
        throwsA(isA<StateError>()),
      );
      expect(await target.exists(), isFalse);
    },
  );
}

Future<bool> _markerFileValidator(File file) async {
  final bytes = await file.readAsBytes();
  return bytes.length >= 2 && bytes.first == 7;
}

class _FakeResourceClient extends CstCloudS3CompatClient {
  _FakeResourceClient(this.payloads, {this.failAfterWrite = false});

  final List<Uint8List> payloads;
  final bool failAfterWrite;
  int downloadCalls = 0;

  @override
  Future<File> downloadObjectToFile(
    String objectKey,
    File targetFile, {
    void Function(int receivedBytes, int totalBytes)? onProgress,
  }) async {
    downloadCalls += 1;
    if (payloads.isEmpty) {
      throw StateError('No fake payload remains for $objectKey');
    }
    final payload = payloads.removeAt(0);
    await targetFile.parent.create(recursive: true);
    await targetFile.writeAsBytes(payload, flush: true);
    onProgress?.call(payload.length, payload.length);
    if (failAfterWrite) {
      throw StateError('Simulated download failure for $objectKey');
    }
    return targetFile;
  }
}

class _FailOnceCacheService extends CstCloudResourceCacheService {
  _FailOnceCacheService(this.file);

  final File file;
  int calls = 0;

  @override
  Future<File> ensureFileDownloaded(
    String remoteKey, {
    String? cacheRelativePath,
    ResourceDownloadProgressCallback? onProgress,
  }) async {
    calls += 1;
    if (calls == 1) {
      throw StateError('simulated unavailable download');
    }
    await file.parent.create(recursive: true);
    await file.writeAsBytes(<int>[7, 8], flush: true);
    return file;
  }
}

class _FakeProbeClient extends S3BucketProbeClient {
  _FakeProbeClient({required this.result, required this.bytesToWrite})
    : super(
        config: const S3BucketProbeConfig(
          endpoint: 'example.test',
          bucket: 'bucket',
          accessKeyId: 'key',
          secretAccessKey: 'secret',
        ),
      );

  final S3DownloadObjectResult result;
  final List<int> bytesToWrite;

  @override
  Future<S3DownloadObjectResult> downloadObjectToFile(
    String objectKey,
    File targetFile, {
    void Function(int receivedBytes, int totalBytes)? onProgress,
  }) async {
    await targetFile.parent.create(recursive: true);
    await targetFile.writeAsBytes(bytesToWrite, flush: true);
    onProgress?.call(bytesToWrite.length, result.contentLength);
    return result;
  }
}

class _FailOnceResourceClient extends CstCloudS3CompatClient {
  _FailOnceResourceClient(this.payload);

  final Uint8List payload;
  int downloadCalls = 0;
  bool _failed = false;

  @override
  Future<File> downloadObjectToFile(
    String objectKey,
    File targetFile, {
    void Function(int receivedBytes, int totalBytes)? onProgress,
  }) async {
    downloadCalls += 1;
    await targetFile.parent.create(recursive: true);
    await targetFile.writeAsBytes(payload, flush: true);
    onProgress?.call(payload.length, payload.length);
    if (!_failed) {
      _failed = true;
      throw StateError('simulated network interruption');
    }
    return targetFile;
  }
}

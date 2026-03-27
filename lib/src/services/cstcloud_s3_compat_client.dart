import 'dart:typed_data';

import 's3_bucket_probe.dart';

class CstCloudS3CompatClient {
  CstCloudS3CompatClient({S3BucketProbeClient? probeClient})
    : _probeClient =
          probeClient ??
          S3BucketProbeClient(
            config: const S3BucketProbeConfig(
              endpoint: _endpoint,
              bucket: _bucket,
              accessKeyId: _accessKeyId,
              secretAccessKey: _secretAccessKey,
              region: _region,
              userAgent: _userAgent,
            ),
          );

  static const String _endpoint = 's3.cstcloud.cn';
  static const String _bucket = '32be744530ff4a4b9be7bf802bd959b8';
  static const String _region = 'us-east-1';
  static const String _userAgent = 'S3 Browser 13.1.1';

  // NOTE: The current CSTCloud S3 compatibility layer accepts standard
  // Signature V4 only when the request source matches the S3 Browser style
  // user-agent above. This client centralizes that compatibility behavior.
  static const String _accessKeyId = 'AKIAWACWCLYJA9JV9K4T';
  static const String _secretAccessKey =
      '65=KRYW55Y7E1817UJZZ6CDURMQO7/8QUX=6C1JJ';

  final S3BucketProbeClient _probeClient;

  Future<List<S3ObjectSummary>> listPrefix(
    String prefix, {
    int maxKeys = 1000,
  }) async {
    final result = await _probeClient.listObjects(
      prefix: prefix,
      maxKeys: maxKeys,
    );
    return result.objects;
  }

  Future<S3HeadObjectResult> headObject(String objectKey) {
    return _probeClient.headObject(objectKey);
  }

  Future<Uint8List> getObjectBytes(
    String objectKey, {
    void Function(int receivedBytes, int totalBytes)? onProgress,
  }) async {
    final result = await _probeClient.getObject(
      objectKey,
      onProgress: onProgress,
    );
    return Uint8List.fromList(result.bytes);
  }

  Future<Uint8List> getObjectRange(
    String objectKey, {
    required int start,
    required int end,
  }) async {
    final result = await _probeClient.getObjectRange(
      objectKey,
      start: start,
      end: end,
    );
    return Uint8List.fromList(result.bytes);
  }

  Future<void> close() => _probeClient.close();
}

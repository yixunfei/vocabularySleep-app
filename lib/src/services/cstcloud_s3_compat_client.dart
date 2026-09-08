import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 's3_bucket_probe.dart';

/// S3 兼容存储客户端 (CST Cloud)
///
/// 支持环境变量配置，默认使用公开只读凭据
/// 配置项（可选）：
/// - S3_ENDPOINT: 服务端点 (默认：s3.cstcloud.cn)
/// - S3_BUCKET: 存储桶名称 (默认：32be744530ff4a4b9be7bf802bd959b8)
/// - S3_REGION: 区域 (默认：us-east-1)
/// - S3_USER_AGENT: User-Agent 标识 (默认：S3 browser 13.1.1)
class CstCloudS3CompatClient {
  CstCloudS3CompatClient({
    S3BucketProbeClient? probeClient,
    String? endpoint,
    String? bucket,
    String? region,
    String? accessKeyId,
    String? secretAccessKey,
    String? userAgent,
  }) : _probeClient =
           probeClient ??
           S3BucketProbeClient(
             config: S3BucketProbeConfig(
               endpoint: endpoint ?? _getEnv('S3_ENDPOINT', _endpoint),
               bucket: bucket ?? _getEnv('S3_BUCKET', _bucket),
               accessKeyId:
                   accessKeyId ?? _getEnv('S3_ACCESS_KEY_ID', _accessKeyId),
               secretAccessKey:
                   secretAccessKey ??
                   _getEnv('S3_SECRET_ACCESS_KEY', _secretAccessKey),
               region: region ?? _getEnv('S3_REGION', _region),
               userAgent: userAgent ?? _getEnv('S3_USER_AGENT', _userAgent),
             ),
           );

  // 默认公开只读凭据
  static const String _endpoint = 's3.cstcloud.cn';
  static const String _bucket = '32be744530ff4a4b9be7bf802bd959b8';
  static const String _region = 'us-east-1';
  static const String _userAgent = 'S3 browser 13.1.1';
  static const String _accessKeyId = 'AKIAWACWCLYJA9JV9K4T';
  static const String _secretAccessKey =
      '65=KRYW55Y7E1817UJZZ6CDURMQO7/8QUX=6C1JJ';

  static String _getEnv(String key, String defaultValue) {
    try {
      if (dotenv.isInitialized) {
        final value = dotenv.env[key];
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    } catch (_) {
      // dotenv 未初始化时使用默认值
    }

    // 回退到系统环境变量
    final sysEnv = Platform.environment[key];
    if (sysEnv != null && sysEnv.isNotEmpty) {
      return sysEnv;
    }

    return defaultValue;
  }

  final S3BucketProbeClient _probeClient;

  /// 列出指定前缀的对象
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

  /// 获取对象元数据
  Future<S3HeadObjectResult> headObject(String objectKey) {
    return _probeClient.headObject(objectKey);
  }

  /// 获取对象字节数据
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

  Future<File> downloadObjectToFile(
    String objectKey,
    File targetFile, {
    void Function(int receivedBytes, int totalBytes)? onProgress,
  }) async {
    try {
      final result = await _probeClient.downloadObjectToFile(
        objectKey,
        targetFile,
        onProgress: onProgress,
      );
      if (result.writtenBytes <= 0) {
        throw StateError('Downloaded object is empty: $objectKey');
      }
      final actualBytes = await targetFile.length();
      if (actualBytes != result.writtenBytes) {
        throw StateError(
          'Downloaded object write count mismatch: $objectKey '
          '($actualBytes/${result.writtenBytes} bytes)',
        );
      }
      if (result.contentLength > 0 &&
          result.writtenBytes != result.contentLength) {
        throw StateError(
          'Downloaded object is incomplete: $objectKey '
          '(${result.writtenBytes}/${result.contentLength} bytes)',
        );
      }
      return targetFile;
    } catch (_) {
      for (final file in <File>[targetFile, File('${targetFile.path}.part')]) {
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {
          // Best-effort cleanup; preserve the original download error.
        }
      }
      rethrow;
    }
  }

  /// 获取对象范围数据
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

  /// 关闭客户端
  Future<void> close() => _probeClient.close();
}

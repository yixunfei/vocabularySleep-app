import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class S3BucketProbeConfig {
  const S3BucketProbeConfig({
    required this.endpoint,
    required this.bucket,
    required this.accessKeyId,
    required this.secretAccessKey,
    this.region = 'us-east-1',
    this.useHttps = true,
    this.userAgent,
  });

  final String endpoint;
  final String bucket;
  final String accessKeyId;
  final String secretAccessKey;
  final String region;
  final bool useHttps;
  final String? userAgent;
}

class S3ObjectSummary {
  const S3ObjectSummary({
    required this.key,
    required this.size,
    this.eTag,
    this.lastModified,
  });

  final String key;
  final int size;
  final String? eTag;
  final DateTime? lastModified;
}

class S3ListBucketResult {
  const S3ListBucketResult({
    required this.name,
    required this.prefix,
    required this.maxKeys,
    required this.isTruncated,
    required this.objects,
  });

  final String name;
  final String prefix;
  final int maxKeys;
  final bool isTruncated;
  final List<S3ObjectSummary> objects;
}

class S3HeadObjectResult {
  const S3HeadObjectResult({
    required this.contentLength,
    required this.contentType,
    this.lastModified,
    this.contentDisposition,
    this.eTag,
  });

  final int contentLength;
  final String contentType;
  final DateTime? lastModified;
  final String? contentDisposition;
  final String? eTag;
}

class S3RangeObjectResult {
  const S3RangeObjectResult({
    required this.bytes,
    required this.contentType,
    this.contentRange,
  });

  final List<int> bytes;
  final String contentType;
  final String? contentRange;
}

class S3GetObjectResult {
  const S3GetObjectResult({required this.bytes, required this.contentType});

  final List<int> bytes;
  final String contentType;
}

class S3DownloadObjectResult {
  const S3DownloadObjectResult({
    required this.contentType,
    required this.contentLength,
    required this.writtenBytes,
  });

  final String contentType;
  final int contentLength;
  final int writtenBytes;
}

class S3BucketProbeClient {
  S3BucketProbeClient({required this.config, HttpClient? httpClient})
    : _httpClient = httpClient ?? HttpClient();

  final S3BucketProbeConfig config;
  final HttpClient _httpClient;

  Future<void> close() async {
    _httpClient.close(force: true);
  }

  Future<S3ListBucketResult> listObjects({
    String prefix = '',
    int maxKeys = 20,
  }) async {
    final queryParameters = <String, String>{
      'list-type': '2',
      'max-keys': '$maxKeys',
      if (prefix.trim().isNotEmpty) 'prefix': prefix.trim(),
    };
    final uri = _buildUri(queryParameters);
    final signed = _signRequest(uri, queryParameters: queryParameters);
    final request = await _httpClient.getUrl(uri);
    signed.headers.forEach(request.headers.set);
    final response = await request.close();
    final body = await utf8.decodeStream(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'S3 probe failed with ${response.statusCode}: $body',
        uri: uri,
      );
    }
    return parseListBucketXml(body);
  }

  Future<S3HeadObjectResult> headObject(String objectKey) async {
    final uri = _buildObjectUri(objectKey);
    final signed = _signRequest(uri, method: 'HEAD');
    final request = await _httpClient.openUrl('HEAD', uri);
    signed.headers.forEach(request.headers.set);
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await utf8.decodeStream(response);
      throw HttpException(
        'S3 head probe failed with ${response.statusCode}: $body',
        uri: uri,
      );
    }
    return S3HeadObjectResult(
      contentLength:
          int.tryParse(
            response.headers.value(HttpHeaders.contentLengthHeader) ?? '0',
          ) ??
          0,
      contentType:
          response.headers.value(HttpHeaders.contentTypeHeader) ??
          'application/octet-stream',
      lastModified: _tryParseHttpDate(
        response.headers.value(HttpHeaders.lastModifiedHeader),
      ),
      contentDisposition:
          response.headers.value('content-disposition') ??
          response.headers.value('content-dcosition'),
      eTag: response.headers.value(HttpHeaders.etagHeader),
    );
  }

  Future<S3RangeObjectResult> getObjectRange(
    String objectKey, {
    required int start,
    required int end,
  }) async {
    final uri = _buildObjectUri(objectKey);
    final signed = _signRequest(uri);
    final request = await _httpClient.getUrl(uri);
    signed.headers.forEach(request.headers.set);
    request.headers.set(HttpHeaders.rangeHeader, 'bytes=$start-$end');
    final response = await request.close();
    final bytes = await _readAllBytes(response);
    if (response.statusCode < 200 || response.statusCode >= 299) {
      throw HttpException(
        'S3 range probe failed with ${response.statusCode}: ${utf8.decode(bytes, allowMalformed: true)}',
        uri: uri,
      );
    }
    return S3RangeObjectResult(
      bytes: bytes,
      contentType:
          response.headers.value(HttpHeaders.contentTypeHeader) ??
          'application/octet-stream',
      contentRange: response.headers.value(HttpHeaders.contentRangeHeader),
    );
  }

  Future<S3GetObjectResult> getObject(
    String objectKey, {
    void Function(int receivedBytes, int totalBytes)? onProgress,
  }) async {
    final uri = _buildObjectUri(objectKey);
    final signed = _signRequest(uri);
    final request = await _httpClient.getUrl(uri);
    signed.headers.forEach(request.headers.set);
    final response = await request.close();
    final totalBytes =
        int.tryParse(
          response.headers.value(HttpHeaders.contentLengthHeader) ?? '',
        ) ??
        0;
    final bytes = await _readAllBytes(
      response,
      onProgress: onProgress,
      totalBytes: totalBytes,
    );
    if (response.statusCode < 200 || response.statusCode >= 299) {
      throw HttpException(
        'S3 get probe failed with ${response.statusCode}: ${utf8.decode(bytes, allowMalformed: true)}',
        uri: uri,
      );
    }
    return S3GetObjectResult(
      bytes: bytes,
      contentType:
          response.headers.value(HttpHeaders.contentTypeHeader) ??
          'application/octet-stream',
    );
  }

  Future<S3DownloadObjectResult> downloadObjectToFile(
    String objectKey,
    File targetFile, {
    void Function(int receivedBytes, int totalBytes)? onProgress,
  }) async {
    final uri = _buildObjectUri(objectKey);
    final signed = _signRequest(uri);
    final request = await _httpClient.getUrl(uri);
    signed.headers.forEach(request.headers.set);
    final response = await request.close();
    final totalBytes =
        int.tryParse(
          response.headers.value(HttpHeaders.contentLengthHeader) ?? '',
        ) ??
        0;
    if (response.statusCode < 200 || response.statusCode >= 299) {
      final bytes = await _readAllBytes(
        response,
        onProgress: onProgress,
        totalBytes: totalBytes,
      );
      throw HttpException(
        'S3 get probe failed with ${response.statusCode}: ${utf8.decode(bytes, allowMalformed: true)}',
        uri: uri,
      );
    }

    IOSink? sink;
    var writtenBytes = 0;
    var lastReportedBytes = 0;
    const reportInterval = 64 * 1024;

    void report({bool force = false}) {
      if (onProgress == null) return;
      if (!force && totalBytes > 0) {
        final percentProgress = writtenBytes * 100 ~/ totalBytes;
        final lastPercentProgress = lastReportedBytes * 100 ~/ totalBytes;
        final bytesProgress = writtenBytes - lastReportedBytes;
        if (writtenBytes < totalBytes &&
            bytesProgress < reportInterval &&
            percentProgress == lastPercentProgress) {
          return;
        }
      }
      lastReportedBytes = writtenBytes;
      onProgress(writtenBytes, totalBytes);
    }

    try {
      await targetFile.parent.create(recursive: true);
      sink = targetFile.openWrite();
      report(force: true);
      await for (final chunk in response) {
        sink.add(chunk);
        writtenBytes += chunk.length;
        report();
      }
      await sink.flush();
      await sink.close();
      report(force: true);
    } catch (_) {
      try {
        await sink?.close();
      } catch (_) {}
      rethrow;
    }

    return S3DownloadObjectResult(
      contentType:
          response.headers.value(HttpHeaders.contentTypeHeader) ??
          'application/octet-stream',
      contentLength: totalBytes,
      writtenBytes: writtenBytes,
    );
  }

  Uri _buildUri(Map<String, String> queryParameters) {
    final path = '/${config.bucket}';
    return config.useHttps
        ? Uri.https(config.endpoint, path, queryParameters)
        : Uri.http(config.endpoint, path, queryParameters);
  }

  Uri _buildObjectUri(String objectKey) {
    final normalizedKey = objectKey.startsWith('/')
        ? objectKey.substring(1)
        : objectKey;
    final path = '/${config.bucket}/$normalizedKey';
    return config.useHttps
        ? Uri.https(config.endpoint, path)
        : Uri.http(config.endpoint, path);
  }

  SignedS3Request _signRequest(
    Uri uri, {
    String method = 'GET',
    Map<String, String> queryParameters = const <String, String>{},
    DateTime? now,
  }) {
    final timestamp = (now ?? DateTime.now().toUtc());
    final amzDate = _formatAmzDate(timestamp);
    final dateStamp = _formatDateStamp(timestamp);
    const payloadHash =
        'e3b0c44298fc1c149afbf4c8996fb924'
        '27ae41e4649b934ca495991b7852b855';
    final canonicalQuery = queryParameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final canonicalQueryString = canonicalQuery
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}='
              '${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
    final canonicalHeaders =
        'host:${uri.host}\n'
        'x-amz-content-sha256:$payloadHash\n'
        'x-amz-date:$amzDate\n';
    const signedHeaders = 'host;x-amz-content-sha256;x-amz-date';
    final canonicalRequest =
        '$method\n'
        '${uri.path}\n'
        '$canonicalQueryString\n'
        '$canonicalHeaders\n'
        '$signedHeaders\n'
        '$payloadHash';
    final credentialScope = '$dateStamp/${config.region}/s3/aws4_request';
    final stringToSign =
        'AWS4-HMAC-SHA256\n'
        '$amzDate\n'
        '$credentialScope\n'
        '${sha256.convert(utf8.encode(canonicalRequest)).toString()}';
    final signingKey = _deriveSigningKey(
      secretAccessKey: config.secretAccessKey,
      dateStamp: dateStamp,
      region: config.region,
      service: 's3',
    );
    final signature = Hmac(
      sha256,
      signingKey,
    ).convert(utf8.encode(stringToSign)).toString();
    final authorization =
        'AWS4-HMAC-SHA256 '
        'Credential=${config.accessKeyId}/$credentialScope, '
        'SignedHeaders=$signedHeaders, '
        'Signature=$signature';

    return SignedS3Request(
      headers: <String, String>{
        'authorization': authorization,
        'x-amz-content-sha256': payloadHash,
        'x-amz-date': amzDate,
        if ((config.userAgent ?? '').trim().isNotEmpty)
          HttpHeaders.userAgentHeader: config.userAgent!.trim(),
      },
    );
  }

  static List<int> _deriveSigningKey({
    required String secretAccessKey,
    required String dateStamp,
    required String region,
    required String service,
  }) {
    final kDate = Hmac(
      sha256,
      utf8.encode('AWS4$secretAccessKey'),
    ).convert(utf8.encode(dateStamp)).bytes;
    final kRegion = Hmac(sha256, kDate).convert(utf8.encode(region)).bytes;
    final kService = Hmac(sha256, kRegion).convert(utf8.encode(service)).bytes;
    return Hmac(sha256, kService).convert(utf8.encode('aws4_request')).bytes;
  }

  static String _formatAmzDate(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    final s = value.second.toString().padLeft(2, '0');
    return '$y$m${d}T$h$min${s}Z';
  }

  static String _formatDateStamp(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  static S3ListBucketResult parseListBucketXml(String xml) {
    String readSingle(String tag, {String fallback = ''}) {
      final match = RegExp('<$tag>([\\s\\S]*?)</$tag>').firstMatch(xml);
      if (match == null) return fallback;
      return _decodeXml(match.group(1) ?? fallback);
    }

    final objectMatches = RegExp(
      '<Contents>([\\s\\S]*?)</Contents>',
    ).allMatches(xml);
    final objects = objectMatches
        .map((match) {
          final block = match.group(1) ?? '';
          final key = _decodeXml(
            RegExp('<Key>([\\s\\S]*?)</Key>').firstMatch(block)?.group(1) ?? '',
          );
          final size =
              int.tryParse(
                RegExp(
                      '<Size>([\\s\\S]*?)</Size>',
                    ).firstMatch(block)?.group(1) ??
                    '',
              ) ??
              0;
          final eTag = RegExp(
            '<ETag>([\\s\\S]*?)</ETag>',
          ).firstMatch(block)?.group(1)?.replaceAll('"', '');
          final lastModifiedRaw = RegExp(
            '<LastModified>([\\s\\S]*?)</LastModified>',
          ).firstMatch(block)?.group(1);
          return S3ObjectSummary(
            key: key,
            size: size,
            eTag: eTag,
            lastModified: lastModifiedRaw == null
                ? null
                : DateTime.tryParse(lastModifiedRaw),
          );
        })
        .toList(growable: false);

    return S3ListBucketResult(
      name: readSingle('Name'),
      prefix: readSingle('Prefix'),
      maxKeys: int.tryParse(readSingle('MaxKeys', fallback: '0')) ?? 0,
      isTruncated: readSingle('IsTruncated').toLowerCase() == 'true',
      objects: objects,
    );
  }

  static String _decodeXml(String raw) {
    return raw
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }

  static DateTime? _tryParseHttpDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return HttpDate.parse(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<List<int>> _readAllBytes(
    HttpClientResponse response, {
    void Function(int receivedBytes, int totalBytes)? onProgress,
    int totalBytes = 0,
  }) async {
    final chunks = BytesBuilder(copy: false);
    var receivedBytes = 0;
    var lastReportedBytes = 0;
    const reportInterval = 64 * 1024; // Report every 64KB
    void report({bool force = false}) {
      if (onProgress == null) return;
      if (!force && totalBytes > 0) {
        // Report either every 64KB or every 5% progress
        final percentProgress = receivedBytes * 100 ~/ totalBytes;
        final lastPercentProgress = lastReportedBytes * 100 ~/ totalBytes;
        final bytesProgress = receivedBytes - lastReportedBytes;
        if (receivedBytes < totalBytes &&
            bytesProgress < reportInterval &&
            percentProgress == lastPercentProgress) {
          return;
        }
      }
      lastReportedBytes = receivedBytes;
      onProgress(receivedBytes, totalBytes);
    }

    report(force: true);
    await for (final chunk in response) {
      chunks.add(chunk);
      receivedBytes += chunk.length;
      report();
    }
    report(force: true);
    return chunks.takeBytes();
  }
}

class SignedS3Request {
  const SignedS3Request({required this.headers});

  final Map<String, String> headers;
}

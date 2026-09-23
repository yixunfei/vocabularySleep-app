import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/s3_bucket_probe.dart';

void main() {
  test(
    'object signature encodes reserved bytes and includes endpoint port',
    () async {
      await _verifyRequest(
        (client) => client.headObject("music/中 a!+'()%2F.mp3"),
        method: 'HEAD',
        canonicalPath: '/test/music/%E4%B8%AD%20a%21%2B%27%28%29%252F.mp3',
      );
    },
  );

  test(
    'list signature uses RFC3986 spaces and reserved query characters',
    () async {
      await _verifyRequest(
        (client) => client.listObjects(prefix: "music/中 a!+'()/", maxKeys: 2),
        method: 'GET',
        canonicalPath: '/test',
        canonicalQuery:
            'list-type=2&max-keys=2&prefix=music%2F%E4%B8%AD%20a%21%2B%27%28%29%2F',
      );
    },
  );
}

Future<void> _verifyRequest(
  Future<Object> Function(S3BucketProbeClient) operation, {
  required String method,
  required String canonicalPath,
  String canonicalQuery = '',
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final transport = _RealHttpOverrides().createHttpClient(null);
  final client = S3BucketProbeClient(
    config: S3BucketProbeConfig(
      endpoint: '127.0.0.1:${server.port}',
      bucket: 'test',
      accessKeyId: 'test-key',
      secretAccessKey: 'test-secret',
      useHttps: false,
    ),
    httpClient: transport,
  );
  late HttpRequest captured;
  final subscription = server.listen((request) async {
    captured = request;
    if (request.method != 'HEAD') {
      request.response.write('<ListBucketResult></ListBucketResult>');
    }
    await request.response.close();
  });
  try {
    await operation(client);
    final date = captured.headers.value('x-amz-date')!;
    final hash = sha256.convert([]).toString();
    final host = captured.headers.value('host');
    expect(host, '127.0.0.1:${server.port}');
    const signedHeaders = 'host;x-amz-content-sha256;x-amz-date';
    final canonical =
        '$method\n$canonicalPath\n$canonicalQuery\n'
        'host:$host\nx-amz-content-sha256:$hash\nx-amz-date:$date\n\n'
        '$signedHeaders\n$hash';
    final scope = '${date.substring(0, 8)}/us-east-1/s3/aws4_request';
    List<int> signingKey = utf8.encode('AWS4test-secret');
    for (final part in [
      date.substring(0, 8),
      'us-east-1',
      's3',
      'aws4_request',
    ]) {
      signingKey = Hmac(sha256, signingKey).convert(utf8.encode(part)).bytes;
    }
    final signature = Hmac(sha256, signingKey).convert(
      utf8.encode(
        'AWS4-HMAC-SHA256\n$date\n$scope\n${sha256.convert(utf8.encode(canonical))}',
      ),
    );
    expect(
      captured.headers.value('authorization'),
      'AWS4-HMAC-SHA256 Credential=test-key/$scope, '
      'SignedHeaders=$signedHeaders, Signature=$signature',
    );
  } finally {
    await client.close();
    await server.close(force: true);
    await subscription.cancel();
  }
}

class _RealHttpOverrides extends HttpOverrides {}

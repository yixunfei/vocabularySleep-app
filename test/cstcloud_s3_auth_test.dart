import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/cstcloud_s3_compat_client.dart';
import 'package:vocabulary_sleep_app/src/services/s3_bucket_probe.dart';

void main() {
  _registerReadTests();
  _registerConfigurationTests();
}

void _registerReadTests() {
  for (final operation in ['list', 'head', 'get', 'range', 'download']) {
    test('$operation uses signed default access without dotenv', () async {
      dotenv.clean();
      await _withServer((client, capture, directory) async {
        switch (operation) {
          case 'list':
            expect(await client.listPrefix('music/', maxKeys: 2), isEmpty);
          case 'head':
            expect(
              (await client.headObject('music/test.wav')).contentLength,
              4,
            );
          case 'get':
            expect(await client.getObjectBytes('music/test.wav'), [1, 2, 3, 4]);
          case 'range':
            expect(
              await client.getObjectRange('music/test.wav', start: 0, end: 3),
              [1, 2, 3, 4],
            );
          case 'download':
            final file = await client.downloadObjectToFile(
              'music/test.wav',
              File('${directory.path}/test.wav'),
            );
            expect(await file.readAsBytes(), [1, 2, 3, 4]);
        }
        final request = capture.requests.single;
        expect(request.headers.value('user-agent'), 'S3 browser 13.1.1');
        expect(request.headers.value('x-amz-date'), matches(r'^\d{8}T\d{6}Z$'));
        expect(
          request.headers.value('x-amz-content-sha256'),
          sha256.convert([]).toString(),
        );
        expect(
          request.headers.value('authorization'),
          matches(
            r'^AWS4-HMAC-SHA256 Credential=\S+/\d{8}/us-east-1/s3/'
            r'aws4_request, SignedHeaders=host;x-amz-content-sha256;'
            r'x-amz-date, Signature=[a-f0-9]{64}$',
          ),
        );
        expect(request.method, operation == 'head' ? 'HEAD' : 'GET');
        if (operation == 'range') {
          expect(request.headers.value('range'), 'bytes=0-3');
        }
      });
    });
  }
}

void _registerConfigurationTests() {
  test(
    'dotenv credentials sign requests and explicit credentials override them',
    () async {
      dotenv.testLoad(
        fileInput:
            'S3_ACCESS_KEY_ID=env-key\n'
            'S3_SECRET_ACCESS_KEY=env-secret\n',
      );
      addTearDown(dotenv.clean);
      await _withServer((client, capture, directory) async {
        await client.headObject('music/test.wav');
        _expectSignature(capture, 'env-key', 'env-secret');
      });
      await _withServer(
        (client, capture, directory) async {
          await client.headObject('music/test.wav');
          _expectSignature(capture, 'explicit-key', 'explicit-secret');
        },
        accessKeyId: 'explicit-key',
        secretAccessKey: 'explicit-secret',
      );
    },
  );

  for (final credentials in [('', 'secret'), ('key', ''), (' ', 'secret')]) {
    test(
      'empty credentials are rejected before network access $credentials',
      () async {
        final client = S3BucketProbeClient(
          config: S3BucketProbeConfig(
            endpoint: 'invalid.invalid',
            bucket: 'test',
            accessKeyId: credentials.$1,
            secretAccessKey: credentials.$2,
          ),
        );
        addTearDown(client.close);
        await expectLater(client.headObject('test'), throwsStateError);
        await expectLater(client.listObjects(), throwsStateError);
        await expectLater(client.getObject('test'), throwsStateError);
        await expectLater(
          client.getObjectRange('test', start: 0, end: 1),
          throwsStateError,
        );
        await expectLater(
          client.downloadObjectToFile('test', File('unused-download-target')),
          throwsStateError,
        );
      },
    );
  }
}

// Verify the wire signature with test-only credentials and the captured date.
void _expectSignature(_Capture capture, String key, String secret) {
  final request = capture.requests.single;
  final uri = capture.uris.single;
  final date = request.headers.value('x-amz-date')!;
  final hash = sha256.convert([]).toString();
  final scope = '${date.substring(0, 8)}/us-east-1/s3/aws4_request';
  const signedHeaders = 'host;x-amz-content-sha256;x-amz-date';
  final canonical =
      'HEAD\n${uri.path}\n\n'
      'host:${uri.host}\nx-amz-content-sha256:$hash\nx-amz-date:$date\n\n'
      '$signedHeaders\n$hash';
  List<int> signingKey = utf8.encode('AWS4$secret');
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
    request.headers.value('authorization'),
    'AWS4-HMAC-SHA256 Credential=$key/$scope, '
    'SignedHeaders=$signedHeaders, Signature=$signature',
  );
}

Future<void> _withServer(
  Future<void> Function(CstCloudS3CompatClient, _Capture, Directory) run, {
  String? accessKeyId,
  String? secretAccessKey,
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final transport = _RealHttpOverrides().createHttpClient(null);
  final directory = await Directory.systemTemp.createTemp('s3-auth-test-');
  final capture = _Capture();
  final subscription = server.listen((request) async {
    capture.requests.add(request);
    if (request.uri.queryParameters.containsKey('list-type')) {
      request.response.write(
        '<ListBucketResult><Name>test</Name>'
        '<MaxKeys>2</MaxKeys><IsTruncated>false</IsTruncated>'
        '</ListBucketResult>',
      );
    } else {
      request.response.contentLength = 4;
      if (request.method != 'HEAD') request.response.add([1, 2, 3, 4]);
    }
    await request.response.close();
  });
  try {
    await HttpOverrides.runZoned(
      () async {
        final client = CstCloudS3CompatClient(
          accessKeyId: accessKeyId,
          secretAccessKey: secretAccessKey,
        );
        try {
          await run(client, capture, directory);
        } finally {
          await client.close();
        }
      },
      createHttpClient: (_) => _RedirectClient(transport, server.port, capture),
    );
  } finally {
    transport.close(force: true);
    await server.close(force: true);
    await subscription.cancel();
    await directory.delete(recursive: true);
  }
}

class _Capture {
  final requests = <HttpRequest>[];
  final uris = <Uri>[];
}

class _RealHttpOverrides extends HttpOverrides {}

// Redirect the real default endpoint locally without changing the signed URI.
class _RedirectClient implements HttpClient {
  _RedirectClient(this.transport, this.port, this.capture);

  final HttpClient transport;
  final int port;
  final _Capture capture;

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    capture.uris.add(url);
    return transport.openUrl(
      method,
      url.replace(scheme: 'http', host: '127.0.0.1', port: port),
    );
  }

  @override
  void close({bool force = false}) => transport.close(force: force);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

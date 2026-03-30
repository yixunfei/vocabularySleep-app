import 'dart:io';

import 'package:vocabulary_sleep_app/src/services/s3_bucket_probe.dart';

Future<void> main(List<String> args) async {
  final endpoint = _envOrArg('S3_ENDPOINT', args, '--endpoint');
  final bucket = _envOrArg('S3_BUCKET', args, '--bucket');
  final accessKeyId = _envOrArg('S3_ACCESS_KEY_ID', args, '--access-key-id');
  final secretAccessKey = _envOrArg(
    'S3_SECRET_ACCESS_KEY',
    args,
    '--secret-access-key',
  );
  final region = _envOrArg(
    'S3_REGION',
    args,
    '--region',
    fallback: 'us-east-1',
  );
  final prefix = _envOrArg('S3_PREFIX', args, '--prefix', fallback: '');
  final maxKeysRaw = _envOrArg(
    'S3_MAX_KEYS',
    args,
    '--max-keys',
    fallback: '10',
  );
  final maxKeys = int.tryParse(maxKeysRaw) ?? 10;
  final userAgent = _envOrArg('S3_USER_AGENT', args, '--user-agent');
  final operation = _envOrArg('S3_OP', args, '--op', fallback: 'list');
  final objectKey = _envOrArg('S3_OBJECT_KEY', args, '--key', fallback: '');

  if (endpoint.isEmpty ||
      bucket.isEmpty ||
      accessKeyId.isEmpty ||
      secretAccessKey.isEmpty) {
    stderr.writeln(
      'Missing S3 probe configuration. '
      'Provide env vars or args for endpoint, bucket, access key, and secret.',
    );
    exitCode = 64;
    return;
  }

  final client = S3BucketProbeClient(
    config: S3BucketProbeConfig(
      endpoint: endpoint,
      bucket: bucket,
      accessKeyId: accessKeyId,
      secretAccessKey: secretAccessKey,
      region: region,
      userAgent: userAgent.isEmpty ? null : userAgent,
    ),
  );

  try {
    switch (operation) {
      case 'head':
        if (objectKey.isEmpty) {
          stderr.writeln('Missing object key for head operation.');
          exitCode = 64;
          return;
        }
        final result = await client.headObject(objectKey);
        stdout.writeln('Content-Length: ${result.contentLength}');
        stdout.writeln('Content-Type: ${result.contentType}');
        stdout.writeln('Last-Modified: ${result.lastModified}');
        stdout.writeln('Content-Disposition: ${result.contentDisposition}');
        stdout.writeln('ETag: ${result.eTag}');
        break;
      case 'get-range':
        if (objectKey.isEmpty) {
          stderr.writeln('Missing object key for get-range operation.');
          exitCode = 64;
          return;
        }
        final result = await client.getObjectRange(
          objectKey,
          start: 0,
          end: 31,
        );
        stdout.writeln('Content-Type: ${result.contentType}');
        stdout.writeln('Content-Range: ${result.contentRange}');
        stdout.writeln('Bytes: ${result.bytes.length}');
        stdout.writeln(result.bytes);
        break;
      default:
        final result = await client.listObjects(
          prefix: prefix,
          maxKeys: maxKeys,
        );
        stdout.writeln('Bucket: ${result.name}');
        stdout.writeln('Prefix: ${result.prefix}');
        stdout.writeln('Objects: ${result.objects.length}');
        for (final object in result.objects) {
          stdout.writeln('${object.key} | ${object.size} bytes');
        }
        break;
    }
  } finally {
    await client.close();
  }
}

String _envOrArg(
  String envKey,
  List<String> args,
  String argKey, {
  String fallback = '',
}) {
  final env = Platform.environment[envKey];
  if (env != null && env.trim().isNotEmpty) {
    return env.trim();
  }
  final index = args.indexOf(argKey);
  if (index >= 0 && index < args.length - 1) {
    return args[index + 1].trim();
  }
  return fallback;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/cstcloud_s3_compat_client.dart';
import 'package:vocabulary_sleep_app/src/services/s3_bucket_probe.dart';

void main() {
  test('resource listing continues through all S3 pages', () async {
    final probe = _PagedProbe();
    final client = CstCloudS3CompatClient(probeClient: probe);
    addTearDown(client.close);
    final objects = await client.listPrefix('music/', maxKeys: 1);
    expect(objects.map((item) => item.key), ['music/a', 'music/b']);
    expect(probe.tokens, [null, 'page+2/=']);
  });

  test(
    'repeated continuation tokens fail instead of looping forever',
    () async {
      final probe = _PagedProbe(repeatToken: true);
      final client = CstCloudS3CompatClient(probeClient: probe);
      addTearDown(client.close);
      await expectLater(client.listPrefix('music/'), throwsStateError);
      expect(probe.tokens.length, 2);
    },
  );

  test('list XML exposes the decoded continuation token', () {
    final page = S3BucketProbeClient.parseListBucketXml('''
<ListBucketResult><IsTruncated>true</IsTruncated>
<NextContinuationToken>a&amp;b+2/=</NextContinuationToken></ListBucketResult>
''');
    expect(page.nextContinuationToken, 'a&b+2/=');
  });
}

class _PagedProbe extends S3BucketProbeClient {
  _PagedProbe({this.repeatToken = false})
    : super(
        config: const S3BucketProbeConfig(
          endpoint: 'unused.invalid',
          bucket: 'test',
          accessKeyId: 'test-key',
          secretAccessKey: 'test-secret',
        ),
      );

  final bool repeatToken;
  final List<String?> tokens = [];

  @override
  Future<S3ListBucketResult> listObjects({
    String prefix = '',
    int maxKeys = 20,
    String? continuationToken,
  }) async {
    tokens.add(continuationToken);
    final truncated = continuationToken == null || repeatToken;
    return S3ListBucketResult(
      name: 'test',
      prefix: prefix,
      maxKeys: maxKeys,
      isTruncated: truncated,
      objects: [
        S3ObjectSummary(
          key: continuationToken == null ? 'music/a' : 'music/b',
          size: 1,
        ),
      ],
      nextContinuationToken: truncated ? 'page+2/=' : null,
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/s3_bucket_probe.dart';

void main() {
  test('S3BucketProbeClient parses list bucket xml payload', () {
    const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult>
  <Name>demo-bucket</Name>
  <Prefix>music/</Prefix>
  <MaxKeys>2</MaxKeys>
  <IsTruncated>false</IsTruncated>
  <Contents>
    <Key>music/chill.m4a</Key>
    <LastModified>2026-03-27T08:12:00.000Z</LastModified>
    <ETag>"abc123"</ETag>
    <Size>12345</Size>
  </Contents>
  <Contents>
    <Key>wordbooks/basic.csv</Key>
    <LastModified>2026-03-26T08:12:00.000Z</LastModified>
    <ETag>"def456"</ETag>
    <Size>23456</Size>
  </Contents>
</ListBucketResult>
''';

    final result = S3BucketProbeClient.parseListBucketXml(xml);

    expect(result.name, 'demo-bucket');
    expect(result.prefix, 'music/');
    expect(result.maxKeys, 2);
    expect(result.isTruncated, isFalse);
    expect(result.objects, hasLength(2));
    expect(result.objects.first.key, 'music/chill.m4a');
    expect(result.objects.first.size, 12345);
    expect(result.objects.first.eTag, 'abc123');
    expect(result.objects.last.key, 'wordbooks/basic.csv');
  });
}

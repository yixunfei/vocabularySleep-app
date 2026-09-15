import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/resource_store.dart';
import 'package:vocabulary_sleep_app/src/services/web_audio_source_policy.dart';

void main() {
  test('web resource store caches bytes without native paths', () async {
    var fetches = 0;
    final store = WebResourceStore(
      fetch: (key) async {
        fetches++;
        return Uint8List.fromList(key.codeUnits);
      },
    );
    final first = await store.readBytes('ambient/rain.mp3');
    final second = await store.readBytes('ambient/rain.mp3');
    expect(first, second);
    expect(fetches, 1);
    expect(await store.contains('ambient/rain.mp3'), isTrue);
    expect(await store.listKeys('ambient/'), <String>['ambient/rain.mp3']);
    await store.close();
    expect(await store.contains('ambient/rain.mp3'), isFalse);
  });

  test('web audio policy only accepts browser-safe sources', () {
    const policy = WebAudioSourcePolicy();
    expect(policy.acceptsAsset('sounds/rain.mp3'), isTrue);
    expect(policy.acceptsUrl('https://example.com/rain.mp3'), isTrue);
    expect(policy.acceptsUrl('C:\\rain.mp3'), isFalse);
    expect(policy.acceptsBytes(Uint8List.fromList(<int>[1])), isTrue);
    expect(policy.acceptsBytes(Uint8List(0)), isFalse);
  });
}

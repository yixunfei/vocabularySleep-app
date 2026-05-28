import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_life_tools.dart';

void main() {
  group('life text split and count', () {
    test('splits by no-symbol metric while preserving punctuation in output', () {
      final chunks = buildLifeTextCounterTestChunks(
        text: '甲乙，丙丁。戊己；庚辛。',
        chunkLimit: 4,
        metric: 'no_symbols',
        splitMode: 'fixed',
      );

      expect(chunks, hasLength(2));
      expect(chunks[0]['content'], '甲乙，丙丁。');
      expect(chunks[0]['effectiveLength'], 4);
      expect(chunks[1]['content'], '戊己；庚辛。');
      expect(chunks[1]['effectiveLength'], 4);
    });

    test('prefers sentence ending within range before hard split', () {
      final chunks = buildLifeTextCounterTestChunks(
        text: '第一句。第二句更长一些。第三句。',
        chunkLimit: 8,
        metric: 'content_only',
        splitMode: 'sentence',
      );

      expect(chunks, hasLength(3));
      expect(chunks[0]['content'], '第一句。');
      expect(chunks[1]['content'], '第二句更长一些。');
      expect(chunks[2]['content'], '第三句。');
    });

    test('falls back to hard split when no sentence ending exists', () {
      final chunks = buildLifeTextCounterTestChunks(
        text: 'abcdefghij',
        chunkLimit: 3,
        metric: 'total',
        splitMode: 'sentence',
      );

      expect(chunks, hasLength(4));
      expect(
        chunks.map((chunk) => chunk['content']).toList(),
        <Object?>['abc', 'def', 'ghi', 'j'],
      );
    });
  });
}

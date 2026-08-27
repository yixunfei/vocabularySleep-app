import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/models/word_entry.dart';
import 'package:vocabulary_sleep_app/src/models/word_field.dart';

void main() {
  group('WordEntry summary fields', () {
    test('lite entries preserve legacy meaning precedence', () {
      const entry = WordEntry(
        wordbookId: 1,
        word: 'alpha',
        meaning: ' Legacy meaning ',
        primaryGloss: 'Primary gloss',
      );

      expect(entry.displayMeaning, 'Legacy meaning');
      expect(entry.summaryMeaningText, 'Legacy meaning');
      expect(entry.listSubtitleText, 'Legacy meaning');
      expect(entry.primaryMeaningField?.asText(), 'Legacy meaning');
    });

    test('lite entries fall back to primary gloss', () {
      const entry = WordEntry(
        wordbookId: 1,
        word: 'alpha',
        primaryGloss: 'Primary gloss',
      );

      expect(entry.displayMeaning, 'Primary gloss');
      expect(entry.summaryMeaningText, 'Primary gloss');
    });

    test('structured meaning fields keep their priority', () {
      const entry = WordEntry(
        wordbookId: 1,
        word: 'alpha',
        primaryGloss: 'Primary gloss',
        fields: <WordFieldItem>[
          WordFieldItem(
            key: 'meaning',
            label: 'Meaning',
            value: 'Structured meaning',
          ),
        ],
      );

      expect(entry.displayMeaning, 'Structured meaning');
      expect(entry.summaryMeaningText, 'Structured meaning');
    });
  });
}

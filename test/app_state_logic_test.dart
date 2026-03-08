import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/word_entry.dart';
import 'package:vocabulary_sleep_app/src/models/word_field.dart';
import 'package:vocabulary_sleep_app/src/state/app_state.dart';

WordEntry _word(
  String word, {
  String? meaning,
  List<WordFieldItem> fields = const <WordFieldItem>[],
}) {
  return WordEntry(wordbookId: 1, word: word, meaning: meaning, fields: fields);
}

void main() {
  group('P1-3 search and jump scope', () {
    test('jump helpers operate on visible words only', () {
      final words = <WordEntry>[
        _word('Alpha', meaning: 'first'),
        _word('Beta', meaning: 'target term'),
        _word('Zeta', meaning: 'target concept'),
      ];
      final visible = AppState.filterWords(
        words: words,
        query: 'target',
        mode: SearchMode.meaning,
      );

      expect(visible.map((w) => w.word), <String>['Beta', 'Zeta']);
      expect(AppState.findJumpIndexByPrefix(visible, 'al'), -1);
      expect(AppState.findJumpIndexByPrefix(visible, 'ze'), 1);
      expect(AppState.findJumpIndexByInitial(visible, 'Z'), 1);
    });

    test('search and jump normalize diacritics consistently', () {
      final words = <WordEntry>[
        _word('脡clair', meaning: 'dessert'),
        _word('Banana', meaning: 'fruit'),
      ];
      final visible = AppState.filterWords(
        words: words,
        query: 'ecl',
        mode: SearchMode.word,
      );

      expect(visible.length, 1);
      expect(visible.first.word, '脡clair');
      expect(AppState.findJumpIndexByPrefix(visible, 'ec'), 0);
      expect(AppState.findJumpIndexByInitial(visible, 'E'), 0);
    });
  });

  group('P1-4 pronunciation scoring', () {
    test('light inflection differences remain high similarity', () {
      final result = AppState.comparePronunciationTexts(
        expected: 'running tests',
        recognized: 'run test',
      );
      expect(result.similarity, greaterThan(0.8));
    });

    test('filler tokens are ignored for follow-along scoring', () {
      final result = AppState.comparePronunciationTexts(
        expected: 'hello world',
        recognized: 'um hello uh world',
      );
      expect(result.similarity, greaterThan(0.95));
      expect(result.isCorrect, true);
    });

    test('casual contractions are normalized for scoring', () {
      final result = AppState.comparePronunciationTexts(
        expected: 'i am going to study',
        recognized: "i'm gonna study",
      );
      expect(result.similarity, greaterThan(0.9));
      expect(result.isCorrect, true);
    });

    test('cjk filler tokens are ignored for scoring', () {
      final result = AppState.comparePronunciationTexts(
        expected: '\u4f60\u597d\u4e16\u754c',
        recognized: '\u55ef \u4f60\u597d \u554a \u4e16\u754c',
      );
      expect(result.similarity, greaterThan(0.9));
      expect(result.isCorrect, true);
    });

    test('cjk text compares by characters instead of full sentence token', () {
      final result = AppState.comparePronunciationTexts(
        expected: '\u4f60\u597d\u4e16\u754c',
        recognized: '\u4f60\u597d\u4e16\u95f4',
      );
      expect(result.similarity, greaterThan(0.7));
      expect(result.differences.isNotEmpty, true);
    });

    test('differences use structured keys for i18n rendering', () {
      final result = AppState.comparePronunciationTexts(
        expected: 'apple',
        recognized: 'apricot',
      );
      expect(result.differences.isNotEmpty, true);
      expect(
        result.differences.first.startsWith('replace::') ||
            result.differences.first.startsWith('missing::') ||
            result.differences.first.startsWith('extra::'),
        true,
      );
    });
  });
}

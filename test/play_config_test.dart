import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/models/word_entry.dart';
import 'package:vocabulary_sleep_app/src/models/word_field.dart';

void main() {
  group('play config spelling', () {
    test('defaults ASR language to auto for system-aware speech input', () {
      expect(PlayConfig.defaults.asr.language, 'auto');

      final restored = PlayConfig.fromJson(<String, Object?>{});

      expect(restored.asr.language, 'auto');
    });

    test('spellWord can group by letter pairs', () {
      expect(spellWord('word', mode: SpellingPlaybackMode.pairs), 'wo - rd');
    });

    test('buildPlayQueue inserts spelling before meaning', () {
      final word = WordEntry(
        wordbookId: 1,
        word: 'word',
        fields: const <WordFieldItem>[
          WordFieldItem(key: 'meaning', label: 'Meaning', value: '词义'),
          WordFieldItem(
            key: 'examples',
            label: 'Examples',
            value: 'A sample sentence.',
          ),
        ],
      );
      final config = PlayConfig.defaults.copyWith(
        repeats: <String, int>{
          ...PlayConfig.defaults.repeats,
          'word': 1,
          'spelling': 1,
          'meaning': 1,
          'example': 0,
        },
        spellingPlaybackMode: SpellingPlaybackMode.letters,
      );

      final queue = buildPlayQueue(word, config);

      expect(queue.map((item) => item.type).toList(growable: false), <String>[
        'word',
        'spelling',
        'meaning',
      ]);
      expect(queue[1].text, 'w - o - r - d');
    });

    test('json round-trip preserves spelling and transition settings', () {
      final config = PlayConfig.defaults.copyWith(
        spellingPlaybackMode: SpellingPlaybackMode.pairs,
        wordPageTransitionStyle: WordPageTransitionStyle.pageFlip,
        appearance: PlayConfig.defaults.appearance.copyWith(
          ambientLauncherX: 0.18,
          ambientLauncherY: 0.67,
        ),
      );

      final restored = PlayConfig.fromJson(config.toJson());

      expect(restored.spellingPlaybackMode, SpellingPlaybackMode.pairs);
      expect(
        restored.wordPageTransitionStyle,
        WordPageTransitionStyle.pageFlip,
      );
      expect(
        restored.appearance.normalizedAmbientLauncherX,
        closeTo(0.18, 0.001),
      );
      expect(
        restored.appearance.normalizedAmbientLauncherY,
        closeTo(0.67, 0.001),
      );
    });
  });
}

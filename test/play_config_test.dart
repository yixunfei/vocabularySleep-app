import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/models/word_entry.dart';
import 'package:vocabulary_sleep_app/src/models/word_field.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('play config spelling', () {
    test('defaults ASR language to auto for system-aware speech input', () {
      expect(PlayConfig.defaults.asr.language, 'auto');
      expect(
        PlayConfig.defaults.voiceInput.provider,
        VoiceInputProviderType.system,
      );
      expect(PlayConfig.defaults.voiceInput.language, 'auto');
      expect(PlayConfig.defaults.appearance.timerStyle, 'countdown');

      final restored = PlayConfig.fromJson(<String, Object?>{});

      expect(restored.asr.language, 'auto');
      expect(restored.voiceInput.provider, VoiceInputProviderType.system);
      expect(restored.voiceInput.language, 'auto');
      expect(restored.appearance.timerStyle, 'countdown');
    });

    test('legacy config migrates voice input fields from ASR config', () {
      final restored = PlayConfig.fromJson(<String, Object?>{
        'asr': <String, Object?>{
          'enabled': true,
          'provider': 'api',
          'engineOrder': <String>['api'],
          'scoringMethods': <String>['sslEmbedding'],
          'apiKey': 'legacy-key',
          'model': 'legacy-model',
          'language': 'ja-JP',
        },
      });

      expect(restored.voiceInput.provider, VoiceInputProviderType.system);
      expect(restored.voiceInput.language, 'ja-JP');
      expect(restored.voiceInput.model, 'legacy-model');
      expect(restored.voiceInput.apiKey, 'legacy-key');
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

    test(
      'repeat count keeps meaning playable despite legacy disabled toggle',
      () {
        final word = WordEntry(
          wordbookId: 1,
          word: 'abandon',
          fields: const <WordFieldItem>[
            WordFieldItem(
              key: 'meaning',
              label: 'Meaning',
              value: 'to leave behind',
            ),
          ],
        );
        final config = PlayConfig.defaults.copyWith(
          fieldSettings: const <String, FieldPlaybackSetting>{
            'meaning': FieldPlaybackSetting(enabled: false),
          },
          repeats: <String, int>{
            ...PlayConfig.defaults.repeats,
            'word': 1,
            'meaning': 1,
          },
        );

        final queue = buildPlayQueue(word, config);

        expect(queue.map((item) => item.type).toList(growable: false), <String>[
          'word',
          'meaning',
        ]);
        expect(queue.last.text, 'to leave behind');
      },
    );

    test('json round-trip preserves spelling and transition settings', () {
      final config = PlayConfig.defaults.copyWith(
        voiceInput: PlayConfig.defaults.voiceInput.copyWith(
          provider: VoiceInputProviderType.api,
          language: 'en-US',
          model: 'test-model',
          apiKey: 'secret',
        ),
        spellingPlaybackMode: SpellingPlaybackMode.pairs,
        wordPageTransitionStyle: WordPageTransitionStyle.pageFlip,
        appearance: PlayConfig.defaults.appearance.copyWith(
          ambientLauncherX: 0.18,
          ambientLauncherY: 0.67,
        ),
      );

      final restored = PlayConfig.fromJson(config.toJson());

      expect(restored.spellingPlaybackMode, SpellingPlaybackMode.pairs);
      expect(restored.voiceInput.provider, VoiceInputProviderType.api);
      expect(restored.voiceInput.language, 'en-US');
      expect(restored.voiceInput.model, 'test-model');
      expect(restored.voiceInput.apiKey, 'secret');
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

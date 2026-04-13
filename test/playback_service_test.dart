import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/models/word_entry.dart';
import 'package:vocabulary_sleep_app/src/models/word_field.dart';
import 'package:vocabulary_sleep_app/src/services/playback_service.dart';
import 'package:vocabulary_sleep_app/src/services/tts_service.dart';

class _FakeTtsService extends TtsService {
  final List<String> spoken = <String>[];

  @override
  Future<void> speak(
    String text,
    TtsConfig config, {
    bool preCacheOnly = false,
  }) async {
    if (preCacheOnly) {
      return;
    }
    spoken.add(text);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> pause(TtsProviderType provider) async {}

  @override
  Future<void> resume(TtsProviderType provider) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const audioChannel = MethodChannel('xyz.luan/audioplayers');
  const audioGlobalChannel = MethodChannel('xyz.luan/audioplayers.global');
  const audioGlobalEventsChannel = MethodChannel(
    'xyz.luan/audioplayers.global/events',
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, (call) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, (call) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('xyz.luan/audioplayers/events'),
          (call) async => null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          audioGlobalEventsChannel,
          (call) async => null,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('xyz.luan/audioplayers/events'),
          null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalEventsChannel, null);
  });

  test('random playback keeps the active word as the first item', () async {
    final tts = _FakeTtsService();
    final service = PlaybackService(tts);
    addTearDown(service.stop);
    final words = List<WordEntry>.generate(
      10,
      (index) => WordEntry(
        wordbookId: 1,
        word: 'Word $index',
        fields: const <WordFieldItem>[],
      ),
    );
    final config = PlayConfig.defaults.copyWith(
      order: PlayOrder.random,
      delayBetweenUnitsMs: 0,
    );

    for (var attempt = 0; attempt < 10; attempt++) {
      final seenIndices = <int>[];
      await service.playWords(
        words: words,
        startIndex: 4,
        config: config,
        onWordChanged: (index, _) => seenIndices.add(index),
      );

      expect(seenIndices, isNotEmpty);
      expect(seenIndices.first, 4);
      expect(seenIndices.toSet().length, words.length);
    }
  });

  test(
    'playback resolves lite entries before building the play queue',
    () async {
      final tts = _FakeTtsService();
      final service = PlaybackService(tts);
      addTearDown(service.stop);
      const liteEntry = WordEntry(
        wordbookId: 1,
        word: 'abandon',
        fields: <WordFieldItem>[],
      );
      const hydratedEntry = WordEntry(
        wordbookId: 1,
        word: 'abandon',
        meaning: 'to leave behind',
        rawContent: 'to leave behind',
        fields: <WordFieldItem>[
          WordFieldItem(
            key: 'meaning',
            label: 'Meaning',
            value: 'to leave behind',
          ),
        ],
      );
      final config = PlayConfig.defaults.copyWith(delayBetweenUnitsMs: 0);

      await service.playWords(
        words: <WordEntry>[liteEntry],
        startIndex: 0,
        config: config,
        resolveWord: (_, _) => hydratedEntry,
      );

      expect(tts.spoken, <String>['abandon', 'to leave behind']);
    },
  );

  test(
    'repeat-enabled fields still play when legacy field toggle stays disabled',
    () async {
      final tts = _FakeTtsService();
      final service = PlaybackService(tts);
      addTearDown(service.stop);
      const entry = WordEntry(
        wordbookId: 1,
        word: 'abandon',
        meaning: 'to leave behind',
        rawContent: 'to leave behind',
        fields: <WordFieldItem>[
          WordFieldItem(
            key: 'meaning',
            label: 'Meaning',
            value: 'to leave behind',
          ),
        ],
      );
      final config = PlayConfig.defaults.copyWith(
        delayBetweenUnitsMs: 0,
        fieldSettings: const <String, FieldPlaybackSetting>{
          'meaning': FieldPlaybackSetting(enabled: false),
        },
      );

      await service.playWords(
        words: const <WordEntry>[entry],
        startIndex: 0,
        config: config,
      );

      expect(tts.spoken, <String>['abandon', 'to leave behind']);
    },
  );
}

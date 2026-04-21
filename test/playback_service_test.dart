import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/models/word_entry.dart';
import 'package:vocabulary_sleep_app/src/models/word_field.dart';
import 'package:vocabulary_sleep_app/src/services/playback_service.dart';
import 'package:vocabulary_sleep_app/src/services/tts_service.dart';

class _TtsMethodSpy {
  _TtsMethodSpy({required this.emitTtsCallback});

  final Future<void> Function(String method) emitTtsCallback;
  final List<String> spoken = <String>[];

  Future<dynamic> handle(MethodCall call) async {
    switch (call.method) {
      case 'speak':
        final args = call.arguments;
        if (args is Map) {
          spoken.add(args['text']?.toString() ?? '');
        } else {
          spoken.add(args?.toString() ?? '');
        }
        unawaited(emitTtsCallback('speak.onComplete'));
        return 1;
      case 'setVoice':
      case 'setLanguage':
      case 'setSpeechRate':
      case 'setVolume':
      case 'setPitch':
      case 'awaitSpeakCompletion':
      case 'setAudioAttributesForNavigation':
      case 'stop':
        return 1;
      default:
        return 1;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const audioChannel = MethodChannel('xyz.luan/audioplayers');
  const audioGlobalChannel = MethodChannel('xyz.luan/audioplayers.global');
  const audioGlobalEventsChannel = MethodChannel(
    'xyz.luan/audioplayers.global/events',
  );
  const ttsChannel = MethodChannel('flutter_tts');
  const codec = StandardMethodCodec();
  late _TtsMethodSpy ttsSpy;

  Future<void> emitTtsCallback(String method) {
    final completer = Completer<void>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          'flutter_tts',
          codec.encodeMethodCall(MethodCall(method)),
          (_) => completer.complete(),
        );
    return completer.future;
  }

  setUp(() {
    ttsSpy = _TtsMethodSpy(emitTtsCallback: emitTtsCallback);
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, ttsSpy.handle);
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, null);
  });

  test('random playback keeps the active word as the first item', () async {
    final tts = TtsService();
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
      final tts = TtsService();
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

      expect(ttsSpy.spoken, <String>['abandon', 'to leave behind']);
    },
  );

  test(
    'repeat-enabled fields still play when legacy field toggle stays disabled',
    () async {
      final tts = TtsService();
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

      expect(ttsSpy.spoken, <String>['abandon', 'to leave behind']);
    },
  );
}

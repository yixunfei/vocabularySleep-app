import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/services/app_log_service.dart';
import 'package:vocabulary_sleep_app/src/services/tts_service.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProviderPlatform({
    required this.temporaryPath,
    required this.applicationSupportPath,
  });

  final String temporaryPath;
  final String applicationSupportPath;

  @override
  Future<String?> getTemporaryPath() async => temporaryPath;

  @override
  Future<String?> getApplicationSupportPath() async => applicationSupportPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ttsChannel = MethodChannel('flutter_tts');
  const audioChannel = MethodChannel('xyz.luan/audioplayers');
  const audioGlobalChannel = MethodChannel('xyz.luan/audioplayers.global');
  const audioEventsChannel = MethodChannel('xyz.luan/audioplayers/events');
  const audioGlobalEventsChannel = MethodChannel(
    'xyz.luan/audioplayers.global/events',
  );
  const codec = StandardMethodCodec();

  late PathProviderPlatform originalPathProvider;
  late Directory tempDir;
  late Directory supportDir;
  dynamic flutterTtsVoicesPayload;

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

  void mockAudioPlayers() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, (call) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, (call) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioEventsChannel, (call) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          audioGlobalEventsChannel,
          (call) async => null,
        );
  }

  setUp(() async {
    flutterTtsVoicesPayload = const <Object?>[];
    originalPathProvider = PathProviderPlatform.instance;
    tempDir = await Directory.systemTemp.createTemp('tts-service-temp-');
    supportDir = await Directory.systemTemp.createTemp('tts-service-support-');
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      temporaryPath: tempDir.path,
      applicationSupportPath: supportDir.path,
    );
    AppLogService.instance.resetForTest();
    debugDefaultTargetPlatformOverride = null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (call) async {
          switch (call.method) {
            case 'getVoices':
              return flutterTtsVoicesPayload;
            case 'awaitSpeakCompletion':
            case 'setSpeechRate':
            case 'setVolume':
            case 'setPitch':
            case 'setLanguage':
            case 'setVoice':
            case 'stop':
              return 1;
          }
          return null;
        });
    mockAudioPlayers();
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioEventsChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalEventsChannel, null);
    PathProviderPlatform.instance = originalPathProvider;
    await AppLogService.instance.flushForTest();
    AppLogService.instance.resetForTest();
    debugDefaultTargetPlatformOverride = null;
    if (await tempDir.exists()) {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }
    if (await supportDir.exists()) {
      try {
        await supportDir.delete(recursive: true);
      } catch (_) {}
    }
  });

  test('getLocalVoices sorts and de-duplicates mixed voice payloads', () async {
    flutterTtsVoicesPayload = <Object?>[
      <String, Object?>{'name': 'beta'},
      <String, Object?>{'name': 'alpha'},
      'gamma',
      'beta',
      <String, Object?>{'name': ''},
    ];
    final service = TtsService();

    final voices = await service.getLocalVoices();

    expect(voices, <String>['alpha', 'beta', 'gamma']);
  });

  test(
    'getLocalVoices falls back to empty when the plugin payload is invalid',
    () async {
      flutterTtsVoicesPayload = <String, Object?>{'voices': const <String>[]};
      final service = TtsService();

      final voices = await service.getLocalVoices();

      expect(voices, isEmpty);
    },
  );

  test('API cache size and clearApiCache track cached audio files', () async {
    final cacheDir = Directory('${supportDir.path}\\tts_api_cache');
    await cacheDir.create(recursive: true);
    final first = File('${cacheDir.path}\\one.mp3');
    final second = File('${cacheDir.path}\\two.mp3');
    await first.writeAsBytes(List<int>.filled(12, 7), flush: true);
    await second.writeAsBytes(List<int>.filled(20, 5), flush: true);

    final service = TtsService();

    final before = await service.getApiCacheSizeBytes();
    expect(before, 32);

    await service.clearApiCache();

    final after = await service.getApiCacheSizeBytes();
    expect(after, 0);
    expect(await first.exists(), isFalse);
    expect(await second.exists(), isFalse);
  });

  test('cache helpers honor the configured API cache directory', () async {
    final service = TtsService();
    final cacheSize = await service.getApiCacheSizeBytes();

    expect(cacheSize, 0);
    expect(Directory('${supportDir.path}\\tts_api_cache').existsSync(), isTrue);
    expect(
      PlayConfig.defaults.tts.copyWith(enableApiCache: true).enableApiCache,
      isTrue,
    );
  });

  test('api preCacheOnly uses cache without player calls', () async {
    final audioCalls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, (call) async {
          audioCalls.add(call.method);
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, (call) async {
          audioCalls.add('global.${call.method}');
          return null;
        });

    final service = TtsService();
    audioCalls.clear();
    final config = PlayConfig.defaults.tts.copyWith(
      provider: TtsProviderType.customApi,
      apiKey: 'test-key',
      baseUrl: 'https://tts.example.test',
      enableApiCache: true,
      model: 'test-model',
      remoteVoice: 'test-voice',
    );
    final cachePayload = jsonEncode(<String, Object?>{
      'provider': config.provider.name,
      'baseUrl': config.baseUrl?.trim() ?? '',
      'model': 'test-model',
      'voice': 'test-voice',
      'speed': config.speed,
      'text': 'cache me',
    });
    final cacheKey = sha256.convert(utf8.encode(cachePayload)).toString();
    final cacheDir = Directory(path.join(supportDir.path, 'tts_api_cache'));
    await cacheDir.create(recursive: true);
    final cacheFile = File(path.join(cacheDir.path, '$cacheKey.mp3'));
    await cacheFile.writeAsBytes(<int>[1, 2, 3, 4], flush: true);

    await service.speak('cache me', config, preCacheOnly: true);

    expect(
      audioCalls.where(
        (method) => method != 'create' && method != 'global.create',
      ),
      isEmpty,
    );
    expect(await service.getApiCacheSizeBytes(), 4);

    audioCalls.clear();
    await service.speak('cache me', config, preCacheOnly: true);

    expect(
      audioCalls.where(
        (method) => method != 'create' && method != 'global.create',
      ),
      isEmpty,
    );
  });

  test('api preCacheOnly requests can run in parallel', () async {
    final requests = <String>[];
    final service = TtsService(
      apiClientFactory: () => MockClient((request) async {
        final decoded = jsonDecode(request.body) as Map<String, Object?>;
        requests.add(decoded['input']?.toString() ?? '');
        await Future<void>.delayed(const Duration(milliseconds: 40));
        return http.Response.bytes(
          <int>[1, 2, 3, 4, 5],
          200,
          headers: const <String, String>{'content-type': 'audio/mpeg'},
        );
      }),
    );
    final config = PlayConfig.defaults.tts.copyWith(
      provider: TtsProviderType.customApi,
      apiKey: 'test-key',
      baseUrl: 'https://tts.example.test',
      enableApiCache: true,
      model: 'test-model',
      remoteVoice: 'test-voice',
    );

    await Future.wait(<Future<void>>[
      service.speak('first item', config, preCacheOnly: true),
      service.speak('second item', config, preCacheOnly: true),
    ]);

    expect(requests, unorderedEquals(<String>['first item', 'second item']));
    final cacheDir = Directory(path.join(supportDir.path, 'tts_api_cache'));
    final cacheFiles = await cacheDir
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.mp3'))
        .toList();
    expect(cacheFiles, hasLength(2));
  });

  test('api tts validates required remote configuration', () async {
    final service = TtsService();

    await expectLater(
      service.speak(
        'missing key',
        PlayConfig.defaults.tts.copyWith(provider: TtsProviderType.api),
      ),
      throwsA(isA<TtsConfigurationException>()),
    );

    await expectLater(
      service.speak(
        'missing base url',
        PlayConfig.defaults.tts.copyWith(
          provider: TtsProviderType.customApi,
          apiKey: 'test-key',
        ),
      ),
      throwsA(isA<TtsConfigurationException>()),
    );
  });

  test(
    'windows local tts switches voices between English word and Chinese meaning',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final spokenTexts = <String>[];
      final voicePayloads = <Map<String, String>>[];
      var getVoicesCalls = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ttsChannel, (call) async {
            switch (call.method) {
              case 'awaitSpeakCompletion':
              case 'setSpeechRate':
              case 'setVolume':
              case 'setPitch':
              case 'stop':
                return 1;
              case 'getVoices':
                getVoicesCalls += 1;
                return <Map<String, String>>[
                  <String, String>{'name': 'Zira', 'locale': 'en-US'},
                  <String, String>{'name': 'Huihui', 'locale': 'zh-CN'},
                ];
              case 'setVoice':
                voicePayloads.add(
                  Map<String, String>.from(
                    call.arguments as Map<Object?, Object?>,
                  ),
                );
                return 1;
              case 'setLanguage':
                fail(
                  'language fallback should not be used when matching voices exist',
                );
              case 'speak':
                spokenTexts.add(call.arguments as String);
                scheduleMicrotask(() {
                  unawaited(emitTtsCallback('speak.onComplete'));
                });
                return 1;
            }
            return 1;
          });

      final service = TtsService();
      addTearDown(service.stop);
      final config = PlayConfig.defaults.tts.copyWith(
        provider: TtsProviderType.local,
        localVoice: '',
        language: 'auto',
      );

      await service.speak('abandon', config);
      await service.speak('离开；放弃', config);

      expect(spokenTexts, <String>['abandon', '离开；放弃']);
      expect(getVoicesCalls, 1);
      expect(voicePayloads, <Map<String, String>>[
        <String, String>{'name': 'Zira', 'locale': 'en-US'},
        <String, String>{'name': 'Huihui', 'locale': 'zh-CN'},
      ]);
    },
  );

  test(
    'windows local tts completes from callback even if isSpeaking stays true',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      var isSpeakingCalls = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ttsChannel, (call) async {
            switch (call.method) {
              case 'awaitSpeakCompletion':
              case 'setSpeechRate':
              case 'setVolume':
              case 'setPitch':
              case 'stop':
                return 1;
              case 'getVoices':
                return <Map<String, String>>[
                  <String, String>{'name': 'Zira', 'locale': 'en-US'},
                ];
              case 'setVoice':
                return 1;
              case 'isSpeaking':
                isSpeakingCalls += 1;
                return true;
              case 'speak':
                Future<void>.delayed(const Duration(milliseconds: 20), () {
                  unawaited(emitTtsCallback('speak.onComplete'));
                });
                return 1;
            }
            return 1;
          });

      final service = TtsService();
      addTearDown(service.stop);
      final config = PlayConfig.defaults.tts.copyWith(
        provider: TtsProviderType.local,
        localVoice: '',
        language: 'auto',
      );

      final stopwatch = Stopwatch()..start();
      await service.speak('abbot', config).timeout(const Duration(seconds: 2));
      stopwatch.stop();

      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
      expect(isSpeakingCalls, lessThanOrEqualTo(1));
    },
  );

  test(
    'windows local tts falls back to isSpeaking polling when callback is missing',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      var isSpeakingCalls = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ttsChannel, (call) async {
            switch (call.method) {
              case 'awaitSpeakCompletion':
              case 'setSpeechRate':
              case 'setVolume':
              case 'setPitch':
              case 'stop':
                return 1;
              case 'getVoices':
                return <Map<String, String>>[
                  <String, String>{'name': 'Zira', 'locale': 'en-US'},
                ];
              case 'setVoice':
                return 1;
              case 'isSpeaking':
                isSpeakingCalls += 1;
                return isSpeakingCalls < 3;
              case 'speak':
                return 1;
            }
            return 1;
          });

      final service = TtsService();
      addTearDown(service.stop);
      final config = PlayConfig.defaults.tts.copyWith(
        provider: TtsProviderType.local,
        localVoice: '',
        language: 'auto',
      );

      await service.speak('abbot', config).timeout(const Duration(seconds: 2));

      expect(isSpeakingCalls, 3);
    },
  );

  test('windows local tts keeps explicit local voice selection', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final voicePayloads = <Map<String, String>>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (call) async {
          switch (call.method) {
            case 'awaitSpeakCompletion':
            case 'setSpeechRate':
            case 'setVolume':
            case 'setPitch':
            case 'stop':
              return 1;
            case 'getVoices':
              return <Map<String, String>>[
                <String, String>{'name': 'Zira', 'locale': 'en-US'},
                <String, String>{'name': 'Huihui', 'locale': 'zh-CN'},
              ];
            case 'setVoice':
              voicePayloads.add(
                Map<String, String>.from(
                  call.arguments as Map<Object?, Object?>,
                ),
              );
              return 1;
            case 'speak':
              scheduleMicrotask(() {
                unawaited(emitTtsCallback('speak.onComplete'));
              });
              return 1;
          }
          return 1;
        });

    final service = TtsService();
    addTearDown(service.stop);
    final config = PlayConfig.defaults.tts.copyWith(
      provider: TtsProviderType.local,
      localVoice: 'Zira',
      language: 'auto',
    );

    await service.speak('中文释义', config);

    expect(voicePayloads, <Map<String, String>>[
      <String, String>{'name': 'Zira', 'locale': 'en-US'},
    ]);
  });

  test(
    'windows local tts falls back to setLanguage when setVoice fails',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final languageCalls = <String>[];
      final voicePayloads = <Map<String, String>>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ttsChannel, (call) async {
            switch (call.method) {
              case 'awaitSpeakCompletion':
              case 'setSpeechRate':
              case 'setVolume':
              case 'setPitch':
              case 'stop':
                return 1;
              case 'getVoices':
                return <Map<String, String>>[
                  <String, String>{'name': 'Zira', 'locale': 'en-US'},
                  <String, String>{'name': 'Huihui', 'locale': 'zh-CN'},
                ];
              case 'setVoice':
                voicePayloads.add(
                  Map<String, String>.from(
                    call.arguments as Map<Object?, Object?>,
                  ),
                );
                return 0;
              case 'setLanguage':
                languageCalls.add(call.arguments as String);
                return 1;
              case 'speak':
                scheduleMicrotask(() {
                  unawaited(emitTtsCallback('speak.onComplete'));
                });
                return 1;
            }
            return 1;
          });

      final service = TtsService();
      addTearDown(service.stop);
      final config = PlayConfig.defaults.tts.copyWith(
        provider: TtsProviderType.local,
        localVoice: '',
        language: 'auto',
      );

      await service.speak('释义内容', config);

      expect(voicePayloads, <Map<String, String>>[
        <String, String>{'name': 'Huihui', 'locale': 'zh-CN'},
      ]);
      expect(languageCalls, <String>['zh-CN']);
    },
  );
}

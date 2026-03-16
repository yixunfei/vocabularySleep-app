import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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

  const flutterTtsChannel = MethodChannel('flutter_tts');
  const audioChannel = MethodChannel('xyz.luan/audioplayers');
  const audioGlobalChannel = MethodChannel('xyz.luan/audioplayers.global');
  const audioEventsChannel = MethodChannel('xyz.luan/audioplayers/events');
  const audioGlobalEventsChannel = MethodChannel(
    'xyz.luan/audioplayers.global/events',
  );

  late PathProviderPlatform originalPathProvider;
  late Directory tempDir;
  late Directory supportDir;
  dynamic flutterTtsVoicesPayload;

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

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(flutterTtsChannel, (call) async {
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
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(flutterTtsChannel, null);
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
}

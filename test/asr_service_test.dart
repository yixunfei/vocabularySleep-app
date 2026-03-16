import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/services/asr_service.dart';

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

  const recordChannel = MethodChannel('com.llfbandit.record/messages');
  late PathProviderPlatform originalPathProvider;
  late Directory tempDir;
  late Directory supportDir;
  late AsrService service;

  setUp(() async {
    originalPathProvider = PathProviderPlatform.instance;
    tempDir = await Directory.systemTemp.createTemp('asr-service-temp-');
    supportDir = await Directory.systemTemp.createTemp('asr-service-support-');
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      temporaryPath: tempDir.path,
      applicationSupportPath: supportDir.path,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(recordChannel, (call) async {
          switch (call.method) {
            case 'create':
            case 'cancel':
            case 'dispose':
              return null;
          }
          return false;
        });
    service = AsrService();
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(recordChannel, null);
    PathProviderPlatform.instance = originalPathProvider;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    if (await supportDir.exists()) {
      await supportDir.delete(recursive: true);
    }
  });

  test(
    'transcribeFile returns disabled result before touching audio',
    () async {
      final result = await service.transcribeFile(
        audioPath: 'missing.wav',
        config: PlayConfig.defaults.asr,
      );

      expect(result.success, isFalse);
      expect(result.error, 'asrDisabled');
    },
  );

  test(
    'transcribeFile reports missing audio file when ASR is enabled',
    () async {
      final result = await service.transcribeFile(
        audioPath: '${tempDir.path}\\missing.wav',
        config: PlayConfig.defaults.asr.copyWith(enabled: true),
      );

      expect(result.success, isFalse);
      expect(result.error, 'asrAudioFileNotFound');
    },
  );

  test('local similarity requires an expected transcript', () async {
    final audioFile = File('${tempDir.path}\\dummy.wav');
    await audioFile.writeAsBytes(const <int>[1, 2, 3], flush: true);

    final result = await service.transcribeFile(
      audioPath: audioFile.path,
      config: PlayConfig.defaults.asr.copyWith(
        enabled: true,
        provider: AsrProviderType.localSimilarity,
      ),
    );

    expect(result.success, isFalse);
    expect(result.error, 'asrSimilarityExpectedTextMissing');
  });

  test('local similarity requires a TTS reference config', () async {
    final audioFile = File('${tempDir.path}\\dummy.wav');
    await audioFile.writeAsBytes(const <int>[1, 2, 3], flush: true);

    final result = await service.transcribeFile(
      audioPath: audioFile.path,
      config: PlayConfig.defaults.asr.copyWith(
        enabled: true,
        provider: AsrProviderType.localSimilarity,
      ),
      expectedText: 'focus',
    );

    expect(result.success, isFalse);
    expect(result.error, 'asrSimilarityTtsMissing');
  });

  test(
    'pron scoring pack status reflects prepare and remove lifecycle',
    () async {
      const method = PronScoringMethod.gop;

      final before = await service.getPronScoringPackStatus(method);
      expect(before.installed, isFalse);
      expect(before.bytes, 0);

      await service.preparePronScoringPack(method: method);

      final installed = await service.getPronScoringPackStatus(method);
      expect(installed.installed, isTrue);
      expect(installed.bytes, greaterThan(0));

      await service.removePronScoringPack(method);

      final removed = await service.getPronScoringPackStatus(method);
      expect(removed.installed, isFalse);
      expect(removed.bytes, 0);
    },
  );
}

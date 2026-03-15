import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:vocabulary_sleep_app/src/services/app_log_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'vocabulary_sleep_log_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          if (call.method == 'getApplicationSupportDirectory') {
            return tempDir.path;
          }
          return tempDir.path;
        });
    AppLogService.instance.resetForTest();
  });

  tearDown(() async {
    await AppLogService.instance.flushForTest();
    AppLogService.instance.resetForTest();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('recreates the log directory after it is deleted', () async {
    final service = AppLogService.instance;

    await service.init();
    final initialPath = await service.getLogFilePath();
    expect(initialPath, isNotNull);

    final initialDirectory = Directory(p.dirname(initialPath!));
    expect(await initialDirectory.exists(), isTrue);

    await initialDirectory.delete(recursive: true);
    expect(await initialDirectory.exists(), isFalse);

    service.i('test', 'after delete', data: <String, Object?>{'attempt': 1});
    await service.flushForTest();

    final recoveredPath = await service.getLogFilePath();
    expect(recoveredPath, isNotNull);

    final recoveredFile = File(recoveredPath!);
    expect(await recoveredFile.exists(), isTrue);
    expect(
      await recoveredFile.readAsString(),
      contains('"message":"after delete"'),
    );
  });

  test('falls back to console-only logging when path provider is unavailable', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    AppLogService.instance.resetForTest();

    final service = AppLogService.instance;
    service.i('test', 'plugin unavailable');
    await service.flushForTest();

    expect(await service.getLogFilePath(), isNull);
    expect(service.isFileLoggingDisabled, isTrue);
    expect(service.fileLoggingDisableReason, isNotNull);
  });
}

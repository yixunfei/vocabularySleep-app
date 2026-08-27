import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:vocabulary_sleep_app/src/services/app_log_service.dart';
import 'package:vocabulary_sleep_app/src/services/buffered_file_log_writer.dart';

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

  test(
    'falls back to console-only logging when path provider is unavailable',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderChannel, null);
      AppLogService.instance.resetForTest();

      final service = AppLogService.instance;
      service.i('test', 'plugin unavailable');
      await service.flushForTest();

      expect(await service.getLogFilePath(), isNull);
      expect(service.isFileLoggingDisabled, isTrue);
      expect(service.fileLoggingDisableReason, isNotNull);
    },
  );

  test('keeps debug logs console-only', () async {
    final previousDebugPrint = debugPrint;
    debugPrint = (String? _, {int? wrapWidth}) {};
    addTearDown(() => debugPrint = previousDebugPrint);
    final service = AppLogService.instance;

    service.d('test', 'debug-only-line');
    service.i('test', 'persisted-info-line');
    await service.flushForTest();

    final path = await service.getLogFilePath();
    expect(path, isNotNull);
    final content = await File(path!).readAsString();
    expect(content, contains('persisted-info-line'));
    expect(content, isNot(contains('debug-only-line')));
  });

  test('bounds burst backlog and preserves a trailing error', () async {
    final previousDebugPrint = debugPrint;
    debugPrint = (String? _, {int? wrapWidth}) {};
    addTearDown(() => debugPrint = previousDebugPrint);
    final service = AppLogService.instance;
    await service.init();
    final payload = List<String>.filled(160, 'x').join();

    for (var index = 0; index < 5000; index += 1) {
      service.i(
        'burst',
        'line $index',
        data: <String, Object?>{'payload': payload},
      );
    }
    service.e('burst', 'must-survive-backpressure');

    expect(
      service.retainedFileLogLineCount,
      lessThanOrEqualTo(service.maxRetainedFileLogLines),
    );
    expect(
      service.maxObservedRetainedFileLogLines,
      lessThanOrEqualTo(service.maxRetainedFileLogLines),
    );
    expect(service.droppedFileLogLineCount, greaterThan(0));

    await service.flushForTest();
    final path = await service.getLogFilePath();
    expect(path, isNotNull);
    expect(
      await File(path!).readAsString(),
      contains('must-survive-backpressure'),
    );
    expect(service.fileLogWriteBatchCount, lessThan(20));
  });

  test('reset serializes a new generation behind the active drain', () async {
    final file = File(p.join(tempDir.path, 'generation.log'));
    final firstResolveStarted = Completer<void>();
    final releaseFirstResolve = Completer<void>();
    var resolveCount = 0;
    final writer = BufferedFileLogWriter(
      resolveFile: ({bool forceRefresh = false}) async {
        resolveCount += 1;
        if (resolveCount == 1) {
          firstResolveStarted.complete();
          await releaseFirstResolve.future;
        }
        return file;
      },
      isDisabled: () => false,
      shouldDisable: (_) => false,
      disable: (_) {},
    );

    writer.add(level: 'INFO', line: 'old generation');
    await firstResolveStarted.future;
    writer.reset();
    writer.add(level: 'ERROR', line: 'new generation');

    expect(resolveCount, 1);
    releaseFirstResolve.complete();
    await writer.flush();

    expect(await file.readAsString(), isNot(contains('old generation')));
    expect(await file.readAsString(), contains('new generation'));
    expect(writer.writeBatchCount, 1);
  });
}

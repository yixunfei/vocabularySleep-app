import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/models/todo_item.dart';
import 'package:vocabulary_sleep_app/src/services/app_log_service.dart';
import 'package:vocabulary_sleep_app/src/services/database_service.dart';
import 'package:vocabulary_sleep_app/src/services/system_calendar_service.dart';
import 'package:vocabulary_sleep_app/src/services/wordbook_import_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const systemCalendarChannel = MethodChannel(
    'vocabulary_sleep/system_calendar',
  );
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'vocabulary_sleep_system_calendar_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          if (call.method == 'getApplicationSupportDirectory') {
            return tempDir.path;
          }
          if (call.method == 'getTemporaryDirectory') {
            return tempDir.path;
          }
          return tempDir.path;
        });
    AppLogService.instance.resetForTest();
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    await AppLogService.instance.flushForTest();
    AppLogService.instance.resetForTest();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'system calendar sync sends notification and alarm offsets separately',
    () async {
      final database = AppDatabaseService(WordbookImportService());
      await database.init();
      final service = PlatformSystemCalendarService(database);
      MethodCall? capturedCall;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(systemCalendarChannel, (call) async {
            capturedCall = call;
            return <String, Object?>{'success': true, 'eventId': 'event-1'};
          });

      addTearDown(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(systemCalendarChannel, null);
        await service.dispose();
        database.dispose();
      });

      await service.syncTodo(
        TodoItem(
          id: 1,
          content: 'Calendar alert split',
          dueAt: DateTime(2026, 3, 18, 9, 30),
          alarmEnabled: true,
          systemCalendarNotificationEnabled: true,
          systemCalendarNotificationMinutesBefore: 5,
          systemCalendarAlarmEnabled: true,
          systemCalendarAlarmMinutesBefore: 15,
        ),
      );

      expect(capturedCall, isNotNull);
      expect(capturedCall!.method, 'upsertTodoReminder');

      final arguments = Map<Object?, Object?>.from(
        capturedCall!.arguments as Map,
      );
      expect(
        List<Object?>.from(arguments['notificationOffsetsMinutes'] as List),
        <Object?>[5],
      );
      expect(
        List<Object?>.from(arguments['alarmOffsetsMinutes'] as List),
        <Object?>[15],
      );
      expect(
        List<Object?>.from(arguments['reminderOffsetsMinutes'] as List),
        <Object?>[5, 15],
      );
    },
  );
}

import 'dart:io';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/todo_item.dart';
import 'package:vocabulary_sleep_app/src/models/word_entry.dart';
import 'package:vocabulary_sleep_app/src/models/word_field.dart';
import 'package:vocabulary_sleep_app/src/models/word_memory_progress.dart';
import 'package:vocabulary_sleep_app/src/services/app_log_service.dart';
import 'package:vocabulary_sleep_app/src/services/database_service.dart';
import 'package:vocabulary_sleep_app/src/services/wordbook_import_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'vocabulary_sleep_database_test_',
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
    await AppLogService.instance.flushForTest();
    AppLogService.instance.resetForTest();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('restores the database from a safety backup snapshot', () async {
    final database = AppDatabaseService(WordbookImportService());
    await database.init();
    addTearDown(database.dispose);

    await database.importWordbook(
      sourcePath: 'custom:test_restore',
      name: 'Restore test',
      entries: const <WordEntryPayload>[
        WordEntryPayload(
          word: 'alpha',
          fields: <WordFieldItem>[
            WordFieldItem(key: 'meaning', label: 'Meaning', value: 'First'),
          ],
          rawContent: 'First',
        ),
      ],
    );

    final wordbook = database.getWordbooks().firstWhere(
      (item) => item.path == 'custom:test_restore',
    );
    expect(database.getWords(wordbook.id).map((item) => item.word), <String>[
      'alpha',
    ]);

    final backupPath = await database.createSafetyBackup(
      reason: 'restore_test',
    );
    expect(await File(backupPath).exists(), isTrue);

    database.addWord(
      wordbook.id,
      const WordEntryPayload(
        word: 'beta',
        fields: <WordFieldItem>[
          WordFieldItem(key: 'meaning', label: 'Meaning', value: 'Second'),
        ],
        rawContent: 'Second',
      ),
    );
    expect(database.getWords(wordbook.id).map((item) => item.word), <String>[
      'alpha',
      'beta',
    ]);

    await database.restoreSafetyBackup(backupPath);

    final restoredWordbook = database.getWordbooks().firstWhere(
      (item) => item.path == 'custom:test_restore',
    );
    expect(
      database.getWords(restoredWordbook.id).map((item) => item.word),
      <String>['alpha'],
    );
  });

  test(
    'updateWord replaces existing content instead of appending it',
    () async {
      final database = AppDatabaseService(WordbookImportService());
      await database.init();
      addTearDown(database.dispose);

      await database.importWordbook(
        sourcePath: 'custom:test_update',
        name: 'Update test',
        entries: const <WordEntryPayload>[
          WordEntryPayload(
            word: 'alpha',
            fields: <WordFieldItem>[
              WordFieldItem(key: 'meaning', label: 'Meaning', value: '123'),
            ],
            rawContent: '123',
          ),
        ],
      );

      final wordbook = database.getWordbooks().firstWhere(
        (item) => item.path == 'custom:test_update',
      );

      database.updateWord(
        wordbookId: wordbook.id,
        sourceWord: 'alpha',
        payload: const WordEntryPayload(
          word: 'alpha',
          fields: <WordFieldItem>[
            WordFieldItem(key: 'meaning', label: 'Meaning', value: '321'),
            WordFieldItem(key: 'memory', label: 'Memory', value: 'fresh note'),
          ],
          rawContent: '321',
        ),
      );

      final updated = database.getWords(wordbook.id).single;
      expect(updated.meaning, '321');
      expect(updated.rawContent, '321');
      expect(
        updated.fields.firstWhere((item) => item.key == 'meaning').asText(),
        '321',
      );
      expect(
        updated.fields.firstWhere((item) => item.key == 'memory').asText(),
        'fresh note',
      );
      expect(
        updated.fields.any((item) => item.asText().contains('123')),
        isFalse,
      );
    },
  );

  test('exportUserData writes notes and todos to json', () async {
    final database = AppDatabaseService(WordbookImportService());
    await database.init();
    addTearDown(database.dispose);

    database.insertTodo(
      TodoItem(
        content: 'Review exported todos',
        priority: 2,
        createdAt: DateTime(2026, 3, 14),
      ),
    );
    database.insertNote(
      PlanNote(
        title: 'Export note',
        content: 'Keep user data safe.',
        createdAt: DateTime(2026, 3, 14),
        updatedAt: DateTime(2026, 3, 14),
      ),
    );

    final exportPath = await database.exportUserData();
    final exportFile = File(exportPath);
    expect(await exportFile.exists(), isTrue);

    final decoded = jsonDecode(await exportFile.readAsString()) as Map;
    final todos = decoded['todos'] as List;
    final notes = decoded['notes'] as List;
    expect(
      todos.any((item) => (item as Map)['content'] == 'Review exported todos'),
      isTrue,
    );
    expect(
      notes.any((item) => (item as Map)['title'] == 'Export note'),
      isTrue,
    );
  });

  test('todo deferred status persists and is cleared by completion', () async {
    final database = AppDatabaseService(WordbookImportService());
    await database.init();
    addTearDown(database.dispose);

    database.insertTodo(
      TodoItem(
        content: 'Pause until next review cycle',
        deferred: true,
        priority: 1,
        createdAt: DateTime(2026, 3, 14),
      ),
    );

    final inserted = database.getTodos().singleWhere(
      (item) => item.content == 'Pause until next review cycle',
    );
    expect(inserted.isDeferred, isTrue);
    expect(inserted.completed, isFalse);

    database.updateTodo(
      inserted.copyWith(
        completed: true,
        deferred: true,
        completedAt: DateTime(2026, 3, 15),
      ),
    );

    final updated = database.getTodos().singleWhere(
      (item) => item.id == inserted.id,
    );
    expect(updated.completed, isTrue);
    expect(updated.isDeferred, isFalse);
  });

  test(
    'todo calendar sync preference persists and defaults to enabled',
    () async {
      final database = AppDatabaseService(WordbookImportService());
      await database.init();
      addTearDown(database.dispose);

      database.insertTodo(
        TodoItem(
          content: 'Keep syncing by default',
          alarmEnabled: true,
          dueAt: DateTime(2026, 3, 16, 9),
          createdAt: DateTime(2026, 3, 16),
        ),
      );
      database.insertTodo(
        TodoItem(
          content: 'Only keep in-app reminder',
          alarmEnabled: true,
          dueAt: DateTime(2026, 3, 16, 10),
          syncToSystemCalendar: false,
          systemCalendarNotificationEnabled: false,
          systemCalendarAlarmEnabled: true,
          systemCalendarAlarmMinutesBefore: 15,
          createdAt: DateTime(2026, 3, 16),
        ),
      );

      final synced = database.getTodos().singleWhere(
        (item) => item.content == 'Keep syncing by default',
      );
      final localOnly = database.getTodos().singleWhere(
        (item) => item.content == 'Only keep in-app reminder',
      );

      expect(synced.syncToSystemCalendar, isTrue);
      expect(synced.systemCalendarNotificationEnabled, isTrue);
      expect(synced.systemCalendarNotificationMinutesBefore, 0);
      expect(synced.systemCalendarAlarmEnabled, isFalse);
      expect(synced.systemCalendarAlarmMinutesBefore, 10);
      expect(localOnly.syncToSystemCalendar, isFalse);
      expect(localOnly.systemCalendarNotificationEnabled, isFalse);
      expect(localOnly.systemCalendarAlarmEnabled, isTrue);
      expect(localOnly.systemCalendarAlarmMinutesBefore, 15);
    },
  );

  test('word memory progress persists spaced repetition fields', () async {
    final database = AppDatabaseService(WordbookImportService());
    await database.init();
    addTearDown(database.dispose);

    await database.importWordbook(
      sourcePath: 'custom:test_progress',
      name: 'Progress test',
      entries: const <WordEntryPayload>[
        WordEntryPayload(
          word: 'alpha',
          fields: <WordFieldItem>[
            WordFieldItem(key: 'meaning', label: 'Meaning', value: 'First'),
          ],
          rawContent: 'First',
        ),
      ],
    );

    final wordbook = database.getWordbooks().firstWhere(
      (item) => item.path == 'custom:test_progress',
    );
    final word = database.getWords(wordbook.id).single;

    database.upsertWordMemoryProgress(
      WordMemoryProgress(
        wordId: word.id!,
        timesPlayed: 4,
        timesCorrect: 3,
        lastPlayed: DateTime.utc(2026, 3, 15, 8),
        familiarity: 0.625,
        easeFactor: 2.42,
        intervalDays: 6,
        nextReview: DateTime.utc(2026, 3, 21, 8),
        consecutiveCorrect: 2,
        memoryState: 'familiar',
      ),
    );

    final stored = database.getWordMemoryProgress(word.id!);
    expect(stored, isNotNull);
    expect(stored!.timesPlayed, 4);
    expect(stored.timesCorrect, 3);
    expect(stored.easeFactor, closeTo(2.42, 0.0001));
    expect(stored.intervalDays, 6);
    expect(stored.nextReview, DateTime.utc(2026, 3, 21, 8));
    expect(stored.consecutiveCorrect, 2);
    expect(stored.memoryState, 'familiar');
  });

  test('exportUserData includes word memory progress rows', () async {
    final database = AppDatabaseService(WordbookImportService());
    await database.init();
    addTearDown(database.dispose);

    await database.importWordbook(
      sourcePath: 'custom:test_progress_export',
      name: 'Progress export test',
      entries: const <WordEntryPayload>[
        WordEntryPayload(
          word: 'alpha',
          fields: <WordFieldItem>[
            WordFieldItem(key: 'meaning', label: 'Meaning', value: 'First'),
          ],
          rawContent: 'First',
        ),
      ],
    );

    final wordbook = database.getWordbooks().firstWhere(
      (item) => item.path == 'custom:test_progress_export',
    );
    final word = database.getWords(wordbook.id).single;
    database.upsertWordMemoryProgress(
      WordMemoryProgress(
        wordId: word.id!,
        timesPlayed: 2,
        timesCorrect: 1,
        nextReview: DateTime.utc(2026, 3, 16, 8),
        consecutiveCorrect: 1,
        memoryState: 'learning',
      ),
    );

    final exportPath = await database.exportUserData();
    final decoded = jsonDecode(await File(exportPath).readAsString()) as Map;
    final progressRows = decoded['progress'] as List<dynamic>;

    expect(progressRows, isNotEmpty);
    expect(
      progressRows.any((item) {
        final row = item as Map;
        return row['word_id'] == word.id &&
            row['times_played'] == 2 &&
            row['consecutive_correct'] == 1;
      }),
      isTrue,
    );
  });

  test('deleteSafetyBackup removes an existing backup file', () async {
    final database = AppDatabaseService(WordbookImportService());
    await database.init();
    addTearDown(database.dispose);

    await database.importWordbook(
      sourcePath: 'custom:test_backup_delete',
      name: 'Delete backup test',
      entries: const <WordEntryPayload>[
        WordEntryPayload(
          word: 'alpha',
          fields: <WordFieldItem>[
            WordFieldItem(key: 'meaning', label: 'Meaning', value: 'First'),
          ],
          rawContent: 'First',
        ),
      ],
    );

    final backupPath = await database.createSafetyBackup(reason: 'delete_test');
    expect(await File(backupPath).exists(), isTrue);

    await database.deleteSafetyBackup(backupPath);

    expect(await File(backupPath).exists(), isFalse);
  });
}

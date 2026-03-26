import 'dart:io';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:vocabulary_sleep_app/src/models/todo_item.dart';
import 'package:vocabulary_sleep_app/src/models/user_data_export.dart';
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

  test('database schema version is upgraded for future migrations', () async {
    final database = AppDatabaseService(WordbookImportService());
    await database.init();
    addTearDown(database.dispose);

    final sqlite = sqlite3.open(database.dbPath);
    addTearDown(sqlite.dispose);
    final row = sqlite.select('PRAGMA user_version;').single;

    expect((row['user_version'] as int?) ?? 0, greaterThanOrEqualTo(7));
  });

  test(
    'words persist only minimal entry_json recovery fields in sqlite',
    () async {
      final database = AppDatabaseService(WordbookImportService());
      await database.init();
      addTearDown(database.dispose);

      await database.importWordbook(
        sourcePath: 'custom:test_entry_json',
        name: 'Entry json test',
        entries: const <WordEntryPayload>[
          WordEntryPayload(
            word: 'alpha',
            fields: <WordFieldItem>[
              WordFieldItem(key: 'meaning', label: 'Meaning', value: 'First'),
              WordFieldItem(
                key: 'usage',
                label: 'Usage',
                value: 'Use it in a sentence.',
                style: WordFieldStyle(
                  backgroundHex: '#101010',
                  textHex: '#ffffff',
                ),
              ),
            ],
            rawContent: 'First',
          ),
        ],
      );

      final wordbook = database.getWordbooks().firstWhere(
        (item) => item.path == 'custom:test_entry_json',
      );
      final sqlite = sqlite3.open(database.dbPath);
      addTearDown(sqlite.dispose);

      final row = sqlite.select(
        'SELECT entry_json, extension_json FROM words WHERE wordbook_id = ?',
        <Object?>[wordbook.id],
      ).single;
      final entryJson = '${row['entry_json'] ?? ''}';
      expect(entryJson.trim(), isNotEmpty);

      final decoded = jsonDecode(entryJson) as Map<String, Object?>;
      expect(decoded['rawContent'], 'First');
      expect(decoded.keys, <String>['rawContent']);

      final extensionJson = '${row['extension_json'] ?? ''}';
      expect(extensionJson.trim(), isNotEmpty);
      final decodedExtension =
          jsonDecode(extensionJson) as Map<String, Object?>;
      final extensionFields = decodedExtension['fields'] as List;
      expect(extensionFields, hasLength(1));
      expect((extensionFields.single as Map)['key'], 'usage');

      final fieldRows = sqlite.select(
        '''
      SELECT field_key, field_label, field_value_json, style_json
      FROM word_fields
      WHERE word_id = (SELECT id FROM words WHERE wordbook_id = ?)
      ORDER BY sort_order ASC
      ''',
        <Object?>[wordbook.id],
      );
      expect(fieldRows.length, 2);
      expect(fieldRows.first['field_key'], 'meaning');
      expect(
        jsonDecode('${fieldRows.last['field_value_json']}'),
        'Use it in a sentence.',
      );
      expect(
        (jsonDecode('${fieldRows.last['style_json']}') as Map)['textHex'],
        '#ffffff',
      );

      final restored = database.getWords(wordbook.id).single;
      expect(
        restored.fields.firstWhere((item) => item.key == 'usage').asText(),
        'Use it in a sentence.',
      );
      expect(
        restored.fields.firstWhere((item) => item.key == 'usage').style.textHex,
        '#ffffff',
      );
    },
  );

  test('searchWords queries cached sqlite search columns', () async {
    final database = AppDatabaseService(WordbookImportService());
    await database.init();
    addTearDown(database.dispose);

    await database.importWordbook(
      sourcePath: 'custom:test_search_words',
      name: 'Search words test',
      entries: const <WordEntryPayload>[
        WordEntryPayload(
          word: 'Alpha',
          fields: <WordFieldItem>[
            WordFieldItem(key: 'meaning', label: 'Meaning', value: 'First'),
            WordFieldItem(key: 'usage', label: 'Usage', value: 'Launch item'),
          ],
          rawContent: 'First',
        ),
        WordEntryPayload(
          word: 'Bravo',
          fields: <WordFieldItem>[
            WordFieldItem(key: 'meaning', label: 'Meaning', value: 'Second'),
          ],
          rawContent: 'Second',
        ),
      ],
    );

    final wordbook = database.getWordbooks().firstWhere(
      (item) => item.path == 'custom:test_search_words',
    );

    expect(
      database
          .searchWords(wordbook.id, query: 'alp', mode: 'word')
          .map((item) => item.word)
          .toList(growable: false),
      <String>['Alpha'],
    );
    expect(
      database
          .searchWords(wordbook.id, query: 'launch', mode: 'meaning')
          .map((item) => item.word)
          .toList(growable: false),
      <String>['Alpha'],
    );
    expect(
      database
          .searchWords(wordbook.id, query: 'ah', mode: 'fuzzy')
          .map((item) => item.word)
          .toList(growable: false),
      <String>['Alpha'],
    );
  });

  test(
    'searchWords normalizes diacritics and fuzzy order like in-memory search',
    () async {
      final database = AppDatabaseService(WordbookImportService());
      await database.init();
      addTearDown(database.dispose);

      await database.importWordbook(
        sourcePath: 'custom:test_search_diacritics',
        name: 'Search diacritics test',
        entries: const <WordEntryPayload>[
          WordEntryPayload(
            word: 'Éclair',
            fields: <WordFieldItem>[
              WordFieldItem(key: 'meaning', label: 'Meaning', value: 'Dessert'),
            ],
            rawContent: 'Dessert',
          ),
        ],
      );

      final wordbook = database.getWordbooks().firstWhere(
        (item) => item.path == 'custom:test_search_diacritics',
      );

      expect(
        database
            .searchWords(wordbook.id, query: 'ecl', mode: 'word')
            .map((item) => item.word)
            .toList(growable: false),
        <String>['Éclair'],
      );
      expect(
        database
            .searchWords(wordbook.id, query: 'elr', mode: 'fuzzy')
            .map((item) => item.word)
            .toList(growable: false),
        <String>['Éclair'],
      );
    },
  );

  test('word field style tag and media subtables round-trip through sqlite', () async {
    final database = AppDatabaseService(WordbookImportService());
    await database.init();
    addTearDown(database.dispose);

    await database.importWordbook(
      sourcePath: 'custom:test_field_subtables',
      name: 'Field subtables test',
      entries: const <WordEntryPayload>[
        WordEntryPayload(
          word: 'alpha',
          fields: <WordFieldItem>[
            WordFieldItem(
              key: 'usage',
              label: 'Usage',
              value: 'Use it in a sentence.',
              style: WordFieldStyle(
                backgroundHex: '#101010',
                borderHex: '#202020',
                textHex: '#ffffff',
                accentHex: '#00ffcc',
              ),
              tags: <String>['core', 'spoken'],
              media: <WordFieldMediaItem>[
                WordFieldMediaItem(
                  type: WordFieldMediaType.audio,
                  source: 'https://example.com/audio.mp3',
                  label: 'Pronunciation',
                  mimeType: 'audio/mpeg',
                ),
              ],
            ),
          ],
          rawContent: 'Use it in a sentence.',
        ),
      ],
    );

    final wordbook = database.getWordbooks().firstWhere(
      (item) => item.path == 'custom:test_field_subtables',
    );
    final sqlite = sqlite3.open(database.dbPath);
    addTearDown(sqlite.dispose);

    final fieldId =
        (sqlite.select(
              'SELECT id FROM word_fields WHERE word_id = (SELECT id FROM words WHERE wordbook_id = ?) AND field_key = ?',
              <Object?>[wordbook.id, 'usage'],
            ).single['id']
            as int);

    final styleRow = sqlite.select(
      'SELECT text_hex, accent_hex FROM word_field_styles WHERE word_field_id = ?',
      <Object?>[fieldId],
    ).single;
    expect(styleRow['text_hex'], '#ffffff');
    expect(styleRow['accent_hex'], '#00ffcc');

    final tagRows = sqlite.select(
      'SELECT tag FROM word_field_tags WHERE word_field_id = ? ORDER BY sort_order ASC',
      <Object?>[fieldId],
    );
    expect(tagRows.map((row) => row['tag']), <Object?>['core', 'spoken']);

    final mediaRow = sqlite.select(
      'SELECT media_type, media_source, media_label, mime_type FROM word_field_media WHERE word_field_id = ?',
      <Object?>[fieldId],
    ).single;
    expect(mediaRow['media_type'], 'audio');
    expect(mediaRow['media_source'], 'https://example.com/audio.mp3');
    expect(mediaRow['media_label'], 'Pronunciation');
    expect(mediaRow['mime_type'], 'audio/mpeg');

    final restored = database.getWords(wordbook.id).single;
    final usage = restored.fields.firstWhere((item) => item.key == 'usage');
    expect(usage.style.textHex, '#ffffff');
    expect(usage.tags, <String>['core', 'spoken']);
    expect(usage.media.single.source, 'https://example.com/audio.mp3');
    expect(usage.media.single.type, WordFieldMediaType.audio);
  });

  test('getWords chunks sqlite IN queries for large field datasets', () async {
    final database = AppDatabaseService(WordbookImportService());
    await database.init();
    addTearDown(database.dispose);

    final entries = List<WordEntryPayload>.generate(1100, (index) {
      return WordEntryPayload(
        word: 'bulk_$index',
        fields: <WordFieldItem>[
          WordFieldItem(
            key: 'meaning',
            label: 'Meaning',
            value: 'Meaning $index',
          ),
          WordFieldItem(
            key: 'usage',
            label: 'Usage',
            value: 'Usage $index',
            style: const WordFieldStyle(
              backgroundHex: '#111111',
              textHex: '#ffffff',
            ),
            tags: const <String>['bulk'],
            media: <WordFieldMediaItem>[
              WordFieldMediaItem(
                type: WordFieldMediaType.audio,
                source: 'https://example.com/audio/$index.mp3',
                label: 'Audio',
              ),
            ],
          ),
        ],
        rawContent: 'Meaning $index',
      );
    });

    await database.importWordbook(
      sourcePath: 'custom:test_large_field_queries',
      name: 'Large field query test',
      entries: entries,
    );

    final wordbook = database.getWordbooks().firstWhere(
      (item) => item.path == 'custom:test_large_field_queries',
    );
    final words = database.getWords(wordbook.id);

    expect(words, hasLength(1100));
    final last = words.last;
    expect(last.word, 'bulk_1099');
    final usage = last.fields.firstWhere((item) => item.key == 'usage');
    expect(usage.asText(), 'Usage 1099');
    expect(usage.style.textHex, '#ffffff');
    expect(usage.tags, <String>['bulk']);
    expect(usage.media.single.source, 'https://example.com/audio/1099.mp3');
  });

  test('word memory events persist detailed answer history', () async {
    final database = AppDatabaseService(WordbookImportService());
    await database.init();
    addTearDown(database.dispose);

    await database.importWordbook(
      sourcePath: 'custom:test_memory_events',
      name: 'Memory event test',
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
      (item) => item.path == 'custom:test_memory_events',
    );
    final word = database.getWords(wordbook.id).single;
    database.insertWordMemoryEvent(
      wordId: word.id!,
      eventKind: 'weak',
      quality: 1,
      weakReasonIds: const <String>['meaning', 'spelling'],
      sessionTitle: 'Round A',
      createdAt: DateTime(2026, 3, 24, 14, 0),
    );

    final events = database.getWordMemoryEvents(word.id!);
    expect(events, hasLength(1));
    expect(events.single['event_kind'], 'weak');
    expect(events.single['quality'], 1);
    expect(events.single['session_title'], 'Round A');
    expect(jsonDecode('${events.single['weak_reasons_json']}'), <Object?>[
      'meaning',
      'spelling',
    ]);
  });

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

  test(
    'buildUserDataExportPayload aggregates wordbook fields from sqlite tables',
    () async {
      final database = AppDatabaseService(WordbookImportService());
      await database.init();
      addTearDown(database.dispose);

      await database.importWordbook(
        sourcePath: 'custom:test_export_wordbook_tables',
        name: 'Export table aggregation test',
        entries: const <WordEntryPayload>[
          WordEntryPayload(
            word: 'alpha',
            fields: <WordFieldItem>[
              WordFieldItem(key: 'meaning', label: 'Meaning', value: 'First'),
              WordFieldItem(
                key: 'usage',
                label: 'Usage',
                value: 'Use it in a sentence.',
                style: WordFieldStyle(
                  backgroundHex: '#101010',
                  textHex: '#ffffff',
                ),
                tags: <String>['core'],
                media: <WordFieldMediaItem>[
                  WordFieldMediaItem(
                    type: WordFieldMediaType.audio,
                    source: 'https://example.com/audio.mp3',
                    label: 'Pronunciation',
                  ),
                ],
              ),
            ],
            rawContent: 'First',
          ),
        ],
      );

      final payload = database.buildUserDataExportPayload(
        sections: const <UserDataExportSection>{
          UserDataExportSection.wordbooks,
        },
      );
      final exportedWordbook = payload.wordbooks.firstWhere(
        (item) => item.wordbook.path == 'custom:test_export_wordbook_tables',
      );
      final exportedWord = exportedWordbook.words.single;
      final usage = exportedWord.fields.firstWhere(
        (field) => field.key == 'usage',
      );

      expect(exportedWord.word, 'alpha');
      expect(exportedWord.rawContent, 'First');
      expect(exportedWord.meaning, 'First');
      expect(usage.asText(), 'Use it in a sentence.');
      expect(usage.style.textHex, '#ffffff');
      expect(usage.tags, <String>['core']);
      expect(usage.media.single.source, 'https://example.com/audio.mp3');
      expect(usage.media.single.type, WordFieldMediaType.audio);
    },
  );

  test(
    'exportUserData respects selected sections, settings, and custom destination',
    () async {
      final database = AppDatabaseService(WordbookImportService());
      await database.init();
      addTearDown(database.dispose);

      database.insertTodo(
        TodoItem(
          content: 'Only export selected content',
          priority: 1,
          createdAt: DateTime(2026, 3, 18),
        ),
      );
      database.insertNote(
        PlanNote(
          title: 'Should stay out of this export',
          content: 'Notes are not selected this time.',
          createdAt: DateTime(2026, 3, 18),
          updatedAt: DateTime(2026, 3, 18),
        ),
      );
      database.setSetting('theme', 'mono');

      final exportPath = await database.exportUserData(
        sections: const <UserDataExportSection>{
          UserDataExportSection.todos,
          UserDataExportSection.settings,
        },
        directoryPath: '${tempDir.path}${Platform.pathSeparator}custom-exports',
        fileName: 'manual backup',
      );

      expect(await File(exportPath).exists(), isTrue);
      expect(exportPath, endsWith('manual_backup.json'));

      final decoded =
          jsonDecode(await File(exportPath).readAsString())
              as Map<String, dynamic>;
      expect(decoded['sections'], <String>['todos', 'settings']);
      expect(decoded.containsKey('todos'), isTrue);
      expect(decoded.containsKey('settings'), isTrue);
      expect(decoded.containsKey('notes'), isFalse);
      expect(
        (decoded['todos'] as List<dynamic>).any(
          (item) => (item as Map)['content'] == 'Only export selected content',
        ),
        isTrue,
      );
      expect(decoded['settings'], containsPair('theme', 'mono'));
    },
  );

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
          systemCalendarNotificationEnabled: true,
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

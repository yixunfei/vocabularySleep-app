import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'package:vocabulary_sleep_app/src/services/wordbook_query_worker.dart';
import 'package:vocabulary_sleep_app/src/models/word_entry_lite_decoder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'background lite query reads summary rows without field tables',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'vocabulary_sleep_worker_test_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final databasePath = p.join(directory.path, 'worker.sqlite');
      final database = sqlite3.open(databasePath);
      database.execute('''
        CREATE TABLE words (
          id INTEGER PRIMARY KEY,
          wordbook_id INTEGER NOT NULL,
          word TEXT NOT NULL,
          meaning TEXT,
          entry_uid TEXT,
          primary_gloss TEXT,
          schema_version TEXT,
          sort_index INTEGER
        )
      ''');
      database.execute(
        'INSERT INTO words (id, wordbook_id, word, primary_gloss, sort_index) '
        'VALUES (1, 7, ?, ?, 0)',
        <Object?>['background', '后台读取'],
      );
      database.dispose();

      final rows = await loadWordbookLiteRowsInBackground(
        databasePath: databasePath,
        wordbookId: 7,
      );

      expect(rows, hasLength(1));
      expect(rows.single['word'], 'background');
      expect(rows.single['primary_gloss'], '后台读取');
      expect(rows.single.containsKey('field_value_json'), isFalse);

      final entry = wordEntryFromLiteRow(rows.single);
      expect(entry.summaryMeaningText, '后台读取');
      expect(entry.fields.map((field) => field.key), <String>['meaning']);

      final entries = await loadWordbookLiteEntriesInBackground(
        databasePath: databasePath,
        wordbookId: 7,
      );
      expect(entries, hasLength(1));
      expect(entries.single.id, 1);
      expect(entries.single.word, 'background');
      expect(entries.single.summaryMeaningText, '后台读取');
    },
  );

  test('background search materializes matching lite entries', () async {
    final directory = await Directory.systemTemp.createTemp(
      'vocabulary_sleep_search_worker_test_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final databasePath = p.join(directory.path, 'worker.sqlite');
    final database = sqlite3.open(databasePath);
    database.execute('''
      CREATE TABLE words (
        id INTEGER PRIMARY KEY,
        wordbook_id INTEGER NOT NULL,
        word TEXT NOT NULL,
        meaning TEXT,
        entry_uid TEXT,
        primary_gloss TEXT,
        schema_version TEXT,
        sort_index INTEGER,
        search_word TEXT NOT NULL,
        search_meaning TEXT,
        search_details TEXT,
        search_word_compact TEXT NOT NULL,
        search_details_compact TEXT
      )
    ''');
    database.execute(
      '''
      INSERT INTO words (
        id, wordbook_id, word, primary_gloss, sort_index,
        search_word, search_meaning, search_details,
        search_word_compact, search_details_compact
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      <Object?>[
        1,
        7,
        'background',
        'worker target',
        0,
        'background',
        'worker target',
        'worker target',
        'background',
        'workertarget',
      ],
    );
    database.execute(
      '''
      INSERT INTO words (
        id, wordbook_id, word, primary_gloss, sort_index,
        search_word, search_meaning, search_details,
        search_word_compact, search_details_compact
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      <Object?>[
        2,
        7,
        'ignored',
        'other',
        1,
        'ignored',
        'other',
        'other',
        'ignored',
        'other',
      ],
    );
    database.dispose();

    final result = await searchWordbookLiteInBackground(
      databasePath: databasePath,
      wordbookId: 7,
      query: 'target',
      mode: 'meaning',
    );

    expect(result.totalCount, 1);
    expect(result.entries, hasLength(1));
    expect(result.entries.single.word, 'background');
    expect(result.entries.single.summaryMeaningText, 'worker target');
  });
}

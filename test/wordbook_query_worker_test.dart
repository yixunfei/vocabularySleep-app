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
    },
  );
}

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/word_entry.dart';
import 'package:vocabulary_sleep_app/src/models/word_field.dart';
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
  });

  tearDown(() async {
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

  test('updateWord replaces existing content instead of appending it', () async {
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
    expect(updated.fields.any((item) => item.asText().contains('123')), isFalse);
  });
}

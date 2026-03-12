import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../models/word_entry.dart';
import '../models/word_field.dart';
import '../models/wordbook.dart';
import 'app_log_service.dart';
import 'wordbook_import_service.dart';

class WordbookMergeResult {
  const WordbookMergeResult({
    required this.total,
    required this.inserted,
    required this.updated,
    required this.sourceWordbookId,
    required this.targetWordbookId,
    required this.deleteSourceAfterMerge,
  });

  final int total;
  final int inserted;
  final int updated;
  final int sourceWordbookId;
  final int targetWordbookId;
  final bool deleteSourceAfterMerge;
}

class _BuiltInWordbookConfig {
  const _BuiltInWordbookConfig({
    required this.path,
    required this.name,
    required this.assetPath,
  });

  final String path;
  final String name;
  final String assetPath;
}

class AppDatabaseService {
  AppDatabaseService(this._importService);

  final WordbookImportService _importService;
  final AppLogService _log = AppLogService.instance;

  late final Database _db;
  late final String dbPath;
  bool _initialized = false;
  int _transactionDepth = 0;

  static const _specialWordbooks = <String, String>{
    'builtin:favorites': 'Favorites',
    'builtin:task': 'Task',
  };
  static const String _dictAssetPrefix = 'dict/';
  static const String _dictBuiltinPathPrefix = 'builtin:dict:';

  Future<void> init() async {
    if (_initialized) return;
    final supportDir = await getApplicationSupportDirectory();
    if (!await supportDir.exists()) {
      await supportDir.create(recursive: true);
    }
    dbPath = p.join(supportDir.path, 'vocabulary.db');
    _db = sqlite3.open(dbPath);
    _db.execute('PRAGMA foreign_keys = ON;');
    _db.execute('PRAGMA journal_mode = WAL;');
    _db.execute('PRAGMA synchronous = NORMAL;');
    _createTables();
    _migrateWordsSchema();
    ensureSpecialWordbooks();
    await syncBuiltInWordbooksCatalog();
    _initialized = true;
  }

  Future<String> createSafetyBackup({String reason = 'manual'}) async {
    if (!_initialized) {
      throw StateError('Database is not initialized');
    }

    final source = File(dbPath);
    if (!await source.exists()) {
      throw FileSystemException('Database file does not exist', dbPath);
    }

    final supportDir = await getApplicationSupportDirectory();
    final backupDir = Directory(p.join(supportDir.path, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final normalizedReason = reason.trim().isEmpty
        ? 'manual'
        : reason.trim().replaceAll(RegExp(r'[^\w-]+'), '_');
    final targetPath = p.join(
      backupDir.path,
      'vocabulary_${normalizedReason}_$timestamp.db',
    );
    await source.copy(targetPath);
    return targetPath;
  }

  Future<void> resetUserData() async {
    if (!_initialized) {
      throw StateError('Database is not initialized');
    }

    _runInTransaction<void>(() {
      _db.execute('DELETE FROM user_marks;');
      _db.execute('DELETE FROM progress;');
      _db.execute('''
        DELETE FROM words
        WHERE wordbook_id IN (
          SELECT id FROM wordbooks
          WHERE path IN ('builtin:favorites', 'builtin:task')
        )
        ''');
      _db.execute('''
        DELETE FROM wordbooks
        WHERE path IS NULL OR path NOT LIKE 'builtin:%'
        ''');
      _db.execute('DELETE FROM settings;');
      _db.execute('''
        UPDATE wordbooks
        SET word_count = (
          SELECT COUNT(*)
          FROM words
          WHERE words.wordbook_id = wordbooks.id
        )
        ''');
    });

    ensureSpecialWordbooks();
    await syncBuiltInWordbooksCatalog();
  }

  void dispose() {
    if (!_initialized) return;
    _db.dispose();
    _initialized = false;
  }

  void _createTables() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS wordbooks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        path TEXT UNIQUE,
        word_count INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        wordbook_id INTEGER NOT NULL,
        word TEXT NOT NULL,
        meaning TEXT,
        examples TEXT,
        etymology TEXT,
        roots TEXT,
        affixes TEXT,
        variations TEXT,
        memory TEXT,
        story TEXT,
        fields_json TEXT,
        raw_content TEXT,
        FOREIGN KEY (wordbook_id) REFERENCES wordbooks(id) ON DELETE CASCADE
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS user_marks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id INTEGER NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('new', 'important', 'mastered')),
        note TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE,
        UNIQUE(word_id, type)
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id INTEGER NOT NULL,
        times_played INTEGER DEFAULT 0,
        times_correct INTEGER DEFAULT 0,
        last_played DATETIME,
        familiarity REAL DEFAULT 0,
        FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE,
        UNIQUE(word_id)
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_words_wordbook ON words(wordbook_id);',
    );
    _db.execute('CREATE INDEX IF NOT EXISTS idx_words_word ON words(word);');
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_marks_word ON user_marks(word_id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_progress_word ON progress(word_id);',
    );
  }

  void _migrateWordsSchema() {
    final tableInfo = _db.select('PRAGMA table_info(words);');
    final columnNames = <String>{
      for (final row in tableInfo) row['name'].toString(),
    };
    if (!columnNames.contains('fields_json')) {
      _db.execute('ALTER TABLE words ADD COLUMN fields_json TEXT;');
    }
    if (!columnNames.contains('raw_content')) {
      _db.execute('ALTER TABLE words ADD COLUMN raw_content TEXT;');
    }
  }

  void ensureSpecialWordbooks() {
    for (final entry in _specialWordbooks.entries) {
      final existing = _selectOne(
        'SELECT id FROM wordbooks WHERE path = ?',
        <Object?>[entry.key],
      );
      if (existing != null) continue;
      _db.execute(
        'INSERT INTO wordbooks (name, path, word_count) VALUES (?, ?, 0)',
        <Object?>[entry.value, entry.key],
      );
    }
  }

  Future<void> syncBuiltInWordbooksCatalog() async {
    final builtins = await _resolveBuiltInWordbooks();
    if (builtins.isEmpty) return;
    _removeObsoleteBuiltInWordbooks(builtins.map((item) => item.path).toSet());
    var created = 0;
    var renamed = 0;
    for (final builtin in builtins) {
      final existing = _selectOne(
        'SELECT id, name, word_count FROM wordbooks WHERE path = ?',
        <Object?>[builtin.path],
      );

      if (existing == null) {
        _db.execute(
          'INSERT INTO wordbooks (name, path, word_count) VALUES (?, ?, 0)',
          <Object?>[builtin.name, builtin.path],
        );
        created += 1;
        continue;
      }

      final currentName = existing['name']?.toString().trim() ?? '';
      if (currentName == builtin.name) continue;
      _db.execute('UPDATE wordbooks SET name = ? WHERE path = ?', <Object?>[
        builtin.name,
        builtin.path,
      ]);
      renamed += 1;
    }
    _log.i(
      'database',
      'built-in wordbook catalog synced',
      data: <String, Object?>{
        'count': builtins.length,
        'created': created,
        'renamed': renamed,
      },
    );
  }

  bool isLazyBuiltInPath(String path) =>
      path.startsWith(_dictBuiltinPathPrefix);

  Future<int> ensureBuiltInWordbookLoaded(String path) async {
    if (!isLazyBuiltInPath(path)) return 0;

    final builtins = await _resolveBuiltInWordbooks();
    _BuiltInWordbookConfig? target;
    for (final builtin in builtins) {
      if (builtin.path == path) {
        target = builtin;
        break;
      }
    }

    if (target == null) {
      throw StateError('Built-in wordbook asset missing: $path');
    }

    final existing = _selectOne(
      'SELECT word_count FROM wordbooks WHERE path = ?',
      <Object?>[path],
    );
    if (existing == null) {
      _db.execute(
        'INSERT INTO wordbooks (name, path, word_count) VALUES (?, ?, 0)',
        <Object?>[target.name, target.path],
      );
    } else if (((existing['word_count'] as num?) ?? 0).toInt() > 0) {
      return ((existing['word_count'] as num?) ?? 0).toInt();
    }

    _log.i(
      'database',
      'loading built-in wordbook on demand',
      data: <String, Object?>{'path': path, 'assetPath': target.assetPath},
    );
    final content = await rootBundle.loadString(target.assetPath);
    final entries = _importService.parseJsonText(content);
    final imported = await importWordbook(
      sourcePath: target.path,
      name: target.name,
      entries: entries,
      replaceExisting: true,
    );
    _log.i(
      'database',
      'built-in wordbook loaded',
      data: <String, Object?>{
        'path': path,
        'assetPath': target.assetPath,
        'count': imported,
      },
    );
    return imported;
  }

  List<Wordbook> getWordbooks() {
    final rows = _selectMaps('''
      SELECT * FROM wordbooks
      ORDER BY
        CASE
          WHEN path = 'builtin:task' THEN 0
          WHEN path = 'builtin:favorites' THEN 1
          WHEN path LIKE 'builtin:dict:%' THEN 2
          WHEN path LIKE 'builtin:%' THEN 3
          ELSE 4
        END,
        CASE
          WHEN path LIKE 'builtin:dict:%' THEN name
          ELSE ''
        END COLLATE NOCASE ASC,
        id DESC
    ''');
    return rows.map(Wordbook.fromMap).toList();
  }

  Wordbook? getSpecialWordbook(String type) {
    final path = type == 'favorites' ? 'builtin:favorites' : 'builtin:task';
    final row = _selectOne(
      'SELECT id, name, path, word_count, created_at FROM wordbooks WHERE path = ?',
      <Object?>[path],
    );
    if (row == null) return null;
    return Wordbook.fromMap(row);
  }

  List<WordEntry> getWords(
    int wordbookId, {
    int limit = 100000,
    int offset = 0,
  }) {
    final rows = _selectMaps(
      'SELECT * FROM words WHERE wordbook_id = ? LIMIT ? OFFSET ?',
      <Object?>[wordbookId, limit, offset],
    );
    return rows.map(WordEntry.fromMap).toList();
  }

  Future<int> importWordbook({
    required String sourcePath,
    required String name,
    required List<WordEntryPayload> entries,
    bool replaceExisting = true,
  }) async {
    return _runInTransaction<int>(() {
      var wordbookId = 0;
      final existing = _selectOne(
        'SELECT id FROM wordbooks WHERE path = ?',
        <Object?>[sourcePath],
      );
      if (existing != null) {
        wordbookId = (existing['id'] as num).toInt();
        if (replaceExisting) {
          _db.execute('DELETE FROM words WHERE wordbook_id = ?', <Object?>[
            wordbookId,
          ]);
        }
      } else {
        _db.execute(
          'INSERT INTO wordbooks (name, path, word_count) VALUES (?, ?, 0)',
          <Object?>[name, sourcePath],
        );
        wordbookId = _lastInsertId();
      }

      var count = 0;
      for (final entry in entries) {
        if (entry.word.trim().isEmpty) continue;
        _insertWord(wordbookId, entry);
        count += 1;
      }

      _refreshWordbookCount(wordbookId);
      return count;
    });
  }

  int createWordbook(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('单词本名称不能为空');
    _db.execute(
      'INSERT INTO wordbooks (name, path, word_count) VALUES (?, ?, 0)',
      <Object?>[trimmed, 'custom_${DateTime.now().millisecondsSinceEpoch}'],
    );
    return _lastInsertId();
  }

  void renameWordbook(int wordbookId, String newName) {
    final wordbook = _selectOne(
      'SELECT path FROM wordbooks WHERE id = ?',
      <Object?>[wordbookId],
    );
    if (wordbook == null) throw StateError('单词本不存在');
    final path = wordbook['path']?.toString() ?? '';
    if (_isBuiltInPath(path)) throw StateError('系统单词本不允许重命名');

    final trimmed = newName.trim();
    if (trimmed.isEmpty) throw ArgumentError('名称不能为空');
    _db.execute('UPDATE wordbooks SET name = ? WHERE id = ?', <Object?>[
      trimmed,
      wordbookId,
    ]);
  }

  void deleteWordbook(int wordbookId) {
    final wordbook = _selectOne(
      'SELECT path FROM wordbooks WHERE id = ?',
      <Object?>[wordbookId],
    );
    if (wordbook == null) throw StateError('单词本不存在');
    final path = wordbook['path']?.toString() ?? '';
    if (_isBuiltInPath(path)) throw StateError('系统单词本不允许删除');

    _db.execute('DELETE FROM words WHERE wordbook_id = ?', <Object?>[
      wordbookId,
    ]);
    _db.execute('DELETE FROM wordbooks WHERE id = ?', <Object?>[wordbookId]);
  }

  bool upsertWord(
    int wordbookId,
    WordEntryPayload payload, {
    bool refreshWordbookCount = true,
  }) {
    final word = payload.word.trim();
    if (word.isEmpty) throw ArgumentError('单词不能为空');

    final existing = _selectOne(
      'SELECT id, fields_json, raw_content FROM words WHERE wordbook_id = ? AND word = ?',
      <Object?>[wordbookId, word],
    );

    if (existing == null) {
      _insertWord(wordbookId, payload.copyWith(word: word));
      if (refreshWordbookCount) {
        _refreshWordbookCount(wordbookId);
      }
      return true;
    }

    final existingFields = parseFieldItemsJson(
      existing['fields_json']?.toString() ?? '',
    );
    final incomingRawContent = sanitizeDisplayText(payload.rawContent);
    final normalizedRawContent = incomingRawContent.isNotEmpty
        ? incomingRawContent
        : sanitizeDisplayText(existing['raw_content']?.toString() ?? '');
    final normalizedFields = mergeFieldItems(<WordFieldItem>[
      ...existingFields,
      ...payload.fields,
      if (normalizedRawContent.isNotEmpty)
        ...parseSectionedContent(normalizedRawContent),
    ]);
    final legacy = toLegacyFields(normalizedFields);

    _db.execute(
      '''
      UPDATE words SET
        meaning = ?, examples = ?, etymology = ?, roots = ?,
        affixes = ?, variations = ?, memory = ?, story = ?,
        fields_json = ?, raw_content = ?
      WHERE id = ?
      ''',
      <Object?>[
        legacy.meaning,
        legacy.examples == null ? null : jsonEncode(legacy.examples),
        legacy.etymology,
        legacy.roots,
        legacy.affixes,
        legacy.variations,
        legacy.memory,
        legacy.story,
        stringifyFieldItems(normalizedFields),
        normalizedRawContent,
        (existing['id'] as num).toInt(),
      ],
    );
    if (refreshWordbookCount) {
      _refreshWordbookCount(wordbookId);
    }
    return false;
  }

  void addWord(int wordbookId, WordEntryPayload payload) {
    final existing = _selectOne(
      'SELECT id FROM words WHERE wordbook_id = ? AND word = ?',
      <Object?>[wordbookId, payload.word.trim()],
    );
    if (existing != null) throw StateError('该单词已存在');
    upsertWord(wordbookId, payload);
  }

  void updateWord({
    required int wordbookId,
    required String sourceWord,
    required WordEntryPayload payload,
  }) {
    final oldWord = sourceWord.trim();
    final nextWord = payload.word.trim().isEmpty
        ? oldWord
        : payload.word.trim();
    if (oldWord.isEmpty || nextWord.isEmpty) throw ArgumentError('单词不能为空');

    final existing = _selectOne(
      'SELECT id, fields_json, raw_content FROM words WHERE wordbook_id = ? AND word = ?',
      <Object?>[wordbookId, oldWord],
    );
    if (existing == null) throw StateError('单词不存在');

    if (oldWord != nextWord) {
      final conflict = _selectOne(
        'SELECT id FROM words WHERE wordbook_id = ? AND word = ?',
        <Object?>[wordbookId, nextWord],
      );
      if (conflict != null) throw StateError('目标单词已存在');
    }

    final existingFields = parseFieldItemsJson(
      existing['fields_json']?.toString() ?? '',
    );
    final incomingRawContent = sanitizeDisplayText(payload.rawContent);
    final normalizedRawContent = incomingRawContent.isNotEmpty
        ? incomingRawContent
        : sanitizeDisplayText(existing['raw_content']?.toString() ?? '');
    final normalizedFields = mergeFieldItems(<WordFieldItem>[
      ...existingFields,
      ...payload.fields,
      if (normalizedRawContent.isNotEmpty)
        ...parseSectionedContent(normalizedRawContent),
    ]);
    final legacy = toLegacyFields(normalizedFields);

    _db.execute(
      '''
      UPDATE words SET
        word = ?, meaning = ?, examples = ?, etymology = ?, roots = ?,
        affixes = ?, variations = ?, memory = ?, story = ?, fields_json = ?, raw_content = ?
      WHERE id = ?
      ''',
      <Object?>[
        nextWord,
        legacy.meaning,
        legacy.examples == null ? null : jsonEncode(legacy.examples),
        legacy.etymology,
        legacy.roots,
        legacy.affixes,
        legacy.variations,
        legacy.memory,
        legacy.story,
        stringifyFieldItems(normalizedFields),
        normalizedRawContent,
        (existing['id'] as num).toInt(),
      ],
    );

    _refreshWordbookCount(wordbookId);
  }

  void deleteWord(int wordbookId, String word) {
    _db.execute(
      'DELETE FROM words WHERE wordbook_id = ? AND word = ?',
      <Object?>[wordbookId, word],
    );
    _refreshWordbookCount(wordbookId);
  }

  void clearWordbook(int wordbookId) {
    _db.execute('DELETE FROM words WHERE wordbook_id = ?', <Object?>[
      wordbookId,
    ]);
    _refreshWordbookCount(wordbookId);
  }

  int exportWordbook(int sourceWordbookId, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('名称不能为空');
    return _runInTransaction<int>(() {
      _db.execute(
        'INSERT INTO wordbooks (name, path, word_count) VALUES (?, ?, 0)',
        <Object?>[trimmed, 'export_${DateTime.now().millisecondsSinceEpoch}'],
      );
      final insertedId = _lastInsertId();
      _db.execute(
        '''
        INSERT INTO words (wordbook_id, word, meaning, examples, etymology, roots, affixes, variations, memory, story, fields_json, raw_content)
        SELECT ?, word, meaning, examples, etymology, roots, affixes, variations, memory, story, fields_json, raw_content
        FROM words WHERE wordbook_id = ?
        ''',
        <Object?>[insertedId, sourceWordbookId],
      );
      _refreshWordbookCount(insertedId);
      return insertedId;
    });
  }

  WordbookMergeResult mergeWordbooks({
    required int sourceWordbookId,
    required int targetWordbookId,
    required bool deleteSourceAfterMerge,
  }) {
    if (sourceWordbookId == targetWordbookId) {
      throw StateError('源单词本和目标单词本不能相同');
    }

    final sourceWordbook = _selectOne(
      'SELECT id, path FROM wordbooks WHERE id = ?',
      <Object?>[sourceWordbookId],
    );
    final targetWordbook = _selectOne(
      'SELECT id FROM wordbooks WHERE id = ?',
      <Object?>[targetWordbookId],
    );
    if (sourceWordbook == null || targetWordbook == null) {
      throw StateError('单词本不存在');
    }

    final sourceWords = _selectMaps(
      'SELECT * FROM words WHERE wordbook_id = ?',
      <Object?>[sourceWordbookId],
    );
    var inserted = 0;
    var updated = 0;

    _runInTransaction<void>(() {
      for (final row in sourceWords) {
        final entry = WordEntry.fromMap(row);
        final added = upsertWord(
          targetWordbookId,
          entry.toPayload(),
          refreshWordbookCount: false,
        );
        if (added) {
          inserted += 1;
        } else {
          updated += 1;
        }
      }

      if (deleteSourceAfterMerge) {
        final sourcePath = sourceWordbook['path']?.toString() ?? '';
        if (_isBuiltInPath(sourcePath)) {
          throw StateError('系统单词本不允许在合并后删除');
        }
        _db.execute('DELETE FROM words WHERE wordbook_id = ?', <Object?>[
          sourceWordbookId,
        ]);
        _db.execute('DELETE FROM wordbooks WHERE id = ?', <Object?>[
          sourceWordbookId,
        ]);
      } else {
        _refreshWordbookCount(sourceWordbookId);
      }

      _refreshWordbookCount(targetWordbookId);
    });

    return WordbookMergeResult(
      total: sourceWords.length,
      inserted: inserted,
      updated: updated,
      sourceWordbookId: sourceWordbookId,
      targetWordbookId: targetWordbookId,
      deleteSourceAfterMerge: deleteSourceAfterMerge,
    );
  }

  String? getSetting(String key) {
    final row = _selectOne(
      'SELECT value FROM settings WHERE key = ?',
      <Object?>[key],
    );
    return row?['value']?.toString();
  }

  void setSetting(String key, String value) {
    _db.execute(
      'INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)',
      <Object?>[key, value],
    );
  }

  Future<int> importWordbookFile({
    required String filePath,
    required String name,
  }) async {
    final entries = await _importService.parseFile(filePath);
    return importWordbook(
      sourcePath: filePath,
      name: name,
      entries: entries,
      replaceExisting: true,
    );
  }

  Future<int> importLegacyDatabase(String legacyDbPath) async {
    final legacyFile = File(legacyDbPath);
    if (!await legacyFile.exists()) {
      throw FileSystemException('数据库文件不存在', legacyDbPath);
    }

    final legacyDb = sqlite3.open(legacyDbPath);
    try {
      final legacyWordbooks = _rowsAsMaps(
        legacyDb.select('SELECT * FROM wordbooks'),
      );
      final legacyWords = _rowsAsMaps(legacyDb.select('SELECT * FROM words'));

      _runInTransaction<void>(() {
        _db.execute('DELETE FROM words;');
        _db.execute('DELETE FROM wordbooks;');

        for (final wb in legacyWordbooks) {
          _db.execute(
            '''
            INSERT INTO wordbooks (id, name, path, word_count, created_at)
            VALUES (?, ?, ?, ?, ?)
            ''',
            <Object?>[
              wb['id'],
              wb['name'],
              wb['path'],
              wb['word_count'],
              wb['created_at'],
            ],
          );
        }

        for (final word in legacyWords) {
          _db.execute(
            '''
            INSERT INTO words (id, wordbook_id, word, meaning, examples, etymology, roots, affixes, variations, memory, story, fields_json, raw_content)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            <Object?>[
              word['id'],
              word['wordbook_id'],
              word['word'],
              word['meaning'],
              word['examples'],
              word['etymology'],
              word['roots'],
              word['affixes'],
              word['variations'],
              word['memory'],
              word['story'],
              word['fields_json'],
              word['raw_content'],
            ],
          );
        }

        _db.execute('''
          UPDATE wordbooks
          SET word_count = (
            SELECT COUNT(*)
            FROM words
            WHERE words.wordbook_id = wordbooks.id
          );
          ''');
      });
      ensureSpecialWordbooks();
      await syncBuiltInWordbooksCatalog();
      return legacyWords.length;
    } finally {
      legacyDb.dispose();
    }
  }

  Future<List<_BuiltInWordbookConfig>> _resolveBuiltInWordbooks() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets =
          manifest
              .listAssets()
              .where(
                (path) =>
                    path.startsWith(_dictAssetPrefix) &&
                    path.toLowerCase().endsWith('.json'),
              )
              .toList(growable: false)
            ..sort();

      return assets.map(_buildBuiltInConfigFromAsset).toList(growable: false);
    } catch (_) {
      return const <_BuiltInWordbookConfig>[];
    }
  }

  _BuiltInWordbookConfig _buildBuiltInConfigFromAsset(String assetPath) {
    final filename = p.basenameWithoutExtension(assetPath).trim();
    final baseName = filename.isEmpty ? 'dict' : filename;
    return _BuiltInWordbookConfig(
      path: '$_dictBuiltinPathPrefix$baseName',
      name: baseName,
      assetPath: assetPath,
    );
  }

  void _removeObsoleteBuiltInWordbooks(Set<String> targetBuiltinPaths) {
    final rows = _selectMaps(
      'SELECT id, path FROM wordbooks WHERE path LIKE ?;',
      <Object?>['builtin:%'],
    );
    for (final row in rows) {
      final path = row['path']?.toString() ?? '';
      if (_specialWordbooks.containsKey(path)) continue;
      if (targetBuiltinPaths.contains(path)) continue;
      final wordbookId = (row['id'] as num?)?.toInt();
      if (wordbookId == null) continue;
      _db.execute('DELETE FROM words WHERE wordbook_id = ?', <Object?>[
        wordbookId,
      ]);
      _db.execute('DELETE FROM wordbooks WHERE id = ?', <Object?>[wordbookId]);
    }
  }

  T _runInTransaction<T>(T Function() action) {
    final depth = _transactionDepth;
    final savepoint = 'sp_tx_$depth';
    if (depth == 0) {
      _db.execute('BEGIN TRANSACTION;');
    } else {
      _db.execute('SAVEPOINT $savepoint;');
    }
    _transactionDepth += 1;

    try {
      final result = action();
      _transactionDepth -= 1;
      if (depth == 0) {
        _db.execute('COMMIT;');
      } else {
        _db.execute('RELEASE SAVEPOINT $savepoint;');
      }
      return result;
    } catch (_) {
      _transactionDepth -= 1;
      if (depth == 0) {
        _db.execute('ROLLBACK;');
      } else {
        _db.execute('ROLLBACK TO SAVEPOINT $savepoint;');
        _db.execute('RELEASE SAVEPOINT $savepoint;');
      }
      rethrow;
    }
  }

  void _insertWord(int wordbookId, WordEntryPayload payload) {
    final normalizedWord = sanitizeDisplayText(payload.word).trim();
    final normalizedRawContent = sanitizeDisplayText(payload.rawContent);

    final fields = mergeFieldItems(<WordFieldItem>[
      ...payload.fields,
      if (normalizedRawContent.isNotEmpty)
        ...parseSectionedContent(normalizedRawContent),
    ]);
    final legacy = toLegacyFields(fields);
    final rawContent = normalizedRawContent.isNotEmpty
        ? normalizedRawContent
        : (legacy.meaning ?? '');

    _db.execute(
      '''
      INSERT INTO words (wordbook_id, word, meaning, examples, etymology, roots, affixes, variations, memory, story, fields_json, raw_content)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      <Object?>[
        wordbookId,
        normalizedWord,
        legacy.meaning,
        legacy.examples == null ? null : jsonEncode(legacy.examples),
        legacy.etymology,
        legacy.roots,
        legacy.affixes,
        legacy.variations,
        legacy.memory,
        legacy.story,
        stringifyFieldItems(fields),
        rawContent,
      ],
    );
  }

  void _refreshWordbookCount(int wordbookId) {
    final row = _selectOne(
      'SELECT COUNT(*) AS count FROM words WHERE wordbook_id = ?',
      <Object?>[wordbookId],
    );
    final count = ((row?['count'] as num?) ?? 0).toInt();
    _db.execute('UPDATE wordbooks SET word_count = ? WHERE id = ?', <Object?>[
      count,
      wordbookId,
    ]);
  }

  bool _isBuiltInPath(String path) => path.startsWith('builtin:');

  int _lastInsertId() {
    final row = _db.select('SELECT last_insert_rowid() AS id');
    if (row.isEmpty) {
      throw StateError('无法获取插入 ID');
    }
    return (row.first['id'] as num).toInt();
  }

  List<Map<String, Object?>> _selectMaps(
    String sql, [
    List<Object?> params = const <Object?>[],
  ]) {
    return _rowsAsMaps(_db.select(sql, params));
  }

  Map<String, Object?>? _selectOne(
    String sql, [
    List<Object?> params = const <Object?>[],
  ]) {
    final rows = _selectMaps(sql, params);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  List<Map<String, Object?>> _rowsAsMaps(ResultSet resultSet) {
    final maps = <Map<String, Object?>>[];
    for (final row in resultSet) {
      final map = <String, Object?>{};
      for (var i = 0; i < resultSet.columnNames.length; i++) {
        final columnName = resultSet.columnNames[i];
        map[columnName] = row[columnName];
      }
      maps.add(map);
    }
    return maps;
  }
}

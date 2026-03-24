import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../models/todo_item.dart';
import '../models/tomato_timer.dart';
import '../models/user_data_export.dart';
import '../models/word_entry.dart';
import '../models/word_field.dart';
import '../models/word_memory_progress.dart';
import '../models/wordbook.dart';
import '../models/export_dto.dart';
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

class DatabaseBackupInfo {
  const DatabaseBackupInfo({
    required this.name,
    required this.path,
    required this.reason,
    required this.modifiedAt,
    required this.sizeBytes,
  });

  final String name;
  final String path;
  final String reason;
  final DateTime modifiedAt;
  final int sizeBytes;

  String get reasonLabel {
    final normalized = reason.trim().replaceAll('_', ' ');
    return normalized.isEmpty ? 'manual' : normalized;
  }
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

class _PreparedWordRecord {
  const _PreparedWordRecord({required this.row, required this.fields});

  final Map<String, Object?> row;
  final List<WordFieldItem> fields;
}

class AppDatabaseService {
  AppDatabaseService(this._importService);

  final WordbookImportService _importService;
  final AppLogService _log = AppLogService.instance;

  late Database _db;
  late final String dbPath;
  bool _initialized = false;
  int _transactionDepth = 0;

  static const _specialWordbooks = <String, String>{
    'builtin:favorites': 'Favorites',
    'builtin:task': 'Task',
  };
  static const String _dictAssetPrefix = 'dict/';
  static const String _dictBuiltinPathPrefix = 'builtin:dict:';
  static const String _hiddenBuiltInWordbooksSettingKey =
      'hidden_built_in_wordbooks';
  static final RegExp _backupFilePattern = RegExp(
    r'^vocabulary_(.+)_(\d{4}-\d{2}-\d{2}T.+)\.db$',
  );
  static final RegExp _windowsReservedFileNamePattern = RegExp(
    r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)',
    caseSensitive: false,
  );

  Future<void> init() async {
    if (_initialized) return;
    final supportDir = await getApplicationSupportDirectory();
    if (!await supportDir.exists()) {
      await supportDir.create(recursive: true);
    }
    dbPath = p.join(supportDir.path, 'vocabulary.db');
    _openDatabase();
    await _prepareDatabase();
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

    final backupDir = await _ensureBackupDirectory();

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
    final targetFile = File(targetPath);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }

    _db.execute('PRAGMA wal_checkpoint(FULL);');
    _db.execute("VACUUM INTO '${_escapeSqlString(targetPath)}';");
    return targetPath;
  }

  Future<List<DatabaseBackupInfo>> listSafetyBackups({int limit = 20}) async {
    final backupDir = await _ensureBackupDirectory();
    if (!await backupDir.exists()) {
      return const <DatabaseBackupInfo>[];
    }

    final infos = <DatabaseBackupInfo>[];
    await for (final entity in backupDir.list(followLinks: false)) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.db')) {
        continue;
      }
      final stat = await entity.stat();
      final filename = p.basename(entity.path);
      infos.add(
        DatabaseBackupInfo(
          name: filename,
          path: entity.path,
          reason: _parseBackupReason(filename),
          modifiedAt: stat.modified,
          sizeBytes: stat.size,
        ),
      );
    }

    infos.sort((left, right) => right.modifiedAt.compareTo(left.modifiedAt));
    if (limit > 0 && infos.length > limit) {
      return infos.take(limit).toList(growable: false);
    }
    return infos;
  }

  Future<void> deleteSafetyBackup(String backupPath) async {
    final backupDir = await _ensureBackupDirectory();
    final file = File(backupPath);
    if (!await file.exists()) {
      throw FileSystemException('Backup file does not exist', backupPath);
    }

    final normalizedBackupDir = p.normalize(backupDir.path);
    final normalizedTarget = p.normalize(file.path);
    if (!p.isWithin(normalizedBackupDir, normalizedTarget) &&
        normalizedBackupDir != normalizedTarget) {
      throw FileSystemException(
        'Backup file is outside the backup directory',
        backupPath,
      );
    }

    await file.delete();
  }

  Future<String> exportUserData({
    Iterable<UserDataExportSection>? sections,
    String? directoryPath,
    String? fileName,
  }) async {
    if (!_initialized) {
      throw StateError('Database is not initialized');
    }

    final resolvedSections = _resolveUserDataExportSections(sections);
    final exportDir = (directoryPath ?? '').trim().isEmpty
        ? await _ensureExportDirectory()
        : Directory(directoryPath!.trim());
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final exportPath = p.join(
      exportDir.path,
      _normalizeUserDataExportFileName(fileName),
    );
    final payload = buildUserDataExportPayload(sections: resolvedSections);

    await File(exportPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload.toJsonMap()),
      flush: true,
    );
    return exportPath;
  }

  Future<String> writeTextExport({
    required String contents,
    required String defaultFileStem,
    required String extension,
    String? directoryPath,
    String? fileName,
  }) async {
    final exportDir = (directoryPath ?? '').trim().isEmpty
        ? await _ensureExportDirectory()
        : Directory(directoryPath!.trim());
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final exportPath = p.join(
      exportDir.path,
      _normalizeExportFileName(
        rawFileName: fileName,
        defaultFileStem: defaultFileStem,
        extension: extension,
      ),
    );
    await File(exportPath).writeAsString(contents, flush: true);
    return exportPath;
  }

  UserDataExportPayload buildUserDataExportPayload({
    Iterable<UserDataExportSection>? sections,
  }) {
    if (!_initialized) {
      throw StateError('Database is not initialized');
    }

    final resolvedSections = _resolveUserDataExportSections(sections);
    return UserDataExportPayload(
      exportedAt: DateTime.now(),
      sections: resolvedSections
          .map((section) => section.storageKey)
          .toList(growable: false),
      wordbooks: resolvedSections.contains(UserDataExportSection.wordbooks)
          ? _buildWordbooksExportPayload()
          : const <UserDataExportWordbook>[],
      todos: resolvedSections.contains(UserDataExportSection.todos)
          ? getTodos()
          : const <TodoItem>[],
      notes: resolvedSections.contains(UserDataExportSection.notes)
          ? getNotes()
          : const <PlanNote>[],
      progress: resolvedSections.contains(UserDataExportSection.progress)
          ? _selectMaps(
              'SELECT * FROM progress ORDER BY word_id ASC',
            ).map(WordMemoryProgress.fromMap).toList(growable: false)
          : const <WordMemoryProgress>[],
      timerRecords:
          resolvedSections.contains(UserDataExportSection.timerRecords)
          ? getTimerRecords(limit: 100000)
          : const <TomatoTimerRecord>[],
      settings: resolvedSections.contains(UserDataExportSection.settings)
          ? _buildSettingsExportPayload()
          : const <String, String>{},
    );
  }

  Future<String> getDefaultUserDataExportDirectoryPath() async {
    final exportDir = await _ensureExportDirectory();
    return exportDir.path;
  }

  Future<void> restoreSafetyBackup(String backupPath) async {
    if (!_initialized) {
      throw StateError('Database is not initialized');
    }

    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      throw FileSystemException('Backup file does not exist', backupPath);
    }

    final currentDb = File(dbPath);
    final rollbackPath = '$dbPath.restore_previous';
    final rollbackDb = File(rollbackPath);
    final walFile = File('$dbPath-wal');
    final shmFile = File('$dbPath-shm');
    final rollbackWal = File('$rollbackPath-wal');
    final rollbackShm = File('$rollbackPath-shm');
    var reopenedRestoredDatabase = false;

    _db.execute('PRAGMA wal_checkpoint(FULL);');
    _db.dispose();

    try {
      if (await rollbackDb.exists()) {
        await rollbackDb.delete();
      }
      if (await rollbackWal.exists()) {
        await rollbackWal.delete();
      }
      if (await rollbackShm.exists()) {
        await rollbackShm.delete();
      }
      if (await walFile.exists()) {
        await walFile.delete();
      }
      if (await shmFile.exists()) {
        await shmFile.delete();
      }
      if (await currentDb.exists()) {
        await currentDb.rename(rollbackPath);
      }

      await backupFile.copy(dbPath);
      _openDatabase();
      reopenedRestoredDatabase = true;
      await _prepareDatabase();

      if (await rollbackDb.exists()) {
        await rollbackDb.delete();
      }
      if (await rollbackWal.exists()) {
        await rollbackWal.delete();
      }
      if (await rollbackShm.exists()) {
        await rollbackShm.delete();
      }
    } catch (_) {
      if (reopenedRestoredDatabase) {
        try {
          _db.dispose();
        } catch (_) {}
      }

      final restoredDb = File(dbPath);
      if (await restoredDb.exists()) {
        await restoredDb.delete();
      }
      if (await walFile.exists()) {
        await walFile.delete();
      }
      if (await shmFile.exists()) {
        await shmFile.delete();
      }
      if (await rollbackDb.exists()) {
        await rollbackDb.rename(dbPath);
      }

      _openDatabase();
      await _prepareDatabase();
      rethrow;
    }
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
        entry_json TEXT,
        FOREIGN KEY (wordbook_id) REFERENCES wordbooks(id) ON DELETE CASCADE
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS word_fields (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id INTEGER NOT NULL,
        field_key TEXT NOT NULL,
        field_label TEXT NOT NULL,
        field_value_json TEXT NOT NULL,
        style_json TEXT,
        sort_order INTEGER DEFAULT 0,
        FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE
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
        ease_factor REAL DEFAULT 2.5,
        interval_days INTEGER DEFAULT 0,
        next_review DATETIME,
        consecutive_correct INTEGER DEFAULT 0,
        memory_state TEXT DEFAULT 'new',
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

    _db.execute('''
      CREATE TABLE IF NOT EXISTS todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        completed INTEGER DEFAULT 0,
        deferred INTEGER DEFAULT 0,
        priority INTEGER DEFAULT 0,
        category TEXT,
        note TEXT,
        color TEXT,
        sort_order INTEGER DEFAULT 0,
        due_at DATETIME,
        alarm_enabled INTEGER DEFAULT 0,
        sync_to_system_calendar INTEGER DEFAULT 1,
        system_calendar_notification_enabled INTEGER DEFAULT 1,
        system_calendar_notification_minutes_before INTEGER DEFAULT 0,
        system_calendar_alarm_enabled INTEGER DEFAULT 0,
        system_calendar_alarm_minutes_before INTEGER DEFAULT 10,
        created_at DATETIME,
        completed_at DATETIME
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT,
        color TEXT,
        sort_order INTEGER DEFAULT 0,
        created_at DATETIME,
        updated_at DATETIME
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS timer_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time DATETIME NOT NULL,
        duration_minutes INTEGER DEFAULT 0,
        focus_duration_minutes INTEGER DEFAULT 0,
        break_duration_minutes INTEGER DEFAULT 0,
        rounds_completed INTEGER DEFAULT 0,
        focus_minutes INTEGER DEFAULT 25,
        break_minutes INTEGER DEFAULT 5,
        is_partial INTEGER DEFAULT 0
      );
    ''');

    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_words_wordbook ON words(wordbook_id);',
    );
    _db.execute('CREATE INDEX IF NOT EXISTS idx_words_word ON words(word);');
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_word_fields_word ON word_fields(word_id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_word_fields_key ON word_fields(field_key);',
    );
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
    if (!columnNames.contains('entry_json')) {
      _db.execute('ALTER TABLE words ADD COLUMN entry_json TEXT;');
    }
    _backfillWordEntryJson();
  }

  void _migrateWordFieldsSchema() {
    final rowsWithoutFields = _selectMaps('''
      SELECT w.*
      FROM words w
      LEFT JOIN (
        SELECT word_id, COUNT(*) AS field_count
        FROM word_fields
        GROUP BY word_id
      ) wf ON wf.word_id = w.id
      WHERE COALESCE(wf.field_count, 0) = 0
      ''');
    if (rowsWithoutFields.isEmpty) {
      return;
    }
    for (final row in rowsWithoutFields) {
      final wordId = (row['id'] as num?)?.toInt();
      if (wordId == null || wordId <= 0) {
        continue;
      }
      final entry = WordEntry.fromMap(row);
      _replaceWordFields(wordId, entry.fields);
    }
  }

  void _backfillWordEntryJson() {
    final rows = _selectMaps('''
      SELECT * FROM words
      WHERE entry_json IS NULL OR TRIM(entry_json) = ''
      ''');
    if (rows.isEmpty) {
      return;
    }
    for (final row in rows) {
      final wordId = (row['id'] as num?)?.toInt();
      if (wordId == null || wordId <= 0) {
        continue;
      }
      final entry = WordEntry.fromMap(row);
      _db.execute('UPDATE words SET entry_json = ? WHERE id = ?', <Object?>[
        jsonEncode(entry.toJsonMap()),
        wordId,
      ]);
    }
  }

  void _migrateTimerRecordsSchema() {
    final tableInfo = _db.select('PRAGMA table_info(timer_records);');
    final columnNames = <String>{
      for (final row in tableInfo) row['name'].toString(),
    };

    if (!columnNames.contains('focus_duration_minutes')) {
      _db.execute(
        'ALTER TABLE timer_records ADD COLUMN focus_duration_minutes INTEGER DEFAULT 0;',
      );
      _db.execute('''
        UPDATE timer_records
        SET focus_duration_minutes = COALESCE(rounds_completed, 0) * COALESCE(focus_minutes, 25)
        WHERE COALESCE(focus_duration_minutes, 0) = 0;
      ''');
    }
    if (!columnNames.contains('break_duration_minutes')) {
      _db.execute(
        'ALTER TABLE timer_records ADD COLUMN break_duration_minutes INTEGER DEFAULT 0;',
      );
      _db.execute('''
        UPDATE timer_records
        SET break_duration_minutes =
          CASE
            WHEN duration_minutes - COALESCE(focus_duration_minutes, COALESCE(rounds_completed, 0) * COALESCE(focus_minutes, 25)) > 0
              THEN duration_minutes - COALESCE(focus_duration_minutes, COALESCE(rounds_completed, 0) * COALESCE(focus_minutes, 25))
            ELSE 0
          END
        WHERE COALESCE(break_duration_minutes, 0) = 0;
      ''');
    }
    if (!columnNames.contains('is_partial')) {
      _db.execute(
        'ALTER TABLE timer_records ADD COLUMN is_partial INTEGER DEFAULT 0;',
      );
    }
  }

  void _migrateProgressSchema() {
    final tableInfo = _db.select('PRAGMA table_info(progress);');
    final columnNames = <String>{
      for (final row in tableInfo) row['name'].toString(),
    };

    if (!columnNames.contains('ease_factor')) {
      _db.execute(
        'ALTER TABLE progress ADD COLUMN ease_factor REAL DEFAULT 2.5;',
      );
    }
    if (!columnNames.contains('interval_days')) {
      _db.execute(
        'ALTER TABLE progress ADD COLUMN interval_days INTEGER DEFAULT 0;',
      );
    }
    if (!columnNames.contains('next_review')) {
      _db.execute('ALTER TABLE progress ADD COLUMN next_review DATETIME;');
    }
    if (!columnNames.contains('consecutive_correct')) {
      _db.execute(
        'ALTER TABLE progress ADD COLUMN consecutive_correct INTEGER DEFAULT 0;',
      );
    }
    if (!columnNames.contains('memory_state')) {
      _db.execute(
        "ALTER TABLE progress ADD COLUMN memory_state TEXT DEFAULT 'new';",
      );
      _db.execute('''
        UPDATE progress
        SET memory_state =
          CASE
            WHEN COALESCE(times_played, 0) <= 0 THEN 'new'
            WHEN COALESCE(familiarity, 0) >= 0.8 THEN 'mastered'
            WHEN COALESCE(familiarity, 0) >= 0.4 THEN 'familiar'
            ELSE 'learning'
          END;
      ''');
    }
  }

  void _migrateNotesSchema() {
    final tableInfo = _db.select('PRAGMA table_info(notes);');
    final columnNames = <String>{
      for (final row in tableInfo) row['name'].toString(),
    };
    if (!columnNames.contains('sort_order')) {
      _db.execute('ALTER TABLE notes ADD COLUMN sort_order INTEGER DEFAULT 0;');
      final rows = _selectMaps(
        'SELECT id FROM notes ORDER BY updated_at DESC, created_at DESC, id DESC',
      );
      _runInTransaction<void>(() {
        for (var index = 0; index < rows.length; index += 1) {
          _db.execute('UPDATE notes SET sort_order = ? WHERE id = ?', <Object?>[
            index,
            rows[index]['id'],
          ]);
        }
      });
    }
  }

  void _migrateTodosSchema() {
    final tableInfo = _db.select('PRAGMA table_info(todos);');
    final columnNames = <String>{
      for (final row in tableInfo) row['name'].toString(),
    };

    if (!columnNames.contains('category')) {
      _db.execute('ALTER TABLE todos ADD COLUMN category TEXT;');
    }
    if (!columnNames.contains('deferred')) {
      _db.execute('ALTER TABLE todos ADD COLUMN deferred INTEGER DEFAULT 0;');
    }
    if (!columnNames.contains('note')) {
      _db.execute('ALTER TABLE todos ADD COLUMN note TEXT;');
    }
    if (!columnNames.contains('color')) {
      _db.execute('ALTER TABLE todos ADD COLUMN color TEXT;');
    }
    if (!columnNames.contains('due_at')) {
      _db.execute('ALTER TABLE todos ADD COLUMN due_at DATETIME;');
    }
    if (!columnNames.contains('alarm_enabled')) {
      _db.execute(
        'ALTER TABLE todos ADD COLUMN alarm_enabled INTEGER DEFAULT 0;',
      );
    }
    if (!columnNames.contains('sync_to_system_calendar')) {
      _db.execute(
        'ALTER TABLE todos ADD COLUMN sync_to_system_calendar INTEGER DEFAULT 1;',
      );
    }
    if (!columnNames.contains('system_calendar_notification_enabled')) {
      _db.execute(
        'ALTER TABLE todos ADD COLUMN system_calendar_notification_enabled INTEGER DEFAULT 1;',
      );
    }
    if (!columnNames.contains('system_calendar_notification_minutes_before')) {
      _db.execute(
        'ALTER TABLE todos ADD COLUMN system_calendar_notification_minutes_before INTEGER DEFAULT 0;',
      );
    }
    if (!columnNames.contains('system_calendar_alarm_enabled')) {
      _db.execute(
        'ALTER TABLE todos ADD COLUMN system_calendar_alarm_enabled INTEGER DEFAULT 0;',
      );
    }
    if (!columnNames.contains('system_calendar_alarm_minutes_before')) {
      _db.execute(
        'ALTER TABLE todos ADD COLUMN system_calendar_alarm_minutes_before INTEGER DEFAULT 10;',
      );
    }
    if (!columnNames.contains('sort_order')) {
      _db.execute('ALTER TABLE todos ADD COLUMN sort_order INTEGER DEFAULT 0;');
      final rows = _selectMaps(
        'SELECT id FROM todos ORDER BY completed ASC, priority DESC, created_at DESC, id DESC',
      );
      _runInTransaction<void>(() {
        for (var index = 0; index < rows.length; index += 1) {
          _db.execute('UPDATE todos SET sort_order = ? WHERE id = ?', <Object?>[
            index,
            rows[index]['id'],
          ]);
        }
      });
    }

    _db.execute(
      'UPDATE todos SET deferred = 0 WHERE completed = 1 AND COALESCE(deferred, 0) != 0;',
    );
    _db.execute('''
      UPDATE todos
      SET system_calendar_notification_enabled =
        CASE
          WHEN COALESCE(system_calendar_alarm_enabled, 0) = 1 THEN 0
          ELSE 1
        END
      WHERE COALESCE(system_calendar_notification_enabled, 0) =
            COALESCE(system_calendar_alarm_enabled, 0);
    ''');
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
    final builtinPaths = builtins.map((item) => item.path).toSet();
    final hiddenPaths = _hiddenBuiltInWordbookPaths()
      ..removeWhere((path) => !builtinPaths.contains(path));
    _saveHiddenBuiltInWordbookPaths(hiddenPaths);
    final visibleBuiltins = builtins
        .where((item) => !hiddenPaths.contains(item.path))
        .toList(growable: false);

    _removeObsoleteBuiltInWordbooks(
      visibleBuiltins.map((item) => item.path).toSet(),
    );
    var created = 0;
    var renamed = 0;
    for (final builtin in visibleBuiltins) {
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
        'count': visibleBuiltins.length,
        'created': created,
        'hidden': hiddenPaths.length,
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
    final bundleData = await rootBundle.load(target.assetPath);
    final bytes = bundleData.buffer.asUint8List();
    final content = _decodeBuiltInWordbookAsset(target.assetPath, bytes);
    final imported = importWordbookJsonText(
      sourcePath: target.path,
      name: target.name,
      content: content,
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
      'SELECT * FROM words WHERE wordbook_id = ? ORDER BY id ASC LIMIT ? OFFSET ?',
      <Object?>[wordbookId, limit, offset],
    );
    final wordIds = rows
        .map((row) => (row['id'] as num?)?.toInt())
        .whereType<int>()
        .where((id) => id > 0)
        .toList(growable: false);
    final fieldsByWordId = _getWordFieldsByWordIds(wordIds);
    return rows
        .map((row) {
          final entry = WordEntry.fromMap(row);
          final wordId = (row['id'] as num?)?.toInt();
          final fields = wordId == null
              ? const <WordFieldItem>[]
              : (fieldsByWordId[wordId] ?? const <WordFieldItem>[]);
          if (fields.isEmpty) {
            return entry;
          }
          return entry.copyWith(fields: fields);
        })
        .toList(growable: false);
  }

  Map<int, List<WordFieldItem>> _getWordFieldsByWordIds(Iterable<int> wordIds) {
    final ids = wordIds.where((id) => id > 0).toSet().toList(growable: false);
    if (ids.isEmpty) {
      return const <int, List<WordFieldItem>>{};
    }
    final placeholders = List<String>.filled(ids.length, '?').join(', ');
    final rows = _selectMaps('''
      SELECT word_id, field_key, field_label, field_value_json, style_json, sort_order
      FROM word_fields
      WHERE word_id IN ($placeholders)
      ORDER BY word_id ASC, sort_order ASC, id ASC
      ''', ids.cast<Object?>());
    final output = <int, List<WordFieldItem>>{};
    for (final row in rows) {
      final wordId = (row['word_id'] as num?)?.toInt();
      if (wordId == null || wordId <= 0) {
        continue;
      }
      final field = _wordFieldItemFromRow(row);
      if (field == null) {
        continue;
      }
      output.putIfAbsent(wordId, () => <WordFieldItem>[]).add(field);
    }
    return output.map(
      (key, value) =>
          MapEntry(key, mergeFieldItems(List<WordFieldItem>.from(value))),
    );
  }

  WordFieldItem? _wordFieldItemFromRow(Map<String, Object?> row) {
    final key = normalizeFieldKey('${row['field_key'] ?? ''}');
    if (key.isEmpty) {
      return null;
    }
    final label = '${row['field_label'] ?? key}'.trim();
    final value = _decodeWordFieldValue(row['field_value_json']);
    if (value == null) {
      return null;
    }
    return WordFieldItem(
      key: key,
      label: label.isEmpty ? key : label,
      value: value,
      style: WordFieldStyle.fromJsonMap(_decodeJsonObject(row['style_json'])),
    );
  }

  WordFieldValue? _decodeWordFieldValue(Object? raw) {
    if (raw == null) {
      return null;
    }
    final text = '$raw'.trim();
    if (text.isEmpty) {
      return null;
    }
    try {
      return normalizeFieldValue(jsonDecode(text));
    } catch (_) {
      return normalizeFieldValue(text);
    }
  }

  Object? _decodeJsonObject(Object? raw) {
    if (raw == null) {
      return null;
    }
    final text = '$raw'.trim();
    if (text.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  Map<int, WordMemoryProgress> getWordMemoryProgressByWordIds(
    Iterable<int> wordIds,
  ) {
    final ids = wordIds.where((id) => id > 0).toSet().toList(growable: false);
    if (ids.isEmpty) {
      return const <int, WordMemoryProgress>{};
    }
    final placeholders = List<String>.filled(ids.length, '?').join(', ');
    final rows = _selectMaps(
      'SELECT * FROM progress WHERE word_id IN ($placeholders)',
      ids.cast<Object?>(),
    );
    final progressList = rows
        .map(WordMemoryProgress.fromMap)
        .toList(growable: false);
    return <int, WordMemoryProgress>{
      for (final progress in progressList) progress.wordId: progress,
    };
  }

  WordMemoryProgress? getWordMemoryProgress(int wordId) {
    final row = _selectOne(
      'SELECT * FROM progress WHERE word_id = ?',
      <Object?>[wordId],
    );
    if (row == null) {
      return null;
    }
    return WordMemoryProgress.fromMap(row);
  }

  void upsertWordMemoryProgress(WordMemoryProgress progress) {
    _db.execute(
      '''
      INSERT INTO progress (
        word_id,
        times_played,
        times_correct,
        last_played,
        familiarity,
        ease_factor,
        interval_days,
        next_review,
        consecutive_correct,
        memory_state
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(word_id) DO UPDATE SET
        times_played = excluded.times_played,
        times_correct = excluded.times_correct,
        last_played = excluded.last_played,
        familiarity = excluded.familiarity,
        ease_factor = excluded.ease_factor,
        interval_days = excluded.interval_days,
        next_review = excluded.next_review,
        consecutive_correct = excluded.consecutive_correct,
        memory_state = excluded.memory_state
      ''',
      <Object?>[
        progress.wordId,
        progress.timesPlayed,
        progress.timesCorrect,
        progress.lastPlayed?.toIso8601String(),
        progress.familiarity,
        progress.easeFactor,
        progress.intervalDays,
        progress.nextReview?.toIso8601String(),
        progress.consecutiveCorrect,
        progress.memoryState,
      ],
    );
  }

  int importWordbookJsonText({
    required String sourcePath,
    required String name,
    required String content,
    bool replaceExisting = true,
  }) {
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

      final count = _importService.processJsonText(
        content,
        onPayload: (payload) {
          if (payload.word.trim().isEmpty) return;
          _insertWord(wordbookId, payload);
        },
      );

      _refreshWordbookCount(wordbookId);
      return count;
    });
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

  void deleteManagedWordbook(int wordbookId) {
    final wordbook = _selectOne(
      'SELECT path FROM wordbooks WHERE id = ?',
      <Object?>[wordbookId],
    );
    if (wordbook == null) throw StateError('Wordbook not found');

    final path = wordbook['path']?.toString() ?? '';
    if (_isBuiltInPath(path)) {
      if (!_isDeletableBuiltInPath(path)) {
        throw StateError('Protected built-in wordbooks cannot be deleted');
      }
      final hiddenPaths = _hiddenBuiltInWordbookPaths()..add(path);
      _saveHiddenBuiltInWordbookPaths(hiddenPaths);
    }

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
      'SELECT * FROM words WHERE wordbook_id = ? AND word = ?',
      <Object?>[wordbookId, word],
    );

    if (existing == null) {
      _insertWord(wordbookId, payload.copyWith(word: word));
      if (refreshWordbookCount) {
        _refreshWordbookCount(wordbookId);
      }
      return true;
    }

    final existingEntry = WordEntry.fromMap(existing);
    final incomingRawContent = sanitizeDisplayText(payload.rawContent);
    final normalizedRawContent = incomingRawContent.isNotEmpty
        ? incomingRawContent
        : existingEntry.rawContent;
    final normalizedFields = mergeFieldItems(<WordFieldItem>[
      ...existingEntry.fields,
      ...payload.fields,
      if (normalizedRawContent.isNotEmpty)
        ...parseSectionedContent(normalizedRawContent),
    ]);
    final prepared = _buildStoredWordColumns(
      id: existingEntry.id,
      wordbookId: wordbookId,
      word: word,
      fields: normalizedFields,
      rawContent: normalizedRawContent,
    );

    _db.execute(
      '''
      UPDATE words SET
        meaning = ?, examples = ?, etymology = ?, roots = ?,
        affixes = ?, variations = ?, memory = ?, story = ?,
        fields_json = ?, raw_content = ?, entry_json = ?
      WHERE id = ?
      ''',
      <Object?>[
        prepared.row['meaning'],
        prepared.row['examples'],
        prepared.row['etymology'],
        prepared.row['roots'],
        prepared.row['affixes'],
        prepared.row['variations'],
        prepared.row['memory'],
        prepared.row['story'],
        prepared.row['fields_json'],
        prepared.row['raw_content'],
        prepared.row['entry_json'],
        (existing['id'] as num).toInt(),
      ],
    );
    _replaceWordFields((existing['id'] as num).toInt(), prepared.fields);
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
      'SELECT id FROM words WHERE wordbook_id = ? AND word = ?',
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

    final incomingRawContent = sanitizeDisplayText(payload.rawContent);
    final normalizedFields = mergeFieldItems(<WordFieldItem>[
      ...payload.fields,
      if (incomingRawContent.isNotEmpty)
        ...parseSectionedContent(incomingRawContent),
    ]);
    final prepared = _buildStoredWordColumns(
      id: (existing['id'] as num).toInt(),
      wordbookId: wordbookId,
      word: nextWord,
      fields: normalizedFields,
      rawContent: incomingRawContent,
    );

    _db.execute(
      '''
      UPDATE words SET
        word = ?, meaning = ?, examples = ?, etymology = ?, roots = ?,
        affixes = ?, variations = ?, memory = ?, story = ?, fields_json = ?, raw_content = ?, entry_json = ?
      WHERE id = ?
      ''',
      <Object?>[
        prepared.row['word'],
        prepared.row['meaning'],
        prepared.row['examples'],
        prepared.row['etymology'],
        prepared.row['roots'],
        prepared.row['affixes'],
        prepared.row['variations'],
        prepared.row['memory'],
        prepared.row['story'],
        prepared.row['fields_json'],
        prepared.row['raw_content'],
        prepared.row['entry_json'],
        (existing['id'] as num).toInt(),
      ],
    );
    _replaceWordFields((existing['id'] as num).toInt(), prepared.fields);

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
      final sourceWords = getWords(sourceWordbookId);
      _db.execute(
        'INSERT INTO wordbooks (name, path, word_count) VALUES (?, ?, 0)',
        <Object?>[trimmed, 'export_${DateTime.now().millisecondsSinceEpoch}'],
      );
      final insertedId = _lastInsertId();
      for (final entry in sourceWords) {
        _insertWord(insertedId, entry.toPayload());
      }
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
    if (filePath.toLowerCase().endsWith('.json')) {
      final content = await File(filePath).readAsString();
      return importWordbookJsonText(
        sourcePath: filePath,
        name: name,
        content: content,
        replaceExisting: true,
      );
    }

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
        _db.execute('DELETE FROM word_fields;');
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
            INSERT INTO words (id, wordbook_id, word, meaning, examples, etymology, roots, affixes, variations, memory, story, fields_json, raw_content, entry_json)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
              word['entry_json'],
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
      _backfillWordEntryJson();
      _migrateWordFieldsSchema();
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
                    _isBuiltInWordbookAsset(path),
              )
              .toList(growable: false)
            ..sort();

      return assets.map(_buildBuiltInConfigFromAsset).toList(growable: false);
    } catch (_) {
      return const <_BuiltInWordbookConfig>[];
    }
  }

  _BuiltInWordbookConfig _buildBuiltInConfigFromAsset(String assetPath) {
    final filename = p.basename(assetPath).trim();
    final normalizedFilename = filename.toLowerCase().endsWith('.json.gz')
        ? filename.substring(0, filename.length - '.json.gz'.length)
        : p.basenameWithoutExtension(filename);
    final baseName = normalizedFilename.trim().isEmpty
        ? 'dict'
        : normalizedFilename.trim();
    return _BuiltInWordbookConfig(
      path: '$_dictBuiltinPathPrefix$baseName',
      name: baseName,
      assetPath: assetPath,
    );
  }

  bool _isBuiltInWordbookAsset(String assetPath) {
    final normalized = assetPath.toLowerCase();
    return normalized.endsWith('.json') || normalized.endsWith('.json.gz');
  }

  String _decodeBuiltInWordbookAsset(String assetPath, List<int> bytes) {
    final normalized = assetPath.toLowerCase();
    final decodedBytes = normalized.endsWith('.json.gz')
        ? gzip.decode(bytes)
        : bytes;
    return utf8.decode(decodedBytes);
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

  Set<String> _hiddenBuiltInWordbookPaths() {
    final raw = getSetting(_hiddenBuiltInWordbooksSettingKey)?.trim();
    if (raw == null || raw.isEmpty) {
      return <String>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <String>{};
      }
      return decoded
          .map((item) => '$item'.trim())
          .where((path) => _isDeletableBuiltInPath(path))
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  void _saveHiddenBuiltInWordbookPaths(Set<String> paths) {
    final sortedPaths = paths.toList(growable: false)..sort();
    setSetting(_hiddenBuiltInWordbooksSettingKey, jsonEncode(sortedPaths));
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

  void _openDatabase() {
    _db = sqlite3.open(dbPath);
    _db.execute('PRAGMA foreign_keys = ON;');
    _db.execute('PRAGMA journal_mode = WAL;');
    _db.execute('PRAGMA synchronous = NORMAL;');
  }

  Future<void> _prepareDatabase() async {
    _createTables();
    _migrateWordsSchema();
    _migrateWordFieldsSchema();
    _migrateTimerRecordsSchema();
    _migrateProgressSchema();
    _migrateTodosSchema();
    _migrateNotesSchema();
    ensureSpecialWordbooks();
    await syncBuiltInWordbooksCatalog();
    _initialized = true;
  }

  Future<Directory> _ensureBackupDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    final backupDir = Directory(p.join(supportDir.path, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  Future<Directory> _ensureExportDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    final exportDir = Directory(p.join(supportDir.path, 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  String _parseBackupReason(String filename) {
    final match = _backupFilePattern.firstMatch(filename);
    return match?.group(1) ?? 'manual';
  }

  List<UserDataExportWordbook> _buildWordbooksExportPayload() {
    final rows = _selectMaps('''
      SELECT id, name, path, word_count, created_at
      FROM wordbooks
      ORDER BY id ASC
    ''');
    return rows
        .map((row) {
          final wordbookId = ((row['id'] as num?) ?? 0).toInt();
          return UserDataExportWordbook(
            wordbook: Wordbook.fromMap(row),
            words: getWords(wordbookId),
          );
        })
        .toList(growable: false);
  }

  Map<String, String> _buildSettingsExportPayload() {
    final rows = _selectMaps(
      'SELECT key, value FROM settings ORDER BY key ASC',
    );
    return <String, String>{
      for (final row in rows) '${row['key'] ?? ''}': '${row['value'] ?? ''}',
    };
  }

  Set<UserDataExportSection> _resolveUserDataExportSections(
    Iterable<UserDataExportSection>? sections,
  ) {
    final resolved = sections == null
        ? UserDataExportSection.values.toSet()
        : sections.toSet();
    if (resolved.isEmpty) {
      throw ArgumentError('At least one export section must be selected');
    }
    return resolved;
  }

  String _normalizeUserDataExportFileName(String? rawFileName) {
    return _normalizeExportFileName(
      rawFileName: rawFileName,
      defaultFileStem: 'xianyushengxi_user_data',
      extension: 'json',
    );
  }

  String _normalizeExportFileName({
    required String? rawFileName,
    required String defaultFileStem,
    required String extension,
  }) {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    var normalized = (rawFileName ?? '').trim();
    if (normalized.isEmpty) {
      normalized = '${defaultFileStem}_$timestamp.$extension';
    }
    if (!normalized.toLowerCase().endsWith('.$extension')) {
      normalized = '$normalized.$extension';
    }
    normalized = normalized.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]+'), '_');
    normalized = normalized.replaceAll(RegExp(r'\s+'), '_');
    normalized = normalized.replaceAll(RegExp(r'_+'), '_');
    normalized = normalized.replaceAll(RegExp(r'^\.+|\.+$'), '');
    if (normalized.isEmpty) {
      normalized = '${defaultFileStem}_$timestamp.$extension';
    }
    if (_windowsReservedFileNamePattern.hasMatch(normalized)) {
      normalized = 'export_$normalized';
    }
    if (!normalized.toLowerCase().endsWith('.$extension')) {
      normalized = '$normalized.$extension';
    }
    return normalized;
  }

  String _escapeSqlString(String value) => value.replaceAll("'", "''");

  void _replaceWordFields(int wordId, List<WordFieldItem> fields) {
    _db.execute('DELETE FROM word_fields WHERE word_id = ?', <Object?>[wordId]);
    final normalizedFields = mergeFieldItems(List<WordFieldItem>.from(fields));
    for (var index = 0; index < normalizedFields.length; index += 1) {
      final field = normalizedFields[index];
      _db.execute(
        '''
        INSERT INTO word_fields (
          word_id,
          field_key,
          field_label,
          field_value_json,
          style_json,
          sort_order
        ) VALUES (?, ?, ?, ?, ?, ?)
        ''',
        <Object?>[
          wordId,
          field.key,
          field.label,
          jsonEncode(field.value),
          field.style.isEmpty ? null : jsonEncode(field.style.toJsonMap()),
          index,
        ],
      );
    }
  }

  _PreparedWordRecord _buildStoredWordColumns({
    int? id,
    required int wordbookId,
    required String word,
    required List<WordFieldItem> fields,
    required String rawContent,
  }) {
    final normalizedWord = sanitizeDisplayText(word).trim();
    final normalizedRawContent = sanitizeDisplayText(rawContent);
    final normalizedFields = mergeFieldItems(<WordFieldItem>[
      ...fields,
      if (normalizedRawContent.isNotEmpty)
        ...parseSectionedContent(normalizedRawContent),
    ]);
    final legacy = toLegacyFields(normalizedFields);
    final persistedRawContent = normalizedRawContent.isNotEmpty
        ? normalizedRawContent
        : (legacy.meaning ?? '');
    final entry = WordEntry(
      id: id,
      wordbookId: wordbookId,
      word: normalizedWord,
      meaning: legacy.meaning,
      examples: legacy.examples,
      etymology: legacy.etymology,
      roots: legacy.roots,
      affixes: legacy.affixes,
      variations: legacy.variations,
      memory: legacy.memory,
      story: legacy.story,
      fields: normalizedFields,
      rawContent: persistedRawContent,
    );

    return _PreparedWordRecord(
      row: <String, Object?>{
        'word': normalizedWord,
        'meaning': legacy.meaning,
        'examples': legacy.examples == null
            ? null
            : jsonEncode(legacy.examples),
        'etymology': legacy.etymology,
        'roots': legacy.roots,
        'affixes': legacy.affixes,
        'variations': legacy.variations,
        'memory': legacy.memory,
        'story': legacy.story,
        'fields_json': stringifyFieldItems(normalizedFields),
        'raw_content': persistedRawContent,
        'entry_json': jsonEncode(entry.toJsonMap()),
      },
      fields: normalizedFields,
    );
  }

  void _insertWord(int wordbookId, WordEntryPayload payload) {
    final prepared = _buildStoredWordColumns(
      wordbookId: wordbookId,
      word: payload.word,
      fields: payload.fields,
      rawContent: payload.rawContent,
    );

    _db.execute(
      '''
      INSERT INTO words (wordbook_id, word, meaning, examples, etymology, roots, affixes, variations, memory, story, fields_json, raw_content, entry_json)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      <Object?>[
        wordbookId,
        prepared.row['word'],
        prepared.row['meaning'],
        prepared.row['examples'],
        prepared.row['etymology'],
        prepared.row['roots'],
        prepared.row['affixes'],
        prepared.row['variations'],
        prepared.row['memory'],
        prepared.row['story'],
        prepared.row['fields_json'],
        prepared.row['raw_content'],
        prepared.row['entry_json'],
      ],
    );
    _replaceWordFields(_lastInsertId(), prepared.fields);
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
  bool _isDeletableBuiltInPath(String path) =>
      path.startsWith(_dictBuiltinPathPrefix);

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

  List<TodoItem> getTodos() {
    final rows = _selectMaps(
      'SELECT * FROM todos ORDER BY sort_order ASC, created_at DESC, id DESC',
    );
    return rows.map(TodoItem.fromMap).toList();
  }

  int insertTodo(TodoItem item) {
    final normalizedItem = _normalizeTodoSystemCalendarAlertSelection(item);
    final sortOrder = item.sortOrder > 0
        ? item.sortOrder
        : _nextTodoSortOrder();
    final normalizedDeferred = normalizedItem.completed
        ? false
        : normalizedItem.deferred;
    _db.execute(
      'INSERT INTO todos (content, completed, deferred, priority, category, note, color, sort_order, due_at, alarm_enabled, sync_to_system_calendar, system_calendar_notification_enabled, system_calendar_notification_minutes_before, system_calendar_alarm_enabled, system_calendar_alarm_minutes_before, created_at, completed_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        normalizedItem.content,
        normalizedItem.completed ? 1 : 0,
        normalizedDeferred ? 1 : 0,
        normalizedItem.priority,
        normalizedItem.category,
        normalizedItem.note,
        normalizedItem.color,
        sortOrder,
        normalizedItem.dueAt?.toIso8601String(),
        normalizedItem.alarmEnabled ? 1 : 0,
        normalizedItem.syncToSystemCalendar ? 1 : 0,
        normalizedItem.systemCalendarAlertMode ==
                TodoSystemCalendarAlertMode.notification
            ? 1
            : 0,
        normalizedItem.systemCalendarNotificationMinutesBefore,
        normalizedItem.systemCalendarAlertMode ==
                TodoSystemCalendarAlertMode.alarm
            ? 1
            : 0,
        normalizedItem.systemCalendarAlarmMinutesBefore,
        normalizedItem.createdAt?.toIso8601String(),
        normalizedItem.completedAt?.toIso8601String(),
      ],
    );
    return _lastInsertId();
  }

  void updateTodo(TodoItem item) {
    if (item.id == null) return;
    final normalizedItem = _normalizeTodoSystemCalendarAlertSelection(item);
    final normalizedDeferred = normalizedItem.completed
        ? false
        : normalizedItem.deferred;
    _db.execute(
      'UPDATE todos SET content = ?, completed = ?, deferred = ?, priority = ?, category = ?, note = ?, color = ?, sort_order = ?, due_at = ?, alarm_enabled = ?, sync_to_system_calendar = ?, system_calendar_notification_enabled = ?, system_calendar_notification_minutes_before = ?, system_calendar_alarm_enabled = ?, system_calendar_alarm_minutes_before = ?, completed_at = ? WHERE id = ?',
      <Object?>[
        normalizedItem.content,
        normalizedItem.completed ? 1 : 0,
        normalizedDeferred ? 1 : 0,
        normalizedItem.priority,
        normalizedItem.category,
        normalizedItem.note,
        normalizedItem.color,
        normalizedItem.sortOrder,
        normalizedItem.dueAt?.toIso8601String(),
        normalizedItem.alarmEnabled ? 1 : 0,
        normalizedItem.syncToSystemCalendar ? 1 : 0,
        normalizedItem.systemCalendarAlertMode ==
                TodoSystemCalendarAlertMode.notification
            ? 1
            : 0,
        normalizedItem.systemCalendarNotificationMinutesBefore,
        normalizedItem.systemCalendarAlertMode ==
                TodoSystemCalendarAlertMode.alarm
            ? 1
            : 0,
        normalizedItem.systemCalendarAlarmMinutesBefore,
        normalizedItem.completedAt?.toIso8601String(),
        normalizedItem.id,
      ],
    );
  }

  TodoItem _normalizeTodoSystemCalendarAlertSelection(TodoItem item) {
    final useAlarm =
        item.systemCalendarAlertMode == TodoSystemCalendarAlertMode.alarm;
    return item.copyWith(
      systemCalendarNotificationEnabled: !useAlarm,
      systemCalendarAlarmEnabled: useAlarm,
    );
  }

  void deleteTodo(int id) {
    _db.execute('DELETE FROM todos WHERE id = ?', <Object?>[id]);
  }

  void clearCompletedTodos() {
    _db.execute('DELETE FROM todos WHERE completed = 1');
  }

  void reorderTodos(List<int> orderedIds) {
    if (orderedIds.isEmpty) return;
    _runInTransaction<void>(() {
      for (var index = 0; index < orderedIds.length; index += 1) {
        _db.execute('UPDATE todos SET sort_order = ? WHERE id = ?', <Object?>[
          index,
          orderedIds[index],
        ]);
      }
    });
  }

  List<PlanNote> getNotes() {
    final rows = _selectMaps(
      'SELECT * FROM notes ORDER BY sort_order ASC, updated_at DESC, id DESC',
    );
    return rows.map(PlanNote.fromMap).toList();
  }

  void insertNote(PlanNote note) {
    final sortOrder = note.sortOrder > 0
        ? note.sortOrder
        : _nextNoteSortOrder();
    _db.execute(
      'INSERT INTO notes (title, content, color, sort_order, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
      <Object?>[
        note.title,
        note.content,
        note.color,
        sortOrder,
        note.createdAt?.toIso8601String(),
        note.updatedAt?.toIso8601String(),
      ],
    );
  }

  void updateNote(PlanNote note) {
    if (note.id == null) return;
    _db.execute(
      'UPDATE notes SET title = ?, content = ?, color = ?, sort_order = ?, updated_at = ? WHERE id = ?',
      <Object?>[
        note.title,
        note.content,
        note.color,
        note.sortOrder,
        note.updatedAt?.toIso8601String(),
        note.id,
      ],
    );
  }

  void deleteNote(int id) {
    _db.execute('DELETE FROM notes WHERE id = ?', <Object?>[id]);
  }

  void deleteNotes(List<int> ids) {
    if (ids.isEmpty) return;
    final placeholders = List<String>.filled(ids.length, '?').join(', ');
    _db.execute(
      'DELETE FROM notes WHERE id IN ($placeholders)',
      ids.cast<Object?>(),
    );
  }

  void reorderNotes(List<int> orderedIds) {
    if (orderedIds.isEmpty) return;
    _runInTransaction<void>(() {
      for (var index = 0; index < orderedIds.length; index += 1) {
        _db.execute('UPDATE notes SET sort_order = ? WHERE id = ?', <Object?>[
          index,
          orderedIds[index],
        ]);
      }
    });
  }

  void insertTimerRecord(TomatoTimerRecord record) {
    _db.execute(
      'INSERT INTO timer_records (start_time, duration_minutes, focus_duration_minutes, break_duration_minutes, rounds_completed, focus_minutes, break_minutes, is_partial) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        record.startTime.toIso8601String(),
        record.durationMinutes,
        record.focusDurationMinutes,
        record.breakDurationMinutes,
        record.roundsCompleted,
        record.focusMinutes,
        record.breakMinutes,
        record.partial ? 1 : 0,
      ],
    );
  }

  List<TomatoTimerRecord> getTimerRecords({int limit = 30}) {
    final rows = _selectMaps(
      'SELECT * FROM timer_records ORDER BY start_time DESC LIMIT ?',
      <Object?>[limit],
    );
    return rows.map(TomatoTimerRecord.fromMap).toList();
  }

  int _nextNoteSortOrder() {
    final row = _selectOne(
      'SELECT COALESCE(MAX(sort_order), -1) AS value FROM notes',
    );
    return ((row?['value'] as num?)?.toInt() ?? -1) + 1;
  }

  int _nextTodoSortOrder() {
    final row = _selectOne(
      'SELECT COALESCE(MAX(sort_order), -1) AS value FROM todos',
    );
    return ((row?['value'] as num?)?.toInt() ?? -1) + 1;
  }
}

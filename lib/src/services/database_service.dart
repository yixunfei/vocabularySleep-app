import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';

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
import '../models/wordbook_schema_v1.dart';
import '../utils/search_text_normalizer.dart' as search_text;
import 'built_in_wordbook_source.dart';
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

class DownloadedAmbientSoundInfo {
  const DownloadedAmbientSoundInfo({
    required this.soundId,
    required this.remoteKey,
    required this.relativePath,
    required this.categoryKey,
    required this.name,
    required this.filePath,
    required this.downloadedAt,
    required this.lastAccessedAt,
  });

  final String soundId;
  final String remoteKey;
  final String relativePath;
  final String categoryKey;
  final String name;
  final String filePath;
  final DateTime downloadedAt;
  final DateTime lastAccessedAt;

  factory DownloadedAmbientSoundInfo.fromMap(Map<String, Object?> map) {
    return DownloadedAmbientSoundInfo(
      soundId: map['sound_id'] as String,
      remoteKey: map['remote_key'] as String,
      relativePath: map['relative_path'] as String,
      categoryKey: map['category_key'] as String,
      name: map['name'] as String,
      filePath: map['file_path'] as String,
      downloadedAt: DateTime.parse(map['downloaded_at'] as String),
      lastAccessedAt: DateTime.parse(map['last_accessed_at'] as String),
    );
  }
}

enum BuiltInWordbookLoadStage { downloading, processing, completed }

class BuiltInWordbookLoadProgress {
  const BuiltInWordbookLoadProgress({
    required this.stage,
    this.progress,
    this.receivedBytes,
    this.totalBytes,
    this.processedEntries,
    this.totalEntries,
  });

  final BuiltInWordbookLoadStage stage;
  final double? progress;
  final int? receivedBytes;
  final int? totalBytes;
  final int? processedEntries;
  final int? totalEntries;
}

typedef BuiltInWordbookLoadProgressCallback =
    void Function(BuiltInWordbookLoadProgress progress);

class _PreparedWordRecord {
  const _PreparedWordRecord({
    required this.row,
    required this.fields,
    required this.entryUid,
    required this.primaryGloss,
    required this.schemaVersion,
    required this.sourcePayloadJson,
    required this.sortIndex,
  });

  final Map<String, Object?> row;
  final List<WordFieldItem> fields;
  final String? entryUid;
  final String? primaryGloss;
  final String? schemaVersion;
  final String? sourcePayloadJson;
  final int sortIndex;
}

class _WordImportInsertStatements {
  _WordImportInsertStatements({
    required this.wordInsert,
    required this.fieldInsert,
    required this.styleInsert,
    required this.tagInsert,
    required this.mediaInsert,
  });

  final PreparedStatement wordInsert;
  final PreparedStatement fieldInsert;
  final PreparedStatement styleInsert;
  final PreparedStatement tagInsert;
  final PreparedStatement mediaInsert;

  void dispose() {
    wordInsert.dispose();
    fieldInsert.dispose();
    styleInsert.dispose();
    tagInsert.dispose();
    mediaInsert.dispose();
  }
}

class AppDatabaseService {
  AppDatabaseService(
    WordbookImportService importService, {
    BuiltInWordbookSource? builtInWordbookSource,
  }) : _importService = importService,
       _builtInWordbookSource =
           builtInWordbookSource ?? const AssetBuiltInWordbookSource();

  final WordbookImportService _importService;
  final BuiltInWordbookSource _builtInWordbookSource;
  final Map<String, Future<int>> _builtInWordbookLoadFutures =
      <String, Future<int>>{};

  late Database _db;
  late final String dbPath;
  bool _initialized = false;
  Future<void>? _initFuture;
  int _transactionDepth = 0;

  static const _specialWordbooks = <String, String>{
    'builtin:favorites': 'Favorites',
    'builtin:task': 'Task',
  };
  static final RegExp _backupFilePattern = RegExp(
    r'^vocabulary_(.+)_(\d{4}-\d{2}-\d{2}T.+)\.db$',
  );
  static final RegExp _windowsReservedFileNamePattern = RegExp(
    r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)',
    caseSensitive: false,
  );
  static const int _maxSqlVariablesPerStatement = 900;
  static const int _currentSchemaVersion = 9;
  static const String _wordOrderClause = 'sort_index ASC, id ASC';
  static const String _dictBuiltinPathPrefix = 'builtin:dict:';
  static const String _hiddenBuiltInWordbooksSettingKey =
      'hidden_built_in_wordbooks';

  Future<void> init() {
    if (_initialized) {
      return Future<void>.value();
    }
    _initFuture ??= _initImpl();
    return _initFuture!;
  }

  Future<void> _initImpl() async {
    try {
      final supportDir = await getApplicationSupportDirectory();
      if (!await supportDir.exists()) {
        await supportDir.create(recursive: true);
      }
      dbPath = p.join(supportDir.path, 'vocabulary.db');
      _openDatabase();
      await _prepareDatabase();
      _initialized = true;
    } catch (_) {
      try {
        _db.dispose();
      } catch (_) {}
      rethrow;
    } finally {
      if (!_initialized) {
        _initFuture = null;
      }
    }
  }

  Future<String> createSafetyBackup({String reason = 'manual'}) async {
    await init();

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
    await init();
    final payload = buildUserDataExportPayload(sections: sections);
    final contents = const JsonEncoder.withIndent(
      '  ',
    ).convert(payload.toJsonMap());
    return writeTextExport(
      contents: contents,
      defaultFileStem: 'user_data_export',
      extension: 'json',
      directoryPath: directoryPath,
      fileName: fileName,
    );
  }

  Future<void> restoreUserDataExportFromFile(String filePath) async {
    await init();

    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('导出文件不存在', filePath);
    }

    final raw = await file.readAsString();
    Map<String, Object?> jsonMap;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        jsonMap = decoded;
      } else if (decoded is Map) {
        jsonMap = decoded.cast<String, Object?>();
      } else {
        throw const UserDataExportValidationException(
          '导出文件根节点必须是对象，无法识别 schema。',
        );
      }
    } on UserDataExportValidationException {
      rethrow;
    } catch (error) {
      throw UserDataExportValidationException(
        '导出文件解析失败，无法识别 schema 或 JSON 结构：$error',
      );
    }

    final payload = UserDataExportPayload.validatedFromJsonMap(jsonMap);
    await restoreUserDataExportPayload(payload);
  }

  Future<void> restoreUserDataExportPayload(
    UserDataExportPayload payload,
  ) async {
    await init();

    final selectedSections = _resolveSelectedExportSections(
      storageKeys: payload.sections,
    );
    final restoredWordIds = <int, int>{};

    await _runInTransactionAsync(() async {
      if (selectedSections.contains(UserDataExportSection.wordbooks)) {
        final wordIdMap = await _restoreWordbooksFromExport(payload.wordbooks);
        restoredWordIds.addAll(wordIdMap);
      }

      if (selectedSections.contains(UserDataExportSection.todos)) {
        _db.execute('DELETE FROM todos;');
        for (final item in payload.todos) {
          _db.execute(
            '''
            INSERT INTO todos (
              content,
              completed,
              deferred,
              priority,
              category,
              note,
              color,
              sort_order,
              due_at,
              alarm_enabled,
              sync_to_system_calendar,
              system_calendar_notification_enabled,
              system_calendar_notification_minutes_before,
              system_calendar_alarm_enabled,
              system_calendar_alarm_minutes_before,
              created_at,
              completed_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            <Object?>[
              item.content,
              item.completed ? 1 : 0,
              item.isDeferred ? 1 : 0,
              item.priority,
              item.category,
              item.note,
              item.color,
              item.sortOrder,
              item.dueAt?.toIso8601String(),
              item.alarmEnabled ? 1 : 0,
              item.syncToSystemCalendar ? 1 : 0,
              item.systemCalendarAlertMode ==
                      TodoSystemCalendarAlertMode.notification
                  ? 1
                  : 0,
              item.systemCalendarNotificationMinutesBefore,
              item.systemCalendarAlertMode == TodoSystemCalendarAlertMode.alarm
                  ? 1
                  : 0,
              item.systemCalendarAlarmMinutesBefore,
              item.createdAt?.toIso8601String(),
              item.completedAt?.toIso8601String(),
            ],
          );
        }
      }

      if (selectedSections.contains(UserDataExportSection.notes)) {
        _db.execute('DELETE FROM notes;');
        for (final note in payload.notes) {
          _db.execute(
            '''
            INSERT INTO notes (
              title,
              content,
              color,
              sort_order,
              created_at,
              updated_at
            ) VALUES (?, ?, ?, ?, ?, ?)
            ''',
            <Object?>[
              note.title,
              note.content,
              note.color,
              note.sortOrder,
              note.createdAt?.toIso8601String(),
              note.updatedAt?.toIso8601String(),
            ],
          );
        }
      }

      if (selectedSections.contains(UserDataExportSection.timerRecords)) {
        _db.execute('DELETE FROM timer_records;');
        for (final record in payload.timerRecords) {
          _db.execute(
            '''
            INSERT INTO timer_records (
              start_time,
              duration_minutes,
              focus_duration_minutes,
              break_duration_minutes,
              rounds_completed,
              focus_minutes,
              break_minutes,
              is_partial
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''',
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
      }

      if (selectedSections.contains(UserDataExportSection.settings)) {
        _db.execute('DELETE FROM settings;');
        for (final entry in payload.settings.entries) {
          setSetting(entry.key, entry.value);
        }
      }

      if (selectedSections.contains(UserDataExportSection.progress)) {
        _db.execute('DELETE FROM progress;');
        for (final progress in payload.progress) {
          final restoredWordId =
              restoredWordIds[progress.wordId] ??
              _resolveExistingRestoredWordId(progress.wordId);
          if (restoredWordId == null || restoredWordId <= 0) {
            continue;
          }
          upsertWordMemoryProgress(progress.copyWith(wordId: restoredWordId));
        }
      }
    });

    ensureSpecialWordbooks();
    await syncBuiltInWordbooksCatalog();
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
    final selectedSections = _resolveSelectedExportSections(sections: sections);
    final orderedSectionKeys = UserDataExportSection.values
        .where(selectedSections.contains)
        .map((item) => item.storageKey)
        .toList(growable: false);

    final wordbooks = selectedSections.contains(UserDataExportSection.wordbooks)
        ? _buildWordbooksExportPayload()
        : const <UserDataExportWordbook>[];
    final todos = selectedSections.contains(UserDataExportSection.todos)
        ? getTodos()
        : const <TodoItem>[];
    final notes = selectedSections.contains(UserDataExportSection.notes)
        ? getNotes()
        : const <PlanNote>[];
    final progress = selectedSections.contains(UserDataExportSection.progress)
        ? _selectMaps(
            'SELECT * FROM progress ORDER BY word_id ASC, id ASC',
          ).map(WordMemoryProgress.fromMap).toList(growable: false)
        : const <WordMemoryProgress>[];
    final timerRecords =
        selectedSections.contains(UserDataExportSection.timerRecords)
        ? getTimerRecords(limit: 100000)
        : const <TomatoTimerRecord>[];
    final settings = selectedSections.contains(UserDataExportSection.settings)
        ? <String, String>{
            for (final row in _selectMaps(
              'SELECT key, value FROM settings ORDER BY key ASC',
            ))
              '${row['key'] ?? ''}': '${row['value'] ?? ''}',
          }
        : const <String, String>{};

    return UserDataExportPayload(
      exportedAt: DateTime.now().toUtc(),
      sections: orderedSectionKeys,
      wordbooks: wordbooks,
      todos: todos,
      notes: notes,
      progress: progress,
      timerRecords: timerRecords,
      settings: settings,
    );
  }

  Set<UserDataExportSection> _resolveSelectedExportSections({
    Iterable<UserDataExportSection>? sections,
    Iterable<String>? storageKeys,
  }) {
    if (sections != null) {
      final selected = sections.toSet();
      return selected.isEmpty ? UserDataExportSection.values.toSet() : selected;
    }
    if (storageKeys != null) {
      final keys = storageKeys.map((item) => item.trim()).toSet();
      final selected = UserDataExportSection.values
          .where((item) => keys.contains(item.storageKey))
          .toSet();
      return selected.isEmpty ? UserDataExportSection.values.toSet() : selected;
    }
    return UserDataExportSection.values.toSet();
  }

  List<UserDataExportWordbook> _buildWordbooksExportPayload() {
    final books = getWordbooks()
        .where(
          (wordbook) =>
              !wordbook.path.startsWith(_dictBuiltinPathPrefix) &&
              wordbook.path.trim().isNotEmpty,
        )
        .toList(growable: false);

    return books
        .map((wordbook) {
          final standardBook = _tryBuildStandardBookMetaFromWordbook(wordbook);
          return UserDataExportWordbook(
            wordbook: wordbook,
            words: _buildWordbookExportWords(wordbook.id),
            standardBook: standardBook,
          );
        })
        .toList(growable: false);
  }

  List<UserDataExportWordRecord> _buildWordbookExportWords(int wordbookId) {
    final rows = _selectMaps(
      'SELECT * FROM words WHERE wordbook_id = ? ORDER BY $_wordOrderClause',
      <Object?>[wordbookId],
    );
    final wordIds = rows
        .map((row) => (row['id'] as num?)?.toInt())
        .whereType<int>()
        .where((id) => id > 0)
        .toList(growable: false);
    final fieldsByWordId = _getWordFieldsByWordIds(wordIds);

    return rows
        .map((row) {
          final wordId = (row['id'] as num?)?.toInt();
          final storedFields = wordId == null
              ? const <WordFieldItem>[]
              : (fieldsByWordId[wordId] ?? const <WordFieldItem>[]);
          final entry = WordEntry.fromMap(row).copyWith(fields: storedFields);
          final legacy = entry.legacyFields;
          final resolvedMeaning = sanitizeDisplayText(entry.summaryMeaningText);
          return UserDataExportWordRecord(
            id: wordId,
            wordbookId: wordbookId,
            word: entry.word,
            entryUid: entry.entryUid,
            meaning: resolvedMeaning.isEmpty ? entry.meaning : resolvedMeaning,
            primaryGloss:
                entry.primaryGloss ??
                (resolvedMeaning.isEmpty ? entry.meaning : resolvedMeaning),
            schemaVersion: entry.schemaVersion,
            sortIndex: entry.sortIndex,
            examples: legacy.examples,
            etymology: legacy.etymology,
            roots: legacy.roots,
            affixes: legacy.affixes,
            variations: legacy.variations,
            memory: legacy.memory,
            story: legacy.story,
            sourcePayloadJson: entry.sourcePayloadJson,
            fields: storedFields,
            rawContent: _resolveStoredRawContent(row),
          );
        })
        .toList(growable: false);
  }

  WordbookBookMetaV1? _tryBuildStandardBookMetaFromWordbook(Wordbook wordbook) {
    if ((wordbook.schemaVersion ?? '').trim() != wordbookSchemaV1) {
      return null;
    }
    final metadata = _tryDecodeJsonObjectMap(wordbook.metadataJson);
    if (metadata == null) {
      return null;
    }
    try {
      final book = WordbookBookMetaV1.fromJsonMap(metadata);
      if (book.id.trim().isEmpty ||
          book.sourceLanguage.trim().isEmpty ||
          book.targetLanguage.trim().isEmpty ||
          book.direction.trim().isEmpty) {
        return null;
      }
      return book;
    } catch (_) {
      return null;
    }
  }

  Future<String> getDefaultUserDataExportDirectoryPath() async {
    final exportDir = await _ensureExportDirectory();
    return exportDir.path;
  }

  Future<void> restoreSafetyBackup(String backupPath) async {
    await init();

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
    await init();

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
    _initFuture = null;
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
        schema_version TEXT,
        metadata_json TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        wordbook_id INTEGER NOT NULL,
        entry_uid TEXT,
        word TEXT NOT NULL,
        meaning TEXT,
        primary_gloss TEXT,
        search_word TEXT NOT NULL,
        search_meaning TEXT,
        search_details TEXT,
        search_word_compact TEXT NOT NULL,
        search_details_compact TEXT,
        schema_version TEXT,
        source_payload_json TEXT,
        sort_index INTEGER DEFAULT 0,
        extension_json TEXT,
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
      CREATE TABLE IF NOT EXISTS word_field_styles (
        word_field_id INTEGER PRIMARY KEY,
        background_hex TEXT,
        border_hex TEXT,
        text_hex TEXT,
        accent_hex TEXT,
        FOREIGN KEY (word_field_id) REFERENCES word_fields(id) ON DELETE CASCADE
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS word_field_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_field_id INTEGER NOT NULL,
        tag TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0,
        FOREIGN KEY (word_field_id) REFERENCES word_fields(id) ON DELETE CASCADE
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS word_field_media (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_field_id INTEGER NOT NULL,
        media_type TEXT NOT NULL,
        media_source TEXT NOT NULL,
        media_label TEXT,
        mime_type TEXT,
        sort_order INTEGER DEFAULT 0,
        FOREIGN KEY (word_field_id) REFERENCES word_fields(id) ON DELETE CASCADE
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
      CREATE TABLE IF NOT EXISTS word_memory_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id INTEGER NOT NULL,
        event_kind TEXT NOT NULL,
        quality INTEGER DEFAULT 0,
        weak_reasons_json TEXT,
        session_title TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE
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

    _db.execute('''
      CREATE TABLE IF NOT EXISTS downloaded_ambient_sounds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sound_id TEXT NOT NULL UNIQUE,
        remote_key TEXT NOT NULL,
        relative_path TEXT NOT NULL UNIQUE,
        category_key TEXT NOT NULL,
        name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        downloaded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        last_accessed_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_words_wordbook ON words(wordbook_id);',
    );
    _db.execute('CREATE INDEX IF NOT EXISTS idx_words_word ON words(word);');
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_words_search_word ON words(wordbook_id, search_word);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_words_search_meaning ON words(wordbook_id, search_meaning);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_words_search_details ON words(wordbook_id, search_details);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_words_search_word_compact ON words(wordbook_id, search_word_compact);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_words_search_details_compact ON words(wordbook_id, search_details_compact);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_words_entry_uid ON words(wordbook_id, entry_uid);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_words_sort_index ON words(wordbook_id, sort_index, id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_word_fields_word ON word_fields(word_id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_word_fields_word_sort ON word_fields(word_id, sort_order, id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_word_fields_key_label_word ON word_fields(field_key, field_label, word_id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_word_fields_key_sort ON word_fields(field_key, sort_order, word_id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_word_field_tags_field_sort ON word_field_tags(word_field_id, sort_order, id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_word_field_tags_tag ON word_field_tags(tag, word_field_id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_word_field_media_field_sort ON word_field_media(word_field_id, sort_order, id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_word_field_media_type_source ON word_field_media(media_type, media_source, word_field_id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_marks_word ON user_marks(word_id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_progress_word ON progress(word_id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_word_memory_events_word_time ON word_memory_events(word_id, created_at DESC, id DESC);',
    );
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

  void _migrateWordsStorageSchema() {
    final tableInfo = _db.select('PRAGMA table_info(words);');
    final columnNames = <String>{
      for (final row in tableInfo) row['name'].toString(),
    };
    final hasLegacyColumns =
        columnNames.contains('examples') ||
        columnNames.contains('etymology') ||
        columnNames.contains('roots') ||
        columnNames.contains('affixes') ||
        columnNames.contains('variations') ||
        columnNames.contains('memory') ||
        columnNames.contains('story') ||
        columnNames.contains('fields_json') ||
        columnNames.contains('raw_content');
    final missingSearchColumns =
        !columnNames.contains('search_word') ||
        !columnNames.contains('search_meaning') ||
        !columnNames.contains('search_details') ||
        !columnNames.contains('search_word_compact') ||
        !columnNames.contains('search_details_compact') ||
        !columnNames.contains('entry_json');
    if (!hasLegacyColumns && !missingSearchColumns) {
      return;
    }

    final existingRows = _selectMaps('SELECT * FROM words ORDER BY id ASC');
    final fieldRows = _selectMaps('''
      SELECT word_id, field_key, field_label, field_value_json, style_json, sort_order
      FROM word_fields
      ORDER BY word_id ASC, sort_order ASC, id ASC
      ''');
    final existingFieldsByWordId = <int, List<WordFieldItem>>{};
    for (final row in fieldRows) {
      final wordId = (row['word_id'] as num?)?.toInt();
      if (wordId == null || wordId <= 0) {
        continue;
      }
      final field = _wordFieldItemFromRow(row);
      if (field == null) {
        continue;
      }
      existingFieldsByWordId
          .putIfAbsent(wordId, () => <WordFieldItem>[])
          .add(field);
    }

    _db.execute('PRAGMA foreign_keys = OFF;');
    try {
      _db.execute('ALTER TABLE words RENAME TO words_legacy_cache;');
      _db.execute('''
        CREATE TABLE words (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          wordbook_id INTEGER NOT NULL,
          entry_uid TEXT,
          word TEXT NOT NULL,
          meaning TEXT,
          primary_gloss TEXT,
          search_word TEXT NOT NULL,
          search_meaning TEXT,
          search_details TEXT,
          search_word_compact TEXT NOT NULL,
          search_details_compact TEXT,
          schema_version TEXT,
          source_payload_json TEXT,
          sort_index INTEGER DEFAULT 0,
          extension_json TEXT,
          entry_json TEXT,
          FOREIGN KEY (wordbook_id) REFERENCES wordbooks(id) ON DELETE CASCADE
        );
      ''');
      for (final row in existingRows) {
        final baseEntry = WordEntry.fromMap(row);
        final wordId = (row['id'] as num?)?.toInt();
        final fields = wordId == null
            ? const <WordFieldItem>[]
            : (existingFieldsByWordId[wordId] ?? const <WordFieldItem>[]);
        final entry = fields.isEmpty
            ? baseEntry
            : baseEntry.copyWith(fields: fields);
        final prepared = _buildStoredWordRecord(
          id: entry.id,
          wordbookId: entry.wordbookId,
          word: entry.word,
          fields: entry.fields,
          rawContent: entry.rawContent,
        );
        _db.execute(
          '''
          INSERT INTO words (
            id,
            wordbook_id,
            entry_uid,
            word,
            meaning,
            primary_gloss,
            search_word,
            search_meaning,
            search_details,
            search_word_compact,
            search_details_compact,
            schema_version,
            source_payload_json,
            sort_index,
            extension_json,
            entry_json
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          <Object?>[
            entry.id,
            entry.wordbookId,
            row['entry_uid'],
            prepared.row['word'],
            prepared.row['meaning'],
            row['primary_gloss'],
            prepared.row['search_word'],
            prepared.row['search_meaning'],
            prepared.row['search_details'],
            prepared.row['search_word_compact'],
            prepared.row['search_details_compact'],
            row['schema_version'],
            row['source_payload_json'],
            row['sort_index'] ?? 0,
            prepared.row['extension_json'],
            prepared.row['entry_json'],
          ],
        );
      }
      _db.execute('DROP TABLE words_legacy_cache;');
      _db.execute(
        'CREATE INDEX IF NOT EXISTS idx_words_wordbook ON words(wordbook_id);',
      );
      _db.execute('CREATE INDEX IF NOT EXISTS idx_words_word ON words(word);');
      _db.execute(
        'CREATE INDEX IF NOT EXISTS idx_words_search_word ON words(wordbook_id, search_word);',
      );
      _db.execute(
        'CREATE INDEX IF NOT EXISTS idx_words_search_meaning ON words(wordbook_id, search_meaning);',
      );
      _db.execute(
        'CREATE INDEX IF NOT EXISTS idx_words_search_details ON words(wordbook_id, search_details);',
      );
      _db.execute(
        'CREATE INDEX IF NOT EXISTS idx_words_search_word_compact ON words(wordbook_id, search_word_compact);',
      );
      _db.execute(
        'CREATE INDEX IF NOT EXISTS idx_words_search_details_compact ON words(wordbook_id, search_details_compact);',
      );
    } finally {
      _db.execute('PRAGMA foreign_keys = ON;');
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

  Future<void> syncBuiltInWordbooksCatalogIfNeeded() async {
    await syncBuiltInWordbooksCatalog();
  }

  Future<void> syncBuiltInWordbooksCatalog() async {
    final hiddenPaths = _readHiddenBuiltInWordbookPaths();
    final configs = await _builtInWordbookSource.listBuiltInWordbooks();
    final visibleConfigs = <String, BuiltInWordbookConfig>{
      for (final config in configs)
        if (!hiddenPaths.contains(config.path)) config.path: config,
    };
    final existingRows = _selectMaps(
      '''
      SELECT *
      FROM wordbooks
      WHERE path LIKE ?
      ORDER BY id ASC
      ''',
      <Object?>['$_dictBuiltinPathPrefix%'],
    );

    _runInTransaction<void>(() {
      final existingByPath = <String, Map<String, Object?>>{
        for (final row in existingRows) '${row['path'] ?? ''}': row,
      };

      for (final entry in visibleConfigs.entries) {
        final path = entry.key;
        final config = entry.value;
        final existing = existingByPath[path];
        if (existing == null) {
          _db.execute(
            '''
            INSERT INTO wordbooks (name, path, word_count, schema_version, metadata_json)
            VALUES (?, ?, 0, NULL, NULL)
            ''',
            <Object?>[config.name, config.path],
          );
          continue;
        }

        final currentName = sanitizeDisplayText('${existing['name'] ?? ''}');
        final hasLoadedMetadata =
            _sanitizeNullableText(existing['metadata_json']) != null &&
            ((existing['word_count'] as num?)?.toInt() ?? 0) > 0;
        final nextName = hasLoadedMetadata ? currentName : config.name;
        if (nextName != currentName) {
          _db.execute('UPDATE wordbooks SET name = ? WHERE id = ?', <Object?>[
            nextName,
            existing['id'],
          ]);
        }
      }

      for (final row in existingRows) {
        final path = '${row['path'] ?? ''}';
        if (visibleConfigs.containsKey(path)) {
          continue;
        }
        _db.execute('DELETE FROM wordbooks WHERE id = ?', <Object?>[row['id']]);
      }
    });
  }

  bool isLazyBuiltInPath(String path) =>
      path.startsWith(_dictBuiltinPathPrefix);

  Future<int> ensureBuiltInWordbookLoaded(
    String path, {
    BuiltInWordbookLoadProgressCallback? onProgress,
  }) async {
    final existingFuture = _builtInWordbookLoadFutures[path];
    if (existingFuture != null) {
      return existingFuture;
    }

    final future = () async {
      final existing = _selectOne(
        'SELECT id, word_count FROM wordbooks WHERE path = ?',
        <Object?>[path],
      );
      final existingId = (existing?['id'] as num?)?.toInt();
      final existingWordCount = ((existing?['word_count'] as num?) ?? 0)
          .toInt();
      if (existingId != null && existingId > 0 && existingWordCount > 0) {
        onProgress?.call(
          const BuiltInWordbookLoadProgress(
            stage: BuiltInWordbookLoadStage.completed,
            progress: 1,
          ),
        );
        return existingId;
      }

      final configs = await _builtInWordbookSource.listBuiltInWordbooks();
      BuiltInWordbookConfig? config;
      for (final item in configs) {
        if (item.path == path) {
          config = item;
          break;
        }
      }
      if (config == null) {
        throw StateError('未找到内置词本资源: $path');
      }

      final byteStream = await _builtInWordbookSource
          .openBuiltInWordbookByteStream(
            config,
            onProgress: (progress) {
              final totalBytes = progress.totalBytes;
              final ratio = totalBytes <= 0
                  ? null
                  : (progress.receivedBytes / totalBytes).clamp(0.0, 1.0);
              onProgress?.call(
                BuiltInWordbookLoadProgress(
                  stage: BuiltInWordbookLoadStage.downloading,
                  progress: ratio,
                  receivedBytes: progress.receivedBytes,
                  totalBytes: progress.totalBytes,
                ),
              );
            },
          );

      await importWordbookJsonByteStreamAsync(
        sourcePath: path,
        name: config.name,
        byteStream: byteStream,
        gzipped: config.sourcePath.toLowerCase().endsWith('.gz'),
        onProgress: (processedEntries, totalEntries) {
          final ratio = totalEntries == null || totalEntries <= 0
              ? null
              : (processedEntries / totalEntries).clamp(0.0, 1.0);
          onProgress?.call(
            BuiltInWordbookLoadProgress(
              stage: BuiltInWordbookLoadStage.processing,
              progress: ratio,
              processedEntries: processedEntries,
              totalEntries: totalEntries,
            ),
          );
        },
      );

      onProgress?.call(
        const BuiltInWordbookLoadProgress(
          stage: BuiltInWordbookLoadStage.completed,
          progress: 1,
        ),
      );
      final importedRow = _selectOne(
        'SELECT id FROM wordbooks WHERE path = ?',
        <Object?>[path],
      );
      final importedId = (importedRow?['id'] as num?)?.toInt();
      if (importedId == null || importedId <= 0) {
        throw StateError('内置词本导入完成后未找到词本记录: $path');
      }
      return importedId;
    }();

    _builtInWordbookLoadFutures[path] = future;
    try {
      return await future;
    } finally {
      _builtInWordbookLoadFutures.remove(path);
    }
  }

  Set<String> _readHiddenBuiltInWordbookPaths() {
    final raw = getSetting(_hiddenBuiltInWordbooksSettingKey);
    if ((raw ?? '').trim().isEmpty) {
      return <String>{};
    }
    try {
      final decoded = jsonDecode(raw!);
      if (decoded is! List) {
        return <String>{};
      }
      return decoded
          .map((item) => sanitizeDisplayText('$item'))
          .where(
            (item) =>
                item.isNotEmpty && item.startsWith(_dictBuiltinPathPrefix),
          )
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  void _writeHiddenBuiltInWordbookPaths(Set<String> hiddenPaths) {
    final normalized =
        hiddenPaths
            .map(sanitizeDisplayText)
            .where(
              (item) =>
                  item.isNotEmpty && item.startsWith(_dictBuiltinPathPrefix),
            )
            .toList(growable: false)
          ..sort();
    setSetting(_hiddenBuiltInWordbooksSettingKey, jsonEncode(normalized));
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
      'SELECT * FROM words WHERE wordbook_id = ? ORDER BY $_wordOrderClause LIMIT ? OFFSET ?',
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

  List<WordEntry> getWordsLite(
    int wordbookId, {
    int limit = 100000,
    int offset = 0,
  }) {
    final rows = _selectMaps(
      'SELECT * FROM words WHERE wordbook_id = ? ORDER BY $_wordOrderClause LIMIT ? OFFSET ?',
      <Object?>[wordbookId, limit, offset],
    );
    return rows.map(_wordEntryLiteFromRow).toList(growable: false);
  }

  List<String> getWordTexts(
    int wordbookId, {
    int limit = 100000,
    int offset = 0,
  }) {
    final rows = _selectMaps(
      'SELECT word FROM words WHERE wordbook_id = ? ORDER BY $_wordOrderClause LIMIT ? OFFSET ?',
      <Object?>[wordbookId, limit, offset],
    );
    return rows
        .map((row) => sanitizeDisplayText('${row['word'] ?? ''}'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
  }

  List<WordEntry> searchWords(
    int wordbookId, {
    required String query,
    required String mode,
    int limit = 100000,
    int offset = 0,
  }) {
    final (whereClause, params) = _buildSearchWhereClause(
      wordbookId: wordbookId,
      query: query,
      mode: mode,
    );
    if (params.length == 1) {
      return getWords(wordbookId, limit: limit, offset: offset);
    }

    final rows = _selectMaps(
      '''
      SELECT * FROM words
      WHERE $whereClause
      ORDER BY $_wordOrderClause
      LIMIT ? OFFSET ?
      ''',
      <Object?>[...params, limit, offset],
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
          return fields.isEmpty ? entry : entry.copyWith(fields: fields);
        })
        .toList(growable: false);
  }

  List<WordEntry> searchWordsLite(
    int wordbookId, {
    required String query,
    required String mode,
    int limit = 100000,
    int offset = 0,
  }) {
    final (whereClause, params) = _buildSearchWhereClause(
      wordbookId: wordbookId,
      query: query,
      mode: mode,
    );
    if (params.length == 1) {
      return getWordsLite(wordbookId, limit: limit, offset: offset);
    }

    final rows = _selectMaps(
      '''
      SELECT * FROM words
      WHERE $whereClause
      ORDER BY $_wordOrderClause
      LIMIT ? OFFSET ?
      ''',
      <Object?>[...params, limit, offset],
    );
    return rows.map(_wordEntryLiteFromRow).toList(growable: false);
  }

  WordEntry? hydrateWordEntry(WordEntry entry) {
    final wordId = entry.id;
    if (wordId != null && wordId > 0) {
      final row = _selectOne(
        'SELECT * FROM words WHERE id = ? LIMIT 1',
        <Object?>[wordId],
      );
      if (row != null) {
        return _inflateWordEntry(row);
      }
    }

    final wordbookId = entry.wordbookId;
    if (wordbookId <= 0) {
      return null;
    }

    final normalizedEntryUid = _sanitizeNullableText(entry.entryUid);
    if (normalizedEntryUid != null) {
      final row = _selectOne(
        '''
        SELECT *
        FROM words
        WHERE wordbook_id = ? AND entry_uid = ?
        ORDER BY $_wordOrderClause
        LIMIT 1
        ''',
        <Object?>[wordbookId, normalizedEntryUid],
      );
      if (row != null) {
        return _inflateWordEntry(row);
      }
    }

    final normalizedWord = sanitizeDisplayText(entry.word);
    if (normalizedWord.isEmpty) {
      return null;
    }

    final rows = _selectMaps(
      '''
      SELECT *
      FROM words
      WHERE wordbook_id = ? AND word = ?
      ORDER BY $_wordOrderClause
      LIMIT 32
      ''',
      <Object?>[wordbookId, normalizedWord],
    );
    for (final row in rows) {
      final candidate = _inflateWordEntry(row);
      if (candidate.sameEntryAs(entry)) {
        return candidate;
      }
    }

    if (rows.length == 1) {
      return _inflateWordEntry(rows.first);
    }
    return null;
  }

  int countSearchWords(
    int wordbookId, {
    required String query,
    required String mode,
  }) {
    final (whereClause, params) = _buildSearchWhereClause(
      wordbookId: wordbookId,
      query: query,
      mode: mode,
    );
    final row = _selectOne(
      'SELECT COUNT(*) AS count FROM words WHERE $whereClause',
      params,
    );
    return ((row?['count'] as num?) ?? 0).toInt();
  }

  int? findSearchOffsetByPrefix(
    int wordbookId, {
    required String prefix,
    required String query,
    required String mode,
  }) {
    final normalizedPrefix = search_text.normalizeJumpText(prefix);
    if (normalizedPrefix.isEmpty) {
      return null;
    }
    final (whereClause, params) = _buildSearchWhereClause(
      wordbookId: wordbookId,
      query: query,
      mode: mode,
    );
    final target = _selectOne(
      '''
      SELECT id
      FROM words
      WHERE $whereClause
        AND search_word_compact LIKE ?
      ORDER BY $_wordOrderClause
      LIMIT 1
      ''',
      <Object?>[
        ...params,
        '${normalizedPrefix.replaceAll('%', '\\%').replaceAll('_', '\\_')}%',
      ],
    );
    final targetId = (target?['id'] as num?)?.toInt();
    if (targetId == null || targetId <= 0) {
      return null;
    }
    final row = _selectOne(
      'SELECT COUNT(*) AS count FROM words WHERE $whereClause AND id < ?',
      <Object?>[...params, targetId],
    );
    return ((row?['count'] as num?) ?? 0).toInt();
  }

  int? findSearchOffsetByInitial(
    int wordbookId, {
    required String initial,
    required String query,
    required String mode,
  }) {
    final normalized = initial.trim().toUpperCase();
    if (normalized.isEmpty) {
      return null;
    }
    final (whereClause, params) = _buildSearchWhereClause(
      wordbookId: wordbookId,
      query: query,
      mode: mode,
    );
    final target = normalized == '#'
        ? _selectOne('''
            SELECT id
            FROM words
            WHERE $whereClause
              AND (
                search_word_compact = ''
                OR substr(search_word_compact, 1, 1) < 'a'
                OR substr(search_word_compact, 1, 1) > 'z'
              )
            ORDER BY $_wordOrderClause
            LIMIT 1
            ''', params)
        : _selectOne(
            '''
            SELECT id
            FROM words
            WHERE $whereClause
              AND substr(search_word_compact, 1, 1) = ?
            ORDER BY $_wordOrderClause
            LIMIT 1
            ''',
            <Object?>[...params, normalized.toLowerCase()],
          );
    final targetId = (target?['id'] as num?)?.toInt();
    if (targetId == null || targetId <= 0) {
      return null;
    }
    final row = _selectOne(
      'SELECT COUNT(*) AS count FROM words WHERE $whereClause AND id < ?',
      <Object?>[...params, targetId],
    );
    return ((row?['count'] as num?) ?? 0).toInt();
  }

  int? findSearchOffsetByWordId(
    int wordbookId, {
    required int wordId,
    required String query,
    required String mode,
  }) {
    if (wordId <= 0) {
      return null;
    }
    final (whereClause, params) = _buildSearchWhereClause(
      wordbookId: wordbookId,
      query: query,
      mode: mode,
    );
    final exists = _selectOne(
      'SELECT id FROM words WHERE $whereClause AND id = ? LIMIT 1',
      <Object?>[...params, wordId],
    );
    if (exists == null) {
      return null;
    }
    final row = _selectOne(
      'SELECT COUNT(*) AS count FROM words WHERE $whereClause AND id < ?',
      <Object?>[...params, wordId],
    );
    return ((row?['count'] as num?) ?? 0).toInt();
  }

  (String, List<Object?>) _buildSearchWhereClause({
    required int wordbookId,
    required String query,
    required String mode,
  }) {
    final normalizedQuery = search_text.normalizeSearchText(query);
    if (normalizedQuery.isEmpty) {
      return ('wordbook_id = ?', <Object?>[wordbookId]);
    }
    final likeQuery = _buildContainsLikePattern(normalizedQuery);
    final fuzzyLikeQuery = search_text.buildFuzzySqlLikePattern(query);
    final resolvedFuzzyPattern = fuzzyLikeQuery.isEmpty
        ? likeQuery
        : fuzzyLikeQuery;
    return switch (mode.trim()) {
      'word' => (
        'wordbook_id = ? AND search_word LIKE ?',
        <Object?>[wordbookId, likeQuery],
      ),
      'meaning' => (
        'wordbook_id = ? AND (COALESCE(search_meaning, \'\') LIKE ? OR COALESCE(search_details, \'\') LIKE ?)',
        <Object?>[wordbookId, likeQuery, likeQuery],
      ),
      'fuzzy' => (
        'wordbook_id = ? AND (search_word_compact LIKE ? OR COALESCE(search_details_compact, \'\') LIKE ?)',
        <Object?>[wordbookId, resolvedFuzzyPattern, resolvedFuzzyPattern],
      ),
      _ => (
        'wordbook_id = ? AND (search_word LIKE ? OR COALESCE(search_meaning, \'\') LIKE ? OR COALESCE(search_details, \'\') LIKE ?)',
        <Object?>[wordbookId, likeQuery, likeQuery, likeQuery],
      ),
    };
  }

  WordEntry? findJumpWordByPrefix(
    int wordbookId, {
    required String prefix,
    required String query,
    required String mode,
  }) {
    final normalizedPrefix = search_text.normalizeJumpText(prefix);
    if (normalizedPrefix.isEmpty) {
      return null;
    }
    final (whereClause, params) = _buildSearchWhereClause(
      wordbookId: wordbookId,
      query: query,
      mode: mode,
    );
    final row = _selectOne(
      '''
      SELECT *
      FROM words
      WHERE $whereClause
        AND search_word_compact LIKE ?
      ORDER BY $_wordOrderClause
      LIMIT 1
      ''',
      <Object?>[
        ...params,
        '${normalizedPrefix.replaceAll('%', '\\%').replaceAll('_', '\\_')}%',
      ],
    );
    if (row == null) {
      return null;
    }
    return _inflateWordEntry(row);
  }

  WordEntry? findJumpWordByInitial(
    int wordbookId, {
    required String initial,
    required String query,
    required String mode,
  }) {
    final normalized = initial.trim().toUpperCase();
    if (normalized.isEmpty) {
      return null;
    }
    final (whereClause, params) = _buildSearchWhereClause(
      wordbookId: wordbookId,
      query: query,
      mode: mode,
    );
    final row = normalized == '#'
        ? _selectOne('''
            SELECT *
            FROM words
            WHERE $whereClause
              AND (
                search_word_compact = ''
                OR substr(search_word_compact, 1, 1) < 'a'
                OR substr(search_word_compact, 1, 1) > 'z'
              )
            ORDER BY $_wordOrderClause
            LIMIT 1
            ''', params)
        : _selectOne(
            '''
            SELECT *
            FROM words
            WHERE $whereClause
              AND substr(search_word_compact, 1, 1) = ?
            ORDER BY $_wordOrderClause
            LIMIT 1
            ''',
            <Object?>[...params, normalized.toLowerCase()],
          );
    if (row == null) {
      return null;
    }
    return _inflateWordEntry(row);
  }

  WordEntry _inflateWordEntry(Map<String, Object?> row) {
    final entry = WordEntry.fromMap(row);
    final wordId = (row['id'] as num?)?.toInt();
    if (wordId == null || wordId <= 0) {
      return entry;
    }
    final fieldsByWordId = _getWordFieldsByWordIds(<int>[wordId]);
    final fields = fieldsByWordId[wordId] ?? const <WordFieldItem>[];
    return fields.isEmpty ? entry : entry.copyWith(fields: fields);
  }

  String _buildContainsLikePattern(String raw) {
    final escaped = raw
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');
    return '%$escaped%';
  }

  List<List<int>> _chunkSqlIntIds(Iterable<int> ids) {
    final normalized = ids
        .where((id) => id > 0)
        .toSet()
        .toList(growable: false);
    if (normalized.isEmpty) {
      return const <List<int>>[];
    }
    final chunks = <List<int>>[];
    for (
      var start = 0;
      start < normalized.length;
      start += _maxSqlVariablesPerStatement
    ) {
      final end = math.min(
        start + _maxSqlVariablesPerStatement,
        normalized.length,
      );
      chunks.add(normalized.sublist(start, end));
    }
    return chunks;
  }

  List<Map<String, Object?>> _selectMapsByChunkedIntIds({
    required Iterable<int> ids,
    required String selectSqlPrefix,
    required String whereColumn,
    String? orderByClause,
  }) {
    final chunks = _chunkSqlIntIds(ids);
    if (chunks.isEmpty) {
      return const <Map<String, Object?>>[];
    }
    final rows = <Map<String, Object?>>[];
    final orderSql = (orderByClause ?? '').trim().isEmpty
        ? ''
        : ' ORDER BY ${orderByClause!.trim()}';
    for (final chunk in chunks) {
      final placeholders = List<String>.filled(chunk.length, '?').join(', ');
      rows.addAll(
        _selectMaps(
          '$selectSqlPrefix WHERE $whereColumn IN ($placeholders)$orderSql',
          chunk.cast<Object?>(),
        ),
      );
    }
    return rows;
  }

  Map<int, List<WordFieldItem>> _getWordFieldsByWordIds(Iterable<int> wordIds) {
    final ids = wordIds.where((id) => id > 0).toSet().toList(growable: false);
    if (ids.isEmpty) {
      return const <int, List<WordFieldItem>>{};
    }
    final rows = _selectMapsByChunkedIntIds(
      ids: ids,
      selectSqlPrefix: '''
      SELECT id, word_id, field_key, field_label, field_value_json, style_json, sort_order
      FROM word_fields
      ''',
      whereColumn: 'word_id',
      orderByClause: 'word_id ASC, sort_order ASC, id ASC',
    );
    final fieldIds = rows
        .map((row) => (row['id'] as num?)?.toInt())
        .whereType<int>()
        .where((id) => id > 0)
        .toList(growable: false);
    final stylesByFieldId = _getWordFieldStylesByFieldIds(fieldIds);
    final tagsByFieldId = _getWordFieldTagsByFieldIds(fieldIds);
    final mediaByFieldId = _getWordFieldMediaByFieldIds(fieldIds);
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
      final fieldId = (row['id'] as num?)?.toInt();
      final fieldWithSubtables = field.copyWith(
        style: fieldId == null
            ? field.style
            : (stylesByFieldId[fieldId] ?? field.style),
        tags: fieldId == null
            ? field.tags
            : (tagsByFieldId[fieldId] ?? field.tags),
        media: fieldId == null
            ? field.media
            : (mediaByFieldId[fieldId] ?? field.media),
      );
      output
          .putIfAbsent(wordId, () => <WordFieldItem>[])
          .add(fieldWithSubtables);
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

  Map<int, WordFieldStyle> _getWordFieldStylesByFieldIds(
    Iterable<int> fieldIds,
  ) {
    final ids = fieldIds.where((id) => id > 0).toSet().toList(growable: false);
    if (ids.isEmpty) {
      return const <int, WordFieldStyle>{};
    }
    final rows = _selectMapsByChunkedIntIds(
      ids: ids,
      selectSqlPrefix: '''
      SELECT word_field_id, background_hex, border_hex, text_hex, accent_hex
      FROM word_field_styles
      ''',
      whereColumn: 'word_field_id',
    );
    return <int, WordFieldStyle>{
      for (final row in rows)
        ((row['word_field_id'] as num?) ?? 0).toInt(): WordFieldStyle(
          backgroundHex: '${row['background_hex'] ?? ''}'.trim(),
          borderHex: '${row['border_hex'] ?? ''}'.trim(),
          textHex: '${row['text_hex'] ?? ''}'.trim(),
          accentHex: '${row['accent_hex'] ?? ''}'.trim(),
        ),
    };
  }

  Map<int, List<String>> _getWordFieldTagsByFieldIds(Iterable<int> fieldIds) {
    final ids = fieldIds.where((id) => id > 0).toSet().toList(growable: false);
    if (ids.isEmpty) {
      return const <int, List<String>>{};
    }
    final rows = _selectMapsByChunkedIntIds(
      ids: ids,
      selectSqlPrefix: '''
      SELECT word_field_id, tag
      FROM word_field_tags
      ''',
      whereColumn: 'word_field_id',
      orderByClause: 'word_field_id ASC, sort_order ASC, id ASC',
    );
    final output = <int, List<String>>{};
    for (final row in rows) {
      final fieldId = (row['word_field_id'] as num?)?.toInt();
      final tag = '${row['tag'] ?? ''}'.trim();
      if (fieldId == null || fieldId <= 0 || tag.isEmpty) {
        continue;
      }
      output.putIfAbsent(fieldId, () => <String>[]).add(tag);
    }
    return output;
  }

  Map<int, List<WordFieldMediaItem>> _getWordFieldMediaByFieldIds(
    Iterable<int> fieldIds,
  ) {
    final ids = fieldIds.where((id) => id > 0).toSet().toList(growable: false);
    if (ids.isEmpty) {
      return const <int, List<WordFieldMediaItem>>{};
    }
    final rows = _selectMapsByChunkedIntIds(
      ids: ids,
      selectSqlPrefix: '''
      SELECT word_field_id, media_type, media_source, media_label, mime_type
      FROM word_field_media
      ''',
      whereColumn: 'word_field_id',
      orderByClause: 'word_field_id ASC, sort_order ASC, id ASC',
    );
    final output = <int, List<WordFieldMediaItem>>{};
    for (final row in rows) {
      final fieldId = (row['word_field_id'] as num?)?.toInt();
      if (fieldId == null || fieldId <= 0) {
        continue;
      }
      final type = WordFieldMediaType.values.firstWhere(
        (item) => item.name == '${row['media_type'] ?? 'link'}'.trim(),
        orElse: () => WordFieldMediaType.link,
      );
      final source = '${row['media_source'] ?? ''}'.trim();
      if (source.isEmpty) {
        continue;
      }
      output
          .putIfAbsent(fieldId, () => <WordFieldMediaItem>[])
          .add(
            WordFieldMediaItem(
              type: type,
              source: source,
              label: '${row['media_label'] ?? ''}'.trim(),
              mimeType: '${row['mime_type'] ?? ''}'.trim().isEmpty
                  ? null
                  : '${row['mime_type']}'.trim(),
            ),
          );
    }
    return output;
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
    final rows = _selectMapsByChunkedIntIds(
      ids: ids,
      selectSqlPrefix: 'SELECT * FROM progress',
      whereColumn: 'word_id',
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

  void insertWordMemoryEvent({
    required int wordId,
    required String eventKind,
    required int quality,
    List<String> weakReasonIds = const <String>[],
    String? sessionTitle,
    DateTime? createdAt,
  }) {
    if (!_initialized || wordId <= 0) {
      return;
    }
    final normalizedReasons = weakReasonIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    _db.execute(
      '''
      INSERT INTO word_memory_events (
        word_id,
        event_kind,
        quality,
        weak_reasons_json,
        session_title,
        created_at
      ) VALUES (?, ?, ?, ?, ?, ?)
      ''',
      <Object?>[
        wordId,
        eventKind.trim(),
        quality,
        normalizedReasons.isEmpty ? null : jsonEncode(normalizedReasons),
        sessionTitle?.trim(),
        (createdAt ?? DateTime.now()).toIso8601String(),
      ],
    );
  }

  List<Map<String, Object?>> getWordMemoryEvents(int wordId, {int limit = 50}) {
    if (!_initialized || wordId <= 0) {
      return const <Map<String, Object?>>[];
    }
    return _selectMaps(
      '''
      SELECT *
      FROM word_memory_events
      WHERE word_id = ?
      ORDER BY created_at DESC, id DESC
      LIMIT ?
      ''',
      <Object?>[wordId, limit],
    );
  }

  int importWordbookJsonText({
    required String sourcePath,
    required String name,
    required String content,
    bool replaceExisting = true,
    void Function(int processedEntries, int? totalEntries)? onProgress,
  }) {
    final descriptor = _importService.inspectJsonText(
      content,
      fallbackName: name,
    );
    final resolvedName = _resolveImportedWordbookName(
      sourcePath: sourcePath,
      requestedName: name,
      descriptorName: descriptor.bookName,
    );
    return _runInTransaction<int>(() {
      final wordbookId = _upsertImportedWordbookRow(
        sourcePath: sourcePath,
        name: resolvedName,
        schemaVersion: descriptor.schemaVersion,
        metadataJson: descriptor.metadataJson,
        replaceExisting: replaceExisting,
      );
      final statements = replaceExisting
          ? _openWordImportInsertStatements()
          : null;
      var imported = 0;
      try {
        _importService.processJsonText(
          content,
          onPayload: (payload) {
            final accepted = replaceExisting
                ? _insertWordWithStatements(
                    wordbookId,
                    payload,
                    statements: statements!,
                  )
                : upsertWord(wordbookId, payload, refreshWordbookCount: false);
            if (accepted) {
              imported += 1;
            }
          },
          onProgress: onProgress,
        );
      } finally {
        statements?.dispose();
      }
      _refreshWordbookCount(wordbookId);
      return imported;
    });
  }

  Future<int> importWordbookJsonTextAsync({
    required String sourcePath,
    required String name,
    required String content,
    bool replaceExisting = true,
    void Function(int processedEntries, int? totalEntries)? onProgress,
    int yieldEvery = 180,
  }) async {
    final descriptor = _importService.inspectJsonText(
      content,
      fallbackName: name,
    );
    final resolvedName = _resolveImportedWordbookName(
      sourcePath: sourcePath,
      requestedName: name,
      descriptorName: descriptor.bookName,
    );
    return _runInTransactionAsync<int>(() async {
      final wordbookId = _upsertImportedWordbookRow(
        sourcePath: sourcePath,
        name: resolvedName,
        schemaVersion: descriptor.schemaVersion,
        metadataJson: descriptor.metadataJson,
        replaceExisting: replaceExisting,
      );
      final statements = replaceExisting
          ? _openWordImportInsertStatements()
          : null;
      var imported = 0;
      try {
        await _importService.processJsonTextAsync(
          content,
          onPayload: (payload) {
            final accepted = replaceExisting
                ? _insertWordWithStatements(
                    wordbookId,
                    payload,
                    statements: statements!,
                  )
                : upsertWord(wordbookId, payload, refreshWordbookCount: false);
            if (accepted) {
              imported += 1;
            }
          },
          onProgress: onProgress,
          yieldEvery: yieldEvery,
        );
      } finally {
        statements?.dispose();
      }
      _refreshWordbookCount(wordbookId);
      return imported;
    });
  }

  Future<int> importWordbookJsonByteStreamAsync({
    required String sourcePath,
    required String name,
    required Stream<List<int>> byteStream,
    bool gzipped = false,
    bool replaceExisting = true,
    void Function(int processedEntries, int? totalEntries)? onProgress,
    int yieldEvery = 180,
  }) async {
    final content = await _importService.readJsonByteStreamAsString(
      byteStream,
      gzipped: gzipped,
    );
    return importWordbookJsonTextAsync(
      sourcePath: sourcePath,
      name: name,
      content: content,
      replaceExisting: replaceExisting,
      onProgress: onProgress,
      yieldEvery: yieldEvery,
    );
  }

  Future<int> importWordbook({
    required String sourcePath,
    required String name,
    required List<WordEntryPayload> entries,
    bool replaceExisting = true,
    void Function(int processedEntries, int? totalEntries)? onProgress,
  }) async {
    return _runInTransactionAsync<int>(() async {
      final wordbookId = _upsertImportedWordbookRow(
        sourcePath: sourcePath,
        name: _resolveImportedWordbookName(
          sourcePath: sourcePath,
          requestedName: name,
          descriptorName: null,
        ),
        schemaVersion: _deriveSchemaVersionFromPayloads(entries),
        metadataJson: null,
        replaceExisting: replaceExisting,
      );
      final total = entries.length;
      onProgress?.call(0, total);
      final statements = replaceExisting
          ? _openWordImportInsertStatements()
          : null;
      var imported = 0;
      try {
        for (var index = 0; index < entries.length; index += 1) {
          final payload = entries[index];
          final accepted = replaceExisting
              ? _insertWordWithStatements(
                  wordbookId,
                  payload,
                  statements: statements!,
                )
              : upsertWord(wordbookId, payload, refreshWordbookCount: false);
          if (accepted) {
            imported += 1;
          }
          onProgress?.call(index + 1, total);
        }
      } finally {
        statements?.dispose();
      }
      _refreshWordbookCount(wordbookId);
      return imported;
    });
  }

  Future<int> importWordbookAsync({
    required String sourcePath,
    required String name,
    required List<WordEntryPayload> entries,
    bool replaceExisting = true,
    void Function(int processedEntries, int? totalEntries)? onProgress,
    int yieldEvery = 180,
  }) async {
    return _runInTransactionAsync<int>(() async {
      final wordbookId = _upsertImportedWordbookRow(
        sourcePath: sourcePath,
        name: _resolveImportedWordbookName(
          sourcePath: sourcePath,
          requestedName: name,
          descriptorName: null,
        ),
        schemaVersion: _deriveSchemaVersionFromPayloads(entries),
        metadataJson: null,
        replaceExisting: replaceExisting,
      );
      final total = entries.length;
      final resolvedYieldEvery = yieldEvery < 1 ? 1 : yieldEvery;
      onProgress?.call(0, total);
      final statements = replaceExisting
          ? _openWordImportInsertStatements()
          : null;
      var imported = 0;
      try {
        for (var index = 0; index < entries.length; index += 1) {
          final payload = entries[index];
          final accepted = replaceExisting
              ? _insertWordWithStatements(
                  wordbookId,
                  payload,
                  statements: statements!,
                )
              : upsertWord(wordbookId, payload, refreshWordbookCount: false);
          if (accepted) {
            imported += 1;
          }
          onProgress?.call(index + 1, total);
          if ((index + 1) % resolvedYieldEvery == 0) {
            await Future<void>.delayed(Duration.zero);
          }
        }
      } finally {
        statements?.dispose();
      }
      _refreshWordbookCount(wordbookId);
      return imported;
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
      'SELECT id, path FROM wordbooks WHERE id = ?',
      <Object?>[wordbookId],
    );
    if (wordbook == null) {
      throw StateError('单词本不存在');
    }
    final path = '${wordbook['path'] ?? ''}';
    if (path == 'builtin:favorites' || path == 'builtin:task') {
      throw StateError('系统单词本不允许删除');
    }
    if (path.startsWith(_dictBuiltinPathPrefix)) {
      final hiddenPaths = _readHiddenBuiltInWordbookPaths()..add(path);
      _runInTransaction<void>(() {
        _writeHiddenBuiltInWordbookPaths(hiddenPaths);
        _db.execute('DELETE FROM wordbooks WHERE id = ?', <Object?>[
          wordbookId,
        ]);
      });
      return;
    }
    deleteWordbook(wordbookId);
  }

  bool upsertWord(
    int wordbookId,
    WordEntryPayload payload, {
    bool refreshWordbookCount = true,
  }) {
    final word = payload.word.trim();
    if (word.isEmpty) throw ArgumentError('单词不能为空');

    final existing = _findExistingWordRow(
      wordbookId,
      word: word,
      entryUid: payload.entryUid,
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
    final prepared = _buildStoredWordRecord(
      id: existingEntry.id,
      wordbookId: wordbookId,
      word: word,
      fields: normalizedFields,
      rawContent: normalizedRawContent,
      entryUid: payload.entryUid ?? existingEntry.entryUid,
      primaryGloss: payload.primaryGloss ?? existingEntry.primaryGloss,
      schemaVersion: payload.schemaVersion ?? existingEntry.schemaVersion,
      sourcePayloadJson:
          payload.sourcePayloadJson ?? existingEntry.sourcePayloadJson,
      sortIndex: payload.sortIndex ?? existingEntry.sortIndex,
    );

    _db.execute(
      '''
      UPDATE words SET
        meaning = ?,
        entry_uid = ?,
        primary_gloss = ?,
        search_word = ?,
        search_meaning = ?,
        search_details = ?,
        search_word_compact = ?,
        search_details_compact = ?,
        schema_version = ?,
        source_payload_json = ?,
        sort_index = ?,
        extension_json = ?,
        entry_json = ?
      WHERE id = ?
      ''',
      <Object?>[
        prepared.row['meaning'],
        prepared.entryUid,
        prepared.primaryGloss,
        prepared.row['search_word'],
        prepared.row['search_meaning'],
        prepared.row['search_details'],
        prepared.row['search_word_compact'],
        prepared.row['search_details_compact'],
        prepared.schemaVersion,
        prepared.sourcePayloadJson,
        prepared.sortIndex,
        prepared.row['extension_json'],
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
    final existing = _findExistingWordRow(
      wordbookId,
      word: payload.word.trim(),
      entryUid: payload.entryUid,
    );
    if (existing != null) throw StateError('该单词已存在');
    upsertWord(wordbookId, payload);
  }

  void updateWord({
    required int wordbookId,
    required String sourceWord,
    int? sourceWordId,
    String? sourceEntryUid,
    String? sourcePrimaryGloss,
    required WordEntryPayload payload,
  }) {
    final oldWord = sourceWord.trim();
    final nextWord = payload.word.trim().isEmpty
        ? oldWord
        : payload.word.trim();
    if (oldWord.isEmpty || nextWord.isEmpty) throw ArgumentError('单词不能为空');

    Map<String, Object?>? existing;
    if ((sourceWordId ?? 0) > 0) {
      existing = _selectOne(
        'SELECT * FROM words WHERE wordbook_id = ? AND id = ?',
        <Object?>[wordbookId, sourceWordId],
      );
    }
    existing ??= _findExistingWordRow(
      wordbookId,
      word: oldWord,
      entryUid: sourceEntryUid,
      primaryGloss: sourcePrimaryGloss,
    );
    if (existing == null) throw StateError('单词不存在');
    final existingId = (existing['id'] as num).toInt();

    if (oldWord != nextWord) {
      final conflict = _findExistingWordRow(
        wordbookId,
        word: nextWord,
        entryUid: payload.entryUid ?? sourceEntryUid,
      );
      final conflictId = (conflict?['id'] as num?)?.toInt();
      if (conflictId != null && conflictId != existingId) {
        throw StateError('目标单词已存在');
      }
    }

    final incomingRawContent = sanitizeDisplayText(payload.rawContent);
    final normalizedFields = mergeFieldItems(<WordFieldItem>[
      ...payload.fields,
      if (incomingRawContent.isNotEmpty)
        ...parseSectionedContent(incomingRawContent),
    ]);
    final prepared = _buildStoredWordRecord(
      id: existingId,
      wordbookId: wordbookId,
      word: nextWord,
      fields: normalizedFields,
      rawContent: incomingRawContent,
      entryUid:
          payload.entryUid ?? _sanitizeNullableText(existing['entry_uid']),
      primaryGloss:
          payload.primaryGloss ??
          _sanitizeNullableText(existing['primary_gloss']),
      schemaVersion:
          payload.schemaVersion ??
          _sanitizeNullableText(existing['schema_version']),
      sourcePayloadJson:
          payload.sourcePayloadJson ??
          _sanitizeNullableText(existing['source_payload_json']),
      sortIndex: payload.sortIndex ?? (existing['sort_index'] as num?)?.toInt(),
    );

    _db.execute(
      '''
      UPDATE words SET
        word = ?,
        meaning = ?,
        entry_uid = ?,
        primary_gloss = ?,
        search_word = ?,
        search_meaning = ?,
        search_details = ?,
        search_word_compact = ?,
        search_details_compact = ?,
        schema_version = ?,
        source_payload_json = ?,
        sort_index = ?,
        extension_json = ?,
        entry_json = ?
      WHERE id = ?
      ''',
      <Object?>[
        prepared.row['word'],
        prepared.row['meaning'],
        prepared.entryUid,
        prepared.primaryGloss,
        prepared.row['search_word'],
        prepared.row['search_meaning'],
        prepared.row['search_details'],
        prepared.row['search_word_compact'],
        prepared.row['search_details_compact'],
        prepared.schemaVersion,
        prepared.sourcePayloadJson,
        prepared.sortIndex,
        prepared.row['extension_json'],
        prepared.row['entry_json'],
        existingId,
      ],
    );
    _replaceWordFields(existingId, prepared.fields);

    _refreshWordbookCount(wordbookId);
  }

  void deleteWord(int wordbookId, String word) {
    _db.execute(
      'DELETE FROM words WHERE wordbook_id = ? AND word = ?',
      <Object?>[wordbookId, word],
    );
    _refreshWordbookCount(wordbookId);
  }

  void deleteWordByEntryIdentity(int wordbookId, WordEntry entry) {
    final normalizedEntryUid = sanitizeDisplayText(entry.entryUid ?? '');
    if (normalizedEntryUid.isNotEmpty) {
      _db.execute(
        'DELETE FROM words WHERE wordbook_id = ? AND entry_uid = ?',
        <Object?>[wordbookId, normalizedEntryUid],
      );
      _refreshWordbookCount(wordbookId);
      return;
    }

    final primaryGloss = sanitizeDisplayText(
      entry.primaryGloss ?? entry.summaryMeaningText,
    );
    if (primaryGloss.isNotEmpty) {
      _db.execute(
        '''
        DELETE FROM words
        WHERE wordbook_id = ? AND word = ? AND COALESCE(primary_gloss, meaning, '') = ?
        ''',
        <Object?>[wordbookId, entry.word, primaryGloss],
      );
      _refreshWordbookCount(wordbookId);
      return;
    }

    deleteWord(wordbookId, entry.word);
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
      final sourceWords = _buildWordEntryPayloadsForWordbook(sourceWordbookId);
      _db.execute(
        'INSERT INTO wordbooks (name, path, word_count) VALUES (?, ?, 0)',
        <Object?>[trimmed, 'export_${DateTime.now().millisecondsSinceEpoch}'],
      );
      final insertedId = _lastInsertId();
      for (final entry in sourceWords) {
        _insertWord(insertedId, entry);
      }
      _refreshWordbookCount(insertedId);
      return insertedId;
    });
  }

  Map<String, Object?>? _findExistingWordRow(
    int wordbookId, {
    required String word,
    String? entryUid,
    String? primaryGloss,
  }) {
    final normalizedEntryUid = sanitizeDisplayText(entryUid ?? '');
    if (normalizedEntryUid.isNotEmpty) {
      return _selectOne(
        'SELECT * FROM words WHERE wordbook_id = ? AND entry_uid = ?',
        <Object?>[wordbookId, normalizedEntryUid],
      );
    }
    final normalizedPrimaryGloss = sanitizeDisplayText(primaryGloss ?? '');
    if (normalizedPrimaryGloss.isNotEmpty) {
      return _selectOne(
        '''
        SELECT * FROM words
        WHERE wordbook_id = ? AND word = ? AND COALESCE(primary_gloss, meaning, '') = ?
        ''',
        <Object?>[wordbookId, word, normalizedPrimaryGloss],
      );
    }
    return _selectOne(
      'SELECT * FROM words WHERE wordbook_id = ? AND word = ?',
      <Object?>[wordbookId, word],
    );
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
    void Function(int processedEntries, int? totalEntries)? onProgress,
  }) async {
    return importWordbookFileAsync(
      filePath: filePath,
      name: name,
      onProgress: onProgress,
    );
  }

  Future<int> importWordbookFileAsync({
    required String filePath,
    required String name,
    void Function(int processedEntries, int? totalEntries)? onProgress,
  }) async {
    final normalizedPath = filePath.trim();
    if (normalizedPath.isEmpty) {
      throw ArgumentError('文件路径不能为空');
    }

    final normalizedLower = normalizedPath.toLowerCase();
    if (normalizedLower.endsWith('.json.gz') ||
        normalizedLower.endsWith('.gz')) {
      return importWordbookJsonByteStreamAsync(
        sourcePath: normalizedPath,
        name: name,
        byteStream: File(normalizedPath).openRead(),
        gzipped: true,
        onProgress: onProgress,
      );
    }

    if (normalizedLower.endsWith('.json') ||
        normalizedLower.endsWith('.jsonl')) {
      final content = await File(normalizedPath).readAsString();
      return importWordbookJsonTextAsync(
        sourcePath: normalizedPath,
        name: name,
        content: content,
        onProgress: onProgress,
      );
    }

    final entries = await _importService.parseFile(normalizedPath);
    return importWordbookAsync(
      sourcePath: normalizedPath,
      name: name,
      entries: entries,
      onProgress: onProgress,
    );
  }

  Future<int> importLegacyDatabase(String legacyDbPath) async {
    final normalizedPath = legacyDbPath.trim();
    if (normalizedPath.isEmpty) {
      throw ArgumentError('旧数据库路径不能为空');
    }
    final sourceFile = File(normalizedPath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('旧数据库文件不存在', normalizedPath);
    }

    final legacyDb = sqlite3.open(normalizedPath);
    try {
      final tables = legacyDb
          .select(
            "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name ASC",
          )
          .map((row) => '${row['name'] ?? ''}'.trim())
          .where((name) => name.isNotEmpty)
          .toSet();
      if (!tables.contains('words')) {
        throw StateError('旧数据库缺少 words 表，无法迁移');
      }

      final wordsTableInfo = legacyDb.select('PRAGMA table_info(words);');
      final wordsColumns = <String>{
        for (final row in wordsTableInfo) '${row['name'] ?? ''}'.trim(),
      };
      final allWordRows = _rowsAsMaps(legacyDb.select('SELECT * FROM words'));
      allWordRows.sort(_compareLegacyWordRows);

      final baseName = _deriveWordbookNameFromSourcePath(normalizedPath);
      var imported = 0;

      if (tables.contains('wordbooks') &&
          wordsColumns.contains('wordbook_id')) {
        final groupedRows = <int, List<Map<String, Object?>>>{};
        for (final row in allWordRows) {
          final legacyWordbookId = (row['wordbook_id'] as num?)?.toInt() ?? 0;
          groupedRows
              .putIfAbsent(legacyWordbookId, () => <Map<String, Object?>>[])
              .add(row);
        }
        final legacyWordbooks = _rowsAsMaps(
          legacyDb.select('SELECT * FROM wordbooks ORDER BY id ASC'),
        );
        for (final legacyWordbook in legacyWordbooks) {
          final legacyId = (legacyWordbook['id'] as num?)?.toInt() ?? 0;
          final payloads =
              (groupedRows[legacyId] ?? const <Map<String, Object?>>[])
                  .map(_legacyWordPayloadFromRow)
                  .whereType<WordEntryPayload>()
                  .toList(growable: false);
          if (payloads.isEmpty) {
            continue;
          }
          final legacyName = sanitizeDisplayText(
            '${legacyWordbook['name'] ?? ''}',
          );
          await importWordbookAsync(
            sourcePath:
                'legacy:${p.basenameWithoutExtension(normalizedPath)}:$legacyId',
            name: legacyName.isEmpty ? '$baseName-$legacyId' : legacyName,
            entries: payloads,
          );
          imported += payloads.length;
        }
      }

      if (imported > 0) {
        return imported;
      }

      final payloads = allWordRows
          .map(_legacyWordPayloadFromRow)
          .whereType<WordEntryPayload>()
          .toList(growable: false);
      if (payloads.isEmpty) {
        return 0;
      }
      await importWordbookAsync(
        sourcePath: 'legacy:${p.basenameWithoutExtension(normalizedPath)}',
        name: baseName.isEmpty ? 'Legacy Import' : baseName,
        entries: payloads,
      );
      return payloads.length;
    } finally {
      legacyDb.dispose();
    }
  }

  int _upsertImportedWordbookRow({
    required String sourcePath,
    required String name,
    required bool replaceExisting,
    String? schemaVersion,
    String? metadataJson,
  }) {
    final normalizedPath = sourcePath.trim();
    if (normalizedPath.isEmpty) {
      throw ArgumentError('sourcePath 不能为空');
    }
    final normalizedName = sanitizeDisplayText(name).trim().isEmpty
        ? _deriveWordbookNameFromSourcePath(normalizedPath)
        : sanitizeDisplayText(name).trim();
    final nextSchemaVersion = _sanitizeNullableText(schemaVersion);
    final nextMetadataJson = _sanitizeNullableText(metadataJson);
    final existing = _selectOne(
      'SELECT * FROM wordbooks WHERE path = ?',
      <Object?>[normalizedPath],
    );

    if (existing == null) {
      _db.execute(
        '''
        INSERT INTO wordbooks (name, path, word_count, schema_version, metadata_json)
        VALUES (?, ?, 0, ?, ?)
        ''',
        <Object?>[
          normalizedName,
          normalizedPath,
          nextSchemaVersion,
          nextMetadataJson,
        ],
      );
      if (normalizedPath.startsWith(_dictBuiltinPathPrefix)) {
        final hiddenPaths = _readHiddenBuiltInWordbookPaths();
        if (hiddenPaths.remove(normalizedPath)) {
          _writeHiddenBuiltInWordbookPaths(hiddenPaths);
        }
      }
      return _lastInsertId();
    }

    final wordbookId = (existing['id'] as num).toInt();
    final resolvedSchemaVersion =
        nextSchemaVersion ?? _sanitizeNullableText(existing['schema_version']);
    final resolvedMetadataJson =
        nextMetadataJson ?? _sanitizeNullableText(existing['metadata_json']);
    _db.execute(
      '''
      UPDATE wordbooks
      SET name = ?, schema_version = ?, metadata_json = ?
      WHERE id = ?
      ''',
      <Object?>[
        normalizedName,
        resolvedSchemaVersion,
        resolvedMetadataJson,
        wordbookId,
      ],
    );
    if (replaceExisting) {
      _db.execute('DELETE FROM words WHERE wordbook_id = ?', <Object?>[
        wordbookId,
      ]);
      _db.execute('UPDATE wordbooks SET word_count = 0 WHERE id = ?', <Object?>[
        wordbookId,
      ]);
    }
    if (normalizedPath.startsWith(_dictBuiltinPathPrefix)) {
      final hiddenPaths = _readHiddenBuiltInWordbookPaths();
      if (hiddenPaths.remove(normalizedPath)) {
        _writeHiddenBuiltInWordbookPaths(hiddenPaths);
      }
    }
    return wordbookId;
  }

  String _resolveImportedWordbookName({
    required String sourcePath,
    required String requestedName,
    required String? descriptorName,
  }) {
    final normalizedRequested = sanitizeDisplayText(requestedName).trim();
    final normalizedDescriptor = sanitizeDisplayText(
      descriptorName ?? '',
    ).trim();
    if (sourcePath.startsWith(_dictBuiltinPathPrefix)) {
      if (normalizedDescriptor.isNotEmpty) {
        return normalizedDescriptor;
      }
      if (normalizedRequested.isNotEmpty) {
        return normalizedRequested;
      }
      return _deriveWordbookNameFromSourcePath(sourcePath);
    }
    if (normalizedRequested.isNotEmpty) {
      return normalizedRequested;
    }
    if (normalizedDescriptor.isNotEmpty) {
      return normalizedDescriptor;
    }
    return _deriveWordbookNameFromSourcePath(sourcePath);
  }

  String _deriveWordbookNameFromSourcePath(String sourcePath) {
    final trimmed = sourcePath.trim();
    if (trimmed.isEmpty) {
      return 'Wordbook';
    }
    final basename = p.basename(trimmed);
    if (basename.trim().isEmpty) {
      return trimmed;
    }
    final lower = basename.toLowerCase();
    if (lower.endsWith('.json.gz')) {
      return basename.substring(0, basename.length - '.json.gz'.length);
    }
    if (lower.endsWith('.jsonl')) {
      return basename.substring(0, basename.length - '.jsonl'.length);
    }
    return p.basenameWithoutExtension(basename);
  }

  String? _deriveSchemaVersionFromPayloads(List<WordEntryPayload> entries) {
    final versions = entries
        .map((entry) => sanitizeDisplayText(entry.schemaVersion ?? ''))
        .where((item) => item.isNotEmpty)
        .toSet();
    if (versions.length != 1) {
      return null;
    }
    return versions.first;
  }

  Future<Map<int, int>> _restoreWordbooksFromExport(
    List<UserDataExportWordbook> wordbooks,
  ) async {
    final restoredWordIds = <int, int>{};
    for (final exportedWordbook in wordbooks) {
      final sourcePath = sanitizeDisplayText(exportedWordbook.wordbook.path);
      if (sourcePath.isEmpty) {
        continue;
      }
      final metadataJson =
          _sanitizeNullableText(exportedWordbook.wordbook.metadataJson) ??
          (exportedWordbook.standardBook == null
              ? null
              : jsonEncode(exportedWordbook.standardBook!.toJsonMap()));
      final schemaVersion = _sanitizeNullableText(
        exportedWordbook.wordbook.schemaVersion,
      );
      final payloads = exportedWordbook.words
          .map((word) => word.toRestorablePayload())
          .toList(growable: false);
      final wordbookId = _upsertImportedWordbookRow(
        sourcePath: sourcePath,
        name: sanitizeDisplayText(exportedWordbook.wordbook.name),
        schemaVersion: schemaVersion,
        metadataJson: metadataJson,
        replaceExisting: true,
      );

      final statements = _openWordImportInsertStatements();
      try {
        for (final payload in payloads) {
          _insertWordWithStatements(
            wordbookId,
            payload,
            statements: statements,
          );
        }
      } finally {
        statements.dispose();
      }
      _refreshWordbookCount(wordbookId);
      restoredWordIds.addAll(
        _mapRestoredWordIds(
          exportedWords: exportedWordbook.words,
          restoredWordbookId: wordbookId,
        ),
      );
    }
    return restoredWordIds;
  }

  Map<int, int> _mapRestoredWordIds({
    required List<UserDataExportWordRecord> exportedWords,
    required int restoredWordbookId,
  }) {
    final restoredRows = _selectMaps(
      'SELECT * FROM words WHERE wordbook_id = ? ORDER BY $_wordOrderClause',
      <Object?>[restoredWordbookId],
    );
    final restoredEntries = restoredRows
        .map(_inflateWordEntry)
        .toList(growable: false);

    final entryUidMap = <String, WordEntry>{};
    final wordGlossMap = <String, List<WordEntry>>{};
    final wordRawMap = <String, List<WordEntry>>{};
    final wordOnlyMap = <String, List<WordEntry>>{};

    void push(
      Map<String, List<WordEntry>> target,
      String key,
      WordEntry entry,
    ) {
      if (key.isEmpty) {
        return;
      }
      target.putIfAbsent(key, () => <WordEntry>[]).add(entry);
    }

    for (final entry in restoredEntries) {
      final normalizedEntryUid = sanitizeDisplayText(entry.entryUid ?? '');
      if (normalizedEntryUid.isNotEmpty) {
        entryUidMap[normalizedEntryUid] = entry;
      }
      final normalizedWord = sanitizeDisplayText(entry.word);
      final normalizedGloss = sanitizeDisplayText(
        entry.primaryGloss ?? entry.summaryMeaningText,
      );
      final normalizedRaw = sanitizeDisplayText(entry.rawContent);
      push(wordGlossMap, '$normalizedWord::$normalizedGloss', entry);
      push(wordRawMap, '$normalizedWord::$normalizedRaw', entry);
      push(wordOnlyMap, normalizedWord, entry);
    }

    final restoredIds = <int, int>{};
    final consumedIds = <int>{};

    WordEntry? takeFirstUnused(List<WordEntry>? entries) {
      if (entries == null) {
        return null;
      }
      for (final entry in entries) {
        final id = entry.id;
        if (id == null || consumedIds.contains(id)) {
          continue;
        }
        consumedIds.add(id);
        return entry;
      }
      return null;
    }

    for (final exportedWord in exportedWords) {
      final legacyId = exportedWord.id;
      if (legacyId == null || legacyId <= 0) {
        continue;
      }

      final normalizedEntryUid = sanitizeDisplayText(
        exportedWord.entryUid ?? '',
      );
      WordEntry? match;
      if (normalizedEntryUid.isNotEmpty) {
        final direct = entryUidMap[normalizedEntryUid];
        final directId = direct?.id;
        if (directId != null && !consumedIds.contains(directId)) {
          consumedIds.add(directId);
          match = direct;
        }
      }

      match ??= takeFirstUnused(
        wordGlossMap['${sanitizeDisplayText(exportedWord.word)}::${sanitizeDisplayText(exportedWord.primaryGloss ?? exportedWord.meaning ?? '')}'],
      );
      match ??= takeFirstUnused(
        wordRawMap['${sanitizeDisplayText(exportedWord.word)}::${sanitizeDisplayText(exportedWord.rawContent)}'],
      );
      match ??= takeFirstUnused(
        wordOnlyMap[sanitizeDisplayText(exportedWord.word)],
      );

      final restoredId = match?.id;
      if (restoredId != null && restoredId > 0) {
        restoredIds[legacyId] = restoredId;
      }
    }

    return restoredIds;
  }

  int? _resolveExistingRestoredWordId(int legacyWordId) {
    final row = _selectOne(
      'SELECT id FROM words WHERE id = ? LIMIT 1',
      <Object?>[legacyWordId],
    );
    return (row?['id'] as num?)?.toInt();
  }

  Map<String, Object?>? _tryDecodeJsonObjectMap(String? raw) {
    final normalized = sanitizeDisplayText(raw ?? '');
    if (normalized.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(normalized);
      if (decoded is Map<String, Object?>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.cast<String, Object?>();
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  WordEntryPayload? _legacyWordPayloadFromRow(Map<String, Object?> row) {
    final inferredWord = sanitizeDisplayText(
      '${row['word'] ?? row['term'] ?? row['title'] ?? row['headword'] ?? ''}',
    );
    if (inferredWord.isEmpty) {
      return null;
    }

    final entry = WordEntry.fromMap(<String, Object?>{
      ...row,
      'word': inferredWord,
    });
    final payload = entry.toPayload();
    if (payload.word.trim().isNotEmpty) {
      return payload;
    }

    final fallbackMeaning = sanitizeDisplayText(
      '${row['meaning'] ?? row['content'] ?? row['raw_content'] ?? ''}',
    );
    return WordEntryPayload(
      word: inferredWord,
      fields: fallbackMeaning.isEmpty
          ? const <WordFieldItem>[]
          : <WordFieldItem>[
              WordFieldItem(
                key: 'meaning',
                label: legacyFieldLabels['meaning'] ?? 'Meaning',
                value: fallbackMeaning,
              ),
            ],
      rawContent: fallbackMeaning,
    );
  }

  int _compareLegacyWordRows(Map<String, Object?> a, Map<String, Object?> b) {
    final sortIndexA = (a['sort_index'] as num?)?.toInt() ?? 0;
    final sortIndexB = (b['sort_index'] as num?)?.toInt() ?? 0;
    if (sortIndexA != sortIndexB) {
      return sortIndexA.compareTo(sortIndexB);
    }
    final idA = (a['id'] as num?)?.toInt() ?? 0;
    final idB = (b['id'] as num?)?.toInt() ?? 0;
    return idA.compareTo(idB);
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

  Future<T> _runInTransactionAsync<T>(Future<T> Function() action) async {
    final depth = _transactionDepth;
    final savepoint = 'sp_tx_$depth';
    if (depth == 0) {
      _db.execute('BEGIN TRANSACTION;');
    } else {
      _db.execute('SAVEPOINT $savepoint;');
    }
    _transactionDepth += 1;

    try {
      final result = await action();
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
    _applySchemaMigrations();
    ensureSpecialWordbooks();
    await syncBuiltInWordbooksCatalogIfNeeded();
    _initialized = true;
  }

  void _applySchemaMigrations() {
    var version = _readSchemaVersion();
    if (version < 1) {
      _migrateTimerRecordsSchema();
      _migrateProgressSchema();
      _migrateTodosSchema();
      _migrateNotesSchema();
      _setSchemaVersion(1);
      version = 1;
    }
    if (version < 2) {
      _migrateWordsStorageSchema();
      _setSchemaVersion(2);
      version = 2;
    }
    if (version < 3) {
      _migrateWordFieldsSchema();
      _setSchemaVersion(3);
      version = 3;
    }
    if (version < 4) {
      _migrateWordFieldSubtablesSchema();
      _setSchemaVersion(4);
      version = 4;
    }
    if (version < 5) {
      _migrateWordExtensionSchema();
      _setSchemaVersion(5);
      version = 5;
    }
    if (version < 6) {
      _migrateWordCompatibilityCacheSchema();
      _setSchemaVersion(6);
      version = 6;
    }
    if (version < 7) {
      _migrateWordEntryRecoverySchema();
      _setSchemaVersion(7);
      version = 7;
    }
    if (version < 8) {
      _migrateDownloadedAmbientSoundsSchema();
      _setSchemaVersion(8);
      version = 8;
    }
    if (version < 9) {
      _migrateWordbookStandardStorageSchema();
      _setSchemaVersion(9);
      version = 9;
    }
    if (version != _currentSchemaVersion) {
      _setSchemaVersion(_currentSchemaVersion);
    }
  }

  void _migrateWordFieldSubtablesSchema() {
    final fieldRows = _selectMaps('''
      SELECT id, word_id, style_json, sort_order
      FROM word_fields
      ORDER BY word_id ASC, sort_order ASC, id ASC
      ''');
    if (fieldRows.isEmpty) {
      return;
    }
    final byWordId = <int, List<Map<String, Object?>>>{};
    for (final row in fieldRows) {
      final wordId = (row['word_id'] as num?)?.toInt();
      if (wordId == null || wordId <= 0) {
        continue;
      }
      byWordId.putIfAbsent(wordId, () => <Map<String, Object?>>[]).add(row);
      final fieldId = (row['id'] as num?)?.toInt();
      if (fieldId == null || fieldId <= 0) {
        continue;
      }
      final style = WordFieldStyle.fromJsonMap(
        _decodeJsonObject(row['style_json']),
      );
      if (!style.isEmpty) {
        _db.execute(
          '''
          INSERT OR REPLACE INTO word_field_styles (
            word_field_id,
            background_hex,
            border_hex,
            text_hex,
            accent_hex
          ) VALUES (?, ?, ?, ?, ?)
          ''',
          <Object?>[
            fieldId,
            style.backgroundHex.trim(),
            style.borderHex.trim(),
            style.textHex.trim(),
            style.accentHex.trim(),
          ],
        );
      }
    }

    for (final entry in byWordId.entries) {
      final wordRow = _selectOne('SELECT * FROM words WHERE id = ?', <Object?>[
        entry.key,
      ]);
      if (wordRow == null) {
        continue;
      }
      final wordEntry = WordEntry.fromMap(wordRow);
      final rows = entry.value;
      final fields = wordEntry.fields;
      final count = math.min(rows.length, fields.length);
      for (var index = 0; index < count; index += 1) {
        final fieldId = (rows[index]['id'] as num?)?.toInt();
        if (fieldId == null || fieldId <= 0) {
          continue;
        }
        _replaceWordFieldSubtables(fieldId, fields[index]);
      }
    }
  }

  void _migrateWordExtensionSchema() {
    final tableInfo = _db.select('PRAGMA table_info(words);');
    final columnNames = <String>{
      for (final row in tableInfo) row['name'].toString(),
    };
    if (!columnNames.contains('extension_json')) {
      _db.execute('ALTER TABLE words ADD COLUMN extension_json TEXT;');
    }
    _rebuildWordCompatibilityCaches();
  }

  void _migrateWordCompatibilityCacheSchema() {
    _rebuildWordCompatibilityCaches();
  }

  void _migrateWordEntryRecoverySchema() {
    _rebuildWordCompatibilityCaches();
  }

  void _migrateDownloadedAmbientSoundsSchema() {
    // Table was already created in _createTables for new installations.
    // For existing users, we just need to ensure the table exists.
    // The migration is mainly for upgrading from schema version 7 to 8.
  }

  void _migrateWordbookStandardStorageSchema() {
    final wordbookTableInfo = _db.select('PRAGMA table_info(wordbooks);');
    final wordbookColumns = <String>{
      for (final row in wordbookTableInfo) row['name'].toString(),
    };
    if (!wordbookColumns.contains('schema_version')) {
      _db.execute('ALTER TABLE wordbooks ADD COLUMN schema_version TEXT;');
    }
    if (!wordbookColumns.contains('metadata_json')) {
      _db.execute('ALTER TABLE wordbooks ADD COLUMN metadata_json TEXT;');
    }

    final wordTableInfo = _db.select('PRAGMA table_info(words);');
    final wordColumns = <String>{
      for (final row in wordTableInfo) row['name'].toString(),
    };
    if (!wordColumns.contains('entry_uid')) {
      _db.execute('ALTER TABLE words ADD COLUMN entry_uid TEXT;');
    }
    if (!wordColumns.contains('primary_gloss')) {
      _db.execute('ALTER TABLE words ADD COLUMN primary_gloss TEXT;');
    }
    if (!wordColumns.contains('schema_version')) {
      _db.execute('ALTER TABLE words ADD COLUMN schema_version TEXT;');
    }
    if (!wordColumns.contains('source_payload_json')) {
      _db.execute('ALTER TABLE words ADD COLUMN source_payload_json TEXT;');
    }
    if (!wordColumns.contains('sort_index')) {
      _db.execute('ALTER TABLE words ADD COLUMN sort_index INTEGER DEFAULT 0;');
    }

    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_words_entry_uid ON words(wordbook_id, entry_uid);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_words_sort_index ON words(wordbook_id, sort_index, id);',
    );
  }

  void _rebuildWordCompatibilityCaches() {
    final rows = _selectMaps('SELECT * FROM words ORDER BY $_wordOrderClause');
    _updateWordCompatibilityCaches(rows);
  }

  void _updateWordCompatibilityCaches(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) {
      return;
    }
    final wordIds = rows
        .map((row) => (row['id'] as num?)?.toInt())
        .whereType<int>()
        .where((id) => id > 0)
        .toList(growable: false);
    final fieldsByWordId = _getWordFieldsByWordIds(wordIds);
    for (final row in rows) {
      final wordId = (row['id'] as num?)?.toInt();
      if (wordId == null || wordId <= 0) {
        continue;
      }
      final fieldRows = fieldsByWordId[wordId] ?? const <WordFieldItem>[];
      final extensionJson = _buildExtensionJson(fieldRows);
      final compactEntryJson = _buildEntryRecoveryJson(
        rawContent: _resolveStoredRawContent(row),
      );
      _db.execute(
        'UPDATE words SET extension_json = ?, entry_json = ? WHERE id = ?',
        <Object?>[extensionJson, compactEntryJson, wordId],
      );
    }
  }

  int _readSchemaVersion() {
    final row = _db.select('PRAGMA user_version;');
    if (row.isEmpty) {
      return 0;
    }
    return (row.first['user_version'] as num?)?.toInt() ?? 0;
  }

  void _setSchemaVersion(int version) {
    _db.execute('PRAGMA user_version = $version;');
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

  List<WordEntryPayload> _buildWordEntryPayloadsForWordbook(int wordbookId) {
    final rows = _selectMaps(
      'SELECT * FROM words WHERE wordbook_id = ? ORDER BY $_wordOrderClause',
      <Object?>[wordbookId],
    );
    final wordIds = rows
        .map((row) => (row['id'] as num?)?.toInt())
        .whereType<int>()
        .where((id) => id > 0)
        .toList(growable: false);
    final fieldsByWordId = _getWordFieldsByWordIds(wordIds);

    return rows
        .map((row) {
          final wordId = (row['id'] as num?)?.toInt();
          final fields = wordId == null
              ? const <WordFieldItem>[]
              : (fieldsByWordId[wordId] ?? const <WordFieldItem>[]);
          if (fields.isEmpty) {
            return WordEntry.fromMap(row).toPayload();
          }
          return WordEntryPayload(
            word: sanitizeDisplayText('${row['word'] ?? ''}'),
            fields: fields,
            rawContent: _resolveStoredRawContent(row),
          );
        })
        .toList(growable: false);
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
    _db.execute(
      '''
      DELETE FROM word_field_styles
      WHERE word_field_id IN (SELECT id FROM word_fields WHERE word_id = ?)
      ''',
      <Object?>[wordId],
    );
    _db.execute(
      '''
      DELETE FROM word_field_tags
      WHERE word_field_id IN (SELECT id FROM word_fields WHERE word_id = ?)
      ''',
      <Object?>[wordId],
    );
    _db.execute(
      '''
      DELETE FROM word_field_media
      WHERE word_field_id IN (SELECT id FROM word_fields WHERE word_id = ?)
      ''',
      <Object?>[wordId],
    );
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
      _replaceWordFieldSubtables(_lastInsertId(), field);
    }
  }

  void _replaceWordFieldSubtables(int wordFieldId, WordFieldItem field) {
    _db.execute(
      'DELETE FROM word_field_styles WHERE word_field_id = ?',
      <Object?>[wordFieldId],
    );
    _db.execute(
      'DELETE FROM word_field_tags WHERE word_field_id = ?',
      <Object?>[wordFieldId],
    );
    _db.execute(
      'DELETE FROM word_field_media WHERE word_field_id = ?',
      <Object?>[wordFieldId],
    );

    if (!field.style.isEmpty) {
      _db.execute(
        '''
        INSERT INTO word_field_styles (
          word_field_id,
          background_hex,
          border_hex,
          text_hex,
          accent_hex
        ) VALUES (?, ?, ?, ?, ?)
        ''',
        <Object?>[
          wordFieldId,
          field.style.backgroundHex.trim(),
          field.style.borderHex.trim(),
          field.style.textHex.trim(),
          field.style.accentHex.trim(),
        ],
      );
    }

    for (var index = 0; index < field.tags.length; index += 1) {
      final tag = field.tags[index].trim();
      if (tag.isEmpty) {
        continue;
      }
      _db.execute(
        '''
        INSERT INTO word_field_tags (word_field_id, tag, sort_order)
        VALUES (?, ?, ?)
        ''',
        <Object?>[wordFieldId, tag, index],
      );
    }

    for (var index = 0; index < field.media.length; index += 1) {
      final media = field.media[index];
      if (media.source.trim().isEmpty) {
        continue;
      }
      _db.execute(
        '''
        INSERT INTO word_field_media (
          word_field_id,
          media_type,
          media_source,
          media_label,
          mime_type,
          sort_order
        ) VALUES (?, ?, ?, ?, ?, ?)
        ''',
        <Object?>[
          wordFieldId,
          media.type.name,
          media.source.trim(),
          media.label.trim(),
          media.mimeType?.trim(),
          index,
        ],
      );
    }
  }

  String? _buildExtensionJson(List<WordFieldItem> fields) {
    final extensions = fields
        .where((field) => !_isWordCompatibilityColumnBackedFieldKey(field.key))
        .map((field) => field.toJsonMap())
        .toList(growable: false);
    if (extensions.isEmpty) {
      return null;
    }
    return jsonEncode(<String, Object?>{'fields': extensions});
  }

  bool _isWordCompatibilityColumnBackedFieldKey(String key) {
    return const <String>{
      'meaning',
      'examples',
      'etymology',
      'roots',
      'affixes',
      'variations',
      'memory',
      'story',
    }.contains(normalizeFieldKey(key));
  }

  String? _buildEntryRecoveryJson({required String rawContent}) {
    final normalizedRawContent = sanitizeDisplayText(rawContent);
    if (normalizedRawContent.isEmpty) {
      return null;
    }
    return jsonEncode(<String, Object?>{'rawContent': normalizedRawContent});
  }

  String _readEntryRecoveryRawContent(Object? raw) {
    final jsonText = '${raw ?? ''}'.trim();
    if (jsonText.isEmpty) {
      return '';
    }
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is Map) {
        return sanitizeDisplayText(
          '${decoded['rawContent'] ?? decoded['raw_content'] ?? ''}',
        );
      }
    } catch (_) {
      // Keep compatibility with broken legacy cache rows by treating them as empty.
    }
    return '';
  }

  String _resolveStoredRawContent(Map<String, Object?> row) {
    final inlineRawContent = sanitizeDisplayText('${row['raw_content'] ?? ''}');
    if (inlineRawContent.isNotEmpty) {
      return inlineRawContent;
    }
    final cachedRawContent = _readEntryRecoveryRawContent(row['entry_json']);
    if (cachedRawContent.isNotEmpty) {
      return cachedRawContent;
    }
    final fallbackGloss = sanitizeDisplayText('${row['primary_gloss'] ?? ''}');
    if (fallbackGloss.isNotEmpty) {
      return fallbackGloss;
    }
    final fallbackMeaning = sanitizeDisplayText('${row['meaning'] ?? ''}');
    return fallbackMeaning;
  }

  WordEntry _wordEntryLiteFromRow(Map<String, Object?> row) {
    final entry = WordEntry(
      id: (row['id'] as num?)?.toInt(),
      wordbookId: ((row['wordbook_id'] as num?) ?? 0).toInt(),
      word: sanitizeDisplayText('${row['word'] ?? ''}'),
      meaning:
          _sanitizeNullableText(row['primary_gloss']) ??
          _sanitizeNullableText(row['meaning']),
      entryUid: _sanitizeNullableText(row['entry_uid']),
      primaryGloss: _sanitizeNullableText(row['primary_gloss']),
      schemaVersion: _sanitizeNullableText(row['schema_version']),
      sortIndex: (row['sort_index'] as num?)?.toInt(),
      sourcePayloadJson: _sanitizeNullableText(row['source_payload_json']),
      rawContent: _resolveStoredRawContent(row),
    );
    return entry.copyWith(
      meaning: entry.summaryMeaningText.trim().isEmpty
          ? entry.meaning
          : entry.summaryMeaningText,
    );
  }

  String? _sanitizeNullableText(Object? raw) {
    final text = sanitizeDisplayText('${raw ?? ''}');
    return text.isEmpty ? null : text;
  }

  _PreparedWordRecord _buildStoredWordRecord({
    int? id,
    required int wordbookId,
    required String word,
    required List<WordFieldItem> fields,
    required String rawContent,
    String? entryUid,
    String? primaryGloss,
    String? schemaVersion,
    String? sourcePayloadJson,
    int? sortIndex,
  }) {
    final normalizedWord = sanitizeDisplayText(word).trim();
    final normalizedRawContent = sanitizeDisplayText(rawContent);
    final normalizedFields = mergeFieldItems(<WordFieldItem>[
      ...fields,
      if (normalizedRawContent.isNotEmpty)
        ...parseSectionedContent(normalizedRawContent),
    ]);
    final previewEntry = WordEntry(
      id: id,
      wordbookId: wordbookId,
      word: normalizedWord,
      fields: normalizedFields,
      rawContent: normalizedRawContent,
      entryUid: entryUid,
      primaryGloss: primaryGloss,
      schemaVersion: schemaVersion,
      sortIndex: sortIndex,
      sourcePayloadJson: sourcePayloadJson,
    );
    final legacy = previewEntry.legacyFields;
    final resolvedMeaning = previewEntry.displayMeaning.trim().isEmpty
        ? legacy.meaning
        : previewEntry.displayMeaning;
    final persistedRawContent = normalizedRawContent.isNotEmpty
        ? normalizedRawContent
        : resolvedMeaning ?? '';
    final detailsText = previewEntry.searchDetailsText;
    final extensionJson = _buildExtensionJson(normalizedFields);
    final compactEntryJson = _buildEntryRecoveryJson(
      rawContent: persistedRawContent,
    );

    return _PreparedWordRecord(
      row: <String, Object?>{
        'word': normalizedWord,
        'meaning': resolvedMeaning,
        'search_word': search_text.normalizeSearchText(normalizedWord),
        'search_meaning': search_text.normalizeSearchText(
          resolvedMeaning ?? '',
        ),
        'search_details': search_text.normalizeSearchText(detailsText),
        'search_word_compact': search_text.normalizeFuzzyCompactText(
          normalizedWord,
        ),
        'search_details_compact': search_text.normalizeFuzzyCompactText(
          detailsText,
        ),
        'extension_json': extensionJson,
        'entry_json': compactEntryJson,
      },
      fields: normalizedFields,
      entryUid: _sanitizeNullableText(entryUid),
      primaryGloss: _sanitizeNullableText(primaryGloss) ?? resolvedMeaning,
      schemaVersion: _sanitizeNullableText(schemaVersion),
      sourcePayloadJson: _sanitizeNullableText(sourcePayloadJson),
      sortIndex: sortIndex ?? 0,
    );
  }

  _WordImportInsertStatements _openWordImportInsertStatements() {
    return _WordImportInsertStatements(
      wordInsert: _db.prepare('''
        INSERT INTO words (
          wordbook_id,
          entry_uid,
          word,
          meaning,
          primary_gloss,
          search_word,
          search_meaning,
          search_details,
          search_word_compact,
          search_details_compact,
          schema_version,
          source_payload_json,
          sort_index,
          extension_json,
          entry_json
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        '''),
      fieldInsert: _db.prepare('''
        INSERT INTO word_fields (
          word_id,
          field_key,
          field_label,
          field_value_json,
          style_json,
          sort_order
        ) VALUES (?, ?, ?, ?, ?, ?)
        '''),
      styleInsert: _db.prepare('''
        INSERT INTO word_field_styles (
          word_field_id,
          background_hex,
          border_hex,
          text_hex,
          accent_hex
        ) VALUES (?, ?, ?, ?, ?)
        '''),
      tagInsert: _db.prepare('''
        INSERT INTO word_field_tags (word_field_id, tag, sort_order)
        VALUES (?, ?, ?)
        '''),
      mediaInsert: _db.prepare('''
        INSERT INTO word_field_media (
          word_field_id,
          media_type,
          media_source,
          media_label,
          mime_type,
          sort_order
        ) VALUES (?, ?, ?, ?, ?, ?)
        '''),
    );
  }

  bool _insertWordWithStatements(
    int wordbookId,
    WordEntryPayload payload, {
    required _WordImportInsertStatements statements,
  }) {
    if (payload.word.trim().isEmpty) {
      return false;
    }
    final prepared = _buildStoredWordRecord(
      wordbookId: wordbookId,
      word: payload.word,
      fields: payload.fields,
      rawContent: payload.rawContent,
      entryUid: payload.entryUid,
      primaryGloss: payload.primaryGloss,
      schemaVersion: payload.schemaVersion,
      sourcePayloadJson: payload.sourcePayloadJson,
      sortIndex: payload.sortIndex,
    );

    statements.wordInsert.execute(<Object?>[
      wordbookId,
      prepared.entryUid,
      prepared.row['word'],
      prepared.row['meaning'],
      prepared.primaryGloss,
      prepared.row['search_word'],
      prepared.row['search_meaning'],
      prepared.row['search_details'],
      prepared.row['search_word_compact'],
      prepared.row['search_details_compact'],
      prepared.schemaVersion,
      prepared.sourcePayloadJson,
      prepared.sortIndex,
      prepared.row['extension_json'],
      prepared.row['entry_json'],
    ]);
    final wordId = _lastInsertId();
    final normalizedFields = prepared.fields;
    for (var index = 0; index < normalizedFields.length; index += 1) {
      final field = normalizedFields[index];
      statements.fieldInsert.execute(<Object?>[
        wordId,
        field.key,
        field.label,
        jsonEncode(field.value),
        field.style.isEmpty ? null : jsonEncode(field.style.toJsonMap()),
        index,
      ]);
      final wordFieldId = _lastInsertId();
      _insertWordFieldSubtablesWithStatements(
        wordFieldId,
        field,
        statements: statements,
      );
    }
    return true;
  }

  void _insertWordFieldSubtablesWithStatements(
    int wordFieldId,
    WordFieldItem field, {
    required _WordImportInsertStatements statements,
  }) {
    if (!field.style.isEmpty) {
      statements.styleInsert.execute(<Object?>[
        wordFieldId,
        field.style.backgroundHex.trim(),
        field.style.borderHex.trim(),
        field.style.textHex.trim(),
        field.style.accentHex.trim(),
      ]);
    }

    for (var index = 0; index < field.tags.length; index += 1) {
      final tag = field.tags[index].trim();
      if (tag.isEmpty) continue;
      statements.tagInsert.execute(<Object?>[wordFieldId, tag, index]);
    }

    for (var index = 0; index < field.media.length; index += 1) {
      final media = field.media[index];
      if (media.source.trim().isEmpty) continue;
      statements.mediaInsert.execute(<Object?>[
        wordFieldId,
        media.type.name,
        media.source.trim(),
        media.label.trim(),
        media.mimeType?.trim(),
        index,
      ]);
    }
  }

  void _insertWord(int wordbookId, WordEntryPayload payload) {
    final prepared = _buildStoredWordRecord(
      wordbookId: wordbookId,
      word: payload.word,
      fields: payload.fields,
      rawContent: payload.rawContent,
      entryUid: payload.entryUid,
      primaryGloss: payload.primaryGloss,
      schemaVersion: payload.schemaVersion,
      sourcePayloadJson: payload.sourcePayloadJson,
      sortIndex: payload.sortIndex,
    );

    _db.execute(
      '''
      INSERT INTO words (
        wordbook_id,
        entry_uid,
        word,
        meaning,
        primary_gloss,
        search_word,
        search_meaning,
        search_details,
        search_word_compact,
        search_details_compact,
        schema_version,
        source_payload_json,
        sort_index,
        extension_json,
        entry_json
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      <Object?>[
        wordbookId,
        prepared.entryUid,
        prepared.row['word'],
        prepared.row['meaning'],
        prepared.primaryGloss,
        prepared.row['search_word'],
        prepared.row['search_meaning'],
        prepared.row['search_details'],
        prepared.row['search_word_compact'],
        prepared.row['search_details_compact'],
        prepared.schemaVersion,
        prepared.sourcePayloadJson,
        prepared.sortIndex,
        prepared.row['extension_json'],
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

  List<Map<String, Object?>> _selectDownloadedAmbientSounds() {
    return _selectMaps(
      'SELECT * FROM downloaded_ambient_sounds ORDER BY downloaded_at DESC',
    );
  }

  List<DownloadedAmbientSoundInfo> getDownloadedAmbientSounds() {
    final rows = _selectDownloadedAmbientSounds();
    return rows.map((row) => DownloadedAmbientSoundInfo.fromMap(row)).toList();
  }

  void insertDownloadedAmbientSound({
    required String soundId,
    required String remoteKey,
    required String relativePath,
    required String categoryKey,
    required String name,
    required String filePath,
  }) {
    _db.execute(
      '''
      INSERT OR REPLACE INTO downloaded_ambient_sounds (
        sound_id, remote_key, relative_path, category_key, name, file_path, last_accessed_at
      ) VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
      ''',
      <Object?>[soundId, remoteKey, relativePath, categoryKey, name, filePath],
    );
  }

  void deleteDownloadedAmbientSound(String soundId) {
    _db.execute(
      'DELETE FROM downloaded_ambient_sounds WHERE sound_id = ?',
      <Object?>[soundId],
    );
  }

  bool isAmbientSoundDownloaded(String soundId) {
    final row = _selectOne(
      'SELECT 1 FROM downloaded_ambient_sounds WHERE sound_id = ?',
      <Object?>[soundId],
    );
    return row != null;
  }

  void updateDownloadedAmbientSoundAccess(String soundId) {
    _db.execute(
      'UPDATE downloaded_ambient_sounds SET last_accessed_at = CURRENT_TIMESTAMP WHERE sound_id = ?',
      <Object?>[soundId],
    );
  }
}

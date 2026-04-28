import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../../services/cstcloud_s3_compat_client.dart';
import 'daily_choice_models.dart';

class DailyChoiceWearLibraryStatus {
  const DailyChoiceWearLibraryStatus({
    required this.hasInstalledLibrary,
    this.outfitCount = 0,
    this.referenceTitles = const <String>[],
    this.libraryId = '',
    this.libraryVersion = '',
    this.schemaId = '',
    this.schemaVersion = 0,
    this.installedAt,
    this.updatedAt,
    this.errorMessage,
  });

  const DailyChoiceWearLibraryStatus.empty()
    : hasInstalledLibrary = false,
      outfitCount = 0,
      referenceTitles = const <String>[],
      libraryId = '',
      libraryVersion = '',
      schemaId = '',
      schemaVersion = 0,
      installedAt = null,
      updatedAt = null,
      errorMessage = null;

  final bool hasInstalledLibrary;
  final int outfitCount;
  final List<String> referenceTitles;
  final String libraryId;
  final String libraryVersion;
  final String schemaId;
  final int schemaVersion;
  final DateTime? installedAt;
  final DateTime? updatedAt;
  final String? errorMessage;

  DailyChoiceWearLibraryStatus copyWith({
    bool? hasInstalledLibrary,
    int? outfitCount,
    List<String>? referenceTitles,
    String? libraryId,
    String? libraryVersion,
    String? schemaId,
    int? schemaVersion,
    DateTime? installedAt,
    DateTime? updatedAt,
    String? errorMessage,
  }) {
    return DailyChoiceWearLibraryStatus(
      hasInstalledLibrary: hasInstalledLibrary ?? this.hasInstalledLibrary,
      outfitCount: outfitCount ?? this.outfitCount,
      referenceTitles: referenceTitles ?? this.referenceTitles,
      libraryId: libraryId ?? this.libraryId,
      libraryVersion: libraryVersion ?? this.libraryVersion,
      schemaId: schemaId ?? this.schemaId,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      installedAt: installedAt ?? this.installedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      errorMessage: errorMessage,
    );
  }
}

typedef DailyChoiceWearSupportDirectoryProvider = Future<Directory> Function();

class DailyChoiceWearLibraryStore {
  DailyChoiceWearLibraryStore({
    CstCloudS3CompatClient? s3Client,
    DailyChoiceWearSupportDirectoryProvider? supportDirectoryProvider,
    this.databaseFileName = 'toolbox_daily_choice_wear.db',
    this.remoteLibraryKey = 'wear_data/daily_choice_wear_library.json',
  }) : _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory,
       _s3Client = s3Client ?? CstCloudS3CompatClient(),
       _ownsS3Client = s3Client == null;

  final DailyChoiceWearSupportDirectoryProvider _supportDirectoryProvider;
  final CstCloudS3CompatClient _s3Client;
  final bool _ownsS3Client;
  final String databaseFileName;
  final String remoteLibraryKey;

  Database? _db;

  static const String _optionsTable = 'daily_choice_wear_options';
  static const String _metaTable = 'daily_choice_wear_meta';
  static const int _schemaVersion = 1;

  // ── public API ──

  Future<DailyChoiceWearLibraryStatus> inspectStatus() async {
    final file = await _databaseFile();
    if (!await file.exists()) {
      return const DailyChoiceWearLibraryStatus.empty();
    }
    final db = await _database();
    return _inspectOpenDatabase(db);
  }

  Future<DailyChoiceWearLibraryStatus> installLibrary() async {
    final previousStatus = await inspectStatus();
    _closeDatabase();
    final targetFile = await _databaseFile();
    final jsonFile = File('${targetFile.path}.json_download');
    try {
      await _deleteDatabaseArtifacts(targetFile);
      await _downloadRemoteLibrary(jsonFile);
      final dbFile = File('${targetFile.path}.build');
      await _deleteDatabaseArtifacts(dbFile);
      await _buildDatabaseFromJson(jsonFile, dbFile);
      await _normalizeInstalledDatabaseMeta(dbFile: dbFile);
      final status = _inspectDatabaseFile(dbFile);
      if (!status.hasInstalledLibrary || status.outfitCount <= 0) {
        throw StateError('Remote wear library is empty.');
      }
      await _replaceDatabaseFile(candidateFile: dbFile, targetFile: targetFile);
      await _deleteDatabaseArtifacts(jsonFile);
      await _deleteDatabaseArtifacts(dbFile);
      return inspectStatus();
    } catch (error) {
      await _deleteDatabaseArtifacts(jsonFile);
      await _deleteDatabaseArtifacts(File('${targetFile.path}.build'));
      if (previousStatus.hasInstalledLibrary) {
        return previousStatus.copyWith(errorMessage: '$error');
      }
      await _deleteDatabaseArtifacts(targetFile);
      return DailyChoiceWearLibraryStatus(
        hasInstalledLibrary: false,
        errorMessage: '$error',
      );
    }
  }

  Future<List<DailyChoiceOption>> loadBuiltInSummaries() async {
    final status = await inspectStatus();
    if (!status.hasInstalledLibrary) {
      return const <DailyChoiceOption>[];
    }
    final databasePath = (await _databaseFile()).path;
    try {
      return await Isolate.run(
        () => _loadSummariesFromDatabaseFile(databasePath),
      );
    } catch (_) {
      final db = await _database();
      return _loadSummariesFromDatabase(db);
    }
  }

  Future<DailyChoiceOption?> loadBuiltInDetail(String optionId) async {
    final status = await inspectStatus();
    if (!status.hasInstalledLibrary) {
      return null;
    }
    try {
      final db = await _database();
      return _loadDetail(db, optionId);
    } catch (_) {
      return null;
    }
  }

  Future<List<DailyChoiceOption>> queryBuiltInSummaries({
    String? categoryId,
    String? contextId,
    int limit = 200,
    int offset = 0,
  }) async {
    final db = await _database();
    return _querySummaries(
      db,
      categoryId: categoryId,
      contextId: contextId,
      limit: limit,
      offset: offset,
    );
  }

  Future<void> close() async {
    _closeDatabase();
    if (_ownsS3Client) {
      await _s3Client.close();
    }
  }

  // ── database file management ──

  void _closeDatabase() {
    _db?.dispose();
    _db = null;
  }

  Future<File> _databaseFile() async {
    final directory = await _supportDirectoryProvider();
    await directory.create(recursive: true);
    return File(p.join(directory.path, databaseFileName));
  }

  Future<Database> _database() async {
    final existing = _db;
    if (existing != null) {
      return existing;
    }
    final file = await _databaseFile();
    final db = sqlite3.open(file.path);
    db.execute('PRAGMA foreign_keys = ON;');
    db.execute('PRAGMA journal_mode = WAL;');
    db.execute('PRAGMA synchronous = NORMAL;');
    _ensureSchema(db);
    _db = db;
    return db;
  }

  // ── schema ──

  void _ensureSchema(Database db) {
    if (!_tableExists(db, _optionsTable)) {
      _createSchema(db);
    }
    final currentVersion = _readSchemaVersion(db);
    if (currentVersion > _schemaVersion) {
      throw StateError(
        'Wear library schema version $currentVersion is newer than supported $_schemaVersion.',
      );
    }
  }

  void _createSchema(Database db) {
    db.execute('''
      CREATE TABLE $_optionsTable (
        option_id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        context_id TEXT,
        context_ids_json TEXT NOT NULL DEFAULT '[]',
        title_zh TEXT NOT NULL,
        title_en TEXT NOT NULL,
        subtitle_zh TEXT NOT NULL,
        subtitle_en TEXT NOT NULL,
        details_zh TEXT NOT NULL,
        details_en TEXT NOT NULL,
        materials_zh_json TEXT NOT NULL DEFAULT '[]',
        materials_en_json TEXT NOT NULL DEFAULT '[]',
        steps_zh_json TEXT NOT NULL DEFAULT '[]',
        steps_en_json TEXT NOT NULL DEFAULT '[]',
        notes_zh_json TEXT NOT NULL DEFAULT '[]',
        notes_en_json TEXT NOT NULL DEFAULT '[]',
        tags_zh_json TEXT NOT NULL DEFAULT '[]',
        tags_en_json TEXT NOT NULL DEFAULT '[]',
        source_label TEXT,
        source_url TEXT,
        references_json TEXT NOT NULL DEFAULT '[]',
        attributes_json TEXT NOT NULL DEFAULT '{}',
        custom INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'active',
        is_available INTEGER NOT NULL DEFAULT 1,
        sort_key INTEGER NOT NULL DEFAULT 0
      )
    ''');
    db.execute('''
      CREATE TABLE $_metaTable (
        meta_key TEXT PRIMARY KEY,
        meta_value TEXT NOT NULL
      )
    ''');
    db.execute('''
      CREATE INDEX idx_wear_cat_ctx
      ON $_optionsTable(category_id, context_id, status, is_available)
    ''');
    db.execute('PRAGMA user_version = $_schemaVersion;');
  }

  // ── status inspection ──

  DailyChoiceWearLibraryStatus _inspectOpenDatabase(Database db) {
    if (!_tableExists(db, _optionsTable)) {
      return const DailyChoiceWearLibraryStatus.empty();
    }
    final countRow = db.select(
      '''
      SELECT COUNT(*) AS total
      FROM $_optionsTable
      WHERE status = ? AND is_available = ?
    ''',
      <Object?>['active', 1],
    );
    final outfitCount = (countRow.firstOrNull?['total'] as num?)?.toInt() ?? 0;
    if (outfitCount <= 0) {
      return const DailyChoiceWearLibraryStatus.empty();
    }
    final meta = _metaMap(db);
    return DailyChoiceWearLibraryStatus(
      hasInstalledLibrary: true,
      outfitCount: outfitCount,
      referenceTitles: _stringListMeta(meta, 'reference_titles_json'),
      libraryId: _stringMeta(meta, 'library_id'),
      libraryVersion: _stringMeta(meta, 'library_version'),
      schemaId: _stringMeta(meta, 'schema_id'),
      schemaVersion: _intMeta(meta, 'schema_version'),
      installedAt: _dateTimeMeta(meta, 'installed_at'),
      updatedAt: _dateTimeMeta(meta, 'updated_at'),
      errorMessage: _nullableMeta(meta, 'error_message'),
    );
  }

  DailyChoiceWearLibraryStatus _inspectDatabaseFile(File file) {
    final db = sqlite3.open(file.path);
    try {
      db.execute('PRAGMA foreign_keys = ON;');
      _ensureSchema(db);
      return _inspectOpenDatabase(db);
    } finally {
      db.dispose();
    }
  }

  // ── download ──

  Future<void> _downloadRemoteLibrary(File targetFile) async {
    await targetFile.parent.create(recursive: true);
    final tempFile = File('${targetFile.path}.part');
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
    try {
      await _s3Client.downloadObjectToFile(remoteLibraryKey, tempFile);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await tempFile.rename(targetFile.path);
    } catch (_) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }

  // ── database build from JSON ──

  Future<void> _buildDatabaseFromJson(File jsonFile, File dbFile) async {
    await dbFile.parent.create(recursive: true);
    final db = sqlite3.open(dbFile.path);
    try {
      db.execute('PRAGMA foreign_keys = ON;');
      db.execute('PRAGMA journal_mode = OFF;');
      db.execute('PRAGMA synchronous = OFF;');
      _createSchema(db);

      final jsonText = await jsonFile.readAsString();
      final decoded = jsonDecode(jsonText) as Map<String, Object?>;

      // Write meta from library header
      _upsertMeta(db, 'library_id', _stringValue(decoded['libraryId']));
      _upsertMeta(
        db,
        'library_version',
        _stringValue(decoded['libraryVersion']),
      );
      _upsertMeta(db, 'schema_id', _stringValue(decoded['schemaId']));
      _upsertMeta(db, 'schema_version', '${decoded['schemaVersion'] ?? 1}');
      _upsertMeta(
        db,
        'reference_titles_json',
        jsonEncode(decoded['referenceTitles'] ?? const <String>[]),
      );

      // Insert options
      final options = decoded['options'];
      if (options is! List || options.isEmpty) {
        throw StateError('Library JSON contains no options.');
      }

      final insertStatement = db.prepare('''
        INSERT INTO $_optionsTable (
          option_id, category_id, context_id, context_ids_json,
          title_zh, title_en, subtitle_zh, subtitle_en,
          details_zh, details_en,
          materials_zh_json, materials_en_json,
          steps_zh_json, steps_en_json,
          notes_zh_json, notes_en_json,
          tags_zh_json, tags_en_json,
          source_label, source_url, references_json,
          attributes_json,
          custom, status, is_available, sort_key
        ) VALUES (
          ?, ?, ?, ?,
          ?, ?, ?, ?,
          ?, ?,
          ?, ?,
          ?, ?,
          ?, ?,
          ?, ?,
          ?, ?, ?,
          ?,
          ?, ?, ?, ?
        )
      ''');

      for (var i = 0; i < options.length; i++) {
        final option = options[i] as Map<String, Object?>;
        final optionId = _stringValue(option['id']);
        final categoryId = _stringValue(option['categoryId']);
        final contextId = _nullableString(option['contextId']);
        final contextIds = option['contextIds'];
        final contextIdsJson = (contextIds is List && contextIds.isNotEmpty)
            ? jsonEncode(contextIds.map((e) => '$e').toList())
            : (contextId != null ? jsonEncode(<String>[contextId]) : '[]');

        insertStatement.execute(<Object?>[
          optionId,
          categoryId,
          contextId,
          contextIdsJson,
          _stringValue(option['titleZh']),
          _stringValue(option['titleEn']),
          _stringValue(option['subtitleZh']),
          _stringValue(option['subtitleEn']),
          _stringValue(option['detailsZh']),
          _stringValue(option['detailsEn']),
          _jsonField(option['materialsZh']),
          _jsonField(option['materialsEn']),
          _jsonField(option['stepsZh']),
          _jsonField(option['stepsEn']),
          _jsonField(option['notesZh']),
          _jsonField(option['notesEn']),
          _jsonField(option['tagsZh']),
          _jsonField(option['tagsEn']),
          _nullableString(option['sourceLabel']),
          _nullableString(option['sourceUrl']),
          _jsonField(option['references']),
          _jsonField(option['attributes']),
          option['custom'] == true ? 1 : 0,
          'active',
          1,
          i,
        ]);
      }
      insertStatement.dispose();

      db.execute('PRAGMA user_version = $_schemaVersion;');
    } finally {
      db.dispose();
    }
  }

  // ── database meta management ──

  Future<void> _normalizeInstalledDatabaseMeta({required File dbFile}) async {
    final db = sqlite3.open(dbFile.path);
    try {
      _ensureSchema(db);
      final now = DateTime.now().toIso8601String();
      final meta = _metaMap(db);
      final previousUpdatedAt = _stringMeta(meta, 'updated_at');
      final normalizedUpdatedAt = previousUpdatedAt.trim().isNotEmpty
          ? previousUpdatedAt
          : now;
      _upsertMeta(db, 'installed_at', now);
      _upsertMeta(db, 'updated_at', normalizedUpdatedAt);
      _upsertMeta(db, 'error_message', '');
      db.execute('PRAGMA user_version = $_schemaVersion;');
      db.execute('PRAGMA wal_checkpoint(TRUNCATE);');
    } finally {
      db.dispose();
    }
  }

  // ── queries ──

  List<DailyChoiceOption> _loadSummariesFromDatabase(Database db) {
    final rows = db.select(
      '''
      SELECT
        option_id, category_id, context_id, context_ids_json,
        title_zh, title_en, subtitle_zh, subtitle_en,
        details_zh, details_en,
        materials_zh_json, materials_en_json,
        steps_zh_json, steps_en_json,
        notes_zh_json, notes_en_json,
        tags_zh_json, tags_en_json,
        source_label, source_url, references_json,
        attributes_json
      FROM $_optionsTable
      WHERE status = ? AND is_available = ?
      ORDER BY sort_key ASC, option_id ASC
    ''',
      <Object?>['active', 1],
    );
    return List<DailyChoiceOption>.unmodifiable(
      rows.map(_optionFromRow).toList(growable: false),
    );
  }

  DailyChoiceOption? _loadDetail(Database db, String optionId) {
    final rows = db.select(
      '''
      SELECT
        option_id, category_id, context_id, context_ids_json,
        title_zh, title_en, subtitle_zh, subtitle_en,
        details_zh, details_en,
        materials_zh_json, materials_en_json,
        steps_zh_json, steps_en_json,
        notes_zh_json, notes_en_json,
        tags_zh_json, tags_en_json,
        source_label, source_url, references_json,
        attributes_json
      FROM $_optionsTable
      WHERE option_id = ? AND status = ? AND is_available = ?
      LIMIT 1
    ''',
      <Object?>[optionId, 'active', 1],
    );
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.first;
    return _optionFromRow(row);
  }

  List<DailyChoiceOption> _querySummaries(
    Database db, {
    String? categoryId,
    String? contextId,
    int limit = 200,
    int offset = 0,
  }) {
    final conditions = <String>['status = ?', 'is_available = ?'];
    final args = <Object?>['active', 1];
    if (categoryId != null && categoryId != 'all') {
      conditions.add('category_id = ?');
      args.add(categoryId);
    }
    if (contextId != null && contextId != 'all') {
      conditions.add('context_id = ?');
      args.add(contextId);
    }
    final where = conditions.join(' AND ');
    final rows = db.select(
      '''
      SELECT
        option_id, category_id, context_id, context_ids_json,
        title_zh, title_en, subtitle_zh, subtitle_en,
        details_zh, details_en,
        materials_zh_json, materials_en_json,
        steps_zh_json, steps_en_json,
        notes_zh_json, notes_en_json,
        tags_zh_json, tags_en_json,
        source_label, source_url, references_json,
        attributes_json
      FROM $_optionsTable
      WHERE $where
      ORDER BY sort_key ASC, option_id ASC
      LIMIT ? OFFSET ?
    ''',
      <Object?>[...args, limit, offset],
    );
    return List<DailyChoiceOption>.unmodifiable(
      rows.map(_optionFromRow).toList(growable: false),
    );
  }

  DailyChoiceOption _optionFromRow(Row row) {
    return DailyChoiceOption(
      id: '${row['option_id'] ?? ''}',
      moduleId: DailyChoiceModuleId.wear.storageValue,
      categoryId: '${row['category_id'] ?? ''}',
      contextId: _nullableString(row['context_id']),
      contextIds: _jsonStringList(row['context_ids_json']),
      titleZh: '${row['title_zh'] ?? ''}',
      titleEn: '${row['title_en'] ?? ''}',
      subtitleZh: '${row['subtitle_zh'] ?? ''}',
      subtitleEn: '${row['subtitle_en'] ?? ''}',
      detailsZh: '${row['details_zh'] ?? ''}',
      detailsEn: '${row['details_en'] ?? ''}',
      materialsZh: _jsonStringList(row['materials_zh_json']),
      materialsEn: _jsonStringList(row['materials_en_json']),
      stepsZh: _jsonStringList(row['steps_zh_json']),
      stepsEn: _jsonStringList(row['steps_en_json']),
      notesZh: _jsonStringList(row['notes_zh_json']),
      notesEn: _jsonStringList(row['notes_en_json']),
      tagsZh: _jsonStringList(row['tags_zh_json']),
      tagsEn: _jsonStringList(row['tags_en_json']),
      sourceLabel: _nullableString(row['source_label']),
      sourceUrl: _nullableString(row['source_url']),
      references: _jsonReferenceList(row['references_json']),
      attributes: _jsonStringListMap(row['attributes_json']),
      custom: (row['custom'] as num?)?.toInt() == 1,
    );
  }

  // ── file management ──

  Future<void> _replaceDatabaseFile({
    required File candidateFile,
    required File targetFile,
  }) async {
    _closeDatabase();
    await targetFile.parent.create(recursive: true);
    await _deleteDatabaseArtifacts(targetFile);
    await candidateFile.rename(targetFile.path);
  }

  Future<void> _deleteDatabaseArtifacts(File databaseFile) async {
    for (final path in <String>[
      databaseFile.path,
      '${databaseFile.path}-wal',
      '${databaseFile.path}-shm',
      '${databaseFile.path}-journal',
    ]) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  // ── Isolate helpers ──

  static List<DailyChoiceOption> _loadSummariesFromDatabaseFile(
    String databasePath,
  ) {
    final db = sqlite3.open(databasePath);
    try {
      db.execute('PRAGMA foreign_keys = ON;');
      if (!_tableExistsStatic(db, _optionsTable)) {
        return const <DailyChoiceOption>[];
      }
      final rows = db.select(
        '''
        SELECT
          option_id, category_id, context_id, context_ids_json,
          title_zh, title_en, subtitle_zh, subtitle_en,
          details_zh, details_en,
          materials_zh_json, materials_en_json,
          steps_zh_json, steps_en_json,
          notes_zh_json, notes_en_json,
          tags_zh_json, tags_en_json,
          source_label, source_url, references_json,
          attributes_json
        FROM $_optionsTable
        WHERE status = ? AND is_available = ?
        ORDER BY sort_key ASC, option_id ASC
      ''',
        <Object?>['active', 1],
      );
      return List<DailyChoiceOption>.unmodifiable(
        rows.map(_optionFromRowStatic).toList(growable: false),
      );
    } finally {
      db.dispose();
    }
  }

  static DailyChoiceOption _optionFromRowStatic(Row row) {
    return DailyChoiceOption(
      id: '${row['option_id'] ?? ''}',
      moduleId: DailyChoiceModuleId.wear.storageValue,
      categoryId: '${row['category_id'] ?? ''}',
      contextId: _nullableStringStatic(row['context_id']),
      contextIds: _jsonStringListStatic(row['context_ids_json']),
      titleZh: '${row['title_zh'] ?? ''}',
      titleEn: '${row['title_en'] ?? ''}',
      subtitleZh: '${row['subtitle_zh'] ?? ''}',
      subtitleEn: '${row['subtitle_en'] ?? ''}',
      detailsZh: '${row['details_zh'] ?? ''}',
      detailsEn: '${row['details_en'] ?? ''}',
      materialsZh: _jsonStringListStatic(row['materials_zh_json']),
      materialsEn: _jsonStringListStatic(row['materials_en_json']),
      stepsZh: _jsonStringListStatic(row['steps_zh_json']),
      stepsEn: _jsonStringListStatic(row['steps_en_json']),
      notesZh: _jsonStringListStatic(row['notes_zh_json']),
      notesEn: _jsonStringListStatic(row['notes_en_json']),
      tagsZh: _jsonStringListStatic(row['tags_zh_json']),
      tagsEn: _jsonStringListStatic(row['tags_en_json']),
      sourceLabel: _nullableStringStatic(row['source_label']),
      sourceUrl: _nullableStringStatic(row['source_url']),
      references: _jsonReferenceListStatic(row['references_json']),
      attributes: _jsonStringListMapStatic(row['attributes_json']),
      custom: (row['custom'] as num?)?.toInt() == 1,
    );
  }

  // ── meta helpers ──

  Map<String, String> _metaMap(Database db) {
    final rows = db.select('SELECT meta_key, meta_value FROM $_metaTable');
    return <String, String>{
      for (final row in rows)
        '${row['meta_key'] ?? ''}': '${row['meta_value'] ?? ''}',
    };
  }

  void _upsertMeta(Database db, String key, String value) {
    db.execute(
      '''
      INSERT INTO $_metaTable (meta_key, meta_value)
      VALUES (?, ?)
      ON CONFLICT(meta_key) DO UPDATE SET meta_value = excluded.meta_value
      ''',
      <Object?>[key, value],
    );
  }

  static int _intMeta(Map<String, String> meta, String key) {
    return int.tryParse(meta[key] ?? '') ?? 0;
  }

  static String _stringMeta(Map<String, String> meta, String key) {
    return (meta[key] ?? '').trim();
  }

  static String? _nullableMeta(Map<String, String> meta, String key) {
    final value = (meta[key] ?? '').trim();
    return value.isEmpty ? null : value;
  }

  static DateTime? _dateTimeMeta(Map<String, String> meta, String key) {
    final value = (meta[key] ?? '').trim();
    if (value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  static List<String> _stringListMeta(Map<String, String> meta, String key) {
    return _jsonStringListStatic(meta[key]);
  }

  // ── schema helpers ──

  bool _tableExists(Database db, String tableName) {
    return _tableExistsStatic(db, tableName);
  }

  static bool _tableExistsStatic(Database db, String tableName) {
    final rows = db.select(
      '''
      SELECT name FROM sqlite_master
      WHERE type = 'table' AND name = ?
      LIMIT 1
      ''',
      <Object?>[tableName],
    );
    return rows.isNotEmpty;
  }

  int _readSchemaVersion(Database db) {
    final rows = db.select('PRAGMA user_version');
    return (rows.firstOrNull?['user_version'] as num?)?.toInt() ?? 0;
  }

  // ── JSON helpers ──

  static String _stringValue(Object? value) {
    return value == null ? '' : '$value'.trim();
  }

  static String _jsonField(Object? value) {
    if (value == null) {
      return '[]';
    }
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? '[]' : trimmed;
    }
    return jsonEncode(value);
  }

  static String? _nullableString(Object? value) {
    final text = '${value ?? ''}'.trim();
    return text.isEmpty ? null : text;
  }

  static String? _nullableStringStatic(Object? value) {
    final text = '${value ?? ''}'.trim();
    return text.isEmpty ? null : text;
  }

  static List<String> _jsonStringList(Object? value) {
    return _jsonStringListStatic(value);
  }

  static List<String> _jsonStringListStatic(Object? value) {
    final raw = '${value ?? ''}'.trim();
    if (raw.isEmpty) {
      return const <String>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <String>[];
      }
      return decoded
          .map((item) => '$item'.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <String>[];
    }
  }

  static Map<String, List<String>> _jsonStringListMap(Object? value) {
    return _jsonStringListMapStatic(value);
  }

  static Map<String, List<String>> _jsonStringListMapStatic(Object? value) {
    final raw = '${value ?? ''}'.trim();
    if (raw.isEmpty) {
      return const <String, List<String>>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const <String, List<String>>{};
      }
      final result = <String, List<String>>{};
      for (final entry in decoded.entries) {
        final key = '${entry.key}'.trim();
        if (key.isEmpty || entry.value is! List) {
          continue;
        }
        result[key] = (entry.value as List)
            .map((item) => '$item'.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
      }
      return result;
    } catch (_) {
      return const <String, List<String>>{};
    }
  }

  static List<DailyChoiceReferenceLink> _jsonReferenceList(Object? value) {
    return _jsonReferenceListStatic(value);
  }

  static List<DailyChoiceReferenceLink> _jsonReferenceListStatic(
    Object? value,
  ) {
    final raw = '${value ?? ''}'.trim();
    if (raw.isEmpty) {
      return const <DailyChoiceReferenceLink>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <DailyChoiceReferenceLink>[];
      }
      final references = <DailyChoiceReferenceLink>[];
      for (final item in decoded) {
        if (item is Map<String, Object?>) {
          references.add(DailyChoiceReferenceLink.fromJson(item));
        } else if (item is Map) {
          references.add(
            DailyChoiceReferenceLink.fromJson(item.cast<String, Object?>()),
          );
        }
      }
      return List<DailyChoiceReferenceLink>.unmodifiable(references);
    } catch (_) {
      return const <DailyChoiceReferenceLink>[];
    }
  }
}

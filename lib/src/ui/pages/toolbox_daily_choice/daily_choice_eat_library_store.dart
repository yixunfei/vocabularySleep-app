import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../../services/cstcloud_s3_compat_client.dart';
import 'daily_choice_cook_service.dart';
import 'daily_choice_eat_support.dart';
import 'daily_choice_models.dart';

class DailyChoiceEatLibraryStatus {
  const DailyChoiceEatLibraryStatus({
    required this.hasInstalledLibrary,
    this.recipeCount = 0,
    this.localLibraryCount = 0,
    this.cookRecipeCount = 0,
    this.referenceTitles = const <String>[],
    this.libraryId = '',
    this.libraryVersion = '',
    this.schemaId = '',
    this.schemaVersion = 0,
    this.source,
    this.installedAt,
    this.updatedAt,
    this.errorMessage,
  });

  const DailyChoiceEatLibraryStatus.empty()
    : hasInstalledLibrary = false,
      recipeCount = 0,
      localLibraryCount = 0,
      cookRecipeCount = 0,
      referenceTitles = const <String>[],
      libraryId = '',
      libraryVersion = '',
      schemaId = '',
      schemaVersion = 0,
      source = null,
      installedAt = null,
      updatedAt = null,
      errorMessage = null;

  final bool hasInstalledLibrary;
  final int recipeCount;
  final int localLibraryCount;
  final int cookRecipeCount;
  final List<String> referenceTitles;
  final String libraryId;
  final String libraryVersion;
  final String schemaId;
  final int schemaVersion;
  final DailyChoiceCookDataSource? source;
  final DateTime? installedAt;
  final DateTime? updatedAt;
  final String? errorMessage;

  DailyChoiceEatLibraryStatus copyWith({
    bool? hasInstalledLibrary,
    int? recipeCount,
    int? localLibraryCount,
    int? cookRecipeCount,
    List<String>? referenceTitles,
    String? libraryId,
    String? libraryVersion,
    String? schemaId,
    int? schemaVersion,
    DailyChoiceCookDataSource? source,
    DateTime? installedAt,
    DateTime? updatedAt,
    String? errorMessage,
  }) {
    return DailyChoiceEatLibraryStatus(
      hasInstalledLibrary: hasInstalledLibrary ?? this.hasInstalledLibrary,
      recipeCount: recipeCount ?? this.recipeCount,
      localLibraryCount: localLibraryCount ?? this.localLibraryCount,
      cookRecipeCount: cookRecipeCount ?? this.cookRecipeCount,
      referenceTitles: referenceTitles ?? this.referenceTitles,
      libraryId: libraryId ?? this.libraryId,
      libraryVersion: libraryVersion ?? this.libraryVersion,
      schemaId: schemaId ?? this.schemaId,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      source: source ?? this.source,
      installedAt: installedAt ?? this.installedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      errorMessage: errorMessage,
    );
  }
}

typedef DailyChoiceEatLibrarySupportDirectoryProvider =
    Future<Directory> Function();
typedef DailyChoiceEatLibraryRemoteDatabaseInstaller =
    Future<DateTime?> Function(File targetFile);

class DailyChoiceEatLibraryStore {
  DailyChoiceEatLibraryStore({
    DailyChoiceCookService? cookService,
    DailyChoiceEatLibrarySupportDirectoryProvider? supportDirectoryProvider,
    DailyChoiceEatLibraryRemoteDatabaseInstaller? remoteDatabaseInstaller,
    CstCloudS3CompatClient? s3Client,
    this.databaseFileName = 'toolbox_daily_choice_recipes.db',
    this.cachedLibraryFileName = 'toolbox_daily_choice_recipe_library.json',
    this.remoteDatabaseKey = 'cook_data/daily_choice_recipe_library.db',
  }) : _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory,
       _remoteDatabaseInstaller = remoteDatabaseInstaller,
       _s3Client = s3Client ?? CstCloudS3CompatClient(),
       _ownsS3Client = s3Client == null;

  final DailyChoiceEatLibrarySupportDirectoryProvider _supportDirectoryProvider;
  final DailyChoiceEatLibraryRemoteDatabaseInstaller? _remoteDatabaseInstaller;
  final CstCloudS3CompatClient _s3Client;
  final bool _ownsS3Client;
  final String databaseFileName;
  final String cachedLibraryFileName;
  final String remoteDatabaseKey;

  Database? _db;

  static const int _schemaVersion = 1;
  static const String _recipesTable = 'daily_choice_eat_recipe_summaries';
  static const String _detailsTable = 'daily_choice_eat_recipe_details';
  static const String _indexTermsTable = 'daily_choice_eat_recipe_index_terms';
  static const String _metaTable = 'daily_choice_eat_recipe_meta';

  Future<DailyChoiceEatLibraryStatus> inspectStatus() async {
    final file = await _databaseFile();
    if (!await file.exists()) {
      return const DailyChoiceEatLibraryStatus.empty();
    }
    final db = await _database();
    return _inspectOpenDatabase(db);
  }

  DailyChoiceEatLibraryStatus _inspectOpenDatabase(Database db) {
    final hasTable = _tableExists(db, _recipesTable);
    if (!hasTable) {
      return const DailyChoiceEatLibraryStatus.empty();
    }
    final countRow = db.select('SELECT COUNT(*) AS total FROM $_recipesTable');
    final recipeCount = (countRow.firstOrNull?['total'] as num?)?.toInt() ?? 0;
    if (recipeCount <= 0) {
      return const DailyChoiceEatLibraryStatus.empty();
    }

    final meta = _metaMap(db);
    return DailyChoiceEatLibraryStatus(
      hasInstalledLibrary: true,
      recipeCount: recipeCount,
      localLibraryCount: _intMeta(meta, 'local_library_count'),
      cookRecipeCount: _intMeta(meta, 'cook_recipe_count'),
      referenceTitles: _stringListMeta(meta, 'reference_titles_json'),
      libraryId: _stringMeta(meta, 'library_id'),
      libraryVersion: _stringMeta(meta, 'library_version'),
      schemaId: _stringMeta(meta, 'schema_id'),
      schemaVersion: _intMeta(meta, 'schema_version'),
      source: _sourceMeta(meta, 'install_source'),
      installedAt: _dateTimeMeta(meta, 'installed_at'),
      updatedAt: _dateTimeMeta(meta, 'updated_at'),
      errorMessage: _nullableMeta(meta, 'error_message'),
    );
  }

  DailyChoiceEatLibraryStatus _inspectDatabaseFile(File file) {
    final db = sqlite3.open(file.path);
    try {
      db.execute('PRAGMA foreign_keys = ON;');
      _ensureSchema(db);
      return _inspectOpenDatabase(db);
    } finally {
      db.dispose();
    }
  }

  Future<DailyChoiceEatLibraryStatus> installLibrary() async {
    final previousStatus = await inspectStatus();
    _closeDatabase();
    final targetFile = await _databaseFile();
    final candidateFile = File('${targetFile.path}.remote');
    try {
      await _deleteDatabaseArtifacts(candidateFile);
      final remoteUpdatedAt =
          await (_remoteDatabaseInstaller ?? _downloadRemoteDatabase)(
            candidateFile,
          );
      await _normalizeInstalledRemoteDatabaseMeta(
        databaseFile: candidateFile,
        remoteUpdatedAt: remoteUpdatedAt,
      );
      final status = _inspectDatabaseFile(candidateFile);
      if (!status.hasInstalledLibrary || status.recipeCount <= 0) {
        throw StateError('Remote cook_data library database is empty.');
      }
      await _replaceDatabaseFile(
        candidateFile: candidateFile,
        targetFile: targetFile,
      );
      await _deleteDatabaseArtifacts(candidateFile);
      await _deleteLegacyLibraryFiles();
      return inspectStatus();
    } catch (error) {
      await _deleteDatabaseArtifacts(candidateFile);
      await _deleteLegacyLibraryFiles();
      if (previousStatus.hasInstalledLibrary) {
        return previousStatus.copyWith(errorMessage: '$error');
      }
      await _deleteDatabaseArtifacts(targetFile);
      return DailyChoiceEatLibraryStatus(
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
    final file = await _databaseFile();
    final databasePath = file.path;
    try {
      return await Isolate.run(
        () => _loadBuiltInSummariesFromDatabaseFile(databasePath),
      );
    } catch (_) {
      return _loadBuiltInSummariesFromDatabase();
    }
  }

  Future<List<DailyChoiceOption>> _loadBuiltInSummariesFromDatabase() async {
    final db = await _database();
    return _loadBuiltInSummariesFromDatabaseConnection(
      db,
      recipesTable: _recipesTable,
    );
  }

  Future<DailyChoiceOption?> loadBuiltInDetail(String recipeId) async {
    final db = await _database();
    final rows = db.select(
      '''
      SELECT
        s.id,
        s.module_id,
        s.category_id,
        s.context_id,
        s.context_ids_json,
        s.title_zh,
        s.title_en,
        s.subtitle_zh,
        s.subtitle_en,
        s.tags_zh_json,
        s.tags_en_json,
        s.attributes_json,
        s.source_label,
        s.source_url,
        d.details_zh,
        d.details_en,
        d.materials_zh_json,
        d.materials_en_json,
        d.steps_zh_json,
        d.steps_en_json,
        d.notes_zh_json,
        d.notes_en_json,
        d.references_json
      FROM $_recipesTable s
      LEFT JOIN $_detailsTable d
        ON d.recipe_id = s.id
      WHERE s.id = ?
      LIMIT 1
      ''',
      <Object?>[recipeId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _detailOptionFromRow(rows.first);
  }

  Future<void> close() async {
    _closeDatabase();
    if (_ownsS3Client) {
      await _s3Client.close();
    }
  }

  void _closeDatabase() {
    _db?.dispose();
    _db = null;
  }

  Future<DateTime?> _downloadRemoteDatabase(File targetFile) async {
    final remoteHead = await _s3Client.headObject(remoteDatabaseKey);
    await targetFile.parent.create(recursive: true);
    final tempFile = File('${targetFile.path}.part');
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
    try {
      await _s3Client.downloadObjectToFile(remoteDatabaseKey, tempFile);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await tempFile.rename(targetFile.path);
      return remoteHead.lastModified;
    } catch (_) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }

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

  Future<void> _normalizeInstalledRemoteDatabaseMeta({
    required File databaseFile,
    required DateTime? remoteUpdatedAt,
  }) async {
    final db = sqlite3.open(databaseFile.path);
    try {
      _ensureSchema(db);
      final previousMeta = _metaMap(db);
      final now = DateTime.now().toIso8601String();
      final previousUpdatedAt = _stringMeta(previousMeta, 'updated_at');
      final normalizedUpdatedAt =
          remoteUpdatedAt?.toIso8601String() ??
          (previousUpdatedAt.trim().isNotEmpty ? previousUpdatedAt : now);
      _upsertMeta(db, 'install_source', DailyChoiceCookDataSource.remote.name);
      _upsertMeta(db, 'installed_at', now);
      _upsertMeta(db, 'updated_at', normalizedUpdatedAt);
      _upsertMeta(db, 'error_message', '');
      db.execute('PRAGMA user_version = $_schemaVersion;');
      db.execute('PRAGMA wal_checkpoint(TRUNCATE);');
    } finally {
      db.dispose();
    }
  }

  Future<void> _deleteLegacyLibraryFiles() async {
    final cachedLibrary = await _cachedLibraryFile();
    if (await cachedLibrary.exists()) {
      await cachedLibrary.delete();
    }
    final legacyCookCache = await _legacyCookCacheFile();
    if (await legacyCookCache.exists()) {
      await legacyCookCache.delete();
    }
  }

  Future<File> _cachedLibraryFile() async {
    final directory = await _supportDirectoryProvider();
    await directory.create(recursive: true);
    return File(p.join(directory.path, cachedLibraryFileName));
  }

  Future<File> _databaseFile() async {
    final directory = await _supportDirectoryProvider();
    await directory.create(recursive: true);
    return File(p.join(directory.path, databaseFileName));
  }

  Future<File> _legacyCookCacheFile() async {
    final directory = await _supportDirectoryProvider();
    await directory.create(recursive: true);
    return File(p.join(directory.path, 'toolbox_daily_choice_cook_recipe.csv'));
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

  void _ensureSchema(Database db) {
    final currentVersion = _readSchemaVersion(db);
    if (currentVersion > _schemaVersion) {
      throw StateError(
        'Eat recipe library schema version $currentVersion is newer than supported $_schemaVersion.',
      );
    }
    if (currentVersion != 0 && currentVersion != _schemaVersion) {
      _resetTables(db);
    }
    db.execute('''
      CREATE TABLE IF NOT EXISTS $_recipesTable (
        id TEXT PRIMARY KEY,
        module_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        context_id TEXT,
        context_ids_json TEXT NOT NULL,
        title_zh TEXT NOT NULL,
        title_en TEXT NOT NULL,
        subtitle_zh TEXT NOT NULL,
        subtitle_en TEXT NOT NULL,
        tags_zh_json TEXT NOT NULL,
        tags_en_json TEXT NOT NULL,
        attributes_json TEXT NOT NULL,
        source_label TEXT,
        source_url TEXT,
        search_title TEXT NOT NULL,
        sort_key TEXT NOT NULL
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS $_detailsTable (
        recipe_id TEXT PRIMARY KEY,
        details_zh TEXT NOT NULL,
        details_en TEXT NOT NULL,
        materials_zh_json TEXT NOT NULL,
        materials_en_json TEXT NOT NULL,
        steps_zh_json TEXT NOT NULL,
        steps_en_json TEXT NOT NULL,
        notes_zh_json TEXT NOT NULL,
        notes_en_json TEXT NOT NULL,
        references_json TEXT NOT NULL,
        FOREIGN KEY (recipe_id) REFERENCES $_recipesTable(id) ON DELETE CASCADE
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS $_indexTermsTable (
        recipe_id TEXT NOT NULL,
        term_group TEXT NOT NULL,
        term_value TEXT NOT NULL,
        PRIMARY KEY (recipe_id, term_group, term_value),
        FOREIGN KEY (recipe_id) REFERENCES $_recipesTable(id) ON DELETE CASCADE
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS $_metaTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_daily_choice_eat_recipe_category ON $_recipesTable(category_id, id)',
    );
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_daily_choice_eat_recipe_context ON $_recipesTable(context_id, id)',
    );
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_daily_choice_eat_recipe_search_title ON $_recipesTable(search_title)',
    );
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_daily_choice_eat_recipe_sort ON $_recipesTable(sort_key, id)',
    );
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_daily_choice_eat_recipe_index_terms ON $_indexTermsTable(term_group, term_value, recipe_id)',
    );
    db.execute('PRAGMA user_version = $_schemaVersion;');
  }

  void _resetTables(Database db) {
    db.execute('DROP TABLE IF EXISTS $_indexTermsTable;');
    db.execute('DROP TABLE IF EXISTS $_detailsTable;');
    db.execute('DROP TABLE IF EXISTS $_recipesTable;');
    db.execute('DROP TABLE IF EXISTS $_metaTable;');
  }

  bool _tableExists(Database db, String tableName) {
    final rows = db.select(
      '''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table' AND name = ?
      LIMIT 1
      ''',
      <Object?>[tableName],
    );
    return rows.isNotEmpty;
  }

  Map<String, String> _metaMap(Database db) {
    final rows = db.select('SELECT key, value FROM $_metaTable');
    return <String, String>{
      for (final row in rows) '${row['key'] ?? ''}': '${row['value'] ?? ''}',
    };
  }

  int _readSchemaVersion(Database db) {
    final rows = db.select('PRAGMA user_version');
    return (rows.firstOrNull?['user_version'] as num?)?.toInt() ?? 0;
  }

  void _upsertMeta(Database db, String key, String value) {
    db.execute(
      '''
      INSERT INTO $_metaTable (key, value)
      VALUES (?, ?)
      ON CONFLICT(key) DO UPDATE SET value = excluded.value
      ''',
      <Object?>[key, value],
    );
  }

  DailyChoiceOption _detailOptionFromRow(Row row) {
    return ensureEatOptionAttributes(
      DailyChoiceOption(
        id: '${row['id'] ?? ''}',
        moduleId: '${row['module_id'] ?? ''}',
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
        attributes: _jsonStringListMap(row['attributes_json']),
        sourceLabel: _nullableString(row['source_label']),
        sourceUrl: _nullableString(row['source_url']),
        references: _jsonReferenceList(row['references_json']),
      ),
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

  static DailyChoiceCookDataSource? _sourceMeta(
    Map<String, String> meta,
    String key,
  ) {
    final value = (meta[key] ?? '').trim();
    if (value.isEmpty) {
      return null;
    }
    for (final item in DailyChoiceCookDataSource.values) {
      if (item.name == value) {
        return item;
      }
    }
    return null;
  }

  static List<String> _stringListMeta(Map<String, String> meta, String key) {
    return _jsonStringList(meta[key]);
  }
}

List<DailyChoiceOption> _loadBuiltInSummariesFromDatabaseFile(String dbPath) {
  final db = sqlite3.open(dbPath);
  try {
    return _loadBuiltInSummariesFromDatabaseConnection(
      db,
      recipesTable: 'daily_choice_eat_recipe_summaries',
    );
  } finally {
    db.dispose();
  }
}

List<DailyChoiceOption> _loadBuiltInSummariesFromDatabaseConnection(
  Database db, {
  required String recipesTable,
}) {
  final rows = db.select('''
    SELECT
      id,
      module_id,
      category_id,
      context_id,
      context_ids_json,
      title_zh,
      title_en,
      subtitle_zh,
      subtitle_en,
      tags_zh_json,
      tags_en_json,
      attributes_json,
      source_label,
      source_url
    FROM $recipesTable
    ORDER BY sort_key ASC, id ASC
  ''');
  return List<DailyChoiceOption>.unmodifiable(
    rows.map(_summaryOptionFromDatabaseRow),
  );
}

DailyChoiceOption _summaryOptionFromDatabaseRow(Row row) {
  return ensureEatOptionAttributes(
    DailyChoiceOption(
      id: '${row['id'] ?? ''}',
      moduleId: '${row['module_id'] ?? ''}',
      categoryId: '${row['category_id'] ?? ''}',
      contextId: _nullableString(row['context_id']),
      contextIds: _jsonStringList(row['context_ids_json']),
      titleZh: '${row['title_zh'] ?? ''}',
      titleEn: '${row['title_en'] ?? ''}',
      subtitleZh: '${row['subtitle_zh'] ?? ''}',
      subtitleEn: '${row['subtitle_en'] ?? ''}',
      detailsZh: '',
      detailsEn: '',
      tagsZh: _jsonStringList(row['tags_zh_json']),
      tagsEn: _jsonStringList(row['tags_en_json']),
      attributes: _jsonStringListMap(row['attributes_json']),
      sourceLabel: _nullableString(row['source_label']),
      sourceUrl: _nullableString(row['source_url']),
    ),
  );
}

String? _nullableString(Object? value) {
  final text = '${value ?? ''}'.trim();
  return text.isEmpty ? null : text;
}

List<String> _jsonStringList(Object? value) {
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

Map<String, List<String>> _jsonStringListMap(Object? value) {
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

List<DailyChoiceReferenceLink> _jsonReferenceList(Object? value) {
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

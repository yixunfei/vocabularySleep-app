import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../../services/cstcloud_s3_compat_client.dart';
import 'daily_choice_cook_service.dart';
import 'daily_choice_eat_catalog.dart';
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

class DailyChoiceEatLibraryQuery {
  const DailyChoiceEatLibraryQuery({
    this.mealId = 'all',
    this.toolId = 'all',
    this.selectedTraitFilters = const <String, Set<String>>{},
    this.excludedContains = const <String>{},
    this.customExcludedIngredients = const <String>[],
    this.availableIngredients = const <String>[],
    this.preferAvailableIngredients = false,
    this.allowedOptionIds,
    this.setIds = const <String>[],
    this.limit = 50,
    this.offset = 0,
  });

  final String mealId;
  final String toolId;
  final Map<String, Set<String>> selectedTraitFilters;
  final Set<String> excludedContains;
  final Iterable<String> customExcludedIngredients;
  final Iterable<String> availableIngredients;
  final bool preferAvailableIngredients;
  final Iterable<String>? allowedOptionIds;
  final Iterable<String> setIds;
  final int limit;
  final int offset;
}

class DailyChoiceEatLibraryQueryResult {
  const DailyChoiceEatLibraryQueryResult({
    required this.options,
    required this.totalCount,
    required this.randomCandidateIds,
    required this.limit,
    required this.offset,
  });

  DailyChoiceEatLibraryQueryResult.empty(DailyChoiceEatLibraryQuery query)
    : options = const <DailyChoiceOption>[],
      totalCount = 0,
      randomCandidateIds = const <String>[],
      limit = _normalizedQueryLimit(query.limit),
      offset = _normalizedQueryOffset(query.offset);

  final List<DailyChoiceOption> options;
  final int totalCount;
  final List<String> randomCandidateIds;
  final int limit;
  final int offset;

  bool get hasMore => offset + options.length < totalCount;
}

typedef DailyChoiceEatLibrarySupportDirectoryProvider =
    Future<Directory> Function();
typedef DailyChoiceEatLibraryRemoteDatabaseInstaller =
    Future<DateTime?> Function(File targetFile);

enum _DailyChoiceEatLibrarySchema { empty, legacyV1, v2 }

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

  final math.Random _random = math.Random();
  Database? _db;

  static const int _legacySchemaVersion = 1;
  static const int _v2SchemaVersion = 2;
  static const String _recipesTable = 'daily_choice_eat_recipe_summaries';
  static const String _detailsTable = 'daily_choice_eat_recipe_details';
  static const String _indexTermsTable = 'daily_choice_eat_recipe_index_terms';
  static const String _metaTable = 'daily_choice_eat_recipe_meta';
  static const String _v2RecipesTable = 'daily_choice_recipes';
  static const String _v2SummariesTable = 'daily_choice_recipe_summaries';
  static const String _v2DetailsTable = 'daily_choice_recipe_details';
  static const String _v2SetsTable = 'daily_choice_recipe_sets';
  static const String _v2MetaTable = 'daily_choice_recipe_schema_meta';
  static const String _v2FilterIndexTable = 'daily_choice_recipe_filter_index';
  static const String _v2IngredientIndexTable =
      'daily_choice_recipe_ingredient_index';
  static const String _v2BookSetId = 'book_library';
  static const String _v2CookSetId = 'cook_csv';

  Future<DailyChoiceEatLibraryStatus> inspectStatus() async {
    final file = await _databaseFile();
    if (!await file.exists()) {
      return const DailyChoiceEatLibraryStatus.empty();
    }
    final db = await _database();
    return _inspectOpenDatabase(db);
  }

  DailyChoiceEatLibraryStatus _inspectOpenDatabase(Database db) {
    return switch (_detectLibrarySchema(db)) {
      _DailyChoiceEatLibrarySchema.v2 => _inspectV2Database(db),
      _DailyChoiceEatLibrarySchema.legacyV1 => _inspectLegacyDatabase(db),
      _DailyChoiceEatLibrarySchema.empty =>
        const DailyChoiceEatLibraryStatus.empty(),
    };
  }

  DailyChoiceEatLibraryStatus _inspectLegacyDatabase(Database db) {
    final countRow = db.select('SELECT COUNT(*) AS total FROM $_recipesTable');
    final recipeCount = (countRow.firstOrNull?['total'] as num?)?.toInt() ?? 0;
    if (recipeCount <= 0) {
      return const DailyChoiceEatLibraryStatus.empty();
    }

    final meta = _metaMap(db, tableName: _metaTable);
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

  DailyChoiceEatLibraryStatus _inspectV2Database(Database db) {
    final countRow = db.select('''
      SELECT COUNT(*) AS total
      FROM $_v2RecipesTable
      WHERE status = 'active' AND is_available = 1
      ''');
    final recipeCount = (countRow.firstOrNull?['total'] as num?)?.toInt() ?? 0;
    if (recipeCount <= 0) {
      return const DailyChoiceEatLibraryStatus.empty();
    }

    final meta = _metaMap(db, tableName: _v2MetaTable);
    return DailyChoiceEatLibraryStatus(
      hasInstalledLibrary: true,
      recipeCount: recipeCount,
      localLibraryCount: _v2SetRecipeCount(db, _v2BookSetId),
      cookRecipeCount: _v2SetRecipeCount(db, _v2CookSetId),
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

  int _v2SetRecipeCount(Database db, String setId) {
    if (_tableExists(db, _v2SetsTable)) {
      final rows = db.select(
        '''
        SELECT recipe_count
        FROM $_v2SetsTable
        WHERE set_id = ?
        LIMIT 1
        ''',
        <Object?>[setId],
      );
      final count = (rows.firstOrNull?['recipe_count'] as num?)?.toInt();
      if (count != null && count > 0) {
        return count;
      }
    }
    final rows = db.select(
      '''
      SELECT COUNT(*) AS total
      FROM $_v2RecipesTable
      WHERE primary_set_id = ?
        AND status = 'active'
        AND is_available = 1
      ''',
      <Object?>[setId],
    );
    return (rows.firstOrNull?['total'] as num?)?.toInt() ?? 0;
  }

  DailyChoiceEatLibraryStatus _inspectDatabaseFile(File file) {
    final db = sqlite3.open(file.path);
    try {
      db.execute('PRAGMA foreign_keys = ON;');
      _ensureReadableSchema(db);
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
    return _loadBuiltInSummariesFromDatabaseConnection(db);
  }

  Future<DailyChoiceEatLibraryQueryResult> queryBuiltInSummaries(
    DailyChoiceEatLibraryQuery query,
  ) async {
    final status = await inspectStatus();
    if (!status.hasInstalledLibrary) {
      return DailyChoiceEatLibraryQueryResult.empty(query);
    }
    final db = await _database();
    return switch (_detectLibrarySchema(db)) {
      _DailyChoiceEatLibrarySchema.v2 => _queryBuiltInV2Summaries(db, query),
      _DailyChoiceEatLibrarySchema.legacyV1 => _queryBuiltInInMemorySummaries(
        _loadBuiltInLegacySummariesFromDatabaseConnection(db),
        query,
      ),
      _DailyChoiceEatLibrarySchema.empty =>
        DailyChoiceEatLibraryQueryResult.empty(query),
    };
  }

  Future<DailyChoiceOption?> pickBuiltInRandomSummary(
    DailyChoiceEatLibraryQuery query, {
    int? pivotKey,
  }) async {
    final status = await inspectStatus();
    if (!status.hasInstalledLibrary) {
      return null;
    }
    final db = await _database();
    final resolvedPivot = pivotKey ?? _nextRandomPivotKey();
    return switch (_detectLibrarySchema(db)) {
      _DailyChoiceEatLibrarySchema.v2 => _pickBuiltInV2RandomSummary(
        db,
        query,
        resolvedPivot,
      ),
      _DailyChoiceEatLibrarySchema.legacyV1 =>
        _pickBuiltInInMemoryRandomSummary(
          _loadBuiltInLegacySummariesFromDatabaseConnection(db),
          query,
          resolvedPivot,
        ),
      _DailyChoiceEatLibrarySchema.empty => null,
    };
  }

  Future<DailyChoiceOption?> loadBuiltInDetail(String recipeId) async {
    final db = await _database();
    if (_detectLibrarySchema(db) == _DailyChoiceEatLibrarySchema.v2) {
      return _loadBuiltInV2Detail(db, recipeId);
    }
    return _loadBuiltInLegacyDetail(db, recipeId);
  }

  DailyChoiceOption? _loadBuiltInLegacyDetail(Database db, String recipeId) {
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
    return _detailOptionFromLegacyRow(rows.first);
  }

  DailyChoiceOption? _loadBuiltInV2Detail(Database db, String recipeId) {
    final rows = db.select(
      '''
      SELECT
        r.recipe_id,
        r.title_zh,
        r.title_en,
        r.primary_meal_id,
        r.primary_tool_id,
        s.subtitle_zh,
        s.subtitle_en,
        s.tags_zh_json,
        s.tags_en_json,
        s.summary_attributes_json,
        d.details_zh,
        d.details_en,
        d.materials_zh_json,
        d.materials_en_json,
        d.steps_zh_json,
        d.steps_en_json,
        d.notes_zh_json,
        d.notes_en_json,
        d.raw_payload_json
      FROM $_v2RecipesTable r
      LEFT JOIN $_v2SummariesTable s
        ON s.recipe_id = r.recipe_id
      LEFT JOIN $_v2DetailsTable d
        ON d.recipe_id = r.recipe_id
      WHERE r.recipe_id = ?
      LIMIT 1
      ''',
      <Object?>[recipeId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _detailOptionFromV2Row(rows.first);
  }

  DailyChoiceEatLibraryQueryResult _queryBuiltInV2Summaries(
    Database db,
    DailyChoiceEatLibraryQuery query,
  ) {
    if (!_tableExists(db, _v2FilterIndexTable) ||
        !_tableExists(db, _v2IngredientIndexTable)) {
      return _queryBuiltInInMemorySummaries(
        _loadBuiltInV2SummariesFromDatabaseConnection(db),
        query,
      );
    }

    final limit = _normalizedQueryLimit(query.limit);
    final offset = _normalizedQueryOffset(query.offset);
    final filter = _buildV2QueryFilter(query);
    final totalCount = _countV2Recipes(db, filter);
    final rows = db.select(
      '''
      SELECT
        r.recipe_id,
        r.title_zh,
        r.title_en,
        r.primary_meal_id,
        r.primary_tool_id,
        s.subtitle_zh,
        s.subtitle_en,
        s.tags_zh_json,
        s.tags_en_json,
        s.summary_attributes_json
      FROM $_v2RecipesTable r
      LEFT JOIN $_v2SummariesTable s
        ON s.recipe_id = r.recipe_id
      WHERE ${filter.whereClause}
      ORDER BY r.sort_key ASC, r.recipe_id ASC
      LIMIT ? OFFSET ?
      ''',
      <Object?>[...filter.args, limit, offset],
    );
    final options = List<DailyChoiceOption>.unmodifiable(
      rows.map(_summaryOptionFromV2DatabaseRow),
    );
    final randomCandidateIds = _selectV2RandomCandidateIds(db, query, filter);
    return DailyChoiceEatLibraryQueryResult(
      options: options,
      totalCount: totalCount,
      randomCandidateIds: randomCandidateIds,
      limit: limit,
      offset: offset,
    );
  }

  DailyChoiceEatLibraryQueryResult _queryBuiltInInMemorySummaries(
    List<DailyChoiceOption> summaries,
    DailyChoiceEatLibraryQuery query,
  ) {
    final limit = _normalizedQueryLimit(query.limit);
    final offset = _normalizedQueryOffset(query.offset);
    final setIds = _normalizedStringList(query.setIds).toSet();
    final scopedSummaries = setIds.isEmpty
        ? summaries
        : summaries
              .where((item) => setIds.contains(_v2PrimarySetIdForOption(item)))
              .toList(growable: false);
    final catalog = DailyChoiceEatCatalog.fromOptions(scopedSummaries);
    final filtered = catalog.filter(
      mealId: query.mealId,
      toolId: query.toolId,
      selectedTraitFilters: query.selectedTraitFilters,
      excludedContains: query.excludedContains,
      customExcludedIngredients: query.customExcludedIngredients,
      availableIngredients: query.availableIngredients,
      preferAvailableIngredients: query.preferAvailableIngredients,
      allowedOptionIds: query.allowedOptionIds,
    );
    return DailyChoiceEatLibraryQueryResult(
      options: List<DailyChoiceOption>.unmodifiable(
        filtered.eligibleOptions.skip(offset).take(limit),
      ),
      totalCount: filtered.eligibleOptions.length,
      randomCandidateIds: List<String>.unmodifiable(
        filtered.randomPool.map((item) => item.id),
      ),
      limit: limit,
      offset: offset,
    );
  }

  _V2QueryFilter _buildV2QueryFilter(
    DailyChoiceEatLibraryQuery query, {
    Iterable<String> requiredIngredientTokens = const <String>[],
  }) {
    final clauses = <String>["r.status = 'active'", 'r.is_available = 1'];
    final args = <Object?>[];

    void addInClause(
      String column,
      Iterable<String>? rawValues, {
      required bool emptyMatchesNone,
    }) {
      if (rawValues == null) {
        return;
      }
      final values = _normalizedStringList(rawValues);
      if (values.isEmpty) {
        if (emptyMatchesNone) {
          clauses.add('1 = 0');
        }
        return;
      }
      clauses.add('$column IN (${_sqlPlaceholders(values.length)})');
      args.addAll(values);
    }

    void addFilterExists(String group, Iterable<String> rawValues) {
      final values = _normalizedStringList(rawValues);
      final normalizedGroup = group.trim();
      if (normalizedGroup.isEmpty || values.isEmpty) {
        return;
      }
      clauses.add('''
        EXISTS (
          SELECT 1
          FROM $_v2FilterIndexTable f
          WHERE f.recipe_id = r.recipe_id
            AND f.set_id = r.primary_set_id
            AND f.term_group = ?
            AND f.term_value IN (${_sqlPlaceholders(values.length)})
        )
        ''');
      args.add(normalizedGroup);
      args.addAll(values);
    }

    void addIngredientExists(
      Iterable<String> rawValues, {
      required bool negate,
    }) {
      final values = _normalizedStringList(rawValues);
      if (values.isEmpty) {
        return;
      }
      clauses.add('''
        ${negate ? 'NOT ' : ''}EXISTS (
          SELECT 1
          FROM $_v2IngredientIndexTable i
          WHERE i.recipe_id = r.recipe_id
            AND i.set_id = r.primary_set_id
            AND i.token_kind IN ('raw', 'canonical')
            AND i.token_value IN (${_sqlPlaceholders(values.length)})
        )
        ''');
      args.addAll(values);
    }

    addInClause('r.primary_set_id', query.setIds, emptyMatchesNone: false);
    addInClause('r.recipe_id', query.allowedOptionIds, emptyMatchesNone: true);

    final mealId = query.mealId.trim();
    if (mealId.isNotEmpty && mealId != 'all') {
      addFilterExists(eatAttributeMeal, <String>[mealId]);
    }
    final toolId = query.toolId.trim();
    if (toolId.isNotEmpty && toolId != 'all') {
      addFilterExists(eatAttributeTool, <String>[toolId]);
    }

    for (final entry in query.selectedTraitFilters.entries) {
      addFilterExists(entry.key, entry.value);
    }

    final excludedTokens = _expandedExcludedIngredientTokens(
      selectedContains: query.excludedContains,
      customExcludedIngredients: query.customExcludedIngredients,
    );
    if (excludedTokens.isNotEmpty) {
      _addFilterExistsNot(eatAttributeContains, excludedTokens, clauses, args);
      addIngredientExists(excludedTokens, negate: true);
    }

    addIngredientExists(requiredIngredientTokens, negate: false);

    return _V2QueryFilter(
      whereClause: clauses.join('\n        AND '),
      args: List<Object?>.unmodifiable(args),
    );
  }

  void _addFilterExistsNot(
    String group,
    Iterable<String> rawValues,
    List<String> clauses,
    List<Object?> args,
  ) {
    final values = _normalizedStringList(rawValues);
    final normalizedGroup = group.trim();
    if (normalizedGroup.isEmpty || values.isEmpty) {
      return;
    }
    clauses.add('''
      NOT EXISTS (
        SELECT 1
        FROM $_v2FilterIndexTable f
        WHERE f.recipe_id = r.recipe_id
          AND f.set_id = r.primary_set_id
          AND f.term_group = ?
          AND f.term_value IN (${_sqlPlaceholders(values.length)})
      )
      ''');
    args.add(normalizedGroup);
    args.addAll(values);
  }

  int _countV2Recipes(Database db, _V2QueryFilter filter) {
    final rows = db.select('''
      SELECT COUNT(*) AS total
      FROM $_v2RecipesTable r
      WHERE ${filter.whereClause}
      ''', filter.args);
    return (rows.firstOrNull?['total'] as num?)?.toInt() ?? 0;
  }

  List<String> _selectV2RandomCandidateIds(
    Database db,
    DailyChoiceEatLibraryQuery query,
    _V2QueryFilter eligibleFilter,
  ) {
    final randomFilter = _buildV2RandomCandidateFilter(
      db,
      query,
      eligibleFilter,
    );
    return _selectV2RecipeIds(db, randomFilter);
  }

  _V2QueryFilter _buildV2RandomCandidateFilter(
    Database db,
    DailyChoiceEatLibraryQuery query,
    _V2QueryFilter eligibleFilter,
  ) {
    if (!query.preferAvailableIngredients) {
      return eligibleFilter;
    }
    final availableTokens = normalizeEatIngredientInputs(
      query.availableIngredients,
    );
    if (availableTokens.isEmpty) {
      return eligibleFilter;
    }
    final ingredientFilter = _buildV2QueryFilter(
      query,
      requiredIngredientTokens: availableTokens,
    );
    return _countV2Recipes(db, ingredientFilter) <= 0
        ? eligibleFilter
        : ingredientFilter;
  }

  DailyChoiceOption? _pickBuiltInV2RandomSummary(
    Database db,
    DailyChoiceEatLibraryQuery query,
    int pivotKey,
  ) {
    if (!_tableExists(db, _v2FilterIndexTable) ||
        !_tableExists(db, _v2IngredientIndexTable)) {
      return _pickBuiltInInMemoryRandomSummary(
        _loadBuiltInV2SummariesFromDatabaseConnection(db),
        query,
        pivotKey,
      );
    }

    final eligibleFilter = _buildV2QueryFilter(query);
    final randomFilter = _buildV2RandomCandidateFilter(
      db,
      query,
      eligibleFilter,
    );
    return _selectV2RandomSummaryAtPivot(
          db,
          randomFilter,
          _normalizedV2RandomPivot(pivotKey),
        ) ??
        _selectV2RandomSummaryAtStart(db, randomFilter);
  }

  DailyChoiceOption? _selectV2RandomSummaryAtPivot(
    Database db,
    _V2QueryFilter filter,
    int pivotKey,
  ) {
    final rows = _selectV2RandomSummaryRows(
      db,
      filter,
      extraWhere: 'AND r.random_key >= ?',
      extraArgs: <Object?>[pivotKey],
    );
    return rows.isEmpty ? null : _summaryOptionFromV2DatabaseRow(rows.first);
  }

  DailyChoiceOption? _selectV2RandomSummaryAtStart(
    Database db,
    _V2QueryFilter filter,
  ) {
    final rows = _selectV2RandomSummaryRows(db, filter);
    return rows.isEmpty ? null : _summaryOptionFromV2DatabaseRow(rows.first);
  }

  ResultSet _selectV2RandomSummaryRows(
    Database db,
    _V2QueryFilter filter, {
    String extraWhere = '',
    List<Object?> extraArgs = const <Object?>[],
  }) {
    return db.select(
      '''
      SELECT
        r.recipe_id,
        r.title_zh,
        r.title_en,
        r.primary_meal_id,
        r.primary_tool_id,
        s.subtitle_zh,
        s.subtitle_en,
        s.tags_zh_json,
        s.tags_en_json,
        s.summary_attributes_json
      FROM $_v2RecipesTable r
      LEFT JOIN $_v2SummariesTable s
        ON s.recipe_id = r.recipe_id
      WHERE ${filter.whereClause}
        $extraWhere
      ORDER BY r.random_key ASC, r.recipe_id ASC
      LIMIT 1
      ''',
      <Object?>[...filter.args, ...extraArgs],
    );
  }

  DailyChoiceOption? _pickBuiltInInMemoryRandomSummary(
    List<DailyChoiceOption> summaries,
    DailyChoiceEatLibraryQuery query,
    int pivotKey,
  ) {
    final result = _queryBuiltInInMemorySummaries(summaries, query);
    if (result.randomCandidateIds.isEmpty) {
      return null;
    }
    final pickedId =
        result.randomCandidateIds[_normalizedV2RandomPivot(pivotKey) %
            result.randomCandidateIds.length];
    for (final summary in summaries) {
      if (summary.id == pickedId) {
        return summary;
      }
    }
    return null;
  }

  List<String> _selectV2RecipeIds(Database db, _V2QueryFilter filter) {
    final rows = db.select('''
      SELECT DISTINCT r.recipe_id
      FROM $_v2RecipesTable r
      WHERE ${filter.whereClause}
      ORDER BY r.random_key ASC, r.recipe_id ASC
      ''', filter.args);
    return List<String>.unmodifiable(
      _normalizedStringList(rows.map((row) => '${row['recipe_id']}')),
    );
  }

  int _nextRandomPivotKey() {
    final high = _random.nextInt(1 << 31);
    final middle = _random.nextInt(1 << 31);
    final low = _random.nextInt(2);
    return (high << 32) | (middle << 1) | low;
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
      _ensureReadableSchema(db);
      final schema = _detectLibrarySchema(db);
      final metaTable = schema == _DailyChoiceEatLibrarySchema.v2
          ? _v2MetaTable
          : _metaTable;
      final schemaVersion = schema == _DailyChoiceEatLibrarySchema.v2
          ? _v2SchemaVersion
          : _legacySchemaVersion;
      final previousMeta = _metaMap(db, tableName: metaTable);
      final now = DateTime.now().toIso8601String();
      final previousUpdatedAt = _stringMeta(previousMeta, 'updated_at');
      final normalizedUpdatedAt =
          remoteUpdatedAt?.toIso8601String() ??
          (previousUpdatedAt.trim().isNotEmpty ? previousUpdatedAt : now);
      _upsertMeta(
        db,
        'install_source',
        DailyChoiceCookDataSource.remote.name,
        tableName: metaTable,
      );
      _upsertMeta(db, 'installed_at', now, tableName: metaTable);
      _upsertMeta(db, 'updated_at', normalizedUpdatedAt, tableName: metaTable);
      _upsertMeta(db, 'error_message', '', tableName: metaTable);
      db.execute('PRAGMA user_version = $schemaVersion;');
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
    _ensureReadableSchema(db);
    _db = db;
    return db;
  }

  void _ensureReadableSchema(Database db) {
    if (_detectLibrarySchema(db) == _DailyChoiceEatLibrarySchema.v2) {
      _ensureV2SchemaSupported(db);
      return;
    }
    _ensureLegacySchema(db);
  }

  void _ensureV2SchemaSupported(Database db) {
    final currentVersion = _readSchemaVersion(db);
    if (currentVersion > _v2SchemaVersion) {
      throw StateError(
        'Eat recipe library schema version $currentVersion is newer than supported $_v2SchemaVersion.',
      );
    }
    for (final tableName in <String>[
      _v2RecipesTable,
      _v2SummariesTable,
      _v2DetailsTable,
      _v2MetaTable,
    ]) {
      if (!_tableExists(db, tableName)) {
        throw StateError('Eat recipe v2 library is missing $tableName.');
      }
    }
  }

  void _ensureLegacySchema(Database db) {
    final currentVersion = _readSchemaVersion(db);
    if (currentVersion > _legacySchemaVersion) {
      throw StateError(
        'Eat recipe library schema version $currentVersion is newer than supported $_legacySchemaVersion.',
      );
    }
    if (currentVersion != 0 && currentVersion != _legacySchemaVersion) {
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
    db.execute('PRAGMA user_version = $_legacySchemaVersion;');
  }

  void _resetTables(Database db) {
    db.execute('DROP TABLE IF EXISTS $_indexTermsTable;');
    db.execute('DROP TABLE IF EXISTS $_detailsTable;');
    db.execute('DROP TABLE IF EXISTS $_recipesTable;');
    db.execute('DROP TABLE IF EXISTS $_metaTable;');
  }

  bool _tableExists(Database db, String tableName) {
    return _databaseTableExists(db, tableName);
  }

  Map<String, String> _metaMap(Database db, {required String tableName}) {
    if (!_tableExists(db, tableName)) {
      return const <String, String>{};
    }
    final rows = db.select('SELECT key, value FROM $tableName');
    return <String, String>{
      for (final row in rows) '${row['key'] ?? ''}': '${row['value'] ?? ''}',
    };
  }

  int _readSchemaVersion(Database db) {
    final rows = db.select('PRAGMA user_version');
    return (rows.firstOrNull?['user_version'] as num?)?.toInt() ?? 0;
  }

  void _upsertMeta(
    Database db,
    String key,
    String value, {
    required String tableName,
  }) {
    db.execute(
      '''
      INSERT INTO $tableName (key, value)
      VALUES (?, ?)
      ON CONFLICT(key) DO UPDATE SET value = excluded.value
      ''',
      <Object?>[key, value],
    );
  }

  DailyChoiceOption _detailOptionFromLegacyRow(Row row) {
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

  DailyChoiceOption _detailOptionFromV2Row(Row row) {
    final attributes = _jsonStringListMap(row['summary_attributes_json']);
    final contextId = _v2ContextId(row, attributes);
    return ensureEatOptionAttributes(
      DailyChoiceOption(
        id: '${row['recipe_id'] ?? ''}',
        moduleId: DailyChoiceModuleId.eat.storageValue,
        categoryId: _v2MealId(row),
        contextId: contextId,
        contextIds: _v2ContextIds(row, attributes),
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
        attributes: attributes,
        sourceLabel: _rawPayloadNullableString(
          row['raw_payload_json'],
          'sourceLabel',
        ),
        sourceUrl: _rawPayloadNullableString(
          row['raw_payload_json'],
          'sourceUrl',
        ),
        references: _rawPayloadReferences(row['raw_payload_json']),
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

class _V2QueryFilter {
  const _V2QueryFilter({required this.whereClause, required this.args});

  final String whereClause;
  final List<Object?> args;
}

int _normalizedQueryLimit(int value) {
  if (value <= 0) {
    return 50;
  }
  return value > 200 ? 200 : value;
}

int _normalizedQueryOffset(int value) {
  return value < 0 ? 0 : value;
}

int _normalizedV2RandomPivot(int value) {
  if (value < 0) {
    return 0;
  }
  const maxSigned63Bit = 0x7FFFFFFFFFFFFFFF;
  return value > maxSigned63Bit ? maxSigned63Bit : value;
}

List<String> _normalizedStringList(Iterable<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final normalized = value.trim();
    if (normalized.isNotEmpty && seen.add(normalized)) {
      result.add(normalized);
    }
  }
  return List<String>.unmodifiable(result);
}

List<String> _expandedExcludedIngredientTokens({
  required Iterable<String> selectedContains,
  required Iterable<String> customExcludedIngredients,
}) {
  final tokens = <String>{};
  for (final token in selectedContains) {
    tokens.addAll(eatContainsExpandedTokens(token));
  }
  for (final token in normalizeEatIngredientInputs(customExcludedIngredients)) {
    tokens.addAll(eatContainsExpandedTokens(token));
  }
  return List<String>.unmodifiable(tokens);
}

String _sqlPlaceholders(int count) {
  return List<String>.filled(count, '?').join(', ');
}

String _v2PrimarySetIdForOption(DailyChoiceOption option) {
  if (option.id.startsWith('${DailyChoiceEatLibraryStore._v2CookSetId}_')) {
    return DailyChoiceEatLibraryStore._v2CookSetId;
  }
  if (option
      .attributeValues('recipeSet')
      .contains(DailyChoiceEatLibraryStore._v2CookSetId)) {
    return DailyChoiceEatLibraryStore._v2CookSetId;
  }
  return DailyChoiceEatLibraryStore._v2BookSetId;
}

List<DailyChoiceOption> _loadBuiltInSummariesFromDatabaseFile(String dbPath) {
  final db = sqlite3.open(dbPath);
  try {
    return _loadBuiltInSummariesFromDatabaseConnection(db);
  } finally {
    db.dispose();
  }
}

List<DailyChoiceOption> _loadBuiltInSummariesFromDatabaseConnection(
  Database db,
) {
  return switch (_detectLibrarySchema(db)) {
    _DailyChoiceEatLibrarySchema.v2 =>
      _loadBuiltInV2SummariesFromDatabaseConnection(db),
    _DailyChoiceEatLibrarySchema.legacyV1 =>
      _loadBuiltInLegacySummariesFromDatabaseConnection(db),
    _DailyChoiceEatLibrarySchema.empty => const <DailyChoiceOption>[],
  };
}

List<DailyChoiceOption> _loadBuiltInLegacySummariesFromDatabaseConnection(
  Database db,
) {
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
    FROM daily_choice_eat_recipe_summaries
    ORDER BY sort_key ASC, id ASC
  ''');
  return List<DailyChoiceOption>.unmodifiable(
    rows.map(_summaryOptionFromLegacyDatabaseRow),
  );
}

List<DailyChoiceOption> _loadBuiltInV2SummariesFromDatabaseConnection(
  Database db,
) {
  final rows = db.select('''
    SELECT
      r.recipe_id,
      r.title_zh,
      r.title_en,
      r.primary_meal_id,
      r.primary_tool_id,
      s.subtitle_zh,
      s.subtitle_en,
      s.tags_zh_json,
      s.tags_en_json,
      s.summary_attributes_json
    FROM daily_choice_recipes r
    LEFT JOIN daily_choice_recipe_summaries s
      ON s.recipe_id = r.recipe_id
    WHERE r.status = 'active'
      AND r.is_available = 1
    ORDER BY r.sort_key ASC, r.recipe_id ASC
  ''');
  return List<DailyChoiceOption>.unmodifiable(
    rows.map(_summaryOptionFromV2DatabaseRow),
  );
}

DailyChoiceOption _summaryOptionFromLegacyDatabaseRow(Row row) {
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

DailyChoiceOption _summaryOptionFromV2DatabaseRow(Row row) {
  final attributes = _jsonStringListMap(row['summary_attributes_json']);
  final contextId = _v2ContextId(row, attributes);
  return ensureEatOptionAttributes(
    DailyChoiceOption(
      id: '${row['recipe_id'] ?? ''}',
      moduleId: DailyChoiceModuleId.eat.storageValue,
      categoryId: _v2MealId(row),
      contextId: contextId,
      contextIds: _v2ContextIds(row, attributes),
      titleZh: '${row['title_zh'] ?? ''}',
      titleEn: '${row['title_en'] ?? ''}',
      subtitleZh: '${row['subtitle_zh'] ?? ''}',
      subtitleEn: '${row['subtitle_en'] ?? ''}',
      detailsZh: '',
      detailsEn: '',
      tagsZh: _jsonStringList(row['tags_zh_json']),
      tagsEn: _jsonStringList(row['tags_en_json']),
      attributes: attributes,
    ),
  );
}

_DailyChoiceEatLibrarySchema _detectLibrarySchema(Database db) {
  if (_databaseTableExists(db, 'daily_choice_recipes') &&
      _databaseTableExists(db, 'daily_choice_recipe_summaries') &&
      _databaseTableExists(db, 'daily_choice_recipe_details')) {
    return _DailyChoiceEatLibrarySchema.v2;
  }
  if (_databaseTableExists(db, 'daily_choice_eat_recipe_summaries') &&
      _databaseTableExists(db, 'daily_choice_eat_recipe_details')) {
    return _DailyChoiceEatLibrarySchema.legacyV1;
  }
  return _DailyChoiceEatLibrarySchema.empty;
}

bool _databaseTableExists(Database db, String tableName) {
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

String _v2MealId(Row row) {
  final value = '${row['primary_meal_id'] ?? ''}'.trim();
  return value.isEmpty ? 'all' : value;
}

String? _v2ContextId(Row row, Map<String, List<String>> attributes) {
  final primaryTool = _nullableString(row['primary_tool_id']);
  if (primaryTool != null) {
    return primaryTool;
  }
  return attributes[eatAttributeTool]?.firstOrNull;
}

List<String> _v2ContextIds(Row row, Map<String, List<String>> attributes) {
  final primaryTool = _nullableString(row['primary_tool_id']);
  return _dedupeNonEmptyStrings(<String>[
    ?primaryTool,
    ...(attributes[eatAttributeTool] ?? const <String>[]),
  ]);
}

List<String> _dedupeNonEmptyStrings(List<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final normalized = value.trim();
    if (normalized.isNotEmpty && seen.add(normalized)) {
      result.add(normalized);
    }
  }
  return List<String>.unmodifiable(result);
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

Map<String, Object?> _jsonObjectMap(Object? value) {
  final raw = '${value ?? ''}'.trim();
  if (raw.isEmpty) {
    return const <String, Object?>{};
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, Object?>();
    }
  } catch (_) {
    return const <String, Object?>{};
  }
  return const <String, Object?>{};
}

String? _rawPayloadNullableString(Object? value, String key) {
  return _nullableString(_jsonObjectMap(value)[key]);
}

List<DailyChoiceReferenceLink> _rawPayloadReferences(Object? value) {
  return _jsonReferenceList(_jsonObjectMap(value)['references']);
}

part of 'database_service.dart';

extension AppDatabaseServiceWordbookQuery on AppDatabaseService {
  void ensureSpecialWordbooks() {
    for (final entry in AppDatabaseService._specialWordbooks.entries) {
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
      <Object?>['${AppDatabaseService._dictBuiltinPathPrefix}%'],
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
      path.startsWith(AppDatabaseService._dictBuiltinPathPrefix);

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
    final raw = getSetting(
      AppDatabaseService._hiddenBuiltInWordbooksSettingKey,
    );
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
                item.isNotEmpty &&
                item.startsWith(AppDatabaseService._dictBuiltinPathPrefix),
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
                  item.isNotEmpty &&
                  item.startsWith(AppDatabaseService._dictBuiltinPathPrefix),
            )
            .toList(growable: false)
          ..sort();
    setSetting(
      AppDatabaseService._hiddenBuiltInWordbooksSettingKey,
      jsonEncode(normalized),
    );
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
      'SELECT * FROM words WHERE wordbook_id = ? ORDER BY ${AppDatabaseService._wordOrderClause} LIMIT ? OFFSET ?',
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
      '''
      SELECT
        id,
        wordbook_id,
        word,
        meaning,
        entry_uid,
        primary_gloss,
        schema_version,
        sort_index
      FROM words
      WHERE wordbook_id = ?
      ORDER BY ${AppDatabaseService._wordOrderClause}
      LIMIT ? OFFSET ?
      ''',
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
      'SELECT word FROM words WHERE wordbook_id = ? ORDER BY ${AppDatabaseService._wordOrderClause} LIMIT ? OFFSET ?',
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
      SELECT
        id,
        wordbook_id,
        word,
        meaning,
        entry_uid,
        primary_gloss,
        schema_version,
        sort_index
      FROM words
      WHERE $whereClause
      ORDER BY ${AppDatabaseService._wordOrderClause}
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
      ORDER BY ${AppDatabaseService._wordOrderClause}
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
        ORDER BY ${AppDatabaseService._wordOrderClause}
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
      ORDER BY ${AppDatabaseService._wordOrderClause}
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
      ORDER BY ${AppDatabaseService._wordOrderClause}
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
            ORDER BY ${AppDatabaseService._wordOrderClause}
            LIMIT 1
            ''', params)
        : _selectOne(
            '''
            SELECT id
            FROM words
            WHERE $whereClause
              AND substr(search_word_compact, 1, 1) = ?
            ORDER BY ${AppDatabaseService._wordOrderClause}
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
      ORDER BY ${AppDatabaseService._wordOrderClause}
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
            ORDER BY ${AppDatabaseService._wordOrderClause}
            LIMIT 1
            ''', params)
        : _selectOne(
            '''
            SELECT *
            FROM words
            WHERE $whereClause
              AND substr(search_word_compact, 1, 1) = ?
            ORDER BY ${AppDatabaseService._wordOrderClause}
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
      start += AppDatabaseService._maxSqlVariablesPerStatement
    ) {
      final end = math.min(
        start + AppDatabaseService._maxSqlVariablesPerStatement,
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
}

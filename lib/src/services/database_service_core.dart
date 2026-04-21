part of 'database_service.dart';

extension AppDatabaseServiceCore on AppDatabaseService {
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
    final match = AppDatabaseService._backupFilePattern.firstMatch(filename);
    return match?.group(1) ?? 'manual';
  }

  List<WordEntryPayload> _buildWordEntryPayloadsForWordbook(int wordbookId) {
    final rows = _selectMaps(
      'SELECT * FROM words WHERE wordbook_id = ? ORDER BY ${AppDatabaseService._wordOrderClause}',
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
    if (AppDatabaseService._windowsReservedFileNamePattern.hasMatch(
      normalized,
    )) {
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
    final resolvedMeaning =
        _sanitizeNullableText(row['primary_gloss']) ??
        _sanitizeNullableText(row['meaning']);
    final entry = WordEntry(
      id: (row['id'] as num?)?.toInt(),
      wordbookId: ((row['wordbook_id'] as num?) ?? 0).toInt(),
      word: sanitizeDisplayText('${row['word'] ?? ''}'),
      meaning: resolvedMeaning,
      entryUid: _sanitizeNullableText(row['entry_uid']),
      primaryGloss: _sanitizeNullableText(row['primary_gloss']),
      schemaVersion: _sanitizeNullableText(row['schema_version']),
      sortIndex: (row['sort_index'] as num?)?.toInt(),
      rawContent: resolvedMeaning ?? '',
    );
    final summaryMeaning = entry.summaryMeaningText.trim();
    return entry.copyWith(
      meaning: summaryMeaning.isEmpty ? entry.meaning : summaryMeaning,
      rawContent: summaryMeaning.isEmpty ? entry.rawContent : summaryMeaning,
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
}

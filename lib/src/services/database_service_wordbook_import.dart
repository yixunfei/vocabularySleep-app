part of 'database_service.dart';

extension AppDatabaseServiceWordbookImport on AppDatabaseService {
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
    if (path.startsWith(AppDatabaseService._dictBuiltinPathPrefix)) {
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
      if (normalizedPath.startsWith(
        AppDatabaseService._dictBuiltinPathPrefix,
      )) {
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
    if (normalizedPath.startsWith(AppDatabaseService._dictBuiltinPathPrefix)) {
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
    if (sourcePath.startsWith(AppDatabaseService._dictBuiltinPathPrefix)) {
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
      'SELECT * FROM words WHERE wordbook_id = ? ORDER BY ${AppDatabaseService._wordOrderClause}',
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
}

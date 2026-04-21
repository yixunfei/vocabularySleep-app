part of 'database_service.dart';

extension AppDatabaseServiceMaintenance on AppDatabaseService {
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
              !wordbook.path.startsWith(
                AppDatabaseService._dictBuiltinPathPrefix,
              ) &&
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
}

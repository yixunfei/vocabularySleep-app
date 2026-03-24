part of 'app_state.dart';

extension _AppStatePractice on AppState {
  void _updatePracticeSessionPreferencesImpl({
    bool? autoAddWeakWordsToTask,
    bool? autoPlayPronunciation,
    bool? showHintsByDefault,
    PracticeQuestionType? defaultQuestionType,
  }) {
    final nextAutoAdd =
        autoAddWeakWordsToTask ?? _practiceAutoAddWeakWordsToTask;
    final nextAutoPlay =
        autoPlayPronunciation ?? _practiceAutoPlayPronunciation;
    final nextShowHints = showHintsByDefault ?? _practiceShowHintsByDefault;
    final nextQuestionType =
        defaultQuestionType ?? _practiceDefaultQuestionType;
    final changed =
        nextAutoAdd != _practiceAutoAddWeakWordsToTask ||
        nextAutoPlay != _practiceAutoPlayPronunciation ||
        nextShowHints != _practiceShowHintsByDefault ||
        nextQuestionType != _practiceDefaultQuestionType;
    if (!changed) {
      return;
    }
    _practiceAutoAddWeakWordsToTask = nextAutoAdd;
    _practiceAutoPlayPronunciation = nextAutoPlay;
    _practiceShowHintsByDefault = nextShowHints;
    _practiceDefaultQuestionType = nextQuestionType;
    _persistPracticeDashboard();
    _notifyStateChanged();
  }

  bool _dismissPracticeWeakWordImpl(WordEntry entry) {
    final key = _normalizeTrackedWord(entry.word);
    if (key.isEmpty) {
      return false;
    }
    return _removePracticeWeakKeys(<String>{key}) > 0;
  }

  int _dismissPracticeWeakWordsImpl(Iterable<WordEntry> entries) {
    final keys = entries
        .map((entry) => _normalizeTrackedWord(entry.word))
        .where((item) => item.isNotEmpty)
        .toSet();
    return _removePracticeWeakKeys(keys);
  }

  Future<int> _addPracticeWordsToTaskImpl(Iterable<WordEntry> entries) async {
    final uniqueEntries = _dedupePracticeEntries(entries);
    var added = 0;
    for (final entry in uniqueEntries) {
      if (_taskWords.contains(entry.word)) {
        continue;
      }
      await toggleTaskWord(entry);
      added += 1;
    }
    return added;
  }

  Future<int> _addPracticeWordsToFavoritesImpl(
    Iterable<WordEntry> entries,
  ) async {
    final uniqueEntries = _dedupePracticeEntries(entries);
    var added = 0;
    for (final entry in uniqueEntries) {
      if (_favorites.contains(entry.word)) {
        continue;
      }
      await toggleFavorite(entry);
      added += 1;
    }
    return added;
  }

  int _clearPracticeWeakWordsImpl({bool masteredOnly = false}) {
    if (_practiceWeakWords.isEmpty) {
      return 0;
    }
    if (!masteredOnly) {
      return _removePracticeWeakKeys(
        _practiceWeakWords
            .map(_normalizeTrackedWord)
            .where((item) => item.isNotEmpty)
            .toSet(),
      );
    }

    final now = DateTime.now();
    final rememberedKeys = <String>{
      ..._rememberedWords,
      ..._practiceRememberedWords
          .map(_normalizeTrackedWord)
          .where((item) => item.isNotEmpty),
    };
    final removableKeys = <String>{};
    for (final entry in practiceWrongNotebookEntries) {
      final key = _normalizeTrackedWord(entry.word);
      if (key.isEmpty) {
        continue;
      }
      if (rememberedKeys.contains(key)) {
        removableKeys.add(key);
        continue;
      }
      if (_isStablePracticeProgress(memoryProgressForWordEntry(entry), now)) {
        removableKeys.add(key);
      }
    }
    return _removePracticeWeakKeys(removableKeys);
  }

  void _recordPracticeSessionImpl({
    required String title,
    required int total,
    required int remembered,
    required List<String> rememberedWords,
    required List<String> weakWords,
    List<WordEntry>? rememberedEntries,
    List<WordEntry>? weakEntries,
    Map<String, List<String>> weakReasonIdsByWord =
        const <String, List<String>>{},
  }) {
    final safeTotal = total < 0 ? 0 : total;
    final safeRemembered = remembered.clamp(0, safeTotal).toInt();
    if (safeTotal <= 0) return;

    _ensurePracticeDate();
    _practiceTodaySessions += 1;
    _practiceTodayReviewed += safeTotal;
    _practiceTodayRemembered += safeRemembered;
    _practiceTotalSessions += 1;
    _practiceTotalReviewed += safeTotal;
    _practiceTotalRemembered += safeRemembered;
    _practiceLastSessionTitle = title.trim();
    final normalizedRememberedWords = _normalizePracticeWords(rememberedWords);
    final normalizedWeakWords = _normalizePracticeWords(
      weakWords,
    ).where((word) => !normalizedRememberedWords.contains(word)).toList();
    final rememberedSet = normalizedRememberedWords.toSet();
    final weakSet = normalizedWeakWords.toSet();
    final resolvedRememberedEntries = _resolveTrackedPracticeEntries(
      preferredEntries: rememberedEntries,
      fallbackWords: normalizedRememberedWords,
    );
    final resolvedWeakEntries = _resolveTrackedPracticeEntries(
      preferredEntries: weakEntries,
      fallbackWords: normalizedWeakWords,
    );
    final normalizedWeakReasonsByWord = _normalizePracticeWeakReasonMap(
      weakReasonIdsByWord,
      normalizedWeakWords,
    );
    _updateRememberedWordsStatus(
      rememberedWords: normalizedRememberedWords,
      weakWords: normalizedWeakWords,
    );

    _practiceRememberedWords = _mergePracticeWords(
      primary: normalizedRememberedWords,
      existing: _practiceRememberedWords,
      excluded: weakSet,
    );
    _practiceWeakWords = _mergePracticeWords(
      primary: normalizedWeakWords,
      existing: _practiceWeakWords,
      excluded: rememberedSet,
    );
    _cachePracticeTrackedEntries(
      rememberedEntries: resolvedRememberedEntries,
      weakEntries: resolvedWeakEntries,
    );
    _updatePracticeWeakReasonMap(
      rememberedWords: normalizedRememberedWords,
      weakWords: normalizedWeakWords,
      weakReasonsByWord: normalizedWeakReasonsByWord,
    );
    _updateWordMemoryProgress(
      rememberedEntries: resolvedRememberedEntries,
      weakEntries: resolvedWeakEntries,
    );
    _appendPracticeSessionHistory(
      title: title,
      total: safeTotal,
      remembered: safeRemembered,
      weakReasonIdsByWord: normalizedWeakReasonsByWord,
    );
    _persistPracticeDashboard();
    _notifyStateChanged();
  }

  List<WordEntry> _beginPracticeBatchImpl({
    required String cursorKey,
    required List<WordEntry> sourceWords,
    required int batchSize,
    WordEntry? anchorWord,
    int? cursorAdvance,
  }) {
    if (sourceWords.isEmpty || batchSize <= 0) {
      return const <WordEntry>[];
    }

    final safeBatchSize = math.min(batchSize, sourceWords.length);
    final safeCursorAdvance = math.min(
      sourceWords.length,
      math.max(cursorAdvance ?? safeBatchSize, 1),
    );
    final normalizedKey = cursorKey.trim();
    final anchorIndex = anchorWord == null
        ? -1
        : _indexOfWordEntry(sourceWords, anchorWord);
    final storedCursor = normalizedKey.isEmpty
        ? 0
        : (_practiceLaunchCursors[normalizedKey] ?? 0) % sourceWords.length;
    final startIndex = anchorIndex >= 0 ? anchorIndex : storedCursor;
    final batch = <WordEntry>[];
    for (var offset = 0; offset < safeBatchSize; offset += 1) {
      final index = (startIndex + offset) % sourceWords.length;
      batch.add(sourceWords[index]);
    }

    if (normalizedKey.isNotEmpty) {
      _ensurePracticeDate();
      _practiceLaunchCursors[normalizedKey] =
          (startIndex + safeCursorAdvance) % sourceWords.length;
      _persistPracticeDashboard();
    }

    return batch.toList(growable: false);
  }

  PracticeReviewExportPayload _buildPracticeReviewExportPayloadImpl({
    Iterable<PracticeSessionRecord>? records,
    Iterable<WordEntry>? wrongNotebookEntries,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    final now = DateTime.now();
    final notebookEntries =
        (wrongNotebookEntries ?? practiceWrongNotebookEntries).toList(
          growable: false,
        );
    final sessions = (records ?? practiceSessionHistory).toList(
      growable: false,
    );
    final overallReasonCounts = <String, int>{};
    for (final session in sessions) {
      for (final entry in session.weakReasonCounts.entries) {
        overallReasonCounts.update(
          entry.key,
          (value) => value + entry.value,
          ifAbsent: () => entry.value,
        );
      }
    }
    return PracticeReviewExportPayload(
      exportedAt: now,
      summary: PracticeReviewExportSummary(
        todaySessions: _practiceTodaySessions,
        todayReviewed: _practiceTodayReviewed,
        todayRemembered: _practiceTodayRemembered,
        totalSessions: _practiceTotalSessions,
        totalReviewed: _practiceTotalReviewed,
        totalRemembered: _practiceTotalRemembered,
        todayAccuracy: practiceTodayAccuracy,
        totalAccuracy: practiceTotalAccuracy,
        lastSessionTitle: _practiceLastSessionTitle,
        defaultQuestionType: _practiceDefaultQuestionType.storageValue,
      ),
      metadata: metadata,
      weakReasonCounts: overallReasonCounts,
      sessionHistory: sessions,
      wrongNotebook: notebookEntries
          .map(
            (entry) => PracticeExportWordEntry(
              id: entry.id,
              wordbookId: entry.wordbookId,
              word: entry.word,
              meaning: _practiceMeaningText(entry),
              reasons: practiceWeakReasonsForWord(entry),
              memoryProgress: memoryProgressForWordEntry(entry),
            ),
          )
          .toList(growable: false),
    );
  }

  Future<String?> _exportPracticeReviewDataImpl({
    required PracticeExportFormat format,
    String? directoryPath,
    String? fileName,
    Iterable<PracticeSessionRecord>? records,
    Iterable<WordEntry>? wrongNotebookEntries,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {
    _setBusy(true, messageKey: 'processing');
    try {
      final contents = switch (format) {
        PracticeExportFormat.json => const JsonEncoder.withIndent('  ').convert(
          _buildPracticeReviewExportPayloadImpl(
            records: records,
            wrongNotebookEntries: wrongNotebookEntries,
            metadata: metadata,
          ).toJsonMap(),
        ),
        PracticeExportFormat.csv => _buildPracticeReviewCsv(records: records),
      };
      return await _database.writeTextExport(
        contents: contents,
        defaultFileStem: 'xianyushengxi_practice_review',
        extension: format.extension,
        directoryPath: directoryPath,
        fileName: fileName,
      );
    } catch (error, stackTrace) {
      _log.e(
        'app_state',
        'export practice review failed',
        error: error,
        stackTrace: stackTrace,
      );
      _setMessage(
        'errorExportFailed',
        params: <String, Object?>{'error': error},
      );
      return null;
    } finally {
      _setBusy(false);
    }
  }

  PracticeWrongNotebookExportPayload
  _buildPracticeWrongNotebookExportPayloadImpl({
    required Iterable<WordEntry> entries,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    final resolvedEntries = _dedupePracticeEntries(entries);
    return PracticeWrongNotebookExportPayload(
      exportedAt: DateTime.now(),
      count: resolvedEntries.length,
      metadata: metadata,
      entries: resolvedEntries
          .map(
            (entry) => PracticeExportWordEntry(
              id: entry.id,
              wordbookId: entry.wordbookId,
              word: entry.word,
              meaning: _practiceMeaningText(entry),
              reasons: practiceWeakReasonsForWord(entry),
              memoryProgress: memoryProgressForWordEntry(entry),
            ),
          )
          .toList(growable: false),
    );
  }

  Future<String?> _exportPracticeWrongNotebookDataImpl({
    required Iterable<WordEntry> entries,
    required PracticeExportFormat format,
    String? directoryPath,
    String? fileName,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {
    _setBusy(true, messageKey: 'processing');
    try {
      final resolvedEntries = _dedupePracticeEntries(entries);
      final contents = switch (format) {
        PracticeExportFormat.json => const JsonEncoder.withIndent('  ').convert(
          _buildPracticeWrongNotebookExportPayloadImpl(
            entries: resolvedEntries,
            metadata: metadata,
          ).toJsonMap(),
        ),
        PracticeExportFormat.csv => _buildPracticeWrongNotebookCsv(
          resolvedEntries,
        ),
      };
      return await _database.writeTextExport(
        contents: contents,
        defaultFileStem: 'xianyushengxi_wrong_notebook',
        extension: format.extension,
        directoryPath: directoryPath,
        fileName: fileName,
      );
    } catch (error, stackTrace) {
      _log.e(
        'app_state',
        'export practice wrong notebook failed',
        error: error,
        stackTrace: stackTrace,
      );
      _setMessage(
        'errorExportFailed',
        params: <String, Object?>{'error': error},
      );
      return null;
    } finally {
      _setBusy(false);
    }
  }

  String _buildPracticeReviewCsv({Iterable<PracticeSessionRecord>? records}) {
    final sessions = (records ?? _practiceSessionHistory).toList(
      growable: false,
    );
    final rows = <List<String>>[
      <String>[
        'title',
        'practiced_at',
        'total',
        'remembered',
        'accuracy_percent',
        'weak_reason_counts',
      ],
    ];
    for (final session in sessions) {
      final accuracy = session.total <= 0
          ? 0
          : ((session.remembered / session.total) * 100).round();
      rows.add(<String>[
        session.title,
        session.practicedAt.toIso8601String(),
        '${session.total}',
        '${session.remembered}',
        '$accuracy',
        session.weakReasonCounts.entries
            .map((entry) => '${entry.key}:${entry.value}')
            .join('|'),
      ]);
    }

    String escape(String value) {
      final normalized = value.replaceAll('"', '""');
      if (normalized.contains(',') ||
          normalized.contains('\n') ||
          normalized.contains('\r')) {
        return '"$normalized"';
      }
      return normalized;
    }

    return rows.map((row) => row.map(escape).join(',')).join('\n');
  }

  String _buildPracticeWrongNotebookCsv(Iterable<WordEntry> entries) {
    final rows = <List<String>>[
      <String>[
        'word',
        'meaning',
        'wordbook_id',
        'reasons',
        'times_played',
        'times_correct',
        'accuracy_percent',
        'next_review',
      ],
    ];
    for (final entry in entries) {
      final progress = memoryProgressForWordEntry(entry);
      final timesPlayed = progress?.timesPlayed ?? 0;
      final timesCorrect = progress?.timesCorrect ?? 0;
      final accuracy = timesPlayed <= 0
          ? 0
          : ((timesCorrect / timesPlayed) * 100).round();
      rows.add(<String>[
        entry.word,
        _practiceMeaningText(entry),
        '${entry.wordbookId}',
        practiceWeakReasonsForWord(entry).join('|'),
        '$timesPlayed',
        '$timesCorrect',
        '$accuracy',
        progress?.nextReview?.toIso8601String() ?? '',
      ]);
    }

    String escape(String value) {
      final normalized = value.replaceAll('"', '""');
      if (normalized.contains(',') ||
          normalized.contains('\n') ||
          normalized.contains('\r')) {
        return '"$normalized"';
      }
      return normalized;
    }

    return rows.map((row) => row.map(escape).join(',')).join('\n');
  }

  void _loadPracticeDashboard() {
    final data = _settings.loadPracticeDashboard();
    _practiceTrackedEntriesByWord.clear();
    _practiceDateKey = data.date.trim();
    _practiceTodaySessions = data.todaySessions;
    _practiceTodayReviewed = data.todayReviewed;
    _practiceTodayRemembered = data.todayRemembered;
    _practiceTotalSessions = data.totalSessions;
    _practiceTotalReviewed = data.totalReviewed;
    _practiceTotalRemembered = data.totalRemembered;
    _practiceLastSessionTitle = data.lastSessionTitle.trim();
    _practiceRememberedWords = _normalizePracticeWords(data.rememberedWords);
    _practiceWeakWords = _normalizePracticeWords(data.weakWords)
        .where((word) => !_practiceRememberedWords.contains(word))
        .toList(growable: false);
    _practiceWeakWordReasons = _normalizePracticeWeakReasonMap(
      data.weakReasonIdsByWord,
      _practiceWeakWords,
    );
    _practiceAutoAddWeakWordsToTask = data.sessionPrefs.autoAddWeakWordsToTask;
    _practiceAutoPlayPronunciation = data.sessionPrefs.autoPlayPronunciation;
    _practiceShowHintsByDefault = data.sessionPrefs.showHintsByDefault;
    _practiceDefaultQuestionType = data.sessionPrefs.defaultQuestionType;
    _practiceSessionHistory = data.history;
    _practiceLaunchCursors = data.launchCursors;
    _practiceTrackedEntriesByWord
      ..clear()
      ..addEntries(
        <String, WordEntry>{
          for (final entry in data.trackedEntries)
            if (_normalizeTrackedWord(entry.word).isNotEmpty &&
                entry.wordbookId > 0)
              _normalizeTrackedWord(entry.word): entry.toWordEntry(),
        }.entries,
      );
    _prunePracticeTrackedEntries();
    _prunePracticeWeakReasons();
  }

  void _ensurePracticeDate({bool persist = false}) {
    final today = _todayDateKey();
    if (_practiceDateKey == today) return;
    _practiceDateKey = today;
    _practiceTodaySessions = 0;
    _practiceTodayReviewed = 0;
    _practiceTodayRemembered = 0;
    if (persist) {
      _persistPracticeDashboard();
    }
  }

  String _todayDateKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  void _persistPracticeDashboard() {
    _settings.savePracticeDashboard(
      PracticeDashboardState(
        date: _practiceDateKey,
        todaySessions: _practiceTodaySessions,
        todayReviewed: _practiceTodayReviewed,
        todayRemembered: _practiceTodayRemembered,
        totalSessions: _practiceTotalSessions,
        totalReviewed: _practiceTotalReviewed,
        totalRemembered: _practiceTotalRemembered,
        lastSessionTitle: _practiceLastSessionTitle,
        rememberedWords: _practiceRememberedWords,
        weakWords: _practiceWeakWords,
        weakReasonIdsByWord: _practiceWeakWordReasons,
        history: _practiceSessionHistory,
        sessionPrefs: PracticeSessionPreferences(
          autoAddWeakWordsToTask: _practiceAutoAddWeakWordsToTask,
          autoPlayPronunciation: _practiceAutoPlayPronunciation,
          showHintsByDefault: _practiceShowHintsByDefault,
          defaultQuestionType: _practiceDefaultQuestionType,
        ),
        launchCursors: _practiceLaunchCursors,
        trackedEntries: _practiceTrackedEntriesByWord.values
            .map(PracticeTrackedEntrySnapshot.fromWordEntry)
            .toList(growable: false),
      ),
    );
  }

  List<WordEntry> _practiceEntriesFromWords(List<String> trackedWords) {
    if (trackedWords.isEmpty) {
      return const <WordEntry>[];
    }
    final byWord = <String, WordEntry>{};

    void addEntries(Iterable<WordEntry> entries) {
      for (final entry in entries) {
        final key = _normalizeTrackedWord(entry.word);
        if (key.isEmpty || byWord.containsKey(key)) {
          continue;
        }
        byWord[key] = entry;
      }
    }

    addEntries(_practiceTrackedEntriesByWord.values);
    addEntries(_scopeWords);
    addEntries(_words);
    if (byWord.isEmpty) {
      return const <WordEntry>[];
    }

    final output = <WordEntry>[];
    for (final word in trackedWords) {
      final entry = byWord[_normalizeTrackedWord(word)];
      if (entry != null) {
        output.add(entry);
      }
    }
    return output;
  }

  List<WordEntry> _memoryStableEntries(List<WordEntry> words) {
    final tracked = MemoryLaneSelector.selectStableEntries(
      words: words,
      progressByWordId: _wordMemoryProgressByWordId,
    );
    final remembered = _practiceEntriesFromWords(
      _rememberedWords.toList(growable: false),
    );
    final practice = _practiceEntriesFromWords(_practiceRememberedWords);
    return _mergeTrackedWordEntries(<List<WordEntry>>[
      tracked,
      remembered,
      practice,
    ]);
  }

  List<WordEntry> _memoryRecoveryEntries(List<WordEntry> words) {
    final tracked = MemoryLaneSelector.selectRecoveryEntries(
      words: words,
      progressByWordId: _wordMemoryProgressByWordId,
    );
    final practice = _practiceEntriesFromWords(_practiceWeakWords);
    final merged = _mergeTrackedWordEntries(<List<WordEntry>>[
      tracked,
      practice,
    ]);
    if (_rememberedWords.isEmpty) {
      return merged;
    }
    final rememberedKeys = _rememberedWords
        .map(_normalizeTrackedWord)
        .where((item) => item.isNotEmpty)
        .toSet();
    return merged
        .where(
          (entry) =>
              !rememberedKeys.contains(_normalizeTrackedWord(entry.word)),
        )
        .toList(growable: false);
  }

  void _refreshWordMemoryProgressCache(List<WordEntry> words) {
    final wordIds = <int>{
      ...words.map((item) => item.id).whereType<int>().where((id) => id > 0),
      ..._practiceTrackedEntriesByWord.values
          .map((item) => item.id)
          .whereType<int>()
          .where((id) => id > 0),
    };
    _wordMemoryProgressByWordId = _database.getWordMemoryProgressByWordIds(
      wordIds,
    );
  }

  List<WordEntry> _resolveTrackedPracticeEntries({
    required List<String> fallbackWords,
    List<WordEntry>? preferredEntries,
  }) {
    final sourceEntries =
        preferredEntries ?? _practiceEntriesFromWords(fallbackWords);
    if (sourceEntries.isEmpty) {
      return const <WordEntry>[];
    }
    final output = <WordEntry>[];
    final seen = <String>{};
    for (final entry in sourceEntries) {
      final identity = _wordEntryIdentity(entry);
      if (identity == null || !seen.add(identity)) {
        continue;
      }
      output.add(entry);
    }
    return output;
  }

  void _cachePracticeTrackedEntries({
    required List<WordEntry> rememberedEntries,
    required List<WordEntry> weakEntries,
  }) {
    if (rememberedEntries.isEmpty && weakEntries.isEmpty) {
      return;
    }

    for (final entry in <WordEntry>[...rememberedEntries, ...weakEntries]) {
      final key = _normalizeTrackedWord(entry.word);
      if (key.isEmpty) {
        continue;
      }
      _practiceTrackedEntriesByWord[key] = entry;
    }
    _prunePracticeTrackedEntries();
  }

  int _removePracticeWeakKeys(Set<String> keys) {
    if (keys.isEmpty || _practiceWeakWords.isEmpty) {
      return 0;
    }

    final nextWeakWords = _practiceWeakWords
        .where((word) => !keys.contains(_normalizeTrackedWord(word)))
        .toList(growable: false);
    final removed = _practiceWeakWords.length - nextWeakWords.length;
    if (removed <= 0) {
      return 0;
    }

    _practiceWeakWords = nextWeakWords;
    for (final key in keys) {
      _practiceWeakWordReasons.remove(key);
    }
    _prunePracticeTrackedEntries();
    _prunePracticeWeakReasons();
    _persistPracticeDashboard();
    _notifyStateChanged();
    return removed;
  }

  void _prunePracticeTrackedEntries() {
    final activeKeys = <String>{
      ..._practiceRememberedWords.map(_normalizeTrackedWord),
      ..._practiceWeakWords.map(_normalizeTrackedWord),
    }.where((item) => item.isNotEmpty).toSet();
    _practiceTrackedEntriesByWord.removeWhere(
      (key, _) => !activeKeys.contains(key),
    );
  }

  void _prunePracticeWeakReasons() {
    final activeWeakKeys = _practiceWeakWords
        .map(_normalizeTrackedWord)
        .where((item) => item.isNotEmpty)
        .toSet();
    _practiceWeakWordReasons.removeWhere(
      (key, _) => !activeWeakKeys.contains(key),
    );
  }

  Map<String, List<String>> _normalizePracticeWeakReasonMap(
    Map<String, List<String>> raw,
    List<String> weakWords,
  ) {
    if (weakWords.isEmpty) {
      return <String, List<String>>{};
    }
    final output = <String, List<String>>{};
    for (final word in weakWords) {
      final key = _normalizeTrackedWord(word);
      if (key.isEmpty) {
        continue;
      }
      output[key] = _sanitizePracticeWeakReasons(raw[key]);
    }
    return output;
  }

  List<String> _sanitizePracticeWeakReasons(Object? raw) {
    final normalized = <String>[];
    final items = raw is List ? raw : const <Object?>[];
    for (final item in items) {
      final value = '${item ?? ''}'.trim();
      if (!practiceWeakReasonIds.contains(value) ||
          normalized.contains(value)) {
        continue;
      }
      normalized.add(value);
    }
    if (normalized.isEmpty) {
      return const <String>['recall'];
    }
    return normalized;
  }

  void _updatePracticeWeakReasonMap({
    required List<String> rememberedWords,
    required List<String> weakWords,
    required Map<String, List<String>> weakReasonsByWord,
  }) {
    for (final word in rememberedWords) {
      final key = _normalizeTrackedWord(word);
      if (key.isNotEmpty) {
        _practiceWeakWordReasons.remove(key);
      }
    }
    for (final word in weakWords) {
      final key = _normalizeTrackedWord(word);
      if (key.isEmpty) {
        continue;
      }
      _practiceWeakWordReasons[key] = List<String>.from(
        weakReasonsByWord[key] ?? const <String>['recall'],
        growable: false,
      );
    }
    _prunePracticeWeakReasons();
  }

  void _appendPracticeSessionHistory({
    required String title,
    required int total,
    required int remembered,
    required Map<String, List<String>> weakReasonIdsByWord,
  }) {
    final reasonCounts = <String, int>{};
    for (final reasons in weakReasonIdsByWord.values) {
      for (final reason in reasons) {
        reasonCounts.update(reason, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    final nextHistory = <PracticeSessionRecord>[
      PracticeSessionRecord(
        title: title.trim(),
        practicedAt: DateTime.now(),
        total: total,
        remembered: remembered,
        weakReasonCounts: reasonCounts,
      ),
      ..._practiceSessionHistory,
    ];
    _practiceSessionHistory = nextHistory
        .take(AppState._practiceSessionHistoryLimit)
        .toList(growable: false);
  }

  List<WordEntry> _dedupePracticeEntries(Iterable<WordEntry> entries) {
    final output = <WordEntry>[];
    final seen = <String>{};
    for (final entry in entries) {
      final key = _wordEntryIdentity(entry);
      if (key == null || !seen.add(key)) {
        continue;
      }
      output.add(entry);
    }
    return output;
  }

  String _practiceMeaningText(WordEntry entry) {
    final direct = entry.meaning?.trim() ?? '';
    if (direct.isNotEmpty) {
      return direct;
    }
    for (final field in entry.fields) {
      if (field.key == 'meaning') {
        final text = field.asText().trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
    }
    return '';
  }

  bool _isStablePracticeProgress(WordMemoryProgress? progress, DateTime now) {
    if (progress == null || !progress.isTracked) {
      return false;
    }
    if (progress.timesCorrect <= 0 || progress.consecutiveCorrect <= 0) {
      return false;
    }
    final nextReview = progress.nextReview;
    if (nextReview == null) {
      return false;
    }
    return nextReview.isAfter(now);
  }

  void _updateWordMemoryProgress({
    required List<WordEntry> rememberedEntries,
    required List<WordEntry> weakEntries,
  }) {
    if (rememberedEntries.isEmpty && weakEntries.isEmpty) {
      return;
    }

    final nextProgressByWordId = Map<int, WordMemoryProgress>.from(
      _wordMemoryProgressByWordId,
    );
    final updatedAt = DateTime.now();

    void persistProgress(WordEntry entry, {required bool remembered}) {
      final wordId = entry.id;
      if (wordId == null || wordId <= 0) {
        return;
      }
      final previous =
          nextProgressByWordId[wordId] ?? WordMemoryProgress(wordId: wordId);
      final result = MemoryAlgorithm.sm2(
        quality: remembered ? 4 : 1,
        previousEaseFactor: previous.easeFactor,
        previousInterval: previous.intervalDays,
        consecutiveCorrect: previous.consecutiveCorrect,
      );
      final nextProgress = previous.copyWith(
        timesPlayed: previous.timesPlayed + 1,
        timesCorrect: previous.timesCorrect + (remembered ? 1 : 0),
        lastPlayed: updatedAt,
        familiarity: result.familiarity,
        easeFactor: result.easeFactor,
        intervalDays: result.intervalDays,
        nextReview: DateTime.tryParse(result.nextReview),
        consecutiveCorrect: result.consecutiveCorrect,
        memoryState: result.memoryState,
      );
      _database.upsertWordMemoryProgress(nextProgress);
      nextProgressByWordId[wordId] = nextProgress;
    }

    for (final entry in rememberedEntries) {
      persistProgress(entry, remembered: true);
    }
    for (final entry in weakEntries) {
      persistProgress(entry, remembered: false);
    }

    _wordMemoryProgressByWordId = nextProgressByWordId;
  }

  String? _wordEntryIdentity(WordEntry entry) {
    final id = entry.id;
    if (id != null && id > 0) {
      return 'id:$id';
    }
    final word = entry.word.trim();
    if (word.isEmpty) {
      return null;
    }
    return 'word:${word.toLowerCase()}';
  }

  List<String> _normalizePracticeWords(Object? value) {
    if (value is! List) {
      return const <String>[];
    }
    final normalized = <String>[];
    for (final item in value) {
      final word = '$item'.trim();
      if (word.isEmpty || normalized.contains(word)) {
        continue;
      }
      normalized.add(word);
    }
    return normalized.take(40).toList(growable: false);
  }

  List<String> _mergePracticeWords({
    required List<String> primary,
    required List<String> existing,
    Set<String> excluded = const <String>{},
  }) {
    final merged = <String>[];

    void addWord(String raw) {
      final value = raw.trim();
      if (value.isEmpty || excluded.contains(value) || merged.contains(value)) {
        return;
      }
      merged.add(value);
    }

    for (final item in primary) {
      addWord(item);
    }
    for (final item in existing) {
      addWord(item);
    }
    return merged.take(40).toList(growable: false);
  }

  void _updateRememberedWordsStatus({
    required List<String> rememberedWords,
    required List<String> weakWords,
  }) {
    if (rememberedWords.isEmpty && weakWords.isEmpty) {
      return;
    }
    final next = Set<String>.from(_rememberedWords);
    for (final word in weakWords) {
      next.remove(_normalizeTrackedWord(word));
    }
    for (final word in rememberedWords) {
      final normalized = _normalizeTrackedWord(word);
      if (normalized.isNotEmpty) {
        next.add(normalized);
      }
    }
    if (setEquals(next, _rememberedWords)) {
      return;
    }
    _rememberedWords = next;
    _settings.saveRememberedWords(_rememberedWords);
  }

  List<WordEntry> _mergeTrackedWordEntries(List<List<WordEntry>> groups) {
    if (groups.isEmpty) {
      return const <WordEntry>[];
    }
    final merged = <WordEntry>[];
    final seen = <String>{};
    for (final group in groups) {
      for (final entry in group) {
        final identity = _wordEntryIdentity(entry);
        if (identity == null || !seen.add(identity)) {
          continue;
        }
        merged.add(entry);
      }
    }
    return merged;
  }

  String _normalizeTrackedWord(String value) {
    return value.trim().toLowerCase();
  }
}

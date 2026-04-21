part of 'app_state.dart';

const int _practiceDashboardPersistWarnThresholdMs = 80;
const int _practiceAnswerWriteWarnThresholdMs = 120;

extension _AppStatePractice on AppState {
  void _updatePracticeSessionPreferencesImpl({
    bool? autoAddWeakWordsToTask,
    bool? autoPlayPronunciation,
    bool? showHintsByDefault,
    bool? showAnswerFeedbackDialog,
    PracticeQuestionType? defaultQuestionType,
  }) {
    final nextAutoAdd =
        autoAddWeakWordsToTask ?? _practiceStore.autoAddWeakWordsToTask;
    final nextAutoPlay =
        autoPlayPronunciation ?? _practiceStore.autoPlayPronunciation;
    final nextShowHints = showHintsByDefault ?? _practiceStore.showHintsByDefault;
    final nextShowAnswerFeedbackDialog =
        showAnswerFeedbackDialog ?? _practiceStore.showAnswerFeedbackDialog;
    final nextQuestionType =
        defaultQuestionType ?? _practiceStore.defaultQuestionType;
    final changed =
        nextAutoAdd != _practiceStore.autoAddWeakWordsToTask ||
        nextAutoPlay != _practiceStore.autoPlayPronunciation ||
        nextShowHints != _practiceStore.showHintsByDefault ||
        nextShowAnswerFeedbackDialog != _practiceStore.showAnswerFeedbackDialog ||
        nextQuestionType != _practiceStore.defaultQuestionType;
    if (!changed) {
      return;
    }
    _practiceStore.autoAddWeakWordsToTask = nextAutoAdd;
    _practiceStore.autoPlayPronunciation = nextAutoPlay;
    _practiceStore.showHintsByDefault = nextShowHints;
    _practiceStore.showAnswerFeedbackDialog = nextShowAnswerFeedbackDialog;
    _practiceStore.defaultQuestionType = nextQuestionType;
    _persistPracticeDashboard();
    _notifyStateChanged();
  }

  bool _dismissPracticeWeakWordImpl(WordEntry entry) {
    final key = _practiceTrackingKeyForEntry(entry);
    if (key.isEmpty) {
      return false;
    }
    return _removePracticeWeakKeys(<String>{key}) > 0;
  }

  int _dismissPracticeWeakWordsImpl(Iterable<WordEntry> entries) {
    final keys = entries
        .map(_practiceTrackingKeyForEntry)
        .where((item) => item.isNotEmpty)
        .toSet();
    return _removePracticeWeakKeys(keys);
  }

  Future<int> _addPracticeWordsToTaskImpl(Iterable<WordEntry> entries) async {
    final uniqueEntries = _dedupePracticeEntries(entries);
    var added = 0;
    for (final entry in uniqueEntries) {
      if (isTaskEntry(entry)) {
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
      if (isFavoriteEntry(entry)) {
        continue;
      }
      await toggleFavorite(entry);
      added += 1;
    }
    return added;
  }

  int _clearPracticeWeakWordsImpl({bool masteredOnly = false}) {
    if (_practiceStore.weakWords.isEmpty) {
      return 0;
    }
    if (!masteredOnly) {
      return _removePracticeWeakKeys(
        _practiceStore.weakWords
            .map(_normalizeTrackedWord)
            .where((item) => item.isNotEmpty)
            .toSet(),
      );
    }

    final now = DateTime.now();
    final rememberedKeys = <String>{
      ..._rememberedWords,
      ..._practiceStore.rememberedWords
          .map(_normalizeTrackedWord)
          .where((item) => item.isNotEmpty),
    };
    final removableKeys = <String>{};
    for (final entry in practiceWrongNotebookEntries) {
      final key = _practiceTrackingKeyForEntry(entry);
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
    _practiceStore.todaySessions += 1;
    _practiceStore.todayReviewed += safeTotal;
    _practiceStore.todayRemembered += safeRemembered;
    _practiceStore.totalSessions += 1;
    _practiceStore.totalReviewed += safeTotal;
    _practiceStore.totalRemembered += safeRemembered;
    _practiceStore.lastSessionTitle = title.trim();
    final resolvedRememberedEntries = _resolveTrackedPracticeEntries(
      preferredEntries: rememberedEntries,
      fallbackWords: _normalizePracticeWords(rememberedWords),
    );
    final resolvedWeakEntries = _resolveTrackedPracticeEntries(
      preferredEntries: weakEntries,
      fallbackWords: _normalizePracticeWords(weakWords),
    );
    final normalizedRememberedWords = resolvedRememberedEntries.isNotEmpty
        ? _trackingKeysFromEntries(resolvedRememberedEntries)
        : _normalizePracticeTrackingKeys(rememberedWords);
    final normalizedWeakWords =
        (resolvedWeakEntries.isNotEmpty
                ? _trackingKeysFromEntries(resolvedWeakEntries)
                : _normalizePracticeTrackingKeys(weakWords))
            .where((word) => !normalizedRememberedWords.contains(word))
            .toList();
    final rememberedSet = normalizedRememberedWords.toSet();
    final weakSet = normalizedWeakWords.toSet();
    final normalizedWeakReasonsByWord = _normalizePracticeWeakReasonMap(
      weakReasonIdsByWord,
      normalizedWeakWords,
      preferredEntries: resolvedWeakEntries,
    );
    _updateRememberedWordsStatus(
      rememberedWords: normalizedRememberedWords,
      weakWords: normalizedWeakWords,
    );

    _practiceStore.rememberedWords = _mergePracticeWords(
      primary: normalizedRememberedWords,
      existing: _practiceStore.rememberedWords,
      excluded: weakSet,
    );
    _practiceStore.weakWords = _mergePracticeWords(
      primary: normalizedWeakWords,
      existing: _practiceStore.weakWords,
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

  void _startPracticeSessionImpl({required String title}) {
    _ensurePracticeDate();
    _practiceStore.todaySessions += 1;
    _practiceStore.totalSessions += 1;
    _practiceStore.lastSessionTitle = title.trim();
    _persistPracticeDashboard();
    _notifyStateChanged();
  }

  void _recordPracticeAnswerImpl({
    required WordEntry entry,
    required bool remembered,
    List<String> weakReasonIds = const <String>[],
    bool addToWrongNotebook = true,
    String? sessionTitle,
  }) {
    final writeWatch = Stopwatch()..start();
    _ensurePracticeDate();
    _practiceStore.todayReviewed += 1;
    _practiceStore.totalReviewed += 1;
    if (remembered) {
      _practiceStore.todayRemembered += 1;
      _practiceStore.totalRemembered += 1;
    }

    final normalizedWord = _practiceTrackingKeyForEntry(entry);
    final rememberedWords = remembered
        ? <String>[normalizedWord]
        : const <String>[];
    final sanitizedWeakReasons = _sanitizePracticeWeakReasons(weakReasonIds);

    if (remembered) {
      _practiceStore.rememberedWords = _mergePracticeWords(
        primary: rememberedWords,
        existing: _practiceStore.rememberedWords,
      );
      _practiceStore.weakWords = _practiceStore.weakWords
          .where((word) => _normalizeTrackedWord(word) != normalizedWord)
          .toList(growable: false);
      if (normalizedWord.isNotEmpty) {
        _practiceStore.weakWordReasons.remove(normalizedWord);
      }
    } else {
      _practiceStore.rememberedWords = _practiceStore.rememberedWords
          .where((word) => _normalizeTrackedWord(word) != normalizedWord)
          .toList(growable: false);
      if (addToWrongNotebook) {
        _practiceStore.weakWords = _mergePracticeWords(
          primary: <String>[normalizedWord],
          existing: _practiceStore.weakWords,
        );
        if (normalizedWord.isNotEmpty) {
          _practiceStore.weakWordReasons[normalizedWord] = List<String>.from(
            sanitizedWeakReasons,
            growable: false,
          );
        }
      } else {
        _practiceStore.weakWords = _practiceStore.weakWords
            .where((word) => _normalizeTrackedWord(word) != normalizedWord)
            .toList(growable: false);
        if (normalizedWord.isNotEmpty) {
          _practiceStore.weakWordReasons.remove(normalizedWord);
        }
      }
    }

    _updateRememberedWordsStatus(
      rememberedWords: rememberedWords,
      weakWords: remembered ? const <String>[] : <String>[normalizedWord],
    );
    _cachePracticeTrackedEntries(
      rememberedEntries: remembered ? <WordEntry>[entry] : const <WordEntry>[],
      weakEntries: !remembered && addToWrongNotebook
          ? <WordEntry>[entry]
          : const <WordEntry>[],
    );
    _updateWordMemoryProgress(
      rememberedEntries: remembered ? <WordEntry>[entry] : const <WordEntry>[],
      weakEntries: !remembered ? <WordEntry>[entry] : const <WordEntry>[],
    );
    final wordId = entry.id;
    if (wordId != null && wordId > 0) {
      _practiceRepository.insertWordMemoryEvent(
        wordId: wordId,
        eventKind: remembered ? 'remembered' : 'weak',
        quality: remembered ? 4 : 1,
        weakReasonIds: remembered ? const <String>[] : sanitizedWeakReasons,
        sessionTitle: sessionTitle ?? _practiceStore.lastSessionTitle,
      );
    }
    _prunePracticeTrackedEntries();
    _prunePracticeWeakReasons();
    _persistPracticeDashboard();
    if (writeWatch.elapsedMilliseconds >= _practiceAnswerWriteWarnThresholdMs) {
      _log.w(
        'practice',
        'recordPracticeAnswer slow',
        data: <String, Object?>{
          'word': entry.word,
          'remembered': remembered,
          'addToWrongNotebook': addToWrongNotebook,
          'elapsedMs': writeWatch.elapsedMilliseconds,
          'trackedEntries': _practiceStore.trackedEntriesByWord.length,
          'history': _practiceStore.sessionHistory.length,
          'rememberedWords': _practiceStore.rememberedWords.length,
          'weakWords': _practiceStore.weakWords.length,
        },
      );
    }
    _notifyStateChanged();
  }

  void _finishPracticeSessionImpl({
    required String title,
    required int total,
    required int remembered,
    Map<String, List<String>> weakReasonIdsByWord =
        const <String, List<String>>{},
  }) {
    final safeTotal = total < 0 ? 0 : total;
    if (safeTotal <= 0) {
      return;
    }
    _practiceStore.lastSessionTitle = title.trim();
    _appendPracticeSessionHistory(
      title: title,
      total: safeTotal,
      remembered: remembered.clamp(0, safeTotal).toInt(),
      weakReasonIdsByWord: _normalizePracticeWeakReasonMap(
        weakReasonIdsByWord,
        weakReasonIdsByWord.keys.toList(growable: false),
      ),
    );
    _persistPracticeDashboard();
    _notifyStateChanged();
  }

  void _updatePracticeRoundSettingsImpl({
    PracticeRoundSource? source,
    PracticeRoundStartMode? startMode,
    int? roundSize,
    bool? shuffle,
    bool? collapsed,
  }) {
    final nextSettings = _practiceStore.roundSettings.copyWith(
      source: source,
      startMode: startMode,
      roundSize: roundSize,
      shuffle: shuffle,
      collapsed: collapsed,
    );
    if (nextSettings.source == _practiceStore.roundSettings.source &&
        nextSettings.startMode == _practiceStore.roundSettings.startMode &&
        nextSettings.roundSize == _practiceStore.roundSettings.roundSize &&
        nextSettings.shuffle == _practiceStore.roundSettings.shuffle &&
        nextSettings.collapsed == _practiceStore.roundSettings.collapsed) {
      return;
    }
    _practiceStore.roundSettings = nextSettings;
    _persistPracticeDashboard();
    _notifyStateChanged();
  }

  int _previewPracticeBatchStartIndexImpl({
    required String cursorKey,
    required List<WordEntry> sourceWords,
    PracticeRoundStartMode? startMode,
    WordEntry? anchorWord,
  }) {
    if (sourceWords.isEmpty) {
      return 0;
    }
    final resolvedStartMode = startMode ?? _practiceStore.roundSettings.startMode;
    return switch (resolvedStartMode) {
      PracticeRoundStartMode.fromStart => 0,
      PracticeRoundStartMode.currentWord => math.max(
        0,
        _indexOfWordEntry(sourceWords, anchorWord ?? sourceWords.first),
      ),
      PracticeRoundStartMode.resumeCursor =>
        cursorKey.trim().isEmpty
            ? 0
            : (_practiceStore.launchCursors[cursorKey.trim()] ?? 0) %
                  sourceWords.length,
    };
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
        : (_practiceStore.launchCursors[normalizedKey] ?? 0) % sourceWords.length;
    final startIndex = anchorIndex >= 0 ? anchorIndex : storedCursor;
    final batch = <WordEntry>[];
    for (var offset = 0; offset < safeBatchSize; offset += 1) {
      final index = (startIndex + offset) % sourceWords.length;
      batch.add(sourceWords[index]);
    }

    if (normalizedKey.isNotEmpty) {
      _ensurePracticeDate();
      _practiceStore.launchCursors[normalizedKey] =
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
        todaySessions: _practiceStore.todaySessions,
        todayReviewed: _practiceStore.todayReviewed,
        todayRemembered: _practiceStore.todayRemembered,
        totalSessions: _practiceStore.totalSessions,
        totalReviewed: _practiceStore.totalReviewed,
        totalRemembered: _practiceStore.totalRemembered,
        todayAccuracy: practiceTodayAccuracy,
        totalAccuracy: practiceTotalAccuracy,
        lastSessionTitle: _practiceStore.lastSessionTitle,
        defaultQuestionType: _practiceStore.defaultQuestionType.storageValue,
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
      return await _practiceRepository.writeTextExport(
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
      return await _practiceRepository.writeTextExport(
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
    final sessions = (records ?? _practiceStore.sessionHistory).toList(
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
    _practiceStore.trackedEntriesByWord.clear();
    _practiceStore.dateKey = data.date.trim();
    _practiceStore.todaySessions = data.todaySessions;
    _practiceStore.todayReviewed = data.todayReviewed;
    _practiceStore.todayRemembered = data.todayRemembered;
    _practiceStore.totalSessions = data.totalSessions;
    _practiceStore.totalReviewed = data.totalReviewed;
    _practiceStore.totalRemembered = data.totalRemembered;
    _practiceStore.lastSessionTitle = data.lastSessionTitle.trim();
    final trackedEntries = data.trackedEntries
        .map((entry) => entry.toWordEntry())
        .toList(growable: false);
    final trackedEntriesByKey = <String, WordEntry>{
      for (var index = 0; index < trackedEntries.length; index += 1)
        if (data.trackedEntries[index].wordbookId > 0)
          _practiceTrackingKeyForEntry(trackedEntries[index]):
              trackedEntries[index],
    }..removeWhere((key, _) => key.isEmpty);
    _practiceStore.rememberedWords = _normalizePracticeTrackingKeys(
      data.rememberedWords,
      preferredEntries: trackedEntries,
    );
    _practiceStore.weakWords =
        _normalizePracticeTrackingKeys(
              data.weakWords,
              preferredEntries: trackedEntries,
            )
            .where((word) => !_practiceStore.rememberedWords.contains(word))
            .toList(growable: false);
    _practiceStore.weakWordReasons = _normalizePracticeWeakReasonMap(
      data.weakReasonIdsByWord,
      _practiceStore.weakWords,
      preferredEntries: trackedEntries,
    );
    _practiceStore.autoAddWeakWordsToTask = data.sessionPrefs.autoAddWeakWordsToTask;
    _practiceStore.autoPlayPronunciation = data.sessionPrefs.autoPlayPronunciation;
    _practiceStore.showHintsByDefault = data.sessionPrefs.showHintsByDefault;
    _practiceStore.showAnswerFeedbackDialog =
        data.sessionPrefs.showAnswerFeedbackDialog;
    _practiceStore.defaultQuestionType = data.sessionPrefs.defaultQuestionType;
    _practiceStore.roundSettings = data.roundSettings;
    _practiceStore.sessionHistory = data.history;
    _practiceStore.launchCursors = data.launchCursors;
    _practiceStore.trackedEntriesByWord
      ..clear()
      ..addEntries(trackedEntriesByKey.entries);
    _prunePracticeTrackedEntries();
    _prunePracticeWeakReasons();
  }

  void _ensurePracticeDate({bool persist = false}) {
    final today = _todayDateKey();
    if (_practiceStore.dateKey == today) return;
    _practiceStore.dateKey = today;
    _practiceStore.todaySessions = 0;
    _practiceStore.todayReviewed = 0;
    _practiceStore.todayRemembered = 0;
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
    final watch = Stopwatch()..start();
    final trackedEntries = _practiceStore.trackedEntriesByWord.values
        .map(PracticeTrackedEntrySnapshot.fromWordEntry)
        .toList(growable: false);
    _settings.savePracticeDashboard(
      PracticeDashboardState(
        date: _practiceStore.dateKey,
        todaySessions: _practiceStore.todaySessions,
        todayReviewed: _practiceStore.todayReviewed,
        todayRemembered: _practiceStore.todayRemembered,
        totalSessions: _practiceStore.totalSessions,
        totalReviewed: _practiceStore.totalReviewed,
        totalRemembered: _practiceStore.totalRemembered,
        lastSessionTitle: _practiceStore.lastSessionTitle,
        rememberedWords: _practiceStore.rememberedWords,
        weakWords: _practiceStore.weakWords,
        weakReasonIdsByWord: _practiceStore.weakWordReasons,
        history: _practiceStore.sessionHistory,
        sessionPrefs: PracticeSessionPreferences(
          autoAddWeakWordsToTask: _practiceStore.autoAddWeakWordsToTask,
          autoPlayPronunciation: _practiceStore.autoPlayPronunciation,
          showHintsByDefault: _practiceStore.showHintsByDefault,
          showAnswerFeedbackDialog: _practiceStore.showAnswerFeedbackDialog,
          defaultQuestionType: _practiceStore.defaultQuestionType,
        ),
        roundSettings: _practiceStore.roundSettings,
        launchCursors: _practiceStore.launchCursors,
        trackedEntries: trackedEntries,
      ),
    );
    if (watch.elapsedMilliseconds >= _practiceDashboardPersistWarnThresholdMs) {
      _log.w(
        'practice',
        'practice dashboard persist slow',
        data: <String, Object?>{
          'elapsedMs': watch.elapsedMilliseconds,
          'trackedEntries': trackedEntries.length,
          'history': _practiceStore.sessionHistory.length,
          'rememberedWords': _practiceStore.rememberedWords.length,
          'weakWords': _practiceStore.weakWords.length,
        },
      );
    }
  }

  List<WordEntry> _practiceEntriesFromWords(List<String> trackedWords) {
    if (trackedWords.isEmpty) {
      return const <WordEntry>[];
    }
    final byTrackingKey = <String, WordEntry>{};
    final byLegacyWord = <String, WordEntry>{};

    void addEntries(Iterable<WordEntry> entries) {
      for (final entry in entries) {
        final trackingKey = _practiceTrackingKeyForEntry(entry);
        if (trackingKey.isNotEmpty) {
          byTrackingKey.putIfAbsent(trackingKey, () => entry);
        }
        final legacyKey = _normalizeTrackedWord(entry.word);
        if (legacyKey.isNotEmpty) {
          byLegacyWord.putIfAbsent(legacyKey, () => entry);
        }
      }
    }

    addEntries(_scopeWords);
    addEntries(_words);
    addEntries(_practiceStore.trackedEntriesByWord.values);
    if (byTrackingKey.isEmpty && byLegacyWord.isEmpty) {
      return const <WordEntry>[];
    }

    final output = <WordEntry>[];
    for (final word in trackedWords) {
      final normalized = _normalizeTrackedWord(word);
      final entry = byTrackingKey[normalized] ?? byLegacyWord[normalized];
      if (entry != null) {
        output.add(entry);
      }
    }
    return output;
  }

  List<WordEntry> _memoryStableEntries(List<WordEntry> words) {
    final tracked = MemoryLaneSelector.selectStableEntries(
      words: words,
      progressByWordId: _practiceStore.wordMemoryProgressByWordId,
    );
    final remembered = _practiceEntriesFromWords(
      _rememberedWords.toList(growable: false),
    );
    final practice = _practiceEntriesFromWords(_practiceStore.rememberedWords);
    return _mergeTrackedWordEntries(<List<WordEntry>>[
      tracked,
      remembered,
      practice,
    ]);
  }

  List<WordEntry> _memoryRecoveryEntries(List<WordEntry> words) {
    final tracked = MemoryLaneSelector.selectRecoveryEntries(
      words: words,
      progressByWordId: _practiceStore.wordMemoryProgressByWordId,
    );
    final practice = _practiceEntriesFromWords(_practiceStore.weakWords);
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
              !rememberedKeys.contains(_practiceTrackingKeyForEntry(entry)),
        )
        .toList(growable: false);
  }

  void _refreshWordMemoryProgressCache(List<WordEntry> words) {
    final wordIds = <int>{
      ...words.map((item) => item.id).whereType<int>().where((id) => id > 0),
      ..._practiceStore.trackedEntriesByWord.values
          .map((item) => item.id)
          .whereType<int>()
          .where((id) => id > 0),
    };
    _practiceStore.wordMemoryProgressByWordId = _practiceRepository
        .getWordMemoryProgressByWordIds(wordIds);
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
      final key = _practiceTrackingKeyForEntry(entry);
      if (key.isEmpty) {
        continue;
      }
      _practiceStore.trackedEntriesByWord[key] = _buildPracticeTrackedEntryLite(
        entry,
      );
    }
    _prunePracticeTrackedEntries();
  }

  WordEntry _buildPracticeTrackedEntryLite(WordEntry entry) {
    final summaryMeaning = entry.summaryMeaningText.trim();
    final needsRawContentFallback =
        entry.entryUid?.trim().isNotEmpty != true &&
        (entry.primaryGloss?.trim().isNotEmpty != true &&
            summaryMeaning.isEmpty);
    return WordEntry(
      id: entry.id,
      wordbookId: entry.wordbookId,
      word: entry.word,
      entryUid: entry.entryUid,
      primaryGloss: entry.primaryGloss,
      meaning: summaryMeaning.isEmpty ? entry.meaning : summaryMeaning,
      rawContent: needsRawContentFallback ? entry.rawContent : '',
      fields: const <WordFieldItem>[],
    );
  }

  int _removePracticeWeakKeys(Set<String> keys) {
    if (keys.isEmpty || _practiceStore.weakWords.isEmpty) {
      return 0;
    }

    final nextWeakWords = _practiceStore.weakWords
        .where((word) => !keys.contains(_normalizeTrackedWord(word)))
        .toList(growable: false);
    final removed = _practiceStore.weakWords.length - nextWeakWords.length;
    if (removed <= 0) {
      return 0;
    }

    _practiceStore.weakWords = nextWeakWords;
    for (final key in keys) {
      _practiceStore.weakWordReasons.remove(key);
    }
    _prunePracticeTrackedEntries();
    _prunePracticeWeakReasons();
    _persistPracticeDashboard();
    _notifyStateChanged();
    return removed;
  }

  void _prunePracticeTrackedEntries() {
    final activeKeys = <String>{
      ..._practiceStore.rememberedWords.map(_normalizeTrackedWord),
      ..._practiceStore.weakWords.map(_normalizeTrackedWord),
    }.where((item) => item.isNotEmpty).toSet();
    _practiceStore.trackedEntriesByWord.removeWhere(
      (key, _) => !activeKeys.contains(key),
    );
  }

  void _prunePracticeWeakReasons() {
    final activeWeakKeys = _practiceStore.weakWords
        .map(_normalizeTrackedWord)
        .where((item) => item.isNotEmpty)
        .toSet();
    _practiceStore.weakWordReasons.removeWhere(
      (key, _) => !activeWeakKeys.contains(key),
    );
  }

  Map<String, List<String>> _normalizePracticeWeakReasonMap(
    Map<String, List<String>> raw,
    List<String> weakWords, {
    List<WordEntry>? preferredEntries,
  }) {
    if (weakWords.isEmpty) {
      return <String, List<String>>{};
    }
    final tokenToLegacyWord = <String, String>{
      for (final entry in preferredEntries ?? const <WordEntry>[])
        if (_practiceTrackingKeyForEntry(entry).isNotEmpty)
          _practiceTrackingKeyForEntry(entry): _normalizeTrackedWord(
            entry.word,
          ),
    };
    final output = <String, List<String>>{};
    for (final word in weakWords) {
      final key = _normalizeTrackedWord(word);
      final normalizedWord = tokenToLegacyWord[key] ?? key;
      if (key.isEmpty) {
        continue;
      }
      output[key] = _sanitizePracticeWeakReasons(
        raw[key] ?? raw[normalizedWord] ?? raw[word],
      );
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
        _practiceStore.weakWordReasons.remove(key);
      }
    }
    for (final word in weakWords) {
      final key = _normalizeTrackedWord(word);
      if (key.isEmpty) {
        continue;
      }
      _practiceStore.weakWordReasons[key] = List<String>.from(
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
      ..._practiceStore.sessionHistory,
    ];
    _practiceStore.sessionHistory = nextHistory
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
    return entry.displayMeaning.trim();
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
      _practiceStore.wordMemoryProgressByWordId,
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
      _practiceRepository.upsertWordMemoryProgress(nextProgress);
      nextProgressByWordId[wordId] = nextProgress;
    }

    for (final entry in rememberedEntries) {
      persistProgress(entry, remembered: true);
    }
    for (final entry in weakEntries) {
      persistProgress(entry, remembered: false);
    }

    _practiceStore.wordMemoryProgressByWordId = nextProgressByWordId;
  }

  String? _wordEntryIdentity(WordEntry entry) {
    final identity = entry.stableIdentityKey.trim();
    if (identity.isEmpty) {
      return null;
    }
    return identity;
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

  List<String> _normalizePracticeTrackingKeys(
    Object? value, {
    List<WordEntry>? preferredEntries,
  }) {
    final words = _normalizePracticeWords(value);
    if (preferredEntries == null || preferredEntries.isEmpty) {
      return words;
    }
    final byLegacyWord = <String, String>{
      for (final entry in preferredEntries)
        if (_normalizeTrackedWord(entry.word).isNotEmpty)
          _normalizeTrackedWord(entry.word): _practiceTrackingKeyForEntry(
            entry,
          ),
    };
    final normalized = <String>[];
    for (final word in words) {
      final legacyKey = _normalizeTrackedWord(word);
      final resolved = byLegacyWord[legacyKey] ?? word.trim();
      if (resolved.isEmpty ||
          normalized.any((item) => _normalizeTrackedWord(item) == legacyKey)) {
        continue;
      }
      normalized.add(resolved);
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

  String _practiceTrackingKeyForEntry(WordEntry entry) {
    return _normalizeTrackedWord(entry.collectionReferenceKey);
  }

  List<String> _trackingKeysFromEntries(List<WordEntry> entries) {
    final normalized = <String>[];
    for (final entry in entries) {
      final key = _practiceTrackingKeyForEntry(entry);
      if (key.isEmpty || normalized.contains(key)) {
        continue;
      }
      normalized.add(key);
    }
    return normalized.take(40).toList(growable: false);
  }

  List<String> _practiceDisplayWords(List<String> trackedWords) {
    final resolvedEntries = _practiceEntriesFromWords(trackedWords);
    if (resolvedEntries.isNotEmpty) {
      return resolvedEntries.map((entry) => entry.word).toList(growable: false);
    }
    final output = <String>[];
    for (final tracked in trackedWords) {
      final text = tracked.trim();
      if (text.isEmpty) {
        continue;
      }
      final fallback = text.startsWith('word:') ? text.substring(5) : text;
      if (fallback.isEmpty || output.contains(fallback)) {
        continue;
      }
      output.add(fallback);
    }
    return output;
  }
}

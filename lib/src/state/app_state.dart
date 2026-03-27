import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../i18n/app_i18n.dart';
import '../models/app_home_tab.dart';
import '../models/focus_startup_tab.dart';
import '../models/export_dto.dart';
import '../models/play_config.dart';
import '../models/practice_export_format.dart';
import '../models/practice_question_type.dart';
import '../models/practice_session_record.dart';
import '../models/settings_dto.dart';
import '../models/study_startup_tab.dart';
import '../models/todo_item.dart';
import '../models/user_data_export.dart';
import '../models/weather_snapshot.dart';
import '../models/word_entry.dart';
import '../models/word_field.dart';
import '../models/word_memory_progress.dart';
import '../models/wordbook.dart';
import '../services/ambient_service.dart';
import '../services/app_log_service.dart';
import '../services/asr_service.dart';
import '../services/database_service.dart';
import '../services/daily_quote_service.dart';
import '../services/focus_service.dart';
import '../services/memory_algorithm.dart';
import '../services/memory_lane_selector.dart';
import '../services/online_ambient_catalog_service.dart';
import '../services/playback_service.dart';
import '../services/settings_service.dart';
import '../services/weather_service.dart';
import '../utils/search_text_normalizer.dart' as search_text;

part 'app_state_practice.dart';
part 'app_state_playback.dart';
part 'app_state_startup.dart';
part 'app_state_wordbook.dart';

class PronunciationComparison {
  const PronunciationComparison({
    required this.isCorrect,
    required this.similarity,
    required this.differences,
  });

  final bool isCorrect;
  final double similarity;
  final List<String> differences;
}

enum SearchMode { all, word, meaning, fuzzy }

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  static const int _practiceSessionHistoryLimit = 365;

  static String _resolveSystemUiLanguage() {
    final locale = PlatformDispatcher.instance.locale;
    final languageCode = locale.languageCode.trim();
    if (languageCode.isNotEmpty) {
      return AppI18n.normalizeLanguageCode(languageCode);
    }
    return AppI18n.normalizeLanguageCode(locale.toLanguageTag());
  }

  AppState({
    required AppDatabaseService database,
    required SettingsService settings,
    required PlaybackService playback,
    required AmbientService ambient,
    required AsrService asr,
    required FocusService focusService,
    WeatherService? weatherService,
    DailyQuoteService? dailyQuoteService,
  }) : _database = database,
       _settings = settings,
       _playback = playback,
       _ambient = ambient,
       _asr = asr,
       _focusService = focusService,
       _weatherService = weatherService ?? WeatherService(),
       _dailyQuoteService = dailyQuoteService ?? DailyQuoteService() {
    WidgetsBinding.instance.addObserver(this);
  }

  final AppDatabaseService _database;
  final SettingsService _settings;
  final PlaybackService _playback;
  final AmbientService _ambient;
  final AsrService _asr;
  final FocusService _focusService;
  final WeatherService _weatherService;
  final DailyQuoteService _dailyQuoteService;
  final AppLogService _log = AppLogService.instance;
  final OnlineAmbientCatalogService _onlineAmbientCatalogService =
      OnlineAmbientCatalogService();

  FocusService get focusService => _focusService;

  bool _initializing = false;
  bool _initialized = false;
  bool _busy = false;
  String? _busyMessageKey;
  Map<String, Object?> _busyMessageParams = const <String, Object?>{};
  String? _message;
  Map<String, Object?> _messageParams = const <String, Object?>{};

  PlayConfig _config = PlayConfig.defaults;
  List<Wordbook> _wordbooks = <Wordbook>[];
  Wordbook? _selectedWordbook;
  List<WordEntry> _words = <WordEntry>[];
  int _currentWordIndex = 0;
  String _searchQuery = '';
  SearchMode _searchMode = SearchMode.all;
  Set<String> _favorites = <String>{};
  Set<String> _taskWords = <String>{};
  Set<String> _rememberedWords = <String>{};
  String _uiLanguage = _resolveSystemUiLanguage();
  bool _uiLanguageFollowsSystem = true;
  AppHomeTab _startupPage = AppHomeTab.focus;
  FocusStartupTab _focusStartupTab = FocusStartupTab.todo;
  StudyStartupTab _studyStartupTab = StudyStartupTab.play;
  bool _weatherEnabled = false;
  WeatherSnapshot? _weatherSnapshot;
  bool _weatherLoading = false;
  bool _startupTodoPromptEnabled = false;
  String? _startupTodoPromptSuppressedDate;
  String? _startupDailyQuote;
  String _startupDailyQuoteDateKey = '';
  bool _startupDailyQuoteLoading = false;
  bool _testModeEnabled = false;
  bool _testModeRevealed = false;
  bool _testModeHintRevealed = false;
  String? _lastBackupPath;
  String _practiceDateKey = '';
  int _practiceTodaySessions = 0;
  int _practiceTodayReviewed = 0;
  int _practiceTodayRemembered = 0;
  int _practiceTotalSessions = 0;
  int _practiceTotalReviewed = 0;
  int _practiceTotalRemembered = 0;
  String _practiceLastSessionTitle = '';
  List<String> _practiceRememberedWords = <String>[];
  List<String> _practiceWeakWords = <String>[];
  Map<String, List<String>> _practiceWeakWordReasons = <String, List<String>>{};
  List<PracticeSessionRecord> _practiceSessionHistory =
      <PracticeSessionRecord>[];
  Map<String, int> _practiceLaunchCursors = <String, int>{};
  final Map<String, WordEntry> _practiceTrackedEntriesByWord =
      <String, WordEntry>{};
  Map<int, WordMemoryProgress> _wordMemoryProgressByWordId =
      <int, WordMemoryProgress>{};
  bool _practiceAutoAddWeakWordsToTask = false;
  bool _practiceAutoPlayPronunciation = false;
  bool _practiceShowHintsByDefault = false;
  bool _practiceShowAnswerFeedbackDialog = true;
  PracticeQuestionType _practiceDefaultQuestionType =
      PracticeQuestionType.flashcard;
  PracticeRoundSettings _practiceRoundSettings = PracticeRoundSettings.defaults;
  int? _pendingTodoReminderLaunchId;

  bool _isPlaying = false;
  bool _isPaused = false;
  int _currentUnit = 0;
  int _totalUnits = 0;
  PlayUnit? _activeUnit;
  int? _playingWordbookId;
  String? _playingWordbookName;
  String? _playingWord;
  List<WordEntry> _playingScopeWords = <WordEntry>[];
  int _playingScopeIndex = 0;
  int _playSessionId = 0;
  bool _playbackScopeRestarting = false;
  int? _queuedPlaybackScopeTarget;
  int _wordbookPlaybackSyncToken = 0;
  int _wordsVersion = 0;
  Map<String, PlaybackProgressSnapshot> _playbackProgressByWordbookPath =
      <String, PlaybackProgressSnapshot>{};
  List<WordEntry>? _visibleWordsCache;
  int _visibleWordsCacheVersion = -1;
  String _visibleWordsCacheQuery = '';
  SearchMode _visibleWordsCacheMode = SearchMode.all;

  bool get initializing => _initializing;
  bool get initialized => _initialized;
  bool get busy => _busy;
  String? get busyMessageKey => _busyMessageKey;
  String? get busyMessage {
    final key = _busyMessageKey;
    if (!_busy || key == null || key.trim().isEmpty) return null;
    return AppI18n(_uiLanguage).t(key, params: _busyMessageParams);
  }

  String? get error {
    final key = _message;
    if (key == null || key.trim().isEmpty) return null;
    return AppI18n(_uiLanguage).t(key, params: _messageParams);
  }

  PlayConfig get config => _config;
  List<Wordbook> get wordbooks => _wordbooks;
  Wordbook? get selectedWordbook => _selectedWordbook;
  List<WordEntry> get words => _words;
  int get currentWordIndex => _currentWordIndex;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  int get currentUnit => _currentUnit;
  int get totalUnits => _totalUnits;
  PlayUnit? get activeUnit => _activeUnit;
  int? get playingWordbookId => _playingWordbookId;
  String? get playingWordbookName => _playingWordbookName;
  String? get playingWord => _playingWord;
  bool get isPlayingDifferentWordbook =>
      _isPlaying &&
      _playingWordbookId != null &&
      _selectedWordbook?.id != _playingWordbookId;
  Set<String> get favorites => _favorites;
  Set<String> get taskWords => _taskWords;
  String get searchQuery => _searchQuery;
  SearchMode get searchMode => _searchMode;
  String get uiLanguage => _uiLanguage;
  bool get uiLanguageFollowsSystem => _uiLanguageFollowsSystem;
  AppHomeTab get startupPage => _startupPage;
  FocusStartupTab get focusStartupTab => _focusStartupTab;
  StudyStartupTab get studyStartupTab => _studyStartupTab;
  bool get weatherEnabled => _weatherEnabled;
  WeatherSnapshot? get weatherSnapshot => _weatherSnapshot;
  bool get weatherLoading => _weatherLoading;
  bool get startupTodoPromptEnabled => _startupTodoPromptEnabled;
  bool get shouldShowStartupTodoPromptToday =>
      _startupTodoPromptEnabled &&
      _startupTodoPromptSuppressedDate != _todayDateKey();
  String? get startupDailyQuote =>
      _startupDailyQuoteDateKey == _todayDateKey() ? _startupDailyQuote : null;
  bool get startupDailyQuoteLoading => _startupDailyQuoteLoading;
  List<TodoItem> get todayActiveTodos {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    return _focusService
        .getTodos()
        .where(
          (item) =>
              !item.completed &&
              !item.isDeferred &&
              item.dueAt != null &&
              !item.dueAt!.isBefore(todayStart) &&
              item.dueAt!.isBefore(tomorrowStart),
        )
        .toList(growable: false);
  }

  String get uiLanguageSelection =>
      _uiLanguageFollowsSystem ? SettingsService.uiLanguageSystem : _uiLanguage;
  bool get testModeEnabled => _testModeEnabled;
  bool get testModeRevealed => _testModeRevealed;
  bool get testModeHintRevealed => _testModeHintRevealed;
  String? get lastBackupPath => _lastBackupPath;
  int get practiceTodaySessions => _practiceTodaySessions;
  int get practiceTodayReviewed => _practiceTodayReviewed;
  int get practiceTodayRemembered => _practiceTodayRemembered;
  int get practiceTotalSessions => _practiceTotalSessions;
  int get practiceTotalReviewed => _practiceTotalReviewed;
  int get practiceTotalRemembered => _practiceTotalRemembered;
  String get practiceLastSessionTitle => _practiceLastSessionTitle;
  List<String> get practiceRememberedWords => _practiceRememberedWords;
  List<String> get practiceWeakWords => _practiceWeakWords;
  List<PracticeSessionRecord> get practiceSessionHistory =>
      List<PracticeSessionRecord>.unmodifiable(_practiceSessionHistory);
  bool get practiceAutoAddWeakWordsToTask => _practiceAutoAddWeakWordsToTask;
  bool get practiceAutoPlayPronunciation => _practiceAutoPlayPronunciation;
  bool get practiceShowHintsByDefault => _practiceShowHintsByDefault;
  bool get practiceShowAnswerFeedbackDialog =>
      _practiceShowAnswerFeedbackDialog;
  PracticeQuestionType get practiceDefaultQuestionType =>
      _practiceDefaultQuestionType;
  PracticeRoundSettings get practiceRoundSettings => _practiceRoundSettings;
  int? get pendingTodoReminderLaunchId => _pendingTodoReminderLaunchId;
  List<WordEntry> get practiceWrongNotebookEntries {
    return _practiceEntriesFromWords(_practiceWeakWords);
  }

  double get practiceTodayAccuracy => _practiceTodayReviewed <= 0
      ? 0
      : (_practiceTodayRemembered / _practiceTodayReviewed).clamp(0.0, 1.0);
  double get practiceTotalAccuracy => _practiceTotalReviewed <= 0
      ? 0
      : (_practiceTotalRemembered / _practiceTotalReviewed).clamp(0.0, 1.0);
  List<AmbientSource> get ambientSources => _ambient.sources;
  bool get ambientEnabled => _ambient.isEnabled;
  double get ambientMasterVolume => _ambient.masterVolume;

  List<WordEntry> get visibleWords {
    if (_visibleWordsCache != null &&
        _visibleWordsCacheVersion == _wordsVersion &&
        _visibleWordsCacheQuery == _searchQuery &&
        _visibleWordsCacheMode == _searchMode) {
      return _visibleWordsCache!;
    }

    final normalizedQuery = _searchQuery.trim();
    final selectedWordbook = _selectedWordbook;
    final computed = selectedWordbook == null || normalizedQuery.isEmpty
        ? _words
        : _database.searchWords(
            selectedWordbook.id,
            query: normalizedQuery,
            mode: _searchMode.name,
          );
    _visibleWordsCache = computed;
    _visibleWordsCacheVersion = _wordsVersion;
    _visibleWordsCacheQuery = _searchQuery;
    _visibleWordsCacheMode = _searchMode;
    return computed;
  }

  bool requiresWordbookLoadConfirmation(Wordbook wordbook) {
    return _database.isLazyBuiltInPath(wordbook.path) &&
        wordbook.wordCount <= 0;
  }

  List<WordEntry> get recentWeakWordEntries {
    return _memoryRecoveryEntries(_words);
  }

  List<WordEntry> get recentRememberedWordEntries {
    return _memoryStableEntries(_words);
  }

  WordMemoryProgress? memoryProgressForWordEntry(WordEntry entry) {
    final wordId = entry.id;
    if (wordId == null || wordId <= 0) {
      return null;
    }
    return _wordMemoryProgressByWordId[wordId];
  }

  List<String> practiceWeakReasonsForWord(WordEntry entry) {
    final key = _normalizeTrackedWord(entry.word);
    final reasons = _practiceWeakWordReasons[key];
    if (reasons == null || reasons.isEmpty) {
      return const <String>[];
    }
    return List<String>.unmodifiable(reasons);
  }

  void updatePracticeSessionPreferences({
    bool? autoAddWeakWordsToTask,
    bool? autoPlayPronunciation,
    bool? showHintsByDefault,
    bool? showAnswerFeedbackDialog,
    PracticeQuestionType? defaultQuestionType,
  }) => _updatePracticeSessionPreferencesImpl(
    autoAddWeakWordsToTask: autoAddWeakWordsToTask,
    autoPlayPronunciation: autoPlayPronunciation,
    showHintsByDefault: showHintsByDefault,
    showAnswerFeedbackDialog: showAnswerFeedbackDialog,
    defaultQuestionType: defaultQuestionType,
  );

  bool dismissPracticeWeakWord(WordEntry entry) =>
      _dismissPracticeWeakWordImpl(entry);

  int dismissPracticeWeakWords(Iterable<WordEntry> entries) =>
      _dismissPracticeWeakWordsImpl(entries);

  Future<int> addPracticeWordsToTask(Iterable<WordEntry> entries) =>
      _addPracticeWordsToTaskImpl(entries);

  Future<int> addPracticeWordsToFavorites(Iterable<WordEntry> entries) =>
      _addPracticeWordsToFavoritesImpl(entries);

  int clearPracticeWeakWords({bool masteredOnly = false}) =>
      _clearPracticeWeakWordsImpl(masteredOnly: masteredOnly);

  int get visibleWordCount {
    final selectedWordbook = _selectedWordbook;
    if (selectedWordbook == null) {
      return 0;
    }
    if (_searchQuery.trim().isEmpty) {
      return _words.length;
    }
    return _database.countSearchWords(
      selectedWordbook.id,
      query: _searchQuery,
      mode: _searchMode.name,
    );
  }

  List<WordEntry> getVisibleWordsPage({required int limit, int offset = 0}) {
    final selectedWordbook = _selectedWordbook;
    if (selectedWordbook == null) {
      return const <WordEntry>[];
    }
    if (_searchQuery.trim().isEmpty) {
      final start = offset.clamp(0, _words.length).toInt();
      final end = (start + limit).clamp(start, _words.length).toInt();
      return _words.sublist(start, end);
    }
    return _database.searchWords(
      selectedWordbook.id,
      query: _searchQuery,
      mode: _searchMode.name,
      limit: limit,
      offset: offset,
    );
  }

  int? findVisibleWordOffsetByPrefix(String prefix) {
    final selectedWordbook = _selectedWordbook;
    if (selectedWordbook == null) {
      return null;
    }
    return _database.findSearchOffsetByPrefix(
      selectedWordbook.id,
      prefix: prefix,
      query: _searchQuery,
      mode: _searchMode.name,
    );
  }

  int? findVisibleWordOffsetByInitial(String initial) {
    final selectedWordbook = _selectedWordbook;
    if (selectedWordbook == null) {
      return null;
    }
    return _database.findSearchOffsetByInitial(
      selectedWordbook.id,
      initial: initial,
      query: _searchQuery,
      mode: _searchMode.name,
    );
  }

  int? findVisibleWordOffsetForEntry(WordEntry entry) {
    final selectedWordbook = _selectedWordbook;
    if (selectedWordbook == null || entry.wordbookId != selectedWordbook.id) {
      return null;
    }
    final wordId = entry.id;
    if (_searchQuery.trim().isEmpty || wordId == null || wordId <= 0) {
      final index = visibleWords.indexWhere(
        (item) => _isSameWordEntry(item, entry),
      );
      return index < 0 ? null : index;
    }
    final offset = _database.findSearchOffsetByWordId(
      selectedWordbook.id,
      wordId: wordId,
      query: _searchQuery,
      mode: _searchMode.name,
    );
    if (offset != null) {
      return offset;
    }
    final fallbackIndex = visibleWords.indexWhere(
      (item) => _isSameWordEntry(item, entry),
    );
    return fallbackIndex < 0 ? null : fallbackIndex;
  }

  WordEntry? get currentWord {
    if (_currentWordIndex < 0 || _currentWordIndex >= _words.length) {
      return _scopeWords.isEmpty ? null : _scopeWords.first;
    }
    final current = _words[_currentWordIndex];
    if (_searchQuery.trim().isEmpty) return current;
    if (visibleWords.any((item) => _isSameWordEntry(item, current))) {
      return current;
    }
    return _scopeWords.isEmpty ? null : _scopeWords.first;
  }

  String _localizedBuiltinWordbookName(String path) {
    final language = AppI18n.normalizeLanguageCode(_uiLanguage);
    if (path == 'builtin:favorites') {
      return switch (language) {
        'zh' => '收藏',
        'ja' => 'お気に入り',
        'de' => 'Favoriten',
        'fr' => 'Favoris',
        'es' => 'Favoritos',
        _ => 'Favorites',
      };
    }
    if (path == 'builtin:task') {
      return switch (language) {
        'zh' => '任务',
        'ja' => 'タスク',
        'de' => 'Aufgabe',
        'fr' => 'Tache',
        'es' => 'Tarea',
        _ => 'Task',
      };
    }
    return '';
  }

  Wordbook _withLocalizedBuiltinName(Wordbook wordbook) {
    final localized = _localizedBuiltinWordbookName(wordbook.path);
    if (localized.isEmpty || localized == wordbook.name) return wordbook;
    return Wordbook(
      id: wordbook.id,
      name: localized,
      path: wordbook.path,
      wordCount: wordbook.wordCount,
      createdAt: wordbook.createdAt,
    );
  }

  void _refreshLocalizedWordbookNames() {
    if (_wordbooks.isEmpty) return;
    _wordbooks = _wordbooks
        .map(_withLocalizedBuiltinName)
        .toList(growable: false);

    final selectedId = _selectedWordbook?.id;
    if (selectedId != null) {
      _selectedWordbook = _wordbooks
          .where((item) => item.id == selectedId)
          .cast<Wordbook?>()
          .firstOrNull;
    }

    final playingId = _playingWordbookId;
    if (playingId != null) {
      final playingBook = _wordbooks
          .where((item) => item.id == playingId)
          .cast<Wordbook?>()
          .firstOrNull;
      if (playingBook != null) {
        _playingWordbookName = playingBook.name;
      }
    }
  }

  Future<void> init() => _initImpl();

  void clearMessage() => _clearMessageImpl();

  void setUiLanguage(String language) => _setUiLanguageImpl(language);

  void setUiLanguageFollowSystem() => _setUiLanguageFollowSystemImpl();

  void setStartupPage(AppHomeTab page) => _setStartupPageImpl(page);

  void setFocusStartupTab(FocusStartupTab tab) => _setFocusStartupTabImpl(tab);

  void setStudyStartupTab(StudyStartupTab tab) => _setStudyStartupTabImpl(tab);

  void setWeatherEnabled(bool enabled) => _setWeatherEnabledImpl(enabled);

  void setStartupTodoPromptEnabled(bool enabled) =>
      _setStartupTodoPromptEnabledImpl(enabled);

  void suppressStartupTodoPromptForToday() =>
      _suppressStartupTodoPromptForTodayImpl();

  Future<void> refreshStartupTodoPromptContent({bool force = false}) =>
      _refreshStartupTodoPromptContentImpl(force: force);

  Future<void> refreshWeather({bool force = false}) =>
      _refreshWeatherImpl(force: force);

  void refreshWeatherIfStale() => _refreshWeatherIfStaleImpl();

  @override
  void didChangeLocales(List<Locale>? locales) {
    super.didChangeLocales(locales);
    _didChangeLocalesImpl(locales);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _didChangeAppLifecycleStateImpl(state);
  }

  int? consumePendingTodoReminderLaunchId() =>
      _consumePendingTodoReminderLaunchIdImpl();

  void setTestModeEnabled(bool enabled) => _setTestModeEnabledImpl(enabled);

  void toggleTestModeReveal() => _toggleTestModeRevealImpl();

  void toggleTestModeHint() => _toggleTestModeHintImpl();

  void resetTestModeProgress() => _resetTestModeProgressImpl();

  void recordPracticeSession({
    required String title,
    required int total,
    required int remembered,
    required List<String> rememberedWords,
    required List<String> weakWords,
    List<WordEntry>? rememberedEntries,
    List<WordEntry>? weakEntries,
    Map<String, List<String>> weakReasonIdsByWord =
        const <String, List<String>>{},
  }) => _recordPracticeSessionImpl(
    title: title,
    total: total,
    remembered: remembered,
    rememberedWords: rememberedWords,
    weakWords: weakWords,
    rememberedEntries: rememberedEntries,
    weakEntries: weakEntries,
    weakReasonIdsByWord: weakReasonIdsByWord,
  );

  void startPracticeSession({required String title}) =>
      _startPracticeSessionImpl(title: title);

  void recordPracticeAnswer({
    required WordEntry entry,
    required bool remembered,
    List<String> weakReasonIds = const <String>[],
    bool addToWrongNotebook = true,
    String? sessionTitle,
  }) => _recordPracticeAnswerImpl(
    entry: entry,
    remembered: remembered,
    weakReasonIds: weakReasonIds,
    addToWrongNotebook: addToWrongNotebook,
    sessionTitle: sessionTitle,
  );

  void finishPracticeSession({
    required String title,
    required int total,
    required int remembered,
    Map<String, List<String>> weakReasonIdsByWord =
        const <String, List<String>>{},
  }) => _finishPracticeSessionImpl(
    title: title,
    total: total,
    remembered: remembered,
    weakReasonIdsByWord: weakReasonIdsByWord,
  );

  void updatePracticeRoundSettings({
    PracticeRoundSource? source,
    PracticeRoundStartMode? startMode,
    int? roundSize,
    bool? shuffle,
    bool? collapsed,
  }) => _updatePracticeRoundSettingsImpl(
    source: source,
    startMode: startMode,
    roundSize: roundSize,
    shuffle: shuffle,
    collapsed: collapsed,
  );

  List<WordEntry> beginPracticeBatch({
    required String cursorKey,
    required List<WordEntry> sourceWords,
    required int batchSize,
    WordEntry? anchorWord,
    int? cursorAdvance,
  }) => _beginPracticeBatchImpl(
    cursorKey: cursorKey,
    sourceWords: sourceWords,
    batchSize: batchSize,
    anchorWord: anchorWord,
    cursorAdvance: cursorAdvance,
  );

  int previewPracticeBatchStartIndex({
    required String cursorKey,
    required List<WordEntry> sourceWords,
    PracticeRoundStartMode? startMode,
    WordEntry? anchorWord,
  }) => _previewPracticeBatchStartIndexImpl(
    cursorKey: cursorKey,
    sourceWords: sourceWords,
    startMode: startMode,
    anchorWord: anchorWord,
  );

  void setSearchQuery(String value) => _setSearchQueryImpl(value);

  void setSearchMode(SearchMode mode) => _setSearchModeImpl(mode);

  Future<void> selectWordbook(
    Wordbook? wordbook, {
    String? focusWord,
    int? focusWordId,
  }) => _selectWordbookImpl(
    wordbook,
    focusWord: focusWord,
    focusWordId: focusWordId,
  );

  void selectWordIndex(int index) => _selectWordIndexImpl(index);

  void selectWordByText(String word) => _selectWordByTextImpl(word);

  void selectWordEntry(WordEntry entry) => _selectWordEntryImpl(entry);

  Future<void> createWordbook(String name) async {
    if (name.trim().isEmpty) return;
    _setBusy(true);
    try {
      final id = _database.createWordbook(name.trim());
      await _reloadWordbooks(keepCurrentSelection: false);
      final created = _wordbooks
          .where((item) => item.id == id)
          .cast<Wordbook?>()
          .firstOrNull;
      if (created != null) {
        await selectWordbook(created);
      }
    } catch (error) {
      _setMessage(
        'errorCreateWordbookFailed',
        params: <String, Object?>{'error': error},
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<void> renameWordbook(Wordbook wordbook, String newName) async {
    _setBusy(true);
    try {
      _database.renameWordbook(wordbook.id, newName.trim());
      await _reloadWordbooks(keepCurrentSelection: true);
    } catch (error) {
      _setMessage(
        'errorRenameWordbookFailed',
        params: <String, Object?>{'error': error},
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<void> deleteWordbook(Wordbook wordbook) async {
    _setBusy(true);
    try {
      _database.deleteManagedWordbook(wordbook.id);
      await _reloadWordbooks(keepCurrentSelection: true);
      await _syncSpecialWordbooks();
    } catch (error) {
      _setMessage(
        'errorDeleteWordbookFailed',
        params: <String, Object?>{'error': error},
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<void> importWordbookByPicker({
    Future<String?> Function(String suggestedName)? requestName,
  }) async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: <String>['json', 'csv', 'mdx', 'mdd'],
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    if (file.path == null || file.path!.trim().isEmpty) return;
    var name = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
    if (requestName != null) {
      final provided = await requestName(name);
      if (provided == null) return;
      final trimmed = provided.trim();
      if (trimmed.isNotEmpty) {
        name = trimmed;
      }
    }
    await importWordbookFile(file.path!, name);
  }

  Future<void> importWordbookFile(String filePath, String name) async {
    _setBusy(
      true,
      messageKey: 'busyImportingWordbook',
      params: <String, Object?>{'name': name.trim()},
    );
    try {
      await _createSafetyBackup(reason: 'import_wordbook');
      final count = await _database.importWordbookFile(
        filePath: filePath,
        name: name.trim().isEmpty
            ? AppI18n(_uiLanguage).t('importedWordbookName')
            : name.trim(),
      );
      await _reloadWordbooks(keepCurrentSelection: false);
      await _syncSpecialWordbooks();
      _setMessage(
        _lastBackupPath == null
            ? 'importWordbookSuccess'
            : 'importWordbookSuccessWithBackup',
        params: <String, Object?>{'count': count},
      );
    } catch (error) {
      _setMessage(
        'errorImportFailed',
        params: <String, Object?>{'error': error},
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<void> importLegacyDatabaseByPicker() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: <String>['db', 'sqlite', 'sqlite3'],
    );
    if (picked == null || picked.files.isEmpty) return;
    final path = picked.files.first.path;
    if (path == null || path.trim().isEmpty) return;

    _setBusy(true, messageKey: 'busyMigratingLegacyData');
    try {
      await _createSafetyBackup(reason: 'legacy_migration');
      final count = await _database.importLegacyDatabase(path);
      await _reloadWordbooks(keepCurrentSelection: false);
      await _syncSpecialWordbooks();
      _setMessage(
        _lastBackupPath == null
            ? 'migrationSuccess'
            : 'migrationSuccessWithBackup',
        params: <String, Object?>{'count': count},
      );
    } catch (error) {
      _setMessage(
        'errorMigrationFailed',
        params: <String, Object?>{'error': error},
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> saveWord({
    WordEntry? original,
    required String word,
    required List<WordFieldItem> fields,
    String rawContent = '',
  }) async {
    final selected = _selectedWordbook;
    if (selected == null) return false;
    if (word.trim().isEmpty) {
      _setMessage('errorWordEmpty');
      notifyListeners();
      return false;
    }

    final payload = WordEntryPayload(
      word: word.trim(),
      fields: fields,
      rawContent: rawContent,
    );

    _setBusy(true);
    try {
      if (original == null) {
        _database.addWord(selected.id, payload);
      } else {
        _database.updateWord(
          wordbookId: selected.id,
          sourceWord: original.word,
          payload: payload,
        );
      }
      await _reloadWordbooks(keepCurrentSelection: true);
      await selectWordbook(selected, focusWord: word.trim());
      await _syncSpecialWordbooks();
      return true;
    } catch (error) {
      _setMessage(
        'errorSaveWordFailed',
        params: <String, Object?>{'error': error},
      );
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<int> importWordsBatch(List<WordEntryPayload> payloads) async {
    final selected = _selectedWordbook;
    if (selected == null || payloads.isEmpty) return 0;
    _setBusy(true);
    var imported = 0;
    try {
      for (final payload in payloads) {
        final word = payload.word.trim();
        if (word.isEmpty) continue;
        _database.upsertWord(
          selected.id,
          payload.copyWith(word: word, fields: mergeFieldItems(payload.fields)),
        );
        imported += 1;
      }
      await _reloadWordbooks(keepCurrentSelection: true);
      await selectWordbook(selected);
      await _syncSpecialWordbooks();
      _setMessage(
        'importWordbookSuccess',
        params: <String, Object?>{'count': imported},
      );
      return imported;
    } catch (error) {
      _setMessage(
        'errorImportFailed',
        params: <String, Object?>{'error': error},
      );
      return imported;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> deleteWord(WordEntry word) async {
    final selected = _selectedWordbook;
    if (selected == null) return;
    _setBusy(true);
    try {
      _database.deleteWord(selected.id, word.word);
      await _reloadWordbooks(keepCurrentSelection: true);
      await selectWordbook(selected);
      await _syncSpecialWordbooks();
    } catch (error) {
      _setMessage(
        'errorDeleteWordFailed',
        params: <String, Object?>{'error': error},
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<void> toggleFavorite(WordEntry word) async {
    final favoritesBook = _wordbooks
        .where((item) => item.path == 'builtin:favorites')
        .cast<Wordbook?>()
        .firstOrNull;
    if (favoritesBook == null) return;

    final wasFavorite = _favorites.contains(word.word);
    final previousFavorites = Set<String>.from(_favorites);
    final previousWordbooks = List<Wordbook>.from(_wordbooks);
    final previousSelectedWordbook = _selectedWordbook;
    final previousWords = List<WordEntry>.from(_words);
    final previousCurrentWordIndex = _currentWordIndex;

    final nextFavorites = Set<String>.from(_favorites);
    if (wasFavorite) {
      nextFavorites.remove(word.word);
    } else {
      nextFavorites.add(word.word);
    }
    _favorites = nextFavorites;
    _persistSpecialWordSet('favorites', _favorites);
    _updateWordbookCount(favoritesBook.path, wasFavorite ? -1 : 1);
    _refreshSelectedSpecialWordbook(
      favoritesBook,
      optimisticWord: word,
      optimisticAdded: !wasFavorite,
    );
    notifyListeners();

    try {
      if (wasFavorite) {
        _database.deleteWord(favoritesBook.id, word.word);
      } else {
        _database.upsertWord(favoritesBook.id, word.toPayload());
      }
      _refreshSelectedSpecialWordbook(favoritesBook);
      _persistSpecialWordSet('favorites', _favorites);
      notifyListeners();
    } catch (error) {
      _favorites = previousFavorites;
      _persistSpecialWordSet('favorites', _favorites);
      _restoreWordbookSnapshot(
        wordbooks: previousWordbooks,
        selectedWordbook: previousSelectedWordbook,
        words: previousWords,
        currentWordIndex: previousCurrentWordIndex,
      );
      _setMessage(
        'errorFavoriteOperationFailed',
        params: <String, Object?>{'error': error},
      );
      notifyListeners();
    }
  }

  Future<void> toggleTaskWord(WordEntry word) async {
    final taskBook = _wordbooks
        .where((item) => item.path == 'builtin:task')
        .cast<Wordbook?>()
        .firstOrNull;
    if (taskBook == null) return;

    final wasTaskWord = _taskWords.contains(word.word);
    final previousTaskWords = Set<String>.from(_taskWords);
    final previousWordbooks = List<Wordbook>.from(_wordbooks);
    final previousSelectedWordbook = _selectedWordbook;
    final previousWords = List<WordEntry>.from(_words);
    final previousCurrentWordIndex = _currentWordIndex;

    final nextTaskWords = Set<String>.from(_taskWords);
    if (wasTaskWord) {
      nextTaskWords.remove(word.word);
    } else {
      nextTaskWords.add(word.word);
    }
    _taskWords = nextTaskWords;
    _persistSpecialWordSet('taskWords', _taskWords);
    _updateWordbookCount(taskBook.path, wasTaskWord ? -1 : 1);
    _refreshSelectedSpecialWordbook(
      taskBook,
      optimisticWord: word,
      optimisticAdded: !wasTaskWord,
    );
    notifyListeners();

    try {
      if (wasTaskWord) {
        _database.deleteWord(taskBook.id, word.word);
      } else {
        _database.upsertWord(taskBook.id, word.toPayload());
      }
      _refreshSelectedSpecialWordbook(taskBook);
      _persistSpecialWordSet('taskWords', _taskWords);
      notifyListeners();
    } catch (error) {
      _taskWords = previousTaskWords;
      _persistSpecialWordSet('taskWords', _taskWords);
      _restoreWordbookSnapshot(
        wordbooks: previousWordbooks,
        selectedWordbook: previousSelectedWordbook,
        words: previousWords,
        currentWordIndex: previousCurrentWordIndex,
      );
      _setMessage(
        'errorTaskOperationFailed',
        params: <String, Object?>{'error': error},
      );
      notifyListeners();
    }
  }

  Future<void> clearTaskWordbook() async {
    final taskBook = _wordbooks
        .where((item) => item.path == 'builtin:task')
        .cast<Wordbook?>()
        .firstOrNull;
    if (taskBook == null) return;
    _setBusy(true);
    try {
      _database.clearWordbook(taskBook.id);
      await _syncSpecialWordbooks();
      await _reloadWordbooks(keepCurrentSelection: true);
    } catch (error) {
      _setMessage(
        'errorClearTaskWordbookFailed',
        params: <String, Object?>{'error': error},
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<void> exportTaskWordbook(String name) async {
    final taskBook = _wordbooks
        .where((item) => item.path == 'builtin:task')
        .cast<Wordbook?>()
        .firstOrNull;
    if (taskBook == null) return;
    _setBusy(true);
    try {
      final exportedId = _database.exportWordbook(taskBook.id, name);
      await _reloadWordbooks(keepCurrentSelection: false);
      final exported = _wordbooks
          .where((item) => item.id == exportedId)
          .cast<Wordbook?>()
          .firstOrNull;
      if (exported != null) {
        await selectWordbook(exported);
      }
      await _syncSpecialWordbooks();
    } catch (error) {
      _setMessage(
        'errorExportFailed',
        params: <String, Object?>{'error': error},
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<void> mergeWordbooks({
    required int sourceWordbookId,
    required int targetWordbookId,
    required bool deleteSourceAfterMerge,
  }) async {
    _setBusy(true, messageKey: 'busyMergingWordbooks');
    try {
      await _createSafetyBackup(reason: 'merge_wordbooks');
      _database.mergeWordbooks(
        sourceWordbookId: sourceWordbookId,
        targetWordbookId: targetWordbookId,
        deleteSourceAfterMerge: deleteSourceAfterMerge,
      );
      await _reloadWordbooks(keepCurrentSelection: true);
      await _syncSpecialWordbooks();
    } catch (error) {
      _setMessage(
        'errorMergeFailed',
        params: <String, Object?>{'error': error},
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> resetUserData() async {
    _setBusy(true, messageKey: 'busyResettingUserData');
    try {
      await _createSafetyBackup(reason: 'reset_user_data');
      await stop();
      _focusService.stop(saveProgress: false);
      await _ambient.reset();
      await _database.resetUserData();

      _message = null;
      _messageParams = const <String, Object?>{};
      _searchQuery = '';
      _searchMode = SearchMode.all;
      _favorites = <String>{};
      _taskWords = <String>{};
      await _reloadPersistentStateAfterDatabaseChange();
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      _log.e(
        'app_state',
        'reset user data failed',
        error: error,
        stackTrace: stackTrace,
      );
      _setMessage(
        'errorResetUserDataFailed',
        params: <String, Object?>{'error': error},
      );
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<List<DatabaseBackupInfo>> listDatabaseBackups() {
    return _database.listSafetyBackups();
  }

  Future<bool> deleteDatabaseBackup(DatabaseBackupInfo backup) async {
    try {
      await _database.deleteSafetyBackup(backup.path);
      if (_lastBackupPath == backup.path) {
        _lastBackupPath = null;
      }
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      _log.e(
        'app_state',
        'delete backup failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'path': backup.path},
      );
      _setMessage(
        'errorInitFailed',
        params: <String, Object?>{'error': 'delete backup: $error'},
      );
      notifyListeners();
      return false;
    }
  }

  Future<String> getDefaultUserDataExportDirectoryPath() async {
    return _database.getDefaultUserDataExportDirectoryPath();
  }

  Future<String?> exportUserData({
    Iterable<UserDataExportSection>? sections,
    String? directoryPath,
    String? fileName,
  }) async {
    _setBusy(true, messageKey: 'processing');
    try {
      return await _database.exportUserData(
        sections: sections,
        directoryPath: directoryPath,
        fileName: fileName,
      );
    } catch (error, stackTrace) {
      _log.e(
        'app_state',
        'export user data failed',
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

  PracticeReviewExportPayload buildPracticeReviewExportPayload({
    Iterable<PracticeSessionRecord>? records,
    Iterable<WordEntry>? wrongNotebookEntries,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) => _buildPracticeReviewExportPayloadImpl(
    records: records,
    wrongNotebookEntries: wrongNotebookEntries,
    metadata: metadata,
  );

  Future<String?> exportPracticeReviewData({
    required PracticeExportFormat format,
    String? directoryPath,
    String? fileName,
    Iterable<PracticeSessionRecord>? records,
    Iterable<WordEntry>? wrongNotebookEntries,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) => _exportPracticeReviewDataImpl(
    format: format,
    directoryPath: directoryPath,
    fileName: fileName,
    records: records,
    wrongNotebookEntries: wrongNotebookEntries,
    metadata: metadata,
  );

  PracticeWrongNotebookExportPayload buildPracticeWrongNotebookExportPayload({
    required Iterable<WordEntry> entries,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) => _buildPracticeWrongNotebookExportPayloadImpl(
    entries: entries,
    metadata: metadata,
  );

  Future<String?> exportPracticeWrongNotebookData({
    required Iterable<WordEntry> entries,
    required PracticeExportFormat format,
    String? directoryPath,
    String? fileName,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) => _exportPracticeWrongNotebookDataImpl(
    entries: entries,
    format: format,
    directoryPath: directoryPath,
    fileName: fileName,
    metadata: metadata,
  );

  Future<bool> restoreDatabaseBackup(DatabaseBackupInfo backup) async {
    _setBusy(
      true,
      messageKey: 'busyRestoringBackup',
      params: <String, Object?>{'name': backup.name},
    );
    try {
      await _createSafetyBackup(reason: 'before_restore');
      await stop();
      _focusService.stop(saveProgress: false);
      await _ambient.stopAll();
      await _database.restoreSafetyBackup(backup.path);
      _message = null;
      _messageParams = const <String, Object?>{};
      await _reloadPersistentStateAfterDatabaseChange();
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      _log.e(
        'app_state',
        'restore backup failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'path': backup.path},
      );
      _setMessage(
        'errorInitFailed',
        params: <String, Object?>{'error': 'restore backup: $error'},
      );
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  void updateConfig(PlayConfig config) {
    _log.i(
      'app_state',
      'update config',
      data: <String, Object?>{
        'ttsProvider': config.tts.provider.name,
        'ttsModel': config.tts.model,
        'ttsVoice': config.tts.activeVoice,
        'ttsSpeed': config.tts.speed,
        'ttsVolume': config.tts.volume,
        'voiceInputProvider': config.voiceInput.provider.name,
        'voiceInputLanguage': config.voiceInput.language,
        'voiceInputModel': config.voiceInput.model,
        'asrProvider': config.asr.provider.name,
        'asrEnabled': config.asr.enabled,
        'appearanceTheme': config.appearance.normalizedTheme,
        'appearanceCompact': config.appearance.compactLayout,
        'appearanceHighContrast': config.appearance.highContrastText,
        'appearanceGradient': config.appearance.normalizedGradientIntensity,
        'appearanceEffects': config.appearance.normalizedEffectIntensity,
      },
    );
    _config = config;
    _settings.savePlayConfig(config);
    _playback.updateRuntimeConfig(config);
    notifyListeners();
  }

  Future<void> play() => _playImpl();

  Future<void> pauseOrResume() => _pauseOrResumeImpl();

  Future<void> stop() => _stopPlaybackImpl();

  Future<void> skipCurrentWord() => _skipCurrentWordImpl();

  Future<void> playPreviousWord() => _playPreviousWordImpl();

  Future<void> playNextWord() => _playNextWordImpl();

  Future<void> jumpToPlayingWordbook() => _jumpToPlayingWordbookImpl();

  Future<void> playCurrentWordbook() => _playCurrentWordbookImpl();

  Future<void> movePlaybackPreviousWord() => _movePlaybackPreviousWordImpl();

  Future<void> movePlaybackNextWord() => _movePlaybackNextWordImpl();

  void rememberPlaybackProgress([WordEntry? entry]) =>
      _rememberPlaybackProgressImpl(entry);

  bool restorePlaybackProgressForSelectedWordbook() =>
      _restorePlaybackProgressForSelectedWordbookImpl();

  bool jumpByInitial(String initial) {
    final selectedWordbook = _selectedWordbook;
    if (selectedWordbook == null) return false;
    final entry = _database.findJumpWordByInitial(
      selectedWordbook.id,
      initial: initial,
      query: _searchQuery,
      mode: _searchMode.name,
    );
    if (entry == null) return false;
    _setCurrentWordByEntry(entry);
    resetTestModeProgress();
    notifyListeners();
    return true;
  }

  bool jumpByPrefix(String rawPrefix) {
    final selectedWordbook = _selectedWordbook;
    if (selectedWordbook == null) return false;
    final entry = _database.findJumpWordByPrefix(
      selectedWordbook.id,
      prefix: rawPrefix,
      query: _searchQuery,
      mode: _searchMode.name,
    );
    if (entry == null) return false;
    _setCurrentWordByEntry(entry);
    resetTestModeProgress();
    notifyListeners();
    return true;
  }

  Future<void> setAmbientMasterVolume(double value) async {
    _ambient.setMasterVolume(value);
    await _ambient.syncPlayback();
    notifyListeners();
  }

  Future<void> setAmbientEnabled(bool value) async {
    _ambient.setEnabled(value);
    await _ambient.syncPlayback();
    notifyListeners();
  }

  Future<void> setAmbientSourceEnabled(String sourceId, bool enabled) async {
    _ambient.setSourceEnabled(sourceId, enabled);
    await _ambient.syncPlayback();
    notifyListeners();
  }

  Future<void> setAmbientSourceVolume(String sourceId, double value) async {
    _ambient.setSourceVolume(sourceId, value);
    await _ambient.syncPlayback();
    notifyListeners();
  }

  Future<void> addAmbientFileSource() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: <String>['mp3', 'wav', 'ogg', 'm4a', 'flac'],
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    if (file.path == null || file.path!.trim().isEmpty) return;

    _ambient.addFileSource(file.path!, name: file.name);
    await _ambient.syncPlayback();
    notifyListeners();
  }

  Future<List<OnlineAmbientSoundOption>> fetchOnlineAmbientCatalog({
    bool forceRefresh = false,
  }) {
    return _onlineAmbientCatalogService.fetchCatalog(
      forceRefresh: forceRefresh,
    );
  }

  Future<Set<String>> fetchDownloadedOnlineAmbientRelativePaths() {
    return _onlineAmbientCatalogService.listDownloadedRelativePaths();
  }

  Future<String?> downloadOnlineAmbientSource(
    OnlineAmbientSoundOption option,
  ) async {
    try {
      final path = await _onlineAmbientCatalogService.downloadToLocal(option);
      _ambient.addFileSourceWithMetadata(
        path,
        id: 'downloaded_${option.id}',
        name: option.name,
        categoryKey: option.categoryKey,
        volume: option.defaultVolume,
      );
      await _ambient.syncPlayback();
      notifyListeners();
      return path;
    } catch (error, stackTrace) {
      _log.e(
        'app_state',
        'download online ambient failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'id': option.id,
          'name': option.name,
          'url': option.primaryUrl,
        },
      );
      return null;
    }
  }

  Future<bool> deleteDownloadedOnlineAmbientSource(
    OnlineAmbientSoundOption option,
  ) async {
    try {
      final path = await _onlineAmbientCatalogService.localPathFor(option);
      await _onlineAmbientCatalogService.deleteLocal(option);
      final matchingIds = _ambient.sources
          .where(
            (source) =>
                source.id == 'downloaded_${option.id}' ||
                (source.filePath?.trim() ?? '') == path.trim(),
          )
          .map((source) => source.id)
          .toList(growable: false);
      for (final sourceId in matchingIds) {
        _ambient.removeSource(sourceId);
      }
      await _ambient.syncPlayback();
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      _log.e(
        'app_state',
        'delete downloaded ambient failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'id': option.id,
          'name': option.name,
          'relativePath': option.relativePath,
        },
      );
      return false;
    }
  }

  Future<String?> pickBackgroundImageByPicker() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final file = picked.files.first;
    final path = file.path;
    if (path == null || path.trim().isEmpty) return null;
    return path;
  }

  Future<void> removeAmbientSource(String sourceId) async {
    _ambient.removeSource(sourceId);
    await _ambient.syncPlayback();
    notifyListeners();
  }

  Future<void> previewPronunciation(String word) async {
    final target = word.trim();
    if (target.isEmpty) return;
    final configSnapshot = _config;
    try {
      await _playback.speakText(target, configSnapshot);
      return;
    } catch (error, stackTrace) {
      _log.e(
        'app_state',
        'preview pronunciation failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'provider': configSnapshot.tts.provider.name,
          'word': target,
        },
      );

      if (configSnapshot.tts.provider != TtsProviderType.local) {
        final fallbackConfig = configSnapshot.copyWith(
          tts: configSnapshot.tts.copyWith(
            provider: TtsProviderType.local,
            voice: configSnapshot.tts.localVoice,
          ),
        );
        try {
          _log.w(
            'app_state',
            'preview pronunciation fallback to local tts',
            data: <String, Object?>{'word': target},
          );
          await _playback.speakText(target, fallbackConfig);
          return;
        } catch (fallbackError, fallbackStackTrace) {
          _log.e(
            'app_state',
            'preview pronunciation local fallback failed',
            error: fallbackError,
            stackTrace: fallbackStackTrace,
            data: <String, Object?>{'word': target},
          );
          _setMessage(
            'errorInitFailed',
            params: <String, Object?>{
              'error': 'preview pronunciation: $fallbackError',
            },
          );
          notifyListeners();
          return;
        }
      }

      _setMessage(
        'errorInitFailed',
        params: <String, Object?>{'error': 'preview pronunciation: $error'},
      );
      notifyListeners();
    }
  }

  Future<List<String>> fetchLocalTtsVoices() async {
    try {
      final voices = await _playback.getLocalVoices();
      _log.i(
        'app_state',
        'local voices fetched',
        data: <String, Object?>{
          'count': voices.length,
          'sample': voices.take(5).join(', '),
        },
      );
      return voices;
    } catch (error, stackTrace) {
      _log.e(
        'app_state',
        'fetch local voices failed',
        error: error,
        stackTrace: stackTrace,
      );
      return const <String>[];
    }
  }

  Future<int> getApiTtsCacheSizeBytes() async {
    try {
      return await _playback.getApiTtsCacheSizeBytes();
    } catch (error, stackTrace) {
      _log.e(
        'app_state',
        'get api tts cache size failed',
        error: error,
        stackTrace: stackTrace,
      );
      return 0;
    }
  }

  Future<void> clearApiTtsCache() async {
    try {
      await _playback.clearApiTtsCache();
    } catch (error, stackTrace) {
      _log.e(
        'app_state',
        'clear api tts cache failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<AsrResult> transcribeRecording(
    String audioPath, {
    String? expectedText,
    AsrProviderType? provider,
    AsrProgressCallback? onProgress,
  }) {
    final config = provider == null
        ? _config.asr
        : _config.asr.copyWith(provider: provider);
    return _asr.transcribeFile(
      audioPath: audioPath,
      config: config,
      expectedText: expectedText,
      ttsConfig: _config.tts,
      onProgress: onProgress,
    );
  }

  Future<String?> startAsrRecording({AsrProviderType? provider}) {
    final selected = provider ?? _config.asr.provider;
    final recordingProvider = selected == AsrProviderType.multiEngine
        ? _config.asr.normalizedEngineOrder.first
        : selected;
    return _asr.startRecording(provider: recordingProvider);
  }

  Future<String?> stopAsrRecording() {
    return _asr.stopRecording();
  }

  Future<void> cancelAsrRecording() => _asr.cancelRecording();

  void stopAsrProcessing() => _asr.stopOfflineRecognition();

  Future<String?> startVoiceInputRecording({bool forceRecorder = false}) {
    if (_config.voiceInput.usesSystemSpeech && !forceRecorder) {
      return Future<String?>.value(null);
    }
    return _asr.startRecording(provider: _config.voiceInput.recordingProvider);
  }

  Future<String?> stopVoiceInputRecording() => _asr.stopRecording();

  Future<void> cancelVoiceInputRecording() => _asr.cancelRecording();

  void stopVoiceInputProcessing() => _asr.stopOfflineRecognition();

  Future<AsrResult> transcribeVoiceInputRecording(
    String audioPath, {
    AsrProgressCallback? onProgress,
  }) {
    return _asr.transcribeFile(
      audioPath: audioPath,
      config: _config.voiceInput.toAsrConfig(fallback: _config.asr),
      ttsConfig: _config.tts,
      onProgress: onProgress,
    );
  }

  Future<AsrOfflineModelStatus> getVoiceInputOfflineModelStatus() {
    return _asr.getOfflineModelStatus(AsrProviderType.offline);
  }

  Future<void> prepareVoiceInputOfflineModel({
    AsrProgressCallback? onProgress,
  }) async {
    await _asr.prepareOfflineModel(
      provider: AsrProviderType.offline,
      language: _config.voiceInput.language,
      onProgress: onProgress,
    );
  }

  Future<void> removeVoiceInputOfflineModel() async {
    await _asr.removeOfflineModel(AsrProviderType.offline);
  }

  Future<AsrOfflineModelStatus> getAsrOfflineModelStatus(
    AsrProviderType provider,
  ) {
    return _asr.getOfflineModelStatus(provider);
  }

  Future<void> prepareAsrOfflineModel(
    AsrProviderType provider, {
    AsrProgressCallback? onProgress,
  }) async {
    await _asr.prepareOfflineModel(
      provider: provider,
      language: _config.asr.language,
      onProgress: onProgress,
    );
  }

  Future<void> removeAsrOfflineModel(AsrProviderType provider) async {
    await _asr.removeOfflineModel(provider);
  }

  Future<PronScoringPackStatus> getPronScoringPackStatus(
    PronScoringMethod method,
  ) {
    return _asr.getPronScoringPackStatus(method);
  }

  Future<void> preparePronScoringPack(
    PronScoringMethod method, {
    AsrProgressCallback? onProgress,
  }) async {
    await _asr.preparePronScoringPack(method: method, onProgress: onProgress);
  }

  Future<void> removePronScoringPack(PronScoringMethod method) async {
    await _asr.removePronScoringPack(method);
  }

  PronunciationComparison comparePronunciation(
    String expected,
    String recognized,
  ) {
    return comparePronunciationTexts(
      expected: expected,
      recognized: recognized,
    );
  }

  static final List<MapEntry<RegExp, String>> _latinFoldRules =
      <MapEntry<RegExp, String>>[
        MapEntry(RegExp(r'[áàâãäåāăą]'), 'a'),
        MapEntry(RegExp(r'[çćčĉċ]'), 'c'),
        MapEntry(RegExp(r'[ďđ]'), 'd'),
        MapEntry(RegExp(r'[éèêëēĕėęě]'), 'e'),
        MapEntry(RegExp(r'[íìîïīĭįı]'), 'i'),
        MapEntry(RegExp(r'[ñńňņŋ]'), 'n'),
        MapEntry(RegExp(r'[óòôõöøōŏő]'), 'o'),
        MapEntry(RegExp(r'[úùûüũūŭůűų]'), 'u'),
        MapEntry(RegExp(r'[ýÿŷ]'), 'y'),
        MapEntry(RegExp(r'[ß]'), 'ss'),
        MapEntry(RegExp(r'[æ]'), 'ae'),
        MapEntry(RegExp(r'[œ]'), 'oe'),
        MapEntry(RegExp(r'[脿谩芒茫盲氓膩膬膮]'), 'a'),
        MapEntry(RegExp(r'[莽膰膷]'), 'c'),
        MapEntry(RegExp(r'[膹膽]'), 'd'),
        MapEntry(RegExp(r'[猫茅锚毛膿臅臈臋臎脡]'), 'e'),
        MapEntry(RegExp(r'[茠]'), 'f'),
        MapEntry(RegExp(r'[臐臒摹模]'), 'g'),
        MapEntry(RegExp(r'[磨魔]'), 'h'),
        MapEntry(RegExp(r'[矛铆卯茂末墨沫寞谋]'), 'i'),
        MapEntry(RegExp(r'[牡]'), 'j'),
        MapEntry(RegExp(r'[姆]'), 'k'),
        MapEntry(RegExp(r'[暮募木艂]'), 'l'),
        MapEntry(RegExp(r'[帽艅艈艌]'), 'n'),
        MapEntry(RegExp(r'[貌贸么玫枚酶艒艔艖]'), 'o'),
        MapEntry(RegExp(r'[艜艞艡]'), 'r'),
        MapEntry(RegExp(r'[艣艥艧拧]'), 's'),
        MapEntry(RegExp(r'[牛钮脓]'), 't'),
        MapEntry(RegExp(r'[霉煤没眉农奴怒暖疟懦]'), 'u'),
        MapEntry(RegExp(r'[诺]'), 'w'),
        MapEntry(RegExp(r'[媒每欧]'), 'y'),
        MapEntry(RegExp(r'[藕偶啪]'), 'z'),
        MapEntry(RegExp(r'[脽]'), 'ss'),
        MapEntry(RegExp(r'[忙]'), 'ae'),
        MapEntry(RegExp(r'[艙]'), 'oe'),
      ];

  static final List<MapEntry<RegExp, String>> _pronunciationReplacements =
      <MapEntry<RegExp, String>>[
        MapEntry(RegExp(r"\bcan't\b"), 'cannot'),
        MapEntry(RegExp(r"\bwon't\b"), 'will not'),
        MapEntry(RegExp(r"\bi'm\b"), 'i am'),
        MapEntry(RegExp(r"\bit's\b"), 'it is'),
        MapEntry(RegExp(r"\bthey're\b"), 'they are'),
        MapEntry(RegExp(r"\bwe're\b"), 'we are'),
        MapEntry(RegExp(r"\byou're\b"), 'you are'),
        MapEntry(RegExp(r"\bgonna\b"), 'going to'),
        MapEntry(RegExp(r"\bwanna\b"), 'want to'),
        MapEntry(RegExp(r"\bkinda\b"), 'kind of'),
        MapEntry(RegExp(r"\bsorta\b"), 'sort of'),
      ];
  static final RegExp _pronunciationTokenCharPattern = RegExp(
    r"[\p{L}\p{N}']",
    unicode: true,
  );
  static const Set<String> _pronunciationFillerTokens = <String>{
    'uh',
    'um',
    'ah',
    'huh',
    'mm',
    'er',
    'hmm',
    '嗯',
    '啊',
    '呃',
    '额',
    '哦',
    '噢',
    '诶',
  };

  @visibleForTesting
  static List<WordEntry> filterWords({
    required List<WordEntry> words,
    required String query,
    required SearchMode mode,
  }) {
    final normalizedQuery = search_text.normalizeSearchText(query);
    if (normalizedQuery.isEmpty) return words;
    final fuzzyPattern = search_text.buildFuzzyPattern(normalizedQuery);

    return words
        .where((word) {
          final wordText = search_text.normalizeSearchText(word.word);
          final meaningText = search_text.normalizeSearchText(
            word.meaning ?? '',
          );
          final detailsText = search_text.normalizeSearchText(word.rawContent);
          final compactWordText = wordText.replaceAll(' ', '');
          final compactDetailsText = detailsText.replaceAll(' ', '');

          switch (mode) {
            case SearchMode.word:
              return wordText.contains(normalizedQuery);
            case SearchMode.meaning:
              return meaningText.contains(normalizedQuery) ||
                  detailsText.contains(normalizedQuery);
            case SearchMode.fuzzy:
              if (fuzzyPattern == null) return false;
              return fuzzyPattern.hasMatch(compactWordText) ||
                  fuzzyPattern.hasMatch(compactDetailsText);
            case SearchMode.all:
              return wordText.contains(normalizedQuery) ||
                  meaningText.contains(normalizedQuery) ||
                  detailsText.contains(normalizedQuery);
          }
        })
        .toList(growable: false);
  }

  @visibleForTesting
  static int findJumpIndexByInitial(
    List<WordEntry> scopedWords,
    String initial,
  ) {
    final normalized = initial.trim().toUpperCase();
    if (normalized.isEmpty) return -1;
    return scopedWords.indexWhere(
      (entry) => search_text.wordInitialBucket(entry.word) == normalized,
    );
  }

  @visibleForTesting
  static int findJumpIndexByPrefix(List<WordEntry> scopedWords, String prefix) {
    final normalizedPrefix = search_text.normalizeJumpText(prefix);
    if (normalizedPrefix.isEmpty) return -1;
    return scopedWords.indexWhere(
      (entry) => search_text
          .normalizeJumpText(entry.word)
          .startsWith(normalizedPrefix),
    );
  }

  @visibleForTesting
  static PronunciationComparison comparePronunciationTexts({
    required String expected,
    required String recognized,
  }) {
    final expectedWords = _normalizePronunciationText(expected);
    final recognizedWords = _normalizePronunciationText(recognized);
    final expectedChars = expectedWords.join('');
    final recognizedChars = recognizedWords.join('');

    if (expectedWords.isEmpty && recognizedWords.isEmpty) {
      return const PronunciationComparison(
        isCorrect: false,
        similarity: 0,
        differences: <String>[],
      );
    }

    final tokenDistance = _weightedTokenDistance(
      expectedWords,
      recognizedWords,
    );
    final tokenDenominator = math
        .max(expectedWords.length, recognizedWords.length)
        .toDouble();
    final tokenSimilarity = tokenDenominator == 0
        ? 0.0
        : (1 - tokenDistance / tokenDenominator).clamp(0.0, 1.0);

    final charDistance = _levenshteinDistance(
      expectedChars.split(''),
      recognizedChars.split(''),
    );
    final charDenominator = math.max(
      expectedChars.length,
      recognizedChars.length,
    );
    final charSimilarity = charDenominator == 0
        ? 0.0
        : (1 - charDistance / charDenominator).clamp(0.0, 1.0);

    final similarity = (tokenSimilarity * 0.7 + charSimilarity * 0.3).clamp(
      0.0,
      1.0,
    );
    final tokenCount = math.max(expectedWords.length, recognizedWords.length);
    final minSimilarity = tokenCount <= 2
        ? 0.9
        : (tokenCount <= 4 ? 0.86 : 0.82);
    final minTokenSimilarity = tokenCount <= 2
        ? 0.86
        : (tokenCount <= 4 ? 0.82 : 0.78);
    final differences = _buildPronunciationDifferences(
      expectedWords,
      recognizedWords,
    );

    return PronunciationComparison(
      isCorrect:
          similarity >= minSimilarity && tokenSimilarity >= minTokenSimilarity,
      similarity: similarity,
      differences: differences,
    );
  }

  static String _foldLatinDiacritics(String text) {
    var output = text;
    for (final rule in _latinFoldRules) {
      output = output.replaceAll(rule.key, rule.value);
    }
    return output;
  }

  static List<String> _normalizePronunciationText(String text) {
    var normalized = _foldLatinDiacritics(
      text.toLowerCase().replaceAll(RegExp(r"[’`´]"), "'"),
    );
    for (final replacement in _pronunciationReplacements) {
      normalized = normalized.replaceAll(replacement.key, replacement.value);
    }
    normalized = normalized
        .replaceAll(RegExp(r"[^\p{L}\p{N}\s']", unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return const <String>[];

    return _tokenizePronunciation(normalized)
        .map(_normalizePronunciationToken)
        .where((item) => item.isNotEmpty && !_isFillerPronunciationToken(item))
        .toList(growable: false);
  }

  static List<String> _tokenizePronunciation(String text) {
    final tokens = <String>[];
    final buffer = StringBuffer();

    void flushBuffer() {
      if (buffer.isEmpty) return;
      tokens.add(buffer.toString());
      buffer.clear();
    }

    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      if (_isCjkLikeCodePoint(rune)) {
        flushBuffer();
        tokens.add(char);
        continue;
      }
      if (_pronunciationTokenCharPattern.hasMatch(char)) {
        buffer.write(char);
        continue;
      }
      flushBuffer();
    }

    flushBuffer();
    return tokens;
  }

  static bool _isFillerPronunciationToken(String token) {
    return _pronunciationFillerTokens.contains(token);
  }

  static bool _isCjkLikeCodePoint(int rune) {
    return (rune >= 0x4E00 && rune <= 0x9FFF) ||
        (rune >= 0x3400 && rune <= 0x4DBF) ||
        (rune >= 0x3040 && rune <= 0x309F) ||
        (rune >= 0x30A0 && rune <= 0x30FF) ||
        (rune >= 0xAC00 && rune <= 0xD7AF) ||
        (rune >= 0x1100 && rune <= 0x11FF);
  }

  static String _normalizePronunciationToken(String token) {
    var text = token.trim();
    if (text.isEmpty) return '';
    text = text.replaceAll(RegExp(r"^'+|'+$"), '');
    if (text.isEmpty) return '';

    if (text.endsWith("'s") && text.length > 3) {
      text = text.substring(0, text.length - 2);
    }
    if (text.endsWith('ies') && text.length > 4) {
      return '${text.substring(0, text.length - 3)}y';
    }
    if (text.endsWith('ing') && text.length > 5) {
      var stem = text.substring(0, text.length - 3);
      if (stem.length >= 2 && stem[stem.length - 1] == stem[stem.length - 2]) {
        stem = stem.substring(0, stem.length - 1);
      }
      return stem;
    }
    if (text.endsWith('ed') && text.length > 4) {
      var stem = text.substring(0, text.length - 2);
      if (stem.endsWith('i') && stem.length > 2) {
        stem = '${stem.substring(0, stem.length - 1)}y';
      }
      return stem;
    }
    if (text.endsWith('es') && text.length > 4) {
      return text.substring(0, text.length - 2);
    }
    if (text.endsWith('s') && text.length > 3 && !text.endsWith('ss')) {
      return text.substring(0, text.length - 1);
    }
    return text;
  }

  static int _levenshteinDistance(List<String> left, List<String> right) {
    final rows = left.length + 1;
    final cols = right.length + 1;
    final matrix = List<List<int>>.generate(
      rows,
      (_) => List<int>.filled(cols, 0),
      growable: false,
    );

    for (var i = 0; i < rows; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j < cols; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i < rows; i++) {
      for (var j = 1; j < cols; j++) {
        final cost = left[i - 1] == right[j - 1] ? 0 : 1;
        final deletion = matrix[i - 1][j] + 1;
        final insertion = matrix[i][j - 1] + 1;
        final substitution = matrix[i - 1][j - 1] + cost;
        matrix[i][j] = deletion < insertion
            ? (deletion < substitution ? deletion : substitution)
            : (insertion < substitution ? insertion : substitution);
      }
    }

    return matrix[rows - 1][cols - 1];
  }

  static double _weightedTokenDistance(List<String> left, List<String> right) {
    final rows = left.length + 1;
    final cols = right.length + 1;
    final matrix = List<List<double>>.generate(
      rows,
      (_) => List<double>.filled(cols, 0),
      growable: false,
    );

    for (var i = 0; i < rows; i++) {
      matrix[i][0] = i.toDouble();
    }
    for (var j = 0; j < cols; j++) {
      matrix[0][j] = j.toDouble();
    }

    for (var i = 1; i < rows; i++) {
      for (var j = 1; j < cols; j++) {
        final substitutionCost =
            1 - _tokenSimilarity(left[i - 1], right[j - 1]);
        final deletion = matrix[i - 1][j] + 1;
        final insertion = matrix[i][j - 1] + 1;
        final substitution = matrix[i - 1][j - 1] + substitutionCost;
        matrix[i][j] = math.min(deletion, math.min(insertion, substitution));
      }
    }

    return matrix[rows - 1][cols - 1];
  }

  static double _tokenSimilarity(String left, String right) {
    if (left == right) return 1;
    if (left.isEmpty || right.isEmpty) return 0;
    final charDistance = _levenshteinDistance(left.split(''), right.split(''));
    final denominator = math.max(left.length, right.length);
    if (denominator == 0) return 1;
    return (1 - charDistance / denominator).clamp(0.0, 1.0);
  }

  static List<String> _buildPronunciationDifferences(
    List<String> expectedWords,
    List<String> recognizedWords,
  ) {
    final rows = expectedWords.length + 1;
    final cols = recognizedWords.length + 1;
    final matrix = List<List<int>>.generate(
      rows,
      (_) => List<int>.filled(cols, 0),
      growable: false,
    );

    for (var i = 0; i < rows; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j < cols; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i < rows; i++) {
      for (var j = 1; j < cols; j++) {
        final similarity = _tokenSimilarity(
          expectedWords[i - 1],
          recognizedWords[j - 1],
        );
        final cost = similarity >= 0.92 ? 0 : 1;
        final deletion = matrix[i - 1][j] + 1;
        final insertion = matrix[i][j - 1] + 1;
        final substitution = matrix[i - 1][j - 1] + cost;
        matrix[i][j] = deletion < insertion
            ? (deletion < substitution ? deletion : substitution)
            : (insertion < substitution ? insertion : substitution);
      }
    }

    final differences = <String>[];
    var i = expectedWords.length;
    var j = recognizedWords.length;
    while (i > 0 || j > 0) {
      if (i > 0 &&
          j > 0 &&
          expectedWords[i - 1] == recognizedWords[j - 1] &&
          matrix[i][j] == matrix[i - 1][j - 1]) {
        i -= 1;
        j -= 1;
        continue;
      }

      if (i > 0 && j > 0 && matrix[i][j] == matrix[i - 1][j - 1] + 1) {
        differences.add(
          'replace::${expectedWords[i - 1]}::${recognizedWords[j - 1]}',
        );
        i -= 1;
        j -= 1;
        continue;
      }

      if (i > 0 && matrix[i][j] == matrix[i - 1][j] + 1) {
        differences.add('missing::${expectedWords[i - 1]}');
        i -= 1;
        continue;
      }

      if (j > 0 && matrix[i][j] == matrix[i][j - 1] + 1) {
        differences.add('extra::${recognizedWords[j - 1]}');
        j -= 1;
        continue;
      }

      if (i > 0) {
        differences.add('missing::${expectedWords[i - 1]}');
        i -= 1;
      } else if (j > 0) {
        differences.add('extra::${recognizedWords[j - 1]}');
        j -= 1;
      }
    }

    return differences.reversed.take(12).toList(growable: false);
  }

  Future<void> _reloadWordbooks({required bool keepCurrentSelection}) async {
    final selectedId = keepCurrentSelection ? _selectedWordbook?.id : null;
    _wordbooks = _database
        .getWordbooks()
        .map(_withLocalizedBuiltinName)
        .toList(growable: false);

    Wordbook? nextSelection;
    if (selectedId != null) {
      nextSelection = _wordbooks
          .where((book) => book.id == selectedId)
          .cast<Wordbook?>()
          .firstOrNull;
    }
    nextSelection ??= _wordbooks
        .where((book) => !book.isSpecial && book.wordCount > 0)
        .cast<Wordbook?>()
        .firstOrNull;
    nextSelection ??= _wordbooks.isEmpty ? null : _wordbooks.first;
    _selectedWordbook = nextSelection;

    if (_selectedWordbook != null) {
      _setWords(_database.getWords(_selectedWordbook!.id));
      final restoredIndex = _playbackProgressIndexForWordbook(
        _selectedWordbook!,
      );
      if (restoredIndex >= 0) {
        final target = (_searchQuery.trim().isEmpty
            ? _words
            : _scopeWords)[restoredIndex];
        _setCurrentWordByEntry(target);
      } else if (_currentWordIndex >= _words.length) {
        _currentWordIndex = _words.isEmpty ? 0 : (_words.length - 1);
      }
      _ensureCurrentWordInScope();
    } else {
      _setWords(<WordEntry>[]);
      _currentWordIndex = 0;
    }
    notifyListeners();
  }

  void _setWords(List<WordEntry> nextWords) {
    _words = nextWords;
    _refreshWordMemoryProgressCache(nextWords);
    _wordsVersion += 1;
    _invalidateVisibleWordsCache();
  }

  void _invalidateVisibleWordsCache() {
    _visibleWordsCache = null;
    _visibleWordsCacheVersion = -1;
    _visibleWordsCacheQuery = '';
    _visibleWordsCacheMode = SearchMode.all;
  }

  Future<void> _syncSpecialWordbooks() async {
    final favoritesBook = _wordbooks
        .where((item) => item.path == 'builtin:favorites')
        .cast<Wordbook?>()
        .firstOrNull;
    if (favoritesBook != null) {
      _favorites = _database
          .getWords(favoritesBook.id)
          .map((item) => item.word)
          .toSet();
      _persistSpecialWordSet('favorites', _favorites);
    } else {
      _favorites = <String>{};
    }

    final taskBook = _wordbooks
        .where((item) => item.path == 'builtin:task')
        .cast<Wordbook?>()
        .firstOrNull;
    if (taskBook != null) {
      _taskWords = _database
          .getWords(taskBook.id)
          .map((item) => item.word)
          .toSet();
      _persistSpecialWordSet('taskWords', _taskWords);
    } else {
      _taskWords = <String>{};
    }
    notifyListeners();
  }

  void _persistSpecialWordSet(String settingKey, Set<String> values) {
    _database.setSetting(
      settingKey,
      jsonEncode(values.toList(growable: false)),
    );
  }

  void _updateWordbookCount(String path, int delta) {
    if (delta == 0 || _wordbooks.isEmpty) return;
    _wordbooks = _wordbooks
        .map((item) {
          if (item.path != path) return item;
          final updated = Wordbook(
            id: item.id,
            name: item.name,
            path: item.path,
            wordCount: math.max(0, item.wordCount + delta),
            createdAt: item.createdAt,
          );
          if (_selectedWordbook?.id == item.id) {
            _selectedWordbook = updated;
          }
          return updated;
        })
        .toList(growable: false);
  }

  void _refreshSelectedSpecialWordbook(
    Wordbook specialWordbook, {
    WordEntry? optimisticWord,
    bool? optimisticAdded,
  }) {
    if (_selectedWordbook?.id != specialWordbook.id) return;

    if (optimisticWord != null && optimisticAdded != null) {
      final nextWords = List<WordEntry>.from(_words);
      if (optimisticAdded) {
        final alreadyExists = nextWords.any(
          (item) => item.word == optimisticWord.word,
        );
        if (!alreadyExists) {
          nextWords.insert(
            0,
            optimisticWord.copyWith(wordbookId: specialWordbook.id),
          );
        }
      } else {
        nextWords.removeWhere((item) => item.word == optimisticWord.word);
      }
      _setWords(nextWords);
    } else {
      _setWords(_database.getWords(specialWordbook.id));
    }

    if (_currentWordIndex >= _words.length) {
      _currentWordIndex = _words.isEmpty ? 0 : (_words.length - 1);
    }
    _ensureCurrentWordInScope();
  }

  void _restoreWordbookSnapshot({
    required List<Wordbook> wordbooks,
    required Wordbook? selectedWordbook,
    required List<WordEntry> words,
    required int currentWordIndex,
  }) {
    _wordbooks = wordbooks;
    _selectedWordbook = selectedWordbook;
    _setWords(words);
    _currentWordIndex = currentWordIndex;
    if (_currentWordIndex >= _words.length) {
      _currentWordIndex = _words.isEmpty ? 0 : (_words.length - 1);
    }
    _ensureCurrentWordInScope();
  }

  List<WordEntry> get _scopeWords {
    return visibleWords;
  }

  void _setCurrentWordByEntry(WordEntry entry) {
    final index = _indexOfWordEntry(_words, entry);
    if (index >= 0) {
      _currentWordIndex = index;
      return;
    }
    // Fallback for legacy records without stable ids/content.
    final fallback = _words.indexWhere((item) => item.word == entry.word);
    if (fallback >= 0) {
      _currentWordIndex = fallback;
    }
  }

  void _ensureCurrentWordInScope() {
    if (_words.isEmpty) {
      _currentWordIndex = 0;
      return;
    }
    if (_currentWordIndex < 0 || _currentWordIndex >= _words.length) {
      _currentWordIndex = 0;
    }

    final scoped = _scopeWords;
    if (scoped.isEmpty) return;

    final currentEntry = _words[_currentWordIndex];
    final inScope = scoped.any((item) => _isSameWordEntry(item, currentEntry));
    if (inScope) return;
    _setCurrentWordByEntry(scoped.first);
  }

  int _indexOfWordEntry(List<WordEntry> entries, WordEntry target) {
    for (var i = 0; i < entries.length; i += 1) {
      if (_isSameWordEntry(entries[i], target)) {
        return i;
      }
    }
    return -1;
  }

  bool _isSameWordEntry(WordEntry a, WordEntry b) {
    if (identical(a, b)) return true;
    final aId = a.id;
    final bId = b.id;
    if (aId != null && bId != null) {
      return aId == bId;
    }
    if (a.wordbookId != b.wordbookId) return false;
    final sameWord = a.word.trim() == b.word.trim();
    if (!sameWord) return false;
    final aRaw = a.rawContent.trim();
    final bRaw = b.rawContent.trim();
    if (aRaw.isNotEmpty || bRaw.isNotEmpty) {
      return aRaw == bRaw;
    }
    return true;
  }

  Wordbook? _resolveWordbookForEntry(WordEntry entry) {
    return _wordbooks
            .where((item) => item.id == entry.wordbookId)
            .cast<Wordbook?>()
            .firstOrNull ??
        (_selectedWordbook?.id == entry.wordbookId ? _selectedWordbook : null);
  }

  void _persistPlaybackProgress() {
    _settings.savePlaybackProgressByWordbook(_playbackProgressByWordbookPath);
  }

  void _rememberPlaybackProgressImpl([WordEntry? entry]) {
    final resolvedEntry = entry ?? currentWord;
    if (resolvedEntry == null) {
      return;
    }
    final wordbook = _resolveWordbookForEntry(resolvedEntry);
    final path = wordbook?.path.trim() ?? '';
    if (path.isEmpty) {
      return;
    }
    final previous = _playbackProgressByWordbookPath[path];
    if (previous != null &&
        previous.wordId == resolvedEntry.id &&
        previous.word == resolvedEntry.word) {
      return;
    }
    _playbackProgressByWordbookPath = <String, PlaybackProgressSnapshot>{
      ..._playbackProgressByWordbookPath,
      path: PlaybackProgressSnapshot(
        wordbookPath: path,
        wordId: resolvedEntry.id,
        word: resolvedEntry.word,
        updatedAt: DateTime.now(),
      ),
    };
    _persistPlaybackProgress();
  }

  int _playbackProgressIndexForWordbook(Wordbook wordbook) {
    final snapshot = _playbackProgressByWordbookPath[wordbook.path.trim()];
    if (snapshot == null) {
      return -1;
    }
    final scoped = _scopeWords;
    final entries = _searchQuery.trim().isEmpty ? _words : scoped;
    if (entries.isEmpty) {
      return -1;
    }
    final byId = snapshot.wordId;
    if (byId != null) {
      final index = entries.indexWhere((item) => item.id == byId);
      if (index >= 0) {
        return index;
      }
    }
    return entries.indexWhere((item) => item.word == snapshot.word);
  }

  bool _restorePlaybackProgressForSelectedWordbookImpl() {
    if (_isPlaying) {
      return false;
    }
    final selectedWordbook = _selectedWordbook;
    if (selectedWordbook == null || _words.isEmpty) {
      return false;
    }
    final index = _playbackProgressIndexForWordbook(selectedWordbook);
    if (index < 0) {
      return false;
    }
    final target = (_searchQuery.trim().isEmpty ? _words : _scopeWords)[index];
    final current = currentWord;
    if (current != null && _isSameWordEntry(current, target)) {
      return false;
    }
    _setCurrentWordByEntry(target);
    resetTestModeProgress();
    _notifyStateChanged();
    return true;
  }

  Future<void> _createSafetyBackup({required String reason}) async {
    try {
      _lastBackupPath = await _database.createSafetyBackup(reason: reason);
    } catch (_) {
      _lastBackupPath = null;
    }
  }

  Future<void> _reloadPersistentStateAfterDatabaseChange() async {
    _config = _settings.loadPlayConfig();
    _playback.updateRuntimeConfig(_config);

    final languageSetting = _settings.loadUiLanguage();
    if (languageSetting == SettingsService.uiLanguageSystem) {
      _uiLanguageFollowsSystem = true;
      _uiLanguage = _resolveSystemUiLanguage();
    } else {
      _uiLanguageFollowsSystem = false;
      _uiLanguage = AppI18n.normalizeLanguageCode(languageSetting);
    }
    _startupPage = _settings.loadStartupPage();
    _focusStartupTab = _settings.loadFocusStartupTab();
    _weatherEnabled = _settings.loadWeatherEnabled();
    _startupTodoPromptEnabled = _settings.loadStartupTodoPromptEnabled();
    _startupTodoPromptSuppressedDate = _settings
        .loadStartupTodoPromptSuppressedDate();
    _rememberedWords = _settings.loadRememberedWords();
    _playbackProgressByWordbookPath = _settings
        .loadPlaybackProgressByWordbook();

    final testModeState = _settings.loadTestModeState();
    _testModeEnabled = testModeState.enabled;
    _testModeRevealed = testModeState.revealed;
    _testModeHintRevealed = testModeState.hintRevealed;

    _practiceDateKey = '';
    _practiceTodaySessions = 0;
    _practiceTodayReviewed = 0;
    _practiceTodayRemembered = 0;
    _practiceTotalSessions = 0;
    _practiceTotalReviewed = 0;
    _practiceTotalRemembered = 0;
    _practiceLastSessionTitle = '';
    _practiceRememberedWords = <String>[];
    _practiceWeakWords = <String>[];
    _practiceWeakWordReasons = <String, List<String>>{};
    _practiceSessionHistory = <PracticeSessionRecord>[];
    _practiceLaunchCursors = <String, int>{};
    _practiceAutoAddWeakWordsToTask = false;
    _practiceAutoPlayPronunciation = false;
    _practiceShowHintsByDefault = false;
    _practiceShowAnswerFeedbackDialog = true;
    _practiceDefaultQuestionType = PracticeQuestionType.flashcard;
    _practiceRoundSettings = PracticeRoundSettings.defaults;

    _searchQuery = '';
    _searchMode = SearchMode.all;
    _invalidateVisibleWordsCache();
    _loadPracticeDashboard();
    _ensurePracticeDate(persist: true);
    await _focusService.init();
    await _reloadWordbooks(keepCurrentSelection: false);
    await _syncSpecialWordbooks();
    _refreshLocalizedWordbookNames();
    if (_weatherEnabled) {
      unawaited(refreshWeather(force: true));
    }
  }

  void _persistTestModeState() {
    _settings.saveTestModeState(
      TestModeState(
        enabled: _testModeEnabled,
        revealed: _testModeRevealed,
        hintRevealed: _testModeHintRevealed,
      ),
    );
  }

  void _setMessage(
    String key, {
    Map<String, Object?> params = const <String, Object?>{},
  }) {
    _message = key;
    _messageParams = params;
    _log.w(
      'app_state',
      'message set',
      data: <String, Object?>{'key': key, 'params': params.toString()},
    );
  }

  void _setBusy(
    bool value, {
    String? messageKey,
    Map<String, Object?> params = const <String, Object?>{},
  }) {
    _busy = value;
    if (value) {
      _busyMessageKey = messageKey;
      _busyMessageParams = params;
    } else {
      _busyMessageKey = null;
      _busyMessageParams = const <String, Object?>{};
    }
    notifyListeners();
  }

  void _notifyStateChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _log.i('app_state', 'dispose start');
    WidgetsBinding.instance.removeObserver(this);
    _playback.stop();
    _focusService.dispose();
    _ambient.stopAll();
    _asr.dispose();
    _database.dispose();
    _log.i('app_state', 'dispose done');
    super.dispose();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}

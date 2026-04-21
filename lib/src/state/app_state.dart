import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../core/module_system/module_system.dart';
import '../i18n/app_i18n.dart';
import '../models/ambient_preset.dart';
import '../models/app_home_tab.dart';
import '../models/focus_startup_tab.dart';
import '../models/export_dto.dart';
import '../models/play_config.dart';
import '../models/practice_export_format.dart';
import '../models/practice_question_type.dart';
import '../models/practice_session_record.dart';
import '../models/settings_dto.dart';
import '../models/sleep_daily_log.dart';
import '../models/sleep_plan.dart';
import '../models/sleep_profile.dart';
import '../models/sleep_routine_template.dart';
import '../models/study_startup_tab.dart';
import '../models/todo_item.dart';
import '../models/user_data_export.dart';
import '../models/weather_snapshot.dart';
import '../models/word_entry.dart';
import '../models/word_field.dart';
import '../models/word_memory_progress.dart';
import '../models/wordbook.dart';
import '../repositories/repositories.dart';
import '../services/ambient_service.dart';
import '../services/app_log_service.dart';
import '../services/asr_service.dart';
import '../services/database_service.dart';
import '../services/daily_quote_service.dart';
import '../services/cstcloud_resource_prewarm_service.dart';
import '../services/cstcloud_resource_cache_service.dart';
import '../services/focus_service.dart';
import '../services/memory_algorithm.dart';
import '../services/memory_lane_selector.dart';
import '../services/online_ambient_catalog_service.dart';
import '../services/playback_service.dart';
import '../services/settings_service.dart';
import '../services/weather_service.dart';
import 'weather_store.dart';
import 'test_mode_store.dart';
import 'startup_store.dart';
import '../utils/search_text_normalizer.dart' as search_text;

part 'app_state_practice.dart';
part 'app_state_playback.dart';
part 'app_state_startup.dart';
part 'app_state_sleep.dart';
part 'app_state_wordbook.dart';
part 'app_state_ambient.dart';
part 'app_state_asr.dart';
part 'app_state_weather.dart';
part 'app_state_export.dart';

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
  static const int _startupEagerWordLoadLimit = 1500;

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
    required AsrServiceContract asr,
    required FocusService focusService,
    MaintenanceRepository? maintenanceRepository,
    WordbookRepository? wordbookRepository,
    PracticeRepository? practiceRepository,
    AmbientRepository? ambientRepository,
    SleepRepository? sleepRepository,
    CstCloudResourcePrewarmService? remoteResourcePrewarm,
    WeatherService? weatherService,
    WeatherStore? weatherStore,
    TestModeStore? testModeStore,
    StartupStore? startupStore,
    DailyQuoteService? dailyQuoteService,
  }) : _maintenanceRepository =
           maintenanceRepository ?? DatabaseMaintenanceRepository(database),
       _wordbookRepository =
           wordbookRepository ?? DatabaseWordbookRepository(database),
       _practiceRepository =
           practiceRepository ?? DatabasePracticeRepository(database),
       _ambientRepository =
           ambientRepository ?? DatabaseAmbientRepository(database),
       _sleepRepository =
           sleepRepository ??
           SettingsStoreSleepRepository(
             DatabaseSettingsStoreRepository(database),
           ),
       _settings = settings,
       _playback = playback,
       _ambient = ambient,
       _asr = asr,
       _focusService = focusService,
       _remoteResourcePrewarm = remoteResourcePrewarm,
       _weatherService = weatherService ?? WeatherService(),
       _dailyQuoteService = dailyQuoteService ?? DailyQuoteService() {
    _weatherStore =
        weatherStore ??
        WeatherStore(
          settings: settings,
          weatherService: _weatherService,
          log: _log,
        );
    _ownsWeatherStore = weatherStore == null;
    _weatherStore.addListener(_onWeatherStoreChanged);
    _testModeStore = testModeStore ?? TestModeStore(settings: settings);
    _ownsTestModeStore = testModeStore == null;
    _testModeStore.addListener(_onTestModeStoreChanged);
    _startupStore = startupStore ?? StartupStore(settings: settings);
    _ownsStartupStore = startupStore == null;
    _startupStore.addListener(_onStartupStoreChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  final MaintenanceRepository _maintenanceRepository;
  final WordbookRepository _wordbookRepository;
  final PracticeRepository _practiceRepository;
  final AmbientRepository _ambientRepository;
  final SleepRepository _sleepRepository;
  final SettingsService _settings;
  final PlaybackService _playback;
  final AmbientService _ambient;
  final AsrServiceContract _asr;
  final FocusService _focusService;
  final CstCloudResourcePrewarmService? _remoteResourcePrewarm;
  final WeatherService _weatherService;
  final DailyQuoteService _dailyQuoteService;
  final AppLogService _log = AppLogService.instance;
  final OnlineAmbientCatalogService _onlineAmbientCatalogService =
      OnlineAmbientCatalogService();
  final Uuid _uuid = const Uuid();
  late final WeatherStore _weatherStore;
  late final bool _ownsWeatherStore;
  late final TestModeStore _testModeStore;
  late final bool _ownsTestModeStore;
  late final StartupStore _startupStore;
  late final bool _ownsStartupStore;

  FocusService get focusService => _focusService;

  bool _initializing = false;
  bool _initialized = false;
  bool _busy = false;
  String? _busyMessageKey;
  Map<String, Object?> _busyMessageParams = const <String, Object?>{};
  String? _busyDetail;
  double? _busyProgress;
  List<AmbientPreset> _ambientPresets = const <AmbientPreset>[];
  bool _wordbookImportActive = false;
  String _wordbookImportName = '';
  int _wordbookImportProcessedEntries = 0;
  int? _wordbookImportTotalEntries;
  String? _message;
  Map<String, Object?> _messageParams = const <String, Object?>{};

  PlayConfig _config = PlayConfig.defaults;
  List<Wordbook> _wordbooks = <Wordbook>[];
  Wordbook? _selectedWordbook;
  List<WordEntry> _words = <WordEntry>[];
  int? _loadedWordbookId;
  int _currentWordIndex = 0;
  WordEntry? _transientCurrentWord;
  String _searchQuery = '';
  SearchMode _searchMode = SearchMode.all;
  Set<String> _favorites = <String>{};
  Set<String> _taskWords = <String>{};
  Set<String> _rememberedWords = <String>{};
  String _uiLanguage = _resolveSystemUiLanguage();
  bool _uiLanguageFollowsSystem = true;
  ModuleToggleState _moduleToggleState = ModuleToggleState.defaults;
  bool _remotePrewarmActive = false;
  bool _remotePrewarmCompleted = false;
  bool _remotePrewarmFailed = false;
  int _remotePrewarmCompletedCount = 0;
  int _remotePrewarmTotalCount = 0;
  String _remotePrewarmCurrentLabel = '';
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
  bool _sleepLoading = false;
  SleepProfile? _sleepProfile;
  SleepPlan? _sleepCurrentPlan;
  SleepDashboardState _sleepDashboardState = const SleepDashboardState();
  SleepAssessmentDraftState _sleepAssessmentDraft =
      const SleepAssessmentDraftState();
  SleepRoutineRunnerState _sleepRoutineRunnerState =
      const SleepRoutineRunnerState();
  SleepNightRescueState _sleepNightRescueState = const SleepNightRescueState();
  List<SleepDailyLog> _sleepDailyLogs = <SleepDailyLog>[];
  List<SleepNightEvent> _sleepNightEvents = <SleepNightEvent>[];
  List<SleepThoughtEntry> _sleepThoughtEntries = <SleepThoughtEntry>[];
  List<SleepRoutineTemplate> _sleepRoutineTemplates = <SleepRoutineTemplate>[];
  SleepProgramProgress? _sleepProgramProgress;

  // Ambient sync debounce to prevent race conditions from rapid state changes
  Timer? _ambientSyncDebounceTimer;

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

  String? get busyDetail => _busy ? _busyDetail : null;
  double? get busyProgress => _busy ? _busyProgress : null;
  bool get wordbookImportActive => _wordbookImportActive;
  String get wordbookImportName => _wordbookImportName;
  int get wordbookImportProcessedEntries => _wordbookImportProcessedEntries;
  int? get wordbookImportTotalEntries => _wordbookImportTotalEntries;
  double? get wordbookImportProgress {
    final total = _wordbookImportTotalEntries;
    if (!_wordbookImportActive || total == null || total <= 0) {
      return null;
    }
    return (_wordbookImportProcessedEntries / total).clamp(0.0, 1.0);
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
  bool get selectedWordbookLoaded =>
      _selectedWordbook != null && _loadedWordbookId == _selectedWordbook!.id;
  bool get selectedWordbookRequiresOnDemandLoad =>
      _selectedWordbook != null &&
      !selectedWordbookLoaded &&
      _selectedWordbook!.wordCount > 0;
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
  bool isFavoriteEntry(WordEntry entry) =>
      _favorites.contains(entry.collectionReferenceKey);
  bool isTaskEntry(WordEntry entry) =>
      _taskWords.contains(entry.collectionReferenceKey);
  String get searchQuery => _searchQuery;
  SearchMode get searchMode => _searchMode;
  String get uiLanguage => _uiLanguage;
  bool get uiLanguageFollowsSystem => _uiLanguageFollowsSystem;
  ModuleToggleState get moduleToggleState => _moduleToggleState;
  AppHomeTab get startupPage => _startupStore.startupPage;
  FocusStartupTab get focusStartupTab => _startupStore.focusStartupTab;
  StudyStartupTab get studyStartupTab => _startupStore.studyStartupTab;
  bool get weatherEnabled => _weatherStore.enabled;
  WeatherSnapshot? get weatherSnapshot => _weatherStore.snapshot;
  bool get weatherLoading => _weatherStore.loading;
  bool get startupTodoPromptEnabled => _startupStore.startupTodoPromptEnabled;
  bool get shouldShowStartupTodoPromptToday =>
      _startupStore.startupTodoPromptEnabled &&
      _startupStore.startupTodoPromptSuppressedDate != _todayDateKey();
  String? get startupDailyQuote =>
      _startupStore.startupDailyQuoteDateKey == _todayDateKey()
      ? _startupStore.startupDailyQuote
      : null;
  bool get startupDailyQuoteLoading => _startupStore.startupDailyQuoteLoading;
  bool get remotePrewarmActive => _remotePrewarmActive;
  bool get remotePrewarmCompleted => _remotePrewarmCompleted;
  bool get remotePrewarmFailed => _remotePrewarmFailed;
  int get remotePrewarmCompletedCount => _remotePrewarmCompletedCount;
  int get remotePrewarmTotalCount => _remotePrewarmTotalCount;
  String get remotePrewarmCurrentLabel => _remotePrewarmCurrentLabel;
  double get remotePrewarmProgress => _remotePrewarmTotalCount <= 0
      ? 0
      : (_remotePrewarmCompletedCount / _remotePrewarmTotalCount).clamp(
          0.0,
          1.0,
        );
  bool get sleepLoading => _sleepLoading;
  SleepProfile? get sleepProfile => _sleepProfile;
  SleepPlan? get sleepCurrentPlan => _sleepCurrentPlan;
  SleepDashboardState get sleepDashboardState => _sleepDashboardState;
  SleepAssessmentDraftState get sleepAssessmentDraft => _sleepAssessmentDraft;
  SleepRoutineRunnerState get sleepRoutineRunnerState =>
      _sleepRoutineRunnerState;
  SleepNightRescueState get sleepNightRescueState => _sleepNightRescueState;
  List<SleepDailyLog> get sleepDailyLogs =>
      List<SleepDailyLog>.unmodifiable(_sleepDailyLogs);
  List<SleepNightEvent> get sleepNightEvents =>
      List<SleepNightEvent>.unmodifiable(_sleepNightEvents);
  List<SleepThoughtEntry> get sleepThoughtEntries =>
      List<SleepThoughtEntry>.unmodifiable(_sleepThoughtEntries);
  List<SleepRoutineTemplate> get sleepRoutineTemplates =>
      List<SleepRoutineTemplate>.unmodifiable(_sleepRoutineTemplates);
  SleepProgramProgress? get sleepProgramProgress => _sleepProgramProgress;
  SleepDailyLog? get latestSleepDailyLog => _sleepDailyLogs.firstOrNull;
  SleepRoutineStep? get currentSleepRoutineStep {
    final template = activeSleepRoutineTemplate;
    final index = _sleepRoutineRunnerState.currentStepIndex;
    if (template == null || index < 0 || index >= template.steps.length) {
      return null;
    }
    return template.steps[index];
  }

  double get sleepRoutineProgress {
    final template = activeSleepRoutineTemplate;
    if (template == null || template.steps.isEmpty) {
      return 0;
    }
    return ((_sleepRoutineRunnerState.currentStepIndex + 1) /
            template.steps.length)
        .clamp(0.0, 1.0);
  }

  SleepRoutineTemplate? get activeSleepRoutineTemplate {
    final activeId = _sleepRoutineRunnerState.activeTemplateId;
    if (activeId != null) {
      for (final template in _sleepRoutineTemplates) {
        if (template.id == activeId) {
          return template;
        }
      }
    }
    return _sleepRoutineTemplates.firstOrNull;
  }

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
  bool get testModeEnabled => _testModeStore.enabled;
  bool get testModeRevealed => _testModeStore.revealed;
  bool get testModeHintRevealed => _testModeStore.hintRevealed;
  String? get lastBackupPath => _lastBackupPath;
  int get practiceTodaySessions => _practiceTodaySessions;
  int get practiceTodayReviewed => _practiceTodayReviewed;
  int get practiceTodayRemembered => _practiceTodayRemembered;
  int get practiceTotalSessions => _practiceTotalSessions;
  int get practiceTotalReviewed => _practiceTotalReviewed;
  int get practiceTotalRemembered => _practiceTotalRemembered;
  String get practiceLastSessionTitle => _practiceLastSessionTitle;
  List<String> get practiceRememberedWords =>
      _practiceDisplayWords(_practiceRememberedWords);
  List<String> get practiceWeakWords =>
      _practiceDisplayWords(_practiceWeakWords);
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
  int? get pendingTodoReminderLaunchId =>
      _startupStore.pendingTodoReminderLaunchId;
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
  List<AmbientPreset> get ambientPresets =>
      List<AmbientPreset>.unmodifiable(_ambientPresets);

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
        : _searchWordbookEntries(
            selectedWordbook,
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
    return false;
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
    final key = _practiceTrackingKeyForEntry(entry);
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
      return selectedWordbookLoaded
          ? _words.length
          : selectedWordbook.wordCount;
    }
    return _wordbookRepository.countSearchWords(
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
      if (!selectedWordbookLoaded) {
        return _queryWordbookEntries(
          selectedWordbook,
          limit: limit,
          offset: offset,
        );
      }
      final start = offset.clamp(0, _words.length).toInt();
      final end = (start + limit).clamp(start, _words.length).toInt();
      return _words.sublist(start, end);
    }
    return _searchWordbookEntries(
      selectedWordbook,
      query: _searchQuery,
      mode: _searchMode.name,
      limit: limit,
      offset: offset,
    );
  }

  List<WordEntry> _queryWordbookEntries(
    Wordbook wordbook, {
    int limit = 100000,
    int offset = 0,
    bool? includeFields,
  }) {
    final resolvedIncludeFields =
        includeFields ?? !_shouldUseLiteWordQueries(wordbook);
    if (resolvedIncludeFields) {
      return _wordbookRepository.getWords(
        wordbook.id,
        limit: limit,
        offset: offset,
      );
    }
    return _wordbookRepository.getWordsLite(
      wordbook.id,
      limit: limit,
      offset: offset,
    );
  }

  List<WordEntry> _searchWordbookEntries(
    Wordbook wordbook, {
    required String query,
    required String mode,
    int limit = 100000,
    int offset = 0,
  }) {
    if (_shouldUseLiteWordQueries(wordbook)) {
      return _wordbookRepository.searchWordsLite(
        wordbook.id,
        query: query,
        mode: mode,
        limit: limit,
        offset: offset,
      );
    }
    return _wordbookRepository.searchWords(
      wordbook.id,
      query: query,
      mode: mode,
      limit: limit,
      offset: offset,
    );
  }

  int? findVisibleWordOffsetByPrefix(String prefix) {
    final selectedWordbook = _selectedWordbook;
    if (selectedWordbook == null) {
      return null;
    }
    return _wordbookRepository.findSearchOffsetByPrefix(
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
    return _wordbookRepository.findSearchOffsetByInitial(
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
    final offset = _wordbookRepository.findSearchOffsetByWordId(
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
    final transient = _transientCurrentWord;
    final searchActive = _searchQuery.trim().isNotEmpty;
    if (transient != null &&
        (_selectedWordbook == null ||
            transient.wordbookId == _selectedWordbook!.id)) {
      if (!searchActive) {
        if (_words.isEmpty || _indexOfWordEntry(_words, transient) < 0) {
          return transient;
        }
      } else if (visibleWords.any(
        (item) => _isSameWordEntry(item, transient),
      )) {
        return transient;
      }
    }
    if (_currentWordIndex < 0 || _currentWordIndex >= _words.length) {
      return _scopeWords.isEmpty ? null : _scopeWords.first;
    }
    final current = _words[_currentWordIndex];
    if (!searchActive) return current;
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

  bool isModuleEnabled(String moduleId) {
    return ModuleRuntimeGuard(_moduleToggleState).canAccess(moduleId);
  }

  void setModuleEnabled(String moduleId, bool enabled) =>
      _setModuleEnabledImpl(moduleId, enabled);

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

  Future<void> saveAmbientPresetFromCurrentMix(String name) =>
      AppStateAmbientDomain(this).saveAmbientPresetFromCurrentMix(name);

  Future<void> deleteAmbientPreset(String presetId) =>
      AppStateAmbientDomain(this).deleteAmbientPreset(presetId);

  Future<void> applyAmbientPreset(String presetId) =>
      AppStateAmbientDomain(this).applyAmbientPreset(presetId);

  Future<void> setAmbientMasterVolume(double value) =>
      AppStateAmbientDomain(this).setAmbientMasterVolume(value);

  Future<void> setAmbientEnabled(bool value) =>
      AppStateAmbientDomain(this).setAmbientEnabled(value);

  Future<void> setAmbientSourceEnabled(String sourceId, bool enabled) =>
      AppStateAmbientDomain(this).setAmbientSourceEnabled(sourceId, enabled);

  Future<void> setAmbientSourceVolume(String sourceId, double value) =>
      AppStateAmbientDomain(this).setAmbientSourceVolume(sourceId, value);

  Future<void> addAmbientFileSource() =>
      AppStateAmbientDomain(this).addAmbientFileSource();

  Future<List<OnlineAmbientSoundOption>> fetchOnlineAmbientCatalog({
    bool forceRefresh = false,
  }) => AppStateAmbientDomain(
    this,
  ).fetchOnlineAmbientCatalog(forceRefresh: forceRefresh);

  Future<Set<String>> fetchDownloadedOnlineAmbientRelativePaths() =>
      AppStateAmbientDomain(this).fetchDownloadedOnlineAmbientRelativePaths();

  Future<String?> downloadOnlineAmbientSource(
    OnlineAmbientSoundOption option,
  ) => AppStateAmbientDomain(this).downloadOnlineAmbientSource(option);

  Future<String?> downloadOnlineAmbientSourceWithProgress(
    OnlineAmbientSoundOption option,
    void Function(ResourceDownloadProgress progress)? onProgress,
  ) => AppStateAmbientDomain(
    this,
  ).downloadOnlineAmbientSourceWithProgress(option, onProgress);

  Future<bool> deleteDownloadedOnlineAmbientSource(
    OnlineAmbientSoundOption option,
  ) => AppStateAmbientDomain(this).deleteDownloadedOnlineAmbientSource(option);

  Future<String?> pickBackgroundImageByPicker() =>
      AppStateAmbientDomain(this).pickBackgroundImageByPicker();

  Future<void> removeAmbientSource(String sourceId) =>
      AppStateAmbientDomain(this).removeAmbientSource(sourceId);

  Future<AsrResult> transcribeRecording(
    String audioPath, {
    String? expectedText,
    AsrProviderType? provider,
    AsrProgressCallback? onProgress,
  }) => AppStateAsrDomain(this).transcribeRecording(
    audioPath,
    expectedText: expectedText,
    provider: provider,
    onProgress: onProgress,
  );

  Future<String?> startAsrRecording({AsrProviderType? provider}) =>
      AppStateAsrDomain(this).startAsrRecording(provider: provider);

  Future<String?> stopAsrRecording() =>
      AppStateAsrDomain(this).stopAsrRecording();

  Future<void> cancelAsrRecording() =>
      AppStateAsrDomain(this).cancelAsrRecording();

  void stopAsrProcessing() => AppStateAsrDomain(this).stopAsrProcessing();

  Future<String?> startVoiceInputRecording({bool forceRecorder = false}) =>
      AppStateAsrDomain(
        this,
      ).startVoiceInputRecording(forceRecorder: forceRecorder);

  Future<String?> stopVoiceInputRecording() =>
      AppStateAsrDomain(this).stopVoiceInputRecording();

  Future<void> cancelVoiceInputRecording() =>
      AppStateAsrDomain(this).cancelVoiceInputRecording();

  void stopVoiceInputProcessing() =>
      AppStateAsrDomain(this).stopVoiceInputProcessing();

  Future<AsrResult> transcribeVoiceInputRecording(
    String audioPath, {
    AsrProgressCallback? onProgress,
  }) => AppStateAsrDomain(
    this,
  ).transcribeVoiceInputRecording(audioPath, onProgress: onProgress);

  Future<AsrOfflineModelStatus> getVoiceInputOfflineModelStatus() =>
      AppStateAsrDomain(this).getVoiceInputOfflineModelStatus();

  Future<void> prepareVoiceInputOfflineModel({
    AsrProgressCallback? onProgress,
  }) => AppStateAsrDomain(
    this,
  ).prepareVoiceInputOfflineModel(onProgress: onProgress);

  Future<void> removeVoiceInputOfflineModel() =>
      AppStateAsrDomain(this).removeVoiceInputOfflineModel();

  Future<AsrOfflineModelStatus> getAsrOfflineModelStatus(
    AsrProviderType provider,
  ) => AppStateAsrDomain(this).getAsrOfflineModelStatus(provider);

  Future<void> prepareAsrOfflineModel(
    AsrProviderType provider, {
    AsrProgressCallback? onProgress,
  }) => AppStateAsrDomain(
    this,
  ).prepareAsrOfflineModel(provider, onProgress: onProgress);

  Future<void> removeAsrOfflineModel(AsrProviderType provider) =>
      AppStateAsrDomain(this).removeAsrOfflineModel(provider);

  Future<PronScoringPackStatus> getPronScoringPackStatus(
    PronScoringMethod method,
  ) => AppStateAsrDomain(this).getPronScoringPackStatus(method);

  Future<void> preparePronScoringPack(
    PronScoringMethod method, {
    AsrProgressCallback? onProgress,
  }) => AppStateAsrDomain(
    this,
  ).preparePronScoringPack(method, onProgress: onProgress);

  Future<void> removePronScoringPack(PronScoringMethod method) =>
      AppStateAsrDomain(this).removePronScoringPack(method);

  PronunciationComparison comparePronunciation(
    String expected,
    String recognized,
  ) => AppStateAsrDomain(this).comparePronunciation(expected, recognized);

  Future<List<DatabaseBackupInfo>> listDatabaseBackups() =>
      AppStateExportDomain(this).listDatabaseBackups();

  Future<bool> deleteDatabaseBackup(DatabaseBackupInfo backup) =>
      AppStateExportDomain(this).deleteDatabaseBackup(backup);

  Future<String> getDefaultUserDataExportDirectoryPath() =>
      AppStateExportDomain(this).getDefaultUserDataExportDirectoryPath();

  Future<String?> exportUserData({
    Iterable<UserDataExportSection>? sections,
    String? directoryPath,
    String? fileName,
  }) => AppStateExportDomain(this).exportUserData(
    sections: sections,
    directoryPath: directoryPath,
    fileName: fileName,
  );

  Future<bool> restoreUserDataExport(String filePath) =>
      AppStateExportDomain(this).restoreUserDataExport(filePath);

  PracticeReviewExportPayload buildPracticeReviewExportPayload({
    Iterable<PracticeSessionRecord>? records,
    Iterable<WordEntry>? wrongNotebookEntries,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) => AppStateExportDomain(this).buildPracticeReviewExportPayload(
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
  }) => AppStateExportDomain(this).exportPracticeReviewData(
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
  }) => AppStateExportDomain(this).buildPracticeWrongNotebookExportPayload(
    entries: entries,
    metadata: metadata,
  );

  Future<String?> exportPracticeWrongNotebookData({
    required Iterable<WordEntry> entries,
    required PracticeExportFormat format,
    String? directoryPath,
    String? fileName,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) => AppStateExportDomain(this).exportPracticeWrongNotebookData(
    entries: entries,
    format: format,
    directoryPath: directoryPath,
    fileName: fileName,
    metadata: metadata,
  );

  Future<bool> restoreDatabaseBackup(DatabaseBackupInfo backup) =>
      AppStateExportDomain(this).restoreDatabaseBackup(backup);

  Future<void> ensureRemoteResourcePrewarmOnDemand() =>
      _ensureRemoteResourcePrewarmOnDemandImpl();

  Future<void> loadSleepAssistantData() => _loadSleepAssistantDataImpl();

  void saveSleepProfile(SleepProfile profile) => _saveSleepProfileImpl(profile);

  void updateSleepAssessmentDraft(SleepAssessmentDraftState draft) =>
      _updateSleepAssessmentDraftImpl(draft);

  void saveSleepDailyLog(SleepDailyLog log) => _saveSleepDailyLogImpl(log);

  void saveSleepNightEvent(SleepNightEvent event) =>
      _saveSleepNightEventImpl(event);

  void saveSleepThoughtEntry(SleepThoughtEntry entry) =>
      _saveSleepThoughtEntryImpl(entry);

  SleepDailyLog? sleepDailyLogByDateKey(String dateKey) =>
      _sleepDailyLogByDateKeyImpl(dateKey);

  void setSleepActiveRoutineTemplate(String templateId) =>
      _setSleepActiveRoutineTemplateImpl(templateId);

  void replaceSleepRoutineTemplates(List<SleepRoutineTemplate> templates) =>
      _replaceSleepRoutineTemplatesImpl(templates);

  void saveSleepRoutineTemplate(SleepRoutineTemplate template) =>
      _saveSleepRoutineTemplateImpl(template);

  void deleteSleepRoutineTemplate(String templateId) =>
      _deleteSleepRoutineTemplateImpl(templateId);

  void startSleepRoutine([String? templateId]) =>
      _startSleepRoutineImpl(templateId);

  void pauseSleepRoutine() => _pauseSleepRoutineImpl();

  void resumeSleepRoutine() => _resumeSleepRoutineImpl();

  void advanceSleepRoutine() => _advanceSleepRoutineImpl();

  void tickSleepRoutine() => _tickSleepRoutineImpl();

  void stopSleepRoutine() => _stopSleepRoutineImpl();

  void setSleepCurrentPlan(SleepPlan? plan) => _setSleepCurrentPlanImpl(plan);

  void updateSleepDashboardState(SleepDashboardState state) =>
      _updateSleepDashboardStateImpl(state);

  void startSleepProgram(SleepProgramType type) => _startSleepProgramImpl(type);

  void completeSleepProgramDay(int day) => _completeSleepProgramDayImpl(day);

  void startSleepNightRescue(SleepNightRescueMode mode) =>
      _startSleepNightRescueImpl(mode);

  void finishSleepNightRescue({
    String? suggestedAction,
    bool hasLeftBed = false,
  }) => _finishSleepNightRescueImpl(
    suggestedAction: suggestedAction,
    hasLeftBed: hasLeftBed,
  );

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

  Future<void> selectWordEntry(WordEntry entry) => _selectWordEntryImpl(entry);

  Future<void> createWordbook(String name) async {
    if (name.trim().isEmpty) return;
    _setBusy(true);
    try {
      final id = _wordbookRepository.createWordbook(name.trim());
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

  Future<void> refreshBuiltInWordbookCatalog() async {
    _setBusy(true, messageKey: 'busyLoadingWordbook');
    try {
      await _wordbookRepository.syncBuiltInWordbooksCatalog();
      await _reloadWordbooks(keepCurrentSelection: true);
      await _syncSpecialWordbooks();
    } catch (error) {
      _setMessage(
        'errorImportFailed',
        params: <String, Object?>{'error': error},
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<void> renameWordbook(Wordbook wordbook, String newName) async {
    _setBusy(true);
    try {
      _wordbookRepository.renameWordbook(wordbook.id, newName.trim());
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
      _wordbookRepository.deleteManagedWordbook(wordbook.id);
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['json', 'jsonl', 'csv', 'mdx', 'gz'],
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final filePath = result.files.single.path?.trim() ?? '';
    if (filePath.isEmpty) {
      return;
    }

    final suggestedName = _deriveImportedWordbookNameFromPath(filePath);
    final requested = await requestName?.call(suggestedName);
    final resolvedName = (requested ?? suggestedName).trim();
    if (resolvedName.isEmpty) {
      return;
    }
    await importWordbookFile(filePath, resolvedName);
  }

  Future<void> importWordbookFile(String filePath, String name) async {
    final normalizedPath = filePath.trim();
    final normalizedName = name.trim().isEmpty
        ? _deriveImportedWordbookNameFromPath(filePath)
        : name.trim();
    if (normalizedPath.isEmpty || normalizedName.isEmpty) {
      return;
    }

    _wordbookImportActive = true;
    _wordbookImportName = normalizedName;
    _wordbookImportProcessedEntries = 0;
    _wordbookImportTotalEntries = null;
    _setBusy(
      true,
      messageKey: 'busyImportingWordbook',
      detail: normalizedName,
      progress: null,
    );
    try {
      final imported = await _wordbookRepository.importWordbookFileAsync(
        filePath: normalizedPath,
        name: normalizedName,
        onProgress: (processedEntries, totalEntries) {
          _wordbookImportActive = true;
          _wordbookImportName = normalizedName;
          _wordbookImportProcessedEntries = processedEntries;
          _wordbookImportTotalEntries = totalEntries;
          final progress = totalEntries == null || totalEntries <= 0
              ? null
              : (processedEntries / totalEntries).clamp(0.0, 1.0);
          final detail = totalEntries == null
              ? '$processedEntries'
              : '$processedEntries / $totalEntries';
          _setBusy(
            true,
            messageKey: 'busyImportingWordbook',
            detail: detail,
            progress: progress,
          );
        },
      );
      await _reloadWordbooks(keepCurrentSelection: false);
      final importedWordbook = _wordbooks
          .where((item) => item.path == normalizedPath)
          .cast<Wordbook?>()
          .firstOrNull;
      if (importedWordbook != null) {
        await selectWordbook(importedWordbook);
      }
      await _syncSpecialWordbooks();
      _setMessage(
        'importWordbookSuccess',
        params: <String, Object?>{'count': imported},
      );
    } catch (error) {
      _setMessage(
        'errorImportFailed',
        params: <String, Object?>{'error': error},
      );
    } finally {
      _wordbookImportActive = false;
      _wordbookImportName = '';
      _wordbookImportProcessedEntries = 0;
      _wordbookImportTotalEntries = null;
      _setBusy(false);
    }
  }

  Future<void> importLegacyDatabaseByPicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['db'],
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final filePath = result.files.single.path?.trim() ?? '';
    if (filePath.isEmpty) {
      return;
    }

    _setBusy(true, messageKey: 'busyMigratingLegacyData');
    try {
      final imported = await _wordbookRepository.importLegacyDatabase(filePath);
      await _reloadWordbooks(keepCurrentSelection: false);
      await _syncSpecialWordbooks();
      _setMessage(
        'migrationSuccess',
        params: <String, Object?>{'count': imported},
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

  String _deriveImportedWordbookNameFromPath(String filePath) {
    final basename = p.basename(filePath.trim());
    final lower = basename.toLowerCase();
    if (lower.endsWith('.json.gz')) {
      return basename.substring(0, basename.length - '.json.gz'.length);
    }
    if (lower.endsWith('.jsonl')) {
      return basename.substring(0, basename.length - '.jsonl'.length);
    }
    return p.basenameWithoutExtension(basename);
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

    String? derivePrimaryGloss(List<WordFieldItem> fields, String rawContent) {
      for (final field in fields) {
        if (field.key != 'meaning') {
          continue;
        }
        final text = field.asText().trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
      final normalizedRaw = rawContent.trim();
      return normalizedRaw.isEmpty ? null : normalizedRaw;
    }

    final payload = WordEntryPayload(
      word: word.trim(),
      fields: fields,
      rawContent: rawContent,
      entryUid: original?.entryUid,
      primaryGloss:
          derivePrimaryGloss(fields, rawContent) ?? original?.primaryGloss,
      schemaVersion: original?.schemaVersion,
      sortIndex: original?.sortIndex,
      sourcePayloadJson: original?.sourcePayloadJson,
    );

    _setBusy(true);
    try {
      if (original == null) {
        _wordbookRepository.addWord(selected.id, payload);
      } else {
        _wordbookRepository.updateWord(
          wordbookId: selected.id,
          sourceWord: original.word,
          sourceWordId: original.id,
          sourceEntryUid: original.entryUid,
          sourcePrimaryGloss:
              original.primaryGloss ?? original.summaryMeaningText,
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
        _wordbookRepository.upsertWord(
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
      _wordbookRepository.deleteWord(selected.id, word.word);
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

    final referenceKey = word.collectionReferenceKey;
    final wasFavorite = _favorites.contains(referenceKey);
    final previousFavorites = Set<String>.from(_favorites);
    final previousWordbooks = List<Wordbook>.from(_wordbooks);
    final previousSelectedWordbook = _selectedWordbook;
    final previousWords = List<WordEntry>.from(_words);
    final previousCurrentWordIndex = _currentWordIndex;

    final nextFavorites = Set<String>.from(_favorites);
    if (wasFavorite) {
      nextFavorites.remove(referenceKey);
    } else {
      nextFavorites.add(referenceKey);
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
        _wordbookRepository.deleteWordByEntryIdentity(favoritesBook.id, word);
      } else {
        _wordbookRepository.upsertWord(favoritesBook.id, word.toPayload());
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

    final referenceKey = word.collectionReferenceKey;
    final wasTaskWord = _taskWords.contains(referenceKey);
    final previousTaskWords = Set<String>.from(_taskWords);
    final previousWordbooks = List<Wordbook>.from(_wordbooks);
    final previousSelectedWordbook = _selectedWordbook;
    final previousWords = List<WordEntry>.from(_words);
    final previousCurrentWordIndex = _currentWordIndex;

    final nextTaskWords = Set<String>.from(_taskWords);
    if (wasTaskWord) {
      nextTaskWords.remove(referenceKey);
    } else {
      nextTaskWords.add(referenceKey);
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
        _wordbookRepository.deleteWordByEntryIdentity(taskBook.id, word);
      } else {
        _wordbookRepository.upsertWord(taskBook.id, word.toPayload());
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
      _wordbookRepository.clearWordbook(taskBook.id);
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
      final exportedId = _wordbookRepository.exportWordbook(taskBook.id, name);
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
      _wordbookRepository.mergeWordbooks(
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
      await _maintenanceRepository.resetUserData();

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

  void updateConfig(PlayConfig config) {
    _config = config;
    _settings.savePlayConfig(config);
    _playback.updateRuntimeConfig(config);
    notifyListeners();
  }

  Future<void> play() => _playImpl();

  Future<void> preparePlay() => _preparePlayImpl();

  Future<void> startPreparedPlay() => _startPreparedPlayImpl();

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
    final entry = _wordbookRepository.findJumpWordByInitial(
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
    final entry = _wordbookRepository.findJumpWordByPrefix(
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
        MapEntry(RegExp(r'\bgonna\b'), 'going to'),
        MapEntry(RegExp(r'\bwanna\b'), 'want to'),
        MapEntry(RegExp(r'\bkinda\b'), 'kind of'),
        MapEntry(RegExp(r'\bsorta\b'), 'sort of'),
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
            word.searchMeaningText,
          );
          final detailsText = search_text.normalizeSearchText(
            word.searchDetailsText,
          );
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
      text.toLowerCase().replaceAll(RegExp(r'[’`´]'), "'"),
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

  Future<void> _reloadWordbooks({
    required bool keepCurrentSelection,
    bool preloadSelectedWords = true,
  }) async {
    final selectedId = keepCurrentSelection ? _selectedWordbook?.id : null;
    _wordbooks = _wordbookRepository
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

    final selectedWordbook = _selectedWordbook;
    final shouldLoadSelectedWords = switch (selectedWordbook) {
      null => false,
      _ when preloadSelectedWords => true,
      final wordbook => _shouldEagerLoadWordbookOnStartup(wordbook),
    };

    if (selectedWordbook != null && shouldLoadSelectedWords) {
      _setWords(_queryWordbookEntries(selectedWordbook));
      final restoredIndex = _playbackProgressIndexForWordbook(selectedWordbook);
      final restoredEntries = _searchQuery.trim().isEmpty
          ? _words
          : _scopeWords;
      if (restoredIndex >= 0 && restoredIndex < restoredEntries.length) {
        final target = (_searchQuery.trim().isEmpty
            ? _words
            : _scopeWords)[restoredIndex];
        _setCurrentWordByEntry(target);
      } else if (_currentWordIndex >= _words.length) {
        _currentWordIndex = _words.isEmpty ? 0 : (_words.length - 1);
      }
      _ensureCurrentWordInScope();
    } else {
      _clearSelectedWordbookWords();
      _currentWordIndex = 0;
    }
    notifyListeners();
  }

  void _setWords(List<WordEntry> nextWords) {
    final transient = _transientCurrentWord;
    _words = nextWords;
    _loadedWordbookId = _selectedWordbook?.id;
    if (transient != null) {
      final index = _indexOfWordEntry(nextWords, transient);
      if (index >= 0) {
        _currentWordIndex = index;
      }
    }
    _transientCurrentWord = null;
    _refreshWordMemoryProgressCache(nextWords);
    _wordsVersion += 1;
    _invalidateVisibleWordsCache();
  }

  void _clearSelectedWordbookWords() {
    _words = const <WordEntry>[];
    _loadedWordbookId = null;
    _transientCurrentWord = null;
    _refreshWordMemoryProgressCache(_words);
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
      _favorites = _wordbookRepository
          .getWords(favoritesBook.id)
          .map((item) => item.collectionReferenceKey)
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
      _taskWords = _wordbookRepository
          .getWords(taskBook.id)
          .map((item) => item.collectionReferenceKey)
          .toSet();
      _persistSpecialWordSet('taskWords', _taskWords);
    } else {
      _taskWords = <String>{};
    }
    notifyListeners();
  }

  void _persistSpecialWordSet(String settingKey, Set<String> values) {
    _settings.saveStringSet(settingKey, values);
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
          (item) =>
              item.collectionReferenceKey ==
              optimisticWord.collectionReferenceKey,
        );
        if (!alreadyExists) {
          nextWords.insert(
            0,
            optimisticWord.copyWith(wordbookId: specialWordbook.id),
          );
        }
      } else {
        nextWords.removeWhere(
          (item) =>
              item.collectionReferenceKey ==
              optimisticWord.collectionReferenceKey,
        );
      }
      _setWords(nextWords);
    } else {
      _setWords(_wordbookRepository.getWords(specialWordbook.id));
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
      _transientCurrentWord = null;
      return;
    }
    // Fallback for legacy records without stable ids/content.
    final fallback = _words.indexWhere((item) => item.word == entry.word);
    if (fallback >= 0) {
      _currentWordIndex = fallback;
      return;
    }
    _transientCurrentWord = entry;
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
    return a.sameEntryAs(b);
  }

  WordEntry _hydrateWordEntryIfNeeded(WordEntry entry) {
    final wordbook = _resolveWordbookForEntry(entry);
    if (wordbook == null || !_shouldUseLiteWordQueries(wordbook)) {
      return entry;
    }
    final hydrated = _wordbookRepository.hydrateWordEntry(entry);
    if (hydrated == null) {
      return entry;
    }
    _replaceLoadedWordEntryIfNeeded(hydrated);
    return hydrated;
  }

  void _replaceLoadedWordEntryIfNeeded(WordEntry entry) {
    final index = _indexOfWordEntry(_words, entry);
    if (index < 0) {
      return;
    }
    final existing = _words[index];
    if (_isWordEntryHydrationEquivalent(existing, entry)) {
      return;
    }
    final nextWords = List<WordEntry>.from(_words);
    nextWords[index] = entry;
    _words = nextWords;
    _loadedWordbookId = _selectedWordbook?.id;
    _transientCurrentWord = null;
    _refreshWordMemoryProgressCache(nextWords);
    _wordsVersion += 1;
    _invalidateVisibleWordsCache();
  }

  bool _isWordEntryHydrationEquivalent(WordEntry current, WordEntry next) {
    return _isSameWordEntry(current, next) &&
        current.summaryMeaningText == next.summaryMeaningText &&
        current.rawContent == next.rawContent &&
        current.fields.length == next.fields.length;
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
        previous.entryUid == resolvedEntry.entryUid &&
        previous.primaryGloss == resolvedEntry.primaryGloss &&
        previous.word == resolvedEntry.word) {
      return;
    }
    _playbackProgressByWordbookPath = <String, PlaybackProgressSnapshot>{
      ..._playbackProgressByWordbookPath,
      path: PlaybackProgressSnapshot(
        wordbookPath: path,
        wordId: resolvedEntry.id,
        entryUid: resolvedEntry.entryUid,
        primaryGloss: resolvedEntry.primaryGloss,
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
    final entryUid = snapshot.entryUid?.trim() ?? '';
    if (entryUid.isNotEmpty) {
      final index = entries.indexWhere((item) => item.entryUid == entryUid);
      if (index >= 0) {
        return index;
      }
    }
    final primaryGloss = snapshot.primaryGloss?.trim() ?? '';
    if (primaryGloss.isNotEmpty) {
      final index = entries.indexWhere(
        (item) =>
            item.word == snapshot.word &&
            (item.primaryGloss?.trim() ?? item.summaryMeaningText.trim()) ==
                primaryGloss,
      );
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

  bool _shouldEagerLoadWordbookOnStartup(Wordbook wordbook) {
    return wordbook.wordCount <= _startupEagerWordLoadLimit;
  }

  bool _shouldUseLiteWordQueries(Wordbook wordbook) {
    return wordbook.wordCount > _startupEagerWordLoadLimit;
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
    _startupStore.syncPersistentStateFromSettings();
    _weatherStore.syncEnabledFromSettings();
    _rememberedWords = _settings.loadRememberedWords();
    _playbackProgressByWordbookPath = _settings
        .loadPlaybackProgressByWordbook();

    _testModeStore.syncFromSettings();

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
    await _loadSleepAssistantDataImpl();
    await _focusService.init();
    await _reloadWordbooks(keepCurrentSelection: false);
    await _syncSpecialWordbooks();
    _refreshLocalizedWordbookNames();
    if (_weatherStore.enabled) {
      unawaited(refreshWeather(force: true));
    }
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
    String? detail,
    double? progress,
  }) {
    _busy = value;
    if (value) {
      _busyMessageKey = messageKey;
      _busyMessageParams = params;
      final trimmedDetail = detail?.trim() ?? '';
      _busyDetail = trimmedDetail.isEmpty ? null : trimmedDetail;
      _busyProgress = progress?.clamp(0.0, 1.0).toDouble();
    } else {
      _busyMessageKey = null;
      _busyMessageParams = const <String, Object?>{};
      _busyDetail = null;
      _busyProgress = null;
    }
    notifyListeners();
  }

  double? _busyProgressForWordbookLoad(BuiltInWordbookLoadProgress progress) {
    final stageProgress = progress.progress;
    if (stageProgress == null) {
      return progress.stage == BuiltInWordbookLoadStage.completed ? 1.0 : null;
    }
    return switch (progress.stage) {
      BuiltInWordbookLoadStage.downloading => (stageProgress * 0.72).clamp(
        0.0,
        0.72,
      ),
      BuiltInWordbookLoadStage.processing =>
        (0.72 + stageProgress * 0.26).clamp(0.72, 0.98),
      BuiltInWordbookLoadStage.completed => 1.0,
    };
  }

  String _busyDetailForWordbookLoadProgress(
    BuiltInWordbookLoadProgress progress,
  ) {
    final i18n = AppI18n(_uiLanguage);
    return switch (progress.stage) {
      BuiltInWordbookLoadStage.downloading => _busyDownloadDetailText(
        i18n,
        receivedBytes: progress.receivedBytes ?? 0,
        totalBytes: progress.totalBytes ?? 0,
        progress: progress.progress,
      ),
      BuiltInWordbookLoadStage.processing => _busyProcessingDetailText(
        i18n,
        processedEntries: progress.processedEntries ?? 0,
        totalEntries: progress.totalEntries,
        progress: progress.progress,
      ),
      BuiltInWordbookLoadStage.completed => _busyProcessingDetailText(
        i18n,
        processedEntries:
            progress.processedEntries ?? progress.totalEntries ?? 0,
        totalEntries: progress.totalEntries ?? progress.processedEntries,
        progress: 1.0,
      ),
    };
  }

  String _busyDownloadDetailText(
    AppI18n i18n, {
    required int receivedBytes,
    required int totalBytes,
    required double? progress,
  }) {
    final label = i18n.t('download');
    if (totalBytes <= 0) {
      return label;
    }
    final percent = (((progress ?? 0) * 100).clamp(0.0, 100.0)).round();
    return '$label ${_formatByteSize(receivedBytes)}/${_formatByteSize(totalBytes)} | $percent%';
  }

  String _busyProcessingDetailText(
    AppI18n i18n, {
    required int processedEntries,
    required int? totalEntries,
    required double? progress,
  }) {
    final label = i18n.t('processing');
    if (totalEntries == null || totalEntries <= 0) {
      return processedEntries <= 0 ? label : '$label | $processedEntries';
    }
    final percent = (((progress ?? 0) * 100).clamp(0.0, 100.0)).round();
    return '$label | $processedEntries/$totalEntries | $percent%';
  }

  String _formatByteSize(int bytes) {
    if (bytes <= 0) {
      return '0 KB';
    }
    const units = <String>['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex += 1;
    }
    final precision = size >= 100 || unitIndex == 0 ? 0 : 1;
    return '${size.toStringAsFixed(precision)} ${units[unitIndex]}';
  }

  void _onWeatherStoreChanged() {
    _notifyStateChanged();
  }

  void _onTestModeStoreChanged() {
    _notifyStateChanged();
  }

  void _onStartupStoreChanged() {
    _notifyStateChanged();
  }

  void _notifyStateChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _ambientSyncDebounceTimer?.cancel();
    _weatherStore.removeListener(_onWeatherStoreChanged);
    _testModeStore.removeListener(_onTestModeStoreChanged);
    _startupStore.removeListener(_onStartupStoreChanged);
    if (_ownsWeatherStore) {
      _weatherStore.dispose();
    }
    if (_ownsTestModeStore) {
      _testModeStore.dispose();
    }
    if (_ownsStartupStore) {
      _startupStore.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    _playback.stop();
    _focusService.dispose();
    _ambient.stopAll();
    _asr.dispose();
    _maintenanceRepository.dispose();
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

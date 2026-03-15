import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../i18n/app_i18n.dart';
import '../models/app_home_tab.dart';
import '../models/play_config.dart';
import '../models/weather_snapshot.dart';
import '../models/word_entry.dart';
import '../models/word_field.dart';
import '../models/word_memory_progress.dart';
import '../models/wordbook.dart';
import '../services/ambient_service.dart';
import '../services/app_log_service.dart';
import '../services/asr_service.dart';
import '../services/database_service.dart';
import '../services/focus_service.dart';
import '../services/memory_algorithm.dart';
import '../services/memory_lane_selector.dart';
import '../services/playback_service.dart';
import '../services/settings_service.dart';
import '../services/weather_service.dart';

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
  }) : _database = database,
       _settings = settings,
       _playback = playback,
       _ambient = ambient,
       _asr = asr,
       _focusService = focusService,
       _weatherService = weatherService ?? WeatherService() {
    WidgetsBinding.instance.addObserver(this);
  }

  final AppDatabaseService _database;
  final SettingsService _settings;
  final PlaybackService _playback;
  final AmbientService _ambient;
  final AsrService _asr;
  final FocusService _focusService;
  final WeatherService _weatherService;
  final AppLogService _log = AppLogService.instance;

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
  String _uiLanguage = _resolveSystemUiLanguage();
  bool _uiLanguageFollowsSystem = true;
  AppHomeTab _startupPage = AppHomeTab.play;
  bool _weatherEnabled = false;
  WeatherSnapshot? _weatherSnapshot;
  bool _weatherLoading = false;
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
  Map<int, WordMemoryProgress> _wordMemoryProgressByWordId =
      <int, WordMemoryProgress>{};

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
  bool get weatherEnabled => _weatherEnabled;
  WeatherSnapshot? get weatherSnapshot => _weatherSnapshot;
  bool get weatherLoading => _weatherLoading;
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
  double get practiceTodayAccuracy => _practiceTodayReviewed <= 0
      ? 0
      : (_practiceTodayRemembered / _practiceTodayReviewed).clamp(0.0, 1.0);
  double get practiceTotalAccuracy => _practiceTotalReviewed <= 0
      ? 0
      : (_practiceTotalRemembered / _practiceTotalReviewed).clamp(0.0, 1.0);
  List<AmbientSource> get ambientSources => _ambient.sources;
  double get ambientMasterVolume => _ambient.masterVolume;

  List<WordEntry> get visibleWords {
    if (_visibleWordsCache != null &&
        _visibleWordsCacheVersion == _wordsVersion &&
        _visibleWordsCacheQuery == _searchQuery &&
        _visibleWordsCacheMode == _searchMode) {
      return _visibleWordsCache!;
    }

    final computed = filterWords(
      words: _words,
      query: _searchQuery,
      mode: _searchMode,
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

  Future<void> init() async {
    if (_initialized || _initializing) return;
    _initializing = true;
    _message = null;
    _log.i('app_state', 'init start');
    notifyListeners();

    try {
      await _database.init();
      await _focusService.init();
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
      _weatherEnabled = _settings.loadWeatherEnabled();
      final testModeState = _settings.loadTestModeState();
      _testModeEnabled = testModeState['enabled'] ?? false;
      _testModeRevealed = testModeState['revealed'] ?? false;
      _testModeHintRevealed = testModeState['hintRevealed'] ?? false;
      _loadPracticeDashboard();
      _ensurePracticeDate(persist: true);
      await _reloadWordbooks(keepCurrentSelection: false);
      await _syncSpecialWordbooks();
      _initialized = true;
      final logFilePath = await _log.getLogFilePath();
      _log.i(
        'app_state',
        'init success',
        data: <String, Object?>{
          'wordbooks': _wordbooks.length,
          'selectedWordbookId': _selectedWordbook?.id,
          'selectedWordbookName': _selectedWordbook?.name,
          'words': _words.length,
          'uiLanguage': _uiLanguage,
          'uiLanguageFollowsSystem': _uiLanguageFollowsSystem,
          'startupPage': _startupPage.storageValue,
          'weatherEnabled': _weatherEnabled,
          'logFile': logFilePath,
          'ttsProvider': _config.tts.provider.name,
          'ttsModel': _config.tts.model,
          'ttsVoice': _config.tts.activeVoice,
        },
      );
      if (_weatherEnabled) {
        unawaited(refreshWeather(force: true));
      }
    } catch (error) {
      _log.e('app_state', 'init failed', error: error);
      _setMessage('errorInitFailed', params: <String, Object?>{'error': error});
    } finally {
      _initializing = false;
      notifyListeners();
    }
  }

  void clearMessage() {
    _message = null;
    _messageParams = const <String, Object?>{};
    notifyListeners();
  }

  void setUiLanguage(String language) {
    final normalized = AppI18n.normalizeLanguageCode(language);
    if (normalized.isEmpty ||
        (normalized == _uiLanguage && !_uiLanguageFollowsSystem)) {
      return;
    }
    _log.i(
      'app_state',
      'set ui language',
      data: <String, Object?>{
        'from': _uiLanguage,
        'to': normalized,
        'followSystem': false,
      },
    );
    _uiLanguage = normalized;
    _uiLanguageFollowsSystem = false;
    _settings.saveUiLanguage(_uiLanguage);
    _refreshLocalizedWordbookNames();
    notifyListeners();
  }

  void setUiLanguageFollowSystem() {
    final resolved = _resolveSystemUiLanguage();
    final changed = !_uiLanguageFollowsSystem || _uiLanguage != resolved;
    if (!changed) return;
    _log.i(
      'app_state',
      'set ui language follow system',
      data: <String, Object?>{'from': _uiLanguage, 'to': resolved},
    );
    _uiLanguageFollowsSystem = true;
    _uiLanguage = resolved;
    _settings.saveUiLanguage(SettingsService.uiLanguageSystem);
    _refreshLocalizedWordbookNames();
    notifyListeners();
  }

  void setStartupPage(AppHomeTab page) {
    if (_startupPage == page) return;
    _log.i(
      'app_state',
      'set startup page',
      data: <String, Object?>{
        'from': _startupPage.storageValue,
        'to': page.storageValue,
      },
    );
    _startupPage = page;
    _settings.saveStartupPage(page);
    notifyListeners();
  }

  void setWeatherEnabled(bool enabled) {
    if (_weatherEnabled == enabled) return;
    _weatherEnabled = enabled;
    _settings.saveWeatherEnabled(enabled);
    if (!enabled) {
      notifyListeners();
      return;
    }
    notifyListeners();
    unawaited(refreshWeather(force: true));
  }

  Future<void> refreshWeather({bool force = false}) async {
    if (!_weatherEnabled) return;
    if (_weatherLoading) return;
    if (!force && !_isWeatherStale()) return;

    _weatherLoading = true;
    notifyListeners();
    try {
      _weatherSnapshot = await _weatherService.fetchCurrentWeather();
    } catch (error) {
      _log.w(
        'app_state',
        'weather refresh failed',
        data: <String, Object?>{'error': '$error'},
      );
    } finally {
      _weatherLoading = false;
      notifyListeners();
    }
  }

  void refreshWeatherIfStale() {
    if (!_weatherEnabled || _weatherLoading || !_isWeatherStale()) {
      return;
    }
    unawaited(refreshWeather());
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    super.didChangeLocales(locales);
    if (!_uiLanguageFollowsSystem) return;
    final resolved = _resolveSystemUiLanguage();
    if (_uiLanguage == resolved) return;
    _log.i(
      'app_state',
      'sync ui language from system locale change',
      data: <String, Object?>{'from': _uiLanguage, 'to': resolved},
    );
    _uiLanguage = resolved;
    _refreshLocalizedWordbookNames();
    notifyListeners();
  }

  void setTestModeEnabled(bool enabled) {
    _testModeEnabled = enabled;
    _testModeRevealed = false;
    _testModeHintRevealed = false;
    _persistTestModeState();
    notifyListeners();
  }

  void toggleTestModeReveal() {
    if (!_testModeEnabled) return;
    _testModeRevealed = !_testModeRevealed;
    _persistTestModeState();
    notifyListeners();
  }

  void toggleTestModeHint() {
    if (!_testModeEnabled) return;
    _testModeHintRevealed = !_testModeHintRevealed;
    _persistTestModeState();
    notifyListeners();
  }

  void resetTestModeProgress() {
    if (!_testModeEnabled) return;
    if (!_testModeRevealed && !_testModeHintRevealed) return;
    _testModeRevealed = false;
    _testModeHintRevealed = false;
    _persistTestModeState();
    notifyListeners();
  }

  void recordPracticeSession({
    required String title,
    required int total,
    required int remembered,
    required List<String> rememberedWords,
    required List<String> weakWords,
    List<WordEntry>? rememberedEntries,
    List<WordEntry>? weakEntries,
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
    final normalizedWeakWords = _normalizePracticeWords(weakWords)
      ..removeWhere(normalizedRememberedWords.contains);
    final rememberedSet = normalizedRememberedWords.toSet();
    final weakSet = normalizedWeakWords.toSet();

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
    _updateWordMemoryProgress(
      rememberedEntries: _resolveTrackedPracticeEntries(
        preferredEntries: rememberedEntries,
        fallbackWords: normalizedRememberedWords,
      ),
      weakEntries: _resolveTrackedPracticeEntries(
        preferredEntries: weakEntries,
        fallbackWords: normalizedWeakWords,
      ),
    );
    _persistPracticeDashboard();
    notifyListeners();
  }

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    _invalidateVisibleWordsCache();
    _ensureCurrentWordInScope();
    _log.d(
      'app_state',
      'set search query',
      data: <String, Object?>{
        'query': value,
        'mode': _searchMode.name,
        'visibleCount': visibleWords.length,
      },
    );
    notifyListeners();
  }

  void setSearchMode(SearchMode mode) {
    if (_searchMode == mode) return;
    _searchMode = mode;
    _invalidateVisibleWordsCache();
    _ensureCurrentWordInScope();
    _log.d(
      'app_state',
      'set search mode',
      data: <String, Object?>{
        'mode': mode.name,
        'query': _searchQuery,
        'visibleCount': visibleWords.length,
      },
    );
    notifyListeners();
  }

  Future<void> selectWordbook(
    Wordbook? wordbook, {
    String? focusWord,
    int? focusWordId,
  }) async {
    if (wordbook == null) return;
    final shouldFollowPlayingWord =
        (focusWordId == null) &&
        ((focusWord ?? '').trim().isEmpty) &&
        _isPlaying &&
        _playingWordbookId == wordbook.id &&
        _playingScopeWords.isNotEmpty;
    if (shouldFollowPlayingWord) {
      final playingIndex = _playingScopeIndex.clamp(
        0,
        _playingScopeWords.length - 1,
      );
      final playingEntry = _playingScopeWords[playingIndex];
      focusWordId = playingEntry.id;
      focusWord = playingEntry.word;
    }
    final normalizedFocusWord = focusWord?.trim();
    final previousSelection = _selectedWordbook;
    _log.i(
      'app_state',
      'select wordbook',
      data: <String, Object?>{
        'id': wordbook.id,
        'name': wordbook.name,
        'path': wordbook.path,
        'focusWordId': focusWordId,
        'focusWord': focusWord,
      },
    );
    if (_database.isLazyBuiltInPath(wordbook.path) && wordbook.wordCount <= 0) {
      final lazyWordbookId = wordbook.id;
      final lazyWordbookName = wordbook.name;
      final lazyPath = wordbook.path;
      _setBusy(
        true,
        messageKey: 'busyLoadingWordbook',
        params: <String, Object?>{'name': lazyWordbookName},
      );
      try {
        await _database.ensureBuiltInWordbookLoaded(lazyPath);
        await _reloadWordbooks(keepCurrentSelection: false);
        wordbook =
            _wordbooks
                .where((item) => item.path == lazyPath)
                .cast<Wordbook?>()
                .firstOrNull ??
            wordbook;
      } catch (error, stackTrace) {
        _log.e(
          'app_state',
          'lazy built-in wordbook load failed',
          error: error,
          stackTrace: stackTrace,
          data: <String, Object?>{
            'id': lazyWordbookId,
            'name': lazyWordbookName,
            'path': lazyPath,
          },
        );
        _selectedWordbook = previousSelection;
        _setMessage(
          'errorImportFailed',
          params: <String, Object?>{'error': error},
        );
        return;
      } finally {
        _setBusy(false);
      }
    }
    _selectedWordbook = wordbook;
    _setWords(_database.getWords(wordbook.id));
    if (shouldFollowPlayingWord && _searchQuery.trim().isNotEmpty) {
      final matchesFocusedWord = _scopeWords.any(
        (item) =>
            (focusWordId != null && item.id == focusWordId) ||
            ((normalizedFocusWord ?? '').isNotEmpty &&
                item.word == normalizedFocusWord),
      );
      if (!matchesFocusedWord) {
        _searchQuery = '';
        _invalidateVisibleWordsCache();
      }
    }
    _currentWordIndex = 0;
    if (focusWordId != null) {
      final index = _words.indexWhere((item) => item.id == focusWordId);
      if (index >= 0) {
        _currentWordIndex = index;
      }
    }
    if (_currentWordIndex == 0 && (normalizedFocusWord ?? '').isNotEmpty) {
      final index = _words.indexWhere(
        (item) => item.word == normalizedFocusWord,
      );
      if (index >= 0) {
        _currentWordIndex = index;
      }
    }
    _ensureCurrentWordInScope();
    resetTestModeProgress();
    notifyListeners();
    if (previousSelection?.id != wordbook.id) {
      await _syncPlaybackToSelectedWordbook(wordbook);
    }
  }

  Future<void> _syncPlaybackToSelectedWordbook(Wordbook wordbook) async {
    if (!_isPlaying || _isPaused || _playingWordbookId == wordbook.id) {
      return;
    }

    final scopeWords = _scopeWords;
    if (scopeWords.isEmpty) {
      await stop();
      return;
    }

    final activeWord = currentWord;
    var startIndex = 0;
    if (activeWord != null) {
      final scopedIndex = _indexOfWordEntry(scopeWords, activeWord);
      if (scopedIndex >= 0) {
        startIndex = scopedIndex;
      }
    }
    final words = List<WordEntry>.from(scopeWords);
    final safeStart = startIndex.clamp(0, words.length - 1);
    final syncToken = ++_wordbookPlaybackSyncToken;

    _log.i(
      'app_state',
      'sync playback to selected wordbook',
      data: <String, Object?>{
        'selectedWordbookId': wordbook.id,
        'selectedWordbookName': wordbook.name,
        'playingWordbookId': _playingWordbookId,
        'startIndex': safeStart,
        'startWordId': words[safeStart].id,
        'startWord': words[safeStart].word,
      },
    );

    _playingWordbookId = wordbook.id;
    _playingWordbookName = wordbook.name;
    _playingScopeWords = words;
    _playingScopeIndex = safeStart;
    _playingWord = words[safeStart].word;
    _currentUnit = 0;
    _totalUnits = 0;
    _activeUnit = null;
    notifyListeners();

    _playSessionId += 1;
    await _playback.stop();
    if (syncToken != _wordbookPlaybackSyncToken) return;
    if (_selectedWordbook?.id != wordbook.id) return;

    unawaited(
      _startPlaySession(
        scopeWords: words,
        startIndex: safeStart,
        playingWordbookId: wordbook.id,
        playingWordbookName: wordbook.name,
      ),
    );
  }

  void selectWordIndex(int index) {
    if (index < 0 || index >= _words.length) return;
    _currentWordIndex = index;
    resetTestModeProgress();
    notifyListeners();
  }

  void selectWordByText(String word) {
    final index = _words.indexWhere((item) => item.word == word);
    if (index >= 0) {
      _currentWordIndex = index;
      resetTestModeProgress();
      notifyListeners();
    }
  }

  void selectWordEntry(WordEntry entry) {
    _setCurrentWordByEntry(entry);
    resetTestModeProgress();
    notifyListeners();
  }

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
        'errorInitFailed',
        params: <String, Object?>{'error': 'reset user data: $error'},
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

  Future<String?> exportUserData() async {
    _setBusy(true, messageKey: 'processing');
    try {
      return await _database.exportUserData();
    } catch (error, stackTrace) {
      _log.e(
        'app_state',
        'export user data failed',
        error: error,
        stackTrace: stackTrace,
      );
      _setMessage(
        'errorInitFailed',
        params: <String, Object?>{'error': 'export user data: $error'},
      );
      return null;
    } finally {
      _setBusy(false);
    }
  }

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

  Future<void> play() async {
    final selected = _selectedWordbook;
    final scopeWords = _scopeWords;
    if (selected == null || scopeWords.isEmpty || _isPlaying) {
      _log.w(
        'app_state',
        'play ignored',
        data: <String, Object?>{
          'selectedWordbook': selected?.id,
          'scopeWords': scopeWords.length,
          'isPlaying': _isPlaying,
        },
      );
      return;
    }

    final activeWord = currentWord;
    var startIndex = 0;
    if (activeWord != null) {
      final scopedIndex = _indexOfWordEntry(scopeWords, activeWord);
      if (scopedIndex >= 0) startIndex = scopedIndex;
    }
    _log.i(
      'app_state',
      'play requested',
      data: <String, Object?>{
        'wordbookId': selected.id,
        'wordbookName': selected.name,
        'scopeWords': scopeWords.length,
        'startIndex': startIndex,
        'activeWord': activeWord?.word,
        'searchMode': _searchMode.name,
        'searchQuery': _searchQuery,
        'provider': _config.tts.provider.name,
        'model': _config.tts.model,
        'voice': _config.tts.activeVoice,
      },
    );

    await _startPlaySession(
      scopeWords: scopeWords,
      startIndex: startIndex,
      playingWordbookId: selected.id,
      playingWordbookName: selected.name,
    );
  }

  Future<void> _startPlaySession({
    required List<WordEntry> scopeWords,
    required int startIndex,
    required int playingWordbookId,
    required String playingWordbookName,
  }) async {
    if (scopeWords.isEmpty) return;
    final words = List<WordEntry>.from(scopeWords);
    final safeStart = startIndex.clamp(0, words.length - 1);
    final sessionId = ++_playSessionId;

    _isPlaying = true;
    _isPaused = false;
    _playingWordbookId = playingWordbookId;
    _playingWordbookName = playingWordbookName;
    _playingScopeWords = words;
    _playingScopeIndex = safeStart;
    _playingWord = words[safeStart].word;
    _currentUnit = 0;
    _totalUnits = 0;
    _activeUnit = null;
    notifyListeners();

    try {
      await _playback.playWords(
        words: words,
        startIndex: safeStart,
        config: _config,
        onWordChanged: (index, word) {
          if (sessionId != _playSessionId) return;
          final nextWord = (index >= 0 && index < words.length)
              ? words[index]
              : word;
          final mappedIndex = _indexOfWordEntry(words, nextWord);
          if (mappedIndex >= 0) {
            _playingScopeIndex = mappedIndex;
          } else if (index >= 0 && index < words.length) {
            _playingScopeIndex = index;
          }
          _playingWord = nextWord.word;
          if (_selectedWordbook?.id == _playingWordbookId) {
            _setCurrentWordByEntry(nextWord);
            resetTestModeProgress();
          }
          notifyListeners();
        },
        onUnitChanged: (current, total, unit) {
          if (sessionId != _playSessionId) return;
          _currentUnit = current;
          _totalUnits = total;
          _activeUnit = unit;
          notifyListeners();
        },
        onFinished: () {
          if (sessionId != _playSessionId) return;
          _log.i(
            'app_state',
            'playback finished callback',
            data: <String, Object?>{
              'wordbookId': _playingWordbookId,
              'scopeWords': words.length,
            },
          );
          _clearPlaybackSession(notify: true);
        },
      );
    } catch (error, stackTrace) {
      if (sessionId != _playSessionId) return;
      _log.e(
        'app_state',
        'playback crashed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'wordbookId': _playingWordbookId,
          'scopeWords': words.length,
          'startIndex': safeStart,
        },
      );
      _setMessage(
        'errorInitFailed',
        params: <String, Object?>{'error': 'playback: $error'},
      );
      _clearPlaybackSession(notify: true);
    }
  }

  Future<void> pauseOrResume() async {
    if (!_isPlaying) {
      _log.w('app_state', 'pauseOrResume ignored because not playing');
      return;
    }
    _log.i(
      'app_state',
      _isPaused ? 'resume requested' : 'pause requested',
      data: <String, Object?>{
        'provider': _config.tts.provider.name,
        'currentUnit': _currentUnit,
        'totalUnits': _totalUnits,
      },
    );
    try {
      if (_isPaused) {
        await _playback.resume();
        _isPaused = false;
      } else {
        await _playback.pause();
        _isPaused = true;
      }
      notifyListeners();
    } catch (error, stackTrace) {
      _log.e(
        'app_state',
        'pauseOrResume failed',
        error: error,
        stackTrace: stackTrace,
      );
      _setMessage(
        'errorInitFailed',
        params: <String, Object?>{'error': 'pause/resume: $error'},
      );
      notifyListeners();
    }
  }

  Future<void> stop() async {
    _log.i(
      'app_state',
      'stop requested',
      data: <String, Object?>{
        'isPlaying': _isPlaying,
        'isPaused': _isPaused,
        'currentUnit': _currentUnit,
        'totalUnits': _totalUnits,
      },
    );
    try {
      _playSessionId += 1;
      await _playback.stop();
    } catch (error, stackTrace) {
      _log.e('app_state', 'stop failed', error: error, stackTrace: stackTrace);
    } finally {
      _clearPlaybackSession(notify: true);
    }
  }

  Future<void> skipCurrentWord() => _playback.skipCurrentWord();

  Future<void> playPreviousWord() async {
    final scopeWords = _scopeWords;
    if (scopeWords.isEmpty) return;
    final current = currentWord;
    final currentScopeIndex = current == null
        ? 0
        : _indexOfWordEntry(scopeWords, current);
    final safeIndex = currentScopeIndex < 0 ? 0 : currentScopeIndex;
    final nextScopeIndex =
        (safeIndex - 1 + scopeWords.length) % scopeWords.length;
    _setCurrentWordByEntry(scopeWords[nextScopeIndex]);
    resetTestModeProgress();
    _log.i(
      'app_state',
      'browse previous requested',
      data: <String, Object?>{
        'fromIndex': safeIndex,
        'toIndex': nextScopeIndex,
        'word': scopeWords[nextScopeIndex].word,
      },
    );
    notifyListeners();
  }

  Future<void> playNextWord() async {
    final scopeWords = _scopeWords;
    if (scopeWords.isEmpty) return;
    final current = currentWord;
    final currentScopeIndex = current == null
        ? 0
        : _indexOfWordEntry(scopeWords, current);
    final safeIndex = currentScopeIndex < 0 ? 0 : currentScopeIndex;
    final nextScopeIndex = (safeIndex + 1) % scopeWords.length;
    _setCurrentWordByEntry(scopeWords[nextScopeIndex]);
    resetTestModeProgress();
    _log.i(
      'app_state',
      'browse next requested',
      data: <String, Object?>{
        'fromIndex': safeIndex,
        'toIndex': nextScopeIndex,
        'word': scopeWords[nextScopeIndex].word,
      },
    );
    notifyListeners();
  }

  Future<void> jumpToPlayingWordbook() async {
    final playingId = _playingWordbookId;
    if (playingId == null) return;
    final target = _wordbooks
        .where((book) => book.id == playingId)
        .cast<Wordbook?>()
        .firstOrNull;
    if (target == null) return;
    final focusIndex = _playingScopeWords.isEmpty
        ? null
        : _playingScopeIndex.clamp(0, _playingScopeWords.length - 1);
    final focusEntry = focusIndex == null
        ? null
        : _playingScopeWords[focusIndex];
    final focusWord = focusEntry?.word ?? _playingWord;
    await selectWordbook(
      target,
      focusWord: focusWord,
      focusWordId: focusEntry?.id,
    );
    final hasFocusedEntry = focusEntry != null
        ? _scopeWords.any((item) => _isSameWordEntry(item, focusEntry))
        : (focusWord != null
              ? _scopeWords.any((item) => item.word == focusWord)
              : true);
    if (_searchQuery.trim().isNotEmpty && !hasFocusedEntry) {
      _searchQuery = '';
      await selectWordbook(
        target,
        focusWord: focusWord,
        focusWordId: focusEntry?.id,
      );
    }
  }

  Future<void> playCurrentWordbook() async {
    if (_selectedWordbook == null) return;
    if (_isPlaying) {
      await stop();
    }
    await play();
  }

  Future<void> movePlaybackPreviousWord() async {
    if (!_isPlaying || _playingScopeWords.isEmpty) return;
    final current = _playingScopeIndex.clamp(0, _playingScopeWords.length - 1);
    final target =
        (current - 1 + _playingScopeWords.length) % _playingScopeWords.length;
    await _restartPlaybackFromPlayingScope(target);
  }

  Future<void> movePlaybackNextWord() async {
    if (!_isPlaying || _playingScopeWords.isEmpty) return;
    final current = _playingScopeIndex.clamp(0, _playingScopeWords.length - 1);
    final target = (current + 1) % _playingScopeWords.length;
    await _restartPlaybackFromPlayingScope(target);
  }

  Future<void> _restartPlaybackFromPlayingScope(int targetIndex) async {
    _queuedPlaybackScopeTarget = targetIndex;
    if (_playbackScopeRestarting) {
      _log.d(
        'app_state',
        'restart playback queued',
        data: <String, Object?>{
          'queuedTarget': _queuedPlaybackScopeTarget,
          'playingScopeSize': _playingScopeWords.length,
        },
      );
      return;
    }
    _playbackScopeRestarting = true;
    try {
      while (_queuedPlaybackScopeTarget != null) {
        final pending = _queuedPlaybackScopeTarget!;
        _queuedPlaybackScopeTarget = null;
        await _restartPlaybackFromPlayingScopeInternal(pending);
        if (!_isPlaying) break;
      }
    } finally {
      _playbackScopeRestarting = false;
    }
  }

  Future<void> _restartPlaybackFromPlayingScopeInternal(int targetIndex) async {
    final playingId = _playingWordbookId;
    final playingName = _playingWordbookName;
    if (playingId == null ||
        playingName == null ||
        _playingScopeWords.isEmpty) {
      return;
    }
    final words = List<WordEntry>.from(_playingScopeWords);
    final safeTarget = targetIndex.clamp(0, words.length - 1);
    _log.i(
      'app_state',
      'restart playback from scope index',
      data: <String, Object?>{
        'wordbookId': playingId,
        'targetIndex': safeTarget,
        'targetWordId': words[safeTarget].id,
        'targetWord': words[safeTarget].word,
      },
    );
    _playingScopeIndex = safeTarget;
    _playingWord = words[safeTarget].word;
    if (_selectedWordbook?.id == playingId) {
      _setCurrentWordByEntry(words[safeTarget]);
      resetTestModeProgress();
      notifyListeners();
    }
    _playSessionId += 1;
    await _playback.stop();
    unawaited(
      _startPlaySession(
        scopeWords: words,
        startIndex: safeTarget,
        playingWordbookId: playingId,
        playingWordbookName: playingName,
      ),
    );
  }

  bool jumpByInitial(String initial) {
    final scopeWords = _scopeWords;
    if (scopeWords.isEmpty) return false;
    final index = findJumpIndexByInitial(scopeWords, initial);
    if (index < 0) return false;
    _setCurrentWordByEntry(scopeWords[index]);
    resetTestModeProgress();
    notifyListeners();
    return true;
  }

  bool jumpByPrefix(String rawPrefix) {
    final scopeWords = _scopeWords;
    if (scopeWords.isEmpty) return false;
    final index = findJumpIndexByPrefix(scopeWords, rawPrefix);
    if (index < 0) return false;
    _setCurrentWordByEntry(scopeWords[index]);
    resetTestModeProgress();
    notifyListeners();
    return true;
  }

  Future<void> setAmbientMasterVolume(double value) async {
    _ambient.setMasterVolume(value);
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
    final normalizedQuery = _normalizeSearchText(query);
    if (normalizedQuery.isEmpty) return words;
    final fuzzyPattern = _buildFuzzyPattern(normalizedQuery);

    return words
        .where((word) {
          final wordText = _normalizeSearchText(word.word);
          final meaningText = _normalizeSearchText(word.meaning ?? '');
          final detailsText = _normalizeSearchText(word.rawContent);
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
      (entry) => _wordInitialBucket(entry.word) == normalized,
    );
  }

  @visibleForTesting
  static int findJumpIndexByPrefix(List<WordEntry> scopedWords, String prefix) {
    final normalizedPrefix = _normalizeJumpText(prefix);
    if (normalizedPrefix.isEmpty) return -1;
    return scopedWords.indexWhere(
      (entry) => _normalizeJumpText(entry.word).startsWith(normalizedPrefix),
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

  static String _normalizeSearchText(String text) {
    var normalized = _foldLatinDiacritics(text.toLowerCase());
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized;
  }

  static String _normalizeJumpText(String text) {
    final normalized = _normalizeSearchText(text);
    return normalized.replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fff]+'), '');
  }

  static String _wordInitialBucket(String word) {
    final normalized = _normalizeJumpText(word);
    if (normalized.isEmpty) return '#';
    final first = normalized[0];
    final code = first.codeUnitAt(0);
    final isLatinLetter = code >= 97 && code <= 122;
    return isLatinLetter ? first.toUpperCase() : '#';
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

  static RegExp? _buildFuzzyPattern(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) return null;
    final compact = normalized.replaceAll(' ', '');
    if (compact.isEmpty) return null;
    final escaped = compact.split('').map(RegExp.escape).join('.*');
    return RegExp(escaped, caseSensitive: false);
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
      if (_currentWordIndex >= _words.length) {
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
    _weatherEnabled = _settings.loadWeatherEnabled();

    final testModeState = _settings.loadTestModeState();
    _testModeEnabled = testModeState['enabled'] ?? false;
    _testModeRevealed = testModeState['revealed'] ?? false;
    _testModeHintRevealed = testModeState['hintRevealed'] ?? false;

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

  bool _isWeatherStale() {
    final snapshot = _weatherSnapshot;
    if (snapshot == null) {
      return true;
    }
    return DateTime.now().difference(snapshot.fetchedAt) >=
        const Duration(minutes: 30);
  }

  void _clearPlaybackSession({required bool notify}) {
    _isPlaying = false;
    _isPaused = false;
    _currentUnit = 0;
    _totalUnits = 0;
    _activeUnit = null;
    _playingWordbookId = null;
    _playingWordbookName = null;
    _playingWord = null;
    _playingScopeWords = <WordEntry>[];
    _playingScopeIndex = 0;
    _queuedPlaybackScopeTarget = null;
    _playbackScopeRestarting = false;
    if (notify) {
      notifyListeners();
    }
  }

  void _loadPracticeDashboard() {
    final data = _settings.loadPracticeDashboard();
    _practiceDateKey = '${data['date'] ?? ''}'.trim();
    _practiceTodaySessions = _readPracticeInt(data['todaySessions']);
    _practiceTodayReviewed = _readPracticeInt(data['todayReviewed']);
    _practiceTodayRemembered = _readPracticeInt(data['todayRemembered']);
    _practiceTotalSessions = _readPracticeInt(data['totalSessions']);
    _practiceTotalReviewed = _readPracticeInt(data['totalReviewed']);
    _practiceTotalRemembered = _readPracticeInt(data['totalRemembered']);
    _practiceLastSessionTitle = '${data['lastSessionTitle'] ?? ''}'.trim();
    _practiceRememberedWords = _normalizePracticeWords(data['rememberedWords']);
    final rememberedSet = _practiceRememberedWords.toSet();
    _practiceWeakWords = _normalizePracticeWords(
      data['weakWords'],
    ).where((word) => !rememberedSet.contains(word)).toList(growable: false);
  }

  int _readPracticeInt(Object? value) {
    if (value is int) return value < 0 ? 0 : value;
    if (value is num) {
      final parsed = value.toInt();
      return parsed < 0 ? 0 : parsed;
    }
    return 0;
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
    _settings.savePracticeDashboard(<String, Object?>{
      'date': _practiceDateKey,
      'todaySessions': _practiceTodaySessions,
      'todayReviewed': _practiceTodayReviewed,
      'todayRemembered': _practiceTodayRemembered,
      'totalSessions': _practiceTotalSessions,
      'totalReviewed': _practiceTotalReviewed,
      'totalRemembered': _practiceTotalRemembered,
      'lastSessionTitle': _practiceLastSessionTitle,
      'rememberedWords': _practiceRememberedWords,
      'weakWords': _practiceWeakWords,
    });
  }

  List<WordEntry> _practiceEntriesFromWords(List<String> trackedWords) {
    if (trackedWords.isEmpty || _words.isEmpty) {
      return const <WordEntry>[];
    }
    final byWord = <String, WordEntry>{
      for (final item in _words) item.word.trim(): item,
    };
    final output = <WordEntry>[];
    for (final word in trackedWords) {
      final entry = byWord[word];
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
    if (tracked.isNotEmpty) {
      return tracked;
    }
    return _practiceEntriesFromWords(_practiceRememberedWords);
  }

  List<WordEntry> _memoryRecoveryEntries(List<WordEntry> words) {
    final tracked = MemoryLaneSelector.selectRecoveryEntries(
      words: words,
      progressByWordId: _wordMemoryProgressByWordId,
    );
    if (tracked.isNotEmpty) {
      return tracked;
    }
    return _practiceEntriesFromWords(_practiceWeakWords);
  }

  void _refreshWordMemoryProgressCache(List<WordEntry> words) {
    final wordIds = words
        .map((item) => item.id)
        .whereType<int>()
        .where((id) => id > 0);
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

  void _persistTestModeState() {
    _settings.saveTestModeState(
      enabled: _testModeEnabled,
      revealed: _testModeRevealed,
      hintRevealed: _testModeHintRevealed,
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

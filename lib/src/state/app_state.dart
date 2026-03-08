import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../i18n/app_i18n.dart';
import '../models/play_config.dart';
import '../models/word_entry.dart';
import '../models/word_field.dart';
import '../models/wordbook.dart';
import '../services/ambient_service.dart';
import '../services/app_log_service.dart';
import '../services/asr_service.dart';
import '../services/database_service.dart';
import '../services/playback_service.dart';
import '../services/settings_service.dart';

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

class AppState extends ChangeNotifier {
  AppState({
    required AppDatabaseService database,
    required SettingsService settings,
    required PlaybackService playback,
    required AmbientService ambient,
    required AsrService asr,
  }) : _database = database,
       _settings = settings,
       _playback = playback,
       _ambient = ambient,
       _asr = asr;

  final AppDatabaseService _database;
  final SettingsService _settings;
  final PlaybackService _playback;
  final AmbientService _ambient;
  final AsrService _asr;
  final AppLogService _log = AppLogService.instance;

  bool _initializing = false;
  bool _initialized = false;
  bool _busy = false;
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
  String _uiLanguage = 'zh';
  bool _testModeEnabled = false;
  bool _testModeRevealed = false;
  bool _testModeHintRevealed = false;
  String? _lastBackupPath;

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

  bool get initializing => _initializing;
  bool get initialized => _initialized;
  bool get busy => _busy;
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
  bool get testModeEnabled => _testModeEnabled;
  bool get testModeRevealed => _testModeRevealed;
  bool get testModeHintRevealed => _testModeHintRevealed;
  String? get lastBackupPath => _lastBackupPath;
  List<AmbientSource> get ambientSources => _ambient.sources;
  double get ambientMasterVolume => _ambient.masterVolume;

  List<WordEntry> get visibleWords =>
      filterWords(words: _words, query: _searchQuery, mode: _searchMode);

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

  Future<void> init() async {
    if (_initialized || _initializing) return;
    _initializing = true;
    _message = null;
    _log.i('app_state', 'init start');
    notifyListeners();

    try {
      await _database.init();
      _config = _settings.loadPlayConfig();
      _playback.updateRuntimeConfig(_config);
      _uiLanguage = AppI18n.normalizeLanguageCode(_settings.loadUiLanguage());
      final testModeState = _settings.loadTestModeState();
      _testModeEnabled = testModeState['enabled'] ?? false;
      _testModeRevealed = testModeState['revealed'] ?? false;
      _testModeHintRevealed = testModeState['hintRevealed'] ?? false;
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
          'logFile': logFilePath,
          'ttsProvider': _config.tts.provider.name,
          'ttsModel': _config.tts.model,
          'ttsVoice': _config.tts.activeVoice,
        },
      );
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
    if (normalized.isEmpty || normalized == _uiLanguage) return;
    _log.i(
      'app_state',
      'set ui language',
      data: <String, Object?>{'from': _uiLanguage, 'to': normalized},
    );
    _uiLanguage = normalized;
    _settings.saveUiLanguage(_uiLanguage);
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

  void setSearchQuery(String value) {
    _searchQuery = value;
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
    _selectedWordbook = wordbook;
    _words = _database.getWords(wordbook.id);
    _currentWordIndex = 0;
    if (focusWordId != null) {
      final index = _words.indexWhere((item) => item.id == focusWordId);
      if (index >= 0) {
        _currentWordIndex = index;
      }
    }
    if (_currentWordIndex == 0 &&
        focusWord != null &&
        focusWord.trim().isNotEmpty) {
      final index = _words.indexWhere((item) => item.word == focusWord.trim());
      if (index >= 0) {
        _currentWordIndex = index;
      }
    }
    _ensureCurrentWordInScope();
    resetTestModeProgress();
    notifyListeners();
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
      _database.deleteWordbook(wordbook.id);
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
    _setBusy(true);
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

    _setBusy(true);
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

  Future<void> saveWord({
    WordEntry? original,
    required String word,
    required List<WordFieldItem> fields,
    String rawContent = '',
  }) async {
    final selected = _selectedWordbook;
    if (selected == null) return;
    if (word.trim().isEmpty) {
      _setMessage('errorWordEmpty');
      notifyListeners();
      return;
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
    } catch (error) {
      _setMessage(
        'errorSaveWordFailed',
        params: <String, Object?>{'error': error},
      );
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

    try {
      if (_favorites.contains(word.word)) {
        _database.deleteWord(favoritesBook.id, word.word);
      } else {
        _database.upsertWord(favoritesBook.id, word.toPayload());
      }
      await _syncSpecialWordbooks();
      await _reloadWordbooks(keepCurrentSelection: true);
    } catch (error) {
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

    try {
      if (_taskWords.contains(word.word)) {
        _database.deleteWord(taskBook.id, word.word);
      } else {
        _database.upsertWord(taskBook.id, word.toPayload());
      }
      await _syncSpecialWordbooks();
      await _reloadWordbooks(keepCurrentSelection: true);
    } catch (error) {
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
    _setBusy(true);
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

  Future<void> removeAmbientSource(String sourceId) async {
    _ambient.removeSource(sourceId);
    await _ambient.syncPlayback();
    notifyListeners();
  }

  Future<void> previewPronunciation(String word) {
    return _playback.speakText(word, _config);
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

  Future<AsrResult> transcribeRecording(
    String audioPath, {
    String? expectedText,
    AsrProgressCallback? onProgress,
  }) {
    return _asr.transcribeFile(
      audioPath: audioPath,
      config: _config.asr,
      expectedText: expectedText,
      onProgress: onProgress,
    );
  }

  Future<String?> startAsrRecording() {
    return _asr.startRecording(provider: _config.asr.provider);
  }

  Future<String?> stopAsrRecording() {
    return _asr.stopRecording();
  }

  Future<void> cancelAsrRecording() => _asr.cancelRecording();

  void stopAsrProcessing() => _asr.stopOfflineRecognition();

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
          final fieldsText = _normalizeSearchText(
            word.fields.map((field) => field.asText()).join('\n'),
          );
          final compactWordText = wordText.replaceAll(' ', '');
          final compactFieldsText = fieldsText.replaceAll(' ', '');

          switch (mode) {
            case SearchMode.word:
              return wordText.contains(normalizedQuery);
            case SearchMode.meaning:
              return meaningText.contains(normalizedQuery) ||
                  fieldsText.contains(normalizedQuery);
            case SearchMode.fuzzy:
              if (fuzzyPattern == null) return false;
              return fuzzyPattern.hasMatch(compactWordText) ||
                  fuzzyPattern.hasMatch(compactFieldsText);
            case SearchMode.all:
              return wordText.contains(normalizedQuery) ||
                  meaningText.contains(normalizedQuery) ||
                  fieldsText.contains(normalizedQuery);
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
    _wordbooks = _database.getWordbooks();

    Wordbook? nextSelection;
    if (selectedId != null) {
      nextSelection = _wordbooks
          .where((book) => book.id == selectedId)
          .cast<Wordbook?>()
          .firstOrNull;
    }
    nextSelection ??= _wordbooks.isEmpty ? null : _wordbooks.first;
    _selectedWordbook = nextSelection;

    if (_selectedWordbook != null) {
      _words = _database.getWords(_selectedWordbook!.id);
      if (_currentWordIndex >= _words.length) {
        _currentWordIndex = _words.isEmpty ? 0 : (_words.length - 1);
      }
      _ensureCurrentWordInScope();
    } else {
      _words = <WordEntry>[];
      _currentWordIndex = 0;
    }
    notifyListeners();
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
      _database.setSetting('favorites', jsonEncode(_favorites.toList()));
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
      _database.setSetting('taskWords', jsonEncode(_taskWords.toList()));
    } else {
      _taskWords = <String>{};
    }
    notifyListeners();
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

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _log.i('app_state', 'dispose start');
    _playback.stop();
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

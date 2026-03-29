part of 'app_state.dart';

extension _AppStateStartup on AppState {
  Future<void> _initImpl() async {
    if (_initialized || _initializing) return;
    _initializing = true;
    _message = null;
    _log.i('app_state', 'init start');
    _notifyStateChanged();

    try {
      await _database.init();
      await _focusService.init();
      await _ambient.init();
      await _restoreDownloadedAmbientSounds();
      await _pollPendingTodoReminderLaunchImpl();
      _config = _settings.loadPlayConfig();
      _playback.updateRuntimeConfig(_config);
      final languageSetting = _settings.loadUiLanguage();
      if (languageSetting == SettingsService.uiLanguageSystem) {
        _uiLanguageFollowsSystem = true;
        _uiLanguage = AppState._resolveSystemUiLanguage();
      } else {
        _uiLanguageFollowsSystem = false;
        _uiLanguage = AppI18n.normalizeLanguageCode(languageSetting);
      }
      _rememberedWords = _settings.loadRememberedWords();
      _playbackProgressByWordbookPath = _settings
          .loadPlaybackProgressByWordbook();
      _startupPage = _settings.loadStartupPage();
      _focusStartupTab = _settings.loadFocusStartupTab();
      _studyStartupTab = _settings.loadStudyStartupTab();
      _weatherEnabled = _settings.loadWeatherEnabled();
      _startupTodoPromptEnabled = _settings.loadStartupTodoPromptEnabled();
      _startupTodoPromptSuppressedDate = _settings
          .loadStartupTodoPromptSuppressedDate();
      final testModeState = _settings.loadTestModeState();
      _testModeEnabled = testModeState.enabled;
      _testModeRevealed = testModeState.revealed;
      _testModeHintRevealed = testModeState.hintRevealed;
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
          'focusStartupTab': _focusStartupTab.storageValue,
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
      _remotePrewarmCompleted = _settings.loadRemoteResourcePrewarmCompleted();
    } catch (error) {
      _log.e('app_state', 'init failed', error: error);
      _setMessage('errorInitFailed', params: <String, Object?>{'error': error});
    } finally {
      _initializing = false;
      _notifyStateChanged();
    }
  }

  void _clearMessageImpl() {
    _message = null;
    _messageParams = const <String, Object?>{};
    _notifyStateChanged();
  }

  void _setUiLanguageImpl(String language) {
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
    _notifyStateChanged();
  }

  void _setUiLanguageFollowSystemImpl() {
    final resolved = AppState._resolveSystemUiLanguage();
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
    _notifyStateChanged();
  }

  void _setStartupPageImpl(AppHomeTab page) {
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
    _notifyStateChanged();
  }

  void _setFocusStartupTabImpl(FocusStartupTab tab) {
    if (_focusStartupTab == tab) return;
    _log.i(
      'app_state',
      'set focus startup tab',
      data: <String, Object?>{
        'from': _focusStartupTab.storageValue,
        'to': tab.storageValue,
      },
    );
    _focusStartupTab = tab;
    _settings.saveFocusStartupTab(tab);
    _notifyStateChanged();
  }

  void _setStudyStartupTabImpl(StudyStartupTab tab) {
    if (_studyStartupTab == tab) return;
    _log.i(
      'app_state',
      'set study startup tab',
      data: <String, Object?>{
        'from': _studyStartupTab.storageValue,
        'to': tab.storageValue,
      },
    );
    _studyStartupTab = tab;
    _settings.saveStudyStartupTab(tab);
    _notifyStateChanged();
  }

  void _setWeatherEnabledImpl(bool enabled) {
    if (_weatherEnabled == enabled) return;
    _weatherEnabled = enabled;
    _settings.saveWeatherEnabled(enabled);
    if (!enabled) {
      _notifyStateChanged();
      return;
    }
    _notifyStateChanged();
    unawaited(refreshWeather(force: true));
  }

  void _setStartupTodoPromptEnabledImpl(bool enabled) {
    if (_startupTodoPromptEnabled == enabled) {
      return;
    }
    _startupTodoPromptEnabled = enabled;
    _settings.saveStartupTodoPromptEnabled(enabled);
    _notifyStateChanged();
  }

  void _suppressStartupTodoPromptForTodayImpl() {
    final today = _todayDateKey();
    if (_startupTodoPromptSuppressedDate == today) {
      return;
    }
    _startupTodoPromptSuppressedDate = today;
    _settings.saveStartupTodoPromptSuppressedDate(today);
    _notifyStateChanged();
  }

  Future<void> _refreshStartupTodoPromptContentImpl({
    bool force = false,
  }) async {
    await Future.wait(<Future<void>>[
      _refreshStartupDailyQuoteImpl(force: force),
      _refreshWeatherSnapshotImpl(force: force),
    ]);
  }

  Future<void> _refreshWeatherImpl({bool force = false}) async {
    if (!_weatherEnabled) return;
    await _refreshWeatherSnapshotImpl(force: force);
  }

  void _refreshWeatherIfStaleImpl() {
    if (!_weatherEnabled || _weatherLoading || !_isWeatherStaleImpl()) {
      return;
    }
    unawaited(refreshWeather());
  }

  void _didChangeLocalesImpl(List<Locale>? locales) {
    if (!_uiLanguageFollowsSystem) return;
    final resolved = AppState._resolveSystemUiLanguage();
    if (_uiLanguage == resolved) return;
    _log.i(
      'app_state',
      'sync ui language from system locale change',
      data: <String, Object?>{'from': _uiLanguage, 'to': resolved},
    );
    _uiLanguage = resolved;
    _refreshLocalizedWordbookNames();
    _notifyStateChanged();
  }

  void _didChangeAppLifecycleStateImpl(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_pollPendingTodoReminderLaunchImpl());
    }
  }

  int? _consumePendingTodoReminderLaunchIdImpl() {
    final pending = _pendingTodoReminderLaunchId;
    _pendingTodoReminderLaunchId = null;
    return pending;
  }

  void _setTestModeEnabledImpl(bool enabled) {
    _testModeEnabled = enabled;
    _testModeRevealed = false;
    _testModeHintRevealed = false;
    _persistTestModeState();
    _notifyStateChanged();
  }

  void _toggleTestModeRevealImpl() {
    if (!_testModeEnabled) return;
    _testModeRevealed = !_testModeRevealed;
    _persistTestModeState();
    _notifyStateChanged();
  }

  void _toggleTestModeHintImpl() {
    if (!_testModeEnabled) return;
    _testModeHintRevealed = !_testModeHintRevealed;
    _persistTestModeState();
    _notifyStateChanged();
  }

  void _resetTestModeProgressImpl() {
    if (!_testModeEnabled) return;
    if (!_testModeRevealed && !_testModeHintRevealed) return;
    _testModeRevealed = false;
    _testModeHintRevealed = false;
    _persistTestModeState();
    _notifyStateChanged();
  }

  bool _isWeatherStaleImpl() {
    final snapshot = _weatherSnapshot;
    if (snapshot == null) {
      return true;
    }
    return DateTime.now().difference(snapshot.fetchedAt) >=
        const Duration(minutes: 30);
  }

  Future<void> _refreshWeatherSnapshotImpl({bool force = false}) async {
    if (_weatherLoading) return;
    if (!force && !_isWeatherStaleImpl()) return;

    _weatherLoading = true;
    _notifyStateChanged();
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
      _notifyStateChanged();
    }
  }

  Future<void> _refreshStartupDailyQuoteImpl({bool force = false}) async {
    if (_startupDailyQuoteLoading) {
      return;
    }
    final today = _todayDateKey();
    final hasFreshQuote =
        _startupDailyQuoteDateKey == today &&
        (_startupDailyQuote?.trim().isNotEmpty ?? false);
    if (!force && hasFreshQuote) {
      return;
    }

    _startupDailyQuoteLoading = true;
    _notifyStateChanged();
    try {
      _startupDailyQuote = await _dailyQuoteService.fetchQuote();
      _startupDailyQuoteDateKey = today;
    } catch (error) {
      _log.w(
        'app_state',
        'daily quote refresh failed',
        data: <String, Object?>{'error': '$error'},
      );
    } finally {
      _startupDailyQuoteLoading = false;
      _notifyStateChanged();
    }
  }

  Future<void> _pollPendingTodoReminderLaunchImpl() async {
    int? todoId;
    try {
      todoId = await _focusService.consumePendingTodoReminderLaunchId();
    } catch (error, stackTrace) {
      _log.e(
        'app_state',
        'pending todo reminder launch poll failed',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }
    if (todoId == null || todoId <= 0) {
      return;
    }
    if (_pendingTodoReminderLaunchId == todoId) {
      return;
    }
    _pendingTodoReminderLaunchId = todoId;
    _notifyStateChanged();
  }

  Future<void> _startRemoteResourcePrewarmImpl() async {
    final prewarm = _remoteResourcePrewarm;
    if (prewarm == null || _remotePrewarmActive || _remotePrewarmCompleted) {
      return;
    }
    _remotePrewarmActive = true;
    _remotePrewarmFailed = false;
    _remotePrewarmCompletedCount = 0;
    _remotePrewarmTotalCount = 0;
    _remotePrewarmCurrentLabel = '';
    _notifyStateChanged();
    try {
      await prewarm.prewarm(
        onProgress: (progress) {
          _remotePrewarmCompletedCount = progress.completed;
          _remotePrewarmTotalCount = progress.total;
          _remotePrewarmCurrentLabel = progress.currentLabel;
          _notifyStateChanged();
        },
      );
      _remotePrewarmCompleted = true;
      _settings.saveRemoteResourcePrewarmCompleted(true);
    } catch (error, stackTrace) {
      _remotePrewarmFailed = true;
      _log.e(
        'app_state',
        'remote resource prewarm failed',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _remotePrewarmActive = false;
      _notifyStateChanged();
    }
  }

  Future<void> _ensureRemoteResourcePrewarmOnDemandImpl() async {
    final prewarm = _remoteResourcePrewarm;
    if (prewarm == null || _remotePrewarmActive || _remotePrewarmCompleted) {
      return;
    }
    try {
      final shouldPrewarm = await prewarm.shouldPrewarmMusic();
      if (!shouldPrewarm) {
        _remotePrewarmCompleted = true;
        _settings.saveRemoteResourcePrewarmCompleted(true);
        _notifyStateChanged();
        return;
      }
    } catch (_) {
      // Keep lazy behavior if remote probe fails; actual download can still run later.
    }
    await _startRemoteResourcePrewarmImpl();
  }
}

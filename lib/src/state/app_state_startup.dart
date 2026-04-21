part of 'app_state.dart';

extension _AppStateStartup on AppState {
  Future<void> _initImpl() async {
    if (_initialized || _initializing) return;
    _initializing = true;
    _message = null;
    _notifyStateChanged();

    try {
      await _maintenanceRepository.init();
      _moduleToggleState = _settings.loadModuleToggleState();

      if (isModuleEnabled(ModuleIds.focus)) {
        await _focusService.init();
        await _pollPendingTodoReminderLaunchImpl();
      }

      final shouldInitAmbient =
          isModuleEnabled(ModuleIds.study) ||
          isModuleEnabled(ModuleIds.focus) ||
          isModuleEnabled(ModuleIds.toolbox);
      if (shouldInitAmbient) {
        await _ambient.init();
        await _restoreDownloadedAmbientSounds();
      }

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
      _ambientPresets = _settings.loadAmbientPresets();
      _playbackProgressByWordbookPath = _settings
          .loadPlaybackProgressByWordbook();
      _startupStore.syncPersistentStateFromSettings();
      _weatherStore.syncEnabledFromSettings();
      _testModeStore.syncFromSettings();
      _loadPracticeDashboard();
      _ensurePracticeDate(persist: true);
      if (isModuleEnabled(ModuleIds.toolboxSleepAssistant)) {
        await _loadSleepAssistantDataImpl();
      }
      await _reloadWordbooks(
        keepCurrentSelection: false,
        preloadSelectedWords: false,
      );
      await _syncSpecialWordbooks();
      _initialized = true;
      if (_weatherStore.enabled) {
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
    _uiLanguageFollowsSystem = true;
    _uiLanguage = resolved;
    _settings.saveUiLanguage(SettingsService.uiLanguageSystem);
    _refreshLocalizedWordbookNames();
    _notifyStateChanged();
  }

  void _setStartupPageImpl(AppHomeTab page) {
    _startupStore.setStartupPage(page);
  }

  void _setFocusStartupTabImpl(FocusStartupTab tab) {
    _startupStore.setFocusStartupTab(tab);
  }

  void _setStudyStartupTabImpl(StudyStartupTab tab) {
    _startupStore.setStudyStartupTab(tab);
  }

  void _setModuleEnabledImpl(String moduleId, bool enabled) {
    final descriptor = ModuleRegistry.find(moduleId);
    if (descriptor == null) {
      return;
    }
    if (!descriptor.canDisable && !enabled) {
      return;
    }
    if (_moduleToggleState.isEnabled(moduleId) == enabled) {
      return;
    }

    final previousState = _moduleToggleState;
    var next = _moduleToggleState.copyWithModule(moduleId, enabled);
    if (!enabled) {
      for (final child in ModuleRegistry.descriptors.where(
        (item) => item.parentId == moduleId,
      )) {
        next = next.copyWithModule(child.id, false);
      }
    } else {
      final parentId = descriptor.parentId;
      if (parentId != null && !next.isEnabled(parentId)) {
        next = next.copyWithModule(parentId, true);
      }
    }

    _moduleToggleState = next;
    _settings.saveModuleToggleState(next);
    _normalizeStartupPageForModuleToggles();
    _syncModuleRuntimeTransition(previous: previousState, next: next);

    if (!isModuleEnabled(ModuleIds.focus)) {
      _startupStore.setPendingTodoReminderLaunchId(null);
    }

    _notifyStateChanged();
  }

  void _normalizeStartupPageForModuleToggles() {
    if (isModuleEnabled(_moduleIdForHomeTab(_startupStore.startupPage))) {
      return;
    }
    for (final tab in const <AppHomeTab>[
      AppHomeTab.focus,
      AppHomeTab.study,
      AppHomeTab.practice,
      AppHomeTab.toolbox,
      AppHomeTab.more,
    ]) {
      if (!isModuleEnabled(_moduleIdForHomeTab(tab))) {
        continue;
      }
      _startupStore.setStartupPage(tab);
      return;
    }
  }

  String _moduleIdForHomeTab(AppHomeTab tab) {
    return switch (tab) {
      AppHomeTab.study => ModuleIds.study,
      AppHomeTab.practice => ModuleIds.practice,
      AppHomeTab.focus => ModuleIds.focus,
      AppHomeTab.toolbox => ModuleIds.toolbox,
      AppHomeTab.more => ModuleIds.more,
    };
  }

  bool _isAmbientRuntimeRequired(ModuleToggleState state) {
    final guard = ModuleRuntimeGuard(state);
    return guard.canAccess(ModuleIds.study) ||
        guard.canAccess(ModuleIds.focus) ||
        guard.canAccess(ModuleIds.toolbox);
  }

  void _syncModuleRuntimeTransition({
    required ModuleToggleState previous,
    required ModuleToggleState next,
  }) {
    final previousGuard = ModuleRuntimeGuard(previous);
    final nextGuard = ModuleRuntimeGuard(next);
    final wasStudyEnabled = previousGuard.canAccess(ModuleIds.study);
    final studyEnabled = nextGuard.canAccess(ModuleIds.study);
    if (wasStudyEnabled && !studyEnabled) {
      unawaited(stop());
    }

    final wasFocusEnabled = previousGuard.canAccess(ModuleIds.focus);
    final focusEnabled = nextGuard.canAccess(ModuleIds.focus);
    if (wasFocusEnabled && !focusEnabled) {
      _focusService.stop();
      _startupStore.setPendingTodoReminderLaunchId(null);
    } else if (!wasFocusEnabled && focusEnabled && _initialized) {
      unawaited(() async {
        await _focusService.init();
        await _pollPendingTodoReminderLaunchImpl();
        _notifyStateChanged();
      }());
    }

    final wasSleepAssistantEnabled = previousGuard.canAccess(
      ModuleIds.toolboxSleepAssistant,
    );
    final sleepAssistantEnabled = nextGuard.canAccess(
      ModuleIds.toolboxSleepAssistant,
    );
    if (wasSleepAssistantEnabled && !sleepAssistantEnabled) {
      _stopSleepRoutineImpl();
      _sleepNightRescueState = const SleepNightRescueState();
    } else if (!wasSleepAssistantEnabled &&
        sleepAssistantEnabled &&
        _initialized &&
        !_hasSleepAssistantDataLoaded()) {
      unawaited(_loadSleepAssistantDataImpl());
    }

    final wasAmbientRequired = _isAmbientRuntimeRequired(previous);
    final ambientRequired = _isAmbientRuntimeRequired(next);
    if (wasAmbientRequired && !ambientRequired) {
      _ambient.setEnabled(false);
      unawaited(_ambient.stopAll());
    } else if (!wasAmbientRequired && ambientRequired) {
      _ambient.setEnabled(true);
      if (_initialized) {
        unawaited(() async {
          await _ambient.init();
          await _restoreDownloadedAmbientSounds();
          _scheduleAmbientSync();
          _notifyStateChanged();
        }());
      }
    }
  }

  void _setStartupTodoPromptEnabledImpl(bool enabled) {
    _startupStore.setStartupTodoPromptEnabled(enabled);
  }

  void _suppressStartupTodoPromptForTodayImpl() {
    final today = _todayDateKey();
    _startupStore.suppressStartupTodoPromptForDate(today);
  }

  Future<void> _refreshStartupTodoPromptContentImpl({
    bool force = false,
  }) async {
    await Future.wait(<Future<void>>[
      _refreshStartupDailyQuoteImpl(force: force),
      _weatherStore.refresh(force: force, bypassEnabled: true),
    ]);
  }

  void _didChangeLocalesImpl(List<Locale>? locales) {
    if (!_uiLanguageFollowsSystem) return;
    final resolved = AppState._resolveSystemUiLanguage();
    if (_uiLanguage == resolved) return;
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
    return _startupStore.consumePendingTodoReminderLaunchId();
  }

  void _setTestModeEnabledImpl(bool enabled) {
    _testModeStore.setEnabled(enabled);
  }

  void _toggleTestModeRevealImpl() {
    _testModeStore.toggleReveal();
  }

  void _toggleTestModeHintImpl() {
    _testModeStore.toggleHint();
  }

  void _resetTestModeProgressImpl() {
    _testModeStore.resetProgress();
  }

  Future<void> _refreshStartupDailyQuoteImpl({bool force = false}) async {
    if (_startupStore.startupDailyQuoteLoading) {
      return;
    }
    final today = _todayDateKey();
    final hasFreshQuote =
        _startupStore.startupDailyQuoteDateKey == today &&
        (_startupStore.startupDailyQuote?.trim().isNotEmpty ?? false);
    if (!force && hasFreshQuote) {
      return;
    }

    _startupStore.setStartupDailyQuoteLoading(true);
    try {
      final quote = await _dailyQuoteService.fetchQuote();
      _startupStore.setStartupDailyQuote(quote: quote, dateKey: today);
    } catch (error) {
      _log.w(
        'app_state',
        'daily quote refresh failed',
        data: <String, Object?>{'error': '$error'},
      );
    } finally {
      _startupStore.setStartupDailyQuoteLoading(false);
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
    _startupStore.setPendingTodoReminderLaunchId(todoId);
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

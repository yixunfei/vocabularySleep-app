part of 'app_state.dart';

extension _AppStateSleep on AppState {
  bool _hasSleepAssistantDataLoaded() {
    return _sleepProfile != null ||
        _sleepCurrentPlan != null ||
        _sleepDailyLogs.isNotEmpty ||
        _sleepThoughtEntries.isNotEmpty ||
        _sleepNightEvents.isNotEmpty ||
        _sleepRoutineTemplates.isNotEmpty ||
        _sleepProgramProgress != null;
  }

  Future<void> _loadSleepAssistantDataImpl() async {
    if (_sleepLoading) {
      return;
    }
    _sleepLoading = true;
    _notifyStateChanged();
    try {
      _sleepProfile = _sleepRepository.loadSleepProfile();
      _sleepDailyLogs = _sortSleepDailyLogs(
        _sleepRepository.loadSleepDailyLogs(),
      );
      _sleepNightEvents = _sortSleepNightEvents(
        _sleepRepository.loadSleepNightEvents(),
      );
      _sleepThoughtEntries = _sortSleepThoughtEntries(
        _sleepRepository.loadSleepThoughtEntries(),
      );
      final loadedTemplates = _sleepRepository.loadSleepRoutineTemplates();
      _sleepRoutineTemplates = _mergeSleepRoutineDefaults(loadedTemplates);
      if (loadedTemplates.length != _sleepRoutineTemplates.length) {
        _sleepRepository.saveSleepRoutineTemplates(_sleepRoutineTemplates);
      }
      final activeTemplateId = _resolveSleepRoutineTemplateId(
        _sleepRepository.loadSleepActiveRoutineTemplateId(),
      );
      _sleepRoutineController.selectTemplate(
        _sleepRoutineTemplateById(activeTemplateId),
      );
      _sleepCurrentPlan = _sleepRepository.loadSleepCurrentPlan();
      _sleepDashboardState = _sleepRepository.loadSleepDashboardState();
      _sleepProgramProgress = _sleepRepository.loadSleepProgramProgress();
      final profile = _sleepProfile;
      if (_sleepCurrentPlan == null && profile != null) {
        _sleepCurrentPlan = _buildRecommendedSleepPlan(profile);
        _sleepRepository.saveSleepCurrentPlan(_sleepCurrentPlan);
      }
      // Keep an in-progress assessment intact when the sleep data is
      // refreshed while its editor is open. The saved profile is only a
      // baseline for a clean draft.
      if (profile != null && !_sleepAssessmentDraftDirty) {
        _sleepAssessmentDraft = SleepAssessmentDraftState(
          selectedIssues: profile.primaryIssues,
          typicalBedtime: profile.typicalBedtime,
          typicalWakeTime: profile.typicalWakeTime,
          hasRacingThoughts: profile.hasRacingThoughts,
          snoringRisk: profile.snoringRisk,
          caffeineSensitive: profile.caffeineSensitive,
          painImpactLevel: profile.painImpactLevel,
          stressLoadLevel: profile.stressLoadLevel,
          screenDependenceLevel: profile.screenDependenceLevel,
          lateWorkFrequency: profile.lateWorkFrequency,
          exerciseLateFrequency: profile.exerciseLateFrequency,
          bedroomLightIssue: profile.bedroomLightIssue,
          bedroomNoiseIssue: profile.bedroomNoiseIssue,
          bedroomTempIssue: profile.bedroomTempIssue,
          shiftWorkOrJetLag: profile.shiftWorkOrJetLag,
          refluxOrDigestiveDiscomfort: profile.refluxOrDigestiveDiscomfort,
          nightmaresOrDreamDistress: profile.nightmaresOrDreamDistress,
          goal: profile.goal,
        );
        _sleepAssessmentDraftDirty = false;
      }
    } finally {
      _sleepLoading = false;
      _notifyStateChanged();
    }
  }

  void _saveSleepProfileImpl(SleepProfile profile) {
    final now = DateTime.now();
    final normalized = profile.copyWith(
      createdAt: _sleepProfile?.createdAt ?? profile.createdAt,
      updatedAt: now,
    );
    final plan = _buildRecommendedSleepPlan(normalized);
    _sleepRepository.saveSleepProfile(normalized);
    _sleepRepository.saveSleepCurrentPlan(plan);
    _sleepProfile = normalized;
    _sleepAssessmentDraft = SleepAssessmentDraftState(
      selectedIssues: normalized.primaryIssues,
      typicalBedtime: normalized.typicalBedtime,
      typicalWakeTime: normalized.typicalWakeTime,
      hasRacingThoughts: normalized.hasRacingThoughts,
      snoringRisk: normalized.snoringRisk,
      caffeineSensitive: normalized.caffeineSensitive,
      painImpactLevel: normalized.painImpactLevel,
      stressLoadLevel: normalized.stressLoadLevel,
      screenDependenceLevel: normalized.screenDependenceLevel,
      lateWorkFrequency: normalized.lateWorkFrequency,
      exerciseLateFrequency: normalized.exerciseLateFrequency,
      bedroomLightIssue: normalized.bedroomLightIssue,
      bedroomNoiseIssue: normalized.bedroomNoiseIssue,
      bedroomTempIssue: normalized.bedroomTempIssue,
      shiftWorkOrJetLag: normalized.shiftWorkOrJetLag,
      refluxOrDigestiveDiscomfort: normalized.refluxOrDigestiveDiscomfort,
      nightmaresOrDreamDistress: normalized.nightmaresOrDreamDistress,
      goal: normalized.goal,
    );
    _sleepAssessmentDraftDirty = false;
    _sleepCurrentPlan = plan;
    _notifyStateChanged();
  }

  void _updateSleepAssessmentDraftImpl(SleepAssessmentDraftState draft) {
    _sleepAssessmentDraft = draft;
    _sleepAssessmentDraftDirty = true;
    // This in-memory draft is read when reopening the editor; its controls own
    // their visual state, so typing need not rebuild the rest of the app.
  }

  SleepDailyLog? _sleepDailyLogByDateKeyImpl(String dateKey) {
    final normalized = dateKey.trim();
    if (normalized.isEmpty) {
      return null;
    }
    for (final item in _sleepDailyLogs) {
      if (item.dateKey == normalized) {
        return item;
      }
    }
    return null;
  }

  void _saveSleepDailyLogImpl(SleepDailyLog log) {
    final currentLogs = _sleepDailyLogs.isEmpty
        ? _sleepRepository.loadSleepDailyLogs()
        : _sleepDailyLogs;
    final existing = currentLogs
        .where((item) => item.dateKey == log.dateKey)
        .cast<SleepDailyLog?>()
        .firstOrNull;
    final normalized = _normalizeSleepDailyLog(log, existing: existing);
    final next =
        currentLogs
            .where((item) => item.dateKey != normalized.dateKey)
            .toList(growable: true)
          ..add(normalized);
    final saved = _sortSleepDailyLogs(next).take(120).toList(growable: false);
    _sleepRepository.saveSleepDailyLogs(saved);
    _sleepDailyLogs = List.unmodifiable(saved);
    _notifyStateChanged();
  }

  void _saveSleepNightEventImpl(SleepNightEvent event) {
    // Night guidance can open before the daytime dashboard has loaded history.
    final currentEvents = _sleepNightEvents.isEmpty
        ? _sleepRepository.loadSleepNightEvents()
        : _sleepNightEvents;
    final normalized = SleepNightEvent(
      id: (event.id ?? '').trim().isEmpty ? _uuid.v4() : event.id,
      dateKey: event.dateKey,
      mode: event.mode,
      intent: event.intent,
      hasLeftBed: event.hasLeftBed,
      startedAt: event.startedAt,
      endedAt: event.endedAt,
      guessedTrigger: event.guessedTrigger,
      actionTaken: event.actionTaken,
      returnedToBedAt: event.returnedToBedAt,
      fellAsleepAgainAt: event.fellAsleepAgainAt,
      notes: event.notes,
    );
    final next =
        currentEvents
            .where((item) => item.id != normalized.id)
            .toList(growable: true)
          ..add(normalized);
    final saved = _sortSleepNightEvents(next).take(160).toList(growable: false);
    _sleepRepository.saveSleepNightEvents(saved);
    _sleepNightEvents = List.unmodifiable(saved);
    _notifyStateChanged();
  }

  void _saveSleepThoughtEntryImpl(SleepThoughtEntry entry) {
    final normalized = SleepThoughtEntry(
      id: (entry.id ?? '').trim().isEmpty ? _uuid.v4() : entry.id,
      dateKey: entry.dateKey,
      entryType: entry.entryType.trim(),
      content: entry.content.trim(),
      reframedContent: entry.reframedContent?.trim(),
      intensity: entry.intensity,
      deferredToDateKey: entry.deferredToDateKey?.trim(),
      createdAt: entry.createdAt ?? DateTime.now(),
    );
    final next = List<SleepThoughtEntry>.from(_sleepThoughtEntries)
      ..add(normalized);
    _sleepThoughtEntries = List.unmodifiable(
      _sortSleepThoughtEntries(next).take(240),
    );
    _sleepRepository.saveSleepThoughtEntries(_sleepThoughtEntries);
    _notifyStateChanged();
  }

  void _setSleepActiveRoutineTemplateImpl(String templateId) {
    final resolvedId = _resolveSleepRoutineTemplateId(templateId);
    if (_sleepRoutineRunnerState.activeTemplateId == resolvedId) {
      return;
    }
    _sleepRoutineController.selectTemplate(
      _sleepRoutineTemplateById(resolvedId),
    );
    _sleepRepository.saveSleepActiveRoutineTemplateId(resolvedId);
    _notifyStateChanged();
  }

  void _replaceSleepRoutineTemplatesImpl(List<SleepRoutineTemplate> templates) {
    final next = templates.isEmpty
        ? SleepRoutineTemplate.builtInDefaults()
        : templates.map(_normalizeSleepRoutineTemplate).toList(growable: false);
    _sleepRoutineTemplates = List.unmodifiable(next);
    final resolvedId = _resolveSleepRoutineTemplateId(
      _sleepRoutineRunnerState.activeTemplateId,
    );
    _sleepRoutineController.selectTemplate(
      _sleepRoutineTemplateById(resolvedId),
    );
    _sleepRepository.saveSleepRoutineTemplates(_sleepRoutineTemplates);
    _sleepRepository.saveSleepActiveRoutineTemplateId(resolvedId);
    _notifyStateChanged();
  }

  void _saveSleepRoutineTemplateImpl(SleepRoutineTemplate template) {
    final normalized = _normalizeSleepRoutineTemplate(template);
    final next =
        _sleepRoutineTemplates
            .where((item) => item.id != normalized.id)
            .toList(growable: true)
          ..add(normalized);
    next.sort((a, b) {
      if (a.builtIn != b.builtIn) {
        return a.builtIn ? -1 : 1;
      }
      return a.updatedAt.compareTo(b.updatedAt);
    });
    _sleepRoutineTemplates = List.unmodifiable(next);
    if (_sleepRoutineRunnerState.activeTemplateId == null) {
      _sleepRoutineController.selectTemplate(normalized);
      _sleepRepository.saveSleepActiveRoutineTemplateId(normalized.id);
    }
    _sleepRepository.saveSleepRoutineTemplates(_sleepRoutineTemplates);
    _notifyStateChanged();
  }

  void _deleteSleepRoutineTemplateImpl(String templateId) {
    final normalizedId = templateId.trim();
    if (normalizedId.isEmpty) {
      return;
    }
    final target = _sleepRoutineTemplates
        .where((item) => item.id == normalizedId)
        .cast<SleepRoutineTemplate?>()
        .firstOrNull;
    if (target == null || target.builtIn) {
      return;
    }
    _sleepRoutineTemplates = List.unmodifiable(
      _sleepRoutineTemplates.where((item) => item.id != normalizedId),
    );
    final resolvedId = _resolveSleepRoutineTemplateId(
      _sleepRoutineRunnerState.activeTemplateId == normalizedId
          ? null
          : _sleepRoutineRunnerState.activeTemplateId,
    );
    _sleepRoutineController.selectTemplate(
      _sleepRoutineTemplateById(resolvedId),
    );
    _sleepRepository.saveSleepRoutineTemplates(_sleepRoutineTemplates);
    _sleepRepository.saveSleepActiveRoutineTemplateId(resolvedId);
    _notifyStateChanged();
  }

  void _startSleepRoutineImpl([String? templateId]) {
    final resolvedId = _resolveSleepRoutineTemplateId(
      templateId ?? _sleepRoutineRunnerState.activeTemplateId,
    );
    final template = _sleepRoutineTemplates
        .where((item) => item.id == resolvedId)
        .cast<SleepRoutineTemplate?>()
        .firstOrNull;
    if (template == null || template.steps.isEmpty) {
      return;
    }
    _sleepRoutineController.start(template);
    _sleepRepository.saveSleepActiveRoutineTemplateId(template.id);
    _notifyStateChanged();
  }

  void _pauseSleepRoutineImpl() {
    if (!_sleepRoutineRunnerState.isRunning ||
        _sleepRoutineRunnerState.isPaused) {
      return;
    }
    _sleepRoutineController.pause();
    _notifyStateChanged();
  }

  void _resumeSleepRoutineImpl() {
    if (_sleepRoutineRunnerState.activeTemplateId == null ||
        !_sleepRoutineRunnerState.isPaused) {
      return;
    }
    _sleepRoutineController.resume();
    _notifyStateChanged();
  }

  void _advanceSleepRoutineImpl() {
    _sleepRoutineController.advance();
    _notifyStateChanged();
  }

  void _tickSleepRoutineImpl() {
    _sleepRoutineController.synchronize();
  }

  void _stopSleepRoutineImpl() {
    _sleepRoutineController.stop();
    _notifyStateChanged();
  }

  SleepRoutineTemplate? _sleepRoutineTemplateById(String? id) {
    return _sleepRoutineTemplates.where((item) => item.id == id).firstOrNull;
  }

  void _setSleepCurrentPlanImpl(SleepPlan? plan) {
    _sleepCurrentPlan = plan;
    _sleepRepository.saveSleepCurrentPlan(plan);
    _notifyStateChanged();
  }

  void _updateSleepDashboardStateImpl(SleepDashboardState state) {
    _sleepDashboardState = state;
    _sleepRepository.saveSleepDashboardState(state);
    _notifyStateChanged();
  }

  void _startSleepProgramImpl(SleepProgramType type) {
    _sleepProgramProgress = SleepProgramProgress(
      programType: type,
      startedAt: DateTime.now(),
      currentDay: 1,
      completedDays: <int>{},
      isCompleted: false,
    );
    _sleepRepository.saveSleepProgramProgress(_sleepProgramProgress);
    _notifyStateChanged();
  }

  void _completeSleepProgramDayImpl(int day) {
    final current = _sleepProgramProgress;
    if (current == null) {
      return;
    }
    final next = SleepDayProgram.complete(current, day, now: DateTime.now());
    if (identical(current, next)) return;
    _sleepRepository.saveSleepProgramProgress(next);
    _sleepProgramProgress = next;
    _notifyStateChanged();
  }

  void _startSleepNightRescueImpl(SleepNightRescueMode mode) {
    _sleepNightRescueState = SleepNightRescueState(
      mode: mode,
      startedAt: DateTime.now(),
      suggestedAction: _nightRescueActionForMode(mode),
      hasLeftBed: false,
    );
    _notifyStateChanged();
  }

  void _finishSleepNightRescueImpl({
    String? suggestedAction,
    bool hasLeftBed = false,
  }) {
    _sleepNightRescueState = _sleepNightRescueState.copyWith(
      suggestedAction: suggestedAction,
      hasLeftBed: hasLeftBed,
    );
    _notifyStateChanged();
  }

  SleepDailyLog _normalizeSleepDailyLog(
    SleepDailyLog log, {
    SleepDailyLog? existing,
  }) {
    final timeInBedMinutes =
        log.timeInBedMinutes ?? _minutesBetween(log.bedtimeAt, log.outOfBedAt);
    final estimatedSleepMinutes = log.estimatedTotalSleepMinutes;
    final efficiency =
        log.sleepEfficiency ??
        ((timeInBedMinutes == null ||
                timeInBedMinutes <= 0 ||
                estimatedSleepMinutes == null)
            ? null
            : (estimatedSleepMinutes / timeInBedMinutes).clamp(0.0, 1.0));
    return log.copyWith(
      id: existing?.id ?? log.id ?? _uuid.v4(),
      timeInBedMinutes: timeInBedMinutes,
      sleepEfficiency: efficiency,
      createdAt: existing?.createdAt ?? log.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  int? _minutesBetween(DateTime? start, DateTime? end) {
    if (start == null || end == null) {
      return null;
    }
    final minutes = end.difference(start).inMinutes;
    return minutes > 0 ? minutes : null;
  }

  String? _resolveSleepRoutineTemplateId(String? candidate) {
    final normalized = candidate?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      for (final template in _sleepRoutineTemplates) {
        if (template.id == normalized) {
          return normalized;
        }
      }
    }
    return _sleepRoutineTemplates.firstOrNull?.id;
  }

  List<SleepDailyLog> _sortSleepDailyLogs(Iterable<SleepDailyLog> items) {
    final list = items.toList(growable: false);
    list.sort((a, b) {
      final dateCompare = b.dateKey.compareTo(a.dateKey);
      if (dateCompare != 0) {
        return dateCompare;
      }
      final aUpdated =
          a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bUpdated =
          b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bUpdated.compareTo(aUpdated);
    });
    return List.unmodifiable(list);
  }

  List<SleepNightEvent> _sortSleepNightEvents(Iterable<SleepNightEvent> items) {
    final list = items.toList(growable: false);
    list.sort((a, b) {
      final aTime =
          a.startedAt ?? a.endedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime =
          b.startedAt ?? b.endedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return List.unmodifiable(list);
  }

  List<SleepRoutineTemplate> _mergeSleepRoutineDefaults(
    List<SleepRoutineTemplate> templates,
  ) {
    final defaults = SleepRoutineTemplate.builtInDefaults();
    if (templates.isEmpty) {
      return List.unmodifiable(defaults);
    }
    final next = List<SleepRoutineTemplate>.from(templates);
    final existingIds = templates.map((item) => item.id).toSet();
    for (final template in defaults) {
      if (!existingIds.contains(template.id)) {
        next.add(template);
      }
    }
    next.sort((a, b) {
      if (a.builtIn != b.builtIn) {
        return a.builtIn ? -1 : 1;
      }
      return a.updatedAt.compareTo(b.updatedAt);
    });
    return List.unmodifiable(next);
  }

  List<SleepThoughtEntry> _sortSleepThoughtEntries(
    Iterable<SleepThoughtEntry> items,
  ) {
    final list = items.toList(growable: false);
    list.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return List.unmodifiable(list);
  }

  SleepPlan _buildRecommendedSleepPlan(SleepProfile profile) {
    final track = _recommendSleepPlanTrack(profile);
    final startedAt = DateTime.now();
    return switch (track) {
      SleepPlanTrack.rhythmReset => SleepPlan(
        track: track,
        title: _sleepI18nText(
          'inline.plan296.state.app.state.sleep.rhythm_reset_plan.48bd2997db',
        ),
        summary: _sleepI18nText(
          'inline.plan296.state.app.state.sleep.stabilize_wake_time_morning_light_and.c714ec8d29',
        ),
        primaryActions: <String>[
          _sleepI18nText(
            'inline.plan296.state.app.state.sleep.keep_a_fixed_wake_time.d75ce57225',
          ),
          _sleepI18nText(
            'inline.plan296.state.app.state.sleep.get_daylight_soon_after_waking.50b9f89056',
          ),
          _sleepI18nText(
            'inline.plan296.state.app.state.sleep.dim_lights_earlier_at_night.0d195b4f5f',
          ),
        ],
        startedAt: startedAt,
      ),
      SleepPlanTrack.insomniaSupport => SleepPlan(
        track: track,
        title: _sleepI18nText(
          'inline.plan296.state.app.state.sleep.insomnia_support_plan.d465940b02',
        ),
        summary: _sleepI18nText(
          'inline.plan296.state.app.state.sleep.address_long_awake_time_in_bed.268241b5e6',
        ),
        primaryActions: <String>[
          _sleepI18nText(
            'inline.plan296.state.app.state.sleep.use_a_leave_bed_strategy_when.20b2abdf92',
          ),
          _sleepI18nText(
            'inline.plan296.state.app.state.sleep.start_a_sleep_diary.9d3c9fa1dc',
          ),
          _sleepI18nText(
            'inline.plan296.state.app.state.sleep.move_worry_work_into_daytime.a84b2e5f93',
          ),
        ],
        startedAt: startedAt,
      ),
      SleepPlanTrack.daytimeRecovery => SleepPlan(
        track: track,
        title: _sleepI18nText(
          'inline.plan296.state.app.state.sleep.daytime_recovery_plan.b5e3a87105',
        ),
        summary: _sleepI18nText(
          'inline.plan296.state.app.state.sleep.focus_on_daytime_behaviors_that_drag.27f8dabb02',
        ),
        primaryActions: <String>[
          _sleepI18nText(
            'inline.plan296.state.app.state.sleep.track_morning_energy.ac5f04ad18',
          ),
          _sleepI18nText(
            'inline.plan296.state.app.state.sleep.keep_naps_short.c1f5802b9a',
          ),
          _sleepI18nText(
            'inline.plan296.state.app.state.sleep.set_a_caffeine_cutoff.a104468d2c',
          ),
        ],
        startedAt: startedAt,
      ),
      SleepPlanTrack.environmentFix => SleepPlan(
        track: track,
        title: _sleepI18nText(
          'inline.plan296.state.app.state.sleep.environment_fix_plan.ad39ab85af',
        ),
        summary: _sleepI18nText(
          'inline.plan296.state.app.state.sleep.fix_the_most_obvious_bedroom_stressors.2d91017f83',
        ),
        primaryActions: <String>[
          _sleepI18nText(
            'inline.plan296.state.app.state.sleep.make_the_room_darker_and_cooler.aeb835e093',
          ),
          _sleepI18nText(
            'inline.plan296.state.app.state.sleep.keep_work_and_phones_away_from.6e0e962599',
          ),
          _sleepI18nText(
            'inline.plan296.state.app.state.sleep.track_which_conditions_trigger_awakenings.4706e59578',
          ),
        ],
        startedAt: startedAt,
      ),
      SleepPlanTrack.windDown => SleepPlan(
        track: track,
        title: _sleepI18nText(
          'inline.plan296.state.app.state.sleep.wind_down_plan.128f503a48',
        ),
        summary: _sleepI18nText(
          'inline.plan296.state.app.state.sleep.lower_bedtime_activation_with_a_softer.7c9773731a',
        ),
        primaryActions: <String>[
          _sleepI18nText(
            'inline.plan296.state.app.state.sleep.start_a_fixed_wind_down_routine.66d0db65c8',
          ),
          _sleepI18nText(
            'inline.plan296.state.app.state.sleep.unload_worries_and_tomorrow_tasks.4169a639ad',
          ),
          _sleepI18nText(
            'inline.plan296.state.app.state.sleep.use_gentle_breathing_instead_of_forcing.1271e4df64',
          ),
        ],
        startedAt: startedAt,
      ),
      SleepPlanTrack.observation => SleepPlan(
        track: track,
        title: _sleepI18nText(
          'inline.plan296.state.app.state.sleep.observation_plan.bfb8dc1f09',
        ),
        summary: _sleepI18nText(
          'inline.plan296.state.app.state.sleep.track_a_few_days_first_and.1b854706af',
        ),
        primaryActions: <String>[
          _sleepI18nText(
            'inline.plan296.state.app.state.sleep.log_3_to_7_days_first.c72938e96a',
          ),
          _sleepI18nText(
            'inline.plan296.state.app.state.sleep.track_evening_stimulation.f2a36b2060',
          ),
          _sleepI18nText(
            'inline.plan296.state.app.state.sleep.change_one_thing_at_a_time.a83deec89e',
          ),
        ],
        startedAt: startedAt,
      ),
    };
  }

  SleepPlanTrack _recommendSleepPlanTrack(SleepProfile profile) {
    final issues = profile.primaryIssues;
    if (issues.contains(SleepIssueType.irregularSchedule) ||
        profile.shiftWorkOrJetLag) {
      return SleepPlanTrack.rhythmReset;
    }
    if (issues.contains(SleepIssueType.difficultyFallingAsleep) ||
        issues.contains(SleepIssueType.frequentAwakenings) ||
        issues.contains(SleepIssueType.earlyAwakening)) {
      return SleepPlanTrack.insomniaSupport;
    }
    if (issues.contains(SleepIssueType.nonRestorativeSleep) ||
        issues.contains(SleepIssueType.daytimeSleepiness)) {
      return SleepPlanTrack.daytimeRecovery;
    }
    if (issues.contains(SleepIssueType.painOrTension) ||
        profile.painImpactLevel >= 3 ||
        profile.bedroomLightIssue ||
        profile.bedroomNoiseIssue ||
        profile.bedroomTempIssue ||
        profile.refluxOrDigestiveDiscomfort) {
      return SleepPlanTrack.environmentFix;
    }
    if (issues.contains(SleepIssueType.racingThoughts) ||
        profile.hasRacingThoughts ||
        profile.stressLoadLevel >= 3 ||
        profile.screenDependenceLevel >= 3 ||
        profile.lateWorkFrequency >= 3) {
      return SleepPlanTrack.windDown;
    }
    return SleepPlanTrack.observation;
  }

  String _nightRescueActionForMode(SleepNightRescueMode mode) {
    return switch (mode) {
      SleepNightRescueMode.briefAwakening => _sleepI18nText(
        'inline.plan296.state.app.state.sleep.keep_things_low_stim_and_give.45e2748ab8',
      ),
      SleepNightRescueMode.fullyAwake => _sleepI18nText(
        'inline.plan296.state.app.state.sleep.if_you_are_fully_awake_leave.85320bc1da',
      ),
      SleepNightRescueMode.racingThoughts => _sleepI18nText(
        'inline.plan296.state.app.state.sleep.stop_problem_solving_in_bed_park.0db7ce02de',
      ),
      SleepNightRescueMode.bodyActivated => _sleepI18nText(
        'inline.plan296.state.app.state.sleep.lower_body_activation_first_with_a.2a2cf6f0b0',
      ),
      SleepNightRescueMode.temperatureDiscomfort => _sleepI18nText(
        'inline.plan296.state.app.state.sleep.adjust_temperature_discomfort_first_then_decide.70907e4863',
      ),
    };
  }

  String _sleepI18nText(
    String key, {
    Map<String, Object?> params = const <String, Object?>{},
  }) {
    return AppI18n(_uiLanguage).t(key, params: params);
  }

  SleepRoutineTemplate _normalizeSleepRoutineTemplate(
    SleepRoutineTemplate template,
  ) {
    final sanitizedSteps = template.steps
        .where(
          (step) => step.label.trim().isNotEmpty && step.durationSeconds > 0,
        )
        .map(
          (step) => SleepRoutineStep(
            type: step.type,
            label: step.label.trim(),
            durationSeconds: math.max(30, step.durationSeconds),
            payload: step.payload,
          ),
        )
        .toList(growable: false);
    final totalMinutes = sanitizedSteps.isEmpty
        ? 0
        : (sanitizedSteps.fold<int>(
                    0,
                    (sum, step) => sum + step.durationSeconds,
                  ) /
                  60)
              .ceil();
    final id = template.id.trim().isEmpty ? _uuid.v4() : template.id.trim();
    final name = template.name.trim().isEmpty
        ? 'Custom routine'
        : template.name.trim();
    return SleepRoutineTemplate(
      id: id,
      name: name,
      totalMinutes: totalMinutes,
      steps: sanitizedSteps,
      builtIn: template.builtIn,
      updatedAt: DateTime.now(),
    );
  }
}

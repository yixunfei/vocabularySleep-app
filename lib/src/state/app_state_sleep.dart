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
      _sleepRoutineTemplates = _sleepRepository.loadSleepRoutineTemplates();
      if (_sleepRoutineTemplates.isEmpty) {
        _sleepRoutineTemplates = SleepRoutineTemplate.builtInDefaults();
        _sleepRepository.saveSleepRoutineTemplates(_sleepRoutineTemplates);
      }
      final activeTemplateId = _resolveSleepRoutineTemplateId(
        _sleepRepository.loadSleepActiveRoutineTemplateId(),
      );
      _sleepRoutineRunnerState = _sleepRoutineRunnerState.copyWith(
        activeTemplateId: activeTemplateId,
      );
      _sleepCurrentPlan = _sleepRepository.loadSleepCurrentPlan();
      _sleepDashboardState = _sleepRepository.loadSleepDashboardState();
      _sleepProgramProgress = _sleepRepository.loadSleepProgramProgress();
      final profile = _sleepProfile;
      if (_sleepCurrentPlan == null && profile != null) {
        _sleepCurrentPlan = _buildRecommendedSleepPlan(profile);
        _sleepRepository.saveSleepCurrentPlan(_sleepCurrentPlan);
      }
      if (profile != null) {
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
    _sleepCurrentPlan = _buildRecommendedSleepPlan(normalized);
    _sleepRepository.saveSleepProfile(normalized);
    _sleepRepository.saveSleepCurrentPlan(_sleepCurrentPlan);
    _notifyStateChanged();
  }

  void _updateSleepAssessmentDraftImpl(SleepAssessmentDraftState draft) {
    _sleepAssessmentDraft = draft;
    _notifyStateChanged();
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
    final existing = _sleepDailyLogs
        .where((item) => item.dateKey == log.dateKey)
        .cast<SleepDailyLog?>()
        .firstOrNull;
    final normalized = _normalizeSleepDailyLog(log, existing: existing);
    final next =
        _sleepDailyLogs
            .where((item) => item.dateKey != normalized.dateKey)
            .toList(growable: true)
          ..add(normalized);
    _sleepDailyLogs = _sortSleepDailyLogs(
      next,
    ).take(120).toList(growable: false);
    _sleepRepository.saveSleepDailyLogs(_sleepDailyLogs);
    _notifyStateChanged();
  }

  void _saveSleepNightEventImpl(SleepNightEvent event) {
    final normalized = SleepNightEvent(
      id: (event.id ?? '').trim().isEmpty ? _uuid.v4() : event.id,
      dateKey: event.dateKey,
      mode: event.mode,
      startedAt: event.startedAt,
      endedAt: event.endedAt,
      guessedTrigger: event.guessedTrigger,
      actionTaken: event.actionTaken,
      returnedToBedAt: event.returnedToBedAt,
      fellAsleepAgainAt: event.fellAsleepAgainAt,
      notes: event.notes,
    );
    final next = List<SleepNightEvent>.from(_sleepNightEvents)..add(normalized);
    _sleepNightEvents = _sortSleepNightEvents(
      next,
    ).take(160).toList(growable: false);
    _sleepRepository.saveSleepNightEvents(_sleepNightEvents);
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
    _sleepThoughtEntries = _sortSleepThoughtEntries(
      next,
    ).take(240).toList(growable: false);
    _sleepRepository.saveSleepThoughtEntries(_sleepThoughtEntries);
    _notifyStateChanged();
  }

  void _setSleepActiveRoutineTemplateImpl(String templateId) {
    final resolvedId = _resolveSleepRoutineTemplateId(templateId);
    if (_sleepRoutineRunnerState.activeTemplateId == resolvedId) {
      return;
    }
    _sleepRoutineRunnerState = _sleepRoutineRunnerState.copyWith(
      activeTemplateId: resolvedId,
      currentStepIndex: 0,
      remainingSeconds: 0,
      isRunning: false,
      isPaused: false,
      startedAt: null,
    );
    _sleepRepository.saveSleepActiveRoutineTemplateId(resolvedId);
    _notifyStateChanged();
  }

  void _replaceSleepRoutineTemplatesImpl(List<SleepRoutineTemplate> templates) {
    final next = templates.isEmpty
        ? SleepRoutineTemplate.builtInDefaults()
        : templates.map(_normalizeSleepRoutineTemplate).toList(growable: false);
    _sleepRoutineTemplates = next.toList(growable: false);
    final resolvedId = _resolveSleepRoutineTemplateId(
      _sleepRoutineRunnerState.activeTemplateId,
    );
    _sleepRoutineRunnerState = _sleepRoutineRunnerState.copyWith(
      activeTemplateId: resolvedId,
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
    _sleepRoutineTemplates = next.toList(growable: false);
    if (_sleepRoutineRunnerState.activeTemplateId == null) {
      _sleepRoutineRunnerState = _sleepRoutineRunnerState.copyWith(
        activeTemplateId: normalized.id,
      );
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
    _sleepRoutineTemplates = _sleepRoutineTemplates
        .where((item) => item.id != normalizedId)
        .toList(growable: false);
    final resolvedId = _resolveSleepRoutineTemplateId(
      _sleepRoutineRunnerState.activeTemplateId == normalizedId
          ? null
          : _sleepRoutineRunnerState.activeTemplateId,
    );
    _sleepRoutineRunnerState = _sleepRoutineRunnerState.copyWith(
      activeTemplateId: resolvedId,
      currentStepIndex: 0,
      remainingSeconds: 0,
      isRunning: false,
      isPaused: false,
      startedAt: null,
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
    _sleepRoutineRunnerState = SleepRoutineRunnerState(
      activeTemplateId: template.id,
      currentStepIndex: 0,
      remainingSeconds: template.steps.first.durationSeconds,
      isRunning: true,
      isPaused: false,
      startedAt: DateTime.now(),
    );
    _sleepRepository.saveSleepActiveRoutineTemplateId(template.id);
    _notifyStateChanged();
  }

  void _pauseSleepRoutineImpl() {
    if (!_sleepRoutineRunnerState.isRunning ||
        _sleepRoutineRunnerState.isPaused) {
      return;
    }
    _sleepRoutineRunnerState = _sleepRoutineRunnerState.copyWith(
      isPaused: true,
      isRunning: false,
    );
    _notifyStateChanged();
  }

  void _resumeSleepRoutineImpl() {
    if (_sleepRoutineRunnerState.activeTemplateId == null ||
        !_sleepRoutineRunnerState.isPaused) {
      return;
    }
    _sleepRoutineRunnerState = _sleepRoutineRunnerState.copyWith(
      isPaused: false,
      isRunning: true,
      startedAt: _sleepRoutineRunnerState.startedAt ?? DateTime.now(),
    );
    _notifyStateChanged();
  }

  void _advanceSleepRoutineImpl() {
    final template = activeSleepRoutineTemplate;
    if (template == null || template.steps.isEmpty) {
      _stopSleepRoutineImpl();
      return;
    }
    final nextIndex = _sleepRoutineRunnerState.currentStepIndex + 1;
    if (nextIndex >= template.steps.length) {
      _stopSleepRoutineImpl();
      return;
    }
    _sleepRoutineRunnerState = _sleepRoutineRunnerState.copyWith(
      currentStepIndex: nextIndex,
      remainingSeconds: template.steps[nextIndex].durationSeconds,
      isRunning: true,
      isPaused: false,
    );
    _notifyStateChanged();
  }

  void _tickSleepRoutineImpl() {
    if (!_sleepRoutineRunnerState.isRunning ||
        _sleepRoutineRunnerState.isPaused) {
      return;
    }
    final remaining = _sleepRoutineRunnerState.remainingSeconds;
    if (remaining <= 1) {
      _advanceSleepRoutineImpl();
      return;
    }
    _sleepRoutineRunnerState = _sleepRoutineRunnerState.copyWith(
      remainingSeconds: remaining - 1,
    );
    _notifyStateChanged();
  }

  void _stopSleepRoutineImpl() {
    _sleepRoutineRunnerState = _sleepRoutineRunnerState.copyWith(
      currentStepIndex: 0,
      remainingSeconds: 0,
      isRunning: false,
      isPaused: false,
      startedAt: null,
    );
    _notifyStateChanged();
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
    if (current == null || day <= 0) {
      return;
    }
    final completedDays = Set<int>.from(current.completedDays)..add(day);
    final targetDays = switch (current.programType) {
      SleepProgramType.sevenDayRhythmReset => 7,
      SleepProgramType.fourteenDaySleepReset => 14,
      SleepProgramType.insomniaStarter => 7,
    };
    _sleepProgramProgress = current.copyWith(
      currentDay: math.min(day + 1, targetDays),
      completedDays: completedDays,
      isCompleted: completedDays.length >= targetDays,
    );
    _sleepRepository.saveSleepProgramProgress(_sleepProgramProgress);
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
    return list;
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
    return list;
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
    return list;
  }

  SleepPlan _buildRecommendedSleepPlan(SleepProfile profile) {
    final track = _recommendSleepPlanTrack(profile);
    final startedAt = DateTime.now();
    return switch (track) {
      SleepPlanTrack.rhythmReset => SleepPlan(
        track: track,
        title: _sleepText(zh: '节律修复计划', en: 'Rhythm reset plan'),
        summary: _sleepText(
          zh: '先稳住起床、晨光和晚间减光，再慢慢把夜里的节奏拉回来。',
          en: 'Stabilize wake time, morning light, and evening dim-down first.',
        ),
        primaryActions: <String>[
          _sleepText(zh: '固定起床时间', en: 'Keep a fixed wake time'),
          _sleepText(zh: '醒来后尽快接触自然光', en: 'Get daylight soon after waking'),
          _sleepText(zh: '晚上提前减光', en: 'Dim lights earlier at night'),
        ],
        startedAt: startedAt,
      ),
      SleepPlanTrack.insomniaSupport => SleepPlan(
        track: track,
        title: _sleepText(zh: '失眠支持计划', en: 'Insomnia support plan'),
        summary: _sleepText(
          zh: '优先处理夜醒挣扎和床上清醒过久的问题，再看要不要收紧睡眠窗口。',
          en: 'Address long awake time in bed before adding stricter sleep work.',
        ),
        primaryActions: <String>[
          _sleepText(
            zh: '学习夜醒后的离床策略',
            en: 'Use a leave-bed strategy when fully awake',
          ),
          _sleepText(zh: '开始睡眠日记', en: 'Start a sleep diary'),
          _sleepText(zh: '把担忧移到白天处理', en: 'Move worry work into daytime'),
        ],
        startedAt: startedAt,
      ),
      SleepPlanTrack.daytimeRecovery => SleepPlan(
        track: track,
        title: _sleepText(zh: '白天恢复计划', en: 'Daytime recovery plan'),
        summary: _sleepText(
          zh: '重点看晨起恢复感、午后低谷和白天行为怎样拖累了夜里。',
          en: 'Focus on daytime behaviors that drag down the night.',
        ),
        primaryActions: <String>[
          _sleepText(zh: '记录晨起精神度', en: 'Track morning energy'),
          _sleepText(zh: '管理午睡时长', en: 'Keep naps short'),
          _sleepText(zh: '设定咖啡因截止时间', en: 'Set a caffeine cutoff'),
        ],
        startedAt: startedAt,
      ),
      SleepPlanTrack.environmentFix => SleepPlan(
        track: track,
        title: _sleepText(zh: '环境调整计划', en: 'Environment fix plan'),
        summary: _sleepText(
          zh: '先清掉卧室里最明显的刺激和不适，再看更细的习惯。',
          en: 'Fix the most obvious bedroom stressors first.',
        ),
        primaryActions: <String>[
          _sleepText(zh: '让卧室更暗更凉', en: 'Make the room darker and cooler'),
          _sleepText(
            zh: '把工作和手机移出床边',
            en: 'Keep work and phones away from bed',
          ),
          _sleepText(
            zh: '记录哪些环境更影响夜醒',
            en: 'Track which conditions trigger awakenings',
          ),
        ],
        startedAt: startedAt,
      ),
      SleepPlanTrack.windDown => SleepPlan(
        track: track,
        title: _sleepText(zh: '睡前减压计划', en: 'Wind-down plan'),
        summary: _sleepText(
          zh: '优先降低睡前唤醒水平，让脑子和身体都慢慢收下来。',
          en: 'Lower bedtime activation with a softer wind-down.',
        ),
        primaryActions: <String>[
          _sleepText(zh: '开始固定睡前流程', en: 'Start a fixed wind-down routine'),
          _sleepText(zh: '写下担忧和明日待办', en: 'Unload worries and tomorrow tasks'),
          _sleepText(
            zh: '用轻柔呼吸代替硬扛入睡',
            en: 'Use gentle breathing instead of forcing sleep',
          ),
        ],
        startedAt: startedAt,
      ),
      SleepPlanTrack.observation => SleepPlan(
        track: track,
        title: _sleepText(zh: '观察计划', en: 'Observation plan'),
        summary: _sleepText(
          zh: '先连续记录几天，找出真正拖累睡眠的主因。',
          en: 'Track a few days first and identify the main drag on sleep.',
        ),
        primaryActions: <String>[
          _sleepText(zh: '先记 3 到 7 天睡眠日志', en: 'Log 3 to 7 days first'),
          _sleepText(zh: '记录晚间刺激因素', en: 'Track evening stimulation'),
          _sleepText(zh: '不要一次改太多', en: 'Change one thing at a time'),
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
      SleepNightRescueMode.briefAwakening => _sleepText(
        zh: '先别加任务，保持低刺激，看看困意会不会自己回来。',
        en: 'Keep things low-stim and give the sleep drive a chance to return.',
      ),
      SleepNightRescueMode.fullyAwake => _sleepText(
        zh: '如果你明显越来越清醒，先离开床，去做一件枯燥又不刺激的事。',
        en: 'If you are fully awake, leave bed and do something calm and boring.',
      ),
      SleepNightRescueMode.racingThoughts => _sleepText(
        zh: '不要在床上继续解决问题，先把念头停放下来，再回到呼吸。',
        en: 'Stop problem-solving in bed, park the thoughts, then return to breathing.',
      ),
      SleepNightRescueMode.bodyActivated => _sleepText(
        zh: '先让身体降下来，做轻柔呼气或放松动作，不追求立刻睡着。',
        en: 'Lower body activation first with a softer exhale or a small release.',
      ),
      SleepNightRescueMode.temperatureDiscomfort => _sleepText(
        zh: '先处理冷热和不适，再决定要不要离床。',
        en: 'Adjust temperature discomfort first, then decide whether to leave bed.',
      ),
    };
  }

  String _sleepText({required String zh, required String en}) {
    return AppI18n.normalizeLanguageCode(_uiLanguage) == 'zh' ? zh : en;
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

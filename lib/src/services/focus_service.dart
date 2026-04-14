import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../i18n/app_i18n.dart';
import '../models/todo_item.dart';
import '../models/tomato_timer.dart';
import '../repositories/focus_repository.dart';
import 'ambient_service.dart';
import 'database_service.dart';
import 'reminder_service.dart';
import 'settings_service.dart';
import 'system_calendar_service.dart';
import 'todo_reminder_service.dart';
import 'tts_service.dart';

enum _PendingReminderFollowUp { none, startBreak, startFocus, completeSession }

class FocusService extends ChangeNotifier {
  FocusService(
    AppDatabaseService database, {
    FocusRepository? repository,
    SettingsService? settings,
    AmbientService? ambient,
    ReminderService? reminder,
    SystemCalendarService? systemCalendar,
    TodoReminderService? todoReminder,
    TtsService? tts,
  }) : this.fromRepository(
         repository: repository ?? DatabaseFocusRepository(database),
         settings: settings ?? SettingsService(database),
         ambient: ambient,
         reminder: reminder,
         systemCalendar:
             systemCalendar ?? PlatformSystemCalendarService(database),
         todoReminder: todoReminder,
         tts: tts,
       );

  FocusService.fromRepository({
    required FocusRepository repository,
    required SettingsService settings,
    AmbientService? ambient,
    ReminderService? reminder,
    SystemCalendarService? systemCalendar,
    TodoReminderService? todoReminder,
    TtsService? tts,
  }) : _repository = repository,
       _settings = settings,
       _ambient = ambient,
       _reminder = reminder,
       _systemCalendar = systemCalendar,
       _todoReminder = todoReminder ?? PlatformTodoReminderService(),
       _tts = tts;

  final FocusRepository _repository;
  final SettingsService _settings;
  final AmbientService? _ambient;
  final ReminderService? _reminder;
  final SystemCalendarService? _systemCalendar;
  final TodoReminderService _todoReminder;
  final TtsService? _tts;

  bool _initialized = false;
  bool _lockScreenActive = false;
  TomatoTimerConfig _timerConfig = const TomatoTimerConfig();
  TomatoTimerState _timerState = const TomatoTimerState();
  Timer? _timer;
  static const Duration _reminderAlertTimeout = Duration(seconds: 45);
  DateTime? _sessionStartTime;
  int _sessionDurationSeconds = 0;
  int _sessionFocusSeconds = 0;
  int _sessionBreakSeconds = 0;
  int _sessionRoundsCompleted = 0;
  TomatoTimerPhase? _pendingReminderPhase;
  _PendingReminderFollowUp _pendingReminderFollowUp =
      _PendingReminderFollowUp.none;
  int _pendingReminderRound = 0;
  void Function(TomatoTimerState)? _onTick;
  void Function(TomatoTimerPhase, int)? _onPhaseComplete;
  final ValueNotifier<TomatoTimerState> _timerStateNotifier =
      ValueNotifier<TomatoTimerState>(const TomatoTimerState());
  final ValueNotifier<int> _viewRevision = ValueNotifier<int>(0);
  List<TodoItem>? _todosCache;
  List<PlanNote>? _notesCache;
  _TodayStatsSnapshot? _todayStatsCache;

  TomatoTimerConfig get config => _timerConfig;
  TomatoTimerState get state => _timerState;
  bool get initialized => _initialized;
  bool get lockScreenActive => _lockScreenActive;
  bool get reminderAcknowledgementPending => _pendingReminderPhase != null;
  TomatoTimerPhase? get pendingReminderPhase => _pendingReminderPhase;
  ValueListenable<TomatoTimerState> get timerListenable => _timerStateNotifier;
  ValueListenable<int> get viewRevision => _viewRevision;

  Future<TodoReminderCapability> getTodoReminderCapability() {
    return _todoReminder.getCapability();
  }

  Future<bool> requestTodoReminderNotificationPermission() {
    return _todoReminder.requestNotificationPermission();
  }

  Future<void> openTodoReminderExactAlarmSettings() {
    return _todoReminder.openExactAlarmSettings();
  }

  Future<int?> consumePendingTodoReminderLaunchId() {
    return _todoReminder.consumePendingTodoLaunchId();
  }

  Future<TodoReminderLaunchAction?> consumePendingTodoReminderAction() {
    return _todoReminder.consumePendingTodoAction();
  }

  Future<void> init() async {
    _timerConfig = await _loadConfig();
    _initialized = true;
    _timerStateNotifier.value = _timerState;
    _bumpViewRevision();
    notifyListeners();
    unawaited(_syncAllTodoReminders());
  }

  Future<TomatoTimerConfig> _loadConfig() async {
    final map = <String, Object?>{};
    final focusSecondsStr = _repository.getSetting('tomato_focus_seconds');
    final breakSecondsStr = _repository.getSetting('tomato_break_seconds');
    final focusMinutesStr = _repository.getSetting('tomato_focus_minutes');
    final breakMinutesStr = _repository.getSetting('tomato_break_minutes');
    final roundsStr = _repository.getSetting('tomato_rounds');
    final autoBreakStr = _repository.getSetting('tomato_auto_start_break');
    final autoNextStr =
        _repository.getSetting('tomato_auto_start_next_round') ??
        _repository.getSetting('tomato_auto_start_next');
    final splitRatioStr = _repository.getSetting(
      'tomato_workspace_split_ratio',
    );
    final reminderStr = _repository.getSetting('tomato_reminder_config');

    if (focusSecondsStr != null) {
      map['focus_seconds'] = int.tryParse(focusSecondsStr);
    } else if (focusMinutesStr != null) {
      map['focus_minutes'] = int.tryParse(focusMinutesStr) ?? 25;
    }
    if (breakSecondsStr != null) {
      map['break_seconds'] = int.tryParse(breakSecondsStr);
    } else if (breakMinutesStr != null) {
      map['break_minutes'] = int.tryParse(breakMinutesStr) ?? 5;
    }
    if (roundsStr != null) {
      map['rounds'] = int.tryParse(roundsStr) ?? 4;
    }
    if (autoBreakStr != null) {
      map['auto_start_break'] = autoBreakStr == '1' ? 1 : 0;
    }
    if (autoNextStr != null) {
      map['auto_start_next_round'] = autoNextStr == '1' ? 1 : 0;
    }
    if (splitRatioStr != null) {
      map['workspace_split_ratio'] =
          double.tryParse(splitRatioStr) ??
          const TomatoTimerConfig().workspaceSplitRatio;
    }
    if (reminderStr != null && reminderStr.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(reminderStr);
        if (decoded is Map<String, Object?>) {
          map['reminder'] = decoded;
        } else if (decoded is Map) {
          map['reminder'] = decoded.cast<String, Object?>();
        }
      } catch (_) {
        // Ignore invalid reminder payloads and keep defaults.
      }
    }

    return TomatoTimerConfig.fromMap(map);
  }

  void saveConfig(TomatoTimerConfig config) {
    _timerConfig = config.copyWith(
      workspaceSplitRatio: config.normalizedWorkspaceSplitRatio,
    );
    _repository.setSetting(
      'tomato_focus_seconds',
      _timerConfig.focusDurationSeconds.toString(),
    );
    _repository.setSetting(
      'tomato_break_seconds',
      _timerConfig.breakDurationSeconds.toString(),
    );
    _repository.setSetting(
      'tomato_focus_minutes',
      _timerConfig.focusMinutes.toString(),
    );
    _repository.setSetting(
      'tomato_break_minutes',
      _timerConfig.breakMinutes.toString(),
    );
    _repository.setSetting('tomato_rounds', _timerConfig.rounds.toString());
    _repository.setSetting(
      'tomato_auto_start_break',
      _timerConfig.autoStartBreak ? '1' : '0',
    );
    _repository.setSetting(
      'tomato_auto_start_next',
      _timerConfig.autoStartNextRound ? '1' : '0',
    );
    _repository.setSetting(
      'tomato_auto_start_next_round',
      _timerConfig.autoStartNextRound ? '1' : '0',
    );
    _repository.setSetting(
      'tomato_workspace_split_ratio',
      _timerConfig.normalizedWorkspaceSplitRatio.toStringAsFixed(4),
    );
    _repository.setSetting(
      'tomato_reminder_config',
      jsonEncode(_timerConfig.reminder.toMap()),
    );
    _bumpViewRevision();
    notifyListeners();
  }

  void saveWorkspaceSplitRatio(double ratio) {
    saveConfig(_timerConfig.copyWith(workspaceSplitRatio: ratio));
  }

  void saveReminderConfig(TimerReminderConfig reminder) {
    saveConfig(_timerConfig.copyWith(reminder: reminder));
  }

  void setCallbacks({
    void Function(TomatoTimerState)? onTick,
    void Function(TomatoTimerPhase, int)? onPhaseComplete,
  }) {
    _onTick = onTick;
    _onPhaseComplete = onPhaseComplete;
  }

  void start({
    int? focusDurationSeconds,
    int? breakDurationSeconds,
    int? focusMinutes,
    int? breakMinutes,
    int? rounds,
  }) {
    _timer?.cancel();
    _clearPendingReminder();
    unawaited(_stopActiveReminder());
    final config = _timerConfig.copyWith(
      focusDurationSeconds:
          focusDurationSeconds ??
          (focusMinutes != null ? focusMinutes * 60 : null),
      breakDurationSeconds:
          breakDurationSeconds ??
          (breakMinutes != null ? breakMinutes * 60 : null),
      rounds: rounds,
    );
    _timerConfig = config;
    _sessionStartTime = DateTime.now();
    _sessionDurationSeconds = 0;
    _sessionFocusSeconds = 0;
    _sessionBreakSeconds = 0;
    _sessionRoundsCompleted = 0;

    _startFocusPhase(round: 1);
  }

  void _startFocusPhase({required int round}) {
    final totalSeconds = _timerConfig.focusDurationSeconds;
    _timerState = TomatoTimerState(
      phase: TomatoTimerPhase.focus,
      currentRound: round,
      remainingSeconds: totalSeconds,
      totalSeconds: totalSeconds,
      isPaused: false,
    );
    _publishState();
    _startTimer();
  }

  void _startBreakPhase({required int round, required int totalRounds}) {
    final isLongBreak = round > totalRounds;
    final totalSeconds = isLongBreak
        ? _timerConfig.breakDurationSeconds * 2
        : _timerConfig.breakDurationSeconds;
    _timerState = TomatoTimerState(
      phase: TomatoTimerPhase.breakTime,
      currentRound: round,
      remainingSeconds: totalSeconds,
      totalSeconds: totalSeconds,
      isPaused: false,
    );
    _publishState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_timerState.isActiveCountdown || _timerState.isPaused) return;

      final newRemaining = _timerState.remainingSeconds - 1;
      _sessionDurationSeconds += 1;
      if (_timerState.phase == TomatoTimerPhase.focus) {
        _sessionFocusSeconds += 1;
      } else if (_timerState.phase == TomatoTimerPhase.breakTime) {
        _sessionBreakSeconds += 1;
      }

      if (newRemaining <= 0) {
        _timerState = _timerState.copyWith(remainingSeconds: 0);
        _publishState();
        _handlePhaseComplete(triggerReminder: true);
      } else {
        _timerState = _timerState.copyWith(remainingSeconds: newRemaining);
        _publishState();
      }
    });
  }

  void _handlePhaseComplete({required bool triggerReminder}) {
    final phase = _timerState.phase;
    final round = _timerState.currentRound;
    final totalRounds = _timerConfig.rounds;
    final reminder = _timerConfig.reminder;
    final awaitReminderAcknowledgement =
        triggerReminder && _requiresReminderAcknowledgement(reminder);

    if (phase == TomatoTimerPhase.focus) {
      _sessionRoundsCompleted += 1;
    }

    if (awaitReminderAcknowledgement) {
      _queueReminderAcknowledgementState(
        phase: phase,
        round: round,
        totalRounds: totalRounds,
      );
      _onPhaseComplete?.call(phase, round);
      unawaited(_triggerReminder(phase, persistent: true));
      return;
    }

    if (triggerReminder) {
      unawaited(_triggerReminder(phase));
    }
    _onPhaseComplete?.call(phase, round);
    _applyCompletedPhase(phase: phase, round: round, totalRounds: totalRounds);
  }

  bool _requiresReminderAcknowledgement(TimerReminderConfig reminder) {
    return reminder.haptic || reminder.sound;
  }

  void _queueReminderAcknowledgementState({
    required TomatoTimerPhase phase,
    required int round,
    required int totalRounds,
  }) {
    _pendingReminderPhase = phase;
    switch (phase) {
      case TomatoTimerPhase.focus:
        _queueBreakPhase(round: round);
        _pendingReminderRound = round;
        _pendingReminderFollowUp = _timerConfig.autoStartBreak
            ? _PendingReminderFollowUp.startBreak
            : _PendingReminderFollowUp.none;
        return;
      case TomatoTimerPhase.breakTime:
        if (round < totalRounds) {
          _queueFocusPhase(round: round + 1);
          _pendingReminderRound = round + 1;
          _pendingReminderFollowUp = _timerConfig.autoStartNextRound
              ? _PendingReminderFollowUp.startFocus
              : _PendingReminderFollowUp.none;
          return;
        }
        _timer?.cancel();
        _timer = null;
        _timerState = _timerState.copyWith(isPaused: true);
        _pendingReminderRound = round;
        _pendingReminderFollowUp = _PendingReminderFollowUp.completeSession;
        _publishState();
        return;
      default:
        return;
    }
  }

  void _applyCompletedPhase({
    required TomatoTimerPhase phase,
    required int round,
    required int totalRounds,
  }) {
    if (phase == TomatoTimerPhase.focus) {
      if (_timerConfig.autoStartBreak) {
        _startBreakPhase(round: round, totalRounds: totalRounds);
      } else {
        _queueBreakPhase(round: round);
      }
      return;
    }

    if (phase == TomatoTimerPhase.breakTime) {
      if (round < totalRounds) {
        if (_timerConfig.autoStartNextRound) {
          _startFocusPhase(round: round + 1);
        } else {
          _queueFocusPhase(round: round + 1);
        }
      } else {
        _completeSession();
      }
    }
  }

  Future<void> acknowledgeReminder() async {
    await _stopActiveReminder();
    final followUp = _pendingReminderFollowUp;
    final round = _pendingReminderRound;
    _clearPendingReminder();
    switch (followUp) {
      case _PendingReminderFollowUp.none:
        return;
      case _PendingReminderFollowUp.startBreak:
        _startBreakPhase(round: round, totalRounds: _timerConfig.rounds);
        return;
      case _PendingReminderFollowUp.startFocus:
        _startFocusPhase(round: round);
        return;
      case _PendingReminderFollowUp.completeSession:
        _completeSession();
        return;
    }
  }

  Future<void> _triggerReminder(
    TomatoTimerPhase phase, {
    bool persistent = false,
  }) async {
    final reminder = _timerConfig.reminder;
    final systemLanguageTag = _resolveSystemLanguageTag();
    final i18n = AppI18n(_resolveSystemI18nLanguageCode(systemLanguageTag));
    final voiceMessage = _buildReminderVoiceMessage(
      i18n,
      phase,
      persistent: persistent,
    );

    if (reminder.pauseAmbient && _ambient != null) {
      try {
        await _ambient.stopAll();
      } catch (_) {
        // Best-effort reminder action.
      }
    }

    var handledPersistentAlert = false;
    if (persistent &&
        _reminder != null &&
        (reminder.haptic || reminder.sound)) {
      try {
        await _reminder.play(
          haptic: reminder.haptic,
          sound: reminder.sound,
          announcementText: reminder.voice ? voiceMessage : null,
          announcementLanguageTag: reminder.voice ? systemLanguageTag : null,
          duration: _reminderAlertTimeout,
        );
        handledPersistentAlert = true;
      } catch (_) {
        // Fall back to one-shot system feedback below.
      }
    }
    if (!handledPersistentAlert) {
      if (reminder.haptic) {
        try {
          await HapticFeedback.mediumImpact();
        } catch (_) {
          // Not supported on all platforms.
        }
      }

      if (reminder.sound) {
        try {
          await SystemSound.play(SystemSoundType.alert);
        } catch (_) {
          // Not supported on all platforms.
        }
      }
    }

    if (reminder.voice && _tts != null) {
      final voiceHandledNatively =
          persistent &&
          handledPersistentAlert &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android;
      if (voiceHandledNatively) {
        return;
      }
      try {
        await _tts.speak(
          voiceMessage,
          _settings.loadPlayConfig().tts.copyWith(language: systemLanguageTag),
        );
      } catch (_) {
        // Avoid breaking timer flow for reminder failures.
      }
    }
  }

  String _resolveSystemLanguageTag() {
    final tag = WidgetsBinding.instance.platformDispatcher.locale
        .toLanguageTag()
        .trim();
    if (tag.isEmpty) {
      return 'en';
    }
    return tag;
  }

  String _resolveSystemI18nLanguageCode(String languageTag) {
    final normalized = AppI18n.normalizeLanguageCode(languageTag);
    if (normalized.trim().isEmpty) {
      return 'en';
    }
    return normalized;
  }

  String _buildReminderVoiceMessage(
    AppI18n i18n,
    TomatoTimerPhase phase, {
    required bool persistent,
  }) {
    final round = _timerState.currentRound;
    final totalRounds = _timerConfig.rounds;
    final breakDuration = _formatReminderDuration(
      i18n,
      _timerConfig.breakDurationSeconds,
    );
    final focusDuration = _formatReminderDuration(
      i18n,
      _timerConfig.focusDurationSeconds,
    );

    if (phase == TomatoTimerPhase.focus) {
      final nextAction = persistent || !_timerConfig.autoStartBreak
          ? i18n.t('startBreak')
          : i18n.t('breakReady');
      return '${i18n.t('focusPhaseComplete')} ${i18n.t('roundProgress', params: <String, Object?>{'current': round, 'total': totalRounds})}. $nextAction. ${i18n.t('breakMinutes')}: $breakDuration.';
    }

    if (phase == TomatoTimerPhase.breakTime && round < totalRounds) {
      final nextRound = round + 1;
      final nextAction = persistent || !_timerConfig.autoStartNextRound
          ? i18n.t('startFocus')
          : i18n.t('focusReady');
      return '${i18n.t('breakPhaseComplete')} $nextAction. ${i18n.t('roundProgress', params: <String, Object?>{'current': nextRound, 'total': totalRounds})}. ${i18n.t('focusMinutesLabel')}: $focusDuration.';
    }

    final focusMinutes = (_sessionFocusSeconds / 60)
        .round()
        .clamp(0, 9999)
        .toString();
    final sessionMinutes = (_sessionDurationSeconds / 60)
        .round()
        .clamp(0, 9999)
        .toString();
    return '${i18n.t('breakPhaseComplete')} ${i18n.t('roundsLabel')}: $totalRounds. ${i18n.t('focusMinutesLabel')}: $focusMinutes ${i18n.t('minutesUnit')}. ${i18n.t('sessionMinutesLabel')}: $sessionMinutes ${i18n.t('minutesUnit')}.';
  }

  String _formatReminderDuration(AppI18n i18n, int seconds) {
    final minutes = (seconds / 60).round().clamp(1, 9999);
    return '$minutes ${i18n.t('minutesUnit')}';
  }

  void _queueBreakPhase({required int round}) {
    _timer?.cancel();
    final totalSeconds = _timerConfig.breakDurationSeconds;
    _timerState = TomatoTimerState(
      phase: TomatoTimerPhase.breakReady,
      currentRound: round,
      remainingSeconds: totalSeconds,
      totalSeconds: totalSeconds,
      isPaused: false,
    );
    _publishState();
  }

  void _queueFocusPhase({required int round}) {
    _timer?.cancel();
    final totalSeconds = _timerConfig.focusDurationSeconds;
    _timerState = TomatoTimerState(
      phase: TomatoTimerPhase.focusReady,
      currentRound: round,
      remainingSeconds: totalSeconds,
      totalSeconds: totalSeconds,
      isPaused: false,
    );
    _publishState();
  }

  void advanceToNextPhase() {
    if (reminderAcknowledgementPending) {
      return;
    }
    switch (_timerState.phase) {
      case TomatoTimerPhase.breakReady:
        _startBreakPhase(
          round: _timerState.currentRound,
          totalRounds: _timerConfig.rounds,
        );
        return;
      case TomatoTimerPhase.focusReady:
        _startFocusPhase(round: _timerState.currentRound);
        return;
      default:
        return;
    }
  }

  void _completeSession() {
    _timer?.cancel();
    _saveCurrentSessionRecord(partial: false);
    _clearPendingReminder();
    unawaited(_stopActiveReminder());
    _lockScreenActive = false;
    _timerState = const TomatoTimerState();
    _publishState();
    _resetSessionTracking();
  }

  void _saveCurrentSessionRecord({required bool partial}) {
    if (_sessionStartTime == null || _sessionDurationSeconds <= 0) {
      return;
    }
    final record = TomatoTimerRecord(
      startTime: _sessionStartTime!,
      durationMinutes: (_sessionDurationSeconds / 60).round(),
      focusDurationMinutes: (_sessionFocusSeconds / 60).round(),
      breakDurationMinutes: (_sessionBreakSeconds / 60).round(),
      roundsCompleted: _sessionRoundsCompleted,
      focusMinutes: _timerConfig.focusMinutes,
      breakMinutes: _timerConfig.breakMinutes,
      partial: partial,
    );
    _repository.insertTimerRecord(record);
    _invalidateTodayStatsCache();
    _bumpViewRevision();
  }

  void pause() {
    if (!_timerState.canPause) return;
    _timerState = _timerState.copyWith(isPaused: true);
    _publishState();
  }

  void pauseOrResume() {
    if (_timerState.isPaused) {
      resume();
      return;
    }
    pause();
  }

  void resume() {
    if (!_timerState.canResume) return;
    _timerState = _timerState.copyWith(isPaused: false);
    _publishState();
  }

  void setLockScreenActive(bool value) {
    if (_lockScreenActive == value) return;
    _lockScreenActive = value;
    _bumpViewRevision();
    notifyListeners();
  }

  void skip() {
    if (_timerState.phase == TomatoTimerPhase.idle) return;
    if (_timerState.isAwaitingManualTransition) {
      advanceToNextPhase();
      return;
    }
    _handlePhaseComplete(triggerReminder: false);
  }

  void stop({bool saveProgress = true}) {
    _timer?.cancel();
    if (saveProgress) {
      _saveCurrentSessionRecord(partial: true);
    }
    _clearPendingReminder();
    unawaited(_stopActiveReminder());
    _lockScreenActive = false;
    _timerState = const TomatoTimerState();
    _resetSessionTracking();
    _publishState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    unawaited(_stopActiveReminder());
    unawaited(_reminder?.dispose() ?? Future<void>.value());
    unawaited(_systemCalendar?.dispose() ?? Future<void>.value());
    unawaited(_todoReminder.dispose());
    _timerStateNotifier.dispose();
    _viewRevision.dispose();
    super.dispose();
  }

  List<TodoItem> getTodos() {
    if (!_initialized) return const <TodoItem>[];
    final cached = _todosCache;
    if (cached != null) {
      return cached;
    }
    final todos = List<TodoItem>.unmodifiable(_repository.getTodos());
    _todosCache = todos;
    return todos;
  }

  void addTodo(
    String content, {
    int priority = 1,
    String? category,
    String? note,
    String? color,
    DateTime? dueAt,
    bool alarmEnabled = false,
    bool syncToSystemCalendar = true,
    bool systemCalendarNotificationEnabled = true,
    int systemCalendarNotificationMinutesBefore = 0,
    bool systemCalendarAlarmEnabled = false,
    int systemCalendarAlarmMinutesBefore = 10,
  }) {
    if (!_initialized || content.trim().isEmpty) return;
    saveTodo(
      TodoItem(
        content: content.trim(),
        priority: priority,
        category: category?.trim().isNotEmpty == true ? category!.trim() : null,
        note: note?.trim().isNotEmpty == true ? note!.trim() : null,
        color: color,
        dueAt: dueAt,
        alarmEnabled: alarmEnabled && dueAt != null,
        syncToSystemCalendar: syncToSystemCalendar,
        systemCalendarNotificationEnabled: systemCalendarNotificationEnabled,
        systemCalendarNotificationMinutesBefore:
            systemCalendarNotificationMinutesBefore,
        systemCalendarAlarmEnabled: systemCalendarAlarmEnabled,
        systemCalendarAlarmMinutesBefore: systemCalendarAlarmMinutesBefore,
        createdAt: DateTime.now(),
      ),
    );
  }

  void saveTodo(TodoItem item) {
    if (!_initialized || item.content.trim().isEmpty) return;
    final normalized = _normalizeTodoItem(item);
    TodoItem persisted = normalized;
    if (normalized.id == null) {
      final inserted = normalized.copyWith(
        createdAt: normalized.createdAt ?? DateTime.now(),
      );
      final insertedId = _repository.insertTodo(inserted);
      persisted = inserted.copyWith(id: insertedId);
    } else {
      _repository.updateTodo(normalized);
    }
    _invalidateTodosCache();
    _bumpViewRevision();
    notifyListeners();
    _scheduleTodoReminderSync(persisted);
  }

  void updateTodo(TodoItem item) {
    if (!_initialized) return;
    final normalized = _normalizeTodoItem(item);
    _repository.updateTodo(normalized);
    _invalidateTodosCache();
    _bumpViewRevision();
    notifyListeners();
    _scheduleTodoReminderSync(normalized);
  }

  void toggleTodo(int id) {
    if (!_initialized) return;
    final item = _findTodoById(id);
    if (item == null) return;
    final updated = _normalizeTodoItem(
      item.copyWith(
        completed: !item.completed,
        deferred: false,
        completedAt: !item.completed ? DateTime.now() : null,
      ),
    );
    _repository.updateTodo(updated);
    _invalidateTodosCache();
    _bumpViewRevision();
    notifyListeners();
    _scheduleTodoReminderSync(updated);
  }

  TodoItem? _findTodoById(int id) {
    for (final item in getTodos()) {
      if (item.id == id) return item;
    }
    return null;
  }

  void deleteTodo(int id) {
    if (!_initialized) return;
    _repository.deleteTodo(id);
    _invalidateTodosCache();
    _bumpViewRevision();
    notifyListeners();
    _scheduleTodoReminderRemoval(id);
  }

  void completeTodo(int id) {
    if (!_initialized) return;
    final item = _findTodoById(id);
    if (item == null || item.completed) return;
    final updated = _normalizeTodoItem(
      item.copyWith(
        completed: true,
        deferred: false,
        completedAt: DateTime.now(),
      ),
    );
    _repository.updateTodo(updated);
    _invalidateTodosCache();
    _bumpViewRevision();
    notifyListeners();
    _scheduleTodoReminderSync(updated);
  }

  void snoozeTodoReminder(int id, Duration duration) {
    if (!_initialized) return;
    final item = _findTodoById(id);
    if (item == null || !item.hasReminder || item.completed) return;
    final nextDueAt = DateTime.now().add(duration);
    final updated = _normalizeTodoItem(
      item.copyWith(
        dueAt: nextDueAt,
        alarmEnabled: true,
        completed: false,
        deferred: false,
        completedAt: null,
      ),
    );
    _repository.updateTodo(updated);
    _invalidateTodosCache();
    _bumpViewRevision();
    notifyListeners();
    _scheduleTodoReminderSync(updated);
  }

  void clearCompletedTodos() {
    if (!_initialized) return;
    final completedIds = getTodos()
        .where((item) => item.completed && item.id != null)
        .map((item) => item.id!)
        .toList(growable: false);
    _repository.clearCompletedTodos();
    _invalidateTodosCache();
    _bumpViewRevision();
    notifyListeners();
    for (final id in completedIds) {
      _scheduleTodoReminderRemoval(id);
    }
  }

  void reorderTodos(List<TodoItem> orderedTodos) {
    if (!_initialized) return;
    final ids = <int>[];
    for (final todo in orderedTodos) {
      if (todo.id != null) {
        ids.add(todo.id!);
      }
    }
    if (ids.isEmpty) return;
    _repository.reorderTodos(ids);
    _invalidateTodosCache();
    _bumpViewRevision();
    notifyListeners();
  }

  List<PlanNote> getNotes() {
    if (!_initialized) return const <PlanNote>[];
    final cached = _notesCache;
    if (cached != null) {
      return cached;
    }
    final notes = List<PlanNote>.unmodifiable(_repository.getNotes());
    _notesCache = notes;
    return notes;
  }

  void addNote(String title, String? content, String? color) {
    if (!_initialized || title.trim().isEmpty) return;
    final now = DateTime.now();
    _repository.insertNote(
      PlanNote(
        title: title.trim(),
        content: content?.trim().isNotEmpty == true ? content!.trim() : null,
        color: color,
        createdAt: now,
        updatedAt: now,
      ),
    );
    _invalidateNotesCache();
    _bumpViewRevision();
    notifyListeners();
  }

  void updateNote(PlanNote note) {
    if (!_initialized) return;
    _repository.updateNote(note.copyWith(updatedAt: DateTime.now()));
    _invalidateNotesCache();
    _bumpViewRevision();
    notifyListeners();
  }

  void deleteNote(int id) {
    if (!_initialized) return;
    _repository.deleteNote(id);
    _invalidateNotesCache();
    _bumpViewRevision();
    notifyListeners();
  }

  void deleteNotes(List<int> ids) {
    if (!_initialized || ids.isEmpty) return;
    _repository.deleteNotes(ids);
    _invalidateNotesCache();
    _bumpViewRevision();
    notifyListeners();
  }

  void reorderNotes(List<PlanNote> orderedNotes) {
    if (!_initialized) return;
    final ids = <int>[];
    for (final note in orderedNotes) {
      if (note.id != null) {
        ids.add(note.id!);
      }
    }
    if (ids.isEmpty) return;
    _repository.reorderNotes(ids);
    _invalidateNotesCache();
    _bumpViewRevision();
    notifyListeners();
  }

  List<TomatoTimerRecord> getTimerRecords({int limit = 30}) {
    if (!_initialized) return const <TomatoTimerRecord>[];
    return _repository.getTimerRecords(limit: limit);
  }

  int getTodayFocusMinutes() {
    return _getTodayStatsSnapshot().focusMinutes;
  }

  int getTodaySessionMinutes() {
    return _getTodayStatsSnapshot().sessionMinutes;
  }

  int getTodayRoundsCompleted() {
    return _getTodayStatsSnapshot().roundsCompleted;
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  void _invalidateTodosCache() {
    _todosCache = null;
  }

  void _invalidateNotesCache() {
    _notesCache = null;
  }

  void _invalidateTodayStatsCache() {
    _todayStatsCache = null;
  }

  TodoItem _normalizeTodoItem(TodoItem item) {
    final useAlarm =
        item.systemCalendarAlertMode == TodoSystemCalendarAlertMode.alarm;
    return item.copyWith(
      content: item.content.trim(),
      deferred: item.completed ? false : item.deferred,
      category: (item.category ?? '').trim().isEmpty
          ? null
          : item.category!.trim(),
      note: (item.note ?? '').trim().isEmpty ? null : item.note!.trim(),
      dueAt: item.alarmEnabled ? item.dueAt : null,
      alarmEnabled: item.alarmEnabled && item.dueAt != null,
      syncToSystemCalendar: item.syncToSystemCalendar,
      systemCalendarNotificationEnabled: !useAlarm,
      systemCalendarNotificationMinutesBefore: item
          .systemCalendarNotificationMinutesBefore
          .clamp(0, 7 * 24 * 60)
          .toInt(),
      systemCalendarAlarmEnabled: useAlarm,
      systemCalendarAlarmMinutesBefore: item.systemCalendarAlarmMinutesBefore
          .clamp(0, 7 * 24 * 60)
          .toInt(),
      completedAt: item.completed ? item.completedAt : null,
    );
  }

  void _bumpViewRevision() {
    _viewRevision.value += 1;
  }

  Future<void> _syncAllTodoReminders() async {
    final systemCalendar = _systemCalendar;
    if (!_initialized) {
      return;
    }
    for (final todo in getTodos()) {
      await _todoReminder.syncTodo(todo);
      await systemCalendar?.syncTodo(todo);
    }
  }

  void _scheduleTodoReminderSync(TodoItem item) {
    if (item.id == null) {
      return;
    }
    unawaited(_todoReminder.syncTodo(item));
    final systemCalendar = _systemCalendar;
    if (systemCalendar != null) {
      unawaited(systemCalendar.syncTodo(item));
    }
  }

  void _scheduleTodoReminderRemoval(int todoId) {
    unawaited(_todoReminder.removeTodoReminder(todoId));
    final systemCalendar = _systemCalendar;
    if (systemCalendar != null) {
      unawaited(systemCalendar.removeTodoReminder(todoId));
    }
  }

  _TodayStatsSnapshot _getTodayStatsSnapshot() {
    final today = DateTime.now();
    final dayKey = _dayKey(today);
    final cached = _todayStatsCache;
    if (!_initialized) {
      return _TodayStatsSnapshot.empty(dayKey);
    }
    if (cached != null && cached.dayKey == dayKey) {
      return cached;
    }
    final records = getTimerRecords(limit: 100);
    var focusMinutes = 0;
    var sessionMinutes = 0;
    var roundsCompleted = 0;
    for (final record in records) {
      if (!_isSameDay(record.startTime, today)) {
        continue;
      }
      focusMinutes += record.focusDurationMinutes;
      sessionMinutes += record.durationMinutes;
      roundsCompleted += record.roundsCompleted;
    }
    final snapshot = _TodayStatsSnapshot(
      dayKey: dayKey,
      focusMinutes: focusMinutes,
      sessionMinutes: sessionMinutes,
      roundsCompleted: roundsCompleted,
    );
    _todayStatsCache = snapshot;
    return snapshot;
  }

  String _dayKey(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  void _publishState() {
    _onTick?.call(_timerState);
    _timerStateNotifier.value = _timerState;
  }

  Future<void> _stopActiveReminder() async {
    try {
      await _reminder?.stop();
    } catch (_) {
      // Best-effort cleanup for reminder playback.
    }
  }

  void _clearPendingReminder() {
    _pendingReminderPhase = null;
    _pendingReminderRound = 0;
    _pendingReminderFollowUp = _PendingReminderFollowUp.none;
  }

  void _resetSessionTracking() {
    _sessionStartTime = null;
    _sessionDurationSeconds = 0;
    _sessionFocusSeconds = 0;
    _sessionBreakSeconds = 0;
    _sessionRoundsCompleted = 0;
  }
}

class _TodayStatsSnapshot {
  const _TodayStatsSnapshot({
    required this.dayKey,
    required this.focusMinutes,
    required this.sessionMinutes,
    required this.roundsCompleted,
  });

  factory _TodayStatsSnapshot.empty(String dayKey) {
    return _TodayStatsSnapshot(
      dayKey: dayKey,
      focusMinutes: 0,
      sessionMinutes: 0,
      roundsCompleted: 0,
    );
  }

  final String dayKey;
  final int focusMinutes;
  final int sessionMinutes;
  final int roundsCompleted;
}

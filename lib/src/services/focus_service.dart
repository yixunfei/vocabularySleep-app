import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../i18n/app_i18n.dart';
import '../models/todo_item.dart';
import '../models/tomato_timer.dart';
import 'ambient_service.dart';
import 'database_service.dart';
import 'settings_service.dart';
import 'tts_service.dart';

class FocusService extends ChangeNotifier {
  FocusService(
    AppDatabaseService database, {
    SettingsService? settings,
    AmbientService? ambient,
    TtsService? tts,
  }) : _database = database,
       _settings = settings ?? SettingsService(database),
       _ambient = ambient,
       _tts = tts;

  final AppDatabaseService _database;
  final SettingsService _settings;
  final AmbientService? _ambient;
  final TtsService? _tts;

  bool _initialized = false;
  bool _lockScreenActive = false;
  TomatoTimerConfig _timerConfig = const TomatoTimerConfig();
  TomatoTimerState _timerState = const TomatoTimerState();
  Timer? _timer;
  DateTime? _sessionStartTime;
  int _sessionDurationSeconds = 0;
  int _sessionFocusSeconds = 0;
  int _sessionBreakSeconds = 0;
  int _sessionRoundsCompleted = 0;
  void Function(TomatoTimerState)? _onTick;
  void Function(TomatoTimerPhase, int)? _onPhaseComplete;

  TomatoTimerConfig get config => _timerConfig;
  TomatoTimerState get state => _timerState;
  bool get initialized => _initialized;
  bool get lockScreenActive => _lockScreenActive;

  Future<void> init() async {
    _timerConfig = await _loadConfig();
    _initialized = true;
    notifyListeners();
  }

  Future<TomatoTimerConfig> _loadConfig() async {
    final map = <String, Object?>{};
    final focusSecondsStr = _database.getSetting('tomato_focus_seconds');
    final breakSecondsStr = _database.getSetting('tomato_break_seconds');
    final focusMinutesStr = _database.getSetting('tomato_focus_minutes');
    final breakMinutesStr = _database.getSetting('tomato_break_minutes');
    final roundsStr = _database.getSetting('tomato_rounds');
    final autoBreakStr = _database.getSetting('tomato_auto_start_break');
    final autoNextStr =
        _database.getSetting('tomato_auto_start_next_round') ??
        _database.getSetting('tomato_auto_start_next');
    final splitRatioStr = _database.getSetting('tomato_workspace_split_ratio');
    final reminderStr = _database.getSetting('tomato_reminder_config');

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
    _database.setSetting(
      'tomato_focus_seconds',
      _timerConfig.focusDurationSeconds.toString(),
    );
    _database.setSetting(
      'tomato_break_seconds',
      _timerConfig.breakDurationSeconds.toString(),
    );
    _database.setSetting(
      'tomato_focus_minutes',
      _timerConfig.focusMinutes.toString(),
    );
    _database.setSetting(
      'tomato_break_minutes',
      _timerConfig.breakMinutes.toString(),
    );
    _database.setSetting('tomato_rounds', _timerConfig.rounds.toString());
    _database.setSetting(
      'tomato_auto_start_break',
      _timerConfig.autoStartBreak ? '1' : '0',
    );
    _database.setSetting(
      'tomato_auto_start_next',
      _timerConfig.autoStartNextRound ? '1' : '0',
    );
    _database.setSetting(
      'tomato_auto_start_next_round',
      _timerConfig.autoStartNextRound ? '1' : '0',
    );
    _database.setSetting(
      'tomato_workspace_split_ratio',
      _timerConfig.normalizedWorkspaceSplitRatio.toStringAsFixed(4),
    );
    _database.setSetting(
      'tomato_reminder_config',
      jsonEncode(_timerConfig.reminder.toMap()),
    );
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

    if (triggerReminder) {
      unawaited(_triggerReminder(phase));
    }
    _onPhaseComplete?.call(phase, round);

    if (phase == TomatoTimerPhase.focus) {
      _sessionRoundsCompleted += 1;
      if (_timerConfig.autoStartBreak) {
        _startBreakPhase(round: round, totalRounds: totalRounds);
      } else {
        _queueBreakPhase(round: round);
      }
    } else if (phase == TomatoTimerPhase.breakTime) {
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

  Future<void> _triggerReminder(TomatoTimerPhase phase) async {
    final reminder = _timerConfig.reminder;

    if (reminder.pauseAmbient && _ambient != null) {
      try {
        await _ambient.stopAll();
      } catch (_) {
        // Best-effort reminder action.
      }
    }

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

    if (reminder.voice && _tts != null) {
      final language = AppI18n.normalizeLanguageCode(
        _database.getSetting('uiLanguage') ?? 'en',
      );
      final i18n = AppI18n(language);
      final message = phase == TomatoTimerPhase.focus
          ? i18n.t('focusPhaseComplete')
          : i18n.t('breakPhaseComplete');
      try {
        await _tts.speak(message, _settings.loadPlayConfig().tts);
      } catch (_) {
        // Avoid breaking timer flow for reminder failures.
      }
    }
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
    _database.insertTimerRecord(record);
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
    _lockScreenActive = false;
    _timerState = const TomatoTimerState();
    _resetSessionTracking();
    _publishState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  List<TodoItem> getTodos() {
    if (!_initialized) return const <TodoItem>[];
    return _database.getTodos();
  }

  void addTodo(
    String content, {
    int priority = 1,
    String? category,
    String? note,
    String? color,
    DateTime? dueAt,
    bool alarmEnabled = false,
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
        createdAt: DateTime.now(),
      ),
    );
  }

  void saveTodo(TodoItem item) {
    if (!_initialized || item.content.trim().isEmpty) return;
    final normalized = item.copyWith(
      content: item.content.trim(),
      category: (item.category ?? '').trim().isEmpty
          ? null
          : item.category!.trim(),
      note: (item.note ?? '').trim().isEmpty ? null : item.note!.trim(),
      dueAt: item.alarmEnabled ? item.dueAt : null,
      alarmEnabled: item.alarmEnabled && item.dueAt != null,
    );
    if (normalized.id == null) {
      _database.insertTodo(
        normalized.copyWith(createdAt: normalized.createdAt ?? DateTime.now()),
      );
    } else {
      _database.updateTodo(normalized);
    }
    notifyListeners();
  }

  void updateTodo(TodoItem item) {
    if (!_initialized) return;
    _database.updateTodo(item);
    notifyListeners();
  }

  void toggleTodo(int id) {
    if (!_initialized) return;
    final item = _findTodoById(id);
    if (item == null) return;
    _database.updateTodo(
      item.copyWith(
        completed: !item.completed,
        completedAt: !item.completed ? DateTime.now() : null,
      ),
    );
    notifyListeners();
  }

  TodoItem? _findTodoById(int id) {
    for (final item in getTodos()) {
      if (item.id == id) return item;
    }
    return null;
  }

  void deleteTodo(int id) {
    if (!_initialized) return;
    _database.deleteTodo(id);
    notifyListeners();
  }

  void clearCompletedTodos() {
    if (!_initialized) return;
    _database.clearCompletedTodos();
    notifyListeners();
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
    _database.reorderTodos(ids);
    notifyListeners();
  }

  List<PlanNote> getNotes() {
    if (!_initialized) return const <PlanNote>[];
    return _database.getNotes();
  }

  void addNote(String title, String? content, String? color) {
    if (!_initialized || title.trim().isEmpty) return;
    final now = DateTime.now();
    _database.insertNote(
      PlanNote(
        title: title.trim(),
        content: content?.trim().isNotEmpty == true ? content!.trim() : null,
        color: color,
        createdAt: now,
        updatedAt: now,
      ),
    );
    notifyListeners();
  }

  void updateNote(PlanNote note) {
    if (!_initialized) return;
    _database.updateNote(note.copyWith(updatedAt: DateTime.now()));
    notifyListeners();
  }

  void deleteNote(int id) {
    if (!_initialized) return;
    _database.deleteNote(id);
    notifyListeners();
  }

  void deleteNotes(List<int> ids) {
    if (!_initialized || ids.isEmpty) return;
    _database.deleteNotes(ids);
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
    _database.reorderNotes(ids);
    notifyListeners();
  }

  List<TomatoTimerRecord> getTimerRecords({int limit = 30}) {
    if (!_initialized) return const <TomatoTimerRecord>[];
    return _database.getTimerRecords(limit: limit);
  }

  int getTodayFocusMinutes() {
    if (!_initialized) return 0;
    final today = DateTime.now();
    final records = getTimerRecords(limit: 100);
    var totalMinutes = 0;
    for (final record in records) {
      if (_isSameDay(record.startTime, today)) {
        totalMinutes += record.focusDurationMinutes;
      }
    }
    return totalMinutes;
  }

  int getTodaySessionMinutes() {
    if (!_initialized) return 0;
    final today = DateTime.now();
    final records = getTimerRecords(limit: 100);
    var totalMinutes = 0;
    for (final record in records) {
      if (_isSameDay(record.startTime, today)) {
        totalMinutes += record.durationMinutes;
      }
    }
    return totalMinutes;
  }

  int getTodayRoundsCompleted() {
    if (!_initialized) return 0;
    final today = DateTime.now();
    final records = getTimerRecords(limit: 100);
    var totalRounds = 0;
    for (final record in records) {
      if (_isSameDay(record.startTime, today)) {
        totalRounds += record.roundsCompleted;
      }
    }
    return totalRounds;
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  void _publishState() {
    _onTick?.call(_timerState);
    notifyListeners();
  }

  void _resetSessionTracking() {
    _sessionStartTime = null;
    _sessionDurationSeconds = 0;
    _sessionFocusSeconds = 0;
    _sessionBreakSeconds = 0;
    _sessionRoundsCompleted = 0;
  }
}

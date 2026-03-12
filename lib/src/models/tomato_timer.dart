import 'dart:math' as math;

class TimerReminderConfig {
  const TimerReminderConfig({
    this.haptic = true,
    this.sound = true,
    this.voice = false,
    this.pauseAmbient = false,
    this.visual = true,
  });

  static const TimerReminderConfig defaults = TimerReminderConfig();

  final bool haptic;
  final bool sound;
  final bool voice;
  final bool pauseAmbient;
  final bool visual;

  TimerReminderConfig copyWith({
    bool? haptic,
    bool? sound,
    bool? voice,
    bool? pauseAmbient,
    bool? visual,
  }) {
    return TimerReminderConfig(
      haptic: haptic ?? this.haptic,
      sound: sound ?? this.sound,
      voice: voice ?? this.voice,
      pauseAmbient: pauseAmbient ?? this.pauseAmbient,
      visual: visual ?? this.visual,
    );
  }

  factory TimerReminderConfig.fromMap(Map<String, Object?> map) {
    bool readBool(String key, bool fallback) {
      final raw = map[key];
      if (raw is bool) return raw;
      if (raw is num) return raw.toInt() == 1;
      if (raw is String) return raw == '1' || raw.toLowerCase() == 'true';
      return fallback;
    }

    return TimerReminderConfig(
      haptic: readBool('haptic', defaults.haptic),
      sound: readBool('sound', defaults.sound),
      voice: readBool('voice', defaults.voice),
      pauseAmbient: readBool('pause_ambient', defaults.pauseAmbient),
      visual: readBool('visual', defaults.visual),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'haptic': haptic,
      'sound': sound,
      'voice': voice,
      'pause_ambient': pauseAmbient,
      'visual': visual,
    };
  }
}

class TomatoTimerConfig {
  const TomatoTimerConfig({
    this.focusDurationSeconds = 25 * 60,
    this.breakDurationSeconds = 5 * 60,
    this.rounds = 4,
    this.autoStartBreak = true,
    this.autoStartNextRound = false,
    this.workspaceSplitRatio = 0.58,
    this.reminder = TimerReminderConfig.defaults,
  });

  final int focusDurationSeconds;
  final int breakDurationSeconds;
  final int rounds;
  final bool autoStartBreak;
  final bool autoStartNextRound;
  final double workspaceSplitRatio;
  final TimerReminderConfig reminder;

  int get focusMinutes => math.max(1, (focusDurationSeconds / 60).ceil());
  int get breakMinutes => math.max(1, (breakDurationSeconds / 60).ceil());
  double get normalizedWorkspaceSplitRatio =>
      workspaceSplitRatio.clamp(0.25, 0.75).toDouble();

  TomatoTimerConfig copyWith({
    int? focusDurationSeconds,
    int? breakDurationSeconds,
    int? rounds,
    bool? autoStartBreak,
    bool? autoStartNextRound,
    double? workspaceSplitRatio,
    TimerReminderConfig? reminder,
  }) {
    return TomatoTimerConfig(
      focusDurationSeconds: focusDurationSeconds ?? this.focusDurationSeconds,
      breakDurationSeconds: breakDurationSeconds ?? this.breakDurationSeconds,
      rounds: rounds ?? this.rounds,
      autoStartBreak: autoStartBreak ?? this.autoStartBreak,
      autoStartNextRound: autoStartNextRound ?? this.autoStartNextRound,
      workspaceSplitRatio: workspaceSplitRatio ?? this.workspaceSplitRatio,
      reminder: reminder ?? this.reminder,
    );
  }

  factory TomatoTimerConfig.fromMap(Map<String, Object?> map) {
    final defaults = const TomatoTimerConfig();
    final focusSeconds = (map['focus_seconds'] as num?)?.toInt();
    final breakSeconds = (map['break_seconds'] as num?)?.toInt();
    final focusMinutes = (map['focus_minutes'] as num?)?.toInt();
    final breakMinutes = (map['break_minutes'] as num?)?.toInt();
    final reminderMap = map['reminder'];
    final ratioRaw = map['workspace_split_ratio'];

    double ratio = defaults.workspaceSplitRatio;
    if (ratioRaw is num) {
      ratio = ratioRaw.toDouble();
    } else if (ratioRaw is String) {
      ratio = double.tryParse(ratioRaw) ?? defaults.workspaceSplitRatio;
    }

    return TomatoTimerConfig(
      focusDurationSeconds:
          focusSeconds ?? ((focusMinutes ?? defaults.focusMinutes) * 60),
      breakDurationSeconds:
          breakSeconds ?? ((breakMinutes ?? defaults.breakMinutes) * 60),
      rounds: (map['rounds'] as num?)?.toInt() ?? defaults.rounds,
      autoStartBreak: map.containsKey('auto_start_break')
          ? (map['auto_start_break'] as num?)?.toInt() == 1
          : defaults.autoStartBreak,
      autoStartNextRound: map.containsKey('auto_start_next_round')
          ? (map['auto_start_next_round'] as num?)?.toInt() == 1
          : defaults.autoStartNextRound,
      workspaceSplitRatio: ratio.clamp(0.25, 0.75).toDouble(),
      reminder: reminderMap is Map<String, Object?>
          ? TimerReminderConfig.fromMap(reminderMap)
          : reminderMap is Map
          ? TimerReminderConfig.fromMap(reminderMap.cast<String, Object?>())
          : defaults.reminder,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'focus_seconds': focusDurationSeconds,
      'break_seconds': breakDurationSeconds,
      'focus_minutes': focusMinutes,
      'break_minutes': breakMinutes,
      'rounds': rounds,
      'auto_start_break': autoStartBreak ? 1 : 0,
      'auto_start_next_round': autoStartNextRound ? 1 : 0,
      'workspace_split_ratio': normalizedWorkspaceSplitRatio,
      'reminder': reminder.toMap(),
    };
  }
}

enum TomatoTimerPhase { idle, focus, breakTime, breakReady, focusReady }

class TomatoTimerState {
  const TomatoTimerState({
    this.phase = TomatoTimerPhase.idle,
    this.currentRound = 0,
    this.remainingSeconds = 0,
    this.totalSeconds = 0,
    this.isPaused = false,
  });

  final TomatoTimerPhase phase;
  final int currentRound;
  final int remainingSeconds;
  final int totalSeconds;
  final bool isPaused;

  double get progress =>
      totalSeconds > 0 ? (totalSeconds - remainingSeconds) / totalSeconds : 0;

  double get remainingProgress =>
      totalSeconds > 0 ? remainingSeconds / totalSeconds : 0;

  bool get isActiveCountdown =>
      phase == TomatoTimerPhase.focus || phase == TomatoTimerPhase.breakTime;

  bool get isAwaitingManualTransition =>
      phase == TomatoTimerPhase.breakReady ||
      phase == TomatoTimerPhase.focusReady;

  bool get canPause => isActiveCountdown && !isPaused;

  bool get canResume => isActiveCountdown && isPaused;

  TomatoTimerState copyWith({
    TomatoTimerPhase? phase,
    int? currentRound,
    int? remainingSeconds,
    int? totalSeconds,
    bool? isPaused,
  }) {
    return TomatoTimerState(
      phase: phase ?? this.phase,
      currentRound: currentRound ?? this.currentRound,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}

class TomatoTimerRecord {
  const TomatoTimerRecord({
    this.id,
    required this.startTime,
    required this.durationMinutes,
    required this.focusDurationMinutes,
    required this.breakDurationMinutes,
    required this.roundsCompleted,
    required this.focusMinutes,
    required this.breakMinutes,
    this.partial = false,
  });

  final int? id;
  final DateTime startTime;
  final int durationMinutes;
  final int focusDurationMinutes;
  final int breakDurationMinutes;
  final int roundsCompleted;
  final int focusMinutes;
  final int breakMinutes;
  final bool partial;

  factory TomatoTimerRecord.fromMap(Map<String, Object?> map) {
    final focusMinutes = (map['focus_minutes'] as num?)?.toInt() ?? 25;
    final durationMinutes = (map['duration_minutes'] as num?)?.toInt() ?? 0;
    final roundsCompleted = (map['rounds_completed'] as num?)?.toInt() ?? 0;
    final restoredFocusDuration =
        (map['focus_duration_minutes'] as num?)?.toInt() ??
        (roundsCompleted * focusMinutes);
    final restoredBreakDuration =
        (map['break_duration_minutes'] as num?)?.toInt() ??
        (durationMinutes - restoredFocusDuration).clamp(0, durationMinutes);

    return TomatoTimerRecord(
      id: (map['id'] as num?)?.toInt(),
      startTime: DateTime.parse(map['start_time'] as String),
      durationMinutes: durationMinutes,
      focusDurationMinutes: restoredFocusDuration,
      breakDurationMinutes: restoredBreakDuration,
      roundsCompleted: roundsCompleted,
      focusMinutes: focusMinutes,
      breakMinutes: (map['break_minutes'] as num?)?.toInt() ?? 5,
      partial: ((map['is_partial'] as num?)?.toInt() ?? 0) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'start_time': startTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'focus_duration_minutes': focusDurationMinutes,
      'break_duration_minutes': breakDurationMinutes,
      'rounds_completed': roundsCompleted,
      'focus_minutes': focusMinutes,
      'break_minutes': breakMinutes,
      'is_partial': partial ? 1 : 0,
    };
  }
}

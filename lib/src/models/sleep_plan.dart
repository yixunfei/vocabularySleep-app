enum SleepPlanTrack {
  observation('observation'),
  windDown('wind_down'),
  insomniaSupport('insomnia_support'),
  rhythmReset('rhythm_reset'),
  environmentFix('environment_fix'),
  daytimeRecovery('daytime_recovery');

  const SleepPlanTrack(this.storageValue);

  final String storageValue;

  static SleepPlanTrack? fromStorage(String? raw) {
    final normalized = raw?.trim();
    for (final value in SleepPlanTrack.values) {
      if (value.storageValue == normalized) {
        return value;
      }
    }
    return null;
  }
}

enum SleepProgramType {
  sevenDayRhythmReset('seven_day_rhythm_reset'),
  fourteenDaySleepReset('fourteen_day_sleep_reset'),
  insomniaStarter('insomnia_starter');

  const SleepProgramType(this.storageValue);

  final String storageValue;

  static SleepProgramType? fromStorage(String? raw) {
    final normalized = raw?.trim();
    for (final value in SleepProgramType.values) {
      if (value.storageValue == normalized) {
        return value;
      }
    }
    return null;
  }
}

class SleepPlan {
  const SleepPlan({
    required this.track,
    required this.title,
    required this.summary,
    required this.primaryActions,
    required this.startedAt,
    this.reviewAfterDays = 7,
    this.completed = false,
  });

  final SleepPlanTrack track;
  final String title;
  final String summary;
  final List<String> primaryActions;
  final DateTime startedAt;
  final int reviewAfterDays;
  final bool completed;

  SleepPlan copyWith({
    SleepPlanTrack? track,
    String? title,
    String? summary,
    List<String>? primaryActions,
    DateTime? startedAt,
    int? reviewAfterDays,
    bool? completed,
  }) {
    return SleepPlan(
      track: track ?? this.track,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      primaryActions: primaryActions ?? this.primaryActions,
      startedAt: startedAt ?? this.startedAt,
      reviewAfterDays: reviewAfterDays ?? this.reviewAfterDays,
      completed: completed ?? this.completed,
    );
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'track': track.storageValue,
      'title': title,
      'summary': summary,
      'primary_actions': primaryActions,
      'started_at': startedAt.toIso8601String(),
      'review_after_days': reviewAfterDays,
      'completed': completed,
    };
  }

  static SleepPlan? fromJsonValue(Object? value) {
    if (value is! Map) {
      return null;
    }
    final map = value.cast<Object?, Object?>();
    final track = SleepPlanTrack.fromStorage('${map['track'] ?? ''}');
    if (track == null) {
      return null;
    }
    final actionsRaw = map['primary_actions'];
    return SleepPlan(
      track: track,
      title: '${map['title'] ?? ''}'.trim(),
      summary: '${map['summary'] ?? ''}'.trim(),
      primaryActions: actionsRaw is List
          ? actionsRaw
                .map((item) => '$item'.trim())
                .where((item) => item.isNotEmpty)
                .toList(growable: false)
          : const <String>[],
      startedAt: _readDateTime(map['started_at']) ?? DateTime.now(),
      reviewAfterDays: _readInt(map['review_after_days']) ?? 7,
      completed: map['completed'] == true,
    );
  }
}

class SleepProgramProgress {
  const SleepProgramProgress({
    required this.programType,
    required this.startedAt,
    required this.currentDay,
    required this.completedDays,
    required this.isCompleted,
  });

  final SleepProgramType programType;
  final DateTime startedAt;
  final int currentDay;
  final Set<int> completedDays;
  final bool isCompleted;

  SleepProgramProgress copyWith({
    SleepProgramType? programType,
    DateTime? startedAt,
    int? currentDay,
    Set<int>? completedDays,
    bool? isCompleted,
  }) {
    return SleepProgramProgress(
      programType: programType ?? this.programType,
      startedAt: startedAt ?? this.startedAt,
      currentDay: currentDay ?? this.currentDay,
      completedDays: completedDays ?? this.completedDays,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, Object?> toJsonMap() {
    final days = completedDays.toList()..sort();
    return <String, Object?>{
      'program_type': programType.storageValue,
      'started_at': startedAt.toIso8601String(),
      'current_day': currentDay,
      'completed_days': days,
      'is_completed': isCompleted,
    };
  }

  static SleepProgramProgress? fromJsonValue(Object? value) {
    if (value is! Map) {
      return null;
    }
    final map = value.cast<Object?, Object?>();
    final programType = SleepProgramType.fromStorage(
      '${map['program_type'] ?? ''}',
    );
    if (programType == null) {
      return null;
    }
    final completedDaysRaw = map['completed_days'];
    return SleepProgramProgress(
      programType: programType,
      startedAt: _readDateTime(map['started_at']) ?? DateTime.now(),
      currentDay: _readInt(map['current_day']) ?? 1,
      completedDays: completedDaysRaw is List
          ? completedDaysRaw.map(_readInt).whereType<int>().toSet()
          : <int>{},
      isCompleted: map['is_completed'] == true,
    );
  }
}

class SleepDashboardState {
  const SleepDashboardState({
    this.lastOpenedDateKey = '',
    this.dismissedRiskBannerDateKey = '',
    this.preferredQuickAction,
    this.selectedLogDateKey = '',
    this.lastReportRangeDays = 7,
    this.preferredWhiteNoiseId,
    this.sleepDarkModeEnabled = false,
  });

  final String lastOpenedDateKey;
  final String dismissedRiskBannerDateKey;
  final String? preferredQuickAction;
  final String selectedLogDateKey;
  final int lastReportRangeDays;
  final String? preferredWhiteNoiseId;
  final bool sleepDarkModeEnabled;

  SleepDashboardState copyWith({
    String? lastOpenedDateKey,
    String? dismissedRiskBannerDateKey,
    String? preferredQuickAction,
    String? selectedLogDateKey,
    int? lastReportRangeDays,
    String? preferredWhiteNoiseId,
    bool? sleepDarkModeEnabled,
  }) {
    return SleepDashboardState(
      lastOpenedDateKey: lastOpenedDateKey ?? this.lastOpenedDateKey,
      dismissedRiskBannerDateKey:
          dismissedRiskBannerDateKey ?? this.dismissedRiskBannerDateKey,
      preferredQuickAction: preferredQuickAction ?? this.preferredQuickAction,
      selectedLogDateKey: selectedLogDateKey ?? this.selectedLogDateKey,
      lastReportRangeDays: lastReportRangeDays ?? this.lastReportRangeDays,
      preferredWhiteNoiseId:
          preferredWhiteNoiseId ?? this.preferredWhiteNoiseId,
      sleepDarkModeEnabled: sleepDarkModeEnabled ?? this.sleepDarkModeEnabled,
    );
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'last_opened_date_key': lastOpenedDateKey,
      'dismissed_risk_banner_date_key': dismissedRiskBannerDateKey,
      'preferred_quick_action': preferredQuickAction,
      'selected_log_date_key': selectedLogDateKey,
      'last_report_range_days': lastReportRangeDays,
      'preferred_white_noise_id': preferredWhiteNoiseId,
      'sleep_dark_mode_enabled': sleepDarkModeEnabled,
    };
  }

  static SleepDashboardState fromJsonValue(Object? value) {
    if (value is! Map) {
      return const SleepDashboardState();
    }
    final map = value.cast<Object?, Object?>();
    return SleepDashboardState(
      lastOpenedDateKey: '${map['last_opened_date_key'] ?? ''}'.trim(),
      dismissedRiskBannerDateKey:
          '${map['dismissed_risk_banner_date_key'] ?? ''}'.trim(),
      preferredQuickAction: _readString(map['preferred_quick_action']),
      selectedLogDateKey: '${map['selected_log_date_key'] ?? ''}'.trim(),
      lastReportRangeDays: _readInt(map['last_report_range_days']) ?? 7,
      preferredWhiteNoiseId: _readString(map['preferred_white_noise_id']),
      sleepDarkModeEnabled: map['sleep_dark_mode_enabled'] == true,
    );
  }
}

DateTime? _readDateTime(Object? value) {
  final raw = '$value'.trim();
  if (raw.isEmpty || raw == 'null') {
    return null;
  }
  return DateTime.tryParse(raw);
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

String? _readString(Object? value) {
  final raw = '$value'.trim();
  return raw.isEmpty || raw == 'null' ? null : raw;
}

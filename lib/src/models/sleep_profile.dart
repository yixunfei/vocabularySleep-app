enum SleepIssueType {
  difficultyFallingAsleep('difficulty_falling_asleep'),
  frequentAwakenings('frequent_awakenings'),
  earlyAwakening('early_awakening'),
  nonRestorativeSleep('non_restorative_sleep'),
  irregularSchedule('irregular_schedule'),
  racingThoughts('racing_thoughts'),
  daytimeSleepiness('daytime_sleepiness'),
  snoringRisk('snoring_risk'),
  painOrTension('pain_or_tension');

  const SleepIssueType(this.storageValue);

  final String storageValue;

  static SleepIssueType? fromStorage(String? raw) {
    final normalized = raw?.trim();
    for (final value in SleepIssueType.values) {
      if (value.storageValue == normalized) {
        return value;
      }
    }
    return null;
  }
}

enum SleepRiskLevel {
  none('none'),
  mild('mild'),
  medium('medium'),
  high('high');

  const SleepRiskLevel(this.storageValue);

  final String storageValue;

  static SleepRiskLevel fromStorage(String? raw) {
    final normalized = raw?.trim();
    for (final value in SleepRiskLevel.values) {
      if (value.storageValue == normalized) {
        return value;
      }
    }
    return SleepRiskLevel.none;
  }
}

class SleepProfile {
  const SleepProfile({
    required this.primaryIssues,
    required this.typicalBedtime,
    required this.typicalWakeTime,
    required this.hasRacingThoughts,
    required this.caffeineSensitive,
    required this.snoringRisk,
    required this.painImpactLevel,
    required this.stressLoadLevel,
    required this.screenDependenceLevel,
    required this.lateWorkFrequency,
    required this.exerciseLateFrequency,
    required this.bedroomLightIssue,
    required this.bedroomNoiseIssue,
    required this.bedroomTempIssue,
    required this.shiftWorkOrJetLag,
    required this.refluxOrDigestiveDiscomfort,
    required this.nightmaresOrDreamDistress,
    required this.goal,
    required this.createdAt,
    required this.updatedAt,
  });

  final Set<SleepIssueType> primaryIssues;
  final String typicalBedtime;
  final String typicalWakeTime;
  final bool hasRacingThoughts;
  final bool caffeineSensitive;
  final SleepRiskLevel snoringRisk;
  final int painImpactLevel;
  final int stressLoadLevel;
  final int screenDependenceLevel;
  final int lateWorkFrequency;
  final int exerciseLateFrequency;
  final bool bedroomLightIssue;
  final bool bedroomNoiseIssue;
  final bool bedroomTempIssue;
  final bool shiftWorkOrJetLag;
  final bool refluxOrDigestiveDiscomfort;
  final bool nightmaresOrDreamDistress;
  final String goal;
  final DateTime createdAt;
  final DateTime updatedAt;

  SleepProfile copyWith({
    Set<SleepIssueType>? primaryIssues,
    String? typicalBedtime,
    String? typicalWakeTime,
    bool? hasRacingThoughts,
    bool? caffeineSensitive,
    SleepRiskLevel? snoringRisk,
    int? painImpactLevel,
    int? stressLoadLevel,
    int? screenDependenceLevel,
    int? lateWorkFrequency,
    int? exerciseLateFrequency,
    bool? bedroomLightIssue,
    bool? bedroomNoiseIssue,
    bool? bedroomTempIssue,
    bool? shiftWorkOrJetLag,
    bool? refluxOrDigestiveDiscomfort,
    bool? nightmaresOrDreamDistress,
    String? goal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SleepProfile(
      primaryIssues: primaryIssues ?? this.primaryIssues,
      typicalBedtime: typicalBedtime ?? this.typicalBedtime,
      typicalWakeTime: typicalWakeTime ?? this.typicalWakeTime,
      hasRacingThoughts: hasRacingThoughts ?? this.hasRacingThoughts,
      caffeineSensitive: caffeineSensitive ?? this.caffeineSensitive,
      snoringRisk: snoringRisk ?? this.snoringRisk,
      painImpactLevel: painImpactLevel ?? this.painImpactLevel,
      stressLoadLevel: stressLoadLevel ?? this.stressLoadLevel,
      screenDependenceLevel:
          screenDependenceLevel ?? this.screenDependenceLevel,
      lateWorkFrequency: lateWorkFrequency ?? this.lateWorkFrequency,
      exerciseLateFrequency:
          exerciseLateFrequency ?? this.exerciseLateFrequency,
      bedroomLightIssue: bedroomLightIssue ?? this.bedroomLightIssue,
      bedroomNoiseIssue: bedroomNoiseIssue ?? this.bedroomNoiseIssue,
      bedroomTempIssue: bedroomTempIssue ?? this.bedroomTempIssue,
      shiftWorkOrJetLag: shiftWorkOrJetLag ?? this.shiftWorkOrJetLag,
      refluxOrDigestiveDiscomfort:
          refluxOrDigestiveDiscomfort ?? this.refluxOrDigestiveDiscomfort,
      nightmaresOrDreamDistress:
          nightmaresOrDreamDistress ?? this.nightmaresOrDreamDistress,
      goal: goal ?? this.goal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJsonMap() {
    final issues = primaryIssues.map((item) => item.storageValue).toList()
      ..sort();
    return <String, Object?>{
      'primary_issues': issues,
      'typical_bedtime': typicalBedtime,
      'typical_wake_time': typicalWakeTime,
      'has_racing_thoughts': hasRacingThoughts,
      'caffeine_sensitive': caffeineSensitive,
      'snoring_risk': snoringRisk.storageValue,
      'pain_impact_level': painImpactLevel,
      'stress_load_level': stressLoadLevel,
      'screen_dependence_level': screenDependenceLevel,
      'late_work_frequency': lateWorkFrequency,
      'exercise_late_frequency': exerciseLateFrequency,
      'bedroom_light_issue': bedroomLightIssue,
      'bedroom_noise_issue': bedroomNoiseIssue,
      'bedroom_temp_issue': bedroomTempIssue,
      'shift_work_or_jet_lag': shiftWorkOrJetLag,
      'reflux_or_digestive_discomfort': refluxOrDigestiveDiscomfort,
      'nightmares_or_dream_distress': nightmaresOrDreamDistress,
      'goal': goal,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static SleepProfile? fromJsonValue(Object? value) {
    if (value is! Map) {
      return null;
    }
    final map = value.cast<Object?, Object?>();
    final issuesRaw = map['primary_issues'];
    final issues = issuesRaw is List
        ? issuesRaw
              .map((item) => SleepIssueType.fromStorage('$item'))
              .whereType<SleepIssueType>()
              .toSet()
        : <SleepIssueType>{};
    final createdAt = _readDateTime(map['created_at']);
    final updatedAt = _readDateTime(map['updated_at']);
    return SleepProfile(
      primaryIssues: issues,
      typicalBedtime: '${map['typical_bedtime'] ?? ''}'.trim(),
      typicalWakeTime: '${map['typical_wake_time'] ?? ''}'.trim(),
      hasRacingThoughts: map['has_racing_thoughts'] == true,
      caffeineSensitive: map['caffeine_sensitive'] == true,
      snoringRisk: SleepRiskLevel.fromStorage('${map['snoring_risk'] ?? ''}'),
      painImpactLevel: _readInt(map['pain_impact_level']) ?? 0,
      stressLoadLevel: _readInt(map['stress_load_level']) ?? 0,
      screenDependenceLevel: _readInt(map['screen_dependence_level']) ?? 0,
      lateWorkFrequency: _readInt(map['late_work_frequency']) ?? 0,
      exerciseLateFrequency: _readInt(map['exercise_late_frequency']) ?? 0,
      bedroomLightIssue: map['bedroom_light_issue'] == true,
      bedroomNoiseIssue: map['bedroom_noise_issue'] == true,
      bedroomTempIssue: map['bedroom_temp_issue'] == true,
      shiftWorkOrJetLag: map['shift_work_or_jet_lag'] == true,
      refluxOrDigestiveDiscomfort:
          map['reflux_or_digestive_discomfort'] == true,
      nightmaresOrDreamDistress:
          map['nightmares_or_dream_distress'] == true,
      goal: '${map['goal'] ?? ''}'.trim(),
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? createdAt ?? DateTime.now(),
    );
  }
}

class SleepAssessmentDraftState {
  const SleepAssessmentDraftState({
    this.selectedIssues = const <SleepIssueType>{},
    this.typicalBedtime = '',
    this.typicalWakeTime = '',
    this.hasRacingThoughts = false,
    this.snoringRisk = SleepRiskLevel.none,
    this.caffeineSensitive = false,
    this.painImpactLevel = 0,
    this.stressLoadLevel = 0,
    this.screenDependenceLevel = 0,
    this.lateWorkFrequency = 0,
    this.exerciseLateFrequency = 0,
    this.bedroomLightIssue = false,
    this.bedroomNoiseIssue = false,
    this.bedroomTempIssue = false,
    this.shiftWorkOrJetLag = false,
    this.refluxOrDigestiveDiscomfort = false,
    this.nightmaresOrDreamDistress = false,
    this.goal = '',
  });

  final Set<SleepIssueType> selectedIssues;
  final String typicalBedtime;
  final String typicalWakeTime;
  final bool hasRacingThoughts;
  final SleepRiskLevel snoringRisk;
  final bool caffeineSensitive;
  final int painImpactLevel;
  final int stressLoadLevel;
  final int screenDependenceLevel;
  final int lateWorkFrequency;
  final int exerciseLateFrequency;
  final bool bedroomLightIssue;
  final bool bedroomNoiseIssue;
  final bool bedroomTempIssue;
  final bool shiftWorkOrJetLag;
  final bool refluxOrDigestiveDiscomfort;
  final bool nightmaresOrDreamDistress;
  final String goal;

  SleepAssessmentDraftState copyWith({
    Set<SleepIssueType>? selectedIssues,
    String? typicalBedtime,
    String? typicalWakeTime,
    bool? hasRacingThoughts,
    SleepRiskLevel? snoringRisk,
    bool? caffeineSensitive,
    int? painImpactLevel,
    int? stressLoadLevel,
    int? screenDependenceLevel,
    int? lateWorkFrequency,
    int? exerciseLateFrequency,
    bool? bedroomLightIssue,
    bool? bedroomNoiseIssue,
    bool? bedroomTempIssue,
    bool? shiftWorkOrJetLag,
    bool? refluxOrDigestiveDiscomfort,
    bool? nightmaresOrDreamDistress,
    String? goal,
  }) {
    return SleepAssessmentDraftState(
      selectedIssues: selectedIssues ?? this.selectedIssues,
      typicalBedtime: typicalBedtime ?? this.typicalBedtime,
      typicalWakeTime: typicalWakeTime ?? this.typicalWakeTime,
      hasRacingThoughts: hasRacingThoughts ?? this.hasRacingThoughts,
      snoringRisk: snoringRisk ?? this.snoringRisk,
      caffeineSensitive: caffeineSensitive ?? this.caffeineSensitive,
      painImpactLevel: painImpactLevel ?? this.painImpactLevel,
      stressLoadLevel: stressLoadLevel ?? this.stressLoadLevel,
      screenDependenceLevel:
          screenDependenceLevel ?? this.screenDependenceLevel,
      lateWorkFrequency: lateWorkFrequency ?? this.lateWorkFrequency,
      exerciseLateFrequency:
          exerciseLateFrequency ?? this.exerciseLateFrequency,
      bedroomLightIssue: bedroomLightIssue ?? this.bedroomLightIssue,
      bedroomNoiseIssue: bedroomNoiseIssue ?? this.bedroomNoiseIssue,
      bedroomTempIssue: bedroomTempIssue ?? this.bedroomTempIssue,
      shiftWorkOrJetLag: shiftWorkOrJetLag ?? this.shiftWorkOrJetLag,
      refluxOrDigestiveDiscomfort:
          refluxOrDigestiveDiscomfort ?? this.refluxOrDigestiveDiscomfort,
      nightmaresOrDreamDistress:
          nightmaresOrDreamDistress ?? this.nightmaresOrDreamDistress,
      goal: goal ?? this.goal,
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

enum SleepNightRescueMode {
  briefAwakening('brief_awakening'),
  fullyAwake('fully_awake'),
  racingThoughts('racing_thoughts'),
  bodyActivated('body_activated'),
  temperatureDiscomfort('temperature_discomfort');

  const SleepNightRescueMode(this.storageValue);

  final String storageValue;

  static SleepNightRescueMode? fromStorage(String? raw) {
    final normalized = raw?.trim();
    for (final value in SleepNightRescueMode.values) {
      if (value.storageValue == normalized) {
        return value;
      }
    }
    return null;
  }
}

class SleepDailyLog {
  const SleepDailyLog({
    this.id,
    required this.dateKey,
    this.bedtimeAt,
    this.lightsOffAt,
    this.sleepOnsetAt,
    this.finalWakeAt,
    this.outOfBedAt,
    this.estimatedTotalSleepMinutes,
    this.sleepLatencyMinutes,
    this.nightWakeCount = 0,
    this.nightWakeTotalMinutes = 0,
    this.timeInBedMinutes,
    this.sleepEfficiency,
    this.morningEnergy,
    this.daytimeSleepiness,
    this.caffeineAfterCutoff = false,
    this.alcoholAtNight = false,
    this.lateScreenExposure = false,
    this.morningLightDone = false,
    this.heavyDinner = false,
    this.intenseExerciseLate = false,
    this.hotBathDone = false,
    this.stretchingDone = false,
    this.whiteNoiseUsed = false,
    this.whiteNoiseSourceId,
    this.bedroomTooHot = false,
    this.bedroomTooBright = false,
    this.bedroomTooNoisy = false,
    this.clockChecking = false,
    this.stressPeakLevel,
    this.worryLoadLevel,
    this.windDownMinutes,
    this.napMinutes = 0,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String dateKey;
  final DateTime? bedtimeAt;
  final DateTime? lightsOffAt;
  final DateTime? sleepOnsetAt;
  final DateTime? finalWakeAt;
  final DateTime? outOfBedAt;
  final int? estimatedTotalSleepMinutes;
  final int? sleepLatencyMinutes;
  final int nightWakeCount;
  final int nightWakeTotalMinutes;
  final int? timeInBedMinutes;
  final double? sleepEfficiency;
  final int? morningEnergy;
  final int? daytimeSleepiness;
  final bool caffeineAfterCutoff;
  final bool alcoholAtNight;
  final bool lateScreenExposure;
  final bool morningLightDone;
  final bool heavyDinner;
  final bool intenseExerciseLate;
  final bool hotBathDone;
  final bool stretchingDone;
  final bool whiteNoiseUsed;
  final String? whiteNoiseSourceId;
  final bool bedroomTooHot;
  final bool bedroomTooBright;
  final bool bedroomTooNoisy;
  final bool clockChecking;
  final int? stressPeakLevel;
  final int? worryLoadLevel;
  final int? windDownMinutes;
  final int napMinutes;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SleepDailyLog copyWith({
    String? id,
    String? dateKey,
    DateTime? bedtimeAt,
    DateTime? lightsOffAt,
    DateTime? sleepOnsetAt,
    DateTime? finalWakeAt,
    DateTime? outOfBedAt,
    int? estimatedTotalSleepMinutes,
    int? sleepLatencyMinutes,
    int? nightWakeCount,
    int? nightWakeTotalMinutes,
    int? timeInBedMinutes,
    double? sleepEfficiency,
    int? morningEnergy,
    int? daytimeSleepiness,
    bool? caffeineAfterCutoff,
    bool? alcoholAtNight,
    bool? lateScreenExposure,
    bool? morningLightDone,
    bool? heavyDinner,
    bool? intenseExerciseLate,
    bool? hotBathDone,
    bool? stretchingDone,
    bool? whiteNoiseUsed,
    String? whiteNoiseSourceId,
    bool? bedroomTooHot,
    bool? bedroomTooBright,
    bool? bedroomTooNoisy,
    bool? clockChecking,
    int? stressPeakLevel,
    int? worryLoadLevel,
    int? windDownMinutes,
    int? napMinutes,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SleepDailyLog(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      bedtimeAt: bedtimeAt ?? this.bedtimeAt,
      lightsOffAt: lightsOffAt ?? this.lightsOffAt,
      sleepOnsetAt: sleepOnsetAt ?? this.sleepOnsetAt,
      finalWakeAt: finalWakeAt ?? this.finalWakeAt,
      outOfBedAt: outOfBedAt ?? this.outOfBedAt,
      estimatedTotalSleepMinutes:
          estimatedTotalSleepMinutes ?? this.estimatedTotalSleepMinutes,
      sleepLatencyMinutes: sleepLatencyMinutes ?? this.sleepLatencyMinutes,
      nightWakeCount: nightWakeCount ?? this.nightWakeCount,
      nightWakeTotalMinutes:
          nightWakeTotalMinutes ?? this.nightWakeTotalMinutes,
      timeInBedMinutes: timeInBedMinutes ?? this.timeInBedMinutes,
      sleepEfficiency: sleepEfficiency ?? this.sleepEfficiency,
      morningEnergy: morningEnergy ?? this.morningEnergy,
      daytimeSleepiness: daytimeSleepiness ?? this.daytimeSleepiness,
      caffeineAfterCutoff:
          caffeineAfterCutoff ?? this.caffeineAfterCutoff,
      alcoholAtNight: alcoholAtNight ?? this.alcoholAtNight,
      lateScreenExposure: lateScreenExposure ?? this.lateScreenExposure,
      morningLightDone: morningLightDone ?? this.morningLightDone,
      heavyDinner: heavyDinner ?? this.heavyDinner,
      intenseExerciseLate: intenseExerciseLate ?? this.intenseExerciseLate,
      hotBathDone: hotBathDone ?? this.hotBathDone,
      stretchingDone: stretchingDone ?? this.stretchingDone,
      whiteNoiseUsed: whiteNoiseUsed ?? this.whiteNoiseUsed,
      whiteNoiseSourceId: whiteNoiseSourceId ?? this.whiteNoiseSourceId,
      bedroomTooHot: bedroomTooHot ?? this.bedroomTooHot,
      bedroomTooBright: bedroomTooBright ?? this.bedroomTooBright,
      bedroomTooNoisy: bedroomTooNoisy ?? this.bedroomTooNoisy,
      clockChecking: clockChecking ?? this.clockChecking,
      stressPeakLevel: stressPeakLevel ?? this.stressPeakLevel,
      worryLoadLevel: worryLoadLevel ?? this.worryLoadLevel,
      windDownMinutes: windDownMinutes ?? this.windDownMinutes,
      napMinutes: napMinutes ?? this.napMinutes,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'id': id,
      'date_key': dateKey,
      'bedtime_at': bedtimeAt?.toIso8601String(),
      'lights_off_at': lightsOffAt?.toIso8601String(),
      'sleep_onset_at': sleepOnsetAt?.toIso8601String(),
      'final_wake_at': finalWakeAt?.toIso8601String(),
      'out_of_bed_at': outOfBedAt?.toIso8601String(),
      'estimated_total_sleep_minutes': estimatedTotalSleepMinutes,
      'sleep_latency_minutes': sleepLatencyMinutes,
      'night_wake_count': nightWakeCount,
      'night_wake_total_minutes': nightWakeTotalMinutes,
      'time_in_bed_minutes': timeInBedMinutes,
      'sleep_efficiency': sleepEfficiency,
      'morning_energy': morningEnergy,
      'daytime_sleepiness': daytimeSleepiness,
      'caffeine_after_cutoff': caffeineAfterCutoff,
      'alcohol_at_night': alcoholAtNight,
      'late_screen_exposure': lateScreenExposure,
      'morning_light_done': morningLightDone,
      'heavy_dinner': heavyDinner,
      'intense_exercise_late': intenseExerciseLate,
      'hot_bath_done': hotBathDone,
      'stretching_done': stretchingDone,
      'white_noise_used': whiteNoiseUsed,
      'white_noise_source_id': whiteNoiseSourceId,
      'bedroom_too_hot': bedroomTooHot,
      'bedroom_too_bright': bedroomTooBright,
      'bedroom_too_noisy': bedroomTooNoisy,
      'clock_checking': clockChecking,
      'stress_peak_level': stressPeakLevel,
      'worry_load_level': worryLoadLevel,
      'wind_down_minutes': windDownMinutes,
      'nap_minutes': napMinutes,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static SleepDailyLog? fromJsonValue(Object? value) {
    if (value is! Map) {
      return null;
    }
    final map = value.cast<Object?, Object?>();
    final dateKey = '${map['date_key'] ?? ''}'.trim();
    if (dateKey.isEmpty) {
      return null;
    }
    return SleepDailyLog(
      id: _readString(map['id']),
      dateKey: dateKey,
      bedtimeAt: _readDateTime(map['bedtime_at']),
      lightsOffAt: _readDateTime(map['lights_off_at']),
      sleepOnsetAt: _readDateTime(map['sleep_onset_at']),
      finalWakeAt: _readDateTime(map['final_wake_at']),
      outOfBedAt: _readDateTime(map['out_of_bed_at']),
      estimatedTotalSleepMinutes: _readInt(map['estimated_total_sleep_minutes']),
      sleepLatencyMinutes: _readInt(map['sleep_latency_minutes']),
      nightWakeCount: _readInt(map['night_wake_count']) ?? 0,
      nightWakeTotalMinutes: _readInt(map['night_wake_total_minutes']) ?? 0,
      timeInBedMinutes: _readInt(map['time_in_bed_minutes']),
      sleepEfficiency: _readDouble(map['sleep_efficiency']),
      morningEnergy: _readInt(map['morning_energy']),
      daytimeSleepiness: _readInt(map['daytime_sleepiness']),
      caffeineAfterCutoff: map['caffeine_after_cutoff'] == true,
      alcoholAtNight: map['alcohol_at_night'] == true,
      lateScreenExposure: map['late_screen_exposure'] == true,
      morningLightDone: map['morning_light_done'] == true,
      heavyDinner: map['heavy_dinner'] == true,
      intenseExerciseLate: map['intense_exercise_late'] == true,
      hotBathDone: map['hot_bath_done'] == true,
      stretchingDone: map['stretching_done'] == true,
      whiteNoiseUsed: map['white_noise_used'] == true,
      whiteNoiseSourceId: _readString(map['white_noise_source_id']),
      bedroomTooHot: map['bedroom_too_hot'] == true,
      bedroomTooBright: map['bedroom_too_bright'] == true,
      bedroomTooNoisy: map['bedroom_too_noisy'] == true,
      clockChecking: map['clock_checking'] == true,
      stressPeakLevel: _readInt(map['stress_peak_level']),
      worryLoadLevel: _readInt(map['worry_load_level']),
      windDownMinutes: _readInt(map['wind_down_minutes']),
      napMinutes: _readInt(map['nap_minutes']) ?? 0,
      notes: _readString(map['notes']),
      createdAt: _readDateTime(map['created_at']),
      updatedAt: _readDateTime(map['updated_at']),
    );
  }
}

class SleepNightEvent {
  const SleepNightEvent({
    this.id,
    required this.dateKey,
    required this.mode,
    this.startedAt,
    this.endedAt,
    this.guessedTrigger,
    this.actionTaken,
    this.returnedToBedAt,
    this.fellAsleepAgainAt,
    this.notes,
  });

  final String? id;
  final String dateKey;
  final SleepNightRescueMode mode;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? guessedTrigger;
  final String? actionTaken;
  final DateTime? returnedToBedAt;
  final DateTime? fellAsleepAgainAt;
  final String? notes;

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'id': id,
      'date_key': dateKey,
      'mode': mode.storageValue,
      'started_at': startedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'guessed_trigger': guessedTrigger,
      'action_taken': actionTaken,
      'returned_to_bed_at': returnedToBedAt?.toIso8601String(),
      'fell_asleep_again_at': fellAsleepAgainAt?.toIso8601String(),
      'notes': notes,
    };
  }

  static SleepNightEvent? fromJsonValue(Object? value) {
    if (value is! Map) {
      return null;
    }
    final map = value.cast<Object?, Object?>();
    final dateKey = '${map['date_key'] ?? ''}'.trim();
    final mode = SleepNightRescueMode.fromStorage('${map['mode'] ?? ''}');
    if (dateKey.isEmpty || mode == null) {
      return null;
    }
    return SleepNightEvent(
      id: _readString(map['id']),
      dateKey: dateKey,
      mode: mode,
      startedAt: _readDateTime(map['started_at']),
      endedAt: _readDateTime(map['ended_at']),
      guessedTrigger: _readString(map['guessed_trigger']),
      actionTaken: _readString(map['action_taken']),
      returnedToBedAt: _readDateTime(map['returned_to_bed_at']),
      fellAsleepAgainAt: _readDateTime(map['fell_asleep_again_at']),
      notes: _readString(map['notes']),
    );
  }
}

class SleepThoughtEntry {
  const SleepThoughtEntry({
    this.id,
    required this.dateKey,
    required this.entryType,
    required this.content,
    this.reframedContent,
    this.intensity,
    this.deferredToDateKey,
    this.createdAt,
  });

  final String? id;
  final String dateKey;
  final String entryType;
  final String content;
  final String? reframedContent;
  final int? intensity;
  final String? deferredToDateKey;
  final DateTime? createdAt;

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'id': id,
      'date_key': dateKey,
      'entry_type': entryType,
      'content': content,
      'reframed_content': reframedContent,
      'intensity': intensity,
      'deferred_to_date_key': deferredToDateKey,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static SleepThoughtEntry? fromJsonValue(Object? value) {
    if (value is! Map) {
      return null;
    }
    final map = value.cast<Object?, Object?>();
    final dateKey = '${map['date_key'] ?? ''}'.trim();
    final entryType = '${map['entry_type'] ?? ''}'.trim();
    final content = '${map['content'] ?? ''}'.trim();
    if (dateKey.isEmpty || entryType.isEmpty || content.isEmpty) {
      return null;
    }
    return SleepThoughtEntry(
      id: _readString(map['id']),
      dateKey: dateKey,
      entryType: entryType,
      content: content,
      reframedContent: _readString(map['reframed_content']),
      intensity: _readInt(map['intensity']),
      deferredToDateKey: _readString(map['deferred_to_date_key']),
      createdAt: _readDateTime(map['created_at']),
    );
  }
}

class SleepNightRescueState {
  const SleepNightRescueState({
    this.mode,
    this.startedAt,
    this.suggestedAction,
    this.hasLeftBed = false,
  });

  final SleepNightRescueMode? mode;
  final DateTime? startedAt;
  final String? suggestedAction;
  final bool hasLeftBed;

  SleepNightRescueState copyWith({
    Object? mode = _sleepUnset,
    Object? startedAt = _sleepUnset,
    Object? suggestedAction = _sleepUnset,
    bool? hasLeftBed,
  }) {
    return SleepNightRescueState(
      mode: mode == _sleepUnset ? this.mode : mode as SleepNightRescueMode?,
      startedAt: startedAt == _sleepUnset
          ? this.startedAt
          : startedAt as DateTime?,
      suggestedAction: suggestedAction == _sleepUnset
          ? this.suggestedAction
          : suggestedAction as String?,
      hasLeftBed: hasLeftBed ?? this.hasLeftBed,
    );
  }
}

const Object _sleepUnset = Object();

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

double? _readDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

String? _readString(Object? value) {
  final raw = '$value'.trim();
  return raw.isEmpty || raw == 'null' ? null : raw;
}

enum SleepRoutineStepType {
  dimLights('dim_lights'),
  stopScreens('stop_screens'),
  prepareRoom('prepare_room'),
  unloadThoughts('unload_thoughts'),
  breathing('breathing'),
  stretch('stretch'),
  warmBath('warm_bath'),
  whiteNoise('white_noise'),
  soothingAudio('soothing_audio'),
  bodyScan('body_scan'),
  goToBed('go_to_bed');

  const SleepRoutineStepType(this.storageValue);

  final String storageValue;

  static SleepRoutineStepType? fromStorage(String? raw) {
    final normalized = raw?.trim();
    for (final value in SleepRoutineStepType.values) {
      if (value.storageValue == normalized) {
        return value;
      }
    }
    return null;
  }
}

class SleepRoutineStep {
  const SleepRoutineStep({
    required this.type,
    required this.label,
    required this.durationSeconds,
    this.payload,
  });

  final SleepRoutineStepType type;
  final String label;
  final int durationSeconds;
  final Map<String, Object?>? payload;

  SleepRoutineStep copyWith({
    SleepRoutineStepType? type,
    String? label,
    int? durationSeconds,
    Map<String, Object?>? payload,
  }) {
    return SleepRoutineStep(
      type: type ?? this.type,
      label: label ?? this.label,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      payload: payload ?? this.payload,
    );
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'type': type.storageValue,
      'label': label,
      'duration_seconds': durationSeconds,
      'payload': payload,
    };
  }

  static SleepRoutineStep? fromJsonValue(Object? value) {
    if (value is! Map) {
      return null;
    }
    final map = value.cast<Object?, Object?>();
    final type = SleepRoutineStepType.fromStorage('${map['type'] ?? ''}');
    if (type == null) {
      return null;
    }
    final payload = map['payload'];
    return SleepRoutineStep(
      type: type,
      label: '${map['label'] ?? ''}'.trim(),
      durationSeconds: _readInt(map['duration_seconds']) ?? 0,
      payload: payload is Map ? payload.cast<String, Object?>() : null,
    );
  }
}

class SleepRoutineTemplate {
  const SleepRoutineTemplate({
    required this.id,
    required this.name,
    required this.totalMinutes,
    required this.steps,
    required this.builtIn,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int totalMinutes;
  final List<SleepRoutineStep> steps;
  final bool builtIn;
  final DateTime updatedAt;

  SleepRoutineTemplate copyWith({
    String? id,
    String? name,
    int? totalMinutes,
    List<SleepRoutineStep>? steps,
    bool? builtIn,
    DateTime? updatedAt,
  }) {
    return SleepRoutineTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      steps: steps ?? this.steps,
      builtIn: builtIn ?? this.builtIn,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'total_minutes': totalMinutes,
      'steps': steps.map((step) => step.toJsonMap()).toList(growable: false),
      'built_in': builtIn,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static SleepRoutineTemplate? fromJsonValue(Object? value) {
    if (value is! Map) {
      return null;
    }
    final map = value.cast<Object?, Object?>();
    final id = '${map['id'] ?? ''}'.trim();
    if (id.isEmpty) {
      return null;
    }
    final stepsRaw = map['steps'];
    final steps = stepsRaw is List
        ? stepsRaw
              .map(SleepRoutineStep.fromJsonValue)
              .whereType<SleepRoutineStep>()
              .toList(growable: false)
        : const <SleepRoutineStep>[];
    return SleepRoutineTemplate(
      id: id,
      name: '${map['name'] ?? ''}'.trim(),
      totalMinutes: _readInt(map['total_minutes']) ?? 0,
      steps: steps,
      builtIn: map['built_in'] == true,
      updatedAt: _readDateTime(map['updated_at']) ?? DateTime.now(),
    );
  }

  static List<SleepRoutineTemplate> builtInDefaults() {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    return <SleepRoutineTemplate>[
      SleepRoutineTemplate(
        id: 'quick_reset',
        name: 'Quick reset',
        totalMinutes: 15,
        steps: const <SleepRoutineStep>[
          SleepRoutineStep(
            type: SleepRoutineStepType.dimLights,
            label: 'Dim lights',
            durationSeconds: 60,
          ),
          SleepRoutineStep(
            type: SleepRoutineStepType.stopScreens,
            label: 'Put the screen away',
            durationSeconds: 120,
          ),
          SleepRoutineStep(
            type: SleepRoutineStepType.prepareRoom,
            label: 'Cool and darken the room',
            durationSeconds: 120,
          ),
          SleepRoutineStep(
            type: SleepRoutineStepType.breathing,
            label: 'Slow breathing',
            durationSeconds: 300,
          ),
          SleepRoutineStep(
            type: SleepRoutineStepType.soothingAudio,
            label: 'Low-stim soothing audio',
            durationSeconds: 240,
          ),
          SleepRoutineStep(
            type: SleepRoutineStepType.goToBed,
            label: 'Go to bed',
            durationSeconds: 180,
          ),
        ],
        builtIn: true,
        updatedAt: epoch,
      ),
      SleepRoutineTemplate(
        id: 'standard_wind_down',
        name: 'Standard wind-down',
        totalMinutes: 30,
        steps: const <SleepRoutineStep>[
          SleepRoutineStep(
            type: SleepRoutineStepType.dimLights,
            label: 'Lower lights',
            durationSeconds: 120,
          ),
          SleepRoutineStep(
            type: SleepRoutineStepType.stopScreens,
            label: 'End stimulating input',
            durationSeconds: 180,
          ),
          SleepRoutineStep(
            type: SleepRoutineStepType.prepareRoom,
            label: 'Prepare a darker, cooler room',
            durationSeconds: 180,
          ),
          SleepRoutineStep(
            type: SleepRoutineStepType.unloadThoughts,
            label: 'Unload thoughts',
            durationSeconds: 300,
          ),
          SleepRoutineStep(
            type: SleepRoutineStepType.breathing,
            label: 'Slow exhale breathing',
            durationSeconds: 420,
          ),
          SleepRoutineStep(
            type: SleepRoutineStepType.soothingAudio,
            label: 'Settle with audio',
            durationSeconds: 360,
          ),
          SleepRoutineStep(
            type: SleepRoutineStepType.goToBed,
            label: 'Go to bed quietly',
            durationSeconds: 240,
          ),
        ],
        builtIn: true,
        updatedAt: epoch,
      ),
      SleepRoutineTemplate(
        id: 'deep_release',
        name: 'Deep release',
        totalMinutes: 45,
        steps: const <SleepRoutineStep>[
          SleepRoutineStep(
            type: SleepRoutineStepType.dimLights,
            label: 'Lower lights and noise',
            durationSeconds: 180,
          ),
          SleepRoutineStep(
            type: SleepRoutineStepType.warmBath,
            label: 'Warm bath or foot soak',
            durationSeconds: 480,
          ),
          SleepRoutineStep(
            type: SleepRoutineStepType.stopScreens,
            label: 'End screens',
            durationSeconds: 240,
          ),
          SleepRoutineStep(
            type: SleepRoutineStepType.unloadThoughts,
            label: 'Worry unload',
            durationSeconds: 420,
          ),
          SleepRoutineStep(
            type: SleepRoutineStepType.stretch,
            label: 'Gentle stretch',
            durationSeconds: 420,
          ),
          SleepRoutineStep(
            type: SleepRoutineStepType.breathing,
            label: 'Breathing reset',
            durationSeconds: 480,
          ),
          SleepRoutineStep(
            type: SleepRoutineStepType.bodyScan,
            label: 'Body scan',
            durationSeconds: 360,
          ),
          SleepRoutineStep(
            type: SleepRoutineStepType.whiteNoise,
            label: 'Set white noise',
            durationSeconds: 180,
          ),
          SleepRoutineStep(
            type: SleepRoutineStepType.soothingAudio,
            label: 'Quiet audio',
            durationSeconds: 360,
          ),
          SleepRoutineStep(
            type: SleepRoutineStepType.goToBed,
            label: 'Settle into bed',
            durationSeconds: 240,
          ),
        ],
        builtIn: true,
        updatedAt: epoch,
      ),
    ];
  }
}

const Object _sleepRoutineUnset = Object();

class SleepRoutineRunnerState {
  const SleepRoutineRunnerState({
    this.activeTemplateId,
    this.currentStepIndex = 0,
    this.remainingSeconds = 0,
    this.isRunning = false,
    this.isPaused = false,
    this.startedAt,
  });

  final String? activeTemplateId;
  final int currentStepIndex;
  final int remainingSeconds;
  final bool isRunning;
  final bool isPaused;
  final DateTime? startedAt;

  SleepRoutineRunnerState copyWith({
    Object? activeTemplateId = _sleepRoutineUnset,
    int? currentStepIndex,
    int? remainingSeconds,
    bool? isRunning,
    bool? isPaused,
    Object? startedAt = _sleepRoutineUnset,
  }) {
    return SleepRoutineRunnerState(
      activeTemplateId: activeTemplateId == _sleepRoutineUnset
          ? this.activeTemplateId
          : activeTemplateId as String?,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      startedAt: startedAt == _sleepRoutineUnset
          ? this.startedAt
          : startedAt as DateTime?,
    );
  }
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

DateTime? _readDateTime(Object? value) {
  final raw = '$value'.trim();
  if (raw.isEmpty || raw == 'null') {
    return null;
  }
  return DateTime.tryParse(raw);
}

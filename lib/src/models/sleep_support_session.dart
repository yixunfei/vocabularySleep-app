enum SleepSupportIntent { prepareForSleep, nightWaking, distressed }

enum SleepSupportStep {
  releaseDay(
    'toolbox.sleep.support.step.releaseDay.title',
    'toolbox.sleep.support.step.releaseDay.body',
  ),
  softenBody(
    'toolbox.sleep.support.step.softenBody.title',
    'toolbox.sleep.support.step.softenBody.body',
  ),
  wakingSettle(
    'toolbox.sleep.support.step.wakingSettle.title',
    'toolbox.sleep.support.step.wakingSettle.body',
  ),
  distressSettle(
    'toolbox.sleep.support.step.distressSettle.title',
    'toolbox.sleep.support.step.distressSettle.body',
  ),
  chooseMethod(
    'toolbox.sleep.support.step.chooseMethod.title',
    'toolbox.sleep.support.step.chooseMethod.body',
  ),
  easeThoughts(
    'toolbox.sleep.support.step.easeThoughts.title',
    'toolbox.sleep.support.step.easeThoughts.body',
  ),
  easeTension(
    'toolbox.sleep.support.step.easeTension.title',
    'toolbox.sleep.support.step.easeTension.body',
  ),
  adjustTemperature(
    'toolbox.sleep.support.step.adjustTemperature.title',
    'toolbox.sleep.support.step.adjustTemperature.body',
  ),
  leaveBed(
    'toolbox.sleep.support.step.leaveBed.title',
    'toolbox.sleep.support.step.leaveBed.body',
  ),
  awayFromBed(
    'toolbox.sleep.support.step.awayFromBed.title',
    'toolbox.sleep.support.step.awayFromBed.body',
  );

  const SleepSupportStep(this.titleKey, this.bodyKey);

  final String titleKey;
  final String bodyKey;
}

enum SleepSupportChoice {
  continueGuide('toolbox.sleep.support.choice.continueGuide'),
  stillAwake('toolbox.sleep.support.choice.stillAwake'),
  sleepy('toolbox.sleep.support.choice.sleepy'),
  racingThoughts('toolbox.sleep.support.choice.racingThoughts'),
  bodyTension('toolbox.sleep.support.choice.bodyTension'),
  temperature('toolbox.sleep.support.choice.temperature'),
  leftBed('toolbox.sleep.support.choice.leftBed'),
  returnedToBed('toolbox.sleep.support.choice.returnedToBed'),
  rest('toolbox.sleep.support.choice.rest');

  const SleepSupportChoice(this.labelKey);

  final String labelKey;
}

/// A support session describes acknowledged actions, never inferred sleep.
class SleepSupportSession {
  const SleepSupportSession({
    required this.id,
    required this.intent,
    required this.startedAt,
    required this.step,
    this.hasEngaged = false,
    this.hasLeftBed = false,
    this.returnedToBedAt,
    this.endedAt,
    this.isResting = false,
    this.isFinished = false,
    this.isPersisting = false,
    this.saveFailed = false,
    this.isSaved = false,
  });

  final String id;
  final SleepSupportIntent intent;
  final DateTime startedAt;
  final SleepSupportStep step;
  final bool hasEngaged;
  final bool hasLeftBed;
  final DateTime? returnedToBedAt;
  final DateTime? endedAt;
  final bool isResting;
  final bool isFinished;
  final bool isPersisting;
  final bool saveFailed;
  final bool isSaved;

  String get titleKey => step.titleKey;
  String get bodyKey => step.bodyKey;

  List<SleepSupportChoice> get choices {
    if (isFinished || isResting) return const [];
    return switch (step) {
      SleepSupportStep.releaseDay => const [SleepSupportChoice.continueGuide],
      SleepSupportStep.softenBody => const [SleepSupportChoice.rest],
      SleepSupportStep.wakingSettle => const [
        SleepSupportChoice.sleepy,
        SleepSupportChoice.stillAwake,
      ],
      SleepSupportStep.distressSettle ||
      SleepSupportStep.chooseMethod => const [
        SleepSupportChoice.racingThoughts,
        SleepSupportChoice.bodyTension,
        SleepSupportChoice.temperature,
      ],
      SleepSupportStep.leaveBed => const [
        SleepSupportChoice.leftBed,
        SleepSupportChoice.rest,
      ],
      SleepSupportStep.awayFromBed => const [SleepSupportChoice.returnedToBed],
      _ => const [SleepSupportChoice.rest],
    };
  }

  SleepSupportSession copyWith({
    SleepSupportStep? step,
    bool? hasEngaged,
    bool? hasLeftBed,
    DateTime? returnedToBedAt,
    DateTime? endedAt,
    bool? isResting,
    bool? isFinished,
    bool? isPersisting,
    bool? saveFailed,
    bool? isSaved,
  }) {
    return SleepSupportSession(
      id: id,
      intent: intent,
      startedAt: startedAt,
      step: step ?? this.step,
      hasEngaged: hasEngaged ?? this.hasEngaged,
      hasLeftBed: hasLeftBed ?? this.hasLeftBed,
      returnedToBedAt: returnedToBedAt ?? this.returnedToBedAt,
      endedAt: endedAt ?? this.endedAt,
      isResting: isResting ?? this.isResting,
      isFinished: isFinished ?? this.isFinished,
      isPersisting: isPersisting ?? this.isPersisting,
      saveFailed: saveFailed ?? this.saveFailed,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

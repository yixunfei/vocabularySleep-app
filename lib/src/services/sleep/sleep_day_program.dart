import '../../models/sleep_plan.dart';

/// Calendar-day progress never advances because a button was pressed twice.
abstract final class SleepDayProgram {
  static int duration(SleepProgramType type) =>
      type == SleepProgramType.fourteenDaySleepReset ? 14 : 7;

  static int todayDay(SleepProgramProgress progress, {required DateTime now}) {
    final start = progress.startedAt.toLocal();
    final today = now.toLocal();
    // UTC date-only values avoid DST days of 23 or 25 hours.
    return DateTime.utc(
          today.year,
          today.month,
          today.day,
        ).difference(DateTime.utc(start.year, start.month, start.day)).inDays +
        1;
  }

  static bool canComplete(
    SleepProgramProgress progress,
    int day, {
    required DateTime now,
  }) =>
      !progress.isCompleted &&
      day >= 1 &&
      day <= duration(progress.programType) &&
      day == todayDay(progress, now: now) &&
      !progress.completedDays.contains(day);

  static SleepProgramProgress complete(
    SleepProgramProgress progress,
    int day, {
    required DateTime now,
  }) {
    if (!canComplete(progress, day, now: now)) return progress;
    final days = {...progress.completedDays, day};
    final total = duration(progress.programType);
    return progress.copyWith(
      currentDay: day,
      completedDays: days,
      // A cycle ends on its final date even when earlier days were skipped.
      isCompleted: day == total,
    );
  }

  static String actionKey(SleepProgramType type, int day) {
    final actions = switch (type) {
      SleepProgramType.insomniaStarter => const [
        'rest',
        'light',
        'worry',
        'room',
        'caffeine',
        'routine',
        'review',
      ],
      SleepProgramType.sevenDayRhythmReset => const [
        'wake',
        'light',
        'caffeine',
        'move',
        'room',
        'routine',
        'review',
      ],
      SleepProgramType.fourteenDaySleepReset => const [
        'wake',
        'light',
        'caffeine',
        'move',
        'room',
        'worry',
        'review',
        'wake',
        'light',
        'rest',
        'move',
        'routine',
        'worry',
        'review',
      ],
    };
    return 'toolbox.sleep.day.action.${actions[(day - 1).clamp(0, actions.length - 1)]}';
  }
}

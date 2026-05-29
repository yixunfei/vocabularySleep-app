import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../../models/sleep_daily_log.dart';
import '../../models/sleep_plan.dart';
import '../../models/sleep_profile.dart';
import '../../models/sleep_routine_template.dart';

String todaySleepDateKey() {
  return sleepDateKeyFromDateTime(DateTime.now());
}

String sleepDateKeyFromDateTime(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String pickSleepText(AppI18n i18n, {required String zh, required String en}) {
  return AppI18n.normalizeLanguageCode(i18n.languageCode) == 'zh' ? zh : en;
}

Color sleepReadableAccent(
  BuildContext context,
  Color color, {
  double darkBlend = 0.30,
}) {
  if (Theme.of(context).colorScheme.brightness != Brightness.dark) {
    return color;
  }
  return Color.lerp(color, Colors.white, darkBlend) ?? color;
}

Widget sleepModuleTheme({
  required BuildContext context,
  required bool enabled,
  required Widget child,
}) {
  if (!enabled) {
    return child;
  }
  final base = Theme.of(context);
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF8FB9A8),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFFA9D7C2),
        onPrimary: const Color(0xFF0F2B23),
        primaryContainer: const Color(0xFF214A3C),
        onPrimaryContainer: const Color(0xFFE1F6EC),
        secondary: const Color(0xFFC3C9E8),
        onSecondary: const Color(0xFF24283F),
        tertiary: const Color(0xFFE2C49E),
        onTertiary: const Color(0xFF382A16),
        surface: const Color(0xFF0C1216),
        onSurface: const Color(0xFFE8EEF0),
        surfaceContainerLowest: const Color(0xFF080D10),
        surfaceContainerLow: const Color(0xFF121B20),
        surfaceContainer: const Color(0xFF172229),
        surfaceContainerHigh: const Color(0xFF1D2A31),
        surfaceContainerHighest: const Color(0xFF26353D),
        onSurfaceVariant: const Color(0xFFC3CED2),
        outline: const Color(0xFF789098),
        outlineVariant: const Color(0xFF32454D),
        errorContainer: const Color(0xFF5E282D),
        onErrorContainer: const Color(0xFFFFDADC),
      );
  final textTheme = _sleepDarkTextTheme(base.textTheme, colorScheme);
  return Theme(
    data: base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF090F12),
      canvasColor: colorScheme.surface,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: const Color(0xFF090F12),
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.28),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainerHigh,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: colorScheme.surfaceContainerLow,
        checkmarkColor: colorScheme.onPrimaryContainer,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        iconColor: colorScheme.primary,
        textColor: colorScheme.onSurface,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
          disabledForegroundColor: colorScheme.onSurfaceVariant,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainer,
        modalBackgroundColor: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: colorScheme.outline,
      ),
      dividerTheme: base.dividerTheme.copyWith(
        color: colorScheme.outlineVariant,
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainerHighest,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      timePickerTheme: base.timePickerTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainer,
        dialBackgroundColor: colorScheme.surfaceContainerLow,
        hourMinuteColor: colorScheme.surfaceContainerHigh,
        hourMinuteTextColor: colorScheme.onSurface,
      ),
    ),
    child: child,
  );
}

TextTheme _sleepDarkTextTheme(TextTheme base, ColorScheme colorScheme) {
  TextStyle? primary(TextStyle? style) =>
      style?.copyWith(color: colorScheme.onSurface);
  TextStyle? secondary(TextStyle? style) =>
      style?.copyWith(color: colorScheme.onSurfaceVariant);
  return base.copyWith(
    displayLarge: primary(base.displayLarge),
    displayMedium: primary(base.displayMedium),
    displaySmall: primary(base.displaySmall),
    headlineLarge: primary(base.headlineLarge),
    headlineMedium: primary(base.headlineMedium),
    headlineSmall: primary(base.headlineSmall),
    titleLarge: primary(base.titleLarge),
    titleMedium: primary(base.titleMedium),
    titleSmall: primary(base.titleSmall),
    bodyLarge: primary(base.bodyLarge),
    bodyMedium: primary(base.bodyMedium),
    bodySmall: secondary(base.bodySmall),
    labelLarge: primary(base.labelLarge),
    labelMedium: secondary(base.labelMedium),
    labelSmall: secondary(base.labelSmall),
  );
}

String sleepIssueLabel(AppI18n i18n, SleepIssueType issue) {
  return switch (issue) {
    SleepIssueType.difficultyFallingAsleep => i18n.t('toolbox.sleep.support.issue.hard_fall_asleep'),
    SleepIssueType.frequentAwakenings => i18n.t('toolbox.sleep.support.issue.frequent_awakenings'),
    SleepIssueType.earlyAwakening => i18n.t('toolbox.sleep.support.issue.early_awakening'),
    SleepIssueType.nonRestorativeSleep => i18n.t('toolbox.sleep.support.issue.non_restorative'),
    SleepIssueType.irregularSchedule => i18n.t('toolbox.sleep.support.issue.irregular_schedule'),
    SleepIssueType.racingThoughts => i18n.t('toolbox.sleep.support.issue.racing_thoughts'),
    SleepIssueType.daytimeSleepiness => i18n.t('toolbox.sleep.support.issue.daytime_sleepiness'),
    SleepIssueType.snoringRisk => i18n.t('toolbox.sleep.support.issue.snoring_risk'),
    SleepIssueType.painOrTension => i18n.t('toolbox.sleep.support.issue.pain_tension'),
  };
}

String sleepRiskLabel(AppI18n i18n, SleepRiskLevel risk) {
  return switch (risk) {
    SleepRiskLevel.none => i18n.t('toolbox.sleep.support.risk.low'),
    SleepRiskLevel.mild => i18n.t('toolbox.sleep.support.risk.mild'),
    SleepRiskLevel.medium => i18n.t('toolbox.sleep.support.risk.medium'),
    SleepRiskLevel.high => i18n.t('toolbox.sleep.support.risk.high'),
  };
}

String sleepNightModeLabel(AppI18n i18n, SleepNightRescueMode mode) {
  return switch (mode) {
    SleepNightRescueMode.briefAwakening => i18n.t('toolbox.sleep.support.mode.brief'),
    SleepNightRescueMode.fullyAwake => i18n.t('toolbox.sleep.support.mode.fully_awake'),
    SleepNightRescueMode.racingThoughts => i18n.t('toolbox.sleep.support.mode.racing_thoughts'),
    SleepNightRescueMode.bodyActivated => i18n.t('toolbox.sleep.support.mode.body_activated'),
    SleepNightRescueMode.temperatureDiscomfort => i18n.t('toolbox.sleep.support.mode.temperature'),
  };
}

String sleepNightModeBody(AppI18n i18n, SleepNightRescueMode mode) {
  return switch (mode) {
    SleepNightRescueMode.briefAwakening => i18n.t('toolbox.sleep.support.mode_body.brief'),
    SleepNightRescueMode.fullyAwake => i18n.t('toolbox.sleep.support.mode_body.fully_awake'),
    SleepNightRescueMode.racingThoughts => i18n.t('toolbox.sleep.support.mode_body.racing_thoughts'),
    SleepNightRescueMode.bodyActivated => i18n.t('toolbox.sleep.support.mode_body.body_activated'),
    SleepNightRescueMode.temperatureDiscomfort => i18n.t('toolbox.sleep.support.mode_body.temperature'),
  };
}

String sleepTrackLabel(AppI18n i18n, SleepPlanTrack track) {
  return switch (track) {
    SleepPlanTrack.observation => i18n.t('toolbox.sleep.support.track.observation'),
    SleepPlanTrack.windDown => i18n.t('toolbox.sleep.support.track.wind_down'),
    SleepPlanTrack.insomniaSupport => i18n.t('toolbox.sleep.support.track.insomnia'),
    SleepPlanTrack.rhythmReset => i18n.t('toolbox.sleep.support.track.rhythm_reset'),
    SleepPlanTrack.environmentFix => i18n.t('toolbox.sleep.support.track.environment'),
    SleepPlanTrack.daytimeRecovery => i18n.t('toolbox.sleep.support.track.recovery'),
  };
}

String sleepProgramLabel(AppI18n i18n, SleepProgramType type) {
  return switch (type) {
    SleepProgramType.sevenDayRhythmReset => i18n.t('toolbox.sleep.support.program.rhythm_7'),
    SleepProgramType.fourteenDaySleepReset => i18n.t('toolbox.sleep.support.program.reset_14'),
    SleepProgramType.insomniaStarter => i18n.t('toolbox.sleep.support.program.starter'),
  };
}

String sleepProgramBody(AppI18n i18n, SleepProgramType type) {
  return switch (type) {
    SleepProgramType.sevenDayRhythmReset => i18n.t('toolbox.sleep.support.program_body.rhythm_7'),
    SleepProgramType.fourteenDaySleepReset => i18n.t('toolbox.sleep.support.program_body.reset_14'),
    SleepProgramType.insomniaStarter => i18n.t('toolbox.sleep.support.program_body.starter'),
  };
}

String sleepRoutineStepTypeLabel(AppI18n i18n, SleepRoutineStepType type) {
  return switch (type) {
    SleepRoutineStepType.dimLights => i18n.t('toolbox.sleep.support.step.dim_lights'),
    SleepRoutineStepType.stopScreens => i18n.t('toolbox.sleep.support.step.stop_screens'),
    SleepRoutineStepType.prepareRoom => i18n.t('toolbox.sleep.support.step.prepare_room'),
    SleepRoutineStepType.unloadThoughts => i18n.t('toolbox.sleep.support.step.unload_thoughts'),
    SleepRoutineStepType.breathing => i18n.t('toolbox.sleep.support.step.breathing'),
    SleepRoutineStepType.stretch => i18n.t('toolbox.sleep.support.step.stretch'),
    SleepRoutineStepType.warmBath => i18n.t('toolbox.sleep.support.step.warm_bath'),
    SleepRoutineStepType.whiteNoise => i18n.t('toolbox.sleep.support.step.white_noise'),
    SleepRoutineStepType.soothingAudio => i18n.t('toolbox.sleep.support.step.soothing_audio'),
    SleepRoutineStepType.bodyScan => i18n.t('toolbox.sleep.support.step.body_scan'),
    SleepRoutineStepType.goToBed => i18n.t('toolbox.sleep.support.step.go_to_bed'),
  };
}

String sleepRoutineTemplateName(AppI18n i18n, SleepRoutineTemplate template) {
  return switch (template.id) {
    'minimum_energy_shutdown' => i18n.t('toolbox.sleep.support.template.tiny'),
    'quick_reset' => i18n.t('toolbox.sleep.support.template.quick_reset'),
    'standard_wind_down' => i18n.t('toolbox.sleep.support.template.standard'),
    _ => template.name,
  };
}

String sleepRoutineStepLabel(AppI18n i18n, SleepRoutineStep step) {
  return switch (step.label) {
    'Dim only the lights you can reach' => i18n.t('toolbox.sleep.support.template_step.tiny1'),
    'Put the screen face down' => i18n.t('toolbox.sleep.support.template_step.tiny2'),
    'Park one loud thought' => i18n.t('toolbox.sleep.support.template_step.tiny3'),
    'Longer exhale breathing' => i18n.t('toolbox.sleep.support.template_step.tiny4'),
    'Get into bed without adding tasks' => i18n.t('toolbox.sleep.support.template_step.tiny5'),
    _ =>
      step.label.trim().isEmpty
          ? sleepRoutineStepTypeLabel(i18n, step.type)
          : step.label,
  };
}

String sleepMinutesLabel(int? minutes, {bool long = false, AppI18n? i18n}) {
  if (minutes == null || minutes <= 0) {
    return '--';
  }
  final hours = minutes ~/ 60;
  final remain = minutes % 60;
  if (!long) {
    if (hours <= 0) {
      return '${remain}m';
    }
    if (remain <= 0) {
      return '${hours}h';
    }
    return '${hours}h ${remain}m';
  }
  final resolved = i18n ?? AppI18n('zh');
  if (hours <= 0) {
    return pickSleepText(resolved, zh: '$remain 分钟', en: '$remain minutes');
  }
  if (remain <= 0) {
    return pickSleepText(resolved, zh: '$hours 小时', en: '$hours hours');
  }
  return pickSleepText(
    resolved,
    zh: '$hours 小时 $remain 分钟',
    en: '$hours h $remain min',
  );
}

String sleepSecondsLabel(int seconds, {AppI18n? i18n}) {
  if (seconds <= 0) {
    return '--';
  }
  final minutes = seconds ~/ 60;
  if (seconds % 60 == 0) {
    return sleepMinutesLabel(minutes, long: true, i18n: i18n);
  }
  final resolved = i18n ?? AppI18n('zh');
  if (minutes <= 0) {
    return pickSleepText(resolved, zh: '$seconds 秒', en: '$seconds sec');
  }
  return pickSleepText(
    resolved,
    zh: '$minutes 分 ${seconds % 60} 秒',
    en: '$minutes min ${seconds % 60} sec',
  );
}

String sleepPercentLabel(double? value) {
  if (value == null) {
    return '--';
  }
  return '${(value * 100).round()}%';
}

String sleepScoreLabel(int? value, {int max = 5}) {
  if (value == null || value <= 0) {
    return '--';
  }
  return '$value/$max';
}

String sleepDateLabel(String dateKey) {
  final parsed = tryParseSleepDateKey(dateKey);
  if (parsed == null) {
    return dateKey;
  }
  final month = parsed.month.toString().padLeft(2, '0');
  final day = parsed.day.toString().padLeft(2, '0');
  return '${parsed.year}-$month-$day';
}

DateTime? tryParseSleepDateKey(String raw) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw.trim());
  if (match == null) {
    return null;
  }
  final year = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  final day = int.tryParse(match.group(3)!);
  if (year == null || month == null || day == null) {
    return null;
  }
  return DateTime(year, month, day);
}

String sleepDateTimeLabel(DateTime? value) {
  if (value == null) {
    return '--';
  }
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$month-$day $hour:$minute';
}

String sleepTimeOfDayLabel(TimeOfDay? value) {
  if (value == null) {
    return '--';
  }
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String timeOfDayToStorage(TimeOfDay? value) {
  return value == null ? '' : sleepTimeOfDayLabel(value);
}

TimeOfDay? tryParseTimeOfDay(String raw) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw.trim());
  if (match == null) {
    return null;
  }
  final hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null ||
      minute == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59) {
    return null;
  }
  return TimeOfDay(hour: hour, minute: minute);
}

TimeOfDay? timeOfDayFromDateTime(DateTime? value) {
  if (value == null) {
    return null;
  }
  return TimeOfDay(hour: value.hour, minute: value.minute);
}

DateTime? sleepDateTimeFromTimeOfDay(
  String dateKey,
  TimeOfDay? time, {
  required bool bedtimeSide,
}) {
  final baseDate = tryParseSleepDateKey(dateKey);
  if (baseDate == null || time == null) {
    return null;
  }
  final anchor = bedtimeSide && time.hour >= 12
      ? baseDate.subtract(const Duration(days: 1))
      : baseDate;
  return DateTime(
    anchor.year,
    anchor.month,
    anchor.day,
    time.hour,
    time.minute,
  );
}

String sleepIntensityLabel(AppI18n i18n, int? value) {
  final resolved = value ?? 0;
  if (resolved <= 1) {
    return i18n.t('toolbox.sleep.support.intensity.very_low');
  }
  if (resolved == 2) {
    return i18n.t('toolbox.sleep.support.intensity.low');
  }
  if (resolved == 3) {
    return i18n.t('toolbox.sleep.support.intensity.moderate');
  }
  if (resolved == 4) {
    return i18n.t('toolbox.sleep.support.intensity.high');
  }
  return i18n.t('toolbox.sleep.support.intensity.very_high');
}

String sleepFrequencyLabel(AppI18n i18n, int? value) {
  final resolved = value ?? 0;
  if (resolved <= 1) {
    return i18n.t('toolbox.sleep.support.frequency.rare');
  }
  if (resolved == 2) {
    return i18n.t('toolbox.sleep.support.frequency.sometimes');
  }
  if (resolved == 3) {
    return i18n.t('toolbox.sleep.support.frequency.often');
  }
  if (resolved == 4) {
    return i18n.t('toolbox.sleep.support.frequency.frequent');
  }
  return i18n.t('toolbox.sleep.support.frequency.daily');
}

String sleepBooleanStatus(AppI18n i18n, bool value) {
  return value
      ? i18n.t('toolbox.sleep.support.bool.recorded')
      : i18n.t('toolbox.sleep.support.bool.not_recorded');
}

String sleepWakeBurdenLabel(AppI18n i18n, SleepDailyLog log) {
  final burden = sleepWakeBurdenValue(log);
  if (burden <= 1) {
    return i18n.t('toolbox.sleep.support.burden.low');
  }
  if (burden == 2) {
    return i18n.t('toolbox.sleep.support.burden.medium');
  }
  return i18n.t('toolbox.sleep.support.burden.high');
}

int sleepWakeBurdenValue(SleepDailyLog log) {
  final wakeMinutes = log.nightWakeTotalMinutes;
  final wakeCount = log.nightWakeCount;
  if (wakeCount <= 1 && wakeMinutes <= 10) {
    return 1;
  }
  if (wakeCount <= 2 && wakeMinutes <= 30) {
    return 2;
  }
  return 3;
}

String sleepAssessmentFactorTitle(AppI18n i18n, String factorId) {
  return switch (factorId) {
    'stressLoadLevel' => i18n.t('toolbox.sleep.support.factor.stress'),
    'screenDependenceLevel' => i18n.t('toolbox.sleep.support.factor.screen'),
    'lateWorkFrequency' => i18n.t('toolbox.sleep.support.factor.late_work'),
    'exerciseLateFrequency' => i18n.t('toolbox.sleep.support.factor.late_exercise'),
    'painImpactLevel' => i18n.t('toolbox.sleep.support.factor.pain'),
    'snoringRisk' => i18n.t('toolbox.sleep.support.factor.snoring'),
    _ => factorId,
  };
}

String sleepAssessmentFactorHint(AppI18n i18n, String factorId) {
  return switch (factorId) {
    'stressLoadLevel' => i18n.t('toolbox.sleep.support.factor_hint.stress'),
    'screenDependenceLevel' => i18n.t('toolbox.sleep.support.factor_hint.screen'),
    'lateWorkFrequency' => i18n.t('toolbox.sleep.support.factor_hint.late_work'),
    'exerciseLateFrequency' => i18n.t('toolbox.sleep.support.factor_hint.late_exercise'),
    'painImpactLevel' => i18n.t('toolbox.sleep.support.factor_hint.pain'),
    'snoringRisk' => i18n.t('toolbox.sleep.support.factor_hint.snoring'),
    _ => '',
  };
}

String sleepDailyFactorTitle(AppI18n i18n, String factorId) {
  return switch (factorId) {
    'caffeineAfterCutoff' => i18n.t('toolbox.sleep.support.daily.late_caffeine'),
    'lateScreenExposure' => i18n.t('toolbox.sleep.support.daily.late_screens'),
    'alcoholAtNight' => i18n.t('toolbox.sleep.support.daily.alcohol'),
    'morningLightDone' => i18n.t('toolbox.sleep.support.daily.morning_light'),
    'heavyDinner' => i18n.t('toolbox.sleep.support.daily.heavy_dinner'),
    'intenseExerciseLate' => i18n.t('toolbox.sleep.support.daily.late_exercise'),
    'hotBathDone' => i18n.t('toolbox.sleep.support.daily.warm_bath'),
    'stretchingDone' => i18n.t('toolbox.sleep.support.daily.stretching'),
    'whiteNoiseUsed' => i18n.t('toolbox.sleep.support.daily.white_noise'),
    'bedroomTooHot' => i18n.t('toolbox.sleep.support.daily.room_hot'),
    'bedroomTooBright' => i18n.t('toolbox.sleep.support.daily.room_bright'),
    'bedroomTooNoisy' => i18n.t('toolbox.sleep.support.daily.room_noisy'),
    'clockChecking' => i18n.t('toolbox.sleep.support.daily.clock_checking'),
    _ => factorId,
  };
}

String sleepDailyFactorHint(AppI18n i18n, String factorId) {
  return switch (factorId) {
    'caffeineAfterCutoff' => i18n.t('toolbox.sleep.support.daily_hint.caffeine'),
    'lateScreenExposure' => i18n.t('toolbox.sleep.support.daily_hint.screens'),
    'alcoholAtNight' => i18n.t('toolbox.sleep.support.daily_hint.alcohol'),
    'morningLightDone' => i18n.t('toolbox.sleep.support.daily_hint.morning_light'),
    'clockChecking' => i18n.t('toolbox.sleep.support.daily_hint.clock'),
    'whiteNoiseUsed' => i18n.t('toolbox.sleep.support.daily_hint.white_noise'),
    _ => '',
  };
}

List<String> recentSleepDateKeys({DateTime? anchor, int count = 7}) {
  final base = anchor ?? DateTime.now();
  return List<String>.generate(
    count,
    (index) => sleepDateKeyFromDateTime(base.subtract(Duration(days: index))),
    growable: false,
  );
}

double? averageSleepDouble(Iterable<double?> values) {
  final resolved = values.whereType<double>().toList(growable: false);
  if (resolved.isEmpty) {
    return null;
  }
  final total = resolved.fold<double>(0, (sum, value) => sum + value);
  return total / resolved.length;
}

int? averageSleepInt(Iterable<int?> values) {
  final resolved = values.whereType<int>().toList(growable: false);
  if (resolved.isEmpty) {
    return null;
  }
  final total = resolved.fold<int>(0, (sum, value) => sum + value);
  return (total / resolved.length).round();
}

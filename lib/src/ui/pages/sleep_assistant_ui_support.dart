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
    SleepIssueType.difficultyFallingAsleep => pickSleepText(
      i18n,
      zh: '入睡困难',
      en: 'Hard to fall asleep',
    ),
    SleepIssueType.frequentAwakenings => pickSleepText(
      i18n,
      zh: '夜里容易醒',
      en: 'Frequent awakenings',
    ),
    SleepIssueType.earlyAwakening => pickSleepText(
      i18n,
      zh: '早醒',
      en: 'Early awakening',
    ),
    SleepIssueType.nonRestorativeSleep => pickSleepText(
      i18n,
      zh: '睡后不解乏',
      en: 'Non-restorative sleep',
    ),
    SleepIssueType.irregularSchedule => pickSleepText(
      i18n,
      zh: '作息不规律',
      en: 'Irregular schedule',
    ),
    SleepIssueType.racingThoughts => pickSleepText(
      i18n,
      zh: '脑子停不下来',
      en: 'Racing thoughts',
    ),
    SleepIssueType.daytimeSleepiness => pickSleepText(
      i18n,
      zh: '白天犯困',
      en: 'Daytime sleepiness',
    ),
    SleepIssueType.snoringRisk => pickSleepText(
      i18n,
      zh: '打鼾风险',
      en: 'Snoring risk',
    ),
    SleepIssueType.painOrTension => pickSleepText(
      i18n,
      zh: '疼痛或紧绷',
      en: 'Pain or tension',
    ),
  };
}

String sleepRiskLabel(AppI18n i18n, SleepRiskLevel risk) {
  return switch (risk) {
    SleepRiskLevel.none => pickSleepText(i18n, zh: '无明显风险', en: 'Low'),
    SleepRiskLevel.mild => pickSleepText(i18n, zh: '轻度', en: 'Mild'),
    SleepRiskLevel.medium => pickSleepText(i18n, zh: '中度', en: 'Medium'),
    SleepRiskLevel.high => pickSleepText(i18n, zh: '较高', en: 'High'),
  };
}

String sleepNightModeLabel(AppI18n i18n, SleepNightRescueMode mode) {
  return switch (mode) {
    SleepNightRescueMode.briefAwakening => pickSleepText(
      i18n,
      zh: '短暂醒来',
      en: 'Brief awakening',
    ),
    SleepNightRescueMode.fullyAwake => pickSleepText(
      i18n,
      zh: '完全清醒',
      en: 'Fully awake',
    ),
    SleepNightRescueMode.racingThoughts => pickSleepText(
      i18n,
      zh: '思绪停不下来',
      en: 'Racing thoughts',
    ),
    SleepNightRescueMode.bodyActivated => pickSleepText(
      i18n,
      zh: '身体太兴奋',
      en: 'Body activated',
    ),
    SleepNightRescueMode.temperatureDiscomfort => pickSleepText(
      i18n,
      zh: '温度或环境不适',
      en: 'Temperature discomfort',
    ),
  };
}

String sleepNightModeBody(AppI18n i18n, SleepNightRescueMode mode) {
  return switch (mode) {
    SleepNightRescueMode.briefAwakening => pickSleepText(
      i18n,
      zh: '先别急着做事，保持低刺激，观察困意会不会自己回来。',
      en: 'Stay low-stim and let the sleep drive come back on its own.',
    ),
    SleepNightRescueMode.fullyAwake => pickSleepText(
      i18n,
      zh: '如果越躺越清醒，先离床，做一件单调、安静、不会越做越兴奋的事。',
      en: 'If you are clearly awake, leave bed and do something calm and boring.',
    ),
    SleepNightRescueMode.racingThoughts => pickSleepText(
      i18n,
      zh: '不要继续在床上解决问题，先把念头停放，再回到呼吸和身体。',
      en: 'Stop problem-solving in bed and park the thoughts first.',
    ),
    SleepNightRescueMode.bodyActivated => pickSleepText(
      i18n,
      zh: '先把身体唤醒度降下来，用更长呼气、放松肩颈或轻柔伸展。',
      en: 'Lower body activation first with longer exhales or gentle release.',
    ),
    SleepNightRescueMode.temperatureDiscomfort => pickSleepText(
      i18n,
      zh: '优先处理过热、过冷、闷、亮或被窝不适，再决定要不要离床。',
      en: 'Fix heat, cold, light, or bedding discomfort before deciding next.',
    ),
  };
}

String sleepTrackLabel(AppI18n i18n, SleepPlanTrack track) {
  return switch (track) {
    SleepPlanTrack.observation => pickSleepText(
      i18n,
      zh: '观察计划',
      en: 'Observation',
    ),
    SleepPlanTrack.windDown => pickSleepText(i18n, zh: '睡前减压', en: 'Wind-down'),
    SleepPlanTrack.insomniaSupport => pickSleepText(
      i18n,
      zh: '失眠支持',
      en: 'Insomnia support',
    ),
    SleepPlanTrack.rhythmReset => pickSleepText(
      i18n,
      zh: '节律重建',
      en: 'Rhythm reset',
    ),
    SleepPlanTrack.environmentFix => pickSleepText(
      i18n,
      zh: '环境修正',
      en: 'Environment fix',
    ),
    SleepPlanTrack.daytimeRecovery => pickSleepText(
      i18n,
      zh: '白天恢复',
      en: 'Daytime recovery',
    ),
  };
}

String sleepProgramLabel(AppI18n i18n, SleepProgramType type) {
  return switch (type) {
    SleepProgramType.sevenDayRhythmReset => pickSleepText(
      i18n,
      zh: '7 天节律重建',
      en: '7-day rhythm reset',
    ),
    SleepProgramType.fourteenDaySleepReset => pickSleepText(
      i18n,
      zh: '14 天睡眠重启',
      en: '14-day sleep reset',
    ),
    SleepProgramType.insomniaStarter => pickSleepText(
      i18n,
      zh: '失眠起步计划',
      en: 'Insomnia starter',
    ),
  };
}

String sleepProgramBody(AppI18n i18n, SleepProgramType type) {
  return switch (type) {
    SleepProgramType.sevenDayRhythmReset => pickSleepText(
      i18n,
      zh: '先稳住起床时间、晨光和咖啡因截止线，重新拉直作息。',
      en: 'Stabilize wake time, morning light, and caffeine cutoff first.',
    ),
    SleepProgramType.fourteenDaySleepReset => pickSleepText(
      i18n,
      zh: '连续两周记录日志、执行睡前流程，并对照周报做小步调整。',
      en: 'Build two weeks around logs, routines, and small weekly adjustments.',
    ),
    SleepProgramType.insomniaStarter => pickSleepText(
      i18n,
      zh: '优先练习夜醒应对、离床策略和担忧卸载，再看是否需要更进阶调整。',
      en: 'Learn rescue, leave-bed strategy, and worry unload before stricter work.',
    ),
  };
}

String sleepRoutineStepTypeLabel(AppI18n i18n, SleepRoutineStepType type) {
  return switch (type) {
    SleepRoutineStepType.dimLights => pickSleepText(
      i18n,
      zh: '调暗灯光',
      en: 'Dim lights',
    ),
    SleepRoutineStepType.stopScreens => pickSleepText(
      i18n,
      zh: '停止看屏',
      en: 'Stop screens',
    ),
    SleepRoutineStepType.prepareRoom => pickSleepText(
      i18n,
      zh: '整理房间环境',
      en: 'Prepare room',
    ),
    SleepRoutineStepType.unloadThoughts => pickSleepText(
      i18n,
      zh: '卸载思绪',
      en: 'Unload thoughts',
    ),
    SleepRoutineStepType.breathing => pickSleepText(
      i18n,
      zh: '呼吸放松',
      en: 'Breathing',
    ),
    SleepRoutineStepType.stretch => pickSleepText(
      i18n,
      zh: '轻柔拉伸',
      en: 'Stretch',
    ),
    SleepRoutineStepType.warmBath => pickSleepText(
      i18n,
      zh: '热水澡或泡脚',
      en: 'Warm bath',
    ),
    SleepRoutineStepType.whiteNoise => pickSleepText(
      i18n,
      zh: '白噪音',
      en: 'White noise',
    ),
    SleepRoutineStepType.soothingAudio => pickSleepText(
      i18n,
      zh: '舒缓声音',
      en: 'Soothing audio',
    ),
    SleepRoutineStepType.bodyScan => pickSleepText(
      i18n,
      zh: '身体扫描',
      en: 'Body scan',
    ),
    SleepRoutineStepType.goToBed => pickSleepText(
      i18n,
      zh: '上床准备睡',
      en: 'Go to bed',
    ),
  };
}

String sleepRoutineTemplateName(AppI18n i18n, SleepRoutineTemplate template) {
  return switch (template.id) {
    'minimum_energy_shutdown' => pickSleepText(
      i18n,
      zh: '最低能量睡前流程',
      en: 'Tiny wind-down',
    ),
    'quick_reset' => pickSleepText(i18n, zh: '快速重置', en: 'Quick reset'),
    'standard_wind_down' => pickSleepText(
      i18n,
      zh: '标准睡前放松',
      en: 'Standard wind-down',
    ),
    _ => template.name,
  };
}

String sleepRoutineStepLabel(AppI18n i18n, SleepRoutineStep step) {
  return switch (step.label) {
    'Dim only the lights you can reach' => pickSleepText(
      i18n,
      zh: '只调暗伸手够得到的灯',
      en: 'Dim only the lights you can reach',
    ),
    'Put the screen face down' => pickSleepText(
      i18n,
      zh: '把屏幕朝下放好',
      en: 'Put the screen face down',
    ),
    'Park one loud thought' => pickSleepText(
      i18n,
      zh: '停放一个最吵的念头',
      en: 'Park one loud thought',
    ),
    'Longer exhale breathing' => pickSleepText(
      i18n,
      zh: '做更长呼气的呼吸',
      en: 'Longer exhale breathing',
    ),
    'Get into bed without adding tasks' => pickSleepText(
      i18n,
      zh: '进床，不再加任务',
      en: 'Get into bed without adding tasks',
    ),
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
    return pickSleepText(i18n, zh: '很低', en: 'Very low');
  }
  if (resolved == 2) {
    return pickSleepText(i18n, zh: '偏低', en: 'Low');
  }
  if (resolved == 3) {
    return pickSleepText(i18n, zh: '中等', en: 'Moderate');
  }
  if (resolved == 4) {
    return pickSleepText(i18n, zh: '偏高', en: 'High');
  }
  return pickSleepText(i18n, zh: '很高', en: 'Very high');
}

String sleepFrequencyLabel(AppI18n i18n, int? value) {
  final resolved = value ?? 0;
  if (resolved <= 1) {
    return pickSleepText(i18n, zh: '偶尔', en: 'Rare');
  }
  if (resolved == 2) {
    return pickSleepText(i18n, zh: '有时', en: 'Sometimes');
  }
  if (resolved == 3) {
    return pickSleepText(i18n, zh: '经常', en: 'Often');
  }
  if (resolved == 4) {
    return pickSleepText(i18n, zh: '很频繁', en: 'Frequent');
  }
  return pickSleepText(i18n, zh: '几乎每天', en: 'Nearly daily');
}

String sleepBooleanStatus(AppI18n i18n, bool value) {
  return value
      ? pickSleepText(i18n, zh: '已记录', en: 'Yes')
      : pickSleepText(i18n, zh: '未记录', en: 'No');
}

String sleepWakeBurdenLabel(AppI18n i18n, SleepDailyLog log) {
  final burden = sleepWakeBurdenValue(log);
  if (burden <= 1) {
    return pickSleepText(i18n, zh: '低', en: 'Low');
  }
  if (burden == 2) {
    return pickSleepText(i18n, zh: '中', en: 'Moderate');
  }
  return pickSleepText(i18n, zh: '高', en: 'High');
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
    'stressLoadLevel' => pickSleepText(i18n, zh: '压力负荷', en: 'Stress load'),
    'screenDependenceLevel' => pickSleepText(
      i18n,
      zh: '屏幕依赖',
      en: 'Screen dependence',
    ),
    'lateWorkFrequency' => pickSleepText(i18n, zh: '晚间工作', en: 'Late work'),
    'exerciseLateFrequency' => pickSleepText(
      i18n,
      zh: '晚间剧烈运动',
      en: 'Late exercise',
    ),
    'painImpactLevel' => pickSleepText(
      i18n,
      zh: '疼痛或紧绷',
      en: 'Pain or tension',
    ),
    'snoringRisk' => pickSleepText(i18n, zh: '打鼾风险', en: 'Snoring risk'),
    _ => factorId,
  };
}

String sleepAssessmentFactorHint(AppI18n i18n, String factorId) {
  return switch (factorId) {
    'stressLoadLevel' => pickSleepText(
      i18n,
      zh: '压力越高，越需要把担忧和任务从床上挪走。',
      en: 'Higher stress means more need for worry unload before bed.',
    ),
    'screenDependenceLevel' => pickSleepText(
      i18n,
      zh: '不仅是蓝光，更是内容刺激会顶掉困意。',
      en: 'It is not only light; stimulating content can override sleepiness.',
    ),
    'lateWorkFrequency' => pickSleepText(
      i18n,
      zh: '晚间脑力工作会把大脑维持在解决问题模式。',
      en: 'Late cognitive work keeps the brain in problem-solving mode.',
    ),
    'exerciseLateFrequency' => pickSleepText(
      i18n,
      zh: '太晚的高强度运动可能抬高体温和唤醒度。',
      en: 'Very late intense exercise can raise activation and body temperature.',
    ),
    'painImpactLevel' => pickSleepText(
      i18n,
      zh: '先识别是痛感、紧绷还是姿势与环境问题。',
      en: 'Separate pain, tension, and posture or environment triggers.',
    ),
    'snoringRisk' => pickSleepText(
      i18n,
      zh: '如伴随憋醒、头痛或白天极困，需要更认真评估。',
      en: 'If paired with gasping or strong daytime sleepiness, assess further.',
    ),
    _ => '',
  };
}

String sleepDailyFactorTitle(AppI18n i18n, String factorId) {
  return switch (factorId) {
    'caffeineAfterCutoff' => pickSleepText(
      i18n,
      zh: '咖啡因超线',
      en: 'Late caffeine',
    ),
    'lateScreenExposure' => pickSleepText(
      i18n,
      zh: '临睡前看屏',
      en: 'Late screens',
    ),
    'alcoholAtNight' => pickSleepText(i18n, zh: '夜间饮酒', en: 'Alcohol at night'),
    'morningLightDone' => pickSleepText(i18n, zh: '晨光暴露', en: 'Morning light'),
    'heavyDinner' => pickSleepText(i18n, zh: '晚餐偏重', en: 'Heavy dinner'),
    'intenseExerciseLate' => pickSleepText(
      i18n,
      zh: '太晚运动',
      en: 'Late intense exercise',
    ),
    'hotBathDone' => pickSleepText(i18n, zh: '热水澡/泡脚', en: 'Warm bath'),
    'stretchingDone' => pickSleepText(i18n, zh: '拉伸放松', en: 'Stretching'),
    'whiteNoiseUsed' => pickSleepText(i18n, zh: '白噪音', en: 'White noise'),
    'bedroomTooHot' => pickSleepText(i18n, zh: '卧室太热', en: 'Room too hot'),
    'bedroomTooBright' => pickSleepText(
      i18n,
      zh: '卧室太亮',
      en: 'Room too bright',
    ),
    'bedroomTooNoisy' => pickSleepText(i18n, zh: '卧室太吵', en: 'Room too noisy'),
    'clockChecking' => pickSleepText(i18n, zh: '反复看时间', en: 'Clock checking'),
    _ => factorId,
  };
}

String sleepDailyFactorHint(AppI18n i18n, String factorId) {
  return switch (factorId) {
    'caffeineAfterCutoff' => pickSleepText(
      i18n,
      zh: '多数人可以先尝试把截止线放到上床前 8 小时左右。',
      en: 'A practical first cutoff is often around eight hours before bed.',
    ),
    'lateScreenExposure' => pickSleepText(
      i18n,
      zh: '高唤醒内容比单纯刷一会更影响入睡。',
      en: 'Highly stimulating content matters more than screen light alone.',
    ),
    'alcoholAtNight' => pickSleepText(
      i18n,
      zh: '酒精可能让前半夜困，但常破坏后半夜连续性。',
      en: 'Alcohol may increase drowsiness but often fragments the second half.',
    ),
    'morningLightDone' => pickSleepText(
      i18n,
      zh: '晨起尽快接触自然光，是最强的节律锚点之一。',
      en: 'Morning outdoor light is one of the strongest rhythm anchors.',
    ),
    'clockChecking' => pickSleepText(
      i18n,
      zh: '反复确认时间会放大焦虑和性能压力。',
      en: 'Repeated clock checking often amplifies sleep pressure anxiety.',
    ),
    'whiteNoiseUsed' => pickSleepText(
      i18n,
      zh: '更适合掩盖不稳定噪声，不是人人都需要。',
      en: 'Best for masking unstable noise, not necessary for everyone.',
    ),
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

import 'dart:math' as math;

enum ToolboxDateMathDirection { add, subtract }

class ToolboxDateDifference {
  const ToolboxDateDifference({
    required this.start,
    required this.end,
    required this.isNegative,
    required this.years,
    required this.months,
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.totalSeconds,
    required this.totalMinutes,
    required this.totalHours,
    required this.totalDays,
    required this.approxYears,
  });

  final DateTime start;
  final DateTime end;
  final bool isNegative;
  final int years;
  final int months;
  final int days;
  final int hours;
  final int minutes;
  final int seconds;
  final int totalSeconds;
  final double totalMinutes;
  final double totalHours;
  final double totalDays;
  final double approxYears;
}

class ToolboxDateOffsetInput {
  const ToolboxDateOffsetInput({
    required this.start,
    required this.direction,
    this.years = '',
    this.months = '',
    this.days = '',
    this.hours = '',
    this.minutes = '',
    this.seconds = '',
  });

  final DateTime start;
  final ToolboxDateMathDirection direction;
  final String years;
  final String months;
  final String days;
  final String hours;
  final String minutes;
  final String seconds;
}

class ToolboxDateOffsetResult {
  const ToolboxDateOffsetResult({
    required this.start,
    required this.end,
    required this.direction,
    required this.signedSeconds,
    required this.calendarYears,
    required this.calendarMonths,
    required this.fractionalYearSeconds,
    required this.fractionalMonthSeconds,
    required this.durationSeconds,
  });

  final DateTime start;
  final DateTime end;
  final ToolboxDateMathDirection direction;
  final int signedSeconds;
  final int calendarYears;
  final int calendarMonths;
  final int fractionalYearSeconds;
  final int fractionalMonthSeconds;
  final int durationSeconds;
}

class ToolboxTimeProgress {
  const ToolboxTimeProgress({
    required this.key,
    required this.start,
    required this.end,
    required this.now,
    required this.elapsed,
    required this.remaining,
    required this.progress,
  });

  final String key;
  final DateTime start;
  final DateTime end;
  final DateTime now;
  final Duration elapsed;
  final Duration remaining;
  final double progress;

  double get remainingRatio => (1 - progress).clamp(0.0, 1.0);
  bool get isComplete => progress >= 1;
}

class ToolboxTargetProgress {
  const ToolboxTargetProgress({
    required this.start,
    required this.target,
    required this.now,
    required this.elapsed,
    required this.remaining,
    required this.progress,
    required this.isComplete,
    required this.isBeforeStart,
  });

  final DateTime start;
  final DateTime target;
  final DateTime now;
  final Duration elapsed;
  final Duration remaining;
  final double progress;
  final bool isComplete;
  final bool isBeforeStart;
}

class ToolboxLifeCandleProgress {
  const ToolboxLifeCandleProgress({
    required this.birth,
    required this.expectedEnd,
    required this.now,
    required this.expectedYears,
    required this.elapsed,
    required this.remaining,
    required this.burnedRatio,
  });

  final DateTime birth;
  final DateTime expectedEnd;
  final DateTime now;
  final double expectedYears;
  final Duration elapsed;
  final Duration remaining;
  final double burnedRatio;

  double get waxRatio => (1 - burnedRatio).clamp(0.0, 1.0);
}

class ToolboxDateCalculatorService {
  static const double averageGregorianYearDays = 365.2425;
  static const double defaultExpectedLifeYears = 79.0;

  ToolboxDateDifference difference(DateTime start, DateTime end) {
    final isNegative = end.isBefore(start);
    final low = isNegative ? end : start;
    final high = isNegative ? start : end;
    var cursor = low;
    var years = 0;
    var months = 0;

    while (true) {
      final next = _addCalendarYears(cursor, 1);
      if (next.isAfter(high)) {
        break;
      }
      years += 1;
      cursor = next;
    }

    while (true) {
      final next = _addCalendarMonths(cursor, 1);
      if (next.isAfter(high)) {
        break;
      }
      months += 1;
      cursor = next;
    }

    final remainder = high.difference(cursor);
    final total = high.difference(low);
    final totalSeconds = total.inSeconds;
    return ToolboxDateDifference(
      start: start,
      end: end,
      isNegative: isNegative,
      years: years,
      months: months,
      days: remainder.inDays,
      hours: remainder.inHours % Duration.hoursPerDay,
      minutes: remainder.inMinutes % Duration.minutesPerHour,
      seconds: remainder.inSeconds % Duration.secondsPerMinute,
      totalSeconds: totalSeconds,
      totalMinutes: totalSeconds / Duration.secondsPerMinute,
      totalHours: totalSeconds / Duration.secondsPerHour,
      totalDays: totalSeconds / Duration.secondsPerDay,
      approxYears:
          totalSeconds / (averageGregorianYearDays * Duration.secondsPerDay),
    );
  }

  ToolboxDateOffsetResult offset(ToolboxDateOffsetInput input) {
    final sign = input.direction == ToolboxDateMathDirection.add ? 1 : -1;
    final yearValue = parseFlexibleNumber(input.years);
    final monthValue = parseFlexibleNumber(input.months);
    final dayValue = parseFlexibleNumber(input.days);
    final hourValue = parseFlexibleNumber(input.hours);
    final minuteValue = parseFlexibleNumber(input.minutes);
    final secondValue = parseFlexibleNumber(input.seconds);

    final calendarYears = yearValue.truncate();
    final calendarMonths = monthValue.truncate();
    var end = input.start;

    if (calendarYears != 0) {
      end = _addCalendarYears(end, sign * calendarYears);
    }
    if (calendarMonths != 0) {
      end = _addCalendarMonths(end, sign * calendarMonths);
    }

    final fractionalYearSeconds = _roundSeconds(
      (yearValue - calendarYears) * _secondsInCalendarYear(end),
    );
    final fractionalMonthSeconds = _roundSeconds(
      (monthValue - calendarMonths) * _secondsInCalendarMonth(end),
    );
    final durationSeconds = _roundSeconds(
      dayValue * Duration.secondsPerDay +
          hourValue * Duration.secondsPerHour +
          minuteValue * Duration.secondsPerMinute +
          secondValue,
    );
    final totalDurationSeconds =
        fractionalYearSeconds + fractionalMonthSeconds + durationSeconds;

    if (totalDurationSeconds != 0) {
      end = end.add(Duration(seconds: sign * totalDurationSeconds));
    }

    return ToolboxDateOffsetResult(
      start: input.start,
      end: end,
      direction: input.direction,
      signedSeconds: end.difference(input.start).inSeconds,
      calendarYears: calendarYears,
      calendarMonths: calendarMonths,
      fractionalYearSeconds: fractionalYearSeconds,
      fractionalMonthSeconds: fractionalMonthSeconds,
      durationSeconds: durationSeconds,
    );
  }

  List<ToolboxTimeProgress> currentPeriodProgress(DateTime now) {
    final hourStart = DateTime(now.year, now.month, now.day, now.hour);
    final dayStart = DateTime(now.year, now.month, now.day);
    final weekStart = dayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month);
    final yearStart = DateTime(now.year);
    return <ToolboxTimeProgress>[
      progressForRange(
        'hour',
        hourStart,
        hourStart.add(const Duration(hours: 1)),
        now,
      ),
      progressForRange(
        'day',
        dayStart,
        dayStart.add(const Duration(days: 1)),
        now,
      ),
      progressForRange(
        'week',
        weekStart,
        weekStart.add(const Duration(days: 7)),
        now,
      ),
      progressForRange(
        'month',
        monthStart,
        DateTime(now.year, now.month + 1),
        now,
      ),
      progressForRange('year', yearStart, DateTime(now.year + 1), now),
    ];
  }

  ToolboxTimeProgress progressForRange(
    String key,
    DateTime start,
    DateTime end,
    DateTime now,
  ) {
    final totalSeconds = end.difference(start).inSeconds.abs();
    if (totalSeconds <= 0) {
      return ToolboxTimeProgress(
        key: key,
        start: start,
        end: end,
        now: now,
        elapsed: Duration.zero,
        remaining: Duration.zero,
        progress: 1,
      );
    }
    final forward = !end.isBefore(start);
    final rawElapsed = forward ? now.difference(start) : start.difference(now);
    final elapsedSeconds = rawElapsed.inSeconds.clamp(0, totalSeconds).toInt();
    final remainingSeconds = math.max(0, totalSeconds - elapsedSeconds);
    return ToolboxTimeProgress(
      key: key,
      start: start,
      end: end,
      now: now,
      elapsed: Duration(seconds: elapsedSeconds),
      remaining: Duration(seconds: remainingSeconds),
      progress: elapsedSeconds / totalSeconds,
    );
  }

  ToolboxTargetProgress targetProgress({
    required DateTime start,
    required DateTime target,
    required DateTime now,
  }) {
    final totalSeconds = target.difference(start).inSeconds.abs();
    if (totalSeconds <= 0) {
      final complete = !now.isBefore(target);
      return ToolboxTargetProgress(
        start: start,
        target: target,
        now: now,
        elapsed: complete ? Duration.zero : Duration.zero,
        remaining: Duration.zero,
        progress: complete ? 1 : 0,
        isComplete: complete,
        isBeforeStart: false,
      );
    }

    final forward = !target.isBefore(start);
    final beforeStart = forward ? now.isBefore(start) : now.isAfter(start);
    final complete = forward ? !now.isBefore(target) : !now.isAfter(target);
    final rawElapsed = forward ? now.difference(start) : start.difference(now);
    final elapsedSeconds = rawElapsed.inSeconds.clamp(0, totalSeconds).toInt();
    final remainingRaw = forward
        ? target.difference(now)
        : now.difference(target);
    final remainingSeconds = remainingRaw.inSeconds
        .clamp(0, totalSeconds)
        .toInt();

    return ToolboxTargetProgress(
      start: start,
      target: target,
      now: now,
      elapsed: Duration(seconds: elapsedSeconds),
      remaining: Duration(seconds: remainingSeconds),
      progress: elapsedSeconds / totalSeconds,
      isComplete: complete,
      isBeforeStart: beforeStart,
    );
  }

  ToolboxLifeCandleProgress lifeCandle({
    required DateTime birth,
    required double expectedYears,
    required DateTime now,
  }) {
    final safeYears = expectedYears <= 0
        ? defaultExpectedLifeYears
        : expectedYears;
    final wholeYears = safeYears.truncate();
    var expectedEnd = _addCalendarYears(birth, wholeYears);
    final fractionalSeconds = _roundSeconds(
      (safeYears - wholeYears) * _secondsInCalendarYear(expectedEnd),
    );
    if (fractionalSeconds > 0) {
      expectedEnd = expectedEnd.add(Duration(seconds: fractionalSeconds));
    }
    final target = targetProgress(start: birth, target: expectedEnd, now: now);
    return ToolboxLifeCandleProgress(
      birth: birth,
      expectedEnd: expectedEnd,
      now: now,
      expectedYears: safeYears,
      elapsed: target.elapsed,
      remaining: target.remaining,
      burnedRatio: target.progress,
    );
  }

  static double parseFlexibleNumber(String raw) {
    final normalized = raw.trim().replaceAll(',', '');
    if (normalized.isEmpty) {
      return 0;
    }
    if (normalized.endsWith('%')) {
      final value = double.tryParse(
        normalized.substring(0, normalized.length - 1).trim(),
      );
      return (value ?? 0) / 100;
    }
    return double.tryParse(normalized) ?? 0;
  }

  static DateTime _addCalendarYears(DateTime value, int years) {
    return _addCalendarMonths(value, years * 12);
  }

  static DateTime _addCalendarMonths(DateTime value, int months) {
    final targetMonthIndex = value.month - 1 + months;
    final targetYear = value.year + targetMonthIndex ~/ 12;
    final targetMonth = targetMonthIndex.remainder(12) + 1;
    final targetDay = math.min(
      value.day,
      _daysInMonth(targetYear, targetMonth),
    );
    return DateTime(
      targetYear,
      targetMonth,
      targetDay,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
  }

  static int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  static int _secondsInCalendarMonth(DateTime anchor) {
    final start = DateTime(anchor.year, anchor.month);
    final end = DateTime(anchor.year, anchor.month + 1);
    return end.difference(start).inSeconds;
  }

  static int _secondsInCalendarYear(DateTime anchor) {
    final start = DateTime(anchor.year);
    final end = DateTime(anchor.year + 1);
    return end.difference(start).inSeconds;
  }

  static int _roundSeconds(double value) {
    if (!value.isFinite) {
      return 0;
    }
    return value.round();
  }
}

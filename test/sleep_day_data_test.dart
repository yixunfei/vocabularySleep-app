import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/models/sleep_daily_log.dart';
import 'package:vocabulary_sleep_app/src/models/sleep_plan.dart';
import 'package:vocabulary_sleep_app/src/services/sleep/sleep_day_program.dart';
import 'package:vocabulary_sleep_app/src/services/sleep/sleep_day_report.dart';
import 'package:vocabulary_sleep_app/src/services/sleep/sleep_log_draft.dart';

void main() {
  _recordTests();
  _reportTests();
  _programTests();
}

void _recordTests() {
  group('sparse daily records', () {
    test('one energy answer never fabricates sleep measurements or causes', () {
      final draft = SleepLogDraft(dateKey: '2026-09-09');
      draft.set('morning_energy', 1);
      final log = draft.build();
      expect(log.morningEnergy, 1);
      expect(log.estimatedTotalSleepMinutes, isNull);
      expect(log.sleepLatencyMinutes, isNull);
      expect(log.nightWakeCount, isNull);
      expect(log.nightWakeTotalMinutes, isNull);
      expect(log.napMinutes, isNull);
      expect(log.daytimeSleepiness, isNull);
      expect(log.stressPeakLevel, isNull);
      expect(log.lateScreenExposure, isNull);
      expect(log.bedtimeAt, isNull);
    });

    test('editing a score preserves all other existing measurements', () {
      final existing = SleepDailyLog(
        dateKey: '2026-09-09',
        bedtimeAt: DateTime(2026, 9, 8, 22, 43),
        estimatedTotalSleepMinutes: 367,
        sleepLatencyMinutes: 17,
        nightWakeCount: 2,
        nightWakeTotalMinutes: 34,
        napMinutes: 12,
        morningEnergy: 4,
        caffeineAfterCutoff: false,
        lateScreenExposure: true,
        notes: 'existing note',
      );
      final draft = SleepLogDraft(
        dateKey: existing.dateKey,
        existing: existing,
      );
      draft.set('morning_energy', 2);
      expect(draft.build().toJsonMap(), {
        ...existing.toJsonMap(),
        'morning_energy': 2,
      });
    });

    test(
      'explicit zero and false survive storage while unknown remains null',
      () {
        final log = SleepDailyLog.fromJsonValue({
          'date_key': '2026-09-09',
          'night_wake_count': 0,
          'caffeine_after_cutoff': false,
        })!;
        final restored = SleepDailyLog.fromJsonValue(log.toJsonMap())!;
        expect(restored.nightWakeCount, 0);
        expect(restored.nightWakeTotalMinutes, isNull);
        expect(restored.caffeineAfterCutoff, false);
        expect(restored.alcoholAtNight, isNull);
      },
    );

    test('clearing a value stays unknown and invalidates derived metrics', () {
      final draft = SleepLogDraft(
        dateKey: '2026-09-09',
        existing: const SleepDailyLog(
          dateKey: '2026-09-09',
          estimatedTotalSleepMinutes: 400,
          timeInBedMinutes: 500,
          sleepEfficiency: 0.8,
          caffeineAfterCutoff: true,
        ),
      );
      draft.set('estimated_total_sleep_minutes', null);
      draft.set('caffeine_after_cutoff', null);
      final log = draft.build();
      expect(log.estimatedTotalSleepMinutes, isNull);
      expect(log.sleepEfficiency, isNull);
      expect(log.timeInBedMinutes, isNull);
      expect(log.caffeineAfterCutoff, isNull);
    });

    test('notes append a real tag exactly once and preserve original text', () {
      expect(SleepLogDraft.appendNoteTag('note', 'travel'), 'note\ntravel');
      expect(
        SleepLogDraft.appendNoteTag('note\ntravel', 'travel'),
        'note\ntravel',
      );
      expect(SleepLogDraft.appendNoteTag('', 'travel'), 'travel');
      expect(SleepLogDraft.appendNoteTag('note', '  '), 'note');
    });
  });
}

void _reportTests() {
  group('calendar reports', () {
    test(
      'seven days excludes old, future, malformed dates and retains gaps',
      () {
        final report = SleepDayReport(
          [
            const SleepDailyLog(dateKey: '2026-08-01'),
            const SleepDailyLog(dateKey: '2026-09-02'),
            const SleepDailyLog(dateKey: '2026-09-03', morningEnergy: 2),
            const SleepDailyLog(dateKey: '2026-09-09', morningEnergy: 4),
            const SleepDailyLog(dateKey: '2026-09-10'),
            const SleepDailyLog(dateKey: '2026-02-31'),
          ],
          days: 7,
          now: DateTime(2026, 9, 9, 23, 59),
        );
        expect(report.dates, hasLength(7));
        expect(report.recordedLogs, hasLength(2));
        expect(report.logs.first?.morningEnergy, 2);
        expect(report.logs[1], isNull);
        expect(report.logs.last?.morningEnergy, 4);
      },
    );

    test('fourteen days crosses a month boundary and deduplicates a date', () {
      final report = SleepDayReport(
        [
          SleepDailyLog(
            dateKey: '2026-08-31',
            morningEnergy: 1,
            updatedAt: DateTime(2026, 9, 1),
          ),
          SleepDailyLog(
            dateKey: '2026-08-31',
            morningEnergy: 4,
            updatedAt: DateTime(2026, 9, 2),
          ),
        ],
        days: 14,
        now: DateTime(2026, 9, 1, 0, 1),
      );
      expect(SleepDayReport.dateKey(report.dates.first), '2026-08-19');
      expect(report.recordedLogs.single.morningEnergy, 4);
      expect(report.logs.last, isNull);
    });
  });
}

void _programTests() {
  group('one program action per calendar date', () {
    final start = DateTime(2026, 9, 9, 23, 50);
    final progress = SleepProgramProgress(
      programType: SleepProgramType.sevenDayRhythmReset,
      startedAt: start,
      currentDay: 1,
      completedDays: {},
      isCompleted: false,
    );

    test('future, past and invalid day requests do nothing', () {
      for (final day in [-1, 0, 2, 7, 8, 99]) {
        expect(
          identical(
            SleepDayProgram.complete(progress, day, now: start),
            progress,
          ),
          isTrue,
        );
      }
      expect(
        SleepDayProgram.canComplete(
          progress,
          1,
          now: start.subtract(const Duration(days: 1)),
        ),
        isFalse,
      );
    });

    test('repeated taps cannot advance beyond today', () {
      final done = SleepDayProgram.complete(progress, 1, now: start);
      expect(done.completedDays, {1});
      expect(done.currentDay, 1);
      expect(
        identical(SleepDayProgram.complete(done, 1, now: start), done),
        isTrue,
      );
      expect(
        identical(SleepDayProgram.complete(done, 2, now: start), done),
        isTrue,
      );
    });

    test('midnight unlocks tomorrow even if fewer than 24 hours passed', () {
      final tomorrow = DateTime(2026, 9, 10, 0, 1);
      expect(SleepDayProgram.todayDay(progress, now: tomorrow), 2);
      expect(SleepDayProgram.canComplete(progress, 2, now: tomorrow), isTrue);
      expect(SleepDayProgram.canComplete(progress, 1, now: tomorrow), isFalse);
    });

    test('last date closes the cycle without requiring missed-day catchup', () {
      final end = DateTime(2026, 9, 15);
      final done = SleepDayProgram.complete(progress, 7, now: end);
      expect(done.isCompleted, isTrue);
      expect(done.completedDays, {7});
      expect(
        SleepDayProgram.canComplete(progress, 8, now: DateTime(2026, 9, 16)),
        isFalse,
      );
    });
  });
}

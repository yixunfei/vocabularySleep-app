import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/i18n/app_i18n.dart';
import 'package:vocabulary_sleep_app/src/models/sleep_daily_log.dart';
import 'package:vocabulary_sleep_app/src/services/sleep/sleep_day_report.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/sleep_assistant_ui_support.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/sleep_support/sleep_day_history.dart';

void main() {
  _calendarTest();
  _historyWidgetTest();
}

void _calendarTest() {
  test(
    'history uses calendar dates and sorts repeated nights by actual time',
    () {
      final dates = SleepDayReport(
        [],
        days: 7,
        now: DateTime(2026, 9, 9),
      ).dates;
      final events = [
        const SleepNightEvent(
          dateKey: '2026-09-02',
          mode: SleepNightRescueMode.fullyAwake,
        ),
        SleepNightEvent(
          id: 'earlier',
          dateKey: '2026-09-03',
          mode: SleepNightRescueMode.racingThoughts,
          startedAt: DateTime(2026, 9, 3, 1),
        ),
        SleepNightEvent(
          id: 'later',
          dateKey: '2026-09-03',
          mode: SleepNightRescueMode.racingThoughts,
          startedAt: DateTime(2026, 9, 3, 3),
        ),
        const SleepNightEvent(
          id: 'today',
          dateKey: '2026-09-09',
          mode: SleepNightRescueMode.fullyAwake,
        ),
        const SleepNightEvent(
          dateKey: '2026-09-10',
          mode: SleepNightRescueMode.fullyAwake,
        ),
        const SleepNightEvent(
          dateKey: '2026-02-31',
          mode: SleepNightRescueMode.fullyAwake,
        ),
      ];
      expect(sleepNightEventsInWindow(events, dates).map((e) => e.id), [
        'today',
        'later',
        'earlier',
      ]);
      final fourteen = SleepDayReport(
        [],
        days: 14,
        now: DateTime(2026, 9, 9),
      ).dates;
      expect(sleepNightEventsInWindow(events, fourteen), hasLength(4));
    },
  );
}

void _historyWidgetTest() {
  testWidgets(
    'history is usable without diary data and never infers sleep or leaving bed',
    (tester) async {
      final i18n = AppI18n('en');
      final dates = SleepDayReport(
        [],
        days: 7,
        now: DateTime(2026, 9, 9),
      ).dates;
      final event = SleepNightEvent(
        dateKey: '2026-09-09',
        mode: SleepNightRescueMode.fullyAwake,
        startedAt: DateTime(2026, 9, 9, 1),
        endedAt: DateTime(2026, 9, 9, 1, 4),
        returnedToBedAt: DateTime(2026, 9, 9, 1, 3),
        notes: 'original note',
      );
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SleepDayHistory(events: [event], dates: dates, i18n: i18n),
            ),
          ),
        ),
      );
      await tester.tap(find.text(i18n.t('toolbox.sleep.day.history.title')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(sleepNightModeLabel(i18n, event.mode)));
      await tester.pumpAndSettle();
      expect(
        find.text(
          '${i18n.t('toolbox.sleep.day.history.left')}: '
          '${i18n.t('toolbox.sleep.day.unknown')}',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(i18n.t('toolbox.sleep.day.history.returned')),
        findsOneWidget,
      );
      expect(
        find.textContaining(i18n.t('toolbox.sleep.day.history.sleep_reported')),
        findsNothing,
      );
      expect(find.textContaining('original note'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

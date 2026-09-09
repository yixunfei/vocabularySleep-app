import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/models/sleep_daily_log.dart';
import 'package:vocabulary_sleep_app/src/models/sleep_routine_template.dart';
import 'package:vocabulary_sleep_app/src/repositories/sleep_repository.dart';
import 'package:vocabulary_sleep_app/src/state/app_state.dart';
import 'test_support/sleep_test_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SleepTestSettings store;
  late AppState state;
  setUp(() {
    store = SleepTestSettings();
    state = createSleepTestState(store);
  });
  tearDown(() => state.dispose());

  test('night entry before dashboard load preserves historical events', () {
    final repository = SettingsStoreSleepRepository(store);
    repository.saveSleepNightEvents([_event('old')]);
    state.saveSleepNightEvent(_event('new'));
    state.saveSleepNightEvent(_event('new'));
    expect(state.sleepNightEvents.map((e) => e.id).toSet(), {'old', 'new'});
    expect(repository.loadSleepNightEvents(), hasLength(2));
  });

  test('a failed night write does not publish a saved event', () {
    store.failingKey = 'sleepNightEvents';
    expect(() => state.saveSleepNightEvent(_event('a')), throwsStateError);
    expect(state.sleepNightEvents, isEmpty);
    store.failingKey = null;
    state.saveSleepNightEvent(_event('a'));
    expect(state.sleepNightEvents.single.id, 'a');
  });

  test(
    'sleep list snapshots stay stable and immutable until a data change',
    () async {
      await state.loadSleepAssistantData();
      final logs = state.sleepDailyLogs;
      expect(identical(state.sleepDailyLogs, logs), isTrue);
      expect(
        () => logs.add(const SleepDailyLog(dateKey: '2026-09-09')),
        throwsUnsupportedError,
      );
      state.saveSleepDailyLog(
        const SleepDailyLog(dateKey: '2026-09-09', morningEnergy: 2),
      );
      expect(identical(state.sleepDailyLogs, logs), isFalse);
      expect(logs, isEmpty);
      expect(state.sleepDailyLogs.single.nightWakeCount, isNull);
    },
  );

  testWidgets('routine clock never notifies the global app each second', (
    tester,
  ) async {
    await state.loadSleepAssistantData();
    final template = SleepRoutineTemplate.builtInDefaults().first;
    var notifications = 0;
    state.addListener(() => notifications++);
    state.startSleepRoutine(template.id);
    notifications = 0;
    await tester.pump(const Duration(seconds: 3));
    expect(notifications, 0);
    state.stopSleepRoutine();
  });

  test('saving an edited duration recomputes efficiency without fake data', () {
    state.saveSleepDailyLog(
      SleepDailyLog(
        dateKey: '2026-09-09',
        bedtimeAt: DateTime(2026, 9, 8, 23),
        outOfBedAt: DateTime(2026, 9, 9, 7),
        estimatedTotalSleepMinutes: 360,
      ),
    );
    expect(state.sleepDailyLogs.single.sleepEfficiency, .75);
    final saved = jsonDecode(store.values['sleepDailyLogs']!) as List;
    expect(saved.single['night_wake_count'], isNull);
    expect(saved.single['caffeine_after_cutoff'], isNull);
  });
}

SleepNightEvent _event(String id) => SleepNightEvent(
  id: id,
  dateKey: '2026-09-09',
  mode: SleepNightRescueMode.fullyAwake,
  startedAt: DateTime(2026, 9, 9, 2),
);

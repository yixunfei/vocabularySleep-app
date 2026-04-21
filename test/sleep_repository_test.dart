import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/sleep_daily_log.dart';
import 'package:vocabulary_sleep_app/src/models/sleep_plan.dart';
import 'package:vocabulary_sleep_app/src/models/sleep_profile.dart';
import 'package:vocabulary_sleep_app/src/models/sleep_routine_template.dart';
import 'package:vocabulary_sleep_app/src/repositories/sleep_repository.dart';
import 'package:vocabulary_sleep_app/src/repositories/settings_store_repository.dart';

class _MemorySettingsStoreRepository implements SettingsStoreRepository {
  final Map<String, String> _settings = <String, String>{};

  @override
  String? getSetting(String key) => _settings[key];

  @override
  void setSetting(String key, String value) {
    _settings[key] = value;
  }
}

void main() {
  test('sleep repository returns empty defaults for blank store', () {
    final repository = SettingsStoreSleepRepository(
      _MemorySettingsStoreRepository(),
    );

    expect(repository.loadSleepProfile(), isNull);
    expect(repository.loadSleepDailyLogs(), isEmpty);
    expect(repository.loadSleepNightEvents(), isEmpty);
    expect(repository.loadSleepThoughtEntries(), isEmpty);
    expect(repository.loadSleepCurrentPlan(), isNull);
    expect(repository.loadSleepRoutineTemplates(), isEmpty);
    expect(repository.loadSleepActiveRoutineTemplateId(), isNull);
    expect(repository.loadSleepDashboardState().lastReportRangeDays, 7);
    expect(repository.loadSleepProgramProgress(), isNull);
  });

  test('sleep repository persists and restores sleep state payloads', () {
    final repository = SettingsStoreSleepRepository(
      _MemorySettingsStoreRepository(),
    );
    final now = DateTime(2026, 4, 14, 22, 30);

    final profile = SleepProfile(
      primaryIssues: const <SleepIssueType>{SleepIssueType.irregularSchedule},
      typicalBedtime: '23:30',
      typicalWakeTime: '07:00',
      hasRacingThoughts: true,
      caffeineSensitive: true,
      snoringRisk: SleepRiskLevel.mild,
      painImpactLevel: 1,
      stressLoadLevel: 2,
      screenDependenceLevel: 2,
      lateWorkFrequency: 1,
      exerciseLateFrequency: 0,
      bedroomLightIssue: false,
      bedroomNoiseIssue: true,
      bedroomTempIssue: false,
      shiftWorkOrJetLag: false,
      refluxOrDigestiveDiscomfort: false,
      nightmaresOrDreamDistress: false,
      goal: 'Stabilize wake-up routine',
      createdAt: now,
      updatedAt: now,
    );

    final log = SleepDailyLog(
      dateKey: '2026-04-13',
      estimatedTotalSleepMinutes: 420,
      nightWakeCount: 1,
      morningEnergy: 3,
      createdAt: now,
      updatedAt: now,
    );
    final event = SleepNightEvent(
      dateKey: '2026-04-13',
      mode: SleepNightRescueMode.fullyAwake,
      startedAt: now,
      notes: 'Wake-up after loud noise',
    );
    final thought = SleepThoughtEntry(
      dateKey: '2026-04-13',
      entryType: 'worry',
      content: 'Project deadline',
      intensity: 2,
      createdAt: now,
    );
    final plan = SleepPlan(
      track: SleepPlanTrack.rhythmReset,
      title: 'Rhythm reset',
      summary: 'Keep wake-up time stable',
      primaryActions: const <String>[
        'Morning sunlight',
        'Consistent bedtime window',
      ],
      startedAt: now,
    );
    final template = SleepRoutineTemplate(
      id: 'test-template',
      name: 'Test routine',
      totalMinutes: 10,
      steps: const <SleepRoutineStep>[
        SleepRoutineStep(
          type: SleepRoutineStepType.dimLights,
          label: 'Dim lights',
          durationSeconds: 300,
        ),
        SleepRoutineStep(
          type: SleepRoutineStepType.breathing,
          label: 'Breathing',
          durationSeconds: 300,
        ),
      ],
      builtIn: false,
      updatedAt: now,
    );
    final dashboardState = SleepDashboardState(
      lastOpenedDateKey: '2026-04-14',
      selectedLogDateKey: '2026-04-13',
      lastReportRangeDays: 14,
      preferredQuickAction: 'wind_down',
      preferredWhiteNoiseId: 'rain',
    );
    final progress = SleepProgramProgress(
      programType: SleepProgramType.sevenDayRhythmReset,
      startedAt: now,
      currentDay: 3,
      completedDays: const <int>{1, 2},
      isCompleted: false,
    );

    repository.saveSleepProfile(profile);
    repository.saveSleepDailyLogs(<SleepDailyLog>[log]);
    repository.saveSleepNightEvents(<SleepNightEvent>[event]);
    repository.saveSleepThoughtEntries(<SleepThoughtEntry>[thought]);
    repository.saveSleepCurrentPlan(plan);
    repository.saveSleepRoutineTemplates(<SleepRoutineTemplate>[template]);
    repository.saveSleepActiveRoutineTemplateId('test-template');
    repository.saveSleepDashboardState(dashboardState);
    repository.saveSleepProgramProgress(progress);

    expect(repository.loadSleepProfile()?.goal, 'Stabilize wake-up routine');
    expect(repository.loadSleepDailyLogs().single.dateKey, '2026-04-13');
    expect(
      repository.loadSleepNightEvents().single.mode,
      SleepNightRescueMode.fullyAwake,
    );
    expect(
      repository.loadSleepThoughtEntries().single.content,
      'Project deadline',
    );
    expect(
      repository.loadSleepCurrentPlan()?.track,
      SleepPlanTrack.rhythmReset,
    );
    expect(repository.loadSleepRoutineTemplates().single.id, 'test-template');
    expect(repository.loadSleepActiveRoutineTemplateId(), 'test-template');
    expect(repository.loadSleepDashboardState().lastReportRangeDays, 14);
    expect(repository.loadSleepProgramProgress()?.currentDay, 3);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vocabulary_sleep_app/src/i18n/app_i18n.dart';
import 'package:vocabulary_sleep_app/src/models/sleep_daily_log.dart';
import 'package:vocabulary_sleep_app/src/models/sleep_plan.dart';
import 'package:vocabulary_sleep_app/src/models/sleep_profile.dart';
import 'package:vocabulary_sleep_app/src/state/app_state.dart';
import 'package:vocabulary_sleep_app/src/services/sleep/sleep_log_draft.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/sleep_support/sleep_log_detail_form.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/sleep_assessment_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/sleep_daily_log_page.dart';

class _DayState extends ChangeNotifier implements AppState {
  _DayState({this.uiLanguage = 'en', this.log});
  @override
  final String uiLanguage;
  SleepDailyLog? log;
  int saves = 0;
  bool failSave = false;
  @override
  final sleepDashboardState = const SleepDashboardState(
    selectedLogDateKey: '2026-09-09',
  );
  @override
  SleepAssessmentDraftState sleepAssessmentDraft =
      const SleepAssessmentDraftState();
  @override
  SleepProfile? sleepProfile;
  @override
  bool isModuleEnabled(String moduleId) => true;
  @override
  SleepDailyLog? sleepDailyLogByDateKey(String dateKey) => log;
  @override
  void saveSleepDailyLog(SleepDailyLog value) {
    if (failSave) throw StateError('test storage unavailable');
    log = value;
    saves++;
    notifyListeners();
  }

  @override
  void updateSleepAssessmentDraft(SleepAssessmentDraftState value) {
    sleepAssessmentDraft = value;
    notifyListeners();
  }

  @override
  void saveSleepProfile(SleepProfile value) {
    if (failSave) throw StateError('test storage unavailable');
    sleepProfile = value;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(WidgetTester tester, _DayState state, Widget page) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String label) async {
  final finder = find.text(label).first;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  _detailSyncTest();
  testWidgets(
    'quick diary records only the explicit answer and keeps details optional',
    (tester) async {
      final state = _DayState();
      final i18n = AppI18n('en');
      await _pump(tester, state, const SleepDailyLogPage());
      expect(find.byType(TextField), findsNothing);
      await _tap(tester, i18n.t('toolbox.sleep.log.flow.energy.1'));
      await _tap(tester, i18n.t('toolbox.sleep.day.skip'));
      await _tap(tester, i18n.t('toolbox.sleep.day.skip'));
      await _tap(tester, i18n.t('toolbox.sleep.log.saveCurrent'));
      expect(state.saves, 1);
      expect(state.log?.morningEnergy, 1);
      expect(state.log?.nightWakeCount, isNull);
      expect(state.log?.estimatedTotalSleepMinutes, isNull);
      expect(state.log?.lateScreenExposure, isNull);
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('skipping all diary questions does not save an empty entry', (
    tester,
  ) async {
    final state = _DayState();
    final i18n = AppI18n('en');
    await _pump(tester, state, const SleepDailyLogPage());
    for (var step = 0; step < 3; step++) {
      await _tap(tester, i18n.t('toolbox.sleep.day.skip'));
    }
    final save = tester.widget<FilledButton>(
      find.widgetWithText(
        FilledButton,
        i18n.t('toolbox.sleep.log.saveCurrent'),
      ),
    );
    expect(save.onPressed, isNull);
    expect(state.saves, 0);
  });

  testWidgets('quick edit preserves existing numeric and environmental facts', (
    tester,
  ) async {
    final state = _DayState(
      log: const SleepDailyLog(
        dateKey: '2026-09-09',
        estimatedTotalSleepMinutes: 367,
        nightWakeCount: 3,
        lateScreenExposure: true,
        morningEnergy: 4,
      ),
    );
    final i18n = AppI18n('en');
    await _pump(tester, state, const SleepDailyLogPage());
    await _tap(tester, i18n.t('toolbox.sleep.log.flow.energy.1'));
    await _tap(tester, i18n.t('toolbox.sleep.day.skip'));
    await _tap(tester, i18n.t('toolbox.sleep.day.skip'));
    await _tap(tester, i18n.t('toolbox.sleep.log.saveCurrent'));
    expect(state.log?.morningEnergy, 1);
    expect(state.log?.estimatedTotalSleepMinutes, 367);
    expect(state.log?.nightWakeCount, 3);
    expect(state.log?.lateScreenExposure, true);
  });

  _saveFailureTests();
  _layoutTests();
}

void _detailSyncTest() {
  testWidgets(
    'quick answers update visible detailed values without losing other input',
    (tester) async {
      final draft = SleepLogDraft(dateKey: '2026-09-09');
      draft.set('night_wake_count', 2);
      late StateSetter rebuild;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) {
                  rebuild = setState;
                  return SleepLogDetailForm(
                    draft: draft,
                    dateKey: '2026-09-09',
                    i18n: AppI18n('en'),
                    onChanged: () {},
                  );
                },
              ),
            ),
          ),
        ),
      );
      final field = find.byKey(const ValueKey('night_wake_count'));
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(field).controller!.text, '2');
      rebuild(() => draft.set('night_wake_count', 4));
      await tester.pump();
      expect(tester.widget<TextFormField>(field).controller!.text, '4');
      await tester.enterText(field, '3');
      expect(draft.build().nightWakeCount, 3);
      expect(tester.takeException(), isNull);
    },
  );
}

void _layoutTests() {
  for (final width in [320.0, 375.0, 600.0]) {
    for (final language in ['de', 'ru']) {
      testWidgets('day flows fit $width dp and $language with larger text', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(width, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final state = _DayState(uiLanguage: language);
        await _pump(tester, state, const SleepDailyLogPage());
        expect(find.byType(TextField), findsNothing);
        expect(tester.takeException(), isNull);
        await _pump(tester, state, const SleepAssessmentPage());
        expect(find.byType(TextField), findsNothing);
        expect(tester.takeException(), isNull);
        await _tap(tester, AppI18n(language).t('toolbox.sleep.day.skip'));
        expect(tester.takeException(), isNull);
      });
    }
  }
}

void _saveFailureTests() {
  testWidgets('diary failure retains chosen answers and can retry', (
    tester,
  ) async {
    final state = _DayState()..failSave = true;
    final i18n = AppI18n('en');
    await _pump(tester, state, const SleepDailyLogPage());
    await _tap(tester, i18n.t('toolbox.sleep.log.flow.energy.1'));
    await _tap(tester, i18n.t('toolbox.sleep.day.skip'));
    await _tap(tester, i18n.t('toolbox.sleep.day.skip'));
    await _tap(tester, i18n.t('toolbox.sleep.log.saveCurrent'));
    expect(find.text(i18n.t('toolbox.sleep.day.save_failed')), findsOneWidget);
    expect(state.saves, 0);
    state.failSave = false;
    await _tap(tester, i18n.t('toolbox.sleep.log.saveCurrent'));
    expect(state.log?.morningEnergy, 1);
    expect(state.saves, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('assessment failure keeps draft and allows a successful retry', (
    tester,
  ) async {
    final state = _DayState()..failSave = true;
    state.sleepAssessmentDraft = const SleepAssessmentDraftState(
      goal: 'existing goal',
      stressLoadLevel: 4,
    );
    final i18n = AppI18n('en');
    await _pump(tester, state, const SleepAssessmentPage());
    await _tap(tester, i18n.t('toolbox.sleep.day.skip'));
    await _tap(tester, i18n.t('toolbox.sleep.day.skip'));
    await _tap(tester, i18n.t('toolbox.sleep.assessment.save'));
    expect(find.text(i18n.t('toolbox.sleep.day.save_failed')), findsOneWidget);
    expect(state.sleepProfile, isNull);
    state.failSave = false;
    await _tap(tester, i18n.t('toolbox.sleep.assessment.save'));
    expect(state.sleepProfile?.goal, 'existing goal');
    expect(state.sleepProfile?.stressLoadLevel, 4);
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vocabulary_sleep_app/src/i18n/app_i18n.dart';
import 'package:vocabulary_sleep_app/src/i18n/app_i18n_catalog.dart';
import 'package:vocabulary_sleep_app/src/state/app_state.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_sleep_assistant_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/sleep_support/sleep_support_guide_page.dart';
import 'test_support/sleep_test_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppI18nCatalog.loadFromAssets);
  tearDownAll(AppI18nCatalog.resetForTesting);
  for (final width in [320.0, 375.0]) {
    testWidgets('night flow and sound controls work at $width x 667', (
      tester,
    ) async {
      final state = await _home(tester, width);
      final i18n = AppI18n(state.uiLanguage);
      expect(find.byType(TextField), findsNothing);
      final intent = find.byKey(const ValueKey('sleep-intent-awake'));
      if (width == 375) expect(tester.getBottomRight(intent).dy, lessThan(667));
      await tester.ensureVisible(intent);
      await tester.pumpAndSettle();
      await tester.tap(intent);
      await tester.tap(intent);
      await tester.pumpAndSettle();
      expect(find.byType(SleepSupportGuidePage), findsOneWidget);
      await _tapText(tester, i18n.t('toolbox.sleep.sound.status.silent'));
      expect(find.byKey(const ValueKey('sleep-sound-brown')), findsOneWidget);
      await _tapText(tester, i18n.t('toolbox.sleep.sound.silent'));
      Navigator.of(
        tester.element(find.byKey(const ValueKey('sleep-sound-silent'))),
      ).pop();
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('sleep-choice-sleepy')),
      );
      await tester.tap(find.byKey(const ValueKey('sleep-choice-sleepy')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('sleep-resume-guide')), findsOneWidget);
      expect(
        find.text(i18n.t('toolbox.sleep.sound.status.silent')),
        findsOneWidget,
      );
      final finish = find.text(i18n.t('toolbox.sleep.night.exit'));
      await tester.ensureVisible(finish);
      await tester.tap(finish);
      await tester.tap(finish);
      await tester.pumpAndSettle();
      expect(find.byType(ToolboxSleepAssistantPage), findsOneWidget);
      expect(find.byType(SleepSupportGuidePage), findsNothing);
      expect(state.sleepNightEvents, hasLength(1));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('failed night save can retry without losing the event', (
    tester,
  ) async {
    final store = SleepTestSettings()..failingKey = 'sleepNightEvents';
    final state = await _home(tester, 375, store: store);
    final i18n = AppI18n(state.uiLanguage);
    await tester.tap(find.byKey(const ValueKey('sleep-intent-awake')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sleep-choice-sleepy')));
    await tester.pumpAndSettle();
    await _tapText(tester, i18n.t('toolbox.sleep.night.exit'));
    expect(
      find.text(i18n.t('toolbox.sleep.night.save_failed')),
      findsOneWidget,
    );
    expect(state.sleepNightEvents, isEmpty);
    final eventId = state.sleepSupportSessionController.state!.id;
    store.failingKey = null;
    await _tapText(tester, i18n.t('toolbox.sleep.night.retry_save'));
    expect(state.sleepNightEvents.single.id, eventId);
    expect(find.byType(SleepSupportGuidePage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<AppState> _home(
  WidgetTester tester,
  double width, {
  SleepTestSettings? store,
}) async {
  tester.view.physicalSize = Size(width, 667);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final state = createSleepTestState(store ?? SleepTestSettings());
  addTearDown(state.dispose);
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
        home: const ToolboxSleepAssistantPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return state;
}

Future<void> _tapText(WidgetTester tester, String label) async {
  final target = find.text(label).first;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

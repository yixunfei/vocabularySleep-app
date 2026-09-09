import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/i18n/app_i18n.dart';
import 'package:vocabulary_sleep_app/src/i18n/app_i18n_catalog.dart';
import 'package:vocabulary_sleep_app/src/models/sleep_support_session.dart';
import 'package:vocabulary_sleep_app/src/services/sleep/sleep_support_session_controller.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/sleep_assistant_ui_support.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/sleep_support/sleep_night_home.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/sleep_support/sleep_night_stage.dart';

void main() {
  setUp(() {
    AppI18nCatalog.installForTesting({
      'de': {
        'toolbox.sleep.night.home.title': 'Jetzt nur eine kleine Sache',
        'toolbox.sleep.night.home.body':
            'Wähle, was gerade passt. Ohne Tippen.',
        'toolbox.sleep.night.home.daytime': 'Für den Tag',
        'toolbox.sleep.night.home.daytime_hint': 'Einträge und Einstellungen',
        'toolbox.sleep.night.intent.prepare': 'Ich gehe schlafen',
        'toolbox.sleep.night.intent.awake': 'Nachts aufgewacht',
        'toolbox.sleep.night.intent.distressed': 'Unruhig oder angespannt',
        'toolbox.sleep.support.step.wakingSettle.title':
            'Kein Grund, Schlaf zu erzwingen',
        'toolbox.sleep.support.step.wakingSettle.body':
            'Schau nicht auf die Uhr. Lockere die Schultern und spüre die Unterlage.',
        'toolbox.sleep.support.choice.sleepy': 'Etwas schläfrig, ausruhen',
        'toolbox.sleep.support.choice.stillAwake': 'Noch hellwach',
        'toolbox.sleep.support.choice.returnedToBed':
            'Schläfrig und wieder im Bett',
      },
    });
  });
  tearDown(AppI18nCatalog.resetForTesting);
  _homeTests();
  _wakingTests();
}

void _homeTests() {
  for (final width in [320.0, 375.0, 600.0]) {
    testWidgets('three immediate intents fit width $width with large text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final selected = <SleepSupportIntent>[];
      var daytimeOpened = false;
      await tester.pumpWidget(
        _harness(
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: SleepNightHome(
              i18n: AppI18n('de'),
              onIntent: selected.add,
              onDaytime: () => daytimeOpened = true,
            ),
          ),
        ),
      );
      expect(find.byType(TextField), findsNothing);
      for (final name in ['prepare', 'awake', 'distressed']) {
        final target = find.byKey(ValueKey('sleep-intent-$name'));
        expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
        await tester.tap(target);
      }
      expect(selected, SleepSupportIntent.values);
      await tester.ensureVisible(
        find.byKey(const ValueKey('sleep-daytime-entry')),
      );
      await tester.tap(find.byKey(const ValueKey('sleep-daytime-entry')));
      expect(daytimeOpened, isTrue);
      expect(tester.takeException(), isNull);
      final context = tester.element(find.byType(SleepNightHome));
      expect(Theme.of(context).brightness, Brightness.dark);
    });
  }
}

void _wakingTests() {
  testWidgets('night waking uses explicit leaving and returning actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = SleepSupportSessionController(saveEvent: (_) async {});
    addTearDown(controller.dispose);
    controller.start(SleepSupportIntent.nightWaking);
    await tester.pumpWidget(
      _harness(
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => _stage(controller),
        ),
      ),
    );
    expect(find.byType(TextField), findsNothing);
    expect(
      find.byKey(const ValueKey('sleep-choice-returnedToBed')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('sleep-choice-stillAwake')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('sleep-choice-leftBed')));
    await tester.pump();
    expect(controller.state!.returnedToBedAt, isNull);
    await tester.tap(find.byKey(const ValueKey('sleep-choice-returnedToBed')));
    await tester.pump();
    expect(controller.state!.returnedToBedAt, isNotNull);
    expect(find.byKey(const ValueKey('sleep-resume-guide')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sleep-resume-guide')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('sleep-choice-stillAwake')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _stage(SleepSupportSessionController controller) {
  return SleepNightStage(
    i18n: AppI18n('de'),
    session: controller.state!,
    onChoice: controller.choose,
    onSkip: controller.skip,
    onChangeMethod: controller.changeMethod,
    onRest: controller.rest,
    onResume: controller.resumeGuide,
    onFinish: controller.finish,
    soundPanel: const SizedBox.shrink(),
  );
}

Widget _harness(Widget child) {
  return MaterialApp(
    home: Builder(
      builder: (context) => sleepModuleTheme(
        context: context,
        enabled: true,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: Scaffold(body: SafeArea(child: child)),
          ),
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_human_tests.dart';
import 'package:vocabulary_sleep_app/src/ui/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('calculation test exposes richer settings and report entry', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: buildAppTheme(PlayConfig.defaults.appearance),
        home: const CalculationTestPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Calculation test'), findsWidgets);
    expect(find.text('Calculation settings'), findsOneWidget);
    expect(find.text('Difficulty'), findsOneWidget);
    expect(find.text('Operation type'), findsOneWidget);
    expect(find.text('Two-step'), findsOneWidget);
    expect(find.text('Timed'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);
  });

  testWidgets('dynamic vision symbol mode exposes sets paths and report', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: buildAppTheme(PlayConfig.defaults.appearance),
        home: const DynamicVisionTestPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Moving symbol'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Character set'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Character set'), findsOneWidget);
    expect(find.text('Confusable'), findsOneWidget);
    expect(find.text('Movement path'), findsOneWidget);
    expect(find.text('Bounce'), findsOneWidget);
    expect(find.text('Show faint distractors'), findsOneWidget);
  });

  testWidgets('luck and sustained attention expose goals and richer tasks', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: buildAppTheme(PlayConfig.defaults.appearance),
        home: const LuckTestPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Luck index'), findsWidgets);
    expect(find.text('Draw settings'), findsOneWidget);
    expect(find.text('20 draws'), findsWidgets);
    expect(find.text('Draw goal'), findsOneWidget);
    expect(find.text('Tier count'), findsOneWidget);
    expect(find.text('Rare draw effects'), findsOneWidget);
    expect(find.text('A1'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('20 draws').first,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('20 draws').first);
    await tester.pumpAndSettle();
    expect(find.text('A1'), findsNothing);
    expect(
      find.text('20 draws mode: press the button below to generate 20 cards.'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: buildAppTheme(PlayConfig.defaults.appearance),
        home: const SustainedAttentionTestPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Attention settings'), findsOneWidget);
    expect(find.text('Task mode'), findsOneWidget);
    expect(find.text('Oddball'), findsOneWidget);
    expect(find.text('n-back'), findsOneWidget);
    expect(find.text('Target ratio'), findsOneWidget);
    expect(find.text('Highlight target background'), findsOneWidget);
  });

  testWidgets('tap speed stroop and time perception expose enhanced modes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: buildAppTheme(PlayConfig.defaults.appearance),
        home: const TapSpeedTestPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tap settings'), findsOneWidget);
    expect(find.text('Classic'), findsOneWidget);
    expect(find.text('Target chase'), findsOneWidget);
    expect(find.text('Rhythm hit'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: buildAppTheme(PlayConfig.defaults.appearance),
        home: const StroopTestPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Submode'), findsOneWidget);
    expect(find.text('Ink color'), findsOneWidget);
    expect(find.text('Word meaning'), findsOneWidget);
    expect(find.text('Reverse rule'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: buildAppTheme(PlayConfig.defaults.appearance),
        home: const TimePerceptionTestPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Countdown'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Start'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(find.text('Countdown'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Running'), findsOneWidget);
  });
}

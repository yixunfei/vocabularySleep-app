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
    expect(find.text('Powers'), findsOneWidget);
    expect(find.text('Factorial'), findsNothing);
    expect(find.text('Arithmetic seq.'), findsOneWidget);
    expect(find.text('Geometric seq.'), findsOneWidget);
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
    expect(
      find.byKey(const ValueKey<String>('luck-module-draw')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('luck-module-scratch')),
      findsOneWidget,
    );
    expect(find.text('Draw cards'), findsOneWidget);
    expect(find.text('Scratch'), findsOneWidget);
    expect(find.text('20 draws'), findsWidgets);
    expect(find.text('Draw goal'), findsOneWidget);
    expect(find.text('Tier count'), findsOneWidget);
    expect(find.text('Flip card effects'), findsOneWidget);
    expect(find.text('A1'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey<String>('luck-module-scratch')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('New ticket'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('luck-scratch-grid')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Scratch the winning numbers and your numbers. Match any winning number to win that spot prize; stars auto-win and multipliers boost the prize. This is a local ticket simulation.',
      ),
      findsOneWidget,
    );
    expect(find.text('Winning numbers'), findsOneWidget);
    expect(find.text('Your numbers'), findsOneWidget);
    expect(find.text('Prize table'), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'Ticket \d{3}-\d{6}-\d{3}')),
      findsOneWidget,
    );
    expect(find.textContaining(RegExp(r'Pack \d{4}-\d{6}')), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'Validation [A-Z2-9]{10}')),
      findsOneWidget,
    );
    expect(find.text('Spent'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Scratch settings'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scratch settings'));
    await tester.pumpAndSettle();
    expect(find.text('Ticket price'), findsOneWidget);
    expect(find.text('Restore defaults'), findsOneWidget);
    final scratchGrid = find.byKey(const ValueKey<String>('luck-scratch-grid'));
    await tester.ensureVisible(scratchGrid);
    await tester.pumpAndSettle();
    final scratchGesture = await tester.startGesture(
      tester.getCenter(scratchGrid),
    );
    await scratchGesture.moveBy(const Offset(34, 4));
    await tester.pump(const Duration(milliseconds: 16));
    await scratchGesture.moveBy(const Offset(26, -3));
    await tester.pump(const Duration(milliseconds: 16));
    await scratchGesture.moveBy(const Offset(20, 8));
    await tester.pump(const Duration(milliseconds: 16));
    await scratchGesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('luck-module-draw')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('luck-module-draw')));
    await tester.pumpAndSettle();
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
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('luck-primary-draw-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('luck-primary-draw-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.text('Multi-draw cards'), findsOneWidget);

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
    expect(find.text('Restart'), findsOneWidget);

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

  testWidgets(
    'human tests hub exposes the new visual auditory and coordination modules',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          theme: buildAppTheme(PlayConfig.defaults.appearance),
          home: const HumanTestsToolPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Visual search'), findsWidgets);
      expect(find.text('Auditory reaction'), findsWidgets);
      expect(find.text('Dual-task switching'), findsWidgets);
      expect(find.text('Fine drag tracking'), findsWidgets);
      expect(find.text('Bimanual coordination'), findsWidgets);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          theme: buildAppTheme(PlayConfig.defaults.appearance),
          home: const VisualSearchTestPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Difference'), findsOneWidget);
      expect(find.text('Visual search settings'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          theme: buildAppTheme(PlayConfig.defaults.appearance),
          home: const AuditoryReactionTestPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Reaction'), findsWidgets);
      expect(find.text('Frequency'), findsWidgets);
      expect(find.text('Volume'), findsWidgets);
      expect(find.text('Channel'), findsWidgets);
      expect(find.text('Preview test tones'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          theme: buildAppTheme(PlayConfig.defaults.appearance),
          home: const DualTaskSwitchTestPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Every round'), findsOneWidget);
      expect(find.text('Odd'), findsOneWidget);
      expect(find.text('Even'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          theme: buildAppTheme(PlayConfig.defaults.appearance),
          home: const FineDragTrackingTestPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Track width'), findsOneWidget);
      expect(find.text('Difficulty'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          theme: buildAppTheme(PlayConfig.defaults.appearance),
          home: const BimanualCoordinationTestPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Alternating'), findsOneWidget);
      expect(find.text('Sync'), findsOneWidget);
      expect(find.text('Left'), findsWidgets);
      expect(find.text('Right'), findsWidgets);
    },
  );
}

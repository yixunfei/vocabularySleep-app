import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      expect(find.text('Auditory test'), findsWidgets);
      expect(find.text('Acoustic experiment'), findsWidgets);
      expect(find.text('Dual-task switching'), findsWidgets);
      expect(find.text('Fine drag tracking'), findsWidgets);
      expect(find.text('Bimanual coordination'), findsWidgets);
      expect(find.text('My tools'), findsOneWidget);
      expect(find.text('No quick tools yet'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('human_tests_quick_dock')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('human_tests_entry_reaction')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('human_tests_entry_aim')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('human_tests_grid_slot_reaction')),
        findsOneWidget,
      );
      final reactionRect = tester.getRect(
        find.byKey(const ValueKey<String>('human_tests_entry_reaction')),
      );
      final aimRect = tester.getRect(
        find.byKey(const ValueKey<String>('human_tests_entry_aim')),
      );
      expect((reactionRect.top - aimRect.top).abs(), lessThan(4));
      expect(aimRect.left, greaterThan(reactionRect.left));
      expect(reactionRect.height, closeTo(118, 0.5));

      final reorderGesture = await tester.startGesture(aimRect.center);
      await tester.pump(const Duration(milliseconds: 650));
      await reorderGesture.moveBy(const Offset(-120, 0));
      await tester.pump(const Duration(milliseconds: 120));
      await reorderGesture.moveBy(const Offset(-120, 0));
      await tester.pump(const Duration(milliseconds: 120));
      await reorderGesture.up();
      await tester.pumpAndSettle();
      final reorderedAimRect = tester.getRect(
        find.byKey(const ValueKey<String>('human_tests_entry_aim')),
      );
      final reorderedReactionRect = tester.getRect(
        find.byKey(const ValueKey<String>('human_tests_entry_reaction')),
      );
      expect(reorderedAimRect.left, lessThan(reorderedReactionRect.left));

      await tester.tap(
        find.byKey(const ValueKey<String>('human_tests_add_quick_button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Add quick tool'), findsWidgets);
      await tester.tap(
        find.widgetWithText(ListTile, 'Reaction test').last,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('human_tests_quick_reaction')),
        findsOneWidget,
      );
      expect(find.text('No quick tools yet'), findsNothing);

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
      expect(find.text('Link match'), findsOneWidget);
      expect(find.text('Visual search settings'), findsOneWidget);

      await tester.tap(find.text('Link match'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Pairs'), findsOneWidget);
      expect(find.text('Moves'), findsOneWidget);
      expect(find.text('Link board size'), findsOneWidget);
      expect(find.text('Icon-only match'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('visual-link-ignore-path-switch')),
        findsOneWidget,
      );
      await tester.tap(find.text('Icon-only match'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.textContaining('Ignore route blocking'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('visual-link-match-grid')),
        findsOneWidget,
      );
      expect(find.textContaining('two-turn route'), findsWidgets);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          theme: buildAppTheme(PlayConfig.defaults.appearance),
          home: const AuditoryReactionTestPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Auditory test'), findsWidgets);
      expect(find.text('Volume calibration'), findsOneWidget);
      expect(find.text('Mic acoustic lab'), findsNothing);
      expect(find.text('Frequency'), findsWidgets);
      expect(find.text('Sensitivity'), findsWidgets);
      expect(find.text('Spatial'), findsWidgets);
      expect(find.text('Auditory settings'), findsOneWidget);
      expect(find.text('Rounds'), findsOneWidget);
      expect(find.text('10 rounds'), findsOneWidget);
      expect(find.text('Analysis bands'), findsOneWidget);
      expect(find.text('Allow replay'), findsOneWidget);
      await tester.tap(find.text('Sensitivity'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Threshold hint'), findsNothing);
      await tester.tap(find.text('Spatial'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Direction count'), findsOneWidget);
      expect(find.text('Slider smoothing'), findsOneWidget);
      expect(find.text('8-way pad'), findsOneWidget);
      expect(find.text('Pointer'), findsOneWidget);
      expect(find.text('Confirm position'), findsOneWidget);
      expect(find.text('Preview current mode'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Start'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final auditoryStatusSlot = find.byKey(
        const ValueKey<String>('auditory-status-slot'),
      );
      expect(auditoryStatusSlot, findsOneWidget);
      expect(tester.getSize(auditoryStatusSlot).height, 64);
      await tester.tap(find.text('Start'), warnIfMissed: false);
      await tester.pump();
      expect(tester.getSize(auditoryStatusSlot).height, 64);
      expect(
        find.byKey(const ValueKey<String>('auditory-wait-marker')),
        findsOneWidget,
      );
      final frontDirectionButton = find.byKey(
        const ValueKey<String>('auditory-spatial-direction-0'),
      );
      final frontDirectionMaterial = tester.widget<Material>(
        find
            .descendant(
              of: frontDirectionButton,
              matching: find.byType(Material),
            )
            .first,
      );
      expect(
        frontDirectionMaterial.color,
        Theme.of(tester.element(frontDirectionButton)).colorScheme.surface,
      );
      expect(find.textContaining('Playing'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          theme: buildAppTheme(PlayConfig.defaults.appearance),
          home: const AcousticExperimentTestPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Acoustic experiment'), findsWidgets);
      expect(find.text('Mic acoustic lab'), findsOneWidget);
      expect(find.text('Noise meter'), findsOneWidget);
      expect(find.text('Smoothness'), findsOneWidget);
      expect(find.text('Ambient'), findsOneWidget);

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

      _mockSystemChromeForFullscreenTest();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          theme: buildAppTheme(PlayConfig.defaults.appearance),
          home: const BimanualCoordinationTestPage(),
        ),
      );
      await tester.pumpAndSettle();

      final fullscreenView = find.byKey(
        const ValueKey<String>('brain_split_fullscreen_view'),
      );
      if (fullscreenView.evaluate().isEmpty) {
        expect(find.text('Bimanual coordination'), findsWidgets);
        expect(find.text('Fullscreen start'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Fullscreen start'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Fullscreen start'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 650));
      }

      expect(fullscreenView, findsOneWidget);
      expect(find.text('No active pair yet.'), findsNothing);
      expect(find.text('Idle'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('brain_split_fullscreen_status_peek')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('brain_split_fullscreen_start_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('brain_split_fullscreen_reset_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('brain_split_fullscreen_settings_button'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('brain_split_fullscreen_menu_button'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('brain_split_left_slot')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('brain_split_right_slot')),
        findsOneWidget,
      );
      final leftSlotRect = tester.getRect(
        find.byKey(const ValueKey<String>('brain_split_left_slot')),
      );
      final rightSlotRect = tester.getRect(
        find.byKey(const ValueKey<String>('brain_split_right_slot')),
      );
      expect((leftSlotRect.top - rightSlotRect.top).abs(), lessThan(4));
      expect(rightSlotRect.left, greaterThan(leftSlotRect.left));

      await tester.tap(
        find.byKey(
          const ValueKey<String>('brain_split_fullscreen_settings_button'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey<String>('brain_split_fullscreen_settings_dialog'),
        ),
        findsOneWidget,
      );
      expect(find.text('Bimanual settings'), findsOneWidget);
      expect(find.text('Split-brain settings'), findsOneWidget);
      expect(find.text('Rounds'), findsOneWidget);
      expect(find.text('Time limit'), findsWidgets);
      expect(find.text('Unlimited'), findsWidgets);
      expect(find.text('Pace level'), findsOneWidget);
      expect(find.text('Sync window'), findsOneWidget);
      expect(find.text('Charge window'), findsOneWidget);
      expect(find.text('Arcade mix'), findsWidgets);
      expect(find.text('Split-brain storm'), findsOneWidget);
      expect(find.text('Rhythm conductor'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>('brain_split_fullscreen_menu_button'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(_popupMenuItem('Settings'), findsOneWidget);
      expect(_popupMenuItem('Reset'), findsOneWidget);
      expect(_popupMenuItem('Stop challenge'), findsOneWidget);
      expect(_popupMenuItem('Exit fullscreen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

void _mockSystemChromeForFullscreenTest() {
  final binding = TestDefaultBinaryMessengerBinding.instance;
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (_) async => null,
  );
  addTearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });
}

Finder _popupMenuItem(String text) {
  return find.byWidgetPredicate((widget) {
    if (widget is! PopupMenuItem<dynamic>) {
      return false;
    }
    final child = widget.child;
    return child is Text && child.data == text;
  });
}

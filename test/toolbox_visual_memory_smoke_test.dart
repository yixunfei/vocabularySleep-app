import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_human_tests.dart';
import 'package:vocabulary_sleep_app/src/ui/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('visual memory exposes stepped modes and starts a round', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(PlayConfig.defaults.appearance),
        home: const VisualMemoryTestPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Visual memory'), findsWidgets);
    expect(find.text('Grid'), findsOneWidget);
    expect(find.text('Visual memory settings'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Visual memory settings'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Visual memory settings'));
    await tester.pumpAndSettle();

    expect(find.text('Difficulty ladder'), findsOneWidget);
    expect(find.text('Positions'), findsWidgets);
    expect(find.text('Color targets'), findsOneWidget);
    expect(find.text('Target color'), findsOneWidget);
    expect(find.text('Distractor cells'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Color targets'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Color targets'));
    await tester.pumpAndSettle();

    expect(find.text('Active colors'), findsOneWidget);

    final startButton = find.widgetWithText(FilledButton, 'Start');
    await tester.scrollUntilVisible(
      startButton,
      -320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(startButton);
    await tester.pump();

    expect(find.textContaining('Tap the'), findsNothing);
    expect(find.textContaining('Memorize'), findsWidgets);
    expect(find.textContaining('Target color:'), findsOneWidget);
    expect(find.textContaining('similar colors'), findsWidgets);
  });

  testWidgets('visual memory shows report when lives run out', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(PlayConfig.defaults.appearance),
        home: const VisualMemoryTestPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Visual memory settings'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Visual memory settings'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Custom'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();

    final sliders = find.byType(Slider);
    await tester.ensureVisible(sliders.at(3));
    await tester.pumpAndSettle();
    await tester.drag(sliders.at(3), const Offset(-320, 0));
    await tester.pumpAndSettle();
    await tester.ensureVisible(sliders.at(4));
    await tester.pumpAndSettle();
    await tester.drag(sliders.at(4), const Offset(-320, 0));
    await tester.pumpAndSettle();

    final startButton = find.widgetWithText(FilledButton, 'Start');
    await tester.scrollUntilVisible(
      startButton,
      -420,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(startButton);
    await tester.pump(const Duration(milliseconds: 2600));

    await tester.ensureVisible(find.byType(AspectRatio).first);
    await tester.pumpAndSettle();

    final gridCells = find.descendant(
      of: find.byType(AspectRatio),
      matching: find.byType(InkWell),
    );
    for (var attempt = 0; attempt < 36; attempt++) {
      await tester.tap(gridCells.at(attempt % 16));
      await tester.pump(const Duration(milliseconds: 120));
      if (find.text('Visual memory report').evaluate().isNotEmpty) {
        break;
      }
      if ((attempt + 1) % 16 == 0) {
        await tester.pump(const Duration(milliseconds: 2600));
      }
    }
    await tester.pumpAndSettle();

    expect(find.text('Visual memory report'), findsOneWidget);
    expect(find.text('Miss sources'), findsOneWidget);
  });
}

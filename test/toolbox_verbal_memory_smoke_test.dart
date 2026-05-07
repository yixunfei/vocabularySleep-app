import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_human_tests.dart';
import 'package:vocabulary_sleep_app/src/ui/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('verbal memory exposes multi-mode settings and report', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: buildAppTheme(PlayConfig.defaults.appearance),
        home: const VerbalMemoryTestPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verbal memory'), findsWidgets);
    expect(find.text('Training settings'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Training settings'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Training settings'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.textContaining('Domain word bank'), findsOneWidget);
    expect(find.textContaining('Base repeat rate'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Digits'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(ChoiceChip, 'Digits'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Base digits'), findsOneWidget);
    expect(find.textContaining('View time'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Arrows'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(ChoiceChip, 'Arrows'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.text('Direction set'), findsOneWidget);
    expect(find.text('4 directions'), findsOneWidget);
    expect(find.text('8 directions'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Words'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(ChoiceChip, 'Words'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    final startButton = find.widgetWithText(FilledButton, 'Start');
    await tester.ensureVisible(startButton);
    await tester.pumpAndSettle();
    await tester.tap(startButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    final newButton = find.widgetWithText(FilledButton, 'New');
    expect(newButton, findsOneWidget);
    await tester.ensureVisible(newButton);
    await tester.pumpAndSettle();
    await tester.tap(newButton, warnIfMissed: false);
    await tester.pump();

    final reportButton = find.widgetWithText(OutlinedButton, 'Report');
    await tester.ensureVisible(reportButton);
    await tester.pumpAndSettle();
    expect(tester.widget<OutlinedButton>(reportButton).onPressed, isNotNull);
    await tester.tap(reportButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Memory run report'), findsOneWidget);
    expect(find.text('Analysis'), findsOneWidget);
    expect(find.text('Run settings'), findsOneWidget);
    expect(find.text('Recent rounds'), findsOneWidget);
  });
}

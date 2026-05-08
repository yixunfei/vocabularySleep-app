import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_human_tests.dart';
import 'package:vocabulary_sleep_app/src/ui/theme/app_theme.dart';
import 'package:vocabulary_sleep_app/src/models/play_config.dart';

void main() {
  testWidgets('typing test exposes professional modes and report', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1300));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: buildAppTheme(PlayConfig.defaults.appearance),
        home: const TypingTestPage(),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> tapVisibleChip(String key) async {
      final finder = find.byKey(ValueKey<String>(key));
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder, warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    expect(find.text('Typing test'), findsWidgets);
    expect(find.text('Typing settings'), findsOneWidget);
    expect(find.textContaining('鎵'), findsNothing);
    expect(find.text('Classic'), findsWidgets);
    expect(find.text('Sprint'), findsWidgets);
    expect(find.text('Precision'), findsWidgets);
    expect(find.text('Blind'), findsWidgets);
    expect(find.text('Symbols'), findsWidgets);
    expect(find.text('Fix errors'), findsWidgets);
    expect(find.text('Code'), findsWidgets);
    expect(find.text('Numbers'), findsWidgets);
    expect(find.text('Short'), findsWidgets);
    expect(find.text('Standard'), findsWidgets);
    expect(find.text('Long'), findsWidgets);
    expect(find.text('All'), findsWidgets);
    expect(find.text('Final speed'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Typing settings'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Typing settings'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Modes'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Chinese'), findsWidgets);
    expect(find.text('English'), findsWidgets);
    expect(find.text('Mixed'), findsWidgets);
    expect(find.text('Japanese'), findsWidgets);
    expect(find.text('Spanish'), findsWidgets);
    expect(find.text('Content topic'), findsOneWidget);
    expect(find.text('Length'), findsOneWidget);
    expect(find.text('All'), findsWidgets);

    await tapVisibleChip('typing-mode-symbols');
    expect(find.textContaining('#42', findRichText: true), findsOneWidget);

    await tapVisibleChip('typing-language-ja');
    expect(find.text('Japanese'), findsWidgets);

    await tapVisibleChip('typing-mode-code');
    expect(
      find.text(
        'Code drill: preserve case, brackets, quotes, and line breaks.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('final', findRichText: true), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('typing-test-input')),
      'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    );
    await tester.pumpAndSettle();

    expect(find.text('Result report'), findsOneWidget);
    expect(find.text('Final speed'), findsOneWidget);
    expect(find.text('Net speed'), findsOneWidget);
    expect(find.text('Error profile'), findsOneWidget);
    expect(find.text('Error hotspots'), findsOneWidget);
    expect(find.text('Practice suggestion'), findsOneWidget);
    expect(find.text('Recent local results'), findsOneWidget);
  });
}

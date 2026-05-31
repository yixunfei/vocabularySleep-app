import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_mini_games.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'randomizer page paints the lightweight stage without framework errors',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: RouletteGamePage()));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Choice spinner'), findsWidgets);
      expect(find.text('Spin choice'), findsOneWidget);
    },
  );

  testWidgets('randomizer page renders repaired Chinese labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh'),
        supportedLocales: <Locale>[Locale('zh'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: RouletteGamePage(),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('随机选择器'), findsWidgets);
    expect(find.text('旋转选择'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
    expect(find.textContaining('??'), findsNothing);
  });
}

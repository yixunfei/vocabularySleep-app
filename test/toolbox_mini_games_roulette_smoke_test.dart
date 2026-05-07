import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_mini_games.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'roulette page paints the immersive stage without framework errors',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: RouletteGamePage()));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Roulette trigger'), findsWidgets);
      expect(find.text('Spin cylinder'), findsOneWidget);
    },
  );

  testWidgets('roulette page renders repaired Chinese labels', (tester) async {
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
    expect(find.text('俄罗斯轮盘赌'), findsWidgets);
    expect(find.text('旋转弹仓'), findsOneWidget);
    expect(find.text('扣动扳机'), findsOneWidget);
    expect(find.text('舞台控制'), findsOneWidget);
    expect(find.textContaining('??'), findsNothing);
  });
}

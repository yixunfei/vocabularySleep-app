import 'package:flutter/material.dart';
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
}

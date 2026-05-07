import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_human_tests.dart';
import 'package:vocabulary_sleep_app/src/ui/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('color vision exposes mixed mode settings and report', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: buildAppTheme(PlayConfig.defaults.appearance),
        home: const ColorVisionTestPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Color vision'), findsWidgets);
    expect(find.text('Color vision settings'), findsOneWidget);
    expect(find.text('Odd tile'), findsWidgets);
    expect(find.text('Mixed match'), findsOneWidget);
    expect(find.text('Avoid red-green'), findsOneWidget);
    expect(find.text('Maximum lives'), findsOneWidget);
    expect(find.text('Initial grid'), findsOneWidget);
    expect(find.text('Maximum grid'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Mixed match'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mixed match'), warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Target color'),
      -360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Target color'), findsOneWidget);
    expect(find.text('Matching targets'), findsOneWidget);
    expect(find.text('Random target count'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Hint'),
      -320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hint'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.my_location_rounded), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('End and analyze'),
      -220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('End and analyze'));
    await tester.pumpAndSettle();

    expect(find.text('Color vision report'), findsOneWidget);
    expect(find.text('Overall analysis'), findsOneWidget);
    expect(find.text('Training note'), findsOneWidget);
  });
}

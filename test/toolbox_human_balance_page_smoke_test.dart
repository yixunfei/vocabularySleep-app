import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_human_tests.dart';
import 'package:vocabulary_sleep_app/src/ui/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('balance test renders on narrow screens with manual fallback', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 667));
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    _mockSystemChromeForFullscreenTest();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
    });

    try {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          theme: buildAppTheme(PlayConfig.defaults.appearance),
          home: const BalanceTestPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Balance test'), findsOneWidget);
      expect(find.text('Manual tilt'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Start'), findsOneWidget);

      await tester.tap(find.text('Start'));
      await tester.pump(const Duration(milliseconds: 40));

      expect(find.textContaining('Running'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
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

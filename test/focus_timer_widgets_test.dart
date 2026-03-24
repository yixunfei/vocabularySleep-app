import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/i18n/app_i18n.dart';
import 'package:vocabulary_sleep_app/src/models/tomato_timer.dart';
import 'package:vocabulary_sleep_app/src/ui/layout/app_width_tier.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/focus_timer_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hourglass timer display fits inside the regular card height', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: FocusTimerDisplayCard(
                timerState: const TomatoTimerState(
                  phase: TomatoTimerPhase.focusReady,
                  currentRound: 0,
                  remainingSeconds: 0,
                  totalSeconds: 0,
                ),
                config: const TomatoTimerConfig(),
                i18n: AppI18n('en'),
                widthTier: AppWidthTier.regular,
                timerStyle: 'hourglass',
                lastCompletedPhase: null,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('00:00'), findsOneWidget);
    expect(find.byType(FocusTimerDisplayCard), findsOneWidget);
  });
}

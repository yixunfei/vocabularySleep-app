import 'package:flutter/material.dart';

import '../../models/sleep_daily_log.dart';
import '../../models/sleep_support_session.dart';
import 'sleep_support/sleep_support_guide_page.dart';

class SleepNightRescuePage extends StatelessWidget {
  const SleepNightRescuePage({super.key, this.initialMode});

  final SleepNightRescueMode? initialMode;

  @override
  Widget build(BuildContext context) => SleepSupportGuidePage(
    intent:
        initialMode == SleepNightRescueMode.racingThoughts ||
            initialMode == SleepNightRescueMode.bodyActivated ||
            initialMode == SleepNightRescueMode.temperatureDiscomfort
        ? SleepSupportIntent.distressed
        : SleepSupportIntent.nightWaking,
    initialMode: initialMode,
  );
}

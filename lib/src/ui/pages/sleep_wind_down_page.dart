import 'package:flutter/material.dart';

import '../../models/sleep_support_session.dart';
import 'sleep_support/sleep_support_guide_page.dart';

class SleepWindDownPage extends StatelessWidget {
  const SleepWindDownPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const SleepSupportGuidePage(intent: SleepSupportIntent.prepareForSleep);
}

import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../ui_copy.dart';
import 'toolbox_daily_choice/daily_choice_hub.dart';
import 'toolbox_tool_shell.dart';

class DailyDecisionToolPage extends StatelessWidget {
  const DailyDecisionToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: i18n.t('toolbox.daily_choice.page_title'),
      subtitle: i18n.t('toolbox.daily_choice.page_subtitle'),
      child: const DailyChoiceHub(),
    );
  }
}

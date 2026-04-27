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
      title: pickUiText(i18n, zh: '每日抉择', en: 'Daily decision'),
      subtitle: pickUiText(
        i18n,
        zh: '从吃什么、穿什么、去哪儿到行动选择和轻量决策计算，把日常纠结拆成可随机、可编辑、可复盘的小选择。',
        en: 'Break everyday indecision into randomizable, editable, reviewable choices across food, outfits, places, actions, and decision math.',
      ),
      child: const DailyChoiceHub(),
    );
  }
}

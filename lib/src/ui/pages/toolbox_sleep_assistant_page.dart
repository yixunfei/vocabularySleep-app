import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../state/app_state.dart';
import '../module/module_access.dart';
import 'sleep_assistant_ui_support.dart';
import 'sleep_support/sleep_day_hub_page.dart';
import 'sleep_support/sleep_night_home.dart';
import 'sleep_support/sleep_night_sound_panel.dart';
import 'sleep_support/sleep_support_guide_page.dart';
import 'toolbox_tool_shell.dart';

class ToolboxSleepAssistantPage extends StatelessWidget {
  const ToolboxSleepAssistantPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.select<AppState, String>((s) => s.uiLanguage);
    final enabled = context.select<AppState, bool>(
      (s) => s.isModuleEnabled(ModuleIds.toolboxSleepAssistant),
    );
    final i18n = AppI18n(language);
    return sleepModuleTheme(
      context: context,
      enabled: true,
      child: Builder(
        builder: (context) => ToolboxToolPage(
          title: i18n.t('toolbox.sleep.core.title'),
          subtitle: '',
          showPageHeader: false,
          child: enabled
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SleepNightHome(
                      i18n: i18n,
                      onIntent: (intent) =>
                          _open(context, SleepSupportGuidePage(intent: intent)),
                      onDaytime: () => _open(context, const SleepDayHubPage()),
                    ),
                    const SleepNightSoundPanel(),
                  ],
                )
              : ModuleDisabledView(
                  i18n: i18n,
                  moduleId: ModuleIds.toolboxSleepAssistant,
                ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

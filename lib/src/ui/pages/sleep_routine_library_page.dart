import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../state/app_state.dart';
import '../module/module_access.dart';
import 'sleep_assistant_ui_support.dart';
import 'sleep_support/sleep_routine_library_panel.dart';
import 'sleep_support/sleep_routine_tools_panel.dart';
import 'sleep_support/sleep_thought_library_panel.dart';
import 'toolbox_tool_shell.dart';

/// Daytime management stays separate from the immediate nighttime guide.
class SleepRoutineLibraryPage extends StatelessWidget {
  const SleepRoutineLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.select<AppState, String>((s) => s.uiLanguage);
    final enabled = context.select<AppState, bool>(
      (s) => s.isModuleEnabled(ModuleIds.toolboxSleepAssistant),
    );
    final dark = context.select<AppState, bool>(
      (s) => s.sleepDashboardState.sleepDarkModeEnabled,
    );
    final i18n = AppI18n(language);
    return sleepModuleTheme(
      context: context,
      enabled: dark,
      child: Builder(
        builder: (context) => ToolboxToolPage(
          title: i18n.t('toolbox.sleep.night.library_title'),
          subtitle: i18n.t('toolbox.sleep.night.library_body'),
          child: enabled
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _section(
                      title: i18n.t('toolbox.sleep.winddown.templates'),
                      icon: Icons.playlist_add_check_rounded,
                      child: SleepRoutineLibraryPanel(i18n: i18n),
                      initiallyExpanded: true,
                    ),
                    const SizedBox(height: 12),
                    _section(
                      title: i18n.t('toolbox.sleep.winddown.unloadThoughts'),
                      icon: Icons.edit_note_rounded,
                      child: SleepThoughtLibraryPanel(i18n: i18n),
                    ),
                    const SizedBox(height: 12),
                    _section(
                      title: i18n.t('toolbox.sleep.winddown.quickTools'),
                      icon: Icons.tune_rounded,
                      child: SleepRoutineToolsPanel(i18n: i18n),
                    ),
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

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
    bool initiallyExpanded = false,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icon),
        title: Text(title),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [child],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/app_i18n.dart';
import '../../state/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../ui_copy.dart';
import '../wordbook_localization.dart';
import '../widgets/page_header.dart';
import '../widgets/setting_tile.dart';
import 'data_management_page.dart';
import 'help_center_page.dart';
import 'settings_home_page.dart';
import 'wordbook_management_page.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    final mode = experienceModeFromAppearance(state.config.appearance);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: <Widget>[
        PageHeader(
          eyebrow: pageLabelMore(i18n),
          title: i18n.t(
            'inline.ui.pages.more_page.low_frequency_high_value_tools_8680ee',
          ),
          subtitle: i18n.t(
            'inline.ui.pages.more_page.keep_management_tools_here_so_the_primary_flow_stays_foc_f3adde',
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  i18n.t(
                    'inline.ui.pages.data_management_page.current_status_ed1d4c',
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  i18n.t(
                    'inline.ui.pages.more_page.mode_experiencemodetitle_i18n_mode_a24484',
                    params: <String, Object?>{
                      'mode': experienceModeTitle(i18n, mode),
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  i18n.t(
                    'inline.ui.pages.more_page.current_wordbook_localizedwordbookname_i18n_state_select_3d822a',
                    params: <String, Object?>{
                      'wordbook': localizedWordbookName(
                        i18n,
                        state.selectedWordbook,
                      ),
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  i18n.t(
                    'inline.ui.pages.more_page.visible_words_state_visiblewords_length_9686c9',
                    params: <String, Object?>{
                      'count': state.visibleWords.length,
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  i18n.t(
                    'inline.ui.pages.more_page.today_startup_prompt_b4b78b',
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  i18n.t(
                    'inline.ui.pages.more_page.show_today_s_todos_daily_quote_and_weather_after_launch_c81d04',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: state.startupTodoPromptEnabled,
                  title: Text(
                    i18n.t(
                      'inline.ui.pages.more_page.enable_startup_prompt_ea03c4',
                    ),
                  ),
                  subtitle: Text(
                    state.startupTodoPromptEnabled
                        ? i18n.t(
                            'inline.ui.pages.more_page.enabled_the_summary_appears_after_entering_the_main_scre_c61cef',
                          )
                        : i18n.t(
                            'inline.ui.pages.more_page.disabled_the_summary_stays_hidden_on_startup_e1d925',
                          ),
                  ),
                  onChanged: state.setStartupTodoPromptEnabled,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SettingTile(
          icon: Icons.tune_rounded,
          title: i18n.t('inline.ui.pages.more_page.settings_center_5780d6'),
          subtitle: i18n.t(
            'inline.ui.pages.more_page.language_playback_speech_startup_prompt_and_practical_ap_62b5ad',
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsHomePage()),
            );
          },
        ),
        const SizedBox(height: 12),
        SettingTile(
          icon: Icons.collections_bookmark_outlined,
          title: i18n.t(
            'inline.ui.pages.help_center_page.wordbook_management_7c76ef',
          ),
          subtitle: i18n.t(
            'inline.ui.pages.help_center_page.create_import_edit_rename_and_merge_wordbooks_02acd1',
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const WordbookManagementPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        SettingTile(
          icon: Icons.storage_rounded,
          title: i18n.t(
            'inline.ui.pages.data_management_page.data_management_87880c',
          ),
          subtitle: i18n.t(
            'inline.ui.pages.more_page.import_export_migration_and_task_word_maintenance_bb6500',
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DataManagementPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        SettingTile(
          icon: Icons.help_outline_rounded,
          title: i18n.t('inline.ui.pages.help_center_page.about_help_adbe73'),
          subtitle: i18n.t(
            'inline.ui.pages.more_page.version_info_faq_and_quick_guidance_71b833',
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HelpCenterPage()),
            );
          },
        ),
      ],
    );
  }
}

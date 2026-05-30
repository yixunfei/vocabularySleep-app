import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/app_i18n.dart';
import '../../state/app_state_provider.dart';
import '../../utils/asr_language.dart';
import '../theme/app_theme.dart';
import '../ui_copy.dart';
import '../widgets/page_header.dart';
import '../widgets/setting_tile.dart';
import 'appearance_studio_page.dart';
import 'language_settings_page.dart';
import 'module_management_page.dart';
import 'playback_advanced_page.dart';
import 'recognition_settings_page.dart';
import 'voice_input_settings_page.dart';
import 'voice_settings_page.dart';

class SettingsHomePage extends ConsumerWidget {
  const SettingsHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    final config = state.config;
    final appearance = config.appearance;
    final mode = experienceModeFromAppearance(appearance);
    final voiceInputLabel = voiceInputProviderLabel(
      i18n,
      config.voiceInput.provider,
    );
    final voiceInputLanguageLabel = asrLanguageLabel(
      i18n,
      config.voiceInput.language,
    );
    final asrStatus = config.asr.enabled
        ? i18n.t('toolbox.sleep.tools.enabled')
        : i18n.t('toolbox.sleep.tools.disabled');
    final asrProvider = asrProviderLabel(i18n, config.asr.provider);
    final textVisibilityLabel = config.showText
        ? i18n.t('showText')
        : i18n.t('inline.ui.pages.word_detail_page.text_is_hidden_262961');

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.t('inline.ui.pages.more_page.settings_center_5780d6')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          PageHeader(
            eyebrow: i18n.t('settings'),
            title: i18n.t(
              'inline.ui.pages.settings_home_page.unified_settings_ddaa4e',
            ),
            subtitle: i18n.t(
              'inline.ui.pages.settings_home_page.manage_playback_voice_recognition_and_appearance_in_dedi_c71fb1',
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
                      'inline.ui.pages.settings_home_page.startup_prompt_5be8f6',
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    i18n.t(
                      'inline.ui.pages.settings_home_page.show_today_s_todos_daily_quote_and_weather_after_enterin_8a8513',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: state.startupTodoPromptEnabled,
                    title: Text(
                      i18n.t(
                        'inline.ui.pages.settings_home_page.enable_today_prompt_025f9b',
                      ),
                    ),
                    subtitle: Text(
                      state.startupTodoPromptEnabled
                          ? i18n.t(
                              'inline.ui.pages.settings_home_page.enabled_you_can_still_mute_it_for_the_rest_of_the_day_fr_0ab148',
                            )
                          : i18n.t(
                              'inline.ui.pages.settings_home_page.when_off_the_startup_summary_will_not_appear_automatical_093d7e',
                            ),
                    ),
                    onChanged: state.setStartupTodoPromptEnabled,
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
                      'inline.ui.pages.settings_home_page.navigation_behavior_19ebce',
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    i18n.t(
                      'inline.ui.pages.settings_home_page.control_how_the_global_bottom_navigation_behaves_while_p_821f9f',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: state.bottomNavigationAutoHideEnabled,
                    title: Text(
                      i18n.t(
                        'inline.ui.pages.settings_home_page.auto_hide_bottom_navigation_on_scroll_9c1fa6',
                      ),
                    ),
                    subtitle: Text(
                      state.bottomNavigationAutoHideEnabled
                          ? i18n.t(
                              'inline.ui.pages.settings_home_page.enabled_the_bottom_navigation_hides_on_downward_scroll_a_eba1be',
                            )
                          : i18n.t(
                              'inline.ui.pages.settings_home_page.disabled_the_bottom_navigation_stays_visible_so_the_main_d209a6',
                            ),
                    ),
                    onChanged: state.setBottomNavigationAutoHideEnabled,
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
                      'inline.ui.pages.settings_home_page.permissions_system_actions_4b5e3e',
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    i18n.t(
                      'inline.ui.pages.settings_home_page.manage_features_that_create_system_notifications_backgro_76c0c2',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: state.todoSystemRemindersEnabled,
                    title: Text(
                      i18n.t(
                        'inline.ui.pages.settings_home_page.allow_system_todo_reminders_5c6a86',
                      ),
                    ),
                    subtitle: Text(
                      state.todoSystemRemindersEnabled
                          ? i18n.t(
                              'inline.ui.pages.settings_home_page.enabled_focus_and_relaxation_todos_may_register_backgrou_d5e14d',
                            )
                          : i18n.t(
                              'inline.ui.pages.settings_home_page.disabled_todo_times_stay_inside_the_app_and_no_backgroun_5a301d',
                            ),
                    ),
                    onChanged: state.setTodoSystemRemindersEnabled,
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: state.toolboxAutoAdjustSystemVolumeEnabled,
                    title: Text(
                      i18n.t(
                        'inline.ui.pages.settings_home_page.allow_acoustic_auto_volume_adjustment_8f973f',
                      ),
                    ),
                    subtitle: Text(
                      state.toolboxAutoAdjustSystemVolumeEnabled
                          ? i18n.t(
                              'inline.ui.pages.settings_home_page.enabled_acoustic_tests_check_volume_and_may_set_media_vo_755429',
                            )
                          : i18n.t(
                              'inline.ui.pages.settings_home_page.disabled_acoustic_tests_will_not_change_system_media_vol_a9c96f',
                            ),
                    ),
                    onChanged: state.setToolboxAutoAdjustSystemVolumeEnabled,
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
                      'inline.ui.pages.settings_home_page.current_summary_14c0f8',
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    i18n.t(
                      'inline.plan296.ui.pages.settings.home.page.playback.4c5292ccff',
                      params: <String, Object?>{
                        'p0': playOrderLabel(i18n, config.order),
                        'p1': textVisibilityLabel,
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    i18n.t(
                      'inline.ui.pages.settings_home_page.voice_ttsproviderlabel_i18n_config_tts_provider_be7301',
                      params: <String, Object?>{
                        'configTtsProvider': ttsProviderLabel(
                          i18n,
                          config.tts.provider,
                        ),
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    i18n.t(
                      'inline.ui.pages.settings_home_page.voice_input_voiceinputlabel_asrlanguagelabel_i18n_config_82e5e9',
                      params: <String, Object?>{
                        'voiceInputLabel': voiceInputLabel,
                        'configVoiceInputLanguage': voiceInputLanguageLabel,
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    i18n.t(
                      'inline.ui.pages.settings_home_page.recognition_asrstatus_asrproviderlabel_i18n_config_asr_p_30aa7c',
                      params: <String, Object?>{
                        'asrStatus': asrStatus,
                        'configAsrProvider': asrProvider,
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
                      'inline.ui.pages.appearance_studio_page.experience_mode_933582',
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    i18n.t(
                      'inline.ui.pages.settings_home_page.sleep_keeps_visuals_calm_focus_favors_information_densit_da93f9',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<AppExperienceMode>(
                    segments: AppExperienceMode.values
                        .map(
                          (item) => ButtonSegment<AppExperienceMode>(
                            value: item,
                            label: Text(experienceModeTitle(i18n, item)),
                          ),
                        )
                        .toList(growable: false),
                    selected: <AppExperienceMode>{mode},
                    onSelectionChanged: (selection) {
                      final nextAppearance = applyExperienceMode(
                        appearance,
                        selection.first,
                      );
                      state.updateConfig(
                        config.copyWith(appearance: nextAppearance),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SettingTile(
            icon: Icons.play_circle_outline_rounded,
            title: i18n.t(
              'inline.ui.pages.playback_advanced_page.playback_advanced_9d4699',
            ),
            subtitle: i18n.t(
              'inline.ui.pages.settings_home_page.order_text_visibility_and_pacing_settings_34f466',
            ),
            trailing: Text(
              playOrderLabel(i18n, config.order),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            onTap: () => _open(context, const PlaybackAdvancedPage()),
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.record_voice_over_rounded,
            title: i18n.t(
              'inline.ui.pages.help_center_page.voice_settings_9938df',
            ),
            subtitle: i18n.t(
              'inline.ui.pages.settings_home_page.tts_provider_speed_and_volume_5c1731',
            ),
            trailing: Text(
              ttsProviderLabel(i18n, config.tts.provider),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            onTap: () => _open(context, const VoiceSettingsPage()),
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.mic_rounded,
            title: i18n.t(
              'inline.ui.pages.help_center_page.voice_input_settings_2bf6ed',
            ),
            subtitle: i18n.t(
              'inline.ui.pages.settings_home_page.provider_language_and_offline_package_for_quick_note_voi_597a4b',
            ),
            trailing: Text(
              voiceInputLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            onTap: () => _open(context, const VoiceInputSettingsPage()),
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.hearing_rounded,
            title: i18n.t('settingsTabAsr'),
            subtitle: i18n.t(
              'inline.ui.pages.settings_home_page.asr_switch_engine_and_practice_recognition_options_7d89ec',
            ),
            trailing: Text(
              '$asrStatus · $asrProvider',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            onTap: () => _open(context, const RecognitionSettingsPage()),
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.palette_outlined,
            title: i18n.t(
              'inline.ui.pages.appearance_studio_page.appearance_studio_9d4889',
            ),
            subtitle: i18n.t(
              'inline.ui.pages.settings_home_page.layout_density_background_and_panel_style_6bb1f0',
            ),
            onTap: () => _open(context, const AppearanceStudioPage()),
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.extension_rounded,
            title: i18n.t(
              'inline.ui.pages.module_management_page.module_management_e20d5f',
            ),
            subtitle: i18n.t(
              'inline.ui.pages.settings_home_page.enable_or_disable_feature_entry_points_by_module_541e83',
            ),
            onTap: () => _open(context, const ModuleManagementPage()),
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.language_rounded,
            title: i18n.t('language'),
            subtitle: i18n.t(
              'inline.ui.pages.settings_home_page.interface_language_and_display_preferences_62fdbd',
            ),
            trailing: Text(
              state.uiLanguageFollowsSystem
                  ? i18n.t(
                      'inline.ui.pages.language_settings_page.follow_system_ef2221',
                    )
                  : i18n.languageName(state.uiLanguage),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            onTap: () => _open(context, const LanguageSettingsPage()),
          ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, Widget page) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/app_i18n.dart';
import '../../state/app_state_provider.dart';
import '../ui_copy.dart';
import '../widgets/page_header.dart';
import '../widgets/setting_tile.dart';
import 'data_management_page.dart';
import 'recognition_settings_page.dart';
import 'settings_home_page.dart';
import 'voice_input_settings_page.dart';
import 'voice_settings_page.dart';
import 'wordbook_management_page.dart';

class HelpCenterPage extends ConsumerWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          i18n.t('inline.ui.pages.help_center_page.about_help_adbe73'),
        ),
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            PageHeader(
              eyebrow: i18n.t(
                'inline.ui.pages.help_center_page.help_center_78fd28',
              ),
              title: i18n.t('appTitle'),
              subtitle: i18n.t(
                'inline.ui.pages.help_center_page.find_the_app_overview_getting_started_flow_common_troubl_3956df',
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.info_outline_rounded,
              title: i18n.t(
                'inline.ui.pages.help_center_page.what_this_app_does_6ef62f',
              ),
              children: <Widget>[
                _BulletItem(
                  text: i18n.t(
                    'inline.ui.pages.help_center_page.combines_word_playback_library_management_speech_follow_9362dd',
                  ),
                ),
                _BulletItem(
                  text: i18n.t(
                    'inline.ui.pages.help_center_page.the_main_flow_is_play_library_practice_more_which_suppor_1db8ad',
                  ),
                ),
                _BulletItem(
                  text: i18n.t(
                    'inline.ui.pages.help_center_page.tasks_and_notes_can_act_as_a_lightweight_learning_inbox_edf63e',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.flag_outlined,
              title: i18n.t(
                'inline.ui.pages.help_center_page.recommended_start_349f08',
              ),
              children: <Widget>[
                _StepItem(
                  index: 1,
                  text: i18n.t(
                    'inline.ui.pages.help_center_page.start_in_wordbook_management_by_importing_or_creating_a_960ba9',
                  ),
                ),
                _StepItem(
                  index: 2,
                  text: i18n.t(
                    'inline.ui.pages.help_center_page.configure_voice_settings_voice_input_settings_and_recogn_22f7d0',
                  ),
                ),
                _StepItem(
                  index: 3,
                  text: i18n.t(
                    'inline.ui.pages.help_center_page.use_play_for_listening_ambient_sound_weather_and_quick_n_22e180',
                  ),
                ),
                _StepItem(
                  index: 4,
                  text: i18n.t(
                    'inline.ui.pages.help_center_page.use_practice_for_review_shuffled_drills_follow_along_and_40497b',
                  ),
                ),
                _StepItem(
                  index: 5,
                  text: i18n.t(
                    'inline.ui.pages.help_center_page.before_changing_devices_or_for_long_term_backup_export_u_e304b0',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.rule_folder_outlined,
              title: i18n.t(
                'inline.ui.pages.help_center_page.feature_boundaries_96b733',
              ),
              children: <Widget>[
                _BulletItem(
                  text: i18n.t(
                    'inline.ui.pages.help_center_page.voice_settings_control_playback_spoken_prompts_and_previ_31918c',
                  ),
                ),
                _BulletItem(
                  text: i18n.t(
                    'inline.ui.pages.help_center_page.voice_input_settings_only_control_speech_to_text_entry_p_3fde0a',
                  ),
                ),
                _BulletItem(
                  text: i18n.t(
                    'inline.ui.pages.help_center_page.recognition_settings_affect_only_follow_along_and_practi_95dd08',
                  ),
                ),
                _BulletItem(
                  text: i18n.t(
                    'inline.ui.pages.help_center_page.todo_reminders_require_a_reminder_time_first_syncing_the_076289',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.help_outline_rounded,
              title: i18n.t(
                'inline.ui.pages.help_center_page.common_questions_54fd93',
              ),
              children: <Widget>[
                _FaqTile(
                  question: i18n.t(
                    'inline.ui.pages.help_center_page.what_if_there_is_no_wordbook_or_no_study_content_f14c35',
                  ),
                  answer: i18n.t(
                    'inline.ui.pages.help_center_page.go_to_wordbook_management_first_and_import_create_or_edi_967643',
                  ),
                ),
                _FaqTile(
                  question: i18n.t(
                    'inline.ui.pages.help_center_page.what_if_playback_is_silent_or_the_voice_sounds_wrong_228734',
                  ),
                  answer: i18n.t(
                    'inline.ui.pages.help_center_page.check_voice_settings_first_along_with_device_media_volum_dcbbb7',
                  ),
                ),
                _FaqTile(
                  question: i18n.t(
                    'inline.ui.pages.help_center_page.what_is_the_difference_between_voice_input_and_speech_re_616b42',
                  ),
                  answer: i18n.t(
                    'inline.ui.pages.help_center_page.voice_input_is_for_dictation_into_text_such_as_quick_not_c935e1',
                  ),
                ),
                _FaqTile(
                  question: i18n.t(
                    'inline.ui.pages.help_center_page.what_if_todo_reminders_or_system_calendar_sync_do_not_wo_360b80',
                  ),
                  answer: i18n.t(
                    'inline.ui.pages.help_center_page.make_sure_the_todo_has_a_concrete_reminder_time_and_that_f0da13',
                  ),
                ),
                _FaqTile(
                  question: i18n.t(
                    'inline.ui.pages.help_center_page.how_should_i_back_up_or_move_data_to_another_device_f14e0e',
                  ),
                  answer: i18n.t(
                    'inline.ui.pages.help_center_page.open_data_management_export_user_data_and_confirm_the_ex_eddbee',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.shield_outlined,
              title: i18n.t(
                'inline.ui.pages.help_center_page.data_network_notes_577f2b',
              ),
              children: <Widget>[
                _BulletItem(
                  text: i18n.t(
                    'inline.ui.pages.help_center_page.wordbooks_practice_records_tasks_notes_and_most_settings_8d6272',
                  ),
                ),
                _BulletItem(
                  text: i18n.t(
                    'inline.ui.pages.help_center_page.weather_daily_quote_online_wordbook_lists_and_api_based_edfb36',
                  ),
                ),
                _BulletItem(
                  text: i18n.t(
                    'inline.ui.pages.help_center_page.if_you_rely_on_long_term_records_or_plan_to_change_devic_36bdae',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              i18n.t('toolbox.sleep.assist.jumpTitle'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SettingTile(
              icon: Icons.tune_rounded,
              title: i18n.t(
                'inline.ui.pages.help_center_page.open_settings_6ca4f9',
              ),
              subtitle: i18n.t(
                'inline.ui.pages.help_center_page.review_the_current_configuration_summary_and_fine_tune_i_4d1fc3',
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsHomePage(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SettingTile(
              icon: Icons.record_voice_over_rounded,
              title: i18n.t(
                'inline.ui.pages.help_center_page.voice_settings_9938df',
              ),
              subtitle: i18n.t(
                'inline.ui.pages.help_center_page.configure_playback_spoken_prompts_and_preview_options_0dfd7d',
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const VoiceSettingsPage(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SettingTile(
              icon: Icons.keyboard_voice_rounded,
              title: i18n.t(
                'inline.ui.pages.help_center_page.voice_input_settings_2bf6ed',
              ),
              subtitle: i18n.t(
                'inline.ui.pages.help_center_page.configure_dictation_based_voice_input_such_as_quick_note_992a4c',
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const VoiceInputSettingsPage(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SettingTile(
              icon: Icons.hearing_rounded,
              title: i18n.t(
                'inline.ui.pages.help_center_page.recognition_settings_887724',
              ),
              subtitle: i18n.t(
                'inline.ui.pages.help_center_page.configure_speech_recognition_offline_packages_and_scorin_2107da',
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const RecognitionSettingsPage(),
                ),
              ),
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
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const WordbookManagementPage(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SettingTile(
              icon: Icons.storage_rounded,
              title: i18n.t(
                'inline.ui.pages.data_management_page.data_management_87880c',
              ),
              subtitle: i18n.t(
                'inline.ui.pages.help_center_page.import_export_migration_and_user_data_maintenance_2226f3',
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DataManagementPage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 12,
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            child: Text('$index', style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        title: Text(question),
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(answer, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

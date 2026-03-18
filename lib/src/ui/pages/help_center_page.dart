import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../state/app_state.dart';
import '../ui_copy.dart';
import '../widgets/page_header.dart';
import '../widgets/setting_tile.dart';
import 'data_management_page.dart';
import 'recognition_settings_page.dart';
import 'settings_home_page.dart';
import 'voice_input_settings_page.dart';
import 'voice_settings_page.dart';
import 'wordbook_management_page.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);

    return Scaffold(
      appBar: AppBar(
        title: Text(pickUiText(i18n, zh: '关于与帮助', en: 'About & help')),
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            PageHeader(
              eyebrow: pickUiText(i18n, zh: '帮助中心', en: 'Help center'),
              title: i18n.t('appTitle'),
              subtitle: pickUiText(
                i18n,
                zh: '这里集中说明应用用途、上手顺序、常见问题和关键入口，方便你快速定位功能。',
                en: 'Find the app overview, getting-started flow, common troubleshooting, and key entry points in one place.',
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.info_outline_rounded,
              title: pickUiText(i18n, zh: '应用简介', en: 'What This App Does'),
              children: <Widget>[
                _BulletItem(
                  text: pickUiText(
                    i18n,
                    zh: '将单词播放、词库管理、跟读识别、练习、待办笔记与背景音整合在一个应用内。',
                    en: 'Combines word playback, library management, speech follow-along, practice, tasks, notes, and ambient audio in one app.',
                  ),
                ),
                _BulletItem(
                  text: pickUiText(
                    i18n,
                    zh: '主要入口为「播放 / 词库 / 练习 / 更多」，适合边听边记、再通过练习巩固。',
                    en: 'The main flow is Play / Library / Practice / More, which supports listen-first learning and later reinforcement.',
                  ),
                ),
                _BulletItem(
                  text: pickUiText(
                    i18n,
                    zh: '待办与笔记页可作为学习计划入口，用于记录任务、快速笔记与提醒。',
                    en: 'Tasks and notes can act as a lightweight learning inbox for reminders, quick notes, and daily planning.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.flag_outlined,
              title: pickUiText(i18n, zh: '推荐上手顺序', en: 'Recommended Start'),
              children: <Widget>[
                _StepItem(
                  index: 1,
                  text: pickUiText(
                    i18n,
                    zh: '先在「词本管理」中导入或新建词本，确认有可学习内容。',
                    en: 'Start in Wordbook Management by importing or creating a wordbook so the app has content to work with.',
                  ),
                ),
                _StepItem(
                  index: 2,
                  text: pickUiText(
                    i18n,
                    zh: '根据需要分别配置「语音设置」「语音输入设置」「识别设置」。这三者控制的是不同功能。',
                    en: 'Configure Voice settings, Voice input settings, and Recognition settings separately. They control different parts of the app.',
                  ),
                ),
                _StepItem(
                  index: 3,
                  text: pickUiText(
                    i18n,
                    zh: '进入「播放」页试听、切换背景音、查看天气，并在需要时记录快速笔记。',
                    en: 'Use Play for listening, ambient sound, weather, and quick notes during study or rest.',
                  ),
                ),
                _StepItem(
                  index: 4,
                  text: pickUiText(
                    i18n,
                    zh: '进入「练习」页做复习、乱序冲刺、跟读与记忆轨道，检查掌握情况。',
                    en: 'Use Practice for review, shuffled drills, follow-along, and memory-track progress.',
                  ),
                ),
                _StepItem(
                  index: 5,
                  text: pickUiText(
                    i18n,
                    zh: '准备迁移设备或长期保存时，到「数据管理」中导出用户数据。',
                    en: 'Before changing devices or for long-term backup, export user data from Data Management.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.rule_folder_outlined,
              title: pickUiText(i18n, zh: '功能区分说明', en: 'Feature Boundaries'),
              children: <Widget>[
                _BulletItem(
                  text: pickUiText(
                    i18n,
                    zh: '语音设置：控制单词播放、播报与试听，不负责快速笔记语音输入。',
                    en: 'Voice settings control playback, spoken prompts, and previews. They do not control quick-note voice input.',
                  ),
                ),
                _BulletItem(
                  text: pickUiText(
                    i18n,
                    zh: '语音输入设置：只控制快速笔记等语音转文字入口。',
                    en: 'Voice input settings only control speech-to-text entry points such as quick-note dictation.',
                  ),
                ),
                _BulletItem(
                  text: pickUiText(
                    i18n,
                    zh: '识别设置：只影响跟读和练习中的语音识别与评分。',
                    en: 'Recognition settings affect only follow-along and practice-time recognition or scoring.',
                  ),
                ),
                _BulletItem(
                  text: pickUiText(
                    i18n,
                    zh: '待办提醒需要先设置提醒时间；同步到系统日历时还需要系统日历权限。',
                    en: 'Todo reminders require a reminder time first. Syncing them into the system calendar also requires calendar permission.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.help_outline_rounded,
              title: pickUiText(i18n, zh: '常见问题', en: 'Common Questions'),
              children: <Widget>[
                _FaqTile(
                  question: pickUiText(
                    i18n,
                    zh: '没有词本或页面里没有可学内容怎么办？',
                    en: 'What if there is no wordbook or no study content?',
                  ),
                  answer: pickUiText(
                    i18n,
                    zh: '先到「词本管理」中导入、本地创建或编辑词本。没有词本时，播放、练习和复习相关功能都不会完整工作。',
                    en: 'Go to Wordbook Management first and import, create, or edit a wordbook. Without one, playback, practice, and review features cannot work fully.',
                  ),
                ),
                _FaqTile(
                  question: pickUiText(
                    i18n,
                    zh: '没有声音、发音不对或试听异常怎么办？',
                    en: 'What if playback is silent or the voice sounds wrong?',
                  ),
                  answer: pickUiText(
                    i18n,
                    zh: '优先检查「语音设置」、设备媒体音量、静音状态，以及当前是否切换到了本地或 API 发音源。修改后可先用试听验证。',
                    en: 'Check Voice settings first, along with device media volume, mute state, and whether the current source is local or API-based. Use the preview button after changing settings.',
                  ),
                ),
                _FaqTile(
                  question: pickUiText(
                    i18n,
                    zh: '语音输入和语音识别有什么区别？',
                    en: 'What is the difference between voice input and speech recognition?',
                  ),
                  answer: pickUiText(
                    i18n,
                    zh: '语音输入用于快速笔记等“说话转文字”；语音识别用于跟读和练习中的识别、评分与对比，两者配置入口是分开的。',
                    en: 'Voice input is for dictation into text, such as quick notes. Speech recognition is for follow-along and practice analysis, scoring, or comparison. They are configured separately.',
                  ),
                ),
                _FaqTile(
                  question: pickUiText(
                    i18n,
                    zh: '待办提醒或系统日历同步没有生效怎么办？',
                    en: 'What if todo reminders or system calendar sync do not work?',
                  ),
                  answer: pickUiText(
                    i18n,
                    zh: '确认待办已开启提醒并设置了具体时间，同时检查系统日历权限是否已授予。不同系统日历对通知和闹钟的呈现方式可能不同。',
                    en: 'Make sure the todo has a concrete reminder time and that calendar permission has been granted. Different system calendars may present notification-style and alarm-style reminders differently.',
                  ),
                ),
                _FaqTile(
                  question: pickUiText(
                    i18n,
                    zh: '换设备或担心数据丢失时该怎么做？',
                    en: 'How should I back up or move data to another device?',
                  ),
                  answer: pickUiText(
                    i18n,
                    zh: '到「数据管理」中导出用户数据，并在迁移前确认导出内容与保存位置。建议在大版本更新前也做一次导出备份。',
                    en: 'Open Data Management, export user data, and confirm the exported sections and destination path before migrating. It is also a good idea to export before major updates.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.shield_outlined,
              title: pickUiText(
                i18n,
                zh: '数据与联网说明',
                en: 'Data & Network Notes',
              ),
              children: <Widget>[
                _BulletItem(
                  text: pickUiText(
                    i18n,
                    zh: '词本、练习记录、待办、笔记和大部分设置默认保存在本地设备内。',
                    en: 'Wordbooks, practice records, tasks, notes, and most settings are stored locally on the device by default.',
                  ),
                ),
                _BulletItem(
                  text: pickUiText(
                    i18n,
                    zh: '天气、每日一言、在线词本列表以及使用 API 的语音相关功能会访问网络服务。',
                    en: 'Weather, daily quote, online wordbook lists, and API-based voice features use network services.',
                  ),
                ),
                _BulletItem(
                  text: pickUiText(
                    i18n,
                    zh: '如果你依赖长期记录或准备更换设备，建议定期导出用户数据。',
                    en: 'If you rely on long-term records or plan to change devices, export user data regularly.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              pickUiText(i18n, zh: '快捷入口', en: 'Quick actions'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SettingTile(
              icon: Icons.tune_rounded,
              title: pickUiText(i18n, zh: '打开设置中心', en: 'Open settings'),
              subtitle: pickUiText(
                i18n,
                zh: '查看当前配置摘要并继续微调。',
                en: 'Review the current configuration summary and fine-tune it.',
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
              title: pickUiText(i18n, zh: '语音设置', en: 'Voice settings'),
              subtitle: pickUiText(
                i18n,
                zh: '配置发音、播报与试听相关选项。',
                en: 'Configure playback, spoken prompts, and preview options.',
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
              title: pickUiText(i18n, zh: '语音输入设置', en: 'Voice input settings'),
              subtitle: pickUiText(
                i18n,
                zh: '配置快速笔记等语音转文字入口。',
                en: 'Configure dictation-based voice input such as quick-note entry.',
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
              title: pickUiText(i18n, zh: '识别设置', en: 'Recognition settings'),
              subtitle: pickUiText(
                i18n,
                zh: '配置跟读和练习中的语音识别、离线包与评分方式。',
                en: 'Configure speech recognition, offline packages, and scoring for follow-along and practice.',
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
              title: pickUiText(i18n, zh: '词本管理', en: 'Wordbook management'),
              subtitle: pickUiText(
                i18n,
                zh: '新建、导入、编辑、重命名与合并词本。',
                en: 'Create, import, edit, rename, and merge wordbooks.',
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
              title: pickUiText(i18n, zh: '数据管理', en: 'Data management'),
              subtitle: pickUiText(
                i18n,
                zh: '导入导出、迁移与用户数据维护。',
                en: 'Import, export, migration, and user-data maintenance.',
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

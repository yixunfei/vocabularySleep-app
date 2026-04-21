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
          title: pickUiText(
            i18n,
            zh: '低频但重要的入口',
            en: 'Low-frequency, high-value tools',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '把管理能力收拢到这里，让主流程更专注',
            en: 'Keep management tools here so the primary flow stays focused.',
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
                  pickUiText(i18n, zh: '当前状态', en: 'Current status'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  pickUiText(
                    i18n,
                    zh: '模式：${experienceModeTitle(i18n, mode)}',
                    en: 'Mode: ${experienceModeTitle(i18n, mode)}',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pickUiText(
                    i18n,
                    zh: '当前词本：${localizedWordbookName(i18n, state.selectedWordbook)}',
                    en: 'Current wordbook: ${localizedWordbookName(i18n, state.selectedWordbook)}',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pickUiText(
                    i18n,
                    zh: '可见词数：${state.visibleWords.length}',
                    en: 'Visible words: ${state.visibleWords.length}',
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
                  pickUiText(i18n, zh: '今日启动提示', en: 'Today startup prompt'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  pickUiText(
                    i18n,
                    zh: '启动后弹出今日待办、每日一言和天气摘要，可在弹窗中选择今日不再弹出。',
                    en: 'Show today\'s todos, daily quote, and weather after launch. You can still mute it for the rest of the day from the popup.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: state.startupTodoPromptEnabled,
                  title: Text(
                    pickUiText(i18n, zh: '开启启动提示', en: 'Enable startup prompt'),
                  ),
                  subtitle: Text(
                    state.startupTodoPromptEnabled
                        ? pickUiText(
                            i18n,
                            zh: '已开启，进入主界面时会自动显示今日摘要。',
                            en: 'Enabled. The summary appears after entering the main screen.',
                          )
                        : pickUiText(
                            i18n,
                            zh: '已关闭，启动后不会自动弹出今日摘要。',
                            en: 'Disabled. The summary stays hidden on startup.',
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
          title: pickUiText(i18n, zh: '设置中心', en: 'Settings center'),
          subtitle: pickUiText(
            i18n,
            zh: '语言、播放、语音和基础外观',
            en: 'Language, playback, speech, startup prompt, and practical appearance settings.',
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
          title: pickUiText(i18n, zh: '词本管理', en: 'Wordbook management'),
          subtitle: pickUiText(
            i18n,
            zh: '新增、导入、编辑、重命名和合并词本',
            en: 'Create, import, edit, rename, and merge wordbooks.',
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
          title: pickUiText(i18n, zh: '数据管理', en: 'Data management'),
          subtitle: pickUiText(
            i18n,
            zh: '导入导出、迁移和任务词维护',
            en: 'Import, export, migration, and task word maintenance.',
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
          title: pickUiText(i18n, zh: '关于与帮助', en: 'About & help'),
          subtitle: pickUiText(
            i18n,
            zh: '查看版本信息、常见问题与使用指引',
            en: 'Version info, FAQ, and quick guidance.',
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

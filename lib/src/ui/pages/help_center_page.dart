import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../state/app_state.dart';
import '../ui_copy.dart';
import '../widgets/page_header.dart';
import '../widgets/setting_tile.dart';
import 'data_management_page.dart';
import 'settings_home_page.dart';
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          PageHeader(
            eyebrow: pickUiText(i18n, zh: '支持中心', en: 'Support'),
            title: i18n.t('appTitle'),
            subtitle: pickUiText(
              i18n,
              zh: '4.0 产品深化阶段：重点优化跨页面联动与学习闭环。',
              en: '4.0 product-deepen stage focused on cross-page flow and learning loop.',
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
                    pickUiText(i18n, zh: '版本与状态', en: 'Version & status'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '当前版本：4.0',
                      en: 'Current version: 4.0',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '主路径：播放 / 词库 / 练习 / 更多',
                      en: 'Main path: Play / Library / Practice / More',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '建议：先在播放页输入，再去练习页做巩固。',
                      en: 'Suggestion: input from Play first, then reinforce in Practice.',
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
                    pickUiText(i18n, zh: '常见问题', en: 'Quick FAQ'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '1. 没有词本怎么办？请先到数据管理导入或新建词本。',
                      en: '1. No wordbook yet? Import or create one in Data Management.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '2. 如何快速复习？进入练习中心，优先选择“最近薄弱词复习”。',
                      en: '2. Fast review? Open Practice and start with recent weak words.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '3. 配置改完没感觉？可在语音设置即时试听，或返回播放页体验。',
                      en: '3. Changed settings but unsure? Use live voice preview or go back to Play.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SettingTile(
            icon: Icons.tune_rounded,
            title: pickUiText(i18n, zh: '打开设置中心', en: 'Open settings'),
            subtitle: pickUiText(
              i18n,
              zh: '查看当前配置摘要并继续微调。',
              en: 'See current summary and tune details.',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsHomePage()),
            ),
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.navigation_rounded,
            title: pickUiText(i18n, zh: '前往练习中心', en: 'Go to practice'),
            subtitle: pickUiText(
              i18n,
              zh: '请使用底部导航栏的“练习”页签进入。',
              en: 'Use the bottom navigation “Practice” tab.',
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    pickUiText(
                      i18n,
                      zh: '返回后点击底部“练习”页签即可进入。',
                      en: 'Go back and tap the bottom “Practice” tab.',
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.collections_bookmark_outlined,
            title: pickUiText(i18n, zh: '词本管理', en: 'Wordbook management'),
            subtitle: pickUiText(
              i18n,
              zh: '新建、重命名、删除与合并词本。',
              en: 'Create, rename, delete, and merge wordbooks.',
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
              zh: '导入导出、迁移与任务词维护。',
              en: 'Import, export, migration, and task maintenance.',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DataManagementPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

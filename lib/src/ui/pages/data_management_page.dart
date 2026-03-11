import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../state/app_state.dart';
import '../modal_helpers.dart';
import '../ui_copy.dart';
import '../widgets/setting_tile.dart';

class DataManagementPage extends StatelessWidget {
  const DataManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    return Scaffold(
      appBar: AppBar(
        title: Text(pickUiText(i18n, zh: '数据管理', en: 'Data management')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          SettingTile(
            icon: Icons.file_upload_outlined,
            title: pickUiText(i18n, zh: '导入词本', en: 'Import wordbook'),
            subtitle: pickUiText(
              i18n,
              zh: '支持 JSON / CSV / MDX 等格式',
              en: 'Supports JSON / CSV / MDX and more.',
            ),
            onTap: () => state.importWordbookByPicker(
              requestName: (suggestedName) => showTextPromptDialog(
                context: context,
                title: pickUiText(i18n, zh: '词本名称', en: 'Wordbook name'),
                initialValue: suggestedName,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.swap_horiz_rounded,
            title: pickUiText(
              i18n,
              zh: '迁移旧数据库',
              en: 'Migrate legacy database',
            ),
            subtitle: pickUiText(
              i18n,
              zh: '从历史 SQLite 数据迁移进当前结构',
              en: 'Import records from a previous SQLite database.',
            ),
            onTap: state.importLegacyDatabaseByPicker,
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.outbox_outlined,
            title: pickUiText(i18n, zh: '导出任务词本', en: 'Export task wordbook'),
            subtitle: pickUiText(
              i18n,
              zh: '把任务词导出成一个新的普通词本',
              en: 'Export task words into a regular wordbook.',
            ),
            onTap: () async {
              final name = await showTextPromptDialog(
                context: context,
                title: pickUiText(i18n, zh: '导出名称', en: 'Export name'),
                initialValue: pickUiText(i18n, zh: '任务词导出', en: 'Task export'),
              );
              if (name == null || name.trim().isEmpty) return;
              await state.exportTaskWordbook(name.trim());
            },
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.cleaning_services_outlined,
            title: pickUiText(i18n, zh: '清空任务词本', en: 'Clear task wordbook'),
            subtitle: pickUiText(
              i18n,
              zh: '清空后不会删除普通词本内容',
              en: 'This clears the task list without touching regular wordbooks.',
            ),
            onTap: () async {
              final confirmed = await showConfirmDialog(
                context: context,
                title: pickUiText(
                  i18n,
                  zh: '清空任务词本',
                  en: 'Clear task wordbook',
                ),
                message: pickUiText(
                  i18n,
                  zh: '确定清空当前任务词本吗？',
                  en: 'Clear the current task wordbook?',
                ),
                danger: true,
              );
              if (!confirmed) return;
              await state.clearTaskWordbook();
            },
          ),
          if ((state.lastBackupPath ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pickUiText(
                        i18n,
                        zh: '最近一次安全备份',
                        en: 'Latest safety backup',
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(state.lastBackupPath!),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

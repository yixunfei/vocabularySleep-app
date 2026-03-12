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
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.delete_forever_outlined,
            title: pickUiText(i18n, zh: '删除用户数据', en: 'Delete user data'),
            subtitle: pickUiText(
              i18n,
              zh: '清除自建词本、收藏、任务、外观配置与练习统计，保留内置词库。',
              en: 'Clear custom wordbooks, favorites, tasks, appearance settings, and practice stats while keeping built-in dictionaries.',
            ),
            onTap: () async {
              final confirmed = await showConfirmDialog(
                context: context,
                title: pickUiText(i18n, zh: '删除用户数据', en: 'Delete user data'),
                message: pickUiText(
                  i18n,
                  zh: '此操作会将应用恢复到初始状态，并尽量先创建安全备份。确定继续吗？',
                  en: 'This resets the app to its initial state and tries to create a safety backup first. Continue?',
                ),
                confirmText: pickUiText(i18n, zh: '确认删除', en: 'Delete'),
                danger: true,
              );
              if (!confirmed) return;

              final success = await state.resetUserData();
              if (!context.mounted || !success) return;

              final backupPath = state.lastBackupPath?.trim() ?? '';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    backupPath.isEmpty
                        ? pickUiText(
                            i18n,
                            zh: '用户数据已重置。',
                            en: 'User data has been reset.',
                          )
                        : pickUiText(
                            i18n,
                            zh: '用户数据已重置，并已创建安全备份。',
                            en: 'User data has been reset and a safety backup was created.',
                          ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickUiText(i18n, zh: '重置范围说明', en: 'Reset scope guide'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '当前页面偏向导入导出工具。完整重置将分层提供：外观与界面、播放与识别配置、练习统计、词本数据、离线资源。',
                      en: 'This page is currently focused on import/export tools. Layered reset actions will cover appearance/UI, playback/recognition settings, practice stats, wordbook data, and offline resources.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '建议先创建安全备份，再执行影响范围较大的清理或重置。',
                      en: 'Create a safety backup before running high-impact cleanup or reset actions.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickUiText(i18n, zh: '备份恢复入口', en: 'Backup restore entry'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '恢复入口将提供备份列表、来源操作和一键回滚。当前先保留占位，避免误导为已可恢复。',
                      en: 'A dedicated restore flow (backup list, source action, one-tap rollback) will be added next. This placeholder keeps behavior explicit.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.history_toggle_off_rounded),
                    label: Text(
                      pickUiText(
                        i18n,
                        zh: '从备份恢复（即将支持）',
                        en: 'Restore from backup (coming soon)',
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

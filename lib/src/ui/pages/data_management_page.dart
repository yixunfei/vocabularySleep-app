import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../services/database_service.dart';
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickUiText(i18n, zh: '当前调整', en: 'Current status'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '单词本导入、解析、迁移与导出恢复链路已临时下线，等待后续整体重写。这里暂时只保留安全备份、任务词导出和数据重置能力。',
                      en: 'Wordbook import, parsing, migration, export, and restore flows are temporarily offline pending a full rewrite. This page currently keeps safety backups, task export, and reset tools only.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.outbox_outlined,
            title: pickUiText(i18n, zh: '导出任务词本', en: 'Export task wordbook'),
            subtitle: pickUiText(
              i18n,
              zh: '把任务词导出成一个新的普通词本。',
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
              zh: '只清空任务列表，不影响普通词本内容。',
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
              zh: '清除自建词本、收藏、任务、界面配置与练习统计，并优先尝试创建安全备份。',
              en: 'Clear custom wordbooks, favorites, tasks, appearance settings, and practice stats, while trying to create a safety backup first.',
            ),
            onTap: () async {
              final confirmed = await showConfirmDialog(
                context: context,
                title: pickUiText(i18n, zh: '删除用户数据', en: 'Delete user data'),
                message: pickUiText(
                  i18n,
                  zh: '此操作会将应用恢复到初始状态，并会先尝试创建安全备份。确定继续吗？',
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
          const SizedBox(height: 12),
          _buildBackupRestoreCard(context, state, i18n),
          if ((state.lastBackupPath ?? '').trim().isNotEmpty) ...<Widget>[
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

  Widget _buildBackupRestoreCard(
    BuildContext context,
    AppState state,
    AppI18n i18n,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              pickUiText(i18n, zh: '恢复备份', en: 'Restore backup'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              pickUiText(
                i18n,
                zh: '可以查看最近备份、确认来源，并在恢复前自动为当前数据再创建一份安全备份。',
                en: 'Review recent backups, confirm where they came from, and create one more safety backup before restoring current data.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<DatabaseBackupInfo>>(
              future: state.listDatabaseBackups(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Text(
                    pickUiText(
                      i18n,
                      zh: '读取备份列表失败。',
                      en: 'Failed to read backup list.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }

                final backups = snapshot.data ?? const <DatabaseBackupInfo>[];
                if (backups.isEmpty) {
                  return Text(
                    pickUiText(
                      i18n,
                      zh: '还没有可恢复的备份。',
                      en: 'No backups are available yet.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }

                return Column(
                  children: backups
                      .map(
                        (backup) => Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _buildBackupItem(context, state, i18n, backup),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupItem(
    BuildContext context,
    AppState state,
    AppI18n i18n,
    DatabaseBackupInfo backup,
  ) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _formatBackupDate(backup.modifiedAt),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            pickUiText(
              i18n,
              zh: '来源: ${backup.reasonLabel}  ·  大小: ${_formatFileSize(backup.sizeBytes)}',
              en: 'Source: ${backup.reasonLabel}  ·  Size: ${_formatFileSize(backup.sizeBytes)}',
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(
            backup.path,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton.icon(
                onPressed: () => _deleteBackup(context, state, i18n, backup),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(pickUiText(i18n, zh: '删除', en: 'Delete')),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _restoreBackup(context, state, i18n, backup),
                icon: const Icon(Icons.restore_rounded),
                label: Text(
                  pickUiText(i18n, zh: '恢复这个备份', en: 'Restore this backup'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _restoreBackup(
    BuildContext context,
    AppState state,
    AppI18n i18n,
    DatabaseBackupInfo backup,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: pickUiText(i18n, zh: '恢复备份', en: 'Restore backup'),
      message: pickUiText(
        i18n,
        zh: '恢复后会用所选备份覆盖当前数据库内容。系统会先为当前状态再创建一份安全备份。确定继续吗？',
        en: 'The selected backup will replace the current database contents. The app will create one more safety backup first. Continue?',
      ),
      confirmText: pickUiText(i18n, zh: '确认恢复', en: 'Restore'),
      danger: true,
    );
    if (!confirmed) return;

    final success = await state.restoreDatabaseBackup(backup);
    if (!context.mounted || !success) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pickUiText(
            i18n,
            zh: '备份已恢复，当前数据已重新加载。',
            en: 'Backup restored and app data reloaded.',
          ),
        ),
      ),
    );
  }

  Future<void> _deleteBackup(
    BuildContext context,
    AppState state,
    AppI18n i18n,
    DatabaseBackupInfo backup,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: pickUiText(i18n, zh: '删除备份', en: 'Delete backup'),
      message: pickUiText(
        i18n,
        zh: '将永久删除这份安全备份。确认继续吗？',
        en: 'This will permanently delete the selected safety backup. Continue?',
      ),
      confirmText: pickUiText(i18n, zh: '删除', en: 'Delete'),
      danger: true,
    );
    if (!confirmed) return;

    final success = await state.deleteDatabaseBackup(backup);
    if (!context.mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pickUiText(i18n, zh: '备份已删除。', en: 'Backup deleted.')),
      ),
    );
  }

  String _formatBackupDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$month-$day $hour:$minute';
  }

  String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }
}

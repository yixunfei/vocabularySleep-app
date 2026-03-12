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
          SettingTile(
            icon: Icons.file_upload_outlined,
            title: pickUiText(i18n, zh: '导入词本', en: 'Import wordbook'),
            subtitle: pickUiText(
              i18n,
              zh: '支持 JSON / CSV / MDX 等格式。',
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
              zh: '从旧版 SQLite 数据库导入当前结构。',
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
              zh: '清除自建词本、收藏、任务、界面配置与练习统计，保留内建词库。',
              en: 'Clear custom wordbooks, favorites, tasks, appearance settings, and practice stats while keeping built-in dictionaries.',
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
                      zh: '这里集中放置导入、迁移、导出、删除与恢复能力。执行高影响操作前，建议先确认备份可用。',
                      en: 'This page groups import, migration, export, reset, and restore tools. Before high-impact actions, confirm that backups are available.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '删除和恢复都会影响当前数据库内容，请先确认风险范围。',
                      en: 'Delete and restore actions both affect the current database contents, so it is best to confirm the impact first.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
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
                      .map((backup) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _buildBackupItem(context, state, i18n, backup),
                        );
                      })
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
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _restoreBackup(context, state, i18n, backup),
              icon: const Icon(Icons.restore_rounded),
              label: Text(
                pickUiText(i18n, zh: '恢复这个备份', en: 'Restore this backup'),
              ),
            ),
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

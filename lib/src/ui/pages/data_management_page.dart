import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/app_i18n.dart';
import '../../services/database_service.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import '../modal_helpers.dart';
import '../widgets/setting_tile.dart';

class DataManagementPage extends ConsumerWidget {
  const DataManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          i18n.t('inline.ui.pages.data_management_page.data_management_87880c'),
        ),
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
                    i18n.t(
                      'inline.ui.pages.data_management_page.current_status_ed1d4c',
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    i18n.t(
                      'inline.ui.pages.data_management_page.wordbook_import_parsing_migration_export_and_restore_flo_5715a0',
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
            title: i18n.t('exportTaskWordbook'),
            subtitle: i18n.t(
              'inline.ui.pages.data_management_page.export_task_words_into_a_regular_wordbook_18f492',
            ),
            onTap: () async {
              final name = await showTextPromptDialog(
                context: context,
                title: i18n.t(
                  'inline.ui.pages.data_management_page.export_name_0da9da',
                ),
                initialValue: i18n.t(
                  'inline.ui.pages.data_management_page.task_export_887b93',
                ),
              );
              if (name == null || name.trim().isEmpty) return;
              await state.exportTaskWordbook(name.trim());
            },
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.cleaning_services_outlined,
            title: i18n.t('clearTaskWordbook'),
            subtitle: i18n.t(
              'inline.ui.pages.data_management_page.this_clears_the_task_list_without_touching_regular_wordb_dd7f85',
            ),
            onTap: () async {
              final confirmed = await showConfirmDialog(
                context: context,
                title: i18n.t('clearTaskWordbook'),
                message: i18n.t(
                  'inline.ui.pages.data_management_page.clear_the_current_task_wordbook_4a34f0',
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
            title: i18n.t(
              'inline.ui.pages.data_management_page.delete_user_data_0266ab',
            ),
            subtitle: i18n.t(
              'inline.ui.pages.data_management_page.clear_custom_wordbooks_favorites_tasks_appearance_settin_f4c888',
            ),
            onTap: () async {
              final confirmed = await showConfirmDialog(
                context: context,
                title: i18n.t(
                  'inline.ui.pages.data_management_page.delete_user_data_0266ab',
                ),
                message: i18n.t(
                  'inline.ui.pages.data_management_page.this_resets_the_app_to_its_initial_state_and_tries_to_cr_e1cc79',
                ),
                confirmText: i18n.t('delete'),
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
                        ? i18n.t(
                            'inline.ui.pages.data_management_page.user_data_has_been_reset_ce467e',
                          )
                        : i18n.t(
                            'inline.ui.pages.data_management_page.user_data_has_been_reset_and_a_safety_backup_was_created_0ddbe6',
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
                      i18n.t(
                        'inline.ui.pages.data_management_page.latest_safety_backup_7166aa',
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
              i18n.t(
                'inline.ui.pages.data_management_page.restore_backup_9c7c0d',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              i18n.t(
                'inline.ui.pages.data_management_page.review_recent_backups_confirm_where_they_came_from_and_c_dad97e',
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
                    i18n.t(
                      'inline.ui.pages.data_management_page.failed_to_read_backup_list_6177e8',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }

                final backups = snapshot.data ?? const <DatabaseBackupInfo>[];
                if (backups.isEmpty) {
                  return Text(
                    i18n.t(
                      'inline.ui.pages.data_management_page.no_backups_are_available_yet_14cacf',
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
            i18n.t(
              'inline.ui.pages.data_management_page.source_backup_reasonlabel_size_formatfilesize_backup_siz_85229a',
              params: <String, Object?>{
                'backupReasonLabel': backup.reasonLabel,
                'formatFileSizeBackupSizeBytes': _formatFileSize(
                  backup.sizeBytes,
                ),
              },
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
                label: Text(i18n.t('delete')),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _restoreBackup(context, state, i18n, backup),
                icon: const Icon(Icons.restore_rounded),
                label: Text(
                  i18n.t(
                    'inline.ui.pages.data_management_page.restore_this_backup_108e18',
                  ),
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
      title: i18n.t(
        'inline.ui.pages.data_management_page.restore_backup_9c7c0d',
      ),
      message: i18n.t(
        'inline.ui.pages.data_management_page.the_selected_backup_will_replace_the_current_database_co_f0a532',
      ),
      confirmText: i18n.t('toolbox.hub.edit.restore_action'),
      danger: true,
    );
    if (!confirmed) return;

    final success = await state.restoreDatabaseBackup(backup);
    if (!context.mounted || !success) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          i18n.t(
            'inline.ui.pages.data_management_page.backup_restored_and_app_data_reloaded_6d30b1',
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
      title: i18n.t(
        'inline.ui.pages.data_management_page.delete_backup_317ea6',
      ),
      message: i18n.t(
        'inline.ui.pages.data_management_page.this_will_permanently_delete_the_selected_safety_backup_23ebc2',
      ),
      confirmText: i18n.t('delete'),
      danger: true,
    );
    if (!confirmed) return;

    final success = await state.deleteDatabaseBackup(backup);
    if (!context.mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          i18n.t('inline.ui.pages.data_management_page.backup_deleted_7f48c1'),
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

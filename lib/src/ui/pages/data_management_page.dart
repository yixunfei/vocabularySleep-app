import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/user_data_export.dart';
import '../../services/database_service.dart';
import '../../state/app_state.dart';
import '../modal_helpers.dart';
import '../ui_copy.dart';
import '../widgets/setting_tile.dart';

const List<_UserDataExportSectionOption> _userDataExportSectionOptions =
    <_UserDataExportSectionOption>[
      _UserDataExportSectionOption(
        section: UserDataExportSection.wordbooks,
        zhTitle: '单词本与单词',
        enTitle: 'Wordbooks and words',
        zhSubtitle: '导出词本信息、单词内容和字段数据。',
        enSubtitle: 'Export wordbooks, entries, and field content.',
      ),
      _UserDataExportSectionOption(
        section: UserDataExportSection.todos,
        zhTitle: '待办事项',
        enTitle: 'Todos',
        zhSubtitle: '导出待办状态、提醒与排序信息。',
        enSubtitle: 'Export todo status, reminders, and ordering.',
      ),
      _UserDataExportSectionOption(
        section: UserDataExportSection.notes,
        zhTitle: '笔记',
        enTitle: 'Notes',
        zhSubtitle: '导出笔记标题、正文和更新时间。',
        enSubtitle: 'Export note titles, content, and timestamps.',
      ),
      _UserDataExportSectionOption(
        section: UserDataExportSection.progress,
        zhTitle: '记忆进度',
        enTitle: 'Memory progress',
        zhSubtitle: '导出单词熟悉度与复习状态。',
        enSubtitle: 'Export familiarity and spaced-repetition progress.',
      ),
      _UserDataExportSectionOption(
        section: UserDataExportSection.timerRecords,
        zhTitle: '专注记录',
        enTitle: 'Focus records',
        zhSubtitle: '导出番茄钟与专注时段记录。',
        enSubtitle: 'Export focus timer sessions and history.',
      ),
      _UserDataExportSectionOption(
        section: UserDataExportSection.settings,
        zhTitle: '应用设置',
        enTitle: 'App settings',
        zhSubtitle: '导出当前本地设置与偏好。',
        enSubtitle: 'Export local settings and preferences.',
      ),
    ];

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
            onTap: () async {
              final confirmed = await _confirmWordbookImport(context, i18n);
              if (!confirmed) return;
              await state.importWordbookByPicker(
                requestName: (suggestedName) => showTextPromptDialog(
                  context: context,
                  title: pickUiText(i18n, zh: '词本名称', en: 'Wordbook name'),
                  initialValue: suggestedName,
                ),
              );
            },
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
            onTap: () async {
              final confirmed = await _confirmLegacyMigration(context, i18n);
              if (!confirmed) return;
              await state.importLegacyDatabaseByPicker();
            },
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
            icon: Icons.ios_share_rounded,
            title: pickUiText(i18n, zh: '导出用户数据', en: 'Export user data'),
            subtitle: pickUiText(
              i18n,
              zh: '导出单词本、待办、笔记与专注记录，便于手动备份重要内容。',
              en: 'Export wordbooks, todos, notes, and focus records so important data can be backed up manually.',
            ),
            onTap: () => _exportUserData(context, state, i18n),
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

  Future<void> _exportUserData(
    BuildContext context,
    AppState state,
    AppI18n i18n,
  ) async {
    final defaultDirectoryPath = await state
        .getDefaultUserDataExportDirectoryPath();
    if (!context.mounted) return;

    final options = await _showUserDataExportDialog(
      context: context,
      i18n: i18n,
      defaultDirectoryPath: defaultDirectoryPath,
    );
    if (options == null) return;

    final path = await state.exportUserData(
      sections: options.sections,
      directoryPath: options.directoryPath,
      fileName: options.fileName,
    );
    if (!context.mounted || path == null || path.trim().isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pickUiText(
            i18n,
            zh: '用户数据已导出到: $path',
            en: 'User data exported to: $path',
          ),
        ),
      ),
    );
  }

  Future<UserDataExportOptions?> _showUserDataExportDialog({
    required BuildContext context,
    required AppI18n i18n,
    required String defaultDirectoryPath,
  }) async {
    final fileNameController = TextEditingController(
      text: _buildDefaultUserDataExportFileName(),
    );
    final directoryController = TextEditingController(
      text: defaultDirectoryPath,
    );
    final supportsNativeDirectoryPicker =
        !kIsWeb && defaultTargetPlatform != TargetPlatform.windows;
    final selectedSections = <UserDataExportSection>{
      for (final option in _userDataExportSectionOptions) option.section,
    };
    String? validationMessage;

    return showDialog<UserDataExportOptions>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            Future<void> pickDirectory() async {
              if (!supportsNativeDirectoryPicker) {
                return;
              }
              try {
                final picked = await FilePicker.platform.getDirectoryPath(
                  dialogTitle: pickUiText(
                    i18n,
                    zh: '选择导出位置',
                    en: 'Choose export location',
                  ),
                  initialDirectory: directoryController.text.trim().isEmpty
                      ? null
                      : directoryController.text.trim(),
                );
                if (picked == null || picked.trim().isEmpty) return;
                setStateDialog(() {
                  directoryController.text = picked.trim();
                  validationMessage = null;
                });
              } catch (error) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      pickUiText(
                        i18n,
                        zh: '选择导出位置失败：$error',
                        en: 'Failed to choose export location: $error',
                      ),
                    ),
                  ),
                );
              }
            }

            void submit() {
              final fileName = fileNameController.text.trim();
              final directoryPath = directoryController.text.trim();
              if (selectedSections.isEmpty) {
                setStateDialog(() {
                  validationMessage = pickUiText(
                    i18n,
                    zh: '请至少选择一项导出内容。',
                    en: 'Select at least one export section.',
                  );
                });
                return;
              }
              if (fileName.isEmpty) {
                setStateDialog(() {
                  validationMessage = pickUiText(
                    i18n,
                    zh: '请输入导出文件名。',
                    en: 'Enter an export file name.',
                  );
                });
                return;
              }
              if (directoryPath.isEmpty) {
                setStateDialog(() {
                  validationMessage = pickUiText(
                    i18n,
                    zh: '请选择或输入导出位置。',
                    en: 'Choose or enter an export location.',
                  );
                });
                return;
              }
              Navigator.of(dialogContext).pop(
                UserDataExportOptions(
                  sections: Set<UserDataExportSection>.from(selectedSections),
                  directoryPath: directoryPath,
                  fileName: fileName,
                ),
              );
            }

            final theme = Theme.of(dialogContext);
            return AlertDialog(
              title: Text(
                pickUiText(i18n, zh: '导出用户数据', en: 'Export user data'),
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        pickUiText(
                          i18n,
                          zh: '选择要导出的内容、保存位置和文件名。导出文件为 JSON，可用于手动备份。',
                          en: 'Choose what to export, where to save it, and the file name. The export will be written as JSON.',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        pickUiText(i18n, zh: '导出内容', en: 'Export content'),
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      for (final option in _userDataExportSectionOptions)
                        CheckboxListTile(
                          value: selectedSections.contains(option.section),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            pickUiText(
                              i18n,
                              zh: option.zhTitle,
                              en: option.enTitle,
                            ),
                          ),
                          subtitle: Text(
                            pickUiText(
                              i18n,
                              zh: option.zhSubtitle,
                              en: option.enSubtitle,
                            ),
                          ),
                          onChanged: (value) {
                            setStateDialog(() {
                              if (value ?? false) {
                                selectedSections.add(option.section);
                              } else {
                                selectedSections.remove(option.section);
                              }
                              validationMessage = null;
                            });
                          },
                        ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: fileNameController,
                        decoration: InputDecoration(
                          labelText: pickUiText(
                            i18n,
                            zh: '导出文件名',
                            en: 'File name',
                          ),
                          hintText:
                              'xianyushengxi_user_data_2026-03-18_09-30-00.json',
                          helperText: pickUiText(
                            i18n,
                            zh: '可不手动填写 .json 后缀，系统会自动补齐。',
                            en: 'The .json suffix is optional and will be added automatically.',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) {
                          if (validationMessage == null) return;
                          setStateDialog(() => validationMessage = null);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: directoryController,
                        minLines: 1,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: pickUiText(
                            i18n,
                            zh: '导出位置',
                            en: 'Export location',
                          ),
                          helperText: supportsNativeDirectoryPicker
                              ? pickUiText(
                                  i18n,
                                  zh: '可直接输入路径，也可以点击右侧按钮选择文件夹。',
                                  en: 'Enter a path directly or use the folder button to choose one.',
                                )
                              : pickUiText(
                                  i18n,
                                  zh: 'Windows 端为避免系统不稳定，已禁用文件夹选择器，请直接输入导出路径。',
                                  en: 'On Windows, the folder chooser is disabled to avoid system instability. Enter the export path directly.',
                                ),
                          border: const OutlineInputBorder(),
                          suffixIcon: supportsNativeDirectoryPicker
                              ? IconButton(
                                  tooltip: pickUiText(
                                    i18n,
                                    zh: '选择文件夹',
                                    en: 'Choose folder',
                                  ),
                                  onPressed: pickDirectory,
                                  icon: const Icon(Icons.folder_open_outlined),
                                )
                              : null,
                        ),
                        onChanged: (_) {
                          if (validationMessage == null) return;
                          setStateDialog(() => validationMessage = null);
                        },
                      ),
                      if (validationMessage != null) ...<Widget>[
                        const SizedBox(height: 12),
                        Text(
                          validationMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(pickUiText(i18n, zh: '取消', en: 'Cancel')),
                ),
                FilledButton.icon(
                  onPressed: submit,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(pickUiText(i18n, zh: '开始导出', en: 'Export')),
                ),
              ],
            );
          },
        );
      },
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

  Future<bool> _confirmWordbookImport(BuildContext context, AppI18n i18n) {
    return showConfirmDialog(
      context: context,
      title: pickUiText(i18n, zh: '导入单词本', en: 'Import wordbook'),
      message: pickUiText(
        i18n,
        zh: '单词本可能较大，导入与初始化需要一些时间。确认后将继续选择文件，请耐心等待。',
        en: 'Wordbooks can be large, so import and initialization may take a while. Continue to choose a file and please wait patiently.',
      ),
      confirmText: pickUiText(i18n, zh: '继续', en: 'Continue'),
    );
  }

  Future<bool> _confirmLegacyMigration(BuildContext context, AppI18n i18n) {
    return showConfirmDialog(
      context: context,
      title: pickUiText(i18n, zh: '迁移旧数据库', en: 'Migrate legacy database'),
      message: pickUiText(
        i18n,
        zh: '迁移前会先创建安全备份，旧库导入也可能持续一段时间。确认后将继续选择数据库文件。',
        en: 'A safety backup will be created first, and migrating an old database may also take a while. Continue to choose a database file?',
      ),
      confirmText: pickUiText(i18n, zh: '继续', en: 'Continue'),
    );
  }

  String _buildDefaultUserDataExportFileName({DateTime? now}) {
    final value = now ?? DateTime.now();
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return 'xianyushengxi_user_data_${value.year}-$month-$day'
        '_$hour-$minute-$second.json';
  }
}

class _UserDataExportSectionOption {
  const _UserDataExportSectionOption({
    required this.section,
    required this.zhTitle,
    required this.enTitle,
    required this.zhSubtitle,
    required this.enSubtitle,
  });

  final UserDataExportSection section;
  final String zhTitle;
  final String enTitle;
  final String zhSubtitle;
  final String enSubtitle;
}

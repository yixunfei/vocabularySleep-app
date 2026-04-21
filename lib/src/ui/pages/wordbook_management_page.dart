import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/app_i18n.dart';
import '../../models/wordbook.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import '../modal_helpers.dart';
import '../ui_copy.dart';
import '../wordbook_localization.dart';
import 'wordbook_editor_page.dart';

class WordbookManagementPage extends ConsumerWidget {
  const WordbookManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          pickUiText(
            i18n,
            zh: '词本管理',
            en: 'Wordbook management',
            ja: '単語帳管理',
            de: 'Wortbuchverwaltung',
            fr: 'Gestion des livres de mots',
            es: 'Gestion del libro de palabras',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          _QuickActionCard(
            i18n: i18n,
            onCreate: () => _createWordbook(context, state, i18n),
            onImport: () => _importWordbook(context, state, i18n),
            onDownloadOnline: () =>
                _downloadOnlineWordbooks(context, state, i18n),
          ),
          const SizedBox(height: 16),
          for (final book in state.wordbooks) ...<Widget>[
            _WordbookCard(
              book: book,
              isCurrent: state.selectedWordbook?.id == book.id,
              i18n: i18n,
              onSelect: () => _selectWordbook(context, state, book),
              onOpenEditor: () => _openEditor(context, state, book),
              onRename: book.isSystem
                  ? null
                  : () => _renameWordbook(context, state, i18n, book),
              onDelete: !book.canDelete
                  ? null
                  : () => _deleteWordbook(context, state, i18n, book),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          FilledButton.tonalIcon(
            onPressed: () => _mergeWordbooks(context, state, i18n),
            icon: const Icon(Icons.merge_type_rounded),
            label: Text(pickUiText(i18n, zh: '合并词本', en: 'Merge wordbooks')),
          ),
        ],
      ),
    );
  }

  Future<void> _createWordbook(
    BuildContext context,
    AppState state,
    AppI18n i18n,
  ) async {
    final name = await showTextPromptDialog(
      context: context,
      title: pickUiText(i18n, zh: '新建词本', en: 'New wordbook'),
      hintText: pickUiText(
        i18n,
        zh: '例如：睡前复习',
        en: 'For example: Night review',
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    await state.createWordbook(name.trim());
  }

  Future<void> _importWordbook(
    BuildContext context,
    AppState state,
    AppI18n i18n,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: pickUiText(i18n, zh: '导入词本', en: 'Import wordbook'),
      message: pickUiText(
        i18n,
        zh: '将从本地文件中选择一个词本进行导入。下一步你可以先确认名称，再选择实际文件。',
        en: 'You will choose a local wordbook file next. After that, you can confirm the import name before the file is processed.',
      ),
      confirmText: pickUiText(i18n, zh: '继续', en: 'Continue'),
    );
    if (!confirmed || !context.mounted) return;

    await state.importWordbookByPicker(
      requestName: (suggestedName) {
        return showTextPromptDialog(
          context: context,
          title: pickUiText(i18n, zh: '导入词本', en: 'Import wordbook'),
          subtitle: pickUiText(
            i18n,
            zh: '请输入导入后显示的词本名称。',
            en: 'Choose the display name for the imported wordbook.',
          ),
          initialValue: suggestedName,
          confirmText: pickUiText(i18n, zh: '导入', en: 'Import'),
        );
      },
    );
  }

  Future<void> _downloadOnlineWordbooks(
    BuildContext context,
    AppState state,
    AppI18n i18n,
  ) async {
    await state.refreshBuiltInWordbookCatalog();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pickUiText(
            i18n,
            zh: '已刷新在线词本目录。',
            en: 'Online wordbook catalog refreshed.',
          ),
        ),
      ),
    );
  }

  Future<void> _selectWordbook(
    BuildContext context,
    AppState state,
    Wordbook book,
  ) async {
    await state.selectWordbook(book);
  }

  Future<void> _openEditor(
    BuildContext context,
    AppState state,
    Wordbook book,
  ) async {
    await _selectWordbook(context, state, book);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WordbookEditorPage(wordbookId: book.id),
      ),
    );
  }

  Future<void> _renameWordbook(
    BuildContext context,
    AppState state,
    AppI18n i18n,
    Wordbook book,
  ) async {
    final name = await showTextPromptDialog(
      context: context,
      title: pickUiText(i18n, zh: '重命名词本', en: 'Rename wordbook'),
      initialValue: book.name,
    );
    if (name == null || name.trim().isEmpty) return;
    await state.renameWordbook(book, name.trim());
  }

  Future<void> _deleteWordbook(
    BuildContext context,
    AppState state,
    AppI18n i18n,
    Wordbook book,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: pickUiText(i18n, zh: '删除词本', en: 'Delete wordbook'),
      message: pickUiText(
        i18n,
        zh: '确定删除“${book.name}”吗？',
        en: 'Delete "${book.name}"?',
      ),
      danger: true,
      confirmText: pickUiText(i18n, zh: '删除', en: 'Delete'),
    );
    if (!confirmed) return;
    await state.deleteWordbook(book);
  }

  Future<void> _mergeWordbooks(
    BuildContext context,
    AppState state,
    AppI18n i18n,
  ) async {
    final books = state.wordbooks.where((item) => !item.isSystem).toList();
    if (books.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pickUiText(
              i18n,
              zh: '至少需要两个普通词本才能合并。',
              en: 'You need at least two regular wordbooks to merge.',
            ),
          ),
        ),
      );
      return;
    }

    var source = books.first;
    var target = books[1];
    var deleteSource = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final targetChoices = books
                .where((item) => item.id != source.id)
                .toList(growable: false);
            if (!targetChoices.any((item) => item.id == target.id)) {
              target = targetChoices.first;
            }
            return AlertDialog(
              title: Text(pickUiText(i18n, zh: '合并词本', en: 'Merge wordbooks')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButtonFormField<Wordbook>(
                    initialValue: source,
                    decoration: InputDecoration(
                      labelText: pickUiText(i18n, zh: '来源词本', en: 'Source'),
                    ),
                    items: books
                        .map(
                          (item) => DropdownMenuItem<Wordbook>(
                            value: item,
                            child: Text(item.name),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setStateDialog(() {
                        source = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Wordbook>(
                    initialValue: target,
                    decoration: InputDecoration(
                      labelText: pickUiText(i18n, zh: '目标词本', en: 'Target'),
                    ),
                    items: targetChoices
                        .map(
                          (item) => DropdownMenuItem<Wordbook>(
                            value: item,
                            child: Text(item.name),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setStateDialog(() {
                        target = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      pickUiText(
                        i18n,
                        zh: '合并后删除来源词本',
                        en: 'Delete source after merge',
                      ),
                    ),
                    value: deleteSource,
                    onChanged: (value) {
                      setStateDialog(() {
                        deleteSource = value;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel,
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(MaterialLocalizations.of(context).okButtonLabel),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true) return;
    await state.mergeWordbooks(
      sourceWordbookId: source.id,
      targetWordbookId: target.id,
      deleteSourceAfterMerge: deleteSource,
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.i18n,
    required this.onCreate,
    required this.onImport,
    required this.onDownloadOnline,
  });

  final AppI18n i18n;
  final VoidCallback onCreate;
  final VoidCallback onImport;
  final VoidCallback onDownloadOnline;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              pickUiText(i18n, zh: '快速操作', en: 'Quick actions'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              pickUiText(
                i18n,
                zh: '你可以新建空词本、从本地导入，或刷新当前可下载的内置/在线词本目录。',
                en: 'Create a blank wordbook, import one from a local file, or refresh the built-in and online catalog.',
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(pickUiText(i18n, zh: '新建词本', en: 'New wordbook')),
                ),
                FilledButton.tonalIcon(
                  onPressed: onImport,
                  icon: const Icon(Icons.file_upload_rounded),
                  label: Text(
                    pickUiText(i18n, zh: '导入词本', en: 'Import wordbook'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onDownloadOnline,
                  icon: const Icon(Icons.cloud_download_rounded),
                  label: Text(
                    pickUiText(
                      i18n,
                      zh: '下载在线词本',
                      en: 'Download online wordbooks',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WordbookCard extends StatelessWidget {
  const _WordbookCard({
    required this.book,
    required this.isCurrent,
    required this.i18n,
    required this.onSelect,
    required this.onOpenEditor,
    this.onRename,
    this.onDelete,
  });

  final Wordbook book;
  final bool isCurrent;
  final AppI18n i18n;
  final VoidCallback onSelect;
  final VoidCallback onOpenEditor;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = pickUiText(
      i18n,
      zh: book.isSystem
          ? '${book.wordCount} 个词 · 内置词本'
          : '${book.wordCount} 个词 · 自定义词本',
      en: book.isSystem
          ? '${book.wordCount} words · built-in'
          : '${book.wordCount} words · custom',
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: CircleAvatar(
                child: Icon(
                  book.isSystem
                      ? Icons.inventory_2_rounded
                      : Icons.collections_bookmark_rounded,
                ),
              ),
              title: Text(localizedWordbookName(i18n, book)),
              subtitle: Text(subtitle),
              selected: isCurrent,
              onTap: onSelect,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: isCurrent ? null : onSelect,
                    icon: Icon(
                      isCurrent
                          ? Icons.check_circle_rounded
                          : Icons.navigation_rounded,
                    ),
                    label: Text(
                      pickUiText(
                        i18n,
                        zh: isCurrent ? '当前使用' : '设为当前',
                        en: isCurrent ? 'Current' : 'Use',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpenEditor,
                    icon: const Icon(Icons.edit_note_rounded),
                    label: Text(pickUiText(i18n, zh: '编辑', en: 'Edit')),
                  ),
                  if (onRename != null)
                    OutlinedButton.icon(
                      onPressed: onRename,
                      icon: const Icon(Icons.drive_file_rename_outline_rounded),
                      label: Text(pickUiText(i18n, zh: '重命名', en: 'Rename')),
                    ),
                  if (onDelete != null)
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(pickUiText(i18n, zh: '删除', en: 'Delete')),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

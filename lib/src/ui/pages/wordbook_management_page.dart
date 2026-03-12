import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/wordbook.dart';
import '../../state/app_state.dart';
import '../modal_helpers.dart';
import '../ui_copy.dart';
import '../wordbook_localization.dart';
import 'wordbook_editor_page.dart';

class WordbookManagementPage extends StatelessWidget {
  const WordbookManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          pickUiText(
            i18n,
            zh: '\u8bcd\u672c\u7ba1\u7406',
            en: 'Wordbook management',
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
          ),
          const SizedBox(height: 16),
          for (final book in state.wordbooks) ...<Widget>[
            _WordbookCard(
              book: book,
              isCurrent: state.selectedWordbook?.id == book.id,
              i18n: i18n,
              onSelect: () => state.selectWordbook(book),
              onOpenEditor: () => _openEditor(context, state, book),
              onRename: book.isSystem
                  ? null
                  : () => _renameWordbook(context, state, i18n, book),
              onDelete: book.isSystem
                  ? null
                  : () => _deleteWordbook(context, state, i18n, book),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          FilledButton.tonalIcon(
            onPressed: () => _mergeWordbooks(context, state, i18n),
            icon: const Icon(Icons.merge_type_rounded),
            label: Text(
              pickUiText(
                i18n,
                zh: '\u5408\u5e76\u8bcd\u672c',
                en: 'Merge wordbooks',
              ),
            ),
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
      title: pickUiText(
        i18n,
        zh: '\u65b0\u5efa\u8bcd\u672c',
        en: 'New wordbook',
      ),
      hintText: pickUiText(
        i18n,
        zh: '\u4f8b\u5982\uff1a\u7761\u524d\u590d\u4e60',
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
    await state.importWordbookByPicker(
      requestName: (suggestedName) {
        return showTextPromptDialog(
          context: context,
          title: pickUiText(
            i18n,
            zh: '\u5bfc\u5165\u8bcd\u672c',
            en: 'Import wordbook',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '\u53ef\u4ee5\u76f4\u63a5\u4f7f\u7528\u6587\u4ef6\u540d\uff0c\u4e5f\u53ef\u4ee5\u5728\u8fd9\u91cc\u4fee\u6539\u8bcd\u672c\u540d\u79f0\u3002',
            en: 'Use the file name as-is, or rename the wordbook before import.',
          ),
          initialValue: suggestedName,
          hintText: pickUiText(
            i18n,
            zh: '\u8bcd\u672c\u540d\u79f0',
            en: 'Wordbook name',
          ),
          confirmText: pickUiText(i18n, zh: '\u5bfc\u5165', en: 'Import'),
        );
      },
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    AppState state,
    Wordbook book,
  ) async {
    await state.selectWordbook(book);
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
      title: pickUiText(
        i18n,
        zh: '\u91cd\u547d\u540d\u8bcd\u672c',
        en: 'Rename wordbook',
      ),
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
      title: pickUiText(
        i18n,
        zh: '\u5220\u9664\u8bcd\u672c',
        en: 'Delete wordbook',
      ),
      message: pickUiText(
        i18n,
        zh: '\u786e\u5b9a\u5220\u9664\u201c${book.name}\u201d\u5417\uff1f',
        en: 'Delete "${book.name}"?',
      ),
      danger: true,
      confirmText: pickUiText(i18n, zh: '\u5220\u9664', en: 'Delete'),
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
              zh: '\u81f3\u5c11\u9700\u8981\u4e24\u4e2a\u666e\u901a\u8bcd\u672c\u624d\u80fd\u5408\u5e76\u3002',
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
              title: Text(
                pickUiText(
                  i18n,
                  zh: '\u5408\u5e76\u8bcd\u672c',
                  en: 'Merge wordbooks',
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButtonFormField<Wordbook>(
                    initialValue: source,
                    decoration: InputDecoration(
                      labelText: pickUiText(
                        i18n,
                        zh: '\u6765\u6e90\u8bcd\u672c',
                        en: 'Source',
                      ),
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
                      labelText: pickUiText(
                        i18n,
                        zh: '\u76ee\u6807\u8bcd\u672c',
                        en: 'Target',
                      ),
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
                        zh: '\u5408\u5e76\u540e\u5220\u9664\u6765\u6e90\u8bcd\u672c',
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
  });

  final AppI18n i18n;
  final VoidCallback onCreate;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              pickUiText(
                i18n,
                zh: '\u5feb\u901f\u64cd\u4f5c',
                en: 'Quick actions',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              pickUiText(
                i18n,
                zh: '\u65b0\u5efa\u3001\u5bfc\u5165\u6216\u7ee7\u7eed\u7f16\u8f91\u8bcd\u672c\u3002./dict \u76ee\u5f55\u4e0b\u7684 JSON \u4f1a\u88ab\u8bc6\u522b\u4e3a\u5185\u7f6e\u8bcd\u672c\uff0c\u540d\u79f0\u9ed8\u8ba4\u4f7f\u7528\u6587\u4ef6\u540d\uff0c\u5e76\u5728\u9996\u6b21\u6253\u5f00\u65f6\u8f7d\u5165\u3002',
                en: 'Create, import, or continue editing wordbooks. JSON files under ./dict become built-ins, use the file name as their title, and load on first open.',
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
                  label: Text(
                    pickUiText(
                      i18n,
                      zh: '\u65b0\u589e\u8bcd\u672c',
                      en: 'New wordbook',
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: onImport,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(
                    pickUiText(
                      i18n,
                      zh: '\u5bfc\u5165\u8bcd\u672c',
                      en: 'Import wordbook',
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
          ? '${book.wordCount} \u4e2a\u8bcd \u00b7 \u5185\u7f6e\u8bcd\u672c'
          : '${book.wordCount} \u4e2a\u8bcd \u00b7 \u81ea\u5b9a\u4e49\u8bcd\u672c',
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
                        zh: isCurrent
                            ? '\u5f53\u524d\u4f7f\u7528'
                            : '\u8bbe\u4e3a\u5f53\u524d',
                        en: isCurrent ? 'Current' : 'Use',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpenEditor,
                    icon: const Icon(Icons.edit_note_rounded),
                    label: Text(
                      pickUiText(i18n, zh: '\u7f16\u8f91', en: 'Edit'),
                    ),
                  ),
                  if (onRename != null)
                    OutlinedButton.icon(
                      onPressed: onRename,
                      icon: const Icon(Icons.drive_file_rename_outline_rounded),
                      label: Text(
                        pickUiText(
                          i18n,
                          zh: '\u91cd\u547d\u540d',
                          en: 'Rename',
                        ),
                      ),
                    ),
                  if (onDelete != null)
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(
                        pickUiText(i18n, zh: '\u5220\u9664', en: 'Delete'),
                      ),
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

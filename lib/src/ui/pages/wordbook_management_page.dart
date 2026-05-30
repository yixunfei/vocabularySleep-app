import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/app_i18n.dart';
import '../../models/wordbook.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import '../modal_helpers.dart';
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
          i18n.t('inline.ui.pages.help_center_page.wordbook_management_7c76ef'),
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
            label: Text(i18n.t('mergeDialogTitle')),
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
      title: i18n.t(
        'inline.ui.pages.wordbook_management_page.new_wordbook_3f4de3',
      ),
      hintText: i18n.t(
        'inline.ui.pages.wordbook_management_page.for_example_night_review_714259',
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
      title: i18n.t(
        'inline.ui.pages.wordbook_management_page.import_wordbook_4905aa',
      ),
      message: i18n.t(
        'inline.ui.pages.wordbook_management_page.you_will_choose_a_local_wordbook_file_next_after_that_yo_4f6559',
      ),
      confirmText: i18n.t('toolbox.breathing.continue_select'),
    );
    if (!confirmed || !context.mounted) return;

    await state.importWordbookByPicker(
      requestName: (suggestedName) {
        return showTextPromptDialog(
          context: context,
          title: i18n.t(
            'inline.ui.pages.wordbook_management_page.import_wordbook_4905aa',
          ),
          subtitle: i18n.t(
            'inline.ui.pages.wordbook_management_page.choose_the_display_name_for_the_imported_wordbook_c226a0',
          ),
          initialValue: suggestedName,
          confirmText: i18n.t(
            'inline.ui.pages.wordbook_management_page.import_3c273d',
          ),
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
          i18n.t(
            'inline.ui.pages.wordbook_management_page.online_wordbook_catalog_refreshed_34f1d3',
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
      title: i18n.t('renameWordbook'),
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
      title: i18n.t('deleteWordbook'),
      message: i18n.t(
        'inline.ui.pages.wordbook_management_page.delete_book_name_974093',
      ),
      danger: true,
      confirmText: i18n.t('delete'),
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
            i18n.t(
              'inline.ui.pages.wordbook_management_page.you_need_at_least_two_regular_wordbooks_to_merge_88b3e6',
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
              title: Text(i18n.t('mergeDialogTitle')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButtonFormField<Wordbook>(
                    initialValue: source,
                    decoration: InputDecoration(
                      labelText: i18n.t(
                        'toolbox.sleep.science.referenceSource',
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
                      labelText: i18n.t('toolbox.breathing.target'),
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
                    title: Text(i18n.t('deleteSourceAfterMerge')),
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
              i18n.t('toolbox.sleep.assist.jumpTitle'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              i18n.t(
                'inline.ui.pages.wordbook_management_page.create_a_blank_wordbook_import_one_from_a_local_file_or_11655e',
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
                    i18n.t(
                      'inline.ui.pages.wordbook_management_page.new_wordbook_3f4de3',
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: onImport,
                  icon: const Icon(Icons.file_upload_rounded),
                  label: Text(
                    i18n.t(
                      'inline.ui.pages.wordbook_management_page.import_wordbook_4905aa',
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onDownloadOnline,
                  icon: const Icon(Icons.cloud_download_rounded),
                  label: Text(
                    i18n.t(
                      'inline.ui.pages.wordbook_management_page.download_online_wordbooks_1f8ecb',
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
    final subtitle = i18n.t(
      book.isSystem
          ? 'wordbookManagement.card.builtInSubtitle'
          : 'wordbookManagement.card.customSubtitle',
      params: <String, Object?>{'count': book.wordCount},
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
                      i18n.t(
                        isCurrent
                            ? 'wordbookManagement.card.currentAction'
                            : 'wordbookManagement.card.useAction',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpenEditor,
                    icon: const Icon(Icons.edit_note_rounded),
                    label: Text(i18n.t('edit')),
                  ),
                  if (onRename != null)
                    OutlinedButton.icon(
                      onPressed: onRename,
                      icon: const Icon(Icons.drive_file_rename_outline_rounded),
                      label: Text(i18n.t('rename')),
                    ),
                  if (onDelete != null)
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(i18n.t('delete')),
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

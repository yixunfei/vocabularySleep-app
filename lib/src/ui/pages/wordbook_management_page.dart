import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/wordbook.dart';
import '../../state/app_state.dart';
import '../modal_helpers.dart';
import '../ui_copy.dart';

class WordbookManagementPage extends StatelessWidget {
  const WordbookManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    return Scaffold(
      appBar: AppBar(
        title: Text(pickUiText(i18n, zh: '词本管理', en: 'Wordbook management')),
        actions: <Widget>[
          IconButton(
            onPressed: () => _createWordbook(context, state, i18n),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          for (final book in state.wordbooks) ...[
            Card(
              child: ListTile(
                selected: state.selectedWordbook?.id == book.id,
                title: Text(book.name),
                subtitle: Text(
                  pickUiText(
                    i18n,
                    zh: '${book.wordCount} 个词${book.isSystem ? ' · 系统词本' : ''}',
                    en: '${book.wordCount} words${book.isSystem ? ' · system' : ''}',
                  ),
                ),
                onTap: () => state.selectWordbook(book),
                trailing: book.isSystem
                    ? null
                    : PopupMenuButton<String>(
                        onSelected: (value) async {
                          switch (value) {
                            case 'rename':
                              await _renameWordbook(context, state, i18n, book);
                            case 'delete':
                              await _deleteWordbook(context, state, i18n, book);
                          }
                        },
                        itemBuilder: (_) => <PopupMenuEntry<String>>[
                          PopupMenuItem(
                            value: 'rename',
                            child: Text(
                              pickUiText(i18n, zh: '重命名', en: 'Rename'),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              pickUiText(i18n, zh: '删除', en: 'Delete'),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
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
        zh: '例如：睡前词表',
        en: 'For example: Night review',
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    await state.createWordbook(name.trim());
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
              zh: '至少需要两个普通词本才能合并',
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
                .toList();
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

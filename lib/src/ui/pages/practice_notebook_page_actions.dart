part of 'practice_notebook_page.dart';

extension _PracticeNotebookPageActions on _PracticeNotebookPageState {
  Future<void> _openPractice(
    BuildContext context,
    AppI18n i18n,
    List<WordEntry> words, {
    required bool shuffle,
  }) async {
    if (words.isEmpty) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticeSessionPage(
          title: i18n.t(
            'inline.ui.pages.practice_notebook_page_actions.wrong_notebook_review_88939c',
          ),
          subtitle: i18n.t(
            'inline.ui.pages.practice_notebook_page_actions.words_length_notebook_words_orderlabel_i18n_order_f4aa18',
            params: <String, Object?>{
              'words': words.length,
              'orderLabelOrder': _orderLabel(i18n, _order),
            },
          ),
          words: words,
          shuffle: shuffle,
        ),
      ),
    );
  }

  Future<void> _exportFiltered(
    BuildContext context,
    AppI18n i18n,
    List<WordEntry> entries,
    PracticeExportFormat format,
  ) async {
    final state = ref.read(appStateProvider);
    final defaultDirectory = await state
        .getDefaultUserDataExportDirectoryPath();
    if (!context.mounted) {
      return;
    }
    final fileName = await showTextPromptDialog(
      context: context,
      title: i18n.t(
        'inline.ui.pages.practice_notebook_page_actions.export_file_name_518c5f',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.practice_notebook_page_actions.the_file_will_be_saved_to_defaultdirectory_682a9b',
        params: <String, Object?>{'defaultDirectory': defaultDirectory},
      ),
      initialValue: 'xianyushengxi_wrong_notebook.${format.extension}',
      confirmText: i18n.t(
        'inline.ui.pages.practice_notebook_page_actions.export_bc626a',
      ),
    );
    if (fileName == null || fileName.trim().isEmpty) {
      return;
    }
    final path = await state.exportPracticeWrongNotebookData(
      entries: entries,
      format: format,
      fileName: fileName.trim(),
      metadata: <String, Object?>{
        'query': _query.trim(),
        'statusFilter': _statusFilter.name,
        'reasonFilter': _reasonFilter,
        'wordbookFilterId': _wordbookFilterId,
        'order': _order.name,
        'count': entries.length,
      },
    );
    if (!context.mounted || path == null || path.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          i18n.t(
            'inline.ui.pages.practice_notebook_page_actions.filtered_notebook_results_exported_to_path_20dd67',
            params: <String, Object?>{'path': path},
          ),
        ),
      ),
    );
  }

  Future<void> _applyBatchTask(
    BuildContext context,
    AppI18n i18n,
    List<WordEntry> selectedEntries,
  ) async {
    final added = await ref
        .read(appStateProvider)
        .addPracticeWordsToTask(selectedEntries);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added <= 0
              ? i18n.t(
                  'inline.ui.pages.practice_notebook_page_actions.all_selected_words_are_already_in_the_task_list_c2f3af',
                )
              : i18n.t(
                  'inline.ui.pages.practice_notebook_page_actions.added_to_task_list_added_a18082',
                  params: <String, Object?>{'added': added},
                ),
        ),
      ),
    );
  }

  Future<void> _applyBatchFavorite(
    BuildContext context,
    AppI18n i18n,
    List<WordEntry> selectedEntries,
  ) async {
    final added = await ref
        .read(appStateProvider)
        .addPracticeWordsToFavorites(selectedEntries);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added <= 0
              ? i18n.t(
                  'inline.ui.pages.practice_notebook_page_actions.all_selected_words_are_already_favorited_7c30bb',
                )
              : i18n.t(
                  'inline.ui.pages.practice_notebook_page_actions.added_to_favorites_added_6ace25',
                  params: <String, Object?>{'added': added},
                ),
        ),
      ),
    );
  }

  Future<void> _openFollowAlong(
    BuildContext context,
    AppState state,
    WordEntry word,
  ) async {
    await state.selectWordEntry(word);
    if (!context.mounted) return;
    final resolvedWord = state.currentWord ?? word;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FollowAlongPage(word: resolvedWord),
      ),
    );
  }

  Future<void> _clearNotebook(
    BuildContext context,
    AppI18n i18n, {
    required bool masteredOnly,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            masteredOnly
                ? i18n.t(
                    'inline.ui.pages.practice_notebook_page_actions.clear_mastered_words_2848c5',
                  )
                : i18n.t(
                    'inline.ui.pages.practice_notebook_page_actions.clear_notebook_3e08fc',
                  ),
          ),
          content: Text(
            masteredOnly
                ? i18n.t(
                    'inline.ui.pages.practice_notebook_page_actions.this_removes_words_that_look_stable_now_and_keeps_the_on_98d96c',
                  )
                : i18n.t(
                    'inline.ui.pages.practice_notebook_page_actions.this_removes_all_notebook_entries_but_does_not_delete_th_51c7e0',
                  ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(i18n.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(i18n.t('toolbox.breathing.continue_select')),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final removed = ref
        .read(appStateProvider)
        .clearPracticeWeakWords(masteredOnly: masteredOnly);
    final message = removed <= 0
        ? i18n.t(
            'inline.ui.pages.practice_notebook_page_actions.there_is_nothing_to_clear_in_the_notebook_4dbb2d',
          )
        : masteredOnly
        ? i18n.t(
            'inline.ui.pages.practice_notebook_page_actions.cleared_removed_mastered_notebook_words_194c80',
            params: <String, Object?>{'removed': removed},
          )
        : i18n.t(
            'inline.ui.pages.practice_notebook_page_actions.cleared_removed_notebook_words_85a05e',
            params: <String, Object?>{'removed': removed},
          );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

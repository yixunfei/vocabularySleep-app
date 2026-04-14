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
          title: pickUiText(i18n, zh: '错题本练习', en: 'Wrong notebook review'),
          subtitle: pickUiText(
            i18n,
            zh: '共 ${words.length} 个错题 · ${_orderLabel(i18n, _order)}',
            en: '${words.length} notebook words · ${_orderLabel(i18n, _order)}',
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
      title: pickUiText(i18n, zh: '导出文件名', en: 'Export file name'),
      subtitle: pickUiText(
        i18n,
        zh: '文件会默认保存到：$defaultDirectory',
        en: 'The file will be saved to: $defaultDirectory',
      ),
      initialValue: 'xianyushengxi_wrong_notebook.${format.extension}',
      confirmText: pickUiText(i18n, zh: '导出', en: 'Export'),
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
          pickUiText(
            i18n,
            zh: '错题本筛选结果已导出到：$path',
            en: 'Filtered notebook results exported to: $path',
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
              ? pickUiText(
                  i18n,
                  zh: '所选单词已全部在任务本中',
                  en: 'All selected words are already in the task list.',
                )
              : pickUiText(
                  i18n,
                  zh: '已加入任务本：$added 项',
                  en: 'Added to task list: $added',
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
              ? pickUiText(
                  i18n,
                  zh: '所选单词已全部在收藏中',
                  en: 'All selected words are already favorited.',
                )
              : pickUiText(
                  i18n,
                  zh: '已加入收藏：$added 项',
                  en: 'Added to favorites: $added',
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
                ? pickUiText(i18n, zh: '清理已掌握错题', en: 'Clear mastered words')
                : pickUiText(i18n, zh: '清空错题本', en: 'Clear notebook'),
          ),
          content: Text(
            masteredOnly
                ? pickUiText(
                    i18n,
                    zh: '会从错题本移除当前已稳定掌握的单词，保留仍需复习的部分。',
                    en: 'This removes words that look stable now and keeps the ones that still need review.',
                  )
                : pickUiText(
                    i18n,
                    zh: '会移除错题本中的全部单词，但不会删除词库本身和历史记忆进度。',
                    en: 'This removes all notebook entries but does not delete the wordbook data or memory history.',
                  ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(pickUiText(i18n, zh: '取消', en: 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(pickUiText(i18n, zh: '继续', en: 'Continue')),
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
        ? pickUiText(
            i18n,
            zh: '错题本没有可清理的内容',
            en: 'There is nothing to clear in the notebook.',
          )
        : masteredOnly
        ? pickUiText(
            i18n,
            zh: '已清理 $removed 个已掌握错题',
            en: 'Cleared $removed mastered notebook words',
          )
        : pickUiText(
            i18n,
            zh: '已清空 $removed 个错题',
            en: 'Cleared $removed notebook words',
          );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

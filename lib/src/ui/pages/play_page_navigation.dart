part of 'play_page.dart';

extension _PlayPageNavigation on _PlayPageState {
  int _indexOfWord(List<WordEntry> words, WordEntry target) {
    for (var index = 0; index < words.length; index += 1) {
      final item = words[index];
      if (item.id != null && target.id != null && item.id == target.id) {
        return index;
      }
      if (item.word == target.word && item.wordbookId == target.wordbookId) {
        return index;
      }
    }
    return words.indexWhere((item) => item.word == target.word);
  }

  Future<void> _moveToPreviousWord(
    AppState state, {
    required List<WordEntry> visibleWords,
    required int currentIndex,
  }) async {
    _setTransitionDirection(-1);
    if (state.isPlaying) {
      await state.movePlaybackPreviousWord();
      return;
    }
    if (visibleWords.isEmpty) return;
    final base = currentIndex < 0 ? 0 : currentIndex;
    final target = (base - 1 + visibleWords.length) % visibleWords.length;
    final targetWord = visibleWords[target];
    await state.selectWordEntry(targetWord);
    state.rememberPlaybackProgress(targetWord);
  }

  Future<void> _moveToNextWord(
    AppState state, {
    required List<WordEntry> visibleWords,
    required int currentIndex,
  }) async {
    _setTransitionDirection(1);
    if (state.isPlaying) {
      await state.movePlaybackNextWord();
      return;
    }
    if (visibleWords.isEmpty) return;
    final base = currentIndex < 0 ? 0 : currentIndex;
    final target = (base + 1) % visibleWords.length;
    final targetWord = visibleWords[target];
    await state.selectWordEntry(targetWord);
    state.rememberPlaybackProgress(targetWord);
  }

  int _resolveTargetIndex(double value, int totalWords) {
    if (totalWords <= 1) {
      return 0;
    }
    final clamped = value.clamp(0.0, 1.0);
    return (clamped * (totalWords - 1)).round().clamp(0, totalWords - 1);
  }

  double _resolveSliderValue(int index, int totalWords) {
    if (totalWords <= 1) {
      return 0;
    }
    return (index.clamp(0, totalWords - 1) / (totalWords - 1)).toDouble();
  }

  int _progressJumpStep(int totalWords) {
    if (totalWords >= 10000) return 500;
    if (totalWords >= 5000) return 250;
    if (totalWords >= 2000) return 100;
    if (totalWords >= 500) return 25;
    if (totalWords >= 200) return 10;
    return 5;
  }

  Future<void> _jumpToIndex(
    AppState state, {
    required List<WordEntry> visibleWords,
    required int currentIndex,
    required int targetIndex,
  }) async {
    if (visibleWords.isEmpty) {
      return;
    }
    final normalizedTarget = targetIndex.clamp(0, visibleWords.length - 1);
    final normalizedCurrent = currentIndex < 0 ? 0 : currentIndex;
    _setTransitionDirection(normalizedTarget >= normalizedCurrent ? 1 : -1);
    final targetWord = visibleWords[normalizedTarget];
    await state.selectWordEntry(targetWord);
    state.rememberPlaybackProgress(targetWord);
  }

  Future<void> _openExactJumpDialog(
    BuildContext context,
    AppState state,
    AppI18n i18n, {
    required List<WordEntry> visibleWords,
    required int currentIndex,
  }) async {
    if (visibleWords.length <= 1) {
      return;
    }
    final raw = await showTextPromptDialog(
      context: context,
      title: pickUiText(i18n, zh: '精确跳转', en: 'Exact jump'),
      subtitle: pickUiText(
        i18n,
        zh: '输入 1 到 ${visibleWords.length} 之间的位置编号。',
        en: 'Enter a position between 1 and ${visibleWords.length}.',
      ),
      hintText: pickUiText(i18n, zh: '例如 256', en: 'e.g. 256'),
      confirmText: pickUiText(i18n, zh: '跳转', en: 'Jump'),
    );
    if (!mounted || !context.mounted || raw == null) {
      return;
    }
    final target = int.tryParse(raw.trim());
    if (target == null || target < 1 || target > visibleWords.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pickUiText(
              i18n,
              zh: '请输入 1 到 ${visibleWords.length} 之间的编号。',
              en: 'Enter a number between 1 and ${visibleWords.length}.',
            ),
          ),
        ),
      );
      return;
    }
    _jumpToIndex(
      state,
      visibleWords: visibleWords,
      currentIndex: currentIndex,
      targetIndex: target - 1,
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

  Future<void> _openWordbookSheet(
    BuildContext context,
    AppState state,
    AppI18n i18n,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: <Widget>[
              Text(
                pickUiText(i18n, zh: '切换词本', en: 'Switch wordbook'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final book in state.wordbooks) ...<Widget>[
                Card(
                  child: ListTile(
                    selected: state.selectedWordbook?.id == book.id,
                    title: Text(localizedWordbookName(i18n, book)),
                    subtitle: Text(
                      pickUiText(
                        i18n,
                        zh: '${book.wordCount} 个词',
                        en: '${book.wordCount} words',
                      ),
                    ),
                    onTap: () async {
                      final confirmed = await _confirmWordbookLoadIfNeeded(
                        state,
                        i18n,
                        book,
                      );
                      if (!confirmed) return;
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                      await state.selectWordbook(book);
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confirmWordbookLoadIfNeeded(
    AppState state,
    AppI18n i18n,
    Wordbook book,
  ) {
    if (!state.requiresWordbookLoadConfirmation(book)) {
      return Future<bool>.value(true);
    }
    return showConfirmDialog(
      context: context,
      title: pickUiText(i18n, zh: '初始化单词本', en: 'Initialize wordbook'),
      message: pickUiText(
        i18n,
        zh: '${localizedWordbookName(i18n, book)} 可能较大，首次加载会初始化内容并需要一些时间。确认后继续，请耐心等待。',
        en: '${localizedWordbookName(i18n, book)} may be large. The first load will initialize its contents and may take a while. Continue and please wait patiently.',
      ),
      confirmText: pickUiText(i18n, zh: '继续', en: 'Continue'),
    );
  }
}

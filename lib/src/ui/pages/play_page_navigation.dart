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
    if (state.isPlaying) {
      await state.movePlaybackToWord(targetWord);
      return;
    }
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
      title: i18n.t('inline.ui.pages.play_page_navigation.exact_jump_8b53eb'),
      subtitle: i18n.t(
        'inline.ui.pages.play_page_navigation.enter_a_position_between_1_and_visiblewords_length_ed5abd',
        params: <String, Object?>{'count': visibleWords.length},
      ),
      hintText: i18n.t('inline.ui.pages.play_page_navigation.e_g_256_226af0'),
      confirmText: i18n.t('inline.ui.pages.play_page_navigation.jump_1534a4'),
    );
    if (!mounted || !context.mounted || raw == null) {
      return;
    }
    final target = int.tryParse(raw.trim());
    if (target == null || target < 1 || target > visibleWords.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            i18n.t(
              'inline.ui.pages.play_page_navigation.enter_a_number_between_1_and_visiblewords_length_01bc91',
              params: <String, Object?>{'count': visibleWords.length},
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
}

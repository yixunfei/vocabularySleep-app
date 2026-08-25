part of 'practice_page.dart';

String _practiceRoundSourceLabel(AppI18n i18n, PracticeRoundSource source) {
  return switch (source) {
    PracticeRoundSource.currentScope => i18n.t(
      'inline.ui.pages.practice_page_helpers.current_scope_dac5c3',
    ),
    PracticeRoundSource.wholeWordbook => i18n.t(
      'inline.ui.pages.practice_page_helpers.whole_wordbook_97adc1',
    ),
    PracticeRoundSource.wrongNotebook => i18n.t(
      'inline.ui.pages.practice_notebook_page.wrong_notebook_6c7ca5',
    ),
    PracticeRoundSource.taskWords => i18n.t(
      'inline.ui.pages.practice_page_helpers.task_words_75fdf1',
    ),
    PracticeRoundSource.favorites => i18n.t(
      'toolbox.sound.soothing.mode_filter_favorites',
    ),
    PracticeRoundSource.recentWeak => i18n.t(
      'inline.ui.pages.practice_page_helpers.recent_weak_words_9759a1',
    ),
  };
}

String _practiceRoundStartModeLabel(AppI18n i18n, PracticeRoundStartMode mode) {
  return switch (mode) {
    PracticeRoundStartMode.resumeCursor => i18n.t(
      'inline.ui.pages.practice_page_helpers.resume_last_position_980440',
    ),
    PracticeRoundStartMode.currentWord => i18n.t(
      'inline.ui.pages.practice_page_helpers.start_at_current_word_be574e',
    ),
    PracticeRoundStartMode.fromStart => i18n.t(
      'inline.ui.pages.practice_page_helpers.start_from_the_beginning_75193c',
    ),
  };
}

List<WordEntry> _resolvePracticeRoundSourceWords(
  PracticeRoundSource source, {
  required List<WordEntry> wordbookWords,
  required List<WordEntry> scopedWords,
  required List<WordEntry> taskWords,
  required List<WordEntry> favoriteWords,
  required List<WordEntry> weakWords,
  required List<WordEntry> wrongNotebookWords,
}) {
  return switch (source) {
    PracticeRoundSource.currentScope => scopedWords,
    PracticeRoundSource.wholeWordbook => wordbookWords,
    PracticeRoundSource.wrongNotebook => wrongNotebookWords,
    PracticeRoundSource.taskWords => taskWords,
    PracticeRoundSource.favorites => favoriteWords,
    PracticeRoundSource.recentWeak => weakWords,
  };
}

WordEntry? _resolvePracticeRoundAnchorWord(
  PracticeRoundStartMode mode, {
  required List<WordEntry> sourceWords,
  required WordEntry current,
}) {
  if (sourceWords.isEmpty) {
    return null;
  }
  return switch (mode) {
    PracticeRoundStartMode.resumeCursor => null,
    PracticeRoundStartMode.currentWord =>
      _containsWordEntry(sourceWords, current) ? current : sourceWords.first,
    PracticeRoundStartMode.fromStart => sourceWords.first,
  };
}

List<WordEntry> _mergeWordCollections(
  List<WordEntry> primary,
  List<WordEntry> secondary, {
  int limit = 12,
}) {
  final merged = <WordEntry>[];
  final seen = <String>{};

  void addWord(WordEntry word) {
    final key = '${word.wordbookId}:${word.word}';
    if (seen.contains(key)) {
      return;
    }
    seen.add(key);
    merged.add(word);
  }

  for (final word in primary) {
    addWord(word);
  }
  for (final word in secondary) {
    addWord(word);
  }
  if (merged.length <= limit) {
    return merged;
  }
  return merged.take(limit).toList(growable: false);
}

String _buildPracticeScopeRotationKey(AppState state, {required String slot}) {
  final query = state.searchQuery.trim().toLowerCase();
  final wordbookId = state.selectedWordbook?.id ?? 0;
  return 'practice:$slot:wordbook:$wordbookId:mode:${state.searchMode.name}:query:$query';
}

String _buildPracticeRoundRotationKey(
  AppState state, {
  required PracticeRoundSource source,
}) {
  final slot = switch (source) {
    PracticeRoundSource.currentScope => 'current-scope',
    PracticeRoundSource.wholeWordbook => 'whole-wordbook',
    PracticeRoundSource.wrongNotebook => 'wrong-notebook',
    PracticeRoundSource.taskWords => 'task-words',
    PracticeRoundSource.favorites => 'favorites',
    PracticeRoundSource.recentWeak => 'recent-weak',
  };
  if (source == PracticeRoundSource.currentScope) {
    return _buildPracticeScopeRotationKey(state, slot: 'round-$slot');
  }
  final wordbookId = state.selectedWordbook?.id ?? 0;
  return 'practice:round:$slot:wordbook:$wordbookId';
}

bool _containsWordEntry(List<WordEntry> words, WordEntry target) {
  return words.any((entry) => _isSameWordEntry(entry, target));
}

bool _isSameWordEntry(WordEntry a, WordEntry b) {
  return a.sameEntryAs(b);
}

class _PracticeWordBuckets {
  const _PracticeWordBuckets({
    required this.taskWords,
    required this.favoriteWords,
    required this.warmupWords,
    required this.currentSprintSourceWords,
    required this.currentSprintSource,
  });

  factory _PracticeWordBuckets.build({
    required AppState state,
    required List<WordEntry> wordbookWords,
    required List<WordEntry> scopedWords,
    required WordEntry current,
  }) {
    final taskWords = identical(wordbookWords, state.words)
        ? state.practiceTaskEntries
        : wordbookWords.where(state.isTaskEntry).toList(growable: false);
    final favoriteWords = identical(wordbookWords, state.words)
        ? state.practiceFavoriteEntries
        : wordbookWords.where(state.isFavoriteEntry).toList(growable: false);

    final warmupWords = scopedWords.length <= 7
        ? scopedWords
        : scopedWords.take(7).toList(growable: false);
    final currentInScope = _containsWordEntry(scopedWords, current);
    final currentSprintSourceWords = currentInScope
        ? scopedWords
        : wordbookWords;
    final currentSprintSource = currentInScope
        ? PracticeRoundSource.currentScope
        : PracticeRoundSource.wholeWordbook;

    return _PracticeWordBuckets(
      taskWords: taskWords,
      favoriteWords: favoriteWords,
      warmupWords: warmupWords,
      currentSprintSourceWords: currentSprintSourceWords,
      currentSprintSource: currentSprintSource,
    );
  }

  final List<WordEntry> taskWords;
  final List<WordEntry> favoriteWords;
  final List<WordEntry> warmupWords;
  final List<WordEntry> currentSprintSourceWords;
  final PracticeRoundSource currentSprintSource;
}

Future<void> _openPracticeWordbookSheet(
  BuildContext context,
  AppState state,
  AppI18n i18n,
) async {
  await showStudyWordbookSheet(context: context, state: state, i18n: i18n);
}

Future<void> _openPracticeSession(
  BuildContext context, {
  required String title,
  required String subtitle,
  required List<WordEntry> words,
  required bool shuffle,
  String? rotationKey,
  PracticeRoundSource? rotationSource,
  int? rotationSourceCount,
  int? rotationBatchSize,
  WordEntry? rotationAnchorWord,
  int? rotationCursorAdvance,
}) async {
  if (words.isEmpty) return;
  final appState = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(appStateProvider);
  if (!appState.isModuleEnabled(ModuleIds.practice)) {
    ensureModuleRouteAccess(
      context,
      state: appState,
      moduleId: ModuleIds.practice,
    );
    return;
  }
  var sessionWords = words;
  final canRotate =
      rotationKey != null &&
      rotationSource != null &&
      rotationSourceCount != null &&
      rotationBatchSize != null;
  if (canRotate) {
    final source = rotationSource;
    final key = rotationKey;
    final batchSize = rotationBatchSize;
    final sourceWords = appState.practiceBatchSourceWords(source);
    sessionWords = appState.beginPracticeBatch(
      cursorKey: key,
      sourceWords: sourceWords,
      batchSize: batchSize,
      anchorWord: rotationAnchorWord,
      cursorAdvance: rotationCursorAdvance,
    );
    if (sessionWords.isEmpty) {
      return;
    }
  }
  await pushModuleRoute<void>(
    context,
    state: appState,
    moduleId: ModuleIds.practice,
    builder: (_) => PracticeSessionPage(
      title: title,
      subtitle: subtitle,
      words: sessionWords,
      shuffle: shuffle,
      rotationKey: rotationKey,
      rotationSource: rotationSource,
      rotationSourceCount: rotationSourceCount,
      rotationBatchSize: rotationBatchSize,
      rotationCursorAdvance: rotationCursorAdvance,
    ),
  );
}

Future<void> _openReviewSession(
  BuildContext context,
  AppI18n i18n, {
  required String title,
  required String subtitle,
  required List<WordEntry> words,
}) async {
  if (words.isEmpty) {
    _showNoWordsSnack(context, i18n);
    return;
  }
  final appState = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(appStateProvider);
  await pushModuleRoute<void>(
    context,
    state: appState,
    moduleId: ModuleIds.practice,
    builder: (_) =>
        ReviewSessionPage(title: title, subtitle: subtitle, words: words),
  );
}

void _showNoWordsSnack(BuildContext context, AppI18n i18n) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        i18n.t(
          'inline.ui.pages.practice_page_helpers.no_words_available_in_the_current_scope_b9f098',
        ),
      ),
    ),
  );
}

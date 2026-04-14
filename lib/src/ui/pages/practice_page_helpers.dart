part of 'practice_page.dart';

String _practiceRoundSourceLabel(AppI18n i18n, PracticeRoundSource source) {
  return switch (source) {
    PracticeRoundSource.currentScope => pickUiText(
      i18n,
      zh: '当前范围',
      en: 'Current scope',
    ),
    PracticeRoundSource.wholeWordbook => pickUiText(
      i18n,
      zh: '整本词本',
      en: 'Whole wordbook',
    ),
    PracticeRoundSource.wrongNotebook => pickUiText(
      i18n,
      zh: '错题本',
      en: 'Wrong notebook',
    ),
    PracticeRoundSource.taskWords => pickUiText(
      i18n,
      zh: '任务词',
      en: 'Task words',
    ),
    PracticeRoundSource.favorites => pickUiText(
      i18n,
      zh: '收藏词',
      en: 'Favorites',
    ),
    PracticeRoundSource.recentWeak => pickUiText(
      i18n,
      zh: '最近薄弱词',
      en: 'Recent weak words',
    ),
  };
}

String _practiceRoundStartModeLabel(AppI18n i18n, PracticeRoundStartMode mode) {
  return switch (mode) {
    PracticeRoundStartMode.resumeCursor => pickUiText(
      i18n,
      zh: '从上次位置继续',
      en: 'Resume last position',
    ),
    PracticeRoundStartMode.currentWord => pickUiText(
      i18n,
      zh: '从当前词开始',
      en: 'Start at current word',
    ),
    PracticeRoundStartMode.fromStart => pickUiText(
      i18n,
      zh: '从头开始',
      en: 'Start from the beginning',
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

Future<void> _openPracticeSession(
  BuildContext context, {
  required String title,
  required String subtitle,
  required List<WordEntry> words,
  required bool shuffle,
  String? rotationKey,
  List<WordEntry>? rotationSourceWords,
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
      rotationSourceWords != null &&
      rotationBatchSize != null;
  if (canRotate) {
    sessionWords = appState.beginPracticeBatch(
      cursorKey: rotationKey,
      sourceWords: rotationSourceWords,
      batchSize: rotationBatchSize,
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
      rotationSourceWords: rotationSourceWords,
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
        pickUiText(
          i18n,
          zh: '当前范围内没有可练习单词。',
          en: 'No words available in the current scope.',
        ),
      ),
    ),
  );
}

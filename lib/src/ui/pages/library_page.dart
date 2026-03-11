import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/word_entry.dart';
import '../../state/app_state.dart';
import '../modal_helpers.dart';
import '../ui_copy.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/page_header.dart';
import '../widgets/word_row.dart';
import '../widgets/wordbook_switcher.dart';
import 'follow_along_page.dart';
import 'word_detail_page.dart';
import 'word_editor_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, this.onAttachScrollToTop});

  final ValueChanged<VoidCallback>? onAttachScrollToTop;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  static const List<String> _letters = <String>[
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    '#',
  ];
  static const int _pageSize = 20;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _rowKeys = <String, GlobalKey>{};
  bool _showScrollTopAnchor = false;
  int _visibleItemCount = _pageSize;
  int _currentScopeWordCount = 0;
  String _paginationSignature = '';

  @override
  void initState() {
    super.initState();
    widget.onAttachScrollToTop?.call(_scrollToTop);
    _scrollController.addListener(_handleScrollChanged);
  }

  @override
  void didUpdateWidget(covariant LibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onAttachScrollToTop != widget.onAttachScrollToTop) {
      widget.onAttachScrollToTop?.call(_scrollToTop);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScrollChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _syncSearchField(AppState state) {
    if (_searchController.text == state.searchQuery) return;
    _searchController.value = TextEditingValue(
      text: state.searchQuery,
      selection: TextSelection.collapsed(offset: state.searchQuery.length),
    );
  }

  String _wordIdentity(WordEntry word) {
    final rawId = word.id?.toString();
    if (rawId != null && rawId.isNotEmpty) {
      return '${word.wordbookId}|$rawId';
    }
    final fallbackSeed =
        '${word.wordbookId}|${word.word}|${word.meaning ?? ''}|${word.rawContent}';
    return '${word.wordbookId}|${fallbackSeed.hashCode}';
  }

  GlobalKey _rowKeyFor(WordEntry word) {
    final identity = _wordIdentity(word);
    return _rowKeys.putIfAbsent(
      identity,
      () => GlobalKey(debugLabel: 'library_word_$identity'),
    );
  }

  void _syncRowKeys(List<WordEntry> words) {
    final activeIdentities = words.map(_wordIdentity).toSet();
    _rowKeys.removeWhere((key, _) => !activeIdentities.contains(key));
    for (final word in words) {
      _rowKeyFor(word);
    }
  }

  String _buildPaginationSignature(AppState state, List<WordEntry> words) {
    final selectedWordbookId = state.selectedWordbook?.id.toString() ?? 'none';
    final searchQuery = state.searchQuery.trim();
    final firstIdentity = words.isEmpty ? 'empty' : _wordIdentity(words.first);
    final lastIdentity = words.isEmpty ? 'empty' : _wordIdentity(words.last);
    return '$selectedWordbookId|${state.searchMode.name}|$searchQuery|${words.length}|$firstIdentity|$lastIdentity';
  }

  void _syncPaginationState(AppState state, List<WordEntry> words) {
    final signature = _buildPaginationSignature(state, words);
    final scopeWordCount = words.length;
    if (_paginationSignature != signature) {
      _paginationSignature = signature;
      _currentScopeWordCount = scopeWordCount;
      _visibleItemCount = scopeWordCount == 0
          ? 0
          : min(_pageSize, scopeWordCount);
      return;
    }

    _currentScopeWordCount = scopeWordCount;
    if (_visibleItemCount > scopeWordCount) {
      _visibleItemCount = scopeWordCount;
    }
    if (scopeWordCount > 0 && _visibleItemCount == 0) {
      _visibleItemCount = min(_pageSize, scopeWordCount);
    }
  }

  bool _ensureVisibleItemCount(int requiredCount) {
    if (_currentScopeWordCount <= 0) return false;
    final normalizedCount = requiredCount
        .clamp(0, _currentScopeWordCount)
        .toInt();
    final nextCount = min(
      _currentScopeWordCount,
      max(normalizedCount, _visibleItemCount + _pageSize),
    );
    if (nextCount <= _visibleItemCount) return false;
    setState(() {
      _visibleItemCount = nextCount;
    });
    return true;
  }

  void _scrollToCurrent(AppState state, List<WordEntry> words) {
    final current = state.currentWord;
    if (current == null || words.isEmpty) return;
    final targetIdentity = _wordIdentity(current);
    final targetIndex = words.indexWhere(
      (word) => _wordIdentity(word) == targetIdentity,
    );
    if (targetIndex < 0) return;

    final loaded = _ensureVisibleItemCount(targetIndex + 1);
    if (loaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToCurrent(state, state.visibleWords);
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _rowKeys[targetIdentity];
      final targetContext = key?.currentContext;
      if (targetContext == null) return;
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.12,
      );
    });
  }

  void _scrollToTop() {
    if (_visibleItemCount > _pageSize) {
      setState(() {
        _visibleItemCount = min(_pageSize, _currentScopeWordCount);
        _showScrollTopAnchor = false;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController
          .animateTo(
            0,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          )
          .whenComplete(() {
            if (!_scrollController.hasClients) return;
            if (_scrollController.offset > 0.5) {
              _scrollController.jumpTo(0);
            }
          });
    });
  }

  void _handleScrollChanged() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final shouldLoadMore =
        _visibleItemCount < _currentScopeWordCount &&
        position.extentAfter < 560;
    final nextVisibleCount = shouldLoadMore
        ? min(_currentScopeWordCount, _visibleItemCount + _pageSize)
        : _visibleItemCount;
    final shouldShow = _scrollController.offset > 320;
    if (shouldShow == _showScrollTopAnchor &&
        nextVisibleCount == _visibleItemCount) {
      return;
    }
    setState(() {
      _visibleItemCount = nextVisibleCount;
      _showScrollTopAnchor = shouldShow;
    });
  }

  Future<void> _openPrefixJump(AppState state, AppI18n i18n) async {
    final prefix = await showTextPromptDialog(
      context: context,
      title: pickUiText(
        i18n,
        zh: '\u524d\u7f00\u8df3\u8f6c',
        en: 'Jump by prefix',
      ),
      hintText: pickUiText(
        i18n,
        zh: '\u8f93\u5165\u524d\u7f00',
        en: 'Type a prefix',
      ),
    );
    if (!mounted || prefix == null || prefix.trim().isEmpty) return;
    final success = state.jumpByPrefix(prefix.trim());
    if (success) {
      _scrollToCurrent(state, state.visibleWords);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pickUiText(
            i18n,
            zh: '\u5f53\u524d\u8303\u56f4\u5185\u6ca1\u6709\u5339\u914d\u7684\u8bcd',
            en: 'No matching word found in the current scope.',
          ),
        ),
      ),
    );
  }

  Set<String> _availableInitialLetters(List<WordEntry> words) {
    if (words.isEmpty) return const <String>{};
    final letters = <String>{};
    for (final word in words) {
      letters.add(_initialBucket(word.word));
    }
    return letters;
  }

  String _initialBucket(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '#';
    final first = trimmed[0].toUpperCase();
    final code = first.codeUnitAt(0);
    if (code >= 65 && code <= 90) return first;
    return '#';
  }

  Future<void> _openLetterIndexSheet(
    AppState state,
    AppI18n i18n, {
    required Set<String> availableLetters,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: <Widget>[
              Text(
                pickUiText(
                  i18n,
                  zh: '\u5b57\u6bcd\u8df3\u8f6c',
                  en: 'Letter index',
                ),
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                pickUiText(
                  i18n,
                  zh: '\u5c55\u5f00\u5168\u90e8\u9996\u5b57\u6bcd\uff0c\u5feb\u901f\u5b9a\u4f4d\u5230\u76ee\u6807\u533a\u6bb5\u3002',
                  en: 'Open full index and jump to the target section quickly.',
                ),
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _letters
                    .map((letter) {
                      final enabled = availableLetters.contains(letter);
                      return SizedBox(
                        width: 44,
                        child: FilledButton.tonal(
                          onPressed: enabled
                              ? () {
                                  Navigator.of(sheetContext).pop();
                                  final success = state.jumpByInitial(letter);
                                  if (success) {
                                    _scrollToCurrent(state, state.visibleWords);
                                  }
                                }
                              : null,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(44, 40),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(letter),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _openPrefixJump(state, i18n);
                },
                icon: const Icon(Icons.input_rounded),
                label: Text(
                  pickUiText(
                    i18n,
                    zh: '\u524d\u7f00\u8df3\u8f6c',
                    en: 'Prefix jump',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    _syncSearchField(state);

    if (state.selectedWordbook == null) {
      return EmptyStateView(
        icon: Icons.menu_book_rounded,
        title: pickUiText(
          i18n,
          zh: '\u8bcd\u5e93\u4e3a\u7a7a',
          en: 'Your library is empty',
        ),
        message: i18n.t('noWordbookYet'),
      );
    }

    final words = state.visibleWords;
    _syncPaginationState(state, words);
    final displayedWords = words
        .take(_visibleItemCount.clamp(0, words.length).toInt())
        .toList(growable: false);
    _syncRowKeys(displayedWords);
    final previewVisible = state.config.showText;
    final searching = state.searchQuery.trim().isNotEmpty;
    final availableLetters = _availableInitialLetters(words);
    final orderedLetters = _letters
        .where((letter) => availableLetters.contains(letter))
        .toList(growable: false);
    final quickLetters = orderedLetters.take(8).toList(growable: false);
    final useDenseIndexPreview = words.length > 12 && !searching;
    return Stack(
      children: <Widget>[
        ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          children: <Widget>[
            PageHeader(
              eyebrow: pageLabelLibrary(i18n),
              title: pickUiText(
                i18n,
                zh: '\u641c\u7d22\u4e0e\u6d4f\u89c8',
                en: 'Search and browse',
              ),
              subtitle: pickUiText(
                i18n,
                zh: '\u628a\u67e5\u8be2\u3001\u5207\u6362\u548c\u8df3\u8f6c\u653e\u5230\u79fb\u52a8\u7aef\u7684\u4e00\u7b49\u5165\u53e3',
                en: 'Make search, switching, and jumping first-class mobile actions.',
              ),
              action: IconButton(
                onPressed: () {
                  state.updateConfig(
                    state.config.copyWith(showText: !state.config.showText),
                  );
                },
                icon: Icon(
                  previewVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
                tooltip: i18n.t('showText'),
              ),
            ),
            const SizedBox(height: 18),
            WordbookSwitcher(
              wordbook: state.selectedWordbook,
              subtitle: pickUiText(
                i18n,
                zh: '${words.length} \u4e2a\u7ed3\u679c',
                en: '${words.length} results',
              ),
              onTap: () => _openWordbookSheet(state, i18n),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              onChanged: state.setSearchQuery,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: pickUiText(
                  i18n,
                  zh: '\u641c\u7d22\u5355\u8bcd\u3001\u91ca\u4e49\u6216\u6a21\u7cca\u5339\u914d',
                  en: 'Search words, meanings, or fuzzy matches',
                ),
                suffixIcon: state.searchQuery.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          state.setSearchQuery('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<SearchMode>(
                segments: SearchMode.values
                    .map(
                      (mode) => ButtonSegment<SearchMode>(
                        value: mode,
                        label: Text(searchModeLabel(i18n, mode)),
                      ),
                    )
                    .toList(growable: false),
                selected: <SearchMode>{state.searchMode},
                onSelectionChanged: (selection) {
                  state.setSearchMode(selection.first);
                },
              ),
            ),
            const SizedBox(height: 12),
            if (words.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              pickUiText(
                                i18n,
                                zh: '\u7d22\u5f15\u5bfc\u822a',
                                en: 'Index tools',
                              ),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: availableLetters.isEmpty
                                ? null
                                : () => _openLetterIndexSheet(
                                    state,
                                    i18n,
                                    availableLetters: availableLetters,
                                  ),
                            icon: const Icon(Icons.unfold_more_rounded),
                            label: Text(
                              pickUiText(
                                i18n,
                                zh: '\u5c55\u5f00\u7d22\u5f15',
                                en: 'Open index',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (useDenseIndexPreview && quickLetters.isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: <Widget>[
                              for (var i = 0; i < quickLetters.length; i++) ...[
                                ActionChip(
                                  label: Text(quickLetters[i]),
                                  onPressed: () {
                                    final success = state.jumpByInitial(
                                      quickLetters[i],
                                    );
                                    if (success) {
                                      _scrollToCurrent(
                                        state,
                                        state.visibleWords,
                                      );
                                    }
                                  },
                                ),
                                if (i != quickLetters.length - 1)
                                  const SizedBox(width: 8),
                              ],
                              if (orderedLetters.length > quickLetters.length)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    pickUiText(
                                      i18n,
                                      zh: '\u66f4\u591a...',
                                      en: 'More...',
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                            ],
                          ),
                        )
                      else
                        Text(
                          pickUiText(
                            i18n,
                            zh: '\u5f53\u524d\u4ec5 ${words.length} \u4e2a\u7ed3\u679c\uff0c\u5df2\u81ea\u52a8\u7b80\u5316\u5b57\u6bcd\u7d22\u5f15\u5c55\u793a\u3002',
                            en: 'Only ${words.length} results now. Letter index is simplified automatically.',
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          ActionChip(
                            avatar: const Icon(Icons.input_rounded, size: 18),
                            label: Text(
                              pickUiText(
                                i18n,
                                zh: '\u524d\u7f00\u8df3\u8f6c',
                                en: 'Prefix jump',
                              ),
                            ),
                            onPressed: () => _openPrefixJump(state, i18n),
                          ),
                          if (searching)
                            ActionChip(
                              avatar: const Icon(Icons.close_rounded, size: 18),
                              label: Text(
                                pickUiText(
                                  i18n,
                                  zh: '\u6e05\u9664\u641c\u7d22',
                                  en: 'Clear search',
                                ),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                state.setSearchQuery('');
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (words.isEmpty)
              EmptyStateView(
                icon: Icons.search_off_rounded,
                title: pickUiText(
                  i18n,
                  zh: '\u6ca1\u6709\u5339\u914d\u7ed3\u679c',
                  en: 'No matching words',
                ),
                message: pickUiText(
                  i18n,
                  zh: '\u8bd5\u8bd5\u5207\u6362\u641c\u7d22\u6a21\u5f0f\uff0c\u6216\u56de\u5230\u66f4\u591a\u9875\u5bfc\u5165\u65b0\u7684\u8bcd\u672c\u3002',
                  en: 'Try another search mode or import a new wordbook from More.',
                ),
              )
            else
              for (final word in displayedWords) ...[
                KeyedSubtree(
                  key: _rowKeyFor(word),
                  child: WordRow(
                    word: word,
                    i18n: i18n,
                    selected: state.currentWord?.word == word.word,
                    showMeaning: previewVisible,
                    showFields: previewVisible,
                    isFavorite: state.favorites.contains(word.word),
                    isTaskWord: state.taskWords.contains(word.word),
                    onTap: () => _openDetail(state, word),
                    onPlay: () => state.previewPronunciation(word.word),
                    onFollowAlong: () => _openFollowAlong(state, word),
                    onToggleFavorite: () => state.toggleFavorite(word),
                    onToggleTask: () => state.toggleTaskWord(word),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            if (displayedWords.length < words.length)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                child: Text(
                  pickUiText(
                    i18n,
                    zh: '已加载 ${displayedWords.length}/${words.length}，继续下滑将自动加载后续内容。',
                    en: 'Loaded ${displayedWords.length}/${words.length}. Keep scrolling to load more.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 86,
          child: IgnorePointer(
            ignoring: !_showScrollTopAnchor,
            child: AnimatedOpacity(
              opacity: _showScrollTopAnchor ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: FloatingActionButton.small(
                heroTag: 'library_scroll_top',
                onPressed: _scrollToTop,
                child: const Icon(Icons.vertical_align_top_rounded),
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 12,
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const WordEditorPage()),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: Text(pickUiText(i18n, zh: '\u52a0\u8bcd', en: 'Add word')),
          ),
        ),
      ],
    );
  }

  Future<void> _openWordbookSheet(AppState state, AppI18n i18n) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: <Widget>[
              Text(
                pickUiText(
                  i18n,
                  zh: '\u5207\u6362\u8bcd\u672c',
                  en: 'Switch wordbook',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final book in state.wordbooks) ...[
                Card(
                  child: ListTile(
                    selected: state.selectedWordbook?.id == book.id,
                    title: Text(book.name),
                    subtitle: Text(
                      pickUiText(
                        i18n,
                        zh: '${book.wordCount} \u4e2a\u8bcd',
                        en: '${book.wordCount} words',
                      ),
                    ),
                    onTap: () async {
                      await state.selectWordbook(book);
                      if (context.mounted) Navigator.of(context).pop();
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

  Future<void> _openDetail(AppState state, WordEntry word) async {
    state.selectWordEntry(word);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WordDetailPage(initialWord: word),
      ),
    );
  }

  Future<void> _openFollowAlong(AppState state, WordEntry word) async {
    state.selectWordEntry(word);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => FollowAlongPage(word: word)),
    );
  }
}

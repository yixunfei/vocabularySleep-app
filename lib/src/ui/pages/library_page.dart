import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/word_entry.dart';
import '../../models/wordbook.dart';
import '../../state/app_state.dart';
import '../modal_helpers.dart';
import '../ui_copy.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/page_header.dart';
import '../widgets/word_row.dart';
import '../widgets/wordbook_switcher.dart';
import '../wordbook_localization.dart';
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
  static const int _pageSize = 20;
  static const Duration _searchDebounceDuration = Duration(milliseconds: 160);

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listTopKey = GlobalKey(debugLabel: 'library_list_top');
  final Map<String, GlobalKey> _rowKeys = <String, GlobalKey>{};
  final Map<String, double> _rowHeights = <String, double>{};
  Timer? _searchDebounce;

  bool _showScrollTopAnchor = false;
  int _visibleItemCount = _pageSize;
  int _currentScopeWordCount = 0;
  String _paginationSignature = '';
  String _autoScrolledSignature = '';
  List<WordEntry> _loadedWords = const <WordEntry>[];

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
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _syncSearchField(AppState state) {
    if (_searchDebounce?.isActive == true) return;
    if (_searchController.text == state.searchQuery) return;
    _searchController.value = TextEditingValue(
      text: state.searchQuery,
      selection: TextSelection.collapsed(offset: state.searchQuery.length),
    );
  }

  void _onSearchChanged(AppState state, String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, () {
      if (!mounted) return;
      state.setSearchQuery(value);
    });
  }

  void _commitSearchQuery(AppState state, String value) {
    _searchDebounce?.cancel();
    state.setSearchQuery(value);
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
    _rowHeights.removeWhere((key, _) => !activeIdentities.contains(key));
    for (final word in words) {
      _rowKeyFor(word);
    }
  }

  void _recordRowExtent(WordEntry word, Size size) {
    final identity = _wordIdentity(word);
    final nextHeight = size.height;
    final currentHeight = _rowHeights[identity];
    if (currentHeight != null && (currentHeight - nextHeight).abs() < 0.5) {
      return;
    }
    _rowHeights[identity] = nextHeight;
  }

  String _buildPaginationSignature(AppState state, int totalWords) {
    final selectedWordbookId = state.selectedWordbook?.id.toString() ?? 'none';
    final searchQuery = state.searchQuery.trim();
    return '$selectedWordbookId|${state.searchMode.name}|$searchQuery|$totalWords';
  }

  void _syncPaginationState(AppState state, int totalWords) {
    final signature = _buildPaginationSignature(state, totalWords);
    final scopeWordCount = totalWords;
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

  void _maybeScrollToCurrentWord(AppState state) {
    final current = state.currentWord;
    if (current == null || _paginationSignature == _autoScrolledSignature) {
      return;
    }
    final targetIndex = state.findVisibleWordOffsetForEntry(current);
    if (targetIndex == null || targetIndex < 0) {
      return;
    }
    _autoScrolledSignature = _paginationSignature;
    if (targetIndex <= 1) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _scrollToIndex(targetIndex);
    });
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

  double _averageRowExtent(List<WordEntry> words) {
    if (_rowHeights.isEmpty) return 124;
    final measured = words
        .map((word) => _rowHeights[_wordIdentity(word)])
        .whereType<double>()
        .toList(growable: false);
    if (measured.isEmpty) return 124;
    final total = measured.fold<double>(0, (sum, height) => sum + height);
    return total / measured.length;
  }

  double? _scrollOffsetForKey(GlobalKey key) {
    final targetContext = key.currentContext;
    final renderObject = targetContext?.findRenderObject();
    if (renderObject == null) return null;
    final viewport = RenderAbstractViewport.of(renderObject);
    return viewport.getOffsetToReveal(renderObject, 0).offset;
  }

  double _estimateOffsetForIndex(List<WordEntry> words, int targetIndex) {
    final averageExtent = _averageRowExtent(words);
    final listTopOffset = _scrollOffsetForKey(_listTopKey) ?? 0;

    int? nearestBuiltIndex;
    double? nearestBuiltOffset;
    var nearestDistance = words.length + 1;

    for (var index = 0; index < words.length; index += 1) {
      final identity = _wordIdentity(words[index]);
      final key = _rowKeys[identity];
      final offset = key == null ? null : _scrollOffsetForKey(key);
      if (offset == null) continue;
      final distance = (index - targetIndex).abs();
      if (distance >= nearestDistance) continue;
      nearestDistance = distance;
      nearestBuiltIndex = index;
      nearestBuiltOffset = offset;
      if (distance == 0) break;
    }

    if (nearestBuiltIndex == null || nearestBuiltOffset == null) {
      return listTopOffset + averageExtent * targetIndex;
    }

    var estimated = nearestBuiltOffset;
    if (nearestBuiltIndex < targetIndex) {
      for (var index = nearestBuiltIndex; index < targetIndex; index += 1) {
        estimated += _rowHeights[_wordIdentity(words[index])] ?? averageExtent;
      }
      return estimated;
    }

    for (var index = targetIndex; index < nearestBuiltIndex; index += 1) {
      estimated -= _rowHeights[_wordIdentity(words[index])] ?? averageExtent;
    }
    return estimated;
  }

  Future<void> _coarseScrollToIndex(
    List<WordEntry> words,
    int targetIndex,
  ) async {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final desiredOffset =
        _estimateOffsetForIndex(words, targetIndex) -
        position.viewportDimension * 0.12;
    final targetOffset = desiredOffset.clamp(0.0, position.maxScrollExtent);
    final distance = (targetOffset - _scrollController.offset).abs();
    if (distance < 1) {
      _scrollController.jumpTo(targetOffset);
      return;
    }
    await _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollToIndex(int targetIndex, {int attempt = 0}) {
    if (targetIndex < 0 || _currentScopeWordCount <= 0) return;
    final loaded = _ensureVisibleItemCount(targetIndex + 1);
    if (loaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToIndex(targetIndex, attempt: attempt);
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (targetIndex >= _loadedWords.length) return;
      final targetIdentity = _wordIdentity(_loadedWords[targetIndex]);
      final key = _rowKeys[targetIdentity];
      final targetContext = key?.currentContext;
      if (targetContext != null) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: 0.12,
        );
        return;
      }
      if (attempt >= 4 || !_scrollController.hasClients) return;
      unawaited(
        _coarseScrollToIndex(_loadedWords, targetIndex).whenComplete(() {
          if (!mounted) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _scrollToIndex(targetIndex, attempt: attempt + 1);
          });
        }),
      );
    });
  }

  void _scrollToTop() {
    _searchDebounce?.cancel();
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
    final shouldShowTop = _scrollController.offset > 320;
    if (shouldShowTop == _showScrollTopAnchor &&
        nextVisibleCount == _visibleItemCount) {
      return;
    }
    setState(() {
      _visibleItemCount = nextVisibleCount;
      _showScrollTopAnchor = shouldShowTop;
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
    final normalizedPrefix = prefix.trim();
    final targetIndex = state.findVisibleWordOffsetByPrefix(normalizedPrefix);
    final success = state.jumpByPrefix(normalizedPrefix);
    if (success) {
      if (targetIndex != null) {
        _scrollToIndex(targetIndex);
      }
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

  String _wordbookSummary(AppI18n i18n, Wordbook? book, int visibleCount) {
    final isLazyBuiltIn =
        book != null &&
        book.path.startsWith('builtin:dict:') &&
        book.wordCount <= 0;
    if (isLazyBuiltIn) {
      return pickUiText(
        i18n,
        zh: '\u5185\u7f6e\u8bcd\u672c\uff0c\u9996\u6b21\u6253\u5f00\u65f6\u8f7d\u5165',
        en: 'Built-in wordbook, loads on first open',
      );
    }
    return pickUiText(
      i18n,
      zh: '$visibleCount \u4e2a\u7ed3\u679c',
      en: '$visibleCount results',
    );
  }

  String _wordbookSheetSubtitle(AppI18n i18n, Wordbook book) {
    final isLazyBuiltIn =
        book.path.startsWith('builtin:dict:') && book.wordCount <= 0;
    if (isLazyBuiltIn) {
      return pickUiText(
        i18n,
        zh: '\u5185\u7f6e\u8bcd\u672c\uff0c\u70b9\u51fb\u540e\u9996\u6b21\u8f7d\u5165',
        en: 'Built-in wordbook, loads on first tap',
      );
    }
    return pickUiText(
      i18n,
      zh: '${book.wordCount} \u4e2a\u8bcd',
      en: '${book.wordCount} words',
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

    final totalWords = state.visibleWordCount;
    final words = _WordCountProxy(totalWords);
    _syncPaginationState(state, totalWords);
    final displayedWords = totalWords <= 0
        ? const <WordEntry>[]
        : state.getVisibleWordsPage(
            limit: _visibleItemCount.clamp(0, totalWords).toInt(),
            offset: 0,
          );
    _loadedWords = displayedWords;
    _syncRowKeys(displayedWords);
    final currentWord = state.currentWord;
    final selectedIdentity = currentWord == null
        ? null
        : _wordIdentity(currentWord);
    _maybeScrollToCurrentWord(state);
    final previewVisible = state.config.showText;
    final searching = state.searchQuery.trim().isNotEmpty;
    final mediaQuery = MediaQuery.of(context);
    final compactHeight = mediaQuery.size.height < 720;
    final showCompactAddWord = compactHeight || mediaQuery.size.width < 360;
    final showFloatingScrollTop = _showScrollTopAnchor;
    final overlayRight = compactHeight ? 12.0 : 16.0;
    final overlayBottom = mediaQuery.padding.bottom + 12;
    final bottomSpacer = showCompactAddWord ? 128.0 : 144.0;

    return Stack(
      children: <Widget>[
        CustomScrollView(
          controller: _scrollController,
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            state.config.copyWith(
                              showText: !state.config.showText,
                            ),
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
                      title: localizedWordbookName(
                        i18n,
                        state.selectedWordbook,
                      ),
                      subtitle: _wordbookSummary(
                        i18n,
                        state.selectedWordbook,
                        totalWords,
                      ),
                      onTap: () {
                        _commitSearchQuery(state, _searchController.text);
                        _openWordbookSheet(state, i18n);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => _onSearchChanged(state, value),
                      onSubmitted: (value) => _commitSearchQuery(state, value),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        hintText: pickUiText(
                          i18n,
                          zh: '\u641c\u7d22\u5355\u8bcd\u3001\u91ca\u4e49\u6216\u6a21\u7cca\u5339\u914d',
                          en: 'Search words, meanings, or fuzzy matches',
                        ),
                        suffixIcon: _searchController.text.trim().isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  _commitSearchQuery(state, '');
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
                          if (selection.isEmpty) return;
                          _commitSearchQuery(state, _searchController.text);
                          state.setSearchMode(selection.first);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (totalWords > 0)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                pickUiText(
                                  i18n,
                                  zh: '\u5feb\u901f\u8df3\u8f6c',
                                  en: 'Quick jump',
                                  ja: '\u30af\u30a4\u30c3\u30af\u30b8\u30e3\u30f3\u30d7',
                                  de: 'Schnellsprung',
                                  fr: 'Saut rapide',
                                  es: 'Salto rapido',
                                ),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                pickUiText(
                                  i18n,
                                  zh: '\u8f93\u5165\u5355\u8bcd\u524d\u7f00\uff0c\u53ef\u76f4\u63a5\u8df3\u5230\u5f53\u524d\u8303\u56f4\u5185\u7b2c\u4e00\u4e2a\u5339\u914d\u9879\u3002',
                                  en: 'Type a prefix to jump directly to the first matching word in the current scope.',
                                  ja: '\u63a5\u982d\u8f9e\u3092\u5165\u529b\u3059\u308b\u3068\u3001\u73fe\u5728\u306e\u7bc4\u56f2\u5185\u3067\u6700\u521d\u306b\u4e00\u81f4\u3059\u308b\u5358\u8a9e\u3078\u79fb\u52d5\u3067\u304d\u307e\u3059\u3002',
                                  de: 'Geben Sie ein Praefix ein, um direkt zum ersten passenden Wort im aktuellen Bereich zu springen.',
                                  fr: 'Saisissez un prefixe pour aller directement au premier mot correspondant dans la portee actuelle.',
                                  es: 'Escribe un prefijo para saltar directamente a la primera palabra coincidente del alcance actual.',
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  ActionChip(
                                    avatar: const Icon(
                                      Icons.input_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      pickUiText(
                                        i18n,
                                        zh: '\u524d\u7f00\u8df3\u8f6c',
                                        en: 'Prefix jump',
                                        ja: '\u63a5\u982d\u8f9e\u30b8\u30e3\u30f3\u30d7',
                                        de: 'Praefixsprung',
                                        fr: 'Saut par prefixe',
                                        es: 'Salto por prefijo',
                                      ),
                                    ),
                                    onPressed: () =>
                                        _openPrefixJump(state, i18n),
                                  ),
                                  if (searching)
                                    ActionChip(
                                      avatar: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        pickUiText(
                                          i18n,
                                          zh: '\u6e05\u9664\u641c\u7d22',
                                          en: 'Clear search',
                                          ja: '\u691c\u7d22\u3092\u30af\u30ea\u30a2',
                                          de: 'Suche loeschen',
                                          fr: 'Effacer la recherche',
                                          es: 'Limpiar busqueda',
                                        ),
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        _commitSearchQuery(state, '');
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            if (totalWords <= 0)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: EmptyStateView(
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
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(key: _listTopKey, height: 0),
                ),
              ),
            if (totalWords > 0)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final word = displayedWords[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MeasuredSize(
                        onSizeChanged: (size) => _recordRowExtent(word, size),
                        child: KeyedSubtree(
                          key: _rowKeyFor(word),
                          child: WordRow(
                            word: word,
                            i18n: i18n,
                            selected: selectedIdentity == _wordIdentity(word),
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
                      ),
                    );
                  }, childCount: displayedWords.length),
                ),
              ),
            if (displayedWords.length < totalWords)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    pickUiText(
                      i18n,
                      zh: '已加载 ${displayedWords.length}/${words.length}，继续下滑将自动加载后续内容。',
                      en: 'Loaded ${displayedWords.length}/$totalWords. Keep scrolling to load more.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: bottomSpacer)),
          ],
        ),
        Positioned(
          right: overlayRight,
          bottom: overlayBottom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              if (showFloatingScrollTop) ...<Widget>[
                FloatingActionButton.small(
                  heroTag: 'library_scroll_top',
                  onPressed: _scrollToTop,
                  child: const Icon(Icons.vertical_align_top_rounded),
                ),
                const SizedBox(height: 10),
              ],
              if (showCompactAddWord)
                FloatingActionButton.small(
                  heroTag: 'library_add_word',
                  tooltip: pickUiText(i18n, zh: '\u52a0\u8bcd', en: 'Add word'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const WordEditorPage(),
                      ),
                    );
                  },
                  child: const Icon(Icons.add_rounded),
                )
              else
                FloatingActionButton.extended(
                  heroTag: 'library_add_word',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const WordEditorPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    pickUiText(i18n, zh: '\u52a0\u8bcd', en: 'Add word'),
                  ),
                ),
            ],
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
                    title: Text(localizedWordbookName(i18n, book)),
                    subtitle: Text(_wordbookSheetSubtitle(i18n, book)),
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

  Future<void> _openDetail(AppState state, WordEntry word) async {
    state.selectWordEntry(word);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WordDetailPage(initialWord: word),
      ),
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

  Future<void> _openFollowAlong(AppState state, WordEntry word) async {
    state.selectWordEntry(word);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => FollowAlongPage(word: word)),
    );
  }
}

class _WordCountProxy {
  const _WordCountProxy(this.length);

  final int length;
}

class _MeasuredSize extends StatefulWidget {
  const _MeasuredSize({required this.child, required this.onSizeChanged});

  final Widget child;
  final ValueChanged<Size> onSizeChanged;

  @override
  State<_MeasuredSize> createState() => _MeasuredSizeState();
}

class _MeasuredSizeState extends State<_MeasuredSize> {
  Size? _lastSize;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = context.size;
      if (size == null || size == _lastSize) return;
      _lastSize = size;
      widget.onSizeChanged(size);
    });
    return widget.child;
  }
}

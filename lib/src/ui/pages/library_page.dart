import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/app_i18n.dart';
import '../../models/word_entry.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import '../modal_helpers.dart';
import '../ui_copy.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/page_header.dart';
import '../widgets/study_wordbook_status.dart';
import '../widgets/word_row.dart';
import 'follow_along_page.dart';
import 'word_detail_page.dart';
import 'word_editor_page.dart';
import 'wordbook_management_page.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({
    super.key,
    this.onAttachScrollToTop,
    this.isActive = true,
  });

  final ValueChanged<VoidCallback>? onAttachScrollToTop;
  final bool isActive;

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  static const int _pageSize = 20;
  static const int _maxRetainedRowKeys = 240;
  static const int _maxMeasuredRowHeights = 240;
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
  String _loadedWordsSignature = '';
  String _autoScrolledSignature = '';
  List<WordEntry> _loadedWords = const <WordEntry>[];
  late final AppState _appState;

  void _handlePlaybackRevision() {
    if (!mounted || !widget.isActive) {
      return;
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.onAttachScrollToTop?.call(_scrollToTop);
    _scrollController.addListener(_handleScrollChanged);
    _appState = ref.read(appStateProvider);
    _appState.playbackRevisionListenable.addListener(_handlePlaybackRevision);
  }

  @override
  void didUpdateWidget(covariant LibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onAttachScrollToTop != widget.onAttachScrollToTop) {
      widget.onAttachScrollToTop?.call(_scrollToTop);
    }
    if (widget.isActive && !oldWidget.isActive && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _appState.playbackRevisionListenable.removeListener(
      _handlePlaybackRevision,
    );
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
        '${word.wordbookId}|${word.word}|${word.searchMeaningText}|${word.rawContent}';
    return '${word.wordbookId}|${fallbackSeed.hashCode}';
  }

  GlobalKey _rowKeyFor(WordEntry word) {
    final identity = _wordIdentity(word);
    final existing = _rowKeys[identity];
    if (existing != null) return existing;
    final key = GlobalKey(debugLabel: 'library_word_$identity');
    _rowKeys[identity] = key;
    _pruneDetachedRowKeys();
    return key;
  }

  void _syncRowKeys(List<WordEntry> _) {
    // SliverList only builds a small viewport window. Keys are created from
    // the builder, so do not eagerly allocate one for every loaded word.
    _pruneDetachedRowKeys();
  }

  void _pruneDetachedRowKeys() {
    if (_rowKeys.length <= _maxRetainedRowKeys) return;
    final removable = _rowKeys.entries
        .where((entry) => entry.value.currentContext == null)
        .take(_rowKeys.length - _maxRetainedRowKeys)
        .map((entry) => entry.key)
        .toList(growable: false);
    for (final identity in removable) {
      _rowKeys.remove(identity);
      _rowHeights.remove(identity);
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
    while (_rowHeights.length > _maxMeasuredRowHeights) {
      _rowHeights.remove(_rowHeights.keys.first);
    }
  }

  String _buildPaginationSignature(AppState state, int totalWords) {
    final selectedWordbookId = state.selectedWordbook?.id.toString() ?? 'none';
    final searchQuery = state.searchQuery.trim();
    return '$selectedWordbookId|${state.wordsVersion}|'
        '${state.searchMode.name}|$searchQuery|$totalWords';
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
      _rowHeights.clear();
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

  List<WordEntry> _resolveDisplayedWords(AppState state, int totalWords) {
    final limit = totalWords <= 0
        ? 0
        : _visibleItemCount.clamp(0, totalWords).toInt();
    final signature = '$_paginationSignature|limit:$limit';
    if (_loadedWordsSignature == signature) {
      return _loadedWords;
    }
    _loadedWordsSignature = signature;
    _loadedWords = limit <= 0
        ? const <WordEntry>[]
        : state.getVisibleWordsPage(limit: limit, offset: 0);
    return _loadedWords;
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

    // Before any row has been laid out there is no useful anchor to inspect;
    // avoid scanning the entire deferred wordbook just to discover that.
    if (_rowKeys.isEmpty) {
      return listTopOffset + averageExtent * targetIndex;
    }

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
      title: i18n.t('jumpByPrefix'),
      hintText: i18n.t('inline.ui.pages.library_page.type_a_prefix_39793f'),
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
          i18n.t(
            'inline.ui.pages.library_page.no_matching_word_found_in_the_current_scope_2a85d6',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Avoid rebuilding the deferred page and retaining its visible row
    // elements on every global AppState notification while Study is hidden.
    if (!widget.isActive) {
      return const SizedBox.shrink();
    }
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    _syncSearchField(state);

    if (state.selectedWordbook == null) {
      return EmptyStateView(
        icon: Icons.menu_book_rounded,
        title: i18n.t('study.library.empty.no_wordbooks.title'),
        message: i18n.t('noWordbookYet'),
        actionLabel: state.wordbooks.isEmpty
            ? i18n.t('study.wordbook.action.manage')
            : i18n.t('study.wordbook.action.choose'),
        onAction: state.wordbooks.isEmpty
            ? () => _openWordbookManagement()
            : () => showStudyWordbookSheet(
                context: context,
                state: state,
                i18n: i18n,
              ),
      );
    }

    final totalWords = state.visibleWordCount;
    _syncPaginationState(state, totalWords);
    final displayedWords = _resolveDisplayedWords(state, totalWords);
    _syncRowKeys(displayedWords);
    final currentWord = state.currentWord;
    final selectedIdentity = currentWord == null
        ? null
        : _wordIdentity(currentWord);
    _maybeScrollToCurrentWord(state);
    final previewVisible = state.config.showText;
    final searching = state.searchQuery.trim().isNotEmpty;
    final searchLoading = state.wordbookSearchInProgress;
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
                      title: i18n.t(
                        'inline.ui.pages.library_page.search_and_browse_05b156',
                      ),
                      subtitle: i18n.t(
                        'inline.ui.pages.library_page.make_search_switching_and_jumping_first_class_mobile_act_ea67b6',
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
                    StudyWordbookStatusBar(
                      state: state,
                      i18n: i18n,
                      visibleCount: totalWords,
                      searching: searching,
                      currentWordbookEmpty: totalWords <= 0 && !searching,
                      onTap: () {
                        _commitSearchQuery(state, _searchController.text);
                        showStudyWordbookSheet(
                          context: context,
                          state: state,
                          i18n: i18n,
                        );
                      },
                      onLoadCurrent: state.loadSelectedWordbook,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => _onSearchChanged(state, value),
                      onSubmitted: (value) => _commitSearchQuery(state, value),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        hintText: i18n.t(
                          'inline.ui.pages.library_page.search_words_meanings_or_fuzzy_matches_7093f1',
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
                          _searchDebounce?.cancel();
                          state.setSearchCriteria(
                            query: _searchController.text,
                            mode: selection.first,
                          );
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
                                i18n.t('toolbox.sound.piano.quickJump'),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                i18n.t(
                                  'inline.ui.pages.library_page.type_a_prefix_to_jump_directly_to_the_first_matching_wor_fe6295',
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
                                      i18n.t(
                                        'inline.ui.pages.library_page.prefix_jump_7ac67e',
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
                                        i18n.t(
                                          'inline.ui.pages.library_page.clear_search_028a7e',
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
            if (searchLoading)
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: LinearProgressIndicator()),
              )
            else if (totalWords <= 0)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: _buildLibraryEmptyWordsState(
                    context,
                    state,
                    i18n,
                    searching: searching,
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
                            isFavorite: state.isFavoriteEntry(word),
                            isTaskWord: state.isTaskEntry(word),
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
                    i18n.t(
                      'inline.ui.pages.library_page.loaded_displayedwords_length_totalwords_keep_scrolling_t_22d8a6',
                      params: <String, Object?>{
                        'loaded': displayedWords.length,
                        'total': totalWords,
                      },
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
                  tooltip: i18n.t('addWordTitle'),
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
                  label: Text(i18n.t('addWordTitle')),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLibraryEmptyWordsState(
    BuildContext context,
    AppState state,
    AppI18n i18n, {
    required bool searching,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              searching ? Icons.search_off_rounded : Icons.menu_book_outlined,
              size: 36,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              searching
                  ? i18n.t(
                      'inline.ui.pages.library_page.no_matching_words_1e85c1',
                    )
                  : i18n.t('study.library.empty.selected_empty.title'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              searching
                  ? i18n.t('study.library.empty.search_empty.message')
                  : i18n.t('study.library.empty.selected_empty.message'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                if (searching)
                  FilledButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      _commitSearchQuery(state, '');
                    },
                    icon: const Icon(Icons.close_rounded),
                    label: Text(
                      i18n.t(
                        'inline.ui.pages.library_page.clear_search_028a7e',
                      ),
                    ),
                  )
                else
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const WordEditorPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: Text(i18n.t('addWordTitle')),
                  ),
                OutlinedButton.icon(
                  onPressed: () => showStudyWordbookSheet(
                    context: context,
                    state: state,
                    i18n: i18n,
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: Text(i18n.t('study.wordbook.action.switch')),
                ),
                if (!searching)
                  OutlinedButton.icon(
                    onPressed: _openWordbookManagement,
                    icon: const Icon(Icons.library_books_rounded),
                    label: Text(i18n.t('study.wordbook.action.manage')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDetail(AppState state, WordEntry word) async {
    await state.selectWordEntry(word);
    if (!mounted) return;
    final resolvedWord = state.currentWord ?? word;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WordDetailPage(initialWord: resolvedWord),
      ),
    );
  }

  void _openWordbookManagement() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WordbookManagementPage()),
    );
  }

  Future<void> _openFollowAlong(AppState state, WordEntry word) async {
    await state.selectWordEntry(word);
    if (!mounted) return;
    final updatedWord = state.currentWord ?? word;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FollowAlongPage(word: updatedWord),
      ),
    );
  }
}

class _MeasuredSize extends SingleChildRenderObjectWidget {
  const _MeasuredSize({required Widget child, required this.onSizeChanged})
    : super(child: child);

  final ValueChanged<Size> onSizeChanged;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasuredSizeRenderObject(onSizeChanged);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _MeasuredSizeRenderObject renderObject,
  ) {
    renderObject.onSizeChanged = onSizeChanged;
  }
}

class _MeasuredSizeRenderObject extends RenderProxyBox {
  _MeasuredSizeRenderObject(this.onSizeChanged);

  ValueChanged<Size> onSizeChanged;
  Size? _lastSize;

  @override
  void performLayout() {
    super.performLayout();
    final nextSize = size;
    if (nextSize == _lastSize) return;
    _lastSize = nextSize;
    final callback = onSizeChanged;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!attached) return;
      callback(nextSize);
    });
  }
}

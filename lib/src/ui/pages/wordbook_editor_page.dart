import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/word_entry.dart';
import '../../models/wordbook.dart';
import '../../state/app_state.dart';
import '../modal_helpers.dart';
import '../ui_copy.dart';
import '../widgets/empty_state_view.dart';
import '../wordbook_localization.dart';
import 'word_detail_page.dart';
import 'word_editor_page.dart';

enum _WordbookWordAction { edit, delete }

class WordbookEditorPage extends StatefulWidget {
  const WordbookEditorPage({super.key, required this.wordbookId});

  final int wordbookId;

  @override
  State<WordbookEditorPage> createState() => _WordbookEditorPageState();
}

class _WordbookEditorPageState extends State<WordbookEditorPage> {
  final TextEditingController _searchController = TextEditingController();
  SearchMode _searchMode = SearchMode.all;
  bool _selectionRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureSelectedWordbook();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _ensureSelectedWordbook() {
    if (_selectionRequested) return;
    final state = context.read<AppState>();
    if (state.selectedWordbook?.id == widget.wordbookId) return;
    final book = _resolveBook(state);
    if (book == null) return;
    _selectionRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await state.selectWordbook(book);
      if (!mounted) return;
      setState(() {
        _selectionRequested = false;
      });
    });
  }

  Wordbook? _resolveBook(AppState state) {
    for (final book in state.wordbooks) {
      if (book.id == widget.wordbookId) {
        return book;
      }
    }
    final selected = state.selectedWordbook;
    if (selected?.id == widget.wordbookId) {
      return selected;
    }
    return null;
  }

  String _buildWordSubtitle(WordEntry word) {
    return word.listSubtitleText;
  }

  List<WordEntry> _filterWords(List<WordEntry> words) {
    final normalizedQuery = _normalizeSearchText(_searchController.text);
    if (normalizedQuery.isEmpty) return words;
    final fuzzyPattern = _buildFuzzyPattern(normalizedQuery);

    return words
        .where((word) {
          final wordText = _normalizeSearchText(word.word);
          final meaningText = _normalizeSearchText(word.searchMeaningText);
          final detailsText = _normalizeSearchText(word.searchDetailsText);
          final compactWordText = wordText.replaceAll(' ', '');
          final compactDetailsText = detailsText.replaceAll(' ', '');

          switch (_searchMode) {
            case SearchMode.word:
              return wordText.contains(normalizedQuery);
            case SearchMode.meaning:
              return meaningText.contains(normalizedQuery) ||
                  detailsText.contains(normalizedQuery);
            case SearchMode.fuzzy:
              if (fuzzyPattern == null) return false;
              return fuzzyPattern.hasMatch(compactWordText) ||
                  fuzzyPattern.hasMatch(compactDetailsText);
            case SearchMode.all:
              return wordText.contains(normalizedQuery) ||
                  meaningText.contains(normalizedQuery) ||
                  detailsText.contains(normalizedQuery);
          }
        })
        .toList(growable: false);
  }

  String _normalizeSearchText(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  RegExp? _buildFuzzyPattern(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) return null;
    final compact = normalized.replaceAll(' ', '');
    if (compact.isEmpty) return null;
    final escaped = compact.split('').map(RegExp.escape).join('.*');
    return RegExp(escaped, caseSensitive: false);
  }

  Future<void> _openWordDetail(BuildContext context, WordEntry word) async {
    final state = context.read<AppState>();
    await state.selectWordEntry(word);
    if (!context.mounted) return;
    final resolvedWord = state.currentWord ?? word;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WordDetailPage(initialWord: resolvedWord),
      ),
    );
  }

  Future<void> _openWordEditor(BuildContext context, {WordEntry? word}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => WordEditorPage(original: word)),
    );
  }

  Future<void> _deleteWord(
    BuildContext context,
    AppState state,
    AppI18n i18n,
    WordEntry word,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: pickUiText(
        i18n,
        zh: '\u5220\u9664\u8bcd\u6761',
        en: 'Delete word',
      ),
      message: pickUiText(
        i18n,
        zh: '\u5220\u9664\u540e\u65e0\u6cd5\u6062\u590d\uff0c\u786e\u5b9a\u7ee7\u7eed\u5417\uff1f',
        en: 'This cannot be undone. Continue?',
      ),
      danger: true,
      confirmText: pickUiText(i18n, zh: '\u5220\u9664', en: 'Delete'),
    );
    if (!confirmed) return;
    await state.deleteWord(word);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final book = _resolveBook(state);
    final selectionReady = state.selectedWordbook?.id == widget.wordbookId;
    final filteredWords = selectionReady && book != null
        ? _filterWords(state.words)
        : const <WordEntry>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizedWordbookName(
            i18n,
            book,
            placeholder: pickUiText(
              i18n,
              zh: '\u8bcd\u672c\u7f16\u8f91',
              en: 'Wordbook editor',
            ),
          ),
        ),
      ),
      body: book == null
          ? EmptyStateView(
              icon: Icons.menu_book_rounded,
              title: pickUiText(
                i18n,
                zh: '\u8bcd\u672c\u4e0d\u5b58\u5728',
                en: 'Wordbook not found',
              ),
              message: pickUiText(
                i18n,
                zh: '\u8fd9\u4e2a\u8bcd\u672c\u53ef\u80fd\u5df2\u88ab\u5220\u9664\u6216\u91cd\u547d\u540d\u3002',
                en: 'This wordbook may have been deleted or renamed.',
              ),
            )
          : !selectionReady
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            localizedWordbookName(i18n, book),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            pickUiText(
                              i18n,
                              zh: '${filteredWords.length}/${book.wordCount} \u4e2a\u8bcd \u00b7 \u70b9\u51fb\u8bcd\u6761\u53ef\u67e5\u770b\u8be6\u60c5\uff0c\u53f3\u4fa7\u83dc\u5355\u53ef\u76f4\u63a5\u7f16\u8f91\u6216\u5220\u9664',
                              en: '${filteredWords.length}/${book.wordCount} words · tap a row for details, or use the menu to edit and delete directly',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search_rounded),
                              hintText: pickUiText(
                                i18n,
                                zh: '\u641c\u7d22\u8bcd\u5f62\u3001\u91ca\u4e49\u6216\u6a21\u7cca\u5339\u914d',
                                en: 'Search by word, meaning, or fuzzy match',
                              ),
                              suffixIcon: _searchController.text.trim().isEmpty
                                  ? null
                                  : IconButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
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
                              selected: <SearchMode>{_searchMode},
                              onSelectionChanged: (selection) {
                                if (selection.isEmpty) return;
                                setState(() {
                                  _searchMode = selection.first;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filteredWords.isEmpty
                      ? EmptyStateView(
                          icon: Icons.search_off_rounded,
                          title: pickUiText(
                            i18n,
                            zh: _searchController.text.trim().isEmpty
                                ? '\u8fd8\u6ca1\u6709\u8bcd\u6761'
                                : '\u6ca1\u627e\u5230\u5339\u914d\u7684\u8bcd\u6761',
                            en: _searchController.text.trim().isEmpty
                                ? 'No words yet'
                                : 'No matching words',
                          ),
                          message: pickUiText(
                            i18n,
                            zh: _searchController.text.trim().isEmpty
                                ? '\u53ef\u4ee5\u76f4\u63a5\u65b0\u589e\u8bcd\u6761\uff0c\u6216\u8005\u5148\u5bfc\u5165\u5185\u5bb9\u518d\u56de\u6765\u7f16\u8f91\u3002'
                                : '\u53ef\u4ee5\u8bd5\u8bd5\u66f4\u77ed\u7684\u5173\u952e\u8bcd\uff0c\u6216\u5207\u6362\u68c0\u7d22\u6a21\u5f0f\u3002',
                            en: _searchController.text.trim().isEmpty
                                ? 'Add a word directly, or import content and come back to edit it here.'
                                : 'Try a shorter query or switch the search mode.',
                          ),
                          actionLabel: _searchController.text.trim().isEmpty
                              ? pickUiText(
                                  i18n,
                                  zh: '\u65b0\u589e\u8bcd\u6761',
                                  en: 'Add word',
                                )
                              : null,
                          onAction: _searchController.text.trim().isEmpty
                              ? () => _openWordEditor(context)
                              : null,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: filteredWords.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final word = filteredWords[index];
                            final subtitle = _buildWordSubtitle(word);
                            return Card(
                              child: ListTile(
                                title: Text(word.word),
                                subtitle: subtitle.isEmpty
                                    ? null
                                    : Text(
                                        subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                onTap: () => _openWordDetail(context, word),
                                trailing: PopupMenuButton<_WordbookWordAction>(
                                  onSelected: (action) async {
                                    switch (action) {
                                      case _WordbookWordAction.edit:
                                        await _openWordEditor(
                                          context,
                                          word: word,
                                        );
                                      case _WordbookWordAction.delete:
                                        await _deleteWord(
                                          context,
                                          state,
                                          i18n,
                                          word,
                                        );
                                    }
                                  },
                                  itemBuilder: (context) =>
                                      <PopupMenuEntry<_WordbookWordAction>>[
                                        PopupMenuItem<_WordbookWordAction>(
                                          value: _WordbookWordAction.edit,
                                          child: Text(
                                            pickUiText(
                                              i18n,
                                              zh: '\u7f16\u8f91',
                                              en: 'Edit',
                                            ),
                                          ),
                                        ),
                                        PopupMenuItem<_WordbookWordAction>(
                                          value: _WordbookWordAction.delete,
                                          child: Text(
                                            pickUiText(
                                              i18n,
                                              zh: '\u5220\u9664',
                                              en: 'Delete',
                                            ),
                                          ),
                                        ),
                                      ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: book == null || !selectionReady
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openWordEditor(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                pickUiText(
                  i18n,
                  zh: '\u65b0\u589e\u8bcd\u6761',
                  en: 'Add word',
                ),
              ),
            ),
    );
  }
}

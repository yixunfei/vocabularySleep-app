import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/app_i18n.dart';
import '../../models/word_entry.dart';
import '../../models/wordbook.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import '../modal_helpers.dart';
import '../ui_copy.dart';
import '../widgets/empty_state_view.dart';
import '../wordbook_localization.dart';
import 'word_detail_page.dart';
import 'word_editor_page.dart';

enum _WordbookWordAction { edit, delete }

class WordbookEditorPage extends ConsumerStatefulWidget {
  const WordbookEditorPage({super.key, required this.wordbookId});

  final int wordbookId;

  @override
  ConsumerState<WordbookEditorPage> createState() => _WordbookEditorPageState();
}

class _WordbookEditorPageState extends ConsumerState<WordbookEditorPage> {
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
    final state = ref.read(appStateProvider);
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
    final state = ref.read(appStateProvider);
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
      title: i18n.t('inline.ui.pages.word_detail_page.delete_word_5cf638'),
      message: i18n.t(
        'inline.ui.pages.word_detail_page.this_cannot_be_undone_continue_887e94',
      ),
      danger: true,
      confirmText: i18n.t('delete'),
    );
    if (!confirmed) return;
    await state.deleteWord(word);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
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
            placeholder: i18n.t(
              'inline.ui.pages.wordbook_editor_page.wordbook_editor_6acfd5',
            ),
          ),
        ),
      ),
      body: book == null
          ? EmptyStateView(
              icon: Icons.menu_book_rounded,
              title: i18n.t(
                'inline.ui.pages.wordbook_editor_page.wordbook_not_found_d0c5b6',
              ),
              message: i18n.t(
                'inline.ui.pages.wordbook_editor_page.this_wordbook_may_have_been_deleted_or_renamed_9b14c0',
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
                            i18n.t(
                              'inline.ui.pages.wordbook_editor_page.filteredwords_length_book_wordcount_words_tap_a_row_for_0f25b3',
                              params: <String, Object?>{
                                'filtered': filteredWords.length,
                                'total': book.wordCount,
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search_rounded),
                              hintText: i18n.t(
                                'inline.ui.pages.wordbook_editor_page.search_by_word_meaning_or_fuzzy_match_954f5f',
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
                          title: i18n.t(
                            _searchController.text.trim().isEmpty
                                ? 'wordbookEditor.empty.noWordsTitle'
                                : 'wordbookEditor.empty.noMatchesTitle',
                          ),
                          message: i18n.t(
                            _searchController.text.trim().isEmpty
                                ? 'wordbookEditor.empty.noWordsMessage'
                                : 'wordbookEditor.empty.noMatchesMessage',
                          ),
                          actionLabel: _searchController.text.trim().isEmpty
                              ? i18n.t('addWordTitle')
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
                                          child: Text(i18n.t('edit')),
                                        ),
                                        PopupMenuItem<_WordbookWordAction>(
                                          value: _WordbookWordAction.delete,
                                          child: Text(i18n.t('delete')),
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
              label: Text(i18n.t('addWordTitle')),
            ),
    );
  }
}

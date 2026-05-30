import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/app_i18n.dart';
import '../../models/word_entry.dart';
import '../../services/app_log_service.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import '../modal_helpers.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';
import '../widgets/word_card.dart';
import '../widgets/word_detail_sections.dart';
import 'follow_along_page.dart';
import 'word_editor_page.dart';

class WordDetailPage extends ConsumerStatefulWidget {
  const WordDetailPage({super.key, required this.initialWord});

  final WordEntry initialWord;

  @override
  ConsumerState<WordDetailPage> createState() => _WordDetailPageState();
}

class _WordDetailPageState extends ConsumerState<WordDetailPage> {
  int _transitionDirection = 1;

  static const double _contentMaxWidth = 600;

  void _setTransitionDirection(int direction) {
    if (_transitionDirection == direction) return;
    setState(() {
      _transitionDirection = direction;
    });
  }

  int _indexOfWord(List<WordEntry> words, WordEntry target) {
    for (var index = 0; index < words.length; index += 1) {
      final item = words[index];
      if (item.sameEntryAs(target)) {
        return index;
      }
    }
    return words.indexWhere(
      (item) => item.sameEntryAs(target, ignoreWordbook: true),
    );
  }

  WordEntry? _resolveWord(AppState state) {
    final current = state.currentWord;
    if (current != null &&
        current.wordbookId == widget.initialWord.wordbookId &&
        _indexOfWord(state.words, current) >= 0) {
      return current;
    }

    final exactId = widget.initialWord.id;
    if (exactId != null) {
      for (final item in state.words) {
        if (item.id == exactId) return item;
      }
    }

    for (final item in state.words) {
      if (item.sameEntryAs(widget.initialWord, ignoreWordbook: true)) {
        return item;
      }
    }
    final fallback = state.currentWord;
    if (fallback != null &&
        fallback.wordbookId == widget.initialWord.wordbookId) {
      return fallback;
    }
    return widget.initialWord;
  }

  Future<void> _moveToWord(
    AppState state, {
    required List<WordEntry> visibleWords,
    required int currentIndex,
    required int offset,
  }) async {
    if (visibleWords.isEmpty) return;
    _setTransitionDirection(offset >= 0 ? 1 : -1);
    final safeIndex = currentIndex < 0 ? 0 : currentIndex;
    final nextIndex =
        (safeIndex + offset + visibleWords.length) % visibleWords.length;
    await state.selectWordEntry(visibleWords[nextIndex]);
  }

  Future<void> _openFollowAlong(
    BuildContext context,
    AppState state,
    WordEntry word,
  ) async {
    await state.selectWordEntry(word);
    if (!context.mounted) return;
    final updatedWord = state.currentWord ?? word;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FollowAlongPage(word: updatedWord),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    final word = _resolveWord(state);
    if (word == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            i18n.t(
              'inline.ui.pages.word_detail_page.this_word_no_longer_exists_c471c1',
            ),
          ),
        ),
      );
    }

    AppLogService.instance.d(
      'word_detail',
      'Displaying word details',
      data: <String, Object?>{
        'word': word.word,
        'wordId': word.id,
        'wordbookId': word.wordbookId,
        'meaning': word.displayMeaning,
        'meaningLength': word.displayMeaning.length,
        'rawContent': word.rawContent,
        'rawContentLength': word.rawContent.length,
        'rawContentHasNewlines': word.rawContent.contains('\n'),
        'rawContentHasDoubleNewlines': word.rawContent.contains('\n\n'),
        'rawContentFirst200': word.rawContent.length > 200
            ? word.rawContent.substring(0, 200)
            : word.rawContent,
        'fields': word.fields.map((f) => f.toJsonMap()).toList(),
        'fieldsCount': word.fields.length,
        'groupedFields': word.groupedFields
            .map(
              (group) => <String, Object?>{
                'groupKey': group.groupKey,
                'count': group.fields.length,
              },
            )
            .toList(growable: false),
        'entryUid': word.entryUid,
        'schemaVersion': word.schemaVersion,
        'primaryGloss': word.primaryGloss,
      },
    );

    final groupedFields = word.groupedFields;
    final visibleWords = state.visibleWords;
    final currentIndex = _indexOfWord(visibleWords, word);

    return Scaffold(
      appBar: AppBar(
        title: Text(word.word),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              state.updateConfig(
                state.config.copyWith(showText: !state.config.showText),
              );
            },
            icon: Icon(
              state.config.showText
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
            ),
            tooltip: i18n.t('showText'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'edit':
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => WordEditorPage(original: word),
                    ),
                  );
                case 'delete':
                  final confirmed = await showConfirmDialog(
                    context: context,
                    title: i18n.t(
                      'inline.ui.pages.word_detail_page.delete_word_5cf638',
                    ),
                    message: i18n.t(
                      'inline.ui.pages.word_detail_page.this_cannot_be_undone_continue_887e94',
                    ),
                    danger: true,
                  );
                  if (!confirmed) return;
                  await state.deleteWord(word);
                  if (context.mounted) Navigator.of(context).pop();
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem(value: 'edit', child: Text(i18n.t('edit'))),
              PopupMenuItem(value: 'delete', child: Text(i18n.t('delete'))),
            ],
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              WordCard(
                word: word,
                i18n: i18n,
                density: WordCardDensity.immersive,
                transitionStyle: state.config.wordPageTransitionStyle,
                transitionDirection: _transitionDirection,
                showMeaning: state.config.showText,
                showFields: state.config.showText,
                isFavorite: state.isFavoriteEntry(word),
                isTaskWord: state.isTaskEntry(word),
                onToggleFavorite: () => state.toggleFavorite(word),
                onToggleTask: () => state.toggleTaskWord(word),
                onPlayPronunciation: () =>
                    state.previewPronunciation(word.word),
                onFollowAlong: () => _openFollowAlong(context, state, word),
                onPreviousWord: visibleWords.length <= 1
                    ? null
                    : () => _moveToWord(
                        state,
                        visibleWords: visibleWords,
                        currentIndex: currentIndex,
                        offset: -1,
                      ),
                onNextWord: visibleWords.length <= 1
                    ? null
                    : () => _moveToWord(
                        state,
                        visibleWords: visibleWords,
                        currentIndex: currentIndex,
                        offset: 1,
                      ),
                onSwipePrevious: visibleWords.length <= 1
                    ? null
                    : () => _moveToWord(
                        state,
                        visibleWords: visibleWords,
                        currentIndex: currentIndex,
                        offset: -1,
                      ),
                onSwipeNext: visibleWords.length <= 1
                    ? null
                    : () => _moveToWord(
                        state,
                        visibleWords: visibleWords,
                        currentIndex: currentIndex,
                        offset: 1,
                      ),
              ),
              const SizedBox(height: 16),
              if (state.config.showText) ...<Widget>[
                KeyedSubtree(
                  key: ValueKey<String>('detail:${word.stableIdentityKey}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      WordDetailOverviewCard(
                        i18n: i18n,
                        word: word,
                        groupedFields: groupedFields,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SectionHeader(
                                title: i18n.t(
                                  'inline.ui.pages.word_detail_page.field_details_8215f0',
                                ),
                                subtitle: i18n.t(
                                  'inline.ui.pages.word_detail_page.fields_are_grouped_into_core_usage_linguistics_memory_an_f4a863',
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (groupedFields.isEmpty)
                                Text(
                                  i18n.t(
                                    'inline.ui.pages.word_detail_page.no_structured_fields_are_available_right_now_so_the_card_43714b',
                                  ),
                                )
                              else
                                for (final group in groupedFields) ...<Widget>[
                                  WordFieldGroupCard(
                                    key: ValueKey<String>(
                                      '${word.stableIdentityKey}:${group.groupKey}',
                                    ),
                                    i18n: i18n,
                                    group: group,
                                  ),
                                  if (group != groupedFields.last)
                                    const SizedBox(height: 12),
                                ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          i18n.t(
                            'inline.ui.pages.word_detail_page.text_is_hidden_262961',
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          i18n.t(
                            'inline.ui.pages.word_detail_page.use_the_visibility_button_in_the_top_bar_to_reveal_meani_acc3a4',
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: () {
                            state.updateConfig(
                              state.config.copyWith(showText: true),
                            );
                          },
                          icon: const Icon(Icons.visibility_rounded),
                          label: Text(i18n.t('showText')),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

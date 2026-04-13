import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/word_entry.dart';
import '../../services/app_log_service.dart';
import '../../state/app_state.dart';
import '../modal_helpers.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';
import '../widgets/word_card.dart';
import '../widgets/word_detail_sections.dart';
import 'follow_along_page.dart';
import 'word_editor_page.dart';

class WordDetailPage extends StatefulWidget {
  const WordDetailPage({super.key, required this.initialWord});

  final WordEntry initialWord;

  @override
  State<WordDetailPage> createState() => _WordDetailPageState();
}

class _WordDetailPageState extends State<WordDetailPage> {
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
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final word = _resolveWord(state);
    if (word == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            pickUiText(
              i18n,
              zh: '这个词条已经不存在了',
              en: 'This word no longer exists.',
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
                    title: pickUiText(i18n, zh: '删除词条', en: 'Delete word'),
                    message: pickUiText(
                      i18n,
                      zh: '删除后无法恢复，确定继续吗？',
                      en: 'This cannot be undone. Continue?',
                    ),
                    danger: true,
                  );
                  if (!confirmed) return;
                  await state.deleteWord(word);
                  if (context.mounted) Navigator.of(context).pop();
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem(
                value: 'edit',
                child: Text(pickUiText(i18n, zh: '编辑', en: 'Edit')),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(pickUiText(i18n, zh: '删除', en: 'Delete')),
              ),
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
                                title: pickUiText(
                                  i18n,
                                  zh: '字段详情',
                                  en: 'Field details',
                                ),
                                subtitle: pickUiText(
                                  i18n,
                                  zh: '按核心、用法、语言学、记忆与其他分组展示；长内容支持折叠，避免移动端一屏信息冲突。',
                                  en: 'Fields are grouped into core, usage, linguistics, memory, and other sections, with long text collapsed for mobile readability.',
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (groupedFields.isEmpty)
                                Text(
                                  pickUiText(
                                    i18n,
                                    zh: '当前没有可展示的结构化字段，已回退到词卡摘要视图。',
                                    en: 'No structured fields are available right now, so the card summary is used as the fallback view.',
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
                          pickUiText(i18n, zh: '文本当前已隐藏', en: 'Text is hidden'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pickUiText(
                            i18n,
                            zh: '点击右上角的可见性按钮，可以重新显示释义和字段内容。',
                            en: 'Use the visibility button in the top bar to reveal meanings and field content again.',
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
                          label: Text(
                            pickUiText(i18n, zh: '显示文本', en: 'Show text'),
                          ),
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

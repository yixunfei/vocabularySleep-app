import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/word_entry.dart';
import '../../models/word_field.dart';
import '../../services/app_log_service.dart';
import '../../state/app_state.dart';
import '../modal_helpers.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';
import '../widgets/word_card.dart';
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

  void _setTransitionDirection(int direction) {
    if (_transitionDirection == direction) return;
    setState(() {
      _transitionDirection = direction;
    });
  }

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
      if (item.word == widget.initialWord.word) return item;
    }
    final fallback = state.currentWord;
    if (fallback != null &&
        fallback.wordbookId == widget.initialWord.wordbookId) {
      return fallback;
    }
    return widget.initialWord;
  }

  void _moveToWord(
    AppState state, {
    required List<WordEntry> visibleWords,
    required int currentIndex,
    required int offset,
  }) {
    if (visibleWords.isEmpty) return;
    _setTransitionDirection(offset >= 0 ? 1 : -1);
    final safeIndex = currentIndex < 0 ? 0 : currentIndex;
    final nextIndex =
        (safeIndex + offset + visibleWords.length) % visibleWords.length;
    state.selectWordEntry(visibleWords[nextIndex]);
  }

  Future<void> _openFollowAlong(
    BuildContext context,
    AppState state,
    WordEntry word,
  ) async {
    final updatedWord = state.currentWord ?? word;
    state.selectWordEntry(updatedWord);
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
        'meaning': word.meaning,
        'meaningLength': word.meaning?.length ?? 0,
        'rawContent': word.rawContent,
        'rawContentLength': word.rawContent.length,
        'rawContentHasNewlines': word.rawContent.contains('\n'),
        'rawContentHasDoubleNewlines': word.rawContent.contains('\n\n'),
        'rawContentFirst200': word.rawContent.length > 200
            ? word.rawContent.substring(0, 200)
            : word.rawContent,
        'fields': word.fields.map((f) => f.toJsonMap()).toList(),
        'fieldsCount': word.fields.length,
        'legacyFields': <String, Object?>{
          'examples': word.examples,
          'examplesCount': word.examples?.length ?? 0,
          'etymology': word.etymology,
          'roots': word.roots,
          'affixes': word.affixes,
          'variations': word.variations,
          'memory': word.memory,
          'story': word.story,
        },
      },
    );

    final fields = word.fields.isNotEmpty
        ? word.fields
        : buildFieldItemsFromRecord(<String, Object?>{
            'meaning': word.meaning,
            'examples': word.examples,
            'etymology': word.etymology,
            'roots': word.roots,
            'affixes': word.affixes,
            'variations': word.variations,
            'memory': word.memory,
            'story': word.story,
          });
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
      body: ListView(
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
            isFavorite: state.favorites.contains(word.word),
            isTaskWord: state.taskWords.contains(word.word),
            onToggleFavorite: () => state.toggleFavorite(word),
            onToggleTask: () => state.toggleTaskWord(word),
            onPlayPronunciation: () => state.previewPronunciation(word.word),
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
          if (state.config.showText)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SectionHeader(
                      title: pickUiText(i18n, zh: '全部字段', en: 'All fields'),
                      subtitle: pickUiText(
                        i18n,
                        zh: '阅读态默认展示，管理操作收在右上角菜单',
                        en: 'Reading stays primary; management moves into the overflow menu.',
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final field in fields) ...<Widget>[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              localizedFieldLabel(i18n, field),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(field.asText()),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '文本当前已隐藏',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('点击右上角的可见性按钮，可以重新显示释义和字段内容。'),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () {
                        state.updateConfig(
                          state.config.copyWith(showText: true),
                        );
                      },
                      icon: const Icon(Icons.visibility_rounded),
                      label: const Text('显示文本'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

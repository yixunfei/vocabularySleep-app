import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/word_entry.dart';
import '../../models/word_field.dart';
import '../../state/app_state.dart';
import '../modal_helpers.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';
import '../widgets/word_card.dart';
import 'follow_along_page.dart';
import 'word_editor_page.dart';

class WordDetailPage extends StatelessWidget {
  const WordDetailPage({super.key, required this.initialWord});

  final WordEntry initialWord;

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
              zh: '\u8fd9\u4e2a\u8bcd\u6761\u5df2\u7ecf\u4e0d\u5b58\u5728\u4e86',
              en: 'This word no longer exists.',
            ),
          ),
        ),
      );
    }

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
                  );
                  if (!confirmed) return;
                  await state.deleteWord(word);
                  if (context.mounted) Navigator.of(context).pop();
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem(
                value: 'edit',
                child: Text(pickUiText(i18n, zh: '\u7f16\u8f91', en: 'Edit')),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(pickUiText(i18n, zh: '\u5220\u9664', en: 'Delete')),
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
            showMeaning: state.config.showText,
            showFields: state.config.showText,
            isFavorite: state.favorites.contains(word.word),
            isTaskWord: state.taskWords.contains(word.word),
            onToggleFavorite: () => state.toggleFavorite(word),
            onToggleTask: () => state.toggleTaskWord(word),
            onPlayPronunciation: () => state.previewPronunciation(word.word),
            onFollowAlong: () => _openFollowAlong(context, state, word),
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
                      title: pickUiText(
                        i18n,
                        zh: '\u5168\u90e8\u5b57\u6bb5',
                        en: 'All fields',
                      ),
                      subtitle: pickUiText(
                        i18n,
                        zh: '\u9605\u8bfb\u6001\u9ed8\u8ba4\u5c55\u793a\uff0c\u7ba1\u7406\u64cd\u4f5c\u6536\u5165\u53f3\u4e0a\u89d2\u83dc\u5355',
                        en: 'Reading stays primary; management moves into the overflow menu.',
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final field in fields) ...[
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
                      '\u6587\u672c\u5f53\u524d\u5df2\u9690\u85cf',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\u70b9\u51fb\u53f3\u4e0a\u89d2\u7684\u53ef\u89c1\u6027\u6309\u94ae\uff0c\u53ef\u4ee5\u91cd\u65b0\u663e\u793a\u91ca\u4e49\u548c\u5b57\u6bb5\u5185\u5bb9\u3002',
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () {
                        state.updateConfig(
                          state.config.copyWith(showText: true),
                        );
                      },
                      icon: const Icon(Icons.visibility_rounded),
                      label: const Text('\u663e\u793a\u6587\u672c'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  WordEntry? _resolveWord(AppState state) {
    final exactId = initialWord.id;
    if (exactId != null) {
      for (final item in state.words) {
        if (item.id == exactId) return item;
      }
    }
    for (final item in state.words) {
      if (item.word == initialWord.word) return item;
    }
    return state.currentWord;
  }

  Future<void> _openFollowAlong(
    BuildContext context,
    AppState state,
    WordEntry word,
  ) async {
    state.selectWordEntry(word);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => FollowAlongPage(word: word)),
    );
  }
}

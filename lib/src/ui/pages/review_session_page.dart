import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/word_entry.dart';
import '../../state/app_state.dart';
import '../ui_copy.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/page_header.dart';
import '../widgets/word_row.dart';
import 'follow_along_page.dart';
import 'practice_session_page.dart';

class ReviewSessionPage extends StatelessWidget {
  const ReviewSessionPage({
    super.key,
    required this.title,
    required this.words,
    this.subtitle,
  });

  final String title;
  final List<WordEntry> words;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    if (words.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: EmptyStateView(
          icon: Icons.assignment_turned_in_outlined,
          title: pickUiText(i18n, zh: '当前没有可复习词', en: 'No words to review'),
          message: pickUiText(
            i18n,
            zh: '可以先在词库中加入任务词或收藏词，再回来开始会话。',
            en: 'Add task or favorite words in Library, then come back here.',
          ),
        ),
      );
    }

    final previewWords = words.take(20).toList(growable: false);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          PageHeader(
            eyebrow: pickUiText(i18n, zh: '复习会话', en: 'Review session'),
            title: title,
            subtitle:
                subtitle ??
                pickUiText(
                  i18n,
                  zh: '共 ${words.length} 个词，开始前可先预览一部分词条。',
                  en: '${words.length} words. Preview a subset before starting.',
                ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: () => _openPractice(
                      context,
                      title: title,
                      words: words,
                      subtitle: subtitle,
                      shuffle: false,
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(pickUiText(i18n, zh: '顺序开始', en: 'Start')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openPractice(
                      context,
                      title: title,
                      words: words,
                      subtitle: subtitle,
                      shuffle: true,
                    ),
                    icon: const Icon(Icons.shuffle_rounded),
                    label: Text(
                      pickUiText(i18n, zh: '随机练习', en: 'Shuffle start'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final word in previewWords) ...[
            WordRow(
              word: word,
              i18n: i18n,
              selected: false,
              showMeaning: state.config.showText,
              showFields: state.config.showText,
              isFavorite: state.favorites.contains(word.word),
              isTaskWord: state.taskWords.contains(word.word),
              onTap: () => state.selectWordEntry(word),
              onPlay: () => state.previewPronunciation(word.word),
              onFollowAlong: () => _openFollowAlong(context, state, word),
              onToggleFavorite: () => state.toggleFavorite(word),
              onToggleTask: () => state.toggleTaskWord(word),
            ),
            const SizedBox(height: 10),
          ],
          if (words.length > previewWords.length)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                pickUiText(
                  i18n,
                  zh: '仅预览前 ${previewWords.length} 个词，开始会话可覆盖全部。',
                  en: 'Showing first ${previewWords.length} words. The session covers all.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openPractice(
    BuildContext context, {
    required String title,
    required List<WordEntry> words,
    String? subtitle,
    required bool shuffle,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticeSessionPage(
          title: title,
          words: words,
          subtitle: subtitle,
          shuffle: shuffle,
        ),
      ),
    );
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

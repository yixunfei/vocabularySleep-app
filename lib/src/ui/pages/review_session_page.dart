import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../models/word_entry.dart';
import '../../models/word_memory_progress.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import '../module/module_access.dart';
import '../ui_copy.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/page_header.dart';
import '../widgets/word_row.dart';
import 'follow_along_page.dart';
import 'practice_session_page.dart';

enum _ReviewOrder { source, dueFirst, weakFirst, alphabetical }

class ReviewSessionPage extends ConsumerStatefulWidget {
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
  ConsumerState<ReviewSessionPage> createState() => _ReviewSessionPageState();
}

class _ReviewSessionPageState extends ConsumerState<ReviewSessionPage> {
  _ReviewOrder _order = _ReviewOrder.source;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    if (!state.isModuleEnabled(ModuleIds.practice)) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: ModuleDisabledView(i18n: i18n, moduleId: ModuleIds.practice),
      );
    }
    if (widget.words.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
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

    final orderedWords = _orderedWords(state, widget.words);
    final previewWords = orderedWords.take(20).toList(growable: false);
    final now = DateTime.now();
    final dueCount = orderedWords
        .where((word) => _isDue(state.memoryProgressForWordEntry(word), now))
        .length;
    final trackedCount = orderedWords
        .where(
          (word) =>
              (state.memoryProgressForWordEntry(word)?.timesPlayed ?? 0) > 0,
        )
        .length;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          PageHeader(
            eyebrow: pickUiText(i18n, zh: '复习会话', en: 'Review session'),
            title: widget.title,
            subtitle:
                widget.subtitle ??
                pickUiText(
                  i18n,
                  zh: '共 ${widget.words.length} 个词，开始前可先预览一部分词条。',
                  en: '${widget.words.length} words. Preview a subset before starting.',
                ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickUiText(i18n, zh: '复习顺序', en: 'Review order'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _ReviewOrder.values
                        .map(
                          (order) => ChoiceChip(
                            label: Text(_orderLabel(i18n, order)),
                            selected: _order == order,
                            onSelected: (selected) {
                              if (!selected) return;
                              setState(() {
                                _order = order;
                              });
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      _buildStatChip(
                        context,
                        icon: Icons.library_books_rounded,
                        value: '${orderedWords.length}',
                        label: pickUiText(i18n, zh: '本次词数', en: 'Words'),
                      ),
                      _buildStatChip(
                        context,
                        icon: Icons.schedule_rounded,
                        value: '$dueCount',
                        label: pickUiText(i18n, zh: '待复习', en: 'Due now'),
                      ),
                      _buildStatChip(
                        context,
                        icon: Icons.query_stats_rounded,
                        value: '$trackedCount',
                        label: pickUiText(i18n, zh: '已有记录', en: 'Tracked'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: () => _openPractice(
                          context,
                          title: widget.title,
                          words: orderedWords,
                          subtitle: widget.subtitle,
                          shuffle: false,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          pickUiText(i18n, zh: '按当前顺序开始', en: 'Start review'),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _openPractice(
                          context,
                          title: widget.title,
                          words: orderedWords,
                          subtitle: widget.subtitle,
                          shuffle: true,
                        ),
                        icon: const Icon(Icons.shuffle_rounded),
                        label: Text(
                          pickUiText(i18n, zh: '随机练习', en: 'Shuffle start'),
                        ),
                      ),
                    ],
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
              isFavorite: state.isFavoriteEntry(word),
              isTaskWord: state.isTaskEntry(word),
              onTap: () => state.selectWordEntry(word),
              onPlay: () => state.previewPronunciation(word.word),
              onFollowAlong: () => _openFollowAlong(context, state, word),
              onToggleFavorite: () => state.toggleFavorite(word),
              onToggleTask: () => state.toggleTaskWord(word),
            ),
            const SizedBox(height: 10),
          ],
          if (orderedWords.length > previewWords.length)
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

  List<WordEntry> _orderedWords(AppState state, List<WordEntry> source) {
    if (source.length <= 1) {
      return source;
    }

    final ordered = List<WordEntry>.from(source);
    final sourceIndex = <String, int>{
      for (var index = 0; index < source.length; index += 1)
        _entryKey(source[index]): index,
    };
    final now = DateTime.now();

    int compareBySource(WordEntry left, WordEntry right) {
      final leftIndex = sourceIndex[_entryKey(left)] ?? source.length;
      final rightIndex = sourceIndex[_entryKey(right)] ?? source.length;
      return leftIndex.compareTo(rightIndex);
    }

    int compareByDue(WordEntry left, WordEntry right) {
      final leftProgress = state.memoryProgressForWordEntry(left);
      final rightProgress = state.memoryProgressForWordEntry(right);
      final leftDue = _isDue(leftProgress, now);
      final rightDue = _isDue(rightProgress, now);
      if (leftDue != rightDue) {
        return leftDue ? -1 : 1;
      }

      final leftNext = leftProgress?.nextReview;
      final rightNext = rightProgress?.nextReview;
      if (leftNext == null && rightNext != null) {
        return -1;
      }
      if (leftNext != null && rightNext == null) {
        return 1;
      }
      if (leftNext != null && rightNext != null) {
        final nextOrder = leftNext.compareTo(rightNext);
        if (nextOrder != 0) {
          return nextOrder;
        }
      }

      return compareBySource(left, right);
    }

    int compareByWeakness(WordEntry left, WordEntry right) {
      final leftProgress = state.memoryProgressForWordEntry(left);
      final rightProgress = state.memoryProgressForWordEntry(right);
      final accuracyOrder = _accuracy(
        leftProgress,
      ).compareTo(_accuracy(rightProgress));
      if (accuracyOrder != 0) {
        return accuracyOrder;
      }

      final leftPlayed = leftProgress?.timesPlayed ?? 0;
      final rightPlayed = rightProgress?.timesPlayed ?? 0;
      if (leftPlayed != rightPlayed) {
        return rightPlayed.compareTo(leftPlayed);
      }

      return compareByDue(left, right);
    }

    switch (_order) {
      case _ReviewOrder.source:
        return ordered;
      case _ReviewOrder.dueFirst:
        ordered.sort(compareByDue);
        return ordered;
      case _ReviewOrder.weakFirst:
        ordered.sort(compareByWeakness);
        return ordered;
      case _ReviewOrder.alphabetical:
        ordered.sort(
          (left, right) =>
              left.word.toLowerCase().compareTo(right.word.toLowerCase()),
        );
        return ordered;
    }
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(value, style: theme.textTheme.titleMedium),
                Text(label, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _orderLabel(AppI18n i18n, _ReviewOrder order) {
    return switch (order) {
      _ReviewOrder.source => pickUiText(i18n, zh: '原始顺序', en: 'Source order'),
      _ReviewOrder.dueFirst => pickUiText(i18n, zh: '到期优先', en: 'Due first'),
      _ReviewOrder.weakFirst => pickUiText(i18n, zh: '薄弱优先', en: 'Weak first'),
      _ReviewOrder.alphabetical => pickUiText(i18n, zh: '字母顺序', en: 'A-Z'),
    };
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
    await state.selectWordEntry(word);
    if (!context.mounted) return;
    final resolvedWord = state.currentWord ?? word;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FollowAlongPage(word: resolvedWord),
      ),
    );
  }

  bool _isDue(WordMemoryProgress? progress, DateTime now) {
    final nextReview = progress?.nextReview;
    if (nextReview == null) {
      return true;
    }
    return !nextReview.isAfter(now);
  }

  double _accuracy(WordMemoryProgress? progress) {
    if (progress == null || progress.timesPlayed <= 0) {
      return 0;
    }
    return (progress.timesCorrect / progress.timesPlayed).clamp(0.0, 1.0);
  }

  String _entryKey(WordEntry entry) {
    final id = entry.id;
    if (id != null && id > 0) {
      return 'id:$id';
    }
    return 'wordbook:${entry.wordbookId}:${entry.word.trim().toLowerCase()}';
  }
}

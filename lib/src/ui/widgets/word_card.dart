import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../../models/word_entry.dart';
import '../../models/word_field.dart';
import '../theme/app_theme.dart';
import '../ui_copy.dart';
import 'status_badge.dart';

enum WordCardDensity { immersive, compact, practice }

class WordCard extends StatelessWidget {
  const WordCard({
    super.key,
    required this.word,
    required this.i18n,
    this.density = WordCardDensity.immersive,
    this.showMeaning = true,
    this.showFields = true,
    this.revealPracticeAnswer = true,
    this.isFavorite = false,
    this.isTaskWord = false,
    this.onToggleFavorite,
    this.onToggleTask,
    this.onPlayPronunciation,
    this.onFollowAlong,
    this.onPreviousWord,
    this.onNextWord,
    this.onSwipePrevious,
    this.onSwipeNext,
    this.footer,
  });

  final WordEntry word;
  final AppI18n i18n;
  final WordCardDensity density;
  final bool showMeaning;
  final bool showFields;
  final bool revealPracticeAnswer;
  final bool isFavorite;
  final bool isTaskWord;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onToggleTask;
  final VoidCallback? onPlayPronunciation;
  final VoidCallback? onFollowAlong;
  final VoidCallback? onPreviousWord;
  final VoidCallback? onNextWord;
  final VoidCallback? onSwipePrevious;
  final VoidCallback? onSwipeNext;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppThemeTokens.of(context);
    final fields = _displayFields(word);
    final meaning = fields
        .where((item) => item.key == 'meaning')
        .cast<WordFieldItem?>()
        .firstOrNull;
    final examples = fields
        .where((item) => item.key == 'examples')
        .cast<WordFieldItem?>()
        .firstOrNull;
    final titleStyle = switch (density) {
      WordCardDensity.compact => theme.textTheme.titleLarge,
      WordCardDensity.practice => theme.textTheme.headlineSmall,
      WordCardDensity.immersive => theme.textTheme.headlineLarge,
    };

    final canReveal =
        density != WordCardDensity.practice || revealPracticeAnswer;
    final visibleMeaning = showMeaning && canReveal
        ? meaning?.asText() ?? ''
        : '';
    final visibleExamples = showFields && canReveal
        ? (examples?.asList() ?? const <String>[])
        : const <String>[];
    final enableWordSwipe = onSwipePrevious != null || onSwipeNext != null;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(density == WordCardDensity.compact ? 18 : 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (isFavorite)
                  StatusBadge(
                    label: pickUiText(i18n, zh: '已收藏', en: 'Favorite'),
                    icon: Icons.favorite_rounded,
                    color: const Color(0xFFE25A7A),
                  ),
                if (isTaskWord)
                  StatusBadge(
                    label: pickUiText(i18n, zh: '任务词', en: 'Task'),
                    icon: Icons.task_alt_rounded,
                    color: tokens.success,
                  ),
              ],
            ),
            if (isFavorite || isTaskWord) const SizedBox(height: 14),
            _WordHeaderBlock(
              i18n: i18n,
              word: word.word,
              titleStyle: titleStyle,
              visibleMeaning: visibleMeaning,
              revealPracticeAnswer: revealPracticeAnswer,
              density: density,
              visibleExamples: visibleExamples,
              textSecondary: tokens.textSecondary,
              onPreviousWord: onPreviousWord,
              onNextWord: onNextWord,
              onPlayPronunciation: onPlayPronunciation,
              onFollowAlong: onFollowAlong,
              onSwipePrevious: onSwipePrevious,
              onSwipeNext: onSwipeNext,
              enableWordSwipe: enableWordSwipe,
            ),
            if (showFields) ...[
              const SizedBox(height: 18),
              Column(
                children: fields
                    .where(
                      (item) => item.key != 'meaning' && item.key != 'examples',
                    )
                    .take(density == WordCardDensity.compact ? 2 : 4)
                    .map(
                      (field) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        constraints: const BoxConstraints(minHeight: 40),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.surfaceMuted,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: tokens.outline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              localizedFieldLabel(i18n, field),
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              field.asText(),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                if (onToggleFavorite != null)
                  OutlinedButton.icon(
                    onPressed: onToggleFavorite,
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                    ),
                    label: Text(pickUiText(i18n, zh: '收藏', en: 'Favorite')),
                  ),
                if (onToggleTask != null)
                  OutlinedButton.icon(
                    onPressed: onToggleTask,
                    icon: Icon(
                      isTaskWord
                          ? Icons.task_alt_rounded
                          : Icons.playlist_add_check_rounded,
                    ),
                    label: Text(
                      pickUiText(i18n, zh: '加入任务', en: 'Add to task'),
                    ),
                  ),
              ],
            ),
            if (footer != null) ...[const SizedBox(height: 16), footer!],
          ],
        ),
      ),
    );
  }

  List<WordFieldItem> _displayFields(WordEntry entry) {
    if (entry.fields.isNotEmpty) return entry.fields;
    return buildFieldItemsFromRecord(<String, Object?>{
      'meaning': entry.meaning,
      'examples': entry.examples,
      'etymology': entry.etymology,
      'roots': entry.roots,
      'affixes': entry.affixes,
      'variations': entry.variations,
      'memory': entry.memory,
      'story': entry.story,
    });
  }
}

class _WordHeaderBlock extends StatelessWidget {
  const _WordHeaderBlock({
    required this.i18n,
    required this.word,
    required this.titleStyle,
    required this.visibleMeaning,
    required this.revealPracticeAnswer,
    required this.density,
    required this.visibleExamples,
    required this.textSecondary,
    required this.onPreviousWord,
    required this.onNextWord,
    required this.onPlayPronunciation,
    required this.onFollowAlong,
    required this.onSwipePrevious,
    required this.onSwipeNext,
    required this.enableWordSwipe,
  });

  static const double _swipeVelocityThreshold = 320;
  static const double _swipeDistanceThreshold = 56;

  final AppI18n i18n;
  final String word;
  final TextStyle? titleStyle;
  final String visibleMeaning;
  final bool revealPracticeAnswer;
  final WordCardDensity density;
  final List<String> visibleExamples;
  final Color textSecondary;
  final VoidCallback? onPreviousWord;
  final VoidCallback? onNextWord;
  final VoidCallback? onPlayPronunciation;
  final VoidCallback? onFollowAlong;
  final VoidCallback? onSwipePrevious;
  final VoidCallback? onSwipeNext;
  final bool enableWordSwipe;

  void _onHorizontalDragEnd(
    DragEndDetails details, {
    required double dragDistance,
  }) {
    final velocity = details.primaryVelocity ?? 0;
    final swipeRight =
        velocity >= _swipeVelocityThreshold ||
        dragDistance >= _swipeDistanceThreshold;
    final swipeLeft =
        velocity <= -_swipeVelocityThreshold ||
        dragDistance <= -_swipeDistanceThreshold;
    if (swipeRight) {
      onSwipePrevious?.call();
      return;
    }
    if (swipeLeft) {
      onSwipeNext?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canReveal =
        density != WordCardDensity.practice || revealPracticeAnswer;
    final cleanedMeaning = visibleMeaning.trim();
    final cleanedExamples = visibleExamples
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(density == WordCardDensity.compact ? 1 : 3)
        .toList(growable: false);

    final controls = <Widget>[
      if (onPreviousWord != null)
        IconButton.filledTonal(
          onPressed: onPreviousWord,
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: pickUiText(
            i18n,
            zh: '\u4e0a\u4e00\u4e2a',
            en: 'Previous word',
          ),
        ),
      if (onNextWord != null)
        IconButton.filledTonal(
          onPressed: onNextWord,
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: pickUiText(i18n, zh: '\u4e0b\u4e00\u4e2a', en: 'Next word'),
        ),
      if (onPlayPronunciation != null)
        FilledButton.tonalIcon(
          onPressed: onPlayPronunciation,
          icon: const Icon(Icons.volume_up_rounded),
          label: Text(i18n.t('playPronunciation')),
        ),
      if (onFollowAlong != null)
        OutlinedButton.icon(
          onPressed: onFollowAlong,
          icon: const Icon(Icons.mic_external_on_rounded),
          label: Text(pickUiText(i18n, zh: '\u8ddf\u8bfb', en: 'Follow')),
        ),
    ];

    final wordPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(word, style: titleStyle),
        if (!canReveal) ...[
          const SizedBox(height: 10),
          Text(
            pickUiText(
              i18n,
              zh: '\u5148\u56de\u5fc6\uff0c\u518d\u70b9\u51fb\u663e\u793a\u7b54\u6848',
              en: 'Recall first, then reveal the answer.',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(color: textSecondary),
          ),
        ] else ...[
          if (cleanedMeaning.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              cleanedMeaning,
              style: theme.textTheme.bodyLarge?.copyWith(color: textSecondary),
            ),
          ],
          if (cleanedExamples.isNotEmpty) ...[
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: cleanedExamples
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '\u2022 $item',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textSecondary,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
        if (enableWordSwipe) ...[
          const SizedBox(height: 10),
          Text(
            pickUiText(
              i18n,
              zh: '\u5728\u5355\u8bcd\u533a\u57df\u5de6\u53f3\u6ed1\u52a8\u53ef\u5207\u8bcd',
              en: 'Swipe left or right on this word to switch.',
            ),
            style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (controls.isNotEmpty) ...[
          Wrap(spacing: 8, runSpacing: 8, children: controls),
          const SizedBox(height: 14),
        ],
        if (enableWordSwipe)
          Builder(
            builder: (context) {
              var dragDistance = 0.0;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (_) {
                  dragDistance = 0;
                },
                onHorizontalDragUpdate: (details) {
                  dragDistance += details.primaryDelta ?? 0;
                },
                onHorizontalDragEnd: (details) {
                  _onHorizontalDragEnd(details, dragDistance: dragDistance);
                },
                child: wordPanel,
              );
            },
          )
        else
          wordPanel,
      ],
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}

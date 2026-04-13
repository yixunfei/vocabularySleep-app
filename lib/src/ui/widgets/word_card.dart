import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../../models/play_config.dart';
import '../../models/word_entry.dart';
import '../../models/word_field.dart';
import '../legacy_style.dart';
import '../theme/app_theme.dart';
import '../ui_copy.dart';
import 'effectful_text.dart';
import 'status_badge.dart';

enum WordCardDensity { immersive, compact, practice }

class WordCard extends StatelessWidget {
  const WordCard({
    super.key,
    required this.word,
    required this.i18n,
    this.density = WordCardDensity.immersive,
    this.transitionStyle = WordPageTransitionStyle.defaultStyle,
    this.transitionDirection = 1,
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
  final WordPageTransitionStyle transitionStyle;
  final int transitionDirection;
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

  Duration get _transitionDuration => switch (transitionStyle) {
    WordPageTransitionStyle.defaultStyle => Duration.zero,
    WordPageTransitionStyle.smooth => const Duration(milliseconds: 280),
    WordPageTransitionStyle.fade => const Duration(milliseconds: 240),
    WordPageTransitionStyle.pageFlip => const Duration(milliseconds: 340),
  };

  String _wordIdentity(WordEntry entry) => entry.stableIdentityKey;

  String _favoriteLabel() {
    if (isFavorite) {
      return pickUiText(i18n, zh: '取消收藏', en: 'Unfavorite');
    }
    return pickUiText(i18n, zh: '收藏', en: 'Favorite');
  }

  String _taskLabel() {
    if (isTaskWord) {
      return pickUiText(i18n, zh: '移出任务', en: 'Remove task');
    }
    return pickUiText(i18n, zh: '加入任务', en: 'Add to task');
  }

  List<WordFieldItem> _displayFields(WordEntry entry) {
    return entry.previewSupplementaryFields;
  }

  Widget _buildTransition(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final direction = transitionDirection >= 0 ? 1 : -1;

    return switch (transitionStyle) {
      WordPageTransitionStyle.defaultStyle => FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(direction * 0.08, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      ),
      WordPageTransitionStyle.smooth => FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(direction * 0.18, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      ),
      WordPageTransitionStyle.fade => FadeTransition(
        opacity: curved,
        child: child,
      ),
      WordPageTransitionStyle.pageFlip => AnimatedBuilder(
        animation: curved,
        child: child,
        builder: (context, flipChild) {
          final value = curved.value;
          final tilt = (1 - value) * 0.55 * direction;
          return FadeTransition(
            opacity: curved,
            child: Transform(
              alignment: direction > 0
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0014)
                ..rotateY(tilt),
              child: flipChild,
            ),
          );
        },
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppThemeTokens.of(context);
    final appearance = LegacyStyle.appearance;
    final fields = _displayFields(word);
    final titleStyle = switch (density) {
      WordCardDensity.compact => theme.textTheme.titleLarge,
      WordCardDensity.practice => theme.textTheme.headlineSmall,
      WordCardDensity.immersive => theme.textTheme.headlineLarge,
    };
    final canReveal =
        density != WordCardDensity.practice || revealPracticeAnswer;
    final visibleMeaning = showMeaning && canReveal ? word.displayMeaning : '';
    final visibleExamples = showFields && canReveal
        ? word.displayExamples
        : const <String>[];
    final enableWordSwipe = onSwipePrevious != null || onSwipeNext != null;

    final cardContent = KeyedSubtree(
      key: ValueKey<String>(_wordIdentity(word)),
      child: Card(
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
                titleColor:
                    Color.lerp(tokens.textPrimary, tokens.accent, 0.42) ??
                    tokens.textPrimary,
                textSecondary: tokens.textSecondary,
                onPreviousWord: onPreviousWord,
                onNextWord: onNextWord,
                onPlayPronunciation: onPlayPronunciation,
                onFollowAlong: onFollowAlong,
                enableWordSwipe: enableWordSwipe,
              ),
              if (showFields) ...<Widget>[
                const SizedBox(height: 18),
                Column(
                  children: fields
                      .where(
                        (item) =>
                            item.key != 'meaning' && item.key != 'examples',
                      )
                      .take(density == WordCardDensity.compact ? 2 : 4)
                      .toList(growable: false)
                      .asMap()
                      .entries
                      .map((entry) {
                        final field = entry.value;
                        final accentColor = appearance.randomEntryColors
                            ? seededAccentColor(
                                '${word.word}:${field.key}:${entry.key}',
                                fallback: tokens.accent,
                                saturation: 0.56,
                                value: tokens.isDark ? 0.92 : 0.78,
                              )
                            : tokens.accent;
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          constraints: const BoxConstraints(minHeight: 40),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: LegacyStyle.fieldCardDecoration(
                            accentColor: accentColor,
                            fieldKey: field.key,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                localizedFieldLabel(i18n, field),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: accentColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                field.asText(),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: tokens.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      })
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
                      label: Text(_favoriteLabel()),
                    ),
                  if (onToggleTask != null)
                    OutlinedButton.icon(
                      onPressed: onToggleTask,
                      icon: Icon(
                        isTaskWord
                            ? Icons.task_alt_rounded
                            : Icons.playlist_add_check_rounded,
                      ),
                      label: Text(_taskLabel()),
                    ),
                ],
              ),
              ...?switch (footer) {
                final footerWidget? => <Widget>[
                  const SizedBox(height: 16),
                  footerWidget,
                ],
                null => null,
              },
            ],
          ),
        ),
      ),
    );

    final animatedCard = transitionStyle == WordPageTransitionStyle.defaultStyle
        ? cardContent
        : ClipRect(
            child: AnimatedSwitcher(
              duration: _transitionDuration,
              reverseDuration: _transitionDuration,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    ...previousChildren,
                    ...?switch (currentChild) {
                      final child? => <Widget>[child],
                      null => null,
                    },
                  ],
                );
              },
              transitionBuilder: _buildTransition,
              child: cardContent,
            ),
          );

    if (!enableWordSwipe) return animatedCard;

    return _WordSwipeRegion(
      onSwipePrevious: onSwipePrevious,
      onSwipeNext: onSwipeNext,
      child: animatedCard,
    );
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
    required this.titleColor,
    required this.textSecondary,
    required this.onPreviousWord,
    required this.onNextWord,
    required this.onPlayPronunciation,
    required this.onFollowAlong,
    required this.enableWordSwipe,
  });

  final AppI18n i18n;
  final String word;
  final TextStyle? titleStyle;
  final String visibleMeaning;
  final bool revealPracticeAnswer;
  final WordCardDensity density;
  final List<String> visibleExamples;
  final Color titleColor;
  final Color textSecondary;
  final VoidCallback? onPreviousWord;
  final VoidCallback? onNextWord;
  final VoidCallback? onPlayPronunciation;
  final VoidCallback? onFollowAlong;
  final bool enableWordSwipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appearance = LegacyStyle.appearance;
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
          tooltip: pickUiText(i18n, zh: '上一个', en: 'Previous word'),
        ),
      if (onNextWord != null)
        IconButton.filledTonal(
          onPressed: onNextWord,
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: pickUiText(i18n, zh: '下一个', en: 'Next word'),
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
          label: Text(pickUiText(i18n, zh: '跟读', en: 'Follow')),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (controls.isNotEmpty) ...<Widget>[
          Wrap(spacing: 8, runSpacing: 8, children: controls),
          const SizedBox(height: 14),
        ],
        Semantics(
          header: density != WordCardDensity.compact,
          label: word,
          child: ExcludeSemantics(
            child: EffectfulText(
              word,
              style: titleStyle?.copyWith(
                color: appearance.rainbowText ? Colors.white : titleColor,
                fontWeight: FontWeight.w800,
              ),
              maxLines: appearance.marqueeText ? null : 2,
              rainbowText: appearance.rainbowText,
              marqueeText: appearance.marqueeText,
              breathingEffect: appearance.breathingEffect,
              flowingEffect: appearance.flowingEffect,
            ),
          ),
        ),
        if (!canReveal) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            pickUiText(
              i18n,
              zh: '先回忆，再点击显示答案',
              en: 'Recall first, then reveal the answer.',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(color: textSecondary),
          ),
        ] else ...<Widget>[
          if (cleanedMeaning.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              cleanedMeaning,
              style: theme.textTheme.bodyLarge?.copyWith(color: textSecondary),
            ),
          ],
          if (cleanedExamples.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: cleanedExamples
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '- $item',
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
        if (enableWordSwipe) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            pickUiText(
              i18n,
              zh: '在整张单词卡片上左右滑动可切词',
              en: 'Swipe anywhere on this card to switch.',
            ),
            style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
          ),
        ],
      ],
    );
  }
}

class _WordSwipeRegion extends StatefulWidget {
  const _WordSwipeRegion({
    required this.child,
    this.onSwipePrevious,
    this.onSwipeNext,
  });

  static const double swipeVelocityThreshold = 320;
  static const double swipeDistanceThreshold = 56;

  final Widget child;
  final VoidCallback? onSwipePrevious;
  final VoidCallback? onSwipeNext;

  @override
  State<_WordSwipeRegion> createState() => _WordSwipeRegionState();
}

class _WordSwipeRegionState extends State<_WordSwipeRegion> {
  double _dragDistance = 0;

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final swipeRight =
        velocity >= _WordSwipeRegion.swipeVelocityThreshold ||
        _dragDistance >= _WordSwipeRegion.swipeDistanceThreshold;
    final swipeLeft =
        velocity <= -_WordSwipeRegion.swipeVelocityThreshold ||
        _dragDistance <= -_WordSwipeRegion.swipeDistanceThreshold;

    if (swipeRight) {
      widget.onSwipePrevious?.call();
      return;
    }
    if (swipeLeft) {
      widget.onSwipeNext?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) {
        _dragDistance = 0;
      },
      onHorizontalDragUpdate: (details) {
        _dragDistance += details.primaryDelta ?? 0;
      },
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      child: widget.child,
    );
  }
}

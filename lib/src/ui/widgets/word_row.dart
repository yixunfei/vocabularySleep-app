import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../../models/word_entry.dart';
import '../legacy_style.dart';
import '../theme/app_theme.dart';
import '../ui_copy.dart';
import 'effectful_text.dart';

enum _WordRowMenuAction { toggleFavorite, toggleTask }

class WordRow extends StatelessWidget {
  const WordRow({
    super.key,
    required this.word,
    required this.i18n,
    required this.selected,
    required this.showMeaning,
    this.showFields = false,
    required this.isFavorite,
    required this.isTaskWord,
    required this.onTap,
    this.onPlay,
    this.onFollowAlong,
    this.onToggleFavorite,
    this.onToggleTask,
  });

  final WordEntry word;
  final AppI18n i18n;
  final bool selected;
  final bool showMeaning;
  final bool showFields;
  final bool isFavorite;
  final bool isTaskWord;
  final VoidCallback onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onFollowAlong;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onToggleTask;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppThemeTokens.of(context);
    final appearance = LegacyStyle.appearance;
    final rowAccent = appearance.randomEntryColors
        ? seededAccentColor(
            '${word.wordbookId}:${word.word}',
            fallback: tokens.accent,
            saturation: 0.52,
            value: tokens.isDark ? 0.9 : 0.8,
          )
        : tokens.accent;
    final subtitle = word.meaning?.trim().isNotEmpty == true
        ? word.meaning!
        : (word.fields.isEmpty ? '' : word.fields.first.asText());
    final extraFields = word.fields
        .where((item) => item.key != 'meaning')
        .take(showFields ? 2 : 0)
        .toList(growable: false);
    final hasMenuActions = onToggleFavorite != null || onToggleTask != null;

    return Card(
      color: selected
          ? Color.lerp(tokens.surfaceStrong, rowAccent, 0.14)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: (selected ? rowAccent : tokens.outline).withValues(
            alpha: selected ? 0.92 : (appearance.randomEntryColors ? 0.82 : 1),
          ),
          width: selected ? 1.35 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 8, right: 10),
                    decoration: BoxDecoration(
                      color: rowAccent,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: rowAccent.withValues(
                            alpha: appearance.randomEntryColors ? 0.32 : 0.18,
                          ),
                          blurRadius: appearance.randomEntryColors ? 10 : 6,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: EffectfulText(
                      word.word,
                      maxLines: 2,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: selected
                            ? rowAccent
                            : (appearance.randomEntryColors
                                  ? Color.lerp(
                                      tokens.textPrimary,
                                      rowAccent,
                                      0.28,
                                    )
                                  : null),
                        fontWeight: FontWeight.w700,
                      ),
                      rainbowText: selected && appearance.rainbowText,
                      marqueeText: selected && appearance.marqueeText,
                      breathingEffect: selected && appearance.breathingEffect,
                      flowingEffect: selected && appearance.flowingEffect,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: tokens.textSecondary,
                    size: 20,
                  ),
                ],
              ),
              if (selected || isFavorite || isTaskWord) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    if (selected)
                      _WordRowTag(
                        label: '\u5f53\u524d',
                        icon: Icons.navigation_rounded,
                        color: rowAccent,
                      ),
                    if (isFavorite)
                      _WordRowTag(
                        label: pickUiText(i18n, zh: '\u6536\u85cf', en: 'Fav'),
                        icon: Icons.favorite_rounded,
                        color: const Color(0xFFE25A7A),
                      ),
                    if (isTaskWord)
                      _WordRowTag(
                        label: pickUiText(i18n, zh: '\u4efb\u52a1', en: 'Task'),
                        icon: Icons.task_alt_rounded,
                        color: tokens.success,
                      ),
                  ],
                ),
              ],
              if (showMeaning && subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
              ] else if (!showMeaning) ...[
                const SizedBox(height: 10),
                Text(
                  '\u6587\u672c\u5df2\u9690\u85cf',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
              ],
              if (showMeaning && extraFields.isNotEmpty) ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: extraFields
                      .map(
                        (field) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '${field.label}: ${field.asText()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 420;
                  final moreAction = hasMenuActions
                      ? PopupMenuButton<_WordRowMenuAction>(
                          tooltip: pickUiText(
                            i18n,
                            zh: '\u66f4\u591a\u64cd\u4f5c',
                            en: 'More actions',
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case _WordRowMenuAction.toggleFavorite:
                                onToggleFavorite?.call();
                                break;
                              case _WordRowMenuAction.toggleTask:
                                onToggleTask?.call();
                                break;
                            }
                          },
                          itemBuilder: (context) => <PopupMenuEntry<_WordRowMenuAction>>[
                            if (onToggleFavorite != null)
                              PopupMenuItem<_WordRowMenuAction>(
                                value: _WordRowMenuAction.toggleFavorite,
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      isFavorite
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isFavorite
                                            ? pickUiText(
                                                i18n,
                                                zh: '\u53d6\u6d88\u6536\u85cf',
                                                en: 'Unfavorite',
                                              )
                                            : pickUiText(
                                                i18n,
                                                zh: '\u52a0\u5165\u6536\u85cf',
                                                en: 'Add favorite',
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (onToggleTask != null)
                              PopupMenuItem<_WordRowMenuAction>(
                                value: _WordRowMenuAction.toggleTask,
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      isTaskWord
                                          ? Icons.task_alt_rounded
                                          : Icons.playlist_add_check_rounded,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isTaskWord
                                            ? pickUiText(
                                                i18n,
                                                zh: '\u79fb\u51fa\u4efb\u52a1',
                                                en: 'Remove task',
                                              )
                                            : pickUiText(
                                                i18n,
                                                zh: '\u52a0\u5165\u4efb\u52a1',
                                                en: 'Add task',
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.more_horiz_rounded),
                          ),
                        )
                      : null;

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (onPlay != null)
                          FilledButton.tonalIcon(
                            onPressed: onPlay,
                            icon: const Icon(Icons.volume_up_rounded),
                            label: Text(i18n.t('playPronunciation')),
                          ),
                        if (onPlay != null && onFollowAlong != null)
                          const SizedBox(height: 8),
                        if (onFollowAlong != null)
                          OutlinedButton.icon(
                            onPressed: onFollowAlong,
                            icon: const Icon(Icons.mic_external_on_rounded),
                            label: Text(
                              pickUiText(
                                i18n,
                                zh: '\u8ddf\u8bfb',
                                en: 'Follow',
                              ),
                            ),
                          ),
                        if (moreAction != null) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: moreAction,
                          ),
                        ],
                      ],
                    );
                  }

                  return Row(
                    children: <Widget>[
                      if (onPlay != null)
                        FilledButton.tonalIcon(
                          onPressed: onPlay,
                          icon: const Icon(Icons.volume_up_rounded),
                          label: Text(i18n.t('playPronunciation')),
                        ),
                      if (onPlay != null && onFollowAlong != null)
                        const SizedBox(width: 8),
                      if (onFollowAlong != null)
                        OutlinedButton.icon(
                          onPressed: onFollowAlong,
                          icon: const Icon(Icons.mic_external_on_rounded),
                          label: Text(
                            pickUiText(i18n, zh: '\u8ddf\u8bfb', en: 'Follow'),
                          ),
                        ),
                      if (moreAction != null) ...[const Spacer(), moreAction],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordRowTag extends StatelessWidget {
  const _WordRowTag({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

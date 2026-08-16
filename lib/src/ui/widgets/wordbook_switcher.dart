import 'package:flutter/material.dart';

import '../../models/wordbook.dart';

class WordbookSwitcher extends StatelessWidget {
  const WordbookSwitcher({
    super.key,
    required this.wordbook,
    this.title,
    required this.subtitle,
    required this.onTap,
    this.semanticLabel,
    this.tooltip,
    this.actionLabel,
    this.actionIcon,
    this.onActionTap,
  });

  final Wordbook? wordbook;
  final String? title;
  final String subtitle;
  final VoidCallback onTap;
  final String? semanticLabel;
  final String? tooltip;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTitle = title ?? wordbook?.name ?? subtitle;
    final effectiveTooltip = tooltip ?? semanticLabel ?? effectiveTitle;
    final trailingLabel = actionLabel;

    return Semantics(
      button: true,
      label: semanticLabel ?? effectiveTitle,
      child: Tooltip(
        message: effectiveTooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compactAction = constraints.maxWidth < 380;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.menu_book_rounded, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 240;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  effectiveTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  maxLines: isNarrow ? 2 : 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (trailingLabel == null)
                        const Icon(Icons.expand_more_rounded, size: 18)
                      else if (compactAction)
                        IconButton.filledTonal(
                          tooltip: trailingLabel,
                          visualDensity: VisualDensity.compact,
                          onPressed: onActionTap ?? onTap,
                          icon: Icon(
                            actionIcon ?? Icons.swap_horiz_rounded,
                            size: 18,
                          ),
                        )
                      else
                        ActionChip(
                          avatar: Icon(
                            actionIcon ?? Icons.swap_horiz_rounded,
                            size: 18,
                          ),
                          label: Text(
                            trailingLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: onActionTap ?? onTap,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

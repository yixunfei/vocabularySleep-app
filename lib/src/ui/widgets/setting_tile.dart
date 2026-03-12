import 'package:flutter/material.dart';

import '../layout/app_width_tier.dart';

class SettingTile extends StatelessWidget {
  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedTrailing =
        trailing ??
        (onTap != null ? const Icon(Icons.chevron_right_rounded) : null);
    final iconLikeTrailing =
        resolvedTrailing is Icon || resolvedTrailing is IconButton;

    Widget buildTrailing({
      int maxLines = 1,
      TextAlign textAlign = TextAlign.right,
    }) {
      final trailingChild = resolvedTrailing;
      if (trailingChild == null) return const SizedBox.shrink();
      return DefaultTextStyle.merge(
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        softWrap: maxLines > 1,
        textAlign: textAlign,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: theme.colorScheme.primary),
          child: trailingChild,
        ),
      );
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final widthTier = AppWidthBreakpoints.tierFor(
                constraints.maxWidth,
              );
              final stackTextTrailing =
                  resolvedTrailing != null &&
                  !iconLikeTrailing &&
                  widthTier.isCompact;
              final trailingMaxWidth = iconLikeTrailing
                  ? 28.0
                  : constraints.maxWidth * (stackTextTrailing ? 0.62 : 0.4);

              final header = resolvedTrailing == null
                  ? Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    )
                  : stackTextTrailing
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: trailingMaxWidth,
                            ),
                            child: buildTrailing(maxLines: 2),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: trailingMaxWidth,
                            minWidth: iconLikeTrailing ? 24 : 0,
                          ),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: buildTrailing(
                              maxLines: iconLikeTrailing ? 1 : 2,
                            ),
                          ),
                        ),
                      ],
                    );

              final textBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  header,
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: stackTextTrailing ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              );

              if (resolvedTrailing == null) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(icon),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: textBlock),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(icon),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: textBlock),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

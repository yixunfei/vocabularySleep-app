import 'package:flutter/material.dart';

import '../layout/app_width_tier.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textBlock = LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = AppWidthBreakpoints.tierFor(
          constraints.maxWidth,
        ).isCompact;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: isCompact
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.titleLarge,
            ),
            if ((subtitle ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: theme.textTheme.bodySmall),
            ],
          ],
        );
      },
    );

    final resolvedTrailing = trailing;
    if (resolvedTrailing == null) {
      return textBlock;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = AppWidthBreakpoints.tierFor(
          constraints.maxWidth,
        ).isCompact;
        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              textBlock,
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: resolvedTrailing),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(child: textBlock),
            const SizedBox(width: 12),
            resolvedTrailing,
          ],
        );
      },
    );
  }
}

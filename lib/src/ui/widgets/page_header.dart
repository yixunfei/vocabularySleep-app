import 'package:flutter/material.dart';

import '../layout/app_width_tier.dart';
import 'app_logo.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.action,
  });

  final String title;
  final String subtitle;
  final String? eyebrow;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedAction = action ?? const AppLogoMark();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = AppWidthBreakpoints.tierFor(
          constraints.maxWidth,
        ).isCompact;
        final textBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if ((eyebrow ?? '').trim().isNotEmpty) ...[
              Text(
                eyebrow!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(title, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(subtitle, style: theme.textTheme.bodyMedium),
          ],
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              textBlock,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: resolvedAction),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: textBlock),
            const SizedBox(width: 12),
            resolvedAction,
          ],
        );
      },
    );
  }
}

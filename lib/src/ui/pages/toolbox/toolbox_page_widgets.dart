import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/app_state_provider.dart';
import '../../module/module_access.dart';
import '../../layout/app_width_tier.dart';
import '../../motion/app_motion.dart';
import '../../widgets/section_header.dart';
import 'toolbox_page_models.dart';
import 'toolbox_ui_components.dart';
import 'toolbox_ui_tokens.dart';

class ToolboxIntroPanel extends StatelessWidget {
  const ToolboxIntroPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.highlights,
  });

  final String title;
  final String subtitle;
  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(18),
      radius: ToolboxUiTokens.panelRadius,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          colorScheme.primaryContainer.withValues(alpha: 0.68),
          colorScheme.surfaceContainerLowest,
          colorScheme.secondaryContainer.withValues(alpha: 0.44),
        ],
      ),
      borderColor: colorScheme.outlineVariant.withValues(alpha: 0.75),
      shadowColor: colorScheme.primary,
      shadowOpacity: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: highlights
                .map(
                  (item) => ToolboxInfoPill(
                    text: item,
                    accent: colorScheme.outlineVariant,
                    backgroundColor: colorScheme.surface.withValues(
                      alpha: 0.72,
                    ),
                    textColor: colorScheme.onSurface,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class ToolboxSection extends StatelessWidget {
  const ToolboxSection({super.key, required this.section});

  final ToolboxSectionData section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(title: section.title, subtitle: section.subtitle),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        LayoutBuilder(
          builder: (context, constraints) {
            final widthTier = AppWidthBreakpoints.tierFor(constraints.maxWidth);
            final columns = widthTier.isExpanded ? 2 : 1;
            final spacing = ToolboxUiTokens.cardSpacing;
            final availableWidth =
                constraints.maxWidth - spacing * (columns - 1);
            final cardWidth = availableWidth / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: section.entries
                  .map(
                    (entry) => SizedBox(
                      width: cardWidth,
                      child: ToolboxEntryCard(entry: entry),
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

class ToolboxEntryCard extends ConsumerStatefulWidget {
  const ToolboxEntryCard({super.key, required this.entry});

  final ToolboxEntryData entry;

  @override
  ConsumerState<ToolboxEntryCard> createState() => _ToolboxEntryCardState();
}

class _ToolboxEntryCardState extends ConsumerState<ToolboxEntryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entry = widget.entry;
    final accent = entry.accent;
    final radius = BorderRadius.circular(ToolboxUiTokens.cardRadius);

    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: AppDurations.quick,
      curve: AppEasing.snappy,
      child: AnimatedContainer(
        duration: AppDurations.standard,
        curve: AppEasing.standard,
        constraints: const BoxConstraints(
          minHeight: ToolboxUiTokens.entryMinHeight,
        ),
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              accent.withValues(alpha: _pressed ? 0.05 : 0.11),
              colorScheme.surface.withValues(alpha: 0.98),
              accent.withValues(alpha: _pressed ? 0.015 : 0.035),
            ],
          ),
          border: Border.all(
            color: accent.withValues(alpha: _pressed ? 0.16 : 0.24),
          ),
          boxShadow: <BoxShadow>[toolboxCardShadow(accent, pressed: _pressed)],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onHighlightChanged: (value) {
              if (_pressed == value) {
                return;
              }
              setState(() {
                _pressed = value;
              });
            },
            onTap: () {
              final appState = ref.read(appStateProvider);
              pushModuleRoute<void>(
                context,
                state: appState,
                moduleId: entry.moduleId,
                builder: (_) => entry.pageBuilder(),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: ToolboxUiTokens.iconSize,
                    height: ToolboxUiTokens.iconSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        ToolboxUiTokens.iconRadius,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          accent.withValues(alpha: 0.22),
                          accent.withValues(alpha: 0.08),
                        ],
                      ),
                      border: Border.all(color: accent.withValues(alpha: 0.16)),
                    ),
                    alignment: Alignment.center,
                    child: Icon(entry.icon, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          entry.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.35,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 52,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        AnimatedContainer(
                          duration: AppDurations.quick,
                          curve: AppEasing.snappy,
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: accent.withValues(
                              alpha: _pressed ? 0.12 : 0.08,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: accent.withValues(
                              alpha: _pressed ? 0.98 : 0.84,
                            ),
                          ),
                        ),
                        AnimatedOpacity(
                          duration: AppDurations.quick,
                          curve: AppEasing.gentle,
                          opacity: _pressed ? 0.12 : 1,
                          child: Container(
                            width: 18,
                            height: 3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: accent.withValues(alpha: 0.42),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

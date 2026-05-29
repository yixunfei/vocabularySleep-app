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
    required this.summary,
    required this.details,
    required this.highlights,
    required this.helpTooltip,
  });

  final String title;
  final String summary;
  final String details;
  final List<String> highlights;
  final String helpTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ToolboxSurfaceCard(
      key: const ValueKey<String>('toolbox_intro_panel'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      radius: ToolboxUiTokens.shellCardRadius,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          colorScheme.primaryContainer.withValues(alpha: 0.44),
          colorScheme.surfaceContainerLowest,
          colorScheme.secondaryContainer.withValues(alpha: 0.28),
        ],
      ),
      borderColor: colorScheme.outlineVariant.withValues(alpha: 0.68),
      shadowColor: colorScheme.primary,
      shadowOpacity: 0.04,
      shadowBlur: 14,
      shadowOffsetY: 6,
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.14),
              ),
            ),
            child: Icon(
              Icons.dashboard_customize_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Semantics(
            button: true,
            label: helpTooltip,
            child: Tooltip(
              message: helpTooltip,
              child: IconButton.filledTonal(
                key: const ValueKey<String>('toolbox_intro_help_button'),
                onPressed: () => _showIntroDetails(context),
                icon: const Icon(Icons.help_outline_rounded),
                color: colorScheme.primary,
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surface.withValues(alpha: 0.74),
                  minimumSize: const Size(48, 48),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showIntroDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.58,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.help_outline_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          details,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: highlights
                    .map(
                      (item) => ToolboxInfoPill(
                        text: item,
                        accent: colorScheme.outlineVariant,
                        backgroundColor: colorScheme.surfaceContainerLow
                            .withValues(alpha: 0.82),
                        textColor: colorScheme.onSurface,
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ToolboxSection extends StatelessWidget {
  const ToolboxSection({
    super.key,
    required this.section,
    this.editing = false,
    this.enableQuickDrag = false,
    this.onEntryLongPress,
    this.onEntryRemove,
    this.onEntryOpen,
    this.dragTooltip = '',
    this.removeTooltip = '',
  });

  final ToolboxSectionData section;
  final bool editing;
  final bool enableQuickDrag;
  final ValueChanged<ToolboxEntryData>? onEntryLongPress;
  final ValueChanged<ToolboxEntryData>? onEntryRemove;
  final ValueChanged<ToolboxEntryData>? onEntryOpen;
  final String dragTooltip;
  final String removeTooltip;

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
                      child: _ToolboxEntryTile(
                        entry: entry,
                        editing: editing,
                        enableQuickDrag: enableQuickDrag,
                        onLongPress: onEntryLongPress == null
                            ? null
                            : () => onEntryLongPress!(entry),
                        onRemove: onEntryRemove == null
                            ? null
                            : () => onEntryRemove!(entry),
                        onOpen: onEntryOpen,
                        dragTooltip: dragTooltip,
                        removeTooltip: removeTooltip,
                      ),
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

class _ToolboxEntryTile extends StatelessWidget {
  const _ToolboxEntryTile({
    required this.entry,
    required this.editing,
    required this.enableQuickDrag,
    required this.onLongPress,
    required this.onRemove,
    required this.onOpen,
    required this.dragTooltip,
    required this.removeTooltip,
  });

  final ToolboxEntryData entry;
  final bool editing;
  final bool enableQuickDrag;
  final VoidCallback? onLongPress;
  final VoidCallback? onRemove;
  final ValueChanged<ToolboxEntryData>? onOpen;
  final String dragTooltip;
  final String removeTooltip;

  @override
  Widget build(BuildContext context) {
    final card = ToolboxEntryCard(
      entry: entry,
      editing: editing,
      onLongPress: onLongPress,
      onRemove: onRemove,
      onOpen: onOpen,
      dragTooltip: dragTooltip,
      removeTooltip: removeTooltip,
    );
    if (!enableQuickDrag || editing) {
      return card;
    }
    return LongPressDraggable<ToolboxEntryData>(
      key: ValueKey<String>('toolbox_entry_draggable_${entry.moduleId}'),
      data: entry,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width - 32,
          child: Opacity(opacity: 0.94, child: card),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.55, child: card),
      child: card,
    );
  }
}

class ToolboxEntryCard extends ConsumerStatefulWidget {
  const ToolboxEntryCard({
    super.key,
    required this.entry,
    this.editing = false,
    this.onLongPress,
    this.onRemove,
    this.onOpen,
    this.dragHandle,
    this.dragTooltip = '',
    this.removeTooltip = '',
  });

  final ToolboxEntryData entry;
  final bool editing;
  final VoidCallback? onLongPress;
  final VoidCallback? onRemove;
  final ValueChanged<ToolboxEntryData>? onOpen;
  final Widget? dragHandle;
  final String dragTooltip;
  final String removeTooltip;

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
        height: widget.editing
            ? ToolboxUiTokens.entryEditingCardHeight
            : ToolboxUiTokens.entryCardHeight,
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
              if (widget.editing) {
                return;
              }
              final onOpen = widget.onOpen;
              if (onOpen != null) {
                onOpen(entry);
                return;
              }
              final appState = ref.read(appStateProvider);
              pushModuleRoute<void>(
                context,
                state: appState,
                moduleId: entry.moduleId,
                builder: (_) => entry.pageBuilder(),
              );
            },
            onLongPress: widget.onLongPress,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.35,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (widget.editing)
                    _ToolboxEntryEditActions(
                      accent: accent,
                      dragHandle: widget.dragHandle,
                      dragKey: ValueKey<String>(
                        'toolbox_drag_${entry.moduleId}',
                      ),
                      onRemove: widget.onRemove,
                      dragTooltip: widget.dragTooltip,
                      removeTooltip: widget.removeTooltip,
                      removeKey: ValueKey<String>(
                        'toolbox_remove_${entry.moduleId}',
                      ),
                    )
                  else
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

class _ToolboxEntryEditActions extends StatelessWidget {
  const _ToolboxEntryEditActions({
    required this.accent,
    required this.dragHandle,
    required this.dragKey,
    required this.onRemove,
    required this.dragTooltip,
    required this.removeTooltip,
    required this.removeKey,
  });

  final Color accent;
  final Widget? dragHandle;
  final Key dragKey;
  final VoidCallback? onRemove;
  final String dragTooltip;
  final String removeTooltip;
  final Key removeKey;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const actionSize = ToolboxUiTokens.editActionSize;
    return SizedBox(
      width: actionSize,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Tooltip(
            message: dragTooltip,
            child: SizedBox(
              key: dragKey,
              width: actionSize,
              height: actionSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withValues(alpha: 0.18)),
                ),
                child:
                    dragHandle ??
                    Center(
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: accent,
                        size: 26,
                      ),
                    ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: removeTooltip,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: removeKey,
                borderRadius: BorderRadius.circular(999),
                onTap: onRemove,
                child: Ink(
                  width: actionSize,
                  height: actionSize,
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.74),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Icon(
                    Icons.remove_circle_outline_rounded,
                    size: 20,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

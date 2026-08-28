import 'package:flutter/material.dart';

import '../../../i18n/app_i18n.dart';
import '../../../state/app_state.dart';
import '../../module/module_access.dart';
import 'toolbox_page_models.dart';
import 'toolbox_ui_components.dart';
import 'toolbox_ui_tokens.dart';

class ToolboxQuickEntryPanel extends StatelessWidget {
  const ToolboxQuickEntryPanel({
    super.key,
    required this.i18n,
    required this.state,
    required this.quickEntries,
    required this.availableEntries,
    this.onOpenEntry,
  });

  final AppI18n i18n;
  final AppState state;
  final List<ToolboxEntryData> quickEntries;
  final List<ToolboxEntryData> availableEntries;
  final ValueChanged<ToolboxEntryData>? onOpenEntry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return _QuickEntryDragTarget(
      state: state,
      quickEntries: quickEntries,
      availableEntries: availableEntries,
      builder: (context, accepting) {
        return SizedBox(
          key: const ValueKey<String>('toolbox_quick_entry_drop_target'),
          width: double.infinity,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            child: ToolboxSurfaceCard(
              padding: const EdgeInsets.all(16),
              radius: ToolboxUiTokens.sectionPanelRadius,
              color: accepting
                  ? colorScheme.primaryContainer.withValues(alpha: 0.34)
                  : colorScheme.surfaceContainerLowest,
              borderColor: accepting
                  ? colorScheme.primary.withValues(alpha: 0.42)
                  : colorScheme.outlineVariant.withValues(alpha: 0.74),
              shadowColor: colorScheme.primary,
              shadowOpacity: accepting ? 0.08 : 0.04,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(
                            alpha: 0.58,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Icon(
                          accepting
                              ? Icons.add_task_rounded
                              : Icons.flash_on_rounded,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          accepting
                              ? i18n.t('toolbox.hub.quick.release_hint')
                              : i18n.t('toolbox.hub.quick.title'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        key: const ValueKey<String>(
                          'toolbox_manage_quick_entries',
                        ),
                        onPressed: availableEntries.isEmpty
                            ? null
                            : () => _showQuickEntrySheet(context),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(i18n.t('toolbox.hub.quick.manage')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (quickEntries.isEmpty)
                    Text(
                      i18n.t('toolbox.hub.quick.empty_hint'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        for (final entry in quickEntries)
                          _QuickEntryChip(
                            entry: entry,
                            state: state,
                            onOpenEntry: onOpenEntry,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showQuickEntrySheet(BuildContext context) {
    final availableIds = availableEntries
        .map((entry) => entry.moduleId)
        .toSet();
    final selected = <String>{
      for (final moduleId in state.toolboxLayoutState.quick)
        if (availableIds.contains(moduleId)) moduleId,
    };

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setModalState) {
            void saveAndClose() {
              state.setToolboxQuickEntries(
                availableEntries
                    .where((entry) => selected.contains(entry.moduleId))
                    .map((entry) => entry.moduleId)
                    .toList(growable: false),
              );
              Navigator.of(context).pop();
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      i18n.t('toolbox.hub.quick.choose_title'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      i18n.t('toolbox.hub.quick.choose_desc'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final entry in availableEntries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ToolboxSurfaceCard(
                          padding: EdgeInsets.zero,
                          radius: ToolboxUiTokens.cardRadius,
                          color: theme.colorScheme.surfaceContainerLowest,
                          borderColor: selected.contains(entry.moduleId)
                              ? entry.accent.withValues(alpha: 0.34)
                              : theme.colorScheme.outlineVariant,
                          shadowColor: entry.accent,
                          shadowOpacity: selected.contains(entry.moduleId)
                              ? 0.05
                              : 0,
                          child: Material(
                            color: Colors.transparent,
                            child: CheckboxListTile(
                              value: selected.contains(entry.moduleId),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              secondary: CircleAvatar(
                                backgroundColor: entry.accent.withValues(
                                  alpha: 0.16,
                                ),
                                foregroundColor: entry.accent,
                                child: Icon(entry.icon),
                              ),
                              title: Text(entry.title),
                              subtitle: Text(entry.subtitle),
                              onChanged: (value) {
                                setModalState(() {
                                  if (value == true) {
                                    selected.add(entry.moduleId);
                                  } else {
                                    selected.remove(entry.moduleId);
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: selected.isEmpty
                                ? null
                                : () {
                                    setModalState(selected.clear);
                                  },
                            icon: const Icon(Icons.clear_rounded),
                            label: Text(i18n.t('toolbox.hub.quick.clear')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            key: const ValueKey<String>(
                              'toolbox_save_quick_entries',
                            ),
                            onPressed: saveAndClose,
                            icon: const Icon(Icons.check_rounded),
                            label: Text(i18n.t('toolbox.hub.quick.save')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ToolboxQuickEntryDropOverlay extends StatelessWidget {
  const ToolboxQuickEntryDropOverlay({
    super.key,
    required this.i18n,
    required this.state,
    required this.quickEntries,
    required this.availableEntries,
  });

  final AppI18n i18n;
  final AppState state;
  final List<ToolboxEntryData> quickEntries;
  final List<ToolboxEntryData> availableEntries;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: ToolboxUiTokens.contentMaxWidth,
      ),
      child: _QuickEntryDragTarget(
        state: state,
        quickEntries: quickEntries,
        availableEntries: availableEntries,
        builder: (context, accepting) {
          return Material(
            key: const ValueKey<String>(
              'toolbox_quick_entry_floating_drop_target',
            ),
            color: colorScheme.surfaceContainerLowest,
            elevation: 8,
            shadowColor: colorScheme.shadow.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(
              ToolboxUiTokens.sectionPanelRadius,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: accepting
                    ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                    : colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(
                  ToolboxUiTokens.sectionPanelRadius,
                ),
                border: Border.all(
                  color: accepting
                      ? colorScheme.primary.withValues(alpha: 0.54)
                      : colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    accepting
                        ? Icons.add_task_rounded
                        : Icons.vertical_align_top_rounded,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      i18n.t('toolbox.hub.quick.release_hint'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickEntryDragTarget extends StatelessWidget {
  const _QuickEntryDragTarget({
    required this.state,
    required this.quickEntries,
    required this.availableEntries,
    required this.builder,
  });

  final AppState state;
  final List<ToolboxEntryData> quickEntries;
  final List<ToolboxEntryData> availableEntries;
  final Widget Function(BuildContext context, bool accepting) builder;

  @override
  Widget build(BuildContext context) {
    final quickIds = quickEntries.map((entry) => entry.moduleId).toSet();
    final availableIds = availableEntries
        .map((entry) => entry.moduleId)
        .toSet();
    return DragTarget<ToolboxEntryData>(
      onWillAcceptWithDetails: (details) =>
          availableIds.contains(details.data.moduleId) &&
          !quickIds.contains(details.data.moduleId),
      onAcceptWithDetails: (details) {
        state.setToolboxQuickEntries(<String>[
          for (final moduleId in state.toolboxLayoutState.quick)
            if (availableIds.contains(moduleId)) moduleId,
          details.data.moduleId,
        ]);
      },
      builder: (context, candidateData, rejectedData) =>
          builder(context, candidateData.isNotEmpty),
    );
  }
}

class _QuickEntryChip extends StatelessWidget {
  const _QuickEntryChip({
    required this.entry,
    required this.state,
    this.onOpenEntry,
  });

  final ToolboxEntryData entry;
  final AppState state;
  final ValueChanged<ToolboxEntryData>? onOpenEntry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(ToolboxUiTokens.pillRadius),
        onTap: () {
          final onOpenEntry = this.onOpenEntry;
          if (onOpenEntry != null) {
            onOpenEntry(entry);
            return;
          }
          pushModuleRoute<void>(
            context,
            state: state,
            moduleId: entry.moduleId,
            builder: (_) => entry.pageBuilder(),
          );
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: entry.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ToolboxUiTokens.pillRadius),
              border: Border.all(color: entry.accent.withValues(alpha: 0.22)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(entry.icon, size: 18, color: entry.accent),
                const SizedBox(width: 8),
                Text(
                  entry.title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

part of '../toolbox_life_tools.dart';

typedef _CalculatorHistoryPartCallback =
    void Function(
      ToolboxCalculatorHistoryEntry entry,
      ToolboxCalculatorResultPart part,
    );

class _CalculatorHistorySheet extends StatelessWidget {
  const _CalculatorHistorySheet({
    required this.session,
    required this.onRestoreExpression,
    required this.onUseResult,
    required this.onUsePart,
  });

  final ToolboxCalculatorSessionController session;
  final ValueChanged<ToolboxCalculatorHistoryEntry> onRestoreExpression;
  final ValueChanged<ToolboxCalculatorHistoryEntry> onUseResult;
  final _CalculatorHistoryPartCallback onUsePart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 8),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _lifeI18nText(
                        context,
                        'toolbox.life.advanced_calculator.history.group',
                      ),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: session.history.isEmpty
                        ? null
                        : session.clearHistory,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: Text(
                      _lifeI18nText(
                        context,
                        'toolbox.life.advanced_calculator.clear_history',
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            Expanded(
              child: AnimatedBuilder(
                animation: session,
                builder: (context, _) {
                  final history = session.history;
                  if (history.isEmpty) return const _CalculatorHistoryEmpty();
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
                    itemCount: history.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _CalculatorHistoryTile(
                        entry: history[index],
                        onRestoreExpression: () =>
                            onRestoreExpression(history[index]),
                        onUseResult: () => onUseResult(history[index]),
                        onUsePart: (part) => onUsePart(history[index], part),
                        onRemove: () =>
                            session.removeHistory(history[index].id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalculatorHistoryEmpty extends StatelessWidget {
  const _CalculatorHistoryEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.history_toggle_off_rounded,
              size: 42,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            Text(
              _lifeI18nText(
                context,
                'toolbox.life.advanced_calculator.history_empty',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CalculatorHistoryTile extends StatelessWidget {
  const _CalculatorHistoryTile({
    required this.entry,
    required this.onRestoreExpression,
    required this.onUseResult,
    required this.onUsePart,
    required this.onRemove,
  });

  final ToolboxCalculatorHistoryEntry entry;
  final VoidCallback onRestoreExpression;
  final VoidCallback onUseResult;
  final ValueChanged<ToolboxCalculatorResultPart> onUsePart;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final time = TimeOfDay.fromDateTime(entry.createdAt).format(context);
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onRestoreExpression,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _CalculatorHistoryOperationIcon(
                operation: entry.result.operation,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _lifeI18nText(
                              context,
                              _calculatorOperationKey(entry.result.operation),
                            ),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(time, style: theme.textTheme.labelSmall),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.expression,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.result.isComposite
                          ? _lifeI18nText(
                              context,
                              'toolbox.life.advanced_calculator.result_parts_count',
                              params: <String, Object?>{
                                'count': entry.result.parts.length,
                              },
                            )
                          : '= ${entry.result.exact}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.primary,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (entry.result.parts.isNotEmpty)
                      _CalculatorHistoryResultParts(
                        parts: entry.result.parts,
                        onUsePart: onUsePart,
                      ),
                  ],
                ),
              ),
              _CalculatorHistoryMenu(
                isComposite: entry.result.isComposite,
                onRestoreExpression: onRestoreExpression,
                onUseResult: onUseResult,
                onRemove: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalculatorHistoryOperationIcon extends StatelessWidget {
  const _CalculatorHistoryOperationIcon({required this.operation});

  final ToolboxCalculatorOperation operation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        _calculatorOperationIcon(operation),
        size: 18,
        color: colors.onPrimaryContainer,
      ),
    );
  }
}

class _CalculatorHistoryMenu extends StatelessWidget {
  const _CalculatorHistoryMenu({
    required this.isComposite,
    required this.onRestoreExpression,
    required this.onUseResult,
    required this.onRemove,
  });

  final bool isComposite;
  final VoidCallback onRestoreExpression;
  final VoidCallback onUseResult;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_CalculatorHistoryAction>(
      tooltip: MaterialLocalizations.of(context).showMenuTooltip,
      onSelected: (action) {
        switch (action) {
          case _CalculatorHistoryAction.restoreExpression:
            onRestoreExpression();
          case _CalculatorHistoryAction.useResult:
            onUseResult();
          case _CalculatorHistoryAction.remove:
            onRemove();
        }
      },
      itemBuilder: (context) => <PopupMenuEntry<_CalculatorHistoryAction>>[
        _item(
          context,
          _CalculatorHistoryAction.restoreExpression,
          'toolbox.life.advanced_calculator.restore_expression',
        ),
        if (!isComposite)
          _item(
            context,
            _CalculatorHistoryAction.useResult,
            'toolbox.life.advanced_calculator.use_result',
          ),
        _item(
          context,
          _CalculatorHistoryAction.remove,
          'toolbox.life.advanced_calculator.remove_history',
        ),
      ],
    );
  }

  PopupMenuItem<_CalculatorHistoryAction> _item(
    BuildContext context,
    _CalculatorHistoryAction value,
    String labelKey,
  ) {
    return PopupMenuItem<_CalculatorHistoryAction>(
      value: value,
      child: Text(_lifeI18nText(context, labelKey)),
    );
  }
}

class _CalculatorHistoryResultParts extends StatelessWidget {
  const _CalculatorHistoryResultParts({
    required this.parts,
    required this.onUsePart,
  });

  final List<ToolboxCalculatorResultPart> parts;
  final ValueChanged<ToolboxCalculatorResultPart> onUsePart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: parts
            .map(
              (part) => SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  key: ValueKey<String>(
                    'advanced_calculator_history_part_${part.id}',
                  ),
                  onPressed: () => onUsePart(part),
                  icon: const Icon(Icons.subdirectory_arrow_left_rounded),
                  label: Text(part.id),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

enum _CalculatorHistoryAction { restoreExpression, useResult, remove }

extension _CalculatorHistoryActions on _AdvancedCalculatorToolPageState {
  void _openHistorySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.82,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: _CalculatorHistorySheet(
              session: _session,
              onRestoreExpression: (entry) {
                Navigator.pop(sheetContext);
                _restoreHistoryEntry(entry);
              },
              onUseResult: (entry) {
                Navigator.pop(sheetContext);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  unawaited(
                    _continueRoutableResult(
                      exact: entry.result.exact,
                      type: entry.result.type,
                    ),
                  );
                });
              },
              onUsePart: (entry, part) {
                Navigator.pop(sheetContext);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  unawaited(
                    _continueRoutableResult(exact: part.exact, type: part.type),
                  );
                });
              },
            ),
          ),
        );
      },
    );
  }
}

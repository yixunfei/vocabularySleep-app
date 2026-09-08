part of '../toolbox_life_tools.dart';

class _CalculatorWorkspacePanel extends StatelessWidget {
  const _CalculatorWorkspacePanel({
    required this.expressionController,
    required this.expressionFocusNode,
    required this.undoController,
    required this.session,
    required this.onEvaluate,
    required this.onContinue,
    required this.onCopyPlain,
    required this.onCopyLatex,
    required this.onInsertMemory,
  });

  final TextEditingController expressionController;
  final FocusNode expressionFocusNode;
  final UndoHistoryController undoController;
  final ToolboxCalculatorSessionController session;
  final VoidCallback onEvaluate;
  final ValueChanged<ToolboxCalculatorResultPart?> onContinue;
  final ValueChanged<ToolboxCalculatorResultPart?> onCopyPlain;
  final ValueChanged<ToolboxCalculatorResultPart?> onCopyLatex;
  final VoidCallback onInsertMemory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _CalculatorWorkspaceHeader(session: session),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey<String>('advanced_calculator_expression'),
            controller: expressionController,
            focusNode: expressionFocusNode,
            undoController: undoController,
            minLines: 1,
            maxLines: 4,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              prefixIconConstraints: const BoxConstraints(
                minWidth: 96,
                minHeight: 48,
              ),
              prefixIcon: _CalculatorUndoControls(
                undoController: undoController,
              ),
              labelText: _lifeI18nText(
                context,
                'toolbox.life.advanced_calculator.expression',
              ),
              hintText: _lifeI18nText(
                context,
                'toolbox.life.advanced_calculator.expression_example',
              ),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.operation.evaluate',
                ),
                onPressed: session.isCalculating ? null : onEvaluate,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
            onSubmitted: (_) => onEvaluate(),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: colors.outlineVariant),
          const SizedBox(height: 14),
          _CalculatorResultStage(
            session: session,
            onContinue: onContinue,
            onCopyPlain: onCopyPlain,
            onCopyLatex: onCopyLatex,
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: colors.outlineVariant),
          const SizedBox(height: 8),
          _CalculatorMemoryStrip(
            session: session,
            onInsertMemory: onInsertMemory,
          ),
        ],
      ),
    );
  }
}

class _CalculatorUndoControls extends StatelessWidget {
  const _CalculatorUndoControls({required this.undoController});

  final UndoHistoryController undoController;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UndoHistoryValue>(
      valueListenable: undoController,
      builder: (context, value, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            key: const ValueKey<String>('advanced_calculator_undo'),
            tooltip: _lifeI18nText(
              context,
              'toolbox.life.advanced_calculator.undo',
            ),
            onPressed: value.canUndo ? undoController.undo : null,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            key: const ValueKey<String>('advanced_calculator_redo'),
            tooltip: _lifeI18nText(
              context,
              'toolbox.life.advanced_calculator.redo',
            ),
            onPressed: value.canRedo ? undoController.redo : null,
            icon: const Icon(Icons.redo_rounded),
          ),
        ],
      ),
    );
  }
}

class _CalculatorWorkspaceHeader extends StatelessWidget {
  const _CalculatorWorkspaceHeader({required this.session});

  final ToolboxCalculatorSessionController session;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final selector = _buildAngleSelector(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (constraints.maxWidth < 300) ...<Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: _CalculatorStatusChip(status: session.status),
              ),
              const SizedBox(height: 6),
              selector,
            ] else
              Row(
                children: <Widget>[
                  Expanded(
                    child: _CalculatorStatusChip(status: session.status),
                  ),
                  const SizedBox(width: 8),
                  selector,
                ],
              ),
            const SizedBox(height: 4),
            Text(
              _lifeI18nText(
                context,
                'toolbox.life.advanced_calculator.angle_semantics',
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAngleSelector(BuildContext context) {
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      segments: <ButtonSegment<bool>>[
        ButtonSegment<bool>(
          value: true,
          label: Text(
            _lifeI18nText(
              context,
              'toolbox.life.advanced_calculator.angle_degree',
            ),
          ),
        ),
        ButtonSegment<bool>(
          value: false,
          label: Text(
            _lifeI18nText(
              context,
              'toolbox.life.advanced_calculator.angle_radian',
            ),
          ),
        ),
      ],
      selected: <bool>{session.degreeMode},
      onSelectionChanged: (selection) {
        session.setDegreeMode(selection.first);
      },
      style: const ButtonStyle(
        visualDensity: VisualDensity(horizontal: -2, vertical: -1),
      ),
    );
  }
}

class _CalculatorResultStage extends StatelessWidget {
  const _CalculatorResultStage({
    required this.session,
    required this.onContinue,
    required this.onCopyPlain,
    required this.onCopyLatex,
  });

  final ToolboxCalculatorSessionController session;
  final ValueChanged<ToolboxCalculatorResultPart?> onContinue;
  final ValueChanged<ToolboxCalculatorResultPart?> onCopyPlain;
  final ValueChanged<ToolboxCalculatorResultPart?> onCopyLatex;

  @override
  Widget build(BuildContext context) {
    final child = switch (session.status) {
      ToolboxCalculatorSessionStatus.calculating =>
        const _CalculatorLoadingResult(),
      ToolboxCalculatorSessionStatus.error => _CalculatorErrorResult(
        error: session.error,
      ),
      ToolboxCalculatorSessionStatus.success => _CalculatorSuccessResult(
        result: session.result!,
        onContinue: onContinue,
        onCopyPlain: onCopyPlain,
        onCopyLatex: onCopyLatex,
      ),
      ToolboxCalculatorSessionStatus.idle => const _CalculatorIdleResult(),
    };
    return AnimatedSwitcher(
      duration: AppDurations.standard,
      switchInCurve: AppEasing.snappy,
      switchOutCurve: AppEasing.gentle,
      child: KeyedSubtree(key: ValueKey(session.status), child: child),
    );
  }
}

class _CalculatorIdleResult extends StatelessWidget {
  const _CalculatorIdleResult();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 84),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.calculate_outlined,
            color: theme.colorScheme.primary,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _lifeI18nText(
                context,
                'toolbox.life.advanced_calculator.result_empty',
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalculatorLoadingResult extends StatelessWidget {
  const _CalculatorLoadingResult();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 84),
      child: Row(
        children: <Widget>[
          const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _lifeI18nText(
                context,
                'toolbox.life.advanced_calculator.status.calculating',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalculatorErrorResult extends StatelessWidget {
  const _CalculatorErrorResult({required this.error});

  final ToolboxCalculatorEngineException? error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 84),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline_rounded, color: colors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _lifeI18nText(
                context,
                error?.i18nKey ??
                    'toolbox.life.advanced_calculator.error.computation',
              ),
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalculatorSuccessResult extends StatelessWidget {
  const _CalculatorSuccessResult({
    required this.result,
    required this.onContinue,
    required this.onCopyPlain,
    required this.onCopyLatex,
  });

  final ToolboxCalculatorResult result;
  final ValueChanged<ToolboxCalculatorResultPart?> onContinue;
  final ValueChanged<ToolboxCalculatorResultPart?> onCopyPlain;
  final ValueChanged<ToolboxCalculatorResultPart?> onCopyLatex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _CalculatorResultHeader(result: result),
        if (!result.isComposite) ...<Widget>[
          const SizedBox(height: 10),
          _CalculatorPrimaryResult(result: result),
        ],
        if (result.parts.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _CalculatorResultParts(
            parts: result.parts,
            onContinue: onContinue,
            onCopyPlain: onCopyPlain,
            onCopyLatex: onCopyLatex,
          ),
        ],
        if (result.unevaluated) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            _lifeI18nText(
              context,
              'toolbox.life.advanced_calculator.result_unevaluated',
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
        ],
        const SizedBox(height: 10),
        _CalculatorResultActions(
          showContinue: !result.isComposite,
          onContinue: () => onContinue(null),
          onCopyPlain: () => onCopyPlain(null),
          onCopyLatex: () => onCopyLatex(null),
        ),
      ],
    );
  }
}

class _CalculatorStatusChip extends StatelessWidget {
  const _CalculatorStatusChip({required this.status});

  final ToolboxCalculatorSessionStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, key, color) = switch (status) {
      ToolboxCalculatorSessionStatus.idle => (
        Icons.edit_rounded,
        'toolbox.life.advanced_calculator.status.ready',
        theme.colorScheme.primary,
      ),
      ToolboxCalculatorSessionStatus.calculating => (
        Icons.hourglass_top_rounded,
        'toolbox.life.advanced_calculator.status.calculating',
        theme.colorScheme.tertiary,
      ),
      ToolboxCalculatorSessionStatus.success => (
        Icons.check_circle_outline_rounded,
        'toolbox.life.advanced_calculator.status.success',
        theme.colorScheme.primary,
      ),
      ToolboxCalculatorSessionStatus.error => (
        Icons.error_outline_rounded,
        'toolbox.life.advanced_calculator.status.error',
        theme.colorScheme.error,
      ),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            _lifeI18nText(context, key),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _CalculatorBackendPill extends StatelessWidget {
  const _CalculatorBackendPill({required this.backend});

  final ToolboxCalculatorBackend backend;

  @override
  Widget build(BuildContext context) {
    final labelKey = switch (backend) {
      ToolboxCalculatorBackend.nerdamerPrime =>
        'toolbox.life.advanced_calculator.backend.nerdamer',
      ToolboxCalculatorBackend.algebrite =>
        'toolbox.life.advanced_calculator.backend.algebrite',
      ToolboxCalculatorBackend.numeric =>
        'toolbox.life.advanced_calculator.backend.numeric',
      ToolboxCalculatorBackend.unknown =>
        'toolbox.life.advanced_calculator.backend.cas',
    };
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _lifeI18nText(context, labelKey),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.onTertiaryContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CalculatorMemoryStrip extends StatelessWidget {
  const _CalculatorMemoryStrip({
    required this.session,
    required this.onInsertMemory,
  });

  final ToolboxCalculatorSessionController session;
  final VoidCallback onInsertMemory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final memory = session.memoryExpression;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            _lifeI18nText(
              context,
              'toolbox.life.advanced_calculator.memory_value',
              params: <String, Object?>{'value': memory ?? '-'},
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        _CalculatorMemoryButton(
          label: 'MS',
          tooltipKey: 'toolbox.life.advanced_calculator.memory_store',
          onPressed: session.result == null ? null : session.storeMemory,
        ),
        _CalculatorMemoryButton(
          label: 'MR',
          tooltipKey: 'toolbox.life.advanced_calculator.memory_recall',
          onPressed: memory == null ? null : onInsertMemory,
        ),
        _CalculatorMemoryButton(
          label: 'MC',
          tooltipKey: 'toolbox.life.advanced_calculator.memory_clear',
          onPressed: memory == null ? null : session.clearMemory,
        ),
      ],
    );
  }
}

class _CalculatorMemoryButton extends StatelessWidget {
  const _CalculatorMemoryButton({
    required this.label,
    required this.tooltipKey,
    required this.onPressed,
  });

  final String label;
  final String tooltipKey;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _lifeI18nText(context, tooltipKey),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Text(label),
      ),
    );
  }
}

class _CalculatorCommandBar extends StatelessWidget {
  const _CalculatorCommandBar({
    required this.onOpenDefinitions,
    required this.onOpenCatalog,
    required this.onOpenTools,
    required this.onOpenHistory,
  });

  final VoidCallback onOpenDefinitions;
  final VoidCallback onOpenCatalog;
  final VoidCallback onOpenTools;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _compactAction(
                context,
                key: 'advanced_calculator_catalog_command',
                tooltipKey: 'toolbox.life.advanced_calculator.catalog.title',
                icon: Icons.menu_book_rounded,
                onPressed: onOpenCatalog,
              ),
              _compactAction(
                context,
                key: 'advanced_calculator_definitions_action',
                tooltipKey:
                    'toolbox.life.advanced_calculator.definition.manage',
                icon: Icons.data_object_rounded,
                onPressed: onOpenDefinitions,
              ),
              _compactAction(
                context,
                key: 'advanced_calculator_open_tools',
                tooltipKey: 'toolbox.life.advanced_calculator.tools',
                icon: Icons.functions_rounded,
                onPressed: onOpenTools,
              ),
              _compactAction(
                context,
                key: 'advanced_calculator_history_command',
                tooltipKey: 'toolbox.life.advanced_calculator.history.group',
                icon: Icons.history_rounded,
                onPressed: onOpenHistory,
              ),
            ],
          );
        }
        final itemWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 8,
          children: <Widget>[
            _labeledAction(
              context,
              width: itemWidth,
              key: 'advanced_calculator_definitions_action',
              labelKey: 'toolbox.life.advanced_calculator.definition.manage',
              icon: Icons.data_object_rounded,
              onPressed: onOpenDefinitions,
            ),
            _labeledAction(
              context,
              width: itemWidth,
              key: 'advanced_calculator_catalog_command',
              labelKey: 'toolbox.life.advanced_calculator.catalog.title',
              icon: Icons.menu_book_rounded,
              onPressed: onOpenCatalog,
            ),
            _labeledAction(
              context,
              width: itemWidth,
              key: 'advanced_calculator_open_tools',
              labelKey: 'toolbox.life.advanced_calculator.tools',
              icon: Icons.functions_rounded,
              onPressed: onOpenTools,
              filled: true,
            ),
            _labeledAction(
              context,
              width: itemWidth,
              key: 'advanced_calculator_history_command',
              labelKey: 'toolbox.life.advanced_calculator.history.group',
              icon: Icons.history_rounded,
              onPressed: onOpenHistory,
            ),
          ],
        );
      },
    );
  }

  Widget _compactAction(
    BuildContext context, {
    required String key,
    required String tooltipKey,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton.filledTonal(
      key: ValueKey<String>(key),
      tooltip: _lifeI18nText(context, tooltipKey),
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }

  Widget _labeledAction(
    BuildContext context, {
    required double width,
    required String key,
    required String labelKey,
    required IconData icon,
    required VoidCallback onPressed,
    bool filled = false,
  }) {
    final label = Text(
      _lifeI18nText(context, labelKey),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
    return SizedBox(
      width: width,
      height: 52,
      child: filled
          ? FilledButton.icon(
              key: ValueKey<String>(key),
              onPressed: onPressed,
              icon: Icon(icon),
              label: label,
            )
          : OutlinedButton.icon(
              key: ValueKey<String>(key),
              onPressed: onPressed,
              icon: Icon(icon),
              label: label,
            ),
    );
  }
}

extension _CalculatorClipboardActions on _AdvancedCalculatorToolPageState {
  Future<void> _copyResult({
    required bool latex,
    ToolboxCalculatorResultPart? part,
  }) async {
    final result = _session.result;
    if (result == null) return;
    final exact = part?.exact ?? result.exact;
    final partLatex = part?.latex ?? result.latex;
    final text = latex && partLatex.isNotEmpty ? partLatex : exact;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _lifeI18nText(context, 'toolbox.life.advanced_calculator.copied'),
        ),
      ),
    );
  }
}

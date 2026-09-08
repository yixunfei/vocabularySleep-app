part of '../toolbox_life_tools.dart';

class _CalculatorResultHeader extends StatelessWidget {
  const _CalculatorResultHeader({required this.result});

  final ToolboxCalculatorResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            _lifeI18nText(
              context,
              result.isComposite
                  ? 'toolbox.life.advanced_calculator.structured_result'
                  : 'toolbox.life.advanced_calculator.exact_result',
            ),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _CalculatorBackendPill(backend: result.backend),
      ],
    );
  }
}

class _CalculatorPrimaryResult extends StatelessWidget {
  const _CalculatorPrimaryResult({required this.result});

  final ToolboxCalculatorResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 54),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Center(
              child: Math.tex(
                result.latex.isEmpty ? result.exact : result.latex,
                mathStyle: MathStyle.display,
                textStyle: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                onErrorFallback: (_) => SelectableText(
                  result.exact,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        ),
        if (result.hasApproximation) ...<Widget>[
          const SizedBox(height: 8),
          _CalculatorApproximation(value: result.approximate!),
        ],
      ],
    );
  }
}

class _CalculatorResultParts extends StatelessWidget {
  const _CalculatorResultParts({
    required this.parts,
    required this.onContinue,
    required this.onCopyPlain,
    required this.onCopyLatex,
  });

  final List<ToolboxCalculatorResultPart> parts;
  final ValueChanged<ToolboxCalculatorResultPart?> onContinue;
  final ValueChanged<ToolboxCalculatorResultPart?> onCopyPlain;
  final ValueChanged<ToolboxCalculatorResultPart?> onCopyLatex;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          _lifeI18nText(
            context,
            'toolbox.life.advanced_calculator.result_parts',
          ),
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        for (final part in parts) ...<Widget>[
          Divider(height: 1, color: colors.outlineVariant),
          _CalculatorResultPartRow(
            part: part,
            onContinue: () => onContinue(part),
            onCopyPlain: () => onCopyPlain(part),
            onCopyLatex: () => onCopyLatex(part),
          ),
        ],
        Divider(height: 1, color: colors.outlineVariant),
      ],
    );
  }
}

class _CalculatorResultPartRow extends StatelessWidget {
  const _CalculatorResultPartRow({
    required this.part,
    required this.onContinue,
    required this.onCopyPlain,
    required this.onCopyLatex,
  });

  final ToolboxCalculatorResultPart part;
  final VoidCallback onContinue;
  final VoidCallback onCopyPlain;
  final VoidCallback onCopyLatex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: ValueKey<String>('advanced_calculator_result_part_${part.id}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  part.id,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                key: ValueKey<String>(
                  'advanced_calculator_result_part_copy_${part.id}',
                ),
                tooltip: _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.copy_plain',
                ),
                onPressed: onCopyPlain,
                icon: const Icon(Icons.copy_rounded),
              ),
              IconButton(
                key: ValueKey<String>(
                  'advanced_calculator_result_part_latex_${part.id}',
                ),
                tooltip: _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.copy_latex',
                ),
                onPressed: onCopyLatex,
                icon: const Icon(Icons.code_rounded),
              ),
              IconButton.filledTonal(
                key: ValueKey<String>(
                  'advanced_calculator_result_part_continue_${part.id}',
                ),
                tooltip: _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.continue_result',
                ),
                onPressed: onContinue,
                icon: const Icon(Icons.subdirectory_arrow_left_rounded),
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Math.tex(
              part.latex.isEmpty ? part.exact : part.latex,
              mathStyle: MathStyle.display,
              textStyle: theme.textTheme.titleLarge,
              onErrorFallback: (_) => SelectableText(
                part.exact,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          if (part.hasApproximation) ...<Widget>[
            const SizedBox(height: 4),
            _CalculatorApproximation(value: part.approximate!),
          ],
        ],
      ),
    );
  }
}

class _CalculatorApproximation extends StatelessWidget {
  const _CalculatorApproximation({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      _lifeI18nText(
        context,
        'toolbox.life.advanced_calculator.approximate_result',
        params: <String, Object?>{'value': value},
      ),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontFeatures: const <ui.FontFeature>[ui.FontFeature.tabularFigures()],
      ),
    );
  }
}

class _CalculatorResultActions extends StatelessWidget {
  const _CalculatorResultActions({
    required this.showContinue,
    required this.onContinue,
    required this.onCopyPlain,
    required this.onCopyLatex,
  });

  final bool showContinue;
  final VoidCallback onContinue;
  final VoidCallback onCopyPlain;
  final VoidCallback onCopyLatex;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: <Widget>[
        IconButton.filledTonal(
          tooltip: _lifeI18nText(
            context,
            'toolbox.life.advanced_calculator.copy_plain',
          ),
          onPressed: onCopyPlain,
          icon: const Icon(Icons.copy_rounded),
        ),
        IconButton.filledTonal(
          tooltip: _lifeI18nText(
            context,
            'toolbox.life.advanced_calculator.copy_latex',
          ),
          onPressed: onCopyLatex,
          icon: const Icon(Icons.code_rounded),
        ),
        if (showContinue)
          FilledButton.tonalIcon(
            onPressed: onContinue,
            icon: const Icon(Icons.subdirectory_arrow_left_rounded),
            label: Text(
              _lifeI18nText(
                context,
                'toolbox.life.advanced_calculator.continue_result',
              ),
            ),
          ),
      ],
    );
  }
}

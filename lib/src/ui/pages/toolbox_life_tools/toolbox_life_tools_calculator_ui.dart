part of '../toolbox_life_tools.dart';

class _CalculatorActionSpec<T> {
  const _CalculatorActionSpec({
    required this.value,
    required this.labelKey,
    required this.icon,
  });

  final T value;
  final String labelKey;
  final IconData icon;
}

_CalculatorActionSpec<ToolboxCalculatorOperation> _calculatorEngineAction(
  ToolboxCalculatorOperation operation,
) {
  return _CalculatorActionSpec<ToolboxCalculatorOperation>(
    value: operation,
    labelKey: _calculatorOperationKey(operation),
    icon: _calculatorOperationIcon(operation),
  );
}

IconData _calculatorOperationIcon(ToolboxCalculatorOperation operation) {
  return switch (operation) {
    ToolboxCalculatorOperation.evaluate => Icons.calculate_rounded,
    ToolboxCalculatorOperation.approximate => Icons.tune_rounded,
    ToolboxCalculatorOperation.simplify => Icons.auto_fix_high_rounded,
    ToolboxCalculatorOperation.expand => Icons.open_in_full_rounded,
    ToolboxCalculatorOperation.factor => Icons.account_tree_outlined,
    ToolboxCalculatorOperation.partialFraction => Icons.call_split_rounded,
    ToolboxCalculatorOperation.substitute => Icons.find_replace_rounded,
    ToolboxCalculatorOperation.solveEquation => Icons.rule_rounded,
    ToolboxCalculatorOperation.solveSystem =>
      Icons.format_list_numbered_rounded,
    ToolboxCalculatorOperation.differentiate => Icons.show_chart_rounded,
    ToolboxCalculatorOperation.integrate => Icons.area_chart_rounded,
    ToolboxCalculatorOperation.definiteIntegral =>
      Icons.stacked_line_chart_rounded,
    ToolboxCalculatorOperation.limit =>
      Icons.keyboard_double_arrow_right_rounded,
    ToolboxCalculatorOperation.taylor => Icons.multiline_chart_rounded,
    ToolboxCalculatorOperation.summation => Icons.functions_rounded,
    ToolboxCalculatorOperation.product => Icons.close_fullscreen_rounded,
    ToolboxCalculatorOperation.laplace => Icons.swap_horiz_rounded,
    ToolboxCalculatorOperation.inverseLaplace => Icons.swap_horiz_rounded,
    ToolboxCalculatorOperation.gradient => Icons.trending_up_rounded,
    ToolboxCalculatorOperation.divergence => Icons.call_made_rounded,
    ToolboxCalculatorOperation.curl => Icons.rotate_right_rounded,
    ToolboxCalculatorOperation.hessian => Icons.grid_4x4_rounded,
    ToolboxCalculatorOperation.matrixAdd => Icons.add_box_outlined,
    ToolboxCalculatorOperation.matrixSubtract =>
      Icons.indeterminate_check_box_outlined,
    ToolboxCalculatorOperation.matrixMultiply => Icons.grid_goldenratio_rounded,
    ToolboxCalculatorOperation.scalarMultiply => Icons.tag_rounded,
    ToolboxCalculatorOperation.matrixPower => Icons.superscript_rounded,
    ToolboxCalculatorOperation.determinant => Icons.grid_on_rounded,
    ToolboxCalculatorOperation.inverse => Icons.flip_to_back_rounded,
    ToolboxCalculatorOperation.transpose => Icons.swap_vert_rounded,
    ToolboxCalculatorOperation.trace => Icons.timeline_rounded,
    ToolboxCalculatorOperation.rank => Icons.format_list_numbered_rtl_rounded,
    ToolboxCalculatorOperation.rref => Icons.table_rows_rounded,
    ToolboxCalculatorOperation.solveLinearSystem => Icons.rule_folder_rounded,
    ToolboxCalculatorOperation.characteristicPolynomial =>
      Icons.polyline_rounded,
    ToolboxCalculatorOperation.eigenvalues => Icons.data_object_rounded,
    ToolboxCalculatorOperation.eigenvectors => Icons.arrow_outward_rounded,
    ToolboxCalculatorOperation.nullSpace => Icons.space_bar_rounded,
    ToolboxCalculatorOperation.columnSpace => Icons.view_column_rounded,
    ToolboxCalculatorOperation.rowSpace => Icons.table_rows_rounded,
    ToolboxCalculatorOperation.luDecomposition => Icons.call_split_rounded,
    ToolboxCalculatorOperation.qrDecomposition => Icons.grid_view_rounded,
    ToolboxCalculatorOperation.leastSquares => Icons.scatter_plot_rounded,
    ToolboxCalculatorOperation.gramSchmidt => Icons.straighten_rounded,
    ToolboxCalculatorOperation.dotProduct => Icons.circle_outlined,
    ToolboxCalculatorOperation.crossProduct => Icons.close_rounded,
    ToolboxCalculatorOperation.vectorNorm => Icons.square_foot_rounded,
    ToolboxCalculatorOperation.vectorProjection => Icons.compress_rounded,
    ToolboxCalculatorOperation.complexRealPart => Icons.looks_one_outlined,
    ToolboxCalculatorOperation.complexImaginaryPart => Icons.looks_two_outlined,
    ToolboxCalculatorOperation.complexConjugate => Icons.compare_arrows_rounded,
    ToolboxCalculatorOperation.complexMagnitude => Icons.speed_rounded,
    ToolboxCalculatorOperation.complexArgument => Icons.rotate_right_rounded,
    ToolboxCalculatorOperation.complexPolarForm => Icons.radar_rounded,
    ToolboxCalculatorOperation.complexRectangularForm => Icons.grid_3x3_rounded,
    ToolboxCalculatorOperation.complexFromPolar => Icons.my_location_rounded,
  };
}

class _CalculatorCategorySelector extends StatelessWidget {
  const _CalculatorCategorySelector({
    required this.value,
    required this.onChanged,
  });

  final _CalculatorToolCategory value;
  final ValueChanged<_CalculatorToolCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _CalculatorToolCategory.values
            .map(
              (category) => ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 48,
                  maxWidth: constraints.maxWidth,
                ),
                child: ChoiceChip(
                  selected: category == value,
                  showCheckmark: false,
                  label: Text(
                    _lifeI18nText(context, _calculatorCategoryKey(category)),
                    maxLines: 2,
                  ),
                  onSelected: (_) => onChanged(category),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _CalculatorActionGrid<T> extends StatelessWidget {
  const _CalculatorActionGrid({
    required this.actions,
    required this.onSelected,
    this.highlighted,
  });

  final List<_CalculatorActionSpec<T>> actions;
  final ValueChanged<T> onSelected;
  final T? highlighted;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final itemWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: actions
              .map((action) {
                final selected = action.value == highlighted;
                return SizedBox(
                  width: itemWidth,
                  child: selected
                      ? FilledButton.tonalIcon(
                          onPressed: () => onSelected(action.value),
                          icon: Icon(action.icon, size: 19),
                          label: _actionLabel(context, action.labelKey),
                        )
                      : OutlinedButton.icon(
                          onPressed: () => onSelected(action.value),
                          icon: Icon(action.icon, size: 19),
                          label: _actionLabel(context, action.labelKey),
                        ),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }

  Widget _actionLabel(BuildContext context, String key) {
    return Text(
      _lifeI18nText(context, key),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }
}

class _CalculatorSheetSectionTitle extends StatelessWidget {
  const _CalculatorSheetSectionTitle({
    required this.titleKey,
    required this.icon,
    this.subtitleKey,
  });

  final String titleKey;
  final String? subtitleKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 19,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _lifeI18nText(context, titleKey),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subtitleKey != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  _lifeI18nText(context, subtitleKey!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CalculatorToolField extends StatelessWidget {
  const _CalculatorToolField({
    required this.controller,
    required this.labelKey,
    this.helperKey,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String labelKey;
  final String? helperKey;
  final int minLines;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: _lifeI18nText(context, labelKey),
        helperText: helperKey == null
            ? null
            : _lifeI18nText(context, helperKey!),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _CalculatorInlineError extends StatelessWidget {
  const _CalculatorInlineError();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _lifeI18nText(
          context,
          'toolbox.life.advanced_calculator.error.invalid_input',
        ),
        style: TextStyle(color: colors.onErrorContainer),
      ),
    );
  }
}

part of '../toolbox_life_tools.dart';

extension _CalculatorAnalysisToolViews on _CalculatorToolSheetState {
  Widget _buildAlgebraTools(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _CalculatorSheetSectionTitle(
          titleKey: 'toolbox.life.advanced_calculator.section.algebra',
          subtitleKey: 'toolbox.life.advanced_calculator.section.algebra_hint',
          icon: Icons.auto_fix_high_rounded,
        ),
        const SizedBox(height: 12),
        _CalculatorToolField(
          controller: draft.variable,
          labelKey: 'toolbox.life.advanced_calculator.variable',
        ),
        const SizedBox(height: 10),
        _CalculatorActionGrid<ToolboxCalculatorOperation>(
          highlighted: widget.initialOperation,
          actions: <ToolboxCalculatorOperation>[
            ToolboxCalculatorOperation.approximate,
            ToolboxCalculatorOperation.simplify,
            ToolboxCalculatorOperation.expand,
            ToolboxCalculatorOperation.factor,
            ToolboxCalculatorOperation.partialFraction,
            ToolboxCalculatorOperation.solveEquation,
          ].map(_calculatorEngineAction).toList(growable: false),
          onSelected: _runAlgebraOperation,
        ),
        const SizedBox(height: 22),
        const _CalculatorSheetSectionTitle(
          titleKey: 'toolbox.life.advanced_calculator.operation.substitute',
          subtitleKey: 'toolbox.life.advanced_calculator.substitutions_helper',
          icon: Icons.find_replace_rounded,
        ),
        const SizedBox(height: 10),
        _CalculatorToolField(
          controller: draft.substitutions,
          labelKey: 'toolbox.life.advanced_calculator.substitutions',
          helperKey: 'toolbox.life.advanced_calculator.substitutions_helper',
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: _runSubstitution,
          icon: const Icon(Icons.find_replace_rounded),
          label: Text(
            _lifeI18nText(
              context,
              'toolbox.life.advanced_calculator.operation.substitute',
            ),
          ),
        ),
        const SizedBox(height: 22),
        const _CalculatorSheetSectionTitle(
          titleKey: 'toolbox.life.advanced_calculator.operation.solve_system',
          subtitleKey: 'toolbox.life.advanced_calculator.equations_helper',
          icon: Icons.format_list_numbered_rounded,
        ),
        const SizedBox(height: 10),
        _CalculatorToolField(
          controller: draft.equations,
          labelKey: 'toolbox.life.advanced_calculator.equations',
          minLines: 2,
          maxLines: 5,
        ),
        const SizedBox(height: 10),
        _CalculatorToolField(
          controller: draft.variables,
          labelKey: 'toolbox.life.advanced_calculator.variables',
          helperKey: 'toolbox.life.advanced_calculator.variables_helper',
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: _runEquationSystem,
          icon: const Icon(Icons.rule_rounded),
          label: Text(
            _lifeI18nText(
              context,
              'toolbox.life.advanced_calculator.operation.solve_system',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalculusTools(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _CalculatorSheetSectionTitle(
          titleKey: 'toolbox.life.advanced_calculator.section.calculus',
          subtitleKey: 'toolbox.life.advanced_calculator.section.calculus_hint',
          icon: Icons.area_chart_rounded,
        ),
        const SizedBox(height: 12),
        _buildCalculusParameters(context),
        const SizedBox(height: 12),
        _CalculatorActionGrid<ToolboxCalculatorOperation>(
          highlighted: widget.initialOperation,
          actions: <ToolboxCalculatorOperation>[
            ToolboxCalculatorOperation.differentiate,
            ToolboxCalculatorOperation.integrate,
            ToolboxCalculatorOperation.definiteIntegral,
            ToolboxCalculatorOperation.limit,
            ToolboxCalculatorOperation.taylor,
            ToolboxCalculatorOperation.summation,
            ToolboxCalculatorOperation.product,
            ToolboxCalculatorOperation.laplace,
            ToolboxCalculatorOperation.inverseLaplace,
          ].map(_calculatorEngineAction).toList(growable: false),
          onSelected: _runCalculusOperation,
        ),
        const SizedBox(height: 22),
        const _CalculatorSheetSectionTitle(
          titleKey: 'toolbox.life.advanced_calculator.section.multivariable',
          subtitleKey:
              'toolbox.life.advanced_calculator.section.multivariable_hint',
          icon: Icons.grid_4x4_rounded,
        ),
        const SizedBox(height: 10),
        _CalculatorToolField(
          controller: draft.multiVariables,
          labelKey: 'toolbox.life.advanced_calculator.variables',
          helperKey: 'toolbox.life.advanced_calculator.variables_helper',
        ),
        const SizedBox(height: 10),
        _CalculatorToolField(
          controller: draft.vectorFunctions,
          labelKey: 'toolbox.life.advanced_calculator.vector_components',
          helperKey:
              'toolbox.life.advanced_calculator.vector_components_helper',
          minLines: 2,
          maxLines: 4,
        ),
        const SizedBox(height: 10),
        _CalculatorActionGrid<ToolboxCalculatorOperation>(
          highlighted: widget.initialOperation,
          actions: <ToolboxCalculatorOperation>[
            ToolboxCalculatorOperation.gradient,
            ToolboxCalculatorOperation.divergence,
            ToolboxCalculatorOperation.curl,
            ToolboxCalculatorOperation.hessian,
          ].map(_calculatorEngineAction).toList(growable: false),
          onSelected: _runMultivariableOperation,
        ),
      ],
    );
  }

  Widget _buildCalculusParameters(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _CalculatorToolField(
                controller: draft.variable,
                labelKey: 'toolbox.life.advanced_calculator.variable',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CalculatorToolField(
                controller: draft.order,
                labelKey: 'toolbox.life.advanced_calculator.order',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CalculatorToolField(
                controller: draft.point,
                labelKey: 'toolbox.life.advanced_calculator.point',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _CalculatorToolField(
                controller: draft.lowerBound,
                labelKey: 'toolbox.life.advanced_calculator.lower',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CalculatorToolField(
                controller: draft.upperBound,
                labelKey: 'toolbox.life.advanced_calculator.upper',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CalculatorToolField(
                controller: draft.targetVariable,
                labelKey: 'toolbox.life.advanced_calculator.target_variable',
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _runAlgebraOperation(ToolboxCalculatorOperation operation) {
    if (!_hasExpression()) return;
    final variable = draft.variable.text.trim();
    runRequest(
      ToolboxCalculatorRequest(
        operation: operation,
        expression: expression,
        variable: variable,
      ),
    );
  }

  void _runSubstitution() {
    if (!_hasExpression()) return;
    try {
      runRequest(
        ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.substitute,
          expression: expression,
          substitutions: draft.substitutionMap(),
        ),
      );
    } on FormatException {
      showDraftError();
    }
  }

  void _runEquationSystem() {
    final equations = draft.equationList();
    final variables = draft.csv(draft.variables);
    if (equations.isEmpty || variables.isEmpty) {
      showDraftError();
      return;
    }
    runRequest(
      ToolboxCalculatorRequest(
        operation: ToolboxCalculatorOperation.solveSystem,
        equations: equations,
        variables: variables,
      ),
      detail: equations.join('; '),
    );
  }

  void _runCalculusOperation(ToolboxCalculatorOperation operation) {
    if (!_hasExpression()) return;
    try {
      final order = operation == ToolboxCalculatorOperation.taylor
          ? draft.integer(draft.order, min: 0, max: 30)
          : draft.integer(draft.order, min: 1, max: 20);
      runRequest(
        ToolboxCalculatorRequest(
          operation: operation,
          expression: expression,
          variable: draft.variable.text.trim(),
          targetVariable: draft.targetVariable.text.trim(),
          lowerBound: draft.lowerBound.text.trim(),
          upperBound: draft.upperBound.text.trim(),
          point: draft.point.text.trim(),
          order: order,
        ),
      );
    } on FormatException {
      showDraftError();
    }
  }

  void _runMultivariableOperation(ToolboxCalculatorOperation operation) {
    if (!_hasExpression() &&
        operation != ToolboxCalculatorOperation.divergence &&
        operation != ToolboxCalculatorOperation.curl) {
      return;
    }
    final variables = draft.csv(draft.multiVariables);
    final expressions = draft.csv(draft.vectorFunctions);
    if (variables.isEmpty ||
        ((operation == ToolboxCalculatorOperation.divergence ||
                operation == ToolboxCalculatorOperation.curl) &&
            expressions.isEmpty)) {
      showDraftError();
      return;
    }
    runRequest(
      ToolboxCalculatorRequest(
        operation: operation,
        expression: expression,
        expressions: expressions,
        variables: variables,
      ),
    );
  }

  bool _hasExpression() {
    if (expression.isNotEmpty) return true;
    showDraftError();
    return false;
  }
}

part of '../toolbox_life_tools.dart';

extension _CalculatorLinearToolViews on _CalculatorToolSheetState {
  Widget _buildLinearTools(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _CalculatorSheetSectionTitle(
          titleKey: 'toolbox.life.advanced_calculator.section.linear',
          subtitleKey: 'toolbox.life.advanced_calculator.section.linear_hint',
          icon: Icons.grid_on_rounded,
        ),
        const SizedBox(height: 12),
        _CalculatorMatrixEditor(
          label: _lifeI18nText(
            context,
            'toolbox.life.advanced_calculator.matrix_a',
          ),
          draft: draft.matrixA,
        ),
        const SizedBox(height: 18),
        Divider(color: Theme.of(context).colorScheme.outlineVariant),
        const SizedBox(height: 12),
        _CalculatorMatrixEditor(
          label: _lifeI18nText(
            context,
            'toolbox.life.advanced_calculator.matrix_b',
          ),
          draft: draft.matrixB,
        ),
        const SizedBox(height: 14),
        _buildLinearParameters(),
        const SizedBox(height: 12),
        _CalculatorActionGrid<ToolboxCalculatorOperation>(
          highlighted: widget.initialOperation,
          actions: <ToolboxCalculatorOperation>[
            ToolboxCalculatorOperation.matrixAdd,
            ToolboxCalculatorOperation.matrixSubtract,
            ToolboxCalculatorOperation.matrixMultiply,
            ToolboxCalculatorOperation.scalarMultiply,
            ToolboxCalculatorOperation.matrixPower,
            ToolboxCalculatorOperation.determinant,
            ToolboxCalculatorOperation.inverse,
            ToolboxCalculatorOperation.transpose,
            ToolboxCalculatorOperation.trace,
            ToolboxCalculatorOperation.rank,
            ToolboxCalculatorOperation.rref,
            ToolboxCalculatorOperation.solveLinearSystem,
            ToolboxCalculatorOperation.characteristicPolynomial,
            ToolboxCalculatorOperation.eigenvalues,
            ToolboxCalculatorOperation.eigenvectors,
          ].map(_calculatorEngineAction).toList(growable: false),
          onSelected: _runLinearOperation,
        ),
        _buildAdvancedLinearTools(),
        const SizedBox(height: 22),
        const _CalculatorSheetSectionTitle(
          titleKey: 'toolbox.life.advanced_calculator.section.vector',
          subtitleKey: 'toolbox.life.advanced_calculator.section.vector_hint',
          icon: Icons.arrow_outward_rounded,
        ),
        const SizedBox(height: 10),
        _CalculatorToolField(
          controller: draft.vectorA,
          labelKey: 'toolbox.life.advanced_calculator.vector_a',
        ),
        const SizedBox(height: 8),
        _CalculatorToolField(
          controller: draft.vectorB,
          labelKey: 'toolbox.life.advanced_calculator.vector_b',
        ),
        const SizedBox(height: 10),
        _CalculatorActionGrid<ToolboxCalculatorOperation>(
          highlighted: widget.initialOperation,
          actions: <ToolboxCalculatorOperation>[
            ToolboxCalculatorOperation.dotProduct,
            ToolboxCalculatorOperation.crossProduct,
            ToolboxCalculatorOperation.vectorNorm,
            ToolboxCalculatorOperation.vectorProjection,
          ].map(_calculatorEngineAction).toList(growable: false),
          onSelected: _runLinearOperation,
        ),
      ],
    );
  }

  Widget _buildAdvancedLinearTools() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 22),
        const _CalculatorSheetSectionTitle(
          titleKey: 'toolbox.life.advanced_calculator.section.linear_advanced',
          subtitleKey:
              'toolbox.life.advanced_calculator.section.linear_advanced_hint',
          icon: Icons.account_tree_outlined,
        ),
        const SizedBox(height: 10),
        _CalculatorActionGrid<ToolboxCalculatorOperation>(
          highlighted: widget.initialOperation,
          actions: <ToolboxCalculatorOperation>[
            ToolboxCalculatorOperation.nullSpace,
            ToolboxCalculatorOperation.columnSpace,
            ToolboxCalculatorOperation.rowSpace,
            ToolboxCalculatorOperation.luDecomposition,
            ToolboxCalculatorOperation.qrDecomposition,
            ToolboxCalculatorOperation.leastSquares,
            ToolboxCalculatorOperation.gramSchmidt,
          ].map(_calculatorEngineAction).toList(growable: false),
          onSelected: _runLinearOperation,
        ),
      ],
    );
  }

  Widget _buildLinearParameters() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _CalculatorToolField(
            controller: draft.scalar,
            labelKey: 'toolbox.life.advanced_calculator.scalar',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CalculatorToolField(
            controller: draft.order,
            labelKey: 'toolbox.life.advanced_calculator.order',
            keyboardType: const TextInputType.numberWithOptions(signed: true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CalculatorToolField(
            controller: draft.linearVariables,
            labelKey: 'toolbox.life.advanced_calculator.variables',
          ),
        ),
      ],
    );
  }

  void _runLinearOperation(ToolboxCalculatorOperation operation) {
    try {
      final request = _buildLinearRequest(operation);
      runRequest(request, detail: _linearOperationDetail(operation));
    } on FormatException {
      showDraftError();
    }
  }

  ToolboxCalculatorRequest _buildLinearRequest(
    ToolboxCalculatorOperation operation,
  ) {
    final vectors = <ToolboxCalculatorOperation>{
      ToolboxCalculatorOperation.dotProduct,
      ToolboxCalculatorOperation.crossProduct,
      ToolboxCalculatorOperation.vectorNorm,
      ToolboxCalculatorOperation.vectorProjection,
    };
    if (vectors.contains(operation)) {
      return ToolboxCalculatorRequest(
        operation: operation,
        vector: draft.csv(draft.vectorA),
        secondaryVector: draft.csv(draft.vectorB),
      );
    }
    return ToolboxCalculatorRequest(
      operation: operation,
      matrix: draft.matrixA.values(),
      secondaryMatrix: draft.matrixB.values(),
      vector: draft.csv(draft.vectorA),
      variables: draft.csv(draft.linearVariables),
      scalar: draft.scalar.text.trim(),
      order: draft.integer(draft.order, min: -10, max: 10),
      targetVariable: 'lambda',
    );
  }

  String _linearOperationDetail(ToolboxCalculatorOperation operation) {
    return switch (operation) {
      ToolboxCalculatorOperation.matrixAdd => 'A + B',
      ToolboxCalculatorOperation.matrixSubtract => 'A − B',
      ToolboxCalculatorOperation.matrixMultiply => 'AB',
      ToolboxCalculatorOperation.scalarMultiply => 'kA',
      ToolboxCalculatorOperation.matrixPower => 'Aⁿ',
      ToolboxCalculatorOperation.dotProduct => 'u · v',
      ToolboxCalculatorOperation.crossProduct => 'u × v',
      ToolboxCalculatorOperation.vectorNorm => '‖u‖',
      ToolboxCalculatorOperation.vectorProjection => 'projᵥ(u)',
      ToolboxCalculatorOperation.nullSpace => 'ker(A)',
      ToolboxCalculatorOperation.columnSpace => 'col(A)',
      ToolboxCalculatorOperation.rowSpace => 'row(A)',
      ToolboxCalculatorOperation.luDecomposition => 'PA = LU',
      ToolboxCalculatorOperation.qrDecomposition => 'A = QR',
      ToolboxCalculatorOperation.leastSquares => 'min ‖Ax − b‖₂',
      ToolboxCalculatorOperation.gramSchmidt => 'orth(A)',
      _ => 'A',
    };
  }

  Widget _buildProbabilityTools(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _CalculatorSheetSectionTitle(
          titleKey: 'toolbox.life.advanced_calculator.section.probability',
          subtitleKey:
              'toolbox.life.advanced_calculator.section.probability_hint',
          icon: Icons.casino_outlined,
        ),
        const SizedBox(height: 12),
        _buildBinomialFields(),
        const SizedBox(height: 10),
        _CalculatorActionGrid<_CalculatorProbabilityAction>(
          actions: _probabilityActions(const <_CalculatorProbabilityAction>[
            _CalculatorProbabilityAction.combination,
            _CalculatorProbabilityAction.permutation,
            _CalculatorProbabilityAction.binomialPmf,
            _CalculatorProbabilityAction.binomialCdf,
          ]),
          onSelected: _runProbabilityOperation,
        ),
        const SizedBox(height: 22),
        const _CalculatorSheetSectionTitle(
          titleKey: 'toolbox.life.advanced_calculator.probability.normal_group',
          icon: Icons.stacked_line_chart_rounded,
        ),
        const SizedBox(height: 10),
        _buildNormalFields(),
        const SizedBox(height: 10),
        _CalculatorActionGrid<_CalculatorProbabilityAction>(
          actions: _probabilityActions(const <_CalculatorProbabilityAction>[
            _CalculatorProbabilityAction.normalPdf,
            _CalculatorProbabilityAction.normalCdf,
          ]),
          onSelected: _runProbabilityOperation,
        ),
      ],
    );
  }

  Widget _buildBinomialFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _CalculatorToolField(
            controller: draft.probabilityN,
            labelKey: 'toolbox.life.advanced_calculator.prob_n',
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CalculatorToolField(
            controller: draft.probabilityK,
            labelKey: 'toolbox.life.advanced_calculator.prob_k',
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CalculatorToolField(
            controller: draft.probabilityP,
            labelKey: 'toolbox.life.advanced_calculator.prob_p',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      ],
    );
  }

  Widget _buildNormalFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _CalculatorToolField(
            controller: draft.normalMean,
            labelKey: 'toolbox.life.advanced_calculator.normal_mean',
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CalculatorToolField(
            controller: draft.normalDeviation,
            labelKey: 'toolbox.life.advanced_calculator.normal_sd',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CalculatorToolField(
            controller: draft.normalX,
            labelKey: 'toolbox.life.advanced_calculator.normal_x',
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
          ),
        ),
      ],
    );
  }

  List<_CalculatorActionSpec<_CalculatorProbabilityAction>> _probabilityActions(
    List<_CalculatorProbabilityAction> actions,
  ) {
    return actions
        .map(
          (action) => _CalculatorActionSpec<_CalculatorProbabilityAction>(
            value: action,
            labelKey: _probabilityActionKey(action),
            icon: _probabilityActionIcon(action),
          ),
        )
        .toList(growable: false);
  }

  void _runProbabilityOperation(_CalculatorProbabilityAction action) {
    try {
      final calculator = const ToolboxScientificCalculatorService();
      final label = _lifeI18nText(context, _probabilityActionKey(action));
      switch (action) {
        case _CalculatorProbabilityAction.combination:
        case _CalculatorProbabilityAction.permutation:
          _runExactCombinatorics(action, label);
        case _CalculatorProbabilityAction.binomialPmf:
        case _CalculatorProbabilityAction.binomialCdf:
          _runBinomial(calculator, action);
        case _CalculatorProbabilityAction.normalPdf:
        case _CalculatorProbabilityAction.normalCdf:
          _runNormal(calculator, action);
      }
    } on FormatException {
      showDraftError();
    }
  }

  void _runExactCombinatorics(
    _CalculatorProbabilityAction action,
    String label,
  ) {
    final n = draft.integer(draft.probabilityN, min: 0);
    final k = draft.integer(draft.probabilityK, min: 0);
    if (k > n) throw const FormatException('k > n');
    final function = action == _CalculatorProbabilityAction.combination
        ? 'nCr'
        : 'nPr';
    final source = '$function($n,$k)';
    Navigator.pop(context);
    unawaited(
      widget.onSubmit(
        ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.evaluate,
          expression: source,
        ),
        '$label · $source',
      ),
    );
  }

  void _runBinomial(
    ToolboxScientificCalculatorService calculator,
    _CalculatorProbabilityAction action,
  ) {
    final n = draft.integer(draft.probabilityN, min: 0);
    final k = draft.integer(draft.probabilityK, min: 0);
    final p = draft.number(draft.probabilityP);
    if (k > n || p < 0 || p > 1) throw const FormatException('Invalid p');
    final value = action == _CalculatorProbabilityAction.binomialPmf
        ? calculator.binomialPmf(n: n, k: k, p: p)
        : calculator.binomialCdf(n: n, k: k, p: p);
    final function = action == _CalculatorProbabilityAction.binomialPmf
        ? 'binomialPmf'
        : 'binomialCdf';
    runNumeric(
      ToolboxCalculatorOperation.evaluate,
      '$function($n,$k,$p)',
      value,
    );
  }

  void _runNormal(
    ToolboxScientificCalculatorService calculator,
    _CalculatorProbabilityAction action,
  ) {
    final mean = draft.number(draft.normalMean);
    final deviation = draft.number(draft.normalDeviation);
    final x = draft.number(draft.normalX);
    if (deviation <= 0) throw const FormatException('Invalid deviation');
    final value = action == _CalculatorProbabilityAction.normalPdf
        ? calculator.normalPdf(mean: mean, standardDeviation: deviation, x: x)
        : calculator.normalCdf(mean: mean, standardDeviation: deviation, x: x);
    final function = action == _CalculatorProbabilityAction.normalPdf
        ? 'normalPdf'
        : 'normalCdf';
    runNumeric(
      ToolboxCalculatorOperation.evaluate,
      '$function($mean,$deviation,$x)',
      value,
    );
  }
}

String _probabilityActionKey(_CalculatorProbabilityAction action) {
  return switch (action) {
    _CalculatorProbabilityAction.combination =>
      'toolbox.life.advanced_calculator.operation.combination',
    _CalculatorProbabilityAction.permutation =>
      'toolbox.life.advanced_calculator.operation.permutation',
    _CalculatorProbabilityAction.binomialPmf =>
      'toolbox.life.advanced_calculator.binomial_pmf',
    _CalculatorProbabilityAction.binomialCdf =>
      'toolbox.life.advanced_calculator.binomial_cdf',
    _CalculatorProbabilityAction.normalPdf =>
      'toolbox.life.advanced_calculator.normal_pdf',
    _CalculatorProbabilityAction.normalCdf =>
      'toolbox.life.advanced_calculator.normal_cdf',
  };
}

IconData _probabilityActionIcon(_CalculatorProbabilityAction action) {
  return switch (action) {
    _CalculatorProbabilityAction.combination => Icons.hub_outlined,
    _CalculatorProbabilityAction.permutation => Icons.shuffle_rounded,
    _CalculatorProbabilityAction.binomialPmf => Icons.bar_chart_rounded,
    _CalculatorProbabilityAction.binomialCdf => Icons.waterfall_chart_rounded,
    _CalculatorProbabilityAction.normalPdf => Icons.show_chart_rounded,
    _CalculatorProbabilityAction.normalCdf => Icons.area_chart_rounded,
  };
}

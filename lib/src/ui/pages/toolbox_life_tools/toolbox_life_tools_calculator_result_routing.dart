part of '../toolbox_life_tools.dart';

enum _CalculatorResultDestination {
  expression,
  matrixA,
  matrixB,
  vectorA,
  vectorB,
}

extension _CalculatorResultRouting on _AdvancedCalculatorToolPageState {
  Future<void> _continueWithResult(ToolboxCalculatorResultPart? part) async {
    final result = _session.result;
    if (result == null) return;
    if (result.isComposite && part == null) return;
    await _continueRoutableResult(
      exact: part?.exact ?? result.exact,
      type: part?.type ?? result.type,
    );
  }

  Future<void> _continueRoutableResult({
    required String exact,
    required ToolboxCalculatorResultType type,
  }) async {
    if (type != ToolboxCalculatorResultType.matrix &&
        type != ToolboxCalculatorResultType.vector) {
      _routeResultTo(
        _CalculatorResultDestination.expression,
        exact: exact,
        type: type,
      );
      return;
    }
    final destinations = type == ToolboxCalculatorResultType.matrix
        ? const <_CalculatorResultDestination>[
            _CalculatorResultDestination.matrixA,
            _CalculatorResultDestination.matrixB,
            _CalculatorResultDestination.expression,
          ]
        : const <_CalculatorResultDestination>[
            _CalculatorResultDestination.vectorA,
            _CalculatorResultDestination.vectorB,
            _CalculatorResultDestination.expression,
          ];
    final destination =
        await showModalBottomSheet<_CalculatorResultDestination>(
          context: context,
          showDragHandle: true,
          builder: (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    _lifeI18nText(
                      sheetContext,
                      'toolbox.life.advanced_calculator.result_route.title',
                    ),
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                for (final item in destinations)
                  ListTile(
                    minTileHeight: 48,
                    leading: Icon(_resultDestinationIcon(item)),
                    title: Text(
                      _lifeI18nText(sheetContext, _resultDestinationKey(item)),
                    ),
                    onTap: () => Navigator.pop(sheetContext, item),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
    if (!mounted || destination == null) return;
    _routeResultTo(destination, exact: exact, type: type);
  }

  void _routeResultTo(
    _CalculatorResultDestination destination, {
    required String exact,
    required ToolboxCalculatorResultType type,
  }) {
    try {
      switch (destination) {
        case _CalculatorResultDestination.expression:
          _replaceExpression(exact);
        case _CalculatorResultDestination.matrixA:
          if (type != ToolboxCalculatorResultType.matrix) {
            throw const FormatException('Expected a matrix result');
          }
          _toolDraft.matrixA.replaceValues(_parseMatrixResult(exact));
        case _CalculatorResultDestination.matrixB:
          if (type != ToolboxCalculatorResultType.matrix) {
            throw const FormatException('Expected a matrix result');
          }
          _toolDraft.matrixB.replaceValues(_parseMatrixResult(exact));
        case _CalculatorResultDestination.vectorA:
          if (type != ToolboxCalculatorResultType.vector) {
            throw const FormatException('Expected a vector result');
          }
          _toolDraft.vectorA.text = _parseVectorResult(exact).join(',');
        case _CalculatorResultDestination.vectorB:
          if (type != ToolboxCalculatorResultType.vector) {
            throw const FormatException('Expected a vector result');
          }
          _toolDraft.vectorB.text = _parseVectorResult(exact).join(',');
      }
      _setResultCommitted(false);
    } on FormatException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _lifeI18nText(
              context,
              'toolbox.life.advanced_calculator.result_route.invalid',
            ),
          ),
        ),
      );
    }
  }

  List<List<String>> _parseMatrixResult(String source) {
    final draft = _CalculatorMatrixDraft(
      values: const <List<String>>[
        <String>['0'],
      ],
    );
    try {
      draft
        ..textController.text = source
        ..gridMode = false;
      return draft.values();
    } finally {
      draft.dispose();
    }
  }

  List<String> _parseVectorResult(String source) {
    var normalized = source.trim();
    if (normalized.startsWith('vector(') && normalized.endsWith(')')) {
      normalized = normalized.substring(7, normalized.length - 1);
    } else if (normalized.startsWith('[') && normalized.endsWith(']')) {
      normalized = normalized.substring(1, normalized.length - 1);
    }
    final values = _splitCalculatorTopLevel(normalized);
    if (values.isEmpty || values.length > 32) {
      throw const FormatException('Invalid vector result');
    }
    return values;
  }
}

List<String> _splitCalculatorTopLevel(String source) {
  final values = <String>[];
  var start = 0;
  var depth = 0;
  for (var index = 0; index < source.length; index += 1) {
    final character = source[index];
    if (character == '(' || character == '[' || character == '{') depth += 1;
    if (character == ')' || character == ']' || character == '}') depth -= 1;
    if (depth < 0) throw const FormatException('Unbalanced vector result');
    if (character == ',' && depth == 0) {
      final value = source.substring(start, index).trim();
      if (value.isEmpty) throw const FormatException('Empty vector value');
      values.add(value);
      start = index + 1;
    }
  }
  if (depth != 0) throw const FormatException('Unbalanced vector result');
  final tail = source.substring(start).trim();
  if (tail.isEmpty) throw const FormatException('Empty vector value');
  values.add(tail);
  return values;
}

String _resultDestinationKey(_CalculatorResultDestination destination) {
  return switch (destination) {
    _CalculatorResultDestination.expression =>
      'toolbox.life.advanced_calculator.result_route.expression',
    _CalculatorResultDestination.matrixA =>
      'toolbox.life.advanced_calculator.result_route.matrix_a',
    _CalculatorResultDestination.matrixB =>
      'toolbox.life.advanced_calculator.result_route.matrix_b',
    _CalculatorResultDestination.vectorA =>
      'toolbox.life.advanced_calculator.result_route.vector_a',
    _CalculatorResultDestination.vectorB =>
      'toolbox.life.advanced_calculator.result_route.vector_b',
  };
}

IconData _resultDestinationIcon(_CalculatorResultDestination destination) {
  return switch (destination) {
    _CalculatorResultDestination.expression => Icons.edit_note_rounded,
    _CalculatorResultDestination.matrixA => Icons.grid_on_rounded,
    _CalculatorResultDestination.matrixB => Icons.grid_view_rounded,
    _CalculatorResultDestination.vectorA => Icons.arrow_right_alt_rounded,
    _CalculatorResultDestination.vectorB => Icons.trending_flat_rounded,
  };
}

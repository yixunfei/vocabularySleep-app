part of '../toolbox_life_tools.dart';

enum _AdvancedCalculatorPanel { analysis, linearAlgebra, probability }

class _AdvancedCalculatorToolPage extends StatefulWidget {
  const _AdvancedCalculatorToolPage();

  @override
  State<_AdvancedCalculatorToolPage> createState() =>
      _AdvancedCalculatorToolPageState();
}

class _AdvancedCalculatorToolPageState
    extends State<_AdvancedCalculatorToolPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _analysisController = TextEditingController(
    text: 'sin(x)',
  );
  final TextEditingController _lowerController = TextEditingController(
    text: '0',
  );
  final TextEditingController _upperController = TextEditingController(
    text: 'pi',
  );
  final TextEditingController _pointController = TextEditingController(
    text: '0',
  );
  final TextEditingController _rootLeftController = TextEditingController(
    text: '-2',
  );
  final TextEditingController _rootRightController = TextEditingController(
    text: '2',
  );
  final TextEditingController _matrixController = TextEditingController(
    text: '1,2;3,4',
  );
  final TextEditingController _vectorController = TextEditingController(
    text: '5,6',
  );
  final TextEditingController _probNController = TextEditingController(
    text: '10',
  );
  final TextEditingController _probKController = TextEditingController(
    text: '3',
  );
  final TextEditingController _probPController = TextEditingController(
    text: '0.5',
  );
  final TextEditingController _normalMeanController = TextEditingController(
    text: '0',
  );
  final TextEditingController _normalSdController = TextEditingController(
    text: '1',
  );
  final TextEditingController _normalXController = TextEditingController(
    text: '1.96',
  );

  final ToolboxScientificCalculatorService _calculator =
      const ToolboxScientificCalculatorService();
  final List<_CalculatorHistoryItem> _history = <_CalculatorHistoryItem>[];
  double _memory = 0;
  double? _lastAnswer;
  double? _result;
  String? _errorKey;
  bool _degreeMode = true;
  _AdvancedCalculatorPanel _panel = _AdvancedCalculatorPanel.analysis;
  String? _analysisResult;
  String? _matrixResult;
  String? _probabilityResult;

  ScientificAngleMode get _angleMode =>
      _degreeMode ? ScientificAngleMode.degree : ScientificAngleMode.radian;

  void applyState(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_evaluate);
  }

  @override
  void dispose() {
    _controller.dispose();
    _analysisController.dispose();
    _lowerController.dispose();
    _upperController.dispose();
    _pointController.dispose();
    _rootLeftController.dispose();
    _rootRightController.dispose();
    _matrixController.dispose();
    _vectorController.dispose();
    _probNController.dispose();
    _probKController.dispose();
    _probPController.dispose();
    _normalMeanController.dispose();
    _normalSdController.dispose();
    _normalXController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'toolbox.life.advanced_calculator.title'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.life.advanced_calculator.subtitle',
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final expanded =
              AppWidthBreakpoints.tierFor(constraints.maxWidth).isExpanded &&
              constraints.maxWidth >= 760;
          if (!expanded) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildExpressionWorkspace(context),
                const SizedBox(height: 12),
                _buildKeypad(context),
                const SizedBox(height: 12),
                _buildProfessionalWorkspace(context),
                const SizedBox(height: 12),
                _buildMemoryAndHistory(context),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    _buildExpressionWorkspace(context),
                    const SizedBox(height: 12),
                    _buildKeypad(context),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: <Widget>[
                    _buildProfessionalWorkspace(context),
                    const SizedBox(height: 12),
                    _buildMemoryAndHistory(context),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _insert(String token) {
    final text = _controller.text;
    final selection = _controller.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    _controller.value = TextEditingValue(
      text: text.replaceRange(start, end, token),
      selection: TextSelection.collapsed(offset: start + token.length),
    );
  }

  void _backspace() {
    final text = _controller.text;
    final selection = _controller.selection;
    if (text.isEmpty) {
      return;
    }
    if (selection.isValid && selection.start != selection.end) {
      _controller.value = TextEditingValue(
        text: text.replaceRange(selection.start, selection.end, ''),
        selection: TextSelection.collapsed(offset: selection.start),
      );
      return;
    }
    final offset = selection.isValid ? selection.start : text.length;
    if (offset <= 0) {
      return;
    }
    _controller.value = TextEditingValue(
      text: text.replaceRange(offset - 1, offset, ''),
      selection: TextSelection.collapsed(offset: offset - 1),
    );
  }

  void _evaluate() {
    final expression = _controller.text.trim();
    if (expression.isEmpty) {
      setState(() {
        _result = null;
        _errorKey = null;
      });
      return;
    }
    try {
      final value = _evalExpression(expression);
      if (!value.isFinite) {
        throw const FormatException('non-finite');
      }
      setState(() {
        _result = value;
        _lastAnswer = value;
        _errorKey = null;
      });
    } catch (_) {
      setState(() {
        _result = null;
        _errorKey = 'toolbox.life.advanced_calculator.error';
      });
    }
  }

  double _evalExpression(String expression, {double? x}) {
    final variables = <String, double>{
      if (x != null) 'x': x,
      if (_lastAnswer != null) 'ans': _lastAnswer!,
      'mem': _memory,
    };
    return _calculator.evaluate(
      expression,
      angleMode: _angleMode,
      variables: variables,
    );
  }

  void _calculateIntegral() {
    try {
      final expression = _analysisController.text.trim();
      final a = _evalExpression(_lowerController.text);
      final b = _evalExpression(_upperController.text);
      final value = _calculator.integrate(
        expression,
        lower: a,
        upper: b,
        angleMode: _angleMode,
      );
      _setAnalysisResult(
        'toolbox.life.advanced_calculator.result_integral',
        <String, Object?>{'value': _formatNumber(value)},
      );
    } catch (_) {
      _setAnalysisError();
    }
  }

  void _calculateDerivative() {
    try {
      final expression = _analysisController.text.trim();
      final x0 = _evalExpression(_pointController.text);
      final value = _calculator.derivative(
        expression,
        at: x0,
        angleMode: _angleMode,
      );
      _setAnalysisResult(
        'toolbox.life.advanced_calculator.result_derivative',
        <String, Object?>{'value': _formatNumber(value)},
      );
    } catch (_) {
      _setAnalysisError();
    }
  }

  void _calculateLimit() {
    try {
      final expression = _analysisController.text.trim();
      final x0 = _evalExpression(_pointController.text);
      final limit = _calculator.limit(
        expression,
        at: x0,
        angleMode: _angleMode,
      );
      final combined = limit.converged
          ? _formatNumber(limit.value)
          : _lifeI18nText(
              context,
              'toolbox.life.advanced_calculator.limit_two_sided',
              params: <String, Object?>{
                'left': _formatNumber(limit.left),
                'right': _formatNumber(limit.right),
              },
            );
      _setAnalysisResult(
        'toolbox.life.advanced_calculator.result_limit',
        <String, Object?>{'value': combined},
      );
    } catch (_) {
      _setAnalysisError();
    }
  }

  void _solveRoot() {
    try {
      final expression = _analysisController.text.trim();
      final root = _calculator.solveRoot(
        expression,
        leftBound: _evalExpression(_rootLeftController.text),
        rightBound: _evalExpression(_rootRightController.text),
        angleMode: _angleMode,
      );
      _setAnalysisResult(
        'toolbox.life.advanced_calculator.result_root',
        <String, Object?>{
          'value': _formatNumber(root.value),
          'residual': _formatNumber(root.residual),
        },
      );
    } catch (_) {
      _setAnalysisError();
    }
  }

  void _setAnalysisResult(String key, Map<String, Object?> params) {
    setState(() {
      _analysisResult = _lifeI18nText(context, key, params: params);
    });
  }

  void _setAnalysisError() {
    setState(() {
      _analysisResult = _lifeI18nText(
        context,
        'toolbox.life.advanced_calculator.analysis_error',
      );
    });
  }

  void _calculateDeterminant() {
    try {
      final matrix = _calculator.parseMatrix(
        _matrixController.text,
        angleMode: _angleMode,
      );
      final det = _calculator.determinant(matrix);
      setState(() {
        _matrixResult = _lifeI18nText(
          context,
          'toolbox.life.advanced_calculator.result_determinant',
          params: <String, Object?>{'value': _formatNumber(det)},
        );
      });
    } catch (_) {
      _setMatrixError();
    }
  }

  void _calculateInverse() {
    try {
      final inverse = _calculator.inverse(
        _calculator.parseMatrix(_matrixController.text, angleMode: _angleMode),
      );
      setState(() {
        _matrixResult = _lifeI18nText(
          context,
          'toolbox.life.advanced_calculator.result_inverse',
          params: <String, Object?>{'value': _formatMatrix(inverse)},
        );
      });
    } catch (_) {
      _setMatrixError();
    }
  }

  void _solveLinearSystem() {
    try {
      final matrix = _calculator.parseMatrix(
        _matrixController.text,
        angleMode: _angleMode,
      );
      final vector = _calculator.parseVector(
        _vectorController.text,
        angleMode: _angleMode,
      );
      final solution = _calculator.solveLinear(matrix, vector);
      setState(() {
        _matrixResult = _lifeI18nText(
          context,
          'toolbox.life.advanced_calculator.result_linear',
          params: <String, Object?>{'value': _formatVector(solution)},
        );
      });
    } catch (_) {
      _setMatrixError();
    }
  }

  void _setMatrixError() {
    setState(() {
      _matrixResult = _lifeI18nText(
        context,
        'toolbox.life.advanced_calculator.matrix_error',
      );
    });
  }

  String _formatMatrix(List<List<double>> matrix) {
    return matrix.map((row) => '[${_formatVector(row)}]').join('\n');
  }

  String _formatVector(List<double> vector) {
    return vector.map(_formatNumber).join(', ');
  }

  void _calculateCombination() {
    try {
      final n = _readInt(_probNController);
      final k = _readInt(_probKController);
      _setProbabilityResult(
        'toolbox.life.advanced_calculator.result_combination',
        <String, Object?>{
          'value': _formatNumber(_calculator.combination(n, k)),
        },
      );
    } catch (_) {
      _setProbabilityError();
    }
  }

  void _calculatePermutation() {
    try {
      final n = _readInt(_probNController);
      final k = _readInt(_probKController);
      _setProbabilityResult(
        'toolbox.life.advanced_calculator.result_permutation',
        <String, Object?>{
          'value': _formatNumber(_calculator.permutation(n, k)),
        },
      );
    } catch (_) {
      _setProbabilityError();
    }
  }

  void _calculateBinomialPmf() {
    try {
      final n = _readInt(_probNController);
      final k = _readInt(_probKController);
      final p = _readDouble(_probPController);
      final value = _calculator.binomialPmf(n: n, k: k, p: p);
      _setProbabilityResult(
        'toolbox.life.advanced_calculator.result_binomial_pmf',
        <String, Object?>{'value': _formatNumber(value)},
      );
    } catch (_) {
      _setProbabilityError();
    }
  }

  void _calculateBinomialCdf() {
    try {
      final n = _readInt(_probNController);
      final k = _readInt(_probKController);
      final p = _readDouble(_probPController);
      final value = _calculator.binomialCdf(n: n, k: k, p: p);
      _setProbabilityResult(
        'toolbox.life.advanced_calculator.result_binomial_cdf',
        <String, Object?>{'value': _formatNumber(value)},
      );
    } catch (_) {
      _setProbabilityError();
    }
  }

  void _calculateNormalPdf() {
    try {
      final mean = _readDouble(_normalMeanController);
      final sd = _readDouble(_normalSdController);
      final x = _readDouble(_normalXController);
      final value = _calculator.normalPdf(
        mean: mean,
        standardDeviation: sd,
        x: x,
      );
      _setProbabilityResult(
        'toolbox.life.advanced_calculator.result_normal_pdf',
        <String, Object?>{'value': _formatNumber(value)},
      );
    } catch (_) {
      _setProbabilityError();
    }
  }

  void _calculateNormalCdf() {
    try {
      final mean = _readDouble(_normalMeanController);
      final sd = _readDouble(_normalSdController);
      final x = _readDouble(_normalXController);
      final value = _calculator.normalCdf(
        mean: mean,
        standardDeviation: sd,
        x: x,
      );
      _setProbabilityResult(
        'toolbox.life.advanced_calculator.result_normal_cdf',
        <String, Object?>{'value': _formatNumber(value)},
      );
    } catch (_) {
      _setProbabilityError();
    }
  }

  int _readInt(TextEditingController controller) {
    final value = _evalExpression(controller.text).round();
    if (value < 0) {
      throw const FormatException('negative');
    }
    return value;
  }

  double _readDouble(TextEditingController controller) {
    return _evalExpression(controller.text);
  }

  void _setProbabilityResult(String key, Map<String, Object?> params) {
    setState(() {
      _probabilityResult = _lifeI18nText(context, key, params: params);
    });
  }

  void _setProbabilityError() {
    setState(() {
      _probabilityResult = _lifeI18nText(
        context,
        'toolbox.life.advanced_calculator.probability_error',
      );
    });
  }

  void _addHistory() {
    final value = _result;
    final expression = _controller.text.trim();
    if (value == null || expression.isEmpty) {
      return;
    }
    setState(() {
      _history.insert(
        0,
        _CalculatorHistoryItem(expression: expression, value: value),
      );
      if (_history.length > 20) {
        _history.removeRange(20, _history.length);
      }
    });
  }

  void _commitResult() {
    final value = _result;
    if (value == null) {
      return;
    }
    _addHistory();
    _setExpression(value);
  }

  void _setExpression(double value) {
    _controller.text = _formatNumber(value);
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  String _formatNumber(num? value) {
    return _calculator.formatNumber(value);
  }
}

class _CalculatorHistoryItem {
  const _CalculatorHistoryItem({required this.expression, required this.value});

  final String expression;
  final double value;
}

class _CalculatorResultBox extends StatelessWidget {
  const _CalculatorResultBox({required this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        text ??
            _lifeI18nText(
              context,
              'toolbox.life.advanced_calculator.pro_empty',
            ),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFeatures: const <ui.FontFeature>[ui.FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

part of '../toolbox_life_tools.dart';

enum _CalculatorKeypadPage { basic, scientific, symbols }

enum _CalculatorToolCategory {
  algebra,
  calculus,
  linearAlgebra,
  complex,
  probability,
}

enum _CalculatorProbabilityAction {
  combination,
  permutation,
  binomialPmf,
  binomialCdf,
  normalPdf,
  normalCdf,
}

enum _CalculatorKeyKind { digit, operator, function, constant }

enum _CalculatorControlAction { clear, left, right, backspace, evaluate }

class _CalculatorKeySpec {
  const _CalculatorKeySpec({
    required this.label,
    required this.insertion,
    this.cursorBack = 0,
    this.kind = _CalculatorKeyKind.digit,
  }) : toolCategory = null,
       toolOperation = null;

  const _CalculatorKeySpec.tool({
    required this.label,
    required this.toolCategory,
    required this.toolOperation,
  }) : insertion = null,
       cursorBack = 0,
       kind = _CalculatorKeyKind.function;

  final String label;
  final String? insertion;
  final int cursorBack;
  final _CalculatorKeyKind kind;
  final _CalculatorToolCategory? toolCategory;
  final ToolboxCalculatorOperation? toolOperation;
}

class _CalculatorToolDraft {
  _CalculatorToolDraft()
    : matrixA = _CalculatorMatrixDraft(
        values: const <List<String>>[
          <String>['1', '2'],
          <String>['3', '4'],
        ],
      ),
      matrixB = _CalculatorMatrixDraft(
        values: const <List<String>>[
          <String>['1', '0'],
          <String>['0', '1'],
        ],
      );

  final variable = TextEditingController(text: 'x');
  final targetVariable = TextEditingController(text: 's');
  final lowerBound = TextEditingController(text: '0');
  final upperBound = TextEditingController(text: '1');
  final point = TextEditingController(text: '0');
  final order = TextEditingController(text: '2');
  final substitutions = TextEditingController(text: 'x=2');
  final equations = TextEditingController(text: 'x+y=3\nx-y=1');
  final variables = TextEditingController(text: 'x,y');
  final vectorFunctions = TextEditingController(text: 'x^2,y^2,z^2');
  final multiVariables = TextEditingController(text: 'x,y,z');
  final scalar = TextEditingController(text: '2');
  final linearVariables = TextEditingController(text: 'x1,x2');
  final vectorA = TextEditingController(text: '1,0,0');
  final vectorB = TextEditingController(text: '0,1,0');
  final complexRadius = TextEditingController(text: '1');
  final complexAngle = TextEditingController(text: '0');
  final probabilityN = TextEditingController(text: '10');
  final probabilityK = TextEditingController(text: '3');
  final probabilityP = TextEditingController(text: '0.5');
  final normalMean = TextEditingController(text: '0');
  final normalDeviation = TextEditingController(text: '1');
  final normalX = TextEditingController(text: '1.96');
  final _CalculatorMatrixDraft matrixA;
  final _CalculatorMatrixDraft matrixB;

  List<String> csv(TextEditingController controller) {
    return controller.text
        .split(RegExp(r'[,;\n]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  List<String> equationList() {
    return equations.text
        .split(RegExp(r'[;\n]+'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  Map<String, String> substitutionMap() {
    final result = <String, String>{};
    for (final pair in substitutions.text.split(RegExp(r'[,;\n]+'))) {
      final separator = pair.indexOf('=');
      if (separator <= 0 || separator == pair.length - 1) {
        throw const FormatException('Invalid substitution');
      }
      result[pair.substring(0, separator).trim()] = pair
          .substring(separator + 1)
          .trim();
    }
    if (result.isEmpty) throw const FormatException('Empty substitution');
    return result;
  }

  int integer(TextEditingController controller, {int? min, int? max}) {
    final value = int.tryParse(controller.text.trim());
    if (value == null ||
        (min != null && value < min) ||
        (max != null && value > max)) {
      throw const FormatException('Invalid integer');
    }
    return value;
  }

  double number(TextEditingController controller) {
    final value = double.tryParse(controller.text.trim());
    if (value == null || !value.isFinite) {
      throw const FormatException('Invalid number');
    }
    return value;
  }

  void dispose() {
    for (final controller in <TextEditingController>[
      variable,
      targetVariable,
      lowerBound,
      upperBound,
      point,
      order,
      substitutions,
      equations,
      variables,
      vectorFunctions,
      multiVariables,
      scalar,
      linearVariables,
      vectorA,
      vectorB,
      complexRadius,
      complexAngle,
      probabilityN,
      probabilityK,
      probabilityP,
      normalMean,
      normalDeviation,
      normalX,
    ]) {
      controller.dispose();
    }
    matrixA.dispose();
    matrixB.dispose();
  }
}

String _calculatorOperationKey(ToolboxCalculatorOperation operation) {
  final suffix = switch (operation) {
    ToolboxCalculatorOperation.evaluate => 'evaluate',
    ToolboxCalculatorOperation.approximate => 'approximate',
    ToolboxCalculatorOperation.simplify => 'simplify',
    ToolboxCalculatorOperation.expand => 'expand',
    ToolboxCalculatorOperation.factor => 'factor',
    ToolboxCalculatorOperation.partialFraction => 'partial_fraction',
    ToolboxCalculatorOperation.substitute => 'substitute',
    ToolboxCalculatorOperation.solveEquation => 'solve_equation',
    ToolboxCalculatorOperation.solveSystem => 'solve_system',
    ToolboxCalculatorOperation.differentiate => 'differentiate',
    ToolboxCalculatorOperation.integrate => 'integrate',
    ToolboxCalculatorOperation.definiteIntegral => 'definite_integral',
    ToolboxCalculatorOperation.limit => 'limit',
    ToolboxCalculatorOperation.taylor => 'taylor',
    ToolboxCalculatorOperation.summation => 'summation',
    ToolboxCalculatorOperation.product => 'product',
    ToolboxCalculatorOperation.laplace => 'laplace',
    ToolboxCalculatorOperation.inverseLaplace => 'inverse_laplace',
    ToolboxCalculatorOperation.gradient => 'gradient',
    ToolboxCalculatorOperation.divergence => 'divergence',
    ToolboxCalculatorOperation.curl => 'curl',
    ToolboxCalculatorOperation.hessian => 'hessian',
    ToolboxCalculatorOperation.matrixAdd => 'matrix_add',
    ToolboxCalculatorOperation.matrixSubtract => 'matrix_subtract',
    ToolboxCalculatorOperation.matrixMultiply => 'matrix_multiply',
    ToolboxCalculatorOperation.scalarMultiply => 'scalar_multiply',
    ToolboxCalculatorOperation.matrixPower => 'matrix_power',
    ToolboxCalculatorOperation.determinant => 'determinant',
    ToolboxCalculatorOperation.inverse => 'inverse',
    ToolboxCalculatorOperation.transpose => 'transpose',
    ToolboxCalculatorOperation.trace => 'trace',
    ToolboxCalculatorOperation.rank => 'rank',
    ToolboxCalculatorOperation.rref => 'rref',
    ToolboxCalculatorOperation.solveLinearSystem => 'solve_linear_system',
    ToolboxCalculatorOperation.characteristicPolynomial =>
      'characteristic_polynomial',
    ToolboxCalculatorOperation.eigenvalues => 'eigenvalues',
    ToolboxCalculatorOperation.eigenvectors => 'eigenvectors',
    ToolboxCalculatorOperation.nullSpace => 'null_space',
    ToolboxCalculatorOperation.columnSpace => 'column_space',
    ToolboxCalculatorOperation.rowSpace => 'row_space',
    ToolboxCalculatorOperation.luDecomposition => 'lu_decomposition',
    ToolboxCalculatorOperation.qrDecomposition => 'qr_decomposition',
    ToolboxCalculatorOperation.leastSquares => 'least_squares',
    ToolboxCalculatorOperation.gramSchmidt => 'gram_schmidt',
    ToolboxCalculatorOperation.dotProduct => 'dot_product',
    ToolboxCalculatorOperation.crossProduct => 'cross_product',
    ToolboxCalculatorOperation.vectorNorm => 'vector_norm',
    ToolboxCalculatorOperation.vectorProjection => 'vector_projection',
    ToolboxCalculatorOperation.complexRealPart => 'complex_real_part',
    ToolboxCalculatorOperation.complexImaginaryPart => 'complex_imaginary_part',
    ToolboxCalculatorOperation.complexConjugate => 'complex_conjugate',
    ToolboxCalculatorOperation.complexMagnitude => 'complex_magnitude',
    ToolboxCalculatorOperation.complexArgument => 'complex_argument',
    ToolboxCalculatorOperation.complexPolarForm => 'complex_polar_form',
    ToolboxCalculatorOperation.complexRectangularForm =>
      'complex_rectangular_form',
    ToolboxCalculatorOperation.complexFromPolar => 'complex_from_polar',
  };
  return 'toolbox.life.advanced_calculator.operation.$suffix';
}

String _calculatorCategoryKey(_CalculatorToolCategory category) {
  return 'toolbox.life.advanced_calculator.category.${category.name}';
}

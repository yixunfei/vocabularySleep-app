import 'dart:math' as math;

enum ScientificAngleMode { degree, radian }

class ScientificLimitResult {
  const ScientificLimitResult({
    required this.left,
    required this.right,
    required this.converged,
  });

  final double left;
  final double right;
  final bool converged;

  double get value => (left + right) / 2;
}

class ScientificRootResult {
  const ScientificRootResult({required this.value, required this.residual});

  final double value;
  final double residual;
}

class ToolboxScientificCalculatorService {
  const ToolboxScientificCalculatorService();

  double evaluate(
    String expression, {
    ScientificAngleMode angleMode = ScientificAngleMode.degree,
    Map<String, double> variables = const <String, double>{},
  }) {
    return _ScientificExpressionParser(
      expression,
      angleMode: angleMode,
      variables: variables,
    ).parse();
  }

  double integrate(
    String expression, {
    required double lower,
    required double upper,
    ScientificAngleMode angleMode = ScientificAngleMode.degree,
    int segments = 512,
  }) {
    if (!lower.isFinite || !upper.isFinite || segments <= 0) {
      throw const FormatException('invalid integral bounds');
    }
    final evenSegments = segments.isEven ? segments : segments + 1;
    final step = (upper - lower) / evenSegments;
    var sum =
        evaluate(
          expression,
          angleMode: angleMode,
          variables: <String, double>{'x': lower},
        ) +
        evaluate(
          expression,
          angleMode: angleMode,
          variables: <String, double>{'x': upper},
        );
    for (var i = 1; i < evenSegments; i++) {
      final x = lower + step * i;
      sum +=
          (i.isEven ? 2 : 4) *
          evaluate(
            expression,
            angleMode: angleMode,
            variables: <String, double>{'x': x},
          );
    }
    return sum * step / 3;
  }

  double derivative(
    String expression, {
    required double at,
    ScientificAngleMode angleMode = ScientificAngleMode.degree,
  }) {
    if (!at.isFinite) {
      throw const FormatException('invalid derivative point');
    }
    final h = math.max(1e-6, at.abs() * 1e-6);
    return (evaluate(
              expression,
              angleMode: angleMode,
              variables: <String, double>{'x': at + h},
            ) -
            evaluate(
              expression,
              angleMode: angleMode,
              variables: <String, double>{'x': at - h},
            )) /
        (2 * h);
  }

  ScientificLimitResult limit(
    String expression, {
    required double at,
    ScientificAngleMode angleMode = ScientificAngleMode.degree,
  }) {
    if (!at.isFinite) {
      throw const FormatException('invalid limit point');
    }
    var left = double.nan;
    var right = double.nan;
    for (var i = 1; i <= 8; i++) {
      final h = math.pow(10, -i).toDouble() * math.max(1, at.abs());
      left = evaluate(
        expression,
        angleMode: angleMode,
        variables: <String, double>{'x': at - h},
      );
      right = evaluate(
        expression,
        angleMode: angleMode,
        variables: <String, double>{'x': at + h},
      );
    }
    final tolerance = math.max(1e-6, math.max(left.abs(), right.abs()) * 1e-5);
    return ScientificLimitResult(
      left: left,
      right: right,
      converged: (left - right).abs() <= tolerance,
    );
  }

  ScientificRootResult solveRoot(
    String expression, {
    required double leftBound,
    required double rightBound,
    ScientificAngleMode angleMode = ScientificAngleMode.degree,
  }) {
    if (!leftBound.isFinite || !rightBound.isFinite || leftBound > rightBound) {
      throw const FormatException('invalid root bounds');
    }
    var left = leftBound;
    var right = rightBound;
    var fLeft = evaluate(
      expression,
      angleMode: angleMode,
      variables: <String, double>{'x': left},
    );
    final fRight = evaluate(
      expression,
      angleMode: angleMode,
      variables: <String, double>{'x': right},
    );
    if (fLeft == 0) {
      right = left;
    } else if (fRight != 0 && fLeft.sign == fRight.sign) {
      throw const FormatException('root not bracketed');
    }
    for (var i = 0; i < 80 && (right - left).abs() > 1e-10; i++) {
      final mid = (left + right) / 2;
      final fMid = evaluate(
        expression,
        angleMode: angleMode,
        variables: <String, double>{'x': mid},
      );
      if (fMid == 0) {
        left = mid;
        right = mid;
        break;
      }
      if (fLeft.sign == fMid.sign) {
        left = mid;
        fLeft = fMid;
      } else {
        right = mid;
      }
    }
    final value = (left + right) / 2;
    final residual = evaluate(
      expression,
      angleMode: angleMode,
      variables: <String, double>{'x': value},
    );
    return ScientificRootResult(value: value, residual: residual);
  }

  List<List<double>> parseMatrix(
    String raw, {
    ScientificAngleMode angleMode = ScientificAngleMode.degree,
  }) {
    final rows = raw
        .split(';')
        .map(
          (row) => row
              .split(RegExp(r'[\s,]+'))
              .where((cell) => cell.trim().isNotEmpty)
              .map((cell) => evaluate(cell, angleMode: angleMode))
              .toList(growable: false),
        )
        .where((row) => row.isNotEmpty)
        .toList(growable: false);
    if (rows.isEmpty || rows.any((row) => row.length != rows.first.length)) {
      throw const FormatException('invalid matrix');
    }
    return rows;
  }

  List<double> parseVector(
    String raw, {
    ScientificAngleMode angleMode = ScientificAngleMode.degree,
  }) {
    final vector = raw
        .split(RegExp(r'[\s,;]+'))
        .where((cell) => cell.trim().isNotEmpty)
        .map((cell) => evaluate(cell, angleMode: angleMode))
        .toList(growable: false);
    if (vector.isEmpty) {
      throw const FormatException('invalid vector');
    }
    return vector;
  }

  double determinant(List<List<double>> matrix) {
    final n = matrix.length;
    if (matrix.any((row) => row.length != n)) {
      throw const FormatException('matrix must be square');
    }
    final a = matrix.map((row) => List<double>.of(row)).toList(growable: false);
    var det = 1.0;
    for (var col = 0; col < n; col++) {
      var pivot = col;
      for (var row = col + 1; row < n; row++) {
        if (a[row][col].abs() > a[pivot][col].abs()) {
          pivot = row;
        }
      }
      if (a[pivot][col].abs() < 1e-12) {
        return 0;
      }
      if (pivot != col) {
        final tmp = a[col];
        a[col] = a[pivot];
        a[pivot] = tmp;
        det = -det;
      }
      det *= a[col][col];
      for (var row = col + 1; row < n; row++) {
        final factor = a[row][col] / a[col][col];
        for (var c = col; c < n; c++) {
          a[row][c] -= factor * a[col][c];
        }
      }
    }
    return det;
  }

  List<List<double>> inverse(List<List<double>> matrix) {
    final n = matrix.length;
    if (matrix.any((row) => row.length != n)) {
      throw const FormatException('matrix must be square');
    }
    final a = List<List<double>>.generate(n, (row) {
      return <double>[
        ...matrix[row],
        for (var col = 0; col < n; col++) row == col ? 1.0 : 0.0,
      ];
    });
    for (var col = 0; col < n; col++) {
      var pivot = col;
      for (var row = col + 1; row < n; row++) {
        if (a[row][col].abs() > a[pivot][col].abs()) {
          pivot = row;
        }
      }
      if (a[pivot][col].abs() < 1e-12) {
        throw const FormatException('singular matrix');
      }
      if (pivot != col) {
        final tmp = a[col];
        a[col] = a[pivot];
        a[pivot] = tmp;
      }
      final div = a[col][col];
      for (var c = 0; c < 2 * n; c++) {
        a[col][c] /= div;
      }
      for (var row = 0; row < n; row++) {
        if (row == col) {
          continue;
        }
        final factor = a[row][col];
        for (var c = 0; c < 2 * n; c++) {
          a[row][c] -= factor * a[col][c];
        }
      }
    }
    return a.map((row) => row.sublist(n)).toList(growable: false);
  }

  List<double> solveLinear(List<List<double>> matrix, List<double> vector) {
    if (matrix.length != vector.length) {
      throw const FormatException('dimension mismatch');
    }
    final inv = inverse(matrix);
    return inv
        .map(
          (row) => List<double>.generate(
            row.length,
            (i) => row[i] * vector[i],
          ).reduce((a, b) => a + b),
        )
        .toList(growable: false);
  }

  double combination(int n, int k) {
    if (n < 0 || k < 0 || k > n) {
      return 0;
    }
    final r = math.min(k, n - k);
    var value = 1.0;
    for (var i = 1; i <= r; i++) {
      value = value * (n - r + i) / i;
    }
    return value;
  }

  double permutation(int n, int k) {
    if (n < 0 || k < 0 || k > n) {
      return 0;
    }
    var value = 1.0;
    for (var i = 0; i < k; i++) {
      value *= n - i;
    }
    return value;
  }

  double binomialPmf({required int n, required int k, required double p}) {
    _validateBinomialInputs(n, p);
    if (k < 0 || k > n) return 0;
    if (p == 0) return k == 0 ? 1 : 0;
    if (p == 1) return k == n ? 1 : 0;
    return combination(n, k) * math.pow(p, k) * math.pow(1 - p, n - k);
  }

  double binomialCdf({required int n, required int k, required double p}) {
    _validateBinomialInputs(n, p);
    if (k < 0) return 0;
    if (k >= n) return 1;
    var value = 0.0;
    for (var i = 0; i <= k; i++) {
      value += binomialPmf(n: n, k: i, p: p);
    }
    return value;
  }

  double normalPdf({
    required double mean,
    required double standardDeviation,
    required double x,
  }) {
    if (!mean.isFinite ||
        !standardDeviation.isFinite ||
        !x.isFinite ||
        standardDeviation <= 0) {
      throw const FormatException('invalid standard deviation');
    }
    final z = (x - mean) / standardDeviation;
    return math.exp(-0.5 * z * z) /
        (standardDeviation * math.sqrt(2 * math.pi));
  }

  double normalCdf({
    required double mean,
    required double standardDeviation,
    required double x,
  }) {
    if (!mean.isFinite ||
        !standardDeviation.isFinite ||
        !x.isFinite ||
        standardDeviation <= 0) {
      throw const FormatException('invalid standard deviation');
    }
    final z = (x - mean) / (standardDeviation * math.sqrt2);
    return 0.5 * (1 + _erf(z));
  }

  String formatNumber(num? value) {
    if (value == null || !value.isFinite) {
      return '--';
    }
    final asDouble = value.toDouble();
    if (asDouble == asDouble.roundToDouble() && asDouble.abs() < 1e12) {
      return asDouble.toStringAsFixed(0);
    }
    final fixed =
        asDouble.abs() >= 1e9 || asDouble.abs() < 1e-6 && asDouble != 0
        ? asDouble.toStringAsExponential(8)
        : asDouble.toStringAsPrecision(12);
    return fixed
        .replaceFirstMapped(
          RegExp(r'\.?0+(e|$)'),
          (match) => match.group(1) ?? '',
        )
        .replaceFirst(RegExp(r'e\+'), 'e');
  }

  void _validateBinomialInputs(int n, double p) {
    if (n < 0 || !p.isFinite || p < 0 || p > 1) {
      throw const FormatException('invalid binomial inputs');
    }
  }

  double _erf(double x) {
    final sign = x < 0 ? -1 : 1;
    final ax = x.abs();
    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    const p = 0.3275911;
    final t = 1 / (1 + p * ax);
    final y =
        1 -
        (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) *
            t *
            math.exp(-ax * ax);
    return sign * y;
  }
}

class _ScientificExpressionParser {
  _ScientificExpressionParser(
    this.source, {
    required this.angleMode,
    this.variables = const <String, double>{},
  });

  final String source;
  final ScientificAngleMode angleMode;
  final Map<String, double> variables;
  int _index = 0;

  bool get _degreeMode => angleMode == ScientificAngleMode.degree;

  double parse() {
    final value = _parseExpression();
    _skipSpace();
    if (_index != source.length) {
      throw const FormatException('trailing token');
    }
    if (!value.isFinite) {
      throw const FormatException('non-finite result');
    }
    return value;
  }

  double _parseExpression() {
    var value = _parseTerm();
    while (true) {
      _skipSpace();
      if (_match('+')) {
        value += _parseTerm();
      } else if (_match('-')) {
        value -= _parseTerm();
      } else {
        return value;
      }
    }
  }

  double _parseTerm() {
    var value = _parseUnary();
    while (true) {
      _skipSpace();
      if (_match('*') || _match('×')) {
        value *= _parseUnary();
      } else if (_match('/') || _match('÷')) {
        value /= _parseUnary();
      } else if (_match('%')) {
        value %= _parseUnary();
      } else if (_canStartImplicitFactor()) {
        value *= _parseUnary();
      } else {
        return value;
      }
    }
  }

  double _parsePower() {
    var value = _parsePostfix();
    _skipSpace();
    if (_match('^')) {
      value = math.pow(value, _parseUnary()).toDouble();
    }
    return value;
  }

  double _parseUnary() {
    _skipSpace();
    if (_match('+')) {
      return _parseUnary();
    }
    if (_match('-')) {
      return -_parseUnary();
    }
    return _parsePower();
  }

  double _parsePostfix() {
    var value = _parsePrimary();
    while (true) {
      _skipSpace();
      if (_match('!')) {
        value = _factorial(value);
      } else {
        return value;
      }
    }
  }

  double _parsePrimary() {
    _skipSpace();
    if (_match('(')) {
      final value = _parseExpression();
      if (!_match(')')) {
        throw const FormatException('missing close paren');
      }
      return value;
    }
    if (_match('√')) {
      return math.sqrt(_parseUnary());
    }
    if (_peekLetter()) {
      final name = _readIdentifier().toLowerCase();
      if (variables.containsKey(name)) {
        return variables[name]!;
      }
      if (name == 'pi') {
        return math.pi;
      }
      if (name == 'tau') {
        return math.pi * 2;
      }
      if (name == 'phi') {
        return (1 + math.sqrt(5)) / 2;
      }
      if (name == 'e') {
        return math.e;
      }
      final hasParen = _match('(');
      final arguments = hasParen
          ? _parseArgumentList()
          : <double>[_parseUnary()];
      if (hasParen && !_match(')')) {
        throw const FormatException('missing function close paren');
      }
      return _applyFunction(name, arguments);
    }
    return _readNumber();
  }

  List<double> _parseArgumentList() {
    _skipSpace();
    if (_peek(')')) {
      return const <double>[];
    }
    final values = <double>[];
    while (true) {
      values.add(_parseExpression());
      _skipSpace();
      if (!_match(',')) {
        return values;
      }
    }
  }

  double _applyFunction(String name, List<double> values) {
    if (values.isEmpty) {
      throw const FormatException('missing function argument');
    }
    final value = values.first;
    final angle = _degreeMode ? value * math.pi / 180 : value;
    return switch (name) {
      'sin' => _one(values, math.sin(angle)),
      'cos' => _one(values, math.cos(angle)),
      'tan' => _one(values, math.tan(angle)),
      'sec' => _one(values, 1 / math.cos(angle)),
      'csc' => _one(values, 1 / math.sin(angle)),
      'cot' => _one(values, 1 / math.tan(angle)),
      'asin' || 'arcsin' => _one(values, _fromAngle(math.asin(value))),
      'acos' || 'arccos' => _one(values, _fromAngle(math.acos(value))),
      'atan' || 'arctan' => _one(values, _fromAngle(math.atan(value))),
      'asec' => _one(values, _fromAngle(math.acos(1 / value))),
      'acsc' => _one(values, _fromAngle(math.asin(1 / value))),
      'acot' => _one(values, _fromAngle(math.atan(1 / value))),
      'sinh' => _one(values, _sinh(value)),
      'cosh' => _one(values, _cosh(value)),
      'tanh' => _one(values, _tanh(value)),
      'asinh' => _one(values, math.log(value + math.sqrt(value * value + 1))),
      'acosh' => _one(values, math.log(value + math.sqrt(value * value - 1))),
      'atanh' => _one(values, 0.5 * math.log((1 + value) / (1 - value))),
      'sqrt' => _one(values, math.sqrt(value)),
      'cbrt' => _one(
        values,
        value < 0 ? -_nthRoot(-value, 3) : _nthRoot(value, 3),
      ),
      'root' => _two(values, (n, x) {
        if (x < 0) {
          final degree = _asNonNegativeInt(n);
          if (!degree.isOdd) {
            throw const FormatException('even root of negative value');
          }
          return -_nthRoot(-x, degree.toDouble());
        }
        return _nthRoot(x, n);
      }),
      'ln' => _one(values, math.log(value)),
      'log' =>
        values.length == 1
            ? math.log(value) / math.ln10
            : _two(values, (base, x) => math.log(x) / math.log(base)),
      'log2' => _one(values, math.log(value) / math.ln2),
      'log10' => _one(values, math.log(value) / math.ln10),
      'abs' => _one(values, value.abs()),
      'exp' => _one(values, math.exp(value)),
      'floor' => _one(values, value.floorToDouble()),
      'ceil' => _one(values, value.ceilToDouble()),
      'round' => _one(values, value.roundToDouble()),
      'pow' => _two(
        values,
        (base, exponent) => math.pow(base, exponent).toDouble(),
      ),
      'hypot' => _two(values, (a, b) => math.sqrt(a * a + b * b)),
      'atan2' => _two(values, (y, x) => _fromAngle(math.atan2(y, x))),
      'min' => values.reduce(math.min),
      'max' => values.reduce(math.max),
      'gcd' => _multiInt(values, _gcd).toDouble(),
      'lcm' => _multiInt(values, _lcm).toDouble(),
      'fact' || 'factorial' => _one(values, _factorial(value)),
      'ncr' || 'comb' || 'combination' => _two(
        values,
        (n, k) => _combination(_asNonNegativeInt(n), _asNonNegativeInt(k)),
      ),
      'npr' || 'perm' || 'permutation' => _two(
        values,
        (n, k) => _permutation(_asNonNegativeInt(n), _asNonNegativeInt(k)),
      ),
      _ => throw const FormatException('unknown function'),
    };
  }

  double _one(List<double> values, double result) {
    if (values.length != 1) {
      throw const FormatException('wrong argument count');
    }
    return result;
  }

  double _two(List<double> values, double Function(double, double) apply) {
    if (values.length != 2) {
      throw const FormatException('wrong argument count');
    }
    return apply(values[0], values[1]);
  }

  int _multiInt(List<double> values, int Function(int, int) apply) {
    if (values.length < 2) {
      throw const FormatException('wrong argument count');
    }
    return values.map(_asNonNegativeInt).reduce(apply);
  }

  double _factorial(double value) {
    final n = _asNonNegativeInt(value);
    if (n > 170) {
      throw const FormatException('factorial too large');
    }
    var result = 1.0;
    for (var i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }

  int _asNonNegativeInt(double value) {
    if (!value.isFinite ||
        value < 0 ||
        (value - value.roundToDouble()).abs() > 1e-10) {
      throw const FormatException('integer expected');
    }
    return value.round();
  }

  int _gcd(int a, int b) {
    var x = a.abs();
    var y = b.abs();
    while (y != 0) {
      final next = x % y;
      x = y;
      y = next;
    }
    return x;
  }

  int _lcm(int a, int b) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (a ~/ _gcd(a, b) * b).abs();
  }

  double _combination(int n, int k) {
    if (k < 0 || k > n) {
      return 0;
    }
    final r = math.min(k, n - k);
    var value = 1.0;
    for (var i = 1; i <= r; i++) {
      value = value * (n - r + i) / i;
    }
    return value;
  }

  double _permutation(int n, int k) {
    if (k < 0 || k > n) {
      return 0;
    }
    var value = 1.0;
    for (var i = 0; i < k; i++) {
      value *= n - i;
    }
    return value;
  }

  double _nthRoot(double value, double degree) {
    if (degree == 0) {
      throw const FormatException('zero root');
    }
    return math.pow(value, 1 / degree).toDouble();
  }

  double _sinh(double value) => (math.exp(value) - math.exp(-value)) / 2;

  double _cosh(double value) => (math.exp(value) + math.exp(-value)) / 2;

  double _tanh(double value) {
    final positive = math.exp(value);
    final negative = math.exp(-value);
    return (positive - negative) / (positive + negative);
  }

  double _fromAngle(double radians) {
    return _degreeMode ? radians * 180 / math.pi : radians;
  }

  double _readNumber() {
    _skipSpace();
    final start = _index;
    var seenDot = false;
    while (_index < source.length) {
      final code = source.codeUnitAt(_index);
      final isDigit = code >= 0x30 && code <= 0x39;
      if (isDigit) {
        _index += 1;
        continue;
      }
      if (code == 0x2E && !seenDot) {
        seenDot = true;
        _index += 1;
        continue;
      }
      if ((code == 0x65 || code == 0x45) && _index > start) {
        _index += 1;
        if (_index < source.length &&
            (source[_index] == '+' || source[_index] == '-')) {
          _index += 1;
        }
        continue;
      }
      break;
    }
    if (start == _index) {
      throw const FormatException('number expected');
    }
    return double.parse(source.substring(start, _index));
  }

  String _readIdentifier() {
    final start = _index;
    while (_index < source.length && _peekIdentifierPart()) {
      _index += 1;
    }
    return source.substring(start, _index);
  }

  bool _peekLetter() {
    if (_index >= source.length) {
      return false;
    }
    final code = source.codeUnitAt(_index);
    return (code >= 0x41 && code <= 0x5A) ||
        (code >= 0x61 && code <= 0x7A) ||
        code == 0x5F;
  }

  bool _peekIdentifierPart() {
    if (_peekLetter()) {
      return true;
    }
    if (_index >= source.length) {
      return false;
    }
    final code = source.codeUnitAt(_index);
    return code >= 0x30 && code <= 0x39;
  }

  bool _match(String token) {
    _skipSpace();
    if (!source.startsWith(token, _index)) {
      return false;
    }
    _index += token.length;
    return true;
  }

  bool _peek(String token) {
    _skipSpace();
    return source.startsWith(token, _index);
  }

  bool _canStartImplicitFactor() {
    _skipSpace();
    if (_index >= source.length) {
      return false;
    }
    final char = source[_index];
    if (char == ')' || char == ',') {
      return false;
    }
    final code = source.codeUnitAt(_index);
    return char == '(' ||
        char == '√' ||
        (code >= 0x30 && code <= 0x39) ||
        code == 0x2E ||
        _peekLetter();
  }

  void _skipSpace() {
    while (_index < source.length && source.codeUnitAt(_index) <= 0x20) {
      _index += 1;
    }
  }
}

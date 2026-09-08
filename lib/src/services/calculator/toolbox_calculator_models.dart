enum ToolboxCalculatorOperation {
  evaluate('evaluate'),
  approximate('approximate'),
  simplify('simplify'),
  expand('expand'),
  factor('factor'),
  partialFraction('partialFraction'),
  substitute('substitute'),
  solveEquation('solveEquation'),
  solveSystem('solveSystem'),
  differentiate('differentiate'),
  integrate('integrate'),
  definiteIntegral('definiteIntegral'),
  limit('limit'),
  taylor('taylor'),
  summation('summation'),
  product('product'),
  laplace('laplace'),
  inverseLaplace('inverseLaplace'),
  gradient('gradient'),
  divergence('divergence'),
  curl('curl'),
  hessian('hessian'),
  matrixAdd('matrixAdd'),
  matrixSubtract('matrixSubtract'),
  matrixMultiply('matrixMultiply'),
  scalarMultiply('scalarMultiply'),
  matrixPower('matrixPower'),
  determinant('determinant'),
  inverse('inverse'),
  transpose('transpose'),
  trace('trace'),
  rank('rank'),
  rref('rref'),
  solveLinearSystem('solveLinearSystem'),
  characteristicPolynomial('characteristicPolynomial'),
  eigenvalues('eigenvalues'),
  eigenvectors('eigenvectors'),
  nullSpace('nullSpace'),
  columnSpace('columnSpace'),
  rowSpace('rowSpace'),
  luDecomposition('luDecomposition'),
  qrDecomposition('qrDecomposition'),
  leastSquares('leastSquares'),
  gramSchmidt('gramSchmidt'),
  dotProduct('dotProduct'),
  crossProduct('crossProduct'),
  vectorNorm('vectorNorm'),
  vectorProjection('vectorProjection'),
  complexRealPart('complexRealPart'),
  complexImaginaryPart('complexImaginaryPart'),
  complexConjugate('complexConjugate'),
  complexMagnitude('complexMagnitude'),
  complexArgument('complexArgument'),
  complexPolarForm('complexPolarForm'),
  complexRectangularForm('complexRectangularForm'),
  complexFromPolar('complexFromPolar');

  const ToolboxCalculatorOperation(this.wireName);

  final String wireName;

  static ToolboxCalculatorOperation fromWireName(Object? value) {
    return values.firstWhere(
      (item) => item.wireName == value,
      orElse: () => ToolboxCalculatorOperation.evaluate,
    );
  }
}

enum ToolboxCalculatorAngleUnit {
  degree('degree'),
  radian('radian');

  const ToolboxCalculatorAngleUnit(this.wireName);

  final String wireName;

  static ToolboxCalculatorAngleUnit fromWireName(Object? value) {
    return values.firstWhere(
      (item) => item.wireName == value,
      orElse: () => ToolboxCalculatorAngleUnit.radian,
    );
  }
}

enum ToolboxCalculatorResultType {
  expression,
  vector,
  matrix,
  equationSet,
  boolean,
  unknown;

  static ToolboxCalculatorResultType fromWireName(Object? value) {
    return values.firstWhere(
      (item) => item.name == value,
      orElse: () => ToolboxCalculatorResultType.unknown,
    );
  }
}

enum ToolboxCalculatorBackend {
  nerdamerPrime,
  algebrite,
  numeric,
  unknown;

  String get wireName => switch (this) {
    ToolboxCalculatorBackend.nerdamerPrime => 'nerdamer-prime',
    ToolboxCalculatorBackend.algebrite => 'algebrite',
    ToolboxCalculatorBackend.numeric => 'numeric',
    ToolboxCalculatorBackend.unknown => 'unknown',
  };

  static ToolboxCalculatorBackend fromWireName(Object? value) {
    return switch (value) {
      'nerdamer-prime' => ToolboxCalculatorBackend.nerdamerPrime,
      'algebrite' => ToolboxCalculatorBackend.algebrite,
      'numeric' => ToolboxCalculatorBackend.numeric,
      _ => ToolboxCalculatorBackend.unknown,
    };
  }
}

enum ToolboxCalculatorFailureCode {
  invalidInput,
  unsupported,
  timeout,
  resourceLimit,
  engineUnavailable,
  computation;

  static ToolboxCalculatorFailureCode fromWireName(Object? value) {
    return values.firstWhere(
      (item) => item.name == value,
      orElse: () => ToolboxCalculatorFailureCode.computation,
    );
  }
}

class ToolboxCalculatorRequest {
  const ToolboxCalculatorRequest({
    required this.operation,
    this.angleUnit = ToolboxCalculatorAngleUnit.radian,
    this.expression,
    this.secondaryExpression,
    this.variable = 'x',
    this.targetVariable,
    this.lowerBound,
    this.upperBound,
    this.point,
    this.order,
    this.equations = const <String>[],
    this.expressions = const <String>[],
    this.variables = const <String>[],
    this.substitutions = const <String, String>{},
    this.matrix,
    this.secondaryMatrix,
    this.vector,
    this.secondaryVector,
    this.scalar,
    this.radius,
    this.angle,
    this.definitions = const <ToolboxCalculatorDefinition>[],
  });

  final ToolboxCalculatorOperation operation;
  final ToolboxCalculatorAngleUnit angleUnit;
  final String? expression;
  final String? secondaryExpression;
  final String variable;
  final String? targetVariable;
  final String? lowerBound;
  final String? upperBound;
  final String? point;
  final int? order;
  final List<String> equations;
  final List<String> expressions;
  final List<String> variables;
  final Map<String, String> substitutions;
  final List<List<String>>? matrix;
  final List<List<String>>? secondaryMatrix;
  final List<String>? vector;
  final List<String>? secondaryVector;
  final String? scalar;
  final String? radius;
  final String? angle;
  final List<ToolboxCalculatorDefinition> definitions;

  ToolboxCalculatorRequest withSubstitutions(
    Map<String, String> additionalSubstitutions,
  ) {
    return ToolboxCalculatorRequest(
      operation: operation,
      angleUnit: angleUnit,
      expression: expression,
      secondaryExpression: secondaryExpression,
      variable: variable,
      targetVariable: targetVariable,
      lowerBound: lowerBound,
      upperBound: upperBound,
      point: point,
      order: order,
      equations: equations,
      expressions: expressions,
      variables: variables,
      substitutions: <String, String>{
        ...additionalSubstitutions,
        ...substitutions,
      },
      matrix: matrix,
      secondaryMatrix: secondaryMatrix,
      vector: vector,
      secondaryVector: secondaryVector,
      scalar: scalar,
      radius: radius,
      angle: angle,
      definitions: definitions,
    );
  }

  ToolboxCalculatorRequest withSessionContext({
    required ToolboxCalculatorAngleUnit angleUnit,
    required Map<String, String> substitutions,
    required List<ToolboxCalculatorDefinition> definitions,
  }) {
    return ToolboxCalculatorRequest(
      operation: operation,
      angleUnit: angleUnit,
      expression: expression,
      secondaryExpression: secondaryExpression,
      variable: variable,
      targetVariable: targetVariable,
      lowerBound: lowerBound,
      upperBound: upperBound,
      point: point,
      order: order,
      equations: equations,
      expressions: expressions,
      variables: variables,
      substitutions: <String, String>{...substitutions, ...this.substitutions},
      matrix: matrix,
      secondaryMatrix: secondaryMatrix,
      vector: vector,
      secondaryVector: secondaryVector,
      scalar: scalar,
      radius: radius,
      angle: angle,
      definitions: <ToolboxCalculatorDefinition>[
        ...definitions,
        ...this.definitions,
      ],
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'version': 1,
      'operation': operation.wireName,
      'angleUnit': angleUnit.wireName,
      if (expression != null) 'expression': expression,
      if (secondaryExpression != null)
        'secondaryExpression': secondaryExpression,
      'variable': variable,
      if (targetVariable != null) 'targetVariable': targetVariable,
      if (lowerBound != null) 'lowerBound': lowerBound,
      if (upperBound != null) 'upperBound': upperBound,
      if (point != null) 'point': point,
      if (order != null) 'order': order,
      if (equations.isNotEmpty) 'equations': equations,
      if (expressions.isNotEmpty) 'expressions': expressions,
      if (variables.isNotEmpty) 'variables': variables,
      if (substitutions.isNotEmpty) 'substitutions': substitutions,
      if (matrix != null) 'matrix': matrix,
      if (secondaryMatrix != null) 'secondaryMatrix': secondaryMatrix,
      if (vector != null) 'vector': vector,
      if (secondaryVector != null) 'secondaryVector': secondaryVector,
      if (scalar != null) 'scalar': scalar,
      if (radius != null) 'radius': radius,
      if (angle != null) 'angle': angle,
      if (definitions.isNotEmpty)
        'definitions': definitions
            .map((definition) => definition.toJson())
            .toList(growable: false),
    };
  }
}

class ToolboxCalculatorDefinition {
  const ToolboxCalculatorDefinition({
    required this.name,
    required this.expression,
    this.parameters = const <String>[],
  });

  factory ToolboxCalculatorDefinition.fromJsonValue(Object? value) {
    if (value is! Map) {
      throw const FormatException('Invalid calculator definition');
    }
    final map = value.cast<Object?, Object?>();
    final rawParameters = map['parameters'];
    if (rawParameters != null && rawParameters is! List) {
      throw const FormatException('Invalid calculator definition parameters');
    }
    return ToolboxCalculatorDefinition(
      name: '${map['name'] ?? ''}'.trim(),
      expression: '${map['expression'] ?? ''}'.trim(),
      parameters: rawParameters is List
          ? rawParameters.map((item) => '$item'.trim()).toList(growable: false)
          : const <String>[],
    );
  }

  final String name;
  final String expression;
  final List<String> parameters;

  bool get isFunction => parameters.isNotEmpty;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'expression': expression,
      if (parameters.isNotEmpty) 'parameters': parameters,
    };
  }
}

class ToolboxCalculatorResultPart {
  const ToolboxCalculatorResultPart({
    required this.id,
    required this.exact,
    required this.latex,
    required this.type,
    this.approximate,
  });

  factory ToolboxCalculatorResultPart.fromJsonValue(Object? value) {
    if (value is! Map) {
      throw const FormatException('Invalid calculator result part');
    }
    final map = value.cast<Object?, Object?>();
    final id = '${map['id'] ?? ''}'.trim();
    final exact = '${map['exact'] ?? ''}'.trim();
    if (id.isEmpty || exact.isEmpty) {
      throw const FormatException('Incomplete calculator result part');
    }
    return ToolboxCalculatorResultPart(
      id: id,
      exact: exact,
      latex: '${map['latex'] ?? ''}',
      approximate: ToolboxCalculatorResult._optionalText(map['approximate']),
      type: ToolboxCalculatorResultType.fromWireName(map['type']),
    );
  }

  final String id;
  final String exact;
  final String latex;
  final String? approximate;
  final ToolboxCalculatorResultType type;

  bool get hasApproximation => approximate != null && approximate!.isNotEmpty;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'exact': exact,
      'latex': latex,
      if (approximate != null) 'approximate': approximate,
      'type': type.name,
    };
  }
}

class ToolboxCalculatorResult {
  const ToolboxCalculatorResult({
    required this.operation,
    required this.exact,
    required this.latex,
    required this.type,
    required this.backend,
    this.approximate,
    this.unevaluated = false,
    this.warnings = const <String>[],
    this.parts = const <ToolboxCalculatorResultPart>[],
  });

  factory ToolboxCalculatorResult.fromJson(
    Map<String, Object?> json,
    ToolboxCalculatorOperation fallbackOperation,
  ) {
    final operationName = json['operation'];
    final operation = ToolboxCalculatorOperation.values.firstWhere(
      (item) => item.wireName == operationName,
      orElse: () => fallbackOperation,
    );
    final warnings = json['warnings'];
    final parts = json['parts'];
    final exact = json['exact']?.toString().trim() ?? '';
    if (exact.isEmpty) {
      throw const FormatException('Calculator result is empty');
    }
    return ToolboxCalculatorResult(
      operation: operation,
      exact: exact,
      latex: json['latex']?.toString() ?? '',
      approximate: _optionalText(json['approximate']),
      type: ToolboxCalculatorResultType.fromWireName(json['type']),
      backend: ToolboxCalculatorBackend.fromWireName(json['backend']),
      unevaluated: json['unevaluated'] == true,
      warnings: warnings is List<Object?>
          ? warnings.map((item) => item.toString()).toList(growable: false)
          : const <String>[],
      parts: parts is List
          ? parts
                .map(ToolboxCalculatorResultPart.fromJsonValue)
                .toList(growable: false)
          : const <ToolboxCalculatorResultPart>[],
    );
  }

  final ToolboxCalculatorOperation operation;
  final String exact;
  final String latex;
  final String? approximate;
  final ToolboxCalculatorResultType type;
  final ToolboxCalculatorBackend backend;
  final bool unevaluated;
  final List<String> warnings;
  final List<ToolboxCalculatorResultPart> parts;

  bool get hasApproximation => approximate != null && approximate!.isNotEmpty;
  bool get isComposite =>
      type == ToolboxCalculatorResultType.unknown && parts.isNotEmpty;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'operation': operation.wireName,
      'exact': exact,
      'latex': latex,
      if (approximate != null) 'approximate': approximate,
      'type': type.name,
      'backend': backend.wireName,
      'unevaluated': unevaluated,
      if (warnings.isNotEmpty) 'warnings': warnings,
      if (parts.isNotEmpty)
        'parts': parts.map((part) => part.toJson()).toList(growable: false),
    };
  }

  static String? _optionalText(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class ToolboxCalculatorHistoryEntry {
  const ToolboxCalculatorHistoryEntry({
    required this.id,
    required this.expression,
    required this.result,
    required this.createdAt,
  });

  final int id;
  final String expression;
  final ToolboxCalculatorResult result;
  final DateTime createdAt;

  factory ToolboxCalculatorHistoryEntry.fromJsonValue(Object? value) {
    if (value is! Map) {
      throw const FormatException('Invalid calculator history entry');
    }
    final map = value.cast<Object?, Object?>();
    final rawResult = map['result'];
    if (rawResult is! Map) {
      throw const FormatException('Invalid calculator history result');
    }
    final resultMap = rawResult.cast<String, Object?>();
    final operation = ToolboxCalculatorOperation.fromWireName(
      resultMap['operation'],
    );
    final createdAt = DateTime.tryParse('${map['createdAt'] ?? ''}');
    if (createdAt == null) {
      throw const FormatException('Invalid calculator history timestamp');
    }
    return ToolboxCalculatorHistoryEntry(
      id: (map['id'] as num?)?.toInt() ?? 0,
      expression: '${map['expression'] ?? ''}',
      result: ToolboxCalculatorResult.fromJson(resultMap, operation),
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'expression': expression,
      'result': result.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

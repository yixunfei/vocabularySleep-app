import 'toolbox_calculator_models.dart';

enum ToolboxCalculatorDefinitionFailure {
  limit,
  invalidName,
  reservedName,
  duplicateName,
  invalidParameters,
  invalidExpression,
  cyclicDependency,
}

class ToolboxCalculatorDefinitionException implements Exception {
  const ToolboxCalculatorDefinitionException(this.failure);

  final ToolboxCalculatorDefinitionFailure failure;

  String get i18nKey => switch (failure) {
    ToolboxCalculatorDefinitionFailure.limit =>
      'toolbox.life.advanced_calculator.definition.error.limit',
    ToolboxCalculatorDefinitionFailure.invalidName =>
      'toolbox.life.advanced_calculator.definition.error.invalidName',
    ToolboxCalculatorDefinitionFailure.reservedName =>
      'toolbox.life.advanced_calculator.definition.error.reservedName',
    ToolboxCalculatorDefinitionFailure.duplicateName =>
      'toolbox.life.advanced_calculator.definition.error.duplicateName',
    ToolboxCalculatorDefinitionFailure.invalidParameters =>
      'toolbox.life.advanced_calculator.definition.error.invalidParameters',
    ToolboxCalculatorDefinitionFailure.invalidExpression =>
      'toolbox.life.advanced_calculator.definition.error.invalidExpression',
    ToolboxCalculatorDefinitionFailure.cyclicDependency =>
      'toolbox.life.advanced_calculator.definition.error.cyclicDependency',
  };
}

class ToolboxCalculatorDefinitionValidator {
  const ToolboxCalculatorDefinitionValidator();

  static const int maxDefinitions = 32;
  static const int maxParameters = 4;
  static const int maxNameLength = 32;
  static const int maxExpressionLength = 2000;

  static final RegExp _identifier = RegExp(
    r'^[A-Za-z_\u0370-\u03ff][A-Za-z0-9_\u0370-\u03ff]*$',
    unicode: true,
  );
  static final RegExp _identifierToken = RegExp(
    r'[A-Za-z_\u0370-\u03ff][A-Za-z0-9_\u0370-\u03ff]*',
    unicode: true,
  );

  static const Set<String> _reservedNames = <String>{
    'ans',
    'mem',
    'pi',
    'tau',
    'phi',
    'e',
    'i',
    'infinity',
    'sin',
    'cos',
    'tan',
    'asin',
    'acos',
    'atan',
    'atan2',
    'sinh',
    'cosh',
    'tanh',
    'log',
    'ln',
    'exp',
    'sqrt',
    'cbrt',
    'root',
    'abs',
    'floor',
    'ceil',
    'round',
    'min',
    'max',
    'mod',
    'gcd',
    'lcm',
    'ncr',
    'npr',
    'factor',
    'diff',
    'integrate',
    'limit',
    'sum',
    'product',
    'matrix',
    'vector',
    'det',
    'transpose',
    'realpart',
    'imagpart',
    'conjugate',
    'arg',
  };

  void validate(List<ToolboxCalculatorDefinition> definitions) {
    if (definitions.length > maxDefinitions) {
      throw const ToolboxCalculatorDefinitionException(
        ToolboxCalculatorDefinitionFailure.limit,
      );
    }
    final names = <String>{};
    for (final definition in definitions) {
      _validateDefinition(definition);
      final normalizedName = definition.name.toLowerCase();
      if (!names.add(normalizedName)) {
        throw const ToolboxCalculatorDefinitionException(
          ToolboxCalculatorDefinitionFailure.duplicateName,
        );
      }
    }
    _validateDependencies(definitions);
  }

  void _validateDefinition(ToolboxCalculatorDefinition definition) {
    final name = definition.name.trim();
    if (name.isEmpty ||
        name.length > maxNameLength ||
        !_identifier.hasMatch(name)) {
      throw const ToolboxCalculatorDefinitionException(
        ToolboxCalculatorDefinitionFailure.invalidName,
      );
    }
    if (_reservedNames.contains(name.toLowerCase()) ||
        name.startsWith('__calc_')) {
      throw const ToolboxCalculatorDefinitionException(
        ToolboxCalculatorDefinitionFailure.reservedName,
      );
    }
    final expression = definition.expression.trim();
    if (expression.isEmpty ||
        expression.length > maxExpressionLength ||
        expression.contains(':=') ||
        expression.contains('\n') ||
        expression.contains('\r') ||
        expression.contains('\u0000')) {
      throw const ToolboxCalculatorDefinitionException(
        ToolboxCalculatorDefinitionFailure.invalidExpression,
      );
    }
    if (definition.parameters.length > maxParameters) {
      throw const ToolboxCalculatorDefinitionException(
        ToolboxCalculatorDefinitionFailure.invalidParameters,
      );
    }
    final parameters = <String>{};
    for (final parameter in definition.parameters) {
      final normalized = parameter.trim();
      if (normalized.isEmpty ||
          normalized.length > maxNameLength ||
          !_identifier.hasMatch(normalized) ||
          normalized.toLowerCase() == name.toLowerCase() ||
          _reservedNames.contains(normalized.toLowerCase()) ||
          !parameters.add(normalized.toLowerCase())) {
        throw const ToolboxCalculatorDefinitionException(
          ToolboxCalculatorDefinitionFailure.invalidParameters,
        );
      }
    }
  }

  void _validateDependencies(List<ToolboxCalculatorDefinition> definitions) {
    final byName = <String, ToolboxCalculatorDefinition>{
      for (final definition in definitions)
        definition.name.toLowerCase(): definition,
    };
    final dependencies = <String, Set<String>>{};
    for (final entry in byName.entries) {
      final parameters = entry.value.parameters
          .map((parameter) => parameter.toLowerCase())
          .toSet();
      dependencies[entry.key] = _identifierToken
          .allMatches(entry.value.expression)
          .map((match) => match.group(0)!.toLowerCase())
          .where(
            (token) => byName.containsKey(token) && !parameters.contains(token),
          )
          .toSet();
    }

    final state = <String, int>{};
    bool visit(String name) {
      final current = state[name] ?? 0;
      if (current == 1) return false;
      if (current == 2) return true;
      state[name] = 1;
      for (final dependency in dependencies[name] ?? const <String>{}) {
        if (!visit(dependency)) return false;
      }
      state[name] = 2;
      return true;
    }

    for (final name in byName.keys) {
      if (!visit(name)) {
        throw const ToolboxCalculatorDefinitionException(
          ToolboxCalculatorDefinitionFailure.cyclicDependency,
        );
      }
    }
  }
}

import 'toolbox_calculator_models.dart';

abstract interface class ToolboxCalculatorEngine {
  Future<ToolboxCalculatorResult> calculate(ToolboxCalculatorRequest request);

  Future<void> dispose();
}

class ToolboxCalculatorEngineException implements Exception {
  const ToolboxCalculatorEngineException(this.code, {this.technicalMessage});

  final ToolboxCalculatorFailureCode code;
  final String? technicalMessage;

  String get i18nKey => switch (code) {
    ToolboxCalculatorFailureCode.invalidInput =>
      'toolbox.life.advanced_calculator.error.invalid_input',
    ToolboxCalculatorFailureCode.unsupported =>
      'toolbox.life.advanced_calculator.error.unsupported',
    ToolboxCalculatorFailureCode.timeout =>
      'toolbox.life.advanced_calculator.error.timeout',
    ToolboxCalculatorFailureCode.resourceLimit =>
      'toolbox.life.advanced_calculator.error.resource_limit',
    ToolboxCalculatorFailureCode.engineUnavailable =>
      'toolbox.life.advanced_calculator.error.engine_unavailable',
    ToolboxCalculatorFailureCode.computation =>
      'toolbox.life.advanced_calculator.error.computation',
  };

  @override
  String toString() {
    final details = technicalMessage;
    return details == null
        ? 'ToolboxCalculatorEngineException(${code.name})'
        : 'ToolboxCalculatorEngineException(${code.name}): $details';
  }
}

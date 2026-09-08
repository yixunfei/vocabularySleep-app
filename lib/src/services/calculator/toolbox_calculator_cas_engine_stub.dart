import 'package:flutter/services.dart';

import 'toolbox_calculator_engine.dart';
import 'toolbox_calculator_models.dart';

ToolboxCalculatorEngine createPlatformCalculatorEngine({
  AssetBundle? assetBundle,
  required Duration calculationTimeout,
}) {
  return const _UnavailableCalculatorEngine();
}

class _UnavailableCalculatorEngine implements ToolboxCalculatorEngine {
  const _UnavailableCalculatorEngine();

  @override
  Future<ToolboxCalculatorResult> calculate(ToolboxCalculatorRequest request) {
    throw const ToolboxCalculatorEngineException(
      ToolboxCalculatorFailureCode.engineUnavailable,
      technicalMessage: 'The native symbolic runtime is unavailable.',
    );
  }

  @override
  Future<void> dispose() async {}
}

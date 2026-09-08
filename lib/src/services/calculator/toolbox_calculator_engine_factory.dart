import 'package:flutter/services.dart';

import 'toolbox_calculator_cas_engine_stub.dart'
    if (dart.library.io) 'toolbox_calculator_cas_engine_native.dart'
    as platform;
import 'toolbox_calculator_engine.dart';

ToolboxCalculatorEngine createToolboxCalculatorEngine({
  AssetBundle? assetBundle,
  Duration calculationTimeout = const Duration(seconds: 4),
}) {
  return platform.createPlatformCalculatorEngine(
    assetBundle: assetBundle,
    calculationTimeout: calculationTimeout,
  );
}

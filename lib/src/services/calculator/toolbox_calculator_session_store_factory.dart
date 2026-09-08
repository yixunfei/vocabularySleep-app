import 'toolbox_calculator_session_store.dart';
import 'toolbox_calculator_session_store_stub.dart'
    if (dart.library.io) 'toolbox_calculator_session_store_native.dart'
    as platform;

ToolboxCalculatorSessionStore createToolboxCalculatorSessionStore() {
  return platform.createPlatformCalculatorSessionStore();
}

import 'toolbox_calculator_session_snapshot.dart';

abstract interface class ToolboxCalculatorSessionStore {
  Future<ToolboxCalculatorSessionSnapshot?> load();

  Future<void> save(ToolboxCalculatorSessionSnapshot snapshot);
}

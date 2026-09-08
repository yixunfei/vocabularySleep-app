import 'toolbox_calculator_session_snapshot.dart';
import 'toolbox_calculator_session_store.dart';

ToolboxCalculatorSessionStore createPlatformCalculatorSessionStore() {
  return const _NoopToolboxCalculatorSessionStore();
}

class _NoopToolboxCalculatorSessionStore
    implements ToolboxCalculatorSessionStore {
  const _NoopToolboxCalculatorSessionStore();

  @override
  Future<ToolboxCalculatorSessionSnapshot?> load() async => null;

  @override
  Future<void> save(ToolboxCalculatorSessionSnapshot snapshot) async {}
}

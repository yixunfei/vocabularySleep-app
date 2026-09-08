import 'toolbox_calculator_session_snapshot.dart';
import 'toolbox_calculator_session_store.dart';

class ToolboxCalculatorSessionPersistence {
  ToolboxCalculatorSessionPersistence(this._store);

  final ToolboxCalculatorSessionStore _store;
  ToolboxCalculatorSessionSnapshot? _pendingSnapshot;
  Future<void>? _saveWorker;

  Future<ToolboxCalculatorSessionSnapshot?> restore() => _store.load();

  void schedule(ToolboxCalculatorSessionSnapshot snapshot) {
    _pendingSnapshot = snapshot;
    _saveWorker ??= _drain();
  }

  Future<void> flush(ToolboxCalculatorSessionSnapshot snapshot) async {
    schedule(snapshot);
    while (true) {
      final worker = _saveWorker;
      if (worker == null) {
        break;
      }
      await worker;
    }
  }

  Future<void> _drain() async {
    try {
      while (_pendingSnapshot != null) {
        final snapshot = _pendingSnapshot!;
        _pendingSnapshot = null;
        try {
          await _store.save(snapshot);
        } on Object {
          // Persistence is best effort and must never interrupt calculation.
        }
      }
    } finally {
      _saveWorker = null;
      if (_pendingSnapshot != null) _saveWorker = _drain();
    }
  }
}

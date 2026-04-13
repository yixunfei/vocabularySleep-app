import 'module_registry.dart';
import 'module_toggle_state.dart';

class ModuleRuntimeGuard {
  const ModuleRuntimeGuard(this._toggleState);

  final ModuleToggleState _toggleState;

  bool isEnabled(String moduleId) {
    return _toggleState.isEnabled(moduleId);
  }

  bool canAccess(String moduleId) {
    final descriptor = ModuleRegistry.find(moduleId);
    if (descriptor == null) {
      return true;
    }
    if (!isEnabled(descriptor.id)) {
      return false;
    }
    final parentId = descriptor.parentId;
    if (parentId != null && !isEnabled(parentId)) {
      return false;
    }
    return true;
  }
}

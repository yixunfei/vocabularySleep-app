import 'module_id.dart';
import 'module_registry.dart';

class ModuleToggleState {
  const ModuleToggleState({required this.version, required this.modules});

  static const int currentVersion = 1;

  static final ModuleToggleState defaults = ModuleToggleState(
    version: currentVersion,
    modules: <String, bool>{
      for (final descriptor in ModuleRegistry.descriptors)
        descriptor.id: descriptor.enabledByDefault,
    },
  );

  final int version;
  final Map<String, bool> modules;

  bool isEnabled(String moduleId) {
    final stored = modules[moduleId];
    if (stored != null) {
      return stored;
    }
    final descriptor = ModuleRegistry.find(moduleId);
    return descriptor?.enabledByDefault ?? true;
  }

  ModuleToggleState copyWithModule(String moduleId, bool enabled) {
    final normalized = <String, bool>{
      for (final descriptor in ModuleRegistry.descriptors)
        descriptor.id: isEnabled(descriptor.id),
    };
    normalized[moduleId] = enabled;
    return ModuleToggleState(version: currentVersion, modules: normalized);
  }

  Map<String, Object?> toJsonMap() {
    final normalized = <String, Object?>{
      for (final moduleId in ModuleIds.allModules)
        moduleId: isEnabled(moduleId),
    };
    return <String, Object?>{'version': version, 'modules': normalized};
  }

  static ModuleToggleState fromJsonValue(Object? value) {
    if (value is! Map) {
      return defaults;
    }
    final map = value.cast<Object?, Object?>();
    final rawModules = map['modules'];
    final normalized = <String, bool>{
      for (final descriptor in ModuleRegistry.descriptors)
        descriptor.id: descriptor.enabledByDefault,
    };
    if (rawModules is Map) {
      for (final entry in rawModules.entries) {
        final key = '${entry.key}'.trim();
        if (key.isEmpty || !normalized.containsKey(key)) {
          continue;
        }
        final rawValue = entry.value;
        normalized[key] = switch (rawValue) {
          bool() => rawValue,
          num() => rawValue != 0,
          _ => '${rawValue ?? ''}'.trim() == '1',
        };
      }
    }

    final rawVersion = map['version'];
    final version = switch (rawVersion) {
      int() => rawVersion,
      num() => rawVersion.toInt(),
      _ => currentVersion,
    };
    return ModuleToggleState(version: version, modules: normalized);
  }
}

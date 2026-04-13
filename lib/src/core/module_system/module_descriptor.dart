enum ModuleGroup { topLevel, toolbox }

class ModuleDescriptor {
  const ModuleDescriptor({
    required this.id,
    required this.group,
    this.parentId,
    this.enabledByDefault = true,
    this.canDisable = true,
  });

  final String id;
  final ModuleGroup group;
  final String? parentId;
  final bool enabledByDefault;
  final bool canDisable;
}

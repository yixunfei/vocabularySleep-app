import 'module_descriptor.dart';
import 'module_id.dart';

class ModuleRegistry {
  ModuleRegistry._();

  static const List<ModuleDescriptor> descriptors = <ModuleDescriptor>[
    ModuleDescriptor(id: ModuleIds.study, group: ModuleGroup.topLevel),
    ModuleDescriptor(id: ModuleIds.practice, group: ModuleGroup.topLevel),
    ModuleDescriptor(id: ModuleIds.focus, group: ModuleGroup.topLevel),
    ModuleDescriptor(id: ModuleIds.toolbox, group: ModuleGroup.topLevel),
    ModuleDescriptor(
      id: ModuleIds.more,
      group: ModuleGroup.topLevel,
      canDisable: false,
    ),
    ModuleDescriptor(
      id: ModuleIds.toolboxSleepAssistant,
      group: ModuleGroup.toolbox,
      parentId: ModuleIds.toolbox,
    ),
    ModuleDescriptor(
      id: ModuleIds.toolboxMiniGames,
      group: ModuleGroup.toolbox,
      parentId: ModuleIds.toolbox,
    ),
    ModuleDescriptor(
      id: ModuleIds.toolboxHumanTests,
      group: ModuleGroup.toolbox,
      parentId: ModuleIds.toolbox,
    ),
    ModuleDescriptor(
      id: ModuleIds.toolboxSoothingMusic,
      group: ModuleGroup.toolbox,
      parentId: ModuleIds.toolbox,
    ),
    ModuleDescriptor(
      id: ModuleIds.toolboxSoundDeck,
      group: ModuleGroup.toolbox,
      parentId: ModuleIds.toolbox,
    ),
    ModuleDescriptor(
      id: ModuleIds.toolboxSingingBowls,
      group: ModuleGroup.toolbox,
      parentId: ModuleIds.toolbox,
    ),
    ModuleDescriptor(
      id: ModuleIds.toolboxFocusBeats,
      group: ModuleGroup.toolbox,
      parentId: ModuleIds.toolbox,
    ),
    ModuleDescriptor(
      id: ModuleIds.toolboxWoodfish,
      group: ModuleGroup.toolbox,
      parentId: ModuleIds.toolbox,
    ),
    ModuleDescriptor(
      id: ModuleIds.toolboxSchulteGrid,
      group: ModuleGroup.toolbox,
      parentId: ModuleIds.toolbox,
    ),
    ModuleDescriptor(
      id: ModuleIds.toolboxBreathing,
      group: ModuleGroup.toolbox,
      parentId: ModuleIds.toolbox,
    ),
    ModuleDescriptor(
      id: ModuleIds.toolboxPrayerBeads,
      group: ModuleGroup.toolbox,
      parentId: ModuleIds.toolbox,
    ),
    ModuleDescriptor(
      id: ModuleIds.toolboxZenSand,
      group: ModuleGroup.toolbox,
      parentId: ModuleIds.toolbox,
    ),
    ModuleDescriptor(
      id: ModuleIds.toolboxDailyDecision,
      group: ModuleGroup.toolbox,
      parentId: ModuleIds.toolbox,
    ),
  ];

  static final Map<String, ModuleDescriptor> _byId = <String, ModuleDescriptor>{
    for (final descriptor in descriptors) descriptor.id: descriptor,
  };

  static ModuleDescriptor? find(String moduleId) => _byId[moduleId];

  static List<ModuleDescriptor> descriptorsByGroup(ModuleGroup group) {
    return descriptors
        .where((item) => item.group == group)
        .toList(growable: false);
  }
}

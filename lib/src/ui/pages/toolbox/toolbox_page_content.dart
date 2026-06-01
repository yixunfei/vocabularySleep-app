import 'package:flutter/material.dart';

import '../../../core/module_system/module_id.dart';
import '../../../i18n/app_i18n.dart';
import '../../../models/settings_dto.dart';
import '../../theme/toolbox_colors.dart';
import '../toolbox_crypto_security.dart';
import '../toolbox_daily_choice_tool.dart';
import '../toolbox_free_chimes_tool.dart';
import '../toolbox_human_tests.dart';
import '../toolbox_mini_games.dart';
import '../toolbox_mind_tools.dart';
import '../toolbox_sleep_assistant_page.dart';
import '../toolbox_singing_bowls_tool.dart';
import '../toolbox_soothing_music_v2_page.dart';
import '../toolbox_life_tools.dart';
import '../toolbox_sound_tools.dart';
import '../toolbox_zen_sand_tool.dart';
import 'toolbox_page_models.dart';

List<ToolboxSectionData> buildToolboxSections(
  AppI18n i18n, {
  required bool Function(String moduleId) isModuleEnabled,
  ToolboxLayoutState layoutState = ToolboxLayoutState.defaults,
}) {
  final sections = buildAllToolboxSections(i18n);
  final visibleEntries = orderedToolboxEntries(
    sections,
    layoutState: layoutState,
    isModuleEnabled: isModuleEnabled,
  );
  return sections
      .map((section) {
        final visibleSectionEntries = visibleEntries
            .where((entry) => section.entries.any((item) => item == entry))
            .toList(growable: false);
        return ToolboxSectionData(
          title: section.title,
          subtitle: section.subtitle,
          entries: visibleSectionEntries,
        );
      })
      .where((section) => section.entries.isNotEmpty)
      .toList(growable: false);
}

List<ToolboxEntryData> orderedToolboxEntries(
  List<ToolboxSectionData> sections, {
  required ToolboxLayoutState layoutState,
  required bool Function(String moduleId) isModuleEnabled,
  bool includeHidden = false,
}) {
  final entries = flattenToolboxEntries(sections)
      .where((entry) => isModuleEnabled(entry.moduleId))
      .where((entry) => includeHidden || !layoutState.isHidden(entry.moduleId))
      .toList(growable: false);
  final order = layoutState
      .normalizedFor(entries.map((entry) => entry.moduleId))
      .order;
  final originalIndexById = <String, int>{
    for (var i = 0; i < entries.length; i += 1) entries[i].moduleId: i,
  };
  final indexById = <String, int>{
    for (var i = 0; i < order.length; i += 1) order[i]: i,
  };
  entries.sort((a, b) {
    return (indexById[a.moduleId] ?? originalIndexById[a.moduleId] ?? 0)
        .compareTo(indexById[b.moduleId] ?? originalIndexById[b.moduleId] ?? 0);
  });
  return entries;
}

List<ToolboxEntryData> quickToolboxEntries(
  List<ToolboxSectionData> sections, {
  required ToolboxLayoutState layoutState,
  required bool Function(String moduleId) isModuleEnabled,
}) {
  final visibleEntries = orderedToolboxEntries(
    sections,
    layoutState: layoutState,
    isModuleEnabled: isModuleEnabled,
  );
  final entryById = <String, ToolboxEntryData>{
    for (final entry in visibleEntries) entry.moduleId: entry,
  };
  return layoutState.quick
      .map((moduleId) => entryById[moduleId])
      .nonNulls
      .toList(growable: false);
}

List<ToolboxEntryData> flattenToolboxEntries(
  List<ToolboxSectionData> sections,
) {
  return <ToolboxEntryData>[for (final section in sections) ...section.entries];
}

List<ToolboxSectionData> buildAllToolboxSections(AppI18n i18n) {
  return <ToolboxSectionData>[
    ToolboxSectionData(
      title: i18n.t('toolbox.hub.section.sleep.title'),
      subtitle: i18n.t('toolbox.hub.section.sleep.subtitle'),
      entries: <ToolboxEntryData>[
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxSleepAssistant,
          title: i18n.t('toolbox.hub.entry.sleep_assistant.title'),
          subtitle: i18n.t('toolbox.hub.entry.sleep_assistant.subtitle'),
          icon: Icons.bedtime_rounded,
          accent: ToolboxColors.sleepAccent,
          pageBuilder: () => const ToolboxSleepAssistantPage(),
        ),
      ],
    ),
    ToolboxSectionData(
      title: i18n.t('toolbox.hub.section.games.title'),
      subtitle: i18n.t('toolbox.hub.section.games.subtitle'),
      entries: <ToolboxEntryData>[
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxMiniGames,
          title: i18n.t('toolbox.hub.entry.games.title'),
          subtitle: i18n.t('toolbox.hub.entry.games.subtitle'),
          icon: Icons.videogame_asset_rounded,
          accent: ToolboxColors.gamesAccent,
          pageBuilder: () => const MiniGamesToolPage(),
        ),
      ],
    ),
    ToolboxSectionData(
      title: i18n.t('toolbox.hub.section.tests.title'),
      subtitle: i18n.t('toolbox.hub.section.tests.subtitle'),
      entries: <ToolboxEntryData>[
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxHumanTests,
          title: i18n.t('toolbox.hub.entry.tests.title'),
          subtitle: i18n.t('toolbox.hub.entry.tests.subtitle'),
          icon: Icons.psychology_alt_rounded,
          accent: const Color(0xFF2F8D8E),
          pageBuilder: () => const HumanTestsToolPage(),
        ),
      ],
    ),
    ToolboxSectionData(
      title: i18n.t('toolbox.hub.section.sound.title'),
      subtitle: i18n.t('toolbox.hub.section.sound.subtitle'),
      entries: <ToolboxEntryData>[
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxSoothingMusic,
          title: i18n.t('toolbox.hub.entry.soothing.title'),
          subtitle: i18n.t('toolbox.hub.entry.soothing.subtitle'),
          icon: Icons.spa_rounded,
          accent: ToolboxColors.soundAccent,
          pageBuilder: () => const SoothingMusicV2Page(),
        ),
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxSoundDeck,
          title: i18n.t('toolbox.hub.entry.harp.title'),
          subtitle: i18n.t('toolbox.hub.entry.harp.subtitle'),
          icon: Icons.music_note_rounded,
          accent: ToolboxColors.harpAccent,
          pageBuilder: () => const HarpToolPage(),
        ),
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxFreeChimes,
          title: i18n.t('toolbox.hub.entry.free_chimes.title'),
          subtitle: i18n.t('toolbox.hub.entry.free_chimes.subtitle'),
          icon: Icons.phonelink_ring_rounded,
          accent: ToolboxColors.soundAccent,
          pageBuilder: () => const ToolboxFreeChimesToolPage(),
        ),
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxSingingBowls,
          title: i18n.t('toolbox.hub.entry.bowls.title'),
          subtitle: i18n.t('toolbox.hub.entry.bowls.subtitle'),
          icon: Icons.blur_circular_rounded,
          accent: ToolboxColors.bowlsAccent,
          pageBuilder: () => const SingingBowlsToolPage(),
        ),
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxFocusBeats,
          title: i18n.t('toolbox.hub.entry.beats.title'),
          subtitle: i18n.t('toolbox.hub.entry.beats.subtitle'),
          icon: Icons.av_timer_rounded,
          accent: ToolboxColors.beatsAccent,
          pageBuilder: () => const FocusBeatsToolPage(),
        ),
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxWoodfish,
          title: i18n.t('toolbox.hub.entry.woodfish.title'),
          subtitle: i18n.t('toolbox.hub.entry.woodfish.subtitle'),
          icon: Icons.self_improvement_rounded,
          accent: ToolboxColors.woodfishAccent,
          pageBuilder: () => const WoodfishToolPage(),
        ),
      ],
    ),
    ToolboxSectionData(
      title: i18n.t('toolbox.hub.section.focus.title'),
      subtitle: i18n.t('toolbox.hub.section.focus.subtitle'),
      entries: <ToolboxEntryData>[
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxSchulteGrid,
          title: i18n.t('toolbox.hub.entry.schulte.title'),
          subtitle: i18n.t('toolbox.hub.entry.schulte.subtitle'),
          icon: Icons.grid_view_rounded,
          accent: ToolboxColors.schulteAccent,
          pageBuilder: () => const SchulteGridToolPage(),
        ),
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxBreathing,
          title: i18n.t('toolbox.hub.entry.breathing.title'),
          subtitle: i18n.t('toolbox.hub.entry.breathing.subtitle'),
          icon: Icons.air_rounded,
          accent: ToolboxColors.breathingAccent,
          pageBuilder: () => const BreathingToolPage(),
        ),
      ],
    ),
    ToolboxSectionData(
      title: i18n.t('toolbox.hub.section.calm.title'),
      subtitle: i18n.t('toolbox.hub.section.calm.subtitle'),
      entries: <ToolboxEntryData>[
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxPrayerBeads,
          title: i18n.t('toolbox.hub.entry.beads.title'),
          subtitle: i18n.t('toolbox.hub.entry.beads.subtitle'),
          icon: Icons.trip_origin_rounded,
          accent: ToolboxColors.prayerAccent,
          pageBuilder: () => const PrayerBeadsToolPage(),
        ),
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxZenSand,
          title: i18n.t('toolbox.hub.entry.zen.title'),
          subtitle: i18n.t('toolbox.hub.entry.zen.subtitle'),
          icon: Icons.landscape_rounded,
          accent: ToolboxColors.zenAccent,
          pageBuilder: () => const ZenSandStudioPage(),
        ),
      ],
    ),
    ToolboxSectionData(
      title: i18n.t('toolbox.hub.section.life.title'),
      subtitle: i18n.t('toolbox.hub.section.life.subtitle'),
      entries: <ToolboxEntryData>[
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxLifeTools,
          title: i18n.t('toolbox.hub.entry.life.title'),
          subtitle: i18n.t('toolbox.hub.entry.life.subtitle'),
          icon: Icons.home_repair_service_rounded,
          accent: ToolboxColors.lifeAccent,
          pageBuilder: () => const LifeToolsHubPage(),
        ),
      ],
    ),
    ToolboxSectionData(
      title: i18n.t('toolbox.hub.section.crypto.title'),
      subtitle: i18n.t('toolbox.hub.section.crypto.subtitle'),
      entries: <ToolboxEntryData>[
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxCryptoSecurity,
          title: i18n.t('toolbox.hub.entry.crypto.title'),
          subtitle: i18n.t('toolbox.hub.entry.crypto.subtitle'),
          icon: Icons.enhanced_encryption_rounded,
          accent: ToolboxColors.cryptoAccent,
          pageBuilder: () => const CryptoSecurityHubPage(),
        ),
      ],
    ),
    ToolboxSectionData(
      title: i18n.t('toolbox.hub.section.decision.title'),
      subtitle: i18n.t('toolbox.hub.section.decision.subtitle'),
      entries: <ToolboxEntryData>[
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxDailyDecision,
          title: i18n.t('toolbox.hub.entry.decision.title'),
          subtitle: i18n.t('toolbox.hub.entry.decision.subtitle'),
          icon: Icons.casino_rounded,
          accent: ToolboxColors.decisionAccent,
          pageBuilder: () => const DailyDecisionToolPage(),
        ),
      ],
    ),
  ];
}

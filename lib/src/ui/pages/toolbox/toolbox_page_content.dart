import 'package:flutter/material.dart';

import '../../../core/module_system/module_id.dart';
import '../../../i18n/app_i18n.dart';
import '../../../models/settings_dto.dart';
import '../../theme/toolbox_colors.dart';
import '../../ui_copy.dart';
import '../toolbox_daily_choice_tool.dart';
import '../toolbox_human_tests.dart';
import '../toolbox_mini_games.dart';
import '../toolbox_mind_tools.dart';
import '../toolbox_sleep_assistant_page.dart';
import '../toolbox_singing_bowls_tool.dart';
import '../toolbox_soothing_music_v2_page.dart';
import '../toolbox_life_tools.dart';
import '../toolbox_sound_locator_tool.dart';
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
      title: pickUiText(i18n, zh: '睡眠支持', en: 'Sleep support'),
      subtitle: pickUiText(
        i18n,
        zh: '记录睡眠、安排睡前准备，也能在夜里醒来时帮你缓一缓。',
        en: 'Track sleep, wind down at night, and get a calmer path when you wake up.',
      ),
      entries: <ToolboxEntryData>[
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxSleepAssistant,
          title: pickUiText(i18n, zh: '睡眠助手', en: 'Sleep assistant'),
          subtitle: pickUiText(
            i18n,
            zh: '睡眠记录、睡前清单、夜醒安抚和每周回顾。',
            en: 'Sleep logs, wind-down steps, night support, and weekly reviews.',
          ),
          icon: Icons.bedtime_rounded,
          accent: ToolboxColors.sleepAccent,
          pageBuilder: () => const ToolboxSleepAssistantPage(),
        ),
      ],
    ),
    ToolboxSectionData(
      title: pickUiText(i18n, zh: '小游戏', en: 'Mini games'),
      subtitle: pickUiText(
        i18n,
        zh: '短时间就能玩一局的益智小游戏。',
        en: 'Small puzzle games for a quick break.',
      ),
      entries: <ToolboxEntryData>[
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxMiniGames,
          title: pickUiText(i18n, zh: '游戏中心', en: 'Game hub'),
          subtitle: pickUiText(
            i18n,
            zh: '俄罗斯方块、推箱子、数独、扫雷、拼图和小转盘都在这里。',
            en: 'Tetris, Sokoban, Sudoku, Minesweeper, jigsaw, and a small roulette game.',
          ),
          icon: Icons.videogame_asset_rounded,
          accent: ToolboxColors.gamesAccent,
          pageBuilder: () => const MiniGamesToolPage(),
        ),
      ],
    ),
    ToolboxSectionData(
      title: pickUiText(i18n, zh: '人类测试', en: 'Human tests'),
      subtitle: pickUiText(
        i18n,
        zh: '测测反应、记忆、视觉搜索和手眼协调。',
        en: 'Try reaction, memory, visual search, and coordination tests.',
      ),
      entries: <ToolboxEntryData>[
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxHumanTests,
          title: pickUiText(i18n, zh: '人类测试中心', en: 'Human test hub'),
          subtitle: pickUiText(
            i18n,
            zh: '反应、记忆、打字、色觉、视力、计算和协调练习。',
            en: 'Reaction, memory, typing, color, vision, math, and coordination drills.',
          ),
          icon: Icons.psychology_alt_rounded,
          accent: const Color(0xFF2F8D8E),
          pageBuilder: () => const HumanTestsToolPage(),
        ),
      ],
    ),
    ToolboxSectionData(
      title: pickUiText(i18n, zh: '声音工具', en: 'Sound tools'),
      subtitle: pickUiText(
        i18n,
        zh: '一些可以放松、打节奏或随手演奏的声音。',
        en: 'Sounds for relaxing, keeping rhythm, or playing for a moment.',
      ),
      entries: <ToolboxEntryData>[
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxSoothingMusic,
          title: pickUiText(i18n, zh: '舒缓音乐', en: 'Soothing music'),
          subtitle: pickUiText(
            i18n,
            zh: '挑一段音乐，让自己慢慢安静下来。',
            en: 'Pick a track and let the room settle.',
          ),
          icon: Icons.spa_rounded,
          accent: ToolboxColors.soundAccent,
          pageBuilder: () => const SoothingMusicV2Page(),
        ),
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxSoundDeck,
          title: pickUiText(i18n, zh: '空灵竖琴', en: 'Ethereal harp'),
          subtitle: pickUiText(
            i18n,
            zh: '竖琴、钢琴、长笛、鼓垫和几种小乐器随手切换。',
            en: 'Switch between harp, piano, flute, drum pad, guitar, and small instruments.',
          ),
          icon: Icons.music_note_rounded,
          accent: ToolboxColors.harpAccent,
          pageBuilder: () => const HarpToolPage(),
        ),
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxSingingBowls,
          title: pickUiText(i18n, zh: '疗愈音钵', en: 'Healing bowls'),
          subtitle: pickUiText(
            i18n,
            zh: '轻敲音钵，听一段慢慢散开的共振。',
            en: 'Tap a bowl and listen to a slow, spacious resonance.',
          ),
          icon: Icons.blur_circular_rounded,
          accent: ToolboxColors.bowlsAccent,
          pageBuilder: () => const SingingBowlsToolPage(),
        ),
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxSoundLocator,
          title: pickUiText(i18n, zh: '声源定位', en: 'Sound locator'),
          subtitle: pickUiText(
            i18n,
            zh: '用麦克风阵列确认声源方向，并在空间舞台中给出指引。',
            en: 'Confirm sound direction with mic arrays and spatial guidance.',
          ),
          icon: Icons.spatial_audio_rounded,
          accent: ToolboxColors.locatorAccent,
          pageBuilder: () => const SoundLocatorToolPage(),
        ),
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxFocusBeats,
          title: pickUiText(i18n, zh: '专注节拍', en: 'Focus beats'),
          subtitle: pickUiText(
            i18n,
            zh: '跟着节拍练专注，也可以自己排一段循环。',
            en: 'Practice with a beat or build a simple loop.',
          ),
          icon: Icons.av_timer_rounded,
          accent: ToolboxColors.beatsAccent,
          pageBuilder: () => const FocusBeatsToolPage(),
        ),
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxWoodfish,
          title: pickUiText(i18n, zh: '电子木鱼', en: 'Digital woodfish'),
          subtitle: pickUiText(
            i18n,
            zh: '轻敲计数，做一个微型重置。',
            en: 'Quick strike and count for a tiny reset.',
          ),
          icon: Icons.self_improvement_rounded,
          accent: ToolboxColors.woodfishAccent,
          pageBuilder: () => const WoodfishToolPage(),
        ),
      ],
    ),
    ToolboxSectionData(
      title: pickUiText(i18n, zh: '专注训练', en: 'Focus drills'),
      subtitle: pickUiText(
        i18n,
        zh: '用数字、呼吸和节奏把注意力拉回来。',
        en: 'Use numbers, breathing, and rhythm to steady attention.',
      ),
      entries: <ToolboxEntryData>[
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxSchulteGrid,
          title: pickUiText(i18n, zh: '舒尔特方格', en: 'Schulte grid'),
          subtitle: pickUiText(
            i18n,
            zh: '按顺序寻找数字，训练视觉搜索。',
            en: 'Find numbers in order to train visual search.',
          ),
          icon: Icons.grid_view_rounded,
          accent: ToolboxColors.schulteAccent,
          pageBuilder: () => const SchulteGridToolPage(),
        ),
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxBreathing,
          title: pickUiText(i18n, zh: '呼吸训练', en: 'Breathing practice'),
          subtitle: pickUiText(
            i18n,
            zh: '专注、放松、睡前和短暂停顿时都能用。',
            en: 'Breathing patterns for focus, relaxing, bedtime, and short pauses.',
          ),
          icon: Icons.air_rounded,
          accent: ToolboxColors.breathingAccent,
          pageBuilder: () => const BreathingToolPage(),
        ),
      ],
    ),
    ToolboxSectionData(
      title: pickUiText(i18n, zh: '静心减压', en: 'Calm tools'),
      subtitle: pickUiText(
        i18n,
        zh: '用触摸、计数和简单画面让自己慢下来。',
        en: 'Slow down with touch, counting, and simple visuals.',
      ),
      entries: <ToolboxEntryData>[
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxPrayerBeads,
          title: pickUiText(i18n, zh: '静心念珠', en: 'Prayer beads'),
          subtitle: pickUiText(
            i18n,
            zh: '按自己的节奏一颗颗拨动。',
            en: 'Advance bead by bead at your own rhythm.',
          ),
          icon: Icons.trip_origin_rounded,
          accent: ToolboxColors.prayerAccent,
          pageBuilder: () => const PrayerBeadsToolPage(),
        ),
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxZenSand,
          title: pickUiText(i18n, zh: '禅意沙盘', en: 'Zen sand tray'),
          subtitle: pickUiText(
            i18n,
            zh: '画出痕迹、摆放石子，做一个迷你沙盘。',
            en: 'Draw in sand, place stones, and make a small quiet scene.',
          ),
          icon: Icons.landscape_rounded,
          accent: ToolboxColors.zenAccent,
          pageBuilder: () => const ZenSandStudioPage(),
        ),
      ],
    ),
    ToolboxSectionData(
      title: pickUiText(i18n, zh: '生活实用', en: 'Life tools'),
      subtitle: pickUiText(
        i18n,
        zh: '时间、弹幕、记分、查询、编码和计算工具集中在一个入口。',
        en: 'Time, barrage, scoreboard, lookup, encoding, and calculators in one place.',
      ),
      entries: <ToolboxEntryData>[
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxLifeTools,
          title: pickUiText(i18n, zh: '生活实用中心', en: 'Life tool hub'),
          subtitle: pickUiText(
            i18n,
            zh: '37 个独立功能入口，覆盖日常高频工具与在线资源助手。',
            en: '37 standalone entries for daily practical tools and online resource helpers.',
          ),
          icon: Icons.home_repair_service_rounded,
          accent: ToolboxColors.lifeAccent,
          pageBuilder: () => const LifeToolsHubPage(),
        ),
      ],
    ),
    ToolboxSectionData(
      title: pickUiText(i18n, zh: '随机决策', en: 'Random choice'),
      subtitle: pickUiText(
        i18n,
        zh: '选择太多时，让转盘帮你先动起来。',
        en: 'When there are too many choices, let the wheel get you moving.',
      ),
      entries: <ToolboxEntryData>[
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxDailyDecision,
          title: pickUiText(i18n, zh: '每日决策', en: 'Daily decision'),
          subtitle: pickUiText(
            i18n,
            zh: '输入选项后转一次，直接给出结果。',
            en: 'Drop in your options and spin once.',
          ),
          icon: Icons.casino_rounded,
          accent: ToolboxColors.decisionAccent,
          pageBuilder: () => const DailyDecisionToolPage(),
        ),
      ],
    ),
  ];
}

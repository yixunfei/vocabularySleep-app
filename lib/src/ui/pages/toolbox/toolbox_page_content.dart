import 'package:flutter/material.dart';

import '../../../core/module_system/module_id.dart';
import '../../../i18n/app_i18n.dart';
import '../../theme/toolbox_colors.dart';
import '../../ui_copy.dart';
import '../toolbox_daily_choice_tool.dart';
import '../toolbox_mini_games.dart';
import '../toolbox_mind_tools.dart';
import '../toolbox_sleep_assistant_page.dart';
import '../toolbox_singing_bowls_tool.dart';
import '../toolbox_soothing_music_v2_page.dart';
import '../toolbox_sound_tools.dart';
import '../toolbox_zen_sand_tool.dart';
import 'toolbox_page_models.dart';

List<ToolboxSectionData> buildToolboxSections(
  AppI18n i18n, {
  required bool Function(String moduleId) isModuleEnabled,
}) {
  final sections = <ToolboxSectionData>[
    ToolboxSectionData(
      title: pickUiText(i18n, zh: '睡眠支持', en: 'Sleep support'),
      subtitle: pickUiText(
        i18n,
        zh: '从评估、记录、减压到夜醒救援的一体化睡眠模块。',
        en: 'An integrated sleep module spanning assessment, logging, wind-down, and rescue.',
      ),
      entries: <ToolboxEntryData>[
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxSleepAssistant,
          title: pickUiText(i18n, zh: '睡眠助手', en: 'Sleep assistant'),
          subtitle: pickUiText(
            i18n,
            zh: '睡眠评估、昨夜记录、睡前流程、夜醒救援与周报。',
            en: 'Assessment, sleep logs, wind-down, night rescue, and reports.',
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
        zh: '轻量益智与拼图。',
        en: 'Lightweight puzzles and small games.',
      ),
      entries: <ToolboxEntryData>[
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxMiniGames,
          title: pickUiText(i18n, zh: '游戏中心', en: 'Game hub'),
          subtitle: pickUiText(
            i18n,
            zh: '包含数独、扫雷和导入图片拼图。',
            en: 'Includes Sudoku, Minesweeper, and imported-image jigsaw.',
          ),
          icon: Icons.videogame_asset_rounded,
          accent: ToolboxColors.gamesAccent,
          pageBuilder: () => const MiniGamesToolPage(),
        ),
      ],
    ),
    ToolboxSectionData(
      title: pickUiText(i18n, zh: '声音工具', en: 'Sound tools'),
      subtitle: pickUiText(
        i18n,
        zh: '本地优先的乐器、节拍与放松声音。',
        en: 'Local-first instruments, beats, and calming sound tools.',
      ),
      entries: <ToolboxEntryData>[
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxSoothingMusic,
          title: pickUiText(i18n, zh: '舒缓音乐', en: 'Soothing music'),
          subtitle: pickUiText(
            i18n,
            zh: '本地曲目配合沉浸式视觉。',
            en: 'Local tracks with immersive visuals.',
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
            zh: '统一入口切换多种乐器。',
            en: 'Unified deck for harp, piano, flute, drum pad, guitar, triangle, violin, and pickup.',
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
            zh: '参考站频率体系、移动端抽屉交互与沉静共振尾韵。',
            en: 'Reference-matched tones, mobile drawer controls, and spacious resonance.',
          ),
          icon: Icons.blur_circular_rounded,
          accent: ToolboxColors.bowlsAccent,
          pageBuilder: () => const SingingBowlsToolPage(),
        ),
        ToolboxEntryData(
          moduleId: ModuleIds.toolboxFocusBeats,
          title: pickUiText(i18n, zh: '专注节拍', en: 'Focus beats'),
          subtitle: pickUiText(
            i18n,
            zh: '沉浸式节拍训练与循环编排。',
            en: 'Immersive rhythm practice with cycle arrangement.',
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
        zh: '稳定你的注意力、节奏与呼吸。',
        en: 'Steady your attention, rhythm, and breathing.',
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
            zh: '做专注、放松、睡前和生理叹息练习。',
            en: 'Scenario-based breathing for focus, relaxation, bedtime, and physiological sigh drills.',
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
        zh: '通过计数、动作和简洁视觉放松。',
        en: 'Unwind through counting, touch, and simple visuals.',
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
            zh: '画耙痕、摆石子，做一个迷你沙盘。',
            en: 'Mobile-friendly sand drawing with synced textures, quick rituals, and calm focus resets.',
          ),
          icon: Icons.landscape_rounded,
          accent: ToolboxColors.zenAccent,
          pageBuilder: () => const ZenSandStudioPage(),
        ),
      ],
    ),
    ToolboxSectionData(
      title: pickUiText(i18n, zh: '随机决策', en: 'Random choice'),
      subtitle: pickUiText(
        i18n,
        zh: '用转盘快速打破犹豫。',
        en: 'Use a wheel to break indecision and keep moving.',
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
  return sections
      .map(
        (section) => ToolboxSectionData(
          title: section.title,
          subtitle: section.subtitle,
          entries: section.entries
              .where((entry) => isModuleEnabled(entry.moduleId))
              .toList(growable: false),
        ),
      )
      .where((section) => section.entries.isNotEmpty)
      .toList(growable: false);
}

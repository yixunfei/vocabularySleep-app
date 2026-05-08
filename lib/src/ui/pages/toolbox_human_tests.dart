import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import '../../i18n/app_i18n.dart';
import '../../services/audio_player_source_helper.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';
import 'toolbox_tool_shell.dart';

part 'toolbox_human_tests_action.dart';
part 'toolbox_human_tests_aim.dart';
part 'toolbox_human_tests_aim_widgets.dart';
part 'toolbox_human_tests_cognition.dart';
part 'toolbox_human_tests_typing.dart';
part 'toolbox_human_tests_typing_copy.dart';
part 'toolbox_human_tests_typing_data.dart';
part 'toolbox_human_tests_typing_widgets.dart';
part 'toolbox_human_tests_dynamic_vision.dart';
part 'toolbox_human_tests_dynamic_vision_parts.dart';
part 'toolbox_human_tests_dynamic_vision_ui.dart';
part 'toolbox_human_tests_visual_search.dart';
part 'toolbox_human_tests_auditory.dart';
part 'toolbox_human_tests_switching.dart';
part 'toolbox_human_tests_drag_tracking.dart';
part 'toolbox_human_tests_bimanual.dart';
part 'toolbox_human_tests_hand_eye.dart';
part 'toolbox_human_tests_hand_eye_joystick.dart';
part 'toolbox_human_tests_hand_eye_parts.dart';
part 'toolbox_human_tests_hand_eye_fullscreen.dart';
part 'toolbox_human_tests_hand_eye_reports.dart';
part 'toolbox_human_tests_hand_eye_settings.dart';
part 'toolbox_human_tests_reaction.dart';
part 'toolbox_human_tests_number_memory_models.dart';
part 'toolbox_human_tests_verbal_memory_data.dart';
part 'toolbox_human_tests_number_memory.dart';
part 'toolbox_human_tests_number_memory_view.dart';
part 'toolbox_human_tests_number_memory_widgets.dart';
part 'toolbox_human_tests_verbal_memory_models.dart';
part 'toolbox_human_tests_verbal_memory.dart';
part 'toolbox_human_tests_verbal_memory_view.dart';
part 'toolbox_human_tests_verbal_memory_widgets.dart';
part 'toolbox_human_tests_memory.dart';
part 'toolbox_human_tests_shared.dart';
part 'toolbox_human_tests_time_perception.dart';
part 'toolbox_human_tests_visual_memory.dart';
part 'toolbox_human_tests_visual_memory_widgets.dart';
part 'toolbox_human_tests_visual.dart';
part 'toolbox_human_tests_visual_widgets.dart';

class HumanTestsToolPage extends StatelessWidget {
  const HumanTestsToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '人类测试', en: 'Human tests'),
      subtitle: pickUiText(
        i18n,
        zh: '参考 Human Benchmark 条目组织的本地趣味测试，覆盖反应、记忆、视觉搜索、听觉、打字、手眼协调、双任务切换、计算和注意力。',
        en: 'A local set of Human Benchmark-inspired tests covering reaction, memory, visual search, sound, typing, coordination, switching, calculation, and attention.',
      ),
      child: const _HumanTestsHub(),
    );
  }
}

const List<DeviceOrientation> _humanTestAllOrientations = <DeviceOrientation>[
  DeviceOrientation.portraitUp,
  DeviceOrientation.portraitDown,
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
];

bool _supportsHumanTestOrientationLock() {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

Future<void> _enterHumanTestLandscapeFullscreen() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  if (_supportsHumanTestOrientationLock()) {
    await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
}

Future<void> _exitHumanTestFullscreen() async {
  if (_supportsHumanTestOrientationLock()) {
    await SystemChrome.setPreferredOrientations(_humanTestAllOrientations);
  }
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

class _HumanTestsHub extends StatelessWidget {
  const _HumanTestsHub();

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final entries = _humanTestEntries(i18n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: pickUiText(i18n, zh: '测试中心', en: 'Test hub'),
          subtitle: pickUiText(
            i18n,
            zh: '选择一个测试开始，结果只在本次页面中展示，不写入用户数据。',
            en: 'Choose a test to begin. Results are shown locally on this page only.',
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            const spacing = 12.0;
            final cardWidth = compact
                ? constraints.maxWidth
                : (constraints.maxWidth - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: entries
                  .map(
                    (entry) => SizedBox(
                      width: cardWidth,
                      child: _HumanTestEntryCard(entry: entry),
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

List<_HumanTestEntry> _humanTestEntries(AppI18n i18n) {
  return <_HumanTestEntry>[
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '反应测试', en: 'Reaction test'),
      subtitle: pickUiText(
        i18n,
        zh: '经典松手、方向滑动与颜色匹配三种反应模式。',
        en: 'Classic release, direction-swipe, and color-match reaction modes.',
      ),
      icon: Icons.flash_on_rounded,
      accent: const Color(0xFF2F8D8E),
      pageBuilder: () => const ReactionTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '数字记忆', en: 'Number memory'),
      subtitle: pickUiText(
        i18n,
        zh: '支持数字串、彩色数字、多数字目标与计算式，毫秒级停留和随机化可调。',
        en: 'Train digit strings, colored digits, multi-number targets, and equations with millisecond timing and randomization.',
      ),
      icon: Icons.pin_rounded,
      accent: const Color(0xFF536CC7),
      pageBuilder: () => const NumberMemoryTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '黑猩猩测试', en: 'Chimp test'),
      subtitle: pickUiText(
        i18n,
        zh: '支持经典、顺序数字与颜色顺序三种模式，并可调切换速度与难度。',
        en: 'Classic, sequential-number, and color-sequence modes with tunable speed/difficulty.',
      ),
      icon: Icons.grid_view_rounded,
      accent: const Color(0xFF6C8D42),
      pageBuilder: () => const ChimpTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '打字测试', en: 'Typing test'),
      subtitle: pickUiText(
        i18n,
        zh: '多语言语料、趣味模式、实时纠错和完成报告，训练速度、准确率与节奏稳定性。',
        en: 'Multi-language passages, playful modes, live correction, and reports for speed, accuracy, and rhythm.',
      ),
      icon: Icons.keyboard_alt_rounded,
      accent: const Color(0xFFC27A37),
      pageBuilder: () => const TypingTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '视觉记忆', en: 'Visual memory'),
      subtitle: pickUiText(
        i18n,
        zh: '支持动态网格、颜色目标、指定颜色与干扰格，难度随等级阶梯提升。',
        en: 'Dynamic grids, color targets, target-color recall, and distractors with stepped difficulty.',
      ),
      icon: Icons.dashboard_customize_rounded,
      accent: const Color(0xFF8B6BC8),
      pageBuilder: () => const VisualMemoryTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '视觉搜索', en: 'Visual search'),
      subtitle: pickUiText(
        i18n,
        zh: '在密集特征网格中快速找目标，并在双面板对照模式中辨别细微差异。',
        en: 'Scan dense grids for the target, then compare paired boards to spot a subtle difference.',
      ),
      icon: Icons.manage_search_rounded,
      accent: const Color(0xFF457B9D),
      pageBuilder: () => const VisualSearchTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '瞄准测试', en: 'Aim test'),
      subtitle: pickUiText(
        i18n,
        zh: '支持经典点靶、降级放大、移动靶和真假干扰，统计命中质量与连击。',
        en: 'Classic, reveal-grow, moving, and decoy target modes with accuracy and streak feedback.',
      ),
      icon: Icons.adjust_rounded,
      accent: const Color(0xFFC24D5A),
      pageBuilder: () => const AimTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '色觉测试', en: 'Color vision'),
      subtitle: pickUiText(
        i18n,
        zh: '找不同、混色匹配、提示记录和可读报告，分析色差、色相与差异类型弱项。',
        en: 'Odd-tile and mixed-match modes with hints and readable reports for hue, delta, and contrast weaknesses.',
      ),
      icon: Icons.palette_rounded,
      accent: const Color(0xFF3F9A6B),
      pageBuilder: () => const ColorVisionTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '听觉反应', en: 'Auditory reaction'),
      subtitle: pickUiText(
        i18n,
        zh: '在随机提示下练习听音反应，并在快速音效识别模式中判断声音类型。',
        en: 'Train reaction time to a cue sound or identify which sound effect was played.',
      ),
      icon: Icons.hearing_rounded,
      accent: const Color(0xFF6E9BC3),
      pageBuilder: () => const AuditoryReactionTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '斯特鲁普', en: 'Stroop test'),
      subtitle: pickUiText(
        i18n,
        zh: '可配置 3-12 种颜色，判断词义与显示颜色是否一致。',
        en: 'Configure 3-12 colors and judge meaning-vs-ink consistency.',
      ),
      icon: Icons.contrast_rounded,
      accent: const Color(0xFF5B82C2),
      pageBuilder: () => const StroopTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '词汇记忆', en: 'Verbal memory'),
      subtitle: pickUiText(
        i18n,
        zh: '支持分领域词库、随机数字串与空间箭头序列，并可自定义展示高度。',
        en: 'Domain word banks, random digit strings, and arrow sequences with custom stage height.',
      ),
      icon: Icons.menu_book_rounded,
      accent: const Color(0xFF8F6C45),
      pageBuilder: () => const VerbalMemoryTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '序列记忆', en: 'Sequence memory'),
      subtitle: pickUiText(
        i18n,
        zh: '记住灯光顺序并原样复现。',
        en: 'Remember the light sequence and repeat it.',
      ),
      icon: Icons.auto_awesome_motion_rounded,
      accent: const Color(0xFF7C6BC8),
      pageBuilder: () => const SequenceMemoryTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '运气测试', en: 'Luck test'),
      subtitle: pickUiText(
        i18n,
        zh: '支持单抽、十连、二十连、概率自定义、目标抽取和幸运指数报告。',
        en: 'Single, 10x, and 20x draws with custom odds, goals, and luck-index reports.',
      ),
      icon: Icons.casino_rounded,
      accent: const Color(0xFFD0923A),
      pageBuilder: () => const LuckTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '手速测试', en: 'Tap speed'),
      subtitle: pickUiText(
        i18n,
        zh: '10 秒内尽可能多次点击按钮。',
        en: 'Tap as many times as possible in 10 seconds.',
      ),
      icon: Icons.touch_app_rounded,
      accent: const Color(0xFFC05180),
      pageBuilder: () => const TapSpeedTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '时间感知测试', en: 'Time perception'),
      subtitle: pickUiText(
        i18n,
        zh: '连续多个时间节点感知：在指定时刻点击对应数字。',
        en: 'Multi-node time perception: tap matching numbers at planned moments.',
      ),
      icon: Icons.timer_rounded,
      accent: const Color(0xFF4D8C9E),
      pageBuilder: () => const TimePerceptionTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '手眼协调测试', en: 'Hand-eye coordination'),
      subtitle: pickUiText(
        i18n,
        zh: '随机目标快速出现、移动并消失，统计成功、漏点、点空和反应延迟。',
        en: 'Fast random targets appear, move, and vanish while tracking hits, misses, blanks, and latency.',
      ),
      icon: Icons.center_focus_strong_rounded,
      accent: const Color(0xFFB55D42),
      pageBuilder: () => const HandEyeCoordinationTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '精细拖拽追踪', en: 'Fine drag tracking'),
      subtitle: pickUiText(
        i18n,
        zh: '沿窄轨迹拖动光标，记录偏离距离、离轨次数和完成时间。',
        en: 'Drag a small cursor along a narrow track while watching deviation, off-track events, and completion time.',
      ),
      icon: Icons.gesture_rounded,
      accent: const Color(0xFF4E8B6B),
      pageBuilder: () => const FineDragTrackingTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '摇杆手眼协调', en: 'Joystick coordination'),
      subtitle: pickUiText(
        i18n,
        zh: '用虚拟摇杆移动准星并点击射击，支持限时和目标总数两种测试。',
        en: 'Move a crosshair with a virtual joystick and fire in timed or target-count modes.',
      ),
      icon: Icons.gamepad_rounded,
      accent: const Color(0xFF8A6849),
      pageBuilder: () => const JoystickHandEyeCoordinationTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '双手协调', en: 'Bimanual coordination'),
      subtitle: pickUiText(
        i18n,
        zh: '在交替或同步节拍中双手协同，练习左右手切换和同次反应。',
        en: 'Practice left-right alternation or synchronized double taps across both hands.',
      ),
      icon: Icons.pan_tool_alt_rounded,
      accent: const Color(0xFFD08A3A),
      pageBuilder: () => const BimanualCoordinationTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '计算能力测试', en: 'Calculation test'),
      subtitle: pickUiText(
        i18n,
        zh: '按难度、题型、题量或限时训练口算，完成后查看速度与准确率分析。',
        en: 'Train arithmetic by difficulty, operation type, fixed rounds, or time limit with speed and accuracy analysis.',
      ),
      icon: Icons.calculate_rounded,
      accent: const Color(0xFF6178B8),
      pageBuilder: () => const CalculationTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '动态视力测试', en: 'Dynamic vision'),
      subtitle: pickUiText(
        i18n,
        zh: '字符识别支持字符集、轨迹、干扰与报告；小球数量随等级提升速度和数量。',
        en: 'Symbol recognition adds sets, paths, distractors, and reports; ball counting raises speed and count by level.',
      ),
      icon: Icons.remove_red_eye_rounded,
      accent: const Color(0xFF407E92),
      pageBuilder: () => const DynamicVisionTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '双任务切换', en: 'Dual-task switching'),
      subtitle: pickUiText(
        i18n,
        zh: '在数字与颜色判断之间来回切换注意力，并统计切换代价。',
        en: 'Switch between two judgment rules and track switch cost, repeat cost, and response speed.',
      ),
      icon: Icons.swap_horiz_rounded,
      accent: const Color(0xFFB05C5C),
      pageBuilder: () => const DualTaskSwitchTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '持续注意力测试', en: 'Sustained attention'),
      subtitle: pickUiText(
        i18n,
        zh: '目标点击、低频目标和 n-back 三类任务，统计命中、漏点、误点与反应时。',
        en: 'Go/no-go, oddball, and n-back tasks with hit, miss, false-alarm, and reaction-time stats.',
      ),
      icon: Icons.track_changes_rounded,
      accent: const Color(0xFF6D8657),
      pageBuilder: () => const SustainedAttentionTestPage(),
    ),
  ];
}

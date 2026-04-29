import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';
import 'toolbox_tool_shell.dart';

part 'toolbox_human_tests_action.dart';
part 'toolbox_human_tests_cognition.dart';
part 'toolbox_human_tests_memory.dart';
part 'toolbox_human_tests_shared.dart';
part 'toolbox_human_tests_visual.dart';

class HumanTestsToolPage extends StatelessWidget {
  const HumanTestsToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '人类测试', en: 'Human tests'),
      subtitle: pickUiText(
        i18n,
        zh: '参考 Human Benchmark 条目组织的本地趣味测试，覆盖反应、记忆、视觉、手眼协调、计算和注意力。',
        en: 'A local set of Human Benchmark-inspired tests covering reaction, memory, vision, coordination, calculation, and attention.',
      ),
      child: const _HumanTestsHub(),
    );
  }
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
        zh: '等待颜色变绿后立刻点击，统计 5 次平均反应。',
        en: 'Wait for green, then tap fast. Averages 5 trials.',
      ),
      icon: Icons.flash_on_rounded,
      accent: const Color(0xFF2F8D8E),
      pageBuilder: () => const ReactionTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '数字记忆', en: 'Number memory'),
      subtitle: pickUiText(
        i18n,
        zh: '记住逐级变长的数字串，再输入复现。',
        en: 'Memorize a growing number string and type it back.',
      ),
      icon: Icons.pin_rounded,
      accent: const Color(0xFF536CC7),
      pageBuilder: () => const NumberMemoryTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '黑猩猩测试', en: 'Chimp test'),
      subtitle: pickUiText(
        i18n,
        zh: '数字消失后，按顺序找回全部位置。',
        en: 'Remember numbered locations after they vanish.',
      ),
      icon: Icons.grid_view_rounded,
      accent: const Color(0xFF6C8D42),
      pageBuilder: () => const ChimpTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '打字测试', en: 'Typing test'),
      subtitle: pickUiText(
        i18n,
        zh: '输入短句，查看速度与准确率。',
        en: 'Type a short passage and check speed and accuracy.',
      ),
      icon: Icons.keyboard_alt_rounded,
      accent: const Color(0xFFC27A37),
      pageBuilder: () => const TypingTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '视觉记忆', en: 'Visual memory'),
      subtitle: pickUiText(
        i18n,
        zh: '记住闪烁格子，再从网格中点回。',
        en: 'Memorize highlighted cells and select them again.',
      ),
      icon: Icons.dashboard_customize_rounded,
      accent: const Color(0xFF8B6BC8),
      pageBuilder: () => const VisualMemoryTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '瞄准测试', en: 'Aim test'),
      subtitle: pickUiText(
        i18n,
        zh: '连续点击目标，统计平均命中间隔。',
        en: 'Tap targets in sequence and measure average time.',
      ),
      icon: Icons.adjust_rounded,
      accent: const Color(0xFFC24D5A),
      pageBuilder: () => const AimTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '色觉测试', en: 'Color vision'),
      subtitle: pickUiText(
        i18n,
        zh: '找出色块阵列里唯一不同的颜色。',
        en: 'Find the one tile with a different color.',
      ),
      icon: Icons.palette_rounded,
      accent: const Color(0xFF3F9A6B),
      pageBuilder: () => const ColorVisionTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '斯特鲁普', en: 'Stroop test'),
      subtitle: pickUiText(
        i18n,
        zh: '判断文字含义和显示颜色是否一致。',
        en: 'Judge whether the word meaning matches its ink color.',
      ),
      icon: Icons.contrast_rounded,
      accent: const Color(0xFF5B82C2),
      pageBuilder: () => const StroopTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '词汇记忆', en: 'Verbal memory'),
      subtitle: pickUiText(
        i18n,
        zh: '判断当前词是否已经出现过。',
        en: 'Decide whether the current word has appeared before.',
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
        zh: '猜左右结果，看看连续命中的手气。',
        en: 'Guess left or right and track your streak.',
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
        zh: '闭眼估算 5 秒，越接近越好。',
        en: 'Estimate 5 seconds without watching a timer.',
      ),
      icon: Icons.timer_rounded,
      accent: const Color(0xFF4D8C9E),
      pageBuilder: () => const TimePerceptionTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '手眼协调测试', en: 'Hand-eye coordination'),
      subtitle: pickUiText(
        i18n,
        zh: '追踪移动目标并尽量准确点击。',
        en: 'Track a moving target and tap accurately.',
      ),
      icon: Icons.center_focus_strong_rounded,
      accent: const Color(0xFFB55D42),
      pageBuilder: () => const HandEyeCoordinationTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '计算能力测试', en: 'Calculation test'),
      subtitle: pickUiText(
        i18n,
        zh: '快速完成四则运算题。',
        en: 'Solve quick arithmetic prompts.',
      ),
      icon: Icons.calculate_rounded,
      accent: const Color(0xFF6178B8),
      pageBuilder: () => const CalculationTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '动态视力测试', en: 'Dynamic vision'),
      subtitle: pickUiText(
        i18n,
        zh: '观察移动字符，结束后选择你看到的内容。',
        en: 'Watch a moving symbol, then choose what you saw.',
      ),
      icon: Icons.remove_red_eye_rounded,
      accent: const Color(0xFF407E92),
      pageBuilder: () => const DynamicVisionTestPage(),
    ),
    _HumanTestEntry(
      title: pickUiText(i18n, zh: '持续注意力测试', en: 'Sustained attention'),
      subtitle: pickUiText(
        i18n,
        zh: '连续观察刺激，只在目标出现时点击。',
        en: 'Watch a stream and tap only when the target appears.',
      ),
      icon: Icons.track_changes_rounded,
      accent: const Color(0xFF6D8657),
      pageBuilder: () => const SustainedAttentionTestPage(),
    ),
  ];
}

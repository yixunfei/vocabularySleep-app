import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../i18n/app_i18n.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';
import 'toolbox_sudoku_card.dart';
import 'toolbox_tool_shell.dart';

part 'toolbox_mini_games_sudoku.dart';
part 'toolbox_mini_games_minesweeper.dart';
part 'toolbox_mini_games_jigsaw.dart';
part 'toolbox_mini_games_gomoku.dart';
part 'toolbox_mini_games_slide.dart';
part 'toolbox_mini_games_roulette.dart';
part 'toolbox_mini_games_tetris.dart';
part 'toolbox_mini_games_sokoban.dart';

class MiniGamesToolPage extends StatelessWidget {
  const MiniGamesToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '小游戏模块', en: 'Mini games'),
      subtitle: pickUiText(
        i18n,
        zh: '在工具箱里集中放置俄罗斯轮盘赌、俄罗斯方块、推箱子、数独、扫雷、电子拼图、五子棋和 2048/4096。',
        en: 'A compact game module with roulette, Tetris, Sokoban, Sudoku, Minesweeper, image jigsaw, Gomoku, and 2048/4096.',
      ),
      child: const _MiniGamesHub(),
    );
  }
}

class RouletteGamePage extends StatelessWidget {
  const RouletteGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '俄罗斯轮盘赌', en: 'Roulette trigger'),
      subtitle: pickUiText(
        i18n,
        zh: '设置子弹数后依次扣动扳机，空膛播放咔哒声，命中时触发闪烁、震动和警示音。',
        en: 'Set the bullet count and pull chamber by chamber. Empty pulls click; hits flash, vibrate, and play an alert.',
      ),
      child: const _RouletteGame(),
    );
  }
}

class TetrisGamePage extends StatelessWidget {
  const TetrisGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '俄罗斯方块', en: 'Tetris'),
      subtitle: pickUiText(
        i18n,
        zh: '经典 10x20 下落方块，支持旋转、软降、硬降、消行得分和暂停。',
        en: 'Classic 10x20 falling blocks with rotate, soft drop, hard drop, line clears, scoring, and pause.',
      ),
      child: const _TetrisGame(),
    );
  }
}

class SokobanGamePage extends StatelessWidget {
  const SokobanGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '推箱子', en: 'Sokoban'),
      subtitle: pickUiText(
        i18n,
        zh: '先生成可解正确路径，再布置障碍；支持提示、撤销和正确线路显示。',
        en: 'Generates a solvable route first, then places walls. Includes hints, undo, and route reveal.',
      ),
      child: const _SokobanGame(),
    );
  }
}

class SudokuGamePage extends StatelessWidget {
  const SudokuGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '数独', en: 'Sudoku'),
      subtitle: pickUiText(
        i18n,
        zh: '9x9 数独，支持冲突高亮、擦除和重开。',
        en: '9x9 Sudoku with conflict highlighting, clear cell, and new game.',
      ),
      child: const SudokuGameCard(),
    );
  }
}

class MinesweeperGamePage extends StatelessWidget {
  const MinesweeperGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '扫雷', en: 'Minesweeper'),
      subtitle: pickUiText(
        i18n,
        zh: '点击翻开、长按插旗，首步保证安全。',
        en: 'Tap to reveal and long-press to flag. The first move is always safe.',
      ),
      child: const _MinesweeperGame(),
    );
  }
}

class JigsawGamePage extends StatelessWidget {
  const JigsawGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '电子拼图', en: 'Image jigsaw'),
      subtitle: pickUiText(
        i18n,
        zh: '导入图片后自动切片，通过交换拼块完成拼图。',
        en: 'Import an image, split it into tiles, and solve by swapping tiles.',
      ),
      child: const _JigsawGame(),
    );
  }
}

class GomokuGamePage extends StatelessWidget {
  const GomokuGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '五子棋', en: 'Gomoku'),
      subtitle: pickUiText(
        i18n,
        zh: '人机对弈五子棋，AI 包含进攻、防守和落点评估逻辑。',
        en: 'Play Gomoku against an AI with attack, defense, and position evaluation.',
      ),
      child: const _GomokuGame(),
    );
  }
}

class SlideNumberGamePage extends StatelessWidget {
  const SlideNumberGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '2048 / 4096', en: '2048 / 4096'),
      subtitle: pickUiText(
        i18n,
        zh: '经典数字合并玩法，支持目标切换到 2048 或 4096。',
        en: 'Classic merge puzzle with switchable targets: 2048 or 4096.',
      ),
      child: const _SlideNumberGame(),
    );
  }
}

class _MiniGamesHub extends StatelessWidget {
  const _MiniGamesHub();

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final entries = <_MiniGameEntry>[
      _MiniGameEntry(
        title: pickUiText(i18n, zh: '俄罗斯轮盘赌', en: 'Roulette trigger'),
        subtitle: pickUiText(
          i18n,
          zh: '设置子弹数，逐次扣动扳机。',
          en: 'Set bullets and pull one chamber at a time.',
        ),
        icon: Icons.casino_rounded,
        accent: const Color(0xFFC2554C),
        pageBuilder: RouletteGamePage.new,
      ),
      _MiniGameEntry(
        title: pickUiText(i18n, zh: '俄罗斯方块', en: 'Tetris'),
        subtitle: pickUiText(
          i18n,
          zh: '下落、旋转、消行和得分。',
          en: 'Drop, rotate, clear lines, and score.',
        ),
        icon: Icons.view_module_rounded,
        accent: const Color(0xFF4B8BC8),
        pageBuilder: TetrisGamePage.new,
      ),
      _MiniGameEntry(
        title: pickUiText(i18n, zh: '推箱子', en: 'Sokoban'),
        subtitle: pickUiText(
          i18n,
          zh: '有解关卡、提示与正确路线。',
          en: 'Solvable levels with hints and route reveal.',
        ),
        icon: Icons.inventory_2_rounded,
        accent: const Color(0xFF8A6CCF),
        pageBuilder: SokobanGamePage.new,
      ),
      _MiniGameEntry(
        title: pickUiText(i18n, zh: '数独', en: 'Sudoku'),
        subtitle: pickUiText(i18n, zh: '9x9 逻辑填数。', en: '9x9 logic puzzle.'),
        icon: Icons.grid_on_rounded,
        accent: const Color(0xFF5C7BE1),
        pageBuilder: SudokuGamePage.new,
      ),
      _MiniGameEntry(
        title: pickUiText(i18n, zh: '扫雷', en: 'Minesweeper'),
        subtitle: pickUiText(
          i18n,
          zh: '翻开格子并插旗排雷。',
          en: 'Reveal safe cells and flag mines.',
        ),
        icon: Icons.flag_rounded,
        accent: const Color(0xFF3EA37D),
        pageBuilder: MinesweeperGamePage.new,
      ),
      _MiniGameEntry(
        title: pickUiText(i18n, zh: '电子拼图', en: 'Image jigsaw'),
        subtitle: pickUiText(
          i18n,
          zh: '导入图片后自动切片拼图。',
          en: 'Import an image and solve by swapping tiles.',
        ),
        icon: Icons.extension_rounded,
        accent: const Color(0xFFD0874A),
        pageBuilder: JigsawGamePage.new,
      ),
      _MiniGameEntry(
        title: pickUiText(i18n, zh: '五子棋', en: 'Gomoku'),
        subtitle: pickUiText(
          i18n,
          zh: '人机对战，AI 自动应对。',
          en: 'Take on the AI and connect five.',
        ),
        icon: Icons.radio_button_checked_rounded,
        accent: const Color(0xFF9A6B3A),
        pageBuilder: GomokuGamePage.new,
      ),
      _MiniGameEntry(
        title: '2048 / 4096',
        subtitle: pickUiText(
          i18n,
          zh: '滑动合并数字。',
          en: 'Slide to merge number tiles.',
        ),
        icon: Icons.view_module_rounded,
        accent: const Color(0xFFB47A45),
        pageBuilder: SlideNumberGamePage.new,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: pickUiText(i18n, zh: '游戏中心', en: 'Game hub'),
          subtitle: pickUiText(
            i18n,
            zh: '从工具箱的小游戏模块中选择一个开始。',
            en: 'Choose a game from the toolbox mini-game module.',
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final spacing = 12.0;
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
                      child: _MiniGameEntryCard(entry: entry),
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

class _MiniGameEntry {
  const _MiniGameEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.pageBuilder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget Function() pageBuilder;
}

class _MiniGameEntryCard extends StatelessWidget {
  const _MiniGameEntryCard({required this.entry});

  final _MiniGameEntry entry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => entry.pageBuilder()));
        },
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: entry.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(entry.icon, color: entry.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _miniGameCompactLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 720;

bool _supportsMiniGameOrientationLock() {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

Future<void> _enterMiniGameFullscreen({bool landscape = false}) async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  if (_supportsMiniGameOrientationLock()) {
    await SystemChrome.setPreferredOrientations(
      landscape
          ? const <DeviceOrientation>[
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const <DeviceOrientation>[
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
    );
  }
}

Future<void> _exitMiniGameFullscreen() async {
  if (_supportsMiniGameOrientationLock()) {
    await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

class _MiniGameScrollLockSurface extends StatefulWidget {
  const _MiniGameScrollLockSurface({required this.child});

  final Widget child;

  @override
  State<_MiniGameScrollLockSurface> createState() =>
      _MiniGameScrollLockSurfaceState();
}

class _MiniGameScrollLockSurfaceState
    extends State<_MiniGameScrollLockSurface> {
  final Map<int, ScrollHoldController> _scrollHolds =
      <int, ScrollHoldController>{};
  ScrollableState? _ancestorScrollable;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ancestorScrollable = Scrollable.maybeOf(context);
  }

  @override
  void dispose() {
    for (final hold in _scrollHolds.values) {
      hold.cancel();
    }
    _scrollHolds.clear();
    super.dispose();
  }

  void _holdScroll(int pointer) {
    final scrollable = _ancestorScrollable;
    if (scrollable == null || _scrollHolds.containsKey(pointer)) {
      return;
    }
    _scrollHolds[pointer] = scrollable.position.hold(() {});
  }

  void _releaseScroll(int pointer) {
    _scrollHolds.remove(pointer)?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) => _holdScroll(event.pointer),
      onPointerUp: (event) => _releaseScroll(event.pointer),
      onPointerCancel: (event) => _releaseScroll(event.pointer),
      child: widget.child,
    );
  }
}

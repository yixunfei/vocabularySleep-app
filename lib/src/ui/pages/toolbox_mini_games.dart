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
import '../../services/app_log_service.dart';
import '../widgets/section_header.dart';
import 'toolbox_sudoku_card.dart';
import 'toolbox_tool_shell.dart';

part 'toolbox_mini_games_sudoku.dart';
part 'toolbox_mini_games_minesweeper.dart';
part 'toolbox_mini_games_jigsaw.dart';
part 'toolbox_mini_games_gomoku.dart';
part 'toolbox_mini_games_slide.dart';
part 'toolbox_mini_games_match3.dart';
part 'toolbox_mini_games_tetris.dart';
part 'toolbox_mini_games_sokoban.dart';

class MiniGamesToolPage extends StatelessWidget {
  const MiniGamesToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: i18n.t('inline.ui.module.module_access.mini_games_e63f5e'),
      subtitle: i18n.t('toolbox.miniGames.hub.subtitle.current'),
      child: const _MiniGamesHub(),
    );
  }
}

class TetrisGamePage extends StatelessWidget {
  const TetrisGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: i18n.t('inline.ui.pages.toolbox_mini_games.tetris_7fab1e'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_mini_games.classic_10x20_falling_blocks_with_rotate_soft_drop_hard_512f74',
      ),
      showPageHeader: false,
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
      title: i18n.t('inline.ui.pages.toolbox_mini_games.sokoban_4ed75c'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_mini_games.generates_a_solvable_route_first_then_places_walls_inclu_706ea2',
      ),
      child: const _SokobanGame(),
    );
  }
}

class MatchThreeGamePage extends StatelessWidget {
  const MatchThreeGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: i18n.t('toolbox.miniGames.match3.title'),
      subtitle: i18n.t('toolbox.miniGames.match3.subtitle'),
      child: const _MatchThreeGame(),
    );
  }
}

class SudokuGamePage extends StatelessWidget {
  const SudokuGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: i18n.t('inline.ui.pages.toolbox_mini_games.sudoku_3498e2'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_mini_games.9x9_sudoku_with_conflict_highlighting_clear_cell_and_new_a6fef9',
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
      title: i18n.t('inline.ui.pages.toolbox_mini_games.minesweeper_1b6ec2'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_mini_games.tap_to_reveal_and_long_press_to_flag_the_first_move_is_a_d896b8',
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
      title: i18n.t('inline.ui.pages.toolbox_mini_games.image_jigsaw_01767e'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_mini_games.import_an_image_split_it_into_tiles_and_solve_by_swappin_11cc58',
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
      title: i18n.t('inline.ui.pages.toolbox_mini_games.gomoku_053d7a'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_mini_games.play_gomoku_against_an_ai_with_attack_defense_and_positi_d3bf47',
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
      title: i18n.t('inline.ui.pages.toolbox_mini_games.text_f00657'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_mini_games.classic_merge_puzzle_with_switchable_targets_2048_or_409_3c2419',
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
        title: i18n.t('inline.ui.pages.toolbox_mini_games.tetris_7fab1e'),
        subtitle: i18n.t(
          'inline.ui.pages.toolbox_mini_games.drop_rotate_clear_lines_and_score_8c5735',
        ),
        icon: Icons.view_module_rounded,
        accent: const Color(0xFF4B8BC8),
        pageBuilder: TetrisGamePage.new,
      ),
      _MiniGameEntry(
        title: i18n.t('toolbox.miniGames.match3.title'),
        subtitle: i18n.t('toolbox.miniGames.match3.entry_subtitle'),
        icon: Icons.auto_awesome_rounded,
        accent: const Color(0xFFD76593),
        pageBuilder: MatchThreeGamePage.new,
      ),
      _MiniGameEntry(
        title: i18n.t('inline.ui.pages.toolbox_mini_games.sokoban_4ed75c'),
        subtitle: i18n.t(
          'inline.ui.pages.toolbox_mini_games.solvable_levels_with_hints_and_route_reveal_d4aa30',
        ),
        icon: Icons.inventory_2_rounded,
        accent: const Color(0xFF8A6CCF),
        pageBuilder: SokobanGamePage.new,
      ),
      _MiniGameEntry(
        title: i18n.t('inline.ui.pages.toolbox_mini_games.sudoku_3498e2'),
        subtitle: i18n.t(
          'inline.ui.pages.toolbox_mini_games.9x9_logic_puzzle_e049f7',
        ),
        icon: Icons.grid_on_rounded,
        accent: const Color(0xFF5C7BE1),
        pageBuilder: SudokuGamePage.new,
      ),
      _MiniGameEntry(
        title: i18n.t('inline.ui.pages.toolbox_mini_games.minesweeper_1b6ec2'),
        subtitle: i18n.t(
          'inline.ui.pages.toolbox_mini_games.reveal_safe_cells_and_flag_mines_e9b976',
        ),
        icon: Icons.flag_rounded,
        accent: const Color(0xFF3EA37D),
        pageBuilder: MinesweeperGamePage.new,
      ),
      _MiniGameEntry(
        title: i18n.t('inline.ui.pages.toolbox_mini_games.image_jigsaw_01767e'),
        subtitle: i18n.t(
          'inline.ui.pages.toolbox_mini_games.import_an_image_and_solve_by_swapping_tiles_0eec72',
        ),
        icon: Icons.extension_rounded,
        accent: const Color(0xFFD0874A),
        pageBuilder: JigsawGamePage.new,
      ),
      _MiniGameEntry(
        title: i18n.t('inline.ui.pages.toolbox_mini_games.gomoku_053d7a'),
        subtitle: i18n.t(
          'inline.ui.pages.toolbox_mini_games.take_on_the_ai_and_connect_five_a207ef',
        ),
        icon: Icons.radio_button_checked_rounded,
        accent: const Color(0xFF9A6B3A),
        pageBuilder: GomokuGamePage.new,
      ),
      _MiniGameEntry(
        title: '2048 / 4096',
        subtitle: i18n.t(
          'inline.ui.pages.toolbox_mini_games.slide_to_merge_number_tiles_18c176',
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
          title: i18n.t('inline.ui.pages.toolbox_mini_games.game_hub_6974bd'),
          subtitle: i18n.t(
            'inline.ui.pages.toolbox_mini_games.choose_a_game_from_the_toolbox_mini_game_module_639ec9',
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

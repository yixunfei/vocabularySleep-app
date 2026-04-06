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

class MiniGamesToolPage extends StatelessWidget {
  const MiniGamesToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '小游戏模块', en: 'Mini games'),
      subtitle: pickUiText(
        i18n,
        zh: '在工具箱里集中放置数独、扫雷、电子拼图、五子棋和 2048/4096。',
        en: 'A compact game module with Sudoku, Minesweeper, image jigsaw, Gomoku, and 2048/4096.',
      ),
      child: const _MiniGamesHub(),
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

class _SudokuGame extends StatefulWidget {
  const _SudokuGame();

  @override
  State<_SudokuGame> createState() => _SudokuGameState();
}

class _SudokuGameState extends State<_SudokuGame> {
  late List<int> _solution;
  late List<int> _board;
  late Set<int> _fixed;
  Set<int> _conflicts = <int>{};
  int? _selected;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    final puzzle = _generateSudokuPuzzle();
    setState(() {
      _solution = puzzle.solution;
      _board = puzzle.puzzle;
      _fixed = <int>{
        for (var i = 0; i < 81; i += 1)
          if (puzzle.puzzle[i] != 0) i,
      };
      _conflicts = _sudokuConflicts(_board);
      _selected = null;
      _solved = false;
    });
  }

  void _write(int value) {
    final selected = _selected;
    if (selected == null || _fixed.contains(selected) || _solved) return;
    setState(() {
      _board[selected] = value;
      _conflicts = _sudokuConflicts(_board);
      _solved =
          _conflicts.isEmpty &&
          List<int>.generate(81, (i) => _board[i]).toString() ==
              List<int>.generate(81, (i) => _solution[i]).toString();
    });
    if (_solved && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sudoku solved!')));
    }
  }

  void _clear() => _write(0);

  @override
  Widget build(BuildContext context) {
    final filled = _board.where((value) => value != 0).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(label: 'Filled', value: '$filled / 81'),
                ToolboxMetricCard(
                  label: 'Conflicts',
                  value: '${_conflicts.length}',
                ),
                ToolboxMetricCard(
                  label: 'Status',
                  value: _solved ? 'Solved' : 'Playing',
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final boardSize = math.min(430.0, constraints.maxWidth);
                return Center(
                  child: SizedBox(
                    width: boardSize,
                    height: boardSize,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 81,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 9,
                          ),
                      itemBuilder: (context, index) {
                        final row = index ~/ 9;
                        final col = index % 9;
                        final value = _board[index];
                        final selected = _selected == index;
                        final fixed = _fixed.contains(index);
                        final conflict = _conflicts.contains(index);
                        final colors = Theme.of(context).colorScheme;
                        final background = selected
                            ? colors.primary.withValues(alpha: 0.18)
                            : conflict
                            ? colors.errorContainer.withValues(alpha: 0.72)
                            : fixed
                            ? colors.secondaryContainer.withValues(alpha: 0.42)
                            : colors.surfaceContainerLowest;
                        return GestureDetector(
                          onTap: () => setState(() => _selected = index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: background,
                              border: Border(
                                top: BorderSide(
                                  width: row % 3 == 0 ? 2 : 0.7,
                                  color: colors.outlineVariant,
                                ),
                                left: BorderSide(
                                  width: col % 3 == 0 ? 2 : 0.7,
                                  color: colors.outlineVariant,
                                ),
                                right: BorderSide(
                                  width: col == 8 ? 2 : 0.7,
                                  color: colors.outlineVariant,
                                ),
                                bottom: BorderSide(
                                  width: row == 8 ? 2 : 0.7,
                                  color: colors.outlineVariant,
                                ),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              value == 0 ? '' : '$value',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: fixed
                                        ? FontWeight.w900
                                        : FontWeight.w700,
                                  ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (var v = 1; v <= 9; v += 1)
                  FilledButton.tonal(
                    onPressed: () => _write(v),
                    child: Text('$v'),
                  ),
                OutlinedButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.backspace_outlined),
                  label: const Text('Clear'),
                ),
                OutlinedButton.icon(
                  onPressed: _newGame,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('New game'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SudokuPuzzle {
  const _SudokuPuzzle({required this.puzzle, required this.solution});

  final List<int> puzzle;
  final List<int> solution;
}

_SudokuPuzzle _generateSudokuPuzzle() {
  final random = math.Random();
  final solution = _generateSudokuSolution(random);
  final puzzle = List<int>.from(solution);
  final removable = List<int>.generate(81, (i) => i)..shuffle(random);
  for (final index in removable.take(48)) {
    puzzle[index] = 0;
  }
  return _SudokuPuzzle(puzzle: puzzle, solution: solution);
}

List<int> _generateSudokuSolution(math.Random random) {
  final nums = List<int>.generate(9, (i) => i + 1)..shuffle(random);
  final rowBands = List<int>.generate(3, (i) => i)..shuffle(random);
  final colBands = List<int>.generate(3, (i) => i)..shuffle(random);
  final rows = <int>[];
  final cols = <int>[];
  for (final band in rowBands) {
    final local = <int>[0, 1, 2]..shuffle(random);
    for (final row in local) {
      rows.add(band * 3 + row);
    }
  }
  for (final band in colBands) {
    final local = <int>[0, 1, 2]..shuffle(random);
    for (final col in local) {
      cols.add(band * 3 + col);
    }
  }
  final board = List<int>.filled(81, 0);
  for (var row = 0; row < 9; row += 1) {
    for (var col = 0; col < 9; col += 1) {
      final pattern = (rows[row] * 3 + rows[row] ~/ 3 + cols[col]) % 9;
      board[row * 9 + col] = nums[pattern];
    }
  }
  return board;
}

Set<int> _sudokuConflicts(List<int> board) {
  final conflicts = <int>{};
  void markGroup(List<int> indices) {
    final seen = <int, int>{};
    for (final index in indices) {
      final value = board[index];
      if (value == 0) continue;
      final previous = seen[value];
      if (previous != null) {
        conflicts.add(previous);
        conflicts.add(index);
      } else {
        seen[value] = index;
      }
    }
  }

  for (var row = 0; row < 9; row += 1) {
    markGroup(List<int>.generate(9, (col) => row * 9 + col));
  }
  for (var col = 0; col < 9; col += 1) {
    markGroup(List<int>.generate(9, (row) => row * 9 + col));
  }
  for (var boxRow = 0; boxRow < 3; boxRow += 1) {
    for (var boxCol = 0; boxCol < 3; boxCol += 1) {
      final cells = <int>[];
      for (var r = 0; r < 3; r += 1) {
        for (var c = 0; c < 3; c += 1) {
          cells.add((boxRow * 3 + r) * 9 + (boxCol * 3 + c));
        }
      }
      markGroup(cells);
    }
  }
  return conflicts;
}

class _MinesweeperGame extends StatefulWidget {
  const _MinesweeperGame();

  @override
  State<_MinesweeperGame> createState() => _MinesweeperGameState();
}

class _MinesweeperGameState extends State<_MinesweeperGame> {
  int _rows = 9;
  int _cols = 9;
  int _mineCount = 10;
  int _draftRows = 9;
  int _draftCols = 9;
  int _draftMines = 10;
  late List<_MineCell> _cells;
  bool _firstMove = true;
  bool _lost = false;
  bool _won = false;
  bool _flagMode = false;
  int _revealedSafe = 0;
  bool _fullscreen = false;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    if (_fullscreen) {
      unawaited(_exitMiniGameFullscreen());
    }
    super.dispose();
  }

  int get _safeCellTotal => _rows * _cols - _mineCount;

  int _indexOf(int row, int col) => row * _cols + col;

  List<int> _neighbors(int index) {
    final row = index ~/ _cols;
    final col = index % _cols;
    final list = <int>[];
    for (var dr = -1; dr <= 1; dr += 1) {
      for (var dc = -1; dc <= 1; dc += 1) {
        if (dr == 0 && dc == 0) continue;
        final nr = row + dr;
        final nc = col + dc;
        if (nr < 0 || nr >= _rows || nc < 0 || nc >= _cols) continue;
        list.add(_indexOf(nr, nc));
      }
    }
    return list;
  }

  void _syncDraftMineCap() {
    final maxMine = math.max(1, _draftRows * _draftCols - 1);
    if (_draftMines > maxMine) {
      _draftMines = maxMine;
    }
  }

  void _applyPreset(_MinesweeperPreset preset) {
    setState(() {
      _draftRows = preset.rows;
      _draftCols = preset.cols;
      _draftMines = preset.mines;
      _syncDraftMineCap();
      _rows = _draftRows;
      _cols = _draftCols;
      _mineCount = _draftMines;
      _flagMode = false;
      _startNewGame();
    });
  }

  void _applyCustom() {
    setState(() {
      _syncDraftMineCap();
      _rows = _draftRows;
      _cols = _draftCols;
      _mineCount = _draftMines;
      _flagMode = false;
      _startNewGame();
    });
  }

  void _startNewGame({int? safeIndex}) {
    final random = math.Random();
    _cells = List<_MineCell>.generate(_rows * _cols, (_) => _MineCell());
    var placed = 0;
    while (placed < _mineCount) {
      final index = random.nextInt(_cells.length);
      if (index == safeIndex || _cells[index].hasMine) continue;
      _cells[index].hasMine = true;
      placed += 1;
    }
    for (var i = 0; i < _cells.length; i += 1) {
      if (_cells[i].hasMine) continue;
      _cells[i].neighborMines = _neighbors(
        i,
      ).where((n) => _cells[n].hasMine).length;
    }
    _firstMove = true;
    _lost = false;
    _won = false;
    _revealedSafe = 0;
  }

  Future<void> _setFullscreen(bool value) async {
    if (_fullscreen == value) {
      return;
    }
    setState(() {
      _fullscreen = value;
    });
    if (value) {
      await _enterMiniGameFullscreen();
    } else {
      await _exitMiniGameFullscreen();
    }
  }

  String _text(AppI18n i18n, {required String zh, required String en}) {
    return pickUiText(i18n, zh: zh, en: en);
  }

  String _presetLabel(AppI18n i18n, _MinesweeperPreset preset) {
    if (preset.label == 'Easy') {
      return _text(i18n, zh: '简单', en: 'Easy');
    }
    if (preset.label == 'Medium') {
      return _text(i18n, zh: '标准', en: 'Medium');
    }
    return _text(i18n, zh: '挑战', en: 'Hard');
  }

  String _statusLabel(AppI18n i18n) {
    if (_lost) {
      return _text(i18n, zh: '爆炸', en: 'Boom');
    }
    if (_won) {
      return _text(i18n, zh: '已通关', en: 'Cleared');
    }
    return _text(i18n, zh: '进行中', en: 'Playing');
  }

  void _revealHint() {
    if (_lost || _won) {
      return;
    }
    final hiddenSafe = <int>[
      for (var index = 0; index < _cells.length; index += 1)
        if (!_cells[index].revealed &&
            _cells[index].mark != _MineMark.flag &&
            !_cells[index].hasMine)
          index,
    ];
    if (hiddenSafe.isEmpty) {
      return;
    }
    final target = hiddenSafe[math.Random().nextInt(hiddenSafe.length)];
    _reveal(target);
    if (!mounted || _won) {
      return;
    }
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final row = target ~/ _cols + 1;
    final col = target % _cols + 1;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _text(
            i18n,
            zh: '提示已翻开第 $row 行第 $col 列的安全格。',
            en: 'Hint revealed a safe cell at row $row, column $col.',
          ),
        ),
      ),
    );
  }

  Widget _buildBoard(BuildContext context, {required bool fullscreen}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final viewportHeight = constraints.maxHeight;
        final targetCell = _miniGameCompactLayout(context) ? 22.0 : 26.0;
        final boardWidth = fullscreen
            ? _cols *
                  (math.min(viewportWidth / _cols, viewportHeight / _rows) *
                          0.96)
                      .clamp(8.0, 36.0)
            : math.max(viewportWidth, _cols * targetCell);
        final boardHeight = fullscreen
            ? _rows * (boardWidth / _cols)
            : boardWidth * _rows / _cols;
        final cellExtent = boardWidth / _cols;
        return _MiniGameScrollLockSurface(
          child: InteractiveViewer(
            minScale: 0.65,
            maxScale: 4.0,
            boundaryMargin: const EdgeInsets.all(24),
            child: Center(
              child: SizedBox(
                width: boardWidth,
                height: boardHeight,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _cells.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _cols,
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _onCellTap(index),
                      onLongPress: () => _cycleMark(index),
                      child: _MineCellTile(
                        cell: _cells[index],
                        extent: cellExtent,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _cycleMark(int index) {
    if (_lost || _won) return;
    final cell = _cells[index];
    if (cell.revealed) return;
    setState(() {
      cell.mark = switch (cell.mark) {
        _MineMark.none => _MineMark.flag,
        _MineMark.flag => _MineMark.question,
        _MineMark.question => _MineMark.none,
      };
    });
  }

  void _reveal(int index) {
    if (_lost || _won) return;
    final cell = _cells[index];
    if (cell.revealed || cell.mark == _MineMark.flag) return;
    if (cell.mark == _MineMark.question) {
      cell.mark = _MineMark.none;
    }

    setState(() {
      if (_firstMove) {
        _firstMove = false;
        if (_cells[index].hasMine) {
          _startNewGame(safeIndex: index);
          _firstMove = false;
        }
      }

      if (_cells[index].hasMine) {
        _lost = true;
        for (final c in _cells) {
          if (c.hasMine) {
            c.revealed = true;
          }
          if (!c.hasMine && c.mark == _MineMark.flag) {
            c.revealed = true;
            c.wrongFlag = true;
          }
        }
        _cells[index].exploded = true;
        return;
      }

      _floodReveal(index);
      if (_revealedSafe >= _safeCellTotal) {
        _won = true;
        for (final c in _cells) {
          if (c.hasMine) c.mark = _MineMark.flag;
        }
      }
    });

    if (_won && context.mounted) {
      final i18n = AppI18n(Localizations.localeOf(context).languageCode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(i18n, zh: '扫雷通关，已自动插旗。', en: 'Minesweeper cleared!'),
          ),
        ),
      );
    }
  }

  void _floodReveal(int start) {
    final queue = Queue<int>()..add(start);
    while (queue.isNotEmpty) {
      final index = queue.removeFirst();
      final cell = _cells[index];
      if (cell.revealed || cell.mark != _MineMark.none) continue;
      cell.revealed = true;
      if (!cell.hasMine) _revealedSafe += 1;
      if (cell.neighborMines > 0) continue;
      for (final neighbor in _neighbors(index)) {
        final next = _cells[neighbor];
        if (!next.revealed && next.mark == _MineMark.none && !next.hasMine) {
          queue.add(neighbor);
        }
      }
    }
  }

  void _onCellTap(int index) {
    if (_flagMode) {
      _cycleMark(index);
      return;
    }
    _reveal(index);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final flags = _cells.where((c) => c.mark == _MineMark.flag).length;
    final questions = _cells.where((c) => c.mark == _MineMark.question).length;
    const presets = <_MinesweeperPreset>[
      _MinesweeperPreset(label: 'Easy', rows: 9, cols: 9, mines: 10),
      _MinesweeperPreset(label: 'Medium', rows: 16, cols: 16, mines: 40),
      _MinesweeperPreset(label: 'Hard', rows: 24, cols: 24, mines: 99),
    ];
    if (_fullscreen) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton.tonalIcon(
                      onPressed: () => _setFullscreen(false),
                      icon: const Icon(Icons.fullscreen_exit_rounded),
                      label: Text(
                        _text(i18n, zh: '退出全屏', en: 'Exit fullscreen'),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _lost || _won ? null : _revealHint,
                      icon: const Icon(Icons.lightbulb_outline_rounded),
                      label: Text(_text(i18n, zh: '提示', en: 'Hint')),
                    ),
                    FilterChip(
                      label: Text(_text(i18n, zh: '插旗模式', en: 'Flag mode')),
                      selected: _flagMode,
                      onSelected: (value) {
                        setState(() {
                          _flagMode = value;
                        });
                      },
                    ),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _startNewGame()),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(_text(i18n, zh: '新开一局', en: 'New game')),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    ToolboxMetricCard(
                      label: _text(i18n, zh: '棋盘', en: 'Board'),
                      value: '${_rows}x$_cols',
                    ),
                    ToolboxMetricCard(
                      label: _text(i18n, zh: '地雷', en: 'Mines'),
                      value: '$_mineCount',
                    ),
                    ToolboxMetricCard(
                      label: _text(i18n, zh: '剩余地雷', en: 'Mines left'),
                      value: '${math.max(0, _mineCount - flags)}',
                    ),
                    ToolboxMetricCard(
                      label: _text(i18n, zh: '状态', en: 'Status'),
                      value: _statusLabel(i18n),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildBoard(context, fullscreen: true)),
              ],
            ),
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(
                        '${_presetLabel(i18n, preset)} ${preset.rows}x${preset.cols}/${preset.mines}',
                      ),
                      selected:
                          _rows == preset.rows &&
                          _cols == preset.cols &&
                          _mineCount == preset.mines,
                      onSelected: (_) => _applyPreset(preset),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _text(i18n, zh: '自定义设置', en: 'Custom setup'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${_text(i18n, zh: '行数', en: 'Rows')}: $_draftRows'),
                    Slider(
                      value: _draftRows.toDouble(),
                      min: 5,
                      max: 30,
                      divisions: 25,
                      label: '$_draftRows',
                      onChanged: (value) {
                        setState(() {
                          _draftRows = value.round();
                          _syncDraftMineCap();
                        });
                      },
                    ),
                    Text(
                      '${_text(i18n, zh: '列数', en: 'Columns')}: $_draftCols',
                    ),
                    Slider(
                      value: _draftCols.toDouble(),
                      min: 5,
                      max: 30,
                      divisions: 25,
                      label: '$_draftCols',
                      onChanged: (value) {
                        setState(() {
                          _draftCols = value.round();
                          _syncDraftMineCap();
                        });
                      },
                    ),
                    Text(
                      '${_text(i18n, zh: '地雷数', en: 'Mines')}: $_draftMines',
                    ),
                    Slider(
                      value: _draftMines.toDouble(),
                      min: 1,
                      max: math.max(1, _draftRows * _draftCols - 1).toDouble(),
                      divisions: math.max(1, _draftRows * _draftCols - 2),
                      label: '$_draftMines',
                      onChanged: (value) {
                        setState(() {
                          _draftMines = value.round();
                          _syncDraftMineCap();
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: _applyCustom,
                          icon: const Icon(Icons.build_rounded),
                          label: Text(
                            _text(i18n, zh: '应用自定义', en: 'Apply custom'),
                          ),
                        ),
                        FilterChip(
                          label: Text(_text(i18n, zh: '插旗模式', en: 'Flag mode')),
                          selected: _flagMode,
                          onSelected: (value) {
                            setState(() {
                              _flagMode = value;
                            });
                          },
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _lost || _won ? null : _revealHint,
                          icon: const Icon(Icons.lightbulb_outline_rounded),
                          label: Text(_text(i18n, zh: '提示', en: 'Hint')),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _setFullscreen(true),
                          icon: const Icon(Icons.fullscreen_rounded),
                          label: Text(
                            _text(i18n, zh: '全屏棋盘', en: 'Fullscreen board'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(
                  label: _text(i18n, zh: '棋盘', en: 'Board'),
                  value: '${_rows}x$_cols',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '地雷', en: 'Mines'),
                  value: '$_mineCount',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '剩余地雷', en: 'Mines left'),
                  value: '${math.max(0, _mineCount - flags)}',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '旗子', en: 'Flags'),
                  value: '$flags',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '问号', en: 'Question'),
                  value: '$questions',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '进度', en: 'Progress'),
                  value: '$_revealedSafe / $_safeCellTotal',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '状态', en: 'Status'),
                  value: _statusLabel(i18n),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _flagMode
                  ? _text(
                      i18n,
                      zh: '插旗模式已开启：点击会在旗子、问号和空白之间切换。',
                      en: 'Flag mode is on: taps cycle through flag, question, and none.',
                    )
                  : _text(
                      i18n,
                      zh: '轻触翻开，长按可循环标记旗子和问号。',
                      en: 'Tap to reveal, long press to cycle marks.',
                    ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: _miniGameCompactLayout(context) ? 320 : 420,
              child: _buildBoard(context, fullscreen: false),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() => _startNewGame()),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_text(i18n, zh: '新开一局', en: 'New game')),
            ),
          ],
        ),
      ),
    );
  }
}

class _MineCell {
  bool hasMine = false;
  bool revealed = false;
  _MineMark mark = _MineMark.none;
  bool exploded = false;
  bool wrongFlag = false;
  int neighborMines = 0;
}

enum _MineMark { none, flag, question }

class _MinesweeperPreset {
  const _MinesweeperPreset({
    required this.label,
    required this.rows,
    required this.cols,
    required this.mines,
  });

  final String label;
  final int rows;
  final int cols;
  final int mines;
}

class _MineCellTile extends StatelessWidget {
  const _MineCellTile({required this.cell, required this.extent});

  final _MineCell cell;
  final double extent;

  static const Map<int, Color> _numbers = <int, Color>{
    1: Color(0xFF2E6CE6),
    2: Color(0xFF2EA369),
    3: Color(0xFFC94640),
    4: Color(0xFF7B3DE0),
    5: Color(0xFFAB5C1D),
    6: Color(0xFF1F9FB8),
    7: Color(0xFF5E5E5E),
    8: Color(0xFF1D1D1D),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconSize = (extent * 0.62).clamp(7.0, 18.0);
    final fontSize = (extent * 0.56).clamp(6.0, 18.0);
    Widget child;
    if (cell.wrongFlag) {
      child = Icon(
        Icons.close_rounded,
        color: const Color(0xFFD32F2F),
        size: iconSize,
      );
    } else if (cell.revealed && cell.hasMine) {
      child = Icon(
        cell.exploded ? Icons.close_rounded : Icons.circle,
        color: cell.exploded ? const Color(0xFFD32F2F) : scheme.error,
        size: iconSize,
      );
    } else if (!cell.revealed && cell.mark == _MineMark.flag) {
      child = Icon(
        Icons.flag_rounded,
        color: const Color(0xFFC14E2D),
        size: iconSize,
      );
    } else if (!cell.revealed && cell.mark == _MineMark.question) {
      child = FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: fontSize,
          ),
        ),
      );
    } else if (cell.revealed && cell.neighborMines > 0) {
      child = FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '${cell.neighborMines}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: fontSize,
            color: _numbers[cell.neighborMines],
          ),
        ),
      );
    } else {
      child = const SizedBox.shrink();
    }
    return Container(
      margin: EdgeInsets.all(extent <= 16 ? 0.18 : 0.5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: (cell.revealed || cell.wrongFlag)
            ? scheme.surfaceContainerLow
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(extent <= 16 ? 2 : 4),
        border: Border.all(
          color: scheme.outlineVariant,
          width: extent <= 16 ? 0.45 : 0.9,
        ),
      ),
      child: child,
    );
  }
}

class _JigsawGame extends StatefulWidget {
  const _JigsawGame();

  @override
  State<_JigsawGame> createState() => _JigsawGameState();
}

class _JigsawGameState extends State<_JigsawGame> {
  ui.Image? _sourceImage;
  Uint8List? _sourceBytes;
  int _rows = 3;
  int _cols = 3;
  List<int> _tiles = const <int>[];
  int? _selectedTile;
  int? _hintTargetIndex;
  Timer? _hintTimer;
  Timer? _ticker;
  final Stopwatch _stopwatch = Stopwatch();
  Duration _elapsed = Duration.zero;
  int _moves = 0;
  bool _loading = false;
  bool _solved = false;
  bool _resultShown = false;
  bool _fullscreen = false;
  String? _error;

  @override
  void dispose() {
    _ticker?.cancel();
    _hintTimer?.cancel();
    _stopwatch.stop();
    _sourceImage?.dispose();
    if (_fullscreen) {
      unawaited(_exitMiniGameFullscreen());
    }
    super.dispose();
  }

  String _text(AppI18n i18n, {required String zh, required String en}) {
    return pickUiText(i18n, zh: zh, en: en);
  }

  Future<void> _setFullscreen(bool value) async {
    if (_fullscreen == value) {
      return;
    }
    setState(() {
      _fullscreen = value;
    });
    if (value) {
      await _enterMiniGameFullscreen();
    } else {
      await _exitMiniGameFullscreen();
    }
  }

  String _statusLabel(AppI18n i18n) {
    return _solved
        ? _text(i18n, zh: '已完成', en: 'Solved')
        : _text(i18n, zh: '进行中', en: 'Playing');
  }

  Future<void> _importImage() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }
      final bytes = result.files.single.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = _text(
            AppI18n(Localizations.localeOf(context).languageCode),
            zh: '读取图片数据失败。',
            en: 'Failed to read image bytes.',
          );
        });
        return;
      }
      final image = await _decodeImage(bytes);
      if (!mounted) {
        image.dispose();
        return;
      }
      final old = _sourceImage;
      setState(() {
        _sourceImage = image;
        _sourceBytes = bytes;
        _tiles = _shuffleTiles(_rows, _cols);
        _selectedTile = null;
        _hintTargetIndex = null;
        _moves = 0;
        _solved = false;
        _resultShown = false;
        _loading = false;
        _elapsed = Duration.zero;
      });
      _startTimer();
      old?.dispose();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _text(
          AppI18n(Localizations.localeOf(context).languageCode),
          zh: '导入图片失败。',
          en: 'Failed to import image.',
        );
      });
    }
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _startTimer() {
    _ticker?.cancel();
    _stopwatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _solved || _sourceImage == null) return;
      setState(() {
        _elapsed = _stopwatch.elapsed;
      });
    });
  }

  void _stopTimer() {
    _stopwatch.stop();
    _ticker?.cancel();
    _ticker = null;
    _elapsed = _stopwatch.elapsed;
  }

  String _formatDuration(Duration value) {
    final totalSeconds = value.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  List<int> _shuffleTiles(int rows, int cols) {
    final total = rows * cols;
    final list = List<int>.generate(total, (i) => i);
    if (total <= 1) return list;
    final random = math.Random();
    do {
      list.shuffle(random);
    } while (_isSolved(list));
    return list;
  }

  bool _isSolved(List<int> board) {
    for (var i = 0; i < board.length; i += 1) {
      if (board[i] != i) return false;
    }
    return true;
  }

  void _changeRows(int value) {
    setState(() {
      _rows = value.clamp(2, 50);
      _selectedTile = null;
      _hintTargetIndex = null;
      _resultShown = false;
      _moves = 0;
      _solved = false;
      _tiles = _sourceImage == null
          ? const <int>[]
          : _shuffleTiles(_rows, _cols);
      _elapsed = Duration.zero;
    });
    if (_sourceImage != null) {
      _startTimer();
    }
  }

  void _changeCols(int value) {
    setState(() {
      _cols = value.clamp(2, 50);
      _selectedTile = null;
      _hintTargetIndex = null;
      _resultShown = false;
      _moves = 0;
      _solved = false;
      _tiles = _sourceImage == null
          ? const <int>[]
          : _shuffleTiles(_rows, _cols);
      _elapsed = Duration.zero;
    });
    if (_sourceImage != null) {
      _startTimer();
    }
  }

  void _setPresetGrid(int rows, int cols) {
    setState(() {
      _rows = rows;
      _cols = cols;
      _selectedTile = null;
      _hintTargetIndex = null;
      _resultShown = false;
      _moves = 0;
      _solved = false;
      _tiles = _sourceImage == null
          ? const <int>[]
          : _shuffleTiles(_rows, _cols);
      _elapsed = Duration.zero;
    });
    if (_sourceImage != null) {
      _startTimer();
    }
  }

  void _shuffle() {
    if (_sourceImage == null) return;
    setState(() {
      _tiles = _shuffleTiles(_rows, _cols);
      _selectedTile = null;
      _hintTargetIndex = null;
      _resultShown = false;
      _moves = 0;
      _solved = false;
      _elapsed = Duration.zero;
    });
    _startTimer();
  }

  void _showHint() {
    if (_sourceImage == null || _solved || _tiles.isEmpty) return;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final mismatch = <int>[
      for (var index = 0; index < _tiles.length; index += 1)
        if (_tiles[index] != index) index,
    ];
    if (mismatch.isEmpty) return;
    final targetCell = mismatch.first;
    final pieceValue = _tiles[targetCell];
    final correctIndex = pieceValue;
    final correctRow = correctIndex ~/ _cols + 1;
    final correctCol = correctIndex % _cols + 1;
    setState(() {
      _hintTargetIndex = correctIndex;
    });
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _hintTargetIndex = null;
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _text(
            i18n,
            zh: '提示：该拼块应该移动到第 $correctRow 行第 $correctCol 列。',
            en: 'Hint: this piece should go to row $correctRow, column $correctCol.',
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showSolvedDialog() async {
    if (!mounted || _resultShown) return;
    _resultShown = true;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_text(i18n, zh: '恭喜完成', en: 'Congratulations')),
          content: Text(
            _text(
              i18n,
              zh: '拼图已完成。\n网格：${_rows}x$_cols\n步数：$_moves\n用时：${_formatDuration(_elapsed)}',
              en: 'Puzzle solved.\nGrid: ${_rows}x$_cols\nMoves: $_moves\nTime: ${_formatDuration(_elapsed)}',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_text(i18n, zh: '关闭', en: 'Close')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _shuffle();
              },
              child: Text(_text(i18n, zh: '再来一局', en: 'Play again')),
            ),
          ],
        );
      },
    );
  }

  void _tapTile(int boardIndex) {
    if (_sourceImage == null || _solved) return;
    final selected = _selectedTile;
    if (selected == null) {
      setState(() => _selectedTile = boardIndex);
      return;
    }
    if (selected == boardIndex) {
      setState(() => _selectedTile = null);
      return;
    }
    setState(() {
      final next = List<int>.from(_tiles);
      final tmp = next[selected];
      next[selected] = next[boardIndex];
      next[boardIndex] = tmp;
      _tiles = next;
      _selectedTile = null;
      _hintTargetIndex = null;
      _moves += 1;
      _solved = _isSolved(next);
    });
    if (_solved && context.mounted) {
      _stopTimer();
      unawaited(_showSolvedDialog());
    }
  }

  Widget _buildPuzzleBoard(BuildContext context, {required bool fullscreen}) {
    final image = _sourceImage!;
    final tileCount = _tiles.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final viewportHeight = constraints.maxHeight;
        final targetTile = _miniGameCompactLayout(context) ? 54.0 : 64.0;
        final boardWidth = fullscreen
            ? _cols *
                  (math.min(viewportWidth / _cols, viewportHeight / _rows) *
                          0.96)
                      .clamp(24.0, 96.0)
            : math.max(viewportWidth, _cols * targetTile);
        final boardHeight = fullscreen
            ? _rows * (boardWidth / _cols)
            : boardWidth * _rows / _cols;
        return _MiniGameScrollLockSurface(
          child: InteractiveViewer(
            minScale: 0.6,
            maxScale: 4,
            boundaryMargin: const EdgeInsets.all(24),
            child: Center(
              child: SizedBox(
                width: boardWidth,
                height: boardHeight,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tileCount,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _cols,
                  ),
                  itemBuilder: (context, index) {
                    final selected = _selectedTile == index;
                    final hinted = _hintTargetIndex == index;
                    return GestureDetector(
                      onTap: () => _tapTile(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        margin: EdgeInsets.all(
                          boardWidth / _cols <= 56 ? 1 : 2,
                        ),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            fullscreen ? 8 : 6,
                          ),
                          border: Border.all(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : hinted
                                ? Colors.amber.shade700
                                : Theme.of(context).colorScheme.outlineVariant,
                            width: selected || hinted ? 2 : 1,
                          ),
                        ),
                        child: CustomPaint(
                          painter: _PuzzleTilePainter(
                            image: image,
                            sourceTileIndex: _tiles[index],
                            rowCount: _rows,
                            colCount: _cols,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    if (_fullscreen) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton.tonalIcon(
                      onPressed: () => _setFullscreen(false),
                      icon: const Icon(Icons.fullscreen_exit_rounded),
                      label: Text(
                        _text(i18n, zh: '退出全屏', en: 'Exit fullscreen'),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _sourceImage == null || _loading
                          ? null
                          : _showHint,
                      icon: const Icon(Icons.lightbulb_outline_rounded),
                      label: Text(_text(i18n, zh: '提示', en: 'Hint')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _sourceImage == null || _loading
                          ? null
                          : _shuffle,
                      icon: const Icon(Icons.shuffle_rounded),
                      label: Text(_text(i18n, zh: '打乱重排', en: 'Shuffle')),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    ToolboxMetricCard(
                      label: _text(i18n, zh: '网格', en: 'Grid'),
                      value: '${_rows}x$_cols',
                    ),
                    ToolboxMetricCard(
                      label: _text(i18n, zh: '步数', en: 'Moves'),
                      value: '$_moves',
                    ),
                    ToolboxMetricCard(
                      label: _text(i18n, zh: '用时', en: 'Time'),
                      value: _formatDuration(_elapsed),
                    ),
                    ToolboxMetricCard(
                      label: _text(i18n, zh: '状态', en: 'Status'),
                      value: _statusLabel(i18n),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _sourceImage == null
                      ? Center(
                          child: Text(
                            _text(
                              i18n,
                              zh: '先导入一张图片再进入全屏拼图。',
                              en: 'Import an image first to use fullscreen puzzle mode.',
                            ),
                          ),
                        )
                      : _buildPuzzleBoard(context, fullscreen: true),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _loading ? null : _importImage,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    _loading
                        ? _text(i18n, zh: '导入中...', en: 'Importing...')
                        : _text(i18n, zh: '导入图片', en: 'Import image'),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _sourceImage == null || _loading
                      ? null
                      : _showHint,
                  icon: const Icon(Icons.lightbulb_outline_rounded),
                  label: Text(_text(i18n, zh: '提示', en: 'Hint')),
                ),
                OutlinedButton.icon(
                  onPressed: _sourceImage == null || _loading ? null : _shuffle,
                  icon: const Icon(Icons.shuffle_rounded),
                  label: Text(_text(i18n, zh: '打乱重排', en: 'Shuffle')),
                ),
                OutlinedButton.icon(
                  onPressed: _sourceImage == null || _loading
                      ? null
                      : () => _setFullscreen(true),
                  icon: const Icon(Icons.fullscreen_rounded),
                  label: Text(_text(i18n, zh: '全屏拼图', en: 'Fullscreen')),
                ),
                for (final preset in const <(int, int)>[
                  (3, 3),
                  (4, 4),
                  (5, 5),
                  (8, 8),
                  (10, 10),
                ])
                  ChoiceChip(
                    label: Text('${preset.$1}x${preset.$2}'),
                    selected: _rows == preset.$1 && _cols == preset.$2,
                    onSelected: (_) => _setPresetGrid(preset.$1, preset.$2),
                  ),
              ],
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(
                  label: _text(i18n, zh: '网格', en: 'Grid'),
                  value: '${_rows}x$_cols',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '步数', en: 'Moves'),
                  value: '$_moves',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '用时', en: 'Time'),
                  value: _formatDuration(_elapsed),
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '状态', en: 'Status'),
                  value: _statusLabel(i18n),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('${_text(i18n, zh: '行数', en: 'Rows')}: $_rows'),
                    Slider(
                      value: _rows.toDouble(),
                      min: 2,
                      max: 50,
                      divisions: 48,
                      label: '$_rows',
                      onChanged: (value) => _changeRows(value.round()),
                    ),
                    Text('${_text(i18n, zh: '列数', en: 'Columns')}: $_cols'),
                    Slider(
                      value: _cols.toDouble(),
                      min: 2,
                      max: 50,
                      divisions: 48,
                      label: '$_cols',
                      onChanged: (value) => _changeCols(value.round()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_sourceImage == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Text(
                  _text(
                    i18n,
                    zh: '导入一张图片后即可开始电子拼图。',
                    en: 'Import an image to start the jigsaw.',
                  ),
                ),
              )
            else ...<Widget>[
              Text(
                _text(i18n, zh: '原图预览', en: 'Preview'),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = math.min(240.0, constraints.maxWidth);
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: width,
                      height: width,
                      child: Image.memory(_sourceBytes!, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                _text(i18n, zh: '拼图棋盘', en: 'Puzzle board'),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: _miniGameCompactLayout(context) ? 320 : 420,
                child: _buildPuzzleBoard(context, fullscreen: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PuzzleTilePainter extends CustomPainter {
  const _PuzzleTilePainter({
    required this.image,
    required this.sourceTileIndex,
    required this.rowCount,
    required this.colCount,
  });

  final ui.Image image;
  final int sourceTileIndex;
  final int rowCount;
  final int colCount;

  @override
  void paint(Canvas canvas, Size size) {
    final imageW = image.width.toDouble();
    final imageH = image.height.toDouble();
    final crop = math.min(imageW, imageH);
    final cropL = (imageW - crop) / 2;
    final cropT = (imageH - crop) / 2;
    final tileWidth = crop / colCount;
    final tileHeight = crop / rowCount;
    final srcRow = sourceTileIndex ~/ colCount;
    final srcCol = sourceTileIndex % colCount;
    final src = Rect.fromLTWH(
      cropL + srcCol * tileWidth,
      cropT + srcRow * tileHeight,
      tileWidth,
      tileHeight,
    );
    canvas.drawImageRect(image, src, Offset.zero & size, Paint());
  }

  @override
  bool shouldRepaint(covariant _PuzzleTilePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.sourceTileIndex != sourceTileIndex ||
        oldDelegate.rowCount != rowCount ||
        oldDelegate.colCount != colCount;
  }
}

enum _GomokuStone { empty, black, white }

enum _GomokuDifficulty { easy, medium, hard }

class _GomokuGame extends StatefulWidget {
  const _GomokuGame();

  @override
  State<_GomokuGame> createState() => _GomokuGameState();
}

class _GomokuGameState extends State<_GomokuGame> {
  static const int _size = 15;
  static const double _terminalScore = 1000000000;

  late List<_GomokuStone> _board;
  _GomokuStone _turn = _GomokuStone.black;
  _GomokuDifficulty _difficulty = _GomokuDifficulty.medium;
  final math.Random _random = math.Random();
  bool _aiThinking = false;
  bool _gameOver = false;
  bool _resultDialogOpen = false;
  int _moves = 0;
  int? _lastMove;
  int? _suggestedMove;
  String _status = 'Your turn (black)';
  bool _fullscreen = false;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  @override
  void dispose() {
    if (_fullscreen) {
      unawaited(_exitMiniGameFullscreen());
    }
    super.dispose();
  }

  int get _total => _size * _size;

  int _indexOf(int row, int col) => row * _size + col;

  bool _inBounds(int row, int col) {
    return row >= 0 && row < _size && col >= 0 && col < _size;
  }

  String _text(AppI18n i18n, {required String zh, required String en}) {
    return pickUiText(i18n, zh: zh, en: en);
  }

  _GomokuStone _opponent(_GomokuStone stone) {
    return stone == _GomokuStone.black
        ? _GomokuStone.white
        : _GomokuStone.black;
  }

  String _difficultyLabel(AppI18n i18n, _GomokuDifficulty difficulty) {
    return switch (difficulty) {
      _GomokuDifficulty.easy => _text(i18n, zh: '简单', en: 'Easy'),
      _GomokuDifficulty.medium => _text(i18n, zh: '标准', en: 'Medium'),
      _GomokuDifficulty.hard => _text(i18n, zh: '困难', en: 'Hard'),
    };
  }

  Widget _buildDifficultySelector(AppI18n i18n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final level in _GomokuDifficulty.values)
          ChoiceChip(
            label: Text(_difficultyLabel(i18n, level)),
            selected: _difficulty == level,
            onSelected: (_) {
              if (_difficulty == level) return;
              setState(() {
                _difficulty = level;
                _suggestedMove = null;
              });
            },
          ),
      ],
    );
  }

  Future<void> _setFullscreen(bool value) async {
    if (_fullscreen == value) {
      return;
    }
    setState(() {
      _fullscreen = value;
    });
    if (value) {
      await _enterMiniGameFullscreen(landscape: true);
    } else {
      await _exitMiniGameFullscreen();
    }
  }

  void _resetGame() {
    setState(() {
      _board = List<_GomokuStone>.filled(_total, _GomokuStone.empty);
      _turn = _GomokuStone.black;
      _aiThinking = false;
      _gameOver = false;
      _resultDialogOpen = false;
      _moves = 0;
      _lastMove = null;
      _suggestedMove = null;
      _status = 'Your turn (black)';
    });
  }

  void _finishGame({
    required String status,
    required String title,
    required String message,
  }) {
    setState(() {
      _gameOver = true;
      _status = status;
      _aiThinking = false;
    });
    unawaited(_showGameResultDialog(title: title, message: message));
  }

  Future<void> _showGameResultDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted || _resultDialogOpen) return;
    _resultDialogOpen = true;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_text(i18n, zh: '关闭', en: 'Close')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              child: Text(_text(i18n, zh: '新开一局', en: 'New game')),
            ),
          ],
        );
      },
    );
    _resultDialogOpen = false;
  }

  void _tapCell(int index) {
    if (_gameOver || _aiThinking || _turn != _GomokuStone.black) return;
    if (_board[index] != _GomokuStone.empty) return;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    setState(() {
      _board[index] = _GomokuStone.black;
      _moves += 1;
      _lastMove = index;
      _suggestedMove = null;
    });
    if (_winAt(index, _GomokuStone.black)) {
      _finishGame(
        status: _text(i18n, zh: '你获胜了', en: 'You win'),
        title: _text(i18n, zh: '对局结束', en: 'Game over'),
        message: _text(i18n, zh: '你赢下了这局五子棋。', en: 'You win this Gomoku game.'),
      );
      return;
    }
    if (_moves >= _total) {
      _finishGame(
        status: _text(i18n, zh: '平局', en: 'Draw'),
        title: _text(i18n, zh: '对局结束', en: 'Game over'),
        message: _text(i18n, zh: '平局，棋盘已满。', en: 'Draw. No more moves.'),
      );
      return;
    }
    setState(() {
      _turn = _GomokuStone.white;
      _aiThinking = true;
      _status = _text(i18n, zh: 'AI 思考中...', en: 'AI thinking...');
    });
    _runAiTurn();
  }

  Future<void> _runAiTurn() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted || _gameOver || !_aiThinking) return;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final bestMove = _chooseAiMove();
    if (bestMove == null) {
      _finishGame(
        status: _text(i18n, zh: '平局', en: 'Draw'),
        title: _text(i18n, zh: '对局结束', en: 'Game over'),
        message: _text(i18n, zh: '平局，棋盘已满。', en: 'Draw. No more moves.'),
      );
      return;
    }
    setState(() {
      _board[bestMove] = _GomokuStone.white;
      _moves += 1;
      _lastMove = bestMove;
      _aiThinking = false;
      _suggestedMove = null;
    });
    if (_winAt(bestMove, _GomokuStone.white)) {
      _finishGame(
        status: _text(i18n, zh: 'AI 获胜', en: 'AI wins'),
        title: _text(i18n, zh: '对局结束', en: 'Game over'),
        message: _text(
          i18n,
          zh: 'AI 赢下了这局五子棋。',
          en: 'AI wins this Gomoku game.',
        ),
      );
      return;
    }
    if (_moves >= _total) {
      _finishGame(
        status: _text(i18n, zh: '平局', en: 'Draw'),
        title: _text(i18n, zh: '对局结束', en: 'Game over'),
        message: _text(i18n, zh: '平局，棋盘已满。', en: 'Draw. No more moves.'),
      );
      return;
    }
    setState(() {
      _turn = _GomokuStone.black;
      _status = _text(i18n, zh: '轮到你执黑落子', en: 'Your turn (black)');
    });
  }

  int? _chooseAiMove() {
    if (_moves == 0) return _indexOf(_size ~/ 2, _size ~/ 2);
    final candidates = _candidateMoves();
    if (candidates.isEmpty) return null;

    final wins = <int>[
      for (final c in candidates)
        if (_wouldWin(c, _GomokuStone.white)) c,
    ];
    if (wins.isNotEmpty) {
      return _rankedCandidates(
        wins,
        offenseStone: _GomokuStone.white,
        defenseStone: _GomokuStone.black,
        offenseWeight: 1.3,
        defenseWeight: 1.0,
        limit: 1,
      ).first;
    }

    final blocks = <int>[
      for (final c in candidates)
        if (_wouldWin(c, _GomokuStone.black)) c,
    ];
    if (blocks.isNotEmpty) {
      if (_difficulty == _GomokuDifficulty.easy && _random.nextDouble() < 0.2) {
        return _chooseEasyMove(candidates);
      }
      return _rankedCandidates(
        blocks,
        offenseStone: _GomokuStone.white,
        defenseStone: _GomokuStone.black,
        offenseWeight: 0.9,
        defenseWeight: 1.8,
        limit: 1,
      ).first;
    }

    return switch (_difficulty) {
      _GomokuDifficulty.easy => _chooseEasyMove(candidates),
      _GomokuDifficulty.medium => _chooseMediumMove(candidates),
      _GomokuDifficulty.hard => _chooseHardMove(candidates),
    };
  }

  int _chooseEasyMove(List<int> candidates) {
    final ranked = _rankedCandidates(
      candidates,
      offenseStone: _GomokuStone.white,
      defenseStone: _GomokuStone.black,
      offenseWeight: 1.0,
      defenseWeight: 0.95,
      limit: 7,
    );
    final pool = ranked
        .take(math.min(4, ranked.length))
        .toList(growable: false);
    return pool[_random.nextInt(pool.length)];
  }

  int _chooseMediumMove(List<int> candidates) {
    final ranked = _rankedCandidates(
      candidates,
      offenseStone: _GomokuStone.white,
      defenseStone: _GomokuStone.black,
      offenseWeight: 1.12,
      defenseWeight: 1.2,
      limit: 6,
    );
    if (ranked.length > 1 && _random.nextDouble() < 0.2) {
      return ranked[1];
    }
    return ranked.first;
  }

  int _chooseHardMove(List<int> candidates) {
    final ranked = _rankedCandidates(
      candidates,
      offenseStone: _GomokuStone.white,
      defenseStone: _GomokuStone.black,
      offenseWeight: 1.2,
      defenseWeight: 1.3,
      limit: 10,
    );
    var bestMove = ranked.first;
    var bestScore = double.negativeInfinity;
    var alpha = double.negativeInfinity;
    for (final move in ranked) {
      _board[move] = _GomokuStone.white;
      final score = _winAt(move, _GomokuStone.white)
          ? _terminalScore
          : _minimaxScore(
              depth: 2,
              maximizingForAi: false,
              alpha: alpha,
              beta: double.infinity,
            );
      _board[move] = _GomokuStone.empty;
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
      if (score > alpha) {
        alpha = score;
      }
    }
    return bestMove;
  }

  List<int> _rankedCandidates(
    List<int> candidates, {
    required _GomokuStone offenseStone,
    required _GomokuStone defenseStone,
    required double offenseWeight,
    required double defenseWeight,
    int? limit,
  }) {
    final scored = <(int, double)>[];
    for (final c in candidates) {
      final attack = _evaluateMove(c, offenseStone);
      final defense = _evaluateMove(c, defenseStone);
      final center = _centerBias(c);
      final score =
          attack * offenseWeight +
          defense * defenseWeight +
          center +
          _random.nextDouble() * 0.001;
      scored.add((c, score));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    final ranked = <int>[for (final item in scored) item.$1];
    if (limit == null || ranked.length <= limit) {
      return ranked;
    }
    return ranked.sublist(0, limit);
  }

  double _minimaxScore({
    required int depth,
    required bool maximizingForAi,
    required double alpha,
    required double beta,
  }) {
    if (depth <= 0) {
      return _boardHeuristicScore();
    }
    final candidates = _candidateMoves();
    if (candidates.isEmpty) {
      return _boardHeuristicScore();
    }
    final stone = maximizingForAi ? _GomokuStone.white : _GomokuStone.black;
    final ranked = _rankedCandidates(
      candidates,
      offenseStone: stone,
      defenseStone: _opponent(stone),
      offenseWeight: maximizingForAi ? 1.15 : 1.2,
      defenseWeight: maximizingForAi ? 1.1 : 1.28,
      limit: maximizingForAi ? 8 : 7,
    );

    if (maximizingForAi) {
      var best = double.negativeInfinity;
      for (final move in ranked) {
        _board[move] = _GomokuStone.white;
        final score = _winAt(move, _GomokuStone.white)
            ? _terminalScore - (2 - depth)
            : _minimaxScore(
                depth: depth - 1,
                maximizingForAi: false,
                alpha: alpha,
                beta: beta,
              );
        _board[move] = _GomokuStone.empty;
        if (score > best) {
          best = score;
        }
        if (score > alpha) {
          alpha = score;
        }
        if (alpha >= beta) {
          break;
        }
      }
      return best;
    }

    var best = double.infinity;
    for (final move in ranked) {
      _board[move] = _GomokuStone.black;
      final score = _winAt(move, _GomokuStone.black)
          ? -_terminalScore + (2 - depth)
          : _minimaxScore(
              depth: depth - 1,
              maximizingForAi: true,
              alpha: alpha,
              beta: beta,
            );
      _board[move] = _GomokuStone.empty;
      if (score < best) {
        best = score;
      }
      if (score < beta) {
        beta = score;
      }
      if (beta <= alpha) {
        break;
      }
    }
    return best;
  }

  double _boardHeuristicScore() {
    final candidates = _candidateMoves();
    if (candidates.isEmpty) {
      return 0;
    }
    final ranked = _rankedCandidates(
      candidates,
      offenseStone: _GomokuStone.white,
      defenseStone: _GomokuStone.black,
      offenseWeight: 1.0,
      defenseWeight: 1.0,
      limit: 12,
    );
    var aiBest = double.negativeInfinity;
    var playerBest = double.negativeInfinity;
    for (final move in ranked) {
      aiBest = math.max(aiBest, _evaluateMove(move, _GomokuStone.white));
      playerBest = math.max(
        playerBest,
        _evaluateMove(move, _GomokuStone.black),
      );
    }
    if (aiBest.isInfinite) aiBest = 0;
    if (playerBest.isInfinite) playerBest = 0;
    return aiBest * 1.16 - playerBest * 1.22;
  }

  List<int> _candidateMoves() {
    final near = <int>{};
    for (var i = 0; i < _board.length; i += 1) {
      if (_board[i] == _GomokuStone.empty) continue;
      final row = i ~/ _size;
      final col = i % _size;
      for (var dr = -2; dr <= 2; dr += 1) {
        for (var dc = -2; dc <= 2; dc += 1) {
          final nr = row + dr;
          final nc = col + dc;
          if (!_inBounds(nr, nc)) continue;
          final idx = _indexOf(nr, nc);
          if (_board[idx] == _GomokuStone.empty) near.add(idx);
        }
      }
    }
    if (near.isNotEmpty) return near.toList(growable: false);
    return <int>[
      for (var i = 0; i < _board.length; i += 1)
        if (_board[i] == _GomokuStone.empty) i,
    ];
  }

  bool _wouldWin(int index, _GomokuStone stone) {
    if (_board[index] != _GomokuStone.empty) return false;
    _board[index] = stone;
    final result = _winAt(index, stone);
    _board[index] = _GomokuStone.empty;
    return result;
  }

  double _evaluateMove(int index, _GomokuStone stone) {
    if (_board[index] != _GomokuStone.empty) return -1;
    _board[index] = stone;
    final row = index ~/ _size;
    final col = index % _size;
    const dirs = <List<int>>[
      <int>[1, 0],
      <int>[0, 1],
      <int>[1, 1],
      <int>[1, -1],
    ];
    var score = 0.0;
    for (final d in dirs) {
      score += _lineScore(row, col, d[0], d[1], stone);
    }
    _board[index] = _GomokuStone.empty;
    return score;
  }

  double _lineScore(int row, int col, int dr, int dc, _GomokuStone stone) {
    var forward = 0;
    var backward = 0;
    var r = row + dr;
    var c = col + dc;
    while (_inBounds(r, c) && _board[_indexOf(r, c)] == stone) {
      forward += 1;
      r += dr;
      c += dc;
    }
    final openForward =
        _inBounds(r, c) && _board[_indexOf(r, c)] == _GomokuStone.empty;

    r = row - dr;
    c = col - dc;
    while (_inBounds(r, c) && _board[_indexOf(r, c)] == stone) {
      backward += 1;
      r -= dr;
      c -= dc;
    }
    final openBackward =
        _inBounds(r, c) && _board[_indexOf(r, c)] == _GomokuStone.empty;

    final total = 1 + forward + backward;
    final openEnds = (openForward ? 1 : 0) + (openBackward ? 1 : 0);

    if (total >= 5) return 10000000;
    if (total == 4 && openEnds == 2) return 900000;
    if (total == 4 && openEnds == 1) return 130000;
    if (total == 3 && openEnds == 2) return 22000;
    if (total == 3 && openEnds == 1) return 3500;
    if (total == 2 && openEnds == 2) return 700;
    if (total == 2 && openEnds == 1) return 120;
    if (total == 1 && openEnds == 2) return 35;
    return 8;
  }

  double _centerBias(int index) {
    final row = index ~/ _size;
    final col = index % _size;
    final center = (_size - 1) / 2;
    final dist = (row - center).abs() + (col - center).abs();
    return (_size - dist) * 0.5;
  }

  bool _winAt(int index, _GomokuStone stone) {
    final row = index ~/ _size;
    final col = index % _size;
    const dirs = <List<int>>[
      <int>[1, 0],
      <int>[0, 1],
      <int>[1, 1],
      <int>[1, -1],
    ];
    for (final d in dirs) {
      final connected =
          1 +
          _count(row, col, d[0], d[1], stone) +
          _count(row, col, -d[0], -d[1], stone);
      if (connected >= 5) return true;
    }
    return false;
  }

  int _count(int row, int col, int dr, int dc, _GomokuStone stone) {
    var count = 0;
    var r = row + dr;
    var c = col + dc;
    while (_inBounds(r, c) && _board[_indexOf(r, c)] == stone) {
      count += 1;
      r += dr;
      c += dc;
    }
    return count;
  }

  bool _isStarPoint(int row, int col) {
    const points = <int>[3, 7, 11];
    return points.contains(row) && points.contains(col);
  }

  int? _choosePlayerHintMove() {
    if (_gameOver || _aiThinking || _turn != _GomokuStone.black) {
      return null;
    }
    if (_moves == 0) {
      return _indexOf(_size ~/ 2, _size ~/ 2);
    }
    final candidates = _candidateMoves();
    if (candidates.isEmpty) {
      return null;
    }
    return _rankedCandidates(
      candidates,
      offenseStone: _GomokuStone.black,
      defenseStone: _GomokuStone.white,
      offenseWeight: 1.1,
      defenseWeight: 1.18,
      limit: 1,
    ).first;
  }

  void _showHint() {
    final suggestion = _choosePlayerHintMove();
    if (suggestion == null || !mounted) {
      return;
    }
    final row = suggestion ~/ _size + 1;
    final col = suggestion % _size + 1;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    setState(() {
      _suggestedMove = suggestion;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _text(
            i18n,
            zh: '建议在第 $row 行第 $col 列落子。',
            en: 'Suggested move: row $row, column $col.',
          ),
        ),
      ),
    );
  }

  Widget _buildBoard(BuildContext context, {required bool fullscreen}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final targetCell = fullscreen
            ? 34.0
            : _miniGameCompactLayout(context)
            ? 24.0
            : 30.0;
        final boardWidth = math.max(viewportWidth, _size * targetCell);
        final cellExtent = boardWidth / _size;
        return _MiniGameScrollLockSurface(
          child: InteractiveViewer(
            minScale: 0.7,
            maxScale: 4,
            boundaryMargin: const EdgeInsets.all(24),
            child: Center(
              child: SizedBox(
                width: boardWidth,
                height: boardWidth,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _board.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _size,
                  ),
                  itemBuilder: (context, index) {
                    final row = index ~/ _size;
                    final col = index % _size;
                    final suggested = _suggestedMove == index;
                    return GestureDetector(
                      onTap: () => _tapCell(index),
                      child: Container(
                        margin: EdgeInsets.all(cellExtent <= 24 ? 0.18 : 0.3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1D6A9),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.45),
                            width: cellExtent <= 24 ? 0.3 : 0.45,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            if (_board[index] == _GomokuStone.empty &&
                                _isStarPoint(row, col))
                              Container(
                                width: (cellExtent * 0.18)
                                    .clamp(3, 7)
                                    .toDouble(),
                                height: (cellExtent * 0.18)
                                    .clamp(3, 7)
                                    .toDouble(),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF7E5525),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (suggested &&
                                _board[index] == _GomokuStone.empty)
                              Container(
                                width: cellExtent * 0.64,
                                height: cellExtent * 0.64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF2E6CE6),
                                    width: 2,
                                  ),
                                ),
                              ),
                            _GomokuStoneView(
                              stone: _board[index],
                              highlight: _lastMove == index,
                              extent: cellExtent,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final displayStatus = _gameOver
        ? _status
        : _aiThinking
        ? _text(i18n, zh: 'AI 思考中...', en: 'AI thinking...')
        : _text(i18n, zh: '轮到你执黑落子', en: 'Your turn (black)');
    if (_fullscreen) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton.tonalIcon(
                      onPressed: () => _setFullscreen(false),
                      icon: const Icon(Icons.fullscreen_exit_rounded),
                      label: Text(
                        _text(i18n, zh: '退出全屏', en: 'Exit fullscreen'),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed:
                          _aiThinking ||
                              _gameOver ||
                              _turn != _GomokuStone.black
                          ? null
                          : _showHint,
                      icon: const Icon(Icons.tips_and_updates_outlined),
                      label: Text(_text(i18n, zh: '提示', en: 'Hint')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _resetGame,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(_text(i18n, zh: '新开一局', en: 'New game')),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    ToolboxMetricCard(
                      label: _text(i18n, zh: '棋盘', en: 'Board'),
                      value: '15x15',
                    ),
                    ToolboxMetricCard(
                      label: _text(i18n, zh: '步数', en: 'Moves'),
                      value: '$_moves',
                    ),
                    ToolboxMetricCard(
                      label: _text(i18n, zh: '状态', en: 'Status'),
                      value: displayStatus,
                    ),
                    ToolboxMetricCard(
                      label: _text(i18n, zh: 'AI 难度', en: 'AI level'),
                      value: _difficultyLabel(i18n, _difficulty),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDifficultySelector(i18n),
                const SizedBox(height: 12),
                Expanded(child: _buildBoard(context, fullscreen: true)),
              ],
            ),
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(
                  label: _text(i18n, zh: '棋盘', en: 'Board'),
                  value: '15x15',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '步数', en: 'Moves'),
                  value: '$_moves',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '状态', en: 'Status'),
                  value: displayStatus,
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: 'AI 难度', en: 'AI level'),
                  value: _difficultyLabel(i18n, _difficulty),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDifficultySelector(i18n),
            const SizedBox(height: 12),
            Text(
              _text(
                i18n,
                zh: '你执黑先行。点击空位落子，可使用提示查看建议落点。',
                en: 'You play black first. Tap an empty cell to place a stone, or use hint for a suggested move.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: _miniGameCompactLayout(context) ? 360 : 520,
              child: _buildBoard(context, fullscreen: false),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: _resetGame,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(_text(i18n, zh: '新开一局', en: 'New game')),
                ),
                FilledButton.tonalIcon(
                  onPressed:
                      _aiThinking || _gameOver || _turn != _GomokuStone.black
                      ? null
                      : _showHint,
                  icon: const Icon(Icons.tips_and_updates_outlined),
                  label: Text(_text(i18n, zh: '提示', en: 'Hint')),
                ),
                OutlinedButton.icon(
                  onPressed: () => _setFullscreen(true),
                  icon: const Icon(Icons.fullscreen_rounded),
                  label: Text(_text(i18n, zh: '全屏棋盘', en: 'Fullscreen board')),
                ),
                if (_aiThinking)
                  Chip(
                    avatar: const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    label: Text(_text(i18n, zh: 'AI 思考中', en: 'AI thinking')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GomokuStoneView extends StatelessWidget {
  const _GomokuStoneView({
    required this.stone,
    required this.highlight,
    required this.extent,
  });

  final _GomokuStone stone;
  final bool highlight;
  final double extent;

  @override
  Widget build(BuildContext context) {
    if (stone == _GomokuStone.empty) {
      return const SizedBox.shrink();
    }
    final fill = stone == _GomokuStone.black
        ? const Color(0xFF1F1F1F)
        : const Color(0xFFF7F7F7);
    final border = stone == _GomokuStone.black
        ? const Color(0xFF3A3A3A)
        : const Color(0xFF7D7D7D);
    final stoneSize = (extent * 0.74).clamp(12, 26).toDouble();
    final markerSize = (extent * 0.22).clamp(3, 6).toDouble();
    return Container(
      width: stoneSize,
      height: stoneSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: border, width: 1),
      ),
      child: highlight
          ? Center(
              child: Container(
                width: markerSize,
                height: markerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: stone == _GomokuStone.black
                      ? const Color(0xFFF5D77E)
                      : const Color(0xFF8A5B22),
                ),
              ),
            )
          : null,
    );
  }
}

enum _SlideDirection { up, down, left, right }

class _SlideNumberGame extends StatefulWidget {
  const _SlideNumberGame();

  @override
  State<_SlideNumberGame> createState() => _SlideNumberGameState();
}

class _SlideNumberGameState extends State<_SlideNumberGame> {
  static const int _size = 4;
  final math.Random _random = math.Random();

  late List<int> _board;
  int _score = 0;
  int _bestTile = 0;
  int _target = 2048;
  bool _won = false;
  bool _gameOver = false;
  Offset? _dragStart;
  bool _dragConsumed = false;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  String _text(AppI18n i18n, {required String zh, required String en}) {
    return pickUiText(i18n, zh: zh, en: en);
  }

  void _newGame() {
    setState(() {
      _board = List<int>.filled(_size * _size, 0);
      _score = 0;
      _bestTile = 0;
      _won = false;
      _gameOver = false;
      _spawnRandomTile();
      _spawnRandomTile();
    });
  }

  void _setTarget(int target) {
    if (_target == target) return;
    setState(() {
      _target = target;
      _won = _bestTile >= _target;
    });
  }

  void _spawnRandomTile() {
    final empty = <int>[
      for (var i = 0; i < _board.length; i += 1)
        if (_board[i] == 0) i,
    ];
    if (empty.isEmpty) return;
    final index = empty[_random.nextInt(empty.length)];
    _board[index] = _random.nextDouble() < 0.9 ? 2 : 4;
  }

  void _handleDragStart(Offset position) {
    _dragStart = position;
    _dragConsumed = false;
  }

  void _handleDragUpdate(Offset position) {
    if (_dragConsumed || _dragStart == null) {
      return;
    }
    final delta = position - _dragStart!;
    if (delta.distance < 18) {
      return;
    }
    _dragConsumed = true;
    if (delta.dx.abs() > delta.dy.abs()) {
      _move(delta.dx > 0 ? _SlideDirection.right : _SlideDirection.left);
    } else {
      _move(delta.dy > 0 ? _SlideDirection.down : _SlideDirection.up);
    }
  }

  void _handleVerticalDragStart(DragStartDetails details) =>
      _handleDragStart(details.localPosition);

  void _handleHorizontalDragStart(DragStartDetails details) =>
      _handleDragStart(details.localPosition);

  void _handleVerticalDragUpdate(DragUpdateDetails details) =>
      _handleDragUpdate(details.localPosition);

  void _handleHorizontalDragUpdate(DragUpdateDetails details) =>
      _handleDragUpdate(details.localPosition);

  void _handleDragEnd([DragEndDetails? _]) {
    _dragStart = null;
    _dragConsumed = false;
  }

  void _move(_SlideDirection direction) {
    if (_gameOver) return;
    final previous = List<int>.from(_board);
    var gained = 0;

    for (var i = 0; i < _size; i += 1) {
      final line = _readLine(i, direction);
      final merged = _mergeLine(line);
      gained += merged.scoreGain;
      _writeLine(i, direction, merged.values);
    }

    if (_listEquals(previous, _board)) return;

    setState(() {
      _score += gained;
      _spawnRandomTile();
      _bestTile = _board.reduce(math.max);
      if (!_won && _bestTile >= _target) {
        _won = true;
      }
      _gameOver = !_hasValidMove();
    });
  }

  List<int> _readLine(int index, _SlideDirection direction) {
    final values = <int>[];
    for (var offset = 0; offset < _size; offset += 1) {
      final row = switch (direction) {
        _SlideDirection.left => index,
        _SlideDirection.right => index,
        _SlideDirection.up => offset,
        _SlideDirection.down => _size - 1 - offset,
      };
      final col = switch (direction) {
        _SlideDirection.left => offset,
        _SlideDirection.right => _size - 1 - offset,
        _SlideDirection.up => index,
        _SlideDirection.down => index,
      };
      values.add(_board[row * _size + col]);
    }
    return values;
  }

  void _writeLine(int index, _SlideDirection direction, List<int> values) {
    for (var offset = 0; offset < _size; offset += 1) {
      final row = switch (direction) {
        _SlideDirection.left => index,
        _SlideDirection.right => index,
        _SlideDirection.up => offset,
        _SlideDirection.down => _size - 1 - offset,
      };
      final col = switch (direction) {
        _SlideDirection.left => offset,
        _SlideDirection.right => _size - 1 - offset,
        _SlideDirection.up => index,
        _SlideDirection.down => index,
      };
      _board[row * _size + col] = values[offset];
    }
  }

  _MergeLineResult _mergeLine(List<int> line) {
    final compact = <int>[
      for (final value in line)
        if (value != 0) value,
    ];
    final merged = <int>[];
    var scoreGain = 0;

    var cursor = 0;
    while (cursor < compact.length) {
      final current = compact[cursor];
      if (cursor + 1 < compact.length && compact[cursor + 1] == current) {
        final next = current * 2;
        merged.add(next);
        scoreGain += next;
        cursor += 2;
      } else {
        merged.add(current);
        cursor += 1;
      }
    }

    while (merged.length < _size) {
      merged.add(0);
    }
    return _MergeLineResult(values: merged, scoreGain: scoreGain);
  }

  bool _hasValidMove() {
    if (_board.any((value) => value == 0)) return true;
    for (var row = 0; row < _size; row += 1) {
      for (var col = 0; col < _size; col += 1) {
        final current = _board[row * _size + col];
        if (row + 1 < _size && _board[(row + 1) * _size + col] == current) {
          return true;
        }
        if (col + 1 < _size && _board[row * _size + (col + 1)] == current) {
          return true;
        }
      }
    }
    return false;
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Color _tileColor(int value) {
    return switch (value) {
      0 => const Color(0xFFCDC1B4),
      2 => const Color(0xFFEEE4DA),
      4 => const Color(0xFFEDE0C8),
      8 => const Color(0xFFF2B179),
      16 => const Color(0xFFF59563),
      32 => const Color(0xFFF67C5F),
      64 => const Color(0xFFF65E3B),
      128 => const Color(0xFFEDCF72),
      256 => const Color(0xFFEDCC61),
      512 => const Color(0xFFEDC850),
      1024 => const Color(0xFFEDC53F),
      2048 => const Color(0xFFEDC22E),
      _ => const Color(0xFF3C3A32),
    };
  }

  Color _tileTextColor(int value) {
    return value <= 4 ? const Color(0xFF776E65) : const Color(0xFFF9F6F2);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final status = _gameOver
        ? _text(i18n, zh: '游戏结束', en: 'Game over')
        : _won
        ? _text(i18n, zh: '已达到目标', en: 'Target reached')
        : _text(i18n, zh: '进行中', en: 'Playing');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(
                  label: _text(i18n, zh: '得分', en: 'Score'),
                  value: '$_score',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '最大数字', en: 'Best tile'),
                  value: '$_bestTile',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '目标', en: 'Target'),
                  value: '$_target',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '状态', en: 'Status'),
                  value: status,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('2048'),
                  selected: _target == 2048,
                  onSelected: (_) => _setTarget(2048),
                ),
                ChoiceChip(
                  label: const Text('4096'),
                  selected: _target == 4096,
                  onSelected: (_) => _setTarget(4096),
                ),
                OutlinedButton.icon(
                  onPressed: _newGame,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(_text(i18n, zh: '新开一局', en: 'New game')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _text(
                i18n,
                zh: '在棋盘上滑动即可移动数字，页面滚动不会抢走滑动手势。',
                en: 'Swipe on the board to move tiles. Page scrolling will no longer steal the gesture.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final boardSize = math.min(420.0, constraints.maxWidth);
                return Center(
                  child: _MiniGameScrollLockSurface(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      dragStartBehavior: DragStartBehavior.down,
                      onVerticalDragStart: _handleVerticalDragStart,
                      onVerticalDragUpdate: _handleVerticalDragUpdate,
                      onVerticalDragEnd: _handleDragEnd,
                      onVerticalDragCancel: () => _handleDragEnd(),
                      onHorizontalDragStart: _handleHorizontalDragStart,
                      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
                      onHorizontalDragEnd: _handleDragEnd,
                      onHorizontalDragCancel: () => _handleDragEnd(),
                      child: Container(
                        width: boardSize,
                        height: boardSize,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBBADA0),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _board.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _size,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                          itemBuilder: (context, index) {
                            final value = _board[index];
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              decoration: BoxDecoration(
                                color: _tileColor(value),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                value == 0 ? '' : '$value',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: _tileTextColor(value),
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonal(
                  onPressed: () => _move(_SlideDirection.up),
                  child: Text(_text(i18n, zh: '上', en: 'Up')),
                ),
                FilledButton.tonal(
                  onPressed: () => _move(_SlideDirection.left),
                  child: Text(_text(i18n, zh: '左', en: 'Left')),
                ),
                FilledButton.tonal(
                  onPressed: () => _move(_SlideDirection.down),
                  child: Text(_text(i18n, zh: '下', en: 'Down')),
                ),
                FilledButton.tonal(
                  onPressed: () => _move(_SlideDirection.right),
                  child: Text(_text(i18n, zh: '右', en: 'Right')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MergeLineResult {
  const _MergeLineResult({required this.values, required this.scoreGain});

  final List<int> values;
  final int scoreGain;
}

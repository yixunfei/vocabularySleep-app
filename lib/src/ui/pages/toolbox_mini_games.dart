import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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
    final entries = <_MiniGameEntry>[
      const _MiniGameEntry(
        title: '数独',
        subtitle: '9x9 逻辑填数。',
        icon: Icons.grid_on_rounded,
        accent: Color(0xFF5C7BE1),
        pageBuilder: SudokuGamePage.new,
      ),
      const _MiniGameEntry(
        title: '扫雷',
        subtitle: '翻开格子并插旗排雷。',
        icon: Icons.flag_rounded,
        accent: Color(0xFF3EA37D),
        pageBuilder: MinesweeperGamePage.new,
      ),
      const _MiniGameEntry(
        title: '电子拼图',
        subtitle: '导入图片后自动切片拼图。',
        icon: Icons.extension_rounded,
        accent: Color(0xFFD0874A),
        pageBuilder: JigsawGamePage.new,
      ),
      const _MiniGameEntry(
        title: '五子棋',
        subtitle: '人机对战，AI 自动应对。',
        icon: Icons.radio_button_checked_rounded,
        accent: Color(0xFF9A6B3A),
        pageBuilder: GomokuGamePage.new,
      ),
      const _MiniGameEntry(
        title: '2048 / 4096',
        subtitle: '滑动合并数字。',
        icon: Icons.view_module_rounded,
        accent: Color(0xFFB47A45),
        pageBuilder: SlideNumberGamePage.new,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(
          title: 'Game hub',
          subtitle: 'Choose a game from the toolbox mini-game module.',
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
  static const int _rows = 9;
  static const int _cols = 9;
  static const int _mineCount = 12;

  late List<_MineCell> _cells;
  bool _firstMove = true;
  bool _lost = false;
  bool _won = false;
  int _revealedSafe = 0;

  @override
  void initState() {
    super.initState();
    _resetBoard();
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

  void _resetBoard({int? safeIndex}) {
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

  void _toggleFlag(int index) {
    if (_lost || _won) return;
    final cell = _cells[index];
    if (cell.revealed) return;
    setState(() {
      cell.flagged = !cell.flagged;
    });
  }

  void _reveal(int index) {
    if (_lost || _won) return;
    final cell = _cells[index];
    if (cell.revealed || cell.flagged) return;

    setState(() {
      if (_firstMove) {
        _firstMove = false;
        if (_cells[index].hasMine) {
          _resetBoard(safeIndex: index);
          _firstMove = false;
        }
      }

      if (_cells[index].hasMine) {
        _lost = true;
        for (final c in _cells) {
          if (c.hasMine) c.revealed = true;
        }
        return;
      }

      _floodReveal(index);
      if (_revealedSafe >= _safeCellTotal) {
        _won = true;
        for (final c in _cells) {
          if (c.hasMine) c.flagged = true;
        }
      }
    });

    if (_won && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Minesweeper cleared!')));
    }
  }

  void _floodReveal(int start) {
    final queue = Queue<int>()..add(start);
    while (queue.isNotEmpty) {
      final index = queue.removeFirst();
      final cell = _cells[index];
      if (cell.revealed || cell.flagged) continue;
      cell.revealed = true;
      if (!cell.hasMine) _revealedSafe += 1;
      if (cell.neighborMines > 0) continue;
      for (final neighbor in _neighbors(index)) {
        final next = _cells[neighbor];
        if (!next.revealed && !next.flagged && !next.hasMine) {
          queue.add(neighbor);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final flags = _cells.where((c) => c.flagged).length;
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
                const ToolboxMetricCard(label: 'Mines', value: '12'),
                ToolboxMetricCard(
                  label: 'Mines left',
                  value: '${math.max(0, _mineCount - flags)}',
                ),
                ToolboxMetricCard(
                  label: 'Progress',
                  value: '$_revealedSafe / $_safeCellTotal',
                ),
                ToolboxMetricCard(
                  label: 'Status',
                  value: _lost
                      ? 'Boom'
                      : _won
                      ? 'Cleared'
                      : 'Playing',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Tap to reveal, long press to flag.',
              style: Theme.of(context).textTheme.bodySmall,
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
                      itemCount: _cells.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _cols,
                          ),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _reveal(index),
                          onLongPress: () => _toggleFlag(index),
                          child: _MineCellTile(cell: _cells[index]),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => setState(_resetBoard),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('New game'),
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
  bool flagged = false;
  int neighborMines = 0;
}

class _MineCellTile extends StatelessWidget {
  const _MineCellTile({required this.cell});

  final _MineCell cell;

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
    Widget child;
    if (cell.revealed && cell.hasMine) {
      child = Icon(Icons.circle, color: scheme.error, size: 18);
    } else if (!cell.revealed && cell.flagged) {
      child = const Icon(
        Icons.flag_rounded,
        color: Color(0xFFC14E2D),
        size: 18,
      );
    } else if (cell.revealed && cell.neighborMines > 0) {
      child = Text(
        '${cell.neighborMines}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: _numbers[cell.neighborMines],
        ),
      );
    } else {
      child = const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.all(0.5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cell.revealed
            ? scheme.surfaceContainerLow
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.outlineVariant),
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
  int _gridSize = 3;
  List<int> _tiles = const <int>[];
  int? _selectedTile;
  int _moves = 0;
  bool _loading = false;
  bool _solved = false;
  String? _error;

  @override
  void dispose() {
    _sourceImage?.dispose();
    super.dispose();
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
          _error = 'Failed to read image bytes.';
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
        _tiles = _shuffleTiles(_gridSize);
        _selectedTile = null;
        _moves = 0;
        _solved = false;
        _loading = false;
      });
      old?.dispose();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to import image.';
      });
    }
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  List<int> _shuffleTiles(int gridSize) {
    final total = gridSize * gridSize;
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

  void _changeGrid(int size) {
    if (size == _gridSize) return;
    setState(() {
      _gridSize = size;
      _selectedTile = null;
      _moves = 0;
      _solved = false;
      _tiles = _sourceImage == null ? const <int>[] : _shuffleTiles(size);
    });
  }

  void _shuffle() {
    if (_sourceImage == null) return;
    setState(() {
      _tiles = _shuffleTiles(_gridSize);
      _selectedTile = null;
      _moves = 0;
      _solved = false;
    });
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
      _moves += 1;
      _solved = _isSolved(next);
    });
    if (_solved && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Puzzle complete!')));
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  label: Text(_loading ? 'Importing...' : 'Import image'),
                ),
                OutlinedButton.icon(
                  onPressed: _sourceImage == null || _loading ? null : _shuffle,
                  icon: const Icon(Icons.shuffle_rounded),
                  label: const Text('Shuffle'),
                ),
                for (final size in <int>[3, 4, 5])
                  ChoiceChip(
                    label: Text('${size}x$size'),
                    selected: _gridSize == size,
                    onSelected: (_) => _changeGrid(size),
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
                  label: 'Grid',
                  value: '${_gridSize}x$_gridSize',
                ),
                ToolboxMetricCard(label: 'Moves', value: '$_moves'),
                ToolboxMetricCard(
                  label: 'Status',
                  value: _solved ? 'Solved' : 'Playing',
                ),
              ],
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
                child: const Text('Import an image to start the jigsaw.'),
              )
            else ...<Widget>[
              Text(
                'Preview',
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
                'Puzzle board',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = math.min(440.0, constraints.maxWidth);
                  final image = _sourceImage!;
                  return Center(
                    child: SizedBox(
                      width: width,
                      height: width,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _tiles.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _gridSize,
                        ),
                        itemBuilder: (context, index) {
                          final selected = _selectedTile == index;
                          return GestureDetector(
                            onTap: () => _tapTile(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              margin: const EdgeInsets.all(2),
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: selected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.outlineVariant,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: CustomPaint(
                                painter: _PuzzleTilePainter(
                                  image: image,
                                  sourceTileIndex: _tiles[index],
                                  gridSize: _gridSize,
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
    required this.gridSize,
  });

  final ui.Image image;
  final int sourceTileIndex;
  final int gridSize;

  @override
  void paint(Canvas canvas, Size size) {
    final imageW = image.width.toDouble();
    final imageH = image.height.toDouble();
    final crop = math.min(imageW, imageH);
    final cropL = (imageW - crop) / 2;
    final cropT = (imageH - crop) / 2;
    final tile = crop / gridSize;
    final srcRow = sourceTileIndex ~/ gridSize;
    final srcCol = sourceTileIndex % gridSize;
    final src = Rect.fromLTWH(
      cropL + srcCol * tile,
      cropT + srcRow * tile,
      tile,
      tile,
    );
    canvas.drawImageRect(image, src, Offset.zero & size, Paint());
  }

  @override
  bool shouldRepaint(covariant _PuzzleTilePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.sourceTileIndex != sourceTileIndex ||
        oldDelegate.gridSize != gridSize;
  }
}

enum _GomokuStone { empty, black, white }

class _GomokuGame extends StatefulWidget {
  const _GomokuGame();

  @override
  State<_GomokuGame> createState() => _GomokuGameState();
}

class _GomokuGameState extends State<_GomokuGame> {
  static const int _size = 15;

  late List<_GomokuStone> _board;
  _GomokuStone _turn = _GomokuStone.black;
  bool _aiThinking = false;
  bool _gameOver = false;
  int _moves = 0;
  int? _lastMove;
  String _status = 'Your turn (black)';

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  int get _total => _size * _size;

  int _indexOf(int row, int col) => row * _size + col;

  bool _inBounds(int row, int col) {
    return row >= 0 && row < _size && col >= 0 && col < _size;
  }

  void _resetGame() {
    setState(() {
      _board = List<_GomokuStone>.filled(_total, _GomokuStone.empty);
      _turn = _GomokuStone.black;
      _aiThinking = false;
      _gameOver = false;
      _moves = 0;
      _lastMove = null;
      _status = 'Your turn (black)';
    });
  }

  void _tapCell(int index) {
    if (_gameOver || _aiThinking || _turn != _GomokuStone.black) return;
    if (_board[index] != _GomokuStone.empty) return;
    setState(() {
      _board[index] = _GomokuStone.black;
      _moves += 1;
      _lastMove = index;
    });
    if (_winAt(index, _GomokuStone.black)) {
      setState(() {
        _gameOver = true;
        _status = 'You win';
      });
      return;
    }
    if (_moves >= _total) {
      setState(() {
        _gameOver = true;
        _status = 'Draw';
      });
      return;
    }
    setState(() {
      _turn = _GomokuStone.white;
      _aiThinking = true;
      _status = 'AI thinking...';
    });
    _runAiTurn();
  }

  Future<void> _runAiTurn() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted || _gameOver || !_aiThinking) return;
    final bestMove = _chooseAiMove();
    if (bestMove == null) {
      setState(() {
        _gameOver = true;
        _aiThinking = false;
        _status = 'Draw';
      });
      return;
    }
    setState(() {
      _board[bestMove] = _GomokuStone.white;
      _moves += 1;
      _lastMove = bestMove;
      _aiThinking = false;
    });
    if (_winAt(bestMove, _GomokuStone.white)) {
      setState(() {
        _gameOver = true;
        _status = 'AI wins';
      });
      return;
    }
    if (_moves >= _total) {
      setState(() {
        _gameOver = true;
        _status = 'Draw';
      });
      return;
    }
    setState(() {
      _turn = _GomokuStone.black;
      _status = 'Your turn (black)';
    });
  }

  int? _chooseAiMove() {
    if (_moves == 0) return _indexOf(_size ~/ 2, _size ~/ 2);
    final candidates = _candidateMoves();
    if (candidates.isEmpty) return null;

    for (final c in candidates) {
      if (_wouldWin(c, _GomokuStone.white)) return c;
    }

    final blocks = <int>[
      for (final c in candidates)
        if (_wouldWin(c, _GomokuStone.black)) c,
    ];
    if (blocks.isNotEmpty) {
      return _bestScored(blocks, attackWeight: 0.85, defenseWeight: 1.2);
    }
    return _bestScored(candidates, attackWeight: 1.0, defenseWeight: 0.95);
  }

  int _bestScored(
    List<int> candidates, {
    required double attackWeight,
    required double defenseWeight,
  }) {
    final random = math.Random();
    var best = candidates.first;
    var scoreBest = -1.0;
    for (final c in candidates) {
      final attack = _evaluateMove(c, _GomokuStone.white);
      final defense = _evaluateMove(c, _GomokuStone.black);
      final center = _centerBias(c);
      final score =
          attack * attackWeight +
          defense * defenseWeight +
          center +
          random.nextDouble() * 0.001;
      if (score > scoreBest) {
        scoreBest = score;
        best = c;
      }
    }
    return best;
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

  @override
  Widget build(BuildContext context) {
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
                const ToolboxMetricCard(label: 'Board', value: '15x15'),
                ToolboxMetricCard(label: 'Moves', value: '$_moves'),
                ToolboxMetricCard(label: 'Status', value: _status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'You play black. Tap an empty cell to place a stone.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final boardSize = math.min(560.0, constraints.maxWidth);
                return Center(
                  child: SizedBox(
                    width: boardSize,
                    height: boardSize,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _board.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _size,
                          ),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _tapCell(index),
                          child: Container(
                            margin: const EdgeInsets.all(0.3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1D6A9),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.45),
                                width: 0.45,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: _GomokuStoneView(
                              stone: _board[index],
                              highlight: _lastMove == index,
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
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: _resetGame,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('New game'),
                ),
                if (_aiThinking)
                  const Chip(
                    avatar: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    label: Text('AI thinking'),
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
  const _GomokuStoneView({required this.stone, required this.highlight});

  final _GomokuStone stone;
  final bool highlight;

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
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: border, width: 1),
      ),
      child: highlight
          ? Center(
              child: Container(
                width: 5,
                height: 5,
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

  @override
  void initState() {
    super.initState();
    _newGame();
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

  void _handleSwipe(DragEndDetails details) {
    final speed = details.velocity.pixelsPerSecond;
    final dx = speed.dx;
    final dy = speed.dy;
    if (dx.abs() < 160 && dy.abs() < 160) return;
    if (dx.abs() > dy.abs()) {
      _move(dx > 0 ? _SlideDirection.right : _SlideDirection.left);
    } else {
      _move(dy > 0 ? _SlideDirection.down : _SlideDirection.up);
    }
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
    final status = _gameOver
        ? 'Game over'
        : _won
        ? 'Target reached'
        : 'Playing';

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
                ToolboxMetricCard(label: 'Score', value: '$_score'),
                ToolboxMetricCard(label: 'Best tile', value: '$_bestTile'),
                ToolboxMetricCard(label: 'Target', value: '$_target'),
                ToolboxMetricCard(label: 'Status', value: status),
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
                  label: const Text('New game'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Swipe on the board to move tiles.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final boardSize = math.min(420.0, constraints.maxWidth);
                return Center(
                  child: GestureDetector(
                    onPanEnd: _handleSwipe,
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
                  child: const Text('Up'),
                ),
                FilledButton.tonal(
                  onPressed: () => _move(_SlideDirection.left),
                  child: const Text('Left'),
                ),
                FilledButton.tonal(
                  onPressed: () => _move(_SlideDirection.down),
                  child: const Text('Down'),
                ),
                FilledButton.tonal(
                  onPressed: () => _move(_SlideDirection.right),
                  child: const Text('Right'),
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

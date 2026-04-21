part of 'toolbox_mini_games.dart';

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

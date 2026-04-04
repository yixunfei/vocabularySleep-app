import 'dart:math' as math;

enum SudokuDifficulty { easy, medium, hard }

enum SudokuVariant { classic, diagonal, hyper, disjoint }

class SudokuPuzzle {
  const SudokuPuzzle({
    required this.puzzle,
    required this.solution,
    required this.difficulty,
    required this.variant,
    required this.givens,
  });

  final List<int> puzzle;
  final List<int> solution;
  final SudokuDifficulty difficulty;
  final SudokuVariant variant;
  final int givens;
}

extension SudokuDifficultyConfig on SudokuDifficulty {
  int get targetGivens => switch (this) {
    SudokuDifficulty.easy => 40,
    SudokuDifficulty.medium => 34,
    SudokuDifficulty.hard => 28,
  };
}

const Map<SudokuVariant, List<int>> _baseSolutions = <SudokuVariant, List<int>>{
  SudokuVariant.classic: <int>[
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    4,
    5,
    6,
    7,
    8,
    9,
    1,
    2,
    3,
    7,
    8,
    9,
    1,
    2,
    3,
    4,
    5,
    6,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    1,
    5,
    6,
    7,
    8,
    9,
    1,
    2,
    3,
    4,
    8,
    9,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    1,
    2,
    6,
    7,
    8,
    9,
    1,
    2,
    3,
    4,
    5,
    9,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
  ],
  SudokuVariant.diagonal: <int>[
    8,
    6,
    2,
    1,
    5,
    9,
    7,
    3,
    4,
    1,
    9,
    3,
    7,
    8,
    4,
    2,
    6,
    5,
    5,
    7,
    4,
    3,
    6,
    2,
    8,
    1,
    9,
    9,
    5,
    1,
    6,
    2,
    3,
    4,
    8,
    7,
    4,
    3,
    6,
    9,
    7,
    8,
    1,
    5,
    2,
    7,
    2,
    8,
    5,
    4,
    1,
    3,
    9,
    6,
    6,
    8,
    9,
    2,
    3,
    7,
    5,
    4,
    1,
    3,
    1,
    7,
    4,
    9,
    5,
    6,
    2,
    8,
    2,
    4,
    5,
    8,
    1,
    6,
    9,
    7,
    3,
  ],
  SudokuVariant.hyper: <int>[
    6,
    4,
    5,
    3,
    9,
    7,
    1,
    2,
    8,
    3,
    2,
    8,
    6,
    4,
    1,
    7,
    9,
    5,
    1,
    7,
    9,
    5,
    2,
    8,
    3,
    4,
    6,
    8,
    3,
    4,
    1,
    7,
    2,
    5,
    6,
    9,
    2,
    9,
    1,
    8,
    5,
    6,
    4,
    3,
    7,
    7,
    5,
    6,
    9,
    3,
    4,
    8,
    1,
    2,
    9,
    1,
    2,
    7,
    8,
    3,
    6,
    5,
    4,
    5,
    8,
    3,
    4,
    6,
    9,
    2,
    7,
    1,
    4,
    6,
    7,
    2,
    1,
    5,
    9,
    8,
    3,
  ],
  SudokuVariant.disjoint: <int>[
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    4,
    5,
    6,
    7,
    8,
    9,
    1,
    2,
    3,
    7,
    8,
    9,
    1,
    2,
    3,
    4,
    5,
    6,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    1,
    5,
    6,
    7,
    8,
    9,
    1,
    2,
    3,
    4,
    8,
    9,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    1,
    2,
    6,
    7,
    8,
    9,
    1,
    2,
    3,
    4,
    5,
    9,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
  ],
};

final Map<SudokuVariant, List<List<int>>> _constraintGroups =
    <SudokuVariant, List<List<int>>>{
      for (final variant in SudokuVariant.values)
        variant: _buildConstraintGroups(variant),
    };

final Map<SudokuVariant, List<List<int>>> _cellGroupIndexes =
    <SudokuVariant, List<List<int>>>{
      for (final variant in SudokuVariant.values)
        variant: _buildCellGroupIndexes(variant),
    };

final Map<SudokuVariant, List<Set<int>>> _peerCache =
    <SudokuVariant, List<Set<int>>>{
      for (final variant in SudokuVariant.values)
        variant: _buildPeerCache(variant),
    };

SudokuPuzzle generateSudokuPuzzle({
  required SudokuVariant variant,
  required SudokuDifficulty difficulty,
  math.Random? random,
}) {
  final rng = random ?? math.Random();
  final solution = _shuffleSolvedBoard(_baseSolutions[variant]!, rng);
  final puzzle = List<int>.from(solution);
  var givens = puzzle.length;

  var progress = true;
  while (givens > difficulty.targetGivens && progress) {
    progress = false;
    final candidates = <int>[
      for (var i = 0; i < puzzle.length; i += 1)
        if (puzzle[i] != 0) i,
    ]..shuffle(rng);
    for (final index in candidates) {
      if (givens <= difficulty.targetGivens) {
        break;
      }
      final backup = puzzle[index];
      puzzle[index] = 0;
      if (countSudokuSolutions(puzzle, variant, solutionLimit: 2) != 1) {
        puzzle[index] = backup;
        continue;
      }
      givens -= 1;
      progress = true;
    }
  }

  return SudokuPuzzle(
    puzzle: puzzle,
    solution: solution,
    difficulty: difficulty,
    variant: variant,
    givens: givens,
  );
}

Set<int> sudokuConflicts(List<int> board, SudokuVariant variant) {
  final conflicts = <int>{};
  for (final group in _constraintGroups[variant]!) {
    final seen = <int, int>{};
    for (final index in group) {
      final value = board[index];
      if (value == 0) {
        continue;
      }
      final previous = seen[value];
      if (previous == null) {
        seen[value] = index;
        continue;
      }
      conflicts.add(previous);
      conflicts.add(index);
    }
  }
  return conflicts;
}

Map<int, Set<int>> buildSudokuCandidateMap(
  List<int> board,
  SudokuVariant variant,
) {
  return <int, Set<int>>{
    for (var index = 0; index < board.length; index += 1)
      if (board[index] == 0) index: sudokuCandidates(board, index, variant),
  };
}

Set<int> sudokuCandidates(List<int> board, int index, SudokuVariant variant) {
  if (board[index] != 0) {
    return const <int>{};
  }
  final blocked = List<bool>.filled(10, false);
  for (final peer in _peerCache[variant]![index]) {
    final value = board[peer];
    if (value != 0) {
      blocked[value] = true;
    }
  }
  return <int>{
    for (var value = 1; value <= 9; value += 1)
      if (!blocked[value]) value,
  };
}

Set<int> sudokuHighlightZone(int index, SudokuVariant variant) {
  final zone = <int>{};
  final groups = _constraintGroups[variant]!;
  for (final groupIndex in _cellGroupIndexes[variant]![index]) {
    zone.addAll(groups[groupIndex]);
  }
  return zone;
}

Set<int> sudokuPeerIndices(int index, SudokuVariant variant) {
  return <int>{..._peerCache[variant]![index]};
}

int countSudokuSolutions(
  List<int> board,
  SudokuVariant variant, {
  int solutionLimit = 2,
}) {
  final working = List<int>.from(board);
  return _searchSudoku(
    working,
    variant,
    solutionLimit: solutionLimit,
    stopAtFirst: false,
  );
}

bool sudokuIsSolved(
  List<int> board,
  List<int> solution,
  SudokuVariant variant,
) {
  if (sudokuConflicts(board, variant).isNotEmpty) {
    return false;
  }
  for (var index = 0; index < board.length; index += 1) {
    if (board[index] != solution[index]) {
      return false;
    }
  }
  return true;
}

List<List<int>> _buildConstraintGroups(SudokuVariant variant) {
  final groups = <List<int>>[];
  for (var row = 0; row < 9; row += 1) {
    groups.add(List<int>.generate(9, (col) => row * 9 + col));
  }
  for (var col = 0; col < 9; col += 1) {
    groups.add(List<int>.generate(9, (row) => row * 9 + col));
  }
  for (var boxRow = 0; boxRow < 3; boxRow += 1) {
    for (var boxCol = 0; boxCol < 3; boxCol += 1) {
      groups.add(<int>[
        for (var row = 0; row < 3; row += 1)
          for (var col = 0; col < 3; col += 1)
            (boxRow * 3 + row) * 9 + (boxCol * 3 + col),
      ]);
    }
  }
  if (variant == SudokuVariant.diagonal) {
    groups.add(List<int>.generate(9, (index) => index * 10));
    groups.add(List<int>.generate(9, (index) => (index + 1) * 8));
  }
  if (variant == SudokuVariant.hyper) {
    for (final anchor in const <(int, int)>[(1, 1), (1, 5), (5, 1), (5, 5)]) {
      groups.add(<int>[
        for (var row = anchor.$1; row < anchor.$1 + 3; row += 1)
          for (var col = anchor.$2; col < anchor.$2 + 3; col += 1)
            row * 9 + col,
      ]);
    }
  }
  if (variant == SudokuVariant.disjoint) {
    // Disjoint groups: same relative cell across all nine 3x3 boxes.
    for (var localRow = 0; localRow < 3; localRow += 1) {
      for (var localCol = 0; localCol < 3; localCol += 1) {
        groups.add(<int>[
          for (var boxRow = 0; boxRow < 3; boxRow += 1)
            for (var boxCol = 0; boxCol < 3; boxCol += 1)
              (boxRow * 3 + localRow) * 9 + (boxCol * 3 + localCol),
        ]);
      }
    }
  }
  return groups;
}

List<List<int>> _buildCellGroupIndexes(SudokuVariant variant) {
  final groups = _constraintGroups[variant]!;
  return List<List<int>>.generate(81, (index) {
    final related = <int>[];
    for (var groupIndex = 0; groupIndex < groups.length; groupIndex += 1) {
      if (groups[groupIndex].contains(index)) {
        related.add(groupIndex);
      }
    }
    return related;
  });
}

List<Set<int>> _buildPeerCache(SudokuVariant variant) {
  final groups = _constraintGroups[variant]!;
  return List<Set<int>>.generate(81, (index) {
    final peers = <int>{};
    for (final groupIndex in _cellGroupIndexes[variant]![index]) {
      peers.addAll(groups[groupIndex]);
    }
    peers.remove(index);
    return peers;
  });
}

List<int> _shuffleSolvedBoard(List<int> base, math.Random random) {
  var board = List<int>.from(base);
  final remap = List<int>.generate(9, (index) => index + 1)..shuffle(random);

  board = <int>[for (final value in board) remap[value - 1]];

  final rotationCount = random.nextInt(4);
  for (var step = 0; step < rotationCount; step += 1) {
    board = _rotateBoard(board);
  }
  if (random.nextBool()) {
    board = _transposeBoard(board);
  }
  if (random.nextBool()) {
    board = _mirrorRows(board);
  }
  if (random.nextBool()) {
    board = _mirrorColumns(board);
  }
  return board;
}

List<int> _rotateBoard(List<int> board) {
  final rotated = List<int>.filled(81, 0);
  for (var row = 0; row < 9; row += 1) {
    for (var col = 0; col < 9; col += 1) {
      rotated[col * 9 + (8 - row)] = board[row * 9 + col];
    }
  }
  return rotated;
}

List<int> _transposeBoard(List<int> board) {
  final transposed = List<int>.filled(81, 0);
  for (var row = 0; row < 9; row += 1) {
    for (var col = 0; col < 9; col += 1) {
      transposed[col * 9 + row] = board[row * 9 + col];
    }
  }
  return transposed;
}

List<int> _mirrorRows(List<int> board) {
  final mirrored = List<int>.filled(81, 0);
  for (var row = 0; row < 9; row += 1) {
    for (var col = 0; col < 9; col += 1) {
      mirrored[(8 - row) * 9 + col] = board[row * 9 + col];
    }
  }
  return mirrored;
}

List<int> _mirrorColumns(List<int> board) {
  final mirrored = List<int>.filled(81, 0);
  for (var row = 0; row < 9; row += 1) {
    for (var col = 0; col < 9; col += 1) {
      mirrored[row * 9 + (8 - col)] = board[row * 9 + col];
    }
  }
  return mirrored;
}

int _searchSudoku(
  List<int> board,
  SudokuVariant variant, {
  required int solutionLimit,
  required bool stopAtFirst,
}) {
  final peers = _peerCache[variant]!;

  List<int>? candidateValues(int index) {
    if (board[index] != 0) {
      return null;
    }
    final blocked = List<bool>.filled(10, false);
    for (final peer in peers[index]) {
      final value = board[peer];
      if (value != 0) {
        blocked[value] = true;
      }
    }
    final options = <int>[
      for (var value = 1; value <= 9; value += 1)
        if (!blocked[value]) value,
    ];
    return options;
  }

  int backtrack() {
    var targetIndex = -1;
    List<int>? bestOptions;

    for (var index = 0; index < board.length; index += 1) {
      if (board[index] != 0) {
        continue;
      }
      final options = candidateValues(index)!;
      if (options.isEmpty) {
        return 0;
      }
      if (bestOptions == null || options.length < bestOptions.length) {
        targetIndex = index;
        bestOptions = options;
        if (options.length == 1) {
          break;
        }
      }
    }

    if (targetIndex == -1) {
      return 1;
    }

    var found = 0;
    for (final value in bestOptions!) {
      board[targetIndex] = value;
      found += backtrack();
      board[targetIndex] = 0;
      if (found >= solutionLimit || (stopAtFirst && found > 0)) {
        break;
      }
    }
    return found;
  }

  return backtrack();
}

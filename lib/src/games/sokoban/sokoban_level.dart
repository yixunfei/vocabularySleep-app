enum SokobanDirection { up, down, left, right }

extension SokobanDirectionGeometry on SokobanDirection {
  int get rowDelta => switch (this) {
    SokobanDirection.up => -1,
    SokobanDirection.down => 1,
    SokobanDirection.left => 0,
    SokobanDirection.right => 0,
  };

  int get columnDelta => switch (this) {
    SokobanDirection.up => 0,
    SokobanDirection.down => 0,
    SokobanDirection.left => -1,
    SokobanDirection.right => 1,
  };

  SokobanDirection get opposite => switch (this) {
    SokobanDirection.up => SokobanDirection.down,
    SokobanDirection.down => SokobanDirection.up,
    SokobanDirection.left => SokobanDirection.right,
    SokobanDirection.right => SokobanDirection.left,
  };

  String get symbol => switch (this) {
    SokobanDirection.up => 'u',
    SokobanDirection.down => 'd',
    SokobanDirection.left => 'l',
    SokobanDirection.right => 'r',
  };
}

/// The three supported box-count presets intentionally describe play style,
/// not just the number of boxes. Higher presets also add more walls and push
/// decisions so a new level is meaningfully harder.
enum SokobanDifficulty {
  single(
    boxes: 1,
    minPushes: 10,
    targetPushes: 15,
    maxPushes: 22,
    wallBudget: 8,
    minTurns: 3,
  ),
  double(
    boxes: 2,
    minPushes: 20,
    targetPushes: 28,
    maxPushes: 38,
    wallBudget: 13,
    minTurns: 6,
  ),
  triple(
    boxes: 3,
    minPushes: 32,
    targetPushes: 43,
    maxPushes: 56,
    wallBudget: 18,
    minTurns: 9,
  );

  const SokobanDifficulty({
    required this.boxes,
    required this.minPushes,
    required this.targetPushes,
    required this.maxPushes,
    required this.wallBudget,
    required this.minTurns,
  });

  final int boxes;
  final int minPushes;
  final int targetPushes;
  final int maxPushes;
  final int wallBudget;
  final int minTurns;
}

/// One push in the precomputed solution. Walking between pushes is left to
/// the player, which keeps the hint readable and preserves normal Sokoban play.
class SokobanPush {
  const SokobanPush({
    required this.boxId,
    required this.from,
    required this.to,
    required this.direction,
  });

  final int boxId;
  final int from;
  final int to;
  final SokobanDirection direction;
}

/// An immutable, validated-at-generation board description.
class SokobanLevel {
  SokobanLevel({
    required this.rows,
    required this.columns,
    required Set<int> walls,
    required this.playerStart,
    required List<int> boxStarts,
    required List<int> goals,
    required List<SokobanPush> solution,
    required this.seed,
  }) : walls = Set<int>.unmodifiable(walls),
       boxStarts = List<int>.unmodifiable(boxStarts),
       goals = List<int>.unmodifiable(goals),
       solution = List<SokobanPush>.unmodifiable(solution);

  final int rows;
  final int columns;
  final Set<int> walls;
  final int playerStart;
  final List<int> boxStarts;
  final List<int> goals;
  final List<SokobanPush> solution;
  final int seed;

  /// Number of pushes in the generated reference solution.
  ///
  /// The generator deliberately optimizes for a varied, replayable route, so
  /// this is not a proof of mathematical optimality. Keep the legacy getter
  /// below for callers that already use the old name.
  int get solutionPushes => solution.length;

  int get optimalPushes => solutionPushes;

  bool isInside(int index) {
    final row = index ~/ columns;
    final column = index % columns;
    return row >= 0 && row < rows && column >= 0 && column < columns;
  }

  bool isGoal(int index) => goals.contains(index);

  bool isWall(int index) => walls.contains(index);

  bool isSolved(Iterable<int> boxes) {
    final boxSet = boxes.toSet();
    return boxSet.length == goals.length && goals.every(boxSet.contains);
  }

  /// A compact identity used to keep the visible level sequence varied.
  String get signature {
    String sorted(Iterable<int> values) {
      final result = values.toList(growable: false)..sort();
      return result.join('.');
    }

    final route = solution.map(
      (push) => '${push.boxId}${push.direction.symbol}',
    );
    return '${rows}x$columns/$playerStart/${sorted(walls)}/'
        '${sorted(boxStarts)}/${sorted(goals)}/${route.join()}';
  }
}

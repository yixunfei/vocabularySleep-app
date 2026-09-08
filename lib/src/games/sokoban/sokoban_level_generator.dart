import 'dart:isolate';
import 'dart:math' as math;

import 'sokoban_level.dart';

/// Generates Sokoban boards with a fixed amount of work.
///
/// A board starts in its solved state and boxes are pulled away from their
/// goals. Reversing those pulls gives a real solution, so generation never
/// needs an unbounded "try until a solver happens to find a route" loop.
class SokobanLevelGenerator {
  const SokobanLevelGenerator({this.rows = 10, this.columns = 10});

  static const int _maxBoardAttempts = 14;
  static const int _maxWallAttempts = 90;
  static const int _maxGoalAttempts = 48;

  final int rows;
  final int columns;

  SokobanLevel generate({
    required SokobanDifficulty difficulty,
    required int seed,
    Set<String> excludedSignatures = const <String>{},
  }) {
    final normalizedSeed = seed & 0x7fffffff;
    SokobanLevel? best;
    var bestScore = -1;

    for (var attempt = 0; attempt < _maxBoardAttempts; attempt += 1) {
      final attemptSeed = _mixSeed(normalizedSeed, attempt + 1);
      final candidate = _buildCandidate(
        difficulty: difficulty,
        seed: attemptSeed,
        random: math.Random(attemptSeed),
      );
      if (candidate == null ||
          excludedSignatures.contains(candidate.signature)) {
        continue;
      }
      final score = _qualityScore(candidate, difficulty);
      if (score > bestScore) {
        best = candidate;
        bestScore = score;
      }
      if (candidate.solutionPushes >= difficulty.targetPushes && attempt >= 2) {
        return candidate;
      }
    }

    if (best != null) {
      return best;
    }
    // A final open-board pass keeps the safety fallback playable even when a
    // particular wall recipe is unusually constrained. It is still bounded.
    for (var attempt = 0; attempt < 8; attempt += 1) {
      final attemptSeed = _mixSeed(normalizedSeed, 100 + attempt);
      final candidate = _buildCandidate(
        difficulty: difficulty,
        seed: attemptSeed,
        random: math.Random(attemptSeed),
        openBoard: true,
      );
      if (candidate != null) {
        return candidate;
      }
    }
    return _fallbackLevel(difficulty, normalizedSeed);
  }

  SokobanLevel? _buildCandidate({
    required SokobanDifficulty difficulty,
    required int seed,
    required math.Random random,
    bool openBoard = false,
  }) {
    final walls = _buildWalls(difficulty, random, openBoard: openBoard);
    final floor = _floorCells(walls);
    if (floor.length < difficulty.boxes * 8) {
      return null;
    }

    final goals = _chooseGoals(floor, walls, difficulty, random);
    if (goals == null) {
      return null;
    }

    final boxes = List<int>.of(goals);
    final player = _choosePlayer(floor, boxes, walls, random);
    if (player == null) {
      return null;
    }

    final reversePlan = _buildReversePlan(
      difficulty: difficulty,
      goals: goals,
      boxes: boxes,
      player: player,
      walls: walls,
      random: random,
    );
    if (reversePlan == null) {
      return null;
    }
    final solution = _buildSolution(reversePlan.pulls);
    if (!_meetsDifficulty(solution, reversePlan.pulls, difficulty)) {
      return null;
    }

    final level = SokobanLevel(
      rows: rows,
      columns: columns,
      walls: walls,
      playerStart: reversePlan.playerStart,
      boxStarts: reversePlan.boxStarts,
      goals: goals,
      solution: solution,
      seed: seed,
    );
    if (!_validateSolution(level)) {
      return null;
    }
    return _decorateWalls(level, difficulty, random);
  }

  _ReversePlan? _buildReversePlan({
    required SokobanDifficulty difficulty,
    required List<int> goals,
    required List<int> boxes,
    required int player,
    required Set<int> walls,
    required math.Random random,
  }) {
    final boxHistory = <Set<int>>[
      for (final box in boxes) <int>{box},
    ];
    final pulls = <_ReversePull>[];
    var currentPlayer = player;
    int? lastBox;
    SokobanDirection? lastDirection;
    final targetPushes = math.min(
      difficulty.maxPushes,
      difficulty.targetPushes + random.nextInt(5) - 2,
    );

    for (var step = 0; step < targetPushes; step += 1) {
      final candidates = _reverseCandidates(
        boxes: boxes,
        goals: goals,
        walls: walls,
        boxHistory: boxHistory,
        currentPlayer: currentPlayer,
        lastBox: lastBox,
        lastDirection: lastDirection,
        random: random,
      );
      if (candidates.isEmpty) {
        break;
      }
      final selected = _selectReverseCandidate(candidates, random);
      final from = boxes[selected.boxId];
      boxes[selected.boxId] = selected.target;
      boxHistory[selected.boxId].add(selected.target);
      currentPlayer = selected.beyond;
      pulls.add(
        _ReversePull(
          boxId: selected.boxId,
          from: from,
          to: selected.target,
          direction: selected.direction,
        ),
      );
      lastBox = selected.boxId;
      lastDirection = selected.direction;
    }

    return _ReversePlan(
      playerStart: currentPlayer,
      boxStarts: List<int>.of(boxes, growable: false),
      pulls: List<_ReversePull>.of(pulls, growable: false),
    );
  }

  List<_ReverseCandidate> _reverseCandidates({
    required List<int> boxes,
    required List<int> goals,
    required Set<int> walls,
    required List<Set<int>> boxHistory,
    required int currentPlayer,
    required int? lastBox,
    required SokobanDirection? lastDirection,
    required math.Random random,
  }) {
    final reachable = _reachableCells(currentPlayer, boxes, walls);
    final candidates = <_ReverseCandidate>[];
    for (var boxId = 0; boxId < boxes.length; boxId += 1) {
      final box = boxes[boxId];
      for (final direction in SokobanDirection.values) {
        final target = _step(box, direction);
        final beyond = _step(target, direction);
        if (!_reversePullAllowed(
          boxId: boxId,
          target: target,
          beyond: beyond,
          direction: direction,
          boxes: boxes,
          goals: goals,
          walls: walls,
          boxHistory: boxHistory,
          reachable: reachable,
          lastBox: lastBox,
          lastDirection: lastDirection,
        )) {
          continue;
        }
        candidates.add(
          _ReverseCandidate(
            boxId: boxId,
            direction: direction,
            target: target,
            beyond: beyond,
            score: _reverseCandidateScore(
              box: box,
              target: target,
              boxId: boxId,
              direction: direction,
              goals: goals,
              boxes: boxes,
              lastBox: lastBox,
              lastDirection: lastDirection,
              random: random,
              walls: walls,
            ),
          ),
        );
      }
    }
    return candidates;
  }

  bool _reversePullAllowed({
    required int boxId,
    required int target,
    required int beyond,
    required SokobanDirection direction,
    required List<int> boxes,
    required List<int> goals,
    required Set<int> walls,
    required List<Set<int>> boxHistory,
    required List<bool> reachable,
    required int? lastBox,
    required SokobanDirection? lastDirection,
  }) {
    if (!_isFloor(target, walls) ||
        !_isFloor(beyond, walls) ||
        boxes.contains(target) ||
        boxes.contains(beyond) ||
        // A reverse pull must leave the player on the far side of the
        // destination. Checking that stance cell keeps the reversed sequence
        // physically replayable instead of relying only on a later pass.
        !reachable[beyond] ||
        boxHistory[boxId].contains(target) ||
        _isDeadlock(target, walls, boxes, goals)) {
      return false;
    }
    return lastBox != boxId || lastDirection != direction.opposite;
  }

  int _reverseCandidateScore({
    required int box,
    required int target,
    required int boxId,
    required SokobanDirection direction,
    required List<int> goals,
    required List<int> boxes,
    required int? lastBox,
    required SokobanDirection? lastDirection,
    required math.Random random,
    required Set<int> walls,
  }) {
    final oldDistance = _manhattan(box, goals[boxId]);
    final newDistance = _manhattan(target, goals[boxId]);
    var score = (newDistance - oldDistance) * 9;
    score += _floorDegree(target, walls) * 2;
    score += _nearbyBoxScore(target, boxes, boxId);
    score += random.nextInt(13);
    if (newDistance < oldDistance) {
      score -= 14;
    }
    if (lastBox == boxId) {
      score -= 3;
    }
    if (lastDirection != null && direction != lastDirection) {
      score += 4;
    }
    return score;
  }

  _ReverseCandidate _selectReverseCandidate(
    List<_ReverseCandidate> candidates,
    math.Random random,
  ) {
    candidates.sort((a, b) => b.score.compareTo(a.score));
    final poolSize = math.min(5, candidates.length);
    return candidates[random.nextInt(poolSize)];
  }

  List<SokobanPush> _buildSolution(List<_ReversePull> pulls) {
    return <SokobanPush>[
      for (var index = pulls.length - 1; index >= 0; index -= 1)
        _inversePush(pulls[index]),
    ];
  }

  bool _meetsDifficulty(
    List<SokobanPush> solution,
    List<_ReversePull> pulls,
    SokobanDifficulty difficulty,
  ) {
    return pulls.length >= difficulty.minPushes &&
        _everyBoxMovedEnough(pulls, difficulty) &&
        _countTurns(solution) >= difficulty.minTurns;
  }

  Set<int> _buildWalls(
    SokobanDifficulty difficulty,
    math.Random random, {
    bool openBoard = false,
  }) {
    final walls = _boundaryWalls();

    final boundaryCount = walls.length;
    // Keep the reverse-pull phase spacious. Additional walls are decorated
    // only after a valid solution exists, so density can never cause a long
    // search or invalidate every candidate.
    final target = openBoard ? 0 : math.max(0, difficulty.wallBudget ~/ 4);
    var attempts = 0;
    while (walls.length - boundaryCount < target &&
        attempts < _maxWallAttempts) {
      attempts += 1;
      final horizontal = random.nextBool();
      final anchorRow = 2 + random.nextInt(math.max(1, rows - 4));
      final anchorColumn = 2 + random.nextInt(math.max(1, columns - 4));
      final length = 2 + random.nextInt(3);
      final gap = random.nextInt(length);
      final proposal = <int>{};
      for (var offset = 0; offset < length; offset += 1) {
        if (offset == gap) {
          continue;
        }
        final row = horizontal ? anchorRow : anchorRow + offset;
        final column = horizontal ? anchorColumn + offset : anchorColumn;
        if (row > 0 && row < rows - 1 && column > 0 && column < columns - 1) {
          proposal.add(_index(row, column));
        }
      }
      if (proposal.isEmpty || proposal.any(walls.contains)) {
        continue;
      }
      final trial = <int>{...walls, ...proposal};
      if (_floorIsConnected(trial)) {
        walls.addAll(proposal);
      }
    }
    return walls;
  }

  SokobanLevel _decorateWalls(
    SokobanLevel level,
    SokobanDifficulty difficulty,
    math.Random random,
  ) {
    final protected = <int>{
      level.playerStart,
      ...level.boxStarts,
      ...level.goals,
    };
    for (final push in level.solution) {
      protected
        ..add(push.from)
        ..add(push.to)
        ..add(_step(push.from, push.direction.opposite));
    }

    final candidates =
        <int>[
            for (var row = 1; row < rows - 1; row += 1)
              for (var column = 1; column < columns - 1; column += 1)
                _index(row, column),
          ]
          ..removeWhere(
            (cell) => level.walls.contains(cell) || protected.contains(cell),
          )
          ..shuffle(random);
    // Cells close to the solution create useful bottlenecks. Keep a small
    // random component so equal seeds do not collapse into one wall pattern.
    final candidateScores = <int, int>{
      for (final cell in candidates)
        cell: _routeAdjacencyScore(cell, protected) + random.nextInt(4),
    };
    candidates.sort(
      (first, second) =>
          candidateScores[second]!.compareTo(candidateScores[first]!),
    );

    final walls = <int>{...level.walls};
    var interiorWalls = walls.length - _boundaryCount;
    for (final candidate in candidates) {
      if (interiorWalls >= difficulty.wallBudget) {
        break;
      }
      final trialWalls = <int>{...walls, candidate};
      if (!_floorIsConnected(trialWalls)) {
        continue;
      }
      final trialLevel = _levelWithWalls(level, trialWalls);
      if (!_validateSolution(trialLevel)) {
        continue;
      }
      walls.add(candidate);
      interiorWalls += 1;
    }
    return _levelWithWalls(level, walls);
  }

  SokobanLevel _levelWithWalls(SokobanLevel level, Set<int> walls) {
    return SokobanLevel(
      rows: level.rows,
      columns: level.columns,
      walls: walls,
      playerStart: level.playerStart,
      boxStarts: level.boxStarts,
      goals: level.goals,
      solution: level.solution,
      seed: level.seed,
    );
  }

  int _routeAdjacencyScore(int cell, Set<int> protected) {
    var score = 0;
    for (final direction in SokobanDirection.values) {
      if (protected.contains(_step(cell, direction))) {
        score += 1;
      }
    }
    return score;
  }

  List<int>? _chooseGoals(
    List<int> floor,
    Set<int> walls,
    SokobanDifficulty difficulty,
    math.Random random,
  ) {
    final candidates = floor
        .where((cell) => _floorDegree(cell, walls) >= 2)
        .toList(growable: false);
    if (candidates.length < difficulty.boxes) {
      return null;
    }

    for (var attempt = 0; attempt < _maxGoalAttempts; attempt += 1) {
      final shuffled = List<int>.of(candidates)..shuffle(random);
      final selected = <int>[];
      for (final candidate in shuffled) {
        if (selected.every((other) => _manhattan(candidate, other) >= 3)) {
          selected.add(candidate);
        }
        if (selected.length == difficulty.boxes) {
          return selected;
        }
      }
    }

    final fallback = <int>[];
    for (final candidate in candidates) {
      if (fallback.every((other) => _manhattan(candidate, other) >= 2)) {
        fallback.add(candidate);
      }
      if (fallback.length == difficulty.boxes) {
        return fallback;
      }
    }
    return null;
  }

  int? _choosePlayer(
    List<int> floor,
    List<int> boxes,
    Set<int> walls,
    math.Random random,
  ) {
    final candidates = floor.where((cell) => !boxes.contains(cell)).toList();
    if (candidates.isEmpty) {
      return null;
    }
    candidates.shuffle(random);
    final sampleCount = math.min(24, candidates.length);
    var best = candidates.first;
    var bestReachable = -1;
    for (var index = 0; index < sampleCount; index += 1) {
      final candidate = candidates[index];
      final reachable = _reachableCells(candidate, boxes, walls);
      final count = reachable.where((value) => value).length;
      if (count > bestReachable) {
        best = candidate;
        bestReachable = count;
      }
    }
    return best;
  }

  SokobanPush _inversePush(_ReversePull pull) {
    return SokobanPush(
      boxId: pull.boxId,
      from: pull.to,
      to: pull.from,
      direction: pull.direction.opposite,
    );
  }

  bool _everyBoxMovedEnough(
    List<_ReversePull> pulls,
    SokobanDifficulty difficulty,
  ) {
    final counts = List<int>.filled(difficulty.boxes, 0);
    for (final pull in pulls) {
      counts[pull.boxId] += 1;
    }
    final minimum = math.max(2, difficulty.minPushes ~/ difficulty.boxes ~/ 2);
    return counts.every((count) => count >= minimum);
  }

  bool _validateSolution(SokobanLevel level) {
    var player = level.playerStart;
    final boxes = List<int>.of(level.boxStarts);
    for (final push in level.solution) {
      if (push.boxId < 0 ||
          push.boxId >= boxes.length ||
          boxes[push.boxId] != push.from ||
          push.to != _step(push.from, push.direction)) {
        return false;
      }
      final behind = _step(push.from, push.direction.opposite);
      if (!_isFloor(behind, level.walls) ||
          !_isFloor(push.to, level.walls) ||
          _boxOccupiesTarget(boxes, push.boxId, push.to)) {
        return false;
      }
      final reachable = _reachableCells(player, boxes, level.walls);
      if (!reachable[behind]) {
        return false;
      }
      boxes[push.boxId] = push.to;
      player = push.from;
    }
    return level.isSolved(boxes);
  }

  bool _boxOccupiesTarget(List<int> boxes, int movingBoxId, int target) {
    for (var index = 0; index < boxes.length; index += 1) {
      if (index != movingBoxId && boxes[index] == target) {
        return true;
      }
    }
    return false;
  }

  int _qualityScore(SokobanLevel level, SokobanDifficulty difficulty) {
    final turns = _countTurns(level.solution);
    var interactions = 0;
    for (final push in level.solution) {
      if (level.solution.any(
        (other) =>
            other.boxId != push.boxId && _manhattan(other.from, push.from) <= 2,
      )) {
        interactions += 1;
      }
    }
    final wallCount = level.walls.length - _boundaryCount;
    final targetBonus = level.solutionPushes >= difficulty.targetPushes
        ? 20
        : 0;
    return level.solutionPushes * 4 +
        turns * 3 +
        interactions * 2 +
        wallCount +
        targetBonus;
  }

  int _countTurns(List<SokobanPush> solution) {
    var turns = 0;
    SokobanDirection? previous;
    for (final push in solution) {
      if (previous != null && previous != push.direction) {
        turns += 1;
      }
      previous = push.direction;
    }
    return turns;
  }

  SokobanLevel _fallbackLevel(SokobanDifficulty difficulty, int seed) {
    final walls = _boundaryWalls();
    final floor = _floorCells(walls);
    final random = math.Random(seed);
    final paths = _selectFallbackPaths(
      _fallbackPathCandidates(floor, walls, random),
      difficulty.boxes,
    );
    if (paths != null) {
      final level = _validatedFallbackLevel(
        paths: paths,
        floor: floor,
        walls: walls,
        seed: seed,
        random: random,
      );
      if (level != null) {
        return level;
      }
    }

    return _solvedFallbackLevel(
      difficulty: difficulty,
      floor: floor,
      walls: walls,
      seed: seed,
    );
  }

  List<int> _floorCells(Set<int> walls) {
    return <int>[
      for (var index = 0; index < rows * columns; index += 1)
        if (_isFloor(index, walls)) index,
    ];
  }

  List<_FallbackPath> _fallbackPathCandidates(
    List<int> floor,
    Set<int> walls,
    math.Random random,
  ) {
    final candidates = <_FallbackPath>[];
    for (final goal in floor) {
      for (final direction in SokobanDirection.values) {
        final middle = _step(goal, direction.opposite);
        final start = _step(middle, direction.opposite);
        final behind = _step(start, direction.opposite);
        final reserved = <int>{goal, middle, start, behind};
        if (reserved.length != 4 ||
            reserved.any((cell) => !_isFloor(cell, walls))) {
          continue;
        }
        candidates.add(
          _FallbackPath(
            start: start,
            middle: middle,
            goal: goal,
            direction: direction,
            reserved: reserved,
          ),
        );
      }
    }
    candidates.shuffle(random);
    return candidates;
  }

  List<_FallbackPath>? _selectFallbackPaths(
    List<_FallbackPath> candidates,
    int boxCount,
  ) {
    final selected = <_FallbackPath>[];
    final used = <int>{};
    var combinations = 0;
    bool select(int boxId) {
      if (boxId == boxCount) {
        return true;
      }
      for (final candidate in candidates) {
        combinations += 1;
        if (combinations > 512 || candidate.reserved.any(used.contains)) {
          continue;
        }
        selected.add(candidate);
        used.addAll(candidate.reserved);
        if (select(boxId + 1)) {
          return true;
        }
        used.removeAll(candidate.reserved);
        selected.removeLast();
      }
      return false;
    }

    return select(0) ? List<_FallbackPath>.of(selected) : null;
  }

  SokobanLevel? _validatedFallbackLevel({
    required List<_FallbackPath> paths,
    required List<int> floor,
    required Set<int> walls,
    required int seed,
    required math.Random random,
  }) {
    final boxes = <int>[for (final path in paths) path.start];
    final goals = <int>[for (final path in paths) path.goal];
    final solution = <SokobanPush>[
      for (var boxId = 0; boxId < paths.length; boxId += 1) ...[
        SokobanPush(
          boxId: boxId,
          from: paths[boxId].start,
          to: paths[boxId].middle,
          direction: paths[boxId].direction,
        ),
        SokobanPush(
          boxId: boxId,
          from: paths[boxId].middle,
          to: paths[boxId].goal,
          direction: paths[boxId].direction,
        ),
      ],
    ];
    final playerCandidates = List<int>.of(floor)
      ..removeWhere(boxes.contains)
      ..shuffle(random);
    for (final player in playerCandidates) {
      final level = SokobanLevel(
        rows: rows,
        columns: columns,
        walls: walls,
        playerStart: player,
        boxStarts: boxes,
        goals: goals,
        solution: solution,
        seed: seed,
      );
      if (_validateSolution(level)) {
        return level;
      }
    }
    return null;
  }

  SokobanLevel _solvedFallbackLevel({
    required SokobanDifficulty difficulty,
    required List<int> floor,
    required Set<int> walls,
    required int seed,
  }) {
    // If the board is too small for a two-push lane, return a valid solved
    // position rather than coordinates that point into a wall. Normal app
    // boards never reach this branch, but it keeps the public generator safe
    // for constrained previews and tests.
    if (floor.isEmpty) {
      return SokobanLevel(
        rows: rows,
        columns: columns,
        walls: walls,
        playerStart: 0,
        boxStarts: const <int>[],
        goals: const <int>[],
        solution: const <SokobanPush>[],
        seed: seed,
      );
    }
    // Keep one floor cell for the player whenever possible. On a one-cell
    // preview board, an empty solved layout is safer than drawing a player
    // and a box on top of each other.
    final boxCount = math.min(difficulty.boxes, math.max(0, floor.length - 1));
    final boxes = floor.take(boxCount).toList(growable: false);
    final player = floor.firstWhere((cell) => !boxes.contains(cell));
    return SokobanLevel(
      rows: rows,
      columns: columns,
      walls: walls,
      playerStart: player,
      boxStarts: boxes,
      goals: boxes,
      solution: const <SokobanPush>[],
      seed: seed,
    );
  }

  Set<int> _boundaryWalls() {
    final walls = <int>{};
    for (var row = 0; row < rows; row += 1) {
      for (var column = 0; column < columns; column += 1) {
        if (row == 0 ||
            column == 0 ||
            row == rows - 1 ||
            column == columns - 1) {
          walls.add(_index(row, column));
        }
      }
    }
    return walls;
  }

  int get _boundaryCount => rows * 2 + columns * 2 - 4;

  int _nearbyBoxScore(int cell, List<int> boxes, int boxId) {
    var score = 0;
    for (var index = 0; index < boxes.length; index += 1) {
      if (index == boxId) {
        continue;
      }
      final distance = _manhattan(cell, boxes[index]);
      if (distance <= 2) {
        score += 6;
      } else if (distance <= 4) {
        score += 2;
      }
    }
    return score;
  }

  bool _isDeadlock(int cell, Set<int> walls, List<int> boxes, List<int> goals) {
    if (goals.contains(cell)) {
      return false;
    }
    final up = !_isFloor(_step(cell, SokobanDirection.up), walls);
    final down = !_isFloor(_step(cell, SokobanDirection.down), walls);
    final left = !_isFloor(_step(cell, SokobanDirection.left), walls);
    final right = !_isFloor(_step(cell, SokobanDirection.right), walls);
    if ((up || down) && (left || right)) {
      return true;
    }
    if (_floorDegree(cell, walls) <= 1) {
      return true;
    }

    final row = cell ~/ columns;
    final column = cell % columns;
    for (final rowOffset in <int>[-1, 0]) {
      for (final columnOffset in <int>[-1, 0]) {
        final block = <int>[
          _index(row + rowOffset, column + columnOffset),
          _index(row + rowOffset + 1, column + columnOffset),
          _index(row + rowOffset, column + columnOffset + 1),
          _index(row + rowOffset + 1, column + columnOffset + 1),
        ];
        if (block.every(
              (other) =>
                  !_isFloor(other, walls) ||
                  other == cell ||
                  boxes.contains(other),
            ) &&
            block.every((other) => !goals.contains(other))) {
          return true;
        }
      }
    }
    return false;
  }

  int _floorDegree(int cell, Set<int> walls) {
    var degree = 0;
    for (final direction in SokobanDirection.values) {
      if (_isFloor(_step(cell, direction), walls)) {
        degree += 1;
      }
    }
    return degree;
  }

  bool _floorIsConnected(Set<int> walls) {
    final total = rows * columns;
    var start = -1;
    for (var index = 0; index < total; index += 1) {
      if (!walls.contains(index)) {
        start = index;
        break;
      }
    }
    if (start < 0) {
      return false;
    }
    final visited = List<bool>.filled(total, false);
    final queue = List<int>.filled(total, 0);
    var head = 0;
    var tail = 0;
    queue[tail++] = start;
    visited[start] = true;
    while (head < tail) {
      final current = queue[head++];
      for (final direction in SokobanDirection.values) {
        final next = _step(current, direction);
        if (_isFloor(next, walls) && !visited[next]) {
          visited[next] = true;
          queue[tail++] = next;
        }
      }
    }
    for (var index = 0; index < total; index += 1) {
      if (!walls.contains(index) && !visited[index]) {
        return false;
      }
    }
    return true;
  }

  List<bool> _reachableCells(int start, List<int> boxes, Set<int> walls) {
    final total = rows * columns;
    final reachable = List<bool>.filled(total, false);
    if (!_isFloor(start, walls) || boxes.contains(start)) {
      return reachable;
    }
    final queue = List<int>.filled(total, 0);
    var head = 0;
    var tail = 0;
    queue[tail++] = start;
    reachable[start] = true;
    while (head < tail) {
      final current = queue[head++];
      for (final direction in SokobanDirection.values) {
        final next = _step(current, direction);
        if (_isFloor(next, walls) &&
            !boxes.contains(next) &&
            !reachable[next]) {
          reachable[next] = true;
          queue[tail++] = next;
        }
      }
    }
    return reachable;
  }

  bool _isFloor(int index, Set<int> walls) {
    if (index < 0 || index >= rows * columns) {
      return false;
    }
    final row = index ~/ columns;
    final column = index % columns;
    return row > 0 &&
        row < rows - 1 &&
        column > 0 &&
        column < columns - 1 &&
        !walls.contains(index);
  }

  int _step(int index, SokobanDirection direction) {
    final row = index ~/ columns;
    final column = index % columns;
    return _index(row + direction.rowDelta, column + direction.columnDelta);
  }

  int _index(int row, int column) => row * columns + column;

  int _manhattan(int first, int second) {
    return ((first ~/ columns) - (second ~/ columns)).abs() +
        ((first % columns) - (second % columns)).abs();
  }

  int _mixSeed(int seed, int salt) {
    var value = (seed ^ (salt * 0x45d9f3b)) & 0x7fffffff;
    value = (value ^ (value >> 16)) * 0x45d9f3b;
    value = (value ^ (value >> 16)) & 0x7fffffff;
    return value;
  }
}

/// Generates one level away from Flutter's UI isolate.
///
/// The generator itself is deterministic and contains no framework state, so
/// it is safe to run in a short-lived worker. Callers should keep a small
/// queue and discard results after the page is disposed or the mode changes.
Future<SokobanLevel> generateSokobanLevelInBackground({
  required SokobanDifficulty difficulty,
  required int seed,
  Set<String> excludedSignatures = const <String>{},
  int rows = 10,
  int columns = 10,
}) {
  final excluded = Set<String>.of(excludedSignatures);
  return Isolate.run(
    () => SokobanLevelGenerator(rows: rows, columns: columns).generate(
      difficulty: difficulty,
      seed: seed,
      excludedSignatures: excluded,
    ),
  );
}

class _ReversePull {
  const _ReversePull({
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

class _ReversePlan {
  const _ReversePlan({
    required this.playerStart,
    required this.boxStarts,
    required this.pulls,
  });

  final int playerStart;
  final List<int> boxStarts;
  final List<_ReversePull> pulls;
}

class _ReverseCandidate {
  const _ReverseCandidate({
    required this.boxId,
    required this.direction,
    required this.target,
    required this.beyond,
    required this.score,
  });

  final int boxId;
  final SokobanDirection direction;
  final int target;
  final int beyond;
  final int score;
}

class _FallbackPath {
  const _FallbackPath({
    required this.start,
    required this.middle,
    required this.goal,
    required this.direction,
    required this.reserved,
  });

  final int start;
  final int middle;
  final int goal;
  final SokobanDirection direction;
  final Set<int> reserved;
}

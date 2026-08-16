part of 'toolbox_mini_games.dart';

enum _SokobanDirection { up, down, left, right }

enum _SokobanDifficulty {
  easy(boxes: 1, minRoute: 8, maxRoute: 13, extraWalls: 8),
  medium(boxes: 2, minRoute: 10, maxRoute: 16, extraWalls: 14),
  hard(boxes: 3, minRoute: 12, maxRoute: 20, extraWalls: 20);

  const _SokobanDifficulty({
    required this.boxes,
    required this.minRoute,
    required this.maxRoute,
    required this.extraWalls,
  });

  final int boxes;
  final int minRoute;
  final int maxRoute;
  final int extraWalls;
}

class _SokobanGame extends StatefulWidget {
  const _SokobanGame();

  @override
  State<_SokobanGame> createState() => _SokobanGameState();
}

class _SokobanGameState extends State<_SokobanGame> {
  static const int _rows = 10;
  static const int _cols = 10;
  static const int _recentLevelMemory = 40;
  final math.Random _random = math.Random();
  final Queue<String> _recentLevelSignatures = Queue<String>();

  _SokobanDifficulty _difficulty = _SokobanDifficulty.easy;
  late _SokobanLevel _level;
  late int _player;
  late Set<int> _boxes;
  final List<_SokobanSnapshot> _history = <_SokobanSnapshot>[];
  int _moves = 0;
  int _pushes = 0;
  bool _won = false;
  bool _showRoute = false;

  @override
  void initState() {
    super.initState();
    _loadLevel(_generateLevel());
  }

  int _indexOf(int row, int col) => row * _cols + col;

  int _rowOf(int index) => index ~/ _cols;

  int _colOf(int index) => index % _cols;

  bool _inBounds(int index) {
    final row = _rowOf(index);
    final col = _colOf(index);
    return row >= 0 && row < _rows && col >= 0 && col < _cols;
  }

  bool _insidePlayable(int index) {
    final row = _rowOf(index);
    final col = _colOf(index);
    return row > 0 && row < _rows - 1 && col > 0 && col < _cols - 1;
  }

  int _step(int index, _SokobanDirection direction) {
    final row = _rowOf(index);
    final col = _colOf(index);
    return switch (direction) {
      _SokobanDirection.up => _indexOf(row - 1, col),
      _SokobanDirection.down => _indexOf(row + 1, col),
      _SokobanDirection.left => _indexOf(row, col - 1),
      _SokobanDirection.right => _indexOf(row, col + 1),
    };
  }

  _SokobanDirection _opposite(_SokobanDirection direction) {
    return switch (direction) {
      _SokobanDirection.up => _SokobanDirection.down,
      _SokobanDirection.down => _SokobanDirection.up,
      _SokobanDirection.left => _SokobanDirection.right,
      _SokobanDirection.right => _SokobanDirection.left,
    };
  }

  void _loadLevel(_SokobanLevel level) {
    _level = level;
    _player = level.playerStart;
    _boxes = <int>{...level.boxStarts};
    _history.clear();
    _moves = 0;
    _pushes = 0;
    _won = false;
    _showRoute = false;
  }

  void _setDifficulty(_SokobanDifficulty difficulty) {
    if (_difficulty == difficulty) {
      return;
    }
    setState(() {
      _difficulty = difficulty;
      _loadLevel(_generateLevel());
    });
  }

  void _newLevel() {
    setState(() {
      _loadLevel(_generateLevel());
    });
  }

  String _difficultyLabel(AppI18n i18n, _SokobanDifficulty difficulty) {
    return switch (difficulty) {
      _SokobanDifficulty.easy => i18n.t(
        'toolbox.miniGames.sokoban.single.b4b00fd6',
      ),
      _SokobanDifficulty.medium => i18n.t(
        'toolbox.miniGames.sokoban.double.86266b27',
      ),
      _SokobanDifficulty.hard => i18n.t(
        'toolbox.miniGames.sokoban.triple.f9908787',
      ),
    };
  }

  _SokobanLevel _generateLevel() {
    _SokobanLevel? bestLevel;
    var bestScore = -1;
    for (var attempt = 0; attempt < 420; attempt += 1) {
      final plans = <_SokobanPushPlan>[];
      final required = <int>{};
      var failed = false;
      for (var index = 0; index < _difficulty.boxes; index += 1) {
        final plan = _buildNonOverlappingPlan(required);
        if (plan == null) {
          failed = true;
          break;
        }
        plans.add(plan);
        required.addAll(plan.requiredCells);
      }
      if (failed || plans.isEmpty) {
        continue;
      }
      final walls = _buildWalls(required);
      final level = _SokobanLevel(
        walls: walls,
        playerStart: _step(
          plans.first.cells.first,
          _opposite(plans.first.directions.first),
        ),
        boxStarts: <int>{for (final plan in plans) plan.cells.first},
        goals: <int>{for (final plan in plans) plan.cells.last},
        plans: plans,
        difficultySteps: plans.fold<int>(
          0,
          (sum, plan) => sum + plan.directions.length,
        ),
      );
      if (_solutionCanPlay(level)) {
        final signature = 'exact:${_levelSignature(level)}';
        final varietySignature = 'shape:${_levelVarietySignature(level)}';
        final repeated =
            _recentLevelSignatures.contains(signature) ||
            _recentLevelSignatures.contains(varietySignature);
        if (repeated && attempt < 320) {
          continue;
        }
        final score = _levelQualityScore(level);
        if (score > bestScore) {
          bestLevel = level;
          bestScore = score;
        }
        if (score >= _qualityTargetScore && attempt >= 48) {
          _rememberLevelSignature(signature);
          _rememberLevelSignature(varietySignature);
          return level;
        }
      }
    }
    if (bestLevel != null) {
      _rememberLevelSignature('exact:${_levelSignature(bestLevel)}');
      _rememberLevelSignature('shape:${_levelVarietySignature(bestLevel)}');
      return bestLevel;
    }
    final fallback = _fallbackLevel(_difficulty);
    _rememberLevelSignature('exact:${_levelSignature(fallback)}');
    _rememberLevelSignature('shape:${_levelVarietySignature(fallback)}');
    return fallback;
  }

  _SokobanPushPlan? _buildNonOverlappingPlan(Set<int> reserved) {
    _SokobanRouteDraft? bestRoute;
    Set<int>? bestRequired;
    var bestScore = -1;
    for (var attempt = 0; attempt < 150; attempt += 1) {
      final route = _buildRoute();
      if (route == null) {
        continue;
      }
      final required = _requiredCellsForRoute(route);
      if (_routeConflictsWithReserved(required, reserved)) {
        continue;
      }
      final score = _routeQualityScore(route);
      if (score > bestScore) {
        bestRoute = route;
        bestRequired = required;
        bestScore = score;
      }
      if (score >= _routeQualityTarget && attempt >= 24) {
        return _SokobanPushPlan(
          cells: route.cells,
          directions: route.directions,
          requiredCells: required,
        );
      }
    }
    if (bestRoute == null || bestRequired == null) {
      return null;
    }
    return _SokobanPushPlan(
      cells: bestRoute.cells,
      directions: bestRoute.directions,
      requiredCells: bestRequired,
    );
  }

  bool _routeConflictsWithReserved(Set<int> required, Set<int> reserved) {
    if (reserved.isEmpty) {
      return false;
    }
    for (final cell in required) {
      if (reserved.contains(cell)) {
        return true;
      }
      for (final direction in _SokobanDirection.values) {
        if (reserved.contains(_step(cell, direction))) {
          return true;
        }
      }
    }
    return false;
  }

  int get _routeQualityTarget {
    return switch (_difficulty) {
      _SokobanDifficulty.easy => 18,
      _SokobanDifficulty.medium => 24,
      _SokobanDifficulty.hard => 30,
    };
  }

  int get _qualityTargetScore {
    return switch (_difficulty) {
      _SokobanDifficulty.easy => 30,
      _SokobanDifficulty.medium => 44,
      _SokobanDifficulty.hard => 58,
    };
  }

  int _routeQualityScore(_SokobanRouteDraft route) {
    final turns = _turnCount(route.directions);
    final longestStraight = _longestStraightRun(route.directions);
    final distance = _manhattan(route.cells.first, route.cells.last);
    final routeSlack = route.directions.length - distance;
    final centerSpread =
        (_rowOf(route.cells.first) - _rowOf(route.cells.last)).abs() +
        (_colOf(route.cells.first) - _colOf(route.cells.last)).abs();
    return route.directions.length +
        turns * 5 +
        routeSlack * 3 +
        centerSpread -
        math.max(0, longestStraight - 3) * 4;
  }

  int _levelQualityScore(_SokobanLevel level) {
    final routeScore = level.plans.fold<int>(
      0,
      (sum, plan) =>
          sum +
          _routeQualityScore(
            _SokobanRouteDraft(cells: plan.cells, directions: plan.directions),
          ),
    );
    final goalRows = level.goals.map(_rowOf).toList(growable: false);
    final goalCols = level.goals.map(_colOf).toList(growable: false);
    final spread = goalRows.isEmpty
        ? 0
        : (goalRows.reduce(math.max) - goalRows.reduce(math.min)) +
              (goalCols.reduce(math.max) - goalCols.reduce(math.min));
    final wallScore = math.min(
      18,
      level.walls.length - (_rows * 2 + _cols * 2 - 4),
    );
    return routeScore + spread * 3 + wallScore;
  }

  int _turnCount(List<_SokobanDirection> directions) {
    var turns = 0;
    for (var index = 1; index < directions.length; index += 1) {
      if (directions[index] != directions[index - 1]) {
        turns += 1;
      }
    }
    return turns;
  }

  int _longestStraightRun(List<_SokobanDirection> directions) {
    if (directions.isEmpty) {
      return 0;
    }
    var longest = 1;
    var current = 1;
    for (var index = 1; index < directions.length; index += 1) {
      if (directions[index] == directions[index - 1]) {
        current += 1;
      } else {
        longest = math.max(longest, current);
        current = 1;
      }
    }
    return math.max(longest, current);
  }

  bool _routeMeetsBaseline(_SokobanRouteDraft route) {
    final turns = _turnCount(route.directions);
    final longestStraight = _longestStraightRun(route.directions);
    final slack =
        route.directions.length -
        _manhattan(route.cells.first, route.cells.last);
    final minTurns = switch (_difficulty) {
      _SokobanDifficulty.easy => 2,
      _SokobanDifficulty.medium => 3,
      _SokobanDifficulty.hard => 4,
    };
    return turns >= minTurns &&
        slack >= minTurns - 1 &&
        longestStraight <= math.max(4, _difficulty.maxRoute ~/ 2);
  }

  String _levelVarietySignature(_SokobanLevel level) {
    String routeShape(_SokobanPushPlan plan) {
      if (plan.directions.isEmpty) {
        return 'empty';
      }
      final buffer = StringBuffer();
      var last = plan.directions.first;
      var run = 0;
      void flush() {
        buffer
          ..write(switch (last) {
            _SokobanDirection.up => 'u',
            _SokobanDirection.down => 'd',
            _SokobanDirection.left => 'l',
            _SokobanDirection.right => 'r',
          })
          ..write(math.min(run, 4));
      }

      for (final direction in plan.directions) {
        if (direction == last) {
          run += 1;
          continue;
        }
        flush();
        last = direction;
        run = 1;
      }
      flush();
      return buffer.toString();
    }

    final shapes = level.plans.map(routeShape).toList(growable: false)..sort();
    return '${_difficulty.name}:${shapes.join('|')}:${level.walls.length ~/ 4}';
  }

  _SokobanRouteDraft? _buildRoute() {
    _SokobanRouteDraft? bestRoute;
    var bestScore = -1;
    for (var attempt = 0; attempt < 190; attempt += 1) {
      final start = _randomPlayableCell();
      final goal = _randomPlayableCell();
      final directDistance = _manhattan(start, goal);
      if (start == goal ||
          directDistance < math.max(4, _difficulty.boxes + 3)) {
        continue;
      }
      final route = _findRouteBetween(start, goal);
      if (route == null) {
        continue;
      }
      final score = _routeQualityScore(route);
      if (score > bestScore) {
        bestRoute = route;
        bestScore = score;
      }
      if (_routeMeetsBaseline(route) && attempt >= 24) {
        return route;
      }
    }
    return bestRoute;
  }

  int _randomPlayableCell() {
    return _indexOf(
      1 + _random.nextInt(_rows - 2),
      1 + _random.nextInt(_cols - 2),
    );
  }

  int _manhattan(int a, int b) {
    return (_rowOf(a) - _rowOf(b)).abs() + (_colOf(a) - _colOf(b)).abs();
  }

  _SokobanRouteDraft? _findRouteBetween(int start, int goal) {
    final cells = <int>[start];
    final directions = <_SokobanDirection>[];
    final visited = <int>{start};

    bool search(int current) {
      if (current == goal && directions.length >= _difficulty.minRoute) {
        return true;
      }
      if (directions.length >= _difficulty.maxRoute) {
        return false;
      }
      final remaining = _difficulty.maxRoute - directions.length;
      if (_manhattan(current, goal) > remaining) {
        return false;
      }

      final candidates = <_SokobanRouteCandidate>[
        for (final direction in _SokobanDirection.values)
          _SokobanRouteCandidate(
            direction: direction,
            score: _routeCandidateScore(current, goal, direction, directions),
          ),
      ]..sort((a, b) => a.score.compareTo(b.score));

      for (final candidate in candidates) {
        final direction = candidate.direction;
        final next = _step(current, direction);
        final behind = _step(current, _opposite(direction));
        if (!_insidePlayable(next) ||
            !_insidePlayable(behind) ||
            visited.contains(next)) {
          continue;
        }
        if (next == goal && directions.length + 1 < _difficulty.minRoute) {
          continue;
        }
        if (directions.isNotEmpty &&
            direction == _opposite(directions.last) &&
            _random.nextBool()) {
          continue;
        }
        visited.add(next);
        cells.add(next);
        directions.add(direction);
        if (search(next)) {
          return true;
        }
        directions.removeLast();
        cells.removeLast();
        visited.remove(next);
      }
      return false;
    }

    if (search(start)) {
      return _SokobanRouteDraft(
        cells: List<int>.of(cells),
        directions: List<_SokobanDirection>.of(directions),
      );
    }
    return null;
  }

  int _routeCandidateScore(
    int current,
    int goal,
    _SokobanDirection direction,
    List<_SokobanDirection> directions,
  ) {
    final next = _step(current, direction);
    var score = _manhattan(next, goal) * 10 + _random.nextInt(10);
    if (directions.isNotEmpty) {
      final last = directions.last;
      if (direction == last) {
        score += _longestTailRun(directions) >= 2 ? 8 : 3;
      } else if (direction != _opposite(last)) {
        score -= 5;
      }
    }
    return score;
  }

  int _longestTailRun(List<_SokobanDirection> directions) {
    if (directions.isEmpty) {
      return 0;
    }
    var run = 1;
    for (var index = directions.length - 2; index >= 0; index -= 1) {
      if (directions[index] != directions.last) {
        break;
      }
      run += 1;
    }
    return run;
  }

  Set<int> _requiredCellsForRoute(_SokobanRouteDraft route) {
    final required = <int>{...route.cells};
    for (var index = 0; index < route.directions.length; index += 1) {
      required.add(
        _step(route.cells[index], _opposite(route.directions[index])),
      );
    }
    return required;
  }

  Set<int> _buildWalls(Set<int> required) {
    final walls = <int>{};
    for (var row = 0; row < _rows; row += 1) {
      for (var col = 0; col < _cols; col += 1) {
        if (row == 0 || col == 0 || row == _rows - 1 || col == _cols - 1) {
          walls.add(_indexOf(row, col));
        }
      }
    }
    final candidates = <int>[
      for (var row = 1; row < _rows - 1; row += 1)
        for (var col = 1; col < _cols - 1; col += 1)
          if (!required.contains(_indexOf(row, col))) _indexOf(row, col),
    ]..shuffle(_random);
    final nearRoute =
        candidates
            .where(
              (cell) => _SokobanDirection.values.any(
                (direction) => required.contains(_step(cell, direction)),
              ),
            )
            .toList(growable: false)
          ..shuffle(_random);
    final farRoute =
        candidates
            .where((cell) => !nearRoute.contains(cell))
            .toList(growable: false)
          ..shuffle(_random);
    final wallBudget =
        _difficulty.extraWalls +
        _random.nextInt(math.max(2, _difficulty.boxes + 3));
    final nearBudget = (wallBudget * 0.64).round();
    final ordered = <int>[
      ...nearRoute.take(nearBudget),
      ...farRoute,
      ...nearRoute.skip(nearBudget),
    ];
    walls.addAll(ordered.take(math.min(ordered.length, wallBudget)));
    return walls;
  }

  String _levelSignature(_SokobanLevel level) {
    String sortedSet(Set<int> values) {
      final sorted = values.toList(growable: false)..sort();
      return sorted.join('.');
    }

    final routeShape = level.plans
        .map(
          (plan) => plan.directions
              .map(
                (direction) => switch (direction) {
                  _SokobanDirection.up => 'u',
                  _SokobanDirection.down => 'd',
                  _SokobanDirection.left => 'l',
                  _SokobanDirection.right => 'r',
                },
              )
              .join(),
        )
        .join('|');
    return [
      level.playerStart,
      sortedSet(level.boxStarts),
      sortedSet(level.goals),
      sortedSet(level.walls),
      routeShape,
    ].join('/');
  }

  void _rememberLevelSignature(String signature) {
    _recentLevelSignatures.remove(signature);
    _recentLevelSignatures.addLast(signature);
    while (_recentLevelSignatures.length > _recentLevelMemory) {
      _recentLevelSignatures.removeFirst();
    }
  }

  bool _solutionCanPlay(_SokobanLevel level) {
    var player = level.playerStart;
    final boxes = <int>{...level.boxStarts};
    for (final plan in level.plans) {
      var box = plan.cells.first;
      if (!boxes.contains(box)) {
        return false;
      }
      for (var index = 0; index < plan.directions.length; index += 1) {
        final direction = plan.directions[index];
        final behind = _step(box, _opposite(direction));
        final nextBox = _step(box, direction);
        if (!_inBounds(behind) ||
            !_inBounds(nextBox) ||
            level.walls.contains(nextBox) ||
            boxes.contains(behind)) {
          return false;
        }
        if (!_canReach(player, behind, boxes, level.walls)) {
          return false;
        }
        boxes
          ..remove(box)
          ..add(nextBox);
        player = box;
        box = nextBox;
        if (box != plan.cells[index + 1]) {
          return false;
        }
      }
    }
    return level.goals.every(boxes.contains);
  }

  bool _canReach(int start, int target, Set<int> boxes, Set<int> walls) {
    if (walls.contains(target) || boxes.contains(target)) {
      return false;
    }
    final visited = <int>{start};
    final queue = Queue<int>()..add(start);
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (current == target) {
        return true;
      }
      for (final direction in _SokobanDirection.values) {
        final next = _step(current, direction);
        if (!_inBounds(next) ||
            walls.contains(next) ||
            boxes.contains(next) ||
            visited.contains(next)) {
          continue;
        }
        visited.add(next);
        queue.add(next);
      }
    }
    return false;
  }

  _SokobanLevel _fallbackLevel(_SokobanDifficulty difficulty) {
    final plans = <_SokobanPushPlan>[
      _planFromCells(<int>[
        _indexOf(3, 2),
        _indexOf(3, 3),
        _indexOf(3, 4),
        _indexOf(2, 4),
        _indexOf(2, 5),
        _indexOf(3, 5),
      ]),
      if (difficulty.boxes >= 2)
        _planFromCells(<int>[
          _indexOf(5, 5),
          _indexOf(5, 4),
          _indexOf(5, 3),
          _indexOf(4, 3),
          _indexOf(3, 3),
        ]),
      if (difficulty.boxes >= 3)
        _planFromCells(<int>[
          _indexOf(6, 2),
          _indexOf(6, 3),
          _indexOf(6, 4),
          _indexOf(5, 4),
          _indexOf(4, 4),
        ]),
    ];
    final walls = <int>{};
    for (var row = 0; row < _rows; row += 1) {
      for (var col = 0; col < _cols; col += 1) {
        if (row == 0 || col == 0 || row == _rows - 1 || col == _cols - 1) {
          walls.add(_indexOf(row, col));
        }
      }
    }
    walls.addAll(<int>[
      _indexOf(1, 2),
      _indexOf(1, 6),
      _indexOf(4, 1),
      _indexOf(7, 6),
    ]);
    return _SokobanLevel(
      walls: walls,
      playerStart: _indexOf(3, 1),
      boxStarts: <int>{for (final plan in plans) plan.cells.first},
      goals: <int>{for (final plan in plans) plan.cells.last},
      plans: plans,
      difficultySteps: plans.fold<int>(
        0,
        (sum, plan) => sum + plan.directions.length,
      ),
    );
  }

  _SokobanPushPlan _planFromCells(List<int> cells) {
    final directions = <_SokobanDirection>[];
    for (var index = 0; index < cells.length - 1; index += 1) {
      final current = cells[index];
      final next = cells[index + 1];
      directions.add(_directionBetween(current, next));
    }
    return _SokobanPushPlan(
      cells: cells,
      directions: directions,
      requiredCells: <int>{...cells},
    );
  }

  _SokobanDirection _directionBetween(int current, int next) {
    if (next == _step(current, _SokobanDirection.up)) {
      return _SokobanDirection.up;
    }
    if (next == _step(current, _SokobanDirection.down)) {
      return _SokobanDirection.down;
    }
    if (next == _step(current, _SokobanDirection.left)) {
      return _SokobanDirection.left;
    }
    return _SokobanDirection.right;
  }

  void _tryMove(_SokobanDirection direction) {
    if (_won) {
      return;
    }
    final next = _step(_player, direction);
    if (_level.walls.contains(next)) {
      return;
    }
    final snapshot = _SokobanSnapshot(
      player: _player,
      boxes: <int>{..._boxes},
      moves: _moves,
      pushes: _pushes,
      won: _won,
    );
    if (_boxes.contains(next)) {
      final nextBox = _step(next, direction);
      if (_level.walls.contains(nextBox) || _boxes.contains(nextBox)) {
        return;
      }
      setState(() {
        _history.add(snapshot);
        _boxes
          ..remove(next)
          ..add(nextBox);
        _player = next;
        _moves += 1;
        _pushes += 1;
        _won = _level.goals.every(_boxes.contains);
      });
      if (_won) {
        unawaited(HapticFeedback.mediumImpact());
      }
      return;
    }
    setState(() {
      _history.add(snapshot);
      _player = next;
      _moves += 1;
    });
  }

  void _undo() {
    if (_history.isEmpty) {
      return;
    }
    final snapshot = _history.removeLast();
    setState(() {
      _player = snapshot.player;
      _boxes = <int>{...snapshot.boxes};
      _moves = snapshot.moves;
      _pushes = snapshot.pushes;
      _won = snapshot.won;
    });
  }

  _SokobanHint? _nextHint() {
    for (final plan in _level.plans) {
      for (final box in _boxes) {
        final index = plan.cells.indexOf(box);
        if (index >= 0 && index < plan.directions.length) {
          return _SokobanHint(box: box, direction: plan.directions[index]);
        }
      }
    }
    return null;
  }

  String _directionLabel(AppI18n i18n, _SokobanDirection direction) {
    return switch (direction) {
      _SokobanDirection.up => i18n.t('toolbox.miniGames.sokoban.up.e7dd4105'),
      _SokobanDirection.down => i18n.t(
        'toolbox.miniGames.sokoban.down.f73397ee',
      ),
      _SokobanDirection.left => i18n.t(
        'toolbox.miniGames.sokoban.left.8c384155',
      ),
      _SokobanDirection.right => i18n.t(
        'toolbox.miniGames.sokoban.right.580a0ff9',
      ),
    };
  }

  IconData _directionIcon(_SokobanDirection direction) {
    return switch (direction) {
      _SokobanDirection.up => Icons.keyboard_arrow_up_rounded,
      _SokobanDirection.down => Icons.keyboard_arrow_down_rounded,
      _SokobanDirection.left => Icons.keyboard_arrow_left_rounded,
      _SokobanDirection.right => Icons.keyboard_arrow_right_rounded,
    };
  }

  String _hintText(AppI18n i18n) {
    if (_won) {
      return i18n.t(
        'toolbox.miniGames.sokoban.all_crates_are_already_on_goals.0289c7b5',
      );
    }
    final hint = _nextHint();
    if (hint != null) {
      final row = _rowOf(hint.box) + 1;
      final col = _colOf(hint.box) + 1;
      return i18n.t(
        'toolbox.miniGames.sokoban.push_the_crate_at_row_value_column.652ef8e8',
        params: <String, Object?>{
          'row': row,
          'col': col,
          'direction': _directionLabel(i18n, hint.direction),
        },
      );
    }
    return i18n.t(
      'toolbox.miniGames.sokoban.the_crates_have_left_the_generated_routes.27afd7c9',
    );
  }

  void _showHint() {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    setState(() {
      _showRoute = true;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_hintText(i18n))));
  }

  String _statusLabel(AppI18n i18n) {
    if (_won) {
      return i18n.t('toolbox.miniGames.sokoban.solved.a79babd6');
    }
    if (_nextHint() == null) {
      return i18n.t('toolbox.miniGames.sokoban.off_route.7beec4c2');
    }
    return i18n.t('toolbox.miniGames.sokoban.playing.98d237d2');
  }

  int get _solvedBoxes => _boxes.where(_level.goals.contains).length;

  _SokobanRouteCell? _routeCellFor(int cell) {
    for (final plan in _level.plans) {
      final index = plan.cells.indexOf(cell);
      if (index >= 0) {
        return _SokobanRouteCell(
          order: _level.plans.indexOf(plan) + 1,
          direction: index < plan.directions.length
              ? plan.directions[index]
              : null,
        );
      }
    }
    return null;
  }

  Widget _buildBoard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = math.min(440.0, constraints.maxWidth);
        final cellSize = boardSize / _cols;
        return Center(
          child: SizedBox(
            width: boardSize,
            height: boardSize,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _rows * _cols,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _cols,
              ),
              itemBuilder: (context, index) {
                final isWall = _level.walls.contains(index);
                final isGoal = _level.goals.contains(index);
                final isBox = _boxes.contains(index);
                final isPlayer = _player == index;
                final route = _showRoute ? _routeCellFor(index) : null;
                final onRoute = route != null;
                return GestureDetector(
                  onTap: () {
                    for (final direction in _SokobanDirection.values) {
                      if (index == _step(_player, direction)) {
                        _tryMove(direction);
                        return;
                      }
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    margin: EdgeInsets.all(cellSize <= 40 ? 1.0 : 1.8),
                    decoration: BoxDecoration(
                      color: isWall
                          ? const Color(0xFF3A4354)
                          : isGoal
                          ? const Color(0xFFFFE6A6)
                          : onRoute
                          ? Color.alphaBlend(
                              const Color(0xFF8A6CCF).withValues(alpha: 0.18),
                              colors.surfaceContainerLow,
                            )
                          : colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isGoal
                            ? const Color(0xFFD89C2F)
                            : colors.outlineVariant,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        if (route?.direction != null && !isBox && !isPlayer)
                          Icon(
                            _directionIcon(route!.direction!),
                            size: cellSize * 0.42,
                            color: const Color(0xFF8A6CCF),
                          ),
                        if (route != null && route.direction == null && !isBox)
                          Text(
                            '${route.order}',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: const Color(0xFF8A6CCF),
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        if (isGoal)
                          Icon(
                            Icons.flag_rounded,
                            size: cellSize * 0.34,
                            color: const Color(0xFFB7791F),
                          ),
                        if (isBox)
                          Container(
                            width: cellSize * 0.58,
                            height: cellSize * 0.58,
                            decoration: BoxDecoration(
                              color: isGoal
                                  ? const Color(0xFF42A66A)
                                  : const Color(0xFFD1944B),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                            child: Icon(
                              Icons.inventory_2_rounded,
                              size: cellSize * 0.32,
                              color: Colors.white,
                            ),
                          ),
                        if (isPlayer)
                          Icon(
                            Icons.person_rounded,
                            size: cellSize * 0.48,
                            color: colors.primary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _moveButton(_SokobanDirection direction) {
    return SizedBox(
      width: 56,
      height: 48,
      child: FilledButton.tonal(
        onPressed: () => _tryMove(direction),
        style: FilledButton.styleFrom(padding: EdgeInsets.zero),
        child: Icon(_directionIcon(direction)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
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
                  label: i18n.t(
                    'toolbox.miniGames.sokoban.difficulty.34905971',
                  ),
                  value: _difficultyLabel(i18n, _difficulty),
                ),
                ToolboxMetricCard(
                  label: i18n.t(
                    'toolbox.miniGames.sokoban.crates_goals.5e094e06',
                  ),
                  value: '${_boxes.length} / ${_level.goals.length}',
                ),
                ToolboxMetricCard(
                  label: i18n.t('toolbox.miniGames.sokoban.solved.adaf0bd4'),
                  value: '$_solvedBoxes / ${_level.goals.length}',
                ),
                ToolboxMetricCard(
                  label: i18n.t(
                    'toolbox.miniGames.sokoban.route_steps.317b2ecb',
                  ),
                  value: '${_level.difficultySteps}',
                ),
                ToolboxMetricCard(
                  label: i18n.t(
                    'toolbox.miniGames.sokoban.moves_pushes.f00d7aa4',
                  ),
                  value: '$_moves / $_pushes',
                ),
                ToolboxMetricCard(
                  label: i18n.t('toolbox.miniGames.sokoban.status.89987aa2'),
                  value: _statusLabel(i18n),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final difficulty in _SokobanDifficulty.values)
                  ChoiceChip(
                    label: Text(_difficultyLabel(i18n, difficulty)),
                    selected: _difficulty == difficulty,
                    onSelected: (_) => _setDifficulty(difficulty),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Text(
                _hintText(i18n),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
            _MiniGameScrollLockSurface(child: _buildBoard(context)),
            const SizedBox(height: 12),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _moveButton(_SokobanDirection.up),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _moveButton(_SokobanDirection.left),
                      const SizedBox(width: 8),
                      _moveButton(_SokobanDirection.down),
                      const SizedBox(width: 8),
                      _moveButton(_SokobanDirection.right),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: _showHint,
                  icon: const Icon(Icons.lightbulb_outline_rounded),
                  label: Text(
                    i18n.t('toolbox.miniGames.sokoban.hint.f090a729'),
                  ),
                ),
                FilterChip(
                  selected: _showRoute,
                  label: Text(
                    i18n.t('toolbox.miniGames.sokoban.show_route.983e4a6a'),
                  ),
                  onSelected: (value) {
                    setState(() {
                      _showRoute = value;
                    });
                  },
                ),
                OutlinedButton.icon(
                  onPressed: _history.isEmpty ? null : _undo,
                  icon: const Icon(Icons.undo_rounded),
                  label: Text(
                    i18n.t('toolbox.miniGames.sokoban.undo.458cc97f'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _newLevel,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    i18n.t('toolbox.miniGames.sokoban.new_level.d1e3d694'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SokobanLevel {
  const _SokobanLevel({
    required this.walls,
    required this.playerStart,
    required this.boxStarts,
    required this.goals,
    required this.plans,
    required this.difficultySteps,
  });

  final Set<int> walls;
  final int playerStart;
  final Set<int> boxStarts;
  final Set<int> goals;
  final List<_SokobanPushPlan> plans;
  final int difficultySteps;
}

class _SokobanRouteDraft {
  const _SokobanRouteDraft({required this.cells, required this.directions});

  final List<int> cells;
  final List<_SokobanDirection> directions;
}

class _SokobanRouteCandidate {
  const _SokobanRouteCandidate({required this.direction, required this.score});

  final _SokobanDirection direction;
  final int score;
}

class _SokobanPushPlan {
  const _SokobanPushPlan({
    required this.cells,
    required this.directions,
    required this.requiredCells,
  });

  final List<int> cells;
  final List<_SokobanDirection> directions;
  final Set<int> requiredCells;
}

class _SokobanSnapshot {
  const _SokobanSnapshot({
    required this.player,
    required this.boxes,
    required this.moves,
    required this.pushes,
    required this.won,
  });

  final int player;
  final Set<int> boxes;
  final int moves;
  final int pushes;
  final bool won;
}

class _SokobanHint {
  const _SokobanHint({required this.box, required this.direction});

  final int box;
  final _SokobanDirection direction;
}

class _SokobanRouteCell {
  const _SokobanRouteCell({required this.order, required this.direction});

  final int order;
  final _SokobanDirection? direction;
}

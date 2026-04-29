part of 'toolbox_mini_games.dart';

enum _SokobanDirection { up, down, left, right }

enum _SokobanDifficulty {
  easy(boxes: 1, minRoute: 6, maxRoute: 9, extraWalls: 4),
  medium(boxes: 2, minRoute: 6, maxRoute: 11, extraWalls: 8),
  hard(boxes: 3, minRoute: 7, maxRoute: 13, extraWalls: 12);

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
  static const int _rows = 9;
  static const int _cols = 9;
  final math.Random _random = math.Random();

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

  String _text(AppI18n i18n, {required String zh, required String en}) {
    return pickUiText(i18n, zh: zh, en: en);
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
      _SokobanDifficulty.easy => _text(i18n, zh: '单箱', en: 'Single'),
      _SokobanDifficulty.medium => _text(i18n, zh: '双箱', en: 'Double'),
      _SokobanDifficulty.hard => _text(i18n, zh: '三箱', en: 'Triple'),
    };
  }

  _SokobanLevel _generateLevel() {
    for (var attempt = 0; attempt < 320; attempt += 1) {
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
        return level;
      }
    }
    return _fallbackLevel(_difficulty);
  }

  _SokobanPushPlan? _buildNonOverlappingPlan(Set<int> reserved) {
    for (var attempt = 0; attempt < 120; attempt += 1) {
      final route = _buildRoute();
      if (route == null) {
        continue;
      }
      final required = _requiredCellsForRoute(route);
      if (required.any(reserved.contains)) {
        continue;
      }
      return _SokobanPushPlan(
        cells: route.cells,
        directions: route.directions,
        requiredCells: required,
      );
    }
    return null;
  }

  _SokobanRouteDraft? _buildRoute() {
    final targetLength =
        _difficulty.minRoute +
        _random.nextInt(_difficulty.maxRoute - _difficulty.minRoute + 1);
    for (var attempt = 0; attempt < 100; attempt += 1) {
      final start = _indexOf(2 + _random.nextInt(5), 2 + _random.nextInt(5));
      final cells = <int>[start];
      final directions = <_SokobanDirection>[];
      while (directions.length < targetLength) {
        final current = cells.last;
        final candidates = <_SokobanDirection>[];
        for (final direction in _SokobanDirection.values) {
          if (directions.isNotEmpty &&
              direction == _opposite(directions.last)) {
            continue;
          }
          final next = _step(current, direction);
          final behind = _step(current, _opposite(direction));
          if (!_insidePlayable(next) || cells.contains(next)) {
            continue;
          }
          if (!_insidePlayable(behind)) {
            continue;
          }
          candidates.add(direction);
        }
        if (candidates.isEmpty) {
          break;
        }
        final direction = candidates[_random.nextInt(candidates.length)];
        directions.add(direction);
        cells.add(_step(current, direction));
      }
      if (directions.length >= _difficulty.minRoute) {
        return _SokobanRouteDraft(cells: cells, directions: directions);
      }
    }
    return null;
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
    walls.addAll(
      candidates.take(math.min(candidates.length, _difficulty.extraWalls)),
    );
    return walls;
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
      _SokobanDirection.up => _text(i18n, zh: '向上', en: 'up'),
      _SokobanDirection.down => _text(i18n, zh: '向下', en: 'down'),
      _SokobanDirection.left => _text(i18n, zh: '向左', en: 'left'),
      _SokobanDirection.right => _text(i18n, zh: '向右', en: 'right'),
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
      return _text(
        i18n,
        zh: '所有箱子已经到达目标点。',
        en: 'All crates are already on goals.',
      );
    }
    final hint = _nextHint();
    if (hint != null) {
      final row = _rowOf(hint.box) + 1;
      final col = _colOf(hint.box) + 1;
      return _text(
        i18n,
        zh: '建议推动第 $row 行第 $col 列的箱子：${_directionLabel(i18n, hint.direction)}。',
        en: 'Push the crate at row $row, column $col ${_directionLabel(i18n, hint.direction)}.',
      );
    }
    return _text(
      i18n,
      zh: '当前箱子已偏离生成路线，建议撤销或显示正确线路后调整。',
      en: 'The crates have left the generated routes. Undo or reveal the correct routes.',
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
      return _text(i18n, zh: '已完成', en: 'Solved');
    }
    if (_nextHint() == null) {
      return _text(i18n, zh: '偏离路线', en: 'Off route');
    }
    return _text(i18n, zh: '进行中', en: 'Playing');
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
                  label: _text(i18n, zh: '难度', en: 'Difficulty'),
                  value: _difficultyLabel(i18n, _difficulty),
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '箱子/目标', en: 'Crates/goals'),
                  value: '${_boxes.length} / ${_level.goals.length}',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '完成', en: 'Solved'),
                  value: '$_solvedBoxes / ${_level.goals.length}',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '正确步数', en: 'Route steps'),
                  value: '${_level.difficultySteps}',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '移动/推动', en: 'Moves/pushes'),
                  value: '$_moves / $_pushes',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '状态', en: 'Status'),
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
                  label: Text(_text(i18n, zh: '提示', en: 'Hint')),
                ),
                FilterChip(
                  selected: _showRoute,
                  label: Text(_text(i18n, zh: '显示正确线路', en: 'Show route')),
                  onSelected: (value) {
                    setState(() {
                      _showRoute = value;
                    });
                  },
                ),
                OutlinedButton.icon(
                  onPressed: _history.isEmpty ? null : _undo,
                  icon: const Icon(Icons.undo_rounded),
                  label: Text(_text(i18n, zh: '撤销', en: 'Undo')),
                ),
                OutlinedButton.icon(
                  onPressed: _newLevel,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(_text(i18n, zh: '新关卡', en: 'New level')),
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

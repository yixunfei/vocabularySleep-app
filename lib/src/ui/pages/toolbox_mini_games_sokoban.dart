part of 'toolbox_mini_games.dart';

class _SokobanGame extends StatefulWidget {
  const _SokobanGame();

  @override
  State<_SokobanGame> createState() => _SokobanGameState();
}

class _SokobanGameState extends State<_SokobanGame> {
  static const int _maxHistory = 300;
  static const int _prefetchDepth = 2;

  final SokobanLevelGenerator _generator = const SokobanLevelGenerator();
  final Map<SokobanDifficulty, Queue<SokobanLevel>> _levelQueues =
      <SokobanDifficulty, Queue<SokobanLevel>>{};
  final Queue<String> _recentSignatures = Queue<String>();
  final List<_SokobanSnapshot> _history = <_SokobanSnapshot>[];

  SokobanDifficulty _difficulty = SokobanDifficulty.single;
  late SokobanLevel _level;
  late List<int> _boxes;
  int _player = 0;
  int _moves = 0;
  int _pushes = 0;
  int _levelNumber = 1;
  int _seed = DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
  bool _won = false;
  bool _showRoute = false;
  bool _prefetchScheduled = false;
  Timer? _prefetchTimer;
  Future<void>? _prefetchFuture;

  @override
  void initState() {
    super.initState();
    _loadLevel(_takeNextLevel(_difficulty));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _schedulePrefetch();
    });
  }

  SokobanLevel _takeNextLevel(SokobanDifficulty difficulty) {
    final queue = _levelQueues.putIfAbsent(
      difficulty,
      () => Queue<SokobanLevel>(),
    );
    if (queue.isNotEmpty) {
      final level = queue.removeFirst();
      _rememberSignature(level.signature);
      return level;
    }
    final level = _generateLevel(difficulty);
    _rememberSignature(level.signature);
    return level;
  }

  SokobanLevel _generateLevel(SokobanDifficulty difficulty) {
    final excluded = _excludedSignatures();
    return _generator.generate(
      difficulty: difficulty,
      seed: _nextSeed(),
      excludedSignatures: excluded,
    );
  }

  Set<String> _excludedSignatures() {
    final excluded = <String>{..._recentSignatures};
    for (final queue in _levelQueues.values) {
      excluded.addAll(queue.map((level) => level.signature));
    }
    return excluded;
  }

  Future<SokobanLevel> _generateLevelInBackground(
    SokobanDifficulty difficulty,
  ) {
    final seed = _nextSeed();
    final excluded = _excludedSignatures();
    return generateSokobanLevelInBackground(
      difficulty: difficulty,
      seed: seed,
      excludedSignatures: excluded,
    );
  }

  int _nextSeed() {
    _seed = (_seed * 1664525 + 1013904223) & 0x7fffffff;
    return _seed;
  }

  void _rememberSignature(String signature) {
    _recentSignatures.remove(signature);
    _recentSignatures.addLast(signature);
    while (_recentSignatures.length > 40) {
      _recentSignatures.removeFirst();
    }
  }

  void _loadLevel(SokobanLevel level) {
    _level = level;
    _player = level.playerStart;
    _boxes = List<int>.of(level.boxStarts);
    _history.clear();
    _moves = 0;
    _pushes = 0;
    _won = level.isSolved(_boxes);
    _showRoute = false;
  }

  void _schedulePrefetch() {
    if (!mounted || _prefetchScheduled || _prefetchFuture != null) {
      return;
    }
    final targetDifficulty = _prefetchTargetDifficulty();
    if (targetDifficulty == null) {
      return;
    }
    _prefetchScheduled = true;
    // Yield at least one frame before starting the worker request. This keeps
    // mode changes and button feedback responsive on slower devices.
    _prefetchTimer = Timer(const Duration(milliseconds: 16), () {
      _prefetchTimer = null;
      _prefetchScheduled = false;
      if (!mounted) {
        return;
      }
      _prefetchFuture = Future<void>.microtask(
        () => _runPrefetch(targetDifficulty),
      );
    });
  }

  SokobanDifficulty? _prefetchTargetDifficulty() {
    final order = <SokobanDifficulty>[
      _difficulty,
      for (final difficulty in SokobanDifficulty.values)
        if (difficulty != _difficulty) difficulty,
    ];
    for (final difficulty in order) {
      final queue = _levelQueues.putIfAbsent(
        difficulty,
        () => Queue<SokobanLevel>(),
      );
      if (queue.length < _prefetchDepth) {
        return difficulty;
      }
    }
    return null;
  }

  Future<void> _runPrefetch(SokobanDifficulty difficulty) async {
    try {
      if (!mounted) {
        return;
      }
      final queue = _levelQueues.putIfAbsent(
        difficulty,
        () => Queue<SokobanLevel>(),
      );
      if (queue.length >= _prefetchDepth) {
        return;
      }
      SokobanLevel level;
      try {
        level = await _generateLevelInBackground(difficulty);
      } catch (_) {
        // Some embedders (and a few test runners) do not expose worker
        // isolates. Keep the queue usable with the same bounded generator.
        final seed = _nextSeed();
        final excluded = _excludedSignatures();
        level = _generator.generate(
          difficulty: difficulty,
          seed: seed,
          excludedSignatures: excluded,
        );
      }
      if (!mounted) {
        return;
      }
      final currentQueue = _levelQueues.putIfAbsent(
        difficulty,
        () => Queue<SokobanLevel>(),
      );
      final duplicate = currentQueue.any(
        (queued) => queued.signature == level.signature,
      );
      if (currentQueue.length < _prefetchDepth &&
          !_recentSignatures.contains(level.signature) &&
          !duplicate) {
        currentQueue.addLast(level);
      }
    } catch (_) {
      // Prefetch is opportunistic. A failed worker must never surface as an
      // uncaught future or prevent the user from requesting a synchronous
      // level through the normal button path.
    } finally {
      _prefetchFuture = null;
      if (mounted) {
        _schedulePrefetch();
      }
    }
  }

  @override
  void dispose() {
    _prefetchTimer?.cancel();
    _prefetchTimer = null;
    _levelQueues.clear();
    _history.clear();
    super.dispose();
  }

  void _setDifficulty(SokobanDifficulty difficulty) {
    if (_difficulty == difficulty) {
      return;
    }
    final nextLevel = _takeNextLevel(difficulty);
    setState(() {
      _difficulty = difficulty;
      _levelNumber = 1;
      _loadLevel(nextLevel);
    });
    _schedulePrefetch();
  }

  void _newLevel() {
    // Generate before entering setState so the framework is never held while
    // the level builder runs, even if a future generator is more expensive.
    final nextLevel = _takeNextLevel(_difficulty);
    setState(() {
      _levelNumber += 1;
      _loadLevel(nextLevel);
    });
    _schedulePrefetch();
  }

  int _step(int index, SokobanDirection direction) {
    final row = index ~/ _level.columns;
    final column = index % _level.columns;
    return (row + direction.rowDelta) * _level.columns +
        column +
        direction.columnDelta;
  }

  bool _isPlayable(int index) {
    return _level.isInside(index) && !_level.isWall(index);
  }

  void _tryMove(SokobanDirection direction) {
    if (_won) {
      return;
    }
    final next = _step(_player, direction);
    if (!_isPlayable(next)) {
      return;
    }
    final boxId = _boxes.indexOf(next);
    final nextBox = _step(next, direction);
    if (boxId >= 0 &&
        (!_isPlayable(nextBox) || _boxOccupiesTarget(boxId, nextBox))) {
      return;
    }

    final snapshot = _SokobanSnapshot(
      player: _player,
      boxes: List<int>.of(_boxes),
      moves: _moves,
      pushes: _pushes,
      won: _won,
    );
    setState(() {
      if (_history.length >= _maxHistory) {
        _history.removeAt(0);
      }
      _history.add(snapshot);
      if (boxId >= 0) {
        // Replace the collection instead of mutating it in place. The board
        // painter keeps the previous list as its repaint snapshot.
        final nextBoxes = List<int>.of(_boxes);
        nextBoxes[boxId] = nextBox;
        _boxes = nextBoxes;
        _pushes += 1;
      }
      _player = next;
      _moves += 1;
      _won = _level.isSolved(_boxes);
    });
    if (_won) {
      unawaited(HapticFeedback.mediumImpact());
    }
  }

  bool _boxOccupiesTarget(int movingBoxId, int target) {
    for (var index = 0; index < _boxes.length; index += 1) {
      if (index != movingBoxId && _boxes[index] == target) {
        return true;
      }
    }
    return false;
  }

  void _undo() {
    if (_history.isEmpty) {
      return;
    }
    final snapshot = _history.removeLast();
    setState(() {
      _player = snapshot.player;
      _boxes = List<int>.of(snapshot.boxes);
      _moves = snapshot.moves;
      _pushes = snapshot.pushes;
      _won = snapshot.won;
    });
  }

  _SokobanProgress _solutionProgress() {
    final expected = List<int>.of(_level.boxStarts);
    if (_sameBoxes(expected, _boxes)) {
      return const _SokobanProgress(completed: 0, onRoute: true);
    }
    var completed = 0;
    for (final push in _level.solution) {
      if (push.boxId < 0 ||
          push.boxId >= expected.length ||
          expected[push.boxId] != push.from) {
        return _SokobanProgress(completed: completed, onRoute: false);
      }
      expected[push.boxId] = push.to;
      completed += 1;
      if (_sameBoxes(expected, _boxes)) {
        return _SokobanProgress(completed: completed, onRoute: true);
      }
    }
    return _SokobanProgress(completed: completed, onRoute: false);
  }

  bool _sameBoxes(List<int> first, List<int> second) {
    if (first.length != second.length) {
      return false;
    }
    for (var index = 0; index < first.length; index += 1) {
      if (first[index] != second[index]) {
        return false;
      }
    }
    return true;
  }

  List<SokobanPush> _remainingSolution(_SokobanProgress progress) {
    if (!_showRoute || progress.completed >= _level.solution.length) {
      return const <SokobanPush>[];
    }
    // Once a player deviates, keep the reference route available when the
    // route toggle is on. This makes the existing "show route" action useful
    // for recovery instead of silently hiding every arrow.
    if (!progress.onRoute) {
      return _showRoute ? _level.solution : const <SokobanPush>[];
    }
    return _level.solution.skip(progress.completed).toList(growable: false);
  }

  String _difficultyLabel(AppI18n i18n, SokobanDifficulty difficulty) {
    return switch (difficulty) {
      SokobanDifficulty.single => i18n.t(
        'toolbox.miniGames.sokoban.single.b4b00fd6',
      ),
      SokobanDifficulty.double => i18n.t(
        'toolbox.miniGames.sokoban.double.86266b27',
      ),
      SokobanDifficulty.triple => i18n.t(
        'toolbox.miniGames.sokoban.triple.f9908787',
      ),
    };
  }

  String _directionLabel(AppI18n i18n, SokobanDirection direction) {
    return switch (direction) {
      SokobanDirection.up => i18n.t('toolbox.miniGames.sokoban.up.e7dd4105'),
      SokobanDirection.down => i18n.t(
        'toolbox.miniGames.sokoban.down.f73397ee',
      ),
      SokobanDirection.left => i18n.t(
        'toolbox.miniGames.sokoban.left.8c384155',
      ),
      SokobanDirection.right => i18n.t(
        'toolbox.miniGames.sokoban.right.580a0ff9',
      ),
    };
  }

  String _hintText(AppI18n i18n) {
    if (_won) {
      return i18n.t(
        'toolbox.miniGames.sokoban.all_crates_are_already_on_goals.0289c7b5',
      );
    }
    final progress = _solutionProgress();
    if (!progress.onRoute) {
      return i18n.t(
        'toolbox.miniGames.sokoban.the_crates_have_left_the_generated_routes.27afd7c9',
      );
    }
    if (progress.completed < _level.solution.length) {
      final hint = _level.solution[progress.completed];
      return i18n.t(
        'toolbox.miniGames.sokoban.push_the_crate_at_row_value_column.652ef8e8',
        params: <String, Object?>{
          'row': hint.from ~/ _level.columns + 1,
          'col': hint.from % _level.columns + 1,
          'direction': _directionLabel(i18n, hint.direction),
        },
      );
    }
    return i18n.t(
      'toolbox.miniGames.sokoban.all_crates_are_already_on_goals.0289c7b5',
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

  String _statusLabel(AppI18n i18n, _SokobanProgress progress) {
    if (_won) {
      return i18n.t('toolbox.miniGames.sokoban.solved.a79babd6');
    }
    if (!progress.onRoute) {
      return i18n.t('toolbox.miniGames.sokoban.off_route.7beec4c2');
    }
    return i18n.t('toolbox.miniGames.sokoban.playing.98d237d2');
  }

  int get _solvedBoxes =>
      _boxes.where((box) => _level.goals.contains(box)).length;

  Widget _moveButton(SokobanDirection direction) {
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

  IconData _directionIcon(SokobanDirection direction) {
    return switch (direction) {
      SokobanDirection.up => Icons.keyboard_arrow_up_rounded,
      SokobanDirection.down => Icons.keyboard_arrow_down_rounded,
      SokobanDirection.left => Icons.keyboard_arrow_left_rounded,
      SokobanDirection.right => Icons.keyboard_arrow_right_rounded,
    };
  }

  Widget _buildLevelBadge(
    BuildContext context,
    AppI18n i18n,
    ColorScheme colorScheme,
  ) {
    return Align(
      alignment: Alignment.centerRight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.layers_outlined,
                size: 16,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 4),
              Text(
                i18n.t(
                  'toolbox.miniGames.sokoban.level_number',
                  params: <String, Object?>{'level': _levelNumber},
                ),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetrics(AppI18n i18n, _SokobanProgress progress) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        ToolboxMetricCard(
          label: i18n.t('toolbox.miniGames.sokoban.difficulty.34905971'),
          value: _difficultyLabel(i18n, _difficulty),
        ),
        ToolboxMetricCard(
          label: i18n.t('toolbox.miniGames.sokoban.crates_goals.5e094e06'),
          value: '${_boxes.length} / ${_level.goals.length}',
        ),
        ToolboxMetricCard(
          label: i18n.t('toolbox.miniGames.sokoban.solved.adaf0bd4'),
          value: '$_solvedBoxes / ${_level.goals.length}',
        ),
        ToolboxMetricCard(
          label: i18n.t('toolbox.miniGames.sokoban.route_steps.317b2ecb'),
          value: '${_level.solutionPushes}',
        ),
        ToolboxMetricCard(
          label: i18n.t('toolbox.miniGames.sokoban.moves_pushes.f00d7aa4'),
          value: '$_moves / $_pushes',
        ),
        ToolboxMetricCard(
          label: i18n.t('toolbox.miniGames.sokoban.status.89987aa2'),
          value: _statusLabel(i18n, progress),
        ),
      ],
    );
  }

  Widget _buildDifficultyPicker(AppI18n i18n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final difficulty in SokobanDifficulty.values)
          ChoiceChip(
            label: Text(_difficultyLabel(i18n, difficulty)),
            selected: _difficulty == difficulty,
            onSelected: (_) => _setDifficulty(difficulty),
          ),
      ],
    );
  }

  Widget _buildHintPanel(
    BuildContext context,
    AppI18n i18n,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        _hintText(i18n),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _buildBoard(List<SokobanPush> remainingSolution) {
    return _MiniGameScrollLockSurface(
      child: SokobanBoard(
        level: _level,
        boxes: _boxes,
        player: _player,
        showRoute: _showRoute,
        remainingSolution: remainingSolution,
        onMove: _tryMove,
      ),
    );
  }

  Widget _buildDirectionControls() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _moveButton(SokobanDirection.up),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _moveButton(SokobanDirection.left),
              const SizedBox(width: 8),
              _moveButton(SokobanDirection.down),
              const SizedBox(width: 8),
              _moveButton(SokobanDirection.right),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionControls(AppI18n i18n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        FilledButton.tonalIcon(
          onPressed: _showHint,
          icon: const Icon(Icons.lightbulb_outline_rounded),
          label: Text(i18n.t('toolbox.miniGames.sokoban.hint.f090a729')),
        ),
        FilterChip(
          selected: _showRoute,
          label: Text(i18n.t('toolbox.miniGames.sokoban.show_route.983e4a6a')),
          onSelected: (value) {
            setState(() {
              _showRoute = value;
            });
          },
        ),
        OutlinedButton.icon(
          onPressed: _history.isEmpty ? null : _undo,
          icon: const Icon(Icons.undo_rounded),
          label: Text(i18n.t('toolbox.miniGames.sokoban.undo.458cc97f')),
        ),
        OutlinedButton.icon(
          onPressed: _newLevel,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(i18n.t('toolbox.miniGames.sokoban.new_level.d1e3d694')),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final progress = _solutionProgress();
    final remainingSolution = _remainingSolution(progress);
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildLevelBadge(context, i18n, colorScheme),
            const SizedBox(height: 8),
            _buildMetrics(i18n, progress),
            const SizedBox(height: 12),
            _buildDifficultyPicker(i18n),
            const SizedBox(height: 12),
            _buildHintPanel(context, i18n, colorScheme),
            const SizedBox(height: 12),
            _buildBoard(remainingSolution),
            const SizedBox(height: 12),
            _buildDirectionControls(),
            const SizedBox(height: 12),
            _buildActionControls(i18n),
          ],
        ),
      ),
    );
  }
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
  final List<int> boxes;
  final int moves;
  final int pushes;
  final bool won;
}

class _SokobanProgress {
  const _SokobanProgress({required this.completed, required this.onRoute});

  final int completed;
  final bool onRoute;
}

part of 'toolbox_mini_games.dart';

enum _MatchThreeStatus {
  ready,
  selected,
  invalid,
  clearing,
  reshuffled,
  won,
  timeUp,
}

enum _MatchThreePower { none, row, column, bomb, rainbow }

class _MatchThreeRun {
  const _MatchThreeRun({
    required this.indexes,
    required this.kind,
    required this.horizontal,
  });

  final List<int> indexes;
  final int kind;
  final bool horizontal;

  int get length => indexes.length;

  bool contains(int index) => indexes.contains(index);
}

class _MatchThreeActivation {
  const _MatchThreeActivation({required this.index, this.targetKind});

  final int index;
  final int? targetKind;
}

class _MatchThreePowerCreation {
  const _MatchThreePowerCreation({
    required this.index,
    required this.kind,
    required this.power,
  });

  final int index;
  final int kind;
  final _MatchThreePower power;
}

class _MatchThreeClearPlan {
  const _MatchThreeClearPlan({
    required this.clearIndexes,
    required this.creation,
  });

  final Set<int> clearIndexes;
  final _MatchThreePowerCreation? creation;
}

class _MatchThreeGame extends StatefulWidget {
  const _MatchThreeGame();

  @override
  State<_MatchThreeGame> createState() => _MatchThreeGameState();
}

class _MatchThreeGameState extends State<_MatchThreeGame> {
  static const int _rows = 8;
  static const int _cols = 8;
  static const int _kinds = 6;
  static const int _emptyTile = -1;
  static const int _blockerTile = -2;
  static const int _targetScore = 1200;
  static const int _initialSeconds = 75;
  static const int _maxSeconds = 120;
  static const int _minimumPlayableMoves = 3;
  static const String _logTag = 'MatchThreeGame';
  static final AppLogService _log = AppLogService.instance;
  final math.Random _random = math.Random();

  late List<int> _tiles;
  Timer? _timer;
  int? _selected;
  int? _dragOrigin;
  Offset? _dragStart;
  bool _dragSwapConsumed = false;
  int _score = 0;
  int _moves = 0;
  int _remainingSeconds = _initialSeconds;
  int _lastTimeBonus = 0;
  int _chain = 0;
  int _lastCleared = 0;
  int _maxChain = 1;
  int _totalCleared = 0;
  int _totalTimeBonus = 0;
  int _blockersCleared = 0;
  int _invalidSwaps = 0;
  int _autoReshuffles = 0;
  Set<int> _clearingTiles = <int>{};
  bool _resolving = false;
  DateTime? _resolvingSince;
  bool _resultDialogOpen = false;
  _MatchThreeStatus _status = _MatchThreeStatus.ready;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _newGame() {
    _timer?.cancel();
    setState(() {
      _tiles = _generateBoard();
      _selected = null;
      _score = 0;
      _moves = 0;
      _remainingSeconds = _initialSeconds;
      _lastTimeBonus = 0;
      _chain = 0;
      _lastCleared = 0;
      _maxChain = 1;
      _totalCleared = 0;
      _totalTimeBonus = 0;
      _blockersCleared = 0;
      _invalidSwaps = 0;
      _autoReshuffles = 0;
      _clearingTiles = <int>{};
      _dragOrigin = null;
      _dragStart = null;
      _dragSwapConsumed = false;
      _resolving = false;
      _resolvingSince = null;
      _resultDialogOpen = false;
      _status = _MatchThreeStatus.ready;
    });
    _log.i(_logTag, 'match3.new_game', data: _boardDiagnostics());
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted ||
          _resolving ||
          _status == _MatchThreeStatus.won ||
          _status == _MatchThreeStatus.timeUp) {
        return;
      }
      setState(() {
        _remainingSeconds = math.max(0, _remainingSeconds - 1);
        if (_remainingSeconds <= 0) {
          _selected = null;
          _resetTileDrag();
          _status = _MatchThreeStatus.timeUp;
        }
      });
      if (_status == _MatchThreeStatus.timeUp) {
        _timer?.cancel();
        _log.i(_logTag, 'match3.timer.time_up', data: _boardDiagnostics());
        _showResultReportIfNeeded();
      }
    });
  }

  List<int> _generateBoard() {
    for (var attempt = 0; attempt < 80; attempt += 1) {
      final tiles = List<int>.filled(_rows * _cols, 0);
      for (var row = 0; row < _rows; row += 1) {
        for (var col = 0; col < _cols; col += 1) {
          final blocked = <int>{};
          if (col >= 2 &&
              _kindOf(tiles[_indexOf(row, col - 1)]) ==
                  _kindOf(tiles[_indexOf(row, col - 2)])) {
            blocked.add(_kindOf(tiles[_indexOf(row, col - 1)]));
          }
          if (row >= 2 &&
              _kindOf(tiles[_indexOf(row - 1, col)]) ==
                  _kindOf(tiles[_indexOf(row - 2, col)])) {
            blocked.add(_kindOf(tiles[_indexOf(row - 1, col)]));
          }
          final choices = <int>[
            for (var kind = 0; kind < _kinds; kind += 1)
              if (!blocked.contains(kind)) kind,
          ];
          tiles[_indexOf(row, col)] = _tileValue(
            choices[_random.nextInt(choices.length)],
          );
        }
      }
      if (_hasAnyMove(tiles)) {
        return tiles;
      }
    }
    return List<int>.generate(
      _rows * _cols,
      (_) => _tileValue(_random.nextInt(_kinds)),
    );
  }

  int _indexOf(int row, int col) => row * _cols + col;

  int _rowOf(int index) => index ~/ _cols;

  int _colOf(int index) => index % _cols;

  int _tileValue(int kind, [_MatchThreePower power = _MatchThreePower.none]) {
    return kind + power.index * _kinds;
  }

  int _kindOf(int value) => value < 0 ? -1 : value % _kinds;

  _MatchThreePower _powerOf(int value) {
    if (value < 0) {
      return _MatchThreePower.none;
    }
    final index = value ~/ _kinds;
    if (index < 0 || index >= _MatchThreePower.values.length) {
      return _MatchThreePower.none;
    }
    return _MatchThreePower.values[index];
  }

  int get _targetBlockerCount => math.min(7, _score ~/ 260);

  bool _isSwappableIndex(int index) {
    return index >= 0 && index < _tiles.length && _tiles[index] >= 0;
  }

  bool get _gameFinished {
    return _status == _MatchThreeStatus.won ||
        _status == _MatchThreeStatus.timeUp;
  }

  Map<String, Object?> _boardDiagnostics({
    int? origin,
    int? target,
    String? reason,
  }) {
    var normalTiles = 0;
    var powerTiles = 0;
    var blockers = 0;
    var emptyTiles = 0;
    for (final value in _tiles) {
      if (value == _blockerTile) {
        blockers += 1;
      } else if (value == _emptyTile) {
        emptyTiles += 1;
      } else if (_powerOf(value) == _MatchThreePower.none) {
        normalTiles += 1;
      } else {
        powerTiles += 1;
      }
    }
    final data = <String, Object?>{
      'status': _status.name,
      'score': _score,
      'moves': _moves,
      'remainingSeconds': _remainingSeconds,
      'resolving': _resolving,
      'resolvingAgeMs': _resolvingSince == null
          ? null
          : DateTime.now().difference(_resolvingSince!).inMilliseconds,
      'selected': _selected,
      'dragOrigin': _dragOrigin,
      'dragSwapConsumed': _dragSwapConsumed,
      'clearingTiles': _clearingTiles.length,
      'validMoves': _validMoveCount(_tiles, stopAt: 20),
      'normalTiles': normalTiles,
      'powerTiles': powerTiles,
      'blockers': blockers,
      'emptyTiles': emptyTiles,
    };
    if (reason != null) {
      data['reason'] = reason;
    }
    if (origin != null) {
      data['origin'] = origin;
    }
    if (target != null) {
      data['target'] = target;
    }
    return data;
  }

  void _resetTileDrag() {
    _dragOrigin = null;
    _dragStart = null;
    _dragSwapConsumed = false;
  }

  bool _recoverInteractionIfNeeded(String reason) {
    if (_gameFinished || _remainingSeconds <= 0) {
      return false;
    }
    var recovered = false;
    final resolvingAge = _resolvingSince == null
        ? Duration.zero
        : DateTime.now().difference(_resolvingSince!);
    final staleResolving = resolvingAge > const Duration(seconds: 4);
    if (_resolving &&
        _clearingTiles.isEmpty &&
        (_status != _MatchThreeStatus.clearing || staleResolving)) {
      _resolving = false;
      _resolvingSince = null;
      _selected = null;
      _resetTileDrag();
      _status = _MatchThreeStatus.ready;
      recovered = true;
    }
    if (!_resolving && !_hasAnyMove(_tiles)) {
      _tiles = _generateBoard();
      _syncDifficultyBlockers(reason: 'recovery:$reason');
      _selected = null;
      _resetTileDrag();
      _status = _MatchThreeStatus.reshuffled;
      _autoReshuffles += 1;
      recovered = true;
    }
    if (recovered) {
      _log.w(
        _logTag,
        'match3.interaction.recovered',
        data: _boardDiagnostics(reason: reason),
      );
    }
    return recovered;
  }

  void _recoverInteractionWithSetState(String reason) {
    if (!mounted || _gameFinished || _remainingSeconds <= 0) {
      return;
    }
    setState(() {
      _recoverInteractionIfNeeded(reason);
    });
  }

  bool _areAdjacent(int a, int b) {
    return (_rowOf(a) == _rowOf(b) && (_colOf(a) - _colOf(b)).abs() == 1) ||
        (_colOf(a) == _colOf(b) && (_rowOf(a) - _rowOf(b)).abs() == 1);
  }

  void _handleTileTap(int index) {
    if (_resolving || _gameFinished) {
      return;
    }
    if (!_isSwappableIndex(index)) {
      setState(() {
        _selected = null;
        _status = _MatchThreeStatus.ready;
      });
      return;
    }
    final selected = _selected;
    if (selected == null) {
      setState(() {
        _selected = index;
        _status = _MatchThreeStatus.selected;
      });
      return;
    }
    if (selected == index) {
      setState(() {
        _selected = null;
        _status = _MatchThreeStatus.ready;
      });
      return;
    }
    if (_areAdjacent(selected, index)) {
      unawaited(_attemptSwap(selected, index));
      return;
    }
    setState(() {
      _selected = index;
      _status = _MatchThreeStatus.selected;
    });
  }

  int? _boardIndexFromLocalPosition(Offset position, double boardSize) {
    if (position.dx < 0 ||
        position.dy < 0 ||
        position.dx >= boardSize ||
        position.dy >= boardSize) {
      return null;
    }
    final cellSize = boardSize / _cols;
    final row = (position.dy / cellSize).floor();
    final col = (position.dx / cellSize).floor();
    if (row < 0 || row >= _rows || col < 0 || col >= _cols) {
      return null;
    }
    return _indexOf(row, col);
  }

  void _logDragRejected({
    required String reason,
    int? origin,
    int? target,
    Offset? position,
  }) {
    _log.d(
      _logTag,
      'match3.drag.rejected',
      data: <String, Object?>{
        ..._boardDiagnostics(origin: origin, target: target, reason: reason),
        if (position != null) 'x': position.dx.round(),
        if (position != null) 'y': position.dy.round(),
      },
    );
  }

  void _handleBoardDragStart(Offset localPosition, double boardSize) {
    _recoverInteractionWithSetState('drag_start');
    _resetTileDrag();
    if (_resolving || _remainingSeconds <= 0 || _gameFinished) {
      _logDragRejected(reason: 'locked_or_finished', position: localPosition);
      return;
    }
    final origin = _boardIndexFromLocalPosition(localPosition, boardSize);
    if (origin == null || !_isSwappableIndex(origin)) {
      setState(() {
        _selected = null;
        _status = _MatchThreeStatus.ready;
      });
      _logDragRejected(
        reason: origin == null ? 'origin_out_of_board' : 'origin_not_swappable',
        origin: origin,
        position: localPosition,
      );
      return;
    }
    setState(() {
      _dragOrigin = origin;
      _dragStart = localPosition;
      _dragSwapConsumed = false;
      _selected = origin;
      _status = _MatchThreeStatus.selected;
    });
  }

  void _handleBoardDragUpdate(Offset localPosition, double cellSize) {
    final origin = _dragOrigin;
    final start = _dragStart;
    if (_dragSwapConsumed || origin == null || start == null) {
      return;
    }
    final delta = localPosition - start;
    final threshold = math.max(18.0, cellSize * 0.38);
    final absX = delta.dx.abs();
    final absY = delta.dy.abs();
    if (math.max(absX, absY) < threshold) {
      return;
    }
    final horizontal = absX > absY * 1.18;
    final vertical = absY > absX * 1.18;
    if (!horizontal && !vertical) {
      return;
    }
    final row = _rowOf(origin);
    final col = _colOf(origin);
    final target = horizontal
        ? _indexOf(row, col + (delta.dx > 0 ? 1 : -1))
        : _indexOf(row + (delta.dy > 0 ? 1 : -1), col);
    if (target < 0 ||
        target >= _tiles.length ||
        !_areAdjacent(origin, target) ||
        !_isSwappableIndex(target)) {
      setState(() {
        _selected = null;
        _status = _MatchThreeStatus.ready;
      });
      _logDragRejected(
        reason: 'target_not_swappable',
        origin: origin,
        target: target,
        position: localPosition,
      );
      _resetTileDrag();
      return;
    }
    _dragSwapConsumed = true;
    setState(() {
      _selected = origin;
      _status = _MatchThreeStatus.selected;
    });
    unawaited(_attemptSwap(origin, target));
  }

  void _handleBoardDragEnd() {
    if (_dragOrigin != null && !_dragSwapConsumed && mounted && !_resolving) {
      setState(() {
        _selected = null;
        if (!_gameFinished) {
          _status = _MatchThreeStatus.ready;
        }
      });
    }
    _resetTileDrag();
  }

  Future<void> _attemptSwap(int first, int second) async {
    if (_resolving || _remainingSeconds <= 0 || _gameFinished) {
      _log.d(
        _logTag,
        'match3.swap.rejected',
        data: _boardDiagnostics(
          origin: first,
          target: second,
          reason: 'locked_or_finished',
        ),
      );
      _resetTileDrag();
      return;
    }
    if (!_areAdjacent(first, second) ||
        !_isSwappableIndex(first) ||
        !_isSwappableIndex(second)) {
      setState(() {
        _invalidSwaps += 1;
        _selected = null;
        _status = _MatchThreeStatus.invalid;
      });
      _log.d(
        _logTag,
        'match3.swap.invalid_target',
        data: _boardDiagnostics(
          origin: first,
          target: second,
          reason: 'not_adjacent_or_not_swappable',
        ),
      );
      _resetTileDrag();
      return;
    }
    var swapped = false;
    var swapCommitted = false;
    try {
      setState(() {
        _resolving = true;
        _resolvingSince = DateTime.now();
        _selected = null;
        _swap(_tiles, first, second);
        swapped = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 90));
      final runs = _findRuns(_tiles);
      final activations = _swapActivations(
        first,
        second,
        hasMatchAfterSwap: runs.isNotEmpty,
      );
      if (runs.isEmpty && activations.isEmpty) {
        if (!mounted) {
          return;
        }
        setState(() {
          _swap(_tiles, first, second);
          swapped = false;
          _invalidSwaps += 1;
          _resolving = false;
          _resolvingSince = null;
          _resetTileDrag();
          _status = _MatchThreeStatus.invalid;
        });
        _log.d(
          _logTag,
          'match3.swap.no_match',
          data: _boardDiagnostics(
            origin: first,
            target: second,
            reason: 'no_runs_or_power_activation',
          ),
        );
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _moves += 1;
        _status = _MatchThreeStatus.clearing;
      });
      swapCommitted = true;
      await _resolveBoard(
        runs: runs,
        activations: activations,
        creationHints: <int>[second, first],
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _resolving = false;
        _resolvingSince = null;
        _resetTileDrag();
        _syncDifficultyBlockers(reason: 'resolve_complete');
        if (_score >= _targetScore) {
          _status = _MatchThreeStatus.won;
          _timer?.cancel();
        } else if (_remainingSeconds <= 0) {
          _status = _MatchThreeStatus.timeUp;
          _timer?.cancel();
        } else if (!_hasAnyMove(_tiles)) {
          _tiles = _generateBoard();
          _syncDifficultyBlockers(reason: 'no_moves_after_resolve');
          _selected = null;
          _status = _MatchThreeStatus.reshuffled;
          _autoReshuffles += 1;
          _log.w(
            _logTag,
            'match3.board.reshuffled',
            data: _boardDiagnostics(reason: 'no_moves_after_resolve'),
          );
        } else {
          _status = _MatchThreeStatus.ready;
        }
        _recoverInteractionIfNeeded('resolve_complete');
      });
      _log.d(
        _logTag,
        'match3.swap.resolved',
        data: _boardDiagnostics(origin: first, target: second),
      );
      if (_status == _MatchThreeStatus.won) {
        unawaited(HapticFeedback.mediumImpact());
      }
      if (_gameFinished) {
        _showResultReportIfNeeded();
      }
    } catch (error, stackTrace) {
      _log.e(
        _logTag,
        'match3.swap.exception',
        error: error,
        stackTrace: stackTrace,
        data: _boardDiagnostics(
          origin: first,
          target: second,
          reason: 'swap_exception',
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        if (swapped && !swapCommitted) {
          _swap(_tiles, first, second);
        }
        _resolving = false;
        _resolvingSince = null;
        _clearingTiles = <int>{};
        _selected = null;
        _resetTileDrag();
        if (!_gameFinished && _remainingSeconds > 0) {
          _status = _MatchThreeStatus.ready;
        }
        _recoverInteractionIfNeeded('swap_exception');
      });
    }
  }

  Future<void> _resolveBoard({
    required List<_MatchThreeRun> runs,
    List<_MatchThreeActivation> activations = const <_MatchThreeActivation>[],
    List<int> creationHints = const <int>[],
  }) async {
    var currentRuns = runs;
    var currentActivations = activations;
    var currentCreationHints = creationHints;
    var chain = 1;
    while (mounted) {
      final clearPlan = _buildClearPlan(
        runs: currentRuns,
        activations: currentActivations,
        creationHints: currentCreationHints,
      );
      final currentMatches = clearPlan.clearIndexes;
      if (currentMatches.isEmpty) {
        return;
      }
      final clearingTiles = Set<int>.of(currentMatches);
      final blockerClears = currentMatches
          .where((index) => _tiles[index] == _blockerTile)
          .length;
      final timeBonus = _timeBonusFor(currentMatches.length, chain);
      setState(() {
        _chain = chain;
        _maxChain = math.max(_maxChain, chain);
        _lastCleared = currentMatches.length;
        _lastTimeBonus = timeBonus;
        _totalCleared += currentMatches.length;
        _totalTimeBonus += timeBonus;
        _blockersCleared += blockerClears;
        _remainingSeconds = math.min(
          _maxSeconds,
          _remainingSeconds + timeBonus,
        );
        _score += currentMatches.length * 10 * chain;
        _clearingTiles = clearingTiles;
        final creation = clearPlan.creation;
        if (creation != null) {
          _tiles[creation.index] = _tileValue(creation.kind, creation.power);
        }
      });
      await Future<void>.delayed(const Duration(milliseconds: 170));
      if (!mounted) {
        return;
      }
      setState(() {
        for (final index in currentMatches) {
          _tiles[index] = _emptyTile;
        }
        _clearingTiles = <int>{};
      });
      setState(_dropAndFill);
      await Future<void>.delayed(const Duration(milliseconds: 130));
      currentRuns = _findRuns(_tiles);
      currentActivations = const <_MatchThreeActivation>[];
      currentCreationHints = const <int>[];
      chain += 1;
    }
  }

  int _timeBonusFor(int clearedCount, int chain) {
    final countBonus = clearedCount ~/ 4;
    final chainBonus = math.max(0, chain - 1);
    return math.min(12, 2 + countBonus + chainBonus);
  }

  Set<int> _findMatches(List<int> tiles) {
    return <int>{for (final run in _findRuns(tiles)) ...run.indexes};
  }

  List<_MatchThreeRun> _findRuns(List<int> tiles) {
    final runs = <_MatchThreeRun>[];
    bool sameKind(int current, int previous) {
      return current >= 0 &&
          previous >= 0 &&
          _kindOf(current) == _kindOf(previous);
    }

    void addRun({
      required int start,
      required int endExclusive,
      required bool horizontal,
      required int fixed,
    }) {
      if (endExclusive - start < 3) {
        return;
      }
      final firstIndex = horizontal
          ? _indexOf(fixed, start)
          : _indexOf(start, fixed);
      final kind = _kindOf(tiles[firstIndex]);
      if (kind < 0) {
        return;
      }
      runs.add(
        _MatchThreeRun(
          indexes: <int>[
            for (var value = start; value < endExclusive; value += 1)
              horizontal ? _indexOf(fixed, value) : _indexOf(value, fixed),
          ],
          kind: kind,
          horizontal: horizontal,
        ),
      );
    }

    for (var row = 0; row < _rows; row += 1) {
      var runStart = 0;
      for (var col = 1; col <= _cols; col += 1) {
        final same =
            col < _cols &&
            sameKind(tiles[_indexOf(row, col)], tiles[_indexOf(row, col - 1)]);
        if (same) {
          continue;
        }
        addRun(
          start: runStart,
          endExclusive: col,
          horizontal: true,
          fixed: row,
        );
        runStart = col;
      }
    }
    for (var col = 0; col < _cols; col += 1) {
      var runStart = 0;
      for (var row = 1; row <= _rows; row += 1) {
        final same =
            row < _rows &&
            sameKind(tiles[_indexOf(row, col)], tiles[_indexOf(row - 1, col)]);
        if (same) {
          continue;
        }
        addRun(
          start: runStart,
          endExclusive: row,
          horizontal: false,
          fixed: col,
        );
        runStart = row;
      }
    }
    return runs;
  }

  List<_MatchThreeActivation> _swapActivations(
    int first,
    int second, {
    required bool hasMatchAfterSwap,
  }) {
    final activations = <_MatchThreeActivation>[];
    final firstPower = _powerOf(_tiles[first]);
    final secondPower = _powerOf(_tiles[second]);
    if (!hasMatchAfterSwap &&
        firstPower != _MatchThreePower.none &&
        secondPower != _MatchThreePower.none) {
      return activations;
    }

    void addIfPowered(int index, int otherIndex) {
      final power = _powerOf(_tiles[index]);
      if (power == _MatchThreePower.none) {
        return;
      }
      activations.add(
        _MatchThreeActivation(
          index: index,
          targetKind: _rainbowTargetKind(index, otherIndex),
        ),
      );
    }

    addIfPowered(first, second);
    addIfPowered(second, first);
    return activations;
  }

  int? _rainbowTargetKind(int rainbowIndex, int otherIndex) {
    if (_powerOf(_tiles[rainbowIndex]) != _MatchThreePower.rainbow) {
      return null;
    }
    if (_powerOf(_tiles[otherIndex]) == _MatchThreePower.rainbow) {
      return null;
    }
    final kind = _kindOf(_tiles[otherIndex]);
    return kind >= 0 ? kind : null;
  }

  _MatchThreeClearPlan _buildClearPlan({
    required List<_MatchThreeRun> runs,
    required List<_MatchThreeActivation> activations,
    required List<int> creationHints,
  }) {
    final matches = <int>{for (final run in runs) ...run.indexes};
    final creation = _choosePowerCreation(runs, creationHints);
    if (creation != null) {
      matches.remove(creation.index);
    }
    final clearIndexes = _expandPowerClears(
      matches,
      activations,
      preservedIndex: creation?.index,
    );
    return _MatchThreeClearPlan(clearIndexes: clearIndexes, creation: creation);
  }

  _MatchThreePowerCreation? _choosePowerCreation(
    List<_MatchThreeRun> runs,
    List<int> hints,
  ) {
    if (runs.isEmpty) {
      return null;
    }
    final runsByIndex = <int, List<_MatchThreeRun>>{};
    for (final run in runs) {
      for (final index in run.indexes) {
        (runsByIndex[index] ??= <_MatchThreeRun>[]).add(run);
      }
    }

    _MatchThreePowerCreation? creationFor(int index) {
      if (index < 0 ||
          index >= _tiles.length ||
          _tiles[index] < 0 ||
          _powerOf(_tiles[index]) != _MatchThreePower.none) {
        return null;
      }
      final indexRuns = runsByIndex[index];
      if (indexRuns == null || indexRuns.isEmpty) {
        return null;
      }
      final power = _powerForRuns(indexRuns);
      if (power == _MatchThreePower.none) {
        return null;
      }
      return _MatchThreePowerCreation(
        index: index,
        kind: _kindOf(_tiles[index]),
        power: power,
      );
    }

    for (final hint in hints) {
      final creation = creationFor(hint);
      if (creation != null) {
        return creation;
      }
    }

    final candidates = <_MatchThreePowerCreation>[
      for (final index in runsByIndex.keys) ?creationFor(index),
    ];
    if (candidates.isEmpty) {
      return null;
    }
    candidates.sort((a, b) {
      final powerCompare = _powerPriority(b.power) - _powerPriority(a.power);
      if (powerCompare != 0) {
        return powerCompare;
      }
      final lengthCompare =
          _longestRunAt(runsByIndex[b.index]!) -
          _longestRunAt(runsByIndex[a.index]!);
      if (lengthCompare != 0) {
        return lengthCompare;
      }
      final centerCompare =
          _centerDistance(a.index, runsByIndex[a.index]!) -
          _centerDistance(b.index, runsByIndex[b.index]!);
      if (centerCompare != 0) {
        return centerCompare;
      }
      return a.index.compareTo(b.index);
    });
    return candidates.first;
  }

  _MatchThreePower _powerForRuns(List<_MatchThreeRun> runs) {
    if (runs.any((run) => run.length >= 5)) {
      return _MatchThreePower.rainbow;
    }
    final hasHorizontal = runs.any((run) => run.horizontal);
    final hasVertical = runs.any((run) => !run.horizontal);
    if (hasHorizontal && hasVertical) {
      return _MatchThreePower.bomb;
    }
    final longRun = runs
        .where((run) => run.length >= 4)
        .fold<_MatchThreeRun?>(
          null,
          (best, run) => best == null || run.length > best.length ? run : best,
        );
    if (longRun == null) {
      return _MatchThreePower.none;
    }
    return longRun.horizontal ? _MatchThreePower.row : _MatchThreePower.column;
  }

  int _powerPriority(_MatchThreePower power) {
    return switch (power) {
      _MatchThreePower.rainbow => 4,
      _MatchThreePower.bomb => 3,
      _MatchThreePower.row || _MatchThreePower.column => 2,
      _MatchThreePower.none => 0,
    };
  }

  int _longestRunAt(List<_MatchThreeRun> runs) {
    return runs.fold<int>(0, (best, run) => math.max(best, run.length));
  }

  int _centerDistance(int index, List<_MatchThreeRun> runs) {
    return runs.fold<int>(_rows + _cols, (best, run) {
      final center = run.indexes[run.length ~/ 2];
      final distance =
          (_rowOf(index) - _rowOf(center)).abs() +
          (_colOf(index) - _colOf(center)).abs();
      return math.min(best, distance);
    });
  }

  Set<int> _expandPowerClears(
    Set<int> baseClearIndexes,
    List<_MatchThreeActivation> activations, {
    int? preservedIndex,
  }) {
    final clearIndexes = <int>{...baseClearIndexes};
    final queue = Queue<_MatchThreeActivation>();
    final processed = <int>{};

    for (final index in baseClearIndexes) {
      final power = _powerOf(_tiles[index]);
      if (power == _MatchThreePower.none) {
        continue;
      }
      queue.add(
        _MatchThreeActivation(
          index: index,
          targetKind: power == _MatchThreePower.rainbow
              ? _kindOf(_tiles[index])
              : null,
        ),
      );
    }
    queue.addAll(activations);

    while (queue.isNotEmpty) {
      final activation = queue.removeFirst();
      if (!processed.add(activation.index) ||
          activation.index < 0 ||
          activation.index >= _tiles.length ||
          _tiles[activation.index] < 0) {
        continue;
      }
      final power = _powerOf(_tiles[activation.index]);
      if (power == _MatchThreePower.none) {
        continue;
      }
      clearIndexes.add(activation.index);
      for (final index in _affectedByPower(
        activation.index,
        power,
        activation.targetKind,
      )) {
        if (index == preservedIndex ||
            _tiles[index] == _emptyTile ||
            (power == _MatchThreePower.rainbow &&
                _tiles[index] == _blockerTile)) {
          continue;
        }
        clearIndexes.add(index);
        if (_tiles[index] == _blockerTile) {
          continue;
        }
        final chainedPower = _powerOf(_tiles[index]);
        if (chainedPower != _MatchThreePower.none &&
            !processed.contains(index)) {
          queue.add(
            _MatchThreeActivation(
              index: index,
              targetKind: chainedPower == _MatchThreePower.rainbow
                  ? _kindOf(_tiles[index])
                  : null,
            ),
          );
        }
      }
    }

    if (preservedIndex != null) {
      clearIndexes.remove(preservedIndex);
    }
    return clearIndexes;
  }

  Iterable<int> _affectedByPower(
    int index,
    _MatchThreePower power,
    int? targetKind,
  ) sync* {
    switch (power) {
      case _MatchThreePower.none:
        return;
      case _MatchThreePower.row:
        final row = _rowOf(index);
        for (var col = 0; col < _cols; col += 1) {
          yield _indexOf(row, col);
        }
      case _MatchThreePower.column:
        final col = _colOf(index);
        for (var row = 0; row < _rows; row += 1) {
          yield _indexOf(row, col);
        }
      case _MatchThreePower.bomb:
        final centerRow = _rowOf(index);
        final centerCol = _colOf(index);
        for (var row = centerRow - 1; row <= centerRow + 1; row += 1) {
          if (row < 0 || row >= _rows) {
            continue;
          }
          for (var col = centerCol - 1; col <= centerCol + 1; col += 1) {
            if (col < 0 || col >= _cols) {
              continue;
            }
            yield _indexOf(row, col);
          }
        }
      case _MatchThreePower.rainbow:
        for (var tileIndex = 0; tileIndex < _tiles.length; tileIndex += 1) {
          if (_tiles[tileIndex] < 0) {
            continue;
          }
          if (targetKind == null || _kindOf(_tiles[tileIndex]) == targetKind) {
            yield tileIndex;
          }
        }
    }
  }

  bool _hasAnyMove(List<int> tiles) {
    return _validMoveCount(tiles, stopAt: 1) > 0;
  }

  int _validMoveCount(List<int> tiles, {int stopAt = _minimumPlayableMoves}) {
    var count = 0;
    final copy = List<int>.of(tiles);
    bool countPair(int first, int second) {
      if (copy[first] < 0 || copy[second] < 0) {
        return false;
      }
      final firstPower = _powerOf(copy[first]);
      final secondPower = _powerOf(copy[second]);
      if (firstPower != _MatchThreePower.none ||
          secondPower != _MatchThreePower.none) {
        if (firstPower == _MatchThreePower.none ||
            secondPower == _MatchThreePower.none) {
          count += 1;
          return count >= stopAt;
        }
        _swap(copy, first, second);
        final hasMatch = _findMatches(copy).isNotEmpty;
        _swap(copy, first, second);
        if (hasMatch) {
          count += 1;
        }
        return count >= stopAt;
      }
      _swap(copy, first, second);
      final hasMatch = _findMatches(copy).isNotEmpty;
      _swap(copy, first, second);
      if (hasMatch) {
        count += 1;
      }
      return count >= stopAt;
    }

    for (var row = 0; row < _rows; row += 1) {
      for (var col = 0; col < _cols; col += 1) {
        final index = _indexOf(row, col);
        if (copy[index] < 0) {
          continue;
        }
        if (col + 1 < _cols) {
          final right = _indexOf(row, col + 1);
          if (countPair(index, right)) {
            return count;
          }
        }
        if (row + 1 < _rows) {
          final down = _indexOf(row + 1, col);
          if (countPair(index, down)) {
            return count;
          }
        }
      }
    }
    return count;
  }

  void _dropAndFill() {
    for (var col = 0; col < _cols; col += 1) {
      var segmentBottom = _rows - 1;
      while (segmentBottom >= 0) {
        if (_tiles[_indexOf(segmentBottom, col)] == _blockerTile) {
          segmentBottom -= 1;
          continue;
        }
        var segmentTop = segmentBottom;
        while (segmentTop >= 0 &&
            _tiles[_indexOf(segmentTop, col)] != _blockerTile) {
          segmentTop -= 1;
        }
        final kept = <int>[];
        for (var row = segmentBottom; row > segmentTop; row -= 1) {
          final value = _tiles[_indexOf(row, col)];
          if (value >= 0) {
            kept.add(value);
          }
        }
        for (var row = segmentBottom; row > segmentTop; row -= 1) {
          final keptIndex = segmentBottom - row;
          _tiles[_indexOf(row, col)] = keptIndex < kept.length
              ? kept[keptIndex]
              : _tileValue(_random.nextInt(_kinds));
        }
        segmentBottom = segmentTop - 1;
      }
    }
  }

  int _syncDifficultyBlockers({required String reason}) {
    final current = _tiles.where((value) => value == _blockerTile).length;
    final target = _targetBlockerCount;
    var needed = _targetBlockerCount - current;
    if (needed <= 0) {
      return 0;
    }
    var placedCount = 0;
    var rejectedCount = 0;
    var stopReason = 'target_reached';
    while (needed > 0) {
      final candidates = <int>[
        for (var index = 0; index < _tiles.length; index += 1)
          if (_tiles[index] >= 0 &&
              _powerOf(_tiles[index]) == _MatchThreePower.none &&
              _rowOf(index) > 0 &&
              _blockerNeighborCount(index) == 0)
            index,
      ];
      if (candidates.isEmpty) {
        stopReason = 'no_candidates';
        break;
      }
      candidates.shuffle(_random);
      var placed = false;
      for (final index in candidates) {
        final previous = _tiles[index];
        _tiles[index] = _blockerTile;
        if (_validMoveCount(_tiles) < _minimumPlayableMoves) {
          _tiles[index] = previous;
          rejectedCount += 1;
          continue;
        }
        placed = true;
        placedCount += 1;
        needed -= 1;
        break;
      }
      if (!placed) {
        stopReason = 'no_safe_candidate';
        break;
      }
    }
    _log.d(
      _logTag,
      'match3.blockers.sync',
      data: <String, Object?>{
        ..._boardDiagnostics(reason: reason),
        'targetBlockers': target,
        'previousBlockers': current,
        'placedBlockers': placedCount,
        'rejectedCandidates': rejectedCount,
        'stopReason': stopReason,
      },
    );
    return placedCount;
  }

  int _blockerNeighborCount(int index) {
    final row = _rowOf(index);
    final col = _colOf(index);
    var count = 0;
    for (final neighbor in <int>[
      if (row > 0) _indexOf(row - 1, col),
      if (row + 1 < _rows) _indexOf(row + 1, col),
      if (col > 0) _indexOf(row, col - 1),
      if (col + 1 < _cols) _indexOf(row, col + 1),
    ]) {
      if (_tiles[neighbor] == _blockerTile) {
        count += 1;
      }
    }
    return count;
  }

  void _swap(List<int> tiles, int a, int b) {
    final value = tiles[a];
    tiles[a] = tiles[b];
    tiles[b] = value;
  }

  void _reshuffle() {
    if (_resolving || _gameFinished) {
      return;
    }
    setState(() {
      _tiles = _generateBoard();
      _syncDifficultyBlockers(reason: 'manual_reshuffle');
      _selected = null;
      _resetTileDrag();
      _status = _MatchThreeStatus.reshuffled;
    });
    _log.i(
      _logTag,
      'match3.board.reshuffled',
      data: _boardDiagnostics(reason: 'manual_reshuffle'),
    );
  }

  String _reportResultLabel(AppI18n i18n, _MatchThreeStatus status) {
    return switch (status) {
      _MatchThreeStatus.won => i18n.t('toolbox.miniGames.match3.report.won'),
      _MatchThreeStatus.timeUp => i18n.t(
        'toolbox.miniGames.match3.report.time_up',
      ),
      _ => _statusLabel(i18n),
    };
  }

  Map<String, Object?> _resultReportDiagnostics(
    _MatchThreeStatus resultStatus,
  ) {
    return <String, Object?>{
      ..._boardDiagnostics(reason: 'end_report'),
      'result': resultStatus.name,
      'maxChain': _maxChain,
      'totalCleared': _totalCleared,
      'totalTimeBonus': _totalTimeBonus,
      'blockersCleared': _blockersCleared,
      'invalidSwaps': _invalidSwaps,
      'autoReshuffles': _autoReshuffles,
    };
  }

  void _showResultReportIfNeeded() {
    if (!mounted || !_gameFinished || _resultDialogOpen) {
      return;
    }
    _resultDialogOpen = true;
    final resultStatus = _status;
    _log.i(
      _logTag,
      'match3.end_report',
      data: _resultReportDiagnostics(resultStatus),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_gameFinished) {
        _resultDialogOpen = false;
        return;
      }
      final i18n = AppI18n(Localizations.localeOf(context).languageCode);
      unawaited(
        showDialog<void>(
          context: context,
          builder: (dialogContext) {
            Widget reportRow(String label, String value) {
              final theme = Theme.of(dialogContext);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(label, style: theme.textTheme.bodyMedium),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }

            return AlertDialog(
              title: Text(i18n.t('toolbox.miniGames.match3.report.title')),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    reportRow(
                      i18n.t('toolbox.miniGames.match3.report.result'),
                      _reportResultLabel(i18n, resultStatus),
                    ),
                    reportRow(
                      i18n.t('toolbox.miniGames.match3.report.score'),
                      '$_score',
                    ),
                    reportRow(
                      i18n.t('toolbox.miniGames.match3.report.target'),
                      '$_targetScore',
                    ),
                    reportRow(
                      i18n.t('toolbox.miniGames.match3.report.moves'),
                      '$_moves',
                    ),
                    reportRow(
                      i18n.t('toolbox.miniGames.match3.report.max_chain'),
                      '${_maxChain}x',
                    ),
                    reportRow(
                      i18n.t('toolbox.miniGames.match3.report.cleared'),
                      '$_totalCleared',
                    ),
                    reportRow(
                      i18n.t(
                        'toolbox.miniGames.match3.report.time_bonus_seconds',
                      ),
                      '$_totalTimeBonus',
                    ),
                    reportRow(
                      i18n.t(
                        'toolbox.miniGames.match3.report.blockers_cleared',
                      ),
                      '$_blockersCleared',
                    ),
                    reportRow(
                      i18n.t('toolbox.miniGames.match3.report.invalid_swaps'),
                      '$_invalidSwaps',
                    ),
                    reportRow(
                      i18n.t('toolbox.miniGames.match3.report.auto_reshuffles'),
                      '$_autoReshuffles',
                    ),
                    reportRow(
                      i18n.t('toolbox.miniGames.match3.report.remaining_time'),
                      _formatTime(_remainingSeconds),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(i18n.t('close')),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _newGame();
                  },
                  child: Text(i18n.t('toolbox.miniGames.match3.action.new')),
                ),
              ],
            );
          },
        ).whenComplete(() {
          _resultDialogOpen = false;
        }),
      );
    });
  }

  String _statusLabel(AppI18n i18n) {
    return switch (_status) {
      _MatchThreeStatus.ready => i18n.t(
        'toolbox.miniGames.match3.status.ready',
      ),
      _MatchThreeStatus.selected => i18n.t(
        'toolbox.miniGames.match3.status.selected',
      ),
      _MatchThreeStatus.invalid => i18n.t(
        'toolbox.miniGames.match3.status.invalid',
      ),
      _MatchThreeStatus.clearing => i18n.t(
        'toolbox.miniGames.match3.status.clearing',
        params: <String, Object?>{
          'count': _lastCleared,
          'chain': _chain,
          'seconds': _lastTimeBonus,
        },
      ),
      _MatchThreeStatus.reshuffled => i18n.t(
        'toolbox.miniGames.match3.status.reshuffled',
      ),
      _MatchThreeStatus.won => i18n.t('toolbox.miniGames.match3.status.won'),
      _MatchThreeStatus.timeUp => i18n.t(
        'toolbox.miniGames.match3.status.time_up',
      ),
    };
  }

  String _powerLabel(AppI18n i18n, _MatchThreePower power) {
    return switch (power) {
      _MatchThreePower.row => i18n.t('toolbox.miniGames.match3.power.row'),
      _MatchThreePower.column => i18n.t(
        'toolbox.miniGames.match3.power.column',
      ),
      _MatchThreePower.bomb => i18n.t('toolbox.miniGames.match3.power.bomb'),
      _MatchThreePower.rainbow => i18n.t(
        'toolbox.miniGames.match3.power.rainbow',
      ),
      _MatchThreePower.none => '',
    };
  }

  IconData _powerIcon(_MatchThreePower power) {
    return switch (power) {
      _MatchThreePower.row => Icons.swap_horiz_rounded,
      _MatchThreePower.column => Icons.swap_vert_rounded,
      _MatchThreePower.bomb => Icons.blur_circular_rounded,
      _MatchThreePower.rainbow => Icons.auto_awesome_rounded,
      _MatchThreePower.none => Icons.circle_outlined,
    };
  }

  String _blockerLabel(AppI18n i18n) {
    return i18n.t('toolbox.miniGames.match3.obstacle.blocker');
  }

  Widget _buildPowerLegend(BuildContext context, AppI18n i18n) {
    final colors = Theme.of(context).colorScheme;
    Widget legendChip({
      required IconData icon,
      required String label,
      required Color iconColor,
    }) {
      return Tooltip(
        message: label,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final power in _matchThreeLegendPowers)
          legendChip(
            icon: _powerIcon(power),
            label: _powerLabel(i18n, power),
            iconColor: colors.primary,
          ),
        legendChip(
          icon: Icons.block_rounded,
          label: _blockerLabel(i18n),
          iconColor: colors.error,
        ),
      ],
    );
  }

  Widget _buildTileFace(int value, double cellSize) {
    final kind = _kindOf(value);
    final power = _powerOf(value);
    final baseIcon = Icon(
      _matchThreeIcons[kind],
      size: power == _MatchThreePower.none ? cellSize * 0.42 : cellSize * 0.34,
      color: Colors.white.withValues(
        alpha: power == _MatchThreePower.none ? 1 : 0.5,
      ),
    );
    if (power == _MatchThreePower.none) {
      return baseIcon;
    }
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        baseIcon,
        Container(
          width: cellSize * 0.58,
          height: cellSize * 0.58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
          ),
          child: Icon(
            _powerIcon(power),
            size: cellSize * 0.34,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildBlockerFace(BuildContext context, double cellSize) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Icon(
          Icons.grid_4x4_rounded,
          size: cellSize * 0.48,
          color: colors.onSurfaceVariant.withValues(alpha: 0.42),
        ),
        Icon(
          Icons.block_rounded,
          size: cellSize * 0.34,
          color: colors.error.withValues(alpha: 0.92),
        ),
      ],
    );
  }

  Widget _buildBoard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = math.min(420.0, constraints.maxWidth);
        final cellSize = boardSize / _cols;
        return Center(
          child: _MiniGameScrollLockSurface(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) =>
                  _handleBoardDragStart(event.localPosition, boardSize),
              onPointerMove: (event) =>
                  _handleBoardDragUpdate(event.localPosition, cellSize),
              onPointerUp: (_) => _handleBoardDragEnd(),
              onPointerCancel: (_) => _handleBoardDragEnd(),
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
                    final value = _tiles[index];
                    final selected = _selected == index;
                    final kind = _kindOf(value);
                    final power = _powerOf(value);
                    final blocker = value == _blockerTile;
                    final clearing = _clearingTiles.contains(index);
                    final specialClearing =
                        clearing && power != _MatchThreePower.none;
                    final color = value >= 0
                        ? _matchThreeColors[kind]
                        : blocker
                        ? colors.surfaceContainerHighest
                        : colors.surfaceContainerLowest;
                    final rainbow = power == _MatchThreePower.rainbow;
                    return GestureDetector(
                      onTap: () => _handleTileTap(index),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOutCubic,
                        scale: specialClearing
                            ? 1.12
                            : clearing
                            ? 0.72
                            : selected
                            ? 1.08
                            : 1,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 140),
                          opacity: clearing && !specialClearing ? 0.34 : 1,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            margin: EdgeInsets.all(cellSize <= 42 ? 2 : 3),
                            decoration: BoxDecoration(
                              color: rainbow
                                  ? null
                                  : color.withValues(
                                      alpha: value >= 0 || blocker ? 1 : 0.18,
                                    ),
                              gradient: rainbow
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: <Color>[
                                        Color(0xFFE95D7B),
                                        Color(0xFFF0B949),
                                        Color(0xFF43A971),
                                        Color(0xFF4D8FD6),
                                        Color(0xFF8B66D9),
                                      ],
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected || clearing
                                    ? colors.primary
                                    : blocker
                                    ? colors.error.withValues(alpha: 0.66)
                                    : Colors.white.withValues(
                                        alpha: power == _MatchThreePower.none
                                            ? 0.55
                                            : 0.82,
                                      ),
                                width: selected || specialClearing
                                    ? 2.2
                                    : clearing || power != _MatchThreePower.none
                                    ? 1.2
                                    : 0.8,
                              ),
                              boxShadow: value >= 0 || blocker
                                  ? <BoxShadow>[
                                      BoxShadow(
                                        color:
                                            (clearing
                                                    ? colors.primary
                                                    : blocker
                                                    ? colors.error
                                                    : color)
                                                .withValues(
                                                  alpha: clearing ? 0.34 : 0.2,
                                                ),
                                        blurRadius: clearing ? 14 : 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: value >= 0
                                ? _buildTileFace(value, cellSize)
                                : blocker
                                ? _buildBlockerFace(context, cellSize)
                                : null,
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

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '$minutes:${rest.toString().padLeft(2, '0')}';
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
                  label: i18n.t('toolbox.miniGames.match3.metric.score'),
                  value: '$_score',
                ),
                ToolboxMetricCard(
                  label: i18n.t('toolbox.miniGames.match3.metric.time'),
                  value: _formatTime(_remainingSeconds),
                ),
                ToolboxMetricCard(
                  label: i18n.t('toolbox.miniGames.match3.metric.moves'),
                  value: '$_moves',
                ),
                ToolboxMetricCard(
                  label: i18n.t('toolbox.miniGames.match3.metric.target'),
                  value: '$_targetScore',
                ),
                ToolboxMetricCard(
                  label: i18n.t('toolbox.miniGames.match3.metric.chain'),
                  value: _chain <= 1 ? '1' : '${_chain}x',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Text(
                _statusLabel(i18n),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
            _buildPowerLegend(context, i18n),
            const SizedBox(height: 12),
            _buildBoard(context),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: _newGame,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(i18n.t('toolbox.miniGames.match3.action.new')),
                ),
                OutlinedButton.icon(
                  onPressed: _reshuffle,
                  icon: const Icon(Icons.shuffle_rounded),
                  label: Text(
                    i18n.t('toolbox.miniGames.match3.action.reshuffle'),
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

const List<Color> _matchThreeColors = <Color>[
  Color(0xFFE95D7B),
  Color(0xFFF0B949),
  Color(0xFF43A971),
  Color(0xFF4D8FD6),
  Color(0xFF8B66D9),
  Color(0xFFDB7A45),
];

const List<IconData> _matchThreeIcons = <IconData>[
  Icons.favorite_rounded,
  Icons.star_rounded,
  Icons.eco_rounded,
  Icons.water_drop_rounded,
  Icons.hexagon_rounded,
  Icons.brightness_5_rounded,
];

const List<_MatchThreePower> _matchThreeLegendPowers = <_MatchThreePower>[
  _MatchThreePower.row,
  _MatchThreePower.column,
  _MatchThreePower.bomb,
  _MatchThreePower.rainbow,
];

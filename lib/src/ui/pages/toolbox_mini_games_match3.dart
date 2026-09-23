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
  Timer? _resolveDelayTimer;
  Completer<void>? _resolveDelayCompleter;
  int _resolveGeneration = 0;
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
    _cancelResolution();
    super.dispose();
  }

  void _newGame() {
    _timer?.cancel();
    _cancelResolution();
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
      _cancelResolution();
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

  void _setViewState(VoidCallback callback) => setState(callback);

  @override
  Widget build(BuildContext context) => _buildGameView(context);
}

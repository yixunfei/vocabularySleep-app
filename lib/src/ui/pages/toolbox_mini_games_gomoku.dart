part of 'toolbox_mini_games.dart';

enum _GomokuStone { empty, black, white }

enum _GomokuDifficulty { easy, medium, hard }

class _GomokuGame extends StatefulWidget {
  const _GomokuGame();

  @override
  State<_GomokuGame> createState() => _GomokuGameState();
}

class _GomokuGameState extends State<_GomokuGame> {
  static const int _size = 15;
  static const double _terminalScore = 1000000000;

  late List<_GomokuStone> _board;
  _GomokuStone _turn = _GomokuStone.black;
  _GomokuDifficulty _difficulty = _GomokuDifficulty.medium;
  final math.Random _random = math.Random();
  bool _aiThinking = false;
  bool _gameOver = false;
  bool _resultDialogOpen = false;
  int _moves = 0;
  int? _lastMove;
  int? _suggestedMove;
  String _status = 'Your turn (black)';
  bool _fullscreen = false;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  @override
  void dispose() {
    if (_fullscreen) {
      unawaited(_exitMiniGameFullscreen());
    }
    super.dispose();
  }

  int get _total => _size * _size;

  int _indexOf(int row, int col) => row * _size + col;

  bool _inBounds(int row, int col) {
    return row >= 0 && row < _size && col >= 0 && col < _size;
  }

  String _text(AppI18n i18n, {required String zh, required String en}) {
    return pickUiText(i18n, zh: zh, en: en);
  }

  _GomokuStone _opponent(_GomokuStone stone) {
    return stone == _GomokuStone.black
        ? _GomokuStone.white
        : _GomokuStone.black;
  }

  String _difficultyLabel(AppI18n i18n, _GomokuDifficulty difficulty) {
    return switch (difficulty) {
      _GomokuDifficulty.easy => _text(i18n, zh: '简单', en: 'Easy'),
      _GomokuDifficulty.medium => _text(i18n, zh: '标准', en: 'Medium'),
      _GomokuDifficulty.hard => _text(i18n, zh: '困难', en: 'Hard'),
    };
  }

  Widget _buildDifficultySelector(AppI18n i18n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final level in _GomokuDifficulty.values)
          ChoiceChip(
            label: Text(_difficultyLabel(i18n, level)),
            selected: _difficulty == level,
            onSelected: (_) {
              if (_difficulty == level) return;
              setState(() {
                _difficulty = level;
                _suggestedMove = null;
              });
            },
          ),
      ],
    );
  }

  Future<void> _setFullscreen(bool value) async {
    if (_fullscreen == value) {
      return;
    }
    setState(() {
      _fullscreen = value;
    });
    if (value) {
      await _enterMiniGameFullscreen(landscape: true);
    } else {
      await _exitMiniGameFullscreen();
    }
  }

  void _resetGame() {
    setState(() {
      _board = List<_GomokuStone>.filled(_total, _GomokuStone.empty);
      _turn = _GomokuStone.black;
      _aiThinking = false;
      _gameOver = false;
      _resultDialogOpen = false;
      _moves = 0;
      _lastMove = null;
      _suggestedMove = null;
      _status = 'Your turn (black)';
    });
  }

  void _finishGame({
    required String status,
    required String title,
    required String message,
  }) {
    setState(() {
      _gameOver = true;
      _status = status;
      _aiThinking = false;
    });
    unawaited(_showGameResultDialog(title: title, message: message));
  }

  Future<void> _showGameResultDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted || _resultDialogOpen) return;
    _resultDialogOpen = true;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_text(i18n, zh: '关闭', en: 'Close')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              child: Text(_text(i18n, zh: '新开一局', en: 'New game')),
            ),
          ],
        );
      },
    );
    _resultDialogOpen = false;
  }

  void _tapCell(int index) {
    if (_gameOver || _aiThinking || _turn != _GomokuStone.black) return;
    if (_board[index] != _GomokuStone.empty) return;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    setState(() {
      _board[index] = _GomokuStone.black;
      _moves += 1;
      _lastMove = index;
      _suggestedMove = null;
    });
    if (_winAt(index, _GomokuStone.black)) {
      _finishGame(
        status: _text(i18n, zh: '你获胜了', en: 'You win'),
        title: _text(i18n, zh: '对局结束', en: 'Game over'),
        message: _text(i18n, zh: '你赢下了这局五子棋。', en: 'You win this Gomoku game.'),
      );
      return;
    }
    if (_moves >= _total) {
      _finishGame(
        status: _text(i18n, zh: '平局', en: 'Draw'),
        title: _text(i18n, zh: '对局结束', en: 'Game over'),
        message: _text(i18n, zh: '平局，棋盘已满。', en: 'Draw. No more moves.'),
      );
      return;
    }
    setState(() {
      _turn = _GomokuStone.white;
      _aiThinking = true;
      _status = _text(i18n, zh: 'AI 思考中...', en: 'AI thinking...');
    });
    _runAiTurn();
  }

  Future<void> _runAiTurn() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted || _gameOver || !_aiThinking) return;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final bestMove = _chooseAiMove();
    if (bestMove == null) {
      _finishGame(
        status: _text(i18n, zh: '平局', en: 'Draw'),
        title: _text(i18n, zh: '对局结束', en: 'Game over'),
        message: _text(i18n, zh: '平局，棋盘已满。', en: 'Draw. No more moves.'),
      );
      return;
    }
    setState(() {
      _board[bestMove] = _GomokuStone.white;
      _moves += 1;
      _lastMove = bestMove;
      _aiThinking = false;
      _suggestedMove = null;
    });
    if (_winAt(bestMove, _GomokuStone.white)) {
      _finishGame(
        status: _text(i18n, zh: 'AI 获胜', en: 'AI wins'),
        title: _text(i18n, zh: '对局结束', en: 'Game over'),
        message: _text(
          i18n,
          zh: 'AI 赢下了这局五子棋。',
          en: 'AI wins this Gomoku game.',
        ),
      );
      return;
    }
    if (_moves >= _total) {
      _finishGame(
        status: _text(i18n, zh: '平局', en: 'Draw'),
        title: _text(i18n, zh: '对局结束', en: 'Game over'),
        message: _text(i18n, zh: '平局，棋盘已满。', en: 'Draw. No more moves.'),
      );
      return;
    }
    setState(() {
      _turn = _GomokuStone.black;
      _status = _text(i18n, zh: '轮到你执黑落子', en: 'Your turn (black)');
    });
  }

  int? _chooseAiMove() {
    if (_moves == 0) return _indexOf(_size ~/ 2, _size ~/ 2);
    final candidates = _candidateMoves();
    if (candidates.isEmpty) return null;

    final wins = <int>[
      for (final c in candidates)
        if (_wouldWin(c, _GomokuStone.white)) c,
    ];
    if (wins.isNotEmpty) {
      return _rankedCandidates(
        wins,
        offenseStone: _GomokuStone.white,
        defenseStone: _GomokuStone.black,
        offenseWeight: 1.3,
        defenseWeight: 1.0,
        limit: 1,
      ).first;
    }

    final blocks = <int>[
      for (final c in candidates)
        if (_wouldWin(c, _GomokuStone.black)) c,
    ];
    if (blocks.isNotEmpty) {
      if (_difficulty == _GomokuDifficulty.easy && _random.nextDouble() < 0.2) {
        return _chooseEasyMove(candidates);
      }
      return _rankedCandidates(
        blocks,
        offenseStone: _GomokuStone.white,
        defenseStone: _GomokuStone.black,
        offenseWeight: 0.9,
        defenseWeight: 1.8,
        limit: 1,
      ).first;
    }

    return switch (_difficulty) {
      _GomokuDifficulty.easy => _chooseEasyMove(candidates),
      _GomokuDifficulty.medium => _chooseMediumMove(candidates),
      _GomokuDifficulty.hard => _chooseHardMove(candidates),
    };
  }

  int _chooseEasyMove(List<int> candidates) {
    final ranked = _rankedCandidates(
      candidates,
      offenseStone: _GomokuStone.white,
      defenseStone: _GomokuStone.black,
      offenseWeight: 1.0,
      defenseWeight: 0.95,
      limit: 7,
    );
    final pool = ranked
        .take(math.min(4, ranked.length))
        .toList(growable: false);
    return pool[_random.nextInt(pool.length)];
  }

  int _chooseMediumMove(List<int> candidates) {
    final ranked = _rankedCandidates(
      candidates,
      offenseStone: _GomokuStone.white,
      defenseStone: _GomokuStone.black,
      offenseWeight: 1.12,
      defenseWeight: 1.2,
      limit: 6,
    );
    if (ranked.length > 1 && _random.nextDouble() < 0.2) {
      return ranked[1];
    }
    return ranked.first;
  }

  int _chooseHardMove(List<int> candidates) {
    final ranked = _rankedCandidates(
      candidates,
      offenseStone: _GomokuStone.white,
      defenseStone: _GomokuStone.black,
      offenseWeight: 1.2,
      defenseWeight: 1.3,
      limit: 10,
    );
    var bestMove = ranked.first;
    var bestScore = double.negativeInfinity;
    var alpha = double.negativeInfinity;
    for (final move in ranked) {
      _board[move] = _GomokuStone.white;
      final score = _winAt(move, _GomokuStone.white)
          ? _terminalScore
          : _minimaxScore(
              depth: 2,
              maximizingForAi: false,
              alpha: alpha,
              beta: double.infinity,
            );
      _board[move] = _GomokuStone.empty;
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
      if (score > alpha) {
        alpha = score;
      }
    }
    return bestMove;
  }

  List<int> _rankedCandidates(
    List<int> candidates, {
    required _GomokuStone offenseStone,
    required _GomokuStone defenseStone,
    required double offenseWeight,
    required double defenseWeight,
    int? limit,
  }) {
    final scored = <(int, double)>[];
    for (final c in candidates) {
      final attack = _evaluateMove(c, offenseStone);
      final defense = _evaluateMove(c, defenseStone);
      final center = _centerBias(c);
      final score =
          attack * offenseWeight +
          defense * defenseWeight +
          center +
          _random.nextDouble() * 0.001;
      scored.add((c, score));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    final ranked = <int>[for (final item in scored) item.$1];
    if (limit == null || ranked.length <= limit) {
      return ranked;
    }
    return ranked.sublist(0, limit);
  }

  double _minimaxScore({
    required int depth,
    required bool maximizingForAi,
    required double alpha,
    required double beta,
  }) {
    if (depth <= 0) {
      return _boardHeuristicScore();
    }
    final candidates = _candidateMoves();
    if (candidates.isEmpty) {
      return _boardHeuristicScore();
    }
    final stone = maximizingForAi ? _GomokuStone.white : _GomokuStone.black;
    final ranked = _rankedCandidates(
      candidates,
      offenseStone: stone,
      defenseStone: _opponent(stone),
      offenseWeight: maximizingForAi ? 1.15 : 1.2,
      defenseWeight: maximizingForAi ? 1.1 : 1.28,
      limit: maximizingForAi ? 8 : 7,
    );

    if (maximizingForAi) {
      var best = double.negativeInfinity;
      for (final move in ranked) {
        _board[move] = _GomokuStone.white;
        final score = _winAt(move, _GomokuStone.white)
            ? _terminalScore - (2 - depth)
            : _minimaxScore(
                depth: depth - 1,
                maximizingForAi: false,
                alpha: alpha,
                beta: beta,
              );
        _board[move] = _GomokuStone.empty;
        if (score > best) {
          best = score;
        }
        if (score > alpha) {
          alpha = score;
        }
        if (alpha >= beta) {
          break;
        }
      }
      return best;
    }

    var best = double.infinity;
    for (final move in ranked) {
      _board[move] = _GomokuStone.black;
      final score = _winAt(move, _GomokuStone.black)
          ? -_terminalScore + (2 - depth)
          : _minimaxScore(
              depth: depth - 1,
              maximizingForAi: true,
              alpha: alpha,
              beta: beta,
            );
      _board[move] = _GomokuStone.empty;
      if (score < best) {
        best = score;
      }
      if (score < beta) {
        beta = score;
      }
      if (beta <= alpha) {
        break;
      }
    }
    return best;
  }

  double _boardHeuristicScore() {
    final candidates = _candidateMoves();
    if (candidates.isEmpty) {
      return 0;
    }
    final ranked = _rankedCandidates(
      candidates,
      offenseStone: _GomokuStone.white,
      defenseStone: _GomokuStone.black,
      offenseWeight: 1.0,
      defenseWeight: 1.0,
      limit: 12,
    );
    var aiBest = double.negativeInfinity;
    var playerBest = double.negativeInfinity;
    for (final move in ranked) {
      aiBest = math.max(aiBest, _evaluateMove(move, _GomokuStone.white));
      playerBest = math.max(
        playerBest,
        _evaluateMove(move, _GomokuStone.black),
      );
    }
    if (aiBest.isInfinite) aiBest = 0;
    if (playerBest.isInfinite) playerBest = 0;
    return aiBest * 1.16 - playerBest * 1.22;
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

  bool _isStarPoint(int row, int col) {
    const points = <int>[3, 7, 11];
    return points.contains(row) && points.contains(col);
  }

  int? _choosePlayerHintMove() {
    if (_gameOver || _aiThinking || _turn != _GomokuStone.black) {
      return null;
    }
    if (_moves == 0) {
      return _indexOf(_size ~/ 2, _size ~/ 2);
    }
    final candidates = _candidateMoves();
    if (candidates.isEmpty) {
      return null;
    }
    return _rankedCandidates(
      candidates,
      offenseStone: _GomokuStone.black,
      defenseStone: _GomokuStone.white,
      offenseWeight: 1.1,
      defenseWeight: 1.18,
      limit: 1,
    ).first;
  }

  void _showHint() {
    final suggestion = _choosePlayerHintMove();
    if (suggestion == null || !mounted) {
      return;
    }
    final row = suggestion ~/ _size + 1;
    final col = suggestion % _size + 1;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    setState(() {
      _suggestedMove = suggestion;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _text(
            i18n,
            zh: '建议在第 $row 行第 $col 列落子。',
            en: 'Suggested move: row $row, column $col.',
          ),
        ),
      ),
    );
  }

  Widget _buildBoard(BuildContext context, {required bool fullscreen}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final targetCell = fullscreen
            ? 34.0
            : _miniGameCompactLayout(context)
            ? 24.0
            : 30.0;
        final boardWidth = math.max(viewportWidth, _size * targetCell);
        final cellExtent = boardWidth / _size;
        return _MiniGameScrollLockSurface(
          child: InteractiveViewer(
            minScale: 0.7,
            maxScale: 4,
            boundaryMargin: const EdgeInsets.all(24),
            child: Center(
              child: SizedBox(
                width: boardWidth,
                height: boardWidth,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _board.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _size,
                  ),
                  itemBuilder: (context, index) {
                    final row = index ~/ _size;
                    final col = index % _size;
                    final suggested = _suggestedMove == index;
                    return GestureDetector(
                      onTap: () => _tapCell(index),
                      child: Container(
                        margin: EdgeInsets.all(cellExtent <= 24 ? 0.18 : 0.3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1D6A9),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.45),
                            width: cellExtent <= 24 ? 0.3 : 0.45,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            if (_board[index] == _GomokuStone.empty &&
                                _isStarPoint(row, col))
                              Container(
                                width: (cellExtent * 0.18)
                                    .clamp(3, 7)
                                    .toDouble(),
                                height: (cellExtent * 0.18)
                                    .clamp(3, 7)
                                    .toDouble(),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF7E5525),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (suggested &&
                                _board[index] == _GomokuStone.empty)
                              Container(
                                width: cellExtent * 0.64,
                                height: cellExtent * 0.64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF2E6CE6),
                                    width: 2,
                                  ),
                                ),
                              ),
                            _GomokuStoneView(
                              stone: _board[index],
                              highlight: _lastMove == index,
                              extent: cellExtent,
                            ),
                          ],
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

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final displayStatus = _gameOver
        ? _status
        : _aiThinking
        ? _text(i18n, zh: 'AI 思考中...', en: 'AI thinking...')
        : _text(i18n, zh: '轮到你执黑落子', en: 'Your turn (black)');
    if (_fullscreen) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton.tonalIcon(
                      onPressed: () => _setFullscreen(false),
                      icon: const Icon(Icons.fullscreen_exit_rounded),
                      label: Text(
                        _text(i18n, zh: '退出全屏', en: 'Exit fullscreen'),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed:
                          _aiThinking ||
                              _gameOver ||
                              _turn != _GomokuStone.black
                          ? null
                          : _showHint,
                      icon: const Icon(Icons.tips_and_updates_outlined),
                      label: Text(_text(i18n, zh: '提示', en: 'Hint')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _resetGame,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(_text(i18n, zh: '新开一局', en: 'New game')),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    ToolboxMetricCard(
                      label: _text(i18n, zh: '棋盘', en: 'Board'),
                      value: '15x15',
                    ),
                    ToolboxMetricCard(
                      label: _text(i18n, zh: '步数', en: 'Moves'),
                      value: '$_moves',
                    ),
                    ToolboxMetricCard(
                      label: _text(i18n, zh: '状态', en: 'Status'),
                      value: displayStatus,
                    ),
                    ToolboxMetricCard(
                      label: _text(i18n, zh: 'AI 难度', en: 'AI level'),
                      value: _difficultyLabel(i18n, _difficulty),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDifficultySelector(i18n),
                const SizedBox(height: 12),
                Expanded(child: _buildBoard(context, fullscreen: true)),
              ],
            ),
          ),
        ),
      );
    }
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
                  label: _text(i18n, zh: '棋盘', en: 'Board'),
                  value: '15x15',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '步数', en: 'Moves'),
                  value: '$_moves',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '状态', en: 'Status'),
                  value: displayStatus,
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: 'AI 难度', en: 'AI level'),
                  value: _difficultyLabel(i18n, _difficulty),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDifficultySelector(i18n),
            const SizedBox(height: 12),
            Text(
              _text(
                i18n,
                zh: '你执黑先行。点击空位落子，可使用提示查看建议落点。',
                en: 'You play black first. Tap an empty cell to place a stone, or use hint for a suggested move.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: _miniGameCompactLayout(context) ? 360 : 520,
              child: _buildBoard(context, fullscreen: false),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: _resetGame,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(_text(i18n, zh: '新开一局', en: 'New game')),
                ),
                FilledButton.tonalIcon(
                  onPressed:
                      _aiThinking || _gameOver || _turn != _GomokuStone.black
                      ? null
                      : _showHint,
                  icon: const Icon(Icons.tips_and_updates_outlined),
                  label: Text(_text(i18n, zh: '提示', en: 'Hint')),
                ),
                OutlinedButton.icon(
                  onPressed: () => _setFullscreen(true),
                  icon: const Icon(Icons.fullscreen_rounded),
                  label: Text(_text(i18n, zh: '全屏棋盘', en: 'Fullscreen board')),
                ),
                if (_aiThinking)
                  Chip(
                    avatar: const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    label: Text(_text(i18n, zh: 'AI 思考中', en: 'AI thinking')),
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
  const _GomokuStoneView({
    required this.stone,
    required this.highlight,
    required this.extent,
  });

  final _GomokuStone stone;
  final bool highlight;
  final double extent;

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
    final stoneSize = (extent * 0.74).clamp(12, 26).toDouble();
    final markerSize = (extent * 0.22).clamp(3, 6).toDouble();
    return Container(
      width: stoneSize,
      height: stoneSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: border, width: 1),
      ),
      child: highlight
          ? Center(
              child: Container(
                width: markerSize,
                height: markerSize,
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

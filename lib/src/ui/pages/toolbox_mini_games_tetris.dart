part of 'toolbox_mini_games.dart';

enum _TetrisKind { i, o, t, s, z, j, l }

enum _TetrisDifficulty {
  relaxed(baseMs: 780, accelerationMs: 38, linesPerLevel: 12),
  classic(baseMs: 650, accelerationMs: 56, linesPerLevel: 10),
  sprint(baseMs: 520, accelerationMs: 74, linesPerLevel: 8);

  const _TetrisDifficulty({
    required this.baseMs,
    required this.accelerationMs,
    required this.linesPerLevel,
  });

  final int baseMs;
  final int accelerationMs;
  final int linesPerLevel;
}

class _TetrisGame extends StatefulWidget {
  const _TetrisGame();

  @override
  State<_TetrisGame> createState() => _TetrisGameState();
}

class _TetrisGameState extends State<_TetrisGame> {
  static const int _cols = 10;
  static const int _rows = 20;
  final math.Random _random = math.Random();

  late List<int> _board;
  late _TetrisPiece _current;
  late _TetrisPiece _next;
  Timer? _timer;
  int _score = 0;
  int _lines = 0;
  int _level = 1;
  _TetrisDifficulty _difficulty = _TetrisDifficulty.classic;
  bool _paused = false;
  bool _gameOver = false;
  bool _resultDialogOpen = false;
  Offset? _dragStart;
  bool _dragConsumed = false;

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

  Duration get _fallDuration {
    final millis = math.max(
      90,
      _difficulty.baseMs - (_level - 1) * _difficulty.accelerationMs,
    );
    return Duration(milliseconds: millis);
  }

  String _text(AppI18n i18n, {required String zh, required String en}) {
    return pickUiText(i18n, zh: zh, en: en);
  }

  String _difficultyLabel(AppI18n i18n, _TetrisDifficulty difficulty) {
    return switch (difficulty) {
      _TetrisDifficulty.relaxed => _text(i18n, zh: '放松', en: 'Relaxed'),
      _TetrisDifficulty.classic => _text(i18n, zh: '经典', en: 'Classic'),
      _TetrisDifficulty.sprint => _text(i18n, zh: '竞速', en: 'Sprint'),
    };
  }

  _TetrisPiece _randomPiece() {
    return _TetrisPiece(
      kind: _TetrisKind.values[_random.nextInt(_TetrisKind.values.length)],
      row: 0,
      col: 3,
      rotation: 0,
    );
  }

  void _newGame() {
    _timer?.cancel();
    setState(() {
      _board = List<int>.filled(_cols * _rows, 0);
      _score = 0;
      _lines = 0;
      _level = 1;
      _paused = false;
      _gameOver = false;
      _current = _randomPiece();
      _next = _randomPiece();
      if (!_canPlace(_current)) {
        _gameOver = true;
      }
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_fallDuration, (_) => _stepDown());
  }

  void _syncTimerAfterLevelChange(int previousLevel) {
    if (previousLevel != _level && !_gameOver) {
      _startTimer();
    }
  }

  void _setDifficulty(_TetrisDifficulty difficulty) {
    if (_difficulty == difficulty) {
      return;
    }
    setState(() {
      _difficulty = difficulty;
      _level = _lines ~/ _difficulty.linesPerLevel + 1;
    });
    if (!_gameOver) {
      _startTimer();
    }
  }

  bool _canPlace(_TetrisPiece piece) {
    for (final cell in piece.cells) {
      final row = cell.row;
      final col = cell.col;
      if (col < 0 || col >= _cols || row < 0 || row >= _rows) {
        return false;
      }
      if (_board[row * _cols + col] != 0) {
        return false;
      }
    }
    return true;
  }

  void _moveHorizontal(int delta) {
    if (_paused || _gameOver) {
      return;
    }
    final moved = _current.shifted(0, delta);
    if (!_canPlace(moved)) {
      return;
    }
    setState(() {
      _current = moved;
    });
  }

  void _rotate() {
    if (_paused || _gameOver) {
      return;
    }
    for (final kick in <int>[0, -1, 1, -2, 2]) {
      final rotated = _current.rotated().shifted(0, kick);
      if (_canPlace(rotated)) {
        setState(() {
          _current = rotated;
        });
        return;
      }
    }
  }

  void _stepDown({bool soft = false}) {
    if (_paused || _gameOver) {
      return;
    }
    final moved = _current.shifted(1, 0);
    if (_canPlace(moved)) {
      setState(() {
        _current = moved;
        if (soft) {
          _score += 1;
        }
      });
      return;
    }
    final previousLevel = _level;
    setState(_lockPiece);
    _syncTimerAfterLevelChange(previousLevel);
    _showGameOverIfNeeded();
  }

  void _hardDrop() {
    if (_paused || _gameOver) {
      return;
    }
    var dropped = 0;
    var piece = _current;
    while (_canPlace(piece.shifted(1, 0))) {
      piece = piece.shifted(1, 0);
      dropped += 1;
    }
    final previousLevel = _level;
    setState(() {
      _current = piece;
      _score += dropped * 2;
      _lockPiece();
    });
    _syncTimerAfterLevelChange(previousLevel);
    _showGameOverIfNeeded();
  }

  void _lockPiece() {
    for (final cell in _current.cells) {
      _board[cell.row * _cols + cell.col] = _current.kind.index + 1;
    }
    _clearLines();
    _current = _next;
    _next = _randomPiece();
    if (!_canPlace(_current)) {
      _gameOver = true;
      _paused = false;
    }
  }

  void _clearLines() {
    final keptRows = <List<int>>[];
    var cleared = 0;
    for (var row = 0; row < _rows; row += 1) {
      final values = _board.sublist(row * _cols, row * _cols + _cols);
      if (values.every((value) => value != 0)) {
        cleared += 1;
      } else {
        keptRows.add(values);
      }
    }
    if (cleared == 0) {
      return;
    }
    final newRows = <List<int>>[
      for (var index = 0; index < cleared; index += 1)
        List<int>.filled(_cols, 0),
      ...keptRows,
    ];
    _board = <int>[for (final row in newRows) ...row];
    const lineScores = <int>[0, 100, 300, 500, 800];
    _score += lineScores[cleared] * _level;
    _lines += cleared;
    _level = _lines ~/ _difficulty.linesPerLevel + 1;
  }

  int _displayValueAt(int index) {
    final row = index ~/ _cols;
    final col = index % _cols;
    for (final cell in _current.cells) {
      if (cell.row == row && cell.col == col) {
        return _current.kind.index + 1;
      }
    }
    return _board[index];
  }

  void _togglePause() {
    if (_gameOver) {
      return;
    }
    setState(() {
      _paused = !_paused;
    });
  }

  Future<void> _showGameOverIfNeeded() async {
    if (!_gameOver || _resultDialogOpen || !mounted) {
      return;
    }
    _resultDialogOpen = true;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(_text(i18n, zh: '方块堆满了', en: 'Game over')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _text(i18n, zh: '本局结算', en: 'Round summary'),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(_text(i18n, zh: '得分：$_score', en: 'Score: $_score')),
              Text(_text(i18n, zh: '消行：$_lines', en: 'Lines: $_lines')),
              Text(_text(i18n, zh: '等级：$_level', en: 'Level: $_level')),
              Text(
                _text(
                  i18n,
                  zh: '难度：${_difficultyLabel(i18n, _difficulty)}',
                  en: 'Difficulty: ${_difficultyLabel(i18n, _difficulty)}',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_text(i18n, zh: '关闭', en: 'Close')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _newGame();
              },
              child: Text(_text(i18n, zh: '再来一局', en: 'Play again')),
            ),
          ],
        );
      },
    );
    _resultDialogOpen = false;
  }

  void _handleDragStart(Offset position) {
    _dragStart = position;
    _dragConsumed = false;
  }

  void _handleDragUpdate(Offset position) {
    if (_dragConsumed || _dragStart == null) {
      return;
    }
    final delta = position - _dragStart!;
    if (delta.distance < 24) {
      return;
    }
    _dragConsumed = true;
    if (delta.dy < -24 && delta.dy.abs() > delta.dx.abs()) {
      _rotate();
      return;
    }
    if (delta.dy > 24 && delta.dy.abs() > delta.dx.abs()) {
      _stepDown(soft: true);
      return;
    }
    _moveHorizontal(delta.dx > 0 ? 1 : -1);
  }

  void _handleDragEnd([DragEndDetails? _]) {
    _dragStart = null;
    _dragConsumed = false;
  }

  String _statusLabel(AppI18n i18n) {
    if (_gameOver) {
      return _text(i18n, zh: '游戏结束', en: 'Game over');
    }
    if (_paused) {
      return _text(i18n, zh: '已暂停', en: 'Paused');
    }
    return _text(i18n, zh: '进行中', en: 'Playing');
  }

  Color _cellColor(BuildContext context, int value) {
    if (value == 0) {
      return Theme.of(context).colorScheme.surfaceContainerLowest;
    }
    return _tetrisColors[value - 1];
  }

  Widget _buildBoard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.sizeOf(context).height;
        final targetHeight = (screenHeight * 0.62).clamp(380.0, 620.0);
        final boardWidth = math.min(
          constraints.maxWidth,
          math.min(360.0, targetHeight / 2),
        );
        return Center(
          child: _MiniGameScrollLockSurface(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              dragStartBehavior: DragStartBehavior.down,
              onVerticalDragStart: (details) =>
                  _handleDragStart(details.localPosition),
              onVerticalDragUpdate: (details) =>
                  _handleDragUpdate(details.localPosition),
              onVerticalDragEnd: _handleDragEnd,
              onVerticalDragCancel: () => _handleDragEnd(),
              onHorizontalDragStart: (details) =>
                  _handleDragStart(details.localPosition),
              onHorizontalDragUpdate: (details) =>
                  _handleDragUpdate(details.localPosition),
              onHorizontalDragEnd: _handleDragEnd,
              onHorizontalDragCancel: () => _handleDragEnd(),
              child: Container(
                width: boardWidth,
                height: boardWidth * 2,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _cols * _rows,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _cols,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemBuilder: (context, index) {
                    final value = _displayValueAt(index);
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 90),
                      decoration: BoxDecoration(
                        color: _cellColor(context, value),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: value == 0
                              ? colors.outlineVariant.withValues(alpha: 0.26)
                              : Colors.white.withValues(alpha: 0.42),
                          width: 0.6,
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

  Widget _buildNextPreview(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final previewCells = <int>{for (final cell in _next.previewCells) cell};
    return Container(
      width: 112,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            _text(
              AppI18n(Localizations.localeOf(context).languageCode),
              zh: '下一个',
              en: 'Next',
            ),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 72,
            height: 72,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 16,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 3,
                crossAxisSpacing: 3,
              ),
              itemBuilder: (context, index) {
                final active = previewCells.contains(index);
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: active
                        ? _tetrisColors[_next.kind.index]
                        : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySettings(BuildContext context, AppI18n i18n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _text(i18n, zh: '难度设置', en: 'Difficulty settings'),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final difficulty in _TetrisDifficulty.values)
                ChoiceChip(
                  label: Text(_difficultyLabel(i18n, difficulty)),
                  selected: _difficulty == difficulty,
                  onSelected: (_) => _setDifficulty(difficulty),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _text(
              i18n,
              zh: '初始下降 ${_difficulty.baseMs}ms，每级加速 ${_difficulty.accelerationMs}ms，约每 ${_difficulty.linesPerLevel} 行升一级。',
              en: 'Initial fall ${_difficulty.baseMs}ms, speed-up ${_difficulty.accelerationMs}ms per level, level up about every ${_difficulty.linesPerLevel} lines.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildGamepad(BuildContext context, AppI18n i18n) {
    final colors = Theme.of(context).colorScheme;
    Widget padButton({
      required IconData icon,
      required VoidCallback? onPressed,
      VoidCallback? onLongPress,
      required String tooltip,
      bool filled = false,
    }) {
      final style = FilledButton.styleFrom(
        backgroundColor: filled ? null : colors.secondaryContainer,
        foregroundColor: filled ? null : colors.onSecondaryContainer,
        shape: const CircleBorder(),
        padding: EdgeInsets.zero,
        fixedSize: const Size(58, 58),
      );
      return Tooltip(
        message: tooltip,
        child: FilledButton(
          onPressed: onPressed,
          onLongPress: onLongPress,
          style: style,
          child: Icon(icon, size: 28),
        ),
      );
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            padButton(
              icon: _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              onPressed: _togglePause,
              tooltip: _paused
                  ? _text(i18n, zh: '继续', en: 'Resume')
                  : _text(i18n, zh: '暂停', en: 'Pause'),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                padButton(
                  icon: Icons.keyboard_arrow_left_rounded,
                  onPressed: () => _moveHorizontal(-1),
                  tooltip: _text(i18n, zh: '左移', en: 'Move left'),
                ),
                const SizedBox(width: 8),
                padButton(
                  icon: Icons.change_circle_rounded,
                  onPressed: _rotate,
                  tooltip: _text(i18n, zh: '变形', en: 'Transform'),
                  filled: true,
                ),
                const SizedBox(width: 8),
                padButton(
                  icon: Icons.keyboard_arrow_right_rounded,
                  onPressed: () => _moveHorizontal(1),
                  tooltip: _text(i18n, zh: '右移', en: 'Move right'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            padButton(
              icon: Icons.keyboard_arrow_down_rounded,
              onPressed: () => _stepDown(soft: true),
              onLongPress: _hardDrop,
              tooltip: _text(
                i18n,
                zh: '下降，长按硬降',
                en: 'Drop, long-press hard drop',
              ),
            ),
          ],
        ),
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
                  label: _text(i18n, zh: '得分', en: 'Score'),
                  value: '$_score',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '消行', en: 'Lines'),
                  value: '$_lines',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '等级', en: 'Level'),
                  value: '$_level',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '难度', en: 'Difficulty'),
                  value: _difficultyLabel(i18n, _difficulty),
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '状态', en: 'Status'),
                  value: _statusLabel(i18n),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _text(
                i18n,
                zh: '棋盘内滑动或使用五键手柄。上键暂停，下键下降，长按下键硬降，中间键变形。',
                en: 'Swipe on the board or use the five-key pad. Up pauses, down drops, long-press down hard-drops, and the center transforms the block.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _buildDifficultySettings(context, i18n),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 520;
                return compact
                    ? Column(
                        children: <Widget>[
                          _buildBoard(context),
                          const SizedBox(height: 12),
                          _buildNextPreview(context),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(child: _buildBoard(context)),
                          const SizedBox(width: 12),
                          _buildNextPreview(context),
                        ],
                      );
              },
            ),
            const SizedBox(height: 12),
            _buildGamepad(context, i18n),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _newGame,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_text(i18n, zh: '新开一局', en: 'New game')),
            ),
          ],
        ),
      ),
    );
  }
}

class _TetrisPiece {
  const _TetrisPiece({
    required this.kind,
    required this.row,
    required this.col,
    required this.rotation,
  });

  final _TetrisKind kind;
  final int row;
  final int col;
  final int rotation;

  List<_TetrisPoint> get cells {
    final shape = _tetrisShapes[kind.index];
    final offsets = shape[rotation % shape.length];
    return <_TetrisPoint>[
      for (final offset in offsets)
        _TetrisPoint(row + offset.row, col + offset.col),
    ];
  }

  List<int> get previewCells {
    final shape = _tetrisShapes[kind.index];
    final offsets = shape[rotation % shape.length];
    return <int>[for (final offset in offsets) offset.row * 4 + offset.col];
  }

  _TetrisPiece shifted(int rowDelta, int colDelta) {
    return _TetrisPiece(
      kind: kind,
      row: row + rowDelta,
      col: col + colDelta,
      rotation: rotation,
    );
  }

  _TetrisPiece rotated() {
    return _TetrisPiece(kind: kind, row: row, col: col, rotation: rotation + 1);
  }
}

class _TetrisPoint {
  const _TetrisPoint(this.row, this.col);

  final int row;
  final int col;
}

const List<Color> _tetrisColors = <Color>[
  Color(0xFF20B9CF),
  Color(0xFFE5B93E),
  Color(0xFF8E62D6),
  Color(0xFF45A869),
  Color(0xFFD8554D),
  Color(0xFF4B75D1),
  Color(0xFFD68532),
];

const List<List<List<_TetrisPoint>>> _tetrisShapes = <List<List<_TetrisPoint>>>[
  <List<_TetrisPoint>>[
    <_TetrisPoint>[
      _TetrisPoint(1, 0),
      _TetrisPoint(1, 1),
      _TetrisPoint(1, 2),
      _TetrisPoint(1, 3),
    ],
    <_TetrisPoint>[
      _TetrisPoint(0, 2),
      _TetrisPoint(1, 2),
      _TetrisPoint(2, 2),
      _TetrisPoint(3, 2),
    ],
  ],
  <List<_TetrisPoint>>[
    <_TetrisPoint>[
      _TetrisPoint(0, 1),
      _TetrisPoint(0, 2),
      _TetrisPoint(1, 1),
      _TetrisPoint(1, 2),
    ],
  ],
  <List<_TetrisPoint>>[
    <_TetrisPoint>[
      _TetrisPoint(0, 1),
      _TetrisPoint(1, 0),
      _TetrisPoint(1, 1),
      _TetrisPoint(1, 2),
    ],
    <_TetrisPoint>[
      _TetrisPoint(0, 1),
      _TetrisPoint(1, 1),
      _TetrisPoint(1, 2),
      _TetrisPoint(2, 1),
    ],
    <_TetrisPoint>[
      _TetrisPoint(1, 0),
      _TetrisPoint(1, 1),
      _TetrisPoint(1, 2),
      _TetrisPoint(2, 1),
    ],
    <_TetrisPoint>[
      _TetrisPoint(0, 1),
      _TetrisPoint(1, 0),
      _TetrisPoint(1, 1),
      _TetrisPoint(2, 1),
    ],
  ],
  <List<_TetrisPoint>>[
    <_TetrisPoint>[
      _TetrisPoint(0, 1),
      _TetrisPoint(0, 2),
      _TetrisPoint(1, 0),
      _TetrisPoint(1, 1),
    ],
    <_TetrisPoint>[
      _TetrisPoint(0, 1),
      _TetrisPoint(1, 1),
      _TetrisPoint(1, 2),
      _TetrisPoint(2, 2),
    ],
  ],
  <List<_TetrisPoint>>[
    <_TetrisPoint>[
      _TetrisPoint(0, 0),
      _TetrisPoint(0, 1),
      _TetrisPoint(1, 1),
      _TetrisPoint(1, 2),
    ],
    <_TetrisPoint>[
      _TetrisPoint(0, 2),
      _TetrisPoint(1, 1),
      _TetrisPoint(1, 2),
      _TetrisPoint(2, 1),
    ],
  ],
  <List<_TetrisPoint>>[
    <_TetrisPoint>[
      _TetrisPoint(0, 0),
      _TetrisPoint(1, 0),
      _TetrisPoint(1, 1),
      _TetrisPoint(1, 2),
    ],
    <_TetrisPoint>[
      _TetrisPoint(0, 1),
      _TetrisPoint(0, 2),
      _TetrisPoint(1, 1),
      _TetrisPoint(2, 1),
    ],
    <_TetrisPoint>[
      _TetrisPoint(1, 0),
      _TetrisPoint(1, 1),
      _TetrisPoint(1, 2),
      _TetrisPoint(2, 2),
    ],
    <_TetrisPoint>[
      _TetrisPoint(0, 1),
      _TetrisPoint(1, 1),
      _TetrisPoint(2, 0),
      _TetrisPoint(2, 1),
    ],
  ],
  <List<_TetrisPoint>>[
    <_TetrisPoint>[
      _TetrisPoint(0, 2),
      _TetrisPoint(1, 0),
      _TetrisPoint(1, 1),
      _TetrisPoint(1, 2),
    ],
    <_TetrisPoint>[
      _TetrisPoint(0, 1),
      _TetrisPoint(1, 1),
      _TetrisPoint(2, 1),
      _TetrisPoint(2, 2),
    ],
    <_TetrisPoint>[
      _TetrisPoint(1, 0),
      _TetrisPoint(1, 1),
      _TetrisPoint(1, 2),
      _TetrisPoint(2, 0),
    ],
    <_TetrisPoint>[
      _TetrisPoint(0, 0),
      _TetrisPoint(0, 1),
      _TetrisPoint(1, 1),
      _TetrisPoint(2, 1),
    ],
  ],
];

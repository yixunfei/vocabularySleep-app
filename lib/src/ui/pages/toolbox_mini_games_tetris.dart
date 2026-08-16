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

  String _difficultyLabel(AppI18n i18n, _TetrisDifficulty difficulty) {
    return switch (difficulty) {
      _TetrisDifficulty.relaxed => i18n.t(
        'toolbox.miniGames.tetris.relaxed.c6d5ee8e',
      ),
      _TetrisDifficulty.classic => i18n.t(
        'toolbox.miniGames.tetris.classic.665c7f52',
      ),
      _TetrisDifficulty.sprint => i18n.t(
        'toolbox.miniGames.tetris.sprint.e5fb9160',
      ),
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
          title: Text(i18n.t('toolbox.miniGames.tetris.game_over.4a8d9446')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                i18n.t('toolbox.miniGames.tetris.round_summary.43324c59'),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                i18n.t(
                  'toolbox.miniGames.tetris.score_value.6efd0b83',
                  params: <String, Object?>{'score': _score},
                ),
              ),
              Text(
                i18n.t(
                  'toolbox.miniGames.tetris.lines_value.d5f04673',
                  params: <String, Object?>{'lines': _lines},
                ),
              ),
              Text(
                i18n.t(
                  'toolbox.miniGames.tetris.level_value.6a796f4d',
                  params: <String, Object?>{'level': _level},
                ),
              ),
              Text(
                i18n.t(
                  'toolbox.miniGames.tetris.difficulty_value.1fbd5026',
                  params: <String, Object?>{
                    'difficulty': _difficultyLabel(i18n, _difficulty),
                  },
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(i18n.t('toolbox.miniGames.tetris.close.fe81151b')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _newGame();
              },
              child: Text(
                i18n.t('toolbox.miniGames.tetris.play_again.7a9153f9'),
              ),
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
      return i18n.t('toolbox.miniGames.tetris.game_over.746ac38d');
    }
    if (_paused) {
      return i18n.t('toolbox.miniGames.tetris.paused.1e1aa869');
    }
    return i18n.t('toolbox.miniGames.tetris.playing.36f1d9a0');
  }

  Color _cellColor(BuildContext context, int value) {
    if (value == 0) {
      return Theme.of(context).colorScheme.surfaceContainerLowest;
    }
    return _tetrisColors[value - 1];
  }

  Widget _buildBoard(
    BuildContext context, {
    bool compact = false,
    double? maxBoardHeight,
  }) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.sizeOf(context).height;
        final targetHeight =
            maxBoardHeight ??
            (compact
                ? (screenHeight * 0.54).clamp(320.0, 520.0)
                : (screenHeight * 0.62).clamp(380.0, 620.0));
        final boardWidth = math.min(
          constraints.maxWidth,
          math.min(compact ? 320.0 : 360.0, targetHeight / 2),
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
                padding: EdgeInsets.all(compact ? 5 : 8),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(compact ? 12 : 16),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _cols * _rows,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _cols,
                    mainAxisSpacing: compact ? 1 : 2,
                    crossAxisSpacing: compact ? 1 : 2,
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

  Widget _buildNextPreview(BuildContext context, {bool compact = false}) {
    final colors = Theme.of(context).colorScheme;
    final previewCells = <int>{for (final cell in _next.previewCells) cell};
    return Container(
      width: compact ? 88 : 112,
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            AppI18n(
              Localizations.localeOf(context).languageCode,
            ).t('toolbox.miniGames.tetris.next.de45a45c'),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          SizedBox(height: compact ? 6 : 8),
          SizedBox(
            width: compact ? 56 : 72,
            height: compact ? 56 : 72,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 16,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: compact ? 2 : 3,
                crossAxisSpacing: compact ? 2 : 3,
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

  Widget _buildDifficultySettings(
    BuildContext context,
    AppI18n i18n, {
    bool compact = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 8 : 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!compact) ...<Widget>[
            Text(
              i18n.t('toolbox.miniGames.tetris.difficulty_settings.7fcf2a80'),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            runSpacing: compact ? 4 : 8,
            children: <Widget>[
              for (final difficulty in _TetrisDifficulty.values)
                ChoiceChip(
                  visualDensity: compact ? VisualDensity.compact : null,
                  label: Text(_difficultyLabel(i18n, difficulty)),
                  selected: _difficulty == difficulty,
                  onSelected: (_) => _setDifficulty(difficulty),
                ),
            ],
          ),
          if (!compact) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              i18n.t(
                'toolbox.miniGames.tetris.initial_fall_value_ms_speed_up_value.d5017569',
                params: <String, Object?>{
                  'baseMs': _difficulty.baseMs,
                  'accelerationMs': _difficulty.accelerationMs,
                  'linesPerLevel': _difficulty.linesPerLevel,
                },
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGamepad(
    BuildContext context,
    AppI18n i18n, {
    bool compact = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    if (compact) {
      Widget padButton({
        required IconData icon,
        required VoidCallback? onPressed,
        VoidCallback? onLongPress,
        required String tooltip,
        bool filled = false,
        int flex = 1,
      }) {
        final style = FilledButton.styleFrom(
          backgroundColor: filled ? colors.primary : colors.secondaryContainer,
          foregroundColor: filled
              ? colors.onPrimary
              : colors.onSecondaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 52),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
        return Expanded(
          flex: flex,
          child: Tooltip(
            message: tooltip,
            child: SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: onPressed,
                onLongPress: onLongPress,
                style: style,
                child: Icon(icon, size: 26),
              ),
            ),
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                padButton(
                  icon: Icons.keyboard_arrow_left_rounded,
                  onPressed: () => _moveHorizontal(-1),
                  tooltip: i18n.t(
                    'toolbox.miniGames.tetris.move_left.d01e9f05',
                  ),
                ),
                const SizedBox(width: 8),
                padButton(
                  icon: Icons.change_circle_rounded,
                  onPressed: _rotate,
                  tooltip: i18n.t(
                    'toolbox.miniGames.tetris.transform.3dd2f28e',
                  ),
                  filled: true,
                ),
                const SizedBox(width: 8),
                padButton(
                  icon: Icons.keyboard_arrow_right_rounded,
                  onPressed: () => _moveHorizontal(1),
                  tooltip: i18n.t(
                    'toolbox.miniGames.tetris.move_right.e85b744f',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                padButton(
                  icon: Icons.keyboard_arrow_down_rounded,
                  onPressed: () => _stepDown(soft: true),
                  onLongPress: _hardDrop,
                  tooltip: i18n.t(
                    'toolbox.miniGames.tetris.drop_long_press_hard_drop.0faeb5f1',
                  ),
                  flex: 2,
                ),
                const SizedBox(width: 8),
                padButton(
                  icon: Icons.vertical_align_bottom_rounded,
                  onPressed: _hardDrop,
                  tooltip: i18n.t(
                    'toolbox.miniGames.tetris.hard_drop.1e4c9100',
                  ),
                  flex: 2,
                ),
              ],
            ),
          ],
        ),
      );
    }

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
        minimumSize: Size(compact ? 48 : 58, compact ? 48 : 58),
        fixedSize: Size(compact ? 48 : 58, compact ? 48 : 58),
        maximumSize: Size(compact ? 48 : 58, compact ? 48 : 58),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
      return Tooltip(
        message: tooltip,
        child: FilledButton(
          onPressed: onPressed,
          onLongPress: onLongPress,
          style: style,
          child: Icon(icon, size: compact ? 24 : 28),
        ),
      );
    }

    return Center(
      child: Container(
        padding: EdgeInsets.all(compact ? 8 : 14),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(compact ? 16 : 24),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            padButton(
              icon: _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              onPressed: _togglePause,
              tooltip: _paused
                  ? i18n.t('toolbox.miniGames.tetris.resume.7f87ff5e')
                  : i18n.t('toolbox.miniGames.tetris.pause.e6d2c123'),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                padButton(
                  icon: Icons.keyboard_arrow_left_rounded,
                  onPressed: () => _moveHorizontal(-1),
                  tooltip: i18n.t(
                    'toolbox.miniGames.tetris.move_left.d01e9f05',
                  ),
                ),
                const SizedBox(width: 8),
                padButton(
                  icon: Icons.change_circle_rounded,
                  onPressed: _rotate,
                  tooltip: i18n.t(
                    'toolbox.miniGames.tetris.transform.3dd2f28e',
                  ),
                  filled: true,
                ),
                const SizedBox(width: 8),
                padButton(
                  icon: Icons.keyboard_arrow_right_rounded,
                  onPressed: () => _moveHorizontal(1),
                  tooltip: i18n.t(
                    'toolbox.miniGames.tetris.move_right.e85b744f',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            padButton(
              icon: Icons.keyboard_arrow_down_rounded,
              onPressed: () => _stepDown(soft: true),
              onLongPress: _hardDrop,
              tooltip: i18n.t(
                'toolbox.miniGames.tetris.drop_long_press_hard_drop.0faeb5f1',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactControls(BuildContext context, AppI18n i18n) {
    return _buildGamepad(context, i18n, compact: true);
  }

  Widget _buildCompactSideRail(BuildContext context, AppI18n i18n) {
    final colors = Theme.of(context).colorScheme;
    Widget iconAction({
      required IconData icon,
      required String tooltip,
      required VoidCallback? onPressed,
    }) {
      return Tooltip(
        message: tooltip,
        child: IconButton.outlined(
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            fixedSize: const Size(48, 48),
            minimumSize: const Size(48, 48),
            maximumSize: const Size(48, 48),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: BorderSide(color: colors.outlineVariant),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 88,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildNextPreview(context, compact: true),
          const SizedBox(height: 8),
          PopupMenuButton<_TetrisDifficulty>(
            tooltip: i18n.t('toolbox.miniGames.tetris.difficulty.c526df65'),
            onSelected: _setDifficulty,
            itemBuilder: (context) {
              return <PopupMenuEntry<_TetrisDifficulty>>[
                for (final difficulty in _TetrisDifficulty.values)
                  PopupMenuItem<_TetrisDifficulty>(
                    value: difficulty,
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 24,
                          child: _difficulty == difficulty
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: colors.primary,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(_difficultyLabel(i18n, difficulty)),
                      ],
                    ),
                  ),
              ];
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: const Icon(Icons.speed_rounded),
            ),
          ),
          const SizedBox(height: 8),
          iconAction(
            icon: _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            tooltip: _paused
                ? i18n.t('toolbox.miniGames.tetris.resume.7f87ff5e')
                : i18n.t('toolbox.miniGames.tetris.pause.e6d2c123'),
            onPressed: _togglePause,
          ),
          const SizedBox(height: 8),
          iconAction(
            icon: Icons.refresh_rounded,
            tooltip: i18n.t('toolbox.miniGames.tetris.new_game.8857ec9e'),
            onPressed: _newGame,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactGameSurface(BuildContext context, AppI18n i18n) {
    final media = MediaQuery.of(context);
    final colors = Theme.of(context).colorScheme;
    final targetHeight =
        (media.size.height - media.padding.top - media.padding.bottom - 12)
            .clamp(560.0, 740.0);
    return SizedBox(
      height: targetHeight,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          children: <Widget>[
            _buildCompactStatusLine(context, i18n),
            const SizedBox(height: 6),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: _buildBoard(context, compact: true)),
                  const SizedBox(width: 8),
                  _buildCompactSideRail(context, i18n),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildCompactControls(context, i18n),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStatusLine(BuildContext context, AppI18n i18n) {
    final colors = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: colors.onSurfaceVariant,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        children: <Widget>[
          Text(
            '${i18n.t('toolbox.miniGames.tetris.score.81992ab8')}: $_score',
            style: textStyle,
          ),
          Text(
            '${i18n.t('toolbox.miniGames.tetris.lines.7f3795e9')}: $_lines',
            style: textStyle,
          ),
          Text(
            '${i18n.t('toolbox.miniGames.tetris.level.5ea4bdcf')}: $_level',
            style: textStyle,
          ),
          Text(_statusLabel(i18n), style: textStyle),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 520 ||
            MediaQuery.sizeOf(context).height < 760;
        if (compact) {
          return _buildCompactGameSurface(context, i18n);
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
                      label: i18n.t('toolbox.miniGames.tetris.score.81992ab8'),
                      value: '$_score',
                    ),
                    ToolboxMetricCard(
                      label: i18n.t('toolbox.miniGames.tetris.lines.7f3795e9'),
                      value: '$_lines',
                    ),
                    ToolboxMetricCard(
                      label: i18n.t('toolbox.miniGames.tetris.level.5ea4bdcf'),
                      value: '$_level',
                    ),
                    ToolboxMetricCard(
                      label: i18n.t(
                        'toolbox.miniGames.tetris.difficulty.c526df65',
                      ),
                      value: _difficultyLabel(i18n, _difficulty),
                    ),
                    ToolboxMetricCard(
                      label: i18n.t('toolbox.miniGames.tetris.status.b0d4fea8'),
                      value: _statusLabel(i18n),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  i18n.t(
                    'toolbox.miniGames.tetris.swipe_on_the_board_or_use_the.921a2d2a',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                _buildDifficultySettings(context, i18n),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _newGame,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      i18n.t('toolbox.miniGames.tetris.new_game.8857ec9e'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

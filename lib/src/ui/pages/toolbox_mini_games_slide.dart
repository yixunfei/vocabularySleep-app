part of 'toolbox_mini_games.dart';

enum _SlideDirection { up, down, left, right }

class _SlideNumberGame extends StatefulWidget {
  const _SlideNumberGame();

  @override
  State<_SlideNumberGame> createState() => _SlideNumberGameState();
}

class _SlideNumberGameState extends State<_SlideNumberGame> {
  static const int _size = 4;
  final math.Random _random = math.Random();

  late List<int> _board;
  int _score = 0;
  int _bestTile = 0;
  int _target = 2048;
  bool _won = false;
  bool _gameOver = false;
  Offset? _dragStart;
  bool _dragConsumed = false;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    setState(() {
      _board = List<int>.filled(_size * _size, 0);
      _score = 0;
      _bestTile = 0;
      _won = false;
      _gameOver = false;
      _spawnRandomTile();
      _spawnRandomTile();
    });
  }

  void _setTarget(int target) {
    if (_target == target) return;
    setState(() {
      _target = target;
      _won = _bestTile >= _target;
    });
  }

  void _spawnRandomTile() {
    final empty = <int>[
      for (var i = 0; i < _board.length; i += 1)
        if (_board[i] == 0) i,
    ];
    if (empty.isEmpty) return;
    final index = empty[_random.nextInt(empty.length)];
    _board[index] = _random.nextDouble() < 0.9 ? 2 : 4;
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
    if (delta.distance < 18) {
      return;
    }
    _dragConsumed = true;
    if (delta.dx.abs() > delta.dy.abs()) {
      _move(delta.dx > 0 ? _SlideDirection.right : _SlideDirection.left);
    } else {
      _move(delta.dy > 0 ? _SlideDirection.down : _SlideDirection.up);
    }
  }

  void _handleVerticalDragStart(DragStartDetails details) =>
      _handleDragStart(details.localPosition);

  void _handleHorizontalDragStart(DragStartDetails details) =>
      _handleDragStart(details.localPosition);

  void _handleVerticalDragUpdate(DragUpdateDetails details) =>
      _handleDragUpdate(details.localPosition);

  void _handleHorizontalDragUpdate(DragUpdateDetails details) =>
      _handleDragUpdate(details.localPosition);

  void _handleDragEnd([DragEndDetails? _]) {
    _dragStart = null;
    _dragConsumed = false;
  }

  void _move(_SlideDirection direction) {
    if (_gameOver) return;
    final previous = List<int>.from(_board);
    var gained = 0;

    for (var i = 0; i < _size; i += 1) {
      final line = _readLine(i, direction);
      final merged = _mergeLine(line);
      gained += merged.scoreGain;
      _writeLine(i, direction, merged.values);
    }

    if (_listEquals(previous, _board)) return;

    setState(() {
      _score += gained;
      _spawnRandomTile();
      _bestTile = _board.reduce(math.max);
      if (!_won && _bestTile >= _target) {
        _won = true;
      }
      _gameOver = !_hasValidMove();
    });
  }

  List<int> _readLine(int index, _SlideDirection direction) {
    final values = <int>[];
    for (var offset = 0; offset < _size; offset += 1) {
      final row = switch (direction) {
        _SlideDirection.left => index,
        _SlideDirection.right => index,
        _SlideDirection.up => offset,
        _SlideDirection.down => _size - 1 - offset,
      };
      final col = switch (direction) {
        _SlideDirection.left => offset,
        _SlideDirection.right => _size - 1 - offset,
        _SlideDirection.up => index,
        _SlideDirection.down => index,
      };
      values.add(_board[row * _size + col]);
    }
    return values;
  }

  void _writeLine(int index, _SlideDirection direction, List<int> values) {
    for (var offset = 0; offset < _size; offset += 1) {
      final row = switch (direction) {
        _SlideDirection.left => index,
        _SlideDirection.right => index,
        _SlideDirection.up => offset,
        _SlideDirection.down => _size - 1 - offset,
      };
      final col = switch (direction) {
        _SlideDirection.left => offset,
        _SlideDirection.right => _size - 1 - offset,
        _SlideDirection.up => index,
        _SlideDirection.down => index,
      };
      _board[row * _size + col] = values[offset];
    }
  }

  _MergeLineResult _mergeLine(List<int> line) {
    final compact = <int>[
      for (final value in line)
        if (value != 0) value,
    ];
    final merged = <int>[];
    var scoreGain = 0;

    var cursor = 0;
    while (cursor < compact.length) {
      final current = compact[cursor];
      if (cursor + 1 < compact.length && compact[cursor + 1] == current) {
        final next = current * 2;
        merged.add(next);
        scoreGain += next;
        cursor += 2;
      } else {
        merged.add(current);
        cursor += 1;
      }
    }

    while (merged.length < _size) {
      merged.add(0);
    }
    return _MergeLineResult(values: merged, scoreGain: scoreGain);
  }

  bool _hasValidMove() {
    if (_board.any((value) => value == 0)) return true;
    for (var row = 0; row < _size; row += 1) {
      for (var col = 0; col < _size; col += 1) {
        final current = _board[row * _size + col];
        if (row + 1 < _size && _board[(row + 1) * _size + col] == current) {
          return true;
        }
        if (col + 1 < _size && _board[row * _size + (col + 1)] == current) {
          return true;
        }
      }
    }
    return false;
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Color _tileColor(int value) {
    return switch (value) {
      0 => const Color(0xFFCDC1B4),
      2 => const Color(0xFFEEE4DA),
      4 => const Color(0xFFEDE0C8),
      8 => const Color(0xFFF2B179),
      16 => const Color(0xFFF59563),
      32 => const Color(0xFFF67C5F),
      64 => const Color(0xFFF65E3B),
      128 => const Color(0xFFEDCF72),
      256 => const Color(0xFFEDCC61),
      512 => const Color(0xFFEDC850),
      1024 => const Color(0xFFEDC53F),
      2048 => const Color(0xFFEDC22E),
      _ => const Color(0xFF3C3A32),
    };
  }

  Color _tileTextColor(int value) {
    return value <= 4 ? const Color(0xFF776E65) : const Color(0xFFF9F6F2);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final status = _gameOver
        ? i18n.t('toolbox.miniGames.slide.game_over.bc6f5994')
        : _won
        ? i18n.t('toolbox.miniGames.slide.target_reached.bf015ce3')
        : i18n.t('toolbox.miniGames.slide.playing.a76f133d');

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
                  label: i18n.t('toolbox.miniGames.slide.score.21b6ac69'),
                  value: '$_score',
                ),
                ToolboxMetricCard(
                  label: i18n.t('toolbox.miniGames.slide.best_tile.f5bcbfea'),
                  value: '$_bestTile',
                ),
                ToolboxMetricCard(
                  label: i18n.t('toolbox.miniGames.slide.target.6afad01a'),
                  value: '$_target',
                ),
                ToolboxMetricCard(
                  label: i18n.t('toolbox.miniGames.slide.status.e4245e82'),
                  value: status,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('2048'),
                  selected: _target == 2048,
                  onSelected: (_) => _setTarget(2048),
                ),
                ChoiceChip(
                  label: const Text('4096'),
                  selected: _target == 4096,
                  onSelected: (_) => _setTarget(4096),
                ),
                OutlinedButton.icon(
                  onPressed: _newGame,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    i18n.t('toolbox.miniGames.slide.new_game.a2d8dee4'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              i18n.t(
                'toolbox.miniGames.slide.swipe_on_the_board_to_move_tiles.5ae4ef02',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final boardSize = math.min(420.0, constraints.maxWidth);
                return Center(
                  child: _MiniGameScrollLockSurface(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      dragStartBehavior: DragStartBehavior.down,
                      onVerticalDragStart: _handleVerticalDragStart,
                      onVerticalDragUpdate: _handleVerticalDragUpdate,
                      onVerticalDragEnd: _handleDragEnd,
                      onVerticalDragCancel: () => _handleDragEnd(),
                      onHorizontalDragStart: _handleHorizontalDragStart,
                      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
                      onHorizontalDragEnd: _handleDragEnd,
                      onHorizontalDragCancel: () => _handleDragEnd(),
                      child: Container(
                        width: boardSize,
                        height: boardSize,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBBADA0),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _board.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _size,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                          itemBuilder: (context, index) {
                            final value = _board[index];
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              decoration: BoxDecoration(
                                color: _tileColor(value),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                value == 0 ? '' : '$value',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: _tileTextColor(value),
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
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonal(
                  onPressed: () => _move(_SlideDirection.up),
                  child: Text(i18n.t('toolbox.miniGames.slide.up.d59a4395')),
                ),
                FilledButton.tonal(
                  onPressed: () => _move(_SlideDirection.left),
                  child: Text(i18n.t('toolbox.miniGames.slide.left.04efb5dc')),
                ),
                FilledButton.tonal(
                  onPressed: () => _move(_SlideDirection.down),
                  child: Text(i18n.t('toolbox.miniGames.slide.down.8f53047d')),
                ),
                FilledButton.tonal(
                  onPressed: () => _move(_SlideDirection.right),
                  child: Text(i18n.t('toolbox.miniGames.slide.right.070dc40b')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MergeLineResult {
  const _MergeLineResult({required this.values, required this.scoreGain});

  final List<int> values;
  final int scoreGain;
}

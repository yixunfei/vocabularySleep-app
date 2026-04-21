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

  String _text(AppI18n i18n, {required String zh, required String en}) {
    return pickUiText(i18n, zh: zh, en: en);
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
        ? _text(i18n, zh: '游戏结束', en: 'Game over')
        : _won
        ? _text(i18n, zh: '已达到目标', en: 'Target reached')
        : _text(i18n, zh: '进行中', en: 'Playing');

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
                  label: _text(i18n, zh: '最大数字', en: 'Best tile'),
                  value: '$_bestTile',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '目标', en: 'Target'),
                  value: '$_target',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '状态', en: 'Status'),
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
                  label: Text(_text(i18n, zh: '新开一局', en: 'New game')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _text(
                i18n,
                zh: '在棋盘上滑动即可移动数字，页面滚动不会抢走滑动手势。',
                en: 'Swipe on the board to move tiles. Page scrolling will no longer steal the gesture.',
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
                  child: Text(_text(i18n, zh: '上', en: 'Up')),
                ),
                FilledButton.tonal(
                  onPressed: () => _move(_SlideDirection.left),
                  child: Text(_text(i18n, zh: '左', en: 'Left')),
                ),
                FilledButton.tonal(
                  onPressed: () => _move(_SlideDirection.down),
                  child: Text(_text(i18n, zh: '下', en: 'Down')),
                ),
                FilledButton.tonal(
                  onPressed: () => _move(_SlideDirection.right),
                  child: Text(_text(i18n, zh: '右', en: 'Right')),
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

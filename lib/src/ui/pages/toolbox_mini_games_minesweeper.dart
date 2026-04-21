part of 'toolbox_mini_games.dart';

class _MinesweeperGame extends StatefulWidget {
  const _MinesweeperGame();

  @override
  State<_MinesweeperGame> createState() => _MinesweeperGameState();
}

class _MinesweeperGameState extends State<_MinesweeperGame> {
  int _rows = 9;
  int _cols = 9;
  int _mineCount = 10;
  int _draftRows = 9;
  int _draftCols = 9;
  int _draftMines = 10;
  late List<_MineCell> _cells;
  bool _firstMove = true;
  bool _lost = false;
  bool _won = false;
  bool _flagMode = false;
  int _revealedSafe = 0;
  bool _fullscreen = false;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    if (_fullscreen) {
      unawaited(_exitMiniGameFullscreen());
    }
    super.dispose();
  }

  int get _safeCellTotal => _rows * _cols - _mineCount;

  int _indexOf(int row, int col) => row * _cols + col;

  List<int> _neighbors(int index) {
    final row = index ~/ _cols;
    final col = index % _cols;
    final list = <int>[];
    for (var dr = -1; dr <= 1; dr += 1) {
      for (var dc = -1; dc <= 1; dc += 1) {
        if (dr == 0 && dc == 0) continue;
        final nr = row + dr;
        final nc = col + dc;
        if (nr < 0 || nr >= _rows || nc < 0 || nc >= _cols) continue;
        list.add(_indexOf(nr, nc));
      }
    }
    return list;
  }

  void _syncDraftMineCap() {
    final maxMine = math.max(1, _draftRows * _draftCols - 1);
    if (_draftMines > maxMine) {
      _draftMines = maxMine;
    }
  }

  void _applyPreset(_MinesweeperPreset preset) {
    setState(() {
      _draftRows = preset.rows;
      _draftCols = preset.cols;
      _draftMines = preset.mines;
      _syncDraftMineCap();
      _rows = _draftRows;
      _cols = _draftCols;
      _mineCount = _draftMines;
      _flagMode = false;
      _startNewGame();
    });
  }

  void _applyCustom() {
    setState(() {
      _syncDraftMineCap();
      _rows = _draftRows;
      _cols = _draftCols;
      _mineCount = _draftMines;
      _flagMode = false;
      _startNewGame();
    });
  }

  void _startNewGame({int? safeIndex}) {
    final random = math.Random();
    _cells = List<_MineCell>.generate(_rows * _cols, (_) => _MineCell());
    var placed = 0;
    while (placed < _mineCount) {
      final index = random.nextInt(_cells.length);
      if (index == safeIndex || _cells[index].hasMine) continue;
      _cells[index].hasMine = true;
      placed += 1;
    }
    for (var i = 0; i < _cells.length; i += 1) {
      if (_cells[i].hasMine) continue;
      _cells[i].neighborMines = _neighbors(
        i,
      ).where((n) => _cells[n].hasMine).length;
    }
    _firstMove = true;
    _lost = false;
    _won = false;
    _revealedSafe = 0;
  }

  Future<void> _setFullscreen(bool value) async {
    if (_fullscreen == value) {
      return;
    }
    setState(() {
      _fullscreen = value;
    });
    if (value) {
      await _enterMiniGameFullscreen();
    } else {
      await _exitMiniGameFullscreen();
    }
  }

  String _text(AppI18n i18n, {required String zh, required String en}) {
    return pickUiText(i18n, zh: zh, en: en);
  }

  String _presetLabel(AppI18n i18n, _MinesweeperPreset preset) {
    if (preset.label == 'Easy') {
      return _text(i18n, zh: '简单', en: 'Easy');
    }
    if (preset.label == 'Medium') {
      return _text(i18n, zh: '标准', en: 'Medium');
    }
    return _text(i18n, zh: '挑战', en: 'Hard');
  }

  String _statusLabel(AppI18n i18n) {
    if (_lost) {
      return _text(i18n, zh: '爆炸', en: 'Boom');
    }
    if (_won) {
      return _text(i18n, zh: '已通关', en: 'Cleared');
    }
    return _text(i18n, zh: '进行中', en: 'Playing');
  }

  void _revealHint() {
    if (_lost || _won) {
      return;
    }
    final hiddenSafe = <int>[
      for (var index = 0; index < _cells.length; index += 1)
        if (!_cells[index].revealed &&
            _cells[index].mark != _MineMark.flag &&
            !_cells[index].hasMine)
          index,
    ];
    if (hiddenSafe.isEmpty) {
      return;
    }
    final target = hiddenSafe[math.Random().nextInt(hiddenSafe.length)];
    _reveal(target);
    if (!mounted || _won) {
      return;
    }
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final row = target ~/ _cols + 1;
    final col = target % _cols + 1;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _text(
            i18n,
            zh: '提示已翻开第 $row 行第 $col 列的安全格。',
            en: 'Hint revealed a safe cell at row $row, column $col.',
          ),
        ),
      ),
    );
  }

  Widget _buildBoard(BuildContext context, {required bool fullscreen}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final viewportHeight = constraints.maxHeight;
        final targetCell = _miniGameCompactLayout(context) ? 22.0 : 26.0;
        final boardWidth = fullscreen
            ? _cols *
                  (math.min(viewportWidth / _cols, viewportHeight / _rows) *
                          0.96)
                      .clamp(8.0, 36.0)
            : math.max(viewportWidth, _cols * targetCell);
        final boardHeight = fullscreen
            ? _rows * (boardWidth / _cols)
            : boardWidth * _rows / _cols;
        final cellExtent = boardWidth / _cols;
        return _MiniGameScrollLockSurface(
          child: InteractiveViewer(
            minScale: 0.65,
            maxScale: 4.0,
            boundaryMargin: const EdgeInsets.all(24),
            child: Center(
              child: SizedBox(
                width: boardWidth,
                height: boardHeight,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _cells.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _cols,
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _onCellTap(index),
                      onLongPress: () => _cycleMark(index),
                      child: _MineCellTile(
                        cell: _cells[index],
                        extent: cellExtent,
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

  void _cycleMark(int index) {
    if (_lost || _won) return;
    final cell = _cells[index];
    if (cell.revealed) return;
    setState(() {
      cell.mark = switch (cell.mark) {
        _MineMark.none => _MineMark.flag,
        _MineMark.flag => _MineMark.question,
        _MineMark.question => _MineMark.none,
      };
    });
  }

  void _reveal(int index) {
    if (_lost || _won) return;
    final cell = _cells[index];
    if (cell.revealed || cell.mark == _MineMark.flag) return;
    if (cell.mark == _MineMark.question) {
      cell.mark = _MineMark.none;
    }

    setState(() {
      if (_firstMove) {
        _firstMove = false;
        if (_cells[index].hasMine) {
          _startNewGame(safeIndex: index);
          _firstMove = false;
        }
      }

      if (_cells[index].hasMine) {
        _lost = true;
        for (final c in _cells) {
          if (c.hasMine) {
            c.revealed = true;
          }
          if (!c.hasMine && c.mark == _MineMark.flag) {
            c.revealed = true;
            c.wrongFlag = true;
          }
        }
        _cells[index].exploded = true;
        return;
      }

      _floodReveal(index);
      if (_revealedSafe >= _safeCellTotal) {
        _won = true;
        for (final c in _cells) {
          if (c.hasMine) c.mark = _MineMark.flag;
        }
      }
    });

    if (_won && context.mounted) {
      final i18n = AppI18n(Localizations.localeOf(context).languageCode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(i18n, zh: '扫雷通关，已自动插旗。', en: 'Minesweeper cleared!'),
          ),
        ),
      );
    }
  }

  void _floodReveal(int start) {
    final queue = Queue<int>()..add(start);
    while (queue.isNotEmpty) {
      final index = queue.removeFirst();
      final cell = _cells[index];
      if (cell.revealed || cell.mark != _MineMark.none) continue;
      cell.revealed = true;
      if (!cell.hasMine) _revealedSafe += 1;
      if (cell.neighborMines > 0) continue;
      for (final neighbor in _neighbors(index)) {
        final next = _cells[neighbor];
        if (!next.revealed && next.mark == _MineMark.none && !next.hasMine) {
          queue.add(neighbor);
        }
      }
    }
  }

  void _onCellTap(int index) {
    if (_flagMode) {
      _cycleMark(index);
      return;
    }
    _reveal(index);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final flags = _cells.where((c) => c.mark == _MineMark.flag).length;
    final questions = _cells.where((c) => c.mark == _MineMark.question).length;
    const presets = <_MinesweeperPreset>[
      _MinesweeperPreset(label: 'Easy', rows: 9, cols: 9, mines: 10),
      _MinesweeperPreset(label: 'Medium', rows: 16, cols: 16, mines: 40),
      _MinesweeperPreset(label: 'Hard', rows: 24, cols: 24, mines: 99),
    ];
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
                      onPressed: _lost || _won ? null : _revealHint,
                      icon: const Icon(Icons.lightbulb_outline_rounded),
                      label: Text(_text(i18n, zh: '提示', en: 'Hint')),
                    ),
                    FilterChip(
                      label: Text(_text(i18n, zh: '插旗模式', en: 'Flag mode')),
                      selected: _flagMode,
                      onSelected: (value) {
                        setState(() {
                          _flagMode = value;
                        });
                      },
                    ),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _startNewGame()),
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
                      value: '${_rows}x$_cols',
                    ),
                    ToolboxMetricCard(
                      label: _text(i18n, zh: '地雷', en: 'Mines'),
                      value: '$_mineCount',
                    ),
                    ToolboxMetricCard(
                      label: _text(i18n, zh: '剩余地雷', en: 'Mines left'),
                      value: '${math.max(0, _mineCount - flags)}',
                    ),
                    ToolboxMetricCard(
                      label: _text(i18n, zh: '状态', en: 'Status'),
                      value: _statusLabel(i18n),
                    ),
                  ],
                ),
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
              spacing: 8,
              runSpacing: 8,
              children: presets
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(
                        '${_presetLabel(i18n, preset)} ${preset.rows}x${preset.cols}/${preset.mines}',
                      ),
                      selected:
                          _rows == preset.rows &&
                          _cols == preset.cols &&
                          _mineCount == preset.mines,
                      onSelected: (_) => _applyPreset(preset),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _text(i18n, zh: '自定义设置', en: 'Custom setup'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${_text(i18n, zh: '行数', en: 'Rows')}: $_draftRows'),
                    Slider(
                      value: _draftRows.toDouble(),
                      min: 5,
                      max: 30,
                      divisions: 25,
                      label: '$_draftRows',
                      onChanged: (value) {
                        setState(() {
                          _draftRows = value.round();
                          _syncDraftMineCap();
                        });
                      },
                    ),
                    Text(
                      '${_text(i18n, zh: '列数', en: 'Columns')}: $_draftCols',
                    ),
                    Slider(
                      value: _draftCols.toDouble(),
                      min: 5,
                      max: 30,
                      divisions: 25,
                      label: '$_draftCols',
                      onChanged: (value) {
                        setState(() {
                          _draftCols = value.round();
                          _syncDraftMineCap();
                        });
                      },
                    ),
                    Text(
                      '${_text(i18n, zh: '地雷数', en: 'Mines')}: $_draftMines',
                    ),
                    Slider(
                      value: _draftMines.toDouble(),
                      min: 1,
                      max: math.max(1, _draftRows * _draftCols - 1).toDouble(),
                      divisions: math.max(1, _draftRows * _draftCols - 2),
                      label: '$_draftMines',
                      onChanged: (value) {
                        setState(() {
                          _draftMines = value.round();
                          _syncDraftMineCap();
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: _applyCustom,
                          icon: const Icon(Icons.build_rounded),
                          label: Text(
                            _text(i18n, zh: '应用自定义', en: 'Apply custom'),
                          ),
                        ),
                        FilterChip(
                          label: Text(_text(i18n, zh: '插旗模式', en: 'Flag mode')),
                          selected: _flagMode,
                          onSelected: (value) {
                            setState(() {
                              _flagMode = value;
                            });
                          },
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _lost || _won ? null : _revealHint,
                          icon: const Icon(Icons.lightbulb_outline_rounded),
                          label: Text(_text(i18n, zh: '提示', en: 'Hint')),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _setFullscreen(true),
                          icon: const Icon(Icons.fullscreen_rounded),
                          label: Text(
                            _text(i18n, zh: '全屏棋盘', en: 'Fullscreen board'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(
                  label: _text(i18n, zh: '棋盘', en: 'Board'),
                  value: '${_rows}x$_cols',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '地雷', en: 'Mines'),
                  value: '$_mineCount',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '剩余地雷', en: 'Mines left'),
                  value: '${math.max(0, _mineCount - flags)}',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '旗子', en: 'Flags'),
                  value: '$flags',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '问号', en: 'Question'),
                  value: '$questions',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '进度', en: 'Progress'),
                  value: '$_revealedSafe / $_safeCellTotal',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '状态', en: 'Status'),
                  value: _statusLabel(i18n),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _flagMode
                  ? _text(
                      i18n,
                      zh: '插旗模式已开启：点击会在旗子、问号和空白之间切换。',
                      en: 'Flag mode is on: taps cycle through flag, question, and none.',
                    )
                  : _text(
                      i18n,
                      zh: '轻触翻开，长按可循环标记旗子和问号。',
                      en: 'Tap to reveal, long press to cycle marks.',
                    ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: _miniGameCompactLayout(context) ? 320 : 420,
              child: _buildBoard(context, fullscreen: false),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() => _startNewGame()),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_text(i18n, zh: '新开一局', en: 'New game')),
            ),
          ],
        ),
      ),
    );
  }
}

class _MineCell {
  bool hasMine = false;
  bool revealed = false;
  _MineMark mark = _MineMark.none;
  bool exploded = false;
  bool wrongFlag = false;
  int neighborMines = 0;
}

enum _MineMark { none, flag, question }

class _MinesweeperPreset {
  const _MinesweeperPreset({
    required this.label,
    required this.rows,
    required this.cols,
    required this.mines,
  });

  final String label;
  final int rows;
  final int cols;
  final int mines;
}

class _MineCellTile extends StatelessWidget {
  const _MineCellTile({required this.cell, required this.extent});

  final _MineCell cell;
  final double extent;

  static const Map<int, Color> _numbers = <int, Color>{
    1: Color(0xFF2E6CE6),
    2: Color(0xFF2EA369),
    3: Color(0xFFC94640),
    4: Color(0xFF7B3DE0),
    5: Color(0xFFAB5C1D),
    6: Color(0xFF1F9FB8),
    7: Color(0xFF5E5E5E),
    8: Color(0xFF1D1D1D),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconSize = (extent * 0.62).clamp(7.0, 18.0);
    final fontSize = (extent * 0.56).clamp(6.0, 18.0);
    Widget child;
    if (cell.wrongFlag) {
      child = Icon(
        Icons.close_rounded,
        color: const Color(0xFFD32F2F),
        size: iconSize,
      );
    } else if (cell.revealed && cell.hasMine) {
      child = Icon(
        cell.exploded ? Icons.close_rounded : Icons.circle,
        color: cell.exploded ? const Color(0xFFD32F2F) : scheme.error,
        size: iconSize,
      );
    } else if (!cell.revealed && cell.mark == _MineMark.flag) {
      child = Icon(
        Icons.flag_rounded,
        color: const Color(0xFFC14E2D),
        size: iconSize,
      );
    } else if (!cell.revealed && cell.mark == _MineMark.question) {
      child = FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: fontSize,
          ),
        ),
      );
    } else if (cell.revealed && cell.neighborMines > 0) {
      child = FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '${cell.neighborMines}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: fontSize,
            color: _numbers[cell.neighborMines],
          ),
        ),
      );
    } else {
      child = const SizedBox.shrink();
    }
    return Container(
      margin: EdgeInsets.all(extent <= 16 ? 0.18 : 0.5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: (cell.revealed || cell.wrongFlag)
            ? scheme.surfaceContainerLow
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(extent <= 16 ? 2 : 4),
        border: Border.all(
          color: scheme.outlineVariant,
          width: extent <= 16 ? 0.45 : 0.9,
        ),
      ),
      child: child,
    );
  }
}

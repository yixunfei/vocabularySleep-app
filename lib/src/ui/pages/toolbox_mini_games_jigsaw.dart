part of 'toolbox_mini_games.dart';

class _JigsawGame extends StatefulWidget {
  const _JigsawGame();

  @override
  State<_JigsawGame> createState() => _JigsawGameState();
}

class _JigsawGameState extends State<_JigsawGame> {
  ui.Image? _sourceImage;
  Uint8List? _sourceBytes;
  int _rows = 3;
  int _cols = 3;
  List<int> _tiles = const <int>[];
  int? _selectedTile;
  int? _hintTargetIndex;
  Timer? _hintTimer;
  Timer? _ticker;
  final Stopwatch _stopwatch = Stopwatch();
  Duration _elapsed = Duration.zero;
  int _moves = 0;
  bool _loading = false;
  bool _solved = false;
  bool _resultShown = false;
  bool _fullscreen = false;
  String? _error;

  @override
  void dispose() {
    _ticker?.cancel();
    _hintTimer?.cancel();
    _stopwatch.stop();
    _sourceImage?.dispose();
    if (_fullscreen) {
      unawaited(_exitMiniGameFullscreen());
    }
    super.dispose();
  }

  String _text(AppI18n i18n, {required String zh, required String en}) {
    return pickUiText(i18n, zh: zh, en: en);
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

  String _statusLabel(AppI18n i18n) {
    return _solved
        ? _text(i18n, zh: '已完成', en: 'Solved')
        : _text(i18n, zh: '进行中', en: 'Playing');
  }

  Future<void> _importImage() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }
      final bytes = result.files.single.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = _text(
            AppI18n(Localizations.localeOf(context).languageCode),
            zh: '读取图片数据失败。',
            en: 'Failed to read image bytes.',
          );
        });
        return;
      }
      final image = await _decodeImage(bytes);
      if (!mounted) {
        image.dispose();
        return;
      }
      final old = _sourceImage;
      setState(() {
        _sourceImage = image;
        _sourceBytes = bytes;
        _tiles = _shuffleTiles(_rows, _cols);
        _selectedTile = null;
        _hintTargetIndex = null;
        _moves = 0;
        _solved = false;
        _resultShown = false;
        _loading = false;
        _elapsed = Duration.zero;
      });
      _startTimer();
      old?.dispose();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _text(
          AppI18n(Localizations.localeOf(context).languageCode),
          zh: '导入图片失败。',
          en: 'Failed to import image.',
        );
      });
    }
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _startTimer() {
    _ticker?.cancel();
    _stopwatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _solved || _sourceImage == null) return;
      setState(() {
        _elapsed = _stopwatch.elapsed;
      });
    });
  }

  void _stopTimer() {
    _stopwatch.stop();
    _ticker?.cancel();
    _ticker = null;
    _elapsed = _stopwatch.elapsed;
  }

  String _formatDuration(Duration value) {
    final totalSeconds = value.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  List<int> _shuffleTiles(int rows, int cols) {
    final total = rows * cols;
    final list = List<int>.generate(total, (i) => i);
    if (total <= 1) return list;
    final random = math.Random();
    do {
      list.shuffle(random);
    } while (_isSolved(list));
    return list;
  }

  bool _isSolved(List<int> board) {
    for (var i = 0; i < board.length; i += 1) {
      if (board[i] != i) return false;
    }
    return true;
  }

  void _changeRows(int value) {
    setState(() {
      _rows = value.clamp(2, 50);
      _selectedTile = null;
      _hintTargetIndex = null;
      _resultShown = false;
      _moves = 0;
      _solved = false;
      _tiles = _sourceImage == null
          ? const <int>[]
          : _shuffleTiles(_rows, _cols);
      _elapsed = Duration.zero;
    });
    if (_sourceImage != null) {
      _startTimer();
    }
  }

  void _changeCols(int value) {
    setState(() {
      _cols = value.clamp(2, 50);
      _selectedTile = null;
      _hintTargetIndex = null;
      _resultShown = false;
      _moves = 0;
      _solved = false;
      _tiles = _sourceImage == null
          ? const <int>[]
          : _shuffleTiles(_rows, _cols);
      _elapsed = Duration.zero;
    });
    if (_sourceImage != null) {
      _startTimer();
    }
  }

  void _setPresetGrid(int rows, int cols) {
    setState(() {
      _rows = rows;
      _cols = cols;
      _selectedTile = null;
      _hintTargetIndex = null;
      _resultShown = false;
      _moves = 0;
      _solved = false;
      _tiles = _sourceImage == null
          ? const <int>[]
          : _shuffleTiles(_rows, _cols);
      _elapsed = Duration.zero;
    });
    if (_sourceImage != null) {
      _startTimer();
    }
  }

  void _shuffle() {
    if (_sourceImage == null) return;
    setState(() {
      _tiles = _shuffleTiles(_rows, _cols);
      _selectedTile = null;
      _hintTargetIndex = null;
      _resultShown = false;
      _moves = 0;
      _solved = false;
      _elapsed = Duration.zero;
    });
    _startTimer();
  }

  void _showHint() {
    if (_sourceImage == null || _solved || _tiles.isEmpty) return;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final mismatch = <int>[
      for (var index = 0; index < _tiles.length; index += 1)
        if (_tiles[index] != index) index,
    ];
    if (mismatch.isEmpty) return;
    final targetCell = mismatch.first;
    final pieceValue = _tiles[targetCell];
    final correctIndex = pieceValue;
    final correctRow = correctIndex ~/ _cols + 1;
    final correctCol = correctIndex % _cols + 1;
    setState(() {
      _hintTargetIndex = correctIndex;
    });
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _hintTargetIndex = null;
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _text(
            i18n,
            zh: '提示：该拼块应该移动到第 $correctRow 行第 $correctCol 列。',
            en: 'Hint: this piece should go to row $correctRow, column $correctCol.',
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showSolvedDialog() async {
    if (!mounted || _resultShown) return;
    _resultShown = true;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_text(i18n, zh: '恭喜完成', en: 'Congratulations')),
          content: Text(
            _text(
              i18n,
              zh: '拼图已完成。\n网格：${_rows}x$_cols\n步数：$_moves\n用时：${_formatDuration(_elapsed)}',
              en: 'Puzzle solved.\nGrid: ${_rows}x$_cols\nMoves: $_moves\nTime: ${_formatDuration(_elapsed)}',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_text(i18n, zh: '关闭', en: 'Close')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _shuffle();
              },
              child: Text(_text(i18n, zh: '再来一局', en: 'Play again')),
            ),
          ],
        );
      },
    );
  }

  void _tapTile(int boardIndex) {
    if (_sourceImage == null || _solved) return;
    final selected = _selectedTile;
    if (selected == null) {
      setState(() => _selectedTile = boardIndex);
      return;
    }
    if (selected == boardIndex) {
      setState(() => _selectedTile = null);
      return;
    }
    setState(() {
      final next = List<int>.from(_tiles);
      final tmp = next[selected];
      next[selected] = next[boardIndex];
      next[boardIndex] = tmp;
      _tiles = next;
      _selectedTile = null;
      _hintTargetIndex = null;
      _moves += 1;
      _solved = _isSolved(next);
    });
    if (_solved && context.mounted) {
      _stopTimer();
      unawaited(_showSolvedDialog());
    }
  }

  Widget _buildPuzzleBoard(BuildContext context, {required bool fullscreen}) {
    final image = _sourceImage!;
    final tileCount = _tiles.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final viewportHeight = constraints.maxHeight;
        final targetTile = _miniGameCompactLayout(context) ? 54.0 : 64.0;
        final boardWidth = fullscreen
            ? _cols *
                  (math.min(viewportWidth / _cols, viewportHeight / _rows) *
                          0.96)
                      .clamp(24.0, 96.0)
            : math.max(viewportWidth, _cols * targetTile);
        final boardHeight = fullscreen
            ? _rows * (boardWidth / _cols)
            : boardWidth * _rows / _cols;
        return _MiniGameScrollLockSurface(
          child: InteractiveViewer(
            minScale: 0.6,
            maxScale: 4,
            boundaryMargin: const EdgeInsets.all(24),
            child: Center(
              child: SizedBox(
                width: boardWidth,
                height: boardHeight,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tileCount,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _cols,
                  ),
                  itemBuilder: (context, index) {
                    final selected = _selectedTile == index;
                    final hinted = _hintTargetIndex == index;
                    return GestureDetector(
                      onTap: () => _tapTile(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        margin: EdgeInsets.all(
                          boardWidth / _cols <= 56 ? 1 : 2,
                        ),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            fullscreen ? 8 : 6,
                          ),
                          border: Border.all(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : hinted
                                ? Colors.amber.shade700
                                : Theme.of(context).colorScheme.outlineVariant,
                            width: selected || hinted ? 2 : 1,
                          ),
                        ),
                        child: CustomPaint(
                          painter: _PuzzleTilePainter(
                            image: image,
                            sourceTileIndex: _tiles[index],
                            rowCount: _rows,
                            colCount: _cols,
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

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
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
                      onPressed: _sourceImage == null || _loading
                          ? null
                          : _showHint,
                      icon: const Icon(Icons.lightbulb_outline_rounded),
                      label: Text(_text(i18n, zh: '提示', en: 'Hint')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _sourceImage == null || _loading
                          ? null
                          : _shuffle,
                      icon: const Icon(Icons.shuffle_rounded),
                      label: Text(_text(i18n, zh: '打乱重排', en: 'Shuffle')),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    ToolboxMetricCard(
                      label: _text(i18n, zh: '网格', en: 'Grid'),
                      value: '${_rows}x$_cols',
                    ),
                    ToolboxMetricCard(
                      label: _text(i18n, zh: '步数', en: 'Moves'),
                      value: '$_moves',
                    ),
                    ToolboxMetricCard(
                      label: _text(i18n, zh: '用时', en: 'Time'),
                      value: _formatDuration(_elapsed),
                    ),
                    ToolboxMetricCard(
                      label: _text(i18n, zh: '状态', en: 'Status'),
                      value: _statusLabel(i18n),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _sourceImage == null
                      ? Center(
                          child: Text(
                            _text(
                              i18n,
                              zh: '先导入一张图片再进入全屏拼图。',
                              en: 'Import an image first to use fullscreen puzzle mode.',
                            ),
                          ),
                        )
                      : _buildPuzzleBoard(context, fullscreen: true),
                ),
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
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _loading ? null : _importImage,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    _loading
                        ? _text(i18n, zh: '导入中...', en: 'Importing...')
                        : _text(i18n, zh: '导入图片', en: 'Import image'),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _sourceImage == null || _loading
                      ? null
                      : _showHint,
                  icon: const Icon(Icons.lightbulb_outline_rounded),
                  label: Text(_text(i18n, zh: '提示', en: 'Hint')),
                ),
                OutlinedButton.icon(
                  onPressed: _sourceImage == null || _loading ? null : _shuffle,
                  icon: const Icon(Icons.shuffle_rounded),
                  label: Text(_text(i18n, zh: '打乱重排', en: 'Shuffle')),
                ),
                OutlinedButton.icon(
                  onPressed: _sourceImage == null || _loading
                      ? null
                      : () => _setFullscreen(true),
                  icon: const Icon(Icons.fullscreen_rounded),
                  label: Text(_text(i18n, zh: '全屏拼图', en: 'Fullscreen')),
                ),
                for (final preset in const <(int, int)>[
                  (3, 3),
                  (4, 4),
                  (5, 5),
                  (8, 8),
                  (10, 10),
                ])
                  ChoiceChip(
                    label: Text('${preset.$1}x${preset.$2}'),
                    selected: _rows == preset.$1 && _cols == preset.$2,
                    onSelected: (_) => _setPresetGrid(preset.$1, preset.$2),
                  ),
              ],
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(
                  label: _text(i18n, zh: '网格', en: 'Grid'),
                  value: '${_rows}x$_cols',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '步数', en: 'Moves'),
                  value: '$_moves',
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '用时', en: 'Time'),
                  value: _formatDuration(_elapsed),
                ),
                ToolboxMetricCard(
                  label: _text(i18n, zh: '状态', en: 'Status'),
                  value: _statusLabel(i18n),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('${_text(i18n, zh: '行数', en: 'Rows')}: $_rows'),
                    Slider(
                      value: _rows.toDouble(),
                      min: 2,
                      max: 50,
                      divisions: 48,
                      label: '$_rows',
                      onChanged: (value) => _changeRows(value.round()),
                    ),
                    Text('${_text(i18n, zh: '列数', en: 'Columns')}: $_cols'),
                    Slider(
                      value: _cols.toDouble(),
                      min: 2,
                      max: 50,
                      divisions: 48,
                      label: '$_cols',
                      onChanged: (value) => _changeCols(value.round()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_sourceImage == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Text(
                  _text(
                    i18n,
                    zh: '导入一张图片后即可开始电子拼图。',
                    en: 'Import an image to start the jigsaw.',
                  ),
                ),
              )
            else ...<Widget>[
              Text(
                _text(i18n, zh: '原图预览', en: 'Preview'),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = math.min(240.0, constraints.maxWidth);
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: width,
                      height: width,
                      child: Image.memory(_sourceBytes!, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                _text(i18n, zh: '拼图棋盘', en: 'Puzzle board'),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: _miniGameCompactLayout(context) ? 320 : 420,
                child: _buildPuzzleBoard(context, fullscreen: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PuzzleTilePainter extends CustomPainter {
  const _PuzzleTilePainter({
    required this.image,
    required this.sourceTileIndex,
    required this.rowCount,
    required this.colCount,
  });

  final ui.Image image;
  final int sourceTileIndex;
  final int rowCount;
  final int colCount;

  @override
  void paint(Canvas canvas, Size size) {
    final imageW = image.width.toDouble();
    final imageH = image.height.toDouble();
    final crop = math.min(imageW, imageH);
    final cropL = (imageW - crop) / 2;
    final cropT = (imageH - crop) / 2;
    final tileWidth = crop / colCount;
    final tileHeight = crop / rowCount;
    final srcRow = sourceTileIndex ~/ colCount;
    final srcCol = sourceTileIndex % colCount;
    final src = Rect.fromLTWH(
      cropL + srcCol * tileWidth,
      cropT + srcRow * tileHeight,
      tileWidth,
      tileHeight,
    );
    canvas.drawImageRect(image, src, Offset.zero & size, Paint());
  }

  @override
  bool shouldRepaint(covariant _PuzzleTilePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.sourceTileIndex != sourceTileIndex ||
        oldDelegate.rowCount != rowCount ||
        oldDelegate.colCount != colCount;
  }
}

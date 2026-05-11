part of 'toolbox_human_tests.dart';

enum _VisualSearchMode { search, difference, linkMatch }

class VisualSearchTestPage extends StatelessWidget {
  const VisualSearchTestPage({super.key});

  static const Color _accent = Color(0xFF457B9D);

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '视觉搜索', en: 'Visual search'),
      subtitle: pickUiText(
        i18n,
        zh: '在密集网格中快速定位目标，并在左右面板之间辨别细微差异。',
        en: 'Find the target in dense grids, or compare two panels to locate the subtle difference.',
      ),
      accent: _accent,
      icon: Icons.manage_search_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：选择模式并开始扫描',
        en: 'Next: choose a mode and start scanning',
      ),
      child: const _VisualSearchCard(),
    );
  }
}

class _VisualSearchCell {
  const _VisualSearchCell({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

class _VisualSearchLinkTile {
  const _VisualSearchLinkTile({required this.pairId, required this.cell});

  final int pairId;
  final _VisualSearchCell cell;
}

class _VisualSearchGridPoint {
  const _VisualSearchGridPoint(this.row, this.col);

  final int row;
  final int col;
}

class _VisualSearchLinkRouteResult {
  const _VisualSearchLinkRouteResult({
    required this.connected,
    required this.path,
    required this.blockedIndexes,
  });

  final bool connected;
  final List<_VisualSearchGridPoint> path;
  final Set<int> blockedIndexes;
}

enum _VisualSearchLinkFeedbackType { success, blocked, mismatch }

class _VisualSearchLinkFeedback {
  const _VisualSearchLinkFeedback({
    required this.type,
    required this.path,
    required this.markerIndexes,
  });

  final _VisualSearchLinkFeedbackType type;
  final List<_VisualSearchGridPoint> path;
  final Set<int> markerIndexes;
}

class _VisualSearchRoundRecord {
  const _VisualSearchRoundRecord({
    required this.mode,
    required this.correct,
    required this.milliseconds,
    required this.gridSize,
  });

  final _VisualSearchMode mode;
  final bool correct;
  final int milliseconds;
  final int gridSize;
}

class _VisualSearchCard extends StatefulWidget {
  const _VisualSearchCard();

  @override
  State<_VisualSearchCard> createState() => _VisualSearchCardState();
}

class _VisualSearchCardState extends State<_VisualSearchCard> {
  static const int _linkMaxTurns = 2;
  static const double _linkTileSpacing = 7;
  static const List<IconData> _icons = <IconData>[
    Icons.circle_rounded,
    Icons.square_rounded,
    Icons.change_history_rounded,
    Icons.star_rounded,
    Icons.favorite_rounded,
    Icons.auto_awesome_rounded,
    Icons.wb_sunny_rounded,
    Icons.local_fire_department_rounded,
  ];
  static const List<Color> _colors = <Color>[
    Color(0xFF457B9D),
    Color(0xFF4E8B6B),
    Color(0xFFB05C5C),
    Color(0xFFD08A3A),
    Color(0xFF7A6AA8),
    Color(0xFF2F8D8E),
  ];

  final math.Random _random = math.Random();
  final Stopwatch _stopwatch = Stopwatch();
  final List<_VisualSearchRoundRecord> _records = <_VisualSearchRoundRecord>[];
  Timer? _transitionTimer;
  Timer? _ticker;

  _VisualSearchMode _mode = _VisualSearchMode.search;
  int _roundCount = 10;
  int _gridSize = 5;
  int _linkRows = 6;
  int _linkCols = 6;
  int _roundIndex = 0;
  int _correct = 0;
  int _wrong = 0;
  int _moves = 0;
  int _matches = 0;
  int _streak = 0;
  int _bestStreak = 0;
  bool _running = false;
  bool _done = false;
  bool _linkIgnorePath = false;
  int? _correctIndex;
  int? _lastTappedIndex;
  int? _selectedLinkIndex;
  int? _lastLinkIndex;
  bool? _lastCorrect;
  _VisualSearchLinkFeedback? _linkFeedback;
  Duration _elapsed = Duration.zero;
  List<_VisualSearchCell> _cells = const <_VisualSearchCell>[];
  List<_VisualSearchCell> _leftCells = const <_VisualSearchCell>[];
  List<_VisualSearchCell> _rightCells = const <_VisualSearchCell>[];
  List<_VisualSearchLinkTile?> _linkTiles = const <_VisualSearchLinkTile?>[];
  Set<int> _clearedLinkIndexes = const <int>{};

  bool get _linkMode => _mode == _VisualSearchMode.linkMatch;

  int get _activeGridSize {
    if (_mode == _VisualSearchMode.difference) {
      return math.min(_gridSize, 5);
    }
    if (_linkMode) {
      return _linkRows;
    }
    return _gridSize;
  }

  int get _linkPairCount => (_linkRows * _linkCols) ~/ 2;

  int get _linkRemainingPairs => math.max(0, _linkPairCount - _matches);

  double get _accuracy {
    final total = _correct + _wrong;
    return total == 0 ? 0 : _correct / total;
  }

  int get _averageMs {
    if (_records.isEmpty) {
      return 0;
    }
    final total = _records.fold<int>(0, (sum, item) => sum + item.milliseconds);
    return (total / _records.length).round();
  }

  @override
  void initState() {
    super.initState();
    _buildPreviewRound();
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  void _buildPreviewRound() {
    switch (_mode) {
      case _VisualSearchMode.search:
        _buildSearchRound();
      case _VisualSearchMode.difference:
        _buildDifferenceRound();
      case _VisualSearchMode.linkMatch:
        _buildLinkBoard();
    }
  }

  void _start() {
    _transitionTimer?.cancel();
    _ticker?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _records.clear();
      _roundIndex = 0;
      _correct = 0;
      _wrong = 0;
      _moves = 0;
      _matches = 0;
      _streak = 0;
      _bestStreak = 0;
      _running = true;
      _done = false;
      _lastTappedIndex = null;
      _selectedLinkIndex = null;
      _lastLinkIndex = null;
      _lastCorrect = null;
      _linkFeedback = null;
      _elapsed = Duration.zero;
    });
    if (_linkMode) {
      setState(() {
        _buildLinkBoard();
        _stopwatch.start();
      });
      _startTicker();
    } else {
      _beginRound();
    }
  }

  void _reset() {
    _transitionTimer?.cancel();
    _ticker?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _records.clear();
      _roundIndex = 0;
      _correct = 0;
      _wrong = 0;
      _moves = 0;
      _matches = 0;
      _streak = 0;
      _bestStreak = 0;
      _running = false;
      _done = false;
      _lastTappedIndex = null;
      _selectedLinkIndex = null;
      _lastLinkIndex = null;
      _lastCorrect = null;
      _linkFeedback = null;
      _elapsed = Duration.zero;
      _buildPreviewRound();
    });
  }

  void _setMode(_VisualSearchMode mode) {
    if (_mode == mode) {
      return;
    }
    setState(() {
      _mode = mode;
    });
    _reset();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted || !_running || !_linkMode) {
        return;
      }
      setState(() {
        _elapsed = _stopwatch.elapsed;
      });
    });
  }

  void _beginRound() {
    if (!mounted || !_running) {
      return;
    }
    if (_linkMode) {
      return;
    }
    if (_roundIndex >= _roundCount) {
      _finish();
      return;
    }
    setState(() {
      _lastTappedIndex = null;
      _lastCorrect = null;
      switch (_mode) {
        case _VisualSearchMode.search:
          _buildSearchRound();
        case _VisualSearchMode.difference:
          _buildDifferenceRound();
        case _VisualSearchMode.linkMatch:
          _buildLinkBoard();
      }
      _stopwatch
        ..reset()
        ..start();
    });
  }

  void _finish() {
    _stopwatch.stop();
    _ticker?.cancel();
    _elapsed = _stopwatch.elapsed;
    setState(() {
      _running = false;
      _done = true;
    });
    unawaited(_showReport());
  }

  void _buildSearchRound() {
    final grid = _activeGridSize;
    final count = grid * grid;
    final targetIcon = _sample(_random, _icons);
    final targetColor = _sample(_random, _colors);
    final correctIndex = _random.nextInt(count);
    final decoyIcons = _icons.where((icon) => icon != targetIcon).toList();
    final nextCells = List<_VisualSearchCell>.generate(count, (index) {
      if (index == correctIndex) {
        return _VisualSearchCell(icon: targetIcon, color: targetColor);
      }
      final icon = _random.nextDouble() < 0.68
          ? _sample(_random, decoyIcons)
          : targetIcon;
      final color = icon == targetIcon
          ? _sample(
              _random,
              _colors.where((item) => item != targetColor).toList(),
            )
          : _sample(_random, _colors);
      return _VisualSearchCell(icon: icon, color: color);
    }, growable: false);
    _correctIndex = correctIndex;
    _cells = nextCells;
    _leftCells = const <_VisualSearchCell>[];
    _rightCells = const <_VisualSearchCell>[];
  }

  void _buildDifferenceRound() {
    final grid = _activeGridSize;
    final count = grid * grid;
    final baseCells = List<_VisualSearchCell>.generate(count, (index) {
      return _VisualSearchCell(
        icon: _sample(_random, _icons),
        color: _sample(_random, _colors),
      );
    }, growable: false);
    final correctIndex = _random.nextInt(count);
    final original = baseCells[correctIndex];
    final changeIcon = _random.nextBool();
    final nextRight = List<_VisualSearchCell>.from(baseCells);
    nextRight[correctIndex] = _VisualSearchCell(
      icon: changeIcon
          ? _sample(
              _random,
              _icons.where((icon) => icon != original.icon).toList(),
            )
          : original.icon,
      color: changeIcon
          ? original.color
          : _sample(
              _random,
              _colors.where((color) => color != original.color).toList(),
            ),
    );
    _correctIndex = correctIndex;
    _cells = const <_VisualSearchCell>[];
    _leftCells = baseCells;
    _rightCells = nextRight;
  }

  void _buildLinkBoard() {
    final total = _linkRows * _linkCols;
    final pairCount = total ~/ 2;
    final variants = <_VisualSearchCell>[];
    for (final icon in _icons) {
      for (final color in _colors) {
        variants.add(_VisualSearchCell(icon: icon, color: color));
      }
    }
    variants.shuffle(_random);
    final pairs = <_VisualSearchLinkTile>[];
    for (var pair = 0; pair < pairCount; pair += 1) {
      final cell = variants[pair % variants.length];
      pairs.add(_VisualSearchLinkTile(pairId: pair, cell: cell));
    }
    _linkTiles = _buildRandomLinkBoard(pairs, total);
    _clearedLinkIndexes = <int>{};
    _selectedLinkIndex = null;
    _lastLinkIndex = null;
    _lastCorrect = null;
    _linkFeedback = null;
    _correctIndex = null;
    _cells = const <_VisualSearchCell>[];
    _leftCells = const <_VisualSearchCell>[];
    _rightCells = const <_VisualSearchCell>[];
  }

  List<_VisualSearchLinkTile?> _buildRandomLinkBoard(
    List<_VisualSearchLinkTile> pairTiles,
    int total,
  ) {
    final pairCount = pairTiles.length;
    List<_VisualSearchLinkTile?>? bestBoard;
    var bestScatterScore = -1;
    for (var attempt = 0; attempt < 160; attempt += 1) {
      final board = List<_VisualSearchLinkTile?>.filled(total, null);
      final order = List<int>.generate(pairCount, (index) => index)
        ..shuffle(_random);
      var failed = false;
      for (final pairIndex in order) {
        final tile = pairTiles[pairIndex];
        final placements = _randomEmptyLinkPlacements(board);
        if (placements.isEmpty) {
          failed = true;
          break;
        }
        final scatteredPlacements = placements
            .where((item) => !_areAdjacentLinkIndexes(item.$1, item.$2))
            .toList(growable: false);
        final choices = scatteredPlacements.isEmpty
            ? placements
            : scatteredPlacements;
        final placement = _sample(_random, choices);
        board[placement.$1] = tile;
        board[placement.$2] = tile;
      }
      if (!failed && board.every((item) => item != null)) {
        final scatterScore = _linkScatterScore(board);
        if (scatterScore > bestScatterScore) {
          bestScatterScore = scatterScore;
          bestBoard = List<_VisualSearchLinkTile?>.from(board);
        }
        if (scatterScore >= (pairCount * 0.82).floor()) {
          return board;
        }
      }
    }
    return bestBoard ?? _buildLayeredLinkBoard(pairTiles);
  }

  List<_VisualSearchLinkTile?> _buildLayeredLinkBoard(
    List<_VisualSearchLinkTile> pairTiles,
  ) {
    final total = pairTiles.length * 2;
    final board = List<_VisualSearchLinkTile?>.filled(total, null);
    final positionPairs = <(int, int)>[];
    final layers = math.min(_linkRows, _linkCols) ~/ 2;
    for (var layer = 0; layer < layers; layer += 1) {
      final top = layer;
      final bottom = _linkRows - layer - 1;
      final left = layer;
      final right = _linkCols - layer - 1;
      _addLayerSidePairs(
        positionPairs,
        List<int>.generate(
          right - left + 1,
          (offset) => top * _linkCols + left + offset,
          growable: false,
        ),
      );
      if (bottom != top) {
        _addLayerSidePairs(
          positionPairs,
          List<int>.generate(
            right - left + 1,
            (offset) => bottom * _linkCols + left + offset,
            growable: false,
          ),
        );
      }
      if (bottom - top > 1) {
        _addLayerSidePairs(
          positionPairs,
          List<int>.generate(
            bottom - top - 1,
            (offset) => (top + offset + 1) * _linkCols + left,
            growable: false,
          ),
        );
        if (right != left) {
          _addLayerSidePairs(
            positionPairs,
            List<int>.generate(
              bottom - top - 1,
              (offset) => (top + offset + 1) * _linkCols + right,
              growable: false,
            ),
          );
        }
      }
    }
    positionPairs.shuffle(_random);
    final shuffledPairs = List<_VisualSearchLinkTile>.from(pairTiles)
      ..shuffle(_random);
    for (var index = 0; index < shuffledPairs.length; index += 1) {
      final positionPair = positionPairs[index];
      final tile = shuffledPairs[index];
      board[positionPair.$1] = tile;
      board[positionPair.$2] = tile;
    }
    return board;
  }

  void _addLayerSidePairs(List<(int, int)> pairs, List<int> indexes) {
    final available = List<int>.from(indexes)..shuffle(_random);
    while (available.length >= 2) {
      final first = available.removeLast();
      var bestIndex = 0;
      var bestDistance = -1;
      for (var index = 0; index < available.length; index += 1) {
        final distance = _linkIndexDistance(first, available[index]);
        if (distance > bestDistance) {
          bestDistance = distance;
          bestIndex = index;
        }
      }
      pairs.add((first, available.removeAt(bestIndex)));
    }
  }

  List<(int, int)> _randomEmptyLinkPlacements(
    List<_VisualSearchLinkTile?> board,
  ) {
    final placements = <(int, int)>[];
    for (var first = 0; first < board.length; first += 1) {
      if (board[first] != null) {
        continue;
      }
      for (var second = first + 1; second < board.length; second += 1) {
        if (board[second] != null) {
          continue;
        }
        if (_canConnectOnBoard(board, first, second)) {
          placements.add((first, second));
        }
      }
    }
    return placements;
  }

  bool _areAdjacentLinkIndexes(int first, int second) {
    return _linkIndexDistance(first, second) == 1;
  }

  int _linkIndexDistance(int first, int second) {
    final a = _pointForLinkIndex(first);
    final b = _pointForLinkIndex(second);
    return (a.row - b.row).abs() + (a.col - b.col).abs();
  }

  int _linkScatterScore(List<_VisualSearchLinkTile?> board) {
    final firstIndexes = <int, int>{};
    var score = 0;
    for (var index = 0; index < board.length; index += 1) {
      final tile = board[index];
      if (tile == null) {
        continue;
      }
      final firstIndex = firstIndexes[tile.pairId];
      if (firstIndex == null) {
        firstIndexes[tile.pairId] = index;
      } else if (!_areAdjacentLinkIndexes(firstIndex, index)) {
        score += 1;
      }
    }
    return score;
  }

  void _answer(int index) {
    if (!_running || _lastCorrect != null || _correctIndex == null) {
      return;
    }
    _stopwatch.stop();
    final correct = index == _correctIndex;
    final elapsed = math.max(1, _stopwatch.elapsedMilliseconds);
    setState(() {
      _lastTappedIndex = index;
      _lastCorrect = correct;
      _roundIndex += 1;
      _records.add(
        _VisualSearchRoundRecord(
          mode: _mode,
          correct: correct,
          milliseconds: elapsed,
          gridSize: _activeGridSize,
        ),
      );
      if (correct) {
        _correct += 1;
        _streak += 1;
        _bestStreak = math.max(_bestStreak, _streak);
      } else {
        _wrong += 1;
        _streak = 0;
      }
    });
    _transitionTimer?.cancel();
    _transitionTimer = Timer(const Duration(milliseconds: 620), _beginRound);
  }

  void _tapLinkTile(int index) {
    if (!_running ||
        !_linkMode ||
        index < 0 ||
        index >= _linkTiles.length ||
        _clearedLinkIndexes.contains(index)) {
      return;
    }
    final tile = _linkTiles[index];
    if (tile == null) {
      return;
    }
    if (_selectedLinkIndex == null) {
      setState(() {
        _selectedLinkIndex = index;
        _lastLinkIndex = null;
        _lastCorrect = null;
        _linkFeedback = null;
      });
      return;
    }
    final firstIndex = _selectedLinkIndex!;
    if (firstIndex == index) {
      setState(() {
        _selectedLinkIndex = null;
        _lastLinkIndex = index;
        _lastCorrect = null;
        _linkFeedback = null;
      });
      return;
    }
    final firstTile = _linkTiles[firstIndex];
    if (firstTile == null) {
      setState(() {
        _selectedLinkIndex = index;
        _lastLinkIndex = null;
        _lastCorrect = null;
        _linkFeedback = null;
      });
      return;
    }
    final sameTile = firstTile.pairId == tile.pairId;
    final route = sameTile
        ? _findLinkRoute(_liveLinkBoard, firstIndex, index)
        : null;
    final matched = sameTile && (_linkIgnorePath || (route?.connected ?? false));
    final feedback = _linkFeedbackForAttempt(
      firstIndex: firstIndex,
      secondIndex: index,
      sameTile: sameTile,
      route: route,
      matched: matched,
    );
    setState(() {
      _moves += 1;
      _lastTappedIndex = firstIndex;
      _lastLinkIndex = index;
      _lastCorrect = matched;
      _linkFeedback = feedback;
      if (matched) {
        _correct += 1;
        _matches += 1;
        _streak += 1;
        _bestStreak = math.max(_bestStreak, _streak);
        _clearedLinkIndexes = <int>{
          ..._clearedLinkIndexes,
          firstIndex,
          index,
        };
        _selectedLinkIndex = null;
      } else {
        _wrong += 1;
        _streak = 0;
        _selectedLinkIndex = null;
      }
    });
    if (matched && _matches >= _linkPairCount) {
      _finish();
    }
  }

  _VisualSearchLinkFeedback _linkFeedbackForAttempt({
    required int firstIndex,
    required int secondIndex,
    required bool sameTile,
    required _VisualSearchLinkRouteResult? route,
    required bool matched,
  }) {
    if (!sameTile) {
      return _VisualSearchLinkFeedback(
        type: _VisualSearchLinkFeedbackType.mismatch,
        path: const <_VisualSearchGridPoint>[],
        markerIndexes: <int>{firstIndex, secondIndex},
      );
    }
    if (matched) {
      return _VisualSearchLinkFeedback(
        type: _VisualSearchLinkFeedbackType.success,
        path: route != null && route.connected
            ? route.path
            : _directLinkPath(firstIndex, secondIndex),
        markerIndexes: const <int>{},
      );
    }
    return _VisualSearchLinkFeedback(
      type: _VisualSearchLinkFeedbackType.blocked,
      path: route?.path ?? _directLinkPath(firstIndex, secondIndex),
      markerIndexes: route?.blockedIndexes ?? const <int>{},
    );
  }

  List<_VisualSearchGridPoint> _directLinkPath(int first, int second) {
    return <_VisualSearchGridPoint>[
      _pointForLinkIndex(first),
      _pointForLinkIndex(second),
    ];
  }

  List<_VisualSearchLinkTile?> get _liveLinkBoard {
    if (_clearedLinkIndexes.isEmpty) {
      return _linkTiles;
    }
    return List<_VisualSearchLinkTile?>.generate(
      _linkTiles.length,
      (index) => _clearedLinkIndexes.contains(index) ? null : _linkTiles[index],
      growable: false,
    );
  }

  bool _canConnectOnBoard(
    List<_VisualSearchLinkTile?> board,
    int first,
    int second,
  ) {
    return _findLinkRoute(board, first, second).connected;
  }

  _VisualSearchLinkRouteResult _findLinkRoute(
    List<_VisualSearchLinkTile?> board,
    int first,
    int second,
  ) {
    if (first == second ||
        first < 0 ||
        second < 0 ||
        first >= board.length ||
        second >= board.length) {
      return const _VisualSearchLinkRouteResult(
        connected: false,
        path: <_VisualSearchGridPoint>[],
        blockedIndexes: <int>{},
      );
    }
    List<_VisualSearchGridPoint>? bestBlockedPath;
    Set<int>? bestBlockedIndexes;
    var bestBlockedScore = 1 << 30;
    for (final path in _linkRouteCandidates(first, second)) {
      final blockedIndexes = _blockedLinkIndexesOnPath(
        board,
        path,
        first,
        second,
      );
      if (blockedIndexes == null) {
        continue;
      }
      if (blockedIndexes.isEmpty) {
        return _VisualSearchLinkRouteResult(
          connected: true,
          path: path,
          blockedIndexes: const <int>{},
        );
      }
      final score = blockedIndexes.length * 10000 + _linkPathDistance(path);
      if (score < bestBlockedScore) {
        bestBlockedScore = score;
        bestBlockedPath = path;
        bestBlockedIndexes = blockedIndexes;
      }
    }
    final start = _pointForLinkIndex(first);
    final end = _pointForLinkIndex(second);
    return _VisualSearchLinkRouteResult(
      connected: false,
      path: bestBlockedPath ?? <_VisualSearchGridPoint>[start, end],
      blockedIndexes: bestBlockedIndexes ?? const <int>{},
    );
  }

  List<List<_VisualSearchGridPoint>> _linkRouteCandidates(
    int first,
    int second,
  ) {
    final start = _pointForLinkIndex(first);
    final end = _pointForLinkIndex(second);
    final candidates = <List<_VisualSearchGridPoint>>[];
    void addCandidate(List<_VisualSearchGridPoint> points) {
      final path = _normalizeLinkPath(points);
      if (path.length < 2 || !_isStraightLinkPath(path)) {
        return;
      }
      if (path.length - 2 > _linkMaxTurns) {
        return;
      }
      candidates.add(path);
    }

    addCandidate(<_VisualSearchGridPoint>[start, end]);
    addCandidate(<_VisualSearchGridPoint>[
      start,
      _VisualSearchGridPoint(start.row, end.col),
      end,
    ]);
    addCandidate(<_VisualSearchGridPoint>[
      start,
      _VisualSearchGridPoint(end.row, start.col),
      end,
    ]);
    for (var row = -1; row <= _linkRows; row += 1) {
      addCandidate(<_VisualSearchGridPoint>[
        start,
        _VisualSearchGridPoint(row, start.col),
        _VisualSearchGridPoint(row, end.col),
        end,
      ]);
    }
    for (var col = -1; col <= _linkCols; col += 1) {
      addCandidate(<_VisualSearchGridPoint>[
        start,
        _VisualSearchGridPoint(start.row, col),
        _VisualSearchGridPoint(end.row, col),
        end,
      ]);
    }
    return candidates;
  }

  List<_VisualSearchGridPoint> _normalizeLinkPath(
    List<_VisualSearchGridPoint> points,
  ) {
    final normalized = <_VisualSearchGridPoint>[];
    for (final point in points) {
      if (normalized.isNotEmpty && _sameLinkPoint(normalized.last, point)) {
        continue;
      }
      normalized.add(point);
    }
    var changed = true;
    while (changed) {
      changed = false;
      for (var index = 1; index < normalized.length - 1; index += 1) {
        final previous = normalized[index - 1];
        final current = normalized[index];
        final next = normalized[index + 1];
        if ((previous.row == current.row && current.row == next.row) ||
            (previous.col == current.col && current.col == next.col)) {
          normalized.removeAt(index);
          changed = true;
          break;
        }
      }
    }
    return normalized;
  }

  bool _isStraightLinkPath(List<_VisualSearchGridPoint> path) {
    for (var index = 1; index < path.length; index += 1) {
      final previous = path[index - 1];
      final current = path[index];
      if (!_isLinkPointInSearchBounds(previous) ||
          !_isLinkPointInSearchBounds(current)) {
        return false;
      }
      if (previous.row != current.row && previous.col != current.col) {
        return false;
      }
    }
    return true;
  }

  Set<int>? _blockedLinkIndexesOnPath(
    List<_VisualSearchLinkTile?> board,
    List<_VisualSearchGridPoint> path,
    int first,
    int second,
  ) {
    final blockedIndexes = <int>{};
    for (var index = 1; index < path.length; index += 1) {
      final from = path[index - 1];
      final to = path[index];
      if (from.row != to.row && from.col != to.col) {
        return null;
      }
      final rowStep = to.row.compareTo(from.row);
      final colStep = to.col.compareTo(from.col);
      var row = from.row;
      var col = from.col;
      while (row != to.row || col != to.col) {
        row += rowStep;
        col += colStep;
        final pointIndex = _linkIndexForPoint(
          _VisualSearchGridPoint(row, col),
        );
        if (pointIndex == null ||
            pointIndex == first ||
            pointIndex == second) {
          continue;
        }
        if (board[pointIndex] != null) {
          blockedIndexes.add(pointIndex);
        }
      }
    }
    return blockedIndexes;
  }

  _VisualSearchGridPoint _pointForLinkIndex(int index) {
    return _VisualSearchGridPoint(index ~/ _linkCols, index % _linkCols);
  }

  int? _linkIndexForPoint(_VisualSearchGridPoint point) {
    if (point.row < 0 ||
        point.row >= _linkRows ||
        point.col < 0 ||
        point.col >= _linkCols) {
      return null;
    }
    return point.row * _linkCols + point.col;
  }

  bool _isLinkPointInSearchBounds(_VisualSearchGridPoint point) {
    return point.row >= -1 &&
        point.row <= _linkRows &&
        point.col >= -1 &&
        point.col <= _linkCols;
  }

  bool _sameLinkPoint(
    _VisualSearchGridPoint first,
    _VisualSearchGridPoint second,
  ) {
    return first.row == second.row && first.col == second.col;
  }

  int _linkPathDistance(List<_VisualSearchGridPoint> path) {
    var distance = 0;
    for (var index = 1; index < path.length; index += 1) {
      distance += (path[index].row - path[index - 1].row).abs() +
          (path[index].col - path[index - 1].col).abs();
    }
    return distance;
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: _metricItems(i18n),
        ),
        const SizedBox(height: 12),
        _HumanPanel(child: _buildStage(context, i18n)),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: pickUiText(i18n, zh: '视觉搜索设置', en: 'Visual search settings'),
          subtitle: pickUiText(
            i18n,
            zh: '切换搜索、找不同或连连看，并调整网格密度与轮数。',
            en: 'Switch search, difference, or matching mode and adjust board density.',
          ),
          child: _buildSettings(context, i18n),
        ),
      ],
    );
  }

  List<(String, String)> _metricItems(AppI18n i18n) {
    if (_linkMode) {
      return <(String, String)>[
        (
          pickUiText(i18n, zh: '配对', en: 'Pairs'),
          '$_matches/$_linkPairCount',
        ),
        (pickUiText(i18n, zh: '剩余', en: 'Left'), '$_linkRemainingPairs'),
        (pickUiText(i18n, zh: '步数', en: 'Moves'), '$_moves'),
        (
          pickUiText(i18n, zh: '用时', en: 'Time'),
          _elapsed == Duration.zero ? '-' : _formatLinkDuration(_elapsed),
        ),
      ];
    }
    return <(String, String)>[
      (
        pickUiText(i18n, zh: '进度', en: 'Progress'),
        '$_roundIndex/$_roundCount',
      ),
      (
        pickUiText(i18n, zh: '准确率', en: 'Accuracy'),
        '${(_accuracy * 100).round()}%',
      ),
      (
        pickUiText(i18n, zh: '平均用时', en: 'Avg time'),
        _records.isEmpty ? '-' : _formatMilliseconds(_averageMs),
      ),
      (pickUiText(i18n, zh: '最佳连击', en: 'Best streak'), '$_bestStreak'),
    ];
  }

  Widget _buildStage(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            ..._VisualSearchMode.values.map(
              (mode) => ChoiceChip(
                avatar: Icon(_modeIcon(mode), size: 18),
                label: Text(_modeLabel(i18n, mode)),
                selected: _mode == mode,
                onSelected: _running ? null : (_) => _setMode(mode),
              ),
            ),
            _HumanActionButton(
              label: _running
                  ? pickUiText(i18n, zh: '重新开始', en: 'Restart')
                  : pickUiText(i18n, zh: '开始', en: 'Start'),
              icon: _running ? Icons.replay_rounded : Icons.play_arrow_rounded,
              onPressed: _start,
            ),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _stagePrompt(i18n),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: switch (_mode) {
            _VisualSearchMode.search => _buildSearchGrid(context, i18n),
            _VisualSearchMode.difference => _buildDifferenceGrid(
              context,
              i18n,
            ),
            _VisualSearchMode.linkMatch => _buildLinkMatchGrid(context, i18n),
          },
        ),
      ],
    );
  }

  IconData _modeIcon(_VisualSearchMode mode) {
    return switch (mode) {
      _VisualSearchMode.search => Icons.manage_search_rounded,
      _VisualSearchMode.difference => Icons.compare_rounded,
      _VisualSearchMode.linkMatch => Icons.hub_rounded,
    };
  }

  String _modeLabel(AppI18n i18n, _VisualSearchMode mode) {
    return switch (mode) {
      _VisualSearchMode.search => pickUiText(i18n, zh: '找目标', en: 'Search'),
      _VisualSearchMode.difference => pickUiText(
        i18n,
        zh: '找不同',
        en: 'Difference',
      ),
      _VisualSearchMode.linkMatch => pickUiText(
        i18n,
        zh: '连连看',
        en: 'Link match',
      ),
    };
  }

  String _stagePrompt(AppI18n i18n) {
    if (!_running && !_done) {
      return _linkMode
          ? _linkIgnorePath
                ? pickUiText(
                    i18n,
                    zh: '只匹配图案已开启：开始后选择相同图案即可消除。',
                    en: 'Icon-only match is on: identical tiles clear without route checks.',
                  )
                : pickUiText(
                    i18n,
                    zh: '开始后选择相同图案，路径可直连、借边界或最多转两次弯即可消除。',
                    en: 'After starting, match identical tiles when the route is open, can use the edge, and turns at most twice.',
                  )
          : pickUiText(
              i18n,
              zh: '开始后每轮只有一次作答机会。',
              en: 'Each round gives you one answer after the session starts.',
            );
    }
    if (_done) {
      return pickUiText(
        i18n,
        zh: '本组已完成，可重新开始。',
        en: 'Session complete. Restart when ready.',
      );
    }
    return switch (_mode) {
      _VisualSearchMode.search => pickUiText(
        i18n,
        zh: '找出唯一的目标格。',
        en: 'Find the unique target tile.',
      ),
      _VisualSearchMode.difference => pickUiText(
        i18n,
        zh: '比较左右面板，点出差异所在位置。',
        en: 'Compare both panels and tap the changed position.',
      ),
      _VisualSearchMode.linkMatch => pickUiText(
        i18n,
        zh: _linkIgnorePath
            ? '点击两个相同图案即可配对；路线仅作为连接反馈显示。'
            : '点击两个相同图案；路径中无阻挡，可借边界并最多转两次弯即可配对消除。',
        en: _linkIgnorePath
            ? 'Tap two identical tiles to clear them; the line is feedback only.'
            : 'Tap two identical tiles; clear them when the route is open, can use the edge, and turns at most twice.',
      ),
    };
  }

  Widget _buildSearchGrid(BuildContext context, AppI18n i18n) {
    final grid = _activeGridSize;
    return GridView.builder(
      key: const ValueKey<String>('visual-search-grid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _cells.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: grid,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        return _buildVisualTile(
          context,
          cell: _cells[index],
          index: index,
          onTap: () => _answer(index),
        );
      },
    );
  }

  Widget _buildDifferenceGrid(BuildContext context, AppI18n i18n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 460;
        final boards = <Widget>[
          _buildDifferenceBoard(
            context,
            label: pickUiText(i18n, zh: '左图', en: 'Left'),
            cells: _leftCells,
          ),
          _buildDifferenceBoard(
            context,
            label: pickUiText(i18n, zh: '右图', en: 'Right'),
            cells: _rightCells,
          ),
        ];
        if (compact) {
          return Column(
            children: <Widget>[
              boards.first,
              const SizedBox(height: 12),
              boards.last,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: boards.first),
            const SizedBox(width: 12),
            Expanded(child: boards.last),
          ],
        );
      },
    );
  }

  Widget _buildDifferenceBoard(
    BuildContext context, {
    required String label,
    required List<_VisualSearchCell> cells,
  }) {
    final grid = _activeGridSize;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          key: ValueKey<String>('visual-difference-grid-$label'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: grid,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemBuilder: (context, index) {
            return _buildVisualTile(
              context,
              cell: cells[index],
              index: index,
              onTap: () => _answer(index),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLinkMatchGrid(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    final feedback = _linkFeedback;
    return Column(
      key: const ValueKey<String>('visual-link-match-stage'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _HumanPill(
              text: pickUiText(
                i18n,
                zh: '剩余 $_linkRemainingPairs 对',
                en: '$_linkRemainingPairs pairs left',
              ),
              accent: VisualSearchTestPage._accent,
            ),
            _HumanPill(
              text: pickUiText(i18n, zh: '步数 $_moves', en: '$_moves moves'),
              accent: theme.colorScheme.tertiary,
            ),
            _HumanPill(
              text: _formatLinkDuration(_elapsed),
              accent: theme.colorScheme.secondary,
            ),
          ],
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: _linkCols / _linkRows,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              GridView.builder(
                key: const ValueKey<String>('visual-link-match-grid'),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _linkTiles.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _linkCols,
                  crossAxisSpacing: _linkTileSpacing,
                  mainAxisSpacing: _linkTileSpacing,
                ),
                itemBuilder: (context, index) {
                  return _buildLinkTile(context, index: index);
                },
              ),
              if (feedback != null && feedback.path.length > 1)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      key: const ValueKey<String>('visual-link-route-overlay'),
                      painter: _VisualSearchLinkRoutePainter(
                        path: feedback.path,
                        rows: _linkRows,
                        cols: _linkCols,
                        spacing: _linkTileSpacing,
                        color:
                            feedback.type == _VisualSearchLinkFeedbackType.blocked
                            ? theme.colorScheme.error
                            : Colors.green,
                      ),
                    ),
                  ),
                ),
              if (feedback != null && feedback.markerIndexes.isNotEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: feedback.markerIndexes
                              .map(
                                (index) => _buildLinkMarkerPosition(
                                  context,
                                  index: index,
                                  width: constraints.maxWidth,
                                  height: constraints.maxHeight,
                                ),
                              )
                              .toList(growable: false),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisualTile(
    BuildContext context, {
    required _VisualSearchCell cell,
    required int index,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final correct = _correctIndex == index;
    final selected = _lastTappedIndex == index;
    final reveal = _lastCorrect != null && correct;
    final wrong = _lastCorrect == false && selected;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _running ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: reveal
                  ? Colors.green
                  : wrong
                  ? colorScheme.error
                  : colorScheme.outlineVariant,
              width: reveal || wrong ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(cell.icon, color: cell.color, size: 28),
        ),
      ),
    );
  }

  Widget _buildLinkTile(BuildContext context, {required int index}) {
    final tile = _linkTiles[index];
    final colorScheme = Theme.of(context).colorScheme;
    final cleared = _clearedLinkIndexes.contains(index) || tile == null;
    final selected = _selectedLinkIndex == index;
    final recent = _lastTappedIndex == index || _lastLinkIndex == index;
    final success = recent && _lastCorrect == true;
    final wrong = recent && _lastCorrect == false;
    final borderColor = success
        ? Colors.green
        : wrong
        ? colorScheme.error
        : selected
        ? VisualSearchTestPage._accent
        : colorScheme.outlineVariant;
    return Semantics(
      button: true,
      label: cleared ? 'Cleared' : _linkTileSemanticLabel(tile),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _running && !cleared ? () => _tapLinkTile(index) : null,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: cleared
                  ? colorScheme.surfaceContainerLow.withValues(alpha: 0.32)
                  : selected
                  ? VisualSearchTestPage._accent.withValues(alpha: 0.13)
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: selected || success || wrong ? 2 : 1,
              ),
              boxShadow: selected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: VisualSearchTestPage._accent.withValues(
                          alpha: 0.18,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 140),
                  opacity: cleared ? 0 : 1,
                  child: tile == null
                      ? const SizedBox.shrink()
                      : Icon(tile.cell.icon, color: tile.cell.color, size: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Positioned _buildLinkMarkerPosition(
    BuildContext context, {
    required int index,
    required double width,
    required double height,
  }) {
    final row = index ~/ _linkCols;
    final col = index % _linkCols;
    final tileWidth =
        math.max(1.0, (width - _linkTileSpacing * (_linkCols - 1)) / _linkCols);
    final tileHeight = math.max(
      1.0,
      (height - _linkTileSpacing * (_linkRows - 1)) / _linkRows,
    );
    final strideX = tileWidth + _linkTileSpacing;
    final strideY = tileHeight + _linkTileSpacing;
    return Positioned(
      left: col * strideX,
      top: row * strideY,
      width: tileWidth,
      height: tileHeight,
      child: Center(
        child: _buildLinkErrorMark(context),
      ),
    );
  }

  Widget _buildLinkErrorMark(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: error.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: error.withValues(alpha: 0.72), width: 2),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.close_rounded, color: error, size: 30),
    );
  }

  String _linkTileSemanticLabel(_VisualSearchLinkTile? tile) {
    if (tile == null) {
      return 'Cleared';
    }
    return '${tile.cell.icon.codePoint}-${tile.cell.color.toARGB32()}';
  }

  Widget _buildSettings(BuildContext context, AppI18n i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (!_linkMode) ...<Widget>[
          Text(pickUiText(i18n, zh: '轮数', en: 'Rounds')),
          Wrap(
            spacing: 8,
            children: <int>[8, 10, 12, 16]
                .map(
                  (value) => ChoiceChip(
                    label: Text('$value'),
                    selected: _roundCount == value,
                    onSelected: _running
                        ? null
                        : (_) => setState(() => _roundCount = value),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          _linkMode
              ? pickUiText(i18n, zh: '连连看尺寸', en: 'Link board size')
              : pickUiText(i18n, zh: '网格密度', en: 'Grid density'),
        ),
        Slider(
          value: _linkMode ? _linkRows.toDouble() : _gridSize.toDouble(),
          min: _linkMode ? 4 : 3,
          max: _linkMode ? 8 : 7,
          divisions: _linkMode ? 2 : 4,
          label: _linkMode
              ? '${_linkRows}x$_linkCols'
              : '${_activeGridSize}x$_activeGridSize',
          onChanged: _running
              ? null
              : (value) {
                  setState(() {
                    if (_linkMode) {
                      _linkRows = value.round();
                      _linkCols = _linkRows;
                    } else {
                      _gridSize = value.round();
                    }
                    _buildPreviewRound();
                  });
                },
        ),
        if (_linkMode) ...<Widget>[
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            key: const ValueKey<String>('visual-link-ignore-path-switch'),
            contentPadding: EdgeInsets.zero,
            title: Text(
              pickUiText(i18n, zh: '只匹配图案', en: 'Icon-only match'),
            ),
            subtitle: Text(
              pickUiText(
                i18n,
                zh: '开启后，相同图案无需路径连通也能消除。',
                en: 'Ignore route blocking for identical tiles.',
              ),
            ),
            value: _linkIgnorePath,
            onChanged: _running
                ? null
                : (value) {
                    setState(() {
                      _linkIgnorePath = value;
                      _linkFeedback = null;
                    });
                  },
          ),
          const SizedBox(height: 8),
          Text(
            pickUiText(
              i18n,
              zh: '本模式只在视觉搜索页内部生效；关闭只匹配图案时，相同图案需要直线、边界或最多两次转弯路径才能消除。',
              en: 'This mode stays inside visual search; when icon-only match is off, identical tiles need a straight, edge, or two-turn route.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Future<void> _showReport() async {
    if (!mounted) {
      return;
    }
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final linkMode = _linkMode;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            pickUiText(i18n, zh: '视觉搜索报告', en: 'Visual search report'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _HumanMetricWrap(
                  metrics: linkMode
                      ? <(String, String)>[
                          (
                            pickUiText(i18n, zh: '完成配对', en: 'Pairs cleared'),
                            '$_matches/$_linkPairCount',
                          ),
                          (pickUiText(i18n, zh: '步数', en: 'Moves'), '$_moves'),
                          (
                            pickUiText(i18n, zh: '用时', en: 'Time'),
                            _formatLinkDuration(_elapsed),
                          ),
                          (
                            pickUiText(i18n, zh: '最佳连击', en: 'Best streak'),
                            '$_bestStreak',
                          ),
                        ]
                      : <(String, String)>[
                          (
                            pickUiText(i18n, zh: '准确率', en: 'Accuracy'),
                            '${(_accuracy * 100).round()}%',
                          ),
                          (
                            pickUiText(i18n, zh: '平均用时', en: 'Avg time'),
                            _records.isEmpty
                                ? '-'
                                : _formatMilliseconds(_averageMs),
                          ),
                          (
                            pickUiText(i18n, zh: '最佳连击', en: 'Best streak'),
                            '$_bestStreak',
                          ),
                          (
                            pickUiText(i18n, zh: '网格', en: 'Grid'),
                            '${_activeGridSize}x$_activeGridSize',
                          ),
                        ],
                ),
                const SizedBox(height: 14),
                _HumanPanel(
                  child: Text(
                    linkMode
                        ? _linkIgnorePath
                            ? pickUiText(
                                i18n,
                                zh: '当前已开启只匹配图案；下一轮可以关闭开关，继续练习路径预判和短程扫描。',
                                en: 'Icon-only match is on. Turn it off next to keep training route planning and short-range scanning.',
                              )
                            : pickUiText(
                                i18n,
                                zh: '连连看更考验图案分组、路径预判和短程扫描。下一轮可以提高棋盘尺寸，或先从边角可连的对子开始。',
                                en: 'Link match trains grouping, route planning, and short-range scanning. Raise the board size next, or start from edge pairs first.',
                              )
                        : _accuracy >= 0.85
                        ? pickUiText(
                            i18n,
                            zh: '扫描稳定，下一轮可以提高网格密度或切换到找不同模式。',
                            en: 'Scanning is stable. Increase grid density or switch into difference mode next.',
                          )
                        : pickUiText(
                            i18n,
                            zh: '建议先降低网格密度，保持从左到右、从上到下的固定搜索节奏。',
                            en: 'Lower the density and keep a fixed left-to-right, top-to-bottom scan rhythm.',
                          ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(pickUiText(i18n, zh: '关闭', en: 'Close')),
            ),
          ],
        );
      },
    );
  }

  String _formatLinkDuration(Duration value) {
    final totalSeconds = value.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _VisualSearchLinkRoutePainter extends CustomPainter {
  const _VisualSearchLinkRoutePainter({
    required this.path,
    required this.rows,
    required this.cols,
    required this.spacing,
    required this.color,
  });

  final List<_VisualSearchGridPoint> path;
  final int rows;
  final int cols;
  final double spacing;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2 || rows <= 0 || cols <= 0) {
      return;
    }
    final route = Path();
    final first = _offsetForPoint(path.first, size);
    route.moveTo(first.dx, first.dy);
    for (var index = 1; index < path.length; index += 1) {
      final next = _offsetForPoint(path[index], size);
      route.lineTo(next.dx, next.dy);
    }
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.88)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas
      ..drawPath(route, glowPaint)
      ..drawPath(route, linePaint);

    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    canvas
      ..drawCircle(first, 4.5, dotPaint)
      ..drawCircle(_offsetForPoint(path.last, size), 4.5, dotPaint);
  }

  Offset _offsetForPoint(_VisualSearchGridPoint point, Size size) {
    final tileWidth = math.max(1.0, (size.width - spacing * (cols - 1)) / cols);
    final tileHeight = math.max(
      1.0,
      (size.height - spacing * (rows - 1)) / rows,
    );
    final strideX = tileWidth + spacing;
    final strideY = tileHeight + spacing;
    final x = point.col < 0
        ? 0.0
        : point.col >= cols
        ? size.width
        : point.col * strideX + tileWidth / 2;
    final y = point.row < 0
        ? 0.0
        : point.row >= rows
        ? size.height
        : point.row * strideY + tileHeight / 2;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant _VisualSearchLinkRoutePainter oldDelegate) {
    return oldDelegate.path != path ||
        oldDelegate.rows != rows ||
        oldDelegate.cols != cols ||
        oldDelegate.spacing != spacing ||
        oldDelegate.color != color;
  }
}

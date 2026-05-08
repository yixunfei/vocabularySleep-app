part of 'toolbox_human_tests.dart';

enum _VisualSearchMode { search, difference }

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

  _VisualSearchMode _mode = _VisualSearchMode.search;
  int _roundCount = 10;
  int _gridSize = 5;
  int _roundIndex = 0;
  int _correct = 0;
  int _wrong = 0;
  int _streak = 0;
  int _bestStreak = 0;
  bool _running = false;
  bool _done = false;
  int? _correctIndex;
  int? _lastTappedIndex;
  bool? _lastCorrect;
  List<_VisualSearchCell> _cells = const <_VisualSearchCell>[];
  List<_VisualSearchCell> _leftCells = const <_VisualSearchCell>[];
  List<_VisualSearchCell> _rightCells = const <_VisualSearchCell>[];

  int get _activeGridSize => _mode == _VisualSearchMode.difference
      ? math.min(_gridSize, 5)
      : _gridSize;

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
    super.dispose();
  }

  void _buildPreviewRound() {
    if (_mode == _VisualSearchMode.search) {
      _buildSearchRound();
    } else {
      _buildDifferenceRound();
    }
  }

  void _start() {
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _records.clear();
      _roundIndex = 0;
      _correct = 0;
      _wrong = 0;
      _streak = 0;
      _bestStreak = 0;
      _running = true;
      _done = false;
      _lastTappedIndex = null;
      _lastCorrect = null;
    });
    _beginRound();
  }

  void _reset() {
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _records.clear();
      _roundIndex = 0;
      _correct = 0;
      _wrong = 0;
      _streak = 0;
      _bestStreak = 0;
      _running = false;
      _done = false;
      _lastTappedIndex = null;
      _lastCorrect = null;
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

  void _beginRound() {
    if (!mounted || !_running) {
      return;
    }
    if (_roundIndex >= _roundCount) {
      _finish();
      return;
    }
    setState(() {
      _lastTappedIndex = null;
      _lastCorrect = null;
      if (_mode == _VisualSearchMode.search) {
        _buildSearchRound();
      } else {
        _buildDifferenceRound();
      }
      _stopwatch
        ..reset()
        ..start();
    });
  }

  void _finish() {
    _stopwatch.stop();
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

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
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
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(child: _buildStage(context, i18n)),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: pickUiText(i18n, zh: '视觉搜索设置', en: 'Visual search settings'),
          subtitle: pickUiText(
            i18n,
            zh: '切换搜索或找不同，并调整网格密度与轮数。',
            en: 'Switch search modes and adjust grid density and rounds.',
          ),
          child: _buildSettings(context, i18n),
        ),
      ],
    );
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
            SegmentedButton<_VisualSearchMode>(
              segments: <ButtonSegment<_VisualSearchMode>>[
                ButtonSegment<_VisualSearchMode>(
                  value: _VisualSearchMode.search,
                  icon: const Icon(Icons.manage_search_rounded),
                  label: Text(pickUiText(i18n, zh: '找目标', en: 'Search')),
                ),
                ButtonSegment<_VisualSearchMode>(
                  value: _VisualSearchMode.difference,
                  icon: const Icon(Icons.compare_rounded),
                  label: Text(pickUiText(i18n, zh: '找不同', en: 'Difference')),
                ),
              ],
              selected: <_VisualSearchMode>{_mode},
              onSelectionChanged: _running
                  ? null
                  : (values) => _setMode(values.first),
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
          child: _mode == _VisualSearchMode.search
              ? _buildSearchGrid(context, i18n)
              : _buildDifferenceGrid(context, i18n),
        ),
      ],
    );
  }

  String _stagePrompt(AppI18n i18n) {
    if (!_running && !_done) {
      return pickUiText(
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
    return _mode == _VisualSearchMode.search
        ? pickUiText(i18n, zh: '找出唯一的目标格。', en: 'Find the unique target tile.')
        : pickUiText(
            i18n,
            zh: '比较左右面板，点出差异所在位置。',
            en: 'Compare both panels and tap the changed position.',
          );
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

  Widget _buildSettings(BuildContext context, AppI18n i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
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
        Text(pickUiText(i18n, zh: '网格密度', en: 'Grid density')),
        Slider(
          value: _gridSize.toDouble(),
          min: 3,
          max: 7,
          divisions: 4,
          label: '${_activeGridSize}x$_activeGridSize',
          onChanged: _running
              ? null
              : (value) {
                  setState(() {
                    _gridSize = value.round();
                    _buildPreviewRound();
                  });
                },
        ),
      ],
    );
  }

  Future<void> _showReport() async {
    if (!mounted) {
      return;
    }
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
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
                  metrics: <(String, String)>[
                    (
                      pickUiText(i18n, zh: '准确率', en: 'Accuracy'),
                      '${(_accuracy * 100).round()}%',
                    ),
                    (
                      pickUiText(i18n, zh: '平均用时', en: 'Avg time'),
                      _records.isEmpty ? '-' : _formatMilliseconds(_averageMs),
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
                    _accuracy >= 0.85
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
}

part of 'toolbox_human_tests.dart';

class StroopTestPage extends StatelessWidget {
  const StroopTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '斯特鲁普', en: 'Stroop test'),
      subtitle: pickUiText(
        i18n,
        zh: '判断文字含义和显示颜色是否一致，抵抗自动阅读干扰。',
        en: 'Judge whether word meaning and ink color match, resisting the reading reflex.',
      ),
      accent: const Color(0xFF5B82C2),
      icon: Icons.contrast_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：判断是否一致',
        en: 'Next: decide match or mismatch',
      ),
      child: const _StroopTestCard(),
    );
  }
}

class _StroopItem {
  const _StroopItem({required this.zh, required this.en, required this.color});

  final String zh;
  final String en;
  final Color color;
}

class _StroopTestCard extends StatefulWidget {
  const _StroopTestCard();

  @override
  State<_StroopTestCard> createState() => _StroopTestCardState();
}

enum _StroopMode { matchMismatch, inkColor, wordMeaning, reverseRule }

class _StroopRoundRecord {
  const _StroopRoundRecord({
    required this.mode,
    required this.correct,
    required this.reactionMs,
  });

  final _StroopMode mode;
  final bool correct;
  final int reactionMs;
}

class _StroopTestCardState extends State<_StroopTestCard> {
  final math.Random _random = math.Random();
  final List<_StroopItem> _allItems = const <_StroopItem>[
    _StroopItem(zh: '红色', en: 'Red', color: Color(0xFFC24D4D)),
    _StroopItem(zh: '蓝色', en: 'Blue', color: Color(0xFF4D73C2)),
    _StroopItem(zh: '绿色', en: 'Green', color: Color(0xFF3F9A6B)),
    _StroopItem(zh: '黄色', en: 'Yellow', color: Color(0xFFD39B35)),
    _StroopItem(zh: '紫色', en: 'Purple', color: Color(0xFF8C63D8)),
    _StroopItem(zh: '橙色', en: 'Orange', color: Color(0xFFE58C3D)),
    _StroopItem(zh: '粉色', en: 'Pink', color: Color(0xFFD46E98)),
    _StroopItem(zh: '棕色', en: 'Brown', color: Color(0xFF8B6A4F)),
    _StroopItem(zh: '青色', en: 'Cyan', color: Color(0xFF41A8B9)),
    _StroopItem(zh: '灰色', en: 'Gray', color: Color(0xFF7E8795)),
    _StroopItem(zh: '黄绿', en: 'Lime', color: Color(0xFF8ABF45)),
    _StroopItem(zh: '靛蓝', en: 'Indigo', color: Color(0xFF5E6FD1)),
  ];
  int _colorCount = 4;
  int _roundLimit = 24;
  _StroopMode _mode = _StroopMode.matchMismatch;
  late _StroopItem _word;
  late _StroopItem _ink;
  int _score = 0;
  int _round = 0;
  int _lives = 3;
  DateTime? _roundStartedAt;
  bool _reportDialogOpen = false;
  final List<_StroopRoundRecord> _records = <_StroopRoundRecord>[];

  List<_StroopItem> get _activeItems =>
      _allItems.take(_colorCount).toList(growable: false);

  bool get _finished => _lives <= 0 || _records.length >= _roundLimit;

  int get _averageReactionMs {
    if (_records.isEmpty) {
      return 0;
    }
    return (_records.fold<int>(0, (sum, record) => sum + record.reactionMs) /
            _records.length)
        .round();
  }

  @override
  void initState() {
    super.initState();
    _next();
  }

  void _next() {
    final pool = _activeItems;
    _word = _sample(_random, pool);
    if (_random.nextDouble() < 0.45) {
      _ink = _word;
    } else {
      final options = pool
          .where((item) => item != _word)
          .toList(growable: false);
      _ink = _sample(_random, options);
    }
    _round += 1;
    _roundStartedAt = DateTime.now();
  }

  void _answer(bool match) {
    if (_finished) {
      return;
    }
    final same = _word == _ink;
    final correct = _mode == _StroopMode.reverseRule
        ? same != match
        : same == match;
    _recordAnswer(correct);
  }

  void _answerColor(_StroopItem answer) {
    if (_finished) {
      return;
    }
    final target = _mode == _StroopMode.wordMeaning ? _word : _ink;
    _recordAnswer(answer == target);
  }

  void _recordAnswer(bool correct) {
    final started = _roundStartedAt ?? DateTime.now();
    final reactionMs = DateTime.now().difference(started).inMilliseconds;
    setState(() {
      _records.add(
        _StroopRoundRecord(
          mode: _mode,
          correct: correct,
          reactionMs: reactionMs,
        ),
      );
      if (correct) {
        _score += 1;
      } else {
        _lives -= 1;
      }
      if (!_finished) {
        _next();
      }
    });
    if (_finished) {
      unawaited(_showReport());
    }
  }

  void _reset() {
    setState(() {
      _score = 0;
      _round = 0;
      _lives = 3;
      _records.clear();
      _next();
    });
  }

  void _setColorCount(int count) {
    setState(() {
      _colorCount = count;
      _score = 0;
      _round = 0;
      _lives = 3;
      _records.clear();
      _next();
    });
  }

  void _setMode(_StroopMode mode) {
    setState(() {
      _mode = mode;
      _score = 0;
      _round = 0;
      _lives = 3;
      _records.clear();
      _next();
    });
  }

  void _setRoundLimit(int value) {
    setState(() {
      _roundLimit = value;
      _score = 0;
      _round = 0;
      _lives = 3;
      _records.clear();
      _next();
    });
  }

  Future<void> _showReport() async {
    if (!mounted || _records.isEmpty || _reportDialogOpen) {
      return;
    }
    _reportDialogOpen = true;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    try {
      await showDialog<void>(
        context: context,
        builder: (context) => _StroopReportDialog(
          i18n: i18n,
          mode: _modeLabel(i18n, _mode),
          records: List<_StroopRoundRecord>.unmodifiable(_records),
          score: _score,
          roundLimit: _roundLimit,
          livesLeft: _lives,
        ),
      );
    } finally {
      _reportDialogOpen = false;
    }
  }

  String _modeLabel(AppI18n i18n, _StroopMode mode) {
    return switch (mode) {
      _StroopMode.matchMismatch => pickUiText(
        i18n,
        zh: '一致判断',
        en: 'Match judge',
      ),
      _StroopMode.inkColor => pickUiText(i18n, zh: '说出墨色', en: 'Ink color'),
      _StroopMode.wordMeaning => pickUiText(
        i18n,
        zh: '读出字义',
        en: 'Word meaning',
      ),
      _StroopMode.reverseRule => pickUiText(
        i18n,
        zh: '反向规则',
        en: 'Reverse rule',
      ),
    };
  }

  String _instruction(AppI18n i18n) {
    return switch (_mode) {
      _StroopMode.matchMismatch => pickUiText(
        i18n,
        zh: '判断文字含义和显示颜色是否一致。',
        en: 'Decide whether word meaning and ink color match.',
      ),
      _StroopMode.inkColor => pickUiText(
        i18n,
        zh: '忽略文字含义，只选择显示出来的墨色。',
        en: 'Ignore the word and select the ink color.',
      ),
      _StroopMode.wordMeaning => pickUiText(
        i18n,
        zh: '忽略墨色，只选择文字本身的含义。',
        en: 'Ignore the ink and select the word meaning.',
      ),
      _StroopMode.reverseRule => pickUiText(
        i18n,
        zh: '反向作答：相同点“不一致”，不同点“一致”。',
        en: 'Reverse answers: same means Mismatch, different means Match.',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final wordLabel = pickUiText(i18n, zh: _word.zh, en: _word.en);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (pickUiText(i18n, zh: '得分', en: 'Score'), '$_score'),
            (
              pickUiText(i18n, zh: '轮次', en: 'Round'),
              '${_records.length}/$_roundLimit',
            ),
            (pickUiText(i18n, zh: '生命', en: 'Lives'), '$_lives'),
            (pickUiText(i18n, zh: '颜色数', en: 'Colors'), '$_colorCount'),
            (
              pickUiText(i18n, zh: '平均反应', en: 'Avg reaction'),
              _averageReactionMs == 0
                  ? '-'
                  : _formatMilliseconds(_averageReactionMs),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _HumanSettingsSection(
                title: pickUiText(i18n, zh: '设置项', en: 'Settings'),
                subtitle: pickUiText(
                  i18n,
                  zh: '颜色数量可调范围：3-12',
                  en: 'Color count range: 3-12',
                ),
                initiallyExpanded: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      pickUiText(i18n, zh: '子模式', en: 'Submode'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _StroopMode.values
                          .map(
                            (mode) => ChoiceChip(
                              label: Text(_modeLabel(i18n, mode)),
                              selected: _mode == mode,
                              onSelected: (_) => _setMode(mode),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      pickUiText(
                        i18n,
                        zh: '颜色数量设置（3-12）',
                        en: 'Color count setting (3-12)',
                      ),
                      style: theme.textTheme.labelLarge,
                    ),
                    Slider(
                      value: _colorCount.toDouble(),
                      min: 3,
                      max: 12,
                      divisions: 9,
                      label: '$_colorCount',
                      onChanged: (value) => _setColorCount(value.round()),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pickUiText(i18n, zh: '本轮题数', en: 'Round count'),
                      style: theme.textTheme.labelLarge,
                    ),
                    Slider(
                      value: _roundLimit.toDouble(),
                      min: 12,
                      max: 60,
                      divisions: 8,
                      label: '$_roundLimit',
                      onChanged: (value) => _setRoundLimit(value.round()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 150,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Text(
                  wordLabel,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _ink.color,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _instruction(i18n),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              if (_mode == _StroopMode.matchMismatch ||
                  _mode == _StroopMode.reverseRule)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _HumanActionButton(
                      label: pickUiText(i18n, zh: '一致', en: 'Match'),
                      icon: Icons.check_rounded,
                      onPressed: _finished ? null : () => _answer(true),
                    ),
                    OutlinedButton.icon(
                      onPressed: _finished ? null : () => _answer(false),
                      icon: const Icon(Icons.close_rounded),
                      label: Text(pickUiText(i18n, zh: '不一致', en: 'Mismatch')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _records.isEmpty
                          ? null
                          : () => unawaited(_showReport()),
                      icon: const Icon(Icons.analytics_rounded),
                      label: Text(pickUiText(i18n, zh: '报告', en: 'Report')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
                    ),
                  ],
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    ..._activeItems.map(
                      (item) => OutlinedButton.icon(
                        onPressed: _finished ? null : () => _answerColor(item),
                        icon: Icon(Icons.circle_rounded, color: item.color),
                        label: Text(pickUiText(i18n, zh: item.zh, en: item.en)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _records.isEmpty
                          ? null
                          : () => unawaited(_showReport()),
                      icon: const Icon(Icons.analytics_rounded),
                      label: Text(pickUiText(i18n, zh: '报告', en: 'Report')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
                    ),
                  ],
                ),
              if (_finished) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: theme.colorScheme.secondaryContainer.withValues(
                      alpha: 0.42,
                    ),
                  ),
                  child: Text(
                    pickUiText(
                      i18n,
                      zh: '本轮已结束，可查看报告或重置后继续。',
                      en: 'This run is complete. View the report or reset.',
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StroopReportDialog extends StatelessWidget {
  const _StroopReportDialog({
    required this.i18n,
    required this.mode,
    required this.records,
    required this.score,
    required this.roundLimit,
    required this.livesLeft,
  });

  final AppI18n i18n;
  final String mode;
  final List<_StroopRoundRecord> records;
  final int score;
  final int roundLimit;
  final int livesLeft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = records.isEmpty ? 0.0 : score / records.length;
    final avgReaction = records.isEmpty
        ? 0
        : (records.fold<int>(0, (sum, record) => sum + record.reactionMs) /
                  records.length)
              .round();
    final errors = records.where((record) => !record.correct).length;
    final recommendation = accuracy >= 0.9 && avgReaction <= 900
        ? pickUiText(
            i18n,
            zh: '准确率和速度都比较稳定，可以提高颜色数量或切换到反向规则。',
            en: 'Accuracy and speed are stable. Increase colors or switch to reverse rule.',
          )
        : accuracy < 0.7
        ? pickUiText(
            i18n,
            zh: '错误偏多，建议先减少颜色数量，使用“说出墨色”模式单独练习抑制阅读反射。',
            en: 'Errors are high. Reduce colors and practice Ink color mode to isolate response inhibition.',
          )
        : pickUiText(
            i18n,
            zh: '表现接近稳定，下一轮可以保持当前模式并稍微增加题数。',
            en: 'Performance is close to stable. Keep this mode and slightly increase the round count.',
          );
    return AlertDialog(
      title: Text(pickUiText(i18n, zh: '斯特鲁普报告', en: 'Stroop report')),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '准确率', en: 'Accuracy'),
                    value: '${(accuracy * 100).round()}%',
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '平均反应', en: 'Avg reaction'),
                    value: avgReaction == 0
                        ? '-'
                        : _formatMilliseconds(avgReaction),
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '得分', en: 'Score'),
                    value: '$score/${records.length}',
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '错误', en: 'Errors'),
                    value: '$errors',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ColorVisionReportSection(
                title: pickUiText(i18n, zh: '本轮设置', en: 'Session settings'),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    Chip(label: Text(mode)),
                    Chip(label: Text('$roundLimit rounds')),
                    Chip(label: Text('$livesLeft lives left')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ColorVisionReportSection(
                title: pickUiText(i18n, zh: '训练建议', en: 'Training note'),
                child: Text(
                  recommendation,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(pickUiText(i18n, zh: '关闭', en: 'Close')),
        ),
      ],
    );
  }
}

class LuckTestPage extends StatelessWidget {
  const LuckTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '运气测试', en: 'Luck test'),
      subtitle: pickUiText(
        i18n,
        zh: '支持单抽、十连、二十连、概率自定义和目标抽取，按期望值计算幸运指数。',
        en: 'Single, 10x, and 20x card draws with custom odds, goals, and expectation-based luck index.',
      ),
      accent: const Color(0xFFD0923A),
      icon: Icons.casino_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：选择抽卡模式或目标',
        en: 'Next: choose a draw mode or target',
      ),
      child: const _LuckTestCard(),
    );
  }
}

class _LuckTestCard extends StatefulWidget {
  const _LuckTestCard();

  @override
  State<_LuckTestCard> createState() => _LuckTestCardState();
}

class _LuckCardTier {
  const _LuckCardTier({
    required this.zh,
    required this.en,
    required this.color,
    required this.score,
    required this.defaultWeight,
  });

  final String zh;
  final String en;
  final Color color;
  final int score;
  final double defaultWeight;
}

enum _LuckDrawMode { single, ten, twenty }

enum _LuckGoalType { unlimited, tierCount, luckIndex, drawCount }

class _LuckTestCardState extends State<_LuckTestCard>
    with SingleTickerProviderStateMixin {
  final math.Random _random = math.Random();
  final List<_LuckCardTier> _tiers = const <_LuckCardTier>[
    _LuckCardTier(
      zh: '普通卡',
      en: 'Common',
      color: Color(0xFF8A95A7),
      score: 1,
      defaultWeight: 42,
    ),
    _LuckCardTier(
      zh: '优质卡',
      en: 'Uncommon',
      color: Color(0xFF58A47E),
      score: 2,
      defaultWeight: 28,
    ),
    _LuckCardTier(
      zh: '稀有卡',
      en: 'Rare',
      color: Color(0xFF4F87D7),
      score: 3,
      defaultWeight: 17,
    ),
    _LuckCardTier(
      zh: '史诗卡',
      en: 'Epic',
      color: Color(0xFFB06FD9),
      score: 4,
      defaultWeight: 9,
    ),
    _LuckCardTier(
      zh: '传说卡',
      en: 'Legendary',
      color: Color(0xFFE7A43D),
      score: 5,
      defaultWeight: 4,
    ),
  ];

  late final List<double> _weights;
  late final List<int> _tierCounts;
  late final AnimationController _flipController;
  final List<_LuckCardTier> _history = <_LuckCardTier>[];
  final List<_LuckCardTier> _lastBatch = <_LuckCardTier>[];
  final List<_LuckCardTier> _batchCards = <_LuckCardTier>[];
  final List<bool> _batchRevealed = <bool>[];
  final List<int> _deckOrder = List<int>.generate(5, (index) => index);

  int _draws = 0;
  int _streak = 0;
  int _best = 0;
  int _selectedCard = -1;
  double _totalScore = 0;
  double _expectedScoreTotal = 0;
  double _varianceTotal = 0;
  _LuckCardTier? _lastTier;
  _LuckCardTier? _revealedTier;
  _LuckDrawMode _drawMode = _LuckDrawMode.single;
  _LuckGoalType _goalType = _LuckGoalType.unlimited;
  int _goalTierIndex = 4;
  int _goalTierCount = 1;
  int _goalLuckIndex = 130;
  int _goalDrawCount = 100;
  bool _shuffling = false;
  bool _rareEffectEnabled = true;
  int _flipToken = 0;
  bool _goalReportShown = false;
  bool _reportDialogOpen = false;
  OverlayEntry? _rareOverlayEntry;

  @override
  void initState() {
    super.initState();
    _weights = _tiers.map((tier) => tier.defaultWeight).toList(growable: false);
    _tierCounts = List<int>.filled(_tiers.length, 0);
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _flipToken += 1;
    _rareOverlayEntry?.remove();
    _flipController.dispose();
    super.dispose();
  }

  bool get _busy =>
      _selectedCard >= 0 || _flipController.isAnimating || _shuffling;

  bool get _batchActive =>
      _batchCards.isNotEmpty && _batchRevealed.any((revealed) => !revealed);

  int get _batchRevealedCount =>
      _batchRevealed.where((revealed) => revealed).length;

  bool get _batchComplete =>
      _batchCards.isNotEmpty &&
      _batchRevealed.isNotEmpty &&
      _batchRevealed.every((revealed) => revealed);

  double get _weightSum => _weights.fold(0, (sum, value) => sum + value);

  int get _drawCountForMode => switch (_drawMode) {
    _LuckDrawMode.single => 1,
    _LuckDrawMode.ten => 10,
    _LuckDrawMode.twenty => 20,
  };

  double get _expectedScore {
    final sum = _weightSum;
    if (sum <= 0) {
      return _tiers.first.score.toDouble();
    }
    var expected = 0.0;
    for (var i = 0; i < _tiers.length; i += 1) {
      expected += _tiers[i].score * _weights[i] / sum;
    }
    return expected;
  }

  double get _scoreVariance {
    final sum = _weightSum;
    if (sum <= 0) {
      return 0;
    }
    final mean = _expectedScore;
    var variance = 0.0;
    for (var i = 0; i < _tiers.length; i += 1) {
      final diff = _tiers[i].score - mean;
      variance += diff * diff * _weights[i] / sum;
    }
    return variance;
  }

  double get _luckIndex {
    if (_draws <= 0) {
      return 100;
    }
    if (_varianceTotal <= 0) {
      return _totalScore >= _expectedScoreTotal ? 100 : 0;
    }
    final z = (_totalScore - _expectedScoreTotal) / math.sqrt(_varianceTotal);
    return (100 + z * 15).clamp(0, 220);
  }

  double get _averageScore => _draws == 0 ? 0 : _totalScore / _draws;

  bool get _goalCompleted {
    if (_draws <= 0) {
      return false;
    }
    return switch (_goalType) {
      _LuckGoalType.unlimited => false,
      _LuckGoalType.tierCount => _tierCounts[_goalTierIndex] >= _goalTierCount,
      _LuckGoalType.luckIndex => _luckIndex >= _goalLuckIndex,
      _LuckGoalType.drawCount => _draws >= _goalDrawCount,
    };
  }

  String _tierLabel(AppI18n i18n, _LuckCardTier tier) {
    return pickUiText(i18n, zh: tier.zh, en: tier.en);
  }

  _LuckCardTier _drawTier() {
    final sum = _weightSum;
    if (sum <= 0) {
      return _tiers.first;
    }
    final hit = _random.nextDouble() * sum;
    var cumulative = 0.0;
    for (var i = 0; i < _tiers.length; i += 1) {
      cumulative += _weights[i];
      if (hit <= cumulative) {
        return _tiers[i];
      }
    }
    return _tiers.last;
  }

  void _recordTier(_LuckCardTier tier) {
    final index = _tiers.indexOf(tier);
    _draws += 1;
    _totalScore += tier.score;
    _expectedScoreTotal += _expectedScore;
    _varianceTotal += _scoreVariance;
    if (index >= 0) {
      _tierCounts[index] += 1;
    }
    _history.insert(0, tier);
    if (_history.length > 20) {
      _history.removeLast();
    }
    final lucky = tier.score >= 4;
    _streak = lucky ? _streak + 1 : 0;
    _best = math.max(_best, _streak);
    _lastTier = tier;
  }

  double _probability(int index) {
    final sum = _weightSum;
    if (sum <= 0) {
      return 0;
    }
    return _weights[index] / sum * 100;
  }

  bool _isRareTier(_LuckCardTier tier) => tier.score >= 4;

  void _maybeShowRareEffect(_LuckCardTier tier) {
    if (!_rareEffectEnabled || !_isRareTier(tier) || !mounted) {
      return;
    }
    _rareOverlayEntry?.remove();
    _rareOverlayEntry = OverlayEntry(
      builder: (context) => _LuckRareEffectOverlay(
        tier: tier,
        label: _tierLabel(
          AppI18n(Localizations.localeOf(context).languageCode),
          tier,
        ),
      ),
    );
    Overlay.of(context).insert(_rareOverlayEntry!);
    Future<void>.delayed(const Duration(milliseconds: 2600), () {
      _rareOverlayEntry?.remove();
      _rareOverlayEntry = null;
    });
  }

  Future<void> _pickCard(int cardIndex) async {
    if (_busy) {
      return;
    }
    final token = ++_flipToken;
    final tier = _drawTier();
    setState(() {
      _lastBatch
        ..clear()
        ..add(tier);
      _batchCards.clear();
      _batchRevealed.clear();
      _selectedCard = cardIndex;
      _revealedTier = tier;
      _recordTier(tier);
    });
    _maybeShowRareEffect(tier);

    await _flipController.forward(from: 0);
    if (!mounted || token != _flipToken) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted || token != _flipToken) {
      return;
    }

    setState(() => _shuffling = true);
    await Future<void>.delayed(const Duration(milliseconds: 360));
    if (!mounted || token != _flipToken) {
      return;
    }

    setState(() {
      _deckOrder.shuffle(_random);
      _selectedCard = -1;
      _revealedTier = null;
      _shuffling = false;
    });
    _flipController.reset();
    await _maybeShowGoalReport();
  }

  Future<void> _drawCurrentMode() async {
    if (_drawMode == _LuckDrawMode.single) {
      await _pickCard(_random.nextInt(_deckOrder.length));
      return;
    }
    await _drawBatch(_drawCountForMode);
  }

  Future<void> _drawBatch(int count) async {
    if (_busy || _batchActive) {
      return;
    }
    final token = ++_flipToken;
    setState(() {
      _shuffling = true;
      _selectedCard = -1;
      _revealedTier = null;
      _lastBatch.clear();
      _batchCards.clear();
      _batchRevealed.clear();
    });
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted || token != _flipToken) {
      return;
    }
    final batch = List<_LuckCardTier>.generate(count, (_) => _drawTier());
    setState(() {
      _batchCards
        ..clear()
        ..addAll(batch);
      _batchRevealed
        ..clear()
        ..addAll(List<bool>.filled(batch.length, false));
      _deckOrder.shuffle(_random);
      _shuffling = false;
    });
  }

  Future<void> _revealBatchCard(int index) async {
    if (_shuffling ||
        index < 0 ||
        index >= _batchCards.length ||
        _batchRevealed[index]) {
      return;
    }
    final tier = _batchCards[index];
    setState(() {
      _batchRevealed[index] = true;
      _recordTier(tier);
      _lastBatch
        ..clear()
        ..addAll(_revealedBatchCards());
    });
    _maybeShowRareEffect(tier);
    await _maybeShowGoalReport();
  }

  List<_LuckCardTier> _revealedBatchCards() {
    final revealed = <_LuckCardTier>[];
    for (var index = 0; index < _batchCards.length; index += 1) {
      if (_batchRevealed[index]) {
        revealed.add(_batchCards[index]);
      }
    }
    return revealed;
  }

  Future<void> _revealAllBatch() async {
    if (_batchCards.isEmpty || !_batchActive) {
      return;
    }
    for (var index = 0; index < _batchCards.length; index += 1) {
      if (!mounted) {
        return;
      }
      if (!_batchRevealed[index]) {
        await _revealBatchCard(index);
        await Future<void>.delayed(const Duration(milliseconds: 70));
      }
    }
  }

  Future<void> _continueBatch() async {
    if (_busy || _batchActive || _drawMode == _LuckDrawMode.single) {
      return;
    }
    await _drawBatch(_drawCountForMode);
  }

  void _reset() {
    _flipToken += 1;
    _rareOverlayEntry?.remove();
    _rareOverlayEntry = null;
    _flipController.reset();
    setState(() {
      _history.clear();
      _lastBatch.clear();
      _batchCards.clear();
      _batchRevealed.clear();
      for (var i = 0; i < _tierCounts.length; i += 1) {
        _tierCounts[i] = 0;
      }
      _draws = 0;
      _streak = 0;
      _best = 0;
      _selectedCard = -1;
      _totalScore = 0;
      _expectedScoreTotal = 0;
      _varianceTotal = 0;
      _lastTier = null;
      _revealedTier = null;
      _shuffling = false;
      _goalReportShown = false;
      _deckOrder.shuffle(_random);
    });
  }

  void _resetWeights() {
    setState(() {
      for (var i = 0; i < _weights.length; i += 1) {
        _weights[i] = _tiers[i].defaultWeight;
      }
    });
  }

  void _setDrawMode(_LuckDrawMode mode) {
    if (_busy || _drawMode == mode) {
      return;
    }
    setState(() {
      _drawMode = mode;
      _selectedCard = -1;
      _revealedTier = null;
      _batchCards.clear();
      _batchRevealed.clear();
      _lastBatch.clear();
    });
  }

  String _drawModeLabel(AppI18n i18n, _LuckDrawMode mode) {
    return switch (mode) {
      _LuckDrawMode.single => pickUiText(i18n, zh: '单抽', en: 'Single'),
      _LuckDrawMode.ten => pickUiText(i18n, zh: '十连', en: '10 draws'),
      _LuckDrawMode.twenty => pickUiText(i18n, zh: '二十连', en: '20 draws'),
    };
  }

  String _goalTypeLabel(AppI18n i18n, _LuckGoalType type) {
    return switch (type) {
      _LuckGoalType.unlimited => pickUiText(i18n, zh: '无限次', en: 'Unlimited'),
      _LuckGoalType.tierCount => pickUiText(i18n, zh: '卡片数量', en: 'Tier count'),
      _LuckGoalType.luckIndex => pickUiText(i18n, zh: '幸运指数', en: 'Luck index'),
      _LuckGoalType.drawCount => pickUiText(i18n, zh: '抽数目标', en: 'Draw cap'),
    };
  }

  String _goalSummary(AppI18n i18n) {
    return switch (_goalType) {
      _LuckGoalType.unlimited => pickUiText(i18n, zh: '无限次', en: 'Unlimited'),
      _LuckGoalType.tierCount =>
        '${_tierLabel(i18n, _tiers[_goalTierIndex])} x $_goalTierCount',
      _LuckGoalType.luckIndex =>
        '${_goalLuckIndex} ${pickUiText(i18n, zh: '点', en: 'pts')}',
      _LuckGoalType.drawCount => '$_goalDrawCount',
    };
  }

  String _batchSummary(AppI18n i18n) {
    if (_lastBatch.isEmpty) {
      return '';
    }
    final counts = <_LuckCardTier, int>{};
    for (final tier in _lastBatch) {
      counts[tier] = (counts[tier] ?? 0) + 1;
    }
    return _tiers
        .where((tier) => counts.containsKey(tier))
        .map((tier) => '${_tierLabel(i18n, tier)} x ${counts[tier]}')
        .join(' · ');
  }

  String _luckTitle(AppI18n i18n) {
    final index = _luckIndex;
    if (index >= 130) {
      return pickUiText(i18n, zh: '欧皇在世', en: 'Mythic luck');
    }
    if (index >= 118) {
      return pickUiText(i18n, zh: '气运之子', en: 'Fortune favored');
    }
    if (index >= 106) {
      return pickUiText(i18n, zh: '小幸运', en: 'Lucky streak');
    }
    if (index >= 90) {
      return pickUiText(i18n, zh: '普普通通', en: 'Average luck');
    }
    if (index >= 75) {
      return pickUiText(i18n, zh: '运气不佳', en: 'Below odds');
    }
    return pickUiText(i18n, zh: '非酋', en: 'Cursed run');
  }

  Future<void> _maybeShowGoalReport() async {
    if (!_goalCompleted || _goalReportShown) {
      return;
    }
    _goalReportShown = true;
    await _showReport(goalCompleted: true);
  }

  Future<void> _showReport({bool goalCompleted = false}) async {
    if (!mounted || _reportDialogOpen) {
      return;
    }
    _reportDialogOpen = true;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    try {
      await showDialog<void>(
        context: context,
        builder: (context) => _LuckReportDialog(
          i18n: i18n,
          tiers: _tiers,
          counts: List<int>.unmodifiable(_tierCounts),
          draws: _draws,
          totalScore: _totalScore,
          expectedScoreTotal: _expectedScoreTotal,
          luckIndex: _luckIndex,
          luckTitle: _luckTitle(i18n),
          bestStreak: _best,
          goalCompleted: goalCompleted,
          goalText: _goalSummary(i18n),
          tierLabel: (tier) => _tierLabel(i18n, tier),
        ),
      );
    } finally {
      _reportDialogOpen = false;
    }
  }

  Widget _buildCardFront(BuildContext context, int cardNo) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 132,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF314A69), Color(0xFF1A2941)],
        ),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              'A$cardNo',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              'A$cardNo',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.70),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white.withValues(alpha: 0.90),
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(
    BuildContext context,
    AppI18n i18n,
    int cardNo,
    _LuckCardTier tier,
  ) {
    final title = _tierLabel(i18n, tier);
    return Container(
      height: 132,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            tier.color.withValues(alpha: 0.92),
            tier.color.withValues(alpha: 0.64),
          ],
        ),
        border: Border.all(
          color: tier.color.withValues(alpha: 0.95),
          width: 1.3,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x2A000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              '#$cardNo',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pickUiText(
                    i18n,
                    zh: '幸运值 +${tier.score}',
                    en: 'Luck +${tier.score}',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, AppI18n i18n, int slotIndex) {
    final selected = _selectedCard == slotIndex;
    final progress = selected ? _flipController.value : 0.0;
    final showBack = selected && progress >= 0.5;
    var angle = progress * math.pi;
    if (showBack) {
      angle -= math.pi;
    }
    final cardNo = _deckOrder[slotIndex] + 1;

    return SizedBox(
      width: 92,
      child: GestureDetector(
        onTap: _busy ? null : () => _pickCard(slotIndex),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: _busy && !selected ? 0.74 : 1,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0018)
              ..rotateY(angle),
            child: showBack && _revealedTier != null
                ? _buildCardBack(context, i18n, cardNo, _revealedTier!)
                : _buildCardFront(context, cardNo),
          ),
        ),
      ),
    );
  }

  Widget _buildBatchCard(BuildContext context, AppI18n i18n, int index) {
    final revealed = _batchRevealed[index];
    final tier = _batchCards[index];
    return GestureDetector(
      onTap: revealed ? null : () => unawaited(_revealBatchCard(index)),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: revealed ? 1 : 0),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeInOutCubic,
        builder: (context, progress, child) {
          final showBack = progress >= 0.5;
          var angle = progress * math.pi;
          if (showBack) {
            angle -= math.pi;
          }
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0018)
              ..rotateY(angle),
            child: SizedBox(
              width: 88,
              child: showBack
                  ? _buildCardBack(context, i18n, index + 1, tier)
                  : _buildCardFront(context, index + 1),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (pickUiText(i18n, zh: '抽卡', en: 'Draws'), '$_draws'),
            (
              pickUiText(i18n, zh: '幸运指数', en: 'Luck index'),
              _draws == 0 ? '-' : _luckIndex.toStringAsFixed(0),
            ),
            (
              pickUiText(i18n, zh: '均值/期望', en: 'Avg/expected'),
              _draws == 0
                  ? '-'
                  : '${_averageScore.toStringAsFixed(2)}/${(_expectedScoreTotal / _draws).toStringAsFixed(2)}',
            ),
            (pickUiText(i18n, zh: '目标', en: 'Goal'), _goalSummary(i18n)),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color:
                      (_lastTier?.color ??
                              Theme.of(context).colorScheme.surface)
                          .withValues(alpha: 0.20),
                ),
                child: Text(
                  _shuffling
                      ? pickUiText(
                          i18n,
                          zh: '正在抽取并洗牌，请稍候。',
                          en: 'Drawing and shuffling. Please wait.',
                        )
                      : _lastBatch.length > 1
                      ? pickUiText(
                          i18n,
                          zh: '已翻开 $_batchRevealedCount/${_batchCards.isEmpty ? _lastBatch.length : _batchCards.length} 张：${_batchSummary(i18n)}',
                          en: 'Revealed $_batchRevealedCount/${_batchCards.isEmpty ? _lastBatch.length : _batchCards.length}: ${_batchSummary(i18n)}',
                        )
                      : _batchActive
                      ? pickUiText(
                          i18n,
                          zh: '已生成 ${_batchCards.length} 张卡片，点击卡片逐张翻开或一键全翻。',
                          en: '${_batchCards.length} cards are ready. Tap cards to flip them or reveal all.',
                        )
                      : _revealedTier == null
                      ? pickUiText(
                          i18n,
                          zh: '点击卡牌可单抽，也可以使用下方按钮按当前模式抽取。',
                          en: 'Tap a card for one draw, or use the button below for the selected mode.',
                        )
                      : pickUiText(
                          i18n,
                          zh: '本次翻到：${_tierLabel(i18n, _revealedTier!)}',
                          en: 'Revealed: ${_tierLabel(i18n, _revealedTier!)}',
                        ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_drawMode == _LuckDrawMode.single)
                AnimatedBuilder(
                  animation: _flipController,
                  builder: (context, _) {
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List<Widget>.generate(
                        5,
                        (slotIndex) => _buildCard(context, i18n, slotIndex),
                      ),
                    );
                  },
                )
              else if (_batchCards.isEmpty)
                Container(
                  constraints: const BoxConstraints(minHeight: 116),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.34,
                    ),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Text(
                    pickUiText(
                      i18n,
                      zh: '当前为${_drawModeLabel(i18n, _drawMode)}模式，点击下方按钮生成 $_drawCountForMode 张卡片。',
                      en: '${_drawModeLabel(i18n, _drawMode)} mode: press the button below to generate $_drawCountForMode cards.',
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ),
              if (_drawMode != _LuckDrawMode.single &&
                  _batchCards.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _HumanSettingsSection(
                  title: pickUiText(i18n, zh: '多连抽卡片', en: 'Multi-draw cards'),
                  subtitle: pickUiText(
                    i18n,
                    zh: '真实生成本次连抽的全部卡片，翻开后才计入统计。',
                    en: 'All cards are generated for this batch and count after reveal.',
                  ),
                  initiallyExpanded: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List<Widget>.generate(
                          _batchCards.length,
                          (index) => _buildBatchCard(context, i18n, index),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          if (_batchComplete)
                            _HumanActionButton(
                              label: pickUiText(
                                i18n,
                                zh: '继续下一轮',
                                en: 'Next batch',
                              ),
                              icon: Icons.refresh_rounded,
                              onPressed: _busy
                                  ? null
                                  : () => unawaited(_continueBatch()),
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: _batchActive
                                  ? () => unawaited(_revealAllBatch())
                                  : null,
                              icon: const Icon(
                                Icons.auto_awesome_motion_rounded,
                              ),
                              label: Text(
                                pickUiText(i18n, zh: '全部翻开', en: 'Reveal all'),
                              ),
                            ),
                          Text(
                            pickUiText(
                              i18n,
                              zh: '进度 $_batchRevealedCount/${_batchCards.length}',
                              en: 'Progress $_batchRevealedCount/${_batchCards.length}',
                            ),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              if (_history.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _history
                      .map(
                        (tier) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: tier.color.withValues(alpha: 0.18),
                          ),
                          child: Text(_tierLabel(i18n, tier)),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _HumanActionButton(
                    label: pickUiText(
                      i18n,
                      zh: '${_drawModeLabel(i18n, _drawMode)}抽卡',
                      en: _drawMode == _LuckDrawMode.single
                          ? 'Single draw'
                          : '${_drawCountForMode} draws',
                    ),
                    icon: Icons.auto_awesome_rounded,
                    onPressed: _busy || _batchActive
                        ? null
                        : () => unawaited(_drawCurrentMode()),
                  ),
                  OutlinedButton.icon(
                    onPressed: _draws <= 0
                        ? null
                        : () => unawaited(_showReport()),
                    icon: const Icon(Icons.analytics_rounded),
                    label: Text(pickUiText(i18n, zh: '统计报告', en: 'Report')),
                  ),
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(
                      pickUiText(i18n, zh: '重置成绩', en: 'Reset stats'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _HumanSettingsSection(
                title: pickUiText(i18n, zh: '抽卡设置', en: 'Draw settings'),
                subtitle: pickUiText(
                  i18n,
                  zh: '选择抽卡模式、完成目标和不同卡牌概率',
                  en: 'Choose draw mode, completion goal, and card-tier odds',
                ),
                initiallyExpanded: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pickUiText(i18n, zh: '抽卡模式', en: 'Draw mode'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _LuckDrawMode.values
                          .map(
                            (mode) => ChoiceChip(
                              label: Text(_drawModeLabel(i18n, mode)),
                              selected: _drawMode == mode,
                              onSelected: _busy
                                  ? null
                                  : (_) => _setDrawMode(mode),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      pickUiText(i18n, zh: '抽卡目标', en: 'Draw goal'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _LuckGoalType.values
                          .map(
                            (type) => ChoiceChip(
                              label: Text(_goalTypeLabel(i18n, type)),
                              selected: _goalType == type,
                              onSelected: (_) {
                                setState(() {
                                  _goalType = type;
                                  _goalReportShown = false;
                                });
                              },
                            ),
                          )
                          .toList(growable: false),
                    ),
                    if (_goalType == _LuckGoalType.tierCount) ...<Widget>[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List<Widget>.generate(_tiers.length, (index) {
                          final tier = _tiers[index];
                          return ChoiceChip(
                            label: Text(_tierLabel(i18n, tier)),
                            selected: _goalTierIndex == index,
                            selectedColor: tier.color.withValues(alpha: 0.22),
                            onSelected: (_) {
                              setState(() {
                                _goalTierIndex = index;
                                _goalReportShown = false;
                              });
                            },
                          );
                        }),
                      ),
                      _LuckSettingSlider(
                        label: pickUiText(
                          i18n,
                          zh: '目标张数',
                          en: 'Target copies',
                        ),
                        valueText: '$_goalTierCount',
                        value: _goalTierCount.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        onChanged: (value) {
                          setState(() {
                            _goalTierCount = value.round();
                            _goalReportShown = false;
                          });
                        },
                      ),
                    ],
                    if (_goalType == _LuckGoalType.luckIndex)
                      _LuckSettingSlider(
                        label: pickUiText(
                          i18n,
                          zh: '目标幸运指数',
                          en: 'Target luck index',
                        ),
                        valueText: '$_goalLuckIndex',
                        value: _goalLuckIndex.toDouble(),
                        min: 80,
                        max: 180,
                        divisions: 20,
                        onChanged: (value) {
                          setState(() {
                            _goalLuckIndex = value.round();
                            _goalReportShown = false;
                          });
                        },
                      ),
                    if (_goalType == _LuckGoalType.drawCount)
                      _LuckSettingSlider(
                        label: pickUiText(i18n, zh: '目标抽数', en: 'Target draws'),
                        valueText: '$_goalDrawCount',
                        value: _goalDrawCount.toDouble(),
                        min: 10,
                        max: 200,
                        divisions: 19,
                        onChanged: (value) {
                          setState(() {
                            _goalDrawCount = value.round();
                            _goalReportShown = false;
                          });
                        },
                      ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        pickUiText(i18n, zh: '稀有抽中特效', en: 'Rare draw effects'),
                      ),
                      subtitle: Text(
                        pickUiText(
                          i18n,
                          zh: '传说和史诗出现时显示短暂全屏金光或紫色流动。',
                          en: 'Legendary and Epic reveals show a brief full-screen flash.',
                        ),
                      ),
                      value: _rareEffectEnabled,
                      onChanged: (value) =>
                          setState(() => _rareEffectEnabled = value),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pickUiText(
                        i18n,
                        zh: '卡牌概率自定义',
                        en: 'Custom card probabilities',
                      ),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    ...List<Widget>.generate(_tiers.length, (index) {
                      final tier = _tiers[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${_tierLabel(i18n, tier)} · ${_probability(index).toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Slider(
                            value: _weights[index],
                            min: 0,
                            max: 100,
                            divisions: 50,
                            activeColor: tier.color,
                            label: _weights[index].toStringAsFixed(0),
                            onChanged: (value) {
                              setState(() => _weights[index] = value);
                            },
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: _resetWeights,
                          icon: const Icon(Icons.tune_rounded),
                          label: Text(
                            pickUiText(
                              i18n,
                              zh: '恢复默认概率',
                              en: 'Reset default odds',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LuckSettingSlider extends StatelessWidget {
  const _LuckSettingSlider({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(valueText, style: theme.textTheme.labelMedium),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: valueText,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _LuckRareEffectOverlay extends StatelessWidget {
  const _LuckRareEffectOverlay({required this.tier, required this.label});

  final _LuckCardTier tier;
  final String label;

  @override
  Widget build(BuildContext context) {
    final legendary = tier.score >= 5;
    final effectColor = legendary ? const Color(0xFFFFC95A) : tier.color;
    return Positioned.fill(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 2450),
          curve: Curves.easeInOutCubic,
          builder: (context, progress, child) {
            final fade = progress < 0.12
                ? progress / 0.12
                : progress > 0.82
                ? ((1 - progress) / 0.18).clamp(0.0, 1.0)
                : 1.0;
            final wave = math.sin(progress * math.pi * 4).abs();
            return Opacity(
              opacity: fade,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.86 + progress * 0.72,
                        colors: <Color>[
                          effectColor.withValues(
                            alpha: legendary ? 0.78 : 0.68,
                          ),
                          effectColor.withValues(
                            alpha: legendary ? 0.34 : 0.42,
                          ),
                          Colors.black.withValues(alpha: 0.46),
                        ],
                        stops: const <double>[0, 0.46, 1],
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1 + progress * 2, -1),
                        end: Alignment(1 - progress * 2, 1),
                        colors: <Color>[
                          Colors.white.withValues(alpha: 0.00),
                          effectColor.withValues(alpha: 0.26 + wave * 0.18),
                          Colors.white.withValues(alpha: 0.00),
                        ],
                        stops: const <double>[0.18, 0.5, 0.82],
                      ),
                    ),
                  ),
                  Center(
                    child: Transform.scale(
                      scale: 0.88 + progress * 0.14 + wave * 0.03,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 22,
                        ),
                        constraints: const BoxConstraints(minWidth: 230),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          color: Colors.black.withValues(alpha: 0.46),
                          border: Border.all(
                            color: effectColor.withValues(alpha: 0.92),
                            width: 2,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: effectColor.withValues(alpha: 0.62),
                              blurRadius: 46,
                              spreadRadius: 12,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              legendary
                                  ? Icons.workspace_premium_rounded
                                  : Icons.auto_awesome_rounded,
                              color: effectColor,
                              size: 62,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              label,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              legendary ? 'LEGENDARY' : 'EPIC',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.86),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LuckReportDialog extends StatelessWidget {
  const _LuckReportDialog({
    required this.i18n,
    required this.tiers,
    required this.counts,
    required this.draws,
    required this.totalScore,
    required this.expectedScoreTotal,
    required this.luckIndex,
    required this.luckTitle,
    required this.bestStreak,
    required this.goalCompleted,
    required this.goalText,
    required this.tierLabel,
  });

  final AppI18n i18n;
  final List<_LuckCardTier> tiers;
  final List<int> counts;
  final int draws;
  final double totalScore;
  final double expectedScoreTotal;
  final double luckIndex;
  final String luckTitle;
  final int bestStreak;
  final bool goalCompleted;
  final String goalText;
  final String Function(_LuckCardTier tier) tierLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delta = totalScore - expectedScoreTotal;
    final summary = goalCompleted
        ? pickUiText(
            i18n,
            zh: '目标已完成。本轮结果可作为娱乐统计，不代表真实概率会持续偏离期望。',
            en: 'Goal completed. Treat this as entertainment analysis; future draws still follow the configured odds.',
          )
        : pickUiText(
            i18n,
            zh: '当前统计基于本页已完成抽卡。幸运指数以 100 为期望水平，高于 100 表示本轮高于概率期望。',
            en: 'This report uses draws from the current page. Luck index uses 100 as expected; above 100 means this run beat expectation.',
          );
    return AlertDialog(
      title: Text(
        goalCompleted
            ? pickUiText(i18n, zh: '抽卡目标完成', en: 'Draw goal complete')
            : pickUiText(i18n, zh: '运气测试报告', en: 'Luck report'),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '抽数', en: 'Draws'),
                    value: '$draws',
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '幸运指数', en: 'Luck index'),
                    value: luckIndex.toStringAsFixed(0),
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '趣味称号', en: 'Fun title'),
                    value: luckTitle,
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '实际/期望', en: 'Actual/expected'),
                    value:
                        '${totalScore.toStringAsFixed(1)}/${expectedScoreTotal.toStringAsFixed(1)}',
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '最佳连中', en: 'Best streak'),
                    value: '$bestStreak',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ColorVisionReportSection(
                title: pickUiText(i18n, zh: '本轮判断', en: 'Run analysis'),
                child: Text(
                  pickUiText(
                    i18n,
                    zh: '$summary\n目标：$goalText。总幸运值比期望${delta >= 0 ? '高' : '低'} ${delta.abs().toStringAsFixed(1)}。',
                    en: '$summary\nGoal: $goalText. Total luck score is ${delta >= 0 ? 'above' : 'below'} expectation by ${delta.abs().toStringAsFixed(1)}.',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
              ),
              const SizedBox(height: 12),
              _ColorVisionReportSection(
                title: pickUiText(i18n, zh: '卡片分布', en: 'Tier distribution'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List<Widget>.generate(tiers.length, (index) {
                    final tier = tiers[index];
                    final count = counts[index];
                    final ratio = draws <= 0 ? 0.0 : count / draws;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: 92,
                            child: Text(
                              tierLabel(tier),
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                minHeight: 10,
                                value: ratio.clamp(0.0, 1.0),
                                color: tier.color,
                                backgroundColor: tier.color.withValues(
                                  alpha: 0.14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$count'),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(pickUiText(i18n, zh: '关闭', en: 'Close')),
        ),
      ],
    );
  }
}

class CalculationTestPage extends StatelessWidget {
  const CalculationTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '计算能力测试', en: 'Calculation test'),
      subtitle: pickUiText(
        i18n,
        zh: '按难度、题型、题量或限时进行口算训练，完成后查看速度和准确率报告。',
        en: 'Practice arithmetic by difficulty, operation type, round count, or time limit with a final speed and accuracy report.',
      ),
      accent: const Color(0xFF6178B8),
      icon: Icons.calculate_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：输入答案并提交',
        en: 'Next: type answers and submit',
      ),
      child: const _CalculationTestCard(),
    );
  }
}

enum _CalculationDifficulty { easy, standard, hard, expert }

enum _CalculationType { mixed, addSub, multiply, division, twoStep, missing }

enum _CalculationSessionMode { fixedRounds, timed }

class _CalculationProblem {
  const _CalculationProblem({
    required this.prompt,
    required this.answer,
    required this.type,
    required this.difficulty,
  });

  final String prompt;
  final int answer;
  final _CalculationType type;
  final _CalculationDifficulty difficulty;
}

class _CalculationRecord {
  const _CalculationRecord({
    required this.problem,
    required this.userAnswer,
    required this.correct,
    required this.elapsedMs,
  });

  final _CalculationProblem problem;
  final int? userAnswer;
  final bool correct;
  final int elapsedMs;
}

class _CalculationTestCard extends StatefulWidget {
  const _CalculationTestCard();

  @override
  State<_CalculationTestCard> createState() => _CalculationTestCardState();
}

class _CalculationTestCardState extends State<_CalculationTestCard> {
  static const Color _accent = Color(0xFF6178B8);
  final math.Random _random = math.Random();
  final TextEditingController _controller = TextEditingController();

  _CalculationDifficulty _difficulty = _CalculationDifficulty.standard;
  _CalculationType _type = _CalculationType.mixed;
  _CalculationSessionMode _sessionMode = _CalculationSessionMode.fixedRounds;
  int _roundLimit = 12;
  int _timeLimitSeconds = 60;

  _CalculationProblem? _currentProblem;
  final List<_CalculationRecord> _records = <_CalculationRecord>[];
  Timer? _timer;
  DateTime? _sessionStartedAt;
  DateTime? _problemStartedAt;
  int _elapsedSeconds = 0;
  int _score = 0;
  bool _running = false;
  bool _done = false;
  bool? _lastCorrect;
  int? _lastAnswer;
  bool _reportDialogOpen = false;

  int get _attempts => _records.length;

  int get _remainingSeconds => math.max(0, _timeLimitSeconds - _elapsedSeconds);

  bool get _settingsLocked => _running;

  double get _accuracy => _attempts <= 0 ? 0 : _score / _attempts;

  int get _averageMs {
    if (_records.isEmpty) {
      return 0;
    }
    return (_records.fold<int>(0, (sum, record) => sum + record.elapsedMs) /
            _records.length)
        .round();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _records.clear();
      _score = 0;
      _elapsedSeconds = 0;
      _running = true;
      _done = false;
      _lastCorrect = null;
      _lastAnswer = null;
      _sessionStartedAt = DateTime.now();
      _newProblem();
    });
    if (_sessionMode == _CalculationSessionMode.timed) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!_running || !mounted) {
          return;
        }
        final started = _sessionStartedAt;
        if (started == null) {
          return;
        }
        setState(() {
          _elapsedSeconds = DateTime.now().difference(started).inSeconds;
        });
        if (_remainingSeconds <= 0) {
          _finish();
        }
      });
    }
  }

  void _newProblem() {
    _currentProblem = _generateProblem();
    _problemStartedAt = DateTime.now();
    _controller.clear();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _records.clear();
      _currentProblem = null;
      _sessionStartedAt = null;
      _problemStartedAt = null;
      _elapsedSeconds = 0;
      _score = 0;
      _running = false;
      _done = false;
      _lastCorrect = null;
      _lastAnswer = null;
      _controller.clear();
    });
  }

  void _submit() {
    if (!_running || _done || _currentProblem == null) {
      return;
    }
    final value = int.tryParse(_controller.text.trim());
    final problem = _currentProblem!;
    final started = _problemStartedAt ?? DateTime.now();
    final elapsedMs = DateTime.now().difference(started).inMilliseconds;
    final correct = value == problem.answer;
    setState(() {
      if (correct) {
        _score += 1;
      }
      _records.add(
        _CalculationRecord(
          problem: problem,
          userAnswer: value,
          correct: correct,
          elapsedMs: elapsedMs,
        ),
      );
      _lastCorrect = correct;
      _lastAnswer = problem.answer;
    });
    final fixedDone =
        _sessionMode == _CalculationSessionMode.fixedRounds &&
        _records.length >= _roundLimit;
    final timedDone =
        _sessionMode == _CalculationSessionMode.timed && _remainingSeconds <= 0;
    if (fixedDone || timedDone) {
      _finish();
    } else {
      _newProblem();
    }
  }

  void _finish() {
    if (!_running && _done) {
      return;
    }
    _timer?.cancel();
    setState(() {
      _running = false;
      _done = true;
      _currentProblem = null;
      _controller.clear();
    });
    unawaited(_showReport());
  }

  Future<void> _showReport() async {
    if (!mounted || _records.isEmpty || _reportDialogOpen) {
      return;
    }
    _reportDialogOpen = true;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    try {
      await showDialog<void>(
        context: context,
        builder: (context) => _CalculationReportDialog(
          i18n: i18n,
          records: List<_CalculationRecord>.unmodifiable(_records),
          score: _score,
          difficulty: _difficultyLabel(i18n, _difficulty),
          type: _typeLabel(i18n, _type),
          mode: _sessionMode == _CalculationSessionMode.fixedRounds
              ? pickUiText(i18n, zh: '固定题量', en: 'Fixed rounds')
              : pickUiText(i18n, zh: '限时', en: 'Timed'),
        ),
      );
    } finally {
      _reportDialogOpen = false;
    }
  }

  _CalculationProblem _generateProblem() {
    final type = _effectiveType();
    final max = switch (_difficulty) {
      _CalculationDifficulty.easy => 20,
      _CalculationDifficulty.standard => 60,
      _CalculationDifficulty.hard => 120,
      _CalculationDifficulty.expert => 240,
    };
    final multiplierMax = switch (_difficulty) {
      _CalculationDifficulty.easy => 9,
      _CalculationDifficulty.standard => 12,
      _CalculationDifficulty.hard => 18,
      _CalculationDifficulty.expert => 24,
    };

    int next(int min, int upper) => min + _random.nextInt(upper - min + 1);

    switch (type) {
      case _CalculationType.addSub:
        final add = _random.nextBool();
        var a = next(2, max);
        var b = next(2, max);
        if (!add && b > a) {
          final tmp = a;
          a = b;
          b = tmp;
        }
        return _CalculationProblem(
          prompt: add ? '$a + $b = ?' : '$a - $b = ?',
          answer: add ? a + b : a - b,
          type: type,
          difficulty: _difficulty,
        );
      case _CalculationType.multiply:
        final a = next(2, multiplierMax);
        final b = next(2, multiplierMax);
        return _CalculationProblem(
          prompt: '$a x $b = ?',
          answer: a * b,
          type: type,
          difficulty: _difficulty,
        );
      case _CalculationType.division:
        final answer = next(2, multiplierMax);
        final b = next(2, multiplierMax);
        return _CalculationProblem(
          prompt: '${answer * b} ÷ $b = ?',
          answer: answer,
          type: type,
          difficulty: _difficulty,
        );
      case _CalculationType.twoStep:
        final a = next(2, max ~/ 2);
        final b = next(2, max ~/ 2);
        final c = next(2, multiplierMax);
        final pattern = _random.nextInt(3);
        return switch (pattern) {
          0 => _CalculationProblem(
            prompt: '($a + $b) x $c = ?',
            answer: (a + b) * c,
            type: type,
            difficulty: _difficulty,
          ),
          1 => _CalculationProblem(
            prompt: '$a x $c + $b = ?',
            answer: a * c + b,
            type: type,
            difficulty: _difficulty,
          ),
          _ => _CalculationProblem(
            prompt: '$a x $c - $b = ?',
            answer: a * c - b,
            type: type,
            difficulty: _difficulty,
          ),
        };
      case _CalculationType.missing:
        final answer = next(2, max);
        final b = next(2, max ~/ 2);
        final add = _random.nextBool();
        return _CalculationProblem(
          prompt: add ? '? + $b = ${answer + b}' : '? - $b = ${answer - b}',
          answer: answer,
          type: type,
          difficulty: _difficulty,
        );
      case _CalculationType.mixed:
        return _generateProblem();
    }
  }

  _CalculationType _effectiveType() {
    if (_type != _CalculationType.mixed) {
      return _type;
    }
    final pool = switch (_difficulty) {
      _CalculationDifficulty.easy => <_CalculationType>[
        _CalculationType.addSub,
        _CalculationType.multiply,
      ],
      _CalculationDifficulty.standard => <_CalculationType>[
        _CalculationType.addSub,
        _CalculationType.multiply,
        _CalculationType.division,
      ],
      _CalculationDifficulty.hard => <_CalculationType>[
        _CalculationType.addSub,
        _CalculationType.multiply,
        _CalculationType.division,
        _CalculationType.twoStep,
      ],
      _CalculationDifficulty.expert => <_CalculationType>[
        _CalculationType.multiply,
        _CalculationType.division,
        _CalculationType.twoStep,
        _CalculationType.missing,
      ],
    };
    return _sample(_random, pool);
  }

  String _difficultyLabel(AppI18n i18n, _CalculationDifficulty difficulty) {
    return switch (difficulty) {
      _CalculationDifficulty.easy => pickUiText(i18n, zh: '轻量', en: 'Easy'),
      _CalculationDifficulty.standard => pickUiText(
        i18n,
        zh: '标准',
        en: 'Standard',
      ),
      _CalculationDifficulty.hard => pickUiText(i18n, zh: '进阶', en: 'Hard'),
      _CalculationDifficulty.expert => pickUiText(i18n, zh: '专家', en: 'Expert'),
    };
  }

  String _typeLabel(AppI18n i18n, _CalculationType type) {
    return switch (type) {
      _CalculationType.mixed => pickUiText(i18n, zh: '混合', en: 'Mixed'),
      _CalculationType.addSub => pickUiText(i18n, zh: '加减', en: 'Add/Sub'),
      _CalculationType.multiply => pickUiText(i18n, zh: '乘法', en: 'Multiply'),
      _CalculationType.division => pickUiText(i18n, zh: '除法', en: 'Divide'),
      _CalculationType.twoStep => pickUiText(i18n, zh: '两步题', en: 'Two-step'),
      _CalculationType.missing => pickUiText(i18n, zh: '未知数', en: 'Missing'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final theme = Theme.of(context);
    final progressText = _sessionMode == _CalculationSessionMode.fixedRounds
        ? '$_attempts/$_roundLimit'
        : '${_remainingSeconds}s';
    final prompt = _currentProblem?.prompt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (pickUiText(i18n, zh: '进度', en: 'Progress'), progressText),
            (pickUiText(i18n, zh: '正确', en: 'Correct'), '$_score'),
            (
              pickUiText(i18n, zh: '正确率', en: 'Accuracy'),
              _attempts == 0 ? '-' : '${(_accuracy * 100).round()}%',
            ),
            (
              pickUiText(i18n, zh: '平均用时', en: 'Avg time'),
              _records.isEmpty ? '-' : _formatMilliseconds(_averageMs),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                height: 132,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Text(
                  prompt ??
                      (_done
                          ? pickUiText(i18n, zh: '本轮完成', en: 'Session done')
                          : pickUiText(i18n, zh: '准备开始', en: 'Ready')),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (_lastCorrect != null) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  _lastCorrect!
                      ? pickUiText(i18n, zh: '上一题正确', en: 'Last answer correct')
                      : pickUiText(
                          i18n,
                          zh: '上一题答案：$_lastAnswer',
                          en: 'Last answer: $_lastAnswer',
                        ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _lastCorrect! ? _accent : theme.colorScheme.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                enabled: _running,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: pickUiText(i18n, zh: '答案', en: 'Answer'),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _HumanActionButton(
                    label: !_running
                        ? pickUiText(i18n, zh: '开始', en: 'Start')
                        : pickUiText(i18n, zh: '提交', en: 'Submit'),
                    icon: !_running
                        ? Icons.play_arrow_rounded
                        : Icons.check_rounded,
                    onPressed: !_running ? _start : _submit,
                  ),
                  OutlinedButton.icon(
                    onPressed: _records.isEmpty
                        ? null
                        : () => unawaited(_showReport()),
                    icon: const Icon(Icons.analytics_rounded),
                    label: Text(pickUiText(i18n, zh: '查看报告', en: 'Report')),
                  ),
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _HumanSettingsSection(
                title: pickUiText(i18n, zh: '计算设置', en: 'Calculation settings'),
                subtitle: pickUiText(
                  i18n,
                  zh: '选择难度、题型和结束条件',
                  en: 'Choose difficulty, operation type, and completion rule',
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pickUiText(i18n, zh: '难度', en: 'Difficulty'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _CalculationDifficulty.values
                          .map(
                            (difficulty) => ChoiceChip(
                              label: Text(_difficultyLabel(i18n, difficulty)),
                              selected: _difficulty == difficulty,
                              onSelected: _settingsLocked
                                  ? null
                                  : (_) => setState(
                                      () => _difficulty = difficulty,
                                    ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      pickUiText(i18n, zh: '题型', en: 'Operation type'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _CalculationType.values
                          .map(
                            (type) => ChoiceChip(
                              label: Text(_typeLabel(i18n, type)),
                              selected: _type == type,
                              onSelected: _settingsLocked
                                  ? null
                                  : (_) => setState(() => _type = type),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      pickUiText(i18n, zh: '模式', en: 'Mode'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _CalculationSessionMode.values
                          .map(
                            (mode) => ChoiceChip(
                              label: Text(
                                mode == _CalculationSessionMode.fixedRounds
                                    ? pickUiText(i18n, zh: '固定题量', en: 'Fixed')
                                    : pickUiText(i18n, zh: '限时', en: 'Timed'),
                              ),
                              selected: _sessionMode == mode,
                              onSelected: _settingsLocked
                                  ? null
                                  : (_) => setState(() => _sessionMode = mode),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    if (_sessionMode == _CalculationSessionMode.fixedRounds)
                      _LuckSettingSlider(
                        label: pickUiText(i18n, zh: '题目数量', en: 'Round count'),
                        valueText: '$_roundLimit',
                        value: _roundLimit.toDouble(),
                        min: 5,
                        max: 40,
                        divisions: 7,
                        onChanged: _settingsLocked
                            ? (_) {}
                            : (value) =>
                                  setState(() => _roundLimit = value.round()),
                      )
                    else
                      _LuckSettingSlider(
                        label: pickUiText(i18n, zh: '限时秒数', en: 'Time limit'),
                        valueText: '$_timeLimitSeconds s',
                        value: _timeLimitSeconds.toDouble(),
                        min: 20,
                        max: 180,
                        divisions: 16,
                        onChanged: _settingsLocked
                            ? (_) {}
                            : (value) => setState(
                                () => _timeLimitSeconds = value.round(),
                              ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalculationReportDialog extends StatelessWidget {
  const _CalculationReportDialog({
    required this.i18n,
    required this.records,
    required this.score,
    required this.difficulty,
    required this.type,
    required this.mode,
  });

  final AppI18n i18n;
  final List<_CalculationRecord> records;
  final int score;
  final String difficulty;
  final String type;
  final String mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attempts = records.length;
    final accuracy = attempts <= 0 ? 0.0 : score / attempts;
    final averageMs = attempts <= 0
        ? 0
        : (records.fold<int>(0, (sum, record) => sum + record.elapsedMs) /
                  attempts)
              .round();
    final fastest = records.isEmpty
        ? 0
        : records.map((record) => record.elapsedMs).reduce(math.min);
    final wrong = records.where((record) => !record.correct).toList();
    final recommendation = accuracy >= 0.9
        ? pickUiText(
            i18n,
            zh: '准确率稳定，可以提高难度或切换到限时模式。',
            en: 'Accuracy is stable. Raise the difficulty or switch to timed mode.',
          )
        : averageMs > 6500
        ? pickUiText(
            i18n,
            zh: '先降低速度压力，保留当前难度练习口算路径。',
            en: 'Reduce time pressure and keep this difficulty until the arithmetic path feels automatic.',
          )
        : pickUiText(
            i18n,
            zh: '错误主要来自判断而不是速度，建议先做单一题型专项练习。',
            en: 'Errors look more judgment-based than speed-based. Practice one operation type at a time.',
          );
    return AlertDialog(
      title: Text(pickUiText(i18n, zh: '计算能力报告', en: 'Calculation report')),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '正确率', en: 'Accuracy'),
                    value: '${(accuracy * 100).round()}%',
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '正确/题数', en: 'Correct/total'),
                    value: '$score/$attempts',
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '平均用时', en: 'Avg time'),
                    value: _formatMilliseconds(averageMs),
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '最快', en: 'Fastest'),
                    value: _formatMilliseconds(fastest),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ColorVisionReportSection(
                title: pickUiText(i18n, zh: '本轮设置', en: 'Session settings'),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    Chip(label: Text(difficulty)),
                    Chip(label: Text(type)),
                    Chip(label: Text(mode)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ColorVisionReportSection(
                title: pickUiText(i18n, zh: '训练建议', en: 'Training note'),
                child: Text(
                  recommendation,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
              ),
              if (wrong.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _ColorVisionReportSection(
                  title: pickUiText(i18n, zh: '错题回看', en: 'Missed prompts'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: wrong
                        .take(5)
                        .map((record) {
                          return Text(
                            '${record.problem.prompt.replaceAll('?', record.problem.answer.toString())} · ${pickUiText(i18n, zh: '你的答案', en: 'Your answer')}: ${record.userAnswer ?? '-'}',
                            style: theme.textTheme.bodySmall,
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(pickUiText(i18n, zh: '关闭', en: 'Close')),
        ),
      ],
    );
  }
}

class SustainedAttentionTestPage extends StatelessWidget {
  const SustainedAttentionTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '持续注意力测试', en: 'Sustained attention'),
      subtitle: pickUiText(
        i18n,
        zh: '支持目标点击、低频目标和 n-back 任务，统计命中、漏点、误点和反应时。',
        en: 'Go/no-go, oddball, and n-back attention tasks with hit, miss, false-alarm, and reaction-time stats.',
      ),
      accent: const Color(0xFF6D8657),
      icon: Icons.track_changes_rounded,
      status: pickUiText(i18n, zh: '下一步：看到 X 才点击', en: 'Next: tap only on X'),
      child: const _SustainedAttentionCard(),
    );
  }
}

enum _AttentionMode { goNoGo, oddball, nBack }

enum _AttentionPace { calm, standard, fast }

class _AttentionRecord {
  const _AttentionRecord({
    required this.index,
    required this.symbol,
    required this.target,
    required this.tapped,
    required this.reactionMs,
  });

  final int index;
  final String symbol;
  final bool target;
  final bool tapped;
  final int? reactionMs;
}

class _SustainedAttentionCard extends StatefulWidget {
  const _SustainedAttentionCard();

  @override
  State<_SustainedAttentionCard> createState() =>
      _SustainedAttentionCardState();
}

class _SustainedAttentionCardState extends State<_SustainedAttentionCard> {
  static const Color _accent = Color(0xFF6D8657);
  final math.Random _random = math.Random();
  Timer? _timer;
  _AttentionMode _mode = _AttentionMode.goNoGo;
  _AttentionPace _pace = _AttentionPace.standard;
  int _stimulusCount = 40;
  int _targetProbability = 24;
  int _nBack = 1;
  int _step = 0;
  int _hits = 0;
  int _misses = 0;
  int _falseAlarms = 0;
  int _correctRejects = 0;
  int _tapFeedbackSerial = 0;
  String _current = '-';
  bool _running = false;
  bool _target = false;
  bool _tappedThisStimulus = false;
  bool _highlightTargets = false;
  bool? _tapFeedbackCorrect;
  DateTime? _stimulusStartedAt;
  final List<String> _sequence = <String>[];
  final List<_AttentionRecord> _records = <_AttentionRecord>[];
  bool _reportDialogOpen = false;

  int get _paceMs => switch (_pace) {
    _AttentionPace.calm => 1100,
    _AttentionPace.standard => 820,
    _AttentionPace.fast => 620,
  };

  int get _targets => _records.where((record) => record.target).length;

  double get _hitRate => _targets <= 0 ? 0 : _hits / _targets;

  int get _averageReactionMs {
    final times = _records
        .where((record) => record.reactionMs != null)
        .map((record) => record.reactionMs!)
        .toList(growable: false);
    if (times.isEmpty) {
      return 0;
    }
    return (times.fold<int>(0, (sum, value) => sum + value) / times.length)
        .round();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _step = 0;
      _hits = 0;
      _misses = 0;
      _falseAlarms = 0;
      _correctRejects = 0;
      _running = true;
      _current = '-';
      _target = false;
      _tappedThisStimulus = false;
      _tapFeedbackSerial = 0;
      _tapFeedbackCorrect = null;
      _stimulusStartedAt = null;
      _sequence.clear();
      _records.clear();
    });
    _advance();
    _timer = Timer.periodic(Duration(milliseconds: _paceMs), (_) => _advance());
  }

  void _stop() {
    _timer?.cancel();
    _finalizeCurrentStimulus();
    setState(() => _running = false);
    unawaited(_showReport());
  }

  void _advance() {
    if (!mounted || !_running) {
      return;
    }
    _finalizeCurrentStimulus();
    if (_step >= _stimulusCount) {
      _stop();
      return;
    }
    final next = _nextStimulus();
    setState(() {
      _step += 1;
      _current = next.$1;
      _target = next.$2;
      _sequence.add(_current);
      _tappedThisStimulus = false;
      _tapFeedbackCorrect = null;
      _stimulusStartedAt = DateTime.now();
    });
  }

  (String, bool) _nextStimulus() {
    final letters = switch (_mode) {
      _AttentionMode.goNoGo => <String>['A', 'H', 'K', 'M', 'N', 'S', 'T', 'Y'],
      _AttentionMode.oddball => <String>['O', 'Q', 'C', 'G', 'D', 'U'],
      _AttentionMode.nBack => <String>['A', 'B', 'C', 'D', 'E', 'F'],
    };
    if (_mode == _AttentionMode.nBack && _sequence.length >= _nBack) {
      final makeTarget = _random.nextInt(100) < _targetProbability;
      if (makeTarget) {
        return (_sequence[_sequence.length - _nBack], true);
      }
      var symbol = _sample(_random, letters);
      var guard = 0;
      while (symbol == _sequence[_sequence.length - _nBack] && guard < 12) {
        guard += 1;
        symbol = _sample(_random, letters);
      }
      return (symbol, false);
    }
    final target = _random.nextInt(100) < _targetProbability;
    if (_mode == _AttentionMode.oddball) {
      return (target ? 'X' : _sample(_random, letters), target);
    }
    return (target ? 'X' : _sample(_random, letters), target);
  }

  void _finalizeCurrentStimulus() {
    if (_step <= 0 || _current == '-') {
      return;
    }
    if (_target && !_tappedThisStimulus) {
      _misses += 1;
    } else if (!_target && !_tappedThisStimulus) {
      _correctRejects += 1;
    }
    _records.add(
      _AttentionRecord(
        index: _step,
        symbol: _current,
        target: _target,
        tapped: _tappedThisStimulus,
        reactionMs: null,
      ),
    );
    _current = '-';
  }

  void _tap() {
    if (!_running) {
      return;
    }
    if (_tappedThisStimulus) {
      _showTapFeedback(correct: null);
      return;
    }
    final started = _stimulusStartedAt ?? DateTime.now();
    final reactionMs = DateTime.now().difference(started).inMilliseconds;
    final correctTap = _target;
    setState(() {
      if (_target && !_tappedThisStimulus) {
        _hits += 1;
        _tappedThisStimulus = true;
        _records.add(
          _AttentionRecord(
            index: _step,
            symbol: _current,
            target: true,
            tapped: true,
            reactionMs: reactionMs,
          ),
        );
        _current = '-';
      } else {
        _falseAlarms += 1;
        _tappedThisStimulus = true;
        _records.add(
          _AttentionRecord(
            index: _step,
            symbol: _current,
            target: false,
            tapped: true,
            reactionMs: reactionMs,
          ),
        );
        _current = '-';
      }
      _tapFeedbackCorrect = correctTap;
      _tapFeedbackSerial += 1;
    });
  }

  void _showTapFeedback({required bool? correct}) {
    final serial = _tapFeedbackSerial + 1;
    setState(() {
      _tapFeedbackCorrect = correct;
      _tapFeedbackSerial = serial;
    });
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (!mounted || _tapFeedbackSerial != serial) {
        return;
      }
      setState(() => _tapFeedbackCorrect = null);
    });
  }

  Future<void> _showReport() async {
    if (!mounted || _records.isEmpty || _reportDialogOpen) {
      return;
    }
    _reportDialogOpen = true;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    try {
      await showDialog<void>(
        context: context,
        builder: (context) => _AttentionReportDialog(
          i18n: i18n,
          mode: _modeLabel(i18n, _mode),
          pace: _paceLabel(i18n, _pace),
          records: List<_AttentionRecord>.unmodifiable(_records),
          hits: _hits,
          misses: _misses,
          falseAlarms: _falseAlarms,
          correctRejects: _correctRejects,
        ),
      );
    } finally {
      _reportDialogOpen = false;
    }
  }

  String _modeLabel(AppI18n i18n, _AttentionMode mode) {
    return switch (mode) {
      _AttentionMode.goNoGo => pickUiText(i18n, zh: '目标点击', en: 'Go/No-go'),
      _AttentionMode.oddball => pickUiText(i18n, zh: '低频目标', en: 'Oddball'),
      _AttentionMode.nBack => pickUiText(i18n, zh: 'n-back', en: 'n-back'),
    };
  }

  String _paceLabel(AppI18n i18n, _AttentionPace pace) {
    return switch (pace) {
      _AttentionPace.calm => pickUiText(i18n, zh: '平缓', en: 'Calm'),
      _AttentionPace.standard => pickUiText(i18n, zh: '标准', en: 'Standard'),
      _AttentionPace.fast => pickUiText(i18n, zh: '快速', en: 'Fast'),
    };
  }

  String _instruction(AppI18n i18n) {
    return switch (_mode) {
      _AttentionMode.goNoGo => pickUiText(
        i18n,
        zh: '只在 X 出现时点击。',
        en: 'Tap only when X appears.',
      ),
      _AttentionMode.oddball => pickUiText(
        i18n,
        zh: '只点击低频出现的 X，忽略相近干扰字符。',
        en: 'Tap the rare X and ignore similar distractors.',
      ),
      _AttentionMode.nBack => pickUiText(
        i18n,
        zh: '当前字符与前 $_nBack 个字符相同时点击。',
        en: 'Tap when the current symbol matches the one $_nBack step(s) back.',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(i18n, zh: '进度', en: 'Progress'),
              '$_step/$_stimulusCount',
            ),
            (pickUiText(i18n, zh: '命中', en: 'Hits'), '$_hits'),
            (pickUiText(i18n, zh: '漏点', en: 'Misses'), '$_misses'),
            (pickUiText(i18n, zh: '误点', en: 'False taps'), '$_falseAlarms'),
            (
              pickUiText(i18n, zh: '平均反应', en: 'Avg reaction'),
              _averageReactionMs == 0
                  ? '-'
                  : _formatMilliseconds(_averageReactionMs),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _running ? _tap : _start,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 240,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: _target && _highlightTargets
                      ? const Color(0xFF6D8657).withValues(alpha: 0.18)
                      : Theme.of(context).colorScheme.surfaceContainerLow,
                  border: Border.all(
                    color: const Color(0xFF6D8657).withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  _running
                      ? (_current == '-' ? '' : _current)
                      : pickUiText(i18n, zh: '点击开始', en: 'Tap to start'),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (_tapFeedbackCorrect != null || _tapFeedbackSerial > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey<int>(_tapFeedbackSerial),
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        final correct = _tapFeedbackCorrect;
                        final color = correct == null
                            ? theme.colorScheme.outline
                            : correct
                            ? const Color(0xFF3D8B63)
                            : theme.colorScheme.error;
                        return Center(
                          child: Opacity(
                            opacity: (1 - value).clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 0.72 + value * 0.55,
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color.withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.72),
                                    width: 2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  correct == null
                                      ? Icons.do_not_disturb_on_rounded
                                      : correct
                                      ? Icons.check_rounded
                                      : Icons.close_rounded,
                                  color: color,
                                  size: 42,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _instruction(i18n),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _HumanActionButton(
              label: _running
                  ? pickUiText(i18n, zh: '点击目标', en: 'Tap target')
                  : pickUiText(i18n, zh: '开始', en: 'Start'),
              icon: _running
                  ? Icons.ads_click_rounded
                  : Icons.play_arrow_rounded,
              onPressed: _running ? _tap : _start,
            ),
            OutlinedButton.icon(
              onPressed: _running ? _stop : null,
              icon: const Icon(Icons.stop_rounded),
              label: Text(pickUiText(i18n, zh: '结束', en: 'Stop')),
            ),
            OutlinedButton.icon(
              onPressed: _records.isEmpty
                  ? null
                  : () => unawaited(_showReport()),
              icon: const Icon(Icons.analytics_rounded),
              label: Text(pickUiText(i18n, zh: '查看报告', en: 'Report')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: _HumanSettingsSection(
            title: pickUiText(i18n, zh: '注意力设置', en: 'Attention settings'),
            subtitle: pickUiText(
              i18n,
              zh: '选择任务、刺激速度、目标比例和总轮次',
              en: 'Choose task, pace, target ratio, and total stimuli',
            ),
            initiallyExpanded: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  pickUiText(i18n, zh: '任务模式', en: 'Task mode'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _AttentionMode.values
                      .map(
                        (mode) => ChoiceChip(
                          label: Text(_modeLabel(i18n, mode)),
                          selected: _mode == mode,
                          onSelected: _running
                              ? null
                              : (_) => setState(() => _mode = mode),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 12),
                Text(
                  pickUiText(i18n, zh: '节奏', en: 'Pace'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _AttentionPace.values
                      .map(
                        (pace) => ChoiceChip(
                          label: Text(_paceLabel(i18n, pace)),
                          selected: _pace == pace,
                          onSelected: _running
                              ? null
                              : (_) => setState(() => _pace = pace),
                        ),
                      )
                      .toList(growable: false),
                ),
                _LuckSettingSlider(
                  label: pickUiText(i18n, zh: '刺激数量', en: 'Stimuli'),
                  valueText: '$_stimulusCount',
                  value: _stimulusCount.toDouble(),
                  min: 20,
                  max: 100,
                  divisions: 8,
                  onChanged: _running
                      ? (_) {}
                      : (value) =>
                            setState(() => _stimulusCount = value.round()),
                ),
                _LuckSettingSlider(
                  label: pickUiText(i18n, zh: '目标比例', en: 'Target ratio'),
                  valueText: '$_targetProbability%',
                  value: _targetProbability.toDouble(),
                  min: 10,
                  max: 45,
                  divisions: 7,
                  onChanged: _running
                      ? (_) {}
                      : (value) =>
                            setState(() => _targetProbability = value.round()),
                ),
                if (_mode == _AttentionMode.nBack)
                  _LuckSettingSlider(
                    label: pickUiText(i18n, zh: 'n-back 间隔', en: 'n-back span'),
                    valueText: '$_nBack',
                    value: _nBack.toDouble(),
                    min: 1,
                    max: 3,
                    divisions: 2,
                    onChanged: _running
                        ? (_) {}
                        : (value) => setState(() => _nBack = value.round()),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    pickUiText(
                      i18n,
                      zh: '目标背景高亮',
                      en: 'Highlight target background',
                    ),
                  ),
                  subtitle: Text(
                    pickUiText(
                      i18n,
                      zh: '默认关闭；开启后目标出现时舞台会轻微变色，适合练习阶段。',
                      en: 'Off by default. When on, targets tint the stage for practice.',
                    ),
                  ),
                  value: _highlightTargets,
                  onChanged: _running
                      ? null
                      : (value) => setState(() => _highlightTargets = value),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AttentionReportDialog extends StatelessWidget {
  const _AttentionReportDialog({
    required this.i18n,
    required this.mode,
    required this.pace,
    required this.records,
    required this.hits,
    required this.misses,
    required this.falseAlarms,
    required this.correctRejects,
  });

  final AppI18n i18n;
  final String mode;
  final String pace;
  final List<_AttentionRecord> records;
  final int hits;
  final int misses;
  final int falseAlarms;
  final int correctRejects;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targets = records.where((record) => record.target).length;
    final hitRate = targets <= 0 ? 0.0 : hits / targets;
    final falseRate = records.isEmpty ? 0.0 : falseAlarms / records.length;
    final reactionTimes = records
        .where((record) => record.reactionMs != null)
        .map((record) => record.reactionMs!)
        .toList(growable: false);
    final avgReaction = reactionTimes.isEmpty
        ? 0
        : (reactionTimes.fold<int>(0, (sum, value) => sum + value) /
                  reactionTimes.length)
              .round();
    final recommendation = hitRate >= 0.85 && falseRate <= 0.08
        ? pickUiText(
            i18n,
            zh: '命中稳定且误点较少，可以提高节奏或改用 n-back。',
            en: 'Hits are stable and false alarms are low. Increase pace or switch to n-back.',
          )
        : falseAlarms > misses
        ? pickUiText(
            i18n,
            zh: '当前更容易冲动点击，建议降低速度并提高只在目标出现时才动作的抑制感。',
            en: 'False alarms dominate. Slow down and practice response inhibition.',
          )
        : pickUiText(
            i18n,
            zh: '漏点偏多，建议先使用平缓节奏和更高目标比例建立搜索节奏。',
            en: 'Misses are high. Start with calm pace and a higher target ratio to build the search rhythm.',
          );
    return AlertDialog(
      title: Text(pickUiText(i18n, zh: '持续注意力报告', en: 'Attention report')),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '命中率', en: 'Hit rate'),
                    value: '${(hitRate * 100).round()}%',
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '平均反应', en: 'Avg reaction'),
                    value: avgReaction == 0
                        ? '-'
                        : _formatMilliseconds(avgReaction),
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '漏点', en: 'Misses'),
                    value: '$misses',
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '误点', en: 'False taps'),
                    value: '$falseAlarms',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ColorVisionReportSection(
                title: pickUiText(i18n, zh: '本轮设置', en: 'Session settings'),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    Chip(label: Text(mode)),
                    Chip(label: Text(pace)),
                    Chip(label: Text('${records.length} stimuli')),
                    Chip(label: Text('$correctRejects correct rejects')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ColorVisionReportSection(
                title: pickUiText(i18n, zh: '训练建议', en: 'Training note'),
                child: Text(
                  recommendation,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(pickUiText(i18n, zh: '关闭', en: 'Close')),
        ),
      ],
    );
  }
}

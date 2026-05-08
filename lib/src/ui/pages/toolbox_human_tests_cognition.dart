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

class _ScratchTicketStubChip extends StatelessWidget {
  const _ScratchTicketStubChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFF8F0DE),
        border: Border.all(color: const Color(0x2EB78328)),
      ),
      child: Text(
        '$label $value',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: const Color(0xFF76551A),
          fontWeight: FontWeight.w800,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _ScratchBarcodeStrip extends StatelessWidget {
  const _ScratchBarcodeStrip({required this.digits, required this.seed});

  final String digits;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: 38,
          child: CustomPaint(painter: _ScratchBarcodePainter(seed: seed)),
        ),
        const SizedBox(height: 3),
        Text(
          digits,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: const Color(0xFF5E5A52),
            letterSpacing: 0,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _ScratchBarcodePainter extends CustomPainter {
  const _ScratchBarcodePainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed & 0x7fffffff);
    final paint = Paint()..color = const Color(0xFF2F3135);
    var x = 0.0;
    while (x < size.width) {
      final width = 1.0 + random.nextInt(3).toDouble();
      final gap = 1.0 + random.nextInt(2).toDouble();
      final heightFactor = 0.78 + random.nextDouble() * 0.22;
      canvas.drawRect(
        Rect.fromLTWH(x, size.height * (1 - heightFactor), width, size.height),
        paint,
      );
      x += width + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _ScratchBarcodePainter oldDelegate) {
    return oldDelegate.seed != seed;
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
      _lives = 3;
      _records.clear();
      _next();
    });
  }

  void _setColorCount(int count) {
    setState(() {
      _colorCount = count;
      _score = 0;
      _lives = 3;
      _records.clear();
      _next();
    });
  }

  void _setMode(_StroopMode mode) {
    setState(() {
      _mode = mode;
      _score = 0;
      _lives = 3;
      _records.clear();
      _next();
    });
  }

  void _setRoundLimit(int value) {
    setState(() {
      _roundLimit = value;
      _score = 0;
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

class LuckTestPage extends StatefulWidget {
  const LuckTestPage({super.key});

  @override
  State<LuckTestPage> createState() => _LuckTestPageState();
}

enum _LuckTestModule { draw, scratch }

class _LuckTestPageState extends State<LuckTestPage> {
  _LuckTestModule _module = _LuckTestModule.draw;

  void _setModule(_LuckTestModule module) {
    if (_module == module) {
      return;
    }
    setState(() => _module = module);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '运气测试', en: 'Luck test'),
      subtitle: pickUiText(
        i18n,
        zh: '支持抽卡和独立刮刮乐两种子模块，并提供自定义概率与结果报告。',
        en: 'Draw cards or play a standalone scratch-off mode with custom odds and reports.',
      ),
      accent: const Color(0xFFD0923A),
      icon: Icons.casino_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：选择运气子模块',
        en: 'Next: choose a luck module',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ChoiceChip(
                key: const ValueKey<String>('luck-module-draw'),
                label: Text(pickUiText(i18n, zh: '抽卡', en: 'Draw cards')),
                selected: _module == _LuckTestModule.draw,
                onSelected: (_) => _setModule(_LuckTestModule.draw),
              ),
              ChoiceChip(
                key: const ValueKey<String>('luck-module-scratch'),
                label: Text(pickUiText(i18n, zh: '刮刮乐', en: 'Scratch')),
                selected: _module == _LuckTestModule.scratch,
                onSelected: (_) => _setModule(_LuckTestModule.scratch),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _module == _LuckTestModule.draw
                ? const _LuckTestCard(key: ValueKey<String>('luck-draw-module'))
                : const _LuckScratchTestCard(
                    key: ValueKey<String>('luck-scratch-module'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LuckTestCard extends StatefulWidget {
  const _LuckTestCard({super.key});

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
  final List<_LuckCardTier> _rareEffectQueue = <_LuckCardTier>[];
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
  bool _rareEffectPlaying = false;
  int _lastBatchPointerIndex = -1;
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
    _rareEffectQueue.clear();
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
    _rareEffectQueue.add(tier);
    _playNextRareEffect();
  }

  void _playNextRareEffect() {
    if (_rareEffectPlaying ||
        _rareEffectQueue.isEmpty ||
        !mounted ||
        !_rareEffectEnabled) {
      return;
    }
    final tier = _rareEffectQueue.removeAt(0);
    _rareEffectPlaying = true;
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
      _rareEffectPlaying = false;
      _playNextRareEffect();
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
    final showShuffle = _batchCards.isEmpty;
    setState(() {
      _shuffling = showShuffle;
      _selectedCard = -1;
      _revealedTier = null;
      _lastBatch.clear();
      _batchCards.clear();
      _batchRevealed.clear();
      _lastBatchPointerIndex = -1;
    });
    if (showShuffle) {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted || token != _flipToken) {
        return;
      }
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

  void _revealBatchCardFromGesture(int index) {
    if (_shuffling ||
        index < 0 ||
        index >= _batchCards.length ||
        _batchRevealed[index] ||
        index == _lastBatchPointerIndex) {
      return;
    }
    _lastBatchPointerIndex = index;
    unawaited(_revealBatchCard(index));
  }

  void _handleBatchPan(Offset localPosition, double maxWidth) {
    if (_batchCards.isEmpty || !_batchActive || maxWidth <= 0) {
      return;
    }
    final layout = _batchGridLayout(maxWidth, _batchCards.length);
    final col = (localPosition.dx / layout.cellWidth).floor();
    final row = (localPosition.dy / layout.cellHeight).floor();
    if (col < 0 || col >= layout.columns || row < 0 || row >= layout.rows) {
      return;
    }
    final index = row * layout.columns + col;
    if (index >= _batchCards.length) {
      return;
    }
    _revealBatchCardFromGesture(index);
  }

  ({int columns, int rows, double cellWidth, double cellHeight})
  _batchGridLayout(double maxWidth, int count) {
    final columns = maxWidth < 420 ? 5 : 6;
    final rows = (count / columns).ceil();
    return (
      columns: columns,
      rows: rows,
      cellWidth: maxWidth / columns,
      cellHeight: maxWidth < 420 ? 92.0 : 112.0,
    );
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
    _rareEffectQueue.clear();
    _rareEffectPlaying = false;
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
      _lastBatchPointerIndex = -1;
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
      _lastBatchPointerIndex = -1;
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
        '$_goalLuckIndex ${pickUiText(i18n, zh: '点', en: 'pts')}',
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

  Widget _buildCardFront(
    BuildContext context,
    int cardNo, {
    bool compact = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: compact ? 86 : 132,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
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
                fontSize: compact ? 10 : null,
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
                fontSize: compact ? 10 : null,
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white.withValues(alpha: 0.90),
              size: compact ? 22 : 30,
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
    _LuckCardTier tier, {
    bool compact = false,
  }) {
    final title = _tierLabel(i18n, tier);
    return Container(
      height: compact ? 86 : 132,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
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
                fontSize: compact ? 10 : null,
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
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (compact
                              ? Theme.of(context).textTheme.labelMedium
                              : Theme.of(context).textTheme.titleMedium)
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                ),
                if (!compact) ...<Widget>[
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
                ] else
                  Text(
                    '+${tier.score}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w900,
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

  Widget _buildBatchCard(
    BuildContext context,
    AppI18n i18n,
    int index, {
    bool compact = false,
  }) {
    final revealed = _batchRevealed[index];
    final tier = _batchCards[index];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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
              width: compact ? double.infinity : 88,
              child: showBack
                  ? _buildCardBack(
                      context,
                      i18n,
                      index + 1,
                      tier,
                      compact: compact,
                    )
                  : _buildCardFront(context, index + 1, compact: compact),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBatchGrid(BuildContext context, AppI18n i18n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _batchGridLayout(
          constraints.maxWidth,
          _batchCards.length,
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            _lastBatchPointerIndex = -1;
            _handleBatchPan(details.localPosition, constraints.maxWidth);
          },
          onPanUpdate: (details) {
            _handleBatchPan(details.localPosition, constraints.maxWidth);
          },
          onPanEnd: (_) => _lastBatchPointerIndex = -1,
          onPanCancel: () => _lastBatchPointerIndex = -1,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _batchCards.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: layout.columns,
              mainAxisExtent: layout.cellHeight,
              mainAxisSpacing: 7,
              crossAxisSpacing: 7,
            ),
            itemBuilder: (context, index) => _buildBatchCard(
              context,
              i18n,
              index,
              compact: constraints.maxWidth < 420,
            ),
          ),
        );
      },
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
                      _buildBatchGrid(context, i18n),
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
                    key: const ValueKey<String>('luck-primary-draw-button'),
                    label: pickUiText(
                      i18n,
                      zh: '${_drawModeLabel(i18n, _drawMode)}抽卡',
                      en: _drawMode == _LuckDrawMode.single
                          ? 'Single draw'
                          : '$_drawCountForMode draws',
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
                        pickUiText(i18n, zh: '翻卡特效', en: 'Flip card effects'),
                      ),
                      subtitle: Text(
                        pickUiText(
                          i18n,
                          zh: '史诗和传说翻卡时会显示短暂全屏闪光。',
                          en: 'Legendary and Epic flips show a brief full-screen flash.',
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

class _LuckScratchCell {
  const _LuckScratchCell({
    required this.tierKey,
    required this.number,
    required this.displayPrize,
    required this.amount,
    required this.isWinning,
    required this.multiplier,
    required this.isAutoWin,
    required this.validationCode,
  });

  final String tierKey;
  final int number;
  final int displayPrize;
  final int amount;
  final bool isWinning;
  final int multiplier;
  final bool isAutoWin;
  final String validationCode;
}

class _LuckScratchPrizeTier {
  const _LuckScratchPrizeTier({
    required this.key,
    required this.zhLabel,
    required this.enLabel,
    required this.weight,
    required this.baseAmount,
    required this.minAmount,
    required this.maxAmount,
    required this.roundTo,
    this.isJackpot = false,
  });

  final String key;
  final String zhLabel;
  final String enLabel;
  final double weight;
  final int baseAmount;
  final int minAmount;
  final int maxAmount;
  final int roundTo;
  final bool isJackpot;

  int sampleAmount(math.Random random, double priceScale) {
    final minValue = math.max(0, (minAmount * priceScale).round());
    final maxValue = math.max(minValue, (maxAmount * priceScale).round());
    final spread = maxValue - minValue;
    final rawValue = spread <= 0
        ? maxValue
        : minValue + random.nextInt(spread + 1);
    final scaledRound = math.max(1, (roundTo * priceScale).round());
    return _roundToNearest(rawValue, scaledRound);
  }
}

enum _LuckScratchFoilStyle { metal, starfield, ripple, confetti }

class _LuckScratchSettingsSnapshot {
  const _LuckScratchSettingsSnapshot({
    required this.ticketPrice,
    required this.cellCount,
    required this.overallProbabilityCorrection,
    required this.customProbabilityCorrection,
    required this.revealSteps,
    required this.showAmount,
    required this.showResultBadge,
    required this.celebrationEnabled,
    required this.foilStyle,
  });

  final int ticketPrice;
  final int cellCount;
  final double overallProbabilityCorrection;
  final double customProbabilityCorrection;
  final int revealSteps;
  final bool showAmount;
  final bool showResultBadge;
  final bool celebrationEnabled;
  final _LuckScratchFoilStyle foilStyle;
}

int _roundToNearest(int value, int roundTo) {
  if (roundTo <= 1) {
    return value;
  }
  return (value / roundTo).round() * roundTo;
}

class _LuckScratchMark {
  const _LuckScratchMark({
    required this.center,
    required this.angle,
    required this.length,
    required this.width,
  });

  final Offset center;
  final double angle;
  final double length;
  final double width;
}

class _LuckScratchTestCard extends StatefulWidget {
  const _LuckScratchTestCard({super.key});

  @override
  State<_LuckScratchTestCard> createState() => _LuckScratchTestCardState();
}

class _LuckScratchTestCardState extends State<_LuckScratchTestCard> {
  static const Color _accent = Color(0xFFD0923A);
  static const int _defaultTicketPrice = 10;
  static const int _defaultCellCount = 8;
  static const double _defaultOverallProbabilityCorrection = 1.0;
  static const double _defaultCustomProbabilityCorrection = 1.0;
  static const int _defaultRevealSteps = 4;
  static const bool _defaultShowAmount = true;
  static const bool _defaultShowResultBadge = false;
  static const bool _defaultCelebrationEnabled = true;
  static const _LuckScratchFoilStyle _defaultFoilStyle =
      _LuckScratchFoilStyle.metal;
  static const _LuckScratchSettingsSnapshot _defaultScratchSettings =
      _LuckScratchSettingsSnapshot(
        ticketPrice: _defaultTicketPrice,
        cellCount: _defaultCellCount,
        overallProbabilityCorrection: _defaultOverallProbabilityCorrection,
        customProbabilityCorrection: _defaultCustomProbabilityCorrection,
        revealSteps: _defaultRevealSteps,
        showAmount: _defaultShowAmount,
        showResultBadge: _defaultShowResultBadge,
        celebrationEnabled: _defaultCelebrationEnabled,
        foilStyle: _defaultFoilStyle,
      );
  static const double _baseOverallOdds = 3.45;
  static const double _scratchRevealThreshold = 0.62;
  static const double _scratchPromptThreshold = 0.38;
  static const double _scratchCompleteThreshold = 0.96;
  static const List<int> _ticketPriceOptions = <int>[2, 5, 10, 20, 50];
  static const List<_LuckScratchPrizeTier> _prizeTierTemplates =
      <_LuckScratchPrizeTier>[
        _LuckScratchPrizeTier(
          key: 'special',
          zhLabel: '特等奖',
          enLabel: 'Grand prize',
          weight: 0.001,
          baseAmount: 250000,
          minAmount: 200000,
          maxAmount: 500000,
          roundTo: 10000,
          isJackpot: true,
        ),
        _LuckScratchPrizeTier(
          key: 'first',
          zhLabel: '一等奖',
          enLabel: 'First prize',
          weight: 0.007,
          baseAmount: 50000,
          minAmount: 30000,
          maxAmount: 100000,
          roundTo: 5000,
          isJackpot: true,
        ),
        _LuckScratchPrizeTier(
          key: 'second',
          zhLabel: '二等奖',
          enLabel: 'Second prize',
          weight: 0.05,
          baseAmount: 10000,
          minAmount: 6000,
          maxAmount: 18000,
          roundTo: 1000,
        ),
        _LuckScratchPrizeTier(
          key: 'third',
          zhLabel: '三等奖',
          enLabel: 'Third prize',
          weight: 0.32,
          baseAmount: 1000,
          minAmount: 500,
          maxAmount: 3000,
          roundTo: 100,
        ),
        _LuckScratchPrizeTier(
          key: 'fourth',
          zhLabel: '四等奖',
          enLabel: 'Fourth prize',
          weight: 1.6,
          baseAmount: 200,
          minAmount: 100,
          maxAmount: 500,
          roundTo: 100,
        ),
        _LuckScratchPrizeTier(
          key: 'fifth',
          zhLabel: '五等奖',
          enLabel: 'Fifth prize',
          weight: 36.0,
          baseAmount: 20,
          minAmount: 10,
          maxAmount: 50,
          roundTo: 10,
        ),
        _LuckScratchPrizeTier(
          key: 'sixth',
          zhLabel: '六等奖',
          enLabel: 'Sixth prize',
          weight: 210.0,
          baseAmount: 10,
          minAmount: 10,
          maxAmount: 20,
          roundTo: 10,
        ),
      ];
  static const _LuckScratchPrizeTier _missTier = _LuckScratchPrizeTier(
    key: 'miss',
    zhLabel: '谢谢惠顾',
    enLabel: 'Try again',
    weight: 0,
    baseAmount: 0,
    minAmount: 0,
    maxAmount: 0,
    roundTo: 1,
  );

  final math.Random _random = math.Random();
  late _LuckScratchPrizeTier _winningTier;
  late int _winningAmount;
  late Map<String, int> _prizeTable;
  late List<int> _winningNumbers;
  late String _ticketId;
  late String _packId;
  late String _ticketValidationCode;
  late String _barcodeDigits;
  late List<_LuckScratchCell> _cells;
  late List<double> _progress;
  late List<List<_LuckScratchMark>> _scratchMarks;
  int _ticketPrice = _defaultTicketPrice;
  int _slotCount = _defaultCellCount;
  double _overallProbabilityCorrection = _defaultOverallProbabilityCorrection;
  double _customProbabilityCorrection = _defaultCustomProbabilityCorrection;
  int _revealSteps = _defaultRevealSteps;
  bool _showAmount = _defaultShowAmount;
  bool _showResultBadge = _defaultShowResultBadge;
  bool _celebrationEnabled = _defaultCelebrationEnabled;
  _LuckScratchFoilStyle _foilStyle = _defaultFoilStyle;
  int _tickets = 0;
  int _winningTickets = 0;
  int _matchCount = 0;
  int _totalPrize = 0;
  int _totalSpent = 0;
  int _currentTicketMatches = 0;
  int _currentTicketPrize = 0;
  int _revealedCells = 0;
  bool _ticketComplete = false;
  bool _reportDialogOpen = false;
  bool _celebrationDialogOpen = false;
  int _lastScratchIndex = -1;
  Offset? _lastScratchPoint;
  int _scratchVersion = 0;

  int get _cellCount => _cells.length;

  double get _priceScale => _ticketPrice / _defaultTicketPrice;

  double get _completionRatio =>
      _cellCount <= 0 ? 0 : _revealedCells / _cellCount;

  int get _netPrize => _totalPrize - _totalSpent;

  double get _effectiveWinChance {
    return (1 / _baseOverallOdds * _overallProbabilityCorrection)
        .clamp(0.04, 0.92)
        .toDouble();
  }

  double get _effectiveOverallOdds {
    final chance = _effectiveWinChance;
    return chance <= 0 ? _baseOverallOdds : 1 / chance;
  }

  @override
  void initState() {
    super.initState();
    _seedTicket(incrementTicket: true);
  }

  String _randomDigits(int length) {
    return List<int>.generate(length, (_) => _random.nextInt(10)).join();
  }

  String _randomValidationCode(int length) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List<String>.generate(
      length,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
  }

  int _sampleTicketNumber(Set<int> usedNumbers) {
    var number = _random.nextInt(99) + 1;
    var guard = 0;
    while (usedNumbers.contains(number) && guard < 180) {
      number = _random.nextInt(99) + 1;
      guard += 1;
    }
    usedNumbers.add(number);
    return number;
  }

  int _sampleDecoyPrizeAmount() {
    final common = <int>[
      _ticketPrice,
      _ticketPrice * 2,
      _ticketPrice * 5,
      _ticketPrice * 10,
      _ticketPrice * 20,
      _ticketPrice * 50,
    ];
    if (_random.nextDouble() < 0.82) {
      return common[_random.nextInt(common.length)];
    }
    final tier =
        _prizeTierTemplates[3 +
            _random.nextInt(math.max(1, _prizeTierTemplates.length - 3))];
    return tier.sampleAmount(_random, _priceScale);
  }

  int _sampleMultiplier(_LuckScratchPrizeTier tier) {
    if (tier.isJackpot) {
      return 1;
    }
    final baseAmount = _prizeTable[tier.key] ?? tier.baseAmount;
    final roll = _random.nextDouble();
    if (roll < 0.72) {
      return 1;
    }
    if (roll < 0.90) {
      return baseAmount >= _ticketPrice * 2 ? 2 : 1;
    }
    if (roll < 0.98) {
      return baseAmount >= _ticketPrice * 5 ? 5 : 1;
    }
    return baseAmount >= _ticketPrice * 10 ? 10 : 1;
  }

  void _seedTicket({required bool incrementTicket}) {
    final prizeTable = _buildPrizeTable();
    final winningTier = _samplePrizeTier();
    final winningAmount = prizeTable[winningTier.key] ?? 0;
    final shouldWin = _random.nextDouble() < _effectiveWinChance;
    final usedNumbers = <int>{};
    final winningNumbers = List<int>.generate(
      math.min(5, math.max(3, (_slotCount / 2).round())),
      (_) => _sampleTicketNumber(usedNumbers),
    );
    final winningCellIndex = shouldWin && _slotCount > 0
        ? _random.nextInt(_slotCount)
        : -1;
    final winningNumber = shouldWin
        ? winningNumbers[_random.nextInt(winningNumbers.length)]
        : -1;
    _winningTier = winningTier;
    _winningAmount = winningAmount;
    _prizeTable = prizeTable;
    _winningNumbers = winningNumbers;
    _ticketId = '${_randomDigits(3)}-${_randomDigits(6)}-${_randomDigits(3)}';
    _packId = '${_randomDigits(4)}-${_randomDigits(6)}';
    _ticketValidationCode = _randomValidationCode(10);
    _barcodeDigits =
        '${_randomDigits(2)} ${_randomDigits(5)} ${_randomDigits(5)} ${_randomDigits(4)}';
    _cells = List<_LuckScratchCell>.generate(_slotCount, (index) {
      final isWinning = index == winningCellIndex;
      final multiplier = isWinning ? _sampleMultiplier(winningTier) : 1;
      final isAutoWin =
          isWinning && !winningTier.isJackpot && _random.nextDouble() < 0.16;
      final displayPrize = isWinning
          ? (multiplier <= 1
                ? winningAmount
                : math.max(_ticketPrice, (winningAmount / multiplier).round()))
          : _sampleDecoyPrizeAmount();
      final number = isWinning
          ? winningNumber
          : _sampleTicketNumber(usedNumbers);
      return _LuckScratchCell(
        tierKey: isWinning ? winningTier.key : _missTier.key,
        number: number,
        displayPrize: displayPrize,
        amount: isWinning ? winningAmount : 0,
        isWinning: isWinning,
        multiplier: multiplier,
        isAutoWin: isAutoWin,
        validationCode: _randomValidationCode(3),
      );
    });
    _progress = List<double>.filled(_cells.length, 0);
    _scratchMarks = List<List<_LuckScratchMark>>.generate(
      _cells.length,
      (_) => <_LuckScratchMark>[],
    );
    _currentTicketMatches = 0;
    _currentTicketPrize = 0;
    _revealedCells = 0;
    _ticketComplete = false;
    _lastScratchIndex = -1;
    _lastScratchPoint = null;
    _scratchVersion = 0;
    if (incrementTicket) {
      _tickets += 1;
      _totalSpent += _ticketPrice;
    }
  }

  Map<String, int> _buildPrizeTable() {
    return <String, int>{
      for (final tier in _prizeTierTemplates)
        tier.key: tier.sampleAmount(_random, _priceScale),
      _missTier.key: 0,
    };
  }

  _LuckScratchPrizeTier _samplePrizeTier() {
    final totalWeight = Iterable<int>.generate(_prizeTierTemplates.length)
        .fold<double>(
          0,
          (sum, index) =>
              sum + _adjustedPrizeTierWeight(_prizeTierTemplates[index], index),
        );
    final hit = _random.nextDouble() * totalWeight;
    var cumulative = 0.0;
    for (var i = 0; i < _prizeTierTemplates.length; i += 1) {
      final tier = _prizeTierTemplates[i];
      cumulative += _adjustedPrizeTierWeight(tier, i);
      if (hit <= cumulative) {
        return tier;
      }
    }
    return _prizeTierTemplates.last;
  }

  double _adjustedPrizeTierWeight(_LuckScratchPrizeTier tier, int index) {
    final maxIndex = math.max(1, _prizeTierTemplates.length - 1);
    final topBias = 1 - index / maxIndex;
    final correction =
        1 + (_customProbabilityCorrection - 1) * (0.35 + topBias * 0.85);
    return math.max(0.0001, tier.weight * correction);
  }

  _LuckScratchPrizeTier _tierForKey(String key) {
    if (key == _missTier.key) {
      return _missTier;
    }
    return _prizeTierTemplates.firstWhere(
      (tier) => tier.key == key,
      orElse: () => _missTier,
    );
  }

  void _newTicket() {
    setState(() => _seedTicket(incrementTicket: true));
  }

  void _reset() {
    setState(() {
      _clearScratchStats();
      _seedTicket(incrementTicket: true);
    });
  }

  void _clearScratchStats() {
    _tickets = 0;
    _winningTickets = 0;
    _matchCount = 0;
    _totalPrize = 0;
    _totalSpent = 0;
  }

  void _restartScratchRun() {
    _clearScratchStats();
    _seedTicket(incrementTicket: true);
  }

  void _applyScratchSettings(_LuckScratchSettingsSnapshot settings) {
    _ticketPrice = settings.ticketPrice;
    _slotCount = settings.cellCount;
    _overallProbabilityCorrection = settings.overallProbabilityCorrection;
    _customProbabilityCorrection = settings.customProbabilityCorrection;
    _revealSteps = settings.revealSteps;
    _showAmount = settings.showAmount;
    _showResultBadge = settings.showResultBadge;
    _celebrationEnabled = settings.celebrationEnabled;
    _foilStyle = settings.foilStyle;
  }

  void _resetScratchSettings() {
    setState(() {
      _applyScratchSettings(_defaultScratchSettings);
      _restartScratchRun();
    });
  }

  void _changeScratchSimulationSetting(VoidCallback update) {
    setState(() {
      update();
      _restartScratchRun();
    });
  }

  void _changeScratchVisualSetting(VoidCallback update) {
    setState(update);
  }

  void _resetScratchStroke() {
    _lastScratchIndex = -1;
    _lastScratchPoint = null;
  }

  void _scratchAt(Offset localPosition, Size size) {
    if (_ticketComplete ||
        _cells.isEmpty ||
        size.width <= 0 ||
        size.height <= 0) {
      return;
    }
    final layout = _scratchLayout(size.width, _cells.length);
    final strideX = layout.cellWidth + layout.spacing;
    final strideY = layout.cellHeight + layout.spacing;
    final col = (localPosition.dx / strideX).floor();
    final row = (localPosition.dy / strideY).floor();
    if (col < 0 || row < 0 || col >= layout.columns || row >= layout.rows) {
      return;
    }
    final withinCellX = localPosition.dx - col * strideX;
    final withinCellY = localPosition.dy - row * strideY;
    if (withinCellX < 0 ||
        withinCellY < 0 ||
        withinCellX > layout.cellWidth ||
        withinCellY > layout.cellHeight) {
      return;
    }
    final index = row * layout.columns + col;
    if (index < 0 || index >= _cells.length) {
      return;
    }
    final localInCell = Offset(withinCellX, withinCellY);
    final normalized = Offset(
      (localInCell.dx / layout.cellWidth).clamp(0.0, 1.0),
      (localInCell.dy / layout.cellHeight).clamp(0.0, 1.0),
    );
    final hasPreviousPoint =
        _lastScratchIndex == index && _lastScratchPoint != null;
    if (hasPreviousPoint) {
      final dx = normalized.dx - _lastScratchPoint!.dx;
      final dy = normalized.dy - _lastScratchPoint!.dy;
      if (dx * dx + dy * dy < 0.0018) {
        return;
      }
    }
    final delta = hasPreviousPoint
        ? Offset(
            normalized.dx - _lastScratchPoint!.dx,
            normalized.dy - _lastScratchPoint!.dy,
          )
        : Offset(
            math.cos(_random.nextDouble() * math.pi * 2),
            math.sin(_random.nextDouble() * math.pi * 2),
          );
    final travel = hasPreviousPoint
        ? math
              .sqrt(delta.dx * delta.dx + delta.dy * delta.dy)
              .clamp(0.08, 0.42)
              .toDouble()
        : 0.16 + _random.nextDouble() * 0.08;
    final angle =
        math.atan2(delta.dy, delta.dx) + (_random.nextDouble() - 0.5) * 0.18;
    final length = (0.16 + travel * 0.95 + _random.nextDouble() * 0.06)
        .clamp(0.16, 0.44)
        .toDouble();
    final width = (0.028 + travel * 0.17 + _random.nextDouble() * 0.014)
        .clamp(0.03, 0.082)
        .toDouble();
    final mark = _LuckScratchMark(
      center: normalized,
      angle: angle,
      length: length,
      width: width,
    );
    final revealStep = 1 / math.max(1, _revealSteps);
    final wasRevealed = _progress[index] >= _scratchRevealThreshold;
    final nextProgress =
        (_progress[index] +
                revealStep *
                    (0.38 + length * 1.15 + _random.nextDouble() * 0.14))
            .clamp(0.0, 1.0);
    if (nextProgress <= _progress[index]) {
      return;
    }
    setState(() {
      _lastScratchIndex = index;
      _lastScratchPoint = normalized;
      _scratchMarks[index].add(mark);
      if (_scratchMarks[index].length > 24) {
        _scratchMarks[index].removeAt(0);
      }
      _scratchVersion += 1;
      _progress[index] = nextProgress;
      if (!wasRevealed && nextProgress >= _scratchRevealThreshold) {
        _revealedCells += 1;
        final cell = _cells[index];
        if (cell.isWinning) {
          _matchCount += 1;
          _currentTicketMatches += 1;
          _currentTicketPrize += cell.amount;
          _totalPrize += cell.amount;
          if (_currentTicketMatches == 1) {
            _winningTickets += 1;
          }
          if (_celebrationEnabled && _winningTier.isJackpot) {
            unawaited(_showCelebration(_winningTier));
          }
        }
        _ticketComplete = _progress.every(
          (value) => value >= _scratchCompleteThreshold,
        );
      }
    });
  }

  ({int columns, int rows, double spacing, double cellWidth, double cellHeight})
  _scratchLayout(double maxWidth, int count) {
    final columns = maxWidth < 360 ? 2 : 3;
    final rows = (count / columns).ceil();
    final spacing = maxWidth < 360 ? 8.0 : 10.0;
    return (
      columns: columns,
      rows: rows,
      spacing: spacing,
      cellWidth: (maxWidth - spacing * (columns - 1)) / columns,
      cellHeight: maxWidth < 420 ? 112.0 : 126.0,
    );
  }

  Future<void> _showReport() async {
    if (!mounted || _reportDialogOpen) {
      return;
    }
    _reportDialogOpen = true;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    try {
      await showDialog<void>(
        context: context,
        builder: (context) => _LuckScratchReportDialog(
          i18n: i18n,
          tickets: _tickets,
          winningTickets: _winningTickets,
          totalMatches: _matchCount,
          totalPrize: _totalPrize,
          totalSpent: _totalSpent,
          netPrize: _netPrize,
          winningTier: _winningTier,
          winningAmount: _winningAmount,
          currentMatches: _currentTicketMatches,
          currentPrize: _currentTicketPrize,
          completionRatio: _completionRatio,
          prizeTable: Map<String, int>.unmodifiable(_prizeTable),
          cells: List<_LuckScratchCell>.unmodifiable(_cells),
          progress: List<double>.unmodifiable(_progress),
          winningNumbers: List<int>.unmodifiable(_winningNumbers),
          ticketId: _ticketId,
          packId: _packId,
          validationCode: _ticketValidationCode,
        ),
      );
    } finally {
      _reportDialogOpen = false;
    }
  }

  Future<void> _showCelebration(_LuckScratchPrizeTier tier) async {
    if (!mounted || _celebrationDialogOpen) {
      return;
    }
    _celebrationDialogOpen = true;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final amount = _prizeTable[tier.key] ?? _winningAmount;
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: pickUiText(i18n, zh: '关闭', en: 'Close'),
        barrierColor: Colors.black.withValues(alpha: 0.58),
        transitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _LuckScratchCelebrationDialog(
            i18n: i18n,
            tier: tier,
            amountText: _formatPrize(amount),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      );
    } finally {
      _celebrationDialogOpen = false;
    }
  }

  String _formatPrize(int value) {
    return value < 0 ? '-¥${value.abs()}' : '¥$value';
  }

  String _formatTicketNumber(int value) {
    return value.toString().padLeft(2, '0');
  }

  String _tierLabel(AppI18n i18n, _LuckScratchPrizeTier tier) {
    return pickUiText(i18n, zh: tier.zhLabel, en: tier.enLabel);
  }

  String _foilStyleLabel(AppI18n i18n, _LuckScratchFoilStyle style) {
    return switch (style) {
      _LuckScratchFoilStyle.metal => pickUiText(i18n, zh: '金属银', en: 'Metal'),
      _LuckScratchFoilStyle.starfield => pickUiText(
        i18n,
        zh: '星点',
        en: 'Stars',
      ),
      _LuckScratchFoilStyle.ripple => pickUiText(i18n, zh: '波纹', en: 'Ripple'),
      _LuckScratchFoilStyle.confetti => pickUiText(
        i18n,
        zh: '彩屑',
        en: 'Confetti',
      ),
    };
  }

  String _formatCorrection(double value) {
    return '${(value * 100).round()}%';
  }

  Widget _buildScratchSettings(
    BuildContext context,
    AppI18n i18n,
    ThemeData theme,
  ) {
    Widget sectionLabel(String text) {
      return Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      );
    }

    return _HumanSettingsSection(
      title: pickUiText(i18n, zh: '刮刮乐设置', en: 'Scratch settings'),
      subtitle: pickUiText(
        i18n,
        zh: '票价、刮开数量和概率变更会重新开始本轮模拟',
        en: 'Price, spot count, and odds changes start a fresh simulation run',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          sectionLabel(pickUiText(i18n, zh: '票价', en: 'Ticket price')),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ticketPriceOptions
                .map((price) {
                  return ChoiceChip(
                    label: Text(_formatPrize(price)),
                    selected: _ticketPrice == price,
                    onSelected: (_) {
                      if (_ticketPrice == price) {
                        return;
                      }
                      _changeScratchSimulationSetting(
                        () => _ticketPrice = price,
                      );
                    },
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          sectionLabel(pickUiText(i18n, zh: '刮开数量', en: 'Covered spots')),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <int>[6, 8, 10, 12]
                .map((count) {
                  return ChoiceChip(
                    label: Text(
                      pickUiText(i18n, zh: '$count 格', en: '$count spots'),
                    ),
                    selected: _slotCount == count,
                    onSelected: (_) {
                      if (_slotCount == count) {
                        return;
                      }
                      _changeScratchSimulationSetting(() => _slotCount = count);
                    },
                  );
                })
                .toList(growable: false),
          ),
          _LuckSettingSlider(
            label: pickUiText(
              i18n,
              zh: '整体中奖概率修正',
              en: 'Overall win correction',
            ),
            valueText: _formatCorrection(_overallProbabilityCorrection),
            value: _overallProbabilityCorrection,
            min: 0.5,
            max: 1.8,
            divisions: 26,
            onChanged: (value) {
              final next = (value * 100).round() / 100;
              if (next == _overallProbabilityCorrection) {
                return;
              }
              _changeScratchSimulationSetting(
                () => _overallProbabilityCorrection = next,
              );
            },
          ),
          _LuckSettingSlider(
            label: pickUiText(i18n, zh: '大奖概率修正', en: 'Prize tier correction'),
            valueText: _formatCorrection(_customProbabilityCorrection),
            value: _customProbabilityCorrection,
            min: 0.5,
            max: 2.0,
            divisions: 30,
            onChanged: (value) {
              final next = (value * 100).round() / 100;
              if (next == _customProbabilityCorrection) {
                return;
              }
              _changeScratchSimulationSetting(
                () => _customProbabilityCorrection = next,
              );
            },
          ),
          const SizedBox(height: 8),
          Chip(
            visualDensity: VisualDensity.compact,
            label: Text(
              pickUiText(
                i18n,
                zh: '当前整票赔率约 1 / ${_effectiveOverallOdds.toStringAsFixed(2)}',
                en: 'Current ticket odds about 1 / ${_effectiveOverallOdds.toStringAsFixed(2)}',
              ),
            ),
          ),
          const SizedBox(height: 14),
          sectionLabel(pickUiText(i18n, zh: '刮开表现', en: 'Scratch display')),
          _LuckSettingSlider(
            label: pickUiText(i18n, zh: '完全显示滑动次数', en: 'Reveal passes'),
            valueText: '$_revealSteps',
            value: _revealSteps.toDouble(),
            min: 2,
            max: 8,
            divisions: 6,
            onChanged: (value) {
              final next = value.round();
              if (next == _revealSteps) {
                return;
              }
              _changeScratchVisualSetting(() => _revealSteps = next);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(pickUiText(i18n, zh: '显示金额', en: 'Show amount')),
            value: _showAmount,
            onChanged: (value) =>
                _changeScratchVisualSetting(() => _showAmount = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              pickUiText(i18n, zh: '显示中奖标记', en: 'Show result badge'),
            ),
            value: _showResultBadge,
            onChanged: (value) =>
                _changeScratchVisualSetting(() => _showResultBadge = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              pickUiText(
                i18n,
                zh: '特等奖/一等奖全屏恭喜',
                en: 'Grand and first prize celebration',
              ),
            ),
            value: _celebrationEnabled,
            onChanged: (value) =>
                _changeScratchVisualSetting(() => _celebrationEnabled = value),
          ),
          const SizedBox(height: 8),
          sectionLabel(pickUiText(i18n, zh: '印花样式', en: 'Foil pattern')),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _LuckScratchFoilStyle.values
                .map((style) {
                  return ChoiceChip(
                    label: Text(_foilStyleLabel(i18n, style)),
                    selected: _foilStyle == style,
                    onSelected: (_) {
                      if (_foilStyle == style) {
                        return;
                      }
                      _changeScratchVisualSetting(() => _foilStyle = style);
                    },
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const ValueKey<String>('luck-scratch-restore-defaults-button'),
            onPressed: _resetScratchSettings,
            icon: const Icon(Icons.settings_backup_restore_rounded),
            label: Text(pickUiText(i18n, zh: '恢复默认设置', en: 'Restore defaults')),
          ),
        ],
      ),
    );
  }

  Widget _buildScratchTicketSummary(
    BuildContext context,
    AppI18n i18n,
    ThemeData theme,
  ) {
    Widget titleChip({required bool compact}) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: const Color(0xFFECC760).withValues(alpha: 0.20),
          border: Border.all(
            color: const Color(0xFFD7B14F).withValues(alpha: 0.55),
          ),
        ),
        child: Text(
          pickUiText(i18n, zh: '刮刮乐彩票', en: 'Scratch-off ticket'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            color: const Color(0xFF8A611A),
            fontSize: compact ? 12 : null,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    Widget targetChip({required bool compact}) {
      final label = _tierLabel(i18n, _winningTier);
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: _accent.withValues(alpha: 0.14),
          border: Border.all(color: _accent.withValues(alpha: 0.30)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            pickUiText(i18n, zh: '目标 $label', en: 'Target $label'),
            maxLines: 1,
            style: theme.textTheme.titleSmall?.copyWith(
              color: _accent,
              fontSize: compact ? 13 : null,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactHeader = constraints.maxWidth < 340;
        final header = compactHeader
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: titleChip(compact: true),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: targetChip(compact: true),
                  ),
                ],
              )
            : Row(
                children: <Widget>[
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: titleChip(compact: false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  targetChip(compact: false),
                ],
              );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            header,
            const SizedBox(height: 10),
            Text(
              pickUiText(
                i18n,
                zh: '刮开“中奖号码”和“我的号码”。我的号码命中任一中奖号码即可按该格奖金兑奖；星标为自动中奖，倍数符号会放大奖金。本地仅模拟票面与概率。',
                en: 'Scratch the winning numbers and your numbers. Match any winning number to win that spot prize; stars auto-win and multipliers boost the prize. This is a local ticket simulation.',
              ),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Chip(
                  label: Text(
                    pickUiText(
                      i18n,
                      zh: '票价 ${_formatPrize(_ticketPrice)}',
                      en: 'Price ${_formatPrize(_ticketPrice)}',
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text(
                    pickUiText(
                      i18n,
                      zh: '有效赔率约 1 / ${_effectiveOverallOdds.toStringAsFixed(2)}',
                      en: 'Effective odds 1 / ${_effectiveOverallOdds.toStringAsFixed(2)}',
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text(
                    pickUiText(
                      i18n,
                      zh: '$_slotCount 个刮开区',
                      en: '$_slotCount covered spots',
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              pickUiText(i18n, zh: '中奖号码', en: 'Winning numbers'),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _winningNumbers
                  .map(
                    (number) => Container(
                      width: 42,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: const Color(0xFFFFF1B8),
                        border: Border.all(color: const Color(0xFFD7B14F)),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x1AB78328),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        _formatTicketNumber(number),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF7D5514),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.star_rounded, size: 16),
                  label: Text(
                    pickUiText(i18n, zh: '星标自动中奖', en: 'Star auto-wins'),
                  ),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.close_rounded, size: 16),
                  label: Text(
                    pickUiText(
                      i18n,
                      zh: 'x2/x5/x10 放大奖金',
                      en: 'x2/x5/x10 multiply prizes',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              pickUiText(i18n, zh: '奖级表', en: 'Prize table'),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _prizeTierTemplates
                  .map((tier) {
                    final amount = _prizeTable[tier.key] ?? 0;
                    return Chip(
                      label: Text(
                        '${_tierLabel(i18n, tier)} ${_formatPrize(amount)}',
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  })
                  .toList(growable: false),
            ),
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withValues(alpha: 0.58),
                border: Border.all(color: const Color(0x22B78328)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: <Widget>[
                        _ScratchTicketStubChip(
                          label: pickUiText(i18n, zh: '票号', en: 'Ticket'),
                          value: _ticketId,
                        ),
                        _ScratchTicketStubChip(
                          label: pickUiText(i18n, zh: '包号', en: 'Pack'),
                          value: _packId,
                        ),
                        _ScratchTicketStubChip(
                          label: pickUiText(i18n, zh: '校验码', en: 'Validation'),
                          value: _ticketValidationCode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _ScratchBarcodeStrip(
                      digits: _barcodeDigits,
                      seed: _ticketId.hashCode,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (pickUiText(i18n, zh: '奖票', en: 'Tickets'), '$_tickets'),
            (
              pickUiText(i18n, zh: '中奖票', en: 'Winning tickets'),
              '$_winningTickets',
            ),
            (pickUiText(i18n, zh: '中奖数', en: 'Matches'), '$_matchCount'),
            (
              pickUiText(i18n, zh: '总奖金', en: 'Total prize'),
              _formatPrize(_totalPrize),
            ),
            (
              pickUiText(i18n, zh: '总花费', en: 'Spent'),
              _formatPrize(_totalSpent),
            ),
            (pickUiText(i18n, zh: '净收益', en: 'Net'), _formatPrize(_netPrize)),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      const Color(0xFFFFF7D9),
                      Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.62),
                      const Color(0xFFFDF2E2),
                    ],
                  ),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.72),
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x22C08A2A),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x33D5AA4D)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildScratchTicketSummary(context, i18n, theme),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                pickUiText(i18n, zh: '我的号码', en: 'Your numbers'),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final layout = _scratchLayout(width, _cells.length);
                  final height =
                      layout.cellHeight * layout.rows +
                      layout.spacing * math.max(0, layout.rows - 1);
                  return GestureDetector(
                    key: const ValueKey<String>('luck-scratch-grid'),
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      _resetScratchStroke();
                      _scratchAt(details.localPosition, Size(width, height));
                    },
                    onPanStart: (details) {
                      _resetScratchStroke();
                      _scratchAt(details.localPosition, Size(width, height));
                    },
                    onPanUpdate: (details) {
                      _scratchAt(details.localPosition, Size(width, height));
                    },
                    onPanEnd: (_) => _resetScratchStroke(),
                    onPanCancel: _resetScratchStroke,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _cells.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: layout.columns,
                        mainAxisExtent: layout.cellHeight,
                        mainAxisSpacing: layout.spacing,
                        crossAxisSpacing: layout.spacing,
                      ),
                      itemBuilder: (context, index) =>
                          _buildScratchCell(context, i18n, index),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _HumanActionButton(
                    key: const ValueKey<String>(
                      'luck-scratch-new-ticket-button',
                    ),
                    label: pickUiText(i18n, zh: '新奖票', en: 'New ticket'),
                    icon: Icons.casino_rounded,
                    onPressed: _newTicket,
                  ),
                  OutlinedButton.icon(
                    onPressed: _tickets <= 0
                        ? null
                        : () => unawaited(_showReport()),
                    icon: const Icon(Icons.analytics_rounded),
                    label: Text(pickUiText(i18n, zh: '报告', en: 'Report')),
                  ),
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(
                      pickUiText(i18n, zh: '重置统计', en: 'Reset stats'),
                    ),
                  ),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '已刮开 ${(_completionRatio * 100).round()}%',
                      en: 'Revealed ${(_completionRatio * 100).round()}%',
                    ),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (_ticketComplete) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  pickUiText(
                    i18n,
                    zh: '本张奖票已全部刮开，可以继续开下一张。',
                    en: 'This ticket is fully revealed. You can open a new one.',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _buildScratchSettings(context, i18n, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScratchCell(BuildContext context, AppI18n i18n, int index) {
    final theme = Theme.of(context);
    final cell = _cells[index];
    final tier = _tierForKey(cell.tierKey);
    final tierText = _tierLabel(i18n, tier);
    final progress = _progress[index];
    final revealed = progress >= _scratchRevealThreshold;
    final matched = revealed && cell.isWinning;
    final showBadge = revealed && _showResultBadge;
    final showAmount = revealed && _showAmount;
    final numberLabel = cell.isAutoWin
        ? pickUiText(i18n, zh: '星标', en: 'STAR')
        : _formatTicketNumber(cell.number);
    final prizeAmount = cell.isWinning ? cell.amount : cell.displayPrize;
    final multiplierLabel = cell.multiplier > 1 ? 'x${cell.multiplier}' : null;
    final scratchMarks = List<_LuckScratchMark>.unmodifiable(
      _scratchMarks[index],
    );
    final watermarkText = pickUiText(i18n, zh: '刮开', en: 'Scratch');
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 118 || constraints.maxHeight < 116;
        final radius = BorderRadius.circular(18);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: matched
                  ? <Color>[
                      const Color(0xFFFFF2B8),
                      _accent.withValues(alpha: 0.16),
                    ]
                  : <Color>[
                      const Color(0xFFFFFCF2),
                      theme.colorScheme.surfaceContainerLow.withValues(
                        alpha: 0.96,
                      ),
                    ],
            ),
            border: Border.all(
              color: matched
                  ? _accent.withValues(alpha: 0.76)
                  : const Color(0x44C69A36),
              width: matched ? 2 : 1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: matched
                    ? _accent.withValues(alpha: 0.16)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: matched ? 14 : 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          matched
                              ? const Color(0xFFFFF6C7)
                              : const Color(0xFFFFFDF7),
                          matched
                              ? const Color(0xFFFFEBA0)
                              : const Color(0xFFF5F0E4),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 6 : 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withValues(alpha: 0.76),
                      border: Border.all(color: const Color(0x33B68C2B)),
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF7D5A16),
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 6 : 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: cell.isAutoWin
                          ? _accent.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.70),
                      border: Border.all(
                        color: cell.isAutoWin
                            ? _accent.withValues(alpha: 0.34)
                            : const Color(0x22B68C2B),
                      ),
                    ),
                    child: Text(
                      numberLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cell.isAutoWin
                            ? _accent
                            : const Color(0xFF6B5F48),
                        fontWeight: FontWeight.w900,
                        height: 1,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                ),
                if (showBadge)
                  Positioned(
                    left: 8,
                    top: compact ? 32 : 36,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 6 : 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: matched
                            ? _accent.withValues(alpha: 0.18)
                            : theme.colorScheme.outlineVariant.withValues(
                                alpha: 0.50,
                              ),
                      ),
                      child: Text(
                        matched
                            ? pickUiText(i18n, zh: '中奖', en: 'Win')
                            : pickUiText(i18n, zh: '未中', en: 'Miss'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: matched
                              ? _accent
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 8 : 10,
                      compact ? 24 : 32,
                      compact ? 8 : 10,
                      showAmount ? (compact ? 34 : 44) : (compact ? 22 : 28),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            cell.isAutoWin ? '★' : numberLabel,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style:
                                (compact
                                        ? theme.textTheme.headlineSmall
                                        : theme.textTheme.headlineMedium)
                                    ?.copyWith(
                                      color: matched
                                          ? _accent
                                          : theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w900,
                                      height: 0.92,
                                      fontFeatures: const <FontFeature>[
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tierText,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: matched
                                  ? _accent
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          if (multiplierLabel != null) ...<Widget>[
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: _accent.withValues(alpha: 0.14),
                                border: Border.all(
                                  color: _accent.withValues(alpha: 0.26),
                                ),
                              ),
                              child: Text(
                                multiplierLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: _accent,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (showAmount)
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: Container(
                      height: compact ? 24 : 28,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: matched
                            ? _accent.withValues(alpha: 0.16)
                            : Colors.white.withValues(alpha: 0.78),
                        border: Border.all(
                          color: matched
                              ? _accent.withValues(alpha: 0.30)
                              : const Color(0x22A97922),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _formatPrize(prizeAmount),
                          maxLines: 1,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: matched
                                ? _accent
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 8,
                  bottom: showAmount ? (compact ? 36 : 42) : 8,
                  child: Text(
                    cell.validationCode,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.46,
                      ),
                      fontWeight: FontWeight.w900,
                      height: 1,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                if (progress < 0.995)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _LuckScratchFoilPainter(
                          progress: progress,
                          seed:
                              index * 37 +
                              (cell.tierKey.hashCode & 0x7fffffff) * 11 +
                              cell.amount +
                              _foilStyle.index * 101,
                          marks: scratchMarks,
                          scratchVersion: _scratchVersion,
                          watermarkText: watermarkText,
                          foilStyle: _foilStyle,
                        ),
                        child: progress < _scratchPromptThreshold
                            ? Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    top: compact ? 8 : 10,
                                  ),
                                  child: AnimatedOpacity(
                                    opacity:
                                        (1 -
                                                (progress /
                                                    _scratchPromptThreshold))
                                            .clamp(0.22, 1.0),
                                    duration: const Duration(milliseconds: 120),
                                    curve: Curves.easeOutCubic,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: compact ? 8 : 10,
                                        vertical: compact ? 5 : 6,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        color: Colors.white.withValues(
                                          alpha: 0.32,
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.34,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Icon(
                                            Icons.gesture_rounded,
                                            color: const Color(0xFF5D6572),
                                            size: compact ? 15 : 17,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            watermarkText,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: const Color(
                                                    0xFF5D6572,
                                                  ),
                                                  fontWeight: FontWeight.w900,
                                                  height: 1,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
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

class _LuckScratchFoilPainter extends CustomPainter {
  const _LuckScratchFoilPainter({
    required this.progress,
    required this.seed,
    required this.marks,
    required this.scratchVersion,
    required this.watermarkText,
    required this.foilStyle,
  });

  final double progress;
  final int seed;
  final List<_LuckScratchMark> marks;
  final int scratchVersion;
  final String watermarkText;
  final _LuckScratchFoilStyle foilStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 0.995) {
      return;
    }
    final coverStrength = (1.0 - progress * 0.06).clamp(0.94, 1.0).toDouble();

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(18));
    final random = math.Random(seed);
    final baseColors = switch (foilStyle) {
      _LuckScratchFoilStyle.metal => const (
        Color(0xFFF3F4F7),
        Color(0xFFBFC4CE),
        Color(0xFFE8EBF1),
      ),
      _LuckScratchFoilStyle.starfield => const (
        Color(0xFFE9ECF5),
        Color(0xFFAEB8CA),
        Color(0xFFF5E8B8),
      ),
      _LuckScratchFoilStyle.ripple => const (
        Color(0xFFECE8DC),
        Color(0xFFC5C1B5),
        Color(0xFFF4F0E5),
      ),
      _LuckScratchFoilStyle.confetti => const (
        Color(0xFFF6E9C5),
        Color(0xFFC8B17A),
        Color(0xFFF0D8B2),
      ),
    };

    canvas.save();
    canvas.clipRRect(rrect);
    canvas.saveLayer(rect, Paint());

    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[baseColors.$1, baseColors.$2, baseColors.$3],
        stops: const <double>[0, 0.54, 1],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF6F7681).withValues(alpha: 0.24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(0.8), const Radius.circular(17)),
      borderPaint,
    );

    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-0.8, -1),
        end: const Alignment(0.9, 1),
        colors: <Color>[
          Colors.white.withValues(alpha: 0.34 * coverStrength),
          Colors.white.withValues(alpha: 0.08 * coverStrength),
          const Color(0xFFF1C65A).withValues(alpha: 0.12 * coverStrength),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, glowPaint);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (foilStyle) {
      case _LuckScratchFoilStyle.metal:
        for (var i = 0; i < 7; i += 1) {
          final t = (seed * 0.17 + i * 0.39) % 1.0;
          final y = size.height * (0.14 + 0.72 * t);
          strokePaint
            ..strokeWidth = 1.0 + random.nextDouble() * 0.9
            ..color = Colors.white.withValues(
              alpha: (0.20 + i * 0.025) * coverStrength,
            );
          canvas.drawLine(
            Offset(-size.width * 0.08, y - size.height * 0.12),
            Offset(size.width * 1.06, y + size.height * 0.10),
            strokePaint,
          );
        }
      case _LuckScratchFoilStyle.starfield:
        for (var i = 0; i < 18; i += 1) {
          final center = Offset(
            random.nextDouble() * size.width,
            random.nextDouble() * size.height,
          );
          final radius = 1.0 + random.nextDouble() * 2.4;
          strokePaint
            ..strokeWidth = 0.9
            ..color = Colors.white.withValues(alpha: 0.36 * coverStrength);
          canvas.drawLine(
            center.translate(-radius, 0),
            center.translate(radius, 0),
            strokePaint,
          );
          canvas.drawLine(
            center.translate(0, -radius),
            center.translate(0, radius),
            strokePaint,
          );
        }
      case _LuckScratchFoilStyle.ripple:
        for (var i = 0; i < 7; i += 1) {
          final y = size.height * (0.12 + i * 0.13);
          final path = Path()..moveTo(-8, y);
          for (var x = 0.0; x <= size.width + 12; x += 18) {
            path.quadraticBezierTo(
              x + 9,
              y + math.sin((x + seed + i * 17) * 0.08) * 5,
              x + 18,
              y,
            );
          }
          strokePaint
            ..strokeWidth = 1.1
            ..color = Colors.white.withValues(alpha: 0.22 * coverStrength);
          canvas.drawPath(path, strokePaint);
        }
      case _LuckScratchFoilStyle.confetti:
        final confettiPaint = Paint();
        const palette = <Color>[
          Color(0xFFB58A3C),
          Color(0xFFE5CF7A),
          Color(0xFFD77B73),
          Color(0xFF7E9CC8),
        ];
        for (var i = 0; i < 24; i += 1) {
          final x = random.nextDouble() * size.width;
          final y = random.nextDouble() * size.height;
          final w = 2.4 + random.nextDouble() * 4.6;
          final h = 1.2 + random.nextDouble() * 2.6;
          confettiPaint.color = palette[i % palette.length].withValues(
            alpha: 0.32 * coverStrength,
          );
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(random.nextDouble() * math.pi);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: w, height: h),
              const Radius.circular(1.5),
            ),
            confettiPaint,
          );
          canvas.restore();
        }
    }

    for (var i = 0; i < 16; i += 1) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 0.6 + random.nextDouble() * 1.4;
      final dotPaint = Paint()
        ..color =
            Color.lerp(
              const Color(0xFF7F838C),
              Colors.white,
              random.nextDouble(),
            )!.withValues(
              alpha: (0.16 + random.nextDouble() * 0.18) * coverStrength,
            );
      canvas.drawCircle(Offset(x, y), radius, dotPaint);
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: watermarkText,
        style: TextStyle(
          color: const Color(0xFF4E5562).withValues(alpha: 0.58),
          fontSize: math.max(8, size.shortestSide * 0.09),
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.86);
    final labelOffset = Offset(
      (size.width - textPainter.width) / 2,
      size.height * 0.16,
    );
    textPainter.paint(canvas, labelOffset);

    final codePainter = TextPainter(
      text: TextSpan(
        text: '${(seed & 0xffff).toRadixString(16).toUpperCase()} VOID',
        style: TextStyle(
          color: const Color(0xFF4E5562).withValues(alpha: 0.22),
          fontSize: math.max(7, size.shortestSide * 0.055),
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.86);
    codePainter.paint(
      canvas,
      Offset((size.width - codePainter.width) / 2, size.height * 0.72),
    );

    for (var i = 0; i < marks.length; i += 1) {
      final mark = marks[i];
      final localRandom = math.Random(
        seed ^
            scratchVersion ^
            (i * 7919) ^
            (mark.center.dx * 1000).round() ^
            (mark.center.dy * 1000).round(),
      );
      _paintScratchMark(canvas, size, mark, localRandom, coverStrength);
    }

    canvas.restore();
    canvas.restore();
  }

  void _paintScratchMark(
    Canvas canvas,
    Size size,
    _LuckScratchMark mark,
    math.Random localRandom,
    double coverOpacity,
  ) {
    final center = Offset(
      mark.center.dx * size.width,
      mark.center.dy * size.height,
    );
    final length = size.shortestSide * mark.length;
    final width = size.shortestSide * mark.width;
    final path = Path()
      ..moveTo(-length * 0.48, 0)
      ..quadraticBezierTo(
        -length * 0.20,
        width * (localRandom.nextDouble() * 1.2 - 0.6),
        0,
        width * (localRandom.nextDouble() * 1.2 - 0.6),
      )
      ..quadraticBezierTo(
        length * 0.20,
        width * (localRandom.nextDouble() * 1.2 - 0.6),
        length * 0.48,
        0,
      );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(mark.angle);

    final blurPaint = Paint()
      ..blendMode = BlendMode.dstOut
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = width * (1.08 + localRandom.nextDouble() * 0.12)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        math.max(0.6, width * 0.12),
      )
      ..color = Colors.black;
    canvas.drawPath(path, blurPaint);

    final corePaint = Paint()
      ..blendMode = BlendMode.dstOut
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = width * (0.72 + localRandom.nextDouble() * 0.08)
      ..color = Colors.black;
    canvas.drawPath(path, corePaint);

    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = width * 0.18
      ..color = Colors.white.withValues(
        alpha: (0.20 + localRandom.nextDouble() * 0.16) * coverOpacity,
      );
    canvas.drawPath(path.shift(Offset(0, -width * 0.06)), edgePaint);

    final fleckPaint = Paint()
      ..color =
          Color.lerp(
            const Color(0xFF9DA1AB),
            Colors.white,
            localRandom.nextDouble(),
          )!.withValues(
            alpha: (0.16 + localRandom.nextDouble() * 0.16) * coverOpacity,
          );
    for (var i = 0; i < 4; i += 1) {
      final offsetX = (localRandom.nextDouble() - 0.5) * length * 0.92;
      final offsetY = (localRandom.nextDouble() - 0.5) * width * 1.6;
      final radius = width * (0.06 + localRandom.nextDouble() * 0.08);
      canvas.drawCircle(Offset(offsetX, offsetY), radius, fleckPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LuckScratchFoilPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.seed != seed ||
        oldDelegate.scratchVersion != scratchVersion ||
        oldDelegate.watermarkText != watermarkText ||
        oldDelegate.foilStyle != foilStyle ||
        oldDelegate.marks.length != marks.length;
  }
}

class _LuckScratchCelebrationDialog extends StatelessWidget {
  const _LuckScratchCelebrationDialog({
    required this.i18n,
    required this.tier,
    required this.amountText,
  });

  final AppI18n i18n;
  final _LuckScratchPrizeTier tier;
  final String amountText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tierLabel = pickUiText(i18n, zh: tier.zhLabel, en: tier.enLabel);
    const effectColor = Color(0xFFFFC95A);
    return Material(
      color: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1800),
        curve: Curves.easeInOutCubic,
        builder: (context, progress, child) {
          final pulse = math.sin(progress * math.pi * 5).abs();
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.70 + progress * 0.55,
                    colors: <Color>[
                      effectColor.withValues(alpha: 0.64),
                      const Color(0xFF9B5C19).withValues(alpha: 0.34),
                      Colors.black.withValues(alpha: 0.70),
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
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: 0.16 + pulse * 0.15),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const <double>[0.18, 0.50, 0.82],
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Transform.scale(
                    scale: 0.94 + pulse * 0.04,
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 22,
                      ),
                      constraints: const BoxConstraints(maxWidth: 360),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.black.withValues(alpha: 0.48),
                        border: Border.all(
                          color: effectColor.withValues(alpha: 0.90),
                          width: 2,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: effectColor.withValues(alpha: 0.48),
                            blurRadius: 42,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.workspace_premium_rounded,
                            color: effectColor,
                            size: 66,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            pickUiText(i18n, zh: '恭喜中奖', en: 'Congratulations'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$tierLabel  $amountText',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: effectColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.tonal(
                            onPressed: () => Navigator.of(context).maybePop(),
                            child: Text(
                              pickUiText(i18n, zh: '继续刮奖', en: 'Continue'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LuckScratchReportDialog extends StatelessWidget {
  const _LuckScratchReportDialog({
    required this.i18n,
    required this.tickets,
    required this.winningTickets,
    required this.totalMatches,
    required this.totalPrize,
    required this.totalSpent,
    required this.netPrize,
    required this.winningTier,
    required this.winningAmount,
    required this.currentMatches,
    required this.currentPrize,
    required this.completionRatio,
    required this.prizeTable,
    required this.cells,
    required this.progress,
    required this.winningNumbers,
    required this.ticketId,
    required this.packId,
    required this.validationCode,
  });

  final AppI18n i18n;
  final int tickets;
  final int winningTickets;
  final int totalMatches;
  final int totalPrize;
  final int totalSpent;
  final int netPrize;
  final _LuckScratchPrizeTier winningTier;
  final int winningAmount;
  final int currentMatches;
  final int currentPrize;
  final double completionRatio;
  final Map<String, int> prizeTable;
  final List<_LuckScratchCell> cells;
  final List<double> progress;
  final List<int> winningNumbers;
  final String ticketId;
  final String packId;
  final String validationCode;

  String _formatPrize(int value) {
    return value < 0 ? '-¥${value.abs()}' : '¥$value';
  }

  String _formatTicketNumber(int value) {
    return value.toString().padLeft(2, '0');
  }

  _LuckScratchPrizeTier _tierForKey(String key) {
    if (key == _LuckScratchTestCardState._missTier.key) {
      return _LuckScratchTestCardState._missTier;
    }
    return _LuckScratchTestCardState._prizeTierTemplates.firstWhere(
      (tier) => tier.key == key,
      orElse: () => _LuckScratchTestCardState._missTier,
    );
  }

  String _tierLabel(_LuckScratchPrizeTier tier) {
    return pickUiText(i18n, zh: tier.zhLabel, en: tier.enLabel);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final revealed = <String>[];
    for (var i = 0; i < cells.length; i += 1) {
      if (progress[i] >= _LuckScratchTestCardState._scratchRevealThreshold) {
        final cell = cells[i];
        final tier = _tierForKey(cell.tierKey);
        final amount = cell.isWinning ? cell.amount : cell.displayPrize;
        final number = cell.isAutoWin
            ? 'STAR'
            : _formatTicketNumber(cell.number);
        final multiplier = cell.multiplier > 1 ? ' x${cell.multiplier}' : '';
        revealed.add(
          '#${i + 1} $number ${_tierLabel(tier)} / ${_formatPrize(amount)}$multiplier',
        );
      }
    }
    return AlertDialog(
      title: Text(pickUiText(i18n, zh: '刮刮乐报告', en: 'Scratch report')),
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
                    label: pickUiText(i18n, zh: '奖票', en: 'Tickets'),
                    value: '$tickets',
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '中奖票', en: 'Winning tickets'),
                    value: '$winningTickets',
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '中奖数', en: 'Matches'),
                    value: '$totalMatches',
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '总奖金', en: 'Total prize'),
                    value: _formatPrize(totalPrize),
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '总花费', en: 'Spent'),
                    value: _formatPrize(totalSpent),
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '净收益', en: 'Net'),
                    value: _formatPrize(netPrize),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ColorVisionReportSection(
                title: pickUiText(i18n, zh: '当前奖票', en: 'Current ticket'),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    Chip(
                      label: Text(
                        pickUiText(
                          i18n,
                          zh: '中奖号码 ${winningNumbers.map(_formatTicketNumber).join(' ')}',
                          en: 'Winning numbers ${winningNumbers.map(_formatTicketNumber).join(' ')}',
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        pickUiText(
                          i18n,
                          zh: '票号 $ticketId',
                          en: 'Ticket $ticketId',
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        pickUiText(i18n, zh: '包号 $packId', en: 'Pack $packId'),
                      ),
                    ),
                    Chip(
                      label: Text(
                        pickUiText(
                          i18n,
                          zh: '校验码 $validationCode',
                          en: 'Validation $validationCode',
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        pickUiText(
                          i18n,
                          zh: '目标奖级 ${_tierLabel(winningTier)}',
                          en: 'Target tier ${_tierLabel(winningTier)}',
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        pickUiText(
                          i18n,
                          zh: '目标金额 ${_formatPrize(winningAmount)}',
                          en: 'Target amount ${_formatPrize(winningAmount)}',
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        pickUiText(
                          i18n,
                          zh: '已中奖 $currentMatches',
                          en: 'Matches $currentMatches',
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        pickUiText(
                          i18n,
                          zh: '当前奖金 ${_formatPrize(currentPrize)}',
                          en: 'Current prize ${_formatPrize(currentPrize)}',
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        pickUiText(
                          i18n,
                          zh: '刮开进度 ${(completionRatio * 100).round()}%',
                          en: 'Reveal ${(completionRatio * 100).round()}%',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ColorVisionReportSection(
                title: pickUiText(i18n, zh: '奖级表', en: 'Prize table'),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _LuckScratchTestCardState._prizeTierTemplates
                      .map(
                        (tier) => Chip(
                          label: Text(
                            '${_tierLabel(tier)} ${_formatPrize(prizeTable[tier.key] ?? 0)}',
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              if (revealed.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _ColorVisionReportSection(
                  title: pickUiText(i18n, zh: '已刮开内容', en: 'Revealed items'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: revealed
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              item,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        )
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

enum _CalculationType {
  mixed,
  addSub,
  multiply,
  division,
  twoStep,
  missing,
  exponent,
  factorial,
  arithmeticSequence,
  geometricSequence,
}

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

  void _setDifficulty(_CalculationDifficulty difficulty) {
    setState(() {
      _difficulty = difficulty;
      if (!_availableTypesForDifficulty(difficulty).contains(_type)) {
        _type = _CalculationType.mixed;
      }
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
        return _difficulty.index >= _CalculationDifficulty.hard.index
            ? _buildAdvancedTwoStepProblem(
                max: max,
                multiplierMax: multiplierMax,
                type: type,
              )
            : _buildBasicTwoStepProblem(
                max: max,
                multiplierMax: multiplierMax,
                type: type,
              );
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
      case _CalculationType.exponent:
        final baseMax = switch (_difficulty) {
          _CalculationDifficulty.easy => 5,
          _CalculationDifficulty.standard => 7,
          _CalculationDifficulty.hard => 9,
          _CalculationDifficulty.expert => 11,
        };
        final exponentMax = switch (_difficulty) {
          _CalculationDifficulty.easy => 2,
          _CalculationDifficulty.standard => 3,
          _CalculationDifficulty.hard => 3,
          _CalculationDifficulty.expert => 4,
        };
        final base = next(2, baseMax);
        final exponent = next(2, exponentMax);
        return _CalculationProblem(
          prompt: '$base^$exponent = ?',
          answer: math.pow(base, exponent).toInt(),
          type: type,
          difficulty: _difficulty,
        );
      case _CalculationType.factorial:
        final n = switch (_difficulty) {
          _CalculationDifficulty.hard => next(5, 8),
          _CalculationDifficulty.expert => next(6, 10),
          _ => next(5, 8),
        };
        return _CalculationProblem(
          prompt: '$n! = ?',
          answer: _factorial(n),
          type: type,
          difficulty: _difficulty,
        );
      case _CalculationType.arithmeticSequence:
        final first = next(2, max ~/ 3);
        final diff = next(2, switch (_difficulty) {
          _CalculationDifficulty.easy => 6,
          _CalculationDifficulty.standard => 9,
          _CalculationDifficulty.hard => 14,
          _CalculationDifficulty.expert => 18,
        });
        final index = next(4, switch (_difficulty) {
          _CalculationDifficulty.easy => 7,
          _CalculationDifficulty.standard => 9,
          _CalculationDifficulty.hard => 11,
          _CalculationDifficulty.expert => 13,
        });
        return _CalculationProblem(
          prompt:
              '$first, ${first + diff}, ${first + diff * 2}, ... 第 $index 项 = ?',
          answer: first + diff * (index - 1),
          type: type,
          difficulty: _difficulty,
        );
      case _CalculationType.geometricSequence:
        final ratio = next(2, switch (_difficulty) {
          _CalculationDifficulty.easy => 3,
          _CalculationDifficulty.standard => 4,
          _CalculationDifficulty.hard => 5,
          _CalculationDifficulty.expert => 5,
        });
        final first = next(2, switch (_difficulty) {
          _CalculationDifficulty.easy => 5,
          _CalculationDifficulty.standard => 6,
          _CalculationDifficulty.hard => 7,
          _CalculationDifficulty.expert => 8,
        });
        final index = next(3, switch (_difficulty) {
          _CalculationDifficulty.easy => 5,
          _CalculationDifficulty.standard => 6,
          _CalculationDifficulty.hard => 6,
          _CalculationDifficulty.expert => 7,
        });
        return _CalculationProblem(
          prompt:
              '$first, ${first * ratio}, ${first * ratio * ratio}, ... 第 $index 项 = ?',
          answer: first * math.pow(ratio, index - 1).toInt(),
          type: type,
          difficulty: _difficulty,
        );
      case _CalculationType.mixed:
        return _generateProblem();
    }
  }

  int _factorial(int value) {
    var result = 1;
    for (var n = 2; n <= value; n += 1) {
      result *= n;
    }
    return result;
  }

  _CalculationProblem _buildBasicTwoStepProblem({
    required int max,
    required int multiplierMax,
    required _CalculationType type,
  }) {
    int next(int min, int upper) => min + _random.nextInt(upper - min + 1);
    final a = next(2, max ~/ 2);
    final b = next(2, max ~/ 2);
    final c = next(2, multiplierMax);
    switch (_random.nextInt(3)) {
      case 0:
        return _CalculationProblem(
          prompt: '($a + $b) x $c = ?',
          answer: (a + b) * c,
          type: type,
          difficulty: _difficulty,
        );
      case 1:
        return _CalculationProblem(
          prompt: '$a x $c + $b = ?',
          answer: a * c + b,
          type: type,
          difficulty: _difficulty,
        );
      default:
        return _CalculationProblem(
          prompt: '$a x $c - $b = ?',
          answer: a * c - b,
          type: type,
          difficulty: _difficulty,
        );
    }
  }

  _CalculationProblem _buildAdvancedTwoStepProblem({
    required int max,
    required int multiplierMax,
    required _CalculationType type,
  }) {
    int next(int min, int upper) => min + _random.nextInt(upper - min + 1);
    final advancedSequenceIndex = next(4, switch (_difficulty) {
      _CalculationDifficulty.hard => 9,
      _CalculationDifficulty.expert => 12,
      _ => 9,
    });
    switch (_random.nextInt(6)) {
      case 0:
        {
          final a = next(2, max ~/ 2);
          final b = next(2, max ~/ 2);
          final c = next(2, multiplierMax);
          return _CalculationProblem(
            prompt: '($a + $b) x $c = ?',
            answer: (a + b) * c,
            type: type,
            difficulty: _difficulty,
          );
        }
      case 1:
        {
          final a = next(2, max ~/ 2);
          final b = next(2, max ~/ 2);
          final c = next(2, multiplierMax);
          return _CalculationProblem(
            prompt: '$a x $c + $b = ?',
            answer: a * c + b,
            type: type,
            difficulty: _difficulty,
          );
        }
      case 2:
        {
          final a = next(2, max ~/ 2);
          final b = next(2, max ~/ 2);
          final c = next(2, multiplierMax);
          return _CalculationProblem(
            prompt: '$a x $c - $b = ?',
            answer: a * c - b,
            type: type,
            difficulty: _difficulty,
          );
        }
      case 3:
        {
          final first = next(2, max ~/ 3);
          final diff = next(2, switch (_difficulty) {
            _CalculationDifficulty.hard => 9,
            _CalculationDifficulty.expert => 14,
            _ => 9,
          });
          final extra = next(2, multiplierMax);
          return _CalculationProblem(
            prompt:
                '$first, ${first + diff}, ${first + diff * 2}, ... 第 $advancedSequenceIndex 项 + $extra = ?',
            answer: first + diff * (advancedSequenceIndex - 1) + extra,
            type: type,
            difficulty: _difficulty,
          );
        }
      case 4:
        {
          final ratio = next(2, switch (_difficulty) {
            _CalculationDifficulty.hard => 4,
            _CalculationDifficulty.expert => 5,
            _ => 4,
          });
          final first = next(2, max ~/ 4);
          final extra = next(2, multiplierMax);
          return _CalculationProblem(
            prompt:
                '$first, ${first * ratio}, ${first * ratio * ratio}, ... 第 $advancedSequenceIndex 项 - $extra = ?',
            answer:
                first * math.pow(ratio, advancedSequenceIndex - 1).toInt() -
                extra,
            type: type,
            difficulty: _difficulty,
          );
        }
      default:
        {
          final base = next(2, switch (_difficulty) {
            _CalculationDifficulty.hard => 8,
            _CalculationDifficulty.expert => 10,
            _CalculationDifficulty.easy => 8,
            _CalculationDifficulty.standard => 8,
          });
          final exponent = next(2, switch (_difficulty) {
            _CalculationDifficulty.hard => 3,
            _CalculationDifficulty.expert => 4,
            _CalculationDifficulty.easy => 3,
            _CalculationDifficulty.standard => 3,
          });
          final extra = next(2, multiplierMax);
          return _CalculationProblem(
            prompt: '($base + $extra)^$exponent = ?',
            answer: math.pow(base + extra, exponent).toInt(),
            type: type,
            difficulty: _difficulty,
          );
        }
    }
  }

  List<_CalculationType> _availableTypesForDifficulty(
    _CalculationDifficulty difficulty,
  ) {
    final types = <_CalculationType>[
      _CalculationType.mixed,
      _CalculationType.addSub,
      _CalculationType.multiply,
      _CalculationType.division,
      _CalculationType.twoStep,
      _CalculationType.missing,
      _CalculationType.exponent,
    ];
    if (difficulty.index >= _CalculationDifficulty.hard.index) {
      types.add(_CalculationType.factorial);
    }
    types.addAll(<_CalculationType>[
      _CalculationType.arithmeticSequence,
      _CalculationType.geometricSequence,
    ]);
    return types;
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
        _CalculationType.exponent,
        _CalculationType.arithmeticSequence,
        _CalculationType.geometricSequence,
        _CalculationType.factorial,
      ],
      _CalculationDifficulty.expert => <_CalculationType>[
        _CalculationType.multiply,
        _CalculationType.division,
        _CalculationType.twoStep,
        _CalculationType.missing,
        _CalculationType.exponent,
        _CalculationType.factorial,
        _CalculationType.arithmeticSequence,
        _CalculationType.geometricSequence,
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
      _CalculationType.exponent => pickUiText(i18n, zh: '指数', en: 'Powers'),
      _CalculationType.factorial => pickUiText(i18n, zh: '阶乘', en: 'Factorial'),
      _CalculationType.arithmeticSequence => pickUiText(
        i18n,
        zh: '等差数列',
        en: 'Arithmetic seq.',
      ),
      _CalculationType.geometricSequence => pickUiText(
        i18n,
        zh: '等比数列',
        en: 'Geometric seq.',
      ),
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
                                  : (_) => _setDifficulty(difficulty),
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
                      children: _availableTypesForDifficulty(_difficulty)
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

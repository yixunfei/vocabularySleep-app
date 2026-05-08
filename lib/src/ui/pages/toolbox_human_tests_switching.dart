part of 'toolbox_human_tests.dart';

enum _SwitchTask { parity, color }

enum _SwitchPace {
  alternateEveryRound,
  alternateEveryTwo,
  alternateEveryThree,
  randomBlocks,
}

class DualTaskSwitchTestPage extends StatelessWidget {
  const DualTaskSwitchTestPage({super.key});

  static const Color _accent = Color(0xFFB05C5C);

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '双任务切换', en: 'Dual-task switching'),
      subtitle: pickUiText(
        i18n,
        zh: '在数字奇偶与颜色冷热判断之间来回切换，并观察切换代价。',
        en: 'Switch between digit parity and warm/cool color judgments while tracking switch cost.',
      ),
      accent: _accent,
      icon: Icons.swap_horiz_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：选择切换节奏并开始一组交替判断',
        en: 'Next: choose a switch rhythm and start the alternating set',
      ),
      child: const _DualTaskSwitchCard(),
    );
  }
}

class _SwitchRoundRecord {
  const _SwitchRoundRecord({
    required this.task,
    required this.correct,
    required this.milliseconds,
    required this.switched,
  });

  final _SwitchTask task;
  final bool correct;
  final int milliseconds;
  final bool switched;
}

class _DualTaskSwitchCard extends StatefulWidget {
  const _DualTaskSwitchCard();

  @override
  State<_DualTaskSwitchCard> createState() => _DualTaskSwitchCardState();
}

class _DualTaskSwitchCardState extends State<_DualTaskSwitchCard> {
  static const Color _accent = DualTaskSwitchTestPage._accent;
  static const List<Color> _warmColors = <Color>[
    Color(0xFFD9723D),
    Color(0xFFC24D5A),
    Color(0xFFE0B43A),
  ];
  static const List<Color> _coolColors = <Color>[
    Color(0xFF3D6FD8),
    Color(0xFF3F9A6B),
    Color(0xFF4D8C9E),
  ];

  final math.Random _random = math.Random();
  final Stopwatch _stopwatch = Stopwatch();
  final List<_SwitchRoundRecord> _records = <_SwitchRoundRecord>[];
  Timer? _transitionTimer;

  _SwitchPace _pace = _SwitchPace.alternateEveryRound;
  int _roundCount = 12;
  int _roundIndex = 0;
  int _correct = 0;
  int _wrong = 0;
  int _switchRounds = 0;
  int _streak = 0;
  int _bestStreak = 0;
  bool _running = false;
  bool _done = false;
  bool? _lastCorrect;
  _SwitchTask _currentTask = _SwitchTask.parity;
  int _currentDigit = 1;
  Color _currentColor = const Color(0xFFD9723D);
  bool _currentWarm = true;
  List<_SwitchTask> _sequence = const <_SwitchTask>[];

  double get _accuracy {
    final total = _correct + _wrong;
    return total == 0 ? 0 : _correct / total;
  }

  int get _avgSwitchMs {
    final items = _records
        .where((item) => item.switched && item.correct)
        .toList(growable: false);
    if (items.isEmpty) {
      return 0;
    }
    final total = items.fold<int>(0, (sum, item) => sum + item.milliseconds);
    return (total / items.length).round();
  }

  int get _avgRepeatMs {
    final items = _records
        .where((item) => !item.switched && item.correct)
        .toList(growable: false);
    if (items.isEmpty) {
      return 0;
    }
    final total = items.fold<int>(0, (sum, item) => sum + item.milliseconds);
    return (total / items.length).round();
  }

  int get _switchCost {
    final switchMs = _avgSwitchMs;
    final repeatMs = _avgRepeatMs;
    if (switchMs == 0 || repeatMs == 0) {
      return 0;
    }
    return switchMs - repeatMs;
  }

  @override
  void initState() {
    super.initState();
    _buildSequence();
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    super.dispose();
  }

  void _setPace(_SwitchPace pace) {
    if (_pace == pace) {
      return;
    }
    setState(() {
      _pace = pace;
    });
    _reset();
  }

  void _buildSequence() {
    final sequence = <_SwitchTask>[];
    var current = _SwitchTask.parity;
    while (sequence.length < _roundCount) {
      final blockSize = switch (_pace) {
        _SwitchPace.alternateEveryRound => 1,
        _SwitchPace.alternateEveryTwo => 2,
        _SwitchPace.alternateEveryThree => 3,
        _SwitchPace.randomBlocks => 1 + _random.nextInt(3),
      };
      for (var i = 0; i < blockSize && sequence.length < _roundCount; i += 1) {
        sequence.add(current);
      }
      current = current == _SwitchTask.parity
          ? _SwitchTask.color
          : _SwitchTask.parity;
    }
    _sequence = sequence;
  }

  void _start() {
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    _buildSequence();
    setState(() {
      _roundIndex = 0;
      _correct = 0;
      _wrong = 0;
      _switchRounds = 0;
      _streak = 0;
      _bestStreak = 0;
      _lastCorrect = null;
      _records.clear();
      _running = true;
      _done = false;
    });
    _beginRound();
  }

  void _reset() {
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    _buildSequence();
    setState(() {
      _roundIndex = 0;
      _correct = 0;
      _wrong = 0;
      _switchRounds = 0;
      _streak = 0;
      _bestStreak = 0;
      _lastCorrect = null;
      _records.clear();
      _running = false;
      _done = false;
    });
  }

  void _beginRound() {
    if (!mounted || !_running) {
      return;
    }
    if (_roundIndex >= _roundCount) {
      _finish();
      return;
    }
    final nextTask = _sequence[_roundIndex];
    final previousTask = _roundIndex == 0 ? null : _sequence[_roundIndex - 1];
    final switched = previousTask != null && previousTask != nextTask;
    setState(() {
      _currentTask = nextTask;
      _currentDigit = 1 + _random.nextInt(9);
      _currentWarm = _random.nextBool();
      _currentColor = _currentWarm
          ? _sample(_random, _warmColors)
          : _sample(_random, _coolColors);
      _lastCorrect = null;
      if (switched) {
        _switchRounds += 1;
      }
      _stopwatch
        ..reset()
        ..start();
    });
  }

  String _taskLabel(AppI18n i18n, _SwitchTask task) {
    return switch (task) {
      _SwitchTask.parity => pickUiText(i18n, zh: '数字奇偶', en: 'Digit parity'),
      _SwitchTask.color => pickUiText(i18n, zh: '颜色冷热', en: 'Warm or cool'),
    };
  }

  String _taskPrompt(AppI18n i18n) {
    return switch (_currentTask) {
      _SwitchTask.parity => pickUiText(
        i18n,
        zh: '判断当前数字是奇数还是偶数。',
        en: 'Judge whether the current digit is odd or even.',
      ),
      _SwitchTask.color => pickUiText(
        i18n,
        zh: '判断当前颜色是暖色还是冷色。',
        en: 'Judge whether the current color is warm or cool.',
      ),
    };
  }

  void _answer(bool correct) {
    if (!_running || _lastCorrect != null) {
      return;
    }
    _stopwatch.stop();
    final elapsed = math.max(1, _stopwatch.elapsedMilliseconds);
    final switched =
        _roundIndex > 0 && _sequence[_roundIndex] != _sequence[_roundIndex - 1];
    setState(() {
      _lastCorrect = correct;
      _records.add(
        _SwitchRoundRecord(
          task: _currentTask,
          correct: correct,
          milliseconds: elapsed,
          switched: switched,
        ),
      );
      _roundIndex += 1;
      if (correct) {
        _correct += 1;
        _streak += 1;
        _bestStreak = math.max(_bestStreak, _streak);
      } else {
        _wrong += 1;
        _streak = 0;
      }
      _done = _roundIndex >= _roundCount;
      if (_done) {
        _running = false;
      }
    });
    _transitionTimer?.cancel();
    _transitionTimer = Timer(const Duration(milliseconds: 560), () {
      if (!mounted) {
        return;
      }
      if (_done) {
        _finish();
      } else {
        _beginRound();
      }
    });
  }

  void _finish() {
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _running = false;
      _done = true;
    });
    unawaited(_showReport());
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
              pickUiText(i18n, zh: '切换轮', en: 'Switch rounds'),
              '$_switchRounds',
            ),
            (pickUiText(i18n, zh: '连击', en: 'Streak'), '$_bestStreak'),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(child: _buildStage(context, i18n)),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: pickUiText(i18n, zh: '双任务设置', en: 'Dual-task settings'),
          subtitle: pickUiText(
            i18n,
            zh: '调整每轮切换节奏、题量与判断主题。',
            en: 'Adjust the switch rhythm, round count, and judgment theme.',
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
            SegmentedButton<_SwitchPace>(
              segments: <ButtonSegment<_SwitchPace>>[
                ButtonSegment<_SwitchPace>(
                  value: _SwitchPace.alternateEveryRound,
                  label: Text(pickUiText(i18n, zh: '每轮切换', en: 'Every round')),
                ),
                ButtonSegment<_SwitchPace>(
                  value: _SwitchPace.alternateEveryTwo,
                  label: Text(pickUiText(i18n, zh: '每两轮', en: 'Every 2')),
                ),
                ButtonSegment<_SwitchPace>(
                  value: _SwitchPace.alternateEveryThree,
                  label: Text(pickUiText(i18n, zh: '每三轮', en: 'Every 3')),
                ),
                ButtonSegment<_SwitchPace>(
                  value: _SwitchPace.randomBlocks,
                  label: Text(pickUiText(i18n, zh: '随机块', en: 'Random blocks')),
                ),
              ],
              selected: <_SwitchPace>{_pace},
              onSelectionChanged: _running
                  ? null
                  : (values) => _setPace(values.first),
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
        const SizedBox(height: 14),
        _HumanPanel(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: <Widget>[
              _HumanPill(text: _taskLabel(i18n, _currentTask), accent: _accent),
              const SizedBox(height: 10),
              Text(
                _taskPrompt(i18n),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: _currentTask == _SwitchTask.parity
                      ? _accent.withValues(alpha: 0.08)
                      : _currentColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: _currentTask == _SwitchTask.parity
                        ? _accent.withValues(alpha: 0.28)
                        : _currentColor.withValues(alpha: 0.34),
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Icon(
                      _currentTask == _SwitchTask.parity
                          ? Icons.pin_rounded
                          : Icons.palette_rounded,
                      size: 42,
                      color: _currentTask == _SwitchTask.parity
                          ? _accent
                          : _currentColor,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$_currentDigit',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentColor,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: _currentColor.withValues(alpha: 0.24),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_currentTask == _SwitchTask.parity)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: _running
                          ? () => _answer(_currentDigit.isOdd)
                          : null,
                      icon: const Icon(Icons.filter_1_rounded),
                      label: Text(pickUiText(i18n, zh: '奇数', en: 'Odd')),
                    ),
                    FilledButton.icon(
                      onPressed: _running
                          ? () => _answer(_currentDigit.isEven)
                          : null,
                      icon: const Icon(Icons.filter_2_rounded),
                      label: Text(pickUiText(i18n, zh: '偶数', en: 'Even')),
                    ),
                  ],
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: _running ? () => _answer(_currentWarm) : null,
                      icon: const Icon(Icons.wb_sunny_rounded),
                      label: Text(pickUiText(i18n, zh: '暖色', en: 'Warm')),
                    ),
                    FilledButton.icon(
                      onPressed: _running ? () => _answer(!_currentWarm) : null,
                      icon: const Icon(Icons.ac_unit_rounded),
                      label: Text(pickUiText(i18n, zh: '冷色', en: 'Cool')),
                    ),
                  ],
                ),
              if (_lastCorrect != null) ...<Widget>[
                const SizedBox(height: 12),
                _HumanPill(
                  text: _lastCorrect!
                      ? pickUiText(i18n, zh: '上一轮正确', en: 'Last round correct')
                      : pickUiText(i18n, zh: '上一轮失误', en: 'Last round missed'),
                  accent: _lastCorrect!
                      ? const Color(0xFF4E8B6B)
                      : Colors.redAccent,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettings(BuildContext context, AppI18n i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(pickUiText(i18n, zh: '轮数', en: 'Rounds')),
        Wrap(
          spacing: 8,
          children: <int>[8, 12, 16, 20]
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
        Text(pickUiText(i18n, zh: '切换主题', en: 'Task theme')),
        Text(
          pickUiText(
            i18n,
            zh: '数字奇偶与颜色冷热交替出现，帮助观察切换代价。',
            en: 'Digit parity and warm/cool color cues alternate to reveal switch cost.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _showReport() async {
    if (!mounted || _records.isEmpty) {
      return;
    }
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(pickUiText(i18n, zh: '双任务切换报告', en: 'Dual-task report')),
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
                      pickUiText(i18n, zh: '切换代价', en: 'Switch cost'),
                      _switchCost == 0 ? '-' : _formatMilliseconds(_switchCost),
                    ),
                    (
                      pickUiText(i18n, zh: '切换轮', en: 'Switch rounds'),
                      '$_switchRounds',
                    ),
                    (
                      pickUiText(i18n, zh: '最佳连击', en: 'Best streak'),
                      '$_bestStreak',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _HumanPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(pickUiText(i18n, zh: '重复轮平均', en: 'Repeat average')),
                      Text(
                        _avgRepeatMs == 0
                            ? '-'
                            : _formatMilliseconds(_avgRepeatMs),
                      ),
                      const SizedBox(height: 8),
                      Text(pickUiText(i18n, zh: '切换轮平均', en: 'Switch average')),
                      Text(
                        _avgSwitchMs == 0
                            ? '-'
                            : _formatMilliseconds(_avgSwitchMs),
                      ),
                    ],
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

part of 'toolbox_human_tests.dart';

enum _BimanualMode { alternating, sync }

enum _BimanualHand { left, right }

class BimanualCoordinationTestPage extends StatelessWidget {
  const BimanualCoordinationTestPage({super.key});

  static const Color _accent = Color(0xFFD08A3A);

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '双手协调', en: 'Bimanual coordination'),
      subtitle: pickUiText(
        i18n,
        zh: '在左右手交替和双击同步之间切换，训练双手协作节奏。',
        en: 'Switch between left-right alternation and synchronized double taps to train two-hand coordination.',
      ),
      accent: _accent,
      icon: Icons.pan_tool_alt_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：选择节奏后在双侧触区完成一轮',
        en: 'Next: choose a rhythm and finish a round with both touch zones',
      ),
      child: const _BimanualCoordinationCard(),
    );
  }
}

class _BimanualRoundRecord {
  const _BimanualRoundRecord({
    required this.mode,
    required this.correct,
    required this.milliseconds,
    required this.sequenceLength,
    required this.syncGapMs,
  });

  final _BimanualMode mode;
  final bool correct;
  final int milliseconds;
  final int sequenceLength;
  final int syncGapMs;
}

class _BimanualCoordinationCard extends StatefulWidget {
  const _BimanualCoordinationCard();

  @override
  State<_BimanualCoordinationCard> createState() =>
      _BimanualCoordinationCardState();
}

class _BimanualCoordinationCardState extends State<_BimanualCoordinationCard> {
  static const Color _accent = BimanualCoordinationTestPage._accent;

  final math.Random _random = math.Random();
  final Stopwatch _stopwatch = Stopwatch();
  final List<_BimanualRoundRecord> _records = <_BimanualRoundRecord>[];
  Timer? _transitionTimer;

  _BimanualMode _mode = _BimanualMode.alternating;
  int _roundCount = 12;
  int _roundIndex = 0;
  int _correct = 0;
  int _wrong = 0;
  int _streak = 0;
  int _bestStreak = 0;
  bool _running = false;
  bool _done = false;
  bool? _lastCorrect;
  List<_BimanualHand> _sequence = const <_BimanualHand>[];
  int _sequenceStep = 0;
  _BimanualHand? _syncFirstHand;
  int _syncFirstTapMs = 0;
  int _syncWindowMs = 420;

  int get _averageMs {
    if (_records.isEmpty) {
      return 0;
    }
    final total = _records.fold<int>(0, (sum, item) => sum + item.milliseconds);
    return (total / _records.length).round();
  }

  int get _averageSyncGapMs {
    final items = _records
        .where((item) => item.mode == _BimanualMode.sync && item.correct)
        .toList(growable: false);
    if (items.isEmpty) {
      return 0;
    }
    final total = items.fold<int>(0, (sum, item) => sum + item.syncGapMs);
    return (total / items.length).round();
  }

  double get _accuracy {
    final total = _correct + _wrong;
    return total == 0 ? 0 : _correct / total;
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

  void _setMode(_BimanualMode mode) {
    if (_mode == mode) {
      return;
    }
    setState(() {
      _mode = mode;
    });
    _reset();
  }

  void _buildSequence() {
    if (_mode == _BimanualMode.alternating) {
      final start = _random.nextBool()
          ? _BimanualHand.left
          : _BimanualHand.right;
      final sequence = <_BimanualHand>[];
      var current = start;
      for (var i = 0; i < 4; i += 1) {
        sequence.add(current);
        current = current == _BimanualHand.left
            ? _BimanualHand.right
            : _BimanualHand.left;
      }
      _sequence = sequence;
      return;
    }
    _sequence = <_BimanualHand>[_BimanualHand.left, _BimanualHand.right];
  }

  void _start() {
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    _buildSequence();
    setState(() {
      _records.clear();
      _roundIndex = 0;
      _correct = 0;
      _wrong = 0;
      _streak = 0;
      _bestStreak = 0;
      _lastCorrect = null;
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
      _records.clear();
      _roundIndex = 0;
      _correct = 0;
      _wrong = 0;
      _streak = 0;
      _bestStreak = 0;
      _lastCorrect = null;
      _running = false;
      _done = false;
      _sequenceStep = 0;
      _syncFirstHand = null;
      _syncFirstTapMs = 0;
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
    _buildSequence();
    setState(() {
      _sequenceStep = 0;
      _syncFirstHand = null;
      _syncFirstTapMs = 0;
      _lastCorrect = null;
      _stopwatch
        ..reset()
        ..start();
    });
  }

  String _handLabel(AppI18n i18n, _BimanualHand hand) {
    return switch (hand) {
      _BimanualHand.left => pickUiText(i18n, zh: '左手', en: 'Left'),
      _BimanualHand.right => pickUiText(i18n, zh: '右手', en: 'Right'),
    };
  }

  IconData _handIcon(_BimanualHand hand) {
    return hand == _BimanualHand.left
        ? Icons.arrow_back_rounded
        : Icons.arrow_forward_rounded;
  }

  void _tapHand(_BimanualHand hand) {
    if (!_running || _lastCorrect != null) {
      return;
    }
    if (_mode == _BimanualMode.alternating) {
      _handleAlternatingTap(hand);
    } else {
      _handleSyncTap(hand);
    }
  }

  void _handleAlternatingTap(_BimanualHand hand) {
    if (_sequence.isEmpty) {
      return;
    }
    final expected = _sequence[_sequenceStep];
    if (hand != expected) {
      _completeRound(correct: false, syncGapMs: 0);
      return;
    }
    setState(() {
      _sequenceStep += 1;
    });
    if (_sequenceStep >= _sequence.length) {
      _completeRound(correct: true, syncGapMs: 0);
    }
  }

  void _handleSyncTap(_BimanualHand hand) {
    if (_syncFirstHand == null) {
      setState(() {
        _syncFirstHand = hand;
        _syncFirstTapMs = _stopwatch.elapsedMilliseconds;
      });
      _transitionTimer?.cancel();
      _transitionTimer = Timer(Duration(milliseconds: _syncWindowMs + 80), () {
        if (!mounted || _lastCorrect != null) {
          return;
        }
        _completeRound(correct: false, syncGapMs: 0);
      });
      return;
    }
    if (hand == _syncFirstHand) {
      _completeRound(correct: false, syncGapMs: 0);
      return;
    }
    final gap = math.max(1, _stopwatch.elapsedMilliseconds - _syncFirstTapMs);
    if (gap > _syncWindowMs) {
      _completeRound(correct: false, syncGapMs: gap);
      return;
    }
    _completeRound(correct: true, syncGapMs: gap);
  }

  void _completeRound({required bool correct, required int syncGapMs}) {
    if (_lastCorrect != null) {
      return;
    }
    _transitionTimer?.cancel();
    _stopwatch.stop();
    final elapsed = math.max(1, _stopwatch.elapsedMilliseconds);
    setState(() {
      _lastCorrect = correct;
      _records.add(
        _BimanualRoundRecord(
          mode: _mode,
          correct: correct,
          milliseconds: elapsed,
          sequenceLength: _sequence.length,
          syncGapMs: syncGapMs,
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
    _transitionTimer = Timer(const Duration(milliseconds: 620), () {
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
          title: pickUiText(i18n, zh: '双手设置', en: 'Bimanual settings'),
          subtitle: pickUiText(
            i18n,
            zh: '切换左右交替或同步双击，并调整轮数与同步窗口。',
            en: 'Switch between alternation and synchronized taps, then adjust rounds and sync window.',
          ),
          child: _buildSettings(context, i18n),
        ),
      ],
    );
  }

  Widget _buildStage(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    final leftActive = _mode == _BimanualMode.sync
        ? true
        : _sequence.isNotEmpty &&
              _sequenceStep < _sequence.length &&
              _sequence[_sequenceStep] == _BimanualHand.left;
    final rightActive = _mode == _BimanualMode.sync
        ? true
        : _sequence.isNotEmpty &&
              _sequenceStep < _sequence.length &&
              _sequence[_sequenceStep] == _BimanualHand.right;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            SegmentedButton<_BimanualMode>(
              segments: <ButtonSegment<_BimanualMode>>[
                ButtonSegment<_BimanualMode>(
                  value: _BimanualMode.alternating,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: Text(pickUiText(i18n, zh: '交替', en: 'Alternating')),
                ),
                ButtonSegment<_BimanualMode>(
                  value: _BimanualMode.sync,
                  icon: const Icon(Icons.hub_rounded),
                  label: Text(pickUiText(i18n, zh: '同步', en: 'Sync')),
                ),
              ],
              selected: <_BimanualMode>{_mode},
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
        const SizedBox(height: 14),
        _HumanPanel(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                _mode == _BimanualMode.alternating
                    ? pickUiText(
                        i18n,
                        zh: '按顺序点亮对应手侧，按完四步即完成一轮。',
                        en: 'Tap the highlighted side in order. Finish four taps to complete a round.',
                      )
                    : pickUiText(
                        i18n,
                        zh: '先点一侧，再在同步窗口内补点另一侧。',
                        en: 'Tap one side first, then tap the other side within the sync window.',
                      ),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (_mode == _BimanualMode.alternating)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: _sequence
                      .map(
                        (hand) => _HumanPill(
                          text: _handLabel(i18n, hand),
                          accent: hand == _BimanualHand.left
                              ? const Color(0xFF4D8C9E)
                              : _accent,
                        ),
                      )
                      .toList(growable: false),
                )
              else
                _HumanPill(
                  text: pickUiText(i18n, zh: '两手同时', en: 'Both hands together'),
                  accent: _accent,
                ),
              const SizedBox(height: 14),
              AspectRatio(
                aspectRatio: 1.4,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      children: <Widget>[
                        Expanded(
                          child: _HandPad(
                            label: _handLabel(i18n, _BimanualHand.left),
                            icon: _handIcon(_BimanualHand.left),
                            accent: const Color(0xFF4D8C9E),
                            active: leftActive,
                            onTap: _running
                                ? () => _tapHand(_BimanualHand.left)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HandPad(
                            label: _handLabel(i18n, _BimanualHand.right),
                            icon: _handIcon(_BimanualHand.right),
                            accent: _accent,
                            active: rightActive,
                            onTap: _running
                                ? () => _tapHand(_BimanualHand.right)
                                : null,
                          ),
                        ),
                      ],
                    );
                  },
                ),
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
          children: <int>[8, 12, 16]
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
        Text(pickUiText(i18n, zh: '同步窗口', en: 'Sync window')),
        Slider(
          value: _syncWindowMs.toDouble(),
          min: 260,
          max: 700,
          divisions: 11,
          label: '$_syncWindowMs ms',
          onChanged: _running
              ? null
              : (value) => setState(() => _syncWindowMs = value.round()),
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
          title: Text(pickUiText(i18n, zh: '双手协调报告', en: 'Bimanual report')),
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
                      _formatMilliseconds(_averageMs),
                    ),
                    (
                      pickUiText(i18n, zh: '最佳连击', en: 'Best streak'),
                      '$_bestStreak',
                    ),
                    (
                      pickUiText(i18n, zh: '同步差', en: 'Sync gap'),
                      _averageSyncGapMs == 0
                          ? '-'
                          : _formatMilliseconds(_averageSyncGapMs),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _HumanPanel(
                  child: Text(
                    _mode == _BimanualMode.sync
                        ? pickUiText(
                            i18n,
                            zh: '同步窗口内反应稳定时，可以尝试更窄窗口或更快的双击。',
                            en: 'When sync responses are stable, try a narrower window or faster double taps.',
                          )
                        : pickUiText(
                            i18n,
                            zh: '交替节奏稳定后，可以提高轮数或保持更均匀的左右切换。',
                            en: 'When the alternation rhythm is stable, raise the round count or keep the left-right cadence more even.',
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

class _HandPad extends StatelessWidget {
  const _HandPad({
    required this.label,
    required this.icon,
    required this.accent,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: active
                ? accent.withValues(alpha: 0.14)
                : colorScheme.surface,
            border: Border.all(
              color: active
                  ? accent.withValues(alpha: 0.52)
                  : colorScheme.outlineVariant,
              width: active ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 40,
                color: active ? accent : colorScheme.outline,
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

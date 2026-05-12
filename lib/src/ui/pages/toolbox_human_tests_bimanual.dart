part of 'toolbox_human_tests.dart';

enum _BimanualMode { arcade, splitBrain, conductor }

enum _BimanualLane { left, right, both }

enum _BimanualRule { tap, hold, mirror, decoy }

enum _BimanualSide { left, right }

enum _BimanualTaskType { trace, bounce, climb }

enum _BrainSplitFullscreenAction { settings, reset, report, stop, exit }

class BimanualCoordinationTestPage extends StatelessWidget {
  const BimanualCoordinationTestPage({super.key});

  static const Color _accent = Color(0xFFD08A3A);
  static const Color _leftAccent = Color(0xFF4D8C9E);
  static const Color _rightAccent = Color(0xFFD08A3A);
  static const Color _traceAccent = Color(0xFF73A7C4);
  static const Color _bounceAccent = Color(0xFFF0A85A);
  static const Color _climbAccent = Color(0xFFB96D5A);
  static const Color _dangerAccent = Color(0xFFC45C55);

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '双手协调', en: 'Bimanual coordination'),
      subtitle: pickUiText(
        i18n,
        zh: '左右手同时控制不同小游戏，手机默认进入横屏全屏，在脑裂、同步奖励和节奏切换里练习独立分工。',
        en: 'Run different mini-games on both sides at once. Phones default to landscape fullscreen for split-brain separation, sync bonuses, and rhythm shifts.',
      ),
      accent: _accent,
      icon: Icons.pan_tool_alt_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：进入全屏横屏，同时推进左右两侧任务。',
        en: 'Next: enter landscape fullscreen and push both sides forward together.',
      ),
      child: const _BimanualBrainSplitGame(),
    );
  }
}

class _BrainSplitTaskSpec {
  const _BrainSplitTaskSpec({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.goalText,
    required this.accent,
    required this.seed,
  });

  final _BimanualTaskType type;
  final String title;
  final String subtitle;
  final String goalText;
  final Color accent;
  final int seed;
}

class _BrainSplitRoundPlan {
  const _BrainSplitRoundPlan({
    required this.label,
    required this.left,
    required this.right,
    required this.durationMs,
  });

  final String label;
  final _BrainSplitTaskSpec left;
  final _BrainSplitTaskSpec right;
  final int durationMs;
}

class _BrainSplitLaneResult {
  const _BrainSplitLaneResult({
    required this.success,
    required this.milliseconds,
    required this.scoreDelta,
    required this.detail,
  });

  final bool success;
  final int milliseconds;
  final int scoreDelta;
  final String detail;
}

class _BrainSplitRoundRecord {
  const _BrainSplitRoundRecord({
    required this.plan,
    required this.left,
    required this.right,
    required this.roundMilliseconds,
    required this.scoreDelta,
    required this.syncGapMs,
  });

  final _BrainSplitRoundPlan plan;
  final _BrainSplitLaneResult left;
  final _BrainSplitLaneResult right;
  final int roundMilliseconds;
  final int scoreDelta;
  final int syncGapMs;
}

class _BimanualCue {
  const _BimanualCue({
    required this.lane,
    required this.rule,
    required this.durationMs,
    this.holdMs = 0,
  });

  final _BimanualLane lane;
  final _BimanualRule rule;
  final int durationMs;
  final int holdMs;

  bool get isSuccessByTimeout => rule == _BimanualRule.decoy;
}

class _BimanualRoundRecord {
  const _BimanualRoundRecord({
    required this.cue,
    required this.correct,
    required this.milliseconds,
    required this.scoreDelta,
    required this.comboAfter,
    required this.syncGapMs,
  });

  final _BimanualCue cue;
  final bool correct;
  final int milliseconds;
  final int scoreDelta;
  final int comboAfter;
  final int syncGapMs;
}

class _BimanualCoordinationGame extends StatefulWidget {
  const _BimanualCoordinationGame();

  @override
  State<_BimanualCoordinationGame> createState() =>
      _BimanualCoordinationGameState();
}

class _BimanualCoordinationGameState extends State<_BimanualCoordinationGame> {
  static const Color _accent = BimanualCoordinationTestPage._accent;
  static const Color _leftAccent = BimanualCoordinationTestPage._leftAccent;
  static const Color _rightAccent = BimanualCoordinationTestPage._rightAccent;
  static const Color _dangerAccent = BimanualCoordinationTestPage._dangerAccent;

  final math.Random _random = math.Random();
  final Stopwatch _cueStopwatch = Stopwatch();
  final List<_BimanualRoundRecord> _records = <_BimanualRoundRecord>[];

  Timer? _cueTimer;
  Timer? _autoAdvanceTimer;
  Timer? _leftHoldTimer;
  Timer? _rightHoldTimer;

  _BimanualMode _mode = _BimanualMode.arcade;
  _BimanualCue? _cue;
  int _roundCount = 16;
  int _roundIndex = 0;
  int _score = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _leftHits = 0;
  int _rightHits = 0;
  int _mistakes = 0;
  int _syncWindowMs = 240;
  int _holdTargetMs = 360;
  int _paceLevel = 2;
  int _serial = 0;
  bool _running = false;
  bool _done = false;
  bool? _lastCorrect;
  _BimanualLane? _firstSyncLane;
  int _firstSyncMs = 0;
  bool _leftHeld = false;
  bool _rightHeld = false;
  bool _holdCompleted = false;

  int get _correctCount => _records.where((item) => item.correct).length;

  double get _accuracy {
    if (_records.isEmpty) {
      return 0;
    }
    return _correctCount / _records.length;
  }

  int get _averageMs {
    final items = _records
        .where((item) => item.correct && item.cue.rule != _BimanualRule.decoy)
        .toList(growable: false);
    if (items.isEmpty) {
      return 0;
    }
    final total = items.fold<int>(0, (sum, item) => sum + item.milliseconds);
    return (total / items.length).round();
  }

  int get _averageSyncGap {
    final items = _records
        .where((item) => item.correct && item.syncGapMs > 0)
        .toList(growable: false);
    if (items.isEmpty) {
      return 0;
    }
    final total = items.fold<int>(0, (sum, item) => sum + item.syncGapMs);
    return (total / items.length).round();
  }

  @override
  void dispose() {
    _cancelTimers();
    _cueStopwatch
      ..stop()
      ..reset();
    super.dispose();
  }

  void _cancelTimers() {
    _cueTimer?.cancel();
    _autoAdvanceTimer?.cancel();
    _leftHoldTimer?.cancel();
    _rightHoldTimer?.cancel();
  }

  void _setMode(_BimanualMode mode) {
    if (_mode == mode || _running) {
      return;
    }
    setState(() {
      _mode = mode;
      _done = false;
      _lastCorrect = null;
    });
  }

  void _start() {
    _cancelTimers();
    _cueStopwatch
      ..stop()
      ..reset();
    setState(() {
      _records.clear();
      _roundIndex = 0;
      _score = 0;
      _combo = 0;
      _bestCombo = 0;
      _leftHits = 0;
      _rightHits = 0;
      _mistakes = 0;
      _running = true;
      _done = false;
      _lastCorrect = null;
      _serial += 1;
    });
    _beginCue();
  }

  void _reset() {
    _cancelTimers();
    _cueStopwatch
      ..stop()
      ..reset();
    setState(() {
      _records.clear();
      _cue = null;
      _roundIndex = 0;
      _score = 0;
      _combo = 0;
      _bestCombo = 0;
      _leftHits = 0;
      _rightHits = 0;
      _mistakes = 0;
      _running = false;
      _done = false;
      _lastCorrect = null;
      _firstSyncLane = null;
      _firstSyncMs = 0;
      _leftHeld = false;
      _rightHeld = false;
      _holdCompleted = false;
      _serial += 1;
    });
  }

  void _beginCue() {
    if (!mounted || !_running) {
      return;
    }
    if (_roundIndex >= _roundCount) {
      _finish();
      return;
    }
    _cancelTimers();
    final cue = _nextCue();
    setState(() {
      _cue = cue;
      _lastCorrect = null;
      _firstSyncLane = null;
      _firstSyncMs = 0;
      _leftHeld = false;
      _rightHeld = false;
      _holdCompleted = false;
      _serial += 1;
      _cueStopwatch
        ..reset()
        ..start();
    });
    _cueTimer = Timer(Duration(milliseconds: cue.durationMs), () {
      if (!mounted || !_running || _lastCorrect != null || _cue != cue) {
        return;
      }
      _completeCue(correct: cue.isSuccessByTimeout, syncGapMs: 0);
    });
  }

  _BimanualCue _nextCue() {
    final baseDuration = switch (_paceLevel) {
      1 => 1700,
      2 => 1350,
      3 => 1080,
      _ => 920,
    };
    final pressure = (_roundIndex / math.max(1, _roundCount - 1)).clamp(
      0.0,
      1.0,
    );
    final duration = (baseDuration - pressure * 260)
        .round()
        .clamp(680, 1800)
        .toInt();

    final rules = switch (_mode) {
      _BimanualMode.arcade => <_BimanualRule>[
        _BimanualRule.tap,
        _BimanualRule.tap,
        _BimanualRule.hold,
        _BimanualRule.mirror,
      ],
      _BimanualMode.splitBrain => <_BimanualRule>[
        _BimanualRule.tap,
        _BimanualRule.hold,
        _BimanualRule.mirror,
        _BimanualRule.decoy,
      ],
      _BimanualMode.conductor => <_BimanualRule>[
        _BimanualRule.tap,
        _BimanualRule.tap,
        _BimanualRule.mirror,
      ],
    };
    final rule = _sample(_random, rules);

    final lane = switch (rule) {
      _BimanualRule.mirror => _BimanualLane.both,
      _BimanualRule.decoy => _sample(_random, <_BimanualLane>[
        _BimanualLane.left,
        _BimanualLane.right,
      ]),
      _ =>
        _random.nextInt(5) == 0
            ? _BimanualLane.both
            : _sample(_random, <_BimanualLane>[
                _BimanualLane.left,
                _BimanualLane.right,
              ]),
    };

    return _BimanualCue(
      lane: lane,
      rule: rule,
      durationMs: duration,
      holdMs: rule == _BimanualRule.hold ? _holdTargetMs : 0,
    );
  }

  void _tapLane(_BimanualLane lane) {
    final cue = _cue;
    if (!_running || _lastCorrect != null || cue == null) {
      return;
    }
    HapticFeedback.selectionClick();
    if (cue.rule == _BimanualRule.decoy) {
      _completeCue(correct: false, syncGapMs: 0);
      return;
    }
    if (cue.rule == _BimanualRule.hold) {
      _completeCue(correct: false, syncGapMs: 0);
      return;
    }
    if (cue.rule == _BimanualRule.mirror || cue.lane == _BimanualLane.both) {
      _handleSyncTap(lane);
      return;
    }
    _completeCue(correct: lane == cue.lane, syncGapMs: 0);
  }

  void _handleSyncTap(_BimanualLane lane) {
    if (lane == _BimanualLane.both) {
      return;
    }
    if (_firstSyncLane == null) {
      setState(() {
        _firstSyncLane = lane;
        _firstSyncMs = _cueStopwatch.elapsedMilliseconds;
      });
      _autoAdvanceTimer?.cancel();
      _autoAdvanceTimer = Timer(Duration(milliseconds: _syncWindowMs), () {
        if (!mounted || _lastCorrect != null) {
          return;
        }
        _completeCue(correct: false, syncGapMs: 0);
      });
      return;
    }
    if (_firstSyncLane == lane) {
      _completeCue(correct: false, syncGapMs: 0);
      return;
    }
    final gap = math.max(1, _cueStopwatch.elapsedMilliseconds - _firstSyncMs);
    _completeCue(correct: gap <= _syncWindowMs, syncGapMs: gap);
  }

  void _setHold(_BimanualLane lane, bool value) {
    final cue = _cue;
    if (!_running || _lastCorrect != null || cue == null) {
      return;
    }
    if (lane == _BimanualLane.left) {
      _leftHoldTimer?.cancel();
      setState(() => _leftHeld = value);
    } else if (lane == _BimanualLane.right) {
      _rightHoldTimer?.cancel();
      setState(() => _rightHeld = value);
    }
    if (!value) {
      return;
    }
    if (cue.rule != _BimanualRule.hold) {
      return;
    }
    final targetMatches = cue.lane == _BimanualLane.both || cue.lane == lane;
    if (!targetMatches) {
      _completeCue(correct: false, syncGapMs: 0);
      return;
    }
    final timer = Timer(Duration(milliseconds: cue.holdMs), () {
      if (!mounted || _lastCorrect != null || _cue != cue) {
        return;
      }
      final completed = cue.lane == _BimanualLane.both
          ? _leftHeld && _rightHeld
          : lane == _BimanualLane.left
          ? _leftHeld
          : _rightHeld;
      if (completed && !_holdCompleted) {
        _holdCompleted = true;
        _completeCue(correct: true, syncGapMs: 0);
      }
    });
    if (lane == _BimanualLane.left) {
      _leftHoldTimer = timer;
    } else {
      _rightHoldTimer = timer;
    }
  }

  void _completeCue({required bool correct, required int syncGapMs}) {
    final cue = _cue;
    if (!_running || _lastCorrect != null || cue == null) {
      return;
    }
    _cueTimer?.cancel();
    _autoAdvanceTimer?.cancel();
    _leftHoldTimer?.cancel();
    _rightHoldTimer?.cancel();
    _cueStopwatch.stop();
    final elapsed = math.max(1, _cueStopwatch.elapsedMilliseconds);
    final fastBonus = correct
        ? ((cue.durationMs - elapsed) / 70).clamp(0, 10).round()
        : 0;
    final syncBonus = correct && syncGapMs > 0
        ? ((_syncWindowMs - syncGapMs) / 35).round()
        : 0;
    final nextCombo = correct ? _combo + 1 : 0;
    final scoreDelta = correct ? 10 + fastBonus + syncBonus + nextCombo : -6;

    setState(() {
      _lastCorrect = correct;
      if (correct) {
        _combo = nextCombo;
        _bestCombo = math.max(_bestCombo, _combo);
        _score += scoreDelta;
        if (cue.lane == _BimanualLane.left || cue.lane == _BimanualLane.both) {
          _leftHits += 1;
        }
        if (cue.lane == _BimanualLane.right || cue.lane == _BimanualLane.both) {
          _rightHits += 1;
        }
      } else {
        _combo = 0;
        _mistakes += 1;
        _score = math.max(0, _score + scoreDelta);
      }
      _records.add(
        _BimanualRoundRecord(
          cue: cue,
          correct: correct,
          milliseconds: elapsed,
          scoreDelta: scoreDelta,
          comboAfter: _combo,
          syncGapMs: syncGapMs,
        ),
      );
      _roundIndex += 1;
      _done = _roundIndex >= _roundCount;
      if (_done) {
        _running = false;
      }
      _leftHeld = false;
      _rightHeld = false;
      _serial += 1;
    });

    HapticFeedback.lightImpact();
    _autoAdvanceTimer = Timer(const Duration(milliseconds: 520), () {
      if (!mounted) {
        return;
      }
      if (_done) {
        _finish();
      } else {
        _beginCue();
      }
    });
  }

  void _finish() {
    _cancelTimers();
    _cueStopwatch
      ..stop()
      ..reset();
    setState(() {
      _running = false;
      _done = true;
      _leftHeld = false;
      _rightHeld = false;
    });
    unawaited(_showReport());
  }

  String _modeLabel(AppI18n i18n, _BimanualMode mode) {
    return switch (mode) {
      _BimanualMode.arcade => pickUiText(i18n, zh: '街机混合', en: 'Arcade mix'),
      _BimanualMode.splitBrain => pickUiText(
        i18n,
        zh: '脑裂风暴',
        en: 'Split-brain storm',
      ),
      _BimanualMode.conductor => pickUiText(
        i18n,
        zh: '节奏指挥',
        en: 'Rhythm conductor',
      ),
    };
  }

  String _ruleLabel(AppI18n i18n, _BimanualRule rule) {
    return switch (rule) {
      _BimanualRule.tap => pickUiText(i18n, zh: '点按', en: 'Tap'),
      _BimanualRule.hold => pickUiText(i18n, zh: '长按', en: 'Hold'),
      _BimanualRule.mirror => pickUiText(i18n, zh: '同步', en: 'Sync'),
      _BimanualRule.decoy => pickUiText(i18n, zh: '陷阱', en: 'Trap'),
    };
  }

  String _laneLabel(AppI18n i18n, _BimanualLane lane) {
    return switch (lane) {
      _BimanualLane.left => pickUiText(i18n, zh: '左手', en: 'Left'),
      _BimanualLane.right => pickUiText(i18n, zh: '右手', en: 'Right'),
      _BimanualLane.both => pickUiText(i18n, zh: '双手', en: 'Both'),
    };
  }

  String _cueInstruction(AppI18n i18n) {
    final cue = _cue;
    if (!_running || cue == null) {
      return pickUiText(
        i18n,
        zh: '选择玩法后开始，双手分别守住左右触区。',
        en: 'Pick a mode and start. Keep both hands on the left and right pads.',
      );
    }
    return switch (cue.rule) {
      _BimanualRule.tap =>
        cue.lane == _BimanualLane.both
            ? pickUiText(
                i18n,
                zh: '双手几乎同时点下',
                en: 'Tap both pads nearly together',
              )
            : pickUiText(
                i18n,
                zh: '点按${_laneLabel(i18n, cue.lane)}触区',
                en: 'Tap the ${_laneLabel(i18n, cue.lane)} pad',
              ),
      _BimanualRule.hold =>
        cue.lane == _BimanualLane.both
            ? pickUiText(
                i18n,
                zh: '双手同时按住直到充能完成',
                en: 'Hold both pads until charge completes',
              )
            : pickUiText(
                i18n,
                zh: '按住${_laneLabel(i18n, cue.lane)}触区',
                en: 'Hold the ${_laneLabel(i18n, cue.lane)} pad',
              ),
      _BimanualRule.mirror => pickUiText(
        i18n,
        zh: '镜像指令：左右手在窗口内连击',
        en: 'Mirror cue: strike left and right within the sync window',
      ),
      _BimanualRule.decoy => pickUiText(
        i18n,
        zh: '陷阱指令：什么都别按',
        en: 'Trap cue: press nothing',
      ),
    };
  }

  Color _laneAccent(_BimanualLane lane) {
    return switch (lane) {
      _BimanualLane.left => _leftAccent,
      _BimanualLane.right => _rightAccent,
      _BimanualLane.both => _accent,
    };
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final cue = _cue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(i18n, zh: '进度', en: 'Progress'),
              '$_roundIndex/$_roundCount',
            ),
            (pickUiText(i18n, zh: '分数', en: 'Score'), '$_score'),
            (pickUiText(i18n, zh: '连击', en: 'Combo'), '$_combo'),
            (
              pickUiText(i18n, zh: '准确率', en: 'Accuracy'),
              _records.isEmpty ? '-' : '${(_accuracy * 100).round()}%',
            ),
            (
              pickUiText(i18n, zh: '平均反应', en: 'Avg reaction'),
              _averageMs == 0 ? '-' : _formatMilliseconds(_averageMs),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          padding: const EdgeInsets.all(14),
          child: _BimanualStage(
            serial: _serial,
            cue: cue,
            running: _running,
            done: _done,
            lastCorrect: _lastCorrect,
            leftHeld: _leftHeld,
            rightHeld: _rightHeld,
            firstSyncLane: _firstSyncLane,
            modeLabel: _modeLabel(i18n, _mode),
            instruction: _cueInstruction(i18n),
            ruleLabel: cue == null ? '-' : _ruleLabel(i18n, cue.rule),
            laneLabel: cue == null ? '-' : _laneLabel(i18n, cue.lane),
            syncWindowMs: _syncWindowMs,
            onTapLeft: () => _tapLane(_BimanualLane.left),
            onTapRight: () => _tapLane(_BimanualLane.right),
            onHoldLeft: (value) => _setHold(_BimanualLane.left, value),
            onHoldRight: (value) => _setHold(_BimanualLane.right, value),
            laneAccent: _laneAccent,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _HumanActionButton(
              label: _running
                  ? pickUiText(i18n, zh: '重新开始', en: 'Restart')
                  : pickUiText(i18n, zh: '开始挑战', en: 'Start challenge'),
              icon: _running ? Icons.replay_rounded : Icons.play_arrow_rounded,
              onPressed: _start,
            ),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
            ),
            OutlinedButton.icon(
              onPressed: _records.isEmpty
                  ? null
                  : () => unawaited(_showReport()),
              icon: const Icon(Icons.analytics_rounded),
              label: Text(pickUiText(i18n, zh: '报告', en: 'Report')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: pickUiText(i18n, zh: '双手挑战设置', en: 'Bimanual game settings'),
          subtitle: pickUiText(
            i18n,
            zh: '切换玩法、轮数、节奏强度、同步窗口和长按时长。运行中设置会锁定。',
            en: 'Choose mode, rounds, pace, sync window, and hold duration. Settings lock while running.',
          ),
          initiallyExpanded: true,
          child: _buildSettings(context, i18n),
        ),
        if (_records.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _BimanualRecentPanel(records: _records, i18n: i18n),
        ],
      ],
    );
  }

  Widget _buildSettings(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          pickUiText(i18n, zh: '玩法模式', en: 'Game mode'),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _BimanualMode.values
              .map(
                (mode) => ChoiceChip(
                  label: Text(_modeLabel(i18n, mode)),
                  selected: _mode == mode,
                  onSelected: _running ? null : (_) => _setMode(mode),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        Text(pickUiText(i18n, zh: '轮数', en: 'Rounds')),
        Slider(
          value: _roundCount.toDouble(),
          min: 8,
          max: 30,
          divisions: 11,
          label: '$_roundCount',
          onChanged: _running
              ? null
              : (value) => setState(() => _roundCount = value.round()),
        ),
        Text(pickUiText(i18n, zh: '节奏强度', en: 'Pace level')),
        Slider(
          value: _paceLevel.toDouble(),
          min: 1,
          max: 4,
          divisions: 3,
          label: '$_paceLevel',
          onChanged: _running
              ? null
              : (value) => setState(() => _paceLevel = value.round()),
        ),
        Text(pickUiText(i18n, zh: '同步窗口', en: 'Sync window')),
        Slider(
          value: _syncWindowMs.toDouble(),
          min: 120,
          max: 520,
          divisions: 10,
          label: '$_syncWindowMs ms',
          onChanged: _running
              ? null
              : (value) => setState(() => _syncWindowMs = value.round()),
        ),
        Text(pickUiText(i18n, zh: '长按充能', en: 'Hold charge')),
        Slider(
          value: _holdTargetMs.toDouble(),
          min: 220,
          max: 720,
          divisions: 10,
          label: '$_holdTargetMs ms',
          onChanged: _running
              ? null
              : (value) => setState(() => _holdTargetMs = value.round()),
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
      builder: (context) => _BimanualReportDialog(
        i18n: i18n,
        mode: _modeLabel(i18n, _mode),
        records: List<_BimanualRoundRecord>.unmodifiable(_records),
        score: _score,
        bestCombo: _bestCombo,
        mistakes: _mistakes,
        leftHits: _leftHits,
        rightHits: _rightHits,
        averageMs: _averageMs,
        averageSyncGap: _averageSyncGap,
        accuracy: _accuracy,
      ),
    );
  }
}

class _BimanualStage extends StatelessWidget {
  const _BimanualStage({
    required this.serial,
    required this.cue,
    required this.running,
    required this.done,
    required this.lastCorrect,
    required this.leftHeld,
    required this.rightHeld,
    required this.firstSyncLane,
    required this.modeLabel,
    required this.instruction,
    required this.ruleLabel,
    required this.laneLabel,
    required this.syncWindowMs,
    required this.onTapLeft,
    required this.onTapRight,
    required this.onHoldLeft,
    required this.onHoldRight,
    required this.laneAccent,
  });

  final int serial;
  final _BimanualCue? cue;
  final bool running;
  final bool done;
  final bool? lastCorrect;
  final bool leftHeld;
  final bool rightHeld;
  final _BimanualLane? firstSyncLane;
  final String modeLabel;
  final String instruction;
  final String ruleLabel;
  final String laneLabel;
  final int syncWindowMs;
  final VoidCallback onTapLeft;
  final VoidCallback onTapRight;
  final ValueChanged<bool> onHoldLeft;
  final ValueChanged<bool> onHoldRight;
  final Color Function(_BimanualLane lane) laneAccent;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeLane = cue?.lane;
    final accent = cue == null
        ? _BimanualCoordinationGameState._accent
        : laneAccent(cue!.lane);
    final feedbackText = lastCorrect == null
        ? pickUiText(i18n, zh: '等待输入', en: 'Awaiting input')
        : lastCorrect!
        ? pickUiText(i18n, zh: '命中', en: 'Hit')
        : pickUiText(i18n, zh: '失误', en: 'Miss');
    final feedbackColor = lastCorrect == false
        ? _BimanualCoordinationGameState._dangerAccent
        : accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: <Widget>[
            _HumanPill(text: modeLabel, accent: accent),
            _HumanPill(text: ruleLabel, accent: accent),
            _HumanPill(text: laneLabel, accent: accent),
            _HumanPill(
              text: '$syncWindowMs ms sync',
              accent: colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: Container(
            key: ValueKey<int>(serial),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  accent.withValues(alpha: 0.16),
                  colorScheme.surfaceContainerLowest,
                ],
              ),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            child: Column(
              children: <Widget>[
                Icon(
                  cue?.rule == _BimanualRule.decoy
                      ? Icons.block_rounded
                      : cue?.rule == _BimanualRule.hold
                      ? Icons.touch_app_rounded
                      : cue?.rule == _BimanualRule.mirror
                      ? Icons.compare_arrows_rounded
                      : Icons.ads_click_rounded,
                  color: accent,
                  size: 38,
                ),
                const SizedBox(height: 8),
                Text(
                  instruction,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.16,
                  ),
                ),
                const SizedBox(height: 10),
                _HumanPill(text: feedbackText, accent: feedbackColor),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child: _BimanualPad(
                label: pickUiText(i18n, zh: '左手', en: 'Left'),
                subtitle: firstSyncLane == _BimanualLane.left
                    ? pickUiText(i18n, zh: '已先击', en: 'First strike')
                    : pickUiText(i18n, zh: '蓝色触区', en: 'Blue pad'),
                icon: Icons.arrow_back_rounded,
                accent: _BimanualCoordinationGameState._leftAccent,
                active:
                    running &&
                    (activeLane == _BimanualLane.left ||
                        activeLane == _BimanualLane.both),
                warning:
                    running &&
                    cue?.rule == _BimanualRule.decoy &&
                    activeLane == _BimanualLane.left,
                held: leftHeld,
                enabled: running,
                onTap: onTapLeft,
                onHoldChanged: onHoldLeft,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BimanualPad(
                label: pickUiText(i18n, zh: '右手', en: 'Right'),
                subtitle: firstSyncLane == _BimanualLane.right
                    ? pickUiText(i18n, zh: '已先击', en: 'First strike')
                    : pickUiText(i18n, zh: '金色触区', en: 'Gold pad'),
                icon: Icons.arrow_forward_rounded,
                accent: _BimanualCoordinationGameState._rightAccent,
                active:
                    running &&
                    (activeLane == _BimanualLane.right ||
                        activeLane == _BimanualLane.both),
                warning:
                    running &&
                    cue?.rule == _BimanualRule.decoy &&
                    activeLane == _BimanualLane.right,
                held: rightHeld,
                enabled: running,
                onTap: onTapRight,
                onHoldChanged: onHoldRight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BimanualPad extends StatefulWidget {
  const _BimanualPad({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.active,
    required this.warning,
    required this.held,
    required this.enabled,
    required this.onTap,
    required this.onHoldChanged,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool active;
  final bool warning;
  final bool held;
  final bool enabled;
  final VoidCallback onTap;
  final ValueChanged<bool> onHoldChanged;

  @override
  State<_BimanualPad> createState() => _BimanualPadState();
}

class _BimanualPadState extends State<_BimanualPad> {
  void _release() {
    widget.onHoldChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = widget.warning
        ? _BimanualCoordinationGameState._dangerAccent
        : widget.accent;
    final highlighted = widget.active || widget.held || widget.warning;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: widget.enabled
          ? (_) {
              widget.onHoldChanged(true);
            }
          : null,
      onPointerUp: widget.enabled ? (_) => _release() : null,
      onPointerCancel: widget.enabled ? (_) => _release() : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: widget.held ? 0.97 : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 176),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  highlighted
                      ? accent.withValues(alpha: 0.24)
                      : colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.42,
                        ),
                  colorScheme.surface,
                ],
              ),
              border: Border.all(
                color: highlighted
                    ? accent.withValues(alpha: 0.62)
                    : colorScheme.outlineVariant,
                width: highlighted ? 2 : 1,
              ),
              boxShadow: highlighted
                  ? <BoxShadow>[
                      BoxShadow(
                        color: accent.withValues(alpha: 0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 9),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(widget.icon, size: 42, color: accent),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.warning ? 'Trap' : widget.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: double.infinity,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: accent.withValues(alpha: widget.held ? 0.70 : 0.16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BimanualRecentPanel extends StatelessWidget {
  const _BimanualRecentPanel({required this.records, required this.i18n});

  final List<_BimanualRoundRecord> records;
  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final recent = records.length <= 8
        ? records
        : records.sublist(records.length - 8);
    final theme = Theme.of(context);
    return _HumanPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            pickUiText(i18n, zh: '最近节奏', en: 'Recent rhythm'),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recent
                .map(
                  (record) => _HumanPill(
                    text:
                        '${record.correct ? '+' : '-'}${record.scoreDelta.abs()}',
                    accent: record.correct
                        ? _BimanualCoordinationGameState._accent
                        : _BimanualCoordinationGameState._dangerAccent,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _BimanualReportDialog extends StatelessWidget {
  const _BimanualReportDialog({
    required this.i18n,
    required this.mode,
    required this.records,
    required this.score,
    required this.bestCombo,
    required this.mistakes,
    required this.leftHits,
    required this.rightHits,
    required this.averageMs,
    required this.averageSyncGap,
    required this.accuracy,
  });

  final AppI18n i18n;
  final String mode;
  final List<_BimanualRoundRecord> records;
  final int score;
  final int bestCombo;
  final int mistakes;
  final int leftHits;
  final int rightHits;
  final int averageMs;
  final int averageSyncGap;
  final double accuracy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = score >= records.length * 14 && accuracy >= 0.9
        ? pickUiText(i18n, zh: '左右脑合拍', en: 'Two-hand flow')
        : accuracy < 0.7
        ? pickUiText(i18n, zh: '需要降速稳住', en: 'Slow down first')
        : pickUiText(i18n, zh: '节奏正在成形', en: 'Rhythm forming');
    return AlertDialog(
      title: Text(pickUiText(i18n, zh: '双手协调报告', en: 'Bimanual report')),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _HumanMetricWrap(
                metrics: <(String, String)>[
                  (pickUiText(i18n, zh: '称号', en: 'Title'), title),
                  (pickUiText(i18n, zh: '模式', en: 'Mode'), mode),
                  (pickUiText(i18n, zh: '分数', en: 'Score'), '$score'),
                  (
                    pickUiText(i18n, zh: '准确率', en: 'Accuracy'),
                    '${(accuracy * 100).round()}%',
                  ),
                  (
                    pickUiText(i18n, zh: '最佳连击', en: 'Best combo'),
                    '$bestCombo',
                  ),
                  (pickUiText(i18n, zh: '失误', en: 'Mistakes'), '$mistakes'),
                  (
                    pickUiText(i18n, zh: '平均反应', en: 'Avg reaction'),
                    averageMs == 0 ? '-' : _formatMilliseconds(averageMs),
                  ),
                  (
                    pickUiText(i18n, zh: '同步差', en: 'Sync gap'),
                    averageSyncGap == 0
                        ? '-'
                        : _formatMilliseconds(averageSyncGap),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _HumanPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pickUiText(i18n, zh: '左右手负载', en: 'Hand load'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _BimanualLoadBar(
                      leftHits: leftHits,
                      rightHits: rightHits,
                      i18n: i18n,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _HumanPanel(
                child: Text(
                  mistakes > records.length * 0.25
                      ? pickUiText(
                          i18n,
                          zh: '建议先降低节奏强度，重点练习陷阱不按和同步窗口内的双击。',
                          en: 'Lower the pace first. Practice ignoring trap cues and landing two-pad strikes inside the sync window.',
                        )
                      : pickUiText(
                          i18n,
                          zh: '表现稳定，可以提高节奏强度或切换到脑裂风暴，增加陷阱和长按压力。',
                          en: 'Performance is stable. Raise the pace or switch to Split-brain storm for more traps and hold pressure.',
                        ),
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

class _BimanualLoadBar extends StatelessWidget {
  const _BimanualLoadBar({
    required this.leftHits,
    required this.rightHits,
    required this.i18n,
  });

  final int leftHits;
  final int rightHits;
  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final total = math.max(1, leftHits + rightHits);
    final leftRatio = leftHits / total;
    final rightRatio = rightHits / total;
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 12,
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: (leftRatio * 100).round().clamp(1, 99),
                  child: const ColoredBox(
                    color: _BimanualCoordinationGameState._leftAccent,
                  ),
                ),
                Expanded(
                  flex: (rightRatio * 100).round().clamp(1, 99),
                  child: const ColoredBox(
                    color: _BimanualCoordinationGameState._rightAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '${pickUiText(i18n, zh: '左手', en: 'Left')} $leftHits',
                style: theme.textTheme.labelMedium,
              ),
            ),
            Text(
              '${pickUiText(i18n, zh: '右手', en: 'Right')} $rightHits',
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
      ],
    );
  }
}

class _BimanualBrainSplitGame extends StatefulWidget {
  const _BimanualBrainSplitGame();

  @override
  State<_BimanualBrainSplitGame> createState() =>
      _BimanualBrainSplitGameState();
}

class _BimanualBrainSplitGameState extends State<_BimanualBrainSplitGame> {
  static const Color _accent = BimanualCoordinationTestPage._accent;
  static const Color _rightAccent = BimanualCoordinationTestPage._rightAccent;
  static const Color _traceAccent = BimanualCoordinationTestPage._traceAccent;
  static const Color _bounceAccent = BimanualCoordinationTestPage._bounceAccent;
  static const Color _climbAccent = BimanualCoordinationTestPage._climbAccent;
  static const Color _dangerAccent = BimanualCoordinationTestPage._dangerAccent;
  static const List<int> _timeLimitPresetsMs = <int>[
    0,
    180000,
    300000,
    600000,
    900000,
  ];
  final Stopwatch _roundStopwatch = Stopwatch();
  final List<_BrainSplitRoundRecord> _records = <_BrainSplitRoundRecord>[];
  final _HumanTestViewSignal _viewSignal = _HumanTestViewSignal();

  Timer? _roundTimer;
  Timer? _advanceTimer;
  Timer? _sessionTimer;

  _BimanualMode _mode = _BimanualMode.arcade;
  _BrainSplitRoundPlan? _plan;
  _BrainSplitLaneResult? _leftResult;
  _BrainSplitLaneResult? _rightResult;
  int _roundCount = 12;
  int _timeLimitMs = 0;
  int _roundIndex = 0;
  int _score = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _mistakes = 0;
  int _leftWins = 0;
  int _rightWins = 0;
  int _syncWindowMs = 260;
  int _holdTargetMs = 420;
  int _paceLevel = 2;
  int _serial = 0;
  bool _running = false;
  bool _done = false;
  bool _roundSettled = false;
  bool _fullscreenOpening = false;
  bool _fullscreenAutoLaunched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAutoOpenFullscreen();
    });
  }

  int get _laneSuccessCount => _records.fold<int>(
    0,
    (sum, record) =>
        sum + (record.left.success ? 1 : 0) + (record.right.success ? 1 : 0),
  );

  double get _accuracy {
    if (_records.isEmpty) {
      return 0;
    }
    return _laneSuccessCount / (_records.length * 2);
  }

  int get _averageMs {
    final successfulLaneTimes = <int>[
      for (final record in _records) ...<int>[
        if (record.left.success) record.left.milliseconds,
        if (record.right.success) record.right.milliseconds,
      ],
    ];
    if (successfulLaneTimes.isEmpty) {
      return 0;
    }
    final total = successfulLaneTimes.fold<int>(0, (sum, value) => sum + value);
    return (total / successfulLaneTimes.length).round();
  }

  int get _averageSyncGap {
    final items = _records
        .where((item) => item.left.success && item.right.success)
        .toList(growable: false);
    if (items.isEmpty) {
      return 0;
    }
    final total = items.fold<int>(0, (sum, item) => sum + item.syncGapMs);
    return (total / items.length).round();
  }

  @override
  void dispose() {
    _cancelTimers();
    _cancelSessionTimer();
    _roundStopwatch
      ..stop()
      ..reset();
    _viewSignal.dispose();
    super.dispose();
  }

  void _notifyView() {
    _viewSignal.markNeedsBuild();
  }

  void _updateView(VoidCallback update) {
    setState(update);
    _notifyView();
  }

  void _cancelTimers() {
    _roundTimer?.cancel();
    _advanceTimer?.cancel();
  }

  void _cancelSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  void _maybeAutoOpenFullscreen() {
    if (!mounted || _fullscreenAutoLaunched || _fullscreenOpening) {
      return;
    }
    if (kIsWeb || const bool.fromEnvironment('FLUTTER_TEST')) {
      return;
    }
    _fullscreenAutoLaunched = true;
    unawaited(_openFullscreen(autoStart: true));
  }

  void _setMode(_BimanualMode mode) {
    if (_running || _mode == mode) {
      return;
    }
    _updateView(() {
      _mode = mode;
      _done = false;
    });
  }

  void _start(BuildContext context) {
    _cancelTimers();
    _cancelSessionTimer();
    _roundStopwatch
      ..stop()
      ..reset();
    _updateView(() {
      _records.clear();
      _plan = null;
      _leftResult = null;
      _rightResult = null;
      _roundIndex = 0;
      _score = 0;
      _combo = 0;
      _bestCombo = 0;
      _mistakes = 0;
      _leftWins = 0;
      _rightWins = 0;
      _running = true;
      _done = false;
      _roundSettled = false;
      _serial += 1;
    });
    _beginRound(context);
    if (_timeLimitMs > 0) {
      _sessionTimer = Timer(Duration(milliseconds: _timeLimitMs), () {
        if (!mounted || !_running) {
          return;
        }
        _expireSession(context);
      });
    }
  }

  void _reset() {
    _cancelTimers();
    _cancelSessionTimer();
    _roundStopwatch
      ..stop()
      ..reset();
    _updateView(() {
      _records.clear();
      _plan = null;
      _leftResult = null;
      _rightResult = null;
      _roundIndex = 0;
      _score = 0;
      _combo = 0;
      _bestCombo = 0;
      _mistakes = 0;
      _leftWins = 0;
      _rightWins = 0;
      _running = false;
      _done = false;
      _roundSettled = false;
      _serial += 1;
    });
  }

  Future<void> _openFullscreen({required bool autoStart}) async {
    if (_fullscreenOpening) {
      return;
    }
    _fullscreenOpening = true;
    try {
      await _enterHumanTestLandscapeFullscreen();
      if (!mounted) {
        await _exitHumanTestFullscreen();
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) =>
              _BrainSplitFullscreenView(state: this, autoStart: autoStart),
        ),
      );
    } finally {
      await _exitHumanTestFullscreen();
      _fullscreenOpening = false;
      if (mounted) {
        _updateView(() {});
      }
    }
  }

  void _stopChallenge(BuildContext context) {
    if (!_running) {
      return;
    }
    if (_roundSettled) {
      _finish();
      return;
    }
    _settleRound(context, timeout: true, finishImmediately: true);
  }

  void _beginRound(BuildContext context) {
    if (!mounted || !_running) {
      return;
    }
    if (_roundIndex >= _roundCount) {
      _finish(reportContext: context);
      return;
    }
    _cancelTimers();
    final plan = _buildRoundPlan(context);
    _updateView(() {
      _plan = plan;
      _leftResult = null;
      _rightResult = null;
      _roundSettled = false;
      _serial += 1;
      _roundStopwatch
        ..reset()
        ..start();
    });
    _roundTimer = Timer(Duration(milliseconds: plan.durationMs), () {
      if (!mounted || !_running || _roundSettled) {
        return;
      }
      _settleRound(context, timeout: true);
    });
  }

  _BrainSplitRoundPlan _buildRoundPlan(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final baseDuration = switch (_paceLevel) {
      1 => 17000,
      2 => 13600,
      3 => 11200,
      _ => 9400,
    };
    final pressure = (_roundIndex / math.max(1, _roundCount - 1)).clamp(
      0.0,
      1.0,
    );
    final duration = (baseDuration - pressure * 3400)
        .round()
        .clamp(7600, 19000)
        .toInt();
    final swapHands = _roundIndex.isOdd;

    final left = switch (_mode) {
      _BimanualMode.arcade =>
        swapHands
            ? _buildBounceSpec(context, _BimanualSide.left, _roundIndex + 17)
            : _buildTraceSpec(context, _BimanualSide.left, _roundIndex + 11),
      _BimanualMode.splitBrain =>
        swapHands
            ? _buildClimbSpec(context, _BimanualSide.left, _roundIndex + 21)
            : _buildBounceSpec(context, _BimanualSide.left, _roundIndex + 13),
      _BimanualMode.conductor =>
        swapHands
            ? _buildClimbSpec(context, _BimanualSide.left, _roundIndex + 31)
            : _buildTraceSpec(context, _BimanualSide.left, _roundIndex + 23),
    };

    final right = switch (_mode) {
      _BimanualMode.arcade =>
        swapHands
            ? _buildTraceSpec(context, _BimanualSide.right, _roundIndex + 29)
            : _buildBounceSpec(context, _BimanualSide.right, _roundIndex + 19),
      _BimanualMode.splitBrain =>
        swapHands
            ? _buildBounceSpec(context, _BimanualSide.right, _roundIndex + 25)
            : _buildClimbSpec(context, _BimanualSide.right, _roundIndex + 15),
      _BimanualMode.conductor =>
        swapHands
            ? _buildTraceSpec(context, _BimanualSide.right, _roundIndex + 37)
            : _buildClimbSpec(context, _BimanualSide.right, _roundIndex + 27),
    };

    return _BrainSplitRoundPlan(
      label: _pairLabel(i18n, left.type, right.type),
      left: left,
      right: right,
      durationMs: duration,
    );
  }

  _BrainSplitTaskSpec _buildTraceSpec(
    BuildContext context,
    _BimanualSide side,
    int seed,
  ) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final shapeNames = <String>[
      pickUiText(i18n, zh: 'A', en: 'A'),
      pickUiText(i18n, zh: 'B', en: 'B'),
      pickUiText(i18n, zh: 'C', en: 'C'),
      pickUiText(i18n, zh: 'D', en: 'D'),
    ];
    final shape = shapeNames[seed % shapeNames.length];
    final sideLabel = _sideLabel(i18n, side);
    return _BrainSplitTaskSpec(
      type: _BimanualTaskType.trace,
      title: pickUiText(
        i18n,
        zh: '$sideLabel 画图 $shape',
        en: '$sideLabel Trace $shape',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '沿着节点顺序拖动指尖，把图形 $shape 一笔连完。',
        en: 'Drag your finger through the checkpoints and finish shape $shape in one line.',
      ),
      goalText: pickUiText(i18n, zh: '画完形状 $shape', en: 'Finish shape $shape'),
      accent: _traceAccent,
      seed: seed,
    );
  }

  _BrainSplitTaskSpec _buildBounceSpec(
    BuildContext context,
    _BimanualSide side,
    int seed,
  ) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final sideLabel = _sideLabel(i18n, side);
    final rallies = 5 + (seed % 2);
    return _BrainSplitTaskSpec(
      type: _BimanualTaskType.bounce,
      title: pickUiText(i18n, zh: '$sideLabel 弹球', en: '$sideLabel Pinball'),
      subtitle: pickUiText(
        i18n,
        zh: '拖动挡板托住小球，连续稳住 $rallies 次回弹。',
        en: 'Drag the paddle to keep the ball alive for $rallies rallies.',
      ),
      goalText: pickUiText(
        i18n,
        zh: '稳住 $rallies 次回弹',
        en: 'Keep $rallies rallies',
      ),
      accent: _bounceAccent,
      seed: seed,
    );
  }

  _BrainSplitTaskSpec _buildClimbSpec(
    BuildContext context,
    _BimanualSide side,
    int seed,
  ) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final sideLabel = _sideLabel(i18n, side);
    final steps = 6 + (seed % 2);
    return _BrainSplitTaskSpec(
      type: _BimanualTaskType.climb,
      title: pickUiText(i18n, zh: '$sideLabel 楼梯', en: '$sideLabel Stair run'),
      subtitle: pickUiText(
        i18n,
        zh: '短按迈一步，长按充能跳过管道，冲到第 $steps 级。',
        en: 'Tap to step, hold to charge over pipe barriers, and reach step $steps.',
      ),
      goalText: pickUiText(i18n, zh: '冲上 $steps 级楼梯', en: 'Reach step $steps'),
      accent: _climbAccent,
      seed: seed,
    );
  }

  String _pairLabel(
    AppI18n i18n,
    _BimanualTaskType left,
    _BimanualTaskType right,
  ) {
    final leftLabel = _taskLabel(i18n, left);
    final rightLabel = _taskLabel(i18n, right);
    return pickUiText(
      i18n,
      zh: '$leftLabel / $rightLabel',
      en: '$leftLabel / $rightLabel',
    );
  }

  String _taskLabel(AppI18n i18n, _BimanualTaskType type) {
    return switch (type) {
      _BimanualTaskType.trace => pickUiText(i18n, zh: '画图', en: 'Trace'),
      _BimanualTaskType.bounce => pickUiText(i18n, zh: '弹球', en: 'Bounce'),
      _BimanualTaskType.climb => pickUiText(i18n, zh: '楼梯', en: 'Climb'),
    };
  }

  String _sideLabel(AppI18n i18n, _BimanualSide side) {
    return switch (side) {
      _BimanualSide.left => pickUiText(i18n, zh: '左侧', en: 'Left'),
      _BimanualSide.right => pickUiText(i18n, zh: '右侧', en: 'Right'),
    };
  }

  void _recordLaneResult(
    BuildContext context,
    _BimanualSide side,
    _BrainSplitLaneResult result,
  ) {
    if (!_running || _roundSettled) {
      return;
    }
    _updateView(() {
      if (side == _BimanualSide.left) {
        _leftResult = result;
      } else {
        _rightResult = result;
      }
    });
    if (!result.success) {
      _settleRound(context, timeout: false);
      return;
    }
    if (_leftResult != null && _rightResult != null) {
      _settleRound(context, timeout: false);
    }
  }

  void _expireSession(BuildContext context) {
    if (!mounted || !_running) {
      return;
    }
    if (_roundSettled) {
      _finish(reportContext: context);
      return;
    }
    _settleRound(context, timeout: true, finishImmediately: true);
  }

  void _settleRound(
    BuildContext context, {
    required bool timeout,
    bool finishImmediately = false,
  }) {
    if (!_running || _roundSettled) {
      return;
    }
    _roundSettled = true;
    _cancelTimers();
    _roundStopwatch.stop();
    final plan = _plan;
    if (plan == null) {
      return;
    }
    final elapsed = math.max(1, _roundStopwatch.elapsedMilliseconds);
    final left =
        _leftResult ??
        _missingLaneResult(
          success: false,
          milliseconds: elapsed,
          detail: timeout
              ? 'timeout'
              : pickUiText(
                  AppI18n(Localizations.localeOf(context).languageCode),
                  zh: '未完成',
                  en: 'Incomplete',
                ),
        );
    final right =
        _rightResult ??
        _missingLaneResult(
          success: false,
          milliseconds: elapsed,
          detail: timeout
              ? 'timeout'
              : pickUiText(
                  AppI18n(Localizations.localeOf(context).languageCode),
                  zh: '未完成',
                  en: 'Incomplete',
                ),
        );
    final bothSuccess = left.success && right.success;
    final syncGapMs = bothSuccess
        ? (left.milliseconds - right.milliseconds).abs()
        : 0;
    final syncBonus = bothSuccess && syncGapMs <= _syncWindowMs
        ? (10 - (syncGapMs / 35).round()).clamp(0, 10).toInt()
        : 0;
    final roundScore = left.scoreDelta + right.scoreDelta + syncBonus;
    _updateView(() {
      _records.add(
        _BrainSplitRoundRecord(
          plan: plan,
          left: left,
          right: right,
          roundMilliseconds: elapsed,
          scoreDelta: roundScore,
          syncGapMs: syncGapMs,
        ),
      );
      _score = math.max(0, _score + roundScore);
      if (bothSuccess) {
        _combo += 1;
        _bestCombo = math.max(_bestCombo, _combo);
      } else {
        _combo = 0;
        _mistakes += (left.success ? 0 : 1) + (right.success ? 0 : 1);
      }
      if (left.success) {
        _leftWins += 1;
      }
      if (right.success) {
        _rightWins += 1;
      }
      _roundIndex += 1;
      _done = finishImmediately || _roundIndex >= _roundCount;
      _running = !_done;
      _plan = null;
      _leftResult = null;
      _rightResult = null;
      _serial += 1;
    });
    HapticFeedback.lightImpact();
    if (_done) {
      _finish(reportContext: context);
      return;
    }
    _advanceTimer = Timer(const Duration(milliseconds: 540), () {
      if (!mounted) {
        return;
      }
      if (_done) {
        _finish(reportContext: context);
      } else {
        _beginRound(context);
      }
    });
  }

  _BrainSplitLaneResult _missingLaneResult({
    required bool success,
    required int milliseconds,
    required String detail,
  }) {
    return _BrainSplitLaneResult(
      success: success,
      milliseconds: milliseconds,
      scoreDelta: success ? 0 : -6,
      detail: detail,
    );
  }

  void _finish({BuildContext? reportContext}) {
    _cancelTimers();
    _cancelSessionTimer();
    _roundStopwatch
      ..stop()
      ..reset();
    _updateView(() {
      _running = false;
      _done = true;
    });
    unawaited(_showReport(reportContext));
  }

  String _modeLabel(AppI18n i18n, _BimanualMode mode) {
    return switch (mode) {
      _BimanualMode.arcade => pickUiText(i18n, zh: '街机混合', en: 'Arcade mix'),
      _BimanualMode.splitBrain => pickUiText(
        i18n,
        zh: '脑裂风暴',
        en: 'Split-brain storm',
      ),
      _BimanualMode.conductor => pickUiText(
        i18n,
        zh: '节奏指挥',
        en: 'Rhythm conductor',
      ),
    };
  }

  String _timeLimitLabel(AppI18n i18n, int limitMs) {
    return switch (limitMs) {
      0 => pickUiText(i18n, zh: '无限', en: 'Unlimited'),
      180000 => pickUiText(i18n, zh: '3 分钟', en: '3 min'),
      300000 => pickUiText(i18n, zh: '5 分钟', en: '5 min'),
      600000 => pickUiText(i18n, zh: '10 分钟', en: '10 min'),
      900000 => pickUiText(i18n, zh: '15 分钟', en: '15 min'),
      _ => _formatMilliseconds(limitMs),
    };
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final plan = _plan;
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
              pickUiText(i18n, zh: '时长', en: 'Time limit'),
              _timeLimitLabel(i18n, _timeLimitMs),
            ),
            (pickUiText(i18n, zh: '分数', en: 'Score'), '$_score'),
            (pickUiText(i18n, zh: '连击', en: 'Combo'), '$_combo'),
            (
              pickUiText(i18n, zh: '准确率', en: 'Accuracy'),
              _records.isEmpty ? '-' : '${(_accuracy * 100).round()}%',
            ),
            (
              pickUiText(i18n, zh: '平均用时', en: 'Avg lane time'),
              _averageMs == 0 ? '-' : _formatMilliseconds(_averageMs),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _HumanPill(text: _modeLabel(i18n, _mode), accent: _accent),
                  _HumanPill(
                    text: plan == null ? '-' : plan.label,
                    accent: plan == null ? _accent : _traceAccent,
                  ),
                  _HumanPill(
                    text:
                        '${pickUiText(i18n, zh: '同步窗', en: 'Sync')} $_syncWindowMs ms',
                    accent: _rightAccent,
                  ),
                  _HumanPill(
                    text:
                        '${pickUiText(i18n, zh: '充能', en: 'Charge')} $_holdTargetMs ms',
                    accent: _climbAccent,
                  ),
                  _HumanPill(
                    text: _timeLimitLabel(i18n, _timeLimitMs),
                    accent: _dangerAccent,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                plan == null
                    ? pickUiText(
                        i18n,
                        zh: '手机默认会先进入全屏横屏训练；设置、重置和报告都收在菜单里。',
                        en: 'Mobile opens fullscreen landscape first; settings, reset, and reports live in the menu.',
                      )
                    : pickUiText(
                        i18n,
                        zh: '${plan.left.goalText}，${plan.right.goalText}。两侧都完成后可获得同步奖励，全屏里操作更顺手。',
                        en: '${plan.left.goalText}. ${plan.right.goalText}. Finish both sides to earn the sync bonus; fullscreen keeps the controls usable.',
                      ),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.35),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _HumanActionButton(
              label: _fullscreenOpening
                  ? pickUiText(i18n, zh: '正在打开', en: 'Opening')
                  : _running
                  ? pickUiText(i18n, zh: '返回全屏', en: 'Return fullscreen')
                  : pickUiText(i18n, zh: '全屏开始', en: 'Fullscreen start'),
              icon: Icons.fullscreen_rounded,
              onPressed: _fullscreenOpening
                  ? null
                  : () => unawaited(_openFullscreen(autoStart: !_running)),
            ),
            _BrainSplitActionMenuButton(
              state: this,
              i18n: i18n,
              fullscreen: false,
            ),
          ],
        ),
        if (_records.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _BrainSplitRecentPanel(records: _records, i18n: i18n),
        ],
      ],
    );
  }

  Widget _buildSettings(
    BuildContext context,
    AppI18n i18n, {
    VoidCallback? onChanged,
  }) {
    final theme = Theme.of(context);
    void applySetting(VoidCallback update) {
      _updateView(update);
      onChanged?.call();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          pickUiText(i18n, zh: '玩法配对', en: 'Pair mode'),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _BimanualMode.values
              .map(
                (mode) => ChoiceChip(
                  label: Text(_modeLabel(i18n, mode)),
                  selected: _mode == mode,
                  onSelected: _running
                      ? null
                      : (_) {
                          _setMode(mode);
                          onChanged?.call();
                        },
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        Text(pickUiText(i18n, zh: '轮数', en: 'Rounds')),
        Slider(
          value: _roundCount.toDouble(),
          min: 8,
          max: 30,
          divisions: 11,
          label: '$_roundCount',
          onChanged: _running
              ? null
              : (value) => applySetting(() => _roundCount = value.round()),
        ),
        const SizedBox(height: 12),
        Text(pickUiText(i18n, zh: '计时时长', en: 'Time limit')),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _timeLimitPresetsMs
              .map(
                (limitMs) => ChoiceChip(
                  label: Text(_timeLimitLabel(i18n, limitMs)),
                  selected: _timeLimitMs == limitMs,
                  onSelected: _running
                      ? null
                      : (_) => applySetting(() => _timeLimitMs = limitMs),
                ),
              )
              .toList(growable: false),
        ),
        Text(pickUiText(i18n, zh: '节奏强度', en: 'Pace level')),
        Slider(
          value: _paceLevel.toDouble(),
          min: 1,
          max: 4,
          divisions: 3,
          label: '$_paceLevel',
          onChanged: _running
              ? null
              : (value) => applySetting(() => _paceLevel = value.round()),
        ),
        Text(pickUiText(i18n, zh: '同步窗', en: 'Sync window')),
        Slider(
          value: _syncWindowMs.toDouble(),
          min: 120,
          max: 520,
          divisions: 10,
          label: '$_syncWindowMs ms',
          onChanged: _running
              ? null
              : (value) => applySetting(() => _syncWindowMs = value.round()),
        ),
        Text(pickUiText(i18n, zh: '充能时长', en: 'Charge window')),
        Slider(
          value: _holdTargetMs.toDouble(),
          min: 220,
          max: 720,
          divisions: 10,
          label: '$_holdTargetMs ms',
          onChanged: _running
              ? null
              : (value) => applySetting(() => _holdTargetMs = value.round()),
        ),
      ],
    );
  }

  Future<void> _showReport([BuildContext? dialogContext]) async {
    if (!mounted || _records.isEmpty) {
      return;
    }
    final targetContext = dialogContext ?? context;
    final i18n = AppI18n(Localizations.localeOf(targetContext).languageCode);
    await showDialog<void>(
      context: targetContext,
      builder: (context) => _BrainSplitReportDialog(
        i18n: i18n,
        mode: _modeLabel(i18n, _mode),
        records: List<_BrainSplitRoundRecord>.unmodifiable(_records),
        score: _score,
        bestCombo: _bestCombo,
        mistakes: _mistakes,
        leftWins: _leftWins,
        rightWins: _rightWins,
        averageMs: _averageMs,
        averageSyncGap: _averageSyncGap,
        accuracy: _accuracy,
      ),
    );
  }

  Future<void> _showSettingsDialog(BuildContext context) async {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: Text(
            pickUiText(i18n, zh: '双手脑裂设置', en: 'Split-brain settings'),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return SingleChildScrollView(
                  child: _buildSettings(
                    dialogContext,
                    i18n,
                    onChanged: () => setDialogState(() {}),
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                pickUiText(i18n, zh: '关闭', en: 'Close'),
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BrainSplitActionMenuButton extends StatelessWidget {
  const _BrainSplitActionMenuButton({
    required this.state,
    required this.i18n,
    required this.fullscreen,
  });

  final _BimanualBrainSplitGameState state;
  final AppI18n i18n;
  final bool fullscreen;

  @override
  Widget build(BuildContext context) {
    final reportEnabled = state._records.isNotEmpty;
    final actionKey = fullscreen
        ? const ValueKey<String>('brain_split_fullscreen_menu_button')
        : const ValueKey<String>('brain_split_menu_button');
    final startStopAction = fullscreen && !state._running
        ? PopupMenuItem<_BrainSplitFullscreenAction>(
            value: _BrainSplitFullscreenAction.stop,
            enabled: false,
            child: Text(pickUiText(i18n, zh: '挑战进行中', en: 'Running')),
          )
        : null;
    return PopupMenuButton<_BrainSplitFullscreenAction>(
      key: actionKey,
      tooltip: pickUiText(i18n, zh: '更多', en: 'More'),
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (action) {
        switch (action) {
          case _BrainSplitFullscreenAction.settings:
            unawaited(state._showSettingsDialog(context));
            break;
          case _BrainSplitFullscreenAction.reset:
            state._reset();
            break;
          case _BrainSplitFullscreenAction.report:
            unawaited(state._showReport(context));
            break;
          case _BrainSplitFullscreenAction.stop:
            if (state._running) {
              state._stopChallenge(context);
            }
            break;
          case _BrainSplitFullscreenAction.exit:
            Navigator.of(context).pop();
            break;
        }
      },
      itemBuilder: (context) => <PopupMenuEntry<_BrainSplitFullscreenAction>>[
        PopupMenuItem<_BrainSplitFullscreenAction>(
          value: _BrainSplitFullscreenAction.settings,
          child: Text(pickUiText(i18n, zh: '设置', en: 'Settings')),
        ),
        PopupMenuItem<_BrainSplitFullscreenAction>(
          value: _BrainSplitFullscreenAction.reset,
          child: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
        ),
        if (reportEnabled)
          PopupMenuItem<_BrainSplitFullscreenAction>(
            value: _BrainSplitFullscreenAction.report,
            child: Text(pickUiText(i18n, zh: '报告', en: 'Report')),
          ),
        if (fullscreen ||
            state._running) ...<PopupMenuEntry<_BrainSplitFullscreenAction>>[
          const PopupMenuDivider(),
          ?startStopAction,
          PopupMenuItem<_BrainSplitFullscreenAction>(
            value: _BrainSplitFullscreenAction.stop,
            enabled: state._running,
            child: Text(pickUiText(i18n, zh: '结束挑战', en: 'Stop challenge')),
          ),
          PopupMenuItem<_BrainSplitFullscreenAction>(
            value: _BrainSplitFullscreenAction.exit,
            child: Text(pickUiText(i18n, zh: '退出全屏', en: 'Exit fullscreen')),
          ),
        ],
      ],
    );
  }
}

class _BrainSplitFullscreenView extends StatefulWidget {
  const _BrainSplitFullscreenView({
    required this.state,
    required this.autoStart,
  });

  final _BimanualBrainSplitGameState state;
  final bool autoStart;

  @override
  State<_BrainSplitFullscreenView> createState() =>
      _BrainSplitFullscreenViewState();
}

class _BrainSplitFullscreenViewState extends State<_BrainSplitFullscreenView>
    with SingleTickerProviderStateMixin {
  bool _statusExpanded = false;

  _BimanualBrainSplitGameState get state => widget.state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (widget.autoStart || !state._running) {
        state._start(context);
      }
    });
  }

  void _toggleStatus() {
    setState(() => _statusExpanded = !_statusExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return Scaffold(
      key: const ValueKey<String>('brain_split_fullscreen_view'),
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[state._viewSignal]),
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final surfaceSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              final compact = surfaceSize.shortestSide < 380;
              final topInset = MediaQuery.paddingOf(context).top;
              final stageTopPadding = topInset + (compact ? 58 : 70);
              return Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: _BrainSplitStage(
                      key: ValueKey<String>(
                        'brain_split_stage_${state._serial}',
                      ),
                      plan: state._plan,
                      running: state._running,
                      done: state._done,
                      syncWindowMs: state._syncWindowMs,
                      holdTargetMs: state._holdTargetMs,
                      roundToken: state._serial,
                      onLaneResult: (side, result) =>
                          state._recordLaneResult(context, side, result),
                      modeLabel: state._modeLabel(i18n, state._mode),
                      fullscreen: true,
                      activePadding: EdgeInsets.fromLTRB(
                        compact ? 8 : 12,
                        stageTopPadding,
                        compact ? 8 : 12,
                        compact ? 8 : 12,
                      ),
                    ),
                  ),
                  Positioned(
                    top: compact ? 6 : 8,
                    left: compact ? 6 : 8,
                    right: compact ? 6 : 8,
                    child: SafeArea(
                      bottom: false,
                      child: _BrainSplitFullscreenTopBar(
                        state: state,
                        i18n: i18n,
                        compact: compact,
                        expanded: _statusExpanded,
                        onToggleStatus: _toggleStatus,
                        onExit: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _BrainSplitFullscreenTopBar extends StatelessWidget {
  const _BrainSplitFullscreenTopBar({
    required this.state,
    required this.i18n,
    required this.compact,
    required this.expanded,
    required this.onToggleStatus,
    required this.onExit,
  });

  final _BimanualBrainSplitGameState state;
  final AppI18n i18n;
  final bool compact;
  final bool expanded;
  final VoidCallback onToggleStatus;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _HumanTestFullscreenIconButton(
              onPressed: onExit,
              icon: Icons.close_rounded,
              tooltip: MaterialLocalizations.of(context).closeButtonLabel,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BrainSplitFullscreenStatusPeek(
                state: state,
                i18n: i18n,
                compact: compact,
                expanded: expanded,
                onToggle: onToggleStatus,
              ),
            ),
            const SizedBox(width: 8),
            _BrainSplitFullscreenSessionActions(state: state, i18n: i18n),
          ],
        ),
        if (expanded) ...<Widget>[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: _BrainSplitFullscreenStatusPanel(
              state: state,
              i18n: i18n,
              compact: compact,
            ),
          ),
        ],
      ],
    );
  }
}

class _BrainSplitFullscreenStatusPeek extends StatelessWidget {
  const _BrainSplitFullscreenStatusPeek({
    required this.state,
    required this.i18n,
    required this.compact,
    required this.expanded,
    required this.onToggle,
  });

  final _BimanualBrainSplitGameState state;
  final AppI18n i18n;
  final bool compact;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final planLabel =
        state._plan?.label ?? pickUiText(i18n, zh: '准备中', en: 'Preparing');
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 300 : 540),
      child: _HumanTestFullscreenPanel(
        key: const ValueKey<String>('brain_split_fullscreen_status_peek'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onToggle,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: _BimanualBrainSplitGameState._accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  pickUiText(
                    i18n,
                    zh: '${state._roundIndex}/${state._roundCount} · $planLabel · ${state._score}',
                    en: '${state._roundIndex}/${state._roundCount} · $planLabel · ${state._score}',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
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

class _BrainSplitFullscreenStatusPanel extends StatelessWidget {
  const _BrainSplitFullscreenStatusPanel({
    required this.state,
    required this.i18n,
    required this.compact,
  });

  final _BimanualBrainSplitGameState state;
  final AppI18n i18n;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 300 : 540),
      child: _HumanTestFullscreenPanel(
        key: const ValueKey<String>('brain_split_fullscreen_status_panel'),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 8 : 10,
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _HumanTestFullscreenMetric(
              label: pickUiText(i18n, zh: '模式', en: 'Mode'),
              value: state._modeLabel(i18n, state._mode),
              accent: _BimanualBrainSplitGameState._accent,
            ),
            _HumanTestFullscreenMetric(
              label: pickUiText(i18n, zh: '进度', en: 'Progress'),
              value: '${state._roundIndex}/${state._roundCount}',
              accent: _BimanualBrainSplitGameState._traceAccent,
            ),
            _HumanTestFullscreenMetric(
              label: pickUiText(i18n, zh: '分数', en: 'Score'),
              value: '${state._score}',
              accent: _BimanualBrainSplitGameState._rightAccent,
            ),
            _HumanTestFullscreenMetric(
              label: pickUiText(i18n, zh: '连击', en: 'Combo'),
              value: '${state._combo}',
              accent: _BimanualBrainSplitGameState._climbAccent,
            ),
            if (!compact)
              _HumanTestFullscreenMetric(
                label: pickUiText(i18n, zh: '准确率', en: 'Accuracy'),
                value: state._records.isEmpty
                    ? '-'
                    : '${(state._accuracy * 100).round()}%',
                accent: _BimanualBrainSplitGameState._dangerAccent,
              ),
          ],
        ),
      ),
    );
  }
}

class _BrainSplitFullscreenSessionActions extends StatelessWidget {
  const _BrainSplitFullscreenSessionActions({
    required this.state,
    required this.i18n,
  });

  final _BimanualBrainSplitGameState state;
  final AppI18n i18n;

  Future<void> _showSettings(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => _BrainSplitFullscreenSettingsDialog(state: state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportEnabled = state._records.isNotEmpty;
    return _HumanTestFullscreenPanel(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            key: const ValueKey<String>('brain_split_fullscreen_start_button'),
            tooltip: state._running
                ? pickUiText(i18n, zh: '结束', en: 'Finish')
                : pickUiText(i18n, zh: '开始', en: 'Start'),
            onPressed: state._running
                ? () => state._stopChallenge(context)
                : () => state._start(context),
            icon: Icon(
              state._running ? Icons.stop_rounded : Icons.play_arrow_rounded,
            ),
          ),
          IconButton(
            key: const ValueKey<String>('brain_split_fullscreen_reset_button'),
            tooltip: pickUiText(i18n, zh: '重置', en: 'Reset'),
            onPressed: () {
              state._reset();
              state._start(context);
            },
            icon: const Icon(Icons.restart_alt_rounded),
          ),
          IconButton(
            key: const ValueKey<String>('brain_split_fullscreen_settings_button'),
            tooltip: pickUiText(i18n, zh: '设置', en: 'Settings'),
            onPressed: () => _showSettings(context),
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            key: const ValueKey<String>('brain_split_fullscreen_report_button'),
            tooltip: pickUiText(i18n, zh: '报告', en: 'Report'),
            onPressed: reportEnabled ? () => state._showReport(context) : null,
            icon: const Icon(Icons.assessment_rounded),
          ),
          _BrainSplitActionMenuButton(
            state: state,
            i18n: i18n,
            fullscreen: true,
          ),
        ],
      ),
    );
  }
}

class _BrainSplitFullscreenSettingsDialog extends StatelessWidget {
  const _BrainSplitFullscreenSettingsDialog({required this.state});

  final _BimanualBrainSplitGameState state;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final mediaSize = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(420.0, math.max(280.0, mediaSize.width - 32));
    return AlertDialog(
      key: const ValueKey<String>('brain_split_fullscreen_settings_dialog'),
      title: Text(pickUiText(i18n, zh: '双手协调设置', en: 'Bimanual settings')),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: _HumanSettingsSection(
            title: pickUiText(i18n, zh: '脑裂挑战设置', en: 'Split-brain settings'),
            subtitle: pickUiText(
              i18n,
              zh: '进行中参数会锁定；重置后立即按新设置开局。',
              en: 'Running sessions lock settings; reset to restart with new values.',
            ),
            initiallyExpanded: true,
            child: StatefulBuilder(
              builder: (context, setDialogState) => state._buildSettings(
                context,
                i18n,
                onChanged: () => setDialogState(() {}),
              ),
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}

class _BrainSplitStage extends StatelessWidget {
  const _BrainSplitStage({
    super.key,
    required this.plan,
    required this.running,
    required this.done,
    required this.syncWindowMs,
    required this.holdTargetMs,
    required this.roundToken,
    required this.onLaneResult,
    required this.modeLabel,
    this.fullscreen = false,
    this.activePadding = EdgeInsets.zero,
  });

  final _BrainSplitRoundPlan? plan;
  final bool running;
  final bool done;
  final int syncWindowMs;
  final int holdTargetMs;
  final int roundToken;
  final void Function(_BimanualSide side, _BrainSplitLaneResult result)
  onLaneResult;
  final String modeLabel;
  final bool fullscreen;
  final EdgeInsets activePadding;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentPlan = plan;
    final goalText = currentPlan == null
        ? pickUiText(
            i18n,
            zh: '正在准备左右两侧任务。',
            en: 'Preparing left and right tasks.',
          )
        : pickUiText(
            i18n,
            zh: '${currentPlan.left.goalText}，${currentPlan.right.goalText}。',
            en: '${currentPlan.left.goalText}. ${currentPlan.right.goalText}.',
          );
    final stageContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: <Widget>[
            _HumanPill(
              text: modeLabel,
              accent: _BimanualBrainSplitGameState._accent,
            ),
            _HumanPill(
              text:
                  plan?.label ??
                  pickUiText(i18n, zh: '等待配对', en: 'Waiting for pair'),
              accent: plan == null
                  ? _BimanualBrainSplitGameState._accent
                  : _BimanualBrainSplitGameState._traceAccent,
            ),
            _HumanPill(
              text: '$syncWindowMs ms sync',
              accent: colorScheme.primary,
            ),
            _HumanPill(
              text: '$holdTargetMs ms charge',
              accent: _BimanualBrainSplitGameState._climbAccent,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          goalText,
          maxLines: fullscreen ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: (fullscreen ? theme.textTheme.labelLarge : theme.textTheme.bodySmall)
              ?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
                fontWeight: fullscreen ? FontWeight.w800 : null,
              ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 380;
              final laneGap = compact ? 8.0 : 12.0;
              final left = KeyedSubtree(
                key: const ValueKey<String>('brain_split_left_slot'),
                child: _BrainSplitLaneView(
                  key: ValueKey<String>('brain_split_left_$roundToken'),
                  side: _BimanualSide.left,
                  spec: plan?.left,
                  running: running,
                  holdTargetMs: holdTargetMs,
                  onCompleted: (result) =>
                      onLaneResult(_BimanualSide.left, result),
                  fullscreen: fullscreen,
                ),
              );
              final right = KeyedSubtree(
                key: const ValueKey<String>('brain_split_right_slot'),
                child: _BrainSplitLaneView(
                  key: ValueKey<String>('brain_split_right_$roundToken'),
                  side: _BimanualSide.right,
                  spec: plan?.right,
                  running: running,
                  holdTargetMs: holdTargetMs,
                  onCompleted: (result) =>
                      onLaneResult(_BimanualSide.right, result),
                  fullscreen: fullscreen,
                ),
              );
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(child: left),
                  SizedBox(width: laneGap),
                  Expanded(child: right),
                ],
              );
            },
          ),
        ),
        if (done) ...<Widget>[
          const SizedBox(height: 10),
          _HumanPill(
            text: pickUiText(i18n, zh: '本轮已结束', en: 'Round complete'),
            accent: BimanualCoordinationTestPage._dangerAccent,
          ),
        ],
      ],
    );
    if (fullscreen) {
      return Padding(
        padding: activePadding,
        child: _BrainSplitFullscreenStageSurface(child: stageContent),
      );
    }
    return SizedBox(
      height: 430,
      child: _HumanPanel(padding: const EdgeInsets.all(14), child: stageContent),
    );
  }
}

class _BrainSplitFullscreenStageSurface extends StatelessWidget {
  const _BrainSplitFullscreenStageSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}

class _BrainSplitLaneView extends StatelessWidget {
  const _BrainSplitLaneView({
    super.key,
    required this.side,
    required this.spec,
    required this.running,
    required this.holdTargetMs,
    required this.onCompleted,
    this.fullscreen = false,
  });

  final _BimanualSide side;
  final _BrainSplitTaskSpec? spec;
  final bool running;
  final int holdTargetMs;
  final ValueChanged<_BrainSplitLaneResult> onCompleted;
  final bool fullscreen;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final accent = spec?.accent ?? _BimanualBrainSplitGameState._accent;
    final sideLabel = switch (side) {
      _BimanualSide.left => pickUiText(i18n, zh: '左侧', en: 'Left'),
      _BimanualSide.right => pickUiText(i18n, zh: '右侧', en: 'Right'),
    };

    if (spec == null) {
      return _BrainSplitLaneFrame(
        accent: accent,
        title: sideLabel,
        subtitle: pickUiText(i18n, zh: '等待配对', en: 'Waiting for pair'),
        goalText: '-',
        progressText: '0/0',
        progressValue: 0,
        statusText: pickUiText(i18n, zh: '未开始', en: 'Idle'),
        fullscreen: fullscreen,
        child: const SizedBox.shrink(),
      );
    }

    return switch (spec!.type) {
      _BimanualTaskType.trace => _BrainSplitTraceLane(
        key: ValueKey<String>('brain_split_trace_${spec!.seed}_$side'),
        spec: spec!,
        running: running,
        onCompleted: onCompleted,
        fullscreen: fullscreen,
      ),
      _BimanualTaskType.bounce => _BrainSplitBounceLane(
        key: ValueKey<String>('brain_split_bounce_${spec!.seed}_$side'),
        spec: spec!,
        running: running,
        onCompleted: onCompleted,
        fullscreen: fullscreen,
      ),
      _BimanualTaskType.climb => _BrainSplitClimbLane(
        key: ValueKey<String>('brain_split_climb_${spec!.seed}_$side'),
        spec: spec!,
        running: running,
        holdTargetMs: holdTargetMs,
        onCompleted: onCompleted,
        fullscreen: fullscreen,
      ),
    };
  }
}

class _BrainSplitLaneFrame extends StatelessWidget {
  const _BrainSplitLaneFrame({
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.goalText,
    required this.progressText,
    required this.progressValue,
    required this.statusText,
    required this.child,
    this.fullscreen = false,
  });

  final Color accent;
  final String title;
  final String subtitle;
  final String goalText;
  final String progressText;
  final double progressValue;
  final String statusText;
  final Widget child;
  final bool fullscreen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final compact = constraints.maxWidth < 180;
        final padding = EdgeInsets.all(
          fullscreen ? (compact ? 9 : 12) : (compact ? 10 : 12),
        );
        final minHeight = fullscreen ? 0.0 : (compact ? 228.0 : 244.0);
        final titleStyle = compact
            ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)
            : theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              );
        return Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                accent.withValues(alpha: 0.16),
                colorScheme.surfaceContainerLowest,
              ],
            ),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                  ),
                  _HumanPill(text: progressText, accent: accent),
                ],
              ),
              if (!fullscreen || !compact) ...<Widget>[
                SizedBox(height: compact ? 3 : 4),
                Text(
                  subtitle,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
              SizedBox(height: compact ? 4 : 6),
              Text(
                goalText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: compact ? 6 : 8),
              Expanded(child: child),
              if (!fullscreen || !compact) ...<Widget>[
                SizedBox(height: compact ? 8 : 10),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: _HumanPill(text: statusText, accent: accent),
                  ),
                ),
              ],
              SizedBox(height: compact ? 4 : 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: compact ? 6 : 8,
                  value: progressValue.clamp(0, 1).toDouble(),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BrainSplitTraceLane extends StatefulWidget {
  const _BrainSplitTraceLane({
    super.key,
    required this.spec,
    required this.running,
    required this.onCompleted,
    this.fullscreen = false,
  });

  final _BrainSplitTaskSpec spec;
  final bool running;
  final ValueChanged<_BrainSplitLaneResult> onCompleted;
  final bool fullscreen;

  @override
  State<_BrainSplitTraceLane> createState() => _BrainSplitTraceLaneState();
}

class _BrainSplitTraceLaneState extends State<_BrainSplitTraceLane> {
  final Stopwatch _stopwatch = Stopwatch();
  List<Offset> _path = <Offset>[];
  Offset? _pointer;
  int _nextIndex = 1;
  bool _completed = false;
  int _mistakes = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(covariant _BrainSplitTraceLane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spec.seed != widget.spec.seed ||
        oldWidget.running != widget.running) {
      _reset();
    }
  }

  void _reset() {
    _path = _buildPath(widget.spec.seed);
    _pointer = null;
    _nextIndex = 1;
    _completed = false;
    _mistakes = 0;
    _stopwatch
      ..stop()
      ..reset();
    if (widget.running) {
      _stopwatch.start();
    }
  }

  List<Offset> _buildPath(int seed) {
    final mode = seed % 3;
    if (mode == 0) {
      return <Offset>[
        const Offset(0.12, 0.76),
        const Offset(0.25, 0.54),
        const Offset(0.42, 0.38),
        const Offset(0.60, 0.57),
        const Offset(0.79, 0.31),
      ];
    }
    if (mode == 1) {
      return <Offset>[
        const Offset(0.15, 0.28),
        const Offset(0.28, 0.49),
        const Offset(0.42, 0.24),
        const Offset(0.58, 0.52),
        const Offset(0.75, 0.34),
      ];
    }
    return <Offset>[
      const Offset(0.14, 0.68),
      const Offset(0.28, 0.42),
      const Offset(0.45, 0.64),
      const Offset(0.60, 0.34),
      const Offset(0.78, 0.50),
    ];
  }

  void _handlePointer(Offset localPosition, Size size) {
    if (!mounted || !widget.running || _completed) {
      return;
    }
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
    }
    setState(() => _pointer = localPosition);
    if (_nextIndex >= _path.length) {
      return;
    }
    final target = _path[_nextIndex];
    final targetPoint = Offset(target.dx * size.width, target.dy * size.height);
    final threshold = math.min(size.width, size.height) * 0.12;
    if ((localPosition - targetPoint).distance <= threshold) {
      setState(() {
        _nextIndex += 1;
      });
      if (_nextIndex >= _path.length) {
        _complete(true);
      }
    } else if (_pointer != null) {
      final current = _path[_nextIndex - 1];
      final currentPoint = Offset(
        current.dx * size.width,
        current.dy * size.height,
      );
      if ((localPosition - currentPoint).distance > threshold * 2) {
        setState(() => _mistakes += 1);
      }
    }
  }

  void _complete(bool success) {
    if (_completed) {
      return;
    }
    _completed = true;
    _stopwatch.stop();
    final elapsed = math.max(1, _stopwatch.elapsedMilliseconds);
    final scoreDelta = success
        ? 14 + (_path.length - 1) * 2 - _mistakes * 2
        : -6;
    widget.onCompleted(
      _BrainSplitLaneResult(
        success: success,
        milliseconds: elapsed,
        scoreDelta: scoreDelta,
        detail: widget.spec.goalText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressText =
        '${math.min(_nextIndex, _path.length - 1)}/${_path.length - 1}';
    final progressValue = (_nextIndex - 1) / math.max(1, _path.length - 1);
    return _BrainSplitLaneFrame(
      accent: widget.spec.accent,
      title: widget.spec.title,
      subtitle: widget.spec.subtitle,
      goalText: widget.spec.goalText,
      progressText: progressText,
      progressValue: progressValue,
      statusText: _completed
          ? pickUiText(
              AppI18n(Localizations.localeOf(context).languageCode),
              zh: '已完成',
              en: 'Completed',
            )
          : pickUiText(
              AppI18n(Localizations.localeOf(context).languageCode),
              zh: '拖动描线',
              en: 'Trace the path',
            ),
      fullscreen: widget.fullscreen,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          if (size.isEmpty) {
            return const SizedBox.shrink();
          }
          final theme = Theme.of(context);
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: widget.running
                ? (event) => _handlePointer(event.localPosition, size)
                : null,
            onPointerMove: widget.running
                ? (event) => _handlePointer(event.localPosition, size)
                : null,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CustomPaint(
                  painter: _TraceTrackPainter(
                    path: _path,
                    activeIndex: _nextIndex,
                    accent: widget.spec.accent,
                  ),
                ),
                if (_pointer != null)
                  Positioned(
                    left: _pointer!.dx - 8,
                    top: _pointer!.dy - 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: widget.spec.accent.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: widget.spec.accent.withValues(alpha: 0.22),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Text(
                    pickUiText(
                      AppI18n(Localizations.localeOf(context).languageCode),
                      zh: '按顺序连点节点',
                      en: 'Hit the checkpoints in order',
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TraceTrackPainter extends CustomPainter {
  const _TraceTrackPainter({
    required this.path,
    required this.activeIndex,
    required this.accent,
  });

  final List<Offset> path;
  final int activeIndex;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) {
      return;
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.22);
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.78);
    final nodePaint = Paint()..style = PaintingStyle.fill;
    final pathPoints = path
        .map((point) => Offset(point.dx * size.width, point.dy * size.height))
        .toList(growable: false);
    final linePath = Path()..moveTo(pathPoints.first.dx, pathPoints.first.dy);
    for (final point in pathPoints.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(linePath, paint);
    if (activeIndex > 1) {
      final activePath = Path()
        ..moveTo(pathPoints.first.dx, pathPoints.first.dy);
      for (
        var index = 1;
        index < math.min(activeIndex, pathPoints.length);
        index += 1
      ) {
        activePath.lineTo(pathPoints[index].dx, pathPoints[index].dy);
      }
      canvas.drawPath(activePath, activePaint);
    }
    for (var index = 0; index < pathPoints.length; index += 1) {
      final point = pathPoints[index];
      nodePaint.color = index < activeIndex
          ? accent
          : accent.withValues(alpha: 0.34);
      canvas.drawCircle(point, index == activeIndex ? 10 : 7, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TraceTrackPainter oldDelegate) {
    return oldDelegate.path != path ||
        oldDelegate.activeIndex != activeIndex ||
        oldDelegate.accent != accent;
  }
}

class _BrainSplitBounceLane extends StatefulWidget {
  const _BrainSplitBounceLane({
    super.key,
    required this.spec,
    required this.running,
    required this.onCompleted,
    this.fullscreen = false,
  });

  final _BrainSplitTaskSpec spec;
  final bool running;
  final ValueChanged<_BrainSplitLaneResult> onCompleted;
  final bool fullscreen;

  @override
  State<_BrainSplitBounceLane> createState() => _BrainSplitBounceLaneState();
}

class _BrainSplitBounceLaneState extends State<_BrainSplitBounceLane> {
  final Stopwatch _stopwatch = Stopwatch();

  Timer? _tickTimer;
  DateTime? _lastTickAt;
  double _ballX = 0.5;
  double _ballY = 0.35;
  double _ballVx = 0.0;
  double _ballVy = 0.0;
  double _paddleX = 0.5;
  int _rallies = 0;
  int _targetRallies = 5;
  bool _completed = false;
  bool _missed = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(covariant _BrainSplitBounceLane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spec.seed != widget.spec.seed ||
        oldWidget.running != widget.running) {
      _reset();
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    super.dispose();
  }

  void _reset() {
    _tickTimer?.cancel();
    _targetRallies = 5 + (widget.spec.seed % 2);
    _ballX = 0.34 + (widget.spec.seed % 4) * 0.12;
    _ballY = 0.30;
    final direction = widget.spec.seed.isEven ? -1.0 : 1.0;
    _ballVx = direction * (0.18 + (widget.spec.seed % 3) * 0.03);
    _ballVy = 0.34 + (widget.spec.seed % 2) * 0.03;
    _paddleX = 0.5;
    _rallies = 0;
    _completed = false;
    _missed = false;
    _lastTickAt = null;
    _stopwatch
      ..stop()
      ..reset();
    if (widget.running) {
      _stopwatch.start();
      _startTicker();
    }
  }

  void _startTicker() {
    _tickTimer?.cancel();
    _lastTickAt = DateTime.now();
    _tickTimer = Timer.periodic(const Duration(milliseconds: 32), (_) {
      _tick();
    });
  }

  void _tick() {
    if (!mounted || !widget.running || _completed) {
      return;
    }
    final now = DateTime.now();
    final lastTick = _lastTickAt ?? now;
    _lastTickAt = now;
    final dt = now.difference(lastTick).inMicroseconds / 1000000.0;
    if (dt <= 0) {
      return;
    }

    const paddleWidth = 0.28;
    const paddleY = 0.84;
    const radius = 0.055;
    final speedScale = 1.0 + _rallies * 0.055;

    var nextX = _ballX + _ballVx * dt * speedScale;
    var nextY = _ballY + _ballVy * dt * speedScale;
    var nextVx = _ballVx;
    var nextVy = _ballVy;

    if (nextX <= radius) {
      nextX = radius;
      nextVx = nextVx.abs();
    } else if (nextX >= 1 - radius) {
      nextX = 1 - radius;
      nextVx = -nextVx.abs();
    }

    if (nextY <= radius) {
      nextY = radius;
      nextVy = nextVy.abs();
    }

    final paddleHalf = paddleWidth / 2;
    final paddleLeft = (_paddleX - paddleHalf)
        .clamp(radius, 1 - paddleWidth - radius)
        .toDouble();
    final paddleRight = paddleLeft + paddleWidth;
    final crossesPaddle = nextVy > 0 && nextY + radius >= paddleY;

    if (crossesPaddle) {
      if (nextX >= paddleLeft && nextX <= paddleRight) {
        nextY = paddleY - radius;
        nextVy = -((nextVy.abs() * 1.04).clamp(0.26, 0.62).toDouble());
        final paddleBias = ((nextX - _paddleX) / paddleHalf)
            .clamp(-1.0, 1.0)
            .toDouble();
        nextVx += paddleBias * 0.10;
        _rallies += 1;
        HapticFeedback.selectionClick();
        if (_rallies >= _targetRallies) {
          setState(() {
            _ballX = nextX;
            _ballY = nextY;
            _ballVx = nextVx;
            _ballVy = nextVy;
          });
          _complete(true);
          return;
        }
      } else if (nextY + radius >= 1 - radius * 0.3) {
        _missed = true;
        setState(() {
          _ballX = nextX;
          _ballY = nextY;
          _ballVx = nextVx;
          _ballVy = nextVy;
        });
        _complete(false);
        return;
      }
    }

    final magnitude = math.sqrt(nextVx * nextVx + nextVy * nextVy);
    if (magnitude > 0.72) {
      final scale = 0.72 / magnitude;
      nextVx *= scale;
      nextVy *= scale;
    }

    setState(() {
      _ballX = nextX;
      _ballY = nextY;
      _ballVx = nextVx;
      _ballVy = nextVy;
    });
  }

  void _setPaddle(double normalizedX) {
    if (!widget.running || _completed) {
      return;
    }
    setState(() {
      _paddleX = normalizedX.clamp(0.14, 0.86).toDouble();
    });
  }

  void _complete(bool success) {
    if (_completed) {
      return;
    }
    _completed = true;
    _tickTimer?.cancel();
    _stopwatch.stop();
    final elapsed = math.max(1, _stopwatch.elapsedMilliseconds);
    final scoreDelta = success
        ? 12 + _targetRallies * 3 - (_rallies - _targetRallies).abs() * 2
        : -6;
    widget.onCompleted(
      _BrainSplitLaneResult(
        success: success,
        milliseconds: elapsed,
        scoreDelta: scoreDelta,
        detail: widget.spec.goalText,
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final progressText =
        '${math.min(_rallies, _targetRallies)}/$_targetRallies';
    final progressValue = _rallies / math.max(1, _targetRallies);
    return _BrainSplitLaneFrame(
      accent: widget.spec.accent,
      title: widget.spec.title,
      subtitle: widget.spec.subtitle,
      goalText: widget.spec.goalText,
      progressText: progressText,
      progressValue: progressValue,
      statusText: _completed
          ? pickUiText(i18n, zh: '已完成', en: 'Completed')
          : _missed
          ? pickUiText(i18n, zh: '漏球', en: 'Missed')
          : widget.running
          ? pickUiText(i18n, zh: '拖动挡板', en: 'Drag the paddle')
          : pickUiText(i18n, zh: '待发球', en: 'Ready'),
      fullscreen: widget.fullscreen,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          if (size.isEmpty) {
            return const SizedBox.shrink();
          }
          final theme = Theme.of(context);
          const paddleWidth = 0.28;
          const paddleHeight = 0.09;
          const paddleY = 0.84;
          final ballRadius = math.min(size.width, size.height) * 0.075;
          final ballCenter = Offset(_ballX * size.width, _ballY * size.height);
          final paddleLeft =
              ((_paddleX - paddleWidth / 2)
                  .clamp(0.08, 0.92 - paddleWidth)
                  .toDouble()) *
              size.width;
          final paddleTop = paddleY * size.height;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: widget.running
                ? (details) => _setPaddle(details.localPosition.dx / size.width)
                : null,
            onHorizontalDragStart: widget.running
                ? (details) => _setPaddle(details.localPosition.dx / size.width)
                : null,
            onHorizontalDragUpdate: widget.running
                ? (details) => _setPaddle(details.localPosition.dx / size.width)
                : null,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        widget.spec.accent.withValues(alpha: 0.08),
                        Theme.of(context).colorScheme.surfaceContainerLowest,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Text(
                    widget.running
                        ? pickUiText(
                            i18n,
                            zh: '把球稳住',
                            en: 'Keep the ball alive',
                          )
                        : pickUiText(
                            i18n,
                            zh: '先开始再接球',
                            en: 'Start before the serve',
                          ),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (var lane = 0; lane < 5; lane += 1)
                  Positioned(
                    left: 14,
                    right: 14,
                    top: size.height * (0.15 + lane * 0.16),
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        color: widget.spec.accent.withValues(
                          alpha: lane.isEven ? 0.14 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                Positioned(
                  left: paddleLeft,
                  top: paddleTop,
                  child: Container(
                    width: size.width * paddleWidth,
                    height: size.height * paddleHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          widget.spec.accent.withValues(alpha: 0.95),
                          widget.spec.accent.withValues(alpha: 0.58),
                        ],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: widget.spec.accent.withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: ballCenter.dx - ballRadius,
                  top: ballCenter.dy - ballRadius,
                  child: Container(
                    width: ballRadius * 2,
                    height: ballRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.spec.accent.withValues(alpha: 0.94),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: widget.spec.accent.withValues(alpha: 0.28),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: _HumanPill(
                    text:
                        '${(_rallies * 100 / math.max(1, _targetRallies)).round()}%',
                    accent: widget.spec.accent,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BrainSplitClimbLane extends StatefulWidget {
  const _BrainSplitClimbLane({
    super.key,
    required this.spec,
    required this.running,
    required this.holdTargetMs,
    required this.onCompleted,
    this.fullscreen = false,
  });

  final _BrainSplitTaskSpec spec;
  final bool running;
  final int holdTargetMs;
  final ValueChanged<_BrainSplitLaneResult> onCompleted;
  final bool fullscreen;

  @override
  State<_BrainSplitClimbLane> createState() => _BrainSplitClimbLaneState();
}

class _BrainSplitClimbLaneState extends State<_BrainSplitClimbLane> {
  final Stopwatch _stopwatch = Stopwatch();

  Timer? _chargeTimer;
  DateTime? _chargeStartedAt;
  int _stepIndex = 0;
  int _targetSteps = 6;
  List<int> _obstacleSteps = <int>[];
  double _chargeProgress = 0;
  bool _charging = false;
  bool _chargeReady = false;
  bool _chargeAnnounced = false;
  bool _completed = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(covariant _BrainSplitClimbLane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spec.seed != widget.spec.seed ||
        oldWidget.running != widget.running ||
        oldWidget.holdTargetMs != widget.holdTargetMs) {
      _reset();
    }
  }

  @override
  void dispose() {
    _chargeTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    super.dispose();
  }

  void _reset() {
    _chargeTimer?.cancel();
    _targetSteps = 6 + (widget.spec.seed % 2);
    _obstacleSteps = <int>{
      2,
      math.max(2, _targetSteps - 2),
    }.toList(growable: false)..sort();
    _stepIndex = 0;
    _chargeProgress = 0;
    _charging = false;
    _chargeReady = false;
    _chargeAnnounced = false;
    _completed = false;
    _failed = false;
    _chargeStartedAt = null;
    _stopwatch
      ..stop()
      ..reset();
    if (widget.running) {
      _stopwatch.start();
    }
  }

  void _beginCharge() {
    if (!mounted || !widget.running || _completed) {
      return;
    }
    if (_charging) {
      return;
    }
    _chargeTimer?.cancel();
    _charging = true;
    _chargeReady = false;
    _chargeAnnounced = false;
    _chargeProgress = 0;
    _chargeStartedAt = DateTime.now();
    _chargeTimer = Timer.periodic(const Duration(milliseconds: 32), (_) {
      if (!mounted || !_charging || _completed) {
        return;
      }
      final startedAt = _chargeStartedAt ?? DateTime.now();
      final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
      final progress = (elapsed / math.max(1, widget.holdTargetMs))
          .clamp(0.0, 1.0)
          .toDouble();
      setState(() {
        _chargeProgress = progress;
        _chargeReady = progress >= 1;
      });
      if (progress >= 1 && !_chargeAnnounced) {
        _chargeAnnounced = true;
        HapticFeedback.selectionClick();
      }
    });
    setState(() {});
  }

  void _endCharge() {
    if (!mounted || _completed) {
      return;
    }
    final charged = _chargeReady;
    _chargeTimer?.cancel();
    _chargeTimer = null;
    _charging = false;
    _chargeStartedAt = null;
    _chargeProgress = 0;
    _chargeReady = false;
    _chargeAnnounced = false;
    if (charged) {
      _advanceStep(jump: _obstacleSteps.contains(_stepIndex));
      return;
    }
    if (_obstacleSteps.contains(_stepIndex)) {
      _complete(false);
      return;
    }
    _advanceStep(jump: false);
  }

  void _advanceStep({required bool jump}) {
    if (!mounted || _completed) {
      return;
    }
    final obstacle = _obstacleSteps.contains(_stepIndex);
    final advance = obstacle && jump ? 2 : 1;
    setState(() {
      _stepIndex = math.min(_targetSteps, _stepIndex + advance);
    });
    if (_stepIndex >= _targetSteps) {
      _complete(true);
      return;
    }
    HapticFeedback.selectionClick();
  }

  void _complete(bool success) {
    if (_completed) {
      return;
    }
    _completed = true;
    _failed = !success;
    _chargeTimer?.cancel();
    _stopwatch.stop();
    final elapsed = math.max(1, _stopwatch.elapsedMilliseconds);
    final scoreDelta = success ? 13 + _targetSteps * 3 - (_failed ? 4 : 0) : -6;
    widget.onCompleted(
      _BrainSplitLaneResult(
        success: success,
        milliseconds: elapsed,
        scoreDelta: scoreDelta,
        detail: widget.spec.goalText,
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final progressText = '${math.min(_stepIndex, _targetSteps)}/$_targetSteps';
    final progressValue = _stepIndex / math.max(1, _targetSteps);
    final needCharge = _obstacleSteps.contains(_stepIndex);
    return _BrainSplitLaneFrame(
      accent: widget.spec.accent,
      title: widget.spec.title,
      subtitle: widget.spec.subtitle,
      goalText: widget.spec.goalText,
      progressText: progressText,
      progressValue: progressValue,
      statusText: _completed
          ? pickUiText(i18n, zh: '已登顶', en: 'Summit reached')
          : _failed
          ? pickUiText(i18n, zh: '被管道拦住', en: 'Blocked')
          : _charging
          ? pickUiText(
              i18n,
              zh: '蓄力中',
              en: '${(_chargeProgress * 100).round()}% charge',
            )
          : needCharge
          ? pickUiText(i18n, zh: '长按起跳', en: 'Hold to jump')
          : pickUiText(i18n, zh: '短按上步', en: 'Tap to step'),
      fullscreen: widget.fullscreen,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          if (size.isEmpty) {
            return const SizedBox.shrink();
          }
          final theme = Theme.of(context);
          final stepSpacing = size.height / (_targetSteps + 1.6);
          final runnerY = size.height - ((_stepIndex + 1) * stepSpacing);
          final runnerX = size.width * 0.26;
          final pipeWidth = size.width * 0.18;
          final pipeHeight = size.height * 0.09;
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: widget.running ? (_) => _beginCharge() : null,
            onPointerUp: widget.running ? (_) => _endCharge() : null,
            onPointerCancel: widget.running ? (_) => _endCharge() : null,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        widget.spec.accent.withValues(alpha: 0.08),
                        Theme.of(context).colorScheme.surfaceContainerLowest,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Text(
                    widget.running
                        ? pickUiText(
                            i18n,
                            zh: '按一下上一步，遇到管道就长按蓄力。',
                            en: 'Tap to climb; hold when a pipe blocks the way.',
                          )
                        : pickUiText(
                            i18n,
                            zh: '先开始再冲楼梯',
                            en: 'Start before climbing',
                          ),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (var step = 0; step < _targetSteps; step += 1)
                  Positioned(
                    left: 18,
                    right: 18,
                    top: size.height - (step + 1) * stepSpacing,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: step <= _stepIndex
                            ? widget.spec.accent.withValues(alpha: 0.36)
                            : widget.spec.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                for (final obstacle in _obstacleSteps)
                  Positioned(
                    right: 16,
                    top: size.height - (obstacle + 1) * stepSpacing - 2,
                    child: Container(
                      width: pipeWidth,
                      height: pipeHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            BimanualCoordinationTestPage._dangerAccent
                                .withValues(
                                  alpha: obstacle <= _stepIndex ? 0.72 : 0.92,
                                ),
                            widget.spec.accent.withValues(alpha: 0.88),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.block_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOutCubic,
                  left: runnerX,
                  top: runnerY.clamp(12.0, size.height - 54).toDouble(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          widget.spec.accent.withValues(alpha: 0.95),
                          widget.spec.accent.withValues(alpha: 0.55),
                        ],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: widget.spec.accent.withValues(alpha: 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_walk_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      _HumanPill(
                        text: needCharge
                            ? pickUiText(i18n, zh: '管道', en: 'Pipe')
                            : pickUiText(i18n, zh: '楼梯', en: 'Steps'),
                        accent: widget.spec.accent,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 74,
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: _charging ? _chargeProgress : progressValue,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _charging
                                ? BimanualCoordinationTestPage._dangerAccent
                                : widget.spec.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BrainSplitRecentPanel extends StatelessWidget {
  const _BrainSplitRecentPanel({required this.records, required this.i18n});

  final List<_BrainSplitRoundRecord> records;
  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final recent = records.length <= 8
        ? records
        : records.sublist(records.length - 8);
    final theme = Theme.of(context);
    return _HumanPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            pickUiText(i18n, zh: '最近回合', en: 'Recent rounds'),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recent
                .map((record) {
                  final success = record.left.success && record.right.success;
                  return _HumanPill(
                    text:
                        '${record.plan.label} ${success ? '+' : '-'}${record.scoreDelta.abs()}',
                    accent: success
                        ? BimanualCoordinationTestPage._accent
                        : BimanualCoordinationTestPage._dangerAccent,
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _BrainSplitReportDialog extends StatelessWidget {
  const _BrainSplitReportDialog({
    required this.i18n,
    required this.mode,
    required this.records,
    required this.score,
    required this.bestCombo,
    required this.mistakes,
    required this.leftWins,
    required this.rightWins,
    required this.averageMs,
    required this.averageSyncGap,
    required this.accuracy,
  });

  final AppI18n i18n;
  final String mode;
  final List<_BrainSplitRoundRecord> records;
  final int score;
  final int bestCombo;
  final int mistakes;
  final int leftWins;
  final int rightWins;
  final int averageMs;
  final int averageSyncGap;
  final double accuracy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = score >= records.length * 18 && accuracy >= 0.9
        ? pickUiText(i18n, zh: '左右脑合拍', en: 'Two-hand flow')
        : accuracy < 0.7
        ? pickUiText(i18n, zh: '先稳住节奏', en: 'Slow down first')
        : pickUiText(i18n, zh: '节奏正在成形', en: 'Rhythm forming');
    return AlertDialog(
      title: Text(pickUiText(i18n, zh: '双手协调报告', en: 'Bimanual report')),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _HumanMetricWrap(
                metrics: <(String, String)>[
                  (pickUiText(i18n, zh: '称号', en: 'Title'), title),
                  (pickUiText(i18n, zh: '模式', en: 'Mode'), mode),
                  (pickUiText(i18n, zh: '分数', en: 'Score'), '$score'),
                  (
                    pickUiText(i18n, zh: '准确率', en: 'Accuracy'),
                    '${(accuracy * 100).round()}%',
                  ),
                  (
                    pickUiText(i18n, zh: '最佳连击', en: 'Best combo'),
                    '$bestCombo',
                  ),
                  (pickUiText(i18n, zh: '失误', en: 'Mistakes'), '$mistakes'),
                  (
                    pickUiText(i18n, zh: '平均用时', en: 'Avg lane time'),
                    averageMs == 0 ? '-' : _formatMilliseconds(averageMs),
                  ),
                  (
                    pickUiText(i18n, zh: '同步差', en: 'Sync gap'),
                    averageSyncGap == 0
                        ? '-'
                        : _formatMilliseconds(averageSyncGap),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _HumanPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pickUiText(i18n, zh: '左右手负载', en: 'Hand load'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _BimanualLoadBar(
                      leftHits: leftWins,
                      rightHits: rightWins,
                      i18n: i18n,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _BrainSplitRecentPanel(records: records, i18n: i18n),
              const SizedBox(height: 12),
              _HumanPanel(
                child: Text(
                  mistakes > records.length * 0.25
                      ? pickUiText(
                          i18n,
                          zh: '建议先降低节奏，重点练习左/右独立完成与同步窗口内的合拍收尾。',
                          en: 'Lower the pace first. Practice isolated left/right finishes and sync-window endings.',
                        )
                      : pickUiText(
                          i18n,
                          zh: '表现稳定，可以提高节奏强度或切换到更强的脑裂配对。',
                          en: 'Performance is stable. Raise the pace or switch to a tougher split-brain pairing.',
                        ),
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

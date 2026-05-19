part of 'toolbox_human_tests.dart';

enum _BimanualMode { arcade, splitBrain, conductor }

enum _BimanualDifficulty { relaxed, standard, hard, expert }

enum _BimanualLane { left, right, both }

enum _BimanualRule { tap, hold, mirror, decoy }

enum _BimanualSide { left, right }

enum _BimanualTaskType { trace, bounce, climb }

enum _BrainSplitFullscreenAction { settings, reset, report, stop, exit }

enum _BrainSplitTracePattern {
  mixed,
  zigzag,
  wave,
  star,
  spiral,
  box,
  steps,
  loop,
  triangle,
  square,
  rectangle,
  circle,
  trapezoid,
  diamond,
  polyhedron,
}

enum _BrainSplitTraceLineStyle { solid, dashed, dotted, ribbon }

enum _BrainSplitTraceSegmentMode { straight, curved, random }

class _BrainSplitBounceObstacle {
  const _BrainSplitBounceObstacle({required this.center, required this.radius});

  final Offset center;
  final double radius;
}

class _BrainSplitJumpPlatform {
  const _BrainSplitJumpPlatform({
    required this.level,
    required this.width,
    required this.speed,
    required this.phase,
    required this.requiredCharge,
  });

  final int level;
  final double width;
  final double speed;
  final double phase;
  final double requiredCharge;
}

class _BrainSplitBallState {
  const _BrainSplitBallState({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    this.trail = const <Offset>[],
  });

  final double x;
  final double y;
  final double vx;
  final double vy;
  final List<Offset> trail;

  _BrainSplitBallState copyWith({
    double? x,
    double? y,
    double? vx,
    double? vy,
    List<Offset>? trail,
  }) {
    return _BrainSplitBallState(
      x: x ?? this.x,
      y: y ?? this.y,
      vx: vx ?? this.vx,
      vy: vy ?? this.vy,
      trail: trail ?? this.trail,
    );
  }
}

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
      title: pickUiText(
        i18n,
        zh: '双手协调',
        en: 'Bimanual coordination',
        ja: 'バイマニュアルコーディネート',
        de: 'Bimanual coordination',
        fr: 'Coordination bimanuelle',
        es: 'Coordinación bimanual',
        ru: 'Двухсторонняя координация',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '左右手同时控制不同小游戏，手机默认进入横屏全屏，在脑裂、同步奖励和节奏切换里练习独立分工。',
        en: 'Run different mini-games on both sides at once. Phones default to landscape fullscreen for split-brain separation, sync bonuses, and rhythm shifts.',
        ja: 'Run different mini-games on both sides at once. Phones default to landscape fullscreen for split-brain separation, sync bonuses, and rhythm shifts.',
        de: 'Run different mini-games on both sides at once. Phones default to landscape fullscreen for split-brain separation, sync bonuses, and rhythm shifts.',
        fr: 'Exécutez différents mini-jeux des deux côtés à la fois. Les téléphones par défaut pour le paysage plein écran pour la séparation du cerveau divisé, les bonus de synchronisation et les changements de rythme.',
        es: 'Ejecute diferentes minijuegos en ambos lados a la vez. Teléfonos predeterminados para el paisaje de pantalla completa para separación de cerebros, bonos de sincronización y cambios de ritmo.',
        ru: 'Выполняйте различные мини-игры с обеих сторон одновременно. Телефоны по умолчанию выходят на полный экран для разделения разделенного мозга, синхронизации бонусов и сдвига ритма.',
      ),
      accent: _accent,
      icon: Icons.pan_tool_alt_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：进入全屏横屏，同时推进左右两侧任务。',
        en: 'Next: enter landscape fullscreen and push both sides forward together.',
        ja: 'Next: enter landscape fullscreen and push both sides forward together.',
        de: 'Next: enter landscape fullscreen and push both sides forward together.',
        fr: 'Suivant: entrer dans le paysage plein écran et pousser les deux côtés ensemble.',
        es: 'Siguiente: introducir pantalla completa de paisaje y empujar ambos lados hacia adelante juntos.',
        ru: 'Далее: введите ландшафтный полноэкранный экран и сдвиньте обе стороны вперед вместе.',
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
    this.difficulty = _BimanualDifficulty.standard,
    this.tracePattern = _BrainSplitTracePattern.zigzag,
    this.traceLineStyle = _BrainSplitTraceLineStyle.solid,
    this.traceNodeCount = 5,
    this.traceThreshold = 0.12,
    this.targetCount = 5,
    this.speedScale = 1,
    this.ballRadius = 0.044,
    this.ballCount = 1,
    this.collisionAcceleration = false,
    this.paddleWidth = 0.28,
    this.paddleHeight = 0.045,
    this.traceSegmentMode = _BrainSplitTraceSegmentMode.straight,
    this.traceMinAngleDegrees = 35,
    this.traceColorSegments = false,
    this.platformWidth = 0.32,
    this.platformWidthRandomness = 0.08,
    this.bounceObstacles = const <_BrainSplitBounceObstacle>[],
    this.climbPlatforms = const <_BrainSplitJumpPlatform>[],
  });

  final _BimanualTaskType type;
  final String title;
  final String subtitle;
  final String goalText;
  final Color accent;
  final int seed;
  final _BimanualDifficulty difficulty;
  final _BrainSplitTracePattern tracePattern;
  final _BrainSplitTraceLineStyle traceLineStyle;
  final int traceNodeCount;
  final double traceThreshold;
  final int targetCount;
  final double speedScale;
  final double ballRadius;
  final int ballCount;
  final bool collisionAcceleration;
  final double paddleWidth;
  final double paddleHeight;
  final _BrainSplitTraceSegmentMode traceSegmentMode;
  final double traceMinAngleDegrees;
  final bool traceColorSegments;
  final double platformWidth;
  final double platformWidthRandomness;
  final List<_BrainSplitBounceObstacle> bounceObstacles;
  final List<_BrainSplitJumpPlatform> climbPlatforms;
}

class _BrainSplitRoundPlan {
  const _BrainSplitRoundPlan({
    required this.label,
    required this.left,
    required this.right,
    required this.leftActive,
    required this.rightActive,
    required this.durationMs,
  });

  final String label;
  final _BrainSplitTaskSpec left;
  final _BrainSplitTaskSpec right;
  final bool leftActive;
  final bool rightActive;
  final int durationMs;

  int get activeLaneCount => (leftActive ? 1 : 0) + (rightActive ? 1 : 0);
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
      _BimanualMode.arcade => pickUiText(
        i18n,
        zh: '街机混合',
        en: 'Arcade mix',
        ja: 'アーケードミックス',
        de: 'Arcade mix',
        fr: 'Mélange d\'arcade',
        es: 'Arcade mix',
        ru: 'Аркадная смесь',
      ),
      _BimanualMode.splitBrain => pickUiText(
        i18n,
        zh: '脑裂风暴',
        en: 'Split-brain storm',
        ja: 'Split-brain storm',
        de: 'Split-brain storm',
        fr: 'Tempête de cervelle',
        es: 'Tormenta de cerebro-dividido',
        ru: 'Сплит-мозг шторм',
      ),
      _BimanualMode.conductor => pickUiText(
        i18n,
        zh: '节奏指挥',
        en: 'Rhythm conductor',
        ja: 'Rhythm conductor',
        de: 'Rhythm conductor',
        fr: 'Conducteur de rythme',
        es: 'Conductor de Rhythm',
        ru: 'Ритм-проводник',
      ),
    };
  }

  String _ruleLabel(AppI18n i18n, _BimanualRule rule) {
    return switch (rule) {
      _BimanualRule.tap => pickUiText(
        i18n,
        zh: '点按',
        en: 'Tap',
        ja: 'Tap',
        de: 'Tap',
        fr: 'Appuyez sur',
        es: 'Tap',
        ru: 'нажатие',
      ),
      _BimanualRule.hold => pickUiText(
        i18n,
        zh: '长按',
        en: 'Hold',
        ja: 'Hold',
        de: 'Hold',
        fr: 'Attendez',
        es: 'Espera.',
        ru: 'Держать',
      ),
      _BimanualRule.mirror => pickUiText(
        i18n,
        zh: '同步',
        en: 'Sync',
        ja: 'Sync',
        de: 'Sync',
        fr: 'Synchronisation',
        es: 'Sync',
        ru: 'синхронизация',
      ),
      _BimanualRule.decoy => pickUiText(
        i18n,
        zh: '陷阱',
        en: 'Trap',
        ja: 'Trap',
        de: 'Trap',
        fr: 'Trap',
        es: 'Trampa',
        ru: 'Ловушка',
      ),
    };
  }

  String _laneLabel(AppI18n i18n, _BimanualLane lane) {
    return switch (lane) {
      _BimanualLane.left => pickUiText(
        i18n,
        zh: '左手',
        en: 'Left',
        ja: 'Left',
        de: 'Left',
        fr: 'Gauche',
        es: 'Izquierda',
        ru: 'Левый',
      ),
      _BimanualLane.right => pickUiText(
        i18n,
        zh: '右手',
        en: 'Right',
        ja: 'Right',
        de: 'Right',
        fr: 'Droite',
        es: 'Bien.',
        ru: 'Правильно.',
      ),
      _BimanualLane.both => pickUiText(
        i18n,
        zh: '双手',
        en: 'Both',
        ja: '両方',
        de: 'Both',
        fr: 'Les deux',
        es: 'Ambos',
        ru: 'Оба',
      ),
    };
  }

  String _cueInstruction(AppI18n i18n) {
    final cue = _cue;
    if (!_running || cue == null) {
      return pickUiText(
        i18n,
        zh: '选择玩法后开始，双手分别守住左右触区。',
        en: 'Pick a mode and start. Keep both hands on the left and right pads.',
        ja: 'Pick a mode and start. Keep both hands on the left and right pads.',
        de: 'Pick a mode and start. Keep both hands on the left and right pads.',
        fr: 'Choisissez un mode et démarrez. Gardez les deux mains sur les coussinets gauche et droit.',
        es: 'Elige un modo y comienza. Mantén ambas manos en las almohadillas izquierda y derecha.',
        ru: 'Выберите режим и начинайте. Держите обе руки на левой и правой подушках.',
      );
    }
    return switch (cue.rule) {
      _BimanualRule.tap =>
        cue.lane == _BimanualLane.both
            ? pickUiText(
                i18n,
                zh: '双手几乎同时点下',
                en: 'Tap both pads nearly together',
                ja: 'Tap both pads nearly together',
                de: 'Tap both pads nearly together',
                fr: 'Tapez les deux tampons presque ensemble',
                es: 'Toca ambas almohadillas casi juntas',
                ru: 'Нажмите обе прокладки почти вместе',
              )
            : pickUiText(
                i18n,
                zh: '点按${_laneLabel(i18n, cue.lane)}触区',
                en: 'Tap the ${_laneLabel(i18n, cue.lane)} pad',
                ja: 'Tap the ${_laneLabel(i18n, cue.lane)} pad',
                de: 'Tap the ${_laneLabel(i18n, cue.lane)} pad',
                fr: 'Appuyez sur le tampon ${_laneLabel(i18n, cue.lane)}',
                es: 'Toca el almohadilla de <v0/',
                ru: 'Нажмите ${_laneLabel(i18n, cue.lane)} pad',
              ),
      _BimanualRule.hold =>
        cue.lane == _BimanualLane.both
            ? pickUiText(
                i18n,
                zh: '双手同时按住直到充能完成',
                en: 'Hold both pads until charge completes',
                ja: 'Hold both pads until charge completes',
                de: 'Hold both pads until charge completes',
                fr: 'Maintenez les deux tampons jusqu\'à la fin de la charge',
                es: 'Sostenga ambas almohadillas hasta completar el cargo',
                ru: 'Держите обе прокладки до завершения зарядки',
              )
            : pickUiText(
                i18n,
                zh: '按住${_laneLabel(i18n, cue.lane)}触区',
                en: 'Hold the ${_laneLabel(i18n, cue.lane)} pad',
                ja: 'Hold the ${_laneLabel(i18n, cue.lane)} pad',
                de: 'Hold the ${_laneLabel(i18n, cue.lane)} pad',
                fr: 'Maintenez le tampon ${_laneLabel(i18n, cue.lane)}',
                es: 'Sostenga la almohadilla de <v0/',
                ru: 'Держите колодку ${_laneLabel(i18n, cue.lane)}',
              ),
      _BimanualRule.mirror => pickUiText(
        i18n,
        zh: '镜像指令：左右手在窗口内连击',
        en: 'Mirror cue: strike left and right within the sync window',
        ja: 'Mirror cue: strike left and right within the sync window',
        de: 'Mirror cue: strike left and right within the sync window',
        fr: 'Marque miroir: frappez à gauche et à droite dans la fenêtre de synchronisation',
        es: 'Espejo cue: huelga izquierda y derecha dentro de la ventana de sincronización',
        ru: 'Зеркальный сигнал: удар влево и вправо в окне синхронизации',
      ),
      _BimanualRule.decoy => pickUiText(
        i18n,
        zh: '陷阱指令：什么都别按',
        en: 'Trap cue: press nothing',
        ja: 'Trap cue: press nothing',
        de: 'Trap cue: press nothing',
        fr: 'Trap cue: ne pressez rien',
        es: 'Trap cue: nada de prensa',
        ru: 'Оригинальное название: Press Nothing',
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
              pickUiText(
                i18n,
                zh: '进度',
                en: 'Progress',
                ja: 'Progress',
                de: 'Progress',
                fr: 'Progrès accomplis',
                es: 'Progresos',
                ru: 'Прогресс',
              ),
              '$_roundIndex/$_roundCount',
            ),
            (
              pickUiText(
                i18n,
                zh: '分数',
                en: 'Score',
                ja: 'Score',
                de: 'Score',
                fr: 'Score',
                es: 'Puntuación',
                ru: 'счет',
              ),
              '$_score',
            ),
            (
              pickUiText(
                i18n,
                zh: '连击',
                en: 'Combo',
                ja: 'コンボ',
                de: 'Combo',
                fr: 'Combo',
                es: 'Combo',
                ru: 'Комбинация',
              ),
              '$_combo',
            ),
            (
              pickUiText(
                i18n,
                zh: '准确率',
                en: 'Accuracy',
                ja: '精度',
                de: 'Accuracy',
                fr: 'Accuracy',
                es: 'Precisión',
                ru: 'точность',
              ),
              _records.isEmpty ? '-' : '${(_accuracy * 100).round()}%',
            ),
            (
              pickUiText(
                i18n,
                zh: '平均反应',
                en: 'Avg reaction',
                ja: '平均反応',
                de: 'Avg reaction',
                fr: 'Réaction d\' Avg',
                es: 'Reacción de Avg',
                ru: 'Авг реакция',
              ),
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
                  ? pickUiText(
                      i18n,
                      zh: '重新开始',
                      en: 'Restart',
                      ja: 'Restart',
                      de: 'Restart',
                      fr: 'Redémarrer',
                      es: 'Restart',
                      ru: 'Перезапустить',
                    )
                  : pickUiText(
                      i18n,
                      zh: '开始挑战',
                      en: 'Start challenge',
                      ja: 'Start challenge',
                      de: 'Start challenge',
                      fr: 'Démarrage',
                      es: 'Inicio desafío',
                      ru: 'Начинать вызов',
                    ),
              icon: _running ? Icons.replay_rounded : Icons.play_arrow_rounded,
              onPressed: _start,
            ),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                pickUiText(
                  i18n,
                  zh: '重置',
                  en: 'Reset',
                  ja: 'Reset',
                  de: 'Reset',
                  fr: 'Réinitialiser',
                  es: 'Reset',
                  ru: 'сброс',
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _records.isEmpty
                  ? null
                  : () => unawaited(_showReport()),
              icon: const Icon(Icons.analytics_rounded),
              label: Text(
                pickUiText(
                  i18n,
                  zh: '报告',
                  en: 'Report',
                  ja: 'Report',
                  de: 'Report',
                  fr: 'Rapport annuel',
                  es: 'Informe',
                  ru: 'Доклад',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: pickUiText(
            i18n,
            zh: '双手挑战设置',
            en: 'Bimanual game settings',
            ja: 'バイマニュアルゲーム設定',
            de: 'Bimanual game settings',
            fr: 'Paramètres du jeu bimanuel',
            es: 'Ajustes de juego duales',
            ru: 'Бирумные игровые настройки',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '切换玩法、轮数、节奏强度、同步窗口和长按时长。运行中设置会锁定。',
            en: 'Choose mode, rounds, pace, sync window, and hold duration. Settings lock while running.',
            ja: 'モード、ラウンド、ペース、同期ウィンドウ、ホールド時間を選択します。実行中は設定がロックされます。',
            de: 'Choose mode, rounds, pace, sync window, and hold duration. Settings lock while running.',
            fr: 'Choisissez le mode, les tours, le rythme, la fenêtre de synchronisation et la durée de maintien. Réglages verrouillés pendant l\'exécution.',
            es: 'Elija modo, rondas, ritmo, ventana de sincronización y mantener la duración. Los ajustes se bloquean mientras corren.',
            ru: 'Выберите режим, раунды, темп, окно синхронизации и продолжительность удержания. Настройка замка во время бега.',
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
          pickUiText(
            i18n,
            zh: '玩法模式',
            en: 'Game mode',
            ja: 'Game mode',
            de: 'Game mode',
            fr: 'Mode jeu',
            es: 'Modo de juego',
            ru: 'Режим игры',
          ),
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
        Text(
          pickUiText(
            i18n,
            zh: '轮数',
            en: 'Rounds',
            ja: 'Rounds',
            de: 'Rounds',
            fr: 'Rondes',
            es: 'Rondas',
            ru: 'Круги',
          ),
        ),
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
        Text(
          pickUiText(
            i18n,
            zh: '节奏强度',
            en: 'Pace level',
            ja: 'Pace level',
            de: 'Pace level',
            fr: 'Niveau de Pace',
            es: 'Nivel de rotación',
            ru: 'Уровень темпа',
          ),
        ),
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
        Text(
          pickUiText(
            i18n,
            zh: '同步窗口',
            en: 'Sync window',
            ja: 'Sync window',
            de: 'Sync window',
            fr: 'Synchroniser la fenêtre',
            es: 'Ventana sincronizada',
            ru: 'Синхронное окно',
          ),
        ),
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
        Text(
          pickUiText(
            i18n,
            zh: '长按充能',
            en: 'Hold charge',
            ja: 'Hold charge',
            de: 'Hold charge',
            fr: 'Maintenance',
            es: 'Carga de mano',
            ru: 'Держите заряд.',
          ),
        ),
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
        ? pickUiText(
            i18n,
            zh: '等待输入',
            en: 'Awaiting input',
            ja: '入力待ち',
            de: 'Awaiting input',
            fr: 'En attente d\'une contribution',
            es: 'Awaiting input',
            ru: 'Ожидающий вклад',
          )
        : lastCorrect!
        ? pickUiText(
            i18n,
            zh: '命中',
            en: 'Hit',
            ja: 'Hit',
            de: 'Hit',
            fr: 'Affichage',
            es: 'Hit',
            ru: 'удар',
          )
        : pickUiText(
            i18n,
            zh: '失误',
            en: 'Miss',
            ja: 'Miss',
            de: 'Miss',
            fr: 'Mlle',
            es: 'Miss',
            ru: 'Мисс.',
          );
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
                label: pickUiText(
                  i18n,
                  zh: '左手',
                  en: 'Left',
                  ja: 'Left',
                  de: 'Left',
                  fr: 'Gauche',
                  es: 'Izquierda',
                  ru: 'Левый',
                ),
                subtitle: firstSyncLane == _BimanualLane.left
                    ? pickUiText(
                        i18n,
                        zh: '已先击',
                        en: 'First strike',
                        ja: 'First strike',
                        de: 'First strike',
                        fr: 'Première grève',
                        es: 'Primera huelga',
                        ru: 'Первый удар',
                      )
                    : pickUiText(
                        i18n,
                        zh: '蓝色触区',
                        en: 'Blue pad',
                        ja: '青パッド',
                        de: 'Blue pad',
                        fr: 'Tapis bleu',
                        es: 'Almohadilla azul',
                        ru: 'Голубая колодка',
                      ),
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
                label: pickUiText(
                  i18n,
                  zh: '右手',
                  en: 'Right',
                  ja: 'Right',
                  de: 'Right',
                  fr: 'Droite',
                  es: 'Bien.',
                  ru: 'Правильно.',
                ),
                subtitle: firstSyncLane == _BimanualLane.right
                    ? pickUiText(
                        i18n,
                        zh: '已先击',
                        en: 'First strike',
                        ja: 'First strike',
                        de: 'First strike',
                        fr: 'Première grève',
                        es: 'Primera huelga',
                        ru: 'Первый удар',
                      )
                    : pickUiText(
                        i18n,
                        zh: '金色触区',
                        en: 'Gold pad',
                        ja: 'Gold pad',
                        de: 'Gold pad',
                        fr: 'Pad doré',
                        es: 'Almohadilla de oro',
                        ru: 'Золотая колодка',
                      ),
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
  int? _activePointer;
  bool _tapCandidate = false;

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.enabled || _activePointer != null) {
      return;
    }
    _activePointer = event.pointer;
    _tapCandidate = true;
    widget.onHoldChanged(true);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer) {
      return;
    }
    if (event.localDelta.distance > 12) {
      _tapCandidate = false;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointer) {
      return;
    }
    final shouldTap = _tapCandidate && widget.enabled;
    _release();
    if (shouldTap) {
      widget.onTap();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointer) {
      return;
    }
    _release();
  }

  void _release() {
    _activePointer = null;
    _tapCandidate = false;
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
    return _HumanPointerDragBoundary(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      enabled: widget.enabled,
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
            pickUiText(
              i18n,
              zh: '最近节奏',
              en: 'Recent rhythm',
              ja: 'Recent rhythm',
              de: 'Recent rhythm',
              fr: 'Rythme récent',
              es: 'ritmo reciente',
              ru: 'Недавний ритм',
            ),
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
        ? pickUiText(
            i18n,
            zh: '左右脑合拍',
            en: 'Two-hand flow',
            ja: 'Two-hand flow',
            de: 'Two-hand flow',
            fr: 'Débit à deux mains',
            es: 'Flujo de dos manos',
            ru: 'Двусторонний поток',
          )
        : accuracy < 0.7
        ? pickUiText(
            i18n,
            zh: '需要降速稳住',
            en: 'Slow down first',
            ja: 'Slow down first',
            de: 'Slow down first',
            fr: 'Ralentissez d\'abord',
            es: 'Despacio primero',
            ru: 'Сначала помедленнее',
          )
        : pickUiText(
            i18n,
            zh: '节奏正在成形',
            en: 'Rhythm forming',
            ja: 'Rhythm forming',
            de: 'Rhythm forming',
            fr: 'Rythme formant',
            es: 'Rhythm formando',
            ru: 'Формирование ритма',
          );
    return AlertDialog(
      title: Text(
        pickUiText(
          i18n,
          zh: '双手协调报告',
          en: 'Bimanual report',
          ja: 'バイマニュアルレポート',
          de: 'Bimanual report',
          fr: 'Rapport bimanuel',
          es: 'Informe bimanual',
          ru: 'Двухсторонний доклад',
        ),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _HumanMetricWrap(
                metrics: <(String, String)>[
                  (
                    pickUiText(
                      i18n,
                      zh: '称号',
                      en: 'Title',
                      ja: 'Title',
                      de: 'Title',
                      fr: 'Titre',
                      es: 'Título',
                      ru: 'Название',
                    ),
                    title,
                  ),
                  (
                    pickUiText(
                      i18n,
                      zh: '模式',
                      en: 'Mode',
                      ja: 'Mode',
                      de: 'Mode',
                      fr: 'Mode',
                      es: 'Modo',
                      ru: 'Режим',
                    ),
                    mode,
                  ),
                  (
                    pickUiText(
                      i18n,
                      zh: '分数',
                      en: 'Score',
                      ja: 'Score',
                      de: 'Score',
                      fr: 'Score',
                      es: 'Puntuación',
                      ru: 'счет',
                    ),
                    '$score',
                  ),
                  (
                    pickUiText(
                      i18n,
                      zh: '准确率',
                      en: 'Accuracy',
                      ja: '精度',
                      de: 'Accuracy',
                      fr: 'Accuracy',
                      es: 'Precisión',
                      ru: 'точность',
                    ),
                    '${(accuracy * 100).round()}%',
                  ),
                  (
                    pickUiText(
                      i18n,
                      zh: '最佳连击',
                      en: 'Best combo',
                      ja: 'ベストコンボ',
                      de: 'Best combo',
                      fr: 'Meilleur combo',
                      es: 'Mejor combo',
                      ru: 'Лучшее сочетание',
                    ),
                    '$bestCombo',
                  ),
                  (
                    pickUiText(
                      i18n,
                      zh: '失误',
                      en: 'Mistakes',
                      ja: 'Mistakes',
                      de: 'Mistakes',
                      fr: 'Erreurs',
                      es: 'Errores',
                      ru: 'Ошибки',
                    ),
                    '$mistakes',
                  ),
                  (
                    pickUiText(
                      i18n,
                      zh: '平均反应',
                      en: 'Avg reaction',
                      ja: '平均反応',
                      de: 'Avg reaction',
                      fr: 'Réaction d\' Avg',
                      es: 'Reacción de Avg',
                      ru: 'Авг реакция',
                    ),
                    averageMs == 0 ? '-' : _formatMilliseconds(averageMs),
                  ),
                  (
                    pickUiText(
                      i18n,
                      zh: '同步差',
                      en: 'Sync gap',
                      ja: 'Sync gap',
                      de: 'Sync gap',
                      fr: 'Écart de synchronisation',
                      es: 'Sincronización',
                      ru: 'Синхронный разрыв',
                    ),
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
                      pickUiText(
                        i18n,
                        zh: '左右手负载',
                        en: 'Hand load',
                        ja: 'Hand load',
                        de: 'Hand load',
                        fr: 'Charge manuelle',
                        es: 'Carga de mano',
                        ru: 'Ручная нагрузка',
                      ),
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
                          ja: 'Lower the pace first. Practice ignoring trap cues and landing two-pad strikes inside the sync window.',
                          de: 'Lower the pace first. Practice ignoring trap cues and landing two-pad strikes inside the sync window.',
                          fr: 'Baissez d\'abord le rythme. Pratiquez l\'ignorance des repères de piège et atterrissez deux-pad frappes dans la fenêtre de synchronisation.',
                          es: 'Baja el ritmo primero. Practica ignorando las trampas y aterrizando huelgas de dos patas dentro de la ventana de sincronización.',
                          ru: 'Сначала понизить темп. Практикуйте игнорирование сигналов ловушки и посадку двухпадных ударов внутри синхронного окна.',
                        )
                      : pickUiText(
                          i18n,
                          zh: '表现稳定，可以提高节奏强度或切换到脑裂风暴，增加陷阱和长按压力。',
                          en: 'Performance is stable. Raise the pace or switch to Split-brain storm for more traps and hold pressure.',
                          ja: 'Performance is stable. Raise the pace or switch to Split-brain storm for more traps and hold pressure.',
                          de: 'Performance is stable. Raise the pace or switch to Split-brain storm for more traps and hold pressure.',
                          fr: 'La performance est stable. Augmenter le rythme ou passer à la tempête de Split-cerveau pour plus de pièges et maintenir la pression.',
                          es: 'El rendimiento es estable. Aumente el ritmo o cambie a la tormenta Split-brain para más trampas y mantenga presión.',
                          ru: 'Производительность стабильна. Поднимите темп или переключитесь на шторм с разделенным мозгом для большего количества ловушек и удерживайте давление.',
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
          child: Text(
            pickUiText(
              i18n,
              zh: '关闭',
              en: 'Close',
              ja: '閉じる',
              de: 'Close',
              fr: 'Fermer',
              es: 'Cerca',
              ru: 'Закрыть',
            ),
          ),
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
                '${pickUiText(i18n, zh: '左手', en: 'Left', ja: 'Left', de: 'Left', fr: 'Gauche', es: 'Izquierda', ru: 'Левый')} $leftHits',
                style: theme.textTheme.labelMedium,
              ),
            ),
            Text(
              '${pickUiText(i18n, zh: '右手', en: 'Right', ja: 'Right', de: 'Right', fr: 'Droite', es: 'Bien.', ru: 'Правильно.')} $rightHits',
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

  _BimanualTaskType _leftTaskType = _BimanualTaskType.bounce;
  _BimanualTaskType _rightTaskType = _BimanualTaskType.bounce;
  _BimanualDifficulty _difficulty = _BimanualDifficulty.standard;
  _BrainSplitTracePattern _tracePattern = _BrainSplitTracePattern.mixed;
  _BrainSplitTraceLineStyle _traceLineStyle = _BrainSplitTraceLineStyle.solid;
  _BrainSplitTraceSegmentMode _traceSegmentMode =
      _BrainSplitTraceSegmentMode.straight;
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
  int _traceNodeCount = 6;
  int _bounceBallCount = 1;
  int _bounceTargetRallies = 6;
  int _climbStepCount = 7;
  int _climbPlatformSpeedLevel = 2;
  double _traceMinAngleDegrees = 38;
  double _bounceSpeedScale = 1.08;
  double _bounceBallRadius = 0.043;
  double _bouncePaddleWidth = 0.26;
  double _bouncePaddleHeight = 0.045;
  double _climbPlatformWidth = 0.32;
  double _climbPlatformWidthRandomness = 0.08;
  int _serial = 0;
  bool _running = false;
  bool _done = false;
  bool _roundSettled = false;
  bool _fullscreenOpening = false;
  bool _fullscreenAutoLaunched = false;
  bool _bounceCollisionAcceleration = false;
  bool _traceColorSegments = false;
  bool _infiniteMode = false;
  bool _singleSidePractice = false;
  _BimanualSide _practiceSide = _BimanualSide.left;
  AppI18n _i18n = AppI18n('en');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAutoOpenFullscreen();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _i18n = AppI18n(Localizations.localeOf(context).languageCode);
  }

  int get _laneSuccessCount => _records.fold<int>(
    0,
    (sum, record) =>
        sum +
        (record.plan.leftActive && record.left.success ? 1 : 0) +
        (record.plan.rightActive && record.right.success ? 1 : 0),
  );

  int get _activeLaneAttemptCount =>
      _records.fold<int>(0, (sum, record) => sum + record.plan.activeLaneCount);

  double get _accuracy {
    final attempts = _activeLaneAttemptCount;
    if (attempts == 0) {
      return 0;
    }
    return _laneSuccessCount / attempts;
  }

  int get _averageMs {
    final successfulLaneTimes = <int>[
      for (final record in _records) ...<int>[
        if (record.plan.leftActive && record.left.success)
          record.left.milliseconds,
        if (record.plan.rightActive && record.right.success)
          record.right.milliseconds,
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
        .where(
          (item) =>
              item.plan.leftActive &&
              item.plan.rightActive &&
              item.left.success &&
              item.right.success,
        )
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

  void _setSideTask(_BimanualSide side, _BimanualTaskType type) {
    if (_running) {
      return;
    }
    _updateView(() {
      if (side == _BimanualSide.left) {
        _leftTaskType = type;
      } else {
        _rightTaskType = type;
      }
      _done = false;
    });
  }

  bool _isSideActive(_BimanualSide side) {
    return !_singleSidePractice || side == _practiceSide;
  }

  _BrainSplitLaneResult _practiceRestResult(AppI18n i18n) {
    return _BrainSplitLaneResult(
      success: true,
      milliseconds: 0,
      scoreDelta: 0,
      detail: pickUiText(
        i18n,
        zh: '单侧练习休息',
        en: 'Single-side rest',
        ja: 'Single-side rest',
        de: 'Single-side rest',
        fr: 'Repos latéral',
        es: 'Descanso unilateral',
        ru: 'односторонний отдых',
      ),
    );
  }

  void _applyDifficultyPreset(_BimanualDifficulty difficulty) {
    _difficulty = difficulty;
    switch (difficulty) {
      case _BimanualDifficulty.relaxed:
        _traceNodeCount = 5;
        _traceMinAngleDegrees = 55;
        _traceSegmentMode = _BrainSplitTraceSegmentMode.straight;
        _traceColorSegments = true;
        _bounceSpeedScale = 0.86;
        _bounceBallRadius = 0.050;
        _bounceBallCount = 1;
        _bounceCollisionAcceleration = false;
        _bouncePaddleWidth = 0.32;
        _bouncePaddleHeight = 0.050;
        _bounceTargetRallies = 4;
        _climbStepCount = 5;
        _climbPlatformSpeedLevel = 1;
        _climbPlatformWidth = 0.40;
        _climbPlatformWidthRandomness = 0.00;
      case _BimanualDifficulty.standard:
        _traceNodeCount = 6;
        _traceMinAngleDegrees = 42;
        _traceSegmentMode = _BrainSplitTraceSegmentMode.straight;
        _traceColorSegments = false;
        _bounceSpeedScale = 1.08;
        _bounceBallRadius = 0.043;
        _bounceBallCount = 1;
        _bounceCollisionAcceleration = false;
        _bouncePaddleWidth = 0.26;
        _bouncePaddleHeight = 0.045;
        _bounceTargetRallies = 6;
        _climbStepCount = 7;
        _climbPlatformSpeedLevel = 2;
        _climbPlatformWidth = 0.32;
        _climbPlatformWidthRandomness = 0.08;
      case _BimanualDifficulty.hard:
        _traceNodeCount = 8;
        _traceMinAngleDegrees = 32;
        _traceSegmentMode = _BrainSplitTraceSegmentMode.random;
        _traceColorSegments = true;
        _bounceSpeedScale = 1.32;
        _bounceBallRadius = 0.038;
        _bounceBallCount = 2;
        _bounceCollisionAcceleration = true;
        _bouncePaddleWidth = 0.22;
        _bouncePaddleHeight = 0.038;
        _bounceTargetRallies = 8;
        _climbStepCount = 9;
        _climbPlatformSpeedLevel = 3;
        _climbPlatformWidth = 0.26;
        _climbPlatformWidthRandomness = 0.11;
      case _BimanualDifficulty.expert:
        _traceNodeCount = 9;
        _traceMinAngleDegrees = 24;
        _traceSegmentMode = _BrainSplitTraceSegmentMode.random;
        _traceColorSegments = true;
        _bounceSpeedScale = 1.55;
        _bounceBallRadius = 0.034;
        _bounceBallCount = 3;
        _bounceCollisionAcceleration = true;
        _bouncePaddleWidth = 0.19;
        _bouncePaddleHeight = 0.032;
        _bounceTargetRallies = 10;
        _climbStepCount = 11;
        _climbPlatformSpeedLevel = 4;
        _climbPlatformWidth = 0.22;
        _climbPlatformWidthRandomness = 0.14;
    }
  }

  void _start() {
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
    _beginRound();
    if (_timeLimitMs > 0) {
      _sessionTimer = Timer(Duration(milliseconds: _timeLimitMs), () {
        if (!mounted || !_running) {
          return;
        }
        _expireSession();
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

  void _stopChallenge() {
    if (!_running) {
      return;
    }
    if (_roundSettled) {
      _finish();
      return;
    }
    _settleRound(timeout: true, finishImmediately: true);
  }

  void _beginRound() {
    if (!mounted || !_running) {
      return;
    }
    if (!_infiniteMode && _roundIndex >= _roundCount) {
      _finish();
      return;
    }
    _cancelTimers();
    final plan = _buildRoundPlan();
    _updateView(() {
      _plan = plan;
      _leftResult = plan.leftActive ? null : _practiceRestResult(_i18n);
      _rightResult = plan.rightActive ? null : _practiceRestResult(_i18n);
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
      _settleRound(timeout: true, finishImmediately: _infiniteMode);
    });
  }

  _BrainSplitRoundPlan _buildRoundPlan() {
    final i18n = _i18n;
    final baseDuration = switch (_paceLevel) {
      1 => 18200,
      2 => 14800,
      3 => 12200,
      _ => 10400,
    };
    final pressure = (_roundIndex / math.max(1, _roundCount - 1)).clamp(
      0.0,
      1.0,
    );
    final duration = ((baseDuration - pressure * 3400) * _difficultyTimeFactor)
        .round()
        .clamp(6400, 22000)
        .toInt();
    final serialSeed = _infiniteMode
        ? _roundIndex + _mistakes * 19 + _score * 3
        : _roundIndex;
    final left = _buildTaskSpec(
      _BimanualSide.left,
      _leftTaskType,
      serialSeed + 11,
    );
    final right = _buildTaskSpec(
      _BimanualSide.right,
      _rightTaskType,
      serialSeed + 37,
    );
    final leftActive = _isSideActive(_BimanualSide.left);
    final rightActive = _isSideActive(_BimanualSide.right);
    final label = _singleSidePractice
        ? pickUiText(
            i18n,
            zh: '${_sideLabel(i18n, _practiceSide)}单侧 ${_taskLabel(i18n, _practiceSide == _BimanualSide.left ? _leftTaskType : _rightTaskType)}',
            en: '${_sideLabel(i18n, _practiceSide)} only ${_taskLabel(i18n, _practiceSide == _BimanualSide.left ? _leftTaskType : _rightTaskType)}',
            ja: '${_sideLabel(i18n, _practiceSide)} のみ ${_taskLabel(i18n, _practiceSide == _BimanualSide.left ? _leftTaskType : _rightTaskType)}',
            de: '${_sideLabel(i18n, _practiceSide)} only ${_taskLabel(i18n, _practiceSide == _BimanualSide.left ? _leftTaskType : _rightTaskType)}',
            fr: '${_sideLabel(i18n, _practiceSide)} only ${_taskLabel(i18n, _practiceSide == _BimanualSide.left ? _leftTaskType : _rightTaskType)}',
            es: 'No.',
            ru: '${_sideLabel(i18n, _practiceSide)} только ${_taskLabel(i18n, _practiceSide == _BimanualSide.left ? _leftTaskType : _rightTaskType)}',
          )
        : _pairLabel(i18n, left.type, right.type);

    return _BrainSplitRoundPlan(
      label: label,
      left: left,
      right: right,
      leftActive: leftActive,
      rightActive: rightActive,
      durationMs: duration,
    );
  }

  double get _difficultyTimeFactor {
    return switch (_difficulty) {
      _BimanualDifficulty.relaxed => 1.18,
      _BimanualDifficulty.standard => 1.0,
      _BimanualDifficulty.hard => 0.9,
      _BimanualDifficulty.expert => 0.78,
    };
  }

  int get _difficultyIndex => _BimanualDifficulty.values.indexOf(_difficulty);

  _BrainSplitTaskSpec _buildTaskSpec(
    _BimanualSide side,
    _BimanualTaskType type,
    int seed,
  ) {
    return switch (type) {
      _BimanualTaskType.trace => _buildTraceSpec(side, seed),
      _BimanualTaskType.bounce => _buildBounceSpec(side, seed),
      _BimanualTaskType.climb => _buildClimbSpec(side, seed),
    };
  }

  _BrainSplitTaskSpec _buildTraceSpec(_BimanualSide side, int seed) {
    final i18n = _i18n;
    final pattern = _resolvedTracePattern(seed);
    final patternLabel = _tracePatternLabel(i18n, pattern);
    final lineStyleLabel = _traceLineStyleLabel(i18n, _traceLineStyle);
    final sideLabel = _sideLabel(i18n, side);
    final nodes = (_traceNodeCount + _difficultyIndex - 1 + seed % 2)
        .clamp(4, 10)
        .toInt();
    final threshold = (0.145 - _difficultyIndex * 0.014).clamp(0.085, 0.16);
    return _BrainSplitTaskSpec(
      type: _BimanualTaskType.trace,
      title: pickUiText(
        i18n,
        zh: '$sideLabel 画图 $patternLabel',
        en: '$sideLabel Trace $patternLabel',
        ja: '$sideLabelバウンスハイジャンプトレース $patternLabel',
        de: '$sideLabel Trace $patternLabel',
        fr: '$sideLabel Trace $patternLabel',
        es: '■v0/ título Trace',
        ru: '$sideLabel След $patternLabel',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '随机生成 $nodes 个几何节点，沿 $lineStyleLabel 一笔连完，偏离过远会扣分。',
        en: 'Trace $nodes seeded geometry nodes as one $lineStyleLabel stroke; drifting too far costs points.',
        ja: 'Trace $nodes seeded geometry nodes as one $lineStyleLabel stroke; drifting too far costs points.',
        de: 'Trace $nodes seeded geometry nodes as one $lineStyleLabel stroke; drifting too far costs points.',
        fr: 'Tracez les nœuds géométriques ensemencés comme une course $lineStyleLabel; dériver trop loin coûte des points.',
        es: 'Rastreo de nodos geométricos seededed como uno de ellos; derivando demasiados costos puntos.',
        ru: 'След $nodes засеянные геометрические узлы как один $lineStyleLabel ход; дрейф слишком далеко стоит точек.',
      ),
      goalText: pickUiText(
        i18n,
        zh: '画完随机$patternLabel',
        en: 'Finish random $patternLabel',
        ja: 'Finish random $patternLabel',
        de: 'Finish random $patternLabel',
        fr: 'Terminer au hasard $patternLabel',
        es: 'Finalizar al azar',
        ru: 'Завершить случайный $patternLabel',
      ),
      accent: _traceAccent,
      seed: seed,
      difficulty: _difficulty,
      tracePattern: pattern,
      traceLineStyle: _traceLineStyle,
      traceNodeCount: nodes,
      traceThreshold: threshold.toDouble(),
      traceSegmentMode: _traceSegmentMode,
      traceMinAngleDegrees: _traceMinAngleDegrees,
      traceColorSegments: _traceColorSegments,
    );
  }

  _BrainSplitTaskSpec _buildBounceSpec(_BimanualSide side, int seed) {
    final i18n = _i18n;
    final sideLabel = _sideLabel(i18n, side);
    final rallies = (_bounceTargetRallies + _difficultyIndex + seed % 2)
        .clamp(3, 14)
        .toInt();
    final speedScale = (_bounceSpeedScale + _difficultyIndex * 0.09)
        .clamp(0.65, 2.2)
        .toDouble();
    final paddleWidth = (_bouncePaddleWidth - _difficultyIndex * 0.012)
        .clamp(0.16, 0.36)
        .toDouble();
    final ballRadius = (_bounceBallRadius - _difficultyIndex * 0.001).clamp(
      0.030,
      0.060,
    );
    final bounceObstacles = _buildBounceObstacles(seed);
    return _BrainSplitTaskSpec(
      type: _BimanualTaskType.bounce,
      title: pickUiText(
        i18n,
        zh: '$sideLabel 弹球',
        en: '$sideLabel Bounce',
        ja: '$sideLabel',
        de: '$sideLabel Bounce',
        fr: '$sideLabel Bounce',
        es: '&quot; Rebonce &quot;',
        ru: '$sideLabel Отскок',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '在底部控制区拖动挡板，小球会撞随机障碍，速度 ${speedScale.toStringAsFixed(1)}x，稳住 $rallies 次。',
        en: 'Drag from the lower control strip; the ball rebounds off random bumpers at ${speedScale.toStringAsFixed(1)}x for $rallies rallies.',
        ja: 'Drag from the lower control strip; the ball rebounds off random bumpers at ${speedScale.toStringAsFixed(1)}x for $rallies rallies.',
        de: 'Drag from the lower control strip; the ball rebounds off random bumpers at ${speedScale.toStringAsFixed(1)}x for $rallies rallies.',
        fr: 'Faites glisser de la bande de contrôle inférieure; la balle rebondit des pare-chocs aléatoires à ${speedScale.toStringAsFixed(1)}x pour les rassemblements $rallies.',
        es: 'Arrastre de la tira de control inferior; la bola rebota a los parachoques aleatorios en rallies de <v0/юx.',
        ru: 'Перетащите с нижней контрольной полосы; мяч отскакивает от случайных бамперов на ${speedScale.toStringAsFixed(1)}x для митингов $rallies.',
      ),
      goalText: pickUiText(
        i18n,
        zh: '稳住 $rallies 次回弹',
        en: 'Keep $rallies rallies',
        ja: 'Keep $rallies rallies',
        de: 'Keep $rallies rallies',
        fr: 'Conserver les rassemblements $rallies',
        es: 'Mantener los rallyes',
        ru: 'Сохранить $rallies митинги',
      ),
      accent: _bounceAccent,
      seed: seed,
      difficulty: _difficulty,
      targetCount: rallies,
      speedScale: speedScale,
      ballRadius: ballRadius.toDouble(),
      ballCount: _bounceBallCount,
      collisionAcceleration: _bounceCollisionAcceleration,
      paddleWidth: paddleWidth,
      paddleHeight: _bouncePaddleHeight,
      bounceObstacles: bounceObstacles,
    );
  }

  _BrainSplitTaskSpec _buildClimbSpec(_BimanualSide side, int seed) {
    final i18n = _i18n;
    final sideLabel = _sideLabel(i18n, side);
    final steps = (_climbStepCount + _difficultyIndex + seed % 2)
        .clamp(5, 13)
        .toInt();
    final platformSpeed = (0.78 + _climbPlatformSpeedLevel * 0.18)
        .clamp(0.55, 1.65)
        .toDouble();
    final platforms = _buildClimbPlatforms(steps, seed, platformSpeed);
    return _BrainSplitTaskSpec(
      type: _BimanualTaskType.climb,
      title: pickUiText(
        i18n,
        zh: '$sideLabel 跳高',
        en: '$sideLabel High jump',
        ja: '$sideLabel',
        de: '$sideLabel High jump',
        fr: '$sideLabel High jump',
        es: 'salto alto',
        ru: '<v0/Высокий прыжок',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '看准横向移动平台，点击或按住蓄力逐层跳上去，冲到第 $steps 层。',
        en: 'Time the moving platforms, tap or charge based on difficulty, and climb $steps levels.',
        ja: 'Time the moving platforms, tap or charge based on difficulty, and climb $steps levels.',
        de: 'Time the moving platforms, tap or charge based on difficulty, and climb $steps levels.',
        fr: 'Temps de déplacement des plates-formes, tapoter ou charger en fonction de la difficulté, et monter $steps niveaux.',
        es: 'Tiempo de las plataformas móviles, pulsar o cargar sobre la base de la dificultad, y escalar los niveles de garantía real.',
        ru: 'Время перемещения платформ, нажатие или зарядка в зависимости от сложности и подъем уровня $steps.',
      ),
      goalText: pickUiText(
        i18n,
        zh: '登顶 $steps 层',
        en: 'Reach level $steps',
        ja: 'Reach level $steps',
        de: 'Reach level $steps',
        fr: 'Niveau $steps',
        es: 'Nivel de acceso',
        ru: 'Достижение уровня $steps',
      ),
      accent: _climbAccent,
      seed: seed,
      difficulty: _difficulty,
      targetCount: steps,
      speedScale: platformSpeed,
      platformWidth: _climbPlatformWidth,
      platformWidthRandomness: _climbPlatformWidthRandomness,
      climbPlatforms: platforms,
    );
  }

  List<_BrainSplitBounceObstacle> _buildBounceObstacles(int seed) {
    final random = math.Random(seed * 97 + _difficultyIndex * 131);
    final count = (_difficultyIndex + 1 + seed % 2).clamp(1, 5).toInt();
    return List<_BrainSplitBounceObstacle>.generate(count, (index) {
      final column = count == 1 ? 0.5 : (index + 1) / (count + 1);
      final jitterX = (random.nextDouble() - 0.5) * 0.12;
      final centerY = 0.22 + random.nextDouble() * 0.42;
      final radius = (0.038 + random.nextDouble() * 0.020)
          .clamp(0.034, 0.064)
          .toDouble();
      return _BrainSplitBounceObstacle(
        center: Offset(
          (column + jitterX).clamp(0.18, 0.82).toDouble(),
          centerY.clamp(0.18, 0.66).toDouble(),
        ),
        radius: radius,
      );
    });
  }

  List<_BrainSplitJumpPlatform> _buildClimbPlatforms(
    int steps,
    int seed,
    double platformSpeed,
  ) {
    final random = math.Random(seed * 173 + _difficultyIndex * 41);
    return List<_BrainSplitJumpPlatform>.generate(steps, (index) {
      final level = index + 1;
      final randomWidthOffset = _climbPlatformWidthRandomness <= 0
          ? 0.0
          : (random.nextDouble() * 2 - 1) * _climbPlatformWidthRandomness;
      final width =
          (_climbPlatformWidth -
                  _difficultyIndex * 0.010 -
                  level * 0.002 +
                  randomWidthOffset)
              .clamp(0.16, 0.46)
              .toDouble();
      final speed =
          (platformSpeed * (0.33 + random.nextDouble() * 0.24 + level * 0.012))
              .clamp(0.22, 0.86)
              .toDouble();
      final requiresCharge = switch (_difficulty) {
        _BimanualDifficulty.relaxed => false,
        _BimanualDifficulty.standard => level >= 4 && level.isEven,
        _BimanualDifficulty.hard => level >= 3,
        _BimanualDifficulty.expert => level >= 2,
      };
      final requiredCharge = requiresCharge
          ? (0.44 + _difficultyIndex * 0.08 + random.nextDouble() * 0.15)
                .clamp(0.48, 0.9)
                .toDouble()
          : 0.0;
      return _BrainSplitJumpPlatform(
        level: level,
        width: width,
        speed: speed,
        phase: random.nextDouble(),
        requiredCharge: requiredCharge,
      );
    });
  }

  _BrainSplitTracePattern _resolvedTracePattern(int seed) {
    if (_tracePattern != _BrainSplitTracePattern.mixed) {
      return _tracePattern;
    }
    const patterns = <_BrainSplitTracePattern>[
      _BrainSplitTracePattern.zigzag,
      _BrainSplitTracePattern.wave,
      _BrainSplitTracePattern.star,
      _BrainSplitTracePattern.spiral,
      _BrainSplitTracePattern.box,
      _BrainSplitTracePattern.steps,
      _BrainSplitTracePattern.loop,
      _BrainSplitTracePattern.triangle,
      _BrainSplitTracePattern.square,
      _BrainSplitTracePattern.rectangle,
      _BrainSplitTracePattern.circle,
      _BrainSplitTracePattern.trapezoid,
      _BrainSplitTracePattern.diamond,
      _BrainSplitTracePattern.polyhedron,
    ];
    return patterns[seed % patterns.length];
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
      ja: '$leftLabel /$rightLabel',
      de: '$leftLabel / $rightLabel',
      fr: '$leftLabel / $rightLabel',
      es: '- No.',
      ru: '$leftLabel $rightLabel',
    );
  }

  String _taskLabel(AppI18n i18n, _BimanualTaskType type) {
    return switch (type) {
      _BimanualTaskType.trace => pickUiText(
        i18n,
        zh: '画图',
        en: 'Trace',
        ja: 'Trace',
        de: 'Trace',
        fr: 'Trace',
        es: 'Trace',
        ru: 'след',
      ),
      _BimanualTaskType.bounce => pickUiText(
        i18n,
        zh: '弹球',
        en: 'Bounce',
        ja: 'バウンスバウンス',
        de: 'Bounce',
        fr: 'Bounce',
        es: 'Bounce',
        ru: 'отскакивать',
      ),
      _BimanualTaskType.climb => pickUiText(
        i18n,
        zh: '跳高',
        en: 'High jump',
        ja: 'High jump',
        de: 'High jump',
        fr: 'Saut en hauteur',
        es: 'Alto salto',
        ru: 'Высокий прыжок',
      ),
    };
  }

  String _difficultyLabel(AppI18n i18n, _BimanualDifficulty difficulty) {
    return switch (difficulty) {
      _BimanualDifficulty.relaxed => pickUiText(
        i18n,
        zh: '舒缓',
        en: 'Relaxed',
        ja: 'Relaxed',
        de: 'Relaxed',
        fr: 'Détends-toi',
        es: 'Relajado',
        ru: 'Расслабленный',
      ),
      _BimanualDifficulty.standard => pickUiText(
        i18n,
        zh: '标准',
        en: 'Standard',
        ja: 'Standard',
        de: 'Standard',
        fr: 'Norme',
        es: 'Estándar',
        ru: 'Стандарт',
      ),
      _BimanualDifficulty.hard => pickUiText(
        i18n,
        zh: '困难',
        en: 'Hard',
        ja: 'Hard',
        de: 'Hard',
        fr: 'Dur',
        es: 'Duro',
        ru: 'Жесткий',
      ),
      _BimanualDifficulty.expert => pickUiText(
        i18n,
        zh: '专家',
        en: 'Expert',
        ja: 'Expert',
        de: 'Expert',
        fr: 'Expert',
        es: 'Expert',
        ru: 'эксперт',
      ),
    };
  }

  String _tracePatternLabel(AppI18n i18n, _BrainSplitTracePattern pattern) {
    return switch (pattern) {
      _BrainSplitTracePattern.mixed => pickUiText(
        i18n,
        zh: '混合',
        en: 'Mixed',
        ja: 'Mixed',
        de: 'Mixed',
        fr: 'Mélange',
        es: 'Mezcla',
        ru: 'смешанный',
      ),
      _BrainSplitTracePattern.zigzag => pickUiText(
        i18n,
        zh: '折线',
        en: 'Zigzag',
        ja: 'Zigzag',
        de: 'Zigzag',
        fr: 'Zigzag',
        es: 'Zigzag',
        ru: 'Зигзаг',
      ),
      _BrainSplitTracePattern.wave => pickUiText(
        i18n,
        zh: '波浪',
        en: 'Wave',
        ja: 'Wave',
        de: 'Wave',
        fr: 'Vague',
        es: 'Wave',
        ru: 'волна',
      ),
      _BrainSplitTracePattern.star => pickUiText(
        i18n,
        zh: '星形',
        en: 'Star',
        ja: 'Star',
        de: 'Star',
        fr: 'Étoile',
        es: 'Star',
        ru: 'Звезда',
      ),
      _BrainSplitTracePattern.spiral => pickUiText(
        i18n,
        zh: '螺旋',
        en: 'Spiral',
        ja: 'Spiral',
        de: 'Spiral',
        fr: 'Spirale',
        es: 'Spiral',
        ru: 'спиральный',
      ),
      _BrainSplitTracePattern.box => pickUiText(
        i18n,
        zh: '方框',
        en: 'Box',
        ja: 'ボックス',
        de: 'Box',
        fr: 'Boîte',
        es: 'Recuadro',
        ru: 'Коробка',
      ),
      _BrainSplitTracePattern.steps => pickUiText(
        i18n,
        zh: '阶梯',
        en: 'Steps',
        ja: 'Steps',
        de: 'Steps',
        fr: 'Étapes',
        es: 'Pasos',
        ru: 'Шаги',
      ),
      _BrainSplitTracePattern.loop => pickUiText(
        i18n,
        zh: '回环',
        en: 'Loop',
        ja: 'Loop',
        de: 'Loop',
        fr: 'Boucle',
        es: 'Loop',
        ru: 'Луп',
      ),
      _BrainSplitTracePattern.triangle => pickUiText(
        i18n,
        zh: '三角形',
        en: 'Triangle',
        ja: 'Triangle',
        de: 'Triangle',
        fr: 'Triangle',
        es: 'Triángulo',
        ru: 'Треугольник',
      ),
      _BrainSplitTracePattern.square => pickUiText(
        i18n,
        zh: '正方形',
        en: 'Square',
        ja: 'Square',
        de: 'Square',
        fr: 'Carré',
        es: 'Plaza',
        ru: 'Площадь',
      ),
      _BrainSplitTracePattern.rectangle => pickUiText(
        i18n,
        zh: '长方形',
        en: 'Rectangle',
        ja: 'Rectangle',
        de: 'Rectangle',
        fr: 'Rectangle',
        es: 'Rectángulo',
        ru: 'прямоугольник',
      ),
      _BrainSplitTracePattern.circle => pickUiText(
        i18n,
        zh: '圆形',
        en: 'Circle',
        ja: '円',
        de: 'Circle',
        fr: 'Cercle',
        es: 'Circle',
        ru: 'Круг',
      ),
      _BrainSplitTracePattern.trapezoid => pickUiText(
        i18n,
        zh: '梯形',
        en: 'Trapezoid',
        ja: 'Trapezoid',
        de: 'Trapezoid',
        fr: 'Trapézoïde',
        es: 'Trapezoide',
        ru: 'Трапезоид',
      ),
      _BrainSplitTracePattern.diamond => pickUiText(
        i18n,
        zh: '菱形',
        en: 'Diamond',
        ja: 'Diamond',
        de: 'Diamond',
        fr: 'Diamant',
        es: 'Diamante',
        ru: 'алмаз',
      ),
      _BrainSplitTracePattern.polyhedron => pickUiText(
        i18n,
        zh: '多面体',
        en: 'Polyhedron',
        ja: 'Polyhedron',
        de: 'Polyhedron',
        fr: 'Polyèdre',
        es: 'Polyhedron',
        ru: 'многогранник',
      ),
    };
  }

  String _traceLineStyleLabel(AppI18n i18n, _BrainSplitTraceLineStyle style) {
    return switch (style) {
      _BrainSplitTraceLineStyle.solid => pickUiText(
        i18n,
        zh: '实线',
        en: 'Solid',
        ja: 'Solid',
        de: 'Solid',
        fr: 'Solide',
        es: 'Sólido',
        ru: 'твердый',
      ),
      _BrainSplitTraceLineStyle.dashed => pickUiText(
        i18n,
        zh: '虚线',
        en: 'Dashed',
        ja: 'Dashed',
        de: 'Dashed',
        fr: 'Déchiqueté',
        es: 'Dashed',
        ru: 'разбитый',
      ),
      _BrainSplitTraceLineStyle.dotted => pickUiText(
        i18n,
        zh: '点线',
        en: 'Dotted',
        ja: 'Dotted',
        de: 'Dotted',
        fr: 'Pointillé',
        es: 'Dotted',
        ru: 'точечный',
      ),
      _BrainSplitTraceLineStyle.ribbon => pickUiText(
        i18n,
        zh: '宽带',
        en: 'Ribbon',
        ja: 'Ribbon',
        de: 'Ribbon',
        fr: 'Ruban',
        es: 'Ribbon',
        ru: 'Лента',
      ),
    };
  }

  String _traceSegmentModeLabel(
    AppI18n i18n,
    _BrainSplitTraceSegmentMode mode,
  ) {
    return switch (mode) {
      _BrainSplitTraceSegmentMode.straight => pickUiText(
        i18n,
        zh: '直线',
        en: 'Straight',
        ja: 'Straight',
        de: 'Straight',
        fr: 'Tout droit',
        es: 'Derecho',
        ru: 'Прямой',
      ),
      _BrainSplitTraceSegmentMode.curved => pickUiText(
        i18n,
        zh: '曲线',
        en: 'Curved',
        ja: 'Curved',
        de: 'Curved',
        fr: 'Courbé',
        es: 'Curva',
        ru: 'искривленный',
      ),
      _BrainSplitTraceSegmentMode.random => pickUiText(
        i18n,
        zh: '随机',
        en: 'Random',
        ja: 'Random',
        de: 'Random',
        fr: 'Aléatoire',
        es: 'Aleatorio',
        ru: 'Случайность',
      ),
    };
  }

  String _sideLabel(AppI18n i18n, _BimanualSide side) {
    return switch (side) {
      _BimanualSide.left => pickUiText(
        i18n,
        zh: '左侧',
        en: 'Left',
        ja: 'Left',
        de: 'Left',
        fr: 'Gauche',
        es: 'Izquierda',
        ru: 'Левый',
      ),
      _BimanualSide.right => pickUiText(
        i18n,
        zh: '右侧',
        en: 'Right',
        ja: 'Right',
        de: 'Right',
        fr: 'Droite',
        es: 'Bien.',
        ru: 'Правильно.',
      ),
    };
  }

  void _recordLaneResult(_BimanualSide side, _BrainSplitLaneResult result) {
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
    final leftActive = _plan?.leftActive ?? true;
    final rightActive = _plan?.rightActive ?? true;
    if (!result.success) {
      _settleRound(timeout: false, finishImmediately: !_infiniteMode);
      return;
    }
    if ((!leftActive || _leftResult != null) &&
        (!rightActive || _rightResult != null)) {
      _settleRound(timeout: false);
    }
  }

  void _expireSession() {
    if (!mounted || !_running) {
      return;
    }
    if (_roundSettled) {
      _finish();
      return;
    }
    _settleRound(timeout: true, finishImmediately: true);
  }

  void _settleRound({required bool timeout, bool finishImmediately = false}) {
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
                  _i18n,
                  zh: '未完成',
                  en: 'Incomplete',
                  ja: 'Incomplete',
                  de: 'Incomplete',
                  fr: 'Incomplète',
                  es: 'Incompleto',
                  ru: 'неполный',
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
                  _i18n,
                  zh: '未完成',
                  en: 'Incomplete',
                  ja: 'Incomplete',
                  de: 'Incomplete',
                  fr: 'Incomplète',
                  es: 'Incompleto',
                  ru: 'неполный',
                ),
        );
    final leftSuccess = !plan.leftActive || left.success;
    final rightSuccess = !plan.rightActive || right.success;
    final bothActive = plan.leftActive && plan.rightActive;
    final bothSuccess = leftSuccess && rightSuccess;
    final syncGapMs = bothSuccess && bothActive
        ? (left.milliseconds - right.milliseconds).abs()
        : 0;
    final syncBonus = bothSuccess && bothActive && syncGapMs <= _syncWindowMs
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
        _mistakes +=
            (plan.leftActive && !left.success ? 1 : 0) +
            (plan.rightActive && !right.success ? 1 : 0);
      }
      if (plan.leftActive && left.success) {
        _leftWins += 1;
      }
      if (plan.rightActive && right.success) {
        _rightWins += 1;
      }
      _roundIndex += 1;
      _done =
          finishImmediately || (!_infiniteMode && _roundIndex >= _roundCount);
      _running = !_done;
      _plan = null;
      _leftResult = null;
      _rightResult = null;
      _serial += 1;
    });
    HapticFeedback.lightImpact();
    if (_done) {
      _finish();
      return;
    }
    _advanceTimer = Timer(const Duration(milliseconds: 540), () {
      if (!mounted) {
        return;
      }
      if (_done) {
        _finish();
      } else if (_running) {
        _beginRound();
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
    if (_singleSidePractice) {
      final taskType = _practiceSide == _BimanualSide.left
          ? _leftTaskType
          : _rightTaskType;
      return pickUiText(
        i18n,
        zh: '${_sideLabel(i18n, _practiceSide)}单侧 ${_taskLabel(i18n, taskType)}',
        en: '${_sideLabel(i18n, _practiceSide)} only ${_taskLabel(i18n, taskType)}',
        ja: '${_sideLabel(i18n, _practiceSide)} のみ ${_taskLabel(i18n, taskType)}',
        de: '${_sideLabel(i18n, _practiceSide)} only ${_taskLabel(i18n, taskType)}',
        fr: '${_sideLabel(i18n, _practiceSide)} only ${_taskLabel(i18n, taskType)}',
        es: 'No.',
        ru: '${_sideLabel(i18n, _practiceSide)} только ${_taskLabel(i18n, taskType)}',
      );
    }
    return _pairLabel(i18n, _leftTaskType, _rightTaskType);
  }

  String _timeLimitLabel(AppI18n i18n, int limitMs) {
    return switch (limitMs) {
      0 => pickUiText(
        i18n,
        zh: '无限',
        en: 'Unlimited',
        ja: 'Unlimited',
        de: 'Unlimited',
        fr: 'Illimité',
        es: 'Ilimitados',
        ru: 'неограниченный',
      ),
      180000 => pickUiText(
        i18n,
        zh: '3 分钟',
        en: '3 min',
        ja: '3分',
        de: '3 min',
        fr: '3 min',
        es: '3 min',
        ru: '3 мин.',
      ),
      300000 => pickUiText(
        i18n,
        zh: '5 分钟',
        en: '5 min',
        ja: '5分',
        de: '5 min',
        fr: '5 min',
        es: '5 minutos',
        ru: '5 мин.',
      ),
      600000 => pickUiText(
        i18n,
        zh: '10 分钟',
        en: '10 min',
        ja: '10分',
        de: '10 min',
        fr: '10 min',
        es: '10 min',
        ru: '10 мин.',
      ),
      900000 => pickUiText(
        i18n,
        zh: '15 分钟',
        en: '15 min',
        ja: '15分',
        de: '15 min',
        fr: '15 min',
        es: '15 minutos',
        ru: '15 мин.',
      ),
      _ => _formatMilliseconds(limitMs),
    };
  }

  String _progressLabel(AppI18n i18n) {
    return _infiniteMode
        ? pickUiText(
            i18n,
            zh: '无限 $_roundIndex',
            en: 'Endless $_roundIndex',
            ja: 'Endless $_roundIndex',
            de: 'Endless $_roundIndex',
            fr: 'Sans fin $_roundIndex',
            es: 'Endless',
            ru: 'Бесконечный $_roundIndex',
          )
        : '$_roundIndex/$_roundCount';
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
              pickUiText(
                i18n,
                zh: '进度',
                en: 'Progress',
                ja: 'Progress',
                de: 'Progress',
                fr: 'Progrès accomplis',
                es: 'Progresos',
                ru: 'Прогресс',
              ),
              '$_roundIndex/$_roundCount',
            ),
            (
              pickUiText(
                i18n,
                zh: '时长',
                en: 'Time limit',
                ja: 'Time limit',
                de: 'Time limit',
                fr: 'Délai',
                es: 'Plazo límite',
                ru: 'предельный срок',
              ),
              _timeLimitLabel(i18n, _timeLimitMs),
            ),
            (
              pickUiText(
                i18n,
                zh: '分数',
                en: 'Score',
                ja: 'Score',
                de: 'Score',
                fr: 'Score',
                es: 'Puntuación',
                ru: 'счет',
              ),
              '$_score',
            ),
            (
              pickUiText(
                i18n,
                zh: '连击',
                en: 'Combo',
                ja: 'コンボ',
                de: 'Combo',
                fr: 'Combo',
                es: 'Combo',
                ru: 'Комбинация',
              ),
              '$_combo',
            ),
            (
              pickUiText(
                i18n,
                zh: '准确率',
                en: 'Accuracy',
                ja: '精度',
                de: 'Accuracy',
                fr: 'Accuracy',
                es: 'Precisión',
                ru: 'точность',
              ),
              _records.isEmpty ? '-' : '${(_accuracy * 100).round()}%',
            ),
            (
              pickUiText(
                i18n,
                zh: '平均用时',
                en: 'Avg lane time',
                ja: 'レーン時間',
                de: 'Avg lane time',
                fr: 'Heure de la voie d\'Avg',
                es: 'Tiempo de carril de Avg',
                ru: 'Время в пути',
              ),
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
                  _HumanPill(
                    text:
                        '${_taskLabel(i18n, _leftTaskType)} / ${_taskLabel(i18n, _rightTaskType)}',
                    accent: _accent,
                  ),
                  if (_singleSidePractice)
                    _HumanPill(
                      text: pickUiText(
                        i18n,
                        zh: '${_sideLabel(i18n, _practiceSide)}单侧练习',
                        en: '${_sideLabel(i18n, _practiceSide)} practice',
                        ja: '${_sideLabel(i18n, _practiceSide)}練習',
                        de: '${_sideLabel(i18n, _practiceSide)} practice',
                        fr: '${_sideLabel(i18n, _practiceSide)} practice',
                        es: '■v0/ Práctica',
                        ru: '${_sideLabel(i18n, _practiceSide)} Практика',
                      ),
                      accent: _rightAccent,
                    ),
                  _HumanPill(
                    text: _difficultyLabel(i18n, _difficulty),
                    accent: _dangerAccent,
                  ),
                  _HumanPill(
                    text: plan == null ? '-' : plan.label,
                    accent: plan == null ? _accent : _traceAccent,
                  ),
                  _HumanPill(
                    text:
                        '${pickUiText(i18n, zh: '同步窗', en: 'Sync', ja: 'Sync', de: 'Sync', fr: 'Synchronisation', es: 'Sync', ru: 'синхронизация')} $_syncWindowMs ms',
                    accent: _rightAccent,
                  ),
                  _HumanPill(
                    text:
                        '${pickUiText(i18n, zh: '充能', en: 'Charge', ja: 'チャージ', de: 'Charge', fr: 'Frais', es: 'Carga', ru: 'Зарядка')} $_holdTargetMs ms',
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
                        zh: '默认左右都是弹球，可在设置里自由组合画图、弹球和跳高；也可开启单侧练习。',
                        en: 'Both hands default to Bounce. Freely combine Trace, Bounce, and High jump in settings, or enable single-side practice.',
                        ja: '手はデフォルトでバウンスします。 設定でトレース、バウンス、ハイジャンプを自由に組み合わせるか、片側練習を有効にします。',
                        de: 'Both hands default to Bounce. Freely combine Trace, Bounce, and High jump in settings, or enable single-side practice.',
                        fr: 'Les deux mains par défaut à Bounce. Combinez librement Trace, Bounce et High bond dans les réglages, ou activez la pratique à un seul côté.',
                        es: 'Ambas manos predeterminan a Bounce. Combina libremente Trace, Bounce y Alto salto en la configuración, o habilitar la práctica de un solo lado.',
                        ru: 'Обе руки по умолчанию отскакивают. Свободно комбинируйте Trace, Bounce и High jump в настройках или включите одностороннюю практику.',
                      )
                    : pickUiText(
                        i18n,
                        zh: '${plan.left.goalText}，${plan.right.goalText}。两侧都完成后可获得同步奖励，全屏里操作更顺手。',
                        en: '${plan.left.goalText}. ${plan.right.goalText}. Finish both sides to earn the sync bonus; fullscreen keeps the controls usable.',
                        ja: '${plan.left.goalText} ${plan.right.goalText}。両サイドを完了して同期ボーナスを獲得します。フルスクリーンはコントロールを使用可能にします。',
                        de: '${plan.left.goalText}. ${plan.right.goalText}. Finish both sides to earn the sync bonus; fullscreen keeps the controls usable.',
                        fr: '${plan.left.goalText}. ${plan.right.goalText}. Finish both sides to earn the sync bonus; fullscreen keeps the controls usable.',
                        es: '- No. Termina ambos lados para ganar el bono de sincronización; pantalla completa mantiene los controles utilizables.',
                        ru: '${plan.left.goalText} ${plan.right.goalText}. Заканчивайте обе стороны, чтобы заработать бонус синхронизации; полноэкранный режим поддерживает управление.',
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
                  ? pickUiText(
                      i18n,
                      zh: '正在打开',
                      en: 'Opening',
                      ja: 'Opening',
                      de: 'Opening',
                      fr: 'Ouverture',
                      es: 'Apertura',
                      ru: 'Открытие',
                    )
                  : _running
                  ? pickUiText(
                      i18n,
                      zh: '返回全屏',
                      en: 'Return fullscreen',
                      ja: 'Return fullscreen',
                      de: 'Return fullscreen',
                      fr: 'Retour en plein écran',
                      es: 'Regrese pantalla completa',
                      ru: 'Возврат полноэкранного',
                    )
                  : pickUiText(
                      i18n,
                      zh: '全屏开始',
                      en: 'Fullscreen start',
                      ja: 'Fullscreen start',
                      de: 'Fullscreen start',
                      fr: 'Début en plein écran',
                      es: 'Inicio de pantalla completa',
                      ru: 'Полноэкранный старт',
                    ),
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
          pickUiText(
            i18n,
            zh: '左右自由组合',
            en: 'Free hand pairing',
            ja: 'Free hand pairing',
            de: 'Free hand pairing',
            fr: 'Jumelage à main libre',
            es: 'Pareja de mano libre',
            ru: 'Свободная пара рук',
          ),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        _BrainSplitTaskPicker(
          title: pickUiText(
            i18n,
            zh: '左手模式',
            en: 'Left hand',
            ja: 'Left hand',
            de: 'Left hand',
            fr: 'Main gauche',
            es: 'Mano izquierda',
            ru: 'Левая рука',
          ),
          value: _leftTaskType,
          enabled: !_running,
          i18n: i18n,
          labelFor: _taskLabel,
          onChanged: (type) {
            _setSideTask(_BimanualSide.left, type);
            onChanged?.call();
          },
        ),
        const SizedBox(height: 12),
        _BrainSplitTaskPicker(
          title: pickUiText(
            i18n,
            zh: '右手模式',
            en: 'Right hand',
            ja: 'Right hand',
            de: 'Right hand',
            fr: 'Main droite',
            es: 'Mano derecha',
            ru: 'Правая рука',
          ),
          value: _rightTaskType,
          enabled: !_running,
          i18n: i18n,
          labelFor: _taskLabel,
          onChanged: (type) {
            _setSideTask(_BimanualSide.right, type);
            onChanged?.call();
          },
        ),
        const SizedBox(height: 12),
        Text(
          pickUiText(
            i18n,
            zh: '难度设置',
            en: 'Difficulty',
            ja: 'Difficulty',
            de: 'Difficulty',
            fr: 'Difficulté',
            es: 'Dificultad',
            ru: 'трудность',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _BimanualDifficulty.values
              .map(
                (difficulty) => ChoiceChip(
                  label: Text(_difficultyLabel(i18n, difficulty)),
                  selected: _difficulty == difficulty,
                  onSelected: _running
                      ? null
                      : (_) => applySetting(
                          () => _applyDifficultyPreset(difficulty),
                        ),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _infiniteMode,
          onChanged: _running
              ? null
              : (value) => applySetting(() => _infiniteMode = value ?? false),
          title: Text(
            pickUiText(
              i18n,
              zh: '无限模式',
              en: 'Endless mode',
              ja: 'Endless mode',
              de: 'Endless mode',
              fr: 'Mode sans fin',
              es: 'Modo sin fin',
              ru: 'Бесконечный режим',
            ),
          ),
          subtitle: Text(
            pickUiText(
              i18n,
              zh: '成功持续得分，失败自动重开下一组；手动暂停或时间耗尽后再结算。',
              en: 'Success keeps scoring, failure restarts the stream; stop manually or let the time limit end it.',
              ja: 'Success keeps scoring, failure restarts the stream; stop manually or let the time limit end it.',
              de: 'Success keeps scoring, failure restarts the stream; stop manually or let the time limit end it.',
              fr: 'La réussite continue de marquer, l\'échec redémarre le flux; s\'arrêter manuellement ou laisser la limite de temps finir.',
              es: 'El éxito sigue marcando, el fracaso reinicia el flujo; deténgase manualmente o deje que el límite de tiempo termine.',
              ru: 'Успех продолжает забивать, неудача перезапускает поток; остановитесь вручную или дайте временному пределу закончить его.',
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _singleSidePractice,
          onChanged: _running
              ? null
              : (value) =>
                    applySetting(() => _singleSidePractice = value ?? false),
          title: Text(
            pickUiText(
              i18n,
              zh: '单侧练习',
              en: 'Single-side practice',
              ja: 'Single-side practice',
              de: 'Single-side practice',
              fr: 'Pratique individuelle',
              es: 'Práctica unilateral',
              ru: 'Односторонняя практика',
            ),
          ),
          subtitle: Text(
            pickUiText(
              i18n,
              zh: '默认关闭；开启后只训练选中一侧，另一侧休息且不参与同步分。',
              en: 'Off by default; train one selected side while the other rests and does not count toward sync scoring.',
              ja: 'Off by default; train one selected side while the other rests and does not count toward sync scoring.',
              de: 'Off by default; train one selected side while the other rests and does not count toward sync scoring.',
              fr: 'Désactivez par défaut; entraînez un côté sélectionné tandis que l\'autre repose et ne compte pas vers la synchronisation.',
              es: 'De forma predeterminada; entrena un lado seleccionado mientras el otro descansa y no cuenta hacia la sincronización.',
              ru: 'По умолчанию; тренируйте одну выбранную сторону, в то время как другая отдыхает и не рассчитывает на синхронизацию.',
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                pickUiText(
                  i18n,
                  zh: '练习侧',
                  en: 'Practice side',
                  ja: 'Practice side',
                  de: 'Practice side',
                  fr: 'Côté pratique',
                  es: 'Practicar el lado',
                  ru: 'Практическая сторона',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _BimanualSide.values
                    .map(
                      (side) => ChoiceChip(
                        label: Text(
                          side == _BimanualSide.left
                              ? pickUiText(
                                  i18n,
                                  zh: '只练左侧',
                                  en: 'Left only',
                                  ja: 'Left only',
                                  de: 'Left only',
                                  fr: 'A gauche seulement',
                                  es: 'Izquierda',
                                  ru: 'Осталось только',
                                )
                              : pickUiText(
                                  i18n,
                                  zh: '只练右侧',
                                  en: 'Right only',
                                  ja: 'Right only',
                                  de: 'Right only',
                                  fr: 'Droit seulement',
                                  es: 'Sólo derecho',
                                  ru: 'Правильно только',
                                ),
                        ),
                        selected: _practiceSide == side,
                        onSelected: _running
                            ? null
                            : (_) => applySetting(() => _practiceSide = side),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: pickUiText(
            i18n,
            zh: '画图设置',
            en: 'Trace settings',
            ja: 'Trace settings',
            de: 'Trace settings',
            fr: 'Paramètres des traces',
            es: 'Ajustes de trace',
            ru: 'Настройки трассы',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '每回合按风格随机生成几何一笔画节点，线段样式和节点数同时作用于左右画图赛道。',
            en: 'Each round generates seeded geometric one-stroke nodes; style and checkpoint count apply to every Trace lane.',
            ja: 'Each round generates seeded geometric one-stroke nodes; style and checkpoint count apply to every Trace lane.',
            de: 'Each round generates seeded geometric one-stroke nodes; style and checkpoint count apply to every Trace lane.',
            fr: 'Chaque tour génère des nœuds géométriques à un temps; le style et le nombre de points de contrôle s\'appliquent à chaque voie Trace.',
            es: 'Cada ronda genera nodos geométricos de un solo golpe de semilla; el estilo y la cuenta de control se aplican a cada carril Trace.',
            ru: 'Каждый раунд генерирует семенные геометрические однотактные узлы; стиль и количество контрольных точек применяются к каждой полосе трассы.',
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                pickUiText(
                  i18n,
                  zh: '图案模式',
                  en: 'Pattern mode',
                  ja: 'Pattern mode',
                  de: 'Pattern mode',
                  fr: 'Mode modèle',
                  es: 'Modo de patrón',
                  ru: 'Режим шаблона',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _BrainSplitTracePattern.values
                    .map(
                      (pattern) => ChoiceChip(
                        key: ValueKey<String>(
                          'brain_split_trace_pattern_${pattern.name}',
                        ),
                        label: Text(_tracePatternLabel(i18n, pattern)),
                        selected: _tracePattern == pattern,
                        onSelected: _running
                            ? null
                            : (_) =>
                                  applySetting(() => _tracePattern = pattern),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 12),
              Text(
                pickUiText(
                  i18n,
                  zh: '线段样式',
                  en: 'Line style',
                  ja: 'Line style',
                  de: 'Line style',
                  fr: 'Style de ligne',
                  es: 'Estilo de línea',
                  ru: 'Стиль линии',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _BrainSplitTraceLineStyle.values
                    .map(
                      (style) => ChoiceChip(
                        label: Text(_traceLineStyleLabel(i18n, style)),
                        selected: _traceLineStyle == style,
                        onSelected: _running
                            ? null
                            : (_) =>
                                  applySetting(() => _traceLineStyle = style),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 12),
              Text(
                pickUiText(
                  i18n,
                  zh: '线段几何',
                  en: 'Segment geometry',
                  ja: 'Segment geometry',
                  de: 'Segment geometry',
                  fr: 'Géométrie du segment',
                  es: 'Geometría de segmentos',
                  ru: 'Геометрия сегмента',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _BrainSplitTraceSegmentMode.values
                    .map(
                      (mode) => ChoiceChip(
                        label: Text(_traceSegmentModeLabel(i18n, mode)),
                        selected: _traceSegmentMode == mode,
                        onSelected: _running
                            ? null
                            : (_) =>
                                  applySetting(() => _traceSegmentMode = mode),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 12),
              Text(
                pickUiText(
                  i18n,
                  zh: '节点数量',
                  en: 'Checkpoints',
                  ja: 'チェックポイント',
                  de: 'Checkpoints',
                  fr: 'Points de contrôle',
                  es: 'Puntos de control',
                  ru: 'Контрольные точки',
                ),
              ),
              Slider(
                value: _traceNodeCount.toDouble(),
                min: 4,
                max: 12,
                divisions: 8,
                label: '$_traceNodeCount',
                onChanged: _running
                    ? null
                    : (value) =>
                          applySetting(() => _traceNodeCount = value.round()),
              ),
              Text(
                pickUiText(
                  i18n,
                  zh: '最小角度',
                  en: 'Minimum angle',
                  ja: 'Minimum angle',
                  de: 'Minimum angle',
                  fr: 'Angle minimal',
                  es: 'Ángulo mínimo',
                  ru: 'Минимальный угол',
                ),
              ),
              Slider(
                value: _traceMinAngleDegrees,
                min: 15,
                max: 70,
                divisions: 11,
                label: '${_traceMinAngleDegrees.round()}°',
                onChanged: _running
                    ? null
                    : (value) =>
                          applySetting(() => _traceMinAngleDegrees = value),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _traceColorSegments,
                onChanged: _running
                    ? null
                    : (value) => applySetting(
                        () => _traceColorSegments = value ?? false,
                      ),
                title: Text(
                  pickUiText(
                    i18n,
                    zh: '分段彩色提示',
                    en: 'Color each segment',
                    ja: '各セグメントのカラー',
                    de: 'Color each segment',
                    fr: 'Couleur de chaque segment',
                    es: 'Color cada segmento',
                    ru: 'Цвет каждого сегмента',
                  ),
                ),
                subtitle: Text(
                  pickUiText(
                    i18n,
                    zh: '复杂交叉图形中用颜色和方向箭头凸显下一段。',
                    en: 'Use colors and arrows to clarify the next segment in complex paths.',
                    ja: 'Use colors and arrows to clarify the next segment in complex paths.',
                    de: 'Use colors and arrows to clarify the next segment in complex paths.',
                    fr: 'Utilisez les couleurs et les flèches pour clarifier le segment suivant dans les chemins complexes.',
                    es: 'Utilice colores y flechas para aclarar el siguiente segmento en caminos complejos.',
                    ru: 'Используйте цвета и стрелки для уточнения следующего сегмента сложными путями.',
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: pickUiText(
            i18n,
            zh: '弹球设置',
            en: 'Bounce settings',
            ja: '設定',
            de: 'Bounce settings',
            fr: 'Réglages des rebonds',
            es: 'Ajustes de recompensa',
            ru: 'Настройка отказов',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '小球更小并加入随机障碍碰撞；挡板上移，底部控制条避免手指遮挡。',
            en: 'The smaller ball now hits random bumpers; the paddle sits above a lower control strip so fingers do not cover it.',
            ja: 'The smaller ball now hits random bumpers; the paddle sits above a lower control strip so fingers do not cover it.',
            de: 'The smaller ball now hits random bumpers; the paddle sits above a lower control strip so fingers do not cover it.',
            fr: 'La petite balle frappe maintenant des pare-chocs aléatoires; la pagaie est assise au-dessus d\'une bande de contrôle inférieure afin que les doigts ne la couvrent pas.',
            es: 'La bola más pequeña ahora golpea los parachoques aleatorios; la paleta se sienta por encima de una tira de control inferior por lo que los dedos no lo cubren.',
            ru: 'Меньший шар теперь попадает в случайные бамперы; весло находится над нижней контрольной полосой, поэтому пальцы не покрывают его.',
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                pickUiText(
                  i18n,
                  zh: '小球速率',
                  en: 'Ball speed',
                  ja: 'ボール速度',
                  de: 'Ball speed',
                  fr: 'Vitesse de la bille',
                  es: 'Velocidad de bolas',
                  ru: 'Скорость мяча',
                ),
              ),
              Slider(
                value: _bounceSpeedScale,
                min: 0.7,
                max: 1.7,
                divisions: 10,
                label: '${_bounceSpeedScale.toStringAsFixed(1)}x',
                onChanged: _running
                    ? null
                    : (value) => applySetting(() => _bounceSpeedScale = value),
              ),
              Text(
                pickUiText(
                  i18n,
                  zh: '球的大小',
                  en: 'Ball size',
                  ja: 'ボールサイズ',
                  de: 'Ball size',
                  fr: 'Taille de la boule',
                  es: 'Tamaño de la bola',
                  ru: 'Размер мяча',
                ),
              ),
              Slider(
                value: _bounceBallRadius,
                min: 0.030,
                max: 0.060,
                divisions: 15,
                label: '${(_bounceBallRadius * 100).round()}%',
                onChanged: _running
                    ? null
                    : (value) => applySetting(() => _bounceBallRadius = value),
              ),
              Text(
                pickUiText(
                  i18n,
                  zh: '小球个数',
                  en: 'Ball count',
                  ja: 'ボールカウント',
                  de: 'Ball count',
                  fr: 'Nombre de balles',
                  es: 'Conteo de bolas',
                  ru: 'Количество мячей',
                ),
              ),
              Slider(
                value: _bounceBallCount.toDouble(),
                min: 1,
                max: 3,
                divisions: 2,
                label: '$_bounceBallCount',
                onChanged: _running
                    ? null
                    : (value) =>
                          applySetting(() => _bounceBallCount = value.round()),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _bounceCollisionAcceleration,
                onChanged: _running
                    ? null
                    : (value) => applySetting(
                        () => _bounceCollisionAcceleration = value ?? false,
                      ),
                title: Text(
                  pickUiText(
                    i18n,
                    zh: '碰撞加速',
                    en: 'Collision boost',
                    ja: '衝突',
                    de: 'Collision boost',
                    fr: 'Augmentation de la collision',
                    es: 'Aumento de la colisión',
                    ru: 'Усиление столкновения',
                  ),
                ),
                subtitle: Text(
                  pickUiText(
                    i18n,
                    zh: '关闭时每次碰撞只反弹；开启后挡板和障碍碰撞会逐步提速。',
                    en: 'Off means rebound only; on makes paddle and bumper hits gradually faster.',
                    ja: 'Off means rebound only; on makes paddle and bumper hits gradually faster.',
                    de: 'Off means rebound only; on makes paddle and bumper hits gradually faster.',
                    fr: 'Off signifie rebondissement seulement; sur fait paddle et pare-chocs frappe progressivement plus rapidement.',
                    es: 'Fuera significa rebotar solamente; en hace que el remo y el parachoques golpea gradualmente más rápido.',
                    ru: 'Выключение означает только отскок; на делает весло и бампер удары постепенно быстрее.',
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              Text(
                pickUiText(
                  i18n,
                  zh: '回弹目标',
                  en: 'Rally target',
                  ja: 'Rally target',
                  de: 'Rally target',
                  fr: 'Cible du rallye',
                  es: 'Objetivo del Rally',
                  ru: 'Цель ралли',
                ),
              ),
              Slider(
                value: _bounceTargetRallies.toDouble(),
                min: 3,
                max: 10,
                divisions: 7,
                label: '$_bounceTargetRallies',
                onChanged: _running
                    ? null
                    : (value) => applySetting(
                        () => _bounceTargetRallies = value.round(),
                      ),
              ),
              Text(
                pickUiText(
                  i18n,
                  zh: '挡板宽度',
                  en: 'Paddle width',
                  ja: 'Paddle width',
                  de: 'Paddle width',
                  fr: 'Largeur des pagaies',
                  es: 'Ancho de paleta',
                  ru: 'Ширина седла',
                ),
              ),
              Slider(
                value: _bouncePaddleWidth,
                min: 0.18,
                max: 0.34,
                divisions: 8,
                label: '${(_bouncePaddleWidth * 100).round()}%',
                onChanged: _running
                    ? null
                    : (value) => applySetting(() => _bouncePaddleWidth = value),
              ),
              Text(
                pickUiText(
                  i18n,
                  zh: '挡板厚度',
                  en: 'Paddle thickness',
                  ja: 'Paddle thickness',
                  de: 'Paddle thickness',
                  fr: 'Épaisseur de la pagaie',
                  es: 'Espesor de palanca',
                  ru: 'толщина седла',
                ),
              ),
              Slider(
                value: _bouncePaddleHeight,
                min: 0.026,
                max: 0.07,
                divisions: 11,
                label: '${(_bouncePaddleHeight * 100).round()}%',
                onChanged: _running
                    ? null
                    : (value) =>
                          applySetting(() => _bouncePaddleHeight = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: pickUiText(
            i18n,
            zh: '跳高设置',
            en: 'High jump settings',
            ja: 'High jump settings',
            de: 'High jump settings',
            fr: 'Paramètres de saut élevé',
            es: 'Ajustes de salto alto',
            ru: 'Высокие прыжки',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '跳高改为横向移动平台，点击或按住蓄力逐层跳上平台直到登顶。',
            en: 'High jump now uses horizontally moving platforms; tap or hold to charge and climb to the summit one level at a time.',
            ja: 'High jump now uses horizontally moving platforms; tap or hold to charge and climb to the summit one level at a time.',
            de: 'High jump now uses horizontally moving platforms; tap or hold to charge and climb to the summit one level at a time.',
            fr: 'Le saut en hauteur utilise maintenant des plates-formes en mouvement horizontal; touchez ou maintenez pour charger et monter au sommet un niveau à la fois.',
            es: 'Alto salto ahora utiliza plataformas horizontalmente móviles; pulsar o mantener la carga y subir a la cumbre un nivel a la vez.',
            ru: 'Высокий прыжок теперь использует горизонтально движущиеся платформы; нажмите или удерживайте заряд и поднимайтесь на вершину по одному уровню за раз.',
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                pickUiText(
                  i18n,
                  zh: '平台层数',
                  en: 'Platform levels',
                  ja: 'Platform levels',
                  de: 'Platform levels',
                  fr: 'Niveaux de la plate-forme',
                  es: 'Niveles de la plataforma',
                  ru: 'Уровень платформы',
                ),
              ),
              Slider(
                value: _climbStepCount.toDouble(),
                min: 5,
                max: 11,
                divisions: 6,
                label: '$_climbStepCount',
                onChanged: _running
                    ? null
                    : (value) =>
                          applySetting(() => _climbStepCount = value.round()),
              ),
              Text(
                pickUiText(
                  i18n,
                  zh: '平台宽度',
                  en: 'Platform width',
                  ja: 'Platform width',
                  de: 'Platform width',
                  fr: 'Largeur de la plateforme',
                  es: 'Ancho de plataforma',
                  ru: 'Ширина платформы',
                ),
              ),
              Slider(
                value: _climbPlatformWidth,
                min: 0.18,
                max: 0.44,
                divisions: 13,
                label: '${(_climbPlatformWidth * 100).round()}%',
                onChanged: _running
                    ? null
                    : (value) =>
                          applySetting(() => _climbPlatformWidth = value),
              ),
              Text(
                pickUiText(
                  i18n,
                  zh: '宽度随机区间',
                  en: 'Width randomness',
                  ja: 'Width randomness',
                  de: 'Width randomness',
                  fr: 'Largeur aléatoire',
                  es: 'Aleatoriedad',
                  ru: 'Случайность',
                ),
              ),
              Slider(
                value: _climbPlatformWidthRandomness,
                min: 0,
                max: 0.16,
                divisions: 8,
                label: _climbPlatformWidthRandomness == 0
                    ? pickUiText(
                        i18n,
                        zh: '不随机',
                        en: 'Fixed',
                        ja: 'Fixed',
                        de: 'Fixed',
                        fr: 'Correction',
                        es: 'Fijación',
                        ru: 'фиксированный',
                      )
                    : '±${(_climbPlatformWidthRandomness * 100).round()}%',
                onChanged: _running
                    ? null
                    : (value) => applySetting(
                        () => _climbPlatformWidthRandomness = value,
                      ),
              ),
              Text(
                pickUiText(
                  i18n,
                  zh: '平台速率',
                  en: 'Platform speed',
                  ja: 'Platform speed',
                  de: 'Platform speed',
                  fr: 'Vitesse de la plate-forme',
                  es: 'Velocidad de la plataforma',
                  ru: 'Скорость платформы',
                ),
              ),
              Slider(
                value: _climbPlatformSpeedLevel.toDouble(),
                min: 1,
                max: 4,
                divisions: 3,
                label: '$_climbPlatformSpeedLevel',
                onChanged: _running
                    ? null
                    : (value) => applySetting(
                        () => _climbPlatformSpeedLevel = value.round(),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          pickUiText(
            i18n,
            zh: '轮数',
            en: 'Rounds',
            ja: 'Rounds',
            de: 'Rounds',
            fr: 'Rondes',
            es: 'Rondas',
            ru: 'Круги',
          ),
        ),
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
        Text(
          pickUiText(
            i18n,
            zh: '计时时长',
            en: 'Time limit',
            ja: 'Time limit',
            de: 'Time limit',
            fr: 'Délai',
            es: 'Plazo límite',
            ru: 'предельный срок',
          ),
        ),
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
        Text(
          pickUiText(
            i18n,
            zh: '节奏强度',
            en: 'Pace level',
            ja: 'Pace level',
            de: 'Pace level',
            fr: 'Niveau de Pace',
            es: 'Nivel de rotación',
            ru: 'Уровень темпа',
          ),
        ),
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
        Text(
          pickUiText(
            i18n,
            zh: '同步窗',
            en: 'Sync window',
            ja: 'Sync window',
            de: 'Sync window',
            fr: 'Synchroniser la fenêtre',
            es: 'Ventana sincronizada',
            ru: 'Синхронное окно',
          ),
        ),
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
        Text(
          pickUiText(
            i18n,
            zh: '充能时长',
            en: 'Charge window',
            ja: 'チャージウィンドウ',
            de: 'Charge window',
            fr: 'Fenêtre de chargement',
            es: 'Ventana de carga',
            ru: 'Окно зарядки',
          ),
        ),
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
        mode: _modeLabel(i18n, _BimanualMode.arcade),
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
            pickUiText(
              i18n,
              zh: '双手脑裂设置',
              en: 'Split-brain settings',
              ja: 'Split-brain settings',
              de: 'Split-brain settings',
              fr: 'Réglages des cerveaux fractionnés',
              es: 'Ajustes de doble cerebro',
              ru: 'Сплит-мозг настройки',
            ),
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
                pickUiText(
                  i18n,
                  zh: '关闭',
                  en: 'Close',
                  ja: '閉じる',
                  de: 'Close',
                  fr: 'Fermer',
                  es: 'Cerca',
                  ru: 'Закрыть',
                ),
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
    this.onExit,
  });

  final _BimanualBrainSplitGameState state;
  final AppI18n i18n;
  final bool fullscreen;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    final reportEnabled = state._records.isNotEmpty;
    final actionKey = fullscreen
        ? const ValueKey<String>('brain_split_fullscreen_menu_button')
        : const ValueKey<String>('brain_split_menu_button');
    return PopupMenuButton<_BrainSplitFullscreenAction>(
      key: actionKey,
      tooltip: pickUiText(
        i18n,
        zh: '更多',
        en: 'More',
        ja: 'More',
        de: 'More',
        fr: 'Plus',
        es: 'Más',
        ru: 'Больше',
      ),
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
              state._stopChallenge();
            }
            break;
          case _BrainSplitFullscreenAction.exit:
            onExit?.call();
            break;
        }
      },
      itemBuilder: (context) => <PopupMenuEntry<_BrainSplitFullscreenAction>>[
        PopupMenuItem<_BrainSplitFullscreenAction>(
          value: _BrainSplitFullscreenAction.settings,
          child: Text(
            pickUiText(
              i18n,
              zh: '设置',
              en: 'Settings',
              ja: 'Settings',
              de: 'Settings',
              fr: 'Paramètres',
              es: 'Ajustes',
              ru: 'Настройки',
            ),
          ),
        ),
        PopupMenuItem<_BrainSplitFullscreenAction>(
          value: _BrainSplitFullscreenAction.reset,
          child: Text(
            pickUiText(
              i18n,
              zh: '重置',
              en: 'Reset',
              ja: 'Reset',
              de: 'Reset',
              fr: 'Réinitialiser',
              es: 'Reset',
              ru: 'сброс',
            ),
          ),
        ),
        if (reportEnabled)
          PopupMenuItem<_BrainSplitFullscreenAction>(
            value: _BrainSplitFullscreenAction.report,
            child: Text(
              pickUiText(
                i18n,
                zh: '报告',
                en: 'Report',
                ja: 'Report',
                de: 'Report',
                fr: 'Rapport annuel',
                es: 'Informe',
                ru: 'Доклад',
              ),
            ),
          ),
        if (state._running || fullscreen) const PopupMenuDivider(),
        if (state._running)
          PopupMenuItem<_BrainSplitFullscreenAction>(
            value: _BrainSplitFullscreenAction.stop,
            enabled: state._running,
            child: Text(
              pickUiText(
                i18n,
                zh: '结束挑战',
                en: 'Stop challenge',
                ja: 'Stop challenge',
                de: 'Stop challenge',
                fr: 'Arrêter le défi',
                es: 'Parar el desafío',
                ru: 'Прекратить вызов',
              ),
            ),
          ),
        if (fullscreen)
          PopupMenuItem<_BrainSplitFullscreenAction>(
            value: _BrainSplitFullscreenAction.exit,
            child: Text(
              pickUiText(
                i18n,
                zh: '退出全屏',
                en: 'Exit fullscreen',
                ja: 'Exit fullscreen',
                de: 'Exit fullscreen',
                fr: 'Sortie en plein écran',
                es: 'Exit fullscreen',
                ru: 'Выход Fullscreen',
              ),
            ),
          ),
      ],
    );
  }
}

class _BrainSplitTaskPicker extends StatelessWidget {
  const _BrainSplitTaskPicker({
    required this.title,
    required this.value,
    required this.enabled,
    required this.i18n,
    required this.labelFor,
    required this.onChanged,
  });

  final String title;
  final _BimanualTaskType value;
  final bool enabled;
  final AppI18n i18n;
  final String Function(AppI18n i18n, _BimanualTaskType type) labelFor;
  final ValueChanged<_BimanualTaskType> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _BimanualTaskType.values
              .map(
                (type) => ChoiceChip(
                  label: Text(labelFor(i18n, type)),
                  selected: value == type,
                  onSelected: enabled ? (_) => onChanged(type) : null,
                ),
              )
              .toList(growable: false),
        ),
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
  bool _exiting = false;

  _BimanualBrainSplitGameState get state => widget.state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (widget.autoStart || !state._running) {
        state._start();
      }
    });
  }

  void _toggleStatus() {
    setState(() => _statusExpanded = !_statusExpanded);
  }

  void _exitFullscreen() {
    if (_exiting || !mounted) {
      return;
    }
    _exiting = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _exitFullscreen();
        }
      },
      child: Scaffold(
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
                final narrowLandscape =
                    surfaceSize.width >= surfaceSize.height &&
                    surfaceSize.height < 390;
                final compact =
                    surfaceSize.shortestSide < 390 || surfaceSize.width < 680;
                final dense = narrowLandscape || surfaceSize.height < 430;
                final outerPadding = EdgeInsets.fromLTRB(
                  compact ? 6 : 10,
                  compact ? 6 : 8,
                  compact ? 6 : 10,
                  compact ? 6 : 10,
                );
                return SafeArea(
                  child: Padding(
                    padding: outerPadding,
                    child: Column(
                      children: <Widget>[
                        _BrainSplitFullscreenTopBar(
                          state: state,
                          i18n: i18n,
                          compact: compact,
                          dense: dense,
                          expanded: _statusExpanded,
                          onToggleStatus: _toggleStatus,
                          onExit: _exitFullscreen,
                        ),
                        SizedBox(height: dense ? 6 : 8),
                        Expanded(
                          child: _BrainSplitStage(
                            key: ValueKey<String>(
                              'brain_split_stage_${state._serial}',
                            ),
                            plan: state._plan,
                            running: state._running,
                            done: state._done,
                            leftActive:
                                state._plan?.leftActive ??
                                state._isSideActive(_BimanualSide.left),
                            rightActive:
                                state._plan?.rightActive ??
                                state._isSideActive(_BimanualSide.right),
                            syncWindowMs: state._syncWindowMs,
                            holdTargetMs: state._holdTargetMs,
                            roundToken: state._serial,
                            onLaneResult: (side, result) =>
                                state._recordLaneResult(side, result),
                            modeLabel: state._modeLabel(
                              i18n,
                              _BimanualMode.arcade,
                            ),
                            fullscreen: true,
                            denseFullscreen: dense,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _BrainSplitFullscreenTopBar extends StatelessWidget {
  const _BrainSplitFullscreenTopBar({
    required this.state,
    required this.i18n,
    required this.compact,
    required this.dense,
    required this.expanded,
    required this.onToggleStatus,
    required this.onExit,
  });

  final _BimanualBrainSplitGameState state;
  final AppI18n i18n;
  final bool compact;
  final bool dense;
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
              key: const ValueKey<String>(
                'brain_split_fullscreen_close_button',
              ),
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
            _BrainSplitFullscreenSessionActions(
              state: state,
              i18n: i18n,
              compact: compact || dense,
              onExit: onExit,
            ),
          ],
        ),
        if (expanded && !dense) ...<Widget>[
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
        state._plan?.label ??
        pickUiText(
          i18n,
          zh: '准备中',
          en: 'Preparing',
          ja: 'Preparing',
          de: 'Preparing',
          fr: 'Préparation',
          es: 'Preparación',
          ru: 'Подготовка',
        );
    final summary = compact
        ? '${state._progressLabel(i18n)} · ${state._score}'
        : '${state._progressLabel(i18n)} · $planLabel · ${state._score}';
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 260 : 540),
      child: _HumanTestFullscreenPanel(
        key: const ValueKey<String>('brain_split_fullscreen_status_peek'),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 8 : 9,
        ),
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
                  summary,
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
              label: pickUiText(
                i18n,
                zh: '模式',
                en: 'Mode',
                ja: 'Mode',
                de: 'Mode',
                fr: 'Mode',
                es: 'Modo',
                ru: 'Режим',
              ),
              value: state._modeLabel(i18n, _BimanualMode.arcade),
              accent: _BimanualBrainSplitGameState._accent,
            ),
            _HumanTestFullscreenMetric(
              label: pickUiText(
                i18n,
                zh: '进度',
                en: 'Progress',
                ja: 'Progress',
                de: 'Progress',
                fr: 'Progrès accomplis',
                es: 'Progresos',
                ru: 'Прогресс',
              ),
              value: state._progressLabel(i18n),
              accent: _BimanualBrainSplitGameState._traceAccent,
            ),
            _HumanTestFullscreenMetric(
              label: pickUiText(
                i18n,
                zh: '分数',
                en: 'Score',
                ja: 'Score',
                de: 'Score',
                fr: 'Score',
                es: 'Puntuación',
                ru: 'счет',
              ),
              value: '${state._score}',
              accent: _BimanualBrainSplitGameState._rightAccent,
            ),
            _HumanTestFullscreenMetric(
              label: pickUiText(
                i18n,
                zh: '连击',
                en: 'Combo',
                ja: 'コンボ',
                de: 'Combo',
                fr: 'Combo',
                es: 'Combo',
                ru: 'Комбинация',
              ),
              value: '${state._combo}',
              accent: _BimanualBrainSplitGameState._climbAccent,
            ),
            if (!compact)
              _HumanTestFullscreenMetric(
                label: pickUiText(
                  i18n,
                  zh: '准确率',
                  en: 'Accuracy',
                  ja: '精度',
                  de: 'Accuracy',
                  fr: 'Accuracy',
                  es: 'Precisión',
                  ru: 'точность',
                ),
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
    required this.compact,
    required this.onExit,
  });

  final _BimanualBrainSplitGameState state;
  final AppI18n i18n;
  final bool compact;
  final VoidCallback onExit;

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
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 2 : 4,
        vertical: compact ? 2 : 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            key: const ValueKey<String>('brain_split_fullscreen_start_button'),
            tooltip: state._running
                ? pickUiText(
                    i18n,
                    zh: '结束',
                    en: 'Finish',
                    ja: 'Finish',
                    de: 'Finish',
                    fr: 'Finition',
                    es: 'Acabado',
                    ru: 'Закончить',
                  )
                : pickUiText(
                    i18n,
                    zh: '开始',
                    en: 'Start',
                    ja: 'Start',
                    de: 'Start',
                    fr: 'Démarrer',
                    es: 'Comienzo',
                    ru: 'Начинать',
                  ),
            onPressed: state._running ? state._stopChallenge : state._start,
            icon: Icon(
              state._running ? Icons.stop_rounded : Icons.play_arrow_rounded,
            ),
          ),
          IconButton(
            key: const ValueKey<String>('brain_split_fullscreen_reset_button'),
            tooltip: pickUiText(
              i18n,
              zh: '重置',
              en: 'Reset',
              ja: 'Reset',
              de: 'Reset',
              fr: 'Réinitialiser',
              es: 'Reset',
              ru: 'сброс',
            ),
            onPressed: () {
              state._reset();
              state._start();
            },
            icon: const Icon(Icons.restart_alt_rounded),
          ),
          IconButton(
            key: const ValueKey<String>(
              'brain_split_fullscreen_settings_button',
            ),
            tooltip: pickUiText(
              i18n,
              zh: '设置',
              en: 'Settings',
              ja: 'Settings',
              de: 'Settings',
              fr: 'Paramètres',
              es: 'Ajustes',
              ru: 'Настройки',
            ),
            onPressed: () => _showSettings(context),
            icon: const Icon(Icons.tune_rounded),
          ),
          if (!compact)
            IconButton(
              key: const ValueKey<String>(
                'brain_split_fullscreen_report_button',
              ),
              tooltip: pickUiText(
                i18n,
                zh: '报告',
                en: 'Report',
                ja: 'Report',
                de: 'Report',
                fr: 'Rapport annuel',
                es: 'Informe',
                ru: 'Доклад',
              ),
              onPressed: reportEnabled
                  ? () => state._showReport(context)
                  : null,
              icon: const Icon(Icons.assessment_rounded),
            ),
          _BrainSplitActionMenuButton(
            state: state,
            i18n: i18n,
            fullscreen: true,
            onExit: onExit,
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
      title: Text(
        pickUiText(
          i18n,
          zh: '双手协调设置',
          en: 'Bimanual settings',
          ja: 'バイマニュアル設定',
          de: 'Bimanual settings',
          fr: 'Paramètres bimanuels',
          es: 'Ajustes bimanuales',
          ru: 'Бирумные настройки',
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: _HumanSettingsSection(
            title: pickUiText(
              i18n,
              zh: '脑裂挑战设置',
              en: 'Split-brain settings',
              ja: 'Split-brain settings',
              de: 'Split-brain settings',
              fr: 'Réglages des cerveaux fractionnés',
              es: 'Ajustes de doble cerebro',
              ru: 'Сплит-мозг настройки',
            ),
            subtitle: pickUiText(
              i18n,
              zh: '进行中参数会锁定；重置后立即按新设置开局。',
              en: 'Running sessions lock settings; reset to restart with new values.',
              ja: 'Running sessions lock settings; reset to restart with new values.',
              de: 'Running sessions lock settings; reset to restart with new values.',
              fr: 'Lancer des sessions verrouiller les paramètres; réinitialiser pour redémarrer avec de nouvelles valeurs.',
              es: 'Realizar sesiones de configuración de bloqueo; reiniciar para reiniciar con nuevos valores.',
              ru: 'Запуск сеансов блокировки настроек; сброс для перезапуска с новыми значениями.',
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
    required this.leftActive,
    required this.rightActive,
    required this.syncWindowMs,
    required this.holdTargetMs,
    required this.roundToken,
    required this.onLaneResult,
    required this.modeLabel,
    this.fullscreen = false,
    this.denseFullscreen = false,
  });

  final _BrainSplitRoundPlan? plan;
  final bool running;
  final bool done;
  final bool leftActive;
  final bool rightActive;
  final int syncWindowMs;
  final int holdTargetMs;
  final int roundToken;
  final void Function(_BimanualSide side, _BrainSplitLaneResult result)
  onLaneResult;
  final String modeLabel;
  final bool fullscreen;
  final bool denseFullscreen;

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
            ja: 'Preparing left and right tasks.',
            de: 'Preparing left and right tasks.',
            fr: 'Préparation des tâches gauche et droite.',
            es: 'Preparando tareas izquierda y derecha.',
            ru: 'Подготовка левых и правых задач.',
          )
        : currentPlan.leftActive && currentPlan.rightActive
        ? pickUiText(
            i18n,
            zh: '${currentPlan.left.goalText}，${currentPlan.right.goalText}。',
            en: '${currentPlan.left.goalText}. ${currentPlan.right.goalText}.',
            ja: '${currentPlan.left.goalText}ます${currentPlan.right.goalText}。',
            de: '${currentPlan.left.goalText}. ${currentPlan.right.goalText}.',
            fr: '${currentPlan.left.goalText}. ${currentPlan.right.goalText}.',
            es: '- No.',
            ru: '${currentPlan.left.goalText} ${currentPlan.right.goalText}.',
          )
        : currentPlan.leftActive
        ? currentPlan.left.goalText
        : currentPlan.right.goalText;
    final stageContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (!denseFullscreen) ...<Widget>[
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
                    pickUiText(
                      i18n,
                      zh: '等待配对',
                      en: 'Waiting for pair',
                      ja: 'Waiting for pair',
                      de: 'Waiting for pair',
                      fr: 'Attendre la paire',
                      es: 'Esperando pareja',
                      ru: 'В ожидании пары',
                    ),
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
          const SizedBox(height: 10),
          Text(
            goalText,
            maxLines: fullscreen ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style:
                (fullscreen
                        ? theme.textTheme.labelLarge
                        : theme.textTheme.bodySmall)
                    ?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                      fontWeight: fullscreen ? FontWeight.w800 : null,
                    ),
          ),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 380;
              final laneGap = denseFullscreen || compact ? 6.0 : 12.0;
              final left = KeyedSubtree(
                key: const ValueKey<String>('brain_split_left_slot'),
                child: _BrainSplitLaneView(
                  key: ValueKey<String>('brain_split_left_$roundToken'),
                  side: _BimanualSide.left,
                  spec: plan?.left,
                  active: leftActive,
                  running: running && leftActive,
                  holdTargetMs: holdTargetMs,
                  onCompleted: (result) =>
                      onLaneResult(_BimanualSide.left, result),
                  fullscreen: fullscreen,
                  denseFullscreen: denseFullscreen,
                ),
              );
              final right = KeyedSubtree(
                key: const ValueKey<String>('brain_split_right_slot'),
                child: _BrainSplitLaneView(
                  key: ValueKey<String>('brain_split_right_$roundToken'),
                  side: _BimanualSide.right,
                  spec: plan?.right,
                  active: rightActive,
                  running: running && rightActive,
                  holdTargetMs: holdTargetMs,
                  onCompleted: (result) =>
                      onLaneResult(_BimanualSide.right, result),
                  fullscreen: fullscreen,
                  denseFullscreen: denseFullscreen,
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
            text: pickUiText(
              i18n,
              zh: '本轮已结束',
              en: 'Round complete',
              ja: 'Round complete',
              de: 'Round complete',
              fr: 'Cycle terminé',
              es: 'Ronda completa',
              ru: 'Полный раунд',
            ),
            accent: BimanualCoordinationTestPage._dangerAccent,
          ),
        ],
      ],
    );
    if (fullscreen) {
      return _BrainSplitFullscreenStageSurface(
        dense: denseFullscreen,
        child: stageContent,
      );
    }
    return SizedBox(
      height: 430,
      child: _HumanPanel(
        padding: const EdgeInsets.all(14),
        child: stageContent,
      ),
    );
  }
}

class _BrainSplitFullscreenStageSurface extends StatelessWidget {
  const _BrainSplitFullscreenStageSurface({
    required this.child,
    required this.dense,
  });

  final Widget child;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(dense ? 14 : 22),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: Padding(padding: EdgeInsets.all(dense ? 6 : 12), child: child),
    );
  }
}

class _BrainSplitLaneView extends StatelessWidget {
  const _BrainSplitLaneView({
    super.key,
    required this.side,
    required this.spec,
    required this.active,
    required this.running,
    required this.holdTargetMs,
    required this.onCompleted,
    this.fullscreen = false,
    this.denseFullscreen = false,
  });

  final _BimanualSide side;
  final _BrainSplitTaskSpec? spec;
  final bool active;
  final bool running;
  final int holdTargetMs;
  final ValueChanged<_BrainSplitLaneResult> onCompleted;
  final bool fullscreen;
  final bool denseFullscreen;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final accent = spec?.accent ?? _BimanualBrainSplitGameState._accent;
    final sideLabel = switch (side) {
      _BimanualSide.left => pickUiText(
        i18n,
        zh: '左侧',
        en: 'Left',
        ja: 'Left',
        de: 'Left',
        fr: 'Gauche',
        es: 'Izquierda',
        ru: 'Левый',
      ),
      _BimanualSide.right => pickUiText(
        i18n,
        zh: '右侧',
        en: 'Right',
        ja: 'Right',
        de: 'Right',
        fr: 'Droite',
        es: 'Bien.',
        ru: 'Правильно.',
      ),
    };

    if (spec == null) {
      return _BrainSplitLaneFrame(
        accent: accent,
        title: sideLabel,
        subtitle: pickUiText(
          i18n,
          zh: '等待配对',
          en: 'Waiting for pair',
          ja: 'Waiting for pair',
          de: 'Waiting for pair',
          fr: 'Attendre la paire',
          es: 'Esperando pareja',
          ru: 'В ожидании пары',
        ),
        goalText: '-',
        progressText: '0/0',
        progressValue: 0,
        statusText: pickUiText(
          i18n,
          zh: '未开始',
          en: 'Idle',
          ja: 'Idle',
          de: 'Idle',
          fr: 'Idée',
          es: 'Idle',
          ru: 'безделье',
        ),
        fullscreen: fullscreen,
        denseFullscreen: denseFullscreen,
        child: const SizedBox.shrink(),
      );
    }

    if (!active) {
      return _BrainSplitLaneFrame(
        accent: accent,
        title: sideLabel,
        subtitle: pickUiText(
          i18n,
          zh: '单侧练习中，此侧休息',
          en: 'Resting during single-side practice',
          ja: 'Resting during single-side practice',
          de: 'Resting during single-side practice',
          fr: 'Le repos pendant la pratique à un seul côté',
          es: 'Descansar durante la práctica unilateral',
          ru: 'Отдых во время односторонней практики',
        ),
        goalText: pickUiText(
          i18n,
          zh: '休息侧',
          en: 'Rest side',
          ja: 'Rest side',
          de: 'Rest side',
          fr: 'Côté repos',
          es: 'Descanso lado',
          ru: 'Отдых в стороне',
        ),
        progressText: '-',
        progressValue: 0,
        statusText: pickUiText(
          i18n,
          zh: '未计入本轮',
          en: 'Not counted',
          ja: 'Not counted',
          de: 'Not counted',
          fr: 'Non compté',
          es: 'No cuenta',
          ru: 'Не считается',
        ),
        fullscreen: fullscreen,
        denseFullscreen: denseFullscreen,
        child: Center(
          child: Icon(
            Icons.pause_circle_outline_rounded,
            color: accent.withValues(alpha: 0.68),
            size: denseFullscreen ? 34 : 46,
          ),
        ),
      );
    }

    return switch (spec!.type) {
      _BimanualTaskType.trace => _BrainSplitTraceLane(
        key: ValueKey<String>('brain_split_trace_${spec!.seed}_$side'),
        spec: spec!,
        running: running,
        onCompleted: onCompleted,
        fullscreen: fullscreen,
        denseFullscreen: denseFullscreen,
      ),
      _BimanualTaskType.bounce => _BrainSplitBounceLane(
        key: ValueKey<String>('brain_split_bounce_${spec!.seed}_$side'),
        spec: spec!,
        running: running,
        onCompleted: onCompleted,
        fullscreen: fullscreen,
        denseFullscreen: denseFullscreen,
      ),
      _BimanualTaskType.climb => _BrainSplitClimbLane(
        key: ValueKey<String>('brain_split_climb_${spec!.seed}_$side'),
        spec: spec!,
        running: running,
        holdTargetMs: holdTargetMs,
        onCompleted: onCompleted,
        fullscreen: fullscreen,
        denseFullscreen: denseFullscreen,
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
    this.denseFullscreen = false,
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
  final bool denseFullscreen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final compact = constraints.maxWidth < 180 || denseFullscreen;
        final immersiveCompact = fullscreen && denseFullscreen;
        final padding = EdgeInsets.all(
          denseFullscreen
              ? 7
              : fullscreen
              ? (compact ? 9 : 12)
              : (compact ? 10 : 12),
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
              if (!immersiveCompact) ...<Widget>[
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
              ] else ...<Widget>[
                Align(
                  alignment: Alignment.centerRight,
                  child: _HumanPill(text: progressText, accent: accent),
                ),
              ],
              if (!immersiveCompact && (!fullscreen || !compact)) ...<Widget>[
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
              SizedBox(
                height: immersiveCompact
                    ? 2
                    : (denseFullscreen ? 3 : (compact ? 4 : 6)),
              ),
              if (!immersiveCompact)
                Text(
                  goalText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              SizedBox(
                height: immersiveCompact
                    ? 2
                    : (denseFullscreen ? 4 : (compact ? 6 : 8)),
              ),
              Expanded(child: child),
              if (!fullscreen || (!compact && !denseFullscreen)) ...<Widget>[
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
              SizedBox(height: denseFullscreen ? 3 : (compact ? 4 : 8)),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: denseFullscreen ? 5 : (compact ? 6 : 8),
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
    this.denseFullscreen = false,
  });

  final _BrainSplitTaskSpec spec;
  final bool running;
  final ValueChanged<_BrainSplitLaneResult> onCompleted;
  final bool fullscreen;
  final bool denseFullscreen;

  @override
  State<_BrainSplitTraceLane> createState() => _BrainSplitTraceLaneState();
}

class _BrainSplitTraceLaneState extends State<_BrainSplitTraceLane> {
  final Stopwatch _stopwatch = Stopwatch();
  List<Offset> _path = <Offset>[];
  List<Offset> _drawnPoints = <Offset>[];
  List<double> _pathDistances = <double>[];
  Offset? _pointer;
  Offset? _lastPointer;
  int _nextIndex = 1;
  double _segmentProgress = 0;
  double _traceProgressDistance = 0;
  double _traceTotalDistance = 0;
  double _drawnDistance = 0;
  int _traceSampleCount = 0;
  bool _completed = false;
  bool _started = false;
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
        oldWidget.spec.tracePattern != widget.spec.tracePattern ||
        oldWidget.spec.traceLineStyle != widget.spec.traceLineStyle ||
        oldWidget.spec.traceSegmentMode != widget.spec.traceSegmentMode ||
        oldWidget.spec.traceNodeCount != widget.spec.traceNodeCount ||
        oldWidget.spec.traceThreshold != widget.spec.traceThreshold ||
        oldWidget.spec.traceMinAngleDegrees !=
            widget.spec.traceMinAngleDegrees ||
        oldWidget.spec.traceColorSegments != widget.spec.traceColorSegments ||
        oldWidget.running != widget.running) {
      _reset();
    }
  }

  void _reset() {
    _path = _buildPath(
      widget.spec.seed,
      widget.spec.tracePattern,
      widget.spec.traceNodeCount,
    );
    _pathDistances = _buildPathDistances(_path);
    _drawnPoints = <Offset>[];
    _pointer = null;
    _lastPointer = null;
    _nextIndex = 1;
    _segmentProgress = 0;
    _traceProgressDistance = 0;
    _traceTotalDistance = _pathDistances.isEmpty ? 0 : _pathDistances.last;
    _drawnDistance = 0;
    _traceSampleCount = 0;
    _completed = false;
    _started = false;
    _mistakes = 0;
    _stopwatch
      ..stop()
      ..reset();
    if (widget.running) {
      _stopwatch.start();
    }
  }

  List<Offset> _buildPath(
    int seed,
    _BrainSplitTracePattern pattern,
    int requestedCount,
  ) {
    final count = requestedCount.clamp(4, 12).toInt();
    final fixedGeometry = _buildFixedGeometryPath(pattern, count);
    if (fixedGeometry.isNotEmpty) {
      return fixedGeometry;
    }
    final random = math.Random(seed * 1009 + pattern.index * 97 + count * 13);
    if (widget.spec.traceSegmentMode == _BrainSplitTraceSegmentMode.random ||
        widget.spec.traceMinAngleDegrees > 15) {
      final constrained = _buildDirectedPath(seed, pattern, count, random);
      if (constrained.isNotEmpty) {
        return constrained;
      }
    }
    switch (pattern) {
      case _BrainSplitTracePattern.mixed:
        return _buildPath(
          seed,
          _BrainSplitTracePattern.values[1 +
              seed % (_BrainSplitTracePattern.values.length - 1)],
          count,
        );
      case _BrainSplitTracePattern.zigzag:
        return List<Offset>.generate(count, (index) {
          final t = count == 1 ? 0.0 : index / (count - 1);
          final jitterX = (random.nextDouble() - 0.5) * 0.045;
          final high = 0.29 + random.nextDouble() * 0.08;
          final low = 0.71 - random.nextDouble() * 0.08;
          final y = index.isEven ? low : high;
          return _traceNode(0.12 + t * 0.76 + jitterX, y);
        });
      case _BrainSplitTracePattern.wave:
        return List<Offset>.generate(count, (index) {
          final t = count == 1 ? 0.0 : index / (count - 1);
          final phase = random.nextDouble() * math.pi * 0.8;
          final amplitude = 0.17 + random.nextDouble() * 0.07;
          final wave = math.sin(
            (t * (1.7 + random.nextDouble() * 0.8)) * math.pi + phase,
          );
          return _traceNode(
            0.10 + t * 0.80,
            0.50 + wave * amplitude + (random.nextDouble() - 0.5) * 0.035,
          );
        });
      case _BrainSplitTracePattern.star:
        final center = const Offset(0.5, 0.5);
        final phase = -math.pi / 2 + random.nextDouble() * math.pi * 0.18;
        return List<Offset>.generate(count, (index) {
          final angle =
              phase + index * math.pi * (1.42 + random.nextDouble() * 0.22);
          final radius =
              (index.isEven ? 0.38 : 0.18) + (random.nextDouble() - 0.5) * 0.07;
          return _traceNode(
            center.dx + math.cos(angle) * radius,
            center.dy + math.sin(angle) * radius,
          );
        });
      case _BrainSplitTracePattern.spiral:
        final phase = random.nextDouble() * math.pi;
        return List<Offset>.generate(count, (index) {
          final t = count == 1 ? 0.0 : index / (count - 1);
          final angle =
              phase + t * math.pi * (2.05 + random.nextDouble() * 0.85);
          final radius = 0.10 + t * (0.34 + random.nextDouble() * 0.05);
          return _traceNode(
            0.5 + math.cos(angle) * radius,
            0.52 + math.sin(angle) * radius,
          );
        });
      case _BrainSplitTracePattern.box:
        final left = 0.10 + random.nextDouble() * 0.06;
        final right = 0.82 + random.nextDouble() * 0.08;
        final top = 0.14 + random.nextDouble() * 0.06;
        final bottom = 0.76 + random.nextDouble() * 0.10;
        final midX = 0.38 + random.nextDouble() * 0.24;
        final midY = 0.42 + random.nextDouble() * 0.18;
        final anchors = <Offset>[
          _traceNode(left, top),
          _traceNode(right, top),
          _traceNode(right, bottom),
          _traceNode(left, bottom),
          _traceNode(left, midY),
          _traceNode(midX, midY),
          _traceNode(midX, top + (bottom - top) * 0.68),
          _traceNode(right - 0.14, top + (bottom - top) * 0.68),
          _traceNode(right - 0.14, top + (bottom - top) * 0.44),
          _traceNode(left + 0.22, top + (bottom - top) * 0.44),
        ];
        return anchors.take(count).toList(growable: false);
      case _BrainSplitTracePattern.steps:
        return List<Offset>.generate(count, (index) {
          final t = count == 1 ? 0.0 : index / (count - 1);
          final stair = index / math.max(1, count - 1);
          final x =
              0.14 +
              (index.isEven
                  ? t * 0.72
                  : (t - 0.06 - random.nextDouble() * 0.06) * 0.72);
          return _traceNode(
            x,
            0.78 - stair * (0.50 + random.nextDouble() * 0.08),
          );
        });
      case _BrainSplitTracePattern.loop:
        final phase = random.nextDouble() * math.pi;
        final verticalPhase = seed.isEven ? 0.0 : math.pi / 2;
        return List<Offset>.generate(count, (index) {
          final t = count == 1 ? 0.0 : index / (count - 1);
          final angle = t * math.pi * 2;
          final x =
              0.5 +
              math.sin(angle + phase) * (0.26 + random.nextDouble() * 0.06);
          final y =
              0.5 +
              math.sin(angle * 2 + verticalPhase + phase * 0.3) *
                  (0.18 + random.nextDouble() * 0.05);
          return _traceNode(x, y);
        });
      case _BrainSplitTracePattern.triangle:
      case _BrainSplitTracePattern.square:
      case _BrainSplitTracePattern.rectangle:
      case _BrainSplitTracePattern.circle:
      case _BrainSplitTracePattern.trapezoid:
      case _BrainSplitTracePattern.diamond:
      case _BrainSplitTracePattern.polyhedron:
        return _buildFixedGeometryPath(pattern, count);
    }
  }

  List<Offset> _buildFixedGeometryPath(
    _BrainSplitTracePattern pattern,
    int requestedCount,
  ) {
    switch (pattern) {
      case _BrainSplitTracePattern.triangle:
        return <Offset>[
          const Offset(0.50, 0.12),
          const Offset(0.86, 0.82),
          const Offset(0.14, 0.82),
          const Offset(0.50, 0.12),
        ];
      case _BrainSplitTracePattern.square:
        return <Offset>[
          const Offset(0.18, 0.18),
          const Offset(0.82, 0.18),
          const Offset(0.82, 0.82),
          const Offset(0.18, 0.82),
          const Offset(0.18, 0.18),
        ];
      case _BrainSplitTracePattern.rectangle:
        return <Offset>[
          const Offset(0.12, 0.25),
          const Offset(0.88, 0.25),
          const Offset(0.88, 0.75),
          const Offset(0.12, 0.75),
          const Offset(0.12, 0.25),
        ];
      case _BrainSplitTracePattern.circle:
        final count = requestedCount.clamp(8, 12).toInt();
        return List<Offset>.generate(count + 1, (index) {
          final angle = -math.pi / 2 + index / count * math.pi * 2;
          return Offset(
            0.5 + math.cos(angle) * 0.34,
            0.5 + math.sin(angle) * 0.34,
          );
        });
      case _BrainSplitTracePattern.trapezoid:
        return <Offset>[
          const Offset(0.32, 0.18),
          const Offset(0.68, 0.18),
          const Offset(0.88, 0.80),
          const Offset(0.12, 0.80),
          const Offset(0.32, 0.18),
        ];
      case _BrainSplitTracePattern.diamond:
        return <Offset>[
          const Offset(0.50, 0.10),
          const Offset(0.88, 0.50),
          const Offset(0.50, 0.90),
          const Offset(0.12, 0.50),
          const Offset(0.50, 0.10),
        ];
      case _BrainSplitTracePattern.polyhedron:
        return <Offset>[
          const Offset(0.50, 0.10),
          const Offset(0.84, 0.30),
          const Offset(0.78, 0.72),
          const Offset(0.50, 0.90),
          const Offset(0.22, 0.72),
          const Offset(0.16, 0.30),
          const Offset(0.50, 0.10),
          const Offset(0.78, 0.72),
          const Offset(0.16, 0.30),
          const Offset(0.84, 0.30),
          const Offset(0.22, 0.72),
        ];
      case _:
        return const <Offset>[];
    }
  }

  Offset _traceNode(double x, double y) {
    return Offset(
      x.clamp(0.10, 0.90).toDouble(),
      y.clamp(0.14, 0.86).toDouble(),
    );
  }

  List<Offset> _buildDirectedPath(
    int seed,
    _BrainSplitTracePattern pattern,
    int count,
    math.Random random,
  ) {
    final startAngle = switch (pattern) {
      _BrainSplitTracePattern.zigzag => seed.isEven ? 0.0 : math.pi,
      _BrainSplitTracePattern.wave => math.pi * 0.08,
      _BrainSplitTracePattern.star => -math.pi / 2,
      _BrainSplitTracePattern.spiral => seed * 0.37,
      _BrainSplitTracePattern.box => seed.isEven ? 0.0 : math.pi / 2,
      _BrainSplitTracePattern.steps => -math.pi / 5,
      _BrainSplitTracePattern.loop => seed * 0.22,
      _BrainSplitTracePattern.mixed => seed * 0.19,
      _BrainSplitTracePattern.triangle => -math.pi / 2,
      _BrainSplitTracePattern.square => 0.0,
      _BrainSplitTracePattern.rectangle => 0.0,
      _BrainSplitTracePattern.circle => -math.pi / 2,
      _BrainSplitTracePattern.trapezoid => 0.0,
      _BrainSplitTracePattern.diamond => -math.pi / 2,
      _BrainSplitTracePattern.polyhedron => -math.pi / 2,
    };
    final minAngle =
        widget.spec.traceMinAngleDegrees.clamp(15.0, 80.0) * math.pi / 180;
    final points = <Offset>[_traceNode(0.5, 0.52)];
    var previousAngle = startAngle;
    for (var index = 1; index < count; index += 1) {
      Offset? accepted;
      for (var attempt = 0; attempt < 24; attempt += 1) {
        final directionJitter = switch (pattern) {
          _BrainSplitTracePattern.zigzag =>
            (index.isEven ? 1 : -1) * (math.pi * 0.55),
          _BrainSplitTracePattern.wave =>
            math.sin(index * 0.9 + seed) * math.pi * 0.36,
          _BrainSplitTracePattern.star => math.pi * 1.42,
          _BrainSplitTracePattern.spiral => math.pi * 0.42 + index * 0.12,
          _BrainSplitTracePattern.box => math.pi / 2,
          _BrainSplitTracePattern.steps => index.isEven ? 0.0 : -math.pi / 2,
          _BrainSplitTracePattern.loop => math.pi * 0.72,
          _BrainSplitTracePattern.mixed =>
            (random.nextDouble() - 0.5) * math.pi * 1.6,
          _BrainSplitTracePattern.triangle => math.pi * 2 / 3,
          _BrainSplitTracePattern.square => math.pi / 2,
          _BrainSplitTracePattern.rectangle => math.pi / 2,
          _BrainSplitTracePattern.circle => math.pi / 5,
          _BrainSplitTracePattern.trapezoid => math.pi / 2,
          _BrainSplitTracePattern.diamond => math.pi / 2,
          _BrainSplitTracePattern.polyhedron => math.pi / 3,
        };
        final angle =
            previousAngle +
            directionJitter.toDouble() +
            (random.nextDouble() - 0.5) * math.pi * 0.46;
        final delta = _angleDelta(angle, previousAngle).abs();
        if (index > 1 && delta < minAngle && attempt < 18) {
          continue;
        }
        final length = 0.16 + random.nextDouble() * 0.22;
        final current = points.last;
        final candidate = _traceNode(
          current.dx + math.cos(angle) * length,
          current.dy + math.sin(angle) * length,
        );
        if ((candidate - current).distance < 0.12 && attempt < 20) {
          continue;
        }
        accepted = candidate;
        previousAngle = angle;
        break;
      }
      if (accepted == null) {
        final fallbackAngle = previousAngle + minAngle;
        final current = points.last;
        accepted = _traceNode(
          current.dx + math.cos(fallbackAngle) * 0.18,
          current.dy + math.sin(fallbackAngle) * 0.18,
        );
        previousAngle = fallbackAngle;
      }
      points.add(accepted);
    }
    return points;
  }

  double _angleDelta(double a, double b) {
    var delta = (a - b) % (math.pi * 2);
    if (delta > math.pi) {
      delta -= math.pi * 2;
    }
    if (delta < -math.pi) {
      delta += math.pi * 2;
    }
    return delta;
  }

  List<double> _buildPathDistances(List<Offset> path) {
    if (path.isEmpty) {
      return const <double>[];
    }
    final distances = <double>[0];
    for (var index = 1; index < path.length; index += 1) {
      distances.add(distances.last + (path[index] - path[index - 1]).distance);
    }
    return distances;
  }

  void _beginPointer(Offset localPosition, Size size) {
    if (!mounted || !widget.running || _completed || _path.length < 2) {
      return;
    }
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
    }
    final threshold = widget.spec.traceThreshold;
    final normalizedPosition = _normalizePointer(localPosition, size);
    final start = _path.first;
    final projection = _projectOntoPath(normalizedPosition, segmentIndex: 0);
    final nearStart =
        (normalizedPosition - start).distance <= threshold * 1.25 ||
        (projection != null &&
            projection.distanceToPath <= threshold &&
            projection.distanceAlong <= threshold * 1.2);
    setState(() {
      _pointer = localPosition;
      _lastPointer = localPosition;
      if (nearStart) {
        _started = true;
        _drawnPoints = <Offset>[normalizedPosition];
      } else {
        _mistakes += 1;
      }
    });
  }

  void _handleMove(Offset localPosition, Size size) {
    if (!mounted || !widget.running || _completed || _path.length < 2) {
      return;
    }
    if (!_started) {
      _beginPointer(localPosition, size);
      return;
    }
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
    }
    final threshold = widget.spec.traceThreshold;
    final previousPointer = _lastPointer ?? localPosition;
    final pixelScale = math.max(1.0, math.min(size.width, size.height));
    final pointerMove = (localPosition - previousPointer).distance / pixelScale;
    if (_traceTotalDistance <= 0) {
      return;
    }
    final currentDistance = _traceProgressDistance;
    final normalizedPosition = _normalizePointer(localPosition, size);
    final segmentStartDistance = _pathDistances[_nextIndex - 1];
    final segmentEndDistance = _pathDistances[_nextIndex];
    final projection = _projectOntoPath(
      normalizedPosition,
      segmentIndex: _nextIndex - 1,
    );
    if (projection == null) {
      setState(() {
        _pointer = localPosition;
        _lastPointer = localPosition;
        _mistakes += 1;
      });
      return;
    }
    final distanceToPath = projection.distanceToPath;
    final projectedDistance = projection.distanceAlong;
    final forwardDistance = projectedDistance - currentDistance;
    final target = _path[_nextIndex];
    final nearTarget =
        (normalizedPosition - target).distance <= threshold * 1.2;
    final accepted =
        (distanceToPath <= threshold || nearTarget) &&
        forwardDistance >= -threshold * 0.42 &&
        projectedDistance >= segmentStartDistance - threshold * 0.65 &&
        projectedDistance <= segmentEndDistance + threshold * 0.25 &&
        (forwardDistance <= math.max(pointerMove * 3.2 + threshold, 0.14) ||
            _traceSampleCount >= 4);
    if (!accepted) {
      setState(() {
        _pointer = localPosition;
        _lastPointer = localPosition;
        if (distanceToPath > threshold * 1.38 ||
            forwardDistance < -threshold * 0.8 ||
            projectedDistance > segmentEndDistance + threshold * 0.45) {
          _mistakes += 1;
        }
      });
      return;
    }

    final nearSegmentEnd =
        nearTarget || projectedDistance >= segmentEndDistance - threshold;
    final nextDistance = math.max(
      currentDistance,
      nearSegmentEnd ? segmentEndDistance : projectedDistance,
    );
    final progressDelta = nextDistance - currentDistance;
    final shouldCountSample =
        progressDelta > 0.006 || pointerMove > threshold * 0.18;
    setState(() {
      _pointer = localPosition;
      _lastPointer = localPosition;
      _traceProgressDistance = nextDistance;
      _drawnDistance += pointerMove;
      if (shouldCountSample) {
        _traceSampleCount += 1;
      }
      _drawnPoints = <Offset>[..._drawnPoints, normalizedPosition];
      if (_drawnPoints.length > 160) {
        _drawnPoints = _drawnPoints.sublist(_drawnPoints.length - 160);
      }
      _syncProgressFromDistance();
      _settleReachedSegments();
    });
    _checkCompletion();
  }

  void _endPointer() {
    if (!mounted || _completed) {
      return;
    }
    setState(() {
      _lastPointer = null;
      _pointer = null;
    });
  }

  Offset _normalizePointer(Offset localPosition, Size size) {
    return Offset(
      (localPosition.dx / math.max(1, size.width)).clamp(0.0, 1.0).toDouble(),
      (localPosition.dy / math.max(1, size.height)).clamp(0.0, 1.0).toDouble(),
    );
  }

  _TracePathProjection? _projectOntoPath(
    Offset point, {
    required int segmentIndex,
  }) {
    if (_path.length < 2 || _pathDistances.length != _path.length) {
      return null;
    }
    final index = segmentIndex.clamp(0, _path.length - 2).toInt();
    final segmentStartDistance = _pathDistances[index];
    final segmentEndDistance = _pathDistances[index + 1];
    final start = _path[index];
    final end = _path[index + 1];
    final vector = end - start;
    final lengthSquared = vector.dx * vector.dx + vector.dy * vector.dy;
    if (lengthSquared <= 0) {
      return null;
    }
    final pointerVector = point - start;
    final projection =
        (pointerVector.dx * vector.dx + pointerVector.dy * vector.dy) /
        lengthSquared;
    final clampedProjection = projection.clamp(0.0, 1.0).toDouble();
    final closest = start + vector * clampedProjection;
    return _TracePathProjection(
      distanceAlong:
          segmentStartDistance +
          (segmentEndDistance - segmentStartDistance) * clampedProjection,
      distanceToPath: (point - closest).distance,
    );
  }

  void _syncProgressFromDistance() {
    if (_pathDistances.length < 2) {
      _nextIndex = 1;
      _segmentProgress = 0;
      return;
    }
    final progress = _traceProgressDistance.clamp(0.0, _traceTotalDistance);
    var nextIndex = 1;
    while (nextIndex < _pathDistances.length - 1 &&
        progress >= _pathDistances[nextIndex] - 0.0008) {
      nextIndex += 1;
    }
    final segmentStart = _pathDistances[nextIndex - 1];
    final segmentEnd = _pathDistances[nextIndex];
    _nextIndex = nextIndex;
    _segmentProgress = segmentEnd <= segmentStart
        ? 0
        : ((progress - segmentStart) / (segmentEnd - segmentStart))
              .clamp(0.0, 1.0)
              .toDouble();
  }

  void _settleReachedSegments() {
    while (_nextIndex < _pathDistances.length - 1 &&
        _traceProgressDistance >= _pathDistances[_nextIndex] - 0.003) {
      _nextIndex += 1;
    }
    if (_nextIndex >= _pathDistances.length - 1 &&
        _traceProgressDistance >= _traceTotalDistance - 0.004) {
      _nextIndex = _path.length;
      _segmentProgress = 1;
    } else {
      _syncProgressFromDistance();
    }
  }

  void _checkCompletion() {
    if (_completed || _traceTotalDistance <= 0) {
      return;
    }
    final minDrawnRatio = switch (widget.spec.difficulty) {
      _BimanualDifficulty.relaxed => 0.38,
      _BimanualDifficulty.standard => 0.42,
      _BimanualDifficulty.hard => 0.48,
      _BimanualDifficulty.expert => 0.52,
    };
    final minSamples = math.max(6, (_path.length - 1) * 2);
    final reachedEnd =
        _nextIndex >= _path.length &&
        _traceProgressDistance >= _traceTotalDistance * 0.992;
    if (!reachedEnd) {
      return;
    }
    final tracedEnough =
        _drawnDistance >= _traceTotalDistance * minDrawnRatio &&
        _traceSampleCount >= minSamples;
    setState(() {
      if (!tracedEnough) {
        _mistakes += 1;
      }
      _traceProgressDistance = _traceTotalDistance;
      _nextIndex = _path.length;
      _segmentProgress = 1;
    });
    _complete(true);
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
    final totalSegments = math.max(1, _path.length - 1);
    final completedSegments = _completed
        ? totalSegments
        : (_nextIndex - 1).clamp(0, totalSegments).toInt();
    final progressText = '$completedSegments/$totalSegments';
    final progressValue = _traceTotalDistance <= 0
        ? 0.0
        : (_traceProgressDistance / _traceTotalDistance).clamp(0.0, 1.0);
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
              ja: 'しました。完了しました',
              de: 'Completed',
              fr: 'Achevé',
              es: 'Completado',
              ru: 'завершенный',
            )
          : pickUiText(
              AppI18n(Localizations.localeOf(context).languageCode),
              zh: '沿线描摹',
              en: 'Trace along the line',
              ja: 'Trace along the line',
              de: 'Trace along the line',
              fr: 'Tracer le long de la ligne',
              es: 'Trace en la línea',
              ru: 'След вдоль линии',
            ),
      fullscreen: widget.fullscreen,
      denseFullscreen: widget.denseFullscreen,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          if (size.isEmpty) {
            return const SizedBox.shrink();
          }
          final theme = Theme.of(context);
          return _HumanPointerDragBoundary(
            enabled: widget.running,
            onPointerDown: widget.running
                ? (event) => _beginPointer(event.localPosition, size)
                : null,
            onPointerMove: widget.running
                ? (event) => _handleMove(event.localPosition, size)
                : null,
            onPointerUp: widget.running ? (_) => _endPointer() : null,
            onPointerCancel: widget.running ? (_) => _endPointer() : null,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                AnimatedOpacity(
                  opacity: _completed ? 0.72 : 1,
                  duration: const Duration(milliseconds: 180),
                  child: CustomPaint(
                    painter: _TraceTrackPainter(
                      path: _path,
                      activeIndex: _nextIndex,
                      segmentProgress: _segmentProgress,
                      drawnPoints: _drawnPoints,
                      accent: widget.spec.accent,
                      style: widget.spec.traceLineStyle,
                      segmentMode: widget.spec.traceSegmentMode,
                      colorSegments: widget.spec.traceColorSegments,
                    ),
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
                if (!widget.denseFullscreen)
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Text(
                      pickUiText(
                        AppI18n(Localizations.localeOf(context).languageCode),
                        zh: '沿当前线段描到下一个节点',
                        en: 'Trace the segment into the next node',
                        ja: 'Trace the segment into the next node',
                        de: 'Trace the segment into the next node',
                        fr: 'Tracez le segment dans le prochain nœud',
                        es: 'Trace el segmento en el próximo nodo',
                        ru: 'Отследить сегмент до следующего узла',
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

class _TracePathProjection {
  const _TracePathProjection({
    required this.distanceAlong,
    required this.distanceToPath,
  });

  final double distanceAlong;
  final double distanceToPath;
}

class _TraceTrackPainter extends CustomPainter {
  const _TraceTrackPainter({
    required this.path,
    required this.activeIndex,
    required this.segmentProgress,
    required this.drawnPoints,
    required this.accent,
    required this.style,
    required this.segmentMode,
    required this.colorSegments,
  });

  final List<Offset> path;
  final int activeIndex;
  final double segmentProgress;
  final List<Offset> drawnPoints;
  final Color accent;
  final _BrainSplitTraceLineStyle style;
  final _BrainSplitTraceSegmentMode segmentMode;
  final bool colorSegments;

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) {
      return;
    }
    final strokeWidth = switch (style) {
      _BrainSplitTraceLineStyle.ribbon => 9.0,
      _BrainSplitTraceLineStyle.dotted => 4.5,
      _ => 5.0,
    };
    final activeStrokeWidth = switch (style) {
      _BrainSplitTraceLineStyle.ribbon => 11.0,
      _BrainSplitTraceLineStyle.dotted => 6.0,
      _ => 6.0,
    };
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.22);
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = activeStrokeWidth
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.78);
    final nodePaint = Paint()..style = PaintingStyle.fill;
    final pathPoints = path
        .map((point) => Offset(point.dx * size.width, point.dy * size.height))
        .toList(growable: false);
    _drawStyledPath(canvas, pathPoints, paint, style);
    if (drawnPoints.length > 1) {
      final drawnPath = drawnPoints
          .map((point) => Offset(point.dx * size.width, point.dy * size.height))
          .toList(growable: false);
      final drawnPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = activeStrokeWidth + 1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = BimanualCoordinationTestPage._dangerAccent.withValues(
          alpha: 0.64,
        );
      _drawStyledPath(
        canvas,
        drawnPath,
        drawnPaint,
        _BrainSplitTraceLineStyle.solid,
      );
    }
    if (colorSegments) {
      for (var index = 0; index < pathPoints.length - 1; index += 1) {
        final segmentPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 1
          ..strokeCap = StrokeCap.round
          ..color = _segmentColor(
            index,
          ).withValues(alpha: index < activeIndex ? 0.58 : 0.24);
        _drawStyledPath(
          canvas,
          <Offset>[pathPoints[index], pathPoints[index + 1]],
          segmentPaint,
          style,
        );
      }
    }
    if (activeIndex > 1) {
      _drawStyledPath(
        canvas,
        pathPoints.take(math.min(activeIndex, pathPoints.length)).toList(),
        activePaint,
        style,
      );
    }
    if (activeIndex < pathPoints.length) {
      final start = pathPoints[activeIndex - 1];
      final end = pathPoints[activeIndex];
      final livePoint = start + (end - start) * segmentProgress;
      final livePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = activeStrokeWidth + 2
        ..strokeCap = StrokeCap.round
        ..color = BimanualCoordinationTestPage._dangerAccent.withValues(
          alpha: 0.78,
        );
      _drawStyledPath(
        canvas,
        <Offset>[start, livePoint],
        livePaint,
        _BrainSplitTraceLineStyle.solid,
      );
    }
    if (activeIndex < pathPoints.length) {
      _drawDirectionHint(
        canvas,
        pathPoints[activeIndex - 1],
        pathPoints[activeIndex],
        size,
      );
    }
    for (var index = 0; index < pathPoints.length; index += 1) {
      final point = pathPoints[index];
      final isNext = index == activeIndex;
      nodePaint.color = index < activeIndex
          ? accent
          : isNext
          ? BimanualCoordinationTestPage._dangerAccent
          : accent.withValues(alpha: 0.34);
      canvas.drawCircle(point, isNext ? 12 : 7, nodePaint);
      if (isNext) {
        final ring = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = BimanualCoordinationTestPage._dangerAccent.withValues(
            alpha: 0.70,
          );
        canvas.drawCircle(point, 18, ring);
      }
    }
  }

  void _drawStyledPath(
    Canvas canvas,
    List<Offset> points,
    Paint paint,
    _BrainSplitTraceLineStyle style,
  ) {
    if (points.length < 2) {
      return;
    }
    if (style == _BrainSplitTraceLineStyle.solid ||
        style == _BrainSplitTraceLineStyle.ribbon) {
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (var index = 1; index < points.length; index += 1) {
        final point = points[index];
        if (_useCurve(index)) {
          final previous = points[index - 1];
          final mid = Offset(
            (previous.dx + point.dx) / 2,
            (previous.dy + point.dy) / 2,
          );
          final normal = Offset(point.dy - previous.dy, previous.dx - point.dx);
          final distance = (point - previous).distance;
          final control = distance <= 0
              ? mid
              : mid + normal / distance * math.min(28.0, distance * 0.22);
          linePath.quadraticBezierTo(
            control.dx,
            control.dy,
            point.dx,
            point.dy,
          );
        } else {
          linePath.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(linePath, paint);
      if (style == _BrainSplitTraceLineStyle.ribbon) {
        final highlight = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(2, paint.strokeWidth * 0.28)
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.34);
        canvas.drawPath(linePath, highlight);
      }
      return;
    }
    for (var index = 0; index < points.length - 1; index += 1) {
      final start = points[index];
      final end = points[index + 1];
      final vector = end - start;
      final distance = vector.distance;
      if (distance <= 0) {
        continue;
      }
      final direction = vector / distance;
      final dash = style == _BrainSplitTraceLineStyle.dotted ? 2.0 : 14.0;
      final gap = style == _BrainSplitTraceLineStyle.dotted ? 10.0 : 8.0;
      for (var offset = 0.0; offset < distance; offset += dash + gap) {
        final from = start + direction * offset;
        final to = start + direction * math.min(distance, offset + dash);
        if (style == _BrainSplitTraceLineStyle.dotted) {
          canvas.drawCircle(from, paint.strokeWidth * 0.64, paint);
        } else {
          canvas.drawLine(from, to, paint);
        }
      }
    }
  }

  bool _useCurve(int index) {
    return switch (segmentMode) {
      _BrainSplitTraceSegmentMode.straight => false,
      _BrainSplitTraceSegmentMode.curved => true,
      _BrainSplitTraceSegmentMode.random => index.isEven,
    };
  }

  Color _segmentColor(int index) {
    const colors = <Color>[
      Color(0xFF73A7C4),
      Color(0xFFD08A3A),
      Color(0xFFB96D5A),
      Color(0xFF7DAA72),
      Color(0xFF8C79B8),
    ];
    return colors[index % colors.length];
  }

  void _drawDirectionHint(Canvas canvas, Offset start, Offset end, Size size) {
    final vector = end - start;
    final distance = vector.distance;
    if (distance <= 0) {
      return;
    }
    final direction = vector / distance;
    final center = start + direction * math.min(distance * 0.58, distance - 4);
    final normal = Offset(-direction.dy, direction.dx);
    final arrowSize = math.min(size.shortestSide * 0.045, 18.0);
    final path = Path()
      ..moveTo(
        center.dx + direction.dx * arrowSize,
        center.dy + direction.dy * arrowSize,
      )
      ..lineTo(
        center.dx -
            direction.dx * arrowSize * 0.72 +
            normal.dx * arrowSize * 0.46,
        center.dy -
            direction.dy * arrowSize * 0.72 +
            normal.dy * arrowSize * 0.46,
      )
      ..lineTo(
        center.dx -
            direction.dx * arrowSize * 0.72 -
            normal.dx * arrowSize * 0.46,
        center.dy -
            direction.dy * arrowSize * 0.72 -
            normal.dy * arrowSize * 0.46,
      )
      ..close();
    final arrowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = BimanualCoordinationTestPage._dangerAccent.withValues(
        alpha: 0.82,
      );
    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _TraceTrackPainter oldDelegate) {
    return oldDelegate.path != path ||
        oldDelegate.activeIndex != activeIndex ||
        oldDelegate.segmentProgress != segmentProgress ||
        oldDelegate.drawnPoints != drawnPoints ||
        oldDelegate.accent != accent ||
        oldDelegate.style != style ||
        oldDelegate.segmentMode != segmentMode ||
        oldDelegate.colorSegments != colorSegments;
  }
}

class _BrainSplitBounceLane extends StatefulWidget {
  const _BrainSplitBounceLane({
    super.key,
    required this.spec,
    required this.running,
    required this.onCompleted,
    this.fullscreen = false,
    this.denseFullscreen = false,
  });

  final _BrainSplitTaskSpec spec;
  final bool running;
  final ValueChanged<_BrainSplitLaneResult> onCompleted;
  final bool fullscreen;
  final bool denseFullscreen;

  @override
  State<_BrainSplitBounceLane> createState() => _BrainSplitBounceLaneState();
}

class _BrainSplitBounceLaneState extends State<_BrainSplitBounceLane> {
  final Stopwatch _stopwatch = Stopwatch();

  Timer? _tickTimer;
  DateTime? _lastTickAt;
  List<_BrainSplitBallState> _balls = <_BrainSplitBallState>[];
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
        oldWidget.spec.targetCount != widget.spec.targetCount ||
        oldWidget.spec.speedScale != widget.spec.speedScale ||
        oldWidget.spec.ballRadius != widget.spec.ballRadius ||
        oldWidget.spec.ballCount != widget.spec.ballCount ||
        oldWidget.spec.collisionAcceleration !=
            widget.spec.collisionAcceleration ||
        oldWidget.spec.paddleWidth != widget.spec.paddleWidth ||
        oldWidget.spec.paddleHeight != widget.spec.paddleHeight ||
        oldWidget.spec.bounceObstacles != widget.spec.bounceObstacles ||
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
    _targetRallies = widget.spec.targetCount;
    _balls = List<_BrainSplitBallState>.generate(
      widget.spec.ballCount.clamp(1, 3).toInt(),
      (index) {
        final direction = (widget.spec.seed + index).isEven ? -1.0 : 1.0;
        return _BrainSplitBallState(
          x: (0.30 + (widget.spec.seed % 4) * 0.10 + index * 0.12)
              .clamp(0.18, 0.82)
              .toDouble(),
          y: (0.26 + index * 0.055).clamp(0.18, 0.42).toDouble(),
          vx:
              direction *
              (0.16 + ((widget.spec.seed + index) % 3) * 0.032) *
              widget.spec.speedScale,
          vy:
              (0.31 + ((widget.spec.seed + index) % 2) * 0.038) *
              widget.spec.speedScale,
        );
      },
    );
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

    final paddleWidth = widget.spec.paddleWidth;
    const paddleY = 0.74;
    final radius = widget.spec.ballRadius;
    final speedScale =
        1.0 + _rallies * (0.038 + widget.spec.speedScale * 0.014);

    final paddleHalf = paddleWidth / 2;
    final paddleLeft = (_paddleX - paddleHalf)
        .clamp(radius, 1 - paddleWidth - radius)
        .toDouble();
    final paddleRight = paddleLeft + paddleWidth;
    final paddleCenter = paddleLeft + paddleHalf;
    final updatedBalls = <_BrainSplitBallState>[];
    for (final ball in _balls) {
      var nextX = ball.x + ball.vx * dt * speedScale;
      var nextY = ball.y + ball.vy * dt * speedScale;
      var nextVx = ball.vx;
      var nextVy = ball.vy;
      var boosted = false;

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

      for (final obstacle in widget.spec.bounceObstacles) {
        final dx = nextX - obstacle.center.dx;
        final dy = nextY - obstacle.center.dy;
        final distance = math.sqrt(dx * dx + dy * dy);
        final minDistance = radius + obstacle.radius;
        if (distance <= 0 || distance >= minDistance) {
          continue;
        }
        final nx = dx / distance;
        final ny = dy / distance;
        final dot = nextVx * nx + nextVy * ny;
        if (dot < 0) {
          nextVx = nextVx - 2 * dot * nx;
          nextVy = nextVy - 2 * dot * ny;
          final push = minDistance - distance + 0.004;
          nextX = (nextX + nx * push).clamp(radius, 1 - radius).toDouble();
          nextY = (nextY + ny * push).clamp(radius, 1 - radius).toDouble();
          boosted = true;
        }
      }

      final crossesPaddle = nextVy > 0 && nextY + radius >= paddleY;
      if (crossesPaddle) {
        if (nextX >= paddleLeft && nextX <= paddleRight) {
          nextY = paddleY - radius;
          final bounceBoost = widget.spec.collisionAcceleration
              ? 1.055 + widget.spec.speedScale * 0.020
              : 1.010;
          nextVy = -((nextVy.abs() * bounceBoost).clamp(0.24, 0.92).toDouble());
          final paddleBias = ((nextX - paddleCenter) / paddleHalf)
              .clamp(-1.0, 1.0)
              .toDouble();
          nextVx += paddleBias * 0.10;
          boosted = true;
          _rallies += 1;
          HapticFeedback.selectionClick();
          if (_rallies >= _targetRallies) {
            updatedBalls.add(
              ball.copyWith(x: nextX, y: nextY, vx: nextVx, vy: nextVy),
            );
            setState(() => _balls = updatedBalls);
            _complete(true);
            return;
          }
        } else if (nextY + radius >= 1 - radius * 0.3) {
          _missed = true;
          updatedBalls.add(
            ball.copyWith(x: nextX, y: nextY, vx: nextVx, vy: nextVy),
          );
          setState(() => _balls = updatedBalls);
          _complete(false);
          return;
        }
      }

      if (boosted && widget.spec.collisionAcceleration) {
        nextVx *= 1.035;
        nextVy *= 1.035;
      }
      final magnitude = math.sqrt(nextVx * nextVx + nextVy * nextVy);
      final maxMagnitude = (0.72 + widget.spec.speedScale * 0.24).clamp(
        0.74,
        widget.spec.collisionAcceleration ? 1.28 : 1.05,
      );
      if (magnitude > maxMagnitude) {
        final scale = maxMagnitude / magnitude;
        nextVx *= scale;
        nextVy *= scale;
      }
      final trail = <Offset>[
        Offset(ball.x, ball.y),
        ...ball.trail,
      ].take(widget.spec.ballCount == 1 ? 8 : 5).toList(growable: false);
      updatedBalls.add(
        _BrainSplitBallState(
          x: nextX,
          y: nextY,
          vx: nextVx,
          vy: nextVy,
          trail: trail,
        ),
      );
    }

    setState(() {
      _balls = updatedBalls;
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
          ? pickUiText(
              i18n,
              zh: '已完成',
              en: 'Completed',
              ja: 'しました。完了しました',
              de: 'Completed',
              fr: 'Achevé',
              es: 'Completado',
              ru: 'завершенный',
            )
          : _missed
          ? pickUiText(
              i18n,
              zh: '漏球',
              en: 'Missed',
              ja: 'Missed',
              de: 'Missed',
              fr: 'Manque',
              es: 'Desaparecido',
              ru: 'Пропавший',
            )
          : widget.running
          ? pickUiText(
              i18n,
              zh: '拖动挡板',
              en: 'Drag the paddle',
              ja: 'Drag the paddle',
              de: 'Drag the paddle',
              fr: 'Faites glisser la palette',
              es: 'Arrastre la paleta',
              ru: 'Перетащите весло',
            )
          : pickUiText(
              i18n,
              zh: '待发球',
              en: 'Ready',
              ja: 'Ready',
              de: 'Ready',
              fr: 'Prêt',
              es: 'Listo',
              ru: 'Готовы',
            ),
      fullscreen: widget.fullscreen,
      denseFullscreen: widget.denseFullscreen,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          if (size.isEmpty) {
            return const SizedBox.shrink();
          }
          final theme = Theme.of(context);
          final paddleWidth = widget.spec.paddleWidth;
          final paddleHeight = widget.spec.paddleHeight;
          const paddleY = 0.74;
          const controlY = 0.90;
          final ballRadius =
              math.min(size.width, size.height) *
              widget.spec.ballRadius *
              (widget.denseFullscreen ? 0.92 : 1.0);
          final paddleLeft =
              ((_paddleX - paddleWidth / 2)
                  .clamp(0.08, 0.92 - paddleWidth)
                  .toDouble()) *
              size.width;
          final paddleTop = paddleY * size.height;
          return _HumanPointerDragBoundary(
            enabled: widget.running,
            onPointerDown: widget.running
                ? (event) => _setPaddle(event.localPosition.dx / size.width)
                : null,
            onPointerMove: widget.running
                ? (event) => _setPaddle(event.localPosition.dx / size.width)
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
                if (!widget.denseFullscreen)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Text(
                      widget.running
                          ? pickUiText(
                              i18n,
                              zh: '把球稳住',
                              en: 'Keep the ball alive',
                              ja: 'Keep the ball alive',
                              de: 'Keep the ball alive',
                              fr: 'Garde la balle en vie',
                              es: 'Mantenga la pelota viva',
                              ru: 'Держите мяч живым',
                            )
                          : pickUiText(
                              i18n,
                              zh: '先开始再接球',
                              en: 'Start before the serve',
                              ja: 'Start before the serve',
                              de: 'Start before the serve',
                              fr: 'Commencez avant le service',
                              es: 'Comience antes del servicio',
                              ru: 'Начните перед подачей',
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
                for (final obstacle in widget.spec.bounceObstacles)
                  Positioned(
                    left:
                        obstacle.center.dx * size.width -
                        obstacle.radius * size.width,
                    top:
                        obstacle.center.dy * size.height -
                        obstacle.radius * size.width,
                    child: Container(
                      width: obstacle.radius * size.width * 2,
                      height: obstacle.radius * size.width * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.spec.accent.withValues(alpha: 0.18),
                        border: Border.all(
                          color: widget.spec.accent.withValues(alpha: 0.42),
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: widget.spec.accent.withValues(alpha: 0.10),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  left: paddleLeft,
                  top: paddleTop,
                  child: Container(
                    width: size.width * paddleWidth,
                    height: math.max(8.0, size.height * paddleHeight),
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
                  left: 16,
                  right: 16,
                  top: size.height * controlY,
                  child: Container(
                    height: widget.denseFullscreen ? 16 : 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.62),
                      border: Border.all(
                        color: widget.spec.accent.withValues(alpha: 0.20),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: (_paddleX * size.width - 8).clamp(
                    14.0,
                    size.width - 30,
                  ),
                  top: size.height * controlY - 3,
                  child: Container(
                    width: 16,
                    height: widget.denseFullscreen ? 22 : 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: widget.spec.accent.withValues(alpha: 0.36),
                    ),
                  ),
                ),
                for (final ball in _balls)
                  for (
                    var index = ball.trail.length - 1;
                    index >= 0;
                    index -= 1
                  )
                    Positioned(
                      left:
                          ball.trail[index].dx * size.width -
                          ballRadius * (0.35 + index * 0.045),
                      top:
                          ball.trail[index].dy * size.height -
                          ballRadius * (0.35 + index * 0.045),
                      child: Container(
                        width: ballRadius * (0.70 + index * 0.09),
                        height: ballRadius * (0.70 + index * 0.09),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.spec.accent.withValues(
                            alpha: (0.07 + index * 0.018).clamp(0.04, 0.16),
                          ),
                        ),
                      ),
                    ),
                for (final ball in _balls)
                  Positioned(
                    left: ball.x * size.width - ballRadius,
                    top: ball.y * size.height - ballRadius,
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
                  right: widget.denseFullscreen ? 6 : 12,
                  top: widget.denseFullscreen ? 6 : 12,
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
    this.denseFullscreen = false,
  });

  final _BrainSplitTaskSpec spec;
  final bool running;
  final int holdTargetMs;
  final ValueChanged<_BrainSplitLaneResult> onCompleted;
  final bool fullscreen;
  final bool denseFullscreen;

  @override
  State<_BrainSplitClimbLane> createState() => _BrainSplitClimbLaneState();
}

class _BrainSplitClimbLaneState extends State<_BrainSplitClimbLane> {
  final Stopwatch _stopwatch = Stopwatch();

  Timer? _platformTimer;
  Timer? _chargeTimer;
  Timer? _jumpTimer;
  DateTime? _chargeStartedAt;
  DateTime? _lastPlatformTickAt;
  DateTime? _jumpStartedAt;
  int _levelIndex = 0;
  int _targetSteps = 6;
  List<_BrainSplitJumpPlatform> _platforms = <_BrainSplitJumpPlatform>[];
  double _platformClock = 0;
  double _chargeProgress = 0;
  double _lastLandingCharge = 0;
  double _jumpProgress = 0;
  double _jumpStartX = 0.5;
  double _jumpStartY = 0.88;
  double _jumpTargetX = 0.5;
  double _jumpTargetY = 0.5;
  bool _charging = false;
  bool _jumping = false;
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
        oldWidget.spec.targetCount != widget.spec.targetCount ||
        oldWidget.spec.climbPlatforms != widget.spec.climbPlatforms ||
        oldWidget.spec.speedScale != widget.spec.speedScale ||
        oldWidget.running != widget.running ||
        oldWidget.holdTargetMs != widget.holdTargetMs) {
      _reset();
    }
  }

  @override
  void dispose() {
    _platformTimer?.cancel();
    _chargeTimer?.cancel();
    _jumpTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    super.dispose();
  }

  void _reset() {
    _platformTimer?.cancel();
    _chargeTimer?.cancel();
    _jumpTimer?.cancel();
    _targetSteps = widget.spec.targetCount;
    _platforms = widget.spec.climbPlatforms;
    _levelIndex = 0;
    _platformClock = (widget.spec.seed % 17) * 0.071;
    _chargeProgress = 0;
    _lastLandingCharge = 0;
    _jumpProgress = 0;
    _jumpStartX = 0.5;
    _jumpStartY = 0.88;
    _jumpTargetX = 0.5;
    _jumpTargetY = 0.5;
    _charging = false;
    _jumping = false;
    _chargeAnnounced = false;
    _completed = false;
    _failed = false;
    _chargeStartedAt = null;
    _lastPlatformTickAt = null;
    _jumpStartedAt = null;
    _stopwatch
      ..stop()
      ..reset();
    if (widget.running) {
      _stopwatch.start();
      _startPlatformTicker();
    }
  }

  void _startPlatformTicker() {
    _platformTimer?.cancel();
    _lastPlatformTickAt = DateTime.now();
    _platformTimer = Timer.periodic(const Duration(milliseconds: 32), (_) {
      if (!mounted || !widget.running || _completed) {
        return;
      }
      final now = DateTime.now();
      final lastTick = _lastPlatformTickAt ?? now;
      _lastPlatformTickAt = now;
      final dt = now.difference(lastTick).inMicroseconds / 1000000.0;
      if (dt <= 0) {
        return;
      }
      setState(() {
        _platformClock += dt;
      });
    });
  }

  void _beginCharge() {
    if (!mounted || !widget.running || _completed || _jumping) {
      return;
    }
    if (_charging) {
      return;
    }
    _chargeTimer?.cancel();
    _charging = true;
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
      });
      if (progress >= 1 && !_chargeAnnounced) {
        _chargeAnnounced = true;
        HapticFeedback.selectionClick();
      }
    });
    setState(() {});
  }

  void _endCharge() {
    if (!mounted || _completed || _jumping) {
      return;
    }
    _chargeTimer?.cancel();
    _chargeTimer = null;
    _charging = false;
    _chargeStartedAt = null;
    final releasedProgress = _chargeProgress;
    _chargeProgress = 0;
    _chargeAnnounced = false;
    _attemptJump(releasedProgress);
  }

  _BrainSplitJumpPlatform? get _nextPlatform {
    if (_levelIndex >= _platforms.length) {
      return null;
    }
    return _platforms[_levelIndex];
  }

  double _platformCenterX(_BrainSplitJumpPlatform platform) {
    final left = 0.10 + platform.width / 2;
    final right = 0.90 - platform.width / 2;
    final mid = (left + right) / 2;
    final amplitude = math.max(0.02, (right - left) / 2);
    final phase =
        (_platformClock * platform.speed + platform.phase) * math.pi * 2;
    return (mid + math.sin(phase) * amplitude).clamp(left, right).toDouble();
  }

  double _runnerX() {
    if (_levelIndex <= 0 || _platforms.isEmpty) {
      return 0.5;
    }
    final platform = _platforms[math.min(_levelIndex, _platforms.length) - 1];
    return _platformCenterX(platform);
  }

  double _landingTolerance(double chargeProgress) {
    final base = switch (widget.spec.difficulty) {
      _BimanualDifficulty.relaxed => 0.082,
      _BimanualDifficulty.standard => 0.064,
      _BimanualDifficulty.hard => 0.052,
      _BimanualDifficulty.expert => 0.042,
    };
    return base + chargeProgress.clamp(0.0, 1.0).toDouble() * 0.045;
  }

  double _levelY(int level) {
    return 0.88 - level * (0.72 / math.max(1, _targetSteps));
  }

  double _runnerRestY() {
    return _levelIndex <= 0 ? _levelY(0) : _levelY(_levelIndex);
  }

  Offset _currentRunnerPosition() {
    if (!_jumping) {
      return Offset(_runnerX(), _runnerRestY());
    }
    final t = Curves.easeOutCubic.transform(_jumpProgress.clamp(0.0, 1.0));
    final x = _jumpStartX + (_jumpTargetX - _jumpStartX) * t;
    final yLine = _jumpStartY + (_jumpTargetY - _jumpStartY) * t;
    final arc = math.sin(math.pi * t) * (0.12 + _lastLandingCharge * 0.05);
    return Offset(x, yLine - arc);
  }

  void _attemptJump(double chargeProgress) {
    if (!mounted || _completed) {
      return;
    }
    final platform = _nextPlatform;
    if (platform == null) {
      _complete(true);
      return;
    }
    final requiredCharge = platform.requiredCharge;
    final hasCharge = requiredCharge <= 0 || chargeProgress >= requiredCharge;
    final currentPosition = _currentRunnerPosition();
    final platformX = _platformCenterX(platform);
    _jumpTimer?.cancel();
    _jumping = true;
    _jumpProgress = 0;
    _jumpStartX = currentPosition.dx;
    _jumpStartY = currentPosition.dy;
    _jumpTargetX = platformX;
    _jumpTargetY = _levelY(platform.level);
    _lastLandingCharge = chargeProgress;
    _jumpStartedAt = DateTime.now();
    _jumpTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || !_jumping || _completed) {
        return;
      }
      final startedAt = _jumpStartedAt ?? DateTime.now();
      final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
      final progress = (elapsed / 420).clamp(0.0, 1.0).toDouble();
      if (progress < 1) {
        setState(() => _jumpProgress = progress);
        return;
      }
      _landJump(platform, chargeProgress, hasCharge);
    });
    setState(() {});
  }

  void _landJump(
    _BrainSplitJumpPlatform platform,
    double chargeProgress,
    bool hasCharge,
  ) {
    _jumpTimer?.cancel();
    final platformX = _platformCenterX(platform);
    final horizontalOk =
        (_jumpTargetX - platformX).abs() <=
        platform.width / 2 + _landingTolerance(chargeProgress);
    if (!hasCharge || !horizontalOk) {
      setState(() {
        _jumping = false;
        _jumpProgress = 1;
      });
      _complete(false);
      return;
    }
    setState(() {
      _jumping = false;
      _jumpProgress = 1;
      _levelIndex = math.min(_targetSteps, _levelIndex + 1);
      _lastLandingCharge = chargeProgress;
    });
    if (_levelIndex >= _targetSteps) {
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
    _platformTimer?.cancel();
    _chargeTimer?.cancel();
    _jumpTimer?.cancel();
    _stopwatch.stop();
    final elapsed = math.max(1, _stopwatch.elapsedMilliseconds);
    final scoreDelta = success
        ? 13 +
              _targetSteps * 3 +
              _platforms
                      .where((platform) => platform.requiredCharge > 0)
                      .length *
                  2
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
    final progressText = '${math.min(_levelIndex, _targetSteps)}/$_targetSteps';
    final progressValue = _levelIndex / math.max(1, _targetSteps);
    final nextPlatform = _nextPlatform;
    final needCharge = (nextPlatform?.requiredCharge ?? 0) > 0;
    return _BrainSplitLaneFrame(
      accent: widget.spec.accent,
      title: widget.spec.title,
      subtitle: widget.spec.subtitle,
      goalText: widget.spec.goalText,
      progressText: progressText,
      progressValue: progressValue,
      statusText: _completed
          ? pickUiText(
              i18n,
              zh: '已登顶',
              en: 'Summit reached',
              ja: 'Summit reached',
              de: 'Summit reached',
              fr: 'Sommet atteint',
              es: 'Cumbre alcanzada',
              ru: 'Встреча на высшем уровне',
            )
          : _failed
          ? pickUiText(
              i18n,
              zh: '没踩到平台',
              en: 'Missed platform',
              ja: 'Missed platform',
              de: 'Missed platform',
              fr: 'Plateforme manquante',
              es: 'Plataforma perdida',
              ru: 'Пропущенная платформа',
            )
          : _jumping
          ? pickUiText(
              i18n,
              zh: '空中',
              en: 'Airborne',
              ja: 'Airborne',
              de: 'Airborne',
              fr: 'Airborne',
              es: 'Airborne',
              ru: 'воздушно-десантный',
            )
          : _charging
          ? pickUiText(
              i18n,
              zh: '蓄力 ${(_chargeProgress * 100).round()}%',
              en: '${(_chargeProgress * 100).round()}% charge',
              ja: '${(_chargeProgress * 100).round()}%チャージ',
              de: '${(_chargeProgress * 100).round()}% charge',
              fr: '${(_chargeProgress * 100).round()}% charge',
              es: 'Cargo correspondiente',
              ru: '<v0/% заряд',
            )
          : needCharge
          ? pickUiText(
              i18n,
              zh: '长按蓄力等平台对齐',
              en: 'Hold and time the platform',
              ja: 'Hold and time the platform',
              de: 'Hold and time the platform',
              fr: 'Maintenez et maintenez la plate-forme',
              es: 'Mantener y tiempo la plataforma',
              ru: 'Время и время работы платформы',
            )
          : pickUiText(
              i18n,
              zh: '点击跳到下一层',
              en: 'Tap to jump',
              ja: 'Tap to jump',
              de: 'Tap to jump',
              fr: 'Appuyez sur pour sauter',
              es: 'Pulsa para saltar',
              ru: 'Прыжок прыжком',
            ),
      fullscreen: widget.fullscreen,
      denseFullscreen: widget.denseFullscreen,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          if (size.isEmpty) {
            return const SizedBox.shrink();
          }
          final theme = Theme.of(context);
          final baseY = size.height * 0.88;
          final summitY = size.height * 0.16;
          final levelSpacing = (baseY - summitY) / math.max(1, _targetSteps);
          double platformY(_BrainSplitJumpPlatform platform) {
            return baseY - platform.level * levelSpacing;
          }

          final runnerSize = widget.denseFullscreen ? 30.0 : 38.0;
          final runnerPosition = _currentRunnerPosition();
          final runnerX = runnerPosition.dx * size.width;
          final runnerY = runnerPosition.dy * size.height - runnerSize * 0.82;
          final targetX = nextPlatform == null
              ? runnerX
              : _platformCenterX(nextPlatform) * size.width;
          final targetY = nextPlatform == null
              ? summitY
              : platformY(nextPlatform);
          return _HumanPointerDragBoundary(
            enabled: widget.running,
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
                  left: 18,
                  right: 18,
                  top: summitY - 22,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: <Color>[
                          widget.spec.accent.withValues(alpha: 0.10),
                          widget.spec.accent.withValues(alpha: 0.50),
                          widget.spec.accent.withValues(alpha: 0.10),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 18,
                  top: summitY - 42,
                  child: Icon(
                    Icons.flag_rounded,
                    color: widget.spec.accent.withValues(alpha: 0.78),
                    size: widget.denseFullscreen ? 18 : 24,
                  ),
                ),
                if (!widget.denseFullscreen)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Text(
                      widget.running
                          ? pickUiText(
                              i18n,
                              zh: '看准平台横向对齐，再点击或蓄力跳。',
                              en: 'Time the moving platform, then tap or charge.',
                              ja: 'Time the moving platform, then tap or charge.',
                              de: 'Time the moving platform, then tap or charge.',
                              fr: 'Temps de la plate-forme mobile, puis touchez ou chargez.',
                              es: 'Hora de la plataforma móvil, luego pulsar o cargar.',
                              ru: 'Время движущейся платформы, затем нажмите или зарядите.',
                            )
                          : pickUiText(
                              i18n,
                              zh: '先开始再跳高',
                              en: 'Start before jumping',
                              ja: 'Start before jumping',
                              de: 'Start before jumping',
                              fr: 'Commencez avant de sauter',
                              es: 'Empieza antes de saltar',
                              ru: 'Начните перед прыжком',
                            ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Positioned(
                  left: 20,
                  right: 20,
                  top: baseY,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: widget.spec.accent.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                for (final platform in _platforms)
                  Positioned(
                    left:
                        _platformCenterX(platform) * size.width -
                        platform.width * size.width / 2,
                    top: platformY(platform),
                    child: Container(
                      width: platform.width * size.width,
                      height: platform.requiredCharge > 0 ? 12 : 10,
                      decoration: BoxDecoration(
                        color: platform.level <= _levelIndex
                            ? widget.spec.accent.withValues(alpha: 0.36)
                            : platform.requiredCharge > 0
                            ? BimanualCoordinationTestPage._dangerAccent
                                  .withValues(alpha: 0.34)
                            : widget.spec.accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: widget.spec.accent.withValues(
                            alpha: platform.level == _levelIndex + 1
                                ? 0.58
                                : 0.18,
                          ),
                          width: platform.level == _levelIndex + 1 ? 2 : 1,
                        ),
                        boxShadow: <BoxShadow>[
                          if (platform.level == _levelIndex + 1)
                            BoxShadow(
                              color: widget.spec.accent.withValues(alpha: 0.24),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: math.max(
                            18,
                            platform.width * size.width * 0.32,
                          ),
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Colors.white.withValues(alpha: 0.56),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_charging && nextPlatform != null)
                  Positioned(
                    left: math.min(runnerX, targetX),
                    top: math.min(runnerY, targetY),
                    child: CustomPaint(
                      size: Size(
                        (runnerX - targetX).abs().clamp(24.0, size.width),
                        (runnerY - targetY).abs().clamp(24.0, size.height),
                      ),
                      painter: _ClimbJumpGuidePainter(
                        accent: widget.spec.accent,
                        progress: _chargeProgress,
                        flipX: targetX < runnerX,
                        flipY: targetY < runnerY,
                      ),
                    ),
                  ),
                Positioned(
                  left: (runnerX - runnerSize / 2).clamp(
                    8.0,
                    size.width - runnerSize - 8,
                  ),
                  top: runnerY.clamp(12.0, size.height - runnerSize - 8),
                  child: Container(
                    width: runnerSize,
                    height: runnerSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
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
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Icon(
                          _jumping
                              ? Icons.flight_takeoff_rounded
                              : _lastLandingCharge > 0.35
                              ? Icons.keyboard_double_arrow_up_rounded
                              : Icons.directions_run_rounded,
                          color: Colors.white,
                          size: widget.denseFullscreen ? 18 : 22,
                        ),
                        if (_failed)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: BimanualCoordinationTestPage
                                      ._dangerAccent
                                      .withValues(alpha: 0.78),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: widget.denseFullscreen ? 6 : 12,
                  top: widget.denseFullscreen ? 6 : 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      _HumanPill(
                        text: needCharge
                            ? pickUiText(
                                i18n,
                                zh: '蓄力层',
                                en: 'Charge',
                                ja: 'チャージ',
                                de: 'Charge',
                                fr: 'Frais',
                                es: 'Carga',
                                ru: 'Зарядка',
                              )
                            : pickUiText(
                                i18n,
                                zh: '平台',
                                en: 'Platform',
                                ja: 'Platform',
                                de: 'Platform',
                                fr: 'Plateforme',
                                es: 'Plataforma',
                                ru: 'Платформа',
                              ),
                        accent: widget.spec.accent,
                      ),
                      if (!widget.denseFullscreen) ...<Widget>[
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

class _ClimbJumpGuidePainter extends CustomPainter {
  const _ClimbJumpGuidePainter({
    required this.accent,
    required this.progress,
    required this.flipX,
    required this.flipY,
  });

  final Color accent;
  final double progress;
  final bool flipX;
  final bool flipY;

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(flipX ? size.width : 0, flipY ? size.height : 0);
    final end = Offset(flipX ? 0 : size.width, flipY ? 0 : size.height);
    final control = Offset(
      size.width / 2,
      flipY ? size.height * 0.08 : size.height * 0.92,
    );
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 + progress.clamp(0.0, 1.0) * 3.0
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.22 + progress * 0.38);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ClimbJumpGuidePainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.progress != progress ||
        oldDelegate.flipX != flipX ||
        oldDelegate.flipY != flipY;
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
            pickUiText(
              i18n,
              zh: '最近回合',
              en: 'Recent rounds',
              ja: 'Recent rounds',
              de: 'Recent rounds',
              fr: 'Cycles récents',
              es: 'rondas recientes',
              ru: 'Последние раунды',
            ),
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
                  final success =
                      (!record.plan.leftActive || record.left.success) &&
                      (!record.plan.rightActive || record.right.success);
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
        ? pickUiText(
            i18n,
            zh: '左右脑合拍',
            en: 'Two-hand flow',
            ja: 'Two-hand flow',
            de: 'Two-hand flow',
            fr: 'Débit à deux mains',
            es: 'Flujo de dos manos',
            ru: 'Двусторонний поток',
          )
        : accuracy < 0.7
        ? pickUiText(
            i18n,
            zh: '先稳住节奏',
            en: 'Slow down first',
            ja: 'Slow down first',
            de: 'Slow down first',
            fr: 'Ralentissez d\'abord',
            es: 'Despacio primero',
            ru: 'Сначала помедленнее',
          )
        : pickUiText(
            i18n,
            zh: '节奏正在成形',
            en: 'Rhythm forming',
            ja: 'Rhythm forming',
            de: 'Rhythm forming',
            fr: 'Rythme formant',
            es: 'Rhythm formando',
            ru: 'Формирование ритма',
          );
    return AlertDialog(
      title: Text(
        pickUiText(
          i18n,
          zh: '双手协调报告',
          en: 'Bimanual report',
          ja: 'バイマニュアルレポート',
          de: 'Bimanual report',
          fr: 'Rapport bimanuel',
          es: 'Informe bimanual',
          ru: 'Двухсторонний доклад',
        ),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _HumanMetricWrap(
                metrics: <(String, String)>[
                  (
                    pickUiText(
                      i18n,
                      zh: '称号',
                      en: 'Title',
                      ja: 'Title',
                      de: 'Title',
                      fr: 'Titre',
                      es: 'Título',
                      ru: 'Название',
                    ),
                    title,
                  ),
                  (
                    pickUiText(
                      i18n,
                      zh: '模式',
                      en: 'Mode',
                      ja: 'Mode',
                      de: 'Mode',
                      fr: 'Mode',
                      es: 'Modo',
                      ru: 'Режим',
                    ),
                    mode,
                  ),
                  (
                    pickUiText(
                      i18n,
                      zh: '分数',
                      en: 'Score',
                      ja: 'Score',
                      de: 'Score',
                      fr: 'Score',
                      es: 'Puntuación',
                      ru: 'счет',
                    ),
                    '$score',
                  ),
                  (
                    pickUiText(
                      i18n,
                      zh: '准确率',
                      en: 'Accuracy',
                      ja: '精度',
                      de: 'Accuracy',
                      fr: 'Accuracy',
                      es: 'Precisión',
                      ru: 'точность',
                    ),
                    '${(accuracy * 100).round()}%',
                  ),
                  (
                    pickUiText(
                      i18n,
                      zh: '最佳连击',
                      en: 'Best combo',
                      ja: 'ベストコンボ',
                      de: 'Best combo',
                      fr: 'Meilleur combo',
                      es: 'Mejor combo',
                      ru: 'Лучшее сочетание',
                    ),
                    '$bestCombo',
                  ),
                  (
                    pickUiText(
                      i18n,
                      zh: '失误',
                      en: 'Mistakes',
                      ja: 'Mistakes',
                      de: 'Mistakes',
                      fr: 'Erreurs',
                      es: 'Errores',
                      ru: 'Ошибки',
                    ),
                    '$mistakes',
                  ),
                  (
                    pickUiText(
                      i18n,
                      zh: '平均用时',
                      en: 'Avg lane time',
                      ja: 'レーン時間',
                      de: 'Avg lane time',
                      fr: 'Heure de la voie d\'Avg',
                      es: 'Tiempo de carril de Avg',
                      ru: 'Время в пути',
                    ),
                    averageMs == 0 ? '-' : _formatMilliseconds(averageMs),
                  ),
                  (
                    pickUiText(
                      i18n,
                      zh: '同步差',
                      en: 'Sync gap',
                      ja: 'Sync gap',
                      de: 'Sync gap',
                      fr: 'Écart de synchronisation',
                      es: 'Sincronización',
                      ru: 'Синхронный разрыв',
                    ),
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
                      pickUiText(
                        i18n,
                        zh: '左右手负载',
                        en: 'Hand load',
                        ja: 'Hand load',
                        de: 'Hand load',
                        fr: 'Charge manuelle',
                        es: 'Carga de mano',
                        ru: 'Ручная нагрузка',
                      ),
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
                          ja: 'Lower the pace first. Practice isolated left/right finishes and sync-window endings.',
                          de: 'Lower the pace first. Practice isolated left/right finishes and sync-window endings.',
                          fr: 'Baissez d\'abord le rythme. Pratiquez des finitions de gauche/droite isolées et des terminaisons de fenêtre de synchronisation.',
                          es: 'Baja el ritmo primero. Practica acabados aislados izquierda/derecha y terminaciones de sincronización.',
                          ru: 'Сначала понизить темп. Практикуйте изолированные лево-правые отделки и окончания синхронного окна.',
                        )
                      : pickUiText(
                          i18n,
                          zh: '表现稳定，可以提高节奏强度或切换到更强的脑裂配对。',
                          en: 'Performance is stable. Raise the pace or switch to a tougher split-brain pairing.',
                          ja: 'Performance is stable. Raise the pace or switch to a tougher split-brain pairing.',
                          de: 'Performance is stable. Raise the pace or switch to a tougher split-brain pairing.',
                          fr: 'La performance est stable. Augmenter le rythme ou passer à un couplage plus dur entre les cerveaux.',
                          es: 'El rendimiento es estable. Aumente el ritmo o cambie a un emparejamiento de cerebros de separación más duro.',
                          ru: 'Производительность стабильна. Поднимите темп или переключитесь на более жесткое спаривание с разделенным мозгом.',
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
          child: Text(
            pickUiText(
              i18n,
              zh: '关闭',
              en: 'Close',
              ja: '閉じる',
              de: 'Close',
              fr: 'Fermer',
              es: 'Cerca',
              ru: 'Закрыть',
            ),
          ),
        ),
      ],
    );
  }
}

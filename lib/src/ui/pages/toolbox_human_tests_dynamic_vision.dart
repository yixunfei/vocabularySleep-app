part of 'toolbox_human_tests.dart';

enum _DynamicVisionMode { symbol, ballCount }

enum _DynamicVisionGrowthCurve { gentle, linear, accelerated }

enum _DynamicSymbolSet { mixed, digits, letters, confusable, custom }

enum _DynamicSymbolPath { wave, horizontal, diagonal, bounce }

enum _DynamicBallColorMode { uniform, varied }

class _DynamicSymbolRecord {
  const _DynamicSymbolRecord({
    required this.target,
    required this.choice,
    required this.correct,
    required this.durationMs,
    required this.speed,
    required this.path,
    required this.set,
  });

  final String target;
  final String choice;
  final bool correct;
  final int durationMs;
  final double speed;
  final _DynamicSymbolPath path;
  final _DynamicSymbolSet set;
}

class _DynamicSymbolDistractor {
  const _DynamicSymbolDistractor({
    required this.value,
    required this.dx,
    required this.dy,
  });

  final String value;
  final double dx;
  final double dy;
}

class DynamicVisionTestPage extends StatelessWidget {
  const DynamicVisionTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_dynamic_vision.dynamic_vision_4255de',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_dynamic_vision.switch_between_moving_symbol_recognition_and_moving_ball_f639f6',
      ),
      accent: const Color(0xFF407E92),
      icon: Icons.remove_red_eye_rounded,
      status: i18n.t(
        'inline.ui.pages.toolbox_human_tests_dynamic_vision.next_choose_a_mode_and_start_observing_edd654',
      ),
      child: const _DynamicVisionCard(),
    );
  }
}

class _DynamicVisionCard extends StatefulWidget {
  const _DynamicVisionCard();

  @override
  State<_DynamicVisionCard> createState() => _DynamicVisionCardState();
}

class _DynamicVisionCardState extends State<_DynamicVisionCard>
    with TickerProviderStateMixin {
  static const Color _accent = Color(0xFF407E92);
  static const List<String> _symbolValues = <String>[
    '2',
    '3',
    '5',
    '6',
    '8',
    '9',
    'B',
    'E',
    'F',
    'P',
  ];

  final math.Random _random = math.Random();
  late final TextEditingController _symbolCustomController;
  late final TextEditingController _ballObservationController;
  late final AnimationController _symbolController;
  late final AnimationController _ballController;

  _DynamicVisionMode _mode = _DynamicVisionMode.ballCount;

  int _symbolRoundCount = 10;
  int _symbolGroupLength = 1;
  int _symbolOptionCount = 4;
  String _symbolCustomSource = '';
  double _symbolBaseSpeed = 1.0;
  double _symbolWaveAmplitude = 0.18;
  _DynamicVisionGrowthCurve _symbolCurve = _DynamicVisionGrowthCurve.linear;
  _DynamicSymbolSet _symbolSet = _DynamicSymbolSet.mixed;
  _DynamicSymbolPath _symbolPath = _DynamicSymbolPath.wave;
  bool _symbolDistractorEnabled = false;
  int _symbolRound = 0;
  int _symbolCorrect = 0;
  String _symbolTarget = '';
  List<String> _symbolOptions = const <String>[];
  List<_DynamicSymbolDistractor> _symbolDistractors =
      const <_DynamicSymbolDistractor>[];
  final List<_DynamicSymbolRecord> _symbolRecords = <_DynamicSymbolRecord>[];
  bool _symbolShowing = false;
  bool _symbolChoosing = false;
  bool _symbolDone = false;
  bool? _symbolLastCorrect;
  String? _symbolFeedbackKey;
  Map<String, Object?> _symbolFeedbackParams = const <String, Object?>{};
  int _symbolToken = 0;
  bool _symbolReportDialogOpen = false;

  int _ballStartCount = 3;
  int _ballMaxCount = 12;
  double _ballBaseSpeed = 1.0;
  int _ballObservationMs = 2200;
  _DynamicBallColorMode _ballColorMode = _DynamicBallColorMode.uniform;
  _DynamicVisionGrowthCurve _ballCurve = _DynamicVisionGrowthCurve.linear;
  int _ballLevel = 1;
  int _ballCorrect = 0;
  int _ballMisses = 0;
  int _ballBestLevel = 1;
  int _ballAnswer = 0;
  List<int> _ballOptions = const <int>[];
  List<_DynamicVisionBall> _balls = <_DynamicVisionBall>[];
  bool _ballShowing = false;
  bool _ballAnswering = false;
  bool _ballDone = false;
  bool? _ballLastCorrect;
  String? _ballFeedbackKey;
  Map<String, Object?> _ballFeedbackParams = const <String, Object?>{};
  Size _lastBallStageSize = const Size(320, 220);
  Duration? _lastBallTick;
  int _ballToken = 0;
  bool _settingConfirmOpen = false;

  bool get _busy =>
      _symbolShowing || _symbolChoosing || _ballShowing || _ballAnswering;

  bool get _symbolInProgress => _symbolShowing || _symbolChoosing;

  bool get _ballInProgress => _ballShowing || _ballAnswering;

  _DynamicVisionMode get mode => _mode;
  TextEditingController get symbolCustomController => _symbolCustomController;
  TextEditingController get ballObservationController =>
      _ballObservationController;
  int get symbolRoundCount => _symbolRoundCount;
  int get symbolGroupLength => _symbolGroupLength;
  int get symbolOptionCount => _symbolOptionCount;
  double get symbolBaseSpeed => _symbolBaseSpeed;
  double get symbolWaveAmplitude => _symbolWaveAmplitude;
  _DynamicVisionGrowthCurve get symbolCurve => _symbolCurve;
  _DynamicSymbolSet get symbolSet => _symbolSet;
  _DynamicSymbolPath get symbolPath => _symbolPath;
  bool get symbolDistractorEnabled => _symbolDistractorEnabled;
  int get symbolRound => _symbolRound;
  int get symbolCorrect => _symbolCorrect;
  List<String> get symbolOptions => _symbolOptions;
  bool? get symbolLastCorrect => _symbolLastCorrect;
  String? get symbolFeedbackKey => _symbolFeedbackKey;
  Map<String, Object?> get symbolFeedbackParams => _symbolFeedbackParams;
  List<_DynamicSymbolDistractor> get symbolDistractors => _symbolDistractors;
  List<_DynamicSymbolRecord> get symbolRecords => _symbolRecords;
  bool get symbolChoosing => _symbolChoosing;
  bool get symbolDone => _symbolDone;
  double get symbolEffectiveSpeed => _symbolEffectiveSpeed;
  int get ballStartCount => _ballStartCount;
  int get ballMaxCount => _ballMaxCount;
  double get ballBaseSpeed => _ballBaseSpeed;
  int get ballObservationMs => _ballObservationMs;
  _DynamicBallColorMode get ballColorMode => _ballColorMode;
  _DynamicVisionGrowthCurve get ballCurve => _ballCurve;
  int get ballLevel => _ballLevel;
  int get ballCorrect => _ballCorrect;
  int get ballMisses => _ballMisses;
  int get ballBestLevel => _ballBestLevel;
  List<int> get ballOptions => _ballOptions;
  bool get ballShowing => _ballShowing;
  bool get ballAnswering => _ballAnswering;
  bool get ballDone => _ballDone;
  bool? get ballLastCorrect => _ballLastCorrect;
  String? get ballFeedbackKey => _ballFeedbackKey;
  Map<String, Object?> get ballFeedbackParams => _ballFeedbackParams;
  String get ballCountRangeLabel => _ballCountRangeLabel;
  String get ballSpeedRangeLabel => _ballSpeedRangeLabel;

  void setSymbolRoundCount(int value) => _symbolRoundCount = value;
  void setSymbolGroupLength(int value) => _symbolGroupLength = value;
  void setSymbolOptionCount(int value) => _symbolOptionCount = value;
  void setSymbolCustomSource(String value) => _symbolCustomSource = value;
  void setSymbolBaseSpeed(double value) => _symbolBaseSpeed = value;
  void setSymbolWaveAmplitude(double value) => _symbolWaveAmplitude = value;
  void setSymbolCurve(_DynamicVisionGrowthCurve value) => _symbolCurve = value;
  void setSymbolSet(_DynamicSymbolSet value) => _symbolSet = value;
  void setSymbolPath(_DynamicSymbolPath value) => _symbolPath = value;
  void setSymbolDistractorEnabled(bool value) =>
      _symbolDistractorEnabled = value;
  void setBallStartCount(int value) => _ballStartCount = value;
  void setBallMaxCount(int value) => _ballMaxCount = value;
  void setBallBaseSpeed(double value) => _ballBaseSpeed = value;
  void setBallObservationMs(int value) => _ballObservationMs = value;
  void setBallColorMode(_DynamicBallColorMode value) => _ballColorMode = value;
  void setBallCurve(_DynamicVisionGrowthCurve value) => _ballCurve = value;

  @override
  void initState() {
    super.initState();
    _symbolCustomController = TextEditingController(text: _symbolCustomSource);
    _ballObservationController = TextEditingController(
      text: formatObservationInput(_ballObservationMs),
    );
    _symbolController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _ballController = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_tickBalls);
  }

  @override
  void dispose() {
    _symbolCustomController.dispose();
    _ballObservationController.dispose();
    _symbolController.dispose();
    _ballController.dispose();
    super.dispose();
  }

  void _selectMode(_DynamicVisionMode mode) {
    if (_busy || mode == _mode) {
      return;
    }
    _symbolController.stop();
    _ballController.stop();
    setState(() {
      _mode = mode;
    });
  }

  Future<void> changeMode(_DynamicVisionMode mode) async {
    if (mode == _mode) {
      return;
    }
    if (!_busy) {
      _selectMode(mode);
      return;
    }
    final confirmed = await _confirmSettingRestart(
      messageKey:
          'inline.plan297.human_tests.dynamic_vision.restart.change_mode',
    );
    if (!confirmed || !mounted) {
      return;
    }
    _symbolController.stop();
    _ballController.stop();
    _symbolToken += 1;
    _ballToken += 1;
    setState(() => _mode = mode);
    if (mode == _DynamicVisionMode.symbol) {
      resetSymbol();
    } else {
      resetBalls();
    }
  }

  Future<void> startSymbolRound() async {
    if (_symbolShowing || _symbolChoosing || _symbolDone) {
      return;
    }
    final token = ++_symbolToken;
    final candidates = _symbolCandidates();
    final target = _sample(_random, candidates);
    final options = <String>{target};
    final optionCount = math.min(_symbolOptionCount, candidates.length);
    while (options.length < optionCount) {
      options.add(_sample(_random, candidates));
    }
    final duration = symbolDurationForRound(_symbolRound + 1);
    _symbolController.duration = duration;
    setState(() {
      _symbolRound += 1;
      _symbolTarget = target;
      _symbolOptions = options.toList(growable: false)..shuffle(_random);
      _symbolDistractors = _buildSymbolDistractors(candidates, target);
      _symbolShowing = true;
      _symbolChoosing = false;
      _symbolDone = false;
      _symbolFeedbackKey = null;
      _symbolFeedbackParams = const <String, Object?>{};
    });
    _symbolController
      ..reset()
      ..forward();
    await Future<void>.delayed(duration);
    if (!mounted || token != _symbolToken || !_symbolShowing) {
      return;
    }
    setState(() {
      _symbolShowing = false;
      _symbolChoosing = true;
    });
  }

  void chooseSymbol(String value) {
    if (!_symbolChoosing) {
      return;
    }
    final correct = value == _symbolTarget;
    final duration = symbolDurationForRound(_symbolRound);
    setState(() {
      if (correct) {
        _symbolCorrect += 1;
      }
      _symbolRecords.add(
        _DynamicSymbolRecord(
          target: _symbolTarget,
          choice: value,
          correct: correct,
          durationMs: duration.inMilliseconds,
          speed: _symbolEffectiveSpeed,
          path: _symbolPath,
          set: _symbolSet,
        ),
      );
      _symbolLastCorrect = correct;
      _symbolFeedbackKey = correct
          ? 'inline.plan297.human_tests.dynamic_vision.symbol_correct'
          : 'inline.plan297.human_tests.dynamic_vision.symbol_answer_was';
      _symbolFeedbackParams = correct
          ? const <String, Object?>{}
          : <String, Object?>{'answer': _symbolTarget};
      _symbolChoosing = false;
      if (_symbolRound >= _symbolRoundCount) {
        _symbolDone = true;
      }
    });
    if (_symbolRound < _symbolRoundCount) {
      unawaited(startSymbolRound());
    } else {
      unawaited(_showSymbolReport());
    }
  }

  void resetSymbol() {
    _symbolController.stop();
    _symbolToken += 1;
    setState(() {
      _symbolRound = 0;
      _symbolCorrect = 0;
      _symbolTarget = '';
      _symbolOptions = const <String>[];
      _symbolDistractors = const <_DynamicSymbolDistractor>[];
      _symbolRecords.clear();
      _symbolShowing = false;
      _symbolChoosing = false;
      _symbolDone = false;
      _symbolLastCorrect = null;
      _symbolFeedbackKey = null;
      _symbolFeedbackParams = const <String, Object?>{};
    });
  }

  Future<void> startBallRound() async {
    if (_ballShowing || _ballAnswering || _ballDone) {
      return;
    }
    final token = ++_ballToken;
    final difficulty = _rollBallDifficulty();
    final answer = difficulty.count;
    final speed = difficulty.speed;
    final balls = _createBalls(_lastBallStageSize, answer, speed);
    setState(() {
      _ballAnswer = answer;
      _ballOptions = const <int>[];
      _balls = balls;
      _ballShowing = true;
      _ballAnswering = false;
      _ballLastCorrect = null;
      _ballFeedbackKey = null;
      _ballFeedbackParams = const <String, Object?>{};
    });
    _lastBallTick = null;
    _ballController
      ..reset()
      ..repeat();
    await Future<void>.delayed(Duration(milliseconds: _ballObservationMs));
    if (!mounted || token != _ballToken || !_ballShowing) {
      return;
    }
    _ballController.stop();
    setState(() {
      _ballShowing = false;
      _ballAnswering = true;
      _ballOptions = _answerOptionsFor(answer);
    });
  }

  void chooseBallCount(int value) {
    if (!_ballAnswering) {
      return;
    }
    final correct = value == _ballAnswer;
    setState(() {
      _ballAnswering = false;
      _ballLastCorrect = correct;
      if (correct) {
        _ballCorrect += 1;
        _ballLevel += 1;
        _ballBestLevel = math.max(_ballBestLevel, _ballLevel);
        _ballFeedbackKey =
            'inline.plan297.human_tests.dynamic_vision.ball_correct';
        _ballFeedbackParams = const <String, Object?>{};
      } else {
        _ballMisses += 1;
        _ballDone = _ballMisses >= 3;
        _ballFeedbackKey = _ballDone
            ? 'inline.plan297.human_tests.dynamic_vision.ball_test_over'
            : 'inline.plan297.human_tests.dynamic_vision.ball_try_level_again';
        _ballFeedbackParams = <String, Object?>{'answer': _ballAnswer};
      }
    });
  }

  void resetBalls() {
    _ballController.stop();
    _ballToken += 1;
    setState(() {
      _ballLevel = 1;
      _ballCorrect = 0;
      _ballMisses = 0;
      _ballBestLevel = 1;
      _ballAnswer = 0;
      _ballOptions = const <int>[];
      _balls = <_DynamicVisionBall>[];
      _ballShowing = false;
      _ballAnswering = false;
      _ballDone = false;
      _ballLastCorrect = null;
      _ballFeedbackKey = null;
      _ballFeedbackParams = const <String, Object?>{};
    });
  }

  void _tickBalls() {
    if (!_ballShowing || _balls.isEmpty) {
      return;
    }
    final elapsed = _ballController.lastElapsedDuration;
    final previous = _lastBallTick;
    _lastBallTick = elapsed;
    if (elapsed == null || previous == null) {
      return;
    }
    final dt =
        (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond;
    if (dt <= 0 || dt > 0.08) {
      return;
    }
    _advanceBalls(_lastBallStageSize, dt);
  }

  void _advanceBalls(Size size, double dt) {
    for (final ball in _balls) {
      ball.position += ball.velocity * dt;
      if (ball.position.dx - ball.radius < 0) {
        ball.position = Offset(ball.radius, ball.position.dy);
        ball.velocity = Offset(ball.velocity.dx.abs(), ball.velocity.dy);
      } else if (ball.position.dx + ball.radius > size.width) {
        ball.position = Offset(size.width - ball.radius, ball.position.dy);
        ball.velocity = Offset(-ball.velocity.dx.abs(), ball.velocity.dy);
      }
      if (ball.position.dy - ball.radius < 0) {
        ball.position = Offset(ball.position.dx, ball.radius);
        ball.velocity = Offset(ball.velocity.dx, ball.velocity.dy.abs());
      } else if (ball.position.dy + ball.radius > size.height) {
        ball.position = Offset(ball.position.dx, size.height - ball.radius);
        ball.velocity = Offset(ball.velocity.dx, -ball.velocity.dy.abs());
      }
    }

    for (var i = 0; i < _balls.length; i += 1) {
      for (var j = i + 1; j < _balls.length; j += 1) {
        final first = _balls[i];
        final second = _balls[j];
        final delta = second.position - first.position;
        final minDistance = first.radius + second.radius;
        final distanceSquared = delta.distanceSquared;
        if (distanceSquared <= 0 ||
            distanceSquared >= minDistance * minDistance) {
          continue;
        }
        final distance = math.sqrt(distanceSquared);
        final normal = delta / distance;
        final overlap = (minDistance - distance) / 2;
        first.position -= normal * overlap;
        second.position += normal * overlap;
        final impulse =
            (first.velocity - second.velocity).dx * normal.dx +
            (first.velocity - second.velocity).dy * normal.dy;
        if (impulse > 0) {
          first.velocity -= normal * impulse;
          second.velocity += normal * impulse;
        }
      }
    }
  }

  Duration symbolDurationForRound(int round) {
    final progress = _growthProgress(
      _symbolCurve,
      math.max(0, round - 1),
      math.max(1, _symbolRoundCount - 1),
    );
    final speed = _symbolBaseSpeed * (1.0 + progress * 0.95);
    return Duration(milliseconds: (1050 / speed).round().clamp(360, 1800));
  }

  List<_DynamicVisionBall> _createBalls(Size size, int count, double speed) {
    final palette = <Color>[
      const Color(0xFF4E9AA8),
      const Color(0xFFE2A44D),
      const Color(0xFF6EA66A),
      const Color(0xFFB46AA5),
      const Color(0xFFC95E59),
      const Color(0xFF6478C8),
    ];
    final shortestSide = math.min(size.width, size.height);
    final radius = (shortestSide / (13.5 + count * 0.35)).clamp(8.0, 14.0);
    final balls = <_DynamicVisionBall>[];
    final uniformColor = palette[_random.nextInt(palette.length)];
    for (var i = 0; i < count; i += 1) {
      Offset position = Offset.zero;
      for (var attempt = 0; attempt < 80; attempt += 1) {
        final candidate = Offset(
          radius + _random.nextDouble() * math.max(1, size.width - radius * 2),
          radius + _random.nextDouble() * math.max(1, size.height - radius * 2),
        );
        if (balls.every(
          (ball) =>
              (ball.position - candidate).distance >= ball.radius + radius + 4,
        )) {
          position = candidate;
          break;
        }
      }
      if (position == Offset.zero) {
        position = Offset(
          radius + _random.nextDouble() * math.max(1, size.width - radius * 2),
          radius + _random.nextDouble() * math.max(1, size.height - radius * 2),
        );
      }
      final angle = _random.nextDouble() * math.pi * 2;
      final velocitySpeed = (95 + _random.nextDouble() * 90) * speed;
      balls.add(
        _DynamicVisionBall(
          position: position,
          velocity: Offset(math.cos(angle), math.sin(angle)) * velocitySpeed,
          radius: radius,
          color: _ballColorMode == _DynamicBallColorMode.uniform
              ? uniformColor
              : palette[i % palette.length],
        ),
      );
    }
    return balls;
  }

  List<int> _answerOptionsFor(int answer) {
    final values = <int>{answer};
    final lower = math.max(1, answer - 3);
    final upper = math.min(_ballMaxCount, answer + 3);
    for (var value = lower; value <= upper; value += 1) {
      values.add(value);
    }
    while (values.length < math.min(7, _ballMaxCount)) {
      values.add(1 + _random.nextInt(_ballMaxCount));
    }
    return values.toList(growable: false)..sort();
  }

  _DynamicBallDifficulty _rollBallDifficulty() {
    final countRange = _ballCountRangeForLevel(_ballLevel);
    final speedRange = _ballSpeedRangeForLevel(_ballLevel);
    final count =
        countRange.min + _random.nextInt(countRange.max - countRange.min + 1);
    final speed =
        speedRange.min +
        _random.nextDouble() * math.max(0.01, speedRange.max - speedRange.min);
    return _DynamicBallDifficulty(count: count, speed: speed);
  }

  _DynamicIntRange _ballCountRangeForLevel(int level) {
    final safeLevel = math.max(1, level);
    final progress = _growthProgress(_ballCurve, safeLevel - 1, 9);
    final easedCount =
        _ballStartCount +
        (progress * math.max(1, _ballMaxCount - _ballStartCount)).round();
    final spread = (1 + (safeLevel / 3).floor()).clamp(1, 5);
    final minCount = math.max(_ballStartCount, easedCount - spread);
    final maxCount = math.min(_ballMaxCount, easedCount + spread + 1);
    return _DynamicIntRange(min: minCount, max: maxCount);
  }

  _DynamicDoubleRange _ballSpeedRangeForLevel(int level) {
    final safeLevel = math.max(1, level);
    final baseProgress = _growthProgress(_ballCurve, safeLevel - 1, 10);
    final minSpeed = (_ballBaseSpeed * (0.78 + baseProgress * 0.72)).clamp(
      0.45,
      4.2,
    );
    final maxSpeed = (_ballBaseSpeed * (1.10 + baseProgress * 1.80)).clamp(
      minSpeed + 0.10,
      4.8,
    );
    return _DynamicDoubleRange(min: minSpeed, max: maxSpeed + safeLevel * 0.03);
  }

  List<String> _symbolCandidates() {
    final custom = _parseSymbolCustomSource(_symbolCustomSource);
    if (_symbolSet == _DynamicSymbolSet.custom && custom.length >= 2) {
      return custom;
    }
    final source = switch (_symbolSet) {
      _DynamicSymbolSet.digits => const <String>[
        '0',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
      ],
      _DynamicSymbolSet.letters => const <String>[
        'A',
        'B',
        'C',
        'D',
        'E',
        'F',
        'H',
        'K',
        'M',
        'N',
        'R',
        'S',
      ],
      _DynamicSymbolSet.confusable => const <String>[
        'B',
        '8',
        '6',
        'G',
        'O',
        '0',
        'Q',
        'D',
        'P',
        'F',
      ],
      _DynamicSymbolSet.custom => custom.length >= 2 ? custom : _symbolValues,
      _DynamicSymbolSet.mixed => _symbolValues,
    };
    if (_symbolGroupLength <= 1 || _symbolSet == _DynamicSymbolSet.custom) {
      return source;
    }
    final generated = <String>{};
    final targetCount = math.min(72, math.pow(source.length, 2).round());
    var guard = 0;
    while (generated.length < targetCount && guard < 400) {
      guard += 1;
      generated.add(
        List<String>.generate(
          _symbolGroupLength,
          (_) => _sample(_random, source),
        ).join(),
      );
    }
    return generated.toList(growable: false);
  }

  List<_DynamicSymbolDistractor> _buildSymbolDistractors(
    List<String> candidates,
    String target,
  ) {
    if (!_symbolDistractorEnabled || candidates.length < 3) {
      return const <_DynamicSymbolDistractor>[];
    }
    final count = switch (_difficultyLikeSymbolLoad) {
      0 => 2,
      1 => 3,
      _ => 4,
    };
    final values = candidates.where((value) => value != target).toList()
      ..shuffle(_random);
    return List<_DynamicSymbolDistractor>.generate(
      math.min(count, values.length),
      (index) => _DynamicSymbolDistractor(
        value: values[index],
        dx: 0.12 + _random.nextDouble() * 0.76,
        dy: 0.16 + _random.nextDouble() * 0.68,
      ),
      growable: false,
    );
  }

  int get _difficultyLikeSymbolLoad {
    var load = 0;
    if (_symbolGroupLength >= 3) {
      load += 1;
    }
    if (_symbolBaseSpeed >= 1.35) {
      load += 1;
    }
    if (_symbolSet == _DynamicSymbolSet.confusable) {
      load += 1;
    }
    return load;
  }

  Future<void> _showSymbolReport() async {
    if (!mounted || _symbolRecords.isEmpty || _symbolReportDialogOpen) {
      return;
    }
    _symbolReportDialogOpen = true;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    try {
      await showDialog<void>(
        context: context,
        builder: (context) => _DynamicSymbolReportDialog(
          i18n: i18n,
          records: List<_DynamicSymbolRecord>.unmodifiable(_symbolRecords),
          setLabel: (set) => symbolSetLabel(i18n, set),
          pathLabel: (path) => symbolPathLabel(i18n, path),
        ),
      );
    } finally {
      _symbolReportDialogOpen = false;
    }
  }

  List<String> _parseSymbolCustomSource(String source) {
    final seen = <String>{};
    final values = <String>[];
    for (final raw in source.split(RegExp(r'[,，]'))) {
      final value = raw.trim();
      if (value.isEmpty || seen.contains(value)) {
        continue;
      }
      seen.add(value);
      values.add(value);
    }
    return values;
  }

  int? parseObservationMilliseconds(String input) {
    final normalized = input.trim().replaceAll('，', '.');
    if (normalized.isEmpty) {
      return null;
    }
    final seconds = double.tryParse(normalized);
    if (seconds == null || seconds <= 0) {
      return null;
    }
    return (seconds * 1000).round().clamp(800, 12000);
  }

  String formatObservationInput(int milliseconds) {
    return (milliseconds / 1000).toStringAsFixed(
      milliseconds % 1000 == 0 ? 0 : 1,
    );
  }

  String get _ballCountRangeLabel {
    final range = _ballCountRangeForLevel(_ballLevel);
    return range.min == range.max
        ? '${range.min}'
        : '${range.min}-${range.max}';
  }

  String get _ballSpeedRangeLabel {
    final range = _ballSpeedRangeForLevel(_ballLevel);
    return '${formatSpeed(range.min)}-${formatSpeed(range.max)}';
  }

  Future<void> updateBallSetting(VoidCallback change) async {
    if (!_ballInProgress) {
      setState(change);
      _normalizeBallSettings();
      resetBalls();
      return;
    }
    final confirmed = await _confirmSettingRestart(
      messageKey:
          'inline.plan297.human_tests.dynamic_vision.restart.ball_count',
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(change);
    _normalizeBallSettings();
    resetBalls();
  }

  Future<void> updateSymbolSetting(VoidCallback change) async {
    if (!_symbolInProgress) {
      setState(change);
      resetSymbol();
      return;
    }
    final confirmed = await _confirmSettingRestart(
      messageKey:
          'inline.plan297.human_tests.dynamic_vision.restart.symbol_settings',
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(change);
    resetSymbol();
  }

  Future<bool> _confirmSettingRestart({required String messageKey}) async {
    if (_settingConfirmOpen) {
      return false;
    }
    _settingConfirmOpen = true;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_dynamic_vision.change_settings_597f9a',
              ),
            ),
            content: Text(i18n.t(messageKey)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(i18n.t('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  i18n.t(
                    'inline.ui.pages.toolbox_human_tests_dynamic_vision.confirm_and_reset_dc1feb',
                  ),
                ),
              ),
            ],
          );
        },
      );
      return result ?? false;
    } finally {
      _settingConfirmOpen = false;
    }
  }

  void _normalizeBallSettings() {
    if (_ballStartCount > _ballMaxCount) {
      _ballStartCount = _ballMaxCount;
    }
    _ballObservationMs = _ballObservationMs.clamp(800, 12000);
    _ballObservationController.text = formatObservationInput(
      _ballObservationMs,
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildDynamicVisionBody(context);
  }

  double get _symbolEffectiveSpeed {
    final progress = _growthProgress(
      _symbolCurve,
      math.max(0, _symbolRound),
      math.max(1, _symbolRoundCount - 1),
    );
    return _symbolBaseSpeed * (1.0 + progress * 0.95);
  }

  void setLastBallStageSize(Size value) => _lastBallStageSize = value;

  List<_DynamicVisionBall> get visibleBalls =>
      _ballShowing ? _balls : const <_DynamicVisionBall>[];

  Animation<double> get symbolAnimation => _symbolController;

  Animation<double> get ballAnimation => _ballController;

  Color get accent => _accent;

  String get symbolTarget => _symbolTarget;

  bool get symbolShowing => _symbolShowing;

  Future<void> showSymbolReport() => _showSymbolReport();

  Offset symbolPositionFor(double value, Size size) {
    final safeWidth = math.max(1, size.width - 86);
    final safeHeight = math.max(1, size.height - 64);
    final wave = math.sin((value + _symbolRound * 0.13) * math.pi * 2);
    return switch (_symbolPath) {
      _DynamicSymbolPath.horizontal => Offset(
        24 + value * safeWidth,
        (size.height * 0.50 - 22).clamp(16.0, size.height - 56),
      ),
      _DynamicSymbolPath.wave => Offset(
        24 + value * safeWidth,
        (size.height * (0.50 + wave * _symbolWaveAmplitude) - 22).clamp(
          16.0,
          size.height - 56,
        ),
      ),
      _DynamicSymbolPath.diagonal => Offset(
        24 + value * safeWidth,
        (24 + value * safeHeight).clamp(16.0, size.height - 56),
      ),
      _DynamicSymbolPath.bounce => Offset(
        24 + value * safeWidth,
        (size.height * (0.50 + wave.abs() * _symbolWaveAmplitude) - 24).clamp(
          16.0,
          size.height - 56,
        ),
      ),
    };
  }

  double _growthProgress(_DynamicVisionGrowthCurve curve, int step, int span) {
    final raw = (step / math.max(1, span)).clamp(0.0, 1.0);
    return switch (curve) {
      _DynamicVisionGrowthCurve.gentle => math.pow(raw, 1.45).toDouble(),
      _DynamicVisionGrowthCurve.linear => raw,
      _DynamicVisionGrowthCurve.accelerated => math.pow(raw, 0.72).toDouble(),
    };
  }

  String curveLabel(AppI18n i18n, _DynamicVisionGrowthCurve curve) {
    return switch (curve) {
      _DynamicVisionGrowthCurve.gentle => i18n.t(
        'inline.plan295.breathing.gentle.26bb0cd9fc59',
      ),
      _DynamicVisionGrowthCurve.linear => i18n.t(
        'inline.ui.pages.toolbox_human_tests_aim.linear_4e4feb',
      ),
      _DynamicVisionGrowthCurve.accelerated => i18n.t(
        'inline.ui.pages.toolbox_human_tests_dynamic_vision.accelerated_982033',
      ),
    };
  }

  String symbolSetLabel(AppI18n i18n, _DynamicSymbolSet set) {
    return switch (set) {
      _DynamicSymbolSet.mixed => i18n.t(
        'inline.ui.pages.practice_support.mixed_fba1b6',
      ),
      _DynamicSymbolSet.digits => i18n.t(
        'inline.ui.pages.toolbox_human_tests_dynamic_vision.digits_f3a6b5',
      ),
      _DynamicSymbolSet.letters => i18n.t(
        'inline.ui.pages.playback_advanced_page.letters_53e8af',
      ),
      _DynamicSymbolSet.confusable => i18n.t(
        'inline.ui.pages.toolbox_human_tests_dynamic_vision.confusable_1ac46a',
      ),
      _DynamicSymbolSet.custom => i18n.t('toolbox.sound.harp.custom'),
    };
  }

  String symbolPathLabel(AppI18n i18n, _DynamicSymbolPath path) {
    return switch (path) {
      _DynamicSymbolPath.wave => i18n.t(
        'inline.ui.pages.toolbox_human_tests_bimanual.wave_825f43',
      ),
      _DynamicSymbolPath.horizontal => i18n.t('toolbox.sound.harp.horizontal'),
      _DynamicSymbolPath.diagonal => i18n.t(
        'inline.ui.pages.toolbox_human_tests_dynamic_vision.diagonal_c5a023',
      ),
      _DynamicSymbolPath.bounce => i18n.t(
        'inline.ui.pages.toolbox_human_tests_bimanual.bounce_16ab0f',
      ),
    };
  }

  String formatSpeed(double value) => '${value.toStringAsFixed(1)}x';
}

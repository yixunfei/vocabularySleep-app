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
      title: pickUiText(
        i18n,
        zh: '动态视力测试',
        en: 'Dynamic vision',
        ja: 'Dynamic vision',
        de: 'Dynamic vision',
        fr: 'Vision dynamique',
        es: 'Visión dinámica',
        ru: 'Динамическое зрение',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '在移动字符识别与小球数量判断之间切换，训练快速追踪与动态辨识。',
        en: 'Switch between moving-symbol recognition and moving-ball counting for fast tracking practice.',
        ja: 'Switch between moving-symbol recognition and moving-ball counting for fast tracking practice.',
        de: 'Switch between moving-symbol recognition and moving-ball counting for fast tracking practice.',
        fr: 'Interrupteur entre la reconnaissance mobile-symbole et le comptage mobile-ball pour une pratique de suivi rapide.',
        es: 'Interruptor entre el reconocimiento del simbolo móvil y el conteo de bolas móviles para la práctica de seguimiento rápido.',
        ru: 'Переключение между распознаванием движущихся символов и подсчетом движущихся шаров для быстрой практики отслеживания.',
      ),
      accent: const Color(0xFF407E92),
      icon: Icons.remove_red_eye_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：选择模式后开始观察',
        en: 'Next: choose a mode and start observing',
        ja: 'Next: choose a mode and start observing',
        de: 'Next: choose a mode and start observing',
        fr: 'Suivant : choisissez un mode et commencez à observer',
        es: 'Siguiente: elegir un modo y comenzar a observar',
        ru: 'Далее: выберите режим и начните наблюдение',
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

  _DynamicVisionMode _mode = _DynamicVisionMode.symbol;

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
  String? _symbolFeedbackZh;
  String? _symbolFeedbackEn;
  String? _symbolFeedbackJa;
  String? _symbolFeedbackDe;
  String? _symbolFeedbackFr;
  String? _symbolFeedbackEs;
  String? _symbolFeedbackRu;
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
  String? _ballFeedbackZh;
  String? _ballFeedbackEn;
  String? _ballFeedbackJa;
  String? _ballFeedbackDe;
  String? _ballFeedbackFr;
  String? _ballFeedbackEs;
  String? _ballFeedbackRu;
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
  String? get symbolFeedbackZh => _symbolFeedbackZh;
  String? get symbolFeedbackEn => _symbolFeedbackEn;
  String? get symbolFeedbackJa => _symbolFeedbackJa;
  String? get symbolFeedbackDe => _symbolFeedbackDe;
  String? get symbolFeedbackFr => _symbolFeedbackFr;
  String? get symbolFeedbackEs => _symbolFeedbackEs;
  String? get symbolFeedbackRu => _symbolFeedbackRu;
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
  String? get ballFeedbackZh => _ballFeedbackZh;
  String? get ballFeedbackEn => _ballFeedbackEn;
  String? get ballFeedbackJa => _ballFeedbackJa;
  String? get ballFeedbackDe => _ballFeedbackDe;
  String? get ballFeedbackFr => _ballFeedbackFr;
  String? get ballFeedbackEs => _ballFeedbackEs;
  String? get ballFeedbackRu => _ballFeedbackRu;
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
      zh: '切换模式会结束当前观察并重置新模式。确认后需要手动点击开始。',
      en: 'Switching modes will stop the current observation and reset the new mode. Press Start manually after confirming.',
      ja: 'モードを切り替えると現在の観察を終了し、新しいモードをリセットします。確認後は手動で開始してください。',
      de: 'Beim Moduswechsel wird die aktuelle Beobachtung beendet und der neue Modus zurückgesetzt. Starte danach manuell.',
      fr: 'Changer de mode arrête l’observation en cours et réinitialise le nouveau mode. Relancez ensuite manuellement.',
      es: 'Cambiar de modo detendrá la observación actual y reiniciará el nuevo modo. Después inicia manualmente.',
      ru: 'Смена режима остановит текущее наблюдение и сбросит новый режим. После подтверждения начните вручную.',
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
      _symbolFeedbackZh = null;
      _symbolFeedbackEn = null;
      _symbolFeedbackJa = null;
      _symbolFeedbackDe = null;
      _symbolFeedbackFr = null;
      _symbolFeedbackEs = null;
      _symbolFeedbackRu = null;
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
      _symbolFeedbackZh = correct ? '正确，准备下一轮。' : '答案是 $_symbolTarget。';
      _symbolFeedbackEn = correct
          ? 'Correct. Preparing the next round.'
          : 'The answer was $_symbolTarget.';
      _symbolFeedbackJa = correct
          ? '正解です。次のラウンドへ進みます。'
          : '答えは $_symbolTarget でした。';
      _symbolFeedbackDe = correct
          ? 'Richtig. Die nächste Runde ist bereit.'
          : 'Die Antwort war $_symbolTarget.';
      _symbolFeedbackFr = correct
          ? 'Correct. Préparez la manche suivante.'
          : 'La réponse était $_symbolTarget.';
      _symbolFeedbackEs = correct
          ? 'Correcto. Prepara la siguiente ronda.'
          : 'La respuesta era $_symbolTarget.';
      _symbolFeedbackRu = correct
          ? 'Верно. Готовим следующий раунд.'
          : 'Ответ: $_symbolTarget.';
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
      _symbolFeedbackZh = null;
      _symbolFeedbackEn = null;
      _symbolFeedbackJa = null;
      _symbolFeedbackDe = null;
      _symbolFeedbackFr = null;
      _symbolFeedbackEs = null;
      _symbolFeedbackRu = null;
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
      _ballFeedbackZh = null;
      _ballFeedbackEn = null;
      _ballFeedbackJa = null;
      _ballFeedbackDe = null;
      _ballFeedbackFr = null;
      _ballFeedbackEs = null;
      _ballFeedbackRu = null;
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
        _ballFeedbackZh = '正确，准备下一轮。';
        _ballFeedbackEn = 'Correct. Ready for the next round.';
        _ballFeedbackJa = '正解です。次のラウンドへ進みます。';
        _ballFeedbackDe = 'Richtig. Bereit für die nächste Runde.';
        _ballFeedbackFr = 'Correct. Prêt pour la manche suivante.';
        _ballFeedbackEs = 'Correcto. Listo para la siguiente ronda.';
        _ballFeedbackRu = 'Верно. Готово к следующему раунду.';
      } else {
        _ballMisses += 1;
        _ballDone = _ballMisses >= 3;
        _ballFeedbackZh = _ballDone
            ? '测试结束。正确数量是 $_ballAnswer。'
            : '正确数量是 $_ballAnswer，保持当前等级再试一次。';
        _ballFeedbackEn = _ballDone
            ? 'Test over. The correct count was $_ballAnswer.'
            : 'The correct count was $_ballAnswer. Try this level again.';
        _ballFeedbackJa = _ballDone
            ? '終了です。正しい数は $_ballAnswer でした。'
            : '正しい数は $_ballAnswer です。同じレベルでもう一度。';
        _ballFeedbackDe = _ballDone
            ? 'Test beendet. Die richtige Anzahl war $_ballAnswer.'
            : 'Die richtige Anzahl war $_ballAnswer. Versuche dieses Level noch einmal.';
        _ballFeedbackFr = _ballDone
            ? 'Test terminé. Le bon nombre était $_ballAnswer.'
            : 'Le bon nombre était $_ballAnswer. Réessayez ce niveau.';
        _ballFeedbackEs = _ballDone
            ? 'Prueba terminada. La cantidad correcta era $_ballAnswer.'
            : 'La cantidad correcta era $_ballAnswer. Repite este nivel.';
        _ballFeedbackRu = _ballDone
            ? 'Тест завершен. Правильное число: $_ballAnswer.'
            : 'Правильное число: $_ballAnswer. Попробуйте этот уровень еще раз.';
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
      _ballFeedbackZh = null;
      _ballFeedbackEn = null;
      _ballFeedbackJa = null;
      _ballFeedbackDe = null;
      _ballFeedbackFr = null;
      _ballFeedbackEs = null;
      _ballFeedbackRu = null;
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
      zh: '修改小球数量设置会重置当前测试。确认后需要手动点击开始。',
      en: 'Changing ball-count settings will reset the current test. Press Start manually after confirming.',
      ja: '小球の数の設定を変えると現在のテストがリセットされます。確認後は手動で開始してください。',
      de: 'Änderungen an der Kugelanzahl setzen den aktuellen Test zurück. Starte danach manuell.',
      fr: 'Modifier le nombre de balles réinitialise le test en cours. Relancez ensuite manuellement.',
      es: 'Cambiar la cantidad de bolas reiniciará la prueba actual. Después inicia manualmente.',
      ru: 'Изменение количества шаров сбросит текущий тест. После подтверждения начните вручную.',
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
      zh: '修改字符识别设置会重置当前测试。确认后需要手动点击开始。',
      en: 'Changing symbol settings will reset the current test. Press Start manually after confirming.',
      ja: '文字識別の設定を変えると現在のテストがリセットされます。確認後は手動で開始してください。',
      de: 'Änderungen an den Symbol-Einstellungen setzen den aktuellen Test zurück. Starte danach manuell.',
      fr: 'Modifier les réglages des symboles réinitialise le test en cours. Relancez ensuite manuellement.',
      es: 'Cambiar los ajustes de símbolos reiniciará la prueba actual. Después inicia manualmente.',
      ru: 'Изменение настроек символов сбросит текущий тест. После подтверждения начните вручную.',
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(change);
    resetSymbol();
  }

  Future<bool> _confirmSettingRestart({
    required String zh,
    required String en,
    required String ja,
    required String de,
    required String fr,
    required String es,
    required String ru,
  }) async {
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
              pickUiText(
                i18n,
                zh: '确认修改设置？',
                en: 'Change settings?',
                ja: '設定を変更',
                de: 'Change settings?',
                fr: 'Changer les paramètres ?',
                es: '¿Cambio de configuración?',
                ru: 'Изменить настройки?',
              ),
            ),
            content: Text(
              pickUiText(
                i18n,
                zh: zh,
                en: en,
                ja: ja,
                de: de,
                fr: fr,
                es: es,
                ru: ru,
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  pickUiText(
                    i18n,
                    zh: '取消',
                    en: 'Cancel',
                    ja: '取り消す',
                    de: 'Cancel',
                    fr: 'Annuler',
                    es: 'Cancelar',
                    ru: 'отменить',
                  ),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  pickUiText(
                    i18n,
                    zh: '确认并重置',
                    en: 'Confirm and reset',
                    ja: 'を確認してリセット',
                    de: 'Confirm and reset',
                    fr: 'Confirmer et réinitialiser',
                    es: 'Confirmación y restablecimiento',
                    ru: 'Подтвердить и сбросить',
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
      _DynamicVisionGrowthCurve.gentle => pickUiText(
        i18n,
        zh: '平缓',
        en: 'Gentle',
        ja: 'Gentle',
        de: 'Gentle',
        fr: 'Doucement',
        es: 'Gentle',
        ru: 'нежный',
      ),
      _DynamicVisionGrowthCurve.linear => pickUiText(
        i18n,
        zh: '线性',
        en: 'Linear',
        ja: 'Linear',
        de: 'Linear',
        fr: 'Linéaire',
        es: 'Linear',
        ru: 'линейный',
      ),
      _DynamicVisionGrowthCurve.accelerated => pickUiText(
        i18n,
        zh: '加速',
        en: 'Accelerated',
        ja: '加速化された',
        de: 'Accelerated',
        fr: 'Accelerated',
        es: 'Acelerada',
        ru: 'ускоренный',
      ),
    };
  }

  String symbolSetLabel(AppI18n i18n, _DynamicSymbolSet set) {
    return switch (set) {
      _DynamicSymbolSet.mixed => pickUiText(
        i18n,
        zh: '混合',
        en: 'Mixed',
        ja: 'Mixed',
        de: 'Mixed',
        fr: 'Mélange',
        es: 'Mezcla',
        ru: 'смешанный',
      ),
      _DynamicSymbolSet.digits => pickUiText(
        i18n,
        zh: '数字',
        en: 'Digits',
        ja: 'Digits',
        de: 'Digits',
        fr: 'Chiffres',
        es: 'Digits',
        ru: 'Цифры',
      ),
      _DynamicSymbolSet.letters => pickUiText(
        i18n,
        zh: '字母',
        en: 'Letters',
        ja: 'Letters',
        de: 'Letters',
        fr: 'Lettres',
        es: 'Cartas',
        ru: 'Письма',
      ),
      _DynamicSymbolSet.confusable => pickUiText(
        i18n,
        zh: '易混淆',
        en: 'Confusable',
        ja: 'にくい',
        de: 'Confusable',
        fr: 'Confisable',
        es: 'Confusable',
        ru: 'путаный',
      ),
      _DynamicSymbolSet.custom => pickUiText(
        i18n,
        zh: '自定义',
        en: 'Custom',
        ja: 'Custom',
        de: 'Custom',
        fr: 'Personnalisé',
        es: 'Aduanas',
        ru: 'обычай',
      ),
    };
  }

  String symbolPathLabel(AppI18n i18n, _DynamicSymbolPath path) {
    return switch (path) {
      _DynamicSymbolPath.wave => pickUiText(
        i18n,
        zh: '波浪',
        en: 'Wave',
        ja: 'Wave',
        de: 'Wave',
        fr: 'Vague',
        es: 'Wave',
        ru: 'волна',
      ),
      _DynamicSymbolPath.horizontal => pickUiText(
        i18n,
        zh: '水平',
        en: 'Horizontal',
        ja: 'Horizontal',
        de: 'Horizontal',
        fr: 'Horizontale',
        es: 'Horizontal',
        ru: 'горизонтальный',
      ),
      _DynamicSymbolPath.diagonal => pickUiText(
        i18n,
        zh: '斜线',
        en: 'Diagonal',
        ja: 'Diagonal',
        de: 'Diagonal',
        fr: 'Diagonal',
        es: 'Diagonal',
        ru: 'диагональ',
      ),
      _DynamicSymbolPath.bounce => pickUiText(
        i18n,
        zh: '弹跳',
        en: 'Bounce',
        ja: 'バウンスバウンス',
        de: 'Bounce',
        fr: 'Bounce',
        es: 'Bounce',
        ru: 'отскакивать',
      ),
    };
  }

  String formatSpeed(double value) => '${value.toStringAsFixed(1)}x';
}

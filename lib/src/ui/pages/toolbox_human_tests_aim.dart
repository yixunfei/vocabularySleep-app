part of 'toolbox_human_tests.dart';

enum _AimTestMode { classic, revealGrowth, moving, decoys }

enum _AimGrowthCurve { linear, easeOut, easeIn, easeInOut, fastOutSlowIn }

enum _AimFeedbackKind {
  idle,
  ready,
  hit,
  miss,
  decoy,
  timeout,
  sniperFail,
  complete,
}

class AimTestPage extends StatelessWidget {
  const AimTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(
        i18n,
        zh: '瞄准测试',
        en: 'Aim test',
        ja: '照準テスト',
        de: 'Aim test',
        fr: 'Aim test',
        es: 'Prueba de objetivos',
        ru: 'Цель испытания',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '从经典点靶扩展到降级放大、移动靶和真假目标干扰，练速度，也练稳定性。',
        en: 'Train speed and control with classic, reveal-grow, moving, and decoy target modes.',
        ja: 'Train speed and control with classic, reveal-grow, moving, and decoy target modes.',
        de: 'Train speed and control with classic, reveal-grow, moving, and decoy target modes.',
        fr: 'Vitesse et contrôle du train avec des modes classiques, de révélation, de déplacement et de cible de leurre.',
        es: 'Entrena la velocidad y el control con los modos de destino clásicos, revelador, en movimiento y decodificación.',
        ru: 'Скорость поезда и управление с классическими, открытыми, движущимися и скрытыми целевыми режимами.',
      ),
      accent: const Color(0xFFC24D5A),
      icon: Icons.adjust_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：选择模式后开始追踪目标',
        en: 'Next: choose a mode and track the targets',
        ja: 'Next: choose a mode and track the targets',
        de: 'Next: choose a mode and track the targets',
        fr: 'Suivant : choisir un mode et suivre les cibles',
        es: 'Siguiente: elegir un modo y seguir los objetivos',
        ru: 'Далее: выберите режим и отследите цели',
      ),
      child: const _AimTestCard(),
    );
  }
}

class _AimTestCard extends StatefulWidget {
  const _AimTestCard();

  @override
  State<_AimTestCard> createState() => _AimTestCardState();
}

class _AimTestCardState extends State<_AimTestCard>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFFC24D5A);
  static const Color _support = Color(0xFF3E8A89);

  final math.Random _random = math.Random();
  final Stopwatch _sessionStopwatch = Stopwatch();
  final Stopwatch _targetStopwatch = Stopwatch();
  final List<int> _hitIntervals = <int>[];

  late final AnimationController _stageController;

  _AimTestMode _mode = _AimTestMode.classic;
  _AimTarget? _target;
  List<_AimTarget> _decoys = const <_AimTarget>[];
  int _targetGoal = 20;
  double _targetDiameter = 54;
  double _movementSpeed = 1.2;
  double _growthSpeed = 1.1;
  double _revealStartDiameter = 0.2;
  double _revealVisibleDiameter = 6;
  int _revealMilliseconds = 120;
  _AimGrowthCurve _speedCurve = _AimGrowthCurve.easeOut;
  _AimGrowthCurve _targetCurve = _AimGrowthCurve.easeInOut;
  int _decoyCount = 3;
  bool _revealMoves = false;
  bool _movingDecoys = false;
  bool _decoysMove = false;
  bool _sniperDuel = false;

  int _resolvedTargets = 0;
  int _hits = 0;
  int _misses = 0;
  int _decoyHits = 0;
  int _timeouts = 0;
  int _sniperFailures = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  int? _latestHitMs;
  int? _finalMilliseconds;
  bool _running = false;
  bool _done = false;
  _AimFeedbackKind _feedbackKind = _AimFeedbackKind.idle;

  @override
  void initState() {
    super.initState();
    _stageController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1600),
          )
          ..addListener(_handleAnimationTick)
          ..addStatusListener(_handleAnimationStatus);
  }

  @override
  void dispose() {
    _stageController
      ..removeListener(_handleAnimationTick)
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    _sessionStopwatch.stop();
    _targetStopwatch.stop();
    super.dispose();
  }

  int get _attempts => _hits + _misses + _decoyHits + _timeouts;

  bool get _usesRevealGrowth => _mode == _AimTestMode.revealGrowth;

  bool get _usesMovement =>
      _mode == _AimTestMode.moving ||
      (_usesRevealGrowth && _revealMoves) ||
      (_mode == _AimTestMode.decoys && _decoysMove);

  bool get _usesDecoys =>
      _mode == _AimTestMode.decoys ||
      (_mode == _AimTestMode.moving && _movingDecoys);

  bool get _usesSniperDuel => _usesRevealGrowth && _sniperDuel;

  double? get _accuracy {
    if (_attempts == 0) {
      return null;
    }
    return _hits / _attempts;
  }

  double? get _averageHitMs {
    if (_hitIntervals.isEmpty) {
      return null;
    }
    return _hitIntervals.reduce((a, b) => a + b) / _hitIntervals.length;
  }

  void _handleAnimationTick() {
    if (!_running) {
      return;
    }
    if (_usesMovement || _usesRevealGrowth) {
      setState(() {});
    }
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (!_running ||
        !_usesRevealGrowth ||
        status != AnimationStatus.completed) {
      return;
    }
    _resolveCurrentTarget(
      _usesSniperDuel ? _AimFeedbackKind.sniperFail : _AimFeedbackKind.timeout,
    );
  }

  void _start() {
    _stageController.stop();
    _sessionStopwatch
      ..reset()
      ..start();
    _hitIntervals.clear();
    setState(() {
      _resolvedTargets = 0;
      _hits = 0;
      _misses = 0;
      _decoyHits = 0;
      _timeouts = 0;
      _sniperFailures = 0;
      _currentStreak = 0;
      _bestStreak = 0;
      _latestHitMs = null;
      _finalMilliseconds = null;
      _running = true;
      _done = false;
      _feedbackKind = _AimFeedbackKind.ready;
      _spawnTargetData();
    });
    _startTargetClockAndAnimation();
  }

  void _reset() {
    _stageController.stop();
    _sessionStopwatch.stop();
    _targetStopwatch.stop();
    _hitIntervals.clear();
    setState(() {
      _target = null;
      _decoys = const <_AimTarget>[];
      _resolvedTargets = 0;
      _hits = 0;
      _misses = 0;
      _decoyHits = 0;
      _timeouts = 0;
      _sniperFailures = 0;
      _currentStreak = 0;
      _bestStreak = 0;
      _latestHitMs = null;
      _finalMilliseconds = null;
      _running = false;
      _done = false;
      _feedbackKind = _AimFeedbackKind.idle;
    });
  }

  void _setMode(_AimTestMode mode) {
    if (_running || _mode == mode) {
      return;
    }
    setState(() {
      _mode = mode;
      _done = false;
      _feedbackKind = _AimFeedbackKind.idle;
    });
  }

  void _setRevealMoves(bool value) {
    if (_running) {
      return;
    }
    setState(() {
      _revealMoves = value;
      _done = false;
    });
  }

  void _setMovingDecoys(bool value) {
    if (_running) {
      return;
    }
    setState(() {
      _movingDecoys = value;
      _done = false;
    });
  }

  void _setDecoysMove(bool value) {
    if (_running) {
      return;
    }
    setState(() {
      _decoysMove = value;
      _done = false;
    });
  }

  void _setSniperDuel(bool value) {
    if (_running) {
      return;
    }
    setState(() {
      _sniperDuel = value;
      _done = false;
    });
  }

  void _setTargetGoal(double value) {
    setState(() {
      _targetGoal = value.round().clamp(5, 60);
      _done = false;
    });
  }

  void _setTargetDiameter(double value) {
    setState(() {
      _targetDiameter = value.clamp(28, 78);
      _done = false;
    });
  }

  void _setMovementSpeed(double value) {
    setState(() {
      _movementSpeed = value.clamp(0.6, 3.0);
      _done = false;
    });
  }

  void _setGrowthSpeed(double value) {
    setState(() {
      _growthSpeed = value.clamp(0.7, 2.8);
      _done = false;
    });
  }

  void _setRevealStartDiameter(double value) {
    setState(() {
      _revealStartDiameter = value.clamp(0.0, 4.0);
      _done = false;
    });
  }

  void _setRevealVisibleDiameter(double value) {
    setState(() {
      _revealVisibleDiameter = value.clamp(3.0, 16.0);
      _done = false;
    });
  }

  void _setRevealMilliseconds(double value) {
    setState(() {
      _revealMilliseconds = value.round().clamp(60, 260);
      _done = false;
    });
  }

  void _setSpeedCurve(_AimGrowthCurve curve) {
    setState(() {
      _speedCurve = curve;
      _done = false;
    });
  }

  void _setTargetCurve(_AimGrowthCurve curve) {
    setState(() {
      _targetCurve = curve;
      _done = false;
    });
  }

  void _setDecoyCount(double value) {
    setState(() {
      _decoyCount = value.round().clamp(1, 6);
      _done = false;
    });
  }

  void _spawnTargetData() {
    _target = _AimTarget(
      start: _randomPoint(),
      end: _usesMovement ? _randomPoint() : null,
      diameter: _targetDiameter,
      decoy: false,
    );
    if (_usesDecoys) {
      _decoys = List<_AimTarget>.generate(
        _decoyCount,
        (_) => _AimTarget(
          start: _randomPoint(),
          end: _usesMovement ? _randomPoint() : null,
          diameter: _targetDiameter * (0.82 + _random.nextDouble() * 0.2),
          decoy: true,
        ),
      );
    } else {
      _decoys = const <_AimTarget>[];
    }
  }

  Offset _randomPoint() {
    return Offset(
      0.11 + _random.nextDouble() * 0.78,
      0.12 + _random.nextDouble() * 0.76,
    );
  }

  void _startTargetClockAndAnimation() {
    _targetStopwatch
      ..reset()
      ..start();
    _stageController.stop();
    if (_usesRevealGrowth) {
      final durationMs = (2600 / _growthSpeed).round().clamp(900, 4200);
      _stageController
        ..duration = Duration(milliseconds: durationMs)
        ..forward(from: 0);
      return;
    }
    if (_usesMovement) {
      final durationMs = (2300 / _movementSpeed).round().clamp(620, 3600);
      _stageController
        ..duration = Duration(milliseconds: durationMs)
        ..repeat(reverse: true);
      return;
    }
    _stageController.value = 0;
  }

  void _handleStageTap(Offset position, Size size) {
    if (!_running) {
      return;
    }
    final target = _target;
    if (target == null) {
      return;
    }

    for (final decoy in _decoys) {
      if (_containsTarget(position, size, decoy)) {
        _resolveCurrentTarget(_AimFeedbackKind.decoy);
        return;
      }
    }

    if (_containsTarget(position, size, target)) {
      _resolveCurrentTarget(_AimFeedbackKind.hit);
      return;
    }

    setState(() {
      _misses += 1;
      _currentStreak = 0;
      _feedbackKind = _AimFeedbackKind.miss;
    });
  }

  bool _containsTarget(Offset position, Size size, _AimTarget target) {
    final center = _absoluteCenter(target, size);
    final radius = _targetDisplayDiameter(target) / 2;
    return (position - center).distance <= radius;
  }

  Offset _absoluteCenter(_AimTarget target, Size size) {
    final center = target.center(_stageController.value);
    return Offset(center.dx * size.width, center.dy * size.height);
  }

  double _targetDisplayDiameter(_AimTarget target) {
    if (target.decoy || !_usesRevealGrowth) {
      return target.diameter;
    }
    final durationMs = _stageController.duration?.inMilliseconds ?? 2200;
    final elapsedMs = durationMs * _stageController.value.clamp(0.0, 1.0);
    final revealCapMs = math.max(80, durationMs - 80);
    final revealMs = _revealMilliseconds.clamp(60, revealCapMs).toDouble();
    final startDiameter = math.min(
      _revealStartDiameter,
      _revealVisibleDiameter,
    );
    final visibleDiameter = math.min(_revealVisibleDiameter, target.diameter);

    if (elapsedMs <= revealMs) {
      final t = _curveValue(_speedCurve, elapsedMs / revealMs);
      return _lerp(
        startDiameter,
        visibleDiameter,
        t,
      ).clamp(0.0, target.diameter);
    }

    final growSpan = math.max(1.0, durationMs - revealMs);
    final t = _curveValue(_targetCurve, (elapsedMs - revealMs) / growSpan);
    return _lerp(
      visibleDiameter,
      target.diameter,
      t,
    ).clamp(0.0, target.diameter);
  }

  double _lerp(double start, double end, double t) {
    return start + (end - start) * t.clamp(0.0, 1.0);
  }

  double _curveValue(_AimGrowthCurve curve, double value) {
    final t = value.clamp(0.0, 1.0);
    return switch (curve) {
      _AimGrowthCurve.linear => t,
      _AimGrowthCurve.easeOut => Curves.easeOutCubic.transform(t),
      _AimGrowthCurve.easeIn => Curves.easeInCubic.transform(t),
      _AimGrowthCurve.easeInOut => Curves.easeInOutCubic.transform(t),
      _AimGrowthCurve.fastOutSlowIn => Curves.fastOutSlowIn.transform(t),
    };
  }

  void _resolveCurrentTarget(_AimFeedbackKind kind) {
    if (!_running) {
      return;
    }

    if (kind == _AimFeedbackKind.hit) {
      final interval = _targetStopwatch.elapsedMilliseconds;
      _hitIntervals.add(interval);
      _latestHitMs = interval;
    }

    final finished = _resolvedTargets + 1 >= _targetGoal;
    setState(() {
      _resolvedTargets += 1;
      switch (kind) {
        case _AimFeedbackKind.hit:
          _hits += 1;
          _currentStreak += 1;
          _bestStreak = math.max(_bestStreak, _currentStreak);
        case _AimFeedbackKind.decoy:
          _decoyHits += 1;
          _currentStreak = 0;
        case _AimFeedbackKind.timeout:
          _timeouts += 1;
          _currentStreak = 0;
        case _AimFeedbackKind.sniperFail:
          _timeouts += 1;
          _sniperFailures += 1;
          _currentStreak = 0;
        case _AimFeedbackKind.miss:
        case _AimFeedbackKind.idle:
        case _AimFeedbackKind.ready:
        case _AimFeedbackKind.complete:
          break;
      }

      if (finished) {
        _running = false;
        _done = true;
        _feedbackKind = _AimFeedbackKind.complete;
        _finalMilliseconds = _sessionStopwatch.elapsedMilliseconds;
      } else {
        _feedbackKind = kind;
        _spawnTargetData();
      }
    });

    if (finished) {
      _stageController.stop();
      _sessionStopwatch.stop();
      _targetStopwatch.stop();
    } else if (kind == _AimFeedbackKind.sniperFail) {
      _stageController.stop();
      _targetStopwatch.stop();
    } else {
      _startTargetClockAndAnimation();
    }

    if (kind == _AimFeedbackKind.sniperFail) {
      unawaited(_showSniperFailureOverlay(finished: finished));
    } else if (finished) {
      unawaited(_showResultReport());
    }
  }

  Future<void> _showSniperFailureOverlay({required bool finished}) async {
    await _triggerSniperHaptics();
    if (!mounted) {
      return;
    }
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.red.withValues(alpha: 0.38),
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (dialogContext, _, _) {
        return _AimSniperFailureOverlay(
          accent: _accent,
          title: pickUiText(
            i18n,
            zh: '你被虚拟狙击手命中',
            en: 'Sniper hit',
            ja: 'Sniper hit',
            de: 'Sniper hit',
            fr: 'Sniper touché',
            es: 'Sniper hit',
            ru: 'Снайперский удар',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '目标已经放大到最大，反制窗口结束。本轮按失败记录。',
            en: 'The target reached maximum size. The counter-shot window closed.',
            ja: 'The target reached maximum size. The counter-shot window closed.',
            de: 'The target reached maximum size. The counter-shot window closed.',
            fr: 'La cible a atteint la taille maximale. La fenêtre à contre-coups s\'est fermée.',
            es: 'El objetivo alcanzó el tamaño máximo. La ventana cerrada.',
            ru: 'Цель достигла максимального размера. Окно встречного выстрела закрыто.',
          ),
          actionLabel: finished
              ? pickUiText(
                  i18n,
                  zh: '查看报告',
                  en: 'View report',
                  ja: 'View report',
                  de: 'View report',
                  fr: 'Consulter le rapport',
                  es: 'Ver informe',
                  ru: 'Посмотреть доклад',
                )
              : pickUiText(
                  i18n,
                  zh: '继续',
                  en: 'Continue',
                  ja: '継続',
                  de: 'Continue',
                  fr: 'Continuer',
                  es: 'Continuar',
                  ru: 'Продолжать',
                ),
          onDismiss: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
    if (finished && mounted) {
      await _showResultReport();
    } else if (mounted && _running) {
      _startTargetClockAndAnimation();
    }
  }

  Future<void> _triggerSniperHaptics() async {
    try {
      await HapticFeedback.vibrate();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.heavyImpact();
    } catch (_) {
      // Haptics are best-effort because desktop and web targets may ignore them.
    }
  }

  Future<void> _showResultReport() async {
    if (!mounted || !_done) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _AimCompletionReportDialog(
        accent: _accent,
        modeLabel: _modeCombinationLabel(
          AppI18n(Localizations.localeOf(dialogContext).languageCode),
        ),
        targetGoal: _targetGoal,
        resolvedTargets: _resolvedTargets,
        hits: _hits,
        misses: _misses,
        decoyHits: _decoyHits,
        timeouts: _timeouts,
        sniperFailures: _sniperFailures,
        accuracy: _accuracy,
        averageHitMs: _averageHitMs,
        bestStreak: _bestStreak,
        finalMilliseconds: _finalMilliseconds,
        targetDiameter: _targetDiameter,
        movementEnabled: _usesMovement,
        movementSpeed: _movementSpeed,
        revealEnabled: _usesRevealGrowth,
        revealMilliseconds: _revealMilliseconds,
        growthSpeed: _growthSpeed,
        decoysEnabled: _usesDecoys,
        decoyCount: _decoyCount,
        sniperDuel: _usesSniperDuel,
        rating: _ratingLabel(
          AppI18n(Localizations.localeOf(dialogContext).languageCode),
        ),
      ),
    );
  }

  String _modeLabel(AppI18n i18n, _AimTestMode mode) {
    return switch (mode) {
      _AimTestMode.classic => pickUiText(
        i18n,
        zh: '经典点靶',
        en: 'Classic',
        ja: 'クラシック',
        de: 'Classic',
        fr: 'Classique',
        es: 'Clásico',
        ru: 'Классика',
      ),
      _AimTestMode.revealGrowth => pickUiText(
        i18n,
        zh: '降级放大',
        en: 'Reveal grow',
        ja: 'Reveal grow',
        de: 'Reveal grow',
        fr: 'Faire pousser les révélations',
        es: 'Crecimiento de la venganza',
        ru: 'Показать рост',
      ),
      _AimTestMode.moving => pickUiText(
        i18n,
        zh: '移动靶',
        en: 'Moving',
        ja: 'Moving',
        de: 'Moving',
        fr: 'Déplacement',
        es: 'Moving',
        ru: 'двигаться',
      ),
      _AimTestMode.decoys => pickUiText(
        i18n,
        zh: '真假干扰',
        en: 'Decoys',
        ja: 'Decoys',
        de: 'Decoys',
        fr: 'Décors',
        es: 'Decoys',
        ru: 'Декои',
      ),
    };
  }

  String _modeDescription(AppI18n i18n, _AimTestMode mode) {
    return switch (mode) {
      _AimTestMode.classic => pickUiText(
        i18n,
        zh: '目标固定出现，适合测速和热身。',
        en: 'Fixed targets for speed checks and warm-ups.',
        ja: 'Fixed targets for speed checks and warm-ups.',
        de: 'Fixed targets for speed checks and warm-ups.',
        fr: 'Objectifs fixes pour les contrôles de vitesse et les échauffements.',
        es: 'Objetivos fijos para cheques de velocidad y calentamientos.',
        ru: 'Фиксированные цели для проверки скорости и разминки.',
      ),
      _AimTestMode.revealGrowth => pickUiText(
        i18n,
        zh: '目标从几乎不可见的点快速显形，再持续放大，越早命中越难。',
        en: 'The target starts nearly invisible, appears quickly, then keeps growing.',
        ja: 'The target starts nearly invisible, appears quickly, then keeps growing.',
        de: 'The target starts nearly invisible, appears quickly, then keeps growing.',
        fr: 'La cible commence presque invisible, apparaît rapidement, puis continue de croître.',
        es: 'El objetivo comienza casi invisible, aparece rápidamente, luego sigue creciendo.',
        ru: 'Цель становится почти невидимой, появляется быстро, а затем продолжает расти.',
      ),
      _AimTestMode.moving => pickUiText(
        i18n,
        zh: '目标在两点之间移动，考验追踪和预判。',
        en: 'The target moves between two points for tracking practice.',
        ja: 'The target moves between two points for tracking practice.',
        de: 'The target moves between two points for tracking practice.',
        fr: 'La cible se déplace entre deux points pour suivre la pratique.',
        es: 'El objetivo se mueve entre dos puntos para la práctica de seguimiento.',
        ru: 'Цель перемещается между двумя точками для отслеживания.',
      ),
      _AimTestMode.decoys => pickUiText(
        i18n,
        zh: '红色是真目标，青色是假目标，点错会重刷。',
        en: 'Red is real, teal is false. Hitting a decoy refreshes the round.',
        ja: 'Red is real, teal is false. Hitting a decoy refreshes the round.',
        de: 'Red is real, teal is false. Hitting a decoy refreshes the round.',
        fr: 'Red est réel, Teal est faux. Frapper un leurre rafraîchit la ronde.',
        es: 'Red es real, teal es falso. Hitting un decoy refresca la ronda.',
        ru: 'Красный - настоящий, теля - ложный. Удар по приманке освежает раунд.',
      ),
    };
  }

  String _feedbackText(AppI18n i18n) {
    return switch (_feedbackKind) {
      _AimFeedbackKind.idle => _modeDescription(i18n, _mode),
      _AimFeedbackKind.ready => pickUiText(
        i18n,
        zh: '目标已出现，尽快稳定命中。',
        en: 'Target is live. Aim and hit cleanly.',
        ja: 'Target is live. Aim and hit cleanly.',
        de: 'Target is live. Aim and hit cleanly.',
        fr: 'La cible est en direct. Visez et frappez proprement.',
        es: 'El blanco está vivo. Apunta y golpea limpiamente.',
        ru: 'Цель живая. Целься и ударь чисто.',
      ),
      _AimFeedbackKind.hit =>
        _latestHitMs == null
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
                zh: '命中：${_formatMilliseconds(_latestHitMs!)}',
                en: 'Hit: ${_formatMilliseconds(_latestHitMs!)}',
                ja: 'Hit: ${_formatMilliseconds(_latestHitMs!)}',
                de: 'Hit: ${_formatMilliseconds(_latestHitMs!)}',
                fr: 'Affichage : ${_formatMilliseconds(_latestHitMs!)}',
                es: 'Visto:',
                ru: 'Хит: ${_formatMilliseconds(_latestHitMs!)}',
              ),
      _AimFeedbackKind.miss => pickUiText(
        i18n,
        zh: '点空了，目标不会消失，但连击已断。',
        en: 'Blank tap. The target stays, but the streak is broken.',
        ja: 'ブランクタップ。ターゲットは残るが、ストリークは壊れている。',
        de: 'Blank tap. The target stays, but the streak is broken.',
        fr: 'Un robinet blanc. La cible reste, mais la stries est cassée.',
        es: 'Grifo blanco. El objetivo se queda, pero la racha está rota.',
        ru: 'Бланковый кран. Цель остается, но полоса сломана.',
      ),
      _AimFeedbackKind.decoy => pickUiText(
        i18n,
        zh: '点到假目标，本轮刷新。',
        en: 'Decoy hit. Round refreshed.',
        ja: 'Decoy hit. Round refreshed.',
        de: 'Decoy hit. Round refreshed.',
        fr: 'C\'est déco. Rond rafraîchi.',
        es: 'Golpe de Decoy. Refrigerio redondo.',
        ru: 'Декой ударил. Круг освежен.',
      ),
      _AimFeedbackKind.timeout => pickUiText(
        i18n,
        zh: '放大窗口结束，进入下一目标。',
        en: 'Growth window ended. Moving to the next target.',
        ja: 'Growth window ended. Moving to the next target.',
        de: 'Growth window ended. Moving to the next target.',
        fr: 'La fenêtre de croissance s\'est terminée. Aller à la prochaine cible.',
        es: 'La ventana de crecimiento terminó. Mover al siguiente objetivo.',
        ru: 'Окно роста закончилось. Переход к следующей цели.',
      ),
      _AimFeedbackKind.sniperFail => pickUiText(
        i18n,
        zh: '虚拟狙击手命中，反制失败。',
        en: 'Sniper hit. Counter-shot failed.',
        ja: 'Sniper hit. Counter-shot failed.',
        de: 'Sniper hit. Counter-shot failed.',
        fr: 'Sniper frappé. Le contre-coup a échoué.',
        es: 'Golpe de francotirador. El disparo falló.',
        ru: 'Удар снайпера. Контр-выстрел провалился.',
      ),
      _AimFeedbackKind.complete => pickUiText(
        i18n,
        zh: '测试完成，可以调整模式再来一轮。',
        en: 'Test complete. Tune the mode and run another round.',
        ja: 'Test complete. Tune the mode and run another round.',
        de: 'Test complete. Tune the mode and run another round.',
        fr: 'Essai terminé. Alignez le mode et exécutez un autre tour.',
        es: 'Prueba completa. Tune el modo y ejecute otra ronda.',
        ru: 'Тест завершен. Настройте режим и запустите еще один раунд.',
      ),
    };
  }

  String _ratingLabel(AppI18n i18n) {
    if (!_done) {
      return '-';
    }
    final accuracy = _accuracy ?? 0;
    final average = _averageHitMs ?? 9999;
    if (accuracy >= 0.92 && average <= 620) {
      return pickUiText(
        i18n,
        zh: 'S 级',
        en: 'S tier',
        ja: 'S tier',
        de: 'S tier',
        fr: 'Niveau S',
        es: 'S tierno',
        ru: 'Уровень',
      );
    }
    if (accuracy >= 0.82 && average <= 850) {
      return pickUiText(
        i18n,
        zh: 'A 级',
        en: 'A tier',
        ja: 'ランク',
        de: 'A tier',
        fr: 'A tier',
        es: 'Un tierno',
        ru: 'ярус',
      );
    }
    if (accuracy >= 0.70 && average <= 1150) {
      return pickUiText(
        i18n,
        zh: 'B 级',
        en: 'B tier',
        ja: 'Bティア',
        de: 'B tier',
        fr: 'Niveau B',
        es: 'B tier',
        ru: 'B-ярус',
      );
    }
    return pickUiText(
      i18n,
      zh: '练习中',
      en: 'Training',
      ja: 'Training',
      de: 'Training',
      fr: 'Formation',
      es: 'Capacitación',
      ru: 'Подготовка',
    );
  }

  String _modeCombinationLabel(AppI18n i18n) {
    final parts = <String>[_modeLabel(i18n, _mode)];
    if (_usesRevealGrowth && _revealMoves) {
      parts.add(
        pickUiText(
          i18n,
          zh: '移动放大',
          en: 'moving growth',
          ja: 'moving growth',
          de: 'moving growth',
          fr: 'croissance',
          es: 'crecimiento en movimiento',
          ru: 'движущийся рост',
        ),
      );
    }
    if (_mode == _AimTestMode.moving && _movingDecoys) {
      parts.add(
        pickUiText(
          i18n,
          zh: '真假干扰',
          en: 'decoys',
          ja: 'decoys',
          de: 'decoys',
          fr: 'leurres',
          es: 'decoys',
          ru: 'приманка',
        ),
      );
    }
    if (_mode == _AimTestMode.decoys && _decoysMove) {
      parts.add(
        pickUiText(
          i18n,
          zh: '移动干扰',
          en: 'moving decoys',
          ja: 'moving decoys',
          de: 'moving decoys',
          fr: 'leurres mobiles',
          es: 'mudanzas decoys',
          ru: 'перемещение приманок',
        ),
      );
    }
    if (_usesSniperDuel) {
      parts.add(
        pickUiText(
          i18n,
          zh: '狙击手对决',
          en: 'sniper duel',
          ja: 'sniper duel',
          de: 'sniper duel',
          fr: 'sniper duel',
          es: 'duelo de francotirador',
          ru: 'Снайперская дуэль',
        ),
      );
    }
    return parts.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final average = _averageHitMs;
    final accuracy = _accuracy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
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
              _modeLabel(i18n, _mode),
            ),
            (
              pickUiText(
                i18n,
                zh: '目标',
                en: 'Targets',
                ja: 'Targets',
                de: 'Targets',
                fr: 'Objectifs',
                es: 'Metas',
                ru: 'Цели',
              ),
              '$_resolvedTargets/$_targetGoal',
            ),
            (
              pickUiText(
                i18n,
                zh: '命中',
                en: 'Hits',
                ja: 'Hits',
                de: 'Hits',
                fr: 'Coups',
                es: 'Golpes',
                ru: 'Хиты',
              ),
              '$_hits',
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
              accuracy == null ? '-' : '${(accuracy * 100).round()}%',
            ),
            (
              pickUiText(
                i18n,
                zh: '平均命中',
                en: 'Avg hit',
                ja: '平均ヒット',
                de: 'Avg hit',
                fr: 'Avg touché',
                es: 'Avg hit',
                ru: 'Авг ударил',
              ),
              average == null ? '-' : _formatMilliseconds(average),
            ),
            (
              pickUiText(
                i18n,
                zh: '最佳连击',
                en: 'Best streak',
                ja: 'ベストストリーク',
                de: 'Best streak',
                fr: 'Meilleure série',
                es: 'La mejor racha',
                ru: 'Лучшая полоса',
              ),
              '$_bestStreak',
            ),
            (
              pickUiText(
                i18n,
                zh: '评级',
                en: 'Rating',
                ja: 'Rating',
                de: 'Rating',
                fr: 'Évaluation',
                es: 'Valoración',
                ru: 'Рейтинг',
              ),
              _ratingLabel(i18n),
            ),
            if (_sniperFailures > 0)
              (
                pickUiText(
                  i18n,
                  zh: '狙击失败',
                  en: 'Sniper fails',
                  ja: 'Sniper fails',
                  de: 'Sniper fails',
                  fr: 'Le tireur échoue',
                  es: 'El francotirador falla',
                  ru: 'Снайпер провалился',
                ),
                '$_sniperFailures',
              ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: pickUiText(
            i18n,
            zh: '瞄准设置',
            en: 'Aim settings',
            ja: '照準設定',
            de: 'Aim settings',
            fr: 'Aim settings',
            es: 'Ajustes de objetivos',
            ru: 'Настройка цели',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '模式、目标数量、大小、显形、移动和干扰强度。',
            en: 'Modes, target count, size, reveal timing, movement, and decoys.',
            ja: 'Modes, target count, size, reveal timing, movement, and decoys.',
            de: 'Modes, target count, size, reveal timing, movement, and decoys.',
            fr: 'Modes, nombre de cibles, taille, révéler le timing, le mouvement et les leurres.',
            es: 'Modos, recuento de objetivos, tamaño, revelar tiempo, movimiento y decoys.',
            ru: 'Режимы, количество целей, размер, выявляют время, движение и приманки.',
          ),
          child: _buildSettings(i18n),
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          padding: EdgeInsets.zero,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final height = math.min(390.0, constraints.maxWidth * 0.78);
              final stageSize = Size(constraints.maxWidth, height);
              return _HumanPointerDragBoundary(
                onPointerDown: (event) =>
                    _handleStageTap(event.localPosition, stageSize),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: SizedBox(
                    key: const ValueKey<String>('aim_stage_area'),
                    height: height,
                    width: double.infinity,
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _AimStagePainter(
                              accent: _accent,
                              support: _support,
                              progress: _stageController.value,
                              running: _running,
                            ),
                          ),
                        ),
                        if (_running) ..._buildTargetMarkers(stageSize),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: _AimFeedbackPanel(
                            accent: _accent,
                            text: _feedbackText(i18n),
                            running: _running,
                          ),
                        ),
                        if (!_running)
                          Center(
                            child: _AimStageIdleCard(
                              title: _done
                                  ? pickUiText(
                                      i18n,
                                      zh: '本轮完成',
                                      en: 'Round complete',
                                      ja: 'Round complete',
                                      de: 'Round complete',
                                      fr: 'Cycle terminé',
                                      es: 'Ronda completa',
                                      ru: 'Полный раунд',
                                    )
                                  : pickUiText(
                                      i18n,
                                      zh: '准备开始',
                                      en: 'Ready',
                                      ja: 'Ready',
                                      de: 'Ready',
                                      fr: 'Prêt',
                                      es: 'Listo',
                                      ru: 'Готовы',
                                    ),
                              subtitle: _done
                                  ? pickUiText(
                                      i18n,
                                      zh: '总用时 ${_formatMilliseconds(_finalMilliseconds ?? 0)}',
                                      en: 'Total ${_formatMilliseconds(_finalMilliseconds ?? 0)}',
                                      ja: 'Total ${_formatMilliseconds(_finalMilliseconds ?? 0)}',
                                      de: 'Total ${_formatMilliseconds(_finalMilliseconds ?? 0)}',
                                      fr: 'Total ${_formatMilliseconds(_finalMilliseconds ?? 0)}',
                                      es: 'Total',
                                      ru: 'Всего ${_formatMilliseconds(_finalMilliseconds ?? 0)}',
                                    )
                                  : _modeDescription(i18n, _mode),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
                      zh: '开始',
                      en: 'Start',
                      ja: 'Start',
                      de: 'Start',
                      fr: 'Démarrer',
                      es: 'Comienzo',
                      ru: 'Начинать',
                    ),
              icon: _running ? Icons.refresh_rounded : Icons.play_arrow_rounded,
              onPressed: _start,
            ),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.restart_alt_rounded),
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
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(112, 48),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            if (_done)
              OutlinedButton.icon(
                onPressed: _showResultReport,
                icon: const Icon(Icons.summarize_rounded),
                label: Text(
                  pickUiText(
                    i18n,
                    zh: '查看报告',
                    en: 'View report',
                    ja: 'View report',
                    de: 'View report',
                    fr: 'Consulter le rapport',
                    es: 'Ver informe',
                    ru: 'Посмотреть доклад',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(112, 48),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildTargetMarkers(Size stageSize) {
    final target = _target;
    if (target == null) {
      return const <Widget>[];
    }
    final targets = <_AimTarget>[..._decoys, target];
    return targets
        .map((item) {
          final diameter = _targetDisplayDiameter(item);
          final center = _absoluteCenter(item, stageSize);
          return Positioned(
            left: (center.dx - diameter / 2).clamp(
              0,
              stageSize.width - diameter,
            ),
            top: (center.dy - diameter / 2).clamp(
              0,
              stageSize.height - diameter,
            ),
            width: diameter,
            height: diameter,
            child: IgnorePointer(
              child: _AimTargetMarker(
                key: ValueKey<String>(
                  item.decoy
                      ? 'aim_decoy_marker_${targets.indexOf(item)}'
                      : 'aim_real_target_marker',
                ),
                accent: item.decoy ? _support : _accent,
                decoy: item.decoy,
                progress: _usesRevealGrowth && !item.decoy
                    ? _stageController.value
                    : 0,
                simplePoint: _usesRevealGrowth && !item.decoy,
              ),
            ),
          );
        })
        .toList(growable: false);
  }

  Widget _buildSettings(AppI18n i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
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
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _AimTestMode.values
              .map((mode) {
                return ChoiceChip(
                  label: Text(_modeLabel(i18n, mode)),
                  selected: _mode == mode,
                  onSelected: _running ? null : (_) => _setMode(mode),
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 8),
        Text(
          _modeDescription(i18n, _mode),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        _AimSettingSlider(
          label: pickUiText(
            i18n,
            zh: '目标总数',
            en: 'Target total',
            ja: 'Target total',
            de: 'Target total',
            fr: 'Total des objectifs',
            es: 'Total objetivo',
            ru: 'Общая цель',
          ),
          valueText: '$_targetGoal',
          value: _targetGoal.toDouble(),
          min: 5,
          max: 60,
          divisions: 11,
          onChanged: _running ? null : _setTargetGoal,
        ),
        _AimSettingSlider(
          label: pickUiText(
            i18n,
            zh: '目标大小',
            en: 'Target size',
            ja: 'Target size',
            de: 'Target size',
            fr: 'Taille cible',
            es: 'Tamaño del objetivo',
            ru: 'Целевой размер',
          ),
          valueText: '${_targetDiameter.round()} dp',
          value: _targetDiameter,
          min: 28,
          max: 78,
          divisions: 25,
          onChanged: _running ? null : _setTargetDiameter,
        ),
        if (_mode == _AimTestMode.moving)
          _AimSettingSlider(
            label: pickUiText(
              i18n,
              zh: '移动速度',
              en: 'Movement speed',
              ja: 'Movement speed',
              de: 'Movement speed',
              fr: 'Vitesse de mouvement',
              es: 'Velocidad de movimiento',
              ru: 'Скорость движения',
            ),
            valueText: '${_movementSpeed.toStringAsFixed(1)}x',
            value: _movementSpeed,
            min: 0.6,
            max: 3.0,
            divisions: 24,
            onChanged: _running ? null : _setMovementSpeed,
          ),
        if (_mode == _AimTestMode.moving) ...<Widget>[
          _AimSettingSwitch(
            title: pickUiText(
              i18n,
              zh: '加入真假干扰',
              en: 'Add decoys',
              ja: 'おとりを追加',
              de: 'Add decoys',
              fr: 'Add decoys',
              es: 'Add decoys',
              ru: 'Добавить приманки',
            ),
            subtitle: pickUiText(
              i18n,
              zh: '移动靶旁生成真假目标，形成移动且干扰组合。',
              en: 'Add false targets around the moving target.',
              ja: '移動ターゲットの周りに誤ったターゲットを追加します。',
              de: 'Add false targets around the moving target.',
              fr: 'Add false targets around the moving target.',
              es: 'Añadir falsos objetivos alrededor del objetivo en movimiento.',
              ru: 'Добавьте ложные цели вокруг движущейся цели.',
            ),
            value: _movingDecoys,
            onChanged: _running ? null : _setMovingDecoys,
          ),
          if (_movingDecoys)
            _AimSettingSlider(
              label: pickUiText(
                i18n,
                zh: '假目标数量',
                en: 'False targets',
                ja: 'False targets',
                de: 'False targets',
                fr: 'Faux objectifs',
                es: 'Objetivos falsos',
                ru: 'Ложные цели',
              ),
              valueText: '$_decoyCount',
              value: _decoyCount.toDouble(),
              min: 1,
              max: 6,
              divisions: 5,
              onChanged: _running ? null : _setDecoyCount,
            ),
        ],
        if (_mode == _AimTestMode.revealGrowth) ...<Widget>[
          _AimSettingSlider(
            label: pickUiText(
              i18n,
              zh: '初始点径',
              en: 'Start size',
              ja: 'Start size',
              de: 'Start size',
              fr: 'Taille de démarrage',
              es: 'Tamaño de inicio',
              ru: 'Стартовый размер',
            ),
            valueText: '${_revealStartDiameter.toStringAsFixed(1)} dp',
            value: _revealStartDiameter,
            min: 0,
            max: 4,
            divisions: 40,
            onChanged: _running ? null : _setRevealStartDiameter,
          ),
          _AimSettingSlider(
            label: pickUiText(
              i18n,
              zh: '显形时间',
              en: 'Reveal time',
              ja: 'Reveal time',
              de: 'Reveal time',
              fr: 'Temps de révélation',
              es: 'Tiempo de recuperación',
              ru: 'Время раскрытия',
            ),
            valueText: '$_revealMilliseconds ms',
            value: _revealMilliseconds.toDouble(),
            min: 60,
            max: 260,
            divisions: 20,
            onChanged: _running ? null : _setRevealMilliseconds,
          ),
          _AimSettingSlider(
            label: pickUiText(
              i18n,
              zh: '可见点径',
              en: 'Visible size',
              ja: 'Visible size',
              de: 'Visible size',
              fr: 'Taille visible',
              es: 'Tamaño visible',
              ru: 'Видимый размер',
            ),
            valueText: '${_revealVisibleDiameter.toStringAsFixed(1)} dp',
            value: _revealVisibleDiameter,
            min: 3,
            max: 16,
            divisions: 26,
            onChanged: _running ? null : _setRevealVisibleDiameter,
          ),
          _AimSettingSlider(
            label: pickUiText(
              i18n,
              zh: '放大速率',
              en: 'Growth speed',
              ja: 'Growth speed',
              de: 'Growth speed',
              fr: 'Vitesse de croissance',
              es: 'Velocidad de crecimiento',
              ru: 'Скорость роста',
            ),
            valueText: '${_growthSpeed.toStringAsFixed(1)}x',
            value: _growthSpeed,
            min: 0.7,
            max: 2.8,
            divisions: 21,
            onChanged: _running ? null : _setGrowthSpeed,
          ),
          _AimSettingSwitch(
            title: pickUiText(
              i18n,
              zh: '移动放大',
              en: 'Moving growth',
              ja: 'Moving growth',
              de: 'Moving growth',
              fr: 'Croissance en mouvement',
              es: 'Crecimiento en movimiento',
              ru: 'Движущийся рост',
            ),
            subtitle: pickUiText(
              i18n,
              zh: '目标在移动中从小点放大，组合追踪和抢点。',
              en: 'The target grows while moving, mixing tracking with early hits.',
              ja: 'The target grows while moving, mixing tracking with early hits.',
              de: 'The target grows while moving, mixing tracking with early hits.',
              fr: 'La cible grandit tout en se déplaçant, mélangeant le suivi avec les premiers coups.',
              es: 'El objetivo crece mientras se mueve, mezclando el seguimiento con éxitos tempranos.',
              ru: 'Цель растет при движении, смешивая отслеживание с ранними попаданиями.',
            ),
            value: _revealMoves,
            onChanged: _running ? null : _setRevealMoves,
          ),
          if (_revealMoves)
            _AimSettingSlider(
              label: pickUiText(
                i18n,
                zh: '移动速度',
                en: 'Movement speed',
                ja: 'Movement speed',
                de: 'Movement speed',
                fr: 'Vitesse de mouvement',
                es: 'Velocidad de movimiento',
                ru: 'Скорость движения',
              ),
              valueText: '${_movementSpeed.toStringAsFixed(1)}x',
              value: _movementSpeed,
              min: 0.6,
              max: 3.0,
              divisions: 24,
              onChanged: _running ? null : _setMovementSpeed,
            ),
          _AimSettingSwitch(
            title: pickUiText(
              i18n,
              zh: '虚拟狙击手对决',
              en: 'Sniper duel',
              ja: 'Sniper duel',
              de: 'Sniper duel',
              fr: 'Sniper duel',
              es: 'Duelo de francotirador',
              ru: 'Снайперская дуэль',
            ),
            subtitle: pickUiText(
              i18n,
              zh: '放大到最大仍未命中时，触发震动和红色失败弹窗。',
              en: 'If the target maxes out before a hit, trigger haptics and a red fail alert.',
              ja: 'If the target maxes out before a hit, trigger haptics and a red fail alert.',
              de: 'If the target maxes out before a hit, trigger haptics and a red fail alert.',
              fr: 'Si la cible s\'éteint avant un coup, déclencher des haptiques et une alerte d\'échec rouge.',
              es: 'Si el objetivo se maximiza antes de un golpe, dispara la haptica y una alerta de falla roja.',
              ru: 'Если цель достигает максимума перед ударом, срабатывайте тактильность и красное предупреждение об отказе.',
            ),
            value: _sniperDuel,
            onChanged: _running ? null : _setSniperDuel,
          ),
          _buildCurveSelector(
            i18n,
            label: pickUiText(
              i18n,
              zh: '速率曲线',
              en: 'Speed curve',
              ja: 'Speed curve',
              de: 'Speed curve',
              fr: 'Courbe de vitesse',
              es: 'Curva de velocidad',
              ru: 'Кривая скорости',
            ),
            value: _speedCurve,
            onSelected: _setSpeedCurve,
          ),
          const SizedBox(height: 10),
          _buildCurveSelector(
            i18n,
            label: pickUiText(
              i18n,
              zh: '目标曲线',
              en: 'Target curve',
              ja: 'Target curve',
              de: 'Target curve',
              fr: 'Courbe cible',
              es: 'Curva de destino',
              ru: 'Целевая кривая',
            ),
            value: _targetCurve,
            onSelected: _setTargetCurve,
          ),
        ],
        if (_mode == _AimTestMode.decoys) ...<Widget>[
          _AimSettingSwitch(
            title: pickUiText(
              i18n,
              zh: '真假目标移动',
              en: 'Moving decoys',
              ja: 'Moving decoys',
              de: 'Moving decoys',
              fr: 'Déplacement des leurres',
              es: 'Moving decoys',
              ru: 'Движущиеся приманки',
            ),
            subtitle: pickUiText(
              i18n,
              zh: '真目标和假目标一起移动，形成移动且干扰组合。',
              en: 'Move both real and false targets for the combined decoy drill.',
              ja: 'Move both real and false targets for the combined decoy drill.',
              de: 'Move both real and false targets for the combined decoy drill.',
              fr: 'Déplacer les cibles réelles et fausses pour la perceuse de leurres combinée.',
              es: 'Mover objetivos reales y falsos para el simulacro combinado de decoy.',
              ru: 'Двигайте как реальные, так и ложные цели для комбинированной приманки.',
            ),
            value: _decoysMove,
            onChanged: _running ? null : _setDecoysMove,
          ),
          if (_decoysMove)
            _AimSettingSlider(
              label: pickUiText(
                i18n,
                zh: '移动速度',
                en: 'Movement speed',
                ja: 'Movement speed',
                de: 'Movement speed',
                fr: 'Vitesse de mouvement',
                es: 'Velocidad de movimiento',
                ru: 'Скорость движения',
              ),
              valueText: '${_movementSpeed.toStringAsFixed(1)}x',
              value: _movementSpeed,
              min: 0.6,
              max: 3.0,
              divisions: 24,
              onChanged: _running ? null : _setMovementSpeed,
            ),
          _AimSettingSlider(
            label: pickUiText(
              i18n,
              zh: '假目标数量',
              en: 'False targets',
              ja: 'False targets',
              de: 'False targets',
              fr: 'Faux objectifs',
              es: 'Objetivos falsos',
              ru: 'Ложные цели',
            ),
            valueText: '$_decoyCount',
            value: _decoyCount.toDouble(),
            min: 1,
            max: 6,
            divisions: 5,
            onChanged: _running ? null : _setDecoyCount,
          ),
        ],
      ],
    );
  }

  Widget _buildCurveSelector(
    AppI18n i18n, {
    required String label,
    required _AimGrowthCurve value,
    required ValueChanged<_AimGrowthCurve> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _AimGrowthCurve.values
              .map((curve) {
                return ChoiceChip(
                  label: Text(_curveLabel(i18n, curve)),
                  selected: value == curve,
                  onSelected: _running ? null : (_) => onSelected(curve),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }

  String _curveLabel(AppI18n i18n, _AimGrowthCurve curve) {
    return switch (curve) {
      _AimGrowthCurve.linear => pickUiText(
        i18n,
        zh: '线性',
        en: 'Linear',
        ja: 'Linear',
        de: 'Linear',
        fr: 'Linéaire',
        es: 'Linear',
        ru: 'линейный',
      ),
      _AimGrowthCurve.easeOut => pickUiText(
        i18n,
        zh: '先快后慢',
        en: 'Ease out',
        ja: 'Ease out',
        de: 'Ease out',
        fr: 'Soulagement',
        es: 'Cuidado.',
        ru: 'Успокойся.',
      ),
      _AimGrowthCurve.easeIn => pickUiText(
        i18n,
        zh: '先慢后快',
        en: 'Ease in',
        ja: 'Ease in',
        de: 'Ease in',
        fr: 'Facilité',
        es: 'Facilidad en',
        ru: 'Полегче.',
      ),
      _AimGrowthCurve.easeInOut => pickUiText(
        i18n,
        zh: '平滑',
        en: 'Smooth',
        ja: 'Smooth',
        de: 'Smooth',
        fr: 'Lisse',
        es: 'Smooth',
        ru: 'гладкий',
      ),
      _AimGrowthCurve.fastOutSlowIn => pickUiText(
        i18n,
        zh: '快出慢收',
        en: 'Fast-slow',
        ja: 'Fast-slow',
        de: 'Fast-slow',
        fr: 'Rapide-doux',
        es: 'Despacio rápido',
        ru: 'Медленный',
      ),
    };
  }
}

class _AimTarget {
  const _AimTarget({
    required this.start,
    required this.diameter,
    required this.decoy,
    this.end,
  });

  final Offset start;
  final Offset? end;
  final double diameter;
  final bool decoy;

  Offset center(double progress) {
    final targetEnd = end;
    if (targetEnd == null) {
      return start;
    }
    final t = Curves.easeInOutSine.transform(progress);
    return Offset.lerp(start, targetEnd, t) ?? start;
  }
}

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
      title: pickUiText(i18n, zh: '瞄准测试', en: 'Aim test'),
      subtitle: pickUiText(
        i18n,
        zh: '从经典点靶扩展到降级放大、移动靶和真假目标干扰，练速度，也练稳定性。',
        en: 'Train speed and control with classic, reveal-grow, moving, and decoy target modes.',
      ),
      accent: const Color(0xFFC24D5A),
      icon: Icons.adjust_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：选择模式后开始追踪目标',
        en: 'Next: choose a mode and track the targets',
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
          title: pickUiText(i18n, zh: '你被虚拟狙击手命中', en: 'Sniper hit'),
          subtitle: pickUiText(
            i18n,
            zh: '目标已经放大到最大，反制窗口结束。本轮按失败记录。',
            en: 'The target reached maximum size. The counter-shot window closed.',
          ),
          actionLabel: finished
              ? pickUiText(i18n, zh: '查看报告', en: 'View report')
              : pickUiText(i18n, zh: '继续', en: 'Continue'),
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
      _AimTestMode.classic => pickUiText(i18n, zh: '经典点靶', en: 'Classic'),
      _AimTestMode.revealGrowth => pickUiText(
        i18n,
        zh: '降级放大',
        en: 'Reveal grow',
      ),
      _AimTestMode.moving => pickUiText(i18n, zh: '移动靶', en: 'Moving'),
      _AimTestMode.decoys => pickUiText(i18n, zh: '真假干扰', en: 'Decoys'),
    };
  }

  String _modeDescription(AppI18n i18n, _AimTestMode mode) {
    return switch (mode) {
      _AimTestMode.classic => pickUiText(
        i18n,
        zh: '目标固定出现，适合测速和热身。',
        en: 'Fixed targets for speed checks and warm-ups.',
      ),
      _AimTestMode.revealGrowth => pickUiText(
        i18n,
        zh: '目标从几乎不可见的点快速显形，再持续放大，越早命中越难。',
        en: 'The target starts nearly invisible, appears quickly, then keeps growing.',
      ),
      _AimTestMode.moving => pickUiText(
        i18n,
        zh: '目标在两点之间移动，考验追踪和预判。',
        en: 'The target moves between two points for tracking practice.',
      ),
      _AimTestMode.decoys => pickUiText(
        i18n,
        zh: '红色是真目标，青色是假目标，点错会重刷。',
        en: 'Red is real, teal is false. Hitting a decoy refreshes the round.',
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
      ),
      _AimFeedbackKind.hit =>
        _latestHitMs == null
            ? pickUiText(i18n, zh: '命中', en: 'Hit')
            : pickUiText(
                i18n,
                zh: '命中：${_formatMilliseconds(_latestHitMs!)}',
                en: 'Hit: ${_formatMilliseconds(_latestHitMs!)}',
              ),
      _AimFeedbackKind.miss => pickUiText(
        i18n,
        zh: '点空了，目标不会消失，但连击已断。',
        en: 'Blank tap. The target stays, but the streak is broken.',
      ),
      _AimFeedbackKind.decoy => pickUiText(
        i18n,
        zh: '点到假目标，本轮刷新。',
        en: 'Decoy hit. Round refreshed.',
      ),
      _AimFeedbackKind.timeout => pickUiText(
        i18n,
        zh: '放大窗口结束，进入下一目标。',
        en: 'Growth window ended. Moving to the next target.',
      ),
      _AimFeedbackKind.sniperFail => pickUiText(
        i18n,
        zh: '虚拟狙击手命中，反制失败。',
        en: 'Sniper hit. Counter-shot failed.',
      ),
      _AimFeedbackKind.complete => pickUiText(
        i18n,
        zh: '测试完成，可以调整模式再来一轮。',
        en: 'Test complete. Tune the mode and run another round.',
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
      return pickUiText(i18n, zh: 'S 级', en: 'S tier');
    }
    if (accuracy >= 0.82 && average <= 850) {
      return pickUiText(i18n, zh: 'A 级', en: 'A tier');
    }
    if (accuracy >= 0.70 && average <= 1150) {
      return pickUiText(i18n, zh: 'B 级', en: 'B tier');
    }
    return pickUiText(i18n, zh: '练习中', en: 'Training');
  }

  String _modeCombinationLabel(AppI18n i18n) {
    final parts = <String>[_modeLabel(i18n, _mode)];
    if (_usesRevealGrowth && _revealMoves) {
      parts.add(pickUiText(i18n, zh: '移动放大', en: 'moving growth'));
    }
    if (_mode == _AimTestMode.moving && _movingDecoys) {
      parts.add(pickUiText(i18n, zh: '真假干扰', en: 'decoys'));
    }
    if (_mode == _AimTestMode.decoys && _decoysMove) {
      parts.add(pickUiText(i18n, zh: '移动干扰', en: 'moving decoys'));
    }
    if (_usesSniperDuel) {
      parts.add(pickUiText(i18n, zh: '狙击手对决', en: 'sniper duel'));
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
            (pickUiText(i18n, zh: '模式', en: 'Mode'), _modeLabel(i18n, _mode)),
            (
              pickUiText(i18n, zh: '目标', en: 'Targets'),
              '$_resolvedTargets/$_targetGoal',
            ),
            (pickUiText(i18n, zh: '命中', en: 'Hits'), '$_hits'),
            (
              pickUiText(i18n, zh: '准确率', en: 'Accuracy'),
              accuracy == null ? '-' : '${(accuracy * 100).round()}%',
            ),
            (
              pickUiText(i18n, zh: '平均命中', en: 'Avg hit'),
              average == null ? '-' : _formatMilliseconds(average),
            ),
            (pickUiText(i18n, zh: '最佳连击', en: 'Best streak'), '$_bestStreak'),
            (pickUiText(i18n, zh: '评级', en: 'Rating'), _ratingLabel(i18n)),
            if (_sniperFailures > 0)
              (
                pickUiText(i18n, zh: '狙击失败', en: 'Sniper fails'),
                '$_sniperFailures',
              ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          padding: EdgeInsets.zero,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final height = math.min(390.0, constraints.maxWidth * 0.78);
              final stageSize = Size(constraints.maxWidth, height);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) =>
                    _handleStageTap(details.localPosition, stageSize),
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
                                    )
                                  : pickUiText(i18n, zh: '准备开始', en: 'Ready'),
                              subtitle: _done
                                  ? pickUiText(
                                      i18n,
                                      zh: '总用时 ${_formatMilliseconds(_finalMilliseconds ?? 0)}',
                                      en: 'Total ${_formatMilliseconds(_finalMilliseconds ?? 0)}',
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
                  ? pickUiText(i18n, zh: '重新开始', en: 'Restart')
                  : pickUiText(i18n, zh: '开始', en: 'Start'),
              icon: _running ? Icons.refresh_rounded : Icons.play_arrow_rounded,
              onPressed: _start,
            ),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(112, 48),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            if (_done)
              OutlinedButton.icon(
                onPressed: _showResultReport,
                icon: const Icon(Icons.summarize_rounded),
                label: Text(pickUiText(i18n, zh: '查看报告', en: 'View report')),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(112, 48),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: pickUiText(i18n, zh: '瞄准设置', en: 'Aim settings'),
          subtitle: pickUiText(
            i18n,
            zh: '模式、目标数量、大小、显形、移动和干扰强度。',
            en: 'Modes, target count, size, reveal timing, movement, and decoys.',
          ),
          child: _buildSettings(i18n),
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
          pickUiText(i18n, zh: '模式', en: 'Mode'),
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
          label: pickUiText(i18n, zh: '目标总数', en: 'Target total'),
          valueText: '$_targetGoal',
          value: _targetGoal.toDouble(),
          min: 5,
          max: 60,
          divisions: 11,
          onChanged: _running ? null : _setTargetGoal,
        ),
        _AimSettingSlider(
          label: pickUiText(i18n, zh: '目标大小', en: 'Target size'),
          valueText: '${_targetDiameter.round()} dp',
          value: _targetDiameter,
          min: 28,
          max: 78,
          divisions: 25,
          onChanged: _running ? null : _setTargetDiameter,
        ),
        if (_mode == _AimTestMode.moving)
          _AimSettingSlider(
            label: pickUiText(i18n, zh: '移动速度', en: 'Movement speed'),
            valueText: '${_movementSpeed.toStringAsFixed(1)}x',
            value: _movementSpeed,
            min: 0.6,
            max: 3.0,
            divisions: 24,
            onChanged: _running ? null : _setMovementSpeed,
          ),
        if (_mode == _AimTestMode.moving) ...<Widget>[
          _AimSettingSwitch(
            title: pickUiText(i18n, zh: '加入真假干扰', en: 'Add decoys'),
            subtitle: pickUiText(
              i18n,
              zh: '移动靶旁生成真假目标，形成移动且干扰组合。',
              en: 'Add false targets around the moving target.',
            ),
            value: _movingDecoys,
            onChanged: _running ? null : _setMovingDecoys,
          ),
          if (_movingDecoys)
            _AimSettingSlider(
              label: pickUiText(i18n, zh: '假目标数量', en: 'False targets'),
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
            label: pickUiText(i18n, zh: '初始点径', en: 'Start size'),
            valueText: '${_revealStartDiameter.toStringAsFixed(1)} dp',
            value: _revealStartDiameter,
            min: 0,
            max: 4,
            divisions: 40,
            onChanged: _running ? null : _setRevealStartDiameter,
          ),
          _AimSettingSlider(
            label: pickUiText(i18n, zh: '显形时间', en: 'Reveal time'),
            valueText: '$_revealMilliseconds ms',
            value: _revealMilliseconds.toDouble(),
            min: 60,
            max: 260,
            divisions: 20,
            onChanged: _running ? null : _setRevealMilliseconds,
          ),
          _AimSettingSlider(
            label: pickUiText(i18n, zh: '可见点径', en: 'Visible size'),
            valueText: '${_revealVisibleDiameter.toStringAsFixed(1)} dp',
            value: _revealVisibleDiameter,
            min: 3,
            max: 16,
            divisions: 26,
            onChanged: _running ? null : _setRevealVisibleDiameter,
          ),
          _AimSettingSlider(
            label: pickUiText(i18n, zh: '放大速率', en: 'Growth speed'),
            valueText: '${_growthSpeed.toStringAsFixed(1)}x',
            value: _growthSpeed,
            min: 0.7,
            max: 2.8,
            divisions: 21,
            onChanged: _running ? null : _setGrowthSpeed,
          ),
          _AimSettingSwitch(
            title: pickUiText(i18n, zh: '移动放大', en: 'Moving growth'),
            subtitle: pickUiText(
              i18n,
              zh: '目标在移动中从小点放大，组合追踪和抢点。',
              en: 'The target grows while moving, mixing tracking with early hits.',
            ),
            value: _revealMoves,
            onChanged: _running ? null : _setRevealMoves,
          ),
          if (_revealMoves)
            _AimSettingSlider(
              label: pickUiText(i18n, zh: '移动速度', en: 'Movement speed'),
              valueText: '${_movementSpeed.toStringAsFixed(1)}x',
              value: _movementSpeed,
              min: 0.6,
              max: 3.0,
              divisions: 24,
              onChanged: _running ? null : _setMovementSpeed,
            ),
          _AimSettingSwitch(
            title: pickUiText(i18n, zh: '虚拟狙击手对决', en: 'Sniper duel'),
            subtitle: pickUiText(
              i18n,
              zh: '放大到最大仍未命中时，触发震动和红色失败弹窗。',
              en: 'If the target maxes out before a hit, trigger haptics and a red fail alert.',
            ),
            value: _sniperDuel,
            onChanged: _running ? null : _setSniperDuel,
          ),
          _buildCurveSelector(
            i18n,
            label: pickUiText(i18n, zh: '速率曲线', en: 'Speed curve'),
            value: _speedCurve,
            onSelected: _setSpeedCurve,
          ),
          const SizedBox(height: 10),
          _buildCurveSelector(
            i18n,
            label: pickUiText(i18n, zh: '目标曲线', en: 'Target curve'),
            value: _targetCurve,
            onSelected: _setTargetCurve,
          ),
        ],
        if (_mode == _AimTestMode.decoys) ...<Widget>[
          _AimSettingSwitch(
            title: pickUiText(i18n, zh: '真假目标移动', en: 'Moving decoys'),
            subtitle: pickUiText(
              i18n,
              zh: '真目标和假目标一起移动，形成移动且干扰组合。',
              en: 'Move both real and false targets for the combined decoy drill.',
            ),
            value: _decoysMove,
            onChanged: _running ? null : _setDecoysMove,
          ),
          if (_decoysMove)
            _AimSettingSlider(
              label: pickUiText(i18n, zh: '移动速度', en: 'Movement speed'),
              valueText: '${_movementSpeed.toStringAsFixed(1)}x',
              value: _movementSpeed,
              min: 0.6,
              max: 3.0,
              divisions: 24,
              onChanged: _running ? null : _setMovementSpeed,
            ),
          _AimSettingSlider(
            label: pickUiText(i18n, zh: '假目标数量', en: 'False targets'),
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
      _AimGrowthCurve.linear => pickUiText(i18n, zh: '线性', en: 'Linear'),
      _AimGrowthCurve.easeOut => pickUiText(i18n, zh: '先快后慢', en: 'Ease out'),
      _AimGrowthCurve.easeIn => pickUiText(i18n, zh: '先慢后快', en: 'Ease in'),
      _AimGrowthCurve.easeInOut => pickUiText(i18n, zh: '平滑', en: 'Smooth'),
      _AimGrowthCurve.fastOutSlowIn => pickUiText(
        i18n,
        zh: '快出慢收',
        en: 'Fast-slow',
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

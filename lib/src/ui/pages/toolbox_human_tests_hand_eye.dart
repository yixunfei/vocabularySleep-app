part of 'toolbox_human_tests.dart';

enum _HandEyePhase { idle, waiting, visible, done }

enum _JoystickTestMode { timed, targetCount }

enum _HandEyeVisibleMode { timed, untilTaps }

const bool _showHandEyeFullscreenEntry = true;
const bool _showJoystickHandEyeFullscreenEntry = true;

class _HandEyeRoundResult {
  const _HandEyeRoundResult({
    required this.success,
    required this.taps,
    required this.requiredTaps,
    required this.blankTaps,
    required this.distractorTaps,
    required this.visibleFor,
    required this.firstReaction,
    required this.completionLatency,
  });

  final bool success;
  final int taps;
  final int requiredTaps;
  final int blankTaps;
  final int distractorTaps;
  final Duration visibleFor;
  final Duration? firstReaction;
  final Duration? completionLatency;
}

class _HandEyeDistractorTarget {
  const _HandEyeDistractorTarget({
    required this.start,
    required this.end,
    required this.wave,
    required this.diameter,
    this.colorBlend = 0.48,
  });

  final Offset start;
  final Offset end;
  final double wave;
  final double diameter;
  final double colorBlend;
}

class _HumanTestViewSignal extends ChangeNotifier {
  void markNeedsBuild() {
    notifyListeners();
  }
}

class HandEyeCoordinationTestPage extends StatelessWidget {
  const HandEyeCoordinationTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(
        i18n,
        zh: '手眼协调测试',
        en: 'Hand-eye coordination',
        ja: 'Hand-eye coordination',
        de: 'Hand-eye coordination',
        fr: 'Coordination des yeux de la main',
        es: 'Coordinación de la mano-ojo',
        ru: 'Координация рук и глаз',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '目标会在随机时间与位置出现、快速移动并消失；在消失前按要求点击命中。',
        en: 'Targets appear at random times and positions, move quickly, then vanish. Tap enough times before they disappear.',
        ja: 'Targets appear at random times and positions, move quickly, then vanish. Tap enough times before they disappear.',
        de: 'Targets appear at random times and positions, move quickly, then vanish. Tap enough times before they disappear.',
        fr: 'Les cibles apparaissent au hasard, se déplacent rapidement, puis disparaissent. Tapez assez de fois avant qu\'ils disparaissent.',
        es: 'Los objetivos aparecen en tiempos y posiciones al azar, moverse rápidamente, luego desaparecer. Toca bastantes veces antes de desaparecer.',
        ru: 'Цели появляются в случайное время и позиции, двигаются быстро, а затем исчезают. Нажмите достаточно раз, прежде чем они исчезнут.',
      ),
      accent: const Color(0xFFB55D42),
      icon: Icons.center_focus_strong_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：开始后等待目标出现',
        en: 'Next: start and wait for the target',
        ja: 'Next: start and wait for the target',
        de: 'Next: start and wait for the target',
        fr: 'Suivant: démarrer et attendre la cible',
        es: 'Siguiente: comenzar y esperar el objetivo',
        ru: 'Следующий: Начать и ждать цели',
      ),
      child: const _HandEyeCoordinationCard(),
    );
  }
}

class _HandEyeCoordinationCard extends StatefulWidget {
  const _HandEyeCoordinationCard();

  @override
  State<_HandEyeCoordinationCard> createState() =>
      _HandEyeCoordinationCardState();
}

class _HandEyeCoordinationCardState extends State<_HandEyeCoordinationCard>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFFB55D42);

  final math.Random _random = math.Random();
  final Stopwatch _targetStopwatch = Stopwatch();
  final _HumanTestViewSignal _viewSignal = _HumanTestViewSignal();
  late final AnimationController _targetController;
  late final TextEditingController _roundCountController;
  late final TextEditingController _displayMsController;
  late final TextEditingController _movementAmplitudeController;
  late final TextEditingController _movementSpeedController;
  late final TextEditingController _requiredTapsController;
  late final TextEditingController _targetDiameterController;
  late final TextEditingController _distractorChanceController;
  late final TextEditingController _distractorCountController;

  Timer? _spawnTimer;
  Timer? _visibleTimer;
  DateTime? _spawnScheduledAt;
  Duration? _spawnWaitDuration;
  Duration? _pausedSpawnRemaining;
  Duration? _pausedVisibleRemaining;
  Duration _targetElapsedBase = Duration.zero;
  double? _pausedMotionValue;
  int _token = 0;
  bool _paused = false;
  bool _reportDialogOpen = false;

  int _roundCount = 12;
  int _displayMs = 850;
  _HandEyeVisibleMode _visibleMode = _HandEyeVisibleMode.timed;
  double _movementAmplitude = 0.68;
  double _movementSpeed = 1.65;
  int _requiredTaps = 1;
  double _targetDiameter = 42;
  bool _distractorEnabled = false;
  double _distractorChance = 0.35;
  int _distractorCount = 2;

  _HandEyePhase _phase = _HandEyePhase.idle;
  Offset _targetStart = const Offset(0.5, 0.5);
  Offset _targetEnd = const Offset(0.5, 0.5);
  double _wave = 0;
  int _targetTaps = 0;
  int _roundBlankTaps = 0;
  int _roundDistractorTaps = 0;
  int _totalBlankTaps = 0;
  int _totalDistractorTaps = 0;
  Duration? _firstReaction;
  List<_HandEyeDistractorTarget> _distractors =
      const <_HandEyeDistractorTarget>[];
  final List<_HandEyeRoundResult> _results = <_HandEyeRoundResult>[];

  bool get _inSession =>
      _phase == _HandEyePhase.waiting || _phase == _HandEyePhase.visible;

  bool get _active => _inSession && !_paused;

  bool get _settingsLocked => _inSession;

  Duration get _targetElapsed => _targetElapsedBase + _targetStopwatch.elapsed;

  bool get _targetMotionEnabled => _movementAmplitude > 0 && _movementSpeed > 0;

  double get _hitRadius => math.max(14, _targetDiameter * 0.54);

  int get _successes => _results.where((item) => item.success).length;

  int get _missed => _results.where((item) => !item.success).length;

  Duration? get _averageReaction {
    final reactions = _results
        .where((item) => item.success && item.firstReaction != null)
        .map((item) => item.firstReaction!.inMilliseconds)
        .toList(growable: false);
    if (reactions.isEmpty) {
      return null;
    }
    final total = reactions.reduce((a, b) => a + b);
    return Duration(milliseconds: (total / reactions.length).round());
  }

  @override
  void initState() {
    super.initState();
    _roundCountController = TextEditingController(text: '$_roundCount');
    _displayMsController = TextEditingController(text: '$_displayMs');
    _movementAmplitudeController = TextEditingController(
      text: (_movementAmplitude * 100).round().toString(),
    );
    _movementSpeedController = TextEditingController(
      text: _movementSpeed.toStringAsFixed(1),
    );
    _requiredTapsController = TextEditingController(text: '$_requiredTaps');
    _targetDiameterController = TextEditingController(
      text: _targetDiameter.round().toString(),
    );
    _distractorChanceController = TextEditingController(
      text: (_distractorChance * 100).round().toString(),
    );
    _distractorCountController = TextEditingController(
      text: '$_distractorCount',
    );
    _targetController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _displayMs),
    )..addListener(_notifyView);
  }

  @override
  void dispose() {
    _token += 1;
    _spawnTimer?.cancel();
    _visibleTimer?.cancel();
    _targetController.removeListener(_notifyView);
    _targetController.dispose();
    _viewSignal.dispose();
    _roundCountController.dispose();
    _displayMsController.dispose();
    _movementAmplitudeController.dispose();
    _movementSpeedController.dispose();
    _requiredTapsController.dispose();
    _targetDiameterController.dispose();
    _distractorChanceController.dispose();
    _distractorCountController.dispose();
    super.dispose();
  }

  void _notifyView() {
    _viewSignal.markNeedsBuild();
  }

  void _updateView(VoidCallback fn) {
    setState(fn);
    _notifyView();
  }

  void _start() {
    _token += 1;
    _spawnTimer?.cancel();
    _visibleTimer?.cancel();
    _spawnScheduledAt = null;
    _spawnWaitDuration = null;
    _pausedSpawnRemaining = null;
    _pausedVisibleRemaining = null;
    _pausedMotionValue = null;
    _targetElapsedBase = Duration.zero;
    _targetController.stop();
    _notifyView();
    _targetStopwatch
      ..stop()
      ..reset();
    _updateView(() {
      _paused = false;
      _phase = _HandEyePhase.waiting;
      _targetTaps = 0;
      _roundBlankTaps = 0;
      _roundDistractorTaps = 0;
      _totalBlankTaps = 0;
      _totalDistractorTaps = 0;
      _firstReaction = null;
      _distractors = const <_HandEyeDistractorTarget>[];
      _results.clear();
    });
    _scheduleNextTarget();
  }

  void _reset() {
    _token += 1;
    _spawnTimer?.cancel();
    _visibleTimer?.cancel();
    _spawnScheduledAt = null;
    _spawnWaitDuration = null;
    _pausedSpawnRemaining = null;
    _pausedVisibleRemaining = null;
    _pausedMotionValue = null;
    _targetElapsedBase = Duration.zero;
    _targetController.stop();
    _notifyView();
    _targetStopwatch
      ..stop()
      ..reset();
    _updateView(() {
      _paused = false;
      _phase = _HandEyePhase.idle;
      _targetTaps = 0;
      _roundBlankTaps = 0;
      _roundDistractorTaps = 0;
      _totalBlankTaps = 0;
      _totalDistractorTaps = 0;
      _firstReaction = null;
      _distractors = const <_HandEyeDistractorTarget>[];
      _results.clear();
    });
  }

  void _scheduleNextTarget({Duration? waitOverride}) {
    if (!mounted || _paused || _phase == _HandEyePhase.done) {
      return;
    }
    if (_results.length >= _roundCount) {
      _updateView(() => _phase = _HandEyePhase.done);
      _showCompletionReport();
      return;
    }
    final token = _token;
    final wait =
        waitOverride ?? Duration(milliseconds: 280 + _random.nextInt(950));
    _spawnScheduledAt = DateTime.now();
    _spawnWaitDuration = wait;
    _updateView(() => _phase = _HandEyePhase.waiting);
    _spawnTimer = Timer(wait, () {
      if (!mounted || token != _token || _phase != _HandEyePhase.waiting) {
        return;
      }
      _spawnScheduledAt = null;
      _spawnWaitDuration = null;
      _showTarget();
    });
  }

  Offset _randomNormalizedPoint({double edge = 0.12}) {
    return Offset(
      edge + _random.nextDouble() * (1 - edge * 2),
      edge + _random.nextDouble() * (1 - edge * 2),
    );
  }

  Offset _nearbyNormalizedPoint(Offset origin, double radius, double edge) {
    final angle = _random.nextDouble() * math.pi * 2;
    final distance = radius * (0.42 + _random.nextDouble() * 0.58);
    return Offset(
      (origin.dx + math.cos(angle) * distance).clamp(edge, 1 - edge),
      (origin.dy + math.sin(angle) * distance).clamp(edge, 1 - edge),
    );
  }

  _HandEyeDistractorTarget _createDistractorTarget(
    double targetEdge, {
    required Offset targetStart,
    required Offset targetEnd,
  }) {
    final followsTarget = _random.nextDouble() < 0.72;
    final start = followsTarget
        ? _nearbyNormalizedPoint(targetStart, 0.18, targetEdge)
        : _randomNormalizedPoint(edge: targetEdge);
    var end = followsTarget
        ? _nearbyNormalizedPoint(targetEnd, 0.18, targetEdge)
        : start;
    var wave = 0.0;
    if (_targetMotionEnabled) {
      final angle = _random.nextDouble() * math.pi * 2;
      final distance =
          _movementAmplitude *
          (followsTarget ? 0.28 : 0.22 + _movementSpeed * 0.06) *
          (0.55 + _random.nextDouble() * 0.45);
      end = Offset(
        (start.dx + math.cos(angle) * distance).clamp(
          targetEdge,
          1 - targetEdge,
        ),
        (start.dy + math.sin(angle) * distance).clamp(
          targetEdge,
          1 - targetEdge,
        ),
      );
      if (followsTarget) {
        end = Offset.lerp(end, targetEnd, 0.62) ?? end;
      }
      wave =
          _movementAmplitude * _movementSpeed * (followsTarget ? 0.026 : 0.018);
    }
    return _HandEyeDistractorTarget(
      start: start,
      end: end,
      wave: wave,
      diameter: (_targetDiameter * (0.76 + _random.nextDouble() * 0.30)).clamp(
        18,
        72,
      ),
      colorBlend: 0.26 + _random.nextDouble() * 0.28,
    );
  }

  List<_HandEyeDistractorTarget> _spawnDistractors(
    double targetEdge, {
    required Offset targetStart,
    required Offset targetEnd,
  }) {
    if (!_distractorEnabled || _random.nextDouble() > _distractorChance) {
      return const <_HandEyeDistractorTarget>[];
    }
    final count = 1 + _random.nextInt(math.max(1, _distractorCount));
    return List<_HandEyeDistractorTarget>.generate(
      count,
      (_) => _createDistractorTarget(
        targetEdge,
        targetStart: targetStart,
        targetEnd: targetEnd,
      ),
    );
  }

  void _showTarget() {
    _spawnScheduledAt = null;
    _spawnWaitDuration = null;
    _pausedSpawnRemaining = null;
    _pausedVisibleRemaining = null;
    _pausedMotionValue = null;
    _targetElapsedBase = Duration.zero;
    final randomAmplitude = 0.72 + _random.nextDouble() * 0.62;
    final randomSpeed = 0.78 + _random.nextDouble() * 0.52;
    final targetEdge = (_targetDiameter / 320).clamp(0.07, 0.16);
    final start = _randomNormalizedPoint(edge: targetEdge);
    var end = start;
    var wave = 0.0;
    if (_targetMotionEnabled) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speedBoost = 0.80 + _movementSpeed * 0.42;
      final distance =
          _movementAmplitude *
          (0.48 + _movementSpeed * 0.13) *
          randomAmplitude *
          randomSpeed *
          speedBoost;
      end = Offset(
        (start.dx + math.cos(angle) * distance).clamp(
          targetEdge,
          1 - targetEdge,
        ),
        (start.dy + math.sin(angle) * distance).clamp(
          targetEdge,
          1 - targetEdge,
        ),
      );
      wave =
          _movementAmplitude *
          _movementSpeed *
          (0.032 + _random.nextDouble() * 0.068);
    }
    final motionDuration = _motionDuration();
    _targetController.duration = motionDuration;
    if (_targetMotionEnabled) {
      _targetController.repeat(reverse: true);
    } else {
      _targetController.forward(from: 0);
    }
    _targetStopwatch
      ..reset()
      ..start();
    final distractors = _spawnDistractors(
      targetEdge,
      targetStart: start,
      targetEnd: end,
    );
    _updateView(() {
      _paused = false;
      _phase = _HandEyePhase.visible;
      _targetStart = start;
      _targetEnd = end;
      _wave = wave;
      _targetTaps = 0;
      _roundBlankTaps = 0;
      _roundDistractorTaps = 0;
      _firstReaction = null;
      _distractors = distractors;
    });
    if (_visibleMode == _HandEyeVisibleMode.timed) {
      _scheduleVisibleTimeout(Duration(milliseconds: _displayMs));
    }
  }

  void _scheduleVisibleTimeout(Duration duration) {
    final token = _token;
    final remaining = duration <= Duration.zero
        ? const Duration(milliseconds: 1)
        : duration;
    _visibleTimer?.cancel();
    _visibleTimer = Timer(remaining, () {
      if (!mounted ||
          token != _token ||
          _paused ||
          _phase != _HandEyePhase.visible) {
        return;
      }
      _completeTarget(success: false);
    });
  }

  Duration _motionDuration() {
    if (_movementSpeed <= 0) {
      return Duration(milliseconds: _displayMs);
    }
    final speedFactor = 0.45 + _movementSpeed * 0.72;
    final millis = (_displayMs / speedFactor).round().clamp(120, 1600);
    return Duration(milliseconds: millis);
  }

  double _targetMotionValue() {
    if (_paused && _phase == _HandEyePhase.visible) {
      return _pausedMotionValue ?? _targetController.value;
    }
    if (_phase != _HandEyePhase.visible || !_targetStopwatch.isRunning) {
      return _targetController.value;
    }
    final durationMicros = math.max(1, _motionDuration().inMicroseconds);
    final elapsedMicros = _targetElapsed.inMicroseconds;
    if (!_targetMotionEnabled) {
      return (elapsedMicros / durationMicros).clamp(0.0, 1.0).toDouble();
    }
    final cycle = (elapsedMicros % (durationMicros * 2)) / durationMicros;
    return cycle <= 1 ? cycle.toDouble() : (2 - cycle).toDouble();
  }

  void _pauseTargetMotionDriverForFullscreen() {
    _targetController.stop();
  }

  void _resumeTargetMotionDriverAfterFullscreen() {
    if (!mounted || _paused || _phase != _HandEyePhase.visible) {
      return;
    }
    _targetController.duration = _motionDuration();
    if (_targetMotionEnabled) {
      _targetController.repeat(reverse: true);
    } else {
      _targetController.forward(from: _targetMotionValue());
    }
  }

  Offset _targetCenter(Size size) {
    return _movingCenter(
      size: size,
      start: _targetStart,
      end: _targetEnd,
      waveAmount: _wave,
      diameter: _targetDiameter,
    );
  }

  Offset _distractorCenter(Size size, _HandEyeDistractorTarget target) {
    return _movingCenter(
      size: size,
      start: target.start,
      end: target.end,
      waveAmount: target.wave,
      diameter: target.diameter,
    );
  }

  Offset _movingCenter({
    required Size size,
    required Offset start,
    required Offset end,
    required double waveAmount,
    required double diameter,
  }) {
    final t = Curves.easeInOutSine.transform(_targetMotionValue());
    final line = Offset.lerp(start, end, t) ?? start;
    final direction = end - start;
    final length = direction.distance;
    final normal = length <= 0.001
        ? Offset.zero
        : Offset(-direction.dy / length, direction.dx / length);
    final wave = normal * math.sin(t * math.pi * 2) * waveAmount;
    final xEdge = (diameter / 2 / size.width).clamp(0.04, 0.18);
    final yEdge = (diameter / 2 / size.height).clamp(0.04, 0.18);
    final normalized = Offset(
      (line.dx + wave.dx).clamp(xEdge, 1 - xEdge),
      (line.dy + wave.dy).clamp(yEdge, 1 - yEdge),
    );
    return Offset(normalized.dx * size.width, normalized.dy * size.height);
  }

  void _completeTarget({required bool success}) {
    _visibleTimer?.cancel();
    _spawnScheduledAt = null;
    _spawnWaitDuration = null;
    _pausedSpawnRemaining = null;
    _pausedVisibleRemaining = null;
    _pausedMotionValue = null;
    _targetController.stop();
    _notifyView();
    final visibleFor = _targetElapsed;
    _targetStopwatch.stop();
    _targetElapsedBase = visibleFor;
    final result = _HandEyeRoundResult(
      success: success,
      taps: _targetTaps,
      requiredTaps: _requiredTaps,
      blankTaps: _roundBlankTaps,
      distractorTaps: _roundDistractorTaps,
      visibleFor: visibleFor,
      firstReaction: _firstReaction,
      completionLatency: success ? visibleFor : null,
    );
    var done = false;
    _updateView(() {
      _paused = false;
      _results.add(result);
      _phase = _results.length >= _roundCount
          ? _HandEyePhase.done
          : _HandEyePhase.waiting;
      _distractors = const <_HandEyeDistractorTarget>[];
      done = _phase == _HandEyePhase.done;
    });
    if (!done) {
      _scheduleNextTarget();
    } else {
      _showCompletionReport();
    }
  }

  void _pause() {
    if (!_active) {
      return;
    }
    _token += 1;
    _spawnTimer?.cancel();
    _visibleTimer?.cancel();
    Duration? spawnRemaining;
    Duration? visibleRemaining;
    double? motionValue;
    if (_phase == _HandEyePhase.waiting) {
      final scheduledAt = _spawnScheduledAt;
      final waitDuration = _spawnWaitDuration;
      if (scheduledAt != null && waitDuration != null) {
        spawnRemaining = waitDuration - DateTime.now().difference(scheduledAt);
      }
      if (spawnRemaining == null ||
          spawnRemaining <= Duration.zero ||
          spawnRemaining > (_spawnWaitDuration ?? spawnRemaining)) {
        spawnRemaining = const Duration(milliseconds: 160);
      }
    } else if (_phase == _HandEyePhase.visible) {
      motionValue = _targetMotionValue();
      _targetElapsedBase = _targetElapsed;
      _targetStopwatch
        ..stop()
        ..reset();
      if (_visibleMode == _HandEyeVisibleMode.timed) {
        visibleRemaining =
            Duration(milliseconds: _displayMs) - _targetElapsedBase;
        if (visibleRemaining <= Duration.zero) {
          visibleRemaining = const Duration(milliseconds: 1);
        }
      }
      _targetController.stop();
    }
    _updateView(() {
      _paused = true;
      _pausedSpawnRemaining = spawnRemaining;
      _pausedVisibleRemaining = visibleRemaining;
      _pausedMotionValue = motionValue;
    });
  }

  void _resume() {
    if (!_paused || !_inSession) {
      return;
    }
    _token += 1;
    if (_phase == _HandEyePhase.waiting) {
      final remaining =
          _pausedSpawnRemaining ?? const Duration(milliseconds: 160);
      _updateView(() {
        _paused = false;
        _pausedSpawnRemaining = null;
      });
      _scheduleNextTarget(waitOverride: remaining);
      return;
    }
    if (_phase == _HandEyePhase.visible) {
      _targetController.duration = _motionDuration();
      _targetStopwatch
        ..reset()
        ..start();
      if (_targetMotionEnabled) {
        _targetController.repeat(reverse: true);
      } else {
        _targetController.forward(from: _pausedMotionValue ?? 0);
      }
      final visibleRemaining = _pausedVisibleRemaining;
      _updateView(() {
        _paused = false;
        _pausedVisibleRemaining = null;
        _pausedMotionValue = null;
      });
      if (_visibleMode == _HandEyeVisibleMode.timed &&
          visibleRemaining != null) {
        _scheduleVisibleTimeout(visibleRemaining);
      }
    }
  }

  void _handlePrimaryAction() {
    if (_paused) {
      _resume();
      return;
    }
    if (_active) {
      _pause();
      return;
    }
    _start();
  }

  void _handleStageTap(Size size, Offset localPosition) {
    if (!_active) {
      return;
    }
    if (_phase != _HandEyePhase.visible) {
      _updateView(() => _totalBlankTaps += 1);
      return;
    }
    final center = _targetCenter(size);
    if ((localPosition - center).distance <= _hitRadius) {
      _firstReaction ??= _targetElapsed;
      _targetTaps += 1;
      if (_targetTaps >= _requiredTaps) {
        _completeTarget(success: true);
      } else {
        _updateView(() {});
      }
      return;
    }
    for (final distractor in _distractors) {
      final distractorCenter = _distractorCenter(size, distractor);
      final radius = math.max(12, distractor.diameter * 0.52);
      if ((localPosition - distractorCenter).distance <= radius) {
        _updateView(() {
          _roundDistractorTaps += 1;
          _totalDistractorTaps += 1;
        });
        return;
      }
    }
    _updateView(() {
      _roundBlankTaps += 1;
      _totalBlankTaps += 1;
    });
  }

  void _setRoundCount(double value) {
    final next = value.round().clamp(1, 200);
    _updateView(() => _roundCount = next);
    _roundCountController.text = '$next';
  }

  void _setDisplayMs(double value) {
    final next = value.round().clamp(80, 10000);
    _updateView(() => _displayMs = next);
    _displayMsController.text = '$next';
  }

  void _setVisibleMode(_HandEyeVisibleMode value) {
    _updateView(() => _visibleMode = value);
  }

  void _setMovementAmplitude(double value) {
    final next = value.clamp(0.0, 2.5).toDouble();
    _updateView(() => _movementAmplitude = next);
    _movementAmplitudeController.text = '${(next * 100).round()}';
  }

  void _setMovementSpeed(double value) {
    final next = value.clamp(0.0, 8.0).toDouble();
    _updateView(() => _movementSpeed = next);
    _movementSpeedController.text = next.toStringAsFixed(1);
  }

  void _setRequiredTaps(double value) {
    final next = value.round().clamp(1, 20);
    _updateView(() => _requiredTaps = next);
    _requiredTapsController.text = '$next';
  }

  void _setTargetDiameter(double value) {
    final next = value.clamp(12.0, 120.0).toDouble();
    _updateView(() => _targetDiameter = next);
    _targetDiameterController.text = '${next.round()}';
  }

  void _setDistractorEnabled(bool value) {
    _updateView(() => _distractorEnabled = value);
  }

  void _setDistractorChance(double value) {
    final next = value.clamp(0.0, 1.0).toDouble();
    _updateView(() => _distractorChance = next);
    _distractorChanceController.text = '${(next * 100).round()}';
  }

  void _setDistractorCount(double value) {
    final next = value.round().clamp(1, 8);
    _updateView(() => _distractorCount = next);
    _distractorCountController.text = '$next';
  }

  void _applyIntInput({
    required TextEditingController controller,
    required int min,
    required int max,
    required ValueChanged<double> apply,
  }) {
    final parsed = int.tryParse(controller.text.trim());
    if (parsed == null) {
      return;
    }
    apply(parsed.clamp(min, max).toDouble());
  }

  void _applyDoubleInput({
    required TextEditingController controller,
    required double min,
    required double max,
    required ValueChanged<double> apply,
    double scale = 1,
  }) {
    final parsed = double.tryParse(controller.text.trim());
    if (parsed == null) {
      return;
    }
    apply((parsed / scale).clamp(min, max).toDouble());
  }

  String _visibleModeLabel(AppI18n i18n, _HandEyeVisibleMode mode) {
    return switch (mode) {
      _HandEyeVisibleMode.timed => pickUiText(
        i18n,
        zh: '按时消失',
        en: 'Timed vanish',
        ja: 'Timed vanish',
        de: 'Timed vanish',
        fr: 'Disparition dans le temps',
        es: 'Hora de desaparecer',
        ru: 'Исчезновение по времени',
      ),
      _HandEyeVisibleMode.untilTaps => pickUiText(
        i18n,
        zh: '点满才消失',
        en: 'Until taps complete',
        ja: 'Until taps complete',
        de: 'Until taps complete',
        fr: 'Jusqu\'à ce que les robinets soient terminés',
        es: 'Hasta que terminen los tapones',
        ru: 'Пока краны не закончатся',
      ),
    };
  }

  Future<void> _openFullscreen() async {
    await _enterHumanTestLandscapeFullscreen();
    if (!mounted) {
      await _exitHumanTestFullscreen();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _HandEyeFullscreenView(state: this),
      ),
    );
    await _exitHumanTestFullscreen();
    if (mounted) {
      _updateView(() {});
    }
  }

  void _showCompletionReport() {
    if (!mounted || _reportDialogOpen || _results.isEmpty) {
      return;
    }
    _reportDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _reportDialogOpen = false;
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (_) => _HandEyeCompletionReportDialog(
          results: List<_HandEyeRoundResult>.unmodifiable(_results),
          roundCount: _roundCount,
          totalBlankTaps: _totalBlankTaps,
          totalDistractorTaps: _totalDistractorTaps,
          accent: _accent,
        ),
      );
      _reportDialogOpen = false;
    });
  }

  String _phaseText(AppI18n i18n) {
    if (_paused) {
      return pickUiText(
        i18n,
        zh: '已暂停，点击继续恢复本轮测试。',
        en: 'Paused. Press Continue to resume this round.',
        ja: 'Paused. Press Continue to resume this round.',
        de: 'Paused. Press Continue to resume this round.',
        fr: 'En pause. Appuyez sur Continuer pour reprendre ce tour.',
        es: 'Pausado. Pulsa Continuar para reanudar esta ronda.',
        ru: 'Пауза. Нажмите «Продолжить», чтобы возобновить раунд.',
      );
    }
    return switch (_phase) {
      _HandEyePhase.idle => pickUiText(
        i18n,
        zh: '点击开始后，目标会在随机时间出现。',
        en: 'Press Start. Targets will appear after random delays.',
        ja: 'Press Start. Targets will appear after random delays.',
        de: 'Press Start. Targets will appear after random delays.',
        fr: 'Appuyez sur Démarrer. Des cibles apparaîtront après des retards aléatoires.',
        es: 'Press Start. Los objetivos aparecerán después de demoras aleatorias.',
        ru: 'Нажмите Старт. Цели появятся после случайных задержек.',
      ),
      _HandEyePhase.waiting => pickUiText(
        i18n,
        zh: '等待目标出现',
        en: 'Waiting for target',
        ja: 'Waiting for target',
        de: 'Waiting for target',
        fr: 'Attendre la cible',
        es: 'Esperando el objetivo',
        ru: 'В ожидании цели',
      ),
      _HandEyePhase.visible => pickUiText(
        i18n,
        zh: '命中目标：$_targetTaps/$_requiredTaps',
        en: 'Hit target: $_targetTaps/$_requiredTaps',
        ja: 'Hit target: $_targetTaps/$_requiredTaps',
        de: 'Hit target: $_targetTaps/$_requiredTaps',
        fr: 'Affichage de la cible : $_targetTaps/$_requiredTaps',
        es: 'Meta de éxito:',
        ru: 'Ударная цель: $_targetTaps/$_requiredTaps',
      ),
      _HandEyePhase.done => pickUiText(
        i18n,
        zh: '测试完成，可重置或再次开始。',
        en: 'Test complete. Reset or start again.',
        ja: 'Test complete. Reset or start again.',
        de: 'Test complete. Reset or start again.',
        fr: 'Essai terminé. Réinitialisez ou recommencez.',
        es: 'Prueba completa. Reiniciar o empezar de nuevo.',
        ru: 'Тест завершен. Перезагрузить или начать заново.',
      ),
    };
  }

  String _primaryActionLabel(AppI18n i18n) {
    if (_paused) {
      return pickUiText(
        i18n,
        zh: '继续',
        en: 'Continue',
        ja: 'Continue',
        de: 'Continue',
        fr: 'Continuer',
        es: 'Continuar',
        ru: 'Продолжить',
      );
    }
    return switch (_phase) {
      _HandEyePhase.idle => pickUiText(
        i18n,
        zh: '开始',
        en: 'Start',
        ja: 'Start',
        de: 'Start',
        fr: 'Démarrer',
        es: 'Comienzo',
        ru: 'Начинать',
      ),
      _HandEyePhase.waiting || _HandEyePhase.visible => pickUiText(
        i18n,
        zh: '暂停',
        en: 'Pause',
        ja: 'Pause',
        de: 'Pause',
        fr: 'Pause',
        es: 'Pausa',
        ru: 'Пауза',
      ),
      _HandEyePhase.done => pickUiText(
        i18n,
        zh: '重新开始',
        en: 'Restart',
        ja: 'Restart',
        de: 'Restart',
        fr: 'Redémarrer',
        es: 'Restart',
        ru: 'Перезапустить',
      ),
    };
  }

  IconData _primaryActionIcon() {
    if (_paused) {
      return Icons.play_arrow_rounded;
    }
    return switch (_phase) {
      _HandEyePhase.idle => Icons.play_arrow_rounded,
      _HandEyePhase.waiting || _HandEyePhase.visible => Icons.pause_rounded,
      _HandEyePhase.done => Icons.restart_alt_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final averageReaction = _averageReaction;
    final attempted = _results.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(
                i18n,
                zh: '轮次',
                en: 'Rounds',
                ja: 'Rounds',
                de: 'Rounds',
                fr: 'Rondes',
                es: 'Rondas',
                ru: 'Круги',
              ),
              '$attempted/$_roundCount',
            ),
            (
              pickUiText(
                i18n,
                zh: '成功',
                en: 'Success',
                ja: 'Success',
                de: 'Success',
                fr: 'Succès',
                es: 'Éxito',
                ru: 'Успех',
              ),
              '$_successes',
            ),
            (
              pickUiText(
                i18n,
                zh: '漏掉',
                en: 'Missed',
                ja: 'Missed',
                de: 'Missed',
                fr: 'Manque',
                es: 'Desaparecido',
                ru: 'Пропавший',
              ),
              '$_missed',
            ),
            (
              pickUiText(
                i18n,
                zh: '点空',
                en: 'Blanks',
                ja: 'ブランク',
                de: 'Blanks',
                fr: 'Blancs',
                es: 'Blanks',
                ru: 'бланки',
              ),
              '$_totalBlankTaps',
            ),
            (
              pickUiText(
                i18n,
                zh: '假目标',
                en: 'False targets',
                ja: 'False targets',
                de: 'False targets',
                fr: 'Faux objectifs',
                es: 'Objetivos falsos',
                ru: 'Ложные цели',
              ),
              '$_totalDistractorTaps',
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
              averageReaction == null
                  ? '-'
                  : _formatMilliseconds(averageReaction.inMilliseconds),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: pickUiText(
            i18n,
            zh: '目标设置',
            en: 'Target settings',
            ja: 'Target settings',
            de: 'Target settings',
            fr: 'Paramètres de la cible',
            es: 'Ajustes de objetivos',
            ru: 'Целевые настройки',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '轮数、显示时长、移动强度、目标大小和命中点击数',
            en: 'Rounds, visible time, movement strength, target size, and required taps',
            ja: 'Rounds, visible time, movement strength, target size, and required taps',
            de: 'Rounds, visible time, movement strength, target size, and required taps',
            fr: 'Ronds, temps visible, force du mouvement, taille de la cible et robinets requis',
            es: 'Rondas, tiempo visible, fuerza de movimiento, tamaño de objetivo y grifos requeridos',
            ru: 'Круги, видимое время, сила движения, размер цели и необходимые краны',
          ),
          child: _buildTargetSettings(i18n),
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: pickUiText(
            i18n,
            zh: '高阶干扰设置',
            en: 'Advanced interference',
            ja: '高度な干渉',
            de: 'Advanced interference',
            fr: 'Advanced interference',
            es: 'Interferencia avanzada',
            ru: 'Расширенное вмешательство',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '默认关闭：随机等待后可同时出现一个或多个假目标，颜色与真目标区分。',
            en: 'Off by default: one or more color-coded false targets may appear with the real target.',
            ja: 'Off by default: one or more color-coded false targets may appear with the real target.',
            de: 'Off by default: one or more color-coded false targets may appear with the real target.',
            fr: 'Off par défaut : une ou plusieurs cibles fausses codées en couleur peuvent apparaître avec la cible réelle.',
            es: 'De forma predeterminada: uno o más blancos falsos codificados por colores pueden aparecer con el objetivo real.',
            ru: 'Выключено по умолчанию: одна или несколько цветных ложных целей могут появиться с реальной целью.',
          ),
          child: _buildDistractorSettings(i18n),
        ),
        const SizedBox(height: 12),
        _HandEyePlayStage(
          state: this,
          heightForConstraints: (constraints) =>
              math.min(420, constraints.maxWidth * 0.88),
          fullscreen: false,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _HumanActionButton(
              key: const ValueKey<String>('hand_eye_primary_start_button'),
              label: _primaryActionLabel(i18n),
              icon: _primaryActionIcon(),
              onPressed: _handlePrimaryAction,
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
            ),
            if (_showHandEyeFullscreenEntry)
              OutlinedButton.icon(
                key: const ValueKey<String>('hand_eye_fullscreen_button'),
                onPressed: _openFullscreen,
                icon: const Icon(Icons.fullscreen_rounded),
                label: Text(
                  pickUiText(
                    i18n,
                    zh: '全屏',
                    en: 'Fullscreen',
                    ja: 'Fullscreen',
                    de: 'Fullscreen',
                    fr: 'Plein écran',
                    es: 'Pantalla completa',
                    ru: 'Полный экран',
                  ),
                ),
              ),
          ],
        ),
        if (_results.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _HandEyeResultPanel(results: _results, accent: _accent),
        ],
      ],
    );
  }
}

part of 'toolbox_human_tests.dart';

class JoystickHandEyeCoordinationTestPage extends StatelessWidget {
  const JoystickHandEyeCoordinationTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_hand_eye_joystick.joystick_coordination_128f3b',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_hand_eye_joystick.move_a_crosshair_with_a_virtual_joystick_like_a_mobile_g_bd435e',
      ),
      accent: const Color(0xFF8A6849),
      icon: Icons.gamepad_rounded,
      status: i18n.t(
        'inline.ui.pages.toolbox_human_tests_hand_eye_joystick.next_start_steer_and_fire_4a7f0d',
      ),
      child: const _JoystickHandEyeCard(),
    );
  }
}

class _JoystickHandEyeCard extends StatefulWidget {
  const _JoystickHandEyeCard();

  @override
  State<_JoystickHandEyeCard> createState() => _JoystickHandEyeCardState();
}

class _JoystickHandEyeCardState extends State<_JoystickHandEyeCard>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFF8A6849);

  final math.Random _random = math.Random();
  final Stopwatch _sessionStopwatch = Stopwatch();
  final Stopwatch _targetStopwatch = Stopwatch();
  final _HumanTestViewSignal _viewSignal = _HumanTestViewSignal();
  late final AnimationController _motionController;
  late final TextEditingController _durationController;
  late final TextEditingController _targetGoalController;
  late final TextEditingController _crosshairSpeedController;
  late final TextEditingController _joystickAccelerationController;
  late final TextEditingController _targetDiameterController;
  late final TextEditingController _targetMovementRangeController;
  late final TextEditingController _targetMovementSpeedController;
  late final TextEditingController _distractorChanceController;
  late final TextEditingController _distractorCountController;

  Timer? _spawnTimer;
  Timer? _sessionTimer;
  Duration? _lastTick;
  int _token = 0;
  bool _reportDialogOpen = false;
  bool _fullscreenMotionActive = false;

  _JoystickTestMode _mode = _JoystickTestMode.timed;
  int _durationSeconds = 30;
  int _targetGoal = 20;
  double _crosshairSpeed = 1.25;
  double _joystickAcceleration = 1.35;
  double _targetDiameter = 54;
  bool _targetMovementEnabled = false;
  double _targetMovementRange = 0.35;
  double _targetMovementSpeed = 1.2;
  bool _distractorEnabled = false;
  double _distractorChance = 0.30;
  int _distractorCount = 2;
  bool _randomRespawnDelay = false;

  bool _running = false;
  bool _done = false;
  bool _targetActive = false;
  bool _waitingTarget = false;
  int _remainingTenths = 300;
  int _hits = 0;
  int _shotsOff = 0;
  int _falseTargetShots = 0;
  Offset _crosshair = const Offset(0.5, 0.5);
  Offset _joystickVector = Offset.zero;
  Offset _target = const Offset(0.5, 0.5);
  Offset _targetStart = const Offset(0.5, 0.5);
  Offset _targetEnd = const Offset(0.5, 0.5);
  double _targetWave = 0;
  List<_HandEyeDistractorTarget> _distractors =
      const <_HandEyeDistractorTarget>[];
  Size _stageSize = const Size(320, 240);
  final List<Duration> _hitReactions = <Duration>[];

  bool get _settingsLocked => _running;

  int get _shots => _hits + _shotsOff;

  double get _hitRadius => math.max(10, _targetDiameter * 0.56);

  Duration? get _averageReaction {
    if (_hitReactions.isEmpty) {
      return null;
    }
    final total = _hitReactions
        .map((item) => item.inMilliseconds)
        .reduce((a, b) => a + b);
    return Duration(milliseconds: (total / _hitReactions.length).round());
  }

  @override
  void initState() {
    super.initState();
    _durationController = TextEditingController(text: '$_durationSeconds');
    _targetGoalController = TextEditingController(text: '$_targetGoal');
    _crosshairSpeedController = TextEditingController(
      text: _crosshairSpeed.toStringAsFixed(1),
    );
    _joystickAccelerationController = TextEditingController(
      text: _joystickAcceleration.toStringAsFixed(1),
    );
    _targetDiameterController = TextEditingController(
      text: _targetDiameter.round().toString(),
    );
    _targetMovementRangeController = TextEditingController(
      text: (_targetMovementRange * 100).round().toString(),
    );
    _targetMovementSpeedController = TextEditingController(
      text: _targetMovementSpeed.toStringAsFixed(1),
    );
    _distractorChanceController = TextEditingController(
      text: (_distractorChance * 100).round().toString(),
    );
    _distractorCountController = TextEditingController(
      text: '$_distractorCount',
    );
    _remainingTenths = _durationSeconds * 10;
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_tickCrosshair);
  }

  @override
  void dispose() {
    _token += 1;
    _spawnTimer?.cancel();
    _sessionTimer?.cancel();
    _motionController.dispose();
    _viewSignal.dispose();
    _durationController.dispose();
    _targetGoalController.dispose();
    _crosshairSpeedController.dispose();
    _joystickAccelerationController.dispose();
    _targetDiameterController.dispose();
    _targetMovementRangeController.dispose();
    _targetMovementSpeedController.dispose();
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
    _sessionTimer?.cancel();
    _motionController.stop();
    _notifyView();
    _sessionStopwatch
      ..reset()
      ..start();
    _targetStopwatch
      ..stop()
      ..reset();
    _updateView(() {
      _running = true;
      _done = false;
      _targetActive = false;
      _waitingTarget = false;
      _remainingTenths = _durationSeconds * 10;
      _hits = 0;
      _shotsOff = 0;
      _falseTargetShots = 0;
      _crosshair = const Offset(0.5, 0.5);
      _joystickVector = Offset.zero;
      _distractors = const <_HandEyeDistractorTarget>[];
      _hitReactions.clear();
    });
    _lastTick = null;
    if (!_fullscreenMotionActive) {
      _motionController.repeat();
    }
    if (_mode == _JoystickTestMode.timed) {
      _sessionTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted || !_running) {
          return;
        }
        final left = math.max(
          0,
          _durationSeconds * 10 -
              (_sessionStopwatch.elapsedMilliseconds / 100).floor(),
        );
        if (left <= 0) {
          _finish();
        } else {
          _updateView(() => _remainingTenths = left);
        }
      });
    }
    _scheduleTarget(forceImmediate: true);
  }

  void _finish() {
    _token += 1;
    _spawnTimer?.cancel();
    _sessionTimer?.cancel();
    _motionController.stop();
    _notifyView();
    _sessionStopwatch.stop();
    _targetStopwatch.stop();
    if (!mounted) {
      return;
    }
    _updateView(() {
      _running = false;
      _done = true;
      _targetActive = false;
      _waitingTarget = false;
      _joystickVector = Offset.zero;
      _distractors = const <_HandEyeDistractorTarget>[];
      if (_mode == _JoystickTestMode.timed) {
        _remainingTenths = 0;
      }
    });
    _showCompletionReport();
  }

  void _reset() {
    _token += 1;
    _spawnTimer?.cancel();
    _sessionTimer?.cancel();
    _motionController.stop();
    _notifyView();
    _sessionStopwatch
      ..stop()
      ..reset();
    _targetStopwatch
      ..stop()
      ..reset();
    _updateView(() {
      _running = false;
      _done = false;
      _targetActive = false;
      _waitingTarget = false;
      _remainingTenths = _durationSeconds * 10;
      _hits = 0;
      _shotsOff = 0;
      _falseTargetShots = 0;
      _crosshair = const Offset(0.5, 0.5);
      _joystickVector = Offset.zero;
      _distractors = const <_HandEyeDistractorTarget>[];
      _hitReactions.clear();
    });
  }

  void _scheduleTarget({bool forceImmediate = false}) {
    if (!_running) {
      return;
    }
    final immediate = forceImmediate || !_randomRespawnDelay;
    if (immediate) {
      _spawnTarget();
      return;
    }
    final token = _token;
    _updateView(() {
      _targetActive = false;
      _waitingTarget = true;
      _distractors = const <_HandEyeDistractorTarget>[];
    });
    _spawnTimer = Timer(Duration(milliseconds: 260 + _random.nextInt(980)), () {
      if (!mounted || token != _token || !_running) {
        return;
      }
      _spawnTarget();
    });
  }

  void _spawnTarget() {
    final targetEdge = _targetEdgeFraction();
    final start = Offset(
      targetEdge + _random.nextDouble() * (1 - targetEdge * 2),
      targetEdge + _random.nextDouble() * (1 - targetEdge * 2),
    );
    var end = start;
    var wave = 0.0;
    if (_targetMovementEnabled &&
        _targetMovementRange > 0 &&
        _targetMovementSpeed > 0) {
      final angle = _random.nextDouble() * math.pi * 2;
      final distance =
          _targetMovementRange *
          (0.34 + _targetMovementSpeed * 0.08) *
          (0.72 + _random.nextDouble() * 0.50);
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
      wave = _targetMovementRange * _targetMovementSpeed * 0.024;
    }
    _targetStopwatch
      ..reset()
      ..start();
    _updateView(() {
      _target = start;
      _targetStart = start;
      _targetEnd = end;
      _targetWave = wave;
      _targetActive = true;
      _waitingTarget = false;
      _distractors = _spawnDistractors(
        targetEdge,
        targetStart: start,
        targetEnd: end,
      );
    });
  }

  double _targetEdgeFraction() {
    if (!_fullscreenMotionActive) {
      return (_targetDiameter / 320).clamp(0.07, 0.18).toDouble();
    }
    final shortest = math.max(
      1.0,
      math.min(_stageSize.width, _stageSize.height),
    );
    return ((_targetDiameter / 2 + 18) / shortest).clamp(0.06, 0.22).toDouble();
  }

  Offset _nearbyNormalizedPoint(Offset origin, double radius, double edge) {
    final angle = _random.nextDouble() * math.pi * 2;
    final distance = radius * (0.36 + _random.nextDouble() * 0.64);
    return Offset(
      (origin.dx + math.cos(angle) * distance).clamp(edge, 1 - edge),
      (origin.dy + math.sin(angle) * distance).clamp(edge, 1 - edge),
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
    return List<_HandEyeDistractorTarget>.generate(count, (_) {
      final followsTarget = _random.nextDouble() < 0.78;
      final start = followsTarget
          ? _nearbyNormalizedPoint(targetStart, 0.17, targetEdge)
          : Offset(
              targetEdge + _random.nextDouble() * (1 - targetEdge * 2),
              targetEdge + _random.nextDouble() * (1 - targetEdge * 2),
            );
      var end = followsTarget
          ? _nearbyNormalizedPoint(targetEnd, 0.17, targetEdge)
          : start;
      var wave = 0.0;
      if (_targetMovementEnabled &&
          _targetMovementRange > 0 &&
          _targetMovementSpeed > 0) {
        final angle = _random.nextDouble() * math.pi * 2;
        final distance =
            _targetMovementRange *
            (0.20 + _targetMovementSpeed * 0.05) *
            (0.45 + _random.nextDouble() * 0.45);
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
          end = Offset.lerp(end, targetEnd, 0.58) ?? end;
        }
        wave =
            _targetMovementRange *
            _targetMovementSpeed *
            (followsTarget ? 0.024 : 0.014);
      }
      return _HandEyeDistractorTarget(
        start: start,
        end: end,
        wave: wave,
        diameter: (_targetDiameter * (0.78 + _random.nextDouble() * 0.28))
            .clamp(18, 92),
        colorBlend: 0.22 + _random.nextDouble() * 0.30,
      );
    });
  }

  void _tickCrosshair() {
    _tickCrosshairAt(_motionController.lastElapsedDuration);
  }

  void _tickCrosshairAt(Duration? elapsed, {bool allowPractice = false}) {
    final practiceOnly = !_running && allowPractice;
    if ((!_running && !practiceOnly) || elapsed == null) {
      _lastTick = elapsed;
      return;
    }
    final previous = _lastTick;
    _lastTick = elapsed;
    if (previous == null) {
      return;
    }
    final dt = (elapsed - previous).inMicroseconds / 1000000.0;
    if (dt <= 0) {
      return;
    }
    final shortest = math.max(
      1.0,
      math.min(_stageSize.width, _stageSize.height),
    );
    final input = _acceleratedJoystickVector();
    final pixelsPerSecond = shortest * (0.42 + _crosshairSpeed * 0.42);
    final dx = input.dx * pixelsPerSecond * dt / _stageSize.width;
    final dy = input.dy * pixelsPerSecond * dt / _stageSize.height;
    _updateView(() {
      if (_joystickVector.distance > 0.001) {
        _crosshair = Offset(
          (_crosshair.dx + dx).clamp(0.04, 0.96),
          (_crosshair.dy + dy).clamp(0.06, 0.94),
        );
      }
      if (_running) {
        _advanceMovingTarget(dt);
      }
    });
  }

  void _activateFullscreenMotionDriver() {
    _fullscreenMotionActive = true;
    _motionController.stop();
    _lastTick = null;
  }

  void _deactivateFullscreenMotionDriver() {
    _fullscreenMotionActive = false;
    _lastTick = null;
    if (_running && mounted) {
      _motionController.repeat();
    }
  }

  Offset _acceleratedJoystickVector() {
    final distance = _joystickVector.distance.clamp(0.0, 1.8);
    if (distance <= 0.001) {
      return Offset.zero;
    }
    final exponent = (2.2 - _joystickAcceleration * 0.32).clamp(0.55, 2.2);
    final boosted = math.pow(distance, exponent).toDouble().clamp(0.0, 2.1);
    return _joystickVector / distance * boosted;
  }

  void _advanceMovingTarget(double dt) {
    if (!_targetActive ||
        !_targetMovementEnabled ||
        _targetMovementRange <= 0 ||
        _targetMovementSpeed <= 0) {
      return;
    }
    final step = (dt * (0.32 + _targetMovementSpeed * 0.26)).clamp(0.0, 0.08);
    var next = Offset.lerp(_target, _targetEnd, step) ?? _target;
    final direction = _targetEnd - _targetStart;
    final length = direction.distance;
    if (length > 0.001 && _targetWave > 0) {
      final normal = Offset(-direction.dy / length, direction.dx / length);
      final phase = _sessionStopwatch.elapsedMilliseconds / 1000.0;
      next +=
          normal *
          math.sin(phase * math.pi * (0.8 + _targetMovementSpeed * 0.42)) *
          _targetWave *
          step;
    }
    final edge = _targetEdgeFraction();
    _target = Offset(
      next.dx.clamp(edge, 1 - edge),
      next.dy.clamp(edge, 1 - edge),
    );
    if ((_target - _targetEnd).distance < 0.018) {
      final previousEnd = _targetEnd;
      _targetEnd = _targetStart;
      _targetStart = previousEnd;
    }
  }

  void _fire() {
    if (!_running) {
      return;
    }
    if (!_targetActive) {
      _updateView(() => _shotsOff += 1);
      return;
    }
    final crosshairCenter = Offset(
      _crosshair.dx * _stageSize.width,
      _crosshair.dy * _stageSize.height,
    );
    final targetCenter = Offset(
      _target.dx * _stageSize.width,
      _target.dy * _stageSize.height,
    );
    if ((crosshairCenter - targetCenter).distance <= _hitRadius) {
      final reaction = _targetStopwatch.elapsed;
      _targetStopwatch.stop();
      _updateView(() {
        _hits += 1;
        _hitReactions.add(reaction);
        _targetActive = false;
        _waitingTarget = false;
        _distractors = const <_HandEyeDistractorTarget>[];
      });
      if (_mode == _JoystickTestMode.targetCount && _hits >= _targetGoal) {
        _finish();
      } else {
        _scheduleTarget();
      }
      return;
    }
    for (final distractor in _distractors) {
      final distractorCenter = _distractorCenter(distractor);
      final radius = math.max(10, distractor.diameter * 0.52);
      if ((crosshairCenter - distractorCenter).distance <= radius) {
        _updateView(() {
          _shotsOff += 1;
          _falseTargetShots += 1;
        });
        return;
      }
    }
    _updateView(() => _shotsOff += 1);
  }

  void _setMode(_JoystickTestMode mode) {
    _updateView(() {
      _mode = mode;
      _remainingTenths = _durationSeconds * 10;
    });
  }

  void _setDuration(double value) {
    final next = value.round().clamp(3, 600);
    _updateView(() {
      _durationSeconds = next;
      _remainingTenths = _durationSeconds * 10;
    });
    _durationController.text = '$next';
  }

  void _setTargetGoal(double value) {
    final next = value.round().clamp(1, 300);
    _updateView(() => _targetGoal = next);
    _targetGoalController.text = '$next';
  }

  void _setCrosshairSpeed(double value) {
    final next = value.clamp(0.1, 10.0).toDouble();
    _updateView(() => _crosshairSpeed = next);
    _crosshairSpeedController.text = next.toStringAsFixed(1);
  }

  void _setJoystickAcceleration(double value) {
    final next = value.clamp(0.0, 8.0).toDouble();
    _updateView(() => _joystickAcceleration = next);
    _joystickAccelerationController.text = next.toStringAsFixed(1);
  }

  void _setJoystickVector(Offset value) {
    _updateView(() => _joystickVector = value);
  }

  void _setTargetDiameter(double value) {
    final next = value.clamp(14.0, 120.0).toDouble();
    _updateView(() => _targetDiameter = next);
    _targetDiameterController.text = '${next.round()}';
  }

  void _setTargetMovementEnabled(bool value) {
    _updateView(() => _targetMovementEnabled = value);
  }

  void _setTargetMovementRange(double value) {
    final next = value.clamp(0.0, 2.0).toDouble();
    _updateView(() => _targetMovementRange = next);
    _targetMovementRangeController.text = '${(next * 100).round()}';
  }

  void _setTargetMovementSpeed(double value) {
    final next = value.clamp(0.0, 6.0).toDouble();
    _updateView(() => _targetMovementSpeed = next);
    _targetMovementSpeedController.text = next.toStringAsFixed(1);
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

  Future<void> _openFullscreen() async {
    await _enterHumanTestLandscapeFullscreen();
    if (!mounted) {
      await _exitHumanTestFullscreen();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _JoystickFullscreenView(state: this),
      ),
    );
    await _exitHumanTestFullscreen();
    if (mounted) {
      _updateView(() {});
    }
  }

  Offset _distractorCenter(_HandEyeDistractorTarget target) {
    final t = _targetMovementEnabled
        ? (0.5 +
              0.5 *
                  math.sin(
                    _sessionStopwatch.elapsedMilliseconds /
                        1000.0 *
                        math.pi *
                        (0.7 + _targetMovementSpeed * 0.38),
                  ))
        : 0.0;
    final line = Offset.lerp(target.start, target.end, t) ?? target.start;
    final direction = target.end - target.start;
    final length = direction.distance;
    if (length <= 0.001 || target.wave <= 0) {
      return Offset(line.dx * _stageSize.width, line.dy * _stageSize.height);
    }
    final normal = Offset(-direction.dy / length, direction.dx / length);
    final moved =
        line +
        normal *
            math.sin(t * math.pi * 2) *
            target.wave *
            (0.6 + _targetMovementSpeed * 0.2);
    final edge = _targetEdgeFraction();
    final bounded = Offset(
      moved.dx.clamp(edge, 1 - edge),
      moved.dy.clamp(edge, 1 - edge),
    );
    return Offset(
      bounded.dx * _stageSize.width,
      bounded.dy * _stageSize.height,
    );
  }

  void _showCompletionReport() {
    _showJoystickReport();
  }

  void _showJoystickReport() {
    if (!mounted || _reportDialogOpen) {
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
        builder: (_) => _JoystickCompletionReportDialog(
          mode: _mode,
          durationSeconds: _durationSeconds,
          targetGoal: _targetGoal,
          hits: _hits,
          shotsOff: _shotsOff,
          falseTargetShots: _falseTargetShots,
          reactions: List<Duration>.unmodifiable(_hitReactions),
          targetDiameter: _targetDiameter,
          targetMovementEnabled: _targetMovementEnabled,
          accent: _accent,
        ),
      );
      _reportDialogOpen = false;
    });
  }

  String _modeLabel(AppI18n i18n, _JoystickTestMode mode) {
    return switch (mode) {
      _JoystickTestMode.timed => i18n.t(
        'inline.ui.pages.toolbox_human_tests_cognition.timed_4e65ea',
      ),
      _JoystickTestMode.targetCount => i18n.t(
        'inline.plan294.woodfish.target_count_211bec09',
      ),
    };
  }

  String _spawnLabel(AppI18n i18n) {
    return _randomRespawnDelay
        ? i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_joystick.random_delay_c5fe81',
          )
        : i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_joystick.immediate_1d793e',
          );
  }

  String _statusText(AppI18n i18n) {
    if (_done) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_hand_eye_joystick.test_complete_fa03c3',
      );
    }
    if (!_running) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_hand_eye_joystick.press_start_d4f3eb',
      );
    }
    if (_waitingTarget) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_hand_eye_joystick.waiting_for_target_3d26af',
      );
    }
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_hand_eye_joystick.move_and_fire_e2f9ac',
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final averageReaction = _averageReaction;
    final accuracy = _shots == 0 ? null : _hits / _shots * 100;
    final progress = _mode == _JoystickTestMode.timed
        ? _formatSeconds(_remainingTenths / 10)
        : '$_hits/$_targetGoal';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (i18n.t('toolbox.sound.piano.mode'), _modeLabel(i18n, _mode)),
            (i18n.t('progress'), progress),
            (
              i18n.t('inline.ui.pages.toolbox_human_tests_action.hits_fe10b3'),
              '$_hits',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_hand_eye_joystick.shots_off_cac739',
              ),
              '$_shotsOff',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_aim.false_targets_c0458f',
              ),
              '$_falseTargetShots',
            ),
            (
              i18n.t('inline.ui.pages.practice_review_page.accuracy_8cf5a1'),
              accuracy == null ? '-' : '${accuracy.round()}%',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_bimanual.avg_reaction_2a9cf7',
              ),
              averageReaction == null
                  ? '-'
                  : _formatMilliseconds(averageReaction.inMilliseconds),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_fullscreen.joystick_settings_00005b',
          ),
          subtitle: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_fullscreen.test_mode_crosshair_response_speed_and_respawn_timing_c4a9dd',
          ),
          child: _buildJoystickSettings(i18n),
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_fullscreen.target_movement_settings_6a2aa5',
          ),
          subtitle: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_fullscreen.off_by_default_keeps_targets_moving_after_spawn_for_hard_b87d42',
          ),
          child: _buildJoystickMovementSettings(i18n),
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_fullscreen.advanced_interference_7d48f7',
          ),
          subtitle: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_fullscreen.off_by_default_color_coded_false_targets_may_appear_arou_0283f8',
          ),
          child: _buildJoystickDistractorSettings(i18n),
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          padding: EdgeInsets.zero,
          child: _JoystickPlayStage(
            state: this,
            heightForConstraints: (constraints) =>
                math.min(380, constraints.maxWidth * 0.76),
          ),
        ),
        const SizedBox(height: 12),
        _JoystickControlDeck(state: this, fullscreen: false),
        const SizedBox(height: 10),
        if (_showJoystickHandEyeFullscreenEntry)
          OutlinedButton.icon(
            key: const ValueKey<String>('joystick_hand_eye_fullscreen_button'),
            onPressed: _openFullscreen,
            icon: const Icon(Icons.fullscreen_rounded),
            label: Text(
              i18n.t('inline.plan295.daily_choice.fullscreen.d9ff7c0308b7'),
            ),
          ),
        if (_hitReactions.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _JoystickResultPanel(reactions: _hitReactions, accent: _accent),
        ],
      ],
    );
  }
}

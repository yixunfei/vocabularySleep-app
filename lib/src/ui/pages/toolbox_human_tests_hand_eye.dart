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
      title: pickUiText(i18n, zh: '手眼协调测试', en: 'Hand-eye coordination'),
      subtitle: pickUiText(
        i18n,
        zh: '目标会在随机时间与位置出现、快速移动并消失；在消失前按要求点击命中。',
        en: 'Targets appear at random times and positions, move quickly, then vanish. Tap enough times before they disappear.',
      ),
      accent: const Color(0xFFB55D42),
      icon: Icons.center_focus_strong_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：开始后等待目标出现',
        en: 'Next: start and wait for the target',
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
  int _token = 0;
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

  bool get _active =>
      _phase == _HandEyePhase.waiting || _phase == _HandEyePhase.visible;

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
    _targetController.stop();
    _notifyView();
    _targetStopwatch
      ..stop()
      ..reset();
    _updateView(() {
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
    _targetController.stop();
    _notifyView();
    _targetStopwatch
      ..stop()
      ..reset();
    _updateView(() {
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

  void _scheduleNextTarget() {
    if (!mounted || _phase == _HandEyePhase.done) {
      return;
    }
    if (_results.length >= _roundCount) {
      _updateView(() => _phase = _HandEyePhase.done);
      _showCompletionReport();
      return;
    }
    final token = _token;
    final wait = Duration(milliseconds: 280 + _random.nextInt(950));
    _updateView(() => _phase = _HandEyePhase.waiting);
    _spawnTimer = Timer(wait, () {
      if (!mounted || token != _token || _phase != _HandEyePhase.waiting) {
        return;
      }
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
    final token = _token;
    _visibleTimer?.cancel();
    if (_visibleMode == _HandEyeVisibleMode.timed) {
      _visibleTimer = Timer(Duration(milliseconds: _displayMs), () {
        if (!mounted || token != _token || _phase != _HandEyePhase.visible) {
          return;
        }
        _completeTarget(success: false);
      });
    }
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
    if (_phase != _HandEyePhase.visible || !_targetStopwatch.isRunning) {
      return _targetController.value;
    }
    final durationMicros = math.max(1, _motionDuration().inMicroseconds);
    final elapsedMicros = _targetStopwatch.elapsedMicroseconds;
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
    if (!mounted || _phase != _HandEyePhase.visible) {
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
    _targetController.stop();
    _notifyView();
    _targetStopwatch.stop();
    final visibleFor = _targetStopwatch.elapsed;
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
      _firstReaction ??= _targetStopwatch.elapsed;
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
      ),
      _HandEyeVisibleMode.untilTaps => pickUiText(
        i18n,
        zh: '点满才消失',
        en: 'Until taps complete',
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
    return switch (_phase) {
      _HandEyePhase.idle => pickUiText(
        i18n,
        zh: '点击开始后，目标会在随机时间出现。',
        en: 'Press Start. Targets will appear after random delays.',
      ),
      _HandEyePhase.waiting => pickUiText(
        i18n,
        zh: '等待目标出现',
        en: 'Waiting for target',
      ),
      _HandEyePhase.visible => pickUiText(
        i18n,
        zh: '命中目标：$_targetTaps/$_requiredTaps',
        en: 'Hit target: $_targetTaps/$_requiredTaps',
      ),
      _HandEyePhase.done => pickUiText(
        i18n,
        zh: '测试完成，可重置或再次开始。',
        en: 'Test complete. Reset or start again.',
      ),
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
              pickUiText(i18n, zh: '轮次', en: 'Rounds'),
              '$attempted/$_roundCount',
            ),
            (pickUiText(i18n, zh: '成功', en: 'Success'), '$_successes'),
            (pickUiText(i18n, zh: '漏掉', en: 'Missed'), '$_missed'),
            (pickUiText(i18n, zh: '点空', en: 'Blanks'), '$_totalBlankTaps'),
            (
              pickUiText(i18n, zh: '假目标', en: 'False targets'),
              '$_totalDistractorTaps',
            ),
            (
              pickUiText(i18n, zh: '平均反应', en: 'Avg reaction'),
              averageReaction == null
                  ? '-'
                  : _formatMilliseconds(averageReaction.inMilliseconds),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: pickUiText(i18n, zh: '目标设置', en: 'Target settings'),
          subtitle: pickUiText(
            i18n,
            zh: '轮数、显示时长、移动强度、目标大小和命中点击数',
            en: 'Rounds, visible time, movement strength, target size, and required taps',
          ),
          child: _buildTargetSettings(i18n),
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: pickUiText(i18n, zh: '高阶干扰设置', en: 'Advanced interference'),
          subtitle: pickUiText(
            i18n,
            zh: '默认关闭：随机等待后可同时出现一个或多个假目标，颜色与真目标区分。',
            en: 'Off by default: one or more color-coded false targets may appear with the real target.',
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
              label: _active
                  ? pickUiText(i18n, zh: '进行中', en: 'Running')
                  : pickUiText(i18n, zh: '重新开始', en: 'Restart'),
              icon: _active
                  ? Icons.track_changes_rounded
                  : Icons.restart_alt_rounded,
              onPressed: _active ? null : _start,
            ),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
            ),
            if (_showHandEyeFullscreenEntry)
              OutlinedButton.icon(
                key: const ValueKey<String>('hand_eye_fullscreen_button'),
                onPressed: _openFullscreen,
                icon: const Icon(Icons.fullscreen_rounded),
                label: Text(pickUiText(i18n, zh: '全屏', en: 'Fullscreen')),
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

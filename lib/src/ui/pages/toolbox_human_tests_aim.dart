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
      title: i18n.t('inline.ui.pages.toolbox_human_tests_aim.aim_test_70f27c'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_aim.classic_reveal_grow_moving_and_decoy_target_modes_5210c3',
      ),
      accent: const Color(0xFFC24D5A),
      icon: Icons.adjust_rounded,
      status: i18n.t(
        'inline.ui.pages.toolbox_human_tests_aim.next_choose_a_mode_and_track_the_targets_f1f935',
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
          title: i18n.t(
            'inline.ui.pages.toolbox_human_tests_aim.sniper_hit_143114',
          ),
          subtitle: i18n.t(
            'inline.ui.pages.toolbox_human_tests_aim.the_target_reached_maximum_size_the_counter_shot_window_e21500',
          ),
          actionLabel: finished
              ? i18n.t(
                  'inline.ui.pages.toolbox_human_tests_aim.view_report_05b6eb',
                )
              : i18n.t('toolbox.breathing.continue_select'),
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
      _AimTestMode.classic => i18n.t(
        'inline.plan295.life.classic.184f87f1be60',
      ),
      _AimTestMode.revealGrowth => i18n.t(
        'inline.ui.pages.toolbox_human_tests_aim.reveal_grow_e12a67',
      ),
      _AimTestMode.moving => i18n.t('toolbox.sound.focus.stageMoving'),
      _AimTestMode.decoys => i18n.t(
        'inline.ui.pages.toolbox_human_tests_aim_widgets.decoys_7648df',
      ),
    };
  }

  String _modeDescription(AppI18n i18n, _AimTestMode mode) {
    return switch (mode) {
      _AimTestMode.classic => i18n.t(
        'inline.ui.pages.toolbox_human_tests_aim.fixed_targets_for_speed_checks_and_warm_ups_049a5c',
      ),
      _AimTestMode.revealGrowth => i18n.t(
        'inline.ui.pages.toolbox_human_tests_aim.the_target_starts_nearly_invisible_appears_quickly_then_3d7c92',
      ),
      _AimTestMode.moving => i18n.t(
        'inline.ui.pages.toolbox_human_tests_aim.the_target_moves_between_two_points_for_tracking_practic_22311d',
      ),
      _AimTestMode.decoys => i18n.t(
        'inline.ui.pages.toolbox_human_tests_aim.red_is_real_teal_is_false_hitting_a_decoy_refreshes_the_237a7c',
      ),
    };
  }

  String _feedbackText(AppI18n i18n) {
    return switch (_feedbackKind) {
      _AimFeedbackKind.idle => _modeDescription(i18n, _mode),
      _AimFeedbackKind.ready => i18n.t(
        'inline.ui.pages.toolbox_human_tests_aim.target_is_live_aim_and_hit_cleanly_777df8',
      ),
      _AimFeedbackKind.hit =>
        _latestHitMs == null
            ? i18n.t('inline.ui.pages.toolbox_human_tests_aim.hit_bb8a95')
            : i18n.t(
                'inline.ui.pages.toolbox_human_tests_aim.hit_formatmilliseconds_latesthitms_1146a9',
              ),
      _AimFeedbackKind.miss => i18n.t(
        'inline.ui.pages.toolbox_human_tests_aim.blank_tap_the_target_stays_but_the_streak_is_broken_c645da',
      ),
      _AimFeedbackKind.decoy => i18n.t(
        'inline.ui.pages.toolbox_human_tests_aim.decoy_hit_round_refreshed_1f9b43',
      ),
      _AimFeedbackKind.timeout => i18n.t(
        'inline.ui.pages.toolbox_human_tests_aim.growth_window_ended_moving_to_the_next_target_2c4ba6',
      ),
      _AimFeedbackKind.sniperFail => i18n.t(
        'inline.ui.pages.toolbox_human_tests_aim.sniper_hit_counter_shot_failed_938849',
      ),
      _AimFeedbackKind.complete => i18n.t(
        'inline.ui.pages.toolbox_human_tests_aim.test_complete_tune_the_mode_and_run_another_round_48fdbd',
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
      return i18n.t('inline.ui.pages.toolbox_human_tests_aim.s_tier_a034c5');
    }
    if (accuracy >= 0.82 && average <= 850) {
      return i18n.t('inline.ui.pages.toolbox_human_tests_aim.a_tier_ae9fbc');
    }
    if (accuracy >= 0.70 && average <= 1150) {
      return i18n.t('inline.ui.pages.toolbox_human_tests_aim.b_tier_497877');
    }
    return i18n.t('inline.ui.pages.toolbox_human_tests_aim.training_84d5e8');
  }

  String _modeCombinationLabel(AppI18n i18n) {
    final parts = <String>[_modeLabel(i18n, _mode)];
    if (_usesRevealGrowth && _revealMoves) {
      parts.add(
        i18n.t('inline.ui.pages.toolbox_human_tests_aim.moving_growth_f61471'),
      );
    }
    if (_mode == _AimTestMode.moving && _movingDecoys) {
      parts.add(
        i18n.t('inline.ui.pages.toolbox_human_tests_aim.decoys_1dc157'),
      );
    }
    if (_mode == _AimTestMode.decoys && _decoysMove) {
      parts.add(
        i18n.t('inline.ui.pages.toolbox_human_tests_aim.moving_decoys_b3809a'),
      );
    }
    if (_usesSniperDuel) {
      parts.add(
        i18n.t('inline.ui.pages.toolbox_human_tests_aim.sniper_duel_feb174'),
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
            (i18n.t('toolbox.sound.piano.mode'), _modeLabel(i18n, _mode)),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_aim_widgets.targets_d13c96',
              ),
              '$_resolvedTargets/$_targetGoal',
            ),
            (
              i18n.t('inline.ui.pages.toolbox_human_tests_action.hits_fe10b3'),
              '$_hits',
            ),
            (
              i18n.t('inline.ui.pages.practice_review_page.accuracy_8cf5a1'),
              accuracy == null ? '-' : '${(accuracy * 100).round()}%',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_aim_widgets.avg_hit_bb007b',
              ),
              average == null ? '-' : _formatMilliseconds(average),
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_aim_widgets.best_streak_5a5a71',
              ),
              '$_bestStreak',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_aim_widgets.rating_1c57db',
              ),
              _ratingLabel(i18n),
            ),
            if (_sniperFailures > 0)
              (
                i18n.t(
                  'inline.ui.pages.toolbox_human_tests_aim_widgets.sniper_fails_72f20e',
                ),
                '$_sniperFailures',
              ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: i18n.t(
            'inline.ui.pages.toolbox_human_tests_aim.aim_settings_b68a1d',
          ),
          subtitle: i18n.t(
            'inline.ui.pages.toolbox_human_tests_aim.modes_target_count_size_reveal_timing_movement_and_decoy_d63a00',
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
                                  ? i18n.t(
                                      'inline.plan295.prayer_beads.round_complete.40e46fc4aabb',
                                    )
                                  : i18n.t('timerIdle'),
                              subtitle: _done
                                  ? i18n.t(
                                      'inline.ui.pages.toolbox_human_tests_aim.total_formatmilliseconds_finalmilliseconds_0_6a27d6',
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
                  ? i18n.t(
                      'inline.ui.pages.practice_session_page.restart_8b7fcc',
                    )
                  : i18n.t('toolbox.breathing.start'),
              icon: _running ? Icons.refresh_rounded : Icons.play_arrow_rounded,
              onPressed: _start,
            ),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(i18n.t('appearanceReset')),
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
                  i18n.t(
                    'inline.ui.pages.toolbox_human_tests_aim.view_report_05b6eb',
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
          i18n.t('toolbox.sound.piano.mode'),
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
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_aim.target_total_97e9f3',
          ),
          valueText: '$_targetGoal',
          value: _targetGoal.toDouble(),
          min: 5,
          max: 60,
          divisions: 11,
          onChanged: _running ? null : _setTargetGoal,
        ),
        _AimSettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_aim_widgets.target_size_2f3de4',
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
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_aim.movement_speed_3b645c',
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
            title: i18n.t(
              'inline.ui.pages.toolbox_human_tests_aim.add_decoys_115188',
            ),
            subtitle: i18n.t(
              'inline.ui.pages.toolbox_human_tests_aim.add_false_targets_around_the_moving_target_77371c',
            ),
            value: _movingDecoys,
            onChanged: _running ? null : _setMovingDecoys,
          ),
          if (_movingDecoys)
            _AimSettingSlider(
              label: i18n.t(
                'inline.ui.pages.toolbox_human_tests_aim.false_targets_c0458f',
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
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_aim.start_size_d23173',
            ),
            valueText: '${_revealStartDiameter.toStringAsFixed(1)} dp',
            value: _revealStartDiameter,
            min: 0,
            max: 4,
            divisions: 40,
            onChanged: _running ? null : _setRevealStartDiameter,
          ),
          _AimSettingSlider(
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_aim.reveal_time_f91384',
            ),
            valueText: '$_revealMilliseconds ms',
            value: _revealMilliseconds.toDouble(),
            min: 60,
            max: 260,
            divisions: 20,
            onChanged: _running ? null : _setRevealMilliseconds,
          ),
          _AimSettingSlider(
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_aim.visible_size_1aff1e',
            ),
            valueText: '${_revealVisibleDiameter.toStringAsFixed(1)} dp',
            value: _revealVisibleDiameter,
            min: 3,
            max: 16,
            divisions: 26,
            onChanged: _running ? null : _setRevealVisibleDiameter,
          ),
          _AimSettingSlider(
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_aim.growth_speed_fff2b4',
            ),
            valueText: '${_growthSpeed.toStringAsFixed(1)}x',
            value: _growthSpeed,
            min: 0.7,
            max: 2.8,
            divisions: 21,
            onChanged: _running ? null : _setGrowthSpeed,
          ),
          _AimSettingSwitch(
            title: i18n.t(
              'inline.ui.pages.toolbox_human_tests_aim.moving_growth_ba125e',
            ),
            subtitle: i18n.t(
              'inline.ui.pages.toolbox_human_tests_aim.the_target_grows_while_moving_mixing_tracking_with_early_b57b17',
            ),
            value: _revealMoves,
            onChanged: _running ? null : _setRevealMoves,
          ),
          if (_revealMoves)
            _AimSettingSlider(
              label: i18n.t(
                'inline.ui.pages.toolbox_human_tests_aim.movement_speed_3b645c',
              ),
              valueText: '${_movementSpeed.toStringAsFixed(1)}x',
              value: _movementSpeed,
              min: 0.6,
              max: 3.0,
              divisions: 24,
              onChanged: _running ? null : _setMovementSpeed,
            ),
          _AimSettingSwitch(
            title: i18n.t(
              'inline.ui.pages.toolbox_human_tests_aim_widgets.sniper_duel_85c2cf',
            ),
            subtitle: i18n.t(
              'inline.ui.pages.toolbox_human_tests_aim.if_the_target_maxes_out_before_a_hit_trigger_haptics_and_b8f260',
            ),
            value: _sniperDuel,
            onChanged: _running ? null : _setSniperDuel,
          ),
          _buildCurveSelector(
            i18n,
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_aim.speed_curve_c232ac',
            ),
            value: _speedCurve,
            onSelected: _setSpeedCurve,
          ),
          const SizedBox(height: 10),
          _buildCurveSelector(
            i18n,
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_aim.target_curve_4f8f45',
            ),
            value: _targetCurve,
            onSelected: _setTargetCurve,
          ),
        ],
        if (_mode == _AimTestMode.decoys) ...<Widget>[
          _AimSettingSwitch(
            title: i18n.t(
              'inline.ui.pages.toolbox_human_tests_aim.moving_decoys_202d41',
            ),
            subtitle: i18n.t(
              'inline.ui.pages.toolbox_human_tests_aim.move_both_real_and_false_targets_for_the_combined_decoy_b196cc',
            ),
            value: _decoysMove,
            onChanged: _running ? null : _setDecoysMove,
          ),
          if (_decoysMove)
            _AimSettingSlider(
              label: i18n.t(
                'inline.ui.pages.toolbox_human_tests_aim.movement_speed_3b645c',
              ),
              valueText: '${_movementSpeed.toStringAsFixed(1)}x',
              value: _movementSpeed,
              min: 0.6,
              max: 3.0,
              divisions: 24,
              onChanged: _running ? null : _setMovementSpeed,
            ),
          _AimSettingSlider(
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_aim.false_targets_c0458f',
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
      _AimGrowthCurve.linear => i18n.t(
        'inline.ui.pages.toolbox_human_tests_aim.linear_4e4feb',
      ),
      _AimGrowthCurve.easeOut => i18n.t(
        'inline.ui.pages.toolbox_human_tests_aim.ease_out_6b2dea',
      ),
      _AimGrowthCurve.easeIn => i18n.t(
        'inline.ui.pages.toolbox_human_tests_aim.ease_in_209a88',
      ),
      _AimGrowthCurve.easeInOut => i18n.t(
        'inline.plan294.zen_sand.smooth_a6a61c2c',
      ),
      _AimGrowthCurve.fastOutSlowIn => i18n.t(
        'inline.ui.pages.toolbox_human_tests_aim.fast_slow_edfbb3',
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

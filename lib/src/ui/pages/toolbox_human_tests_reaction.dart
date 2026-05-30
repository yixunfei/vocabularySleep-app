part of 'toolbox_human_tests.dart';

enum _ReactionPhase { idle, waiting, ready, feedback, done }

enum _ReactionMode { release, direction, colorMatch }

enum _ReactionPace { standard, sprint, variable }

enum _ReactionDirection { up, right, down, left }

class ReactionTestPage extends StatelessWidget {
  const ReactionTestPage({super.key});

  static const Color _accent = Color(0xFF2F8D8E);

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.reaction_test_916776',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.release_direction_swipe_and_color_match_modes_with_speed_94c314',
      ),
      accent: _accent,
      icon: Icons.flash_on_rounded,
      status: i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.next_choose_a_mode_and_finish_a_reaction_set_45543a',
      ),
      child: const _ReactionTestCard(),
    );
  }
}

class _ReactionAttempt {
  const _ReactionAttempt({
    required this.success,
    this.milliseconds,
    this.falseStart = false,
    this.wrongDirection = false,
    this.wrongColor = false,
  });

  final bool success;
  final int? milliseconds;
  final bool falseStart;
  final bool wrongDirection;
  final bool wrongColor;
}

class _ReactionModeSpec {
  const _ReactionModeSpec({
    required this.label,
    required this.description,
    required this.icon,
  });

  final String label;
  final String description;
  final IconData icon;
}

class _ReactionColorTarget {
  const _ReactionColorTarget({required this.labelKey, required this.color});
  final String labelKey;
  final Color color;

  String label(AppI18n i18n) => i18n.t(labelKey);
}

class _ReactionTestCard extends StatefulWidget {
  const _ReactionTestCard();

  @override
  State<_ReactionTestCard> createState() => _ReactionTestCardState();
}

class _ReactionTestCardState extends State<_ReactionTestCard> {
  static const Color _accent = ReactionTestPage._accent;
  static const double _directionSwipeThreshold = 34;

  static const List<_ReactionColorTarget>
  _colorTargets = <_ReactionColorTarget>[
    _ReactionColorTarget(
      labelKey: 'inline.plan297.human_tests.reaction.color.red.6c9acd0a2b',
      color: Color(0xFFD94B4B),
    ),
    _ReactionColorTarget(
      labelKey: 'inline.plan297.human_tests.reaction.color.blue.cb292647f4',
      color: Color(0xFF3D6FD8),
    ),
    _ReactionColorTarget(
      labelKey: 'inline.plan297.human_tests.reaction.color.green.8efb18c875',
      color: Color(0xFF2F9E68),
    ),
    _ReactionColorTarget(
      labelKey: 'inline.plan297.human_tests.reaction.color.yellow.c260591507',
      color: Color(0xFFE0B43A),
    ),
    _ReactionColorTarget(
      labelKey: 'inline.plan297.human_tests.reaction.color.purple.16fceeffaa',
      color: Color(0xFF8367C7),
    ),
  ];

  final math.Random _random = math.Random();
  final Stopwatch _stopwatch = Stopwatch();
  final List<_ReactionAttempt> _attempts = <_ReactionAttempt>[];

  Timer? _signalTimer;
  _ReactionPhase _phase = _ReactionPhase.idle;
  _ReactionMode _mode = _ReactionMode.release;
  _ReactionPace _pace = _ReactionPace.standard;
  _ReactionDirection? _direction;
  _ReactionColorTarget? _colorTarget;
  bool _pressed = false;
  int _roundTarget = 5;
  int _roundToken = 0;
  Offset? _directionPointerOrigin;
  bool _directionPointerActive = false;
  bool _reportDialogOpen = false;

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  void _cancelTimers() {
    _roundToken += 1;
    _signalTimer?.cancel();
    _signalTimer = null;
    _stopwatch
      ..stop()
      ..reset();
  }

  void _reset() {
    _cancelTimers();
    setState(() {
      _attempts.clear();
      _phase = _ReactionPhase.idle;
      _direction = null;
      _colorTarget = null;
      _pressed = false;
      _clearDirectionPointer();
      _reportDialogOpen = false;
    });
  }

  void _setMode(_ReactionMode mode) {
    if (_mode == mode) {
      return;
    }
    _cancelTimers();
    setState(() {
      _mode = mode;
      _attempts.clear();
      _phase = _ReactionPhase.idle;
      _direction = null;
      _colorTarget = null;
      _pressed = false;
      _clearDirectionPointer();
      _reportDialogOpen = false;
    });
  }

  void _setPace(_ReactionPace pace) {
    if (_pace == pace) {
      return;
    }
    _cancelTimers();
    setState(() {
      _pace = pace;
      _attempts.clear();
      _phase = _ReactionPhase.idle;
      _direction = null;
      _colorTarget = null;
      _pressed = false;
      _clearDirectionPointer();
      _reportDialogOpen = false;
    });
  }

  void _setRoundTarget(int value) {
    if (_roundTarget == value) {
      return;
    }
    _cancelTimers();
    setState(() {
      _roundTarget = value;
      _attempts.clear();
      _phase = _ReactionPhase.idle;
      _direction = null;
      _colorTarget = null;
      _pressed = false;
      _clearDirectionPointer();
      _reportDialogOpen = false;
    });
  }

  Duration _randomDelay() {
    final range = switch (_pace) {
      _ReactionPace.standard => (900, 2600),
      _ReactionPace.sprint => (420, 1350),
      _ReactionPace.variable => (350, 3600),
    };
    final span = range.$2 - range.$1 + 1;
    return Duration(milliseconds: range.$1 + _random.nextInt(span));
  }

  void _startRound({bool holding = false}) {
    final wasDone = _phase == _ReactionPhase.done;
    _cancelTimers();
    _pressed = holding;
    final token = _roundToken;
    setState(() {
      if (wasDone) {
        _attempts.clear();
      }
      _phase = _ReactionPhase.waiting;
      _direction = null;
      _colorTarget = null;
    });
    _signalTimer = Timer(_randomDelay(), () {
      if (!mounted ||
          token != _roundToken ||
          _phase != _ReactionPhase.waiting) {
        return;
      }
      if (_mode == _ReactionMode.release && !_pressed) {
        return;
      }
      _showSignal();
    });
  }

  void _showSignal() {
    _stopwatch
      ..reset()
      ..start();
    setState(() {
      _phase = _ReactionPhase.ready;
      _direction = _mode == _ReactionMode.direction
          ? _sample(_random, _ReactionDirection.values)
          : null;
      _colorTarget = _mode == _ReactionMode.colorMatch
          ? _sample(_random, _colorTargets)
          : null;
    });
    HapticFeedback.selectionClick();
  }

  void _record(_ReactionAttempt attempt) {
    _signalTimer?.cancel();
    _stopwatch.stop();
    final nextAttempts = <_ReactionAttempt>[..._attempts, attempt];
    final completed = nextAttempts.length >= _roundTarget;
    setState(() {
      _attempts
        ..clear()
        ..addAll(nextAttempts);
      _phase = completed ? _ReactionPhase.done : _ReactionPhase.feedback;
      _direction = null;
      _colorTarget = null;
      _pressed = false;
      _clearDirectionPointer();
    });
    if (attempt.success) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
    if (completed) {
      _showCompletionReport();
    }
  }

  void _showCompletionReport() {
    if (!mounted || _reportDialogOpen || _attempts.length < _roundTarget) {
      return;
    }
    final reportAttempts = List<_ReactionAttempt>.unmodifiable(_attempts);
    final successCount = reportAttempts
        .where((attempt) => attempt.success)
        .length;
    final falseStarts = reportAttempts
        .where((attempt) => attempt.falseStart)
        .length;
    final wrongDirections = reportAttempts
        .where((attempt) => attempt.wrongDirection)
        .length;
    final wrongColors = reportAttempts
        .where((attempt) => attempt.wrongColor)
        .length;
    final accuracy = reportAttempts.isEmpty
        ? null
        : successCount / reportAttempts.length;
    final averageMs = _averageMs;
    final bestMs = _bestMs;
    final beat = _beatPercentile();
    final streak = _streak;
    final mode = _mode;
    final pace = _pace;
    final roundTarget = _roundTarget;
    _reportDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _reportDialogOpen = false;
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => _ReactionCompletionReportDialog(
          attempts: reportAttempts,
          roundTarget: roundTarget,
          successCount: successCount,
          falseStarts: falseStarts,
          wrongDirections: wrongDirections,
          wrongColors: wrongColors,
          accuracy: accuracy,
          averageMs: averageMs,
          bestMs: bestMs,
          beatPercentile: beat,
          modeLabel: _modeSpec(
            AppI18n(Localizations.localeOf(dialogContext).languageCode),
            mode,
          ).label,
          paceLabel: _paceLabel(
            AppI18n(Localizations.localeOf(dialogContext).languageCode),
            pace,
          ),
          streak: streak,
          accent: _accent,
        ),
      );
      _reportDialogOpen = false;
    });
  }

  void _falseStart() {
    _record(const _ReactionAttempt(success: false, falseStart: true));
  }

  void _handleStageDown() {
    if (_mode != _ReactionMode.release) {
      return;
    }
    if (_phase == _ReactionPhase.waiting || _phase == _ReactionPhase.ready) {
      return;
    }
    _pressed = true;
    _startRound(holding: true);
  }

  void _handleStageUp() {
    if (_mode == _ReactionMode.release) {
      _handleRelease();
      return;
    }
    _handleStageTap();
  }

  void _handleStageTap() {
    if (_phase == _ReactionPhase.idle ||
        _phase == _ReactionPhase.feedback ||
        _phase == _ReactionPhase.done) {
      _startRound();
      return;
    }
    if (_phase == _ReactionPhase.waiting) {
      _falseStart();
    }
  }

  void _handleRelease() {
    if (!_pressed) {
      return;
    }
    _pressed = false;
    if (_phase == _ReactionPhase.waiting) {
      _falseStart();
      return;
    }
    if (_phase == _ReactionPhase.ready) {
      _record(
        _ReactionAttempt(
          success: true,
          milliseconds: _stopwatch.elapsedMilliseconds,
        ),
      );
    }
  }

  void _handleDirectionTap(_ReactionDirection direction) {
    if (_mode != _ReactionMode.direction) {
      return;
    }
    if (_phase == _ReactionPhase.idle ||
        _phase == _ReactionPhase.feedback ||
        _phase == _ReactionPhase.done) {
      _startRound();
      return;
    }
    if (_phase == _ReactionPhase.waiting) {
      _falseStart();
      return;
    }
    if (_phase != _ReactionPhase.ready) {
      return;
    }
    _recordDirectionChoice(direction);
  }

  void _recordDirectionChoice(_ReactionDirection direction) {
    final correct = direction == _direction;
    _record(
      _ReactionAttempt(
        success: correct,
        milliseconds: correct ? _stopwatch.elapsedMilliseconds : null,
        wrongDirection: !correct,
      ),
    );
  }

  void _handleColorTap(_ReactionColorTarget target) {
    if (_mode != _ReactionMode.colorMatch) {
      return;
    }
    if (_phase == _ReactionPhase.idle ||
        _phase == _ReactionPhase.feedback ||
        _phase == _ReactionPhase.done) {
      _startRound();
      return;
    }
    if (_phase == _ReactionPhase.waiting) {
      _falseStart();
      return;
    }
    if (_phase != _ReactionPhase.ready) {
      return;
    }
    final correct = target == _colorTarget;
    _record(
      _ReactionAttempt(
        success: correct,
        milliseconds: correct ? _stopwatch.elapsedMilliseconds : null,
        wrongColor: !correct,
      ),
    );
  }

  void _handleDirectionPointerDown(PointerDownEvent event) {
    _startDirectionGesture(event.position);
  }

  void _handleDirectionPointerMove(PointerMoveEvent event) {
    _updateDirectionGesture(event.position);
  }

  void _handleDirectionPointerUp(PointerUpEvent event) {
    _endDirectionGesture(event.position);
  }

  void _handleDirectionPointerCancel(PointerCancelEvent event) {
    _clearDirectionPointer();
  }

  void _startDirectionGesture(Offset position) {
    if (_mode != _ReactionMode.direction) {
      return;
    }
    _directionPointerOrigin = position;
    _directionPointerActive = true;
    if (_phase == _ReactionPhase.idle ||
        _phase == _ReactionPhase.feedback ||
        _phase == _ReactionPhase.done) {
      _startRound(holding: true);
    }
  }

  void _updateDirectionGesture(Offset position) {
    if (!_directionPointerActive || _mode != _ReactionMode.direction) {
      return;
    }
    final origin = _directionPointerOrigin;
    if (origin == null) {
      return;
    }
    final direction = _directionFromDelta(position - origin);
    if (direction == null) {
      return;
    }
    if (_phase == _ReactionPhase.waiting) {
      _falseStart();
      return;
    }
    if (_phase == _ReactionPhase.ready) {
      _recordDirectionChoice(direction);
    }
  }

  void _endDirectionGesture(Offset? position) {
    if (!_directionPointerActive || _mode != _ReactionMode.direction) {
      return;
    }
    final origin = _directionPointerOrigin;
    final direction = origin == null || position == null
        ? null
        : _directionFromDelta(position - origin);
    if (_phase == _ReactionPhase.waiting) {
      _falseStart();
      return;
    }
    if (_phase == _ReactionPhase.ready) {
      if (direction == null) {
        _record(const _ReactionAttempt(success: false, wrongDirection: true));
      } else {
        _recordDirectionChoice(direction);
      }
      return;
    }
    _clearDirectionPointer();
  }

  void _clearDirectionPointer() {
    _directionPointerOrigin = null;
    _directionPointerActive = false;
  }

  _ReactionDirection? _directionFromDelta(Offset delta) {
    if (delta.distance < _directionSwipeThreshold) {
      return null;
    }
    if (delta.dx.abs() > delta.dy.abs()) {
      return delta.dx > 0 ? _ReactionDirection.right : _ReactionDirection.left;
    }
    return delta.dy > 0 ? _ReactionDirection.down : _ReactionDirection.up;
  }

  int get _successCount => _attempts.where((attempt) => attempt.success).length;

  int get _streak {
    var value = 0;
    for (final attempt in _attempts.reversed) {
      if (!attempt.success) {
        break;
      }
      value += 1;
    }
    return value;
  }

  List<int> get _times => _attempts
      .where((attempt) => attempt.success && attempt.milliseconds != null)
      .map((attempt) => attempt.milliseconds!)
      .toList(growable: false);

  int? get _averageMs {
    if (_times.isEmpty) {
      return null;
    }
    return (_times.reduce((a, b) => a + b) / _times.length).round();
  }

  int? get _bestMs {
    if (_times.isEmpty) {
      return null;
    }
    return _times.reduce(math.min);
  }

  int? _beatPercentile() {
    final average = _averageMs;
    if (average == null) {
      return null;
    }
    if (average <= 160) {
      return 99;
    }
    if (average <= 210) {
      return 90;
    }
    if (average <= 250) {
      return 75;
    }
    if (average <= 300) {
      return 50;
    }
    if (average <= 360) {
      return 25;
    }
    return 10;
  }

  _ReactionModeSpec _modeSpec(AppI18n i18n, _ReactionMode mode) {
    return switch (mode) {
      _ReactionMode.release => _ReactionModeSpec(
        label: i18n.t('platform.linux.cmakelists.txt.release_82546b'),
        description: i18n.t(
          'inline.ui.pages.toolbox_human_tests_reaction.hold_wait_for_green_then_release_dfd6b7',
        ),
        icon: Icons.front_hand_rounded,
      ),
      _ReactionMode.direction => _ReactionModeSpec(
        label: i18n.t('inline.plan295.daily_choice.direction.4a540ce8efd7'),
        description: i18n.t(
          'inline.ui.pages.toolbox_human_tests_reaction.hold_center_then_slide_toward_the_arrow_d_pad_taps_also_0eb4ca',
        ),
        icon: Icons.open_with_rounded,
      ),
      _ReactionMode.colorMatch => _ReactionModeSpec(
        label: i18n.t(
          'inline.ui.pages.toolbox_human_tests_reaction.color_match_2fff88',
        ),
        description: i18n.t(
          'inline.ui.pages.toolbox_human_tests_reaction.when_the_stage_changes_color_tap_the_matching_color_belo_bda3dd',
        ),
        icon: Icons.palette_rounded,
      ),
    };
  }

  String _paceLabel(AppI18n i18n, _ReactionPace pace) {
    return switch (pace) {
      _ReactionPace.standard => i18n.t(
        'inline.ui.pages.toolbox_human_tests_bimanual.standard_b9acb5',
      ),
      _ReactionPace.sprint => i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.sprint_a70236',
      ),
      _ReactionPace.variable => i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.variable_b5cb9c',
      ),
    };
  }

  String _directionGlyph(_ReactionDirection direction) {
    return switch (direction) {
      _ReactionDirection.up => '↑',
      _ReactionDirection.right => '→',
      _ReactionDirection.down => '↓',
      _ReactionDirection.left => '←',
    };
  }

  String _stageText(AppI18n i18n) {
    if (_phase == _ReactionPhase.ready &&
        _mode == _ReactionMode.direction &&
        _direction != null) {
      return _directionGlyph(_direction!);
    }
    if (_phase == _ReactionPhase.ready &&
        _mode == _ReactionMode.colorMatch &&
        _colorTarget != null) {
      return _colorTarget!.label(i18n);
    }
    return switch (_phase) {
      _ReactionPhase.idle =>
        _mode == _ReactionMode.release
            ? i18n.t(
                'inline.ui.pages.toolbox_human_tests_reaction.hold_to_start_7c0c4c',
              )
            : _mode == _ReactionMode.direction
            ? i18n.t(
                'inline.ui.pages.toolbox_human_tests_reaction.hold_center_or_tap_arrow_8a4be8',
              )
            : i18n.t(
                'inline.ui.pages.toolbox_human_tests_reaction.tap_a_color_to_start_d283ab',
              ),
      _ReactionPhase.waiting =>
        _mode == _ReactionMode.release
            ? i18n.t(
                'inline.ui.pages.toolbox_human_tests_reaction.keep_holding_0372a4',
              )
            : _mode == _ReactionMode.direction
            ? i18n.t(
                'inline.ui.pages.toolbox_human_tests_reaction.wait_for_arrow_f9141c',
              )
            : i18n.t(
                'inline.ui.pages.toolbox_human_tests_reaction.wait_for_color_615ddd',
              ),
      _ReactionPhase.ready =>
        _mode == _ReactionMode.release
            ? i18n.t('platform.linux.cmakelists.txt.release_82546b')
            : _mode == _ReactionMode.direction
            ? i18n.t(
                'inline.ui.pages.toolbox_human_tests_reaction.slide_direction_e5eb80',
              )
            : i18n.t(
                'inline.ui.pages.appearance_studio_page.pick_color_dd4439',
              ),
      _ReactionPhase.feedback => _latestFeedbackText(i18n),
      _ReactionPhase.done => i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.set_complete_082408',
      ),
    };
  }

  String _stageHint(AppI18n i18n) {
    if (_phase == _ReactionPhase.feedback) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.repeat_the_action_for_the_next_round_38ea2f',
      );
    }
    if (_phase == _ReactionPhase.done) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.reset_or_switch_mode_for_a_fresh_challenge_3e9a6e',
      );
    }
    return _modeSpec(i18n, _mode).description;
  }

  String _latestFeedbackText(AppI18n i18n) {
    if (_attempts.isEmpty) {
      return i18n.t('timerIdle');
    }
    final latest = _attempts.last;
    if (latest.success && latest.milliseconds != null) {
      final ms = latest.milliseconds!;
      final rank = ms <= 180
          ? i18n.t(
              'inline.ui.pages.toolbox_human_tests_reaction.lightning_7ffe36',
            )
          : ms <= 260
          ? i18n.t('inline.ui.pages.toolbox_human_tests_reaction.sharp_d18182')
          : i18n.t(
              'inline.ui.pages.toolbox_human_tests_auditory_lab.saved_147d6b',
            );
      return '$rank · ${_formatMilliseconds(ms)}';
    }
    if (latest.falseStart) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.false_start_5a5bbc',
      );
    }
    if (latest.wrongDirection) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.wrong_direction_e67d8e',
      );
    }
    if (latest.wrongColor) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.wrong_color_2430f5',
      );
    }
    return i18n.t('toolbox.sleep.rhythm.missed');
  }

  Color _stageColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (_phase) {
      _ReactionPhase.ready =>
        _mode == _ReactionMode.colorMatch && _colorTarget != null
            ? _colorTarget!.color
            : const Color(0xFF3FA76B),
      _ReactionPhase.waiting => const Color(0xFFC2614E),
      _ReactionPhase.feedback =>
        _attempts.isNotEmpty && _attempts.last.success
            ? const Color(0xFF3FA76B).withValues(alpha: 0.22)
            : colorScheme.errorContainer,
      _ReactionPhase.done => colorScheme.primaryContainer,
      _ReactionPhase.idle => colorScheme.surfaceContainerHigh,
    };
  }

  Color _foregroundFor(Color color) {
    return color.computeLuminance() > 0.45
        ? const Color(0xFF17201E)
        : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final accuracy = _attempts.isEmpty
        ? null
        : (_successCount / _attempts.length * 100).round();
    final beat = _beatPercentile();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (i18n.t('rounds'), '${_attempts.length}/$_roundTarget'),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_reaction.average_68111e',
              ),
              _averageMs == null ? '-' : _formatMilliseconds(_averageMs!),
            ),
            (
              i18n.t('toolbox.breathing.best'),
              _bestMs == null ? '-' : _formatMilliseconds(_bestMs!),
            ),
            (
              i18n.t('inline.ui.pages.practice_review_page.accuracy_8cf5a1'),
              accuracy == null ? '-' : '$accuracy%',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_reaction.streak_78b2bd',
              ),
              '$_streak',
            ),
            (
              i18n.t('toolbox.sound.focus.stageBeatLabel'),
              beat == null ? '-' : '$beat%',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildModes(context, i18n),
        const SizedBox(height: 12),
        _buildSettings(context, i18n),
        const SizedBox(height: 12),
        _buildStage(context, i18n),
        const SizedBox(height: 12),
        if (_mode == _ReactionMode.direction)
          _buildDirectionControls(context, i18n)
        else if (_mode == _ReactionMode.colorMatch)
          _buildColorControls(context, i18n)
        else
          _buildPrimaryControls(context, i18n),
        const SizedBox(height: 12),
        _buildTrail(context, i18n),
      ],
    );
  }

  Widget _buildModes(BuildContext context, AppI18n i18n) {
    return _HumanPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            i18n.t('toolbox.sound.soothing.modes_button_label'),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ReactionMode.values
                .map((mode) {
                  final spec = _modeSpec(i18n, mode);
                  return ChoiceChip(
                    selected: _mode == mode,
                    avatar: Icon(spec.icon, size: 18),
                    label: Text(spec.label),
                    onSelected: (_) => _setMode(mode),
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          Text(
            _modeSpec(i18n, _mode).description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildStage(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    final stageColor = _stageColor(context);
    final foreground = _foregroundFor(stageColor);
    final stage = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      height: 260,
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: stageColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_phase == _ReactionPhase.ready &&
              _mode == _ReactionMode.colorMatch &&
              _colorTarget != null) ...<Widget>[
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _colorTarget!.color,
                border: Border.all(
                  color: foreground.withValues(alpha: 0.72),
                  width: 3,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            _stageText(i18n),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _stageHint(i18n),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: foreground.withValues(alpha: 0.86),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
    if (_mode == _ReactionMode.direction) {
      return _buildDirectionPointerRegion(
        key: const ValueKey<String>('reaction_stage'),
        child: stage,
      );
    }
    return GestureDetector(
      key: const ValueKey<String>('reaction_stage'),
      onTapDown: (_) => _handleStageDown(),
      onTapUp: (_) => _handleStageUp(),
      onTapCancel: () {
        if (_mode == _ReactionMode.release) {
          _handleRelease();
        }
      },
      child: stage,
    );
  }

  Widget _buildDirectionPointerRegion({Key? key, required Widget child}) {
    return _HumanPointerDragBoundary(
      key: key,
      onPointerDown: _handleDirectionPointerDown,
      onPointerMove: _handleDirectionPointerMove,
      onPointerUp: _handleDirectionPointerUp,
      onPointerCancel: _handleDirectionPointerCancel,
      child: child,
    );
  }

  Widget _buildPrimaryControls(BuildContext context, AppI18n i18n) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _HumanActionButton(
            label: _primaryActionLabel(i18n),
            icon: _phase == _ReactionPhase.done
                ? Icons.restart_alt_rounded
                : Icons.play_arrow_rounded,
            onPressed: _mode == _ReactionMode.release
                ? null
                : () => _handleStageTap(),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.restart_alt_rounded),
          label: Text(i18n.t('appearanceReset')),
          style: OutlinedButton.styleFrom(minimumSize: const Size(104, 48)),
        ),
      ],
    );
  }

  String _primaryActionLabel(AppI18n i18n) {
    if (_mode == _ReactionMode.release) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.hold_the_stage_b10f50',
      );
    }
    if (_phase == _ReactionPhase.done) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.restart_set_e97c28',
      );
    }
    return _phase == _ReactionPhase.waiting
        ? i18n.t(
            'inline.ui.pages.toolbox_human_tests_reaction.false_start_5a5bbc',
          )
        : i18n.t(
            'inline.ui.pages.toolbox_human_tests_reaction.start_next_818f58',
          );
  }

  Widget _buildDirectionControls(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    return _HumanPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_reaction.direction_d_pad_41b017',
            ),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_reaction.hold_the_center_then_slide_up_down_left_or_right_after_t_e149c7',
            ),
            style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildDirectionButton(_ReactionDirection.up),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _buildDirectionButton(_ReactionDirection.left),
                  const SizedBox(width: 8),
                  _buildDirectionCenter(context, i18n),
                  const SizedBox(width: 8),
                  _buildDirectionButton(_ReactionDirection.right),
                ],
              ),
              const SizedBox(height: 8),
              _buildDirectionButton(_ReactionDirection.down),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(i18n.t('appearanceReset')),
            style: OutlinedButton.styleFrom(minimumSize: const Size(104, 48)),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionButton(_ReactionDirection direction) {
    return SizedBox(
      width: 68,
      height: 56,
      child: FilledButton(
        onPressed: () => _handleDirectionTap(direction),
        child: Text(
          _directionGlyph(direction),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildDirectionCenter(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return _buildDirectionPointerRegion(
      key: const ValueKey<String>('reaction_direction_center'),
      child: Container(
        width: 92,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: _accent.withValues(alpha: 0.14),
          border: Border.all(color: _accent.withValues(alpha: 0.34)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '●',
              style: theme.textTheme.titleLarge?.copyWith(
                color: _accent,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_reaction.hold_center_ed9cde',
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorControls(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    return _HumanPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_reaction.color_buttons_f9c0d5',
            ),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_reaction.tap_any_color_to_start_then_tap_the_matching_color_after_ae99c4',
            ),
            style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _colorTargets
                .map((target) => _buildColorButton(i18n, target))
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(i18n.t('appearanceReset')),
            style: OutlinedButton.styleFrom(minimumSize: const Size(104, 48)),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(AppI18n i18n, _ReactionColorTarget target) {
    return SizedBox(
      width: 116,
      height: 52,
      child: FilledButton(
        onPressed: () => _handleColorTap(target),
        style: FilledButton.styleFrom(
          backgroundColor: target.color,
          foregroundColor: _foregroundFor(target.color),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
        child: Text(target.label(i18n)),
      ),
    );
  }

  Widget _buildSettings(BuildContext context, AppI18n i18n) {
    return _HumanSettingsSection(
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.reaction_settings_9b620f',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.changing_rounds_or_signal_pace_resets_the_current_set_7c863e',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_cognition.round_count_058a83',
            ),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <int>[5, 8, 12]
                .map((value) {
                  return ChoiceChip(
                    selected: _roundTarget == value,
                    label: Text('$value'),
                    onSelected: (_) => _setRoundTarget(value),
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_reaction.signal_pace_453959',
            ),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ReactionPace.values
                .map((pace) {
                  return ChoiceChip(
                    selected: _pace == pace,
                    label: Text(_paceLabel(i18n, pace)),
                    onSelected: (_) => _setPace(pace),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _buildTrail(BuildContext context, AppI18n i18n) {
    final colorScheme = Theme.of(context).colorScheme;
    return _HumanPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  i18n.t(
                    'inline.ui.pages.toolbox_human_tests_reaction.set_trail_69ed01',
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              _HumanPill(
                text: '$_successCount/${_attempts.length}',
                accent: _accent,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_attempts.isEmpty)
            Text(
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_reaction.results_from_each_reaction_will_appear_here_after_the_fi_f9c990',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _attempts
                  .map((attempt) {
                    final success = attempt.success;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: success
                            ? _accent.withValues(alpha: 0.12)
                            : colorScheme.errorContainer.withValues(
                                alpha: 0.76,
                              ),
                        border: Border.all(
                          color: success
                              ? _accent.withValues(alpha: 0.22)
                              : colorScheme.error.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Text(
                        _attemptLabel(i18n, attempt),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }

  String _attemptLabel(AppI18n i18n, _ReactionAttempt attempt) {
    if (attempt.success && attempt.milliseconds != null) {
      return _formatMilliseconds(attempt.milliseconds!);
    }
    if (attempt.falseStart) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.early_0766fc',
      );
    }
    if (attempt.wrongDirection) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.wrong_2a4363',
      );
    }
    if (attempt.wrongColor) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.wrong_color_2430f5',
      );
    }
    return i18n.t('inline.ui.pages.toolbox_human_tests_bimanual.miss_7876fa');
  }
}

class _ReactionCompletionReportDialog extends StatelessWidget {
  const _ReactionCompletionReportDialog({
    required this.attempts,
    required this.roundTarget,
    required this.successCount,
    required this.falseStarts,
    required this.wrongDirections,
    required this.wrongColors,
    required this.accuracy,
    required this.averageMs,
    required this.bestMs,
    required this.beatPercentile,
    required this.modeLabel,
    required this.paceLabel,
    required this.streak,
    required this.accent,
  });

  final List<_ReactionAttempt> attempts;
  final int roundTarget;
  final int successCount;
  final int falseStarts;
  final int wrongDirections;
  final int wrongColors;
  final double? accuracy;
  final int? averageMs;
  final int? bestMs;
  final int? beatPercentile;
  final String modeLabel;
  final String paceLabel;
  final int streak;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final accuracyText = accuracy == null
        ? '-'
        : '${(accuracy! * 100).round()}%';
    final averageText = averageMs == null
        ? '-'
        : _formatMilliseconds(averageMs!);
    final bestText = bestMs == null ? '-' : _formatMilliseconds(bestMs!);
    final beatText = beatPercentile == null ? '-' : '$beatPercentile%';
    final analysis = _analysisText(i18n);
    return _HumanReportDialogFrame(
      title: Text(
        i18n.t(
          'inline.ui.pages.toolbox_human_tests_reaction.reaction_test_report_57a5c4',
        ),
      ),
      accent: accent,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (i18n.t('toolbox.sound.piano.mode'), modeLabel),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_cognition.pace_194760',
              ),
              paceLabel,
            ),
            (i18n.t('rounds'), '$successCount/$roundTarget'),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_reaction.successes_93fe69',
              ),
              '$successCount',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_auditory.false_starts_9a365d',
              ),
              '$falseStarts',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_reaction.wrong_direction_e67d8e',
              ),
              '$wrongDirections',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_reaction.wrong_color_2430f5',
              ),
              '$wrongColors',
            ),
            (
              i18n.t('inline.ui.pages.practice_review_page.accuracy_8cf5a1'),
              accuracyText,
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_reaction.average_68111e',
              ),
              averageText,
            ),
            (i18n.t('toolbox.breathing.best'), bestText),
            (i18n.t('toolbox.sound.focus.stageBeatLabel'), beatText),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_reaction.streak_78b2bd',
              ),
              '$streak',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _HumanPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                i18n.t(
                  'inline.ui.pages.toolbox_human_tests_memory.analysis_b0b53c',
                ),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                analysis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                i18n.t(
                  'inline.ui.pages.toolbox_human_tests_reaction.set_trail_69ed01',
                ),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: attempts
                    .map(
                      (attempt) => Chip(
                        label: Text(_attemptLabel(i18n, attempt)),
                        avatar: Icon(
                          attempt.success
                              ? Icons.check_circle_rounded
                              : Icons.close_rounded,
                          size: 18,
                          color: attempt.success
                              ? accent
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _analysisText(AppI18n i18n) {
    if (falseStarts > 0 && falseStarts >= wrongDirections + wrongColors) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.false_starts_are_the_main_issue_stabilize_timing_before_51253a',
      );
    }
    if (accuracy != null && accuracy! < 0.7) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.accuracy_is_still_low_make_the_action_clean_first_then_r_d55829',
      );
    }
    if ((averageMs ?? 9999) <= 240 && (accuracy ?? 0) >= 0.85) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.the_rhythm_is_steady_move_to_a_faster_pace_to_keep_trimm_8e6ccc',
      );
    }
    if (wrongDirections > 0 || wrongColors > 0) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.most_misses_come_from_direction_or_color_choice_practice_b14c70',
      );
    }
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_reaction.overall_performance_is_steady_keep_the_current_mode_and_c9f13c',
    );
  }

  String _attemptLabel(AppI18n i18n, _ReactionAttempt attempt) {
    if (attempt.success && attempt.milliseconds != null) {
      return _formatMilliseconds(attempt.milliseconds!);
    }
    if (attempt.falseStart) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.early_0766fc',
      );
    }
    if (attempt.wrongDirection) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.wrong_2a4363',
      );
    }
    if (attempt.wrongColor) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.wrong_color_2430f5',
      );
    }
    return i18n.t('inline.ui.pages.toolbox_human_tests_bimanual.miss_7876fa');
  }
}

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
      title: pickUiText(i18n, zh: '反应测试', en: 'Reaction test'),
      subtitle: pickUiText(
        i18n,
        zh: '经典松手、方向滑动与颜色匹配三种模式，观察速度、准确率和连击。',
        en: 'Release, direction-swipe, and color-match modes with speed, accuracy, and streak feedback.',
      ),
      accent: _accent,
      icon: Icons.flash_on_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：选择模式并完成一组反应挑战',
        en: 'Next: choose a mode and finish a reaction set',
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
  const _ReactionColorTarget({
    required this.zhLabel,
    required this.enLabel,
    required this.color,
  });

  final String zhLabel;
  final String enLabel;
  final Color color;

  String label(AppI18n i18n) => pickUiText(i18n, zh: zhLabel, en: enLabel);
}

class _ReactionTestCard extends StatefulWidget {
  const _ReactionTestCard();

  @override
  State<_ReactionTestCard> createState() => _ReactionTestCardState();
}

class _ReactionTestCardState extends State<_ReactionTestCard> {
  static const Color _accent = ReactionTestPage._accent;
  static const double _directionSwipeThreshold = 34;

  static const List<_ReactionColorTarget> _colorTargets =
      <_ReactionColorTarget>[
        _ReactionColorTarget(
          zhLabel: '红色',
          enLabel: 'Red',
          color: Color(0xFFD94B4B),
        ),
        _ReactionColorTarget(
          zhLabel: '蓝色',
          enLabel: 'Blue',
          color: Color(0xFF3D6FD8),
        ),
        _ReactionColorTarget(
          zhLabel: '绿色',
          enLabel: 'Green',
          color: Color(0xFF2F9E68),
        ),
        _ReactionColorTarget(
          zhLabel: '黄色',
          enLabel: 'Yellow',
          color: Color(0xFFE0B43A),
        ),
        _ReactionColorTarget(
          zhLabel: '紫色',
          enLabel: 'Purple',
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
    if (_mode != _ReactionMode.direction) {
      return;
    }
    _directionPointerOrigin = event.position;
    _directionPointerActive = true;
    if (_phase == _ReactionPhase.idle ||
        _phase == _ReactionPhase.feedback ||
        _phase == _ReactionPhase.done) {
      _startRound(holding: true);
    }
  }

  void _handleDirectionPointerMove(PointerMoveEvent event) {
    if (!_directionPointerActive || _mode != _ReactionMode.direction) {
      return;
    }
    final origin = _directionPointerOrigin;
    if (origin == null) {
      return;
    }
    final direction = _directionFromDelta(event.position - origin);
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

  void _handleDirectionPointerUp(PointerUpEvent event) {
    if (!_directionPointerActive || _mode != _ReactionMode.direction) {
      return;
    }
    final origin = _directionPointerOrigin;
    final direction = origin == null
        ? null
        : _directionFromDelta(event.position - origin);
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

  void _handleDirectionPointerCancel(PointerCancelEvent event) {
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
        label: pickUiText(i18n, zh: '经典松手', en: 'Release'),
        description: pickUiText(
          i18n,
          zh: '按住等待变绿，立刻松手。',
          en: 'Hold, wait for green, then release.',
        ),
        icon: Icons.front_hand_rounded,
      ),
      _ReactionMode.direction => _ReactionModeSpec(
        label: pickUiText(i18n, zh: '方向滑动', en: 'Direction'),
        description: pickUiText(
          i18n,
          zh: '按住中心，看到箭头后滑向对应方向；也可点 D-pad 方向键。',
          en: 'Hold center, then slide toward the arrow; D-pad taps also work.',
        ),
        icon: Icons.open_with_rounded,
      ),
      _ReactionMode.colorMatch => _ReactionModeSpec(
        label: pickUiText(i18n, zh: '颜色匹配', en: 'Color match'),
        description: pickUiText(
          i18n,
          zh: '舞台变色后，点击下方对应颜色。',
          en: 'When the stage changes color, tap the matching color below.',
        ),
        icon: Icons.palette_rounded,
      ),
    };
  }

  String _paceLabel(AppI18n i18n, _ReactionPace pace) {
    return switch (pace) {
      _ReactionPace.standard => pickUiText(i18n, zh: '标准', en: 'Standard'),
      _ReactionPace.sprint => pickUiText(i18n, zh: '冲刺', en: 'Sprint'),
      _ReactionPace.variable => pickUiText(i18n, zh: '迷惑', en: 'Variable'),
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
            ? pickUiText(i18n, zh: '按住开始', en: 'Hold to start')
            : _mode == _ReactionMode.direction
            ? pickUiText(i18n, zh: '按中心或点方向开始', en: 'Hold center or tap arrow')
            : pickUiText(i18n, zh: '点击颜色开始', en: 'Tap a color to start'),
      _ReactionPhase.waiting =>
        _mode == _ReactionMode.release
            ? pickUiText(i18n, zh: '继续按住', en: 'Keep holding')
            : _mode == _ReactionMode.direction
            ? pickUiText(i18n, zh: '等待箭头', en: 'Wait for arrow')
            : pickUiText(i18n, zh: '等待颜色', en: 'Wait for color'),
      _ReactionPhase.ready =>
        _mode == _ReactionMode.release
            ? pickUiText(i18n, zh: '松手', en: 'Release')
            : _mode == _ReactionMode.direction
            ? pickUiText(i18n, zh: '滑动方向', en: 'Slide direction')
            : pickUiText(i18n, zh: '选颜色', en: 'Pick color'),
      _ReactionPhase.feedback => _latestFeedbackText(i18n),
      _ReactionPhase.done => pickUiText(i18n, zh: '本组完成', en: 'Set complete'),
    };
  }

  String _stageHint(AppI18n i18n) {
    if (_phase == _ReactionPhase.feedback) {
      return pickUiText(
        i18n,
        zh: '继续操作进入下一轮',
        en: 'Repeat the action for the next round',
      );
    }
    if (_phase == _ReactionPhase.done) {
      return pickUiText(
        i18n,
        zh: '可重置，或切换模式开始新挑战',
        en: 'Reset or switch mode for a fresh challenge',
      );
    }
    return _modeSpec(i18n, _mode).description;
  }

  String _latestFeedbackText(AppI18n i18n) {
    if (_attempts.isEmpty) {
      return pickUiText(i18n, zh: '准备好', en: 'Ready');
    }
    final latest = _attempts.last;
    if (latest.success && latest.milliseconds != null) {
      final ms = latest.milliseconds!;
      final rank = ms <= 180
          ? pickUiText(i18n, zh: '闪电', en: 'Lightning')
          : ms <= 260
          ? pickUiText(i18n, zh: '很快', en: 'Sharp')
          : pickUiText(i18n, zh: '已记录', en: 'Saved');
      return '$rank · ${_formatMilliseconds(ms)}';
    }
    if (latest.falseStart) {
      return pickUiText(i18n, zh: '抢跑了', en: 'False start');
    }
    if (latest.wrongDirection) {
      return pickUiText(i18n, zh: '方向错了', en: 'Wrong direction');
    }
    if (latest.wrongColor) {
      return pickUiText(i18n, zh: '颜色错了', en: 'Wrong color');
    }
    return pickUiText(i18n, zh: '未命中', en: 'Missed');
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
            (
              pickUiText(i18n, zh: '轮次', en: 'Rounds'),
              '${_attempts.length}/$_roundTarget',
            ),
            (
              pickUiText(i18n, zh: '平均', en: 'Average'),
              _averageMs == null ? '-' : _formatMilliseconds(_averageMs!),
            ),
            (
              pickUiText(i18n, zh: '最快', en: 'Best'),
              _bestMs == null ? '-' : _formatMilliseconds(_bestMs!),
            ),
            (
              pickUiText(i18n, zh: '准确率', en: 'Accuracy'),
              accuracy == null ? '-' : '$accuracy%',
            ),
            (pickUiText(i18n, zh: '连击', en: 'Streak'), '$_streak'),
            (
              pickUiText(i18n, zh: '超越', en: 'Beat'),
              beat == null ? '-' : '$beat%',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildModes(context, i18n),
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
        _buildSettings(context, i18n),
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
            pickUiText(i18n, zh: '模式', en: 'Modes'),
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
    return GestureDetector(
      key: const ValueKey<String>('reaction_stage'),
      onTapDown: (_) => _handleStageDown(),
      onTapUp: (_) => _handleStageUp(),
      onTapCancel: () {
        if (_mode == _ReactionMode.release) {
          _handleRelease();
        }
      },
      child: AnimatedContainer(
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
      ),
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
          label: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
          style: OutlinedButton.styleFrom(minimumSize: const Size(104, 48)),
        ),
      ],
    );
  }

  String _primaryActionLabel(AppI18n i18n) {
    if (_mode == _ReactionMode.release) {
      return pickUiText(i18n, zh: '使用舞台按住', en: 'Hold the stage');
    }
    if (_phase == _ReactionPhase.done) {
      return pickUiText(i18n, zh: '重开一组', en: 'Restart set');
    }
    return _phase == _ReactionPhase.waiting
        ? pickUiText(i18n, zh: '抢跑判定', en: 'False start')
        : pickUiText(i18n, zh: '开始/下一轮', en: 'Start/next');
  }

  Widget _buildDirectionControls(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    return _HumanPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            pickUiText(i18n, zh: '方向 D-pad', en: 'Direction D-pad'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pickUiText(
              i18n,
              zh: '中心按住等待，信号出现后滑向上、下、左、右。',
              en: 'Hold the center, then slide up, down, left, or right after the signal.',
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
            label: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
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
    return Listener(
      onPointerDown: _handleDirectionPointerDown,
      onPointerMove: _handleDirectionPointerMove,
      onPointerUp: _handleDirectionPointerUp,
      onPointerCancel: _handleDirectionPointerCancel,
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
              pickUiText(i18n, zh: '按住', en: 'Hold center'),
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
            pickUiText(i18n, zh: '颜色按钮', en: 'Color buttons'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pickUiText(
              i18n,
              zh: '先点任意颜色开始，等待舞台变色后再点匹配颜色。',
              en: 'Tap any color to start, then tap the matching color after the stage changes.',
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
            label: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
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
      title: pickUiText(i18n, zh: '反应设置', en: 'Reaction settings'),
      subtitle: pickUiText(
        i18n,
        zh: '切换轮次和信号节奏会重置当前成绩。',
        en: 'Changing rounds or signal pace resets the current set.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            pickUiText(i18n, zh: '轮次数', en: 'Round count'),
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
            pickUiText(i18n, zh: '信号节奏', en: 'Signal pace'),
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
                  pickUiText(i18n, zh: '本组轨迹', en: 'Set trail'),
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
              pickUiText(
                i18n,
                zh: '完成第一轮后，这里会显示每次反应的结果。',
                en: 'Results from each reaction will appear here after the first round.',
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
      return pickUiText(i18n, zh: '抢跑', en: 'Early');
    }
    if (attempt.wrongDirection) {
      return pickUiText(i18n, zh: '错向', en: 'Wrong');
    }
    if (attempt.wrongColor) {
      return pickUiText(i18n, zh: '错色', en: 'Wrong color');
    }
    return pickUiText(i18n, zh: '未中', en: 'Miss');
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
      title: Text(pickUiText(i18n, zh: '反应测试报告', en: 'Reaction test report')),
      accent: accent,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (pickUiText(i18n, zh: '模式', en: 'Mode'), modeLabel),
            (pickUiText(i18n, zh: '节奏', en: 'Pace'), paceLabel),
            (
              pickUiText(i18n, zh: '轮次', en: 'Rounds'),
              '$successCount/$roundTarget',
            ),
            (pickUiText(i18n, zh: '成功', en: 'Successes'), '$successCount'),
            (pickUiText(i18n, zh: '抢跑', en: 'False starts'), '$falseStarts'),
            (
              pickUiText(i18n, zh: '判向错误', en: 'Wrong direction'),
              '$wrongDirections',
            ),
            (pickUiText(i18n, zh: '配色错误', en: 'Wrong color'), '$wrongColors'),
            (pickUiText(i18n, zh: '准确率', en: 'Accuracy'), accuracyText),
            (pickUiText(i18n, zh: '平均', en: 'Average'), averageText),
            (pickUiText(i18n, zh: '最快', en: 'Best'), bestText),
            (pickUiText(i18n, zh: '超越', en: 'Beat'), beatText),
            (pickUiText(i18n, zh: '连击', en: 'Streak'), '$streak'),
          ],
        ),
        const SizedBox(height: 14),
        _HumanPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                pickUiText(i18n, zh: '分析', en: 'Analysis'),
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
                pickUiText(i18n, zh: '本组轨迹', en: 'Set trail'),
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
      return pickUiText(
        i18n,
        zh: '主要问题是抢跑，先稳住节奏再追速度。',
        en: 'False starts are the main issue. Stabilize timing before chasing pace.',
      );
    }
    if (accuracy != null && accuracy! < 0.7) {
      return pickUiText(
        i18n,
        zh: '准确率还偏低，先把动作做准，再去缩短反应时间。',
        en: 'Accuracy is still low. Make the action clean first, then reduce latency.',
      );
    }
    if ((averageMs ?? 9999) <= 240 && (accuracy ?? 0) >= 0.85) {
      return pickUiText(
        i18n,
        zh: '节奏已经稳定，可以切到更快的节拍继续压缩时间。',
        en: 'The rhythm is steady. Move to a faster pace to keep trimming latency.',
      );
    }
    if (wrongDirections > 0 || wrongColors > 0) {
      return pickUiText(
        i18n,
        zh: '错误多半来自判向或配色，下一轮先固定单一模式再提速。',
        en: 'Most misses come from direction or color choice. Practice one mode cleanly before speeding up.',
      );
    }
    return pickUiText(
      i18n,
      zh: '整体表现平稳，继续保持当前模式即可。',
      en: 'Overall performance is steady. Keep the current mode and build consistency.',
    );
  }

  String _attemptLabel(AppI18n i18n, _ReactionAttempt attempt) {
    if (attempt.success && attempt.milliseconds != null) {
      return _formatMilliseconds(attempt.milliseconds!);
    }
    if (attempt.falseStart) {
      return pickUiText(i18n, zh: '抢跑', en: 'Early');
    }
    if (attempt.wrongDirection) {
      return pickUiText(i18n, zh: '错向', en: 'Wrong');
    }
    if (attempt.wrongColor) {
      return pickUiText(i18n, zh: '错色', en: 'Wrong color');
    }
    return pickUiText(i18n, zh: '未中', en: 'Miss');
  }
}

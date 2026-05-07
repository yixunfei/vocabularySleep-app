part of 'toolbox_human_tests.dart';

class TimePerceptionTestPage extends StatelessWidget {
  const TimePerceptionTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '时间感知测试', en: 'Time perception'),
      subtitle: pickUiText(
        i18n,
        zh: '启动后按随机目标时刻依次点击时间按钮，测试连续时间感知。',
        en: 'Start and tap randomized target-time buttons in sequence.',
      ),
      accent: const Color(0xFF4D8C9E),
      icon: Icons.timer_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：开始后盯住当前目标时间',
        en: 'Next: start, then watch the current target time',
      ),
      child: const _TimePerceptionTestCard(),
    );
  }
}

enum _TimePerceptionUnit { minutes, seconds, milliseconds, microseconds }

extension _TimePerceptionUnitText on _TimePerceptionUnit {
  String label(AppI18n i18n) {
    return switch (this) {
      _TimePerceptionUnit.minutes => pickUiText(i18n, zh: '分钟', en: 'Minutes'),
      _TimePerceptionUnit.seconds => pickUiText(i18n, zh: '秒', en: 'Seconds'),
      _TimePerceptionUnit.milliseconds => pickUiText(
        i18n,
        zh: '毫秒',
        en: 'Milliseconds',
      ),
      _TimePerceptionUnit.microseconds => pickUiText(
        i18n,
        zh: '微秒',
        en: 'Microseconds',
      ),
    };
  }

  String shortLabel(AppI18n i18n) {
    return switch (this) {
      _TimePerceptionUnit.minutes => pickUiText(i18n, zh: '分', en: 'min'),
      _TimePerceptionUnit.seconds => pickUiText(i18n, zh: '秒', en: 's'),
      _TimePerceptionUnit.milliseconds => 'ms',
      _TimePerceptionUnit.microseconds => 'us',
    };
  }

  int get stepMicros {
    return switch (this) {
      _TimePerceptionUnit.minutes => const Duration(minutes: 1).inMicroseconds,
      _TimePerceptionUnit.seconds => const Duration(seconds: 1).inMicroseconds,
      _TimePerceptionUnit.milliseconds => const Duration(
        milliseconds: 1,
      ).inMicroseconds,
      _TimePerceptionUnit.microseconds => 1,
    };
  }
}

class _TimePerceptionClickResult {
  const _TimePerceptionClickResult({
    required this.target,
    required this.actual,
  });

  final Duration target;
  final Duration actual;

  Duration get signedError => actual - target;
}

class _TimePerceptionTestCard extends StatefulWidget {
  const _TimePerceptionTestCard();

  @override
  State<_TimePerceptionTestCard> createState() =>
      _TimePerceptionTestCardState();
}

class _TimePerceptionTestCardState extends State<_TimePerceptionTestCard> {
  static const Color _accent = Color(0xFF4D8C9E);
  static const Color _success = Color(0xFF3D8B63);

  final math.Random _random = math.Random();
  final Stopwatch _stopwatch = Stopwatch();
  int _nodeCount = 3;
  bool _continuousNodes = false;
  Duration _maxTargetTime = const Duration(seconds: 12);
  _TimePerceptionUnit _minimumUnit = _TimePerceptionUnit.seconds;
  List<Duration> _targets = const <Duration>[];
  final List<_TimePerceptionClickResult> _results =
      <_TimePerceptionClickResult>[];
  int _index = 0;
  int _wrongTap = 0;
  bool _running = false;
  bool _countingDown = false;
  bool _done = false;
  int? _countdownValue;
  int _startToken = 0;

  List<Duration> _buildTargets() {
    final unitMicros = _minimumUnit.stepMicros;
    final minStep = _ceilDiv(
      _minimumFirstTargetTime.inMicroseconds,
      unitMicros,
    );
    final maxStep = _maxTargetTime.inMicroseconds ~/ unitMicros;
    final available = maxStep - minStep + 1;
    final count = _clampInt(_effectiveNodeCount, 1, available);
    final pickedSteps = <int>{};
    if (available <= 0) {
      return const <Duration>[];
    }
    while (pickedSteps.length < count) {
      pickedSteps.add(minStep + _random.nextInt(available));
    }
    return pickedSteps
        .map((step) => Duration(microseconds: step * unitMicros))
        .toList()
      ..sort();
  }

  Future<void> _start() async {
    if (_running || _countingDown) {
      return;
    }
    _normalizeSettings();
    final targets = _buildTargets();
    if (targets.isEmpty) {
      return;
    }
    final token = ++_startToken;
    setState(() {
      _targets = targets;
      _results.clear();
      _index = 0;
      _wrongTap = 0;
      _running = false;
      _countingDown = true;
      _countdownValue = 3;
      _done = false;
    });
    for (var value = 3; value >= 1; value -= 1) {
      if (!mounted || token != _startToken) {
        return;
      }
      setState(() => _countdownValue = value);
      await Future<void>.delayed(const Duration(milliseconds: 720));
    }
    if (!mounted || token != _startToken) {
      return;
    }
    _stopwatch
      ..reset()
      ..start();
    setState(() {
      _countingDown = false;
      _countdownValue = null;
      _running = true;
    });
  }

  void _tapNode(int index) {
    if (!_running) {
      return;
    }
    if (index != _index) {
      setState(() => _wrongTap += 1);
      return;
    }
    final actual = _stopwatch.elapsed;
    _results.add(
      _TimePerceptionClickResult(target: _targets[index], actual: actual),
    );
    if (_results.length >= _targets.length) {
      _stopwatch.stop();
      setState(() {
        _index = _targets.length;
        _running = false;
        _done = true;
      });
      return;
    }
    setState(() => _index += 1);
  }

  void _reset() {
    _startToken += 1;
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _targets = const <Duration>[];
      _results.clear();
      _index = 0;
      _wrongTap = 0;
      _running = false;
      _countingDown = false;
      _countdownValue = null;
      _done = false;
    });
  }

  double? _averageErrorSeconds() {
    if (_results.length != _targets.length || _targets.isEmpty) {
      return null;
    }
    var sum = 0.0;
    for (final result in _results) {
      sum += result.signedError.inMicroseconds.abs() / 1000000;
    }
    return sum / _targets.length;
  }

  Duration get _minimumFirstTargetTime {
    return _minimumUnit == _TimePerceptionUnit.minutes
        ? const Duration(minutes: 1)
        : const Duration(seconds: 1);
  }

  Duration _minimumMaxTargetTime({
    required _TimePerceptionUnit unit,
    required int nodeCount,
  }) {
    final firstTarget = unit == _TimePerceptionUnit.minutes
        ? const Duration(minutes: 1)
        : const Duration(seconds: 1);
    final spacing = Duration(microseconds: unit.stepMicros * (nodeCount - 1));
    final minimum = firstTarget + spacing;
    if (unit == _TimePerceptionUnit.minutes) {
      return minimum;
    }
    return minimum < const Duration(seconds: 3)
        ? const Duration(seconds: 3)
        : minimum;
  }

  Duration _maximumMaxTargetTime(_TimePerceptionUnit unit) {
    return unit == _TimePerceptionUnit.minutes
        ? const Duration(minutes: 10)
        : const Duration(seconds: 60);
  }

  Duration _normalizedMaxTargetTime(
    _TimePerceptionUnit unit,
    Duration value,
    int nodeCount,
  ) {
    final min = _minimumMaxTargetTime(unit: unit, nodeCount: nodeCount);
    final max = _maximumMaxTargetTime(unit);
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }

  void _normalizeSettings() {
    _maxTargetTime = _normalizedMaxTargetTime(
      _minimumUnit,
      _maxTargetTime,
      _effectiveNodeCount,
    );
  }

  int get _effectiveNodeCount => _continuousNodes ? _nodeCount : 1;

  int _plannedTargetCount() {
    final unitMicros = _minimumUnit.stepMicros;
    final minStep = _ceilDiv(
      _minimumFirstTargetTime.inMicroseconds,
      unitMicros,
    );
    final maxStep = _maxTargetTime.inMicroseconds ~/ unitMicros;
    final available = maxStep - minStep + 1;
    return _clampInt(_effectiveNodeCount, 1, available);
  }

  void _setNodeCount(int value) {
    setState(() {
      _nodeCount = value;
      _normalizeSettings();
    });
  }

  void _setContinuousNodes(bool value) {
    setState(() {
      _continuousNodes = value;
      _normalizeSettings();
    });
  }

  void _setMinimumUnit(_TimePerceptionUnit unit) {
    setState(() {
      _minimumUnit = unit;
      _normalizeSettings();
    });
  }

  void _setMaxTargetScalar(double value) {
    final microsPerScalar = _minimumUnit == _TimePerceptionUnit.minutes
        ? const Duration(minutes: 1).inMicroseconds
        : const Duration(seconds: 1).inMicroseconds;
    setState(() {
      _maxTargetTime = Duration(
        microseconds: (value * microsPerScalar).round(),
      );
      _normalizeSettings();
    });
  }

  double _maxTargetScalar(Duration duration) {
    if (_minimumUnit == _TimePerceptionUnit.minutes) {
      return duration.inMicroseconds /
          const Duration(minutes: 1).inMicroseconds;
    }
    return duration.inMicroseconds / const Duration(seconds: 1).inMicroseconds;
  }

  String _formatDuration(Duration duration, AppI18n i18n) {
    return switch (_minimumUnit) {
      _TimePerceptionUnit.minutes =>
        '${(duration.inMicroseconds / const Duration(minutes: 1).inMicroseconds).toStringAsFixed(2)} ${_minimumUnit.shortLabel(i18n)}',
      _TimePerceptionUnit.seconds =>
        '${(duration.inMicroseconds / const Duration(seconds: 1).inMicroseconds).toStringAsFixed(2)} ${_minimumUnit.shortLabel(i18n)}',
      _TimePerceptionUnit.milliseconds =>
        '${(duration.inMicroseconds / const Duration(milliseconds: 1).inMicroseconds).round()} ${_minimumUnit.shortLabel(i18n)}',
      _TimePerceptionUnit.microseconds =>
        '${duration.inMicroseconds} ${_minimumUnit.shortLabel(i18n)}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final avgError = _averageErrorSeconds();
    final plannedTargetCount = _targets.isEmpty
        ? _plannedTargetCount()
        : _targets.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(i18n, zh: '节点', en: 'Nodes'),
              '${_results.length}/$plannedTargetCount',
            ),
            (
              pickUiText(i18n, zh: '平均误差', en: 'Avg error'),
              avgError == null ? '-' : _formatSeconds(avgError),
            ),
            (pickUiText(i18n, zh: '误触', en: 'Wrong taps'), '$_wrongTap'),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                _running
                    ? pickUiText(
                        i18n,
                        zh: '当前目标：${_formatDuration(_targets[_index], i18n)}',
                        en: 'Current target: ${_formatDuration(_targets[_index], i18n)}',
                      )
                    : _done
                    ? pickUiText(
                        i18n,
                        zh: '本轮完成。绿色按钮表示已点击，误差按实际点击时间计算。',
                        en: 'Round complete. Green buttons show completed taps and errors use actual tap time.',
                      )
                    : pickUiText(
                        i18n,
                        zh: '开始时随机生成目标时间；按高亮按钮，在目标时刻点击。',
                        en: 'Target times are randomized on start. Tap the highlighted button at its target moment.',
                      ),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                pickUiText(
                  i18n,
                  zh: '按钮不显示编号，顺序由目标时间从早到晚自然排列；点击后会在同一按钮内显示目标时间、实际点击时间和误差。',
                  en: 'Buttons do not show numbers. They are sorted by target time; after tapping, the same button shows target time, actual tap time, and error.',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              _HumanSettingsSection(
                title: pickUiText(i18n, zh: '设置项', en: 'Settings'),
                subtitle: pickUiText(
                  i18n,
                  zh: '调整目标数量、最大时间和随机粒度',
                  en: 'Adjust target count, maximum time, and randomization unit',
                ),
                initiallyExpanded: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        pickUiText(i18n, zh: '连续节点', en: 'Continuous nodes'),
                      ),
                      subtitle: Text(
                        pickUiText(
                          i18n,
                          zh: '关闭时只生成 1 个目标；开启后按多个随机时刻依次点击。',
                          en: 'Off creates 1 target. On asks you to tap multiple randomized moments in order.',
                        ),
                      ),
                      value: _continuousNodes,
                      onChanged: (_running || _countingDown)
                          ? null
                          : _setContinuousNodes,
                    ),
                    if (_continuousNodes) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        pickUiText(i18n, zh: '连续节点数', en: 'Node count'),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Slider(
                        value: _nodeCount.toDouble(),
                        min: 2,
                        max: 6,
                        divisions: 4,
                        label: '$_nodeCount',
                        onChanged: (_running || _countingDown)
                            ? null
                            : (value) => _setNodeCount(value.round()),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      pickUiText(i18n, zh: '最大目标时间', en: 'Maximum target time'),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Slider(
                      value: _maxTargetScalar(_maxTargetTime),
                      min: _maxTargetScalar(
                        _minimumMaxTargetTime(
                          unit: _minimumUnit,
                          nodeCount: _effectiveNodeCount,
                        ),
                      ),
                      max: _maxTargetScalar(
                        _maximumMaxTargetTime(_minimumUnit),
                      ),
                      divisions: _minimumUnit == _TimePerceptionUnit.minutes
                          ? 10 - _effectiveNodeCount
                          : 114,
                      label: _formatDuration(_maxTargetTime, i18n),
                      onChanged: (_running || _countingDown)
                          ? null
                          : _setMaxTargetScalar,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pickUiText(i18n, zh: '最小随机单位', en: 'Minimum unit'),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _TimePerceptionUnit.values
                          .map((unit) {
                            return ChoiceChip(
                              label: Text(unit.label(i18n)),
                              selected: _minimumUnit == unit,
                              onSelected: (_running || _countingDown)
                                  ? null
                                  : (_) => _setMinimumUnit(unit),
                            );
                          })
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      pickUiText(
                        i18n,
                        zh: '当前会在 ${_formatDuration(_minimumFirstTargetTime, i18n)} 到 ${_formatDuration(_maxTargetTime, i18n)} 之间随机生成 $plannedTargetCount 个目标；单位越细，目标时间越不容易落在整秒上。',
                        en: 'This will randomize $plannedTargetCount targets between ${_formatDuration(_minimumFirstTargetTime, i18n)} and ${_formatDuration(_maxTargetTime, i18n)}. Finer units make targets less likely to land on whole seconds.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_countingDown)
                _TimePerceptionCountdownStage(value: _countdownValue ?? 3)
              else if (_targets.isEmpty)
                _TimePerceptionEmptyStage(
                  text: pickUiText(
                    i18n,
                    zh: '点击开始后，这里会出现随机目标时间按钮。',
                    en: 'Randomized target-time buttons will appear here after start.',
                  ),
                )
              else
                _TimePerceptionTargetGrid(
                  targets: _targets,
                  results: _results,
                  activeIndex: _running ? _index : -1,
                  unit: _minimumUnit,
                  onTap: _running ? _tapNode : null,
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _HumanActionButton(
                    label: _countingDown
                        ? pickUiText(i18n, zh: '倒计时', en: 'Countdown')
                        : _running
                        ? pickUiText(i18n, zh: '进行中', en: 'Running')
                        : pickUiText(i18n, zh: '开始', en: 'Start'),
                    icon: _countingDown
                        ? Icons.hourglass_top_rounded
                        : _running
                        ? Icons.timer_rounded
                        : Icons.play_arrow_rounded,
                    onPressed: (_running || _countingDown)
                        ? null
                        : () => unawaited(_start()),
                  ),
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_done) ...<Widget>[
          const SizedBox(height: 12),
          _HumanPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  pickUiText(i18n, zh: '结果说明', en: 'Result notes'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                ...List<Widget>.generate(_results.length, (index) {
                  final result = _results[index];
                  final error = result.signedError.abs();
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == _results.length - 1 ? 0 : 8,
                    ),
                    child: Text(
                      pickUiText(
                        i18n,
                        zh: '目标 ${_formatDuration(result.target, i18n)}；实际 ${_formatDuration(result.actual, i18n)}；误差 ${_formatDuration(error, i18n)}。',
                        en: 'Target ${_formatDuration(result.target, i18n)}; actual ${_formatDuration(result.actual, i18n)}; error ${_formatDuration(error, i18n)}.',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TimePerceptionEmptyStage extends StatelessWidget {
  const _TimePerceptionEmptyStage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 104),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.35,
        ),
      ),
    );
  }
}

class _TimePerceptionCountdownStage extends StatelessWidget {
  const _TimePerceptionCountdownStage({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            _TimePerceptionTestCardState._accent.withValues(alpha: 0.20),
            theme.colorScheme.surfaceContainerLow,
          ],
        ),
        border: Border.all(
          color: _TimePerceptionTestCardState._accent.withValues(alpha: 0.28),
        ),
      ),
      child: TweenAnimationBuilder<double>(
        key: ValueKey<int>(value),
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        builder: (context, progress, child) {
          return Opacity(
            opacity: (1 - progress * 0.12).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.82 + progress * 0.18,
              child: Text(
                '$value',
                style: theme.textTheme.displayLarge?.copyWith(
                  color: _TimePerceptionTestCardState._accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 88,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimePerceptionTargetGrid extends StatelessWidget {
  const _TimePerceptionTargetGrid({
    required this.targets,
    required this.results,
    required this.activeIndex,
    required this.unit,
    required this.onTap,
  });

  final List<Duration> targets;
  final List<_TimePerceptionClickResult> results;
  final int activeIndex;
  final _TimePerceptionUnit unit;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 430 ? 3 : 2;
        final spacing = 8.0;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List<Widget>.generate(targets.length, (index) {
            final result = index < results.length ? results[index] : null;
            return SizedBox(
              width: tileWidth,
              child: _TimePerceptionTargetTile(
                target: targets[index],
                result: result,
                active: index == activeIndex,
                unit: unit,
                onTap: onTap == null ? null : () => onTap!(index),
              ),
            );
          }),
        );
      },
    );
  }
}

class _TimePerceptionTargetTile extends StatelessWidget {
  const _TimePerceptionTargetTile({
    required this.target,
    required this.result,
    required this.active,
    required this.unit,
    required this.onTap,
  });

  final Duration target;
  final _TimePerceptionClickResult? result;
  final bool active;
  final _TimePerceptionUnit unit;
  final VoidCallback? onTap;

  bool get reached => result != null;

  String _format(Duration duration, AppI18n i18n) {
    return switch (unit) {
      _TimePerceptionUnit.minutes =>
        '${(duration.inMicroseconds / const Duration(minutes: 1).inMicroseconds).toStringAsFixed(2)} ${unit.shortLabel(i18n)}',
      _TimePerceptionUnit.seconds =>
        '${(duration.inMicroseconds / const Duration(seconds: 1).inMicroseconds).toStringAsFixed(2)} ${unit.shortLabel(i18n)}',
      _TimePerceptionUnit.milliseconds =>
        '${(duration.inMicroseconds / const Duration(milliseconds: 1).inMicroseconds).round()} ${unit.shortLabel(i18n)}',
      _TimePerceptionUnit.microseconds =>
        '${duration.inMicroseconds} ${unit.shortLabel(i18n)}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final baseColor = reached
        ? _TimePerceptionTestCardState._success
        : active
        ? _TimePerceptionTestCardState._accent
        : colorScheme.outline;
    final backgroundColor = reached
        ? _TimePerceptionTestCardState._success.withValues(alpha: 0.14)
        : active
        ? _TimePerceptionTestCardState._accent.withValues(alpha: 0.18)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.42);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: reached ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 118),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: backgroundColor,
              border: Border.all(
                color: active || reached
                    ? baseColor.withValues(alpha: 0.54)
                    : colorScheme.outlineVariant,
                width: active ? 1.6 : 1,
              ),
              boxShadow: active
                  ? <BoxShadow>[
                      BoxShadow(
                        color: baseColor.withValues(alpha: 0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      reached
                          ? Icons.check_circle_rounded
                          : active
                          ? Icons.touch_app_rounded
                          : Icons.schedule_rounded,
                      color: baseColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        reached
                            ? pickUiText(i18n, zh: '已点击', en: 'Tapped')
                            : active
                            ? pickUiText(i18n, zh: '待点击', en: 'Tap now')
                            : pickUiText(i18n, zh: '候选目标', en: 'Pending'),
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: baseColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _TimePerceptionTileLine(
                  label: pickUiText(i18n, zh: '目标', en: 'Target'),
                  value: _format(target, i18n),
                ),
                if (result != null) ...<Widget>[
                  const SizedBox(height: 4),
                  _TimePerceptionTileLine(
                    label: pickUiText(i18n, zh: '实际', en: 'Actual'),
                    value: _format(result!.actual, i18n),
                  ),
                  const SizedBox(height: 4),
                  _TimePerceptionTileLine(
                    label: pickUiText(i18n, zh: '误差', en: 'Error'),
                    value: _format(result!.signedError.abs(), i18n),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimePerceptionTileLine extends StatelessWidget {
  const _TimePerceptionTileLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: '$label ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

int _ceilDiv(int a, int b) => (a + b - 1) ~/ b;

int _clampInt(int value, int min, int max) {
  if (max < min) {
    return min;
  }
  if (value < min) {
    return min;
  }
  if (value > max) {
    return max;
  }
  return value;
}

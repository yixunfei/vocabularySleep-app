part of 'toolbox_human_tests.dart';

enum _ReactionPhase { idle, waiting, ready, tooSoon, result, done }

class ReactionTestPage extends StatelessWidget {
  const ReactionTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '反应测试', en: 'Reaction test'),
      subtitle: pickUiText(
        i18n,
        zh: '等待舞台变绿后立刻点击，5 次后显示平均反应时间。',
        en: 'Wait until the stage turns green, then tap as fast as you can. Five trials are averaged.',
      ),
      accent: const Color(0xFF2F8D8E),
      icon: Icons.flash_on_rounded,
      status: pickUiText(i18n, zh: '下一步：点击开始测试', en: 'Next: tap to start'),
      child: const _ReactionTestCard(),
    );
  }
}

class _ReactionTestCard extends StatefulWidget {
  const _ReactionTestCard();

  @override
  State<_ReactionTestCard> createState() => _ReactionTestCardState();
}

class _ReactionTestCardState extends State<_ReactionTestCard> {
  final math.Random _random = math.Random();
  final Stopwatch _stopwatch = Stopwatch();
  final List<int> _results = <int>[];
  Timer? _timer;
  _ReactionPhase _phase = _ReactionPhase.idle;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRound() {
    _timer?.cancel();
    _stopwatch.stop();
    _stopwatch.reset();
    setState(() => _phase = _ReactionPhase.waiting);
    final delay = Duration(milliseconds: 900 + _random.nextInt(2600));
    _timer = Timer(delay, () {
      if (!mounted) {
        return;
      }
      _stopwatch
        ..reset()
        ..start();
      setState(() => _phase = _ReactionPhase.ready);
    });
  }

  void _reset() {
    _timer?.cancel();
    _stopwatch.stop();
    _stopwatch.reset();
    setState(() {
      _results.clear();
      _phase = _ReactionPhase.idle;
    });
  }

  void _handleTap() {
    if (_phase == _ReactionPhase.waiting) {
      _timer?.cancel();
      setState(() => _phase = _ReactionPhase.tooSoon);
      return;
    }
    if (_phase == _ReactionPhase.ready) {
      _stopwatch.stop();
      _results.add(_stopwatch.elapsedMilliseconds);
      setState(() {
        _phase = _results.length >= 5
            ? _ReactionPhase.done
            : _ReactionPhase.result;
      });
      return;
    }
    if (_phase == _ReactionPhase.done) {
      _reset();
      return;
    }
    _startRound();
  }

  Color _stageColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (_phase) {
      _ReactionPhase.ready => const Color(0xFF3FA76B),
      _ReactionPhase.waiting => const Color(0xFFC2614E),
      _ReactionPhase.tooSoon => colorScheme.errorContainer,
      _ReactionPhase.done => colorScheme.primaryContainer,
      _ => colorScheme.surfaceContainerHigh,
    };
  }

  String _stageText(AppI18n i18n) {
    return switch (_phase) {
      _ReactionPhase.idle => pickUiText(i18n, zh: '点击开始', en: 'Tap to start'),
      _ReactionPhase.waiting => pickUiText(
        i18n,
        zh: '等待变绿',
        en: 'Wait for green',
      ),
      _ReactionPhase.ready => pickUiText(i18n, zh: '现在点击', en: 'Tap now'),
      _ReactionPhase.tooSoon => pickUiText(
        i18n,
        zh: '太早了，再来一次',
        en: 'Too soon. Try again',
      ),
      _ReactionPhase.result => pickUiText(
        i18n,
        zh: '已记录，继续下一次',
        en: 'Saved. Continue',
      ),
      _ReactionPhase.done => pickUiText(
        i18n,
        zh: '完成，点击重置',
        en: 'Done. Tap to reset',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final average = _results.isEmpty
        ? 0
        : _results.reduce((a, b) => a + b) / _results.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (pickUiText(i18n, zh: '次数', en: 'Trials'), '${_results.length}/5'),
            (
              pickUiText(i18n, zh: '平均', en: 'Average'),
              _results.isEmpty ? '-' : _formatMilliseconds(average),
            ),
            (
              pickUiText(i18n, zh: '最近', en: 'Latest'),
              _results.isEmpty ? '-' : _formatMilliseconds(_results.last),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _handleTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            height: 260,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _stageColor(context),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              _stageText(i18n),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.restart_alt_rounded),
          label: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
        ),
      ],
    );
  }
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
        zh: '连续点击出现的目标，完成 20 次命中后显示平均间隔。',
        en: 'Tap each target as it appears. The test ends after 20 hits.',
      ),
      accent: const Color(0xFFC24D5A),
      icon: Icons.adjust_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：点击开始后追踪目标',
        en: 'Next: start and track targets',
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

class _AimTestCardState extends State<_AimTestCard> {
  static const int _targetCount = 20;
  final math.Random _random = math.Random();
  final Stopwatch _stopwatch = Stopwatch();
  Offset _target = const Offset(0.5, 0.5);
  int _hits = 0;
  bool _running = false;
  int? _finalMilliseconds;

  void _newTarget() {
    _target = Offset(
      0.08 + _random.nextDouble() * 0.84,
      0.10 + _random.nextDouble() * 0.78,
    );
  }

  void _start() {
    setState(() {
      _hits = 0;
      _finalMilliseconds = null;
      _running = true;
      _newTarget();
    });
    _stopwatch
      ..reset()
      ..start();
  }

  void _hit() {
    if (!_running) {
      return;
    }
    if (_hits + 1 >= _targetCount) {
      _stopwatch.stop();
      setState(() {
        _hits = _targetCount;
        _finalMilliseconds = _stopwatch.elapsedMilliseconds;
        _running = false;
      });
      return;
    }
    setState(() {
      _hits += 1;
      _newTarget();
    });
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final average = _finalMilliseconds == null
        ? null
        : _finalMilliseconds! / _targetCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (pickUiText(i18n, zh: '命中', en: 'Hits'), '$_hits/$_targetCount'),
            (
              pickUiText(i18n, zh: '平均间隔', en: 'Avg interval'),
              average == null ? '-' : _formatMilliseconds(average),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          padding: EdgeInsets.zero,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final height = math.min(360.0, constraints.maxWidth * 0.78);
              return SizedBox(
                height: height,
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                    ),
                    if (_running)
                      Positioned(
                        left: _target.dx * (constraints.maxWidth - 54),
                        top: _target.dy * (height - 54),
                        child: GestureDetector(
                          onTap: _hit,
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(
                                0xFFC24D5A,
                              ).withValues(alpha: 0.18),
                              border: Border.all(
                                color: const Color(0xFFC24D5A),
                                width: 3,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFC24D5A),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Center(
                        child: _HumanActionButton(
                          label: pickUiText(i18n, zh: '开始', en: 'Start'),
                          icon: Icons.play_arrow_rounded,
                          onPressed: _start,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class TapSpeedTestPage extends StatelessWidget {
  const TapSpeedTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '手速测试', en: 'Tap speed'),
      subtitle: pickUiText(
        i18n,
        zh: '10 秒内尽可能多次点击同一个按钮。',
        en: 'Tap the same button as many times as possible in 10 seconds.',
      ),
      accent: const Color(0xFFC05180),
      icon: Icons.touch_app_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：开始后连续点击',
        en: 'Next: start and keep tapping',
      ),
      child: const _TapSpeedTestCard(),
    );
  }
}

class _TapSpeedTestCard extends StatefulWidget {
  const _TapSpeedTestCard();

  @override
  State<_TapSpeedTestCard> createState() => _TapSpeedTestCardState();
}

class _TapSpeedTestCardState extends State<_TapSpeedTestCard> {
  static const Duration _duration = Duration(seconds: 10);
  Timer? _timer;
  int _count = 0;
  int _remainingTenths = _duration.inMilliseconds ~/ 100;
  bool _running = false;
  bool _done = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _count = 0;
      _remainingTenths = _duration.inMilliseconds ~/ 100;
      _running = true;
      _done = false;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        return;
      }
      if (_remainingTenths <= 1) {
        timer.cancel();
        setState(() {
          _remainingTenths = 0;
          _running = false;
          _done = true;
        });
        return;
      }
      setState(() => _remainingTenths -= 1);
    });
  }

  void _tap() {
    if (!_running) {
      return;
    }
    setState(() => _count += 1);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final secondsLeft = _remainingTenths / 10;
    final cps = _done ? _count / 10 : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (pickUiText(i18n, zh: '点击', en: 'Taps'), '$_count'),
            (
              pickUiText(i18n, zh: '剩余', en: 'Left'),
              _formatSeconds(secondsLeft),
            ),
            (
              pickUiText(i18n, zh: '每秒', en: 'Per sec'),
              _done ? cps.toStringAsFixed(1) : '-',
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _running ? _tap : _start,
          child: Container(
            height: 240,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color(0xFFC05180).withValues(alpha: 0.14),
              border: Border.all(
                color: const Color(0xFFC05180).withValues(alpha: 0.22),
              ),
            ),
            child: Text(
              _running
                  ? pickUiText(i18n, zh: '点击', en: 'Tap')
                  : pickUiText(i18n, zh: '点击开始', en: 'Tap to start'),
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}

class TimePerceptionTestPage extends StatelessWidget {
  const TimePerceptionTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '时间感知测试', en: 'Time perception'),
      subtitle: pickUiText(
        i18n,
        zh: '点击开始后在心里估算 5 秒，再点击停止。',
        en: 'Start, estimate 5 seconds in your head, then stop.',
      ),
      accent: const Color(0xFF4D8C9E),
      icon: Icons.timer_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：开始后不要看钟',
        en: 'Next: start without watching a clock',
      ),
      child: const _TimePerceptionTestCard(),
    );
  }
}

class _TimePerceptionTestCard extends StatefulWidget {
  const _TimePerceptionTestCard();

  @override
  State<_TimePerceptionTestCard> createState() =>
      _TimePerceptionTestCardState();
}

class _TimePerceptionTestCardState extends State<_TimePerceptionTestCard> {
  final Stopwatch _stopwatch = Stopwatch();
  bool _running = false;
  Duration? _last;

  void _toggle() {
    if (_running) {
      _stopwatch.stop();
      setState(() {
        _last = _stopwatch.elapsed;
        _running = false;
      });
      return;
    }
    _stopwatch
      ..reset()
      ..start();
    setState(() {
      _last = null;
      _running = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final diff = _last == null
        ? null
        : (_last!.inMilliseconds - 5000).abs() / 1000;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (pickUiText(i18n, zh: '目标', en: 'Target'), _formatSeconds(5)),
            (
              pickUiText(i18n, zh: '结果', en: 'Result'),
              _last == null
                  ? '-'
                  : _formatSeconds(_last!.inMilliseconds / 1000),
            ),
            (
              pickUiText(i18n, zh: '误差', en: 'Error'),
              diff == null ? '-' : _formatSeconds(diff),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            children: <Widget>[
              Text(
                _running
                    ? pickUiText(
                        i18n,
                        zh: '正在计时，感觉到 5 秒就停止',
                        en: 'Running. Stop when 5 seconds feel right',
                      )
                    : pickUiText(i18n, zh: '准备好后开始', en: 'Start when ready'),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              _HumanActionButton(
                label: _running
                    ? pickUiText(i18n, zh: '停止', en: 'Stop')
                    : pickUiText(i18n, zh: '开始', en: 'Start'),
                icon: _running ? Icons.stop_rounded : Icons.play_arrow_rounded,
                onPressed: _toggle,
              ),
            ],
          ),
        ),
      ],
    );
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
        zh: '在移动舞台中追踪目标，命中 12 次完成一轮。',
        en: 'Track the moving target and land 12 hits to finish.',
      ),
      accent: const Color(0xFFB55D42),
      icon: Icons.center_focus_strong_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：开始后点击移动圆心',
        en: 'Next: start and tap the moving center',
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
  static const int _targetHits = 12;
  late final AnimationController _controller;
  int _hits = 0;
  int _misses = 0;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _hits = 0;
      _misses = 0;
      _running = true;
    });
    _controller
      ..reset()
      ..repeat(reverse: true);
  }

  Offset _targetCenter(Size size) {
    final t = _controller.value;
    return Offset(
      40 + t * (size.width - 80),
      size.height * (0.50 + math.sin(t * math.pi * 2) * 0.22),
    );
  }

  void _tap(Size size, Offset localPosition) {
    if (!_running) {
      return;
    }
    final center = _targetCenter(size);
    if ((localPosition - center).distance <= 34) {
      if (_hits + 1 >= _targetHits) {
        _controller.stop();
        setState(() {
          _hits = _targetHits;
          _running = false;
        });
      } else {
        setState(() => _hits += 1);
      }
    } else {
      setState(() => _misses += 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final total = _hits + _misses;
    final accuracy = total == 0 ? 0 : _hits / total * 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (pickUiText(i18n, zh: '命中', en: 'Hits'), '$_hits/$_targetHits'),
            (pickUiText(i18n, zh: '失误', en: 'Misses'), '$_misses'),
            (
              pickUiText(i18n, zh: '准确率', en: 'Accuracy'),
              total == 0 ? '-' : '${accuracy.round()}%',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          padding: EdgeInsets.zero,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(
                constraints.maxWidth,
                math.min(340, constraints.maxWidth * 0.72),
              );
              return GestureDetector(
                onTapDown: _running
                    ? (details) => _tap(size, details.localPosition)
                    : null,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final center = _targetCenter(size);
                      return Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                color: Theme.of(context).colorScheme.surface,
                              ),
                            ),
                          ),
                          if (_running)
                            Positioned(
                              left: center.dx - 28,
                              top: center.dy - 28,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(
                                    0xFFB55D42,
                                  ).withValues(alpha: 0.18),
                                  border: Border.all(
                                    color: const Color(0xFFB55D42),
                                    width: 3,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFB55D42),
                                  ),
                                ),
                              ),
                            )
                          else
                            Center(
                              child: _HumanActionButton(
                                label: pickUiText(i18n, zh: '开始', en: 'Start'),
                                icon: Icons.play_arrow_rounded,
                                onPressed: _start,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

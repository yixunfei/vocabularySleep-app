part of 'toolbox_human_tests.dart';

class TapSpeedTestPage extends StatelessWidget {
  const TapSpeedTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '手速测试', en: 'Tap speed'),
      subtitle: pickUiText(
        i18n,
        zh: '在经典连点、目标追击和节奏命中模式中测试点击速度、稳定性与准确率。',
        en: 'Measure tap speed, stability, and accuracy across classic, target chase, and rhythm modes.',
      ),
      accent: const Color(0xFFC05180),
      icon: Icons.touch_app_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：选择模式后开始挑战',
        en: 'Next: choose a mode and start',
      ),
      child: const _TapSpeedTestCard(),
    );
  }
}

enum _TapSpeedMode { classic, targetChase, rhythm }

class _TapSpeedTestCard extends StatefulWidget {
  const _TapSpeedTestCard();

  @override
  State<_TapSpeedTestCard> createState() => _TapSpeedTestCardState();
}

class _TapSpeedTestCardState extends State<_TapSpeedTestCard> {
  static const Color _accent = Color(0xFFC05180);
  final math.Random _random = math.Random();
  Timer? _timer;
  _TapSpeedMode _mode = _TapSpeedMode.classic;
  int _durationSeconds = 10;
  int _count = 0;
  int _attempts = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _remainingTenths = 100;
  int _targetSlot = 4;
  int _rhythmSlot = 4;
  bool _running = false;
  bool _done = false;
  bool? _lastHit;
  int _feedbackSerial = 0;

  int get _totalTenths => _durationSeconds * 10;

  double get _cps => _durationSeconds <= 0 ? 0 : _count / _durationSeconds;

  double get _accuracy => _attempts <= 0 ? 1 : _count / _attempts;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _count = 0;
      _attempts = 0;
      _combo = 0;
      _bestCombo = 0;
      _remainingTenths = _totalTenths;
      _targetSlot = _random.nextInt(9);
      _rhythmSlot = 4;
      _running = true;
      _done = false;
      _lastHit = null;
      _feedbackSerial = 0;
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
        unawaited(_showReport());
        return;
      }
      setState(() {
        _remainingTenths -= 1;
        if (_mode == _TapSpeedMode.rhythm && _remainingTenths % 5 == 0) {
          _rhythmSlot = _random.nextInt(9);
        }
      });
    });
  }

  void _restart() {
    _timer?.cancel();
    setState(() {
      _count = 0;
      _attempts = 0;
      _combo = 0;
      _bestCombo = 0;
      _remainingTenths = _totalTenths;
      _targetSlot = _random.nextInt(9);
      _rhythmSlot = 4;
      _running = false;
      _done = false;
      _lastHit = null;
      _feedbackSerial = 0;
    });
  }

  void _registerTap({required bool hit}) {
    if (!_running) {
      _start();
      return;
    }
    setState(() {
      _attempts += 1;
      if (hit) {
        _count += 1;
        _combo += 1;
        _bestCombo = math.max(_bestCombo, _combo);
        if (_mode == _TapSpeedMode.targetChase) {
          _targetSlot = _nextDifferentSlot(_targetSlot);
        }
      } else {
        _combo = 0;
      }
      _lastHit = hit;
      _feedbackSerial += 1;
    });
  }

  int _nextDifferentSlot(int current) {
    var next = _random.nextInt(9);
    var guard = 0;
    while (next == current && guard < 8) {
      guard += 1;
      next = _random.nextInt(9);
    }
    return next;
  }

  void _setMode(_TapSpeedMode mode) {
    if (_running) {
      return;
    }
    setState(() {
      _mode = mode;
      _done = false;
      _lastHit = null;
    });
  }

  Future<void> _showReport() async {
    if (!mounted || (!_done && _attempts <= 0)) {
      return;
    }
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    await showDialog<void>(
      context: context,
      builder: (context) => _TapSpeedReportDialog(
        i18n: i18n,
        mode: _modeLabel(i18n, _mode),
        taps: _count,
        attempts: _attempts,
        cps: _cps,
        accuracy: _accuracy,
        bestCombo: _bestCombo,
        durationSeconds: _durationSeconds,
      ),
    );
  }

  String _modeLabel(AppI18n i18n, _TapSpeedMode mode) {
    return switch (mode) {
      _TapSpeedMode.classic => pickUiText(i18n, zh: '经典连点', en: 'Classic'),
      _TapSpeedMode.targetChase => pickUiText(
        i18n,
        zh: '目标追击',
        en: 'Target chase',
      ),
      _TapSpeedMode.rhythm => pickUiText(i18n, zh: '节奏命中', en: 'Rhythm hit'),
    };
  }

  String _modeHint(AppI18n i18n) {
    return switch (_mode) {
      _TapSpeedMode.classic => pickUiText(
        i18n,
        zh: '任意点击舞台，尽量保持稳定高速。',
        en: 'Tap anywhere on the stage and keep a stable high pace.',
      ),
      _TapSpeedMode.targetChase => pickUiText(
        i18n,
        zh: '只点亮起的目标格，点错会断连击。',
        en: 'Tap only the lit target tile. Wrong taps break combo.',
      ),
      _TapSpeedMode.rhythm => pickUiText(
        i18n,
        zh: '目标按节奏跳动，抓住亮起的格子。',
        en: 'The target jumps on a rhythm. Catch the lit tile.',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final theme = Theme.of(context);
    final secondsLeft = _remainingTenths / 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (pickUiText(i18n, zh: '命中', en: 'Hits'), '$_count'),
            (
              pickUiText(i18n, zh: '剩余', en: 'Left'),
              _formatSeconds(secondsLeft),
            ),
            (
              pickUiText(i18n, zh: '每秒', en: 'Per sec'),
              (_running || _done) ? _cps.toStringAsFixed(1) : '-',
            ),
            (
              pickUiText(i18n, zh: '准确率', en: 'Accuracy'),
              _attempts <= 0 ? '-' : '${(_accuracy * 100).round()}%',
            ),
            (pickUiText(i18n, zh: '连击', en: 'Combo'), '$_combo'),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                _modeHint(i18n),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _TapSpeedStage(
                mode: _mode,
                running: _running,
                targetSlot: _mode == _TapSpeedMode.rhythm
                    ? _rhythmSlot
                    : _targetSlot,
                lastHit: _lastHit,
                feedbackSerial: _feedbackSerial,
                onTapStage: () =>
                    _registerTap(hit: _mode == _TapSpeedMode.classic),
                onTapSlot: (index) {
                  if (_mode == _TapSpeedMode.classic) {
                    _registerTap(hit: true);
                    return;
                  }
                  final target = _mode == _TapSpeedMode.rhythm
                      ? _rhythmSlot
                      : _targetSlot;
                  _registerTap(hit: index == target);
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _HumanActionButton(
                    label: _running
                        ? pickUiText(i18n, zh: '挑战中', en: 'Running')
                        : pickUiText(i18n, zh: '开始挑战', en: 'Start challenge'),
                    icon: _running
                        ? Icons.flash_on_rounded
                        : Icons.play_arrow_rounded,
                    onPressed: _running ? null : _start,
                  ),
                  OutlinedButton.icon(
                    onPressed: _restart,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(pickUiText(i18n, zh: '重新开始', en: 'Restart')),
                  ),
                  OutlinedButton.icon(
                    onPressed: _attempts <= 0
                        ? null
                        : () => unawaited(_showReport()),
                    icon: const Icon(Icons.analytics_rounded),
                    label: Text(pickUiText(i18n, zh: '报告', en: 'Report')),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _HumanSettingsSection(
                title: pickUiText(i18n, zh: '手速设置', en: 'Tap settings'),
                subtitle: pickUiText(
                  i18n,
                  zh: '选择玩法和挑战时长，运行中设置会锁定。',
                  en: 'Choose mode and duration. Settings lock while running.',
                ),
                initiallyExpanded: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pickUiText(i18n, zh: '玩法模式', en: 'Game mode'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _TapSpeedMode.values
                          .map(
                            (mode) => ChoiceChip(
                              label: Text(_modeLabel(i18n, mode)),
                              selected: _mode == mode,
                              onSelected: _running
                                  ? null
                                  : (_) => _setMode(mode),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      pickUiText(i18n, zh: '挑战时长', en: 'Duration'),
                      style: theme.textTheme.labelLarge,
                    ),
                    Slider(
                      value: _durationSeconds.toDouble(),
                      min: 5,
                      max: 30,
                      divisions: 5,
                      label: '$_durationSeconds s',
                      onChanged: _running
                          ? null
                          : (value) => setState(
                              () => _durationSeconds = value.round(),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TapSpeedStage extends StatelessWidget {
  const _TapSpeedStage({
    required this.mode,
    required this.running,
    required this.targetSlot,
    required this.lastHit,
    required this.feedbackSerial,
    required this.onTapStage,
    required this.onTapSlot,
  });

  final _TapSpeedMode mode;
  final bool running;
  final int targetSlot;
  final bool? lastHit;
  final int feedbackSerial;
  final VoidCallback onTapStage;
  final ValueChanged<int> onTapSlot;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    if (mode == _TapSpeedMode.classic) {
      return GestureDetector(
        onTap: onTapStage,
        child: _TapSpeedClassicPad(
          running: running,
          lastHit: lastHit,
          feedbackSerial: feedbackSerial,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 8.0;
        final width = (constraints.maxWidth - spacing * 2) / 3;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              List<Widget>.generate(9, (index) {
                final active = running && index == targetSlot;
                return SizedBox(
                  width: width,
                  height: 82,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onTapSlot(index),
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: active
                              ? _TapSpeedTestCardState._accent.withValues(
                                  alpha: 0.22,
                                )
                              : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.40),
                          border: Border.all(
                            color: active
                                ? _TapSpeedTestCardState._accent.withValues(
                                    alpha: 0.70,
                                  )
                                : Theme.of(context).colorScheme.outlineVariant,
                            width: active ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            active
                                ? Icons.ads_click_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: active
                                ? _TapSpeedTestCardState._accent
                                : Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              })..insert(
                0,
                SizedBox(
                  width: constraints.maxWidth,
                  child: Text(
                    running
                        ? pickUiText(
                            i18n,
                            zh: '点击亮起目标',
                            en: 'Tap the lit target',
                          )
                        : pickUiText(
                            i18n,
                            zh: '开始后目标会亮起',
                            en: 'Targets light up after start',
                          ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
        );
      },
    );
  }
}

class _TapSpeedClassicPad extends StatelessWidget {
  const _TapSpeedClassicPad({
    required this.running,
    required this.lastHit,
    required this.feedbackSerial,
  });

  final bool running;
  final bool? lastHit;
  final int feedbackSerial;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final theme = Theme.of(context);
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Container(
          height: 220,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: _TapSpeedTestCardState._accent.withValues(alpha: 0.14),
            border: Border.all(
              color: _TapSpeedTestCardState._accent.withValues(alpha: 0.24),
            ),
          ),
          child: Text(
            running
                ? pickUiText(i18n, zh: '点击', en: 'Tap')
                : pickUiText(i18n, zh: '点击开始', en: 'Tap to start'),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (feedbackSerial > 0)
          TweenAnimationBuilder<double>(
            key: ValueKey<int>(feedbackSerial),
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: (1 - value).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.7 + value * 0.6,
                  child: const Icon(
                    Icons.touch_app_rounded,
                    size: 64,
                    color: _TapSpeedTestCardState._accent,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _TapSpeedReportDialog extends StatelessWidget {
  const _TapSpeedReportDialog({
    required this.i18n,
    required this.mode,
    required this.taps,
    required this.attempts,
    required this.cps,
    required this.accuracy,
    required this.bestCombo,
    required this.durationSeconds,
  });

  final AppI18n i18n;
  final String mode;
  final int taps;
  final int attempts;
  final double cps;
  final double accuracy;
  final int bestCombo;
  final int durationSeconds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = cps >= 8.5 && accuracy >= 0.9
        ? pickUiText(i18n, zh: '爆发型选手', en: 'Burst specialist')
        : cps >= 6.5
        ? pickUiText(i18n, zh: '高速稳定', en: 'Fast and steady')
        : accuracy < 0.75
        ? pickUiText(i18n, zh: '需要稳手', en: 'Needs control')
        : pickUiText(i18n, zh: '稳定练习中', en: 'Steady practice');
    return AlertDialog(
      title: Text(pickUiText(i18n, zh: '手速报告', en: 'Tap speed report')),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '称号', en: 'Title'),
                    value: title,
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '每秒', en: 'Per sec'),
                    value: cps.toStringAsFixed(1),
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '命中/尝试', en: 'Hits/attempts'),
                    value: '$taps/$attempts',
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(i18n, zh: '最佳连击', en: 'Best combo'),
                    value: '$bestCombo',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ColorVisionReportSection(
                title: pickUiText(i18n, zh: '本轮设置', en: 'Session settings'),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    Chip(label: Text(mode)),
                    Chip(label: Text('$durationSeconds s')),
                    Chip(label: Text('${(accuracy * 100).round()}% accuracy')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ColorVisionReportSection(
                title: pickUiText(i18n, zh: '训练建议', en: 'Training note'),
                child: Text(
                  accuracy < 0.8
                      ? pickUiText(
                          i18n,
                          zh: '先降低误触，目标追击模式下保持拇指回到中心再点下一格。',
                          en: 'Reduce mis-taps first. In target chase, return to center before the next tile.',
                        )
                      : pickUiText(
                          i18n,
                          zh: '准确率稳定，可以缩短休息间隔或切换到节奏命中练习爆发。',
                          en: 'Accuracy is stable. Shorten rests or switch to rhythm hit for burst practice.',
                        ),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(pickUiText(i18n, zh: '关闭', en: 'Close')),
        ),
      ],
    );
  }
}

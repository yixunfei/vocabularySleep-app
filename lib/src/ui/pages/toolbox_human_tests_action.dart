part of 'toolbox_human_tests.dart';

class TapSpeedTestPage extends StatelessWidget {
  const TapSpeedTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_action.tap_speed_1d5f49',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_action.classic_target_chase_and_rhythm_hit_modes_for_speed_and_349b91',
      ),
      accent: const Color(0xFFC05180),
      icon: Icons.touch_app_rounded,
      status: i18n.t(
        'inline.ui.pages.toolbox_human_tests_action.next_choose_a_mode_and_start_46e406',
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
      _TapSpeedMode.classic => i18n.t(
        'inline.plan295.life.classic.184f87f1be60',
      ),
      _TapSpeedMode.targetChase => i18n.t(
        'inline.ui.pages.toolbox_human_tests_action.target_chase_ff1621',
      ),
      _TapSpeedMode.rhythm => i18n.t(
        'inline.ui.pages.toolbox_human_tests_action.rhythm_hit_a57e96',
      ),
    };
  }

  String _modeHint(AppI18n i18n) {
    return switch (_mode) {
      _TapSpeedMode.classic => i18n.t(
        'inline.ui.pages.toolbox_human_tests_action.tap_anywhere_on_the_stage_and_keep_a_stable_high_pace_050362',
      ),
      _TapSpeedMode.targetChase => i18n.t(
        'inline.ui.pages.toolbox_human_tests_action.tap_only_the_lit_target_tile_wrong_taps_break_combo_0f954f',
      ),
      _TapSpeedMode.rhythm => i18n.t(
        'inline.ui.pages.toolbox_human_tests_action.the_target_jumps_on_a_rhythm_catch_the_lit_tile_c5d31f',
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
            (
              i18n.t('inline.ui.pages.toolbox_human_tests_action.hits_fe10b3'),
              '$_count',
            ),
            (
              i18n.t('inline.plan294.breathing.left_a0d89e6f'),
              _formatSeconds(secondsLeft),
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_action.per_sec_600db1',
              ),
              (_running || _done) ? _cps.toStringAsFixed(1) : '-',
            ),
            (
              i18n.t('inline.ui.pages.practice_review_page.accuracy_8cf5a1'),
              _attempts <= 0 ? '-' : '${(_accuracy * 100).round()}%',
            ),
            (
              i18n.t('inline.ui.pages.toolbox_human_tests_action.combo_e9df71'),
              '$_combo',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTapSettingsSection(i18n, theme),
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
                        ? i18n.t(
                            'inline.ui.pages.toolbox_human_tests_action.running_6a424b',
                          )
                        : i18n.t(
                            'inline.ui.pages.toolbox_human_tests_action.start_challenge_9e0ecb',
                          ),
                    icon: _running
                        ? Icons.flash_on_rounded
                        : Icons.play_arrow_rounded,
                    onPressed: _running ? null : _start,
                  ),
                  OutlinedButton.icon(
                    onPressed: _restart,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(
                      i18n.t(
                        'inline.ui.pages.practice_session_page.restart_8b7fcc',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _attempts <= 0
                        ? null
                        : () => unawaited(_showReport()),
                    icon: const Icon(Icons.analytics_rounded),
                    label: Text(i18n.t('toolbox.sleep.assist.reportCard')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTapSettingsSection(AppI18n i18n, ThemeData theme) {
    return _HumanSettingsSection(
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_action.tap_settings_c70439',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_action.choose_mode_and_duration_settings_lock_while_running_124529',
      ),
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_action.game_mode_e4d1de',
            ),
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
                    onSelected: _running ? null : (_) => _setMode(mode),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          Text(
            i18n.t('toolbox.breathing.duration'),
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
                : (value) => setState(() => _durationSeconds = value.round()),
          ),
        ],
      ),
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
                        ? i18n.t(
                            'inline.ui.pages.toolbox_human_tests_action.tap_the_lit_target_259da6',
                          )
                        : i18n.t(
                            'inline.ui.pages.toolbox_human_tests_action.targets_light_up_after_start_a77a5a',
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
                ? i18n.t(
                    'inline.ui.pages.toolbox_human_tests_action.tap_4c3724',
                  )
                : i18n.t(
                    'inline.ui.pages.toolbox_human_tests_action.tap_to_start_9ab8b0',
                  ),
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
        ? i18n.t(
            'inline.ui.pages.toolbox_human_tests_action.burst_specialist_777590',
          )
        : cps >= 6.5
        ? i18n.t(
            'inline.ui.pages.toolbox_human_tests_action.fast_and_steady_6aacef',
          )
        : accuracy < 0.75
        ? i18n.t(
            'inline.ui.pages.toolbox_human_tests_action.needs_control_4db7d5',
          )
        : i18n.t(
            'inline.ui.pages.toolbox_human_tests_action.steady_practice_c21f29',
          );
    return AlertDialog(
      title: Text(
        i18n.t(
          'inline.ui.pages.toolbox_human_tests_action.tap_speed_report_53d3f2',
        ),
      ),
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
                    label: i18n.t('noteTitle'),
                    value: title,
                  ),
                  _ColorVisionReportMetric(
                    label: i18n.t(
                      'inline.ui.pages.toolbox_human_tests_action.per_sec_600db1',
                    ),
                    value: cps.toStringAsFixed(1),
                  ),
                  _ColorVisionReportMetric(
                    label: i18n.t(
                      'inline.ui.pages.toolbox_human_tests_action.hits_attempts_e2479b',
                    ),
                    value: '$taps/$attempts',
                  ),
                  _ColorVisionReportMetric(
                    label: i18n.t(
                      'inline.ui.pages.toolbox_human_tests_action.best_combo_65a7d7',
                    ),
                    value: '$bestCombo',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ColorVisionReportSection(
                title: i18n.t(
                  'inline.ui.pages.practice_session_page.session_settings_35f8c2',
                ),
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
                title: i18n.t(
                  'inline.ui.pages.toolbox_human_tests_action.training_note_0dc151',
                ),
                child: Text(
                  accuracy < 0.8
                      ? i18n.t(
                          'inline.ui.pages.toolbox_human_tests_action.reduce_mis_taps_first_in_target_chase_return_to_center_b_99b2d1',
                        )
                      : i18n.t(
                          'inline.ui.pages.toolbox_human_tests_action.accuracy_is_stable_shorten_rests_or_switch_to_rhythm_hit_9283c9',
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
          child: Text(i18n.t('inline.plan295.life.close.370fb8697deb')),
        ),
      ],
    );
  }
}

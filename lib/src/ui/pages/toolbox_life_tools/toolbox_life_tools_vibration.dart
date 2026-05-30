part of '../toolbox_life_tools.dart';

class _VibrationToolPage extends StatefulWidget {
  const _VibrationToolPage();

  @override
  State<_VibrationToolPage> createState() => _VibrationToolPageState();
}

class _VibrationToolPageState extends State<_VibrationToolPage> {
  static const List<_LifeOption<String>> _presetOptions = <_LifeOption<String>>[
    _LifeOption(
      value: 'focus',
      labelKey: 'inline.plan297.life.focus_taps.3220e6795e0b',
    ),
    _LifeOption(
      value: 'double',
      labelKey: 'inline.plan297.life.double_alert.d88dbd61973c',
    ),
    _LifeOption(
      value: 'sos',
      labelKey: 'inline.plan297.life.sos_rhythm.cc2d2ecf34df',
    ),
    _LifeOption(
      value: 'wave',
      labelKey: 'inline.plan297.life.wave_pulse.5ec55a862bd4',
    ),
  ];

  String _preset = 'focus';
  double _intensity = 0.72;
  double _pulseWidth = 180;
  double _gap = 120;
  int _cycles = 4;
  bool _playing = false;
  int _pulseCount = 0;
  Timer? _finishTimer;
  _LifeVibrationCapability _capability = _LifeVibrationCapability.fallback;

  @override
  void initState() {
    super.initState();
    _loadCapability();
  }

  Future<void> _loadCapability() async {
    final capability = await _getLifeVibrationCapability();
    if (!mounted) {
      return;
    }
    setState(() => _capability = capability);
  }

  @override
  void dispose() {
    _finishTimer?.cancel();
    _cancelLifeVibration();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _patternPreview();
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.vibration_tool.e1833c0d758f',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.shape_rhythm_strength_and_pauses_fir.312c7c9800aa',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _capability.isSupported ? _togglePlayback : null,
        icon: Icon(_playing ? Icons.stop_rounded : Icons.vibration_rounded),
        label: Text(
          _playing
              ? _lifeI18nText(
                  context,
                  'inline.ui.pages.toolbox_daily_choice.daily_choice_widgets.stop_d03661',
                )
              : _lifeI18nText(context, 'inline.plan295.life.test.e08ae258cb69'),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LifeSettingsPanel(
            title: _lifeI18nText(
              context,
              'inline.plan295.life.current_rhythm.a81483a1b8a3',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.life.start_with_the_preset_capability_sta.ed6ab0a78175',
            ),
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _VibrationPill(
                    icon: Icons.tune_rounded,
                    label: _presetLabel(context),
                    color: theme.colorScheme.primary,
                  ),
                  _VibrationPill(
                    icon: Icons.phonelink_ring_rounded,
                    label: _capabilityLabel(context),
                    color: _capability.isSupported
                        ? const Color(0xFF0F9D58)
                        : const Color(0xFFDC2626),
                  ),
                  _VibrationPill(
                    icon: Icons.bolt_rounded,
                    label: _lifeI18nText(
                      context,
                      'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.vibration.pulses.e5e97bd848',
                      params: <String, Object?>{'preview': preview},
                    ),
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.56,
                      ),
                      theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.92,
                      ),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      key: const ValueKey<String>('life-vibration-stage'),
                      height: 96,
                      child: _VibrationPatternPreview(
                        segments: _patternSegments(),
                        playing: _playing,
                        intensity: _intensity,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _playing
                          ? _lifeI18nText(
                              context,
                              'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.vibration.pulses_sent.dcf0cf3233',
                              params: <String, Object?>{
                                '_pulseCount': _pulseCount,
                              },
                            )
                          : _lifeI18nText(
                              context,
                              'inline.plan295.life.tap_the_action_button_when_ready.8cad80ad0e99',
                            ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _capability.isSupported
                          ? _lifeI18nText(
                              context,
                              'inline.plan295.life.android_prefers_native_waveforms_uns.4fa691ba9425',
                            )
                          : _lifeI18nText(
                              context,
                              'inline.plan295.life.this_device_or_runtime_has_no_access.762e7cc59a7e',
                            ),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeI18nText(
              context,
              'inline.plan295.life.pattern_settings.a5d369999b0e',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.life.pulse_width_controls_each_hit_gap_sh.60350ee59049',
            ),
            children: <Widget>[
              _LifeSegmentedField<String>(
                label: _lifeI18nText(
                  context,
                  'inline.ui.pages.toolbox_sound_tools.drum_pad.preset_a98ad7',
                ),
                value: _preset,
                options: _presetOptions,
                onChanged: (value) => setState(() => _preset = value),
              ),
              const SizedBox(height: 12),
              _LifeSliderField(
                label: _lifeI18nText(
                  context,
                  'ref.toolbox.sleep.winddown.intensity',
                ),
                valueText: '${(_intensity * 100).round()}%',
                value: _intensity,
                min: 0.2,
                max: 1,
                divisions: 8,
                onChanged: (value) => setState(() => _intensity = value),
              ),
              _LifeSliderField(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.pulse_width.058f18960e51',
                ),
                valueText: '${_pulseWidth.round()} ms',
                value: _pulseWidth,
                min: 60,
                max: 420,
                divisions: 18,
                onChanged: (value) => setState(() => _pulseWidth = value),
              ),
              _LifeSliderField(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.gap.379f86cce902',
                ),
                valueText: '${_gap.round()} ms',
                value: _gap,
                min: 40,
                max: 420,
                divisions: 19,
                onChanged: (value) => setState(() => _gap = value),
              ),
              _LifeSliderField(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.cycles.3492aa65e38b',
                ),
                valueText: '$_cycles',
                value: _cycles.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (value) => setState(() => _cycles = value.round()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.duration.d33b4c0dbaf1',
                ),
                value: '${_totalDurationMs().round()} ms',
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.pulses.6659139322c4',
                ),
                value: '$preview',
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.ui.pages.toolbox_human_tests_auditory_lab.platform_913e74',
                ),
                value: _capability.platform,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _togglePlayback() async {
    if (_playing) {
      _finishTimer?.cancel();
      await _cancelLifeVibration();
      if (!mounted) {
        return;
      }
      setState(() => _playing = false);
      return;
    }

    final pattern = _buildPattern();
    final amplitudes = _buildAmplitudes(pattern.length);
    final supported = await _playLifeVibrationPattern(
      timingsMs: pattern,
      amplitudes: amplitudes,
    );

    if (!supported) {
      _playFallbackPattern();
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _playing = true;
      _pulseCount = _countActivePulseSlots();
    });
    _finishTimer?.cancel();
    _finishTimer = Timer(
      Duration(milliseconds: _totalDurationMs().round() + 40),
      () {
        if (!mounted) {
          return;
        }
        setState(() => _playing = false);
      },
    );
  }

  void _playFallbackPattern() {
    final count = _countActivePulseSlots();
    for (var i = 0; i < count; i += 1) {
      Future<void>.delayed(
        Duration(milliseconds: i * (_pulseWidth + _gap).round()),
        () {
          final scaled = _intensity;
          if (scaled < 0.4) {
            HapticFeedback.lightImpact();
          } else if (scaled < 0.72) {
            HapticFeedback.mediumImpact();
          } else {
            HapticFeedback.heavyImpact();
          }
        },
      );
    }
    setState(() {
      _playing = true;
      _pulseCount = count;
    });
    _finishTimer?.cancel();
    _finishTimer = Timer(
      Duration(milliseconds: _totalDurationMs().round() + 40),
      () {
        if (!mounted) {
          return;
        }
        setState(() => _playing = false);
      },
    );
  }

  List<int> _buildPattern() {
    final unitOn = _pulseWidth.round();
    final unitGap = _gap.round();
    final base = switch (_preset) {
      'double' => <int>[0, unitOn, unitGap, unitOn],
      'sos' => <int>[
        0,
        unitOn,
        unitGap,
        unitOn,
        unitGap,
        unitOn,
        unitGap * 2,
        unitOn * 2,
        unitGap,
        unitOn * 2,
        unitGap,
        unitOn * 2,
      ],
      'wave' => <int>[
        0,
        unitOn,
        unitGap,
        unitOn,
        unitGap,
        unitOn,
        unitGap,
        unitOn,
      ],
      _ => <int>[0, unitOn, unitGap, unitOn],
    };
    if (_cycles <= 1) {
      return base;
    }
    final merged = <int>[...base];
    for (var i = 1; i < _cycles; i += 1) {
      merged.add(unitGap * 2);
      merged.addAll(base.skip(1));
    }
    return merged;
  }

  List<int> _buildAmplitudes(int count) {
    final baseAmplitude = (_intensity * 255).round().clamp(32, 255);
    return List<int>.generate(count, (index) {
      if (index == 0 || index.isEven) {
        return 0;
      }
      if (_preset != 'wave') {
        return baseAmplitude;
      }
      final slot = ((index - 1) ~/ 2) % 4;
      final factor = <double>[0.45, 0.75, 1, 0.7][slot];
      return (baseAmplitude * factor).round().clamp(32, 255);
    });
  }

  List<double> _patternSegments() {
    final pattern = _buildPattern();
    final total = pattern.fold<int>(0, (sum, value) => sum + value).toDouble();
    return pattern
        .map((value) => value / math.max(total, 1))
        .toList(growable: false);
  }

  int _countActivePulseSlots() {
    final pattern = _buildPattern();
    var count = 0;
    for (var i = 1; i < pattern.length; i += 2) {
      if (pattern[i] > 0) {
        count += 1;
      }
    }
    return count;
  }

  int _patternPreview() => _countActivePulseSlots();

  double _totalDurationMs() {
    return _buildPattern().fold<int>(0, (sum, value) => sum + value).toDouble();
  }

  String _presetLabel(BuildContext context) {
    final option = _presetOptions.firstWhere(
      (item) => item.value == _preset,
      orElse: () => _presetOptions.first,
    );
    return option.label(context);
  }

  String _capabilityLabel(BuildContext context) {
    if (_capability.isSupported) {
      return _capability.supportsWaveform
          ? _lifeI18nText(
              context,
              'inline.plan295.life.native_waveform_ready.b8de25663d12',
            )
          : _lifeI18nText(
              context,
              'inline.plan295.life.basic_haptics_ready.c12bc84e2510',
            );
    }
    return _lifeI18nText(
      context,
      'inline.plan295.life.no_vibration_access.d7b5ed1555ac',
    );
  }
}

class _VibrationPill extends StatelessWidget {
  const _VibrationPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _VibrationPatternPreview extends StatefulWidget {
  const _VibrationPatternPreview({
    required this.segments,
    required this.playing,
    required this.intensity,
  });

  final List<double> segments;
  final bool playing;
  final double intensity;

  @override
  State<_VibrationPatternPreview> createState() =>
      _VibrationPatternPreviewState();
}

class _VibrationPatternPreviewState extends State<_VibrationPatternPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.playing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _VibrationPatternPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.playing && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: widget.segments
              .asMap()
              .entries
              .map((entry) {
                final index = entry.key;
                final weight = math.max(entry.value, 0.04).toDouble();
                final active = index.isOdd;
                final live =
                    widget.playing && _controller.value >= _segmentStart(index);
                final height = active
                    ? (24 + widget.intensity * 34 + (live ? 14 : 0)).toDouble()
                    : 14.0;
                return Expanded(
                  flex: (weight * 1000).round(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOutCubic,
                      height: height,
                      decoration: BoxDecoration(
                        color: active
                            ? theme.colorScheme.primary.withValues(
                                alpha: live ? 0.95 : 0.48,
                              )
                            : theme.colorScheme.outlineVariant.withValues(
                                alpha: 0.28,
                              ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }

  double _segmentStart(int index) {
    var start = 0.0;
    for (var i = 0; i < index; i += 1) {
      start += widget.segments[i];
    }
    return start.clamp(0.0, 1.0);
  }
}

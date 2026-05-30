part of '../toolbox_life_tools.dart';

class _LevelToolPage extends StatefulWidget {
  const _LevelToolPage();

  @override
  State<_LevelToolPage> createState() => _LevelToolPageState();
}

class _LevelToolPageState extends State<_LevelToolPage> {
  StreamSubscription<AccelerometerEvent>? _accelSub;

  double _smoothPitch = 0;
  double _smoothRoll = 0;
  bool _plumbMode = false;
  bool _sensorsAvailable = true;

  static const double _tightThreshold = 0.8;
  static const double _softThreshold = 2.0;

  @override
  void initState() {
    super.initState();
    _startSensors();
  }

  void _startSensors() {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      _sensorsAvailable = false;
      return;
    }
    try {
      _accelSub =
          accelerometerEventStream(
            samplingPeriod: const Duration(milliseconds: 70),
          ).listen(
            (event) {
              final x = event.x;
              final y = event.y;
              final z = event.z;
              final pitch =
                  math.atan2(-x, math.sqrt(y * y + z * z)) * 180 / math.pi;
              final roll = math.atan2(y, z) * 180 / math.pi;
              if (!mounted) {
                return;
              }
              setState(() {
                _smoothPitch = _smoothPitch + (pitch - _smoothPitch) * 0.18;
                _smoothRoll = _smoothRoll + (roll - _smoothRoll) * 0.18;
              });
            },
            onError: (_) {
              if (!mounted) {
                return;
              }
              setState(() => _sensorsAvailable = false);
            },
            cancelOnError: true,
          );
    } on MissingPluginException {
      setState(() => _sensorsAvailable = false);
    }
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  bool get _isTightLevel {
    if (_plumbMode) {
      return _smoothPitch.abs() <= _tightThreshold;
    }
    return _smoothPitch.abs() <= _tightThreshold &&
        _smoothRoll.abs() <= _tightThreshold;
  }

  bool get _isNearLevel {
    if (_plumbMode) {
      return _smoothPitch.abs() <= _softThreshold;
    }
    return _smoothPitch.abs() <= _softThreshold &&
        _smoothRoll.abs() <= _softThreshold;
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.level_meter.12381487172b',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.see_horizontal_vertical_error_and_ho.7b04881a71e4',
      ),
      child: _sensorsAvailable
          ? _buildBody(context)
          : _buildUnsupported(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _isTightLevel
        ? const Color(0xFF16A34A)
        : _isNearLevel
        ? const Color(0xFFF59E0B)
        : theme.colorScheme.primary;
    final primaryAngle = _plumbMode ? _smoothPitch.abs() : _dominantError();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _LifeSettingsPanel(
          title: _lifeI18nText(
            context,
            'inline.plan295.life.mode_and_stage.da87b3ced09f',
          ),
          subtitle: _lifeI18nText(
            context,
            'inline.plan295.life.level_mode_watches_pitch_and_roll_to.d9bb0454d698',
          ),
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ChoiceChip(
                  selected: !_plumbMode,
                  label: Text(
                    _lifeI18nText(
                      context,
                      'inline.plan295.life.level.539dadb65937',
                    ),
                  ),
                  onSelected: (_) => setState(() => _plumbMode = false),
                ),
                ChoiceChip(
                  selected: _plumbMode,
                  label: Text(
                    _lifeI18nText(
                      context,
                      'inline.plan295.life.plumb.072c7db57674',
                    ),
                  ),
                  onSelected: (_) => setState(() => _plumbMode = true),
                ),
                _LevelStatePill(
                  color: accent,
                  label: _levelStatusText(context),
                  icon: _isTightLevel
                      ? Icons.check_circle_rounded
                      : Icons.tune_rounded,
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
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.58),
                    theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.9,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: accent.withValues(alpha: 0.24)),
              ),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    key: const ValueKey<String>('life-level-stage'),
                    width: 272,
                    height: 272,
                    child: CustomPaint(
                      painter: _LevelPainter(
                        pitch: _smoothPitch,
                        roll: _smoothRoll,
                        plumbMode: _plumbMode,
                        isTightLevel: _isTightLevel,
                        accent: accent,
                        theme: theme,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${primaryAngle.toStringAsFixed(1)}°',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _levelHint(context),
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.pitch.0cb07e852905',
              ),
              value: '${_smoothPitch.toStringAsFixed(1)}°',
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.roll.a02089ccbca7',
              ),
              value: '${_smoothRoll.toStringAsFixed(1)}°',
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.main_error.e4e0df46108b',
              ),
              value: '${_dominantError().toStringAsFixed(1)}°',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _LifeSettingsPanel(
          title: _lifeI18nText(
            context,
            'inline.plan295.life.reading_notes.13f00496d11a',
          ),
          subtitle: _lifeI18nText(
            context,
            'inline.plan295.life.raised_cases_soft_surfaces_and_hand.d3c7779e81a7',
          ),
          children: <Widget>[
            Text(
              _lifeI18nText(
                context,
                'inline.plan295.life.green_means_level_yellow_means_close.4a3d4295b048',
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUnsupported(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.unavailable.bd744c3b3507',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.this_device_does_not_expose_the_acce.d57e3272ecbb',
      ),
      children: <Widget>[
        Text(
          _lifeI18nText(
            context,
            'inline.plan295.life.use_this_tool_on_a_physical_phone_de.4b4ffca91b9b',
          ),
        ),
      ],
    );
  }

  double _dominantError() {
    if (_plumbMode) {
      return _smoothPitch.abs();
    }
    return math.max(_smoothPitch.abs(), _smoothRoll.abs());
  }

  String _levelStatusText(BuildContext context) {
    if (_isTightLevel) {
      return _lifeI18nText(context, 'inline.plan295.life.level.454ce987e8a0');
    }
    if (_isNearLevel) {
      return _lifeI18nText(
        context,
        'inline.plan295.life.almost_level.9fb105c4bc6e',
      );
    }
    return _lifeI18nText(
      context,
      'inline.plan295.life.needs_adjustment.92cf8cf41e44',
    );
  }

  String _levelHint(BuildContext context) {
    if (_plumbMode) {
      return _isTightLevel
          ? _lifeI18nText(
              context,
              'inline.plan295.life.the_device_is_close_to_plumb.72fcfd39f414',
            )
          : _lifeI18nText(
              context,
              'inline.plan295.life.bring_the_bubble_back_to_the_center.a0e4bd884d40',
            );
    }
    return _isTightLevel
        ? _lifeI18nText(
            context,
            'inline.plan295.life.pitch_and_roll_are_both_tightly_cent.73cfa21eb6e0',
          )
        : _lifeI18nText(
            context,
            'inline.plan295.life.bring_both_pitch_and_roll_closer_to.e885c58ae7d1',
          );
  }
}

class _LevelStatePill extends StatelessWidget {
  const _LevelStatePill({
    required this.color,
    required this.label,
    required this.icon,
  });

  final Color color;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
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

class _LevelPainter extends CustomPainter {
  const _LevelPainter({
    required this.pitch,
    required this.roll,
    required this.plumbMode,
    required this.isTightLevel,
    required this.accent,
    required this.theme,
  });

  final double pitch;
  final double roll;
  final bool plumbMode;
  final bool isTightLevel;
  final Color accent;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final bubbleRadius = 18.0;
    final maxOffset = radius * 0.62;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            theme.colorScheme.surface.withValues(alpha: 0.98),
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.86),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = theme.colorScheme.outlineVariant,
    );

    for (final factor in <double>[0.25, 0.5, 0.75]) {
      canvas.drawCircle(
        center,
        radius * factor,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = factor == 0.75 ? 1.4 : 1
          ..color = theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
      );
    }

    canvas.drawLine(
      Offset(center.dx - radius + 18, center.dy),
      Offset(center.dx + radius - 18, center.dy),
      Paint()
        ..strokeWidth = 2
        ..color = theme.colorScheme.outlineVariant,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius + 18),
      Offset(center.dx, center.dy + radius - 18),
      Paint()
        ..strokeWidth = 2
        ..color = theme.colorScheme.outlineVariant,
    );

    final dx = (plumbMode ? pitch : roll) / 45;
    final dy = plumbMode ? 0.0 : pitch / 45;
    final bubbleCenter = Offset(
      center.dx + dx.clamp(-1.0, 1.0) * maxOffset,
      center.dy + dy.clamp(-1.0, 1.0) * maxOffset,
    );

    canvas.drawCircle(bubbleCenter, bubbleRadius, Paint()..color = accent);
    canvas.drawCircle(
      bubbleCenter.translate(-5, -5),
      bubbleRadius * 0.34,
      Paint()..color = Colors.white.withValues(alpha: 0.36),
    );
    if (isTightLevel) {
      canvas.drawCircle(center, 8, Paint()..color = accent);
    }
  }

  @override
  bool shouldRepaint(covariant _LevelPainter oldDelegate) {
    return pitch != oldDelegate.pitch ||
        roll != oldDelegate.roll ||
        plumbMode != oldDelegate.plumbMode ||
        isTightLevel != oldDelegate.isTightLevel ||
        accent != oldDelegate.accent ||
        theme.colorScheme != oldDelegate.theme.colorScheme;
  }
}

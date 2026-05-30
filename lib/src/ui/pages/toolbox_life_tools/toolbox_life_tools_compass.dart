part of '../toolbox_life_tools.dart';

class _CompassToolPage extends StatefulWidget {
  const _CompassToolPage();

  @override
  State<_CompassToolPage> createState() => _CompassToolPageState();
}

class _CompassToolPageState extends State<_CompassToolPage> {
  StreamSubscription<MagnetometerEvent>? _magnetSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  List<double> _magnetometer = const <double>[0, 0, 0];
  List<double> _accelerometer = const <double>[0, 0, 9.8];
  double _smoothHeading = 0;
  double _tilt = 0;
  double _fieldStrength = 0;
  bool _sensorsAvailable = true;
  bool _hasFix = false;
  String _status = 'starting';

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
      _status = 'unsupported';
      return;
    }
    try {
      _magnetSub =
          magnetometerEventStream(
            samplingPeriod: const Duration(milliseconds: 90),
          ).listen(
            (event) {
              _magnetometer = <double>[event.x, event.y, event.z];
              _updateHeading();
            },
            onError: (_) {
              if (!mounted) {
                return;
              }
              setState(() {
                _sensorsAvailable = false;
                _status = 'unsupported';
              });
            },
            cancelOnError: true,
          );
      _accelSub =
          accelerometerEventStream(
            samplingPeriod: const Duration(milliseconds: 90),
          ).listen(
            (event) {
              _accelerometer = <double>[event.x, event.y, event.z];
              _updateHeading();
            },
            onError: (_) {
              if (!mounted) {
                return;
              }
              setState(() {
                _sensorsAvailable = false;
                _status = 'unsupported';
              });
            },
            cancelOnError: true,
          );
    } on MissingPluginException {
      setState(() {
        _sensorsAvailable = false;
        _status = 'unsupported';
      });
    }
  }

  void _updateHeading() {
    final mx = _magnetometer[0];
    final my = _magnetometer[1];
    final mz = _magnetometer[2];
    final ax = _accelerometer[0];
    final ay = _accelerometer[1];
    final az = _accelerometer[2];

    final gravityNorm = math.sqrt(ax * ax + ay * ay + az * az);
    final magnetNorm = math.sqrt(mx * mx + my * my + mz * mz);
    if (gravityNorm < 0.1 || magnetNorm < 1) {
      return;
    }

    final pitch = math.atan2(-ax, math.sqrt(ay * ay + az * az));
    final roll = math.atan2(ay, az);
    final cosPitch = math.cos(pitch);
    final sinPitch = math.sin(pitch);
    final cosRoll = math.cos(roll);
    final sinRoll = math.sin(roll);

    final tiltX = mx * cosPitch + mz * sinPitch;
    final tiltY =
        mx * sinRoll * sinPitch + my * cosRoll - mz * sinRoll * cosPitch;

    var heading = math.atan2(-tiltY, tiltX) * 180 / math.pi;
    if (heading < 0) {
      heading += 360;
    }

    final tiltDegrees =
        math.acos((az / gravityNorm).clamp(-1.0, 1.0)) * 180 / math.pi;
    final nextSmooth = _smoothAngle(_smoothHeading, heading, 0.18);
    final status = _compassStatus(tiltDegrees, magnetNorm);

    if (!mounted) {
      return;
    }
    setState(() {
      _smoothHeading = nextSmooth;
      _tilt = tiltDegrees;
      _fieldStrength = magnetNorm;
      _hasFix = true;
      _status = status;
    });
  }

  @override
  void dispose() {
    _magnetSub?.cancel();
    _accelSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'inline.plan295.life.compass.64c372418a25'),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.heading_tilt_and_magnetic_quality_st.28488a978389',
      ),
      child: _sensorsAvailable
          ? _buildBody(context, theme)
          : _buildUnsupported(context),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme) {
    final direction = _directionLabel(_smoothHeading);
    final accent = _statusColor(theme);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _LifeSettingsPanel(
          title: _lifeI18nText(
            context,
            'inline.plan295.life.direction_stage.30aa01e1aec8',
          ),
          subtitle: _lifeI18nText(
            context,
            'inline.plan295.life.check_heading_first_then_device_tilt.dd0814354b2e',
          ),
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _CompassStatusPill(
                  icon: Icons.explore_rounded,
                  label: direction,
                  color: accent,
                ),
                _CompassStatusPill(
                  icon: Icons.screen_rotation_alt_rounded,
                  label: _lifeI18nText(
                    context,
                    'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.compass.tilt.e423ee6c8e',
                    params: <String, Object?>{'p0': _tilt.toStringAsFixed(0)},
                  ),
                  color: accent,
                ),
                _CompassStatusPill(
                  icon: Icons.waves_rounded,
                  label: _statusText(context),
                  color: accent,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.62),
                    theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.88,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: accent.withValues(alpha: 0.28)),
              ),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    key: const ValueKey<String>('life-compass-stage'),
                    width: 268,
                    height: 268,
                    child: CustomPaint(
                      painter: _CompassPainter(
                        heading: _smoothHeading,
                        accent: accent,
                        theme: theme,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${_smoothHeading.toStringAsFixed(0)}°',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _lifeI18nText(
                      context,
                      'life.compass.heading_hint',
                      params: <String, Object?>{
                        'direction': direction,
                        'hint': _compassHint(context),
                      },
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.heading.0241420b8324',
              ),
              value: '${_smoothHeading.toStringAsFixed(0)}°',
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.tilt.42a72229a797',
              ),
              value: '${_tilt.toStringAsFixed(0)}°',
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.field.3abcdd52b20b',
              ),
              value: '${_fieldStrength.toStringAsFixed(0)} μT',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _LifeSettingsPanel(
          title: _lifeI18nText(
            context,
            'inline.plan295.life.usage_notes.d2647c27f0af',
          ),
          subtitle: _lifeI18nText(
            context,
            'inline.plan295.life.metal_magnetic_cases_and_electronics.0ef60c35b506',
          ),
          children: <Widget>[
            Text(
              _lifeI18nText(
                context,
                'inline.plan295.life.if_the_dial_keeps_jumping_move_away.5965ff2ae423',
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
        'inline.plan295.life.this_device_does_not_expose_the_magn.739200b65c49',
      ),
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.sensors_off_rounded, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.open_this_tool_on_a_real_phone_deskt.a76b72c0b648',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _compassStatus(double tiltDegrees, double field) {
    if (tiltDegrees > 55) {
      return 'tilted';
    }
    if (field < 20 || field > 90) {
      return 'interference';
    }
    if (!_hasFix) {
      return 'starting';
    }
    return 'stable';
  }

  String _statusText(BuildContext context) {
    return switch (_status) {
      'stable' => _lifeI18nText(
        context,
        'inline.plan295.life.stable_field.367e70be2d1e',
      ),
      'tilted' => _lifeI18nText(
        context,
        'inline.plan295.life.flatten_phone.027bdc346566',
      ),
      'interference' => _lifeI18nText(
        context,
        'inline.plan295.life.field_disturbed.edb69e6fbd46',
      ),
      'unsupported' => _lifeI18nText(
        context,
        'inline.plan295.life.unsupported.b44bb9a343a6',
      ),
      _ => _lifeI18nText(context, 'inline.plan295.life.starting.48a42587727e'),
    };
  }

  Color _statusColor(ThemeData theme) {
    return switch (_status) {
      'stable' => const Color(0xFF0F9D58),
      'tilted' => const Color(0xFFF59E0B),
      'interference' => const Color(0xFFDC2626),
      _ => theme.colorScheme.primary,
    };
  }

  String _directionLabel(double heading) {
    const keys = <String>[
      'life.compass.direction.n',
      'life.compass.direction.ne',
      'life.compass.direction.e',
      'life.compass.direction.se',
      'life.compass.direction.s',
      'life.compass.direction.sw',
      'life.compass.direction.w',
      'life.compass.direction.nw',
    ];
    final index = ((heading + 22.5) / 45).floor() % 8;
    return _lifeI18nText(context, keys[index]);
  }

  String _compassHint(BuildContext context) {
    return switch (_status) {
      'stable' => _lifeI18nText(context, 'life.compass.hint.stable'),
      'tilted' => _lifeI18nText(context, 'life.compass.hint.tilted'),
      'interference' => _lifeI18nText(
        context,
        'life.compass.hint.interference',
      ),
      _ => _lifeI18nText(context, 'life.compass.hint.starting'),
    };
  }

  double _smoothAngle(double current, double target, double factor) {
    var delta = target - current;
    if (delta > 180) {
      delta -= 360;
    } else if (delta < -180) {
      delta += 360;
    }
    final next = current + delta * factor;
    return (next % 360 + 360) % 360;
  }
}

class _CompassStatusPill extends StatelessWidget {
  const _CompassStatusPill({
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

class _CompassPainter extends CustomPainter {
  const _CompassPainter({
    required this.heading,
    required this.accent,
    required this.theme,
  });

  final double heading;
  final Color accent;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final ringPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          theme.colorScheme.surface.withValues(alpha: 0.96),
          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.88),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = theme.colorScheme.outlineVariant,
    );

    for (var i = 0; i < 72; i += 1) {
      final angle = (i * 5 - 90) * math.pi / 180;
      final isMajor = i % 9 == 0;
      final inner = radius - (isMajor ? 28 : 18);
      final outer = radius - 10;
      final start = Offset(
        center.dx + inner * math.cos(angle),
        center.dy + inner * math.sin(angle),
      );
      final end = Offset(
        center.dx + outer * math.cos(angle),
        center.dy + outer * math.sin(angle),
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..strokeWidth = isMajor ? 2.2 : 1
          ..color = isMajor
              ? theme.colorScheme.onSurface
              : theme.colorScheme.outlineVariant,
      );
    }

    const labels = <String>['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    for (var i = 0; i < labels.length; i += 1) {
      final angle = (i * 45 - 90) * math.pi / 180;
      final labelRadius = radius - 46;
      final offset = Offset(
        center.dx + labelRadius * math.cos(angle),
        center.dy + labelRadius * math.sin(angle),
      );
      final painter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            fontSize: i == 0 ? 16 : 13,
            fontWeight: i == 0 ? FontWeight.w800 : FontWeight.w700,
            color: i == 0 ? accent : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(offset.dx - painter.width / 2, offset.dy - painter.height / 2),
      );
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(heading * math.pi / 180);
    canvas.translate(-center.dx, -center.dy);

    final northNeedle = Path()
      ..moveTo(center.dx, center.dy - radius + 30)
      ..lineTo(center.dx + 10, center.dy + 14)
      ..lineTo(center.dx, center.dy + 2)
      ..lineTo(center.dx - 10, center.dy + 14)
      ..close();
    canvas.drawPath(northNeedle, Paint()..color = accent);

    final southNeedle = Path()
      ..moveTo(center.dx, center.dy + radius - 42)
      ..lineTo(center.dx + 8, center.dy)
      ..lineTo(center.dx, center.dy - 6)
      ..lineTo(center.dx - 8, center.dy)
      ..close();
    canvas.drawPath(
      southNeedle,
      Paint()..color = theme.colorScheme.onSurfaceVariant,
    );
    canvas.restore();

    canvas.drawCircle(center, 10, Paint()..color = theme.colorScheme.surface);
    canvas.drawCircle(center, 5, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) {
    return heading != oldDelegate.heading ||
        accent != oldDelegate.accent ||
        theme.colorScheme != oldDelegate.theme.colorScheme;
  }
}

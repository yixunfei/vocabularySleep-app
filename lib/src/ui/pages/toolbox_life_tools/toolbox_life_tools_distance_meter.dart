part of '../toolbox_life_tools.dart';

class _DistanceMeterToolPage extends StatefulWidget {
  const _DistanceMeterToolPage();

  @override
  State<_DistanceMeterToolPage> createState() => _DistanceMeterToolPageState();
}

class _DistanceMeterToolPageState extends State<_DistanceMeterToolPage> {
  final TextEditingController _heightController = TextEditingController(
    text: '1.60',
  );
  StreamSubscription<AccelerometerEvent>? _accelSub;

  Position? _pointA;
  Position? _pointB;
  double _pitchDegrees = 0;
  bool _locating = false;
  bool _sensorsAvailable = true;
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    _startTiltSensor();
    _heightController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _heightController.dispose();
    super.dispose();
  }

  double? get _gpsDistance {
    final a = _pointA;
    final b = _pointB;
    if (a == null || b == null) {
      return null;
    }
    return Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }

  double? get _tiltDistance {
    final height = double.tryParse(_heightController.text.trim());
    if (height == null || height <= 0) {
      return null;
    }
    final angle = _pitchDegrees.abs();
    if (angle < 2 || angle > 80) {
      return null;
    }
    return height / math.tan(angle * math.pi / 180);
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'toolbox.life.distance_meter.title'),
      subtitle: _lifeI18nText(context, 'toolbox.life.distance_meter.subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LifeSettingsPanel(
            title: _lifeI18nText(context, 'toolbox.life.distance_meter.gps'),
            subtitle: _lifeI18nText(
              context,
              'toolbox.life.distance_meter.gps_subtitle',
            ),
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: _locating ? null : () => _markPoint(isA: true),
                    icon: const Icon(Icons.looks_one_rounded),
                    label: Text(
                      _lifeI18nText(
                        context,
                        'toolbox.life.distance_meter.mark_a',
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _locating ? null : () => _markPoint(isA: false),
                    icon: const Icon(Icons.looks_two_rounded),
                    label: Text(
                      _lifeI18nText(
                        context,
                        'toolbox.life.distance_meter.mark_b',
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _resetGps,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(
                      _lifeI18nText(context, 'toolbox.life.common.reset'),
                    ),
                  ),
                ],
              ),
              if (_errorKey != null) ...<Widget>[
                const SizedBox(height: 12),
                _LifeInlineNotice(
                  icon: Icons.location_off_rounded,
                  text: _lifeI18nText(context, _errorKey!),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ToolboxMetricCard(
                    label: _lifeI18nText(
                      context,
                      'toolbox.life.distance_meter.point_a',
                    ),
                    value: _pointText(_pointA),
                  ),
                  ToolboxMetricCard(
                    label: _lifeI18nText(
                      context,
                      'toolbox.life.distance_meter.point_b',
                    ),
                    value: _pointText(_pointB),
                  ),
                  ToolboxMetricCard(
                    label: _lifeI18nText(
                      context,
                      'toolbox.life.distance_meter.metric_distance',
                    ),
                    value: _formatMeters(_gpsDistance),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeI18nText(context, 'toolbox.life.distance_meter.tilt'),
            subtitle: _lifeI18nText(
              context,
              'toolbox.life.distance_meter.tilt_subtitle',
            ),
            children: <Widget>[
              TextField(
                controller: _heightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: _lifeI18nText(
                    context,
                    'toolbox.life.distance_meter.height',
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              if (!_sensorsAvailable)
                _LifeInlineNotice(
                  icon: Icons.screen_rotation_alt_rounded,
                  text: _lifeI18nText(
                    context,
                    'toolbox.life.distance_meter.sensor_unsupported',
                  ),
                )
              else
                Column(
                  children: <Widget>[
                    SizedBox(
                      height: 168,
                      child: CustomPaint(
                        painter: _DistanceTiltPainter(
                          pitchDegrees: _pitchDegrees,
                          theme: Theme.of(context),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        ToolboxMetricCard(
                          label: _lifeI18nText(
                            context,
                            'toolbox.life.distance_meter.metric_pitch',
                          ),
                          value: '${_pitchDegrees.toStringAsFixed(1)}°',
                        ),
                        ToolboxMetricCard(
                          label: _lifeI18nText(
                            context,
                            'toolbox.life.distance_meter.metric_tilt_distance',
                          ),
                          value: _formatMeters(_tiltDistance),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _startTiltSensor() {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      _sensorsAvailable = false;
      return;
    }
    try {
      _accelSub =
          accelerometerEventStream(
            samplingPeriod: const Duration(milliseconds: 90),
          ).listen(
            (event) {
              final pitch =
                  math.atan2(
                    -event.x,
                    math.sqrt(event.y * event.y + event.z * event.z),
                  ) *
                  180 /
                  math.pi;
              if (!mounted) {
                return;
              }
              setState(() {
                _pitchDegrees += (pitch - _pitchDegrees) * 0.18;
              });
            },
            onError: (_) {
              if (mounted) {
                setState(() => _sensorsAvailable = false);
              }
            },
            cancelOnError: true,
          );
    } on MissingPluginException {
      _sensorsAvailable = false;
    }
  }

  Future<void> _markPoint({required bool isA}) async {
    setState(() {
      _locating = true;
      _errorKey = null;
    });
    try {
      final position = await _currentPosition();
      if (!mounted || position == null) {
        return;
      }
      setState(() {
        if (isA) {
          _pointA = position;
        } else {
          _pointB = position;
        }
      });
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  Future<Position?> _currentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _errorKey = 'toolbox.life.speedometer.error_service');
      return null;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      setState(() => _errorKey = 'toolbox.life.speedometer.error_denied');
      return null;
    }
    if (permission == LocationPermission.deniedForever) {
      setState(
        () => _errorKey = 'toolbox.life.speedometer.error_denied_forever',
      );
      return null;
    }
    try {
      return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
    } catch (_) {
      setState(() => _errorKey = 'toolbox.life.distance_meter.error_position');
      return null;
    }
  }

  void _resetGps() {
    setState(() {
      _pointA = null;
      _pointB = null;
      _errorKey = null;
    });
  }

  String _pointText(Position? position) {
    if (position == null) {
      return '--';
    }
    return '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
  }

  String _formatMeters(double? meters) {
    if (meters == null || !meters.isFinite) {
      return '--';
    }
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.toStringAsFixed(2)} m';
  }
}

class _DistanceTiltPainter extends CustomPainter {
  const _DistanceTiltPainter({required this.pitchDegrees, required this.theme});

  final double pitchDegrees;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.72);
    final radius = math.min(size.width, size.height * 1.5) * 0.45;
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = theme.colorScheme.outlineVariant;
    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = theme.colorScheme.primary;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      basePaint,
    );
    final angle = (-pitchDegrees).clamp(-80.0, 80.0) * math.pi / 180;
    final end = Offset(
      center.dx + math.cos(math.pi + angle) * radius,
      center.dy + math.sin(math.pi + angle) * radius,
    );
    canvas.drawLine(center, end, accentPaint);
    canvas.drawCircle(center, 6, Paint()..color = theme.colorScheme.primary);
  }

  @override
  bool shouldRepaint(covariant _DistanceTiltPainter oldDelegate) {
    return oldDelegate.pitchDegrees != pitchDegrees ||
        oldDelegate.theme != theme;
  }
}

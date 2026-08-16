part of '../toolbox_life_tools.dart';

class _SpeedometerToolPage extends StatefulWidget {
  const _SpeedometerToolPage();

  @override
  State<_SpeedometerToolPage> createState() => _SpeedometerToolPageState();
}

class _SpeedometerToolPageState extends State<_SpeedometerToolPage> {
  StreamSubscription<Position>? _positionSub;
  Timer? _ticker;

  Position? _lastPosition;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  double _speedMps = 0;
  double _maxSpeedMps = 0;
  double _distanceMeters = 0;
  double _accuracyMeters = 0;
  int _samples = 0;
  bool _tracking = false;
  bool _starting = false;
  String? _errorKey;

  @override
  void dispose() {
    _positionSub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'toolbox.life.speedometer.title'),
      subtitle: _lifeI18nText(context, 'toolbox.life.speedometer.subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LifeSettingsPanel(
            title: _lifeI18nText(context, 'toolbox.life.speedometer.stage'),
            subtitle: _lifeI18nText(
              context,
              'toolbox.life.speedometer.stage_subtitle',
            ),
            children: <Widget>[
              Center(
                child: Column(
                  children: <Widget>[
                    Text(
                      (_speedMps * 3.6).toStringAsFixed(1),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _lifeI18nText(context, 'toolbox.life.speedometer.kmh'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: _starting
                        ? null
                        : _tracking
                        ? _stop
                        : _start,
                    icon: Icon(
                      _tracking ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    ),
                    label: Text(
                      _lifeI18nText(
                        context,
                        _tracking
                            ? 'toolbox.life.speedometer.stop'
                            : 'toolbox.life.speedometer.start',
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _tracking ? null : _reset,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(
                      _lifeI18nText(context, 'toolbox.life.common.reset'),
                    ),
                  ),
                  _SpeedStatusChip(
                    icon: _tracking
                        ? Icons.satellite_alt_rounded
                        : Icons.gps_off_rounded,
                    label: _lifeI18nText(
                      context,
                      _tracking
                          ? 'toolbox.life.speedometer.status_tracking'
                          : 'toolbox.life.speedometer.status_idle',
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
                  'toolbox.life.speedometer.metric_ms',
                ),
                value: _speedMps.toStringAsFixed(2),
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.speedometer.metric_max',
                ),
                value: '${(_maxSpeedMps * 3.6).toStringAsFixed(1)} km/h',
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.speedometer.metric_distance',
                ),
                value: _formatDistance(_distanceMeters),
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.speedometer.metric_accuracy',
                ),
                value: _accuracyMeters <= 0
                    ? '--'
                    : '${_accuracyMeters.toStringAsFixed(0)} m',
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.speedometer.metric_elapsed',
                ),
                value: _formatDuration(_elapsed),
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.speedometer.metric_samples',
                ),
                value: _samples.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _start() async {
    setState(() {
      _starting = true;
      _errorKey = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _errorKey = 'toolbox.life.speedometer.error_service');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        setState(() => _errorKey = 'toolbox.life.speedometer.error_denied');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(
          () => _errorKey = 'toolbox.life.speedometer.error_denied_forever',
        );
        return;
      }

      await _positionSub?.cancel();
      _positionSub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 1,
            ),
          ).listen(
            _onPosition,
            onError: (_) {
              if (!mounted) {
                return;
              }
              setState(
                () => _errorKey = 'toolbox.life.speedometer.error_stream',
              );
            },
          );
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _startedAt == null) {
          return;
        }
        setState(() => _elapsed = DateTime.now().difference(_startedAt!));
      });
      setState(() {
        _tracking = true;
        _startedAt ??= DateTime.now();
      });
    } catch (_) {
      if (mounted) {
        setState(() => _errorKey = 'toolbox.life.speedometer.error_stream');
      }
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
    }
  }

  void _onPosition(Position position) {
    final previous = _lastPosition;
    var speed = position.speed.isFinite ? position.speed : 0.0;
    if (speed < 0 && previous != null) {
      final seconds =
          position.timestamp.difference(previous.timestamp).inMilliseconds /
          1000;
      if (seconds > 0) {
        final meters = Geolocator.distanceBetween(
          previous.latitude,
          previous.longitude,
          position.latitude,
          position.longitude,
        );
        speed = meters / seconds;
      }
    }
    if (previous != null) {
      final meters = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        position.latitude,
        position.longitude,
      );
      if (meters.isFinite && meters >= 0 && meters < 500) {
        _distanceMeters += meters;
      }
    }
    setState(() {
      _lastPosition = position;
      _speedMps = math.max(0, speed);
      _maxSpeedMps = math.max(_maxSpeedMps, _speedMps);
      _accuracyMeters = position.accuracy;
      _samples += 1;
    });
  }

  Future<void> _stop() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _ticker?.cancel();
    _ticker = null;
    setState(() {
      _tracking = false;
      _speedMps = 0;
    });
  }

  void _reset() {
    setState(() {
      _lastPosition = null;
      _startedAt = null;
      _elapsed = Duration.zero;
      _speedMps = 0;
      _maxSpeedMps = 0;
      _distanceMeters = 0;
      _accuracyMeters = 0;
      _samples = 0;
      _errorKey = null;
    });
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _SpeedStatusChip extends StatelessWidget {
  const _SpeedStatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 18, color: theme.colorScheme.onSecondaryContainer),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LifeInlineNotice extends StatelessWidget {
  const _LifeInlineNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Icon(icon, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

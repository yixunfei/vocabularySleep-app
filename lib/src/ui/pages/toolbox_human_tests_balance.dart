part of 'toolbox_human_tests.dart';

class BalanceTestPage extends StatefulWidget {
  const BalanceTestPage({super.key});

  @override
  State<BalanceTestPage> createState() => _BalanceTestPageState();
}

class _BalanceTestPageState extends State<BalanceTestPage> {
  static const Color _accent = Color(0xFF3B9D7E);
  static const Color _background = Color(0xFF0D1513);
  static const Duration _sensorSamplingPeriod = Duration(milliseconds: 20);
  static const double _sensorSmoothing = 0.46;
  static const double _sensorTiltGain = 1.12;

  final ToolboxHumanBalanceController _controller =
      ToolboxHumanBalanceController();
  StreamSubscription<AccelerometerEvent>? _accelerometerSub;
  Timer? _tickTimer;
  DateTime? _lastTickAt;

  double _sensorTiltX = 0;
  double _sensorTiltY = 0;
  double _manualTiltX = 0;
  double _manualTiltY = 0;
  double _neutralTiltX = 0;
  double _neutralTiltY = 0;
  bool _hasSensorNeutral = false;
  bool _sensorsAvailable = true;
  bool _manualControl = false;
  bool _reportDialogOpen = false;

  double get _tiltX => _manualControl
      ? _manualTiltX
      : ToolboxHumanBalanceController.clampTilt(
          (_sensorTiltX - _neutralTiltX) * _sensorTiltGain,
        );

  double get _tiltY => _manualControl
      ? _manualTiltY
      : ToolboxHumanBalanceController.clampTilt(
          (_sensorTiltY - _neutralTiltY) * _sensorTiltGain,
        );

  @override
  void initState() {
    super.initState();
    unawaited(_enterBalanceFullscreen());
    _startSensors();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _accelerometerSub?.cancel();
    unawaited(_exitHumanTestFullscreen());
    super.dispose();
  }

  Future<void> _enterBalanceFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  void _startSensors() {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      _sensorsAvailable = false;
      _manualControl = true;
      return;
    }
    try {
      _accelerometerSub =
          accelerometerEventStream(
            samplingPeriod: _sensorSamplingPeriod,
          ).listen(
            (event) {
              final tilt = ToolboxHumanBalanceController.tiltFromGravity(
                x: event.x,
                y: event.y,
                z: event.z,
              );
              if (!mounted) {
                return;
              }
              setState(() {
                if (!_hasSensorNeutral) {
                  _neutralTiltX = tilt.xDegrees;
                  _neutralTiltY = tilt.yDegrees;
                  _sensorTiltX = tilt.xDegrees;
                  _sensorTiltY = tilt.yDegrees;
                  _hasSensorNeutral = true;
                } else {
                  _sensorTiltX +=
                      (tilt.xDegrees - _sensorTiltX) * _sensorSmoothing;
                  _sensorTiltY +=
                      (tilt.yDegrees - _sensorTiltY) * _sensorSmoothing;
                }
                _sensorsAvailable = true;
                if (!_manualControl) {
                  _manualTiltX = _tiltX;
                  _manualTiltY = _tiltY;
                }
              });
            },
            onError: (_) {
              if (!mounted) {
                return;
              }
              setState(() {
                _manualTiltX = _tiltX;
                _manualTiltY = _tiltY;
                _sensorsAvailable = false;
                _manualControl = true;
              });
            },
            cancelOnError: true,
          );
    } on MissingPluginException {
      _sensorsAvailable = false;
      _manualControl = true;
    }
  }

  void _startTest() {
    _tickTimer?.cancel();
    _calibrateSensorToCurrentPose();
    _controller.start();
    _lastTickAt = DateTime.now();
    _tickTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _onTick(),
    );
    setState(() {});
  }

  void _calibrateSensorToCurrentPose() {
    if (_manualControl || !_sensorsAvailable) {
      return;
    }
    if (!_hasSensorNeutral) {
      return;
    }
    _neutralTiltX = _sensorTiltX;
    _neutralTiltY = _sensorTiltY;
    _manualTiltX = 0;
    _manualTiltY = 0;
    _hasSensorNeutral = true;
  }

  void _resetTest() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _lastTickAt = null;
    setState(() {
      _controller.reset();
      _reportDialogOpen = false;
    });
  }

  void _onTick() {
    final now = DateTime.now();
    final last = _lastTickAt ?? now;
    _lastTickAt = now;
    final dt =
        now.difference(last).inMicroseconds / Duration.microsecondsPerSecond;
    _controller.tick(dtSeconds: dt, tiltXDegrees: _tiltX, tiltYDegrees: _tiltY);
    if (!mounted) {
      return;
    }
    setState(() {});
    if (_controller.state.fallen) {
      _tickTimer?.cancel();
      _tickTimer = null;
      unawaited(_showReport());
    }
  }

  Future<void> _showReport() async {
    if (!mounted ||
        _reportDialogOpen ||
        _controller.state.elapsedSeconds <= 0) {
      return;
    }
    _reportDialogOpen = true;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    await showDialog<void>(
      context: context,
      builder: (context) {
        final state = _controller.state;
        return AlertDialog(
          title: Text(i18n.t('toolbox.human.balance.report.title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _BalanceReportRow(
                label: i18n.t('toolbox.human.balance.metric.time'),
                value: _formatSeconds(state.elapsedSeconds),
              ),
              _BalanceReportRow(
                label: i18n.t('toolbox.human.balance.metric.max_offset'),
                value: _formatPercent(state.maxOffsetPercent),
              ),
              _BalanceReportRow(
                label: i18n.t('toolbox.human.balance.metric.max_tilt'),
                value: _formatDegrees(state.maxTiltMagnitude),
              ),
              _BalanceReportRow(
                label: i18n.t('toolbox.human.balance.metric.impulse'),
                value: state.initialImpulse.toStringAsFixed(2),
              ),
              const SizedBox(height: 10),
              Text(
                i18n.t('toolbox.human.balance.report.body'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(i18n.t('close')),
            ),
          ],
        );
      },
    );
    if (mounted) {
      setState(() => _reportDialogOpen = false);
    }
  }

  String _statusText(AppI18n i18n) {
    final state = _controller.state;
    if (state.fallen) {
      return i18n.t('toolbox.human.balance.state.fallen');
    }
    if (state.running) {
      return i18n.t('toolbox.human.balance.state.running');
    }
    if (state.elapsedSeconds > 0) {
      return i18n.t('toolbox.human.balance.state.result');
    }
    return i18n.t('toolbox.human.balance.state.ready');
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final state = _controller.state;
    final tiltMagnitude = math
        .sqrt(_tiltX * _tiltX + _tiltY * _tiltY)
        .clamp(0, ToolboxHumanBalanceController.maxTiltDegrees)
        .toDouble();
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 650;
            return Padding(
              padding: EdgeInsets.fromLTRB(12, compact ? 8 : 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _BalanceTopBar(
                    title: i18n.t('toolbox.human.balance.title'),
                    subtitle: i18n.t('toolbox.human.balance.subtitle'),
                    status: _statusText(i18n),
                    sensorLabel: _sensorsAvailable
                        ? i18n.t('toolbox.human.balance.sensor.active')
                        : i18n.t('toolbox.human.balance.sensor.manual'),
                    accent: _accent,
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  _BalanceMetricBar(
                    metrics: <(String, String)>[
                      (
                        i18n.t('toolbox.human.balance.metric.time'),
                        _formatSeconds(state.elapsedSeconds),
                      ),
                      (
                        i18n.t('toolbox.human.balance.metric.max_offset'),
                        _formatPercent(state.maxOffsetPercent),
                      ),
                      (
                        i18n.t('toolbox.human.balance.metric.current_offset'),
                        _formatPercent(state.currentOffsetPercent),
                      ),
                      (
                        i18n.t('toolbox.human.balance.metric.tilt'),
                        _formatDegrees(tiltMagnitude),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  Expanded(
                    child: _BalanceStage(
                      state: state,
                      tiltX: _tiltX,
                      tiltY: _tiltY,
                      accent: _accent,
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  _BalanceControlDock(
                    i18n: i18n,
                    accent: _accent,
                    running: state.running,
                    hasResult: state.elapsedSeconds > 0,
                    sensorsAvailable: _sensorsAvailable,
                    manualTiltX: _manualTiltX,
                    manualTiltY: _manualTiltY,
                    onStart: _startTest,
                    onReset: _resetTest,
                    onReport: state.elapsedSeconds > 0 ? _showReport : null,
                    onManualTiltXChanged: (value) {
                      setState(() {
                        _manualControl = true;
                        _manualTiltX = value;
                      });
                    },
                    onManualTiltYChanged: (value) {
                      setState(() {
                        _manualControl = true;
                        _manualTiltY = value;
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BalanceTopBar extends StatelessWidget {
  const _BalanceTopBar({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.sensorLabel,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String status;
  final String sensorLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    _BalanceDarkPill(text: status, accent: accent),
                    _BalanceDarkPill(
                      text: sensorLabel,
                      accent: Colors.lightBlueAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceMetricBar extends StatelessWidget {
  const _BalanceMetricBar({required this.metrics});

  final List<(String, String)> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 7.0;
        final itemWidth = ((constraints.maxWidth - spacing * 3) / 4)
            .clamp(72.0, 112.0)
            .toDouble();
        return Wrap(
          spacing: spacing,
          runSpacing: 7,
          children: metrics
              .map(
                (metric) => _BalanceMetricCard(
                  label: metric.$1,
                  value: metric.$2,
                  width: itemWidth,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _BalanceMetricCard extends StatelessWidget {
  const _BalanceMetricCard({
    required this.label,
    required this.value,
    required this.width,
  });

  final String label;
  final String value;
  final double width;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.62),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceStage extends StatelessWidget {
  const _BalanceStage({
    required this.state,
    required this.tiltX,
    required this.tiltY,
    required this.accent,
  });

  final ToolboxHumanBalanceState state;
  final double tiltX;
  final double tiltY;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _BalanceStagePainter(
            state: state,
            tiltX: tiltX,
            tiltY: tiltY,
            accent: accent,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _BalanceControlDock extends StatelessWidget {
  const _BalanceControlDock({
    required this.i18n,
    required this.accent,
    required this.running,
    required this.hasResult,
    required this.sensorsAvailable,
    required this.manualTiltX,
    required this.manualTiltY,
    required this.onStart,
    required this.onReset,
    required this.onReport,
    required this.onManualTiltXChanged,
    required this.onManualTiltYChanged,
  });

  final AppI18n i18n;
  final Color accent;
  final bool running;
  final bool hasResult;
  final bool sensorsAvailable;
  final double manualTiltX;
  final double manualTiltY;
  final VoidCallback onStart;
  final VoidCallback onReset;
  final VoidCallback? onReport;
  final ValueChanged<double> onManualTiltXChanged;
  final ValueChanged<double> onManualTiltYChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: <Widget>[
              FilledButton.icon(
                onPressed: running ? null : onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(i18n.t('toolbox.human.balance.action.start')),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(118, 46),
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                ),
              ),
              OutlinedButton.icon(
                onPressed: running || hasResult ? onReset : null,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(i18n.t('toolbox.human.balance.action.restart')),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(118, 46),
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
                ),
              ),
              TextButton.icon(
                onPressed: onReport,
                icon: const Icon(Icons.insights_rounded),
                label: Text(i18n.t('toolbox.human.balance.action.report')),
                style: TextButton.styleFrom(
                  minimumSize: const Size(108, 46),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          if (!sensorsAvailable) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              i18n.t('toolbox.human.balance.sensor.fallback_body'),
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.70),
                height: 1.32,
              ),
            ),
            _BalanceManualSlider(
              label: i18n.t('toolbox.human.balance.manual.roll'),
              value: manualTiltX,
              accent: accent,
              onChanged: onManualTiltXChanged,
            ),
            _BalanceManualSlider(
              label: i18n.t('toolbox.human.balance.manual.pitch'),
              value: manualTiltY,
              accent: accent,
              onChanged: onManualTiltYChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _BalanceManualSlider extends StatelessWidget {
  const _BalanceManualSlider({
    required this.label,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  final String label;
  final double value;
  final Color accent;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        SizedBox(
          width: 66,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: -ToolboxHumanBalanceController.maxTiltDegrees,
            max: ToolboxHumanBalanceController.maxTiltDegrees,
            activeColor: accent,
            inactiveColor: Colors.white.withValues(alpha: 0.18),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 42,
          child: Text(
            _formatDegrees(value),
            textAlign: TextAlign.end,
            style: textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _BalanceDarkPill extends StatelessWidget {
  const _BalanceDarkPill({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BalanceReportRow extends StatelessWidget {
  const _BalanceReportRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: textTheme.bodyMedium)),
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _BalanceStagePainter extends CustomPainter {
  const _BalanceStagePainter({
    required this.state,
    required this.tiltX,
    required this.tiltY,
    required this.accent,
  });

  final ToolboxHumanBalanceState state;
  final double tiltX;
  final double tiltY;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF13231F), Color(0xFF08100F)],
        ).createShader(bounds),
    );
    final ambientPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = accent.withValues(alpha: 0.10);
    for (var index = 0; index < 5; index += 1) {
      final inset = 22.0 + index * math.min(size.width, size.height) * 0.09;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          bounds.deflate(inset),
          Radius.circular(34 + index * 18),
        ),
        ambientPaint..color = accent.withValues(alpha: 0.12 - index * 0.018),
      );
    }

    final center = Offset(size.width / 2, size.height * 0.50);
    final halfWidth = math.min(size.width * 0.45, size.height * 0.40);
    final halfHeight = halfWidth * 0.64;
    final skewX = (tiltX / ToolboxHumanBalanceController.maxTiltDegrees) * 34;
    final skewY = (tiltY / ToolboxHumanBalanceController.maxTiltDegrees) * 26;
    final topLeft = center + Offset(-halfWidth - skewX, -halfHeight + skewY);
    final topRight = center + Offset(halfWidth - skewX, -halfHeight - skewY);
    final bottomRight = center + Offset(halfWidth + skewX, halfHeight - skewY);
    final bottomLeft = center + Offset(-halfWidth + skewX, halfHeight + skewY);
    final topPath = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();
    final sideDepth = 34 + tiltY.abs() * 0.12;
    final sidePath = Path()
      ..moveTo(bottomLeft.dx, bottomLeft.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy + sideDepth)
      ..lineTo(bottomLeft.dx, bottomLeft.dy + sideDepth)
      ..close();

    canvas.drawPath(
      topPath.shift(const Offset(0, 20)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.34)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
    canvas.drawPath(
      topPath.shift(const Offset(0, 6)),
      Paint()
        ..color = accent.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawPath(
      sidePath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            accent.withValues(alpha: 0.42),
            const Color(0xFF07110F),
          ],
        ).createShader(sidePath.getBounds()),
    );
    canvas.drawPath(
      topPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accent.withValues(alpha: 0.78),
            const Color(0xFF284B43),
            const Color(0xFF11221E),
          ],
        ).createShader(topPath.getBounds()),
    );

    final edgeFactor =
        ((state.currentOffset - 0.72) /
                (ToolboxHumanBalanceController.fallLimit - 0.72))
            .clamp(0, 1)
            .toDouble();
    if (edgeFactor > 0) {
      canvas.drawPath(
        topPath,
        Paint()
          ..color = Color.lerp(
            Colors.transparent,
            const Color(0xFFFFB86C),
            edgeFactor * 0.42,
          )!,
      );
    }

    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = state.fallen ? 4 : 2.2 + edgeFactor * 1.4
      ..color = state.fallen
          ? const Color(0xFFFF7A7A)
          : Color.lerp(
              Colors.white.withValues(alpha: 0.34),
              const Color(0xFFFFC078),
              edgeFactor,
            )!;
    canvas.drawPath(topPath, edgePaint);

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.13);
    for (final t in const <double>[0.25, 0.5, 0.75]) {
      canvas.drawLine(
        _lerp(topLeft, topRight, t),
        _lerp(bottomLeft, bottomRight, t),
        gridPaint,
      );
      canvas.drawLine(
        _lerp(topLeft, bottomLeft, t),
        _lerp(topRight, bottomRight, t),
        gridPaint,
      );
    }

    final centerPoint = _projectOnPlatform(
      x: 0,
      y: 0,
      topLeft: topLeft,
      topRight: topRight,
      bottomRight: bottomRight,
      bottomLeft: bottomLeft,
    );
    final safeOval = Rect.fromCenter(
      center: centerPoint,
      width: halfWidth * 0.70,
      height: halfHeight * 0.70,
    );
    canvas.drawOval(
      safeOval.inflate(5),
      Paint()
        ..color = accent.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawOval(
      safeOval,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = Colors.white.withValues(alpha: 0.24),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: centerPoint,
        width: halfWidth * 1.35,
        height: halfHeight * 1.28,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = const Color(0xFFFFB86C).withValues(alpha: 0.24),
    );
    _drawTiltDirection(
      canvas: canvas,
      center: centerPoint,
      halfWidth: halfWidth,
      halfHeight: halfHeight,
    );

    final ballPoint = _projectOnPlatform(
      x: state.x.clamp(-1.20, 1.20).toDouble(),
      y: state.y.clamp(-1.20, 1.20).toDouble(),
      topLeft: topLeft,
      topRight: topRight,
      bottomRight: bottomRight,
      bottomLeft: bottomLeft,
    );
    if (state.currentOffset > 0.02 || state.running) {
      canvas.drawLine(
        centerPoint,
        ballPoint,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.18 + edgeFactor * 0.16),
      );
    }
    final ballRadius = math.min(25.0, math.max(15.0, halfWidth * 0.074));
    canvas.drawOval(
      Rect.fromCenter(
        center: ballPoint + Offset(8 + tiltX * 0.08, 12 + tiltY * 0.08),
        width: ballRadius * 2.35,
        height: ballRadius * 0.82,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawCircle(
      ballPoint,
      ballRadius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          radius: 0.78,
          colors: <Color>[
            Color(0xFFFFFFFF),
            Color(0xFFD8F4EA),
            Color(0xFF56B991),
            Color(0xFF16785F),
          ],
        ).createShader(Rect.fromCircle(center: ballPoint, radius: ballRadius)),
    );
    canvas.drawCircle(
      ballPoint,
      ballRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.34),
    );
    canvas.drawCircle(
      ballPoint - Offset(ballRadius * 0.28, ballRadius * 0.32),
      ballRadius * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.78),
    );
  }

  void _drawTiltDirection({
    required Canvas canvas,
    required Offset center,
    required double halfWidth,
    required double halfHeight,
  }) {
    final maxTilt = ToolboxHumanBalanceController.maxTiltDegrees;
    final vector = Offset(tiltX / maxTilt, tiltY / maxTilt);
    final strength = vector.distance.clamp(0, 1).toDouble();
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.16 + strength * 0.28);
    if (strength < 0.05) {
      canvas.drawLine(
        center + Offset(-halfWidth * 0.10, 0),
        center + Offset(halfWidth * 0.10, 0),
        linePaint,
      );
      canvas.drawLine(
        center + Offset(0, -halfHeight * 0.12),
        center + Offset(0, halfHeight * 0.12),
        linePaint,
      );
      return;
    }
    final end =
        center +
        Offset(vector.dx * halfWidth * 0.42, vector.dy * halfHeight * 0.46);
    canvas.drawLine(center, end, linePaint);
    final direction = end - center;
    final angle = math.atan2(direction.dy, direction.dx);
    final arrowSize = 7.0 + strength * 4.0;
    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - math.cos(angle - 0.55) * arrowSize,
        end.dy - math.sin(angle - 0.55) * arrowSize,
      )
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - math.cos(angle + 0.55) * arrowSize,
        end.dy - math.sin(angle + 0.55) * arrowSize,
      );
    canvas.drawPath(arrowPath, linePaint);
    canvas.drawCircle(
      end,
      3.5 + strength * 3.5,
      Paint()..color = accent.withValues(alpha: 0.36 + strength * 0.22),
    );
  }

  Offset _projectOnPlatform({
    required double x,
    required double y,
    required Offset topLeft,
    required Offset topRight,
    required Offset bottomRight,
    required Offset bottomLeft,
  }) {
    final tx = ((x + 1) / 2).clamp(-0.12, 1.12).toDouble();
    final ty = ((y + 1) / 2).clamp(-0.12, 1.12).toDouble();
    final top = _lerp(topLeft, topRight, tx);
    final bottom = _lerp(bottomLeft, bottomRight, tx);
    return _lerp(top, bottom, ty);
  }

  Offset _lerp(Offset a, Offset b, double t) {
    return Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);
  }

  @override
  bool shouldRepaint(covariant _BalanceStagePainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.tiltX != tiltX ||
        oldDelegate.tiltY != tiltY ||
        oldDelegate.accent != accent;
  }
}

String _formatPercent(num value) => '${value.clamp(0, 999).round()}%';

String _formatDegrees(num value) => '${value.round()}°';

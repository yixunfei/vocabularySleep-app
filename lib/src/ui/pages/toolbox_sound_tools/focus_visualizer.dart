part of '../toolbox_sound_tools.dart';

class _FocusBeatVisualizerPainter extends CustomPainter {
  const _FocusBeatVisualizerPainter({
    required this.kind,
    required this.bpm,
    required this.pulseProgress,
    required this.ambientProgress,
    required this.accentLayer,
    required this.running,
    required this.activeBeat,
    required this.activeSubPulse,
    required this.beatsPerBar,
    required this.subdivision,
  });

  final _FocusBeatAnimationKind kind;
  final int bpm;
  final double pulseProgress;
  final double ambientProgress;
  final int accentLayer;
  final bool running;
  final int activeBeat;
  final int activeSubPulse;
  final int beatsPerBar;
  final int subdivision;
  static const double _visualSyncDelayMs = 0.0;

  double _mix(double a, double b, double t) => a + (b - a) * t;

  Color _mixColor(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  Color _withAlpha(Color color, double alpha) {
    return color.withValues(alpha: alpha.clamp(0.0, 1.0).toDouble());
  }

  Color get _layerAccent => switch (accentLayer) {
    0 => const Color(0xFFFFFCF7),
    1 => const Color(0xFFF3EBE1),
    2 => const Color(0xFFE8DDCF),
    _ => const Color(0xFFDCCDBE),
  };

  _FocusVisualizerTheme get _theme => const _FocusVisualizerTheme(
    base: Color(0xFFF8F4EE),
    mid: Color(0xFFE8DED2),
    surface: Color(0xFFD5C6B6),
    accent: Color(0xFFFFFCF7),
    secondary: Color(0xFFE7DCCE),
    highlight: Color(0xFF8A7E72),
  );

  int get _pulseCount => math.max(1, beatsPerBar * subdivision);

  int get _currentPulseIndex {
    if (activeBeat < 0 || activeSubPulse <= 0) {
      return 0;
    }
    return (activeBeat * subdivision + activeSubPulse - 1).clamp(
      0,
      _pulseCount - 1,
    );
  }

  bool get _isBeatPulse => subdivision <= 1 || activeSubPulse <= 1;

  double get _phase => pulseProgress.clamp(0.0, 1.0).toDouble();

  double get _syncDelayFraction {
    final intervalMs = math.max(1.0, 60000.0 / (bpm * subdivision));
    final boundedDelayMs = math.min(_visualSyncDelayMs, intervalMs * 0.30);
    return (boundedDelayMs / intervalMs).clamp(0.0, 0.30).toDouble();
  }

  double get _syncedPhase {
    final delay = _syncDelayFraction;
    if (delay <= 0) {
      return _phase;
    }
    return ((_phase - delay) / (1 - delay)).clamp(0.0, 1.0).toDouble();
  }

  double get _impact {
    if (!running) {
      return 0;
    }
    final delay = _syncDelayFraction;
    if (_phase < delay && delay > 0) {
      return Curves.easeInQuad.transform(_phase / delay) * 0.10;
    }
    return 1 - Curves.easeOutCubic.transform(_syncedPhase);
  }

  double get _accentStrength => switch (accentLayer) {
    0 => 1.0,
    1 => 0.78,
    2 => 0.55,
    _ => 0.34,
  };

  double get _ambientAngle =>
      ambientProgress.clamp(0.0, 1.0).toDouble() * math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final theme = _theme;
    final impact = _impact;
    final accent = _mixColor(theme.accent, _layerAccent, 0.18 + impact * 0.18);
    final secondary = _mixColor(theme.secondary, accent, 0.22);
    final travel = running
        ? Curves.easeInOutCubic.transform(_syncedPhase)
        : 0.0;
    final currentPulse = _currentPulseIndex;
    final travelingPulse = running ? currentPulse + travel : currentPulse * 1.0;
    final runner = _pointForPulse(size, travelingPulse);

    _paintBackground(canvas, size, theme, accent, secondary, impact);
    _paintQuietGrid(canvas, size, theme, accent);
    _paintOrbit(canvas, size, theme, accent, secondary, impact);
    _paintBeatRays(canvas, size, theme, accent, runner, impact);
    _paintPulseTicks(canvas, size, theme, accent, secondary, currentPulse);
    _paintRunner(
      canvas,
      size,
      theme,
      accent,
      secondary,
      travelingPulse,
      impact,
    );
    _paintCenterLens(canvas, size, theme, accent, runner, impact);
  }

  Offset _center(Size size) => Offset(size.width * 0.5, size.height * 0.46);

  double _radiusX(Size size) => math.min(size.width * 0.34, size.height * 0.35);

  double _radiusY(Size size) => math.min(size.height * 0.22, size.width * 0.26);

  double _angleForPulse(double pulseIndex) {
    return -math.pi / 2 + (pulseIndex / _pulseCount) * math.pi * 2;
  }

  Offset _pointForPulse(Size size, double pulseIndex) {
    final center = _center(size);
    final angle = _angleForPulse(pulseIndex);
    final motifShift = switch (kind) {
      _FocusBeatAnimationKind.pendulum => 0.00,
      _FocusBeatAnimationKind.hypno => 0.35,
      _FocusBeatAnimationKind.dew => 0.70,
      _FocusBeatAnimationKind.gear => 1.10,
      _FocusBeatAnimationKind.steps => 1.45,
    };
    final drift =
        1 + math.sin(angle * 3 + _ambientAngle * 0.28 + motifShift) * 0.025;
    return Offset(
      center.dx + math.cos(angle) * _radiusX(size) * drift,
      center.dy + math.sin(angle) * _radiusY(size) * (1.02 - drift * 0.02),
    );
  }

  Offset _unitFromCenter(Size size, Offset point) {
    final center = _center(size);
    final vector = point - center;
    final length = vector.distance;
    if (length <= 0.0001) {
      return const Offset(0, -1);
    }
    return Offset(vector.dx / length, vector.dy / length);
  }

  Path _orbitPath(Size size, {double phaseOffset = 0}) {
    final path = Path();
    const samples = 128;
    for (var i = 0; i <= samples; i += 1) {
      final point = _pointForPulse(
        size,
        phaseOffset + i / samples * _pulseCount,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  void _paintBackground(
    Canvas canvas,
    Size size,
    _FocusVisualizerTheme theme,
    Color accent,
    Color secondary,
    double impact,
  ) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            _mixColor(theme.base, accent, 0.06 + impact * 0.02),
            _mixColor(theme.mid, secondary, 0.08),
            _mixColor(theme.surface, theme.base, 0.42),
          ],
          stops: const <double>[0.0, 0.50, 1.0],
        ).createShader(rect),
    );

    final ambient = _ambientAngle;
    final softPool = Rect.fromCenter(
      center: Offset(
        size.width * (0.35 + math.sin(ambient * 0.21) * 0.05),
        size.height * (0.24 + math.cos(ambient * 0.17) * 0.025),
      ),
      width: size.width * 0.82,
      height: size.height * 0.38,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(softPool, const Radius.circular(999)),
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            _withAlpha(accent, 0.12 + impact * 0.03),
            _withAlpha(secondary, 0.05),
            Colors.transparent,
          ],
          stops: const <double>[0.0, 0.58, 1.0],
        ).createShader(softPool),
    );

    final lowerPool = Rect.fromCenter(
      center: Offset(
        size.width * (0.66 + math.cos(ambient * 0.19) * 0.04),
        size.height * 0.74,
      ),
      width: size.width * 0.92,
      height: size.height * 0.34,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lowerPool, const Radius.circular(999)),
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            _withAlpha(secondary, 0.08 + impact * 0.02),
            Colors.transparent,
          ],
        ).createShader(lowerPool),
    );
  }

  void _paintQuietGrid(
    Canvas canvas,
    Size size,
    _FocusVisualizerTheme theme,
    Color accent,
  ) {
    final center = _center(size);
    final baseAlpha = running ? 0.040 : 0.030;
    for (var ring = 0; ring < 4; ring += 1) {
      final radiusX = _radiusX(size) + ring * size.shortestSide * 0.052;
      final radiusY = _radiusY(size) + ring * size.shortestSide * 0.032;
      final rect = Rect.fromCenter(
        center: center,
        width: radiusX * 2,
        height: radiusY * 2,
      );
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring == 0 ? 1.4 : 0.8
          ..color = _withAlpha(
            ring == 0 ? theme.highlight : accent,
            baseAlpha - ring * 0.006,
          ),
      );
    }

    for (var i = 0; i < 5; i += 1) {
      final y = size.height * (0.18 + i * 0.15);
      final offset = math.sin(_ambientAngle * 0.18 + i) * size.width * 0.018;
      canvas.drawLine(
        Offset(size.width * 0.12 + offset, y),
        Offset(size.width * 0.88 + offset, y),
        Paint()
          ..color = _withAlpha(theme.highlight, 0.030)
          ..strokeWidth = 1,
      );
    }
  }

  void _paintOrbit(
    Canvas canvas,
    Size size,
    _FocusVisualizerTheme theme,
    Color accent,
    Color secondary,
    double impact,
  ) {
    final path = _orbitPath(size);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.026
        ..strokeCap = StrokeCap.round
        ..color = _withAlpha(theme.highlight, 0.10),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.018
        ..strokeCap = StrokeCap.round
        ..shader =
            SweepGradient(
              colors: <Color>[
                _withAlpha(accent, 0.72),
                _withAlpha(secondary, 0.36),
                _withAlpha(theme.highlight, 0.18),
                _withAlpha(accent, 0.72),
              ],
            ).createShader(
              Rect.fromCircle(
                center: _center(size),
                radius: math.max(_radiusX(size), _radiusY(size)),
              ),
            ),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * (0.006 + impact * 0.006)
        ..strokeCap = StrokeCap.round
        ..color = _withAlpha(theme.highlight, 0.08 + impact * 0.12),
    );
  }

  void _paintBeatRays(
    Canvas canvas,
    Size size,
    _FocusVisualizerTheme theme,
    Color accent,
    Offset runner,
    double impact,
  ) {
    final center = _center(size);
    final active = activeBeat < 0 ? -1 : activeBeat % math.max(1, beatsPerBar);
    for (var beat = 0; beat < beatsPerBar; beat += 1) {
      final point = _pointForPulse(size, beat * subdivision.toDouble());
      final selected = beat == active;
      canvas.drawLine(
        center,
        point,
        Paint()
          ..color = _withAlpha(
            selected ? accent : theme.highlight,
            selected ? 0.13 + impact * 0.08 : 0.040,
          )
          ..strokeWidth = selected ? 1.6 : 0.8,
      );
    }

    if (running) {
      canvas.drawLine(
        center,
        runner,
        Paint()
          ..color = _withAlpha(accent, 0.16 + impact * 0.10)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintPulseTicks(
    Canvas canvas,
    Size size,
    _FocusVisualizerTheme theme,
    Color accent,
    Color secondary,
    int currentPulse,
  ) {
    final activeBeatIndex = activeBeat < 0
        ? -1
        : activeBeat.clamp(0, beatsPerBar - 1).toInt();
    for (var pulse = 0; pulse < _pulseCount; pulse += 1) {
      final point = _pointForPulse(size, pulse.toDouble());
      final unit = _unitFromCenter(size, point);
      final isBeat = pulse % subdivision == 0;
      final beatIndex = pulse ~/ subdivision;
      final selectedBeat = beatIndex == activeBeatIndex;
      final selectedPulse = pulse == currentPulse && running;
      final isDownbeat = pulse == 0;
      final tickLength = isBeat ? 13.0 : 7.0;
      final inner = point - unit * (isBeat ? 3.5 : 1.5);
      final outer = point + unit * tickLength;
      final tickColor = selectedPulse
          ? _mixColor(accent, theme.highlight, 0.16)
          : isBeat
          ? (isDownbeat ? _mixColor(accent, theme.highlight, 0.42) : secondary)
          : theme.highlight;
      final alpha = selectedPulse
          ? 0.84
          : selectedBeat && isBeat
          ? 0.68
          : isBeat
          ? 0.44
          : 0.22;

      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = _withAlpha(tickColor, alpha)
          ..strokeWidth = selectedPulse
              ? 3.0
              : isBeat
              ? 2.1
              : 1.1
          ..strokeCap = StrokeCap.round,
      );

      if (isBeat) {
        final radius = isDownbeat ? 9.5 : 7.4;
        final pulseBoost = selectedPulse
            ? _impact * 5.0
            : (selectedBeat ? _impact * 2.8 : 0);
        canvas.drawCircle(
          point,
          radius + pulseBoost,
          Paint()
            ..color = _withAlpha(
              selectedPulse ? accent : tickColor,
              selectedPulse ? 0.76 : 0.50,
            ),
        );
        canvas.drawCircle(
          point,
          math.max(2.4, radius * 0.42),
          Paint()
            ..color = _withAlpha(
              selectedPulse ? theme.highlight : theme.base,
              selectedPulse ? 0.78 : 0.62,
            ),
        );
        _paintBeatNumber(
          canvas,
          '${beatIndex + 1}',
          point + unit * (radius + 16),
          color: selectedPulse || selectedBeat
              ? theme.highlight
              : _withAlpha(theme.highlight, 0.62),
          selected: selectedPulse || selectedBeat,
        );
      } else {
        canvas.drawCircle(
          point,
          selectedPulse ? 4.3 + _impact * 2.2 : 2.6,
          Paint()
            ..color = _withAlpha(
              selectedPulse ? accent : theme.highlight,
              selectedPulse ? 0.86 : 0.30,
            ),
        );
      }
    }
  }

  void _paintBeatNumber(
    Canvas canvas,
    String text,
    Offset center, {
    required Color color,
    required bool selected,
  }) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: selected ? 12 : 11,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        letterSpacing: 0,
      ),
    );
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _paintRunner(
    Canvas canvas,
    Size size,
    _FocusVisualizerTheme theme,
    Color accent,
    Color secondary,
    double travelingPulse,
    double impact,
  ) {
    if (!running) {
      final ready = _pointForPulse(size, 0);
      canvas.drawCircle(ready, 10, Paint()..color = _withAlpha(accent, 0.58));
      return;
    }

    for (var trail = 6; trail >= 1; trail -= 1) {
      final t = trail / 6;
      final point = _pointForPulse(size, travelingPulse - t * 0.64);
      canvas.drawCircle(
        point,
        _mix(3.0, 10.0, 1 - t),
        Paint()
          ..color = _withAlpha(
            _mixColor(secondary, accent, 1 - t),
            (0.035 + (1 - t) * 0.12) * (0.7 + impact * 0.3),
          ),
      );
    }

    final point = _pointForPulse(size, travelingPulse);
    final pulseRadius =
        size.shortestSide * 0.028 + (_isBeatPulse ? 4.0 : 1.5) + impact * 5.0;
    canvas.drawCircle(
      point,
      pulseRadius + 18 + impact * 18,
      Paint()
        ..shader =
            RadialGradient(
              colors: <Color>[
                _withAlpha(accent, 0.12 + impact * 0.08),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(center: point, radius: pulseRadius + 38),
            ),
    );
    canvas.drawCircle(
      point,
      pulseRadius + 6,
      Paint()..color = _withAlpha(theme.highlight, 0.10),
    );
    canvas.drawCircle(
      point,
      pulseRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.42),
          colors: <Color>[
            _withAlpha(theme.highlight, 0.74),
            _withAlpha(accent, 0.92),
            _withAlpha(secondary, 0.66),
          ],
          stops: const <double>[0.0, 0.42, 1.0],
        ).createShader(Rect.fromCircle(center: point, radius: pulseRadius)),
    );
  }

  void _paintCenterLens(
    Canvas canvas,
    Size size,
    _FocusVisualizerTheme theme,
    Color accent,
    Offset runner,
    double impact,
  ) {
    final center = _center(size);
    final lensRadius = math.min(size.shortestSide * 0.12, 58.0);
    final distance = (runner - center).distance;
    final direction = distance <= 0.001
        ? const Offset(0, -1)
        : Offset(
            (runner.dx - center.dx) / distance,
            (runner.dy - center.dy) / distance,
          );
    final focus = center + direction * (lensRadius * 0.28);

    canvas.drawCircle(
      center,
      lensRadius + impact * 18 * _accentStrength,
      Paint()
        ..color = _withAlpha(accent, 0.06 + impact * 0.05)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      lensRadius,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(
            ((focus.dx - center.dx) / lensRadius).clamp(-1.0, 1.0),
            ((focus.dy - center.dy) / lensRadius).clamp(-1.0, 1.0),
          ),
          colors: <Color>[
            _withAlpha(accent, 0.28 + impact * 0.04),
            _withAlpha(theme.secondary, 0.32),
            _withAlpha(theme.base, 0.58),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: lensRadius)),
    );
    canvas.drawCircle(
      center,
      lensRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = _withAlpha(theme.highlight, 0.14),
    );
    canvas.drawCircle(
      focus,
      5.5 + impact * 2.5,
      Paint()..color = _withAlpha(accent, running ? 0.76 : 0.48),
    );
  }

  @override
  bool shouldRepaint(covariant _FocusBeatVisualizerPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.bpm != bpm ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.ambientProgress != ambientProgress ||
        oldDelegate.accentLayer != accentLayer ||
        oldDelegate.running != running ||
        oldDelegate.activeBeat != activeBeat ||
        oldDelegate.activeSubPulse != activeSubPulse ||
        oldDelegate.beatsPerBar != beatsPerBar ||
        oldDelegate.subdivision != subdivision;
  }
}

class _FocusVisualizerTheme {
  const _FocusVisualizerTheme({
    required this.base,
    required this.mid,
    required this.surface,
    required this.accent,
    required this.secondary,
    required this.highlight,
  });

  final Color base;
  final Color mid;
  final Color surface;
  final Color accent;
  final Color secondary;
  final Color highlight;
}

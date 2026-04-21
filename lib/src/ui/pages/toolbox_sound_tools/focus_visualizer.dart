part of '../toolbox_sound_tools.dart';

// ignore_for_file: dead_code, unused_element, unused_local_variable

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

  double _mix(double a, double b, double t) => a + (b - a) * t;

  Color _mixColor(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  Color get _layerAccent => switch (accentLayer) {
    0 => const Color(0xFFF3C77C),
    1 => const Color(0xFFF2A88E),
    2 => const Color(0xFF8CCFF8),
    _ => const Color(0xFF8FDEC4),
  };

  _FocusVisualizerTheme get _theme => switch (kind) {
    _FocusBeatAnimationKind.pendulum => const _FocusVisualizerTheme(
      base: Color(0xFF0B1720),
      mid: Color(0xFF142938),
      surface: Color(0xFF1E4054),
      accent: Color(0xFF82C6FF),
      secondary: Color(0xFF78E0D1),
      highlight: Color(0xFFF7E3B7),
    ),
    _FocusBeatAnimationKind.hypno => const _FocusVisualizerTheme(
      base: Color(0xFF16111D),
      mid: Color(0xFF291E35),
      surface: Color(0xFF43304F),
      accent: Color(0xFFB9A0FF),
      secondary: Color(0xFFFFBDD0),
      highlight: Color(0xFFF4EFFF),
    ),
    _FocusBeatAnimationKind.dew => const _FocusVisualizerTheme(
      base: Color(0xFF0A171B),
      mid: Color(0xFF13333A),
      surface: Color(0xFF1D5560),
      accent: Color(0xFF8DD8E5),
      secondary: Color(0xFF6ED6BE),
      highlight: Color(0xFFE9FFF9),
    ),
    _FocusBeatAnimationKind.gear => const _FocusVisualizerTheme(
      base: Color(0xFF101419),
      mid: Color(0xFF1D2A34),
      surface: Color(0xFF304451),
      accent: Color(0xFFA6CAE8),
      secondary: Color(0xFFF1C78D),
      highlight: Color(0xFFF2F7FB),
    ),
    _FocusBeatAnimationKind.steps => const _FocusVisualizerTheme(
      base: Color(0xFF101611),
      mid: Color(0xFF1B3121),
      surface: Color(0xFF2E4A37),
      accent: Color(0xFF91D39E),
      secondary: Color(0xFFB8E4C1),
      highlight: Color(0xFFF1F7EA),
    ),
  };

  double get _phase => pulseProgress.clamp(0.0, 1.0);

  double get _pulseEnergy =>
      running ? 1 - Curves.easeOutCubic.transform(_phase) : 0.0;

  double get _ambientAngle => ambientProgress.clamp(0.0, 1.0) * math.pi * 2;

  int get _barPulseCount => math.max(1, beatsPerBar * subdivision);

  int get _currentPulseIndex {
    if (activeBeat < 0 || activeSubPulse <= 0) {
      return 0;
    }
    return (activeBeat * subdivision + activeSubPulse - 1).clamp(
      0,
      _barPulseCount - 1,
    );
  }

  bool get _isBeatPulse => subdivision <= 1 || activeSubPulse <= 1;

  double get _accentStrength => switch (accentLayer) {
    0 => 1.0,
    1 => 0.82,
    2 => 0.62,
    _ => 0.45,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final theme = _theme;
    final ambient = _ambientAngle;
    final pulse = _pulseEnergy;
    final accent = _mixColor(theme.accent, _layerAccent, 0.28);
    final guideColor = _mixColor(theme.highlight, Colors.white, 0.50);
    final contrastBoost = kind == _FocusBeatAnimationKind.hypno
        ? (_isBeatPulse ? pulse * 0.10 : pulse * 0.05)
        : 0.0;

    _paintMetronomeBackdrop(
      canvas,
      size,
      theme: theme,
      accent: accent,
      ambient: ambient,
      pulse: pulse,
      contrastBoost: contrastBoost,
    );
    if (kind == _FocusBeatAnimationKind.steps) {
      _paintStepsGuideFlow(
        canvas,
        size,
        accent: accent,
        guideColor: guideColor,
        pulse: pulse,
      );
    }

    final pivot = Offset(size.width * 0.5, size.height * 0.18);
    final armLength = size.height * 0.55;
    final beatDirection = activeBeat >= 0 && activeBeat.isOdd ? -1.0 : 1.0;
    final pulseDirection = _currentPulseIndex.isEven ? -1.0 : 1.0;
    final sign = kind == _FocusBeatAnimationKind.pendulum
        ? beatDirection
        : pulseDirection;
    final amplitude =
        (_isBeatPulse ? 0.64 : 0.44) * (0.74 + _accentStrength * 0.26);
    final easedPhase = Curves.easeInOutCubic.transform(_phase);
    final swing = math.sin(
      easedPhase * math.pi - math.pi / 2,
    ); // gravity-like easing
    final angle = running ? sign * swing * amplitude : 0.0;
    final angularVelocity = running
        ? sign *
              math.cos(easedPhase * math.pi - math.pi / 2) *
              math.pi *
              amplitude
        : 0.0;
    final bob = Offset(
      pivot.dx + math.sin(angle) * armLength,
      pivot.dy + math.cos(angle) * armLength,
    );

    _paintMetronomeTicks(
      canvas,
      size,
      pivot: pivot,
      armLength: armLength,
      guideColor: guideColor,
      accent: accent,
      pulse: pulse,
    );

    if (running && kind == _FocusBeatAnimationKind.pendulum && pulse > 0.03) {
      _paintPendulumMotionBlur(
        canvas,
        pivot: pivot,
        armLength: armLength,
        angle: angle,
        angularVelocity: angularVelocity,
        accent: accent,
        pulse: pulse,
      );
    }

    final armPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          guideColor.withValues(alpha: 0.95),
          accent.withValues(alpha: 0.88),
        ],
      ).createShader(Rect.fromPoints(pivot, bob))
      ..strokeWidth = size.shortestSide * 0.010
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pivot, bob, armPaint);

    final bobRadius =
        size.shortestSide * 0.060 + (_isBeatPulse ? 3.5 : 1.5) + pulse * 4;
    canvas.drawCircle(
      bob.translate(0, 10),
      bobRadius,
      Paint()..color = Colors.black.withValues(alpha: 0.24),
    );
    canvas.drawCircle(
      bob,
      bobRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.34, -0.36),
          colors: <Color>[
            theme.highlight.withValues(alpha: 0.95),
            accent.withValues(alpha: 0.96),
            _mixColor(theme.surface, accent, 0.34),
          ],
          stops: const <double>[0.0, 0.34, 1.0],
        ).createShader(Rect.fromCircle(center: bob, radius: bobRadius)),
    );
    canvas.drawCircle(
      bob.translate(-bobRadius * 0.26, -bobRadius * 0.24),
      bobRadius * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.42),
    );

    canvas.drawCircle(
      pivot,
      size.shortestSide * 0.024,
      Paint()
        ..color = _mixColor(theme.surface, accent, 0.40)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      pivot,
      size.shortestSide * 0.015,
      Paint()..color = guideColor.withValues(alpha: 0.94),
    );

    if (kind == _FocusBeatAnimationKind.hypno) {
      _paintHypnoPulseHalo(canvas, pivot: pivot, accent: accent, pulse: pulse);
    }

    _paintPulseRail(
      canvas,
      size,
      accent: accent,
      pulse: pulse,
      guideColor: guideColor,
    );
    _paintBeatMarkers(canvas, size, accent: accent, pulse: pulse);
  }

  void _paintMetronomeBackdrop(
    Canvas canvas,
    Size size, {
    required _FocusVisualizerTheme theme,
    required Color accent,
    required double ambient,
    required double pulse,
    double contrastBoost = 0.0,
  }) {
    final boosted = contrastBoost.clamp(0.0, 0.18);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            _mixColor(
              _mixColor(theme.base, theme.mid, 0.34),
              Colors.white,
              boosted * 0.30,
            ),
            _mixColor(
              _mixColor(theme.mid, theme.surface, 0.26),
              theme.highlight,
              boosted * 0.22,
            ),
            _mixColor(
              _mixColor(theme.surface, theme.base, 0.18),
              Colors.black,
              boosted * 0.14,
            ),
          ],
        ).createShader(rect),
    );

    final glow = Rect.fromCenter(
      center: Offset(
        size.width * (0.50 + math.sin(ambient * 0.18) * 0.03),
        size.height * 0.30,
      ),
      width: size.width * 0.72,
      height: size.height * 0.40,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(glow, const Radius.circular(999)),
      Paint()..color = accent.withValues(alpha: 0.08 + pulse * 0.05),
    );

    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.10),
      Offset(size.width * 0.5, size.height * 0.84),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 1,
    );
  }

  void _paintPendulumMotionBlur(
    Canvas canvas, {
    required Offset pivot,
    required double armLength,
    required double angle,
    required double angularVelocity,
    required Color accent,
    required double pulse,
  }) {
    final velocity = angularVelocity.abs();
    final blurGain = (velocity * 0.34).clamp(0.0, 1.0) * (0.58 + pulse * 0.42);
    for (var i = 1; i <= 4; i += 1) {
      final lag = i * 0.030;
      final ghostAngle = angle - angularVelocity * lag;
      final ghostEnd = Offset(
        pivot.dx + math.sin(ghostAngle) * armLength,
        pivot.dy + math.cos(ghostAngle) * armLength,
      );
      final alpha = (0.14 - i * 0.025) * blurGain;
      if (alpha <= 0.001) {
        continue;
      }
      canvas.drawLine(
        pivot,
        ghostEnd,
        Paint()
          ..color = accent.withValues(alpha: alpha)
          ..strokeWidth = 1.4 + (4 - i) * 0.32
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        ghostEnd,
        8.0 + (4 - i) * 0.8,
        Paint()..color = accent.withValues(alpha: alpha * 0.56),
      );
    }
  }

  void _paintHypnoPulseHalo(
    Canvas canvas, {
    required Offset pivot,
    required Color accent,
    required double pulse,
  }) {
    for (var i = 0; i < 3; i += 1) {
      final radius = 26.0 + i * 18 + pulse * (22 - i * 4);
      canvas.drawCircle(
        pivot,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = accent.withValues(
            alpha: (0.16 - i * 0.045) * (0.5 + pulse),
          ),
      );
    }
  }

  void _paintStepsGuideFlow(
    Canvas canvas,
    Size size, {
    required Color accent,
    required Color guideColor,
    required double pulse,
  }) {
    final speed = (bpm / 60).clamp(0.6, 3.4);
    final flow = (ambientProgress * speed) % 1.0;
    final vanish = Offset(size.width * 0.5, size.height * 0.30);
    final floorY = size.height * 0.90;

    canvas.drawLine(
      Offset(size.width * 0.20, floorY),
      vanish,
      Paint()
        ..color = guideColor.withValues(alpha: 0.20)
        ..strokeWidth = 1.2,
    );
    canvas.drawLine(
      Offset(size.width * 0.80, floorY),
      vanish,
      Paint()
        ..color = guideColor.withValues(alpha: 0.20)
        ..strokeWidth = 1.2,
    );

    for (var i = 0; i < 7; i += 1) {
      final t = ((flow + i * 0.14) % 1.0);
      final eased = Curves.easeIn.transform(t);
      final y = _mix(size.height * 0.38, floorY, eased);
      final half = _mix(size.width * 0.03, size.width * 0.32, eased);
      final alpha = (0.08 + eased * 0.20) * (0.75 + pulse * 0.25);
      canvas.drawLine(
        Offset(size.width * 0.5 - half, y),
        Offset(size.width * 0.5 + half, y),
        Paint()
          ..color = accent.withValues(alpha: alpha)
          ..strokeWidth = 1.0 + eased * 0.8,
      );
    }
  }

  void _paintMetronomeTicks(
    Canvas canvas,
    Size size, {
    required Offset pivot,
    required double armLength,
    required Color guideColor,
    required Color accent,
    required double pulse,
  }) {
    const start = math.pi / 2 - 0.86;
    const sweep = 1.72;
    final arcPaint = Paint()
      ..color = guideColor.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromCircle(center: pivot, radius: armLength),
      start,
      sweep,
      false,
      arcPaint,
    );

    for (var i = 0; i <= 8; i += 1) {
      final t = i / 8;
      final angle = start + sweep * t;
      final outer = Offset(
        pivot.dx + math.cos(angle) * (armLength + 12),
        pivot.dy + math.sin(angle) * (armLength + 12),
      );
      final inner = Offset(
        pivot.dx + math.cos(angle) * (armLength - (i.isEven ? 10 : 5)),
        pivot.dy + math.sin(angle) * (armLength - (i.isEven ? 10 : 5)),
      );
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = i == 4
              ? accent.withValues(alpha: 0.90)
              : guideColor.withValues(alpha: 0.50),
      );
    }

    if (pulse > 0.02) {
      canvas.drawArc(
        Rect.fromCircle(center: pivot, radius: armLength),
        start + sweep * 0.48,
        sweep * 0.04,
        false,
        Paint()
          ..color = accent.withValues(alpha: pulse * 0.48)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4,
      );
    }
  }

  void _paintPulseRail(
    Canvas canvas,
    Size size, {
    required Color accent,
    required Color guideColor,
    required double pulse,
  }) {
    final railY = size.height * 0.82;
    final railLeft = size.width * 0.20;
    final railRight = size.width * 0.80;
    final visibleCount = _barPulseCount.clamp(1, 24);
    final active = visibleCount == 1
        ? 0
        : ((_currentPulseIndex / (_barPulseCount - 1)) * (visibleCount - 1))
              .round();

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(railLeft, railY - 6, railRight, railY + 6),
        const Radius.circular(999),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );

    for (var i = 0; i < visibleCount; i += 1) {
      final x = _mix(
        railLeft + 8,
        railRight - 8,
        visibleCount == 1 ? 0.5 : i / (visibleCount - 1),
      );
      final isActive = i == active;
      canvas.drawCircle(
        Offset(x, railY),
        isActive ? 3.6 + pulse * 1.8 : 2.2,
        Paint()
          ..color = isActive
              ? accent.withValues(alpha: 0.96)
              : guideColor.withValues(alpha: 0.34),
      );
    }
  }

  void _paintBeatMarkers(
    Canvas canvas,
    Size size, {
    required Color accent,
    required double pulse,
  }) {
    final count = math.max(1, beatsPerBar);
    final active = activeBeat < 0 ? 0 : activeBeat % count;
    final y = size.height * 0.91;
    final left = size.width * 0.24;
    final right = size.width * 0.76;

    for (var i = 0; i < count; i += 1) {
      final x = _mix(left, right, count == 1 ? 0.5 : i / (count - 1));
      final isActive = i == active;
      final radius = isActive
          ? 5.2 + (_isBeatPulse ? pulse * 2.2 : pulse * 1.0)
          : 3.0;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = isActive
              ? accent.withValues(alpha: 0.98)
              : Colors.white.withValues(alpha: 0.26),
      );
    }
  }

  double _beatMarker(int beat) {
    if (beatsPerBar <= 1) {
      return 0.0;
    }
    final bounded = beat.clamp(0, beatsPerBar - 1);
    return -1 + 2 * bounded / (beatsPerBar - 1);
  }

  Offset _beatPoint(
    Size size, {
    required double normalized,
    required double y,
    double inset = 0.18,
  }) {
    final left = size.width * inset;
    final right = size.width * (1 - inset);
    return Offset(_mix(left, right, (normalized + 1) / 2), y);
  }

  void _paintFlatBackdrop(
    Canvas canvas,
    Size size, {
    required _FocusVisualizerTheme theme,
    required Color accent,
    required double ambient,
    required double beat,
  }) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[theme.base, theme.mid, theme.surface],
        ).createShader(rect),
    );

    final hazeRect = Rect.fromCenter(
      center: Offset(
        size.width * (0.24 + math.cos(ambient * 0.24) * 0.04),
        size.height * 0.24,
      ),
      width: size.width * 0.72,
      height: size.height * 0.36,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(hazeRect, const Radius.circular(999)),
      Paint()..color = accent.withValues(alpha: 0.10 + beat * 0.04),
    );

    for (var i = 1; i <= 3; i += 1) {
      final y = size.height * (0.18 + i * 0.20);
      canvas.drawLine(
        Offset(size.width * 0.16, y),
        Offset(size.width * 0.84, y),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.05 - i * 0.008)
          ..strokeWidth = 1,
      );
    }
  }

  void _paintFlatPendulum(
    Canvas canvas,
    Size size, {
    required _FocusVisualizerTheme theme,
    required Color accent,
    required double beat,
    required int currentBeat,
    required int nextBeat,
    required double beatTravel,
  }) {
    final pivot = Offset(size.width * 0.5, size.height * 0.18);
    final length = size.height * 0.42;
    final marker = _mix(
      _beatMarker(currentBeat),
      _beatMarker(nextBeat),
      beatTravel,
    );
    final angle = marker * 0.52;
    final bob =
        pivot + Offset(math.sin(angle) * length, math.cos(angle) * length);

    canvas.drawArc(
      Rect.fromCircle(center: pivot, radius: length),
      math.pi / 2 - 0.64,
      1.28,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (var beatIndex = 0; beatIndex < beatsPerBar; beatIndex += 1) {
      final anchor = _beatPoint(
        size,
        normalized: _beatMarker(beatIndex),
        y: size.height * 0.70,
      );
      canvas.drawCircle(
        anchor,
        beatIndex == currentBeat ? 5 + beat * 3 : 3,
        Paint()
          ..color = beatIndex == currentBeat
              ? accent
              : Colors.white.withValues(alpha: 0.18),
      );
    }
    canvas.drawLine(
      pivot,
      bob,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.88)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      pivot,
      6,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    canvas.drawCircle(bob, 20 + beat * 6, Paint()..color = accent);
  }

  void _paintFlatOrbit(
    Canvas canvas,
    Size size, {
    required _FocusVisualizerTheme theme,
    required Color accent,
    required Color glow,
    required double beat,
    required double ambient,
    required int currentBeat,
    required int nextBeat,
    required double beatTravel,
  }) {
    final center = Offset(size.width * 0.5, size.height * 0.48);
    final radius = size.shortestSide * 0.22;
    final marker = _mix(
      _beatMarker(currentBeat),
      _beatMarker(nextBeat),
      beatTravel,
    );
    final angle = -math.pi / 2 + marker * math.pi;

    for (var ring = 0; ring < 4; ring += 1) {
      canvas.drawCircle(
        center,
        radius + ring * 22,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.10 - ring * 0.015)
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring == 0 ? 2.4 : 1.2,
      );
    }

    final orbitRect = Rect.fromCircle(center: center, radius: radius + 42);
    canvas.drawArc(
      orbitRect,
      ambient * 0.18 - math.pi / 2,
      math.pi * (0.52 + beat * 0.22),
      false,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    final dot =
        center +
        Offset(
          math.cos(angle) * (radius + 42),
          math.sin(angle) * (radius + 42),
        );
    canvas.drawCircle(dot, 14 + beat * 4, Paint()..color = accent);
    canvas.drawCircle(
      center,
      16 + beat * 8,
      Paint()..color = glow.withValues(alpha: 0.72),
    );
  }

  void _paintFlatDroplet(
    Canvas canvas,
    Size size, {
    required _FocusVisualizerTheme theme,
    required Color accent,
    required double beat,
    required int currentBeat,
    required int nextBeat,
    required double beatTravel,
  }) {
    final surfaceY = size.height * 0.70;
    final current = _beatPoint(
      size,
      normalized: _beatMarker(currentBeat),
      y: surfaceY,
    );
    final next = _beatPoint(
      size,
      normalized: _beatMarker(nextBeat),
      y: surfaceY,
    );
    final dropCenter = Offset(
      _mix(current.dx, next.dx, beatTravel),
      _mix(size.height * 0.26, surfaceY - 12, beatTravel),
    );

    canvas.drawLine(
      Offset(size.width * 0.16, surfaceY),
      Offset(size.width * 0.84, surfaceY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = 2,
    );
    for (var ring = 0; ring < 3; ring += 1) {
      canvas.drawOval(
        Rect.fromCenter(
          center: current,
          width: 36 + beat * 50 + ring * 20,
          height: 10 + beat * 10 + ring * 6,
        ),
        Paint()
          ..color = accent.withValues(alpha: 0.18 - ring * 0.04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }

    final path = _buildDropletPath(dropCenter, 16 + beat * 2, 24 + beat * 6);
    canvas.drawPath(path, Paint()..color = accent);
  }

  void _paintFlatRotor(
    Canvas canvas,
    Size size, {
    required _FocusVisualizerTheme theme,
    required Color accent,
    required double beat,
    required double ambient,
    required int currentBeat,
    required int nextBeat,
    required double beatTravel,
  }) {
    final center = Offset(size.width * 0.5, size.height * 0.48);
    final outerRadius = size.shortestSide * 0.28;
    final innerRadius = size.shortestSide * 0.14;
    final marker = _mix(
      _beatMarker(currentBeat),
      _beatMarker(nextBeat),
      beatTravel,
    );
    final rotation = ambient * 0.12 + marker * math.pi;

    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (var tooth = 0; tooth < beatsPerBar; tooth += 1) {
      final angle = rotation + tooth * math.pi * 2 / beatsPerBar;
      final inner =
          center +
          Offset(math.cos(angle) * innerRadius, math.sin(angle) * innerRadius);
      final outer =
          center +
          Offset(math.cos(angle) * outerRadius, math.sin(angle) * outerRadius);
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = tooth == currentBeat
              ? accent
              : Colors.white.withValues(alpha: 0.22)
          ..strokeWidth = tooth == currentBeat ? 4 : 2
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(center, 16 + beat * 5, Paint()..color = accent);
  }

  void _paintFlatSteps(
    Canvas canvas,
    Size size, {
    required _FocusVisualizerTheme theme,
    required Color accent,
    required double beat,
    required int currentBeat,
    required int nextBeat,
    required double beatTravel,
  }) {
    final bars = math.max(3, beatsPerBar);
    final width = size.width * 0.66;
    final barWidth = width / (bars * 1.35);
    final gap = barWidth * 0.35;
    final startX = (size.width - (bars * barWidth + (bars - 1) * gap)) / 2;
    final baseY = size.height * 0.74;
    final scanX = _mix(
      _beatPoint(
        size,
        normalized: _beatMarker(currentBeat),
        y: baseY,
        inset: 0.22,
      ).dx,
      _beatPoint(
        size,
        normalized: _beatMarker(nextBeat),
        y: baseY,
        inset: 0.22,
      ).dx,
      beatTravel,
    );

    for (var index = 0; index < bars; index += 1) {
      final x = startX + index * (barWidth + gap);
      final centerX = x + barWidth / 2;
      final isActive = index == currentBeat;
      final distance = (centerX - scanX).abs() / (barWidth * 3);
      final influence = (1 - distance).clamp(0.0, 1.0);
      final height =
          size.height * (0.16 + 0.10 * index / bars) + influence * 28;
      final rect = RRect.fromLTRBR(
        x,
        baseY - height,
        x + barWidth,
        baseY,
        Radius.circular(barWidth * 0.42),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = isActive
              ? accent
              : Colors.white.withValues(alpha: 0.12 + influence * 0.20),
      );
    }

    canvas.drawLine(
      Offset(startX, baseY + 8),
      Offset(startX + bars * barWidth + (bars - 1) * gap, baseY + 8),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..strokeWidth = 2,
    );
  }

  void _paintFlatPulseDock(
    Canvas canvas,
    Size size, {
    required _FocusVisualizerTheme theme,
    required Color accent,
  }) {
    final width = math.min(size.width * 0.40, 180.0);
    final rect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.88),
      width: width,
      height: 12,
    );
    final dock = RRect.fromRectAndRadius(rect, const Radius.circular(999));
    canvas.drawRRect(
      dock,
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
    final count = math.max(1, subdivision);
    final spacing = rect.width / (count + 1);
    for (var index = 0; index < count; index += 1) {
      final active = activeSubPulse > 0 && activeSubPulse - 1 == index;
      canvas.drawCircle(
        Offset(rect.left + spacing * (index + 1), rect.center.dy),
        active ? 4.5 : 2.5,
        Paint()
          ..color = active ? accent : theme.highlight.withValues(alpha: 0.26),
      );
    }
  }

  void _paintBackdrop(
    Canvas canvas,
    Size size, {
    required _FocusVisualizerTheme theme,
    required Color accent,
    required Color glow,
    required double beat,
    required double breath,
    required double ambient,
  }) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            theme.base,
            theme.mid,
            _mixColor(theme.surface, Colors.black, 0.10),
          ],
          stops: const <double>[0.0, 0.48, 1.0],
        ).createShader(rect),
    );

    _paintGlow(
      canvas,
      Offset(
        size.width * 0.20 + math.cos(ambient * 0.9) * size.width * 0.05,
        size.height * 0.20 + math.sin(ambient * 0.65) * size.height * 0.03,
      ),
      size.width * 0.30,
      accent.withValues(alpha: 0.11 + beat * 0.05),
      blur: 42,
    );
    _paintGlow(
      canvas,
      Offset(
        size.width * 0.78 + math.sin(ambient * 0.55) * size.width * 0.04,
        size.height * 0.74 + math.cos(ambient * 0.72) * size.height * 0.04,
      ),
      size.width * 0.36,
      glow.withValues(alpha: 0.10 + breath * 0.05),
      blur: 54,
    );

    _paintRibbon(
      canvas,
      size,
      y: size.height * 0.26,
      drift: math.sin(ambient * 0.72) * 18,
      amplitude: 22,
      thickness: 20,
      color: theme.highlight.withValues(alpha: 0.045),
    );
    _paintRibbon(
      canvas,
      size,
      y: size.height * 0.60,
      drift: math.cos(ambient * 0.84) * 22,
      amplitude: 28,
      thickness: 28,
      color: accent.withValues(alpha: 0.05),
    );

    final scanY = size.height * (0.34 + breath * 0.16);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(0, (scanY / size.height) * 2 - 1),
          end: Alignment(
            0,
            ((scanY + size.height * 0.22) / size.height) * 2 - 1,
          ),
          colors: <Color>[
            Colors.transparent,
            Colors.white.withValues(alpha: 0.025 + beat * 0.01),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Colors.transparent,
            Colors.black.withValues(alpha: running ? 0.28 : 0.34),
          ],
          stops: const <double>[0.56, 1.0],
        ).createShader(rect),
    );
  }

  void _paintPendulum(
    Canvas canvas,
    Size size,
    _FocusVisualizerTheme theme,
    Color accent,
    Color glow,
    double beat,
    double ambient,
  ) {
    final pivot = Offset(size.width * 0.5, size.height * 0.22);
    final length = size.height * 0.36;
    final direction = activeBeat >= 0 && activeBeat.isOdd ? -1.0 : 1.0;
    final travel = direction * math.cos(_phase * math.pi);
    final angle = travel * 0.64;
    final bob =
        pivot + Offset(math.sin(angle) * length, math.cos(angle) * length);

    final arcRect = Rect.fromCircle(center: pivot, radius: length);
    for (var i = 0; i < 3; i += 1) {
      final radius = length + i * 12.0;
      canvas.drawArc(
        Rect.fromCircle(center: pivot, radius: radius),
        math.pi / 2 - 0.70,
        1.40,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06 - i * 0.015)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    for (var i = 1; i <= 5; i += 1) {
      final samplePhase = (_phase - i * 0.10).clamp(0.0, 1.0);
      final sampleTravel = direction * math.cos(samplePhase * math.pi);
      final sampleAngle = sampleTravel * 0.64;
      final sampleBob =
          pivot +
          Offset(
            math.sin(sampleAngle) * length,
            math.cos(sampleAngle) * length,
          );
      canvas.drawCircle(
        sampleBob,
        12 - i * 1.8,
        Paint()
          ..color = accent.withValues(alpha: 0.10 - i * 0.012)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    canvas.drawLine(
      pivot,
      bob,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            theme.highlight.withValues(alpha: 0.34),
            accent.withValues(alpha: 0.88),
          ],
        ).createShader(Rect.fromPoints(pivot, bob))
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    _paintGlow(
      canvas,
      pivot,
      22 + beat * 8,
      theme.highlight.withValues(alpha: 0.16),
      blur: 18,
    );
    canvas.drawCircle(
      pivot,
      5.5,
      Paint()..color = Colors.white.withValues(alpha: 0.86),
    );

    _paintGlow(
      canvas,
      bob,
      34 + beat * 18,
      glow.withValues(alpha: 0.22 + beat * 0.08),
      blur: 28,
    );
    canvas.drawCircle(
      bob,
      19 + beat * 5,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            theme.highlight.withValues(alpha: 0.96),
            accent.withValues(alpha: 0.84),
            accent.withValues(alpha: 0.10),
          ],
          stops: const <double>[0.0, 0.58, 1.0],
        ).createShader(Rect.fromCircle(center: bob, radius: 24 + beat * 8)),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bob.dx, size.height * 0.78),
        width: 96 + beat * 26,
        height: 18 + beat * 6,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
  }

  void _paintHypno(
    Canvas canvas,
    Size size,
    _FocusVisualizerTheme theme,
    Color accent,
    Color glow,
    double beat,
    double ambient,
    double breath,
  ) {
    final center = Offset(size.width * 0.5, size.height * 0.48);
    final baseRadius = size.shortestSide * 0.15;

    for (var i = 0; i < 6; i += 1) {
      final radius = baseRadius + size.shortestSide * 0.08 * i + breath * 6;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.10 - i * 0.012)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    for (var i = 0; i < 4; i += 1) {
      final radius = baseRadius + size.shortestSide * (0.08 + i * 0.10);
      final rect = Rect.fromCircle(center: center, radius: radius);
      final rotation =
          ambient * (0.34 + i * 0.12) * (i.isEven ? 1 : -1) + i * 0.8;
      final sweep = 0.74 + beat * 0.38 - i * 0.04;
      canvas.drawArc(
        rect,
        rotation,
        sweep,
        false,
        Paint()
          ..shader = SweepGradient(
            startAngle: rotation,
            endAngle: rotation + sweep,
            colors: <Color>[
              Colors.transparent,
              accent.withValues(alpha: 0.58 - i * 0.08),
              theme.highlight.withValues(alpha: 0.16),
            ],
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9 - i * 1.5
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawArc(
        rect,
        rotation + math.pi,
        sweep * 0.72,
        false,
        Paint()
          ..color = glow.withValues(alpha: 0.16 - i * 0.02)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 - i * 0.5
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.drawCircle(
      center,
      baseRadius * 0.54 + beat * 9,
      Paint()
        ..shader =
            RadialGradient(
              colors: <Color>[
                theme.highlight.withValues(alpha: 0.94),
                accent.withValues(alpha: 0.44),
                Colors.transparent,
              ],
              stops: const <double>[0.0, 0.48, 1.0],
            ).createShader(
              Rect.fromCircle(
                center: center,
                radius: baseRadius * 0.92 + beat * 14,
              ),
            ),
    );

    if (beat > 0.02) {
      canvas.drawCircle(
        center,
        baseRadius * (1.16 + beat * 1.8),
        Paint()
          ..color = glow.withValues(alpha: 0.22 * beat)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8 * beat + 1.2,
      );
    }
  }

  void _paintDew(
    Canvas canvas,
    Size size,
    _FocusVisualizerTheme theme,
    Color accent,
    Color glow,
    double beat,
    double ambient,
  ) {
    final surfaceY = size.height * 0.67;
    final centerX =
        size.width * 0.5 + math.sin(ambient * 0.62) * size.width * 0.05;
    final surfaceCenter = Offset(centerX, surfaceY);

    final poolRect = Rect.fromCenter(
      center: surfaceCenter,
      width: size.width * 0.42,
      height: size.height * 0.08,
    );
    canvas.drawOval(
      poolRect,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[accent.withValues(alpha: 0.18), Colors.transparent],
        ).createShader(poolRect),
    );

    for (var i = 0; i < 4; i += 1) {
      final radiusX = size.width * (0.10 + i * 0.07) + beat * size.width * 0.10;
      final radiusY = radiusX * 0.16;
      canvas.drawOval(
        Rect.fromCenter(
          center: surfaceCenter,
          width: radiusX * 2,
          height: radiusY * 2,
        ),
        Paint()
          ..color = Colors.white.withValues(
            alpha: 0.14 - i * 0.025 + beat * 0.05,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    final retract = Curves.easeOutCubic.transform(_phase);
    final dropCenter = Offset(
      centerX + math.sin(ambient * 1.08) * 10,
      _mix(surfaceY - 30, size.height * 0.30 + math.cos(ambient) * 8, retract),
    );
    final threadTop = Offset(centerX, size.height * 0.16);
    canvas.drawLine(
      threadTop,
      dropCenter.translate(0, -16),
      Paint()
        ..color = theme.highlight.withValues(alpha: 0.20)
        ..strokeWidth = 1.0,
    );

    final dropPath = _buildDropletPath(
      dropCenter,
      18 + beat * 4,
      28 + beat * 8,
    );
    final dropBounds = dropPath.getBounds();
    _paintGlow(
      canvas,
      dropCenter,
      28 + beat * 12,
      glow.withValues(alpha: 0.18 + beat * 0.08),
      blur: 22,
    );
    canvas.drawPath(
      dropPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            theme.highlight.withValues(alpha: 0.94),
            accent.withValues(alpha: 0.78),
            glow.withValues(alpha: 0.24),
          ],
          stops: const <double>[0.0, 0.56, 1.0],
        ).createShader(dropBounds),
    );
    canvas.drawPath(
      dropPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = Colors.white.withValues(alpha: 0.28),
    );

    for (var i = 0; i < 2; i += 1) {
      final bead = Offset(
        centerX + (i == 0 ? -1 : 1) * size.width * 0.12,
        size.height * (0.44 + i * 0.08) + math.sin(ambient + i) * 6,
      );
      canvas.drawCircle(
        bead,
        5 + i.toDouble(),
        Paint()
          ..color = theme.highlight.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
  }

  void _paintGear(
    Canvas canvas,
    Size size,
    _FocusVisualizerTheme theme,
    Color accent,
    Color glow,
    double beat,
    double ambient,
  ) {
    final center = Offset(size.width * 0.52, size.height * 0.48);
    final radii = <double>[
      size.shortestSide * 0.15,
      size.shortestSide * 0.24,
      size.shortestSide * 0.34,
    ];

    canvas.drawLine(
      Offset(center.dx - size.width * 0.24, center.dy),
      Offset(center.dx + size.width * 0.24, center.dy),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 1.0,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - size.height * 0.24),
      Offset(center.dx, center.dy + size.height * 0.24),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 1.0,
    );

    for (final radius in radii) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    for (var ring = 0; ring < radii.length; ring += 1) {
      final radius = radii[ring];
      final count = 4 + ring * 2;
      final rotation =
          ambient * (0.50 + ring * 0.20) * (ring.isEven ? 1 : -1) + ring * 0.36;
      final polygon = Path();
      for (var i = 0; i < count; i += 1) {
        final angle = rotation + i * math.pi * 2 / count;
        final point =
            center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
        if (i == 0) {
          polygon.moveTo(point.dx, point.dy);
        } else {
          polygon.lineTo(point.dx, point.dy);
        }
        canvas.drawCircle(
          point,
          4.0 + (ring == 1 ? beat * 1.8 : beat),
          Paint()
            ..color = _mixColor(
              accent,
              theme.highlight,
              ring * 0.22,
            ).withValues(alpha: 0.78 - ring * 0.14),
        );
      }
      polygon.close();
      canvas.drawPath(
        polygon,
        Paint()
          ..color = glow.withValues(alpha: 0.10 - ring * 0.015)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    final sweepRect = Rect.fromCircle(center: center, radius: radii.last + 12);
    final start = ambient * 0.92;
    final sweep = 0.74 + beat * 0.30;
    canvas.drawArc(
      sweepRect,
      start,
      sweep,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: start,
          endAngle: start + sweep,
          colors: <Color>[
            Colors.transparent,
            accent.withValues(alpha: 0.58),
            Colors.transparent,
          ],
        ).createShader(sweepRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    _paintGlow(
      canvas,
      center,
      34 + beat * 12,
      glow.withValues(alpha: 0.16 + beat * 0.08),
      blur: 20,
    );
    canvas.drawCircle(
      center,
      18 + beat * 4,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            theme.highlight.withValues(alpha: 0.92),
            accent.withValues(alpha: 0.74),
            theme.base.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 24 + beat * 8)),
    );
  }

  void _paintSteps(
    Canvas canvas,
    Size size,
    _FocusVisualizerTheme theme,
    Color accent,
    Color glow,
    double beat,
    double ambient,
  ) {
    const profile = <double>[0.28, 0.42, 0.58, 0.76, 0.58, 0.42, 0.28];
    final bars = profile.length;
    final barWidth = size.width * 0.075;
    final gap = size.width * 0.028;
    final totalWidth = bars * barWidth + (bars - 1) * gap;
    final startX = (size.width - totalWidth) / 2;
    final baseY = size.height * 0.74;
    final fieldHeight = size.height * 0.42;
    final scanT = 0.5 + 0.5 * math.sin(ambient * 0.56 - math.pi / 2);
    final scanX = _mix(startX, startX + totalWidth, scanT);
    final skyline = Path();

    canvas.drawLine(
      Offset(size.width * 0.16, baseY + 4),
      Offset(size.width * 0.84, baseY + 4),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..strokeWidth = 1.2,
    );

    for (var i = 0; i < bars; i += 1) {
      final x = startX + i * (barWidth + gap);
      final centerX = x + barWidth / 2;
      final dist = ((centerX - scanX).abs() / (barWidth * 2.1)).clamp(0.0, 1.0);
      final influence = 1 - dist;
      final height = fieldHeight * profile[i] + influence * 18 + beat * 10;
      final rect = RRect.fromLTRBR(
        x,
        baseY - height,
        x + barWidth,
        baseY,
        Radius.circular(barWidth * 0.48),
      );
      final topCenter = Offset(centerX, baseY - height);

      if (i == 0) {
        skyline.moveTo(topCenter.dx, topCenter.dy);
      } else {
        skyline.lineTo(topCenter.dx, topCenter.dy);
      }

      if (influence > 0.02) {
        _paintGlow(
          canvas,
          Offset(centerX, baseY - height * 0.56),
          18 + influence * 12,
          accent.withValues(alpha: influence * 0.10),
          blur: 18,
        );
      }

      canvas.drawRRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: <Color>[
              theme.surface.withValues(alpha: 0.92),
              _mixColor(
                accent,
                theme.highlight,
                influence * 0.42,
              ).withValues(alpha: 0.90),
            ],
          ).createShader(rect.outerRect),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Colors.white.withValues(alpha: 0.16 + influence * 0.14),
      );
    }

    canvas.drawPath(
      skyline,
      Paint()
        ..color = glow.withValues(alpha: 0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final scanRect = Rect.fromLTRB(
      scanX - barWidth * 0.72,
      baseY - fieldHeight * 0.98,
      scanX + barWidth * 0.72,
      baseY + 10,
    );
    canvas.drawRect(
      scanRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            accent.withValues(alpha: 0.0),
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.0),
          ],
        ).createShader(scanRect),
    );
  }

  void _paintPulseDock(
    Canvas canvas,
    Size size,
    _FocusVisualizerTheme theme,
    Color accent,
    double beat,
  ) {
    final width = math.min(size.width * 0.44, 180.0);
    final dockRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.89),
      width: width,
      height: 18,
    );
    final dock = RRect.fromRectAndRadius(dockRect, const Radius.circular(999));
    canvas.drawRRect(
      dock,
      Paint()..color = Colors.black.withValues(alpha: 0.20),
    );
    canvas.drawRRect(
      dock,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.10),
    );

    final count = math.max(1, subdivision);
    final spacing = dockRect.width / (count + 1);
    for (var i = 0; i < count; i += 1) {
      final active =
          activeSubPulse > 0 && i == (activeSubPulse - 1).clamp(0, count - 1);
      final center = Offset(
        dockRect.left + spacing * (i + 1),
        dockRect.center.dy,
      );
      final radius = active ? 4.6 + beat * 2.2 : 2.6;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = (active ? accent : theme.highlight).withValues(
            alpha: active ? 0.94 : 0.32,
          ),
      );
    }

    if (beat > 0.02) {
      canvas.drawRRect(
        dock,
        Paint()
          ..color = accent.withValues(alpha: 0.08 * beat)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  void _paintGlow(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    double blur = 24,
  }) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
    );
  }

  void _paintRibbon(
    Canvas canvas,
    Size size, {
    required double y,
    required double drift,
    required double amplitude,
    required double thickness,
    required Color color,
  }) {
    final path = Path()
      ..moveTo(-size.width * 0.08, y)
      ..cubicTo(
        size.width * 0.14,
        y - amplitude + drift * 0.28,
        size.width * 0.40,
        y + amplitude * 0.9 - drift * 0.18,
        size.width * 0.66,
        y + drift * 0.22,
      )
      ..cubicTo(
        size.width * 0.86,
        y - amplitude * 0.55 - drift * 0.12,
        size.width * 1.02,
        y + amplitude * 0.22,
        size.width * 1.08,
        y - drift * 0.18,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
  }

  Path _buildDropletPath(Offset center, double width, double height) {
    return Path()
      ..moveTo(center.dx, center.dy - height * 0.72)
      ..quadraticBezierTo(
        center.dx + width * 0.56,
        center.dy - height * 0.20,
        center.dx + width * 0.42,
        center.dy + height * 0.20,
      )
      ..quadraticBezierTo(
        center.dx + width * 0.24,
        center.dy + height * 0.66,
        center.dx,
        center.dy + height * 0.82,
      )
      ..quadraticBezierTo(
        center.dx - width * 0.24,
        center.dy + height * 0.66,
        center.dx - width * 0.42,
        center.dy + height * 0.20,
      )
      ..quadraticBezierTo(
        center.dx - width * 0.56,
        center.dy - height * 0.20,
        center.dx,
        center.dy - height * 0.72,
      )
      ..close();
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

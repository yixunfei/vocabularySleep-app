part of '../toolbox_sound_tools.dart';

// ignore_for_file: dead_code, unused_element, unused_local_variable

class _LegacyFocusBeatVisualizerPainter extends CustomPainter {
  const _LegacyFocusBeatVisualizerPainter({
    required this.kind,
    required this.pulseProgress,
    required this.ambientProgress,
    required this.accentLayer,
    required this.running,
    required this.activeBeat,
    required this.activeSubPulse,
    required this.subdivision,
  });

  final _FocusBeatAnimationKind kind;
  final double pulseProgress;
  final double ambientProgress;
  final int accentLayer;
  final bool running;
  final int activeBeat;
  final int activeSubPulse;
  final int subdivision;

  Color get _accentColor => switch (accentLayer) {
    0 => const Color(0xFFFFD27D),
    1 => const Color(0xFFFFB58A),
    2 => const Color(0xFF8CD6FF),
    _ => const Color(0xFF8BE8C6),
  };

  double _mix(double a, double b, double t) => a + (b - a) * t;

  List<Color> _palette() {
    return switch (kind) {
      _FocusBeatAnimationKind.pendulum => const <Color>[
        Color(0xFF16263D),
        Color(0xFF283E66),
        Color(0xFF2E4D86),
      ],
      _FocusBeatAnimationKind.hypno => const <Color>[
        Color(0xFF2A1244),
        Color(0xFF4D1E73),
        Color(0xFF7A2EA2),
      ],
      _FocusBeatAnimationKind.dew => const <Color>[
        Color(0xFF0F2D3A),
        Color(0xFF1B5668),
        Color(0xFF2587A4),
      ],
      _FocusBeatAnimationKind.gear => const <Color>[
        Color(0xFF242A33),
        Color(0xFF3D4756),
        Color(0xFF556174),
      ],
      _FocusBeatAnimationKind.steps => const <Color>[
        Color(0xFF1E2A24),
        Color(0xFF365142),
        Color(0xFF4A6E56),
      ],
    };
  }

  double get _ambientSpeed => switch (kind) {
    _FocusBeatAnimationKind.pendulum => 0.7,
    _FocusBeatAnimationKind.hypno => 1.25,
    _FocusBeatAnimationKind.dew => 0.85,
    _FocusBeatAnimationKind.gear => 1.4,
    _FocusBeatAnimationKind.steps => 1.0,
  };

  void _paintAmbientBackdrop(Canvas canvas, Size size, double pulse) {
    final palette = _palette();
    final baseRect = Offset.zero & size;
    final phase = ambientProgress * math.pi * 2 * _ambientSpeed;
    final drift = Offset(math.cos(phase) * 26, math.sin(phase * 0.8) * 20);
    final center = size.center(Offset.zero) + drift;

    canvas.drawRect(
      baseRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            palette[0],
            palette[1].withValues(alpha: 0.95),
            palette[2].withValues(alpha: 0.9),
          ],
          stops: const <double>[0.0, 0.58, 1.0],
        ).createShader(baseRect),
    );

    canvas.drawRect(
      baseRect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(
            (center.dx / size.width) * 2 - 1,
            (center.dy / size.height) * 2 - 1,
          ),
          radius: 0.9,
          colors: <Color>[
            _accentColor.withValues(alpha: 0.22 + pulse * 0.1),
            Colors.transparent,
          ],
        ).createShader(baseRect),
    );

    for (var i = 0; i < 8; i += 1) {
      final t = i / 8;
      final angle = phase + t * math.pi * 2;
      final orbitRadius = size.shortestSide * (0.22 + t * 0.22);
      final dot =
          center +
          Offset(
            math.cos(angle) * orbitRadius,
            math.sin(angle * 0.9) * orbitRadius * 0.55,
          );
      final r = _mix(1.6, 4.0, 1 - t) + pulse * 0.9;
      canvas.drawCircle(
        dot,
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: _mix(0.04, 0.18, 1 - t)),
      );
    }

    final vignetteColor = Colors.black.withValues(alpha: running ? 0.22 : 0.3);
    canvas.drawRect(
      baseRect,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[Colors.transparent, vignetteColor],
          stops: const <double>[0.62, 1.0],
        ).createShader(baseRect),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final easedPulse =
        1 - Curves.easeOutCubic.transform(pulseProgress.clamp(0.0, 1.0));
    _paintAmbientBackdrop(canvas, size, easedPulse);

    switch (kind) {
      case _FocusBeatAnimationKind.pendulum:
        _paintPendulum(canvas, size, easedPulse);
        break;
      case _FocusBeatAnimationKind.hypno:
        _paintHypno(canvas, size, easedPulse);
        break;
      case _FocusBeatAnimationKind.dew:
        _paintDew(canvas, size, easedPulse);
        break;
      case _FocusBeatAnimationKind.gear:
        _paintGear(canvas, size, easedPulse);
        break;
      case _FocusBeatAnimationKind.steps:
        _paintSteps(canvas, size, easedPulse);
        break;
    }

    _paintBeatIndicators(canvas, size, easedPulse);
  }

  void _paintPendulum(Canvas canvas, Size size, double pulse) {
    final phase = pulseProgress.clamp(0.0, 1.0);
    final swingDirection = activeBeat >= 0
        ? (activeBeat.isOdd ? -1.0 : 1.0)
        : 1.0;
    final harmonic = math.cos(math.pi * phase);
    final motionEnergy = math.sin(math.pi * phase).abs();
    final angle = swingDirection * harmonic * 0.52;
    final frameRect = Rect.fromLTWH(
      size.width * 0.15,
      size.height * 0.06,
      size.width * 0.70,
      size.height * 0.82,
    );
    final chamberRect = Rect.fromLTWH(
      size.width * 0.28,
      size.height * 0.24,
      size.width * 0.44,
      size.height * 0.46,
    );
    final dialCenter = Offset(size.width * 0.5, size.height * 0.16);
    final pivot = Offset(size.width * 0.5, size.height * 0.28);
    final length = size.height * 0.44;
    final bob = Offset(
      pivot.dx + math.sin(angle) * length,
      pivot.dy + math.cos(angle) * length,
    );

    canvas.drawShadow(
      Path()..addRRect(
        RRect.fromRectAndRadius(frameRect, const Radius.circular(22)),
      ),
      Colors.black.withValues(alpha: 0.45),
      18,
      false,
    );

    final cabinetPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF8B5A2B),
          Color(0xFF5C3D1E),
          Color(0xFF9A6B3F),
          Color(0xFF6E4A28),
        ],
        stops: <double>[0.0, 0.35, 0.7, 1.0],
      ).createShader(frameRect);

    final baseRect = Rect.fromLTWH(
      size.width * 0.18,
      size.height * 0.78,
      size.width * 0.64,
      size.height * 0.12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(18)),
      cabinetPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(18)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = const Color(0xFFD4A56A).withValues(alpha: 0.52),
    );

    final columnWidth = size.width * 0.06;
    _drawPendulumColumn(
      canvas,
      rect: Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.18,
        columnWidth,
        size.height * 0.60,
      ),
    );
    _drawPendulumColumn(
      canvas,
      rect: Rect.fromLTWH(
        size.width * 0.76,
        size.height * 0.18,
        columnWidth,
        size.height * 0.60,
      ),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(chamberRect, const Radius.circular(26)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF1E1510), Color(0xFF0C0806)],
        ).createShader(chamberRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(chamberRect, const Radius.circular(26)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF3A2818).withValues(alpha: 0.48),
    );

    final headRect = Rect.fromLTWH(
      size.width * 0.20,
      size.height * 0.06,
      size.width * 0.60,
      size.height * 0.20,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        headRect,
        topLeft: const Radius.circular(38),
        topRight: const Radius.circular(38),
        bottomLeft: const Radius.circular(16),
        bottomRight: const Radius.circular(16),
      ),
      cabinetPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        headRect,
        topLeft: const Radius.circular(38),
        topRight: const Radius.circular(38),
        bottomLeft: const Radius.circular(16),
        bottomRight: const Radius.circular(16),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = const Color(0xFFC99B5F).withValues(alpha: 0.48),
    );

    _drawClockDial(
      canvas,
      center: dialCenter,
      radius: size.shortestSide * 0.16,
    );

    final trailStrength = (motionEnergy * 0.85).clamp(0.0, 1.0);
    for (var i = 1; i <= 5; i += 1) {
      final trailPhase = (phase - i * 0.08).clamp(0.0, 1.0);
      final trailAngle = swingDirection * math.cos(math.pi * trailPhase) * 0.52;
      final trailBob = Offset(
        pivot.dx + math.sin(trailAngle) * length,
        pivot.dy + math.cos(trailAngle) * length,
      );
      canvas.drawLine(
        pivot,
        trailBob,
        Paint()
          ..color = const Color(
            0xFFE5C89E,
          ).withValues(alpha: trailStrength * (0.18 - i * 0.03))
          ..strokeWidth = 2.8 - i * 0.4,
      );
      canvas.drawCircle(
        trailBob,
        18 - i * 3,
        Paint()
          ..color = _accentColor.withValues(
            alpha: trailStrength * (0.12 - i * 0.02),
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    _drawPendulumChain(
      canvas,
      pivot: pivot,
      bob: bob,
      pulse: motionEnergy,
      accentColor: _accentColor,
    );

    canvas.drawCircle(
      bob.translate(0, 8),
      26 + motionEnergy * 10,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    final bobRadius = 24 + pulse * 7;
    canvas.drawCircle(
      bob,
      bobRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.28, -0.36),
          radius: 1.0,
          colors: <Color>[
            const Color(0xFFFFF8D8).withValues(alpha: 1.0),
            const Color(0xFFF5C65A).withValues(alpha: 0.98),
            const Color(0xFFC4872F).withValues(alpha: 0.96),
            const Color(0xFF8B5C1D).withValues(alpha: 0.94),
          ],
          stops: const <double>[0.0, 0.28, 0.58, 1.0],
        ).createShader(Rect.fromCircle(center: bob, radius: bobRadius + 8)),
    );
    canvas.drawCircle(
      bob,
      bobRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = const Color(0xFFFFE8B0).withValues(alpha: 0.62),
    );
    canvas.drawCircle(
      bob.translate(-8, -10),
      5.5,
      Paint()..color = Colors.white.withValues(alpha: 0.82),
    );
    canvas.drawCircle(
      bob.translate(4, -6),
      2.8,
      Paint()..color = Colors.white.withValues(alpha: 0.38),
    );
    canvas.drawCircle(
      bob,
      bobRadius + 8 + motionEnergy * 6,
      Paint()
        ..color = _accentColor.withValues(alpha: 0.22 + motionEnergy * 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    final reflectionGlow = motionEnergy * 0.4;
    canvas.drawArc(
      Rect.fromCircle(center: bob, radius: bobRadius * 0.85),
      -math.pi * 0.6 - angle * 0.5,
      math.pi * 0.35 + reflectionGlow * 0.12,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.16 + reflectionGlow * 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawPendulumChain(
    Canvas canvas, {
    required Offset pivot,
    required Offset bob,
    required double pulse,
    required Color accentColor,
  }) {
    final dx = bob.dx - pivot.dx;
    final dy = bob.dy - pivot.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final angle = math.atan2(dy, dx);

    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle - math.pi / 2);

    final stemRect = Rect.fromCenter(
      center: Offset(0, distance * 0.18),
      width: 5.2,
      height: distance * 0.36,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(stemRect, const Radius.circular(999)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFE5C89E),
            Color(0xFFA87842),
            Color(0xFF8B6230),
          ],
        ).createShader(stemRect),
    );

    final lyreHeight = distance * 0.24;
    final lyreTop = distance * 0.30;
    final leftRail = Path()
      ..moveTo(-12, lyreTop)
      ..quadraticBezierTo(
        -22,
        lyreTop + lyreHeight * 0.28,
        -12,
        lyreTop + lyreHeight,
      )
      ..moveTo(12, lyreTop)
      ..quadraticBezierTo(
        22,
        lyreTop + lyreHeight * 0.28,
        12,
        lyreTop + lyreHeight,
      );
    canvas.drawPath(
      leftRail,
      Paint()
        ..color = const Color(0xFFDAA65C).withValues(alpha: 0.98)
        ..strokeWidth = 2.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < 4; i += 1) {
      final y = lyreTop + lyreHeight * (0.16 + i * 0.22);
      canvas.drawLine(
        Offset(-10.5, y),
        Offset(10.5, y),
        Paint()
          ..color = const Color(0xFFF2D8A0).withValues(alpha: 0.82)
          ..strokeWidth = 1.4,
      );
    }
    canvas.drawLine(
      Offset(0, lyreTop),
      Offset(0, distance - 36),
      Paint()
        ..color = const Color(0xFFE8C890).withValues(alpha: 0.96)
        ..strokeWidth = 2.0,
    );

    final pivotCap = Rect.fromCenter(
      center: const Offset(0, 0),
      width: 22,
      height: 12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pivotCap, const Radius.circular(999)),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            Color(0xFFFCE8B8),
            Color(0xFFB8844A),
            Color(0xFF9A6A38),
          ],
        ).createShader(pivotCap),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pivotCap, const Radius.circular(999)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = const Color(0xFFE0B878).withValues(alpha: 0.48),
    );
    canvas.restore();

    canvas.drawCircle(
      pivot,
      6.2,
      Paint()..color = const Color(0xFFF8E4A8).withValues(alpha: 0.96),
    );
    canvas.drawCircle(
      pivot,
      4.0,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[Color(0xFFFEF4D8), Color(0xFFC49850)],
        ).createShader(Rect.fromCircle(center: pivot, radius: 4)),
    );
    canvas.drawCircle(
      bob.translate(0, -28),
      8 + pulse * 2.0,
      Paint()
        ..color = accentColor.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  void _drawPendulumColumn(Canvas canvas, {required Rect rect}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF805530),
            Color(0xFF5A3820),
            Color(0xFF885835),
            Color(0xFF684528),
          ],
          stops: <double>[0.0, 0.35, 0.7, 1.0],
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFFC89860).withValues(alpha: 0.42),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: rect.center,
          width: rect.width * 0.36,
          height: rect.height * 0.84,
        ),
        const Radius.circular(999),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
  }

  void _drawClockDial(
    Canvas canvas, {
    required Offset center,
    required double radius,
  }) {
    final outerRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius + 8,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[
            Color(0xFFFFEBB8),
            Color(0xFF9A6830),
            Color(0xFF724A20),
          ],
          stops: <double>[0.0, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius + 8)),
    );
    canvas.drawCircle(
      center,
      radius + 8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFFD8A060).withValues(alpha: 0.52),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.14, -0.24),
          colors: <Color>[
            Color(0xFFF8ECC8),
            Color(0xFFD8B88A),
            Color(0xFFBA9868),
            Color(0xFFA07848),
          ],
          stops: <double>[0.0, 0.45, 0.75, 1.0],
        ).createShader(outerRect),
    );
    canvas.drawCircle(
      center,
      radius * 0.85,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0xFF7A5030).withValues(alpha: 0.38),
    );
    canvas.drawCircle(
      center,
      radius * 0.22,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[Color(0xFF7A5030), Color(0xFF583818)],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 0.22)),
    );
    for (var i = 0; i < 12; i += 1) {
      final angle = -math.pi / 2 + i * math.pi / 6;
      final start = Offset(
        center.dx + math.cos(angle) * radius * 0.72,
        center.dy + math.sin(angle) * radius * 0.72,
      );
      final end = Offset(
        center.dx + math.cos(angle) * radius * 0.90,
        center.dy + math.sin(angle) * radius * 0.90,
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = const Color(0xFF5C4020).withValues(alpha: 0.82)
          ..strokeWidth = i % 3 == 0 ? 2.6 : 1.4,
      );
    }
    for (var i = 0; i < 60; i += 1) {
      if (i % 5 == 0) continue;
      final angle = -math.pi / 2 + i * math.pi / 30;
      final dot = Offset(
        center.dx + math.cos(angle) * radius * 0.82,
        center.dy + math.sin(angle) * radius * 0.82,
      );
      canvas.drawCircle(
        dot,
        0.8,
        Paint()..color = const Color(0xFF6E4A28).withValues(alpha: 0.52),
      );
    }
    canvas.drawLine(
      center,
      Offset(center.dx + radius * 0.16, center.dy - radius * 0.52),
      Paint()
        ..color = const Color(0xFF4C3018)
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      center,
      Offset(center.dx - radius * 0.38, center.dy + radius * 0.16),
      Paint()
        ..color = const Color(0xFF4C3018)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      center,
      radius * 0.08,
      Paint()..color = const Color(0xFFD8A860).withValues(alpha: 0.96),
    );
  }

  void _paintHypno(Canvas canvas, Size size, double pulse) {
    final center = size.center(Offset.zero);
    final baseRadius = size.shortestSide * 0.12;
    final phase = ambientProgress * math.pi * 2 * 1.35;
    final breatheCycle = math.sin(phase * 0.5).abs();
    final breathScale = 1.0 + breatheCycle * 0.08;

    for (var layer = 0; layer < 4; layer += 1) {
      final layerPhase = phase + layer * 0.72;
      final swirlRadius =
          baseRadius + size.shortestSide * (0.16 + layer * 0.12) * breathScale;
      final start = layerPhase;
      final sweep = math.pi * 1.4 + pulse * 0.2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: swirlRadius),
        start,
        sweep,
        false,
        Paint()
          ..shader = SweepGradient(
            startAngle: start,
            endAngle: start + sweep,
            colors: <Color>[
              _accentColor.withValues(alpha: 0.0),
              _accentColor.withValues(alpha: 0.32 - layer * 0.06),
              _accentColor.withValues(alpha: 0.18 - layer * 0.03),
              _accentColor.withValues(alpha: 0.0),
            ],
            stops: const <double>[0.0, 0.3, 0.7, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: swirlRadius))
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 5.5 - layer * 1.0,
      );
    }

    for (var i = 0; i < 9; i += 1) {
      final ringT = i / 8;
      final baseRingRadius = baseRadius + size.shortestSide * (0.08 * i);
      final waveOffset = math.sin(phase + i * 0.28) * 4;
      final radius = baseRingRadius + pulse * 14 * (1 - ringT) + waveOffset;
      final alpha = _mix(0.12, 0.68, 1 - ringT) * (0.68 + pulse * 0.32);
      final strokeWidth = _mix(1.0, 4.2, 1 - ringT);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            center: Alignment.center,
            radius: 0.6,
            colors: <Color>[
              _accentColor.withValues(alpha: alpha * 0.9),
              _accentColor.withValues(alpha: alpha * 0.5),
              _accentColor.withValues(alpha: alpha * 0.2),
            ],
            stops: const <double>[0.0, 0.5, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }

    for (var i = 0; i < 6; i += 1) {
      final angle = phase + i * math.pi / 3;
      final rayLength = baseRadius * 2.8 + pulse * 12;
      final start = Offset(
        center.dx + math.cos(angle) * (baseRadius * 1.1),
        center.dy + math.sin(angle) * (baseRadius * 1.1),
      );
      final end = Offset(
        center.dx + math.cos(angle) * rayLength,
        center.dy + math.sin(angle) * rayLength,
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              _accentColor.withValues(alpha: 0.32 + pulse * 0.18),
              _accentColor.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromPoints(start, end))
          ..strokeWidth = 1.8 + pulse * 0.8
          ..strokeCap = StrokeCap.round,
      );
    }

    final coreRadius = baseRadius * (1.1 + pulse * 0.6) * breathScale;
    canvas.drawCircle(
      center,
      coreRadius + 8,
      Paint()
        ..color = _accentColor.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.18, -0.24),
          radius: 0.85,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.96),
            _accentColor.withValues(alpha: 0.94),
            _accentColor.withValues(alpha: 0.78),
            const Color(0xFF5A3A72).withValues(alpha: 0.72),
          ],
          stops: const <double>[0.0, 0.28, 0.58, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: coreRadius)),
    );
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = Colors.white.withValues(alpha: 0.48),
    );
    canvas.drawCircle(
      center.translate(-coreRadius * 0.32, -coreRadius * 0.38),
      coreRadius * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.86),
    );
    canvas.drawCircle(
      center.translate(coreRadius * 0.12, -coreRadius * 0.18),
      coreRadius * 0.08,
      Paint()..color = Colors.white.withValues(alpha: 0.32),
    );

    canvas.drawCircle(
      center,
      coreRadius * 0.42,
      Paint()
        ..shader =
            const RadialGradient(
              colors: <Color>[Color(0xFF7A4A92), Color(0xFF4A2A5A)],
            ).createShader(
              Rect.fromCircle(center: center, radius: coreRadius * 0.42),
            ),
    );
  }

  void _paintDew(Canvas canvas, Size size, double pulse) {
    final centerX = size.width * 0.5;
    final fall = Curves.easeInCubic.transform(pulseProgress.clamp(0.0, 1.0));
    final dropY = _mix(size.height * 0.12, size.height * 0.64, fall);
    final rippleStart = size.height * 0.72;
    final impactProgress = ((fall - 0.82) / 0.18).clamp(0.0, 1.0);
    final preImpactSquash = fall < 0.82
        ? 0.0
        : math.sin(fall * math.pi * 4) * 0.04;
    final squash = impactProgress * 0.22 + preImpactSquash;
    final radius = 14 + pulse * 8;
    final dropRect = Rect.fromCenter(
      center: Offset(centerX, dropY),
      width: radius * 2.4 * (1 + squash * 0.28),
      height: radius * 2.4 * (1 - squash * 0.65),
    );

    for (var i = 0; i < 4; i += 1) {
      final trailY = dropY - (i + 1) * radius * 1.8;
      if (trailY < size.height * 0.08) continue;
      final trailAlpha = 0.16 - i * 0.04;
      final trailRadius = radius * (0.65 - i * 0.12);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            centerX + math.sin(ambientProgress * math.pi * 8 + i) * 3,
            trailY,
          ),
          width: trailRadius * 1.8,
          height: trailRadius * 2.2,
        ),
        Paint()
          ..color = _accentColor.withValues(alpha: trailAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, rippleStart + 6),
        width: 62 + impactProgress * 58,
        height: 18 + impactProgress * 8,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.14 + impactProgress * 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    final waterSurfaceRect = Rect.fromLTWH(
      size.width * 0.15,
      rippleStart - 4,
      size.width * 0.70,
      size.height * 0.12,
    );
    canvas.drawRect(
      waterSurfaceRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFF1A4558).withValues(alpha: 0.18),
            const Color(0xFF0F2838).withValues(alpha: 0.42),
            const Color(0xFF081820).withValues(alpha: 0.68),
          ],
        ).createShader(waterSurfaceRect),
    );

    canvas.drawOval(
      dropRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.38, -0.48),
          radius: 1.1,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.96),
            Colors.white.withValues(alpha: 0.78),
            _accentColor.withValues(alpha: 0.52),
            _accentColor.withValues(alpha: 0.28),
            const Color(0xFF1A5568).withValues(alpha: 0.18),
          ],
          stops: const <double>[0.0, 0.18, 0.42, 0.72, 1.0],
        ).createShader(dropRect),
    );
    canvas.drawOval(
      dropRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: 0.52),
    );

    canvas.drawCircle(
      Offset(centerX - radius * 0.48, dropY - radius * 0.58),
      radius * 0.28,
      Paint()..color = Colors.white.withValues(alpha: 0.88),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + radius * 0.22, dropY + radius * 0.18),
        width: radius * 1.2,
        height: radius * 0.58,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - radius * 0.12, dropY - radius * 0.28),
        width: radius * 0.55,
        height: radius * 0.28,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );

    final glowRadius = radius * 2.2 + pulse * 8;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, dropY),
        width: glowRadius,
        height: glowRadius * 0.8,
      ),
      Paint()
        ..color = _accentColor.withValues(alpha: 0.12 + pulse * 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    for (var i = 0; i < 5; i += 1) {
      final wave = (impactProgress - i * 0.16).clamp(0.0, 1.0);
      if (wave <= 0) continue;
      final rippleRadius = 22 + wave * 88;
      final alpha = (1 - wave * 0.48).clamp(0.0, 1.0) * 0.44;
      final rippleWidth = 2.4 - i * 0.35;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, rippleStart),
          width: rippleRadius * 2,
          height: rippleRadius * 0.48,
        ),
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: <Color>[
                  _accentColor.withValues(alpha: 0.0),
                  _accentColor.withValues(alpha: alpha),
                  _accentColor.withValues(alpha: alpha * 0.8),
                  _accentColor.withValues(alpha: 0.0),
                ],
                stops: const <double>[0.0, 0.25, 0.75, 1.0],
              ).createShader(
                Rect.fromCenter(
                  center: Offset(centerX, rippleStart),
                  width: rippleRadius * 2,
                  height: rippleRadius * 0.48,
                ),
              )
          ..style = PaintingStyle.stroke
          ..strokeWidth = rippleWidth,
      );
    }

    if (impactProgress > 0) {
      final splashT = Curves.easeOut.transform(impactProgress);
      for (var i = 0; i < 8; i += 1) {
        final theta = (-0.75 + i * 0.22) * math.pi;
        final baseLength = _mix(4, 24, splashT);
        final length = baseLength * (1 - (i % 4) * 0.15);
        final start = Offset(centerX, rippleStart - 4);
        final end = Offset(
          start.dx + math.cos(theta) * length,
          start.dy + math.sin(theta) * length * 0.6 - splashT * 12,
        );

        canvas.drawLine(
          start,
          end,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: <Color>[
                _accentColor.withValues(alpha: (1 - splashT) * 0.48),
                Colors.white.withValues(alpha: (1 - splashT) * 0.32),
              ],
            ).createShader(Rect.fromPoints(start, end))
            ..strokeWidth = 1.8 - splashT * 0.6
            ..strokeCap = StrokeCap.round,
        );

        if (splashT > 0.3) {
          canvas.drawCircle(
            end,
            2.4 - splashT * 1.2,
            Paint()
              ..color = Colors.white.withValues(alpha: (1 - splashT) * 0.42),
          );
        }
      }

      for (var ring = 0; ring < 2; ring += 1) {
        final ringT = (splashT - ring * 0.28).clamp(0.0, 1.0);
        if (ringT <= 0) continue;
        final secondaryRadius = 45 + ringT * 65 + ring * 28;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(centerX, rippleStart + ring * 6),
            width: secondaryRadius * 2,
            height: secondaryRadius * 0.38,
          ),
          Paint()
            ..color = _accentColor.withValues(alpha: (1 - ringT) * 0.22)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
    }
  }

  void _paintGear(Canvas canvas, Size size, double pulse) {
    final phase = pulseProgress.clamp(0.0, 1.0);
    final swingDirection = activeBeat >= 0
        ? (activeBeat.isOdd ? -1.0 : 1.0)
        : 1.0;
    final tickImpulse =
        Curves.easeOutCubic.transform((1 - phase).clamp(0.0, 1.0)) * 0.12;
    final mainRotation =
        ambientProgress * math.pi * 2 * (running ? 0.48 : 0.12) +
        tickImpulse * swingDirection;
    final caseCenter = Offset(size.width * 0.5, size.height * 0.48);
    final caseRadius = size.shortestSide * 0.36;
    final caseRect = Rect.fromCircle(center: caseCenter, radius: caseRadius);

    canvas.drawCircle(
      caseCenter,
      caseRadius + 22,
      Paint()
        ..shader =
            const RadialGradient(
              colors: <Color>[
                Color(0xFF8A4A28),
                Color(0xFF4A2818),
                Color(0xFF2A1408),
              ],
              stops: <double>[0.0, 0.6, 1.0],
            ).createShader(
              Rect.fromCircle(center: caseCenter, radius: caseRadius + 22),
            ),
    );
    canvas.drawCircle(
      caseCenter,
      caseRadius + 12,
      Paint()
        ..shader =
            const RadialGradient(
              center: Alignment(-0.16, -0.32),
              colors: <Color>[
                Color(0xFFFAD88E),
                Color(0xFFD8A048),
                Color(0xFFB07832),
                Color(0xFF683818),
              ],
              stops: <double>[0.0, 0.32, 0.62, 1.0],
            ).createShader(
              Rect.fromCircle(center: caseCenter, radius: caseRadius + 12),
            ),
    );
    canvas.drawCircle(
      caseCenter,
      caseRadius + 12,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color(0xFFC89858).withValues(alpha: 0.48),
    );
    canvas.drawCircle(
      caseCenter,
      caseRadius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment.center,
          colors: <Color>[
            Color(0xFF2A1E14),
            Color(0xFF1A120A),
            Color(0xFF0A0604),
          ],
        ).createShader(caseRect),
    );

    _drawFocusGear(
      canvas,
      center: caseCenter.translate(-caseRadius * 0.28, caseRadius * 0.16),
      radius: caseRadius * 0.46 + pulse * 6,
      teeth: 24,
      rotation: mainRotation,
      color: const Color(0xFFDAB35C),
      pulse: pulse,
    );
    _drawFocusGear(
      canvas,
      center: caseCenter.translate(caseRadius * 0.28, -caseRadius * 0.22),
      radius: caseRadius * 0.20 + pulse * 3,
      teeth: 14,
      rotation: -mainRotation * 2.1,
      color: const Color(0xFFD0D7E0),
      pulse: pulse * 0.85,
    );
    _drawFocusGear(
      canvas,
      center: caseCenter.translate(-caseRadius * 0.38, -caseRadius * 0.32),
      radius: caseRadius * 0.18,
      teeth: 14,
      rotation: -mainRotation * 1.48,
      color: const Color(0xFFAEB9C7),
      pulse: pulse * 0.65,
    );
    _drawFocusGear(
      canvas,
      center: caseCenter.translate(caseRadius * 0.36, caseRadius * 0.32),
      radius: caseRadius * 0.14,
      teeth: 12,
      rotation: mainRotation * 2.6,
      color: const Color(0xFFB3BAC4),
      pulse: pulse * 0.55,
    );
    _drawFocusGear(
      canvas,
      center: caseCenter.translate(-caseRadius * 0.12, caseRadius * 0.38),
      radius: caseRadius * 0.10,
      teeth: 10,
      rotation: mainRotation * 3.2,
      color: const Color(0xFFC8D0D8),
      pulse: pulse * 0.45,
    );

    final balanceAngle = swingDirection * math.cos(math.pi * phase) * 0.58;
    _drawBalanceWheel(
      canvas,
      center: caseCenter,
      radius: caseRadius * 0.32,
      rotation: balanceAngle,
      pulse: pulse,
    );

    final bridgeColor = const Color(0xFFD8DEE8).withValues(alpha: 0.98);
    final bridgePaint = Paint()
      ..color = bridgeColor
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: caseCenter, radius: caseRadius * 0.38),
      math.pi * 1.05,
      math.pi * 0.92,
      false,
      bridgePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: caseCenter, radius: caseRadius * 0.38),
      math.pi * 1.05,
      math.pi * 0.92,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = Colors.white.withValues(alpha: 0.32),
    );
    canvas.drawLine(
      caseCenter.translate(-caseRadius * 0.04, 0),
      caseCenter.translate(caseRadius * 0.42, -caseRadius * 0.06),
      Paint()
        ..color = bridgeColor
        ..strokeWidth = 8.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      caseCenter.translate(-caseRadius * 0.22, -caseRadius * 0.26),
      caseCenter.translate(caseRadius * 0.12, -caseRadius * 0.08),
      Paint()
        ..color = bridgeColor.withValues(alpha: 0.88)
        ..strokeWidth = 7.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      caseCenter.translate(-caseRadius * 0.08, caseRadius * 0.28),
      caseCenter.translate(caseRadius * 0.32, caseRadius * 0.12),
      Paint()
        ..color = bridgeColor.withValues(alpha: 0.82)
        ..strokeWidth = 5.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      caseCenter,
      10,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[
            Color(0xFFFCE8AA),
            Color(0xFFD8A848),
            Color(0xFF9A6D25),
          ],
        ).createShader(Rect.fromCircle(center: caseCenter, radius: 10)),
    );
    canvas.drawCircle(
      caseCenter,
      10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFE8C878).withValues(alpha: 0.62),
    );

    for (final screw in <Offset>[
      caseCenter.translate(-caseRadius * 0.58, -caseRadius * 0.56),
      caseCenter.translate(caseRadius * 0.62, -caseRadius * 0.52),
      caseCenter.translate(-caseRadius * 0.52, caseRadius * 0.62),
      caseCenter.translate(caseRadius * 0.48, caseRadius * 0.58),
    ]) {
      _drawMovementScrew(canvas, center: screw, radius: 13);
    }
    for (final jewel in <Offset>[
      caseCenter.translate(-caseRadius * 0.26, -caseRadius * 0.12),
      caseCenter.translate(caseRadius * 0.12, -caseRadius * 0.02),
      caseCenter.translate(caseRadius * 0.22, -caseRadius * 0.16),
      caseCenter.translate(-caseRadius * 0.32, caseRadius * 0.08),
    ]) {
      canvas.drawCircle(
        jewel,
        5.2,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.24, -0.28),
            colors: <Color>[
              Color(0xFFE8A8FF),
              Color(0xFF8E4DA8),
              Color(0xFF5A2A6A),
            ],
          ).createShader(Rect.fromCircle(center: jewel, radius: 5.2)),
      );
      canvas.drawCircle(
        jewel,
        1.8,
        Paint()..color = Colors.white.withValues(alpha: 0.72),
      );
    }

    for (var i = 0; i < 8; i += 1) {
      final angle = i * math.pi / 4 + mainRotation * 0.08;
      final decorationRadius = caseRadius * 0.72;
      final decorationPos = Offset(
        caseCenter.dx + math.cos(angle) * decorationRadius,
        caseCenter.dy + math.sin(angle) * decorationRadius,
      );
      canvas.drawCircle(
        decorationPos,
        2.8,
        Paint()
          ..shader = const RadialGradient(
            colors: <Color>[Color(0xFFD8A858), Color(0xFF7A4828)],
          ).createShader(Rect.fromCircle(center: decorationPos, radius: 2.8)),
      );
    }

    canvas.drawCircle(
      caseCenter,
      caseRadius + 5 + pulse * 4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.22 + pulse * 0.08),
    );

    canvas.drawArc(
      Rect.fromCircle(center: caseCenter, radius: caseRadius + 8),
      -math.pi * 0.4 + ambientProgress * math.pi * 0.8,
      math.pi * 0.6,
      false,
      Paint()
        ..shader =
            SweepGradient(
              colors: <Color>[
                Colors.white.withValues(alpha: 0.0),
                Colors.white.withValues(alpha: 0.24),
                Colors.white.withValues(alpha: 0.0),
              ],
            ).createShader(
              Rect.fromCircle(center: caseCenter, radius: caseRadius + 8),
            )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintSteps(Canvas canvas, Size size, double pulse) {
    final phase = pulseProgress.clamp(0.0, 1.0);
    final leftActive = activeBeat >= 0 ? activeBeat.isEven : true;
    final vanishing = Offset(size.width * 0.5, size.height * 0.14);

    final skyRect = Rect.fromLTWH(0, 0, size.width, vanishing.dy + 18);
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFF1A2822).withValues(alpha: 0.28),
            const Color(0xFF1E3A28).withValues(alpha: 0.48),
            const Color(0xFF182818).withValues(alpha: 0.72),
          ],
        ).createShader(skyRect),
    );

    final lanePath = Path()
      ..moveTo(size.width * 0.14, size.height * 0.94)
      ..lineTo(size.width * 0.86, size.height * 0.94)
      ..lineTo(size.width * 0.62, vanishing.dy)
      ..lineTo(size.width * 0.38, vanishing.dy)
      ..close();
    canvas.drawPath(
      lanePath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFF1A2822).withValues(alpha: 0.22),
            const Color(0xFF243A32).withValues(alpha: 0.58),
            const Color(0xFF183028).withValues(alpha: 0.85),
            const Color(0xFF0E1812).withValues(alpha: 0.92),
          ],
          stops: const <double>[0.0, 0.35, 0.7, 1.0],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      lanePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = Colors.white.withValues(alpha: 0.16),
    );

    final laneDividerPath = Path()
      ..moveTo(size.width * 0.5, vanishing.dy)
      ..lineTo(size.width * 0.5, size.height * 0.94);
    canvas.drawPath(
      laneDividerPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.28),
          ],
        ).createShader(laneDividerPath.getBounds())
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < 8; i += 1) {
      final t = i / 7;
      final y = _mix(vanishing.dy + 22, size.height * 0.96, t);
      final halfWidth = _mix(8, size.width * 0.32, t);
      final alpha = 0.04 + t * 0.12;
      canvas.drawLine(
        Offset(size.width * 0.5 - halfWidth, y),
        Offset(size.width * 0.5 + halfWidth, y),
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: <Color>[
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: alpha),
                  Colors.white.withValues(alpha: alpha),
                  Colors.white.withValues(alpha: 0.0),
                ],
                stops: const <double>[0.0, 0.28, 0.72, 1.0],
              ).createShader(
                Rect.fromLTWH(
                  size.width * 0.5 - halfWidth,
                  y - 0.5,
                  halfWidth * 2,
                  1,
                ),
              )
          ..strokeWidth = _mix(0.8, 2.2, t),
      );
    }

    for (var i = 0; i < 10; i += 1) {
      final t = ((ambientProgress * 1.25) + i * 0.12) % 1.0;
      final depth = Curves.easeIn.transform(t);
      final y = _mix(vanishing.dy + 12, size.height * 0.96, depth);
      final width = _mix(3, 18, depth);
      final height = _mix(8, 38, depth);
      final alpha = 0.04 + depth * 0.18;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * 0.5, y),
            width: width,
            height: height,
          ),
          const Radius.circular(999),
        ),
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.white.withValues(alpha: alpha),
                  Colors.white.withValues(alpha: alpha * 0.5),
                ],
              ).createShader(
                Rect.fromCenter(
                  center: Offset(size.width * 0.5, y),
                  width: width,
                  height: height,
                ),
              ),
      );
    }

    final flow = (ambientProgress * 1.8 + phase * 0.14) % 1.0;
    for (var i = 0; i < 8; i += 1) {
      final t = ((flow + i * 0.14) % 1.0);
      final depth = Curves.easeIn.transform(t);
      final scale = _mix(0.22, 1.18, depth);
      final y = _mix(vanishing.dy + 28, size.height * 0.92, depth);
      final x = size.width * 0.5 + (i.isEven ? -1 : 1) * _mix(6, 48, depth);
      final opacity = _mix(0.06, 0.42, depth);
      _drawFootprint(
        canvas,
        center: Offset(x, y),
        active: false,
        pulse: pulse,
        color: Colors.white.withValues(alpha: opacity),
        scale: scale,
        rotation: (i.isEven ? -1.0 : 1.0) * _mix(0.02, 0.22, depth),
      );
    }

    final strideLift = math.sin(math.pi * phase).abs();
    final impactSquash = strideLift * 0.12;
    final leadY = _mix(size.height * 0.88, size.height * 0.62, phase);
    final trailY = _mix(size.height * 0.68, size.height * 0.88, phase);

    if (leftActive) {
      _drawFootprint(
        canvas,
        center: Offset(size.width * 0.5 - 32, leadY),
        active: true,
        pulse: pulse + strideLift * 0.42,
        color: _accentColor,
        scale: 1.22 - impactSquash * 0.5,
        rotation: -0.16,
        squash: impactSquash,
      );
      _drawFootprint(
        canvas,
        center: Offset(size.width * 0.5 + 32, trailY),
        active: false,
        pulse: pulse + strideLift * 0.28,
        color: Colors.white.withValues(alpha: 0.88),
        scale: 0.98,
        rotation: 0.08,
      );
    } else {
      _drawFootprint(
        canvas,
        center: Offset(size.width * 0.5 + 32, leadY),
        active: true,
        pulse: pulse + strideLift * 0.42,
        color: _accentColor,
        scale: 1.22 - impactSquash * 0.5,
        rotation: 0.16,
        squash: impactSquash,
      );
      _drawFootprint(
        canvas,
        center: Offset(size.width * 0.5 - 32, trailY),
        active: false,
        pulse: pulse + strideLift * 0.28,
        color: Colors.white.withValues(alpha: 0.88),
        scale: 0.98,
        rotation: -0.08,
      );
    }

    final groundGlowAlpha = 0.18 + strideLift * 0.16;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          size.width * 0.5 + (leftActive ? -32 : 32),
          size.height * 0.90,
        ),
        width: 56 + pulse * 18,
        height: 14 + pulse * 4,
      ),
      Paint()
        ..color = _accentColor.withValues(alpha: groundGlowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  void _drawFootprint(
    Canvas canvas, {
    required Offset center,
    required bool active,
    required double pulse,
    required Color color,
    double scale = 1.0,
    double rotation = 0.0,
    double squash = 0.0,
  }) {
    final actualScale = active ? scale * (1.0 + pulse * 0.08) : scale;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final sole = Rect.fromCenter(
      center: Offset.zero,
      width: 36 * actualScale * (1 + squash * 0.35),
      height: 74 * actualScale * (1 - squash * 0.55),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, 18 * actualScale),
        width: sole.width * 0.78,
        height: sole.height * 0.28,
      ),
      Paint()
        ..shader =
            RadialGradient(
              colors: <Color>[
                Colors.black.withValues(alpha: active ? 0.28 : 0.14),
                Colors.black.withValues(alpha: 0.0),
              ],
            ).createShader(
              Rect.fromCenter(
                center: Offset(0, 18 * actualScale),
                width: sole.width * 0.78,
                height: sole.height * 0.28,
              ),
            ),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sole, Radius.circular(20 * actualScale)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            color.withValues(alpha: active ? 0.98 : 0.62),
            color.withValues(alpha: active ? 0.82 : 0.38),
            color.withValues(alpha: active ? 0.65 : 0.25),
          ],
          stops: const <double>[0.0, 0.55, 1.0],
        ).createShader(sole),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sole, Radius.circular(20 * actualScale)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: active ? 0.32 : 0.12),
    );
    for (final toe in <Offset>[
      Offset(-9 * actualScale, -28 * actualScale),
      Offset(0, -33 * actualScale),
      Offset(9 * actualScale, -27 * actualScale),
    ]) {
      canvas.drawCircle(
        toe,
        5.6 * actualScale,
        Paint()
          ..shader =
              RadialGradient(
                center: const Alignment(-0.18, -0.28),
                colors: <Color>[
                  color.withValues(alpha: active ? 0.96 : 0.42),
                  color.withValues(alpha: active ? 0.78 : 0.28),
                ],
              ).createShader(
                Rect.fromCircle(center: toe, radius: 5.6 * actualScale),
              ),
      );
    }
    if (active) {
      canvas.drawCircle(
        Offset(-9 * actualScale, -28 * actualScale),
        5.6 * actualScale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.42),
      );
      canvas.drawCircle(
        Offset(-4 * actualScale, -32 * actualScale),
        1.8 * actualScale,
        Paint()..color = Colors.white.withValues(alpha: 0.62),
      );
    }
    canvas.restore();
  }

  void _paintBeatIndicators(Canvas canvas, Size size, double pulse) {
    final spacing = 12.0;
    final count = subdivision.clamp(1, 6);
    final totalWidth = (count - 1) * spacing;
    final startX = size.width * 0.5 - totalWidth * 0.5;
    final y = size.height - 22;
    final padRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, y),
        width: totalWidth + 28,
        height: 18,
      ),
      const Radius.circular(999),
    );
    canvas.drawRRect(
      padRect,
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );
    for (var i = 0; i < count; i += 1) {
      final active =
          activeSubPulse > 0 && i == (activeSubPulse - 1).clamp(0, count - 1);
      canvas.drawCircle(
        Offset(startX + i * spacing, y),
        active ? 4.2 + pulse * 1.3 : 3,
        Paint()
          ..color = (active ? _accentColor : Colors.white).withValues(
            alpha: active ? 0.94 : 0.34,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LegacyFocusBeatVisualizerPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.ambientProgress != ambientProgress ||
        oldDelegate.accentLayer != accentLayer ||
        oldDelegate.running != running ||
        oldDelegate.activeBeat != activeBeat ||
        oldDelegate.activeSubPulse != activeSubPulse ||
        oldDelegate.subdivision != subdivision;
  }
}

void _drawFocusGear(
  Canvas canvas, {
  required Offset center,
  required double radius,
  required int teeth,
  required double rotation,
  required Color color,
  required double pulse,
}) {
  final innerRadius = radius * 0.76;
  final outerRadius = radius * 1.08;
  final gearPath = Path();
  for (var i = 0; i < teeth * 2; i += 1) {
    final isTooth = i.isEven;
    final angle = rotation + i * math.pi / teeth;
    final r = isTooth ? outerRadius : innerRadius;
    final point = Offset(
      center.dx + math.cos(angle) * r,
      center.dy + math.sin(angle) * r,
    );
    if (i == 0) {
      gearPath.moveTo(point.dx, point.dy);
    } else {
      gearPath.lineTo(point.dx, point.dy);
    }
  }
  gearPath.close();

  canvas.drawPath(
    gearPath,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.22, -0.38),
        radius: 1.1,
        colors: <Color>[
          Colors.white.withValues(alpha: 1.0),
          color.withValues(alpha: 0.92),
          const Color(0xFF8A9AAB).withValues(alpha: 0.88),
          const Color(0xFF3A4350).withValues(alpha: 0.94),
        ],
        stops: const <double>[0.0, 0.28, 0.58, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius)),
  );
  canvas.drawPath(
    gearPath,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white.withValues(alpha: 0.32),
  );

  final hubRadius = radius * 0.58;
  canvas.drawCircle(
    center,
    hubRadius,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.18, -0.28),
        colors: <Color>[
          const Color(0xFFF8FAFC).withValues(alpha: 0.96),
          const Color(0xFFB8C4D0).withValues(alpha: 0.92),
          const Color(0xFF6B7788).withValues(alpha: 0.88),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: hubRadius)),
  );
  canvas.drawCircle(
    center,
    hubRadius,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.28),
  );
  canvas.drawCircle(
    center,
    radius * 0.22,
    Paint()
      ..shader = const RadialGradient(
        colors: <Color>[Color(0xFF2A3038), Color(0xFF181E24)],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.22)),
  );

  for (var i = 0; i < 6; i += 1) {
    final angle = rotation + i * math.pi / 3;
    final start = Offset(
      center.dx + math.cos(angle) * radius * 0.22,
      center.dy + math.sin(angle) * radius * 0.22,
    );
    final end = Offset(
      center.dx + math.cos(angle) * radius * 0.52,
      center.dy + math.sin(angle) * radius * 0.52,
    );
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );
  }

  canvas.drawArc(
    Rect.fromCircle(center: center, radius: outerRadius + 4),
    rotation - 0.5,
    0.58 + pulse * 0.22,
    false,
    Paint()
      ..shader = SweepGradient(
        startAngle: rotation - 0.5,
        endAngle: rotation + 0.08 + pulse * 0.22,
        colors: <Color>[
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.38),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius + 4))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4,
  );

  canvas.drawCircle(
    center,
    radius * 0.08,
    Paint()
      ..shader = const RadialGradient(
        colors: <Color>[Color(0xFFD8A850), Color(0xFF8A5828)],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.08)),
  );
}

void _drawBalanceWheel(
  Canvas canvas, {
  required Offset center,
  required double radius,
  required double rotation,
  required double pulse,
}) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(rotation);
  final ringRect = Rect.fromCircle(center: Offset.zero, radius: radius);
  canvas.drawCircle(
    Offset.zero,
    radius,
    Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.18, -0.28),
        colors: <Color>[
          Color(0xFFF8FCFF),
          Color(0xFFD0D8E4),
          Color(0xFF9EA8B6),
          Color(0xFF4C5564),
        ],
        stops: <double>[0.0, 0.32, 0.62, 1.0],
      ).createShader(ringRect),
  );
  canvas.drawCircle(
    Offset.zero,
    radius,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Colors.white.withValues(alpha: 0.38),
  );
  canvas.drawCircle(
    Offset.zero,
    radius * 0.72,
    Paint()
      ..shader =
          const RadialGradient(
            colors: <Color>[Color(0xFF1A2028), Color(0xFF0E1418)],
          ).createShader(
            Rect.fromCircle(center: Offset.zero, radius: radius * 0.72),
          ),
  );
  for (var i = 0; i < 6; i += 1) {
    final angle = i * math.pi / 3;
    final end = Offset(
      math.cos(angle) * radius * 0.78,
      math.sin(angle) * radius * 0.78,
    );
    canvas.drawLine(
      Offset.zero,
      end,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.42)
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );
  }
  for (var i = 0; i < 12; i += 1) {
    final angle = i * math.pi / 6;
    final tickEnd = Offset(
      math.cos(angle) * radius * 0.68,
      math.sin(angle) * radius * 0.68,
    );
    canvas.drawCircle(
      tickEnd,
      1.8,
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );
  }
  canvas.drawCircle(
    Offset.zero,
    radius * 0.18,
    Paint()
      ..shader =
          const RadialGradient(
            center: Alignment(-0.24, -0.32),
            colors: <Color>[
              Color(0xFFFEE8B4),
              Color(0xFFD8A848),
              Color(0xFF9B6C24),
            ],
          ).createShader(
            Rect.fromCircle(center: Offset.zero, radius: radius * 0.18),
          ),
  );
  canvas.drawCircle(
    Offset.zero,
    radius * 0.18,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFE8C078).withValues(alpha: 0.48),
  );
  canvas.restore();

  canvas.drawArc(
    Rect.fromCircle(
      center: center.translate(0, -radius * 0.12),
      radius: radius * 1.18,
    ),
    math.pi * 1.02,
    math.pi * 0.96,
    false,
    Paint()
      ..shader =
          SweepGradient(
            startAngle: math.pi * 1.02,
            endAngle: math.pi * 1.98,
            colors: <Color>[
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.82),
              Colors.white.withValues(alpha: 0.62),
              Colors.white.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: center.translate(0, -radius * 0.12),
              radius: radius * 1.18,
            ),
          )
      ..strokeWidth = 6.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke,
  );
  canvas.drawCircle(
    center,
    radius + 8 + pulse * 4,
    Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              const Color(0xFF96D9FF).withValues(alpha: 0.14),
              const Color(0xFF96D9FF).withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: radius + 8 + pulse * 4),
          )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
  );
}

void _drawMovementScrew(
  Canvas canvas, {
  required Offset center,
  required double radius,
}) {
  final rect = Rect.fromCircle(center: center, radius: radius);
  canvas.drawCircle(
    center,
    radius + 1,
    Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.28, -0.32),
        colors: <Color>[
          Color(0xFFF4F8FC),
          Color(0xFFD0D4DA),
          Color(0xFF8A9AA8),
          Color(0xFF3A4A58),
        ],
        stops: <double>[0.0, 0.32, 0.62, 1.0],
      ).createShader(rect),
  );
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.28),
  );
  canvas.drawLine(
    center.translate(-radius * 0.48, 0),
    center.translate(radius * 0.48, 0),
    Paint()
      ..color = const Color(0xFF1A2432).withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round,
  );
  canvas.drawLine(
    center.translate(0, -radius * 0.48),
    center.translate(0, radius * 0.48),
    Paint()
      ..color = const Color(0xFF1A2432).withValues(alpha: 0.32)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round,
  );
  canvas.drawCircle(
    center.translate(-radius * 0.18, -radius * 0.18),
    radius * 0.15,
    Paint()..color = Colors.white.withValues(alpha: 0.42),
  );
}

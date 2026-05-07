part of 'toolbox_mini_games.dart';

class _RouletteBackdropPainter extends CustomPainter {
  const _RouletteBackdropPainter({
    required this.accent,
    required this.ambient,
    required this.hitFlash,
    required this.phase,
  });

  final Color accent;
  final double ambient;
  final double hitFlash;
  final _RoulettePhase phase;

  @override
  void paint(Canvas canvas, Size size) {
    final ambientWave = 0.5 + 0.5 * math.sin(ambient * math.pi * 2);
    final glowCenter = Offset(
      size.width * (0.24 + math.sin(ambient * math.pi * 2) * 0.03),
      size.height * 0.08,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          glowCenter,
          size.width * 0.92,
          <Color>[
            const Color(
              0xFFD5C3AA,
            ).withValues(alpha: 0.42 + ambientWave * 0.06),
            const Color(0xFF6A5D53).withValues(alpha: 0.88),
            const Color(0xFF34383F),
          ],
          const <double>[0, 0.55, 1],
        ),
    );

    final grainPaint = Paint()
      ..color = const Color(0xFFFFF4E0).withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.0018;
    for (var index = 0; index < 8; index += 1) {
      final y = size.height * (0.12 + index * 0.075);
      canvas.drawLine(
        Offset(size.width * 0.04, y),
        Offset(size.width * 0.96, y + size.height * 0.018),
        grainPaint,
      );
    }

    final floorRect = Rect.fromLTWH(
      0,
      size.height * 0.64,
      size.width,
      size.height * 0.36,
    );
    canvas.drawRect(
      floorRect,
      Paint()
        ..shader =
            ui.Gradient.linear(floorRect.topLeft, floorRect.bottomLeft, <Color>[
              const Color(0xFF7C6B5C).withValues(alpha: 0.38),
              const Color(0xFF353236).withValues(alpha: 0.72),
            ]),
    );

    final smokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    for (var index = 0; index < 4; index += 1) {
      final drift = (ambient + index * 0.21) % 1;
      final y = size.height * (0.2 + index * 0.1);
      final amp = size.height * (0.02 + index * 0.006);
      final alpha = 0.08 + ambientWave * 0.05;
      smokePaint
        ..color = const Color(0xFFFFE1BC).withValues(alpha: alpha * 0.78)
        ..strokeWidth = size.width * (0.004 + index * 0.0006);
      final path = Path()
        ..moveTo(size.width * 0.02, y)
        ..cubicTo(
          size.width * (0.2 + drift * 0.08),
          y - amp,
          size.width * (0.55 + drift * 0.12),
          y + amp,
          size.width * 0.98,
          y - amp * 0.4,
        );
      canvas.drawPath(path, smokePaint);
    }

    final flashT = hitFlash.clamp(0.0, 1.0);
    if (phase == _RoulettePhase.hit && flashT < 0.88) {
      final burst = 1 - Curves.easeOutCubic.transform(flashT);
      final blastCenter = Offset(size.width * 0.78, size.height * 0.34);
      canvas.drawCircle(
        blastCenter,
        size.width * (0.16 + flashT * 0.22),
        Paint()
          ..shader = ui.Gradient.radial(
            blastCenter,
            size.width * (0.19 + flashT * 0.26),
            <Color>[
              const Color(0xFFFFD06A).withValues(alpha: burst * 0.36),
              const Color(0xFFC74C3F).withValues(alpha: burst * 0.18),
              Colors.transparent,
            ],
            const <double>[0, 0.4, 1],
          ),
      );
      final sparkPaint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = size.width * 0.004
        ..color = const Color(0xFFFFD68A).withValues(alpha: burst * 0.8);
      for (var index = 0; index < 12; index += 1) {
        final angle = index / 12 * math.pi * 2 + flashT * 0.3;
        final start =
            blastCenter +
            Offset(math.cos(angle), math.sin(angle)) * size.width * 0.05;
        final end =
            start +
            Offset(math.cos(angle), math.sin(angle)) *
                size.width *
                (0.03 + burst * 0.07);
        canvas.drawLine(start, end, sparkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RouletteBackdropPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.ambient != ambient ||
        oldDelegate.hitFlash != hitFlash ||
        oldDelegate.phase != phase;
  }
}

class _RouletteRevolverPainter extends CustomPainter {
  const _RouletteRevolverPainter({
    required this.phase,
    required this.sequence,
    required this.bulletCount,
    required this.activeChamber,
    required this.pullCount,
    required this.cylinderAngle,
    required this.fireProgress,
    required this.safeKickProgress,
    required this.recoilProgress,
    required this.ambient,
  });

  final _RoulettePhase phase;
  final List<bool> sequence;
  final int bulletCount;
  final int activeChamber;
  final int pullCount;
  final double cylinderAngle;
  final double fireProgress;
  final double safeKickProgress;
  final double recoilProgress;
  final double ambient;

  @override
  void paint(Canvas canvas, Size size) {
    final safeKick = math
        .sin(safeKickProgress * math.pi)
        .clamp(0.0, 1.0)
        .toDouble();
    final recoilKick = math
        .sin(recoilProgress * math.pi)
        .clamp(0.0, 1.0)
        .toDouble();
    final rattle =
        math.sin(safeKickProgress * math.pi * 6) * (1 - safeKickProgress);
    final recoilX =
        recoilKick * size.width * 0.055 + safeKick * size.width * 0.012;
    final muzzleLift = -(recoilKick * 0.048 + safeKick * 0.01);
    final pulse = 0.5 + 0.5 * math.sin(ambient * math.pi * 2);
    final fireClamped = fireProgress.clamp(0.0, 1.0);
    final triggerPull = math.sin(fireClamped * math.pi).clamp(0.0, 1.0);
    final hammerPhase = fireClamped <= 0.36
        ? Curves.easeOutCubic.transform(fireClamped / 0.36)
        : 1 - Curves.easeInQuad.transform((fireClamped - 0.36) / 0.64);

    canvas.save();
    canvas.translate(-recoilX + rattle * size.width * 0.004, 0);
    canvas.translate(size.width * 0.47, size.height * 0.48);
    canvas.rotate(muzzleLift);
    canvas.translate(-size.width * 0.47, -size.height * 0.48);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.49, size.height * 0.81),
        width: size.width * 0.76,
        height: size.height * 0.18,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.36)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    final steelShader = ui.Gradient.linear(
      Offset(size.width * 0.25, size.height * 0.24),
      Offset(size.width * 0.86, size.height * 0.58),
      const <Color>[
        Color(0xFFD5D9DC),
        Color(0xFF89929B),
        Color(0xFF3D4650),
        Color(0xFF171C24),
      ],
      const <double>[0, 0.32, 0.72, 1],
    );
    final steelPaint = Paint()..shader = steelShader;
    final darkStroke = Paint()
      ..color = const Color(0xFF111419)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.008;

    final barrelTop = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.49,
        size.height * 0.265,
        size.width * 0.41,
        size.height * 0.055,
      ),
      Radius.circular(size.height * 0.018),
    );
    canvas.drawRRect(
      barrelTop.shift(Offset(0, size.height * 0.012)),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    canvas.drawRRect(
      barrelTop,
      Paint()
        ..shader = ui.Gradient.linear(
          barrelTop.outerRect.topCenter,
          barrelTop.outerRect.bottomCenter,
          const <Color>[Color(0xFFE5E8EA), Color(0xFF56606B)],
        ),
    );
    canvas.drawRRect(barrelTop, darkStroke);

    final frontSight = Path()
      ..moveTo(size.width * 0.845, size.height * 0.267)
      ..lineTo(size.width * 0.875, size.height * 0.216)
      ..lineTo(size.width * 0.894, size.height * 0.27)
      ..close();
    canvas.drawPath(
      frontSight.shift(Offset(0, size.height * 0.008)),
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );
    canvas.drawPath(frontSight, Paint()..color = const Color(0xFF242A32));

    final barrelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.5,
        size.height * 0.302,
        size.width * 0.39,
        size.height * 0.145,
      ),
      Radius.circular(size.height * 0.054),
    );
    canvas.drawRRect(
      barrelRect.shift(Offset(0, size.height * 0.016)),
      Paint()..color = Colors.black.withValues(alpha: 0.24),
    );
    canvas.drawRRect(barrelRect, steelPaint);
    canvas.drawRRect(barrelRect, darkStroke);
    canvas.drawLine(
      Offset(size.width * 0.53, size.height * 0.325),
      Offset(size.width * 0.84, size.height * 0.325),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..strokeWidth = size.width * 0.005
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(size.width * 0.54, size.height * 0.43),
      Offset(size.width * 0.81, size.height * 0.43),
      Paint()
        ..color = const Color(0xFF171C23).withValues(alpha: 0.42)
        ..strokeWidth = size.width * 0.006
        ..strokeCap = StrokeCap.round,
    );

    final underlug = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.56,
        size.height * 0.43,
        size.width * 0.27,
        size.height * 0.052,
      ),
      Radius.circular(size.height * 0.025),
    );
    canvas.drawRRect(
      underlug,
      Paint()
        ..shader = ui.Gradient.linear(
          underlug.outerRect.topLeft,
          underlug.outerRect.bottomRight,
          const <Color>[Color(0xFF6D7680), Color(0xFF20252D)],
        ),
    );
    canvas.drawRRect(underlug, darkStroke);
    canvas.drawLine(
      Offset(size.width * 0.57, size.height * 0.458),
      Offset(size.width * 0.82, size.height * 0.458),
      Paint()
        ..color = const Color(0xFFE9EDF0).withValues(alpha: 0.18)
        ..strokeWidth = size.width * 0.004
        ..strokeCap = StrokeCap.round,
    );

    final muzzle = Offset(size.width * 0.88, size.height * 0.37);
    canvas.drawOval(
      Rect.fromCenter(
        center: muzzle,
        width: size.width * 0.1,
        height: size.height * 0.12,
      ),
      Paint()
        ..shader = ui.Gradient.radial(
          muzzle.translate(-size.width * 0.012, -size.height * 0.012),
          size.width * 0.07,
          const <Color>[Color(0xFF707885), Color(0xFF13161D)],
        ),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: muzzle,
        width: size.width * 0.056,
        height: size.height * 0.064,
      ),
      Paint()..color = const Color(0xFF050608),
    );

    final frame = Path()
      ..moveTo(size.width * 0.21, size.height * 0.37)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.23,
        size.width * 0.53,
        size.height * 0.3,
      )
      ..lineTo(size.width * 0.59, size.height * 0.48)
      ..quadraticBezierTo(
        size.width * 0.43,
        size.height * 0.62,
        size.width * 0.22,
        size.height * 0.51,
      )
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.44,
        size.width * 0.21,
        size.height * 0.37,
      )
      ..close();
    canvas.drawPath(
      frame.shift(Offset(0, size.height * 0.014)),
      Paint()..color = Colors.black.withValues(alpha: 0.24),
    );
    canvas.drawPath(frame, steelPaint);
    canvas.drawPath(frame, darkStroke);
    final rearSight = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.255,
        size.height * 0.305,
        size.width * 0.07,
        size.height * 0.026,
      ),
      Radius.circular(size.height * 0.008),
    );
    canvas.drawRRect(rearSight, Paint()..color = const Color(0xFF10141A));
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.352),
      Offset(size.width * 0.52, size.height * 0.318),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..strokeWidth = size.width * 0.005
        ..strokeCap = StrokeCap.round,
    );
    final sidePlate = Path()
      ..moveTo(size.width * 0.31, size.height * 0.385)
      ..quadraticBezierTo(
        size.width * 0.39,
        size.height * 0.33,
        size.width * 0.51,
        size.height * 0.382,
      )
      ..lineTo(size.width * 0.535, size.height * 0.49)
      ..quadraticBezierTo(
        size.width * 0.43,
        size.height * 0.55,
        size.width * 0.31,
        size.height * 0.49,
      )
      ..close();
    canvas.drawPath(
      sidePlate,
      Paint()
        ..color = const Color(0xFF10141A).withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.004,
    );
    for (final screw in <Offset>[
      Offset(size.width * 0.31, size.height * 0.43),
      Offset(size.width * 0.49, size.height * 0.46),
    ]) {
      canvas.drawCircle(
        screw,
        size.width * 0.014,
        Paint()..color = const Color(0xFF1A2028),
      );
      canvas.drawLine(
        screw.translate(-size.width * 0.008, 0),
        screw.translate(size.width * 0.008, 0),
        Paint()
          ..color = const Color(0xFFADB5BC).withValues(alpha: 0.36)
          ..strokeWidth = size.width * 0.0028
          ..strokeCap = StrokeCap.round,
      );
    }

    final cylinderCenter = Offset(size.width * 0.4, size.height * 0.42);
    final radius = size.height * 0.19;
    _drawCylinder(
      canvas,
      size,
      center: cylinderCenter,
      radius: radius,
      pulse: pulse,
    );
    final crane = Path()
      ..moveTo(size.width * 0.49, size.height * 0.39)
      ..quadraticBezierTo(
        size.width * 0.55,
        size.height * 0.39,
        size.width * 0.59,
        size.height * 0.45,
      )
      ..quadraticBezierTo(
        size.width * 0.54,
        size.height * 0.49,
        size.width * 0.48,
        size.height * 0.48,
      );
    canvas.drawPath(
      crane,
      Paint()
        ..color = const Color(0xFF242B34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.018
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      crane,
      Paint()
        ..color = const Color(0xFFBBC2C8).withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.004
        ..strokeCap = StrokeCap.round,
    );

    final grip = Path()
      ..moveTo(size.width * 0.27, size.height * 0.52)
      ..lineTo(size.width * 0.43, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.83,
        size.width * 0.22,
        size.height * 0.9,
      )
      ..quadraticBezierTo(
        size.width * 0.11,
        size.height * 0.74,
        size.width * 0.2,
        size.height * 0.56,
      )
      ..close();
    canvas.drawPath(
      grip.shift(Offset(0, size.height * 0.012)),
      Paint()..color = Colors.black.withValues(alpha: 0.24),
    );
    canvas.drawPath(
      grip,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width * 0.16, size.height * 0.54),
          Offset(size.width * 0.39, size.height * 0.88),
          const <Color>[
            Color(0xFF8D5636),
            Color(0xFF5E311D),
            Color(0xFF2D170F),
          ],
          const <double>[0, 0.56, 1],
        ),
    );
    canvas.save();
    canvas.clipPath(grip);
    final woodPaint = Paint()
      ..color = const Color(0xFFE2B179).withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.0038
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 5; index += 1) {
      final y = size.height * (0.61 + index * 0.055);
      canvas.drawPath(
        Path()
          ..moveTo(size.width * 0.18, y)
          ..quadraticBezierTo(
            size.width * (0.28 + index * 0.012),
            y + size.height * 0.028,
            size.width * 0.39,
            y + size.height * 0.014,
          ),
        woodPaint,
      );
    }
    final checkPaint = Paint()
      ..color = const Color(0xFF1F110C).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.0026
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 6; index += 1) {
      final startX = size.width * (0.17 + index * 0.037);
      canvas.drawLine(
        Offset(startX, size.height * 0.58),
        Offset(startX + size.width * 0.13, size.height * 0.86),
        checkPaint,
      );
      canvas.drawLine(
        Offset(startX + size.width * 0.13, size.height * 0.58),
        Offset(startX, size.height * 0.86),
        checkPaint,
      );
    }
    canvas.restore();
    canvas.drawPath(
      grip,
      Paint()
        ..color = const Color(0xFF28150F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.009,
    );
    for (final screw in <Offset>[
      Offset(size.width * 0.3, size.height * 0.64),
      Offset(size.width * 0.25, size.height * 0.79),
    ]) {
      canvas.drawCircle(
        screw,
        size.width * 0.018,
        Paint()..color = const Color(0xFF2A1710),
      );
      canvas.drawCircle(
        screw.translate(-size.width * 0.004, -size.height * 0.004),
        size.width * 0.007,
        Paint()..color = const Color(0xFFE2B179).withValues(alpha: 0.32),
      );
    }

    final triggerGuard = Rect.fromLTWH(
      size.width * 0.34,
      size.height * 0.52,
      size.width * 0.16,
      size.height * 0.18,
    );
    canvas.drawOval(
      triggerGuard,
      Paint()
        ..color = const Color(0xFF151820)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.022,
    );
    final triggerX = size.width * (0.417 + triggerPull * 0.046);
    canvas.drawArc(
      Rect.fromLTWH(
        triggerX,
        size.height * 0.535,
        size.width * 0.064,
        size.height * 0.13,
      ),
      math.pi * 0.82,
      math.pi * 0.84,
      false,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(triggerX, size.height * 0.54),
          Offset(triggerX + size.width * 0.06, size.height * 0.66),
          const <Color>[Color(0xFF3C424C), Color(0xFF0A0C10)],
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.014
        ..strokeCap = StrokeCap.round,
    );

    final hammerBack = hammerPhase * 0.052 + recoilKick * 0.016;
    final hammer = Path()
      ..moveTo(size.width * 0.236, size.height * 0.345)
      ..lineTo(
        size.width * (0.156 - hammerBack),
        size.height * (0.264 - hammerPhase * 0.018),
      )
      ..quadraticBezierTo(
        size.width * (0.173 - hammerBack),
        size.height * 0.206,
        size.width * (0.228 - hammerBack * 0.42),
        size.height * 0.224,
      )
      ..lineTo(size.width * 0.304, size.height * 0.318)
      ..close();
    canvas.drawPath(
      hammer,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width * 0.16, size.height * 0.22),
          Offset(size.width * 0.3, size.height * 0.34),
          const <Color>[Color(0xFF3F464F), Color(0xFF15181E)],
        ),
    );

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16 + pulse * 0.04)
      ..strokeWidth = size.width * 0.0055
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.51, size.height * 0.305),
      Offset(size.width * 0.83, size.height * 0.305),
      highlightPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.27, size.height * 0.39),
      Offset(size.width * 0.53, size.height * 0.33),
      highlightPaint..color = Colors.white.withValues(alpha: 0.08),
    );

    if (phase == _RoulettePhase.hit && recoilProgress < 0.6) {
      _drawMuzzleFlash(canvas, size, muzzle, recoilProgress);
    }

    canvas.restore();
  }

  void _drawCylinder(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required double pulse,
  }) {
    canvas.drawCircle(
      center.translate(0, radius * 0.08),
      radius * 1.08,
      Paint()..color = Colors.black.withValues(alpha: 0.34),
    );
    canvas.drawCircle(
      center,
      radius * 1.06,
      Paint()..color = const Color(0xFF11151B),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          center.translate(-radius * 0.2, -radius * 0.18),
          radius * 1.18,
          const <Color>[
            Color(0xFF99A2AD),
            Color(0xFF4D5561),
            Color(0xFF151A21),
          ],
          const <double>[0, 0.45, 1],
        ),
    );

    final chambers = sequence.length;
    for (var index = 0; index < chambers; index += 1) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(cylinderAngle + index * math.pi * 2 / chambers);
      final flute = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(radius * 0.38, 0),
          width: radius * 0.2,
          height: radius * 0.54,
        ),
        Radius.circular(radius * 0.1),
      );
      canvas.drawRRect(
        flute,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(radius * 0.28, -radius * 0.27),
            Offset(radius * 0.48, radius * 0.27),
            const <Color>[Color(0xFF171C23), Color(0xFF5C6570)],
          ),
      );
      canvas.drawRRect(
        flute.deflate(radius * 0.024),
        Paint()..color = Colors.white.withValues(alpha: 0.05),
      );
      canvas.restore();
    }

    for (var index = 0; index < chambers; index += 1) {
      final angle =
          cylinderAngle - math.pi / 2 + index * math.pi * 2 / chambers;
      final chamberCenter =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.58;
      final spent = index < pullCount;
      final active =
          (phase == _RoulettePhase.armed ||
              phase == _RoulettePhase.firing ||
              phase == _RoulettePhase.safeClick) &&
          index == activeChamber;
      final loaded = sequence[index];
      canvas.drawCircle(
        chamberCenter,
        radius * 0.23,
        Paint()..color = const Color(0xFF090B0E),
      );
      canvas.drawCircle(
        chamberCenter,
        radius * 0.2,
        Paint()
          ..shader = ui.Gradient.radial(
            chamberCenter.translate(-radius * 0.03, -radius * 0.03),
            radius * 0.22,
            <Color>[
              spent && loaded
                  ? const Color(0xFF862A23)
                  : spent
                  ? const Color(0xFF6A7568)
                  : const Color(0xFF36404A),
              const Color(0xFF090B0F),
            ],
          ),
      );
      if (phase == _RoulettePhase.idle && index < bulletCount) {
        canvas.drawCircle(
          chamberCenter,
          radius * 0.11,
          Paint()
            ..shader = ui.Gradient.radial(
              chamberCenter.translate(-radius * 0.02, -radius * 0.02),
              radius * 0.13,
              const <Color>[Color(0xFFFFD878), Color(0xFF8B5B21)],
            ),
        );
      }
      if (active) {
        canvas.drawCircle(
          chamberCenter,
          radius * (0.27 + pulse * 0.018),
          Paint()
            ..color = const Color(0xFFFFD36E)
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.width * 0.006,
        );
        canvas.drawCircle(
          chamberCenter,
          radius * 0.308,
          Paint()
            ..color = const Color(0xFFFFD36E).withValues(alpha: 0.18)
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.width * 0.01,
        );
      }
    }
    canvas.drawCircle(
      center,
      radius * 0.34,
      Paint()
        ..shader = ui.Gradient.radial(
          center.translate(-radius * 0.07, -radius * 0.08),
          radius * 0.34,
          const <Color>[Color(0xFF4A535E), Color(0xFF10141A)],
        ),
    );
    canvas.drawCircle(
      center,
      radius * 0.1,
      Paint()..color = const Color(0xFF060709),
    );
  }

  void _drawMuzzleFlash(Canvas canvas, Size size, Offset muzzle, double t) {
    final local = (t / 0.6).clamp(0.0, 1.0);
    final alpha = 1 - Curves.easeInQuad.transform(local);
    final length = size.width * (0.12 + (1 - local) * 0.09);
    final height = size.height * (0.12 + (1 - local) * 0.05);
    final flare = Path()
      ..moveTo(muzzle.dx + size.width * 0.02, muzzle.dy)
      ..lineTo(muzzle.dx + length * 0.55, muzzle.dy - height * 0.58)
      ..lineTo(muzzle.dx + length * 0.42, muzzle.dy - height * 0.1)
      ..lineTo(muzzle.dx + length, muzzle.dy)
      ..lineTo(muzzle.dx + length * 0.44, muzzle.dy + height * 0.14)
      ..lineTo(muzzle.dx + length * 0.58, muzzle.dy + height * 0.62)
      ..close();
    canvas.drawPath(
      flare,
      Paint()
        ..shader = ui.Gradient.linear(
          muzzle,
          Offset(muzzle.dx + length, muzzle.dy),
          <Color>[
            const Color(0xFFFFF5C8).withValues(alpha: alpha),
            const Color(0xFFFFAF2D).withValues(alpha: alpha * 0.86),
            const Color(0xFFC64B3F).withValues(alpha: alpha * 0.22),
          ],
          const <double>[0, 0.48, 1],
        ),
    );
    canvas.drawPath(
      flare,
      Paint()
        ..color = const Color(0xFFFFE39D).withValues(alpha: alpha * 0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.006
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RouletteRevolverPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.sequence != sequence ||
        oldDelegate.bulletCount != bulletCount ||
        oldDelegate.activeChamber != activeChamber ||
        oldDelegate.pullCount != pullCount ||
        oldDelegate.cylinderAngle != cylinderAngle ||
        oldDelegate.fireProgress != fireProgress ||
        oldDelegate.safeKickProgress != safeKickProgress ||
        oldDelegate.recoilProgress != recoilProgress ||
        oldDelegate.ambient != ambient;
  }
}

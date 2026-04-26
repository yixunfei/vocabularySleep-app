part of 'toolbox_singing_bowls_tool.dart';

class _SingingBowlBackdropPainter extends CustomPainter {
  _SingingBowlBackdropPainter({
    required this.accent,
    required this.glow,
    required this.ambientValue,
    required this.strikeValue,
  }) : super(
         repaint: Listenable.merge(<Listenable>[ambientValue, strikeValue]),
       );

  final Color accent;
  final Color glow;
  final Animation<double> ambientValue;
  final Animation<double> strikeValue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final pulse = 0.5 + 0.5 * math.sin(ambientValue.value * math.pi * 2);
    final strike = Curves.easeOut.transform(strikeValue.value);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.22, size.height * 0.16),
        width: size.width * 0.9,
        height: size.shortestSide * 0.52,
      ),
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Colors.white.withValues(alpha: 0.30 + pulse * 0.04),
            glow.withValues(alpha: 0.12 + pulse * 0.05),
            glow.withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.52, 1],
        ).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 58),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.78, size.height * 0.82),
        width: size.width * 0.58,
        height: size.shortestSide * 0.22,
      ),
      Paint()
        ..color = accent.withValues(alpha: 0.04 + pulse * 0.02 + strike * 0.02)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 56),
    );

    // 自然舒适：降低线性纹理的强度，从 0.026 → 0.018
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = accent.withValues(alpha: 0.018);
    const step = 28.0;
    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.height, size.height),
        linePaint,
      );
    }
    for (double x = 0; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        linePaint,
      );
    }

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.14),
            Colors.transparent,
            accent.withValues(alpha: 0.04),
          ],
          stops: const <double>[0, 0.42, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _SingingBowlBackdropPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.glow != glow ||
        oldDelegate.ambientValue != ambientValue ||
        oldDelegate.strikeValue != strikeValue;
  }
}

class _SpectrumBurstPainter extends CustomPainter {
  const _SpectrumBurstPainter({
    required this.accent,
    required this.glow,
    required this.progress,
    required this.seed,
  });

  final Color accent;
  final Color glow;
  final double progress;
  final double seed;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final baseRadius = size.shortestSide * 0.18;
    const ringCount = 5;

    for (var ring = 0; ring < ringCount; ring += 1) {
      final localProgress = (progress - ring * 0.09) / (1 - ring * 0.09);
      if (localProgress < 0 || localProgress > 1) {
        continue;
      }
      final eased = Curves.easeOut.transform(localProgress);
      final opacity =
          math.pow(1 - localProgress, 1.7).toDouble() * (0.22 - ring * 0.03);
      final radius = lerpDouble(
        baseRadius,
        size.shortestSide * (0.44 + ring * 0.035),
        eased,
      )!;
      final ellipse = 0.9 + ring * 0.03;
      final path = Path();
      const steps = 72;
      for (var step = 0; step <= steps; step += 1) {
        final theta = step / steps * math.pi * 2;
        final wobble =
            math.sin(theta * (3 + ring * 0.6) + seed + progress * 7.5) *
                size.shortestSide *
                0.012 *
                (1 - localProgress) +
            math.cos(theta * 5.2 - seed * 0.7 + progress * 5.0) *
                size.shortestSide *
                0.005 *
                (1 - localProgress);
        final r = radius + wobble;
        final point = Offset(
          center.dx + math.cos(theta) * r,
          center.dy + math.sin(theta) * r * ellipse,
        );
        if (step == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = lerpDouble(2.2, 0.18, localProgress)!
          ..color = glow.withValues(alpha: opacity * 0.82)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = lerpDouble(1.4, 0.12, localProgress)!
          ..color = accent.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpectrumBurstPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.glow != glow ||
        oldDelegate.progress != progress ||
        oldDelegate.seed != seed;
  }
}

class _SingingBowlPainter extends CustomPainter {
  const _SingingBowlPainter({
    required this.accent,
    required this.glow,
    required this.voice,
    required this.ambientValue,
    required this.strikeValue,
    required this.pressing,
  });

  final Color accent;
  final Color glow;
  final _SingingBowlVoiceSpec voice;
  final double ambientValue;
  final double strikeValue;
  final bool pressing;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center.translate(0, size.height * 0.02);
    final pulse = 0.5 + 0.5 * math.sin(ambientValue * math.pi * 2);
    final strike = AppEasing.bounce.transform(strikeValue);
    final width = size.width * 0.76;
    final height = size.height * 0.42;
    final rimTop = center.dy - height * 0.34;
    final bowlPath = Path()
      ..moveTo(center.dx - width * 0.46, rimTop)
      ..quadraticBezierTo(
        center.dx - width * 0.54,
        center.dy + height * 0.74,
        center.dx,
        center.dy + height * 0.92,
      )
      ..quadraticBezierTo(
        center.dx + width * 0.54,
        center.dy + height * 0.74,
        center.dx + width * 0.46,
        rimTop,
      )
      ..quadraticBezierTo(
        center.dx,
        center.dy + height * 0.10,
        center.dx - width * 0.46,
        rimTop,
      );
    final bowlBounds = bowlPath.getBounds();
    final topRimRect = Rect.fromCenter(
      center: Offset(center.dx, rimTop),
      width: width,
      height: height * 0.28,
    );
    final innerRimRect = Rect.fromCenter(
      center: Offset(center.dx, rimTop + height * 0.01),
      width: width * 0.86,
      height: height * 0.16,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, height * 0.98),
        width: width * 0.88,
        height: height * 0.22,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.07 + strike * 0.035)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );

    canvas.drawCircle(
      center.translate(0, -height * 0.02),
      width * 0.42,
      Paint()
        ..color = glow.withValues(alpha: 0.11 + strike * 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
    );

    canvas.drawPath(
      bowlPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.72),
            accent.withValues(alpha: 0.18 + strike * 0.08),
            accent.withValues(alpha: 0.10),
          ],
          stops: const <double>[0, 0.18, 0.72, 1],
        ).createShader(bowlBounds),
    );

    canvas.drawPath(
      bowlPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: 0.52),
    );

    canvas.drawOval(
      topRimRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.92),
            accent.withValues(alpha: 0.22 + strike * 0.08),
          ],
        ).createShader(topRimRect),
    );
    canvas.drawOval(
      innerRimRect,
      Paint()..color = Colors.white.withValues(alpha: 0.84),
    );

    canvas.drawPath(
      Path()..addArc(
        Rect.fromCenter(
          center: center.translate(-width * 0.06, height * 0.16),
          width: width * 0.82,
          height: height * 0.7,
        ),
        -math.pi * 0.94,
        math.pi * 0.55,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.2 + strike * 0.08),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(width * 0.18, 0),
        width: width * 0.16,
        height: height * 0.56,
      ),
      Paint()
        ..color = accent.withValues(
          alpha: 0.14 + strike * 0.1 + (pressing ? 0.03 : 0),
        ),
    );

    final ringCount = switch (voice.id) {
      'pure' => 1,
      'deep' => 4,
      'brass' => 4,
      _ => 3,
    };
    for (var index = 0; index < ringCount; index += 1) {
      final ratio = ringCount == 1 ? 0.0 : index / (ringCount - 1);
      final ringRect = Rect.fromCenter(
        center: center.translate(0, height * 0.04),
        width: lerpDouble(width * 0.36, width * 0.74, ratio)!,
        height: lerpDouble(height * 0.12, height * 0.34, ratio)!,
      );
      canvas.drawOval(
        ringRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = lerpDouble(1.4, 0.8, ratio)!
          ..color = glow.withValues(
            alpha: (0.08 + pulse * 0.04 + strike * 0.04) * (1 - ratio * 0.28),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SingingBowlPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.glow != glow ||
        oldDelegate.voice != voice ||
        oldDelegate.ambientValue != ambientValue ||
        oldDelegate.strikeValue != strikeValue ||
        oldDelegate.pressing != pressing;
  }
}

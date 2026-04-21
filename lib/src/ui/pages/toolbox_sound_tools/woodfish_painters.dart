part of '../toolbox_sound_tools.dart';

class _WoodfishRipplePainter extends CustomPainter {
  const _WoodfishRipplePainter({
    required this.impact,
    required this.ambient,
    required this.accentColor,
    required this.immersive,
  });

  final double impact;
  final double ambient;
  final Color accentColor;
  final bool immersive;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final maxRadius = size.width * 0.48;

    // Draw 3 expanding rings with staggered timing
    for (var i = 0; i < 3; i += 1) {
      final ringImpact = (impact - i * 0.18).clamp(0.0, 1.0);
      if (ringImpact <= 0.005) continue;

      final radius = maxRadius * (0.3 + ringImpact * 0.7);
      final alpha = (0.28 * (1 - ringImpact)).clamp(0.0, 1.0);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = accentColor.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 - ringImpact * 0.8,
      );
    }

    // Inner glow pulse
    if (impact > 0.1) {
      canvas.drawCircle(
        center,
        maxRadius * 0.22 * impact,
        Paint()
          ..color = accentColor.withValues(alpha: impact * 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WoodfishRipplePainter oldDelegate) {
    return oldDelegate.impact != impact || oldDelegate.ambient != ambient;
  }
}

/// Thin arc showing cycle progress around the woodfish image area.
class _WoodfishCycleRingPainter extends CustomPainter {
  const _WoodfishCycleRingPainter({
    required this.cycleProgress,
    required this.accentColor,
    required this.immersive,
  });

  final double cycleProgress;
  final Color accentColor;
  final bool immersive;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ovalRect = Rect.fromCenter(
      center: rect.center,
      width: rect.width * 0.92,
      height: rect.height * 0.92,
    );

    // Background ring
    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = (immersive ? Colors.white : Colors.black).withValues(
          alpha: immersive ? 0.08 : 0.06,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Progress arc
    if (cycleProgress > 0.001) {
      canvas.drawArc(
        ovalRect,
        -math.pi / 2,
        math.pi * 2 * cycleProgress.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = accentColor.withValues(alpha: immersive ? 0.5 : 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WoodfishCycleRingPainter oldDelegate) {
    return oldDelegate.cycleProgress != cycleProgress ||
        oldDelegate.immersive != immersive;
  }
}

/// Draws a realistic wooden fish (木鱼) in 3/4 perspective.
///
/// Anatomy (matching the reference photo):
///   - Plump, egg-shaped body viewed from slightly above, lying on its side
///   - The LEFT end is the rounded tail
///   - The RIGHT end narrows to a pointed head / nose
///   - A horizontal SLIT runs along the right side of the body (the "mouth"),
///     exposing the dark hollow interior — this is the resonance cavity
///   - The body has a pronounced dome (3D volume), not flat
///   - Natural pale-wood colouring with subtle grain
class _WoodfishBodyPainter extends CustomPainter {
  const _WoodfishBodyPainter({
    required this.impact,
    required this.ambient,
    required this.accent,
    required this.immersive,
    required this.visualStyle,
  });

  final double impact;
  final double ambient;
  final bool accent;
  final bool immersive;
  final _WoodfishVisualStyle visualStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final tokens = _visualTokens(visualStyle);
    final w = size.width;
    final h = size.height;

    // Body centre & dimensions — wider than tall to look plump & rounded.
    final cx = w * 0.45;
    final cy = h * 0.54;
    final bw = w * 0.90; // total body width (left-to-right)
    final bh = h * 0.78; // total body height (top-to-bottom dome)

    // ── 1. Ground contact shadow ──
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + bh * 0.42),
        width: bw * 0.68,
        height: bh * 0.14,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: immersive ? 0.40 : 0.24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // ── 2. Impact halo (behind body) ──
    if (impact > 0.06) {
      final haloColor = accent ? tokens.accentWarm : tokens.accentCool;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: bw * 1.08,
          height: bh * 1.08,
        ),
        Paint()
          ..color = haloColor.withValues(alpha: impact * 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
      );
    }

    // ── 3. Main body outline (plump egg / fish shape) ──
    //
    // The shape is like a horizontal egg with the narrow end (nose/head)
    // pointing right and the wide end (tail) on the left.
    // The TOP contour bulges upward strongly to convey dome volume.
    // The BOTTOM contour is flatter (sitting on a surface).
    final bodyPath = Path()
      // Start at the tail (leftmost point, slightly below centre)
      ..moveTo(cx - bw * 0.48, cy + bh * 0.02)
      // ── Bottom contour (belly) — gently curves right ──
      ..cubicTo(
        cx - bw * 0.32,
        cy + bh * 0.38, // wide belly sag
        cx + bw * 0.10,
        cy + bh * 0.40, // belly peak
        cx + bw * 0.42,
        cy + bh * 0.06, // converges toward nose
      )
      // ── Nose tip (rightmost, slightly above centre) ──
      ..quadraticBezierTo(
        cx + bw * 0.52,
        cy - bh * 0.06,
        cx + bw * 0.42,
        cy - bh * 0.18,
      )
      // ── Top contour (dome) — high arc leftward ──
      ..cubicTo(
        cx + bw * 0.12,
        cy - bh * 0.50, // strong upward bulge
        cx - bw * 0.26,
        cy - bh * 0.48,
        cx - bw * 0.48,
        cy + bh * 0.02, // back to tail
      )
      ..close();

    final bodyRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: bw,
      height: bh,
    );

    // ── 3a. Soft body shadow ──
    canvas.drawPath(
      bodyPath.shift(Offset(0, 8 + impact * 5)),
      Paint()
        ..color = Colors.black.withValues(alpha: immersive ? 0.30 : 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    // ── 3b. Body fill — warm wood gradient (light top-left → dark bottom-right) ──
    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-0.5, -0.9),
          end: const Alignment(0.4, 0.8),
          colors: <Color>[
            Color.lerp(
              tokens.bodyGradient[0],
              Colors.white,
              0.22 + impact * 0.08,
            )!,
            tokens.bodyGradient[0],
            tokens.bodyGradient[1],
            tokens.bodyGradient[2],
          ],
          stops: const <double>[0.0, 0.30, 0.60, 1.0],
        ).createShader(bodyRect),
    );

    // ── 3c. Body outline ──
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = tokens.bodyStroke.withValues(alpha: 0.44)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // ── 4. Upper dome highlight (conveys 3-D volume) ──
    final domePath = Path()
      ..moveTo(cx - bw * 0.38, cy - bh * 0.08)
      ..cubicTo(
        cx - bw * 0.20,
        cy - bh * 0.44,
        cx + bw * 0.18,
        cy - bh * 0.46,
        cx + bw * 0.36,
        cy - bh * 0.12,
      )
      ..quadraticBezierTo(
        cx + bw * 0.04,
        cy - bh * 0.14,
        cx - bw * 0.38,
        cy - bh * 0.08,
      )
      ..close();
    canvas.drawPath(
      domePath,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-0.3, -1),
          end: const Alignment(0.2, 0.5),
          colors: <Color>[
            Color.lerp(tokens.bodyGradient[0], Colors.white, 0.36)!,
            Color.lerp(tokens.bodyGradient[0], tokens.bodyGradient[1], 0.20)!,
            tokens.bodyGradient[1].withValues(alpha: 0.0),
          ],
          stops: const <double>[0.0, 0.50, 1.0],
        ).createShader(bodyRect),
    );

    // ── 5. Belly shadow (underside darker) ──
    final bellyPath = Path()
      ..moveTo(cx - bw * 0.36, cy + bh * 0.12)
      ..cubicTo(
        cx - bw * 0.22,
        cy + bh * 0.36,
        cx + bw * 0.12,
        cy + bh * 0.38,
        cx + bw * 0.36,
        cy + bh * 0.10,
      )
      ..lineTo(cx + bw * 0.30, cy + bh * 0.02)
      ..cubicTo(
        cx + bw * 0.06,
        cy + bh * 0.14,
        cx - bw * 0.18,
        cy + bh * 0.12,
        cx - bw * 0.36,
        cy + bh * 0.12,
      )
      ..close();
    canvas.drawPath(
      bellyPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.transparent,
            Colors.black.withValues(alpha: 0.14),
          ],
        ).createShader(bodyRect),
    );

    // ── 6. Mouth slit — a horizontal opening on the RIGHT side ──
    //
    // In a real 木鱼 the slit runs along one side. When viewed from 3/4
    // the slit appears as a dark horizontal gap on the front-right, with
    // the upper and lower lips of wood framing it.
    //
    // We draw: deep interior shadow → dark slit stroke → upper lip
    // highlight → lower lip shadow → cavity depth glow.

    // Slit runs from roughly body-centre to near the nose.
    final slitLeft = cx - bw * 0.06;
    final slitRight = cx + bw * 0.44;
    final slitY = cy + bh * 0.01; // at the body's equator line

    // Interior shadow (wide blurred dark region behind the slit)
    final slitInteriorPath = Path()
      ..moveTo(slitLeft, slitY)
      ..cubicTo(
        slitLeft + (slitRight - slitLeft) * 0.20,
        slitY - bh * 0.14,
        slitLeft + (slitRight - slitLeft) * 0.70,
        slitY - bh * 0.08,
        slitRight,
        slitY - bh * 0.04,
      );
    canvas.drawPath(
      slitInteriorPath.shift(Offset(0, bh * 0.03)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.36 + impact * 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = bh * 0.20
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Main dark slit line
    canvas.drawPath(
      slitInteriorPath,
      Paint()
        ..color = tokens.grooveDark.withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = bh * 0.12
        ..strokeCap = StrokeCap.round,
    );

    // Deep centre of the slit (narrower, blacker)
    canvas.drawPath(
      slitInteriorPath.shift(Offset(0, bh * 0.005)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.62)
        ..style = PaintingStyle.stroke
        ..strokeWidth = bh * 0.055
        ..strokeCap = StrokeCap.round,
    );

    // Upper lip highlight (wood edge catches light above the slit)
    final upperLip = Path()
      ..moveTo(slitLeft + (slitRight - slitLeft) * 0.04, slitY - bh * 0.07)
      ..cubicTo(
        slitLeft + (slitRight - slitLeft) * 0.28,
        slitY - bh * 0.18,
        slitLeft + (slitRight - slitLeft) * 0.68,
        slitY - bh * 0.13,
        slitRight - (slitRight - slitLeft) * 0.02,
        slitY - bh * 0.08,
      );
    canvas.drawPath(
      upperLip,
      Paint()
        ..color = tokens.grooveLight.withValues(alpha: 0.34 + impact * 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );

    // Lower lip edge (subtle dark line below the slit)
    final lowerLip = Path()
      ..moveTo(slitLeft + (slitRight - slitLeft) * 0.06, slitY + bh * 0.06)
      ..cubicTo(
        slitLeft + (slitRight - slitLeft) * 0.30,
        slitY + bh * 0.12,
        slitLeft + (slitRight - slitLeft) * 0.65,
        slitY + bh * 0.08,
        slitRight - (slitRight - slitLeft) * 0.04,
        slitY + bh * 0.02,
      );
    canvas.drawPath(
      lowerLip,
      Paint()
        ..color = tokens.bodyStroke.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );

    // Mouth opening "peek" at the nose end — the slit widens into
    // a visible cavity at the rightmost tip.
    final openEdge = Path()
      ..moveTo(slitRight - bw * 0.04, slitY - bh * 0.10)
      ..lineTo(slitRight + bw * 0.01, slitY - bh * 0.03)
      ..lineTo(slitRight - bw * 0.03, slitY + bh * 0.05)
      ..close();
    canvas.drawPath(
      openEdge,
      Paint()..color = Colors.black.withValues(alpha: 0.52),
    );
    // Light edge on the cavity opening
    canvas.drawPath(
      openEdge.shift(const Offset(-1.2, -1.0)),
      Paint()
        ..color = tokens.grooveLight.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // ── 7. Wood grain lines (clipped to body) ──
    canvas.save();
    canvas.clipPath(bodyPath);
    for (var i = 0; i < 7; i += 1) {
      final gy = cy - bh * 0.32 + i * bh * 0.10;
      final drift = math.sin((ambient + i * 0.17) * math.pi * 2) * bh * 0.025;
      final grain = Path()
        ..moveTo(cx - bw * 0.44, gy)
        ..cubicTo(
          cx - bw * 0.16,
          gy - bh * 0.05 + drift,
          cx + bw * 0.12,
          gy + bh * 0.05 - drift * 0.7,
          cx + bw * 0.40,
          gy - bh * 0.02 + drift * 0.3,
        );
      canvas.drawPath(
        grain,
        Paint()
          ..color = tokens.grain.withValues(alpha: 0.09 + ambient * 0.03)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }
    canvas.restore();

    // ── 8. Nose tip dot ──
    canvas.drawCircle(
      Offset(cx + bw * 0.48, cy - bh * 0.06),
      bw * 0.012,
      Paint()..color = tokens.bodyStroke.withValues(alpha: 0.42),
    );

    // ── 9. Specular highlight on top of dome ──
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - bw * 0.06, cy - bh * 0.30),
        width: bw * 0.30,
        height: bh * 0.09,
      ),
      Paint()
        ..color = tokens.dust.withValues(alpha: 0.24 + impact * 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // ── 10. Tail detail (decorative curl on the left end) ──
    final tailArc = Rect.fromCenter(
      center: Offset(cx - bw * 0.38, cy + bh * 0.06),
      width: bw * 0.12,
      height: bh * 0.14,
    );
    canvas.drawArc(
      tailArc,
      0.3,
      math.pi * 1.4,
      false,
      Paint()
        ..color = tokens.bodyStroke.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    // ── 11. Impact flash on body surface ──
    if (impact > 0.10) {
      final flashColor = accent ? tokens.accentWarm : tokens.accentCool;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy - bh * 0.14),
          width: bw * 0.34 * impact,
          height: bh * 0.24 * impact,
        ),
        Paint()
          ..color = flashColor.withValues(alpha: impact * 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WoodfishBodyPainter oldDelegate) {
    return oldDelegate.impact != impact ||
        oldDelegate.ambient != ambient ||
        oldDelegate.accent != accent ||
        oldDelegate.immersive != immersive ||
        oldDelegate.visualStyle != visualStyle;
  }
}

class _WoodfishMalletPainter extends CustomPainter {
  const _WoodfishMalletPainter({
    required this.colorScheme,
    required this.immersive,
    required this.impact,
    required this.visualStyle,
  });

  final ColorScheme colorScheme;
  final bool immersive;
  final double impact;
  final _WoodfishVisualStyle visualStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final tokens = _visualTokens(visualStyle);

    // ── Shaft geometry (long tapered stick from bottom-left to top-right) ──
    final shaftStart = Offset(size.width * 0.04, size.height * 0.72);
    final shaftEnd = Offset(size.width * 0.74, size.height * 0.46);
    final shaftWidth = size.height * 0.09;
    final shaftRect = Rect.fromPoints(shaftStart, shaftEnd).inflate(shaftWidth);
    final glowColor =
        Color.lerp(
          tokens.malletGlow,
          immersive ? Colors.white : colorScheme.primary,
          immersive ? 0.26 : 0.18,
        ) ??
        tokens.malletGlow;

    // ── Motion trail when striking ──
    if (impact > 0.14) {
      for (var i = 0; i < 2; i += 1) {
        final trailT = (impact - i * 0.22).clamp(0.0, 1.0);
        if (trailT <= 0.01) continue;
        canvas.drawLine(
          shaftStart.translate(-18 - i * 8, 6 + i * 2),
          shaftEnd.translate(-10 - i * 7, 5 + i * 2),
          Paint()
            ..color = glowColor.withValues(alpha: 0.08 * trailT)
            ..strokeWidth = shaftWidth * (0.9 - i * 0.2)
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }
    }

    // ── Shaft shadow ──
    canvas.drawLine(
      shaftStart.translate(0, shaftWidth * 0.5),
      shaftEnd.translate(0, shaftWidth * 0.45),
      Paint()
        ..color = Colors.black.withValues(alpha: immersive ? 0.36 : 0.2)
        ..strokeWidth = shaftWidth * 1.05
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    // ── Shaft body (tapered) ──
    // Draw the shaft as a tapered path for realism
    final shaftDir = (shaftEnd - shaftStart);
    final shaftLen = shaftDir.distance;
    final shaftNorm = Offset(-shaftDir.dy, shaftDir.dx) / shaftLen;
    final wStart = shaftWidth * 0.38; // thinner at handle end
    final wEnd = shaftWidth * 0.52; // slightly thicker near head

    final shaftPath = Path()
      ..moveTo(
        shaftStart.dx + shaftNorm.dx * wStart,
        shaftStart.dy + shaftNorm.dy * wStart,
      )
      ..lineTo(
        shaftEnd.dx + shaftNorm.dx * wEnd,
        shaftEnd.dy + shaftNorm.dy * wEnd,
      )
      ..lineTo(
        shaftEnd.dx - shaftNorm.dx * wEnd,
        shaftEnd.dy - shaftNorm.dy * wEnd,
      )
      ..lineTo(
        shaftStart.dx - shaftNorm.dx * wStart,
        shaftStart.dy - shaftNorm.dy * wStart,
      )
      ..close();

    canvas.drawPath(
      shaftPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color.lerp(tokens.malletShaftGradient[0], Colors.white, 0.12)!,
            tokens.malletShaftGradient[0],
            tokens.malletShaftGradient[1],
          ],
          stops: const <double>[0.0, 0.3, 1.0],
        ).createShader(shaftRect),
    );

    // Shaft highlight (light edge)
    canvas.drawLine(
      Offset(
        shaftStart.dx + shaftNorm.dx * wStart * 0.6,
        shaftStart.dy + shaftNorm.dy * wStart * 0.6,
      ),
      Offset(
        shaftEnd.dx + shaftNorm.dx * wEnd * 0.5,
        shaftEnd.dy + shaftNorm.dy * wEnd * 0.5,
      ),
      Paint()
        ..color = tokens.dust.withValues(alpha: 0.22)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );

    // Shaft outline
    canvas.drawPath(
      shaftPath,
      Paint()
        ..color = tokens.bodyStroke.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    // ── Padded head (round, like the reference image) ──
    final tipCenter = shaftEnd.translate(
      size.width * 0.04,
      -size.height * 0.02,
    );
    final headRadius = math.min(size.width, size.height) * 0.14;

    // Head shadow
    canvas.drawCircle(
      tipCenter.translate(0, headRadius * 0.5),
      headRadius * 1.05,
      Paint()
        ..color = Colors.black.withValues(alpha: immersive ? 0.38 : 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Head body (round padded shape)
    final headBounds = Rect.fromCircle(center: tipCenter, radius: headRadius);
    canvas.drawCircle(
      tipCenter,
      headRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.28, -0.36),
          radius: 1.0,
          colors: <Color>[
            Color.lerp(tokens.malletHeadGradient[0], Colors.white, 0.26)!,
            tokens.malletHeadGradient[0],
            tokens.malletHeadGradient[1],
            tokens.malletHeadGradient[2],
          ],
          stops: const <double>[0.0, 0.25, 0.62, 1.0],
        ).createShader(headBounds),
    );

    // Head outline
    canvas.drawCircle(
      tipCenter,
      headRadius,
      Paint()
        ..color = tokens.bodyStroke.withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Highlight crescent on top-left
    final highlightPath = Path()
      ..addArc(
        Rect.fromCircle(center: tipCenter, radius: headRadius * 0.86),
        -math.pi * 0.85,
        math.pi * 0.6,
      );
    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // ── Decorative band where shaft meets head ──
    final bandCenter = Offset.lerp(shaftEnd, tipCenter, 0.35)!;
    canvas.drawCircle(
      bandCenter,
      headRadius * 0.22,
      Paint()..color = tokens.malletBand.withValues(alpha: 0.78),
    );
    canvas.drawCircle(
      bandCenter,
      headRadius * 0.22,
      Paint()
        ..color = tokens.bodyStroke.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // ── Impact glow at the tip ──
    if (impact > 0.08) {
      canvas.drawCircle(
        tipCenter,
        headRadius * (0.5 + impact * 0.4),
        Paint()
          ..color = glowColor.withValues(alpha: impact * 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WoodfishMalletPainter oldDelegate) {
    return oldDelegate.impact != impact ||
        oldDelegate.immersive != immersive ||
        oldDelegate.visualStyle != visualStyle;
  }
}

part of '../toolbox_sound_tools.dart';

class _DrumSpotlightPainter extends CustomPainter {
  const _DrumSpotlightPainter({
    required this.beam,
    required this.progress,
    required this.fullScreen,
  });

  final _DrumLaserBeam beam;
  final double progress;
  final bool fullScreen;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final eased = Curves.easeInOutSine.transform(progress.clamp(0.0, 1.0));
    final apexX = size.width * 0.5;
    final angleBase =
        beam.startAngle + (beam.endAngle - beam.startAngle) * eased;
    final angleWobble =
        math.sin(progress * math.pi * 8.4 + beam.wobblePhase) * 0.32;
    final beamAngle = angleBase + angleWobble;
    final targetDrift =
        math.sin(progress * math.pi * 9.6 + beam.wobblePhase * 1.3) *
        size.width *
        0.08;
    final coneHeight = size.height * (fullScreen ? 0.92 : 0.74);
    final coneHalfWidth = (size.width * beam.coneWidthFactor)
        .clamp(size.width * 0.09, size.width * 0.3)
        .toDouble();
    final flareRadius = math.max(size.width * 0.05, coneHalfWidth * 0.72);
    final minTargetX = coneHalfWidth;
    final maxTargetX = math.max(minTargetX, size.width - coneHalfWidth);
    final sweepHalfArc = _DrumPadToolState._laserSweepHalfArc;
    final normalizedAngle = (beamAngle / sweepHalfArc).clamp(-1.0, 1.0);
    final rawTargetX =
        apexX + normalizedAngle * size.width * 0.46 + targetDrift;
    final targetX = rawTargetX.clamp(minTargetX, maxTargetX).toDouble();

    final path = Path()
      ..moveTo(apexX, -24)
      ..quadraticBezierTo(
        apexX - coneHalfWidth * 0.22,
        coneHeight * 0.18,
        targetX - coneHalfWidth,
        coneHeight,
      )
      ..quadraticBezierTo(
        targetX,
        coneHeight * 0.82,
        targetX + coneHalfWidth,
        coneHeight,
      )
      ..quadraticBezierTo(
        apexX + coneHalfWidth * 0.24,
        coneHeight * 0.18,
        apexX,
        -24,
      )
      ..close();

    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          beam.color.withValues(alpha: 0),
          beam.color.withValues(alpha: 0.28),
          beam.color.withValues(alpha: 0.52),
          beam.color.withValues(alpha: 0),
        ],
        stops: const <double>[0, 0.18, 0.78, 1],
      ).createShader(Rect.fromLTWH(0, 0, size.width, coneHeight))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26);
    canvas.drawPath(path, beamPaint);

    final corePaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              beam.color.withValues(alpha: 0),
              beam.color.withValues(alpha: 0.42),
              beam.color.withValues(alpha: 0.78),
              beam.color.withValues(alpha: 0),
            ],
            stops: const <double>[0, 0.28, 0.72, 1],
          ).createShader(
            Rect.fromLTWH(
              targetX - coneHalfWidth * 0.46,
              0,
              coneHalfWidth * 0.92,
              coneHeight,
            ),
          )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(path, corePaint);

    final glowRect = Rect.fromCircle(
      center: Offset(targetX, coneHeight),
      radius: flareRadius,
    );
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          beam.color.withValues(alpha: 1),
          beam.color.withValues(alpha: 0.58),
          beam.color.withValues(alpha: 0),
        ],
        stops: const <double>[0, 0.3, 1],
      ).createShader(glowRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset(targetX, coneHeight), flareRadius, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _DrumSpotlightPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.beam != beam ||
        oldDelegate.fullScreen != fullScreen;
  }
}

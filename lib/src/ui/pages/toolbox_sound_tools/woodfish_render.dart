part of '../toolbox_sound_tools.dart';

class _WoodfishStagePainter extends CustomPainter {
  const _WoodfishStagePainter({
    required this.colorScheme,
    required this.impact,
    required this.ambient,
    required this.cycleProgress,
    required this.accent,
    required this.immersive,
    required this.visualStyle,
  });

  final ColorScheme colorScheme;
  final double impact;
  final double ambient;
  final double cycleProgress;
  final bool accent;
  final bool immersive;
  final _WoodfishVisualStyle visualStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final tokens = _visualTokens(visualStyle);
    final rect = Offset.zero & size;

    final stageColors = immersive
        ? tokens.immersiveStageGradient
        : tokens.normalStageGradient;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            stageColors[0],
            Color.lerp(stageColors[1], stageColors[2], ambient * 0.7)!,
            stageColors[2],
          ],
        ).createShader(rect),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.2),
          radius: 1.1,
          colors: <Color>[
            Colors.transparent,
            Colors.black.withValues(alpha: immersive ? 0.32 : 0.12),
          ],
          stops: const <double>[0.5, 1.0],
        ).createShader(rect),
    );

    if (immersive) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, 0.3),
            radius: 0.9,
            colors: <Color>[
              tokens.accentWarm.withValues(alpha: 0.04 + impact * 0.03),
              Colors.transparent,
            ],
          ).createShader(rect),
      );
    } else {
      final texturePaint = Paint()
        ..color = tokens.grain.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      for (var index = 0; index < 5; index += 1) {
        final y = rect.top + rect.height * (0.18 + index * 0.14);
        final sway = math.sin((ambient + index * 0.2) * math.pi * 2) * 6;
        final path = Path()
          ..moveTo(rect.left - 20, y + sway * 0.2)
          ..cubicTo(
            rect.width * 0.24,
            y - 6 + sway,
            rect.width * 0.56,
            y + 10 - sway * 0.7,
            rect.right + 20,
            y - 3 + sway * 0.25,
          );
        canvas.drawPath(path, texturePaint);
      }
    }

    for (var i = 0; i < 8; i += 1) {
      final phase = (ambient + i * 0.14) % 1.0;
      final px = rect.left + rect.width * (0.1 + i * 0.11);
      final py = rect.top + rect.height * (0.15 + phase * 0.65);
      final drift = math.sin((ambient * 2 + i * 0.3) * math.pi) * 8;
      canvas.drawCircle(
        Offset(px + drift, py),
        0.8 + (i % 3) * 0.4,
        Paint()
          ..color = tokens.dust.withValues(
            alpha:
                (immersive ? 0.06 : 0.1) *
                (1 - phase * 0.6) *
                (0.6 + impact * 0.5),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WoodfishStagePainter oldDelegate) {
    return oldDelegate.impact != impact ||
        oldDelegate.ambient != ambient ||
        oldDelegate.cycleProgress != cycleProgress ||
        oldDelegate.accent != accent ||
        oldDelegate.immersive != immersive ||
        oldDelegate.visualStyle != visualStyle;
  }
}

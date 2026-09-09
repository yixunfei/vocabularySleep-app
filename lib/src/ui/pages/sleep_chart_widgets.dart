import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import 'sleep_assistant_ui_support.dart';

class SleepChartPoint {
  const SleepChartPoint({
    required this.label,
    required this.value,
    this.valueLabel,
  });

  final String label;
  final double? value;
  final String? valueLabel;
}

class SleepMetricChartCard extends StatelessWidget {
  const SleepMetricChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.i18n,
    this.color,
  });

  final String title;
  final String subtitle;
  final List<SleepChartPoint> points;
  final AppI18n i18n;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = sleepReadableAccent(
      context,
      color ?? Theme.of(context).colorScheme.primary,
      darkBlend: 0.24,
    );
    final hasValues = points.any((item) => item.value != null);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            if (!hasValues)
              Container(
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                ),
                child: Text(i18n.t('toolbox.sleep.core.noData')),
              )
            else
              SizedBox(
                height: 150,
                child: CustomPaint(
                  painter: _SleepLineChartPainter(
                    points: points,
                    color: resolvedColor,
                    gridColor: Theme.of(context).colorScheme.outlineVariant,
                    textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: points
                  .map(
                    (point) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                      ),
                      child: Text(
                        '${point.label} ${point.valueLabel ?? '--'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepLineChartPainter extends CustomPainter {
  const _SleepLineChartPainter({
    required this.points,
    required this.color,
    required this.gridColor,
    required this.textColor,
  });

  final List<SleepChartPoint> points;
  final Color color;
  final Color gridColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final offsets = _offsets(size);
    if (offsets.isEmpty) return;
    _drawGrid(canvas, size);
    _drawSegments(canvas, offsets);
    _drawLabels(canvas, size);
  }

  List<Offset?> _offsets(Size size) {
    final values = points
        .map((item) => item.value)
        .whereType<double>()
        .toList();
    if (values.isEmpty || size.width <= 40 || size.height <= 36) return [];
    final minimum = values.reduce(math.min);
    final maximum = values.reduce(math.max);
    final spread = math.max(maximum - minimum, 1.0);
    return List.generate(points.length, (index) {
      final value = points[index].value;
      if (value == null) return null;
      final normalized = maximum == minimum ? 0.5 : (value - minimum) / spread;
      final x = points.length <= 1
          ? size.width / 2
          : 20 + (size.width - 40) * index / (points.length - 1);
      return Offset(x, 12 + (1 - normalized) * (size.height - 36));
    });
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (var index = 0; index < 3; index++) {
      final y = 12 + (size.height - 36) * index / 2;
      canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), paint);
    }
  }

  void _drawSegments(Canvas canvas, List<Offset?> offsets) {
    final line = Paint()
      ..color = color
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = color;
    Offset? previous;
    for (final point in offsets) {
      if (point == null) {
        // A missing date is a gap, never a line suggesting a measured value.
        previous = null;
        continue;
      }
      if (previous != null) canvas.drawLine(previous, point, line);
      canvas.drawCircle(point, 4, dot);
      previous = point;
    }
  }

  void _drawLabels(Canvas canvas, Size size) {
    final interval = math.max(1, (points.length / 4).ceil());
    for (var index = 0; index < points.length; index++) {
      if (index % interval != 0 && index != points.length - 1) continue;
      // Avoid crowding the final label after a near-final tick.
      if (index != points.length - 1 && points.length - 1 - index < interval) {
        continue;
      }
      final text = TextPainter(
        text: TextSpan(
          text: points[index].label,
          style: TextStyle(color: textColor, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = points.length <= 1
          ? size.width / 2
          : 20 + (size.width - 40) * index / (points.length - 1);
      text.paint(
        canvas,
        Offset(
          (x - text.width / 2).clamp(0, size.width - text.width),
          size.height - 18,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SleepLineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor;
  }
}

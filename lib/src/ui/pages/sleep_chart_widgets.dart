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
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;
    final hasValues = points.any((item) => item.value != null);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
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
                child: Text(
                  pickSleepText(
                    i18n,
                    zh: '数据不足，先继续记录',
                    en: 'Not enough data yet',
                  ),
                ),
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
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
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
    const topPadding = 12.0;
    const bottomPadding = 24.0;
    const leftPadding = 8.0;
    const rightPadding = 8.0;
    final usableHeight = size.height - topPadding - bottomPadding;
    final usableWidth = size.width - leftPadding - rightPadding;
    final values = points.map((item) => item.value).whereType<double>().toList();
    if (values.isEmpty || usableHeight <= 0 || usableWidth <= 0) {
      return;
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final spread = maxValue - minValue < 0.001 ? 1.0 : maxValue - minValue;

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.4)
      ..strokeWidth = 1;

    for (var i = 0; i < 3; i += 1) {
      final y = topPadding + usableHeight * (i / 2);
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
    }

    final pointOffsets = <Offset?>[];
    final stepX = points.length <= 1 ? usableWidth : usableWidth / (points.length - 1);
    for (var i = 0; i < points.length; i += 1) {
      final value = points[i].value;
      if (value == null) {
        pointOffsets.add(null);
        continue;
      }
      final normalized = (value - minValue) / spread;
      final x = leftPadding + stepX * i;
      final y = topPadding + (1 - normalized) * usableHeight;
      pointOffsets.add(Offset(x, y));
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          color.withValues(alpha: 0.24),
          color.withValues(alpha: 0.02),
        ],
      ).createShader(Offset.zero & size);

    final linePath = Path();
    final fillPath = Path();
    var started = false;
    for (final point in pointOffsets) {
      if (point == null) {
        continue;
      }
      if (!started) {
        linePath.moveTo(point.dx, point.dy);
        fillPath.moveTo(point.dx, size.height - bottomPadding);
        fillPath.lineTo(point.dx, point.dy);
        started = true;
      } else {
        linePath.lineTo(point.dx, point.dy);
        fillPath.lineTo(point.dx, point.dy);
      }
    }
    if (started) {
      for (var i = pointOffsets.length - 1; i >= 0; i -= 1) {
        final point = pointOffsets[i];
        if (point == null) {
          continue;
        }
        fillPath.lineTo(point.dx, size.height - bottomPadding);
        break;
      }
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(linePath, linePaint);
    }

    final dotPaint = Paint()..color = color;
    final dotFillPaint = Paint()..color = Colors.white;
    for (final point in pointOffsets) {
      if (point == null) {
        continue;
      }
      canvas.drawCircle(point, 4.8, dotPaint);
      canvas.drawCircle(point, 2.4, dotFillPaint);
    }

    for (var i = 0; i < points.length; i += 1) {
      final label = points[i].label;
      final x = leftPadding + stepX * i;
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(
          x - textPainter.width / 2,
          size.height - bottomPadding + 6,
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

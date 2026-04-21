part of '../toolbox_sound_tools.dart';

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HarpSweepTrail {
  const _HarpSweepTrail({
    required this.position,
    required this.velocity,
    required this.createdAtMicros,
    required this.strength,
  });

  final Offset position;
  final Offset velocity;
  final int createdAtMicros;
  final double strength;
}

class _HarpPainter extends CustomPainter {
  const _HarpPainter({
    required this.stringCount,
    required this.noteFrequencies,
    required this.stringOffsets,
    required this.focusedString,
    required this.colorScheme,
    required this.paletteColors,
    required this.pluckStyleId,
    required this.chordStringIndexes,
    required this.sweepTrails,
    required this.horizontalLayout,
  });

  final int stringCount;
  final List<double> noteFrequencies;
  final List<double> stringOffsets;
  final int? focusedString;
  final ColorScheme colorScheme;
  final List<Color> paletteColors;
  final String pluckStyleId;
  final Set<int> chordStringIndexes;
  final List<_HarpSweepTrail> sweepTrails;
  final bool horizontalLayout;

  double _stringTrackAt(int index, Size size) {
    final totalSpan = horizontalLayout ? size.height : size.width;
    final adaptiveInset = totalSpan * (horizontalLayout ? 0.07 : 0.16);
    final minInset = horizontalLayout ? 18.0 : 34.0;
    final leadingInset = math.max(minInset, adaptiveInset);
    final trailingInset = math.max(minInset, adaptiveInset);
    final usableSpan = math.max(1.0, totalSpan - leadingInset - trailingInset);
    if (stringCount == 1) return totalSpan / 2;
    return leadingInset + usableSpan * (index / (stringCount - 1));
  }

  Color _paletteColorAt(double t) {
    if (paletteColors.isEmpty) return colorScheme.primary;
    if (paletteColors.length == 1) return paletteColors.first;
    final clamped = t.clamp(0.0, 1.0);
    final scaled = clamped * (paletteColors.length - 1);
    final index = scaled.floor().clamp(0, paletteColors.length - 1);
    final next = math.min(index + 1, paletteColors.length - 1);
    final localT = scaled - index;
    return Color.lerp(paletteColors[index], paletteColors[next], localT) ??
        paletteColors[index];
  }

  int _pitchClassFromFrequency(double frequency) {
    final midi = (69 + 12 * (math.log(frequency / 440.0) / math.ln2)).round();
    return ((midi % 12) + 12) % 12;
  }

  String _noteName(int pitchClass) {
    const names = <String>[
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];
    return names[pitchClass];
  }

  Color _pitchColor(int pitchClass) {
    const pitchColors = <Color>[
      Color(0xFFEF4444),
      Color(0xFFF97316),
      Color(0xFFF59E0B),
      Color(0xFFEAB308),
      Color(0xFF84CC16),
      Color(0xFF22C55E),
      Color(0xFF14B8A6),
      Color(0xFF06B6D4),
      Color(0xFF3B82F6),
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
      Color(0xFFD946EF),
    ];
    return pitchColors[pitchClass.clamp(0, 11)];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final styleCurve = switch (pluckStyleId) {
      'warm' => 0.78,
      'crystal' => 1.18,
      'bright' => 1.05,
      'glass' => 1.24,
      'nylon' => 0.72,
      'concert' => 0.82,
      'steel' => 0.98,
      _ => 0.9,
    };
    final idleStroke = switch (pluckStyleId) {
      'warm' => 2.2,
      'crystal' => 1.75,
      'bright' => 1.95,
      'glass' => 1.62,
      'nylon' => 2.35,
      'concert' => 2.08,
      'steel' => 1.88,
      _ => 1.9,
    };

    final topGradient = Color.lerp(
      _paletteColorAt(0.05),
      const Color(0xFF041224),
      0.42,
    );
    final middleGradient = Color.lerp(
      _paletteColorAt(0.45),
      const Color(0xFF0B2A43),
      0.46,
    );
    final bottomGradient = Color.lerp(
      _paletteColorAt(0.95),
      const Color(0xFF0F172A),
      0.28,
    );
    final framePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          topGradient ?? const Color(0xFF0F172A),
          middleGradient ?? (topGradient ?? colorScheme.primary),
          bottomGradient ?? const Color(0xFF1E1B4B),
        ],
      ).createShader(Offset.zero & size);
    final borderPaint = Paint()
      ..color = colorScheme.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final frame = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(28),
    );
    canvas.drawRRect(frame, framePaint);
    canvas.drawRRect(frame, borderPaint);

    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              _paletteColorAt(0.5).withValues(alpha: 0.2),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.5, size.height * 0.42),
              radius: size.width * 0.42,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.42),
      size.width * 0.42,
      glowPaint,
    );
    final auroraPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          _paletteColorAt(0.12).withValues(alpha: 0.08),
          Colors.transparent,
          _paletteColorAt(0.86).withValues(alpha: 0.1),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, auroraPaint);

    final nowMicros = DateTime.now().microsecondsSinceEpoch;
    for (final trail in sweepTrails) {
      final ageT = ((nowMicros - trail.createdAtMicros) / 280000)
          .clamp(0.0, 1.0)
          .toDouble();
      if (ageT >= 1.0) {
        continue;
      }
      final fade = 1.0 - ageT;
      final trailColor = _paletteColorAt(
        (0.24 + trail.strength * 0.52).clamp(0.0, 1.0).toDouble(),
      );
      final radius = 10 + trail.strength * 16;
      final stretched = trail.velocity / math.max(1.0, trail.velocity.distance);
      final center = trail.position - stretched * (trail.strength * 6);
      final trailPaint = Paint()
        ..color = trailColor.withValues(alpha: 0.14 * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(center, radius * fade, trailPaint);
      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.18 * fade);
      canvas.drawCircle(center, math.max(1.5, radius * 0.18 * fade), corePaint);
    }

    final topY = size.height * 0.06;
    final bottomY = size.height * 0.94;
    final leftX = size.width * 0.06;
    final rightX = size.width * 0.94;
    final midY = (topY + bottomY) / 2;
    final midX = (leftX + rightX) / 2;
    final textScale = horizontalLayout
        ? (size.height / 520).clamp(0.72, 1.06)
        : (size.width / 420).clamp(0.72, 1.0);
    for (var index = 0; index < stringCount; index += 1) {
      final track = _stringTrackAt(index, size);
      final frequency = noteFrequencies[index % noteFrequencies.length];
      final pitchClass = _pitchClassFromFrequency(frequency);
      final noteColor = _pitchColor(pitchClass);
      final sway = (index < stringOffsets.length ? stringOffsets[index] : 0.0)
          .clamp(-22.0, 22.0)
          .toDouble();
      final activity = (sway.abs() / 22).clamp(0.0, 1.0).toDouble();
      final active = focusedString == index || activity > 0.04;
      final chordTone = chordStringIndexes.contains(index);
      final harmonyAlpha = chordTone || active ? 1.0 : 0.42;
      final paletteColor = _paletteColorAt(index / (stringCount - 1));
      final baseColor = Color.lerp(noteColor, paletteColor, 0.22) ?? noteColor;
      final idleColor =
          Color.lerp(
            baseColor.withValues(alpha: 0.92 * harmonyAlpha),
            Colors.white,
            chordTone ? 0.48 : 0.32,
          ) ??
          baseColor.withValues(alpha: 0.92 * harmonyAlpha);
      final strokeColor = Color.lerp(
        idleColor,
        Colors.white,
        active ? (0.52 + activity * 0.48).clamp(0.0, 1.0) : 0.0,
      );
      final skeletonPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.26 * harmonyAlpha)
        ..strokeWidth = math.max(1.35, idleStroke - 0.72)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final basePaint = Paint()
        ..color = baseColor.withValues(alpha: 0.86 * harmonyAlpha)
        ..strokeWidth = math.max(1.5, idleStroke - 0.42)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final basePath = horizontalLayout
          ? (Path()
              ..moveTo(leftX, track)
              ..quadraticBezierTo(midX, track, rightX, track))
          : (Path()
              ..moveTo(track, topY)
              ..quadraticBezierTo(track, midY, track, bottomY));
      canvas.drawPath(basePath, skeletonPaint);
      canvas.drawPath(basePath, basePaint);
      final paint = Paint()
        ..color = strokeColor ?? colorScheme.primary
        ..strokeWidth = active || chordTone
            ? idleStroke + (active ? 1.2 + activity * 0.95 : 0.28)
            : idleStroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (active) {
        final underGlow = Paint()
          ..color = baseColor.withValues(alpha: 0.2)
          ..strokeWidth = 5.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawPath(basePath, underGlow);

        final glow = Paint()
          ..color = (strokeColor ?? colorScheme.primary).withValues(alpha: 0.28)
          ..strokeWidth = 7
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        final glowPath = horizontalLayout
            ? (Path()
                ..moveTo(leftX, track)
                ..quadraticBezierTo(
                  midX,
                  track + sway * styleCurve,
                  rightX,
                  track,
                ))
            : (Path()
                ..moveTo(track, topY)
                ..quadraticBezierTo(
                  track + sway * styleCurve,
                  midY,
                  track,
                  bottomY,
                ));
        canvas.drawPath(glowPath, glow);
      }

      final path = horizontalLayout
          ? (Path()
              ..moveTo(leftX, track)
              ..quadraticBezierTo(
                midX,
                track + sway * styleCurve,
                rightX,
                track,
              ))
          : (Path()
              ..moveTo(track, topY)
              ..quadraticBezierTo(
                track + sway * styleCurve,
                midY,
                track,
                bottomY,
              ));
      canvas.drawPath(path, paint);

      final anchorPaint = Paint()
        ..color = (strokeColor ?? colorScheme.primary).withValues(
          alpha: chordTone ? 0.9 : 0.75 * harmonyAlpha,
        );
      if (horizontalLayout) {
        canvas.drawCircle(Offset(leftX, track), 2.5, anchorPaint);
        canvas.drawCircle(Offset(rightX, track), 2.2, anchorPaint);
      } else {
        canvas.drawCircle(Offset(track, topY), 2.5, anchorPaint);
        canvas.drawCircle(Offset(track, bottomY), 2.2, anchorPaint);
      }

      if (chordTone) {
        final runePaint = Paint()
          ..color = (strokeColor ?? colorScheme.primary).withValues(alpha: 0.32)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        final runeA = horizontalLayout
            ? Offset(leftX, track)
            : Offset(track, topY);
        final runeB = horizontalLayout
            ? Offset(rightX, track)
            : Offset(track, bottomY);
        canvas.drawCircle(runeA, 6.2, runePaint);
        canvas.drawCircle(runeB, 5.2, runePaint);
      }

      final activeDot = Paint()
        ..color = baseColor.withValues(
          alpha: active
              ? 0.96
              : chordTone
              ? 0.72
              : 0.5 * harmonyAlpha,
        );
      final activeDotOffset = horizontalLayout
          ? Offset(rightX, track)
          : Offset(track, bottomY);
      canvas.drawCircle(activeDotOffset, active ? 3.4 : 2.4, activeDot);

      final labelPainter = TextPainter(
        text: TextSpan(
          text: _noteName(pitchClass),
          style: TextStyle(
            color: (strokeColor ?? noteColor).withValues(
              alpha: chordTone ? 0.96 : 0.9 * harmonyAlpha,
            ),
            fontSize: 9.5 * textScale,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final rawLabelOffset = horizontalLayout
          ? Offset(
              leftX - labelPainter.width - 8,
              track - labelPainter.height / 2,
            )
          : Offset(track - labelPainter.width / 2, topY - 16 * textScale);
      final labelOffset = Offset(
        rawLabelOffset.dx
            .clamp(4.0, size.width - labelPainter.width - 4.0)
            .toDouble(),
        rawLabelOffset.dy
            .clamp(4.0, size.height - labelPainter.height - 4.0)
            .toDouble(),
      );
      const labelPadX = 3.0;
      const labelPadY = 1.5;
      final labelBg = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          labelOffset.dx - labelPadX,
          labelOffset.dy - labelPadY,
          labelPainter.width + labelPadX * 2,
          labelPainter.height + labelPadY * 2,
        ),
        const Radius.circular(5),
      );
      canvas.drawRRect(
        labelBg,
        Paint()..color = Colors.black.withValues(alpha: chordTone ? 0.38 : 0.3),
      );
      labelPainter.paint(canvas, labelOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _HarpPainter oldDelegate) {
    return true;
  }
}

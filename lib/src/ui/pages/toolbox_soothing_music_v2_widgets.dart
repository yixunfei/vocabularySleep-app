part of 'toolbox_soothing_music_v2_page.dart';

class _CompactCurrentModeCard extends StatelessWidget {
  const _CompactCurrentModeCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.palette,
    this.dropdownEnabled = false,
    this.showFavoriteButton = true,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final _SoothingVisualPalette palette;
  final bool dropdownEnabled;
  final bool showFavoriteButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.panelSurfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.14),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          if (showFavoriteButton)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onToggleFavorite,
              icon: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 18,
                color: isFavorite ? accent : palette.textSecondary,
              ),
            ),
          if (dropdownEnabled)
            Padding(
              padding: EdgeInsets.only(left: showFavoriteButton ? 2 : 0),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: palette.accent,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeFilterChip extends StatelessWidget {
  const _ModeFilterChip({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final _SoothingVisualPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.quick,
          curve: AppEasing.snappy,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                selected
                    ? palette.accent.withValues(
                        alpha: palette.isDark ? 0.22 : 0.14,
                      )
                    : palette.panelSurfaceMuted,
                selected
                    ? palette.orbitAccent.withValues(
                        alpha: palette.isDark ? 0.12 : 0.08,
                      )
                    : palette.panelSurfaceMuted.withValues(alpha: 0.92),
              ],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? palette.accent.withValues(alpha: 0.76)
                  : palette.border,
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: palette.accent.withValues(
                        alpha: palette.isDark ? 0.16 : 0.08,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? palette.accent : palette.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackPill extends StatelessWidget {
  const _TrackPill({
    required this.label,
    required this.selected,
    required this.palette,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final _SoothingVisualPalette palette;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.standard,
          curve: AppEasing.standard,
          constraints: BoxConstraints(
            minHeight: 38,
            maxWidth: compact ? 176 : 240,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                selected
                    ? palette.accent.withValues(
                        alpha: palette.isDark ? 0.2 : 0.14,
                      )
                    : palette.panelSurfaceMuted,
                selected
                    ? palette.orbitAccent.withValues(
                        alpha: palette.isDark ? 0.08 : 0.06,
                      )
                    : palette.panelSurfaceMuted.withValues(alpha: 0.92),
              ],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? palette.accent.withValues(alpha: 0.76)
                  : palette.border,
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: palette.accent.withValues(
                        alpha: palette.isDark ? 0.18 : 0.1,
                      ),
                      blurRadius: 18,
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (selected) ...<Widget>[
                Icon(Icons.graphic_eq_rounded, size: 16, color: palette.accent),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? palette.accent : palette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.palette,
    this.dense = false,
    this.accent,
  });

  final IconData icon;
  final String label;
  final _SoothingVisualPalette palette;
  final bool dense;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final resolvedAccent = accent ?? palette.orbitAccent;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 12,
        vertical: dense ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: palette.panelSurfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border.withValues(alpha: 0.82)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: dense ? 13 : 14, color: resolvedAccent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent == null
                    ? palette.textSecondary
                    : Color.lerp(resolvedAccent, palette.textPrimary, 0.3),
                fontSize: dense ? 11 : 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransportIconButton extends StatelessWidget {
  const _TransportIconButton({
    required this.tooltip,
    required this.icon,
    required this.palette,
    required this.compact,
    this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final _SoothingVisualPalette palette;
  final bool compact;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.quick,
      curve: AppEasing.snappy,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            palette.panelSurfaceMuted,
            palette.panelSurface.withValues(
              alpha: palette.isDark ? 0.92 : 0.98,
            ),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: palette.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.accent.withValues(
              alpha: palette.isDark ? 0.12 : 0.06,
            ),
            blurRadius: compact ? 10 : 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        iconSize: compact ? 20 : 24,
        padding: EdgeInsets.all(compact ? 8 : 12),
        constraints: BoxConstraints.tightFor(
          width: compact ? 36 : 44,
          height: compact ? 36 : 44,
        ),
        icon: Icon(icon, color: palette.textPrimary),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.animation,
    required this.color,
    required this.size,
    required this.seed,
    required this.drift,
  });

  final Animation<double> animation;
  final Color color;
  final double size;
  final double seed;
  final double drift;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final phase = animation.value * math.pi * 2;
        final dx = math.sin(phase * 0.82 + seed) * drift;
        final dy = math.cos(phase * 0.58 + seed * 1.3) * drift * 0.56;
        final scale = 0.96 + math.sin(phase * 0.46 + seed * 0.7) * 0.05;
        final rotation = math.pi / 10 + math.sin(phase * 0.34 + seed) * 0.11;
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(
            angle: rotation,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.42),
          gradient: RadialGradient(
            center: const Alignment(-0.18, -0.24),
            radius: 0.72,
            colors: <Color>[
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0.04),
              Colors.transparent,
            ],
            stops: const <double>[0.0, 0.34, 0.72, 1.0],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withValues(alpha: 0.22),
              blurRadius: size * 0.36,
              spreadRadius: size * 0.06,
            ),
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: size * 0.18,
              spreadRadius: size * 0.02,
              offset: Offset(size * 0.04, size * 0.06),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoothingSpectrumPainter extends CustomPainter {
  _SoothingSpectrumPainter({
    required this.accent,
    required this.orbitAccent,
    required this.orbit,
    required this.phaseOffset,
    required this.bands,
    required this.barGain,
    required this.particleGain,
    required this.breathingGain,
    required this.rippleGain,
    required this.waveGain,
    required this.compact,
    required this.isDark,
    required this.animate,
    this.fullscreen = false,
  }) : super(repaint: orbit);

  final Color accent;
  final Color orbitAccent;
  final Animation<double> orbit;
  final double phaseOffset;
  final List<double> bands;
  final double barGain;
  final double particleGain;
  final double breathingGain;
  final double rippleGain;
  final double waveGain;
  final bool compact;
  final bool isDark;
  final bool fullscreen;
  final bool animate;

  @override
  void paint(Canvas canvas, Size size) {
    final phase =
        (animate ? orbit.value : orbit.value.roundToDouble()) * math.pi * 2 +
        phaseOffset;
    final center = size.center(Offset.zero);
    final shortest = math.min(size.width, size.height);
    final compactBoost = compact ? 1.38 : 1.0;
    final fullscreenBoost = fullscreen ? 1.22 : 1.0;
    final innerRadius =
        shortest *
        (compact
            ? 0.19
            : fullscreen
            ? 0.19
            : 0.14);
    final expandedBands = _expandBands(bands, 24);
    final energy =
        bands.fold<double>(0, (sum, item) => sum + item) / bands.length;
    final visibleEnergy = compact ? math.max(energy, 0.24) : energy;

    _drawWaveRibbon(
      canvas,
      size,
      center,
      color: accent.withValues(alpha: isDark ? 0.34 : 0.24),
      phase: phase,
      amplitude: shortest * 0.052 * waveGain * fullscreenBoost * compactBoost,
      verticalOffset: -shortest * 0.06,
      direction: 1,
    );
    _drawWaveRibbon(
      canvas,
      size,
      center,
      color: orbitAccent.withValues(alpha: isDark ? 0.28 : 0.2),
      phase: phase + 1.6,
      amplitude: shortest * 0.042 * waveGain * fullscreenBoost * compactBoost,
      verticalOffset: shortest * 0.08,
      direction: -1,
    );

    for (var ring = 0; ring < (fullscreen ? 6 : 4); ring += 1) {
      final progress = ((phase / (math.pi * 2)) + ring * 0.32) % 1;
      final radius =
          innerRadius * (1.04 + progress * (1.75 + rippleGain * 0.18));
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = accent.withValues(
            alpha: (1 - progress) * (isDark ? 0.18 : 0.14) * rippleGain,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = fullscreen
              ? 3.2
              : compact
              ? 2.0
              : 2.8,
      );
    }

    for (
      var i = 0;
      i <
          (fullscreen
                  ? 26 + particleGain * 48 * compactBoost
                  : 16 + particleGain * 34 * compactBoost)
              .round();
      i += 1
    ) {
      final drift = phase + i * 0.47;
      final radius = innerRadius * (2.22 + (i % 6) * 0.22) * compactBoost;
      final point = Offset(
        center.dx + math.cos(drift) * radius,
        center.dy + math.sin(drift * 1.14) * radius * 0.72,
      );
      canvas.drawCircle(
        point,
        1.6 + (i % 3) * (fullscreen ? 1.2 : 0.9),
        Paint()
          ..color = orbitAccent.withValues(
            alpha: (0.14 + (i % 5) * 0.04).clamp(0.14, 0.42),
          ),
      );
    }

    for (
      var i = 0;
      i <
          (fullscreen ? 18 + particleGain * 30 : 10 + particleGain * 20)
              .round();
      i += 1
    ) {
      final drift = phase * 1.24 + i * 1.34;
      final radius =
          innerRadius * (0.72 + (i % 4) * 0.18 + math.sin(drift) * 0.08);
      final point = Offset(
        center.dx + math.cos(drift) * radius,
        center.dy + math.sin(drift * 0.9) * radius,
      );
      canvas.drawCircle(
        point,
        2.0 + (i % 2) * (fullscreen ? 1.2 : 0.8),
        Paint()..color = accent.withValues(alpha: isDark ? 0.34 : 0.24),
      );
    }

    final barPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader =
          LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: <Color>[
              accent.withValues(alpha: 0.88),
              orbitAccent.withValues(alpha: 0.96),
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: innerRadius * 2.8),
          );
    for (var i = 0; i < expandedBands.length; i += 1) {
      final angle = -math.pi / 2 + (math.pi * 2 * i / expandedBands.length);
      final amplitude = expandedBands[i];
      final visualAmplitude = compact
          ? (0.2 + amplitude * 0.9).clamp(0.2, 1.0)
          : amplitude;
      final pulse =
          0.84 +
          0.38 * math.sin(phase * 1.8 + i * 0.42 + visualAmplitude * 3.2);
      final length =
          (24 + visualAmplitude * shortest * 0.1 * barGain * compactBoost)
              .toDouble() *
          pulse.clamp(0.72, 1.28);
      final barWidth = compact ? 4.2 + barGain * 1.6 : 3.4 + barGain * 1.4;
      final barCenter = Offset(
        center.dx + math.cos(angle) * (innerRadius * 2.08 + length * 0.5),
        center.dy + math.sin(angle) * (innerRadius * 2.08 + length * 0.5),
      );
      canvas.save();
      canvas.translate(barCenter.dx, barCenter.dy);
      canvas.rotate(angle + math.pi / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: barWidth, height: length),
          Radius.circular(barWidth),
        ),
        barPaint,
      );
      canvas.restore();
    }

    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              Colors.white.withValues(alpha: 0.26 + energy * 0.1),
              accent.withValues(alpha: 0.2 + energy * 0.16),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: innerRadius * 2.2),
          );
    canvas.drawCircle(
      center,
      innerRadius * (fullscreen ? 2.05 : 1.8),
      glowPaint,
    );

    for (var ring = 0; ring < 5; ring += 1) {
      final breath =
          1 +
          math.sin(phase * (0.7 + ring * 0.1) + ring) * 0.035 * breathingGain;
      final radius = innerRadius * (1.68 + ring * 0.35) * breath;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = accent.withValues(
            alpha:
                (compact ? 0.04 : 0.028) *
                (5 - ring) *
                (0.9 + visibleEnergy * 0.4),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16,
      );
    }

    _drawSpectrumOrbit(
      canvas,
      center,
      baseRadius: innerRadius * 2.45,
      phase: phase,
      color: accent.withValues(alpha: 0.98),
      bands: bands,
      direction: 1,
    );
    _drawSpectrumOrbit(
      canvas,
      center,
      baseRadius: innerRadius * 2.72,
      phase: phase + 1.4,
      color: orbitAccent.withValues(alpha: 0.94),
      bands: bands,
      direction: -1,
      reverseBands: true,
    );
  }

  List<double> _expandBands(List<double> source, int count) {
    if (source.isEmpty) return List<double>.filled(count, 0.2);
    return List<double>.generate(count, (index) {
      final position = index * (source.length - 1) / math.max(1, count - 1);
      final lower = position.floor().clamp(0, source.length - 1);
      final upper = position.ceil().clamp(0, source.length - 1);
      if (lower == upper) return source[lower];
      final t = position - lower;
      return source[lower] * (1 - t) + source[upper] * t;
    }, growable: false);
  }

  void _drawWaveRibbon(
    Canvas canvas,
    Size size,
    Offset center, {
    required Color color,
    required double phase,
    required double amplitude,
    required double verticalOffset,
    required double direction,
  }) {
    final path = Path();
    final left = size.width * 0.1;
    final right = size.width * 0.9;
    const steps = 84;
    for (var i = 0; i <= steps; i += 1) {
      final t = i / steps;
      final x = left + (right - left) * t;
      final waveA = math.sin(t * math.pi * 4 + phase * direction);
      final waveB = math.cos(t * math.pi * 7 - phase * 0.36);
      final y =
          center.dy +
          verticalOffset +
          waveA * amplitude * 0.72 +
          waveB * amplitude * 0.38;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 3.4 : 3.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(path, paint);
  }

  void _drawSpectrumOrbit(
    Canvas canvas,
    Offset center, {
    required double baseRadius,
    required double phase,
    required Color color,
    required List<double> bands,
    required double direction,
    bool reverseBands = false,
  }) {
    final path = Path();
    const steps = 240;
    for (var i = 0; i <= steps; i += 1) {
      final t = i / steps;
      final angle = t * math.pi * 2;
      final bandIndex = ((t * bands.length).floor()).clamp(0, bands.length - 1);
      final sourceIndex = reverseBands
          ? bands.length - 1 - bandIndex
          : bandIndex;
      final band = bands[sourceIndex];
      final modulation =
          math.sin(angle * 4 + phase * direction) * (0.08 + band * 0.1) +
          math.cos(angle * 7 - phase * 0.35) * (0.03 + band * 0.05);
      final currentRadius = baseRadius * (1 + modulation);
      final point = Offset(
        center.dx + math.cos(angle) * currentRadius,
        center.dy + math.sin(angle) * currentRadius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 5.2 : 4.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SoothingSpectrumPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.orbitAccent != orbitAccent ||
        !identical(oldDelegate.bands, bands) ||
        oldDelegate.barGain != barGain ||
        oldDelegate.particleGain != particleGain ||
        oldDelegate.breathingGain != breathingGain ||
        oldDelegate.rippleGain != rippleGain ||
        oldDelegate.waveGain != waveGain ||
        oldDelegate.compact != compact ||
        oldDelegate.isDark != isDark ||
        oldDelegate.fullscreen != fullscreen ||
        oldDelegate.animate != animate ||
        oldDelegate.phaseOffset != phaseOffset;
  }
}

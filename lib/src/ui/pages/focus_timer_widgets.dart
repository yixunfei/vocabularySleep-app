import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../../models/tomato_timer.dart';
import '../../services/focus_service.dart';
import '../layout/app_width_tier.dart';
import '../ui_copy.dart';

class FocusTimerDisplayCard extends StatelessWidget {
  const FocusTimerDisplayCard({
    super.key,
    required this.timerState,
    required this.config,
    required this.i18n,
    required this.widthTier,
    required this.timerStyle,
    required this.lastCompletedPhase,
  });

  final TomatoTimerState timerState;
  final TomatoTimerConfig config;
  final AppI18n i18n;
  final AppWidthTier widthTier;
  final String timerStyle;
  final TomatoTimerPhase? lastCompletedPhase;

  @override
  Widget build(BuildContext context) {
    final phaseText = switch (timerState.phase) {
      TomatoTimerPhase.idle => i18n.t('timerIdle'),
      TomatoTimerPhase.focus => i18n.t('focusPhase'),
      TomatoTimerPhase.breakTime => i18n.t('breakPhase'),
      TomatoTimerPhase.breakReady => i18n.t('breakReady'),
      TomatoTimerPhase.focusReady => i18n.t('focusReady'),
    };
    final indicatorSize = switch (widthTier) {
      AppWidthTier.compact => 188.0,
      AppWidthTier.expanded => 256.0,
      AppWidthTier.regular => 220.0,
    };
    final helperText = timerState.isAwaitingManualTransition
        ? i18n.t('timerWaitingAction')
        : null;
    final theme = Theme.of(context);
    final alertActive = lastCompletedPhase != null;
    final accent = alertActive
        ? (lastCompletedPhase == TomatoTimerPhase.focus
              ? theme.colorScheme.tertiary
              : theme.colorScheme.secondary)
        : theme.colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      decoration: BoxDecoration(
        color: alertActive
            ? accent.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: alertActive
              ? accent.withValues(alpha: 0.38)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Text(phaseText, style: theme.textTheme.titleLarge),
            if (helperText != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                helperText,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 18),
            _FocusTimerVisual(
              timerState: timerState,
              i18n: i18n,
              timerStyle: timerStyle,
              accent: accent,
              size: indicatorSize,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: <Widget>[
                Chip(
                  avatar: const Icon(Icons.repeat_rounded, size: 18),
                  label: Text(
                    i18n.t(
                      'roundProgress',
                      params: <String, Object?>{
                        'current': timerState.currentRound,
                        'total': config.rounds,
                      },
                    ),
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.schedule_rounded, size: 18),
                  label: Text(
                    '${_formatTimeSummary(timerState.totalSeconds, i18n)} · ${_formatPercent(timerState.remainingProgress)}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FocusTimerControlsCard extends StatelessWidget {
  const FocusTimerControlsCard({
    super.key,
    required this.focus,
    required this.timerState,
    required this.i18n,
    required this.onConfirmStop,
  });

  final FocusService focus;
  final TomatoTimerState timerState;
  final AppI18n i18n;
  final VoidCallback onConfirmStop;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];

    if (timerState.phase == TomatoTimerPhase.idle) {
      buttons.add(
        FilledButton.icon(
          onPressed: focus.start,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(i18n.t('start')),
        ),
      );
    } else {
      buttons.add(
        FilledButton.icon(
          onPressed: focus.pauseOrResume,
          icon: Icon(
            timerState.isPaused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
          ),
          label: Text(timerState.isPaused ? i18n.t('resume') : i18n.t('pause')),
        ),
      );
      buttons.add(
        FilledButton.tonalIcon(
          onPressed: timerState.isAwaitingManualTransition
              ? focus.advanceToNextPhase
              : focus.skip,
          icon: const Icon(Icons.skip_next_rounded),
          label: Text(
            timerState.isAwaitingManualTransition
                ? i18n.t('continue')
                : i18n.t('skip'),
          ),
        ),
      );
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => focus.setLockScreenActive(!focus.lockScreenActive),
          icon: Icon(
            focus.lockScreenActive
                ? Icons.lock_open_rounded
                : Icons.lock_rounded,
          ),
          label: Text(
            focus.lockScreenActive
                ? pickUiText(i18n, zh: '解除锁定', en: 'Unlock focus')
                : pickUiText(i18n, zh: '锁定专注', en: 'Lock focus'),
          ),
        ),
      );
      buttons.add(
        OutlinedButton.icon(
          onPressed: onConfirmStop,
          icon: const Icon(Icons.stop_rounded),
          label: Text(i18n.t('stop')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              pickUiText(i18n, zh: '当前操作', en: 'Current actions'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              pickUiText(
                i18n,
                zh: '保持当前专注节奏，下一步操作会在这里集中显示。',
                en: 'Keep the current focus flow moving with the next actions collected here.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final isSingleColumn = availableWidth < 460;
                final buttonWidth = isSingleColumn
                    ? availableWidth
                    : ((availableWidth - 12) / 2).clamp(180.0, availableWidth);

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: buttons
                      .map(
                        (button) => SizedBox(width: buttonWidth, child: button),
                      )
                      .toList(growable: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusTimerVisual extends StatelessWidget {
  const _FocusTimerVisual({
    required this.timerState,
    required this.i18n,
    required this.timerStyle,
    required this.accent,
    required this.size,
  });

  final TomatoTimerState timerState;
  final AppI18n i18n;
  final String timerStyle;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return switch (timerStyle) {
      'hourglass' => _buildHourglassVisual(context),
      _ => _buildCountdownVisual(context),
    };
  }

  Widget _buildCountdownVisual(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          RepaintBoundary(
            child: CustomPaint(
              size: Size.square(size),
              painter: _CountdownRingPainter(
                remaining: timerState.remainingProgress,
                pulse: timerState.phase == TomatoTimerPhase.focus ? 1 : 0.7,
                accent: accent,
                track: theme.colorScheme.outlineVariant,
                surface: theme.colorScheme.surface,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _formatTime(timerState.remainingSeconds),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(i18n.t('timerTab'), style: theme.textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHourglassVisual(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          RepaintBoundary(
            child: CustomPaint(
              size: Size.square(size),
              painter: _HourglassPainter(
                remaining: timerState.remainingProgress,
                pulse: timerState.phase == TomatoTimerPhase.focus ? 1 : 0.7,
                accent: accent,
                track: theme.colorScheme.outlineVariant,
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.12,
            child: Column(
              children: <Widget>[
                Text(
                  _formatTime(timerState.remainingSeconds),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(i18n.t('timerTab'), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTime(int seconds) {
  final duration = Duration(seconds: seconds.clamp(0, 359999));
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final secs = duration.inSeconds.remainder(60);
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}

String _formatTimeSummary(int seconds, AppI18n i18n) {
  final duration = Duration(seconds: seconds.clamp(0, 359999));
  final parts = <String>[];
  if (duration.inHours > 0) {
    parts.add('${duration.inHours}${i18n.t('hoursUnit')}');
  }
  final minutes = duration.inMinutes.remainder(60);
  if (minutes > 0 || parts.isNotEmpty) {
    parts.add('$minutes${i18n.t('minutesUnit')}');
  }
  parts.add('${duration.inSeconds.remainder(60)}${i18n.t('secondsUnit')}');
  return parts.join(' ');
}

String _formatPercent(double value) {
  return '${(value.clamp(0.0, 1.0) * 100).round()}%';
}

class _CountdownRingPainter extends CustomPainter {
  const _CountdownRingPainter({
    required this.remaining,
    required this.pulse,
    required this.accent,
    required this.track,
    required this.surface,
  });

  final double remaining;
  final double pulse;
  final Color accent;
  final Color track;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final stroke = size.shortestSide * 0.08;
    final radius = size.shortestSide / 2 - stroke;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final clampedRemaining = remaining.clamp(0.0, 1.0).toDouble();
    final sweep = math.pi * 2 * clampedRemaining;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: <Color>[
          accent.withValues(alpha: 0.34),
          accent,
          accent.withValues(alpha: 0.72),
        ],
      ).createShader(rect);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
      ..color = accent.withValues(alpha: 0.16 + pulse * 0.18);

    if (clampedRemaining > 0) {
      canvas.drawArc(rect, -math.pi / 2, sweep, false, glowPaint);
      canvas.drawArc(rect, -math.pi / 2, sweep, false, ringPaint);
    }

    final fillPaint = Paint()..color = surface.withValues(alpha: 0.58);
    canvas.drawCircle(center, radius - stroke * 0.9, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) {
    return oldDelegate.remaining != remaining ||
        oldDelegate.pulse != pulse ||
        oldDelegate.accent != accent ||
        oldDelegate.track != track ||
        oldDelegate.surface != surface;
  }
}

class _HourglassPainter extends CustomPainter {
  const _HourglassPainter({
    required this.remaining,
    required this.pulse,
    required this.accent,
    required this.track,
  });

  final double remaining;
  final double pulse;
  final Color accent;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final clampedRemaining = remaining.clamp(0.0, 1.0).toDouble();
    final sandPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = accent.withValues(alpha: 0.90);
    final glassPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = track.withValues(alpha: 0.54);
    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = accent.withValues(alpha: 0.92);
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
      ..color = accent.withValues(alpha: 0.14 + pulse * 0.12);

    final topChamber = Path()
      ..moveTo(width * 0.28, height * 0.18)
      ..lineTo(width * 0.72, height * 0.18)
      ..lineTo(width * 0.50, height * 0.47)
      ..close();
    final bottomChamber = Path()
      ..moveTo(width * 0.50, height * 0.53)
      ..lineTo(width * 0.72, height * 0.82)
      ..lineTo(width * 0.28, height * 0.82)
      ..close();

    canvas.drawPath(topChamber, glassPaint);
    canvas.drawPath(bottomChamber, glassPaint);
    canvas.drawPath(topChamber, glowPaint);
    canvas.drawPath(bottomChamber, glowPaint);
    canvas.drawPath(topChamber, framePaint);
    canvas.drawPath(bottomChamber, framePaint);

    final topFillHeight = height * 0.29 * clampedRemaining;
    canvas.save();
    canvas.clipPath(topChamber);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          width * 0.24,
          height * 0.48 - topFillHeight,
          width * 0.52,
          topFillHeight + 4,
        ),
        Radius.circular(width * 0.04),
      ),
      sandPaint,
    );
    canvas.restore();

    final bottomFillHeight = height * 0.29 * (1 - clampedRemaining);
    canvas.save();
    canvas.clipPath(bottomChamber);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          width * 0.24,
          height * 0.82 - bottomFillHeight,
          width * 0.52,
          bottomFillHeight,
        ),
        Radius.circular(width * 0.04),
      ),
      sandPaint,
    );
    canvas.restore();

    final streamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.018
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.8);
    canvas.drawLine(
      Offset(width * 0.50, height * 0.47),
      Offset(width * 0.50, height * (0.52 + (1 - clampedRemaining) * 0.12)),
      streamPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HourglassPainter oldDelegate) {
    return oldDelegate.remaining != remaining ||
        oldDelegate.pulse != pulse ||
        oldDelegate.accent != accent ||
        oldDelegate.track != track;
  }
}

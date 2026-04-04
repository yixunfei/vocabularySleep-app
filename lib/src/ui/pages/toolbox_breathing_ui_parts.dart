import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../../services/toolbox_breathing_catalog.dart';
import '../ui_copy.dart';

class VoiceStatusPill extends StatelessWidget {
  const VoiceStatusPill({
    super.key,
    required this.label,
    required this.subtitle,
    this.icon,
    this.iconColor,
  });

  final String label;
  final String subtitle;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          if (icon != null)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? Theme.of(context).colorScheme.primary)
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: iconColor),
            ),
          if (icon != null) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScenarioTagChip extends StatelessWidget {
  const ScenarioTagChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class BreathingMetricPill extends StatelessWidget {
  const BreathingMetricPill({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class BreathingInsightTile extends StatelessWidget {
  const BreathingInsightTile({
    super.key,
    required this.title,
    required this.body,
    required this.icon,
    required this.tint,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tint.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: tint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(body),
        ],
      ),
    );
  }
}

class BreathingStageTimeline extends StatelessWidget {
  const BreathingStageTimeline({
    super.key,
    required this.stages,
    required this.activeIndex,
    required this.i18n,
    required this.stageTintBuilder,
  });

  final List<BreathingStagePlan> stages;
  final int activeIndex;
  final AppI18n i18n;
  final Color Function(BreathingStageKind kind) stageTintBuilder;

  Widget _buildSegment(
    BuildContext context,
    BreathingStagePlan stage,
    int index, {
    double? width,
  }) {
    final active = index == activeIndex;
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: active
            ? stageTintBuilder(stage.kind).withValues(alpha: 0.28)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? stageTintBuilder(stage.kind)
              : Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            stage.label.resolve(i18n),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${stage.seconds}${pickUiText(i18n, zh: '秒', en: 's')}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
    return Padding(
      padding: EdgeInsets.only(right: index == stages.length - 1 ? 0 : 6),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const minCompactWidth = 72.0;
        final needsScroll =
            constraints.maxWidth <
            stages.length * minCompactWidth + 6 * stages.length;
        if (needsScroll) {
          final wrappedWidth = math.max(
            92.0,
            math.min(168.0, (constraints.maxWidth - 6) / 2),
          );
          return Wrap(
            runSpacing: 6,
            children: stages
                .asMap()
                .entries
                .map(
                  (entry) => _buildSegment(
                    context,
                    entry.value,
                    entry.key,
                    width: wrappedWidth,
                  ),
                )
                .toList(growable: false),
          );
        }
        return Row(
          children: stages
              .asMap()
              .entries
              .map(
                (entry) => Expanded(
                  flex: math.max(1, entry.value.seconds),
                  child: _buildSegment(context, entry.value, entry.key),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class SafetyNoteCard extends StatelessWidget {
  const SafetyNoteCard({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(body),
        ],
      ),
    );
  }
}

class SessionSummaryCard extends StatelessWidget {
  const SessionSummaryCard({
    super.key,
    required this.title,
    required this.body,
    required this.nextStep,
  });

  final String title;
  final String body;
  final String nextStep;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(body),
          const SizedBox(height: 8),
          Text(
            nextStep,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class BreathingAuraPainter extends CustomPainter {
  const BreathingAuraPainter({
    required this.progress,
    required this.stageKind,
    required this.color,
    required this.secondary,
  });

  final double progress;
  final BreathingStageKind stageKind;
  final Color color;
  final Color secondary;

  double _strength() {
    return switch (stageKind) {
      BreathingStageKind.inhale =>
        0.74 + Curves.easeOut.transform(progress) * 0.34,
      BreathingStageKind.hold => 1.08,
      BreathingStageKind.exhale =>
        1.08 - Curves.easeIn.transform(progress) * 0.34,
      BreathingStageKind.rest => 0.74,
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = size.shortestSide * 0.23;
    final strength = _strength();

    for (var i = 0; i < 4; i += 1) {
      final radius = base * (1.3 + i * 0.3) * strength;
      final alpha = (0.32 - i * 0.06).clamp(0.06, 0.32).toDouble();
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 + i * 0.55,
      );
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: base * 2.1),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = secondary.withValues(alpha: 0.88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    for (var index = 0; index < 3; index += 1) {
      final path = Path();
      final waveRadius = base * (1.55 + index * 0.18) * strength;
      final amplitude = 8 + index * 5;
      for (var angle = 0.0; angle <= math.pi * 2 + 0.1; angle += 0.12) {
        final wave = math.sin(angle * 2 + progress * math.pi * 2 + index);
        final radius = waveRadius + wave * amplitude;
        final point = Offset(
          center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius,
        );
        if (angle == 0.0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = secondary.withValues(alpha: 0.05 + index * 0.025)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BreathingAuraPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.stageKind != stageKind ||
        oldDelegate.color != color ||
        oldDelegate.secondary != secondary;
  }
}

part of 'toolbox_human_tests.dart';

class _AimSettingSlider extends StatelessWidget {
  const _AimSettingSlider({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$label · $valueText',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: valueText,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _AimSettingSwitch extends StatelessWidget {
  const _AimSettingSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
    );
  }
}

class _AimTargetMarker extends StatelessWidget {
  const _AimTargetMarker({
    super.key,
    required this.accent,
    required this.decoy,
    required this.progress,
    required this.simplePoint,
  });

  final Color accent;
  final bool decoy;
  final double progress;
  final bool simplePoint;

  @override
  Widget build(BuildContext context) {
    if (simplePoint) {
      final pulse = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));
      return DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withValues(alpha: 0.18 + pulse * 0.62),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: accent.withValues(alpha: 0.18 * pulse),
              blurRadius: 2 + pulse * 8,
            ),
          ],
        ),
      );
    }

    final ringOpacity = decoy ? 0.12 : 0.18 + progress * 0.16;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: ringOpacity),
        border: Border.all(
          color: accent.withValues(alpha: decoy ? 0.82 : 1),
          width: decoy ? 2 : 3,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withValues(alpha: decoy ? 0.10 : 0.24),
            blurRadius: decoy ? 10 : 18,
            spreadRadius: decoy ? 0 : 1,
          ),
        ],
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: decoy ? 0.36 : 0.30,
          heightFactor: decoy ? 0.36 : 0.30,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: decoy ? Colors.transparent : accent,
              border: decoy ? Border.all(color: accent, width: 2) : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _AimFeedbackPanel extends StatelessWidget {
  const _AimFeedbackPanel({
    required this.accent,
    required this.text,
    required this.running,
  });

  final Color accent;
  final String text;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: colorScheme.surface.withValues(alpha: running ? 0.82 : 0.92),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            running ? Icons.center_focus_strong_rounded : Icons.info_rounded,
            color: accent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _AimSniperFailureOverlay extends StatelessWidget {
  const _AimSniperFailureOverlay({
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onDismiss,
  });

  final Color accent;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final pulse = math.sin(value * math.pi * 5).abs();
          return DecoratedBox(
            decoration: BoxDecoration(
              color: Color.lerp(
                const Color(0xFF7A1018).withValues(alpha: 0.82),
                const Color(0xFFFF3B30).withValues(alpha: 0.90),
                pulse,
              ),
            ),
            child: child,
          );
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: theme.colorScheme.surface.withValues(alpha: 0.94),
                border: Border.all(color: Colors.white.withValues(alpha: 0.46)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Icon(Icons.gps_fixed_rounded, color: accent, size: 42),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.shield_rounded),
                    label: Text(actionLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AimCompletionReportDialog extends StatelessWidget {
  const _AimCompletionReportDialog({
    required this.accent,
    required this.modeLabel,
    required this.targetGoal,
    required this.resolvedTargets,
    required this.hits,
    required this.misses,
    required this.decoyHits,
    required this.timeouts,
    required this.sniperFailures,
    required this.accuracy,
    required this.averageHitMs,
    required this.bestStreak,
    required this.finalMilliseconds,
    required this.targetDiameter,
    required this.movementEnabled,
    required this.movementSpeed,
    required this.revealEnabled,
    required this.revealMilliseconds,
    required this.growthSpeed,
    required this.decoysEnabled,
    required this.decoyCount,
    required this.sniperDuel,
    required this.rating,
  });

  final Color accent;
  final String modeLabel;
  final int targetGoal;
  final int resolvedTargets;
  final int hits;
  final int misses;
  final int decoyHits;
  final int timeouts;
  final int sniperFailures;
  final double? accuracy;
  final double? averageHitMs;
  final int bestStreak;
  final int? finalMilliseconds;
  final double targetDiameter;
  final bool movementEnabled;
  final double movementSpeed;
  final bool revealEnabled;
  final int revealMilliseconds;
  final double growthSpeed;
  final bool decoysEnabled;
  final int decoyCount;
  final bool sniperDuel;
  final String rating;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final totalTime = finalMilliseconds == null
        ? '-'
        : _formatMilliseconds(finalMilliseconds!);
    final averageText = averageHitMs == null
        ? '-'
        : _formatMilliseconds(averageHitMs!);
    final accuracyText = accuracy == null
        ? '-'
        : '${(accuracy! * 100).round()}%';

    return _HumanReportDialogFrame(
      title: Text(
        i18n.t(
          'inline.ui.pages.toolbox_human_tests_aim_widgets.aim_test_report_8fed9f',
        ),
      ),
      accent: accent,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_aim_widgets.mode_combo_48ba25',
              ),
              modeLabel,
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_aim_widgets.targets_d13c96',
              ),
              '$resolvedTargets/$targetGoal',
            ),
            (
              i18n.t('inline.ui.pages.toolbox_human_tests_action.hits_fe10b3'),
              '$hits',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_aim_widgets.blank_taps_00ed16',
              ),
              '$misses',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_aim_widgets.decoys_7648df',
              ),
              '$decoyHits',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_aim_widgets.timeouts_d74808',
              ),
              '$timeouts',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_aim_widgets.sniper_fails_72f20e',
              ),
              '$sniperFailures',
            ),
            (
              i18n.t('inline.ui.pages.practice_review_page.accuracy_8cf5a1'),
              accuracyText,
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_aim_widgets.avg_hit_bb007b',
              ),
              averageText,
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_aim_widgets.best_streak_5a5a71',
              ),
              '$bestStreak',
            ),
            (i18n.t('toolbox.breathing.total_time'), totalTime),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_aim_widgets.rating_1c57db',
              ),
              rating,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          i18n.t(
            'inline.ui.pages.toolbox_human_tests_aim_widgets.round_settings_c284f3',
          ),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        _AimReportSettingRow(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_aim_widgets.target_size_2f3de4',
          ),
          value: '${targetDiameter.round()} dp',
        ),
        _AimReportSettingRow(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_aim_widgets.movement_3f7d30',
          ),
          value: movementEnabled
              ? '${i18n.t('inline.ui.pages.toolbox_human_tests_aim_widgets.on_0363b2')} · ${movementSpeed.toStringAsFixed(1)}x'
              : i18n.t('toolbox.sound.flute.off'),
        ),
        _AimReportSettingRow(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_aim_widgets.reveal_growth_e1d706',
          ),
          value: revealEnabled
              ? '$revealMilliseconds ms · ${growthSpeed.toStringAsFixed(1)}x'
              : i18n.t('toolbox.sound.flute.off'),
        ),
        _AimReportSettingRow(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_aim_widgets.decoys_7648df',
          ),
          value: decoysEnabled
              ? '$decoyCount'
              : i18n.t('toolbox.sound.flute.off'),
        ),
        _AimReportSettingRow(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_aim_widgets.sniper_duel_85c2cf',
          ),
          value: sniperDuel
              ? i18n.t(
                  'inline.ui.pages.toolbox_human_tests_aim_widgets.on_0363b2',
                )
              : i18n.t('toolbox.sound.flute.off'),
        ),
        const SizedBox(height: 14),
        Text(
          i18n.t(
            'inline.ui.pages.toolbox_human_tests_action.training_note_0dc151',
          ),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          _aimReportAdvice(i18n),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
        ),
      ],
    );
  }

  String _aimReportAdvice(AppI18n i18n) {
    final resolvedAccuracy = accuracy ?? 0;
    if (sniperFailures > 0) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_aim_widgets.with_sniper_failures_lower_growth_speed_or_disable_movin_9bc6de',
      );
    }
    if (decoyHits > 0) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_aim_widgets.decoy_hits_suggest_rushed_confirmation_reduce_false_targ_848319',
      );
    }
    if (resolvedAccuracy < 0.75) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_aim_widgets.accuracy_is_still_settling_increase_target_size_or_lower_634f75',
      );
    }
    if ((averageHitMs ?? 9999) > 900) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_aim_widgets.hits_are_stable_so_the_next_step_is_smaller_targets_or_a_8df796',
      );
    }
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_aim_widgets.nice_rhythm_try_moving_growth_or_moving_decoys_to_train_d39b15',
    );
  }
}

class _AimReportSettingRow extends StatelessWidget {
  const _AimReportSettingRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AimStageIdleCard extends StatelessWidget {
  const _AimStageIdleCard({
    required this.title,
    required this.subtitle,
    this.onStart,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colorScheme.surface.withValues(alpha: 0.92),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (onStart != null) ...<Widget>[
            const SizedBox(height: 12),
            _HumanActionButton(
              label: i18n.t('toolbox.breathing.start'),
              icon: Icons.play_arrow_rounded,
              onPressed: onStart,
            ),
          ],
        ],
      ),
    );
  }
}

class _AimStagePainter extends CustomPainter {
  const _AimStagePainter({
    required this.accent,
    required this.support,
    required this.progress,
    required this.running,
  });

  final Color accent;
  final Color support;
  final double progress;
  final bool running;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          accent.withValues(alpha: 0.10),
          const Color(0xFFF9F6F2),
          support.withValues(alpha: 0.08),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, background);

    final gridPaint = Paint()
      ..color = accent.withValues(alpha: 0.055)
      ..strokeWidth = 1;
    const step = 34.0;
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final center = size.center(Offset.zero);
    final pulse = running ? 0.5 + math.sin(progress * math.pi * 2) * 0.5 : 0.2;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = support.withValues(alpha: 0.08 + pulse * 0.08);
    for (var index = 1; index <= 4; index += 1) {
      canvas.drawCircle(center, index * size.shortestSide * 0.12, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AimStagePainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.support != support ||
        oldDelegate.progress != progress ||
        oldDelegate.running != running;
  }
}

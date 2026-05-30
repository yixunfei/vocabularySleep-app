part of 'toolbox_human_tests.dart';

class _VisualMemoryGrid extends StatelessWidget {
  const _VisualMemoryGrid({
    required this.gridSize,
    required this.marks,
    required this.targets,
    required this.picked,
    required this.wrong,
    required this.showing,
    required this.inputEnabled,
    required this.onTap,
  });

  final int gridSize;
  final Map<int, _VisualMemoryCellMark> marks;
  final Set<int> targets;
  final Set<int> picked;
  final Set<int> wrong;
  final bool showing;
  final bool inputEnabled;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final spacing = gridSize >= 6 ? 6.0 : 8.0;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: gridSize * gridSize,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridSize,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemBuilder: (context, index) {
        return _VisualMemoryGridCell(
          mark: marks[index],
          picked: picked.contains(index),
          wrong: wrong.contains(index),
          showing: showing,
          inputEnabled: inputEnabled,
          compact: gridSize >= 6,
          onTap: () => onTap(index),
        );
      },
    );
  }
}

class _VisualMemoryGridCell extends StatelessWidget {
  const _VisualMemoryGridCell({
    required this.mark,
    required this.picked,
    required this.wrong,
    required this.showing,
    required this.inputEnabled,
    required this.compact,
    required this.onTap,
  });

  final _VisualMemoryCellMark? mark;
  final bool picked;
  final bool wrong;
  final bool showing;
  final bool inputEnabled;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visibleMark = showing ? mark : null;
    final effectiveMark = picked ? mark : visibleMark;
    final radius = compact ? 11.0 : 14.0;
    final borderColor = wrong
        ? colorScheme.error
        : picked
        ? (mark?.color ?? colorScheme.secondary)
        : visibleMark == null
        ? colorScheme.outlineVariant
        : visibleMark.kind == _VisualMemoryMarkKind.distractor
        ? _VisualMemoryCardState.distractorColor.withValues(alpha: 0.52)
        : visibleMark.color.withValues(alpha: 0.92);
    final fillColor = wrong
        ? colorScheme.errorContainer
        : effectiveMark == null
        ? colorScheme.surface
        : effectiveMark.kind == _VisualMemoryMarkKind.distractor
        ? effectiveMark.color.withValues(alpha: 0.18)
        : effectiveMark.color.withValues(alpha: picked ? 0.58 : 0.78);
    final icon = wrong
        ? Icons.close_rounded
        : picked
        ? Icons.check_rounded
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: inputEnabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: fillColor,
            border: Border.all(
              color: borderColor,
              width: wrong || picked ? 2 : 1,
            ),
            boxShadow: visibleMark == null || wrong
                ? const <BoxShadow>[]
                : <BoxShadow>[
                    BoxShadow(
                      color: visibleMark.color.withValues(alpha: 0.18),
                      blurRadius: compact ? 6 : 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: icon == null
              ? null
              : Icon(
                  icon,
                  color: wrong
                      ? colorScheme.onErrorContainer
                      : colorScheme.onPrimaryContainer,
                  size: compact ? 18 : 22,
                ),
        ),
      ),
    );
  }
}

class _VisualMemoryLegend extends StatelessWidget {
  const _VisualMemoryLegend({required this.i18n, required this.showDistractor});

  final AppI18n i18n;
  final bool showDistractor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _VisualMemoryLegendItem(
          color: _VisualMemoryCardState.accent,
          text: i18n.t('toolbox.breathing.target'),
        ),
        _VisualMemoryLegendItem(
          color: colorScheme.secondary,
          text: i18n.t(
            'inline.ui.pages.toolbox_human_tests_visual_memory_widgets.picked_f47f56',
          ),
          icon: Icons.check_rounded,
        ),
        _VisualMemoryLegendItem(
          color: colorScheme.error,
          text: i18n.t(
            'inline.ui.pages.toolbox_human_tests_bimanual.miss_7876fa',
          ),
          icon: Icons.close_rounded,
        ),
        if (showDistractor)
          _VisualMemoryLegendItem(
            color: _VisualMemoryCardState.distractorColor,
            text: i18n.t(
              'inline.ui.pages.toolbox_human_tests_visual_memory_widgets.distractor_a38341',
            ),
          ),
      ],
    );
  }
}

class _VisualMemoryLegendItem extends StatelessWidget {
  const _VisualMemoryLegendItem({
    required this.color,
    required this.text,
    this.icon,
  });

  final Color color;
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.76),
              borderRadius: BorderRadius.circular(4),
            ),
            child: icon == null
                ? null
                : Icon(icon, size: 10, color: theme.colorScheme.onPrimary),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualMemoryColorPill extends StatelessWidget {
  const _VisualMemoryColorPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualMemoryPaletteDots extends StatelessWidget {
  const _VisualMemoryPaletteDots({required this.colors});

  final List<_VisualMemoryColorToken> colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 18,
      child: Stack(
        children: colors
            .take(3)
            .toList(growable: false)
            .asMap()
            .entries
            .map((entry) {
              return Positioned(
                left: entry.key * 6.0,
                top: 3,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: entry.value.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 1.2,
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _VisualMemorySliderLabel extends StatelessWidget {
  const _VisualMemorySliderLabel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: theme.textTheme.labelLarge)),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualMemoryReportDialog extends StatelessWidget {
  const _VisualMemoryReportDialog({required this.data, required this.accent});

  final _VisualMemoryReportData data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final accuracy = data.correctTaps + data.wrongTaps == 0
        ? 0
        : (data.correctTaps / (data.correctTaps + data.wrongTaps) * 100)
              .round();
    final recall = data.totalTargetsShown == 0
        ? 0
        : (data.correctTaps / data.totalTargetsShown * 100).round();
    final recentRounds = data.rounds.length <= 8
        ? data.rounds
        : data.rounds.sublist(data.rounds.length - 8);

    return _HumanReportDialogFrame(
      title: Text(
        i18n.t(
          'inline.ui.pages.toolbox_human_tests_visual_memory_widgets.visual_memory_report_0be164',
        ),
      ),
      accent: accent,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.best_level_6b13a1',
              ),
              '${data.bestLevel}',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_memory.cleared_c85927',
              ),
              '${data.completedRounds}/${data.roundsStarted}',
            ),
            (
              i18n.t('inline.ui.pages.practice_support.recall_4e1a00'),
              '$recall%',
            ),
            (
              i18n.t('inline.ui.pages.practice_review_page.accuracy_8cf5a1'),
              '$accuracy%',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_auditory.misses_bcc2a1',
              ),
              '${data.wrongTaps}',
            ),
            (
              i18n.t('inline.plan295.life.time.bf469a617001'),
              _formatSeconds(data.duration.inMilliseconds / 1000),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _VisualMemoryReportSummary(data: data, accuracy: accuracy),
        const SizedBox(height: 14),
        Text(
          i18n.t(
            'inline.ui.pages.toolbox_human_tests_visual_memory_widgets.miss_sources_d7e2ed',
          ),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_visual_memory_widgets.color_decoys_4838c3',
              ),
              '${data.colorWrongTaps}',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_visual_memory_widgets.gray_decoys_712f8c',
              ),
              '${data.distractorWrongTaps}',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_visual_memory_widgets.blank_cells_39b7bc',
              ),
              '${data.blankWrongTaps}',
            ),
          ],
        ),
        if (recentRounds.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_bimanual.recent_rounds_520a3c',
            ),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Column(
            children: <Widget>[
              for (var index = 0; index < recentRounds.length; index++) ...[
                _VisualMemoryReportRoundRow(
                  result: recentRounds[index],
                  accent: accent,
                ),
                if (index != recentRounds.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _VisualMemoryReportSummary extends StatelessWidget {
  const _VisualMemoryReportSummary({
    required this.data,
    required this.accuracy,
  });

  final _VisualMemoryReportData data;
  final int accuracy;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final theme = Theme.of(context);
    final difficulty = _visualMemoryDifficultyLabel(i18n, data.difficulty);
    final mode = _visualMemoryModeLabel(i18n, data.mode);
    final pressure = (data.colorPressure * 100).round();
    final suggestion = accuracy >= 85 && data.completedRounds >= 3
        ? i18n.t(
            'inline.ui.pages.toolbox_human_tests_visual_memory_widgets.stable_run_try_more_active_colors_or_stronger_decoy_inte_7f68c4',
          )
        : i18n.t(
            'inline.ui.pages.toolbox_human_tests_visual_memory_widgets.anchor_on_the_target_color_label_and_swatch_first_then_s_5c7bb9',
          );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.48,
        ),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        i18n.t(
          'inline.ui.pages.toolbox_human_tests_visual_memory_widgets.difficulty_mode_near_color_pressure_was_about_pressure_s_826dee',
        ),
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
      ),
    );
  }
}

String _visualMemoryDifficultyLabel(
  AppI18n i18n,
  _VisualMemoryDifficulty difficulty,
) {
  return switch (difficulty) {
    _VisualMemoryDifficulty.relaxed => i18n.t(
      'inline.plan295.daily_choice.relaxed.556d216b95e0',
    ),
    _VisualMemoryDifficulty.standard => i18n.t(
      'inline.ui.pages.toolbox_human_tests_bimanual.standard_b9acb5',
    ),
    _VisualMemoryDifficulty.challenge => i18n.t(
      'inline.ui.pages.toolbox_human_tests_visual_memory_widgets.challenge_dea913',
    ),
    _VisualMemoryDifficulty.custom => i18n.t('toolbox.sound.harp.custom'),
  };
}

String _visualMemoryModeLabel(AppI18n i18n, _VisualMemoryMode mode) {
  return switch (mode) {
    _VisualMemoryMode.positions => i18n.t(
      'inline.ui.pages.toolbox_human_tests_visual_memory_widgets.positions_bb6d32',
    ),
    _VisualMemoryMode.colorTargets => i18n.t(
      'inline.ui.pages.toolbox_human_tests_visual_memory_widgets.color_targets_124d6a',
    ),
    _VisualMemoryMode.targetColor => i18n.t(
      'inline.ui.pages.toolbox_human_tests_visual_memory_widgets.target_color_07c19b',
    ),
  };
}

class _VisualMemoryReportRoundRow extends StatelessWidget {
  const _VisualMemoryReportRoundRow({
    required this.result,
    required this.accent,
  });

  final _VisualMemoryRoundResult result;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final theme = Theme.of(context);
    final statusColor = result.success ? accent : theme.colorScheme.error;
    final targetColor = result.targetColor;
    final targetText = targetColor == null
        ? ''
        : i18n.t(
            'inline.ui.pages.toolbox_human_tests_visual_memory_widgets.target_targetcolor_en_d2b139',
          );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: statusColor.withValues(alpha: 0.08),
        border: Border.all(color: statusColor.withValues(alpha: 0.20)),
      ),
      child: Text(
        i18n.t(
          'inline.ui.pages.toolbox_human_tests_visual_memory_widgets.level_result_level_result_gridsize_x_result_gridsize_tar_d58e74',
        ),
        style: theme.textTheme.bodySmall?.copyWith(
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

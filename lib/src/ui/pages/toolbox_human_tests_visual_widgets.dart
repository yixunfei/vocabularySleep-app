part of 'toolbox_human_tests.dart';

class _ColorVisionTargetPrompt extends StatelessWidget {
  const _ColorVisionTargetPrompt({
    required this.i18n,
    required this.color,
    required this.targetCount,
  });

  final AppI18n i18n;
  final Color color;
  final int targetCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.28),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  i18n.t(
                    'inline.ui.pages.toolbox_human_tests_visual_memory_widgets.target_color_07c19b',
                  ),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  i18n.t(
                    'inline.ui.pages.toolbox_human_tests_visual_widgets.tap_tiles_exactly_matching_the_swatch_targets_this_round_ac9ce0',
                    params: <String, Object?>{'targetCount': targetCount},
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorVisionGrid extends StatelessWidget {
  const _ColorVisionGrid({
    required this.i18n,
    required this.cells,
    required this.gridSize,
    required this.hintActive,
    required this.onTap,
  });

  final AppI18n i18n;
  final List<_ColorVisionCell> cells;
  final int gridSize;
  final bool hintActive;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cells.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridSize,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final cell = cells[index];
        final showHint = hintActive && cell.correct;
        return Semantics(
          button: true,
          label: showHint
              ? i18n.t(
                  'inline.ui.pages.toolbox_human_tests_visual_widgets.hint_target_color_tile_95dd0c',
                )
              : i18n.t(
                  'inline.ui.pages.toolbox_human_tests_visual_widgets.color_tile_376f79',
                ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onTap(index),
              child: AnimatedContainer(
                key: ValueKey<String>('color-vision-cell-$index'),
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: cell.color,
                  border: Border.all(
                    color: showHint
                        ? colorScheme.onSurface
                        : Colors.white.withValues(alpha: 0.28),
                    width: showHint ? 3 : 1,
                  ),
                  boxShadow: showHint
                      ? <BoxShadow>[
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: showHint
                    ? Icon(
                        Icons.my_location_rounded,
                        color: colorScheme.onSurface,
                        size: 18,
                      )
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ColorVisionSettingSlider extends StatelessWidget {
  const _ColorVisionSettingSlider({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(valueText, style: theme.textTheme.labelMedium),
          ],
        ),
        if ((max - min).abs() < 0.001)
          const SizedBox(height: 8)
        else
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: math.max(1, divisions),
            label: valueText,
            onChanged: onChanged,
          ),
      ],
    );
  }
}

class _ColorVisionReportDialog extends StatelessWidget {
  const _ColorVisionReportDialog({
    required this.data,
    required this.accent,
    required this.modeLabel,
    required this.filterLabel,
    required this.bandLabel,
    required this.axisLabel,
  });

  final _ColorVisionReportData data;
  final Color accent;
  final String Function(_ColorVisionMode mode) modeLabel;
  final String Function(_ColorVisionFilter filter) filterLabel;
  final String Function(_ColorVisionHueBand band) bandLabel;
  final String Function(_ColorVisionDeltaAxis axis) axisLabel;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final theme = Theme.of(context);
    final bandStats = _bandStats();
    final axisStats = _axisStats();
    final weakestBand = bandStats.isEmpty
        ? null
        : bandStats.reduce(
            (left, right) => left.accuracy <= right.accuracy ? left : right,
          );
    final weakestAxis = axisStats.isEmpty
        ? null
        : axisStats.reduce(
            (left, right) => left.accuracy <= right.accuracy ? left : right,
          );
    final recommendation = _recommendation(i18n, weakestBand, weakestAxis);

    return AlertDialog(
      title: Text(
        i18n.t(
          'inline.ui.pages.toolbox_human_tests_visual_widgets.color_vision_report_b8cb18',
        ),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _ColorVisionReportMetric(
                    label: i18n.t(
                      'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.best_level_6b13a1',
                    ),
                    value: '${data.bestLevel}',
                  ),
                  _ColorVisionReportMetric(
                    label: i18n.t(
                      'inline.ui.pages.practice_review_page.accuracy_8cf5a1',
                    ),
                    value: '${(data.accuracy * 100).round()}%',
                  ),
                  _ColorVisionReportMetric(
                    label: i18n.t('rounds'),
                    value: '${data.rounds}',
                  ),
                  _ColorVisionReportMetric(
                    label: i18n.t(
                      'inline.ui.pages.toolbox_human_tests_visual_widgets.hints_1e1ac9',
                    ),
                    value: '${data.hintsUsed}',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ColorVisionReportSection(
                title: i18n.t(
                  'inline.ui.pages.toolbox_human_tests_visual_widgets.overall_analysis_ee1b15',
                ),
                child: Text(
                  _overallSummary(i18n, weakestBand, weakestAxis),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
              ),
              const SizedBox(height: 12),
              if (data.records.length >= 2)
                _ColorVisionReportSection(
                  title: i18n.t(
                    'inline.ui.pages.toolbox_human_tests_visual_widgets.recent_delta_records_8b9528',
                  ),
                  child: _ColorVisionRecentDeltaList(
                    records: data.records,
                    accent: accent,
                  ),
                ),
              const SizedBox(height: 12),
              if (bandStats.isNotEmpty)
                _ColorVisionReportSection(
                  title: i18n.t(
                    'inline.ui.pages.toolbox_human_tests_visual_widgets.hue_groups_2c17f8',
                  ),
                  child: _ColorVisionBandStatList(
                    stats: bandStats,
                    labelFor: bandLabel,
                    accent: accent,
                  ),
                ),
              const SizedBox(height: 12),
              if (axisStats.isNotEmpty)
                _ColorVisionReportSection(
                  title: i18n.t(
                    'inline.ui.pages.toolbox_human_tests_visual_widgets.contrast_axes_e30257',
                  ),
                  child: _ColorVisionAxisStatList(
                    stats: axisStats,
                    labelFor: axisLabel,
                    accent: accent,
                  ),
                ),
              const SizedBox(height: 12),
              _ColorVisionReportSection(
                title: i18n.t(
                  'inline.ui.pages.practice_session_page.session_settings_35f8c2',
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    Chip(label: Text(modeLabel(data.mode))),
                    Chip(label: Text(filterLabel(data.filter))),
                    Chip(
                      label: Text(
                        '${data.initialGrid}x${data.initialGrid} -> ${data.maxGrid}x${data.maxGrid}',
                      ),
                    ),
                    Chip(
                      label: Text(
                        i18n.t(
                          'inline.ui.pages.toolbox_human_tests_visual_widgets.avg_passed_delta_data_averagecorrectdelta_100_tostringas_6d823d',
                          params: <String, Object?>{
                            'dataAverageCorrectDelta':
                                (data.averageCorrectDelta * 100)
                                    .toStringAsFixed(1),
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ColorVisionReportSection(
                title: i18n.t(
                  'inline.ui.pages.toolbox_human_tests_action.training_note_0dc151',
                ),
                child: Text(
                  recommendation,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(i18n.t('inline.plan295.life.close.370fb8697deb')),
        ),
      ],
    );
  }

  List<_ColorVisionBandStat> _bandStats() {
    return _ColorVisionHueBand.values
        .map((band) {
          final records = data.records
              .where((record) => record.hueBand == band)
              .toList(growable: false);
          if (records.isEmpty) {
            return null;
          }
          return _ColorVisionBandStat(
            band: band,
            total: records.length,
            correct: records.where((record) => record.correct).length,
            averageDelta:
                records.fold<double>(0, (sum, record) => sum + record.delta) /
                records.length,
          );
        })
        .whereType<_ColorVisionBandStat>()
        .toList(growable: false);
  }

  List<_ColorVisionAxisStat> _axisStats() {
    return _ColorVisionDeltaAxis.values
        .map((axis) {
          final records = data.records
              .where((record) => record.deltaAxis == axis)
              .toList(growable: false);
          if (records.isEmpty) {
            return null;
          }
          return _ColorVisionAxisStat(
            axis: axis,
            total: records.length,
            correct: records.where((record) => record.correct).length,
          );
        })
        .whereType<_ColorVisionAxisStat>()
        .toList(growable: false);
  }

  String _overallSummary(
    AppI18n i18n,
    _ColorVisionBandStat? weakestBand,
    _ColorVisionAxisStat? weakestAxis,
  ) {
    if (data.rounds <= 0) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual_widgets.no_valid_rounds_yet_complete_a_few_rounds_to_unlock_delt_621356',
      );
    }
    final weakBandText = weakestBand == null
        ? i18n.t(
            'inline.ui.pages.toolbox_human_tests_visual_widgets.not_clear_yet_108184',
          )
        : bandLabel(weakestBand.band);
    final weakAxisText = weakestAxis == null
        ? i18n.t(
            'inline.ui.pages.toolbox_human_tests_visual_widgets.not_clear_yet_108184',
          )
        : axisLabel(weakestAxis.axis);
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_visual_widgets.accuracy_is_data_accuracy_100_round_the_weakest_hue_band_2b930d',
      params: <String, Object?>{
        'dataAccuracy': (data.accuracy * 100).round(),
        'weakBandText': weakBandText,
        'weakAxisText': weakAxisText,
        'dataAverageCorrectDelta': (data.averageCorrectDelta * 100)
            .toStringAsFixed(1),
        'dataAverageMissDelta': (data.averageMissDelta * 100).toStringAsFixed(
          1,
        ),
      },
    );
  }

  String _recommendation(
    AppI18n i18n,
    _ColorVisionBandStat? weakestBand,
    _ColorVisionAxisStat? weakestAxis,
  ) {
    if (data.rounds < 6) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual_widgets.the_sample_is_still_small_complete_at_least_10_rounds_be_79c936',
      );
    }
    final band = weakestBand == null ? '' : bandLabel(weakestBand.band);
    final axis = weakestAxis == null ? '' : axisLabel(weakestAxis.axis);
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_visual_widgets.for_the_next_run_keep_the_weak_hue_family_enabled_lower_df248f',
      params: <String, Object?>{'axis': axis, 'band': band},
    );
  }
}

class _ColorVisionReportMetric extends StatelessWidget {
  const _ColorVisionReportMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _ColorVisionReportSection extends StatelessWidget {
  const _ColorVisionReportSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ColorVisionRecentDeltaList extends StatelessWidget {
  const _ColorVisionRecentDeltaList({
    required this.records,
    required this.accent,
  });

  final List<_ColorVisionRoundRecord> records;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final shown = records.length <= 8
        ? records
        : records.sublist(records.length - 8);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List<Widget>.generate(shown.length, (index) {
        final record = shown[index];
        final color = record.correct
            ? accent
            : Theme.of(context).colorScheme.error;
        return Padding(
          padding: EdgeInsets.only(bottom: index == shown.length - 1 ? 0 : 8),
          child: Row(
            children: <Widget>[
              Icon(
                record.correct
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 9,
                    value: record.delta.clamp(0.0, 1.0),
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                i18n.t(
                  'inline.ui.pages.toolbox_human_tests_visual_widgets.delta_record_delta_100_tostringasfixed_1_472de9',
                  params: <String, Object?>{
                    'recordDelta': (record.delta * 100).toStringAsFixed(1),
                  },
                ),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ColorVisionBandStatList extends StatelessWidget {
  const _ColorVisionBandStatList({
    required this.stats,
    required this.labelFor,
    required this.accent,
  });

  final List<_ColorVisionBandStat> stats;
  final String Function(_ColorVisionHueBand band) labelFor;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: stats
          .map((stat) {
            return _ColorVisionStatRow(
              label: labelFor(stat.band),
              value: stat.accuracy,
              trailing:
                  '${stat.correct}/${stat.total} · ${(stat.averageDelta * 100).toStringAsFixed(1)}',
              color: accent,
            );
          })
          .toList(growable: false),
    );
  }
}

class _ColorVisionAxisStatList extends StatelessWidget {
  const _ColorVisionAxisStatList({
    required this.stats,
    required this.labelFor,
    required this.accent,
  });

  final List<_ColorVisionAxisStat> stats;
  final String Function(_ColorVisionDeltaAxis axis) labelFor;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: stats
          .map((stat) {
            return _ColorVisionStatRow(
              label: labelFor(stat.axis),
              value: stat.accuracy,
              trailing: '${stat.correct}/${stat.total}',
              color: accent,
            );
          })
          .toList(growable: false),
    );
  }
}

class _ColorVisionStatRow extends StatelessWidget {
  const _ColorVisionStatRow({
    required this.label,
    required this.value,
    required this.trailing,
    required this.color,
  });

  final String label;
  final double value;
  final String trailing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 88,
            child: Text(label, style: theme.textTheme.labelMedium),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: value.clamp(0.0, 1.0),
                color: color,
                backgroundColor: color.withValues(alpha: 0.14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 74,
            child: Text(
              '${(value * 100).round()}% $trailing',
              textAlign: TextAlign.right,
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

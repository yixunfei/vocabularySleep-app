part of 'toolbox_human_tests.dart';

class _VerbalMemoryFeedback extends StatelessWidget {
  const _VerbalMemoryFeedback({required this.title, required this.accent});

  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: accent.withValues(alpha: 0.10),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline_rounded, color: accent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageMessage extends StatelessWidget {
  const _StageMessage({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
        ),
      ],
    );
  }
}

class _ArrowSequenceView extends StatelessWidget {
  const _ArrowSequenceView({required this.sequence, required this.accent});

  final List<_VerbalMemoryArrowDirection> sequence;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: sequence
          .map((direction) {
            final spec = _arrowSpec(direction);
            return Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                color: accent.withValues(alpha: 0.14),
                border: Border.all(color: accent.withValues(alpha: 0.28)),
              ),
              child: Icon(spec.icon, color: accent),
            );
          })
          .toList(growable: false),
    );
  }
}

class _ArrowPad extends StatelessWidget {
  const _ArrowPad({
    required this.specs,
    required this.enabled,
    required this.onTap,
  });

  final List<_VerbalMemoryArrowSpec> specs;
  final bool enabled;
  final ValueChanged<_VerbalMemoryArrowDirection> onTap;

  @override
  Widget build(BuildContext context) {
    final active = specs.map((spec) => spec.direction).toSet();
    final slots = <_VerbalMemoryArrowDirection?>[
      _VerbalMemoryArrowDirection.upLeft,
      _VerbalMemoryArrowDirection.up,
      _VerbalMemoryArrowDirection.upRight,
      _VerbalMemoryArrowDirection.left,
      null,
      _VerbalMemoryArrowDirection.right,
      _VerbalMemoryArrowDirection.downLeft,
      _VerbalMemoryArrowDirection.down,
      _VerbalMemoryArrowDirection.downRight,
    ];
    return Center(
      child: SizedBox(
        width: 178,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: slots.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final direction = slots[index];
            if (direction == null || !active.contains(direction)) {
              return const SizedBox.shrink();
            }
            final spec = _arrowSpec(direction);
            return Tooltip(
              message: spec.label(
                AppI18n(Localizations.localeOf(context).languageCode),
              ),
              child: IconButton.filledTonal(
                onPressed: enabled ? () => onTap(direction) : null,
                icon: Icon(spec.icon),
                iconSize: 22,
                style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VerbalMemoryReportDialog extends StatelessWidget {
  const _VerbalMemoryReportDialog({
    required this.mode,
    required this.success,
    required this.attempts,
    required this.correct,
    required this.lives,
    required this.bestLevel,
    required this.bestStreak,
    required this.totalResponseMs,
    required this.bestResponseMs,
    required this.maxSequenceLength,
    required this.stageHeight,
    required this.previewMs,
    required this.wordPoolSize,
    required this.domainsSummary,
    required this.wordRepeatChance,
    required this.arrowSet,
    required this.numberBaseLength,
    required this.duration,
    required this.results,
    required this.accent,
  });

  final _VerbalMemoryMode mode;
  final bool success;
  final int attempts;
  final int correct;
  final int lives;
  final int bestLevel;
  final int bestStreak;
  final int totalResponseMs;
  final int? bestResponseMs;
  final int maxSequenceLength;
  final int stageHeight;
  final int previewMs;
  final int wordPoolSize;
  final String domainsSummary;
  final double wordRepeatChance;
  final _VerbalMemoryArrowSet arrowSet;
  final int numberBaseLength;
  final Duration duration;
  final List<_VerbalMemoryRoundResult> results;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final accuracy = attempts == 0 ? 0 : (correct / attempts * 100).round();
    final averageResponse = attempts == 0 ? null : totalResponseMs / attempts;
    return _HumanReportDialogFrame(
      title: Text(
        i18n.t(
          'inline.ui.pages.toolbox_human_tests_verbal_memory_widgets.memory_run_report_78694f',
        ),
      ),
      accent: accent,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              i18n.t('inline.plan295.life.result.e1843313cacb'),
              success
                  ? i18n.t(
                      'inline.ui.pages.toolbox_human_tests_verbal_memory_view.ended_97c445',
                    )
                  : i18n.t(
                      'inline.ui.pages.toolbox_human_tests_verbal_memory_widgets.out_of_lives_dbb831',
                    ),
            ),
            (
              i18n.t('toolbox.sound.piano.mode'),
              _verbalMemoryModeLabel(i18n, mode),
            ),
            (i18n.t('rounds'), '$attempts'),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_cognition.correct_465f00',
              ),
              '$correct',
            ),
            (
              i18n.t('inline.ui.pages.practice_review_page.accuracy_8cf5a1'),
              '$accuracy%',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_verbal_memory_widgets.lives_left_6b7bdd',
              ),
              '$lives',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.best_level_6b13a1',
              ),
              '$bestLevel',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_aim_widgets.best_streak_5a5a71',
              ),
              '$bestStreak',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_auditory.avg_response_3140b8',
              ),
              averageResponse == null
                  ? '-'
                  : _formatMilliseconds(averageResponse),
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_verbal_memory_widgets.best_response_7613b9',
              ),
              bestResponseMs == null
                  ? '-'
                  : _formatMilliseconds(bestResponseMs!),
            ),
            (
              i18n.t('toolbox.breathing.duration'),
              _formatSeconds(duration.inMilliseconds / 1000),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _VerbalMemoryReportBlock(
          title: i18n.t(
            'inline.ui.pages.toolbox_human_tests_memory.analysis_b0b53c',
          ),
          body: _analysisText(i18n, accuracy),
          accent: accent,
        ),
        const SizedBox(height: 10),
        _VerbalMemoryReportBlock(
          title: i18n.t(
            'inline.ui.pages.toolbox_human_tests_verbal_memory_widgets.run_settings_ece56c',
          ),
          body: _settingsSummary(i18n),
          accent: accent,
        ),
        if (results.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
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
              for (var index = 0; index < results.length; index++) ...<Widget>[
                _VerbalMemoryResultRow(
                  index: results.length - index,
                  result: results[index],
                  accent: accent,
                ),
                if (index != results.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
        ],
      ],
    );
  }

  String _analysisText(AppI18n i18n, int accuracy) {
    if (attempts < 3) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_verbal_memory_widgets.the_sample_is_still_small_complete_at_least_8_12_rounds_372c47',
      );
    }
    if (accuracy >= 92 && bestStreak >= 6) {
      return switch (mode) {
        _VerbalMemoryMode.words => i18n.t(
          'inline.ui.pages.toolbox_human_tests_verbal_memory_widgets.word_recognition_is_stable_raise_repeat_rate_or_narrow_t_1c2a38',
        ),
        _VerbalMemoryMode.numbers => i18n.t(
          'inline.ui.pages.toolbox_human_tests_verbal_memory_widgets.digit_recall_is_stable_raise_base_digits_or_shorten_view_f47a23',
        ),
        _VerbalMemoryMode.arrows => i18n.t(
          'inline.ui.pages.toolbox_human_tests_verbal_memory_widgets.spatial_recall_is_stable_switch_to_8_directions_or_short_9bac20',
        ),
      };
    }
    if (accuracy >= 75) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_verbal_memory_widgets.performance_is_usable_but_uneven_keep_the_current_diffic_ba87a5',
      );
    }
    return switch (mode) {
      _VerbalMemoryMode.words => i18n.t(
        'inline.ui.pages.toolbox_human_tests_verbal_memory_widgets.the_pressure_is_mainly_new_vs_seen_judgment_use_fewer_do_6dc8c6',
      ),
      _VerbalMemoryMode.numbers => i18n.t(
        'inline.ui.pages.toolbox_human_tests_verbal_memory_widgets.digit_recall_accuracy_is_low_lower_base_digits_or_raise_5a85aa',
      ),
      _VerbalMemoryMode.arrows => i18n.t(
        'inline.ui.pages.toolbox_human_tests_verbal_memory_widgets.spatial_order_is_not_steady_yet_stay_on_4_directions_unt_7d8b8e',
      ),
    };
  }

  String _settingsSummary(AppI18n i18n) {
    return switch (mode) {
      _VerbalMemoryMode.words => i18n.t(
        'inline.ui.pages.toolbox_human_tests_verbal_memory_widgets.domains_domainssummary_pool_wordpoolsize_base_repeat_wor_7d5c7d',
      ),
      _VerbalMemoryMode.numbers => i18n.t(
        'inline.ui.pages.toolbox_human_tests_verbal_memory_widgets.base_digits_numberbaselength_max_sequence_maxsequencelen_31452b',
      ),
      _VerbalMemoryMode.arrows => i18n.t(
        'inline.ui.pages.toolbox_human_tests_verbal_memory_widgets.direction_set_verbalmemoryarrowsetlabel_i18n_arrowset_ma_fe9b32',
      ),
    };
  }
}

class _VerbalMemoryReportBlock extends StatelessWidget {
  const _VerbalMemoryReportBlock({
    required this.title,
    required this.body,
    required this.accent,
  });

  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: accent.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _VerbalMemoryResultRow extends StatelessWidget {
  const _VerbalMemoryResultRow({
    required this.index,
    required this.result,
    required this.accent,
  });

  final int index;
  final _VerbalMemoryRoundResult result;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final color = result.correct
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            result.correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '#$index · ${_verbalMemoryModeLabel(i18n, result.mode)} L${result.level} · ${result.sizeLabel}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  i18n.t(
                    'inline.ui.pages.toolbox_human_tests_verbal_memory_widgets.expected_result_expectedlabel_response_result_responsela_f9d347',
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(height: 1.3),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMilliseconds(result.responseMs),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

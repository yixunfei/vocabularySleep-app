part of 'toolbox_human_tests.dart';

class _HumanReportDialogFrame extends StatelessWidget {
  const _HumanReportDialogFrame({
    required this.title,
    required this.children,
    required this.accent,
  });

  final Widget title;
  final List<Widget> children;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mediaSize = MediaQuery.sizeOf(context);
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : mediaSize.width - 32;
          final availableHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : mediaSize.height - 48;
          final width = math.min(560.0, math.max(0.0, availableWidth));
          final height = math.min(640.0, math.max(0.0, availableHeight));

          return SizedBox(
            width: width,
            height: height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                  child: DefaultTextStyle.merge(
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                    child: title,
                  ),
                ),
                Divider(height: 1, color: accent.withValues(alpha: 0.18)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        MaterialLocalizations.of(context).okButtonLabel,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HandEyeCompletionReportDialog extends StatelessWidget {
  const _HandEyeCompletionReportDialog({
    required this.results,
    required this.roundCount,
    required this.totalBlankTaps,
    required this.totalDistractorTaps,
    required this.accent,
  });

  final List<_HandEyeRoundResult> results;
  final int roundCount;
  final int totalBlankTaps;
  final int totalDistractorTaps;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final successes = results.where((item) => item.success).length;
    final missed = results.length - successes;
    final reactions = results
        .where((item) => item.success && item.firstReaction != null)
        .map((item) => item.firstReaction!.inMilliseconds)
        .toList(growable: false);
    final averageReaction = reactions.isEmpty
        ? null
        : Duration(
            milliseconds: (reactions.reduce((a, b) => a + b) / reactions.length)
                .round(),
          );
    final bestReaction = reactions.isEmpty ? null : reactions.reduce(math.min);
    final completionTimes = results
        .where((item) => item.completionLatency != null)
        .map((item) => item.completionLatency!.inMilliseconds)
        .toList(growable: false);
    final averageCompletion = completionTimes.isEmpty
        ? null
        : Duration(
            milliseconds:
                (completionTimes.reduce((a, b) => a + b) /
                        completionTimes.length)
                    .round(),
          );

    return _HumanReportDialogFrame(
      title: Text(
        i18n.t(
          'inline.ui.pages.toolbox_human_tests_hand_eye_reports.hand_eye_report_f6bee0',
        ),
      ),
      accent: accent,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (i18n.t('rounds'), '$successes/$roundCount'),
            (i18n.t('toolbox.sleep.rhythm.missed'), '$missed'),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_hand_eye_parts.blanks_84a873',
              ),
              '$totalBlankTaps',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_aim.false_targets_c0458f',
              ),
              '$totalDistractorTaps',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_bimanual.avg_reaction_2a9cf7',
              ),
              averageReaction == null
                  ? '-'
                  : _formatMilliseconds(averageReaction.inMilliseconds),
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_hand_eye_reports.best_reaction_7f77f1',
              ),
              bestReaction == null ? '-' : _formatMilliseconds(bestReaction),
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_hand_eye_reports.avg_completion_6748fa',
              ),
              averageCompletion == null
                  ? '-'
                  : _formatMilliseconds(averageCompletion.inMilliseconds),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_reports.round_details_fd1be3',
          ),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Column(
          children: <Widget>[
            for (var index = 0; index < results.length; index++) ...<Widget>[
              _HandEyeResultRow(
                index: index + 1,
                result: results[index],
                accent: accent,
              ),
              if (index != results.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _JoystickCompletionReportDialog extends StatelessWidget {
  const _JoystickCompletionReportDialog({
    required this.mode,
    required this.durationSeconds,
    required this.targetGoal,
    required this.hits,
    required this.shotsOff,
    required this.falseTargetShots,
    required this.reactions,
    required this.targetDiameter,
    required this.targetMovementEnabled,
    required this.accent,
  });

  final _JoystickTestMode mode;
  final int durationSeconds;
  final int targetGoal;
  final int hits;
  final int shotsOff;
  final int falseTargetShots;
  final List<Duration> reactions;
  final double targetDiameter;
  final bool targetMovementEnabled;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final shots = hits + shotsOff;
    final accuracy = shots == 0 ? null : hits / shots * 100;
    final reactionMs = reactions
        .map((item) => item.inMilliseconds)
        .toList(growable: false);
    final averageReaction = reactionMs.isEmpty
        ? null
        : Duration(
            milliseconds:
                (reactionMs.reduce((a, b) => a + b) / reactionMs.length)
                    .round(),
          );
    final bestReaction = reactionMs.isEmpty
        ? null
        : reactionMs.reduce(math.min);
    final progress = mode == _JoystickTestMode.timed
        ? _formatSeconds(durationSeconds)
        : '$hits/$targetGoal';

    return _HumanReportDialogFrame(
      title: Text(
        i18n.t(
          'inline.ui.pages.toolbox_human_tests_hand_eye_reports.joystick_report_194515',
        ),
      ),
      accent: accent,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              i18n.t('toolbox.sound.piano.mode'),
              mode == _JoystickTestMode.timed
                  ? i18n.t(
                      'inline.ui.pages.toolbox_human_tests_cognition.timed_4e65ea',
                    )
                  : i18n.t('inline.plan294.woodfish.target_count_211bec09'),
            ),
            (i18n.t('progress'), progress),
            (
              i18n.t('inline.ui.pages.toolbox_human_tests_action.hits_fe10b3'),
              '$hits',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_hand_eye_joystick.shots_off_cac739',
              ),
              '$shotsOff',
            ),
            (
              i18n.t('inline.ui.pages.practice_review_page.accuracy_8cf5a1'),
              accuracy == null ? '-' : '${accuracy.round()}%',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_bimanual.avg_reaction_2a9cf7',
              ),
              averageReaction == null
                  ? '-'
                  : _formatMilliseconds(averageReaction.inMilliseconds),
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_hand_eye_reports.best_reaction_7f77f1',
              ),
              bestReaction == null ? '-' : _formatMilliseconds(bestReaction),
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_hand_eye_reports.false_shots_787c84',
              ),
              '$falseTargetShots',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_aim_widgets.target_size_2f3de4',
              ),
              '${targetDiameter.round()} dp',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_hand_eye_reports.target_movement_6fc861',
              ),
              targetMovementEnabled
                  ? i18n.t(
                      'inline.ui.pages.toolbox_human_tests_aim_widgets.on_0363b2',
                    )
                  : i18n.t('toolbox.sound.flute.off'),
            ),
          ],
        ),
        if (reactions.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_hand_eye_parts.hit_latency_details_21ebbf',
            ),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(reactions.length, (index) {
              return _HumanPill(
                text:
                    '#${index + 1} ${_formatMilliseconds(reactions[index].inMilliseconds)}',
                accent: accent,
              );
            }),
          ),
        ],
      ],
    );
  }
}

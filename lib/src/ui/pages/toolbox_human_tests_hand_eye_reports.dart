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
      title: Text(pickUiText(i18n, zh: '手眼协调结果报告', en: 'Hand-eye report')),
      accent: accent,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(i18n, zh: '完成轮次', en: 'Rounds'),
              '$successes/$roundCount',
            ),
            (pickUiText(i18n, zh: '漏掉', en: 'Missed'), '$missed'),
            (pickUiText(i18n, zh: '点空', en: 'Blanks'), '$totalBlankTaps'),
            (
              pickUiText(i18n, zh: '假目标', en: 'False targets'),
              '$totalDistractorTaps',
            ),
            (
              pickUiText(i18n, zh: '平均反应', en: 'Avg reaction'),
              averageReaction == null
                  ? '-'
                  : _formatMilliseconds(averageReaction.inMilliseconds),
            ),
            (
              pickUiText(i18n, zh: '最快反应', en: 'Best reaction'),
              bestReaction == null ? '-' : _formatMilliseconds(bestReaction),
            ),
            (
              pickUiText(i18n, zh: '平均完成', en: 'Avg completion'),
              averageCompletion == null
                  ? '-'
                  : _formatMilliseconds(averageCompletion.inMilliseconds),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          pickUiText(i18n, zh: '逐轮明细', en: 'Round details'),
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
      title: Text(pickUiText(i18n, zh: '摇杆手眼协调结果报告', en: 'Joystick report')),
      accent: accent,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(i18n, zh: '模式', en: 'Mode'),
              mode == _JoystickTestMode.timed
                  ? pickUiText(i18n, zh: '单位时间', en: 'Timed')
                  : pickUiText(i18n, zh: '目标总数', en: 'Target count'),
            ),
            (pickUiText(i18n, zh: '进度', en: 'Progress'), progress),
            (pickUiText(i18n, zh: '命中', en: 'Hits'), '$hits'),
            (pickUiText(i18n, zh: '射空', en: 'Shots off'), '$shotsOff'),
            (
              pickUiText(i18n, zh: '准确率', en: 'Accuracy'),
              accuracy == null ? '-' : '${accuracy.round()}%',
            ),
            (
              pickUiText(i18n, zh: '平均反应', en: 'Avg reaction'),
              averageReaction == null
                  ? '-'
                  : _formatMilliseconds(averageReaction.inMilliseconds),
            ),
            (
              pickUiText(i18n, zh: '最快反应', en: 'Best reaction'),
              bestReaction == null ? '-' : _formatMilliseconds(bestReaction),
            ),
            (
              pickUiText(i18n, zh: '假目标射击', en: 'False shots'),
              '$falseTargetShots',
            ),
            (
              pickUiText(i18n, zh: '目标大小', en: 'Target size'),
              '${targetDiameter.round()} dp',
            ),
            (
              pickUiText(i18n, zh: '目标移动', en: 'Target movement'),
              targetMovementEnabled
                  ? pickUiText(i18n, zh: '开启', en: 'On')
                  : pickUiText(i18n, zh: '关闭', en: 'Off'),
            ),
          ],
        ),
        if (reactions.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          Text(
            pickUiText(i18n, zh: '命中延迟明细', en: 'Hit latency details'),
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

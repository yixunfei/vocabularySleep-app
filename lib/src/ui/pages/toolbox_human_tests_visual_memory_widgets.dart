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
          text: pickUiText(i18n, zh: '目标', en: 'Target'),
        ),
        _VisualMemoryLegendItem(
          color: colorScheme.secondary,
          text: pickUiText(i18n, zh: '已选', en: 'Picked'),
          icon: Icons.check_rounded,
        ),
        _VisualMemoryLegendItem(
          color: colorScheme.error,
          text: pickUiText(i18n, zh: '误点', en: 'Miss'),
          icon: Icons.close_rounded,
        ),
        if (showDistractor)
          _VisualMemoryLegendItem(
            color: _VisualMemoryCardState.distractorColor,
            text: pickUiText(i18n, zh: '干扰', en: 'Distractor'),
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
      title: Text(pickUiText(i18n, zh: '视觉记忆统计报告', en: 'Visual memory report')),
      accent: accent,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(i18n, zh: '最高等级', en: 'Best level'),
              '${data.bestLevel}',
            ),
            (
              pickUiText(i18n, zh: '完成关卡', en: 'Cleared'),
              '${data.completedRounds}/${data.roundsStarted}',
            ),
            (pickUiText(i18n, zh: '回忆率', en: 'Recall'), '$recall%'),
            (pickUiText(i18n, zh: '点击准确', en: 'Accuracy'), '$accuracy%'),
            (pickUiText(i18n, zh: '总误点', en: 'Misses'), '${data.wrongTaps}'),
            (
              pickUiText(i18n, zh: '用时', en: 'Time'),
              _formatSeconds(data.duration.inMilliseconds / 1000),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _VisualMemoryReportSummary(data: data, accuracy: accuracy),
        const SizedBox(height: 14),
        Text(
          pickUiText(i18n, zh: '误点来源', en: 'Miss sources'),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(i18n, zh: '相近色', en: 'Color decoys'),
              '${data.colorWrongTaps}',
            ),
            (
              pickUiText(i18n, zh: '灰色干扰', en: 'Gray decoys'),
              '${data.distractorWrongTaps}',
            ),
            (
              pickUiText(i18n, zh: '空白格', en: 'Blank cells'),
              '${data.blankWrongTaps}',
            ),
          ],
        ),
        if (recentRounds.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          Text(
            pickUiText(i18n, zh: '最近关卡', en: 'Recent rounds'),
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
        ? pickUiText(
            i18n,
            zh: '表现稳定，可以尝试提高颜色数量或开启更高干扰强度。',
            en: 'Stable run. Try more active colors or stronger decoy intensity next.',
          )
        : pickUiText(
            i18n,
            zh: '先盯住目标色名称和色块，再扫网格位置；相近色不要急着点。',
            en: 'Anchor on the target color label and swatch first, then scan positions; slow down on similar colors.',
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
        pickUiText(
          i18n,
          zh: '$difficulty · $mode，本次近似色压力约 $pressure%。$suggestion',
          en: '$difficulty · $mode, near-color pressure was about $pressure%. $suggestion',
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
    _VisualMemoryDifficulty.relaxed => pickUiText(
      i18n,
      zh: '轻量',
      en: 'Relaxed',
    ),
    _VisualMemoryDifficulty.standard => pickUiText(
      i18n,
      zh: '标准',
      en: 'Standard',
    ),
    _VisualMemoryDifficulty.challenge => pickUiText(
      i18n,
      zh: '进阶',
      en: 'Challenge',
    ),
    _VisualMemoryDifficulty.custom => pickUiText(i18n, zh: '自定义', en: 'Custom'),
  };
}

String _visualMemoryModeLabel(AppI18n i18n, _VisualMemoryMode mode) {
  return switch (mode) {
    _VisualMemoryMode.positions => pickUiText(
      i18n,
      zh: '位置记忆',
      en: 'Positions',
    ),
    _VisualMemoryMode.colorTargets => pickUiText(
      i18n,
      zh: '彩色目标',
      en: 'Color targets',
    ),
    _VisualMemoryMode.targetColor => pickUiText(
      i18n,
      zh: '指定颜色',
      en: 'Target color',
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
        : pickUiText(
            i18n,
            zh: ' · 目标色 ${targetColor.zh}',
            en: ' · target ${targetColor.en}',
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
        pickUiText(
          i18n,
          zh: '等级 ${result.level} · ${result.gridSize}x${result.gridSize} · 目标 ${result.targets} · 误点 ${result.mistakes}$targetText',
          en: 'Level ${result.level} · ${result.gridSize}x${result.gridSize} · targets ${result.targets} · misses ${result.mistakes}$targetText',
        ),
        style: theme.textTheme.bodySmall?.copyWith(
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

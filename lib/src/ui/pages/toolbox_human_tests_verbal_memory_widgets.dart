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
              message: pickUiText(
                AppI18n(Localizations.localeOf(context).languageCode),
                zh: spec.zh,
                en: spec.en,
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
      title: Text(pickUiText(i18n, zh: '词汇记忆训练报告', en: 'Memory run report')),
      accent: accent,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(i18n, zh: '结论', en: 'Result'),
              success
                  ? pickUiText(i18n, zh: '手动结束', en: 'Ended')
                  : pickUiText(i18n, zh: '生命耗尽', en: 'Out of lives'),
            ),
            (
              pickUiText(i18n, zh: '模式', en: 'Mode'),
              _verbalMemoryModeLabel(i18n, mode),
            ),
            (pickUiText(i18n, zh: '轮次', en: 'Rounds'), '$attempts'),
            (pickUiText(i18n, zh: '正确', en: 'Correct'), '$correct'),
            (pickUiText(i18n, zh: '正确率', en: 'Accuracy'), '$accuracy%'),
            (pickUiText(i18n, zh: '剩余生命', en: 'Lives left'), '$lives'),
            (pickUiText(i18n, zh: '最高等级', en: 'Best level'), '$bestLevel'),
            (pickUiText(i18n, zh: '最佳连击', en: 'Best streak'), '$bestStreak'),
            (
              pickUiText(i18n, zh: '平均响应', en: 'Avg response'),
              averageResponse == null
                  ? '-'
                  : _formatMilliseconds(averageResponse),
            ),
            (
              pickUiText(i18n, zh: '最快响应', en: 'Best response'),
              bestResponseMs == null
                  ? '-'
                  : _formatMilliseconds(bestResponseMs!),
            ),
            (
              pickUiText(i18n, zh: '用时', en: 'Duration'),
              _formatSeconds(duration.inMilliseconds / 1000),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _VerbalMemoryReportBlock(
          title: pickUiText(i18n, zh: '结果分析', en: 'Analysis'),
          body: _analysisText(i18n, accuracy),
          accent: accent,
        ),
        const SizedBox(height: 10),
        _VerbalMemoryReportBlock(
          title: pickUiText(i18n, zh: '本轮设置', en: 'Run settings'),
          body: _settingsSummary(i18n),
          accent: accent,
        ),
        if (results.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          Text(
            pickUiText(i18n, zh: '最近轮次', en: 'Recent rounds'),
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
      return pickUiText(
        i18n,
        zh: '样本轮次较少，建议至少完成 8 到 12 轮再判断稳定水平。',
        en: 'The sample is still small. Complete at least 8-12 rounds before judging stability.',
      );
    }
    if (accuracy >= 92 && bestStreak >= 6) {
      return switch (mode) {
        _VerbalMemoryMode.words => pickUiText(
          i18n,
          zh: '词汇识别稳定，当前领域组合可继续提高基础重复率，或只选单一领域做精细辨认。',
          en: 'Word recognition is stable. Raise repeat rate or narrow to one domain for finer discrimination.',
        ),
        _VerbalMemoryMode.numbers => pickUiText(
          i18n,
          zh: '数字序列复现稳定，可提高起始位数或缩短观察时长。',
          en: 'Digit recall is stable. Raise base digits or shorten view time.',
        ),
        _VerbalMemoryMode.arrows => pickUiText(
          i18n,
          zh: '空间序列稳定，可切到八方向或继续缩短观察时长。',
          en: 'Spatial recall is stable. Switch to 8 directions or shorten view time.',
        ),
      };
    }
    if (accuracy >= 75) {
      return pickUiText(
        i18n,
        zh: '整体表现可用，但仍有波动。建议保持当前难度，先把连击稳定到 5 轮以上。',
        en: 'Performance is usable but uneven. Keep the current difficulty and stabilize a 5-round streak first.',
      );
    }
    return switch (mode) {
      _VerbalMemoryMode.words => pickUiText(
        i18n,
        zh: '主要压力来自新旧判断。建议减少领域数量或降低重复率，先建立稳定识别节奏。',
        en: 'The pressure is mainly new-vs-seen judgment. Use fewer domains or lower repeat rate first.',
      ),
      _VerbalMemoryMode.numbers => pickUiText(
        i18n,
        zh: '数字复现准确率偏低。建议降低起始位数，或者把观察时长提高到 1500ms 以上。',
        en: 'Digit recall accuracy is low. Lower base digits or raise view time above 1500ms.',
      ),
      _VerbalMemoryMode.arrows => pickUiText(
        i18n,
        zh: '空间方向顺序还不稳。建议先用四方向，等 6 个箭头稳定后再加斜向。',
        en: 'Spatial order is not steady yet. Stay on 4 directions until 6-arrow runs are stable.',
      ),
    };
  }

  String _settingsSummary(AppI18n i18n) {
    return switch (mode) {
      _VerbalMemoryMode.words => pickUiText(
        i18n,
        zh: '领域：$domainsSummary；词库量：$wordPoolSize；基础重复率：${(wordRepeatChance * 100).round()}%；舞台高度：$stageHeight dp。',
        en: 'Domains: $domainsSummary; pool: $wordPoolSize; base repeat: ${(wordRepeatChance * 100).round()}%; stage: $stageHeight dp.',
      ),
      _VerbalMemoryMode.numbers => pickUiText(
        i18n,
        zh: '起始位数：$numberBaseLength；最高序列：$maxSequenceLength；观察时长：$previewMs ms；舞台高度：$stageHeight dp。',
        en: 'Base digits: $numberBaseLength; max sequence: $maxSequenceLength; view time: $previewMs ms; stage: $stageHeight dp.',
      ),
      _VerbalMemoryMode.arrows => pickUiText(
        i18n,
        zh: '方向集合：${_verbalMemoryArrowSetLabel(i18n, arrowSet)}；最高序列：$maxSequenceLength；观察时长：$previewMs ms；舞台高度：$stageHeight dp。',
        en: 'Direction set: ${_verbalMemoryArrowSetLabel(i18n, arrowSet)}; max sequence: $maxSequenceLength; view time: $previewMs ms; stage: $stageHeight dp.',
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
                  pickUiText(
                    i18n,
                    zh: '目标：${result.expectedLabel}；输入：${result.responseLabel}；${result.detailLabel}',
                    en: 'Expected: ${result.expectedLabel}; response: ${result.responseLabel}; ${result.detailLabel}',
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

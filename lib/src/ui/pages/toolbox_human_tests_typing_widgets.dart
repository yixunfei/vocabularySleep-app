part of 'toolbox_human_tests.dart';

Widget _typingBuildSettings(
  _TypingTestCardState state,
  BuildContext context,
  AppI18n i18n,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      _typingBuildModeChips(state, context, i18n),
      const SizedBox(height: 12),
      _typingBuildLanguageTopicChips(state, context, i18n),
    ],
  );
}

Widget _typingBuildModeChips(
  _TypingTestCardState state,
  BuildContext context,
  AppI18n i18n,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        pickUiText(i18n, zh: '趣味模式', en: 'Modes'),
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _TypingMode.values
            .map(
              (mode) => ChoiceChip(
                key: ValueKey<String>('typing-mode-${mode.name}'),
                selected: state._mode == mode,
                label: Text(_typingModeLabel(i18n, mode)),
                avatar: Icon(_typingModeIcon(mode), size: 16),
                onSelected: (_) => state._setMode(mode),
              ),
            )
            .toList(growable: false),
      ),
    ],
  );
}

Widget _typingBuildLanguageTopicChips(
  _TypingTestCardState state,
  BuildContext context,
  AppI18n i18n,
) {
  final textStyle = Theme.of(
    context,
  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        pickUiText(i18n, zh: '语言', en: 'Language'),
        style: textStyle,
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _TypingLanguage.values
            .map(
              (language) => ChoiceChip(
                key: ValueKey<String>('typing-language-${language.name}'),
                selected: state._language == language,
                label: Text(_typingLanguageLabel(i18n, language)),
                onSelected: (_) => state._setLanguage(language),
              ),
            )
            .toList(growable: false),
      ),
      const SizedBox(height: 10),
      Text(
        pickUiText(i18n, zh: '内容题材', en: 'Content topic'),
        style: textStyle,
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _TypingTopic.values
            .map(
              (topic) => ChoiceChip(
                key: ValueKey<String>('typing-topic-${topic.name}'),
                selected: state._topic == topic,
                label: Text(_typingTopicLabel(i18n, topic)),
                onSelected: (_) => state._setTopic(topic),
              ),
            )
            .toList(growable: false),
      ),
      const SizedBox(height: 10),
      Text(
        pickUiText(i18n, zh: '长度', en: 'Length'),
        style: textStyle,
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _TypingLength.values
            .map(
              (length) => ChoiceChip(
                key: ValueKey<String>('typing-length-${length.name}'),
                selected: state._length == length,
                label: Text(_typingLengthLabel(i18n, length)),
                avatar: Icon(_typingLengthIcon(length), size: 16),
                onSelected: (_) => state._setLength(length),
              ),
            )
            .toList(growable: false),
      ),
    ],
  );
}

IconData _typingModeIcon(_TypingMode mode) {
  return switch (mode) {
    _TypingMode.classic => Icons.article_rounded,
    _TypingMode.sprint => Icons.bolt_rounded,
    _TypingMode.precision => Icons.gps_fixed_rounded,
    _TypingMode.blind => Icons.visibility_off_rounded,
    _TypingMode.symbols => Icons.alternate_email_rounded,
    _TypingMode.fixErrors => Icons.spellcheck_rounded,
    _TypingMode.code => Icons.code_rounded,
    _TypingMode.numbers => Icons.pin_rounded,
  };
}

IconData _typingLengthIcon(_TypingLength length) {
  return switch (length) {
    _TypingLength.short => Icons.short_text_rounded,
    _TypingLength.standard => Icons.subject_rounded,
    _TypingLength.long => Icons.notes_rounded,
  };
}

Widget _typingBuildPassageStage(
  _TypingTestCardState state,
  BuildContext context,
  AppI18n i18n,
  String target,
  String input,
  double progress,
) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final challengePrompt = state._challengePrompt(i18n, target);
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      color: colorScheme.surface,
      border: Border.all(color: _typingAccent.withValues(alpha: 0.20)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _HumanPill(
                    text: _typingModeLabel(i18n, state._mode),
                    accent: _typingAccent,
                  ),
                  _HumanPill(
                    text: _typingLanguageLabel(i18n, state._language),
                    accent: _typingAccent,
                  ),
                  _HumanPill(
                    text: _typingTopicLabel(i18n, state._topic),
                    accent: _typingAccent,
                  ),
                  _HumanPill(
                    text: _typingLengthLabel(i18n, state._length),
                    accent: _typingAccent,
                  ),
                ],
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: _typingAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: _typingAccent.withValues(alpha: 0.12),
            color: _typingAccent,
          ),
        ),
        if (challengePrompt != null) ...<Widget>[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: _typingAccent.withValues(alpha: 0.08),
              border: Border.all(color: _typingAccent.withValues(alpha: 0.16)),
            ),
            child: Text(
              challengePrompt,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        SelectableText.rich(
          TextSpan(
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.55,
              fontFamily: state._mode == _TypingMode.code ? 'monospace' : null,
            ),
            children: _typingHighlightSpans(context, target, input),
          ),
        ),
      ],
    ),
  );
}

List<TextSpan> _typingHighlightSpans(
  BuildContext context,
  String target,
  String input,
) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final targetChars = target.characters.toList(growable: false);
  final inputChars = input.characters.toList(growable: false);
  final spans = <TextSpan>[];
  for (var index = 0; index < targetChars.length; index += 1) {
    final targetChar = targetChars[index];
    final typed = index < inputChars.length;
    final correct = typed && inputChars[index] == targetChar;
    final error = typed && !correct;
    spans.add(
      TextSpan(
        text: targetChar,
        style: TextStyle(
          color: correct
              ? const Color(0xFF2F8D68)
              : error
              ? colorScheme.error
              : colorScheme.onSurface,
          backgroundColor: correct
              ? const Color(0xFF2F8D68).withValues(alpha: 0.12)
              : error
              ? colorScheme.errorContainer.withValues(alpha: 0.58)
              : index == inputChars.length
              ? _typingAccent.withValues(alpha: 0.18)
              : Colors.transparent,
          decoration: error ? TextDecoration.underline : null,
          decorationColor: colorScheme.error,
          fontWeight: index == inputChars.length
              ? FontWeight.w900
              : theme.textTheme.titleMedium?.fontWeight,
        ),
      ),
    );
  }
  if (inputChars.length > targetChars.length) {
    for (
      var index = targetChars.length;
      index < inputChars.length;
      index += 1
    ) {
      spans.add(
        TextSpan(
          text: inputChars[index],
          style: TextStyle(
            color: colorScheme.error,
            backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.58),
            decoration: TextDecoration.lineThrough,
            decorationColor: colorScheme.error,
          ),
        ),
      );
    }
  }
  return spans;
}

Widget _typingBuildReport(
  _TypingTestCardState state,
  BuildContext context,
  AppI18n i18n,
  _TypingReport report,
) {
  final theme = Theme.of(context);
  final suggestedMode = _typingSuggestedMode(report);
  return _HumanPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _typingAccent.withValues(alpha: 0.14),
              ),
              child: const Icon(Icons.insights_rounded, color: _typingAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickUiText(i18n, zh: '结果报告', en: 'Result report'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_typingGrade(i18n, report)} · ${_typingModeLabel(i18n, report.mode)} · ${_typingLanguageLabel(i18n, report.language)} · ${_typingLengthLabel(i18n, report.length)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(i18n, zh: '完成速度', en: 'Final speed'),
              '${report.wpm.round()} WPM',
            ),
            (
              pickUiText(i18n, zh: '净速度', en: 'Net speed'),
              '${report.netWpm.round()} WPM',
            ),
            (
              pickUiText(i18n, zh: '峰值速度', en: 'Peak speed'),
              '${report.peakWpm.round()} WPM',
            ),
            (
              pickUiText(i18n, zh: '字符速度', en: 'Final chars'),
              '${report.cpm.round()} CPM',
            ),
            (
              pickUiText(i18n, zh: '准确率', en: 'Accuracy'),
              '${report.accuracy.round()}%',
            ),
            (
              pickUiText(i18n, zh: '稳定性', en: 'Stability'),
              '${report.consistencyScore.round()}%',
            ),
            (
              pickUiText(i18n, zh: '完成用时', en: 'Duration'),
              state._formatDuration(report.elapsed),
            ),
            (
              pickUiText(i18n, zh: '长停顿', en: 'Long pauses'),
              '${report.longPauses}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _typingAdvice(i18n, report),
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 12),
        _typingBuildIssueBars(context, i18n, report),
        if (report.hotspots.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _typingBuildHotspots(context, i18n, report),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _HumanActionButton(
              label: pickUiText(i18n, zh: '按建议再练', en: 'Practice suggestion'),
              icon: _typingModeIcon(suggestedMode),
              onPressed: () => state._startSuggestedDrill(report),
            ),
            OutlinedButton.icon(
              onPressed: () => state._reset(pickNew: false),
              icon: const Icon(Icons.replay_rounded),
              label: Text(pickUiText(i18n, zh: '同配置重来', en: 'Retry setup')),
            ),
            OutlinedButton.icon(
              onPressed: state._reset,
              icon: const Icon(Icons.shuffle_rounded),
              label: Text(pickUiText(i18n, zh: '新语料', en: 'New content')),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _typingBuildIssueBars(
  BuildContext context,
  AppI18n i18n,
  _TypingReport report,
) {
  final theme = Theme.of(context);
  final total = math.max(report.errorCount + report.missingCount, 1);
  final ordered = <_TypingIssue>[
    _TypingIssue.letter,
    _TypingIssue.cjk,
    _TypingIssue.space,
    _TypingIssue.punctuation,
    _TypingIssue.number,
    _TypingIssue.extra,
    _TypingIssue.missing,
  ];
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        pickUiText(i18n, zh: '错误结构', en: 'Error profile'),
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 8),
      ...ordered.map((issue) {
        final value = report.issueBreakdown[issue] ?? 0;
        if (value == 0) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _TypingIssueBar(
            label: _typingIssueLabel(i18n, issue),
            value: value,
            fraction: value / total,
          ),
        );
      }),
    ],
  );
}

Widget _typingBuildHotspots(
  BuildContext context,
  AppI18n i18n,
  _TypingReport report,
) {
  final theme = Theme.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        pickUiText(i18n, zh: '错误热区', en: 'Error hotspots'),
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: report.hotspots
            .map((item) {
              final expected = item.expected.isEmpty
                  ? pickUiText(i18n, zh: '多余', en: 'Extra')
                  : item.expected;
              final typed = item.typed.isEmpty
                  ? pickUiText(i18n, zh: '漏输', en: 'Missing')
                  : item.typed;
              return _HumanPill(
                text: '$expected -> $typed x${item.count}',
                accent: Theme.of(context).colorScheme.error,
              );
            })
            .toList(growable: false),
      ),
    ],
  );
}

Widget _typingBuildRecentReports(
  _TypingTestCardState state,
  BuildContext context,
  AppI18n i18n,
) {
  final theme = Theme.of(context);
  return _HumanPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          pickUiText(i18n, zh: '本页最近结果', en: 'Recent local results'),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ...List<Widget>.generate(state._recentReports.length, (index) {
          final report = state._recentReports[index];
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${_typingModeLabel(i18n, report.mode)} · ${_typingTopicLabel(i18n, report.topic)} · ${_typingLengthLabel(i18n, report.length)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${report.netWpm.round()} WPM · ${report.accuracy.round()}% · ${report.consistencyScore.round()}%',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }),
      ],
    ),
  );
}

String _typingIssueLabel(AppI18n i18n, _TypingIssue issue) {
  return switch (issue) {
    _TypingIssue.letter => pickUiText(i18n, zh: '字母', en: 'Letters'),
    _TypingIssue.cjk => pickUiText(i18n, zh: '中日韩字符', en: 'CJK chars'),
    _TypingIssue.space => pickUiText(i18n, zh: '空格', en: 'Spaces'),
    _TypingIssue.punctuation => pickUiText(i18n, zh: '标点符号', en: 'Punctuation'),
    _TypingIssue.number => pickUiText(i18n, zh: '数字', en: 'Numbers'),
    _TypingIssue.extra => pickUiText(i18n, zh: '多余输入', en: 'Extra input'),
    _TypingIssue.missing => pickUiText(i18n, zh: '漏输', en: 'Missing'),
  };
}

class _TypingIssueBar extends StatelessWidget {
  const _TypingIssueBar({
    required this.label,
    required this.value,
    required this.fraction,
  });

  final String label;
  final int value;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$value',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: fraction.clamp(0.02, 1.0),
            color: _typingAccent,
            backgroundColor: _typingAccent.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

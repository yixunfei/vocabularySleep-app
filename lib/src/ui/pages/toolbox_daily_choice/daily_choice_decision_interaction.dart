part of 'daily_choice_hub.dart';

enum _DecisionQuickPreset { balanced, quick, highStakes, uncertain }

String _defaultDecisionOptionName(AppI18n i18n, int index) {
  const letters = <String>['A', 'B', 'C', 'D', 'E', 'F'];
  final label = index > 0 && index <= letters.length
      ? letters[index - 1]
      : '$index';
  return pickUiText(i18n, zh: '可选项 $label', en: 'Option $label');
}

Color _decisionOptionTint(ThemeData theme, Color accent) =>
    Color.lerp(accent, theme.colorScheme.tertiary, 0.28) ?? accent;

Color _decisionContextTint(ThemeData theme) => theme.colorScheme.secondary;

Color _decisionCalibrationTint(ThemeData theme) => theme.colorScheme.primary;

Color _decisionReportTint(ThemeData theme, Color accent) =>
    Color.lerp(accent, theme.colorScheme.error, 0.24) ?? accent;

Color _decisionReadableTint(ThemeData theme, Color tint) {
  return Color.lerp(tint, theme.colorScheme.onSurface, 0.42) ?? tint;
}

Color _decisionTintedSurface(ThemeData theme, Color tint, double alpha) {
  return Color.alphaBlend(
    tint.withValues(alpha: alpha),
    theme.colorScheme.surface,
  );
}

class _DecisionSectionLabel extends StatelessWidget {
  const _DecisionSectionLabel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readableTint = _decisionReadableTint(theme, tint);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _decisionTintedSurface(theme, tint, 0.10),
        borderRadius: BorderRadius.circular(ToolboxUiTokens.cardRadius),
        border: Border.all(color: readableTint.withValues(alpha: 0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: readableTint, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.92,
                      ),
                      height: 1.32,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecisionExpandIcon extends StatelessWidget {
  const _DecisionExpandIcon({
    required this.expanded,
    required this.openColor,
    required this.closedColor,
  });

  final bool expanded;
  final Color openColor;
  final Color closedColor;

  @override
  Widget build(BuildContext context) {
    final color = expanded ? openColor : closedColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: expanded ? 0.16 : 0.10),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: expanded ? 0.28 : 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          expanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          color: color,
        ),
      ),
    );
  }
}

class _DecisionQuestionFlowCard extends StatelessWidget {
  const _DecisionQuestionFlowCard({
    required this.i18n,
    required this.accent,
    required this.decisionQuestion,
    required this.contextValue,
    required this.report,
    required this.items,
    required this.activeOptionId,
    required this.draftRevision,
    required this.showFullCalibration,
    required this.onQuestionChanged,
    required this.onStakesChanged,
    required this.onUncertaintyChanged,
    required this.onReversibilityChanged,
    required this.onUrgencyChanged,
    required this.onPresetSelected,
    required this.onOptionNameChanged,
    required this.onActiveOptionChanged,
    required this.onAddOption,
    required this.onDeleteOption,
    required this.onChanged,
    required this.onToggleFullCalibration,
  });

  final AppI18n i18n;
  final Color accent;
  final String decisionQuestion;
  final DailyChoiceDecisionContext contextValue;
  final DailyChoiceDecisionReport report;
  final List<_DecisionDraft> items;
  final String activeOptionId;
  final int draftRevision;
  final bool showFullCalibration;
  final ValueChanged<String> onQuestionChanged;
  final ValueChanged<DailyChoiceDecisionLevel> onStakesChanged;
  final ValueChanged<DailyChoiceDecisionLevel> onUncertaintyChanged;
  final ValueChanged<DailyChoiceDecisionReversibility> onReversibilityChanged;
  final ValueChanged<DailyChoiceDecisionUrgency> onUrgencyChanged;
  final ValueChanged<_DecisionQuickPreset> onPresetSelected;
  final void Function(_DecisionDraft item, String value) onOptionNameChanged;
  final ValueChanged<String> onActiveOptionChanged;
  final VoidCallback? onAddOption;
  final void Function(_DecisionDraft item)? onDeleteOption;
  final VoidCallback onChanged;
  final VoidCallback onToggleFullCalibration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeItem = items.firstWhere(
      (item) => item.id == activeOptionId,
      orElse: () => items.first,
    );
    final recommended = report.recommendedMethods
        .take(3)
        .map((method) => decisionMethodSpec(method).title(i18n))
        .join(' / ');
    final highlightName = _highlightOptionName(report);
    final optionTint = _decisionOptionTint(theme, accent);
    final contextTint = _decisionContextTint(theme);
    final calibrationTint = _decisionCalibrationTint(theme);
    final readableAccent = _decisionReadableTint(theme, accent);

    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: accent.withValues(alpha: 0.22),
      shadowColor: accent,
      shadowOpacity: 0.07,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.forum_rounded, color: readableAccent, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pickUiText(i18n, zh: '快速决策', en: 'Guided decision flow'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pickUiText(
                        i18n,
                        zh: '按问题、可选项、情境和校准四步收口；高级表格按需展开。',
                        en: 'Narrow the question, options, context, and scoring. Open the table only when needed.',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DecisionSectionLabel(
            icon: Icons.edit_note_rounded,
            title: pickUiText(i18n, zh: '先写清问题', en: 'Frame the question'),
            subtitle: pickUiText(
              i18n,
              zh: '一句话说明当前要决定的事，避免在范围外来回摇摆。',
              en: 'Use one sentence so the decision does not keep drifting.',
            ),
            tint: accent,
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: ValueKey<String>('decision-question-$draftRevision'),
            initialValue: decisionQuestion,
            minLines: 1,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: pickUiText(
                i18n,
                zh: '我现在要决定什么？',
                en: 'What am I deciding?',
              ),
              hintText: pickUiText(
                i18n,
                zh: '例如：今晚要不要推进这个方案？',
                en: 'Example: should I move forward with this plan tonight?',
              ),
              isDense: true,
            ),
            onChanged: onQuestionChanged,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _DecisionQuickPreset.values
                .map(
                  (preset) => ToolboxSelectablePill(
                    selected: false,
                    tint: accent,
                    onTap: () => onPresetSelected(preset),
                    leading: Icon(_presetIcon(preset), size: 18),
                    label: Text(_presetLabel(i18n, preset)),
                    tooltip: _presetTooltip(i18n, preset),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 16),
          _DecisionQuestionStepHeader(
            number: '1',
            icon: Icons.list_alt_rounded,
            title: pickUiText(i18n, zh: '可选项', en: 'Options'),
            body: pickUiText(
              i18n,
              zh: '保留 2 到 4 个真实可做的选择；单方案时先补一个保守备选。',
              en: 'Keep 2 to 4 viable options; add a conservative fallback if needed.',
            ),
            accent: optionTint,
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < items.length; index += 1) ...<Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: _decisionTintedSurface(theme, accent, 0.18),
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: readableAccent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    key: ValueKey<String>(
                      'quick-option-$draftRevision-${items[index].id}',
                    ),
                    initialValue: items[index].name,
                    decoration: InputDecoration(
                      labelText: pickUiText(
                        i18n,
                        zh: '可选项名称',
                        en: 'Option name',
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) =>
                        onOptionNameChanged(items[index], value),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: pickUiText(
                    i18n,
                    zh: '聚焦校准',
                    en: 'Score this option',
                  ),
                  onPressed: () => onActiveOptionChanged(items[index].id),
                  icon: Icon(
                    items[index].id == activeItem.id
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: items[index].id == activeItem.id
                        ? accent
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  tooltip: pickUiText(i18n, zh: '删除方案', en: 'Delete option'),
                  onPressed: onDeleteOption == null || items.length <= 2
                      ? null
                      : () => onDeleteOption!(items[index]),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            if (index != items.length - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onAddOption,
              icon: const Icon(Icons.add_rounded),
              label: Text(pickUiText(i18n, zh: '新增可选项', en: 'Add option')),
            ),
          ),
          const SizedBox(height: 18),
          _DecisionQuestionStepHeader(
            number: '2',
            icon: Icons.rule_folder_rounded,
            title: pickUiText(i18n, zh: '情境分型', en: 'Classify the situation'),
            body: pickUiText(
              i18n,
              zh: '风险、信息差和可回头性决定优先用哪种模型。',
              en: 'Stakes, info gaps, and reversibility decide the leading lens.',
            ),
            accent: contextTint,
          ),
          const SizedBox(height: 10),
          _DecisionContextSection<DailyChoiceDecisionLevel>(
            i18n: i18n,
            accent: accent,
            titleZh: '风险级别',
            titleEn: 'Stakes',
            values: DailyChoiceDecisionLevel.values,
            selectedValue: contextValue.stakes,
            onSelected: onStakesChanged,
            labelBuilder: (value) => _decisionLevelLabel(i18n, value),
          ),
          const SizedBox(height: 12),
          _DecisionContextSection<DailyChoiceDecisionLevel>(
            i18n: i18n,
            accent: accent,
            titleZh: '不确定性',
            titleEn: 'Uncertainty',
            values: DailyChoiceDecisionLevel.values,
            selectedValue: contextValue.uncertainty,
            onSelected: onUncertaintyChanged,
            labelBuilder: (value) => _decisionUncertaintyLabel(i18n, value),
          ),
          const SizedBox(height: 12),
          _DecisionContextSection<DailyChoiceDecisionReversibility>(
            i18n: i18n,
            accent: accent,
            titleZh: '可回头性',
            titleEn: 'Reversibility',
            values: DailyChoiceDecisionReversibility.values,
            selectedValue: contextValue.reversibility,
            onSelected: onReversibilityChanged,
            labelBuilder: (value) => _decisionReversibilityLabel(i18n, value),
          ),
          const SizedBox(height: 12),
          _DecisionContextSection<DailyChoiceDecisionUrgency>(
            i18n: i18n,
            accent: accent,
            titleZh: '时间压力',
            titleEn: 'Urgency',
            values: DailyChoiceDecisionUrgency.values,
            selectedValue: contextValue.urgency,
            onSelected: onUrgencyChanged,
            labelBuilder: (value) => _decisionUrgencyLabel(i18n, value),
          ),
          const SizedBox(height: 18),
          _DecisionQuestionStepHeader(
            number: '3',
            icon: Icons.fact_check_rounded,
            title: pickUiText(
              i18n,
              zh: '逐项校准',
              en: 'Score one option at a time',
            ),
            body: pickUiText(
              i18n,
              zh: '先回答最影响结论的四项；完整校准可稍后展开。',
              en: 'Answer the four highest-impact fields first; expand the rest later.',
            ),
            accent: calibrationTint,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (item) => ToolboxSelectablePill(
                    selected: activeItem.id == item.id,
                    tint: accent,
                    onTap: () => onActiveOptionChanged(item.id),
                    label: Text(item.name.trim().isEmpty ? item.id : item.name),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          Text(
            pickUiText(
              i18n,
              zh: '当前校准：${activeItem.name.trim().isEmpty ? activeItem.id : activeItem.name}',
              en: 'Scoring: ${activeItem.name.trim().isEmpty ? activeItem.id : activeItem.name}',
            ),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: calibrationTint,
            ),
          ),
          const SizedBox(height: 8),
          _DecisionQuestionSlider(
            i18n: i18n,
            accent: accent,
            labelZh: '它成功的可能性有多高？',
            labelEn: 'How likely is success?',
            value: activeItem.successProbability,
            max: 1,
            divisions: 20,
            formatter: _formatPercent,
            onChanged: (value) {
              activeItem.successProbability = value;
              onChanged();
            },
          ),
          _DecisionQuestionSlider(
            i18n: i18n,
            accent: accent,
            labelZh: '你能执行到位吗？',
            labelEn: 'Can you execute it well?',
            value: activeItem.executionProbability,
            max: 1,
            divisions: 20,
            formatter: _formatPercent,
            onChanged: (value) {
              activeItem.executionProbability = value;
              onChanged();
            },
          ),
          _DecisionQuestionSlider(
            i18n: i18n,
            accent: accent,
            labelZh: '如果顺利，收益/价值有多大？',
            labelEn: 'If it works, how valuable is it?',
            value: activeItem.upside,
            max: 10,
            divisions: 20,
            formatter: _formatScore,
            onChanged: (value) {
              activeItem.upside = value;
              onChanged();
            },
          ),
          _DecisionQuestionSlider(
            i18n: i18n,
            accent: accent,
            labelZh: '如果不顺，代价有多大？',
            labelEn: 'If it goes badly, how costly is it?',
            value: activeItem.downside,
            max: 10,
            divisions: 20,
            formatter: _formatScore,
            onChanged: (value) {
              activeItem.downside = value;
              onChanged();
            },
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: <Widget>[
                _DecisionQuestionSlider(
                  i18n: i18n,
                  accent: accent,
                  labelZh: '投入成本有多高？',
                  labelEn: 'How much effort does it take?',
                  value: activeItem.effort,
                  max: 10,
                  divisions: 20,
                  formatter: _formatScore,
                  onChanged: (value) {
                    activeItem.effort = value;
                    onChanged();
                  },
                ),
                _DecisionQuestionSlider(
                  i18n: i18n,
                  accent: accent,
                  labelZh: '做错后还能回头吗？',
                  labelEn: 'How reversible is it?',
                  value: activeItem.reversibility,
                  max: 10,
                  divisions: 20,
                  formatter: _formatScore,
                  onChanged: (value) {
                    activeItem.reversibility = value;
                    onChanged();
                  },
                ),
                _DecisionQuestionSlider(
                  i18n: i18n,
                  accent: accent,
                  labelZh: '你对这些估计有多有把握？',
                  labelEn: 'How confident are these estimates?',
                  value: activeItem.confidence,
                  max: 1,
                  divisions: 20,
                  formatter: _formatPercent,
                  onChanged: (value) {
                    activeItem.confidence = value;
                    onChanged();
                  },
                ),
                _DecisionQuestionSlider(
                  i18n: i18n,
                  accent: accent,
                  labelZh: '事后后悔风险有多高？',
                  labelEn: 'How much regret exposure is there?',
                  value: activeItem.regret,
                  max: 10,
                  divisions: 20,
                  formatter: _formatScore,
                  onChanged: (value) {
                    activeItem.regret = value;
                    onChanged();
                  },
                ),
                _DecisionQuestionSlider(
                  i18n: i18n,
                  accent: accent,
                  labelZh: '还缺多少关键事实？',
                  labelEn: 'How large is the info gap?',
                  value: activeItem.infoGap,
                  max: 10,
                  divisions: 20,
                  formatter: _formatScore,
                  onChanged: (value) {
                    activeItem.infoGap = value;
                    onChanged();
                  },
                ),
              ],
            ),
            crossFadeState: showFullCalibration
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: AppDurations.expand,
            firstCurve: AppEasing.standard,
            secondCurve: AppEasing.standard,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onToggleFullCalibration,
              icon: Icon(
                showFullCalibration
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: showFullCalibration
                    ? calibrationTint
                    : theme.colorScheme.tertiary,
              ),
              style: TextButton.styleFrom(
                foregroundColor: showFullCalibration
                    ? calibrationTint
                    : theme.colorScheme.tertiary,
              ),
              label: Text(
                showFullCalibration
                    ? pickUiText(i18n, zh: '收起完整校准', en: 'Hide full scoring')
                    : pickUiText(i18n, zh: '展开完整校准', en: 'Open full scoring'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _DecisionInlineNotice(
            accent: accent,
            icon: report.infoSignal.shouldGatherMoreInfo
                ? Icons.manage_search_rounded
                : Icons.task_alt_rounded,
            title: report.infoSignal.shouldGatherMoreInfo
                ? pickUiText(
                    i18n,
                    zh: highlightName == null
                        ? '建议先补一条关键信息'
                        : '建议先补 $highlightName 的关键信息',
                    en: highlightName == null
                        ? 'Gather one key missing fact first'
                        : 'Gather one missing fact for $highlightName first',
                  )
                : pickUiText(i18n, zh: '当前可以先收口', en: 'Ready to narrow down'),
            body: pickUiText(
              i18n,
              zh: '推荐优先查看：$recommended。下面的报告会把所有模型放在一起对照。',
              en: 'Recommended lenses: $recommended. The report below compares every model side by side.',
            ),
          ),
        ],
      ),
    );
  }

  String? _highlightOptionName(DailyChoiceDecisionReport report) {
    final optionId = report.infoSignal.highlightOptionId;
    if (optionId == null) {
      return null;
    }
    for (final option in report.options) {
      if (option.id == optionId) {
        return option.name;
      }
    }
    return null;
  }
}

class _DecisionAdvancedEditorCard extends StatelessWidget {
  const _DecisionAdvancedEditorCard({
    required this.i18n,
    required this.accent,
    required this.items,
    required this.activeScores,
    required this.infoSignal,
    required this.method,
    required this.expanded,
    required this.draftRevision,
    required this.onToggle,
    required this.onChanged,
    required this.onDelete,
  });

  final AppI18n i18n;
  final Color accent;
  final List<_DecisionDraft> items;
  final Map<String, DailyChoiceDecisionScore> activeScores;
  final DailyChoiceDecisionInfoSignal infoSignal;
  final DailyChoiceDecisionMethod method;
  final bool expanded;
  final int draftRevision;
  final VoidCallback onToggle;
  final VoidCallback onChanged;
  final void Function(_DecisionDraft item) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final closedColor = theme.colorScheme.tertiary;
    final readableAccent = _decisionReadableTint(theme, accent);
    final readableClosedColor = _decisionReadableTint(theme, closedColor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ToolboxSurfaceCard(
          padding: const EdgeInsets.all(16),
          borderColor: accent.withValues(alpha: 0.16),
          shadowOpacity: 0.04,
          child: Row(
            children: <Widget>[
              Icon(
                Icons.table_chart_rounded,
                color: expanded ? readableAccent : readableClosedColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pickUiText(i18n, zh: '高级评分表', en: 'Advanced score table'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pickUiText(
                        i18n,
                        zh: '需要精细复盘时再展开；问答流会同步这些字段。',
                        en: 'Open for detailed review; the guided flow updates the same fields.',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ToolboxInfoPill(
                text: pickUiText(
                  i18n,
                  zh: expanded ? '已展开' : '${items.length} 个可选项',
                  en: expanded ? 'Open' : '${items.length} options',
                ),
                accent: expanded ? readableAccent : readableClosedColor,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              IconButton(
                tooltip: expanded
                    ? pickUiText(i18n, zh: '收起', en: 'Collapse')
                    : pickUiText(i18n, zh: '展开', en: 'Expand'),
                onPressed: onToggle,
                icon: _DecisionExpandIcon(
                  expanded: expanded,
                  openColor: readableAccent,
                  closedColor: readableClosedColor,
                ),
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: ToolboxUiTokens.cardSpacing),
            child: Column(
              children: <Widget>[
                for (final item in items) ...<Widget>[
                  _DecisionInputCard(
                    key: ValueKey<String>('advanced-$draftRevision-${item.id}'),
                    i18n: i18n,
                    accent: accent,
                    item: item,
                    score: activeScores[item.id],
                    infoSignal: infoSignal,
                    method: method,
                    canDelete: items.length > 2,
                    onChanged: onChanged,
                    onDelete: () => onDelete(item),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: AppDurations.expand,
          firstCurve: AppEasing.standard,
          secondCurve: AppEasing.standard,
        ),
      ],
    );
  }
}

class _DecisionReportCard extends StatelessWidget {
  const _DecisionReportCard({
    required this.i18n,
    required this.accent,
    required this.report,
    required this.activeMethod,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoiceDecisionReport report;
  final DailyChoiceDecisionMethod activeMethod;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reportTint = _decisionReportTint(theme, accent);
    final readableReportTint = _decisionReadableTint(theme, reportTint);
    final methods = <DailyChoiceDecisionMethod>[
      ...report.recommendedMethods,
      ...DailyChoiceDecisionMethod.values.where(
        (method) => !report.recommendedMethods.contains(method),
      ),
    ];
    final consensus = report.consensus;
    final stabilityText = consensus.methodCount == 0
        ? '--'
        : '${(consensus.stability * 100).round()}%';
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: accent.withValues(alpha: 0.18),
      shadowColor: accent,
      shadowOpacity: 0.06,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.assignment_rounded,
                color: readableReportTint,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pickUiText(
                        i18n,
                        zh: '决策分析摘要',
                        en: 'Decision analysis report',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pickUiText(
                        i18n,
                        zh: '先看结论、稳定度和信息价值；完整模型对照放到弹窗里。',
                        en: 'Scan the conclusion, stability, and information value first. Open the full model comparison when needed.',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DecisionInlineNotice(
            accent: reportTint,
            icon: report.infoSignal.shouldDelayDecision
                ? Icons.manage_search_rounded
                : Icons.verified_rounded,
            title: _reportActionTitle(i18n, report),
            body: _reportActionBody(i18n, report),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxInfoPill(
                text: pickUiText(
                  i18n,
                  zh: consensus.winnerName.isEmpty
                      ? '暂无共识'
                      : '共识：${consensus.winnerName}',
                  en: consensus.winnerName.isEmpty
                      ? 'No consensus yet'
                      : 'Consensus: ${consensus.winnerName}',
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: pickUiText(
                  i18n,
                  zh: '稳定度 $stabilityText',
                  en: 'Stability $stabilityText',
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: report.infoSignal.shouldGatherMoreInfo
                    ? pickUiText(i18n, zh: '信息价值偏高', en: 'High info value')
                    : pickUiText(i18n, zh: '信息差可控', en: 'Info gap controlled'),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showModelComparison(context, methods),
            icon: const Icon(Icons.open_in_full_rounded),
            label: Text(
              pickUiText(i18n, zh: '查看完整模型对照', en: 'Open model comparison'),
            ),
          ),
        ],
      ),
    );
  }

  void _showModelComparison(
    BuildContext context,
    List<DailyChoiceDecisionMethod> methods,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.74,
            minChildSize: 0.42,
            maxChildSize: 0.94,
            builder: (context, controller) {
              return ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                children: <Widget>[
                  Text(
                    pickUiText(i18n, zh: '完整模型对照', en: 'Model comparison'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '推荐模型优先展开；其余模型用于发现分歧和校验盲点。',
                      en: 'Recommended models open first; the rest expose disagreement and blind spots.',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Theme(
                    data: theme.copyWith(dividerColor: Colors.transparent),
                    child: Column(
                      children: <Widget>[
                        for (var index = 0; index < methods.length; index += 1)
                          _DecisionMethodReportTile(
                            i18n: i18n,
                            accent: accent,
                            report: report,
                            method: methods[index],
                            active: methods[index] == activeMethod,
                            initiallyExpanded:
                                index < 2 || methods[index] == activeMethod,
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _DecisionActionPlanCard extends StatelessWidget {
  const _DecisionActionPlanCard({
    required this.i18n,
    required this.accent,
    required this.decisionQuestion,
    required this.report,
    required this.draft,
    required this.expanded,
    required this.draftRevision,
    required this.onGenerate,
    required this.onToggle,
    required this.onDraftChanged,
  });

  final AppI18n i18n;
  final Color accent;
  final String decisionQuestion;
  final DailyChoiceDecisionReport report;
  final _DecisionActionDraft draft;
  final bool expanded;
  final int draftRevision;
  final VoidCallback onGenerate;
  final VoidCallback onToggle;
  final ValueChanged<_DecisionActionDraft> onDraftChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionTint = _decisionReadableTint(theme, theme.colorScheme.primary);
    final stabilityText = report.consensus.methodCount == 0
        ? '--'
        : '${(report.consensus.stability * 100).round()}%';
    final targetText = report.infoSignal.shouldGatherMoreInfo
        ? pickUiText(i18n, zh: '先补信息', en: 'Research first')
        : report.consensus.winnerName.isEmpty
        ? pickUiText(i18n, zh: '待收口', en: 'Needs narrowing')
        : pickUiText(
            i18n,
            zh: '执行：${report.consensus.winnerName}',
            en: 'Act: ${report.consensus.winnerName}',
          );
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: actionTint.withValues(alpha: 0.18),
      shadowColor: actionTint,
      shadowOpacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.rocket_launch_rounded, color: actionTint, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pickUiText(i18n, zh: '落地执行卡', en: 'Execution card'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pickUiText(
                        i18n,
                        zh: '把模型结论变成下一步、停止规则、复盘条件和失败预演。',
                        en: 'Turn the model result into a next step, stop rule, review trigger, and premortem.',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxInfoPill(
                text: targetText,
                accent: actionTint,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: pickUiText(
                  i18n,
                  zh: '稳定度 $stabilityText',
                  en: 'Stability $stabilityText',
                ),
                accent: actionTint,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: draft.hasContent
                    ? pickUiText(i18n, zh: '草案已生成', en: 'Draft ready')
                    : pickUiText(i18n, zh: '等待生成草案', en: 'No draft yet'),
                accent: actionTint,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DecisionInlineNotice(
            accent: actionTint,
            icon: report.infoSignal.shouldDelayDecision
                ? Icons.manage_search_rounded
                : Icons.task_alt_rounded,
            title: _actionPlanNoticeTitle(i18n, report),
            body: _actionPlanNoticeBody(i18n, report),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: onGenerate,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  pickUiText(i18n, zh: '生成落地草案', en: 'Generate action draft'),
                ),
              ),
              OutlinedButton.icon(
                onPressed: draft.hasContent
                    ? () => _copyExecutionBrief(context)
                    : null,
                icon: const Icon(Icons.content_copy_rounded),
                label: Text(pickUiText(i18n, zh: '复制执行简报', en: 'Copy brief')),
              ),
              TextButton.icon(
                onPressed: onToggle,
                icon: Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                ),
                label: Text(
                  expanded
                      ? pickUiText(i18n, zh: '收起草案', en: 'Hide draft')
                      : pickUiText(i18n, zh: '编辑草案', en: 'Edit draft'),
                ),
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: <Widget>[
                  _DecisionActionTextField(
                    key: ValueKey<String>('action-next-$draftRevision'),
                    label: pickUiText(i18n, zh: '下一步动作', en: 'Next action'),
                    hint: pickUiText(
                      i18n,
                      zh: '写成今天或明天能执行的一句话。',
                      en: 'Write one action you can take today or tomorrow.',
                    ),
                    value: draft.nextStep,
                    onChanged: (value) =>
                        onDraftChanged(draft.copyWith(nextStep: value)),
                  ),
                  const SizedBox(height: 10),
                  _DecisionActionTextField(
                    key: ValueKey<String>('action-evidence-$draftRevision'),
                    label: pickUiText(
                      i18n,
                      zh: '关键验证信息',
                      en: 'Key evidence to verify',
                    ),
                    hint: pickUiText(
                      i18n,
                      zh: '只写最可能改变结论的一条信息。',
                      en: 'Name the one fact most likely to change the answer.',
                    ),
                    value: draft.evidenceTask,
                    onChanged: (value) =>
                        onDraftChanged(draft.copyWith(evidenceTask: value)),
                  ),
                  const SizedBox(height: 10),
                  _DecisionActionTextField(
                    key: ValueKey<String>('action-stop-$draftRevision'),
                    label: pickUiText(i18n, zh: '停止规则', en: 'Stop rule'),
                    hint: pickUiText(
                      i18n,
                      zh: '例如到某个时间、补够几条证据或两种模型一致就停止。',
                      en: 'Use a time, evidence count, or model agreement as the stop point.',
                    ),
                    value: draft.stopRule,
                    onChanged: (value) =>
                        onDraftChanged(draft.copyWith(stopRule: value)),
                  ),
                  const SizedBox(height: 10),
                  _DecisionActionTextField(
                    key: ValueKey<String>('action-review-$draftRevision'),
                    label: pickUiText(i18n, zh: '复盘触发', en: 'Review trigger'),
                    hint: pickUiText(
                      i18n,
                      zh: '写清什么时候检查结果是否符合预期。',
                      en: 'Define when to check whether reality matched the forecast.',
                    ),
                    value: draft.reviewTrigger,
                    onChanged: (value) =>
                        onDraftChanged(draft.copyWith(reviewTrigger: value)),
                  ),
                  const SizedBox(height: 10),
                  _DecisionActionTextField(
                    key: ValueKey<String>('action-premortem-$draftRevision'),
                    label: pickUiText(i18n, zh: '失败预演', en: 'Premortem'),
                    hint: pickUiText(
                      i18n,
                      zh: '假设失败了，最可能输在哪一步？',
                      en: 'Assume it failed. Where did it most likely break?',
                    ),
                    value: draft.premortem,
                    minLines: 2,
                    onChanged: (value) =>
                        onDraftChanged(draft.copyWith(premortem: value)),
                  ),
                ],
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: AppDurations.expand,
            firstCurve: AppEasing.standard,
            secondCurve: AppEasing.standard,
          ),
        ],
      ),
    );
  }

  Future<void> _copyExecutionBrief(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _executionBriefText()));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pickUiText(i18n, zh: '已复制执行简报', en: 'Execution brief copied'),
        ),
      ),
    );
  }

  String _executionBriefText() {
    final question = decisionQuestion.trim().isEmpty
        ? pickUiText(i18n, zh: '未填写', en: 'Not specified')
        : decisionQuestion.trim();
    final consensus = report.consensus.winnerName.isEmpty
        ? pickUiText(i18n, zh: '暂无稳定共识', en: 'No stable consensus yet')
        : report.consensus.winnerName;
    final recommended = report.recommendedMethods
        .take(3)
        .map((method) => decisionMethodSpec(method).title(i18n))
        .join(' / ');
    return <String>[
      pickUiText(i18n, zh: '【决策问题】$question', en: 'Decision: $question'),
      pickUiText(i18n, zh: '【模型共识】$consensus', en: 'Consensus: $consensus'),
      pickUiText(
        i18n,
        zh: '【推荐模型】$recommended',
        en: 'Recommended lenses: $recommended',
      ),
      pickUiText(
        i18n,
        zh: '【下一步动作】${_briefValue(draft.nextStep)}',
        en: 'Next action: ${_briefValue(draft.nextStep)}',
      ),
      pickUiText(
        i18n,
        zh: '【关键验证信息】${_briefValue(draft.evidenceTask)}',
        en: 'Key evidence: ${_briefValue(draft.evidenceTask)}',
      ),
      pickUiText(
        i18n,
        zh: '【停止规则】${_briefValue(draft.stopRule)}',
        en: 'Stop rule: ${_briefValue(draft.stopRule)}',
      ),
      pickUiText(
        i18n,
        zh: '【复盘触发】${_briefValue(draft.reviewTrigger)}',
        en: 'Review trigger: ${_briefValue(draft.reviewTrigger)}',
      ),
      pickUiText(
        i18n,
        zh: '【失败预演】${_briefValue(draft.premortem)}',
        en: 'Premortem: ${_briefValue(draft.premortem)}',
      ),
    ].join('\n');
  }

  String _briefValue(String value) {
    return value.trim().isEmpty
        ? pickUiText(i18n, zh: '待填写', en: 'To fill')
        : value.trim();
  }
}

class _DecisionActionTextField extends StatelessWidget {
  const _DecisionActionTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.minLines = 1,
  });

  final String label;
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      minLines: minLines,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }
}

class _DecisionMethodReportTile extends StatefulWidget {
  const _DecisionMethodReportTile({
    required this.i18n,
    required this.accent,
    required this.report,
    required this.method,
    required this.active,
    required this.initiallyExpanded,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoiceDecisionReport report;
  final DailyChoiceDecisionMethod method;
  final bool active;
  final bool initiallyExpanded;

  @override
  State<_DecisionMethodReportTile> createState() =>
      _DecisionMethodReportTileState();
}

class _DecisionMethodReportTileState extends State<_DecisionMethodReportTile> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec = decisionMethodSpec(widget.method);
    final result = widget.report.resultFor(widget.method);
    final winner = result.winner;
    final runnerUp = result.runnerUp;
    final closedColor = theme.colorScheme.tertiary;
    final leadingText = winner == null
        ? pickUiText(widget.i18n, zh: '等待输入', en: 'Waiting for input')
        : widget.method == DailyChoiceDecisionMethod.random
        ? pickUiText(
            widget.i18n,
            zh: '每项 ${_formatPercent(winner.score)}',
            en: '${_formatPercent(winner.score)} each',
          )
        : '${winner.option.name} · ${winner.score.toStringAsFixed(2)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: (widget.active ? widget.accent : closedColor).withValues(
          alpha: _expanded ? 0.08 : 0.04,
        ),
        borderRadius: BorderRadius.circular(ToolboxUiTokens.cardRadius),
        border: Border.all(
          color: (widget.active ? widget.accent : closedColor).withValues(
            alpha: _expanded ? 0.22 : 0.12,
          ),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        initiallyExpanded: widget.initiallyExpanded,
        onExpansionChanged: (value) => setState(() => _expanded = value),
        trailing: _DecisionExpandIcon(
          expanded: _expanded,
          openColor: widget.active ? widget.accent : theme.colorScheme.primary,
          closedColor: closedColor,
        ),
        leading: Icon(
          spec.icon,
          color: widget.active ? widget.accent : closedColor,
        ),
        title: Text(
          spec.title(widget.i18n),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: widget.active ? widget.accent : null,
          ),
        ),
        subtitle: Text(
          leadingText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _methodReportSummary(widget.i18n, widget.method, result),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                if (winner != null &&
                    widget.method != DailyChoiceDecisionMethod.random)
                  Text(
                    _scoreSummary(widget.i18n, widget.method, winner),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                if (runnerUp != null &&
                    widget.method !=
                        DailyChoiceDecisionMethod.random) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    pickUiText(
                      widget.i18n,
                      zh: '领先第二名 ${runnerUp.option.name}：${result.leadMargin.toStringAsFixed(2)}。${_leadMarginAdvice(widget.i18n, result.leadMargin)}',
                      en: 'Lead over ${runnerUp.option.name}: ${result.leadMargin.toStringAsFixed(2)}. ${_leadMarginAdvice(widget.i18n, result.leadMargin)}',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _methodTrustText(widget.i18n, widget.method),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  spec.caution(widget.i18n),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                if (widget.method != DailyChoiceDecisionMethod.random &&
                    result.ranked.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  for (
                    var index = 0;
                    index < math.min(3, result.ranked.length);
                    index += 1
                  )
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: index == math.min(3, result.ranked.length) - 1
                            ? 0
                            : 6,
                      ),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: 24,
                            child: Text(
                              '${index + 1}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: widget.accent,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              result.ranked[index].option.name,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            result.ranked[index].score.toStringAsFixed(2),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: widget.accent,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionQuestionStepHeader extends StatelessWidget {
  const _DecisionQuestionStepHeader({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });

  final String number;
  final IconData icon;
  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readableAccent = _decisionReadableTint(theme, accent);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _decisionTintedSurface(theme, accent, 0.10),
        borderRadius: BorderRadius.circular(ToolboxUiTokens.cardRadius),
        border: Border.all(color: readableAccent.withValues(alpha: 0.32)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _decisionTintedSurface(theme, accent, 0.18),
                border: Border.all(
                  color: readableAccent.withValues(alpha: 0.34),
                ),
              ),
              child: Text(
                number,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: readableAccent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, color: readableAccent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.94,
                      ),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecisionQuestionSlider extends StatelessWidget {
  const _DecisionQuestionSlider({
    required this.i18n,
    required this.accent,
    required this.labelZh,
    required this.labelEn,
    required this.value,
    required this.max,
    required this.divisions,
    required this.formatter,
    required this.onChanged,
  });

  final AppI18n i18n;
  final Color accent;
  final String labelZh;
  final String labelEn;
  final double value;
  final double max;
  final int divisions;
  final String Function(double value) formatter;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = value.clamp(0.0, max).toDouble();
    final readableAccent = _decisionReadableTint(theme, accent);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  pickUiText(i18n, zh: labelZh, en: labelEn),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatter(normalized),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: readableAccent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Slider(
            value: normalized,
            min: 0,
            max: max,
            divisions: divisions,
            activeColor: readableAccent,
            label: formatter(normalized),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DecisionInlineNotice extends StatelessWidget {
  const _DecisionInlineNotice({
    required this.accent,
    required this.icon,
    required this.title,
    required this.body,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readableAccent = _decisionReadableTint(theme, accent);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _decisionTintedSurface(theme, accent, 0.10),
        borderRadius: BorderRadius.circular(ToolboxUiTokens.sectionPanelRadius),
        border: Border.all(color: readableAccent.withValues(alpha: 0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: readableAccent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.94,
                      ),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _presetIcon(_DecisionQuickPreset preset) {
  return switch (preset) {
    _DecisionQuickPreset.balanced => Icons.tune_rounded,
    _DecisionQuickPreset.quick => Icons.flash_on_rounded,
    _DecisionQuickPreset.highStakes => Icons.rule_rounded,
    _DecisionQuickPreset.uncertain => Icons.travel_explore_rounded,
  };
}

String _presetLabel(AppI18n i18n, _DecisionQuickPreset preset) {
  return switch (preset) {
    _DecisionQuickPreset.balanced => pickUiText(
      i18n,
      zh: '常规比较',
      en: 'Balanced',
    ),
    _DecisionQuickPreset.quick => pickUiText(
      i18n,
      zh: '低风险快决',
      en: 'Quick tie',
    ),
    _DecisionQuickPreset.highStakes => pickUiText(
      i18n,
      zh: '高风险稳妥',
      en: 'High stakes',
    ),
    _DecisionQuickPreset.uncertain => pickUiText(
      i18n,
      zh: '不确定先查',
      en: 'Uncertain',
    ),
  };
}

String _presetTooltip(AppI18n i18n, _DecisionQuickPreset preset) {
  return switch (preset) {
    _DecisionQuickPreset.balanced => pickUiText(
      i18n,
      zh: '用加权因素先排出优先级。',
      en: 'Rank options with weighted factors first.',
    ),
    _DecisionQuickPreset.quick => pickUiText(
      i18n,
      zh: '低风险、可回头、差别不大时尽快结束犹豫。',
      en: 'End dithering when the choice is low-stakes and reversible.',
    ),
    _DecisionQuickPreset.highStakes => pickUiText(
      i18n,
      zh: '先检查底线，再谈收益。',
      en: 'Check guardrails before chasing upside.',
    ),
    _DecisionQuickPreset.uncertain => pickUiText(
      i18n,
      zh: '让情景分析和信息价值优先。',
      en: 'Prioritize scenarios and information value.',
    ),
  };
}

String _formatPercent(double value) => '${(value * 100).round()}%';

String _formatScore(double value) =>
    value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);

String _reportActionTitle(AppI18n i18n, DailyChoiceDecisionReport report) {
  if (report.infoSignal.shouldDelayDecision) {
    return pickUiText(i18n, zh: '先补信息，再拍板', en: 'Research before committing');
  }
  if (report.consensus.stability >= 0.6 &&
      report.consensus.winnerName.isNotEmpty) {
    return pickUiText(
      i18n,
      zh: '可以围绕 ${report.consensus.winnerName} 收口',
      en: 'Narrow around ${report.consensus.winnerName}',
    );
  }
  return pickUiText(i18n, zh: '模型分歧仍需复核', en: 'Review the model disagreement');
}

String _reportActionBody(AppI18n i18n, DailyChoiceDecisionReport report) {
  String? highlight;
  final highlightId = report.infoSignal.highlightOptionId;
  if (highlightId != null) {
    for (final option in report.options) {
      if (option.id == highlightId) {
        highlight = option.name;
        break;
      }
    }
  }
  if (report.infoSignal.shouldDelayDecision) {
    return pickUiText(
      i18n,
      zh: highlight == null
          ? '当前信息价值为 ${report.infoSignal.impactScore.toStringAsFixed(2)}，先查一条最可能改变结论的事实。'
          : '当前信息价值为 ${report.infoSignal.impactScore.toStringAsFixed(2)}，优先核实 $highlight 的关键假设。',
      en: highlight == null
          ? 'Information value is ${report.infoSignal.impactScore.toStringAsFixed(2)}. Check the one fact most likely to change the conclusion.'
          : 'Information value is ${report.infoSignal.impactScore.toStringAsFixed(2)}. Verify the key assumption behind $highlight first.',
    );
  }
  if (report.consensus.winnerName.isNotEmpty) {
    return pickUiText(
      i18n,
      zh: '有 ${report.consensus.supportCount}/${report.consensus.methodCount} 个质量模型支持该方向；下一步写清执行动作和复盘条件。',
      en: '${report.consensus.supportCount}/${report.consensus.methodCount} quality models support that direction. Next, define the action and review trigger.',
    );
  }
  return pickUiText(
    i18n,
    zh: '先补充方案或重新校准概率、风险、投入和信息差，再看报告。',
    en: 'Add options or recalibrate probability, risk, effort, and info gaps, then review the report again.',
  );
}

String _actionPlanNoticeTitle(AppI18n i18n, DailyChoiceDecisionReport report) {
  if (report.infoSignal.shouldDelayDecision) {
    return pickUiText(i18n, zh: '先验证，再承诺', en: 'Verify before committing');
  }
  if (report.consensus.stability >= 0.6 &&
      report.consensus.winnerName.isNotEmpty) {
    return pickUiText(
      i18n,
      zh: '把 ${report.consensus.winnerName} 变成最小行动',
      en: 'Turn ${report.consensus.winnerName} into the smallest action',
    );
  }
  return pickUiText(i18n, zh: '先把承诺写小', en: 'Keep the commitment small');
}

String _actionPlanNoticeBody(AppI18n i18n, DailyChoiceDecisionReport report) {
  if (report.infoSignal.shouldDelayDecision) {
    return pickUiText(
      i18n,
      zh: '当前继续查证有价值，落地草案会优先生成“只补一条关键信息”的任务，避免无限搜索。',
      en: 'More research is currently valuable, so the draft starts with one targeted evidence task instead of open-ended searching.',
    );
  }
  if (report.consensus.winnerName.isNotEmpty) {
    return pickUiText(
      i18n,
      zh: '不要停在“我决定了”。生成草案后，至少留下下一步动作、停止规则和复盘触发。',
      en: 'Do not stop at “I decided.” Generate the draft, then keep a next action, stop rule, and review trigger.',
    );
  }
  return pickUiText(
    i18n,
    zh: '当前结论还不稳，先把下一步写成小动作，再回到选项或评分校准。',
    en: 'The conclusion is still unstable. Make the next step small, then revisit options or scoring.',
  );
}

String _methodReportSummary(
  AppI18n i18n,
  DailyChoiceDecisionMethod method,
  DailyChoiceDecisionMethodResult result,
) {
  final winner = result.winner?.option.name;
  return switch (method) {
    DailyChoiceDecisionMethod.random => pickUiText(
      i18n,
      zh: '随机模型不判断质量，只在低风险、可回头、差别很小时负责停止消耗。',
      en: 'Random choice does not judge quality. It only stops low-stakes, reversible dithering.',
    ),
    DailyChoiceDecisionMethod.weightedFactors => pickUiText(
      i18n,
      zh: winner == null
          ? '把收益、成功率、把握度和可回头性加总，再扣除风险、投入、后悔和信息差。'
          : '$winner 的综合拉力暂时最高，适合当作常规主结论。',
      en: winner == null
          ? 'Adds upside, odds, confidence, and reversibility, then subtracts risk, effort, regret, and info gaps.'
          : '$winner currently has the strongest composite pull.',
    ),
    DailyChoiceDecisionMethod.expectedValue => pickUiText(
      i18n,
      zh: winner == null
          ? '用概率折算收益和损失，适合能粗略估计成功率的选择。'
          : '$winner 在概率折算后的净收益更高。',
      en: winner == null
          ? 'Converts gains and losses through probability when odds can be roughly estimated.'
          : '$winner has the stronger probability-adjusted net value.',
    ),
    DailyChoiceDecisionMethod.jointProbability => pickUiText(
      i18n,
      zh: winner == null
          ? '把“判断对、执行到位、有把握”连乘，适合多条件同时成立才算成功的场景。'
          : '$winner 在多条件同时成立时仍保留较好胜率。',
      en: winner == null
          ? 'Multiplies judgment, execution, and confidence for decisions that need several conditions to line up.'
          : '$winner keeps the better chance when multiple conditions must align.',
    ),
    DailyChoiceDecisionMethod.scenarioBlend => pickUiText(
      i18n,
      zh: winner == null
          ? '同时看乐观、基准、悲观三种情景，避免只盯着最好结果。'
          : '$winner 在乐观、基准和悲观混合后更稳。',
      en: winner == null
          ? 'Blends optimistic, base, and pessimistic cases so the upside does not dominate.'
          : '$winner is stronger after blending optimistic, base, and pessimistic cases.',
    ),
    DailyChoiceDecisionMethod.regretBalance => pickUiText(
      i18n,
      zh: winner == null ? '检查未来后悔、机会成本和可回头缓冲。' : '$winner 的后悔暴露和机会成本更可控。',
      en: winner == null
          ? 'Checks future regret, opportunity cost, and reversibility buffers.'
          : '$winner has more manageable regret and opportunity-cost exposure.',
    ),
    DailyChoiceDecisionMethod.thresholdGuardrail => pickUiText(
      i18n,
      zh: winner == null
          ? '先看把握、风险、可回头和信息差是否过线，再做排序。'
          : '$winner 在底线守门下排在前面，适合高风险场景优先参考。',
      en: winner == null
          ? 'Checks confidence, downside, reversibility, and info gaps before ranking.'
          : '$winner leads under guardrails, which matters most in higher-stakes contexts.',
    ),
    DailyChoiceDecisionMethod.calibratedForecast => pickUiText(
      i18n,
      zh: winner == null ? '把过于极端的预期往均值拉回，用来削弱过度自信。' : '$winner 在校准极端预期后仍然占优。',
      en: winner == null
          ? 'Pulls extreme forecasts toward the mean to reduce overconfidence.'
          : '$winner still leads after extreme expectations are calibrated.',
    ),
  };
}

String _methodTrustText(AppI18n i18n, DailyChoiceDecisionMethod method) {
  return switch (method) {
    DailyChoiceDecisionMethod.random => pickUiText(
      i18n,
      zh: '适用：餐厅、轻量安排、可撤销小选择；不适用：高风险或难回头事项。',
      en: 'Use for restaurants, light plans, or reversible small choices. Avoid it for high-stakes calls.',
    ),
    DailyChoiceDecisionMethod.weightedFactors => pickUiText(
      i18n,
      zh: '适用：需要在多个因素之间做清晰权衡的常规选择。',
      en: 'Best when several factors need a transparent tradeoff.',
    ),
    DailyChoiceDecisionMethod.expectedValue => pickUiText(
      i18n,
      zh: '适用：收益和风险可粗略量化，且概率不是纯猜。',
      en: 'Best when value and risk can be roughly quantified and the odds are not pure guesses.',
    ),
    DailyChoiceDecisionMethod.jointProbability => pickUiText(
      i18n,
      zh: '适用：成功依赖多个环节同时成立，例如判断、资源、执行都要到位。',
      en: 'Best when success depends on multiple links such as judgment, resources, and execution.',
    ),
    DailyChoiceDecisionMethod.scenarioBlend => pickUiText(
      i18n,
      zh: '适用：不确定性高，且最坏情景真的可能改变选择。',
      en: 'Best when uncertainty is high and the pessimistic case could change the choice.',
    ),
    DailyChoiceDecisionMethod.regretBalance => pickUiText(
      i18n,
      zh: '适用：你很在意事后复盘、错失机会或长期后悔。',
      en: 'Best when future review, missed opportunity, or regret matters.',
    ),
    DailyChoiceDecisionMethod.thresholdGuardrail => pickUiText(
      i18n,
      zh: '适用：高风险、难回头、时间紧或需要先保护底线。',
      en: 'Best when stakes are high, reversal is hard, time is tight, or the floor must be protected.',
    ),
    DailyChoiceDecisionMethod.calibratedForecast => pickUiText(
      i18n,
      zh: '适用：你怀疑自己被乐观、悲观或锚定带偏。',
      en: 'Best when optimism, pessimism, or anchoring may be pulling estimates too far.',
    ),
  };
}

String _leadMarginAdvice(AppI18n i18n, double margin) {
  if (margin.abs() < 0.35) {
    return pickUiText(
      i18n,
      zh: '分差很小，适合补信息或用低风险随机收口。',
      en: 'The margin is tiny; gather more information or use random choice if stakes are low.',
    );
  }
  if (margin.abs() < 1.0) {
    return pickUiText(
      i18n,
      zh: '分差存在但不厚，建议看其他模型是否同意。',
      en: 'The lead exists but is not thick; check whether other models agree.',
    );
  }
  return pickUiText(
    i18n,
    zh: '分差较清晰，可以进入行动条件检查。',
    en: 'The lead is clear enough to move into action checks.',
  );
}

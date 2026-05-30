part of 'daily_choice_hub.dart';

enum _DecisionQuickPreset { balanced, quick, highStakes, uncertain }

String _defaultDecisionOptionName(AppI18n i18n, int index) {
  const letters = <String>['A', 'B', 'C', 'D', 'E', 'F'];
  final label = index > 0 && index <= letters.length
      ? letters[index - 1]
      : '$index';
  return i18n.t(
    'inline.plan295.daily_choice.option_label.a5f302b1c989',
    params: <String, Object?>{'label': label},
  );
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
                      i18n.t(
                        'inline.plan295.daily_choice.guided_decision_flow.9d4d2136d225',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      i18n.t(
                        'inline.plan295.daily_choice.narrow_the_question_options_context.6fda7a7217c2',
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
            title: i18n.t(
              'inline.plan295.daily_choice.frame_the_question.6faff6c92fc8',
            ),
            subtitle: i18n.t(
              'inline.plan295.daily_choice.use_one_sentence_so_the_decision_doe.dd92d73ed379',
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
              labelText: i18n.t(
                'inline.plan295.daily_choice.what_am_i_deciding.3d279b80408a',
              ),
              hintText: i18n.t(
                'inline.plan295.daily_choice.example_should_i_move_forward_with_t.c98fa235039e',
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
            title: i18n.t('inline.plan295.daily_choice.options.6bedb4ecdb4e'),
            body: i18n.t(
              'inline.plan295.daily_choice.keep_2_to_4_viable_options_add_a_con.9c745ea1ee56',
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
                      labelText: i18n.t(
                        'inline.plan295.daily_choice.option_name.934bc67687b3',
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) =>
                        onOptionNameChanged(items[index], value),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: i18n.t(
                    'inline.plan295.daily_choice.score_this_option.ecfc7884ad9a',
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
                  tooltip: i18n.t(
                    'inline.plan295.daily_choice.delete_option.80d33f3b4257',
                  ),
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
              label: Text(
                i18n.t('inline.plan295.daily_choice.add_option.263616c76e32'),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _DecisionQuestionStepHeader(
            number: '2',
            icon: Icons.rule_folder_rounded,
            title: i18n.t(
              'inline.plan295.daily_choice.classify_the_situation.44286a722650',
            ),
            body: i18n.t(
              'inline.plan295.daily_choice.stakes_info_gaps_and_reversibility_d.aecbc9b2532f',
            ),
            accent: contextTint,
          ),
          const SizedBox(height: 10),
          _DecisionContextSection<DailyChoiceDecisionLevel>(
            i18n: i18n,
            accent: accent,
            titleKey: 'inline.plan295.daily_choice.stakes.77a846ddca68',
            values: DailyChoiceDecisionLevel.values,
            selectedValue: contextValue.stakes,
            onSelected: onStakesChanged,
            labelBuilder: (value) => _decisionLevelLabel(i18n, value),
          ),
          const SizedBox(height: 12),
          _DecisionContextSection<DailyChoiceDecisionLevel>(
            i18n: i18n,
            accent: accent,
            titleKey: 'inline.plan295.daily_choice.uncertainty.fa2b24fe9b00',
            values: DailyChoiceDecisionLevel.values,
            selectedValue: contextValue.uncertainty,
            onSelected: onUncertaintyChanged,
            labelBuilder: (value) => _decisionUncertaintyLabel(i18n, value),
          ),
          const SizedBox(height: 12),
          _DecisionContextSection<DailyChoiceDecisionReversibility>(
            i18n: i18n,
            accent: accent,
            titleKey: 'inline.plan295.daily_choice.reversibility.2a2598a412f3',
            values: DailyChoiceDecisionReversibility.values,
            selectedValue: contextValue.reversibility,
            onSelected: onReversibilityChanged,
            labelBuilder: (value) => _decisionReversibilityLabel(i18n, value),
          ),
          const SizedBox(height: 12),
          _DecisionContextSection<DailyChoiceDecisionUrgency>(
            i18n: i18n,
            accent: accent,
            titleKey: 'inline.plan295.daily_choice.urgency.a1654947238a',
            values: DailyChoiceDecisionUrgency.values,
            selectedValue: contextValue.urgency,
            onSelected: onUrgencyChanged,
            labelBuilder: (value) => _decisionUrgencyLabel(i18n, value),
          ),
          const SizedBox(height: 18),
          _DecisionQuestionStepHeader(
            number: '3',
            icon: Icons.fact_check_rounded,
            title: i18n.t(
              'inline.plan295.daily_choice.score_one_option_at_a_time.75e76ecdbc35',
            ),
            body: i18n.t(
              'inline.plan295.daily_choice.answer_the_four_highest_impact_field.440a64334b14',
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
            i18n.t(
              'inline.plan295.daily_choice.scoring_activeitem_name_trim_isempty.0a5528e9c554',
              params: <String, Object?>{
                'activeItemIdActiveItem': activeItem.name.trim().isEmpty
                    ? activeItem.id
                    : activeItem.name.trim(),
              },
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
            labelKey:
                'inline.plan295.daily_choice.how_likely_is_success.8260c27b9ec4',
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
            labelKey:
                'toolbox.daily_choice.decision.question.execution_probability',
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
            labelKey:
                'inline.plan295.daily_choice.if_it_works_how_valuable_is_it.8bddf51d2832',
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
            labelKey:
                'inline.plan295.daily_choice.if_it_goes_badly_how_costly_is_it.ebbfb55dd01a',
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
                  labelKey:
                      'inline.plan295.daily_choice.how_much_effort_does_it_take.a9707a67897b',
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
                  labelKey:
                      'inline.plan295.daily_choice.how_reversible_is_it.0761b0364a0e',
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
                  labelKey:
                      'inline.plan295.daily_choice.how_confident_are_these_estimates.77998f19d96a',
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
                  labelKey:
                      'toolbox.daily_choice.decision.question.regret_exposure',
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
                  labelKey: 'toolbox.daily_choice.decision.question.info_gap',
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
                    ? i18n.t(
                        'inline.plan295.daily_choice.hide_full_scoring.00d58d0e1275',
                      )
                    : i18n.t(
                        'inline.plan295.daily_choice.open_full_scoring.8a38309d5143',
                      ),
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
                ? highlightName == null
                      ? i18n.t(
                          'inline.plan295.daily_choice.gather_one_key_missing_fact_first.00182cbe4167',
                        )
                      : i18n.t(
                          'inline.plan295.daily_choice.gather_one_missing_fact_for_highligh.1e7704d37c29',
                          params: <String, Object?>{
                            'highlightName': highlightName,
                          },
                        )
                : i18n.t(
                    'inline.plan295.daily_choice.ready_to_narrow_down.20daf2de42f3',
                  ),
            body: i18n.t(
              'inline.plan295.daily_choice.recommended_lenses_recommended_the_r.79ccb84669c2',
              params: <String, Object?>{'recommended': recommended},
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
                      i18n.t(
                        'inline.ui.pages.toolbox_daily_choice.daily_choice_decision_interaction.advanced_score_table_a11282',
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      i18n.t(
                        'inline.plan295.daily_choice.open_for_detailed_review_the_guided.6d3052bca8ea',
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
                text: expanded
                    ? i18n.t('inline.plan295.daily_choice.open.34dacfa544d1')
                    : i18n.t(
                        'inline.plan295.daily_choice.items_length_options.ebed8e40c40e',
                        params: <String, Object?>{
                          'items': items.length,
                          'items.length': items.length,
                        },
                      ),
                accent: expanded ? readableAccent : readableClosedColor,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              IconButton(
                tooltip: expanded
                    ? i18n.t(
                        'inline.plan295.daily_choice.collapse.ad0db950964e',
                      )
                    : i18n.t('inline.ui.pages.play_page.expand_33fdcb'),
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
                      i18n.t(
                        'inline.plan295.daily_choice.decision_analysis_report.a8205f6ddab8',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      i18n.t(
                        'inline.plan295.daily_choice.scan_the_conclusion_stability_and_in.369c5ef5d345',
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
                text: consensus.winnerName.isEmpty
                    ? i18n.t(
                        'inline.plan295.daily_choice.no_consensus_yet.6df11818bbc9',
                      )
                    : i18n.t(
                        'inline.plan295.daily_choice.consensus_consensus_winnername.15c320b891da',
                        params: <String, Object?>{
                          'consensusWinnerName': consensus.winnerName,
                          'consensus.winnerName': consensus.winnerName,
                        },
                      ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: i18n.t(
                  'inline.plan295.daily_choice.stability_stabilitytext.04d6310e4297',
                  params: <String, Object?>{'stabilityText': stabilityText},
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: report.infoSignal.shouldGatherMoreInfo
                    ? i18n.t(
                        'inline.plan295.daily_choice.high_info_value.aab08d78a4cc',
                      )
                    : i18n.t(
                        'inline.plan295.daily_choice.info_gap_controlled.8a012a499861',
                      ),
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
              i18n.t(
                'inline.plan295.daily_choice.open_model_comparison.8441e95adaed',
              ),
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
                    i18n.t(
                      'inline.plan295.daily_choice.model_comparison.89adccc70957',
                    ),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    i18n.t(
                      'inline.plan295.daily_choice.recommended_models_open_first_the_re.14709b14823e',
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
        ? i18n.t('inline.plan295.daily_choice.research_first.ba9299704b36')
        : report.consensus.winnerName.isEmpty
        ? i18n.t('inline.plan295.daily_choice.needs_narrowing.26ea8268b9c3')
        : i18n.t(
            'inline.plan295.daily_choice.act_report_consensus_winnername.012489cb6c90',
            params: <String, Object?>{
              'reportConsensusWinnerName': report.consensus.winnerName,
            },
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
                      i18n.t(
                        'inline.plan295.daily_choice.execution_card.a09180cc48f3',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      i18n.t(
                        'inline.plan295.daily_choice.turn_the_model_result_into_a_next_st.c2daa6c50f91',
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
                text: i18n.t(
                  'inline.plan295.daily_choice.stability_stabilitytext.04d6310e4297',
                  params: <String, Object?>{'stabilityText': stabilityText},
                ),
                accent: actionTint,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: draft.hasContent
                    ? i18n.t(
                        'inline.plan295.daily_choice.draft_ready.1e4bf8c7dc05',
                      )
                    : i18n.t(
                        'inline.plan295.daily_choice.no_draft_yet.1661b8083ea6',
                      ),
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
                  i18n.t(
                    'inline.plan295.daily_choice.generate_action_draft.c6e170ccea67',
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: draft.hasContent
                    ? () => _copyExecutionBrief(context)
                    : null,
                icon: const Icon(Icons.content_copy_rounded),
                label: Text(
                  i18n.t('inline.plan295.daily_choice.copy_brief.629ef30eaf02'),
                ),
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
                      ? i18n.t(
                          'inline.plan295.daily_choice.hide_draft.ea141c477342',
                        )
                      : i18n.t(
                          'inline.plan295.daily_choice.edit_draft.09feeb365ade',
                        ),
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
                    label: i18n.t(
                      'inline.plan295.daily_choice.next_action.00ed975ddee9',
                    ),
                    hint: i18n.t(
                      'inline.plan295.daily_choice.write_one_action_you_can_take_today.f3312bc8e37d',
                    ),
                    value: draft.nextStep,
                    onChanged: (value) =>
                        onDraftChanged(draft.copyWith(nextStep: value)),
                  ),
                  const SizedBox(height: 10),
                  _DecisionActionTextField(
                    key: ValueKey<String>('action-evidence-$draftRevision'),
                    label: i18n.t(
                      'inline.plan295.daily_choice.key_evidence_to_verify.f9774e8be627',
                    ),
                    hint: i18n.t(
                      'inline.plan295.daily_choice.name_the_one_fact_most_likely_to_cha.c263e99ab46a',
                    ),
                    value: draft.evidenceTask,
                    onChanged: (value) =>
                        onDraftChanged(draft.copyWith(evidenceTask: value)),
                  ),
                  const SizedBox(height: 10),
                  _DecisionActionTextField(
                    key: ValueKey<String>('action-stop-$draftRevision'),
                    label: i18n.t(
                      'inline.ui.pages.toolbox_daily_choice.daily_choice_decision_interaction.stop_rule_fa753d',
                    ),
                    hint: i18n.t(
                      'inline.plan295.daily_choice.use_a_time_evidence_count_or_model_a.38f688cf2d85',
                    ),
                    value: draft.stopRule,
                    onChanged: (value) =>
                        onDraftChanged(draft.copyWith(stopRule: value)),
                  ),
                  const SizedBox(height: 10),
                  _DecisionActionTextField(
                    key: ValueKey<String>('action-review-$draftRevision'),
                    label: i18n.t(
                      'inline.plan295.daily_choice.review_trigger.97342cb8fc62',
                    ),
                    hint: i18n.t(
                      'inline.plan295.daily_choice.define_when_to_check_whether_reality.391e0b1b3a13',
                    ),
                    value: draft.reviewTrigger,
                    onChanged: (value) =>
                        onDraftChanged(draft.copyWith(reviewTrigger: value)),
                  ),
                  const SizedBox(height: 10),
                  _DecisionActionTextField(
                    key: ValueKey<String>('action-premortem-$draftRevision'),
                    label: i18n.t(
                      'inline.plan295.daily_choice.premortem.222425c664dd',
                    ),
                    hint: i18n.t(
                      'inline.plan295.daily_choice.assume_it_failed_where_did_it_most_l.d0bade7a6c61',
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
          i18n.t(
            'inline.plan295.daily_choice.execution_brief_copied.beedb33d3a37',
          ),
        ),
      ),
    );
  }

  String _executionBriefText() {
    final question = decisionQuestion.trim().isEmpty
        ? i18n.t('inline.plan295.daily_choice.not_specified.1b990fe66747')
        : decisionQuestion.trim();
    final consensus = report.consensus.winnerName.isEmpty
        ? i18n.t(
            'inline.plan295.daily_choice.no_stable_consensus_yet.ea8a0c6eaa9f',
          )
        : report.consensus.winnerName;
    final recommended = report.recommendedMethods
        .take(3)
        .map((method) => decisionMethodSpec(method).title(i18n))
        .join(' / ');
    return <String>[
      i18n.t(
        'inline.plan295.daily_choice.decision_question.5f59a5e1a488',
        params: <String, Object?>{'question': question},
      ),
      i18n.t(
        'inline.plan295.daily_choice.consensus_consensus.a127c803fb92',
        params: <String, Object?>{'consensus': consensus},
      ),
      i18n.t(
        'inline.plan295.daily_choice.recommended_lenses_recommended.51d61438eb22',
        params: <String, Object?>{'recommended': recommended},
      ),
      i18n.t(
        'inline.plan295.daily_choice.next_action_briefvalue_draft_nextste.274036ed54f4',
        params: <String, Object?>{
          'briefValueDraftNextStep': _briefValue(draft.nextStep),
        },
      ),
      i18n.t(
        'inline.plan295.daily_choice.key_evidence_briefvalue_draft_eviden.441151fed3e2',
        params: <String, Object?>{
          'briefValueDraftEvidenceTask': _briefValue(draft.evidenceTask),
        },
      ),
      i18n.t(
        'inline.plan295.daily_choice.stop_rule_briefvalue_draft_stoprule.a212703b3dbc',
        params: <String, Object?>{
          'briefValueDraftStopRule': _briefValue(draft.stopRule),
        },
      ),
      i18n.t(
        'inline.plan295.daily_choice.review_trigger_briefvalue_draft_revi.529d01e07d5a',
        params: <String, Object?>{
          'briefValueDraftReviewTrigger': _briefValue(draft.reviewTrigger),
        },
      ),
      i18n.t(
        'inline.plan295.daily_choice.premortem_briefvalue_draft_premortem.d0cf33135808',
        params: <String, Object?>{
          'briefValueDraftPremortem': _briefValue(draft.premortem),
        },
      ),
    ].join('\n');
  }

  String _briefValue(String value) {
    return value.trim().isEmpty
        ? i18n.t(
            'inline.ui.pages.toolbox_daily_choice.daily_choice_decision_interaction.to_fill_00e752',
          )
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
        ? widget.i18n.t(
            'inline.ui.pages.toolbox_daily_choice.daily_choice_decision_interaction.waiting_for_input_b6faa9',
          )
        : widget.method == DailyChoiceDecisionMethod.random
        ? widget.i18n.t(
            'inline.plan295.daily_choice.formatpercent_winner_score_each.64ae961878af',
            params: <String, Object?>{
              'formatPercentWinnerScore': _formatPercent(winner.score),
            },
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
                    widget.i18n.t(
                      'inline.plan295.daily_choice.lead_over_runnerup_option_name_resul.4de5a3116fb3',
                      params: <String, Object?>{
                        'leadMarginAdviceResultLeadMargin': _leadMarginAdvice(
                          widget.i18n,
                          result.leadMargin,
                        ),
                        'resultLeadMargin': result.leadMargin.toStringAsFixed(
                          2,
                        ),
                        'runnerUpOption': runnerUp.option.name,
                      },
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
    required this.labelKey,
    required this.value,
    required this.max,
    required this.divisions,
    required this.formatter,
    required this.onChanged,
  });

  final AppI18n i18n;
  final Color accent;
  final String labelKey;
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
                  i18n.t(labelKey),
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
    _DecisionQuickPreset.balanced => i18n.t(
      'inline.plan295.daily_choice.balanced.25ab54e298ff',
    ),
    _DecisionQuickPreset.quick => i18n.t(
      'inline.plan295.daily_choice.quick_tie.930a0cb01d43',
    ),
    _DecisionQuickPreset.highStakes => i18n.t(
      'inline.plan295.daily_choice.high_stakes.824082a752c2',
    ),
    _DecisionQuickPreset.uncertain => i18n.t(
      'inline.plan295.daily_choice.uncertain.9ef42cb387ea',
    ),
  };
}

String _presetTooltip(AppI18n i18n, _DecisionQuickPreset preset) {
  return switch (preset) {
    _DecisionQuickPreset.balanced => i18n.t(
      'inline.plan295.daily_choice.rank_options_with_weighted_factors_f.4e3f91ef258f',
    ),
    _DecisionQuickPreset.quick => i18n.t(
      'inline.plan295.daily_choice.end_dithering_when_the_choice_is_low.80c2f444782f',
    ),
    _DecisionQuickPreset.highStakes => i18n.t(
      'inline.plan295.daily_choice.check_guardrails_before_chasing_upsi.93dbe12dc2d8',
    ),
    _DecisionQuickPreset.uncertain => i18n.t(
      'inline.plan295.daily_choice.prioritize_scenarios_and_information.a5198384228a',
    ),
  };
}

String _formatPercent(double value) => '${(value * 100).round()}%';

String _formatScore(double value) =>
    value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);

String _reportActionTitle(AppI18n i18n, DailyChoiceDecisionReport report) {
  if (report.infoSignal.shouldDelayDecision) {
    return i18n.t(
      'inline.plan295.daily_choice.research_before_committing.05392893029a',
    );
  }
  if (report.consensus.stability >= 0.6 &&
      report.consensus.winnerName.isNotEmpty) {
    return i18n.t(
      'inline.plan295.daily_choice.narrow_around_report_consensus_winne.dcb90e83d7ce',
      params: <String, Object?>{
        'reportConsensusWinnerName': report.consensus.winnerName,
      },
    );
  }
  return i18n.t(
    'inline.plan295.daily_choice.review_the_model_disagreement.442e66a251f0',
  );
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
    return highlight == null
        ? i18n.t(
            'inline.plan295.daily_choice.information_value_is_report_infosign.d6653124f45f',
            params: <String, Object?>{
              'reportInfoSignalImpactScore': report.infoSignal.impactScore
                  .toStringAsFixed(2),
              'report.infoSignal.impactScore.toStringAsFixed(2)': report
                  .infoSignal
                  .impactScore
                  .toStringAsFixed(2),
            },
          )
        : i18n.t(
            'inline.plan295.daily_choice.information_value_is_report_infosign.8216f998d3ef',
            params: <String, Object?>{
              'reportInfoSignalImpactScore': report.infoSignal.impactScore
                  .toStringAsFixed(2),
              'report.infoSignal.impactScore.toStringAsFixed(2)': report
                  .infoSignal
                  .impactScore
                  .toStringAsFixed(2),
              'highlight': highlight,
            },
          );
  }
  if (report.consensus.winnerName.isNotEmpty) {
    return i18n.t(
      'inline.plan295.daily_choice.report_consensus_supportcount_report.26229b88f94a',
      params: <String, Object?>{
        'reportConsensusMethodCount': report.consensus.methodCount,
        'reportConsensusSupportCount': report.consensus.supportCount,
      },
    );
  }
  return i18n.t(
    'inline.plan295.daily_choice.add_options_or_recalibrate_probabili.ee76915ccbca',
  );
}

String _actionPlanNoticeTitle(AppI18n i18n, DailyChoiceDecisionReport report) {
  if (report.infoSignal.shouldDelayDecision) {
    return i18n.t(
      'inline.plan295.daily_choice.verify_before_committing.cc6856876251',
    );
  }
  if (report.consensus.stability >= 0.6 &&
      report.consensus.winnerName.isNotEmpty) {
    return i18n.t(
      'inline.plan295.daily_choice.turn_report_consensus_winnername_int.c4fc8fe86df4',
      params: <String, Object?>{
        'reportConsensusWinnerName': report.consensus.winnerName,
      },
    );
  }
  return i18n.t(
    'inline.plan295.daily_choice.keep_the_commitment_small.77ef8f93b0e1',
  );
}

String _actionPlanNoticeBody(AppI18n i18n, DailyChoiceDecisionReport report) {
  if (report.infoSignal.shouldDelayDecision) {
    return i18n.t(
      'inline.plan295.daily_choice.more_research_is_currently_valuable.eca28f0c5a11',
    );
  }
  if (report.consensus.winnerName.isNotEmpty) {
    return i18n.t(
      'inline.plan295.daily_choice.do_not_stop_at_i_decided_generate_th.b94d17ec6815',
    );
  }
  return i18n.t(
    'inline.plan295.daily_choice.the_conclusion_is_still_unstable_mak.b6b78e91b2f0',
  );
}

String _methodReportSummary(
  AppI18n i18n,
  DailyChoiceDecisionMethod method,
  DailyChoiceDecisionMethodResult result,
) {
  final winner = result.winner?.option.name;
  return switch (method) {
    DailyChoiceDecisionMethod.random => i18n.t(
      'inline.plan295.daily_choice.random_choice_does_not_judge_quality.e4eea2a74521',
    ),
    DailyChoiceDecisionMethod.weightedFactors =>
      winner == null
          ? i18n.t(
              'inline.plan295.daily_choice.adds_upside_odds_confidence_and_reve.52a573b279fd',
            )
          : i18n.t(
              'inline.plan295.daily_choice.winner_currently_has_the_strongest_c.38e072d80809',
              params: <String, Object?>{'winner': winner},
            ),
    DailyChoiceDecisionMethod.expectedValue =>
      winner == null
          ? i18n.t(
              'inline.plan295.daily_choice.converts_gains_and_losses_through_pr.011366b59a05',
            )
          : i18n.t(
              'inline.plan295.daily_choice.winner_has_the_stronger_probability.86715e26b6bd',
              params: <String, Object?>{'winner': winner},
            ),
    DailyChoiceDecisionMethod.jointProbability =>
      winner == null
          ? i18n.t(
              'inline.plan295.daily_choice.multiplies_judgment_execution_and_co.abe56cf27065',
            )
          : i18n.t(
              'inline.plan295.daily_choice.winner_keeps_the_better_chance_when.d847d8d81c2c',
              params: <String, Object?>{'winner': winner},
            ),
    DailyChoiceDecisionMethod.scenarioBlend =>
      winner == null
          ? i18n.t(
              'inline.plan295.daily_choice.blends_optimistic_base_and_pessimist.2808e2d6f35e',
            )
          : i18n.t(
              'inline.plan295.daily_choice.winner_is_stronger_after_blending_op.1e2507ee3c4f',
              params: <String, Object?>{'winner': winner},
            ),
    DailyChoiceDecisionMethod.regretBalance =>
      winner == null
          ? i18n.t(
              'inline.plan295.daily_choice.checks_future_regret_opportunity_cos.a9c8d6c5d8d6',
            )
          : i18n.t(
              'inline.plan295.daily_choice.winner_has_more_manageable_regret_an.a07a29d55f58',
              params: <String, Object?>{'winner': winner},
            ),
    DailyChoiceDecisionMethod.thresholdGuardrail =>
      winner == null
          ? i18n.t(
              'inline.plan295.daily_choice.checks_confidence_downside_reversibi.9306fab342c0',
            )
          : i18n.t(
              'inline.plan295.daily_choice.winner_leads_under_guardrails_which.ade4d447a465',
              params: <String, Object?>{'winner': winner},
            ),
    DailyChoiceDecisionMethod.calibratedForecast =>
      winner == null
          ? i18n.t(
              'inline.plan295.daily_choice.pulls_extreme_forecasts_toward_the_m.afe7781524a9',
            )
          : i18n.t(
              'inline.plan295.daily_choice.winner_still_leads_after_extreme_exp.b7570111454d',
              params: <String, Object?>{'winner': winner},
            ),
  };
}

String _methodTrustText(AppI18n i18n, DailyChoiceDecisionMethod method) {
  return switch (method) {
    DailyChoiceDecisionMethod.random => i18n.t(
      'inline.plan295.daily_choice.use_for_restaurants_light_plans_or_r.6eba281ab953',
    ),
    DailyChoiceDecisionMethod.weightedFactors => i18n.t(
      'inline.plan295.daily_choice.best_when_several_factors_need_a_tra.a560ed7de5d6',
    ),
    DailyChoiceDecisionMethod.expectedValue => i18n.t(
      'inline.plan295.daily_choice.best_when_value_and_risk_can_be_roug.f7f9c2653a20',
    ),
    DailyChoiceDecisionMethod.jointProbability => i18n.t(
      'inline.plan295.daily_choice.best_when_success_depends_on_multipl.e2a06b30d294',
    ),
    DailyChoiceDecisionMethod.scenarioBlend => i18n.t(
      'inline.plan295.daily_choice.best_when_uncertainty_is_high_and_th.2ea420d7869a',
    ),
    DailyChoiceDecisionMethod.regretBalance => i18n.t(
      'inline.plan295.daily_choice.best_when_future_review_missed_oppor.8497ef96ed14',
    ),
    DailyChoiceDecisionMethod.thresholdGuardrail => i18n.t(
      'inline.plan295.daily_choice.best_when_stakes_are_high_reversal_i.d8749c3c786a',
    ),
    DailyChoiceDecisionMethod.calibratedForecast => i18n.t(
      'inline.plan295.daily_choice.best_when_optimism_pessimism_or_anch.bad3a3bfd55e',
    ),
  };
}

String _leadMarginAdvice(AppI18n i18n, double margin) {
  if (margin.abs() < 0.35) {
    return i18n.t(
      'inline.plan295.daily_choice.the_margin_is_tiny_gather_more_infor.4d5d5df133b9',
    );
  }
  if (margin.abs() < 1.0) {
    return i18n.t(
      'inline.plan295.daily_choice.the_lead_exists_but_is_not_thick_che.a697c09ac2b9',
    );
  }
  return i18n.t(
    'inline.plan295.daily_choice.the_lead_is_clear_enough_to_move_int.c85c4ebaba73',
  );
}

part of 'daily_choice_hub.dart';

class _DecisionDraft {
  _DecisionDraft({
    required this.id,
    required this.name,
    required this.successProbability,
    required this.executionProbability,
    required this.upside,
    required this.downside,
    required this.effort,
    required this.reversibility,
    required this.confidence,
    required this.regret,
    required this.infoGap,
  });

  final String id;
  String name;
  double successProbability;
  double executionProbability;
  double upside;
  double downside;
  double effort;
  double reversibility;
  double confidence;
  double regret;
  double infoGap;

  DailyChoiceDecisionOptionInput toInput() {
    return DailyChoiceDecisionOptionInput(
      id: id,
      name: name.trim().isEmpty ? id : name.trim(),
      successProbability: successProbability,
      executionProbability: executionProbability,
      upside: upside,
      downside: downside,
      effort: effort,
      reversibility: reversibility,
      confidence: confidence,
      regret: regret,
      infoGap: infoGap,
    );
  }
}

class _DecisionActionDraft {
  const _DecisionActionDraft({
    required this.nextStep,
    required this.evidenceTask,
    required this.stopRule,
    required this.reviewTrigger,
    required this.premortem,
  });

  const _DecisionActionDraft.empty()
    : nextStep = '',
      evidenceTask = '',
      stopRule = '',
      reviewTrigger = '',
      premortem = '';

  final String nextStep;
  final String evidenceTask;
  final String stopRule;
  final String reviewTrigger;
  final String premortem;

  bool get hasContent =>
      nextStep.trim().isNotEmpty ||
      evidenceTask.trim().isNotEmpty ||
      stopRule.trim().isNotEmpty ||
      reviewTrigger.trim().isNotEmpty ||
      premortem.trim().isNotEmpty;

  _DecisionActionDraft copyWith({
    String? nextStep,
    String? evidenceTask,
    String? stopRule,
    String? reviewTrigger,
    String? premortem,
  }) {
    return _DecisionActionDraft(
      nextStep: nextStep ?? this.nextStep,
      evidenceTask: evidenceTask ?? this.evidenceTask,
      stopRule: stopRule ?? this.stopRule,
      reviewTrigger: reviewTrigger ?? this.reviewTrigger,
      premortem: premortem ?? this.premortem,
    );
  }
}

class _DecisionAssistantModule extends StatefulWidget {
  const _DecisionAssistantModule({
    super.key,
    required this.i18n,
    required this.accent,
  });

  final AppI18n i18n;
  final Color accent;

  @override
  State<_DecisionAssistantModule> createState() =>
      _DecisionAssistantModuleState();
}

class _DecisionAssistantModuleState extends State<_DecisionAssistantModule> {
  final math.Random _random = math.Random();
  DailyChoiceDecisionMethod _method = DailyChoiceDecisionMethod.weightedFactors;
  DailyChoiceDecisionContext _context = const DailyChoiceDecisionContext();
  String _decisionQuestion = '';
  String _activeQuestionOptionId = 'plan_a';
  String? _randomPickId;
  int _draftRevision = 0;
  int _actionDraftRevision = 0;
  bool _showFullQuestionCalibration = false;
  bool _advancedEditorExpanded = false;
  bool _actionPlanExpanded = false;
  _DecisionActionDraft _actionDraft = const _DecisionActionDraft.empty();
  late List<_DecisionDraft> _items = _buildDemoItems();

  @override
  Widget build(BuildContext context) {
    final report = DailyChoiceDecisionEngine.buildReport(
      context: _context,
      options: _items.map((item) => item.toInput()).toList(growable: false),
      activeMethod: _method,
    );
    final activeResult = report.resultFor(_method);
    final activeSpec = decisionMethodSpec(_method);
    final activeScores = <String, DailyChoiceDecisionScore>{
      for (final score in activeResult.ranked) score.option.id: score,
    };
    final hygieneEntries = buildDecisionHygieneEntries(
      context: _context,
      report: report,
    );
    final randomPick = _randomPickId == null
        ? null
        : report.options.firstWhere(
            (item) => item.id == _randomPickId,
            orElse: () => report.options.first,
          );
    final activeQuestionOptionId =
        _items.any((item) => item.id == _activeQuestionOptionId)
        ? _activeQuestionOptionId
        : _items.first.id;
    final thresholdPassCount = report
        .resultFor(DailyChoiceDecisionMethod.thresholdGuardrail)
        .ranked
        .where((item) => item.passesGuardrails)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _DecisionWorkbenchCard(
          i18n: widget.i18n,
          accent: widget.accent,
          onGuide: _showGuide,
          onReset: _resetDemo,
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        _DecisionQuestionFlowCard(
          i18n: widget.i18n,
          accent: widget.accent,
          decisionQuestion: _decisionQuestion,
          contextValue: _context,
          report: report,
          items: _items,
          activeOptionId: activeQuestionOptionId,
          draftRevision: _draftRevision,
          showFullCalibration: _showFullQuestionCalibration,
          onQuestionChanged: (value) =>
              setState(() => _decisionQuestion = value),
          onStakesChanged: (value) =>
              setState(() => _context = _context.copyWith(stakes: value)),
          onUncertaintyChanged: (value) =>
              setState(() => _context = _context.copyWith(uncertainty: value)),
          onReversibilityChanged: (value) => setState(
            () => _context = _context.copyWith(reversibility: value),
          ),
          onUrgencyChanged: (value) =>
              setState(() => _context = _context.copyWith(urgency: value)),
          onPresetSelected: _applyQuickPreset,
          onOptionNameChanged: (item, value) {
            setState(() {
              item.name = value;
            });
          },
          onActiveOptionChanged: (value) =>
              setState(() => _activeQuestionOptionId = value),
          onAddOption: _items.length >= 6 ? null : _addItem,
          onDeleteOption: _deleteItem,
          onChanged: () => setState(() {}),
          onToggleFullCalibration: () => setState(
            () => _showFullQuestionCalibration = !_showFullQuestionCalibration,
          ),
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        _DecisionMethodCard(
          i18n: widget.i18n,
          accent: widget.accent,
          report: report,
          activeMethod: _method,
          activeSpec: activeSpec,
          activeResult: activeResult,
          randomPick: _method == DailyChoiceDecisionMethod.random
              ? randomPick
              : null,
          thresholdPassCount: thresholdPassCount,
          onMethodChanged: (value) {
            setState(() {
              _method = value;
              _randomPickId = null;
            });
          },
          onRandomDraw: _method == DailyChoiceDecisionMethod.random
              ? _drawRandom
              : null,
          onAddOption: _items.length >= 6 ? null : _addItem,
          onGuide: _showGuide,
          onReset: _resetDemo,
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        _DecisionReportCard(
          i18n: widget.i18n,
          accent: widget.accent,
          report: report,
          activeMethod: _method,
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        _DecisionActionPlanCard(
          i18n: widget.i18n,
          accent: widget.accent,
          decisionQuestion: _decisionQuestion,
          report: report,
          draft: _actionDraft,
          expanded: _actionPlanExpanded,
          draftRevision: _actionDraftRevision,
          onGenerate: () => _generateActionDraft(report),
          onToggle: () =>
              setState(() => _actionPlanExpanded = !_actionPlanExpanded),
          onDraftChanged: (draft) => setState(() => _actionDraft = draft),
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        _DecisionAdvancedEditorCard(
          i18n: widget.i18n,
          accent: widget.accent,
          items: _items,
          activeScores: activeScores,
          infoSignal: report.infoSignal,
          method: _method,
          expanded: _advancedEditorExpanded,
          draftRevision: _draftRevision,
          onToggle: () => setState(
            () => _advancedEditorExpanded = !_advancedEditorExpanded,
          ),
          onChanged: () => setState(() {}),
          onDelete: _deleteItem,
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        _DecisionHygieneCard(
          i18n: widget.i18n,
          accent: widget.accent,
          entries: hygieneEntries,
          showHighRiskBoundary:
              _context.stakes == DailyChoiceDecisionLevel.high,
        ),
      ],
    );
  }

  void _showGuide() {
    showDailyChoiceGuideSheet(
      context: context,
      i18n: widget.i18n,
      accent: widget.accent,
      title: widget.i18n.t(
        'inline.plan295.daily_choice.rational_decision_guide.0adbe029be76',
      ),
      modules: decisionGuideModules,
    );
  }

  void _drawRandom() {
    if (_items.isEmpty) {
      return;
    }
    setState(() {
      _randomPickId = _items[_random.nextInt(_items.length)].id;
    });
  }

  void _addItem() {
    final nextIndex = _items.length + 1;
    final nextId = 'custom_${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _items = <_DecisionDraft>[
        ..._items,
        _DecisionDraft(
          id: nextId,
          name: _defaultDecisionOptionName(widget.i18n, nextIndex),
          successProbability: 0.55,
          executionProbability: 0.60,
          upside: 6,
          downside: 4,
          effort: 4,
          reversibility: 5,
          confidence: 0.55,
          regret: 4,
          infoGap: 4,
        ),
      ];
      _activeQuestionOptionId = nextId;
    });
  }

  void _deleteItem(_DecisionDraft item) {
    if (_items.length <= 2) {
      return;
    }
    setState(() {
      _items.removeWhere((candidate) => candidate.id == item.id);
      if (_randomPickId == item.id) {
        _randomPickId = null;
      }
      if (_activeQuestionOptionId == item.id) {
        _activeQuestionOptionId = _items.first.id;
      }
    });
  }

  void _applyQuickPreset(_DecisionQuickPreset preset) {
    setState(() {
      _randomPickId = null;
      switch (preset) {
        case _DecisionQuickPreset.balanced:
          _method = DailyChoiceDecisionMethod.weightedFactors;
          _context = const DailyChoiceDecisionContext(
            stakes: DailyChoiceDecisionLevel.medium,
            uncertainty: DailyChoiceDecisionLevel.medium,
            reversibility: DailyChoiceDecisionReversibility.mixed,
            urgency: DailyChoiceDecisionUrgency.soon,
          );
        case _DecisionQuickPreset.quick:
          _method = DailyChoiceDecisionMethod.random;
          _context = const DailyChoiceDecisionContext(
            stakes: DailyChoiceDecisionLevel.low,
            uncertainty: DailyChoiceDecisionLevel.low,
            reversibility: DailyChoiceDecisionReversibility.easy,
            urgency: DailyChoiceDecisionUrgency.now,
          );
        case _DecisionQuickPreset.highStakes:
          _method = DailyChoiceDecisionMethod.thresholdGuardrail;
          _context = const DailyChoiceDecisionContext(
            stakes: DailyChoiceDecisionLevel.high,
            uncertainty: DailyChoiceDecisionLevel.medium,
            reversibility: DailyChoiceDecisionReversibility.hard,
            urgency: DailyChoiceDecisionUrgency.soon,
          );
        case _DecisionQuickPreset.uncertain:
          _method = DailyChoiceDecisionMethod.scenarioBlend;
          _context = const DailyChoiceDecisionContext(
            stakes: DailyChoiceDecisionLevel.medium,
            uncertainty: DailyChoiceDecisionLevel.high,
            reversibility: DailyChoiceDecisionReversibility.mixed,
            urgency: DailyChoiceDecisionUrgency.canWait,
          );
      }
    });
  }

  void _resetDemo() {
    setState(() {
      _method = DailyChoiceDecisionMethod.weightedFactors;
      _context = const DailyChoiceDecisionContext();
      _decisionQuestion = '';
      _activeQuestionOptionId = 'plan_a';
      _randomPickId = null;
      _draftRevision += 1;
      _actionDraftRevision += 1;
      _showFullQuestionCalibration = false;
      _advancedEditorExpanded = false;
      _actionPlanExpanded = false;
      _actionDraft = const _DecisionActionDraft.empty();
      _items = _buildDemoItems();
    });
  }

  void _generateActionDraft(DailyChoiceDecisionReport report) {
    setState(() {
      _actionDraft = _buildSuggestedActionDraft(report);
      _actionDraftRevision += 1;
      _actionPlanExpanded = true;
    });
  }

  _DecisionActionDraft _buildSuggestedActionDraft(
    DailyChoiceDecisionReport report,
  ) {
    final focus = _focusOptionForAction(report);
    final focusName = focus?.name ?? report.consensus.winnerName;
    final hasFocus = focusName.trim().isNotEmpty;
    final shouldResearch =
        report.infoSignal.shouldGatherMoreInfo ||
        report.infoSignal.shouldDelayDecision;
    final highStakes = report.context.stakes == DailyChoiceDecisionLevel.high;
    final highUncertainty =
        report.context.uncertainty == DailyChoiceDecisionLevel.high;
    final decideNow = report.context.urgency == DailyChoiceDecisionUrgency.now;

    final nextStep = shouldResearch
        ? hasFocus
              ? widget.i18n.t(
                  'inline.plan295.daily_choice.verify_the_one_fact_most_likely_to_c.9caedba50e1f',
                  params: <String, Object?>{'focusName': focusName},
                )
              : widget.i18n.t(
                  'inline.plan295.daily_choice.verify_the_one_fact_most_likely_to_c.4ff730c5da56',
                )
        : report.consensus.winnerName.isNotEmpty
        ? widget.i18n.t(
            'inline.plan295.daily_choice.take_one_small_reversible_action_aro.91849e446b6d',
          )
        : widget.i18n.t(
            'inline.plan295.daily_choice.add_viable_options_or_recalibrate_th.cea239fde266',
          );

    final evidenceTask = shouldResearch
        ? hasFocus
              ? widget.i18n.t(
                  'inline.plan295.daily_choice.research_one_fact_only_which_success.901eeb03cc73',
                  params: <String, Object?>{'focusName': focusName},
                )
              : widget.i18n.t(
                  'inline.plan295.daily_choice.research_one_fact_only_which_success.6b679f25c528',
                )
        : widget.i18n.t(
            'inline.plan295.daily_choice.write_down_the_basis_for_the_current.b098bd9ca41c',
          );

    final stopRule = decideNow
        ? widget.i18n.t(
            'inline.plan295.daily_choice.after_this_guardrail_pass_stop_addin.5a8430d0ce9f',
          )
        : shouldResearch
        ? widget.i18n.t(
            'inline.plan295.daily_choice.stop_after_one_key_fact_or_at_22_00.408d14524862',
          )
        : widget.i18n.t(
            'inline.plan295.daily_choice.add_at_most_two_more_pieces_of_evide.f23c61704ec1',
          );

    final reviewTrigger = highStakes
        ? widget.i18n.t(
            'inline.plan295.daily_choice.review_at_the_next_key_milestone_did.1c9d930bb16b',
          )
        : widget.i18n.t(
            'inline.plan295.daily_choice.review_once_24_hours_after_execution.c266e71fde47',
          );

    final premortem = highStakes
        ? widget.i18n.t(
            'inline.plan295.daily_choice.assume_this_failed_three_months_from.65936a70596a',
          )
        : highUncertainty
        ? widget.i18n.t(
            'inline.plan295.daily_choice.assume_the_result_disappoints_which.f0877e272d1a',
          )
        : widget.i18n.t(
            'inline.plan295.daily_choice.assume_tomorrow_shows_this_was_not_w.752197ac4032',
          );

    return _DecisionActionDraft(
      nextStep: nextStep,
      evidenceTask: evidenceTask,
      stopRule: stopRule,
      reviewTrigger: reviewTrigger,
      premortem: premortem,
    );
  }

  DailyChoiceDecisionOptionInput? _focusOptionForAction(
    DailyChoiceDecisionReport report,
  ) {
    final highlightId = report.infoSignal.highlightOptionId;
    if (highlightId != null) {
      for (final option in report.options) {
        if (option.id == highlightId) {
          return option;
        }
      }
    }
    if (report.consensus.winnerId.isNotEmpty) {
      for (final option in report.options) {
        if (option.id == report.consensus.winnerId) {
          return option;
        }
      }
    }
    final recommended = report.recommendedMethods.isEmpty
        ? report.activeMethod
        : report.recommendedMethods.first;
    return report.resultFor(recommended).winner?.option;
  }

  List<_DecisionDraft> _buildDemoItems() {
    return <_DecisionDraft>[
      _DecisionDraft(
        id: 'plan_a',
        name: _defaultDecisionOptionName(widget.i18n, 1),
        successProbability: 0.72,
        executionProbability: 0.78,
        upside: 8.4,
        downside: 3.2,
        effort: 4.0,
        reversibility: 7.2,
        confidence: 0.68,
        regret: 4.3,
        infoGap: 3.0,
      ),
      _DecisionDraft(
        id: 'plan_b',
        name: _defaultDecisionOptionName(widget.i18n, 2),
        successProbability: 0.58,
        executionProbability: 0.84,
        upside: 9.0,
        downside: 5.4,
        effort: 6.1,
        reversibility: 4.2,
        confidence: 0.56,
        regret: 6.5,
        infoGap: 5.2,
      ),
      _DecisionDraft(
        id: 'plan_c',
        name: _defaultDecisionOptionName(widget.i18n, 3),
        successProbability: 0.64,
        executionProbability: 0.66,
        upside: 7.1,
        downside: 2.8,
        effort: 3.6,
        reversibility: 8.3,
        confidence: 0.74,
        regret: 3.8,
        infoGap: 2.4,
      ),
    ];
  }
}

class _DecisionWorkbenchCard extends StatelessWidget {
  const _DecisionWorkbenchCard({
    required this.i18n,
    required this.accent,
    required this.onGuide,
    required this.onReset,
  });

  final AppI18n i18n;
  final Color accent;
  final VoidCallback onGuide;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(18),
      borderColor: accent.withValues(alpha: 0.22),
      shadowColor: accent,
      shadowOpacity: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      i18n.t(
                        'inline.plan295.daily_choice.decision_workbench.652abaa832fe',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      i18n.t(
                        'inline.plan295.daily_choice.separate_the_question_options_risks.17adcefeb1b1',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ToolboxIconPillButton(
                icon: Icons.menu_book_rounded,
                active: false,
                tint: accent,
                tooltip: i18n.t(
                  'inline.plan295.daily_choice.guide.c55f3c837205',
                ),
                onTap: onGuide,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxInfoPill(
                text: i18n.t(
                  'inline.plan295.daily_choice.six_elements.95a7f218e56a',
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: i18n.t(
                  'inline.plan295.daily_choice.bias_vs_noise.c8e7b75949aa',
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: i18n.t(
                  'inline.plan295.daily_choice.probability_and_scenarios.2ef8bc2bff29',
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: onGuide,
                icon: const Icon(Icons.menu_book_rounded),
                label: Text(
                  i18n.t(
                    'inline.plan295.daily_choice.rational_guide.47476a22c0eb',
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(
                  i18n.t(
                    'inline.plan295.daily_choice.reset_sample.27e2114c44ac',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _DecisionContextCard extends StatelessWidget {
  const _DecisionContextCard({
    required this.i18n,
    required this.accent,
    required this.contextValue,
    required this.onStakesChanged,
    required this.onUncertaintyChanged,
    required this.onReversibilityChanged,
    required this.onUrgencyChanged,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoiceDecisionContext contextValue;
  final ValueChanged<DailyChoiceDecisionLevel> onStakesChanged;
  final ValueChanged<DailyChoiceDecisionLevel> onUncertaintyChanged;
  final ValueChanged<DailyChoiceDecisionReversibility> onReversibilityChanged;
  final ValueChanged<DailyChoiceDecisionUrgency> onUrgencyChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: accent.withValues(alpha: 0.16),
      shadowOpacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            i18n.t(
              'inline.plan295.daily_choice.set_the_decision_context.d83a5dd79ac2',
            ),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            i18n.t(
              'inline.plan295.daily_choice.the_context_changes_which_lens_shoul.32a5147d2743',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          _DecisionContextSection<DailyChoiceDecisionLevel>(
            i18n: i18n,
            accent: accent,
            titleKey: 'inline.plan295.daily_choice.stakes.77a846ddca68',
            values: DailyChoiceDecisionLevel.values,
            selectedValue: contextValue.stakes,
            onSelected: onStakesChanged,
            labelBuilder: (value) => _decisionLevelLabel(i18n, value),
          ),
          const SizedBox(height: 14),
          _DecisionContextSection<DailyChoiceDecisionLevel>(
            i18n: i18n,
            accent: accent,
            titleKey: 'inline.plan295.daily_choice.uncertainty.fa2b24fe9b00',
            values: DailyChoiceDecisionLevel.values,
            selectedValue: contextValue.uncertainty,
            onSelected: onUncertaintyChanged,
            labelBuilder: (value) => _decisionUncertaintyLabel(i18n, value),
          ),
          const SizedBox(height: 14),
          _DecisionContextSection<DailyChoiceDecisionReversibility>(
            i18n: i18n,
            accent: accent,
            titleKey:
                'inline.plan295.daily_choice.global_reversibility.93cfac7a91b5',
            values: DailyChoiceDecisionReversibility.values,
            selectedValue: contextValue.reversibility,
            onSelected: onReversibilityChanged,
            labelBuilder: (value) => _decisionReversibilityLabel(i18n, value),
          ),
          const SizedBox(height: 14),
          _DecisionContextSection<DailyChoiceDecisionUrgency>(
            i18n: i18n,
            accent: accent,
            titleKey: 'inline.plan295.daily_choice.urgency.a1654947238a',
            values: DailyChoiceDecisionUrgency.values,
            selectedValue: contextValue.urgency,
            onSelected: onUrgencyChanged,
            labelBuilder: (value) => _decisionUrgencyLabel(i18n, value),
          ),
        ],
      ),
    );
  }
}

class _DecisionContextSection<T> extends StatelessWidget {
  const _DecisionContextSection({
    required this.i18n,
    required this.accent,
    required this.titleKey,
    required this.values,
    required this.selectedValue,
    required this.onSelected,
    required this.labelBuilder,
  });

  final AppI18n i18n;
  final Color accent;
  final String titleKey;
  final List<T> values;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final String Function(T value) labelBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          i18n.t(titleKey),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (value) => ToolboxSelectablePill(
                  selected: selectedValue == value,
                  tint: accent,
                  onTap: () => onSelected(value),
                  label: Text(labelBuilder(value)),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _DecisionMethodCard extends StatelessWidget {
  const _DecisionMethodCard({
    required this.i18n,
    required this.accent,
    required this.report,
    required this.activeMethod,
    required this.activeSpec,
    required this.activeResult,
    required this.randomPick,
    required this.thresholdPassCount,
    required this.onMethodChanged,
    required this.onRandomDraw,
    required this.onAddOption,
    required this.onGuide,
    required this.onReset,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoiceDecisionReport report;
  final DailyChoiceDecisionMethod activeMethod;
  final DailyChoiceDecisionMethodSpec activeSpec;
  final DailyChoiceDecisionMethodResult activeResult;
  final DailyChoiceDecisionOptionInput? randomPick;
  final int thresholdPassCount;
  final ValueChanged<DailyChoiceDecisionMethod> onMethodChanged;
  final VoidCallback? onRandomDraw;
  final VoidCallback? onAddOption;
  final VoidCallback onGuide;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: accent.withValues(alpha: 0.16),
      shadowOpacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            i18n.t('inline.plan295.daily_choice.decision_lens.b4dd9ca6456e'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            i18n.t(
              'inline.plan295.daily_choice.start_with_recommended_lenses_then_c.de2a6daefe92',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: report.recommendedMethods
                .map(
                  (method) => ToolboxInfoPill(
                    text: decisionMethodSpec(method).title(i18n),
                    accent: accent,
                    backgroundColor: method == activeMethod
                        ? accent.withValues(alpha: 0.14)
                        : theme.colorScheme.surfaceContainerLow,
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DailyChoiceDecisionMethod.values
                .map(
                  (method) => ToolboxSelectablePill(
                    selected: activeMethod == method,
                    tint: accent,
                    onTap: () => onMethodChanged(method),
                    leading: Icon(decisionMethodSpec(method).icon, size: 18),
                    label: Text(decisionMethodSpec(method).title(i18n)),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 16),
          _DecisionOutcomePanel(
            i18n: i18n,
            accent: accent,
            report: report,
            activeMethod: activeMethod,
            spec: activeSpec,
            result: activeResult,
            randomPick: randomPick,
            thresholdPassCount: thresholdPassCount,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              if (onRandomDraw != null)
                FilledButton.icon(
                  onPressed: onRandomDraw,
                  icon: const Icon(Icons.casino_rounded),
                  label: Text(
                    i18n.t(
                      'inline.plan295.daily_choice.draw_once.3a8ebf65e4ab',
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: onAddOption,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  i18n.t('inline.plan295.daily_choice.add_option.263616c76e32'),
                ),
              ),
              TextButton.icon(
                onPressed: onGuide,
                icon: const Icon(Icons.menu_book_rounded),
                label: Text(
                  i18n.t('inline.plan295.daily_choice.guide.e2b8ec17037f'),
                ),
              ),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(
                  i18n.t('inline.plan295.daily_choice.reset.b544c0676a8a'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DecisionOutcomePanel extends StatelessWidget {
  const _DecisionOutcomePanel({
    required this.i18n,
    required this.accent,
    required this.report,
    required this.activeMethod,
    required this.spec,
    required this.result,
    required this.randomPick,
    required this.thresholdPassCount,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoiceDecisionReport report;
  final DailyChoiceDecisionMethod activeMethod;
  final DailyChoiceDecisionMethodSpec spec;
  final DailyChoiceDecisionMethodResult result;
  final DailyChoiceDecisionOptionInput? randomPick;
  final int thresholdPassCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeWinner = result.winner;
    final recommendationTitle = switch ((
      activeMethod,
      report.infoSignal.shouldDelayDecision,
    )) {
      (_, true) => i18n.t(
        'inline.plan295.daily_choice.gather_more_info_first.65aed8f34e5c',
      ),
      (DailyChoiceDecisionMethod.random, _) when randomPick == null => i18n.t(
        'inline.plan295.daily_choice.draw_to_break_the_tie.e0e991d37cdc',
      ),
      (DailyChoiceDecisionMethod.random, _) => i18n.t(
        'inline.plan295.daily_choice.current_pick.704a7ff328a2',
      ),
      _ when activeWinner == null => i18n.t(
        'inline.ui.pages.toolbox_daily_choice.daily_choice_decision_assistant.waiting_for_inputs_28f0fe',
      ),
      _ => i18n.t(
        'inline.plan295.daily_choice.current_recommendation.1e08fa450267',
      ),
    };
    final headline = switch ((
      activeMethod,
      report.infoSignal.shouldDelayDecision,
    )) {
      (_, true) =>
        activeWinner == null
            ? i18n.t(
                'inline.plan295.daily_choice.close_the_most_important_info_gap.ec751b5f7a73',
              )
            : i18n.t(
                'inline.plan295.daily_choice.prioritize_missing_facts_for_highlig.4c883ac1e111',
              ),
      (DailyChoiceDecisionMethod.random, _) when randomPick == null => i18n.t(
        'inline.plan295.daily_choice.let_randomness_end_a_low_stakes_tie.c69c72b8f4dd',
      ),
      (DailyChoiceDecisionMethod.random, _) => randomPick!.name,
      _ when activeWinner != null =>
        '${activeWinner.option.name} · ${activeWinner.score.toStringAsFixed(2)}',
      _ => i18n.t(
        'inline.plan295.daily_choice.keep_at_least_two_options.8089b2309b71',
      ),
    };
    final supportText = switch ((
      activeMethod,
      report.infoSignal.shouldDelayDecision,
    )) {
      (_, true) =>
        activeWinner == null
            ? i18n.t(
                'inline.plan295.daily_choice.the_value_of_information_is_currentl.4d423e0fc2b8',
              )
            : i18n.t(
                'inline.plan295.daily_choice.information_value_is_report_infosign.c47489931003',
              ),
      _ => spec.subtitle(i18n),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accent.withValues(alpha: 0.18),
            theme.colorScheme.surfaceContainerLow,
          ],
        ),
        borderRadius: BorderRadius.circular(ToolboxUiTokens.sectionPanelRadius),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            recommendationTitle,
            style: theme.textTheme.labelLarge?.copyWith(
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            headline,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            supportText,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxInfoPill(
                text: i18n.t(
                  'inline.ui.pages.toolbox_daily_choice.daily_choice_decision_assistant.consensus_report_consensus_supportcount_report_consensus_33a5b4',
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surface,
              ),
              ToolboxInfoPill(
                text: i18n.t(
                  'inline.plan295.daily_choice.pass_thresholdpasscount_report_optio.2d78a1c88f67',
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surface,
              ),
              ToolboxInfoPill(
                text: report.infoSignal.shouldDelayDecision
                    ? i18n.t(
                        'inline.plan295.daily_choice.research_first.c5675290aea6',
                      )
                    : i18n.t(
                        'inline.plan295.daily_choice.ready_to_decide.ed90cc79a0a2',
                      ),
                accent: accent,
                backgroundColor: theme.colorScheme.surface,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            spec.formula(i18n),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            spec.caution(i18n),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
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

class _DecisionInputCard extends StatelessWidget {
  const _DecisionInputCard({
    super.key,
    required this.i18n,
    required this.accent,
    required this.item,
    required this.score,
    required this.infoSignal,
    required this.method,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
  });

  final AppI18n i18n;
  final Color accent;
  final _DecisionDraft item;
  final DailyChoiceDecisionScore? score;
  final DailyChoiceDecisionInfoSignal infoSignal;
  final DailyChoiceDecisionMethod method;
  final bool canDelete;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badges = <String>[
      if (method == DailyChoiceDecisionMethod.thresholdGuardrail &&
          score != null)
        score!.passesGuardrails
            ? i18n.t(
                'inline.plan295.daily_choice.passes_guardrails.86e4d953d932',
              )
            : i18n.t(
                'inline.plan295.daily_choice.fails_guardrails.caedd7f10587',
              )
      else if (score != null && method != DailyChoiceDecisionMethod.random)
        i18n.t(
          'inline.plan295.daily_choice.score_score_score_tostringasfixed_2.591dc0b4157d',
        ),
      if (infoSignal.highlightOptionId == item.id)
        i18n.t('inline.plan295.daily_choice.research_needed.dc11a2beffe7'),
    ];

    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(14),
      borderColor: accent.withValues(alpha: 0.16),
      shadowOpacity: 0.04,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  initialValue: item.name,
                  decoration: InputDecoration(
                    labelText: i18n.t(
                      'inline.ui.pages.toolbox_daily_choice.daily_choice_decision_assistant.option_9245f7',
                    ),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    item.name = value;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: i18n.t('delete'),
                onPressed: canDelete ? onDelete : null,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          if (badges.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: badges
                  .map(
                    (badge) => ToolboxInfoPill(
                      text: badge,
                      accent: accent,
                      backgroundColor: theme.colorScheme.surfaceContainerLow,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            i18n.t(
              'inline.plan295.daily_choice.use_0_1_for_success_execution_and_co.a155fcee013d',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _NumberField(
                label: i18n.t('inline.plan295.daily_choice.p.eee4d085f8fc'),
                value: item.successProbability,
                onChanged: (value) {
                  item.successProbability = value;
                  onChanged();
                },
              ),
              _NumberField(
                label: i18n.t(
                  'inline.ui.pages.toolbox_daily_choice.daily_choice_decision_assistant.exec_69da70',
                ),
                value: item.executionProbability,
                onChanged: (value) {
                  item.executionProbability = value;
                  onChanged();
                },
              ),
              _NumberField(
                label: i18n.t('inline.plan295.daily_choice.conf.c2ae9d92e0b6'),
                value: item.confidence,
                onChanged: (value) {
                  item.confidence = value;
                  onChanged();
                },
              ),
              _NumberField(
                label: i18n.t(
                  'inline.plan295.daily_choice.upside.a6007c10d7ff',
                ),
                value: item.upside,
                onChanged: (value) {
                  item.upside = value;
                  onChanged();
                },
              ),
              _NumberField(
                label: i18n.t('inline.plan295.daily_choice.down.eb143dfedb93'),
                value: item.downside,
                onChanged: (value) {
                  item.downside = value;
                  onChanged();
                },
              ),
              _NumberField(
                label: i18n.t(
                  'inline.plan295.daily_choice.effort.7ad89e9156b7',
                ),
                value: item.effort,
                onChanged: (value) {
                  item.effort = value;
                  onChanged();
                },
              ),
              _NumberField(
                label: i18n.t('inline.plan295.daily_choice.undo.6186447eec1d'),
                value: item.reversibility,
                onChanged: (value) {
                  item.reversibility = value;
                  onChanged();
                },
              ),
              _NumberField(
                label: i18n.t(
                  'inline.ui.pages.toolbox_daily_choice.daily_choice_decision_assistant.regret_e436ea',
                ),
                value: item.regret,
                onChanged: (value) {
                  item.regret = value;
                  onChanged();
                },
              ),
              _NumberField(
                label: i18n.t('inline.plan295.daily_choice.info.06ab22dc7ecf'),
                value: item.infoGap,
                onChanged: (value) {
                  item.infoGap = value;
                  onChanged();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _DecisionRankingCard extends StatelessWidget {
  const _DecisionRankingCard({
    required this.i18n,
    required this.accent,
    required this.method,
    required this.spec,
    required this.result,
    required this.consensus,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoiceDecisionMethod method;
  final DailyChoiceDecisionMethodSpec spec;
  final DailyChoiceDecisionMethodResult result;
  final DailyChoiceDecisionConsensus consensus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: accent.withValues(alpha: 0.16),
      shadowOpacity: 0.04,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            i18n.t(
              'inline.plan295.daily_choice.transparent_ranking.7d03f1f00916',
            ),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            spec.subtitle(i18n),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          if (method == DailyChoiceDecisionMethod.random)
            Text(
              consensus.winnerName.isEmpty
                  ? i18n.t(
                      'inline.plan295.daily_choice.random_mode_does_not_rank_quality_it.9de9b506f5c6',
                    )
                  : i18n.t(
                      'inline.plan295.daily_choice.random_mode_does_not_rank_quality_fo.7e9d681a3081',
                      params: <String, Object?>{
                        'consensus.winnerName': consensus.winnerName,
                      },
                    ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (var index = 0; index < result.ranked.length; index += 1)
              Padding(
                padding: EdgeInsets.only(
                  bottom: index == result.ranked.length - 1 ? 0 : 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: accent.withValues(alpha: 0.16),
                          child: Text(
                            '${index + 1}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            result.ranked[index].option.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          result.ranked[index].score.toStringAsFixed(2),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _scoreSummary(i18n, method, result.ranked[index]),
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
    );
  }
}

class _DecisionHygieneCard extends StatelessWidget {
  const _DecisionHygieneCard({
    required this.i18n,
    required this.accent,
    required this.entries,
    required this.showHighRiskBoundary,
  });

  final AppI18n i18n;
  final Color accent;
  final List<DailyChoiceGuideEntry> entries;
  final bool showHighRiskBoundary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cautionTint = showHighRiskBoundary
        ? theme.colorScheme.error
        : theme.colorScheme.tertiary;
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: cautionTint.withValues(alpha: 0.18),
      shadowOpacity: 0.04,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.health_and_safety_rounded, color: cautionTint),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  i18n.t(
                    'inline.plan295.daily_choice.decision_hygiene.c56f14a721b9',
                  ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ToolboxInfoPill(
                text: i18n.t(
                  'inline.plan295.daily_choice.entries_length_checks.2d24b95c1bc6',
                ),
                accent: cautionTint,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            showHighRiskBoundary
                ? i18n.t(
                    'inline.plan295.daily_choice.for_high_stakes_calls_check_guardrai.619c17ed042c',
                  )
                : i18n.t(
                    'inline.plan295.daily_choice.before_committing_scan_bias_noise_an.98543b80bd4a',
                  ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          if (showHighRiskBoundary) ...<Widget>[
            const SizedBox(height: 12),
            _DecisionInlineNotice(
              accent: cautionTint,
              icon: Icons.warning_amber_rounded,
              title: i18n.t(
                'inline.ui.pages.toolbox_daily_choice.daily_choice_decision_assistant.high_stakes_reminder_e88bac',
              ),
              body: i18n.t(
                'inline.plan295.daily_choice.for_medical_legal_or_financial_calls.498474374f7c',
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showChecklist(context),
            icon: const Icon(Icons.checklist_rounded),
            label: Text(
              i18n.t('inline.plan295.daily_choice.open_checklist.345be8b5fb35'),
            ),
          ),
        ],
      ),
    );
  }

  void _showChecklist(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.70,
            minChildSize: 0.40,
            maxChildSize: 0.92,
            builder: (context, controller) {
              return ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                children: <Widget>[
                  Text(
                    i18n.t(
                      'inline.plan295.daily_choice.decision_checklist.d51fd37067e5',
                    ),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (
                    var index = 0;
                    index < entries.length;
                    index += 1
                  ) ...<Widget>[
                    _DecisionInlineNotice(
                      accent: accent,
                      icon: entries[index].icon,
                      title: entries[index].title(i18n),
                      body: entries[index].body(i18n),
                    ),
                    if (index != entries.length - 1) const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: TextFormField(
        key: ValueKey<String>('$label-$value'),
        initialValue: value.toStringAsFixed(
          value == value.roundToDouble() ? 0 : 2,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, isDense: true),
        onChanged: (raw) {
          final parsed = double.tryParse(raw.trim());
          if (parsed == null) {
            return;
          }
          onChanged(parsed);
        },
      ),
    );
  }
}

String _decisionLevelLabel(AppI18n i18n, DailyChoiceDecisionLevel value) {
  return switch (value) {
    DailyChoiceDecisionLevel.low => i18n.t(
      'inline.plan295.daily_choice.low.07a2ed959563',
    ),
    DailyChoiceDecisionLevel.medium => i18n.t(
      'inline.plan295.daily_choice.medium.bb65dfe59b4c',
    ),
    DailyChoiceDecisionLevel.high => i18n.t(
      'inline.plan295.daily_choice.high.19f4cbaf6366',
    ),
  };
}

String _decisionUncertaintyLabel(AppI18n i18n, DailyChoiceDecisionLevel value) {
  return switch (value) {
    DailyChoiceDecisionLevel.low => i18n.t(
      'inline.plan295.daily_choice.low_uncertainty.2174704c33e1',
    ),
    DailyChoiceDecisionLevel.medium => i18n.t(
      'inline.plan295.daily_choice.medium_uncertainty.06515c9c82f7',
    ),
    DailyChoiceDecisionLevel.high => i18n.t(
      'inline.plan295.daily_choice.high_uncertainty.95c36a8bdb7f',
    ),
  };
}

String _decisionReversibilityLabel(
  AppI18n i18n,
  DailyChoiceDecisionReversibility value,
) {
  return switch (value) {
    DailyChoiceDecisionReversibility.easy => i18n.t(
      'inline.plan295.daily_choice.easy_to_undo.b52f9f52e5fb',
    ),
    DailyChoiceDecisionReversibility.mixed => i18n.t(
      'inline.plan295.daily_choice.partly_undoable.00e38f894ca9',
    ),
    DailyChoiceDecisionReversibility.hard => i18n.t(
      'inline.plan295.daily_choice.hard_to_undo.6b257ba68877',
    ),
  };
}

String _decisionUrgencyLabel(AppI18n i18n, DailyChoiceDecisionUrgency value) {
  return switch (value) {
    DailyChoiceDecisionUrgency.now => i18n.t(
      'inline.plan295.daily_choice.decide_now.6d76b70bfe18',
    ),
    DailyChoiceDecisionUrgency.soon => i18n.t(
      'inline.plan295.daily_choice.soon.ecf448027cb2',
    ),
    DailyChoiceDecisionUrgency.canWait => i18n.t(
      'inline.plan295.daily_choice.can_wait.c0dae3aae0d9',
    ),
  };
}

String _scoreSummary(
  AppI18n i18n,
  DailyChoiceDecisionMethod method,
  DailyChoiceDecisionScore score,
) {
  final metrics = score.metrics;
  return switch (method) {
    DailyChoiceDecisionMethod.weightedFactors => i18n.t(
      'inline.plan296.ui.pages.toolbox.daily.choice.daily.choice.decision.assistant.positive_pull_penalties.9259c1b658',
      params: <String, Object?>{
        'p0': metrics['positivePull']?.toStringAsFixed(2) ?? '--',
        'p1': metrics['negativePull']?.toStringAsFixed(2) ?? '--',
      },
    ),
    DailyChoiceDecisionMethod.expectedValue => i18n.t(
      'inline.plan296.ui.pages.toolbox.daily.choice.daily.choice.decision.assistant.effective_success_gain_loss.e0d883d32c',
      params: <String, Object?>{
        'p0': metrics['effectiveSuccess']?.toStringAsFixed(2) ?? '--',
        'p1': metrics['expectedGain']?.toStringAsFixed(2) ?? '--',
        'p2': metrics['expectedLoss']?.toStringAsFixed(2) ?? '--',
      },
    ),
    DailyChoiceDecisionMethod.jointProbability => i18n.t(
      'inline.plan296.ui.pages.toolbox.daily.choice.daily.choice.decision.assistant.joint_success_downside.923a9e726e',
      params: <String, Object?>{
        'p0': metrics['jointProbability']?.toStringAsFixed(2) ?? '--',
        'p1': metrics['downsideExposure']?.toStringAsFixed(2) ?? '--',
      },
    ),
    DailyChoiceDecisionMethod.scenarioBlend => i18n.t(
      'inline.plan296.ui.pages.toolbox.daily.choice.daily.choice.decision.assistant.opt_base_pess.dde87ae645',
      params: <String, Object?>{
        'p0': metrics['optimistic']?.toStringAsFixed(1) ?? '--',
        'p1': metrics['baseline']?.toStringAsFixed(1) ?? '--',
        'p2': metrics['pessimistic']?.toStringAsFixed(1) ?? '--',
      },
    ),
    DailyChoiceDecisionMethod.regretBalance => i18n.t(
      'inline.plan296.ui.pages.toolbox.daily.choice.daily.choice.decision.assistant.realized_upside_regret_opportunity_cost.f7abb5c8c3',
      params: <String, Object?>{
        'p0': metrics['realizedPotential']?.toStringAsFixed(2) ?? '--',
        'p1': metrics['missPenalty']?.toStringAsFixed(2) ?? '--',
        'p2': metrics['opportunityCost']?.toStringAsFixed(2) ?? '--',
      },
    ),
    DailyChoiceDecisionMethod.thresholdGuardrail =>
      score.passesGuardrails
          ? i18n.t(
              'inline.plan296.ui.pages.toolbox.daily.choice.daily.choice.decision.assistant.passed_4_guardrails_fallback.4a279bacb6',
              params: <String, Object?>{
                'p0': metrics['passCount']?.toStringAsFixed(0) ?? '0',
                'p1': metrics['weightedFallback']?.toStringAsFixed(2) ?? '--',
              },
            )
          : i18n.t(
              'toolbox.daily_choice.decision.guardrail.fails',
              params: <String, Object?>{
                'items': score.failedGuardrails
                    .map((item) => _guardrailLabel(i18n, item))
                    .join(
                      AppI18n.normalizeLanguageCode(i18n.languageCode) == 'zh'
                          ? '、'
                          : ', ',
                    ),
              },
            ),
    DailyChoiceDecisionMethod.calibratedForecast => i18n.t(
      'inline.plan296.ui.pages.toolbox.daily.choice.daily.choice.decision.assistant.raw_expected_calibrated.7e45ff7c23',
      params: <String, Object?>{
        'p0': metrics['rawExpected']?.toStringAsFixed(2) ?? '--',
        'p1': score.score.toStringAsFixed(2),
      },
    ),
    DailyChoiceDecisionMethod.random => i18n.t(
      'inline.plan295.daily_choice.random_mode_does_not_rank_quality.1ce15fffa235',
    ),
  };
}

String _guardrailLabel(AppI18n i18n, DailyChoiceDecisionGuardrailType value) {
  return switch (value) {
    DailyChoiceDecisionGuardrailType.confidence => i18n.t(
      'inline.plan295.daily_choice.confidence.d84ce8925edc',
    ),
    DailyChoiceDecisionGuardrailType.downside => i18n.t(
      'inline.plan295.daily_choice.downside.d4cc77348c3d',
    ),
    DailyChoiceDecisionGuardrailType.reversibility => i18n.t(
      'inline.plan295.daily_choice.reversibility.d298a67dfcbf',
    ),
    DailyChoiceDecisionGuardrailType.infoGap => i18n.t(
      'inline.plan295.daily_choice.info_gap.b85a8fb011ca',
    ),
  };
}

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
  String? _randomPickId;
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
        _DecisionContextCard(
          i18n: widget.i18n,
          accent: widget.accent,
          contextValue: _context,
          onStakesChanged: (value) =>
              setState(() => _context = _context.copyWith(stakes: value)),
          onUncertaintyChanged: (value) =>
              setState(() => _context = _context.copyWith(uncertainty: value)),
          onReversibilityChanged: (value) => setState(
            () => _context = _context.copyWith(reversibility: value),
          ),
          onUrgencyChanged: (value) =>
              setState(() => _context = _context.copyWith(urgency: value)),
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
        for (final item in _items) ...<Widget>[
          _DecisionInputCard(
            key: ValueKey<String>(item.id),
            i18n: widget.i18n,
            accent: widget.accent,
            item: item,
            score: activeScores[item.id],
            infoSignal: report.infoSignal,
            method: _method,
            canDelete: _items.length > 2,
            onChanged: () => setState(() {}),
            onDelete: () {
              setState(() {
                _items.removeWhere((candidate) => candidate.id == item.id);
                if (_randomPickId == item.id) {
                  _randomPickId = null;
                }
              });
            },
          ),
          const SizedBox(height: 10),
        ],
        _DecisionRankingCard(
          i18n: widget.i18n,
          accent: widget.accent,
          method: _method,
          spec: activeSpec,
          result: activeResult,
          consensus: report.consensus,
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
      title: pickUiText(
        widget.i18n,
        zh: '理性决策精要指南',
        en: 'Rational decision guide',
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
    setState(() {
      _items = <_DecisionDraft>[
        ..._items,
        _DecisionDraft(
          id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
          name: 'Option $nextIndex',
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
    });
  }

  void _resetDemo() {
    setState(() {
      _method = DailyChoiceDecisionMethod.weightedFactors;
      _context = const DailyChoiceDecisionContext();
      _randomPickId = null;
      _items = _buildDemoItems();
    });
  }

  List<_DecisionDraft> _buildDemoItems() {
    return <_DecisionDraft>[
      _DecisionDraft(
        id: 'plan_a',
        name: 'Option A',
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
        name: 'Option B',
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
        name: 'Option C',
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
                      pickUiText(i18n, zh: '科学决策助手', en: 'Decision workbench'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pickUiText(
                        i18n,
                        zh: '把本地决策资料里的六要素、偏差校正、概率与情景分析收成一个透明工作台，帮你把“纠结”拆成可以比较的字段。',
                        en: 'Turn local decision references into a transparent workbench built on framing, bias control, probability, and scenario thinking.',
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
                tooltip: pickUiText(i18n, zh: '理性决策精要指南', en: 'Guide'),
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
                text: pickUiText(i18n, zh: '六要素框架', en: 'Six elements'),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: pickUiText(i18n, zh: '偏差 vs 噪声', en: 'Bias vs noise'),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: pickUiText(
                  i18n,
                  zh: '概率与情景',
                  en: 'Probability and scenarios',
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
                  pickUiText(i18n, zh: '理性决策精要指南', en: 'Rational guide'),
                ),
              ),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(pickUiText(i18n, zh: '恢复示例', en: 'Reset sample')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
            pickUiText(i18n, zh: '先定决策情境', en: 'Set the decision context'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pickUiText(
              i18n,
              zh: '情境会影响你更该先看随机、加权、情景分析还是底线守门。',
              en: 'The context changes which lens should lead: random, weighted, scenario, or guardrails.',
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
            titleZh: '风险级别',
            titleEn: 'Stakes',
            values: DailyChoiceDecisionLevel.values,
            selectedValue: contextValue.stakes,
            onSelected: onStakesChanged,
            labelBuilder: (value) => _decisionLevelLabel(i18n, value),
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),
          _DecisionContextSection<DailyChoiceDecisionReversibility>(
            i18n: i18n,
            accent: accent,
            titleZh: '全局可回头性',
            titleEn: 'Global reversibility',
            values: DailyChoiceDecisionReversibility.values,
            selectedValue: contextValue.reversibility,
            onSelected: onReversibilityChanged,
            labelBuilder: (value) => _decisionReversibilityLabel(i18n, value),
          ),
          const SizedBox(height: 14),
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
        ],
      ),
    );
  }
}

class _DecisionContextSection<T> extends StatelessWidget {
  const _DecisionContextSection({
    required this.i18n,
    required this.accent,
    required this.titleZh,
    required this.titleEn,
    required this.values,
    required this.selectedValue,
    required this.onSelected,
    required this.labelBuilder,
  });

  final AppI18n i18n;
  final Color accent;
  final String titleZh;
  final String titleEn;
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
          pickUiText(i18n, zh: titleZh, en: titleEn),
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
            pickUiText(i18n, zh: '选择计算镜头', en: 'Choose the decision lens'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pickUiText(
              i18n,
              zh: '根据当前情境，先看推荐镜头；如果你想交叉验证，再切到别的策略做对照。',
              en: 'Start with the recommended lenses for this context, then cross-check with others if needed.',
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
                  label: Text(pickUiText(i18n, zh: '抽取一次', en: 'Draw once')),
                ),
              OutlinedButton.icon(
                onPressed: onAddOption,
                icon: const Icon(Icons.add_rounded),
                label: Text(pickUiText(i18n, zh: '新增选项', en: 'Add option')),
              ),
              TextButton.icon(
                onPressed: onGuide,
                icon: const Icon(Icons.menu_book_rounded),
                label: Text(pickUiText(i18n, zh: '看指南', en: 'Guide')),
              ),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(pickUiText(i18n, zh: '恢复示例', en: 'Reset')),
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
      (_, true) => pickUiText(
        i18n,
        zh: '先补信息，再做决定',
        en: 'Gather more info first',
      ),
      (DailyChoiceDecisionMethod.random, _) when randomPick == null =>
        pickUiText(i18n, zh: '抽取一次结束犹豫', en: 'Draw to break the tie'),
      (DailyChoiceDecisionMethod.random, _) => pickUiText(
        i18n,
        zh: '当前抽中',
        en: 'Current pick',
      ),
      _ when activeWinner == null => pickUiText(
        i18n,
        zh: '等待输入',
        en: 'Waiting for inputs',
      ),
      _ => pickUiText(i18n, zh: '当前建议', en: 'Current recommendation'),
    };
    final headline = switch ((
      activeMethod,
      report.infoSignal.shouldDelayDecision,
    )) {
      (_, true) =>
        activeWinner == null
            ? pickUiText(
                i18n,
                zh: '先补最关键的信息差',
                en: 'Close the most important info gap',
              )
            : pickUiText(
                i18n,
                zh: '优先补 ${_highlightOptionName(report) ?? activeWinner.option.name} 的关键条件',
                en: 'Prioritize missing facts for ${_highlightOptionName(report) ?? activeWinner.option.name}',
              ),
      (DailyChoiceDecisionMethod.random, _) when randomPick == null =>
        pickUiText(
          i18n,
          zh: '低风险场景可以交给随机',
          en: 'Let randomness end a low-stakes tie',
        ),
      (DailyChoiceDecisionMethod.random, _) => randomPick!.name,
      _ when activeWinner != null =>
        '${activeWinner.option.name} · ${activeWinner.score.toStringAsFixed(2)}',
      _ => pickUiText(i18n, zh: '至少保留两个可选项', en: 'Keep at least two options'),
    };
    final supportText = switch ((
      activeMethod,
      report.infoSignal.shouldDelayDecision,
    )) {
      (_, true) =>
        activeWinner == null
            ? pickUiText(
                i18n,
                zh: '当前信息价值偏高，尤其适合先查一条最可能改变结论的事实。',
                en: 'The value of information is currently high, so first research the one fact most likely to change the answer.',
              )
            : pickUiText(
                i18n,
                zh: '信息价值 ${report.infoSignal.impactScore.toStringAsFixed(2)}。如果现在必须定，先看 ${activeWinner.option.name}；如果还能等等，先补信息更划算。',
                en: 'Information value is ${report.infoSignal.impactScore.toStringAsFixed(2)}. If you must decide now, start with ${activeWinner.option.name}; if not, more research is worth it.',
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
                text: pickUiText(
                  i18n,
                  zh: '共识 ${report.consensus.supportCount}/${report.consensus.methodCount}',
                  en: 'Consensus ${report.consensus.supportCount}/${report.consensus.methodCount}',
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surface,
              ),
              ToolboxInfoPill(
                text: pickUiText(
                  i18n,
                  zh: '过线 $thresholdPassCount/${report.options.length}',
                  en: 'Pass $thresholdPassCount/${report.options.length}',
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surface,
              ),
              ToolboxInfoPill(
                text: report.infoSignal.shouldDelayDecision
                    ? pickUiText(i18n, zh: '建议先补信息', en: 'Research first')
                    : pickUiText(i18n, zh: '可先做决定', en: 'Ready to decide'),
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
            ? pickUiText(i18n, zh: '已过线', en: 'Passes guardrails')
            : pickUiText(i18n, zh: '未过线', en: 'Fails guardrails')
      else if (score != null && method != DailyChoiceDecisionMethod.random)
        pickUiText(
          i18n,
          zh: '当前分数 ${score!.score.toStringAsFixed(2)}',
          en: 'Score ${score!.score.toStringAsFixed(2)}',
        ),
      if (infoSignal.highlightOptionId == item.id)
        pickUiText(i18n, zh: '建议补信息', en: 'Research needed'),
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
                    labelText: pickUiText(i18n, zh: '选项', en: 'Option'),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    item.name = value.trim().isEmpty ? item.name : value.trim();
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: pickUiText(i18n, zh: '删除', en: 'Delete'),
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
            pickUiText(
              i18n,
              zh: '成功/执行/把握填 0-1；收益、风险、投入、可回退、后悔、信息差填 0-10。',
              en: 'Use 0-1 for success, execution, and confidence. Use 0-10 for the other fields.',
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
                label: pickUiText(i18n, zh: '成功 P', en: 'P'),
                value: item.successProbability,
                onChanged: (value) {
                  item.successProbability = value;
                  onChanged();
                },
              ),
              _NumberField(
                label: pickUiText(i18n, zh: '执行', en: 'Exec'),
                value: item.executionProbability,
                onChanged: (value) {
                  item.executionProbability = value;
                  onChanged();
                },
              ),
              _NumberField(
                label: pickUiText(i18n, zh: '把握', en: 'Conf'),
                value: item.confidence,
                onChanged: (value) {
                  item.confidence = value;
                  onChanged();
                },
              ),
              _NumberField(
                label: pickUiText(i18n, zh: '收益', en: 'Upside'),
                value: item.upside,
                onChanged: (value) {
                  item.upside = value;
                  onChanged();
                },
              ),
              _NumberField(
                label: pickUiText(i18n, zh: '风险', en: 'Down'),
                value: item.downside,
                onChanged: (value) {
                  item.downside = value;
                  onChanged();
                },
              ),
              _NumberField(
                label: pickUiText(i18n, zh: '投入', en: 'Effort'),
                value: item.effort,
                onChanged: (value) {
                  item.effort = value;
                  onChanged();
                },
              ),
              _NumberField(
                label: pickUiText(i18n, zh: '可回退', en: 'Undo'),
                value: item.reversibility,
                onChanged: (value) {
                  item.reversibility = value;
                  onChanged();
                },
              ),
              _NumberField(
                label: pickUiText(i18n, zh: '后悔', en: 'Regret'),
                value: item.regret,
                onChanged: (value) {
                  item.regret = value;
                  onChanged();
                },
              ),
              _NumberField(
                label: pickUiText(i18n, zh: '信息差', en: 'Info'),
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
            pickUiText(i18n, zh: '透明排序', en: 'Transparent ranking'),
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
              pickUiText(
                i18n,
                zh: consensus.winnerName.isEmpty
                    ? '随机镜头不做质量排序，只负责帮你结束低风险犹豫。'
                    : '随机镜头不做质量排序；如果你想看更稳的结论，可以参考跨方法共识：${consensus.winnerName}。',
                en: consensus.winnerName.isEmpty
                    ? 'Random mode does not rank quality. It only ends low-stakes dithering.'
                    : 'Random mode does not rank quality. For a steadier read, check the cross-method consensus: ${consensus.winnerName}.',
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
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: accent.withValues(alpha: 0.16),
      shadowOpacity: 0.04,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            pickUiText(i18n, zh: '决策卫生检查', en: 'Decision hygiene'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pickUiText(
              i18n,
              zh: '在最终拍板前，至少过一遍这些偏差与噪声校正项。',
              en: 'Run through these bias and noise checks before you commit.',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < entries.length; index += 1) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(entries[index].icon, color: accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        entries[index].title(i18n),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entries[index].body(i18n),
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
            if (index != entries.length - 1) ...<Widget>[
              const SizedBox(height: 12),
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 12),
            ],
          ],
          if (showHighRiskBoundary) ...<Widget>[
            const SizedBox(height: 12),
            Divider(color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text(
              pickUiText(
                i18n,
                zh: '提醒：高风险医疗、法律、财务决策请把本模块当作整理思路的辅助手段，不要当成单一依据。',
                en: 'Reminder: for high-stakes medical, legal, or financial decisions, use this module to organize thinking, not as a sole basis.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
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
    DailyChoiceDecisionLevel.low => pickUiText(i18n, zh: '低风险', en: 'Low'),
    DailyChoiceDecisionLevel.medium => pickUiText(
      i18n,
      zh: '中风险',
      en: 'Medium',
    ),
    DailyChoiceDecisionLevel.high => pickUiText(i18n, zh: '高风险', en: 'High'),
  };
}

String _decisionUncertaintyLabel(AppI18n i18n, DailyChoiceDecisionLevel value) {
  return switch (value) {
    DailyChoiceDecisionLevel.low => pickUiText(
      i18n,
      zh: '较确定',
      en: 'Low uncertainty',
    ),
    DailyChoiceDecisionLevel.medium => pickUiText(
      i18n,
      zh: '一般',
      en: 'Medium uncertainty',
    ),
    DailyChoiceDecisionLevel.high => pickUiText(
      i18n,
      zh: '很不确定',
      en: 'High uncertainty',
    ),
  };
}

String _decisionReversibilityLabel(
  AppI18n i18n,
  DailyChoiceDecisionReversibility value,
) {
  return switch (value) {
    DailyChoiceDecisionReversibility.easy => pickUiText(
      i18n,
      zh: '容易回头',
      en: 'Easy to undo',
    ),
    DailyChoiceDecisionReversibility.mixed => pickUiText(
      i18n,
      zh: '部分可回头',
      en: 'Partly undoable',
    ),
    DailyChoiceDecisionReversibility.hard => pickUiText(
      i18n,
      zh: '很难回头',
      en: 'Hard to undo',
    ),
  };
}

String _decisionUrgencyLabel(AppI18n i18n, DailyChoiceDecisionUrgency value) {
  return switch (value) {
    DailyChoiceDecisionUrgency.now => pickUiText(
      i18n,
      zh: '现在就要定',
      en: 'Decide now',
    ),
    DailyChoiceDecisionUrgency.soon => pickUiText(i18n, zh: '很快要定', en: 'Soon'),
    DailyChoiceDecisionUrgency.canWait => pickUiText(
      i18n,
      zh: '还能等等',
      en: 'Can wait',
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
    DailyChoiceDecisionMethod.weightedFactors => pickUiText(
      i18n,
      zh: '正向拉力 ${metrics['positivePull']?.toStringAsFixed(2) ?? '--'} · 惩罚 ${metrics['negativePull']?.toStringAsFixed(2) ?? '--'}',
      en: 'Positive pull ${metrics['positivePull']?.toStringAsFixed(2) ?? '--'} · penalties ${metrics['negativePull']?.toStringAsFixed(2) ?? '--'}',
    ),
    DailyChoiceDecisionMethod.expectedValue => pickUiText(
      i18n,
      zh: '有效成功率 ${metrics['effectiveSuccess']?.toStringAsFixed(2) ?? '--'} · 期望收益 ${metrics['expectedGain']?.toStringAsFixed(2) ?? '--'} · 期望损失 ${metrics['expectedLoss']?.toStringAsFixed(2) ?? '--'}',
      en: 'Effective success ${metrics['effectiveSuccess']?.toStringAsFixed(2) ?? '--'} · gain ${metrics['expectedGain']?.toStringAsFixed(2) ?? '--'} · loss ${metrics['expectedLoss']?.toStringAsFixed(2) ?? '--'}',
    ),
    DailyChoiceDecisionMethod.jointProbability => pickUiText(
      i18n,
      zh: '联合成功率 ${metrics['jointProbability']?.toStringAsFixed(2) ?? '--'} · 下行暴露 ${metrics['downsideExposure']?.toStringAsFixed(2) ?? '--'}',
      en: 'Joint success ${metrics['jointProbability']?.toStringAsFixed(2) ?? '--'} · downside ${metrics['downsideExposure']?.toStringAsFixed(2) ?? '--'}',
    ),
    DailyChoiceDecisionMethod.scenarioBlend => pickUiText(
      i18n,
      zh: '乐/基/悲 ${metrics['optimistic']?.toStringAsFixed(1) ?? '--'} / ${metrics['baseline']?.toStringAsFixed(1) ?? '--'} / ${metrics['pessimistic']?.toStringAsFixed(1) ?? '--'}',
      en: 'Opt/base/pess ${metrics['optimistic']?.toStringAsFixed(1) ?? '--'} / ${metrics['baseline']?.toStringAsFixed(1) ?? '--'} / ${metrics['pessimistic']?.toStringAsFixed(1) ?? '--'}',
    ),
    DailyChoiceDecisionMethod.regretBalance => pickUiText(
      i18n,
      zh: '已实现潜力 ${metrics['realizedPotential']?.toStringAsFixed(2) ?? '--'} · 后悔暴露 ${metrics['missPenalty']?.toStringAsFixed(2) ?? '--'} · 机会成本 ${metrics['opportunityCost']?.toStringAsFixed(2) ?? '--'}',
      en: 'Realized upside ${metrics['realizedPotential']?.toStringAsFixed(2) ?? '--'} · regret ${metrics['missPenalty']?.toStringAsFixed(2) ?? '--'} · opportunity cost ${metrics['opportunityCost']?.toStringAsFixed(2) ?? '--'}',
    ),
    DailyChoiceDecisionMethod.thresholdGuardrail =>
      score.passesGuardrails
          ? pickUiText(
              i18n,
              zh: '已过 ${metrics['passCount']?.toStringAsFixed(0) ?? '0'}/4 道守门线 · 同档综合 ${metrics['weightedFallback']?.toStringAsFixed(2) ?? '--'}',
              en: 'Passed ${metrics['passCount']?.toStringAsFixed(0) ?? '0'}/4 guardrails · fallback ${metrics['weightedFallback']?.toStringAsFixed(2) ?? '--'}',
            )
          : pickUiText(
              i18n,
              zh: '未过线：${score.failedGuardrails.map((item) => _guardrailLabel(i18n, item)).join('、')}',
              en: 'Fails: ${score.failedGuardrails.map((item) => _guardrailLabel(i18n, item)).join(', ')}',
            ),
    DailyChoiceDecisionMethod.calibratedForecast => pickUiText(
      i18n,
      zh: '原始预期 ${metrics['rawExpected']?.toStringAsFixed(2) ?? '--'} → 校准后 ${score.score.toStringAsFixed(2)}',
      en: 'Raw expected ${metrics['rawExpected']?.toStringAsFixed(2) ?? '--'} -> calibrated ${score.score.toStringAsFixed(2)}',
    ),
    DailyChoiceDecisionMethod.random => pickUiText(
      i18n,
      zh: '随机镜头不做质量排序。',
      en: 'Random mode does not rank quality.',
    ),
  };
}

String _guardrailLabel(AppI18n i18n, DailyChoiceDecisionGuardrailType value) {
  return switch (value) {
    DailyChoiceDecisionGuardrailType.confidence => pickUiText(
      i18n,
      zh: '把握度',
      en: 'Confidence',
    ),
    DailyChoiceDecisionGuardrailType.downside => pickUiText(
      i18n,
      zh: '风险',
      en: 'Downside',
    ),
    DailyChoiceDecisionGuardrailType.reversibility => pickUiText(
      i18n,
      zh: '可回退性',
      en: 'Reversibility',
    ),
    DailyChoiceDecisionGuardrailType.infoGap => pickUiText(
      i18n,
      zh: '信息差',
      en: 'Info gap',
    ),
  };
}

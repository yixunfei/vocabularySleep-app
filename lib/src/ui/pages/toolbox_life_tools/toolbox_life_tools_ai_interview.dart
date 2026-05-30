part of '../toolbox_life_tools.dart';

class _AiInterviewToolPage extends StatefulWidget {
  const _AiInterviewToolPage();

  @override
  State<_AiInterviewToolPage> createState() => _AiInterviewToolPageState();
}

class _AiInterviewToolPageState extends State<_AiInterviewToolPage> {
  final TextEditingController _question = TextEditingController(
    text: '讲一次你处理项目推进受阻或团队冲突的经历。',
  );
  final TextEditingController _role = TextEditingController(
    text: 'Flutter 工程师',
  );
  final TextEditingController _company = TextEditingController();
  final TextEditingController _highlights = TextEditingController(
    text: '跨团队协作, 性能优化, 独立负责移动端模块',
  );
  final TextEditingController _draft = TextEditingController();
  final ToolboxAiInterviewService _service = const ToolboxAiInterviewService();

  ToolboxAiInterviewType _type = ToolboxAiInterviewType.auto;
  ToolboxAiInterviewDepth _depth = ToolboxAiInterviewDepth.standard;
  ToolboxAiInterviewLanguage _language = ToolboxAiInterviewLanguage.zh;
  ToolboxAiInterviewTone _tone = ToolboxAiInterviewTone.balanced;
  bool _includeFollowUps = true;
  double _strictness = 0.65;

  @override
  void dispose() {
    _question.dispose();
    _role.dispose();
    _company.dispose();
    _highlights.dispose();
    _draft.dispose();
    super.dispose();
  }

  ToolboxAiInterviewInput get _input => ToolboxAiInterviewInput(
    question: _question.text,
    role: _role.text,
    company: _company.text,
    resumeHighlights: _highlights.text,
    answerDraft: _draft.text,
    type: _type,
    depth: _depth,
    language: _language,
    tone: _tone,
    strictness: _strictness,
    includeFollowUps: _includeFollowUps,
  );

  ToolboxAiInterviewResult get _result => _service.build(_input);

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.ai_interview.0618cad69887',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.a_local_interview_practice_desk_insp.555e7611f874',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _AiInterviewStage(result: result),
          const SizedBox(height: 14),
          _questionPanel(context),
          const SizedBox(height: 12),
          _settingsPanel(context),
          const SizedBox(height: 12),
          _outputPanel(
            context,
            title: _lifeI18nText(
              context,
              'inline.plan295.life.answer_frame.11e30d1bc06f',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.life.rehearse_this_frame_first_then_add_r.4b176680784f',
            ),
            items: result.answerOutline,
            icon: Icons.account_tree_rounded,
          ),
          const SizedBox(height: 12),
          _outputPanel(
            context,
            title: _lifeI18nText(
              context,
              'inline.plan295.life.draft_check.127a681fa646',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.life.lightweight_feedback_on_structure_ev.77e6ed19f44c',
            ),
            items: result.evaluationNotes,
            icon: Icons.fact_check_rounded,
          ),
          if (result.followUpQuestions.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _outputPanel(
              context,
              title: _lifeI18nText(
                context,
                'inline.plan295.life.follow_ups.37bc56ab7358',
              ),
              subtitle: _lifeI18nText(
                context,
                'inline.plan295.life.use_these_to_test_whether_the_answer.41c72b0c6116',
              ),
              items: result.followUpQuestions,
              icon: Icons.question_answer_rounded,
            ),
          ],
          const SizedBox(height: 12),
          _promptPanel(context, _input),
          const SizedBox(height: 12),
          _outputPanel(
            context,
            title: _lifeI18nText(
              context,
              'inline.plan295.life.next_steps.843b4e1ff867',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.life.follow_in_order_so_the_answer_gets_t.950a704a018f',
            ),
            items: result.actionChecklist,
            icon: Icons.playlist_add_check_rounded,
          ),
          const SizedBox(height: 12),
          _outputPanel(
            context,
            title: _lifeI18nText(
              context,
              'inline.plan295.life.boundaries.27272eb15461',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.life.this_is_for_practice_and_review_not.822856a18756',
            ),
            items: result.boundaryNotes,
            icon: Icons.privacy_tip_rounded,
          ),
        ],
      ),
    );
  }

  Widget _questionPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.question_and_material.19aa4cd99e6c',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.question_role_and_notes_stay_local_o.e38c51551804',
      ),
      children: <Widget>[
        TextField(
          controller: _question,
          minLines: 2,
          maxLines: 5,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _lifeI18nText(
              context,
              'inline.plan295.life.interview_question.1d6f5637e7f0',
            ),
            prefixIcon: const Icon(Icons.help_outline_rounded),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        _AiInterviewFieldGrid(
          children: <Widget>[
            TextField(
              controller: _role,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: _lifeI18nText(
                  context,
                  'inline.plan295.life.target_role.2e86f73363ba',
                ),
                prefixIcon: const Icon(Icons.work_outline_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _company,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: _lifeI18nText(
                  context,
                  'inline.plan295.life.company_team_optional.5ef561faaa31',
                ),
                prefixIcon: const Icon(Icons.business_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _highlights,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _lifeI18nText(
              context,
              'inline.plan295.life.resume_highlights.ce168080e762',
            ),
            helperText: _lifeI18nText(
              context,
              'inline.plan295.life.separate_with_commas_or_new_lines.eb0922209dc9',
            ),
            prefixIcon: const Icon(Icons.stars_rounded),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _draft,
          minLines: 3,
          maxLines: 8,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _lifeI18nText(
              context,
              'inline.plan295.life.my_answer_draft_optional.e20a9654f0ac',
            ),
            prefixIcon: const Icon(Icons.edit_note_rounded),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _settingsPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.interview_setup.33df48ba6133',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.let_the_type_auto_detect_or_set_it_m.3fa09a697e5b',
      ),
      children: <Widget>[
        _LifeSegmentedField<ToolboxAiInterviewType>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.question_type.507405c959f8',
          ),
          value: _type,
          options: const <_LifeOption<ToolboxAiInterviewType>>[
            _LifeOption(
              value: ToolboxAiInterviewType.auto,
              labelKey: 'asrLanguageAuto',
            ),
            _LifeOption(
              value: ToolboxAiInterviewType.behavioral,
              labelKey: 'inline.plan295.life.behavioral.8d103487c5ea',
            ),
            _LifeOption(
              value: ToolboxAiInterviewType.technical,
              labelKey: 'inline.plan295.life.technical.c8e75e76815f',
            ),
            _LifeOption(
              value: ToolboxAiInterviewType.systemDesign,
              labelKey: 'inline.plan295.life.system.5cf8ce77e6ba',
            ),
            _LifeOption(
              value: ToolboxAiInterviewType.productCase,
              labelKey:
                  'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_ai_interview.case_95caaf',
            ),
            _LifeOption(
              value: ToolboxAiInterviewType.hr,
              labelKey:
                  'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_ai_interview.hr_252053',
            ),
          ],
          onChanged: (value) => setState(() => _type = value),
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<ToolboxAiInterviewDepth>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.depth.7070c6c3112e',
          ),
          value: _depth,
          options: const <_LifeOption<ToolboxAiInterviewDepth>>[
            _LifeOption(
              value: ToolboxAiInterviewDepth.quick,
              labelKey: 'inline.plan295.life.quick.a2907af9f021',
            ),
            _LifeOption(
              value: ToolboxAiInterviewDepth.standard,
              labelKey:
                  'inline.ui.pages.toolbox_human_tests_bimanual.standard_b9acb5',
            ),
            _LifeOption(
              value: ToolboxAiInterviewDepth.deep,
              labelKey: 'inline.plan295.life.deep.4e216b0b95cb',
            ),
          ],
          onChanged: (value) => setState(() => _depth = value),
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<ToolboxAiInterviewLanguage>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.language.11cf1287ab3a',
          ),
          value: _language,
          options: const <_LifeOption<ToolboxAiInterviewLanguage>>[
            _LifeOption(
              value: ToolboxAiInterviewLanguage.zh,
              labelKey:
                  'inline.ui.pages.toolbox_human_tests_typing_copy.chinese_7d55e9',
            ),
            _LifeOption(
              value: ToolboxAiInterviewLanguage.en,
              labelKey: 'inline.plan295.life.english.0f5a12198399',
            ),
            _LifeOption(
              value: ToolboxAiInterviewLanguage.bilingual,
              labelKey: 'inline.plan295.life.bilingual.1f0a85217a23',
            ),
          ],
          onChanged: (value) => setState(() => _language = value),
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<ToolboxAiInterviewTone>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.tone.f5d526aa4471',
          ),
          value: _tone,
          options: const <_LifeOption<ToolboxAiInterviewTone>>[
            _LifeOption(
              value: ToolboxAiInterviewTone.concise,
              labelKey: 'inline.plan295.life.concise.99dea537a1cb',
            ),
            _LifeOption(
              value: ToolboxAiInterviewTone.balanced,
              labelKey:
                  'inline.ui.pages.toolbox_daily_choice.daily_choice_decision_interaction.balanced_389852',
            ),
            _LifeOption(
              value: ToolboxAiInterviewTone.coaching,
              labelKey: 'inline.plan295.life.coaching.f86059a5a3ce',
            ),
          ],
          onChanged: (value) => setState(() => _tone = value),
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _includeFollowUps,
          title: Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.generate_follow_ups.bf74d0e9d795',
            ),
          ),
          onChanged: (value) => setState(() => _includeFollowUps = value),
        ),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.scoring_strictness.5a0063344aca',
          ),
          valueText: '${(_strictness * 100).round()}%',
          value: _strictness,
          min: 0,
          max: 1,
          divisions: 20,
          onChanged: (value) => setState(() => _strictness = value),
        ),
      ],
    );
  }

  Widget _outputPanel(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<ToolboxI18nTextRef> items,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return _LifeSettingsPanel(
      title: title,
      subtitle: subtitle,
      children: <Widget>[
        for (var i = 0; i < items.length; i++) ...<Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: i == 0
                    ? Icon(
                        icon,
                        size: 16,
                        color: theme.colorScheme.onPrimaryContainer,
                      )
                    : Text(
                        '${i + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(_lifeI18nRefText(context, items[i]))),
            ],
          ),
          if (i != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _promptPanel(BuildContext context, ToolboxAiInterviewInput input) {
    final promptDraft = _service.renderPromptDraft(
      input,
      (key, {params = const <String, Object?>{}}) =>
          _lifeI18nText(context, key, params: params),
    );
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.prompt_draft.1f68eb72fe86',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.copy_this_prompt_to_an_external_ai_o.29cfa4e03574',
      ),
      children: <Widget>[
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 280),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              promptDraft,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: promptDraft));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _lifeI18nText(
                        context,
                        'inline.plan295.life.prompt_copied.13eaefd85164',
                      ),
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded),
            label: Text(_lifeI18nText(context, 'copyField')),
          ),
        ),
      ],
    );
  }
}

class _AiInterviewStage extends StatelessWidget {
  const _AiInterviewStage({required this.result});

  final ToolboxAiInterviewResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = _scoreColor(theme, result.readinessScore);
    return Container(
      key: const ValueKey<String>('life-ai-interview-stage'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            theme.colorScheme.primaryContainer.withValues(alpha: 0.72),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.52),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _AiInterviewPill(
                icon: Icons.category_rounded,
                label: _lifeI18nText(context, result.typeLabelKey),
              ),
              _AiInterviewPill(
                icon: Icons.verified_rounded,
                label: _lifeI18nText(context, result.readinessLabelKey),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.interview_readiness.c754ee1aea6f',
            ),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withValues(
                alpha: 0.72,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '${result.readinessScore}',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: scoreColor,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/ 100',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: result.readinessScore / 100,
              color: scoreColor,
              backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            result.normalizedQuestion.isEmpty
                ? _lifeI18nText(context, result.fallbackQuestionKey)
                : result.normalizedQuestion,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(ThemeData theme, int score) {
    if (score >= 80) {
      return Colors.green.shade700;
    }
    if (score >= 55) {
      return Colors.orange.shade800;
    }
    if (score > 0) {
      return theme.colorScheme.error;
    }
    return theme.colorScheme.primary;
  }
}

class _AiInterviewPill extends StatelessWidget {
  const _AiInterviewPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiInterviewFieldGrid extends StatelessWidget {
  const _AiInterviewFieldGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 520;
        if (narrow) {
          return Column(
            children: children
                .expand((child) => <Widget>[child, const SizedBox(height: 10)])
                .take(children.length * 2 - 1)
                .toList(growable: false),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children
              .expand(
                (child) => <Widget>[
                  Expanded(child: child),
                  const SizedBox(width: 10),
                ],
              )
              .take(children.length * 2 - 1)
              .toList(growable: false),
        );
      },
    );
  }
}

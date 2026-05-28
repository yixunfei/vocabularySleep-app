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

  ToolboxAiInterviewResult get _result => _service.build(
    ToolboxAiInterviewInput(
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
    ),
  );

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return ToolboxToolPage(
      title: _lifeText(context, zh: 'AI 面试', en: 'AI interview'),
      subtitle: _lifeText(
        context,
        zh: '参考 Snap-Solver 的题目拆解与提示词配置思路，落地为本地面试练习工作台。',
        en: 'A local interview practice desk inspired by Snap-Solver style prompt setup.',
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
            title: _lifeText(context, zh: '回答框架', en: 'Answer frame'),
            subtitle: _lifeText(
              context,
              zh: '先拿这份骨架口述一遍，再补真实证据。',
              en: 'Rehearse this frame first, then add real evidence.',
            ),
            items: result.answerOutline,
            icon: Icons.account_tree_rounded,
          ),
          const SizedBox(height: 12),
          _outputPanel(
            context,
            title: _lifeText(context, zh: '草稿体检', en: 'Draft check'),
            subtitle: _lifeText(
              context,
              zh: '根据结构、证据和岗位迁移性给出轻量反馈。',
              en: 'Lightweight feedback on structure, evidence, and fit.',
            ),
            items: result.evaluationNotes,
            icon: Icons.fact_check_rounded,
          ),
          if (result.followUpQuestions.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _outputPanel(
              context,
              title: _lifeText(context, zh: '模拟追问', en: 'Follow-ups'),
              subtitle: _lifeText(
                context,
                zh: '用这些问题检查答案是否经得起继续追问。',
                en: 'Use these to test whether the answer holds up.',
              ),
              items: result.followUpQuestions,
              icon: Icons.question_answer_rounded,
            ),
          ],
          const SizedBox(height: 12),
          _promptPanel(context, result),
          const SizedBox(height: 12),
          _outputPanel(
            context,
            title: _lifeText(context, zh: '下一步清单', en: 'Next steps'),
            subtitle: _lifeText(
              context,
              zh: '训练时按顺序完成，避免越改越散。',
              en: 'Follow in order so the answer gets tighter.',
            ),
            items: result.actionChecklist,
            icon: Icons.playlist_add_check_rounded,
          ),
          const SizedBox(height: 12),
          _outputPanel(
            context,
            title: _lifeText(context, zh: '使用边界', en: 'Boundaries'),
            subtitle: _lifeText(
              context,
              zh: '本工具定位为准备和复盘，不是实时作弊辅助。',
              en: 'This is for practice and review, not real-time cheating.',
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
      title: _lifeText(context, zh: '题目与素材', en: 'Question and material'),
      subtitle: _lifeText(
        context,
        zh: '题目、岗位和经历亮点都在本地处理，不会上传。',
        en: 'Question, role, and notes stay local on this page.',
      ),
      children: <Widget>[
        TextField(
          controller: _question,
          minLines: 2,
          maxLines: 5,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _lifeText(context, zh: '面试题', en: 'Interview question'),
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
                labelText: _lifeText(context, zh: '目标岗位', en: 'Target role'),
                prefixIcon: const Icon(Icons.work_outline_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _company,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: _lifeText(
                  context,
                  zh: '公司/团队（可选）',
                  en: 'Company/team (optional)',
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
            labelText: _lifeText(
              context,
              zh: '简历亮点 / 可用经历',
              en: 'Resume highlights',
            ),
            helperText: _lifeText(
              context,
              zh: '用逗号或换行分隔',
              en: 'Separate with commas or new lines',
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
            labelText: _lifeText(
              context,
              zh: '我的回答草稿（可选）',
              en: 'My answer draft (optional)',
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
      title: _lifeText(context, zh: '面试参数', en: 'Interview setup'),
      subtitle: _lifeText(
        context,
        zh: '题型可自动识别，也可以手动指定；严格度只影响本地草稿评分。',
        en: 'Let the type auto-detect or set it manually; strictness only affects local scoring.',
      ),
      children: <Widget>[
        _LifeSegmentedField<ToolboxAiInterviewType>(
          label: _lifeText(context, zh: '题型', en: 'Question type'),
          value: _type,
          options: const <_LifeOption<ToolboxAiInterviewType>>[
            _LifeOption(
              value: ToolboxAiInterviewType.auto,
              labelZh: '自动',
              labelEn: 'Auto',
            ),
            _LifeOption(
              value: ToolboxAiInterviewType.behavioral,
              labelZh: '行为',
              labelEn: 'Behavioral',
            ),
            _LifeOption(
              value: ToolboxAiInterviewType.technical,
              labelZh: '技术',
              labelEn: 'Technical',
            ),
            _LifeOption(
              value: ToolboxAiInterviewType.systemDesign,
              labelZh: '系统设计',
              labelEn: 'System',
            ),
            _LifeOption(
              value: ToolboxAiInterviewType.productCase,
              labelZh: 'Case',
              labelEn: 'Case',
            ),
            _LifeOption(
              value: ToolboxAiInterviewType.hr,
              labelZh: 'HR',
              labelEn: 'HR',
            ),
          ],
          onChanged: (value) => setState(() => _type = value),
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<ToolboxAiInterviewDepth>(
          label: _lifeText(context, zh: '分析深度', en: 'Depth'),
          value: _depth,
          options: const <_LifeOption<ToolboxAiInterviewDepth>>[
            _LifeOption(
              value: ToolboxAiInterviewDepth.quick,
              labelZh: '快速',
              labelEn: 'Quick',
            ),
            _LifeOption(
              value: ToolboxAiInterviewDepth.standard,
              labelZh: '标准',
              labelEn: 'Standard',
            ),
            _LifeOption(
              value: ToolboxAiInterviewDepth.deep,
              labelZh: '深度',
              labelEn: 'Deep',
            ),
          ],
          onChanged: (value) => setState(() => _depth = value),
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<ToolboxAiInterviewLanguage>(
          label: _lifeText(context, zh: '输出语言', en: 'Language'),
          value: _language,
          options: const <_LifeOption<ToolboxAiInterviewLanguage>>[
            _LifeOption(
              value: ToolboxAiInterviewLanguage.zh,
              labelZh: '中文',
              labelEn: 'Chinese',
            ),
            _LifeOption(
              value: ToolboxAiInterviewLanguage.en,
              labelZh: '英文',
              labelEn: 'English',
            ),
            _LifeOption(
              value: ToolboxAiInterviewLanguage.bilingual,
              labelZh: '双语',
              labelEn: 'Bilingual',
            ),
          ],
          onChanged: (value) => setState(() => _language = value),
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<ToolboxAiInterviewTone>(
          label: _lifeText(context, zh: '表达风格', en: 'Tone'),
          value: _tone,
          options: const <_LifeOption<ToolboxAiInterviewTone>>[
            _LifeOption(
              value: ToolboxAiInterviewTone.concise,
              labelZh: '简洁',
              labelEn: 'Concise',
            ),
            _LifeOption(
              value: ToolboxAiInterviewTone.balanced,
              labelZh: '平衡',
              labelEn: 'Balanced',
            ),
            _LifeOption(
              value: ToolboxAiInterviewTone.coaching,
              labelZh: '复盘',
              labelEn: 'Coaching',
            ),
          ],
          onChanged: (value) => setState(() => _tone = value),
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _includeFollowUps,
          title: Text(
            _lifeText(context, zh: '生成模拟追问', en: 'Generate follow-ups'),
          ),
          onChanged: (value) => setState(() => _includeFollowUps = value),
        ),
        _LifeSliderField(
          label: _lifeText(context, zh: '草稿评分严格度', en: 'Scoring strictness'),
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
    required List<String> items,
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
              Expanded(child: Text(items[i])),
            ],
          ),
          if (i != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _promptPanel(BuildContext context, ToolboxAiInterviewResult result) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '提示词草稿', en: 'Prompt draft'),
      subtitle: _lifeText(
        context,
        zh: '需要接入外部 AI 时，可复制这份练习提示词；请先移除敏感信息。',
        en: 'Copy this prompt to an external AI only after removing sensitive details.',
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
              result.promptDraft,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: result.promptDraft));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _lifeText(context, zh: '已复制提示词', en: 'Prompt copied'),
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded),
            label: Text(_lifeText(context, zh: '复制', en: 'Copy')),
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
                label: _lifeText(
                  context,
                  zh: result.typeLabelZh,
                  en: result.typeLabelEn,
                ),
              ),
              _AiInterviewPill(
                icon: Icons.verified_rounded,
                label: _lifeText(
                  context,
                  zh: result.readinessLabelZh,
                  en: result.readinessLabelEn,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _lifeText(context, zh: '面试准备度', en: 'Interview readiness'),
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
            result.normalizedQuestion,
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

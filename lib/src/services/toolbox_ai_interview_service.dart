import 'toolbox_i18n_text_ref.dart';

enum ToolboxAiInterviewType {
  auto,
  behavioral,
  technical,
  systemDesign,
  productCase,
  hr,
}

enum ToolboxAiInterviewDepth { quick, standard, deep }

enum ToolboxAiInterviewLanguage { zh, en, bilingual }

enum ToolboxAiInterviewTone { concise, balanced, coaching }

class ToolboxAiInterviewInput {
  const ToolboxAiInterviewInput({
    required this.question,
    this.role = '',
    this.company = '',
    this.resumeHighlights = '',
    this.answerDraft = '',
    this.type = ToolboxAiInterviewType.auto,
    this.depth = ToolboxAiInterviewDepth.standard,
    this.language = ToolboxAiInterviewLanguage.zh,
    this.tone = ToolboxAiInterviewTone.balanced,
    this.strictness = 0.65,
    this.includeFollowUps = true,
  });

  final String question;
  final String role;
  final String company;
  final String resumeHighlights;
  final String answerDraft;
  final ToolboxAiInterviewType type;
  final ToolboxAiInterviewDepth depth;
  final ToolboxAiInterviewLanguage language;
  final ToolboxAiInterviewTone tone;
  final double strictness;
  final bool includeFollowUps;
}

class ToolboxAiInterviewResult {
  const ToolboxAiInterviewResult({
    required this.normalizedQuestion,
    required this.fallbackQuestionKey,
    required this.detectedType,
    required this.typeLabelKey,
    required this.readinessScore,
    required this.readinessLabelKey,
    required this.answerOutline,
    required this.evaluationNotes,
    required this.followUpQuestions,
    required this.actionChecklist,
    required this.boundaryNotes,
  });

  final String normalizedQuestion;
  final String fallbackQuestionKey;
  final ToolboxAiInterviewType detectedType;
  final String typeLabelKey;
  final int readinessScore;
  final String readinessLabelKey;
  final List<ToolboxI18nTextRef> answerOutline;
  final List<ToolboxI18nTextRef> evaluationNotes;
  final List<ToolboxI18nTextRef> followUpQuestions;
  final List<ToolboxI18nTextRef> actionChecklist;
  final List<ToolboxI18nTextRef> boundaryNotes;
}

class ToolboxAiInterviewService {
  const ToolboxAiInterviewService();

  ToolboxAiInterviewResult build(ToolboxAiInterviewInput input) {
    final question = _normalize(input.question);
    final type = input.type == ToolboxAiInterviewType.auto
        ? _detectType(question)
        : input.type;
    final role = _normalize(input.role);
    final company = _normalize(input.company);
    final highlights = _splitSignals(input.resumeHighlights);
    final answerDraft = _normalize(input.answerDraft);
    final score = _scoreAnswer(
      answerDraft: answerDraft,
      highlights: highlights,
      type: type,
      strictness: input.strictness,
    );

    return ToolboxAiInterviewResult(
      normalizedQuestion: question,
      fallbackQuestionKey: _fallbackQuestionKey(type),
      detectedType: type,
      typeLabelKey: _typeLabelKey(type),
      readinessScore: score,
      readinessLabelKey: _readinessLabelKey(score),
      answerOutline: _answerOutline(
        question: question,
        role: role,
        company: company,
        highlights: highlights,
        type: type,
        depth: input.depth,
        language: input.language,
        tone: input.tone,
      ),
      evaluationNotes: _evaluationNotes(
        answerDraft: answerDraft,
        highlights: highlights,
        type: type,
        score: score,
      ),
      followUpQuestions: input.includeFollowUps
          ? _followUps(type, input.depth, role)
          : const <ToolboxI18nTextRef>[],
      actionChecklist: _actionChecklist(type, answerDraft),
      boundaryNotes: const <ToolboxI18nTextRef>[
        ToolboxI18nTextRef('life.ai_interview.boundary.local_practice'),
        ToolboxI18nTextRef('life.ai_interview.boundary.no_sensitive_data'),
        ToolboxI18nTextRef('life.ai_interview.boundary.not_final_advice'),
      ],
    );
  }

  String renderPromptDraft(
    ToolboxAiInterviewInput input,
    String Function(String key, {Map<String, Object?> params}) t,
  ) {
    final question = _normalize(input.question);
    final type = input.type == ToolboxAiInterviewType.auto
        ? _detectType(question)
        : input.type;
    final role = _normalize(input.role);
    final company = _normalize(input.company);
    final highlights = _splitSignals(input.resumeHighlights);
    final answerDraft = _normalize(input.answerDraft);

    String text(
      String key, {
      Map<String, Object?> params = const <String, Object?>{},
    }) {
      return t(key, params: params);
    }

    final buffer = StringBuffer()
      ..writeln(text('life.ai_interview.prompt.coach_intro'))
      ..writeln(
        text(
          'life.ai_interview.prompt.type_line',
          params: <String, Object?>{'type': text(_typeLabelKey(type))},
        ),
      )
      ..writeln(
        text(
          'life.ai_interview.prompt.role_line',
          params: <String, Object?>{
            'role': role.isEmpty
                ? text('life.ai_interview.prompt.not_filled')
                : role,
          },
        ),
      )
      ..writeln(
        text(
          'life.ai_interview.prompt.company_line',
          params: <String, Object?>{
            'company': company.isEmpty
                ? text('life.ai_interview.prompt.not_filled')
                : company,
          },
        ),
      )
      ..writeln(
        text(
          'life.ai_interview.prompt.language_line',
          params: <String, Object?>{
            'language': text(_languageLabelKey(input.language)),
          },
        ),
      )
      ..writeln(
        text(
          'life.ai_interview.prompt.tone_line',
          params: <String, Object?>{'tone': text(_toneLabelKey(input.tone))},
        ),
      )
      ..writeln(
        text(
          'life.ai_interview.prompt.depth_line',
          params: <String, Object?>{'depth': text(_depthLabelKey(input.depth))},
        ),
      )
      ..writeln('')
      ..writeln(text('life.ai_interview.prompt.question_heading'))
      ..writeln(question.isEmpty ? text(_fallbackQuestionKey(type)) : question)
      ..writeln('');
    if (highlights.isNotEmpty) {
      buffer
        ..writeln(text('life.ai_interview.prompt.highlights_heading'))
        ..writeln(highlights.map((item) => '- $item').join('\n'))
        ..writeln('');
    }
    if (answerDraft.isNotEmpty) {
      buffer
        ..writeln(text('life.ai_interview.prompt.draft_heading'))
        ..writeln(answerDraft)
        ..writeln('');
    }
    buffer
      ..writeln(text('life.ai_interview.prompt.output_heading'))
      ..writeln(text('life.ai_interview.prompt.output_60s'))
      ..writeln(text('life.ai_interview.prompt.output_3min'))
      ..writeln(text('life.ai_interview.prompt.output_followups'))
      ..writeln(text('life.ai_interview.prompt.output_evidence'))
      ..writeln(text('life.ai_interview.prompt.output_authenticity'));
    return buffer.toString().trim();
  }

  ToolboxAiInterviewType _detectType(String question) {
    final text = question.toLowerCase();
    final systemDesignSignals = <String>[
      'system design',
      '架构',
      '高并发',
      '缓存',
      '分库',
      '分表',
      '限流',
      '设计一个',
      'design a',
      'scalable',
    ];
    final productCaseSignals = <String>[
      'case',
      '估算',
      '市场',
      '增长',
      '留存',
      '转化',
      '指标',
      '产品',
      '运营',
      'business',
    ];
    final technicalSignals = <String>[
      '算法',
      '代码',
      '数据库',
      '线程',
      '进程',
      '接口',
      'api',
      'bug',
      'debug',
      '性能',
      '复杂度',
      'flutter',
      'dart',
    ];
    final hrSignals = <String>[
      '薪资',
      '离职',
      '加班',
      '优点',
      '缺点',
      '期望',
      '为什么',
      'why do you',
      'salary',
      'strength',
      'weakness',
    ];
    final behavioralSignals = <String>[
      '经历',
      '冲突',
      '失败',
      '成功',
      '协作',
      '压力',
      'tell me about',
      'behavior',
      'example',
      'challenge',
    ];

    if (_containsAny(text, systemDesignSignals)) {
      return ToolboxAiInterviewType.systemDesign;
    }
    if (_containsAny(text, productCaseSignals)) {
      return ToolboxAiInterviewType.productCase;
    }
    if (_containsAny(text, technicalSignals)) {
      return ToolboxAiInterviewType.technical;
    }
    if (_containsAny(text, behavioralSignals)) {
      return ToolboxAiInterviewType.behavioral;
    }
    if (_containsAny(text, hrSignals)) {
      return ToolboxAiInterviewType.hr;
    }
    return ToolboxAiInterviewType.behavioral;
  }

  int _scoreAnswer({
    required String answerDraft,
    required List<String> highlights,
    required ToolboxAiInterviewType type,
    required double strictness,
  }) {
    if (answerDraft.trim().isEmpty) {
      return 0;
    }

    var score = 28;
    final length = answerDraft.runes.length;
    if (length >= 120) {
      score += 14;
    } else if (length >= 60) {
      score += 8;
    }

    final lower = answerDraft.toLowerCase();
    final evidenceSignals = RegExp(
      r'\d|%|倍|w|万|kpi|latency|qps|用户|收入|成本|minutes|users|revenue',
      caseSensitive: false,
    );
    if (evidenceSignals.hasMatch(answerDraft)) {
      score += 14;
    }
    if (_containsAny(lower, _structureSignals(type))) {
      score += 18;
    }
    if (highlights.any(
      (item) => item.isNotEmpty && answerDraft.contains(item),
    )) {
      score += 10;
    }
    if (_containsAny(lower, <String>['复盘', 'trade-off', '权衡', '风险', '验证'])) {
      score += 8;
    }
    if (_containsAny(lower, <String>['我负责', 'i led', 'i built', '我推动'])) {
      score += 8;
    }

    final strictPenalty = ((strictness.clamp(0, 1) - 0.5) * 18).round();
    return (score - strictPenalty).clamp(0, 100);
  }

  List<ToolboxI18nTextRef> _answerOutline({
    required String question,
    required String role,
    required String company,
    required List<String> highlights,
    required ToolboxAiInterviewType type,
    required ToolboxAiInterviewDepth depth,
    required ToolboxAiInterviewLanguage language,
    required ToolboxAiInterviewTone tone,
  }) {
    final roleText = role.isEmpty
        ? const ToolboxI18nTextRef('life.ai_interview.placeholder.target_role')
        : role;
    final companyText = company.isEmpty
        ? const ToolboxI18nTextRef('life.ai_interview.placeholder.target_team')
        : company;
    final signalText = highlights.isEmpty
        ? const ToolboxI18nTextRef(
            'life.ai_interview.placeholder.pick_experience',
          )
        : highlights.take(3).join(' / ');

    final base = switch (type) {
      ToolboxAiInterviewType.behavioral => <ToolboxI18nTextRef>[
        const ToolboxI18nTextRef(
          'life.ai_interview.outline.behavioral.conclusion',
        ),
        const ToolboxI18nTextRef(
          'life.ai_interview.outline.behavioral.situation_task',
        ),
        const ToolboxI18nTextRef('life.ai_interview.outline.behavioral.action'),
        const ToolboxI18nTextRef('life.ai_interview.outline.behavioral.result'),
        ToolboxI18nTextRef(
          'life.ai_interview.outline.behavioral.learning',
          params: <String, Object?>{'role': roleText},
        ),
      ],
      ToolboxAiInterviewType.technical => <ToolboxI18nTextRef>[
        const ToolboxI18nTextRef(
          'life.ai_interview.outline.technical.boundary',
        ),
        const ToolboxI18nTextRef(
          'life.ai_interview.outline.technical.solution',
        ),
        const ToolboxI18nTextRef(
          'life.ai_interview.outline.technical.tradeoff',
        ),
        const ToolboxI18nTextRef(
          'life.ai_interview.outline.technical.validation',
        ),
        ToolboxI18nTextRef(
          'life.ai_interview.outline.technical.experience',
          params: <String, Object?>{'signal': signalText},
        ),
      ],
      ToolboxAiInterviewType.systemDesign => <ToolboxI18nTextRef>[
        const ToolboxI18nTextRef(
          'life.ai_interview.outline.system_design.scale',
        ),
        const ToolboxI18nTextRef('life.ai_interview.outline.system_design.sla'),
        const ToolboxI18nTextRef(
          'life.ai_interview.outline.system_design.core_path',
        ),
        const ToolboxI18nTextRef(
          'life.ai_interview.outline.system_design.cache_queue_storage',
        ),
        const ToolboxI18nTextRef(
          'life.ai_interview.outline.system_design.tradeoffs',
        ),
        const ToolboxI18nTextRef(
          'life.ai_interview.outline.system_design.expand',
        ),
        const ToolboxI18nTextRef(
          'life.ai_interview.outline.system_design.validation',
        ),
      ],
      ToolboxAiInterviewType.productCase => <ToolboxI18nTextRef>[
        const ToolboxI18nTextRef(
          'life.ai_interview.outline.product_case.metric',
        ),
        const ToolboxI18nTextRef(
          'life.ai_interview.outline.product_case.user_scene',
        ),
        const ToolboxI18nTextRef(
          'life.ai_interview.outline.product_case.hypotheses',
        ),
        const ToolboxI18nTextRef(
          'life.ai_interview.outline.product_case.solution_mix',
        ),
        const ToolboxI18nTextRef(
          'life.ai_interview.outline.product_case.review',
        ),
      ],
      ToolboxAiInterviewType.hr => <ToolboxI18nTextRef>[
        const ToolboxI18nTextRef('life.ai_interview.outline.hr.direct_answer'),
        const ToolboxI18nTextRef('life.ai_interview.outline.hr.evidence'),
        const ToolboxI18nTextRef('life.ai_interview.outline.hr.boundary'),
        ToolboxI18nTextRef(
          'life.ai_interview.outline.hr.role_company',
          params: <String, Object?>{'role': roleText, 'company': companyText},
        ),
        const ToolboxI18nTextRef('life.ai_interview.outline.hr.question_back'),
      ],
      ToolboxAiInterviewType.auto => <ToolboxI18nTextRef>[
        const ToolboxI18nTextRef('life.ai_interview.outline.auto.classify'),
        const ToolboxI18nTextRef('life.ai_interview.outline.auto.compress'),
        const ToolboxI18nTextRef('life.ai_interview.outline.auto.evidence'),
      ],
    };

    final additions = switch (depth) {
      ToolboxAiInterviewDepth.quick => <ToolboxI18nTextRef>[
        const ToolboxI18nTextRef('life.ai_interview.outline.depth.quick'),
      ],
      ToolboxAiInterviewDepth.standard => <ToolboxI18nTextRef>[
        const ToolboxI18nTextRef('life.ai_interview.outline.depth.standard'),
      ],
      ToolboxAiInterviewDepth.deep => <ToolboxI18nTextRef>[
        const ToolboxI18nTextRef('life.ai_interview.outline.depth.deep_extra'),
        const ToolboxI18nTextRef(
          'life.ai_interview.outline.depth.deep_rewrite',
        ),
      ],
    };

    final toneHint = switch (tone) {
      ToolboxAiInterviewTone.concise => const ToolboxI18nTextRef(
        'life.ai_interview.outline.tone.concise',
      ),
      ToolboxAiInterviewTone.balanced => const ToolboxI18nTextRef(
        'life.ai_interview.outline.tone.balanced',
      ),
      ToolboxAiInterviewTone.coaching => const ToolboxI18nTextRef(
        'life.ai_interview.outline.tone.coaching',
      ),
    };
    final languageHint = switch (language) {
      ToolboxAiInterviewLanguage.zh => const ToolboxI18nTextRef(
        'life.ai_interview.outline.language.zh',
      ),
      ToolboxAiInterviewLanguage.en => const ToolboxI18nTextRef(
        'life.ai_interview.outline.language.en',
      ),
      ToolboxAiInterviewLanguage.bilingual => const ToolboxI18nTextRef(
        'life.ai_interview.outline.language.bilingual',
      ),
    };

    return <ToolboxI18nTextRef>[...base, ...additions, toneHint, languageHint];
  }

  List<ToolboxI18nTextRef> _evaluationNotes({
    required String answerDraft,
    required List<String> highlights,
    required ToolboxAiInterviewType type,
    required int score,
  }) {
    if (answerDraft.trim().isEmpty) {
      return const <ToolboxI18nTextRef>[
        ToolboxI18nTextRef('life.ai_interview.evaluation.empty.no_draft'),
        ToolboxI18nTextRef('life.ai_interview.evaluation.empty.fill_context'),
      ];
    }

    final notes = <ToolboxI18nTextRef>[];
    final lower = answerDraft.toLowerCase();
    if (!_containsAny(lower, _structureSignals(type))) {
      notes.add(
        const ToolboxI18nTextRef('life.ai_interview.evaluation.structure_weak'),
      );
    }
    if (!RegExp(r'\d|%|万|kpi|qps|ms|用户|收入|成本').hasMatch(answerDraft)) {
      notes.add(
        const ToolboxI18nTextRef('life.ai_interview.evaluation.evidence_weak'),
      );
    }
    if (highlights.isNotEmpty &&
        !highlights.any((item) => answerDraft.contains(item))) {
      notes.add(
        const ToolboxI18nTextRef(
          'life.ai_interview.evaluation.highlights_missing',
        ),
      );
    }
    if (!_containsAny(lower, <String>['复盘', '学到', 'next', '改进', '验证'])) {
      notes.add(
        const ToolboxI18nTextRef('life.ai_interview.evaluation.closing_weak'),
      );
    }
    if (score >= 80) {
      notes.add(
        const ToolboxI18nTextRef('life.ai_interview.evaluation.ready_strong'),
      );
    } else if (score >= 55) {
      notes.add(
        const ToolboxI18nTextRef('life.ai_interview.evaluation.ready_medium'),
      );
    } else {
      notes.add(
        const ToolboxI18nTextRef('life.ai_interview.evaluation.ready_low'),
      );
    }
    return notes;
  }

  List<ToolboxI18nTextRef> _followUps(
    ToolboxAiInterviewType type,
    ToolboxAiInterviewDepth depth,
    String role,
  ) {
    final roleRef = role.isEmpty
        ? const ToolboxI18nTextRef('life.ai_interview.placeholder.target_role')
        : ToolboxI18nTextRef(
            'life.ai_interview.param.raw',
            params: <String, Object?>{'value': role},
          );
    final base = switch (type) {
      ToolboxAiInterviewType.behavioral => <ToolboxI18nTextRef>[
        const ToolboxI18nTextRef(
          'life.ai_interview.follow_up.behavioral.push_when_blocked',
        ),
        const ToolboxI18nTextRef(
          'life.ai_interview.follow_up.behavioral.contribution',
        ),
        const ToolboxI18nTextRef('life.ai_interview.follow_up.behavioral.redo'),
      ],
      ToolboxAiInterviewType.technical => <ToolboxI18nTextRef>[
        const ToolboxI18nTextRef(
          'life.ai_interview.follow_up.technical.complexity',
        ),
        const ToolboxI18nTextRef(
          'life.ai_interview.follow_up.technical.scale_10x',
        ),
        const ToolboxI18nTextRef(
          'life.ai_interview.follow_up.technical.testing',
        ),
      ],
      ToolboxAiInterviewType.systemDesign => <ToolboxI18nTextRef>[
        const ToolboxI18nTextRef(
          'life.ai_interview.follow_up.system_design.consistency_availability',
        ),
        const ToolboxI18nTextRef(
          'life.ai_interview.follow_up.system_design.cache_hot_queue',
        ),
        const ToolboxI18nTextRef(
          'life.ai_interview.follow_up.system_design.mvp_split',
        ),
      ],
      ToolboxAiInterviewType.productCase => <ToolboxI18nTextRef>[
        const ToolboxI18nTextRef(
          'life.ai_interview.follow_up.product_case.first_hypothesis',
        ),
        const ToolboxI18nTextRef(
          'life.ai_interview.follow_up.product_case.metric_no_change',
        ),
        const ToolboxI18nTextRef(
          'life.ai_interview.follow_up.product_case.tradeoff_users',
        ),
      ],
      ToolboxAiInterviewType.hr => <ToolboxI18nTextRef>[
        ToolboxI18nTextRef(
          'life.ai_interview.follow_up.hr.fit_role',
          params: <String, Object?>{'role': roleRef},
        ),
        const ToolboxI18nTextRef(
          'life.ai_interview.follow_up.hr.team_expectation',
        ),
        const ToolboxI18nTextRef('life.ai_interview.follow_up.hr.pressure'),
      ],
      ToolboxAiInterviewType.auto => <ToolboxI18nTextRef>[
        const ToolboxI18nTextRef('life.ai_interview.follow_up.auto.capability'),
        const ToolboxI18nTextRef(
          'life.ai_interview.follow_up.auto.most_challenged',
        ),
      ],
    };
    if (depth != ToolboxAiInterviewDepth.deep) {
      return base;
    }
    return <ToolboxI18nTextRef>[
      ...base,
      const ToolboxI18nTextRef(
        'life.ai_interview.follow_up.deep.ownership_challenge',
      ),
      const ToolboxI18nTextRef('life.ai_interview.follow_up.deep.alternatives'),
    ];
  }

  List<ToolboxI18nTextRef> _actionChecklist(
    ToolboxAiInterviewType type,
    String answerDraft,
  ) {
    const shared = <ToolboxI18nTextRef>[
      ToolboxI18nTextRef('life.ai_interview.action.shared.compress'),
      ToolboxI18nTextRef('life.ai_interview.action.shared.prepare_detail'),
      ToolboxI18nTextRef('life.ai_interview.action.shared.connect_role'),
    ];
    if (answerDraft.trim().isEmpty) {
      return const <ToolboxI18nTextRef>[
        ToolboxI18nTextRef('life.ai_interview.action.empty.write_rough'),
        ToolboxI18nTextRef('life.ai_interview.action.empty.complete_context'),
        ...shared,
      ];
    }
    return switch (type) {
      ToolboxAiInterviewType.technical ||
      ToolboxAiInterviewType.systemDesign => <ToolboxI18nTextRef>[
        const ToolboxI18nTextRef(
          'life.ai_interview.action.tech.check_boundaries',
        ),
        const ToolboxI18nTextRef(
          'life.ai_interview.action.tech.architecture_map',
        ),
        ...shared,
      ],
      ToolboxAiInterviewType.productCase => <ToolboxI18nTextRef>[
        const ToolboxI18nTextRef('life.ai_interview.action.product.north_star'),
        const ToolboxI18nTextRef(
          'life.ai_interview.action.product.disproof_path',
        ),
        ...shared,
      ],
      _ => shared,
    };
  }

  List<String> _splitSignals(String text) {
    return text
        .split(RegExp(r'[,，;；\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  List<String> _structureSignals(ToolboxAiInterviewType type) {
    return switch (type) {
      ToolboxAiInterviewType.behavioral => <String>[
        'star',
        'situation',
        'task',
        'action',
        'result',
        '背景',
        '行动',
        '结果',
      ],
      ToolboxAiInterviewType.technical => <String>[
        '复杂度',
        '边界',
        '测试',
        '方案',
        'trade-off',
        '监控',
      ],
      ToolboxAiInterviewType.systemDesign => <String>[
        '架构',
        '缓存',
        '队列',
        '存储',
        '限流',
        '一致性',
      ],
      ToolboxAiInterviewType.productCase => <String>[
        '指标',
        '假设',
        '实验',
        '转化',
        '留存',
        '用户',
      ],
      ToolboxAiInterviewType.hr => <String>['动机', '匹配', '期待', '原因', '价值'],
      ToolboxAiInterviewType.auto => <String>['结论', '证据', '行动', '结果'],
    };
  }

  bool _containsAny(String text, List<String> signals) {
    return signals.any((signal) => text.contains(signal.toLowerCase()));
  }

  String _normalize(String text) => text.trim().replaceAll(RegExp(r'\s+'), ' ');

  String _fallbackQuestionKey(ToolboxAiInterviewType type) {
    return switch (type) {
      ToolboxAiInterviewType.technical =>
        'life.ai_interview.fallback_question.technical',
      ToolboxAiInterviewType.systemDesign =>
        'life.ai_interview.fallback_question.system_design',
      ToolboxAiInterviewType.productCase =>
        'life.ai_interview.fallback_question.product_case',
      ToolboxAiInterviewType.hr => 'life.ai_interview.fallback_question.hr',
      _ => 'life.ai_interview.fallback_question.behavioral',
    };
  }

  String _typeLabelKey(ToolboxAiInterviewType type) {
    return switch (type) {
      ToolboxAiInterviewType.auto => 'life.ai_interview.type.auto',
      ToolboxAiInterviewType.behavioral => 'life.ai_interview.type.behavioral',
      ToolboxAiInterviewType.technical => 'life.ai_interview.type.technical',
      ToolboxAiInterviewType.systemDesign =>
        'life.ai_interview.type.system_design',
      ToolboxAiInterviewType.productCase =>
        'life.ai_interview.type.product_case',
      ToolboxAiInterviewType.hr => 'life.ai_interview.type.hr',
    };
  }

  String _readinessLabelKey(int score) {
    if (score >= 80) {
      return 'life.ai_interview.readiness.follow_up';
    }
    if (score >= 55) {
      return 'life.ai_interview.readiness.needs_evidence';
    }
    if (score > 0) {
      return 'life.ai_interview.readiness.needs_structure';
    }
    return 'life.ai_interview.readiness.waiting';
  }

  String _languageLabelKey(ToolboxAiInterviewLanguage language) {
    return switch (language) {
      ToolboxAiInterviewLanguage.zh => 'life.ai_interview.language.zh',
      ToolboxAiInterviewLanguage.en => 'life.ai_interview.language.en',
      ToolboxAiInterviewLanguage.bilingual =>
        'life.ai_interview.language.bilingual',
    };
  }

  String _toneLabelKey(ToolboxAiInterviewTone tone) {
    return switch (tone) {
      ToolboxAiInterviewTone.concise => 'life.ai_interview.tone.concise',
      ToolboxAiInterviewTone.balanced => 'life.ai_interview.tone.balanced',
      ToolboxAiInterviewTone.coaching => 'life.ai_interview.tone.coaching',
    };
  }

  String _depthLabelKey(ToolboxAiInterviewDepth depth) {
    return switch (depth) {
      ToolboxAiInterviewDepth.quick => 'life.ai_interview.depth.quick',
      ToolboxAiInterviewDepth.standard => 'life.ai_interview.depth.standard',
      ToolboxAiInterviewDepth.deep => 'life.ai_interview.depth.deep',
    };
  }
}

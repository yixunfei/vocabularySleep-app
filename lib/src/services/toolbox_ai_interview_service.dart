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
    required this.detectedType,
    required this.typeLabelZh,
    required this.typeLabelEn,
    required this.readinessScore,
    required this.readinessLabelZh,
    required this.readinessLabelEn,
    required this.answerOutline,
    required this.evaluationNotes,
    required this.followUpQuestions,
    required this.promptDraft,
    required this.actionChecklist,
    required this.boundaryNotes,
  });

  final String normalizedQuestion;
  final ToolboxAiInterviewType detectedType;
  final String typeLabelZh;
  final String typeLabelEn;
  final int readinessScore;
  final String readinessLabelZh;
  final String readinessLabelEn;
  final List<String> answerOutline;
  final List<String> evaluationNotes;
  final List<String> followUpQuestions;
  final String promptDraft;
  final List<String> actionChecklist;
  final List<String> boundaryNotes;
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
      normalizedQuestion: question.isEmpty ? _fallbackQuestion(type) : question,
      detectedType: type,
      typeLabelZh: _typeLabelZh(type),
      typeLabelEn: _typeLabelEn(type),
      readinessScore: score,
      readinessLabelZh: _readinessLabelZh(score),
      readinessLabelEn: _readinessLabelEn(score),
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
          : const <String>[],
      promptDraft: _promptDraft(
        question: question,
        role: role,
        company: company,
        highlights: highlights,
        answerDraft: answerDraft,
        type: type,
        depth: input.depth,
        language: input.language,
        tone: input.tone,
      ),
      actionChecklist: _actionChecklist(type, answerDraft),
      boundaryNotes: const <String>[
        '本页只做本地练习与答案组织，不进行屏幕捕获、后台监听或实时代答。',
        '不要粘贴身份证号、未公开薪资、客户资料、公司保密题或受 NDA 约束的内容。',
        '输出是结构草稿，不代表真实面试官、招聘方或职业顾问的最终判断。',
      ],
    );
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

  List<String> _answerOutline({
    required String question,
    required String role,
    required String company,
    required List<String> highlights,
    required ToolboxAiInterviewType type,
    required ToolboxAiInterviewDepth depth,
    required ToolboxAiInterviewLanguage language,
    required ToolboxAiInterviewTone tone,
  }) {
    final roleText = role.isEmpty ? '目标岗位' : role;
    final companyText = company.isEmpty ? '目标团队' : company;
    final signalText = highlights.isEmpty
        ? '挑 1-2 个最有说服力的经历'
        : highlights.take(3).join(' / ');

    final base = switch (type) {
      ToolboxAiInterviewType.behavioral => <String>[
        '先用一句话回答结论：你面对的关键矛盾是什么，以及你最终把局面推进到了哪里。',
        'Situation/Task：补充背景、目标、约束和你的职责，避免把团队成果说成个人全部功劳。',
        'Action：按 2-3 个动作展开，优先放入沟通、判断、取舍和执行细节。',
        'Result：给出可验证结果，最好包含数字、时间、质量、用户或团队反馈。',
        'Learning：用一句复盘收尾，说明这段经验如何迁移到 $roleText。',
      ],
      ToolboxAiInterviewType.technical => <String>[
        '先复述问题边界：输入、输出、约束、性能目标和不可做的假设。',
        '给出主方案：核心数据结构、流程、复杂度或关键 API，按步骤说明。',
        '补充权衡：为什么不用另一个方案，风险在哪里，如何降级或扩展。',
        '验证方式：单测、日志、监控、灰度、性能数据或异常场景覆盖。',
        '结合 $signalText，说明你曾经怎么把类似技术判断落到真实项目。',
      ],
      ToolboxAiInterviewType.systemDesign => <String>[
        '先确认规模和 SLA：用户量、峰值流量、读写比例、延迟、可用性和数据一致性。',
        '画出核心链路：客户端、网关、服务、缓存、队列、存储和观测面。',
        '分层讨论取舍：缓存命中、限流熔断、异步化、分片、容灾和回滚。',
        '用瓶颈驱动扩展：指出第一阶段能跑、第二阶段如何横向扩展。',
        '收尾给验证清单：压测指标、告警项、容量预估和失败演练。',
      ],
      ToolboxAiInterviewType.productCase => <String>[
        '先定义目标指标：增长、留存、转化、收入、效率或体验，避免泛泛谈方案。',
        '拆解用户和场景：谁在什么情境下遇到什么问题，现有替代方案是什么。',
        '给出 2-3 个假设，并说明验证数据、样本来源和优先级。',
        '提出方案组合：短期实验、中期机制、长期壁垒，并标出风险。',
        '用复盘口径收尾：如果指标没有变好，下一步会查哪条链路。',
      ],
      ToolboxAiInterviewType.hr => <String>[
        '先正面回答，不绕圈；把动机和岗位匹配讲清楚。',
        '用 1 个真实证据支撑判断，避免只说性格词或空泛价值观。',
        '涉及离职、薪资、加班时保持边界：讲事实、讲期待，不攻击前团队。',
        '把回答落回 $roleText 与 $companyText：你能贡献什么，也想获得什么。',
        '准备 1 个反问，体现你在认真评估团队和岗位。',
      ],
      ToolboxAiInterviewType.auto => <String>[
        '先判断题型，再选择 STAR、技术拆解、系统设计或业务 case 框架。',
        '把答案压成 60-90 秒主线，复杂内容再准备 3 分钟扩展版。',
        '每段都补一个证据点：数字、上下文、你的动作或复盘。',
      ],
    };

    final additions = switch (depth) {
      ToolboxAiInterviewDepth.quick => <String>['快速模式：保留 3 个最强点即可，先保证回答不散。'],
      ToolboxAiInterviewDepth.standard => <String>['标准模式：准备 60 秒口述版和 3 分钟追问版。'],
      ToolboxAiInterviewDepth.deep => <String>[
        '深度模式：额外准备反例、失败路径、替代方案和面试官可能质疑的薄弱点。',
        '把回答改写成“结论 -> 证据 -> 取舍 -> 复盘”的节奏，减少流水账。',
      ],
    };

    final toneHint = switch (tone) {
      ToolboxAiInterviewTone.concise => '语气保持短句和强结论，避免解释过满。',
      ToolboxAiInterviewTone.balanced => '语气保持自然、具体、不过度包装。',
      ToolboxAiInterviewTone.coaching => '语气可以加入复盘意识，体现可成长性。',
    };
    final languageHint = switch (language) {
      ToolboxAiInterviewLanguage.zh => '输出以中文为主。',
      ToolboxAiInterviewLanguage.en =>
        'Output in English, with interview-ready phrasing.',
      ToolboxAiInterviewLanguage.bilingual => '先中文组织逻辑，再给英文口述关键词。',
    };

    return <String>[...base, ...additions, toneHint, languageHint];
  }

  List<String> _evaluationNotes({
    required String answerDraft,
    required List<String> highlights,
    required ToolboxAiInterviewType type,
    required int score,
  }) {
    if (answerDraft.trim().isEmpty) {
      return const <String>[
        '还没有回答草稿。先写 3-5 句话，再让本页帮你检查结构和证据密度。',
        '建议先填岗位、公司和 2-3 个简历亮点，这会让提示词更贴近真实面试。',
      ];
    }

    final notes = <String>[];
    final lower = answerDraft.toLowerCase();
    if (!_containsAny(lower, _structureSignals(type))) {
      notes.add('结构信号偏弱：建议显式写出背景、行动、结果或方案权衡。');
    }
    if (!RegExp(r'\d|%|万|kpi|qps|ms|用户|收入|成本').hasMatch(answerDraft)) {
      notes.add('证据密度偏弱：补充数字、时间、规模、质量或反馈。');
    }
    if (highlights.isNotEmpty &&
        !highlights.any((item) => answerDraft.contains(item))) {
      notes.add('简历亮点没有进入回答：至少接入一个可追问的经历关键词。');
    }
    if (!_containsAny(lower, <String>['复盘', '学到', 'next', '改进', '验证'])) {
      notes.add('收尾可以更强：补一句复盘、验证方式或迁移到目标岗位的价值。');
    }
    if (score >= 80) {
      notes.add('当前草稿已经具备可面试表达的骨架，下一步重点是压缩语言和准备追问。');
    } else if (score >= 55) {
      notes.add('当前草稿可用，但还需要增强证据和取舍细节。');
    } else {
      notes.add('当前草稿更像素材清单，建议先重组为“结论 -> 证据 -> 行动 -> 结果”。');
    }
    return notes;
  }

  List<String> _followUps(
    ToolboxAiInterviewType type,
    ToolboxAiInterviewDepth depth,
    String role,
  ) {
    final roleText = role.isEmpty ? '这个岗位' : role;
    final base = switch (type) {
      ToolboxAiInterviewType.behavioral => <String>[
        '如果对方当时不配合，你具体怎么推进？',
        '这件事里你个人最关键的贡献是什么？',
        '如果重来一次，你会怎么做得更好？',
      ],
      ToolboxAiInterviewType.technical => <String>[
        '这个方案的复杂度、瓶颈和最容易出错的边界是什么？',
        '如果流量或数据量扩大 10 倍，你先改哪里？',
        '你会怎么设计测试来证明方案可靠？',
      ],
      ToolboxAiInterviewType.systemDesign => <String>[
        '数据一致性和可用性冲突时，你怎么取舍？',
        '缓存穿透、热点 key、队列堆积分别怎么处理？',
        '第一版最小可行架构是什么，什么时候需要拆服务？',
      ],
      ToolboxAiInterviewType.productCase => <String>[
        '你会先验证哪一个假设，为什么？',
        '如果核心指标没有变化，你怎么定位问题？',
        '这个方案会牺牲哪些用户或业务目标？',
      ],
      ToolboxAiInterviewType.hr => <String>[
        '你为什么认为 $roleText 适合你？',
        '你对团队、管理方式和成长路径有什么期待？',
        '如果岗位压力比预期更高，你会怎么判断是否继续？',
      ],
      ToolboxAiInterviewType.auto => <String>[
        '这道题最可能考察什么能力？',
        '你的回答里哪一点最容易被继续追问？',
      ],
    };
    if (depth != ToolboxAiInterviewDepth.deep) {
      return base;
    }
    return <String>[
      ...base,
      '面试官如果质疑这个结果不是你主导的，你如何澄清？',
      '有没有失败版本、替代方案或成本更低的做法？',
    ];
  }

  String _promptDraft({
    required String question,
    required String role,
    required String company,
    required List<String> highlights,
    required String answerDraft,
    required ToolboxAiInterviewType type,
    required ToolboxAiInterviewDepth depth,
    required ToolboxAiInterviewLanguage language,
    required ToolboxAiInterviewTone tone,
  }) {
    final buffer = StringBuffer()
      ..writeln('你是严格但友善的面试教练。请帮我准备一段真实、合规、可口述的面试回答。')
      ..writeln('题型：${_typeLabelZh(type)}')
      ..writeln('目标岗位：${role.isEmpty ? '未填写' : role}')
      ..writeln('目标公司/团队：${company.isEmpty ? '未填写' : company}')
      ..writeln('输出语言：${_languageLabel(language)}')
      ..writeln('回答风格：${_toneLabel(tone)}')
      ..writeln('分析深度：${_depthLabel(depth)}')
      ..writeln('')
      ..writeln('面试题：')
      ..writeln(question.isEmpty ? _fallbackQuestion(type) : question)
      ..writeln('');
    if (highlights.isNotEmpty) {
      buffer
        ..writeln('我的可用经历/亮点：')
        ..writeln(highlights.map((item) => '- $item').join('\n'))
        ..writeln('');
    }
    if (answerDraft.isNotEmpty) {
      buffer
        ..writeln('我的草稿：')
        ..writeln(answerDraft)
        ..writeln('');
    }
    buffer
      ..writeln('请输出：')
      ..writeln('1. 60 秒口述版')
      ..writeln('2. 3 分钟展开版')
      ..writeln('3. 面试官可能追问的 5 个问题')
      ..writeln('4. 需要我补充的事实证据清单')
      ..writeln('5. 哪些表达听起来不真实或过度包装');
    return buffer.toString().trim();
  }

  List<String> _actionChecklist(
    ToolboxAiInterviewType type,
    String answerDraft,
  ) {
    final shared = <String>[
      '把答案压到 60-90 秒，保留 1 个主故事和 2 个证据点。',
      '准备一个可追问细节：数字、冲突、取舍、失败或复盘。',
      '最后用一句话连接目标岗位，不要只停在过去经历。',
    ];
    if (answerDraft.trim().isEmpty) {
      return <String>['先写一个粗糙草稿，不追求完美。', '补充岗位、公司和简历亮点后再复制提示词。', ...shared];
    }
    return switch (type) {
      ToolboxAiInterviewType.technical ||
      ToolboxAiInterviewType.systemDesign => <String>[
        '检查边界条件、复杂度、监控和失败降级是否都讲到了。',
        '准备一张脑内架构图：入口、核心链路、数据层和观测面。',
        ...shared,
      ],
      ToolboxAiInterviewType.productCase => <String>[
        '明确北极星指标和第一轮实验，不要只罗列功能。',
        '给出一个反证路径：如果数据不动，先查什么。',
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

  String _fallbackQuestion(ToolboxAiInterviewType type) {
    return switch (type) {
      ToolboxAiInterviewType.technical => '请讲一个你解决复杂技术问题的例子。',
      ToolboxAiInterviewType.systemDesign => '请设计一个可扩展的核心业务系统。',
      ToolboxAiInterviewType.productCase => '请分析一个产品指标下降的问题。',
      ToolboxAiInterviewType.hr => '你为什么想加入这个岗位？',
      _ => '请讲一次你处理挑战或冲突的经历。',
    };
  }

  String _typeLabelZh(ToolboxAiInterviewType type) {
    return switch (type) {
      ToolboxAiInterviewType.auto => '自动识别',
      ToolboxAiInterviewType.behavioral => '行为面试',
      ToolboxAiInterviewType.technical => '技术问答',
      ToolboxAiInterviewType.systemDesign => '系统设计',
      ToolboxAiInterviewType.productCase => '产品/业务 Case',
      ToolboxAiInterviewType.hr => 'HR/动机题',
    };
  }

  String _typeLabelEn(ToolboxAiInterviewType type) {
    return switch (type) {
      ToolboxAiInterviewType.auto => 'Auto',
      ToolboxAiInterviewType.behavioral => 'Behavioral',
      ToolboxAiInterviewType.technical => 'Technical',
      ToolboxAiInterviewType.systemDesign => 'System design',
      ToolboxAiInterviewType.productCase => 'Product/case',
      ToolboxAiInterviewType.hr => 'HR/motivation',
    };
  }

  String _readinessLabelZh(int score) {
    if (score >= 80) {
      return '可进入模拟追问';
    }
    if (score >= 55) {
      return '需要补证据';
    }
    if (score > 0) {
      return '需要重组结构';
    }
    return '等待草稿';
  }

  String _readinessLabelEn(int score) {
    if (score >= 80) {
      return 'Ready for follow-up';
    }
    if (score >= 55) {
      return 'Needs evidence';
    }
    if (score > 0) {
      return 'Needs structure';
    }
    return 'Waiting for draft';
  }

  String _languageLabel(ToolboxAiInterviewLanguage language) {
    return switch (language) {
      ToolboxAiInterviewLanguage.zh => '中文',
      ToolboxAiInterviewLanguage.en => 'English',
      ToolboxAiInterviewLanguage.bilingual => '中英双语',
    };
  }

  String _toneLabel(ToolboxAiInterviewTone tone) {
    return switch (tone) {
      ToolboxAiInterviewTone.concise => '结论先行、简洁',
      ToolboxAiInterviewTone.balanced => '自然平衡、具体',
      ToolboxAiInterviewTone.coaching => '复盘导向、体现成长',
    };
  }

  String _depthLabel(ToolboxAiInterviewDepth depth) {
    return switch (depth) {
      ToolboxAiInterviewDepth.quick => '快速',
      ToolboxAiInterviewDepth.standard => '标准',
      ToolboxAiInterviewDepth.deep => '深度',
    };
  }
}

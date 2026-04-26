import 'package:flutter/material.dart';

import '../../../i18n/app_i18n.dart';
import '../../ui_copy.dart';
import 'daily_choice_decision_engine.dart';
import 'daily_choice_models.dart';

class DailyChoiceDecisionMethodSpec {
  const DailyChoiceDecisionMethodSpec({
    required this.method,
    required this.icon,
    required this.titleZh,
    required this.titleEn,
    required this.subtitleZh,
    required this.subtitleEn,
    required this.formulaZh,
    required this.formulaEn,
    required this.cautionZh,
    required this.cautionEn,
  });

  final DailyChoiceDecisionMethod method;
  final IconData icon;
  final String titleZh;
  final String titleEn;
  final String subtitleZh;
  final String subtitleEn;
  final String formulaZh;
  final String formulaEn;
  final String cautionZh;
  final String cautionEn;

  String title(AppI18n i18n) => pickUiText(i18n, zh: titleZh, en: titleEn);

  String subtitle(AppI18n i18n) =>
      pickUiText(i18n, zh: subtitleZh, en: subtitleEn);

  String formula(AppI18n i18n) =>
      pickUiText(i18n, zh: formulaZh, en: formulaEn);

  String caution(AppI18n i18n) =>
      pickUiText(i18n, zh: cautionZh, en: cautionEn);
}

DailyChoiceDecisionMethodSpec decisionMethodSpec(
  DailyChoiceDecisionMethod method,
) {
  return switch (method) {
    DailyChoiceDecisionMethod.random => const DailyChoiceDecisionMethodSpec(
      method: DailyChoiceDecisionMethod.random,
      icon: Icons.casino_rounded,
      titleZh: '均匀随机',
      titleEn: 'Uniform random',
      subtitleZh: '适合低风险、可回退、差别不大的日常选择。',
      subtitleEn:
          'Best for low-stakes, reversible choices with tiny differences.',
      formulaZh: '每个选项概率相同，目的是尽快结束犹豫。',
      formulaEn:
          'Each option gets the same chance. The goal is to end dithering fast.',
      cautionZh: '不要把随机当成高风险决策的依据。',
      cautionEn: 'Do not use random choice for high-stakes decisions.',
    ),
    DailyChoiceDecisionMethod.weightedFactors =>
      const DailyChoiceDecisionMethodSpec(
        method: DailyChoiceDecisionMethod.weightedFactors,
        icon: Icons.tune_rounded,
        titleZh: '加权因素',
        titleEn: 'Weighted factors',
        subtitleZh: '把价值、成功率、可回退性、风险和信息差放到同一把尺子上比较。',
        subtitleEn:
            'Compare value, success odds, reversibility, risk, and info gaps on one ruler.',
        formulaZh: '正向项加权 - 风险/投入/后悔/信息差惩罚。',
        formulaEn:
            'Weighted positives minus penalties for risk, effort, regret, and info gaps.',
        cautionZh: '它适合排序，不代表绝对正确。',
        cautionEn: 'Useful for ranking, not for claiming certainty.',
      ),
    DailyChoiceDecisionMethod.expectedValue =>
      const DailyChoiceDecisionMethodSpec(
        method: DailyChoiceDecisionMethod.expectedValue,
        icon: Icons.functions_rounded,
        titleZh: '期望收益',
        titleEn: 'Expected value',
        subtitleZh: '适合结果不确定、但可以估一个大致成功率的选择。',
        subtitleEn:
            'Best for uncertain outcomes when you can estimate rough odds.',
        formulaZh: '成功概率 × 收益 - 失败暴露 - 投入成本。',
        formulaEn:
            'Success probability × upside - downside exposure - effort cost.',
        cautionZh: '输入概率来自你的判断，先做独立估值再讨论。',
        cautionEn:
            'Your inputs are still judgments, so estimate independently first.',
      ),
    DailyChoiceDecisionMethod.jointProbability => const DailyChoiceDecisionMethodSpec(
      method: DailyChoiceDecisionMethod.jointProbability,
      icon: Icons.account_tree_rounded,
      titleZh: '联合概率',
      titleEn: 'Joint probability',
      subtitleZh: '当结果需要“判断对 + 执行到位 + 条件真的成立”时，用更保守的乘法。',
      subtitleEn:
          'Use a conservative product when success needs multiple things to line up.',
      formulaZh: '成功概率 × 执行概率 × 把握度，再扣掉下行暴露。',
      formulaEn:
          'Success probability × execution probability × confidence, then subtract downside exposure.',
      cautionZh: '适合多条件联动，不适合把彼此强相关的事件硬拆开。',
      cautionEn:
          'Great for multi-step dependence, weaker when the events are strongly correlated.',
    ),
    DailyChoiceDecisionMethod.scenarioBlend => const DailyChoiceDecisionMethodSpec(
      method: DailyChoiceDecisionMethod.scenarioBlend,
      icon: Icons.alt_route_rounded,
      titleZh: '情景分析',
      titleEn: 'Scenario blend',
      subtitleZh: '把乐观、基准、悲观三种情景同时摆出来，避免只盯着最好结果。',
      subtitleEn:
          'Blend optimistic, base, and pessimistic scenarios so you do not stare only at the upside.',
      formulaZh: '乐观 + 基准 + 悲观按不确定性加权汇总。',
      formulaEn: 'A weighted blend of optimistic, base, and pessimistic cases.',
      cautionZh: '高不确定时要让悲观情景真正进场。',
      cautionEn:
          'When uncertainty is high, let the pessimistic case carry real weight.',
    ),
    DailyChoiceDecisionMethod.regretBalance => const DailyChoiceDecisionMethodSpec(
      method: DailyChoiceDecisionMethod.regretBalance,
      icon: Icons.history_toggle_off_rounded,
      titleZh: '后悔与机会成本',
      titleEn: 'Regret and opportunity cost',
      subtitleZh: '适合容易事后反复想“早知道就选另一个”的选择。',
      subtitleEn:
          'Useful when you are likely to revisit the decision and ask what you should have chosen.',
      formulaZh: '已实现潜力 + 可回退补偿 - 后悔暴露 - 机会成本。',
      formulaEn:
          'Realized upside plus reversibility buffer minus regret exposure and opportunity cost.',
      cautionZh: '它是在校正情绪，不是在预测命运。',
      cautionEn: 'This lens corrects emotion; it does not predict destiny.',
    ),
    DailyChoiceDecisionMethod.thresholdGuardrail =>
      const DailyChoiceDecisionMethodSpec(
        method: DailyChoiceDecisionMethod.thresholdGuardrail,
        icon: Icons.rule_rounded,
        titleZh: '底线守门',
        titleEn: 'Guardrails first',
        subtitleZh: '先看是否过最低门槛，再在过线选项里比较优先级。',
        subtitleEn:
            'Check minimum standards first, then rank only the options that clear them.',
        formulaZh: '先判定信心、风险、可回退性、信息差是否过线，再用综合分做同档比较。',
        formulaEn:
            'Check confidence, downside, reversibility, and info gaps first, then break ties with a composite score.',
        cautionZh: '高风险场景先守门，再谈收益。',
        cautionEn:
            'In high-stakes situations, protect the floor before chasing upside.',
      ),
    DailyChoiceDecisionMethod.calibratedForecast =>
      const DailyChoiceDecisionMethodSpec(
        method: DailyChoiceDecisionMethod.calibratedForecast,
        icon: Icons.show_chart_rounded,
        titleZh: '校准预测',
        titleEn: 'Calibrated forecast',
        subtitleZh: '把过于极端的期望值往均值拉回，减少过度自信。',
        subtitleEn:
            'Shrink extreme forecasts back toward the mean to curb overconfidence.',
        formulaZh: '平均值 + 把握度 × (原始预期 - 平均值)。',
        formulaEn:
            'Average score + confidence × (raw forecast - average forecast).',
        cautionZh: '它不是机器学习，只是把极端判断收一点。',
        cautionEn:
            'This is not machine learning; it is a disciplined pull back from extremes.',
      ),
  };
}

const List<DailyChoiceGuideModule>
decisionGuideModules = <DailyChoiceGuideModule>[
  DailyChoiceGuideModule(
    id: 'sources',
    icon: Icons.library_books_rounded,
    titleZh: '资料来源',
    titleEn: 'Sources',
    subtitleZh: '本页整理自 3 份本地决策参考资料，再转写成移动端可执行工作流。',
    subtitleEn:
        'This guide distills three local decision references into a practical mobile workflow.',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.psychology_rounded,
        titleZh: '《不确定世界的理性选择》',
        titleEn: 'Rational Choice in an Uncertain World',
        bodyZh: '主要提供概率思维、锚定与调整、沉没成本、后见之明、联合概率、回归到均值和贝叶斯更新等判断框架。',
        bodyEn:
            'Main source for probability thinking, anchoring, sunk cost, hindsight, joint probability, regression to the mean, and Bayesian updating.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.balance_rounded,
        titleZh: '《决策思维八部曲》',
        titleEn: 'Decision Thinking Eight-Part Set',
        bodyZh: '重点帮助我们区分偏差和噪声，强调结构化判断、外部视角、检查清单和“决策卫生”。',
        bodyEn:
            'Highlights the difference between bias and noise, and stresses structured judgment, outside views, checklists, and decision hygiene.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.school_rounded,
        titleZh: '《斯坦福商业决策课》',
        titleEn: 'Stanford Decision Quality',
        bodyZh: '核心是优质决策的六要素：合适框架、创造选项、可靠信息、清晰价值、充分论证、付诸行动。',
        bodyEn:
            'The core contribution is the six elements of decision quality: framing, creative options, reliable information, clear values, sound reasoning, and action.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'flow',
    icon: Icons.route_rounded,
    titleZh: '先分型再选法',
    titleEn: 'Classify before choosing a method',
    subtitleZh: '真正高质量的决策，先判断是什么类型，再决定用哪种计算镜头。',
    subtitleEn:
        'High-quality decisions start by identifying the type of decision before choosing the math lens.',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.low_priority_rounded,
        titleZh: '低风险且可回退：直接快决',
        titleEn: 'Low stakes and reversible: decide fast',
        bodyZh: '餐厅、周末安排、轻量购买这类问题，重点不是“最优”，而是别把精力耗在犹豫上。随机或加权因素通常就够。',
        bodyEn:
            'For restaurants, weekend plans, or lightweight purchases, the point is not perfection. Random choice or weighted factors are usually enough.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.warning_amber_rounded,
        titleZh: '高风险或难回头：先设底线',
        titleEn: 'High stakes or hard to undo: set guardrails first',
        bodyZh: '如果一旦做错很难补救，先看风险、把握度、信息差和可回退性是否过线，再比较收益。',
        bodyEn:
            'When mistakes are costly to unwind, check risk, confidence, info gaps, and reversibility before chasing upside.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.cloud_sync_rounded,
        titleZh: '高不确定：一定要把悲观情景拉进来',
        titleEn: 'High uncertainty: bring in the pessimistic case',
        bodyZh: '当你知道自己不知道很多时，单一分数不够，要同时看联合概率、情景分析和信息价值。',
        bodyEn:
            'When you know you do not know enough, a single score is not enough. Use joint probability, scenarios, and information value together.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'quality',
    icon: Icons.workspace_premium_rounded,
    titleZh: '优质决策六要素',
    titleEn: 'Six elements of decision quality',
    subtitleZh: '来自斯坦福决策质量框架，是这个子模块最重要的骨架。',
    subtitleEn:
        'Taken from the Stanford decision-quality framework. This is the backbone of the module.',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.filter_center_focus_rounded,
        titleZh: '先把问题框准',
        titleEn: 'Frame the question correctly',
        bodyZh: '先明确你在决定什么、时间范围是什么、哪些约束不能破。问题框错了，再精细计算也会偏。',
        bodyEn:
            'Clarify what is being decided, the time horizon, and which constraints are non-negotiable. A bad frame corrupts later analysis.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.auto_fix_high_rounded,
        titleZh: '至少造出 2 到 3 个可选项',
        titleEn: 'Generate at least 2 to 3 viable options',
        bodyZh: '很多糟糕决策不是在坏选项里选，而是根本没有认真生成备选。先扩展，再收口。',
        bodyEn:
            'Many bad decisions happen because the option set was poor, not because comparison failed. Expand first, then narrow.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.fact_check_rounded,
        titleZh: '信息要相关且可靠',
        titleEn: 'Use relevant and reliable information',
        bodyZh: '不是信息越多越好，而是越接近关键不确定因素越好。信息差高时，先问“哪条信息最可能改变结论”。',
        bodyEn:
            'More information is not always better. Focus on the facts that are closest to the real uncertainty. Ask which missing fact could actually change the choice.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.scale_rounded,
        titleZh: '把价值和权衡写出来',
        titleEn: 'Write down values and tradeoffs',
        bodyZh: '收益、成本、时间、体力、风险、体面、长期空间，哪些最重要，最好先写下来，再评分。',
        bodyEn:
            'List what matters most before you score: upside, cost, time, energy, risk, reputation, or long-term room to grow.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.analytics_rounded,
        titleZh: '论证要透明，可复盘',
        titleEn: 'Keep reasoning transparent and reviewable',
        bodyZh: '不要只说“我感觉”。把概率、假设、门槛和为什么输给别的方案讲清楚，之后才知道该修哪一步。',
        bodyEn:
            'Do not stop at “it feels right.” Make the probabilities, assumptions, thresholds, and tradeoffs visible so the decision can be reviewed later.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.playlist_add_check_circle_rounded,
        titleZh: '决定后必须落到动作',
        titleEn: 'A decision must end in action',
        bodyZh: '没有下一步动作的“决策”，往往只是延迟焦虑。决定后至少写下第一步、截止点和复盘时间。',
        bodyEn:
            'A decision with no next action is usually just postponed anxiety. End with a first step, a stop point, and a review moment.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'probability',
    icon: Icons.functions_rounded,
    titleZh: '概率与不确定性',
    titleEn: 'Probability and uncertainty',
    subtitleZh: '把“确定/不确定”的情绪语言，转成更可比较的概率语言。',
    subtitleEn:
        'Translate emotional certainty into probability language that can actually be compared.',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.percent_rounded,
        titleZh: '先给概率，再谈结论',
        titleEn: 'Assign probabilities before conclusions',
        bodyZh: '把“我觉得会成”改成“我估计成功率 0.65 左右”。粗略也没关系，关键是强迫自己显式表达不确定性。',
        bodyEn:
            'Replace “I think it will work” with something like “I estimate the success chance around 0.65.” Rough is fine. Explicit beats vague.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.merge_type_rounded,
        titleZh: '多条件同时成立时，用乘法更保守',
        titleEn: 'Use multiplication when several conditions must hold',
        bodyZh: '如果一个结果依赖多个环节都不掉链子，联合概率通常比单一主观概率更诚实。',
        bodyEn:
            'When success depends on several links all holding together, joint probability is usually more honest than one broad guess.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.compare_arrows_rounded,
        titleZh: '高不确定时，把极端判断往均值拉回',
        titleEn: 'Pull extreme forecasts back toward the mean',
        bodyZh: '当证据不足但你给了很高或很低的预期，先做一次校准预测，防止过度自信或过度悲观。',
        bodyEn:
            'If evidence is thin but your forecast is extreme, run a calibrated forecast to reduce overconfidence or over-pessimism.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.update_rounded,
        titleZh: '新证据来了，就更新，不要硬扛',
        titleEn: 'Update when evidence changes',
        bodyZh: '贝叶斯思维的核心不是公式，而是接受“我之前估错了，现在该改”。',
        bodyEn:
            'The core of Bayesian thinking is not the formula. It is the willingness to say, “I estimated badly before, and now I will update.”',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'bias_noise',
    icon: Icons.shield_moon_rounded,
    titleZh: '偏差与噪声校正',
    titleEn: 'Bias and noise control',
    subtitleZh: '避免被锚点、沉没成本、故事感和群体噪声带跑。',
    subtitleEn:
        'Avoid getting dragged around by anchors, sunk costs, compelling stories, or group noise.',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.ads_click_rounded,
        titleZh: '先独立估，再交流，防锚定',
        titleEn: 'Estimate independently before discussion',
        bodyZh: '一旦先看到别人给的数或强烈意见，你自己的判断很容易被拖走。先写，再看。',
        bodyEn:
            'Once you see someone else’s number or strong opinion, your own judgment drifts. Write yours down first.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.money_off_csred_rounded,
        titleZh: '沉没成本不是继续投入的理由',
        titleEn: 'Sunk cost is not a reason to continue',
        bodyZh: '已经花掉、且回不来的时间和钱，不该决定下一步。下一步只看未来成本和未来回报。',
        bodyEn:
            'Past time and money that cannot be recovered should not govern the next step. Look only at future cost and future value.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.grid_view_rounded,
        titleZh: '用统一尺度逐项比较，降低噪声',
        titleEn: 'Use a common scale to reduce noise',
        bodyZh: '对每个选项都用同一组字段、同一组尺度、同一顺序去评估，比“想到什么算什么”稳定得多。',
        bodyEn:
            'Using the same fields, scales, and order across options is much more stable than improvising criteria as you go.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.visibility_rounded,
        titleZh: '故事好听，不等于证据够强',
        titleEn: 'A good story is not strong evidence',
        bodyZh: '确认偏差、后见之明和幸存者偏差都会让故事显得过于圆满。回到数据、概率和基准率。',
        bodyEn:
            'Confirmation bias, hindsight, and survivorship bias all make stories seem more convincing than they are. Go back to numbers, probabilities, and base rates.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'action',
    icon: Icons.task_alt_rounded,
    titleZh: '何时继续查，何时直接做',
    titleEn: 'When to research more and when to move',
    subtitleZh: '信息价值不是无限的，分析也需要停表点。',
    subtitleEn: 'Information has value, but analysis still needs a stop point.',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.travel_explore_rounded,
        titleZh: '如果一条信息最可能改结论，就先去补它',
        titleEn: 'Collect the one fact most likely to change the answer',
        bodyZh: '不是“继续搜一搜”这么模糊，而是明确要补什么信息、什么时候补到停止。',
        bodyEn:
            'Do not just “do more research.” Define which missing fact matters and when the search stops.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.timer_rounded,
        titleZh: '设停止规则，防止无限分析',
        titleEn: 'Set a stopping rule',
        bodyZh: '例如“今晚 10 点前补完 3 条证据就定”“连续两轮结果一致就执行”。没有停止规则，焦虑会冒充认真。',
        bodyEn:
            'Examples: “I decide after three pieces of evidence” or “I act once two rounds agree.” Without a stop rule, anxiety pretends to be diligence.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.report_problem_rounded,
        titleZh: '高风险先做一次预演式失败复盘',
        titleEn: 'Run a premortem for high-stakes choices',
        bodyZh: '假设三个月后这件事失败了，最可能是因为什么。把最容易翻车的环节提前写出来。',
        bodyEn:
            'Imagine the choice has failed three months from now. What most likely caused it? Write down the plausible failure modes now.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.health_and_safety_rounded,
        titleZh: '医疗、法律、金融仍需专业判断',
        titleEn: 'Medical, legal, and financial calls still need experts',
        bodyZh: '这个模块适合辅助日常与一般工作生活决策，不替代医生、律师、理财顾问或正式风控流程。',
        bodyEn:
            'This module supports everyday and general work-life decisions. It does not replace doctors, lawyers, financial advisers, or formal risk controls.',
      ),
    ],
  ),
];

List<DailyChoiceGuideEntry> buildDecisionHygieneEntries({
  required DailyChoiceDecisionContext context,
  required DailyChoiceDecisionReport report,
}) {
  final entries = <DailyChoiceGuideEntry>[
    const DailyChoiceGuideEntry(
      icon: Icons.ads_click_rounded,
      titleZh: '先独立打分，再看别人意见',
      titleEn: 'Score independently first',
      bodyZh: '锚定通常发生在讨论开始前。先写自己的概率、风险和收益，再去听外部意见。',
      bodyEn:
          'Anchoring happens before the conversation even starts. Write your own probabilities, risks, and payoffs before hearing outside views.',
    ),
    const DailyChoiceGuideEntry(
      icon: Icons.money_off_rounded,
      titleZh: '不要为沉没成本追加投入',
      titleEn: 'Do not double down on sunk cost',
      bodyZh: '已经花出去的时间、金钱和面子，不是继续的理由。下一步只看未来代价与未来价值。',
      bodyEn:
          'Past time, money, or ego are not reasons to continue. The next move should be based only on future cost and future value.',
    ),
    const DailyChoiceGuideEntry(
      icon: Icons.rule_folder_rounded,
      titleZh: '用同一套字段比较所有选项',
      titleEn: 'Use the same fields for every option',
      bodyZh: '噪声常来自“这个方案看重努力，另一个方案却看重结果”。统一标准比争论更能降噪。',
      bodyEn:
          'Noise often comes from shifting standards midstream. Consistent fields reduce noise better than more argument.',
    ),
  ];

  if (context.uncertainty == DailyChoiceDecisionLevel.high) {
    entries.add(
      const DailyChoiceGuideEntry(
        icon: Icons.insights_rounded,
        titleZh: '高不确定时，优先看基准率和均值回归',
        titleEn: 'Use base rates when uncertainty is high',
        bodyZh: '当你没有足够案例支撑极端判断时，先用校准预测把预期拉回中间，再看证据是否足以推离均值。',
        bodyEn:
            'If you do not have enough evidence for an extreme forecast, pull it toward the middle first and then ask whether the evidence is strong enough to move away from the mean.',
      ),
    );
  }

  if (report.infoSignal.shouldGatherMoreInfo) {
    entries.add(
      const DailyChoiceGuideEntry(
        icon: Icons.travel_explore_rounded,
        titleZh: '先补最可能改变结论的那条信息',
        titleEn: 'Research the fact most likely to change the answer',
        bodyZh: '如果要继续查，不要散着查。先找那条最可能把胜负翻过去的信息，再决定是否值得继续。',
        bodyEn:
            'If you do more research, do not do it randomly. Target the single fact most likely to flip the choice first.',
      ),
    );
  }

  if (context.stakes == DailyChoiceDecisionLevel.high) {
    entries.add(
      const DailyChoiceGuideEntry(
        icon: Icons.report_rounded,
        titleZh: '高风险决策先做一次预演式复盘',
        titleEn: 'Run a premortem for high stakes',
        bodyZh: '假设结果失败了，最可能会输在哪一步。把这一步写出来，通常比继续堆更多信息更有用。',
        bodyEn:
            'Assume the decision fails. Where is it most likely to break? Writing that down is often more useful than endlessly gathering more information.',
      ),
    );
  }

  if (report.consensus.stability < 0.5) {
    entries.add(
      const DailyChoiceGuideEntry(
        icon: Icons.compare_rounded,
        titleZh: '跨方法分歧大时，回到价值排序',
        titleEn: 'Return to value ranking when methods disagree',
        bodyZh: '不同方法若给出不同答案，通常不是模型错了，而是你真正看重的东西还没排清楚。',
        bodyEn:
            'When the methods disagree, the problem is often not the math. It is that your true priorities have not been ranked clearly yet.',
      ),
    );
  }

  if (context.urgency == DailyChoiceDecisionUrgency.now) {
    entries.add(
      const DailyChoiceGuideEntry(
        icon: Icons.timer_rounded,
        titleZh: '现在就要定时，先写下停止规则',
        titleEn: 'If you must decide now, define a stopping rule',
        bodyZh: '例如“看完这轮排名和守门线就执行，不再开新变量”。在时间压力下，边分析边扩题只会放大噪声。',
        bodyEn:
            'For example: “Once I finish this ranking and guardrail pass, I act and stop opening new variables.” Under time pressure, expanding the question only amplifies noise.',
      ),
    );
  }

  return entries;
}

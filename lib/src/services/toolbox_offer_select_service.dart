import 'dart:math' as math;

import 'toolbox_work_worth_service.dart';

enum OfferSelectFlagLevel { info, warning, danger }

class OfferSelectWeights {
  const OfferSelectWeights({
    required this.cashflow,
    required this.time,
    required this.health,
    required this.growth,
    required this.stability,
    required this.cityFit,
  });

  final double cashflow;
  final double time;
  final double health;
  final double growth;
  final double stability;
  final double cityFit;

  static const OfferSelectWeights balanced = OfferSelectWeights(
    cashflow: 1.25,
    time: 1.0,
    health: 1.1,
    growth: 0.95,
    stability: 0.8,
    cityFit: 0.65,
  );

  double get total => cashflow + time + health + growth + stability + cityFit;

  OfferSelectWeights copyWith({
    double? cashflow,
    double? time,
    double? health,
    double? growth,
    double? stability,
    double? cityFit,
  }) {
    return OfferSelectWeights(
      cashflow: cashflow ?? this.cashflow,
      time: time ?? this.time,
      health: health ?? this.health,
      growth: growth ?? this.growth,
      stability: stability ?? this.stability,
      cityFit: cityFit ?? this.cityFit,
    );
  }
}

class OfferSelectProfile {
  const OfferSelectProfile({
    required this.title,
    required this.background,
    required this.major,
    required this.experience,
  });

  final String title;
  final String background;
  final String major;
  final String experience;
}

class OfferSelectCandidate {
  const OfferSelectCandidate({
    required this.id,
    required this.company,
    required this.role,
    required this.city,
    required this.monthlyBase,
    required this.salaryMonths,
    required this.otherBonus,
    required this.bonusCertainty,
    required this.monthlyTax,
    required this.monthlyInsuranceFund,
    required this.monthlyHousingCost,
    required this.monthlyLivingCost,
    required this.monthlyBenefitValue,
    required this.monthlyOvertimePay,
    required this.workDaysPerWeek,
    required this.workFromHomeDaysPerWeek,
    required this.workHoursPerDay,
    required this.commuteHoursPerDay,
    required this.restHoursPerDay,
    required this.annualLeaveDays,
    required this.publicHolidayDays,
    required this.paidSickLeaveDays,
    required this.unpaidOvertimeHoursPerMonth,
    required this.salaryRating,
    required this.wlbRating,
    required this.offerCertainty,
    required this.cityFitFactor,
    required this.roleMatchFactor,
    required this.environment,
    required this.stability,
    required this.education,
    required this.workYears,
    required this.leadershipFactor,
    required this.teamworkFactor,
    required this.growthFactor,
    required this.boundaryFactor,
    required this.psychologicalSafetyFactor,
    required this.autonomyFactor,
    required this.hasShuttle,
    required this.shuttleFactor,
    required this.hasCanteen,
    required this.canteenFactor,
    required this.benefits,
    required this.socialInsurance,
    required this.workSchedule,
    required this.pros,
    required this.cons,
    this.rejected = false,
  });

  final String id;
  final String company;
  final String role;
  final String city;
  final double monthlyBase;
  final double salaryMonths;
  final double otherBonus;
  final double bonusCertainty;
  final double monthlyTax;
  final double monthlyInsuranceFund;
  final double monthlyHousingCost;
  final double monthlyLivingCost;
  final double monthlyBenefitValue;
  final double monthlyOvertimePay;
  final double workDaysPerWeek;
  final double workFromHomeDaysPerWeek;
  final double workHoursPerDay;
  final double commuteHoursPerDay;
  final double restHoursPerDay;
  final double annualLeaveDays;
  final double publicHolidayDays;
  final double paidSickLeaveDays;
  final double unpaidOvertimeHoursPerMonth;
  final double salaryRating;
  final double wlbRating;
  final double offerCertainty;
  final double cityFitFactor;
  final double roleMatchFactor;
  final WorkWorthEnvironment environment;
  final WorkWorthJobStability stability;
  final WorkWorthEducation education;
  final double workYears;
  final double leadershipFactor;
  final double teamworkFactor;
  final double growthFactor;
  final double boundaryFactor;
  final double psychologicalSafetyFactor;
  final double autonomyFactor;
  final bool hasShuttle;
  final double shuttleFactor;
  final bool hasCanteen;
  final double canteenFactor;
  final String benefits;
  final String socialInsurance;
  final String workSchedule;
  final String pros;
  final String cons;
  final bool rejected;

  double get annualGrossIncome =>
      monthlyBase * salaryMonths +
      otherBonus * bonusCertainty +
      monthlyBenefitValue * 12 +
      monthlyOvertimePay * 12;

  WorkWorthInput toWorkWorthInput() {
    return WorkWorthInput(
      monthlySalary: monthlyBase,
      salaryMonths: salaryMonths,
      annualBonus: otherBonus,
      annualBonusCertainty: bonusCertainty,
      monthlyBenefitValue: monthlyBenefitValue,
      monthlyOvertimePay: monthlyOvertimePay,
      monthlyTax: monthlyTax,
      monthlyInsuranceFund: monthlyInsuranceFund,
      monthlyHousingCost: monthlyHousingCost,
      monthlyLivingCost: monthlyLivingCost,
      workDaysPerWeek: workDaysPerWeek,
      workFromHomeDaysPerWeek: workFromHomeDaysPerWeek,
      annualLeaveDays: annualLeaveDays,
      publicHolidayDays: publicHolidayDays,
      paidSickLeaveDays: paidSickLeaveDays,
      workHoursPerDay: workHoursPerDay,
      commuteHoursPerDay: commuteHoursPerDay,
      restHoursPerDay: restHoursPerDay,
      unpaidOvertimeHoursPerMonth: unpaidOvertimeHoursPerMonth,
      pppFactor: ToolboxWorkWorthService.chinaPppFactor,
      cityFactor: cityFitFactor,
      environment: environment,
      leadershipFactor: leadershipFactor,
      teamworkFactor: teamworkFactor,
      jobStability: stability,
      education: education,
      workYears: workYears,
      hasShuttle: hasShuttle,
      shuttleFactor: shuttleFactor,
      hasCanteen: hasCanteen,
      canteenFactor: canteenFactor,
      growthFactor: growthFactor,
      boundaryFactor: boundaryFactor,
      psychologicalSafetyFactor: psychologicalSafetyFactor,
      autonomyFactor: autonomyFactor,
    );
  }

  OfferSelectCandidate copyWith({
    String? id,
    String? company,
    String? role,
    String? city,
    double? monthlyBase,
    double? salaryMonths,
    double? otherBonus,
    double? bonusCertainty,
    double? monthlyTax,
    double? monthlyInsuranceFund,
    double? monthlyHousingCost,
    double? monthlyLivingCost,
    double? monthlyBenefitValue,
    double? monthlyOvertimePay,
    double? workDaysPerWeek,
    double? workFromHomeDaysPerWeek,
    double? workHoursPerDay,
    double? commuteHoursPerDay,
    double? restHoursPerDay,
    double? annualLeaveDays,
    double? publicHolidayDays,
    double? paidSickLeaveDays,
    double? unpaidOvertimeHoursPerMonth,
    double? salaryRating,
    double? wlbRating,
    double? offerCertainty,
    double? cityFitFactor,
    double? roleMatchFactor,
    WorkWorthEnvironment? environment,
    WorkWorthJobStability? stability,
    WorkWorthEducation? education,
    double? workYears,
    double? leadershipFactor,
    double? teamworkFactor,
    double? growthFactor,
    double? boundaryFactor,
    double? psychologicalSafetyFactor,
    double? autonomyFactor,
    bool? hasShuttle,
    double? shuttleFactor,
    bool? hasCanteen,
    double? canteenFactor,
    String? benefits,
    String? socialInsurance,
    String? workSchedule,
    String? pros,
    String? cons,
    bool? rejected,
  }) {
    return OfferSelectCandidate(
      id: id ?? this.id,
      company: company ?? this.company,
      role: role ?? this.role,
      city: city ?? this.city,
      monthlyBase: monthlyBase ?? this.monthlyBase,
      salaryMonths: salaryMonths ?? this.salaryMonths,
      otherBonus: otherBonus ?? this.otherBonus,
      bonusCertainty: bonusCertainty ?? this.bonusCertainty,
      monthlyTax: monthlyTax ?? this.monthlyTax,
      monthlyInsuranceFund: monthlyInsuranceFund ?? this.monthlyInsuranceFund,
      monthlyHousingCost: monthlyHousingCost ?? this.monthlyHousingCost,
      monthlyLivingCost: monthlyLivingCost ?? this.monthlyLivingCost,
      monthlyBenefitValue: monthlyBenefitValue ?? this.monthlyBenefitValue,
      monthlyOvertimePay: monthlyOvertimePay ?? this.monthlyOvertimePay,
      workDaysPerWeek: workDaysPerWeek ?? this.workDaysPerWeek,
      workFromHomeDaysPerWeek:
          workFromHomeDaysPerWeek ?? this.workFromHomeDaysPerWeek,
      workHoursPerDay: workHoursPerDay ?? this.workHoursPerDay,
      commuteHoursPerDay: commuteHoursPerDay ?? this.commuteHoursPerDay,
      restHoursPerDay: restHoursPerDay ?? this.restHoursPerDay,
      annualLeaveDays: annualLeaveDays ?? this.annualLeaveDays,
      publicHolidayDays: publicHolidayDays ?? this.publicHolidayDays,
      paidSickLeaveDays: paidSickLeaveDays ?? this.paidSickLeaveDays,
      unpaidOvertimeHoursPerMonth:
          unpaidOvertimeHoursPerMonth ?? this.unpaidOvertimeHoursPerMonth,
      salaryRating: salaryRating ?? this.salaryRating,
      wlbRating: wlbRating ?? this.wlbRating,
      offerCertainty: offerCertainty ?? this.offerCertainty,
      cityFitFactor: cityFitFactor ?? this.cityFitFactor,
      roleMatchFactor: roleMatchFactor ?? this.roleMatchFactor,
      environment: environment ?? this.environment,
      stability: stability ?? this.stability,
      education: education ?? this.education,
      workYears: workYears ?? this.workYears,
      leadershipFactor: leadershipFactor ?? this.leadershipFactor,
      teamworkFactor: teamworkFactor ?? this.teamworkFactor,
      growthFactor: growthFactor ?? this.growthFactor,
      boundaryFactor: boundaryFactor ?? this.boundaryFactor,
      psychologicalSafetyFactor:
          psychologicalSafetyFactor ?? this.psychologicalSafetyFactor,
      autonomyFactor: autonomyFactor ?? this.autonomyFactor,
      hasShuttle: hasShuttle ?? this.hasShuttle,
      shuttleFactor: shuttleFactor ?? this.shuttleFactor,
      hasCanteen: hasCanteen ?? this.hasCanteen,
      canteenFactor: canteenFactor ?? this.canteenFactor,
      benefits: benefits ?? this.benefits,
      socialInsurance: socialInsurance ?? this.socialInsurance,
      workSchedule: workSchedule ?? this.workSchedule,
      pros: pros ?? this.pros,
      cons: cons ?? this.cons,
      rejected: rejected ?? this.rejected,
    );
  }
}

class OfferSelectFlag {
  const OfferSelectFlag({
    required this.level,
    required this.titleZh,
    required this.titleEn,
    required this.bodyZh,
    required this.bodyEn,
  });

  final OfferSelectFlagLevel level;
  final String titleZh;
  final String titleEn;
  final String bodyZh;
  final String bodyEn;
}

class OfferSelectStrength {
  const OfferSelectStrength({
    required this.titleZh,
    required this.titleEn,
    required this.bodyZh,
    required this.bodyEn,
  });

  final String titleZh;
  final String titleEn;
  final String bodyZh;
  final String bodyEn;
}

class OfferSelectEvaluation {
  const OfferSelectEvaluation({
    required this.candidate,
    required this.workWorth,
    required this.cashScore,
    required this.timeScore,
    required this.healthScore,
    required this.growthScore,
    required this.stabilityScore,
    required this.cityFitScore,
    required this.weightedScore,
    required this.flags,
    required this.strengths,
    this.monthlyBaseRaiseToLeader,
  });

  final OfferSelectCandidate candidate;
  final WorkWorthResult workWorth;
  final double cashScore;
  final double timeScore;
  final double healthScore;
  final double growthScore;
  final double stabilityScore;
  final double cityFitScore;
  final double weightedScore;
  final List<OfferSelectFlag> flags;
  final List<OfferSelectStrength> strengths;
  final double? monthlyBaseRaiseToLeader;

  bool get isActive => !candidate.rejected;
  double get monthlyFreeCash => workWorth.monthlyDisposableIncome;
  double get monthlyCashAfterHealth =>
      workWorth.monthlyDisposableIncome - workWorth.monthlyHealthReserve;

  OfferSelectEvaluation copyWith({double? monthlyBaseRaiseToLeader}) {
    return OfferSelectEvaluation(
      candidate: candidate,
      workWorth: workWorth,
      cashScore: cashScore,
      timeScore: timeScore,
      healthScore: healthScore,
      growthScore: growthScore,
      stabilityScore: stabilityScore,
      cityFitScore: cityFitScore,
      weightedScore: weightedScore,
      flags: flags,
      strengths: strengths,
      monthlyBaseRaiseToLeader:
          monthlyBaseRaiseToLeader ?? this.monthlyBaseRaiseToLeader,
    );
  }
}

class OfferSelectResult {
  const OfferSelectResult({
    required this.profile,
    required this.evaluations,
    required this.activeEvaluations,
    required this.rejectedEvaluations,
    required this.summaryZh,
    required this.summaryEn,
  });

  final OfferSelectProfile profile;
  final List<OfferSelectEvaluation> evaluations;
  final List<OfferSelectEvaluation> activeEvaluations;
  final List<OfferSelectEvaluation> rejectedEvaluations;
  final String summaryZh;
  final String summaryEn;

  OfferSelectEvaluation? get leader =>
      activeEvaluations.isEmpty ? null : activeEvaluations.first;

  OfferSelectEvaluation? get runnerUp =>
      activeEvaluations.length < 2 ? null : activeEvaluations[1];

  double get leaderGap {
    final first = leader;
    final second = runnerUp;
    if (first == null || second == null) {
      return 0;
    }
    return first.weightedScore - second.weightedScore;
  }
}

class ToolboxOfferSelectService {
  static const OfferSelectProfile defaultProfile = OfferSelectProfile(
    title: '校招 Offer 求帮选',
    background: '本科/硕士求职',
    major: '计算机或相关方向',
    experience: '实习、项目和作品集待补充',
  );

  static const List<OfferSelectCandidate> defaultCandidates =
      <OfferSelectCandidate>[
        OfferSelectCandidate(
          id: 'offer_a',
          company: 'Offer A',
          role: '平台研发',
          city: '上海',
          monthlyBase: 26000,
          salaryMonths: 14,
          otherBonus: 40000,
          bonusCertainty: 0.8,
          monthlyTax: 2600,
          monthlyInsuranceFund: 4800,
          monthlyHousingCost: 6500,
          monthlyLivingCost: 5200,
          monthlyBenefitValue: 800,
          monthlyOvertimePay: 0,
          workDaysPerWeek: 5,
          workFromHomeDaysPerWeek: 1,
          workHoursPerDay: 9.5,
          commuteHoursPerDay: 1.4,
          restHoursPerDay: 2,
          annualLeaveDays: 8,
          publicHolidayDays: 13,
          paidSickLeaveDays: 3,
          unpaidOvertimeHoursPerMonth: 10,
          salaryRating: 4,
          wlbRating: 3.5,
          offerCertainty: 0.9,
          cityFitFactor: 1.0,
          roleMatchFactor: 1.0,
          environment: WorkWorthEnvironment.normal,
          stability: WorkWorthJobStability.privateCompany,
          education: WorkWorthEducation.bachelor,
          workYears: 0,
          leadershipFactor: 1.0,
          teamworkFactor: 1.0,
          growthFactor: 1.1,
          boundaryFactor: 0.95,
          psychologicalSafetyFactor: 1.0,
          autonomyFactor: 1.0,
          hasShuttle: false,
          shuttleFactor: 1.0,
          hasCanteen: true,
          canteenFactor: 1.05,
          benefits: '餐补、补充商业险、年度体检',
          socialInsurance: '足额五险一金',
          workSchedule: '10:00-19:30，偶尔项目加班',
          pros: '平台大，技术栈成熟，导师资源较好',
          cons: '通勤一般，业务节奏可能波动',
        ),
        OfferSelectCandidate(
          id: 'offer_b',
          company: 'Offer B',
          role: 'AI 应用工程',
          city: '杭州',
          monthlyBase: 22000,
          salaryMonths: 13,
          otherBonus: 20000,
          bonusCertainty: 0.7,
          monthlyTax: 1600,
          monthlyInsuranceFund: 3800,
          monthlyHousingCost: 4200,
          monthlyLivingCost: 4300,
          monthlyBenefitValue: 600,
          monthlyOvertimePay: 0,
          workDaysPerWeek: 5,
          workFromHomeDaysPerWeek: 2,
          workHoursPerDay: 8.5,
          commuteHoursPerDay: 0.8,
          restHoursPerDay: 2,
          annualLeaveDays: 10,
          publicHolidayDays: 13,
          paidSickLeaveDays: 3,
          unpaidOvertimeHoursPerMonth: 4,
          salaryRating: 3.5,
          wlbRating: 4.2,
          offerCertainty: 0.85,
          cityFitFactor: 1.08,
          roleMatchFactor: 1.08,
          environment: WorkWorthEnvironment.balanced,
          stability: WorkWorthJobStability.privateCompany,
          education: WorkWorthEducation.bachelor,
          workYears: 0,
          leadershipFactor: 1.05,
          teamworkFactor: 1.05,
          growthFactor: 1.2,
          boundaryFactor: 1.08,
          psychologicalSafetyFactor: 1.05,
          autonomyFactor: 1.05,
          hasShuttle: false,
          shuttleFactor: 1.0,
          hasCanteen: true,
          canteenFactor: 1.05,
          benefits: '弹性办公、学习预算',
          socialInsurance: '常规五险一金',
          workSchedule: '9:30-18:30，弹性居家',
          pros: '方向贴合，成长空间较好，生活成本更低',
          cons: '现金总包略低，奖金不确定',
        ),
      ];

  ToolboxOfferSelectService({ToolboxWorkWorthService? workWorthService})
    : workWorthService = workWorthService ?? ToolboxWorkWorthService();

  final ToolboxWorkWorthService workWorthService;

  OfferSelectResult compare({
    required OfferSelectProfile profile,
    required List<OfferSelectCandidate> candidates,
    OfferSelectWeights weights = OfferSelectWeights.balanced,
  }) {
    final evaluations = candidates
        .map((candidate) {
          return _evaluateCandidate(candidate, weights);
        })
        .toList(growable: false);
    final active =
        evaluations
            .where((evaluation) => evaluation.isActive)
            .toList(growable: false)
          ..sort((a, b) => b.weightedScore.compareTo(a.weightedScore));
    final rejected =
        evaluations
            .where((evaluation) => !evaluation.isActive)
            .toList(growable: false)
          ..sort((a, b) => b.weightedScore.compareTo(a.weightedScore));

    final leader = active.isEmpty ? null : active.first;
    final activeWithRaises = leader == null
        ? active
        : active
              .map((evaluation) {
                if (evaluation.candidate.id == leader.candidate.id) {
                  return evaluation.copyWith(monthlyBaseRaiseToLeader: 0);
                }
                return evaluation.copyWith(
                  monthlyBaseRaiseToLeader: _requiredMonthlyBaseRaise(
                    candidate: evaluation.candidate,
                    weights: weights,
                    targetScore: leader.weightedScore,
                  ),
                );
              })
              .toList(growable: false);

    final allWithRaises = <OfferSelectEvaluation>[
      ...activeWithRaises,
      ...rejected,
    ];

    return OfferSelectResult(
      profile: profile,
      evaluations: allWithRaises,
      activeEvaluations: activeWithRaises,
      rejectedEvaluations: rejected,
      summaryZh: _summaryZh(activeWithRaises),
      summaryEn: _summaryEn(activeWithRaises),
    );
  }

  OfferSelectEvaluation _evaluateCandidate(
    OfferSelectCandidate candidate,
    OfferSelectWeights weights,
  ) {
    final workWorth = workWorthService.calculate(candidate.toWorkWorthInput());
    final cashScore = _cashScore(candidate, workWorth);
    final timeScore = _timeScore(candidate, workWorth);
    final healthScore = _healthScore(candidate, workWorth);
    final growthScore = _growthScore(candidate);
    final stabilityScore = _stabilityScore(candidate);
    final cityFitScore = _cityFitScore(candidate);
    final weightedScore = _weighted(
      weights: weights,
      cashScore: cashScore,
      timeScore: timeScore,
      healthScore: healthScore,
      growthScore: growthScore,
      stabilityScore: stabilityScore,
      cityFitScore: cityFitScore,
    );
    return OfferSelectEvaluation(
      candidate: candidate,
      workWorth: workWorth,
      cashScore: cashScore,
      timeScore: timeScore,
      healthScore: healthScore,
      growthScore: growthScore,
      stabilityScore: stabilityScore,
      cityFitScore: cityFitScore,
      weightedScore: weightedScore,
      flags: _flags(candidate, workWorth),
      strengths: _strengths(
        candidate: candidate,
        workWorth: workWorth,
        cashScore: cashScore,
        timeScore: timeScore,
        healthScore: healthScore,
        growthScore: growthScore,
        stabilityScore: stabilityScore,
        cityFitScore: cityFitScore,
      ),
    );
  }

  double _weighted({
    required OfferSelectWeights weights,
    required double cashScore,
    required double timeScore,
    required double healthScore,
    required double growthScore,
    required double stabilityScore,
    required double cityFitScore,
  }) {
    final total = weights.total <= 0 ? 1.0 : weights.total;
    return (cashScore * weights.cashflow +
            timeScore * weights.time +
            healthScore * weights.health +
            growthScore * weights.growth +
            stabilityScore * weights.stability +
            cityFitScore * weights.cityFit) /
        total;
  }

  double _cashScore(OfferSelectCandidate candidate, WorkWorthResult workWorth) {
    final monthlyCashAfterHealth =
        workWorth.monthlyDisposableIncome - workWorth.monthlyHealthReserve;
    final base = ((monthlyCashAfterHealth + 2500) / 18000) * 100;
    final ratingBoost = (candidate.salaryRating.clamp(1.0, 5.0) - 3) * 4;
    final certaintyPenalty = (1 - candidate.bonusCertainty.clamp(0.0, 1.0)) * 8;
    return _score(base + ratingBoost - certaintyPenalty);
  }

  double _timeScore(OfferSelectCandidate candidate, WorkWorthResult workWorth) {
    final timeCost = workWorth.effectiveTimeCostHours;
    final base = 100 - (timeCost - 8) * 15;
    final wlbScore = _ratingScore(candidate.wlbRating);
    return _score(base * 0.72 + wlbScore * 0.28);
  }

  double _healthScore(
    OfferSelectCandidate candidate,
    WorkWorthResult workWorth,
  ) {
    final environmentPart = _score((workWorth.environmentFactor / 1.35) * 100);
    final wlbScore = _ratingScore(candidate.wlbRating);
    final contextPart = _score(
      ((candidate.boundaryFactor +
                      candidate.psychologicalSafetyFactor +
                      candidate.autonomyFactor) /
                  3 -
              0.75) /
          0.5 *
          100,
    );
    final healthReserveRatio = workWorth.monthlyGrossEquivalent <= 0
        ? 0.0
        : workWorth.monthlyHealthReserve / workWorth.monthlyGrossEquivalent;
    return _score(
      environmentPart * 0.38 +
          wlbScore * 0.32 +
          contextPart * 0.30 -
          healthReserveRatio * 90,
    );
  }

  double _growthScore(OfferSelectCandidate candidate) {
    final growth = _score(((candidate.growthFactor - 0.75) / 0.65) * 100);
    final roleFit = _score(((candidate.roleMatchFactor - 0.75) / 0.6) * 100);
    return _score(growth * 0.62 + roleFit * 0.38);
  }

  double _stabilityScore(OfferSelectCandidate candidate) {
    final base = switch (candidate.stability) {
      WorkWorthJobStability.government => 92.0,
      WorkWorthJobStability.stateOwned => 86.0,
      WorkWorthJobStability.foreignCompany => 78.0,
      WorkWorthJobStability.privateCompany => 66.0,
      WorkWorthJobStability.dispatch => 42.0,
      WorkWorthJobStability.freelance => 55.0,
    };
    final certainty = candidate.offerCertainty.clamp(0.0, 1.0) * 18;
    final bonusPenalty = (1 - candidate.bonusCertainty.clamp(0.0, 1.0)) * 8;
    return _score(base * 0.82 + certainty - bonusPenalty);
  }

  double _cityFitScore(OfferSelectCandidate candidate) {
    return _score(((candidate.cityFitFactor - 0.7) / 0.65) * 100);
  }

  double _ratingScore(double rating) {
    return _score(((rating.clamp(1.0, 5.0) - 1) / 4) * 100);
  }

  List<OfferSelectFlag> _flags(
    OfferSelectCandidate candidate,
    WorkWorthResult workWorth,
  ) {
    final flags = <OfferSelectFlag>[];
    if (candidate.rejected) {
      flags.add(
        const OfferSelectFlag(
          level: OfferSelectFlagLevel.info,
          titleZh: '已婉拒',
          titleEn: 'Rejected',
          bodyZh: '该机会当前不参与首选排序，只保留作对照。',
          bodyEn: 'This offer is excluded from the top ranking.',
        ),
      );
    }
    if (workWorth.monthlyDisposableIncome < 0) {
      flags.add(
        const OfferSelectFlag(
          level: OfferSelectFlagLevel.danger,
          titleZh: '现金流为负',
          titleEn: 'Negative cashflow',
          bodyZh: '扣除税费、五险一金、住房、生活和健康损耗后，每月可支配金额为负。',
          bodyEn:
              'After deductions, housing, living cost, and health reserve, monthly disposable cash is negative.',
        ),
      );
    } else if (workWorth.monthlyDisposableIncome < 3000) {
      flags.add(
        const OfferSelectFlag(
          level: OfferSelectFlagLevel.warning,
          titleZh: '现金缓冲偏薄',
          titleEn: 'Thin cash buffer',
          bodyZh: '可支配金额较低，搬家、押金、设备和突发开销会放大压力。',
          bodyEn:
              'Disposable cash is thin, so relocation, deposit, equipment, or surprises can hurt.',
        ),
      );
    }
    if (workWorth.effectiveTimeCostHours >= 11) {
      flags.add(
        const OfferSelectFlag(
          level: OfferSelectFlagLevel.warning,
          titleZh: '时间成本偏高',
          titleEn: 'High time cost',
          bodyZh: '工作、通勤和无偿加班折算后的日时间成本偏高。',
          bodyEn:
              'Daily time cost is high after work hours, commute, and unpaid overtime.',
        ),
      );
    }
    if (candidate.commuteHoursPerDay >= 2.5 &&
        candidate.workFromHomeDaysPerWeek < 1) {
      flags.add(
        const OfferSelectFlag(
          level: OfferSelectFlagLevel.warning,
          titleZh: '通勤风险',
          titleEn: 'Commute risk',
          bodyZh: '通勤时间较长且居家办公较少，长期会吞掉恢复时间。',
          bodyEn:
              'Long commute with little WFH can eat into long-term recovery time.',
        ),
      );
    }
    if (candidate.environment == WorkWorthEnvironment.lifeTrade ||
        candidate.environment == WorkWorthEnvironment.harmful) {
      flags.add(
        const OfferSelectFlag(
          level: OfferSelectFlagLevel.danger,
          titleZh: '健康消耗高',
          titleEn: 'High health load',
          bodyZh: '环境层级已落入明显损耗区，建议把恢复成本和退出成本写入决策。',
          bodyEn:
              'The environment tier indicates obvious health load; include recovery and exit costs.',
        ),
      );
    }
    if (candidate.bonusCertainty < 0.65) {
      flags.add(
        const OfferSelectFlag(
          level: OfferSelectFlagLevel.warning,
          titleZh: '浮动收入不稳',
          titleEn: 'Variable pay risk',
          bodyZh: '奖金、期权或绩效兑现概率较低，不宜按满额当作稳定现金。',
          bodyEn:
              'Bonus, equity, or performance pay is uncertain and should not be treated as stable cash.',
        ),
      );
    }
    if (candidate.offerCertainty < 0.7) {
      flags.add(
        const OfferSelectFlag(
          level: OfferSelectFlagLevel.warning,
          titleZh: 'Offer 确定性不足',
          titleEn: 'Offer certainty risk',
          bodyZh: '审批、HC、背调或试用期条件仍有不确定性。',
          bodyEn:
              'Approval, headcount, background checks, or probation terms are still uncertain.',
        ),
      );
    }
    if (candidate.stability == WorkWorthJobStability.dispatch ||
        candidate.stability == WorkWorthJobStability.freelance) {
      flags.add(
        const OfferSelectFlag(
          level: OfferSelectFlagLevel.warning,
          titleZh: '稳定性需核对',
          titleEn: 'Stability needs checking',
          bodyZh: '合同主体、社保缴纳、裁撤补偿和续约条款需要额外核实。',
          bodyEn:
              'Contract entity, social insurance, severance, and renewal terms need extra checks.',
        ),
      );
    }
    return flags;
  }

  List<OfferSelectStrength> _strengths({
    required OfferSelectCandidate candidate,
    required WorkWorthResult workWorth,
    required double cashScore,
    required double timeScore,
    required double healthScore,
    required double growthScore,
    required double stabilityScore,
    required double cityFitScore,
  }) {
    final strengths = <OfferSelectStrength>[];
    if (cashScore >= 72) {
      strengths.add(
        OfferSelectStrength(
          titleZh: '现金表现强',
          titleEn: 'Strong cashflow',
          bodyZh:
              '月可支配约 ${workWorth.monthlyDisposableIncome.toStringAsFixed(0)}，现金安全垫相对更好。',
          bodyEn:
              'Monthly disposable cash is about ${workWorth.monthlyDisposableIncome.toStringAsFixed(0)}, giving a stronger buffer.',
        ),
      );
    }
    if (timeScore >= 76) {
      strengths.add(
        const OfferSelectStrength(
          titleZh: '时间成本友好',
          titleEn: 'Time friendly',
          bodyZh: '工时、通勤或居家安排对恢复时间更友好。',
          bodyEn:
              'Work hours, commute, or WFH setup are friendlier to recovery.',
        ),
      );
    }
    if (healthScore >= 76) {
      strengths.add(
        const OfferSelectStrength(
          titleZh: '健康边界较好',
          titleEn: 'Healthy boundaries',
          bodyZh: 'WLB、环境和心理安全感组合表现较好。',
          bodyEn:
              'WLB, environment, and psychological-safety signals look healthy.',
        ),
      );
    }
    if (growthScore >= 74) {
      strengths.add(
        const OfferSelectStrength(
          titleZh: '成长贴合',
          titleEn: 'Good growth fit',
          bodyZh: '岗位方向、技能复利或角色匹配度较高。',
          bodyEn: 'Role direction, skill compounding, or role fit is strong.',
        ),
      );
    }
    if (stabilityScore >= 80) {
      strengths.add(
        const OfferSelectStrength(
          titleZh: '稳定性较强',
          titleEn: 'Stable option',
          bodyZh: '合同、组织形态或 Offer 确定性更稳。',
          bodyEn:
              'Contract, organization type, or offer certainty is steadier.',
        ),
      );
    }
    if (cityFitScore >= 74) {
      strengths.add(
        OfferSelectStrength(
          titleZh: '城市适配较好',
          titleEn: 'Good city fit',
          bodyZh: '${candidate.city} 对生活偏好或发展阶段更友好。',
          bodyEn: '${candidate.city} fits lifestyle or career stage better.',
        ),
      );
    }
    if (strengths.isEmpty) {
      strengths.add(
        const OfferSelectStrength(
          titleZh: '整体均衡',
          titleEn: 'Balanced baseline',
          bodyZh: '暂无突出亮点，也没有明显单项拉满，可继续补充信息校准。',
          bodyEn:
              'No standout dimension yet; add more details to calibrate the baseline.',
        ),
      );
    }
    return strengths;
  }

  double? _requiredMonthlyBaseRaise({
    required OfferSelectCandidate candidate,
    required OfferSelectWeights weights,
    required double targetScore,
  }) {
    final current = _evaluateCandidate(candidate, weights).weightedScore;
    if (current >= targetScore) {
      return 0;
    }
    var low = candidate.monthlyBase;
    var high = math.max(
      candidate.monthlyBase + 1000,
      candidate.monthlyBase * 1.2,
    );
    final hardCap = candidate.monthlyBase + 100000;
    while (high < hardCap) {
      final score = _evaluateCandidate(
        candidate.copyWith(monthlyBase: high),
        weights,
      ).weightedScore;
      if (score >= targetScore) {
        break;
      }
      low = high;
      high = math.min(hardCap, high * 1.22 + 3000);
    }
    final highScore = _evaluateCandidate(
      candidate.copyWith(monthlyBase: high),
      weights,
    ).weightedScore;
    if (highScore < targetScore) {
      return null;
    }
    for (var i = 0; i < 28; i += 1) {
      final mid = (low + high) / 2;
      final score = _evaluateCandidate(
        candidate.copyWith(monthlyBase: mid),
        weights,
      ).weightedScore;
      if (score >= targetScore) {
        high = mid;
      } else {
        low = mid;
      }
    }
    return math.max(0.0, high - candidate.monthlyBase);
  }

  String _summaryZh(List<OfferSelectEvaluation> active) {
    if (active.isEmpty) {
      return '暂无可比较 Offer，请添加或取消婉拒至少一个机会。';
    }
    if (active.length == 1) {
      return '${active.first.candidate.company} 是当前唯一未婉拒的机会，建议继续补齐风险项。';
    }
    final leader = active[0];
    final runner = active[1];
    final gap = leader.weightedScore - runner.weightedScore;
    if (gap < 4) {
      return '${leader.candidate.company} 暂时领先，但与 ${runner.candidate.company} 差距很小，优先谈薪和核对试用期条件。';
    }
    if (leader.flags.any((flag) => flag.level == OfferSelectFlagLevel.danger)) {
      return '${leader.candidate.company} 分数领先，但存在高风险项，建议先确认边界和退出成本。';
    }
    return '${leader.candidate.company} 当前综合更优，优势主要来自现金、时间、成长和稳定性加权后的平衡。';
  }

  String _summaryEn(List<OfferSelectEvaluation> active) {
    if (active.isEmpty) {
      return 'No active offers yet. Add or un-reject at least one option.';
    }
    if (active.length == 1) {
      return '${active.first.candidate.company} is the only active offer; fill in risks before deciding.';
    }
    final leader = active[0];
    final runner = active[1];
    final gap = leader.weightedScore - runner.weightedScore;
    if (gap < 4) {
      return '${leader.candidate.company} leads, but the gap to ${runner.candidate.company} is small. Negotiate and verify probation terms first.';
    }
    if (leader.flags.any((flag) => flag.level == OfferSelectFlagLevel.danger)) {
      return '${leader.candidate.company} leads, but it has high-risk flags. Confirm boundaries and exit costs first.';
    }
    return '${leader.candidate.company} is currently stronger after weighting cash, time, growth, and stability.';
  }

  double _score(num value) => value.clamp(0.0, 100.0).toDouble();
}

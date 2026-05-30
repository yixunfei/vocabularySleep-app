import 'dart:math' as math;

import 'toolbox_i18n_text_ref.dart';
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
    required this.titleKey,
    required this.body,
  });

  final OfferSelectFlagLevel level;
  final String titleKey;
  final ToolboxI18nTextRef body;
}

class OfferSelectStrength {
  const OfferSelectStrength({required this.titleKey, required this.body});

  final String titleKey;
  final ToolboxI18nTextRef body;
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
    required this.summary,
  });

  final OfferSelectProfile profile;
  final List<OfferSelectEvaluation> evaluations;
  final List<OfferSelectEvaluation> activeEvaluations;
  final List<OfferSelectEvaluation> rejectedEvaluations;
  final ToolboxI18nTextRef summary;

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
      summary: _summary(activeWithRaises),
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
          titleKey: 'life.offer_select.flag.rejected.title',
          body: ToolboxI18nTextRef('life.offer_select.flag.rejected.body'),
        ),
      );
    }
    if (workWorth.monthlyDisposableIncome < 0) {
      flags.add(
        const OfferSelectFlag(
          level: OfferSelectFlagLevel.danger,
          titleKey: 'life.offer_select.flag.negative_cashflow.title',
          body: ToolboxI18nTextRef(
            'life.offer_select.flag.negative_cashflow.body',
          ),
        ),
      );
    } else if (workWorth.monthlyDisposableIncome < 3000) {
      flags.add(
        const OfferSelectFlag(
          level: OfferSelectFlagLevel.warning,
          titleKey: 'life.offer_select.flag.thin_cash_buffer.title',
          body: ToolboxI18nTextRef(
            'life.offer_select.flag.thin_cash_buffer.body',
          ),
        ),
      );
    }
    if (workWorth.effectiveTimeCostHours >= 11) {
      flags.add(
        const OfferSelectFlag(
          level: OfferSelectFlagLevel.warning,
          titleKey: 'life.offer_select.flag.high_time_cost.title',
          body: ToolboxI18nTextRef(
            'life.offer_select.flag.high_time_cost.body',
          ),
        ),
      );
    }
    if (candidate.commuteHoursPerDay >= 2.5 &&
        candidate.workFromHomeDaysPerWeek < 1) {
      flags.add(
        const OfferSelectFlag(
          level: OfferSelectFlagLevel.warning,
          titleKey: 'life.offer_select.flag.commute_risk.title',
          body: ToolboxI18nTextRef('life.offer_select.flag.commute_risk.body'),
        ),
      );
    }
    if (candidate.environment == WorkWorthEnvironment.lifeTrade ||
        candidate.environment == WorkWorthEnvironment.harmful) {
      flags.add(
        const OfferSelectFlag(
          level: OfferSelectFlagLevel.danger,
          titleKey: 'life.offer_select.flag.high_health_load.title',
          body: ToolboxI18nTextRef(
            'life.offer_select.flag.high_health_load.body',
          ),
        ),
      );
    }
    if (candidate.bonusCertainty < 0.65) {
      flags.add(
        const OfferSelectFlag(
          level: OfferSelectFlagLevel.warning,
          titleKey: 'life.offer_select.flag.variable_pay.title',
          body: ToolboxI18nTextRef('life.offer_select.flag.variable_pay.body'),
        ),
      );
    }
    if (candidate.offerCertainty < 0.7) {
      flags.add(
        const OfferSelectFlag(
          level: OfferSelectFlagLevel.warning,
          titleKey: 'life.offer_select.flag.offer_certainty.title',
          body: ToolboxI18nTextRef(
            'life.offer_select.flag.offer_certainty.body',
          ),
        ),
      );
    }
    if (candidate.stability == WorkWorthJobStability.dispatch ||
        candidate.stability == WorkWorthJobStability.freelance) {
      flags.add(
        const OfferSelectFlag(
          level: OfferSelectFlagLevel.warning,
          titleKey: 'life.offer_select.flag.stability_check.title',
          body: ToolboxI18nTextRef(
            'life.offer_select.flag.stability_check.body',
          ),
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
          titleKey: 'life.offer_select.strength.strong_cashflow.title',
          body: ToolboxI18nTextRef(
            'life.offer_select.strength.strong_cashflow.body',
            params: <String, Object?>{
              'amount': workWorth.monthlyDisposableIncome.toStringAsFixed(0),
            },
          ),
        ),
      );
    }
    if (timeScore >= 76) {
      strengths.add(
        const OfferSelectStrength(
          titleKey: 'life.offer_select.strength.time_friendly.title',
          body: ToolboxI18nTextRef(
            'life.offer_select.strength.time_friendly.body',
          ),
        ),
      );
    }
    if (healthScore >= 76) {
      strengths.add(
        const OfferSelectStrength(
          titleKey: 'life.offer_select.strength.healthy_boundaries.title',
          body: ToolboxI18nTextRef(
            'life.offer_select.strength.healthy_boundaries.body',
          ),
        ),
      );
    }
    if (growthScore >= 74) {
      strengths.add(
        const OfferSelectStrength(
          titleKey: 'life.offer_select.strength.growth_fit.title',
          body: ToolboxI18nTextRef(
            'life.offer_select.strength.growth_fit.body',
          ),
        ),
      );
    }
    if (stabilityScore >= 80) {
      strengths.add(
        const OfferSelectStrength(
          titleKey: 'life.offer_select.strength.stable_option.title',
          body: ToolboxI18nTextRef(
            'life.offer_select.strength.stable_option.body',
          ),
        ),
      );
    }
    if (cityFitScore >= 74) {
      strengths.add(
        OfferSelectStrength(
          titleKey: 'life.offer_select.strength.city_fit.title',
          body: ToolboxI18nTextRef(
            'life.offer_select.strength.city_fit.body',
            params: <String, Object?>{'city': candidate.city},
          ),
        ),
      );
    }
    if (strengths.isEmpty) {
      strengths.add(
        const OfferSelectStrength(
          titleKey: 'life.offer_select.strength.balanced_baseline.title',
          body: ToolboxI18nTextRef(
            'life.offer_select.strength.balanced_baseline.body',
          ),
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

  ToolboxI18nTextRef _summary(List<OfferSelectEvaluation> active) {
    if (active.isEmpty) {
      return const ToolboxI18nTextRef('life.offer_select.summary.empty');
    }
    if (active.length == 1) {
      return ToolboxI18nTextRef(
        'life.offer_select.summary.single',
        params: <String, Object?>{'company': active.first.candidate.company},
      );
    }
    final leader = active[0];
    final runner = active[1];
    final gap = leader.weightedScore - runner.weightedScore;
    if (gap < 4) {
      return ToolboxI18nTextRef(
        'life.offer_select.summary.small_gap',
        params: <String, Object?>{
          'leader': leader.candidate.company,
          'runner': runner.candidate.company,
        },
      );
    }
    if (leader.flags.any((flag) => flag.level == OfferSelectFlagLevel.danger)) {
      return ToolboxI18nTextRef(
        'life.offer_select.summary.high_risk_leader',
        params: <String, Object?>{'company': leader.candidate.company},
      );
    }
    return ToolboxI18nTextRef(
      'life.offer_select.summary.leader',
      params: <String, Object?>{'company': leader.candidate.company},
    );
  }

  double _score(num value) => value.clamp(0.0, 100.0).toDouble();
}

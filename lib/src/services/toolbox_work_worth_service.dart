import 'dart:math' as math;

enum WorkWorthEnvironment {
  lifeTrade,
  harmful,
  highPressure,
  normal,
  balanced,
  freeComfort,
}

enum WorkWorthJobStability {
  government,
  stateOwned,
  foreignCompany,
  privateCompany,
  dispatch,
  freelance,
}

enum WorkWorthEducation { belowBachelor, bachelor, master, phd }

class WorkWorthEnvironmentSpec {
  const WorkWorthEnvironmentSpec({
    required this.environment,
    required this.factor,
    required this.healthReserveRate,
  });

  final WorkWorthEnvironment environment;
  final double factor;
  final double healthReserveRate;
}

class WorkWorthInput {
  const WorkWorthInput({
    required this.monthlySalary,
    required this.salaryMonths,
    required this.annualBonus,
    required this.monthlyTax,
    required this.monthlyInsuranceFund,
    required this.monthlyHousingCost,
    required this.monthlyLivingCost,
    required this.workDaysPerWeek,
    required this.workFromHomeDaysPerWeek,
    required this.annualLeaveDays,
    required this.publicHolidayDays,
    required this.paidSickLeaveDays,
    required this.workHoursPerDay,
    required this.commuteHoursPerDay,
    required this.restHoursPerDay,
    required this.pppFactor,
    required this.cityFactor,
    required this.environment,
    required this.leadershipFactor,
    required this.teamworkFactor,
    required this.jobStability,
    required this.education,
    required this.workYears,
    required this.hasShuttle,
    required this.shuttleFactor,
    required this.hasCanteen,
    required this.canteenFactor,
    this.monthlyBenefitValue = 0,
    this.monthlyOvertimePay = 0,
    this.unpaidOvertimeHoursPerMonth = 0,
    this.annualBonusCertainty = 1,
    this.growthFactor = 1,
    this.boundaryFactor = 1,
    this.psychologicalSafetyFactor = 1,
    this.autonomyFactor = 1,
  });

  final double monthlySalary;
  final double salaryMonths;
  final double annualBonus;
  final double monthlyTax;
  final double monthlyInsuranceFund;
  final double monthlyHousingCost;
  final double monthlyLivingCost;
  final double workDaysPerWeek;
  final double workFromHomeDaysPerWeek;
  final double annualLeaveDays;
  final double publicHolidayDays;
  final double paidSickLeaveDays;
  final double workHoursPerDay;
  final double commuteHoursPerDay;
  final double restHoursPerDay;
  final double pppFactor;
  final double cityFactor;
  final WorkWorthEnvironment environment;
  final double leadershipFactor;
  final double teamworkFactor;
  final WorkWorthJobStability jobStability;
  final WorkWorthEducation education;
  final double workYears;
  final bool hasShuttle;
  final double shuttleFactor;
  final bool hasCanteen;
  final double canteenFactor;
  final double monthlyBenefitValue;
  final double monthlyOvertimePay;
  final double unpaidOvertimeHoursPerMonth;
  final double annualBonusCertainty;
  final double growthFactor;
  final double boundaryFactor;
  final double psychologicalSafetyFactor;
  final double autonomyFactor;
}

class WorkWorthResult {
  const WorkWorthResult({
    required this.annualGrossIncome,
    required this.monthlyGrossEquivalent,
    required this.annualDisposableIncome,
    required this.monthlyDisposableIncome,
    required this.monthlyHealthReserve,
    required this.workingDaysPerYear,
    required this.localDailyIncome,
    required this.standardizedDailyIncome,
    required this.localDisposableDailyIncome,
    required this.effectiveCommuteHours,
    required this.effectiveTimeCostHours,
    required this.environmentFactor,
    required this.experienceMultiplier,
    required this.educationFactor,
    required this.costFactor,
    required this.expectedAnnualBonus,
    required this.annualBenefitValue,
    required this.annualOvertimePay,
    required this.effectiveUnpaidOvertimeHours,
    required this.contextFactor,
    required this.valueScore,
    required this.rating,
  });

  final double annualGrossIncome;
  final double monthlyGrossEquivalent;
  final double annualDisposableIncome;
  final double monthlyDisposableIncome;
  final double monthlyHealthReserve;
  final double workingDaysPerYear;
  final double localDailyIncome;
  final double standardizedDailyIncome;
  final double localDisposableDailyIncome;
  final double effectiveCommuteHours;
  final double effectiveTimeCostHours;
  final double environmentFactor;
  final double experienceMultiplier;
  final double educationFactor;
  final double costFactor;
  final double expectedAnnualBonus;
  final double annualBenefitValue;
  final double annualOvertimePay;
  final double effectiveUnpaidOvertimeHours;
  final double contextFactor;
  final double valueScore;
  final WorkWorthRating rating;
}

class WorkWorthRating {
  const WorkWorthRating({
    required this.key,
    required this.zh,
    required this.en,
  });

  final String key;
  final String zh;
  final String en;
}

class WorkWorthReferenceStandard {
  const WorkWorthReferenceStandard({
    required this.key,
    required this.zh,
    required this.en,
    required this.value,
    required this.noteZh,
    required this.noteEn,
  });

  final String key;
  final String zh;
  final String en;
  final String value;
  final String noteZh;
  final String noteEn;
}

class ToolboxWorkWorthService {
  static const double chinaPppFactor = 4.19;

  static const Map<String, double> pppFactors = <String, double>{
    'CN': 4.19,
    'US': 1.0,
    'JP': 102.84,
    'KR': 861.82,
    'SG': 0.84,
    'HK': 6.07,
    'TW': 13.85,
    'GB': 0.70,
    'DE': 0.75,
    'FR': 0.73,
    'CA': 1.21,
    'AU': 1.47,
  };

  static const Map<WorkWorthEnvironment, WorkWorthEnvironmentSpec>
  environmentSpecs = <WorkWorthEnvironment, WorkWorthEnvironmentSpec>{
    WorkWorthEnvironment.lifeTrade: WorkWorthEnvironmentSpec(
      environment: WorkWorthEnvironment.lifeTrade,
      factor: 0.45,
      healthReserveRate: 0.18,
    ),
    WorkWorthEnvironment.harmful: WorkWorthEnvironmentSpec(
      environment: WorkWorthEnvironment.harmful,
      factor: 0.62,
      healthReserveRate: 0.12,
    ),
    WorkWorthEnvironment.highPressure: WorkWorthEnvironmentSpec(
      environment: WorkWorthEnvironment.highPressure,
      factor: 0.78,
      healthReserveRate: 0.08,
    ),
    WorkWorthEnvironment.normal: WorkWorthEnvironmentSpec(
      environment: WorkWorthEnvironment.normal,
      factor: 1.0,
      healthReserveRate: 0.04,
    ),
    WorkWorthEnvironment.balanced: WorkWorthEnvironmentSpec(
      environment: WorkWorthEnvironment.balanced,
      factor: 1.12,
      healthReserveRate: 0.02,
    ),
    WorkWorthEnvironment.freeComfort: WorkWorthEnvironmentSpec(
      environment: WorkWorthEnvironment.freeComfort,
      factor: 1.28,
      healthReserveRate: 0.0,
    ),
  };

  static const List<WorkWorthReferenceStandard>
  referenceStandards = <WorkWorthReferenceStandard>[
    WorkWorthReferenceStandard(
      key: 'work_week',
      zh: '标准工时',
      en: 'Standard work week',
      value: '5 天 / 40 小时',
      noteZh: '常用健康基线；超过 45 小时建议显式计入时间成本。',
      noteEn:
          'Common healthy baseline; count time cost explicitly above 45h/week.',
    ),
    WorkWorthReferenceStandard(
      key: 'commute',
      zh: '通勤参考',
      en: 'Commute reference',
      value: '≤ 1h 舒适 / ≥ 2h 偏重',
      noteZh: '按每天往返计算；居家办公会按比例折减。',
      noteEn: 'Round trip per day; WFH days reduce it proportionally.',
    ),
    WorkWorthReferenceStandard(
      key: 'annual_leave',
      zh: '年假参考',
      en: 'Annual leave reference',
      value: '5 / 10 / 15 天',
      noteZh: '可按 1-10 年、10-20 年、20 年以上工作年限估算。',
      noteEn: 'Estimate by 1-10, 10-20, and 20+ years of service.',
    ),
    WorkWorthReferenceStandard(
      key: 'public_holidays',
      zh: '公共假期',
      en: 'Public holidays',
      value: '约 13 天/年',
      noteZh: '作为年度工作日估算默认值；遇到年份政策变化可手动调整。',
      noteEn:
          'Default for annual workday estimate; adjust manually for policy changes.',
    ),
    WorkWorthReferenceStandard(
      key: 'surplus',
      zh: '现金安全垫',
      en: 'Cash safety margin',
      value: '≥ 收入 30%',
      noteZh: '月可支配若低于 15%，分数会被生活成本显著压低。',
      noteEn:
          'Below 15% monthly surplus, living cost heavily suppresses score.',
    ),
    WorkWorthReferenceStandard(
      key: 'health',
      zh: '健康损耗预留',
      en: 'Health reserve',
      value: '0% - 18%',
      noteZh: '从自由舒适到拿命换分层估算，越危险预留越高。',
      noteEn:
          'Estimated by environment tier from free/comfortable to life-trade.',
    ),
  ];

  WorkWorthResult calculate(WorkWorthInput input) {
    final workingDays = _workingDays(input);
    final bonusCertainty = input.annualBonusCertainty.clamp(0.0, 1.0);
    final expectedAnnualBonus = input.annualBonus * bonusCertainty;
    final annualBenefitValue = math.max(0.0, input.monthlyBenefitValue) * 12;
    final annualOvertimePay = math.max(0.0, input.monthlyOvertimePay) * 12;
    final annualGross =
        input.monthlySalary * input.salaryMonths +
        expectedAnnualBonus +
        annualBenefitValue +
        annualOvertimePay;
    final monthlyGross = annualGross / 12;
    final mandatoryDeductions =
        (input.monthlyTax + input.monthlyInsuranceFund) * 12;
    final livingCosts =
        (input.monthlyHousingCost + input.monthlyLivingCost) * 12;
    final environmentSpec =
        environmentSpecs[input.environment] ??
        environmentSpecs[WorkWorthEnvironment.normal]!;
    final monthlyHealthReserve =
        monthlyGross * environmentSpec.healthReserveRate;
    final annualDisposable =
        annualGross -
        mandatoryDeductions -
        livingCosts -
        monthlyHealthReserve * 12;
    final pppFactor = input.pppFactor <= 0 ? chinaPppFactor : input.pppFactor;
    final standardizedAnnualGross = annualGross * (chinaPppFactor / pppFactor);
    final localDailyIncome = annualGross / workingDays;
    final standardizedDailyIncome = standardizedAnnualGross / workingDays;
    final officeRatio = _officeRatio(input);
    final shuttleFactor = input.hasShuttle ? input.shuttleFactor : 1.0;
    final effectiveCommute =
        input.commuteHoursPerDay * officeRatio * shuttleFactor;
    final workingMonths = math.max(1.0, workingDays / 12);
    final effectiveUnpaidOvertimeHours =
        math.max(0.0, input.unpaidOvertimeHoursPerMonth) / workingMonths;
    final effectiveTimeCost = math.max(
      1.0,
      input.workHoursPerDay +
          effectiveCommute +
          effectiveUnpaidOvertimeHours -
          input.restHoursPerDay * 0.5,
    );
    final educationFactor = _educationFactor(input.education);
    final experienceMultiplier = _experienceMultiplier(
      input.jobStability,
      input.workYears,
    );
    final canteenFactor = input.hasCanteen ? input.canteenFactor : 1.0;
    final environmentFactor =
        environmentSpec.factor *
        input.leadershipFactor *
        input.teamworkFactor *
        input.cityFactor *
        canteenFactor;
    final contextFactor =
        input.growthFactor *
        input.boundaryFactor *
        input.psychologicalSafetyFactor *
        input.autonomyFactor;
    final disposableRatio = annualGross <= 0
        ? 0.0
        : annualDisposable / annualGross;
    final costFactor = (0.65 + disposableRatio * 1.2).clamp(0.35, 1.25);
    final baseScore =
        (standardizedDailyIncome * environmentFactor * contextFactor) /
        (35 * effectiveTimeCost * educationFactor * experienceMultiplier);
    final score = math.max(0.0, baseScore * costFactor);

    return WorkWorthResult(
      annualGrossIncome: annualGross,
      monthlyGrossEquivalent: monthlyGross,
      annualDisposableIncome: annualDisposable,
      monthlyDisposableIncome: annualDisposable / 12,
      monthlyHealthReserve: monthlyHealthReserve,
      workingDaysPerYear: workingDays,
      localDailyIncome: localDailyIncome,
      standardizedDailyIncome: standardizedDailyIncome,
      localDisposableDailyIncome: annualDisposable / workingDays,
      effectiveCommuteHours: effectiveCommute,
      effectiveTimeCostHours: effectiveTimeCost,
      environmentFactor: environmentFactor,
      experienceMultiplier: experienceMultiplier,
      educationFactor: educationFactor,
      costFactor: costFactor.toDouble(),
      expectedAnnualBonus: expectedAnnualBonus,
      annualBenefitValue: annualBenefitValue,
      annualOvertimePay: annualOvertimePay,
      effectiveUnpaidOvertimeHours: effectiveUnpaidOvertimeHours,
      contextFactor: contextFactor,
      valueScore: score,
      rating: ratingFor(score),
    );
  }

  static WorkWorthRating ratingFor(double score) {
    if (score < 0.6) {
      return const WorkWorthRating(
        key: 'terrible',
        zh: '不建议硬扛',
        en: 'Not worth it',
      );
    }
    if (score < 1.0) {
      return const WorkWorthRating(key: 'poor', zh: '偏低', en: 'Low');
    }
    if (score <= 1.8) {
      return const WorkWorthRating(key: 'average', zh: '一般', en: 'Average');
    }
    if (score <= 2.5) {
      return const WorkWorthRating(key: 'good', zh: '还不错', en: 'Good');
    }
    if (score <= 3.2) {
      return const WorkWorthRating(key: 'great', zh: '很划算', en: 'Great');
    }
    if (score <= 4.0) {
      return const WorkWorthRating(key: 'excellent', zh: '优秀', en: 'Excellent');
    }
    return const WorkWorthRating(
      key: 'legendary',
      zh: '神仙工位',
      en: 'Exceptional',
    );
  }

  static double _workingDays(WorkWorthInput input) {
    final weeklyDays = input.workDaysPerWeek.clamp(0.0, 7.0);
    final totalWorkDays = 52 * weeklyDays;
    final leaveDays =
        math.max(0.0, input.annualLeaveDays) +
        math.max(0.0, input.publicHolidayDays) +
        math.max(0.0, input.paidSickLeaveDays) * 0.6;
    return math.max(1.0, totalWorkDays - leaveDays);
  }

  static double _officeRatio(WorkWorthInput input) {
    final weeklyDays = input.workDaysPerWeek.clamp(0.0, 7.0);
    if (weeklyDays <= 0) {
      return 0;
    }
    final wfhDays = input.workFromHomeDaysPerWeek.clamp(0.0, weeklyDays);
    return (weeklyDays - wfhDays) / weeklyDays;
  }

  static double _educationFactor(WorkWorthEducation education) {
    return switch (education) {
      WorkWorthEducation.belowBachelor => 0.8,
      WorkWorthEducation.bachelor => 1.0,
      WorkWorthEducation.master => 1.5,
      WorkWorthEducation.phd => 1.8,
    };
  }

  static double _experienceMultiplier(
    WorkWorthJobStability stability,
    double workYears,
  ) {
    if (workYears <= 0) {
      return switch (stability) {
        WorkWorthJobStability.government => 0.8,
        WorkWorthJobStability.stateOwned => 0.9,
        WorkWorthJobStability.foreignCompany => 0.95,
        WorkWorthJobStability.privateCompany => 1.0,
        WorkWorthJobStability.dispatch => 1.1,
        WorkWorthJobStability.freelance => 1.1,
      };
    }

    final base = switch (workYears) {
      <= 1 => 1.5,
      <= 3 => 2.2,
      <= 5 => 2.7,
      <= 8 => 3.2,
      <= 10 => 3.6,
      _ => 3.9,
    };
    final growth = switch (stability) {
      WorkWorthJobStability.government => 0.2,
      WorkWorthJobStability.stateOwned => 0.4,
      WorkWorthJobStability.foreignCompany => 0.8,
      WorkWorthJobStability.privateCompany => 1.0,
      WorkWorthJobStability.dispatch => 1.2,
      WorkWorthJobStability.freelance => 1.2,
    };
    return 1 + (base - 1) * growth;
  }
}

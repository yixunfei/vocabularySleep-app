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
  const WorkWorthRating({required this.key, required this.labelKey});

  final String key;
  final String labelKey;
}

class WorkWorthReferenceStandard {
  const WorkWorthReferenceStandard({
    required this.key,
    required this.titleKey,
    required this.value,
    required this.noteKey,
  });

  final String key;
  final String titleKey;
  final String value;
  final String noteKey;
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

  static const List<WorkWorthReferenceStandard> referenceStandards =
      <WorkWorthReferenceStandard>[
        WorkWorthReferenceStandard(
          key: 'work_week',
          titleKey: 'life.work_worth.reference.work_week.title',
          value: '5 天 / 40 小时',
          noteKey: 'life.work_worth.reference.work_week.note',
        ),
        WorkWorthReferenceStandard(
          key: 'commute',
          titleKey: 'life.work_worth.reference.commute.title',
          value: '≤ 1h 舒适 / ≥ 2h 偏重',
          noteKey: 'life.work_worth.reference.commute.note',
        ),
        WorkWorthReferenceStandard(
          key: 'annual_leave',
          titleKey: 'life.work_worth.reference.annual_leave.title',
          value: '5 / 10 / 15 天',
          noteKey: 'life.work_worth.reference.annual_leave.note',
        ),
        WorkWorthReferenceStandard(
          key: 'public_holidays',
          titleKey: 'life.work_worth.reference.public_holidays.title',
          value: '约 13 天/年',
          noteKey: 'life.work_worth.reference.public_holidays.note',
        ),
        WorkWorthReferenceStandard(
          key: 'surplus',
          titleKey: 'life.work_worth.reference.surplus.title',
          value: '≥ 收入 30%',
          noteKey: 'life.work_worth.reference.surplus.note',
        ),
        WorkWorthReferenceStandard(
          key: 'health',
          titleKey: 'life.work_worth.reference.health.title',
          value: '0% - 18%',
          noteKey: 'life.work_worth.reference.health.note',
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
        labelKey: 'life.work_worth.rating.terrible',
      );
    }
    if (score < 1.0) {
      return const WorkWorthRating(
        key: 'poor',
        labelKey: 'life.work_worth.rating.poor',
      );
    }
    if (score <= 1.8) {
      return const WorkWorthRating(
        key: 'average',
        labelKey: 'life.work_worth.rating.average',
      );
    }
    if (score <= 2.5) {
      return const WorkWorthRating(
        key: 'good',
        labelKey: 'life.work_worth.rating.good',
      );
    }
    if (score <= 3.2) {
      return const WorkWorthRating(
        key: 'great',
        labelKey: 'life.work_worth.rating.great',
      );
    }
    if (score <= 4.0) {
      return const WorkWorthRating(
        key: 'excellent',
        labelKey: 'life.work_worth.rating.excellent',
      );
    }
    return const WorkWorthRating(
      key: 'legendary',
      labelKey: 'life.work_worth.rating.legendary',
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

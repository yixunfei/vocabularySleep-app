import 'dart:math' as math;

import 'toolbox_i18n_text_ref.dart';

enum CityCompareHousingType {
  centerOneBedroom,
  suburbOneBedroom,
  centerThreeBedroom,
  suburbThreeBedroom,
}

enum CityCompareDiningType { homeFocused, balanced, dineOutOften }

enum CityCompareTransportType { publicTransit, car }

enum CityCompareEducationType {
  none,
  kindergarten,
  primary,
  middle,
  high,
  international,
}

enum CityCompareCustomExpenseCategory {
  lifestyle,
  family,
  commute,
  health,
  debt,
  other,
}

class CityCompareCustomExpense {
  const CityCompareCustomExpense({
    required this.label,
    required this.amount,
    required this.category,
  });

  final String label;
  final double amount;
  final CityCompareCustomExpenseCategory category;
}

class CityCompareCityData {
  const CityCompareCityData({
    required this.city,
    required this.socialSecurityBaseMin,
    required this.socialSecurityBaseMax,
    required this.diningHome,
    required this.diningOut,
    required this.transportPublic,
    required this.transportCar,
    required this.rentCenterOneBedroom,
    required this.rentCenterThreeBedroom,
    required this.rentSuburbOneBedroom,
    required this.rentSuburbThreeBedroom,
    required this.housePriceCenter,
    required this.housePriceSuburb,
    required this.kindergarten,
    required this.primary,
    required this.middle,
    required this.high,
    required this.international,
    required this.mealCheap,
    required this.mealMid,
    required this.utilities,
    required this.mobilePlan,
    required this.internet,
    required this.fitness,
    required this.cinema,
  });

  final String city;
  final double socialSecurityBaseMin;
  final double socialSecurityBaseMax;
  final double diningHome;
  final double diningOut;
  final double transportPublic;
  final double transportCar;
  final double rentCenterOneBedroom;
  final double rentCenterThreeBedroom;
  final double rentSuburbOneBedroom;
  final double rentSuburbThreeBedroom;
  final double housePriceCenter;
  final double housePriceSuburb;
  final double kindergarten;
  final double primary;
  final double middle;
  final double high;
  final double international;
  final double mealCheap;
  final double mealMid;
  final double utilities;
  final double mobilePlan;
  final double internet;
  final double fitness;
  final double cinema;
}

class CityCompareProfile {
  const CityCompareProfile({
    required this.housingType,
    required this.diningType,
    required this.transportType,
    required this.educationType,
    required this.includeFitness,
    required this.monthlyCinemaTrips,
    this.housingAdjustment = 1,
    this.diningAdjustment = 1,
    this.transportAdjustment = 1,
    this.educationAdjustment = 1,
    this.utilitiesAdjustment = 1,
    this.fitnessAdjustment = 1,
    this.leisureAdjustment = 1,
    this.fitnessOverride,
    this.cinemaTicketOverride,
    this.customExpenses = const <CityCompareCustomExpense>[],
  });

  final CityCompareHousingType housingType;
  final CityCompareDiningType diningType;
  final CityCompareTransportType transportType;
  final CityCompareEducationType educationType;
  final bool includeFitness;
  final int monthlyCinemaTrips;
  final double housingAdjustment;
  final double diningAdjustment;
  final double transportAdjustment;
  final double educationAdjustment;
  final double utilitiesAdjustment;
  final double fitnessAdjustment;
  final double leisureAdjustment;
  final double? fitnessOverride;
  final double? cinemaTicketOverride;
  final List<CityCompareCustomExpense> customExpenses;
}

class CityCompareCostBreakdown {
  const CityCompareCostBreakdown({
    required this.housing,
    required this.dining,
    required this.transport,
    required this.education,
    required this.utilities,
    required this.digital,
    required this.fitness,
    required this.leisure,
    required this.custom,
    required this.total,
  });

  final double housing;
  final double dining;
  final double transport;
  final double education;
  final double utilities;
  final double digital;
  final double fitness;
  final double leisure;
  final double custom;
  final double total;
}

class CityCompareSalarySnapshot {
  const CityCompareSalarySnapshot({
    required this.grossMonthlySalary,
    required this.socialSecurityContribution,
    required this.tax,
    required this.netSalary,
    required this.monthlyCost,
    required this.monthlyBuffer,
  });

  final double grossMonthlySalary;
  final double socialSecurityContribution;
  final double tax;
  final double netSalary;
  final double monthlyCost;
  final double monthlyBuffer;
}

class CityCompareReferenceItem {
  const CityCompareReferenceItem({
    required this.category,
    required this.labelKey,
    required this.currentValue,
    required this.targetValue,
    required this.unitKey,
  });

  final String category;
  final String labelKey;
  final double currentValue;
  final double targetValue;
  final String unitKey;

  double get delta => targetValue - currentValue;
  double get ratio => currentValue == 0 ? 0 : targetValue / currentValue;
}

class CityCompareInsight {
  const CityCompareInsight({
    required this.level,
    required this.titleKey,
    required this.body,
  });

  final String level;
  final String titleKey;
  final ToolboxI18nTextRef body;
}

class CityCompareResult {
  const CityCompareResult({
    required this.currentCity,
    required this.targetCity,
    required this.currentBreakdown,
    required this.targetBreakdown,
    required this.currentSnapshot,
    required this.sameSalaryTargetSnapshot,
    required this.requiredTargetSnapshot,
    required this.breakEvenTargetSnapshot,
    required this.costRatio,
    required this.referenceItems,
    required this.insights,
  });

  final CityCompareCityData currentCity;
  final CityCompareCityData targetCity;
  final CityCompareCostBreakdown currentBreakdown;
  final CityCompareCostBreakdown targetBreakdown;
  final CityCompareSalarySnapshot currentSnapshot;
  final CityCompareSalarySnapshot sameSalaryTargetSnapshot;
  final CityCompareSalarySnapshot requiredTargetSnapshot;
  final CityCompareSalarySnapshot breakEvenTargetSnapshot;
  final double costRatio;
  final List<CityCompareReferenceItem> referenceItems;
  final List<CityCompareInsight> insights;
}

class ToolboxCityCompareService {
  static const double _standardDeduction = 5000;
  static const double _employeeSocialSecurityRate = 0.175;

  static const List<CityCompareCityData> cities = <CityCompareCityData>[
    CityCompareCityData(
      city: '深圳',
      socialSecurityBaseMin: 2360,
      socialSecurityBaseMax: 31014,
      diningHome: 1500,
      diningOut: 2500,
      transportPublic: 200,
      transportCar: 1500,
      rentCenterOneBedroom: 5388.89,
      rentCenterThreeBedroom: 12473.68,
      rentSuburbOneBedroom: 2882.35,
      rentSuburbThreeBedroom: 6607.14,
      housePriceCenter: 92101.73,
      housePriceSuburb: 48476.44,
      kindergarten: 3900,
      primary: 5000,
      middle: 6000,
      high: 7000,
      international: 13717.95,
      mealCheap: 25,
      mealMid: 200,
      utilities: 487.37,
      mobilePlan: 80.14,
      internet: 101.32,
      fitness: 315.35,
      cinema: 50,
    ),
    CityCompareCityData(
      city: '重庆',
      socialSecurityBaseMin: 3760,
      socialSecurityBaseMax: 19443,
      diningHome: 1000,
      diningOut: 1800,
      transportPublic: 240,
      transportCar: 1200,
      rentCenterOneBedroom: 1828.57,
      rentCenterThreeBedroom: 3400,
      rentSuburbOneBedroom: 1040,
      rentSuburbThreeBedroom: 2100,
      housePriceCenter: 16754.60,
      housePriceSuburb: 9526.36,
      kindergarten: 2300,
      primary: 3000,
      middle: 3500,
      high: 4000,
      international: 16111.11,
      mealCheap: 20,
      mealMid: 150,
      utilities: 310.72,
      mobilePlan: 59.67,
      internet: 63.20,
      fitness: 147.50,
      cinema: 37.5,
    ),
    CityCompareCityData(
      city: '北京',
      socialSecurityBaseMin: 3200,
      socialSecurityBaseMax: 25000,
      diningHome: 1300,
      diningOut: 2200,
      transportPublic: 250,
      transportCar: 1400,
      rentCenterOneBedroom: 6650.51,
      rentCenterThreeBedroom: 15593.75,
      rentSuburbOneBedroom: 3558.12,
      rentSuburbThreeBedroom: 7714.29,
      housePriceCenter: 105485.52,
      housePriceSuburb: 50268.59,
      kindergarten: 5514,
      primary: 6000,
      middle: 7000,
      high: 8000,
      international: 13431.37,
      mealCheap: 30,
      mealMid: 200,
      utilities: 390.82,
      mobilePlan: 67.45,
      internet: 94.03,
      fitness: 478.43,
      cinema: 60,
    ),
    CityCompareCityData(
      city: '上海',
      socialSecurityBaseMin: 3500,
      socialSecurityBaseMax: 27000,
      diningHome: 1600,
      diningOut: 2600,
      transportPublic: 250,
      transportCar: 1500,
      rentCenterOneBedroom: 7356.25,
      rentCenterThreeBedroom: 18979.41,
      rentSuburbOneBedroom: 3805.88,
      rentSuburbThreeBedroom: 9185.19,
      housePriceCenter: 113981.50,
      housePriceSuburb: 62896.55,
      kindergarten: 8865,
      primary: 7000,
      middle: 8000,
      high: 9000,
      international: 18276.52,
      mealCheap: 30,
      mealMid: 250,
      utilities: 400.52,
      mobilePlan: 85.15,
      internet: 120.64,
      fitness: 394.01,
      cinema: 60,
    ),
    CityCompareCityData(
      city: '成都',
      socialSecurityBaseMin: 2800,
      socialSecurityBaseMax: 19000,
      diningHome: 1200,
      diningOut: 1800,
      transportPublic: 200,
      transportCar: 1200,
      rentCenterOneBedroom: 2272.73,
      rentCenterThreeBedroom: 4346.15,
      rentSuburbOneBedroom: 1260,
      rentSuburbThreeBedroom: 2258.33,
      housePriceCenter: 29229.17,
      housePriceSuburb: 15489.35,
      kindergarten: 2729.63,
      primary: 3500,
      middle: 4500,
      high: 5500,
      international: 8854.17,
      mealCheap: 20,
      mealMid: 189.5,
      utilities: 345,
      mobilePlan: 93.71,
      internet: 84.94,
      fitness: 247.88,
      cinema: 40,
    ),
    CityCompareCityData(
      city: '广州',
      socialSecurityBaseMin: 3000,
      socialSecurityBaseMax: 23000,
      diningHome: 1400,
      diningOut: 2200,
      transportPublic: 110,
      transportCar: 1300,
      rentCenterOneBedroom: 3833.33,
      rentCenterThreeBedroom: 7961.54,
      rentSuburbOneBedroom: 1833.33,
      rentSuburbThreeBedroom: 4833.33,
      housePriceCenter: 72107.62,
      housePriceSuburb: 30376.90,
      kindergarten: 3100,
      primary: 4000,
      middle: 5000,
      high: 6000,
      international: 9319.44,
      mealCheap: 25,
      mealMid: 190,
      utilities: 474.69,
      mobilePlan: 94.50,
      internet: 91.07,
      fitness: 206.48,
      cinema: 50,
    ),
    CityCompareCityData(
      city: '长沙',
      socialSecurityBaseMin: 2600,
      socialSecurityBaseMax: 18000,
      diningHome: 1100,
      diningOut: 1600,
      transportPublic: 100,
      transportCar: 1200,
      rentCenterOneBedroom: 2300,
      rentCenterThreeBedroom: 3716.67,
      rentSuburbOneBedroom: 1233.33,
      rentSuburbThreeBedroom: 3433.33,
      housePriceCenter: 15036.36,
      housePriceSuburb: 39222.22,
      kindergarten: 2225,
      primary: 3000,
      middle: 3500,
      high: 4000,
      international: 5166.67,
      mealCheap: 20,
      mealMid: 145,
      utilities: 285.44,
      mobilePlan: 49.80,
      internet: 97.50,
      fitness: 466.42,
      cinema: 40,
    ),
    CityCompareCityData(
      city: '杭州',
      socialSecurityBaseMin: 3100,
      socialSecurityBaseMax: 24000,
      diningHome: 1300,
      diningOut: 2000,
      transportPublic: 110,
      transportCar: 1300,
      rentCenterOneBedroom: 3745.93,
      rentCenterThreeBedroom: 8054.81,
      rentSuburbOneBedroom: 2038.35,
      rentSuburbThreeBedroom: 4854.13,
      housePriceCenter: 60407.46,
      housePriceSuburb: 30427.34,
      kindergarten: 2808.33,
      primary: 4000,
      middle: 5000,
      high: 6000,
      international: 19642.86,
      mealCheap: 25,
      mealMid: 180,
      utilities: 348.07,
      mobilePlan: 85.29,
      internet: 114.78,
      fitness: 300.11,
      cinema: 45,
    ),
    CityCompareCityData(
      city: '南京',
      socialSecurityBaseMin: 3000,
      socialSecurityBaseMax: 21000,
      diningHome: 1200,
      diningOut: 2000,
      transportPublic: 200,
      transportCar: 1300,
      rentCenterOneBedroom: 3037.50,
      rentCenterThreeBedroom: 6100,
      rentSuburbOneBedroom: 2175,
      rentSuburbThreeBedroom: 3800,
      housePriceCenter: 43571.43,
      housePriceSuburb: 25400,
      kindergarten: 3749.68,
      primary: 4500,
      middle: 5500,
      high: 6500,
      international: 15833.33,
      mealCheap: 20,
      mealMid: 160,
      utilities: 336.88,
      mobilePlan: 87.89,
      internet: 90,
      fitness: 188.10,
      cinema: 45,
    ),
    CityCompareCityData(
      city: '武汉',
      socialSecurityBaseMin: 2800,
      socialSecurityBaseMax: 19000,
      diningHome: 1100,
      diningOut: 1800,
      transportPublic: 260,
      transportCar: 1200,
      rentCenterOneBedroom: 2933.33,
      rentCenterThreeBedroom: 5885.71,
      rentSuburbOneBedroom: 1716.67,
      rentSuburbThreeBedroom: 2583.33,
      housePriceCenter: 27272.73,
      housePriceSuburb: 16000,
      kindergarten: 2357.14,
      primary: 3500,
      middle: 4500,
      high: 5500,
      international: 5250,
      mealCheap: 25,
      mealMid: 150,
      utilities: 565,
      mobilePlan: 49.80,
      internet: 99.17,
      fitness: 253.22,
      cinema: 47.5,
    ),
  ];

  CityCompareResult compare({
    required String currentCityName,
    required String targetCityName,
    required double currentGrossMonthlySalary,
    required CityCompareProfile profile,
  }) {
    final currentCity = cityByName(currentCityName);
    final targetCity = cityByName(targetCityName);
    final currentBreakdown = costBreakdown(currentCity, profile);
    final targetBreakdown = costBreakdown(targetCity, profile);
    final currentSnapshot = salarySnapshot(
      city: currentCity,
      grossMonthlySalary: currentGrossMonthlySalary,
      monthlyCost: currentBreakdown.total,
    );
    final sameSalaryTargetSnapshot = salarySnapshot(
      city: targetCity,
      grossMonthlySalary: currentGrossMonthlySalary,
      monthlyCost: targetBreakdown.total,
    );
    final requiredTargetGross = _solveGrossForTargetBuffer(
      city: targetCity,
      monthlyCost: targetBreakdown.total,
      targetBuffer: currentSnapshot.monthlyBuffer,
    );
    final requiredTargetSnapshot = salarySnapshot(
      city: targetCity,
      grossMonthlySalary: requiredTargetGross,
      monthlyCost: targetBreakdown.total,
    );
    final breakEvenTargetGross = _solveGrossForTargetBuffer(
      city: targetCity,
      monthlyCost: targetBreakdown.total,
      targetBuffer: 0,
    );
    final breakEvenTargetSnapshot = salarySnapshot(
      city: targetCity,
      grossMonthlySalary: breakEvenTargetGross,
      monthlyCost: targetBreakdown.total,
    );
    return CityCompareResult(
      currentCity: currentCity,
      targetCity: targetCity,
      currentBreakdown: currentBreakdown,
      targetBreakdown: targetBreakdown,
      currentSnapshot: currentSnapshot,
      sameSalaryTargetSnapshot: sameSalaryTargetSnapshot,
      requiredTargetSnapshot: requiredTargetSnapshot,
      breakEvenTargetSnapshot: breakEvenTargetSnapshot,
      costRatio: targetBreakdown.total / math.max(1, currentBreakdown.total),
      referenceItems: _referenceItems(currentCity, targetCity),
      insights: _insights(
        currentCity: currentCity,
        targetCity: targetCity,
        currentBreakdown: currentBreakdown,
        targetBreakdown: targetBreakdown,
        currentSnapshot: currentSnapshot,
        sameSalaryTargetSnapshot: sameSalaryTargetSnapshot,
        requiredTargetSnapshot: requiredTargetSnapshot,
      ),
    );
  }

  CityCompareCityData cityByName(String name) {
    return cities.firstWhere(
      (city) => city.city == name,
      orElse: () => cities.first,
    );
  }

  CityCompareCostBreakdown costBreakdown(
    CityCompareCityData city,
    CityCompareProfile profile,
  ) {
    final housing =
        switch (profile.housingType) {
          CityCompareHousingType.centerOneBedroom => city.rentCenterOneBedroom,
          CityCompareHousingType.suburbOneBedroom => city.rentSuburbOneBedroom,
          CityCompareHousingType.centerThreeBedroom =>
            city.rentCenterThreeBedroom,
          CityCompareHousingType.suburbThreeBedroom =>
            city.rentSuburbThreeBedroom,
        } *
        profile.housingAdjustment;
    final (homeFactor, outFactor) = switch (profile.diningType) {
      CityCompareDiningType.homeFocused => (1.0, 0.35),
      CityCompareDiningType.balanced => (1.0, 0.75),
      CityCompareDiningType.dineOutOften => (0.8, 1.2),
    };
    final dining =
        (city.diningHome * homeFactor + city.diningOut * outFactor) *
        profile.diningAdjustment;
    final transport =
        switch (profile.transportType) {
          CityCompareTransportType.publicTransit => city.transportPublic,
          CityCompareTransportType.car => city.transportCar,
        } *
        profile.transportAdjustment;
    final education =
        switch (profile.educationType) {
          CityCompareEducationType.none => 0.0,
          CityCompareEducationType.kindergarten => city.kindergarten,
          CityCompareEducationType.primary => city.primary,
          CityCompareEducationType.middle => city.middle,
          CityCompareEducationType.high => city.high,
          CityCompareEducationType.international => city.international,
        } *
        profile.educationAdjustment;
    final utilities = city.utilities * profile.utilitiesAdjustment;
    final digital =
        (city.mobilePlan + city.internet) * profile.utilitiesAdjustment;
    final fitnessBase = profile.fitnessOverride ?? city.fitness;
    final fitness = profile.includeFitness
        ? fitnessBase * profile.fitnessAdjustment
        : 0.0;
    final cinemaTicket = profile.cinemaTicketOverride ?? city.cinema;
    final leisure =
        cinemaTicket * profile.monthlyCinemaTrips * profile.leisureAdjustment;
    final custom = profile.customExpenses.fold<double>(
      0,
      (sum, item) => sum + math.max(0, item.amount),
    );
    final total =
        housing +
        dining +
        transport +
        education +
        utilities +
        digital +
        fitness +
        leisure +
        custom;
    return CityCompareCostBreakdown(
      housing: housing,
      dining: dining,
      transport: transport,
      education: education,
      utilities: utilities,
      digital: digital,
      fitness: fitness,
      leisure: leisure,
      custom: custom,
      total: total,
    );
  }

  CityCompareSalarySnapshot salarySnapshot({
    required CityCompareCityData city,
    required double grossMonthlySalary,
    required double monthlyCost,
  }) {
    final socialSecurityContribution = _socialSecurityContribution(
      grossMonthlySalary,
      city,
    );
    final tax = _monthlyTax(grossMonthlySalary, socialSecurityContribution);
    final netSalary = grossMonthlySalary - socialSecurityContribution - tax;
    return CityCompareSalarySnapshot(
      grossMonthlySalary: grossMonthlySalary,
      socialSecurityContribution: socialSecurityContribution,
      tax: tax,
      netSalary: netSalary,
      monthlyCost: monthlyCost,
      monthlyBuffer: netSalary - monthlyCost,
    );
  }

  double _socialSecurityContribution(
    double grossMonthlySalary,
    CityCompareCityData city,
  ) {
    final base = grossMonthlySalary.clamp(
      city.socialSecurityBaseMin,
      city.socialSecurityBaseMax,
    );
    return base * _employeeSocialSecurityRate;
  }

  double _monthlyTax(double gross, double socialSecurityContribution) {
    final taxable = gross - socialSecurityContribution - _standardDeduction;
    if (taxable <= 0) {
      return 0;
    }
    if (taxable <= 3000) {
      return taxable * 0.03;
    }
    if (taxable <= 12000) {
      return taxable * 0.10 - 210;
    }
    if (taxable <= 25000) {
      return taxable * 0.20 - 1410;
    }
    if (taxable <= 35000) {
      return taxable * 0.25 - 2660;
    }
    if (taxable <= 55000) {
      return taxable * 0.30 - 4410;
    }
    if (taxable <= 80000) {
      return taxable * 0.35 - 7160;
    }
    return taxable * 0.45 - 15160;
  }

  double _solveGrossForTargetBuffer({
    required CityCompareCityData city,
    required double monthlyCost,
    required double targetBuffer,
  }) {
    var low = 0.0;
    var high = 200000.0;
    while (salarySnapshot(
          city: city,
          grossMonthlySalary: high,
          monthlyCost: monthlyCost,
        ).monthlyBuffer <
        targetBuffer) {
      high *= 1.5;
      if (high > 1000000) {
        break;
      }
    }
    for (var index = 0; index < 50; index += 1) {
      final mid = (low + high) / 2;
      final snapshot = salarySnapshot(
        city: city,
        grossMonthlySalary: mid,
        monthlyCost: monthlyCost,
      );
      if (snapshot.monthlyBuffer >= targetBuffer) {
        high = mid;
      } else {
        low = mid;
      }
    }
    return high;
  }

  List<CityCompareReferenceItem> _referenceItems(
    CityCompareCityData currentCity,
    CityCompareCityData targetCity,
  ) {
    return <CityCompareReferenceItem>[
      CityCompareReferenceItem(
        category: 'salary',
        labelKey: 'life.city_compare.reference.social_security_base_min',
        currentValue: currentCity.socialSecurityBaseMin,
        targetValue: targetCity.socialSecurityBaseMin,
        unitKey: 'life.city_compare.unit.cny_month',
      ),
      CityCompareReferenceItem(
        category: 'salary',
        labelKey: 'life.city_compare.reference.social_security_base_max',
        currentValue: currentCity.socialSecurityBaseMax,
        targetValue: targetCity.socialSecurityBaseMax,
        unitKey: 'life.city_compare.unit.cny_month',
      ),
      CityCompareReferenceItem(
        category: 'housing',
        labelKey: 'life.city_compare.reference.center_1br_rent',
        currentValue: currentCity.rentCenterOneBedroom,
        targetValue: targetCity.rentCenterOneBedroom,
        unitKey: 'life.city_compare.unit.cny_month',
      ),
      CityCompareReferenceItem(
        category: 'housing',
        labelKey: 'life.city_compare.reference.suburb_1br_rent',
        currentValue: currentCity.rentSuburbOneBedroom,
        targetValue: targetCity.rentSuburbOneBedroom,
        unitKey: 'life.city_compare.unit.cny_month',
      ),
      CityCompareReferenceItem(
        category: 'housing',
        labelKey: 'life.city_compare.reference.center_3br_rent',
        currentValue: currentCity.rentCenterThreeBedroom,
        targetValue: targetCity.rentCenterThreeBedroom,
        unitKey: 'life.city_compare.unit.cny_month',
      ),
      CityCompareReferenceItem(
        category: 'housing',
        labelKey: 'life.city_compare.reference.suburb_3br_rent',
        currentValue: currentCity.rentSuburbThreeBedroom,
        targetValue: targetCity.rentSuburbThreeBedroom,
        unitKey: 'life.city_compare.unit.cny_month',
      ),
      CityCompareReferenceItem(
        category: 'housing',
        labelKey: 'life.city_compare.reference.center_house_price',
        currentValue: currentCity.housePriceCenter,
        targetValue: targetCity.housePriceCenter,
        unitKey: 'life.city_compare.unit.cny_square_meter',
      ),
      CityCompareReferenceItem(
        category: 'housing',
        labelKey: 'life.city_compare.reference.suburb_house_price',
        currentValue: currentCity.housePriceSuburb,
        targetValue: targetCity.housePriceSuburb,
        unitKey: 'life.city_compare.unit.cny_square_meter',
      ),
      CityCompareReferenceItem(
        category: 'daily',
        labelKey: 'life.city_compare.reference.home_dining_budget',
        currentValue: currentCity.diningHome,
        targetValue: targetCity.diningHome,
        unitKey: 'life.city_compare.unit.cny_month',
      ),
      CityCompareReferenceItem(
        category: 'daily',
        labelKey: 'life.city_compare.reference.dining_out_budget',
        currentValue: currentCity.diningOut,
        targetValue: targetCity.diningOut,
        unitKey: 'life.city_compare.unit.cny_month',
      ),
      CityCompareReferenceItem(
        category: 'daily',
        labelKey: 'life.city_compare.reference.cheap_meal',
        currentValue: currentCity.mealCheap,
        targetValue: targetCity.mealCheap,
        unitKey: 'life.city_compare.unit.cny_meal',
      ),
      CityCompareReferenceItem(
        category: 'daily',
        labelKey: 'life.city_compare.reference.mid_meal',
        currentValue: currentCity.mealMid,
        targetValue: targetCity.mealMid,
        unitKey: 'life.city_compare.unit.cny_meal',
      ),
      CityCompareReferenceItem(
        category: 'daily',
        labelKey: 'life.city_compare.reference.utilities',
        currentValue: currentCity.utilities,
        targetValue: targetCity.utilities,
        unitKey: 'life.city_compare.unit.cny_month',
      ),
      CityCompareReferenceItem(
        category: 'daily',
        labelKey: 'life.city_compare.reference.mobile_plan',
        currentValue: currentCity.mobilePlan,
        targetValue: targetCity.mobilePlan,
        unitKey: 'life.city_compare.unit.cny_month',
      ),
      CityCompareReferenceItem(
        category: 'daily',
        labelKey: 'life.city_compare.reference.internet',
        currentValue: currentCity.internet,
        targetValue: targetCity.internet,
        unitKey: 'life.city_compare.unit.cny_month',
      ),
      CityCompareReferenceItem(
        category: 'transport',
        labelKey: 'life.city_compare.reference.public_transit',
        currentValue: currentCity.transportPublic,
        targetValue: targetCity.transportPublic,
        unitKey: 'life.city_compare.unit.cny_month',
      ),
      CityCompareReferenceItem(
        category: 'transport',
        labelKey: 'life.city_compare.reference.car_commuting',
        currentValue: currentCity.transportCar,
        targetValue: targetCity.transportCar,
        unitKey: 'life.city_compare.unit.cny_month',
      ),
      CityCompareReferenceItem(
        category: 'family',
        labelKey: 'life.city_compare.reference.kindergarten',
        currentValue: currentCity.kindergarten,
        targetValue: targetCity.kindergarten,
        unitKey: 'life.city_compare.unit.cny_month',
      ),
      CityCompareReferenceItem(
        category: 'family',
        labelKey: 'life.city_compare.reference.primary_school',
        currentValue: currentCity.primary,
        targetValue: targetCity.primary,
        unitKey: 'life.city_compare.unit.cny_month',
      ),
      CityCompareReferenceItem(
        category: 'family',
        labelKey: 'life.city_compare.reference.middle_school',
        currentValue: currentCity.middle,
        targetValue: targetCity.middle,
        unitKey: 'life.city_compare.unit.cny_month',
      ),
      CityCompareReferenceItem(
        category: 'family',
        labelKey: 'life.city_compare.reference.high_school',
        currentValue: currentCity.high,
        targetValue: targetCity.high,
        unitKey: 'life.city_compare.unit.cny_month',
      ),
      CityCompareReferenceItem(
        category: 'family',
        labelKey: 'life.city_compare.reference.international_school',
        currentValue: currentCity.international,
        targetValue: targetCity.international,
        unitKey: 'life.city_compare.unit.cny_month',
      ),
      CityCompareReferenceItem(
        category: 'leisure',
        labelKey: 'life.city_compare.reference.fitness',
        currentValue: currentCity.fitness,
        targetValue: targetCity.fitness,
        unitKey: 'life.city_compare.unit.cny_month',
      ),
      CityCompareReferenceItem(
        category: 'leisure',
        labelKey: 'life.city_compare.reference.cinema',
        currentValue: currentCity.cinema,
        targetValue: targetCity.cinema,
        unitKey: 'life.city_compare.unit.cny_ticket',
      ),
    ];
  }

  List<CityCompareInsight> _insights({
    required CityCompareCityData currentCity,
    required CityCompareCityData targetCity,
    required CityCompareCostBreakdown currentBreakdown,
    required CityCompareCostBreakdown targetBreakdown,
    required CityCompareSalarySnapshot currentSnapshot,
    required CityCompareSalarySnapshot sameSalaryTargetSnapshot,
    required CityCompareSalarySnapshot requiredTargetSnapshot,
  }) {
    final costDiffs = <MapEntry<ToolboxI18nTextRef, double>>[
      MapEntry<ToolboxI18nTextRef, double>(
        const ToolboxI18nTextRef('life.city_compare.diff_category.housing'),
        targetBreakdown.housing - currentBreakdown.housing,
      ),
      MapEntry<ToolboxI18nTextRef, double>(
        const ToolboxI18nTextRef('life.city_compare.diff_category.dining'),
        targetBreakdown.dining - currentBreakdown.dining,
      ),
      MapEntry<ToolboxI18nTextRef, double>(
        const ToolboxI18nTextRef('life.city_compare.diff_category.transport'),
        targetBreakdown.transport - currentBreakdown.transport,
      ),
      MapEntry<ToolboxI18nTextRef, double>(
        const ToolboxI18nTextRef('life.city_compare.diff_category.education'),
        targetBreakdown.education - currentBreakdown.education,
      ),
      MapEntry<ToolboxI18nTextRef, double>(
        const ToolboxI18nTextRef('life.city_compare.diff_category.utilities'),
        (targetBreakdown.utilities + targetBreakdown.digital) -
            (currentBreakdown.utilities + currentBreakdown.digital),
      ),
      MapEntry<ToolboxI18nTextRef, double>(
        const ToolboxI18nTextRef('life.city_compare.diff_category.leisure'),
        (targetBreakdown.fitness + targetBreakdown.leisure) -
            (currentBreakdown.fitness + currentBreakdown.leisure),
      ),
    ]..sort((left, right) => right.value.abs().compareTo(left.value.abs()));
    final biggest = costDiffs.first;
    final second = costDiffs.length > 1 ? costDiffs[1] : biggest;
    final sameSalaryDelta =
        sameSalaryTargetSnapshot.monthlyBuffer - currentSnapshot.monthlyBuffer;
    final educationGap = targetCity.international - currentCity.international;
    final centerRentRatio =
        targetCity.rentCenterOneBedroom /
        math.max(1, currentCity.rentCenterOneBedroom);

    return <CityCompareInsight>[
      CityCompareInsight(
        level: 'primary',
        titleKey: 'life.city_compare.insight.biggest_delta.title',
        body: ToolboxI18nTextRef(
          'life.city_compare.insight.biggest_delta.body',
          params: <String, Object?>{
            'targetCity': targetCity.city,
            'currentCity': currentCity.city,
            'biggest': biggest.key,
            'biggestValue':
                '${biggest.value >= 0 ? '+' : ''}${biggest.value.toStringAsFixed(0)}',
            'second': second.key,
          },
        ),
      ),
      CityCompareInsight(
        level: sameSalaryDelta >= 0 ? 'positive' : 'warning',
        titleKey: 'life.city_compare.insight.same_salary.title',
        body: ToolboxI18nTextRef(
          'life.city_compare.insight.same_salary.body',
          params: <String, Object?>{
            'targetCity': targetCity.city,
            'currentBuffer': currentSnapshot.monthlyBuffer.toStringAsFixed(0),
            'targetBuffer': sameSalaryTargetSnapshot.monthlyBuffer
                .toStringAsFixed(0),
            'delta':
                '${sameSalaryDelta >= 0 ? '+' : ''}${sameSalaryDelta.toStringAsFixed(0)}',
          },
        ),
      ),
      CityCompareInsight(
        level: 'neutral',
        titleKey: 'life.city_compare.insight.reference_note.title',
        body: ToolboxI18nTextRef(
          'life.city_compare.insight.reference_note.body',
          params: <String, Object?>{
            'targetCity': targetCity.city,
            'currentCity': currentCity.city,
            'centerRentRatio': centerRentRatio.toStringAsFixed(2),
            'educationGap':
                '${educationGap >= 0 ? '+' : ''}${educationGap.toStringAsFixed(0)}',
          },
        ),
      ),
      CityCompareInsight(
        level: 'primary',
        titleKey: 'life.city_compare.insight.salary_needed.title',
        body: ToolboxI18nTextRef(
          'life.city_compare.insight.salary_needed.body',
          params: <String, Object?>{
            'targetCity': targetCity.city,
            'salary': requiredTargetSnapshot.grossMonthlySalary.toStringAsFixed(
              0,
            ),
          },
        ),
      ),
    ];
  }
}

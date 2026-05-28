import 'dart:math' as math;

part 'toolbox_bmi_cdc_data.dart';

enum ToolboxBmiSex { male, female }

enum ToolboxAdultBmiStandard { china, who }

enum ToolboxBmiActivityLevel { sedentary, light, moderate, active, veryActive }

enum ToolboxAdultBmiCategory {
  underweight,
  healthy,
  overweight,
  obesityClass1,
  obesityClass2,
  obesityClass3,
}

enum ToolboxYouthBmiCategory {
  underweight,
  healthy,
  overweight,
  obesity,
  severeObesity,
}

enum ToolboxWaistHeightCategory { low, healthy, increased, high }

enum ToolboxWaistHipCategory { low, increased, high }

class ToolboxBmiInput {
  const ToolboxBmiInput({
    required this.heightCm,
    required this.weightKg,
    required this.ageYears,
    required this.sex,
    required this.adultStandard,
    required this.activityLevel,
    this.waistCm,
    this.hipCm,
  });

  final double heightCm;
  final double weightKg;
  final double ageYears;
  final ToolboxBmiSex sex;
  final ToolboxAdultBmiStandard adultStandard;
  final ToolboxBmiActivityLevel activityLevel;
  final double? waistCm;
  final double? hipCm;
}

class ToolboxBmiAssessment {
  const ToolboxBmiAssessment({
    required this.bmi,
    required this.heightMeters,
    required this.weightKg,
    required this.ageYears,
    required this.sex,
    required this.ageBand,
    required this.adultStandard,
    required this.adultCategory,
    required this.youthCategory,
    required this.percentile,
    required this.zScore,
    required this.healthyMinKg,
    required this.healthyMaxKg,
    required this.targetMidKg,
    required this.waistToHeightRatio,
    required this.waistHeightCategory,
    required this.waistToHipRatio,
    required this.waistHipCategory,
    required this.bmrKcal,
    required this.tdeeKcal,
  });

  final double bmi;
  final double heightMeters;
  final double weightKg;
  final double ageYears;
  final ToolboxBmiSex sex;
  final String ageBand;
  final ToolboxAdultBmiStandard adultStandard;
  final ToolboxAdultBmiCategory? adultCategory;
  final ToolboxYouthBmiCategory? youthCategory;
  final double? percentile;
  final double? zScore;
  final double? healthyMinKg;
  final double? healthyMaxKg;
  final double? targetMidKg;
  final double? waistToHeightRatio;
  final ToolboxWaistHeightCategory? waistHeightCategory;
  final double? waistToHipRatio;
  final ToolboxWaistHipCategory? waistHipCategory;
  final double? bmrKcal;
  final double? tdeeKcal;

  bool get isAdult => adultCategory != null;

  bool get isYouth => youthCategory != null;

  bool get isTooYoungForBmiForAge => ageYears < 2;
}

class _AdultBmiRange {
  const _AdultBmiRange({
    required this.minHealthy,
    required this.maxHealthy,
    required this.category,
  });

  final double minHealthy;
  final double maxHealthy;
  final ToolboxAdultBmiCategory Function(double bmi) category;
}

class _CdcBmiReferencePoint {
  const _CdcBmiReferencePoint(
    this.sex,
    this.ageMonths,
    this.l,
    this.m,
    this.s,
    this.p5,
    this.p85,
    this.p95,
  );

  final int sex;
  final double ageMonths;
  final double l;
  final double m;
  final double s;
  final double p5;
  final double p85;
  final double p95;
}

List<_CdcBmiReferencePoint> _parseCdcBmiForAge(String csv) {
  return csv
      .trim()
      .split('\n')
      .map((line) {
        final parts = line.trim().split(',');
        return _CdcBmiReferencePoint(
          int.parse(parts[0]),
          double.parse(parts[1]),
          double.parse(parts[2]),
          double.parse(parts[3]),
          double.parse(parts[4]),
          double.parse(parts[5]),
          double.parse(parts[6]),
          double.parse(parts[7]),
        );
      })
      .toList(growable: false);
}

class ToolboxBmiService {
  const ToolboxBmiService();

  static const Map<ToolboxBmiActivityLevel, double> activityFactors =
      <ToolboxBmiActivityLevel, double>{
        ToolboxBmiActivityLevel.sedentary: 1.2,
        ToolboxBmiActivityLevel.light: 1.375,
        ToolboxBmiActivityLevel.moderate: 1.55,
        ToolboxBmiActivityLevel.active: 1.725,
        ToolboxBmiActivityLevel.veryActive: 1.9,
      };

  ToolboxBmiAssessment assess(ToolboxBmiInput input) {
    final heightMeters = input.heightCm / 100;
    if (heightMeters <= 0 || input.weightKg <= 0 || input.ageYears <= 0) {
      throw ArgumentError('height, weight, and age must be positive');
    }

    final bmi = input.weightKg / math.pow(heightMeters, 2);
    final adultRange = _adultRange(input.adultStandard);
    final ageBand = classifyAgeBand(input.ageYears);
    final isAdult = input.ageYears >= 20;
    final isYouth = input.ageYears >= 2 && input.ageYears < 20;
    final youthReference = isYouth
        ? _interpolateCdcReference(input.sex, input.ageYears * 12)
        : null;
    final zScore = youthReference == null
        ? null
        : _zScoreFromLms(
            bmi,
            youthReference.l,
            youthReference.m,
            youthReference.s,
          );
    final percentile = zScore == null ? null : _normalCdf(zScore) * 100;
    final youthCategory = youthReference == null || percentile == null
        ? null
        : _youthCategory(
            bmi: bmi,
            percentile: percentile,
            p95: youthReference.p95,
          );
    final waistHeightRatio = input.waistCm == null || input.waistCm! <= 0
        ? null
        : input.waistCm! / input.heightCm;
    final waistHipRatio =
        input.waistCm == null ||
            input.hipCm == null ||
            input.waistCm! <= 0 ||
            input.hipCm! <= 0
        ? null
        : input.waistCm! / input.hipCm!;
    final bmr = input.ageYears >= 15
        ? _mifflinStJeor(
            heightCm: input.heightCm,
            weightKg: input.weightKg,
            ageYears: input.ageYears,
            sex: input.sex,
          )
        : null;
    final tdee = bmr == null
        ? null
        : bmr * activityFactors[input.activityLevel]!;

    return ToolboxBmiAssessment(
      bmi: bmi,
      heightMeters: heightMeters,
      weightKg: input.weightKg,
      ageYears: input.ageYears,
      sex: input.sex,
      ageBand: ageBand,
      adultStandard: input.adultStandard,
      adultCategory: isAdult ? adultRange.category(bmi) : null,
      youthCategory: youthCategory,
      percentile: percentile,
      zScore: zScore,
      healthyMinKg: isAdult
          ? adultRange.minHealthy * heightMeters * heightMeters
          : youthReference == null
          ? null
          : youthReference.p5 * heightMeters * heightMeters,
      healthyMaxKg: isAdult
          ? adultRange.maxHealthy * heightMeters * heightMeters
          : youthReference == null
          ? null
          : youthReference.p85 * heightMeters * heightMeters,
      targetMidKg: isAdult
          ? ((adultRange.minHealthy + adultRange.maxHealthy) / 2) *
                heightMeters *
                heightMeters
          : youthReference == null
          ? null
          : youthReference.m * heightMeters * heightMeters,
      waistToHeightRatio: waistHeightRatio,
      waistHeightCategory: waistHeightRatio == null
          ? null
          : _waistHeightCategory(waistHeightRatio),
      waistToHipRatio: waistHipRatio,
      waistHipCategory: waistHipRatio == null
          ? null
          : _waistHipCategory(waistHipRatio, input.sex),
      bmrKcal: bmr,
      tdeeKcal: tdee,
    );
  }

  static String classifyAgeBand(double ageYears) {
    if (ageYears < 2) {
      return 'infant';
    }
    if (ageYears < 13) {
      return 'child';
    }
    if (ageYears < 20) {
      return 'teen';
    }
    return 'adult';
  }

  static _AdultBmiRange _adultRange(ToolboxAdultBmiStandard standard) {
    return switch (standard) {
      ToolboxAdultBmiStandard.china => _AdultBmiRange(
        minHealthy: 18.5,
        maxHealthy: 23.9,
        category: (bmi) {
          if (bmi < 18.5) {
            return ToolboxAdultBmiCategory.underweight;
          }
          if (bmi < 24) {
            return ToolboxAdultBmiCategory.healthy;
          }
          if (bmi < 28) {
            return ToolboxAdultBmiCategory.overweight;
          }
          return ToolboxAdultBmiCategory.obesityClass1;
        },
      ),
      ToolboxAdultBmiStandard.who => _AdultBmiRange(
        minHealthy: 18.5,
        maxHealthy: 24.9,
        category: (bmi) {
          if (bmi < 18.5) {
            return ToolboxAdultBmiCategory.underweight;
          }
          if (bmi < 25) {
            return ToolboxAdultBmiCategory.healthy;
          }
          if (bmi < 30) {
            return ToolboxAdultBmiCategory.overweight;
          }
          if (bmi < 35) {
            return ToolboxAdultBmiCategory.obesityClass1;
          }
          if (bmi < 40) {
            return ToolboxAdultBmiCategory.obesityClass2;
          }
          return ToolboxAdultBmiCategory.obesityClass3;
        },
      ),
    };
  }

  static ToolboxYouthBmiCategory _youthCategory({
    required double bmi,
    required double percentile,
    required double p95,
  }) {
    if (percentile < 5) {
      return ToolboxYouthBmiCategory.underweight;
    }
    if (percentile < 85) {
      return ToolboxYouthBmiCategory.healthy;
    }
    if (percentile < 95) {
      return ToolboxYouthBmiCategory.overweight;
    }
    if (bmi >= 35 || bmi >= p95 * 1.2) {
      return ToolboxYouthBmiCategory.severeObesity;
    }
    return ToolboxYouthBmiCategory.obesity;
  }

  static _CdcBmiReferencePoint? _interpolateCdcReference(
    ToolboxBmiSex sex,
    double ageMonths,
  ) {
    final cdcSex = sex == ToolboxBmiSex.male ? 1 : 2;
    final points = _cdcBmiForAge
        .where((point) => point.sex == cdcSex)
        .toList(growable: false);
    if (ageMonths < points.first.ageMonths ||
        ageMonths > points.last.ageMonths) {
      return null;
    }
    for (var index = 0; index < points.length - 1; index += 1) {
      final left = points[index];
      final right = points[index + 1];
      if (ageMonths == left.ageMonths) {
        return left;
      }
      if (ageMonths > left.ageMonths && ageMonths <= right.ageMonths) {
        final t =
            (ageMonths - left.ageMonths) / (right.ageMonths - left.ageMonths);
        return _CdcBmiReferencePoint(
          cdcSex,
          ageMonths,
          _lerp(left.l, right.l, t),
          _lerp(left.m, right.m, t),
          _lerp(left.s, right.s, t),
          _lerp(left.p5, right.p5, t),
          _lerp(left.p85, right.p85, t),
          _lerp(left.p95, right.p95, t),
        );
      }
    }
    return points.last;
  }

  static double _zScoreFromLms(double value, double l, double m, double s) {
    if (l == 0) {
      return math.log(value / m) / s;
    }
    return (math.pow(value / m, l) - 1) / (l * s);
  }

  static double _mifflinStJeor({
    required double heightCm,
    required double weightKg,
    required double ageYears,
    required ToolboxBmiSex sex,
  }) {
    final offset = sex == ToolboxBmiSex.male ? 5 : -161;
    return 10 * weightKg + 6.25 * heightCm - 5 * ageYears + offset;
  }

  static ToolboxWaistHeightCategory _waistHeightCategory(double ratio) {
    if (ratio < 0.4) {
      return ToolboxWaistHeightCategory.low;
    }
    if (ratio < 0.5) {
      return ToolboxWaistHeightCategory.healthy;
    }
    if (ratio < 0.6) {
      return ToolboxWaistHeightCategory.increased;
    }
    return ToolboxWaistHeightCategory.high;
  }

  static ToolboxWaistHipCategory _waistHipCategory(
    double ratio,
    ToolboxBmiSex sex,
  ) {
    final highCutoff = sex == ToolboxBmiSex.male ? 0.9 : 0.85;
    final increasedCutoff = sex == ToolboxBmiSex.male ? 0.85 : 0.8;
    if (ratio >= highCutoff) {
      return ToolboxWaistHipCategory.high;
    }
    if (ratio >= increasedCutoff) {
      return ToolboxWaistHipCategory.increased;
    }
    return ToolboxWaistHipCategory.low;
  }

  static double _normalCdf(double x) {
    final sign = x < 0 ? -1.0 : 1.0;
    final value = x.abs() / math.sqrt2;
    final t = 1.0 / (1.0 + 0.3275911 * value);
    final erf =
        1 -
        (((((1.061405429 * t - 1.453152027) * t + 1.421413741) * t -
                        0.284496736) *
                    t +
                0.254829592) *
            t *
            math.exp(-value * value));
    return 0.5 * (1 + sign * erf);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

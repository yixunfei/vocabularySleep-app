import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_bmi_service.dart';

void main() {
  group('ToolboxBmiService', () {
    const service = ToolboxBmiService();

    test('classifies adult BMI with China bands and energy estimates', () {
      final result = service.assess(
        const ToolboxBmiInput(
          heightCm: 170,
          weightKg: 80,
          ageYears: 32,
          sex: ToolboxBmiSex.female,
          adultStandard: ToolboxAdultBmiStandard.china,
          activityLevel: ToolboxBmiActivityLevel.light,
          waistCm: 78,
          hipCm: 95,
        ),
      );

      expect(result.bmi, closeTo(27.68, 0.01));
      expect(result.adultCategory, ToolboxAdultBmiCategory.overweight);
      expect(result.healthyMinKg, closeTo(53.46, 0.01));
      expect(result.healthyMaxKg, closeTo(69.07, 0.01));
      expect(result.waistHeightCategory, ToolboxWaistHeightCategory.healthy);
      expect(result.waistHipCategory, ToolboxWaistHipCategory.increased);
      expect(result.bmrKcal, closeTo(1541.5, 0.1));
      expect(result.tdeeKcal, closeTo(2119.56, 0.1));
    });

    test('keeps WHO adult obesity levels separate from China bands', () {
      final result = service.assess(
        const ToolboxBmiInput(
          heightCm: 170,
          weightKg: 102,
          ageYears: 40,
          sex: ToolboxBmiSex.male,
          adultStandard: ToolboxAdultBmiStandard.who,
          activityLevel: ToolboxBmiActivityLevel.sedentary,
        ),
      );

      expect(result.bmi, closeTo(35.29, 0.01));
      expect(result.adultCategory, ToolboxAdultBmiCategory.obesityClass2);
      expect(result.healthyMaxKg, closeTo(71.96, 0.01));
    });

    test('uses CDC BMI-for-age for children and teens', () {
      final result = service.assess(
        const ToolboxBmiInput(
          heightCm: 140,
          weightKg: 45,
          ageYears: 10,
          sex: ToolboxBmiSex.male,
          adultStandard: ToolboxAdultBmiStandard.china,
          activityLevel: ToolboxBmiActivityLevel.moderate,
        ),
      );

      expect(result.adultCategory, isNull);
      expect(result.youthCategory, ToolboxYouthBmiCategory.obesity);
      expect(result.percentile, greaterThanOrEqualTo(95));
      expect(result.healthyMinKg, isNotNull);
      expect(result.healthyMaxKg, isNotNull);
    });

    test('does not apply BMI-for-age categories under age two', () {
      final result = service.assess(
        const ToolboxBmiInput(
          heightCm: 80,
          weightKg: 11,
          ageYears: 1.5,
          sex: ToolboxBmiSex.female,
          adultStandard: ToolboxAdultBmiStandard.china,
          activityLevel: ToolboxBmiActivityLevel.light,
        ),
      );

      expect(result.isTooYoungForBmiForAge, isTrue);
      expect(result.adultCategory, isNull);
      expect(result.youthCategory, isNull);
      expect(result.percentile, isNull);
    });
  });
}

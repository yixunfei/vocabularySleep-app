import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_city_compare_service.dart';

void main() {
  group('toolbox city compare service', () {
    const profile = CityCompareProfile(
      housingType: CityCompareHousingType.suburbOneBedroom,
      diningType: CityCompareDiningType.balanced,
      transportType: CityCompareTransportType.publicTransit,
      educationType: CityCompareEducationType.none,
      includeFitness: false,
      monthlyCinemaTrips: 2,
    );

    test('computes target salary and same-salary buffer across cities', () {
      final service = ToolboxCityCompareService();
      final result = service.compare(
        currentCityName: '重庆',
        targetCityName: '北京',
        currentGrossMonthlySalary: 22000,
        profile: profile,
      );

      expect(result.currentSnapshot.monthlyBuffer, greaterThan(0));
      expect(
        result.requiredTargetSnapshot.grossMonthlySalary,
        greaterThan(result.currentSnapshot.grossMonthlySalary),
      );
      expect(
        result.sameSalaryTargetSnapshot.monthlyBuffer,
        lessThan(result.currentSnapshot.monthlyBuffer),
      );
      expect(result.costRatio, greaterThan(1));
      expect(result.referenceItems.length, greaterThan(10));
      expect(
        result.insights.any(
          (insight) =>
              insight.titleKey ==
              'life.city_compare.insight.biggest_delta.title',
        ),
        isTrue,
      );
    });

    test('supports lower target salary when moving to cheaper city', () {
      final service = ToolboxCityCompareService();
      final result = service.compare(
        currentCityName: '上海',
        targetCityName: '长沙',
        currentGrossMonthlySalary: 30000,
        profile: profile,
      );

      expect(
        result.requiredTargetSnapshot.grossMonthlySalary,
        lessThan(result.currentSnapshot.grossMonthlySalary),
      );
      expect(
        result.breakEvenTargetSnapshot.grossMonthlySalary,
        lessThan(result.requiredTargetSnapshot.grossMonthlySalary),
      );
    });

    test('reference items expose raw housing and dining anchors', () {
      final service = ToolboxCityCompareService();
      final result = service.compare(
        currentCityName: '深圳',
        targetCityName: '成都',
        currentGrossMonthlySalary: 28000,
        profile: profile,
      );

      expect(
        result.referenceItems.any(
          (item) =>
              item.labelKey == 'life.city_compare.reference.center_1br_rent',
        ),
        isTrue,
      );
      expect(
        result.referenceItems.any(
          (item) => item.labelKey == 'life.city_compare.reference.cheap_meal',
        ),
        isTrue,
      );
      expect(
        result.insights.any(
          (insight) =>
              insight.body.key ==
              'life.city_compare.insight.reference_note.body',
        ),
        isTrue,
      );
    });

    test('custom expenses and multipliers change breakdown totals', () {
      final service = ToolboxCityCompareService();
      const baseProfile = CityCompareProfile(
        housingType: CityCompareHousingType.suburbOneBedroom,
        diningType: CityCompareDiningType.balanced,
        transportType: CityCompareTransportType.publicTransit,
        educationType: CityCompareEducationType.none,
        includeFitness: true,
        monthlyCinemaTrips: 2,
      );
      const adjustedProfile = CityCompareProfile(
        housingType: CityCompareHousingType.suburbOneBedroom,
        diningType: CityCompareDiningType.balanced,
        transportType: CityCompareTransportType.publicTransit,
        educationType: CityCompareEducationType.none,
        includeFitness: true,
        monthlyCinemaTrips: 2,
        housingAdjustment: 1.2,
        fitnessAdjustment: 1.3,
        customExpenses: <CityCompareCustomExpense>[
          CityCompareCustomExpense(
            label: 'Pet care',
            amount: 800,
            category: CityCompareCustomExpenseCategory.family,
          ),
        ],
      );

      final base = service.compare(
        currentCityName: '成都',
        targetCityName: '杭州',
        currentGrossMonthlySalary: 26000,
        profile: baseProfile,
      );
      final adjusted = service.compare(
        currentCityName: '成都',
        targetCityName: '杭州',
        currentGrossMonthlySalary: 26000,
        profile: adjustedProfile,
      );

      expect(adjusted.currentBreakdown.custom, 800);
      expect(
        adjusted.currentBreakdown.housing,
        greaterThan(base.currentBreakdown.housing),
      );
      expect(
        adjusted.currentBreakdown.total,
        greaterThan(base.currentBreakdown.total),
      );
    });
  });
}

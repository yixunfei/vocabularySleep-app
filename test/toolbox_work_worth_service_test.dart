import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_work_worth_service.dart';

void main() {
  group('toolbox work worth service', () {
    test('computes working days, disposable income, and positive score', () {
      final result = ToolboxWorkWorthService().calculate(
        const WorkWorthInput(
          monthlySalary: 20000,
          salaryMonths: 13,
          annualBonus: 0,
          monthlyTax: 1200,
          monthlyInsuranceFund: 3500,
          monthlyHousingCost: 4500,
          monthlyLivingCost: 4500,
          workDaysPerWeek: 5,
          workFromHomeDaysPerWeek: 0,
          annualLeaveDays: 5,
          publicHolidayDays: 13,
          paidSickLeaveDays: 3,
          workHoursPerDay: 10,
          commuteHoursPerDay: 2,
          restHoursPerDay: 2,
          pppFactor: ToolboxWorkWorthService.chinaPppFactor,
          cityFactor: 1,
          environment: WorkWorthEnvironment.normal,
          leadershipFactor: 1,
          teamworkFactor: 1,
          jobStability: WorkWorthJobStability.privateCompany,
          education: WorkWorthEducation.bachelor,
          workYears: 0,
          hasShuttle: false,
          shuttleFactor: 1,
          hasCanteen: false,
          canteenFactor: 1,
        ),
      );

      expect(result.workingDaysPerYear, closeTo(240.2, 0.01));
      expect(result.monthlyDisposableIncome, closeTo(7100, 0.01));
      expect(result.valueScore, greaterThan(0));
    });

    test('penalizes unhealthy environment and high living cost', () {
      const base = WorkWorthInput(
        monthlySalary: 30000,
        salaryMonths: 13,
        annualBonus: 0,
        monthlyTax: 2000,
        monthlyInsuranceFund: 5000,
        monthlyHousingCost: 3000,
        monthlyLivingCost: 4000,
        workDaysPerWeek: 5,
        workFromHomeDaysPerWeek: 2,
        annualLeaveDays: 10,
        publicHolidayDays: 13,
        paidSickLeaveDays: 3,
        workHoursPerDay: 8,
        commuteHoursPerDay: 1,
        restHoursPerDay: 2,
        pppFactor: ToolboxWorkWorthService.chinaPppFactor,
        cityFactor: 1,
        environment: WorkWorthEnvironment.freeComfort,
        leadershipFactor: 1.1,
        teamworkFactor: 1.1,
        jobStability: WorkWorthJobStability.privateCompany,
        education: WorkWorthEducation.bachelor,
        workYears: 3,
        hasShuttle: false,
        shuttleFactor: 1,
        hasCanteen: true,
        canteenFactor: 1.1,
      );
      final service = ToolboxWorkWorthService();
      final comfortable = service.calculate(base);
      final unhealthy = service.calculate(
        const WorkWorthInput(
          monthlySalary: 30000,
          salaryMonths: 13,
          annualBonus: 0,
          monthlyTax: 2000,
          monthlyInsuranceFund: 5000,
          monthlyHousingCost: 9000,
          monthlyLivingCost: 9000,
          workDaysPerWeek: 5,
          workFromHomeDaysPerWeek: 0,
          annualLeaveDays: 10,
          publicHolidayDays: 13,
          paidSickLeaveDays: 3,
          workHoursPerDay: 11,
          commuteHoursPerDay: 2,
          restHoursPerDay: 1,
          pppFactor: ToolboxWorkWorthService.chinaPppFactor,
          cityFactor: 0.8,
          environment: WorkWorthEnvironment.lifeTrade,
          leadershipFactor: 0.8,
          teamworkFactor: 0.9,
          jobStability: WorkWorthJobStability.privateCompany,
          education: WorkWorthEducation.bachelor,
          workYears: 3,
          hasShuttle: false,
          shuttleFactor: 1,
          hasCanteen: false,
          canteenFactor: 1,
        ),
      );

      expect(
        unhealthy.monthlyHealthReserve,
        greaterThan(comfortable.monthlyHealthReserve),
      );
      expect(unhealthy.valueScore, lessThan(comfortable.valueScore));
    });

    test(
      'applies bonus certainty, benefits, overtime, and context factors',
      () {
        const baseline = WorkWorthInput(
          monthlySalary: 22000,
          salaryMonths: 12,
          annualBonus: 60000,
          monthlyTax: 1500,
          monthlyInsuranceFund: 4000,
          monthlyHousingCost: 5000,
          monthlyLivingCost: 4500,
          workDaysPerWeek: 5,
          workFromHomeDaysPerWeek: 1,
          annualLeaveDays: 8,
          publicHolidayDays: 13,
          paidSickLeaveDays: 3,
          workHoursPerDay: 9,
          commuteHoursPerDay: 1.5,
          restHoursPerDay: 2,
          pppFactor: ToolboxWorkWorthService.chinaPppFactor,
          cityFactor: 1,
          environment: WorkWorthEnvironment.normal,
          leadershipFactor: 1,
          teamworkFactor: 1,
          jobStability: WorkWorthJobStability.privateCompany,
          education: WorkWorthEducation.bachelor,
          workYears: 2,
          hasShuttle: false,
          shuttleFactor: 1,
          hasCanteen: false,
          canteenFactor: 1,
        );
        final service = ToolboxWorkWorthService();
        final weakContext = service.calculate(
          const WorkWorthInput(
            monthlySalary: 22000,
            salaryMonths: 12,
            annualBonus: 60000,
            monthlyTax: 1500,
            monthlyInsuranceFund: 4000,
            monthlyHousingCost: 5000,
            monthlyLivingCost: 4500,
            workDaysPerWeek: 5,
            workFromHomeDaysPerWeek: 1,
            annualLeaveDays: 8,
            publicHolidayDays: 13,
            paidSickLeaveDays: 3,
            workHoursPerDay: 9,
            commuteHoursPerDay: 1.5,
            restHoursPerDay: 2,
            pppFactor: ToolboxWorkWorthService.chinaPppFactor,
            cityFactor: 1,
            environment: WorkWorthEnvironment.normal,
            leadershipFactor: 1,
            teamworkFactor: 1,
            jobStability: WorkWorthJobStability.privateCompany,
            education: WorkWorthEducation.bachelor,
            workYears: 2,
            hasShuttle: false,
            shuttleFactor: 1,
            hasCanteen: false,
            canteenFactor: 1,
            annualBonusCertainty: 0.5,
            unpaidOvertimeHoursPerMonth: 30,
            boundaryFactor: 0.8,
            psychologicalSafetyFactor: 0.9,
          ),
        );
        final strongContext = service.calculate(
          const WorkWorthInput(
            monthlySalary: 22000,
            salaryMonths: 12,
            annualBonus: 60000,
            monthlyBenefitValue: 1500,
            monthlyOvertimePay: 2000,
            monthlyTax: 1500,
            monthlyInsuranceFund: 4000,
            monthlyHousingCost: 5000,
            monthlyLivingCost: 4500,
            workDaysPerWeek: 5,
            workFromHomeDaysPerWeek: 1,
            annualLeaveDays: 8,
            publicHolidayDays: 13,
            paidSickLeaveDays: 3,
            workHoursPerDay: 9,
            commuteHoursPerDay: 1.5,
            restHoursPerDay: 2,
            pppFactor: ToolboxWorkWorthService.chinaPppFactor,
            cityFactor: 1,
            environment: WorkWorthEnvironment.normal,
            leadershipFactor: 1,
            teamworkFactor: 1,
            jobStability: WorkWorthJobStability.privateCompany,
            education: WorkWorthEducation.bachelor,
            workYears: 2,
            hasShuttle: false,
            shuttleFactor: 1,
            hasCanteen: false,
            canteenFactor: 1,
            annualBonusCertainty: 1,
            growthFactor: 1.2,
            boundaryFactor: 1.1,
            psychologicalSafetyFactor: 1.1,
            autonomyFactor: 1.1,
          ),
        );

        expect(weakContext.expectedAnnualBonus, 30000);
        expect(strongContext.annualBenefitValue, 18000);
        expect(strongContext.annualOvertimePay, 24000);
        expect(weakContext.effectiveUnpaidOvertimeHours, greaterThan(0));
        expect(strongContext.valueScore, greaterThan(weakContext.valueScore));
        expect(service.calculate(baseline).valueScore, greaterThan(0));
      },
    );
  });
}

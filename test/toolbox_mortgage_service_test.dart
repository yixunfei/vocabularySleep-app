import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_mortgage_service.dart';

void main() {
  group('toolbox mortgage service', () {
    const service = ToolboxMortgageService();

    test('computes equal installment contract totals', () {
      final result = service.calculate(
        MortgageInput(
          repaymentMethod: MortgageRepaymentMethod.equalInstallment,
          calculationMode: MortgageCalculationMode.loanAmount,
          termYears: 30,
          annualRatePercent: 3.6,
          firstPaymentDate: DateTime(2026, 6),
          loanAmountYuan: 1000000,
        ),
      );

      expect(result.totalMonths, 360);
      expect(result.firstMonthlyPayment, closeTo(4546.45, 0.01));
      expect(result.lastMonthlyPayment, closeTo(4546.45, 0.02));
      expect(result.contractTotalInterest, closeTo(636723.26, 0.1));
      expect(result.remainingPrincipal, closeTo(1000000, 0.01));
    });

    test('computes equal principal declining payments', () {
      final result = service.calculate(
        MortgageInput(
          repaymentMethod: MortgageRepaymentMethod.equalPrincipal,
          calculationMode: MortgageCalculationMode.loanAmount,
          termYears: 30,
          annualRatePercent: 3.6,
          firstPaymentDate: DateTime(2026, 6),
          loanAmountYuan: 1000000,
        ),
      );

      expect(result.firstMonthlyPayment, closeTo(5777.78, 0.01));
      expect(result.lastMonthlyPayment, closeTo(2786.11, 0.01));
      expect(result.contractTotalInterest, closeTo(541500, 0.1));
      expect(
        result.contractSchedule[1].payment,
        lessThan(result.contractSchedule.first.payment),
      );
    });

    test('derives loan from housing area and down payment ratio', () {
      final result = service.calculate(
        MortgageInput(
          repaymentMethod: MortgageRepaymentMethod.equalInstallment,
          calculationMode: MortgageCalculationMode.housingArea,
          termYears: 20,
          annualRatePercent: 4.1,
          firstPaymentDate: DateTime(2026, 6),
          houseAreaSqm: 100,
          unitPriceYuanPerSqm: 30000,
          downPaymentRatio: 0.3,
          monthlyFeeYuan: 50,
          oneTimeFeeYuan: 20000,
        ),
      );

      expect(result.propertyTotal, 3000000);
      expect(result.downPayment, 900000);
      expect(result.principal, 2100000);
      expect(result.contractTotalFees, 32000);
      expect(result.contractSchedule.first.fee, 50);
    });

    test('estimates remaining balance and shortened term after prepayment', () {
      final baseline = service.calculate(
        MortgageInput(
          repaymentMethod: MortgageRepaymentMethod.equalInstallment,
          calculationMode: MortgageCalculationMode.loanAmount,
          termYears: 30,
          annualRatePercent: 3.6,
          firstPaymentDate: DateTime(2026, 6),
          loanAmountYuan: 1000000,
          paidMonths: 60,
        ),
      );
      final prepaid = service.calculate(
        MortgageInput(
          repaymentMethod: MortgageRepaymentMethod.equalInstallment,
          calculationMode: MortgageCalculationMode.loanAmount,
          termYears: 30,
          annualRatePercent: 3.6,
          firstPaymentDate: DateTime(2026, 6),
          loanAmountYuan: 1000000,
          paidMonths: 60,
          extraPrincipalPaidYuan: 100000,
          extraPaymentStrategy: MortgageExtraPaymentStrategy.shortenTerm,
        ),
      );

      expect(
        prepaid.remainingPrincipal,
        closeTo(baseline.remainingPrincipal - 100000, 0.01),
      );
      expect(prepaid.remainingMonths, lessThan(baseline.remainingMonths));
      expect(prepaid.nextPaymentDate, DateTime(2031, 6));
    });
  });
}

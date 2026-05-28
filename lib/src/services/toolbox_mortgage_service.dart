import 'dart:math' as math;

enum MortgageRepaymentMethod { equalInstallment, equalPrincipal }

enum MortgageCalculationMode { loanAmount, housingArea }

enum MortgageExtraPaymentStrategy { reduceMonthlyPayment, shortenTerm }

class MortgageInput {
  const MortgageInput({
    required this.repaymentMethod,
    required this.calculationMode,
    required this.termYears,
    required this.annualRatePercent,
    required this.firstPaymentDate,
    this.loanAmountYuan = 0,
    this.houseAreaSqm = 0,
    this.unitPriceYuanPerSqm = 0,
    this.downPaymentRatio = 0.3,
    this.downPaymentAmountYuan,
    this.paidMonths = 0,
    this.extraPrincipalPaidYuan = 0,
    this.extraPaymentStrategy =
        MortgageExtraPaymentStrategy.reduceMonthlyPayment,
    this.monthlyFeeYuan = 0,
    this.oneTimeFeeYuan = 0,
  });

  final MortgageRepaymentMethod repaymentMethod;
  final MortgageCalculationMode calculationMode;
  final int termYears;
  final double annualRatePercent;
  final DateTime firstPaymentDate;
  final double loanAmountYuan;
  final double houseAreaSqm;
  final double unitPriceYuanPerSqm;
  final double downPaymentRatio;
  final double? downPaymentAmountYuan;
  final int paidMonths;
  final double extraPrincipalPaidYuan;
  final MortgageExtraPaymentStrategy extraPaymentStrategy;
  final double monthlyFeeYuan;
  final double oneTimeFeeYuan;
}

class MortgagePayment {
  const MortgagePayment({
    required this.period,
    required this.dueDate,
    required this.payment,
    required this.principal,
    required this.interest,
    required this.fee,
    required this.remainingPrincipal,
  });

  final int period;
  final DateTime dueDate;
  final double payment;
  final double principal;
  final double interest;
  final double fee;
  final double remainingPrincipal;

  double get totalCashOut => payment + fee;
}

class MortgageResult {
  const MortgageResult({
    required this.input,
    required this.principal,
    required this.propertyTotal,
    required this.downPayment,
    required this.totalMonths,
    required this.paidMonths,
    required this.extraPrincipalApplied,
    required this.remainingMonths,
    required this.contractTotalPayment,
    required this.contractTotalInterest,
    required this.contractTotalFees,
    required this.contractTotalCost,
    required this.paidPrincipal,
    required this.paidInterest,
    required this.paidFees,
    required this.remainingPrincipalBeforeExtra,
    required this.remainingPrincipal,
    required this.remainingInterest,
    required this.remainingFees,
    required this.remainingTotalCost,
    required this.firstMonthlyPayment,
    required this.lastMonthlyPayment,
    required this.averageMonthlyPayment,
    required this.nextPaymentDate,
    required this.finalPaymentDate,
    required this.contractSchedule,
    required this.remainingSchedule,
  });

  final MortgageInput input;
  final double principal;
  final double propertyTotal;
  final double downPayment;
  final int totalMonths;
  final int paidMonths;
  final double extraPrincipalApplied;
  final int remainingMonths;
  final double contractTotalPayment;
  final double contractTotalInterest;
  final double contractTotalFees;
  final double contractTotalCost;
  final double paidPrincipal;
  final double paidInterest;
  final double paidFees;
  final double remainingPrincipalBeforeExtra;
  final double remainingPrincipal;
  final double remainingInterest;
  final double remainingFees;
  final double remainingTotalCost;
  final double firstMonthlyPayment;
  final double lastMonthlyPayment;
  final double averageMonthlyPayment;
  final DateTime? nextPaymentDate;
  final DateTime? finalPaymentDate;
  final List<MortgagePayment> contractSchedule;
  final List<MortgagePayment> remainingSchedule;
}

class ToolboxMortgageService {
  const ToolboxMortgageService();

  MortgageResult calculate(MortgageInput input) {
    final totalMonths = input.termYears * 12;
    if (totalMonths <= 0) {
      throw ArgumentError.value(input.termYears, 'termYears');
    }
    if (input.annualRatePercent < 0) {
      throw ArgumentError.value(input.annualRatePercent, 'annualRatePercent');
    }
    if (input.monthlyFeeYuan < 0 || input.oneTimeFeeYuan < 0) {
      throw ArgumentError('Fees cannot be negative.');
    }

    final propertyTotal = _propertyTotal(input);
    final downPayment = _downPayment(input, propertyTotal);
    final principal = _principal(input, propertyTotal, downPayment);
    if (principal <= 0) {
      throw ArgumentError.value(principal, 'principal');
    }

    final contractSchedule = _buildSchedule(
      method: input.repaymentMethod,
      principal: principal,
      annualRatePercent: input.annualRatePercent,
      months: totalMonths,
      firstPaymentDate: input.firstPaymentDate,
      monthlyFeeYuan: input.monthlyFeeYuan,
      periodOffset: 0,
    );
    final paidMonths = input.paidMonths.clamp(0, totalMonths).toInt();
    final paidSchedule = contractSchedule.take(paidMonths).toList();
    final remainingBeforeExtra = paidMonths == 0
        ? principal
        : contractSchedule[paidMonths - 1].remainingPrincipal;
    final extraPrincipalApplied = input.extraPrincipalPaidYuan
        .clamp(0, remainingBeforeExtra)
        .toDouble();
    final remainingPrincipal = math.max(
      0.0,
      remainingBeforeExtra - extraPrincipalApplied,
    );
    final remainingRegularMonths = totalMonths - paidMonths;
    final nextDueDate = _addMonths(input.firstPaymentDate, paidMonths);
    final remainingSchedule =
        remainingPrincipal <= 0 || remainingRegularMonths <= 0
        ? <MortgagePayment>[]
        : _buildRemainingSchedule(
            input: input,
            originalPrincipal: principal,
            remainingPrincipal: remainingPrincipal,
            remainingRegularMonths: remainingRegularMonths,
            firstPaymentDate: nextDueDate,
            periodOffset: paidMonths,
            originalMonthlyPayment: contractSchedule.first.payment,
          );

    final contractTotalPayment = _sum(
      contractSchedule.map((payment) => payment.payment),
    );
    final contractTotalInterest = _sum(
      contractSchedule.map((payment) => payment.interest),
    );
    final paidInterest = _sum(paidSchedule.map((payment) => payment.interest));
    final remainingInterest = _sum(
      remainingSchedule.map((payment) => payment.interest),
    );
    final remainingFees = input.monthlyFeeYuan * remainingSchedule.length;
    final paidRegularPrincipal = principal - remainingBeforeExtra;

    return MortgageResult(
      input: input,
      principal: principal,
      propertyTotal: propertyTotal,
      downPayment: downPayment,
      totalMonths: totalMonths,
      paidMonths: paidMonths,
      extraPrincipalApplied: extraPrincipalApplied,
      remainingMonths: remainingSchedule.length,
      contractTotalPayment: contractTotalPayment,
      contractTotalInterest: contractTotalInterest,
      contractTotalFees:
          input.oneTimeFeeYuan + input.monthlyFeeYuan * totalMonths,
      contractTotalCost:
          contractTotalPayment +
          input.oneTimeFeeYuan +
          input.monthlyFeeYuan * totalMonths,
      paidPrincipal: paidRegularPrincipal + extraPrincipalApplied,
      paidInterest: paidInterest,
      paidFees: input.oneTimeFeeYuan + input.monthlyFeeYuan * paidMonths,
      remainingPrincipalBeforeExtra: remainingBeforeExtra,
      remainingPrincipal: remainingPrincipal,
      remainingInterest: remainingInterest,
      remainingFees: remainingFees,
      remainingTotalCost:
          remainingPrincipal + remainingInterest + remainingFees,
      firstMonthlyPayment: contractSchedule.first.payment,
      lastMonthlyPayment: contractSchedule.last.payment,
      averageMonthlyPayment: contractTotalPayment / totalMonths,
      nextPaymentDate: remainingSchedule.isEmpty
          ? null
          : remainingSchedule.first.dueDate,
      finalPaymentDate: remainingSchedule.isEmpty
          ? null
          : remainingSchedule.last.dueDate,
      contractSchedule: List<MortgagePayment>.unmodifiable(contractSchedule),
      remainingSchedule: List<MortgagePayment>.unmodifiable(remainingSchedule),
    );
  }

  List<MortgagePayment> _buildRemainingSchedule({
    required MortgageInput input,
    required double originalPrincipal,
    required double remainingPrincipal,
    required int remainingRegularMonths,
    required DateTime firstPaymentDate,
    required int periodOffset,
    required double originalMonthlyPayment,
  }) {
    if (input.extraPaymentStrategy ==
        MortgageExtraPaymentStrategy.reduceMonthlyPayment) {
      return _buildSchedule(
        method: input.repaymentMethod,
        principal: remainingPrincipal,
        annualRatePercent: input.annualRatePercent,
        months: remainingRegularMonths,
        firstPaymentDate: firstPaymentDate,
        monthlyFeeYuan: input.monthlyFeeYuan,
        periodOffset: periodOffset,
      );
    }

    return _buildShortenTermSchedule(
      method: input.repaymentMethod,
      originalPrincipal: originalPrincipal,
      remainingPrincipal: remainingPrincipal,
      annualRatePercent: input.annualRatePercent,
      originalMonths: input.termYears * 12,
      firstPaymentDate: firstPaymentDate,
      monthlyFeeYuan: input.monthlyFeeYuan,
      periodOffset: periodOffset,
      originalMonthlyPayment: originalMonthlyPayment,
    );
  }

  List<MortgagePayment> _buildSchedule({
    required MortgageRepaymentMethod method,
    required double principal,
    required double annualRatePercent,
    required int months,
    required DateTime firstPaymentDate,
    required double monthlyFeeYuan,
    required int periodOffset,
  }) {
    final monthlyRate = annualRatePercent / 100 / 12;
    var remaining = principal;
    final payments = <MortgagePayment>[];
    final fixedPayment = _equalInstallmentPayment(
      principal: principal,
      monthlyRate: monthlyRate,
      months: months,
    );
    final equalPrincipalPart = principal / months;

    for (var index = 0; index < months; index += 1) {
      final interest = remaining * monthlyRate;
      final plannedPrincipal = switch (method) {
        MortgageRepaymentMethod.equalInstallment =>
          monthlyRate == 0 ? fixedPayment : fixedPayment - interest,
        MortgageRepaymentMethod.equalPrincipal => equalPrincipalPart,
      };
      final principalPayment = math.min(remaining, plannedPrincipal);
      final payment = principalPayment + interest;
      remaining = math.max(0, remaining - principalPayment);
      payments.add(
        MortgagePayment(
          period: periodOffset + index + 1,
          dueDate: _addMonths(firstPaymentDate, index),
          payment: payment,
          principal: principalPayment,
          interest: interest,
          fee: monthlyFeeYuan,
          remainingPrincipal: remaining,
        ),
      );
    }
    return payments;
  }

  List<MortgagePayment> _buildShortenTermSchedule({
    required MortgageRepaymentMethod method,
    required double originalPrincipal,
    required double remainingPrincipal,
    required double annualRatePercent,
    required int originalMonths,
    required DateTime firstPaymentDate,
    required double monthlyFeeYuan,
    required int periodOffset,
    required double originalMonthlyPayment,
  }) {
    final monthlyRate = annualRatePercent / 100 / 12;
    final equalPrincipalPart = originalPrincipal / originalMonths;
    var remaining = remainingPrincipal;
    var index = 0;
    final payments = <MortgagePayment>[];
    while (remaining > 0.005 && index < originalMonths + 1200) {
      final interest = remaining * monthlyRate;
      final plannedPrincipal = switch (method) {
        MortgageRepaymentMethod.equalInstallment =>
          monthlyRate == 0
              ? originalMonthlyPayment
              : originalMonthlyPayment - interest,
        MortgageRepaymentMethod.equalPrincipal => equalPrincipalPart,
      };
      if (plannedPrincipal <= 0) {
        throw StateError('Monthly payment cannot cover interest.');
      }
      final principalPayment = math.min(remaining, plannedPrincipal);
      final payment = principalPayment + interest;
      remaining = math.max(0, remaining - principalPayment);
      payments.add(
        MortgagePayment(
          period: periodOffset + index + 1,
          dueDate: _addMonths(firstPaymentDate, index),
          payment: payment,
          principal: principalPayment,
          interest: interest,
          fee: monthlyFeeYuan,
          remainingPrincipal: remaining,
        ),
      );
      index += 1;
    }
    return payments;
  }

  double _equalInstallmentPayment({
    required double principal,
    required double monthlyRate,
    required int months,
  }) {
    if (monthlyRate == 0) {
      return principal / months;
    }
    final factor = math.pow(1 + monthlyRate, months).toDouble();
    return principal * monthlyRate * factor / (factor - 1);
  }

  double _propertyTotal(MortgageInput input) {
    if (input.calculationMode == MortgageCalculationMode.housingArea) {
      if (input.houseAreaSqm <= 0 || input.unitPriceYuanPerSqm <= 0) {
        throw ArgumentError('House area and unit price must be positive.');
      }
      return input.houseAreaSqm * input.unitPriceYuanPerSqm;
    }
    if (input.houseAreaSqm > 0 && input.unitPriceYuanPerSqm > 0) {
      return input.houseAreaSqm * input.unitPriceYuanPerSqm;
    }
    final downPayment = math.max(0, input.downPaymentAmountYuan ?? 0);
    return input.loanAmountYuan + downPayment;
  }

  double _downPayment(MortgageInput input, double propertyTotal) {
    if (input.downPaymentAmountYuan != null) {
      return input.downPaymentAmountYuan!.clamp(0, propertyTotal).toDouble();
    }
    if (input.calculationMode == MortgageCalculationMode.housingArea) {
      return propertyTotal * input.downPaymentRatio.clamp(0, 0.95);
    }
    return 0;
  }

  double _principal(
    MortgageInput input,
    double propertyTotal,
    double downPayment,
  ) {
    if (input.calculationMode == MortgageCalculationMode.loanAmount) {
      return input.loanAmountYuan;
    }
    return math.max(0, propertyTotal - downPayment);
  }

  static DateTime _addMonths(DateTime date, int months) {
    final monthIndex = date.month - 1 + months;
    final year = date.year + monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final day = math.min(date.day, DateTime(year, month + 1, 0).day);
    return DateTime(
      year,
      month,
      day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  static double _sum(Iterable<double> values) {
    return values.fold<double>(0, (total, value) => total + value);
  }
}

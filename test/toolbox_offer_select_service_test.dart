import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_offer_select_service.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_work_worth_service.dart';

void main() {
  group('toolbox offer select service', () {
    test('ranks active offers and excludes rejected options from leader', () {
      final service = ToolboxOfferSelectService();
      final candidates = <OfferSelectCandidate>[
        ...ToolboxOfferSelectService.defaultCandidates,
        ToolboxOfferSelectService.defaultCandidates.first.copyWith(
          id: 'rejected_high_pay',
          company: 'Rejected High Pay',
          monthlyBase: 60000,
          rejected: true,
        ),
      ];

      final result = service.compare(
        profile: ToolboxOfferSelectService.defaultProfile,
        candidates: candidates,
      );

      expect(result.activeEvaluations.length, 2);
      expect(result.rejectedEvaluations.length, 1);
      expect(result.leader?.candidate.company, isNot('Rejected High Pay'));
      expect(result.evaluations.first.candidate.rejected, isFalse);
    });

    test('weights can flip between high cash and healthier offer', () {
      final service = ToolboxOfferSelectService();
      final highCash = ToolboxOfferSelectService.defaultCandidates.first
          .copyWith(
            id: 'cash',
            company: 'Cash Heavy',
            monthlyBase: 42000,
            salaryMonths: 15,
            monthlyTax: 5600,
            monthlyInsuranceFund: 6200,
            monthlyHousingCost: 8500,
            monthlyLivingCost: 6500,
            workHoursPerDay: 12,
            commuteHoursPerDay: 2.4,
            workFromHomeDaysPerWeek: 0,
            wlbRating: 1.5,
            environment: WorkWorthEnvironment.harmful,
            boundaryFactor: 0.75,
            psychologicalSafetyFactor: 0.8,
          );
      final healthy = ToolboxOfferSelectService.defaultCandidates.last.copyWith(
        id: 'healthy',
        company: 'Healthy Growth',
        monthlyBase: 24000,
        workHoursPerDay: 8,
        commuteHoursPerDay: 0.5,
        wlbRating: 4.8,
        environment: WorkWorthEnvironment.freeComfort,
        boundaryFactor: 1.15,
        psychologicalSafetyFactor: 1.15,
        autonomyFactor: 1.12,
      );

      final cashResult = service.compare(
        profile: ToolboxOfferSelectService.defaultProfile,
        candidates: <OfferSelectCandidate>[highCash, healthy],
        weights: const OfferSelectWeights(
          cashflow: 4,
          time: 0.2,
          health: 0.2,
          growth: 0.2,
          stability: 0.2,
          cityFit: 0.2,
        ),
      );
      final healthResult = service.compare(
        profile: ToolboxOfferSelectService.defaultProfile,
        candidates: <OfferSelectCandidate>[highCash, healthy],
        weights: const OfferSelectWeights(
          cashflow: 0.4,
          time: 1.6,
          health: 2.4,
          growth: 1.0,
          stability: 0.4,
          cityFit: 0.4,
        ),
      );

      expect(cashResult.leader?.candidate.company, 'Cash Heavy');
      expect(healthResult.leader?.candidate.company, 'Healthy Growth');
    });

    test('calculates monthly raise needed to match the leading offer', () {
      final service = ToolboxOfferSelectService();
      final leader = ToolboxOfferSelectService.defaultCandidates.first.copyWith(
        id: 'leader',
        company: 'Leader',
        monthlyBase: 30000,
      );
      final runner = leader.copyWith(
        id: 'runner',
        company: 'Runner',
        monthlyBase: 25000,
      );
      final result = service.compare(
        profile: ToolboxOfferSelectService.defaultProfile,
        candidates: <OfferSelectCandidate>[leader, runner],
      );

      final runnerUp = result.runnerUp;
      expect(runnerUp, isNotNull);
      expect(runnerUp!.monthlyBaseRaiseToLeader, isNotNull);
      expect(runnerUp.monthlyBaseRaiseToLeader, greaterThanOrEqualTo(0));
    });

    test('adds risk flags for harsh schedule and weak cashflow', () {
      final service = ToolboxOfferSelectService();
      final harsh = ToolboxOfferSelectService.defaultCandidates.first.copyWith(
        id: 'harsh',
        company: 'Harsh Offer',
        monthlyBase: 16000,
        monthlyTax: 1800,
        monthlyInsuranceFund: 3500,
        monthlyHousingCost: 9000,
        monthlyLivingCost: 7000,
        workHoursPerDay: 12.5,
        commuteHoursPerDay: 3,
        workFromHomeDaysPerWeek: 0,
        environment: WorkWorthEnvironment.lifeTrade,
        bonusCertainty: 0.4,
      );

      final result = service.compare(
        profile: ToolboxOfferSelectService.defaultProfile,
        candidates: <OfferSelectCandidate>[harsh],
      );
      final titles = result.leader!.flags.map((flag) => flag.titleEn).toList();

      expect(titles, contains('Negative cashflow'));
      expect(titles, contains('High time cost'));
      expect(titles, contains('High health load'));
      expect(titles, contains('Variable pay risk'));
    });
  });
}

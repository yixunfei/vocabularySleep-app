import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_decision_content.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_decision_engine.dart';

void main() {
  DailyChoiceDecisionOptionInput option({
    required String id,
    required String name,
    required double successProbability,
    required double executionProbability,
    required double upside,
    required double downside,
    required double effort,
    required double reversibility,
    required double confidence,
    required double regret,
    required double infoGap,
  }) {
    return DailyChoiceDecisionOptionInput(
      id: id,
      name: name,
      successProbability: successProbability,
      executionProbability: executionProbability,
      upside: upside,
      downside: downside,
      effort: effort,
      reversibility: reversibility,
      confidence: confidence,
      regret: regret,
      infoGap: infoGap,
    );
  }

  test('decision guide hides source and roadmap copy', () {
    final guideText = decisionGuideModules
        .expand(
          (module) => <String>[
            module.id,
            module.titleZh,
            module.titleEn,
            module.subtitleZh,
            module.subtitleEn,
            ...module.entries.expand(
              (entry) => <String>[
                entry.titleZh,
                entry.titleEn,
                entry.bodyZh,
                entry.bodyEn,
              ],
            ),
          ],
        )
        .join('\n');

    for (final forbidden in <String>[
      'sources',
      '资料来源',
      'Sources',
      '本地决策参考',
      'This guide distills',
      '第一版',
      '后续',
    ]) {
      expect(guideText, isNot(contains(forbidden)));
    }
  });

  test('recommended methods adapt to high-stakes uncertain context', () {
    const context = DailyChoiceDecisionContext(
      stakes: DailyChoiceDecisionLevel.high,
      uncertainty: DailyChoiceDecisionLevel.high,
      reversibility: DailyChoiceDecisionReversibility.hard,
      urgency: DailyChoiceDecisionUrgency.canWait,
    );

    final methods = DailyChoiceDecisionEngine.recommendedMethodsFor(context);

    expect(methods, contains(DailyChoiceDecisionMethod.thresholdGuardrail));
    expect(methods, contains(DailyChoiceDecisionMethod.scenarioBlend));
    expect(methods, contains(DailyChoiceDecisionMethod.calibratedForecast));
    expect(methods, contains(DailyChoiceDecisionMethod.jointProbability));
  });

  test(
    'threshold guardrails prefer the safe option when upside is too risky',
    () {
      final report = DailyChoiceDecisionEngine.buildReport(
        context: const DailyChoiceDecisionContext(
          stakes: DailyChoiceDecisionLevel.high,
          uncertainty: DailyChoiceDecisionLevel.medium,
          reversibility: DailyChoiceDecisionReversibility.hard,
          urgency: DailyChoiceDecisionUrgency.soon,
        ),
        activeMethod: DailyChoiceDecisionMethod.thresholdGuardrail,
        options: <DailyChoiceDecisionOptionInput>[
          option(
            id: 'risky',
            name: 'Risky',
            successProbability: 0.75,
            executionProbability: 0.80,
            upside: 9.5,
            downside: 8.8,
            effort: 6.5,
            reversibility: 2.0,
            confidence: 0.42,
            regret: 7.0,
            infoGap: 6.5,
          ),
          option(
            id: 'safe',
            name: 'Safe',
            successProbability: 0.66,
            executionProbability: 0.78,
            upside: 7.0,
            downside: 3.2,
            effort: 4.0,
            reversibility: 6.2,
            confidence: 0.74,
            regret: 4.2,
            infoGap: 2.5,
          ),
        ],
      );

      final result = report.resultFor(
        DailyChoiceDecisionMethod.thresholdGuardrail,
      );

      expect(result.winner?.option.id, 'safe');
      expect(
        result.ranked
            .firstWhere((item) => item.option.id == 'risky')
            .passesGuardrails,
        isFalse,
      );
    },
  );

  test(
    'calibrated forecast shrinks low-confidence extremes toward the mean',
    () {
      final report = DailyChoiceDecisionEngine.buildReport(
        context: const DailyChoiceDecisionContext(
          stakes: DailyChoiceDecisionLevel.medium,
          uncertainty: DailyChoiceDecisionLevel.high,
          reversibility: DailyChoiceDecisionReversibility.mixed,
          urgency: DailyChoiceDecisionUrgency.soon,
        ),
        activeMethod: DailyChoiceDecisionMethod.calibratedForecast,
        options: <DailyChoiceDecisionOptionInput>[
          option(
            id: 'swing',
            name: 'Swing',
            successProbability: 0.95,
            executionProbability: 0.95,
            upside: 10,
            downside: 1,
            effort: 2,
            reversibility: 5,
            confidence: 0.20,
            regret: 3,
            infoGap: 7,
          ),
          option(
            id: 'steady',
            name: 'Steady',
            successProbability: 0.68,
            executionProbability: 0.80,
            upside: 7,
            downside: 3,
            effort: 4,
            reversibility: 7,
            confidence: 0.85,
            regret: 4,
            infoGap: 2,
          ),
        ],
      );

      final expected = report.resultFor(
        DailyChoiceDecisionMethod.expectedValue,
      );
      final calibrated = report.resultFor(
        DailyChoiceDecisionMethod.calibratedForecast,
      );
      final averageExpected =
          expected.ranked.map((item) => item.score).reduce((a, b) => a + b) /
          expected.ranked.length;
      final swingExpected = expected.ranked
          .firstWhere((item) => item.option.id == 'swing')
          .score;
      final swingCalibrated = calibrated.ranked
          .firstWhere((item) => item.option.id == 'swing')
          .score;

      expect(
        (swingCalibrated - averageExpected).abs(),
        lessThan((swingExpected - averageExpected).abs()),
      );
    },
  );

  test(
    'information signal recommends delaying when uncertainty and info gap are high',
    () {
      final report = DailyChoiceDecisionEngine.buildReport(
        context: const DailyChoiceDecisionContext(
          stakes: DailyChoiceDecisionLevel.high,
          uncertainty: DailyChoiceDecisionLevel.high,
          reversibility: DailyChoiceDecisionReversibility.mixed,
          urgency: DailyChoiceDecisionUrgency.canWait,
        ),
        activeMethod: DailyChoiceDecisionMethod.scenarioBlend,
        options: <DailyChoiceDecisionOptionInput>[
          option(
            id: 'need_research',
            name: 'Need research',
            successProbability: 0.60,
            executionProbability: 0.62,
            upside: 9.0,
            downside: 6.8,
            effort: 5.5,
            reversibility: 4.5,
            confidence: 0.25,
            regret: 7.2,
            infoGap: 9.0,
          ),
          option(
            id: 'known',
            name: 'Known quantity',
            successProbability: 0.58,
            executionProbability: 0.76,
            upside: 7.2,
            downside: 3.5,
            effort: 4.2,
            reversibility: 6.0,
            confidence: 0.72,
            regret: 4.3,
            infoGap: 2.0,
          ),
        ],
      );

      expect(report.infoSignal.shouldGatherMoreInfo, isTrue);
      expect(report.infoSignal.shouldDelayDecision, isTrue);
      expect(report.infoSignal.highlightOptionId, 'need_research');
    },
  );
}

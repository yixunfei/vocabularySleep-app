import 'dart:math' as math;

enum DailyChoiceDecisionMethod {
  random,
  weightedFactors,
  expectedValue,
  jointProbability,
  scenarioBlend,
  regretBalance,
  thresholdGuardrail,
  calibratedForecast,
}

enum DailyChoiceDecisionLevel { low, medium, high }

enum DailyChoiceDecisionReversibility { easy, mixed, hard }

enum DailyChoiceDecisionUrgency { now, soon, canWait }

enum DailyChoiceDecisionGuardrailType {
  confidence,
  downside,
  reversibility,
  infoGap,
}

class DailyChoiceDecisionContext {
  const DailyChoiceDecisionContext({
    this.stakes = DailyChoiceDecisionLevel.medium,
    this.uncertainty = DailyChoiceDecisionLevel.medium,
    this.reversibility = DailyChoiceDecisionReversibility.mixed,
    this.urgency = DailyChoiceDecisionUrgency.soon,
  });

  final DailyChoiceDecisionLevel stakes;
  final DailyChoiceDecisionLevel uncertainty;
  final DailyChoiceDecisionReversibility reversibility;
  final DailyChoiceDecisionUrgency urgency;

  DailyChoiceDecisionContext copyWith({
    DailyChoiceDecisionLevel? stakes,
    DailyChoiceDecisionLevel? uncertainty,
    DailyChoiceDecisionReversibility? reversibility,
    DailyChoiceDecisionUrgency? urgency,
  }) {
    return DailyChoiceDecisionContext(
      stakes: stakes ?? this.stakes,
      uncertainty: uncertainty ?? this.uncertainty,
      reversibility: reversibility ?? this.reversibility,
      urgency: urgency ?? this.urgency,
    );
  }
}

class DailyChoiceDecisionOptionInput {
  const DailyChoiceDecisionOptionInput({
    required this.id,
    required this.name,
    required this.successProbability,
    required this.executionProbability,
    required this.upside,
    required this.downside,
    required this.effort,
    required this.reversibility,
    required this.confidence,
    required this.regret,
    required this.infoGap,
  });

  final String id;
  final String name;
  final double successProbability;
  final double executionProbability;
  final double upside;
  final double downside;
  final double effort;
  final double reversibility;
  final double confidence;
  final double regret;
  final double infoGap;

  DailyChoiceDecisionOptionInput copyWith({
    String? id,
    String? name,
    double? successProbability,
    double? executionProbability,
    double? upside,
    double? downside,
    double? effort,
    double? reversibility,
    double? confidence,
    double? regret,
    double? infoGap,
  }) {
    return DailyChoiceDecisionOptionInput(
      id: id ?? this.id,
      name: name ?? this.name,
      successProbability: successProbability ?? this.successProbability,
      executionProbability: executionProbability ?? this.executionProbability,
      upside: upside ?? this.upside,
      downside: downside ?? this.downside,
      effort: effort ?? this.effort,
      reversibility: reversibility ?? this.reversibility,
      confidence: confidence ?? this.confidence,
      regret: regret ?? this.regret,
      infoGap: infoGap ?? this.infoGap,
    );
  }
}

class DailyChoiceDecisionGuardrailSettings {
  const DailyChoiceDecisionGuardrailSettings({
    required this.minConfidence,
    required this.maxDownside,
    required this.minReversibility,
    required this.maxInfoGap,
  });

  final double minConfidence;
  final double maxDownside;
  final double minReversibility;
  final double maxInfoGap;
}

class DailyChoiceDecisionScore {
  const DailyChoiceDecisionScore({
    required this.option,
    required this.score,
    this.metrics = const <String, double>{},
    this.failedGuardrails = const <DailyChoiceDecisionGuardrailType>[],
  });

  final DailyChoiceDecisionOptionInput option;
  final double score;
  final Map<String, double> metrics;
  final List<DailyChoiceDecisionGuardrailType> failedGuardrails;

  bool get passesGuardrails => failedGuardrails.isEmpty;
}

class DailyChoiceDecisionMethodResult {
  const DailyChoiceDecisionMethodResult({
    required this.method,
    required this.ranked,
  });

  final DailyChoiceDecisionMethod method;
  final List<DailyChoiceDecisionScore> ranked;

  DailyChoiceDecisionScore? get winner => ranked.isEmpty ? null : ranked.first;

  DailyChoiceDecisionScore? get runnerUp {
    if (ranked.length < 2) {
      return null;
    }
    return ranked[1];
  }

  double get leadMargin {
    final winner = this.winner;
    final runnerUp = this.runnerUp;
    if (winner == null || runnerUp == null) {
      return 0;
    }
    return winner.score - runnerUp.score;
  }
}

class DailyChoiceDecisionConsensus {
  const DailyChoiceDecisionConsensus({
    required this.winnerId,
    required this.winnerName,
    required this.supportCount,
    required this.methodCount,
    required this.methods,
  });

  final String winnerId;
  final String winnerName;
  final int supportCount;
  final int methodCount;
  final List<DailyChoiceDecisionMethod> methods;

  double get stability =>
      methodCount == 0 ? 0 : supportCount / methodCount.toDouble();
}

class DailyChoiceDecisionInfoSignal {
  const DailyChoiceDecisionInfoSignal({
    required this.shouldGatherMoreInfo,
    required this.shouldDelayDecision,
    required this.impactScore,
    this.highlightOptionId,
  });

  final bool shouldGatherMoreInfo;
  final bool shouldDelayDecision;
  final double impactScore;
  final String? highlightOptionId;
}

class DailyChoiceDecisionReport {
  const DailyChoiceDecisionReport({
    required this.context,
    required this.options,
    required this.activeMethod,
    required this.results,
    required this.recommendedMethods,
    required this.guardrails,
    required this.consensus,
    required this.infoSignal,
  });

  final DailyChoiceDecisionContext context;
  final List<DailyChoiceDecisionOptionInput> options;
  final DailyChoiceDecisionMethod activeMethod;
  final Map<DailyChoiceDecisionMethod, DailyChoiceDecisionMethodResult> results;
  final List<DailyChoiceDecisionMethod> recommendedMethods;
  final DailyChoiceDecisionGuardrailSettings guardrails;
  final DailyChoiceDecisionConsensus consensus;
  final DailyChoiceDecisionInfoSignal infoSignal;

  DailyChoiceDecisionMethodResult resultFor(DailyChoiceDecisionMethod method) {
    return results[method]!;
  }
}

class DailyChoiceDecisionEngine {
  static DailyChoiceDecisionReport buildReport({
    required DailyChoiceDecisionContext context,
    required List<DailyChoiceDecisionOptionInput> options,
    required DailyChoiceDecisionMethod activeMethod,
  }) {
    final normalized = options.map(_normalizeOption).toList(growable: false);
    final guardrails = _guardrailsFor(context);
    final weighted = _buildWeightedResult(context, normalized);
    final expected = _buildExpectedValueResult(normalized);
    final joint = _buildJointProbabilityResult(normalized);
    final scenario = _buildScenarioBlendResult(context, normalized);
    final regret = _buildRegretBalanceResult(normalized);
    final threshold = _buildThresholdResult(
      normalized,
      weightedResult: weighted,
      guardrails: guardrails,
    );
    final calibrated = _buildCalibratedForecastResult(
      context,
      expectedResult: expected,
    );
    final random = _buildRandomResult(normalized);
    final results =
        <DailyChoiceDecisionMethod, DailyChoiceDecisionMethodResult>{
          DailyChoiceDecisionMethod.random: random,
          DailyChoiceDecisionMethod.weightedFactors: weighted,
          DailyChoiceDecisionMethod.expectedValue: expected,
          DailyChoiceDecisionMethod.jointProbability: joint,
          DailyChoiceDecisionMethod.scenarioBlend: scenario,
          DailyChoiceDecisionMethod.regretBalance: regret,
          DailyChoiceDecisionMethod.thresholdGuardrail: threshold,
          DailyChoiceDecisionMethod.calibratedForecast: calibrated,
        };
    final recommendedMethods = recommendedMethodsFor(context);
    final consensus = _buildConsensus(results);
    final infoSignal = _buildInfoSignal(
      context,
      normalized,
      guardrails: guardrails,
      thresholdResult: threshold,
    );
    return DailyChoiceDecisionReport(
      context: context,
      options: normalized,
      activeMethod: activeMethod,
      results: results,
      recommendedMethods: recommendedMethods,
      guardrails: guardrails,
      consensus: consensus,
      infoSignal: infoSignal,
    );
  }

  static List<DailyChoiceDecisionMethod> recommendedMethodsFor(
    DailyChoiceDecisionContext context,
  ) {
    final ordered = <DailyChoiceDecisionMethod>[];

    void add(DailyChoiceDecisionMethod method) {
      if (!ordered.contains(method)) {
        ordered.add(method);
      }
    }

    add(DailyChoiceDecisionMethod.weightedFactors);
    add(DailyChoiceDecisionMethod.expectedValue);

    if (context.stakes == DailyChoiceDecisionLevel.low &&
        context.reversibility == DailyChoiceDecisionReversibility.easy) {
      add(DailyChoiceDecisionMethod.random);
    }

    if (context.uncertainty != DailyChoiceDecisionLevel.low) {
      add(DailyChoiceDecisionMethod.scenarioBlend);
      add(DailyChoiceDecisionMethod.calibratedForecast);
    }

    if (context.reversibility == DailyChoiceDecisionReversibility.hard ||
        context.stakes == DailyChoiceDecisionLevel.high) {
      add(DailyChoiceDecisionMethod.thresholdGuardrail);
      add(DailyChoiceDecisionMethod.regretBalance);
    }

    if (context.uncertainty == DailyChoiceDecisionLevel.high) {
      add(DailyChoiceDecisionMethod.jointProbability);
    }

    if (context.urgency == DailyChoiceDecisionUrgency.now) {
      add(DailyChoiceDecisionMethod.thresholdGuardrail);
    }

    return ordered;
  }

  static DailyChoiceDecisionOptionInput _normalizeOption(
    DailyChoiceDecisionOptionInput option,
  ) {
    return option.copyWith(
      successProbability: _clampUnit(option.successProbability),
      executionProbability: _clampUnit(option.executionProbability),
      upside: _clampScore(option.upside),
      downside: _clampScore(option.downside),
      effort: _clampScore(option.effort),
      reversibility: _clampScore(option.reversibility),
      confidence: _clampUnit(option.confidence),
      regret: _clampScore(option.regret),
      infoGap: _clampScore(option.infoGap),
    );
  }

  static DailyChoiceDecisionGuardrailSettings _guardrailsFor(
    DailyChoiceDecisionContext context,
  ) {
    final minConfidence = switch (context.stakes) {
      DailyChoiceDecisionLevel.low => 0.35,
      DailyChoiceDecisionLevel.medium => 0.50,
      DailyChoiceDecisionLevel.high => 0.65,
    };
    final maxDownside = switch (context.stakes) {
      DailyChoiceDecisionLevel.low => 8.0,
      DailyChoiceDecisionLevel.medium => 6.5,
      DailyChoiceDecisionLevel.high => 5.0,
    };
    final minReversibility = switch (context.reversibility) {
      DailyChoiceDecisionReversibility.easy => 2.0,
      DailyChoiceDecisionReversibility.mixed => 3.5,
      DailyChoiceDecisionReversibility.hard => 5.0,
    };
    final maxInfoGap = switch ((context.stakes, context.urgency)) {
      (DailyChoiceDecisionLevel.high, DailyChoiceDecisionUrgency.now) => 3.0,
      (DailyChoiceDecisionLevel.high, _) => 4.5,
      (DailyChoiceDecisionLevel.medium, DailyChoiceDecisionUrgency.now) => 4.0,
      (DailyChoiceDecisionLevel.medium, _) => 6.0,
      (DailyChoiceDecisionLevel.low, DailyChoiceDecisionUrgency.now) => 5.0,
      (DailyChoiceDecisionLevel.low, _) => 7.0,
    };
    return DailyChoiceDecisionGuardrailSettings(
      minConfidence: minConfidence,
      maxDownside: maxDownside,
      minReversibility: minReversibility,
      maxInfoGap: maxInfoGap,
    );
  }

  static DailyChoiceDecisionMethodResult _buildRandomResult(
    List<DailyChoiceDecisionOptionInput> options,
  ) {
    final score = options.isEmpty ? 0.0 : 1 / options.length.toDouble();
    return DailyChoiceDecisionMethodResult(
      method: DailyChoiceDecisionMethod.random,
      ranked: options
          .map(
            (option) => DailyChoiceDecisionScore(
              option: option,
              score: score,
              metrics: <String, double>{'uniformProbability': score},
            ),
          )
          .toList(growable: false),
    );
  }

  static DailyChoiceDecisionMethodResult _buildWeightedResult(
    DailyChoiceDecisionContext context,
    List<DailyChoiceDecisionOptionInput> options,
  ) {
    final downsideWeight = switch (context.stakes) {
      DailyChoiceDecisionLevel.low => 0.10,
      DailyChoiceDecisionLevel.medium => 0.14,
      DailyChoiceDecisionLevel.high => 0.18,
    };
    final infoWeight = switch (context.uncertainty) {
      DailyChoiceDecisionLevel.low => 0.04,
      DailyChoiceDecisionLevel.medium => 0.08,
      DailyChoiceDecisionLevel.high => 0.12,
    };
    final reversibilityWeight = switch (context.reversibility) {
      DailyChoiceDecisionReversibility.easy => 0.10,
      DailyChoiceDecisionReversibility.mixed => 0.14,
      DailyChoiceDecisionReversibility.hard => 0.18,
    };
    final ranked = options
        .map((option) {
          final successBlend =
              option.successProbability * 0.55 +
              option.executionProbability * 0.45;
          final score =
              option.upside * 0.28 +
              successBlend * 10 * 0.18 +
              option.confidence * 10 * 0.14 +
              option.reversibility * reversibilityWeight -
              option.downside * downsideWeight -
              option.effort * 0.08 -
              option.regret * 0.06 -
              option.infoGap * infoWeight;
          return DailyChoiceDecisionScore(
            option: option,
            score: score,
            metrics: <String, double>{
              'successBlend': successBlend,
              'positivePull':
                  option.upside * 0.28 +
                  successBlend * 10 * 0.18 +
                  option.confidence * 10 * 0.14 +
                  option.reversibility * reversibilityWeight,
              'negativePull':
                  option.downside * downsideWeight +
                  option.effort * 0.08 +
                  option.regret * 0.06 +
                  option.infoGap * infoWeight,
            },
          );
        })
        .toList(growable: false);
    _sortScores(ranked);
    return DailyChoiceDecisionMethodResult(
      method: DailyChoiceDecisionMethod.weightedFactors,
      ranked: ranked,
    );
  }

  static DailyChoiceDecisionMethodResult _buildExpectedValueResult(
    List<DailyChoiceDecisionOptionInput> options,
  ) {
    final ranked = options
        .map((option) {
          final successProbability =
              option.successProbability * option.executionProbability;
          final expectedGain = successProbability * option.upside;
          final expectedLoss = (1 - successProbability) * option.downside;
          final effortPenalty = option.effort * 0.20;
          final score = expectedGain - expectedLoss - effortPenalty;
          return DailyChoiceDecisionScore(
            option: option,
            score: score,
            metrics: <String, double>{
              'effectiveSuccess': successProbability,
              'expectedGain': expectedGain,
              'expectedLoss': expectedLoss,
              'effortPenalty': effortPenalty,
            },
          );
        })
        .toList(growable: false);
    _sortScores(ranked);
    return DailyChoiceDecisionMethodResult(
      method: DailyChoiceDecisionMethod.expectedValue,
      ranked: ranked,
    );
  }

  static DailyChoiceDecisionMethodResult _buildJointProbabilityResult(
    List<DailyChoiceDecisionOptionInput> options,
  ) {
    final ranked = options
        .map((option) {
          final jointProbability =
              option.successProbability *
              option.executionProbability *
              option.confidence;
          final downsideExposure = (1 - jointProbability) * option.downside;
          final score =
              jointProbability * option.upside -
              downsideExposure -
              option.effort * 0.10;
          return DailyChoiceDecisionScore(
            option: option,
            score: score,
            metrics: <String, double>{
              'jointProbability': jointProbability,
              'downsideExposure': downsideExposure,
            },
          );
        })
        .toList(growable: false);
    _sortScores(ranked);
    return DailyChoiceDecisionMethodResult(
      method: DailyChoiceDecisionMethod.jointProbability,
      ranked: ranked,
    );
  }

  static DailyChoiceDecisionMethodResult _buildScenarioBlendResult(
    DailyChoiceDecisionContext context,
    List<DailyChoiceDecisionOptionInput> options,
  ) {
    final (
      optimisticWeight,
      baselineWeight,
      pessimisticWeight,
    ) = switch (context.uncertainty) {
      DailyChoiceDecisionLevel.low => (0.20, 0.65, 0.15),
      DailyChoiceDecisionLevel.medium => (0.25, 0.50, 0.25),
      DailyChoiceDecisionLevel.high => (0.20, 0.35, 0.45),
    };
    final ranked = options
        .map((option) {
          final effectiveSuccess =
              option.successProbability * option.executionProbability;
          final optimistic =
              option.upside +
              option.reversibility * 0.25 -
              option.effort * 0.10;
          final baseline =
              effectiveSuccess * option.upside -
              (1 - effectiveSuccess) * option.downside -
              option.effort * 0.15;
          final pessimistic =
              -option.downside -
              option.effort * 0.25 +
              option.reversibility * 0.05;
          final score =
              optimistic * optimisticWeight +
              baseline * baselineWeight +
              pessimistic * pessimisticWeight;
          return DailyChoiceDecisionScore(
            option: option,
            score: score,
            metrics: <String, double>{
              'optimistic': optimistic,
              'baseline': baseline,
              'pessimistic': pessimistic,
            },
          );
        })
        .toList(growable: false);
    _sortScores(ranked);
    return DailyChoiceDecisionMethodResult(
      method: DailyChoiceDecisionMethod.scenarioBlend,
      ranked: ranked,
    );
  }

  static DailyChoiceDecisionMethodResult _buildRegretBalanceResult(
    List<DailyChoiceDecisionOptionInput> options,
  ) {
    final bestPotential = options.fold<double>(
      0,
      (best, option) => math.max(
        best,
        option.upside * option.successProbability * option.executionProbability,
      ),
    );
    final ranked = options
        .map((option) {
          final realizedPotential =
              option.upside *
              option.successProbability *
              option.executionProbability;
          final missPenalty =
              option.regret *
              (1 - option.successProbability * option.executionProbability);
          final opportunityCost = math.max(
            0.0,
            bestPotential - realizedPotential,
          );
          final score =
              realizedPotential +
              option.reversibility * 0.35 -
              missPenalty -
              opportunityCost * 0.45 -
              option.downside * 0.20;
          return DailyChoiceDecisionScore(
            option: option,
            score: score,
            metrics: <String, double>{
              'realizedPotential': realizedPotential,
              'missPenalty': missPenalty,
              'opportunityCost': opportunityCost,
            },
          );
        })
        .toList(growable: false);
    _sortScores(ranked);
    return DailyChoiceDecisionMethodResult(
      method: DailyChoiceDecisionMethod.regretBalance,
      ranked: ranked,
    );
  }

  static DailyChoiceDecisionMethodResult _buildThresholdResult(
    List<DailyChoiceDecisionOptionInput> options, {
    required DailyChoiceDecisionMethodResult weightedResult,
    required DailyChoiceDecisionGuardrailSettings guardrails,
  }) {
    final weightedById = <String, DailyChoiceDecisionScore>{
      for (final score in weightedResult.ranked) score.option.id: score,
    };
    final ranked = options
        .map((option) {
          final failures = <DailyChoiceDecisionGuardrailType>[
            if (option.confidence < guardrails.minConfidence)
              DailyChoiceDecisionGuardrailType.confidence,
            if (option.downside > guardrails.maxDownside)
              DailyChoiceDecisionGuardrailType.downside,
            if (option.reversibility < guardrails.minReversibility)
              DailyChoiceDecisionGuardrailType.reversibility,
            if (option.infoGap > guardrails.maxInfoGap)
              DailyChoiceDecisionGuardrailType.infoGap,
          ];
          final weightedScore = weightedById[option.id]?.score ?? 0;
          final passCount = 4 - failures.length;
          final score = failures.isEmpty
              ? 100 + weightedScore
              : -40 + passCount * 6 + weightedScore * 0.10;
          return DailyChoiceDecisionScore(
            option: option,
            score: score,
            metrics: <String, double>{
              'passCount': passCount.toDouble(),
              'weightedFallback': weightedScore,
            },
            failedGuardrails: failures,
          );
        })
        .toList(growable: false);
    _sortScores(ranked);
    return DailyChoiceDecisionMethodResult(
      method: DailyChoiceDecisionMethod.thresholdGuardrail,
      ranked: ranked,
    );
  }

  static DailyChoiceDecisionMethodResult _buildCalibratedForecastResult(
    DailyChoiceDecisionContext context, {
    required DailyChoiceDecisionMethodResult expectedResult,
  }) {
    final averageExpected = expectedResult.ranked.isEmpty
        ? 0.0
        : expectedResult.ranked
                  .map((item) => item.score)
                  .reduce((a, b) => a + b) /
              expectedResult.ranked.length;
    final uncertaintyMultiplier = switch (context.uncertainty) {
      DailyChoiceDecisionLevel.low => 1.0,
      DailyChoiceDecisionLevel.medium => 0.8,
      DailyChoiceDecisionLevel.high => 0.6,
    };
    final ranked = expectedResult.ranked
        .map((score) {
          final shrinkStrength =
              score.option.confidence * uncertaintyMultiplier;
          final calibrated =
              averageExpected +
              shrinkStrength * (score.score - averageExpected);
          return DailyChoiceDecisionScore(
            option: score.option,
            score: calibrated,
            metrics: <String, double>{
              'rawExpected': score.score,
              'averageExpected': averageExpected,
              'shrinkStrength': shrinkStrength,
            },
          );
        })
        .toList(growable: false);
    _sortScores(ranked);
    return DailyChoiceDecisionMethodResult(
      method: DailyChoiceDecisionMethod.calibratedForecast,
      ranked: ranked,
    );
  }

  static DailyChoiceDecisionConsensus _buildConsensus(
    Map<DailyChoiceDecisionMethod, DailyChoiceDecisionMethodResult> results,
  ) {
    final tally = <String, int>{};
    final winnersById = <String, List<DailyChoiceDecisionMethod>>{};
    final methods = <DailyChoiceDecisionMethod>[
      DailyChoiceDecisionMethod.weightedFactors,
      DailyChoiceDecisionMethod.expectedValue,
      DailyChoiceDecisionMethod.jointProbability,
      DailyChoiceDecisionMethod.scenarioBlend,
      DailyChoiceDecisionMethod.regretBalance,
      DailyChoiceDecisionMethod.thresholdGuardrail,
      DailyChoiceDecisionMethod.calibratedForecast,
    ];
    for (final method in methods) {
      final winner = results[method]?.winner;
      if (winner == null) {
        continue;
      }
      tally.update(winner.option.id, (value) => value + 1, ifAbsent: () => 1);
      winnersById.putIfAbsent(
        winner.option.id,
        () => <DailyChoiceDecisionMethod>[],
      );
      winnersById[winner.option.id]!.add(method);
    }
    if (tally.isEmpty) {
      return const DailyChoiceDecisionConsensus(
        winnerId: '',
        winnerName: '',
        supportCount: 0,
        methodCount: 0,
        methods: <DailyChoiceDecisionMethod>[],
      );
    }
    final bestId = tally.entries
        .reduce((best, next) => next.value > best.value ? next : best)
        .key;
    final sampleResult =
        results[DailyChoiceDecisionMethod.weightedFactors] ??
        results.values.first;
    final winnerName = sampleResult.ranked
        .firstWhere(
          (item) => item.option.id == bestId,
          orElse: () => sampleResult.ranked.first,
        )
        .option
        .name;
    return DailyChoiceDecisionConsensus(
      winnerId: bestId,
      winnerName: winnerName,
      supportCount: tally[bestId] ?? 0,
      methodCount: methods.length,
      methods: winnersById[bestId] ?? const <DailyChoiceDecisionMethod>[],
    );
  }

  static DailyChoiceDecisionInfoSignal _buildInfoSignal(
    DailyChoiceDecisionContext context,
    List<DailyChoiceDecisionOptionInput> options, {
    required DailyChoiceDecisionGuardrailSettings guardrails,
    required DailyChoiceDecisionMethodResult thresholdResult,
  }) {
    var bestImpact = 0.0;
    String? highlightOptionId;
    for (final option in options) {
      final impact =
          option.infoGap *
          ((option.upside + option.downside) / 20) *
          (1 - option.confidence) *
          switch (context.uncertainty) {
            DailyChoiceDecisionLevel.low => 0.9,
            DailyChoiceDecisionLevel.medium => 1.1,
            DailyChoiceDecisionLevel.high => 1.3,
          };
      if (impact > bestImpact) {
        bestImpact = impact;
        highlightOptionId = option.id;
      }
    }
    final passCount = thresholdResult.ranked
        .where((item) => item.passesGuardrails)
        .length;
    final threshold = switch ((context.stakes, context.urgency)) {
      (DailyChoiceDecisionLevel.high, DailyChoiceDecisionUrgency.canWait) =>
        1.4,
      (DailyChoiceDecisionLevel.high, _) => 2.0,
      (DailyChoiceDecisionLevel.medium, DailyChoiceDecisionUrgency.canWait) =>
        1.8,
      (DailyChoiceDecisionLevel.medium, _) => 2.4,
      (DailyChoiceDecisionLevel.low, DailyChoiceDecisionUrgency.canWait) => 2.8,
      (DailyChoiceDecisionLevel.low, _) => 3.2,
    };
    final shouldGatherMoreInfo =
        bestImpact >= threshold ||
        passCount == 0 && bestImpact >= threshold * 0.75;
    final shouldDelayDecision =
        shouldGatherMoreInfo &&
        context.urgency != DailyChoiceDecisionUrgency.now;
    return DailyChoiceDecisionInfoSignal(
      shouldGatherMoreInfo: shouldGatherMoreInfo,
      shouldDelayDecision: shouldDelayDecision,
      impactScore: bestImpact,
      highlightOptionId: highlightOptionId,
    );
  }

  static void _sortScores(List<DailyChoiceDecisionScore> scores) {
    scores.sort((a, b) => b.score.compareTo(a.score));
  }

  static double _clampUnit(double value) => value.clamp(0.0, 1.0).toDouble();

  static double _clampScore(double value) => value.clamp(0.0, 10.0).toDouble();
}

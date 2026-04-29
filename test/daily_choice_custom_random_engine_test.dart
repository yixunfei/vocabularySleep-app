import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_custom_random_engine.dart';

void main() {
  DailyChoiceCustomRandomOption option(
    String id, {
    double weight = 1,
    double conditionProbability = 1,
  }) {
    return DailyChoiceCustomRandomOption(
      id: id,
      label: id,
      weight: weight,
      conditionProbability: conditionProbability,
    );
  }

  test('weighted probabilities follow positive weights', () {
    final probabilities = DailyChoiceCustomRandomEngine.probabilitiesFor(
      options: <DailyChoiceCustomRandomOption>[
        option('heavy', weight: 3),
        option('light', weight: 1),
      ],
      mode: DailyChoiceCustomRandomMode.weighted,
    );

    expect(probabilities['heavy'], closeTo(0.75, 0.0001));
    expect(probabilities['light'], closeTo(0.25, 0.0001));
  });

  test('joint distribution multiplies weight by condition probability', () {
    final probabilities = DailyChoiceCustomRandomEngine.probabilitiesFor(
      options: <DailyChoiceCustomRandomOption>[
        option('ready', weight: 2, conditionProbability: 0.5),
        option('fragile', weight: 1, conditionProbability: 0.25),
      ],
      mode: DailyChoiceCustomRandomMode.jointDistribution,
    );

    expect(probabilities['ready'], closeTo(0.8, 0.0001));
    expect(probabilities['fragile'], closeTo(0.2, 0.0001));
  });

  test(
    'dice layout clamps dice count and keeps every die within 3 to 12 faces',
    () {
      final layout = DailyChoiceDiceLayout.forOptions(
        optionCount: 25,
        preferredDiceCount: 2,
      );

      expect(layout.valid, isTrue);
      expect(layout.diceCount, 3);
      expect(layout.facesPerDie, <int>[9, 8, 8]);
      expect(layout.capacity, 25);
    },
  );

  test('dice draw remains uniform and records die face location', () {
    final options = List<DailyChoiceCustomRandomOption>.generate(
      13,
      (index) => option('option_$index'),
    );

    final result = DailyChoiceCustomRandomEngine.draw(
      options: options,
      mode: DailyChoiceCustomRandomMode.uniform,
      animation: DailyChoiceCustomRandomAnimation.dice,
      diceCount: 1,
      random: math.Random(7),
    );

    expect(result.diceLayout?.diceCount, 2);
    expect(result.diceIndex, isNotNull);
    expect(result.diceFaceIndex, isNotNull);
    expect(result.probabilityFor(result.winner.id), closeTo(1 / 13, 0.0001));
  });

  test('coin animation requires exactly two options and records all flips', () {
    final twoSided = <DailyChoiceCustomRandomOption>[
      option('heads'),
      option('tails'),
    ];

    final result = DailyChoiceCustomRandomEngine.draw(
      options: twoSided,
      mode: DailyChoiceCustomRandomMode.uniform,
      animation: DailyChoiceCustomRandomAnimation.coin,
      coinCount: 5,
      random: math.Random(3),
    );

    expect(result.coinFlips, hasLength(5));
    expect(twoSided.map((item) => item.id), contains(result.winner.id));

    expect(
      () => DailyChoiceCustomRandomEngine.draw(
        options: <DailyChoiceCustomRandomOption>[
          option('a'),
          option('b'),
          option('c'),
        ],
        mode: DailyChoiceCustomRandomMode.uniform,
        animation: DailyChoiceCustomRandomAnimation.coin,
      ),
      throwsStateError,
    );
  });
}

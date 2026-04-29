import 'dart:math' as math;

enum DailyChoiceCustomRandomMode { uniform, weighted, jointDistribution }

enum DailyChoiceCustomRandomAnimation { wheel, dice, coin }

class DailyChoiceCustomRandomOption {
  const DailyChoiceCustomRandomOption({
    required this.id,
    required this.label,
    this.weight = 1,
    this.conditionProbability = 1,
  });

  final String id;
  final String label;
  final double weight;
  final double conditionProbability;

  double get normalizedWeight => math.max(0, weight);

  double get normalizedConditionProbability =>
      conditionProbability.clamp(0.0, 1.0).toDouble();
}

class DailyChoiceDiceLayout {
  const DailyChoiceDiceLayout({
    required this.optionCount,
    required this.diceCount,
    required this.facesPerDie,
    required this.valid,
  });

  final int optionCount;
  final int diceCount;
  final List<int> facesPerDie;
  final bool valid;

  int get capacity => facesPerDie.fold<int>(0, (sum, faces) => sum + faces);

  static DailyChoiceDiceLayout forOptions({
    required int optionCount,
    required int preferredDiceCount,
  }) {
    if (optionCount < 3) {
      return DailyChoiceDiceLayout(
        optionCount: optionCount,
        diceCount: 0,
        facesPerDie: const <int>[],
        valid: false,
      );
    }
    final minDiceCount = (optionCount / 12).ceil().clamp(1, optionCount);
    final maxDiceCount = (optionCount / 3).floor().clamp(1, optionCount);
    final diceCount = preferredDiceCount.clamp(minDiceCount, maxDiceCount);
    final baseFaces = optionCount ~/ diceCount;
    final extraFaces = optionCount % diceCount;
    final faces = List<int>.generate(
      diceCount,
      (index) => baseFaces + (index < extraFaces ? 1 : 0),
      growable: false,
    );
    return DailyChoiceDiceLayout(
      optionCount: optionCount,
      diceCount: diceCount,
      facesPerDie: faces,
      valid: faces.every((faceCount) => faceCount >= 3 && faceCount <= 12),
    );
  }
}

class DailyChoiceCoinFlip {
  const DailyChoiceCoinFlip({required this.index, required this.option});

  final int index;
  final DailyChoiceCustomRandomOption option;
}

class DailyChoiceCustomRandomResult {
  const DailyChoiceCustomRandomResult({
    required this.mode,
    required this.animation,
    required this.winner,
    required this.probabilitiesById,
    required this.roundPicks,
    this.diceLayout,
    this.diceIndex,
    this.diceFaceIndex,
    this.coinFlips = const <DailyChoiceCoinFlip>[],
  });

  final DailyChoiceCustomRandomMode mode;
  final DailyChoiceCustomRandomAnimation animation;
  final DailyChoiceCustomRandomOption winner;
  final Map<String, double> probabilitiesById;
  final List<DailyChoiceCustomRandomOption> roundPicks;
  final DailyChoiceDiceLayout? diceLayout;
  final int? diceIndex;
  final int? diceFaceIndex;
  final List<DailyChoiceCoinFlip> coinFlips;

  double probabilityFor(String optionId) => probabilitiesById[optionId] ?? 0;
}

class DailyChoiceCustomRandomEngine {
  const DailyChoiceCustomRandomEngine._();

  static DailyChoiceCustomRandomResult draw({
    required List<DailyChoiceCustomRandomOption> options,
    required DailyChoiceCustomRandomMode mode,
    required DailyChoiceCustomRandomAnimation animation,
    math.Random? random,
    int rounds = 1,
    int diceCount = 1,
    int coinCount = 1,
  }) {
    if (options.isEmpty) {
      throw ArgumentError.value(options, 'options', 'Options cannot be empty.');
    }
    final picker = random ?? math.Random();
    final probabilities = probabilitiesFor(options: options, mode: mode);
    if (animation == DailyChoiceCustomRandomAnimation.coin) {
      return _drawCoin(
        options: options,
        mode: mode,
        probabilities: probabilities,
        random: picker,
        coinCount: coinCount,
      );
    }
    if (animation == DailyChoiceCustomRandomAnimation.dice) {
      return _drawDice(
        options: options,
        mode: mode,
        probabilities: probabilities,
        random: picker,
        diceCount: diceCount,
      );
    }
    final normalizedRounds =
        mode == DailyChoiceCustomRandomMode.jointDistribution
        ? rounds.clamp(2, 24)
        : 1;
    final picks = List<DailyChoiceCustomRandomOption>.generate(
      normalizedRounds,
      (_) => _pickWeighted(options, probabilities, picker),
      growable: false,
    );
    final winner = _winnerFromRounds(picks, probabilities);
    return DailyChoiceCustomRandomResult(
      mode: mode,
      animation: animation,
      winner: winner,
      probabilitiesById: probabilities,
      roundPicks: picks,
    );
  }

  static Map<String, double> probabilitiesFor({
    required List<DailyChoiceCustomRandomOption> options,
    required DailyChoiceCustomRandomMode mode,
  }) {
    if (options.isEmpty) {
      return const <String, double>{};
    }
    final masses = <String, double>{
      for (final option in options) option.id: _massFor(option, mode),
    };
    final total = masses.values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) {
      final uniform = 1 / options.length;
      return <String, double>{for (final option in options) option.id: uniform};
    }
    return masses.map((key, value) => MapEntry(key, value / total));
  }

  static double _massFor(
    DailyChoiceCustomRandomOption option,
    DailyChoiceCustomRandomMode mode,
  ) {
    return switch (mode) {
      DailyChoiceCustomRandomMode.uniform => 1,
      DailyChoiceCustomRandomMode.weighted => option.normalizedWeight,
      DailyChoiceCustomRandomMode.jointDistribution =>
        option.normalizedWeight * option.normalizedConditionProbability,
    };
  }

  static DailyChoiceCustomRandomResult _drawDice({
    required List<DailyChoiceCustomRandomOption> options,
    required DailyChoiceCustomRandomMode mode,
    required Map<String, double> probabilities,
    required math.Random random,
    required int diceCount,
  }) {
    final layout = DailyChoiceDiceLayout.forOptions(
      optionCount: options.length,
      preferredDiceCount: diceCount,
    );
    if (!layout.valid) {
      throw StateError('Dice animation needs at least 3 options.');
    }
    final optionIndex = random.nextInt(options.length);
    var remaining = optionIndex;
    var dieIndex = 0;
    for (; dieIndex < layout.facesPerDie.length; dieIndex += 1) {
      final faces = layout.facesPerDie[dieIndex];
      if (remaining < faces) {
        break;
      }
      remaining -= faces;
    }
    final winner = options[optionIndex];
    return DailyChoiceCustomRandomResult(
      mode: mode,
      animation: DailyChoiceCustomRandomAnimation.dice,
      winner: winner,
      probabilitiesById: probabilities,
      roundPicks: <DailyChoiceCustomRandomOption>[winner],
      diceLayout: layout,
      diceIndex: dieIndex,
      diceFaceIndex: remaining,
    );
  }

  static DailyChoiceCustomRandomResult _drawCoin({
    required List<DailyChoiceCustomRandomOption> options,
    required DailyChoiceCustomRandomMode mode,
    required Map<String, double> probabilities,
    required math.Random random,
    required int coinCount,
  }) {
    if (options.length != 2) {
      throw StateError('Coin animation needs exactly 2 options.');
    }
    final normalizedCoinCount = coinCount.clamp(1, 21);
    final flips = List<DailyChoiceCoinFlip>.generate(normalizedCoinCount, (
      index,
    ) {
      final optionIndex = random.nextBool() ? 1 : 0;
      return DailyChoiceCoinFlip(index: index, option: options[optionIndex]);
    }, growable: false);
    final firstCount = flips
        .where((flip) => flip.option.id == options[0].id)
        .length;
    final secondCount = flips.length - firstCount;
    final winner = firstCount == secondCount
        ? flips.last.option
        : (firstCount > secondCount ? options[0] : options[1]);
    return DailyChoiceCustomRandomResult(
      mode: mode,
      animation: DailyChoiceCustomRandomAnimation.coin,
      winner: winner,
      probabilitiesById: probabilities,
      roundPicks: flips.map((flip) => flip.option).toList(growable: false),
      coinFlips: flips,
    );
  }

  static DailyChoiceCustomRandomOption _pickWeighted(
    List<DailyChoiceCustomRandomOption> options,
    Map<String, double> probabilities,
    math.Random random,
  ) {
    var cursor = random.nextDouble();
    for (final option in options) {
      cursor -= probabilities[option.id] ?? 0;
      if (cursor <= 0) {
        return option;
      }
    }
    return options.last;
  }

  static DailyChoiceCustomRandomOption _winnerFromRounds(
    List<DailyChoiceCustomRandomOption> picks,
    Map<String, double> probabilities,
  ) {
    final tally = <String, int>{};
    for (final pick in picks) {
      tally.update(pick.id, (value) => value + 1, ifAbsent: () => 1);
    }
    return picks.reduce((best, next) {
      final bestCount = tally[best.id] ?? 0;
      final nextCount = tally[next.id] ?? 0;
      if (nextCount != bestCount) {
        return nextCount > bestCount ? next : best;
      }
      final bestProbability = probabilities[best.id] ?? 0;
      final nextProbability = probabilities[next.id] ?? 0;
      return nextProbability > bestProbability ? next : best;
    });
  }
}

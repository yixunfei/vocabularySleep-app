import 'dart:math' as math;

class MemoryResult {
  const MemoryResult({
    required this.easeFactor,
    required this.intervalDays,
    required this.nextReview,
    required this.memoryState,
    required this.familiarity,
    required this.consecutiveCorrect,
  });

  final double easeFactor;
  final int intervalDays;
  final String nextReview;
  final String memoryState;
  final double familiarity;
  final int consecutiveCorrect;
}

/// SM-2 spaced repetition algorithm.
///
/// Quality scale: 0-5 (0=complete blackout, 5=perfect recall).
/// Typical usage: correct → quality 4, incorrect → quality 1.
class MemoryAlgorithm {
  MemoryAlgorithm._();

  static MemoryResult sm2({
    required int quality,
    required double previousEaseFactor,
    required int previousInterval,
    required int consecutiveCorrect,
  }) {
    final q = quality.clamp(0, 5);
    var ef = previousEaseFactor;
    var interval = previousInterval;
    var streak = consecutiveCorrect;

    if (q >= 3) {
      // Correct response.
      streak += 1;
      if (streak == 1) {
        interval = 1;
      } else if (streak == 2) {
        interval = 6;
      } else {
        interval = (interval * ef).round();
      }
      ef = ef + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    } else {
      // Incorrect response — reset.
      streak = 0;
      interval = 1;
      ef = ef - 0.2;
    }

    ef = math.max(1.3, ef);
    interval = math.max(1, interval);

    final now = DateTime.now();
    final nextDate = now.add(Duration(days: interval));
    final nextReview = nextDate.toUtc().toIso8601String();

    final familiarity = _computeFamiliarity(streak, interval, ef);
    final memoryState = _computeState(streak, interval, familiarity);

    return MemoryResult(
      easeFactor: double.parse(ef.toStringAsFixed(2)),
      intervalDays: interval,
      nextReview: nextReview,
      memoryState: memoryState,
      familiarity: double.parse(familiarity.toStringAsFixed(3)),
      consecutiveCorrect: streak,
    );
  }

  static double _computeFamiliarity(int streak, int interval, double ef) {
    // Familiarity 0.0–1.0 based on streak and interval growth.
    if (streak == 0) return 0.0;
    final streakFactor = (streak / 8.0).clamp(0.0, 0.5);
    final intervalFactor = (interval / 60.0).clamp(0.0, 0.5);
    return (streakFactor + intervalFactor).clamp(0.0, 1.0);
  }

  static String _computeState(int streak, int interval, double familiarity) {
    if (streak == 0) return 'learning';
    if (familiarity >= 0.8 && interval >= 21) return 'mastered';
    if (familiarity >= 0.4 || interval >= 6) return 'familiar';
    return 'learning';
  }
}

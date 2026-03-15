import '../models/word_entry.dart';
import '../models/word_memory_progress.dart';

class MemoryLaneSelector {
  MemoryLaneSelector._();

  static List<WordEntry> selectStableEntries({
    required List<WordEntry> words,
    required Map<int, WordMemoryProgress> progressByWordId,
    DateTime? now,
  }) {
    if (words.isEmpty || progressByWordId.isEmpty) {
      return const <WordEntry>[];
    }
    final referenceTime = now ?? DateTime.now();
    final selected = words
        .where((entry) {
          final progress = _progressForEntry(entry, progressByWordId);
          return progress != null && _isStable(progress, referenceTime);
        })
        .toList(growable: false);
    final ordered = List<WordEntry>.from(selected);
    ordered.sort(
      (left, right) => _compareStableEntries(left, right, progressByWordId),
    );
    return ordered;
  }

  static List<WordEntry> selectRecoveryEntries({
    required List<WordEntry> words,
    required Map<int, WordMemoryProgress> progressByWordId,
    DateTime? now,
  }) {
    if (words.isEmpty || progressByWordId.isEmpty) {
      return const <WordEntry>[];
    }
    final referenceTime = now ?? DateTime.now();
    final selected = words
        .where((entry) {
          final progress = _progressForEntry(entry, progressByWordId);
          return progress != null && _isRecovery(progress, referenceTime);
        })
        .toList(growable: false);
    final ordered = List<WordEntry>.from(selected);
    ordered.sort(
      (left, right) =>
          _compareRecoveryEntries(left, right, progressByWordId, referenceTime),
    );
    return ordered;
  }

  static WordMemoryProgress? _progressForEntry(
    WordEntry entry,
    Map<int, WordMemoryProgress> progressByWordId,
  ) {
    final wordId = entry.id;
    if (wordId == null || wordId <= 0) {
      return null;
    }
    return progressByWordId[wordId];
  }

  static bool _isStable(WordMemoryProgress progress, DateTime now) {
    if (!progress.isTracked) {
      return false;
    }
    if (progress.timesCorrect <= 0 || progress.consecutiveCorrect <= 0) {
      return false;
    }
    final nextReview = progress.nextReview;
    if (nextReview == null) {
      return false;
    }
    return nextReview.isAfter(now);
  }

  static bool _isRecovery(WordMemoryProgress progress, DateTime now) {
    if (!progress.isTracked) {
      return false;
    }
    if (progress.timesCorrect <= 0) {
      return true;
    }
    if (progress.consecutiveCorrect <= 0) {
      return true;
    }
    final nextReview = progress.nextReview;
    if (nextReview == null) {
      return true;
    }
    return !nextReview.isAfter(now);
  }

  static int _compareStableEntries(
    WordEntry left,
    WordEntry right,
    Map<int, WordMemoryProgress> progressByWordId,
  ) {
    final leftProgress = progressByWordId[left.id]!;
    final rightProgress = progressByWordId[right.id]!;

    final reviewOrder = _compareNullableDate(
      leftProgress.nextReview,
      rightProgress.nextReview,
      nullsLast: true,
    );
    if (reviewOrder != 0) {
      return reviewOrder;
    }

    final familiarityOrder = rightProgress.familiarity.compareTo(
      leftProgress.familiarity,
    );
    if (familiarityOrder != 0) {
      return familiarityOrder;
    }

    final streakOrder = rightProgress.consecutiveCorrect.compareTo(
      leftProgress.consecutiveCorrect,
    );
    if (streakOrder != 0) {
      return streakOrder;
    }

    final lastPlayedOrder = _compareNullableDate(
      rightProgress.lastPlayed,
      leftProgress.lastPlayed,
      nullsLast: true,
    );
    if (lastPlayedOrder != 0) {
      return lastPlayedOrder;
    }

    return left.word.toLowerCase().compareTo(right.word.toLowerCase());
  }

  static int _compareRecoveryEntries(
    WordEntry left,
    WordEntry right,
    Map<int, WordMemoryProgress> progressByWordId,
    DateTime now,
  ) {
    final leftProgress = progressByWordId[left.id]!;
    final rightProgress = progressByWordId[right.id]!;

    final lanePriority = _recoveryPriority(
      leftProgress,
      now,
    ).compareTo(_recoveryPriority(rightProgress, now));
    if (lanePriority != 0) {
      return lanePriority;
    }

    final reviewOrder = _compareNullableDate(
      leftProgress.nextReview,
      rightProgress.nextReview,
      nullsLast: false,
    );
    if (reviewOrder != 0) {
      return reviewOrder;
    }

    final familiarityOrder = leftProgress.familiarity.compareTo(
      rightProgress.familiarity,
    );
    if (familiarityOrder != 0) {
      return familiarityOrder;
    }

    final lastPlayedOrder = _compareNullableDate(
      rightProgress.lastPlayed,
      leftProgress.lastPlayed,
      nullsLast: true,
    );
    if (lastPlayedOrder != 0) {
      return lastPlayedOrder;
    }

    return left.word.toLowerCase().compareTo(right.word.toLowerCase());
  }

  static int _recoveryPriority(WordMemoryProgress progress, DateTime now) {
    if (progress.timesCorrect <= 0) {
      return 0;
    }
    if (progress.consecutiveCorrect <= 0) {
      return 1;
    }
    final nextReview = progress.nextReview;
    if (nextReview == null) {
      return 2;
    }
    if (!nextReview.isAfter(now)) {
      return 3;
    }
    return 4;
  }

  static int _compareNullableDate(
    DateTime? left,
    DateTime? right, {
    required bool nullsLast,
  }) {
    if (left == null && right == null) {
      return 0;
    }
    if (left == null) {
      return nullsLast ? 1 : -1;
    }
    if (right == null) {
      return nullsLast ? -1 : 1;
    }
    return left.compareTo(right);
  }
}

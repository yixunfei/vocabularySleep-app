import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/word_entry.dart';
import 'package:vocabulary_sleep_app/src/models/word_memory_progress.dart';
import 'package:vocabulary_sleep_app/src/services/memory_lane_selector.dart';

WordEntry _entry(int id, String word) {
  return WordEntry(id: id, wordbookId: 1, word: word);
}

void main() {
  group('MemoryLaneSelector', () {
    final now = DateTime(2026, 3, 15, 9);
    final words = <WordEntry>[
      _entry(1, 'alpha'),
      _entry(2, 'beta'),
      _entry(3, 'gamma'),
      _entry(4, 'delta'),
    ];

    test('stable lane keeps remembered words that are not due yet', () {
      final progress = <int, WordMemoryProgress>{
        1: WordMemoryProgress(
          wordId: 1,
          timesPlayed: 3,
          timesCorrect: 3,
          consecutiveCorrect: 3,
          familiarity: 0.68,
          nextReview: now.add(const Duration(days: 2)),
          lastPlayed: now.subtract(const Duration(hours: 3)),
          memoryState: 'familiar',
        ),
        2: WordMemoryProgress(
          wordId: 2,
          timesPlayed: 1,
          timesCorrect: 1,
          consecutiveCorrect: 1,
          familiarity: 0.2,
          nextReview: now.add(const Duration(hours: 12)),
          lastPlayed: now.subtract(const Duration(hours: 1)),
          memoryState: 'learning',
        ),
        3: WordMemoryProgress(
          wordId: 3,
          timesPlayed: 2,
          timesCorrect: 1,
          consecutiveCorrect: 0,
          familiarity: 0.05,
          nextReview: now.add(const Duration(days: 1)),
          lastPlayed: now.subtract(const Duration(minutes: 30)),
          memoryState: 'learning',
        ),
      };

      final stable = MemoryLaneSelector.selectStableEntries(
        words: words,
        progressByWordId: progress,
        now: now,
      );

      expect(stable.map((item) => item.word), <String>['beta', 'alpha']);
    });

    test('recovery lane prioritizes failed and due words', () {
      final progress = <int, WordMemoryProgress>{
        1: WordMemoryProgress(
          wordId: 1,
          timesPlayed: 2,
          timesCorrect: 0,
          consecutiveCorrect: 0,
          familiarity: 0,
          nextReview: now.add(const Duration(days: 1)),
          lastPlayed: now.subtract(const Duration(minutes: 20)),
          memoryState: 'learning',
        ),
        2: WordMemoryProgress(
          wordId: 2,
          timesPlayed: 4,
          timesCorrect: 3,
          consecutiveCorrect: 0,
          familiarity: 0.31,
          nextReview: now.add(const Duration(days: 1)),
          lastPlayed: now.subtract(const Duration(hours: 2)),
          memoryState: 'learning',
        ),
        3: WordMemoryProgress(
          wordId: 3,
          timesPlayed: 6,
          timesCorrect: 6,
          consecutiveCorrect: 4,
          familiarity: 0.84,
          nextReview: now.subtract(const Duration(hours: 4)),
          lastPlayed: now.subtract(const Duration(days: 1)),
          memoryState: 'mastered',
        ),
        4: WordMemoryProgress(
          wordId: 4,
          timesPlayed: 3,
          timesCorrect: 3,
          consecutiveCorrect: 2,
          familiarity: 0.61,
          nextReview: now.add(const Duration(days: 3)),
          lastPlayed: now.subtract(const Duration(days: 2)),
          memoryState: 'familiar',
        ),
      };

      final recovery = MemoryLaneSelector.selectRecoveryEntries(
        words: words,
        progressByWordId: progress,
        now: now,
      );

      expect(recovery.map((item) => item.word), <String>[
        'alpha',
        'beta',
        'gamma',
      ]);
    });
  });
}

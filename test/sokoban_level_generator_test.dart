import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/games/sokoban/sokoban_level.dart';
import 'package:vocabulary_sleep_app/src/games/sokoban/sokoban_level_generator.dart';

void main() {
  test('all difficulty presets produce replayable levels quickly', () {
    const generator = SokobanLevelGenerator();
    for (final difficulty in SokobanDifficulty.values) {
      final stopwatch = Stopwatch()..start();
      final signatures = <String>{};
      for (var seed = 1; seed <= 8; seed += 1) {
        final level = generator.generate(
          difficulty: difficulty,
          seed: seed,
          excludedSignatures: signatures,
        );
        signatures.add(level.signature);
        expect(level.boxStarts.length, difficulty.boxes);
        expect(level.goals.length, difficulty.boxes);
        expect(level.solution, isNotEmpty);
        expect(_replay(level), isTrue);
      }
      stopwatch.stop();
      expect(
        stopwatch.elapsed,
        lessThan(const Duration(seconds: 2)),
        reason: '${difficulty.name} generation exceeded the UI budget',
      );
      expect(signatures.length, greaterThanOrEqualTo(6));
    }
  });

  test('new seeds provide structural variety', () {
    const generator = SokobanLevelGenerator();
    final levels = <SokobanLevel>[
      for (var seed = 20; seed < 28; seed += 1)
        generator.generate(difficulty: SokobanDifficulty.triple, seed: seed),
    ];
    expect(
      levels.map((level) => level.walls.length).toSet().length,
      greaterThan(1),
    );
    expect(
      levels.map((level) => level.signature).toSet().length,
      greaterThanOrEqualTo(6),
    );
  });

  test('a broad seed range keeps the intended difficulty floor', () {
    const generator = SokobanLevelGenerator();
    for (final difficulty in SokobanDifficulty.values) {
      for (var seed = 0; seed < 64; seed += 1) {
        final level = generator.generate(difficulty: difficulty, seed: seed);
        expect(level.optimalPushes, greaterThanOrEqualTo(difficulty.minPushes));
        expect(_replay(level), isTrue);
      }
    }
  });

  test('background generation returns a replayable level', () async {
    final level = await generateSokobanLevelInBackground(
      difficulty: SokobanDifficulty.triple,
      seed: 314159,
    );
    expect(level.solutionPushes, greaterThanOrEqualTo(32));
    expect(_replay(level), isTrue);
  });

  test('constrained boards keep fallback coordinates playable', () {
    for (final size in <int>[3, 6]) {
      final generator = SokobanLevelGenerator(rows: size, columns: size);
      for (final difficulty in SokobanDifficulty.values) {
        final level = generator.generate(difficulty: difficulty, seed: 7);
        expect(level.boxStarts.length, lessThanOrEqualTo(difficulty.boxes));
        expect(level.goals.length, level.boxStarts.length);
        expect(
          level.boxStarts.every((cell) => !level.walls.contains(cell)),
          isTrue,
        );
        expect(
          level.goals.every((cell) => !level.walls.contains(cell)),
          isTrue,
        );
        expect(level.boxStarts.contains(level.playerStart), isFalse);
        expect(_replay(level), isTrue);
      }
    }
  });
}

bool _replay(SokobanLevel level) {
  var player = level.playerStart;
  final boxes = List<int>.of(level.boxStarts);
  for (final push in level.solution) {
    if (push.boxId < 0 ||
        push.boxId >= boxes.length ||
        boxes[push.boxId] != push.from ||
        push.to != _step(level, push.from, push.direction)) {
      return false;
    }
    final behind = _step(level, push.from, push.direction.opposite);
    if (!_reachable(level, player, behind, boxes) ||
        level.walls.contains(push.to) ||
        boxes.asMap().entries.any(
          (entry) => entry.key != push.boxId && entry.value == push.to,
        )) {
      return false;
    }
    boxes[push.boxId] = push.to;
    player = push.from;
  }
  return level.isSolved(boxes);
}

int _step(SokobanLevel level, int index, SokobanDirection direction) {
  final row = index ~/ level.columns;
  final column = index % level.columns;
  return (row + direction.rowDelta) * level.columns +
      column +
      direction.columnDelta;
}

bool _reachable(SokobanLevel level, int start, int target, List<int> boxes) {
  if (!level.isInside(start) ||
      !level.isInside(target) ||
      level.walls.contains(start) ||
      level.walls.contains(target) ||
      boxes.contains(start) ||
      boxes.contains(target)) {
    return false;
  }
  final visited = <int>{start};
  final queue = <int>[start];
  for (var head = 0; head < queue.length; head += 1) {
    final current = queue[head];
    if (current == target) {
      return true;
    }
    for (final direction in SokobanDirection.values) {
      final next = _step(level, current, direction);
      if (!level.isInside(next) ||
          level.walls.contains(next) ||
          boxes.contains(next) ||
          !visited.add(next)) {
        continue;
      }
      queue.add(next);
    }
  }
  return false;
}

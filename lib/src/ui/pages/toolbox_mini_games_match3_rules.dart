part of 'toolbox_mini_games.dart';

extension _MatchThreeRules on _MatchThreeGameState {
  int _timeBonusFor(int clearedCount, int chain) {
    final countBonus = clearedCount ~/ 4;
    final chainBonus = math.max(0, chain - 1);
    return math.min(12, 2 + countBonus + chainBonus);
  }

  Set<int> _findMatches(List<int> tiles) {
    return <int>{for (final run in _findRuns(tiles)) ...run.indexes};
  }

  List<_MatchThreeRun> _findRuns(List<int> tiles) {
    final runs = <_MatchThreeRun>[];
    bool sameKind(int current, int previous) {
      return current >= 0 &&
          previous >= 0 &&
          _kindOf(current) == _kindOf(previous);
    }

    void addRun({
      required int start,
      required int endExclusive,
      required bool horizontal,
      required int fixed,
    }) {
      if (endExclusive - start < 3) {
        return;
      }
      final firstIndex = horizontal
          ? _indexOf(fixed, start)
          : _indexOf(start, fixed);
      final kind = _kindOf(tiles[firstIndex]);
      if (kind < 0) {
        return;
      }
      runs.add(
        _MatchThreeRun(
          indexes: <int>[
            for (var value = start; value < endExclusive; value += 1)
              horizontal ? _indexOf(fixed, value) : _indexOf(value, fixed),
          ],
          kind: kind,
          horizontal: horizontal,
        ),
      );
    }

    for (var row = 0; row < _MatchThreeGameState._rows; row += 1) {
      var runStart = 0;
      for (var col = 1; col <= _MatchThreeGameState._cols; col += 1) {
        final same =
            col < _MatchThreeGameState._cols &&
            sameKind(tiles[_indexOf(row, col)], tiles[_indexOf(row, col - 1)]);
        if (same) {
          continue;
        }
        addRun(
          start: runStart,
          endExclusive: col,
          horizontal: true,
          fixed: row,
        );
        runStart = col;
      }
    }
    for (var col = 0; col < _MatchThreeGameState._cols; col += 1) {
      var runStart = 0;
      for (var row = 1; row <= _MatchThreeGameState._rows; row += 1) {
        final same =
            row < _MatchThreeGameState._rows &&
            sameKind(tiles[_indexOf(row, col)], tiles[_indexOf(row - 1, col)]);
        if (same) {
          continue;
        }
        addRun(
          start: runStart,
          endExclusive: row,
          horizontal: false,
          fixed: col,
        );
        runStart = row;
      }
    }
    return runs;
  }

  List<_MatchThreeActivation> _swapActivations(
    int first,
    int second, {
    required bool hasMatchAfterSwap,
  }) {
    final activations = <_MatchThreeActivation>[];
    final firstPower = _powerOf(_tiles[first]);
    final secondPower = _powerOf(_tiles[second]);
    if (!hasMatchAfterSwap &&
        firstPower != _MatchThreePower.none &&
        secondPower != _MatchThreePower.none) {
      return activations;
    }

    void addIfPowered(int index, int otherIndex) {
      final power = _powerOf(_tiles[index]);
      if (power == _MatchThreePower.none) {
        return;
      }
      activations.add(
        _MatchThreeActivation(
          index: index,
          targetKind: _rainbowTargetKind(index, otherIndex),
        ),
      );
    }

    addIfPowered(first, second);
    addIfPowered(second, first);
    return activations;
  }

  int? _rainbowTargetKind(int rainbowIndex, int otherIndex) {
    if (_powerOf(_tiles[rainbowIndex]) != _MatchThreePower.rainbow) {
      return null;
    }
    if (_powerOf(_tiles[otherIndex]) == _MatchThreePower.rainbow) {
      return null;
    }
    final kind = _kindOf(_tiles[otherIndex]);
    return kind >= 0 ? kind : null;
  }

  _MatchThreeClearPlan _buildClearPlan({
    required List<_MatchThreeRun> runs,
    required List<_MatchThreeActivation> activations,
    required List<int> creationHints,
  }) {
    final matches = <int>{for (final run in runs) ...run.indexes};
    final creation = _choosePowerCreation(runs, creationHints);
    if (creation != null) {
      matches.remove(creation.index);
    }
    final clearIndexes = _expandPowerClears(
      matches,
      activations,
      preservedIndex: creation?.index,
    );
    return _MatchThreeClearPlan(clearIndexes: clearIndexes, creation: creation);
  }

  _MatchThreePowerCreation? _choosePowerCreation(
    List<_MatchThreeRun> runs,
    List<int> hints,
  ) {
    if (runs.isEmpty) {
      return null;
    }
    final runsByIndex = <int, List<_MatchThreeRun>>{};
    for (final run in runs) {
      for (final index in run.indexes) {
        (runsByIndex[index] ??= <_MatchThreeRun>[]).add(run);
      }
    }

    _MatchThreePowerCreation? creationFor(int index) {
      if (index < 0 ||
          index >= _tiles.length ||
          _tiles[index] < 0 ||
          _powerOf(_tiles[index]) != _MatchThreePower.none) {
        return null;
      }
      final indexRuns = runsByIndex[index];
      if (indexRuns == null || indexRuns.isEmpty) {
        return null;
      }
      final power = _powerForRuns(indexRuns);
      if (power == _MatchThreePower.none) {
        return null;
      }
      return _MatchThreePowerCreation(
        index: index,
        kind: _kindOf(_tiles[index]),
        power: power,
      );
    }

    for (final hint in hints) {
      final creation = creationFor(hint);
      if (creation != null) {
        return creation;
      }
    }

    final candidates = <_MatchThreePowerCreation>[
      for (final index in runsByIndex.keys) ?creationFor(index),
    ];
    if (candidates.isEmpty) {
      return null;
    }
    candidates.sort((a, b) {
      final powerCompare = _powerPriority(b.power) - _powerPriority(a.power);
      if (powerCompare != 0) {
        return powerCompare;
      }
      final lengthCompare =
          _longestRunAt(runsByIndex[b.index]!) -
          _longestRunAt(runsByIndex[a.index]!);
      if (lengthCompare != 0) {
        return lengthCompare;
      }
      final centerCompare =
          _centerDistance(a.index, runsByIndex[a.index]!) -
          _centerDistance(b.index, runsByIndex[b.index]!);
      if (centerCompare != 0) {
        return centerCompare;
      }
      return a.index.compareTo(b.index);
    });
    return candidates.first;
  }

  _MatchThreePower _powerForRuns(List<_MatchThreeRun> runs) {
    if (runs.any((run) => run.length >= 5)) {
      return _MatchThreePower.rainbow;
    }
    final hasHorizontal = runs.any((run) => run.horizontal);
    final hasVertical = runs.any((run) => !run.horizontal);
    if (hasHorizontal && hasVertical) {
      return _MatchThreePower.bomb;
    }
    final longRun = runs
        .where((run) => run.length >= 4)
        .fold<_MatchThreeRun?>(
          null,
          (best, run) => best == null || run.length > best.length ? run : best,
        );
    if (longRun == null) {
      return _MatchThreePower.none;
    }
    return longRun.horizontal ? _MatchThreePower.row : _MatchThreePower.column;
  }

  int _powerPriority(_MatchThreePower power) {
    return switch (power) {
      _MatchThreePower.rainbow => 4,
      _MatchThreePower.bomb => 3,
      _MatchThreePower.row || _MatchThreePower.column => 2,
      _MatchThreePower.none => 0,
    };
  }

  int _longestRunAt(List<_MatchThreeRun> runs) {
    return runs.fold<int>(0, (best, run) => math.max(best, run.length));
  }

  int _centerDistance(int index, List<_MatchThreeRun> runs) {
    return runs.fold<int>(
      _MatchThreeGameState._rows + _MatchThreeGameState._cols,
      (best, run) {
        final center = run.indexes[run.length ~/ 2];
        final distance =
            (_rowOf(index) - _rowOf(center)).abs() +
            (_colOf(index) - _colOf(center)).abs();
        return math.min(best, distance);
      },
    );
  }

  Set<int> _expandPowerClears(
    Set<int> baseClearIndexes,
    List<_MatchThreeActivation> activations, {
    int? preservedIndex,
  }) {
    final clearIndexes = <int>{...baseClearIndexes};
    final queue = Queue<_MatchThreeActivation>();
    final processed = <int>{};

    for (final index in baseClearIndexes) {
      final power = _powerOf(_tiles[index]);
      if (power == _MatchThreePower.none) {
        continue;
      }
      queue.add(
        _MatchThreeActivation(
          index: index,
          targetKind: power == _MatchThreePower.rainbow
              ? _kindOf(_tiles[index])
              : null,
        ),
      );
    }
    queue.addAll(activations);

    while (queue.isNotEmpty) {
      final activation = queue.removeFirst();
      if (!processed.add(activation.index) ||
          activation.index < 0 ||
          activation.index >= _tiles.length ||
          _tiles[activation.index] < 0) {
        continue;
      }
      final power = _powerOf(_tiles[activation.index]);
      if (power == _MatchThreePower.none) {
        continue;
      }
      clearIndexes.add(activation.index);
      for (final index in _affectedByPower(
        activation.index,
        power,
        activation.targetKind,
      )) {
        if (index == preservedIndex ||
            _tiles[index] == _MatchThreeGameState._emptyTile ||
            (power == _MatchThreePower.rainbow &&
                _tiles[index] == _MatchThreeGameState._blockerTile)) {
          continue;
        }
        clearIndexes.add(index);
        if (_tiles[index] == _MatchThreeGameState._blockerTile) {
          continue;
        }
        final chainedPower = _powerOf(_tiles[index]);
        if (chainedPower != _MatchThreePower.none &&
            !processed.contains(index)) {
          queue.add(
            _MatchThreeActivation(
              index: index,
              targetKind: chainedPower == _MatchThreePower.rainbow
                  ? _kindOf(_tiles[index])
                  : null,
            ),
          );
        }
      }
    }

    if (preservedIndex != null) {
      clearIndexes.remove(preservedIndex);
    }
    return clearIndexes;
  }

  Iterable<int> _affectedByPower(
    int index,
    _MatchThreePower power,
    int? targetKind,
  ) sync* {
    switch (power) {
      case _MatchThreePower.none:
        return;
      case _MatchThreePower.row:
        final row = _rowOf(index);
        for (var col = 0; col < _MatchThreeGameState._cols; col += 1) {
          yield _indexOf(row, col);
        }
      case _MatchThreePower.column:
        final col = _colOf(index);
        for (var row = 0; row < _MatchThreeGameState._rows; row += 1) {
          yield _indexOf(row, col);
        }
      case _MatchThreePower.bomb:
        final centerRow = _rowOf(index);
        final centerCol = _colOf(index);
        for (var row = centerRow - 1; row <= centerRow + 1; row += 1) {
          if (row < 0 || row >= _MatchThreeGameState._rows) {
            continue;
          }
          for (var col = centerCol - 1; col <= centerCol + 1; col += 1) {
            if (col < 0 || col >= _MatchThreeGameState._cols) {
              continue;
            }
            yield _indexOf(row, col);
          }
        }
      case _MatchThreePower.rainbow:
        for (var tileIndex = 0; tileIndex < _tiles.length; tileIndex += 1) {
          if (_tiles[tileIndex] < 0) {
            continue;
          }
          if (targetKind == null || _kindOf(_tiles[tileIndex]) == targetKind) {
            yield tileIndex;
          }
        }
    }
  }

  bool _hasAnyMove(List<int> tiles) {
    return _validMoveCount(tiles, stopAt: 1) > 0;
  }

  int _validMoveCount(
    List<int> tiles, {
    int stopAt = _MatchThreeGameState._minimumPlayableMoves,
  }) {
    var count = 0;
    final copy = List<int>.of(tiles);
    bool countPair(int first, int second) {
      if (copy[first] < 0 || copy[second] < 0) {
        return false;
      }
      final firstPower = _powerOf(copy[first]);
      final secondPower = _powerOf(copy[second]);
      if (firstPower != _MatchThreePower.none ||
          secondPower != _MatchThreePower.none) {
        if (firstPower == _MatchThreePower.none ||
            secondPower == _MatchThreePower.none) {
          count += 1;
          return count >= stopAt;
        }
        _swap(copy, first, second);
        final hasMatch = _findMatches(copy).isNotEmpty;
        _swap(copy, first, second);
        if (hasMatch) {
          count += 1;
        }
        return count >= stopAt;
      }
      _swap(copy, first, second);
      final hasMatch = _findMatches(copy).isNotEmpty;
      _swap(copy, first, second);
      if (hasMatch) {
        count += 1;
      }
      return count >= stopAt;
    }

    for (var row = 0; row < _MatchThreeGameState._rows; row += 1) {
      for (var col = 0; col < _MatchThreeGameState._cols; col += 1) {
        final index = _indexOf(row, col);
        if (copy[index] < 0) {
          continue;
        }
        if (col + 1 < _MatchThreeGameState._cols) {
          final right = _indexOf(row, col + 1);
          if (countPair(index, right)) {
            return count;
          }
        }
        if (row + 1 < _MatchThreeGameState._rows) {
          final down = _indexOf(row + 1, col);
          if (countPair(index, down)) {
            return count;
          }
        }
      }
    }
    return count;
  }

  void _dropAndFill() {
    for (var col = 0; col < _MatchThreeGameState._cols; col += 1) {
      var segmentBottom = _MatchThreeGameState._rows - 1;
      while (segmentBottom >= 0) {
        if (_tiles[_indexOf(segmentBottom, col)] ==
            _MatchThreeGameState._blockerTile) {
          segmentBottom -= 1;
          continue;
        }
        var segmentTop = segmentBottom;
        while (segmentTop >= 0 &&
            _tiles[_indexOf(segmentTop, col)] !=
                _MatchThreeGameState._blockerTile) {
          segmentTop -= 1;
        }
        final kept = <int>[];
        for (var row = segmentBottom; row > segmentTop; row -= 1) {
          final value = _tiles[_indexOf(row, col)];
          if (value >= 0) {
            kept.add(value);
          }
        }
        for (var row = segmentBottom; row > segmentTop; row -= 1) {
          final keptIndex = segmentBottom - row;
          _tiles[_indexOf(row, col)] = keptIndex < kept.length
              ? kept[keptIndex]
              : _tileValue(_random.nextInt(_MatchThreeGameState._kinds));
        }
        segmentBottom = segmentTop - 1;
      }
    }
  }

  int _syncDifficultyBlockers({required String reason}) {
    final current = _tiles
        .where((value) => value == _MatchThreeGameState._blockerTile)
        .length;
    final target = _targetBlockerCount;
    var needed = _targetBlockerCount - current;
    if (needed <= 0) {
      return 0;
    }
    var placedCount = 0;
    var rejectedCount = 0;
    var stopReason = 'target_reached';
    while (needed > 0) {
      final candidates = <int>[
        for (var index = 0; index < _tiles.length; index += 1)
          if (_tiles[index] >= 0 &&
              _powerOf(_tiles[index]) == _MatchThreePower.none &&
              _rowOf(index) > 0 &&
              _blockerNeighborCount(index) == 0)
            index,
      ];
      if (candidates.isEmpty) {
        stopReason = 'no_candidates';
        break;
      }
      candidates.shuffle(_random);
      var placed = false;
      for (final index in candidates) {
        final previous = _tiles[index];
        _tiles[index] = _MatchThreeGameState._blockerTile;
        if (_validMoveCount(_tiles) <
            _MatchThreeGameState._minimumPlayableMoves) {
          _tiles[index] = previous;
          rejectedCount += 1;
          continue;
        }
        placed = true;
        placedCount += 1;
        needed -= 1;
        break;
      }
      if (!placed) {
        stopReason = 'no_safe_candidate';
        break;
      }
    }
    _MatchThreeGameState._log.d(
      _MatchThreeGameState._logTag,
      'match3.blockers.sync',
      data: <String, Object?>{
        ..._boardDiagnostics(reason: reason),
        'targetBlockers': target,
        'previousBlockers': current,
        'placedBlockers': placedCount,
        'rejectedCandidates': rejectedCount,
        'stopReason': stopReason,
      },
    );
    return placedCount;
  }

  int _blockerNeighborCount(int index) {
    final row = _rowOf(index);
    final col = _colOf(index);
    var count = 0;
    for (final neighbor in <int>[
      if (row > 0) _indexOf(row - 1, col),
      if (row + 1 < _MatchThreeGameState._rows) _indexOf(row + 1, col),
      if (col > 0) _indexOf(row, col - 1),
      if (col + 1 < _MatchThreeGameState._cols) _indexOf(row, col + 1),
    ]) {
      if (_tiles[neighbor] == _MatchThreeGameState._blockerTile) {
        count += 1;
      }
    }
    return count;
  }

  void _swap(List<int> tiles, int a, int b) {
    final value = tiles[a];
    tiles[a] = tiles[b];
    tiles[b] = value;
  }
}

part of 'toolbox_mini_games.dart';

extension _MatchThreeResolution on _MatchThreeGameState {
  Future<void> _attemptSwap(int first, int second) async {
    if (!_canAttemptSwap(first, second)) return;
    final generation = ++_resolveGeneration;
    var swapped = false;
    var swapCommitted = false;
    try {
      _setViewState(() {
        _resolving = true;
        _resolvingSince = DateTime.now();
        _selected = null;
        _swap(_tiles, first, second);
        swapped = true;
      });
      await _waitForResolveDelay(const Duration(milliseconds: 90));
      if (!_isResolutionCurrent(generation)) return;
      final runs = _findRuns(_tiles);
      final activations = _swapActivations(
        first,
        second,
        hasMatchAfterSwap: runs.isNotEmpty,
      );
      if (runs.isEmpty && activations.isEmpty) {
        if (!_isResolutionCurrent(generation)) {
          return;
        }
        _setViewState(() {
          _swap(_tiles, first, second);
          swapped = false;
          _invalidSwaps += 1;
          _resolving = false;
          _resolvingSince = null;
          _resetTileDrag();
          _status = _MatchThreeStatus.invalid;
        });
        _MatchThreeGameState._log.d(
          _MatchThreeGameState._logTag,
          'match3.swap.no_match',
          data: _boardDiagnostics(
            origin: first,
            target: second,
            reason: 'no_runs_or_power_activation',
          ),
        );
        return;
      }
      if (!_isResolutionCurrent(generation)) {
        return;
      }
      _setViewState(() {
        _moves += 1;
        _status = _MatchThreeStatus.clearing;
      });
      swapCommitted = true;
      await _resolveBoard(
        generation: generation,
        runs: runs,
        activations: activations,
        creationHints: <int>[second, first],
      );
      if (!_isResolutionCurrent(generation)) {
        return;
      }
      _finishResolution(first, second);
    } catch (error, stackTrace) {
      if (!_isResolutionCurrent(generation)) return;
      _recoverSwapFailure(
        first,
        second,
        swapped && !swapCommitted,
        error,
        stackTrace,
      );
    }
  }

  bool _canAttemptSwap(int first, int second) {
    if (_resolving || _remainingSeconds <= 0 || _gameFinished) {
      _MatchThreeGameState._log.d(
        _MatchThreeGameState._logTag,
        'match3.swap.rejected',
        data: _boardDiagnostics(
          origin: first,
          target: second,
          reason: 'locked_or_finished',
        ),
      );
      _resetTileDrag();
      return false;
    }
    if (!_areAdjacent(first, second) ||
        !_isSwappableIndex(first) ||
        !_isSwappableIndex(second)) {
      _setViewState(() {
        _invalidSwaps += 1;
        _selected = null;
        _status = _MatchThreeStatus.invalid;
      });
      _MatchThreeGameState._log.d(
        _MatchThreeGameState._logTag,
        'match3.swap.invalid_target',
        data: _boardDiagnostics(
          origin: first,
          target: second,
          reason: 'not_adjacent_or_not_swappable',
        ),
      );
      _resetTileDrag();
      return false;
    }
    return true;
  }

  void _finishResolution(int first, int second) {
    _setViewState(() {
      _resolving = false;
      _resolvingSince = null;
      _resetTileDrag();
      _syncDifficultyBlockers(reason: 'resolve_complete');
      if (_score >= _MatchThreeGameState._targetScore) {
        _status = _MatchThreeStatus.won;
        _timer?.cancel();
      } else if (_remainingSeconds <= 0) {
        _status = _MatchThreeStatus.timeUp;
        _timer?.cancel();
      } else if (!_hasAnyMove(_tiles)) {
        _tiles = _generateBoard();
        _syncDifficultyBlockers(reason: 'no_moves_after_resolve');
        _selected = null;
        _status = _MatchThreeStatus.reshuffled;
        _autoReshuffles += 1;
        _MatchThreeGameState._log.w(
          _MatchThreeGameState._logTag,
          'match3.board.reshuffled',
          data: _boardDiagnostics(reason: 'no_moves_after_resolve'),
        );
      } else {
        _status = _MatchThreeStatus.ready;
      }
      _recoverInteractionIfNeeded('resolve_complete');
    });
    _MatchThreeGameState._log.d(
      _MatchThreeGameState._logTag,
      'match3.swap.resolved',
      data: _boardDiagnostics(origin: first, target: second),
    );
    if (_status == _MatchThreeStatus.won) {
      unawaited(HapticFeedback.mediumImpact());
    }
    if (_gameFinished) {
      _showResultReportIfNeeded();
    }
  }

  void _recoverSwapFailure(
    int first,
    int second,
    bool undoSwap,
    Object error,
    StackTrace stackTrace,
  ) {
    _MatchThreeGameState._log.e(
      _MatchThreeGameState._logTag,
      'match3.swap.exception',
      error: error,
      stackTrace: stackTrace,
      data: _boardDiagnostics(
        origin: first,
        target: second,
        reason: 'swap_exception',
      ),
    );
    _setViewState(() {
      if (undoSwap) {
        _swap(_tiles, first, second);
      }
      _resolving = false;
      _resolvingSince = null;
      _clearingTiles = <int>{};
      _selected = null;
      _resetTileDrag();
      if (!_gameFinished && _remainingSeconds > 0) {
        _status = _MatchThreeStatus.ready;
      }
      _recoverInteractionIfNeeded('swap_exception');
    });
  }

  Future<void> _resolveBoard({
    required int generation,
    required List<_MatchThreeRun> runs,
    List<_MatchThreeActivation> activations = const <_MatchThreeActivation>[],
    List<int> creationHints = const <int>[],
  }) async {
    var currentRuns = runs;
    var currentActivations = activations;
    var currentCreationHints = creationHints;
    var chain = 1;
    while (_isResolutionCurrent(generation)) {
      final clearPlan = _buildClearPlan(
        runs: currentRuns,
        activations: currentActivations,
        creationHints: currentCreationHints,
      );
      final currentMatches = clearPlan.clearIndexes;
      if (currentMatches.isEmpty) {
        return;
      }
      final clearingTiles = Set<int>.of(currentMatches);
      final blockerClears = currentMatches
          .where((index) => _tiles[index] == _MatchThreeGameState._blockerTile)
          .length;
      final timeBonus = _timeBonusFor(currentMatches.length, chain);
      _setViewState(() {
        _chain = chain;
        _maxChain = math.max(_maxChain, chain);
        _lastCleared = currentMatches.length;
        _lastTimeBonus = timeBonus;
        _totalCleared += currentMatches.length;
        _totalTimeBonus += timeBonus;
        _blockersCleared += blockerClears;
        _remainingSeconds = math.min(
          _MatchThreeGameState._maxSeconds,
          _remainingSeconds + timeBonus,
        );
        _score += currentMatches.length * 10 * chain;
        _clearingTiles = clearingTiles;
        final creation = clearPlan.creation;
        if (creation != null) {
          _tiles[creation.index] = _tileValue(creation.kind, creation.power);
        }
      });
      await _waitForResolveDelay(const Duration(milliseconds: 170));
      if (!_isResolutionCurrent(generation)) {
        return;
      }
      _setViewState(() {
        for (final index in currentMatches) {
          _tiles[index] = _MatchThreeGameState._emptyTile;
        }
        _clearingTiles = <int>{};
      });
      _setViewState(_dropAndFill);
      await _waitForResolveDelay(const Duration(milliseconds: 130));
      if (!_isResolutionCurrent(generation)) return;
      currentRuns = _findRuns(_tiles);
      currentActivations = const <_MatchThreeActivation>[];
      currentCreationHints = const <int>[];
      chain += 1;
    }
  }

  Future<void> _waitForResolveDelay(Duration duration) {
    _completeResolveDelay();
    final completer = Completer<void>();
    _resolveDelayCompleter = completer;
    _resolveDelayTimer = Timer(duration, () {
      if (identical(_resolveDelayCompleter, completer) &&
          !completer.isCompleted) {
        completer.complete();
      }
    });
    return completer.future;
  }

  bool _isResolutionCurrent(int generation) =>
      mounted && generation == _resolveGeneration;

  void _cancelResolution() {
    ++_resolveGeneration;
    _completeResolveDelay();
  }

  void _completeResolveDelay() {
    _resolveDelayTimer?.cancel();
    _resolveDelayTimer = null;
    final completer = _resolveDelayCompleter;
    _resolveDelayCompleter = null;
    if (completer != null && !completer.isCompleted) completer.complete();
  }
}

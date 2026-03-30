part of 'app_state.dart';

extension _AppStatePlayback on AppState {
  Future<void> _syncPlaybackToSelectedWordbook(Wordbook wordbook) async {
    if (!_isPlaying || _isPaused || _playingWordbookId == wordbook.id) {
      return;
    }

    final scopeWords = _scopeWords;
    if (scopeWords.isEmpty) {
      await stop();
      return;
    }

    final activeWord = currentWord;
    var startIndex = 0;
    if (activeWord != null) {
      final scopedIndex = _indexOfWordEntry(scopeWords, activeWord);
      if (scopedIndex >= 0) {
        startIndex = scopedIndex;
      }
    }
    final words = List<WordEntry>.from(scopeWords);
    final safeStart = startIndex.clamp(0, words.length - 1);
    final syncToken = ++_wordbookPlaybackSyncToken;
    _playingWordbookId = wordbook.id;
    _playingWordbookName = wordbook.name;
    _playingScopeWords = words;
    _playingScopeIndex = safeStart;
    _playingWord = words[safeStart].word;
    _rememberPlaybackProgressImpl(words[safeStart]);
    _currentUnit = 0;
    _totalUnits = 0;
    _activeUnit = null;
    _notifyStateChanged();

    _playSessionId += 1;
    await _playback.stop();
    if (syncToken != _wordbookPlaybackSyncToken) return;
    if (_selectedWordbook?.id != wordbook.id) return;

    unawaited(
      _startPlaySession(
        scopeWords: words,
        startIndex: safeStart,
        playingWordbookId: wordbook.id,
        playingWordbookName: wordbook.name,
      ),
    );
  }

  Future<void> _playImpl() async {
    final selected = _selectedWordbook;
    final scopeWords = _scopeWords;
    if (selected == null || scopeWords.isEmpty || _isPlaying) {
      _log.w(
        'app_state',
        'play ignored',
        data: <String, Object?>{
          'selectedWordbook': selected?.id,
          'scopeWords': scopeWords.length,
          'isPlaying': _isPlaying,
        },
      );
      return;
    }

    final activeWord = currentWord;
    var startIndex = 0;
    if (activeWord != null) {
      final scopedIndex = _indexOfWordEntry(scopeWords, activeWord);
      if (scopedIndex >= 0) startIndex = scopedIndex;
    }
    await _startPlaySession(
      scopeWords: scopeWords,
      startIndex: startIndex,
      playingWordbookId: selected.id,
      playingWordbookName: selected.name,
    );
  }

  Future<void> _startPlaySession({
    required List<WordEntry> scopeWords,
    required int startIndex,
    required int playingWordbookId,
    required String playingWordbookName,
  }) async {
    if (scopeWords.isEmpty) return;
    final words = List<WordEntry>.from(scopeWords);
    final safeStart = startIndex.clamp(0, words.length - 1);
    final sessionId = ++_playSessionId;

    _isPlaying = true;
    _isPaused = false;
    _playingWordbookId = playingWordbookId;
    _playingWordbookName = playingWordbookName;
    _playingScopeWords = words;
    _playingScopeIndex = safeStart;
    _playingWord = words[safeStart].word;
    _rememberPlaybackProgressImpl(words[safeStart]);
    _currentUnit = 0;
    _totalUnits = 0;
    _activeUnit = null;
    _notifyStateChanged();

    try {
      await _playback.playWords(
        words: words,
        startIndex: safeStart,
        config: _config,
        onWordChanged: (index, word) {
          if (sessionId != _playSessionId) return;
          final nextWord = (index >= 0 && index < words.length)
              ? words[index]
              : word;
          final mappedIndex = _indexOfWordEntry(words, nextWord);
          if (mappedIndex >= 0) {
            _playingScopeIndex = mappedIndex;
          } else if (index >= 0 && index < words.length) {
            _playingScopeIndex = index;
          }
          _playingWord = nextWord.word;
          _rememberPlaybackProgressImpl(nextWord);
          if (_selectedWordbook?.id == _playingWordbookId) {
            _setCurrentWordByEntry(nextWord);
            resetTestModeProgress();
          }
          _notifyStateChanged();
        },
        onUnitChanged: (current, total, unit) {
          if (sessionId != _playSessionId) return;
          _currentUnit = current;
          _totalUnits = total;
          _activeUnit = unit;
          _notifyStateChanged();
        },
        onFinished: () {
          if (sessionId != _playSessionId) return;
          _clearPlaybackSession(notify: true);
        },
      );
    } catch (error, stackTrace) {
      if (sessionId != _playSessionId) return;
      _log.e(
        'app_state',
        'playback crashed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'wordbookId': _playingWordbookId,
          'scopeWords': words.length,
          'startIndex': safeStart,
        },
      );
      _setMessage(
        'errorInitFailed',
        params: <String, Object?>{'error': 'playback: $error'},
      );
      _clearPlaybackSession(notify: true);
    }
  }

  Future<void> _pauseOrResumeImpl() async {
    if (!_isPlaying) {
      _log.w('app_state', 'pauseOrResume ignored because not playing');
      return;
    }
    try {
      if (_isPaused) {
        await _playback.resume();
        _isPaused = false;
      } else {
        await _playback.pause();
        _isPaused = true;
      }
      _notifyStateChanged();
    } catch (error, stackTrace) {
      _log.e(
        'app_state',
        'pauseOrResume failed',
        error: error,
        stackTrace: stackTrace,
      );
      _setMessage(
        'errorInitFailed',
        params: <String, Object?>{'error': 'pause/resume: $error'},
      );
      _notifyStateChanged();
    }
  }

  Future<void> _stopPlaybackImpl() async {
    try {
      _playSessionId += 1;
      await _playback.stop();
    } catch (error, stackTrace) {
      _log.e('app_state', 'stop failed', error: error, stackTrace: stackTrace);
    } finally {
      _clearPlaybackSession(notify: true);
    }
  }

  Future<void> _skipCurrentWordImpl() => _playback.skipCurrentWord();

  Future<void> _playPreviousWordImpl() async {
    final scopeWords = _scopeWords;
    if (scopeWords.isEmpty) return;
    final current = currentWord;
    final currentScopeIndex = current == null
        ? 0
        : _indexOfWordEntry(scopeWords, current);
    final safeIndex = currentScopeIndex < 0 ? 0 : currentScopeIndex;
    final nextScopeIndex =
        (safeIndex - 1 + scopeWords.length) % scopeWords.length;
    _setCurrentWordByEntry(scopeWords[nextScopeIndex]);
    _rememberPlaybackProgressImpl(scopeWords[nextScopeIndex]);
    resetTestModeProgress();
    _notifyStateChanged();
  }

  Future<void> _playNextWordImpl() async {
    final scopeWords = _scopeWords;
    if (scopeWords.isEmpty) return;
    final current = currentWord;
    final currentScopeIndex = current == null
        ? 0
        : _indexOfWordEntry(scopeWords, current);
    final safeIndex = currentScopeIndex < 0 ? 0 : currentScopeIndex;
    final nextScopeIndex = (safeIndex + 1) % scopeWords.length;
    _setCurrentWordByEntry(scopeWords[nextScopeIndex]);
    _rememberPlaybackProgressImpl(scopeWords[nextScopeIndex]);
    resetTestModeProgress();
    _notifyStateChanged();
  }

  Future<void> _jumpToPlayingWordbookImpl() async {
    final playingId = _playingWordbookId;
    if (playingId == null) return;
    final target = _wordbooks
        .where((book) => book.id == playingId)
        .cast<Wordbook?>()
        .firstOrNull;
    if (target == null) return;
    final focusIndex = _playingScopeWords.isEmpty
        ? null
        : _playingScopeIndex.clamp(0, _playingScopeWords.length - 1);
    final focusEntry = focusIndex == null
        ? null
        : _playingScopeWords[focusIndex];
    final focusWord = focusEntry?.word ?? _playingWord;
    await selectWordbook(
      target,
      focusWord: focusWord,
      focusWordId: focusEntry?.id,
    );
    final hasFocusedEntry = focusEntry != null
        ? _scopeWords.any((item) => _isSameWordEntry(item, focusEntry))
        : (focusWord != null
              ? _scopeWords.any((item) => item.word == focusWord)
              : true);
    if (_searchQuery.trim().isNotEmpty && !hasFocusedEntry) {
      _searchQuery = '';
      await selectWordbook(
        target,
        focusWord: focusWord,
        focusWordId: focusEntry?.id,
      );
    }
  }

  Future<void> _playCurrentWordbookImpl() async {
    if (_selectedWordbook == null) return;
    if (_isPlaying) {
      await stop();
    }
    await play();
  }

  Future<void> _movePlaybackPreviousWordImpl() async {
    if (!_isPlaying || _playingScopeWords.isEmpty) return;
    final current = _playingScopeIndex.clamp(0, _playingScopeWords.length - 1);
    final target =
        (current - 1 + _playingScopeWords.length) % _playingScopeWords.length;
    await _restartPlaybackFromPlayingScope(target);
  }

  Future<void> _movePlaybackNextWordImpl() async {
    if (!_isPlaying || _playingScopeWords.isEmpty) return;
    final current = _playingScopeIndex.clamp(0, _playingScopeWords.length - 1);
    final target = (current + 1) % _playingScopeWords.length;
    await _restartPlaybackFromPlayingScope(target);
  }

  Future<void> _restartPlaybackFromPlayingScope(int targetIndex) async {
    _queuedPlaybackScopeTarget = targetIndex;
    if (_playbackScopeRestarting) {
      return;
    }
    _playbackScopeRestarting = true;
    try {
      while (_queuedPlaybackScopeTarget != null) {
        final pending = _queuedPlaybackScopeTarget!;
        _queuedPlaybackScopeTarget = null;
        await _restartPlaybackFromPlayingScopeInternal(pending);
        if (!_isPlaying) break;
      }
    } finally {
      _playbackScopeRestarting = false;
    }
  }

  Future<void> _restartPlaybackFromPlayingScopeInternal(int targetIndex) async {
    final playingId = _playingWordbookId;
    final playingName = _playingWordbookName;
    if (playingId == null ||
        playingName == null ||
        _playingScopeWords.isEmpty) {
      return;
    }
    final words = List<WordEntry>.from(_playingScopeWords);
    final safeTarget = targetIndex.clamp(0, words.length - 1);
    _playingScopeIndex = safeTarget;
    _playingWord = words[safeTarget].word;
    _rememberPlaybackProgressImpl(words[safeTarget]);
    if (_selectedWordbook?.id == playingId) {
      _setCurrentWordByEntry(words[safeTarget]);
      resetTestModeProgress();
      _notifyStateChanged();
    }
    _playSessionId += 1;
    await _playback.stop();
    unawaited(
      _startPlaySession(
        scopeWords: words,
        startIndex: safeTarget,
        playingWordbookId: playingId,
        playingWordbookName: playingName,
      ),
    );
  }

  void _clearPlaybackSession({required bool notify}) {
    _isPlaying = false;
    _isPaused = false;
    _currentUnit = 0;
    _totalUnits = 0;
    _activeUnit = null;
    _playingWordbookId = null;
    _playingWordbookName = null;
    _playingWord = null;
    _playingScopeWords = <WordEntry>[];
    _playingScopeIndex = 0;
    _queuedPlaybackScopeTarget = null;
    _playbackScopeRestarting = false;
    if (notify) {
      _notifyStateChanged();
    }
  }
}

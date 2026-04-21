part of 'app_state.dart';

extension _AppStatePlayback on AppState {
  Future<Wordbook?> _ensureSelectedWordbookLoadedForPlayback() async {
    var selected = _selectedWordbook;
    if (selected == null || selectedWordbookLoaded) {
      return selected;
    }

    final showBusy = !_busy;
    if (showBusy) {
      _setBusy(
        true,
        messageKey: 'busyLoadingWordbook',
        params: <String, Object?>{'name': selected.name},
        detail: AppI18n(_uiLanguage).t('busyPatienceHint'),
      );
    }
    try {
      _selectedWordbook = selected;
      _setWords(_queryWordbookEntries(selected));
      final restoredIndex = _playbackProgressIndexForWordbook(selected);
      final restoredEntries = _searchQuery.trim().isEmpty
          ? _words
          : _scopeWords;
      if (restoredIndex >= 0 && restoredIndex < restoredEntries.length) {
        _setCurrentWordByEntry(restoredEntries[restoredIndex]);
      } else if (_currentWordIndex >= _words.length) {
        _currentWordIndex = _words.isEmpty ? 0 : (_words.length - 1);
      }
      _ensureCurrentWordInScope();
      resetTestModeProgress();
      _notifyStateChanged();
    } finally {
      if (showBusy) {
        _setBusy(false);
      }
    }
    return _selectedWordbook;
  }

  Future<void> _syncPlaybackToSelectedWordbook(Wordbook wordbook) async {
    if (!_playbackStore.isPlaying || _playbackStore.isPaused || _playbackStore.playingWordbookId == wordbook.id) {
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
    final syncToken = ++_playbackStore.wordbookPlaybackSyncToken;
    _playbackStore.playingWordbookId = wordbook.id;
    _playbackStore.playingWordbookName = wordbook.name;
    _playbackStore.playingScopeWords = words;
    _playbackStore.playingScopeIndex = safeStart;
    _playbackStore.playingWord = words[safeStart].word;
    _rememberPlaybackProgressImpl(words[safeStart]);
    _playbackStore.currentUnit = 0;
    _playbackStore.totalUnits = 0;
    _playbackStore.activeUnit = null;
    _notifyStateChanged();

    _playbackStore.playSessionId += 1;
    await _playback.stop();
    if (syncToken != _playbackStore.wordbookPlaybackSyncToken) return;
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

  Future<void> _preparePlayImpl() async {
    final selected = await _ensureSelectedWordbookLoadedForPlayback();
    final scopeWords = _scopeWords;
    if (selected == null || scopeWords.isEmpty || _playbackStore.isPlaying) {
      _log.w(
        'app_state',
        'prepare play ignored',
        data: <String, Object?>{
          'selectedWordbook': selected?.id,
          'scopeWords': scopeWords.length,
          'isPlaying': _playbackStore.isPlaying,
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
    final words = List<WordEntry>.from(scopeWords);
    final safeStart = startIndex.clamp(0, words.length - 1);
    final sessionId = ++_playbackStore.playSessionId;

    _playbackStore.isPlaying = false;
    _playbackStore.isPaused = true;
    _playbackStore.playingWordbookId = selected.id;
    _playbackStore.playingWordbookName = selected.name;
    _playbackStore.playingScopeWords = words;
    _playbackStore.playingScopeIndex = safeStart;
    _playbackStore.playingWord = words[safeStart].word;
    _rememberPlaybackProgressImpl(words[safeStart]);
    _playbackStore.currentUnit = 0;
    _playbackStore.totalUnits = 0;
    _playbackStore.activeUnit = null;
    _notifyStateChanged();

    try {
      await _playback.preparePlay(
        words: words,
        startIndex: safeStart,
        config: _config,
        resolveWord: (index, word) {
          final resolved = _hydrateWordEntryIfNeeded(word);
          if (index >= 0 && index < words.length) {
            words[index] = resolved;
          }
          return resolved;
        },
        onWordChanged: (index, word) {
          if (sessionId != _playbackStore.playSessionId) return;
          final nextWord = (index >= 0 && index < words.length)
              ? words[index]
              : word;
          final mappedIndex = _indexOfWordEntry(words, nextWord);
          if (mappedIndex >= 0) {
            _playbackStore.playingScopeIndex = mappedIndex;
          } else if (index >= 0 && index < words.length) {
            _playbackStore.playingScopeIndex = index;
          }
          _playbackStore.playingWord = nextWord.word;
          _rememberPlaybackProgressImpl(nextWord);
          if (_selectedWordbook?.id == _playbackStore.playingWordbookId) {
            _setCurrentWordByEntry(nextWord);
            resetTestModeProgress();
          }
          _notifyStateChanged();
        },
        onUnitChanged: (current, total, unit) {
          if (sessionId != _playbackStore.playSessionId) return;
          _playbackStore.currentUnit = current;
          _playbackStore.totalUnits = total;
          _playbackStore.activeUnit = unit;
          _notifyStateChanged();
        },
        onFinished: () {
          if (sessionId != _playbackStore.playSessionId) return;
          _clearPlaybackSession(notify: true);
        },
      );
      _log.i('app_state', 'Playback prepared successfully');
    } catch (error, stackTrace) {
      if (sessionId != _playbackStore.playSessionId) return;
      _log.e(
        'app_state',
        'playback prepare failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'wordbookId': _playbackStore.playingWordbookId,
          'scopeWords': words.length,
          'startIndex': safeStart,
        },
      );
      _setMessage(
        'errorInitFailed',
        params: <String, Object?>{'error': 'prepare playback: $error'},
      );
      _clearPlaybackSession(notify: true);
    }
  }

  Future<void> _startPreparedPlayImpl() async {
    if (_playbackStore.isPlaying || !_playback.isPrepared) {
      _log.w(
        'app_state',
        'start prepared play ignored',
        data: {'isPlaying': _playbackStore.isPlaying, 'isPrepared': _playback.isPrepared},
      );
      return;
    }
    _playbackStore.isPlaying = true;
    _playbackStore.isPaused = false;
    _notifyStateChanged();
    try {
      await _playback.startPreparedPlay();
    } catch (error, stackTrace) {
      _log.e(
        'app_state',
        'start prepared play failed',
        error: error,
        stackTrace: stackTrace,
      );
      _setMessage(
        'errorInitFailed',
        params: <String, Object?>{'error': 'start playback: $error'},
      );
      _clearPlaybackSession(notify: true);
    }
  }

  Future<void> _playImpl() async {
    final selected = await _ensureSelectedWordbookLoadedForPlayback();
    final scopeWords = _scopeWords;
    if (selected == null || scopeWords.isEmpty || _playbackStore.isPlaying) {
      _log.w(
        'app_state',
        'play ignored',
        data: <String, Object?>{
          'selectedWordbook': selected?.id,
          'scopeWords': scopeWords.length,
          'isPlaying': _playbackStore.isPlaying,
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
    final sessionId = ++_playbackStore.playSessionId;

    _playbackStore.isPlaying = true;
    _playbackStore.isPaused = false;
    _playbackStore.playingWordbookId = playingWordbookId;
    _playbackStore.playingWordbookName = playingWordbookName;
    _playbackStore.playingScopeWords = words;
    _playbackStore.playingScopeIndex = safeStart;
    _playbackStore.playingWord = words[safeStart].word;
    _rememberPlaybackProgressImpl(words[safeStart]);
    _playbackStore.currentUnit = 0;
    _playbackStore.totalUnits = 0;
    _playbackStore.activeUnit = null;
    _notifyStateChanged();

    try {
      await _playback.playWords(
        words: words,
        startIndex: safeStart,
        config: _config,
        resolveWord: (index, word) {
          final resolved = _hydrateWordEntryIfNeeded(word);
          if (index >= 0 && index < words.length) {
            words[index] = resolved;
          }
          return resolved;
        },
        onWordChanged: (index, word) {
          if (sessionId != _playbackStore.playSessionId) return;
          final nextWord = (index >= 0 && index < words.length)
              ? words[index]
              : word;
          final mappedIndex = _indexOfWordEntry(words, nextWord);
          if (mappedIndex >= 0) {
            _playbackStore.playingScopeIndex = mappedIndex;
          } else if (index >= 0 && index < words.length) {
            _playbackStore.playingScopeIndex = index;
          }
          _playbackStore.playingWord = nextWord.word;
          _rememberPlaybackProgressImpl(nextWord);
          if (_selectedWordbook?.id == _playbackStore.playingWordbookId) {
            _setCurrentWordByEntry(nextWord);
            resetTestModeProgress();
          }
          _notifyStateChanged();
        },
        onUnitChanged: (current, total, unit) {
          if (sessionId != _playbackStore.playSessionId) return;
          _playbackStore.currentUnit = current;
          _playbackStore.totalUnits = total;
          _playbackStore.activeUnit = unit;
          _notifyStateChanged();
        },
        onFinished: () {
          if (sessionId != _playbackStore.playSessionId) return;
          _clearPlaybackSession(notify: true);
        },
      );
    } catch (error, stackTrace) {
      if (sessionId != _playbackStore.playSessionId) return;
      _log.e(
        'app_state',
        'playback crashed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'wordbookId': _playbackStore.playingWordbookId,
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
    if (!_playbackStore.isPlaying) {
      _log.w('app_state', 'pauseOrResume ignored because not playing');
      return;
    }
    try {
      if (_playbackStore.isPaused) {
        await _playback.resume();
        _playbackStore.isPaused = false;
      } else {
        await _playback.pause();
        _playbackStore.isPaused = true;
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
      _playbackStore.playSessionId += 1;
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
    final playingId = _playbackStore.playingWordbookId;
    if (playingId == null) return;
    final target = _wordbooks
        .where((book) => book.id == playingId)
        .cast<Wordbook?>()
        .firstOrNull;
    if (target == null) return;
    final focusIndex = _playbackStore.playingScopeWords.isEmpty
        ? null
        : _playbackStore.playingScopeIndex.clamp(0, _playbackStore.playingScopeWords.length - 1);
    final focusEntry = focusIndex == null
        ? null
        : _playbackStore.playingScopeWords[focusIndex];
    final focusWord = focusEntry?.word ?? _playbackStore.playingWord;
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
    if (!selectedWordbookLoaded) {
      await _ensureSelectedWordbookLoadedForPlayback();
      return;
    }
    if (_playbackStore.isPlaying) {
      await stop();
    }
    await play();
  }

  Future<void> _movePlaybackPreviousWordImpl() async {
    if (!_playbackStore.isPlaying || _playbackStore.playingScopeWords.isEmpty) return;
    final current = _playbackStore.playingScopeIndex.clamp(0, _playbackStore.playingScopeWords.length - 1);
    final target =
        (current - 1 + _playbackStore.playingScopeWords.length) % _playbackStore.playingScopeWords.length;
    await _restartPlaybackFromPlayingScope(target);
  }

  Future<void> _movePlaybackNextWordImpl() async {
    if (!_playbackStore.isPlaying || _playbackStore.playingScopeWords.isEmpty) return;
    final current = _playbackStore.playingScopeIndex.clamp(0, _playbackStore.playingScopeWords.length - 1);
    final target = (current + 1) % _playbackStore.playingScopeWords.length;
    await _restartPlaybackFromPlayingScope(target);
  }

  Future<void> _restartPlaybackFromPlayingScope(int targetIndex) async {
    _playbackStore.queuedPlaybackScopeTarget = targetIndex;
    if (_playbackStore.playbackScopeRestarting) {
      return;
    }
    _playbackStore.playbackScopeRestarting = true;
    try {
      while (_playbackStore.queuedPlaybackScopeTarget != null) {
        final pending = _playbackStore.queuedPlaybackScopeTarget!;
        _playbackStore.queuedPlaybackScopeTarget = null;
        await _restartPlaybackFromPlayingScopeInternal(pending);
        if (!_playbackStore.isPlaying) break;
      }
    } finally {
      _playbackStore.playbackScopeRestarting = false;
    }
  }

  Future<void> _restartPlaybackFromPlayingScopeInternal(int targetIndex) async {
    final playingId = _playbackStore.playingWordbookId;
    final playingName = _playbackStore.playingWordbookName;
    if (playingId == null ||
        playingName == null ||
        _playbackStore.playingScopeWords.isEmpty) {
      return;
    }
    final words = List<WordEntry>.from(_playbackStore.playingScopeWords);
    final safeTarget = targetIndex.clamp(0, words.length - 1);
    _playbackStore.playingScopeIndex = safeTarget;
    _playbackStore.playingWord = words[safeTarget].word;
    _rememberPlaybackProgressImpl(words[safeTarget]);
    if (_selectedWordbook?.id == playingId) {
      _setCurrentWordByEntry(words[safeTarget]);
      resetTestModeProgress();
      _notifyStateChanged();
    }
    _playbackStore.playSessionId += 1;
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
    _playbackStore.isPlaying = false;
    _playbackStore.isPaused = false;
    _playbackStore.currentUnit = 0;
    _playbackStore.totalUnits = 0;
    _playbackStore.activeUnit = null;
    _playbackStore.playingWordbookId = null;
    _playbackStore.playingWordbookName = null;
    _playbackStore.playingWord = null;
    _playbackStore.playingScopeWords = <WordEntry>[];
    _playbackStore.playingScopeIndex = 0;
    _playbackStore.queuedPlaybackScopeTarget = null;
    _playbackStore.playbackScopeRestarting = false;
    if (notify) {
      _notifyStateChanged();
    }
  }
}

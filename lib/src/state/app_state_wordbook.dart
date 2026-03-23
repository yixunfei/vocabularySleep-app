part of 'app_state.dart';

extension _AppStateWordbook on AppState {
  void _setSearchQueryImpl(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    _invalidateVisibleWordsCache();
    _ensureCurrentWordInScope();
    _log.d(
      'app_state',
      'set search query',
      data: <String, Object?>{
        'query': value,
        'mode': _searchMode.name,
        'visibleCount': visibleWords.length,
      },
    );
    _notifyStateChanged();
  }

  void _setSearchModeImpl(SearchMode mode) {
    if (_searchMode == mode) return;
    _searchMode = mode;
    _invalidateVisibleWordsCache();
    _ensureCurrentWordInScope();
    _log.d(
      'app_state',
      'set search mode',
      data: <String, Object?>{
        'mode': mode.name,
        'query': _searchQuery,
        'visibleCount': visibleWords.length,
      },
    );
    _notifyStateChanged();
  }

  Future<void> _selectWordbookImpl(
    Wordbook? wordbook, {
    String? focusWord,
    int? focusWordId,
  }) async {
    if (wordbook == null) return;
    final shouldFollowPlayingWord =
        (focusWordId == null) &&
        ((focusWord ?? '').trim().isEmpty) &&
        _isPlaying &&
        _playingWordbookId == wordbook.id &&
        _playingScopeWords.isNotEmpty;
    if (shouldFollowPlayingWord) {
      final playingIndex = _playingScopeIndex.clamp(
        0,
        _playingScopeWords.length - 1,
      );
      final playingEntry = _playingScopeWords[playingIndex];
      focusWordId = playingEntry.id;
      focusWord = playingEntry.word;
    }
    final normalizedFocusWord = focusWord?.trim();
    final previousSelection = _selectedWordbook;
    _log.i(
      'app_state',
      'select wordbook',
      data: <String, Object?>{
        'id': wordbook.id,
        'name': wordbook.name,
        'path': wordbook.path,
        'focusWordId': focusWordId,
        'focusWord': focusWord,
      },
    );
    if (_database.isLazyBuiltInPath(wordbook.path) && wordbook.wordCount <= 0) {
      final lazyWordbookId = wordbook.id;
      final lazyWordbookName = wordbook.name;
      final lazyPath = wordbook.path;
      _setBusy(
        true,
        messageKey: 'busyLoadingWordbook',
        params: <String, Object?>{'name': lazyWordbookName},
      );
      try {
        await _database.ensureBuiltInWordbookLoaded(lazyPath);
        await _reloadWordbooks(keepCurrentSelection: false);
        wordbook =
            _wordbooks
                .where((item) => item.path == lazyPath)
                .cast<Wordbook?>()
                .firstOrNull ??
            wordbook;
      } catch (error, stackTrace) {
        _log.e(
          'app_state',
          'lazy built-in wordbook load failed',
          error: error,
          stackTrace: stackTrace,
          data: <String, Object?>{
            'id': lazyWordbookId,
            'name': lazyWordbookName,
            'path': lazyPath,
          },
        );
        _selectedWordbook = previousSelection;
        _setMessage(
          'errorImportFailed',
          params: <String, Object?>{'error': error},
        );
        return;
      } finally {
        _setBusy(false);
      }
    }
    _selectedWordbook = wordbook;
    _setWords(_database.getWords(wordbook.id));
    if (shouldFollowPlayingWord && _searchQuery.trim().isNotEmpty) {
      final matchesFocusedWord = _scopeWords.any(
        (item) =>
            (focusWordId != null && item.id == focusWordId) ||
            ((normalizedFocusWord ?? '').isNotEmpty &&
                item.word == normalizedFocusWord),
      );
      if (!matchesFocusedWord) {
        _searchQuery = '';
        _invalidateVisibleWordsCache();
      }
    }
    _currentWordIndex = 0;
    if (focusWordId != null) {
      final index = _words.indexWhere((item) => item.id == focusWordId);
      if (index >= 0) {
        _currentWordIndex = index;
      }
    }
    if (_currentWordIndex == 0 && (normalizedFocusWord ?? '').isNotEmpty) {
      final index = _words.indexWhere(
        (item) => item.word == normalizedFocusWord,
      );
      if (index >= 0) {
        _currentWordIndex = index;
      }
    }
    _ensureCurrentWordInScope();
    resetTestModeProgress();
    _notifyStateChanged();
    if (previousSelection?.id != wordbook.id) {
      await _syncPlaybackToSelectedWordbook(wordbook);
    }
  }

  void _selectWordIndexImpl(int index) {
    if (index < 0 || index >= _words.length) return;
    _currentWordIndex = index;
    resetTestModeProgress();
    _notifyStateChanged();
  }

  void _selectWordByTextImpl(String word) {
    final index = _words.indexWhere((item) => item.word == word);
    if (index >= 0) {
      _currentWordIndex = index;
      resetTestModeProgress();
      _notifyStateChanged();
    }
  }

  void _selectWordEntryImpl(WordEntry entry) {
    _setCurrentWordByEntry(entry);
    resetTestModeProgress();
    _notifyStateChanged();
  }
}

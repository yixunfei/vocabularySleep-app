part of 'app_state.dart';

extension _AppStateWordbook on AppState {
  Future<void> _setSearchCriteriaImpl({
    required String query,
    required SearchMode mode,
  }) async {
    if (_searchQuery == query && _searchMode == mode) return;
    _searchQuery = query;
    _searchMode = mode;
    _invalidateVisibleWordsCache();
    _currentWordCacheValid = false;
    if (_shouldSearchWordbookInBackground) {
      await _searchSelectedWordbookInBackground();
      return;
    }
    _wordbookSearchStore.cancel();
    _ensureCurrentWordInScope();
    _notifyStateChanged();
  }

  bool get _shouldSearchWordbookInBackground {
    final selectedWordbook = _selectedWordbook;
    return selectedWordbook != null &&
        _searchQuery.trim().isNotEmpty &&
        _shouldUseLiteWordQueries(selectedWordbook);
  }

  Future<void> _searchSelectedWordbookInBackground() async {
    final selectedWordbook = _selectedWordbook;
    if (selectedWordbook == null || !_shouldSearchWordbookInBackground) {
      return;
    }
    _wordbookSearchStore.schedule(
      wordbookId: selectedWordbook.id,
      query: _searchQuery,
      mode: _searchMode.name,
    );
    _invalidateVisibleWordsCache();
    _currentWordCacheValid = false;
    _notifyStateChanged();

    final activeRunner = _wordbookSearchRunner;
    if (activeRunner != null) {
      await activeRunner;
      return;
    }

    final runner = _drainWordbookSearchRequests();
    _wordbookSearchRunner = runner;
    try {
      await runner;
    } finally {
      if (identical(_wordbookSearchRunner, runner)) {
        _wordbookSearchRunner = null;
      }
    }
  }

  Future<void> _drainWordbookSearchRequests() async {
    while (!_disposed) {
      final request = _wordbookSearchStore.takePendingRequest();
      if (request == null) {
        return;
      }
      final result = await _queryWordbookSearch(request);
      if (!_canCommitWordbookSearch(request) ||
          !_wordbookSearchStore.complete(
            request: request,
            entries: result.entries,
            totalCount: result.totalCount,
          )) {
        continue;
      }
      _invalidateVisibleWordsCache();
      _currentWordCacheValid = false;
      _ensureCurrentWordInScope();
      _notifyStateChanged();
    }
  }

  Future<WordbookSearchResult> _queryWordbookSearch(
    WordbookSearchRequest request,
  ) async {
    try {
      return await _wordbookRepository.searchWordsLiteAsync(
        request.wordbookId,
        query: request.query,
        mode: request.mode,
      );
    } catch (error, stackTrace) {
      _log.e(
        'app_state',
        'background wordbook search failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'wordbookId': request.wordbookId,
          'queryLength': request.query.length,
          'mode': request.mode,
        },
      );
      return const WordbookSearchResult(entries: <WordEntry>[], totalCount: 0);
    }
  }

  bool _canCommitWordbookSearch(WordbookSearchRequest request) {
    final currentWordbook = _selectedWordbook;
    return !_disposed &&
        currentWordbook != null &&
        currentWordbook.id == request.wordbookId &&
        wordbookSearchSignature(
              wordbookId: currentWordbook.id,
              query: _searchQuery,
              mode: _searchMode.name,
            ) ==
            request.signature;
  }

  Future<void> _selectWordbookImpl(
    Wordbook? wordbook, {
    String? focusWord,
    int? focusWordId,
  }) async {
    if (wordbook == null || _disposed) return;
    final loadGeneration = ++_wordbookLoadGeneration;
    _wordbookSearchStore.cancel();
    _currentWordCacheValid = false;
    if (_wordbookLoadBusyGeneration != null) {
      _wordbookLoadBusyGeneration = null;
      _wordbookLoadStore.finish();
      if (_busy) {
        _setBusy(false);
      }
    }
    final shouldFollowPlayingWord =
        (focusWordId == null) &&
        ((focusWord ?? '').trim().isEmpty) &&
        _playbackStore.isPlaying &&
        _playbackStore.playingWordbookId == wordbook.id &&
        _playbackStore.playingScopeWords.isNotEmpty;
    if (shouldFollowPlayingWord) {
      final playingIndex = _playbackStore.playingScopeIndex.clamp(
        0,
        _playbackStore.playingScopeWords.length - 1,
      );
      final playingEntry = _playbackStore.playingScopeWords[playingIndex];
      focusWordId = playingEntry.id;
      focusWord = playingEntry.word;
    }
    final normalizedFocusWord = focusWord?.trim();
    final previousSelection = _selectedWordbook;
    if (_wordbookRepository.isLazyBuiltInPath(wordbook.path) &&
        wordbook.wordCount <= 0) {
      final lazyWordbookId = wordbook.id;
      final lazyWordbookName = wordbook.name;
      final lazyPath = wordbook.path;
      final i18n = AppI18n(_uiLanguage);
      final ownsLazyLoadBusy = !_busy || _wordbookLoadBusyGeneration != null;
      if (ownsLazyLoadBusy) {
        final initialDetail = i18n.t('download');
        _wordbookLoadBusyGeneration = loadGeneration;
        _wordbookLoadStore.start(name: lazyWordbookName, detail: initialDetail);
        _setBusy(
          true,
          messageKey: 'busyLoadingWordbook',
          params: <String, Object?>{'name': lazyWordbookName},
          detail: initialDetail,
          progress: 0,
        );
      }
      try {
        await _wordbookRepository.ensureBuiltInWordbookLoaded(
          lazyPath,
          onProgress: (progress) {
            if (!ownsLazyLoadBusy ||
                _disposed ||
                loadGeneration != _wordbookLoadGeneration) {
              return;
            }
            _wordbookLoadStore.update(
              detail: _busyDetailForWordbookLoadProgress(progress),
              progress: _busyProgressForWordbookLoad(progress),
            );
          },
        );
        if (_disposed || loadGeneration != _wordbookLoadGeneration) {
          return;
        }
        await _reloadWordbooks(keepCurrentSelection: false);
        if (_disposed || loadGeneration != _wordbookLoadGeneration) {
          return;
        }
        wordbook =
            _wordbooks
                .where((item) => item.path == lazyPath)
                .cast<Wordbook?>()
                .firstOrNull ??
            wordbook;
      } catch (error, stackTrace) {
        if (_disposed || loadGeneration != _wordbookLoadGeneration) {
          return;
        }
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
        if (_wordbookLoadBusyGeneration == loadGeneration) {
          _wordbookLoadBusyGeneration = null;
          if (!_disposed) {
            _wordbookLoadStore.finish();
          }
          if (!_disposed && loadGeneration == _wordbookLoadGeneration) {
            _setBusy(false);
          }
        }
      }
    }
    final shouldDeferLargeWordbookLoad =
        _shouldUseLiteWordQueries(wordbook) &&
        focusWordId == null &&
        (normalizedFocusWord ?? '').isEmpty &&
        !shouldFollowPlayingWord;
    if (shouldDeferLargeWordbookLoad) {
      _selectedWordbook = wordbook;
      _clearSelectedWordbookWords();
      _currentWordIndex = 0;
      resetTestModeProgress();
      if (_shouldSearchWordbookInBackground) {
        await _searchSelectedWordbookInBackground();
      } else {
        _notifyStateChanged();
      }
      if (_disposed || loadGeneration != _wordbookLoadGeneration) {
        return;
      }
      if (previousSelection?.id != wordbook.id) {
        await _syncPlaybackToSelectedWordbook(wordbook);
      }
      return;
    }
    final shouldLoadWordbookBusy =
        _loadedWordbookId != wordbook.id &&
        wordbook.wordCount > AppState._startupEagerWordLoadLimit;
    final ownsLocalLoadBusy =
        shouldLoadWordbookBusy &&
        (!_busy || _wordbookLoadBusyGeneration != null);
    if (ownsLocalLoadBusy) {
      _wordbookLoadBusyGeneration = loadGeneration;
      _setBusy(
        true,
        messageKey: 'busyLoadingWordbook',
        params: <String, Object?>{'name': wordbook.name},
        detail: AppI18n(_uiLanguage).t('busyPatienceHint'),
      );
    }
    try {
      _selectedWordbook = wordbook;
      final nextWords = await _queryWordbookEntriesAsync(wordbook);
      if (_disposed || loadGeneration != _wordbookLoadGeneration) {
        return;
      }
      _setWords(nextWords);
    } finally {
      if (_wordbookLoadBusyGeneration == loadGeneration) {
        _wordbookLoadBusyGeneration = null;
        if (!_disposed && loadGeneration == _wordbookLoadGeneration) {
          _setBusy(false);
        }
      }
    }
    if (_shouldSearchWordbookInBackground) {
      await _searchSelectedWordbookInBackground();
      if (_disposed || loadGeneration != _wordbookLoadGeneration) {
        return;
      }
    }
    final restoredProgressIndex =
        (focusWordId == null && (normalizedFocusWord ?? '').isEmpty)
        ? _playbackProgressIndexForWordbook(wordbook)
        : -1;
    if (shouldFollowPlayingWord && _searchQuery.trim().isNotEmpty) {
      final matchesFocusedWord = _scopeWords.any(
        (item) =>
            (focusWordId != null && item.id == focusWordId) ||
            ((normalizedFocusWord ?? '').isNotEmpty &&
                item.word == normalizedFocusWord),
      );
      if (!matchesFocusedWord) {
        _searchQuery = '';
        _wordbookSearchStore.cancel();
        _invalidateVisibleWordsCache();
        _currentWordCacheValid = false;
      }
    }
    _currentWordIndex = restoredProgressIndex >= 0
        ? _indexOfWordEntry(
            _words,
            (_searchQuery.trim().isEmpty
                ? _words
                : _scopeWords)[restoredProgressIndex],
          )
        : 0;
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

  Future<void> _selectWordEntryImpl(WordEntry entry) async {
    final resolved = _hydrateWordEntryIfNeeded(entry);
    _setCurrentWordByEntry(resolved);
    resetTestModeProgress();
    _notifyStateChanged();
  }
}

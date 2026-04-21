part of 'toolbox_soothing_music_v2_page.dart';

extension _SoothingMusicV2Playback on _SoothingMusicV2PageState {
  Future<void> _initAudio() async {
    final prefs = await ToolboxSoothingPrefsService.load();
    if (!mounted) return;
    _SoothingRuntimeStore.favoriteModeIds = Set<String>.from(
      prefs.favoriteModeIds,
    );
    _SoothingRuntimeStore.recentModeIds = List<String>.from(
      prefs.recentModeIds,
    );
    _SoothingRuntimeStore.lastTrackIndexByMode = Map<String, int>.from(
      prefs.lastTrackIndexByMode,
    );
    _SoothingRuntimeStore.lastModeId = prefs.lastModeId;
    _SoothingRuntimeStore.continuePlaybackOnExit = prefs.continuePlaybackOnExit;
    _SoothingRuntimeStore.playbackMode = prefs.playbackMode;
    _SoothingRuntimeStore.arrangementSteps =
        List<SoothingPlaybackArrangementStep>.from(prefs.arrangementSteps);
    _SoothingRuntimeStore.arrangementTemplates =
        List<SoothingPlaybackArrangementTemplate>.from(
          prefs.arrangementTemplates,
        );
    _SoothingRuntimeStore.activeArrangementTemplateId =
        prefs.activeArrangementTemplateId;
    _continuePlaybackOnExit = prefs.continuePlaybackOnExit;
    _mode = _modes.firstWhere(
      (mode) => mode.id == _SoothingRuntimeStore.lastModeId,
      orElse: () => _mode,
    );
    _trackIndex = _restoredTrackIndexForMode(_mode.id);

    await _player.setAudioContext(_soothingAudioContext);
    await _player.setReleaseMode(ReleaseMode.stop);
    if (!mounted) return;
    _volume = _SoothingRuntimeStore.activeVolume;
    _muted = _SoothingRuntimeStore.activeMuted;
    await _player.setVolume(_muted ? 0 : _volume);
    if (!mounted) return;
    if (_SoothingRuntimeStore.retainedPlayer != null &&
        _SoothingRuntimeStore.activeModeId != null) {
      _SoothingRuntimeStore.detachRetainedPlaybackController();
      final retainedModeId = _SoothingRuntimeStore.activeModeId!;
      _mode = _modes.firstWhere(
        (mode) => mode.id == retainedModeId,
        orElse: () => _mode,
      );
      final retainedTracks = _SoothingMusicV2PageState._tracksForMode(_mode.id);
      _trackIndex = retainedTracks.isEmpty
          ? 0
          : _SoothingRuntimeStore.activeTrackIndex.clamp(
              0,
              retainedTracks.length - 1,
            );
      _position = _SoothingRuntimeStore.activePosition;
      _duration = _SoothingRuntimeStore.activeDuration;
      _playing = _SoothingRuntimeStore.activePlaying;
      _playbackIntent = _playing;
      _scene = await ToolboxSoothingAudioService.load(_mode.id);
      _updateStageSpectrum(force: true);
      if (_playing) {
        _orbitController.repeat();
      }
      _SoothingRuntimeStore.notifyChanged();
      if (mounted) {
        _setViewState(() {});
      }
      for (final mode in _modes.where((item) => item.id != _mode.id).take(2)) {
        unawaited(_preloadModeAssets(mode.id));
      }
      return;
    }

    unawaited(_preloadModeAssets(_mode.id));
    if (!mounted) return;
    await _loadMode(_mode, autoplay: false);
    if (!mounted) return;
    for (final mode in _modes.where((item) => item.id != _mode.id).take(2)) {
      unawaited(_preloadModeAssets(mode.id));
    }
  }

  Future<void> _preloadModeAssets(String modeId) async {
    try {
      await _resolvedTrackLoader.preloadMode(modeId);
    } catch (error, stackTrace) {
      _log.w(
        'soothing_audio',
        'preload mode assets failed',
        data: <String, Object?>{'modeId': modeId},
      );
      _log.e(
        'soothing_audio',
        'preload mode assets failure detail',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'modeId': modeId},
      );
    }
  }

  Future<Uint8List> _loadTrackBytes(
    _SoothingTrack track, {
    int? loadToken,
  }) async {
    _trackLoadLabelKey = track.labelKey;
    _trackLoadProgress = null;
    _trackLoadReceivedBytes = 0;
    _trackLoadTotalBytes = 0;
    if (mounted) {
      _setViewState(() {});
    }
    try {
      return await _resolvedTrackLoader.load(
        track,
        onProgress: (progress) {
          if (!mounted || !_isLoadTokenActive(loadToken)) return;
          _setViewState(() {
            _trackLoadLabelKey = track.labelKey;
            _trackLoadProgress = progress.progress;
            _trackLoadReceivedBytes = progress.receivedBytes;
            _trackLoadTotalBytes = progress.totalBytes;
          });
        },
      );
    } finally {
      _clearTrackLoadState(loadToken: loadToken);
    }
  }

  SoothingMusicTrackLoader get _resolvedTrackLoader => _trackLoader ??=
      SoothingMusicTrackLoader(remoteResourceCache: _remoteResourceCache);

  List<_SoothingTrack> get _tracks =>
      _SoothingMusicV2PageState._tracksForMode(_mode.id);
  _SoothingTrack get _currentTrack => _tracks[_trackIndex];

  bool _isLoadTokenActive(int? loadToken) {
    return !_disposed &&
        mounted &&
        (loadToken == null || loadToken == _asyncLoadToken);
  }

  Future<T> _runSerializedPlayerMutation<T>(Future<T> Function() action) {
    final previous = _playerMutationQueue;
    final completer = Completer<void>();
    _playerMutationQueue = completer.future;
    return previous.catchError((_) {}).then((_) => action()).whenComplete(() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
  }

  Future<void> _startArrangementPlayback({bool autoplay = true}) async {
    if (_arrangementSteps.isEmpty) {
      return;
    }
    final firstStep = _arrangementSteps.first;
    _SoothingRuntimeStore.arrangementStepIndex = 0;
    _SoothingRuntimeStore.arrangementStepPlayCount = 0;
    final firstMode = _modes.firstWhere(
      (mode) => mode.id == firstStep.modeId,
      orElse: () => _mode,
    );
    _SoothingRuntimeStore.activeModeId = firstMode.id;
    _SoothingRuntimeStore.activeTrackIndex = firstStep.trackIndex;
    _SoothingRuntimeStore.notifyChanged();
    if (_mode.id != firstMode.id) {
      await _loadMode(
        firstMode,
        autoplay: autoplay,
        preferredTrackIndex: firstStep.trackIndex,
      );
      return;
    }
    if (_trackIndex != firstStep.trackIndex) {
      await _setTrackIndex(firstStep.trackIndex, autoplayOverride: autoplay);
      return;
    }
    if (autoplay) {
      await _seekToRatio(0);
      await _player.resume();
      _SoothingRuntimeStore.activePlaying = true;
      _SoothingRuntimeStore.notifyChanged();
    } else {
      await _player.stop();
      _SoothingRuntimeStore.activePlaying = false;
      _SoothingRuntimeStore.notifyChanged();
    }
  }

  Future<void> _loadMode(
    _SoothingModeTheme mode, {
    required bool autoplay,
    int? preferredTrackIndex,
  }) async {
    if (!mounted) return;
    final tracks = _SoothingMusicV2PageState._tracksForMode(mode.id);
    if (tracks.isEmpty) {
      return;
    }
    final loadToken = ++_asyncLoadToken;
    final restoredTrackIndex =
        preferredTrackIndex?.clamp(0, tracks.length - 1).toInt() ??
        _restoredTrackIndexForMode(mode.id);
    final shouldAutoplay =
        autoplay || _playbackMode == SoothingPlaybackMode.arrangement;
    _setViewState(() {
      _mode = mode;
      _trackIndex = restoredTrackIndex;
      _loading = true;
      _position = Duration.zero;
      _draggingRatio = null;
      _playbackIntent = shouldAutoplay;
      _resetStageSpectrum();
      _clearAudioError();
    });

    try {
      final scene = await ToolboxSoothingAudioService.load(mode.id);
      if (!_isLoadTokenActive(loadToken)) {
        return;
      }
      final track = tracks[restoredTrackIndex];
      final bytes = await _loadTrackBytes(track, loadToken: loadToken);
      if (!_isLoadTokenActive(loadToken)) {
        return;
      }
      final duration = await _runSerializedPlayerMutation<Duration?>(() async {
        if (!_isLoadTokenActive(loadToken)) {
          return null;
        }
        await _player.stop();
        await AudioPlayerSourceHelper.setSource(
          _player,
          BytesSource(bytes, mimeType: 'audio/mp4'),
          tag: 'soothing_audio',
          data: <String, Object?>{
            'modeId': mode.id,
            'trackAssetPath': track.assetPath,
            'bytes': bytes.length,
          },
        );
        final resolvedDuration = await AudioPlayerSourceHelper.waitForDuration(
          _player,
          tag: 'soothing_audio',
          data: <String, Object?>{
            'modeId': mode.id,
            'trackAssetPath': track.assetPath,
            'playerId': _player.playerId,
          },
        );
        await _player.setVolume(_muted ? 0 : _volume);
        if (_isLoadTokenActive(loadToken)) {
          if (shouldAutoplay) {
            await _player.seek(Duration.zero);
            await _player.resume();
            await Future<void>.delayed(const Duration(milliseconds: 50));
          } else {
            await _player.stop();
          }
        }
        return resolvedDuration;
      });
      if (duration != null) {
        _duration = duration;
      }
      _updateStageSpectrum(force: true);
      _SoothingRuntimeStore.activeDuration = _duration;
      if (!_isLoadTokenActive(loadToken)) return;
      _SoothingRuntimeStore.lastTrackIndexByMode[mode.id] = restoredTrackIndex;
      _SoothingRuntimeStore.lastModeId = mode.id;
      _SoothingRuntimeStore.activeModeId = mode.id;
      _SoothingRuntimeStore.activeTrackIndex = restoredTrackIndex;
      _SoothingRuntimeStore.activeVolume = _volume;
      _SoothingRuntimeStore.activeMuted = _muted;
      _SoothingRuntimeStore.activePlaying = shouldAutoplay;
      _setViewState(() {
        _scene = scene;
        _playing = shouldAutoplay;
        _updateStageSpectrum(force: true);
      });
      _SoothingRuntimeStore.notifyChanged();
      _rememberRecent(mode.id);
    } catch (error, stackTrace) {
      _log.e(
        'soothing_audio',
        'load mode failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'modeId': mode.id,
          'trackIndex': restoredTrackIndex,
          'playerId': _player.playerId,
        },
      );
      if (!_isLoadTokenActive(loadToken)) return;
      _setViewState(() {
        _audioErrorLabelKey = 'mode:${mode.id}';
        _playing = false;
        _playbackIntent = false;
      });
    } finally {
      if (mounted && loadToken == _asyncLoadToken) {
        _setViewState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (_loading) return;
    if (_scene == null) {
      _playbackIntent = true;
      await _loadMode(_mode, autoplay: true);
      return;
    }
    if (_playing) {
      _playbackIntent = false;
      await _runSerializedPlayerMutation<void>(() async {
        await _player.pause();
      });
      _setViewState(() {
        _playing = false;
      });
      _SoothingRuntimeStore.activePlaying = false;
      _SoothingRuntimeStore.notifyChanged();
      _orbitController.stop();
      return;
    }
    // CRITICAL FIX: Wait for player to be ready before resuming.
    // Without this, resume() may be called before the audio source is loaded,
    // causing no sound output.
    _playbackIntent = true;
    try {
      await AudioPlayerSourceHelper.waitForDuration(
        _player,
        tag: 'soothing_audio',
        data: <String, Object?>{
          'playerId': _player.playerId,
          'modeId': _mode.id,
        },
        timeout: const Duration(seconds: 5),
      );
      await _runSerializedPlayerMutation<void>(() async {
        await _player.resume();
      });
      _setViewState(() {
        _playing = true;
      });
      _rememberRecent(_mode.id);
      _SoothingRuntimeStore.activePlaying = true;
      _SoothingRuntimeStore.notifyChanged();
      _orbitController.repeat();
    } catch (error, stackTrace) {
      _playbackIntent = false;
      _setViewState(() {
        _playing = false;
      });
      _log.e(
        'soothing_audio',
        'toggle playback failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'modeId': _mode.id,
          'trackIndex': _trackIndex,
          'playerId': _player.playerId,
        },
      );
    }
  }

  Future<void> _handlePlaybackCompletion() async {
    if (_handlingPlaybackCompletion) {
      return;
    }
    _handlingPlaybackCompletion = true;
    try {
      switch (_playbackMode) {
        case SoothingPlaybackMode.singleLoop:
          _playbackIntent = true;
          await _seekToRatio(0);
          await _player.resume();
          _SoothingRuntimeStore.activePlaying = true;
          _SoothingRuntimeStore.notifyChanged();
          if (mounted) {
            _setViewState(() {
              _position = Duration.zero;
              _updateStageSpectrum(force: true);
            });
          }
          return;
        case SoothingPlaybackMode.modeCycle:
          if (_tracks.length <= 1) {
            _playbackIntent = true;
            await _seekToRatio(0);
            await _player.resume();
            _SoothingRuntimeStore.activePlaying = true;
            _SoothingRuntimeStore.notifyChanged();
            return;
          }
          await _stepTrack(1, autoplayOverride: true);
          return;
        case SoothingPlaybackMode.arrangement:
          await _advanceArrangement();
          return;
      }
    } finally {
      if (_playbackMode == SoothingPlaybackMode.arrangement && _loading) {
        final deadline = DateTime.now().add(const Duration(seconds: 10));
        while (_loading && DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      }
      _handlingPlaybackCompletion = false;
    }
  }

  Future<void> _advanceArrangement() async {
    if (_arrangementSteps.isEmpty) {
      _setPlaybackMode(SoothingPlaybackMode.singleLoop);
      await _handlePlaybackCompletion();
      return;
    }
    final currentIndex = _SoothingRuntimeStore.arrangementStepIndex.clamp(
      0,
      _arrangementSteps.length - 1,
    );
    final currentStep = _arrangementSteps[currentIndex];
    final playedCount = _SoothingRuntimeStore.arrangementStepPlayCount + 1;
    if (playedCount < currentStep.repeatCount) {
      _SoothingRuntimeStore.arrangementStepPlayCount = playedCount;
      await _seekToRatio(0);
      await _player.resume();
      _SoothingRuntimeStore.activePlaying = true;
      _SoothingRuntimeStore.notifyChanged();
      if (mounted) {
        _setViewState(() {
          _position = Duration.zero;
        });
      }
      return;
    }

    final nextIndex = (currentIndex + 1) % _arrangementSteps.length;
    final nextStep = _arrangementSteps[nextIndex];
    _SoothingRuntimeStore.arrangementStepIndex = nextIndex;
    _SoothingRuntimeStore.arrangementStepPlayCount = 0;

    final nextMode = _modes.firstWhere(
      (mode) => mode.id == nextStep.modeId,
      orElse: () => _mode,
    );
    if (_mode.id != nextMode.id) {
      await _loadMode(
        nextMode,
        autoplay: true,
        preferredTrackIndex: nextStep.trackIndex,
      );
      return;
    }
    if (_trackIndex == nextStep.trackIndex) {
      await _seekToRatio(0);
      await _player.resume();
      _SoothingRuntimeStore.activePlaying = true;
      _SoothingRuntimeStore.notifyChanged();
      if (mounted) {
        _setViewState(() {
          _position = Duration.zero;
        });
      }
      return;
    }
    await _setTrackIndex(nextStep.trackIndex, autoplayOverride: true);
  }

  Future<void> _setMode(
    _SoothingModeTheme mode, {
    bool? autoplayOverride,
    int? preferredTrackIndex,
  }) async {
    if (_mode.id == mode.id && _scene != null) return;
    final shouldAutoplay = SoothingPlaybackIntentPolicy.resolveShouldAutoplay(
      playing: _playing,
      playbackIntent: _playbackIntent,
      override: autoplayOverride,
    );
    await _loadMode(
      mode,
      autoplay: shouldAutoplay,
      preferredTrackIndex: preferredTrackIndex,
    );
  }

  Future<void> _setTrackIndex(int index, {bool? autoplayOverride}) async {
    if (index == _trackIndex) return;
    if (!mounted) return;
    if (_tracks.isEmpty) return;
    final shouldResume = SoothingPlaybackIntentPolicy.resolveShouldAutoplay(
      playing: _playing,
      playbackIntent: _playbackIntent,
      override: autoplayOverride,
    );
    final loadToken = ++_asyncLoadToken;
    final nextTrackIndex = index.clamp(0, _tracks.length - 1);
    late final _SoothingTrack track;
    _setViewState(() {
      _trackIndex = nextTrackIndex;
      _loading = true;
      _playbackIntent = shouldResume;
      _position = Duration.zero;
      _draggingRatio = null;
      _resetStageSpectrum();
      _clearAudioError();
    });

    try {
      track = _currentTrack;
      final bytes = await _loadTrackBytes(track, loadToken: loadToken);
      if (!_isLoadTokenActive(loadToken)) {
        return;
      }
      final duration = await _runSerializedPlayerMutation<Duration?>(() async {
        if (!_isLoadTokenActive(loadToken)) {
          return null;
        }
        await _player.stop();
        await AudioPlayerSourceHelper.setSource(
          _player,
          BytesSource(bytes, mimeType: 'audio/mp4'),
          tag: 'soothing_audio',
          data: <String, Object?>{
            'modeId': _mode.id,
            'trackAssetPath': track.assetPath,
            'bytes': bytes.length,
          },
        );
        final resolvedDuration = await AudioPlayerSourceHelper.waitForDuration(
          _player,
          tag: 'soothing_audio',
          data: <String, Object?>{
            'modeId': _mode.id,
            'trackAssetPath': track.assetPath,
            'playerId': _player.playerId,
          },
        );
        await _player.setVolume(_muted ? 0 : _volume);
        if (_isLoadTokenActive(loadToken)) {
          if (shouldResume) {
            await _player.seek(Duration.zero);
            await _player.resume();
          } else {
            await _player.stop();
          }
        }
        return resolvedDuration;
      });
      if (duration != null) {
        _duration = duration;
      }
      _updateStageSpectrum(force: true);
      _SoothingRuntimeStore.activeDuration = _duration;
      if (!_isLoadTokenActive(loadToken)) return;
      _SoothingRuntimeStore.activePlaying = shouldResume;
      _setViewState(() {
        _playing = shouldResume;
      });
    } catch (error, stackTrace) {
      _log.e(
        'soothing_audio',
        'set track failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'modeId': _mode.id,
          'trackIndex': _trackIndex,
          'trackAssetPath': track.assetPath,
          'playerId': _player.playerId,
        },
      );
      if (!_isLoadTokenActive(loadToken)) return;
      _setViewState(() {
        _audioErrorLabelKey = 'track:${track.labelKey}';
        _playing = false;
        _playbackIntent = false;
      });
    } finally {
      if (mounted && loadToken == _asyncLoadToken) {
        _setViewState(() {
          _loading = false;
        });
      }
    }

    _SoothingRuntimeStore.lastTrackIndexByMode[_mode.id] = _trackIndex;
    _SoothingRuntimeStore.lastModeId = _mode.id;
    _SoothingRuntimeStore.activeTrackIndex = _trackIndex;
    _SoothingRuntimeStore.notifyChanged();
    unawaited(_persistPrefs());
  }

  Future<void> _stepTrack(int delta, {bool? autoplayOverride}) async {
    if (_tracks.length <= 1) return;
    final shouldResume = SoothingPlaybackIntentPolicy.resolveShouldAutoplay(
      playing: _playing,
      playbackIntent: _playbackIntent,
      override: autoplayOverride,
    );
    final nextIndex = (_trackIndex + delta) % _tracks.length;
    await _setTrackIndex(
      nextIndex < 0 ? nextIndex + _tracks.length : nextIndex,
      autoplayOverride: shouldResume,
    );
  }

  void _toggleFavorite(String modeId) {
    _setViewState(() {
      if (_SoothingRuntimeStore.favoriteModeIds.contains(modeId)) {
        _SoothingRuntimeStore.favoriteModeIds.remove(modeId);
      } else {
        _SoothingRuntimeStore.favoriteModeIds.add(modeId);
      }
    });
    unawaited(_persistPrefs());
  }

  void _rememberRecent(String modeId) {
    _SoothingRuntimeStore.recentModeIds.remove(modeId);
    _SoothingRuntimeStore.recentModeIds.insert(0, modeId);
    if (_SoothingRuntimeStore.recentModeIds.length > 6) {
      _SoothingRuntimeStore.recentModeIds.removeRange(
        6,
        _SoothingRuntimeStore.recentModeIds.length,
      );
    }
    _SoothingRuntimeStore.lastModeId = modeId;
    _SoothingRuntimeStore.notifyChanged();
    unawaited(_persistPrefs());
  }

  Future<void> _setMuted(bool value) async {
    _setViewState(() {
      _muted = value;
    });
    _SoothingRuntimeStore.activeMuted = value;
    _SoothingRuntimeStore.notifyChanged();
    await _player.setVolume(value ? 0 : _volume);
    unawaited(_persistPrefs());
  }

  Future<void> _setVolume(double value) async {
    _setViewState(() {
      _volume = value;
    });
    _SoothingRuntimeStore.activeVolume = value;
    _SoothingRuntimeStore.notifyChanged();
    if (!_muted) {
      await _player.setVolume(value);
    }
    unawaited(_persistPrefs());
  }
}

part of 'toolbox_breathing_tool.dart';

const String _diaphragmScenarioId = 'diaphragm_4262';
const Duration _breathingSystemCueFallbackCap = Duration(seconds: 12);
const Duration _breathingSystemCueCancellationPoll = Duration(milliseconds: 80);

extension _BreathingVoiceHelpers on _BreathingPracticeReleaseCardState {
  List<String> _localeTags(Locale locale) {
    final language = locale.languageCode.trim().toLowerCase();
    final country = (locale.countryCode ?? '').trim().toLowerCase();
    final tags = <String>{};
    if (language.isNotEmpty && country.isNotEmpty) {
      tags.add('$language-$country');
      tags.add('${language}_$country');
    }
    if (language.isNotEmpty) {
      tags.add(language);
    }
    if (language == 'zh') {
      tags.add('zh-cn');
      tags.add('zh_cn');
    }
    tags.add('default');
    return tags.toList(growable: false);
  }

  bool _localeUsesChineseVoice(Locale locale) {
    return locale.languageCode.trim().toLowerCase() == 'zh';
  }

  Future<void> _maybeShowNonChineseVoiceNotice() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted ||
        !_voiceOn ||
        _voiceLocaleDialogOpen ||
        _voiceLocaleNoticeShown) {
      return;
    }
    final locale = Localizations.maybeLocaleOf(context);
    if (locale == null || _localeUsesChineseVoice(locale)) {
      return;
    }
    final i18n = AppI18n(locale.languageCode);
    _voiceLocaleDialogOpen = true;
    final keepVoice = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(i18n.t('toolbox.breathing.voice_only_chinese_title')),
          content: Text(i18n.t('toolbox.breathing.voice_only_chinese_body')),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(i18n.t('toolbox.breathing.turn_voice_off')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(i18n.t('toolbox.breathing.keep_chinese_voice')),
            ),
          ],
        );
      },
    );
    _voiceLocaleDialogOpen = false;
    if (!mounted) {
      return;
    }
    _updateState(() => _voiceLocaleNoticeShown = true);
    if (keepVoice == false) {
      await _setVoiceEnabled(false, showLocaleNotice: false);
    }
  }

  String? _effectiveCueIdForStage(
    BreathingStagePlan stage, {
    bool preferOpeningCue = false,
  }) {
    if (preferOpeningCue) {
      final openingCueId = _openingCueIdForStage(stage);
      if (openingCueId != null) {
        return openingCueId;
      }
    }
    if (stage.kind == BreathingStageKind.rest) {
      return null;
    }
    if (stage.kind == BreathingStageKind.hold && !_includeHoldStage) {
      return null;
    }
    if (stage.seconds <= 2) {
      return switch (stage.kind) {
        BreathingStageKind.inhale => 'inhale_soft',
        BreathingStageKind.exhale => 'exhale_soft',
        BreathingStageKind.hold => 'hold_soft',
        BreathingStageKind.rest => null,
      };
    }
    return stage.cueId;
  }

  String? _openingCueIdForStage(BreathingStagePlan stage) {
    if (_scenario.id == _diaphragmScenarioId &&
        _scenarioStageIndex(stage) == 0 &&
        stage.kind == BreathingStageKind.inhale) {
      return 'preview_nose_slow';
    }
    return null;
  }

  int _scenarioStageIndex(BreathingStagePlan stage) {
    final originalIndex = _scenario.stages.indexOf(stage);
    if (originalIndex >= 0) {
      return originalIndex;
    }
    return _stageIndex;
  }

  Duration _cueSafetyPaddingForStage(BreathingStagePlan stage) {
    if (stage.seconds <= 2) {
      return Duration.zero;
    }
    if (stage.seconds <= 4) {
      return const Duration(milliseconds: 80);
    }
    return const Duration(milliseconds: 180);
  }

  Duration? _resolvedCueDuration(BreathingResolvedCue resolved) {
    return resolved.duration ??
        (resolved.cue.approxDurationMs > 0
            ? Duration(milliseconds: resolved.cue.approxDurationMs)
            : null);
  }

  double _cuePlaybackRateForStage(
    BreathingStagePlan stage,
    BreathingResolvedCue resolved,
  ) {
    final cueDuration = _resolvedCueDuration(resolved);
    if (cueDuration == null || cueDuration <= Duration.zero) {
      return 1.0;
    }
    final paddingMs = _cueSafetyPaddingForStage(stage).inMilliseconds;
    final targetWindowMs = math.max(240, stage.seconds * 1000 - paddingMs);
    final maxRate = _maxCuePlaybackRateForStage(stage);
    return (cueDuration.inMilliseconds / targetWindowMs)
        .clamp(1.0, maxRate)
        .toDouble();
  }

  double _maxCuePlaybackRateForStage(BreathingStagePlan stage) {
    if (stage.seconds <= 1) {
      return 1.55;
    }
    if (stage.seconds <= 2) {
      return 1.4;
    }
    return switch (stage.kind) {
      BreathingStageKind.hold => 1.25,
      BreathingStageKind.inhale => 1.35,
      BreathingStageKind.exhale => 1.35,
      BreathingStageKind.rest => 1.0,
    };
  }

  bool _canPlayResolvedCueForStage(
    BreathingStagePlan stage,
    BreathingResolvedCue resolved,
  ) {
    final cueDuration = _resolvedCueDuration(resolved);
    if (cueDuration == null) {
      return false;
    }
    final playbackRate = _cuePlaybackRateForStage(stage, resolved);
    final adjustedDurationMs =
        cueDuration.inMilliseconds / playbackRate.clamp(0.75, 2.0);
    return stage.seconds * 1000 >=
        adjustedDurationMs.round() +
            _cueSafetyPaddingForStage(stage).inMilliseconds;
  }

  Future<BreathingResolvedCue?> _resolveStageCueForStage(
    BreathingStagePlan stage, {
    bool preferOpeningCue = false,
  }) async {
    final cueId = _effectiveCueIdForStage(
      stage,
      preferOpeningCue: preferOpeningCue,
    );
    if (cueId == null) {
      return null;
    }
    final repo = _cueRepo;
    if (repo == null || !mounted) {
      return null;
    }
    return repo.resolveScenarioStage(
      _scenario.id,
      stageIndex: _scenarioStageIndex(stage),
      stageKind: stage.kind,
      fallbackCueId: cueId,
      languageTags: _localeTags(Localizations.localeOf(context)),
    );
  }

  Future<void> _warmScenarioCues() async {
    if (!mounted || !_voiceOn) {
      if (mounted) {
        _updateState(
          () => _voiceAvailability = _BreathingVoiceAvailability.off,
        );
      }
      return;
    }
    final repo = _cueRepo;
    if (repo == null) {
      return;
    }
    final localeTags = _localeTags(Localizations.localeOf(context));
    final scenarioId = _scenario.id;
    final includeRecoveryStage = _includeRecoveryStage;
    final includeHoldStage = _includeHoldStage;
    const flowCueIds = <String>[
      'session_start',
      'session_complete',
      'bolt_prepare',
      'bolt_start',
      'bolt_stop',
      'bolt_recover',
    ];
    final expectedCueCount =
        _loopStages
            .where((stage) => _effectiveCueIdForStage(stage) != null)
            .length +
        (_scenario.previewCueId == null ? 0 : 1);
    _updateState(() {
      _voiceAvailability = _BreathingVoiceAvailability.checking;
      _expectedCueCount = expectedCueCount;
      _shortStageSilentCount = 0;
    });
    final resolved = <BreathingResolvedCue>[];
    var silentShortCueCount = 0;
    final previewCueId = _scenario.previewCueId;
    if (previewCueId != null) {
      final preview = await repo.resolve(
        previewCueId,
        languageTags: localeTags,
      );
      if (preview != null) {
        resolved.add(preview);
      }
    }
    for (final stage in _loopStages) {
      final stageCue = await _resolveStageCueForStage(stage);
      if (stageCue == null) {
        continue;
      }
      if (_canPlayResolvedCueForStage(stage, stageCue)) {
        resolved.add(stageCue);
      } else {
        silentShortCueCount += 1;
      }
    }
    await repo.warmUpCueIds(flowCueIds, languageTags: localeTags);
    if (!mounted ||
        !_voiceOn ||
        _scenario.id != scenarioId ||
        _includeRecoveryStage != includeRecoveryStage ||
        _includeHoldStage != includeHoldStage) {
      return;
    }
    _updateState(() {
      _availableCueCount = resolved.length;
      _expectedCueCount = expectedCueCount;
      _shortStageSilentCount = silentShortCueCount;
      _voiceAvailability = resolved.isNotEmpty
          ? _BreathingVoiceAvailability.ready
          : _BreathingVoiceAvailability.unavailable;
      _voiceSourceKind = resolved.isNotEmpty ? resolved.first.kind : null;
      _lastVoiceLocation = resolved.isNotEmpty ? resolved.first.location : null;
    });
  }

  Future<bool> _playResolvedCue(
    BreathingResolvedCue resolved, {
    required AudioPlayer player,
    required bool respectVoiceSetting,
    double playbackRate = 1.0,
  }) async {
    if (respectVoiceSetting && !_voiceOn) {
      return false;
    }
    final repo = _cueRepo;
    if (repo == null || !mounted) {
      return false;
    }
    try {
      if (respectVoiceSetting && !_voiceOn) {
        return false;
      }
      await player.stop();
      final normalizedRate = playbackRate.clamp(0.75, 2.0).toDouble();
      await AudioPlayerSourceHelper.play(
        player,
        resolved.source,
        volume: 1.0,
        playbackRate: normalizedRate,
        tag: 'breathing_voice',
        data: <String, Object?>{
          'cueId': resolved.cue.id,
          'sourceKind': resolved.kind.name,
          'location': resolved.location,
          'respectVoiceSetting': respectVoiceSetting,
          'playbackRate': normalizedRate,
        },
      );
      if (mounted) {
        _updateState(() {
          _voiceAvailability = _BreathingVoiceAvailability.ready;
          _voiceSourceKind = resolved.kind;
          _lastVoiceLocation = resolved.location;
        });
      }
      return true;
    } catch (_) {
      if (resolved.kind == BreathingCueSourceKind.remote) {
        await _invalidateRemoteCue(resolved.location);
      }
      if (mounted && respectVoiceSetting) {
        _updateState(
          () => _voiceAvailability = _BreathingVoiceAvailability.unavailable,
        );
      }
      return false;
    }
  }

  Future<void> _invalidateRemoteCue(String remoteKey) async {
    final resourceCache = _resourceCache;
    if (resourceCache != null) {
      try {
        await resourceCache.deleteCachedFile(
          remoteKey,
          cacheRelativePath: remoteKey,
        );
      } catch (_) {}
    }
    final repo = _cueRepo;
    if (repo != null) {
      await repo.invalidateRemoteCue(remoteKey);
    }
  }

  Future<bool> _playCueId(
    String cueId, {
    required AudioPlayer player,
    required bool respectVoiceSetting,
    double playbackRate = 1.0,
  }) async {
    if (respectVoiceSetting && !_voiceOn) {
      return false;
    }
    if (_cueRepo == null || !mounted) {
      return false;
    }
    final resolved = await _cueRepo!.resolve(
      cueId,
      languageTags: _localeTags(Localizations.localeOf(context)),
    );
    if (resolved == null) {
      if (mounted && respectVoiceSetting) {
        _updateState(
          () => _voiceAvailability = _BreathingVoiceAvailability.unavailable,
        );
      }
      return false;
    }
    return _playResolvedCue(
      resolved,
      player: player,
      respectVoiceSetting: respectVoiceSetting,
      playbackRate: playbackRate,
    );
  }

  Duration _resolvedCueDurationOrFallback(
    BreathingResolvedCue resolved, {
    Duration fallback = const Duration(milliseconds: 1200),
  }) {
    return _resolvedCueDuration(resolved) ?? fallback;
  }

  Future<void> _stopSystemCue() async {
    _systemCueSequenceToken += 1;
    try {
      await _systemPlayer.stop();
    } catch (_) {}
  }

  Duration _boundedSystemCueFallback(Duration duration) {
    if (duration <= Duration.zero) {
      return const Duration(milliseconds: 1200);
    }
    if (duration > _breathingSystemCueFallbackCap) {
      return _breathingSystemCueFallbackCap;
    }
    return duration;
  }

  Future<bool> _waitForSystemCueCompletion({
    required int sequenceToken,
    required Duration fallbackDuration,
    required Duration gap,
  }) async {
    if (!mounted || _systemCueSequenceToken != sequenceToken) {
      return false;
    }

    final completion = Completer<bool>();
    StreamSubscription<void>? completionSubscription;
    Timer? fallbackTimer;
    Timer? cancellationTimer;
    Timer? gapTimer;
    var playbackCompleted = false;

    bool sequenceIsActive() {
      return mounted && _systemCueSequenceToken == sequenceToken;
    }

    void finish(bool active) {
      if (!completion.isCompleted) {
        completion.complete(active);
      }
    }

    void handlePlaybackComplete() {
      if (playbackCompleted || completion.isCompleted) {
        return;
      }
      playbackCompleted = true;
      fallbackTimer?.cancel();
      if (gap <= Duration.zero) {
        finish(sequenceIsActive());
        return;
      }
      gapTimer = Timer(gap, () => finish(sequenceIsActive()));
    }

    completionSubscription = _systemPlayer.onPlayerComplete.listen(
      (_) => handlePlaybackComplete(),
      onError: (_, _) {
        // A missing completion event is covered by the bounded fallback timer.
      },
      onDone: () => finish(false),
      cancelOnError: false,
    );
    fallbackTimer = Timer(
      _boundedSystemCueFallback(fallbackDuration) + gap,
      () => finish(sequenceIsActive()),
    );
    cancellationTimer = Timer.periodic(_breathingSystemCueCancellationPoll, (
      _,
    ) {
      if (!sequenceIsActive()) {
        finish(false);
      }
    });

    // A very short cue may have completed before the subscription was added.
    if (_systemPlayer.state == PlayerState.completed) {
      handlePlaybackComplete();
    }

    try {
      return await completion.future;
    } finally {
      fallbackTimer.cancel();
      cancellationTimer.cancel();
      gapTimer?.cancel();
      await completionSubscription.cancel();
    }
  }

  Future<void> _playSystemCueSequence(
    List<String> cueIds, {
    bool respectVoiceSetting = true,
    Duration gap = const Duration(milliseconds: 140),
  }) async {
    if (respectVoiceSetting && !_voiceOn) {
      return;
    }
    if (_cueRepo == null || !mounted) {
      return;
    }
    final sequenceToken = _systemCueSequenceToken + 1;
    _systemCueSequenceToken = sequenceToken;
    await _stopPreview();
    try {
      await _systemPlayer.stop();
    } catch (_) {}
    for (final cueId in cueIds) {
      if (!mounted || _systemCueSequenceToken != sequenceToken) {
        return;
      }
      final resolved = await _cueRepo!.resolve(
        cueId,
        languageTags: _localeTags(Localizations.localeOf(context)),
      );
      if (resolved == null) {
        continue;
      }
      final played = await _playResolvedCue(
        resolved,
        player: _systemPlayer,
        respectVoiceSetting: respectVoiceSetting,
      );
      if (!played) {
        continue;
      }
      final sequenceIsActive = await _waitForSystemCueCompletion(
        sequenceToken: sequenceToken,
        fallbackDuration: _resolvedCueDurationOrFallback(resolved),
        gap: gap,
      );
      if (!sequenceIsActive) {
        return;
      }
    }
  }

  Future<void> _stopPreview() async {
    if (_previewing && mounted) {
      _updateState(() => _previewing = false);
    }
    try {
      await _previewPlayer.stop();
    } catch (_) {}
  }

  Future<void> _previewScenarioCue() async {
    final cueId = _scenario.previewCueId;
    if (cueId == null || _running) {
      return;
    }
    if (_previewing) {
      await _stopPreview();
      return;
    }
    await _cuePlayer.stop();
    if (mounted) {
      _updateState(() => _previewing = true);
    }
    final played = await _playCueId(
      cueId,
      player: _previewPlayer,
      respectVoiceSetting: false,
    );
    if (!played && mounted) {
      _updateState(() => _previewing = false);
    }
  }

  void _performHaptic() {
    if (!_hapticOn) {
      return;
    }
    switch (_stage.kind) {
      case BreathingStageKind.hold:
        HapticFeedback.lightImpact();
      case BreathingStageKind.inhale:
      case BreathingStageKind.exhale:
      case BreathingStageKind.rest:
        HapticFeedback.selectionClick();
    }
  }

  Future<void> _announceStage() async {
    _performHaptic();
    final resolved = await _resolveStageCueForStage(
      _stage,
      preferOpeningCue: _stageIndex == 0 && _rounds == 0,
    );
    if (resolved == null || !_canPlayResolvedCueForStage(_stage, resolved)) {
      return;
    }
    await _playResolvedCue(
      resolved,
      player: _cuePlayer,
      respectVoiceSetting: true,
      playbackRate: _cuePlaybackRateForStage(_stage, resolved),
    );
  }

  Duration get _boltElapsed =>
      Duration(milliseconds: _boltStopwatch.elapsedMilliseconds);
}

part of '../toolbox_sound_tools.dart';

// ignore_for_file: dead_code, unused_element, unused_local_variable

extension _FocusBeatsToolStateLogicX on _FocusBeatsToolState {
  Future<void> _loadPrefs() async {
    final prefs = await ToolboxFocusBeatsPrefsService.load();
    if (!mounted) return;
    _setViewState(() {
      _bpm = prefs.bpm;
      _beatsPerBar = prefs.beatsPerBar;
      _subdivision = prefs.subdivision;
      _soundKind = _FocusBeatSoundKind.fromId(prefs.soundId);
      _animationKind = _FocusBeatAnimationKind.fromId(prefs.animationId);
      _linkAnimationAndSound = prefs.linkedSelection;
      _patternController.text = prefs.patternText;
      _patternEnabled = prefs.patternEnabled;
      _masterVolume = prefs.masterVolume;
      _accentVolume = prefs.accentVolume;
      _regularVolume = prefs.regularVolume;
      _subdivisionVolume = prefs.subdivisionVolume;
      _hapticsEnabled = prefs.hapticsEnabled;
      _savedTemplates = prefs.arrangementTemplates;
      _activeTemplateId = prefs.activeArrangementTemplateId;
      final loaded = _loadPatternFromText(
        prefs.patternText,
        showErrorIfInvalid: false,
      );
      if (!loaded) {
        _arrangementBeats = <int>[_beatsPerBar, _beatsPerBar];
        _syncPatternFromArrangement(syncTemplate: false);
      }
      if (_activeTemplateId != null &&
          !_savedTemplates.any((item) => item.id == _activeTemplateId)) {
        _activeTemplateId = null;
      }
      if (_linkAnimationAndSound) {
        _soundKind = _pairedSoundForAnimation(_animationKind);
      }
      _resetRuntime();
    });
    _syncPulseAnimationDuration();
    await _rebuildPlayers();
  }

  Future<void> _rebuildPlayers() async {
    final oldPlayers = _players.values.toList(growable: false);
    _players = <int, ToolboxRealisticEffectPlayer>{
      for (final layer in <int>[0, 1, 2, 3])
        layer: ToolboxRealisticEffectPlayer.build(
          variants: _FocusBeatsToolState._focusBeatVariants,
          bytesForVariant: (variant) => ToolboxAudioBank.focusBeatClick(
            style: _soundKind.id,
            layer: layer,
            variant: variant,
          ),
          maxPlayers: 3,
          volumeJitter: 0.05,
        ),
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final player in _players.values) {
        unawaited(player.warmUp());
      }
    });
    for (final player in oldPlayers) {
      unawaited(player.dispose());
    }
  }

  void _scheduleSavePrefs() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 360), () {
      unawaited(ToolboxFocusBeatsPrefsService.save(_prefsState));
    });
  }

  void _syncPulseAnimationDuration() {
    _pulseController.duration = Duration(microseconds: _pulseIntervalUs);
  }

  String _animationLabel(_FocusBeatAnimationKind kind) {
    return switch (kind) {
      _FocusBeatAnimationKind.pendulum => '暖色轨道 Warm Path',
      _FocusBeatAnimationKind.hypno => '静蓝环线 Still Orbit',
      _FocusBeatAnimationKind.dew => '清水脉络 Clear Wave',
      _FocusBeatAnimationKind.gear => '精密刻度 Precision Mark',
      _FocusBeatAnimationKind.steps => '步阵路径 Step Array',
    };
  }

  String _soundLabel(_FocusBeatSoundKind kind) {
    return switch (kind) {
      _FocusBeatSoundKind.pendulum => '钟摆 Click',
      _FocusBeatSoundKind.hypno => '呼吸 Pulse',
      _FocusBeatSoundKind.dew => '露滴 Drop',
      _FocusBeatSoundKind.gear => '机械 Tick',
      _FocusBeatSoundKind.steps => '步伐 Step',
    };
  }

  String _animationName(BuildContext context, _FocusBeatAnimationKind kind) {
    final i18n = _i18nOf(context);
    return switch (kind) {
      _FocusBeatAnimationKind.pendulum => i18n.t(
        'toolbox.sound.focus.animNameWarm',
      ),
      _FocusBeatAnimationKind.hypno => i18n.t(
        'toolbox.sound.focus.animNameStill',
      ),
      _FocusBeatAnimationKind.dew => i18n.t(
        'toolbox.sound.focus.animNameClear',
      ),
      _FocusBeatAnimationKind.gear => i18n.t(
        'toolbox.sound.focus.animNamePrecision',
      ),
      _FocusBeatAnimationKind.steps => i18n.t(
        'toolbox.sound.focus.animNameStep',
      ),
    };
  }

  String _soundName(BuildContext context, _FocusBeatSoundKind kind) {
    final i18n = _i18nOf(context);
    return switch (kind) {
      _FocusBeatSoundKind.pendulum => i18n.t(
        'toolbox.sound.focus.soundNamePendulum',
      ),
      _FocusBeatSoundKind.hypno => i18n.t('toolbox.sound.focus.soundNamePulse'),
      _FocusBeatSoundKind.dew => i18n.t('toolbox.sound.focus.soundNameDrop'),
      _FocusBeatSoundKind.gear => i18n.t('toolbox.sound.focus.soundNameTick'),
      _FocusBeatSoundKind.steps => i18n.t('toolbox.sound.focus.soundNameStep'),
    };
  }

  _FocusBeatSoundKind _pairedSoundForAnimation(_FocusBeatAnimationKind kind) {
    return _FocusBeatSoundKind.fromId(kind.id);
  }

  _FocusBeatAnimationKind _pairedAnimationForSound(_FocusBeatSoundKind kind) {
    return _FocusBeatAnimationKind.fromId(kind.id);
  }

  String _animationDescription(_FocusBeatAnimationKind kind) {
    return switch (kind) {
      _FocusBeatAnimationKind.pendulum => '用暖色轨道突出第一拍，让一小节的起点更容易被眼睛捕捉。',
      _FocusBeatAnimationKind.hypno => '用低对比环线降低刺激，把注意力集中在沿轨道推进的光点上。',
      _FocusBeatAnimationKind.dew => '用清透冷色表达子拍密度，适合轻声朗读和较柔的跟拍节奏。',
      _FocusBeatAnimationKind.gear => '用精密刻度强化拍点边界，适合需要明确节奏切分的专注任务。',
      _FocusBeatAnimationKind.steps => '用步阵式色彩区分主拍推进，适合背诵、走拍和节奏记忆。',
    };
  }

  String _animationSyncHint(_FocusBeatAnimationKind kind) {
    return switch (kind) {
      _FocusBeatAnimationKind.pendulum => '第一拍光晕更暖，普通拍保持轻量推进。',
      _FocusBeatAnimationKind.hypno => '光点沿环线匀速呼吸，重拍只做克制强调。',
      _FocusBeatAnimationKind.dew => '子拍以细小刻度衔接，主拍以清亮节点落位。',
      _FocusBeatAnimationKind.gear => '每个拍点都有明确刻度，当前节点会短暂加亮。',
      _FocusBeatAnimationKind.steps => '主拍像步阵依次前进，段落切换时更容易对齐。',
    };
  }

  int _animationRealism(_FocusBeatAnimationKind kind) {
    return switch (kind) {
      _FocusBeatAnimationKind.pendulum => 5,
      _FocusBeatAnimationKind.hypno => 3,
      _FocusBeatAnimationKind.dew => 5,
      _FocusBeatAnimationKind.gear => 5,
      _FocusBeatAnimationKind.steps => 4,
    };
  }

  String _soundDescription(_FocusBeatSoundKind kind) {
    return switch (kind) {
      _FocusBeatSoundKind.pendulum => '偏金属钟体的清脆主击，适合经典节拍器手感。',
      _FocusBeatSoundKind.hypno => '更柔和、带呼吸感的脉冲，不易疲劳。',
      _FocusBeatSoundKind.dew => '高频更透明，像露滴轻触水面。',
      _FocusBeatSoundKind.gear => '机械棘轮感更强，强调“咔哒”式咬合瞬态。',
      _FocusBeatSoundKind.steps => '下盘更稳，像鞋底落地的步伐提示。',
    };
  }

  String _soundSyncHint(_FocusBeatSoundKind kind) {
    return switch (kind) {
      _FocusBeatSoundKind.pendulum => '重拍更厚，普通拍更轻。',
      _FocusBeatSoundKind.hypno => '声头柔和，适合低干扰长时专注。',
      _FocusBeatSoundKind.dew => '高频短促，适合露珠落点动画。',
      _FocusBeatSoundKind.gear => '声头更硬，适合齿轮咬合视觉。',
      _FocusBeatSoundKind.steps => '低频更稳，适合步态与口播跟拍。',
    };
  }

  int _soundRealism(_FocusBeatSoundKind kind) {
    return switch (kind) {
      _FocusBeatSoundKind.pendulum => 4,
      _FocusBeatSoundKind.hypno => 3,
      _FocusBeatSoundKind.dew => 4,
      _FocusBeatSoundKind.gear => 5,
      _FocusBeatSoundKind.steps => 4,
    };
  }

  String _realismLabel(int score) => '拟真度 $score/5';

  List<int> _normalizeArrangementBeats(Iterable<int> values) {
    final normalized = values
        .map((value) => value.clamp(1, 64))
        .map((value) => value.toInt())
        .toList(growable: false);
    if (normalized.isNotEmpty) {
      return normalized;
    }
    return <int>[_beatsPerBar];
  }

  String _barsTokenFromBeats(int beats) {
    final gcd = _focusGreatestCommonDivisor(beats, _beatsPerBar);
    final numerator = beats ~/ gcd;
    final denominator = _beatsPerBar ~/ gcd;
    if (denominator == 1) {
      return '${numerator}bar';
    }
    return '$numerator/${denominator}bar';
  }

  String _patternTextFromArrangement(List<int> beats) {
    return beats.map(_barsTokenFromBeats).join('+');
  }

  void _syncPatternFromArrangement({required bool syncTemplate}) {
    _arrangementBeats = _normalizeArrangementBeats(_arrangementBeats);
    _pattern = _FocusCyclePattern(
      raw: _patternTextFromArrangement(_arrangementBeats),
      segments: _arrangementBeats
          .map((beats) => beats / _beatsPerBar)
          .toList(growable: false),
    );
    _segmentPulseCounts = _arrangementBeats
        .map((beats) => beats * _subdivision)
        .toList(growable: false);
    _patternController.text = _pattern.raw;
    _patternError = '';
    if (!_patternEnabled) {
      _activeTemplateId = null;
      return;
    }
    if (syncTemplate) {
      _syncActiveTemplateByPattern();
    }
  }

  bool _loadPatternFromText(
    String rawText, {
    required bool showErrorIfInvalid,
  }) {
    final result = _parseFocusCyclePattern(
      rawText,
      beatsPerBar: _beatsPerBar,
      subdivision: _subdivision,
    );
    if (!result.isValid || result.pattern == null) {
      _patternError = _patternEnabled && showErrorIfInvalid
          ? (result.error ?? '编排格式无效。')
          : '';
      return false;
    }

    final parsedBeats = <int>[];
    for (final bars in result.pattern!.segments) {
      final beatsValue = bars * _beatsPerBar;
      final rounded = beatsValue.round();
      if ((beatsValue - rounded).abs() > 0.001 || rounded < 1) {
        _patternError = showErrorIfInvalid ? '当前只支持按“整数拍”编辑拍段。' : '';
        return false;
      }
      parsedBeats.add(rounded);
    }
    _arrangementBeats = _normalizeArrangementBeats(parsedBeats);
    _syncPatternFromArrangement(syncTemplate: false);
    return true;
  }

  void _resetRuntime() {
    _cycleCount = 0;
    _cyclePulse = 0;
    _currentSegmentIndex = 0;
    _pulseInSegment = 0;
    _pulseInBar = 0;
    _activeBeat = -1;
    _activeSubPulse = 0;
    _lastLayer = 2;
  }

  void _start() {
    if (_FocusBeatsToolState._runningInstance != null &&
        _FocusBeatsToolState._runningInstance != this) {
      _FocusBeatsToolState._runningInstance!._stop();
    }
    _transportTimer?.cancel();
    _running = true;
    _FocusBeatsToolState._runningInstance = this;
    _resetRuntime();
    _transportTick = 0;
    _transportAnchorUs = DateTime.now().microsecondsSinceEpoch;
    _tick();
    _scheduleNextTick();
    if (mounted) {
      _setViewState(() {});
    }
    _setImmersiveHudVisible(true, autoHide: true, force: true);
  }

  void _scheduleNextTick() {
    if (!_running) {
      return;
    }
    final anchor = _transportAnchorUs ?? DateTime.now().microsecondsSinceEpoch;
    final nextTick = _transportTick + 1;
    final targetUs = anchor + nextTick * _pulseIntervalUs;
    final nowUs = DateTime.now().microsecondsSinceEpoch;
    final waitUs = math.max(
      0,
      targetUs - nowUs - _FocusBeatsToolState._timingCompensationUs,
    );
    _transportTimer = Timer(Duration(microseconds: waitUs), () {
      if (!mounted || !_running) {
        return;
      }
      _transportTick = nextTick;
      _tick();
      var catchUpCount = 0;
      while (catchUpCount < _FocusBeatsToolState._maxCatchUpTicks &&
          mounted &&
          _running) {
        final now = DateTime.now().microsecondsSinceEpoch;
        final followTick = _transportTick + 1;
        final followTargetUs = anchor + followTick * _pulseIntervalUs;
        if (now + _FocusBeatsToolState._timingCompensationUs < followTargetUs) {
          break;
        }
        _transportTick = followTick;
        _tick();
        catchUpCount += 1;
      }
      _scheduleNextTick();
    });
  }

  void _stop() {
    _transportTimer?.cancel();
    _transportTimer = null;
    _running = false;
    if (_FocusBeatsToolState._runningInstance == this) {
      _FocusBeatsToolState._runningInstance = null;
    }
    _transportAnchorUs = null;
    _transportTick = 0;
    _resetRuntime();
    _setViewState(() {});
    _setImmersiveHudVisible(true, autoHide: false, force: true);
  }

  void _restartTransportIfRunning() {
    if (_running) {
      _start();
    }
  }

  void _tick() {
    final frame = _buildTickFrame();
    _maybePrimeLayer(frame.nextLayer);
    _maybeHaptic(frame.layer);
    _playLayer(frame.layer);

    _pulseController
      ..stop()
      ..forward(from: 0);

    if (mounted) {
      _setViewState(() {
        _lastLayer = frame.layer;
        _activeBeat = frame.beat;
        _activeSubPulse = frame.subPulse;
      });
    }

    _pulseInSegment += 1;
    _pulseInBar = (_pulseInBar + 1) % _barPulses;
    _cyclePulse += 1;

    if (_pulseInSegment >= frame.segmentLength) {
      _pulseInSegment = 0;
      _currentSegmentIndex += 1;
      if (_currentSegmentIndex >= _effectiveSegmentPulses.length) {
        _currentSegmentIndex = 0;
        _cycleCount += 1;
        _cyclePulse = 0;
      }
    }
  }

  _FocusTickFrame _buildTickFrame() {
    final segments = _effectiveSegmentPulses;
    final boundedSegmentIndex = _currentSegmentIndex.clamp(
      0,
      segments.length - 1,
    );
    final segmentLength = segments[boundedSegmentIndex];
    final currentLayer = _layerForPulse(
      cyclePulse: _cyclePulse,
      pulseInSegment: _pulseInSegment,
      pulseInBar: _pulseInBar,
    );
    final beat = _pulseInBar ~/ _subdivision;
    final subPulse = (_pulseInBar % _subdivision) + 1;

    var nextPulseInSegment = _pulseInSegment + 1;
    var nextPulseInBar = (_pulseInBar + 1) % _barPulses;
    var nextCyclePulse = _cyclePulse + 1;
    var nextSegmentIndex = _currentSegmentIndex;
    if (nextPulseInSegment >= segmentLength) {
      nextPulseInSegment = 0;
      nextSegmentIndex += 1;
      if (nextSegmentIndex >= segments.length) {
        nextSegmentIndex = 0;
        nextCyclePulse = 0;
      }
    }
    final nextLayer = _layerForPulse(
      cyclePulse: nextCyclePulse,
      pulseInSegment: nextPulseInSegment,
      pulseInBar: nextPulseInBar,
    );
    return _FocusTickFrame(
      segmentLength: segmentLength,
      layer: currentLayer,
      nextLayer: nextLayer,
      beat: beat,
      subPulse: subPulse,
    );
  }

  int _layerForPulse({
    required int cyclePulse,
    required int pulseInSegment,
    required int pulseInBar,
  }) {
    final isCycleStart = cyclePulse == 0;
    final isSegmentStart = pulseInSegment == 0;
    final isOnBeat = pulseInBar % _subdivision == 0;
    return isCycleStart
        ? 0
        : isSegmentStart
        ? 1
        : isOnBeat
        ? 2
        : 3;
  }

  void _maybePrimeLayer(int layer) {
    if (layer == _lastPrimedLayer &&
        _transportTick - _lastPrimedTransportTick < 2) {
      return;
    }
    _lastPrimedLayer = layer;
    _lastPrimedTransportTick = _transportTick;
    final player = _players[layer];
    if (player == null) {
      return;
    }
    unawaited(player.warmUp());
  }

  double _volumeForLayer(int layer) {
    final layerVolume = switch (layer) {
      0 => _accentVolume,
      1 => (_accentVolume * 0.9).clamp(0.0, 1.0),
      2 => _regularVolume,
      _ => _subdivisionVolume,
    };
    return (_masterVolume * layerVolume).clamp(0.0, 1.0).toDouble();
  }

  void _playLayer(int layer) {
    final player = _players[layer];
    if (player == null) return;
    unawaited(player.play(baseVolume: _volumeForLayer(layer)));
  }

  void _maybeHaptic(int layer) {
    if (!_hapticsEnabled) return;
    if (layer == 0) {
      HapticFeedback.mediumImpact();
      return;
    }
    if (layer == 1 && _bpm <= 140) {
      HapticFeedback.lightImpact();
      return;
    }
    if (layer == 2 && _subdivision == 1 && _bpm <= 88) {
      HapticFeedback.selectionClick();
    }
  }

  void _setAnimationKind(_FocusBeatAnimationKind kind) {
    if (_animationKind == kind && !_linkAnimationAndSound) {
      return;
    }
    var shouldRebuildPlayers = false;
    _setViewState(() {
      _animationKind = kind;
      if (_linkAnimationAndSound) {
        final pairedSound = _pairedSoundForAnimation(kind);
        shouldRebuildPlayers = pairedSound != _soundKind;
        _soundKind = pairedSound;
      }
    });
    _scheduleSavePrefs();
    if (shouldRebuildPlayers) {
      unawaited(_rebuildPlayers());
    }
  }

  void _setSoundKind(_FocusBeatSoundKind kind) {
    if (_soundKind == kind && !_linkAnimationAndSound) {
      return;
    }
    _setViewState(() {
      _soundKind = kind;
      if (_linkAnimationAndSound) {
        _animationKind = _pairedAnimationForSound(kind);
      }
    });
    _scheduleSavePrefs();
    unawaited(_rebuildPlayers());
  }

  void _setLinkAnimationAndSound(bool value) {
    var shouldRebuildPlayers = false;
    _setViewState(() {
      _linkAnimationAndSound = value;
      if (value) {
        final pairedSound = _pairedSoundForAnimation(_animationKind);
        shouldRebuildPlayers = pairedSound != _soundKind;
        _soundKind = pairedSound;
      }
    });
    _scheduleSavePrefs();
    if (shouldRebuildPlayers) {
      unawaited(_rebuildPlayers());
    }
  }

  void _previewCurrentSound() {
    _playLayer(0);
    _pulseController
      ..stop()
      ..forward(from: 0);
    if (_hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void _setBpm(int value) {
    final next = value.clamp(30, 220);
    if (next == _bpm) {
      return;
    }
    _setViewState(() {
      _bpm = next;
      _syncPulseAnimationDuration();
    });
    _scheduleSavePrefs();
    _restartTransportIfRunning();
  }

  void _setBeatsPerBar(int value) {
    if (value == _beatsPerBar) {
      return;
    }
    _setViewState(() {
      _beatsPerBar = value;
      _syncPulseAnimationDuration();
      _syncPatternFromArrangement(syncTemplate: _patternEnabled);
      _resetRuntime();
    });
    _scheduleSavePrefs();
    _restartTransportIfRunning();
  }

  void _setSubdivision(int value) {
    if (value == _subdivision) {
      return;
    }
    _setViewState(() {
      _subdivision = value;
      _syncPulseAnimationDuration();
      _syncPatternFromArrangement(syncTemplate: false);
      _resetRuntime();
    });
    _scheduleSavePrefs();
    _restartTransportIfRunning();
  }

  Future<void> _openArrangementEditor() async {
    final result = await Navigator.of(context)
        .push<_FocusArrangementEditorResult>(
          MaterialPageRoute<_FocusArrangementEditorResult>(
            builder: (_) => _FocusArrangementEditorPage(
              beatsPerBar: _beatsPerBar,
              patternEnabled: _patternEnabled,
              arrangementBeats: _arrangementBeats,
              templates: _savedTemplates,
              activeTemplateId: _activeTemplateId,
              presets: _FocusBeatsToolState._patternPresets,
            ),
            fullscreenDialog: true,
          ),
        );
    if (!mounted || result == null) {
      return;
    }
    _setViewState(() {
      _patternEnabled = result.patternEnabled;
      _arrangementBeats = _normalizeArrangementBeats(result.arrangementBeats);
      _savedTemplates = result.templates.toList(growable: false);
      _activeTemplateId = result.activeTemplateId;
      if (_activeTemplateId != null &&
          !_savedTemplates.any((item) => item.id == _activeTemplateId)) {
        _activeTemplateId = null;
      }
      _syncPatternFromArrangement(syncTemplate: false);
      if (!_patternEnabled) {
        _activeTemplateId = null;
      }
      _resetRuntime();
    });
    _scheduleSavePrefs();
    _restartTransportIfRunning();
  }

  void _tapTempo() {
    final now = DateTime.now();
    final last = _lastTapTempoAt;
    if (last == null || now.difference(last) > const Duration(seconds: 2)) {
      _tapTempoIntervalsMs.clear();
      _lastTapTempoAt = now;
      if (_hapticsEnabled) {
        HapticFeedback.selectionClick();
      }
      return;
    }

    final deltaMs = now.difference(last).inMilliseconds;
    _lastTapTempoAt = now;

    if (deltaMs < 180 || deltaMs > 2000) {
      _tapTempoIntervalsMs.clear();
      return;
    }

    _tapTempoIntervalsMs.add(deltaMs);
    if (_tapTempoIntervalsMs.length > 6) {
      _tapTempoIntervalsMs.removeAt(0);
    }
    final averageMs =
        _tapTempoIntervalsMs.reduce((a, b) => a + b) /
        _tapTempoIntervalsMs.length;
    _setBpm((60000 / averageMs).round());
    if (_hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _toggleImmersiveMode() async {
    if (!widget.fullScreen && widget.onOpenFullScreen != null) {
      final shouldAutoStart = _running;
      if (_running) {
        _stop();
      }
      widget.onOpenFullScreen?.call(
        autoStart: shouldAutoStart,
        immersive: true,
      );
      return;
    }
    final next = !_immersiveMode;
    if (widget.fullScreen) {
      await _enterToolboxPortraitMode();
    } else if (next) {
      await _enterToolboxPortraitMode();
    } else {
      await _exitToolboxLandscapeMode();
    }
    if (!mounted) {
      return;
    }
    _setViewState(() {
      _immersiveMode = next;
    });
  }

  void _setImmersiveHudVisible(
    bool visible, {
    bool autoHide = true,
    bool force = false,
  }) {
    if (!widget.fullScreen) {
      return;
    }
    _immersiveHudTimer?.cancel();
    if (!mounted) {
      return;
    }
    if (_immersiveHudVisible != visible || force) {
      _setViewState(() {
        _immersiveHudVisible = visible;
      });
    }
    if (!visible || !_running || !autoHide) {
      return;
    }
    _immersiveHudTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || !_running) {
        return;
      }
      _setViewState(() {
        _immersiveHudVisible = false;
      });
    });
  }

  void _toggleImmersiveHud() {
    _setImmersiveHudVisible(!_immersiveHudVisible, autoHide: _running);
  }

  Future<void> _openImmersiveControlsSheet() async {
    _setImmersiveHudVisible(true, autoHide: false);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final i18n = _i18nOf(sheetContext);
        final arrangementLabel = _patternError.isEmpty ? _pattern.raw : '1bar';
        return FractionallySizedBox(
          heightFactor: 0.90,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(sheetContext).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 32,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              sheetContext,
                            ).colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        i18n.t('toolbox.sound.focus.immersiveControlsTitle'),
                        style: Theme.of(sheetContext).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        i18n.t('toolbox.sound.focus.immersiveControlsDesc'),
                        style: Theme.of(sheetContext).textTheme.bodyMedium
                            ?.copyWith(
                              color: Theme.of(
                                sheetContext,
                              ).colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildPrimaryControls(sheetContext, immersiveSheet: true),
                      const SizedBox(height: 16),
                      _FocusControlSection(
                        icon: Icons.speed_rounded,
                        title: i18n.t('toolbox.sound.focus.controlTempo'),
                        subtitle: i18n.t(
                          'toolbox.sound.focus.controlTempoDesc',
                        ),
                        summary: '$_bpm BPM',
                        expanded: _tempoExpanded,
                        onToggle: () {
                          _setViewState(() {
                            _tempoExpanded = !_tempoExpanded;
                          });
                        },
                        child: _buildTempoSection(sheetContext),
                      ),
                      const SizedBox(height: 12),
                      _FocusControlSection(
                        icon: Icons.tune_rounded,
                        title: i18n.t('toolbox.sound.focus.controlMeter'),
                        subtitle: i18n.t(
                          'toolbox.sound.focus.controlMeterDesc',
                        ),
                        summary: '$_beatsPerBar/4 × $_subdivision',
                        expanded: _meterExpanded,
                        onToggle: () {
                          _setViewState(() {
                            _meterExpanded = !_meterExpanded;
                          });
                        },
                        child: _buildMeterSection(sheetContext),
                      ),
                      const SizedBox(height: 12),
                      _FocusControlSection(
                        icon: Icons.graphic_eq_rounded,
                        title: i18n.t('toolbox.sound.focus.controlTimbre'),
                        subtitle: i18n.t(
                          'toolbox.sound.focus.controlTimbreDesc',
                        ),
                        summary: _soundName(sheetContext, _soundKind),
                        expanded: _styleExpanded,
                        onToggle: () {
                          _setViewState(() {
                            _styleExpanded = !_styleExpanded;
                          });
                        },
                        child: _buildStyleSection(sheetContext),
                      ),
                      const SizedBox(height: 12),
                      _FocusControlSection(
                        icon: Icons.view_timeline_rounded,
                        title: i18n.t('toolbox.sound.focus.controlArrangement'),
                        subtitle: i18n.t(
                          'toolbox.sound.focus.controlArrangementDesc',
                        ),
                        summary: _patternEnabled
                            ? arrangementLabel
                            : i18n.t('toolbox.sound.focus.singleBarLoop'),
                        expanded: _arrangementExpanded,
                        onToggle: () {
                          _setViewState(() {
                            _arrangementExpanded = !_arrangementExpanded;
                          });
                        },
                        child: _buildArrangementSection(
                          sheetContext,
                          arrangementLabel: arrangementLabel,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _FocusControlSection(
                        icon: Icons.graphic_eq_rounded,
                        title: i18n.t('toolbox.sound.focus.controlMix'),
                        subtitle: i18n.t('toolbox.sound.focus.controlMixDesc2'),
                        summary:
                            '${(100 * _masterVolume).round()}% · ${_hapticsEnabled ? i18n.t('toolbox.sound.focus.hapticsOn') : i18n.t('toolbox.sound.focus.hapticsOff')}',
                        expanded: _advancedExpanded,
                        onToggle: () {
                          _setViewState(() {
                            _advancedExpanded = !_advancedExpanded;
                          });
                        },
                        child: _buildMixSection(sheetContext),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: widget.onExitFullScreen,
                          icon: const Icon(Icons.close_rounded),
                          label: Text(
                            i18n.t('toolbox.sound.focus.immersiveExitSheet'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    if (!mounted) {
      return;
    }
    await _enterToolboxPortraitMode();
    _setImmersiveHudVisible(true, autoHide: _running, force: true);
  }
}

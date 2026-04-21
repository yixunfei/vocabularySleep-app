part of '../toolbox_sound_tools.dart';

extension _PianoToolStateLogic on _PianoToolState {
  List<int> _windowStartWhiteIndices(int octaveSpan) {
    final whiteKeys = _activeKeyPool
        .where((key) => !key.isSharp)
        .toList(growable: false);
    final windowWhiteCount = octaveSpan * 7 + 1;
    if (whiteKeys.length <= windowWhiteCount) {
      return const <int>[0];
    }
    final maxStartWhite = whiteKeys.length - windowWhiteCount;
    final indices = <int>[0];
    for (var index = 7; index <= maxStartWhite; index += 7) {
      indices.add(index);
    }
    if (indices.last != maxStartWhite) {
      indices.add(maxStartWhite);
    }
    return indices;
  }

  String _windowLabelForIndex(int startIndex, int octaveSpan) {
    final whiteKeys = _activeKeyPool
        .where((key) => !key.isSharp)
        .toList(growable: false);
    if (whiteKeys.isEmpty) {
      return '--';
    }
    final starts = _windowStartWhiteIndices(octaveSpan);
    final normalized = startIndex.clamp(0, starts.length - 1);
    final startWhite = starts[normalized];
    final endWhite = (startWhite + octaveSpan * 7).clamp(
      0,
      whiteKeys.length - 1,
    );
    return '${whiteKeys[startWhite].label}-${whiteKeys[endWhite].label}';
  }

  String _noteLabelForMidi(int midi) {
    for (final key in _PianoToolState._allKeys) {
      if (key.midi == midi) {
        return key.label;
      }
    }
    return _PianoToolState._allKeys.first.label;
  }

  String _displayKeyLayoutLabel(AppI18n i18n, _PianoKeyLayoutPreset layout) {
    final endMidi = layout.startMidi + layout.keyCount - 1;
    return pickUiText(
      i18n,
      zh: '${layout.keyCount}键 ${_noteLabelForMidi(layout.startMidi)}-${_noteLabelForMidi(endMidi)}',
      en: '${layout.keyCount} keys ${_noteLabelForMidi(layout.startMidi)}-${_noteLabelForMidi(endMidi)}',
    );
  }

  String _displayPresetLabel(AppI18n i18n, _PianoPreset preset) {
    return switch (preset.id) {
      'upright_studio' => pickUiText(i18n, zh: '录音室立式', en: 'Studio upright'),
      'bright_stage' => pickUiText(i18n, zh: '明亮舞台', en: 'Bright stage'),
      'felt_room' => pickUiText(i18n, zh: '毛毡房间', en: 'Felt room'),
      _ => pickUiText(i18n, zh: '音乐厅', en: 'Concert hall'),
    };
  }

  String _displayPresetSubtitleFixed(AppI18n i18n, _PianoPreset preset) {
    return switch (preset.id) {
      'upright_studio' => pickUiText(
        i18n,
        zh: '更接近真实立式钢琴的木质共鸣与干净起音，适合日常练习。',
        en: 'Dryer wood resonance and cleaner attacks, closer to a real upright piano.',
      ),
      'bright_stage' => pickUiText(
        i18n,
        zh: '更锋利的击弦边缘，适合突出旋律和明亮起音。',
        en: 'Sharper hammer edge for lead lines and brighter attacks.',
      ),
      'felt_room' => pickUiText(
        i18n,
        zh: '毛毡包裹感更强，适合安静和亲密的演奏氛围。',
        en: 'Softer felt body for intimate and quiet playing.',
      ),
      _ => pickUiText(
        i18n,
        zh: '延音与空间感更均衡，适合通用演奏和编配。',
        en: 'Balanced sustain and room feel for all-purpose playing.',
      ),
    };
  }

  String _displayScaleLabelFixed(AppI18n i18n, String scaleId) {
    return switch (scaleId) {
      'minor' => pickUiText(i18n, zh: '小调', en: 'Minor'),
      'dorian' => pickUiText(i18n, zh: '多利亚', en: 'Dorian'),
      'lydian' => pickUiText(i18n, zh: '利底亚', en: 'Lydian'),
      'harmonic_minor' => pickUiText(i18n, zh: '和声小调', en: 'Harmonic minor'),
      'pentatonic' => pickUiText(i18n, zh: '五声音阶', en: 'Pentatonic'),
      'chromatic' => pickUiText(i18n, zh: '半音阶', en: 'Chromatic'),
      _ => pickUiText(i18n, zh: '大调', en: 'Major'),
    };
  }

  String _displayChordLabelFixed(AppI18n i18n, String chordId) {
    return switch (chordId) {
      'major' => pickUiText(i18n, zh: '大三和弦', en: 'Major'),
      'minor' => pickUiText(i18n, zh: '小三和弦', en: 'Minor'),
      'sus2' => pickUiText(i18n, zh: '挂二', en: 'Sus2'),
      'maj7' => pickUiText(i18n, zh: '大七', en: 'Maj7'),
      'm7' => pickUiText(i18n, zh: '小七', en: 'm7'),
      'add9' => pickUiText(i18n, zh: '加九', en: 'Add9'),
      _ => pickUiText(i18n, zh: '单音', en: 'Single note'),
    };
  }

  String _displayKeyboardStyleLabelFixed(
    AppI18n i18n,
    _PianoKeyboardStyle style,
  ) {
    return switch (style.id) {
      'classic_bw' => pickUiText(i18n, zh: '经典黑白', en: 'Classic black & white'),
      'midnight' => pickUiText(i18n, zh: '午夜', en: 'Midnight'),
      'mist' => pickUiText(i18n, zh: '薄雾', en: 'Mist'),
      _ => pickUiText(i18n, zh: '象牙', en: 'Ivory'),
    };
  }

  String _displayTouchLabelFixed(AppI18n i18n) {
    return pickUiText(
      i18n,
      zh: '触键 ${(100 * _touch).round()}%',
      en: 'Touch ${(100 * _touch).round()}%',
    );
  }

  String _displaySpaceLabelFixed(AppI18n i18n) {
    return pickUiText(
      i18n,
      zh: '空间 ${(_reverb * 100).round()}%',
      en: 'Space ${(_reverb * 100).round()}%',
    );
  }

  String _displayDecayLabelFixed(AppI18n i18n) {
    return pickUiText(
      i18n,
      zh: '延音 ${_decay.toStringAsFixed(2)}x',
      en: 'Decay ${_decay.toStringAsFixed(2)}x',
    );
  }

  String _displayGestureThresholdLabelFixed(AppI18n i18n) {
    return pickUiText(
      i18n,
      zh: '双指切窗灵敏度 ${(_gestureThresholdScale * 100).round()}%',
      en: 'Two-finger range sensitivity ${(_gestureThresholdScale * 100).round()}%',
    );
  }

  void _applyKeyLayoutById(String layoutId) {
    if (_keyLayoutId == layoutId) {
      return;
    }
    _keyLayoutId = layoutId;
    _rangeStartOctave = 0;
    _dualKeyboardMode = false;
    _compactDualFocus = _PianoCompactDeckFocus.low;
    _invalidatePlayers();
  }

  void _invalidatePlayers({bool warmUp = true}) {
    for (final player in _players.values) {
      unawaited(player.dispose());
    }
    _players.clear();
    if (warmUp) {
      _scheduleRangeWarmUp(
        octaveSpan: _visibleOctaveSpan,
        rangeStart: _rangeStartOctave,
        immediate: true,
        preloadAllKeys: true,
        indicate: false,
      );
    }
  }

  void _applyPreset(String presetId) {
    final preset = _PianoToolState._presets.firstWhere(
      (item) => item.id == presetId,
      orElse: () => _PianoToolState._presets.first,
    );
    if (_presetId == preset.id) {
      return;
    }
    _setViewState(() {
      _presetId = preset.id;
      _touch = preset.touch;
      _reverb = preset.reverb;
      _decay = preset.decay;
    });
    _invalidatePlayers();
  }

  void _toggleRangeNavigatorLayout() {
    _setViewState(() {
      _rangeNavigatorExpanded = !_rangeNavigatorExpanded;
    });
  }

  void _toggleDualKeyboardMode() {
    _setViewState(() {
      _dualKeyboardMode = !_dualKeyboardMode;
    });
  }

  void _toggleCompactKeyboardMode() {
    _setViewState(() {
      _compactKeyboardMode = !_compactKeyboardMode;
    });
  }

  bool _isCompactPhoneWidth(double width) {
    return width < (widget.fullScreen ? 480 : 430);
  }

  bool _isUltraCompactPhoneWidth(double width) {
    return width < 380;
  }

  bool _isAggressiveOneHandWidth(double width) {
    return width >= 320 && width <= 390;
  }

  List<int> _quickRangeStarts(int octaveSpan) {
    final maxStart = _maxRangeStart(octaveSpan);
    final starts = <int>{0, (maxStart / 2).round(), maxStart};
    return starts.toList()..sort();
  }

  void _maybeApplyResponsiveDefaults(double width) {
    if (_didApplyResponsiveDefaults) {
      return;
    }
    _didApplyResponsiveDefaults = true;
    if (!_isCompactPhoneWidth(width)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _setViewState(() {
        _dualKeyboardMode = false;
        _compactKeyboardMode = true;
        _aggressiveOneHandMode = _isAggressiveOneHandWidth(width);
        if (_aggressiveOneHandMode) {
          _gestureThresholdScale = 0.9;
        }
        _compactDualFocus = _PianoCompactDeckFocus.low;
      });
    });
  }

  void _openFullScreen(BuildContext context) {
    if (widget.fullScreen) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(
          backgroundColor: Colors.black,
          body: _PianoTool(fullScreen: true),
        ),
      ),
    );
  }

  void _setRangePreparing(bool value) {
    if (!mounted || _isRangeWindowPreparing == value) {
      return;
    }
    _setViewState(() {
      _isRangeWindowPreparing = value;
    });
  }

  void _scheduleRangeWarmUp({
    required int octaveSpan,
    required int rangeStart,
    bool immediate = false,
    bool preloadAllKeys = false,
    bool indicate = true,
  }) {
    _rangeWarmUpTimer?.cancel();
    _rangeWarmUpTimer = null;
    final normalizedStart = rangeStart.clamp(0, _maxRangeStart(octaveSpan));
    final version = ++_rangeWarmUpVersion;
    if (indicate) {
      _setRangePreparing(true);
    } else {
      _setRangePreparing(false);
    }

    Future<void> runWarmUp() async {
      try {
        await _warmUpVisibleWindow(
          octaveSpan: octaveSpan,
          rangeStart: normalizedStart,
          preloadAllKeys: preloadAllKeys,
          stopIfStale: () => version != _rangeWarmUpVersion,
        );
      } finally {
        if (mounted && version == _rangeWarmUpVersion) {
          _setRangePreparing(false);
        }
      }
    }

    if (immediate) {
      unawaited(runWarmUp());
      return;
    }

    _rangeWarmUpTimer = Timer(const Duration(milliseconds: 120), () {
      _rangeWarmUpTimer = null;
      unawaited(runWarmUp());
    });
  }

  Future<void> _warmUpVisibleWindow({
    int? octaveSpan,
    int? rangeStart,
    bool preloadAllKeys = false,
    bool Function()? stopIfStale,
  }) async {
    final span = octaveSpan ?? _visibleOctaveSpan;
    final start = (rangeStart ?? _rangeStartOctave).clamp(
      0,
      _maxRangeStart(span),
    );
    final slice = _sliceFor(start, span);
    final candidates = preloadAllKeys
        ? <_PianoKey>[
            ...slice.whiteKeys,
            ...slice.blackKeys.map((placement) => placement.key),
          ]
        : <_PianoKey>[
            if (slice.whiteKeys.isNotEmpty) slice.whiteKeys.first,
            if (slice.whiteKeys.isNotEmpty)
              slice.whiteKeys[slice.whiteKeys.length ~/ 2],
            if (slice.blackKeys.isNotEmpty)
              slice.blackKeys[slice.blackKeys.length ~/ 2].key,
            if (slice.whiteKeys.isNotEmpty) slice.whiteKeys.last,
          ];
    final visited = <String>{};
    for (final key in candidates) {
      if (stopIfStale?.call() ?? false) {
        return;
      }
      if (!visited.add(key.id)) {
        continue;
      }
      await _playerFor(key).warmUp();
    }
  }

  double _velocityBucket(double velocity) {
    final normalized = velocity.clamp(0.22, 1.0).toDouble();
    var best = _PianoToolState._velocityBuckets.first;
    var bestDistance = (best - normalized).abs();
    for (final candidate in _PianoToolState._velocityBuckets.skip(1)) {
      final distance = (candidate - normalized).abs();
      if (distance < bestDistance) {
        best = candidate;
        bestDistance = distance;
      }
    }
    return best;
  }

  ToolboxRealisticEffectPlayer _playerFor(
    _PianoKey key, {
    double velocity = 0.74,
  }) {
    final styleId = _activePreset.styleId;
    final velocityBucket = _velocityBucket(velocity);
    final cacheKey =
        '${key.id}:$styleId:${_reverb.toStringAsFixed(2)}:'
        '${_decay.toStringAsFixed(2)}:${velocityBucket.toStringAsFixed(2)}';
    final existing = _players[cacheKey];
    if (existing != null) {
      return existing;
    }
    final created = ToolboxRealisticEffectPlayer.build(
      variants: _PianoToolState._pianoVariants,
      bytesForVariant: (variant) => ToolboxAudioBank.pianoNote(
        key.frequency,
        style: styleId,
        reverb: _reverb,
        decay: _decay,
        velocity: velocityBucket,
        variant: variant,
      ),
      maxPlayers: 4,
      volumeJitter: 0.04,
    );
    _players[cacheKey] = created;
    return created;
  }

  int _maxRangeStart(int octaveSpan) {
    return math.max(0, _windowStartWhiteIndices(octaveSpan).length - 1);
  }

  void _updateRangeStart(
    int nextStart,
    int octaveSpan, {
    bool immediateWarmUp = true,
    bool preloadAllKeys = true,
    bool indicateWarmUp = true,
  }) {
    final normalized = nextStart.clamp(0, _maxRangeStart(octaveSpan));
    if (_rangeStartOctave == normalized) {
      if (immediateWarmUp) {
        _scheduleRangeWarmUp(
          octaveSpan: octaveSpan,
          rangeStart: normalized,
          immediate: true,
          preloadAllKeys: preloadAllKeys,
          indicate: indicateWarmUp,
        );
      }
      return;
    }
    _setViewState(() {
      _rangeStartOctave = normalized;
      _activePointers.clear();
      _activePointerKeyIds.clear();
      _activeKeyPulseCounts.clear();
      _activeKeyIds = <String>{};
      _twoFingerOrigin = null;
      _lastRangeGestureAt = null;
    });
    _scheduleRangeWarmUp(
      octaveSpan: octaveSpan,
      rangeStart: normalized,
      immediate: immediateWarmUp,
      preloadAllKeys: preloadAllKeys,
      indicate: indicateWarmUp,
    );
  }

  Offset _activePointerCentroid() {
    final values = _activePointers.values.toList(growable: false);
    if (values.isEmpty) {
      return Offset.zero;
    }
    var sumX = 0.0;
    var sumY = 0.0;
    for (final offset in values) {
      sumX += offset.dx;
      sumY += offset.dy;
    }
    return Offset(sumX / values.length, sumY / values.length);
  }

  double _activePointerSpread() {
    final values = _activePointers.values.toList(growable: false);
    if (values.length < 2) {
      return 0.0;
    }
    var minX = values.first.dx;
    var maxX = values.first.dx;
    var minY = values.first.dy;
    var maxY = values.first.dy;
    for (final offset in values.skip(1)) {
      if (offset.dx < minX) {
        minX = offset.dx;
      }
      if (offset.dx > maxX) {
        maxX = offset.dx;
      }
      if (offset.dy < minY) {
        minY = offset.dy;
      }
      if (offset.dy > maxY) {
        maxY = offset.dy;
      }
    }
    final deltaX = maxX - minX;
    final deltaY = maxY - minY;
    return math.sqrt(deltaX * deltaX + deltaY * deltaY);
  }

  Set<String> _highlightedPitchClasses() {
    final rootIndex = _PianoToolState._rootPitchClasses.indexOf(
      _rootPitchClass,
    );
    final highlights = <String>{};
    for (final interval in _activeScaleSet.intervals) {
      highlights.add(
        _PianoToolState._rootPitchClasses[(rootIndex + interval) % 12],
      );
    }
    for (final interval in _activeChordSpec.highlightIntervals) {
      highlights.add(
        _PianoToolState._rootPitchClasses[(rootIndex + interval) % 12],
      );
    }
    return highlights;
  }

  List<_PianoKey> _voicedKeysFor(_PianoKey rootKey) {
    final voiced = <_PianoKey>[];
    final seen = <String>{};
    for (final interval in _activeChordSpec.voicedIntervals) {
      final midi = rootKey.midi + interval;
      _PianoKey? key;
      for (final candidate in _activeKeyPool) {
        if (candidate.midi == midi) {
          key = candidate;
          break;
        }
      }
      for (final candidate in _PianoToolState._allKeys) {
        if (key != null) {
          break;
        }
        if (candidate.midi == midi) {
          key = candidate;
          break;
        }
      }
      if (key == null || !seen.add(key.id)) {
        continue;
      }
      voiced.add(key);
    }
    if (voiced.isEmpty) {
      voiced.add(rootKey);
    }
    return voiced;
  }

  double _volumeForVoicedIndex(int index, int total, double baseVolume) {
    if (total <= 1) {
      return baseVolume.clamp(0.0, 1.0);
    }
    final attenuation = index == 0
        ? 1.0
        : math.max(0.54, 0.92 - index * _chordFalloff);
    return (baseVolume * attenuation).clamp(0.0, 1.0).toDouble();
  }

  double _velocityForVoicedIndex(int index, int total, double baseVelocity) {
    if (total <= 1) {
      return baseVelocity.clamp(0.22, 1.0).toDouble();
    }
    final attenuation = index == 0 ? 1.0 : math.max(0.78, 0.94 - index * 0.08);
    return (baseVelocity * attenuation).clamp(0.22, 1.0).toDouble();
  }

  double _humanizedVolume(double volume, {required bool rootVoice}) {
    final spread = rootVoice ? 0.04 : 0.07;
    final jitter = (_humanizeRandom.nextDouble() - 0.5) * spread;
    return (volume * (1 + jitter)).clamp(0.0, 1.0).toDouble();
  }

  double _velocityForVolume(double volume) {
    final normalized = volume.clamp(0.18, 1.0).toDouble();
    return (0.2 + math.pow(normalized, 0.92) * 0.8).clamp(0.22, 1.0).toDouble();
  }

  ({double volume, double velocity}) _touchDynamicsForEvent(
    PointerEvent event,
    _PianoKey key,
    _PianoStageMetrics metrics,
    _PianoKeyboardSlice slice, {
    bool glissando = false,
  }) {
    final volume = _touchVolumeForPosition(
      key,
      event.localPosition,
      metrics,
      slice,
      glissando: glissando,
    );
    final rect = metrics.rectForKey(slice, key);
    if (rect == null || rect.width <= 0 || rect.height <= 0) {
      return (volume: volume, velocity: _velocityForVolume(volume));
    }
    final depth = ((event.localPosition.dx - rect.left) / rect.width)
        .clamp(0.0, 1.0)
        .toDouble();
    final heightRatio = ((event.localPosition.dy - rect.top) / rect.height)
        .clamp(0.0, 1.0)
        .toDouble();
    final pressureSpan = (event.pressureMax - event.pressureMin).abs();
    final pressureEnergy = pressureSpan > 0.05
        ? ((event.pressure - event.pressureMin) / pressureSpan)
              .clamp(0.0, 1.0)
              .toDouble()
        : 0.0;
    final lipEnergy =
        (key.isSharp ? 0.52 + heightRatio * 0.28 : 0.48 + heightRatio * 0.4)
            .clamp(0.0, 1.0)
            .toDouble();
    final depthEnergy = (key.isSharp ? 0.58 + depth * 0.22 : 0.52 + depth * 0.3)
        .clamp(0.0, 1.0)
        .toDouble();
    final glideEnergy = glissando
        ? (event.delta.distance / 42).clamp(0.0, 0.18).toDouble()
        : 0.0;
    final velocity =
        (0.16 +
            pressureEnergy * 0.34 +
            lipEnergy * 0.24 +
            depthEnergy * 0.18 +
            _velocityForVolume(volume) * 0.22 +
            glideEnergy) *
        (glissando ? 0.96 : 1.0);
    return (volume: volume, velocity: velocity.clamp(0.22, 1.0).toDouble());
  }

  Future<void> _playKey(
    _PianoKey key, {
    double? volume,
    double? velocity,
  }) async {
    final voicedKeys = _voicedKeysFor(key);
    final baseVolume = volume ?? _touch;
    final baseVelocity = velocity ?? _velocityForVolume(baseVolume);
    HapticFeedback.selectionClick();
    for (var index = 0; index < voicedKeys.length; index += 1) {
      final note = voicedKeys[index];
      final waitMs =
          (_activeChordSpec.staggerMs * _chordSpreadScale * index).round() +
          ((_humanizeRandom.nextDouble() - 0.5) * 6).round();
      final noteVolume = _humanizedVolume(
        _volumeForVoicedIndex(index, voicedKeys.length, baseVolume),
        rootVoice: index == 0,
      );
      final noteVelocity = _velocityForVoicedIndex(
        index,
        voicedKeys.length,
        baseVelocity,
      );
      unawaited(
        Future<void>.delayed(
          Duration(milliseconds: math.max(0, waitMs)),
          () async {
            await _playerFor(
              note,
              velocity: noteVelocity,
            ).play(volume: noteVolume);
          },
        ),
      );
    }
    if (!mounted) {
      return;
    }
    _setViewState(() {
      for (final note in voicedKeys) {
        _activeKeyPulseCounts.update(
          note.id,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
      _activeKeyIds = _activeKeyPulseCounts.keys.toSet();
    });
    Future<void>.delayed(const Duration(milliseconds: 170), () {
      if (!mounted) {
        return;
      }
      _setViewState(() {
        for (final note in voicedKeys) {
          final count = _activeKeyPulseCounts[note.id];
          if (count == null) {
            continue;
          }
          if (count <= 1) {
            _activeKeyPulseCounts.remove(note.id);
          } else {
            _activeKeyPulseCounts[note.id] = count - 1;
          }
        }
        _activeKeyIds = _activeKeyPulseCounts.keys.toSet();
      });
    });
  }

  void _handleStagePointerDown(
    PointerDownEvent event, {
    required _PianoStageMetrics metrics,
    required _PianoKeyboardSlice slice,
    required int octaveSpan,
  }) {
    _activePointers[event.pointer] = event.localPosition;
    final key = metrics.hitTest(slice, event.localPosition);
    if (key != null) {
      final dynamics = _touchDynamicsForEvent(event, key, metrics, slice);
      _activePointerKeyIds[event.pointer] = key.id;
      unawaited(
        _playKey(key, volume: dynamics.volume, velocity: dynamics.velocity),
      );
    }
    if (_activePointers.length >= 2) {
      _twoFingerOrigin = _activePointerCentroid();
    }
  }

  void _handleStagePointerMove(
    PointerMoveEvent event, {
    required _PianoStageMetrics metrics,
    required _PianoKeyboardSlice slice,
    required int octaveSpan,
  }) {
    if (!_activePointers.containsKey(event.pointer)) {
      return;
    }
    _activePointers[event.pointer] = event.localPosition;
    if (_activePointers.length >= 2) {
      final stageWidth = metrics.size.width;
      final aggressiveOneHand =
          _aggressiveOneHandMode && _isAggressiveOneHandWidth(stageWidth);
      final spread = _activePointerSpread();
      final minSpread = aggressiveOneHand ? 18.0 : 24.0;
      if (spread < minSpread) {
        return;
      }
      final centroid = _activePointerCentroid();
      final origin = _twoFingerOrigin ?? centroid;
      final delta = centroid - origin;
      final thresholdScale = _gestureThresholdScale.clamp(0.78, 1.28);
      final verticalThreshold = widget.fullScreen
          ? (aggressiveOneHand ? 22.0 : 28.0) * thresholdScale
          : (aggressiveOneHand ? 26.0 : 40.0) * thresholdScale;
      final horizontalThreshold = widget.fullScreen
          ? (aggressiveOneHand ? 34.0 : 42.0) *
                thresholdScale *
                (aggressiveOneHand ? 0.9 : 1.0)
          : (aggressiveOneHand ? 42.0 : 56.0) *
                thresholdScale *
                (aggressiveOneHand ? 0.9 : 1.0);
      final axisBias =
          ((aggressiveOneHand ? 0.76 : 0.9) +
                  (_gestureThresholdScale - 1.0) * 0.08)
              .clamp(0.7, 1.04)
              .toDouble();
      final rangeSwitchCooldownMs = aggressiveOneHand ? 68 : 86;
      bool allowSwitch() {
        final now = DateTime.now();
        final last = _lastRangeGestureAt;
        if (last != null &&
            now.difference(last).inMilliseconds < rangeSwitchCooldownMs) {
          return false;
        }
        _lastRangeGestureAt = now;
        return true;
      }

      if (delta.dy.abs() >= verticalThreshold &&
          delta.dy.abs() >= delta.dx.abs() * axisBias) {
        final stepCount = (delta.dy.abs() / verticalThreshold).floor();
        if (stepCount <= 0 || !allowSwitch()) {
          return;
        }
        final direction = delta.dy < 0 ? 1 : -1;
        _updateRangeStart(
          _rangeStartOctave + direction * stepCount,
          octaveSpan,
          immediateWarmUp: false,
          preloadAllKeys: false,
          indicateWarmUp: false,
        );
        _twoFingerOrigin = centroid;
      } else if (delta.dx.abs() >= horizontalThreshold) {
        final stepCount = (delta.dx.abs() / horizontalThreshold).floor();
        if (stepCount <= 0 || !allowSwitch()) {
          return;
        }
        final direction = delta.dx < 0 ? 1 : -1;
        _updateRangeStart(
          _rangeStartOctave + direction * stepCount,
          octaveSpan,
          immediateWarmUp: false,
          preloadAllKeys: false,
          indicateWarmUp: false,
        );
        _twoFingerOrigin = centroid;
      }
      return;
    }
    final key = metrics.hitTest(slice, event.localPosition);
    final lastKeyId = _activePointerKeyIds[event.pointer];
    if (key == null || key.id == lastKeyId) {
      return;
    }
    _activePointerKeyIds[event.pointer] = key.id;
    final dynamics = _touchDynamicsForEvent(
      event,
      key,
      metrics,
      slice,
      glissando: true,
    );
    unawaited(
      _playKey(key, volume: dynamics.volume, velocity: dynamics.velocity),
    );
  }

  void _handleStagePointerUp(PointerEvent event) {
    _activePointers.remove(event.pointer);
    _activePointerKeyIds.remove(event.pointer);
    if (_activePointers.length < 2) {
      _twoFingerOrigin = null;
      _lastRangeGestureAt = null;
    }
  }

  double _touchVolumeForPosition(
    _PianoKey key,
    Offset localPosition,
    _PianoStageMetrics metrics,
    _PianoKeyboardSlice slice, {
    bool glissando = false,
  }) {
    final rect = metrics.rectForKey(slice, key);
    if (rect == null || rect.width <= 0 || rect.height <= 0) {
      return (glissando ? _touch * 0.92 : _touch).clamp(0.18, 1.0).toDouble();
    }
    final depth = ((localPosition.dx - rect.left) / rect.width)
        .clamp(0.0, 1.0)
        .toDouble();
    final heightRatio = ((localPosition.dy - rect.top) / rect.height)
        .clamp(0.0, 1.0)
        .toDouble();
    final depthEnergy = key.isSharp ? 0.82 + depth * 0.18 : 0.62 + depth * 0.34;
    final centerControl = 1 - (heightRatio - 0.5).abs() * 0.18;
    final glideMul = glissando ? 0.92 : 1.0;
    return (_touch * depthEnergy * centerControl * glideMul)
        .clamp(0.18, 1.0)
        .toDouble();
  }

  String _compactFocusLabel(AppI18n i18n, _PianoCompactDeckFocus focus) {
    return switch (focus) {
      _PianoCompactDeckFocus.high => pickUiText(i18n, zh: '高音', en: 'High'),
      _ => pickUiText(i18n, zh: '低音', en: 'Low'),
    };
  }

  _PianoKeyboardSlice _sliceFor(int startOctave, int octaveSpan) {
    final chromaticPool = _activeKeyPool;
    final whitePool = chromaticPool
        .where((key) => !key.isSharp)
        .toList(growable: false);
    if (whitePool.isEmpty) {
      return const _PianoKeyboardSlice(
        whiteKeys: <_PianoKey>[],
        blackKeys: <_PianoBlackKeyPlacement>[],
        label: '--',
      );
    }
    final starts = _windowStartWhiteIndices(octaveSpan);
    final normalizedStart = startOctave.clamp(0, starts.length - 1);
    final startWhite = starts[normalizedStart];
    final endWhite = (startWhite + octaveSpan * 7).clamp(
      0,
      whitePool.length - 1,
    );
    final startMidi = whitePool[startWhite].midi;
    final endMidi = whitePool[endWhite].midi;
    final chromatic = chromaticPool
        .where((key) => key.midi >= startMidi && key.midi <= endMidi)
        .toList(growable: false);
    final whiteKeys = chromatic
        .where((key) => !key.isSharp)
        .toList(growable: false);
    final blackKeys = <_PianoBlackKeyPlacement>[];
    var whiteIndex = -1;
    for (final key in chromatic) {
      if (!key.isSharp) {
        whiteIndex += 1;
        continue;
      }
      if (whiteIndex >= 0 && whiteIndex < whiteKeys.length) {
        blackKeys.add(_PianoBlackKeyPlacement(key: key, slot: whiteIndex));
      }
    }
    return _PianoKeyboardSlice(
      whiteKeys: whiteKeys,
      blackKeys: blackKeys,
      label: '${whitePool[startWhite].label}-${whitePool[endWhite].label}',
    );
  }

  _PianoViewportSpec _viewportFor(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final width = constraints.maxWidth;
    final aggressiveOneHand =
        _aggressiveOneHandMode && _isAggressiveOneHandWidth(width);
    final compactWidth = _isCompactPhoneWidth(width);
    final denseMode =
        (_compactKeyboardMode || (compactWidth && widget.fullScreen)) &&
        !aggressiveOneHand;
    final targetHeight = widget.fullScreen
        ? math.max(420.0, screenHeight - viewPadding.vertical - 40)
        : aggressiveOneHand
        ? math.min(math.max(360.0, screenHeight * 0.52), 560.0)
        : math.min(math.max(320.0, screenHeight * 0.46), 520.0);
    var octaveSpan = widget.fullScreen
        ? width >= 940
              ? 5
              : width >= 680
              ? 4
              : 3
        : denseMode
        ? (width >= 940
              ? 5
              : width >= 680
              ? 4
              : 3)
        : (width >= 940
              ? 4
              : width >= 680
              ? 3
              : 2);
    if (aggressiveOneHand) {
      octaveSpan = math.min(octaveSpan, 2);
    }
    final minWhiteExtent = widget.fullScreen
        ? (denseMode ? 28.0 : 34.0)
        : aggressiveOneHand
        ? 46.0
        : (denseMode ? 28.0 : 40.0);
    while (octaveSpan > 1) {
      final whiteCount = octaveSpan * 7 + 1;
      if (targetHeight / whiteCount >= minWhiteExtent) {
        break;
      }
      octaveSpan -= 1;
    }
    final whiteCount = octaveSpan * 7 + 1;
    final scaledKeyHeight = _keyHeightScale * (denseMode ? 0.88 : 1.0);
    final whiteKeyExtent = ((targetHeight / whiteCount) * scaledKeyHeight)
        .clamp(minWhiteExtent, widget.fullScreen ? 72.0 : 64.0);
    final ultraCompact = _isUltraCompactPhoneWidth(width);
    return _PianoViewportSpec(
      octaveSpan: octaveSpan,
      whiteKeyExtent: whiteKeyExtent.toDouble(),
      stageHeight: whiteKeyExtent * whiteCount,
      compactLabels: ultraCompact || width < 360 || whiteKeyExtent < 44,
    );
  }
}

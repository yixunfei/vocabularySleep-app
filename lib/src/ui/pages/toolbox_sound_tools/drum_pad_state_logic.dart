part of '../toolbox_sound_tools.dart';

extension _DrumPadToolStateLogic on _DrumPadToolState {
  void _invalidatePlayers() {
    _warmUpSerial += 1;
    for (final player in _players.values) {
      unawaited(player.dispose());
    }
    _players.clear();
  }

  Future<void> _warmUpActivePreset() async {
    final serial = ++_warmUpSerial;
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (!mounted || serial != _warmUpSerial) {
      return;
    }
    for (final pad in _DrumPadToolState._pads.take(4)) {
      if (!mounted || serial != _warmUpSerial) {
        return;
      }
      await _playerFor(pad.id).warmUp();
    }
  }

  void _setKit(String value) {
    if (_kit == value) return;
    _setViewState(() {
      _kit = value;
      _presetId = '';
    });
    _invalidatePlayers();
    _restartTransportIfNeeded();
    unawaited(_warmUpActivePreset());
  }

  void _setMaterial(String value) {
    if (_material == value) return;
    _setViewState(() {
      _material = value;
      _presetId = '';
    });
    _invalidatePlayers();
    _restartTransportIfNeeded();
    unawaited(_warmUpActivePreset());
  }

  void _applyPreset(
    String presetId, {
    bool seedPattern = false,
    bool warmUp = true,
  }) {
    final preset = _DrumPadToolState._presets.firstWhere(
      (item) => item.id == presetId,
      orElse: () => _DrumPadToolState._presets.first,
    );
    _setViewState(() {
      _presetId = preset.id;
      _kit = preset.kitId;
      _material = preset.material;
      _drive = preset.drive;
      _tone = preset.tone;
      _tail = preset.tail;
    });
    _invalidatePlayers();
    if (seedPattern) {
      _applyPatternTemplate(
        _DrumPadToolState._patternTemplates.first.id,
        restartTransport: false,
      );
    } else {
      _restartTransportIfNeeded();
    }
    if (warmUp) {
      unawaited(_warmUpActivePreset());
    }
  }

  void _applyPatternTemplate(
    String templateId, {
    bool restartTransport = true,
  }) {
    final template = _DrumPadToolState._patternTemplates.firstWhere(
      (item) => item.id == templateId,
      orElse: () => _DrumPadToolState._patternTemplates.first,
    );
    _setViewState(() {
      _patternId = template.id;
      _bpm = template.bpm;
      _currentStep = -1;
      _barsPlayed = 0;
      for (final row in _sequence.values) {
        row.fillRange(0, row.length, false);
      }
      template.stepsByPad.forEach((padId, steps) {
        final row = _sequence[padId];
        if (row == null) {
          return;
        }
        for (final step in steps) {
          if (step >= 0 && step < row.length) {
            row[step] = true;
          }
        }
      });
    });
    if (restartTransport) {
      _restartTransportIfNeeded();
    }
  }

  void _clearSequence() {
    _setViewState(() {
      for (final row in _sequence.values) {
        row.fillRange(0, row.length, false);
      }
      _patternId = '';
      _currentStep = -1;
      _barsPlayed = 0;
    });
  }

  void _toggleStep(String padId, int stepIndex) {
    final row = _sequence[padId];
    if (row == null || stepIndex < 0 || stepIndex >= row.length) {
      return;
    }
    _setViewState(() {
      row[stepIndex] = !row[stepIndex];
      _patternId = '';
    });
  }

  int get _activeStepCount {
    var count = 0;
    for (final row in _sequence.values) {
      for (final value in row) {
        if (value) {
          count += 1;
        }
      }
    }
    return count;
  }

  ToolboxEffectPlayer _playerFor(String padId) {
    final cacheKey =
        'drum:$padId:$_kit:$_material:${_tone.toStringAsFixed(2)}:${_tail.toStringAsFixed(2)}';
    final existing = _players[cacheKey];
    if (existing != null) {
      return existing;
    }
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.drumHit(
        padId,
        kit: _kit,
        tone: _tone,
        tail: _tail,
        material: _material,
      ),
      maxPlayers: 6,
    );
    _players[cacheKey] = created;
    return created;
  }

  double _volumeForPad(String padId) {
    final perPad = _mixLevels[padId] ?? 0.7;
    final driveGain = 0.8 + _drive * 0.18;
    final contour = switch (padId) {
      'kick' => 1.02,
      'snare' => 0.96,
      'hihat' => 0.84,
      'openhat' => 0.78,
      'clap' => 0.88,
      _ => 0.9,
    };
    return (_masterVolume * perPad * driveGain * contour).clamp(0.0, 1.0);
  }

  Future<void> _stopPadVoices(String padId) async {
    final matched = _players.entries
        .where((entry) => entry.key.startsWith('drum:$padId:'))
        .map((entry) => entry.value)
        .toList(growable: false);
    for (final player in matched) {
      await player.stop();
    }
  }

  void _pruneLaserBeams() {
    if (_laserBeams.isEmpty) {
      if (_laserController.isAnimating) {
        _laserController.stop();
      }
      return;
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final retained = _laserBeams
        .where((beam) => nowMs - beam.startedAtMs < beam.durationMs)
        .toList(growable: false);
    if (retained.length != _laserBeams.length && mounted) {
      _setViewState(() {
        _laserBeams
          ..clear()
          ..addAll(retained);
      });
    }
    if (_laserBeams.isEmpty && _laserController.isAnimating) {
      _laserController.stop();
    }
  }

  void _setStageLightsEnabled(bool value, {bool notify = true}) {
    if (_stageLightsEnabled == value) {
      return;
    }
    _stageLightsEnabled = value;
    if (!value) {
      _laserBeams.clear();
    }
    if (notify && mounted) {
      _setViewState(() {});
    }
    if (!value && _laserController.isAnimating) {
      _laserController.stop();
    }
  }

  void _spawnLaserBeam(
    Color color, {
    double opacity = 1.0,
    double widthBias = 0.0,
    int durationBaseMs = 760,
  }) {
    if (!mounted || !_stageLightsEnabled) {
      return;
    }
    final normalizedOpacity = opacity.clamp(0.35, 1.0);
    final startAngle =
        -_DrumPadToolState._laserSweepHalfArc +
        _random.nextDouble() * (_DrumPadToolState._laserSweepHalfArc * 2);
    final endAngle =
        (startAngle +
                (-_DrumPadToolState._laserSweepHalfArc * 0.42 +
                    _random.nextDouble() *
                        (_DrumPadToolState._laserSweepHalfArc * 0.84)))
            .clamp(
              -_DrumPadToolState._laserSweepHalfArc,
              _DrumPadToolState._laserSweepHalfArc,
            );
    _setViewState(() {
      _laserBeams.add(
        _DrumLaserBeam(
          id: ++_laserSerial,
          color: color,
          coneWidthFactor: (0.12 + _random.nextDouble() * 0.08 + widthBias)
              .clamp(0.11, 0.28),
          startAngle: startAngle,
          endAngle: endAngle,
          wobblePhase: _random.nextDouble() * math.pi * 2,
          startedAtMs: DateTime.now().millisecondsSinceEpoch,
          durationMs: durationBaseMs + _random.nextInt(420),
          opacity: normalizedOpacity,
        ),
      );
      if (_laserBeams.length > 8) {
        _laserBeams.removeAt(0);
      }
    });
    if (!_laserController.isAnimating) {
      _laserController.repeat(period: const Duration(milliseconds: 16));
    }
  }

  void _spawnMetronomeLaser({required bool accent}) {
    final color = accent ? const Color(0xFF38BDF8) : const Color(0xFF93C5FD);
    _spawnLaserBeam(
      color,
      opacity: accent ? 0.92 : 0.68,
      widthBias: accent ? 0.03 : 0.0,
      durationBaseMs: accent ? 840 : 760,
    );
  }

  void _spawnPadLaser(String padId) {
    final pad = _DrumPadToolState._pads.firstWhere((item) => item.id == padId);
    final profile = switch (padId) {
      'kick' => (opacity: 1.0, width: 0.07, duration: 980),
      'snare' => (opacity: 0.96, width: 0.03, duration: 860),
      'hihat' => (opacity: 0.78, width: -0.01, duration: 700),
      'openhat' => (opacity: 0.88, width: 0.01, duration: 760),
      'clap' => (opacity: 0.94, width: 0.02, duration: 820),
      _ => (opacity: 0.9, width: 0.04, duration: 900),
    };
    _spawnLaserBeam(
      pad.color,
      opacity: widget.fullScreen ? profile.opacity : profile.opacity * 0.82,
      widthBias: profile.width,
      durationBaseMs: profile.duration,
    );
  }

  void _flashPad(String padId) {
    final nextEpoch = (_padFlashEpoch[padId] ?? 0) + 1;
    _padFlashEpoch[padId] = nextEpoch;
    if (mounted) {
      _setViewState(() {
        _activePadIds.add(padId);
      });
    }
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) {
        return;
      }
      if (_padFlashEpoch[padId] != nextEpoch) {
        return;
      }
      _setViewState(() {
        _activePadIds.remove(padId);
      });
    });
  }

  bool _isPadHeld(String padId) {
    return (_heldPadCounts[padId] ?? 0) > 0;
  }

  void _releaseHeldPad(String padId) {
    final count = _heldPadCounts[padId];
    if (count == null) {
      return;
    }
    if (count <= 1) {
      _heldPadCounts.remove(padId);
    } else {
      _heldPadCounts[padId] = count - 1;
    }
  }

  void _handlePadPointerDown(
    _DrumPadSpec pad,
    PointerDownEvent event, {
    required Size hitSize,
  }) {
    final previousPadId = _activePadPointers[event.pointer];
    if (previousPadId == pad.id) {
      return;
    }
    if (previousPadId != null) {
      _releaseHeldPad(previousPadId);
    }
    _activePadPointers[event.pointer] = pad.id;
    _heldPadCounts.update(pad.id, (count) => count + 1, ifAbsent: () => 1);
    if (mounted) {
      _setViewState(() {});
    }
    final accent = hitSize.isEmpty
        ? 1.0
        : _manualAccentForPadHit(event.localPosition, hitSize);
    unawaited(_playPad(pad.id, accent: accent));
  }

  void _handlePadPointerEnd(PointerEvent event) {
    final padId = _activePadPointers.remove(event.pointer);
    if (padId == null) {
      return;
    }
    _releaseHeldPad(padId);
    if (mounted) {
      _setViewState(() {});
    }
  }

  double _manualAccentForPadHit(Offset localPosition, Size size) {
    if (size.isEmpty) {
      return 1.0;
    }
    final center = Offset(size.width / 2, size.height / 2);
    final normDx =
        (localPosition.dx - center.dx) / math.max(1.0, size.width / 2);
    final normDy =
        (localPosition.dy - center.dy) / math.max(1.0, size.height / 2);
    final radial = math.min(1.0, math.sqrt(normDx * normDx + normDy * normDy));
    final centerWeight = 1 - radial;
    final attackBias = (1 - localPosition.dy / math.max(1.0, size.height))
        .clamp(0.0, 1.0);
    return (0.8 + centerWeight * 0.24 + attackBias * 0.06)
        .clamp(0.74, 1.12)
        .toDouble();
  }

  Future<void> _playPad(
    String padId, {
    bool manual = true,
    double accent = 1.0,
  }) async {
    if (manual) {
      HapticFeedback.selectionClick();
    }
    await _hit(padId, accent: accent);
  }

  Future<void> _hit(String padId, {double accent = 1.0}) async {
    if (padId == 'hihat' || padId == 'openhat') {
      await _stopPadVoices('openhat');
    }
    final player = _playerFor(padId);
    await player.warmUp();
    await player.play(volume: (_volumeForPad(padId) * accent).clamp(0.0, 1.0));
    if (!mounted) {
      return;
    }
    _spawnPadLaser(padId);
    _flashPad(padId);
    _setViewState(() {
      _lastHitId = padId;
      _hits += 1;
    });
  }

  void _tickTransport() {
    final nextStep = (_currentStep + 1) % _DrumPadToolState._stepCount;
    final stepHasDrums = _DrumPadToolState._pads.any(
      (pad) => _sequence[pad.id]?[nextStep] ?? false,
    );
    if (_metronomeEnabled && nextStep % 4 == 0) {
      final isAccent = nextStep == 0;
      final player = nextStep == 0
          ? _metronomeAccentPlayer
          : _metronomeRegularPlayer;
      final metronomeVolume = nextStep == 0
          ? (stepHasDrums ? 0.52 : 0.68)
          : (stepHasDrums ? 0.34 : 0.46);
      unawaited(player.play(volume: metronomeVolume));
      _spawnMetronomeLaser(accent: isAccent);
    }
    if (nextStep == 0) {
      _barsPlayed += 1;
    }
    for (final pad in _DrumPadToolState._pads) {
      final row = _sequence[pad.id];
      if (row != null && row[nextStep]) {
        final accent = switch (nextStep) {
          0 => 1.1,
          4 || 8 || 12 => 1.04,
          _ => 1.0,
        };
        unawaited(_hit(pad.id, accent: accent));
      }
    }
    if (!mounted) {
      return;
    }
    _setViewState(() {
      _currentStep = nextStep;
    });
  }

  void _startTransport() {
    _transportTimer?.cancel();
    _transportRunning = true;
    _currentStep = -1;
    _tickTransport();
    _transportTimer = Timer.periodic(_stepInterval, (_) {
      _tickTransport();
    });
    if (mounted) {
      _setViewState(() {});
    }
  }

  void _stopTransport() {
    _transportTimer?.cancel();
    _transportTimer = null;
    if (!mounted) {
      return;
    }
    _setViewState(() {
      _transportRunning = false;
      _currentStep = -1;
    });
  }

  void _restartTransportIfNeeded() {
    if (_transportRunning) {
      _startTransport();
    } else if (mounted) {
      _setViewState(() {});
    }
  }

  Future<void> _openFullScreen(BuildContext context) async {
    if (widget.fullScreen) {
      return;
    }
    final usePortraitFullScreen = MediaQuery.sizeOf(context).shortestSide < 600;
    if (usePortraitFullScreen) {
      await _enterToolboxPortraitMode();
    } else {
      await _enterToolboxLandscapeMode();
    }
    try {
      if (!context.mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(
            backgroundColor: Colors.black,
            body: _DrumPadTool(fullScreen: true),
          ),
        ),
      );
    } finally {
      await _exitToolboxLandscapeMode();
    }
  }
}

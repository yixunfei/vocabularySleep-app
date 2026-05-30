part of '../toolbox_sound_tools.dart';

class _ViolinTool extends StatefulWidget {
  const _ViolinTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_ViolinTool> createState() => _ViolinToolState();
}

class _ViolinPreset {
  const _ViolinPreset({
    required this.id,
    required this.styleId,
    required this.bow,
    required this.reverb,
    required this.scaleId,
  });

  final String id;
  final String styleId;
  final double bow;
  final double reverb;
  final String scaleId;
}

class _ViolinString {
  const _ViolinString({required this.label, required this.openMidi});

  final String label;
  final int openMidi;
}

class _ViolinToolState extends State<_ViolinTool> {
  static const List<_ViolinString> _strings = <_ViolinString>[
    _ViolinString(label: 'G3', openMidi: 55),
    _ViolinString(label: 'D4', openMidi: 62),
    _ViolinString(label: 'A4', openMidi: 69),
    _ViolinString(label: 'E5', openMidi: 76),
  ];
  static const List<_ViolinPreset> _presets = <_ViolinPreset>[
    _ViolinPreset(
      id: 'solo_bow',
      styleId: 'solo',
      bow: 0.66,
      reverb: 0.24,
      scaleId: 'major',
    ),
    _ViolinPreset(
      id: 'warm_legato',
      styleId: 'warm',
      bow: 0.58,
      reverb: 0.30,
      scaleId: 'minor',
    ),
    _ViolinPreset(
      id: 'glass_harmonic',
      styleId: 'glass',
      bow: 0.76,
      reverb: 0.18,
      scaleId: 'pentatonic',
    ),
  ];
  static const Map<String, List<int>> _scaleIntervals = <String, List<int>>{
    'major': <int>[0, 2, 4, 5, 7, 9, 11, 12],
    'minor': <int>[0, 2, 3, 5, 7, 8, 10, 12],
    'dorian': <int>[0, 2, 3, 5, 7, 9, 10, 12],
    'pentatonic': <int>[0, 3, 5, 7, 10, 12, 15],
    'chromatic': <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
  };
  static const List<int> _positionOffsets = <int>[0, 2, 5, 7];
  static const List<String> _pitchNames = <String>[
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  final ToolboxLoopController _sustainLoop = ToolboxLoopController();
  final ToolboxLoopController _doubleStopLoop = ToolboxLoopController();
  final Map<String, ToolboxEffectPlayer> _transientPlayers =
      <String, ToolboxEffectPlayer>{};
  final Map<int, Offset> _activePointers = <int, Offset>{};

  String _presetId = _presets.first.id;
  String _scaleId = _presets.first.scaleId;
  double _bow = _presets.first.bow;
  double _reverb = _presets.first.reverb;
  String _toneVariant = 'a';
  int _positionIndex = 0;
  int? _activeStringIndex;
  int? _activeNoteIndex;
  int? _activeNoteMidi;
  int? _activeDoubleStopMidi;
  String? _lastNoteLabel;
  double _bowGestureVolume = 0;
  double _bowGestureRate = 1.0;
  bool _bowing = false;

  bool _isCompactPhoneWidth(double width) {
    return width < (widget.fullScreen ? 480 : 430);
  }

  _ViolinPreset get _activePreset {
    return _presets.firstWhere(
      (item) => item.id == _presetId,
      orElse: () => _presets.first,
    );
  }

  String _presetLabel(AppI18n i18n, _ViolinPreset preset) {
    return switch (preset.id) {
      'warm_legato' => i18n.t('toolbox.sound.violin.warm_legato'),
      'glass_harmonic' => i18n.t('toolbox.sound.violin.glass_harmonic'),
      _ => i18n.t('toolbox.sound.violin.solo_bow'),
    };
  }

  String _presetSubtitle(AppI18n i18n, _ViolinPreset preset) {
    return switch (preset.id) {
      'warm_legato' => i18n.t(
        'toolbox.sound.violin.softer_bow_pressure_with_a',
      ),
      'glass_harmonic' => i18n.t(
        'toolbox.sound.violin.brighter_harmonics_with_a_cleaner',
      ),
      _ => i18n.t('toolbox.sound.violin.balanced_solo_tone_for_melodic'),
    };
  }

  String _scaleLabel(AppI18n i18n, String scaleId) {
    return switch (scaleId) {
      'minor' => i18n.t('toolbox.sound.violin.minor'),
      'dorian' => i18n.t('toolbox.sound.flute.dorian'),
      'pentatonic' => i18n.t('toolbox.sound.flute.pentatonic'),
      'chromatic' => i18n.t('toolbox.sound.violin.chromatic'),
      _ => i18n.t('toolbox.sound.flute.major'),
    };
  }

  String _styleLabel(AppI18n i18n, String styleId) {
    return switch (styleId) {
      'warm' => i18n.t('toolbox.sound.violin.warm'),
      'glass' => i18n.t('toolbox.sound.violin.glass'),
      _ => i18n.t('toolbox.sound.violin.solo'),
    };
  }

  String _positionLabel(AppI18n i18n, int positionIndex) {
    return i18n.t(
      'toolbox.sound.violin.position_2',
      params: <String, Object?>{'value': positionIndex + 1},
    );
  }

  String _variantLabel(AppI18n i18n, String variant) {
    return switch (variant) {
      'b' => i18n.t('toolbox.sound.violin.b_bright'),
      _ => i18n.t('toolbox.sound.violin.a_woody'),
    };
  }

  String _variantSubtitle(AppI18n i18n) {
    return _toneVariant == 'b'
        ? i18n.t('toolbox.sound.violin.variant_b_is_brighter_and')
        : i18n.t('toolbox.sound.violin.variant_a_is_woodier_and');
  }

  List<int> _notesForString(_ViolinString string) {
    final offset = _positionOffsets[_positionIndex];
    final intervals = _scaleIntervals[_scaleId] ?? _scaleIntervals['major']!;
    return intervals
        .map((interval) => string.openMidi + offset + interval)
        .toList(growable: false);
  }

  String _noteLabelFromMidi(int midi) {
    final pitch = _pitchNames[((midi % 12) + 12) % 12];
    final octave = (midi ~/ 12) - 1;
    return '$pitch$octave';
  }

  double _frequencyFromMidi(int midi) {
    return (440 * math.pow(2, (midi - 69) / 12)).toDouble();
  }

  ToolboxEffectPlayer _transientPlayer(String key, Uint8List bytes) {
    final existing = _transientPlayers[key];
    if (existing != null) {
      return existing;
    }
    final created = ToolboxEffectPlayer(bytes, maxPlayers: 4);
    _transientPlayers[key] = created;
    return created;
  }

  ToolboxEffectPlayer _attackPlayerForMidi(int midi) {
    final frequency = _frequencyFromMidi(midi);
    final key =
        'attack:${frequency.toStringAsFixed(2)}:${_activePreset.styleId}:'
        '$_toneVariant:${_bow.toStringAsFixed(2)}';
    return _transientPlayer(
      key,
      ToolboxAudioBank.violinBowAttack(
        frequency,
        style: _activePreset.styleId,
        variant: _toneVariant,
        bow: _bow,
      ),
    );
  }

  ToolboxEffectPlayer _tailPlayerForMidi(int midi) {
    final frequency = _frequencyFromMidi(midi);
    final key =
        'tail:${frequency.toStringAsFixed(2)}:${_activePreset.styleId}:'
        '$_toneVariant:${_bow.toStringAsFixed(2)}:${_reverb.toStringAsFixed(2)}';
    return _transientPlayer(
      key,
      ToolboxAudioBank.violinRoomTail(
        frequency,
        style: _activePreset.styleId,
        variant: _toneVariant,
        bow: _bow,
        reverb: _reverb,
      ),
    );
  }

  ({int stringIndex, int noteIndex, int midi}) _fingerboardTargetFor(
    Offset localPosition,
    Size size,
  ) {
    final laneHeight = size.height / _strings.length;
    final stringIndex = (localPosition.dy / laneHeight).floor().clamp(
      0,
      _strings.length - 1,
    );
    final notes = _notesForString(_strings[stringIndex]);
    final cellWidth = size.width / notes.length;
    final noteIndex = (localPosition.dx / cellWidth).floor().clamp(
      0,
      notes.length - 1,
    );
    return (
      stringIndex: stringIndex,
      noteIndex: noteIndex,
      midi: notes[noteIndex],
    );
  }

  double _bowVolumeForDelta(Offset delta, {bool start = false}) {
    final motion = start ? 0.28 : (delta.distance / 28).clamp(0.0, 1.0);
    return (0.18 + motion * (0.42 + _bow * 0.34)).clamp(0.16, 1.0).toDouble();
  }

  double _bowPlaybackRateForDelta(
    Offset delta,
    Size size, {
    bool start = false,
  }) {
    final lateral = size.width <= 0 ? 0.0 : (delta.dx / size.width);
    final vertical = size.height <= 0 ? 0.0 : (delta.dy / size.height);
    final motion = start ? 0.0 : (delta.distance / 24).clamp(0.0, 1.0);
    return (1.0 + lateral * 0.18 + vertical * 0.08 + motion * 0.006)
        .clamp(0.985, 1.025)
        .toDouble();
  }

  Future<void> _applyBowDynamics({
    required double volume,
    required double playbackRate,
  }) async {
    await _sustainLoop.setVolume(volume);
    await _sustainLoop.setPlaybackRate(playbackRate);
    if (_activeDoubleStopMidi != null) {
      await _doubleStopLoop.setVolume((volume * 0.72).clamp(0.0, 1.0));
      await _doubleStopLoop.setPlaybackRate(playbackRate);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _bowGestureVolume = volume;
      _bowGestureRate = playbackRate;
      _bowing = true;
    });
  }

  Future<void> _playSustain({
    required int stringIndex,
    required int noteIndex,
    required double bowVolume,
    required double playbackRate,
    bool withAttack = false,
  }) async {
    final notes = _notesForString(_strings[stringIndex]);
    final midi = notes[noteIndex.clamp(0, notes.length - 1)];
    if (withAttack) {
      unawaited(
        _attackPlayerForMidi(midi).play(
          volume: (0.12 + bowVolume * 0.24).clamp(0.0, 1.0),
          playbackRate: playbackRate,
        ),
      );
    }
    await _sustainLoop.play(
      ToolboxAudioBank.violinSustainCore(
        _frequencyFromMidi(midi),
        style: _activePreset.styleId,
        variant: _toneVariant,
        bow: _bow,
      ),
      volume: bowVolume,
      playbackRate: playbackRate,
    );

    int? doubleStopMidi;
    if (_activePointers.length >= 2) {
      final secondStringIndex = math.min(stringIndex + 1, _strings.length - 1);
      if (secondStringIndex != stringIndex) {
        final secondNotes = _notesForString(_strings[secondStringIndex]);
        doubleStopMidi =
            secondNotes[noteIndex.clamp(0, secondNotes.length - 1)];
        await _doubleStopLoop.play(
          ToolboxAudioBank.violinSustainCore(
            _frequencyFromMidi(doubleStopMidi),
            style: _activePreset.styleId,
            variant: _toneVariant,
            bow: (_bow * 0.92).clamp(0.15, 1.0),
          ),
          volume: (bowVolume * 0.72).clamp(0.0, 1.0),
          playbackRate: playbackRate,
        );
        if (withAttack) {
          unawaited(
            _attackPlayerForMidi(doubleStopMidi).play(
              volume: (0.08 + bowVolume * 0.16).clamp(0.0, 1.0),
              playbackRate: playbackRate,
            ),
          );
        }
      }
    } else {
      await _doubleStopLoop.stop();
    }

    if (!mounted) return;
    setState(() {
      _activeStringIndex = stringIndex;
      _activeNoteIndex = noteIndex;
      _activeNoteMidi = midi;
      _activeDoubleStopMidi = doubleStopMidi;
      _lastNoteLabel = _noteLabelFromMidi(midi);
      _bowGestureVolume = bowVolume;
      _bowGestureRate = playbackRate;
      _bowing = true;
    });
  }

  Future<void> _stopSustain({bool withTail = true}) async {
    final primaryMidi = _activeNoteMidi;
    final secondMidi = _activeDoubleStopMidi;
    final tailVolume = _bowGestureVolume;
    await _sustainLoop.stop();
    await _doubleStopLoop.stop();
    if (withTail && primaryMidi != null) {
      unawaited(
        _tailPlayerForMidi(
          primaryMidi,
        ).play(volume: (0.1 + tailVolume * 0.18).clamp(0.0, 1.0)),
      );
    }
    if (withTail && secondMidi != null) {
      unawaited(
        _tailPlayerForMidi(
          secondMidi,
        ).play(volume: (0.07 + tailVolume * 0.12).clamp(0.0, 1.0)),
      );
    }
    if (!mounted) return;
    setState(() {
      _activeStringIndex = null;
      _activeNoteIndex = null;
      _activeNoteMidi = null;
      _activeDoubleStopMidi = null;
      _bowGestureVolume = 0;
      _bowGestureRate = 1.0;
      _bowing = false;
    });
  }

  void _applyPreset(String presetId) {
    final preset = _presets.firstWhere(
      (item) => item.id == presetId,
      orElse: () => _presets.first,
    );
    setState(() {
      _presetId = preset.id;
      _scaleId = preset.scaleId;
      _bow = preset.bow;
      _reverb = preset.reverb;
    });
  }

  void _handleFingerboardGesture(
    Offset localPosition,
    Size size, {
    Offset delta = Offset.zero,
    bool start = false,
  }) {
    final target = _fingerboardTargetFor(localPosition, size);
    final expectsDoubleStop =
        _activePointers.length >= 2 && target.stringIndex < _strings.length - 1;
    final sameTarget =
        _activeStringIndex == target.stringIndex &&
        _activeNoteIndex == target.noteIndex &&
        _activeNoteMidi == target.midi &&
        (_activeDoubleStopMidi != null) == expectsDoubleStop;
    final bowVolume = _bowVolumeForDelta(delta, start: start);
    final playbackRate = _bowPlaybackRateForDelta(delta, size, start: start);
    if (sameTarget && _bowing) {
      unawaited(
        _applyBowDynamics(volume: bowVolume, playbackRate: playbackRate),
      );
      return;
    }
    if (_activeStringIndex != target.stringIndex ||
        _activeNoteMidi != target.midi) {
      HapticFeedback.selectionClick();
    }
    unawaited(
      _playSustain(
        stringIndex: target.stringIndex,
        noteIndex: target.noteIndex,
        bowVolume: bowVolume,
        playbackRate: playbackRate,
        withAttack: !_bowing,
      ),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.localPosition;
    if (_bowing &&
        _activePointers.length >= 2 &&
        _activeStringIndex != null &&
        _activeNoteIndex != null) {
      unawaited(
        _playSustain(
          stringIndex: _activeStringIndex!,
          noteIndex: _activeNoteIndex!,
          bowVolume: _bowGestureVolume.clamp(0.16, 1.0).toDouble(),
          playbackRate: _bowGestureRate,
        ),
      );
    }
  }

  void _handlePointerUp(PointerEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.length < 2 && _activeDoubleStopMidi != null) {
      unawaited(_doubleStopLoop.stop());
      if (mounted) {
        setState(() {
          _activeDoubleStopMidi = null;
        });
      }
    }
  }

  Widget _buildFingerboardStage(
    BuildContext context,
    AppI18n i18n,
    ThemeData theme, {
    required double width,
    required double height,
  }) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerUp,
      child: GestureDetector(
        onTapDown: (details) => _handleFingerboardGesture(
          details.localPosition,
          Size(width, height),
          start: true,
        ),
        onTapUp: (_) => unawaited(_stopSustain()),
        onTapCancel: () => unawaited(_stopSustain()),
        onPanStart: (details) => _handleFingerboardGesture(
          details.localPosition,
          Size(width, height),
          start: true,
        ),
        onPanUpdate: (details) => _handleFingerboardGesture(
          details.localPosition,
          Size(width, height),
          delta: details.delta,
        ),
        onPanEnd: (_) => unawaited(_stopSustain()),
        onPanCancel: () => unawaited(_stopSustain()),
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFF3A2A22),
                Color(0xFF5D4638),
                Color(0xFF2A1D18),
              ],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              ...List<Widget>.generate(_strings.length, (index) {
                final string = _strings[index];
                final active = _activeStringIndex == index;
                return Positioned(
                  left: 16,
                  right: 16,
                  top: (height / _strings.length) * index + 18,
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 38,
                        child: Text(
                          string.label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: active ? 4.6 : 3.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: active
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFE5D7C5),
                            boxShadow: active
                                ? <BoxShadow>[
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFBBF24,
                                      ).withValues(alpha: 0.32),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : const <BoxShadow>[],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              Positioned(
                left: 64,
                right: 18,
                bottom: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _notesForString(_strings.last)
                      .map(
                        (midi) => Text(
                          _noteLabelFromMidi(midi),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              Positioned(
                right: 16,
                top: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      i18n.t(
                        'toolbox.sound.violin.two_fingers_enable_doublestop',
                      ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViolinSettingsContent(
    BuildContext context,
    AppI18n i18n,
    ThemeData theme, {
    required VoidCallback refreshSheet,
  }) {
    final preset = _activePreset;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          i18n.t('toolbox.sound.violin.violin_settings'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: 'Scale',
              value: _scaleLabel(i18n, _scaleId),
            ),
            ToolboxMetricCard(
              label: 'Position',
              value: _positionLabel(i18n, _positionIndex),
            ),
            ToolboxMetricCard(
              label: 'Preset',
              value: _presetLabel(i18n, preset),
            ),
            ToolboxMetricCard(
              label: 'AB',
              value: _variantLabel(i18n, _toneVariant),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presets
              .map(
                (item) => ChoiceChip(
                  label: Text(_presetLabel(i18n, item)),
                  selected: item.id == _presetId,
                  onSelected: (_) {
                    _applyPreset(item.id);
                    refreshSheet();
                  },
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 8),
        Text(_presetSubtitle(i18n, preset), style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        SectionHeader(
          title: i18n.t('toolbox.sound.violin.ab_voicing'),
          subtitle: _variantSubtitle(i18n),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ChoiceChip(
              label: Text(_variantLabel(i18n, 'a')),
              selected: _toneVariant == 'a',
              onSelected: (_) {
                setState(() => _toneVariant = 'a');
                refreshSheet();
              },
            ),
            ChoiceChip(
              label: Text(_variantLabel(i18n, 'b')),
              selected: _toneVariant == 'b',
              onSelected: (_) {
                setState(() => _toneVariant = 'b');
                refreshSheet();
              },
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _scaleIntervals.keys
              .map(
                (scaleId) => ChoiceChip(
                  label: Text(_scaleLabel(i18n, scaleId)),
                  selected: _scaleId == scaleId,
                  onSelected: (_) {
                    setState(() => _scaleId = scaleId);
                    refreshSheet();
                  },
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List<Widget>.generate(_positionOffsets.length, (index) {
            return ChoiceChip(
              label: Text(_positionLabel(i18n, index)),
              selected: _positionIndex == index,
              onSelected: (_) {
                setState(() => _positionIndex = index);
                refreshSheet();
              },
            );
          }),
        ),
        const SizedBox(height: 14),
        Text(
          i18n.t(
            'toolbox.sound.violin.bow_tone',
            params: <String, Object?>{
              'pct': (_bow * 100).round(),
              'tone': _styleLabel(i18n, _activePreset.styleId),
              'variant': _variantLabel(i18n, _toneVariant),
            },
          ),
        ),
        Slider(
          value: _bow,
          min: 0.15,
          max: 1.0,
          divisions: 17,
          onChanged: (value) {
            _bow = value;
            refreshSheet();
          },
          onChangeEnd: (_) {
            if (mounted) {
              setState(() {});
            }
            refreshSheet();
          },
        ),
        Text(
          i18n.t(
            'toolbox.sound.violin.reverb',
            params: <String, Object?>{'value': (_reverb * 100).round()},
          ),
        ),
        Slider(
          value: _reverb,
          min: 0.0,
          max: 0.5,
          divisions: 10,
          onChanged: (value) {
            _reverb = value;
            refreshSheet();
          },
          onChangeEnd: (_) {
            if (mounted) {
              setState(() {});
            }
            refreshSheet();
          },
        ),
      ],
    );
  }

  Future<void> _openViolinSettingsSheet(
    BuildContext context,
    AppI18n i18n,
    ThemeData theme,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                4,
                16,
                16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SingleChildScrollView(
                child: _buildViolinSettingsContent(
                  sheetContext,
                  i18n,
                  theme,
                  refreshSheet: () => setSheetState(() {}),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    unawaited(_sustainLoop.dispose());
    unawaited(_doubleStopLoop.dispose());
    for (final player in _transientPlayers.values) {
      unawaited(player.dispose());
    }
    _transientPlayers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    final theme = Theme.of(context);
    final preset = _activePreset;

    if (widget.fullScreen) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF020617), Color(0xFF111827)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stageHeight = math.min(360.0, constraints.maxHeight - 120);
              return Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 54, 16, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: <Widget>[
                              _PianoOverlayChip(
                                label: 'Scale',
                                value: _scaleLabel(i18n, _scaleId),
                              ),
                              _PianoOverlayChip(
                                label: 'Position',
                                value: _positionLabel(i18n, _positionIndex),
                              ),
                              _PianoOverlayChip(
                                label: 'Preset',
                                value: _presetLabel(i18n, preset),
                              ),
                              _PianoOverlayChip(
                                label: 'AB',
                                value: _variantLabel(i18n, _toneVariant),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _variantSubtitle(i18n),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const Spacer(),
                          _buildFingerboardStage(
                            context,
                            i18n,
                            theme,
                            width: constraints.maxWidth - 32,
                            height: stageHeight,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 8,
                    child: FilledButton.tonal(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.38),
                        foregroundColor: Colors.white,
                      ),
                      child: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: 8,
                    child: FilledButton.tonalIcon(
                      onPressed: () =>
                          _openViolinSettingsSheet(context, i18n, theme),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.38),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.tune_rounded),
                      label: Text(i18n.t('toolbox.sound.flute.settings')),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    return _buildInstrumentPanelShell(
      context,
      fullScreen: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = _isCompactPhoneWidth(constraints.maxWidth);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  ToolboxMetricCard(
                    label: i18n.t('toolbox.sound.violin.strings'),
                    value: '${_strings.length}',
                  ),
                  ToolboxMetricCard(
                    label: i18n.t('toolbox.sound.flute.scale'),
                    value: _scaleLabel(i18n, _scaleId),
                  ),
                  ToolboxMetricCard(
                    label: i18n.t('toolbox.sound.violin.position'),
                    value: _positionLabel(i18n, _positionIndex),
                  ),
                  ToolboxMetricCard(
                    label: 'AB',
                    value: _variantLabel(i18n, _toneVariant),
                  ),
                  ToolboxMetricCard(
                    label: i18n.t('toolbox.sound.violin.last_note'),
                    value: _lastNoteLabel ?? '--',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: SectionHeader(
                      title: i18n.t('toolbox.sound.violin.fingerboard_stage'),
                      subtitle: compact
                          ? i18n.t('toolbox.sound.violin.phone_subtitle')
                          : i18n.t('toolbox.sound.violin.desktop_subtitle'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        _openViolinSettingsSheet(context, i18n, theme),
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(i18n.t('toolbox.sound.flute.settings')),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets
                    .map(
                      (item) => ChoiceChip(
                        label: Text(_presetLabel(i18n, item)),
                        selected: item.id == _presetId,
                        onSelected: (_) => _applyPreset(item.id),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 8),
              Text(
                _presetSubtitle(i18n, preset),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              SectionHeader(
                title: i18n.t('toolbox.sound.violin.ab_voicing'),
                subtitle: _variantSubtitle(i18n),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ChoiceChip(
                    label: Text(_variantLabel(i18n, 'a')),
                    selected: _toneVariant == 'a',
                    onSelected: (_) => setState(() => _toneVariant = 'a'),
                  ),
                  ChoiceChip(
                    label: Text(_variantLabel(i18n, 'b')),
                    selected: _toneVariant == 'b',
                    onSelected: (_) => setState(() => _toneVariant = 'b'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildFingerboardStage(
                context,
                i18n,
                theme,
                width: constraints.maxWidth,
                height: compact ? 204 : 220,
              ),
              const SizedBox(height: 14),
              SectionHeader(
                title: i18n.t('toolbox.sound.violin.scale_and_position'),
                subtitle: i18n.t(
                  'toolbox.sound.violin.use_scale_categories_and_position',
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _scaleIntervals.keys
                    .map(
                      (scaleId) => ChoiceChip(
                        label: Text(_scaleLabel(i18n, scaleId)),
                        selected: _scaleId == scaleId,
                        onSelected: (_) => setState(() => _scaleId = scaleId),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List<Widget>.generate(_positionOffsets.length, (
                  index,
                ) {
                  return ChoiceChip(
                    label: Text(_positionLabel(i18n, index)),
                    selected: _positionIndex == index,
                    onSelected: (_) => setState(() => _positionIndex = index),
                  );
                }),
              ),
              const SizedBox(height: 14),
              SectionHeader(
                title: i18n.t('toolbox.sound.violin.bow_and_space'),
                subtitle: i18n.t(
                  'toolbox.sound.violin.expose_bow_pressure_and_reverb',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                i18n.t(
                  'toolbox.sound.violin.bow_tone',
                  params: <String, Object?>{
                    'pct': (_bow * 100).round(),
                    'tone': _styleLabel(i18n, _activePreset.styleId),
                    'variant': _variantLabel(i18n, _toneVariant),
                  },
                ),
              ),
              Slider(
                value: _bow,
                min: 0.15,
                max: 1.0,
                divisions: 17,
                onChanged: (value) => setState(() => _bow = value),
              ),
              Text(
                i18n.t(
                  'toolbox.sound.violin.reverb',
                  params: <String, Object?>{'value': (_reverb * 100).round()},
                ),
              ),
              Slider(
                value: _reverb,
                min: 0.0,
                max: 0.5,
                divisions: 10,
                onChanged: (value) => setState(() => _reverb = value),
              ),
            ],
          );
        },
      ),
    );
  }
}

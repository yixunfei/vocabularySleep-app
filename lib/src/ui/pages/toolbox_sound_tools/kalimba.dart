part of '../toolbox_sound_tools.dart';

class _KalimbaTool extends StatefulWidget {
  const _KalimbaTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_KalimbaTool> createState() => _KalimbaToolState();
}

class _KalimbaPreset {
  const _KalimbaPreset({
    required this.id,
    required this.styleId,
    required this.scaleId,
    required this.resonance,
    required this.reverb,
    required this.volume,
  });

  final String id;
  final String styleId;
  final String scaleId;
  final double resonance;
  final double reverb;
  final double volume;
}

class _KalimbaScale {
  const _KalimbaScale({required this.id, required this.midis});

  final String id;
  final List<int> midis;
}

class _KalimbaToolState extends State<_KalimbaTool> {
  static const List<_KalimbaScale> _scales = <_KalimbaScale>[
    _KalimbaScale(
      id: 'c_major',
      midis: <int>[60, 62, 64, 65, 67, 69, 71, 72, 74, 76, 77, 79, 81],
    ),
    _KalimbaScale(
      id: 'c_pentatonic',
      midis: <int>[60, 62, 64, 67, 69, 72, 74, 76, 79, 81, 84, 86, 88],
    ),
    _KalimbaScale(
      id: 'a_minor',
      midis: <int>[57, 60, 62, 64, 65, 67, 69, 72, 74, 76, 77, 79, 81],
    ),
    _KalimbaScale(
      id: 'hirajoshi',
      midis: <int>[60, 61, 65, 67, 68, 72, 73, 77, 79, 80, 84, 85, 89],
    ),
  ];
  static const List<_KalimbaPreset> _presets = <_KalimbaPreset>[
    _KalimbaPreset(
      id: 'warm_thumb',
      styleId: 'warm',
      scaleId: 'c_pentatonic',
      resonance: 0.72,
      reverb: 0.18,
      volume: 0.86,
    ),
    _KalimbaPreset(
      id: 'bright_tines',
      styleId: 'bright',
      scaleId: 'c_major',
      resonance: 0.58,
      reverb: 0.14,
      volume: 0.82,
    ),
    _KalimbaPreset(
      id: 'dream_box',
      styleId: 'music_box',
      scaleId: 'hirajoshi',
      resonance: 0.86,
      reverb: 0.3,
      volume: 0.78,
    ),
  ];
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

  final Map<String, ToolboxNotePlayer> _players = <String, ToolboxNotePlayer>{};
  final Map<int, int> _pointerTines = <int, int>{};
  late final ToolboxSoundFontInstrumentEngine _sampledKalimbaEngine;

  String _presetId = _presets.first.id;
  String _scaleId = _presets.first.scaleId;
  String _styleId = _presets.first.styleId;
  double _resonance = _presets.first.resonance;
  double _reverb = _presets.first.reverb;
  double _volume = _presets.first.volume;
  bool _sampledKalimbaReady = false;
  bool _muted = false;
  int? _activeTine;
  String? _lastNoteLabel;
  int _playCount = 0;

  @override
  void initState() {
    super.initState();
    _sampledKalimbaEngine = _createToolboxSoundFontInstrumentEngine(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_prepareSampledKalimbaEngine());
      unawaited(_warmUpActiveScale());
    });
  }

  _KalimbaPreset get _activePreset {
    return _presets.firstWhere(
      (item) => item.id == _presetId,
      orElse: () => _presets.first,
    );
  }

  _KalimbaScale get _activeScale {
    return _scales.firstWhere(
      (item) => item.id == _scaleId,
      orElse: () => _scales.first,
    );
  }

  bool _isCompactPhoneWidth(double width) {
    return width < (widget.fullScreen ? 480 : 430);
  }

  String _presetLabel(AppI18n i18n, _KalimbaPreset preset) {
    return switch (preset.id) {
      'bright_tines' => i18n.t('toolbox.sound.kalimba.bright_tines'),
      'dream_box' => i18n.t('toolbox.sound.kalimba.dream_box'),
      _ => i18n.t('toolbox.sound.kalimba.warm_thumb'),
    };
  }

  String _presetSubtitle(AppI18n i18n, _KalimbaPreset preset) {
    return switch (preset.id) {
      'bright_tines' => i18n.t('toolbox.sound.kalimba.bright_tines_sub'),
      'dream_box' => i18n.t('toolbox.sound.kalimba.dream_box_sub'),
      _ => i18n.t('toolbox.sound.kalimba.warm_thumb_sub'),
    };
  }

  String _scaleLabel(AppI18n i18n, String scaleId) {
    return switch (scaleId) {
      'c_pentatonic' => i18n.t('toolbox.sound.kalimba.c_pentatonic'),
      'a_minor' => i18n.t('toolbox.sound.kalimba.a_minor'),
      'hirajoshi' => i18n.t('toolbox.sound.kalimba.hirajoshi'),
      _ => i18n.t('toolbox.sound.kalimba.c_major'),
    };
  }

  String _noteLabelFromMidi(int midi) {
    final pitch = _pitchNames[((midi % 12) + 12) % 12];
    final octave = (midi ~/ 12) - 1;
    return '$pitch$octave';
  }

  double _frequencyFromMidi(int midi) {
    return (440 * math.pow(2, (midi - 69) / 12)).toDouble();
  }

  String _playerKeyForMidi(int midi, {double velocity = 0.76}) {
    return '$midi:$_styleId:${_resonance.toStringAsFixed(2)}:'
        '${_reverb.toStringAsFixed(2)}:${velocity.toStringAsFixed(2)}';
  }

  Future<void> _prepareSampledKalimbaEngine() async {
    final ready = await _sampledKalimbaEngine.ensurePatch(
      bank: ToolboxInstrumentBankCatalog.museScoreGeneral,
      patch: ToolboxInstrumentBankCatalog.kalimba,
      volume: _volume,
      reverb: _reverb,
    );
    if (!mounted || ready == _sampledKalimbaReady) {
      return;
    }
    setState(() {
      _sampledKalimbaReady = ready;
    });
    _invalidatePlayers();
    unawaited(_warmUpActiveScale());
  }

  ToolboxNotePlayer _playerForMidi(int midi, {double velocity = 0.76}) {
    final key = _playerKeyForMidi(midi, velocity: velocity);
    final existing = _players[key];
    if (existing != null) return existing;
    if (_sampledKalimbaReady) {
      final sampled = ToolboxSampledMidiNotePlayer(
        engine: _sampledKalimbaEngine,
        bank: ToolboxInstrumentBankCatalog.museScoreGeneral,
        patch: ToolboxInstrumentBankCatalog.kalimba,
        midiNote: midi,
        velocity: velocity,
        releaseAfter: Duration(
          milliseconds: (920 + _resonance.clamp(0.2, 1.0) * 1380).round(),
        ),
        volume: _volume,
        reverb: _reverb,
      );
      _players[key] = sampled;
      return sampled;
    }
    final fallback = ToolboxEffectPlayer(
      ToolboxAudioBank.kalimbaNote(
        _frequencyFromMidi(midi),
        style: _styleId,
        resonance: _resonance,
        reverb: _reverb,
        variant: midi % 13,
      ),
      maxPlayers: 10,
    );
    _players[key] = fallback;
    return fallback;
  }

  void _invalidatePlayers() {
    for (final player in _players.values) {
      unawaited(player.dispose());
    }
    _players.clear();
  }

  Future<void> _warmUpActiveScale() async {
    final notes = _activeScale.midis;
    final warmIndexes = <int>{0, notes.length ~/ 2, notes.length - 1};
    for (final index in warmIndexes) {
      if (!mounted) return;
      await _playerForMidi(notes[index]).warmUp();
      await Future<void>.delayed(const Duration(milliseconds: 8));
    }
  }

  void _applyPreset(String presetId) {
    final preset = _presets.firstWhere(
      (item) => item.id == presetId,
      orElse: () => _presets.first,
    );
    setState(() {
      _presetId = preset.id;
      _scaleId = preset.scaleId;
      _styleId = preset.styleId;
      _resonance = preset.resonance;
      _reverb = preset.reverb;
      _volume = preset.volume;
    });
    _invalidatePlayers();
    if (_sampledKalimbaReady) {
      unawaited(_prepareSampledKalimbaEngine());
    }
    unawaited(_warmUpActiveScale());
  }

  void _applyScale(String scaleId) {
    if (_scaleId == scaleId) return;
    setState(() {
      _scaleId = scaleId;
      _activeTine = null;
    });
    _invalidatePlayers();
    unawaited(_warmUpActiveScale());
  }

  int? _tineIndexForPosition(Offset position, Size size) {
    if (position.dx < 0 ||
        position.dy < 0 ||
        position.dx > size.width ||
        position.dy > size.height) {
      return null;
    }
    final count = _activeScale.midis.length;
    final laneWidth = size.width / count;
    return (position.dx / laneWidth).floor().clamp(0, count - 1);
  }

  double _velocityForGesture(Offset delta, {bool initial = false}) {
    if (initial) return 0.78;
    return (0.48 + delta.distance / 56).clamp(0.34, 1.0).toDouble();
  }

  Future<void> _playTine(int index, {double velocity = 0.78}) async {
    if (_muted) return;
    final notes = _activeScale.midis;
    if (index < 0 || index >= notes.length) return;
    final midi = notes[index];
    HapticFeedback.selectionClick();
    unawaited(
      _playerForMidi(
        midi,
        velocity: velocity,
      ).play(volume: (_volume * (0.7 + velocity * 0.38)).clamp(0.0, 1.0)),
    );
    if (!mounted) return;
    setState(() {
      _activeTine = index;
      _lastNoteLabel = _noteLabelFromMidi(midi);
      _playCount += 1;
    });
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      if (!mounted || _activeTine != index) return;
      setState(() => _activeTine = null);
    });
  }

  void _handleStagePointerDown(PointerDownEvent event, Size size) {
    final index = _tineIndexForPosition(event.localPosition, size);
    if (index == null) return;
    _pointerTines[event.pointer] = index;
    unawaited(_playTine(index, velocity: _velocityForGesture(Offset.zero)));
  }

  void _handleStagePointerMove(PointerMoveEvent event, Size size) {
    final index = _tineIndexForPosition(event.localPosition, size);
    if (index == null) return;
    final previous = _pointerTines[event.pointer];
    if (previous == index) return;
    _pointerTines[event.pointer] = index;
    unawaited(_playTine(index, velocity: _velocityForGesture(event.delta)));
  }

  void _handleStagePointerUp(PointerEvent event) {
    _pointerTines.remove(event.pointer);
  }

  Widget _buildKalimbaStage(
    BuildContext context, {
    required AppI18n i18n,
    required double height,
    required bool immersive,
  }) {
    final theme = Theme.of(context);
    final notes = _activeScale.midis;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final stageSize = Size(width, height);
        final laneWidth = width / notes.length;
        final compact = width < 390;
        return _ToolboxScrollLockSurface(
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) => _handleStagePointerDown(event, stageSize),
            onPointerMove: (event) => _handleStagePointerMove(event, stageSize),
            onPointerUp: _handleStagePointerUp,
            onPointerCancel: _handleStagePointerUp,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: double.infinity,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  widget.fullScreen ? 26 : 20,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    immersive
                        ? const Color(0xFF102A2C)
                        : const Color(0xFFE7F4F2),
                    immersive
                        ? const Color(0xFF2B1C16)
                        : const Color(0xFFF0D8B8),
                  ],
                ),
                border: Border.all(
                  color: immersive
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFF88A7A2),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: immersive ? 0.3 : 0.12,
                    ),
                    blurRadius: immersive ? 26 : 14,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: compact ? 12 : 18,
                    right: compact ? 12 : 18,
                    top: 18,
                    height: height * 0.34,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: immersive
                            ? const Color(0xFF6B3F26)
                            : const Color(0xFFB8733E),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: compact ? 24 : 34,
                    right: compact ? 24 : 34,
                    top: height * 0.18,
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: immersive
                            ? const Color(0xFF273449)
                            : const Color(0xFF4B6473),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  for (var index = 0; index < notes.length; index += 1)
                    _KalimbaTine(
                      left: laneWidth * index + laneWidth * 0.12,
                      width: laneWidth * 0.76,
                      height: height,
                      active: _activeTine == index,
                      label: _noteLabelFromMidi(notes[index]),
                      index: index,
                      count: notes.length,
                      immersive: immersive,
                      textStyle: theme.textTheme.labelSmall,
                    ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          i18n.t('toolbox.sound.kalimba.low_tines'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: immersive
                                ? Colors.white70
                                : const Color(0xFF30545A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          i18n.t('toolbox.sound.kalimba.high_tines'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: immersive
                                ? Colors.white70
                                : const Color(0xFF30545A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPresetChips(AppI18n i18n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _presets
          .map(
            (preset) => ChoiceChip(
              label: Text(_presetLabel(i18n, preset)),
              selected: _presetId == preset.id,
              onSelected: (_) => _applyPreset(preset.id),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildScaleChips(AppI18n i18n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _scales
          .map(
            (scale) => ChoiceChip(
              label: Text(_scaleLabel(i18n, scale.id)),
              selected: _scaleId == scale.id,
              onSelected: (_) => _applyScale(scale.id),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildFullScreen(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF071819),
            Color(0xFF102A2C),
            Color(0xFF1F130E),
          ],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stageHeight = math
                .max(260.0, math.min(460.0, constraints.maxHeight - 230))
                .toDouble();
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14, 58, 14, bottomInset + 118),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            _PianoOverlayChip(
                              label: i18n.t('toolbox.sound.harp.preset'),
                              value: _presetLabel(i18n, _activePreset),
                            ),
                            _PianoOverlayChip(
                              label: i18n.t('toolbox.sound.flute.scale'),
                              value: _scaleLabel(i18n, _scaleId),
                            ),
                            _PianoOverlayChip(
                              label: i18n.t('toolbox.sound.kalimba.last_note'),
                              value: _lastNoteLabel ?? '--',
                            ),
                          ],
                        ),
                        const Spacer(),
                        _buildKalimbaStage(
                          context,
                          i18n: i18n,
                          height: stageHeight,
                          immersive: true,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 8,
                  child: Row(
                    children: <Widget>[
                      FilledButton.tonal(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.34),
                          foregroundColor: Colors.white,
                        ),
                        child: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Spacer(),
                      FilledButton.tonal(
                        onPressed: () => setState(() => _muted = !_muted),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.34),
                          foregroundColor: Colors.white,
                        ),
                        child: Icon(
                          _muted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: bottomInset + 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            _presetSubtitle(i18n, _activePreset),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildPresetChips(i18n),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _invalidatePlayers();
    unawaited(_sampledKalimbaEngine.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    final theme = Theme.of(context);
    if (widget.fullScreen) {
      return _buildFullScreen(context, i18n);
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
                    label: i18n.t('toolbox.sound.kalimba.tines'),
                    value: '${_activeScale.midis.length}',
                  ),
                  ToolboxMetricCard(
                    label: i18n.t('toolbox.sound.flute.scale'),
                    value: _scaleLabel(i18n, _scaleId),
                  ),
                  ToolboxMetricCard(
                    label: i18n.t('toolbox.sound.harp.preset'),
                    value: _presetLabel(i18n, _activePreset),
                  ),
                  ToolboxMetricCard(
                    label: i18n.t('toolbox.sound.kalimba.last_note'),
                    value: _lastNoteLabel ?? '--',
                  ),
                  ToolboxMetricCard(
                    label: i18n.t('toolbox.sound.kalimba.plays'),
                    value: '$_playCount',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SectionHeader(
                title: i18n.t('toolbox.sound.kalimba.thumb_stage'),
                subtitle: compact
                    ? i18n.t('toolbox.sound.kalimba.phone_stage_sub')
                    : i18n.t('toolbox.sound.kalimba.wide_stage_sub'),
              ),
              const SizedBox(height: 10),
              _buildKalimbaStage(
                context,
                i18n: i18n,
                height: compact ? 256 : 300,
                immersive: false,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: () => setState(() => _muted = !_muted),
                    icon: Icon(
                      _muted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                    ),
                    label: Text(
                      _muted
                          ? i18n.t('toolbox.sound.harp.muted')
                          : i18n.t('toolbox.sound.harp.sound_on'),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      final middle = _activeScale.midis.length ~/ 2;
                      unawaited(_playTine(middle, velocity: 0.82));
                    },
                    icon: const Icon(Icons.touch_app_rounded),
                    label: Text(i18n.t('toolbox.sound.kalimba.play_center')),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SectionHeader(
                title: i18n.t('toolbox.sound.kalimba.sound_palette'),
                subtitle: i18n.t('toolbox.sound.kalimba.sound_palette_sub'),
              ),
              const SizedBox(height: 10),
              _buildPresetChips(i18n),
              const SizedBox(height: 8),
              Text(
                _presetSubtitle(i18n, _activePreset),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              SectionHeader(
                title: i18n.t('toolbox.sound.kalimba.scale_picker'),
                subtitle: i18n.t('toolbox.sound.kalimba.scale_picker_sub'),
              ),
              const SizedBox(height: 10),
              _buildScaleChips(i18n),
              const SizedBox(height: 12),
              Text(
                i18n.t(
                  'toolbox.sound.kalimba.resonance',
                  params: <String, Object?>{
                    'value': (_resonance * 100).round(),
                  },
                ),
              ),
              Slider(
                value: _resonance,
                min: 0.2,
                max: 1.0,
                divisions: 16,
                onChanged: (value) => setState(() => _resonance = value),
                onChangeEnd: (_) {
                  _invalidatePlayers();
                  unawaited(_warmUpActiveScale());
                },
              ),
              Text(
                i18n.t(
                  'toolbox.sound.instrument.reverb',
                  params: <String, Object?>{'value': (_reverb * 100).round()},
                ),
              ),
              Slider(
                value: _reverb,
                min: 0,
                max: 0.55,
                divisions: 11,
                onChanged: (value) => setState(() => _reverb = value),
                onChangeEnd: (_) {
                  _invalidatePlayers();
                  if (_sampledKalimbaReady) {
                    unawaited(_prepareSampledKalimbaEngine());
                  }
                  unawaited(_warmUpActiveScale());
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _KalimbaTine extends StatelessWidget {
  const _KalimbaTine({
    required this.left,
    required this.width,
    required this.height,
    required this.active,
    required this.label,
    required this.index,
    required this.count,
    required this.immersive,
    required this.textStyle,
  });

  final double left;
  final double width;
  final double height;
  final bool active;
  final String label;
  final int index;
  final int count;
  final bool immersive;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final lowToHigh = count <= 1 ? 0.0 : index / (count - 1);
    final tineHeight = height * (0.66 - lowToHigh * 0.24);
    final top = height * 0.22;
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: tineHeight,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, active ? 5 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              active ? const Color(0xFFFFE08A) : const Color(0xFFF7EFE2),
              active ? const Color(0xFFD8A734) : const Color(0xFF9CA3AF),
              immersive ? const Color(0xFF394150) : const Color(0xFF60717A),
            ],
          ),
          boxShadow: active
              ? <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFFFFD166).withValues(alpha: 0.42),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: textStyle?.copyWith(
                  color: active
                      ? const Color(0xFF3B2A09)
                      : (immersive ? Colors.white : const Color(0xFF24333A)),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

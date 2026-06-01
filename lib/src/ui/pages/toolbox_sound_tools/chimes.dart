part of '../toolbox_sound_tools.dart';

class _ChimesTool extends StatefulWidget {
  const _ChimesTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_ChimesTool> createState() => _ChimesToolState();
}

class _ChimesToolState extends State<_ChimesTool> {
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
  final Map<int, int> _pointerBars = <int, int>{};
  late final ToolboxSoundFontInstrumentEngine _sampledMalletEngine;

  String _instrumentId = _malletInstrumentSpecs.first.id;
  String _materialId = 'wood';
  String _cavityId = 'open_box';
  double _tail = _malletInstrumentSpecs.first.defaultTail;
  double _reverb = _malletInstrumentSpecs.first.defaultReverb;
  double _volume = _malletInstrumentSpecs.first.volume;
  bool _sampledMalletReady = false;
  bool _sweepInFlight = false;
  int? _activeBar;
  String? _lastNoteLabel;

  @override
  void initState() {
    super.initState();
    _sampledMalletEngine = _createToolboxSoundFontInstrumentEngine(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_prepareSampledMalletEngine());
      unawaited(_warmUpCoreBars());
    });
  }

  _MalletInstrumentSpec get _activeInstrument {
    return _malletInstrumentById(_instrumentId);
  }

  _MalletMaterialSpec get _activeMaterial {
    return _malletMaterialById(_materialId);
  }

  _MalletCavitySpec get _activeCavity {
    return _malletCavityById(_cavityId);
  }

  List<int> get _activeMidis => _activeInstrument.midis;

  double get _effectiveTail {
    return (_tail + _activeMaterial.tailBias + _activeCavity.tailBias)
        .clamp(0.12, 1.0)
        .toDouble();
  }

  double get _effectiveReverb {
    return (_reverb + _activeMaterial.reverbBias + _activeCavity.reverbBias)
        .clamp(0.0, 0.85)
        .toDouble();
  }

  double get _effectiveVolume {
    return (_volume + _activeMaterial.volumeBias).clamp(0.0, 1.0).toDouble();
  }

  bool _isCompactPhoneWidth(double width) {
    return width < (widget.fullScreen ? 520 : 430);
  }

  String _instrumentLabel(AppI18n i18n, _MalletInstrumentSpec spec) {
    return switch (spec.id) {
      'chimes' => i18n.t('toolbox.sound.mallet.type_chimes'),
      'vibraphone' => i18n.t('toolbox.sound.mallet.type_vibraphone'),
      'marimba' => i18n.t('toolbox.sound.mallet.type_marimba'),
      'glockenspiel' => i18n.t('toolbox.sound.mallet.type_glockenspiel'),
      _ => i18n.t('toolbox.sound.mallet.type_xylophone'),
    };
  }

  String _instrumentSubtitle(AppI18n i18n, _MalletInstrumentSpec spec) {
    return switch (spec.id) {
      'chimes' => i18n.t('toolbox.sound.mallet.type_chimes_sub'),
      'vibraphone' => i18n.t('toolbox.sound.mallet.type_vibraphone_sub'),
      'marimba' => i18n.t('toolbox.sound.mallet.type_marimba_sub'),
      'glockenspiel' => i18n.t('toolbox.sound.mallet.type_glockenspiel_sub'),
      _ => i18n.t('toolbox.sound.mallet.type_xylophone_sub'),
    };
  }

  String _materialLabel(AppI18n i18n, _MalletMaterialSpec material) {
    return switch (material.id) {
      'iron' => i18n.t('toolbox.sound.mallet.material_iron'),
      'copper' => i18n.t('toolbox.sound.mallet.material_copper'),
      'glass' => i18n.t('toolbox.sound.mallet.material_glass'),
      'ceramic' => i18n.t('toolbox.sound.mallet.material_ceramic'),
      'plastic' => i18n.t('toolbox.sound.mallet.material_plastic'),
      _ => i18n.t('toolbox.sound.mallet.material_wood'),
    };
  }

  String _cavityLabel(AppI18n i18n, _MalletCavitySpec cavity) {
    return switch (cavity.id) {
      'shallow' => i18n.t('toolbox.sound.mallet.cavity_shallow'),
      'long_tubes' => i18n.t('toolbox.sound.mallet.cavity_long_tubes'),
      'closed_box' => i18n.t('toolbox.sound.mallet.cavity_closed_box'),
      _ => i18n.t('toolbox.sound.mallet.cavity_open_box'),
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

  Color _barColorFor(int index) {
    final rainbow = _malletRainbowColors[index % _malletRainbowColors.length];
    if (_instrumentId == 'xylophone') {
      return rainbow;
    }
    return Color.lerp(rainbow, _activeMaterial.tint, 0.66)!;
  }

  String _playerKeyForMidi(int midi, {double velocity = 0.78}) {
    return '$midi:$_instrumentId:$_materialId:$_cavityId:'
        '${_effectiveTail.toStringAsFixed(2)}:'
        '${_effectiveReverb.toStringAsFixed(2)}:'
        '${velocity.toStringAsFixed(2)}';
  }

  Future<void> _prepareSampledMalletEngine() async {
    final ready = await _sampledMalletEngine.ensurePatch(
      bank: ToolboxInstrumentBankCatalog.museScoreGeneral,
      patch: _activeInstrument.patch,
      volume: _effectiveVolume,
      reverb: _effectiveReverb,
    );
    if (!mounted) return;
    if (ready != _sampledMalletReady) {
      setState(() {
        _sampledMalletReady = ready;
      });
    }
    if (ready) {
      _invalidatePlayers();
      unawaited(_warmUpCoreBars());
    }
  }

  int _releaseMilliseconds() {
    final base = switch (_instrumentId) {
      'chimes' => 1220,
      'vibraphone' => 940,
      'glockenspiel' => 880,
      'marimba' => 620,
      _ => 520,
    };
    final span = switch (_instrumentId) {
      'chimes' => 3000,
      'vibraphone' => 2500,
      'glockenspiel' => 2200,
      'marimba' => 1600,
      _ => 1300,
    };
    return (base + _effectiveTail * span).round();
  }

  ToolboxNotePlayer _playerForMidi(int midi, {double velocity = 0.78}) {
    final key = _playerKeyForMidi(midi, velocity: velocity);
    final existing = _players[key];
    if (existing != null) return existing;
    if (_sampledMalletReady) {
      final sampled = ToolboxSampledMidiNotePlayer(
        engine: _sampledMalletEngine,
        bank: ToolboxInstrumentBankCatalog.museScoreGeneral,
        patch: _activeInstrument.patch,
        midiNote: midi,
        velocity: velocity,
        releaseAfter: Duration(milliseconds: _releaseMilliseconds()),
        volume: _effectiveVolume,
        reverb: _effectiveReverb,
      );
      _players[key] = sampled;
      return sampled;
    }
    final fallback = ToolboxEffectPlayer(
      ToolboxAudioBank.chimeNote(
        _frequencyFromMidi(midi),
        style: _instrumentId,
        tail: _effectiveTail,
        reverb: _effectiveReverb,
        variant: midi % 17,
      ),
      maxPlayers: 12,
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

  Future<void> _warmUpCoreBars() async {
    final notes = _activeMidis;
    final warmIndexes = <int>{0, notes.length ~/ 2, notes.length - 1};
    for (final index in warmIndexes) {
      if (!mounted) return;
      await _playerForMidi(notes[index]).warmUp();
      await Future<void>.delayed(const Duration(milliseconds: 8));
    }
  }

  void _applyInstrument(String id) {
    if (_instrumentId == id) return;
    final spec = _malletInstrumentById(id);
    setState(() {
      _instrumentId = spec.id;
      _tail = spec.defaultTail;
      _reverb = spec.defaultReverb;
      _volume = spec.volume;
      _activeBar = null;
    });
    _invalidatePlayers();
    unawaited(_prepareSampledMalletEngine());
    unawaited(_warmUpCoreBars());
  }

  void _applyMaterial(String id) {
    if (_materialId == id) return;
    setState(() => _materialId = id);
    _invalidatePlayers();
    unawaited(_prepareSampledMalletEngine());
    unawaited(_warmUpCoreBars());
  }

  void _applyCavity(String id) {
    if (_cavityId == id) return;
    setState(() => _cavityId = id);
    _invalidatePlayers();
    unawaited(_prepareSampledMalletEngine());
    unawaited(_warmUpCoreBars());
  }

  int? _barIndexForPosition(
    Offset position,
    Size size, {
    required bool rotated,
  }) {
    if (position.dx < 0 ||
        position.dy < 0 ||
        position.dx > size.width ||
        position.dy > size.height) {
      return null;
    }
    final count = _activeMidis.length;
    if (rotated) {
      final laneHeight = size.height / count;
      return (position.dy / laneHeight).floor().clamp(0, count - 1);
    }
    final laneWidth = size.width / count;
    return (position.dx / laneWidth).floor().clamp(0, count - 1);
  }

  double _velocityForGesture(Offset delta, {bool initial = false}) {
    if (initial) return 0.82;
    return (0.5 + delta.distance / 52).clamp(0.34, 1.0).toDouble();
  }

  Future<void> _strikeBar(int index, {double velocity = 0.82}) async {
    final notes = _activeMidis;
    if (index < 0 || index >= notes.length) return;
    final midi = notes[index];
    HapticFeedback.lightImpact();
    unawaited(
      _playerForMidi(midi, velocity: velocity).play(
        volume: (_effectiveVolume * (0.68 + velocity * 0.42)).clamp(0.0, 1.0),
      ),
    );
    if (!mounted) return;
    setState(() {
      _activeBar = index;
      _lastNoteLabel = _noteLabelFromMidi(midi);
    });
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (!mounted || _activeBar != index) return;
      setState(() => _activeBar = null);
    });
  }

  void _handleStagePointerDown(
    PointerDownEvent event,
    Size size, {
    required bool rotated,
  }) {
    final index = _barIndexForPosition(
      event.localPosition,
      size,
      rotated: rotated,
    );
    if (index == null) return;
    _pointerBars[event.pointer] = index;
    unawaited(_strikeBar(index, velocity: _velocityForGesture(Offset.zero)));
  }

  void _handleStagePointerMove(
    PointerMoveEvent event,
    Size size, {
    required bool rotated,
  }) {
    final index = _barIndexForPosition(
      event.localPosition,
      size,
      rotated: rotated,
    );
    if (index == null) return;
    final previous = _pointerBars[event.pointer];
    if (previous == index) return;
    _pointerBars[event.pointer] = index;
    unawaited(_strikeBar(index, velocity: _velocityForGesture(event.delta)));
  }

  void _handleStagePointerUp(PointerEvent event) {
    _pointerBars.remove(event.pointer);
  }

  Future<void> _playSweep({required bool ascending}) async {
    if (_sweepInFlight) return;
    _sweepInFlight = true;
    final count = _activeMidis.length;
    final indexes = ascending
        ? List<int>.generate(count, (index) => index)
        : List<int>.generate(count, (index) => count - 1 - index);
    for (final index in indexes) {
      if (!mounted) break;
      await _strikeBar(index, velocity: 0.72);
      await Future<void>.delayed(const Duration(milliseconds: 64));
    }
    _sweepInFlight = false;
  }

  Future<void> _dampAll() async {
    for (final player in _players.values) {
      await player.stop();
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _activeBar = null);
  }

  Widget _buildInstrumentChips(AppI18n i18n, {VoidCallback? onChanged}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _malletInstrumentSpecs
          .map(
            (spec) => ChoiceChip(
              label: Text(_instrumentLabel(i18n, spec)),
              selected: _instrumentId == spec.id,
              onSelected: (_) {
                _applyInstrument(spec.id);
                onChanged?.call();
              },
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildMaterialChips(AppI18n i18n, {VoidCallback? onChanged}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _malletMaterialSpecs
          .map(
            (spec) => ChoiceChip(
              label: Text(_materialLabel(i18n, spec)),
              selected: _materialId == spec.id,
              onSelected: (_) {
                _applyMaterial(spec.id);
                onChanged?.call();
              },
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildCavityChips(AppI18n i18n, {VoidCallback? onChanged}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _malletCavitySpecs
          .map(
            (spec) => ChoiceChip(
              label: Text(_cavityLabel(i18n, spec)),
              selected: _cavityId == spec.id,
              onSelected: (_) {
                _applyCavity(spec.id);
                onChanged?.call();
              },
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildQuickActions(AppI18n i18n, {required bool immersive}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        FilledButton.tonalIcon(
          onPressed: () => unawaited(_playSweep(ascending: true)),
          icon: const Icon(Icons.east_rounded),
          label: Text(i18n.t('toolbox.sound.mallet.sweep_up')),
        ),
        FilledButton.tonalIcon(
          onPressed: () => unawaited(_playSweep(ascending: false)),
          icon: const Icon(Icons.west_rounded),
          label: Text(i18n.t('toolbox.sound.mallet.sweep_down')),
        ),
        OutlinedButton.icon(
          onPressed: () => unawaited(_dampAll()),
          icon: const Icon(Icons.volume_off_rounded),
          label: Text(i18n.t('toolbox.sound.mallet.damp')),
          style: immersive
              ? OutlinedButton.styleFrom(foregroundColor: Colors.white)
              : null,
        ),
      ],
    );
  }

  Future<void> _openMalletSettingsSheet(
    BuildContext context,
    AppI18n i18n, {
    required bool showExit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final theme = Theme.of(sheetContext);
            void refresh() => setSheetState(() {});
            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                0,
                18,
                18 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            i18n.t('toolbox.sound.instrument.settings'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: i18n.t(
                            'toolbox.sound.instrument.close_settings',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _buildQuickActions(i18n, immersive: false),
                        if (showExit)
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.close_fullscreen_rounded),
                            label: Text(
                              i18n.t(
                                'toolbox.sound.instrument.exit_full_screen',
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SectionHeader(
                      title: i18n.t('toolbox.sound.mallet.instrument_type'),
                      subtitle: _instrumentSubtitle(i18n, _activeInstrument),
                    ),
                    const SizedBox(height: 10),
                    _buildInstrumentChips(i18n, onChanged: refresh),
                    const SizedBox(height: 16),
                    SectionHeader(
                      title: i18n.t('toolbox.sound.mallet.material'),
                      subtitle: i18n.t('toolbox.sound.mallet.material_sub'),
                    ),
                    const SizedBox(height: 10),
                    _buildMaterialChips(i18n, onChanged: refresh),
                    const SizedBox(height: 16),
                    SectionHeader(
                      title: i18n.t('toolbox.sound.mallet.cavity'),
                      subtitle: i18n.t('toolbox.sound.mallet.cavity_sub'),
                    ),
                    const SizedBox(height: 10),
                    _buildCavityChips(i18n, onChanged: refresh),
                    const SizedBox(height: 16),
                    Text(
                      i18n.t(
                        'toolbox.sound.mallet.tail',
                        params: <String, Object?>{
                          'value': (_effectiveTail * 100).round(),
                        },
                      ),
                    ),
                    Slider(
                      value: _tail,
                      min: 0.15,
                      max: 1.0,
                      divisions: 17,
                      onChanged: (value) {
                        setState(() => _tail = value);
                        refresh();
                      },
                      onChangeEnd: (_) {
                        _invalidatePlayers();
                        unawaited(_warmUpCoreBars());
                      },
                    ),
                    Text(
                      i18n.t(
                        'toolbox.sound.instrument.reverb',
                        params: <String, Object?>{
                          'value': (_effectiveReverb * 100).round(),
                        },
                      ),
                    ),
                    Slider(
                      value: _reverb,
                      min: 0,
                      max: 0.7,
                      divisions: 14,
                      onChanged: (value) {
                        setState(() => _reverb = value);
                        refresh();
                      },
                      onChangeEnd: (_) {
                        _invalidatePlayers();
                        unawaited(_prepareSampledMalletEngine());
                        unawaited(_warmUpCoreBars());
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFullScreen(BuildContext context, AppI18n i18n) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF111827),
            Color(0xFF2B1C14),
            Color(0xFF141B24),
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stageHeight = math.max(240.0, constraints.maxHeight - 20);
          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _buildMalletStage(
                    context,
                    i18n: i18n,
                    height: stageHeight,
                    immersive: true,
                  ),
                ),
              ),
              Positioned(
                top: viewPadding.top + 10,
                right: viewPadding.right + 10,
                child: IconButton.filledTonal(
                  onPressed: () =>
                      _openMalletSettingsSheet(context, i18n, showExit: true),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.46),
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    minimumSize: const Size.square(52),
                  ),
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: i18n.t('toolbox.sound.instrument.settings'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _invalidatePlayers();
    unawaited(_sampledMalletEngine.dispose());
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
                    label: i18n.t('toolbox.sound.mallet.bars'),
                    value: '${_activeMidis.length}',
                  ),
                  ToolboxMetricCard(
                    label: i18n.t('toolbox.sound.mallet.instrument_type'),
                    value: _instrumentLabel(i18n, _activeInstrument),
                  ),
                  ToolboxMetricCard(
                    label: i18n.t('toolbox.sound.mallet.material'),
                    value: _materialLabel(i18n, _activeMaterial),
                  ),
                  ToolboxMetricCard(
                    label: i18n.t('toolbox.sound.mallet.cavity'),
                    value: _cavityLabel(i18n, _activeCavity),
                  ),
                  ToolboxMetricCard(
                    label: i18n.t('toolbox.sound.mallet.last_note'),
                    value: _lastNoteLabel ?? '--',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SectionHeader(
                title: i18n.t('toolbox.sound.mallet.stage'),
                subtitle: compact
                    ? i18n.t('toolbox.sound.mallet.phone_stage_sub')
                    : i18n.t('toolbox.sound.mallet.wide_stage_sub'),
                trailing: FilledButton.tonalIcon(
                  onPressed: () =>
                      _openMalletSettingsSheet(context, i18n, showExit: false),
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(i18n.t('toolbox.sound.instrument.settings')),
                ),
              ),
              const SizedBox(height: 10),
              _buildMalletStage(
                context,
                i18n: i18n,
                height: compact ? 430 : 318,
                immersive: false,
              ),
              const SizedBox(height: 12),
              _buildQuickActions(i18n, immersive: false),
              const SizedBox(height: 14),
              SectionHeader(
                title: i18n.t('toolbox.sound.mallet.instrument_type'),
                subtitle: _instrumentSubtitle(i18n, _activeInstrument),
              ),
              const SizedBox(height: 10),
              _buildInstrumentChips(i18n),
              const SizedBox(height: 14),
              SectionHeader(
                title: i18n.t('toolbox.sound.mallet.material'),
                subtitle: i18n.t('toolbox.sound.mallet.material_sub'),
              ),
              const SizedBox(height: 10),
              _buildMaterialChips(i18n),
              const SizedBox(height: 14),
              SectionHeader(
                title: i18n.t('toolbox.sound.mallet.cavity'),
                subtitle: i18n.t('toolbox.sound.mallet.cavity_sub'),
              ),
              const SizedBox(height: 10),
              _buildCavityChips(i18n),
              const SizedBox(height: 14),
              Text(
                i18n.t(
                  'toolbox.sound.mallet.tail',
                  params: <String, Object?>{
                    'value': (_effectiveTail * 100).round(),
                  },
                ),
              ),
              Slider(
                value: _tail,
                min: 0.15,
                max: 1.0,
                divisions: 17,
                onChanged: (value) => setState(() => _tail = value),
                onChangeEnd: (_) {
                  _invalidatePlayers();
                  unawaited(_warmUpCoreBars());
                },
              ),
              Text(
                i18n.t(
                  'toolbox.sound.instrument.reverb',
                  params: <String, Object?>{
                    'value': (_effectiveReverb * 100).round(),
                  },
                ),
              ),
              Slider(
                value: _reverb,
                min: 0,
                max: 0.7,
                divisions: 14,
                onChanged: (value) => setState(() => _reverb = value),
                onChangeEnd: (_) {
                  _invalidatePlayers();
                  unawaited(_prepareSampledMalletEngine());
                  unawaited(_warmUpCoreBars());
                },
              ),
              const SizedBox(height: 8),
              Text(
                i18n.t('toolbox.sound.mallet.sample_note'),
                style: theme.textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}

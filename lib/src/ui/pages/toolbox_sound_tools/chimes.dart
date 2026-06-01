part of '../toolbox_sound_tools.dart';

class _ChimesTool extends StatefulWidget {
  const _ChimesTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_ChimesTool> createState() => _ChimesToolState();
}

class _ChimesPreset {
  const _ChimesPreset({
    required this.id,
    required this.styleId,
    required this.tail,
    required this.reverb,
    required this.volume,
  });

  final String id;
  final String styleId;
  final double tail;
  final double reverb;
  final double volume;
}

class _ChimesToolState extends State<_ChimesTool> {
  static const List<int> _tubeMidis = <int>[
    60,
    62,
    64,
    65,
    67,
    69,
    71,
    72,
    74,
    76,
    77,
    79,
  ];
  static const List<_ChimesPreset> _presets = <_ChimesPreset>[
    _ChimesPreset(
      id: 'ceremonial_bells',
      styleId: 'tubular',
      tail: 0.74,
      reverb: 0.34,
      volume: 0.82,
    ),
    _ChimesPreset(
      id: 'soft_hall',
      styleId: 'soft',
      tail: 0.88,
      reverb: 0.46,
      volume: 0.76,
    ),
    _ChimesPreset(
      id: 'bright_towers',
      styleId: 'bright',
      tail: 0.58,
      reverb: 0.24,
      volume: 0.86,
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
  final Map<int, int> _pointerTubes = <int, int>{};
  late final ToolboxSoundFontInstrumentEngine _sampledChimesEngine;

  String _presetId = _presets.first.id;
  String _styleId = _presets.first.styleId;
  double _tail = _presets.first.tail;
  double _reverb = _presets.first.reverb;
  double _volume = _presets.first.volume;
  bool _sampledChimesReady = false;
  bool _sweepInFlight = false;
  int? _activeTube;
  String? _lastNoteLabel;
  int _strikeCount = 0;

  @override
  void initState() {
    super.initState();
    _sampledChimesEngine = _createToolboxSoundFontInstrumentEngine(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_prepareSampledChimesEngine());
      unawaited(_warmUpCoreTubes());
    });
  }

  _ChimesPreset get _activePreset {
    return _presets.firstWhere(
      (item) => item.id == _presetId,
      orElse: () => _presets.first,
    );
  }

  bool _isCompactPhoneWidth(double width) {
    return width < (widget.fullScreen ? 480 : 430);
  }

  String _presetLabel(AppI18n i18n, _ChimesPreset preset) {
    return switch (preset.id) {
      'soft_hall' => i18n.t('toolbox.sound.chimes.soft_hall'),
      'bright_towers' => i18n.t('toolbox.sound.chimes.bright_towers'),
      _ => i18n.t('toolbox.sound.chimes.ceremonial_bells'),
    };
  }

  String _presetSubtitle(AppI18n i18n, _ChimesPreset preset) {
    return switch (preset.id) {
      'soft_hall' => i18n.t('toolbox.sound.chimes.soft_hall_sub'),
      'bright_towers' => i18n.t('toolbox.sound.chimes.bright_towers_sub'),
      _ => i18n.t('toolbox.sound.chimes.ceremonial_bells_sub'),
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

  String _playerKeyForMidi(int midi, {double velocity = 0.78}) {
    return '$midi:$_styleId:${_tail.toStringAsFixed(2)}:'
        '${_reverb.toStringAsFixed(2)}:${velocity.toStringAsFixed(2)}';
  }

  Future<void> _prepareSampledChimesEngine() async {
    final ready = await _sampledChimesEngine.ensurePatch(
      bank: ToolboxInstrumentBankCatalog.museScoreGeneral,
      patch: ToolboxInstrumentBankCatalog.tubularBells,
      volume: _volume,
      reverb: _reverb,
    );
    if (!mounted || ready == _sampledChimesReady) {
      return;
    }
    setState(() {
      _sampledChimesReady = ready;
    });
    _invalidatePlayers();
    unawaited(_warmUpCoreTubes());
  }

  ToolboxNotePlayer _playerForMidi(int midi, {double velocity = 0.78}) {
    final key = _playerKeyForMidi(midi, velocity: velocity);
    final existing = _players[key];
    if (existing != null) return existing;
    if (_sampledChimesReady) {
      final sampled = ToolboxSampledMidiNotePlayer(
        engine: _sampledChimesEngine,
        bank: ToolboxInstrumentBankCatalog.museScoreGeneral,
        patch: ToolboxInstrumentBankCatalog.tubularBells,
        midiNote: midi,
        velocity: velocity,
        releaseAfter: Duration(
          milliseconds: (1200 + _tail.clamp(0.2, 1.0) * 2900).round(),
        ),
        volume: _volume,
        reverb: _reverb,
      );
      _players[key] = sampled;
      return sampled;
    }
    final fallback = ToolboxEffectPlayer(
      ToolboxAudioBank.chimeNote(
        _frequencyFromMidi(midi),
        style: _styleId,
        tail: _tail,
        reverb: _reverb,
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

  Future<void> _warmUpCoreTubes() async {
    final warmIndexes = <int>{0, _tubeMidis.length ~/ 2, _tubeMidis.length - 1};
    for (final index in warmIndexes) {
      if (!mounted) return;
      await _playerForMidi(_tubeMidis[index]).warmUp();
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
      _styleId = preset.styleId;
      _tail = preset.tail;
      _reverb = preset.reverb;
      _volume = preset.volume;
    });
    _invalidatePlayers();
    if (_sampledChimesReady) {
      unawaited(_prepareSampledChimesEngine());
    }
    unawaited(_warmUpCoreTubes());
  }

  int? _tubeIndexForPosition(Offset position, Size size) {
    if (position.dx < 0 ||
        position.dy < 0 ||
        position.dx > size.width ||
        position.dy > size.height) {
      return null;
    }
    final laneWidth = size.width / _tubeMidis.length;
    return (position.dx / laneWidth).floor().clamp(0, _tubeMidis.length - 1);
  }

  double _velocityForGesture(Offset delta, {bool initial = false}) {
    if (initial) return 0.82;
    return (0.5 + delta.distance / 52).clamp(0.34, 1.0).toDouble();
  }

  Future<void> _strikeTube(int index, {double velocity = 0.82}) async {
    if (index < 0 || index >= _tubeMidis.length) return;
    final midi = _tubeMidis[index];
    HapticFeedback.lightImpact();
    unawaited(
      _playerForMidi(
        midi,
        velocity: velocity,
      ).play(volume: (_volume * (0.68 + velocity * 0.42)).clamp(0.0, 1.0)),
    );
    if (!mounted) return;
    setState(() {
      _activeTube = index;
      _lastNoteLabel = _noteLabelFromMidi(midi);
      _strikeCount += 1;
    });
    Future<void>.delayed(const Duration(milliseconds: 210), () {
      if (!mounted || _activeTube != index) return;
      setState(() => _activeTube = null);
    });
  }

  void _handleStagePointerDown(PointerDownEvent event, Size size) {
    final index = _tubeIndexForPosition(event.localPosition, size);
    if (index == null) return;
    _pointerTubes[event.pointer] = index;
    unawaited(_strikeTube(index, velocity: _velocityForGesture(Offset.zero)));
  }

  void _handleStagePointerMove(PointerMoveEvent event, Size size) {
    final index = _tubeIndexForPosition(event.localPosition, size);
    if (index == null) return;
    final previous = _pointerTubes[event.pointer];
    if (previous == index) return;
    _pointerTubes[event.pointer] = index;
    unawaited(_strikeTube(index, velocity: _velocityForGesture(event.delta)));
  }

  void _handleStagePointerUp(PointerEvent event) {
    _pointerTubes.remove(event.pointer);
  }

  Future<void> _playSweep({required bool ascending}) async {
    if (_sweepInFlight) return;
    _sweepInFlight = true;
    final indexes = ascending
        ? List<int>.generate(_tubeMidis.length, (index) => index)
        : List<int>.generate(
            _tubeMidis.length,
            (index) => _tubeMidis.length - 1 - index,
          );
    for (final index in indexes) {
      if (!mounted) break;
      await _strikeTube(index, velocity: 0.72);
      await Future<void>.delayed(const Duration(milliseconds: 72));
    }
    _sweepInFlight = false;
  }

  Future<void> _dampAll() async {
    for (final player in _players.values) {
      await player.stop();
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _activeTube = null;
    });
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

  Widget _buildChimesStage(
    BuildContext context, {
    required AppI18n i18n,
    required double height,
    required bool immersive,
  }) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final stageSize = Size(width, height);
        final laneWidth = width / _tubeMidis.length;
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
                        ? const Color(0xFF111827)
                        : const Color(0xFFE9F1F7),
                    immersive
                        ? const Color(0xFF1F2937)
                        : const Color(0xFFDDE7EF),
                  ],
                ),
                border: Border.all(
                  color: immersive
                      ? Colors.white.withValues(alpha: 0.14)
                      : const Color(0xFF9FB0BD),
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
                    left: compact ? 18 : 26,
                    right: compact ? 18 : 26,
                    top: 24,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: immersive
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF64748B),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  for (var index = 0; index < _tubeMidis.length; index += 1)
                    _ChimeTube(
                      left: laneWidth * index + laneWidth * 0.16,
                      width: laneWidth * 0.68,
                      height: height,
                      active: _activeTube == index,
                      label: _noteLabelFromMidi(_tubeMidis[index]),
                      index: index,
                      count: _tubeMidis.length,
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
                          i18n.t('toolbox.sound.chimes.low_side'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: immersive
                                ? Colors.white70
                                : const Color(0xFF334155),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          i18n.t('toolbox.sound.chimes.high_side'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: immersive
                                ? Colors.white70
                                : const Color(0xFF334155),
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

  Widget _buildQuickActions(AppI18n i18n, {required bool immersive}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        FilledButton.tonalIcon(
          onPressed: () => unawaited(_playSweep(ascending: true)),
          icon: const Icon(Icons.east_rounded),
          label: Text(i18n.t('toolbox.sound.chimes.sweep_up')),
        ),
        FilledButton.tonalIcon(
          onPressed: () => unawaited(_playSweep(ascending: false)),
          icon: const Icon(Icons.west_rounded),
          label: Text(i18n.t('toolbox.sound.chimes.sweep_down')),
        ),
        OutlinedButton.icon(
          onPressed: () => unawaited(_dampAll()),
          icon: const Icon(Icons.volume_off_rounded),
          label: Text(i18n.t('toolbox.sound.chimes.damp')),
          style: immersive
              ? OutlinedButton.styleFrom(foregroundColor: Colors.white)
              : null,
        ),
      ],
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
            Color(0xFF020617),
            Color(0xFF182235),
            Color(0xFF0F172A),
          ],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stageHeight = math
                .max(280.0, math.min(460.0, constraints.maxHeight - 226))
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
                              label: i18n.t('toolbox.sound.chimes.last_note'),
                              value: _lastNoteLabel ?? '--',
                            ),
                            _PianoOverlayChip(
                              label: i18n.t('toolbox.sound.chimes.strikes'),
                              value: '$_strikeCount',
                            ),
                          ],
                        ),
                        const Spacer(),
                        _buildChimesStage(
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
                        onPressed: () => unawaited(_dampAll()),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.34),
                          foregroundColor: Colors.white,
                        ),
                        child: const Icon(Icons.volume_off_rounded),
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
                          _buildQuickActions(i18n, immersive: true),
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
    unawaited(_sampledChimesEngine.dispose());
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
                    label: i18n.t('toolbox.sound.chimes.tubes'),
                    value: '${_tubeMidis.length}',
                  ),
                  ToolboxMetricCard(
                    label: i18n.t('toolbox.sound.harp.preset'),
                    value: _presetLabel(i18n, _activePreset),
                  ),
                  ToolboxMetricCard(
                    label: i18n.t('toolbox.sound.chimes.last_note'),
                    value: _lastNoteLabel ?? '--',
                  ),
                  ToolboxMetricCard(
                    label: i18n.t('toolbox.sound.chimes.strikes'),
                    value: '$_strikeCount',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SectionHeader(
                title: i18n.t('toolbox.sound.chimes.tube_stage'),
                subtitle: compact
                    ? i18n.t('toolbox.sound.chimes.phone_stage_sub')
                    : i18n.t('toolbox.sound.chimes.wide_stage_sub'),
              ),
              const SizedBox(height: 10),
              _buildChimesStage(
                context,
                i18n: i18n,
                height: compact ? 270 : 318,
                immersive: false,
              ),
              const SizedBox(height: 12),
              _buildQuickActions(i18n, immersive: false),
              const SizedBox(height: 14),
              SectionHeader(
                title: i18n.t('toolbox.sound.chimes.sound_palette'),
                subtitle: i18n.t('toolbox.sound.chimes.sound_palette_sub'),
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
                title: i18n.t('toolbox.sound.chimes.tone_and_tail'),
                subtitle: i18n.t('toolbox.sound.chimes.tone_and_tail_sub'),
              ),
              const SizedBox(height: 10),
              Text(
                i18n.t(
                  'toolbox.sound.chimes.tail',
                  params: <String, Object?>{'value': (_tail * 100).round()},
                ),
              ),
              Slider(
                value: _tail,
                min: 0.2,
                max: 1.0,
                divisions: 16,
                onChanged: (value) => setState(() => _tail = value),
                onChangeEnd: (_) {
                  _invalidatePlayers();
                  unawaited(_warmUpCoreTubes());
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
                max: 0.7,
                divisions: 14,
                onChanged: (value) => setState(() => _reverb = value),
                onChangeEnd: (_) {
                  _invalidatePlayers();
                  if (_sampledChimesReady) {
                    unawaited(_prepareSampledChimesEngine());
                  }
                  unawaited(_warmUpCoreTubes());
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChimeTube extends StatelessWidget {
  const _ChimeTube({
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
    final tubeHeight = height * (0.72 - lowToHigh * 0.26);
    final top = height * 0.13;
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: tubeHeight,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, active ? 7 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              active ? const Color(0xFFFFE6A3) : const Color(0xFFE8EEF4),
              active ? const Color(0xFFD0A13A) : const Color(0xFF94A3B8),
              immersive ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ],
          ),
          border: Border.all(
            color: active
                ? const Color(0xFFFFD166)
                : Colors.white.withValues(alpha: immersive ? 0.12 : 0.7),
          ),
          boxShadow: active
              ? <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFFFFD166).withValues(alpha: 0.46),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ]
              : <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
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
                      ? const Color(0xFF392B08)
                      : (immersive ? Colors.white : const Color(0xFF253242)),
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

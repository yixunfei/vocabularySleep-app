part of '../toolbox_sound_tools.dart';

class _ShakuhachiTool extends StatefulWidget {
  const _ShakuhachiTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_ShakuhachiTool> createState() => _ShakuhachiToolState();
}

class _ShakuhachiToolState extends State<_ShakuhachiTool> {
  static const List<_PianoKey> _notes = <_PianoKey>[
    _PianoKey(id: 'D4', label: 'D', frequency: 293.66),
    _PianoKey(id: 'F4', label: 'F', frequency: 349.23),
    _PianoKey(id: 'G4', label: 'G', frequency: 392.0),
    _PianoKey(id: 'A4', label: 'A', frequency: 440.0),
    _PianoKey(id: 'C5', label: 'C', frequency: 523.25),
    _PianoKey(id: 'D5', label: 'D5', frequency: 587.33),
  ];

  late final ToolboxSoundFontInstrumentEngine _sampledEngine;
  late final ToolboxSampledMidiSustainController _sampledSustain;
  final Map<String, ToolboxNotePlayer> _players = <String, ToolboxNotePlayer>{};
  int _noteIndex = 0;
  int? _airPointer;
  double _airLevel = 0;
  double _reverb = 0.24;
  double _tail = 0.76;
  bool _sampledReady = false;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _sampledEngine = _createToolboxSoundFontInstrumentEngine(context);
    _sampledSustain = ToolboxSampledMidiSustainController(
      engine: _sampledEngine,
      bank: ToolboxInstrumentBankCatalog.museScoreGeneral,
      patch: ToolboxInstrumentBankCatalog.shakuhachi,
      volume: 0.82,
      reverb: _reverb,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_prepareSampledEngine());
      unawaited(_sampledSustain.warmUp());
    });
  }

  _PianoKey get _activeNote => _notes[_noteIndex.clamp(0, _notes.length - 1)];

  double get _effectiveAir => _playing ? _airLevel.clamp(0.0, 1.0) : 0.0;

  double get _sampledVelocity {
    return (0.34 + _effectiveAir * 0.62).clamp(0.1, 1.0).toDouble();
  }

  double get _sampledVolume {
    return (0.34 + _effectiveAir * 0.5).clamp(0.2, 0.92).toDouble();
  }

  Future<void> _prepareSampledEngine() async {
    final ready = await _sampledEngine.ensurePatch(
      bank: ToolboxInstrumentBankCatalog.museScoreGeneral,
      patch: ToolboxInstrumentBankCatalog.shakuhachi,
      volume: _sampledVolume,
      reverb: _reverb,
    );
    if (!mounted) return;
    if (_sampledReady != ready) {
      setState(() => _sampledReady = ready);
    }
  }

  void _invalidatePlayers() {
    for (final player in _players.values) {
      unawaited(player.dispose());
    }
    _players.clear();
  }

  ToolboxNotePlayer _fallbackPlayerFor(_PianoKey note) {
    final airKey = (_effectiveAir * 20).round();
    final key = 'shakuhachi:${note.id}:$airKey:${_reverb.toStringAsFixed(2)}';
    final existing = _players[key];
    if (existing != null) return existing;
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.fluteNote(
        note.frequency,
        style: 'bamboo',
        material: 'wood',
        breath: (0.3 + _effectiveAir * 0.7).clamp(0.18, 1.0).toDouble(),
        reverb: _reverb,
        tail: _tail,
      ),
      maxPlayers: 5,
    );
    _players[key] = created;
    return created;
  }

  double _airLevelForDy(double dy, double height) {
    if (height <= 0) return 0.72;
    final relative = (1 - dy / height).clamp(0.0, 1.0).toDouble();
    return (0.22 + relative * 0.78).clamp(0.22, 1.0).toDouble();
  }

  Future<void> _syncSustain() async {
    if (!_playing) {
      await _sampledSustain.stop();
      return;
    }
    if (_sampledReady) {
      await _sampledSustain.start(
        midiNote: ToolboxInstrumentPitch.midiFromFrequency(
          _activeNote.frequency,
        ),
        velocity: _sampledVelocity,
        volume: _sampledVolume,
        reverb: _reverb,
      );
      return;
    }
    await _fallbackPlayerFor(_activeNote).play(volume: _sampledVolume);
  }

  void _startAir(PointerDownEvent event, double height) {
    if (_airPointer != null) return;
    _airPointer = event.pointer;
    setState(() {
      _playing = true;
      _airLevel = _airLevelForDy(event.localPosition.dy, height);
    });
    HapticFeedback.lightImpact();
    unawaited(_syncSustain());
  }

  void _updateAir(PointerMoveEvent event, double height) {
    if (_airPointer != event.pointer) return;
    final next = _airLevelForDy(event.localPosition.dy, height);
    if ((next - _airLevel).abs() < 0.015) return;
    setState(() => _airLevel = next);
    unawaited(_syncSustain());
  }

  void _stopAir(PointerEvent event) {
    if (_airPointer != event.pointer) return;
    _airPointer = null;
    setState(() {
      _playing = false;
      _airLevel = 0;
    });
    unawaited(_syncSustain());
  }

  void _setNoteIndex(int index) {
    if (_noteIndex == index) return;
    setState(() => _noteIndex = index);
    if (_playing) {
      unawaited(_syncSustain());
    }
  }

  void _openFullScreen(BuildContext context) {
    if (widget.fullScreen) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _ShakuhachiFullScreenPage(),
      ),
    );
  }

  @override
  void dispose() {
    _invalidatePlayers();
    unawaited(_sampledSustain.dispose());
    unawaited(_sampledEngine.dispose());
    super.dispose();
  }

  Widget _buildInlineLauncher(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    return _buildInstrumentPanelShell(
      context,
      fullScreen: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.air_rounded, color: Color(0xFF0F766E)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  i18n.t('toolbox.sound.shakuhachi.inline_title'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            i18n.t('toolbox.sound.shakuhachi.inline_sub'),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openFullScreen(context),
              icon: const Icon(Icons.open_in_full_rounded),
              label: Text(i18n.t('toolbox.sound.flute.full_screen')),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirPanel(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = math.max(220.0, constraints.maxHeight);
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) => _startAir(event, height),
          onPointerMove: (event) => _updateAir(event, height),
          onPointerUp: _stopAir,
          onPointerCancel: _stopAir,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: <Color>[
                  const Color(0xFF0F172A),
                  Color.lerp(
                    const Color(0xFF0F766E),
                    const Color(0xFFCCFBF1),
                    _effectiveAir * 0.42,
                  )!,
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(
                    0xFF14B8A6,
                  ).withValues(alpha: _playing ? 0.34 : 0.12),
                  blurRadius: _playing ? 26 : 14,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 22,
                  height: math.max(10, (height - 44) * _effectiveAir),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        _playing ? Icons.air_rounded : Icons.touch_app_rounded,
                        size: 42,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _playing
                            ? i18n.t('toolbox.sound.shakuhachi.blowing')
                            : i18n.t('toolbox.sound.shakuhachi.hold_to_blow'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        i18n.t(
                          'toolbox.sound.shakuhachi.air_value',
                          params: <String, Object?>{
                            'value': (_effectiveAir * 100).round(),
                          },
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoteRail(AppI18n i18n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (var index = 0; index < _notes.length; index += 1)
          ChoiceChip(
            label: Text(_notes[index].label),
            selected: _noteIndex == index,
            onSelected: (_) => _setNoteIndex(index),
          ),
      ],
    );
  }

  Widget _buildFullScreen(BuildContext context, AppI18n i18n) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF020617),
            Color(0xFF083B3A),
            Color(0xFF111827),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            14 + viewPadding.left,
            12,
            14 + viewPadding.right,
            14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          i18n.t('toolbox.sound.shakuhachi.title'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          i18n.t('toolbox.sound.shakuhachi.full_sub'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_fullscreen_rounded),
                    tooltip: i18n.t(
                      'toolbox.sound.instrument.exit_full_screen',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildNoteRail(i18n),
              const SizedBox(height: 12),
              Expanded(child: _buildAirPanel(context, i18n)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    if (!widget.fullScreen) {
      return _buildInlineLauncher(context, i18n);
    }
    return _buildFullScreen(context, i18n);
  }
}

class _ShakuhachiFullScreenPage extends StatefulWidget {
  const _ShakuhachiFullScreenPage();

  @override
  State<_ShakuhachiFullScreenPage> createState() =>
      _ShakuhachiFullScreenPageState();
}

class _ShakuhachiFullScreenPageState extends State<_ShakuhachiFullScreenPage> {
  @override
  void initState() {
    super.initState();
    unawaited(_enterToolboxPortraitMode());
  }

  @override
  void dispose() {
    unawaited(_exitToolboxLandscapeMode());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: _ShakuhachiTool(fullScreen: true),
    );
  }
}

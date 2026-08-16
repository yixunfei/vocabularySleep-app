part of '../toolbox_sound_tools.dart';

class _ShakuhachiTool extends StatefulWidget {
  const _ShakuhachiTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_ShakuhachiTool> createState() => _ShakuhachiToolState();
}

class _ShakuhachiToolState extends State<_ShakuhachiTool> {
  static const _PianoKey _pipeNote = _PianoKey(
    id: 'D4',
    label: 'D',
    frequency: 293.66,
  );
  static const List<_ShakuhachiHole> _holes = <_ShakuhachiHole>[
    _ShakuhachiHole(
      label: 'F',
      tone: _PianoKey(id: 'F4', label: 'F', frequency: 349.23),
    ),
    _ShakuhachiHole(
      label: 'G',
      tone: _PianoKey(id: 'G4', label: 'G', frequency: 392.0),
    ),
    _ShakuhachiHole(
      label: 'A',
      tone: _PianoKey(id: 'A4', label: 'A', frequency: 440.0),
    ),
    _ShakuhachiHole(
      label: 'C',
      tone: _PianoKey(id: 'C5', label: 'C', frequency: 523.25),
    ),
    _ShakuhachiHole(
      label: 'D',
      tone: _PianoKey(id: 'D5', label: 'D', frequency: 587.33),
      backHole: true,
    ),
  ];

  late final ToolboxSoundFontInstrumentEngine _sampledEngine;
  late final ToolboxSampledMidiSustainController _sampledSustain;
  final Map<String, ToolboxNotePlayer> _players = <String, ToolboxNotePlayer>{};
  final Map<int, int> _holePointers = <int, int>{};
  final Set<int> _coveredHoles = <int>{};
  final Set<int> _latchedHoles = <int>{};
  int? _airPointer;
  String? _fallbackPlayingNoteId;
  double _airLevel = 0;
  final double _reverb = 0.24;
  final double _tail = 0.76;
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

  _PianoKey get _activeNote {
    for (var index = _holes.length - 1; index >= 0; index -= 1) {
      if (!_holeIsCovered(index)) {
        return _holes[index].tone;
      }
    }
    return _pipeNote;
  }

  double get _effectiveAir => _playing ? _airLevel.clamp(0.0, 1.0) : 0.0;

  bool _holeIsCovered(int index) {
    return _coveredHoles.contains(index) || _latchedHoles.contains(index);
  }

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
      _fallbackPlayingNoteId = null;
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
    if (_fallbackPlayingNoteId == _activeNote.id) return;
    _fallbackPlayingNoteId = _activeNote.id;
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
    _fallbackPlayingNoteId = null;
    setState(() {
      _playing = false;
      _airLevel = 0;
    });
    unawaited(_syncSustain());
  }

  void _coverHole(int index, PointerDownEvent event) {
    if (_holePointers.containsKey(event.pointer)) return;
    _holePointers[event.pointer] = index;
    setState(() => _coveredHoles.add(index));
    if (_playing) {
      unawaited(_syncSustain());
    }
  }

  void _releaseHole(PointerEvent event) {
    final index = _holePointers.remove(event.pointer);
    if (index == null) return;
    setState(() => _coveredHoles.remove(index));
    if (_playing) {
      unawaited(_syncSustain());
    }
  }

  void _toggleHoleLatch(int index) {
    setState(() {
      if (!_latchedHoles.remove(index)) {
        _latchedHoles.add(index);
      }
    });
    HapticFeedback.selectionClick();
    if (_playing) {
      unawaited(_syncSustain());
    }
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
        ],
      ),
    );
  }

  void _showInfoSheet(BuildContext context, AppI18n i18n) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
              children: <Widget>[
                Text(
                  i18n.t('toolbox.sound.shakuhachi.info_title'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  i18n.t('toolbox.sound.shakuhachi.info_intro'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                _ShakuhachiInfoTile(
                  title: i18n.t('toolbox.sound.shakuhachi.info_history_title'),
                  body: i18n.t('toolbox.sound.shakuhachi.info_history_body'),
                ),
                _ShakuhachiInfoTile(
                  title: i18n.t('toolbox.sound.shakuhachi.info_form_title'),
                  body: i18n.t('toolbox.sound.shakuhachi.info_form_body'),
                ),
                _ShakuhachiInfoTile(
                  title: i18n.t('toolbox.sound.shakuhachi.info_sound_title'),
                  body: i18n.t('toolbox.sound.shakuhachi.info_sound_body'),
                ),
                _ShakuhachiInfoTile(
                  title: i18n.t('toolbox.sound.shakuhachi.info_play_title'),
                  body: i18n.t('toolbox.sound.shakuhachi.info_play_body'),
                ),
                _ShakuhachiInfoTile(
                  title: i18n.t('toolbox.sound.shakuhachi.info_guide_title'),
                  body: i18n.t('toolbox.sound.shakuhachi.info_guide_body'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAirPanel(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 220.0;
        final visualHeight = math.max(120.0, height);
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) => _startAir(event, visualHeight),
          onPointerMove: (event) => _updateAir(event, visualHeight),
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
                  height: math.max(10, (visualHeight - 44) * _effectiveAir),
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

  Widget _buildHolePanel(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 340.0;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 420.0;
        final compact = height < 380 || width < 250;
        final topInset = compact ? 46.0 : 54.0;
        final bottomInset = compact ? 16.0 : 24.0;
        final playableHeight = math.max(150.0, height - topInset - bottomInset);
        final holeSize = math
            .min(width * 0.26, compact ? 58.0 : 68.0)
            .clamp(50.0, 68.0)
            .toDouble();
        final stationWidth = math
            .min(width * 0.44, math.max(88.0, holeSize + 42.0))
            .clamp(80.0, 118.0)
            .toDouble();
        final stationHeight = holeSize + 58.0;
        final pipeWidth = math
            .min(width * 0.28, 92.0)
            .clamp(48.0, 92.0)
            .toDouble();
        return Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: <Color>[Color(0xFF6B3F1D), Color(0xFFB98543)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: topInset + 8,
                bottom: bottomInset + 8,
                left: width / 2 - pipeWidth / 2,
                width: pipeWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: <Color>[
                        Color(0xFF3F2411),
                        Color(0xFFD5A45B),
                        Color(0xFF6F421F),
                      ],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    i18n.t(
                      'toolbox.sound.shakuhachi.current_note',
                      params: <String, Object?>{'note': _activeNote.label},
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              for (var index = 0; index < _holes.length; index += 1)
                _buildVerticalHoleStation(
                  index: index,
                  i18n: i18n,
                  width: width,
                  topInset: topInset,
                  playableHeight: playableHeight,
                  stationWidth: stationWidth,
                  stationHeight: stationHeight,
                  holeSize: holeSize,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVerticalHoleStation({
    required int index,
    required AppI18n i18n,
    required double width,
    required double topInset,
    required double playableHeight,
    required double stationWidth,
    required double stationHeight,
    required double holeSize,
  }) {
    const centers = <Offset>[
      Offset(0.32, 0.80),
      Offset(0.68, 0.66),
      Offset(0.32, 0.52),
      Offset(0.68, 0.38),
      Offset(0.32, 0.24),
    ];
    final center = centers[index];
    final left = (width * center.dx - stationWidth / 2)
        .clamp(8.0, math.max(8.0, width - stationWidth - 8.0))
        .toDouble();
    final top = (topInset + playableHeight * center.dy - stationHeight / 2)
        .clamp(8.0, topInset + playableHeight - stationHeight + 4.0)
        .toDouble();
    return Positioned(
      left: left,
      top: top,
      width: stationWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildHoleLockToggle(index, i18n),
          const SizedBox(height: 6),
          _buildHolePad(index, holeSize),
        ],
      ),
    );
  }

  Widget _buildHoleLockToggle(int index, AppI18n i18n) {
    final locked = _latchedHoles.contains(index);
    final tooltip = i18n.t(
      'toolbox.sound.shakuhachi.hole_lock_toggle',
      params: <String, Object?>{'note': _holes[index].label},
    );
    return Semantics(
      label: tooltip,
      selected: locked,
      child: IconButton.filledTonal(
        onPressed: () => _toggleHoleLatch(index),
        tooltip: tooltip,
        style: IconButton.styleFrom(
          fixedSize: const Size.square(48),
          minimumSize: const Size.square(48),
          backgroundColor: locked
              ? const Color(0xFFCCFBF1)
              : Colors.black.withValues(alpha: 0.28),
          foregroundColor: locked ? const Color(0xFF0F172A) : Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
        ),
        icon: Icon(
          locked ? Icons.push_pin_rounded : Icons.push_pin_outlined,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildHolePad(int index, double holeSize) {
    return _ShakuhachiHolePad(
      hole: _holes[index],
      covered: _holeIsCovered(index),
      size: holeSize,
      onPointerDown: (event) => _coverHole(index, event),
      onPointerUp: _releaseHole,
      onPointerCancel: _releaseHole,
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactLandscape = constraints.maxHeight < 430;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                10 + viewPadding.left,
                compactLandscape ? 8 : 12,
                10 + viewPadding.right,
                compactLandscape ? 10 : 14,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  (compactLandscape
                                          ? theme.textTheme.titleMedium
                                          : theme.textTheme.titleLarge)
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                            ),
                            if (!compactLandscape)
                              Text(
                                i18n.t('toolbox.sound.shakuhachi.full_sub'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => _showInfoSheet(context, i18n),
                        icon: const Icon(Icons.help_outline_rounded),
                        tooltip: i18n.t('toolbox.sound.shakuhachi.info_title'),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_fullscreen_rounded),
                        tooltip: i18n.t(
                          'toolbox.sound.instrument.exit_full_screen',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compactLandscape ? 8 : 12),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(
                          flex: 7,
                          child: _buildHolePanel(context, i18n),
                        ),
                        const SizedBox(width: 10),
                        Expanded(flex: 4, child: _buildAirPanel(context, i18n)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
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

class _ShakuhachiInfoTile extends StatelessWidget {
  const _ShakuhachiInfoTile({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _ShakuhachiHole {
  const _ShakuhachiHole({
    required this.label,
    required this.tone,
    this.backHole = false,
  });

  final String label;
  final _PianoKey tone;
  final bool backHole;
}

class _ShakuhachiHolePad extends StatelessWidget {
  const _ShakuhachiHolePad({
    required this.hole,
    required this.covered,
    required this.size,
    required this.onPointerDown,
    required this.onPointerUp,
    required this.onPointerCancel,
  });

  final _ShakuhachiHole hole;
  final bool covered;
  final double size;
  final void Function(PointerDownEvent event) onPointerDown;
  final void Function(PointerEvent event) onPointerUp;
  final void Function(PointerEvent event) onPointerCancel;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: onPointerDown,
      onPointerUp: onPointerUp,
      onPointerCancel: onPointerCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: covered ? const Color(0xFF111827) : const Color(0xFFF8E7B7),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.72),
            width: 2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: covered ? 0.36 : 0.22),
              blurRadius: covered ? 8 : 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          hole.label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: covered ? Colors.white : const Color(0xFF3F2411),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

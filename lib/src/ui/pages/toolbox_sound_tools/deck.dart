part of '../toolbox_sound_tools.dart';

class SoothingMusicToolPage extends StatelessWidget {
  const SoothingMusicToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return ToolboxToolPage(
      title: i18n.t('toolbox.sound.deck.soothing_title'),
      subtitle: i18n.t('toolbox.sound.deck.soothing_sub'),
      child: const _SoothingMusicTool(),
    );
  }
}

class HarpToolPage extends StatelessWidget {
  const HarpToolPage({super.key, this.fullScreen = false});

  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    if (fullScreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _HarpTool(
          fullScreen: true,
          onExitFullScreen: () => Navigator.of(context).pop(),
        ),
      );
    }
    return ToolboxToolPage(
      title: i18n.t('toolbox.sound.deck.harp_title'),
      subtitle: i18n.t('toolbox.sound.deck.harp_sub'),
      child: const _HarpInstrumentDeck(),
    );
  }
}

enum _HarpDeckInstrument {
  harp,
  piano,
  flute,
  drumPad,
  guitar,
  triangle,
  kalimba,
  chimes,
  pickup,
}

class _HarpInstrumentDeck extends StatefulWidget {
  const _HarpInstrumentDeck();

  @override
  State<_HarpInstrumentDeck> createState() => _HarpInstrumentDeckState();
}

class _HarpInstrumentDeckState extends State<_HarpInstrumentDeck> {
  _HarpDeckInstrument _selected = _HarpDeckInstrument.harp;
  _HarpConfig _harpConfig = const _HarpConfig();
  bool _switchSectionExpanded = true;
  bool _infoSectionExpanded = false;

  void _onHarpConfigChanged(_HarpConfig config) {
    _harpConfig = config;
  }

  String _label(AppI18n i18n, _HarpDeckInstrument instrument) {
    return switch (instrument) {
      _HarpDeckInstrument.piano => i18n.t('toolbox.sound.deck.piano'),
      _HarpDeckInstrument.flute => i18n.t('toolbox.sound.deck.flute'),
      _HarpDeckInstrument.drumPad => i18n.t('toolbox.sound.deck.drum_pad'),
      _HarpDeckInstrument.guitar => i18n.t('toolbox.sound.deck.guitar'),
      _HarpDeckInstrument.triangle => i18n.t('toolbox.sound.deck.triangle'),
      _HarpDeckInstrument.kalimba => i18n.t('toolbox.sound.deck.kalimba'),
      _HarpDeckInstrument.chimes => i18n.t('toolbox.sound.deck.chimes'),
      _HarpDeckInstrument.pickup => i18n.t('toolbox.sound.deck.pickup'),
      _ => i18n.t('toolbox.sound.deck.harp'),
    };
  }

  String _subtitle(AppI18n i18n, _HarpDeckInstrument instrument) {
    return switch (instrument) {
      _HarpDeckInstrument.piano => i18n.t('toolbox.sound.deck.piano_sub'),
      _HarpDeckInstrument.flute => i18n.t('toolbox.sound.deck.flute_sub'),
      _HarpDeckInstrument.drumPad => i18n.t('toolbox.sound.deck.drum_pad_sub'),
      _HarpDeckInstrument.guitar => i18n.t('toolbox.sound.deck.guitar_sub'),
      _HarpDeckInstrument.triangle => i18n.t('toolbox.sound.deck.triangle_sub'),
      _HarpDeckInstrument.kalimba => i18n.t('toolbox.sound.deck.kalimba_sub'),
      _HarpDeckInstrument.chimes => i18n.t('toolbox.sound.deck.chimes_sub'),
      _HarpDeckInstrument.pickup => i18n.t('toolbox.sound.deck.pickup_sub'),
      _ => i18n.t('toolbox.sound.deck.harp_sub'),
    };
  }

  String _gestureHint(AppI18n i18n, _HarpDeckInstrument instrument) {
    return switch (instrument) {
      _HarpDeckInstrument.piano => i18n.t('toolbox.sound.deck.piano_gesture'),
      _HarpDeckInstrument.flute => i18n.t('toolbox.sound.deck.flute_gesture'),
      _HarpDeckInstrument.drumPad => i18n.t(
        'toolbox.sound.deck.drum_pad_gesture',
      ),
      _HarpDeckInstrument.guitar => i18n.t('toolbox.sound.deck.guitar_gesture'),
      _HarpDeckInstrument.triangle => i18n.t(
        'toolbox.sound.deck.triangle_gesture',
      ),
      _HarpDeckInstrument.kalimba => i18n.t(
        'toolbox.sound.deck.kalimba_gesture',
      ),
      _HarpDeckInstrument.chimes => i18n.t('toolbox.sound.deck.chimes_gesture'),
      _HarpDeckInstrument.pickup => i18n.t('toolbox.sound.deck.pickup_gesture'),
      _ => i18n.t('toolbox.sound.deck.harp_gesture'),
    };
  }

  String _mixHint(AppI18n i18n, _HarpDeckInstrument instrument) {
    return switch (instrument) {
      _HarpDeckInstrument.piano => i18n.t('toolbox.sound.deck.piano_mix'),
      _HarpDeckInstrument.flute => i18n.t('toolbox.sound.deck.flute_mix'),
      _HarpDeckInstrument.drumPad => i18n.t('toolbox.sound.deck.drum_pad_mix'),
      _HarpDeckInstrument.guitar => i18n.t('toolbox.sound.deck.guitar_mix'),
      _HarpDeckInstrument.triangle => i18n.t('toolbox.sound.deck.triangle_mix'),
      _HarpDeckInstrument.kalimba => i18n.t('toolbox.sound.deck.kalimba_mix'),
      _HarpDeckInstrument.chimes => i18n.t('toolbox.sound.deck.chimes_mix'),
      _HarpDeckInstrument.pickup => i18n.t('toolbox.sound.deck.pickup_mix'),
      _ => i18n.t('toolbox.sound.deck.harp_mix'),
    };
  }

  String _layoutHint(AppI18n i18n, _HarpDeckInstrument instrument) {
    return switch (instrument) {
      _HarpDeckInstrument.piano => i18n.t('toolbox.sound.deck.piano_layout'),
      _HarpDeckInstrument.pickup => i18n.t('toolbox.sound.deck.piano_layout'),
      _ => i18n.t('toolbox.sound.deck.landscape_recommended'),
    };
  }

  IconData _icon(_HarpDeckInstrument instrument) {
    return switch (instrument) {
      _HarpDeckInstrument.piano => Icons.piano_rounded,
      _HarpDeckInstrument.flute => Icons.air_rounded,
      _HarpDeckInstrument.drumPad => Icons.album_rounded,
      _HarpDeckInstrument.guitar => Icons.queue_music_rounded,
      _HarpDeckInstrument.triangle => Icons.change_history_rounded,
      _HarpDeckInstrument.kalimba => Icons.view_week_rounded,
      _HarpDeckInstrument.chimes => Icons.notifications_none_rounded,
      _HarpDeckInstrument.pickup => Icons.graphic_eq_rounded,
      _ => Icons.music_note_rounded,
    };
  }

  Widget _activeTool() {
    return switch (_selected) {
      _HarpDeckInstrument.piano => const _PianoTool(),
      _HarpDeckInstrument.flute => const _FluteTool(),
      _HarpDeckInstrument.drumPad => const _DrumPadTool(),
      _HarpDeckInstrument.guitar => const _GuitarTool(),
      _HarpDeckInstrument.triangle => const _TriangleTool(),
      _HarpDeckInstrument.kalimba => const _KalimbaTool(),
      _HarpDeckInstrument.chimes => const _ChimesTool(),
      _HarpDeckInstrument.pickup => const _PickupTool(),
      _ => _HarpTool(
        initialConfig: _harpConfig,
        onConfigChanged: _onHarpConfigChanged,
      ),
    };
  }

  void _openInstrumentFullScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DeckInstrumentFullScreenPage(
          instrument: _selected,
          harpConfig: _harpConfig,
          onHarpConfigChanged: _onHarpConfigChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Card(
          child: ExpansionTile(
            initiallyExpanded: _switchSectionExpanded,
            onExpansionChanged: (value) {
              setState(() {
                _switchSectionExpanded = value;
              });
            },
            title: Text(i18n.t('toolbox.sound.deck.instrument_switch')),
            subtitle: Text(i18n.t('toolbox.sound.deck.instrument_switch_sub')),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 6,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final item in _HarpDeckInstrument.values)
                          ChoiceChip(
                            avatar: Icon(_icon(item), size: 16),
                            label: Text(_label(i18n, item)),
                            selected: item == _selected,
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            onSelected: (_) => setState(() => _selected = item),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                      onPressed: _openInstrumentFullScreen,
                      icon: const Icon(Icons.open_in_full_rounded),
                      label: Text(i18n.t('toolbox.sound.deck.full_screen')),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _infoSectionExpanded = true;
                        });
                      },
                      icon: const Icon(Icons.tips_and_updates_rounded),
                      label: Text(i18n.t('toolbox.sound.deck.quick_tips')),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      i18n.t(
                        'toolbox.sound.deck.current_instrument',
                        params: <String, Object?>{
                          'instrument': _label(i18n, _selected),
                        },
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Card(
          child: ExpansionTile(
            initiallyExpanded: _infoSectionExpanded,
            onExpansionChanged: (value) {
              setState(() {
                _infoSectionExpanded = value;
              });
            },
            title: Text(i18n.t('toolbox.sound.deck.instrument_info')),
            subtitle: Text(_label(i18n, _selected)),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(_icon(_selected), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _subtitle(i18n, _selected),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _DeckHintChip(
                          icon: Icons.touch_app_rounded,
                          text: _gestureHint(i18n, _selected),
                        ),
                        _DeckHintChip(
                          icon: Icons.tune_rounded,
                          text: _mixHint(i18n, _selected),
                        ),
                        _DeckHintChip(
                          icon: Icons.screen_rotation_alt_rounded,
                          text: _layoutHint(i18n, _selected),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey<_HarpDeckInstrument>(_selected),
            child: _activeTool(),
          ),
        ),
      ],
    );
  }
}

class _DeckHintChip extends StatelessWidget {
  const _DeckHintChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _DeckInstrumentFullScreenPage extends StatefulWidget {
  const _DeckInstrumentFullScreenPage({
    required this.instrument,
    this.harpConfig,
    this.onHarpConfigChanged,
  });

  final _HarpDeckInstrument instrument;
  final _HarpConfig? harpConfig;
  final void Function(_HarpConfig config)? onHarpConfigChanged;

  @override
  State<_DeckInstrumentFullScreenPage> createState() =>
      _DeckInstrumentFullScreenPageState();
}

class _DeckInstrumentFullScreenPageState
    extends State<_DeckInstrumentFullScreenPage> {
  bool _prefersPortraitFullScreen(_HarpDeckInstrument instrument) {
    return switch (instrument) {
      _HarpDeckInstrument.piano => true,
      _ => false,
    };
  }

  @override
  void initState() {
    super.initState();
    unawaited(
      _prefersPortraitFullScreen(widget.instrument)
          ? _enterToolboxPortraitMode()
          : _enterToolboxLandscapeMode(),
    );
  }

  @override
  void dispose() {
    unawaited(_exitToolboxLandscapeMode());
    super.dispose();
  }

  Widget _tool() {
    return switch (widget.instrument) {
      _HarpDeckInstrument.piano => const _PianoTool(fullScreen: true),
      _HarpDeckInstrument.flute => const _FluteTool(fullScreen: true),
      _HarpDeckInstrument.drumPad => const _DrumPadTool(fullScreen: true),
      _HarpDeckInstrument.guitar => const _GuitarTool(fullScreen: true),
      _HarpDeckInstrument.triangle => const _TriangleTool(fullScreen: true),
      _HarpDeckInstrument.kalimba => const _KalimbaTool(fullScreen: true),
      _HarpDeckInstrument.chimes => const _ChimesTool(fullScreen: true),
      _HarpDeckInstrument.pickup => const _PickupTool(fullScreen: true),
      _ => _HarpTool(
        fullScreen: true,
        initialConfig: widget.harpConfig,
        onConfigChanged: widget.onHarpConfigChanged,
        onExitFullScreen: () => Navigator.of(context).pop(),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, body: _tool());
  }
}

class FocusBeatsToolPage extends StatelessWidget {
  const FocusBeatsToolPage({super.key});

  void _openFullScreen(
    BuildContext context, {
    required bool autoStart,
    required bool immersive,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FocusBeatsFullScreenPage(
          autoStart: autoStart,
          immersiveOnEnter: immersive,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return ToolboxToolPage(
      title: i18n.t('toolbox.sound.deck.focus_beats_title'),
      subtitle: i18n.t('toolbox.sound.deck.focus_beats_sub'),
      appBarActions: <Widget>[
        IconButton(
          tooltip: i18n.t('toolbox.sound.deck.focus_fullscreen_quick_start'),
          icon: const Icon(Icons.open_in_full_rounded),
          onPressed: () =>
              _openFullScreen(context, autoStart: true, immersive: true),
        ),
      ],
      child: _FocusBeatsTool(
        onOpenFullScreen: ({required autoStart, required immersive}) =>
            _openFullScreen(
              context,
              autoStart: autoStart,
              immersive: immersive,
            ),
      ),
    );
  }
}

class _FocusBeatsFullScreenPage extends StatefulWidget {
  const _FocusBeatsFullScreenPage({
    required this.autoStart,
    required this.immersiveOnEnter,
  });

  final bool autoStart;
  final bool immersiveOnEnter;

  @override
  State<_FocusBeatsFullScreenPage> createState() =>
      _FocusBeatsFullScreenPageState();
}

class _FocusBeatsFullScreenPageState extends State<_FocusBeatsFullScreenPage>
    with WidgetsBindingObserver {
  Future<void> _ensureImmersive() async {
    await _enterToolboxPortraitMode();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_ensureImmersive());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_ensureImmersive());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_exitToolboxLandscapeMode());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _FocusBeatsTool(
        fullScreen: true,
        autoStart: widget.autoStart,
        initialImmersive: widget.immersiveOnEnter,
        onExitFullScreen: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class WoodfishToolPage extends StatefulWidget {
  const WoodfishToolPage({super.key});

  @override
  State<WoodfishToolPage> createState() => _WoodfishToolPageState();
}

class _WoodfishToolPageState extends State<WoodfishToolPage> {
  bool _suspendInlinePlayback = false;
  bool _openingFullScreen = false;

  Future<void> _openFullScreen({
    required BuildContext context,
    required bool autoStart,
  }) async {
    if (_openingFullScreen) {
      return;
    }
    setState(() {
      _openingFullScreen = true;
      _suspendInlinePlayback = true;
    });
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _WoodfishFullScreenPage(autoStart: autoStart),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _openingFullScreen = false;
          _suspendInlinePlayback = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return ToolboxToolPage(
      title: i18n.t('toolbox.sound.deck.woodfish_title'),
      subtitle: i18n.t('toolbox.sound.deck.woodfish_sub'),
      appBarActions: <Widget>[
        IconButton(
          tooltip: i18n.t('toolbox.sound.deck.woodfish_full_screen'),
          icon: const Icon(Icons.open_in_full_rounded),
          onPressed: () =>
              unawaited(_openFullScreen(context: context, autoStart: true)),
        ),
      ],
      child: _WoodfishTool(
        suspendPlayback: _suspendInlinePlayback,
        onOpenFullScreen: ({required autoStart}) =>
            unawaited(_openFullScreen(context: context, autoStart: autoStart)),
      ),
    );
  }
}

class _WoodfishFullScreenPage extends StatefulWidget {
  const _WoodfishFullScreenPage({required this.autoStart});

  final bool autoStart;

  @override
  State<_WoodfishFullScreenPage> createState() =>
      _WoodfishFullScreenPageState();
}

class _WoodfishFullScreenPageState extends State<_WoodfishFullScreenPage>
    with WidgetsBindingObserver {
  Future<void> _ensureImmersive() async {
    await _enterToolboxPortraitMode();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_ensureImmersive());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_ensureImmersive());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_exitToolboxLandscapeMode());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _WoodfishTool(
        fullScreen: true,
        autoStart: widget.autoStart,
        onExitFullScreen: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class PianoToolPage extends StatelessWidget {
  const PianoToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return ToolboxToolPage(
      title: i18n.t('toolbox.sound.deck.piano'),
      subtitle: i18n.t('toolbox.sound.deck.piano_title_sub'),
      child: const _PianoTool(),
    );
  }
}

class FluteToolPage extends StatelessWidget {
  const FluteToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return ToolboxToolPage(
      title: i18n.t('toolbox.sound.deck.flute'),
      subtitle: i18n.t('toolbox.sound.deck.flute_title_sub'),
      child: const _FluteTool(),
    );
  }
}

class DrumPadToolPage extends StatelessWidget {
  const DrumPadToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return ToolboxToolPage(
      title: i18n.t('toolbox.sound.deck.drum_pad'),
      subtitle: i18n.t('toolbox.sound.deck.drum_pad_title_sub'),
      child: const _DrumPadTool(),
    );
  }
}

class GuitarToolPage extends StatelessWidget {
  const GuitarToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return ToolboxToolPage(
      title: i18n.t('toolbox.sound.deck.guitar'),
      subtitle: i18n.t('toolbox.sound.deck.guitar_title_sub'),
      child: const _GuitarTool(),
    );
  }
}

class TriangleToolPage extends StatelessWidget {
  const TriangleToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return ToolboxToolPage(
      title: i18n.t('toolbox.sound.deck.triangle_title'),
      subtitle: i18n.t('toolbox.sound.deck.triangle_title_sub'),
      child: const _TriangleTool(),
    );
  }
}

class PickupToolPage extends StatelessWidget {
  const PickupToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return ToolboxToolPage(
      title: i18n.t('toolbox.sound.deck.pickup'),
      subtitle: i18n.t('toolbox.sound.deck.pickup_title_sub'),
      child: const _PickupTool(),
    );
  }
}

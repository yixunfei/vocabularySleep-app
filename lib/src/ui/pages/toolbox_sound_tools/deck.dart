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
  shakuhachi,
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
  static const List<_HarpDeckInstrument> _instrumentOrder =
      <_HarpDeckInstrument>[
        _HarpDeckInstrument.harp,
        _HarpDeckInstrument.chimes,
        _HarpDeckInstrument.kalimba,
        _HarpDeckInstrument.piano,
        _HarpDeckInstrument.flute,
        _HarpDeckInstrument.shakuhachi,
        _HarpDeckInstrument.guitar,
        _HarpDeckInstrument.triangle,
        _HarpDeckInstrument.drumPad,
        _HarpDeckInstrument.pickup,
      ];

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
      _HarpDeckInstrument.shakuhachi => i18n.t('toolbox.sound.deck.shakuhachi'),
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
      _HarpDeckInstrument.shakuhachi => i18n.t(
        'toolbox.sound.deck.shakuhachi_sub',
      ),
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
      _HarpDeckInstrument.shakuhachi => i18n.t(
        'toolbox.sound.deck.shakuhachi_gesture',
      ),
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
      _HarpDeckInstrument.shakuhachi => i18n.t(
        'toolbox.sound.deck.shakuhachi_mix',
      ),
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
      _HarpDeckInstrument.shakuhachi => Icons.spa_rounded,
      _HarpDeckInstrument.drumPad => Icons.album_rounded,
      _HarpDeckInstrument.guitar => Icons.queue_music_rounded,
      _HarpDeckInstrument.triangle => Icons.change_history_rounded,
      _HarpDeckInstrument.kalimba => Icons.view_week_rounded,
      _HarpDeckInstrument.chimes => Icons.notifications_none_rounded,
      _HarpDeckInstrument.pickup => Icons.graphic_eq_rounded,
      _ => Icons.music_note_rounded,
    };
  }

  Color _accentColor(_HarpDeckInstrument instrument) {
    return switch (instrument) {
      _HarpDeckInstrument.harp => const Color(0xFF8B5CF6),
      _HarpDeckInstrument.chimes => const Color(0xFFEA580C),
      _HarpDeckInstrument.kalimba => const Color(0xFF0D9488),
      _HarpDeckInstrument.piano => const Color(0xFF2563EB),
      _HarpDeckInstrument.flute => const Color(0xFF0284C7),
      _HarpDeckInstrument.shakuhachi => const Color(0xFF0F766E),
      _HarpDeckInstrument.guitar => const Color(0xFFB45309),
      _HarpDeckInstrument.triangle => const Color(0xFF64748B),
      _HarpDeckInstrument.drumPad => const Color(0xFFDC2626),
      _HarpDeckInstrument.pickup => const Color(0xFF16A34A),
    };
  }

  Widget _activeTool() {
    return switch (_selected) {
      _HarpDeckInstrument.piano => const _PianoTool(),
      _HarpDeckInstrument.flute => const _FluteTool(),
      _HarpDeckInstrument.shakuhachi => const _ShakuhachiTool(),
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

  Widget _buildInstrumentGrid(AppI18n i18n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = math.max(1.0, constraints.maxWidth);
        final columns = availableWidth >= 560
            ? 4
            : (availableWidth >= 330 ? 3 : 2);
        const spacing = 8.0;
        final tileWidth = (availableWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            for (final item in _instrumentOrder)
              SizedBox(
                width: tileWidth,
                child: _DeckInstrumentTile(
                  icon: _icon(item),
                  label: _label(i18n, item),
                  color: _accentColor(item),
                  selected: item == _selected,
                  onTap: () => setState(() => _selected = item),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFullScreenAction(AppI18n i18n) {
    final color = _accentColor(_selected);
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _openInstrumentFullScreen,
        icon: const Icon(Icons.open_in_full_rounded),
        label: Text(i18n.t('toolbox.sound.deck.full_screen')),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(58),
          textStyle: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
          shadowColor: color.withValues(alpha: 0.36),
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
                    _buildInstrumentGrid(i18n),
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
        const SizedBox(height: 12),
        _buildFullScreenAction(i18n),
      ],
    );
  }
}

class _DeckInstrumentTile extends StatelessWidget {
  const _DeckInstrumentTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = selected
        ? color.withValues(alpha: 0.16)
        : theme.colorScheme.surfaceContainerHighest;
    final borderColor = selected ? color : theme.colorScheme.outlineVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: selected ? 0.22 : 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: selected ? color : theme.colorScheme.onSurface,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
      _HarpDeckInstrument.shakuhachi => const _ShakuhachiTool(fullScreen: true),
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

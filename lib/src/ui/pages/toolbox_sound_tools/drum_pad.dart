part of '../toolbox_sound_tools.dart';

class _DrumPadSpec {
  const _DrumPadSpec({
    required this.id,
    required this.color,
    required this.icon,
    required this.defaultMix,
  });

  final String id;
  final Color color;
  final IconData icon;
  final double defaultMix;
}

class _DrumPatternTemplate {
  const _DrumPatternTemplate({
    required this.id,
    required this.bpm,
    required this.stepsByPad,
  });

  final String id;
  final int bpm;
  final Map<String, List<int>> stepsByPad;
}

class _DrumLaserBeam {
  const _DrumLaserBeam({
    required this.id,
    required this.color,
    required this.coneWidthFactor,
    required this.startAngle,
    required this.endAngle,
    required this.wobblePhase,
    required this.startedAtMs,
    required this.durationMs,
    required this.opacity,
  });

  final int id;
  final Color color;
  final double coneWidthFactor;
  final double startAngle;
  final double endAngle;
  final double wobblePhase;
  final int startedAtMs;
  final int durationMs;
  final double opacity;
}

class _DrumPadTool extends StatefulWidget {
  const _DrumPadTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_DrumPadTool> createState() => _DrumPadToolState();
}

class _DrumPadToolState extends State<_DrumPadTool>
    with SingleTickerProviderStateMixin {
  static const int _stepCount = 16;
  static final double _laserSweepHalfArc = math.pi * 0.75;

  static const List<_DrumPadSpec> _pads = <_DrumPadSpec>[
    _DrumPadSpec(
      id: 'kick',
      color: Color(0xFF2563EB),
      icon: Icons.radio_button_checked_rounded,
      defaultMix: 0.96,
    ),
    _DrumPadSpec(
      id: 'snare',
      color: Color(0xFFEF4444),
      icon: Icons.graphic_eq_rounded,
      defaultMix: 0.9,
    ),
    _DrumPadSpec(
      id: 'hihat',
      color: Color(0xFFF59E0B),
      icon: Icons.blur_on_rounded,
      defaultMix: 0.64,
    ),
    _DrumPadSpec(
      id: 'openhat',
      color: Color(0xFFF97316),
      icon: Icons.waves_rounded,
      defaultMix: 0.54,
    ),
    _DrumPadSpec(
      id: 'clap',
      color: Color(0xFF8B5CF6),
      icon: Icons.pan_tool_alt_rounded,
      defaultMix: 0.62,
    ),
    _DrumPadSpec(
      id: 'tom',
      color: Color(0xFF10B981),
      icon: Icons.album_rounded,
      defaultMix: 0.64,
    ),
  ];

  static const List<_DrumKitPreset> _presets = <_DrumKitPreset>[
    _DrumKitPreset(
      id: 'acoustic_kit',
      kitId: 'acoustic',
      drive: 0.96,
      tone: 0.48,
      tail: 0.46,
      material: 'wood',
    ),
    _DrumKitPreset(
      id: 'electro_kit',
      kitId: 'electro',
      drive: 0.92,
      tone: 0.72,
      tail: 0.28,
      material: 'hybrid',
    ),
    _DrumKitPreset(
      id: 'lofi_kit',
      kitId: 'lofi',
      drive: 0.84,
      tone: 0.38,
      tail: 0.58,
      material: 'wood',
    ),
  ];

  static const List<_DrumPatternTemplate> _patternTemplates =
      <_DrumPatternTemplate>[
        _DrumPatternTemplate(
          id: 'backbeat',
          bpm: 96,
          stepsByPad: <String, List<int>>{
            'kick': <int>[0, 7, 8, 12],
            'snare': <int>[4, 12],
            'hihat': <int>[0, 2, 4, 6, 8, 10, 12, 14],
            'openhat': <int>[15],
          },
        ),
        _DrumPatternTemplate(
          id: 'four_floor',
          bpm: 122,
          stepsByPad: <String, List<int>>{
            'kick': <int>[0, 4, 8, 12],
            'snare': <int>[4, 12],
            'hihat': <int>[0, 2, 4, 6, 8, 10, 12, 14],
            'clap': <int>[4, 12],
            'openhat': <int>[3, 7, 11, 15],
          },
        ),
        _DrumPatternTemplate(
          id: 'dusty_break',
          bpm: 84,
          stepsByPad: <String, List<int>>{
            'kick': <int>[0, 6, 10],
            'snare': <int>[4, 12],
            'hihat': <int>[1, 3, 5, 7, 9, 11, 13, 15],
            'clap': <int>[12],
            'tom': <int>[14],
          },
        ),
      ];

  final Map<String, ToolboxEffectPlayer> _players =
      <String, ToolboxEffectPlayer>{};
  late final ToolboxEffectPlayer _metronomeAccentPlayer;
  late final ToolboxEffectPlayer _metronomeRegularPlayer;
  late final AnimationController _laserController;
  late final Map<String, List<bool>> _sequence;
  late final Map<String, double> _mixLevels;
  final Map<String, int> _padFlashEpoch = <String, int>{};
  final Map<int, String> _activePadPointers = <int, String>{};
  final Map<String, int> _heldPadCounts = <String, int>{};
  final Set<String> _activePadIds = <String>{};
  final List<_DrumLaserBeam> _laserBeams = <_DrumLaserBeam>[];
  final math.Random _random = math.Random();

  Timer? _transportTimer;
  int _warmUpSerial = 0;
  int _laserSerial = 0;
  String _presetId = _presets.first.id;
  String _kit = _presets.first.kitId;
  String _material = _presets.first.material;
  String _patternId = _patternTemplates.first.id;
  double _drive = _presets.first.drive;
  double _tone = _presets.first.tone;
  double _tail = _presets.first.tail;
  double _masterVolume = 0.92;
  int _bpm = _patternTemplates.first.bpm;
  int _currentStep = -1;
  int _hits = 0;
  int _barsPlayed = 0;
  bool _transportRunning = false;
  bool _metronomeEnabled = true;
  bool _stageLightsEnabled = true;
  String? _lastHitId;

  @override
  void initState() {
    super.initState();
    _sequence = <String, List<bool>>{
      for (final pad in _pads) pad.id: List<bool>.filled(_stepCount, false),
    };
    _mixLevels = <String, double>{
      for (final pad in _pads) pad.id: pad.defaultMix,
    };
    _metronomeAccentPlayer = ToolboxEffectPlayer(
      ToolboxAudioBank.metronomeClick(accent: true),
      maxPlayers: 4,
    );
    _metronomeRegularPlayer = ToolboxEffectPlayer(
      ToolboxAudioBank.metronomeClick(accent: false),
      maxPlayers: 4,
    );
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addListener(_pruneLaserBeams);
    _applyPreset(_presets.first.id, seedPattern: true, warmUp: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_warmUpActivePreset());
    });
  }

  @override
  void dispose() {
    _transportTimer?.cancel();
    _activePadPointers.clear();
    _heldPadCounts.clear();
    unawaited(_metronomeAccentPlayer.dispose());
    unawaited(_metronomeRegularPlayer.dispose());
    _laserController
      ..removeListener(_pruneLaserBeams)
      ..dispose();
    _invalidatePlayers();
    super.dispose();
  }

  _DrumKitPreset get _activePreset {
    return _presets.firstWhere(
      (item) => item.id == _presetId,
      orElse: () => _presets.first,
    );
  }

  Duration get _stepInterval {
    return Duration(milliseconds: (60000 / _bpm / 4).round());
  }

  _DrumPatternTemplate get _activePattern {
    return _patternTemplates.firstWhere(
      (item) => item.id == _patternId,
      orElse: () => _patternTemplates.first,
    );
  }

  void _setViewState(VoidCallback updates) {
    if (!mounted) {
      return;
    }
    setState(updates);
  }

  String _presetLabel(AppI18n i18n, _DrumKitPreset preset) {
    return switch (preset.id) {
      'electro_kit' => i18n.t(
        'inline.ui.pages.toolbox_sound_tools.drum_pad.electro_kit_53058e',
      ),
      'lofi_kit' => i18n.t(
        'inline.ui.pages.toolbox_sound_tools.drum_pad.lo_fi_kit_e85a60',
      ),
      _ => i18n.t(
        'inline.ui.pages.toolbox_sound_tools.drum_pad.acoustic_kit_2987f0',
      ),
    };
  }

  String _presetSubtitle(AppI18n i18n, _DrumKitPreset preset) {
    return switch (preset.id) {
      'electro_kit' => i18n.t(
        'inline.ui.pages.toolbox_sound_tools.drum_pad.sharper_transients_and_tighter_tails_for_electronic_groo_bfdffb',
      ),
      'lofi_kit' => i18n.t(
        'inline.ui.pages.toolbox_sound_tools.drum_pad.looser_impact_with_dusty_tails_for_slower_lo_fi_loops_7cc066',
      ),
      _ => i18n.t(
        'inline.ui.pages.toolbox_sound_tools.drum_pad.natural_attack_and_shell_resonance_closer_to_an_acoustic_b75f5f',
      ),
    };
  }

  String _patternLabel(AppI18n i18n, _DrumPatternTemplate template) {
    return switch (template.id) {
      'four_floor' => i18n.t(
        'inline.ui.pages.toolbox_sound_tools.drum_pad.four_on_floor_d786b6',
      ),
      'dusty_break' => i18n.t(
        'inline.ui.pages.toolbox_sound_tools.drum_pad.dusty_break_e82dc4',
      ),
      _ => i18n.t(
        'inline.ui.pages.toolbox_sound_tools.drum_pad.classic_backbeat_217b9a',
      ),
    };
  }

  String _kitLabel(AppI18n i18n, String value) {
    return switch (value) {
      'electro' => i18n.t(
        'inline.ui.pages.toolbox_sound_tools.drum_pad.electro_e79d08',
      ),
      'lofi' => i18n.t(
        'inline.ui.pages.toolbox_sound_tools.drum_pad.lo_fi_5d3e53',
      ),
      _ => i18n.t('inline.ui.pages.toolbox_human_tests.acoustic_295bc5'),
    };
  }

  String _padLabel(AppI18n i18n, String id) {
    return switch (id) {
      'kick' => i18n.t(
        'inline.ui.pages.toolbox_sound_tools.drum_pad.kick_37abf1',
      ),
      'snare' => i18n.t(
        'inline.ui.pages.toolbox_sound_tools.drum_pad.snare_628c2e',
      ),
      'hihat' => i18n.t(
        'inline.ui.pages.toolbox_sound_tools.drum_pad.hi_hat_8a54d3',
      ),
      'openhat' => i18n.t(
        'inline.ui.pages.toolbox_sound_tools.drum_pad.open_hat_62d10b',
      ),
      'clap' => i18n.t(
        'inline.ui.pages.toolbox_sound_tools.drum_pad.clap_d52cd6',
      ),
      _ => i18n.t('inline.ui.pages.toolbox_sound_tools.drum_pad.tom_3afa62'),
    };
  }

  String _materialLabel(AppI18n i18n, String value) {
    return switch (value) {
      'metal' => i18n.t(
        'inline.ui.pages.toolbox_human_tests_cognition.metal_e06672',
      ),
      'hybrid' => i18n.t(
        'inline.ui.pages.toolbox_sound_tools.drum_pad.hybrid_a64944',
      ),
      _ => i18n.t('inline.ui.pages.toolbox_sound_tools.drum_pad.wood_7e2289'),
    };
  }

  Widget _buildSettingsSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }

  BoxDecoration _immersivePanelDecoration({
    double alpha = 0.06,
    double radius = 22,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.16),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Widget _buildImmersiveStatusPill(
    String label, {
    IconData? icon,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 15, color: iconColor ?? Colors.white70),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenSectionCard(
    BuildContext context, {
    required String title,
    String? subtitle,
    Widget? trailing,
    required Widget child,
    bool fillChild = false,
  }) {
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w800,
    );
    final subtitleStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Colors.white70);
    return Container(
      decoration: _immersivePanelDecoration(alpha: 0.055, radius: 18),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(title, style: titleStyle)),
              // ignore: use_null_aware_elements
              if (trailing != null) trailing,
            ],
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(subtitle, style: subtitleStyle),
          ],
          const SizedBox(height: 10),
          if (fillChild) Expanded(child: child) else child,
        ],
      ),
    );
  }

  Widget _buildFullScreenTransportPanel(BuildContext context, AppI18n i18n) {
    return _buildFullScreenSectionCard(
      context,
      title: i18n.t('ambientCategoryTransport'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_sound_tools.drum_pad.play_metronome_and_tempo_c46659',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: _transportRunning
                      ? _stopTransport
                      : _startTransport,
                  icon: Icon(
                    _transportRunning
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    _transportRunning ? i18n.t('stop') : i18n.t('play'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    setState(() {
                      _metronomeEnabled = !_metronomeEnabled;
                    });
                  },
                  icon: Icon(
                    _metronomeEnabled
                        ? Icons.music_note_rounded
                        : Icons.music_off_rounded,
                  ),
                  label: Text(
                    _metronomeEnabled
                        ? i18n.t(
                            'inline.ui.pages.toolbox_sound_tools.drum_pad.metro_on_907b01',
                          )
                        : i18n.t(
                            'inline.ui.pages.toolbox_sound_tools.drum_pad.metro_off_d334d2',
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            i18n.t(
              'inline.ui.pages.toolbox_sound_tools.drum_pad.tempo_bpm_bpm_0cbf79',
              params: <String, Object?>{'bpm': _bpm},
            ),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Slider(
            value: _bpm.toDouble(),
            min: 60,
            max: 156,
            divisions: 96,
            label: '$_bpm',
            onChanged: (value) {
              setState(() {
                _bpm = value.round();
                _patternId = '';
              });
              _restartTransportIfNeeded();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrumFullScreenWorkspace(BuildContext context, AppI18n i18n) {
    return _buildDrumLiveWorkspace(context, i18n);
  }

  Widget _buildPadTile(BuildContext context, AppI18n i18n, _DrumPadSpec pad) {
    final theme = Theme.of(context);
    final held = _isPadHeld(pad.id);
    final active = held || _activePadIds.contains(pad.id);
    final isLast = _lastHitId == pad.id;
    final surface = widget.fullScreen
        ? Colors.white.withValues(alpha: active ? 0.16 : 0.07)
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = widget.fullScreen
        ? Colors.white
        : theme.colorScheme.onSurface;
    return LayoutBuilder(
      builder: (context, constraints) {
        final ultraCompact =
            constraints.maxHeight < 130 || constraints.maxWidth < 150;
        final compact =
            ultraCompact ||
            constraints.maxHeight < 168 ||
            constraints.maxWidth < 190;
        final tilePadding = ultraCompact
            ? 10.0
            : (compact ? 12.0 : (widget.fullScreen ? 18.0 : 16.0));
        final iconSize = ultraCompact ? 18.0 : (compact ? 20.0 : 24.0);
        final badgeSize = ultraCompact ? 32.0 : (compact ? 38.0 : 46.0);
        final titleStyle = ultraCompact
            ? theme.textTheme.labelLarge
            : (compact
                  ? theme.textTheme.titleSmall
                  : theme.textTheme.titleMedium);
        final subtitleStyle = ultraCompact
            ? theme.textTheme.labelSmall
            : (compact
                  ? theme.textTheme.labelSmall
                  : theme.textTheme.bodySmall);
        final mixLabelStyle = ultraCompact
            ? theme.textTheme.labelSmall
            : theme.textTheme.labelLarge;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                pad.color.withValues(alpha: active ? 0.94 : 0.72),
                pad.color.withValues(alpha: active ? 0.74 : 0.48),
              ],
            ),
            border: Border.all(
              color: active
                  ? Colors.white.withValues(alpha: 0.54)
                  : pad.color.withValues(
                      alpha: widget.fullScreen ? 0.38 : 0.22,
                    ),
              width: active ? 1.8 : 1.2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: pad.color.withValues(alpha: active ? 0.42 : 0.18),
                blurRadius: active ? 26 : 16,
                spreadRadius: active ? 1 : 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: _ToolboxScrollLockSurface(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) => _handlePadPointerDown(
                  pad,
                  event,
                  hitSize: Size(constraints.maxWidth, constraints.maxHeight),
                ),
                onPointerUp: _handlePadPointerEnd,
                onPointerCancel: _handlePadPointerEnd,
                child: Padding(
                  padding: EdgeInsets.all(tilePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: badgeSize,
                            height: badgeSize,
                            decoration: BoxDecoration(
                              color: surface,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              pad.icon,
                              color: foreground,
                              size: iconSize,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${((_mixLevels[pad.id] ?? pad.defaultMix) * 100).round()}%',
                            style: mixLabelStyle?.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        _padLabel(i18n, pad.id),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: ultraCompact ? 2 : (compact ? 4 : 6)),
                      Text(
                        held
                            ? i18n.t(
                                'inline.ui.pages.toolbox_sound_tools.drum_pad.held_9d84fb',
                              )
                            : isLast
                            ? i18n.t(
                                'inline.ui.pages.toolbox_sound_tools.drum_pad.just_hit_27564b',
                              )
                            : i18n.t(
                                'inline.ui.pages.toolbox_sound_tools.drum_pad.tap_to_trigger_voice_b36916',
                              ),
                        maxLines: ultraCompact ? 1 : (compact ? 1 : 2),
                        overflow: TextOverflow.ellipsis,
                        style: subtitleStyle?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPadGrid(BuildContext context, AppI18n i18n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final crossAxisCount = 2;
        final mainAxisExtent = widget.fullScreen
            ? (width >= 760 ? 180.0 : (width >= 560 ? 160.0 : 140.0))
            : (width < 400 ? 120.0 : (width < 560 ? 128.0 : 148.0));
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _pads.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: mainAxisExtent,
          ),
          itemBuilder: (context, index) {
            return _buildPadTile(context, i18n, _pads[index]);
          },
        );
      },
    );
  }

  Widget _buildStepCell(
    BuildContext context,
    _DrumPadSpec pad,
    int stepIndex, {
    void Function(String padId, int stepIndex)? onToggleStep,
  }) {
    final active = _sequence[pad.id]?[stepIndex] ?? false;
    final playing = _currentStep == stepIndex;
    final quarter = stepIndex % 4 == 0;
    final background = active
        ? pad.color.withValues(alpha: playing ? 0.96 : 0.82)
        : (widget.fullScreen
              ? Colors.white.withValues(alpha: playing ? 0.12 : 0.05)
              : Theme.of(context).colorScheme.surfaceContainerLowest);
    final border = playing
        ? Colors.white.withValues(alpha: 0.72)
        : active
        ? pad.color.withValues(alpha: 0.42)
        : Theme.of(context).colorScheme.outlineVariant;
    return GestureDetector(
      onTap: () => (onToggleStep ?? _toggleStep)(pad.id, stepIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: widget.fullScreen ? 32 : 28,
        height: widget.fullScreen ? 50 : 44,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: border,
            width: playing || quarter ? 1.4 : 1,
          ),
          boxShadow: active
              ? <BoxShadow>[
                  BoxShadow(
                    color: pad.color.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const <BoxShadow>[],
        ),
        alignment: Alignment.center,
        child: Text(
          '${stepIndex + 1}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: active
                ? Colors.white
                : (widget.fullScreen
                      ? Colors.white70
                      : Theme.of(context).colorScheme.onSurfaceVariant),
            fontWeight: quarter ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSequencerGrid(
    BuildContext context,
    AppI18n i18n, {
    void Function(String padId, int stepIndex)? onToggleStep,
  }) {
    final theme = Theme.of(context);
    return _ToolboxScrollLockSurface(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: _pads
              .map((pad) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: widget.fullScreen ? 126 : 112,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: widget.fullScreen
                              ? Colors.white.withValues(alpha: 0.06)
                              : theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: widget.fullScreen
                                ? Colors.white.withValues(alpha: 0.08)
                                : theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(pad.icon, color: pad.color, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _padLabel(i18n, pad.id),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: widget.fullScreen
                                      ? Colors.white
                                      : null,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Row(
                        children: List<Widget>.generate(_stepCount, (
                          stepIndex,
                        ) {
                          return Padding(
                            padding: EdgeInsets.only(
                              right: stepIndex == _stepCount - 1 ? 0 : 6,
                            ),
                            child: _buildStepCell(
                              context,
                              pad,
                              stepIndex,
                              onToggleStep: onToggleStep,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }

  Widget _buildTransportBar(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(widget.fullScreen ? 18 : 16),
      decoration: widget.fullScreen
          ? _immersivePanelDecoration(alpha: 0.06, radius: 22)
          : BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _transportRunning ? _stopTransport : _startTransport,
                icon: Icon(
                  _transportRunning
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded,
                ),
                label: Text(
                  _transportRunning ? i18n.t('stop') : i18n.t('play'),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () {
                  setState(() {
                    _metronomeEnabled = !_metronomeEnabled;
                  });
                },
                icon: Icon(
                  _metronomeEnabled
                      ? Icons.music_note_rounded
                      : Icons.music_off_rounded,
                ),
                label: Text(
                  _metronomeEnabled
                      ? i18n.t(
                          'inline.ui.pages.toolbox_sound_tools.drum_pad.metronome_on_005642',
                        )
                      : i18n.t(
                          'inline.ui.pages.toolbox_sound_tools.drum_pad.metronome_off_2cf7bc',
                        ),
                ),
              ),
              if (!widget.fullScreen)
                FilledButton.tonalIcon(
                  onPressed: () => _openDrumSettingsSheet(context, i18n),
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(i18n.t('settings')),
                ),
              if (!widget.fullScreen)
                OutlinedButton.icon(
                  onPressed: () => unawaited(_openFullScreen(context)),
                  icon: const Icon(Icons.open_in_full_rounded),
                  label: Text(i18n.t('toolbox.sound.flute.full_screen')),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            i18n.t(
              'inline.ui.pages.toolbox_sound_tools.drum_pad.tempo_bpm_bpm_0cbf79',
              params: <String, Object?>{'bpm': _bpm},
            ),
            style: theme.textTheme.labelLarge?.copyWith(
              color: widget.fullScreen ? Colors.white : null,
              fontWeight: FontWeight.w700,
            ),
          ),
          Slider(
            value: _bpm.toDouble(),
            min: 60,
            max: 156,
            divisions: 96,
            label: '$_bpm',
            onChanged: (value) {
              setState(() {
                _bpm = value.round();
                _patternId = '';
              });
              _restartTransportIfNeeded();
            },
          ),
          if (widget.fullScreen) ...<Widget>[
            const SizedBox(height: 8),
            _buildHorizontalMetronomeMatrix(context, i18n),
          ],
        ],
      ),
    );
  }

  Widget _buildHorizontalMetronomeMatrix(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    final activeBeat = _currentStep < 0 ? -1 : (_currentStep ~/ 4) % 4;
    final headers = List<String>.generate(4, (index) => '${index + 1}');
    final rowStates = <List<bool>>[
      List<bool>.generate(4, (index) => _metronomeEnabled && index == 0),
      List<bool>.generate(
        4,
        (index) => _metronomeEnabled && index == activeBeat,
      ),
      List<bool>.generate(
        4,
        (index) =>
            _metronomeEnabled &&
            _currentStep >= 0 &&
            index == ((_currentStep % _stepCount) ~/ 4),
      ),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: _immersivePanelDecoration(alpha: 0.05, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _metronomeEnabled
                      ? const Color(0xFF0EA5E9).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _metronomeEnabled
                      ? Icons.music_note_rounded
                      : Icons.music_off_rounded,
                  color: _metronomeEnabled
                      ? const Color(0xFF7DD3FC)
                      : Colors.white54,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _metronomeEnabled
                      ? i18n.t(
                          'inline.ui.pages.toolbox_sound_tools.drum_pad.beat_matrix_3745d4',
                        )
                      : i18n.t(
                          'inline.ui.pages.toolbox_sound_tools.drum_pad.metro_off_d334d2',
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List<Widget>.generate(headers.length, (columnIndex) {
              final accent = columnIndex == 0;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: columnIndex == headers.length - 1 ? 0 : 8,
                  ),
                  child: Column(
                    children: <Widget>[
                      Text(
                        i18n.t(
                          'inline.ui.pages.toolbox_sound_tools.drum_pad.beat_headers_columnindex_9e1610',
                          params: <String, Object?>{
                            'headersColumnIndex': columnIndex + 1,
                          },
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List<Widget>.generate(rowStates.length, (rowIndex) {
                        final active = rowStates[rowIndex][columnIndex];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: rowIndex == rowStates.length - 1 ? 0 : 7,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            width: double.infinity,
                            height: active ? 18 : 14,
                            decoration: BoxDecoration(
                              color: active
                                  ? (accent
                                        ? const Color(0xFF38BDF8)
                                        : Colors.white.withValues(alpha: 0.88))
                                  : Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: active
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.08),
                              ),
                              boxShadow: active
                                  ? <BoxShadow>[
                                      BoxShadow(
                                        color:
                                            (accent
                                                    ? const Color(0xFF38BDF8)
                                                    : Colors.white)
                                                .withValues(alpha: 0.32),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : const <BoxShadow>[],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLaserOverlay() {
    if (!_stageLightsEnabled || _laserBeams.isEmpty) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _laserController,
        builder: (context, _) {
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          return LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: _laserBeams
                    .map((beam) {
                      final elapsedMs = nowMs - beam.startedAtMs;
                      final progress = (elapsedMs / beam.durationMs).clamp(
                        0.0,
                        1.0,
                      );
                      final fade = (1 - progress).clamp(0.0, 1.0);
                      return Positioned.fill(
                        key: ValueKey<int>(beam.id),
                        child: Opacity(
                          opacity: beam.opacity * fade,
                          child: CustomPaint(
                            painter: _DrumSpotlightPainter(
                              beam: beam,
                              progress: progress.toDouble(),
                              fullScreen: widget.fullScreen,
                            ),
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWorkspaceContent(
    BuildContext context,
    AppI18n i18n, {
    bool immersiveMinimal = false,
  }) {
    final theme = Theme.of(context);
    final statusColor = widget.fullScreen ? Colors.white70 : theme.hintColor;
    return Stack(
      children: <Widget>[
        Positioned.fill(child: _buildLaserOverlay()),
        LayoutBuilder(
          builder: (context, constraints) {
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (!immersiveMinimal) ...<Widget>[
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      ToolboxMetricCard(
                        label: i18n.t('toolbox.sound.harp.preset'),
                        value: _presetId.isEmpty
                            ? i18n.t('toolbox.sound.harp.custom')
                            : _presetLabel(i18n, _activePreset),
                      ),
                      ToolboxMetricCard(
                        label: i18n.t(
                          'inline.ui.pages.toolbox_sound_tools.drum_pad.kit_0ffc13',
                        ),
                        value: _kitLabel(i18n, _kit),
                      ),
                      ToolboxMetricCard(
                        label: i18n.t(
                          'inline.ui.pages.toolbox_sound_tools.drum_pad.pattern_5f43ca',
                        ),
                        value: _patternId.isEmpty
                            ? i18n.t(
                                'inline.ui.pages.toolbox_sound_tools.drum_pad.custom_steps_0aef71',
                              )
                            : _patternLabel(i18n, _activePattern),
                      ),
                      ToolboxMetricCard(
                        label: i18n.t('toolbox.sound.flute.material'),
                        value: _materialLabel(i18n, _material),
                      ),
                      ToolboxMetricCard(
                        label: i18n.t(
                          'inline.ui.pages.toolbox_human_tests_action.hits_fe10b3',
                        ),
                        value: '$_hits',
                      ),
                      ToolboxMetricCard(
                        label: i18n.t('toolbox.sleep.routine.step'),
                        value: _currentStep < 0 ? '--' : '${_currentStep + 1}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                _buildTransportBar(context, i18n),
                SizedBox(height: immersiveMinimal ? 12 : 16),
                if (!immersiveMinimal)
                  Text(
                    i18n.t(
                      'inline.ui.pages.toolbox_sound_tools.drum_pad.pad_bank_8e79d0',
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: widget.fullScreen ? Colors.white : null,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                if (!immersiveMinimal) const SizedBox(height: 10),
                _buildPadGrid(context, i18n),
                SizedBox(height: immersiveMinimal ? 14 : 20),
                if (!immersiveMinimal)
                  Text(
                    i18n.t(
                      'inline.ui.pages.toolbox_sound_tools.drum_pad.16_step_sequencer_45fd52',
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: widget.fullScreen ? Colors.white : null,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                if (!immersiveMinimal) const SizedBox(height: 8),
                if (!immersiveMinimal)
                  Text(
                    i18n.t(
                      'inline.ui.pages.toolbox_sound_tools.drum_pad.tap_cells_to_edit_steps_every_4_steps_form_a_beat_for_fa_d887c5',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusColor,
                    ),
                  ),
                SizedBox(height: immersiveMinimal ? 8 : 12),
                _buildSequencerGrid(context, i18n),
                if (!immersiveMinimal) ...<Widget>[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      Chip(
                        label: Text(
                          i18n.t(
                            'inline.ui.pages.toolbox_sound_tools.drum_pad.bars_played_barsplayed_195774',
                            params: <String, Object?>{
                              'barsPlayed': _barsPlayed,
                            },
                          ),
                        ),
                      ),
                      Chip(
                        label: Text(
                          i18n.t(
                            'inline.ui.pages.toolbox_sound_tools.drum_pad.active_steps_activestepcount_6b5ee7',
                            params: <String, Object?>{
                              'activeStepCount': _activeStepCount,
                            },
                          ),
                        ),
                      ),
                      Chip(
                        label: Text(
                          i18n.t(
                            'inline.ui.pages.toolbox_sound_tools.drum_pad.master_mix_mastervolume_100_round_6a552f',
                            params: <String, Object?>{
                              'masterVolume': (_masterVolume * 100).round(),
                            },
                          ),
                        ),
                      ),
                      ActionChip(
                        onPressed: _activeStepCount == 0
                            ? null
                            : _clearSequence,
                        avatar: const Icon(
                          Icons.cleaning_services_rounded,
                          size: 16,
                        ),
                        label: Text(
                          i18n.t(
                            'inline.ui.pages.toolbox_sound_tools.drum_pad.clear_steps_8b01c6',
                          ),
                        ),
                      ),
                      if (_lastHitId != null)
                        Chip(label: Text(_padLabel(i18n, _lastHitId!))),
                    ],
                  ),
                ],
              ],
            );
            if (!widget.fullScreen) {
              return content;
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: content,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMixerSection(
    BuildContext context,
    AppI18n i18n, {
    required void Function(VoidCallback mutation) applySettings,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          i18n.t(
            'inline.ui.pages.toolbox_sound_tools.drum_pad.master_mix_mastervolume_100_round_6a552f',
            params: <String, Object?>{
              'masterVolume': (_masterVolume * 100).round(),
            },
          ),
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: _masterVolume,
          min: 0.3,
          max: 1.0,
          divisions: 14,
          onChanged: (value) => applySettings(() {
            _masterVolume = value;
          }),
        ),
        const SizedBox(height: 6),
        ..._pads.map((pad) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${_padLabel(i18n, pad.id)} '
                '${((_mixLevels[pad.id] ?? pad.defaultMix) * 100).round()}%',
                style: theme.textTheme.labelLarge,
              ),
              Slider(
                value: _mixLevels[pad.id] ?? pad.defaultMix,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                onChanged: (value) => applySettings(() {
                  _mixLevels[pad.id] = value;
                }),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSettingsSheetContent(
    BuildContext context,
    AppI18n i18n, {
    required void Function(VoidCallback mutation) applySettings,
  }) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              ToolboxMetricCard(label: 'BPM', value: '$_bpm'),
              ToolboxMetricCard(
                label: i18n.t(
                  'inline.ui.pages.toolbox_sound_tools.drum_pad.kit_0ffc13',
                ),
                value: _kitLabel(i18n, _kit),
              ),
              ToolboxMetricCard(
                label: i18n.t('toolbox.sound.flute.material'),
                value: _materialLabel(i18n, _material),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingsSectionTitle(
            context,
            i18n.t('toolbox.sound.flute.preset_pack'),
          ),
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
                      applySettings(() {});
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          Text(
            _presetId.isEmpty
                ? i18n.t(
                    'inline.ui.pages.toolbox_sound_tools.drum_pad.current_parameters_differ_from_presets_so_the_kit_is_now_60ba41',
                  )
                : _presetSubtitle(i18n, _activePreset),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: () {
                  setState(() {
                    _metronomeEnabled = !_metronomeEnabled;
                  });
                  applySettings(() {});
                },
                icon: Icon(
                  _metronomeEnabled
                      ? Icons.music_note_rounded
                      : Icons.music_off_rounded,
                ),
                label: Text(
                  _metronomeEnabled
                      ? i18n.t(
                          'inline.ui.pages.toolbox_sound_tools.drum_pad.metronome_on_005642',
                        )
                      : i18n.t(
                          'inline.ui.pages.toolbox_sound_tools.drum_pad.metronome_off_2cf7bc',
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingsSectionTitle(
            context,
            i18n.t(
              'inline.ui.pages.toolbox_sound_tools.drum_pad.kit_body_and_material_48ce8e',
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <String>['acoustic', 'electro', 'lofi']
                .map(
                  (item) => ChoiceChip(
                    label: Text(_kitLabel(i18n, item)),
                    selected: _kit == item,
                    onSelected: (_) {
                      _setKit(item);
                      applySettings(() {});
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <String>['wood', 'hybrid', 'metal']
                .map(
                  (item) => ChoiceChip(
                    label: Text(_materialLabel(i18n, item)),
                    selected: _material == item,
                    onSelected: (_) {
                      _setMaterial(item);
                      applySettings(() {});
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 20),
          _buildSettingsSectionTitle(
            context,
            i18n.t(
              'inline.ui.pages.toolbox_sound_tools.drum_pad.drive_and_tail_e5a5a9',
            ),
          ),
          Text(
            i18n.t(
              'inline.ui.pages.toolbox_sound_tools.drum_pad.drive_drive_100_round_59698e',
              params: <String, Object?>{'drive': (_drive * 100).round()},
            ),
            style: theme.textTheme.labelLarge,
          ),
          Slider(
            value: _drive,
            min: 0.45,
            max: 1.0,
            divisions: 11,
            onChanged: (value) => applySettings(() {
              _drive = value;
              _presetId = '';
            }),
          ),
          Text(
            i18n.t(
              'inline.ui.pages.toolbox_sound_tools.drum_pad.tone_tone_100_round_da4602',
              params: <String, Object?>{'tone': (_tone * 100).round()},
            ),
            style: theme.textTheme.labelLarge,
          ),
          Slider(
            value: _tone,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: (value) => applySettings(() {
              _tone = value;
              _presetId = '';
              _invalidatePlayers();
              _restartTransportIfNeeded();
            }),
          ),
          Text(
            i18n.t(
              'inline.ui.pages.toolbox_sound_tools.drum_pad.tail_tail_100_round_e574e4',
              params: <String, Object?>{'tail': (_tail * 100).round()},
            ),
            style: theme.textTheme.labelLarge,
          ),
          Slider(
            value: _tail,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: (value) => applySettings(() {
              _tail = value;
              _presetId = '';
              _invalidatePlayers();
              _restartTransportIfNeeded();
            }),
          ),
          const SizedBox(height: 20),
          _buildSettingsSectionTitle(
            context,
            i18n.t('toolbox.sound.focus.controlTempo'),
          ),
          Text('$_bpm BPM', style: theme.textTheme.labelLarge),
          Slider(
            value: _bpm.toDouble(),
            min: 60,
            max: 156,
            divisions: 96,
            onChanged: (value) => applySettings(() {
              _bpm = value.round();
              _patternId = '';
              _restartTransportIfNeeded();
            }),
          ),
          const SizedBox(height: 20),
          _buildSettingsSectionTitle(
            context,
            i18n.t(
              'inline.ui.pages.toolbox_sound_tools.drum_pad.stage_lights_6e4b99',
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _stageLightsEnabled,
            onChanged: (value) => applySettings(() {
              _setStageLightsEnabled(value, notify: false);
            }),
            title: Text(
              i18n.t(
                'inline.ui.pages.toolbox_sound_tools.drum_pad.enable_spotlights_4dc393',
              ),
            ),
            subtitle: Text(
              i18n.t(
                'inline.ui.pages.toolbox_sound_tools.drum_pad.layer_intensity_by_drum_voice_and_trigger_random_roaming_a6a179',
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSettingsSectionTitle(
            context,
            i18n.t('inline.ui.pages.toolbox_sound_tools.drum_pad.mixer_9272f7'),
          ),
          _buildMixerSection(context, i18n, applySettings: applySettings),
        ],
      ),
    );
  }

  Widget _buildSequencerSheetContent(
    BuildContext context,
    AppI18n i18n, {
    required VoidCallback onClear,
    required void Function(String padId, int stepIndex) onToggleStep,
    required void Function(String templateId) onApplyTemplate,
    required VoidCallback onClose,
  }) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                i18n.t(
                  'inline.ui.pages.toolbox_sound_tools.drum_pad.16_step_sequencer_45fd52',
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Chip(
                label: Text(
                  i18n.t(
                    'inline.ui.pages.toolbox_sound_tools.drum_pad.active_steps_activestepcount_6b5ee7',
                    params: <String, Object?>{
                      'activeStepCount': _activeStepCount,
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            i18n.t(
              'inline.ui.pages.toolbox_sound_tools.drum_pad.tap_cells_to_edit_rhythm_every_4_steps_form_a_beat_for_q_7652ab',
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          _buildSequencerGrid(context, i18n, onToggleStep: onToggleStep),
          const SizedBox(height: 12),
          Text(
            i18n.t(
              'inline.ui.pages.toolbox_sound_tools.drum_pad.patterns_0512d3',
            ),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _patternTemplates
                .map(
                  (item) => ChoiceChip(
                    label: Text(_patternLabel(i18n, item)),
                    selected: item.id == _patternId,
                    onSelected: (_) => onApplyTemplate(item.id),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              Chip(
                label: Text(
                  i18n.t(
                    'inline.ui.pages.toolbox_sound_tools.drum_pad.bars_played_barsplayed_195774',
                    params: <String, Object?>{'barsPlayed': _barsPlayed},
                  ),
                ),
              ),
              Chip(
                label: Text(
                  i18n.t(
                    'inline.plan296.ui.pages.toolbox.sound.tools.drum.pad.current_step.7960ac9bf2',
                    params: <String, Object?>{
                      'p0': _currentStep < 0 ? '--' : _currentStep + 1,
                    },
                  ),
                ),
              ),
              if (_lastHitId != null)
                Chip(label: Text(_padLabel(i18n, _lastHitId!))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _activeStepCount == 0 ? null : onClear,
                  icon: const Icon(Icons.cleaning_services_rounded),
                  label: Text(
                    i18n.t(
                      'inline.ui.pages.toolbox_sound_tools.drum_pad.clear_steps_8b01c6',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(i18n.t('toolbox.breathing.done')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openDrumSequencerSheet(BuildContext context, AppI18n i18n) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final heightFactor = shortest < 600 ? 0.88 : 0.76;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            void refreshSheet() {
              if (!mounted) {
                return;
              }
              setSheetState(() {});
            }

            return FractionallySizedBox(
              heightFactor: heightFactor,
              child: _buildSequencerSheetContent(
                sheetContext,
                i18n,
                onClear: () {
                  _clearSequence();
                  refreshSheet();
                },
                onToggleStep: (padId, stepIndex) {
                  _toggleStep(padId, stepIndex);
                  refreshSheet();
                },
                onApplyTemplate: (templateId) {
                  _applyPatternTemplate(templateId);
                  refreshSheet();
                },
                onClose: () => Navigator.of(sheetContext).maybePop(),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openDrumSettingsSheet(BuildContext context, AppI18n i18n) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            void applySettings(VoidCallback mutation) {
              if (!mounted) {
                return;
              }
              setState(mutation);
              setSheetState(() {});
              unawaited(_warmUpActivePreset());
            }

            return _buildSettingsSheetContent(
              sheetContext,
              i18n,
              applySettings: applySettings,
            );
          },
        );
      },
    );
  }

  // ignore: unused_element
  Widget _buildDrumFullScreen(BuildContext context, AppI18n i18n) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final overlayButtonStyle = FilledButton.styleFrom(
      backgroundColor: Colors.black.withValues(alpha: 0.55),
      foregroundColor: Colors.white,
      elevation: 0,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    return _buildInstrumentPanelShell(
      context,
      fullScreen: true,
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: topInset > 0 ? 4 : 0),
          Row(
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).maybePop(),
                style: overlayButtonStyle,
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(
                  i18n.t(
                    'inline.ui.pages.toolbox_sound_tools.drum_pad.back_add231',
                  ),
                ),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () => _openDrumSettingsSheet(context, i18n),
                style: overlayButtonStyle,
                icon: const Icon(Icons.tune_rounded),
                label: Text(i18n.t('settings')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _buildImmersiveStatusPill(
                '$_bpm BPM',
                icon: Icons.speed_rounded,
                iconColor: const Color(0xFF38BDF8),
              ),
              _buildImmersiveStatusPill(
                _metronomeEnabled
                    ? i18n.t(
                        'inline.ui.pages.toolbox_sound_tools.drum_pad.metronome_on_005642',
                      )
                    : i18n.t(
                        'inline.ui.pages.toolbox_sound_tools.drum_pad.metronome_off_2cf7bc',
                      ),
                icon: _metronomeEnabled
                    ? Icons.music_note_rounded
                    : Icons.music_off_rounded,
                iconColor: _metronomeEnabled
                    ? const Color(0xFF7DD3FC)
                    : Colors.white54,
              ),
              _buildImmersiveStatusPill(
                i18n.t(
                  'inline.ui.pages.toolbox_sound_tools.drum_pad.hits_hits_6dd70f',
                  params: <String, Object?>{'hits': _hits},
                ),
                icon: Icons.flash_on_rounded,
                iconColor: const Color(0xFFFDE68A),
              ),
              _buildImmersiveStatusPill(
                _patternId.isEmpty
                    ? i18n.t(
                        'inline.ui.pages.toolbox_sound_tools.drum_pad.custom_steps_0aef71',
                      )
                    : _patternLabel(i18n, _activePattern),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(child: _buildDrumFullScreenWorkspace(context, i18n)),
        ],
      ),
    );
  }

  Widget _buildDrumLiveOverviewCard(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    final presetLabel = _presetId.isEmpty
        ? i18n.t(
            'inline.ui.pages.toolbox_sound_tools.drum_pad.custom_mix_099e76',
          )
        : _presetLabel(i18n, _activePreset);
    final presetSubtitle = _presetId.isEmpty
        ? i18n.t(
            'inline.ui.pages.toolbox_sound_tools.drum_pad.the_current_parameters_have_drifted_away_from_the_preset_7ee60f',
          )
        : _presetSubtitle(i18n, _activePreset);
    final lastPad = _lastHitId == null
        ? null
        : _pads.firstWhere(
            (pad) => pad.id == _lastHitId,
            orElse: () => _pads.first,
          );
    return _buildFullScreenSectionCard(
      context,
      title: i18n.t(
        'inline.ui.pages.toolbox_sound_tools.drum_pad.live_overview_3d2149',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_sound_tools.drum_pad.current_kit_arrangement_and_performance_status_at_a_glan_a9a901',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            presetLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            presetSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _buildImmersiveStatusPill(
                _kitLabel(i18n, _kit),
                icon: Icons.library_music_rounded,
                iconColor: const Color(0xFF38BDF8),
              ),
              _buildImmersiveStatusPill(
                _materialLabel(i18n, _material),
                icon: Icons.album_rounded,
                iconColor: const Color(0xFFFDA4AF),
              ),
              _buildImmersiveStatusPill(
                i18n.t(
                  'inline.ui.pages.toolbox_sound_tools.drum_pad.barsplayed_bars_699b76',
                  params: <String, Object?>{'barsPlayed': _barsPlayed},
                ),
                icon: Icons.repeat_rounded,
                iconColor: const Color(0xFF86EFAC),
              ),
              _buildImmersiveStatusPill(
                i18n.t(
                  'inline.ui.pages.toolbox_sound_tools.drum_pad.mix_mastervolume_100_round_8d5f68',
                  params: <String, Object?>{
                    'masterVolume': (_masterVolume * 100).round(),
                  },
                ),
                icon: Icons.tune_rounded,
                iconColor: const Color(0xFFC4B5FD),
              ),
              if (lastPad != null)
                _buildImmersiveStatusPill(
                  _padLabel(i18n, lastPad.id),
                  icon: lastPad.icon,
                  iconColor: lastPad.color,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrumLivePadDeck(BuildContext context, AppI18n i18n) {
    final lastPad = _lastHitId == null
        ? null
        : _pads.firstWhere(
            (pad) => pad.id == _lastHitId,
            orElse: () => _pads.first,
          );
    return _buildFullScreenSectionCard(
      context,
      title: i18n.t(
        'inline.ui.pages.toolbox_sound_tools.drum_pad.performance_deck_ae48e3',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_sound_tools.drum_pad.strike_position_directly_shapes_accents_and_the_laser_st_9360c4',
      ),
      trailing: _buildImmersiveStatusPill(
        lastPad == null
            ? i18n.t(
                'inline.ui.pages.toolbox_sound_tools.drum_pad.ready_to_play_6f27fa',
              )
            : _padLabel(i18n, lastPad.id),
        icon: lastPad?.icon ?? Icons.touch_app_rounded,
        iconColor: lastPad?.color ?? const Color(0xFF7DD3FC),
      ),
      fillChild: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.02),
                Colors.black.withValues(alpha: 0.18),
              ],
            ),
          ),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.05,
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              if (_stageLightsEnabled)
                Positioned.fill(
                  child: IgnorePointer(child: _buildLaserOverlay()),
                ),
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final minHeight = constraints.maxHeight.isFinite
                        ? math.max(0.0, constraints.maxHeight - 32)
                        : 0.0;
                    return _ToolboxScrollLockSurface(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: minHeight),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: _buildPadGrid(context, i18n),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrumLiveWorkspace(BuildContext context, AppI18n i18n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone = constraints.maxWidth < 600;

        if (isPhone) {
          return _buildPhoneFullScreenLayout(context, i18n, constraints);
        }

        final sidebarWidth = constraints.maxWidth >= 1480 ? 420.0 : 376.0;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(child: _buildDrumLivePadDeck(context, i18n)),
            const SizedBox(width: 12),
            SizedBox(
              width: sidebarWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildFullScreenTransportPanel(context, i18n),
                  const SizedBox(height: 12),
                  _buildDrumLiveOverviewCard(context, i18n),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhoneFullScreenLayout(
    BuildContext context,
    AppI18n i18n,
    BoxConstraints constraints,
  ) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final compact = constraints.maxHeight < 760 || constraints.maxWidth < 390;
    final transportHeight = compact ? 156.0 : 172.0;

    return Padding(
      padding: EdgeInsets.only(
        top: viewPadding.top + 8,
        left: 12,
        right: 12,
        bottom: viewPadding.bottom + 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: _buildDrumLivePadDeck(context, i18n)),
          const SizedBox(height: 10),
          SizedBox(
            height: transportHeight,
            child: _buildPhoneTransportPanel(context, i18n),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneTransportPanel(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 360;
    final actionButtonSize = compact ? const Size(40, 40) : const Size(44, 44);
    final actionSpacing = compact ? 4.0 : 6.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: _transportRunning
                      ? _stopTransport
                      : _startTransport,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 14,
                      vertical: compact ? 10 : 12,
                    ),
                  ),
                  icon: Icon(
                    _transportRunning
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _transportRunning ? i18n.t('stop') : i18n.t('play'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(width: actionSpacing),
              IconButton.filled(
                onPressed: () =>
                    setState(() => _metronomeEnabled = !_metronomeEnabled),
                icon: Icon(
                  _metronomeEnabled
                      ? Icons.music_note_rounded
                      : Icons.music_off_rounded,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: _metronomeEnabled
                      ? const Color(0xFF0EA5E9).withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                  minimumSize: actionButtonSize,
                ),
              ),
              SizedBox(width: actionSpacing),
              IconButton.outlined(
                onPressed: () => _openDrumSettingsSheet(context, i18n),
                icon: const Icon(Icons.tune_rounded, size: 20),
                style: IconButton.styleFrom(minimumSize: actionButtonSize),
              ),
              SizedBox(width: actionSpacing),
              IconButton.outlined(
                onPressed: () => _openDrumSequencerSheet(context, i18n),
                icon: const Icon(Icons.grid_view_rounded, size: 20),
                style: IconButton.styleFrom(minimumSize: actionButtonSize),
              ),
              SizedBox(width: actionSpacing),
              IconButton.outlined(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded, size: 20),
                style: IconButton.styleFrom(minimumSize: actionButtonSize),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: <Widget>[
              Text(
                '$_bpm',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                ' BPM',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _bpm.toDouble(),
                  min: 60,
                  max: 156,
                  divisions: 96,
                  onChanged: (value) {
                    setState(() {
                      _bpm = value.round();
                      _patternId = '';
                    });
                    _restartTransportIfNeeded();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrumImmersiveFullScreen(BuildContext context, AppI18n i18n) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final leftInset = MediaQuery.viewPaddingOf(context).left;
    final rightInset = MediaQuery.viewPaddingOf(context).right;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF0A0A14),
            Color(0xFF12121F),
            Color(0xFF0A0A14),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: <Widget>[
            if (_stageLightsEnabled)
              Positioned.fill(child: _buildLaserOverlay()),
            Column(
              children: <Widget>[
                SizedBox(height: topInset + 8),
                _buildLandscapeTopBar(context, i18n),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: leftInset + 12,
                      right: rightInset + 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: 3,
                          child: _buildLandscapePadDeck(context, i18n),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _buildLandscapeSidebar(context, i18n),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: bottomInset + 8),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeTopBar(BuildContext context, AppI18n i18n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                IconButton(
                  onPressed: () => _openDrumSettingsSheet(context, i18n),
                  icon: const Icon(Icons.tune_rounded, color: Colors.white),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                IconButton(
                  onPressed: () => _openDrumSequencerSheet(context, i18n),
                  icon: const Icon(
                    Icons.grid_view_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _buildLandscapeStatusChip(
            icon: Icons.speed_rounded,
            label: '$_bpm BPM',
            color: const Color(0xFF38BDF8),
          ),
          const SizedBox(width: 8),
          _buildLandscapeStatusChip(
            icon: _metronomeEnabled
                ? Icons.music_note_rounded
                : Icons.music_off_rounded,
            label: _metronomeEnabled
                ? i18n.t(
                    'inline.ui.pages.toolbox_sound_tools.drum_pad.metro_f8bca5',
                  )
                : i18n.t('toolbox.sound.flute.off'),
            color: _metronomeEnabled ? const Color(0xFF7DD3FC) : Colors.white54,
          ),
          const SizedBox(width: 8),
          _buildLandscapeStatusChip(
            icon: Icons.flash_on_rounded,
            label: i18n.t(
              'inline.ui.pages.toolbox_sound_tools.drum_pad.hits_hits_6dd70f',
              params: <String, Object?>{'hits': _hits},
            ),
            color: const Color(0xFFFDE68A),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeStatusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapePadDeck(BuildContext context, AppI18n i18n) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(child: _buildLandscapePadTile(context, i18n, _pads[0])),
              const SizedBox(width: 8),
              Expanded(child: _buildLandscapePadTile(context, i18n, _pads[1])),
              const SizedBox(width: 8),
              Expanded(child: _buildLandscapePadTile(context, i18n, _pads[2])),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(child: _buildLandscapePadTile(context, i18n, _pads[3])),
              const SizedBox(width: 8),
              Expanded(child: _buildLandscapePadTile(context, i18n, _pads[4])),
              const SizedBox(width: 8),
              Expanded(child: _buildLandscapePadTile(context, i18n, _pads[5])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapePadTile(
    BuildContext context,
    AppI18n i18n,
    _DrumPadSpec pad,
  ) {
    final held = _isPadHeld(pad.id);
    final active = held || _activePadIds.contains(pad.id);

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) =>
          _handlePadPointerDown(pad, event, hitSize: Size.zero),
      onPointerUp: _handlePadPointerEnd,
      onPointerCancel: _handlePadPointerEnd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              pad.color.withValues(alpha: active ? 1.0 : 0.85),
              pad.color.withValues(alpha: active ? 0.85 : 0.65),
            ],
          ),
          border: Border.all(
            color: active
                ? Colors.white.withValues(alpha: 0.5)
                : pad.color.withValues(alpha: 0.3),
            width: active ? 2 : 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: pad.color.withValues(alpha: active ? 0.6 : 0.3),
              blurRadius: active ? 24 : 16,
              spreadRadius: active ? 1 : 0,
            ),
          ],
        ),
        child: Stack(
          children: <Widget>[
            if (_stageLightsEnabled && active)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(pad.icon, color: Colors.white, size: 32),
                  const SizedBox(height: 6),
                  Text(
                    _padLabel(i18n, pad.id),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeSidebar(BuildContext context, AppI18n i18n) {
    return Column(
      children: <Widget>[
        _buildLandscapeTransportPanel(context, i18n),
        const SizedBox(height: 12),
        Expanded(child: _buildLandscapeMetronomePanel(context, i18n)),
      ],
    );
  }

  Widget _buildLandscapeTransportPanel(BuildContext context, AppI18n i18n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: _transportRunning
                      ? _stopTransport
                      : _startTransport,
                  style: FilledButton.styleFrom(
                    backgroundColor: _transportRunning
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    _transportRunning
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    size: 20,
                  ),
                  label: Text(
                    _transportRunning ? i18n.t('stop') : i18n.t('play'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: _metronomeEnabled
                      ? const Color(0xFF38BDF8).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _metronomeEnabled
                        ? const Color(0xFF38BDF8).withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: IconButton(
                  onPressed: () =>
                      setState(() => _metronomeEnabled = !_metronomeEnabled),
                  icon: Icon(
                    _metronomeEnabled
                        ? Icons.music_note_rounded
                        : Icons.music_off_rounded,
                    color: _metronomeEnabled
                        ? const Color(0xFF7DD3FC)
                        : Colors.white54,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              const Icon(
                Icons.speed_rounded,
                color: Color(0xFF38BDF8),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: const Color(0xFF38BDF8),
                    inactiveTrackColor: const Color(
                      0xFF38BDF8,
                    ).withValues(alpha: 0.2),
                    thumbColor: const Color(0xFF38BDF8),
                    overlayColor: const Color(
                      0xFF38BDF8,
                    ).withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _bpm.toDouble(),
                    min: 60,
                    max: 156,
                    divisions: 96,
                    onChanged: (value) {
                      setState(() {
                        _bpm = value.round();
                        _patternId = '';
                      });
                      _restartTransportIfNeeded();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$_bpm',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeMetronomePanel(BuildContext context, AppI18n i18n) {
    final lastPad = _lastHitId == null
        ? null
        : _pads.firstWhere(
            (pad) => pad.id == _lastHitId,
            orElse: () => _pads.first,
          );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                i18n.t(
                  'inline.ui.pages.toolbox_sound_tools.drum_pad.beat_monitor_76dbc0',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _transportRunning
                    ? i18n.t(
                        'inline.ui.pages.toolbox_human_tests_action.running_6a424b',
                      )
                    : i18n.t('timerIdle'),
                style: const TextStyle(
                  color: Color(0xFF7DD3FC),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _buildLandscapeStatusChip(
                icon: Icons.repeat_rounded,
                label: i18n.t(
                  'inline.ui.pages.toolbox_sound_tools.drum_pad.bars_barsplayed_c1618d',
                  params: <String, Object?>{'barsPlayed': _barsPlayed},
                ),
                color: const Color(0xFF86EFAC),
              ),
              _buildLandscapeStatusChip(
                icon: Icons.tune_rounded,
                label: i18n.t(
                  'inline.ui.pages.toolbox_sound_tools.drum_pad.mix_mastervolume_100_round_8d5f68',
                  params: <String, Object?>{
                    'masterVolume': (_masterVolume * 100).round(),
                  },
                ),
                color: const Color(0xFFC4B5FD),
              ),
              if (lastPad != null)
                _buildLandscapeStatusChip(
                  icon: lastPad.icon,
                  label: _padLabel(i18n, lastPad.id),
                  color: lastPad.color,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildHorizontalMetronomeMatrix(context, i18n),
        ],
      ),
    );
  }

  Widget _buildPhoneImmersiveFullScreen(BuildContext context, AppI18n i18n) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF0A0A14),
            Color(0xFF12121F),
            Color(0xFF0A0A14),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: <Widget>[
            if (_stageLightsEnabled)
              Positioned.fill(child: _buildLaserOverlay()),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return _buildPhoneFullScreenLayout(
                    context,
                    i18n,
                    constraints,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    if (widget.fullScreen) {
      final usePhoneFullScreen = MediaQuery.sizeOf(context).shortestSide < 600;
      if (usePhoneFullScreen) {
        return _buildPhoneImmersiveFullScreen(context, i18n);
      }
      return _buildDrumImmersiveFullScreen(context, i18n);
    }
    return _buildInstrumentPanelShell(
      context,
      fullScreen: false,
      child: _buildWorkspaceContent(context, i18n),
    );
  }
}

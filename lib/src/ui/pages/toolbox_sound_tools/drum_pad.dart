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

class _DrumPadTool extends StatefulWidget {
  const _DrumPadTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_DrumPadTool> createState() => _DrumPadToolState();
}

class _DrumPadToolState extends State<_DrumPadTool> {
  static const int _stepCount = 16;

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
  late final Map<String, List<bool>> _sequence;
  late final Map<String, double> _mixLevels;
  final Map<String, int> _padFlashEpoch = <String, int>{};
  final Set<String> _activePadIds = <String>{};

  Timer? _transportTimer;
  int _warmUpSerial = 0;
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
  int _barsPlayed = 0;
  int _hits = 0;
  bool _transportRunning = false;
  bool _metronomeEnabled = true;
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
    _applyPreset(_presets.first.id, seedPattern: true, warmUp: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_warmUpActivePreset());
    });
  }

  @override
  void dispose() {
    _transportTimer?.cancel();
    unawaited(_metronomeAccentPlayer.dispose());
    unawaited(_metronomeRegularPlayer.dispose());
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

  int get _activeStepCount {
    var count = 0;
    for (final row in _sequence.values) {
      for (final active in row) {
        if (active) {
          count += 1;
        }
      }
    }
    return count;
  }

  _DrumPatternTemplate get _activePattern {
    return _patternTemplates.firstWhere(
      (item) => item.id == _patternId,
      orElse: () => _patternTemplates.first,
    );
  }

  String _presetLabel(AppI18n i18n, _DrumKitPreset preset) {
    return switch (preset.id) {
      'electro_kit' => pickUiText(i18n, zh: '电子套件', en: 'Electro kit'),
      'lofi_kit' => pickUiText(i18n, zh: 'Lo-fi 套件', en: 'Lo-fi kit'),
      _ => pickUiText(i18n, zh: '原声套件', en: 'Acoustic kit'),
    };
  }

  String _presetSubtitle(AppI18n i18n, _DrumKitPreset preset) {
    return switch (preset.id) {
      'electro_kit' => pickUiText(
        i18n,
        zh: '瞬态更利落、尾音更短，适合电子和节奏驱动型编排。',
        en: 'Sharper transients and tighter tails for electronic grooves.',
      ),
      'lofi_kit' => pickUiText(
        i18n,
        zh: '鼓皮更松、灰尘感更重，适合慢速 Lo-fi 与低速 loop。',
        en: 'Looser impact with dusty tails for slower lo-fi loops.',
      ),
      _ => pickUiText(
        i18n,
        zh: '更接近原声鼓组的自然起音、壳体共振和鼓腔空气感。',
        en: 'Natural attack and shell resonance closer to an acoustic kit.',
      ),
    };
  }

  String _patternLabel(AppI18n i18n, _DrumPatternTemplate template) {
    return switch (template.id) {
      'four_floor' => pickUiText(i18n, zh: '四踩地板', en: 'Four on floor'),
      'dusty_break' => pickUiText(i18n, zh: '灰尘 break', en: 'Dusty break'),
      _ => pickUiText(i18n, zh: '经典 backbeat', en: 'Classic backbeat'),
    };
  }

  String _kitLabel(AppI18n i18n, String value) {
    return switch (value) {
      'electro' => pickUiText(i18n, zh: '电子', en: 'Electro'),
      'lofi' => pickUiText(i18n, zh: 'Lo-fi', en: 'Lo-fi'),
      _ => pickUiText(i18n, zh: '原声', en: 'Acoustic'),
    };
  }

  String _padLabel(AppI18n i18n, String id) {
    return switch (id) {
      'kick' => pickUiText(i18n, zh: '底鼓', en: 'Kick'),
      'snare' => pickUiText(i18n, zh: '军鼓', en: 'Snare'),
      'hihat' => pickUiText(i18n, zh: '闭镲', en: 'Hi-hat'),
      'openhat' => pickUiText(i18n, zh: '开镲', en: 'Open hat'),
      'clap' => pickUiText(i18n, zh: '拍手', en: 'Clap'),
      _ => pickUiText(i18n, zh: '通鼓', en: 'Tom'),
    };
  }

  String _materialLabel(AppI18n i18n, String value) {
    return switch (value) {
      'metal' => pickUiText(i18n, zh: '金属', en: 'Metal'),
      'hybrid' => pickUiText(i18n, zh: '混合', en: 'Hybrid'),
      _ => pickUiText(i18n, zh: '木腔', en: 'Wood'),
    };
  }

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
    for (final pad in _pads.take(4)) {
      if (!mounted || serial != _warmUpSerial) {
        return;
      }
      await _playerFor(pad.id).warmUp();
    }
  }

  void _setKit(String value) {
    if (_kit == value) return;
    setState(() {
      _kit = value;
      _presetId = '';
    });
    _invalidatePlayers();
    _restartTransportIfNeeded();
    unawaited(_warmUpActivePreset());
  }

  void _setMaterial(String value) {
    if (_material == value) return;
    setState(() {
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
    final preset = _presets.firstWhere(
      (item) => item.id == presetId,
      orElse: () => _presets.first,
    );
    setState(() {
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
        _patternTemplates.first.id,
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
    final template = _patternTemplates.firstWhere(
      (item) => item.id == templateId,
      orElse: () => _patternTemplates.first,
    );
    setState(() {
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
    setState(() {
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
    setState(() {
      row[stepIndex] = !row[stepIndex];
      _patternId = '';
    });
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

  void _flashPad(String padId) {
    final nextEpoch = (_padFlashEpoch[padId] ?? 0) + 1;
    _padFlashEpoch[padId] = nextEpoch;
    if (mounted) {
      setState(() {
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
      setState(() {
        _activePadIds.remove(padId);
      });
    });
  }

  Future<void> _playPad(String padId, {bool manual = true}) async {
    if (manual) {
      HapticFeedback.selectionClick();
    }
    await _hit(padId);
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
    _flashPad(padId);
    setState(() {
      _lastHitId = padId;
      _hits += 1;
    });
  }

  void _tickTransport() {
    final nextStep = (_currentStep + 1) % _stepCount;
    final stepHasDrums = _pads.any(
      (pad) => _sequence[pad.id]?[nextStep] ?? false,
    );
    if (_metronomeEnabled && nextStep % 4 == 0) {
      final player = nextStep == 0
          ? _metronomeAccentPlayer
          : _metronomeRegularPlayer;
      final metronomeVolume = nextStep == 0
          ? (stepHasDrums ? 0.52 : 0.68)
          : (stepHasDrums ? 0.34 : 0.46);
      unawaited(player.play(volume: metronomeVolume));
    }
    if (nextStep == 0) {
      _barsPlayed += 1;
    }
    for (final pad in _pads) {
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
    setState(() {
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
      setState(() {});
    }
  }

  void _stopTransport() {
    _transportTimer?.cancel();
    _transportTimer = null;
    if (!mounted) {
      return;
    }
    setState(() {
      _transportRunning = false;
      _currentStep = -1;
    });
  }

  void _restartTransportIfNeeded() {
    if (_transportRunning) {
      _startTransport();
    } else if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openFullScreen(BuildContext context) async {
    if (widget.fullScreen) {
      return;
    }
    await _enterToolboxLandscapeMode();
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

  Widget _buildPadTile(BuildContext context, AppI18n i18n, _DrumPadSpec pad) {
    final theme = Theme.of(context);
    final active = _activePadIds.contains(pad.id);
    final isLast = _lastHitId == pad.id;
    final surface = widget.fullScreen
        ? Colors.white.withValues(alpha: active ? 0.16 : 0.07)
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = widget.fullScreen
        ? Colors.white
        : theme.colorScheme.onSurface;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 168 || constraints.maxWidth < 190;
        final tilePadding = compact ? 12.0 : (widget.fullScreen ? 18.0 : 16.0);
        final iconSize = compact ? 20.0 : 24.0;
        final badgeSize = compact ? 38.0 : 46.0;
        final titleStyle = compact
            ? theme.textTheme.titleSmall
            : theme.textTheme.titleMedium;
        final subtitleStyle = compact
            ? theme.textTheme.labelSmall
            : theme.textTheme.bodySmall;
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
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => unawaited(_playPad(pad.id)),
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
                          style: theme.textTheme.labelLarge?.copyWith(
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
                    SizedBox(height: compact ? 4 : 6),
                    Text(
                      isLast
                          ? pickUiText(i18n, zh: '刚刚击中', en: 'Just hit')
                          : pickUiText(
                              i18n,
                              zh: '点击触发鼓件',
                              en: 'Tap to trigger voice',
                            ),
                      maxLines: compact ? 1 : 2,
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
        );
      },
    );
  }

  Widget _buildPadGrid(BuildContext context, AppI18n i18n) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = widget.fullScreen
        ? (width >= 1320
              ? 4
              : width >= 980
              ? 3
              : 2)
        : (width >= 880
              ? 3
              : width >= 560
              ? 2
              : 1);
    final mainAxisExtent = widget.fullScreen
        ? (width < 760 ? 138.0 : 156.0)
        : (width < 400 ? 132.0 : 148.0);
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
  }

  Widget _buildStepCell(BuildContext context, _DrumPadSpec pad, int stepIndex) {
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
      onTap: () => _toggleStep(pad.id, stepIndex),
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

  Widget _buildSequencerGrid(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
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
                                color: widget.fullScreen ? Colors.white : null,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Row(
                      children: List<Widget>.generate(_stepCount, (stepIndex) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: stepIndex == _stepCount - 1 ? 0 : 6,
                          ),
                          child: _buildStepCell(context, pad, stepIndex),
                        );
                      }),
                    ),
                  ],
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _buildTransportBar(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(widget.fullScreen ? 18 : 16),
      decoration: BoxDecoration(
        color: widget.fullScreen
            ? Colors.white.withValues(alpha: 0.06)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: widget.fullScreen
              ? Colors.white.withValues(alpha: 0.08)
              : theme.colorScheme.outlineVariant,
        ),
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
                  _transportRunning
                      ? pickUiText(i18n, zh: '停止', en: 'Stop')
                      : pickUiText(i18n, zh: '播放', en: 'Play'),
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
                      ? pickUiText(i18n, zh: '节拍器开', en: 'Metronome on')
                      : pickUiText(i18n, zh: '节拍器关', en: 'Metronome off'),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _openDrumSettingsSheet(context, i18n),
                icon: const Icon(Icons.tune_rounded),
                label: Text(pickUiText(i18n, zh: '设置', en: 'Settings')),
              ),
              if (!widget.fullScreen)
                OutlinedButton.icon(
                  onPressed: () => unawaited(_openFullScreen(context)),
                  icon: const Icon(Icons.open_in_full_rounded),
                  label: Text(pickUiText(i18n, zh: '全屏', en: 'Full screen')),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            pickUiText(i18n, zh: '速度 $_bpm BPM', en: 'Tempo $_bpm BPM'),
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
        ],
      ),
    );
  }

  Widget _buildWorkspaceContent(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    final statusColor = widget.fullScreen ? Colors.white70 : theme.hintColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: pickUiText(i18n, zh: '预设', en: 'Preset'),
              value: _presetId.isEmpty
                  ? pickUiText(i18n, zh: '自定义', en: 'Custom')
                  : _presetLabel(i18n, _activePreset),
            ),
            ToolboxMetricCard(
              label: pickUiText(i18n, zh: '模板', en: 'Pattern'),
              value: _patternId.isEmpty
                  ? pickUiText(i18n, zh: '自编步进', en: 'Custom steps')
                  : _patternLabel(i18n, _activePattern),
            ),
            ToolboxMetricCard(
              label: pickUiText(i18n, zh: '音色', en: 'Kit'),
              value: _kitLabel(i18n, _kit),
            ),
            ToolboxMetricCard(
              label: pickUiText(i18n, zh: '材质', en: 'Material'),
              value: _materialLabel(i18n, _material),
            ),
            ToolboxMetricCard(
              label: pickUiText(i18n, zh: '命中', en: 'Hits'),
              value: '$_hits',
            ),
            ToolboxMetricCard(
              label: pickUiText(i18n, zh: '当前步', en: 'Step'),
              value: _currentStep < 0 ? '--' : '${_currentStep + 1}',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTransportBar(context, i18n),
        const SizedBox(height: 16),
        Text(
          pickUiText(i18n, zh: '鼓件面板', en: 'Pad bank'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: widget.fullScreen ? Colors.white : null,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        _buildPadGrid(context, i18n),
        const SizedBox(height: 20),
        Text(
          pickUiText(i18n, zh: '16 步节拍器', en: '16-step sequencer'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: widget.fullScreen ? Colors.white : null,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          pickUiText(
            i18n,
            zh: '点击格子编辑步进；每 4 步为一拍，适合快速落地鼓型和 loop。',
            en: 'Tap cells to edit steps. Every 4 steps form a beat for fast groove building.',
          ),
          style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
        ),
        const SizedBox(height: 12),
        _buildSequencerGrid(context, i18n),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            Chip(
              label: Text(
                pickUiText(
                  i18n,
                  zh: '激活步数 $_activeStepCount',
                  en: 'Active steps $_activeStepCount',
                ),
              ),
            ),
            Chip(
              label: Text(
                pickUiText(
                  i18n,
                  zh: '已播小节 $_barsPlayed',
                  en: 'Bars played $_barsPlayed',
                ),
              ),
            ),
            Chip(
              label: Text(
                pickUiText(
                  i18n,
                  zh: '主混音 ${(_masterVolume * 100).round()}%',
                  en: 'Master mix ${(_masterVolume * 100).round()}%',
                ),
              ),
            ),
            if (_lastHitId != null)
              Chip(label: Text(_padLabel(i18n, _lastHitId!))),
          ],
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
          pickUiText(
            i18n,
            zh: '主混音 ${(_masterVolume * 100).round()}%',
            en: 'Master mix ${(_masterVolume * 100).round()}%',
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
                label: pickUiText(i18n, zh: '音色', en: 'Kit'),
                value: _kitLabel(i18n, _kit),
              ),
              ToolboxMetricCard(
                label: pickUiText(i18n, zh: '材质', en: 'Material'),
                value: _materialLabel(i18n, _material),
              ),
              ToolboxMetricCard(
                label: pickUiText(i18n, zh: '模板', en: 'Pattern'),
                value: _patternId.isEmpty
                    ? pickUiText(i18n, zh: '自定义', en: 'Custom')
                    : _patternLabel(i18n, _activePattern),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingsSectionTitle(
            context,
            pickUiText(i18n, zh: '套件预设', en: 'Preset pack'),
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
                ? pickUiText(
                    i18n,
                    zh: '当前参数已偏离预设，鼓组处于自定义状态。',
                    en: 'Current parameters differ from presets, so the kit is now custom.',
                  )
                : _presetSubtitle(i18n, _activePreset),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          _buildSettingsSectionTitle(
            context,
            pickUiText(i18n, zh: '鼓型模板', en: 'Pattern template'),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _patternTemplates
                .map(
                  (item) => ChoiceChip(
                    label: Text(_patternLabel(i18n, item)),
                    selected: item.id == _patternId,
                    onSelected: (_) {
                      _applyPatternTemplate(item.id);
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
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: () {
                  _clearSequence();
                  applySettings(() {});
                },
                icon: const Icon(Icons.cleaning_services_rounded),
                label: Text(pickUiText(i18n, zh: '清空步进', en: 'Clear sequence')),
              ),
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
                      ? pickUiText(i18n, zh: '节拍器已开', en: 'Metronome on')
                      : pickUiText(i18n, zh: '节拍器已关', en: 'Metronome off'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingsSectionTitle(
            context,
            pickUiText(i18n, zh: '鼓腔与材质', en: 'Kit body and material'),
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
            pickUiText(i18n, zh: '动态与尾音', en: 'Drive and tail'),
          ),
          Text(
            pickUiText(
              i18n,
              zh: '驱动 ${(_drive * 100).round()}%',
              en: 'Drive ${(_drive * 100).round()}%',
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
            pickUiText(
              i18n,
              zh: '音色 ${(_tone * 100).round()}%',
              en: 'Tone ${(_tone * 100).round()}%',
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
            pickUiText(
              i18n,
              zh: '尾音 ${(_tail * 100).round()}%',
              en: 'Tail ${(_tail * 100).round()}%',
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
            pickUiText(i18n, zh: '节奏速度', en: 'Tempo'),
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
            pickUiText(i18n, zh: '混音', en: 'Mixer'),
          ),
          _buildMixerSection(context, i18n, applySettings: applySettings),
        ],
      ),
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

  Widget _buildDrumFullScreen(BuildContext context, AppI18n i18n) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final overlayButtonStyle = FilledButton.styleFrom(
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      foregroundColor: Colors.white,
    );
    return _buildInstrumentPanelShell(
      context,
      fullScreen: true,
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
                label: Text(pickUiText(i18n, zh: '返回', en: 'Back')),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () => _openDrumSettingsSheet(context, i18n),
                style: overlayButtonStyle,
                icon: const Icon(Icons.tune_rounded),
                label: Text(pickUiText(i18n, zh: '设置', en: 'Settings')),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildWorkspaceContent(context, i18n),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    if (widget.fullScreen) {
      return _buildDrumFullScreen(context, i18n);
    }
    return _buildInstrumentPanelShell(
      context,
      fullScreen: false,
      child: _buildWorkspaceContent(context, i18n),
    );
  }
}

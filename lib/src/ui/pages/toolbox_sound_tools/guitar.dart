part of '../toolbox_sound_tools.dart';

class _GuitarTool extends StatefulWidget {
  const _GuitarTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_GuitarTool> createState() => _GuitarToolState();
}

class _GuitarChordVoicing {
  const _GuitarChordVoicing({
    required this.id,
    required this.label,
    required this.frets,
  });

  final String id;
  final String label;
  final List<int> frets;
}

class _GuitarToolState extends State<_GuitarTool> {
  static const List<_PianoKey> _strings = <_PianoKey>[
    _PianoKey(id: 'E2', label: 'E2', frequency: 82.41),
    _PianoKey(id: 'A2', label: 'A2', frequency: 110.0),
    _PianoKey(id: 'D3', label: 'D3', frequency: 146.83),
    _PianoKey(id: 'G3', label: 'G3', frequency: 196.0),
    _PianoKey(id: 'B3', label: 'B3', frequency: 246.94),
    _PianoKey(id: 'E4', label: 'E4', frequency: 329.63),
  ];
  static const List<int> _openMidis = <int>[40, 45, 50, 55, 59, 64];
  static const List<_GuitarPreset> _presets = <_GuitarPreset>[
    _GuitarPreset(
      id: 'steel_strum',
      styleId: 'steel',
      pluckVolume: 0.9,
      strumVolume: 0.84,
      strumDelayMs: 34,
      resonance: 0.56,
      pickPosition: 0.62,
    ),
    _GuitarPreset(
      id: 'nylon_finger',
      styleId: 'nylon',
      pluckVolume: 0.84,
      strumVolume: 0.78,
      strumDelayMs: 42,
      resonance: 0.66,
      pickPosition: 0.48,
    ),
    _GuitarPreset(
      id: 'ambient_chime',
      styleId: 'ambient',
      pluckVolume: 0.78,
      strumVolume: 0.72,
      strumDelayMs: 52,
      resonance: 0.82,
      pickPosition: 0.34,
    ),
  ];
  static const List<_GuitarChordVoicing> _chords = <_GuitarChordVoicing>[
    _GuitarChordVoicing(id: 'em', label: 'Em', frets: <int>[0, 2, 2, 0, 0, 0]),
    _GuitarChordVoicing(id: 'g', label: 'G', frets: <int>[3, 2, 0, 0, 0, 3]),
    _GuitarChordVoicing(id: 'c', label: 'C', frets: <int>[-1, 3, 2, 0, 1, 0]),
    _GuitarChordVoicing(id: 'd', label: 'D', frets: <int>[-1, -1, 0, 2, 3, 2]),
    _GuitarChordVoicing(id: 'am', label: 'Am', frets: <int>[-1, 0, 2, 2, 1, 0]),
    _GuitarChordVoicing(id: 'f', label: 'F', frets: <int>[1, 3, 3, 2, 1, 1]),
  ];

  final Map<String, ToolboxEffectPlayer> _players =
      <String, ToolboxEffectPlayer>{};
  final Map<int, int> _pointerStringIndexes = <int, int>{};

  String _presetId = _presets.first.id;
  String _chordId = _chords.first.id;
  int _capo = 0;
  int? _activeString;
  double _resonance = _presets.first.resonance;
  double _pickPosition = _presets.first.pickPosition;
  String? _lastPlayedLabel;
  int _strumCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_warmUpActivePreset());
    });
  }

  _GuitarPreset get _activePreset {
    return _presets.firstWhere(
      (item) => item.id == _presetId,
      orElse: () => _presets.first,
    );
  }

  _GuitarChordVoicing get _activeChord {
    return _chords.firstWhere(
      (item) => item.id == _chordId,
      orElse: () => _chords.first,
    );
  }

  bool _isCompactPhoneWidth(double width) =>
      width < (widget.fullScreen ? 480 : 430);

  String _presetLabel(AppI18n i18n, _GuitarPreset preset) {
    return switch (preset.id) {
      'nylon_finger' => pickUiText(i18n, zh: '尼龙指弹', en: 'Nylon finger'),
      'ambient_chime' => pickUiText(i18n, zh: '氛围泛音', en: 'Ambient chime'),
      _ => pickUiText(i18n, zh: '钢弦扫弦', en: 'Steel strum'),
    };
  }

  String _presetSubtitle(AppI18n i18n, _GuitarPreset preset) {
    return switch (preset.id) {
      'nylon_finger' => pickUiText(
        i18n,
        zh: '更圆润柔和，适合慢速分解和单音拨奏。',
        en: 'Rounder and softer for slow arpeggios and finger picking.',
      ),
      'ambient_chime' => pickUiText(
        i18n,
        zh: '更长泛音和尾韵，适合氛围铺底。',
        en: 'Longer shimmer and overtones for ambient layers.',
      ),
      _ => pickUiText(
        i18n,
        zh: '清晰有力的钢弦核心，适合节奏扫弦。',
        en: 'Clear steel-core tone tuned for rhythmic strumming.',
      ),
    };
  }

  int? _frettedMidiForString(int index) {
    final fret = _activeChord.frets[index];
    if (fret < 0) {
      return null;
    }
    return _openMidis[index] + fret + _capo;
  }

  double _frequencyFromMidi(int midi) {
    return (440 * math.pow(2, (midi - 69) / 12)).toDouble();
  }

  String _noteLabelFromMidi(int midi) {
    const pitchNames = <String>[
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
    final pitch = pitchNames[((midi % 12) + 12) % 12];
    final octave = (midi ~/ 12) - 1;
    return '$pitch$octave';
  }

  ToolboxEffectPlayer _playerForMidi(int midi) {
    final frequency = _frequencyFromMidi(midi);
    final key =
        '$midi:${_activePreset.styleId}:${_resonance.toStringAsFixed(2)}:${_pickPosition.toStringAsFixed(2)}';
    final existing = _players[key];
    if (existing != null) return existing;
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.guitarNote(
        frequency,
        style: _activePreset.styleId,
        resonance: _resonance,
        pickPosition: _pickPosition,
      ),
      maxPlayers: 8,
    );
    _players[key] = created;
    return created;
  }

  void _invalidatePlayers() {
    for (final player in _players.values) {
      unawaited(player.dispose());
    }
    _players.clear();
  }

  Future<void> _warmUpActivePreset() async {
    for (var index = 0; index < _strings.length; index += 1) {
      final midi = _frettedMidiForString(index);
      if (midi == null) {
        continue;
      }
      await _playerForMidi(midi).warmUp();
    }
  }

  void _applyPreset(String presetId) {
    if (_presetId == presetId) return;
    final preset = _presets.firstWhere(
      (item) => item.id == presetId,
      orElse: () => _presets.first,
    );
    setState(() {
      _presetId = preset.id;
      _resonance = preset.resonance;
      _pickPosition = preset.pickPosition;
    });
    _invalidatePlayers();
    unawaited(_warmUpActivePreset());
  }

  void _applyChord(String chordId) {
    if (_chordId == chordId) return;
    setState(() {
      _chordId = chordId;
    });
    _invalidatePlayers();
    unawaited(_warmUpActivePreset());
  }

  Future<void> _pluck(int index, {double? volume}) async {
    if (index < 0 || index >= _strings.length) return;
    final midi = _frettedMidiForString(index);
    if (midi == null) {
      HapticFeedback.lightImpact();
      return;
    }
    HapticFeedback.selectionClick();
    unawaited(
      _playerForMidi(midi).play(volume: volume ?? _activePreset.pluckVolume),
    );
    if (!mounted) return;
    setState(() {
      _activeString = index;
      _lastPlayedLabel = _noteLabelFromMidi(midi);
    });
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!mounted || _activeString != index) return;
      setState(() => _activeString = null);
    });
  }

  Future<void> _strum({required bool down}) async {
    final preset = _activePreset;
    final indexes = down
        ? List<int>.generate(_strings.length, (i) => i)
        : List<int>.generate(_strings.length, (i) => _strings.length - 1 - i);
    for (final index in indexes) {
      await _pluck(index, volume: preset.strumVolume);
      await Future<void>.delayed(Duration(milliseconds: preset.strumDelayMs));
    }
    if (!mounted) return;
    setState(() => _strumCount += 1);
  }

  void _handleStagePointerDown(PointerDownEvent event, Size size) {
    final index = _stringIndexForOffset(event.localPosition, size);
    if (index == null) return;
    _pointerStringIndexes[event.pointer] = index;
    unawaited(_pluck(index));
  }

  void _handleStagePointerMove(PointerMoveEvent event, Size size) {
    final index = _stringIndexForOffset(event.localPosition, size);
    if (index == null) return;
    final lastIndex = _pointerStringIndexes[event.pointer];
    if (lastIndex == index) return;
    _pointerStringIndexes[event.pointer] = index;
    unawaited(_pluck(index, volume: _activePreset.strumVolume));
  }

  void _handleStagePointerUp(PointerEvent event) {
    _pointerStringIndexes.remove(event.pointer);
  }

  int? _stringIndexForOffset(Offset position, Size size) {
    if (position.dx < 0 ||
        position.dy < 0 ||
        position.dx > size.width ||
        position.dy > size.height) {
      return null;
    }
    final laneHeight = size.height / _strings.length;
    return (position.dy / laneHeight).floor().clamp(0, _strings.length - 1);
  }

  Widget _buildStringStage(
    BuildContext context,
    AppI18n i18n,
    ThemeData theme, {
    required double width,
    required double height,
    required bool immersive,
  }) {
    final compact = _isCompactPhoneWidth(width);
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.fullScreen ? 24 : 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              immersive ? const Color(0xFF3B2A1C) : const Color(0xFFF8E6C4),
              immersive ? const Color(0xFF22160F) : const Color(0xFFE8C58E),
            ],
          ),
          border: Border.all(
            color: immersive
                ? Colors.white.withValues(alpha: 0.10)
                : const Color(0xFFB0854F),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: immersive ? 0.26 : 0.16),
              blurRadius: immersive ? 24 : 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stageWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : width;
            final stageSize = Size(stageWidth, height);
            return SizedBox(
              width: stageWidth,
              height: height,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) =>
                    _handleStagePointerDown(event, stageSize),
                onPointerMove: (event) =>
                    _handleStagePointerMove(event, stageSize),
                onPointerUp: _handleStagePointerUp,
                onPointerCancel: _handleStagePointerUp,
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: <Color>[
                              Colors.white.withValues(
                                alpha: immersive ? 0.04 : 0.18,
                              ),
                              Colors.transparent,
                              Colors.black.withValues(
                                alpha: immersive ? 0.14 : 0.10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ...List<Widget>.generate(_strings.length, (index) {
                      final active = _activeString == index;
                      final midi = _frettedMidiForString(index);
                      final label = midi == null
                          ? 'X'
                          : _noteLabelFromMidi(midi);
                      final fret = _activeChord.frets[index];
                      final top =
                          (height / _strings.length) * index +
                          (height / _strings.length) * 0.5;
                      final stringThickness = active
                          ? 4.0
                          : (2.2 + index * 0.16);
                      return Positioned(
                        left: compact ? 12 : 16,
                        right: compact ? 12 : 16,
                        top: top - 12,
                        child: SizedBox(
                          height: 24,
                          child: Row(
                            children: <Widget>[
                              SizedBox(
                                width: compact ? 34 : 44,
                                child: Text(
                                  label,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: immersive
                                        ? Colors.white
                                        : const Color(0xFF5A3818),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 90),
                                  height: stringThickness,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: <Color>[
                                        active
                                            ? const Color(0xFFFBBF24)
                                            : const Color(0xFFF7F1E5),
                                        active
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFF7C5A3A),
                                      ],
                                    ),
                                    boxShadow: active
                                        ? <BoxShadow>[
                                            BoxShadow(
                                              color: const Color(
                                                0xFFFBBF24,
                                              ).withValues(alpha: 0.34),
                                              blurRadius: 12,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : const <BoxShadow>[],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: compact ? 36 : 42,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: immersive
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.white.withValues(alpha: 0.62),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  fret < 0 ? 'Mute' : 'F$fret',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: immersive
                                        ? Colors.white70
                                        : const Color(0xFF5A3818),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    Positioned(
                      right: 14,
                      top: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                            alpha: immersive ? 0.30 : 0.18,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            pickUiText(
                              i18n,
                              zh: compact ? '滑扫' : '滑动扫弦',
                              en: compact ? 'Swipe' : 'Swipe to strum',
                            ),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChordSection(
    BuildContext context,
    AppI18n i18n, {
    VoidCallback? onSelectionChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: pickUiText(i18n, zh: '和弦与变调夹', en: 'Chord and capo'),
          subtitle: pickUiText(
            i18n,
            zh: '选定和弦后可直接点弦或滑扫，变调夹会整体抬高音高。',
            en: 'Pick a chord, pluck or sweep the strings, and move the capo to lift the voicing.',
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _chords
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(item.label),
                      selected: _chordId == item.id,
                      onSelected: (_) {
                        _applyChord(item.id);
                        onSelectionChanged?.call();
                      },
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List<Widget>.generate(6, (index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(index == 0 ? 'Capo 0' : 'Capo $index'),
                  selected: _capo == index,
                  onSelected: (_) {
                    if (_capo == index) return;
                    setState(() => _capo = index);
                    _invalidatePlayers();
                    unawaited(_warmUpActivePreset());
                    onSelectionChanged?.call();
                  },
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildGuitarSettingsContent(
    BuildContext context,
    AppI18n i18n, {
    required VoidCallback refreshSheet,
  }) {
    final theme = Theme.of(context);
    final preset = _activePreset;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          pickUiText(i18n, zh: '吉他设置', en: 'Guitar settings'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: 'Preset',
              value: _presetLabel(i18n, preset),
            ),
            ToolboxMetricCard(label: 'Chord', value: _activeChord.label),
            ToolboxMetricCard(label: 'Capo', value: '$_capo'),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presets
              .map(
                (item) => ChoiceChip(
                  label: Text(_presetLabel(i18n, item)),
                  selected: _presetId == item.id,
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
        const SizedBox(height: 18),
        _buildChordSection(context, i18n, onSelectionChanged: refreshSheet),
        const SizedBox(height: 18),
        Text(
          pickUiText(
            i18n,
            zh: '共鸣 ${(_resonance * 100).round()}%',
            en: 'Resonance ${(_resonance * 100).round()}%',
          ),
        ),
        Slider(
          value: _resonance,
          min: 0.1,
          max: 1.0,
          divisions: 18,
          onChanged: (value) {
            _resonance = value;
            refreshSheet();
          },
          onChangeEnd: (_) {
            if (mounted) {
              setState(() {});
            }
            _invalidatePlayers();
            unawaited(_warmUpActivePreset());
            refreshSheet();
          },
        ),
        Text(
          pickUiText(
            i18n,
            zh: '拨弦位置 ${(_pickPosition * 100).round()}%',
            en: 'Pick position ${(_pickPosition * 100).round()}%',
          ),
        ),
        Slider(
          value: _pickPosition,
          min: 0.1,
          max: 0.9,
          divisions: 16,
          onChanged: (value) {
            _pickPosition = value;
            refreshSheet();
          },
          onChangeEnd: (_) {
            if (mounted) {
              setState(() {});
            }
            _invalidatePlayers();
            unawaited(_warmUpActivePreset());
            refreshSheet();
          },
        ),
      ],
    );
  }

  Future<void> _openGuitarSettingsSheet(BuildContext context, AppI18n i18n) {
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
                child: _buildGuitarSettingsContent(
                  sheetContext,
                  i18n,
                  refreshSheet: () => setSheetState(() {}),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    AppI18n i18n, {
    required bool immersive,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        FilledButton.tonalIcon(
          onPressed: () => unawaited(_strum(down: true)),
          icon: const Icon(Icons.south_rounded),
          label: Text(pickUiText(i18n, zh: '下扫', en: 'Strum down')),
        ),
        FilledButton.tonalIcon(
          onPressed: () => unawaited(_strum(down: false)),
          icon: const Icon(Icons.north_rounded),
          label: Text(pickUiText(i18n, zh: '上扫', en: 'Strum up')),
        ),
        if (!immersive)
          OutlinedButton.icon(
            onPressed: () => _openGuitarSettingsSheet(context, i18n),
            icon: const Icon(Icons.tune_rounded),
            label: Text(pickUiText(i18n, zh: '设置', en: 'Settings')),
          ),
      ],
    );
  }

  Widget _buildFullScreen(BuildContext context, AppI18n i18n, ThemeData theme) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF120B07),
            Color(0xFF2B1C13),
            Color(0xFF09090B),
          ],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stageHeight = math.min(380.0, constraints.maxHeight - 210);
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 56, 16, bottomInset + 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            _PianoOverlayChip(
                              label: 'Chord',
                              value: _activeChord.label,
                            ),
                            _PianoOverlayChip(label: 'Capo', value: '$_capo'),
                            _PianoOverlayChip(
                              label: 'Preset',
                              value: _presetLabel(i18n, _activePreset),
                            ),
                            _PianoOverlayChip(
                              label: 'Last',
                              value: _lastPlayedLabel ?? '--',
                            ),
                          ],
                        ),
                        const Spacer(),
                        _buildStringStage(
                          context,
                          i18n,
                          theme,
                          width: constraints.maxWidth - 32,
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
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            _openGuitarSettingsSheet(context, i18n),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.34),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.tune_rounded),
                        label: Text(pickUiText(i18n, zh: '设置', en: 'Settings')),
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
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            pickUiText(
                              i18n,
                              zh: '纵向滑动可扫弦；点按单根琴弦可触发单音拨奏。',
                              en: 'Swipe vertically to strum; tap a string to pluck single notes.',
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildQuickActions(context, i18n, immersive: true),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    final theme = Theme.of(context);
    if (widget.fullScreen) {
      return _buildFullScreen(context, i18n, theme);
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
                  const ToolboxMetricCard(label: 'Strings', value: '6'),
                  ToolboxMetricCard(label: 'Chord', value: _activeChord.label),
                  ToolboxMetricCard(label: 'Capo', value: '$_capo'),
                  ToolboxMetricCard(
                    label: 'Last note',
                    value: _lastPlayedLabel ?? '--',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SectionHeader(
                title: pickUiText(i18n, zh: '吉他舞台', en: 'Guitar stage'),
                subtitle: pickUiText(
                  i18n,
                  zh: compact
                      ? '手机优先保留主扫弦区域，和弦与变调夹收进紧凑控制区。'
                      : '扫弦区域保持主视觉，和弦、变调夹与音色控制围绕其布局。',
                  en: compact
                      ? 'The phone layout keeps the strum surface primary and moves harmony controls into compact rows.'
                      : 'The strum surface stays primary while chords, capo, and tone controls sit around it.',
                ),
              ),
              const SizedBox(height: 10),
              _buildChordSection(context, i18n),
              const SizedBox(height: 12),
              _buildStringStage(
                context,
                i18n,
                theme,
                width: constraints.maxWidth,
                height: compact ? 240 : 280,
                immersive: false,
              ),
              const SizedBox(height: 12),
              _buildQuickActions(context, i18n, immersive: false),
              const SizedBox(height: 12),
              SectionHeader(
                title: pickUiText(i18n, zh: '音色塑形', en: 'Tone shaping'),
                subtitle: pickUiText(
                  i18n,
                  zh: '共鸣控制琴体响应，拨弦位置控制亮度与颗粒感。',
                  en: 'Resonance shapes body response and pick position shifts brightness.',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                pickUiText(
                  i18n,
                  zh: '共鸣 ${(_resonance * 100).round()}%',
                  en: 'Resonance ${(_resonance * 100).round()}%',
                ),
              ),
              Slider(
                value: _resonance,
                min: 0.1,
                max: 1.0,
                divisions: 18,
                onChanged: (value) => setState(() => _resonance = value),
                onChangeEnd: (_) {
                  _invalidatePlayers();
                  unawaited(_warmUpActivePreset());
                },
              ),
              Text(
                pickUiText(
                  i18n,
                  zh: '拨弦位置 ${(_pickPosition * 100).round()}%',
                  en: 'Pick position ${(_pickPosition * 100).round()}%',
                ),
              ),
              Slider(
                value: _pickPosition,
                min: 0.1,
                max: 0.9,
                divisions: 16,
                onChanged: (value) => setState(() => _pickPosition = value),
                onChangeEnd: (_) {
                  _invalidatePlayers();
                  unawaited(_warmUpActivePreset());
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

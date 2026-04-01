part of '../toolbox_sound_tools.dart';

class _HarpConfig {
  const _HarpConfig({
    this.scaleId = 'c_major',
    this.chordId = 'major',
    this.pluckStyleId = 'silk',
    this.patternId = 'glide',
    this.paletteId = 'ivory_wood',
    this.chordRootIndex = 0,
    this.chordResonanceEnabled = false,
    this.reverb = 0.24,
    this.damping = 10,
    this.swipeThreshold = 1.2,
    this.activeRealismPresetId,
  });

  final String scaleId;
  final String chordId;
  final String pluckStyleId;
  final String patternId;
  final String paletteId;
  final int chordRootIndex;
  final bool chordResonanceEnabled;
  final double reverb;
  final double damping;
  final double swipeThreshold;
  final String? activeRealismPresetId;

  _HarpConfig copyWith({
    String? scaleId,
    String? chordId,
    String? pluckStyleId,
    String? patternId,
    String? paletteId,
    int? chordRootIndex,
    bool? chordResonanceEnabled,
    double? reverb,
    double? damping,
    double? swipeThreshold,
    String? activeRealismPresetId,
  }) {
    return _HarpConfig(
      scaleId: scaleId ?? this.scaleId,
      chordId: chordId ?? this.chordId,
      pluckStyleId: pluckStyleId ?? this.pluckStyleId,
      patternId: patternId ?? this.patternId,
      paletteId: paletteId ?? this.paletteId,
      chordRootIndex: chordRootIndex ?? this.chordRootIndex,
      chordResonanceEnabled:
          chordResonanceEnabled ?? this.chordResonanceEnabled,
      reverb: reverb ?? this.reverb,
      damping: damping ?? this.damping,
      swipeThreshold: swipeThreshold ?? this.swipeThreshold,
      activeRealismPresetId:
          activeRealismPresetId ?? this.activeRealismPresetId,
    );
  }
}

class _HarpTool extends StatefulWidget {
  const _HarpTool({
    this.fullScreen = false,
    this.onExitFullScreen,
    this.initialConfig,
    this.onConfigChanged,
  });

  final bool fullScreen;
  final VoidCallback? onExitFullScreen;
  final _HarpConfig? initialConfig;
  final void Function(_HarpConfig config)? onConfigChanged;

  @override
  State<_HarpTool> createState() => _HarpToolState();
}

class _HarpScalePreset {
  const _HarpScalePreset({
    required this.id,
    required this.label,
    required this.notes,
  });

  final String id;
  final String label;
  final List<double> notes;
}

class _HarpChordPreset {
  const _HarpChordPreset({
    required this.id,
    required this.label,
    required this.intervals,
  });

  final String id;
  final String label;
  final List<int> intervals;
}

class _HarpPalettePreset {
  const _HarpPalettePreset({
    required this.id,
    required this.label,
    required this.colors,
  });

  final String id;
  final String label;
  final List<Color> colors;
}

class _HarpPluckPreset {
  const _HarpPluckPreset({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;
}

class _HarpPatternPreset {
  const _HarpPatternPreset({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;
}

class _HarpRealismPreset {
  const _HarpRealismPreset({
    required this.id,
    required this.label,
    required this.description,
    required this.scaleId,
    required this.chordId,
    required this.pluckStyleId,
    required this.patternId,
    required this.paletteId,
    required this.reverb,
    required this.damping,
    required this.swipeThreshold,
    required this.chordResonanceEnabled,
  });

  final String id;
  final String label;
  final String description;
  final String scaleId;
  final String chordId;
  final String pluckStyleId;
  final String patternId;
  final String paletteId;
  final double reverb;
  final double damping;
  final double swipeThreshold;
  final bool chordResonanceEnabled;
}

class _HarpToolState extends State<_HarpTool>
    with SingleTickerProviderStateMixin {
  static const int _stringCount = 12;
  static const double _springStiffness = 34;
  static const List<_HarpScalePreset> _scalePresets = <_HarpScalePreset>[
    _HarpScalePreset(
      id: 'c_major',
      label: 'C Major',
      notes: <double>[
        130.81,
        146.83,
        164.81,
        196.0,
        220.0,
        261.63,
        293.66,
        329.63,
        392.0,
        440.0,
        523.25,
        587.33,
      ],
    ),
    _HarpScalePreset(
      id: 'a_minor',
      label: 'A Minor',
      notes: <double>[
        110.0,
        130.81,
        146.83,
        164.81,
        196.0,
        220.0,
        261.63,
        293.66,
        329.63,
        392.0,
        440.0,
        523.25,
      ],
    ),
    _HarpScalePreset(
      id: 'd_dorian',
      label: 'D Dorian',
      notes: <double>[
        146.83,
        164.81,
        174.61,
        196.0,
        220.0,
        261.63,
        293.66,
        329.63,
        349.23,
        392.0,
        440.0,
        523.25,
      ],
    ),
    _HarpScalePreset(
      id: 'zen',
      label: 'Zen Pentatonic',
      notes: <double>[
        130.81,
        138.59,
        155.56,
        196.0,
        207.65,
        261.63,
        277.18,
        311.13,
        392.0,
        415.3,
        523.25,
        554.37,
      ],
    ),
    _HarpScalePreset(
      id: 'c_lydian',
      label: 'C Lydian',
      notes: <double>[
        130.81,
        146.83,
        164.81,
        185.0,
        196.0,
        220.0,
        246.94,
        261.63,
        293.66,
        329.63,
        369.99,
        392.0,
      ],
    ),
    _HarpScalePreset(
      id: 'hirajoshi',
      label: 'Hirajoshi',
      notes: <double>[
        130.81,
        138.59,
        174.61,
        196.0,
        233.08,
        261.63,
        277.18,
        349.23,
        392.0,
        466.16,
        523.25,
        554.37,
      ],
    ),
  ];
  static const List<_HarpChordPreset> _chordPresets = <_HarpChordPreset>[
    _HarpChordPreset(
      id: 'major',
      label: 'Major',
      intervals: <int>[0, 4, 7, 12],
    ),
    _HarpChordPreset(
      id: 'minor',
      label: 'Minor',
      intervals: <int>[0, 3, 7, 12],
    ),
    _HarpChordPreset(id: 'sus2', label: 'Sus2', intervals: <int>[0, 2, 7, 12]),
    _HarpChordPreset(id: 'add9', label: 'Add9', intervals: <int>[0, 4, 7, 14]),
    _HarpChordPreset(id: 'sus4', label: 'Sus4', intervals: <int>[0, 5, 7, 12]),
    _HarpChordPreset(id: 'maj7', label: 'Maj7', intervals: <int>[0, 4, 7, 11]),
    _HarpChordPreset(id: 'min7', label: 'Min7', intervals: <int>[0, 3, 7, 10]),
  ];
  static const List<_HarpPluckPreset> _pluckPresets = <_HarpPluckPreset>[
    _HarpPluckPreset(
      id: 'silk',
      label: 'Silk',
      description: 'Balanced and soft.',
    ),
    _HarpPluckPreset(
      id: 'warm',
      label: 'Warm',
      description: 'More body and slower tail.',
    ),
    _HarpPluckPreset(
      id: 'crystal',
      label: 'Crystal',
      description: 'Sharper upper harmonics.',
    ),
    _HarpPluckPreset(
      id: 'bright',
      label: 'Bright',
      description: 'Clear attack for active strum.',
    ),
    _HarpPluckPreset(
      id: 'nylon',
      label: 'Nylon',
      description: 'Round body with light transient.',
    ),
    _HarpPluckPreset(
      id: 'glass',
      label: 'Glass',
      description: 'Thin body and sparkling top.',
    ),
    _HarpPluckPreset(
      id: 'concert',
      label: 'Concert',
      description: 'Pedal-harp like balance and sustain.',
    ),
    _HarpPluckPreset(
      id: 'steel',
      label: 'Steel',
      description: 'Stronger core and brighter attack.',
    ),
  ];
  static const List<_HarpPatternPreset> _patternPresets = <_HarpPatternPreset>[
    _HarpPatternPreset(
      id: 'glide',
      label: 'Glide',
      description: 'Ascending sweep.',
    ),
    _HarpPatternPreset(
      id: 'cascade',
      label: 'Cascade',
      description: 'Up then down.',
    ),
    _HarpPatternPreset(
      id: 'chord',
      label: 'Chord',
      description: 'Pulse active chord tones.',
    ),
  ];
  static const List<_HarpPalettePreset> _palettePresets = <_HarpPalettePreset>[
    _HarpPalettePreset(
      id: 'ivory_wood',
      label: 'Ivory Wood',
      colors: <Color>[Color(0xFFF6F0E2), Color(0xFFD8C1A0), Color(0xFFB48857)],
    ),
    _HarpPalettePreset(
      id: 'moon',
      label: 'Moon',
      colors: <Color>[Color(0xFF8B5CF6), Color(0xFF60A5FA), Color(0xFF22D3EE)],
    ),
    _HarpPalettePreset(
      id: 'aurora',
      label: 'Aurora',
      colors: <Color>[Color(0xFF0EA5E9), Color(0xFF22C55E), Color(0xFFFDE047)],
    ),
    _HarpPalettePreset(
      id: 'ember',
      label: 'Ember',
      colors: <Color>[Color(0xFFFB7185), Color(0xFFFB923C), Color(0xFFFACC15)],
    ),
    _HarpPalettePreset(
      id: 'jade',
      label: 'Jade',
      colors: <Color>[Color(0xFF10B981), Color(0xFF2DD4BF), Color(0xFF7DD3FC)],
    ),
  ];
  static const List<_HarpRealismPreset> _realismPresets = <_HarpRealismPreset>[
    _HarpRealismPreset(
      id: 'concert_nylon',
      label: 'Concert Nylon',
      description: 'Round body with controlled hall tail.',
      scaleId: 'c_major',
      chordId: 'major',
      pluckStyleId: 'nylon',
      patternId: 'glide',
      paletteId: 'ivory_wood',
      reverb: 0.18,
      damping: 10.8,
      swipeThreshold: 1.0,
      chordResonanceEnabled: true,
    ),
    _HarpRealismPreset(
      id: 'pedal_harp',
      label: 'Pedal Harp',
      description: 'Balanced sustain for melodic passages.',
      scaleId: 'c_lydian',
      chordId: 'maj7',
      pluckStyleId: 'concert',
      patternId: 'cascade',
      paletteId: 'moon',
      reverb: 0.22,
      damping: 10.0,
      swipeThreshold: 1.1,
      chordResonanceEnabled: true,
    ),
    _HarpRealismPreset(
      id: 'steel_studio',
      label: 'Steel Studio',
      description: 'Tight transient and clear note separation.',
      scaleId: 'd_dorian',
      chordId: 'sus2',
      pluckStyleId: 'steel',
      patternId: 'glide',
      paletteId: 'aurora',
      reverb: 0.16,
      damping: 12.8,
      swipeThreshold: 0.9,
      chordResonanceEnabled: false,
    ),
    _HarpRealismPreset(
      id: 'chamber_soft',
      label: 'Chamber Soft',
      description: 'Soft finger-pluck with gentle bloom.',
      scaleId: 'a_minor',
      chordId: 'minor',
      pluckStyleId: 'warm',
      patternId: 'chord',
      paletteId: 'ember',
      reverb: 0.28,
      damping: 9.2,
      swipeThreshold: 1.3,
      chordResonanceEnabled: true,
    ),
  ];

  final Map<String, ToolboxEffectPlayer> _playersByKey =
      <String, ToolboxEffectPlayer>{};
  final List<double> _stringOffsets = List<double>.filled(_stringCount, 0);
  final List<double> _stringVelocities = List<double>.filled(_stringCount, 0);
  final List<int> _lastPluckAtMillis = List<int>.filled(_stringCount, 0);
  final Map<int, _HarpPointerState> _pointerStates = <int, _HarpPointerState>{};
  late final Ticker _vibrationTicker;

  int? _focusedString;
  int? _lastTickMicros;
  bool _muted = false;
  late String _scaleId;
  late String _chordId;
  late String _pluckStyleId;
  late String _patternId;
  late String _paletteId;
  late int _chordRootIndex;
  late bool _chordResonanceEnabled;
  late double _reverbUi;
  late double _reverbForAudio;
  late double _damping;
  late double _swipeThreshold;
  String? _activeRealismPresetId;

  @override
  void initState() {
    super.initState();
    final config = widget.initialConfig;
    if (config != null) {
      _scaleId = config.scaleId;
      _chordId = config.chordId;
      _pluckStyleId = config.pluckStyleId;
      _patternId = config.patternId;
      _paletteId = config.paletteId;
      _chordRootIndex = config.chordRootIndex;
      _chordResonanceEnabled = config.chordResonanceEnabled;
      _reverbUi = config.reverb;
      _reverbForAudio = config.reverb;
      _damping = config.damping;
      _swipeThreshold = config.swipeThreshold;
      _activeRealismPresetId = config.activeRealismPresetId;
    } else {
      _scaleId = _scalePresets.first.id;
      _chordId = _chordPresets.first.id;
      _pluckStyleId = _pluckPresets.first.id;
      _patternId = _patternPresets.first.id;
      _paletteId = _palettePresets.first.id;
      _chordRootIndex = 0;
      _chordResonanceEnabled = false;
      _reverbUi = 0.24;
      _reverbForAudio = 0.24;
      _damping = 10;
      _swipeThreshold = 1.2;
      _activeRealismPresetId = null;
      _applyRealismPreset(_realismPresets.first, withSetState: false);
    }
    _vibrationTicker = createTicker(_tickStrings);
    if (widget.fullScreen) {
      unawaited(_enterImmersiveMode());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_warmUpActiveTone());
    });
  }

  void _notifyConfigChanged() {
    widget.onConfigChanged?.call(
      _HarpConfig(
        scaleId: _scaleId,
        chordId: _chordId,
        pluckStyleId: _pluckStyleId,
        patternId: _patternId,
        paletteId: _paletteId,
        chordRootIndex: _chordRootIndex,
        chordResonanceEnabled: _chordResonanceEnabled,
        reverb: _reverbUi,
        damping: _damping,
        swipeThreshold: _swipeThreshold,
        activeRealismPresetId: _activeRealismPresetId,
      ),
    );
  }

  _HarpScalePreset get _activeScale =>
      _scalePresets.firstWhere((preset) => preset.id == _scaleId);

  _HarpChordPreset get _activeChord =>
      _chordPresets.firstWhere((preset) => preset.id == _chordId);

  _HarpPalettePreset get _activePalette =>
      _palettePresets.firstWhere((preset) => preset.id == _paletteId);

  List<double> get _activeNotes => _activeScale.notes;

  bool get _isHorizontalLayout => true;

  String _scaleLabel(AppI18n i18n, _HarpScalePreset preset) {
    return switch (preset.id) {
      'a_minor' => pickUiText(i18n, zh: 'A小调', en: 'A Minor'),
      'd_dorian' => pickUiText(i18n, zh: 'D多利亚', en: 'D Dorian'),
      'zen' => pickUiText(i18n, zh: '禅意五声音阶', en: 'Zen Pentatonic'),
      'c_lydian' => pickUiText(i18n, zh: 'C利底亚', en: 'C Lydian'),
      'hirajoshi' => pickUiText(i18n, zh: '平调子', en: 'Hirajoshi'),
      _ => pickUiText(i18n, zh: 'C大调', en: 'C Major'),
    };
  }

  String _chordLabel(AppI18n i18n, _HarpChordPreset preset) {
    return switch (preset.id) {
      'minor' => pickUiText(i18n, zh: '小三和弦', en: 'Minor'),
      'sus2' => pickUiText(i18n, zh: '挂二', en: 'Sus2'),
      'add9' => pickUiText(i18n, zh: '加九', en: 'Add9'),
      'sus4' => pickUiText(i18n, zh: '挂四', en: 'Sus4'),
      'maj7' => pickUiText(i18n, zh: '大七', en: 'Maj7'),
      'min7' => pickUiText(i18n, zh: '小七', en: 'Min7'),
      _ => pickUiText(i18n, zh: '大三和弦', en: 'Major'),
    };
  }

  String _pluckLabel(AppI18n i18n, _HarpPluckPreset preset) {
    return switch (preset.id) {
      'warm' => pickUiText(i18n, zh: '温暖', en: 'Warm'),
      'crystal' => pickUiText(i18n, zh: '水晶', en: 'Crystal'),
      'bright' => pickUiText(i18n, zh: '明亮', en: 'Bright'),
      'nylon' => pickUiText(i18n, zh: '尼龙', en: 'Nylon'),
      'glass' => pickUiText(i18n, zh: '玻璃', en: 'Glass'),
      'concert' => pickUiText(i18n, zh: '音乐厅', en: 'Concert'),
      'steel' => pickUiText(i18n, zh: '钢弦', en: 'Steel'),
      _ => pickUiText(i18n, zh: '丝绸', en: 'Silk'),
    };
  }

  String _pluckDescription(AppI18n i18n, _HarpPluckPreset preset) {
    return switch (preset.id) {
      'warm' => pickUiText(
        i18n,
        zh: '更厚实、尾音更慢。',
        en: 'More body and slower tail.',
      ),
      'crystal' => pickUiText(
        i18n,
        zh: '高频更亮，颗粒更清晰。',
        en: 'Sharper upper harmonics.',
      ),
      'bright' => pickUiText(
        i18n,
        zh: '起音更清楚，适合扫弦。',
        en: 'Clear attack for active strum.',
      ),
      'nylon' => pickUiText(
        i18n,
        zh: '圆润柔和，瞬态较轻。',
        en: 'Round body with light transient.',
      ),
      'glass' => pickUiText(
        i18n,
        zh: '更薄更亮，泛音闪烁。',
        en: 'Thin body and sparkling top.',
      ),
      'concert' => pickUiText(
        i18n,
        zh: '接近踏板竖琴的均衡延音。',
        en: 'Pedal-harp like balance and sustain.',
      ),
      'steel' => pickUiText(
        i18n,
        zh: '核心更强，拨弦更亮。',
        en: 'Stronger core and brighter attack.',
      ),
      _ => pickUiText(i18n, zh: '平衡柔和。', en: 'Balanced and soft.'),
    };
  }

  String _patternLabel(AppI18n i18n, _HarpPatternPreset preset) {
    return switch (preset.id) {
      'cascade' => pickUiText(i18n, zh: '瀑布', en: 'Cascade'),
      'chord' => pickUiText(i18n, zh: '和弦脉冲', en: 'Chord'),
      _ => pickUiText(i18n, zh: '滑行', en: 'Glide'),
    };
  }

  String _patternDescription(AppI18n i18n, _HarpPatternPreset preset) {
    return switch (preset.id) {
      'cascade' => pickUiText(i18n, zh: '先上行再下行。', en: 'Up then down.'),
      'chord' => pickUiText(
        i18n,
        zh: '脉冲弹奏当前和弦音。',
        en: 'Pulse active chord tones.',
      ),
      _ => pickUiText(i18n, zh: '连续上行扫弦。', en: 'Ascending sweep.'),
    };
  }

  String _paletteLabel(AppI18n i18n, _HarpPalettePreset preset) {
    return switch (preset.id) {
      'ivory_wood' => pickUiText(i18n, zh: '象牙木质', en: 'Ivory Wood'),
      'aurora' => pickUiText(i18n, zh: '极光', en: 'Aurora'),
      'ember' => pickUiText(i18n, zh: '余烬', en: 'Ember'),
      'jade' => pickUiText(i18n, zh: '翡翠', en: 'Jade'),
      _ => pickUiText(i18n, zh: '月光', en: 'Moon'),
    };
  }

  String _realismLabel(AppI18n i18n, _HarpRealismPreset preset) {
    return switch (preset.id) {
      'pedal_harp' => pickUiText(i18n, zh: '踏板竖琴', en: 'Pedal Harp'),
      'steel_studio' => pickUiText(i18n, zh: '钢弦录音棚', en: 'Steel Studio'),
      'chamber_soft' => pickUiText(i18n, zh: '室内柔和', en: 'Chamber Soft'),
      _ => pickUiText(i18n, zh: '音乐会尼龙', en: 'Concert Nylon'),
    };
  }

  String _realismDescription(AppI18n i18n, _HarpRealismPreset preset) {
    return switch (preset.id) {
      'pedal_harp' => pickUiText(
        i18n,
        zh: '适合旋律线条的平衡延音。',
        en: 'Balanced sustain for melodic passages.',
      ),
      'steel_studio' => pickUiText(
        i18n,
        zh: '瞬态紧致，音符分离清晰。',
        en: 'Tight transient and clear note separation.',
      ),
      'chamber_soft' => pickUiText(
        i18n,
        zh: '柔和拨弦，余韵舒展。',
        en: 'Soft finger-pluck with gentle bloom.',
      ),
      _ => pickUiText(
        i18n,
        zh: '圆润琴体与受控厅堂尾音。',
        en: 'Round body with controlled hall tail.',
      ),
    };
  }

  Future<void> _enterImmersiveMode() async {
    await _enterToolboxPortraitMode();
  }

  Future<void> _exitImmersiveMode() async {
    await _exitToolboxLandscapeMode();
  }

  void _markRealismCustom() {
    _activeRealismPresetId = null;
  }

  void _applyRealismPreset(
    _HarpRealismPreset preset, {
    bool withSetState = true,
  }) {
    void applyValues() {
      _scaleId = preset.scaleId;
      _chordId = preset.chordId;
      _pluckStyleId = preset.pluckStyleId;
      _patternId = preset.patternId;
      _paletteId = preset.paletteId;
      _reverbUi = preset.reverb;
      _reverbForAudio = preset.reverb;
      _damping = preset.damping;
      _swipeThreshold = preset.swipeThreshold;
      _chordResonanceEnabled = preset.chordResonanceEnabled;
      _activeRealismPresetId = preset.id;
    }

    if (withSetState && mounted) {
      setState(applyValues);
    } else {
      applyValues();
    }
    _invalidateAudioPlayers();
    _notifyConfigChanged();
  }

  void _invalidateAudioPlayers({bool warmUp = true}) {
    for (final player in _playersByKey.values) {
      unawaited(player.dispose());
    }
    _playersByKey.clear();
    if (warmUp) {
      unawaited(_warmUpActiveTone());
    }
  }

  Future<void> _warmUpActiveTone() async {
    for (final frequency in _activeNotes) {
      await _playerForFrequency(frequency).warmUp();
    }
  }

  ToolboxEffectPlayer _playerForFrequency(double frequency) {
    final key =
        '${frequency.toStringAsFixed(2)}|$_pluckStyleId|${_reverbForAudio.toStringAsFixed(2)}';
    final existing = _playersByKey[key];
    if (existing != null) return existing;
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.harpNote(
        frequency,
        style: _pluckStyleId,
        reverb: _reverbForAudio,
      ),
      maxPlayers: 8,
    );
    _playersByKey[key] = created;
    return created;
  }

  double _stringTrackAt(
    int index,
    Size size, {
    required bool horizontalLayout,
  }) {
    final totalSpan = horizontalLayout ? size.height : size.width;
    final adaptiveInset = totalSpan * (horizontalLayout ? 0.07 : 0.16);
    final minInset = horizontalLayout ? 18.0 : 34.0;
    final leadingInset = math.max(minInset, adaptiveInset);
    final trailingInset = math.max(minInset, adaptiveInset);
    final usableSpan = math.max(1.0, totalSpan - leadingInset - trailingInset);
    if (_stringCount == 1) {
      return horizontalLayout ? size.height / 2 : size.width / 2;
    }
    return leadingInset + usableSpan * (index / (_stringCount - 1));
  }

  int _nearestStringByPosition(
    Offset point,
    Size size, {
    required bool horizontalLayout,
  }) {
    final axisValue = horizontalLayout ? point.dy : point.dx;
    var bestIndex = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < _stringCount; i += 1) {
      final distance =
          (_stringTrackAt(i, size, horizontalLayout: horizontalLayout) -
                  axisValue)
              .abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  List<int> _crossedStrings(
    Offset previous,
    Offset current,
    Size size, {
    required bool horizontalLayout,
  }) {
    final startIndex = _nearestStringByPosition(
      previous,
      size,
      horizontalLayout: horizontalLayout,
    );
    final endIndex = _nearestStringByPosition(
      current,
      size,
      horizontalLayout: horizontalLayout,
    );
    if (startIndex == endIndex) {
      return const <int>[];
    }
    final step = endIndex > startIndex ? 1 : -1;
    final indexes = <int>[];
    for (var i = startIndex + step; i != endIndex + step; i += step) {
      indexes.add(i);
    }
    return indexes;
  }

  double _swipeIntensity(Offset delta) {
    final effectiveDistance = math.max(0.0, delta.distance - _swipeThreshold);
    return (effectiveDistance / 52).clamp(0.18, 1.0).toDouble();
  }

  double _swipeDirection(Offset delta, {required bool horizontalLayout}) {
    final axisDelta = horizontalLayout ? delta.dy : delta.dx;
    return axisDelta >= 0 ? 1.0 : -1.0;
  }

  void _startVibrationTicker() {
    if (_vibrationTicker.isActive) return;
    _lastTickMicros = null;
    _vibrationTicker.start();
  }

  void _tickStrings(Duration elapsed) {
    final currentMicros = elapsed.inMicroseconds;
    final previousMicros = _lastTickMicros;
    _lastTickMicros = currentMicros;
    if (previousMicros == null) return;

    var deltaSeconds =
        (currentMicros - previousMicros) / Duration.microsecondsPerSecond;
    if (deltaSeconds <= 0 || deltaSeconds > 0.08) {
      deltaSeconds = 1 / 60;
    }

    var hasMotion = false;
    for (var i = 0; i < _stringOffsets.length; i += 1) {
      final offset = _stringOffsets[i];
      final velocity = _stringVelocities[i];
      final acceleration = (-_springStiffness * offset) - (_damping * velocity);
      final nextVelocity = velocity + acceleration * deltaSeconds;
      final nextOffset = offset + nextVelocity * deltaSeconds;

      if (nextOffset.abs() < 0.02 && nextVelocity.abs() < 0.02) {
        _stringOffsets[i] = 0;
        _stringVelocities[i] = 0;
        continue;
      }

      _stringOffsets[i] = nextOffset;
      _stringVelocities[i] = nextVelocity;
      hasMotion = true;
    }

    if (!hasMotion) {
      _vibrationTicker.stop();
      _lastTickMicros = null;
      if (_focusedString != null && mounted) {
        setState(() {
          _focusedString = null;
        });
      }
      return;
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _pluckString(
    int index, {
    required double intensity,
    required double direction,
    bool force = false,
    double? frequencyOverride,
    bool applyChordResonance = true,
  }) {
    if (index < 0 || index >= _stringCount) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force && now - _lastPluckAtMillis[index] < 28) return;
    _lastPluckAtMillis[index] = now;

    final frequency = frequencyOverride ?? _activeNotes[index];
    final clampedIntensity = intensity.clamp(0.18, 1.0).toDouble();
    if (!_muted) {
      final volume = (0.22 + clampedIntensity * 0.78).clamp(0.0, 1.0);
      unawaited(_playerForFrequency(frequency).play(volume: volume.toDouble()));
    }

    _stringOffsets[index] += direction * (1.8 + clampedIntensity * 2.4);
    _stringVelocities[index] += direction * (42 + clampedIntensity * 68);
    if (applyChordResonance && _chordResonanceEnabled) {
      _triggerChordResonance(
        sourceIndex: index,
        baseFrequency: frequency,
        intensity: clampedIntensity,
        direction: direction,
      );
    }
    _startVibrationTicker();
    if (mounted) {
      setState(() {
        _focusedString = index;
      });
    }
  }

  void _handleTap(Offset localPosition, Size size) {
    final index = _nearestStringByPosition(
      localPosition,
      size,
      horizontalLayout: _isHorizontalLayout,
    );
    final axis = _isHorizontalLayout ? localPosition.dy : localPosition.dx;
    final span = _isHorizontalLayout ? size.height : size.width;
    final spacing = _stringCount <= 1 ? span : span / (_stringCount - 1);
    final distance =
        (_stringTrackAt(index, size, horizontalLayout: _isHorizontalLayout) -
                axis)
            .abs();
    if (distance > spacing * 0.45) return;
    final stringTrack = _stringTrackAt(
      index,
      size,
      horizontalLayout: _isHorizontalLayout,
    );
    final proximity = (1 - distance / (spacing * 0.45)).clamp(0.0, 1.0);
    _pluckString(
      index,
      intensity: (0.34 + proximity * 0.34).clamp(0.32, 0.78).toDouble(),
      direction: axis >= stringTrack ? 1 : -1,
      force: true,
      applyChordResonance: false,
    );
  }

  void _handlePanStart(
    _HarpPointerState pointerState,
    Offset localPosition,
    Size size,
  ) {
    pointerState.lastDragPoint = localPosition;
    final startIndex = _nearestStringByPosition(
      localPosition,
      size,
      horizontalLayout: _isHorizontalLayout,
    );
    final startAxis = _isHorizontalLayout ? localPosition.dy : localPosition.dx;
    final startTrack = _stringTrackAt(
      startIndex,
      size,
      horizontalLayout: _isHorizontalLayout,
    );
    pointerState.lastDragStringIndex = startIndex;
    _pluckString(
      startIndex,
      intensity: 0.36,
      direction: startAxis >= startTrack ? 1 : -1,
      force: true,
      applyChordResonance: false,
    );
  }

  void _handlePanUpdate(
    _HarpPointerState pointerState,
    Offset localPosition,
    Size size,
  ) {
    final current = localPosition;
    final previous = pointerState.lastDragPoint;
    pointerState.lastDragPoint = current;
    if (previous == null) return;

    final delta = current - previous;
    if (delta.distance <= _swipeThreshold) return;

    final intensity = _swipeIntensity(delta);
    final direction = _swipeDirection(
      delta,
      horizontalLayout: _isHorizontalLayout,
    );
    final crossed = _crossedStrings(
      previous,
      current,
      size,
      horizontalLayout: _isHorizontalLayout,
    );
    if (crossed.isEmpty) {
      final nearest = _nearestStringByPosition(
        current,
        size,
        horizontalLayout: _isHorizontalLayout,
      );
      if (nearest == pointerState.lastDragStringIndex) return;
      pointerState.lastDragStringIndex = nearest;
      _pluckString(
        nearest,
        intensity: intensity,
        direction: direction,
        applyChordResonance: false,
      );
      return;
    }
    for (final index in crossed) {
      if (index == pointerState.lastDragStringIndex) continue;
      pointerState.lastDragStringIndex = index;
      _pluckString(
        index,
        intensity: intensity,
        direction: direction,
        applyChordResonance: false,
      );
    }
  }

  void _handlePanEnd(_HarpPointerState pointerState) {
    pointerState.lastDragPoint = null;
    pointerState.lastDragStringIndex = null;
  }

  bool _shouldEnterSweepMode(Offset delta) {
    final primaryDelta = (_isHorizontalLayout ? delta.dy : delta.dx).abs();
    final crossDelta = (_isHorizontalLayout ? delta.dx : delta.dy).abs();
    if (primaryDelta < _swipeThreshold) return false;
    return primaryDelta >= crossDelta * 1.2;
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointerStates[event.pointer] = _HarpPointerState(
      downPosition: event.localPosition,
    );
  }

  void _handlePointerMove(PointerMoveEvent event, Size size) {
    final pointerState = _pointerStates[event.pointer];
    if (pointerState == null) return;
    final start = pointerState.downPosition;
    final current = event.localPosition;
    if (!pointerState.dragActive) {
      final delta = current - start;
      if (!_shouldEnterSweepMode(delta)) return;
      pointerState.dragActive = true;
      _handlePanStart(pointerState, start, size);
    }
    _handlePanUpdate(pointerState, current, size);
  }

  void _handlePointerUp(PointerUpEvent event, Size size) {
    final pointerState = _pointerStates.remove(event.pointer);
    if (pointerState == null) return;
    if (pointerState.dragActive) {
      _handlePanEnd(pointerState);
    } else {
      _handleTap(event.localPosition, size);
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    final pointerState = _pointerStates.remove(event.pointer);
    if (pointerState == null) return;
    _handlePanEnd(pointerState);
  }

  int _nearestStringByFrequency(double frequency) {
    var bestIndex = 0;
    var bestDistance = double.infinity;
    final notes = _activeNotes;
    for (var i = 0; i < notes.length; i += 1) {
      final distance = (notes[i] - frequency).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  List<double> _activeChordFrequencies() {
    final root = _activeNotes[_chordRootIndex.clamp(0, _stringCount - 1)];
    return _activeChord.intervals
        .map((step) => root * math.pow(2.0, step / 12.0).toDouble())
        .toList(growable: false);
  }

  void _triggerChordResonance({
    required int sourceIndex,
    required double baseFrequency,
    required double intensity,
    required double direction,
  }) {
    // Only on strong strums; avoid accidental multi-trigger on regular taps.
    if (intensity < 0.72) return;
    final resonanceIntervals = _activeChord.intervals.where((step) => step > 0);
    var slot = 0;
    for (final step in resonanceIntervals) {
      if (slot >= 1) break;
      final frequency = baseFrequency * math.pow(2.0, step / 12.0).toDouble();
      final index = _nearestStringByFrequency(frequency);
      if (index == sourceIndex) continue;
      final strength = (0.035 + intensity * 0.08) / (slot + 1);
      if (!_muted) {
        unawaited(
          _playerForFrequency(
            frequency,
          ).play(volume: strength.clamp(0.02, 0.12).toDouble()),
        );
      }
      _stringOffsets[index] += direction * (0.16 + strength * 0.8);
      _stringVelocities[index] += direction * (3 + strength * 12);
      slot += 1;
    }
  }

  Future<void> _playArpeggio() async {
    if (_patternId == 'chord') {
      final chordNotes = _activeChordFrequencies();
      final extended = <double>[...chordNotes, chordNotes.first * 2];
      for (var pass = 0; pass < 2; pass += 1) {
        final forward = pass == 0;
        final sequence = forward
            ? extended
            : extended.reversed.toList(growable: false);
        for (var i = 0; i < sequence.length; i += 1) {
          final frequency = sequence[i];
          final visualIndex = _nearestStringByFrequency(frequency);
          final intensity = (0.55 + (1 - i / sequence.length) * 0.26).clamp(
            0.35,
            0.9,
          );
          _pluckString(
            visualIndex,
            intensity: intensity.toDouble(),
            direction: forward ? 1.0 : -1.0,
            force: true,
            frequencyOverride: frequency,
            applyChordResonance: false,
          );
          await Future<void>.delayed(const Duration(milliseconds: 44));
        }
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
      return;
    }

    final ascending = List<int>.generate(_stringCount, (index) => index);
    final sequence = switch (_patternId) {
      'cascade' => <int>[
        ...ascending,
        ...List<int>.generate(_stringCount - 2, (i) => _stringCount - 2 - i),
      ],
      _ => ascending,
    };
    final delay = _patternId == 'cascade' ? 68 : 86;
    for (final index in sequence) {
      _pluckString(
        index,
        intensity: 0.68,
        direction: 1,
        force: true,
        applyChordResonance: false,
      );
      await Future<void>.delayed(Duration(milliseconds: delay));
    }
  }

  @override
  void dispose() {
    if (widget.fullScreen) {
      unawaited(_exitImmersiveMode());
    }
    _vibrationTicker.dispose();
    _invalidateAudioPlayers(warmUp: false);
    super.dispose();
  }

  void _openFullScreen() {
    if (widget.fullScreen) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const HarpToolPage(fullScreen: true),
      ),
    );
  }

  Widget _buildHarpSurface({
    required BuildContext context,
    required Size size,
    required bool rounded,
  }) {
    Widget content = _ToolboxScrollLockSurface(
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _handlePointerDown,
        onPointerMove: (event) => _handlePointerMove(event, size),
        onPointerUp: (event) => _handlePointerUp(event, size),
        onPointerCancel: _handlePointerCancel,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: CustomPaint(
            painter: _HarpPainter(
              stringCount: _stringCount,
              noteFrequencies: _activeNotes,
              stringOffsets: _stringOffsets,
              focusedString: _focusedString,
              colorScheme: Theme.of(context).colorScheme,
              paletteColors: _activePalette.colors,
              pluckStyleId: _pluckStyleId,
              horizontalLayout: _isHorizontalLayout,
            ),
          ),
        ),
      ),
    );
    if (rounded) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: content,
      );
    }
    return content;
  }

  Widget _buildFullScreenBody(BuildContext context) {
    final i18n = _toolboxI18n(context);
    final reverbPercent = (_reverbUi * 100).round();
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final activePreset = _realismPresets.where((preset) {
      return preset.id == _activeRealismPresetId;
    });
    final presetLabel = activePreset.isEmpty
        ? pickUiText(i18n, zh: '自定义', en: 'Custom')
        : _realismLabel(i18n, activePreset.first);

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, topInset + 8, 0, bottomInset + 88),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(
                  constraints.maxWidth,
                  math.max(320.0, constraints.maxHeight),
                );
                return Align(
                  alignment: Alignment.topCenter,
                  child: _buildHarpSurface(
                    context: context,
                    size: size,
                    rounded: true,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: topInset + 10,
          child: Row(
            children: <Widget>[
              FilledButton.tonal(
                onPressed:
                    widget.onExitFullScreen ??
                    () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.38),
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 20),
              ),
              const SizedBox(width: 10),
              FilledButton.tonal(
                onPressed: () => setState(() => _muted = !_muted),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.38),
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
                child: Icon(
                  _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.tonal(
                onPressed: () => _openHarpSettingsSheet(context, i18n),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.38),
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Icon(Icons.tune_rounded, size: 20),
              ),
            ],
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: bottomInset + 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _CompactMetric(
                    label: pickUiText(i18n, zh: '布局', en: 'Layout'),
                    value: pickUiText(i18n, zh: '竖向', en: 'Vertical'),
                  ),
                  const SizedBox(width: 8),
                  _CompactMetric(
                    label: pickUiText(i18n, zh: '预设', en: 'Preset'),
                    value: presetLabel,
                  ),
                  const SizedBox(width: 8),
                  _CompactMetric(
                    label: pickUiText(i18n, zh: '残响', en: 'Reverb'),
                    value: '$reverbPercent%',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openHarpSettingsSheet(BuildContext context, AppI18n i18n) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            void applySettings(VoidCallback mutation) {
              if (!mounted) return;
              setState(mutation);
              setSheetState(() {});
            }

            return _buildHarpSettingsSheetContent(
              context,
              i18n,
              applySettings: applySettings,
            );
          },
        );
      },
    );
  }

  Widget _buildHarpSettingsSheetContent(
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
          Text(
            pickUiText(i18n, zh: '高真实度预设', en: 'High Realism Presets'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _realismPresets
                .map(
                  (preset) => ChoiceChip(
                    label: Text(_realismLabel(i18n, preset)),
                    selected: _activeRealismPresetId == preset.id,
                    tooltip: _realismDescription(i18n, preset),
                    onSelected: (_) {
                      _applyRealismPreset(preset);
                      applySettings(() {});
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 20),
          Text(
            pickUiText(i18n, zh: '音色拟真', en: 'Timbre'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _pluckPresets
                .map(
                  (preset) => ChoiceChip(
                    label: Text(_pluckLabel(i18n, preset)),
                    selected: _pluckStyleId == preset.id,
                    tooltip: _pluckDescription(i18n, preset),
                    onSelected: (_) {
                      if (_pluckStyleId == preset.id) return;
                      setState(() {
                        _pluckStyleId = preset.id;
                        _markRealismCustom();
                      });
                      _invalidateAudioPlayers();
                      applySettings(() {});
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 20),
          Text(
            pickUiText(i18n, zh: '主题配色', en: 'Palette'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _palettePresets
                .map(
                  (preset) => ChoiceChip(
                    label: Text(_paletteLabel(i18n, preset)),
                    selected: _paletteId == preset.id,
                    onSelected: (_) {
                      if (_paletteId == preset.id) return;
                      applySettings(() {
                        _paletteId = preset.id;
                        _markRealismCustom();
                      });
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 20),
          Text(
            pickUiText(i18n, zh: '调式', en: 'Scale'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _scalePresets
                .map(
                  (preset) => ChoiceChip(
                    label: Text(_scaleLabel(i18n, preset)),
                    selected: _scaleId == preset.id,
                    onSelected: (_) {
                      if (_scaleId == preset.id) return;
                      applySettings(() {
                        _scaleId = preset.id;
                        _markRealismCustom();
                      });
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 20),
          Text(
            pickUiText(i18n, zh: '残响', en: 'Reverb'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _reverbUi,
            min: 0.0,
            max: 0.8,
            divisions: 16,
            onChanged: (value) {
              setState(() {
                _reverbUi = value;
                _markRealismCustom();
              });
            },
            onChangeEnd: (value) {
              final quantized = (value * 20).round() / 20;
              setState(() {
                _reverbUi = quantized;
                _reverbForAudio = quantized;
                _markRealismCustom();
              });
              _invalidateAudioPlayers();
              applySettings(() {});
            },
          ),
          const SizedBox(height: 20),
          Text(
            pickUiText(i18n, zh: '阻尼', en: 'Damping'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _damping,
            min: 4,
            max: 18,
            divisions: 28,
            onChanged: (value) {
              applySettings(() {
                _damping = value;
                _markRealismCustom();
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    final theme = Theme.of(context);
    final reverbPercent = (_reverbUi * 100).round();
    if (widget.fullScreen) {
      return _buildFullScreenBody(context);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SectionHeader(
              title: pickUiText(i18n, zh: '琴弦', en: 'Strings'),
              subtitle: pickUiText(
                i18n,
                zh: '二阶段竖琴：开放音色、和声与手势手感参数。',
                en: 'Second-pass harp with exposed tone, harmony, and gesture feel controls.',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                ToolboxMetricCard(
                  label: pickUiText(i18n, zh: '弦数', en: 'Strings'),
                  value: '12',
                ),
                ToolboxMetricCard(
                  label: pickUiText(i18n, zh: '调式', en: 'Scale'),
                  value: _scaleLabel(i18n, _activeScale),
                ),
                ToolboxMetricCard(
                  label: pickUiText(i18n, zh: '残响', en: 'Reverb'),
                  value: '$reverbPercent%',
                ),
                FilledButton.tonalIcon(
                  onPressed: () => setState(() => _muted = !_muted),
                  icon: Icon(
                    _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  ),
                  label: Text(
                    _muted
                        ? pickUiText(i18n, zh: '静音', en: 'Muted')
                        : pickUiText(i18n, zh: '声音开', en: 'Sound on'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _openFullScreen,
                  icon: const Icon(Icons.open_in_full_rounded),
                  label: Text(pickUiText(i18n, zh: '全屏', en: 'Full screen')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final viewportHeight = MediaQuery.sizeOf(context).height;
                final stageHeight = math
                    .min(math.max(380, viewportHeight * 0.68), 620)
                    .toDouble();
                final size = Size(width, stageHeight);
                return _buildHarpSurface(
                  context: context,
                  size: size,
                  rounded: true,
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: _playArpeggio,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    pickUiText(i18n, zh: '自动琶音', en: 'Auto arpeggio'),
                  ),
                ),
                Text(
                  pickUiText(
                    i18n,
                    zh: '提示：更宽更快的扫弦会产生更明亮的音色。',
                    en: 'Tip: a wider, faster swipe creates a brighter strum.',
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SectionHeader(
              title: pickUiText(i18n, zh: '高真实度预设', en: 'High Realism Presets'),
              subtitle: pickUiText(
                i18n,
                zh: '针对琴弦行为与空间响应调校的预设包。',
                en: 'Preset bundles tuned for realistic string behavior and room response.',
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _realismPresets
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(_realismLabel(i18n, preset)),
                      selected: _activeRealismPresetId == preset.id,
                      tooltip: _realismDescription(i18n, preset),
                      onSelected: (_) {
                        _applyRealismPreset(preset);
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            Divider(color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 12),
            SectionHeader(
              title: pickUiText(i18n, zh: '音色与视觉', en: 'Tone & Visual'),
              subtitle: pickUiText(
                i18n,
                zh: '将拨弦音色拟真与主题配色拆分，分别独立调整。',
                en: 'Split pluck timbre realism and theme palette into separate controls.',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              pickUiText(i18n, zh: '音色拟真', en: 'Timbre'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _pluckPresets
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(_pluckLabel(i18n, preset)),
                      selected: _pluckStyleId == preset.id,
                      tooltip: _pluckDescription(i18n, preset),
                      onSelected: (_) {
                        if (_pluckStyleId == preset.id) return;
                        setState(() {
                          _pluckStyleId = preset.id;
                          _markRealismCustom();
                        });
                        _invalidateAudioPlayers();
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            Text(
              pickUiText(i18n, zh: '主题配色', en: 'Palette'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _palettePresets
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(_paletteLabel(i18n, preset)),
                      selected: _paletteId == preset.id,
                      onSelected: (_) {
                        if (_paletteId == preset.id) return;
                        setState(() {
                          _paletteId = preset.id;
                          _markRealismCustom();
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            Text(
              pickUiText(
                i18n,
                zh: '残响 $reverbPercent%',
                en: 'Reverb $reverbPercent%',
              ),
            ),
            Slider(
              value: _reverbUi,
              min: 0.0,
              max: 0.8,
              divisions: 16,
              onChanged: (value) {
                setState(() {
                  _reverbUi = value;
                  _markRealismCustom();
                });
              },
              onChangeEnd: (value) {
                final quantized = (value * 20).round() / 20;
                setState(() {
                  _reverbUi = quantized;
                  _reverbForAudio = quantized;
                  _markRealismCustom();
                });
                _invalidateAudioPlayers();
              },
            ),
            const SizedBox(height: 8),
            SectionHeader(
              title: pickUiText(i18n, zh: '和弦与调式', en: 'Scale & Chord'),
              subtitle: pickUiText(
                i18n,
                zh: '在同一竖琴面板中开放调式、和弦与琶音模式。',
                en: 'Expose mode, chord voicing, and arpeggio pattern from the same harp deck.',
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _scalePresets
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(_scaleLabel(i18n, preset)),
                      selected: _scaleId == preset.id,
                      onSelected: (_) {
                        if (_scaleId == preset.id) return;
                        setState(() {
                          _scaleId = preset.id;
                          _markRealismCustom();
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _chordPresets
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(_chordLabel(i18n, preset)),
                      selected: _chordId == preset.id,
                      onSelected: (_) {
                        if (_chordId == preset.id) return;
                        setState(() {
                          _chordId = preset.id;
                          _markRealismCustom();
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _patternPresets
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(_patternLabel(i18n, preset)),
                      selected: _patternId == preset.id,
                      tooltip: _patternDescription(i18n, preset),
                      onSelected: (_) {
                        if (_patternId == preset.id) return;
                        setState(() {
                          _patternId = preset.id;
                          _markRealismCustom();
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 8),
            FilterChip(
              label: Text(pickUiText(i18n, zh: '和弦共振', en: 'Chord resonance')),
              selected: _chordResonanceEnabled,
              onSelected: (selected) {
                setState(() {
                  _chordResonanceEnabled = selected;
                  _markRealismCustom();
                });
              },
            ),
            const SizedBox(height: 12),
            Text(
              pickUiText(
                i18n,
                zh: '和弦根音 ${_chordRootIndex + 1} / $_stringCount',
                en: 'Chord root ${_chordRootIndex + 1} / $_stringCount',
              ),
            ),
            Slider(
              value: _chordRootIndex.toDouble(),
              min: 0,
              max: (_stringCount - 1).toDouble(),
              divisions: _stringCount - 1,
              onChanged: (value) {
                setState(() {
                  _chordRootIndex = value.round();
                });
              },
            ),
            const SizedBox(height: 8),
            SectionHeader(
              title: pickUiText(i18n, zh: '手感参数', en: 'Feel'),
              subtitle: pickUiText(
                i18n,
                zh: '开放阻尼与触发阈值，便于触控灵敏度调节。',
                en: 'Expose damping and trigger threshold for touch sensitivity tuning.',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              pickUiText(
                i18n,
                zh: '阻尼 ${_damping.toStringAsFixed(1)}',
                en: 'Damping ${_damping.toStringAsFixed(1)}',
              ),
            ),
            Slider(
              value: _damping,
              min: 4,
              max: 18,
              divisions: 28,
              onChanged: (value) {
                setState(() {
                  _damping = value;
                  _markRealismCustom();
                });
              },
            ),
            const SizedBox(height: 6),
            Text(
              pickUiText(
                i18n,
                zh: '触发阈值 ${_swipeThreshold.toStringAsFixed(1)} px',
                en: 'Trigger threshold ${_swipeThreshold.toStringAsFixed(1)} px',
              ),
            ),
            Slider(
              value: _swipeThreshold,
              min: 0.4,
              max: 8,
              divisions: 38,
              onChanged: (value) {
                setState(() {
                  _swipeThreshold = value;
                  _markRealismCustom();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HarpPointerState {
  _HarpPointerState({required this.downPosition});

  final Offset downPosition;
  bool dragActive = false;
  Offset? lastDragPoint;
  int? lastDragStringIndex;
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HarpPainter extends CustomPainter {
  const _HarpPainter({
    required this.stringCount,
    required this.noteFrequencies,
    required this.stringOffsets,
    required this.focusedString,
    required this.colorScheme,
    required this.paletteColors,
    required this.pluckStyleId,
    required this.horizontalLayout,
  });

  final int stringCount;
  final List<double> noteFrequencies;
  final List<double> stringOffsets;
  final int? focusedString;
  final ColorScheme colorScheme;
  final List<Color> paletteColors;
  final String pluckStyleId;
  final bool horizontalLayout;

  double _stringTrackAt(int index, Size size) {
    final totalSpan = horizontalLayout ? size.height : size.width;
    final adaptiveInset = totalSpan * (horizontalLayout ? 0.07 : 0.16);
    final minInset = horizontalLayout ? 18.0 : 34.0;
    final leadingInset = math.max(minInset, adaptiveInset);
    final trailingInset = math.max(minInset, adaptiveInset);
    final usableSpan = math.max(1.0, totalSpan - leadingInset - trailingInset);
    if (stringCount == 1) return totalSpan / 2;
    return leadingInset + usableSpan * (index / (stringCount - 1));
  }

  Color _paletteColorAt(double t) {
    if (paletteColors.isEmpty) return colorScheme.primary;
    if (paletteColors.length == 1) return paletteColors.first;
    final clamped = t.clamp(0.0, 1.0);
    final scaled = clamped * (paletteColors.length - 1);
    final index = scaled.floor().clamp(0, paletteColors.length - 1);
    final next = math.min(index + 1, paletteColors.length - 1);
    final localT = scaled - index;
    return Color.lerp(paletteColors[index], paletteColors[next], localT) ??
        paletteColors[index];
  }

  int _pitchClassFromFrequency(double frequency) {
    final midi = (69 + 12 * (math.log(frequency / 440.0) / math.ln2)).round();
    return ((midi % 12) + 12) % 12;
  }

  String _noteName(int pitchClass) {
    const names = <String>[
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
    return names[pitchClass];
  }

  Color _pitchColor(int pitchClass) {
    const pitchColors = <Color>[
      Color(0xFFEF4444),
      Color(0xFFF97316),
      Color(0xFFF59E0B),
      Color(0xFFEAB308),
      Color(0xFF84CC16),
      Color(0xFF22C55E),
      Color(0xFF14B8A6),
      Color(0xFF06B6D4),
      Color(0xFF3B82F6),
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
      Color(0xFFD946EF),
    ];
    return pitchColors[pitchClass.clamp(0, 11)];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final styleCurve = switch (pluckStyleId) {
      'warm' => 0.78,
      'crystal' => 1.18,
      'bright' => 1.05,
      'glass' => 1.24,
      'nylon' => 0.72,
      'concert' => 0.82,
      'steel' => 0.98,
      _ => 0.9,
    };
    final idleStroke = switch (pluckStyleId) {
      'warm' => 2.2,
      'crystal' => 1.75,
      'bright' => 1.95,
      'glass' => 1.62,
      'nylon' => 2.35,
      'concert' => 2.08,
      'steel' => 1.88,
      _ => 1.9,
    };

    final topGradient = Color.lerp(
      _paletteColorAt(0.05),
      const Color(0xFF041224),
      0.42,
    );
    final middleGradient = Color.lerp(
      _paletteColorAt(0.45),
      const Color(0xFF0B2A43),
      0.46,
    );
    final bottomGradient = Color.lerp(
      _paletteColorAt(0.95),
      const Color(0xFF0F172A),
      0.28,
    );
    final framePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          topGradient ?? const Color(0xFF0F172A),
          middleGradient ?? (topGradient ?? colorScheme.primary),
          bottomGradient ?? const Color(0xFF1E1B4B),
        ],
      ).createShader(Offset.zero & size);
    final borderPaint = Paint()
      ..color = colorScheme.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final frame = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(28),
    );
    canvas.drawRRect(frame, framePaint);
    canvas.drawRRect(frame, borderPaint);

    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              _paletteColorAt(0.5).withValues(alpha: 0.2),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.5, size.height * 0.42),
              radius: size.width * 0.42,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.42),
      size.width * 0.42,
      glowPaint,
    );
    final auroraPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          _paletteColorAt(0.12).withValues(alpha: 0.08),
          Colors.transparent,
          _paletteColorAt(0.86).withValues(alpha: 0.1),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, auroraPaint);

    final topY = size.height * 0.06;
    final bottomY = size.height * 0.94;
    final leftX = size.width * 0.06;
    final rightX = size.width * 0.94;
    final midY = (topY + bottomY) / 2;
    final midX = (leftX + rightX) / 2;
    final textScale = horizontalLayout
        ? (size.height / 520).clamp(0.72, 1.06)
        : (size.width / 420).clamp(0.72, 1.0);
    for (var index = 0; index < stringCount; index += 1) {
      final track = _stringTrackAt(index, size);
      final frequency = noteFrequencies[index % noteFrequencies.length];
      final pitchClass = _pitchClassFromFrequency(frequency);
      final noteColor = _pitchColor(pitchClass);
      final sway = (index < stringOffsets.length ? stringOffsets[index] : 0.0)
          .clamp(-22.0, 22.0)
          .toDouble();
      final activity = (sway.abs() / 22).clamp(0.0, 1.0).toDouble();
      final active = focusedString == index || activity > 0.04;
      final paletteColor = _paletteColorAt(index / (stringCount - 1));
      final baseColor = Color.lerp(noteColor, paletteColor, 0.22) ?? noteColor;
      final idleColor =
          Color.lerp(baseColor.withValues(alpha: 0.92), Colors.white, 0.42) ??
          baseColor.withValues(alpha: 0.92);
      final strokeColor = Color.lerp(
        idleColor,
        Colors.white,
        active ? (0.52 + activity * 0.48).clamp(0.0, 1.0) : 0.0,
      );
      final skeletonPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.26)
        ..strokeWidth = math.max(1.35, idleStroke - 0.72)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final basePaint = Paint()
        ..color = baseColor.withValues(alpha: 0.86)
        ..strokeWidth = math.max(1.5, idleStroke - 0.42)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final basePath = horizontalLayout
          ? (Path()
              ..moveTo(leftX, track)
              ..quadraticBezierTo(midX, track, rightX, track))
          : (Path()
              ..moveTo(track, topY)
              ..quadraticBezierTo(track, midY, track, bottomY));
      canvas.drawPath(basePath, skeletonPaint);
      canvas.drawPath(basePath, basePaint);
      final paint = Paint()
        ..color = strokeColor ?? colorScheme.primary
        ..strokeWidth = active ? idleStroke + 1.2 + activity * 0.95 : idleStroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (active) {
        final underGlow = Paint()
          ..color = baseColor.withValues(alpha: 0.2)
          ..strokeWidth = 5.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawPath(basePath, underGlow);

        final glow = Paint()
          ..color = (strokeColor ?? colorScheme.primary).withValues(alpha: 0.28)
          ..strokeWidth = 7
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        final glowPath = horizontalLayout
            ? (Path()
                ..moveTo(leftX, track)
                ..quadraticBezierTo(
                  midX,
                  track + sway * styleCurve,
                  rightX,
                  track,
                ))
            : (Path()
                ..moveTo(track, topY)
                ..quadraticBezierTo(
                  track + sway * styleCurve,
                  midY,
                  track,
                  bottomY,
                ));
        canvas.drawPath(glowPath, glow);
      }

      final path = horizontalLayout
          ? (Path()
              ..moveTo(leftX, track)
              ..quadraticBezierTo(
                midX,
                track + sway * styleCurve,
                rightX,
                track,
              ))
          : (Path()
              ..moveTo(track, topY)
              ..quadraticBezierTo(
                track + sway * styleCurve,
                midY,
                track,
                bottomY,
              ));
      canvas.drawPath(path, paint);

      final anchorPaint = Paint()
        ..color = (strokeColor ?? colorScheme.primary).withValues(alpha: 0.75);
      if (horizontalLayout) {
        canvas.drawCircle(Offset(leftX, track), 2.5, anchorPaint);
        canvas.drawCircle(Offset(rightX, track), 2.2, anchorPaint);
      } else {
        canvas.drawCircle(Offset(track, topY), 2.5, anchorPaint);
        canvas.drawCircle(Offset(track, bottomY), 2.2, anchorPaint);
      }

      final activeDot = Paint()
        ..color = baseColor.withValues(alpha: active ? 0.96 : 0.5);
      final activeDotOffset = horizontalLayout
          ? Offset(rightX, track)
          : Offset(track, bottomY);
      canvas.drawCircle(activeDotOffset, active ? 3.4 : 2.4, activeDot);

      final labelPainter = TextPainter(
        text: TextSpan(
          text: _noteName(pitchClass),
          style: TextStyle(
            color: (strokeColor ?? noteColor).withValues(alpha: 0.9),
            fontSize: 9.5 * textScale,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelOffset = horizontalLayout
          ? Offset(
              leftX - labelPainter.width - 8,
              track - labelPainter.height / 2,
            )
          : Offset(track - labelPainter.width / 2, topY - 16 * textScale);
      labelPainter.paint(canvas, labelOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _HarpPainter oldDelegate) {
    return true;
  }
}

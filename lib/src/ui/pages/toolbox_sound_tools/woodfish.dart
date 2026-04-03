part of '../toolbox_sound_tools.dart';

enum _WoodfishSoundProfile {
  temple,
  sandal,
  bright,
  hollow,
  night;

  String get id => name;

  String get label => switch (this) {
    _WoodfishSoundProfile.temple => 'Temple',
    _WoodfishSoundProfile.sandal => 'Sandal',
    _WoodfishSoundProfile.bright => 'Bright',
    _WoodfishSoundProfile.hollow => 'Hollow',
    _WoodfishSoundProfile.night => 'Night',
  };

  static _WoodfishSoundProfile fromId(String? value) {
    for (final item in _WoodfishSoundProfile.values) {
      if (item.id == value) {
        return item;
      }
    }
    return _WoodfishSoundProfile.temple;
  }
}

enum _WoodfishVisualStyle {
  zenAmber,
  inkSandal,
  nightLantern;

  String get id => switch (this) {
    _WoodfishVisualStyle.zenAmber => 'zen_amber',
    _WoodfishVisualStyle.inkSandal => 'ink_sandal',
    _WoodfishVisualStyle.nightLantern => 'night_lantern',
  };

  static _WoodfishVisualStyle fromId(String? value) {
    return switch (value) {
      'ink_sandal' => _WoodfishVisualStyle.inkSandal,
      'night_lantern' => _WoodfishVisualStyle.nightLantern,
      _ => _WoodfishVisualStyle.zenAmber,
    };
  }
}

enum _WoodfishReboundArcPreset {
  compact,
  wide;

  String get id => switch (this) {
    _WoodfishReboundArcPreset.compact => 'compact',
    _WoodfishReboundArcPreset.wide => 'wide',
  };

  static _WoodfishReboundArcPreset fromId(String? value) {
    return switch (value) {
      'wide' => _WoodfishReboundArcPreset.wide,
      _ => _WoodfishReboundArcPreset.compact,
    };
  }
}

class _WoodfishVisualTokens {
  const _WoodfishVisualTokens({
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.screenGradient,
    required this.immersiveStageGradient,
    required this.normalStageGradient,
    required this.bodyGradient,
    required this.bodyStroke,
    required this.grooveDark,
    required this.grooveLight,
    required this.grain,
    required this.dust,
    required this.accentWarm,
    required this.accentCool,
    required this.malletShaftGradient,
    required this.malletHeadGradient,
    required this.malletBand,
    required this.malletGlow,
  });

  final Color primaryAccent;
  final Color secondaryAccent;
  final List<Color> screenGradient;
  final List<Color> immersiveStageGradient;
  final List<Color> normalStageGradient;
  final List<Color> bodyGradient;
  final Color bodyStroke;
  final Color grooveDark;
  final Color grooveLight;
  final Color grain;
  final Color dust;
  final Color accentWarm;
  final Color accentCool;
  final List<Color> malletShaftGradient;
  final List<Color> malletHeadGradient;
  final Color malletBand;
  final Color malletGlow;
}

_WoodfishVisualTokens _visualTokens(_WoodfishVisualStyle style) {
  return switch (style) {
    _WoodfishVisualStyle.inkSandal => const _WoodfishVisualTokens(
      primaryAccent: Color(0xFF9CB7D1),
      secondaryAccent: Color(0xFF6EA5C8),
      screenGradient: <Color>[
        Color(0xFF090D16),
        Color(0xFF121B2C),
        Color(0xFF0D131F),
      ],
      immersiveStageGradient: <Color>[
        Color(0xFF080D15),
        Color(0xFF121A28),
        Color(0xFF0B1019),
      ],
      normalStageGradient: <Color>[
        Color(0xFFE6E8EB),
        Color(0xFFD7DDE3),
        Color(0xFFC4CCD5),
      ],
      bodyGradient: <Color>[
        Color(0xFFB8A892),
        Color(0xFF8B745B),
        Color(0xFF5B4A39),
      ],
      bodyStroke: Color(0xFF2D2520),
      grooveDark: Color(0xFF25211D),
      grooveLight: Color(0xFFEDE7DE),
      grain: Color(0xFF3A322C),
      dust: Color(0xFFCED7E2),
      accentWarm: Color(0xFFCAA36A),
      accentCool: Color(0xFF7BB3CF),
      malletShaftGradient: <Color>[Color(0xFF8C7A62), Color(0xFF5E5343)],
      malletHeadGradient: <Color>[
        Color(0xFFD2C3AA),
        Color(0xFF9D8769),
        Color(0xFF6D5C48),
      ],
      malletBand: Color(0xFF617489),
      malletGlow: Color(0xFFA9C5DA),
    ),
    _WoodfishVisualStyle.nightLantern => const _WoodfishVisualTokens(
      primaryAccent: Color(0xFFF5B25E),
      secondaryAccent: Color(0xFFE68A7B),
      screenGradient: <Color>[
        Color(0xFF1F102A),
        Color(0xFF3D1F2E),
        Color(0xFF1A1326),
      ],
      immersiveStageGradient: <Color>[
        Color(0xFF160E22),
        Color(0xFF2A1830),
        Color(0xFF130C1C),
      ],
      normalStageGradient: <Color>[
        Color(0xFFF3DACC),
        Color(0xFFE7C2AF),
        Color(0xFFD19F86),
      ],
      bodyGradient: <Color>[
        Color(0xFFDA9C61),
        Color(0xFFA05A37),
        Color(0xFF6A3529),
      ],
      bodyStroke: Color(0xFF3E1F18),
      grooveDark: Color(0xFF2E1814),
      grooveLight: Color(0xFFF8D1B8),
      grain: Color(0xFF4A2921),
      dust: Color(0xFFF7C89E),
      accentWarm: Color(0xFFF59E0B),
      accentCool: Color(0xFFE8796D),
      malletShaftGradient: <Color>[Color(0xFF9A4E37), Color(0xFF6D3326)],
      malletHeadGradient: <Color>[
        Color(0xFFE6A06A),
        Color(0xFFBA653A),
        Color(0xFF7D3A2B),
      ],
      malletBand: Color(0xFFA52B40),
      malletGlow: Color(0xFFF9BE6B),
    ),
    _ => const _WoodfishVisualTokens(
      primaryAccent: Color(0xFFD9A441),
      secondaryAccent: Color(0xFF6BAF92),
      screenGradient: <Color>[
        Color(0xFF050608),
        Color(0xFF0B0F14),
        Color(0xFF090C12),
      ],
      immersiveStageGradient: <Color>[
        Color(0xFF070A0F),
        Color(0xFF121821),
        Color(0xFF0A0E14),
      ],
      normalStageGradient: <Color>[
        Color(0xFFF7EBD8),
        Color(0xFFEBD6B8),
        Color(0xFFD7B98E),
      ],
      bodyGradient: <Color>[
        Color(0xFFEFDFBC),
        Color(0xFFD6BA8D),
        Color(0xFFB58A58),
      ],
      bodyStroke: Color(0xFF4A2A11),
      grooveDark: Color(0xFF3D2414),
      grooveLight: Color(0xFFF8EACB),
      grain: Color(0xFF5A391F),
      dust: Color(0xFFFCEFD2),
      accentWarm: Color(0xFFF2B35B),
      accentCool: Color(0xFF8CBF9C),
      malletShaftGradient: <Color>[Color(0xFFE7C793), Color(0xFFC3945C)],
      malletHeadGradient: <Color>[
        Color(0xFFF5DEB3),
        Color(0xFFD9B27A),
        Color(0xFFB2834E),
      ],
      malletBand: Color(0xFFB45F2B),
      malletGlow: Color(0xFFF7D289),
    ),
  };
}

class _WoodfishRhythmPreset {
  const _WoodfishRhythmPreset({
    required this.id,
    required this.bpm,
    required this.beatsPerCycle,
    required this.subdivision,
    required this.accentEvery,
    required this.targetCount,
  });

  final String id;
  final int bpm;
  final int beatsPerCycle;
  final int subdivision;
  final int accentEvery;
  final int targetCount;
}

class _WoodfishTool extends StatefulWidget {
  const _WoodfishTool({
    this.fullScreen = false,
    this.autoStart = false,
    this.suspendPlayback = false,
    this.onOpenFullScreen,
    this.onExitFullScreen,
  });

  final bool fullScreen;
  final bool autoStart;
  final bool suspendPlayback;
  final void Function({required bool autoStart})? onOpenFullScreen;
  final VoidCallback? onExitFullScreen;

  @override
  State<_WoodfishTool> createState() => _WoodfishToolState();
}

class _WoodfishToolState extends State<_WoodfishTool>
    with TickerProviderStateMixin {
  static const List<_WoodfishRhythmPreset> _rhythmPresets =
      <_WoodfishRhythmPreset>[
        _WoodfishRhythmPreset(
          id: 'calm_four',
          bpm: 60,
          beatsPerCycle: 4,
          subdivision: 1,
          accentEvery: 4,
          targetCount: 54,
        ),
        _WoodfishRhythmPreset(
          id: 'mantra_flow',
          bpm: 72,
          beatsPerCycle: 4,
          subdivision: 2,
          accentEvery: 4,
          targetCount: 108,
        ),
        _WoodfishRhythmPreset(
          id: 'triplet_focus',
          bpm: 66,
          beatsPerCycle: 3,
          subdivision: 3,
          accentEvery: 3,
          targetCount: 81,
        ),
        _WoodfishRhythmPreset(
          id: 'walking_eight',
          bpm: 84,
          beatsPerCycle: 8,
          subdivision: 1,
          accentEvery: 4,
          targetCount: 108,
        ),
        _WoodfishRhythmPreset(
          id: 'energy_roll',
          bpm: 96,
          beatsPerCycle: 4,
          subdivision: 2,
          accentEvery: 2,
          targetCount: 216,
        ),
      ];

  final Stopwatch _sessionStopwatch = Stopwatch();
  ToolboxEffectPlayer? _regularPlayer;
  ToolboxEffectPlayer? _accentPlayer;
  Timer? _autoTimer;
  Timer? _holdTimer;
  Timer? _persistTimer;
  Timer? _sessionTicker;
  Timer? _floatingHideTimer;
  int _audioRevision = 0;
  int? _transportAnchorUs;

  late final AnimationController _strikeController;
  late final AnimationController _ambientController;

  int _sessionCount = 0;
  int _allTimeCount = 0;
  int _pulseInCycle = 0;
  int _targetCount = 108;

  int _bpm = 68;
  int _beatsPerCycle = 4;
  int _subdivision = 1;
  int _accentEvery = 4;

  double _masterVolume = 0.9;
  double _accentBoost = 0.18;
  double _resonance = 0.7;
  double _brightness = 0.48;
  double _pitch = 0.0;
  double _strikeHardness = 0.55;

  bool _hapticsEnabled = true;
  bool _autoStopAtGoal = true;
  bool _autoRunning = false;
  bool _lastWasAccent = false;

  String _activeRhythmPresetId = 'calm_four';
  String _lastGesture = 'Tap';
  String _floatingText = '功德 +1';
  _WoodfishSoundProfile _soundProfile = _WoodfishSoundProfile.temple;
  _WoodfishVisualStyle _visualStyle = _WoodfishVisualStyle.zenAmber;
  _WoodfishReboundArcPreset _reboundArcPreset =
      _WoodfishReboundArcPreset.compact;
  Duration _elapsed = Duration.zero;
  int _floatingSerial = 0;
  int? _activeFloatingSerial;

  late final TextEditingController _floatingTextController;

  int get _cyclePulses => math.max(1, _beatsPerCycle * _subdivision);
  String get _resolvedFloatingText =>
      _floatingText.trim().isEmpty ? '功德 +1' : _floatingText.trim();

  WoodfishPrefsState get _prefsState => WoodfishPrefsState(
    soundId: _soundProfile.id,
    visualStyleId: _visualStyle.id,
    reboundArcId: _reboundArcPreset.id,
    rhythmPresetId: _activeRhythmPresetId,
    bpm: _bpm,
    beatsPerCycle: _beatsPerCycle,
    subdivision: _subdivision,
    accentEvery: _accentEvery,
    masterVolume: _masterVolume,
    accentBoost: _accentBoost,
    resonance: _resonance,
    brightness: _brightness,
    pitch: _pitch,
    strike: _strikeHardness,
    targetCount: _targetCount,
    hapticsEnabled: _hapticsEnabled,
    autoStopAtGoal: _autoStopAtGoal,
    allTimeCount: _allTimeCount,
    floatingText: _floatingText,
  );

  @override
  void initState() {
    super.initState();
    _strikeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _floatingTextController = TextEditingController(text: _floatingText);
    unawaited(_rebuildPlayers());
    unawaited(_loadPrefs());
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _autoRunning) {
          return;
        }
        _startAuto();
      });
    }
  }

  @override
  void didUpdateWidget(covariant _WoodfishTool oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.suspendPlayback && widget.suspendPlayback) {
      _suspendForOverlay();
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _holdTimer?.cancel();
    _persistTimer?.cancel();
    _sessionTicker?.cancel();
    _floatingHideTimer?.cancel();
    _sessionStopwatch.stop();
    _strikeController.dispose();
    _ambientController.dispose();
    _floatingTextController.dispose();
    final regular = _regularPlayer;
    final accent = _accentPlayer;
    if (regular != null) {
      unawaited(regular.dispose());
    }
    if (accent != null) {
      unawaited(accent.dispose());
    }
    super.dispose();
  }

  bool _isAccentPulse(int pulseIndex) {
    if (pulseIndex == 0) {
      return true;
    }
    if (_accentEvery <= 1) {
      return true;
    }
    return pulseIndex % _accentEvery == 0;
  }

  void _suspendForOverlay() {
    _stopHoldRoll();
    if (_autoRunning) {
      _stopAuto();
    }
  }

  String _formatElapsed(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double _mixDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }

  Color _stylePrimaryAccent() => _visualTokens(_visualStyle).primaryAccent;

  Color _styleSecondaryAccent() => _visualTokens(_visualStyle).secondaryAccent;

  Gradient _screenBackgroundGradient() {
    final tokens = _visualTokens(_visualStyle);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: tokens.screenGradient,
    );
  }

  String _uiText(
    BuildContext context, {
    required String zh,
    required String en,
  }) {
    return pickUiText(_toolboxI18n(context, listen: false), zh: zh, en: en);
  }

  String _modeLabelText(BuildContext context) {
    return _uiText(
      context,
      zh: _autoRunning ? '自动禅拍' : '手动叩击',
      en: _autoRunning ? 'Auto rhythm' : 'Manual strike',
    );
  }

  String _soundLabelText(BuildContext context, _WoodfishSoundProfile profile) {
    return switch (profile) {
      _WoodfishSoundProfile.temple => _uiText(
        context,
        zh: '古寺木韵',
        en: 'Temple',
      ),
      _WoodfishSoundProfile.sandal => _uiText(
        context,
        zh: '檀木清响',
        en: 'Sandal',
      ),
      _WoodfishSoundProfile.bright => _uiText(
        context,
        zh: '晨钟明脆',
        en: 'Bright',
      ),
      _WoodfishSoundProfile.hollow => _uiText(
        context,
        zh: '空谷回鸣',
        en: 'Hollow',
      ),
      _WoodfishSoundProfile.night => _uiText(context, zh: '夜静低鸣', en: 'Night'),
    };
  }

  String _visualStyleLabel(BuildContext context, _WoodfishVisualStyle style) {
    return switch (style) {
      _WoodfishVisualStyle.inkSandal => _uiText(
        context,
        zh: '水墨檀影',
        en: 'Ink Sandal',
      ),
      _WoodfishVisualStyle.nightLantern => _uiText(
        context,
        zh: '灯火夜禅',
        en: 'Night Lantern',
      ),
      _ => _uiText(context, zh: '古寺琥珀', en: 'Zen Amber'),
    };
  }

  String _visualStyleHint(BuildContext context, _WoodfishVisualStyle style) {
    return switch (style) {
      _WoodfishVisualStyle.inkSandal => _uiText(
        context,
        zh: '冷色水墨底纹，檀木纹理更克制，适合静坐与夜读。',
        en: 'Cool ink texture with restrained sandalwood details.',
      ),
      _WoodfishVisualStyle.nightLantern => _uiText(
        context,
        zh: '暗夜灯影与暖金光晕，重击时更有香火流动感。',
        en: 'Lantern-like night glow with warm ritual highlights.',
      ),
      _ => _uiText(
        context,
        zh: '古寺暖木配色，带轻微金粉与木纹起伏。',
        en: 'Warm temple wood palette with subtle golden dust.',
      ),
    };
  }

  String _reboundArcLabel(
    BuildContext context,
    _WoodfishReboundArcPreset preset,
  ) {
    return switch (preset) {
      _WoodfishReboundArcPreset.wide => _uiText(
        context,
        zh: '舒展弧线',
        en: 'Wide Arc',
      ),
      _ => _uiText(context, zh: '紧凑弧线', en: 'Compact Arc'),
    };
  }

  String _reboundArcHint(
    BuildContext context,
    _WoodfishReboundArcPreset preset,
  ) {
    return switch (preset) {
      _WoodfishReboundArcPreset.wide => _uiText(
        context,
        zh: '回弹半径更大，击槌抬手更舒展，适合仪式感节奏。',
        en: 'Larger rebound radius with a wider return arc.',
      ),
      _ => _uiText(
        context,
        zh: '回弹半径更短，轨迹收紧，适合稳定而克制的敲击。',
        en: 'Shorter rebound radius for a tighter return path.',
      ),
    };
  }

  String _gestureLabel(BuildContext context) {
    return switch (_lastGesture) {
      'Tap' => _uiText(context, zh: '轻叩', en: 'Tap'),
      'Hold' => _uiText(context, zh: '长按连击', en: 'Hold roll'),
      'Button' => _uiText(context, zh: '按钮叩击', en: 'Button strike'),
      'Auto' => _uiText(context, zh: '自动禅拍', en: 'Auto rhythm'),
      'Reset' => _uiText(context, zh: '重置', en: 'Reset'),
      _ => _lastGesture,
    };
  }

  String _rhythmLabel(BuildContext context, String id) {
    return switch (id) {
      'mantra_flow' => _uiText(context, zh: '咒息流转', en: 'Mantra Flow'),
      'triplet_focus' => _uiText(context, zh: '三拍入静', en: 'Triplet Focus'),
      'walking_eight' => _uiText(context, zh: '八拍行禅', en: 'Walking 8'),
      'energy_roll' => _uiText(context, zh: '连击振心', en: 'Energy Roll'),
      'custom' => _uiText(context, zh: '自定禅拍', en: 'Custom'),
      _ => _uiText(context, zh: '四拍安定', en: 'Calm 4/4'),
    };
  }

  void _ensureSessionTicker() {
    if (_sessionTicker != null) {
      return;
    }
    _sessionTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_sessionStopwatch.isRunning) {
        return;
      }
      setState(() {
        _elapsed = _sessionStopwatch.elapsed;
      });
    });
  }

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 420), () {
      unawaited(ToolboxWoodfishPrefsService.save(_prefsState));
    });
  }

  Future<void> _loadPrefs() async {
    final prefs = await ToolboxWoodfishPrefsService.load();
    if (!mounted) {
      return;
    }
    final cyclePulses = (prefs.beatsPerCycle * prefs.subdivision).clamp(1, 96);
    setState(() {
      _soundProfile = _WoodfishSoundProfile.fromId(prefs.soundId);
      _visualStyle = _WoodfishVisualStyle.fromId(prefs.visualStyleId);
      _reboundArcPreset = _WoodfishReboundArcPreset.fromId(prefs.reboundArcId);
      _activeRhythmPresetId = prefs.rhythmPresetId;
      _bpm = prefs.bpm;
      _beatsPerCycle = prefs.beatsPerCycle;
      _subdivision = prefs.subdivision;
      _accentEvery = prefs.accentEvery.clamp(1, cyclePulses);
      _masterVolume = prefs.masterVolume;
      _accentBoost = prefs.accentBoost;
      _resonance = prefs.resonance;
      _brightness = prefs.brightness;
      _pitch = prefs.pitch;
      _strikeHardness = prefs.strike;
      _targetCount = prefs.targetCount;
      _hapticsEnabled = prefs.hapticsEnabled;
      _autoStopAtGoal = prefs.autoStopAtGoal;
      _allTimeCount = prefs.allTimeCount;
      _floatingText = prefs.floatingText.trim().isEmpty
          ? '功德 +1'
          : prefs.floatingText.trim();
      _pulseInCycle = _pulseInCycle % _cyclePulses;
    });
    _floatingTextController.value = TextEditingValue(
      text: _floatingText,
      selection: TextSelection.collapsed(offset: _floatingText.length),
    );
    await _rebuildPlayers();
  }

  Future<void> _rebuildPlayers({bool preview = false}) async {
    final revision = ++_audioRevision;
    final regular = ToolboxEffectPlayer(
      ToolboxAudioBank.woodfishClick(
        style: _soundProfile.id,
        resonance: _resonance,
        brightness: _brightness,
        pitch: _pitch,
        strike: _strikeHardness,
        accent: false,
      ),
      maxPlayers: 10,
    );
    final accent = ToolboxEffectPlayer(
      ToolboxAudioBank.woodfishClick(
        style: _soundProfile.id,
        resonance: (_resonance + 0.1).clamp(0.0, 1.0),
        brightness: (_brightness + 0.08).clamp(0.0, 1.0),
        pitch: (_pitch + 0.2).clamp(-6.0, 6.0),
        strike: (_strikeHardness + 0.14).clamp(0.0, 1.0),
        accent: true,
      ),
      maxPlayers: 10,
    );
    await Future.wait<void>(<Future<void>>[regular.warmUp(), accent.warmUp()]);
    if (!mounted || revision != _audioRevision) {
      await regular.dispose();
      await accent.dispose();
      return;
    }
    final oldRegular = _regularPlayer;
    final oldAccent = _accentPlayer;
    _regularPlayer = regular;
    _accentPlayer = accent;
    if (oldRegular != null) {
      await oldRegular.dispose();
    }
    if (oldAccent != null) {
      await oldAccent.dispose();
    }
    if (preview) {
      _previewStrike();
    }
  }

  void _previewStrike() {
    final player = _accentPlayer ?? _regularPlayer;
    if (player == null) {
      return;
    }
    _strikeController.forward(from: 0);
    unawaited(
      player.play(
        volume: (_masterVolume * (1 + _accentBoost * 0.5)).clamp(0.08, 1.0),
      ),
    );
  }

  Future<void> _performStrike({
    required String gesture,
    bool fromAuto = false,
  }) async {
    if (_regularPlayer == null || _accentPlayer == null) {
      await _rebuildPlayers();
    }
    final accent = _isAccentPulse(_pulseInCycle);
    final player = accent ? _accentPlayer : _regularPlayer;
    if (player != null) {
      unawaited(
        player.play(
          volume: (_masterVolume * (accent ? (1 + _accentBoost) : 1.0)).clamp(
            0.08,
            1.0,
          ),
        ),
      );
    }
    if (_hapticsEnabled && !fromAuto) {
      if (accent) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    }
    if (!_sessionStopwatch.isRunning) {
      _sessionStopwatch.start();
      _ensureSessionTicker();
    }
    _strikeController.forward(from: 0);
    if (!mounted) {
      return;
    }
    setState(() {
      _sessionCount += 1;
      _allTimeCount += 1;
      _lastWasAccent = accent;
      _lastGesture = gesture;
      _pulseInCycle = (_pulseInCycle + 1) % _cyclePulses;
      _elapsed = _sessionStopwatch.elapsed;
      _floatingSerial += 1;
      _activeFloatingSerial = _floatingSerial;
    });
    _floatingHideTimer?.cancel();
    _floatingHideTimer = Timer(const Duration(milliseconds: 920), () {
      if (!mounted) return;
      setState(() {
        _activeFloatingSerial = null;
      });
    });
    _schedulePersist();
    if (_autoRunning &&
        _autoStopAtGoal &&
        _targetCount > 0 &&
        _sessionCount >= _targetCount) {
      _stopAuto();
    }
  }

  void _startHoldRoll() {
    if (_autoRunning) {
      return;
    }
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 130), (_) {
      unawaited(_performStrike(gesture: 'Hold'));
    });
  }

  void _stopHoldRoll() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  void _scheduleAutoTick() {
    if (!_autoRunning) {
      return;
    }
    final pulsePerMinute = _bpm * _subdivision;
    final intervalUs = math.max(12000, (60000000 / pulsePerMinute).round());
    final nowUs = DateTime.now().microsecondsSinceEpoch;
    final nextAnchor = (_transportAnchorUs ?? nowUs) + intervalUs;
    _transportAnchorUs = nextAnchor;
    final delayUs = math.max(0, nextAnchor - nowUs);
    _autoTimer?.cancel();
    _autoTimer = Timer(Duration(microseconds: delayUs), () {
      unawaited(_performStrike(gesture: 'Auto', fromAuto: true));
      _scheduleAutoTick();
    });
  }

  void _resyncAutoScheduler() {
    if (!_autoRunning) {
      return;
    }
    _transportAnchorUs = DateTime.now().microsecondsSinceEpoch;
    _scheduleAutoTick();
  }

  void _startAuto() {
    if (_autoRunning) {
      return;
    }
    setState(() {
      _autoRunning = true;
      _lastGesture = 'Auto';
    });
    _transportAnchorUs = DateTime.now().microsecondsSinceEpoch;
    unawaited(_performStrike(gesture: 'Auto', fromAuto: true));
    _scheduleAutoTick();
  }

  void _stopAuto() {
    _autoTimer?.cancel();
    _autoTimer = null;
    _transportAnchorUs = null;
    if (!mounted) {
      return;
    }
    setState(() {
      _autoRunning = false;
    });
  }

  void _toggleAuto() {
    if (_autoRunning) {
      _stopAuto();
    } else {
      _startAuto();
    }
  }

  void _resetSession() {
    _stopAuto();
    _stopHoldRoll();
    _floatingHideTimer?.cancel();
    _sessionStopwatch
      ..stop()
      ..reset();
    _sessionTicker?.cancel();
    _sessionTicker = null;
    setState(() {
      _sessionCount = 0;
      _pulseInCycle = 0;
      _elapsed = Duration.zero;
      _lastGesture = 'Reset';
      _activeFloatingSerial = null;
    });
    _schedulePersist();
  }

  void _resetAllTime() {
    setState(() {
      _allTimeCount = 0;
    });
    _schedulePersist();
  }

  void _markCustomRhythm() {
    if (_activeRhythmPresetId != 'custom') {
      _activeRhythmPresetId = 'custom';
    }
  }

  void _applyRhythmPreset(_WoodfishRhythmPreset preset) {
    final cyclePulses = math.max(1, preset.beatsPerCycle * preset.subdivision);
    setState(() {
      _activeRhythmPresetId = preset.id;
      _bpm = preset.bpm;
      _beatsPerCycle = preset.beatsPerCycle;
      _subdivision = preset.subdivision;
      _accentEvery = preset.accentEvery.clamp(1, cyclePulses);
      _targetCount = preset.targetCount;
      _pulseInCycle = _pulseInCycle % cyclePulses;
    });
    _resyncAutoScheduler();
    _schedulePersist();
  }

  Future<void> _openSettingsSheet(BuildContext context) {
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildRhythmSettings(
                      sheetContext,
                      refreshSheet: () => setSheetState(() {}),
                    ),
                    const SizedBox(height: 18),
                    _buildToneSettings(
                      sheetContext,
                      refreshSheet: () => setSheetState(() {}),
                    ),
                    const SizedBox(height: 18),
                    _buildAdvancedSettings(
                      sheetContext,
                      refreshSheet: () => setSheetState(() {}),
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

  Widget _buildRhythmSettings(
    BuildContext context, {
    required VoidCallback refreshSheet,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: _uiText(context, zh: '禅拍节律', en: 'Rhythm arrangement'),
          subtitle: _uiText(
            context,
            zh: '先选预设入手，再微调 BPM、拍数与重音，让节律更贴合呼吸。',
            en: 'Start with presets, then tune BPM, pulse count, and accents.',
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _rhythmPresets
              .map(
                (preset) => ChoiceChip(
                  label: Text(_rhythmLabel(context, preset.id)),
                  selected: _activeRhythmPresetId == preset.id,
                  onSelected: (_) {
                    _applyRhythmPreset(preset);
                    refreshSheet();
                  },
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        Text(_uiText(context, zh: '每分钟拍数 $_bpm', en: 'BPM $_bpm')),
        Slider(
          value: _bpm.toDouble(),
          min: 36,
          max: 168,
          divisions: 132,
          onChanged: (value) {
            setState(() {
              _bpm = value.round();
              _markCustomRhythm();
            });
            _resyncAutoScheduler();
            refreshSheet();
          },
          onChangeEnd: (_) => _schedulePersist(),
        ),
        Text(
          _uiText(
            context,
            zh: '每轮拍数 $_beatsPerCycle',
            en: 'Beats per cycle $_beatsPerCycle',
          ),
        ),
        Slider(
          value: _beatsPerCycle.toDouble(),
          min: 2,
          max: 12,
          divisions: 10,
          onChanged: (value) {
            final beats = value.round();
            final cyclePulses = math.max(1, beats * _subdivision);
            setState(() {
              _beatsPerCycle = beats;
              _accentEvery = _accentEvery.clamp(1, cyclePulses);
              _pulseInCycle = _pulseInCycle % cyclePulses;
              _markCustomRhythm();
            });
            _resyncAutoScheduler();
            refreshSheet();
          },
          onChangeEnd: (_) => _schedulePersist(),
        ),
        Text(
          _uiText(
            context,
            zh: '子拍细分 $_subdivision',
            en: 'Subdivision $_subdivision',
          ),
        ),
        Slider(
          value: _subdivision.toDouble(),
          min: 1,
          max: 4,
          divisions: 3,
          onChanged: (value) {
            final subdivision = value.round();
            final cyclePulses = math.max(1, _beatsPerCycle * subdivision);
            setState(() {
              _subdivision = subdivision;
              _accentEvery = _accentEvery.clamp(1, cyclePulses);
              _pulseInCycle = _pulseInCycle % cyclePulses;
              _markCustomRhythm();
            });
            _resyncAutoScheduler();
            refreshSheet();
          },
          onChangeEnd: (_) => _schedulePersist(),
        ),
        Text(
          _uiText(
            context,
            zh: '每 $_accentEvery 拍重音一次',
            en: 'Accent every $_accentEvery pulses',
          ),
        ),
        Slider(
          value: _accentEvery.toDouble(),
          min: 1,
          max: _cyclePulses.toDouble(),
          divisions: math.max(0, _cyclePulses - 1),
          onChanged: (value) {
            setState(() {
              _accentEvery = value.round().clamp(1, _cyclePulses);
              _markCustomRhythm();
            });
            refreshSheet();
          },
          onChangeEnd: (_) => _schedulePersist(),
        ),
      ],
    );
  }

  Widget _buildToneSettings(
    BuildContext context, {
    required VoidCallback refreshSheet,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: _uiText(context, zh: '木鱼音色', en: 'Tone shaping'),
          subtitle: _uiText(
            context,
            zh: '调节共鸣、亮度、音高与击打力度，塑造你自己的木鱼声场。',
            en: 'Tune resonance, brightness, pitch, and strike hardness.',
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _uiText(context, zh: '东方意境皮肤', en: 'Eastern visual style'),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _WoodfishVisualStyle.values
              .map(
                (style) => ChoiceChip(
                  label: Text(_visualStyleLabel(context, style)),
                  selected: _visualStyle == style,
                  onSelected: (_) {
                    if (_visualStyle == style) return;
                    setState(() {
                      _visualStyle = style;
                    });
                    _schedulePersist();
                    refreshSheet();
                  },
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 8),
        Text(
          _visualStyleHint(context, _visualStyle),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        Text(
          _uiText(context, zh: '木鱼音色包', en: 'Woodfish timbre'),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _WoodfishSoundProfile.values
              .map(
                (profile) => ChoiceChip(
                  label: Text(_soundLabelText(context, profile)),
                  selected: _soundProfile == profile,
                  onSelected: (_) {
                    if (_soundProfile == profile) return;
                    setState(() {
                      _soundProfile = profile;
                    });
                    unawaited(_rebuildPlayers(preview: true));
                    _schedulePersist();
                    refreshSheet();
                  },
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        Text(
          _uiText(
            context,
            zh: '主音量 ${(_masterVolume * 100).round()}%',
            en: 'Master volume ${(_masterVolume * 100).round()}%',
          ),
        ),
        Slider(
          value: _masterVolume,
          min: 0.1,
          max: 1,
          divisions: 18,
          onChanged: (value) {
            setState(() => _masterVolume = value);
            refreshSheet();
          },
          onChangeEnd: (_) => _schedulePersist(),
        ),
        Text(
          _uiText(
            context,
            zh: '重音增强 +${(_accentBoost * 100).round()}%',
            en: 'Accent boost +${(_accentBoost * 100).round()}%',
          ),
        ),
        Slider(
          value: _accentBoost,
          min: 0.0,
          max: 0.5,
          divisions: 20,
          onChanged: (value) {
            setState(() => _accentBoost = value);
            refreshSheet();
          },
          onChangeEnd: (_) => _schedulePersist(),
        ),
        Text(
          _uiText(
            context,
            zh: '共鸣 ${(_resonance * 100).round()}%',
            en: 'Resonance ${(_resonance * 100).round()}%',
          ),
        ),
        Slider(
          value: _resonance,
          min: 0,
          max: 1,
          divisions: 20,
          onChanged: (value) {
            setState(() => _resonance = value);
            refreshSheet();
          },
          onChangeEnd: (_) {
            unawaited(_rebuildPlayers(preview: true));
            _schedulePersist();
          },
        ),
        Text(
          _uiText(
            context,
            zh: '亮度 ${(_brightness * 100).round()}%',
            en: 'Brightness ${(_brightness * 100).round()}%',
          ),
        ),
        Slider(
          value: _brightness,
          min: 0,
          max: 1,
          divisions: 20,
          onChanged: (value) {
            setState(() => _brightness = value);
            refreshSheet();
          },
          onChangeEnd: (_) {
            unawaited(_rebuildPlayers(preview: true));
            _schedulePersist();
          },
        ),
        Text(
          _uiText(
            context,
            zh: '音高 ${_pitch >= 0 ? '+' : ''}${_pitch.toStringAsFixed(1)} 半音',
            en: 'Pitch ${_pitch >= 0 ? '+' : ''}${_pitch.toStringAsFixed(1)} st',
          ),
        ),
        Slider(
          value: _pitch,
          min: -4,
          max: 4,
          divisions: 16,
          onChanged: (value) {
            setState(() => _pitch = value);
            refreshSheet();
          },
          onChangeEnd: (_) {
            unawaited(_rebuildPlayers(preview: true));
            _schedulePersist();
          },
        ),
        Text(
          _uiText(
            context,
            zh: '击打硬度 ${(_strikeHardness * 100).round()}%',
            en: 'Strike hardness ${(_strikeHardness * 100).round()}%',
          ),
        ),
        Slider(
          value: _strikeHardness,
          min: 0,
          max: 1,
          divisions: 20,
          onChanged: (value) {
            setState(() => _strikeHardness = value);
            refreshSheet();
          },
          onChangeEnd: (_) {
            unawaited(_rebuildPlayers(preview: true));
            _schedulePersist();
          },
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings(
    BuildContext context, {
    required VoidCallback refreshSheet,
  }) {
    final blessingPresets = <String>[
      '功德 +1',
      '清心 +1',
      '福慧增长',
      '诸事顺意',
      '一念归静',
      '愿心圆满',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: _uiText(context, zh: '修持与细节', en: 'Advanced'),
          subtitle: _uiText(
            context,
            zh: '设置每日目标、触感反馈、自动止拍与漂浮愿词，让体验更沉静。',
            en: 'Fine tune target, haptics, auto-stop, and floating blessings.',
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _uiText(context, zh: '修持目标', en: 'Target count'),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <int>[27, 54, 81, 108, 216, 324]
              .map(
                (item) => ChoiceChip(
                  label: Text('$item'),
                  selected: _targetCount == item,
                  onSelected: (_) {
                    setState(() {
                      _targetCount = item;
                    });
                    _schedulePersist();
                    refreshSheet();
                  },
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(_uiText(context, zh: '启用触感反馈', en: 'Enable haptics')),
          subtitle: Text(
            _uiText(
              context,
              zh: '手动叩击时给出轻微震感，帮助建立节律沉浸。',
              en: 'Add subtle vibration to manual strikes.',
            ),
          ),
          value: _hapticsEnabled,
          onChanged: (value) {
            setState(() => _hapticsEnabled = value);
            _schedulePersist();
            refreshSheet();
          },
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(
            _uiText(context, zh: '达到目标后止拍', en: 'Auto stop at target'),
          ),
          subtitle: Text(
            _uiText(
              context,
              zh: '自动节拍达到目标数后自动停下，便于结束当次修持。',
              en: 'Stop auto rhythm once the target is reached.',
            ),
          ),
          value: _autoStopAtGoal,
          onChanged: (value) {
            setState(() => _autoStopAtGoal = value);
            _schedulePersist();
            refreshSheet();
          },
        ),
        const SizedBox(height: 10),
        Text(
          _uiText(context, zh: '击槌回弹弧线', en: 'Mallet rebound arc'),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _WoodfishReboundArcPreset.values
              .map(
                (preset) => ChoiceChip(
                  label: Text(_reboundArcLabel(context, preset)),
                  selected: _reboundArcPreset == preset,
                  onSelected: (_) {
                    if (_reboundArcPreset == preset) {
                      return;
                    }
                    setState(() {
                      _reboundArcPreset = preset;
                    });
                    _schedulePersist();
                    refreshSheet();
                  },
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 6),
        Text(
          _reboundArcHint(context, _reboundArcPreset),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Text(
          _uiText(context, zh: '漂浮愿词', en: 'Floating text'),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _floatingTextController,
          maxLength: 18,
          decoration: InputDecoration(
            hintText: _uiText(
              context,
              zh: '例如：功德 +1、清心 +1',
              en: 'For example: Merit +1',
            ),
            prefixIcon: const Icon(Icons.auto_awesome_rounded),
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.singleLineFormatter,
            LengthLimitingTextInputFormatter(18),
          ],
          onChanged: (value) {
            final normalized = value.replaceAll('\n', ' ').trim();
            setState(() {
              _floatingText = normalized.isEmpty ? '功德 +1' : normalized;
            });
            _schedulePersist();
            refreshSheet();
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: blessingPresets
              .map(
                (text) => ActionChip(
                  label: Text(text),
                  onPressed: () {
                    setState(() {
                      _floatingText = text;
                    });
                    _floatingTextController.value = TextEditingValue(
                      text: text,
                      selection: TextSelection.collapsed(offset: text.length),
                    );
                    _schedulePersist();
                    refreshSheet();
                  },
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: _resetSession,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_uiText(context, zh: '重置本次修持', en: 'Reset session')),
            ),
            OutlinedButton.icon(
              onPressed: _resetAllTime,
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(_uiText(context, zh: '清空总计', en: 'Clear total')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStrikeStage(
    BuildContext context, {
    required bool immersive,
    required double height,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = _visualTokens(_visualStyle);
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        _strikeController,
        _ambientController,
      ]),
      builder: (context, _) {
        final strikeT = _strikeController.value.clamp(0.0, 1.0);
        // ── Faster downstroke (22%), slower rebound (78%) ──
        const downSplit = 0.22;
        final downT = (strikeT / downSplit).clamp(0.0, 1.0);
        final upT = ((strikeT - downSplit) / (1 - downSplit)).clamp(0.0, 1.0);
        final strikeDownPhase = Curves.easeInQuart.transform(downT);
        final strikeUpPhase = Curves.easeOutCubic.transform(upT);
        final arcWide = _reboundArcPreset == _WoodfishReboundArcPreset.wide;

        // ── Elastic micro-bounces in rebound (damped sine) ──
        final bounceCount = arcWide ? 2.5 : 2.0;
        final dampedBounce = math.sin(upT * math.pi * bounceCount) *
            math.exp(-upT * 3.2) *
            (arcWide ? 0.09 : 0.06);

        // ── Mallet motion: swings down from upper-right ──
        final malletAngle = strikeT <= downSplit
            ? _mixDouble(-0.38, 0.08, strikeDownPhase)
            : _mixDouble(0.08, -0.36, strikeUpPhase) + dampedBounce;
        final malletDrop = strikeT <= downSplit
            ? _mixDouble(-30, 8, strikeDownPhase)
            : _mixDouble(8, -28, strikeUpPhase) -
                  dampedBounce * (arcWide ? 10 : 6);
        final malletDriftX = strikeT <= downSplit
            ? _mixDouble(-18, -1, strikeDownPhase)
            : _mixDouble(-1, arcWide ? 20 : 14, strikeUpPhase) +
                  dampedBounce * (arcWide ? 24 : 16);

        // ── Impact intensity with sharper peak ──
        final contactWave = strikeT <= downSplit
            ? Curves.easeIn.transform(downT)
            : (1 - Curves.easeOut.transform(upT)) * 0.5;
        final impact = (math.sin(strikeT * math.pi) * 0.78 + contactWave)
            .clamp(0.0, 1.0);

        // ── Body squash (subtle vertical compression on impact) ──
        final squash = strikeT <= downSplit
            ? strikeDownPhase * 0.028
            : (1 - strikeUpPhase) * 0.028 * math.exp(-upT * 2.8);

        // ── Wobble rotation on impact ──
        final wobble = strikeT <= downSplit
            ? 0.0
            : math.sin(upT * math.pi * 3.5) * math.exp(-upT * 4.2) * 0.018;

        final cycleProgress = _cyclePulses <= 1
            ? 0.0
            : _pulseInCycle / _cyclePulses;
        final ambient = _ambientController.value;

        // ── Image sizing ──
        final imageW = math.min(height * 0.72, 280.0);
        final imageH = imageW * 0.62; // Match the real woodfish aspect ratio
        final imageTop = height * 0.34;

        // ── Text styles ──
        final countTextStyle = Theme.of(context).textTheme.displaySmall
            ?.copyWith(
              fontWeight: FontWeight.w800,
              color: immersive ? Colors.white : colorScheme.onSurface,
              letterSpacing: 1.2,
            );
        final detailTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: immersive
              ? Colors.white.withValues(alpha: 0.72)
              : colorScheme.onSurfaceVariant,
        );

        // ── Accent color for effects ──
        final accentColor = _lastWasAccent
            ? tokens.accentWarm
            : tokens.accentCool;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => unawaited(_performStrike(gesture: 'Tap')),
          onLongPressStart: (_) {
            unawaited(_performStrike(gesture: 'Hold'));
            _startHoldRoll();
          },
          onLongPressEnd: (_) => _stopHoldRoll(),
          onLongPressCancel: _stopHoldRoll,
          child: SizedBox(
            width: double.infinity,
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  // ── 1. Background stage ──
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _WoodfishStagePainter(
                        colorScheme: colorScheme,
                        impact: impact,
                        ambient: ambient,
                        cycleProgress: cycleProgress,
                        accent: _lastWasAccent,
                        immersive: immersive,
                        visualStyle: _visualStyle,
                      ),
                    ),
                  ),

                  // ── 2. Shadow beneath the woodfish ──
                  Positioned(
                    top: imageTop + imageH * 0.82,
                    child: Container(
                      width: imageW * (0.72 + impact * 0.06),
                      height: imageH * 0.18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: immersive ? 0.5 : 0.32,
                            ),
                            blurRadius: 22 + impact * 8,
                            spreadRadius: 2 + impact * 4,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── 3. Impact ripple rings (behind the woodfish) ──
                  if (impact > 0.02)
                    Positioned(
                      top: imageTop + imageH * 0.35,
                      child: SizedBox(
                        width: imageW * 1.6,
                        height: imageW * 1.6,
                        child: CustomPaint(
                          painter: _WoodfishRipplePainter(
                            impact: impact,
                            ambient: ambient,
                            accentColor: accentColor,
                            immersive: immersive,
                          ),
                        ),
                      ),
                    ),

                  // ── 4. Woodfish body (CustomPaint, realistic) ──
                  Positioned(
                    top: imageTop + impact * 3,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.diagonal3Values(
                        1.0 + impact * 0.015,
                        1.0 - squash,
                        1.0,
                      )..rotateZ(wobble),
                      child: SizedBox(
                        width: imageW,
                        height: imageH,
                        child: CustomPaint(
                          painter: _WoodfishBodyPainter(
                            impact: impact,
                            ambient: ambient,
                            accent: _lastWasAccent,
                            immersive: immersive,
                            visualStyle: _visualStyle,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── 5. Mallet ──
                  Positioned(
                    top: height * 0.06 + malletDrop,
                    child: Transform.translate(
                      offset: Offset(malletDriftX, 0),
                      child: Transform.rotate(
                        alignment: const Alignment(-0.2, 0.78),
                        angle: malletAngle,
                        child: SizedBox(
                          width: math.min(220, height * 0.68),
                          height: math.min(130, height * 0.35),
                          child: CustomPaint(
                            painter: _WoodfishMalletPainter(
                              colorScheme: colorScheme,
                              immersive: immersive,
                              impact: impact,
                              visualStyle: _visualStyle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── 6. Impact contact spark ──
                  if (impact > 0.3)
                    Positioned(
                      top: imageTop - 2 + impact * 3,
                      child: Container(
                        width: 8 + impact * 12,
                        height: 8 + impact * 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: accentColor.withValues(
                                alpha: (impact - 0.3) * 0.8,
                              ),
                              blurRadius: 16 + impact * 10,
                              spreadRadius: impact * 4,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── 7. Cycle progress arc ──
                  Positioned(
                    top: imageTop - 10,
                    child: SizedBox(
                      width: imageW + 20,
                      height: imageH + 20,
                      child: CustomPaint(
                        painter: _WoodfishCycleRingPainter(
                          cycleProgress: cycleProgress,
                          accentColor: accentColor,
                          immersive: immersive,
                        ),
                      ),
                    ),
                  ),

                  // ── 8. Count display ──
                  Positioned(
                    top: height * 0.06,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text('$_sessionCount', style: countTextStyle),
                        const SizedBox(height: 2),
                        Text(
                          _uiText(
                            context,
                            zh: '目标 $_targetCount · 轮拍 ${_pulseInCycle + 1}/$_cyclePulses',
                            en: 'Target $_targetCount · ${_pulseInCycle + 1}/$_cyclePulses',
                          ),
                          style: detailTextStyle,
                        ),
                      ],
                    ),
                  ),

                  // ── 9. Floating blessing text ──
                  Positioned(
                    top: height * 0.20,
                    child: _buildFloatingBlessing(context, immersive: immersive),
                  ),

                  // ── 10. Pulse indicators ──
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: _buildPulseIndicators(context, immersive: immersive),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingBlessing(
    BuildContext context, {
    required bool immersive,
  }) {
    final baseText = _resolvedFloatingText;
    final accentPrimary = _stylePrimaryAccent();
    final accentSecondary = _styleSecondaryAccent();
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 860),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          );
          final slide =
              Tween<Offset>(
                begin: const Offset(0, 0.38),
                end: const Offset(0, -0.42),
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                ),
              );
          final scale = Tween<double>(begin: 0.9, end: 1.06).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
              reverseCurve: Curves.easeIn,
            ),
          );
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: ScaleTransition(scale: scale, child: child),
            ),
          );
        },
        child: _activeFloatingSerial == null
            ? const SizedBox.shrink(key: ValueKey<String>('floating-hidden'))
            : DecoratedBox(
                key: ValueKey<int>(_activeFloatingSerial!),
                decoration: BoxDecoration(
                  color: (immersive ? Colors.black : Colors.white).withValues(
                    alpha: immersive ? 0.34 : 0.76,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: (immersive ? accentPrimary : accentSecondary)
                        .withValues(alpha: 0.42),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: (immersive ? accentPrimary : accentSecondary)
                          .withValues(alpha: 0.24),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  child: Text(
                    baseText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: immersive
                          ? const Color(0xFFF8E7C3)
                          : accentPrimary,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPulseIndicators(
    BuildContext context, {
    required bool immersive,
  }) {
    final accentPrimary = _stylePrimaryAccent();
    final accentSecondary = _styleSecondaryAccent();
    final visibleCount = _cyclePulses.clamp(1, 12);
    final activePulse = _pulseInCycle % _cyclePulses;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: (immersive ? Colors.black : Colors.white).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: immersive
              ? Colors.white.withValues(alpha: 0.16)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (var index = 0; index < visibleCount; index += 1)
              Builder(
                builder: (context) {
                  final mappedPulse = ((index / visibleCount) * _cyclePulses)
                      .floor()
                      .clamp(0, _cyclePulses - 1);
                  final active = mappedPulse == activePulse;
                  final accent = _isAccentPulse(mappedPulse);
                  return Container(
                    width: active ? 11 : 7,
                    height: active ? 11 : 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? (accent ? accentPrimary : accentSecondary)
                          : (immersive
                                ? Colors.white.withValues(alpha: 0.24)
                                : Theme.of(context).colorScheme.outlineVariant
                                      .withValues(alpha: accent ? 0.6 : 0.34)),
                      boxShadow: active
                          ? <BoxShadow>[
                              BoxShadow(
                                color:
                                    (accent ? accentPrimary : accentSecondary)
                                        .withValues(alpha: 0.42),
                                blurRadius: 9,
                              ),
                            ]
                          : const <BoxShadow>[],
                    ),
                  );
                },
              ),
            if (_cyclePulses > visibleCount) ...<Widget>[
              const SizedBox(width: 8),
              Text(
                'x$_cyclePulses',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: immersive ? Colors.white70 : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickControls(BuildContext context, {required bool immersive}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        FilledButton.icon(
          onPressed: () => unawaited(_performStrike(gesture: 'Button')),
          icon: const Icon(Icons.pan_tool_alt_rounded),
          label: Text(_uiText(context, zh: '轻叩一次', en: 'Strike once')),
        ),
        FilledButton.tonalIcon(
          onPressed: _toggleAuto,
          icon: Icon(
            _autoRunning
                ? Icons.pause_circle_rounded
                : Icons.play_circle_rounded,
          ),
          label: Text(
            _uiText(
              context,
              zh: _autoRunning ? '止拍' : '启拍',
              en: _autoRunning ? 'Stop auto' : 'Start auto',
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _resetSession,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(_uiText(context, zh: '重置本次', en: 'Reset session')),
          style: immersive
              ? OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
                )
              : null,
        ),
        if (!widget.fullScreen && widget.onOpenFullScreen != null)
          OutlinedButton.icon(
            onPressed: () {
              final shouldAutoStart = _autoRunning;
              _suspendForOverlay();
              widget.onOpenFullScreen?.call(autoStart: shouldAutoStart);
            },
            icon: const Icon(Icons.open_in_full_rounded),
            label: Text(_uiText(context, zh: '全屏', en: 'Full screen')),
          ),
        if (widget.fullScreen)
          OutlinedButton.icon(
            onPressed: () => _openSettingsSheet(context),
            icon: const Icon(Icons.tune_rounded),
            label: Text(_uiText(context, zh: '设置', en: 'Settings')),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
            ),
          ),
      ],
    );
  }

  Widget _buildNormal(BuildContext context) {
    return _buildInstrumentPanelShell(
      context,
      fullScreen: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              ToolboxMetricCard(
                label: _uiText(context, zh: '本次', en: 'Session'),
                value: '$_sessionCount',
              ),
              ToolboxMetricCard(
                label: _uiText(context, zh: '累计', en: 'Total'),
                value: '$_allTimeCount',
              ),
              ToolboxMetricCard(
                label: _uiText(context, zh: '时长', en: 'Elapsed'),
                value: _formatElapsed(_elapsed),
              ),
              ToolboxMetricCard(
                label: _uiText(context, zh: '模式', en: 'Mode'),
                value: _modeLabelText(context),
              ),
              ToolboxMetricCard(
                label: _uiText(context, zh: '节律', en: 'Rhythm'),
                value: _rhythmLabel(context, _activeRhythmPresetId),
              ),
              ToolboxMetricCard(
                label: _uiText(context, zh: '音色', en: 'Tone'),
                value: _soundLabelText(context, _soundProfile),
              ),
              ToolboxMetricCard(
                label: _uiText(context, zh: '意境', en: 'Style'),
                value: _visualStyleLabel(context, _visualStyle),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SectionHeader(
            title: _uiText(context, zh: '叩击禅台', en: 'Strike stage'),
            subtitle: _uiText(
              context,
              zh: '轻触一叩，长按连击；亦可启拍，让呼吸与节律自然归一。',
              en: 'Tap to strike, hold to roll, or start auto mode for stable pulse.',
            ),
          ),
          const SizedBox(height: 10),
          _buildStrikeStage(context, immersive: false, height: 300),
          const SizedBox(height: 10),
          Text(
            _uiText(
              context,
              zh: '当前手势：${_gestureLabel(context)} · 愿词：$_resolvedFloatingText',
              en: 'Gesture: ${_gestureLabel(context)} · Floating text: $_resolvedFloatingText',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          _buildQuickControls(context, immersive: false),
          const SizedBox(height: 18),
          _buildRhythmSettings(context, refreshSheet: () {}),
          const SizedBox(height: 18),
          _buildToneSettings(context, refreshSheet: () {}),
          const SizedBox(height: 18),
          _buildAdvancedSettings(context, refreshSheet: () {}),
        ],
      ),
    );
  }

  Widget _buildFullScreen(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: _screenBackgroundGradient()),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stageHeight = math.min(460.0, constraints.maxHeight - 230);
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14, 64, 14, bottomInset + 124),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            _PianoOverlayChip(
                              label: _uiText(context, zh: '模式', en: 'Mode'),
                              value: _modeLabelText(context),
                            ),
                            _PianoOverlayChip(
                              label: _uiText(context, zh: '轮拍', en: 'Cycle'),
                              value: '${_pulseInCycle + 1}/$_cyclePulses',
                            ),
                            _PianoOverlayChip(
                              label: _uiText(context, zh: '目标', en: 'Target'),
                              value: '$_sessionCount/$_targetCount',
                            ),
                            _PianoOverlayChip(
                              label: _uiText(context, zh: '音色', en: 'Tone'),
                              value: _soundLabelText(context, _soundProfile),
                            ),
                            _PianoOverlayChip(
                              label: _uiText(context, zh: '意境', en: 'Style'),
                              value: _visualStyleLabel(context, _visualStyle),
                            ),
                            _PianoOverlayChip(label: 'BPM', value: '$_bpm'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildStrikeStage(
                          context,
                          immersive: true,
                          height: stageHeight,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  top: 8,
                  child: Row(
                    children: <Widget>[
                      FilledButton.tonal(
                        onPressed: widget.onExitFullScreen,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.34),
                          foregroundColor: Colors.white,
                        ),
                        child: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: () => _openSettingsSheet(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.34),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.tune_rounded),
                        label: Text(_uiText(context, zh: '设置', en: 'Settings')),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: bottomInset + 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            _uiText(
                              context,
                              zh: '手机沉浸禅台：大触控区、拟真击槌、可自定义愿词与节律。',
                              en: 'Mobile immersive mode with large touch targets and realistic motion.',
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 10),
                          _buildQuickControls(context, immersive: true),
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
  Widget build(BuildContext context) {
    if (widget.fullScreen) {
      return _buildFullScreen(context);
    }
    return _buildNormal(context);
  }
}

class _WoodfishStagePainter extends CustomPainter {
  const _WoodfishStagePainter({
    required this.colorScheme,
    required this.impact,
    required this.ambient,
    required this.cycleProgress,
    required this.accent,
    required this.immersive,
    required this.visualStyle,
  });

  final ColorScheme colorScheme;
  final double impact;
  final double ambient;
  final double cycleProgress;
  final bool accent;
  final bool immersive;
  final _WoodfishVisualStyle visualStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final tokens = _visualTokens(visualStyle);
    final rect = Offset.zero & size;

    // ── Stage background gradient ──
    final stageColors = immersive
        ? tokens.immersiveStageGradient
        : tokens.normalStageGradient;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            stageColors[0],
            Color.lerp(stageColors[1], stageColors[2], ambient * 0.7)!,
            stageColors[2],
          ],
        ).createShader(rect),
    );

    // ── Subtle vignette ──
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.2),
          radius: 1.1,
          colors: <Color>[
            Colors.transparent,
            Colors.black.withValues(alpha: immersive ? 0.32 : 0.12),
          ],
          stops: const <double>[0.5, 1.0],
        ).createShader(rect),
    );

    // ── Ambient haze / dust overlay ──
    if (immersive) {
      // Subtle warm glow at center
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, 0.3),
            radius: 0.9,
            colors: <Color>[
              tokens.accentWarm.withValues(alpha: 0.04 + impact * 0.03),
              Colors.transparent,
            ],
          ).createShader(rect),
      );
    } else {
      // Light-mode wood-grain texture lines
      final texturePaint = Paint()
        ..color = tokens.grain.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      for (var index = 0; index < 5; index += 1) {
        final y = rect.top + rect.height * (0.18 + index * 0.14);
        final sway = math.sin((ambient + index * 0.2) * math.pi * 2) * 6;
        final path = Path()
          ..moveTo(rect.left - 20, y + sway * 0.2)
          ..cubicTo(
            rect.width * 0.24,
            y - 6 + sway,
            rect.width * 0.56,
            y + 10 - sway * 0.7,
            rect.right + 20,
            y - 3 + sway * 0.25,
          );
        canvas.drawPath(path, texturePaint);
      }
    }

    // ── Floating dust particles ──
    for (var i = 0; i < 8; i += 1) {
      final phase = (ambient + i * 0.14) % 1.0;
      final px = rect.left + rect.width * (0.1 + i * 0.11);
      final py = rect.top + rect.height * (0.15 + phase * 0.65);
      final drift = math.sin((ambient * 2 + i * 0.3) * math.pi) * 8;
      canvas.drawCircle(
        Offset(px + drift, py),
        0.8 + (i % 3) * 0.4,
        Paint()
          ..color = tokens.dust.withValues(
            alpha: (immersive ? 0.06 : 0.1) *
                (1 - phase * 0.6) *
                (0.6 + impact * 0.5),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WoodfishStagePainter oldDelegate) {
    return oldDelegate.impact != impact ||
        oldDelegate.ambient != ambient ||
        oldDelegate.cycleProgress != cycleProgress ||
        oldDelegate.accent != accent ||
        oldDelegate.immersive != immersive ||
        oldDelegate.visualStyle != visualStyle;
  }
}

/// Expanding concentric ripple rings on impact.
class _WoodfishRipplePainter extends CustomPainter {
  const _WoodfishRipplePainter({
    required this.impact,
    required this.ambient,
    required this.accentColor,
    required this.immersive,
  });

  final double impact;
  final double ambient;
  final Color accentColor;
  final bool immersive;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final maxRadius = size.width * 0.48;

    // Draw 3 expanding rings with staggered timing
    for (var i = 0; i < 3; i += 1) {
      final ringImpact = (impact - i * 0.18).clamp(0.0, 1.0);
      if (ringImpact <= 0.005) continue;

      final radius = maxRadius * (0.3 + ringImpact * 0.7);
      final alpha = (0.28 * (1 - ringImpact)).clamp(0.0, 1.0);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = accentColor.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 - ringImpact * 0.8,
      );
    }

    // Inner glow pulse
    if (impact > 0.1) {
      canvas.drawCircle(
        center,
        maxRadius * 0.22 * impact,
        Paint()
          ..color = accentColor.withValues(alpha: impact * 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WoodfishRipplePainter oldDelegate) {
    return oldDelegate.impact != impact || oldDelegate.ambient != ambient;
  }
}

/// Thin arc showing cycle progress around the woodfish image area.
class _WoodfishCycleRingPainter extends CustomPainter {
  const _WoodfishCycleRingPainter({
    required this.cycleProgress,
    required this.accentColor,
    required this.immersive,
  });

  final double cycleProgress;
  final Color accentColor;
  final bool immersive;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ovalRect = Rect.fromCenter(
      center: rect.center,
      width: rect.width * 0.92,
      height: rect.height * 0.92,
    );

    // Background ring
    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = (immersive ? Colors.white : Colors.black)
            .withValues(alpha: immersive ? 0.08 : 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Progress arc
    if (cycleProgress > 0.001) {
      canvas.drawArc(
        ovalRect,
        -math.pi / 2,
        math.pi * 2 * cycleProgress.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = accentColor.withValues(alpha: immersive ? 0.5 : 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WoodfishCycleRingPainter oldDelegate) {
    return oldDelegate.cycleProgress != cycleProgress ||
        oldDelegate.immersive != immersive;
  }
}

/// Draws a realistic wooden fish (木鱼) in 3/4 perspective.
///
/// Anatomy (matching the reference photo):
///   - Plump, egg-shaped body viewed from slightly above, lying on its side
///   - The LEFT end is the rounded tail
///   - The RIGHT end narrows to a pointed head / nose
///   - A horizontal SLIT runs along the right side of the body (the "mouth"),
///     exposing the dark hollow interior — this is the resonance cavity
///   - The body has a pronounced dome (3D volume), not flat
///   - Natural pale-wood colouring with subtle grain
class _WoodfishBodyPainter extends CustomPainter {
  const _WoodfishBodyPainter({
    required this.impact,
    required this.ambient,
    required this.accent,
    required this.immersive,
    required this.visualStyle,
  });

  final double impact;
  final double ambient;
  final bool accent;
  final bool immersive;
  final _WoodfishVisualStyle visualStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final tokens = _visualTokens(visualStyle);
    final w = size.width;
    final h = size.height;

    // Body centre & dimensions — wider than tall to look plump & rounded.
    final cx = w * 0.45;
    final cy = h * 0.54;
    final bw = w * 0.90; // total body width (left-to-right)
    final bh = h * 0.78; // total body height (top-to-bottom dome)

    // ── 1. Ground contact shadow ──
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + bh * 0.42),
        width: bw * 0.68,
        height: bh * 0.14,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: immersive ? 0.40 : 0.24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // ── 2. Impact halo (behind body) ──
    if (impact > 0.06) {
      final haloColor = accent ? tokens.accentWarm : tokens.accentCool;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: bw * 1.08,
          height: bh * 1.08,
        ),
        Paint()
          ..color = haloColor.withValues(alpha: impact * 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
      );
    }

    // ── 3. Main body outline (plump egg / fish shape) ──
    //
    // The shape is like a horizontal egg with the narrow end (nose/head)
    // pointing right and the wide end (tail) on the left.
    // The TOP contour bulges upward strongly to convey dome volume.
    // The BOTTOM contour is flatter (sitting on a surface).
    final bodyPath = Path()
      // Start at the tail (leftmost point, slightly below centre)
      ..moveTo(cx - bw * 0.48, cy + bh * 0.02)
      // ── Bottom contour (belly) — gently curves right ──
      ..cubicTo(
        cx - bw * 0.32, cy + bh * 0.38, // wide belly sag
        cx + bw * 0.10, cy + bh * 0.40, // belly peak
        cx + bw * 0.42, cy + bh * 0.06, // converges toward nose
      )
      // ── Nose tip (rightmost, slightly above centre) ──
      ..quadraticBezierTo(
        cx + bw * 0.52, cy - bh * 0.06,
        cx + bw * 0.42, cy - bh * 0.18,
      )
      // ── Top contour (dome) — high arc leftward ──
      ..cubicTo(
        cx + bw * 0.12, cy - bh * 0.50, // strong upward bulge
        cx - bw * 0.26, cy - bh * 0.48,
        cx - bw * 0.48, cy + bh * 0.02, // back to tail
      )
      ..close();

    final bodyRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: bw,
      height: bh,
    );

    // ── 3a. Soft body shadow ──
    canvas.drawPath(
      bodyPath.shift(Offset(0, 8 + impact * 5)),
      Paint()
        ..color = Colors.black.withValues(alpha: immersive ? 0.30 : 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    // ── 3b. Body fill — warm wood gradient (light top-left → dark bottom-right) ──
    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-0.5, -0.9),
          end: const Alignment(0.4, 0.8),
          colors: <Color>[
            Color.lerp(tokens.bodyGradient[0], Colors.white, 0.22 + impact * 0.08)!,
            tokens.bodyGradient[0],
            tokens.bodyGradient[1],
            tokens.bodyGradient[2],
          ],
          stops: const <double>[0.0, 0.30, 0.60, 1.0],
        ).createShader(bodyRect),
    );

    // ── 3c. Body outline ──
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = tokens.bodyStroke.withValues(alpha: 0.44)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // ── 4. Upper dome highlight (conveys 3-D volume) ──
    final domePath = Path()
      ..moveTo(cx - bw * 0.38, cy - bh * 0.08)
      ..cubicTo(
        cx - bw * 0.20, cy - bh * 0.44,
        cx + bw * 0.18, cy - bh * 0.46,
        cx + bw * 0.36, cy - bh * 0.12,
      )
      ..quadraticBezierTo(
        cx + bw * 0.04, cy - bh * 0.14,
        cx - bw * 0.38, cy - bh * 0.08,
      )
      ..close();
    canvas.drawPath(
      domePath,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-0.3, -1),
          end: const Alignment(0.2, 0.5),
          colors: <Color>[
            Color.lerp(tokens.bodyGradient[0], Colors.white, 0.36)!,
            Color.lerp(tokens.bodyGradient[0], tokens.bodyGradient[1], 0.20)!,
            tokens.bodyGradient[1].withValues(alpha: 0.0),
          ],
          stops: const <double>[0.0, 0.50, 1.0],
        ).createShader(bodyRect),
    );

    // ── 5. Belly shadow (underside darker) ──
    final bellyPath = Path()
      ..moveTo(cx - bw * 0.36, cy + bh * 0.12)
      ..cubicTo(
        cx - bw * 0.22, cy + bh * 0.36,
        cx + bw * 0.12, cy + bh * 0.38,
        cx + bw * 0.36, cy + bh * 0.10,
      )
      ..lineTo(cx + bw * 0.30, cy + bh * 0.02)
      ..cubicTo(
        cx + bw * 0.06, cy + bh * 0.14,
        cx - bw * 0.18, cy + bh * 0.12,
        cx - bw * 0.36, cy + bh * 0.12,
      )
      ..close();
    canvas.drawPath(
      bellyPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.transparent,
            Colors.black.withValues(alpha: 0.14),
          ],
        ).createShader(bodyRect),
    );

    // ── 6. Mouth slit — a horizontal opening on the RIGHT side ──
    //
    // In a real 木鱼 the slit runs along one side. When viewed from 3/4
    // the slit appears as a dark horizontal gap on the front-right, with
    // the upper and lower lips of wood framing it.
    //
    // We draw: deep interior shadow → dark slit stroke → upper lip
    // highlight → lower lip shadow → cavity depth glow.

    // Slit runs from roughly body-centre to near the nose.
    final slitLeft = cx - bw * 0.06;
    final slitRight = cx + bw * 0.44;
    final slitY = cy + bh * 0.01; // at the body's equator line

    // Interior shadow (wide blurred dark region behind the slit)
    final slitInteriorPath = Path()
      ..moveTo(slitLeft, slitY)
      ..cubicTo(
        slitLeft + (slitRight - slitLeft) * 0.20, slitY - bh * 0.14,
        slitLeft + (slitRight - slitLeft) * 0.70, slitY - bh * 0.08,
        slitRight, slitY - bh * 0.04,
      );
    canvas.drawPath(
      slitInteriorPath.shift(Offset(0, bh * 0.03)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.36 + impact * 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = bh * 0.20
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Main dark slit line
    canvas.drawPath(
      slitInteriorPath,
      Paint()
        ..color = tokens.grooveDark.withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = bh * 0.12
        ..strokeCap = StrokeCap.round,
    );

    // Deep centre of the slit (narrower, blacker)
    canvas.drawPath(
      slitInteriorPath.shift(Offset(0, bh * 0.005)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.62)
        ..style = PaintingStyle.stroke
        ..strokeWidth = bh * 0.055
        ..strokeCap = StrokeCap.round,
    );

    // Upper lip highlight (wood edge catches light above the slit)
    final upperLip = Path()
      ..moveTo(slitLeft + (slitRight - slitLeft) * 0.04, slitY - bh * 0.07)
      ..cubicTo(
        slitLeft + (slitRight - slitLeft) * 0.28, slitY - bh * 0.18,
        slitLeft + (slitRight - slitLeft) * 0.68, slitY - bh * 0.13,
        slitRight - (slitRight - slitLeft) * 0.02, slitY - bh * 0.08,
      );
    canvas.drawPath(
      upperLip,
      Paint()
        ..color = tokens.grooveLight.withValues(alpha: 0.34 + impact * 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );

    // Lower lip edge (subtle dark line below the slit)
    final lowerLip = Path()
      ..moveTo(slitLeft + (slitRight - slitLeft) * 0.06, slitY + bh * 0.06)
      ..cubicTo(
        slitLeft + (slitRight - slitLeft) * 0.30, slitY + bh * 0.12,
        slitLeft + (slitRight - slitLeft) * 0.65, slitY + bh * 0.08,
        slitRight - (slitRight - slitLeft) * 0.04, slitY + bh * 0.02,
      );
    canvas.drawPath(
      lowerLip,
      Paint()
        ..color = tokens.bodyStroke.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );

    // Mouth opening "peek" at the nose end — the slit widens into
    // a visible cavity at the rightmost tip.
    final openEdge = Path()
      ..moveTo(slitRight - bw * 0.04, slitY - bh * 0.10)
      ..lineTo(slitRight + bw * 0.01, slitY - bh * 0.03)
      ..lineTo(slitRight - bw * 0.03, slitY + bh * 0.05)
      ..close();
    canvas.drawPath(
      openEdge,
      Paint()..color = Colors.black.withValues(alpha: 0.52),
    );
    // Light edge on the cavity opening
    canvas.drawPath(
      openEdge.shift(const Offset(-1.2, -1.0)),
      Paint()
        ..color = tokens.grooveLight.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // ── 7. Wood grain lines (clipped to body) ──
    canvas.save();
    canvas.clipPath(bodyPath);
    for (var i = 0; i < 7; i += 1) {
      final gy = cy - bh * 0.32 + i * bh * 0.10;
      final drift = math.sin((ambient + i * 0.17) * math.pi * 2) * bh * 0.025;
      final grain = Path()
        ..moveTo(cx - bw * 0.44, gy)
        ..cubicTo(
          cx - bw * 0.16, gy - bh * 0.05 + drift,
          cx + bw * 0.12, gy + bh * 0.05 - drift * 0.7,
          cx + bw * 0.40, gy - bh * 0.02 + drift * 0.3,
        );
      canvas.drawPath(
        grain,
        Paint()
          ..color = tokens.grain.withValues(alpha: 0.09 + ambient * 0.03)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }
    canvas.restore();

    // ── 8. Nose tip dot ──
    canvas.drawCircle(
      Offset(cx + bw * 0.48, cy - bh * 0.06),
      bw * 0.012,
      Paint()..color = tokens.bodyStroke.withValues(alpha: 0.42),
    );

    // ── 9. Specular highlight on top of dome ──
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - bw * 0.06, cy - bh * 0.30),
        width: bw * 0.30,
        height: bh * 0.09,
      ),
      Paint()
        ..color = tokens.dust.withValues(alpha: 0.24 + impact * 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // ── 10. Tail detail (decorative curl on the left end) ──
    final tailArc = Rect.fromCenter(
      center: Offset(cx - bw * 0.38, cy + bh * 0.06),
      width: bw * 0.12,
      height: bh * 0.14,
    );
    canvas.drawArc(
      tailArc,
      0.3,
      math.pi * 1.4,
      false,
      Paint()
        ..color = tokens.bodyStroke.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    // ── 11. Impact flash on body surface ──
    if (impact > 0.10) {
      final flashColor = accent ? tokens.accentWarm : tokens.accentCool;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy - bh * 0.14),
          width: bw * 0.34 * impact,
          height: bh * 0.24 * impact,
        ),
        Paint()
          ..color = flashColor.withValues(alpha: impact * 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WoodfishBodyPainter oldDelegate) {
    return oldDelegate.impact != impact ||
        oldDelegate.ambient != ambient ||
        oldDelegate.accent != accent ||
        oldDelegate.immersive != immersive ||
        oldDelegate.visualStyle != visualStyle;
  }
}

class _WoodfishMalletPainter extends CustomPainter {
  const _WoodfishMalletPainter({
    required this.colorScheme,
    required this.immersive,
    required this.impact,
    required this.visualStyle,
  });

  final ColorScheme colorScheme;
  final bool immersive;
  final double impact;
  final _WoodfishVisualStyle visualStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final tokens = _visualTokens(visualStyle);

    // ── Shaft geometry (long tapered stick from bottom-left to top-right) ──
    final shaftStart = Offset(size.width * 0.04, size.height * 0.72);
    final shaftEnd = Offset(size.width * 0.74, size.height * 0.46);
    final shaftWidth = size.height * 0.09;
    final shaftRect = Rect.fromPoints(shaftStart, shaftEnd).inflate(shaftWidth);
    final glowColor =
        Color.lerp(
          tokens.malletGlow,
          immersive ? Colors.white : colorScheme.primary,
          immersive ? 0.26 : 0.18,
        ) ??
        tokens.malletGlow;

    // ── Motion trail when striking ──
    if (impact > 0.14) {
      for (var i = 0; i < 2; i += 1) {
        final trailT = (impact - i * 0.22).clamp(0.0, 1.0);
        if (trailT <= 0.01) continue;
        canvas.drawLine(
          shaftStart.translate(-18 - i * 8, 6 + i * 2),
          shaftEnd.translate(-10 - i * 7, 5 + i * 2),
          Paint()
            ..color = glowColor.withValues(alpha: 0.08 * trailT)
            ..strokeWidth = shaftWidth * (0.9 - i * 0.2)
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }
    }

    // ── Shaft shadow ──
    canvas.drawLine(
      shaftStart.translate(0, shaftWidth * 0.5),
      shaftEnd.translate(0, shaftWidth * 0.45),
      Paint()
        ..color = Colors.black.withValues(alpha: immersive ? 0.36 : 0.2)
        ..strokeWidth = shaftWidth * 1.05
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    // ── Shaft body (tapered) ──
    // Draw the shaft as a tapered path for realism
    final shaftDir = (shaftEnd - shaftStart);
    final shaftLen = shaftDir.distance;
    final shaftNorm = Offset(-shaftDir.dy, shaftDir.dx) / shaftLen;
    final wStart = shaftWidth * 0.38; // thinner at handle end
    final wEnd = shaftWidth * 0.52; // slightly thicker near head

    final shaftPath = Path()
      ..moveTo(
        shaftStart.dx + shaftNorm.dx * wStart,
        shaftStart.dy + shaftNorm.dy * wStart,
      )
      ..lineTo(
        shaftEnd.dx + shaftNorm.dx * wEnd,
        shaftEnd.dy + shaftNorm.dy * wEnd,
      )
      ..lineTo(
        shaftEnd.dx - shaftNorm.dx * wEnd,
        shaftEnd.dy - shaftNorm.dy * wEnd,
      )
      ..lineTo(
        shaftStart.dx - shaftNorm.dx * wStart,
        shaftStart.dy - shaftNorm.dy * wStart,
      )
      ..close();

    canvas.drawPath(
      shaftPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color.lerp(tokens.malletShaftGradient[0], Colors.white, 0.12)!,
            tokens.malletShaftGradient[0],
            tokens.malletShaftGradient[1],
          ],
          stops: const <double>[0.0, 0.3, 1.0],
        ).createShader(shaftRect),
    );

    // Shaft highlight (light edge)
    canvas.drawLine(
      Offset(
        shaftStart.dx + shaftNorm.dx * wStart * 0.6,
        shaftStart.dy + shaftNorm.dy * wStart * 0.6,
      ),
      Offset(
        shaftEnd.dx + shaftNorm.dx * wEnd * 0.5,
        shaftEnd.dy + shaftNorm.dy * wEnd * 0.5,
      ),
      Paint()
        ..color = tokens.dust.withValues(alpha: 0.22)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );

    // Shaft outline
    canvas.drawPath(
      shaftPath,
      Paint()
        ..color = tokens.bodyStroke.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    // ── Padded head (round, like the reference image) ──
    final tipCenter = shaftEnd.translate(
      size.width * 0.04,
      -size.height * 0.02,
    );
    final headRadius = math.min(size.width, size.height) * 0.14;

    // Head shadow
    canvas.drawCircle(
      tipCenter.translate(0, headRadius * 0.5),
      headRadius * 1.05,
      Paint()
        ..color = Colors.black.withValues(alpha: immersive ? 0.38 : 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Head body (round padded shape)
    final headBounds = Rect.fromCircle(
      center: tipCenter,
      radius: headRadius,
    );
    canvas.drawCircle(
      tipCenter,
      headRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.28, -0.36),
          radius: 1.0,
          colors: <Color>[
            Color.lerp(tokens.malletHeadGradient[0], Colors.white, 0.26)!,
            tokens.malletHeadGradient[0],
            tokens.malletHeadGradient[1],
            tokens.malletHeadGradient[2],
          ],
          stops: const <double>[0.0, 0.25, 0.62, 1.0],
        ).createShader(headBounds),
    );

    // Head outline
    canvas.drawCircle(
      tipCenter,
      headRadius,
      Paint()
        ..color = tokens.bodyStroke.withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Highlight crescent on top-left
    final highlightPath = Path()
      ..addArc(
        Rect.fromCircle(center: tipCenter, radius: headRadius * 0.86),
        -math.pi * 0.85,
        math.pi * 0.6,
      );
    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // ── Decorative band where shaft meets head ──
    final bandCenter = Offset.lerp(shaftEnd, tipCenter, 0.35)!;
    canvas.drawCircle(
      bandCenter,
      headRadius * 0.22,
      Paint()..color = tokens.malletBand.withValues(alpha: 0.78),
    );
    canvas.drawCircle(
      bandCenter,
      headRadius * 0.22,
      Paint()
        ..color = tokens.bodyStroke.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // ── Impact glow at the tip ──
    if (impact > 0.08) {
      canvas.drawCircle(
        tipCenter,
        headRadius * (0.5 + impact * 0.4),
        Paint()
          ..color = glowColor.withValues(alpha: impact * 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WoodfishMalletPainter oldDelegate) {
    return oldDelegate.impact != impact ||
        oldDelegate.immersive != immersive ||
        oldDelegate.visualStyle != visualStyle;
  }
}

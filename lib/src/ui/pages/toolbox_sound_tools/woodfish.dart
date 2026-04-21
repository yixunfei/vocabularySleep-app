part of '../toolbox_sound_tools.dart';

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
  static const List<int> _woodfishVariants = <int>[0, 5, 12, 27];
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
  ToolboxRealisticEffectPlayer? _regularPlayer;
  ToolboxRealisticEffectPlayer? _accentPlayer;
  Timer? _autoTimer;
  Timer? _holdTimer;
  Timer? _persistTimer;
  Timer? _sessionTicker;
  Timer? _floatingHideTimer;
  int _audioRevision = 0;
  int? _transportAnchorUs;
  final _WoodfishStateStore _stateStore = _WoodfishStateStore();

  late final AnimationController _strikeController;
  late final AnimationController _ambientController;

  int get _sessionCount => _stateStore.sessionCount;
  set _sessionCount(int value) => _stateStore.sessionCount = value;
  int get _allTimeCount => _stateStore.allTimeCount;
  set _allTimeCount(int value) => _stateStore.allTimeCount = value;

  int get _pulseInCycle => _stateStore.pulseInCycle;
  set _pulseInCycle(int value) => _stateStore.pulseInCycle = value;

  int get _targetCount => _stateStore.targetCount;
  set _targetCount(int value) => _stateStore.targetCount = value;

  int get _bpm => _stateStore.bpm;
  set _bpm(int value) => _stateStore.bpm = value;

  int get _beatsPerCycle => _stateStore.beatsPerCycle;
  set _beatsPerCycle(int value) => _stateStore.beatsPerCycle = value;

  int get _subdivision => _stateStore.subdivision;
  set _subdivision(int value) => _stateStore.subdivision = value;

  int get _accentEvery => _stateStore.accentEvery;
  set _accentEvery(int value) => _stateStore.accentEvery = value;

  double get _masterVolume => _stateStore.masterVolume;
  set _masterVolume(double value) => _stateStore.masterVolume = value;

  double get _accentBoost => _stateStore.accentBoost;
  set _accentBoost(double value) => _stateStore.accentBoost = value;

  double get _resonance => _stateStore.resonance;
  set _resonance(double value) => _stateStore.resonance = value;

  double get _brightness => _stateStore.brightness;
  set _brightness(double value) => _stateStore.brightness = value;

  double get _pitch => _stateStore.pitch;
  set _pitch(double value) => _stateStore.pitch = value;

  double get _strikeHardness => _stateStore.strikeHardness;
  set _strikeHardness(double value) => _stateStore.strikeHardness = value;

  bool get _hapticsEnabled => _stateStore.hapticsEnabled;
  set _hapticsEnabled(bool value) => _stateStore.hapticsEnabled = value;

  bool get _autoStopAtGoal => _stateStore.autoStopAtGoal;
  set _autoStopAtGoal(bool value) => _stateStore.autoStopAtGoal = value;

  bool get _autoRunning => _stateStore.autoRunning;
  set _autoRunning(bool value) => _stateStore.autoRunning = value;

  bool get _lastWasAccent => _stateStore.lastWasAccent;
  set _lastWasAccent(bool value) => _stateStore.lastWasAccent = value;

  String get _activeRhythmPresetId => _stateStore.activeRhythmPresetId;
  set _activeRhythmPresetId(String value) =>
      _stateStore.activeRhythmPresetId = value;

  String get _lastGesture => _stateStore.lastGesture;
  set _lastGesture(String value) => _stateStore.lastGesture = value;
  String _floatingText = '功德 +1';
  _WoodfishSoundProfile _soundProfile = _WoodfishSoundProfile.temple;
  _WoodfishVisualStyle _visualStyle = _WoodfishVisualStyle.zenAmber;
  _WoodfishReboundArcPreset _reboundArcPreset =
      _WoodfishReboundArcPreset.compact;
  Duration get _elapsed => _stateStore.elapsed;
  set _elapsed(Duration value) => _stateStore.elapsed = value;

  int get _floatingSerial => _stateStore.floatingSerial;
  set _floatingSerial(int value) => _stateStore.floatingSerial = value;

  int? get _activeFloatingSerial => _stateStore.activeFloatingSerial;
  set _activeFloatingSerial(int? value) =>
      _stateStore.activeFloatingSerial = value;

  late final TextEditingController _floatingTextController;

  int get _cyclePulses => _stateStore.cyclePulses;
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
    final regularPlayer = _regularPlayer;
    final accentPlayer = _accentPlayer;
    _regularPlayer = null;
    _accentPlayer = null;
    if (regularPlayer != null) {
      unawaited(regularPlayer.dispose());
    }
    if (accentPlayer != null) {
      unawaited(accentPlayer.dispose());
    }
    super.dispose();
  }

  bool _isAccentPulse(int pulseIndex) => _stateStore.isAccentPulse(pulseIndex);

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
    setState(() {
      _soundProfile = _WoodfishSoundProfile.fromId(prefs.soundId);
      _visualStyle = _WoodfishVisualStyle.fromId(prefs.visualStyleId);
      _reboundArcPreset = _WoodfishReboundArcPreset.fromId(prefs.reboundArcId);
      _stateStore.applyPrefs(prefs);
      _floatingText = prefs.floatingText.trim().isEmpty
          ? '功德 +1'
          : prefs.floatingText.trim();
    });
    _floatingTextController.value = TextEditingValue(
      text: _floatingText,
      selection: TextSelection.collapsed(offset: _floatingText.length),
    );
    await _rebuildPlayers();
  }

  Future<void> _rebuildPlayers({bool preview = false}) async {
    final revision = ++_audioRevision;
    final regularPlayer = ToolboxRealisticEffectPlayer.build(
      variants: _woodfishVariants,
      bytesForVariant: (variant) => ToolboxAudioBank.woodfishClick(
        style: _soundProfile.id,
        resonance: _resonance,
        brightness: _brightness,
        pitch: _pitch,
        strike: _strikeHardness,
        accent: false,
        variant: variant,
      ),
      maxPlayers: 3,
      volumeJitter: 0.08,
    );
    final accentPlayer = ToolboxRealisticEffectPlayer.build(
      variants: _woodfishVariants,
      bytesForVariant: (variant) => ToolboxAudioBank.woodfishClick(
        style: _soundProfile.id,
        resonance: (_resonance + 0.1).clamp(0.0, 1.0),
        brightness: (_brightness + 0.08).clamp(0.0, 1.0),
        pitch: (_pitch + 0.2).clamp(-6.0, 6.0),
        strike: (_strikeHardness + 0.14).clamp(0.0, 1.0),
        accent: true,
        variant: variant,
      ),
      maxPlayers: 3,
      volumeJitter: 0.08,
    );
    await Future.wait<void>(<Future<void>>[
      regularPlayer.warmUp(),
      accentPlayer.warmUp(),
    ]);
    if (!mounted || revision != _audioRevision) {
      await Future.wait<void>(<Future<void>>[
        regularPlayer.dispose(),
        accentPlayer.dispose(),
      ]);
      return;
    }
    final oldRegularPlayer = _regularPlayer;
    final oldAccentPlayer = _accentPlayer;
    _regularPlayer = regularPlayer;
    _accentPlayer = accentPlayer;
    await Future.wait<void>(<Future<void>>[
      if (oldRegularPlayer != null) oldRegularPlayer.dispose(),
      if (oldAccentPlayer != null) oldAccentPlayer.dispose(),
    ]);
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
        baseVolume: (_masterVolume * (1 + _accentBoost * 0.5)).clamp(0.08, 1.0),
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
          baseVolume: (_masterVolume * (accent ? (1 + _accentBoost) : 1.0))
              .clamp(0.08, 1.0),
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
      _stateStore.registerStrike(
        accent: accent,
        gesture: gesture,
        elapsedValue: _sessionStopwatch.elapsed,
      );
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
      _stateStore.startAuto();
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
      _stateStore.stopAuto();
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
      _stateStore.resetSession();
    });
    _schedulePersist();
  }

  void _resetAllTime() {
    setState(() {
      _stateStore.resetAllTime();
    });
    _schedulePersist();
  }

  void _applyRhythmPreset(_WoodfishRhythmPreset preset) {
    setState(() {
      _stateStore.applyRhythmPreset(preset);
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
              _stateStore.updateBpm(value.round());
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
            setState(() {
              _stateStore.updateBeatsPerCycle(value.round());
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
            setState(() {
              _stateStore.updateSubdivision(value.round());
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
              _stateStore.updateAccentEvery(value.round());
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
        final dampedBounce =
            math.sin(upT * math.pi * bounceCount) *
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
        final impact = (math.sin(strikeT * math.pi) * 0.78 + contactWave).clamp(
          0.0,
          1.0,
        );

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
                    child: _buildFloatingBlessing(
                      context,
                      immersive: immersive,
                    ),
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

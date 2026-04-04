part of '../toolbox_sound_tools.dart';

enum _FocusBeatAnimationKind {
  pendulum,
  hypno,
  dew,
  gear,
  steps;

  String get id => name;

  IconData get icon => switch (this) {
    _FocusBeatAnimationKind.pendulum => Icons.watch_later_rounded,
    _FocusBeatAnimationKind.hypno => Icons.radio_button_checked_rounded,
    _FocusBeatAnimationKind.dew => Icons.water_drop_rounded,
    _FocusBeatAnimationKind.gear => Icons.settings_rounded,
    _FocusBeatAnimationKind.steps => Icons.directions_walk_rounded,
  };

  static _FocusBeatAnimationKind fromId(String? value) {
    for (final item in _FocusBeatAnimationKind.values) {
      if (item.id == value) {
        return item;
      }
    }
    return _FocusBeatAnimationKind.pendulum;
  }
}

enum _FocusBeatSoundKind {
  pendulum,
  hypno,
  dew,
  gear,
  steps;

  String get id => name;

  IconData get icon => switch (this) {
    _FocusBeatSoundKind.pendulum => Icons.music_note_rounded,
    _FocusBeatSoundKind.hypno => Icons.blur_circular_rounded,
    _FocusBeatSoundKind.dew => Icons.bubble_chart_rounded,
    _FocusBeatSoundKind.gear => Icons.precision_manufacturing_rounded,
    _FocusBeatSoundKind.steps => Icons.hiking_rounded,
  };

  static _FocusBeatSoundKind fromId(String? value) {
    for (final item in _FocusBeatSoundKind.values) {
      if (item.id == value) {
        return item;
      }
    }
    return _FocusBeatSoundKind.pendulum;
  }
}

class _FocusCyclePattern {
  const _FocusCyclePattern({required this.raw, required this.segments});

  final String raw;
  final List<double> segments;

  List<int> pulseCounts({required int beatsPerBar, required int subdivision}) {
    return segments
        .map((bars) => (bars * beatsPerBar * subdivision).round())
        .toList(growable: false);
  }
}

class _FocusPatternParseResult {
  const _FocusPatternParseResult.valid(this.pattern) : error = null;

  const _FocusPatternParseResult.invalid(this.error) : pattern = null;

  final _FocusCyclePattern? pattern;
  final String? error;

  bool get isValid => pattern != null;
}

String _focusPatternMatchKey(String input) {
  return input.toLowerCase().replaceAll(RegExp(r'\s+'), '');
}

_FocusPatternParseResult _parseFocusCyclePattern(
  String input, {
  required int beatsPerBar,
  required int subdivision,
}) {
  final normalized = input
      .trim()
      .toLowerCase()
      .replaceAll('小节', 'bar')
      .replaceAll('小節', 'bar')
      .replaceAll('节', 'bar')
      .replaceAll('節', 'bar')
      .replaceAll('循环', '')
      .replaceAll('循環', '')
      .replaceAll('loop', '')
      .replaceAll(RegExp(r'\s+'), '');

  if (normalized.isEmpty) {
    return const _FocusPatternParseResult.invalid('请输入编排，如 2bar+3bar+1/2bar。');
  }

  final tokens = normalized
      .split('+')
      .where((token) => token.trim().isNotEmpty)
      .toList(growable: false);
  if (tokens.isEmpty) {
    return const _FocusPatternParseResult.invalid('编排为空，请用 + 连接拍段。');
  }
  if (tokens.length > 24) {
    return const _FocusPatternParseResult.invalid('拍段过多，请控制在 24 段以内。');
  }

  final tokenRegExp = RegExp(r'^(\d+(?:\.\d+)?|\d+\/\d+)(?:bars?|b)?$');
  final segments = <double>[];
  var totalPulses = 0;
  for (final token in tokens) {
    final match = tokenRegExp.firstMatch(token);
    if (match == null) {
      return _FocusPatternParseResult.invalid(
        '无法解析 "$token"，示例：2bar、1/2bar、0.5bar。',
      );
    }
    final amount = match.group(1) ?? '';
    double bars = 0;
    if (amount.contains('/')) {
      final split = amount.split('/');
      if (split.length != 2) {
        return _FocusPatternParseResult.invalid('无效分数 "$amount"。');
      }
      final numerator = double.tryParse(split.first) ?? 0;
      final denominator = double.tryParse(split.last) ?? 0;
      if (numerator <= 0 || denominator <= 0) {
        return _FocusPatternParseResult.invalid('无效分数 "$amount"。');
      }
      bars = numerator / denominator;
    } else {
      bars = double.tryParse(amount) ?? 0;
    }

    if (bars <= 0 || bars > 16) {
      return _FocusPatternParseResult.invalid(
        '拍段 "$token" 超出范围，请控制在 0~16 bar。',
      );
    }
    final pulsesDouble = bars * beatsPerBar * subdivision;
    final pulses = pulsesDouble.round();
    if ((pulsesDouble - pulses).abs() > 0.001) {
      return _FocusPatternParseResult.invalid('拍段 "$token" 与当前拍号/子拍不对齐。');
    }
    if (pulses < 1) {
      return _FocusPatternParseResult.invalid('拍段 "$token" 过短。');
    }
    totalPulses += pulses;
    if (totalPulses > 4096) {
      return const _FocusPatternParseResult.invalid('循环过长，请简化编排。');
    }
    segments.add(bars);
  }

  return _FocusPatternParseResult.valid(
    _FocusCyclePattern(raw: tokens.join('+'), segments: segments),
  );
}

String _focusBarsLabel(double bars) {
  if ((bars - bars.round()).abs() < 0.0001) {
    return '${bars.round()}bar';
  }
  final half = bars * 2;
  if ((half - half.round()).abs() < 0.0001) {
    return '${half.round()}/2bar';
  }
  return '${bars.toStringAsFixed(2)}bar';
}

int _focusGreatestCommonDivisor(int a, int b) {
  var left = a.abs();
  var right = b.abs();
  while (right != 0) {
    final temp = left % right;
    left = right;
    right = temp;
  }
  return left == 0 ? 1 : left;
}

class _FocusArrangementPreset {
  const _FocusArrangementPreset({
    required this.name,
    required this.segmentsInBars,
  });

  final String name;
  final List<double> segmentsInBars;
}

class _FocusVisualPalette {
  const _FocusVisualPalette({
    required this.accent,
    required this.accentSoft,
    required this.accentGlow,
    required this.stageTop,
    required this.stageMid,
    required this.stageBottom,
    required this.panel,
    required this.panelStrong,
    required this.stroke,
  });

  final Color accent;
  final Color accentSoft;
  final Color accentGlow;
  final Color stageTop;
  final Color stageMid;
  final Color stageBottom;
  final Color panel;
  final Color panelStrong;
  final Color stroke;
}

class _FocusBeatsTool extends StatefulWidget {
  const _FocusBeatsTool({
    this.fullScreen = false,
    this.autoStart = false,
    this.initialImmersive = false,
    this.onOpenFullScreen,
    this.onExitFullScreen,
  });

  final bool fullScreen;
  final bool autoStart;
  final bool initialImmersive;
  final void Function({required bool autoStart, required bool immersive})?
  onOpenFullScreen;
  final VoidCallback? onExitFullScreen;

  @override
  State<_FocusBeatsTool> createState() => _FocusBeatsToolState();
}

class _FocusBeatsToolState extends State<_FocusBeatsTool>
    with TickerProviderStateMixin {
  static _FocusBeatsToolState? _runningInstance;
  static const List<_FocusArrangementPreset> _patternPresets =
      <_FocusArrangementPreset>[
        _FocusArrangementPreset(name: '单段 1bar', segmentsInBars: <double>[1]),
        _FocusArrangementPreset(
          name: '双段 2+2bar',
          segmentsInBars: <double>[2, 2],
        ),
        _FocusArrangementPreset(
          name: '均衡 3+3+2bar',
          segmentsInBars: <double>[3, 3, 2],
        ),
        _FocusArrangementPreset(
          name: '冲刺 2+3+1/2bar',
          segmentsInBars: <double>[2, 3, 0.5],
        ),
      ];

  late final AnimationController _pulseController;
  late final AnimationController _ambientController;
  final TextEditingController _patternController = TextEditingController(
    text: '2bar+2bar',
  );
  final List<int> _tapTempoIntervalsMs = <int>[];
  Timer? _transportTimer;
  Timer? _persistTimer;
  DateTime? _lastTapTempoAt;
  Map<int, ToolboxEffectPlayer> _players = <int, ToolboxEffectPlayer>{};

  int _bpm = 72;
  int _beatsPerBar = 4;
  int _subdivision = 1;
  int _activeBeat = -1;
  int _activeSubPulse = 0;
  bool _running = false;
  bool _patternEnabled = false;
  bool _hapticsEnabled = true;
  bool _immersiveMode = false;
  bool _linkAnimationAndSound = true;
  bool _tempoExpanded = true;
  bool _meterExpanded = false;
  bool _styleExpanded = true;
  bool _arrangementExpanded = false;
  bool _advancedExpanded = false;
  _FocusBeatAnimationKind _animationKind = _FocusBeatAnimationKind.pendulum;
  _FocusBeatSoundKind _soundKind = _FocusBeatSoundKind.pendulum;

  double _masterVolume = 0.9;
  double _accentVolume = 1.0;
  double _regularVolume = 0.78;
  double _subdivisionVolume = 0.54;

  _FocusCyclePattern _pattern = const _FocusCyclePattern(
    raw: '2bar+2bar',
    segments: <double>[2, 2],
  );
  List<int> _arrangementBeats = <int>[8, 8];
  String _patternError = '';
  List<int> _segmentPulseCounts = const <int>[8, 8];
  List<FocusBeatsArrangementTemplate> _savedTemplates =
      <FocusBeatsArrangementTemplate>[];
  String? _activeTemplateId;

  int _cycleCount = 0;
  int _cyclePulse = 0;
  int _currentSegmentIndex = 0;
  int _pulseInSegment = 0;
  int _pulseInBar = 0;
  int _transportTick = 0;
  int? _transportAnchorUs;
  int _lastLayer = 2;

  int get _barPulses => _beatsPerBar * _subdivision;

  int get _pulseIntervalUs =>
      math.max(1, (60000000 / (_bpm * _subdivision)).round());

  List<int> get _effectiveSegmentPulses {
    if (_patternEnabled && _patternError.isEmpty) {
      return _segmentPulseCounts;
    }
    return <int>[_barPulses];
  }

  FocusBeatsPrefsState get _prefsState => FocusBeatsPrefsState(
    bpm: _bpm,
    beatsPerBar: _beatsPerBar,
    subdivision: _subdivision,
    soundId: _soundKind.id,
    animationId: _animationKind.id,
    linkedSelection: _linkAnimationAndSound,
    patternText: _pattern.raw,
    patternEnabled: _patternEnabled,
    masterVolume: _masterVolume,
    accentVolume: _accentVolume,
    regularVolume: _regularVolume,
    subdivisionVolume: _subdivisionVolume,
    hapticsEnabled: _hapticsEnabled,
    arrangementTemplates: _savedTemplates,
    activeArrangementTemplateId: _activeTemplateId,
  );

  @override
  void initState() {
    super.initState();
    _immersiveMode = widget.initialImmersive;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _syncPulseAnimationDuration();
    _syncPatternFromArrangement(syncTemplate: false);
    unawaited(_rebuildPlayers());
    unawaited(_loadPrefs());
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _running) {
          return;
        }
        _start();
      });
    }
  }

  @override
  void dispose() {
    _transportTimer?.cancel();
    _persistTimer?.cancel();
    _patternController.dispose();
    _pulseController.dispose();
    _ambientController.dispose();
    if (_immersiveMode) {
      unawaited(_exitToolboxLandscapeMode());
    }
    for (final player in _players.values) {
      unawaited(player.dispose());
    }
    if (_runningInstance == this) {
      _runningInstance = null;
    }
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await ToolboxFocusBeatsPrefsService.load();
    if (!mounted) return;
    setState(() {
      _bpm = prefs.bpm;
      _beatsPerBar = prefs.beatsPerBar;
      _subdivision = prefs.subdivision;
      _soundKind = _FocusBeatSoundKind.fromId(prefs.soundId);
      _animationKind = _FocusBeatAnimationKind.fromId(prefs.animationId);
      _linkAnimationAndSound = prefs.linkedSelection;
      _patternController.text = prefs.patternText;
      _patternEnabled = prefs.patternEnabled;
      _masterVolume = prefs.masterVolume;
      _accentVolume = prefs.accentVolume;
      _regularVolume = prefs.regularVolume;
      _subdivisionVolume = prefs.subdivisionVolume;
      _hapticsEnabled = prefs.hapticsEnabled;
      _savedTemplates = prefs.arrangementTemplates;
      _activeTemplateId = prefs.activeArrangementTemplateId;
      final loaded = _loadPatternFromText(
        prefs.patternText,
        showErrorIfInvalid: false,
      );
      if (!loaded) {
        _arrangementBeats = <int>[_beatsPerBar, _beatsPerBar];
        _syncPatternFromArrangement(syncTemplate: false);
      }
      if (_activeTemplateId != null &&
          !_savedTemplates.any((item) => item.id == _activeTemplateId)) {
        _activeTemplateId = null;
      }
      if (_linkAnimationAndSound) {
        _soundKind = _pairedSoundForAnimation(_animationKind);
      }
      _resetRuntime();
    });
    _syncPulseAnimationDuration();
    await _rebuildPlayers();
  }

  Future<void> _rebuildPlayers() async {
    final oldPlayers = _players.values.toList(growable: false);
    _players = <int, ToolboxEffectPlayer>{
      for (final layer in <int>[0, 1, 2, 3])
        layer: ToolboxEffectPlayer(
          ToolboxAudioBank.focusBeatClick(style: _soundKind.id, layer: layer),
          maxPlayers: 6,
        ),
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final player in _players.values) {
        unawaited(player.warmUp());
      }
    });
    for (final player in oldPlayers) {
      unawaited(player.dispose());
    }
  }

  void _scheduleSavePrefs() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 360), () {
      unawaited(ToolboxFocusBeatsPrefsService.save(_prefsState));
    });
  }

  void _syncPulseAnimationDuration() {
    final intervalMs = (60000 / _bpm).round();
    _pulseController.duration = Duration(
      milliseconds: intervalMs.clamp(180, 2000),
    );
  }

  String _animationLabel(_FocusBeatAnimationKind kind) {
    return switch (kind) {
      _FocusBeatAnimationKind.pendulum => '摆钟 Pendulum',
      _FocusBeatAnimationKind.hypno => '催眠球 Hypno',
      _FocusBeatAnimationKind.dew => '露珠 Dewdrop',
      _FocusBeatAnimationKind.gear => '齿轮 Gear',
      _FocusBeatAnimationKind.steps => '步伐 Steps',
    };
  }

  String _soundLabel(_FocusBeatSoundKind kind) {
    return switch (kind) {
      _FocusBeatSoundKind.pendulum => '钟摆 Click',
      _FocusBeatSoundKind.hypno => '呼吸 Pulse',
      _FocusBeatSoundKind.dew => '露滴 Drop',
      _FocusBeatSoundKind.gear => '机械 Tick',
      _FocusBeatSoundKind.steps => '步伐 Step',
    };
  }

  _FocusBeatSoundKind _pairedSoundForAnimation(_FocusBeatAnimationKind kind) {
    return _FocusBeatSoundKind.fromId(kind.id);
  }

  _FocusBeatAnimationKind _pairedAnimationForSound(_FocusBeatSoundKind kind) {
    return _FocusBeatAnimationKind.fromId(kind.id);
  }

  String _animationDescription(_FocusBeatAnimationKind kind) {
    return switch (kind) {
      _FocusBeatAnimationKind.pendulum => '锁链与金属摆锤同步摆动，强拍时反光与惯性更重。',
      _FocusBeatAnimationKind.hypno => '同心波纹按拍扩张，适合长时间稳定专注。',
      _FocusBeatAnimationKind.dew => '圆形透光露珠下坠，触水后才逐层扩散涟漪。',
      _FocusBeatAnimationKind.gear => '金属齿轮按拍耦合咬合，落点带短促顿挫反馈。',
      _FocusBeatAnimationKind.steps => '左右步态交替落拍，适合朗读、背诵与走拍。',
    };
  }

  String _animationSyncHint(_FocusBeatAnimationKind kind) {
    return switch (kind) {
      _FocusBeatAnimationKind.pendulum => '强拍摆幅最大，回摆更轻。',
      _FocusBeatAnimationKind.hypno => '每拍呼吸一次，每小节推高一次峰值。',
      _FocusBeatAnimationKind.dew => '落下前聚能，触水瞬间释放波纹。',
      _FocusBeatAnimationKind.gear => '齿间在拍点咬合，视觉上能看到啮合停顿。',
      _FocusBeatAnimationKind.steps => '左右脚按节拍交替，段落切换更稳。',
    };
  }

  int _animationRealism(_FocusBeatAnimationKind kind) {
    return switch (kind) {
      _FocusBeatAnimationKind.pendulum => 5,
      _FocusBeatAnimationKind.hypno => 3,
      _FocusBeatAnimationKind.dew => 5,
      _FocusBeatAnimationKind.gear => 5,
      _FocusBeatAnimationKind.steps => 4,
    };
  }

  String _soundDescription(_FocusBeatSoundKind kind) {
    return switch (kind) {
      _FocusBeatSoundKind.pendulum => '偏金属钟体的清脆主击，适合经典节拍器手感。',
      _FocusBeatSoundKind.hypno => '更柔和、带呼吸感的脉冲，不易疲劳。',
      _FocusBeatSoundKind.dew => '高频更透明，像露滴轻触水面。',
      _FocusBeatSoundKind.gear => '机械棘轮感更强，强调“咔哒”式咬合瞬态。',
      _FocusBeatSoundKind.steps => '下盘更稳，像鞋底落地的步伐提示。',
    };
  }

  String _soundSyncHint(_FocusBeatSoundKind kind) {
    return switch (kind) {
      _FocusBeatSoundKind.pendulum => '重拍更厚，普通拍更轻。',
      _FocusBeatSoundKind.hypno => '声头柔和，适合低干扰长时专注。',
      _FocusBeatSoundKind.dew => '高频短促，适合露珠落点动画。',
      _FocusBeatSoundKind.gear => '声头更硬，适合齿轮咬合视觉。',
      _FocusBeatSoundKind.steps => '低频更稳，适合步态与口播跟拍。',
    };
  }

  int _soundRealism(_FocusBeatSoundKind kind) {
    return switch (kind) {
      _FocusBeatSoundKind.pendulum => 4,
      _FocusBeatSoundKind.hypno => 3,
      _FocusBeatSoundKind.dew => 4,
      _FocusBeatSoundKind.gear => 5,
      _FocusBeatSoundKind.steps => 4,
    };
  }

  String _realismLabel(int score) => '拟真度 $score/5';

  List<int> _normalizeArrangementBeats(Iterable<int> values) {
    final normalized = values
        .map((value) => value.clamp(1, 64))
        .map((value) => value.toInt())
        .toList(growable: false);
    if (normalized.isNotEmpty) {
      return normalized;
    }
    return <int>[_beatsPerBar];
  }

  String _barsTokenFromBeats(int beats) {
    final gcd = _focusGreatestCommonDivisor(beats, _beatsPerBar);
    final numerator = beats ~/ gcd;
    final denominator = _beatsPerBar ~/ gcd;
    if (denominator == 1) {
      return '${numerator}bar';
    }
    return '$numerator/${denominator}bar';
  }

  String _patternTextFromArrangement(List<int> beats) {
    return beats.map(_barsTokenFromBeats).join('+');
  }

  void _syncPatternFromArrangement({required bool syncTemplate}) {
    _arrangementBeats = _normalizeArrangementBeats(_arrangementBeats);
    _pattern = _FocusCyclePattern(
      raw: _patternTextFromArrangement(_arrangementBeats),
      segments: _arrangementBeats
          .map((beats) => beats / _beatsPerBar)
          .toList(growable: false),
    );
    _segmentPulseCounts = _arrangementBeats
        .map((beats) => beats * _subdivision)
        .toList(growable: false);
    _patternController.text = _pattern.raw;
    _patternError = '';
    if (!_patternEnabled) {
      _activeTemplateId = null;
      return;
    }
    if (syncTemplate) {
      _syncActiveTemplateByPattern();
    }
  }

  bool _loadPatternFromText(
    String rawText, {
    required bool showErrorIfInvalid,
  }) {
    final result = _parseFocusCyclePattern(
      rawText,
      beatsPerBar: _beatsPerBar,
      subdivision: _subdivision,
    );
    if (!result.isValid || result.pattern == null) {
      _patternError = _patternEnabled && showErrorIfInvalid
          ? (result.error ?? '编排格式无效。')
          : '';
      return false;
    }

    final parsedBeats = <int>[];
    for (final bars in result.pattern!.segments) {
      final beatsValue = bars * _beatsPerBar;
      final rounded = beatsValue.round();
      if ((beatsValue - rounded).abs() > 0.001 || rounded < 1) {
        _patternError = showErrorIfInvalid ? '当前只支持按“整数拍”编辑拍段。' : '';
        return false;
      }
      parsedBeats.add(rounded);
    }
    _arrangementBeats = _normalizeArrangementBeats(parsedBeats);
    _syncPatternFromArrangement(syncTemplate: false);
    return true;
  }

  void _resetRuntime() {
    _cycleCount = 0;
    _cyclePulse = 0;
    _currentSegmentIndex = 0;
    _pulseInSegment = 0;
    _pulseInBar = 0;
    _activeBeat = -1;
    _activeSubPulse = 0;
    _lastLayer = 2;
  }

  void _start() {
    if (_runningInstance != null && _runningInstance != this) {
      _runningInstance!._stop();
    }
    _transportTimer?.cancel();
    _running = true;
    _runningInstance = this;
    _resetRuntime();
    _transportTick = 0;
    _transportAnchorUs = DateTime.now().microsecondsSinceEpoch;
    _tick();
    _scheduleNextTick();
    if (mounted) {
      setState(() {});
    }
  }

  void _scheduleNextTick() {
    if (!_running) {
      return;
    }
    final anchor = _transportAnchorUs ?? DateTime.now().microsecondsSinceEpoch;
    _transportTick += 1;
    final targetUs = anchor + _transportTick * _pulseIntervalUs;
    final nowUs = DateTime.now().microsecondsSinceEpoch;
    final waitUs = math.max(0, targetUs - nowUs);
    _transportTimer = Timer(Duration(microseconds: waitUs), () {
      if (!mounted || !_running) {
        return;
      }
      _tick();
      _scheduleNextTick();
    });
  }

  void _stop() {
    _transportTimer?.cancel();
    _transportTimer = null;
    _running = false;
    if (_runningInstance == this) {
      _runningInstance = null;
    }
    _transportAnchorUs = null;
    _transportTick = 0;
    _resetRuntime();
    setState(() {});
  }

  void _restartTransportIfRunning() {
    if (_running) {
      _start();
    }
  }

  void _tick() {
    final segments = _effectiveSegmentPulses;
    final boundedSegmentIndex = _currentSegmentIndex.clamp(
      0,
      segments.length - 1,
    );
    final segmentLength = segments[boundedSegmentIndex];

    final isCycleStart = _cyclePulse == 0;
    final isSegmentStart = _pulseInSegment == 0;
    final isOnBeat = _pulseInBar % _subdivision == 0;

    final layer = isCycleStart
        ? 0
        : isSegmentStart
        ? 1
        : isOnBeat
        ? 2
        : 3;

    final beat = _pulseInBar ~/ _subdivision;
    final subPulse = (_pulseInBar % _subdivision) + 1;

    _playLayer(layer);
    _maybeHaptic(layer);

    if (isOnBeat) {
      _pulseController
        ..stop()
        ..forward(from: 0);
    }

    if (mounted) {
      setState(() {
        _lastLayer = layer;
        _activeBeat = beat;
        _activeSubPulse = subPulse;
      });
    }

    _pulseInSegment += 1;
    _pulseInBar = (_pulseInBar + 1) % _barPulses;
    _cyclePulse += 1;

    if (_pulseInSegment >= segmentLength) {
      _pulseInSegment = 0;
      _currentSegmentIndex += 1;
      if (_currentSegmentIndex >= segments.length) {
        _currentSegmentIndex = 0;
        _cycleCount += 1;
        _cyclePulse = 0;
      }
    }
  }

  double _volumeForLayer(int layer) {
    final layerVolume = switch (layer) {
      0 => _accentVolume,
      1 => (_accentVolume * 0.9).clamp(0.0, 1.0),
      2 => _regularVolume,
      _ => _subdivisionVolume,
    };
    return (_masterVolume * layerVolume).clamp(0.0, 1.0).toDouble();
  }

  void _playLayer(int layer) {
    final player = _players[layer];
    if (player == null) return;
    unawaited(player.play(volume: _volumeForLayer(layer)));
  }

  void _maybeHaptic(int layer) {
    if (!_hapticsEnabled) return;
    if (layer == 0) {
      HapticFeedback.mediumImpact();
      return;
    }
    if (layer == 1 && _bpm <= 140) {
      HapticFeedback.lightImpact();
      return;
    }
    if (layer == 2 && _subdivision == 1 && _bpm <= 88) {
      HapticFeedback.selectionClick();
    }
  }

  void _setAnimationKind(_FocusBeatAnimationKind kind) {
    if (_animationKind == kind && !_linkAnimationAndSound) {
      return;
    }
    var shouldRebuildPlayers = false;
    setState(() {
      _animationKind = kind;
      if (_linkAnimationAndSound) {
        final pairedSound = _pairedSoundForAnimation(kind);
        shouldRebuildPlayers = pairedSound != _soundKind;
        _soundKind = pairedSound;
      }
    });
    _scheduleSavePrefs();
    if (shouldRebuildPlayers) {
      unawaited(_rebuildPlayers());
    }
  }

  void _setSoundKind(_FocusBeatSoundKind kind) {
    if (_soundKind == kind && !_linkAnimationAndSound) {
      return;
    }
    setState(() {
      _soundKind = kind;
      if (_linkAnimationAndSound) {
        _animationKind = _pairedAnimationForSound(kind);
      }
    });
    _scheduleSavePrefs();
    unawaited(_rebuildPlayers());
  }

  void _setLinkAnimationAndSound(bool value) {
    var shouldRebuildPlayers = false;
    setState(() {
      _linkAnimationAndSound = value;
      if (value) {
        final pairedSound = _pairedSoundForAnimation(_animationKind);
        shouldRebuildPlayers = pairedSound != _soundKind;
        _soundKind = pairedSound;
      }
    });
    _scheduleSavePrefs();
    if (shouldRebuildPlayers) {
      unawaited(_rebuildPlayers());
    }
  }

  void _previewCurrentSound() {
    _playLayer(0);
    _pulseController
      ..stop()
      ..forward(from: 0);
    if (_hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void _setBpm(int value) {
    final next = value.clamp(30, 220);
    if (next == _bpm) {
      return;
    }
    setState(() {
      _bpm = next;
      _syncPulseAnimationDuration();
    });
    _scheduleSavePrefs();
    _restartTransportIfRunning();
  }

  void _setBeatsPerBar(int value) {
    if (value == _beatsPerBar) {
      return;
    }
    setState(() {
      _beatsPerBar = value;
      _syncPulseAnimationDuration();
      _syncPatternFromArrangement(syncTemplate: _patternEnabled);
      _resetRuntime();
    });
    _scheduleSavePrefs();
    _restartTransportIfRunning();
  }

  void _setSubdivision(int value) {
    if (value == _subdivision) {
      return;
    }
    setState(() {
      _subdivision = value;
      _syncPulseAnimationDuration();
      _syncPatternFromArrangement(syncTemplate: false);
      _resetRuntime();
    });
    _scheduleSavePrefs();
    _restartTransportIfRunning();
  }

  Future<void> _openArrangementEditor() async {
    final result = await Navigator.of(context)
        .push<_FocusArrangementEditorResult>(
          MaterialPageRoute<_FocusArrangementEditorResult>(
            builder: (_) => _FocusArrangementEditorPage(
              beatsPerBar: _beatsPerBar,
              patternEnabled: _patternEnabled,
              arrangementBeats: _arrangementBeats,
              templates: _savedTemplates,
              activeTemplateId: _activeTemplateId,
              presets: _patternPresets,
            ),
            fullscreenDialog: true,
          ),
        );
    if (!mounted || result == null) {
      return;
    }
    setState(() {
      _patternEnabled = result.patternEnabled;
      _arrangementBeats = _normalizeArrangementBeats(result.arrangementBeats);
      _savedTemplates = result.templates.toList(growable: false);
      _activeTemplateId = result.activeTemplateId;
      if (_activeTemplateId != null &&
          !_savedTemplates.any((item) => item.id == _activeTemplateId)) {
        _activeTemplateId = null;
      }
      _syncPatternFromArrangement(syncTemplate: false);
      if (!_patternEnabled) {
        _activeTemplateId = null;
      }
      _resetRuntime();
    });
    _scheduleSavePrefs();
    _restartTransportIfRunning();
  }

  void _tapTempo() {
    final now = DateTime.now();
    final last = _lastTapTempoAt;
    if (last == null || now.difference(last) > const Duration(seconds: 2)) {
      _tapTempoIntervalsMs.clear();
      _lastTapTempoAt = now;
      if (_hapticsEnabled) {
        HapticFeedback.selectionClick();
      }
      return;
    }

    final deltaMs = now.difference(last).inMilliseconds;
    _lastTapTempoAt = now;

    if (deltaMs < 180 || deltaMs > 2000) {
      _tapTempoIntervalsMs.clear();
      return;
    }

    _tapTempoIntervalsMs.add(deltaMs);
    if (_tapTempoIntervalsMs.length > 6) {
      _tapTempoIntervalsMs.removeAt(0);
    }
    final averageMs =
        _tapTempoIntervalsMs.reduce((a, b) => a + b) /
        _tapTempoIntervalsMs.length;
    _setBpm((60000 / averageMs).round());
    if (_hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _toggleImmersiveMode() async {
    if (!widget.fullScreen && widget.onOpenFullScreen != null) {
      final shouldAutoStart = _running;
      if (_running) {
        _stop();
      }
      widget.onOpenFullScreen?.call(
        autoStart: shouldAutoStart,
        immersive: true,
      );
      return;
    }
    final next = !_immersiveMode;
    if (widget.fullScreen) {
      await _enterToolboxPortraitMode();
    } else if (next) {
      await _enterToolboxPortraitMode();
    } else {
      await _exitToolboxLandscapeMode();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _immersiveMode = next;
    });
  }

  Color _animationAccent(_FocusBeatAnimationKind kind) {
    return switch (kind) {
      _FocusBeatAnimationKind.pendulum => const Color(0xFFD7A86B),
      _FocusBeatAnimationKind.hypno => const Color(0xFF7E90F2),
      _FocusBeatAnimationKind.dew => const Color(0xFF59C6C0),
      _FocusBeatAnimationKind.gear => const Color(0xFF95A6C2),
      _FocusBeatAnimationKind.steps => const Color(0xFF78BC8E),
    };
  }

  Color _soundAccent(_FocusBeatSoundKind kind) {
    return switch (kind) {
      _FocusBeatSoundKind.pendulum => const Color(0xFFC68F58),
      _FocusBeatSoundKind.hypno => const Color(0xFF6E84E8),
      _FocusBeatSoundKind.dew => const Color(0xFF4AB4D6),
      _FocusBeatSoundKind.gear => const Color(0xFF8FA0B8),
      _FocusBeatSoundKind.steps => const Color(0xFF84B56A),
    };
  }

  _FocusVisualPalette _visualPalette(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = Color.lerp(
      _animationAccent(_animationKind),
      colorScheme.primary,
      0.22,
    )!;
    return _FocusVisualPalette(
      accent: accent,
      accentSoft: Color.lerp(accent, Colors.white, 0.72)!,
      accentGlow: accent.withValues(alpha: 0.42),
      stageTop: Color.lerp(const Color(0xFF08131F), accent, 0.30)!,
      stageMid: Color.lerp(const Color(0xFF102034), accent, 0.16)!,
      stageBottom: Color.lerp(const Color(0xFF040B14), accent, 0.12)!,
      panel: colorScheme.surface.withValues(alpha: 0.92),
      panelStrong: colorScheme.surfaceContainerHighest.withValues(alpha: 0.94),
      stroke: Color.lerp(colorScheme.outlineVariant, accent, 0.34)!,
    );
  }

  Widget _buildStage(BuildContext context) {
    final palette = _visualPalette(context);
    final beatLabel = _activeBeat < 0 ? '--' : '${_activeBeat + 1}';
    final subLabel = _activeSubPulse == 0
        ? '--'
        : '$_activeSubPulse/$_subdivision';
    final segmentLabel = _patternEnabled && _patternError.isEmpty
        ? '${_currentSegmentIndex + 1}/${_segmentPulseCounts.length}'
        : '1/1';
    final cycleLabel = '${_cycleCount + 1}';
    final arrangementLabel = _patternError.isEmpty ? _pattern.raw : '1bar';
    final screenWidth = MediaQuery.sizeOf(context).width;
    final stageHeight = widget.fullScreen
        ? (screenWidth * 0.64).clamp(340.0, 470.0)
        : (screenWidth * 0.74).clamp(320.0, 430.0);
    return Container(
      width: double.infinity,
      height: stageHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            palette.stageTop,
            palette.stageMid,
            palette.stageBottom,
          ],
        ),
        borderRadius: BorderRadius.circular(widget.fullScreen ? 30 : 28),
        border: Border.all(color: palette.stroke.withValues(alpha: 0.72)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.accentGlow.withValues(alpha: 0.24),
            blurRadius: 42,
            offset: const Offset(0, 22),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          _pulseController,
          _ambientController,
        ]),
        builder: (context, _) {
          return Stack(
            children: <Widget>[
              Positioned(
                left: -48,
                top: -36,
                child: _FocusGlowOrb(
                  size: 180,
                  color: palette.accentGlow.withValues(alpha: 0.24),
                ),
              ),
              Positioned(
                right: -72,
                bottom: -86,
                child: _FocusGlowOrb(
                  size: 220,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.06),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.18),
                      ],
                      stops: const <double>[0.0, 0.38, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _FocusBeatVisualizerPainter(
                    kind: _animationKind,
                    pulseProgress: _pulseController.value,
                    ambientProgress: _ambientController.value,
                    accentLayer: _lastLayer,
                    running: _running,
                    activeBeat: _activeBeat,
                    activeSubPulse: _activeSubPulse,
                    subdivision: _subdivision,
                  ),
                ),
              ),
              Positioned(
                left: 18,
                top: 18,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    const _FocusStageBadge(
                      icon: Icons.blur_on_rounded,
                      label: 'Focus Studio',
                    ),
                    _FocusStageBadge(
                      icon: _animationKind.icon,
                      label: _animationLabel(_animationKind),
                    ),
                    _FocusStageBadge(
                      icon: _soundKind.icon,
                      label: _soundLabel(_soundKind),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 18,
                top: 18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.26),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          beatLabel,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (_subdivision > 1) ...<Widget>[
                          const SizedBox(height: 2),
                          Text(
                            'Sub $subLabel',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          _running ? '节拍运行中' : '等待开始',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.86),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _animationLabel(_animationKind),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _running
                                      ? _animationSyncHint(_animationKind)
                                      : _animationDescription(_animationKind),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.82,
                                        ),
                                        height: 1.4,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: palette.accent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: palette.accentSoft.withValues(
                                  alpha: 0.34,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Cycle',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: palette.accentSoft,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cycleLabel,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildStagePulseRail(context, palette),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          _FocusStageBadge(
                            icon: Icons.timeline_rounded,
                            label: '编排 $arrangementLabel',
                          ),
                          _FocusStageBadge(
                            icon: Icons.layers_rounded,
                            label: '段落 $segmentLabel',
                          ),
                          _FocusStageBadge(
                            icon: Icons.touch_app_rounded,
                            label: _hapticsEnabled ? '触感已启用' : '触感已关闭',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStagePulseRail(
    BuildContext context,
    _FocusVisualPalette palette,
  ) {
    final activeBeat = _activeBeat;
    final activeSub = _activeSubPulse;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            for (var index = 0; index < _beatsPerBar; index += 1)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == _beatsPerBar - 1 ? 0 : 8,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: index == activeBeat
                            ? <Color>[
                                palette.accentSoft.withValues(alpha: 0.96),
                                palette.accent.withValues(alpha: 0.92),
                              ]
                            : <Color>[
                                Colors.white.withValues(
                                  alpha: index == 0 ? 0.20 : 0.12,
                                ),
                                Colors.white.withValues(alpha: 0.04),
                              ],
                      ),
                      border: Border.all(
                        color: index == activeBeat
                            ? palette.accentSoft.withValues(alpha: 0.78)
                            : Colors.white.withValues(
                                alpha: index == 0 ? 0.22 : 0.10,
                              ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: index == activeBeat
                              ? const Color(0xFF09111B)
                              : Colors.white.withValues(alpha: 0.88),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_subdivision > 1) ...<Widget>[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (var index = 0; index < _subdivision; index += 1)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: activeSub == index + 1 ? 26 : 14,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: activeSub == index + 1
                        ? palette.accentSoft
                        : Colors.white.withValues(alpha: 0.18),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPatternPreview(BuildContext context) {
    if (_patternEnabled && _patternError.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _patternError,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      );
    }
    final segmentBeats = _patternError.isEmpty
        ? _arrangementBeats
        : <int>[_beatsPerBar];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (var index = 0; index < segmentBeats.length; index += 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _running && index == _currentSegmentIndex
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _running && index == _currentSegmentIndex
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              'S${index + 1} · ${segmentBeats[index]}拍 · '
              '${_focusBarsLabel(segmentBeats[index] / _beatsPerBar)}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
      ],
    );
  }

  Widget _buildImmersiveAnimationOnly(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[
                _pulseController,
                _ambientController,
              ]),
              builder: (context, _) {
                return CustomPaint(
                  painter: _FocusBeatVisualizerPainter(
                    kind: _animationKind,
                    pulseProgress: _pulseController.value,
                    ambientProgress: _ambientController.value,
                    accentLayer: _lastLayer,
                    running: _running,
                    activeBeat: _activeBeat,
                    activeSubPulse: _activeSubPulse,
                    subdivision: _subdivision,
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: Wrap(
                  spacing: 8,
                  children: <Widget>[
                    IconButton.filledTonal(
                      tooltip: '退出沉浸',
                      onPressed: _toggleImmersiveMode,
                      icon: const Icon(Icons.fullscreen_exit_rounded),
                    ),
                    if (widget.onExitFullScreen != null)
                      IconButton.filledTonal(
                        tooltip: '退出全屏',
                        onPressed: widget.onExitFullScreen,
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMixSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('$label ${(value * 100).round()}%'),
        Slider(value: value, min: 0, max: 1, onChanged: onChanged),
      ],
    );
  }

  Widget _buildSelectionSummary(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _linkAnimationAndSound ? '动画与音色已结对' : '动画与音色独立选择',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _previewCurrentSound,
                icon: const Icon(Icons.graphic_eq_rounded),
                label: const Text('试音'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _linkAnimationAndSound
                ? '切换动画时会同步匹配推荐音色，适合更完整的拟真体验。'
                : '视觉和音色可自由组合，适合按个人偏好做混搭。',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _FocusInfoPill(
                icon: _animationKind.icon,
                label: _animationLabel(_animationKind),
              ),
              _FocusInfoPill(
                icon: _soundKind.icon,
                label: _soundLabel(_soundKind),
              ),
              _FocusInfoPill(
                icon: Icons.auto_awesome_motion_rounded,
                label: _linkAnimationAndSound ? '推荐结对' : '自由混搭',
                emphasized: _linkAnimationAndSound,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _linkAnimationAndSound,
            onChanged: _setLinkAnimationAndSound,
            title: const Text('切换时自动匹配推荐音色'),
            subtitle: Text(
              _linkAnimationAndSound ? '当前会将动画与对应音色保持同步。' : '关闭后可以单独调整动画和音色。',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealismMeter(
    BuildContext context, {
    required int score,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        for (var i = 0; i < 5; i += 1)
          Container(
            width: 9,
            height: 9,
            margin: EdgeInsets.only(right: i == 4 ? 0 : 4),
            decoration: BoxDecoration(
              color: i < score
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }

  Widget _buildAnimationOptionTile(
    BuildContext context,
    _FocusBeatAnimationKind kind,
  ) {
    final selected = _animationKind == kind;
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _setAnimationKind(kind),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer.withValues(alpha: 0.9)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected
                        ? colorScheme.primary.withValues(alpha: 0.14)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    kind.icon,
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _animationLabel(kind),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _animationDescription(kind),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: <Widget>[
                _buildRealismMeter(
                  context,
                  score: _animationRealism(kind),
                  label: _realismLabel(_animationRealism(kind)),
                ),
                Text(
                  _animationSyncHint(kind),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundOptionTile(BuildContext context, _FocusBeatSoundKind kind) {
    final selected = _soundKind == kind;
    final colorScheme = Theme.of(context).colorScheme;
    final pairedAnimation = _pairedAnimationForSound(kind);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _setSoundKind(kind),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.secondaryContainer.withValues(alpha: 0.9)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? colorScheme.secondary
                : colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected
                        ? colorScheme.secondary.withValues(alpha: 0.14)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    kind.icon,
                    color: selected
                        ? colorScheme.secondary
                        : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _soundLabel(kind),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: colorScheme.secondary,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _soundDescription(kind),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: <Widget>[
                _buildRealismMeter(
                  context,
                  score: _soundRealism(kind),
                  label: _realismLabel(_soundRealism(kind)),
                ),
                Text(
                  '推荐动画：${_animationLabel(pairedAnimation)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTempoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Tempo · $_bpm BPM · ${(60 / _bpm).toStringAsFixed(2)} 秒/拍'),
        Slider(
          value: _bpm.toDouble(),
          min: 30,
          max: 220,
          divisions: 190,
          onChanged: (value) => _setBpm(value.round()),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            OutlinedButton(
              onPressed: () => _setBpm(_bpm - 5),
              child: const Text('-5'),
            ),
            OutlinedButton(
              onPressed: () => _setBpm(_bpm - 1),
              child: const Text('-1'),
            ),
            OutlinedButton(
              onPressed: () => _setBpm(_bpm + 1),
              child: const Text('+1'),
            ),
            OutlinedButton(
              onPressed: () => _setBpm(_bpm + 5),
              child: const Text('+5'),
            ),
            for (final quick in <int>[60, 72, 90, 108, 120, 144])
              ChoiceChip(
                label: Text('$quick'),
                selected: _bpm == quick,
                onSelected: (_) => _setBpm(quick),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMeterSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '拍号决定强弱拍结构，子拍决定每拍内部切分；两者会同步影响动画节奏和循环编排。',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <int>[2, 3, 4, 5, 6, 7, 8]
              .map(
                (count) => ChoiceChip(
                  label: Text('$count/4'),
                  selected: _beatsPerBar == count,
                  onSelected: (_) => _setBeatsPerBar(count),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <int>[1, 2, 3, 4]
              .map(
                (division) => ChoiceChip(
                  label: Text('子拍 ×$division'),
                  selected: _subdivision == division,
                  onSelected: (_) => _setSubdivision(division),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildStyleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSelectionSummary(context),
        const SizedBox(height: 14),
        Text(
          '动画样式',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (final kind in _FocusBeatAnimationKind.values) ...<Widget>[
          _buildAnimationOptionTile(context, kind),
          if (kind != _FocusBeatAnimationKind.values.last)
            const SizedBox(height: 10),
        ],
        const SizedBox(height: 16),
        Text(
          '音色样式',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (final kind in _FocusBeatSoundKind.values) ...<Widget>[
          _buildSoundOptionTile(context, kind),
          if (kind != _FocusBeatSoundKind.values.last)
            const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildArrangementSection(
    BuildContext context, {
    required String arrangementLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            _patternEnabled ? '循环编排已启用' : '当前为单小节循环',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '当前编排：$arrangementLabel（共 ${_arrangementBeats.fold<int>(0, (sum, item) => sum + item)} 拍）',
          ),
          trailing: FilledButton.tonalIcon(
            onPressed: _openArrangementEditor,
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('编辑'),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '通过拍段组合可以让视觉与音色在一轮循环里形成更明显的段落感。',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35),
        ),
        const SizedBox(height: 12),
        _buildPatternPreview(context),
      ],
    );
  }

  Widget _buildMixSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildMixSlider(
          label: '总音量',
          value: _masterVolume,
          onChanged: (value) {
            setState(() => _masterVolume = value);
            _scheduleSavePrefs();
          },
        ),
        _buildMixSlider(
          label: '重拍',
          value: _accentVolume,
          onChanged: (value) {
            setState(() => _accentVolume = value);
            _scheduleSavePrefs();
          },
        ),
        _buildMixSlider(
          label: '普通拍',
          value: _regularVolume,
          onChanged: (value) {
            setState(() => _regularVolume = value);
            _scheduleSavePrefs();
          },
        ),
        _buildMixSlider(
          label: '子拍',
          value: _subdivisionVolume,
          onChanged: (value) {
            setState(() => _subdivisionVolume = value);
            _scheduleSavePrefs();
          },
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _hapticsEnabled,
          onChanged: (value) {
            setState(() => _hapticsEnabled = value);
            _scheduleSavePrefs();
          },
          title: const Text('触感反馈'),
          subtitle: const Text('重拍与段落切换时提供更明确的触觉提示。'),
        ),
      ],
    );
  }

  Widget _buildHeroSummary(
    BuildContext context, {
    required String beatLabel,
    required String subBeatLabel,
    required String segmentLabel,
    required String cycleLabel,
    required String arrangementLabel,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = _visualPalette(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[palette.panelStrong, palette.panel],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.stroke.withValues(alpha: 0.42)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _FocusInfoPill(
                icon: Icons.blur_on_rounded,
                label: '专注节拍工作台',
                emphasized: true,
                tone: palette.accent,
              ),
              _FocusInfoPill(
                icon: Icons.motion_photos_on_rounded,
                label: _running ? '当前正在驱动节奏' : '已准备好开始',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '把节拍收束成一条注意力轨迹',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _running
                ? '视觉、声音与拍点已经同步运行，保持动作或呼吸跟着这一条节奏线推进。'
                : '把 BPM、编排、音色与触感反馈整理进同一块舞台，开播前的信息一眼就够。',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _FocusHeroMetric(
                label: '节奏',
                value: '$_bpm BPM',
                caption: '${(60 / _bpm).toStringAsFixed(2)} 秒/拍',
              ),
              _FocusHeroMetric(
                label: '拍号',
                value: '$_beatsPerBar/4 × $_subdivision',
                caption: '决定强弱拍与子拍密度',
              ),
              _FocusHeroMetric(
                label: '当前拍',
                value: '$beatLabel · $subBeatLabel',
                caption: _running ? '跟随当下脉冲' : '等待开始',
              ),
              _FocusHeroMetric(
                label: '段落',
                value: segmentLabel,
                caption: '循环中的当前位置',
              ),
              _FocusHeroMetric(
                label: '循环',
                value: cycleLabel,
                caption: arrangementLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryControls(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = _visualPalette(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.stroke.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: const Color(0xFF09111B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _running ? _stop : _start,
                  icon: Icon(
                    _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                  label: Text(_running ? '停止节拍' : '开始节拍'),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: _tapTempo,
                icon: const Icon(Icons.touch_app_rounded),
                label: const Text('Tap'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tap 可直接敲出当前想要的速度，适合在进入朗读、呼吸或步行前快速定拍。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _toggleImmersiveMode,
                icon: Icon(
                  _immersiveMode
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                ),
                label: Text(_immersiveMode ? '退出沉浸模式' : '沉浸模式'),
              ),
              if (!widget.fullScreen && widget.onOpenFullScreen != null)
                FilledButton.tonalIcon(
                  onPressed: () {
                    final shouldAutoStart = true;
                    if (_running) {
                      _stop();
                    }
                    widget.onOpenFullScreen?.call(
                      autoStart: shouldAutoStart,
                      immersive: false,
                    );
                  },
                  icon: const Icon(Icons.open_in_full_rounded),
                  label: const Text('全屏启动'),
                ),
              _FocusInfoPill(
                icon: Icons.auto_graph_rounded,
                label: _linkAnimationAndSound ? '动画与音色已联动' : '动画与音色自由混搭',
                emphasized: _linkAnimationAndSound,
                tone: palette.accent,
              ),
              _FocusInfoPill(
                icon: Icons.vibration_rounded,
                label: _hapticsEnabled ? '触感反馈已开启' : '触感反馈已关闭',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _syncActiveTemplateByPattern() {
    final key = _focusPatternMatchKey(_pattern.raw);
    String? matched;
    for (final template in _savedTemplates) {
      if (_focusPatternMatchKey(template.patternText) == key) {
        matched = template.id;
        break;
      }
    }
    _activeTemplateId = matched;
  }

  @override
  Widget build(BuildContext context) {
    final cycleLabel = (_cycleCount + 1).toString();
    final segmentLabel = _patternEnabled && _patternError.isEmpty
        ? '${_currentSegmentIndex + 1}/${_segmentPulseCounts.length}'
        : '1/1';
    final beatLabel = _activeBeat < 0 ? '--' : '${_activeBeat + 1}';
    final subBeatLabel = _activeSubPulse == 0
        ? '--'
        : '$_activeSubPulse/$_subdivision';
    final arrangementLabel = _patternError.isEmpty ? _pattern.raw : '1bar';

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildHeroSummary(
          context,
          beatLabel: beatLabel,
          subBeatLabel: subBeatLabel,
          segmentLabel: segmentLabel,
          cycleLabel: cycleLabel,
          arrangementLabel: arrangementLabel,
        ),
        const SizedBox(height: 14),
        const SectionHeader(
          title: '专注节拍工作台',
          subtitle: '围绕手机单手操作重构了节奏、风格、编排与触感设置，首屏只保留最关键的开播信息。',
        ),
        const SizedBox(height: 12),
        if (false)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              ToolboxMetricCard(label: 'BPM', value: '$_bpm'),
              ToolboxMetricCard(
                label: 'Meter',
                value: '$_beatsPerBar/4 ×$_subdivision',
              ),
              ToolboxMetricCard(
                label: 'Beat',
                value: '$beatLabel · $subBeatLabel',
              ),
              ToolboxMetricCard(label: 'Segment', value: segmentLabel),
              ToolboxMetricCard(label: 'Cycle', value: cycleLabel),
            ],
          ),
        const SizedBox(height: 14),
        _buildStage(context),
        const SizedBox(height: 14),
        _buildPrimaryControls(context),
        const SizedBox(height: 14),
        Visibility(
          visible: false,
          child: Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: _running ? _stop : _start,
                  icon: Icon(
                    _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                  label: Text(_running ? '停止节拍' : '开始节拍'),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.tonalIcon(
                onPressed: _tapTempo,
                icon: const Icon(Icons.touch_app_rounded),
                label: const Text('Tap'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Visibility(
          visible: false,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _toggleImmersiveMode,
                icon: Icon(
                  _immersiveMode
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                ),
                label: Text(_immersiveMode ? '退出沉浸' : '沉浸模式'),
              ),
              if (!widget.fullScreen && widget.onOpenFullScreen != null)
                FilledButton.tonalIcon(
                  onPressed: () {
                    final shouldAutoStart = true;
                    if (_running) {
                      _stop();
                    }
                    widget.onOpenFullScreen?.call(
                      autoStart: shouldAutoStart,
                      immersive: false,
                    );
                  },
                  icon: const Icon(Icons.open_in_full_rounded),
                  label: const Text('全屏启动'),
                ),
              _FocusInfoPill(
                icon: Icons.auto_graph_rounded,
                label: _linkAnimationAndSound ? '已结对' : '自由混搭',
                emphasized: _linkAnimationAndSound,
              ),
              _FocusInfoPill(
                icon: Icons.vibration_rounded,
                label: _hapticsEnabled ? '触感开启' : '触感关闭',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _FocusControlSection(
          icon: Icons.speed_rounded,
          title: '节奏控制',
          subtitle: 'BPM 调速与快捷步进',
          summary: '$_bpm BPM · ${(60 / _bpm).toStringAsFixed(2)} 秒/拍',
          expanded: _tempoExpanded,
          onToggle: () {
            setState(() {
              _tempoExpanded = !_tempoExpanded;
            });
          },
          child: _buildTempoSection(context),
        ),
        const SizedBox(height: 12),
        _FocusControlSection(
          icon: Icons.tune_rounded,
          title: '拍号与子拍',
          subtitle: '决定强弱拍结构与细分密度',
          summary: '$_beatsPerBar/4 · 子拍 ×$_subdivision',
          expanded: _meterExpanded,
          onToggle: () {
            setState(() {
              _meterExpanded = !_meterExpanded;
            });
          },
          child: _buildMeterSection(context),
        ),
        const SizedBox(height: 12),
        _FocusControlSection(
          icon: Icons.animation_rounded,
          title: '拟真风格',
          subtitle: '动画与音色可分离，也可一键结对',
          summary:
              '${_animationLabel(_animationKind)} · ${_soundLabel(_soundKind)}',
          expanded: _styleExpanded,
          onToggle: () {
            setState(() {
              _styleExpanded = !_styleExpanded;
            });
          },
          child: _buildStyleSection(context),
        ),
        const SizedBox(height: 12),
        _FocusControlSection(
          icon: Icons.view_timeline_rounded,
          title: '循环编排',
          subtitle: '按段落组织一轮节拍结构',
          summary: _patternEnabled ? arrangementLabel : '单小节循环',
          expanded: _arrangementExpanded,
          onToggle: () {
            setState(() {
              _arrangementExpanded = !_arrangementExpanded;
            });
          },
          child: _buildArrangementSection(
            context,
            arrangementLabel: arrangementLabel,
          ),
        ),
        const SizedBox(height: 12),
        _FocusControlSection(
          icon: Icons.graphic_eq_rounded,
          title: '混音与触感',
          subtitle: '调整重拍、普通拍、子拍与震动',
          summary:
              '总音量 ${(100 * _masterVolume).round()}% · ${_hapticsEnabled ? '触感开' : '触感关'}',
          expanded: _advancedExpanded,
          onToggle: () {
            setState(() {
              _advancedExpanded = !_advancedExpanded;
            });
          },
          child: _buildMixSection(context),
        ),
      ],
    );

    if (widget.fullScreen && _immersiveMode) {
      return _buildImmersiveAnimationOnly(context);
    }

    if (widget.fullScreen) {
      return _buildInstrumentPanelShell(
        context,
        fullScreen: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (widget.onExitFullScreen != null) ...<Widget>[
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: widget.onExitFullScreen,
                  icon: const Icon(Icons.fullscreen_exit_rounded),
                  label: const Text('退出全屏'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            body,
          ],
        ),
      );
    }

    return Card(
      child: Padding(padding: const EdgeInsets.all(18), child: body),
    );
  }
}

class _FocusControlSection extends StatelessWidget {
  const _FocusControlSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String summary;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[colorScheme.surface, colorScheme.surfaceContainerLow],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: expanded
              ? colorScheme.primary.withValues(alpha: 0.72)
              : colorScheme.outlineVariant.withValues(alpha: 0.92),
        ),
        boxShadow: expanded
            ? <BoxShadow>[
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            colorScheme.primary.withValues(alpha: 0.18),
                            colorScheme.primary.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: colorScheme.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.3,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(
                                alpha: 0.72,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              summary,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusInfoPill extends StatelessWidget {
  const _FocusInfoPill({
    required this.icon,
    required this.label,
    this.emphasized = false,
    this.tone,
  });

  final IconData icon;
  final String label;
  final bool emphasized;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final emphasisTone = tone ?? colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: emphasized
              ? <Color>[
                  emphasisTone.withValues(alpha: 0.16),
                  emphasisTone.withValues(alpha: 0.08),
                ]
              : <Color>[
                  colorScheme.surfaceContainerHighest,
                  colorScheme.surfaceContainerHigh,
                ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: emphasized
              ? emphasisTone.withValues(alpha: 0.52)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 16,
            color: emphasized ? emphasisTone : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: emphasized ? emphasisTone : colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusStageBadge extends StatelessWidget {
  const _FocusStageBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.96)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.96),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusHeroMetric extends StatelessWidget {
  const _FocusHeroMetric({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 136),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusGlowOrb extends StatelessWidget {
  const _FocusGlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color,
              blurRadius: size * 0.34,
              spreadRadius: size * 0.04,
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusArrangementEditorResult {
  const _FocusArrangementEditorResult({
    required this.patternEnabled,
    required this.arrangementBeats,
    required this.templates,
    required this.activeTemplateId,
  });

  final bool patternEnabled;
  final List<int> arrangementBeats;
  final List<FocusBeatsArrangementTemplate> templates;
  final String? activeTemplateId;
}

class _FocusArrangementEditorPage extends StatefulWidget {
  const _FocusArrangementEditorPage({
    required this.beatsPerBar,
    required this.patternEnabled,
    required this.arrangementBeats,
    required this.templates,
    required this.activeTemplateId,
    required this.presets,
  });

  final int beatsPerBar;
  final bool patternEnabled;
  final List<int> arrangementBeats;
  final List<FocusBeatsArrangementTemplate> templates;
  final String? activeTemplateId;
  final List<_FocusArrangementPreset> presets;

  @override
  State<_FocusArrangementEditorPage> createState() =>
      _FocusArrangementEditorPageState();
}

class _FocusArrangementEditorPageState
    extends State<_FocusArrangementEditorPage> {
  late bool _patternEnabled;
  late List<int> _arrangementBeats;
  late List<FocusBeatsArrangementTemplate> _templates;
  String? _activeTemplateId;

  @override
  void initState() {
    super.initState();
    _patternEnabled = widget.patternEnabled;
    _arrangementBeats = _normalizeArrangementBeats(widget.arrangementBeats);
    _templates = widget.templates.toList(growable: false);
    _activeTemplateId = widget.activeTemplateId;
    if (_activeTemplateId != null &&
        !_templates.any((item) => item.id == _activeTemplateId)) {
      _activeTemplateId = null;
    }
  }

  List<int> _normalizeArrangementBeats(Iterable<int> values) {
    final normalized = values
        .map((value) => value.clamp(1, 64))
        .map((value) => value.toInt())
        .toList(growable: false);
    if (normalized.isNotEmpty) {
      return normalized;
    }
    return <int>[widget.beatsPerBar];
  }

  String _barsTokenFromBeats(int beats) {
    final gcd = _focusGreatestCommonDivisor(beats, widget.beatsPerBar);
    final numerator = beats ~/ gcd;
    final denominator = widget.beatsPerBar ~/ gcd;
    if (denominator == 1) {
      return '${numerator}bar';
    }
    return '$numerator/${denominator}bar';
  }

  String get _patternRaw =>
      _arrangementBeats.map(_barsTokenFromBeats).join('+');

  int get _totalBeats =>
      _arrangementBeats.fold<int>(0, (sum, item) => sum + item);

  String _newTemplateId() {
    return 'focus_tpl_${DateTime.now().microsecondsSinceEpoch}';
  }

  List<FocusBeatsArrangementTemplate> get _sortedTemplates {
    final list = _templates.toList(growable: false);
    list.sort((a, b) {
      if (a.isFavorite != b.isFavorite) {
        return a.isFavorite ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  void _changeSegmentBeats(int index, int delta) {
    if (index < 0 || index >= _arrangementBeats.length || delta == 0) {
      return;
    }
    setState(() {
      final next = _arrangementBeats.toList(growable: false);
      next[index] = (next[index] + delta).clamp(1, 64);
      _arrangementBeats = _normalizeArrangementBeats(next);
    });
  }

  void _insertSegmentAfter(int index) {
    final insertAt = (index + 1).clamp(0, _arrangementBeats.length);
    setState(() {
      final next = _arrangementBeats.toList(growable: true);
      next.insert(insertAt, widget.beatsPerBar);
      _arrangementBeats = _normalizeArrangementBeats(next);
    });
  }

  void _removeSegment(int index) {
    if (_arrangementBeats.length <= 1 ||
        index < 0 ||
        index >= _arrangementBeats.length) {
      return;
    }
    setState(() {
      final next = _arrangementBeats.toList(growable: true)..removeAt(index);
      _arrangementBeats = _normalizeArrangementBeats(next);
    });
  }

  void _addSegment() {
    setState(() {
      _arrangementBeats = _arrangementBeats.toList(growable: true)
        ..add(widget.beatsPerBar);
    });
  }

  void _applyPreset(_FocusArrangementPreset preset) {
    setState(() {
      _arrangementBeats = _normalizeArrangementBeats(
        preset.segmentsInBars
            .map((bars) => (bars * widget.beatsPerBar).round())
            .toList(growable: false),
      );
      if (_patternEnabled) {
        _activeTemplateId = null;
      }
    });
  }

  void _applyTemplate(FocusBeatsArrangementTemplate template) {
    final result = _parseFocusCyclePattern(
      template.patternText,
      beatsPerBar: widget.beatsPerBar,
      subdivision: 1,
    );
    if (!result.isValid || result.pattern == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('模板格式无效，无法应用。')));
      return;
    }
    final beats = <int>[];
    for (final bars in result.pattern!.segments) {
      final beatsValue = bars * widget.beatsPerBar;
      final rounded = beatsValue.round();
      if ((beatsValue - rounded).abs() > 0.001 || rounded < 1) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('模板包含非整数拍段，当前版本暂不支持。')));
        return;
      }
      beats.add(rounded);
    }
    setState(() {
      _arrangementBeats = _normalizeArrangementBeats(beats);
      _patternEnabled = true;
      _activeTemplateId = template.id;
    });
  }

  Future<void> _promptSaveTemplate({
    FocusBeatsArrangementTemplate? editing,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text:
          editing?.name ??
          '模板 ${(DateTime.now().month).toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}',
    );
    var favorite = editing?.isFavorite ?? false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(editing == null ? '保存编排模板' : '编辑编排模板'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  maxLength: 18,
                  decoration: const InputDecoration(
                    labelText: '模板名称',
                    hintText: '如：专注冲刺 20min',
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return '请输入模板名称';
                    }
                    return null;
                  },
                ),
                StatefulBuilder(
                  builder: (context, setLocalState) {
                    return SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: favorite,
                      onChanged: (value) {
                        setLocalState(() {
                          favorite = value;
                        });
                      },
                      title: const Text('收藏模板'),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                Navigator.of(context).pop(true);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    if (saved != true || !mounted) {
      return;
    }

    final trimmedName = nameController.text.trim();
    setState(() {
      if (editing == null) {
        final template = FocusBeatsArrangementTemplate(
          id: _newTemplateId(),
          name: trimmedName,
          patternText: _patternRaw,
          isFavorite: favorite,
        );
        _templates = <FocusBeatsArrangementTemplate>[..._templates, template];
        _activeTemplateId = template.id;
      } else {
        _templates = _templates
            .map(
              (item) => item.id == editing.id
                  ? item.copyWith(
                      name: trimmedName,
                      patternText: _patternRaw,
                      isFavorite: favorite,
                    )
                  : item,
            )
            .toList(growable: false);
        _activeTemplateId = editing.id;
      }
    });
  }

  Future<void> _promptDeleteTemplate(
    FocusBeatsArrangementTemplate template,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除模板'),
          content: Text('确定删除「${template.name}」吗？'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      _templates = _templates
          .where((item) => item.id != template.id)
          .toList(growable: false);
      if (_activeTemplateId == template.id) {
        _activeTemplateId = null;
      }
    });
  }

  void _toggleTemplateFavorite(FocusBeatsArrangementTemplate template) {
    setState(() {
      _templates = _templates
          .map(
            (item) => item.id == template.id
                ? item.copyWith(isFavorite: !item.isFavorite)
                : item,
          )
          .toList(growable: false);
    });
  }

  Widget _buildPatternPreview(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (var index = 0; index < _arrangementBeats.length; index += 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              'S${index + 1} · ${_arrangementBeats[index]}拍 · ${_focusBarsLabel(_arrangementBeats[index] / widget.beatsPerBar)}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
      ],
    );
  }

  Widget _buildTemplateItem(FocusBeatsArrangementTemplate template) {
    final selected = template.id == _activeTemplateId;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: selected
            ? colorScheme.primaryContainer.withValues(alpha: 0.88)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                template.isFavorite
                    ? Icons.star_rounded
                    : Icons.bookmark_rounded,
                size: 16,
                color: template.isFavorite
                    ? const Color(0xFFF3B84B)
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  template.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (selected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '当前',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            template.patternText,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: () => _applyTemplate(template),
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: const Text('应用'),
              ),
              OutlinedButton.icon(
                onPressed: () => _promptSaveTemplate(editing: template),
                icon: const Icon(Icons.drive_file_rename_outline_rounded),
                label: const Text('重命名'),
              ),
              OutlinedButton.icon(
                onPressed: () => _toggleTemplateFavorite(template),
                icon: Icon(
                  template.isFavorite
                      ? Icons.star_border_rounded
                      : Icons.star_rounded,
                ),
                label: Text(template.isFavorite ? '取消收藏' : '收藏'),
              ),
              OutlinedButton.icon(
                onPressed: () => _promptDeleteTemplate(template),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('删除'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _finishEditing() {
    String? activeTemplateId = _activeTemplateId;
    if (activeTemplateId != null &&
        !_templates.any((item) => item.id == activeTemplateId)) {
      activeTemplateId = null;
    }
    Navigator.of(context).pop(
      _FocusArrangementEditorResult(
        patternEnabled: _patternEnabled,
        arrangementBeats: _arrangementBeats,
        templates: _templates,
        activeTemplateId: activeTemplateId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编排与模板编辑'),
        actions: <Widget>[
          TextButton(onPressed: _finishEditing, child: const Text('完成')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _patternEnabled,
            onChanged: (value) {
              setState(() {
                _patternEnabled = value;
                if (!value) {
                  _activeTemplateId = null;
                }
              });
            },
            title: const Text('启用循环编排'),
            subtitle: Text(
              _patternEnabled
                  ? '当前编排：$_patternRaw（共 $_totalBeats 拍）'
                  : '当前为单小节循环',
            ),
          ),
          const SizedBox(height: 10),
          const SectionHeader(title: '拍段编辑', subtitle: '按拍段逐个加减，可插入与删除。'),
          const SizedBox(height: 8),
          Column(
            children: <Widget>[
              for (var i = 0; i < _arrangementBeats.length; i += 1) ...<Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            '拍段 ${i + 1}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Text(
                            '${_arrangementBeats[i]}拍',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          OutlinedButton.icon(
                            onPressed: () => _changeSegmentBeats(i, -1),
                            icon: const Icon(Icons.remove_rounded),
                            label: const Text('-1 拍'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _changeSegmentBeats(i, 1),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('+1 拍'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _insertSegmentAfter(i),
                            icon: const Icon(Icons.add_box_outlined),
                            label: const Text('后插拍段'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _arrangementBeats.length <= 1
                                ? null
                                : () => _removeSegment(i),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('删除'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (i != _arrangementBeats.length - 1)
                  const SizedBox(height: 8),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: _addSegment,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('新增拍段'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _arrangementBeats = <int>[widget.beatsPerBar];
                    _activeTemplateId = null;
                  });
                },
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('重置编排'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _promptSaveTemplate(),
                icon: const Icon(Icons.bookmark_add_rounded),
                label: const Text('保存为模板'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.presets
                .map(
                  (preset) => ActionChip(
                    label: Text(preset.name),
                    onPressed: () => _applyPreset(preset),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          _buildPatternPreview(context),
          const SizedBox(height: 14),
          const SectionHeader(title: '编排模板库', subtitle: '可收藏、命名、应用、删除。'),
          const SizedBox(height: 8),
          if (_sortedTemplates.isEmpty)
            Text(
              '还没有模板，可先编辑拍段后点击“保存为模板”。',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Column(
              children: <Widget>[
                for (
                  var i = 0;
                  i < _sortedTemplates.length;
                  i += 1
                ) ...<Widget>[
                  _buildTemplateItem(_sortedTemplates[i]),
                  if (i != _sortedTemplates.length - 1)
                    const SizedBox(height: 8),
                ],
              ],
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _finishEditing,
            icon: const Icon(Icons.check_rounded),
            label: const Text('完成并返回'),
          ),
        ],
      ),
    );
  }
}

class _LegacyFocusBeatVisualizerPainter extends CustomPainter {
  const _LegacyFocusBeatVisualizerPainter({
    required this.kind,
    required this.pulseProgress,
    required this.ambientProgress,
    required this.accentLayer,
    required this.running,
    required this.activeBeat,
    required this.activeSubPulse,
    required this.subdivision,
  });

  final _FocusBeatAnimationKind kind;
  final double pulseProgress;
  final double ambientProgress;
  final int accentLayer;
  final bool running;
  final int activeBeat;
  final int activeSubPulse;
  final int subdivision;

  Color get _accentColor => switch (accentLayer) {
    0 => const Color(0xFFFFD27D),
    1 => const Color(0xFFFFB58A),
    2 => const Color(0xFF8CD6FF),
    _ => const Color(0xFF8BE8C6),
  };

  double _mix(double a, double b, double t) => a + (b - a) * t;

  List<Color> _palette() {
    return switch (kind) {
      _FocusBeatAnimationKind.pendulum => const <Color>[
        Color(0xFF16263D),
        Color(0xFF283E66),
        Color(0xFF2E4D86),
      ],
      _FocusBeatAnimationKind.hypno => const <Color>[
        Color(0xFF2A1244),
        Color(0xFF4D1E73),
        Color(0xFF7A2EA2),
      ],
      _FocusBeatAnimationKind.dew => const <Color>[
        Color(0xFF0F2D3A),
        Color(0xFF1B5668),
        Color(0xFF2587A4),
      ],
      _FocusBeatAnimationKind.gear => const <Color>[
        Color(0xFF242A33),
        Color(0xFF3D4756),
        Color(0xFF556174),
      ],
      _FocusBeatAnimationKind.steps => const <Color>[
        Color(0xFF1E2A24),
        Color(0xFF365142),
        Color(0xFF4A6E56),
      ],
    };
  }

  double get _ambientSpeed => switch (kind) {
    _FocusBeatAnimationKind.pendulum => 0.7,
    _FocusBeatAnimationKind.hypno => 1.25,
    _FocusBeatAnimationKind.dew => 0.85,
    _FocusBeatAnimationKind.gear => 1.4,
    _FocusBeatAnimationKind.steps => 1.0,
  };

  void _paintAmbientBackdrop(Canvas canvas, Size size, double pulse) {
    final palette = _palette();
    final baseRect = Offset.zero & size;
    final phase = ambientProgress * math.pi * 2 * _ambientSpeed;
    final drift = Offset(math.cos(phase) * 26, math.sin(phase * 0.8) * 20);
    final center = size.center(Offset.zero) + drift;

    canvas.drawRect(
      baseRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            palette[0],
            palette[1].withValues(alpha: 0.95),
            palette[2].withValues(alpha: 0.9),
          ],
          stops: const <double>[0.0, 0.58, 1.0],
        ).createShader(baseRect),
    );

    canvas.drawRect(
      baseRect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(
            (center.dx / size.width) * 2 - 1,
            (center.dy / size.height) * 2 - 1,
          ),
          radius: 0.9,
          colors: <Color>[
            _accentColor.withValues(alpha: 0.22 + pulse * 0.1),
            Colors.transparent,
          ],
        ).createShader(baseRect),
    );

    for (var i = 0; i < 8; i += 1) {
      final t = i / 8;
      final angle = phase + t * math.pi * 2;
      final orbitRadius = size.shortestSide * (0.22 + t * 0.22);
      final dot =
          center +
          Offset(
            math.cos(angle) * orbitRadius,
            math.sin(angle * 0.9) * orbitRadius * 0.55,
          );
      final r = _mix(1.6, 4.0, 1 - t) + pulse * 0.9;
      canvas.drawCircle(
        dot,
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: _mix(0.04, 0.18, 1 - t)),
      );
    }

    final vignetteColor = Colors.black.withValues(alpha: running ? 0.22 : 0.3);
    canvas.drawRect(
      baseRect,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[Colors.transparent, vignetteColor],
          stops: const <double>[0.62, 1.0],
        ).createShader(baseRect),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final easedPulse =
        1 - Curves.easeOutCubic.transform(pulseProgress.clamp(0.0, 1.0));
    _paintAmbientBackdrop(canvas, size, easedPulse);

    switch (kind) {
      case _FocusBeatAnimationKind.pendulum:
        _paintPendulum(canvas, size, easedPulse);
        break;
      case _FocusBeatAnimationKind.hypno:
        _paintHypno(canvas, size, easedPulse);
        break;
      case _FocusBeatAnimationKind.dew:
        _paintDew(canvas, size, easedPulse);
        break;
      case _FocusBeatAnimationKind.gear:
        _paintGear(canvas, size, easedPulse);
        break;
      case _FocusBeatAnimationKind.steps:
        _paintSteps(canvas, size, easedPulse);
        break;
    }

    _paintBeatIndicators(canvas, size, easedPulse);
  }

  void _paintPendulum(Canvas canvas, Size size, double pulse) {
    final phase = pulseProgress.clamp(0.0, 1.0);
    final swingDirection = activeBeat >= 0
        ? (activeBeat.isOdd ? -1.0 : 1.0)
        : 1.0;
    final harmonic = math.cos(math.pi * phase);
    final motionEnergy = math.sin(math.pi * phase).abs();
    final angle = swingDirection * harmonic * 0.52;
    final frameRect = Rect.fromLTWH(
      size.width * 0.15,
      size.height * 0.06,
      size.width * 0.70,
      size.height * 0.82,
    );
    final chamberRect = Rect.fromLTWH(
      size.width * 0.28,
      size.height * 0.24,
      size.width * 0.44,
      size.height * 0.46,
    );
    final dialCenter = Offset(size.width * 0.5, size.height * 0.16);
    final pivot = Offset(size.width * 0.5, size.height * 0.28);
    final length = size.height * 0.44;
    final bob = Offset(
      pivot.dx + math.sin(angle) * length,
      pivot.dy + math.cos(angle) * length,
    );

    canvas.drawShadow(
      Path()..addRRect(
        RRect.fromRectAndRadius(frameRect, const Radius.circular(22)),
      ),
      Colors.black.withValues(alpha: 0.45),
      18,
      false,
    );

    final cabinetPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF8B5A2B),
          Color(0xFF5C3D1E),
          Color(0xFF9A6B3F),
          Color(0xFF6E4A28),
        ],
        stops: <double>[0.0, 0.35, 0.7, 1.0],
      ).createShader(frameRect);

    final baseRect = Rect.fromLTWH(
      size.width * 0.18,
      size.height * 0.78,
      size.width * 0.64,
      size.height * 0.12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(18)),
      cabinetPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(18)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = const Color(0xFFD4A56A).withValues(alpha: 0.52),
    );

    final columnWidth = size.width * 0.06;
    _drawPendulumColumn(
      canvas,
      rect: Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.18,
        columnWidth,
        size.height * 0.60,
      ),
    );
    _drawPendulumColumn(
      canvas,
      rect: Rect.fromLTWH(
        size.width * 0.76,
        size.height * 0.18,
        columnWidth,
        size.height * 0.60,
      ),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(chamberRect, const Radius.circular(26)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF1E1510), Color(0xFF0C0806)],
        ).createShader(chamberRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(chamberRect, const Radius.circular(26)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF3A2818).withValues(alpha: 0.48),
    );

    final headRect = Rect.fromLTWH(
      size.width * 0.20,
      size.height * 0.06,
      size.width * 0.60,
      size.height * 0.20,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        headRect,
        topLeft: const Radius.circular(38),
        topRight: const Radius.circular(38),
        bottomLeft: const Radius.circular(16),
        bottomRight: const Radius.circular(16),
      ),
      cabinetPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        headRect,
        topLeft: const Radius.circular(38),
        topRight: const Radius.circular(38),
        bottomLeft: const Radius.circular(16),
        bottomRight: const Radius.circular(16),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = const Color(0xFFC99B5F).withValues(alpha: 0.48),
    );

    _drawClockDial(
      canvas,
      center: dialCenter,
      radius: size.shortestSide * 0.16,
    );

    final trailStrength = (motionEnergy * 0.85).clamp(0.0, 1.0);
    for (var i = 1; i <= 5; i += 1) {
      final trailPhase = (phase - i * 0.08).clamp(0.0, 1.0);
      final trailAngle = swingDirection * math.cos(math.pi * trailPhase) * 0.52;
      final trailBob = Offset(
        pivot.dx + math.sin(trailAngle) * length,
        pivot.dy + math.cos(trailAngle) * length,
      );
      canvas.drawLine(
        pivot,
        trailBob,
        Paint()
          ..color = const Color(
            0xFFE5C89E,
          ).withValues(alpha: trailStrength * (0.18 - i * 0.03))
          ..strokeWidth = 2.8 - i * 0.4,
      );
      canvas.drawCircle(
        trailBob,
        18 - i * 3,
        Paint()
          ..color = _accentColor.withValues(
            alpha: trailStrength * (0.12 - i * 0.02),
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    _drawPendulumChain(
      canvas,
      pivot: pivot,
      bob: bob,
      pulse: motionEnergy,
      accentColor: _accentColor,
    );

    canvas.drawCircle(
      bob.translate(0, 8),
      26 + motionEnergy * 10,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    final bobRadius = 24 + pulse * 7;
    canvas.drawCircle(
      bob,
      bobRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.28, -0.36),
          radius: 1.0,
          colors: <Color>[
            const Color(0xFFFFF8D8).withValues(alpha: 1.0),
            const Color(0xFFF5C65A).withValues(alpha: 0.98),
            const Color(0xFFC4872F).withValues(alpha: 0.96),
            const Color(0xFF8B5C1D).withValues(alpha: 0.94),
          ],
          stops: const <double>[0.0, 0.28, 0.58, 1.0],
        ).createShader(Rect.fromCircle(center: bob, radius: bobRadius + 8)),
    );
    canvas.drawCircle(
      bob,
      bobRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = const Color(0xFFFFE8B0).withValues(alpha: 0.62),
    );
    canvas.drawCircle(
      bob.translate(-8, -10),
      5.5,
      Paint()..color = Colors.white.withValues(alpha: 0.82),
    );
    canvas.drawCircle(
      bob.translate(4, -6),
      2.8,
      Paint()..color = Colors.white.withValues(alpha: 0.38),
    );
    canvas.drawCircle(
      bob,
      bobRadius + 8 + motionEnergy * 6,
      Paint()
        ..color = _accentColor.withValues(alpha: 0.22 + motionEnergy * 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    final reflectionGlow = motionEnergy * 0.4;
    canvas.drawArc(
      Rect.fromCircle(center: bob, radius: bobRadius * 0.85),
      -math.pi * 0.6 - angle * 0.5,
      math.pi * 0.35 + reflectionGlow * 0.12,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.16 + reflectionGlow * 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawPendulumChain(
    Canvas canvas, {
    required Offset pivot,
    required Offset bob,
    required double pulse,
    required Color accentColor,
  }) {
    final dx = bob.dx - pivot.dx;
    final dy = bob.dy - pivot.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final angle = math.atan2(dy, dx);

    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle - math.pi / 2);

    final stemRect = Rect.fromCenter(
      center: Offset(0, distance * 0.18),
      width: 5.2,
      height: distance * 0.36,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(stemRect, const Radius.circular(999)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFE5C89E),
            Color(0xFFA87842),
            Color(0xFF8B6230),
          ],
        ).createShader(stemRect),
    );

    final lyreHeight = distance * 0.24;
    final lyreTop = distance * 0.30;
    final leftRail = Path()
      ..moveTo(-12, lyreTop)
      ..quadraticBezierTo(
        -22,
        lyreTop + lyreHeight * 0.28,
        -12,
        lyreTop + lyreHeight,
      )
      ..moveTo(12, lyreTop)
      ..quadraticBezierTo(
        22,
        lyreTop + lyreHeight * 0.28,
        12,
        lyreTop + lyreHeight,
      );
    canvas.drawPath(
      leftRail,
      Paint()
        ..color = const Color(0xFFDAA65C).withValues(alpha: 0.98)
        ..strokeWidth = 2.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < 4; i += 1) {
      final y = lyreTop + lyreHeight * (0.16 + i * 0.22);
      canvas.drawLine(
        Offset(-10.5, y),
        Offset(10.5, y),
        Paint()
          ..color = const Color(0xFFF2D8A0).withValues(alpha: 0.82)
          ..strokeWidth = 1.4,
      );
    }
    canvas.drawLine(
      Offset(0, lyreTop),
      Offset(0, distance - 36),
      Paint()
        ..color = const Color(0xFFE8C890).withValues(alpha: 0.96)
        ..strokeWidth = 2.0,
    );

    final pivotCap = Rect.fromCenter(
      center: const Offset(0, 0),
      width: 22,
      height: 12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pivotCap, const Radius.circular(999)),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            Color(0xFFFCE8B8),
            Color(0xFFB8844A),
            Color(0xFF9A6A38),
          ],
        ).createShader(pivotCap),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pivotCap, const Radius.circular(999)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = const Color(0xFFE0B878).withValues(alpha: 0.48),
    );
    canvas.restore();

    canvas.drawCircle(
      pivot,
      6.2,
      Paint()..color = const Color(0xFFF8E4A8).withValues(alpha: 0.96),
    );
    canvas.drawCircle(
      pivot,
      4.0,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[Color(0xFFFEF4D8), Color(0xFFC49850)],
        ).createShader(Rect.fromCircle(center: pivot, radius: 4)),
    );
    canvas.drawCircle(
      bob.translate(0, -28),
      8 + pulse * 2.0,
      Paint()
        ..color = accentColor.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  void _drawPendulumColumn(Canvas canvas, {required Rect rect}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF805530),
            Color(0xFF5A3820),
            Color(0xFF885835),
            Color(0xFF684528),
          ],
          stops: <double>[0.0, 0.35, 0.7, 1.0],
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFFC89860).withValues(alpha: 0.42),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: rect.center,
          width: rect.width * 0.36,
          height: rect.height * 0.84,
        ),
        const Radius.circular(999),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
  }

  void _drawClockDial(
    Canvas canvas, {
    required Offset center,
    required double radius,
  }) {
    final outerRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius + 8,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[
            Color(0xFFFFEBB8),
            Color(0xFF9A6830),
            Color(0xFF724A20),
          ],
          stops: <double>[0.0, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius + 8)),
    );
    canvas.drawCircle(
      center,
      radius + 8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFFD8A060).withValues(alpha: 0.52),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.14, -0.24),
          colors: <Color>[
            Color(0xFFF8ECC8),
            Color(0xFFD8B88A),
            Color(0xFFBA9868),
            Color(0xFFA07848),
          ],
          stops: <double>[0.0, 0.45, 0.75, 1.0],
        ).createShader(outerRect),
    );
    canvas.drawCircle(
      center,
      radius * 0.85,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0xFF7A5030).withValues(alpha: 0.38),
    );
    canvas.drawCircle(
      center,
      radius * 0.22,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[Color(0xFF7A5030), Color(0xFF583818)],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 0.22)),
    );
    for (var i = 0; i < 12; i += 1) {
      final angle = -math.pi / 2 + i * math.pi / 6;
      final start = Offset(
        center.dx + math.cos(angle) * radius * 0.72,
        center.dy + math.sin(angle) * radius * 0.72,
      );
      final end = Offset(
        center.dx + math.cos(angle) * radius * 0.90,
        center.dy + math.sin(angle) * radius * 0.90,
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = const Color(0xFF5C4020).withValues(alpha: 0.82)
          ..strokeWidth = i % 3 == 0 ? 2.6 : 1.4,
      );
    }
    for (var i = 0; i < 60; i += 1) {
      if (i % 5 == 0) continue;
      final angle = -math.pi / 2 + i * math.pi / 30;
      final dot = Offset(
        center.dx + math.cos(angle) * radius * 0.82,
        center.dy + math.sin(angle) * radius * 0.82,
      );
      canvas.drawCircle(
        dot,
        0.8,
        Paint()..color = const Color(0xFF6E4A28).withValues(alpha: 0.52),
      );
    }
    canvas.drawLine(
      center,
      Offset(center.dx + radius * 0.16, center.dy - radius * 0.52),
      Paint()
        ..color = const Color(0xFF4C3018)
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      center,
      Offset(center.dx - radius * 0.38, center.dy + radius * 0.16),
      Paint()
        ..color = const Color(0xFF4C3018)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      center,
      radius * 0.08,
      Paint()..color = const Color(0xFFD8A860).withValues(alpha: 0.96),
    );
  }

  void _paintHypno(Canvas canvas, Size size, double pulse) {
    final center = size.center(Offset.zero);
    final baseRadius = size.shortestSide * 0.12;
    final phase = ambientProgress * math.pi * 2 * 1.35;
    final breatheCycle = math.sin(phase * 0.5).abs();
    final breathScale = 1.0 + breatheCycle * 0.08;

    for (var layer = 0; layer < 4; layer += 1) {
      final layerPhase = phase + layer * 0.72;
      final swirlRadius =
          baseRadius + size.shortestSide * (0.16 + layer * 0.12) * breathScale;
      final start = layerPhase;
      final sweep = math.pi * 1.4 + pulse * 0.2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: swirlRadius),
        start,
        sweep,
        false,
        Paint()
          ..shader = SweepGradient(
            startAngle: start,
            endAngle: start + sweep,
            colors: <Color>[
              _accentColor.withValues(alpha: 0.0),
              _accentColor.withValues(alpha: 0.32 - layer * 0.06),
              _accentColor.withValues(alpha: 0.18 - layer * 0.03),
              _accentColor.withValues(alpha: 0.0),
            ],
            stops: const <double>[0.0, 0.3, 0.7, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: swirlRadius))
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 5.5 - layer * 1.0,
      );
    }

    for (var i = 0; i < 9; i += 1) {
      final ringT = i / 8;
      final baseRingRadius = baseRadius + size.shortestSide * (0.08 * i);
      final waveOffset = math.sin(phase + i * 0.28) * 4;
      final radius = baseRingRadius + pulse * 14 * (1 - ringT) + waveOffset;
      final alpha = _mix(0.12, 0.68, 1 - ringT) * (0.68 + pulse * 0.32);
      final strokeWidth = _mix(1.0, 4.2, 1 - ringT);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            center: Alignment.center,
            radius: 0.6,
            colors: <Color>[
              _accentColor.withValues(alpha: alpha * 0.9),
              _accentColor.withValues(alpha: alpha * 0.5),
              _accentColor.withValues(alpha: alpha * 0.2),
            ],
            stops: const <double>[0.0, 0.5, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }

    for (var i = 0; i < 6; i += 1) {
      final angle = phase + i * math.pi / 3;
      final rayLength = baseRadius * 2.8 + pulse * 12;
      final start = Offset(
        center.dx + math.cos(angle) * (baseRadius * 1.1),
        center.dy + math.sin(angle) * (baseRadius * 1.1),
      );
      final end = Offset(
        center.dx + math.cos(angle) * rayLength,
        center.dy + math.sin(angle) * rayLength,
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              _accentColor.withValues(alpha: 0.32 + pulse * 0.18),
              _accentColor.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromPoints(start, end))
          ..strokeWidth = 1.8 + pulse * 0.8
          ..strokeCap = StrokeCap.round,
      );
    }

    final coreRadius = baseRadius * (1.1 + pulse * 0.6) * breathScale;
    canvas.drawCircle(
      center,
      coreRadius + 8,
      Paint()
        ..color = _accentColor.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.18, -0.24),
          radius: 0.85,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.96),
            _accentColor.withValues(alpha: 0.94),
            _accentColor.withValues(alpha: 0.78),
            const Color(0xFF5A3A72).withValues(alpha: 0.72),
          ],
          stops: const <double>[0.0, 0.28, 0.58, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: coreRadius)),
    );
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = Colors.white.withValues(alpha: 0.48),
    );
    canvas.drawCircle(
      center.translate(-coreRadius * 0.32, -coreRadius * 0.38),
      coreRadius * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.86),
    );
    canvas.drawCircle(
      center.translate(coreRadius * 0.12, -coreRadius * 0.18),
      coreRadius * 0.08,
      Paint()..color = Colors.white.withValues(alpha: 0.32),
    );

    canvas.drawCircle(
      center,
      coreRadius * 0.42,
      Paint()
        ..shader =
            const RadialGradient(
              colors: <Color>[Color(0xFF7A4A92), Color(0xFF4A2A5A)],
            ).createShader(
              Rect.fromCircle(center: center, radius: coreRadius * 0.42),
            ),
    );
  }

  void _paintDew(Canvas canvas, Size size, double pulse) {
    final centerX = size.width * 0.5;
    final fall = Curves.easeInCubic.transform(pulseProgress.clamp(0.0, 1.0));
    final dropY = _mix(size.height * 0.12, size.height * 0.64, fall);
    final rippleStart = size.height * 0.72;
    final impactProgress = ((fall - 0.82) / 0.18).clamp(0.0, 1.0);
    final preImpactSquash = fall < 0.82
        ? 0.0
        : math.sin(fall * math.pi * 4) * 0.04;
    final squash = impactProgress * 0.22 + preImpactSquash;
    final radius = 14 + pulse * 8;
    final dropRect = Rect.fromCenter(
      center: Offset(centerX, dropY),
      width: radius * 2.4 * (1 + squash * 0.28),
      height: radius * 2.4 * (1 - squash * 0.65),
    );

    for (var i = 0; i < 4; i += 1) {
      final trailY = dropY - (i + 1) * radius * 1.8;
      if (trailY < size.height * 0.08) continue;
      final trailAlpha = 0.16 - i * 0.04;
      final trailRadius = radius * (0.65 - i * 0.12);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            centerX + math.sin(ambientProgress * math.pi * 8 + i) * 3,
            trailY,
          ),
          width: trailRadius * 1.8,
          height: trailRadius * 2.2,
        ),
        Paint()
          ..color = _accentColor.withValues(alpha: trailAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, rippleStart + 6),
        width: 62 + impactProgress * 58,
        height: 18 + impactProgress * 8,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.14 + impactProgress * 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    final waterSurfaceRect = Rect.fromLTWH(
      size.width * 0.15,
      rippleStart - 4,
      size.width * 0.70,
      size.height * 0.12,
    );
    canvas.drawRect(
      waterSurfaceRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFF1A4558).withValues(alpha: 0.18),
            const Color(0xFF0F2838).withValues(alpha: 0.42),
            const Color(0xFF081820).withValues(alpha: 0.68),
          ],
        ).createShader(waterSurfaceRect),
    );

    canvas.drawOval(
      dropRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.38, -0.48),
          radius: 1.1,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.96),
            Colors.white.withValues(alpha: 0.78),
            _accentColor.withValues(alpha: 0.52),
            _accentColor.withValues(alpha: 0.28),
            const Color(0xFF1A5568).withValues(alpha: 0.18),
          ],
          stops: const <double>[0.0, 0.18, 0.42, 0.72, 1.0],
        ).createShader(dropRect),
    );
    canvas.drawOval(
      dropRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: 0.52),
    );

    canvas.drawCircle(
      Offset(centerX - radius * 0.48, dropY - radius * 0.58),
      radius * 0.28,
      Paint()..color = Colors.white.withValues(alpha: 0.88),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + radius * 0.22, dropY + radius * 0.18),
        width: radius * 1.2,
        height: radius * 0.58,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - radius * 0.12, dropY - radius * 0.28),
        width: radius * 0.55,
        height: radius * 0.28,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );

    final glowRadius = radius * 2.2 + pulse * 8;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, dropY),
        width: glowRadius,
        height: glowRadius * 0.8,
      ),
      Paint()
        ..color = _accentColor.withValues(alpha: 0.12 + pulse * 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    for (var i = 0; i < 5; i += 1) {
      final wave = (impactProgress - i * 0.16).clamp(0.0, 1.0);
      if (wave <= 0) continue;
      final rippleRadius = 22 + wave * 88;
      final alpha = (1 - wave * 0.48).clamp(0.0, 1.0) * 0.44;
      final rippleWidth = 2.4 - i * 0.35;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, rippleStart),
          width: rippleRadius * 2,
          height: rippleRadius * 0.48,
        ),
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: <Color>[
                  _accentColor.withValues(alpha: 0.0),
                  _accentColor.withValues(alpha: alpha),
                  _accentColor.withValues(alpha: alpha * 0.8),
                  _accentColor.withValues(alpha: 0.0),
                ],
                stops: const <double>[0.0, 0.25, 0.75, 1.0],
              ).createShader(
                Rect.fromCenter(
                  center: Offset(centerX, rippleStart),
                  width: rippleRadius * 2,
                  height: rippleRadius * 0.48,
                ),
              )
          ..style = PaintingStyle.stroke
          ..strokeWidth = rippleWidth,
      );
    }

    if (impactProgress > 0) {
      final splashT = Curves.easeOut.transform(impactProgress);
      for (var i = 0; i < 8; i += 1) {
        final theta = (-0.75 + i * 0.22) * math.pi;
        final baseLength = _mix(4, 24, splashT);
        final length = baseLength * (1 - (i % 4) * 0.15);
        final start = Offset(centerX, rippleStart - 4);
        final end = Offset(
          start.dx + math.cos(theta) * length,
          start.dy + math.sin(theta) * length * 0.6 - splashT * 12,
        );

        canvas.drawLine(
          start,
          end,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: <Color>[
                _accentColor.withValues(alpha: (1 - splashT) * 0.48),
                Colors.white.withValues(alpha: (1 - splashT) * 0.32),
              ],
            ).createShader(Rect.fromPoints(start, end))
            ..strokeWidth = 1.8 - splashT * 0.6
            ..strokeCap = StrokeCap.round,
        );

        if (splashT > 0.3) {
          canvas.drawCircle(
            end,
            2.4 - splashT * 1.2,
            Paint()
              ..color = Colors.white.withValues(alpha: (1 - splashT) * 0.42),
          );
        }
      }

      for (var ring = 0; ring < 2; ring += 1) {
        final ringT = (splashT - ring * 0.28).clamp(0.0, 1.0);
        if (ringT <= 0) continue;
        final secondaryRadius = 45 + ringT * 65 + ring * 28;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(centerX, rippleStart + ring * 6),
            width: secondaryRadius * 2,
            height: secondaryRadius * 0.38,
          ),
          Paint()
            ..color = _accentColor.withValues(alpha: (1 - ringT) * 0.22)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
    }
  }

  void _paintGear(Canvas canvas, Size size, double pulse) {
    final phase = pulseProgress.clamp(0.0, 1.0);
    final swingDirection = activeBeat >= 0
        ? (activeBeat.isOdd ? -1.0 : 1.0)
        : 1.0;
    final tickImpulse =
        Curves.easeOutCubic.transform((1 - phase).clamp(0.0, 1.0)) * 0.12;
    final mainRotation =
        ambientProgress * math.pi * 2 * (running ? 0.48 : 0.12) +
        tickImpulse * swingDirection;
    final caseCenter = Offset(size.width * 0.5, size.height * 0.48);
    final caseRadius = size.shortestSide * 0.36;
    final caseRect = Rect.fromCircle(center: caseCenter, radius: caseRadius);

    canvas.drawCircle(
      caseCenter,
      caseRadius + 22,
      Paint()
        ..shader =
            const RadialGradient(
              colors: <Color>[
                Color(0xFF8A4A28),
                Color(0xFF4A2818),
                Color(0xFF2A1408),
              ],
              stops: <double>[0.0, 0.6, 1.0],
            ).createShader(
              Rect.fromCircle(center: caseCenter, radius: caseRadius + 22),
            ),
    );
    canvas.drawCircle(
      caseCenter,
      caseRadius + 12,
      Paint()
        ..shader =
            const RadialGradient(
              center: Alignment(-0.16, -0.32),
              colors: <Color>[
                Color(0xFFFAD88E),
                Color(0xFFD8A048),
                Color(0xFFB07832),
                Color(0xFF683818),
              ],
              stops: <double>[0.0, 0.32, 0.62, 1.0],
            ).createShader(
              Rect.fromCircle(center: caseCenter, radius: caseRadius + 12),
            ),
    );
    canvas.drawCircle(
      caseCenter,
      caseRadius + 12,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color(0xFFC89858).withValues(alpha: 0.48),
    );
    canvas.drawCircle(
      caseCenter,
      caseRadius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment.center,
          colors: <Color>[
            Color(0xFF2A1E14),
            Color(0xFF1A120A),
            Color(0xFF0A0604),
          ],
        ).createShader(caseRect),
    );

    _drawFocusGear(
      canvas,
      center: caseCenter.translate(-caseRadius * 0.28, caseRadius * 0.16),
      radius: caseRadius * 0.46 + pulse * 6,
      teeth: 24,
      rotation: mainRotation,
      color: const Color(0xFFDAB35C),
      pulse: pulse,
    );
    _drawFocusGear(
      canvas,
      center: caseCenter.translate(caseRadius * 0.28, -caseRadius * 0.22),
      radius: caseRadius * 0.20 + pulse * 3,
      teeth: 14,
      rotation: -mainRotation * 2.1,
      color: const Color(0xFFD0D7E0),
      pulse: pulse * 0.85,
    );
    _drawFocusGear(
      canvas,
      center: caseCenter.translate(-caseRadius * 0.38, -caseRadius * 0.32),
      radius: caseRadius * 0.18,
      teeth: 14,
      rotation: -mainRotation * 1.48,
      color: const Color(0xFFAEB9C7),
      pulse: pulse * 0.65,
    );
    _drawFocusGear(
      canvas,
      center: caseCenter.translate(caseRadius * 0.36, caseRadius * 0.32),
      radius: caseRadius * 0.14,
      teeth: 12,
      rotation: mainRotation * 2.6,
      color: const Color(0xFFB3BAC4),
      pulse: pulse * 0.55,
    );
    _drawFocusGear(
      canvas,
      center: caseCenter.translate(-caseRadius * 0.12, caseRadius * 0.38),
      radius: caseRadius * 0.10,
      teeth: 10,
      rotation: mainRotation * 3.2,
      color: const Color(0xFFC8D0D8),
      pulse: pulse * 0.45,
    );

    final balanceAngle = swingDirection * math.cos(math.pi * phase) * 0.58;
    _drawBalanceWheel(
      canvas,
      center: caseCenter,
      radius: caseRadius * 0.32,
      rotation: balanceAngle,
      pulse: pulse,
    );

    final bridgeColor = const Color(0xFFD8DEE8).withValues(alpha: 0.98);
    final bridgePaint = Paint()
      ..color = bridgeColor
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: caseCenter, radius: caseRadius * 0.38),
      math.pi * 1.05,
      math.pi * 0.92,
      false,
      bridgePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: caseCenter, radius: caseRadius * 0.38),
      math.pi * 1.05,
      math.pi * 0.92,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = Colors.white.withValues(alpha: 0.32),
    );
    canvas.drawLine(
      caseCenter.translate(-caseRadius * 0.04, 0),
      caseCenter.translate(caseRadius * 0.42, -caseRadius * 0.06),
      Paint()
        ..color = bridgeColor
        ..strokeWidth = 8.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      caseCenter.translate(-caseRadius * 0.22, -caseRadius * 0.26),
      caseCenter.translate(caseRadius * 0.12, -caseRadius * 0.08),
      Paint()
        ..color = bridgeColor.withValues(alpha: 0.88)
        ..strokeWidth = 7.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      caseCenter.translate(-caseRadius * 0.08, caseRadius * 0.28),
      caseCenter.translate(caseRadius * 0.32, caseRadius * 0.12),
      Paint()
        ..color = bridgeColor.withValues(alpha: 0.82)
        ..strokeWidth = 5.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      caseCenter,
      10,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[
            Color(0xFFFCE8AA),
            Color(0xFFD8A848),
            Color(0xFF9A6D25),
          ],
        ).createShader(Rect.fromCircle(center: caseCenter, radius: 10)),
    );
    canvas.drawCircle(
      caseCenter,
      10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFE8C878).withValues(alpha: 0.62),
    );

    for (final screw in <Offset>[
      caseCenter.translate(-caseRadius * 0.58, -caseRadius * 0.56),
      caseCenter.translate(caseRadius * 0.62, -caseRadius * 0.52),
      caseCenter.translate(-caseRadius * 0.52, caseRadius * 0.62),
      caseCenter.translate(caseRadius * 0.48, caseRadius * 0.58),
    ]) {
      _drawMovementScrew(canvas, center: screw, radius: 13);
    }
    for (final jewel in <Offset>[
      caseCenter.translate(-caseRadius * 0.26, -caseRadius * 0.12),
      caseCenter.translate(caseRadius * 0.12, -caseRadius * 0.02),
      caseCenter.translate(caseRadius * 0.22, -caseRadius * 0.16),
      caseCenter.translate(-caseRadius * 0.32, caseRadius * 0.08),
    ]) {
      canvas.drawCircle(
        jewel,
        5.2,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.24, -0.28),
            colors: <Color>[
              Color(0xFFE8A8FF),
              Color(0xFF8E4DA8),
              Color(0xFF5A2A6A),
            ],
          ).createShader(Rect.fromCircle(center: jewel, radius: 5.2)),
      );
      canvas.drawCircle(
        jewel,
        1.8,
        Paint()..color = Colors.white.withValues(alpha: 0.72),
      );
    }

    for (var i = 0; i < 8; i += 1) {
      final angle = i * math.pi / 4 + mainRotation * 0.08;
      final decorationRadius = caseRadius * 0.72;
      final decorationPos = Offset(
        caseCenter.dx + math.cos(angle) * decorationRadius,
        caseCenter.dy + math.sin(angle) * decorationRadius,
      );
      canvas.drawCircle(
        decorationPos,
        2.8,
        Paint()
          ..shader = const RadialGradient(
            colors: <Color>[Color(0xFFD8A858), Color(0xFF7A4828)],
          ).createShader(Rect.fromCircle(center: decorationPos, radius: 2.8)),
      );
    }

    canvas.drawCircle(
      caseCenter,
      caseRadius + 5 + pulse * 4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.22 + pulse * 0.08),
    );

    canvas.drawArc(
      Rect.fromCircle(center: caseCenter, radius: caseRadius + 8),
      -math.pi * 0.4 + ambientProgress * math.pi * 0.8,
      math.pi * 0.6,
      false,
      Paint()
        ..shader =
            SweepGradient(
              colors: <Color>[
                Colors.white.withValues(alpha: 0.0),
                Colors.white.withValues(alpha: 0.24),
                Colors.white.withValues(alpha: 0.0),
              ],
            ).createShader(
              Rect.fromCircle(center: caseCenter, radius: caseRadius + 8),
            )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintSteps(Canvas canvas, Size size, double pulse) {
    final phase = pulseProgress.clamp(0.0, 1.0);
    final leftActive = activeBeat >= 0 ? activeBeat.isEven : true;
    final vanishing = Offset(size.width * 0.5, size.height * 0.14);

    final skyRect = Rect.fromLTWH(0, 0, size.width, vanishing.dy + 18);
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFF1A2822).withValues(alpha: 0.28),
            const Color(0xFF1E3A28).withValues(alpha: 0.48),
            const Color(0xFF182818).withValues(alpha: 0.72),
          ],
        ).createShader(skyRect),
    );

    final lanePath = Path()
      ..moveTo(size.width * 0.14, size.height * 0.94)
      ..lineTo(size.width * 0.86, size.height * 0.94)
      ..lineTo(size.width * 0.62, vanishing.dy)
      ..lineTo(size.width * 0.38, vanishing.dy)
      ..close();
    canvas.drawPath(
      lanePath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFF1A2822).withValues(alpha: 0.22),
            const Color(0xFF243A32).withValues(alpha: 0.58),
            const Color(0xFF183028).withValues(alpha: 0.85),
            const Color(0xFF0E1812).withValues(alpha: 0.92),
          ],
          stops: const <double>[0.0, 0.35, 0.7, 1.0],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      lanePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = Colors.white.withValues(alpha: 0.16),
    );

    final laneDividerPath = Path()
      ..moveTo(size.width * 0.5, vanishing.dy)
      ..lineTo(size.width * 0.5, size.height * 0.94);
    canvas.drawPath(
      laneDividerPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.28),
          ],
        ).createShader(laneDividerPath.getBounds())
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < 8; i += 1) {
      final t = i / 7;
      final y = _mix(vanishing.dy + 22, size.height * 0.96, t);
      final halfWidth = _mix(8, size.width * 0.32, t);
      final alpha = 0.04 + t * 0.12;
      canvas.drawLine(
        Offset(size.width * 0.5 - halfWidth, y),
        Offset(size.width * 0.5 + halfWidth, y),
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: <Color>[
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: alpha),
                  Colors.white.withValues(alpha: alpha),
                  Colors.white.withValues(alpha: 0.0),
                ],
                stops: const <double>[0.0, 0.28, 0.72, 1.0],
              ).createShader(
                Rect.fromLTWH(
                  size.width * 0.5 - halfWidth,
                  y - 0.5,
                  halfWidth * 2,
                  1,
                ),
              )
          ..strokeWidth = _mix(0.8, 2.2, t),
      );
    }

    for (var i = 0; i < 10; i += 1) {
      final t = ((ambientProgress * 1.25) + i * 0.12) % 1.0;
      final depth = Curves.easeIn.transform(t);
      final y = _mix(vanishing.dy + 12, size.height * 0.96, depth);
      final width = _mix(3, 18, depth);
      final height = _mix(8, 38, depth);
      final alpha = 0.04 + depth * 0.18;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * 0.5, y),
            width: width,
            height: height,
          ),
          const Radius.circular(999),
        ),
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.white.withValues(alpha: alpha),
                  Colors.white.withValues(alpha: alpha * 0.5),
                ],
              ).createShader(
                Rect.fromCenter(
                  center: Offset(size.width * 0.5, y),
                  width: width,
                  height: height,
                ),
              ),
      );
    }

    final flow = (ambientProgress * 1.8 + phase * 0.14) % 1.0;
    for (var i = 0; i < 8; i += 1) {
      final t = ((flow + i * 0.14) % 1.0);
      final depth = Curves.easeIn.transform(t);
      final scale = _mix(0.22, 1.18, depth);
      final y = _mix(vanishing.dy + 28, size.height * 0.92, depth);
      final x = size.width * 0.5 + (i.isEven ? -1 : 1) * _mix(6, 48, depth);
      final opacity = _mix(0.06, 0.42, depth);
      _drawFootprint(
        canvas,
        center: Offset(x, y),
        active: false,
        pulse: pulse,
        color: Colors.white.withValues(alpha: opacity),
        scale: scale,
        rotation: (i.isEven ? -1.0 : 1.0) * _mix(0.02, 0.22, depth),
      );
    }

    final strideLift = math.sin(math.pi * phase).abs();
    final impactSquash = strideLift * 0.12;
    final leadY = _mix(size.height * 0.88, size.height * 0.62, phase);
    final trailY = _mix(size.height * 0.68, size.height * 0.88, phase);

    if (leftActive) {
      _drawFootprint(
        canvas,
        center: Offset(size.width * 0.5 - 32, leadY),
        active: true,
        pulse: pulse + strideLift * 0.42,
        color: _accentColor,
        scale: 1.22 - impactSquash * 0.5,
        rotation: -0.16,
        squash: impactSquash,
      );
      _drawFootprint(
        canvas,
        center: Offset(size.width * 0.5 + 32, trailY),
        active: false,
        pulse: pulse + strideLift * 0.28,
        color: Colors.white.withValues(alpha: 0.88),
        scale: 0.98,
        rotation: 0.08,
      );
    } else {
      _drawFootprint(
        canvas,
        center: Offset(size.width * 0.5 + 32, leadY),
        active: true,
        pulse: pulse + strideLift * 0.42,
        color: _accentColor,
        scale: 1.22 - impactSquash * 0.5,
        rotation: 0.16,
        squash: impactSquash,
      );
      _drawFootprint(
        canvas,
        center: Offset(size.width * 0.5 - 32, trailY),
        active: false,
        pulse: pulse + strideLift * 0.28,
        color: Colors.white.withValues(alpha: 0.88),
        scale: 0.98,
        rotation: -0.08,
      );
    }

    final groundGlowAlpha = 0.18 + strideLift * 0.16;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          size.width * 0.5 + (leftActive ? -32 : 32),
          size.height * 0.90,
        ),
        width: 56 + pulse * 18,
        height: 14 + pulse * 4,
      ),
      Paint()
        ..color = _accentColor.withValues(alpha: groundGlowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  void _drawFootprint(
    Canvas canvas, {
    required Offset center,
    required bool active,
    required double pulse,
    required Color color,
    double scale = 1.0,
    double rotation = 0.0,
    double squash = 0.0,
  }) {
    final actualScale = active ? scale * (1.0 + pulse * 0.08) : scale;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final sole = Rect.fromCenter(
      center: Offset.zero,
      width: 36 * actualScale * (1 + squash * 0.35),
      height: 74 * actualScale * (1 - squash * 0.55),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, 18 * actualScale),
        width: sole.width * 0.78,
        height: sole.height * 0.28,
      ),
      Paint()
        ..shader =
            RadialGradient(
              colors: <Color>[
                Colors.black.withValues(alpha: active ? 0.28 : 0.14),
                Colors.black.withValues(alpha: 0.0),
              ],
            ).createShader(
              Rect.fromCenter(
                center: Offset(0, 18 * actualScale),
                width: sole.width * 0.78,
                height: sole.height * 0.28,
              ),
            ),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sole, Radius.circular(20 * actualScale)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            color.withValues(alpha: active ? 0.98 : 0.62),
            color.withValues(alpha: active ? 0.82 : 0.38),
            color.withValues(alpha: active ? 0.65 : 0.25),
          ],
          stops: const <double>[0.0, 0.55, 1.0],
        ).createShader(sole),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sole, Radius.circular(20 * actualScale)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: active ? 0.32 : 0.12),
    );
    for (final toe in <Offset>[
      Offset(-9 * actualScale, -28 * actualScale),
      Offset(0, -33 * actualScale),
      Offset(9 * actualScale, -27 * actualScale),
    ]) {
      canvas.drawCircle(
        toe,
        5.6 * actualScale,
        Paint()
          ..shader =
              RadialGradient(
                center: const Alignment(-0.18, -0.28),
                colors: <Color>[
                  color.withValues(alpha: active ? 0.96 : 0.42),
                  color.withValues(alpha: active ? 0.78 : 0.28),
                ],
              ).createShader(
                Rect.fromCircle(center: toe, radius: 5.6 * actualScale),
              ),
      );
    }
    if (active) {
      canvas.drawCircle(
        Offset(-9 * actualScale, -28 * actualScale),
        5.6 * actualScale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.42),
      );
      canvas.drawCircle(
        Offset(-4 * actualScale, -32 * actualScale),
        1.8 * actualScale,
        Paint()..color = Colors.white.withValues(alpha: 0.62),
      );
    }
    canvas.restore();
  }

  void _paintBeatIndicators(Canvas canvas, Size size, double pulse) {
    final spacing = 12.0;
    final count = subdivision.clamp(1, 6);
    final totalWidth = (count - 1) * spacing;
    final startX = size.width * 0.5 - totalWidth * 0.5;
    final y = size.height - 22;
    final padRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, y),
        width: totalWidth + 28,
        height: 18,
      ),
      const Radius.circular(999),
    );
    canvas.drawRRect(
      padRect,
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );
    for (var i = 0; i < count; i += 1) {
      final active =
          activeSubPulse > 0 && i == (activeSubPulse - 1).clamp(0, count - 1);
      canvas.drawCircle(
        Offset(startX + i * spacing, y),
        active ? 4.2 + pulse * 1.3 : 3,
        Paint()
          ..color = (active ? _accentColor : Colors.white).withValues(
            alpha: active ? 0.94 : 0.34,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LegacyFocusBeatVisualizerPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.ambientProgress != ambientProgress ||
        oldDelegate.accentLayer != accentLayer ||
        oldDelegate.running != running ||
        oldDelegate.activeBeat != activeBeat ||
        oldDelegate.activeSubPulse != activeSubPulse ||
        oldDelegate.subdivision != subdivision;
  }
}

void _drawFocusGear(
  Canvas canvas, {
  required Offset center,
  required double radius,
  required int teeth,
  required double rotation,
  required Color color,
  required double pulse,
}) {
  final innerRadius = radius * 0.76;
  final outerRadius = radius * 1.08;
  final gearPath = Path();
  for (var i = 0; i < teeth * 2; i += 1) {
    final isTooth = i.isEven;
    final angle = rotation + i * math.pi / teeth;
    final r = isTooth ? outerRadius : innerRadius;
    final point = Offset(
      center.dx + math.cos(angle) * r,
      center.dy + math.sin(angle) * r,
    );
    if (i == 0) {
      gearPath.moveTo(point.dx, point.dy);
    } else {
      gearPath.lineTo(point.dx, point.dy);
    }
  }
  gearPath.close();

  canvas.drawPath(
    gearPath,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.22, -0.38),
        radius: 1.1,
        colors: <Color>[
          Colors.white.withValues(alpha: 1.0),
          color.withValues(alpha: 0.92),
          const Color(0xFF8A9AAB).withValues(alpha: 0.88),
          const Color(0xFF3A4350).withValues(alpha: 0.94),
        ],
        stops: const <double>[0.0, 0.28, 0.58, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius)),
  );
  canvas.drawPath(
    gearPath,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white.withValues(alpha: 0.32),
  );

  final hubRadius = radius * 0.58;
  canvas.drawCircle(
    center,
    hubRadius,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.18, -0.28),
        colors: <Color>[
          const Color(0xFFF8FAFC).withValues(alpha: 0.96),
          const Color(0xFFB8C4D0).withValues(alpha: 0.92),
          const Color(0xFF6B7788).withValues(alpha: 0.88),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: hubRadius)),
  );
  canvas.drawCircle(
    center,
    hubRadius,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.28),
  );
  canvas.drawCircle(
    center,
    radius * 0.22,
    Paint()
      ..shader = const RadialGradient(
        colors: <Color>[Color(0xFF2A3038), Color(0xFF181E24)],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.22)),
  );

  for (var i = 0; i < 6; i += 1) {
    final angle = rotation + i * math.pi / 3;
    final start = Offset(
      center.dx + math.cos(angle) * radius * 0.22,
      center.dy + math.sin(angle) * radius * 0.22,
    );
    final end = Offset(
      center.dx + math.cos(angle) * radius * 0.52,
      center.dy + math.sin(angle) * radius * 0.52,
    );
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );
  }

  canvas.drawArc(
    Rect.fromCircle(center: center, radius: outerRadius + 4),
    rotation - 0.5,
    0.58 + pulse * 0.22,
    false,
    Paint()
      ..shader = SweepGradient(
        startAngle: rotation - 0.5,
        endAngle: rotation + 0.08 + pulse * 0.22,
        colors: <Color>[
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.38),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius + 4))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4,
  );

  canvas.drawCircle(
    center,
    radius * 0.08,
    Paint()
      ..shader = const RadialGradient(
        colors: <Color>[Color(0xFFD8A850), Color(0xFF8A5828)],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.08)),
  );
}

void _drawBalanceWheel(
  Canvas canvas, {
  required Offset center,
  required double radius,
  required double rotation,
  required double pulse,
}) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(rotation);
  final ringRect = Rect.fromCircle(center: Offset.zero, radius: radius);
  canvas.drawCircle(
    Offset.zero,
    radius,
    Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.18, -0.28),
        colors: <Color>[
          Color(0xFFF8FCFF),
          Color(0xFFD0D8E4),
          Color(0xFF9EA8B6),
          Color(0xFF4C5564),
        ],
        stops: <double>[0.0, 0.32, 0.62, 1.0],
      ).createShader(ringRect),
  );
  canvas.drawCircle(
    Offset.zero,
    radius,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Colors.white.withValues(alpha: 0.38),
  );
  canvas.drawCircle(
    Offset.zero,
    radius * 0.72,
    Paint()
      ..shader =
          const RadialGradient(
            colors: <Color>[Color(0xFF1A2028), Color(0xFF0E1418)],
          ).createShader(
            Rect.fromCircle(center: Offset.zero, radius: radius * 0.72),
          ),
  );
  for (var i = 0; i < 6; i += 1) {
    final angle = i * math.pi / 3;
    final end = Offset(
      math.cos(angle) * radius * 0.78,
      math.sin(angle) * radius * 0.78,
    );
    canvas.drawLine(
      Offset.zero,
      end,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.42)
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );
  }
  for (var i = 0; i < 12; i += 1) {
    final angle = i * math.pi / 6;
    final tickEnd = Offset(
      math.cos(angle) * radius * 0.68,
      math.sin(angle) * radius * 0.68,
    );
    canvas.drawCircle(
      tickEnd,
      1.8,
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );
  }
  canvas.drawCircle(
    Offset.zero,
    radius * 0.18,
    Paint()
      ..shader =
          const RadialGradient(
            center: Alignment(-0.24, -0.32),
            colors: <Color>[
              Color(0xFFFEE8B4),
              Color(0xFFD8A848),
              Color(0xFF9B6C24),
            ],
          ).createShader(
            Rect.fromCircle(center: Offset.zero, radius: radius * 0.18),
          ),
  );
  canvas.drawCircle(
    Offset.zero,
    radius * 0.18,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFE8C078).withValues(alpha: 0.48),
  );
  canvas.restore();

  canvas.drawArc(
    Rect.fromCircle(
      center: center.translate(0, -radius * 0.12),
      radius: radius * 1.18,
    ),
    math.pi * 1.02,
    math.pi * 0.96,
    false,
    Paint()
      ..shader =
          SweepGradient(
            startAngle: math.pi * 1.02,
            endAngle: math.pi * 1.98,
            colors: <Color>[
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.82),
              Colors.white.withValues(alpha: 0.62),
              Colors.white.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: center.translate(0, -radius * 0.12),
              radius: radius * 1.18,
            ),
          )
      ..strokeWidth = 6.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke,
  );
  canvas.drawCircle(
    center,
    radius + 8 + pulse * 4,
    Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              const Color(0xFF96D9FF).withValues(alpha: 0.14),
              const Color(0xFF96D9FF).withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: radius + 8 + pulse * 4),
          )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
  );
}

void _drawMovementScrew(
  Canvas canvas, {
  required Offset center,
  required double radius,
}) {
  final rect = Rect.fromCircle(center: center, radius: radius);
  canvas.drawCircle(
    center,
    radius + 1,
    Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.28, -0.32),
        colors: <Color>[
          Color(0xFFF4F8FC),
          Color(0xFFD0D4DA),
          Color(0xFF8A9AA8),
          Color(0xFF3A4A58),
        ],
        stops: <double>[0.0, 0.32, 0.62, 1.0],
      ).createShader(rect),
  );
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.28),
  );
  canvas.drawLine(
    center.translate(-radius * 0.48, 0),
    center.translate(radius * 0.48, 0),
    Paint()
      ..color = const Color(0xFF1A2432).withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round,
  );
  canvas.drawLine(
    center.translate(0, -radius * 0.48),
    center.translate(0, radius * 0.48),
    Paint()
      ..color = const Color(0xFF1A2432).withValues(alpha: 0.32)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round,
  );
  canvas.drawCircle(
    center.translate(-radius * 0.18, -radius * 0.18),
    radius * 0.15,
    Paint()..color = Colors.white.withValues(alpha: 0.42),
  );
}

class _FocusBeatVisualizerPainter extends CustomPainter {
  const _FocusBeatVisualizerPainter({
    required this.kind,
    required this.pulseProgress,
    required this.ambientProgress,
    required this.accentLayer,
    required this.running,
    required this.activeBeat,
    required this.activeSubPulse,
    required this.subdivision,
  });

  final _FocusBeatAnimationKind kind;
  final double pulseProgress;
  final double ambientProgress;
  final int accentLayer;
  final bool running;
  final int activeBeat;
  final int activeSubPulse;
  final int subdivision;

  double _mix(double a, double b, double t) => a + (b - a) * t;

  Color _mixColor(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  Color get _layerAccent => switch (accentLayer) {
    0 => const Color(0xFFF3C77C),
    1 => const Color(0xFFF2A88E),
    2 => const Color(0xFF8CCFF8),
    _ => const Color(0xFF8FDEC4),
  };

  _FocusVisualizerTheme get _theme => switch (kind) {
    _FocusBeatAnimationKind.pendulum => const _FocusVisualizerTheme(
      base: Color(0xFF0B1720),
      mid: Color(0xFF142938),
      surface: Color(0xFF1E4054),
      accent: Color(0xFF82C6FF),
      secondary: Color(0xFF78E0D1),
      highlight: Color(0xFFF7E3B7),
    ),
    _FocusBeatAnimationKind.hypno => const _FocusVisualizerTheme(
      base: Color(0xFF16111D),
      mid: Color(0xFF291E35),
      surface: Color(0xFF43304F),
      accent: Color(0xFFB9A0FF),
      secondary: Color(0xFFFFBDD0),
      highlight: Color(0xFFF4EFFF),
    ),
    _FocusBeatAnimationKind.dew => const _FocusVisualizerTheme(
      base: Color(0xFF0A171B),
      mid: Color(0xFF13333A),
      surface: Color(0xFF1D5560),
      accent: Color(0xFF8DD8E5),
      secondary: Color(0xFF6ED6BE),
      highlight: Color(0xFFE9FFF9),
    ),
    _FocusBeatAnimationKind.gear => const _FocusVisualizerTheme(
      base: Color(0xFF101419),
      mid: Color(0xFF1D2A34),
      surface: Color(0xFF304451),
      accent: Color(0xFFA6CAE8),
      secondary: Color(0xFFF1C78D),
      highlight: Color(0xFFF2F7FB),
    ),
    _FocusBeatAnimationKind.steps => const _FocusVisualizerTheme(
      base: Color(0xFF101611),
      mid: Color(0xFF1B3121),
      surface: Color(0xFF2E4A37),
      accent: Color(0xFF91D39E),
      secondary: Color(0xFFB8E4C1),
      highlight: Color(0xFFF1F7EA),
    ),
  };

  double get _phase => pulseProgress.clamp(0.0, 1.0);

  double get _beatEnergy =>
      running ? 1 - Curves.easeOutCubic.transform(_phase) : 0.0;

  double get _ambientAngle => ambientProgress.clamp(0.0, 1.0) * math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    final theme = _theme;
    final beat = _beatEnergy;
    final ambient = _ambientAngle;
    final breath = 0.5 + 0.5 * math.sin(ambient - math.pi / 2);
    final accent = _mixColor(theme.accent, _layerAccent, 0.32);
    final glow = _mixColor(theme.secondary, _layerAccent, 0.18);

    _paintBackdrop(
      canvas,
      size,
      theme: theme,
      accent: accent,
      glow: glow,
      beat: beat,
      breath: breath,
      ambient: ambient,
    );

    switch (kind) {
      case _FocusBeatAnimationKind.pendulum:
        _paintPendulum(canvas, size, theme, accent, glow, beat, ambient);
        break;
      case _FocusBeatAnimationKind.hypno:
        _paintHypno(canvas, size, theme, accent, glow, beat, ambient, breath);
        break;
      case _FocusBeatAnimationKind.dew:
        _paintDew(canvas, size, theme, accent, glow, beat, ambient);
        break;
      case _FocusBeatAnimationKind.gear:
        _paintGear(canvas, size, theme, accent, glow, beat, ambient);
        break;
      case _FocusBeatAnimationKind.steps:
        _paintSteps(canvas, size, theme, accent, glow, beat, ambient);
        break;
    }

    _paintPulseDock(canvas, size, theme, accent, beat);
  }

  void _paintBackdrop(
    Canvas canvas,
    Size size, {
    required _FocusVisualizerTheme theme,
    required Color accent,
    required Color glow,
    required double beat,
    required double breath,
    required double ambient,
  }) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            theme.base,
            theme.mid,
            _mixColor(theme.surface, Colors.black, 0.10),
          ],
          stops: const <double>[0.0, 0.48, 1.0],
        ).createShader(rect),
    );

    _paintGlow(
      canvas,
      Offset(
        size.width * 0.20 + math.cos(ambient * 0.9) * size.width * 0.05,
        size.height * 0.20 + math.sin(ambient * 0.65) * size.height * 0.03,
      ),
      size.width * 0.30,
      accent.withValues(alpha: 0.11 + beat * 0.05),
      blur: 42,
    );
    _paintGlow(
      canvas,
      Offset(
        size.width * 0.78 + math.sin(ambient * 0.55) * size.width * 0.04,
        size.height * 0.74 + math.cos(ambient * 0.72) * size.height * 0.04,
      ),
      size.width * 0.36,
      glow.withValues(alpha: 0.10 + breath * 0.05),
      blur: 54,
    );

    _paintRibbon(
      canvas,
      size,
      y: size.height * 0.26,
      drift: math.sin(ambient * 0.72) * 18,
      amplitude: 22,
      thickness: 20,
      color: theme.highlight.withValues(alpha: 0.045),
    );
    _paintRibbon(
      canvas,
      size,
      y: size.height * 0.60,
      drift: math.cos(ambient * 0.84) * 22,
      amplitude: 28,
      thickness: 28,
      color: accent.withValues(alpha: 0.05),
    );

    final scanY = size.height * (0.34 + breath * 0.16);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(0, (scanY / size.height) * 2 - 1),
          end: Alignment(
            0,
            ((scanY + size.height * 0.22) / size.height) * 2 - 1,
          ),
          colors: <Color>[
            Colors.transparent,
            Colors.white.withValues(alpha: 0.025 + beat * 0.01),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Colors.transparent,
            Colors.black.withValues(alpha: running ? 0.28 : 0.34),
          ],
          stops: const <double>[0.56, 1.0],
        ).createShader(rect),
    );
  }

  void _paintPendulum(
    Canvas canvas,
    Size size,
    _FocusVisualizerTheme theme,
    Color accent,
    Color glow,
    double beat,
    double ambient,
  ) {
    final pivot = Offset(size.width * 0.5, size.height * 0.22);
    final length = size.height * 0.36;
    final direction = activeBeat >= 0 && activeBeat.isOdd ? -1.0 : 1.0;
    final travel = direction * math.cos(_phase * math.pi);
    final angle = travel * 0.64;
    final bob =
        pivot + Offset(math.sin(angle) * length, math.cos(angle) * length);

    final arcRect = Rect.fromCircle(center: pivot, radius: length);
    for (var i = 0; i < 3; i += 1) {
      final radius = length + i * 12.0;
      canvas.drawArc(
        Rect.fromCircle(center: pivot, radius: radius),
        math.pi / 2 - 0.70,
        1.40,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06 - i * 0.015)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    for (var i = 1; i <= 5; i += 1) {
      final samplePhase = (_phase - i * 0.10).clamp(0.0, 1.0);
      final sampleTravel = direction * math.cos(samplePhase * math.pi);
      final sampleAngle = sampleTravel * 0.64;
      final sampleBob =
          pivot +
          Offset(
            math.sin(sampleAngle) * length,
            math.cos(sampleAngle) * length,
          );
      canvas.drawCircle(
        sampleBob,
        12 - i * 1.8,
        Paint()
          ..color = accent.withValues(alpha: 0.10 - i * 0.012)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    canvas.drawLine(
      pivot,
      bob,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            theme.highlight.withValues(alpha: 0.34),
            accent.withValues(alpha: 0.88),
          ],
        ).createShader(Rect.fromPoints(pivot, bob))
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    _paintGlow(
      canvas,
      pivot,
      22 + beat * 8,
      theme.highlight.withValues(alpha: 0.16),
      blur: 18,
    );
    canvas.drawCircle(
      pivot,
      5.5,
      Paint()..color = Colors.white.withValues(alpha: 0.86),
    );

    _paintGlow(
      canvas,
      bob,
      34 + beat * 18,
      glow.withValues(alpha: 0.22 + beat * 0.08),
      blur: 28,
    );
    canvas.drawCircle(
      bob,
      19 + beat * 5,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            theme.highlight.withValues(alpha: 0.96),
            accent.withValues(alpha: 0.84),
            accent.withValues(alpha: 0.10),
          ],
          stops: const <double>[0.0, 0.58, 1.0],
        ).createShader(Rect.fromCircle(center: bob, radius: 24 + beat * 8)),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bob.dx, size.height * 0.78),
        width: 96 + beat * 26,
        height: 18 + beat * 6,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
  }

  void _paintHypno(
    Canvas canvas,
    Size size,
    _FocusVisualizerTheme theme,
    Color accent,
    Color glow,
    double beat,
    double ambient,
    double breath,
  ) {
    final center = Offset(size.width * 0.5, size.height * 0.48);
    final baseRadius = size.shortestSide * 0.15;

    for (var i = 0; i < 6; i += 1) {
      final radius = baseRadius + size.shortestSide * 0.08 * i + breath * 6;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.10 - i * 0.012)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    for (var i = 0; i < 4; i += 1) {
      final radius = baseRadius + size.shortestSide * (0.08 + i * 0.10);
      final rect = Rect.fromCircle(center: center, radius: radius);
      final rotation =
          ambient * (0.34 + i * 0.12) * (i.isEven ? 1 : -1) + i * 0.8;
      final sweep = 0.74 + beat * 0.38 - i * 0.04;
      canvas.drawArc(
        rect,
        rotation,
        sweep,
        false,
        Paint()
          ..shader = SweepGradient(
            startAngle: rotation,
            endAngle: rotation + sweep,
            colors: <Color>[
              Colors.transparent,
              accent.withValues(alpha: 0.58 - i * 0.08),
              theme.highlight.withValues(alpha: 0.16),
            ],
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9 - i * 1.5
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawArc(
        rect,
        rotation + math.pi,
        sweep * 0.72,
        false,
        Paint()
          ..color = glow.withValues(alpha: 0.16 - i * 0.02)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 - i * 0.5
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.drawCircle(
      center,
      baseRadius * 0.54 + beat * 9,
      Paint()
        ..shader =
            RadialGradient(
              colors: <Color>[
                theme.highlight.withValues(alpha: 0.94),
                accent.withValues(alpha: 0.44),
                Colors.transparent,
              ],
              stops: const <double>[0.0, 0.48, 1.0],
            ).createShader(
              Rect.fromCircle(
                center: center,
                radius: baseRadius * 0.92 + beat * 14,
              ),
            ),
    );

    if (beat > 0.02) {
      canvas.drawCircle(
        center,
        baseRadius * (1.16 + beat * 1.8),
        Paint()
          ..color = glow.withValues(alpha: 0.22 * beat)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8 * beat + 1.2,
      );
    }
  }

  void _paintDew(
    Canvas canvas,
    Size size,
    _FocusVisualizerTheme theme,
    Color accent,
    Color glow,
    double beat,
    double ambient,
  ) {
    final surfaceY = size.height * 0.67;
    final centerX =
        size.width * 0.5 + math.sin(ambient * 0.62) * size.width * 0.05;
    final surfaceCenter = Offset(centerX, surfaceY);

    final poolRect = Rect.fromCenter(
      center: surfaceCenter,
      width: size.width * 0.42,
      height: size.height * 0.08,
    );
    canvas.drawOval(
      poolRect,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[accent.withValues(alpha: 0.18), Colors.transparent],
        ).createShader(poolRect),
    );

    for (var i = 0; i < 4; i += 1) {
      final radiusX = size.width * (0.10 + i * 0.07) + beat * size.width * 0.10;
      final radiusY = radiusX * 0.16;
      canvas.drawOval(
        Rect.fromCenter(
          center: surfaceCenter,
          width: radiusX * 2,
          height: radiusY * 2,
        ),
        Paint()
          ..color = Colors.white.withValues(
            alpha: 0.14 - i * 0.025 + beat * 0.05,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    final retract = Curves.easeOutCubic.transform(_phase);
    final dropCenter = Offset(
      centerX + math.sin(ambient * 1.08) * 10,
      _mix(surfaceY - 30, size.height * 0.30 + math.cos(ambient) * 8, retract),
    );
    final threadTop = Offset(centerX, size.height * 0.16);
    canvas.drawLine(
      threadTop,
      dropCenter.translate(0, -16),
      Paint()
        ..color = theme.highlight.withValues(alpha: 0.20)
        ..strokeWidth = 1.0,
    );

    final dropPath = _buildDropletPath(
      dropCenter,
      18 + beat * 4,
      28 + beat * 8,
    );
    final dropBounds = dropPath.getBounds();
    _paintGlow(
      canvas,
      dropCenter,
      28 + beat * 12,
      glow.withValues(alpha: 0.18 + beat * 0.08),
      blur: 22,
    );
    canvas.drawPath(
      dropPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            theme.highlight.withValues(alpha: 0.94),
            accent.withValues(alpha: 0.78),
            glow.withValues(alpha: 0.24),
          ],
          stops: const <double>[0.0, 0.56, 1.0],
        ).createShader(dropBounds),
    );
    canvas.drawPath(
      dropPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = Colors.white.withValues(alpha: 0.28),
    );

    for (var i = 0; i < 2; i += 1) {
      final bead = Offset(
        centerX + (i == 0 ? -1 : 1) * size.width * 0.12,
        size.height * (0.44 + i * 0.08) + math.sin(ambient + i) * 6,
      );
      canvas.drawCircle(
        bead,
        5 + i.toDouble(),
        Paint()
          ..color = theme.highlight.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
  }

  void _paintGear(
    Canvas canvas,
    Size size,
    _FocusVisualizerTheme theme,
    Color accent,
    Color glow,
    double beat,
    double ambient,
  ) {
    final center = Offset(size.width * 0.52, size.height * 0.48);
    final radii = <double>[
      size.shortestSide * 0.15,
      size.shortestSide * 0.24,
      size.shortestSide * 0.34,
    ];

    canvas.drawLine(
      Offset(center.dx - size.width * 0.24, center.dy),
      Offset(center.dx + size.width * 0.24, center.dy),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 1.0,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - size.height * 0.24),
      Offset(center.dx, center.dy + size.height * 0.24),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 1.0,
    );

    for (final radius in radii) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    for (var ring = 0; ring < radii.length; ring += 1) {
      final radius = radii[ring];
      final count = 4 + ring * 2;
      final rotation =
          ambient * (0.50 + ring * 0.20) * (ring.isEven ? 1 : -1) + ring * 0.36;
      final polygon = Path();
      for (var i = 0; i < count; i += 1) {
        final angle = rotation + i * math.pi * 2 / count;
        final point =
            center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
        if (i == 0) {
          polygon.moveTo(point.dx, point.dy);
        } else {
          polygon.lineTo(point.dx, point.dy);
        }
        canvas.drawCircle(
          point,
          4.0 + (ring == 1 ? beat * 1.8 : beat),
          Paint()
            ..color = _mixColor(
              accent,
              theme.highlight,
              ring * 0.22,
            ).withValues(alpha: 0.78 - ring * 0.14),
        );
      }
      polygon.close();
      canvas.drawPath(
        polygon,
        Paint()
          ..color = glow.withValues(alpha: 0.10 - ring * 0.015)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    final sweepRect = Rect.fromCircle(center: center, radius: radii.last + 12);
    final start = ambient * 0.92;
    final sweep = 0.74 + beat * 0.30;
    canvas.drawArc(
      sweepRect,
      start,
      sweep,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: start,
          endAngle: start + sweep,
          colors: <Color>[
            Colors.transparent,
            accent.withValues(alpha: 0.58),
            Colors.transparent,
          ],
        ).createShader(sweepRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    _paintGlow(
      canvas,
      center,
      34 + beat * 12,
      glow.withValues(alpha: 0.16 + beat * 0.08),
      blur: 20,
    );
    canvas.drawCircle(
      center,
      18 + beat * 4,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            theme.highlight.withValues(alpha: 0.92),
            accent.withValues(alpha: 0.74),
            theme.base.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 24 + beat * 8)),
    );
  }

  void _paintSteps(
    Canvas canvas,
    Size size,
    _FocusVisualizerTheme theme,
    Color accent,
    Color glow,
    double beat,
    double ambient,
  ) {
    const profile = <double>[0.28, 0.42, 0.58, 0.76, 0.58, 0.42, 0.28];
    final bars = profile.length;
    final barWidth = size.width * 0.075;
    final gap = size.width * 0.028;
    final totalWidth = bars * barWidth + (bars - 1) * gap;
    final startX = (size.width - totalWidth) / 2;
    final baseY = size.height * 0.74;
    final fieldHeight = size.height * 0.42;
    final scanT = 0.5 + 0.5 * math.sin(ambient * 0.56 - math.pi / 2);
    final scanX = _mix(startX, startX + totalWidth, scanT);
    final skyline = Path();

    canvas.drawLine(
      Offset(size.width * 0.16, baseY + 4),
      Offset(size.width * 0.84, baseY + 4),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..strokeWidth = 1.2,
    );

    for (var i = 0; i < bars; i += 1) {
      final x = startX + i * (barWidth + gap);
      final centerX = x + barWidth / 2;
      final dist = ((centerX - scanX).abs() / (barWidth * 2.1)).clamp(0.0, 1.0);
      final influence = 1 - dist;
      final height = fieldHeight * profile[i] + influence * 18 + beat * 10;
      final rect = RRect.fromLTRBR(
        x,
        baseY - height,
        x + barWidth,
        baseY,
        Radius.circular(barWidth * 0.48),
      );
      final topCenter = Offset(centerX, baseY - height);

      if (i == 0) {
        skyline.moveTo(topCenter.dx, topCenter.dy);
      } else {
        skyline.lineTo(topCenter.dx, topCenter.dy);
      }

      if (influence > 0.02) {
        _paintGlow(
          canvas,
          Offset(centerX, baseY - height * 0.56),
          18 + influence * 12,
          accent.withValues(alpha: influence * 0.10),
          blur: 18,
        );
      }

      canvas.drawRRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: <Color>[
              theme.surface.withValues(alpha: 0.92),
              _mixColor(
                accent,
                theme.highlight,
                influence * 0.42,
              ).withValues(alpha: 0.90),
            ],
          ).createShader(rect.outerRect),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Colors.white.withValues(alpha: 0.16 + influence * 0.14),
      );
    }

    canvas.drawPath(
      skyline,
      Paint()
        ..color = glow.withValues(alpha: 0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final scanRect = Rect.fromLTRB(
      scanX - barWidth * 0.72,
      baseY - fieldHeight * 0.98,
      scanX + barWidth * 0.72,
      baseY + 10,
    );
    canvas.drawRect(
      scanRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            accent.withValues(alpha: 0.0),
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.0),
          ],
        ).createShader(scanRect),
    );
  }

  void _paintPulseDock(
    Canvas canvas,
    Size size,
    _FocusVisualizerTheme theme,
    Color accent,
    double beat,
  ) {
    final width = math.min(size.width * 0.44, 180.0);
    final dockRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.89),
      width: width,
      height: 18,
    );
    final dock = RRect.fromRectAndRadius(dockRect, const Radius.circular(999));
    canvas.drawRRect(
      dock,
      Paint()..color = Colors.black.withValues(alpha: 0.20),
    );
    canvas.drawRRect(
      dock,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.10),
    );

    final count = math.max(1, subdivision);
    final spacing = dockRect.width / (count + 1);
    for (var i = 0; i < count; i += 1) {
      final active =
          activeSubPulse > 0 && i == (activeSubPulse - 1).clamp(0, count - 1);
      final center = Offset(
        dockRect.left + spacing * (i + 1),
        dockRect.center.dy,
      );
      final radius = active ? 4.6 + beat * 2.2 : 2.6;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = (active ? accent : theme.highlight).withValues(
            alpha: active ? 0.94 : 0.32,
          ),
      );
    }

    if (beat > 0.02) {
      canvas.drawRRect(
        dock,
        Paint()
          ..color = accent.withValues(alpha: 0.08 * beat)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  void _paintGlow(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    double blur = 24,
  }) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
    );
  }

  void _paintRibbon(
    Canvas canvas,
    Size size, {
    required double y,
    required double drift,
    required double amplitude,
    required double thickness,
    required Color color,
  }) {
    final path = Path()
      ..moveTo(-size.width * 0.08, y)
      ..cubicTo(
        size.width * 0.14,
        y - amplitude + drift * 0.28,
        size.width * 0.40,
        y + amplitude * 0.9 - drift * 0.18,
        size.width * 0.66,
        y + drift * 0.22,
      )
      ..cubicTo(
        size.width * 0.86,
        y - amplitude * 0.55 - drift * 0.12,
        size.width * 1.02,
        y + amplitude * 0.22,
        size.width * 1.08,
        y - drift * 0.18,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
  }

  Path _buildDropletPath(Offset center, double width, double height) {
    return Path()
      ..moveTo(center.dx, center.dy - height * 0.72)
      ..quadraticBezierTo(
        center.dx + width * 0.56,
        center.dy - height * 0.20,
        center.dx + width * 0.42,
        center.dy + height * 0.20,
      )
      ..quadraticBezierTo(
        center.dx + width * 0.24,
        center.dy + height * 0.66,
        center.dx,
        center.dy + height * 0.82,
      )
      ..quadraticBezierTo(
        center.dx - width * 0.24,
        center.dy + height * 0.66,
        center.dx - width * 0.42,
        center.dy + height * 0.20,
      )
      ..quadraticBezierTo(
        center.dx - width * 0.56,
        center.dy - height * 0.20,
        center.dx,
        center.dy - height * 0.72,
      )
      ..close();
  }

  @override
  bool shouldRepaint(covariant _FocusBeatVisualizerPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.ambientProgress != ambientProgress ||
        oldDelegate.accentLayer != accentLayer ||
        oldDelegate.running != running ||
        oldDelegate.activeBeat != activeBeat ||
        oldDelegate.activeSubPulse != activeSubPulse ||
        oldDelegate.subdivision != subdivision;
  }
}

class _FocusVisualizerTheme {
  const _FocusVisualizerTheme({
    required this.base,
    required this.mid,
    required this.surface,
    required this.accent,
    required this.secondary,
    required this.highlight,
  });

  final Color base;
  final Color mid;
  final Color surface;
  final Color accent;
  final Color secondary;
  final Color highlight;
}

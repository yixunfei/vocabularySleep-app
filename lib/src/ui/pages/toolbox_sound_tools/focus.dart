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

  List<Color> _stageColors() {
    return switch (_animationKind) {
      _FocusBeatAnimationKind.pendulum => const <Color>[
        Color(0xFF102338),
        Color(0xFF1B3B5C),
      ],
      _FocusBeatAnimationKind.hypno => const <Color>[
        Color(0xFF2A1244),
        Color(0xFF4D1E73),
      ],
      _FocusBeatAnimationKind.dew => const <Color>[
        Color(0xFF0F2D3A),
        Color(0xFF1B5668),
      ],
      _FocusBeatAnimationKind.gear => const <Color>[
        Color(0xFF242A33),
        Color(0xFF3D4756),
      ],
      _FocusBeatAnimationKind.steps => const <Color>[
        Color(0xFF1E2A24),
        Color(0xFF365142),
      ],
    };
  }

  Widget _buildStage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final beatLabel = _activeBeat < 0 ? '--' : '${_activeBeat + 1}';
    final subLabel = _activeSubPulse == 0
        ? '--'
        : '$_activeSubPulse/$_subdivision';
    final screenWidth = MediaQuery.sizeOf(context).width;
    final stageHeight = widget.fullScreen
        ? (screenWidth * 0.66).clamp(320.0, 430.0)
        : (screenWidth * 0.72).clamp(280.0, 380.0);
    return Container(
      width: double.infinity,
      height: stageHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _stageColors(),
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
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
                left: 16,
                top: 14,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
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
                right: 16,
                top: 58,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
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
                left: 16,
                right: 16,
                bottom: 14,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          _animationSyncHint(_animationKind),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _soundSyncHint(_soundKind),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                height: 1.3,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
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
        const SectionHeader(
          title: '专注节拍工作台',
          subtitle: '围绕手机单手操作重构了节奏、风格、编排与触感设置，首屏只保留最关键的开播信息。',
        ),
        const SizedBox(height: 12),
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
        Row(
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
        const SizedBox(height: 10),
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
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: expanded ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
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
                          const SizedBox(height: 8),
                          Text(
                            summary,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: colorScheme.onSurfaceVariant,
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
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
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
  });

  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: emphasized
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: emphasized ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 16,
            color: emphasized
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: emphasized ? colorScheme.primary : colorScheme.onSurface,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.95)),
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
    final angle = swingDirection * harmonic * 0.44;
    final frameRect = Rect.fromLTWH(
      size.width * 0.18,
      size.height * 0.08,
      size.width * 0.64,
      size.height * 0.8,
    );
    final chamberRect = Rect.fromLTWH(
      size.width * 0.31,
      size.height * 0.28,
      size.width * 0.38,
      size.height * 0.42,
    );
    final dialCenter = Offset(size.width * 0.5, size.height * 0.19);
    final pivot = Offset(size.width * 0.5, size.height * 0.30);
    final length = size.height * 0.40;
    final bob = Offset(
      pivot.dx + math.sin(angle) * length,
      pivot.dy + math.cos(angle) * length,
    );

    canvas.drawShadow(
      Path()..addRRect(
        RRect.fromRectAndRadius(frameRect, const Radius.circular(18)),
      ),
      Colors.black.withValues(alpha: 0.38),
      14,
      false,
    );

    final cabinetPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF6D4326),
          Color(0xFF4A2B1A),
          Color(0xFF7C5032),
        ],
      ).createShader(frameRect);

    final baseRect = Rect.fromLTWH(
      size.width * 0.22,
      size.height * 0.77,
      size.width * 0.56,
      size.height * 0.11,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(16)),
      cabinetPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(16)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFFB88958).withValues(alpha: 0.38),
    );

    final columnWidth = size.width * 0.055;
    _drawPendulumColumn(
      canvas,
      rect: Rect.fromLTWH(
        size.width * 0.22,
        size.height * 0.22,
        columnWidth,
        size.height * 0.56,
      ),
    );
    _drawPendulumColumn(
      canvas,
      rect: Rect.fromLTWH(
        size.width * 0.725,
        size.height * 0.22,
        columnWidth,
        size.height * 0.56,
      ),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(chamberRect, const Radius.circular(22)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF1B120C), Color(0xFF110A06)],
        ).createShader(chamberRect),
    );

    final headRect = Rect.fromLTWH(
      size.width * 0.24,
      size.height * 0.08,
      size.width * 0.52,
      size.height * 0.18,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        headRect,
        topLeft: const Radius.circular(34),
        topRight: const Radius.circular(34),
        bottomLeft: const Radius.circular(14),
        bottomRight: const Radius.circular(14),
      ),
      cabinetPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        headRect,
        topLeft: const Radius.circular(34),
        topRight: const Radius.circular(34),
        bottomLeft: const Radius.circular(14),
        bottomRight: const Radius.circular(14),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFB98A59).withValues(alpha: 0.4),
    );

    _drawClockDial(
      canvas,
      center: dialCenter,
      radius: size.shortestSide * 0.14,
    );

    final trailStrength = (motionEnergy * 0.75).clamp(0.0, 1.0);
    for (var i = 1; i <= 3; i += 1) {
      final trailPhase = (phase - i * 0.12).clamp(0.0, 1.0);
      final trailAngle = swingDirection * math.cos(math.pi * trailPhase) * 0.44;
      final trailBob = Offset(
        pivot.dx + math.sin(trailAngle) * length,
        pivot.dy + math.cos(trailAngle) * length,
      );
      canvas.drawLine(
        pivot,
        trailBob,
        Paint()
          ..color = const Color(
            0xFFE9D7B0,
          ).withValues(alpha: trailStrength * (0.14 - i * 0.025))
          ..strokeWidth = 2.4 - i * 0.35,
      );
      canvas.drawCircle(
        trailBob,
        15 - i * 2.5,
        Paint()
          ..color = _accentColor.withValues(
            alpha: trailStrength * (0.1 - i * 0.015),
          ),
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
      bob.translate(0, 5),
      22 + motionEnergy * 7,
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );
    final bobRadius = 20 + pulse * 5.5;
    canvas.drawCircle(
      bob,
      bobRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.26, -0.34),
          radius: 0.95,
          colors: <Color>[
            const Color(0xFFFFF2C5).withValues(alpha: 0.98),
            const Color(0xFFD9A84F).withValues(alpha: 0.95),
            const Color(0xFF7C4C1D).withValues(alpha: 0.95),
          ],
          stops: const <double>[0.0, 0.42, 1.0],
        ).createShader(Rect.fromCircle(center: bob, radius: bobRadius + 6)),
    );
    canvas.drawCircle(
      bob,
      bobRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFFFFEDC4).withValues(alpha: 0.55),
    );
    canvas.drawCircle(
      bob.translate(-6, -8),
      4.4,
      Paint()..color = Colors.white.withValues(alpha: 0.72),
    );
    canvas.drawCircle(
      bob,
      bobRadius + 5 + motionEnergy * 4,
      Paint()
        ..color = _accentColor.withValues(alpha: 0.16 + motionEnergy * 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
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
      center: Offset(0, distance * 0.17),
      width: 4.5,
      height: distance * 0.34,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(stemRect, const Radius.circular(999)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFEAD9A8), Color(0xFFA27032)],
        ).createShader(stemRect),
    );

    final lyreHeight = distance * 0.22;
    final lyreTop = distance * 0.28;
    final leftRail = Path()
      ..moveTo(-10, lyreTop)
      ..quadraticBezierTo(
        -18,
        lyreTop + lyreHeight * 0.25,
        -10,
        lyreTop + lyreHeight,
      )
      ..moveTo(10, lyreTop)
      ..quadraticBezierTo(
        18,
        lyreTop + lyreHeight * 0.25,
        10,
        lyreTop + lyreHeight,
      );
    canvas.drawPath(
      leftRail,
      Paint()
        ..color = const Color(0xFFDEB668).withValues(alpha: 0.96)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < 3; i += 1) {
      final y = lyreTop + lyreHeight * (0.18 + i * 0.24);
      canvas.drawLine(
        Offset(-9.2, y),
        Offset(9.2, y),
        Paint()
          ..color = const Color(0xFFF6E2A5).withValues(alpha: 0.74)
          ..strokeWidth = 1.2,
      );
    }
    canvas.drawLine(
      Offset(0, lyreTop),
      Offset(0, distance - 32),
      Paint()
        ..color = const Color(0xFFF0D287).withValues(alpha: 0.92)
        ..strokeWidth = 1.6,
    );

    final pivotCap = Rect.fromCenter(
      center: const Offset(0, 0),
      width: 18,
      height: 10,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pivotCap, const Radius.circular(999)),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFFFBE4B4), Color(0xFFAA7333)],
        ).createShader(pivotCap),
    );
    canvas.restore();

    canvas.drawCircle(
      pivot,
      5.2,
      Paint()..color = const Color(0xFFF6E0A4).withValues(alpha: 0.92),
    );
    canvas.drawCircle(
      bob.translate(0, -24),
      6 + pulse * 1.4,
      Paint()
        ..color = accentColor.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  void _drawPendulumColumn(Canvas canvas, {required Rect rect}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF704728),
            Color(0xFF4A2B1A),
            Color(0xFF7F5231),
          ],
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: rect.center,
          width: rect.width * 0.34,
          height: rect.height * 0.82,
        ),
        const Radius.circular(999),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.14),
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
      radius + 6,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[Color(0xFFFFEAB2), Color(0xFF8C5D22)],
        ).createShader(Rect.fromCircle(center: center, radius: radius + 6)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.12, -0.22),
          colors: <Color>[
            Color(0xFFF5E9C8),
            Color(0xFFD0B68A),
            Color(0xFFB99863),
          ],
          stops: <double>[0.0, 0.68, 1.0],
        ).createShader(outerRect),
    );
    canvas.drawCircle(
      center,
      radius * 0.18,
      Paint()..color = const Color(0xFF83551C).withValues(alpha: 0.84),
    );
    for (var i = 0; i < 12; i += 1) {
      final angle = -math.pi / 2 + i * math.pi / 6;
      final start = Offset(
        center.dx + math.cos(angle) * radius * 0.72,
        center.dy + math.sin(angle) * radius * 0.72,
      );
      final end = Offset(
        center.dx + math.cos(angle) * radius * 0.88,
        center.dy + math.sin(angle) * radius * 0.88,
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = const Color(0xFF6E4B20).withValues(alpha: 0.72)
          ..strokeWidth = i % 3 == 0 ? 2.1 : 1.1,
      );
    }
    canvas.drawLine(
      center,
      Offset(center.dx + radius * 0.14, center.dy - radius * 0.46),
      Paint()
        ..color = const Color(0xFF5C3C18)
        ..strokeWidth = 2.1
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      center,
      Offset(center.dx - radius * 0.34, center.dy + radius * 0.12),
      Paint()
        ..color = const Color(0xFF5C3C18)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintHypno(Canvas canvas, Size size, double pulse) {
    final center = size.center(Offset.zero);
    final baseRadius = size.shortestSide * 0.14;
    final phase = ambientProgress * math.pi * 2 * 1.35;
    for (var i = 0; i < 3; i += 1) {
      final swirlRadius = baseRadius + size.shortestSide * (0.14 + i * 0.08);
      final start = phase + i * 0.9;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: swirlRadius),
        start,
        math.pi * 1.2,
        false,
        Paint()
          ..color = _accentColor.withValues(alpha: 0.18 - i * 0.04)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4 - i * 0.8,
      );
    }
    for (var i = 0; i < 7; i += 1) {
      final ringT = i / 6;
      final radius =
          baseRadius +
          size.shortestSide * (0.07 * i) +
          pulse * 12 * (1 - ringT);
      final alpha = _mix(0.16, 0.62, 1 - ringT) * (0.72 + pulse * 0.28);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = _accentColor.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _mix(1.2, 3.6, 1 - ringT)
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(
      center,
      baseRadius * (1.05 + pulse * 0.55),
      Paint()..color = _accentColor.withValues(alpha: 0.92),
    );
  }

  void _paintDew(Canvas canvas, Size size, double pulse) {
    final centerX = size.width * 0.5;
    final fall = Curves.easeIn.transform(pulseProgress.clamp(0.0, 1.0));
    final dropY = _mix(size.height * 0.16, size.height * 0.67, fall);
    final rippleStart = size.height * 0.74;
    final impactProgress = ((fall - 0.78) / 0.22).clamp(0.0, 1.0);
    final squash = impactProgress * 0.18;
    final radius = 12 + pulse * 7;
    final dropRect = Rect.fromCenter(
      center: Offset(centerX, dropY),
      width: radius * 2.05 * (1 + squash * 0.35),
      height: radius * 2.05 * (1 - squash),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, rippleStart + 4),
        width: 52 + impactProgress * 50,
        height: 14 + impactProgress * 6,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12 + impactProgress * 0.08),
    );
    canvas.drawOval(
      dropRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.9),
            _accentColor.withValues(alpha: 0.4),
            _accentColor.withValues(alpha: 0.16),
          ],
          stops: const <double>[0.0, 0.36, 1.0],
        ).createShader(dropRect),
    );
    canvas.drawOval(
      dropRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.42),
    );
    canvas.drawCircle(
      Offset(centerX - radius * 0.4, dropY - radius * 0.52),
      radius * 0.2,
      Paint()..color = Colors.white.withValues(alpha: 0.72),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + radius * 0.18, dropY + radius * 0.16),
        width: radius * 1.05,
        height: radius * 0.5,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );

    for (var i = 0; i < 3; i += 1) {
      final wave = (impactProgress - i * 0.18).clamp(0.0, 1.0);
      if (wave <= 0) {
        continue;
      }
      final rippleRadius = 16 + wave * 76;
      final alpha = (1 - wave * 0.42).clamp(0.0, 1.0) * 0.38;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, rippleStart),
          width: rippleRadius * 2,
          height: rippleRadius * 0.42,
        ),
        Paint()
          ..color = _accentColor.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.9 - i * 0.3,
      );
    }
    if (impactProgress > 0) {
      final splashT = impactProgress;
      for (var i = 0; i < 5; i += 1) {
        final theta = (-0.6 + i * 0.3) * math.pi;
        final length = _mix(6, 18, splashT);
        final start = Offset(centerX, rippleStart - 2);
        final end = Offset(
          start.dx + math.cos(theta) * length,
          start.dy + math.sin(theta) * length,
        );
        canvas.drawLine(
          start,
          end,
          Paint()
            ..color = _accentColor.withValues(alpha: (1 - splashT) * 0.35)
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
        Curves.easeOutCubic.transform((1 - phase).clamp(0.0, 1.0)) * 0.08;
    final mainRotation =
        ambientProgress * math.pi * 2 * (running ? 0.42 : 0.08) +
        tickImpulse * swingDirection;
    final caseCenter = Offset(size.width * 0.5, size.height * 0.48);
    final caseRadius = size.shortestSide * 0.33;
    final caseRect = Rect.fromCircle(center: caseCenter, radius: caseRadius);

    canvas.drawCircle(
      caseCenter,
      caseRadius + 16,
      Paint()
        ..shader =
            const RadialGradient(
              colors: <Color>[Color(0xFF7D3A20), Color(0xFF3B1408)],
            ).createShader(
              Rect.fromCircle(center: caseCenter, radius: caseRadius + 16),
            ),
    );
    canvas.drawCircle(
      caseCenter,
      caseRadius + 8,
      Paint()
        ..shader =
            const RadialGradient(
              center: Alignment(-0.14, -0.28),
              colors: <Color>[
                Color(0xFFF7D78D),
                Color(0xFFB88A32),
                Color(0xFF5C3614),
              ],
            ).createShader(
              Rect.fromCircle(center: caseCenter, radius: caseRadius + 8),
            ),
    );
    canvas.drawCircle(
      caseCenter,
      caseRadius,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[Color(0xFF20150E), Color(0xFF0A0604)],
        ).createShader(caseRect),
    );

    _drawFocusGear(
      canvas,
      center: caseCenter.translate(-caseRadius * 0.22, caseRadius * 0.12),
      radius: caseRadius * 0.42 + pulse * 4,
      teeth: 20,
      rotation: mainRotation,
      color: const Color(0xFFDAB35C),
      pulse: pulse,
    );
    _drawFocusGear(
      canvas,
      center: caseCenter.translate(caseRadius * 0.24, -caseRadius * 0.18),
      radius: caseRadius * 0.18 + pulse * 2.2,
      teeth: 12,
      rotation: -mainRotation * 1.9,
      color: const Color(0xFFD0D7E0),
      pulse: pulse * 0.8,
    );
    _drawFocusGear(
      canvas,
      center: caseCenter.translate(-caseRadius * 0.34, -caseRadius * 0.28),
      radius: caseRadius * 0.15,
      teeth: 12,
      rotation: -mainRotation * 1.35,
      color: const Color(0xFFAEB9C7),
      pulse: pulse * 0.55,
    );
    _drawFocusGear(
      canvas,
      center: caseCenter.translate(caseRadius * 0.3, caseRadius * 0.28),
      radius: caseRadius * 0.12,
      teeth: 10,
      rotation: mainRotation * 2.2,
      color: const Color(0xFFB3BAC4),
      pulse: pulse * 0.5,
    );

    final balanceAngle = swingDirection * math.cos(math.pi * phase) * 0.54;
    _drawBalanceWheel(
      canvas,
      center: caseCenter,
      radius: caseRadius * 0.28,
      rotation: balanceAngle,
      pulse: pulse,
    );

    final bridgeColor = const Color(0xFFD8DEE8).withValues(alpha: 0.95);
    final bridgePaint = Paint()
      ..color = bridgeColor
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: caseCenter, radius: caseRadius * 0.33),
      math.pi * 1.02,
      math.pi * 0.95,
      false,
      bridgePaint,
    );
    canvas.drawLine(
      caseCenter.translate(-caseRadius * 0.02, 0),
      caseCenter.translate(caseRadius * 0.4, -caseRadius * 0.04),
      bridgePaint,
    );
    canvas.drawLine(
      caseCenter.translate(-caseRadius * 0.18, -caseRadius * 0.22),
      caseCenter.translate(caseRadius * 0.08, -caseRadius * 0.06),
      Paint()
        ..color = bridgeColor.withValues(alpha: 0.84)
        ..strokeWidth = 6.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      caseCenter,
      8,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[Color(0xFFFCE8AA), Color(0xFF9A6D25)],
        ).createShader(Rect.fromCircle(center: caseCenter, radius: 8)),
    );

    for (final screw in <Offset>[
      caseCenter.translate(-caseRadius * 0.55, -caseRadius * 0.52),
      caseCenter.translate(caseRadius * 0.57, -caseRadius * 0.48),
      caseCenter.translate(-caseRadius * 0.48, caseRadius * 0.58),
    ]) {
      _drawMovementScrew(canvas, center: screw, radius: 11);
    }
    for (final jewel in <Offset>[
      caseCenter.translate(-caseRadius * 0.23, -caseRadius * 0.1),
      caseCenter.translate(caseRadius * 0.08, 0),
      caseCenter.translate(caseRadius * 0.17, -caseRadius * 0.12),
    ]) {
      canvas.drawCircle(
        jewel,
        4.2,
        Paint()..color = const Color(0xFF8E4DA8).withValues(alpha: 0.88),
      );
    }
    canvas.drawCircle(
      caseCenter,
      caseRadius + 3 + pulse * 3,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = Colors.white.withValues(alpha: 0.18),
    );
  }

  void _paintSteps(Canvas canvas, Size size, double pulse) {
    final phase = pulseProgress.clamp(0.0, 1.0);
    final leftActive = activeBeat >= 0 ? activeBeat.isEven : true;
    final vanishing = Offset(size.width * 0.5, size.height * 0.18);
    final lanePath = Path()
      ..moveTo(size.width * 0.18, size.height * 0.92)
      ..lineTo(size.width * 0.82, size.height * 0.92)
      ..lineTo(size.width * 0.58, vanishing.dy)
      ..lineTo(size.width * 0.42, vanishing.dy)
      ..close();
    canvas.drawPath(
      lanePath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFF1B2D22).withValues(alpha: 0.18),
            const Color(0xFF203A2E).withValues(alpha: 0.48),
            const Color(0xFF0E1712).withValues(alpha: 0.82),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      lanePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = Colors.white.withValues(alpha: 0.12),
    );
    for (var i = 0; i < 5; i += 1) {
      final t = i / 4;
      final y = _mix(vanishing.dy + 18, size.height * 0.94, t);
      final halfWidth = _mix(10, size.width * 0.28, t);
      canvas.drawLine(
        Offset(size.width * 0.5 - halfWidth, y),
        Offset(size.width * 0.5 + halfWidth, y),
        Paint()..color = Colors.white.withValues(alpha: 0.05 + t * 0.08),
      );
    }
    for (var i = 0; i < 6; i += 1) {
      final t = ((ambientProgress * 1.15) + i * 0.17) % 1.0;
      final depth = Curves.easeIn.transform(t);
      final y = _mix(vanishing.dy + 8, size.height * 0.94, depth);
      final width = _mix(4, 15, depth);
      final height = _mix(12, 32, depth);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * 0.5, y),
            width: width,
            height: height,
          ),
          const Radius.circular(999),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.05 + depth * 0.12),
      );
    }

    final flow = (ambientProgress * 1.6 + phase * 0.12) % 1.0;
    for (var i = 0; i < 6; i += 1) {
      final t = ((flow + i * 0.16) % 1.0);
      final depth = Curves.easeIn.transform(t);
      final scale = _mix(0.3, 1.08, depth);
      final y = _mix(vanishing.dy + 20, size.height * 0.9, depth);
      final x = size.width * 0.5 + (i.isEven ? -1 : 1) * _mix(8, 42, depth);
      final opacity = _mix(0.08, 0.36, depth);
      _drawFootprint(
        canvas,
        center: Offset(x, y),
        active: false,
        pulse: pulse,
        color: Colors.white.withValues(alpha: opacity),
        scale: scale,
        rotation: (i.isEven ? -1.0 : 1.0) * _mix(0.04, 0.18, depth),
      );
    }

    final strideLift = math.sin(math.pi * phase).abs();
    final leadY = _mix(size.height * 0.84, size.height * 0.66, phase);
    final trailY = _mix(size.height * 0.7, size.height * 0.84, phase);
    _drawFootprint(
      canvas,
      center: Offset(
        size.width * 0.5 + (leftActive ? -24 : 24),
        leftActive ? leadY : trailY,
      ),
      active: leftActive,
      pulse: pulse + strideLift * 0.3,
      color: _accentColor,
      scale: leftActive ? 1.14 : 0.98,
      rotation: leftActive ? -0.14 : -0.04,
    );
    _drawFootprint(
      canvas,
      center: Offset(
        size.width * 0.5 + (leftActive ? 24 : -24),
        leftActive ? trailY : leadY,
      ),
      active: !leftActive,
      pulse: pulse + strideLift * 0.3,
      color: Colors.white.withValues(alpha: 0.9),
      scale: leftActive ? 0.98 : 1.14,
      rotation: leftActive ? 0.04 : 0.14,
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
  }) {
    final actualScale = active ? scale * (1.0 + pulse * 0.08) : scale;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final sole = Rect.fromCenter(
      center: Offset.zero,
      width: 32 * actualScale,
      height: 68 * actualScale,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, 16 * actualScale),
        width: sole.width * 0.74,
        height: sole.height * 0.24,
      ),
      Paint()..color = Colors.black.withValues(alpha: active ? 0.22 : 0.1),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sole, Radius.circular(18 * actualScale)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            color.withValues(alpha: active ? 0.95 : 0.55),
            color.withValues(alpha: active ? 0.72 : 0.3),
          ],
        ).createShader(sole),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sole, Radius.circular(18 * actualScale)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = Colors.white.withValues(alpha: active ? 0.24 : 0.08),
    );
    for (final toe in <Offset>[
      Offset(-8 * actualScale, -25 * actualScale),
      Offset(0, -29 * actualScale),
      Offset(8 * actualScale, -24 * actualScale),
    ]) {
      canvas.drawCircle(
        toe,
        4.8 * actualScale,
        Paint()..color = color.withValues(alpha: active ? 0.86 : 0.32),
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

void _drawFocusGear(
  Canvas canvas, {
  required Offset center,
  required double radius,
  required int teeth,
  required double rotation,
  required Color color,
  required double pulse,
}) {
  final innerRadius = radius * 0.78;
  final outerRadius = radius * 1.06;
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
        center: const Alignment(-0.2, -0.35),
        radius: 1.0,
        colors: <Color>[
          Colors.white.withValues(alpha: 0.95),
          color.withValues(alpha: 0.86),
          const Color(0xFF3A4350).withValues(alpha: 0.92),
        ],
        stops: const <double>[0.0, 0.32, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius)),
  );
  canvas.drawPath(
    gearPath,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Colors.white.withValues(alpha: 0.26),
  );
  canvas.drawCircle(
    center,
    radius * 0.56,
    Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFFF8FAFC).withValues(alpha: 0.92),
          const Color(0xFF6B7788).withValues(alpha: 0.92),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.56)),
  );
  canvas.drawCircle(
    center,
    radius * 0.18,
    Paint()..color = const Color(0xFF27303A).withValues(alpha: 0.92),
  );

  for (var i = 0; i < 4; i += 1) {
    final angle = rotation + i * math.pi / 2;
    final start = Offset(
      center.dx + math.cos(angle) * radius * 0.18,
      center.dy + math.sin(angle) * radius * 0.18,
    );
    final end = Offset(
      center.dx + math.cos(angle) * radius * 0.48,
      center.dy + math.sin(angle) * radius * 0.48,
    );
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.38)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  canvas.drawArc(
    Rect.fromCircle(center: center, radius: outerRadius + 3),
    rotation - 0.45,
    0.52 + pulse * 0.18,
    false,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
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
        center: Alignment(-0.16, -0.24),
        colors: <Color>[
          Color(0xFFF5F8FC),
          Color(0xFF8E99A6),
          Color(0xFF4C5564),
        ],
      ).createShader(ringRect),
  );
  canvas.drawCircle(
    Offset.zero,
    radius * 0.68,
    Paint()..color = const Color(0xFF151A21).withValues(alpha: 0.92),
  );
  for (var i = 0; i < 4; i += 1) {
    final angle = i * math.pi / 2;
    final end = Offset(
      math.cos(angle) * radius * 0.74,
      math.sin(angle) * radius * 0.74,
    );
    canvas.drawLine(
      Offset.zero,
      end,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.34)
        ..strokeWidth = 2.1
        ..strokeCap = StrokeCap.round,
    );
  }
  canvas.drawCircle(
    Offset.zero,
    radius * 0.16,
    Paint()
      ..shader =
          const RadialGradient(
            colors: <Color>[Color(0xFFFEE3A4), Color(0xFF9B6C24)],
          ).createShader(
            Rect.fromCircle(center: Offset.zero, radius: radius * 0.16),
          ),
  );
  canvas.restore();

  canvas.drawArc(
    Rect.fromCircle(
      center: center.translate(0, -radius * 0.08),
      radius: radius * 1.12,
    ),
    math.pi * 1.04,
    math.pi * 0.92,
    false,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 5.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke,
  );
  canvas.drawCircle(
    center,
    radius + 6 + pulse * 3,
    Paint()
      ..color = const Color(0xFF96D9FF).withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
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
    radius,
    Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.24, -0.24),
        colors: <Color>[
          Color(0xFFF0F4FA),
          Color(0xFF7A8798),
          Color(0xFF374150),
        ],
      ).createShader(rect),
  );
  canvas.drawLine(
    center.translate(-radius * 0.42, 0),
    center.translate(radius * 0.42, 0),
    Paint()
      ..color = const Color(0xFF1A1F27).withValues(alpha: 0.78)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round,
  );
  canvas.drawLine(
    center.translate(0, -radius * 0.42),
    center.translate(0, radius * 0.42),
    Paint()
      ..color = const Color(0xFF1A1F27).withValues(alpha: 0.26)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round,
  );
}

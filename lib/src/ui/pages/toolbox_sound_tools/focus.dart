part of '../toolbox_sound_tools.dart';

// ignore_for_file: dead_code, unused_element, unused_local_variable

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

class _FocusTickFrame {
  const _FocusTickFrame({
    required this.segmentLength,
    required this.layer,
    required this.nextLayer,
    required this.beat,
    required this.subPulse,
  });

  final int segmentLength;
  final int layer;
  final int nextLayer;
  final int beat;
  final int subPulse;
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
  static const List<int> _focusBeatVariants = <int>[0, 11, 23];
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
  Timer? _immersiveHudTimer;
  DateTime? _lastTapTempoAt;
  Map<int, ToolboxRealisticEffectPlayer> _players =
      <int, ToolboxRealisticEffectPlayer>{};

  int _bpm = 72;
  int _beatsPerBar = 4;
  int _subdivision = 1;
  int _activeBeat = -1;
  int _activeSubPulse = 0;
  bool _running = false;
  bool _patternEnabled = false;
  bool _hapticsEnabled = true;
  bool _immersiveMode = false;
  bool _immersiveHudVisible = true;
  bool _linkAnimationAndSound = true;
  bool _tempoExpanded = true;
  bool _meterExpanded = false;
  bool _styleExpanded = false;
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
  int _lastPrimedLayer = -1;
  int _lastPrimedTransportTick = -9999;

  static const int _timingCompensationUs = 1200;
  static const int _maxCatchUpTicks = 3;

  int get _barPulses => _beatsPerBar * _subdivision;

  int get _pulseIntervalUs =>
      math.max(1, (60000000 / (_bpm * _subdivision)).round());

  AppI18n _i18nOf(BuildContext context, {bool listen = true}) =>
      _toolboxI18n(context, listen: listen);

  List<int> get _effectiveSegmentPulses {
    if (_patternEnabled && _patternError.isEmpty) {
      return _segmentPulseCounts;
    }
    return <int>[_barPulses];
  }

  void _setViewState(VoidCallback fn) {
    if (!mounted) {
      return;
    }
    setState(fn);
  }

  String _text(
    BuildContext context, {
    required String zh,
    required String en,
    bool listen = true,
  }) {
    return pickUiText(
      _i18nOf(context, listen: listen),
      zh: zh,
      en: en,
    );
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
    _immersiveHudTimer?.cancel();
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
    final inlineI18n = _i18nOf(context);
    final inlineArrangementLabel = _patternError.isEmpty
        ? _pattern.raw
        : '1bar';
    final mobileBody = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildStudioSummaryStrip(context),
        const SizedBox(height: 16),
        _buildStageCompact(context),
        const SizedBox(height: 16),
        _buildPrimaryControls(context),
        const SizedBox(height: 16),
        _FocusControlSection(
          icon: Icons.speed_rounded,
          title: pickUiText(inlineI18n, zh: '节奏', en: 'Tempo'),
          subtitle: pickUiText(
            inlineI18n,
            zh: '调整 BPM 与常用速度',
            en: 'Adjust BPM and quick tempos',
          ),
          summary: '$_bpm BPM · ${(60 / _bpm).toStringAsFixed(2)} s/beat',
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
          title: pickUiText(inlineI18n, zh: '拍号与细分', en: 'Meter'),
          subtitle: pickUiText(
            inlineI18n,
            zh: '控制重拍结构和子拍密度',
            en: 'Control the pulse structure and subdivisions',
          ),
          summary: '$_beatsPerBar/4 × $_subdivision',
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
          title: pickUiText(inlineI18n, zh: '动画与音色', en: 'Style'),
          subtitle: pickUiText(
            inlineI18n,
            zh: '选择舞台动画和节拍音色',
            en: 'Choose the stage motion and click timbre',
          ),
          summary:
              '${_animationName(context, _animationKind)} · ${_soundName(context, _soundKind)}',
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
          title: pickUiText(inlineI18n, zh: '循环编排', en: 'Arrangement'),
          subtitle: pickUiText(
            inlineI18n,
            zh: '管理段落与循环模板',
            en: 'Manage phrases and loop templates',
          ),
          summary: _patternEnabled
              ? inlineArrangementLabel
              : pickUiText(inlineI18n, zh: '单小节循环', en: 'Single-bar loop'),
          expanded: _arrangementExpanded,
          onToggle: () {
            setState(() {
              _arrangementExpanded = !_arrangementExpanded;
            });
          },
          child: _buildArrangementSection(
            context,
            arrangementLabel: inlineArrangementLabel,
          ),
        ),
        const SizedBox(height: 12),
        _FocusControlSection(
          icon: Icons.graphic_eq_rounded,
          title: pickUiText(inlineI18n, zh: '混音与触感', en: 'Mix'),
          subtitle: pickUiText(
            inlineI18n,
            zh: '调节音量层级与震动反馈',
            en: 'Adjust volume layers and haptics',
          ),
          summary:
              '${(100 * _masterVolume).round()}% · ${_hapticsEnabled ? pickUiText(inlineI18n, zh: '触感开', en: 'Haptics on') : pickUiText(inlineI18n, zh: '触感关', en: 'Haptics off')}',
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
    if (widget.fullScreen) {
      return _buildImmersiveAnimationOnly(context);
    }
    return Card(
      child: Padding(padding: const EdgeInsets.all(18), child: mobileBody),
    );

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

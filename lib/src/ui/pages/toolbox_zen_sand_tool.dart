import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/toolbox_zen_sand_prefs_service.dart';
import '../../services/toolbox_zen_sand_sound_service.dart';

part 'toolbox_zen_sand_tool_config.dart';
part 'toolbox_zen_sand_tool_render.dart';
part 'toolbox_zen_sand_tool_state.dart';
part 'toolbox_zen_sand_tool_widgets.dart';

const List<_ZenBackgroundSpec> _backgrounds = <_ZenBackgroundSpec>[
  _ZenBackgroundSpec(
    id: 'sunlit_garden',
    labelZh: '暖金沙',
    labelEn: 'Warm Sand',
    descriptionZh: '细密金砂与平行底纹，适合慢慢梳理呼吸和注意力。',
    descriptionEn: 'Fine golden grains with calm parallel base lines.',
    startColor: Color(0xFFF9E6BE),
    endColor: Color(0xFFE6C98A),
    accent: Color(0xFFD6A958),
    grooveDark: Color(0xFFA07B42),
    grooveLight: Color(0xFFFFF7DD),
    patternKind: _ZenPatternKind.parallel,
    patternSeed: 11,
    lineSpacing: 18,
    waveAmplitude: 3.4,
  ),
  _ZenBackgroundSpec(
    id: 'tidal_shore',
    labelZh: '潮汐浅滩',
    labelEn: 'Tidal Shore',
    descriptionZh: '轻海雾与退潮纹路，更适合波纹和留白构图。',
    descriptionEn: 'Shoreline contours with sea-mist light and softer rhythm.',
    startColor: Color(0xFFF4E8D7),
    endColor: Color(0xFFD8D1C6),
    accent: Color(0xFF7DAFC2),
    grooveDark: Color(0xFF7B6A58),
    grooveLight: Color(0xFFF8FBFF),
    patternKind: _ZenPatternKind.tidal,
    patternSeed: 23,
    lineSpacing: 22,
    waveAmplitude: 6.0,
  ),
  _ZenBackgroundSpec(
    id: 'moon_ash',
    labelZh: '月灰石庭',
    labelEn: 'Moon Ash',
    descriptionZh: '冷灰砂面与环形静波，适合极简景石布局。',
    descriptionEn: 'Cool ash-grey sand with orbital ripples for stone layouts.',
    startColor: Color(0xFFE6E1DD),
    endColor: Color(0xFFBDB5AF),
    accent: Color(0xFF7C879D),
    grooveDark: Color(0xFF625B57),
    grooveLight: Color(0xFFFAFAFA),
    patternKind: _ZenPatternKind.orbital,
    patternSeed: 37,
    lineSpacing: 20,
    waveAmplitude: 4.0,
  ),
  _ZenBackgroundSpec(
    id: 'rose_clay',
    labelZh: '暮色陶砂',
    labelEn: 'Rose Clay',
    descriptionZh: '微暖陶土调，适合更柔和的指尖与抚平笔触。',
    descriptionEn: 'Warm clay tones for softer fingertip and smoothing trails.',
    startColor: Color(0xFFF2D7CA),
    endColor: Color(0xFFD2AC97),
    accent: Color(0xFFC97563),
    grooveDark: Color(0xFF8B6154),
    grooveLight: Color(0xFFFFF1EC),
    patternKind: _ZenPatternKind.contour,
    patternSeed: 41,
    lineSpacing: 19,
    waveAmplitude: 5.2,
  ),
];

const List<_ZenToolSpec> _tools = <_ZenToolSpec>[
  _ZenToolSpec(
    id: 'rake',
    icon: Icons.drag_handle_rounded,
    labelZh: '木耙',
    labelEn: 'Rake',
    helpZh: '拖动画出多齿沙纹，用来建立秩序感和节奏。',
    helpEn: 'Drag multi-prong grooves to build rhythm and order.',
    tint: Color(0xFFB98538),
  ),
  _ZenToolSpec(
    id: 'finger',
    icon: Icons.draw_rounded,
    labelZh: '指尖',
    labelEn: 'Fingertip',
    helpZh: '更宽更柔的单线笔触，像手指轻轻划过沙面。',
    helpEn: 'A wider single groove like tracing the tray by hand.',
    tint: Color(0xFFB45D4B),
  ),
  _ZenToolSpec(
    id: 'paint',
    icon: Icons.format_paint_rounded,
    labelZh: '涂料',
    labelEn: 'Pigment',
    helpZh: '用可调色颜料做涂抹和涂鸦，适合创作主题色层。',
    helpEn: 'Lay down colored pigment for doodles and themed accents.',
    tint: Color(0xFF4E6F52),
    supportsColor: true,
  ),
  _ZenToolSpec(
    id: 'water',
    icon: Icons.water_drop_rounded,
    labelZh: '水迹',
    labelEn: 'Water',
    helpZh: '半透明水痕会顺着路径铺开，适合做流动质感。',
    helpEn: 'Spread translucent water trails for a fluid texture.',
    tint: Color(0xFF4E8FA8),
    supportsColor: true,
  ),
  _ZenToolSpec(
    id: 'wave',
    icon: Icons.waves_rounded,
    labelZh: '波纹',
    labelEn: 'Ripple',
    helpZh: '生成起伏曲线，适合呼吸节奏与水波感。',
    helpEn: 'Paint rhythmic waves for breathing and water-like motion.',
    tint: Color(0xFF4E8FA8),
  ),
  _ZenToolSpec(
    id: 'shovel',
    icon: Icons.construction_rounded,
    labelZh: '沙铲',
    labelEn: 'Shovel',
    helpZh: '宽面推开沙层，在两侧留下起伏堆线。',
    helpEn: 'Push sand aside with a broad shovel and raised banks.',
    tint: Color(0xFF9D744B),
  ),
  _ZenToolSpec(
    id: 'gravel',
    icon: Icons.blur_on_rounded,
    labelZh: '沙砾',
    labelEn: 'Gravel',
    helpZh: '沿着笔迹堆出颗粒沙砾，适合铺路与点缀。',
    helpEn: 'Build granular gravel trails for paths and texture accents.',
    tint: Color(0xFF7B7468),
  ),
  _ZenToolSpec(
    id: 'smooth',
    icon: Icons.auto_fix_high_rounded,
    labelZh: '抚平',
    labelEn: 'Smooth',
    helpZh: '局部抚平已有痕迹，让沙面重新安静下来。',
    helpEn: 'Calm a local area and restore a quieter surface.',
    tint: Color(0xFF8C877B),
  ),
  _ZenToolSpec(
    id: 'stone',
    icon: Icons.circle_rounded,
    labelZh: '景石',
    labelEn: 'Stone',
    helpZh: '轻点安放景石，为画面建立重心和留白。',
    helpEn: 'Tap to place stones and set a visual anchor.',
    tint: Color(0xFF5F5C63),
    isPlacement: true,
  ),
];

const List<_ZenColorSpec> _paintPalette = <_ZenColorSpec>[
  _ZenColorSpec(value: 0xFF4E6F52, labelZh: '苔绿', labelEn: 'Moss'),
  _ZenColorSpec(value: 0xFF6D5D8C, labelZh: '暮紫', labelEn: 'Dusk'),
  _ZenColorSpec(value: 0xFF9B5A56, labelZh: '陶红', labelEn: 'Clay'),
  _ZenColorSpec(value: 0xFF3A7CA5, labelZh: '湖蓝', labelEn: 'Lake'),
  _ZenColorSpec(value: 0xFFC58A3A, labelZh: '暖金', labelEn: 'Amber'),
  _ZenColorSpec(value: 0xFF5C677D, labelZh: '雾蓝灰', labelEn: 'Slate'),
];

const List<_ZenRitualPresetSpec> _ritualPresets = <_ZenRitualPresetSpec>[
  _ZenRitualPresetSpec(
    id: 'breath_tides',
    icon: Icons.air_rounded,
    titleZh: '呼吸潮纹',
    titleEn: 'Breath Tides',
    descriptionZh: '从舒缓波纹起笔，适合睡前放松、慢速呼吸和单手描摹。',
    descriptionEn:
        'Start from soft tidal waves for bedtime unwinding and slow breathing.',
    backgroundId: 'tidal_shore',
    toolId: 'wave',
    brushSize: 32,
    accent: Color(0xFF6FA7BC),
  ),
  _ZenRitualPresetSpec(
    id: 'stone_balance',
    icon: Icons.filter_vintage_rounded,
    titleZh: '平衡石庭',
    titleEn: 'Balanced Stones',
    descriptionZh: '先摆重心石，再沿石旁留白，适合安静构图和减压。',
    descriptionEn:
        'Place anchor stones first, then leave calm space around them.',
    backgroundId: 'moon_ash',
    toolId: 'stone',
    brushSize: 42,
    accent: Color(0xFF7C879D),
  ),
  _ZenRitualPresetSpec(
    id: 'water_path',
    icon: Icons.water_drop_rounded,
    titleZh: '沁润溪路',
    titleEn: 'Water Path',
    descriptionZh: '先铺一条水痕小径，再补砂砾与石点，适合做流动层次。',
    descriptionEn:
        'Lay down a damp path first, then add gravel and stones for flow.',
    backgroundId: 'rose_clay',
    toolId: 'water',
    brushSize: 30,
    accent: Color(0xFF5E92A9),
    colorValue: 0xFF3A7CA5,
  ),
  _ZenRitualPresetSpec(
    id: 'focus_furrows',
    icon: Icons.center_focus_strong_rounded,
    titleZh: '专注耙纹',
    titleEn: 'Focus Furrows',
    descriptionZh: '用规律耙纹和中轴构图稳住视线，适合短时专注重置。',
    descriptionEn:
        'Use rhythmic rake furrows and a stable centerline for quick refocus.',
    backgroundId: 'sunlit_garden',
    toolId: 'rake',
    brushSize: 30,
    accent: Color(0xFFC89A4A),
  ),
];

class ZenSandStudioPage extends StatefulWidget {
  const ZenSandStudioPage({super.key});

  @override
  State<ZenSandStudioPage> createState() => _ZenSandStudioPageState();
}

class _ZenSandStudioPageState extends State<ZenSandStudioPage> {
  final _ZenSandCanvasStore _canvasStore = _ZenSandCanvasStore();
  List<ZenSandAction> get _actions => _canvasStore.actions;
  set _actions(List<ZenSandAction> value) => _canvasStore.actions = value;

  List<ZenSandAction> get _redoStack => _canvasStore.redoStack;
  set _redoStack(List<ZenSandAction> value) => _canvasStore.redoStack = value;

  List<Offset> get _workingStroke => _canvasStore.workingStroke;
  set _workingStroke(List<Offset> value) => _canvasStore.workingStroke = value;

  String get _backgroundId => _canvasStore.backgroundId;
  set _backgroundId(String value) => _canvasStore.backgroundId = value;

  String get _toolId => _canvasStore.toolId;
  set _toolId(String value) => _canvasStore.toolId = value;

  double get _brushSize => _canvasStore.brushSize;
  set _brushSize(double value) => _canvasStore.brushSize = value;

  int get _colorValue => _canvasStore.colorValue;
  set _colorValue(int value) => _canvasStore.colorValue = value;

  bool get _hapticsEnabled => _canvasStore.hapticsEnabled;
  set _hapticsEnabled(bool value) => _canvasStore.hapticsEnabled = value;

  bool get _guideEnabled => _canvasStore.guideEnabled;
  set _guideEnabled(bool value) => _canvasStore.guideEnabled = value;

  bool get _soundEnabled => _canvasStore.soundEnabled;
  set _soundEnabled(bool value) => _canvasStore.soundEnabled = value;

  bool get _drawFromContactPoint => _canvasStore.drawFromContactPoint;
  set _drawFromContactPoint(bool value) =>
      _canvasStore.drawFromContactPoint = value;

  double get _touchOffset => _canvasStore.touchOffset;
  set _touchOffset(double value) => _canvasStore.touchOffset = value;

  bool get _immersiveMode => _canvasStore.immersiveMode;
  set _immersiveMode(bool value) => _canvasStore.immersiveMode = value;

  double get _viewportScale => _canvasStore.viewportScale;
  set _viewportScale(double value) => _canvasStore.viewportScale = value;

  Offset get _viewportOffset => _canvasStore.viewportOffset;
  set _viewportOffset(Offset value) => _canvasStore.viewportOffset = value;

  _ZenGestureMode get _gestureMode => _canvasStore.gestureMode;
  set _gestureMode(_ZenGestureMode value) => _canvasStore.gestureMode = value;
  final _ZenSandInteractionStore _interactionStore = _ZenSandInteractionStore();
  final _ZenSandInteractionController _interactionController =
      _ZenSandInteractionController();

  Size? get _currentCanvasSize => _interactionStore.currentCanvasSize;
  set _currentCanvasSize(Size? value) => _interactionStore.currentCanvasSize = value;

  Offset? get _lastTouchContactPoint => _interactionStore.lastTouchContactPoint;
  set _lastTouchContactPoint(Offset? value) =>
      _interactionStore.lastTouchContactPoint = value;

  Offset? get _lastResolvedInputPoint => _interactionStore.lastResolvedInputPoint;
  set _lastResolvedInputPoint(Offset? value) =>
      _interactionStore.lastResolvedInputPoint = value;

  bool get _transformHintVisible => _interactionStore.transformHintVisible;

  final Set<_ZenDrawerSection> _expandedDrawerSections = <_ZenDrawerSection>{
    _ZenDrawerSection.tools,
  };
  final ToolboxZenSandSoundService _soundService = ToolboxZenSandSoundService();
  String? get _lastPresetId => _canvasStore.lastPresetId;
  set _lastPresetId(String? value) => _canvasStore.lastPresetId = value;

  bool get _isZh => Localizations.localeOf(
    context,
  ).languageCode.toLowerCase().startsWith('zh');

  String _text(String zh, String en) => _isZh ? zh : en;

  _ZenBackgroundSpec get _background =>
      _backgroundById[_backgroundId] ?? _backgrounds.first;

  _ZenToolSpec get _tool => _toolById[_toolId] ?? _tools.first;

  _ZenColorSpec get _activeColorSpec =>
      _colorByValue[_colorValue] ?? _paintPalette.first;

  _ZenRitualPresetSpec? get _lastPreset =>
      _lastPresetId == null ? null : _ritualById[_lastPresetId];

  int get _strokeCount => _actions.where((action) => action.isStroke).length;

  int get _stoneCount => _actions.where((action) => action.isStone).length;

  @override
  void initState() {
    super.initState();
    _restorePrefs();
  }

  @override
  void dispose() {
    _interactionController.dispose();
    unawaited(_soundService.stopLoop(immediate: true));
    if (_immersiveMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    unawaited(_soundService.dispose());
    super.dispose();
  }

  Future<void> _restorePrefs() async {
    final prefs = await ToolboxZenSandPrefsService.load();
    if (!mounted) return;
    setState(() {
      _canvasStore.restoreFromPrefs(prefs, maxActions: _maxCanvasActions);
    });
  }

  void _persist() {
    unawaited(
      ToolboxZenSandPrefsService.save(
        _canvasStore.toPrefsState(maxActions: _maxCanvasActions),
      ),
    );
  }

  void _tapHaptic() {
    if (_hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void _impactHaptic() {
    if (_hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  ZenSandSoundKind? get _activeSoundKind => _soundKindForToolId(_toolId);

  String get _soundDescriptor {
    if (!_soundEnabled) {
      return _text('静音', 'Muted');
    }
    return switch (_toolId) {
      'rake' => _text('梭梭沙纹', 'Rake hush'),
      'finger' => _text('指尖沙沙', 'Finger brush'),
      'paint' => _text('涂抹摩挲', 'Pigment sweep'),
      'water' => _text('沁润水痕', 'Water bloom'),
      'wave' => _text('起伏细浪', 'Ripple flow'),
      'shovel' => _text('推砂划擦', 'Shovel scrape'),
      'gravel' => _text('砂砾颗粒', 'Pebble grain'),
      'smooth' => _text('抚平刷刷', 'Soft smoothing'),
      'stone' => _text('石落轻扣', 'Stone drop'),
      _ => _text('环境轻声', 'Ambient touch'),
    };
  }

  String get _anchorLabel =>
      _drawFromContactPoint ? _text('贴点', 'Contact') : _text('抬笔', 'Lifted');

  ZenSandSoundKind? _soundKindForToolId(String toolId) {
    return switch (toolId) {
      'rake' => ZenSandSoundKind.rake,
      'finger' || 'paint' || 'wave' => ZenSandSoundKind.finger,
      'water' => ZenSandSoundKind.water,
      'shovel' => ZenSandSoundKind.shovel,
      'gravel' => ZenSandSoundKind.gravel,
      'smooth' => ZenSandSoundKind.smooth,
      'stone' => ZenSandSoundKind.stone,
      _ => null,
    };
  }

  void _startSandLoop({double intensity = 0.82}) {
    if (!_soundEnabled) {
      return;
    }
    final kind = _activeSoundKind;
    if (kind == null || kind == ZenSandSoundKind.stone) {
      return;
    }
    unawaited(
      _soundService.startLoop(
        kind,
        brushSize: _brushSize,
        intensity: intensity.clamp(0.0, 1.0).toDouble(),
      ),
    );
  }

  void _updateSandLoop({double gestureDistance = 0.0}) {
    if (!_soundEnabled) {
      return;
    }
    final kind = _activeSoundKind;
    if (kind == null || kind == ZenSandSoundKind.stone) {
      return;
    }
    final normalizedDistance = (gestureDistance / math.max(10.0, _brushSize))
        .clamp(0.0, 1.0)
        .toDouble();
    final intensity = (0.48 + normalizedDistance * 0.42)
        .clamp(0.18, 1.0)
        .toDouble();
    unawaited(
      _soundService.updateLoop(
        kind,
        brushSize: _brushSize,
        intensity: intensity,
      ),
    );
  }

  void _stopSandLoop({bool immediate = false}) {
    unawaited(_soundService.stopLoop(immediate: immediate));
  }

  void _resetStrokeAudioSync() {
    _interactionStore.resetStrokeAudioSync();
  }

  double _accentStrideFor(ZenSandSoundKind kind) {
    final brushFactor = ((_brushSize - 14.0) / 82.0).clamp(0.0, 1.0);
    final base = switch (kind) {
      ZenSandSoundKind.rake => 14.0,
      ZenSandSoundKind.finger => 18.0,
      ZenSandSoundKind.water => 22.0,
      ZenSandSoundKind.shovel => 16.0,
      ZenSandSoundKind.gravel => 12.0,
      ZenSandSoundKind.smooth => 20.0,
      ZenSandSoundKind.stone => 999.0,
    };
    return base + brushFactor * 8.0;
  }

  Duration _accentGapFor(ZenSandSoundKind kind) {
    return switch (kind) {
      ZenSandSoundKind.rake => const Duration(milliseconds: 80),
      ZenSandSoundKind.finger => const Duration(milliseconds: 95),
      ZenSandSoundKind.water => const Duration(milliseconds: 130),
      ZenSandSoundKind.shovel => const Duration(milliseconds: 90),
      ZenSandSoundKind.gravel => const Duration(milliseconds: 72),
      ZenSandSoundKind.smooth => const Duration(milliseconds: 120),
      ZenSandSoundKind.stone => const Duration(milliseconds: 120),
    };
  }

  void _playSandAccent({
    double gestureDistance = 0.0,
    double intensityBias = 0.0,
    bool force = false,
  }) {
    if (!_soundEnabled) {
      return;
    }
    final kind = _activeSoundKind;
    if (kind == null || kind == ZenSandSoundKind.stone) {
      return;
    }
    final now = DateTime.now();
    final shouldPlay = _interactionStore.shouldPlayAccent(
      gestureDistance: gestureDistance,
      accentStride: _accentStrideFor(kind),
      accentGap: _accentGapFor(kind),
      force: force,
      now: now,
    );
    if (!shouldPlay) {
      return;
    }
    final normalizedDistance = (gestureDistance / math.max(10.0, _brushSize))
        .clamp(0.0, 1.0)
        .toDouble();
    final intensity = (0.34 + normalizedDistance * 0.34 + intensityBias)
        .clamp(0.22, 0.92)
        .toDouble();
    _soundService.tap(kind, brushSize: _brushSize, intensity: intensity);
  }

  bool get _toolSupportsColor => _tool.supportsColor;

  Offset _clampViewportOffset(Offset offset, Size size, double scale) {
    final minDx = size.width - size.width * scale;
    final minDy = size.height - size.height * scale;
    return Offset(
      offset.dx.clamp(minDx, 0.0).toDouble(),
      offset.dy.clamp(minDy, 0.0).toDouble(),
    );
  }

  void _setImmersiveMode(bool value) {
    if (_immersiveMode == value) return;
    if (value) {
      _impactHaptic();
    }
    setState(() {
      _immersiveMode = value;
    });
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        value ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      ),
    );
  }

  void _toggleImmersiveMode() {
    _setImmersiveMode(!_immersiveMode);
  }

  void _setColorValue(int value) {
    if (_colorValue == value) return;
    setState(() {
      _colorValue = value;
    });
    _persist();
  }

  void _resetViewport({bool withHaptic = true}) {
    if (_viewportScale == 1 && _viewportOffset == Offset.zero) return;
    if (withHaptic) {
      _tapHaptic();
    }
    setState(() {
      _canvasStore.resetViewport();
    });
  }

  void _appendAction(ZenSandAction action) {
    setState(() {
      _canvasStore.appendAction(action, maxActions: _maxCanvasActions);
      _gestureMode = _ZenGestureMode.idle;
      _workingStroke = <Offset>[];
    });
    _persist();
  }

  void _selectTool(String id) {
    if (_toolId == id) return;
    _tapHaptic();
    _stopWaterHoldPainter();
    _stopSandLoop(immediate: true);
    _resetStrokeAudioSync();
    setState(() {
      _toolId = id;
      _workingStroke = <Offset>[];
      _gestureMode = _ZenGestureMode.idle;
    });
    _persist();
  }

  void _selectBackground(String id) {
    if (_backgroundId == id) return;
    _impactHaptic();
    setState(() {
      _backgroundId = id;
    });
    _persist();
  }

  void _setBrushSize(double value) {
    setState(() {
      _canvasStore.setBrushSize(value);
    });
  }

  void _toggleHaptics(bool value) {
    setState(() {
      _hapticsEnabled = value;
    });
    _persist();
  }

  void _toggleGuidance(bool value) {
    setState(() {
      _guideEnabled = value;
    });
    _persist();
  }

  void _toggleSound(bool value) {
    setState(() {
      _soundEnabled = value;
    });
    if (!value) {
      _stopWaterHoldPainter();
      _stopSandLoop(immediate: true);
      _resetStrokeAudioSync();
    }
    _persist();
  }

  void _setDrawFromContactPoint(bool value) {
    if (_drawFromContactPoint == value) {
      return;
    }
    setState(() {
      _drawFromContactPoint = value;
    });
    _persist();
  }

  void _setTouchOffset(double value) {
    setState(() {
      _touchOffset = value.clamp(0.0, 1.0);
    });
    _persist();
  }

  void _toggleDrawerSection(_ZenDrawerSection section) {
    setState(() {
      if (_expandedDrawerSections.contains(section)) {
        _expandedDrawerSections.remove(section);
      } else {
        _expandedDrawerSections
          ..clear()
          ..add(section);
      }
    });
  }

  Offset _resolveInputPoint(Offset local, Size size) {
    final clampedLocal = Offset(
      local.dx.clamp(0.0, size.width).toDouble(),
      local.dy.clamp(0.0, size.height).toDouble(),
    );
    if (_drawFromContactPoint) {
      return clampedLocal;
    }
    final brushFactor = ((_brushSize - 14.0) / 82.0).clamp(0.0, 1.0);
    final normalizedLocal = Offset(
      clampedLocal.dx / math.max(size.width, 1),
      clampedLocal.dy / math.max(size.height, 1),
    );
    final liftY = (0.018 + _touchOffset * 0.085) * (0.72 + brushFactor * 0.28);
    var adjusted = normalizedLocal.translate(0, -liftY);
    final previous = _lastTouchContactPoint;
    if (previous != null) {
      final delta = Offset(
        (clampedLocal.dx - previous.dx) / math.max(size.width, 1),
        (clampedLocal.dy - previous.dy) / math.max(size.height, 1),
      );
      final distance = delta.distance;
      if (distance > 0.001) {
        final tangent = Offset(delta.dx / distance, delta.dy / distance);
        adjusted += tangent * math.min(liftY * 0.36, distance * 0.52);
      }
    }
    return Offset(
      adjusted.dx.clamp(0.0, 1.0).toDouble() * size.width,
      adjusted.dy.clamp(0.0, 1.0).toDouble() * size.height,
    );
  }

  void _startWaterHoldPainter() {
    _stopWaterHoldPainter();
    if (_toolId != 'water') {
      return;
    }
    _interactionStore.beginWaterHoldCycle();
    _interactionController.startWaterHoldFlow(
      period: const Duration(milliseconds: 55),
      shouldContinue: _canDriveWaterHoldTick,
      onTick: _applyWaterHoldTick,
      onStop: _stopWaterHoldPainter,
    );
  }

  void _stopWaterHoldPainter() {
    _interactionController.cancelWaterHoldTimer();
  }

  bool _canDriveWaterHoldTick() {
    return _interactionStore.canDriveWaterHold(
      mounted: mounted,
      gestureMode: _gestureMode,
      toolId: _toolId,
      workingStroke: _workingStroke,
      lastResolvedInputPoint: _lastResolvedInputPoint,
      canvasSize: _currentCanvasSize,
    );
  }

  void _applyWaterHoldTick() {
    final canvasSize = _currentCanvasSize;
    final lastResolvedInputPoint = _lastResolvedInputPoint;
    if (canvasSize == null || lastResolvedInputPoint == null) {
      return;
    }
    final point = _normalize(lastResolvedInputPoint, canvasSize);
    setState(() {
      _workingStroke = <Offset>[..._workingStroke, point];
    });
    _updateSandLoop(gestureDistance: _brushSize * 0.18);
    final holdTicks = _interactionStore.incrementWaterHoldTicks();
    if (holdTicks % 4 == 0) {
      _playSandAccent(
        gestureDistance: _brushSize * 0.32,
        intensityBias: 0.08,
      );
    }
  }

  Offset _normalize(Offset local, Size size) {
    final world = (local - _viewportOffset) / _viewportScale;
    return Offset(
      (world.dx / size.width).clamp(0.0, 1.0),
      (world.dy / size.height).clamp(0.0, 1.0),
    );
  }

  void _handlePanStart(Offset local, Size size) {
    if (_tool.isPlacement) return;
    final resolvedLocal = _resolveInputPoint(local, size);
    _currentCanvasSize = size;
    _lastTouchContactPoint = local;
    _lastResolvedInputPoint = resolvedLocal;
    _resetStrokeAudioSync();
    setState(() {
      _gestureMode = _ZenGestureMode.draw;
      _workingStroke = <Offset>[_normalize(resolvedLocal, size)];
    });
    _startSandLoop(intensity: 0.86);
    _playSandAccent(
      gestureDistance: _brushSize * 0.32,
      intensityBias: 0.06,
      force: true,
    );
    _startWaterHoldPainter();
  }

  void _handlePanUpdate(Offset local, Size size) {
    if (_tool.isPlacement || _workingStroke.isEmpty) return;
    final previousTouchPoint = _lastTouchContactPoint;
    final resolvedLocal = _resolveInputPoint(local, size);
    _currentCanvasSize = size;
    final point = _normalize(resolvedLocal, size);
    final minDistance =
        (_brushSize / math.max(size.width, size.height)).clamp(0.004, 0.04) *
        0.24;
    if ((_workingStroke.last - point).distance < minDistance) {
      _lastTouchContactPoint = local;
      _lastResolvedInputPoint = resolvedLocal;
      _updateSandLoop(
        gestureDistance: previousTouchPoint == null
            ? 0.0
            : (local - previousTouchPoint).distance,
      );
      return;
    }
    _lastTouchContactPoint = local;
    _lastResolvedInputPoint = resolvedLocal;
    setState(() {
      _workingStroke = <Offset>[..._workingStroke, point];
    });
    _updateSandLoop(
      gestureDistance: previousTouchPoint == null
          ? 0.0
          : (local - previousTouchPoint).distance,
    );
    _playSandAccent(
      gestureDistance: previousTouchPoint == null
          ? 0.0
          : (local - previousTouchPoint).distance,
    );
  }

  void _handlePanEnd() {
    if (_tool.isPlacement) return;
    if (_workingStroke.length < 2) {
      setState(() {
        _gestureMode = _ZenGestureMode.idle;
        _workingStroke = <Offset>[];
      });
      _stopWaterHoldPainter();
      _stopSandLoop();
      _resetStrokeAudioSync();
      _interactionStore.clearTouchPoints();
      return;
    }
    _tapHaptic();
    _appendAction(
      ZenSandAction.stroke(
        toolId: _toolId,
        size: _brushSize,
        colorValue: _toolSupportsColor ? _colorValue : null,
        points: _workingStroke
            .map((point) => ZenSandPoint(point.dx, point.dy))
            .toList(growable: false),
      ),
    );
    _gestureMode = _ZenGestureMode.idle;
    _stopWaterHoldPainter();
    _stopSandLoop();
    _resetStrokeAudioSync();
    _interactionStore.clearTouchPoints();
  }

  void _handlePanCancel() {
    if (_workingStroke.isNotEmpty) {
      setState(() {
        _gestureMode = _ZenGestureMode.idle;
        _workingStroke = <Offset>[];
      });
    } else {
      _gestureMode = _ZenGestureMode.idle;
    }
    _stopWaterHoldPainter();
    _stopSandLoop(immediate: true);
    _resetStrokeAudioSync();
    _interactionStore.clearTouchPoints();
  }

  void _setTransformHintVisible(bool value) {
    if (!mounted) {
      return;
    }
    final didChange = _interactionStore.updateTransformHintVisible(value);
    if (!didChange) {
      return;
    }
    setState(() {});
  }

  void _cancelPendingTransformIntent({bool hideHint = true}) {
    _interactionController.cancelTransformIntent();
    if (hideHint) {
      _setTransformHintVisible(false);
    }
  }

  void _armTransformIntent() {
    _setTransformHintVisible(true);
    _interactionController.scheduleTransformIntent(
      delay: const Duration(milliseconds: 260),
      shouldFire: () => _interactionStore.canFireTransformIntent(mounted: mounted),
      onFire: () {
        if (_gestureMode == _ZenGestureMode.draw) {
          _handlePanCancel();
        }
      },
      onCancel: _cancelPendingTransformIntent,
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    _interactionStore.addActivePointer(event.pointer);
    if (_interactionStore.hasTransformPointers &&
        _gestureMode == _ZenGestureMode.draw) {
      _armTransformIntent();
    }
    if (_interactionStore.hasTransformPointers) {
      _stopWaterHoldPainter();
      _stopSandLoop(immediate: true);
      _resetStrokeAudioSync();
      _interactionStore.clearTouchPoints();
    }
  }

  void _handlePointerUp(PointerEvent event) {
    _interactionStore.removeActivePointer(event.pointer);
    if (_interactionStore.hasLessThanTransformPointers) {
      _cancelPendingTransformIntent();
    }
    if (_interactionStore.hasNoPointers) {
      _interactionStore.clearTouchPoints();
    }
  }

  void _startTransform(Offset focalPoint, Size size) {
    _cancelPendingTransformIntent();
    _stopWaterHoldPainter();
    _stopSandLoop(immediate: true);
    _resetStrokeAudioSync();
    _canvasStore.startTransform(focalPoint: focalPoint, size: size);
  }

  void _updateTransform(Offset focalPoint, double scale, Size size) {
    final didUpdate = _canvasStore.updateTransform(
      focalPoint: focalPoint,
      scale: scale,
      size: size,
      clampViewportOffset: _clampViewportOffset,
    );
    if (!didUpdate) {
      return;
    }
    setState(() {});
  }

  void _handleScaleStart(ScaleStartDetails details, Size size) {
    _currentCanvasSize = size;
    if (_interactionStore.hasTransformPointers) {
      _cancelPendingTransformIntent();
      _interactionStore.clearTouchPoints();
      _startTransform(details.localFocalPoint, size);
      return;
    }
    if (_tool.isPlacement) {
      _interactionStore.clearTouchPoints();
      _gestureMode = _ZenGestureMode.idle;
      return;
    }
    _handlePanStart(details.localFocalPoint, size);
  }

  void _handleScaleUpdate(ScaleUpdateDetails details, Size size) {
    final isTransforming =
        _interactionStore.hasTransformPointers ||
        details.scale != 1 ||
        _gestureMode == _ZenGestureMode.transform;
    if (isTransforming) {
      _cancelPendingTransformIntent();
      if (_gestureMode != _ZenGestureMode.transform) {
        _handlePanCancel();
        _startTransform(details.localFocalPoint, size);
      }
      _updateTransform(details.localFocalPoint, details.scale, size);
      return;
    }
    if (_tool.isPlacement) return;
    if (_gestureMode != _ZenGestureMode.draw) {
      _handlePanStart(details.localFocalPoint, size);
      return;
    }
    _handlePanUpdate(details.localFocalPoint, size);
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _cancelPendingTransformIntent();
    if (_gestureMode == _ZenGestureMode.draw) {
      _handlePanEnd();
      return;
    }
    _gestureMode = _ZenGestureMode.idle;
    _stopWaterHoldPainter();
    _stopSandLoop(immediate: true);
    _resetStrokeAudioSync();
    _interactionStore.clearTouchPoints();
  }

  void _placeStone(Offset local, Size size) {
    if (!_tool.isPlacement) return;
    final point = _normalize(_resolveInputPoint(local, size), size);
    final seed = _actions.length + _background.patternSeed;
    _impactHaptic();
    _appendAction(
      ZenSandAction.stone(
        x: point.dx,
        y: point.dy,
        size: _brushSize,
        rotation: math.sin(seed * 0.78) * 0.5,
        variant: seed % 8,
      ),
    );
    if (_soundEnabled) {
      _soundService.tap(
        ZenSandSoundKind.stone,
        brushSize: _brushSize,
        intensity: 0.88,
      );
    }
  }

  void _undo() {
    final didUndo = _canvasStore.undo();
    if (!didUndo) return;
    _tapHaptic();
    setState(() {});
    _persist();
  }

  void _redo() {
    final didRedo = _canvasStore.redo(maxActions: _maxCanvasActions);
    if (!didRedo) return;
    _tapHaptic();
    setState(() {});
    _persist();
  }

  void _smoothAll() {
    final didSmooth = _canvasStore.keepOnlyStones();
    if (!didSmooth) return;
    _impactHaptic();
    setState(() {});
    if (_soundEnabled) {
      _soundService.tap(
        ZenSandSoundKind.smooth,
        brushSize: _brushSize,
        intensity: 0.7,
      );
    }
    _persist();
  }

  Future<void> _clearAll() async {
    if (_actions.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_text('清空当前沙盘？', 'Clear this tray?')),
          content: Text(
            _text(
              '这会移除所有笔触和景石，但会保留当前场景和工具设置。',
              'This removes all strokes and stones but keeps the current scene and tool setup.',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(_text('取消', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(_text('清空', 'Clear')),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    final didClear = _canvasStore.clearAllActions();
    if (!didClear) return;
    _impactHaptic();
    setState(() {});
    if (_soundEnabled) {
      _soundService.tap(
        ZenSandSoundKind.smooth,
        brushSize: _brushSize,
        intensity: 0.62,
      );
    }
    _persist();
  }

  void _showFloatingMessage(String message) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _applyRitualPreset(
    _ZenRitualPresetSpec preset, {
    required bool replace,
  }) {
    final presetActions = _buildZenRitualActions(preset.id);

    _impactHaptic();
    _resetStrokeAudioSync();
    setState(() {
      _canvasStore.applyRitualPreset(
        preset: preset,
        presetActions: presetActions,
        replace: replace,
        maxActions: _maxCanvasActions,
      );
    });
    if (_soundEnabled) {
      final impactKind = replace
          ? ZenSandSoundKind.smooth
          : (_soundKindForToolId(preset.toolId) ?? ZenSandSoundKind.rake);
      _soundService.tap(
        impactKind,
        brushSize: preset.brushSize,
        intensity: replace ? 0.54 : 0.74,
      );
    }
    _persist();
    _showFloatingMessage(
      replace
          ? _text('已套用“${preset.titleZh}”预设。', 'Applied "${preset.titleEn}".')
          : _text(
              '已将“${preset.titleZh}”叠加到当前沙盘。',
              'Layered "${preset.titleEn}" onto the current tray.',
            ),
    );
  }

  Future<void> _useRitualPreset(_ZenRitualPresetSpec preset) async {
    var mode = _ZenRitualApplyMode.replace;
    if (_actions.isNotEmpty) {
      final selected = await showDialog<_ZenRitualApplyMode>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              _text('将预设用于当前沙盘？', 'Use this preset on the current tray?'),
            ),
            content: Text(
              _text(
                '可以直接替换当前沙盘，也可以把预设作为新一层叠加到现有构图上。',
                'You can replace the current tray or layer the preset on top of the existing composition.',
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(_text('取消', 'Cancel')),
              ),
              FilledButton.tonal(
                onPressed: () =>
                    Navigator.of(context).pop(_ZenRitualApplyMode.append),
                child: Text(_text('叠加', 'Layer it')),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop(_ZenRitualApplyMode.replace),
                child: Text(_text('替换当前沙盘', 'Replace tray')),
              ),
            ],
          );
        },
      );
      if (selected == null || !mounted) {
        return;
      }
      mode = selected;
    }
    _applyRitualPreset(preset, replace: mode == _ZenRitualApplyMode.replace);
  }

  Future<void> _openRitualSheet() async {
    final preset = await showModalBottomSheet<_ZenRitualPresetSpec>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, _) {
            final screenWidth = MediaQuery.sizeOf(context).width;
            final cardWidth =
                (screenWidth - 16 * 2 - 12).clamp(160.0, 420.0) / 2;
            return _ZenSheetFrame(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _ZenSheetHeader(
                    title: _text('起手预设', 'Quick rituals'),
                    subtitle: _text(
                      '先用一个构图预设起笔，再继续手工修整，移动端会更容易进入状态。',
                      'Start from a guided composition, then keep shaping it by hand on mobile.',
                    ),
                  ),
                  const SizedBox(height: 18),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _ritualPresets
                            .map((preset) {
                              return SizedBox(
                                width: cardWidth,
                                child: _ZenRitualCard(
                                  preset: preset,
                                  isZh: _isZh,
                                  selected: preset.id == _lastPresetId,
                                  onTap: () =>
                                      Navigator.of(context).pop(preset),
                                ),
                              );
                            })
                            .toList(growable: false),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (preset == null || !mounted) {
      return;
    }
    await _useRitualPreset(preset);
  }

  Future<void> _openSceneSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final screenWidth = MediaQuery.sizeOf(context).width;
            final cardWidth =
                (screenWidth - 16 * 2 - 12).clamp(160.0, 420.0) / 2;
            return _ZenSheetFrame(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _ZenSheetHeader(
                    title: _text('场景背景', 'Scenes'),
                    subtitle: _text(
                      '不同底纹会改变沙面的情绪和层次。',
                      'Different base patterns change the tray mood and visual rhythm.',
                    ),
                  ),
                  const SizedBox(height: 18),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _backgrounds
                            .map((background) {
                              return SizedBox(
                                width: cardWidth,
                                child: _ZenBackgroundCard(
                                  background: background,
                                  isZh: _isZh,
                                  selected: background.id == _backgroundId,
                                  onTap: () {
                                    _selectBackground(background.id);
                                    setSheetState(() {});
                                  },
                                ),
                              );
                            })
                            .toList(growable: false),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openControlSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void refresh(VoidCallback callback) {
              callback();
              setSheetState(() {});
            }

            return _ZenSheetFrame(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _ZenSheetHeader(
                      title: _text('工具与控制', 'Tools & controls'),
                      subtitle: _text(
                        '调整笔触宽度、切换工具，并管理触感反馈。',
                        'Adjust stroke width, switch tools, and manage tactile feedback.',
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ZenSectionCard(
                      title: _text('绘画工具', 'Drawing tools'),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _tools
                            .map((tool) {
                              return _ZenToolCard(
                                tool: tool,
                                isZh: _isZh,
                                selected: tool.id == _toolId,
                                onTap: () =>
                                    refresh(() => _selectTool(tool.id)),
                              );
                            })
                            .toList(growable: false),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ZenSectionCard(
                      title: _text('笔触宽度', 'Brush width'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _ZenToolPreview(
                                  background: _background,
                                  tool: _tool,
                                  brushSize: _brushSize,
                                  colorValue: _toolSupportsColor
                                      ? _colorValue
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 14),
                              _ZenActionBadge(
                                label: _text('尺寸', 'Size'),
                                value: _brushSize.round().toString(),
                                accent: _tool.tint,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Slider(
                            value: _brushSize,
                            min: 14,
                            max: 96,
                            divisions: 41,
                            activeColor: _tool.tint,
                            onChanged: (value) {
                              refresh(() => _setBrushSize(value));
                            },
                            onChangeEnd: (_) => _persist(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_toolSupportsColor) ...<Widget>[
                      const SizedBox(height: 14),
                      _ZenSectionCard(
                        title: _text('颜色盘', 'Color palette'),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _paintPalette
                              .map((color) {
                                return _ZenColorChip(
                                  color: color.color,
                                  label: color.label(_isZh),
                                  selected: color.value == _colorValue,
                                  onTap: () => refresh(
                                    () => _setColorValue(color.value),
                                  ),
                                );
                              })
                              .toList(growable: false),
                        ),
                      ),
                    ],
                    _ZenSectionCard(
                      title: _text('体验设置', 'Experience'),
                      child: Column(
                        children: <Widget>[
                          _ZenToggleRow(
                            title: _text('触感反馈', 'Haptics'),
                            subtitle: _text(
                              '切换工具、落石和撤销时给出轻微振动。',
                              'Adds light feedback when switching tools, placing stones, and undoing.',
                            ),
                            value: _hapticsEnabled,
                            activeColor: _background.accent,
                            onChanged: (value) =>
                                refresh(() => _toggleHaptics(value)),
                          ),
                          const Divider(height: 18),
                          _ZenToggleRow(
                            title: _text('操作提示', 'Guidance'),
                            subtitle: _text(
                              '在画布上显示当前工具的手势说明。',
                              'Shows contextual hints for the active tool.',
                            ),
                            value: _guideEnabled,
                            activeColor: _background.accent,
                            onChanged: (value) =>
                                refresh(() => _toggleGuidance(value)),
                          ),
                          const Divider(height: 18),
                          _ZenToggleRow(
                            title: _text('沙盘音效', 'Sand sounds'),
                            subtitle: _text(
                              '给木耙、水迹、沙铲和景石加入轻柔摩擦声，连续拖动时会自动节流。',
                              'Adds gentle rake, water, shovel, and stone textures with throttled playback during drags.',
                            ),
                            value: _soundEnabled,
                            activeColor: _background.accent,
                            onChanged: (value) =>
                                refresh(() => _toggleSound(value)),
                          ),
                          const Divider(height: 18),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _text('触点锚定', 'Touch anchor'),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _text(
                              '可以直接从接触点落笔，或把笔尖上移一段距离，减少手指遮挡。',
                              'Draw directly from the contact point or lift the tip upward so your finger covers less of the mark.',
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: const Color(0xFF655949),
                                  height: 1.4,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              ChoiceChip(
                                label: Text(_text('贴合触点', 'Contact point')),
                                selected: _drawFromContactPoint,
                                onSelected: (_) => refresh(
                                  () => _setDrawFromContactPoint(true),
                                ),
                              ),
                              ChoiceChip(
                                label: Text(_text('上移笔尖', 'Lifted tip')),
                                selected: !_drawFromContactPoint,
                                onSelected: (_) => refresh(
                                  () => _setDrawFromContactPoint(false),
                                ),
                              ),
                            ],
                          ),
                          if (!_drawFromContactPoint) ...<Widget>[
                            const SizedBox(height: 10),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Slider(
                                    value: _touchOffset,
                                    min: 0,
                                    max: 1,
                                    divisions: 10,
                                    activeColor: _background.accent,
                                    onChanged: (value) {
                                      refresh(() => _setTouchOffset(value));
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _ZenActionBadge(
                                  label: _text('偏移', 'Offset'),
                                  value: '${(_touchOffset * 100).round()}%',
                                  accent: _background.accent,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ZenSectionCard(
                      title: _text('手势与缩放', 'Gestures & zoom'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _text(
                              '单指负责绘制或落石，双指负责缩放和平移；如果想避开手指遮挡，可以切到上移笔尖。',
                              'Single-finger input keeps drawing or placing stones, while two fingers handle zoom and pan for detail work.',
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: const Color(0xFF655949),
                                  height: 1.4,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: <Widget>[
                              _ZenCompactActionChip(
                                icon: Icons.zoom_out_map_rounded,
                                label: '${_viewportScale.toStringAsFixed(1)}x',
                                accent: _background.accent,
                                onTap: _viewportScale > 1.01
                                    ? () => refresh(_resetViewport)
                                    : null,
                              ),
                              _ZenCompactActionChip(
                                icon: _immersiveMode
                                    ? Icons.fullscreen_exit_rounded
                                    : Icons.fullscreen_rounded,
                                label: _text('沉浸模式', 'Immersive'),
                                accent: _tool.tint,
                                onTap: () => refresh(_toggleImmersiveMode),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shellGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        Color.lerp(_background.startColor, Colors.white, 0.22)!,
        Color.lerp(_background.endColor, const Color(0xFF15110D), 0.62)!,
      ],
    );

    return PopScope(
      canPop: !_immersiveMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _immersiveMode) {
          _setImmersiveMode(false);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4EFE7),
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: shellGradient),
          child: _immersiveMode
              ? _buildImmersiveBody(theme)
              : _buildRegularBody(theme),
        ),
      ),
    );
  }

  Widget _buildRegularBody(ThemeData theme) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isShortViewport = constraints.maxHeight < 820;
          final collapseDock = constraints.maxHeight < 900;
          final foldBottomDock = constraints.maxHeight < 760;
          final hideRitualRow = constraints.maxHeight < 700;
          final hideInlinePalette = constraints.maxHeight < 740;
          final headerGap = isShortViewport ? 10.0 : 14.0;
          final sectionGap = isShortViewport ? 8.0 : 12.0;
          final bottomDockMaxHeight = math
              .min(
                foldBottomDock
                    ? 72.0
                    : collapseDock
                    ? constraints.maxHeight * 0.22
                    : isShortViewport
                    ? constraints.maxHeight * 0.4
                    : constraints.maxHeight * 0.48,
                foldBottomDock
                    ? 72.0
                    : collapseDock
                    ? 142.0
                    : isShortViewport
                    ? 272.0
                    : 360.0,
              )
              .toDouble();

          return Padding(
            padding: EdgeInsets.fromLTRB(16, isShortViewport ? 6 : 8, 16, 16),
            child: Column(
              children: <Widget>[
                _buildHeader(theme),
                SizedBox(height: headerGap),
                _buildStats(theme),
                if (!hideRitualRow) ...<Widget>[
                  SizedBox(height: sectionGap),
                  _buildRitualQuickRow(theme),
                ],
                SizedBox(height: sectionGap),
                if (_guideEnabled && !collapseDock) ...<Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _ZenGlassPill(
                      icon: _tool.icon,
                      accent: _tool.tint,
                      label: _tool.help(_isZh),
                    ),
                  ),
                  SizedBox(height: sectionGap),
                ],
                if (_toolSupportsColor && !hideInlinePalette) ...<Widget>[
                  _buildOuterPalette(theme),
                  SizedBox(height: sectionGap),
                ],
                Expanded(child: _buildCanvas(theme, immersive: false)),
                SizedBox(height: headerGap),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: bottomDockMaxHeight),
                  child: _buildBottomDock(
                    theme,
                    compact: collapseDock,
                    collapsed: foldBottomDock,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImmersiveBody(ThemeData theme) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: _buildCanvas(theme, immersive: true),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Align(
            alignment: Alignment.topCenter,
            child: Row(
              children: <Widget>[
                _ZenQuickIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: _text('返回', 'Back'),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 8),
                _ZenQuickIconButton(
                  icon: Icons.fullscreen_exit_rounded,
                  tooltip: _text('退出全屏', 'Exit full screen'),
                  onPressed: _toggleImmersiveMode,
                ),
                const Spacer(),
                _ZenQuickIconButton(
                  icon: Icons.landscape_rounded,
                  tooltip: _text('切换场景', 'Scenes'),
                  onPressed: _openSceneSheet,
                ),
                const SizedBox(width: 8),
                _ZenQuickIconButton(
                  icon: Icons.tune_rounded,
                  tooltip: _text('工具与控制', 'Tools & controls'),
                  onPressed: _openControlSheet,
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomDock(theme, compact: true),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ZenQuickIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: _text('返回', 'Back'),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _text('禅意沙盘', 'Zen sand tray'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E1813),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _text(
                  '像在沙面上作画一样，自由涂鸦、铺陈留白、安放景石。',
                  'Sketch freely as if drawing on sand, leaving space and placing stones.',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF4D443A),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _ZenQuickIconButton(
          icon: Icons.landscape_rounded,
          tooltip: _text('切换场景', 'Scenes'),
          onPressed: _openSceneSheet,
        ),
        const SizedBox(width: 8),
        _ZenQuickIconButton(
          icon: Icons.tune_rounded,
          tooltip: _text('工具与控制', 'Tools & controls'),
          onPressed: _openControlSheet,
        ),
      ],
    );
  }

  Widget _buildStats(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _ZenActionBadge(
            label: _text('场景', 'Scene'),
            value: _background.label(_isZh),
            accent: _background.accent,
          ),
          const SizedBox(width: 10),
          _ZenActionBadge(
            label: _text('笔触', 'Strokes'),
            value: _strokeCount.toString(),
            accent: _tool.tint,
          ),
          const SizedBox(width: 10),
          _ZenActionBadge(
            label: _text('景石', 'Stones'),
            value: _stoneCount.toString(),
            accent: const Color(0xFF6A6670),
          ),
          const SizedBox(width: 10),
          _ZenActionBadge(
            label: _text('宽度', 'Brush'),
            value: _brushSize.round().toString(),
            accent: Color.lerp(_tool.tint, Colors.white, 0.15)!,
          ),
          const SizedBox(width: 10),
          _ZenActionBadge(
            label: _text('缩放', 'Zoom'),
            value: '${_viewportScale.toStringAsFixed(1)}x',
            accent: _background.accent,
          ),
          if (_toolSupportsColor) ...<Widget>[
            const SizedBox(width: 10),
            _ZenActionBadge(
              label: _text('颜色', 'Color'),
              value: _activeColorSpec.label(_isZh),
              accent: Color(_colorValue),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRitualQuickRow(ThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.9),
        border: Border.all(color: Colors.white.withValues(alpha: 0.74)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _text('起手预设', 'Quick rituals'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF281F16),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _text(
                          '空白沙盘也可以直接画；预设只是帮你更快进入手感。',
                          'Blank trays are welcome too. Presets simply get you into the flow faster.',
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF655949),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _ZenCompactActionChip(
                  icon: Icons.auto_awesome_rounded,
                  label: _text('全部', 'Browse'),
                  accent: _background.accent,
                  onTap: _openRitualSheet,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _ritualPresets
                    .map(
                      (preset) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _ZenRitualQuickChip(
                          preset: preset,
                          isZh: _isZh,
                          selected: preset.id == _lastPresetId,
                          onTap: () {
                            unawaited(_useRitualPreset(preset));
                          },
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _ZenCanvasHint(
                  label: _text(
                    '声音：$_soundDescriptor',
                    'Sound: $_soundDescriptor',
                  ),
                  accent: _soundEnabled ? _tool.tint : const Color(0xFF9D8D7E),
                ),
                _ZenCanvasHint(
                  label: _text('触点：$_anchorLabel', 'Anchor: $_anchorLabel'),
                  accent: _background.accent,
                ),
                if (_lastPreset != null)
                  _ZenCanvasHint(
                    label: _text(
                      '上次：${_lastPreset!.title(_isZh)}',
                      'Last: ${_lastPreset!.title(_isZh)}',
                    ),
                    accent: _lastPreset!.accent,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvas(ThemeData theme, {required bool immersive}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final hideCanvasActionStrip = !immersive && maxHeight < 290;
        final hideCanvasChrome = !immersive && maxHeight < 220;
        final canvasGap = hideCanvasChrome
            ? 0.0
            : hideCanvasActionStrip
            ? 8.0
            : 12.0;
        final canvasHeight = immersive
            ? maxHeight
            : math.min(maxHeight, width * 1.18);
        final canvasSize = Size(width, canvasHeight);
        _currentCanvasSize = canvasSize;

        return Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: width,
            height: immersive ? maxHeight : null,
            padding: EdgeInsets.all(
              immersive
                  ? 10
                  : hideCanvasChrome
                  ? 8
                  : 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(immersive ? 34 : 30),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color.lerp(_background.accent, Colors.white, 0.82)!,
                  Color.lerp(_background.endColor, Colors.black, 0.22)!,
                ],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: immersive ? 0.16 : 0.12,
                  ),
                  blurRadius: immersive ? 32 : 26,
                  offset: Offset(0, immersive ? 18 : 16),
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                if (!hideCanvasChrome) ...<Widget>[
                  _buildCanvasChrome(theme, immersive: immersive),
                  SizedBox(height: canvasGap),
                ],
                if (!hideCanvasActionStrip) ...<Widget>[
                  _buildCanvasActionStrip(),
                  SizedBox(height: canvasGap),
                ],
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(immersive ? 28 : 24),
                    child: Listener(
                      onPointerDown: _handlePointerDown,
                      onPointerUp: _handlePointerUp,
                      onPointerCancel: _handlePointerUp,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: _tool.isPlacement
                            ? (details) {
                                _placeStone(details.localPosition, canvasSize);
                              }
                            : null,
                        onScaleStart: (details) {
                          _handleScaleStart(details, canvasSize);
                        },
                        onScaleUpdate: (details) {
                          _handleScaleUpdate(details, canvasSize);
                        },
                        onScaleEnd: _handleScaleEnd,
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            RepaintBoundary(
                              child: CustomPaint(
                                painter: _ZenSurfacePainter(
                                  background: _background,
                                  viewportScale: _viewportScale,
                                  viewportOffset: _viewportOffset,
                                ),
                                foregroundPainter: _ZenSandPainter(
                                  background: _background,
                                  actions: _actions,
                                  currentStroke: _workingStroke,
                                  currentToolId: _toolId,
                                  currentBrushSize: _brushSize,
                                  currentColorValue: _toolSupportsColor
                                      ? _colorValue
                                      : null,
                                  viewportScale: _viewportScale,
                                  viewportOffset: _viewportOffset,
                                ),
                              ),
                            ),
                            if (_guideEnabled)
                              Positioned(
                                left: 12,
                                top: 12,
                                child: _ZenCanvasHint(
                                  label: _tool.isPlacement
                                      ? _text('轻点放置景石', 'Tap to place stones')
                                      : _text(
                                          '单指绘制，双指缩放/平移',
                                          'One finger draws, two fingers zoom/pan',
                                        ),
                                  accent: _tool.tint,
                                ),
                              ),
                            if (_transformHintVisible)
                              Positioned(
                                left: 12,
                                top: _guideEnabled ? 56 : 12,
                                child: _ZenCanvasHint(
                                  label: _text(
                                    '双指已识别，停顿后进入缩放/平移',
                                    'Two fingers detected. Hold briefly to zoom/pan',
                                  ),
                                  accent: _background.accent,
                                ),
                              ),
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: _ZenCanvasHint(
                                label: _toolSupportsColor
                                    ? _activeColorSpec.label(_isZh)
                                    : _tool.label(_isZh),
                                accent: _toolSupportsColor
                                    ? Color(_colorValue)
                                    : _tool.tint,
                                trailing:
                                    '${_brushSize.round()} px / ${_viewportScale.toStringAsFixed(1)}x',
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildCanvasActionStrip() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _ZenCompactActionChip(
            icon: Icons.auto_awesome_rounded,
            label: _text('起手预设', 'Rituals'),
            accent: _background.accent,
            onTap: _openRitualSheet,
          ),
          const SizedBox(width: 10),
          _ZenCompactActionChip(
            icon: Icons.undo_rounded,
            label: _text('撤销', 'Undo'),
            accent: _tool.tint,
            onTap: _actions.isNotEmpty ? _undo : null,
          ),
          const SizedBox(width: 10),
          _ZenCompactActionChip(
            icon: Icons.redo_rounded,
            label: _text('重做', 'Redo'),
            accent: _tool.tint,
            onTap: _redoStack.isNotEmpty ? _redo : null,
          ),
          const SizedBox(width: 10),
          _ZenCompactActionChip(
            icon: Icons.auto_fix_high_rounded,
            label: _text('一键抚平', 'Smooth all'),
            accent: _background.accent,
            onTap: _strokeCount == 0 ? null : _smoothAll,
          ),
          const SizedBox(width: 10),
          _ZenCompactActionChip(
            icon: Icons.delete_sweep_rounded,
            label: _text('清空沙盘', 'Clear tray'),
            accent: const Color(0xFF8B6651),
            onTap: _actions.isEmpty
                ? null
                : () {
                    unawaited(_clearAll());
                  },
          ),
          const SizedBox(width: 10),
          _ZenCompactActionChip(
            icon: Icons.center_focus_strong_rounded,
            label: _text('重置视角', 'Reset view'),
            accent: _background.accent,
            onTap: _viewportScale > 1.01 ? _resetViewport : null,
          ),
          const SizedBox(width: 10),
          _ZenCompactActionChip(
            icon: _immersiveMode
                ? Icons.fullscreen_exit_rounded
                : Icons.fullscreen_rounded,
            label: _immersiveMode
                ? _text('退出全屏', 'Exit full screen')
                : _text('沉浸模式', 'Immersive'),
            accent: _tool.tint,
            onTap: _toggleImmersiveMode,
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasChrome(ThemeData theme, {required bool immersive}) {
    const color = Color(0xFF2C241E);
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _background.label(_isZh),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _background.description(_isZh),
                maxLines: immersive ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color.withValues(alpha: 0.72),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _ZenMiniMetric(
          icon: _tool.icon,
          label: _tool.label(_isZh),
          accent: _tool.tint,
        ),
      ],
    );
  }

  Widget _buildOuterPalette(ThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.9),
        border: Border.all(color: Colors.white.withValues(alpha: 0.74)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  _text('颜色色盘', 'Color palette'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF281F16),
                  ),
                ),
                const Spacer(),
                _ZenActionBadge(
                  label: _text('当前', 'Active'),
                  value: _activeColorSpec.label(_isZh),
                  accent: Color(_colorValue),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _paintPalette.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final color = _paintPalette[index];
                  return _ZenColorChip(
                    color: color.color,
                    label: color.label(_isZh),
                    selected: color.value == _colorValue,
                    onTap: () => _setColorValue(color.value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomDock(
    ThemeData theme, {
    bool compact = false,
    bool collapsed = false,
  }) {
    if (collapsed) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withValues(alpha: 0.92),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _tool.tint.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(_tool.icon, size: 18, color: _tool.tint),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _tool.label(_isZh),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: const Color(0xFF2C241E),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            _text('底部菜单已折叠', 'Bottom menu folded'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF6A5B4C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      _ZenDockButton(
                        icon: Icons.landscape_rounded,
                        label: _text('场景', 'Scenes'),
                        onPressed: _openSceneSheet,
                      ),
                      const SizedBox(width: 4),
                      _ZenDockButton(
                        icon: Icons.tune_rounded,
                        label: _text('工具', 'Tools'),
                        onPressed: _openControlSheet,
                      ),
                      const SizedBox(width: 4),
                      _ZenDockButton(
                        icon: Icons.undo_rounded,
                        label: _text('撤销', 'Undo'),
                        enabled: _actions.isNotEmpty,
                        onPressed: _undo,
                      ),
                      const SizedBox(width: 4),
                      _ZenDockButton(
                        icon: Icons.redo_rounded,
                        label: _text('重做', 'Redo'),
                        enabled: _redoStack.isNotEmpty,
                        onPressed: _redo,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (compact) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.white.withValues(alpha: 0.88),
          border: Border.all(color: Colors.white.withValues(alpha: 0.64)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _tool.help(_isZh),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF5F554A),
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    _ZenDockButton(
                      icon: Icons.landscape_rounded,
                      label: _text('场景', 'Scenes'),
                      onPressed: _openSceneSheet,
                    ),
                    const SizedBox(width: 8),
                    _ZenDockButton(
                      icon: Icons.tune_rounded,
                      label: _text('控制', 'Control'),
                      onPressed: _openControlSheet,
                    ),
                    const SizedBox(width: 8),
                    _ZenDockButton(
                      icon: Icons.undo_rounded,
                      label: _text('撤销', 'Undo'),
                      enabled: _actions.isNotEmpty,
                      onPressed: _undo,
                    ),
                    const SizedBox(width: 8),
                    _ZenDockButton(
                      icon: Icons.redo_rounded,
                      label: _text('重做', 'Redo'),
                      enabled: _redoStack.isNotEmpty,
                      onPressed: _redo,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 58,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tools.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final tool = _tools[index];
                    return _ZenCompactToolChip(
                      tool: tool,
                      isZh: _isZh,
                      selected: tool.id == _toolId,
                      onTap: () => _selectTool(tool.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withValues(alpha: 0.88),
        border: Border.all(color: Colors.white.withValues(alpha: 0.64)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _tool.help(_isZh),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF5F554A),
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  _ZenDockButton(
                    icon: Icons.landscape_rounded,
                    label: _text('场景', 'Scenes'),
                    onPressed: _openSceneSheet,
                  ),
                  const SizedBox(width: 8),
                  _ZenDockButton(
                    icon: Icons.undo_rounded,
                    label: _text('撤销', 'Undo'),
                    enabled: _actions.isNotEmpty,
                    onPressed: _undo,
                  ),
                  const SizedBox(width: 8),
                  _ZenDockButton(
                    icon: Icons.redo_rounded,
                    label: _text('重做', 'Redo'),
                    enabled: _redoStack.isNotEmpty,
                    onPressed: _redo,
                  ),
                  const SizedBox(width: 8),
                  _ZenDockButton(
                    icon: _immersiveMode
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    label: _immersiveMode
                        ? _text('退出全屏', 'Exit full')
                        : _text('沉浸', 'Immersive'),
                    onPressed: _toggleImmersiveMode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _ZenDrawerSectionCard(
              icon: Icons.handyman_rounded,
              title: _text('工具抽屉', 'Tool drawer'),
              subtitle: _text(
                '折叠查看全部工具，避免在手机上反复横向滑动。',
                'Open the folded tool drawer instead of swiping through everything on mobile.',
              ),
              expanded: _expandedDrawerSections.contains(
                _ZenDrawerSection.tools,
              ),
              onTap: () => _toggleDrawerSection(_ZenDrawerSection.tools),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _tools
                    .map(
                      (tool) => _ZenCompactToolChip(
                        tool: tool,
                        isZh: _isZh,
                        selected: tool.id == _toolId,
                        onTap: () => _selectTool(tool.id),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 10),
            _ZenDrawerSectionCard(
              icon: Icons.brush_rounded,
              title: _text('笔触与材质', 'Brush & material'),
              subtitle: _text(
                '快速调笔触宽度，并预览当前工具在沙面上的表现。',
                'Tune brush size and preview how the active tool behaves on sand.',
              ),
              expanded: _expandedDrawerSections.contains(
                _ZenDrawerSection.brush,
              ),
              onTap: () => _toggleDrawerSection(_ZenDrawerSection.brush),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _ZenToolPreview(
                          background: _background,
                          tool: _tool,
                          brushSize: _brushSize,
                          colorValue: _toolSupportsColor ? _colorValue : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _ZenActionBadge(
                        label: _text('尺寸', 'Size'),
                        value: _brushSize.round().toString(),
                        accent: _tool.tint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: _brushSize,
                    min: 14,
                    max: 96,
                    divisions: 41,
                    activeColor: _tool.tint,
                    onChanged: _setBrushSize,
                    onChangeEnd: (_) => _persist(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _ZenDrawerSectionCard(
              icon: Icons.tune_rounded,
              title: _text('体验设置', 'Experience'),
              subtitle: _text(
                '把触感、持续音效和触点锚定集中到一个折叠卡片里。',
                'Keep haptics, continuous sand audio, and touch anchoring in one folded card.',
              ),
              expanded: _expandedDrawerSections.contains(
                _ZenDrawerSection.experience,
              ),
              onTap: () => _toggleDrawerSection(_ZenDrawerSection.experience),
              child: Column(
                children: <Widget>[
                  _ZenToggleRow(
                    title: _text('触感反馈', 'Haptics'),
                    subtitle: _text(
                      '切换工具、落石和撤销时给出轻微振动。',
                      'Adds light feedback when switching tools, placing stones, and undoing.',
                    ),
                    value: _hapticsEnabled,
                    activeColor: _background.accent,
                    onChanged: _toggleHaptics,
                  ),
                  const Divider(height: 18),
                  _ZenToggleRow(
                    title: _text('沙盘音效', 'Sand sounds'),
                    subtitle: _text(
                      '拖动时持续播放沙沙底噪，停手即停。',
                      'Keeps a continuous sand texture running while you drag and stops as soon as you lift.',
                    ),
                    value: _soundEnabled,
                    activeColor: _background.accent,
                    onChanged: _toggleSound,
                  ),
                  const Divider(height: 18),
                  _ZenToggleRow(
                    title: _text('操作提示', 'Guidance'),
                    subtitle: _text(
                      '在画布上显示当前工具的手势说明。',
                      'Shows contextual hints for the active tool.',
                    ),
                    value: _guideEnabled,
                    activeColor: _background.accent,
                    onChanged: _toggleGuidance,
                  ),
                  const Divider(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _text('触点锚定', 'Touch anchor'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF281F16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _text(
                      '按画布相对尺寸自适应对齐，可直接贴合触点，也可把笔尖抬到手指上方。',
                      'The anchor now adapts relative to canvas size, so you can draw right under the touch or lift the tip above your finger.',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF655949),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      ChoiceChip(
                        label: Text(_text('贴合触点', 'Contact point')),
                        selected: _drawFromContactPoint,
                        onSelected: (_) => _setDrawFromContactPoint(true),
                      ),
                      ChoiceChip(
                        label: Text(_text('上移笔尖', 'Lifted tip')),
                        selected: !_drawFromContactPoint,
                        onSelected: (_) => _setDrawFromContactPoint(false),
                      ),
                    ],
                  ),
                  if (!_drawFromContactPoint) ...<Widget>[
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Slider(
                            value: _touchOffset,
                            min: 0,
                            max: 1,
                            divisions: 10,
                            activeColor: _background.accent,
                            onChanged: _setTouchOffset,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _ZenActionBadge(
                          label: _text('偏移', 'Offset'),
                          value: '${(_touchOffset * 100).round()}%',
                          accent: _background.accent,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            _ZenDrawerSectionCard(
              icon: Icons.zoom_out_map_rounded,
              title: _text('手势与视角', 'Gestures & view'),
              subtitle: _text(
                '把缩放、视角和沉浸模式也收进折叠卡片里。',
                'Keep zoom, view reset, and immersive mode inside a folded card as well.',
              ),
              expanded: _expandedDrawerSections.contains(
                _ZenDrawerSection.gestures,
              ),
              onTap: () => _toggleDrawerSection(_ZenDrawerSection.gestures),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _text(
                      '单指绘制或落石，双指缩放和平移；水迹长按会继续向周围积湿加深。',
                      'Use one finger for drawing or stones and two fingers for zoom/pan; holding the water tool keeps building damp diffusion.',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF655949),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      _ZenCompactActionChip(
                        icon: Icons.zoom_out_map_rounded,
                        label: '${_viewportScale.toStringAsFixed(1)}x',
                        accent: _background.accent,
                        onTap: _viewportScale > 1.01 ? _resetViewport : null,
                      ),
                      _ZenCompactActionChip(
                        icon: _immersiveMode
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        label: _immersiveMode
                            ? _text('退出全屏', 'Exit full screen')
                            : _text('沉浸模式', 'Immersive'),
                        accent: _tool.tint,
                        onTap: _toggleImmersiveMode,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _paintTraySurface(
  Canvas canvas,
  Rect rect,
  _ZenBackgroundSpec background, {
  double cornerRadius = 24,
}) {
  final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));

  final fillPaint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        background.startColor,
        background.fillColor,
        background.endColor,
      ],
      stops: const <double>[0, 0.56, 1],
    ).createShader(rect);
  canvas.drawRRect(rrect, fillPaint);

  final vignette = Paint()
    ..shader = RadialGradient(
      center: const Alignment(-0.2, -0.4),
      radius: 1.28,
      colors: <Color>[
        Colors.white.withValues(alpha: 0.16),
        Colors.transparent,
        Colors.black.withValues(alpha: 0.12),
      ],
      stops: const <double>[0, 0.66, 1],
    ).createShader(rect);
  canvas.drawRRect(rrect, vignette);

  _paintBasePattern(canvas, rect, background);
  _paintSandGrain(canvas, rect, background);

  final edgePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.1
    ..color = Colors.white.withValues(alpha: 0.34);
  canvas.drawRRect(rrect.deflate(0.55), edgePaint);

  final innerShadow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 16
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Colors.white.withValues(alpha: 0.12),
        Colors.transparent,
        Colors.black.withValues(alpha: 0.09),
      ],
    ).createShader(rect);
  canvas.drawRRect(rrect.deflate(8), innerShadow);
}

void _paintBasePattern(
  Canvas canvas,
  Rect rect,
  _ZenBackgroundSpec background,
) {
  switch (background.patternKind) {
    case _ZenPatternKind.parallel:
      _paintParallelPattern(canvas, rect, background);
      break;
    case _ZenPatternKind.tidal:
      _paintTidalPattern(canvas, rect, background);
      break;
    case _ZenPatternKind.orbital:
      _paintOrbitalPattern(canvas, rect, background);
      break;
    case _ZenPatternKind.contour:
      _paintContourPattern(canvas, rect, background);
      break;
  }
}

void _paintParallelPattern(
  Canvas canvas,
  Rect rect,
  _ZenBackgroundSpec background,
) {
  final dark = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 1.15
    ..color = background.grooveDark.withValues(alpha: 0.18);
  final light = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 0.8
    ..color = background.grooveLight.withValues(alpha: 0.22);

  for (
    double y = rect.top + 18;
    y < rect.bottom - 12;
    y += background.lineSpacing
  ) {
    final path = Path()..moveTo(rect.left + 10, y);
    for (double x = rect.left + 10; x <= rect.right; x += 18) {
      path.quadraticBezierTo(
        x + 9,
        y +
            math.sin((x + y + background.patternSeed) / 34) *
                background.waveAmplitude,
        math.min(x + 18, rect.right - 10),
        y,
      );
    }
    canvas.drawPath(path, dark);
    canvas.save();
    canvas.translate(0, -1.1);
    canvas.drawPath(path, light);
    canvas.restore();
  }
}

void _paintTidalPattern(
  Canvas canvas,
  Rect rect,
  _ZenBackgroundSpec background,
) {
  final dark = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..color = background.grooveDark.withValues(alpha: 0.16);
  final light = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.7
    ..color = background.grooveLight.withValues(alpha: 0.2);

  for (
    double y = rect.top + 20;
    y < rect.bottom - 8;
    y += background.lineSpacing
  ) {
    final path = Path()..moveTo(rect.left - 8, y);
    for (double x = rect.left - 8; x <= rect.right + 24; x += 22) {
      final wave =
          math.sin((x * 0.018) + y * 0.015 + background.patternSeed) *
          background.waveAmplitude;
      path.quadraticBezierTo(
        x + 10,
        y + wave,
        math.min(x + 22, rect.right + 24),
        y + wave * 0.22,
      );
    }
    canvas.drawPath(path, dark);
    canvas.save();
    canvas.translate(0, -0.9);
    canvas.drawPath(path, light);
    canvas.restore();
  }
}

void _paintOrbitalPattern(
  Canvas canvas,
  Rect rect,
  _ZenBackgroundSpec background,
) {
  final center = Offset(rect.center.dx * 1.02, rect.center.dy * 0.96);
  final dark = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..color = background.grooveDark.withValues(alpha: 0.17);
  final light = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.75
    ..color = background.grooveLight.withValues(alpha: 0.22);

  for (
    double radius = 32;
    radius < rect.longestSide * 0.88;
    radius += background.lineSpacing
  ) {
    final ellipse = Rect.fromCenter(
      center: center,
      width: radius * 2.18,
      height: radius * 1.26,
    );
    canvas.drawOval(ellipse, dark);
    canvas.drawOval(ellipse.shift(const Offset(0, -1.0)), light);
  }
}

void _paintContourPattern(
  Canvas canvas,
  Rect rect,
  _ZenBackgroundSpec background,
) {
  final dark = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..color = background.grooveDark.withValues(alpha: 0.17);
  final light = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.7
    ..color = background.grooveLight.withValues(alpha: 0.18);

  for (double x = rect.left - 10; x < rect.right + 40; x += 34) {
    final path = Path()..moveTo(x, rect.top - 12);
    for (double y = rect.top - 12; y < rect.bottom + 24; y += 20) {
      final offset =
          math.sin((x + y + background.patternSeed) / 38) *
          background.waveAmplitude *
          1.3;
      path.quadraticBezierTo(
        x + offset,
        y + 8,
        x + offset * 0.6,
        math.min(y + 20, rect.bottom + 24),
      );
    }
    canvas.drawPath(path, dark);
    canvas.save();
    canvas.translate(-0.8, 0);
    canvas.drawPath(path, light);
    canvas.restore();
  }
}

void _paintSandGrain(Canvas canvas, Rect rect, _ZenBackgroundSpec background) {
  final random = math.Random(background.patternSeed);
  final grainPaint = Paint()..style = PaintingStyle.fill;
  final total = (rect.width * rect.height / 1800).round().clamp(80, 240);
  for (int i = 0; i < total; i++) {
    final dx = rect.left + random.nextDouble() * rect.width;
    final dy = rect.top + random.nextDouble() * rect.height;
    final radius = random.nextDouble() * 1.2 + 0.2;
    grainPaint.color =
        (i.isEven ? background.grooveLight : background.grooveDark).withValues(
          alpha: i.isEven ? 0.08 : 0.05,
        );
    canvas.drawCircle(Offset(dx, dy), radius, grainPaint);
  }
}

void _paintSandActions(
  Canvas canvas,
  Size size, {
  required _ZenBackgroundSpec background,
  required List<ZenSandAction> actions,
  required List<Offset> currentStroke,
  required String currentToolId,
  required double currentBrushSize,
  required int? currentColorValue,
}) {
  for (final action in actions) {
    if (action.isStone) {
      _paintStone(canvas, size, action, background);
      continue;
    }
    _paintStroke(
      canvas,
      size,
      action.toolId,
      action.size,
      action.points
          .map((point) => Offset(point.x, point.y))
          .toList(growable: false),
      background,
      colorValue: action.colorValue,
      isPreview: false,
    );
  }

  if (currentStroke.length >= 2) {
    _paintStroke(
      canvas,
      size,
      currentToolId,
      currentBrushSize,
      currentStroke,
      background,
      colorValue: currentColorValue,
      isPreview: true,
    );
  }
}

void _paintStroke(
  Canvas canvas,
  Size size,
  String toolId,
  double brushSize,
  List<Offset> normalizedPoints,
  _ZenBackgroundSpec background, {
  required int? colorValue,
  required bool isPreview,
}) {
  final points = normalizedPoints
      .map((point) => Offset(point.dx * size.width, point.dy * size.height))
      .toList(growable: false);
  if (points.length < 2) return;

  final alphaScale = isPreview ? 0.72 : 1.0;
  final tintColor = colorValue == null ? null : Color(colorValue);

  switch (toolId) {
    case 'rake':
      _paintRakeStroke(canvas, points, brushSize, background, alphaScale);
      break;
    case 'finger':
      _paintFingerStroke(canvas, points, brushSize, background, alphaScale);
      break;
    case 'paint':
      _paintPigmentStroke(
        canvas,
        points,
        brushSize,
        background,
        tintColor ?? const Color(zenSandDefaultColorValue),
        alphaScale,
      );
      break;
    case 'water':
      _paintWaterStroke(
        canvas,
        points,
        brushSize,
        background,
        tintColor ?? background.accent,
        alphaScale,
      );
      break;
    case 'wave':
      _paintWaveStroke(canvas, points, brushSize, background, alphaScale);
      break;
    case 'shovel':
      _paintShovelStroke(canvas, points, brushSize, background, alphaScale);
      break;
    case 'gravel':
      _paintGravelStroke(canvas, points, brushSize, background, alphaScale);
      break;
    case 'smooth':
      _paintSmoothStroke(canvas, points, brushSize, background, alphaScale);
      break;
    default:
      _paintFingerStroke(canvas, points, brushSize, background, alphaScale);
      break;
  }
}

void _paintRakeStroke(
  Canvas canvas,
  List<Offset> points,
  double brushSize,
  _ZenBackgroundSpec background,
  double alphaScale,
) {
  final laneSpacing = (brushSize * 0.14).clamp(3.2, 10.5);
  const offsets = <double>[-2, -1, 0, 1, 2];
  for (final lane in offsets) {
    final shifted = _offsetPolyline(points, lane * laneSpacing);
    final path = _smoothPath(shifted);
    final dark = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = (brushSize * 0.048).clamp(1.05, 2.6)
      ..color = background.grooveDark.withValues(alpha: 0.54 * alphaScale);
    final light = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = (brushSize * 0.028).clamp(0.7, 1.4)
      ..color = background.grooveLight.withValues(alpha: 0.46 * alphaScale);
    canvas.drawPath(path, dark);
    canvas.save();
    canvas.translate(0, -1.2);
    canvas.drawPath(path, light);
    canvas.restore();
  }
}

void _paintFingerStroke(
  Canvas canvas,
  List<Offset> points,
  double brushSize,
  _ZenBackgroundSpec background,
  double alphaScale,
) {
  final path = _smoothPath(points);
  final shadow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.42
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2)
    ..color = background.grooveDark.withValues(alpha: 0.20 * alphaScale);
  final groove = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.24
    ..color = background.grooveDark.withValues(alpha: 0.42 * alphaScale);
  final highlight = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.11
    ..color = background.grooveLight.withValues(alpha: 0.40 * alphaScale);

  canvas.drawPath(path, shadow);
  canvas.drawPath(path, groove);
  canvas.save();
  canvas.translate(-1.4, -1.2);
  canvas.drawPath(path, highlight);
  canvas.restore();
}

void _paintPigmentStroke(
  Canvas canvas,
  List<Offset> points,
  double brushSize,
  _ZenBackgroundSpec background,
  Color tintColor,
  double alphaScale,
) {
  final path = _smoothPath(points);
  final glow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.48
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.2)
    ..color = tintColor.withValues(alpha: 0.18 * alphaScale);
  final body = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.28
    ..color = Color.lerp(
      tintColor,
      background.fillColor,
      0.08,
    )!.withValues(alpha: 0.78 * alphaScale);
  final highlight = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.12
    ..color = Color.lerp(
      tintColor,
      Colors.white,
      0.46,
    )!.withValues(alpha: 0.36 * alphaScale);

  canvas.drawPath(path, glow);
  canvas.drawPath(path, body);
  canvas.save();
  canvas.translate(-1.0, -1.0);
  canvas.drawPath(path, highlight);
  canvas.restore();
}

void _paintWaterStroke(
  Canvas canvas,
  List<Offset> points,
  double brushSize,
  _ZenBackgroundSpec background,
  Color tintColor,
  double alphaScale,
) {
  final waved = _wavePolyline(points, brushSize * 0.08);
  final path = _smoothPath(waved);
  final wetShadow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.98
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13)
    ..color = Color.lerp(
      background.grooveDark,
      tintColor,
      0.44,
    )!.withValues(alpha: 0.14 * alphaScale);
  final bloom = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.88
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
    ..color = Color.lerp(
      tintColor,
      background.grooveLight,
      0.18,
    )!.withValues(alpha: 0.11 * alphaScale);
  final dampCore = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.38
    ..color = Color.lerp(
      tintColor,
      background.grooveDark,
      0.28,
    )!.withValues(alpha: 0.28 * alphaScale);
  final trail = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.28
    ..color = Color.lerp(
      tintColor,
      background.grooveLight,
      0.34,
    )!.withValues(alpha: 0.36 * alphaScale);
  final light = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.08
    ..color = Colors.white.withValues(alpha: 0.42 * alphaScale);

  canvas.drawPath(path, wetShadow);
  canvas.drawPath(path, bloom);
  canvas.drawPath(path, dampCore);
  canvas.drawPath(path, trail);
  canvas.save();
  canvas.translate(-0.8, -0.8);
  canvas.drawPath(path, light);
  canvas.restore();

  final diffuseShadow = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
  final diffuseEdge = Paint()..style = PaintingStyle.fill;
  final diffuseCore = Paint()..style = PaintingStyle.fill;
  final diffuseHighlight = Paint()..style = PaintingStyle.fill;
  final pointStep = points.length > 180 ? 2 : 1;
  for (int i = 0; i < waved.length; i += pointStep) {
    final offset = waved[i];
    final prevDistance = i == 0
        ? brushSize
        : (waved[i] - waved[i - 1]).distance;
    final nextDistance = i == waved.length - 1
        ? brushSize
        : (waved[i + 1] - waved[i]).distance;
    final holdRadius = brushSize * 0.16;
    final holdBoost =
        (1 -
                math
                        .min(prevDistance, nextDistance)
                        .clamp(0.0, holdRadius)
                        .toDouble() /
                    holdRadius)
            .clamp(0.0, 1.0)
            .toDouble();
    final spreadRadius =
        brushSize * (0.18 + holdBoost * 0.22 + (i.isEven ? 0.03 : 0.0));
    final centerRadius = spreadRadius * (0.42 + holdBoost * 0.18);
    final edgeRadius = spreadRadius * (0.74 + holdBoost * 0.12);

    diffuseShadow.color = Color.lerp(
      background.grooveDark,
      tintColor,
      0.54,
    )!.withValues(alpha: (0.08 + holdBoost * 0.10) * alphaScale);
    canvas.drawCircle(offset, spreadRadius * 1.58, diffuseShadow);

    diffuseEdge.color = Color.lerp(
      tintColor,
      background.grooveLight,
      0.28,
    )!.withValues(alpha: (0.10 + holdBoost * 0.08) * alphaScale);
    canvas.drawCircle(offset, edgeRadius, diffuseEdge);

    diffuseCore.color = Color.lerp(
      tintColor,
      background.grooveDark,
      0.42,
    )!.withValues(alpha: (0.14 + holdBoost * 0.12) * alphaScale);
    canvas.drawCircle(offset, centerRadius, diffuseCore);

    diffuseHighlight.color = Color.lerp(
      tintColor,
      Colors.white,
      0.52,
    )!.withValues(alpha: (0.07 + holdBoost * 0.05) * alphaScale);
    canvas.drawCircle(
      offset.translate(-spreadRadius * 0.16, -spreadRadius * 0.18),
      spreadRadius * 0.24,
      diffuseHighlight,
    );

    for (int burst = 0; burst < 3; burst += 1) {
      final seed = i * 0.93 + burst * 2.17;
      final burstOffset = Offset(
        math.cos(seed) * spreadRadius * (0.26 + burst * 0.1),
        math.sin(seed) * spreadRadius * (0.24 + burst * 0.12),
      );
      final burstCenter = offset + burstOffset;
      final burstRadius =
          spreadRadius * (0.18 + burst * 0.06 + holdBoost * 0.05);
      diffuseEdge.color = Color.lerp(
        tintColor,
        background.grooveLight,
        0.42,
      )!.withValues(alpha: (0.08 + holdBoost * 0.06) * alphaScale);
      canvas.drawCircle(burstCenter, burstRadius, diffuseEdge);
      diffuseCore.color = Color.lerp(
        tintColor,
        background.grooveDark,
        0.24,
      )!.withValues(alpha: (0.07 + holdBoost * 0.05) * alphaScale);
      canvas.drawCircle(burstCenter, burstRadius * 0.54, diffuseCore);
    }
  }
}

void _paintWaveStroke(
  Canvas canvas,
  List<Offset> points,
  double brushSize,
  _ZenBackgroundSpec background,
  double alphaScale,
) {
  final waved = _wavePolyline(points, brushSize * 0.12);
  final path = _smoothPath(waved);
  final shadow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.18
    ..color = background.accent.withValues(alpha: 0.18 * alphaScale);
  final groove = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.1
    ..color = Color.lerp(
      background.grooveDark,
      background.accent,
      0.48,
    )!.withValues(alpha: 0.48 * alphaScale);
  final light = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.05
    ..color = background.grooveLight.withValues(alpha: 0.46 * alphaScale);

  canvas.drawPath(path, shadow);
  canvas.drawPath(path, groove);
  canvas.save();
  canvas.translate(0, -1.0);
  canvas.drawPath(path, light);
  canvas.restore();
}

void _paintShovelStroke(
  Canvas canvas,
  List<Offset> points,
  double brushSize,
  _ZenBackgroundSpec background,
  double alphaScale,
) {
  final path = _smoothPath(points);
  final ridgeOffset = (brushSize * 0.28).clamp(7.0, 20.0);
  final leftPoints = _offsetPolyline(points, ridgeOffset);
  final rightPoints = _offsetPolyline(points, -ridgeOffset);
  final leftPath = _smoothPath(leftPoints);
  final rightPath = _smoothPath(rightPoints);
  final troughShadow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.76
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
    ..color = background.grooveDark.withValues(alpha: 0.12 * alphaScale);
  final trough = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.58
    ..color = Color.lerp(
      background.fillColor,
      background.grooveDark,
      0.14,
    )!.withValues(alpha: 0.84 * alphaScale);
  final scrape = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.16
    ..color = background.grooveDark.withValues(alpha: 0.34 * alphaScale);
  final ridgeShadow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.24
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.8)
    ..color = background.grooveDark.withValues(alpha: 0.12 * alphaScale);
  final berm = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.28
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.2)
    ..color = Color.lerp(
      background.grooveLight,
      background.fillColor,
      0.22,
    )!.withValues(alpha: 0.22 * alphaScale);
  final ridge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.16
    ..color = background.grooveLight.withValues(alpha: 0.32 * alphaScale);
  final duneShadow = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
    ..color = Colors.black.withValues(alpha: 0.08 * alphaScale);
  final duneFill = Paint()..style = PaintingStyle.fill;

  canvas.drawPath(path, troughShadow);
  canvas.drawPath(path, trough);
  canvas.drawPath(path, scrape);
  canvas.drawPath(leftPath, berm);
  canvas.drawPath(rightPath, berm);
  canvas.drawPath(leftPath, ridgeShadow);
  canvas.drawPath(rightPath, ridgeShadow);
  canvas.drawPath(leftPath, ridge);
  canvas.drawPath(rightPath, ridge);

  final leftDunes = _samplePolyline(
    leftPoints,
    (brushSize * 0.24).clamp(10.0, 22.0),
  );
  final rightDunes = _samplePolyline(
    rightPoints,
    (brushSize * 0.24).clamp(10.0, 22.0),
  );
  for (int i = 0; i < leftDunes.length; i += 2) {
    final radius = brushSize * (0.045 + (i % 4) * 0.01);
    final left = leftDunes[i];
    final rightIndex = i < rightDunes.length ? i : rightDunes.length - 1;
    final right = rightDunes[rightIndex];
    canvas.drawCircle(left.translate(1.2, 1.8), radius * 1.12, duneShadow);
    canvas.drawCircle(right.translate(1.2, 1.8), radius * 1.12, duneShadow);
    duneFill.color = Color.lerp(
      background.grooveLight,
      background.fillColor,
      0.34,
    )!.withValues(alpha: 0.38 * alphaScale);
    canvas.drawCircle(left, radius, duneFill);
    duneFill.color = Color.lerp(
      background.grooveLight,
      background.fillColor,
      0.44,
    )!.withValues(alpha: 0.34 * alphaScale);
    canvas.drawCircle(right, radius * 0.96, duneFill);
  }
}

void _paintGravelStroke(
  Canvas canvas,
  List<Offset> points,
  double brushSize,
  _ZenBackgroundSpec background,
  double alphaScale,
) {
  final shadow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.22
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
    ..color = background.grooveDark.withValues(alpha: 0.10 * alphaScale);
  canvas.drawPath(_smoothPath(points), shadow);

  final random = math.Random(points.length * 31 + brushSize.round());
  final pebblePaint = Paint()..style = PaintingStyle.fill;
  final pebbleShadow = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.black.withValues(alpha: 0.10 * alphaScale);
  final samples = _samplePolyline(points, (brushSize * 0.16).clamp(8.0, 18.0));
  for (final sample in samples) {
    final pebble = sample.translate(
      (random.nextDouble() - 0.5) * brushSize * 0.18,
      (random.nextDouble() - 0.5) * brushSize * 0.22,
    );
    final radius = brushSize * (0.045 + random.nextDouble() * 0.035);
    canvas.drawCircle(pebble.translate(1.2, 1.6), radius, pebbleShadow);
    pebblePaint.color = Color.lerp(
      random.nextBool() ? background.grooveDark : background.grooveLight,
      background.fillColor,
      0.38 + random.nextDouble() * 0.28,
    )!.withValues(alpha: 0.84 * alphaScale);
    canvas.drawCircle(pebble, radius, pebblePaint);
  }
}

void _paintSmoothStroke(
  Canvas canvas,
  List<Offset> points,
  double brushSize,
  _ZenBackgroundSpec background,
  double alphaScale,
) {
  final path = _smoothPath(points);
  final blur = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.72
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.4)
    ..color = background.fillColor.withValues(alpha: 0.28 * alphaScale);
  final fill = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.54
    ..color = background.fillColor.withValues(alpha: 0.74 * alphaScale);
  final grain = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = brushSize * 0.18
    ..color = background.grooveLight.withValues(alpha: 0.16 * alphaScale);

  canvas.drawPath(path, blur);
  canvas.drawPath(path, fill);
  canvas.drawPath(path, grain);
}

void _paintStone(
  Canvas canvas,
  Size size,
  ZenSandAction action,
  _ZenBackgroundSpec background,
) {
  final center = Offset(action.x * size.width, action.y * size.height);
  final width = action.size * (0.78 + (action.variant % 3) * 0.14);
  final height = action.size * (0.58 + (action.variant % 4) * 0.1);
  final rect = Rect.fromCenter(center: center, width: width, height: height);

  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(action.rotation);
  canvas.translate(-center.dx, -center.dy);

  final shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.18)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  canvas.drawOval(rect.shift(const Offset(2.5, 5.5)), shadowPaint);

  final base = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Color.lerp(background.grooveLight, const Color(0xFF6E6A6B), 0.74)!,
        Color.lerp(background.grooveDark, const Color(0xFF2C272A), 0.46)!,
      ],
    ).createShader(rect);
  canvas.drawOval(rect, base);

  final edge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.1
    ..color = Colors.white.withValues(alpha: 0.18);
  canvas.drawOval(rect.deflate(0.8), edge);

  final highlight = Paint()
    ..shader = RadialGradient(
      center: const Alignment(-0.3, -0.5),
      radius: 0.9,
      colors: <Color>[Colors.white.withValues(alpha: 0.28), Colors.transparent],
    ).createShader(rect);
  canvas.drawOval(rect.deflate(width * 0.12), highlight);
  canvas.restore();
}

Path _smoothPath(List<Offset> points) {
  if (points.length < 2) {
    return Path()..addPolygon(points, false);
  }

  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (int i = 1; i < points.length - 1; i++) {
    final current = points[i];
    final next = points[i + 1];
    final midpoint = Offset(
      (current.dx + next.dx) / 2,
      (current.dy + next.dy) / 2,
    );
    path.quadraticBezierTo(current.dx, current.dy, midpoint.dx, midpoint.dy);
  }
  final last = points.last;
  path.lineTo(last.dx, last.dy);
  return path;
}

List<Offset> _offsetPolyline(List<Offset> points, double distance) {
  if (points.length < 2) return points;
  final shifted = <Offset>[];
  for (int i = 0; i < points.length; i++) {
    final previous = i == 0 ? points[i] : points[i - 1];
    final next = i == points.length - 1 ? points[i] : points[i + 1];
    final tangent = next - previous;
    final length = tangent.distance;
    if (length == 0) {
      shifted.add(points[i]);
      continue;
    }
    final normal = Offset(-tangent.dy / length, tangent.dx / length);
    shifted.add(points[i] + normal * distance);
  }
  return shifted;
}

List<Offset> _samplePolyline(List<Offset> points, double spacing) {
  if (points.isEmpty) return const <Offset>[];
  if (points.length == 1) return <Offset>[points.first];

  final samples = <Offset>[points.first];
  double remainder = spacing;
  for (int i = 0; i < points.length - 1; i++) {
    final start = points[i];
    final end = points[i + 1];
    final vector = end - start;
    final length = vector.distance;
    if (length == 0) continue;
    var travelled = remainder;
    while (travelled < length) {
      final t = travelled / length;
      samples.add(Offset.lerp(start, end, t)!);
      travelled += spacing;
    }
    remainder = travelled - length;
  }
  if (samples.last != points.last) {
    samples.add(points.last);
  }
  return samples;
}

List<Offset> _wavePolyline(List<Offset> points, double amplitude) {
  if (points.length < 2) return points;
  final waved = <Offset>[points.first];
  double progress = 0;
  for (int i = 0; i < points.length - 1; i++) {
    final start = points[i];
    final end = points[i + 1];
    final vector = end - start;
    final length = vector.distance;
    if (length == 0) continue;
    final normal = Offset(-vector.dy / length, vector.dx / length);
    final steps = math.max(3, (length / 16).round());
    for (int step = 1; step <= steps; step++) {
      final t = step / steps;
      final base = Offset.lerp(start, end, t)!;
      final offset = math.sin((progress + t) * math.pi * 2.2) * amplitude;
      waved.add(base + normal * offset);
    }
    progress += 1;
  }
  return waved;
}

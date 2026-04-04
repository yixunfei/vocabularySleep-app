import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/toolbox_zen_sand_prefs_service.dart';

const int _maxCanvasActions = 220;

enum _ZenPatternKind { parallel, tidal, orbital, contour }

class _ZenBackgroundSpec {
  const _ZenBackgroundSpec({
    required this.id,
    required this.labelZh,
    required this.labelEn,
    required this.descriptionZh,
    required this.descriptionEn,
    required this.startColor,
    required this.endColor,
    required this.accent,
    required this.grooveDark,
    required this.grooveLight,
    required this.patternKind,
    required this.patternSeed,
    required this.lineSpacing,
    required this.waveAmplitude,
  });

  final String id;
  final String labelZh;
  final String labelEn;
  final String descriptionZh;
  final String descriptionEn;
  final Color startColor;
  final Color endColor;
  final Color accent;
  final Color grooveDark;
  final Color grooveLight;
  final _ZenPatternKind patternKind;
  final int patternSeed;
  final double lineSpacing;
  final double waveAmplitude;

  String label(bool isZh) => isZh ? labelZh : labelEn;

  String description(bool isZh) => isZh ? descriptionZh : descriptionEn;

  Color get fillColor => Color.lerp(startColor, endColor, 0.52)!;
}

class _ZenToolSpec {
  const _ZenToolSpec({
    required this.id,
    required this.icon,
    required this.labelZh,
    required this.labelEn,
    required this.helpZh,
    required this.helpEn,
    required this.tint,
    this.isPlacement = false,
  });

  final String id;
  final IconData icon;
  final String labelZh;
  final String labelEn;
  final String helpZh;
  final String helpEn;
  final Color tint;
  final bool isPlacement;

  String label(bool isZh) => isZh ? labelZh : labelEn;

  String help(bool isZh) => isZh ? helpZh : helpEn;
}

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
    id: 'wave',
    icon: Icons.waves_rounded,
    labelZh: '波纹',
    labelEn: 'Ripple',
    helpZh: '生成起伏曲线，适合呼吸节奏与水波感。',
    helpEn: 'Paint rhythmic waves for breathing and water-like motion.',
    tint: Color(0xFF4E8FA8),
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

final Map<String, _ZenBackgroundSpec> _backgroundById =
    <String, _ZenBackgroundSpec>{
      for (final background in _backgrounds) background.id: background,
    };

final Map<String, _ZenToolSpec> _toolById = <String, _ZenToolSpec>{
  for (final tool in _tools) tool.id: tool,
};

class ZenSandStudioPage extends StatefulWidget {
  const ZenSandStudioPage({super.key});

  @override
  State<ZenSandStudioPage> createState() => _ZenSandStudioPageState();
}

class _ZenSandStudioPageState extends State<ZenSandStudioPage> {
  List<ZenSandAction> _actions = <ZenSandAction>[];
  List<ZenSandAction> _redoStack = <ZenSandAction>[];
  List<Offset> _workingStroke = <Offset>[];
  String _backgroundId = zenSandDefaultBackgroundId;
  String _toolId = zenSandDefaultToolId;
  double _brushSize = zenSandDefaultBrushSize;
  bool _hapticsEnabled = true;
  bool _guideEnabled = true;

  bool get _isZh => Localizations.localeOf(
    context,
  ).languageCode.toLowerCase().startsWith('zh');

  String _text(String zh, String en) => _isZh ? zh : en;

  _ZenBackgroundSpec get _background =>
      _backgroundById[_backgroundId] ?? _backgrounds.first;

  _ZenToolSpec get _tool => _toolById[_toolId] ?? _tools.first;

  int get _strokeCount => _actions.where((action) => action.isStroke).length;

  int get _stoneCount => _actions.where((action) => action.isStone).length;

  @override
  void initState() {
    super.initState();
    _restorePrefs();
  }

  Future<void> _restorePrefs() async {
    final prefs = await ToolboxZenSandPrefsService.load();
    if (!mounted) return;
    setState(() {
      _backgroundId = prefs.backgroundId;
      _toolId = prefs.toolId;
      _brushSize = prefs.brushSize;
      _hapticsEnabled = prefs.hapticsEnabled;
      _guideEnabled = prefs.guidanceEnabled;
      _actions = prefs.actions.take(_maxCanvasActions).toList(growable: false);
      _redoStack = <ZenSandAction>[];
      _workingStroke = <Offset>[];
    });
  }

  void _persist() {
    unawaited(
      ToolboxZenSandPrefsService.save(
        ZenSandPrefsState(
          backgroundId: _backgroundId,
          toolId: _toolId,
          brushSize: _brushSize,
          hapticsEnabled: _hapticsEnabled,
          guidanceEnabled: _guideEnabled,
          actions: _actions.take(_maxCanvasActions).toList(growable: false),
        ),
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

  void _appendAction(ZenSandAction action) {
    final nextActions = <ZenSandAction>[..._actions, action];
    if (nextActions.length > _maxCanvasActions) {
      nextActions.removeRange(0, nextActions.length - _maxCanvasActions);
    }
    setState(() {
      _actions = nextActions;
      _redoStack = <ZenSandAction>[];
      _workingStroke = <Offset>[];
    });
    _persist();
  }

  void _selectTool(String id) {
    if (_toolId == id) return;
    _tapHaptic();
    setState(() {
      _toolId = id;
      _workingStroke = <Offset>[];
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
      _brushSize = value.clamp(14.0, 96.0);
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

  Offset _normalize(Offset local, Size size) {
    return Offset(
      (local.dx / size.width).clamp(0.0, 1.0),
      (local.dy / size.height).clamp(0.0, 1.0),
    );
  }

  void _handlePanStart(Offset local, Size size) {
    if (_tool.isPlacement) return;
    setState(() {
      _workingStroke = <Offset>[_normalize(local, size)];
    });
  }

  void _handlePanUpdate(Offset local, Size size) {
    if (_tool.isPlacement || _workingStroke.isEmpty) return;
    final point = _normalize(local, size);
    final minDistance =
        (_brushSize / math.max(size.width, size.height)).clamp(0.004, 0.04) *
        0.24;
    if ((_workingStroke.last - point).distance < minDistance) return;
    setState(() {
      _workingStroke = <Offset>[..._workingStroke, point];
    });
  }

  void _handlePanEnd() {
    if (_tool.isPlacement) return;
    if (_workingStroke.length < 2) {
      setState(() {
        _workingStroke = <Offset>[];
      });
      return;
    }
    _tapHaptic();
    _appendAction(
      ZenSandAction.stroke(
        toolId: _toolId,
        size: _brushSize,
        points: _workingStroke
            .map((point) => ZenSandPoint(point.dx, point.dy))
            .toList(growable: false),
      ),
    );
  }

  void _handlePanCancel() {
    if (_workingStroke.isEmpty) return;
    setState(() {
      _workingStroke = <Offset>[];
    });
  }

  void _placeStone(Offset local, Size size) {
    if (!_tool.isPlacement) return;
    final point = _normalize(local, size);
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
  }

  void _undo() {
    if (_actions.isEmpty) return;
    _tapHaptic();
    setState(() {
      final actions = <ZenSandAction>[..._actions];
      final removed = actions.removeLast();
      _actions = actions;
      _redoStack = <ZenSandAction>[removed, ..._redoStack];
      _workingStroke = <Offset>[];
    });
    _persist();
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _tapHaptic();
    setState(() {
      final redo = <ZenSandAction>[..._redoStack];
      final restored = redo.removeAt(0);
      _redoStack = redo;
      final actions = <ZenSandAction>[..._actions, restored];
      if (actions.length > _maxCanvasActions) {
        actions.removeRange(0, actions.length - _maxCanvasActions);
      }
      _actions = actions;
      _workingStroke = <Offset>[];
    });
    _persist();
  }

  void _smoothAll() {
    if (_strokeCount == 0) return;
    _impactHaptic();
    setState(() {
      _actions = _actions
          .where((action) => action.isStone)
          .toList(growable: false);
      _redoStack = <ZenSandAction>[];
      _workingStroke = <Offset>[];
    });
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
    _impactHaptic();
    setState(() {
      _actions = <ZenSandAction>[];
      _redoStack = <ZenSandAction>[];
      _workingStroke = <Offset>[];
    });
    _persist();
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ZenSectionCard(
                      title: _text('沙盘管理', 'Tray actions'),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _strokeCount == 0
                                  ? null
                                  : () {
                                      _smoothAll();
                                      setSheetState(() {});
                                    },
                              icon: const Icon(Icons.auto_fix_high_rounded),
                              label: Text(_text('一键抚平', 'Smooth all')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: _actions.isEmpty
                                  ? null
                                  : () async {
                                      await _clearAll();
                                      if (context.mounted) {
                                        setSheetState(() {});
                                      }
                                    },
                              icon: const Icon(Icons.delete_sweep_rounded),
                              label: Text(_text('清空画布', 'Clear tray')),
                            ),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF4EFE7),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: shellGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: <Widget>[
                _buildHeader(theme),
                const SizedBox(height: 14),
                _buildStats(theme),
                const SizedBox(height: 12),
                if (_guideEnabled) ...<Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _ZenGlassPill(
                      icon: _tool.icon,
                      accent: _tool.tint,
                      label: _tool.help(_isZh),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Expanded(child: _buildCanvas(theme)),
                const SizedBox(height: 14),
                _buildBottomDock(theme),
              ],
            ),
          ),
        ),
      ),
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
        ],
      ),
    );
  }

  Widget _buildCanvas(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final canvasHeight = math.min(maxHeight, width * 1.18);
        final canvasSize = Size(width, canvasHeight);

        return Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: width,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
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
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 26,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                _buildCanvasChrome(theme),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: _tool.isPlacement
                          ? (details) {
                              _placeStone(details.localPosition, canvasSize);
                            }
                          : null,
                      onPanStart: (details) {
                        _handlePanStart(details.localPosition, canvasSize);
                      },
                      onPanUpdate: (details) {
                        _handlePanUpdate(details.localPosition, canvasSize);
                      },
                      onPanCancel: _handlePanCancel,
                      onPanEnd: (_) => _handlePanEnd(),
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          RepaintBoundary(
                            child: CustomPaint(
                              painter: _ZenSurfacePainter(
                                background: _background,
                              ),
                              foregroundPainter: _ZenSandPainter(
                                background: _background,
                                actions: _actions,
                                currentStroke: _workingStroke,
                                currentToolId: _toolId,
                                currentBrushSize: _brushSize,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 12,
                            top: 12,
                            child: _ZenCanvasHint(
                              label: _tool.isPlacement
                                  ? _text('轻点安放景石', 'Tap to place stones')
                                  : _text('拖动在沙面上作画', 'Drag to draw on sand'),
                              accent: _tool.tint,
                            ),
                          ),
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: _ZenCanvasHint(
                              label: _tool.label(_isZh),
                              accent: _tool.tint,
                              trailing:
                                  '${_brushSize.round()} ${_text('号', 'px')}',
                            ),
                          ),
                        ],
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

  Widget _buildCanvasChrome(ThemeData theme) {
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
                maxLines: 2,
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

  Widget _buildBottomDock(ThemeData theme) {
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
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
                const SizedBox(width: 12),
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
            const SizedBox(height: 12),
            SizedBox(
              height: 58,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _tools.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  if (index == _tools.length) {
                    return _ZenCompactActionChip(
                      icon: Icons.delete_sweep_rounded,
                      label: _text('清空', 'Clear'),
                      accent: const Color(0xFF8B6651),
                      onTap: _actions.isEmpty ? null : _clearAll,
                    );
                  }
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
}

class _ZenSheetFrame extends StatelessWidget {
  const _ZenSheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F2EA),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: child,
        ),
      ),
    );
  }
}

class _ZenSheetHeader extends StatelessWidget {
  const _ZenSheetHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF271F18),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF655949),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _ZenSectionCard extends StatelessWidget {
  const _ZenSectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF281F16),
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ZenGlassPill extends StatelessWidget {
  const _ZenGlassPill({
    required this.icon,
    required this.accent,
    required this.label,
  });

  final IconData icon;
  final Color accent;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.82),
        border: Border.all(color: Colors.white.withValues(alpha: 0.68)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(icon, size: 16, color: accent),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF4E4338),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZenActionBadge extends StatelessWidget {
  const _ZenActionBadge({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.76),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF6A5B4C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF2C241E),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ZenQuickIconButton extends StatelessWidget {
  const _ZenQuickIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: const Color(0xFF2A241D)),
          ),
        ),
      ),
    );
  }
}

class _ZenDockButton extends StatelessWidget {
  const _ZenDockButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final foreground = enabled
        ? const Color(0xFF2C241E)
        : const Color(0xFFA49585);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: enabled ? onPressed : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 20, color: foreground),
            const SizedBox(height: 3),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZenCompactToolChip extends StatelessWidget {
  const _ZenCompactToolChip({
    required this.tool,
    required this.isZh,
    required this.selected,
    required this.onTap,
  });

  final _ZenToolSpec tool;
  final bool isZh;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: selected
            ? tool.tint.withValues(alpha: 0.16)
            : const Color(0xFFF3ECE3),
        border: Border.all(
          color: selected
              ? tool.tint.withValues(alpha: 0.42)
              : const Color(0xFFE2D8CC),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(tool.icon, size: 18, color: tool.tint),
              const SizedBox(width: 8),
              Text(
                tool.label(isZh),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2A2118),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZenCompactActionChip extends StatelessWidget {
  const _ZenCompactActionChip({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.42,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: enabled ? () => onTap!.call() : null,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: accent.withValues(alpha: 0.12),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 18, color: accent),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF402E24),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZenToolCard extends StatelessWidget {
  const _ZenToolCard({
    required this.tool,
    required this.isZh,
    required this.selected,
    required this.onTap,
  });

  final _ZenToolSpec tool;
  final bool isZh;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Material(
        color: selected ? tool.tint.withValues(alpha: 0.14) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? tool.tint.withValues(alpha: 0.48)
                    : const Color(0xFFE5DBD0),
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
                        color: tool.tint.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(tool.icon, color: tool.tint),
                    ),
                    const Spacer(),
                    if (selected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: tool.tint,
                        size: 22,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  tool.label(isZh),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2A2118),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tool.help(isZh),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B5D4F),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZenBackgroundCard extends StatelessWidget {
  const _ZenBackgroundCard({
    required this.background,
    required this.isZh,
    required this.selected,
    required this.onTap,
  });

  final _ZenBackgroundSpec background;
  final bool isZh;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? background.accent.withValues(alpha: 0.56)
                  : const Color(0xFFE3D8CC),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AspectRatio(
                aspectRatio: 1.1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CustomPaint(
                    painter: _ZenScenePreviewPainter(background: background),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      background.label(isZh),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2A2118),
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: background.accent,
                      size: 22,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                background.description(isZh),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B5D4F),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZenToggleRow extends StatelessWidget {
  const _ZenToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C241E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF655949),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch.adaptive(
          value: value,
          activeTrackColor: activeColor.withValues(alpha: 0.36),
          activeThumbColor: activeColor,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ZenCanvasHint extends StatelessWidget {
  const _ZenCanvasHint({
    required this.label,
    required this.accent,
    this.trailing,
  });

  final String label;
  final Color accent;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.78),
        border: Border.all(color: Colors.white.withValues(alpha: 0.66)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3D3228),
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: 8),
              Text(
                trailing!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF73614E),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ZenMiniMetric extends StatelessWidget {
  const _ZenMiniMetric({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.78),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF332920),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZenToolPreview extends StatelessWidget {
  const _ZenToolPreview({
    required this.background,
    required this.tool,
    required this.brushSize,
  });

  final _ZenBackgroundSpec background;
  final _ZenToolSpec tool;
  final double brushSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: CustomPaint(
          painter: _ZenToolPreviewPainter(
            background: background,
            tool: tool,
            brushSize: brushSize,
          ),
        ),
      ),
    );
  }
}

class _ZenScenePreviewPainter extends CustomPainter {
  const _ZenScenePreviewPainter({required this.background});

  final _ZenBackgroundSpec background;

  @override
  void paint(Canvas canvas, Size size) {
    _paintTraySurface(canvas, Offset.zero & size, background, cornerRadius: 18);
    final previewActions = <ZenSandAction>[
      ZenSandAction.stroke(
        toolId: 'rake',
        size: 26,
        points: const <ZenSandPoint>[
          ZenSandPoint(0.12, 0.22),
          ZenSandPoint(0.28, 0.30),
          ZenSandPoint(0.46, 0.52),
          ZenSandPoint(0.68, 0.60),
          ZenSandPoint(0.88, 0.74),
        ],
      ),
      ZenSandAction.stone(
        x: 0.72,
        y: 0.36,
        size: 28,
        rotation: 0.3,
        variant: background.patternSeed % 5,
      ),
    ];
    _paintSandActions(
      canvas,
      size,
      background: background,
      actions: previewActions,
      currentStroke: const <Offset>[],
      currentToolId: 'rake',
      currentBrushSize: 26,
    );
  }

  @override
  bool shouldRepaint(covariant _ZenScenePreviewPainter oldDelegate) {
    return oldDelegate.background != background;
  }
}

class _ZenToolPreviewPainter extends CustomPainter {
  const _ZenToolPreviewPainter({
    required this.background,
    required this.tool,
    required this.brushSize,
  });

  final _ZenBackgroundSpec background;
  final _ZenToolSpec tool;
  final double brushSize;

  @override
  void paint(Canvas canvas, Size size) {
    _paintTraySurface(canvas, Offset.zero & size, background, cornerRadius: 18);
    final List<ZenSandAction> actions;
    if (tool.isPlacement) {
      actions = <ZenSandAction>[
        ZenSandAction.stone(
          x: 0.36,
          y: 0.52,
          size: brushSize,
          rotation: -0.28,
          variant: 2,
        ),
        ZenSandAction.stone(
          x: 0.68,
          y: 0.42,
          size: brushSize * 0.78,
          rotation: 0.22,
          variant: 5,
        ),
      ];
    } else {
      actions = <ZenSandAction>[
        ZenSandAction.stroke(
          toolId: tool.id,
          size: brushSize,
          points: const <ZenSandPoint>[
            ZenSandPoint(0.12, 0.62),
            ZenSandPoint(0.28, 0.48),
            ZenSandPoint(0.48, 0.58),
            ZenSandPoint(0.72, 0.36),
            ZenSandPoint(0.90, 0.44),
          ],
        ),
      ];
    }
    _paintSandActions(
      canvas,
      size,
      background: background,
      actions: actions,
      currentStroke: const <Offset>[],
      currentToolId: tool.id,
      currentBrushSize: brushSize,
    );
  }

  @override
  bool shouldRepaint(covariant _ZenToolPreviewPainter oldDelegate) {
    return oldDelegate.background != background ||
        oldDelegate.tool != tool ||
        oldDelegate.brushSize != brushSize;
  }
}

class _ZenSurfacePainter extends CustomPainter {
  const _ZenSurfacePainter({required this.background});

  final _ZenBackgroundSpec background;

  @override
  void paint(Canvas canvas, Size size) {
    _paintTraySurface(canvas, Offset.zero & size, background);
  }

  @override
  bool shouldRepaint(covariant _ZenSurfacePainter oldDelegate) {
    return oldDelegate.background != background;
  }
}

class _ZenSandPainter extends CustomPainter {
  const _ZenSandPainter({
    required this.background,
    required this.actions,
    required this.currentStroke,
    required this.currentToolId,
    required this.currentBrushSize,
  });

  final _ZenBackgroundSpec background;
  final List<ZenSandAction> actions;
  final List<Offset> currentStroke;
  final String currentToolId;
  final double currentBrushSize;

  @override
  void paint(Canvas canvas, Size size) {
    _paintSandActions(
      canvas,
      size,
      background: background,
      actions: actions,
      currentStroke: currentStroke,
      currentToolId: currentToolId,
      currentBrushSize: currentBrushSize,
    );
  }

  @override
  bool shouldRepaint(covariant _ZenSandPainter oldDelegate) {
    return oldDelegate.background != background ||
        oldDelegate.actions != actions ||
        oldDelegate.currentStroke != currentStroke ||
        oldDelegate.currentToolId != currentToolId ||
        oldDelegate.currentBrushSize != currentBrushSize;
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
  required bool isPreview,
}) {
  final points = normalizedPoints
      .map((point) => Offset(point.dx * size.width, point.dy * size.height))
      .toList(growable: false);
  if (points.length < 2) return;

  final alphaScale = isPreview ? 0.72 : 1.0;

  switch (toolId) {
    case 'rake':
      _paintRakeStroke(canvas, points, brushSize, background, alphaScale);
      break;
    case 'finger':
      _paintFingerStroke(canvas, points, brushSize, background, alphaScale);
      break;
    case 'wave':
      _paintWaveStroke(canvas, points, brushSize, background, alphaScale);
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

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const String zenSandDefaultBackgroundId = 'sunlit_garden';
const String zenSandDefaultToolId = 'rake';
const double zenSandDefaultBrushSize = 34.0;

const int _maxSavedActions = 220;
const int _maxStrokePoints = 260;

class ZenSandPoint {
  const ZenSandPoint(this.x, this.y);

  final double x;
  final double y;

  ZenSandPoint normalized() {
    return ZenSandPoint(
      x.clamp(0.0, 1.0).toDouble(),
      y.clamp(0.0, 1.0).toDouble(),
    );
  }

  Map<String, Object?> toJson() {
    final point = normalized();
    return <String, Object?>{'x': point.x, 'y': point.y};
  }

  static ZenSandPoint? fromJsonValue(Object? value) {
    if (value is! Map) {
      return null;
    }
    final map = value.cast<Object?, Object?>();
    return ZenSandPoint(
      ((map['x'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0),
      ((map['y'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0),
    );
  }
}

class ZenSandAction {
  const ZenSandAction._({
    required this.kind,
    required this.toolId,
    required this.size,
    required this.points,
    required this.x,
    required this.y,
    required this.rotation,
    required this.variant,
  });

  factory ZenSandAction.stroke({
    required String toolId,
    required double size,
    required List<ZenSandPoint> points,
  }) {
    final normalizedPoints = points
        .take(_maxStrokePoints)
        .map((point) => point.normalized())
        .toList(growable: false);
    return ZenSandAction._(
      kind: 'stroke',
      toolId: toolId.trim().isEmpty ? zenSandDefaultToolId : toolId.trim(),
      size: size.clamp(14.0, 96.0),
      points: normalizedPoints,
      x: 0.0,
      y: 0.0,
      rotation: 0.0,
      variant: 0,
    );
  }

  factory ZenSandAction.stone({
    required double x,
    required double y,
    required double size,
    required double rotation,
    required int variant,
  }) {
    return ZenSandAction._(
      kind: 'stone',
      toolId: 'stone',
      size: size.clamp(18.0, 96.0),
      points: const <ZenSandPoint>[],
      x: x.clamp(0.0, 1.0),
      y: y.clamp(0.0, 1.0),
      rotation: rotation.clamp(-1.2, 1.2),
      variant: variant.clamp(0, 7),
    );
  }

  final String kind;
  final String toolId;
  final double size;
  final List<ZenSandPoint> points;
  final double x;
  final double y;
  final double rotation;
  final int variant;

  bool get isStroke => kind == 'stroke';
  bool get isStone => kind == 'stone';

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'kind': kind,
      'tool_id': toolId,
      'size': size,
      'points': points.map((point) => point.toJson()).toList(growable: false),
      'x': x,
      'y': y,
      'rotation': rotation,
      'variant': variant,
    };
  }

  static ZenSandAction? fromJsonValue(Object? value) {
    if (value is! Map) {
      return null;
    }
    final map = value.cast<Object?, Object?>();
    final kind = '${map['kind'] ?? 'stroke'}'.trim().toLowerCase();
    if (kind == 'stone') {
      return ZenSandAction.stone(
        x: ((map['x'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0),
        y: ((map['y'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0),
        size: ((map['size'] as num?)?.toDouble() ?? zenSandDefaultBrushSize)
            .clamp(18.0, 96.0),
        rotation: ((map['rotation'] as num?)?.toDouble() ?? 0.0).clamp(
          -1.2,
          1.2,
        ),
        variant: ((map['variant'] as num?)?.toInt() ?? 0).clamp(0, 7),
      );
    }

    final rawPoints = map['points'];
    if (rawPoints is! List) {
      return null;
    }
    final points = rawPoints
        .map(ZenSandPoint.fromJsonValue)
        .whereType<ZenSandPoint>()
        .take(_maxStrokePoints)
        .toList(growable: false);
    if (points.length < 2) {
      return null;
    }
    return ZenSandAction.stroke(
      toolId: '${map['tool_id'] ?? zenSandDefaultToolId}',
      size: ((map['size'] as num?)?.toDouble() ?? zenSandDefaultBrushSize)
          .clamp(14.0, 96.0),
      points: points,
    );
  }
}

class ZenSandPrefsState {
  const ZenSandPrefsState({
    this.backgroundId = zenSandDefaultBackgroundId,
    this.toolId = zenSandDefaultToolId,
    this.brushSize = zenSandDefaultBrushSize,
    this.hapticsEnabled = true,
    this.guidanceEnabled = true,
    this.actions = const <ZenSandAction>[],
  });

  final String backgroundId;
  final String toolId;
  final double brushSize;
  final bool hapticsEnabled;
  final bool guidanceEnabled;
  final List<ZenSandAction> actions;

  ZenSandPrefsState copyWith({
    String? backgroundId,
    String? toolId,
    double? brushSize,
    bool? hapticsEnabled,
    bool? guidanceEnabled,
    List<ZenSandAction>? actions,
  }) {
    return ZenSandPrefsState(
      backgroundId: backgroundId ?? this.backgroundId,
      toolId: toolId ?? this.toolId,
      brushSize: brushSize ?? this.brushSize,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      guidanceEnabled: guidanceEnabled ?? this.guidanceEnabled,
      actions: actions ?? this.actions,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'background_id': backgroundId,
      'tool_id': toolId,
      'brush_size': brushSize,
      'haptics_enabled': hapticsEnabled,
      'guidance_enabled': guidanceEnabled,
      'actions': actions
          .take(_maxSavedActions)
          .map((action) => action.toJson())
          .toList(growable: false),
    };
  }

  static ZenSandPrefsState fromJsonValue(Object? value) {
    if (value is! Map) {
      return const ZenSandPrefsState();
    }
    final map = value.cast<Object?, Object?>();
    final rawActions = map['actions'];
    final actions = rawActions is List
        ? rawActions
              .map(ZenSandAction.fromJsonValue)
              .whereType<ZenSandAction>()
              .take(_maxSavedActions)
              .toList(growable: false)
        : const <ZenSandAction>[];
    return ZenSandPrefsState(
      backgroundId:
          '${map['background_id'] ?? zenSandDefaultBackgroundId}'.trim().isEmpty
          ? zenSandDefaultBackgroundId
          : '${map['background_id']}'.trim(),
      toolId: '${map['tool_id'] ?? zenSandDefaultToolId}'.trim().isEmpty
          ? zenSandDefaultToolId
          : '${map['tool_id']}'.trim(),
      brushSize:
          ((map['brush_size'] as num?)?.toDouble() ?? zenSandDefaultBrushSize)
              .clamp(14.0, 96.0),
      hapticsEnabled: map['haptics_enabled'] as bool? ?? true,
      guidanceEnabled: map['guidance_enabled'] as bool? ?? true,
      actions: actions,
    );
  }
}

class ToolboxZenSandPrefsService {
  const ToolboxZenSandPrefsService._();

  static Future<File> _resolveFile() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(supportDir.path, 'toolbox'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(p.join(dir.path, 'zen_sand_prefs.json'));
  }

  static Future<ZenSandPrefsState> load() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) {
        return const ZenSandPrefsState();
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return const ZenSandPrefsState();
      }
      return ZenSandPrefsState.fromJsonValue(jsonDecode(raw));
    } catch (_) {
      return const ZenSandPrefsState();
    }
  }

  static Future<void> save(ZenSandPrefsState state) async {
    try {
      final file = await _resolveFile();
      await file.writeAsString(jsonEncode(state.toJson()), flush: true);
    } catch (_) {}
  }
}

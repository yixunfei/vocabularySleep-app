part of 'toolbox_zen_sand_tool.dart';

const int _maxCanvasActions = 220;
const double _maxViewportScale = 3.6;

enum _ZenPatternKind { parallel, tidal, orbital, contour }

enum _ZenGestureMode { idle, draw, transform }

enum _ZenDrawerSection { tools, brush, experience, gestures }

enum _ZenRitualApplyMode { append, replace }

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
    this.supportsColor = false,
  });

  final String id;
  final IconData icon;
  final String labelZh;
  final String labelEn;
  final String helpZh;
  final String helpEn;
  final Color tint;
  final bool isPlacement;
  final bool supportsColor;

  String label(bool isZh) => isZh ? labelZh : labelEn;

  String help(bool isZh) => isZh ? helpZh : helpEn;
}

class _ZenColorSpec {
  const _ZenColorSpec({
    required this.value,
    required this.labelZh,
    required this.labelEn,
  });

  final int value;
  final String labelZh;
  final String labelEn;

  Color get color => Color(value);

  String label(bool isZh) => isZh ? labelZh : labelEn;
}

class _ZenRitualPresetSpec {
  const _ZenRitualPresetSpec({
    required this.id,
    required this.icon,
    required this.titleZh,
    required this.titleEn,
    required this.descriptionZh,
    required this.descriptionEn,
    required this.backgroundId,
    required this.toolId,
    required this.brushSize,
    required this.accent,
    this.colorValue,
  });

  final String id;
  final IconData icon;
  final String titleZh;
  final String titleEn;
  final String descriptionZh;
  final String descriptionEn;
  final String backgroundId;
  final String toolId;
  final double brushSize;
  final Color accent;
  final int? colorValue;

  String title(bool isZh) => isZh ? titleZh : titleEn;

  String description(bool isZh) => isZh ? descriptionZh : descriptionEn;
}

final Map<String, _ZenBackgroundSpec> _backgroundById =
    <String, _ZenBackgroundSpec>{
      for (final background in _backgrounds) background.id: background,
    };

final Map<String, _ZenToolSpec> _toolById = <String, _ZenToolSpec>{
  for (final tool in _tools) tool.id: tool,
};

final Map<int, _ZenColorSpec> _colorByValue = <int, _ZenColorSpec>{
  for (final color in _paintPalette) color.value: color,
};

final Map<String, _ZenRitualPresetSpec> _ritualById =
    <String, _ZenRitualPresetSpec>{
      for (final preset in _ritualPresets) preset.id: preset,
    };

ZenSandAction _ritualStroke({
  required String toolId,
  required double size,
  required List<Offset> points,
  int? colorValue,
}) {
  return ZenSandAction.stroke(
    toolId: toolId,
    size: size,
    colorValue: colorValue,
    points: points
        .map((point) => ZenSandPoint(point.dx, point.dy))
        .toList(growable: false),
  );
}

List<ZenSandAction> _buildZenRitualActions(String presetId) {
  switch (presetId) {
    case 'breath_tides':
      return <ZenSandAction>[
        _ritualStroke(
          toolId: 'wave',
          size: 24,
          points: const <Offset>[
            Offset(0.08, 0.24),
            Offset(0.26, 0.28),
            Offset(0.44, 0.22),
            Offset(0.62, 0.26),
            Offset(0.88, 0.22),
          ],
        ),
        _ritualStroke(
          toolId: 'wave',
          size: 22,
          points: const <Offset>[
            Offset(0.1, 0.4),
            Offset(0.28, 0.44),
            Offset(0.46, 0.38),
            Offset(0.66, 0.42),
            Offset(0.9, 0.36),
          ],
        ),
        _ritualStroke(
          toolId: 'wave',
          size: 22,
          points: const <Offset>[
            Offset(0.12, 0.58),
            Offset(0.32, 0.62),
            Offset(0.5, 0.55),
            Offset(0.7, 0.6),
            Offset(0.9, 0.54),
          ],
        ),
        _ritualStroke(
          toolId: 'finger',
          size: 20,
          points: const <Offset>[
            Offset(0.22, 0.16),
            Offset(0.34, 0.28),
            Offset(0.48, 0.44),
            Offset(0.56, 0.58),
            Offset(0.64, 0.7),
          ],
        ),
        ZenSandAction.stone(
          x: 0.76,
          y: 0.3,
          size: 28,
          rotation: 0.24,
          variant: 2,
        ),
      ];
    case 'stone_balance':
      return <ZenSandAction>[
        _ritualStroke(
          toolId: 'rake',
          size: 26,
          points: const <Offset>[
            Offset(0.12, 0.2),
            Offset(0.34, 0.24),
            Offset(0.56, 0.22),
            Offset(0.84, 0.18),
          ],
        ),
        _ritualStroke(
          toolId: 'rake',
          size: 24,
          points: const <Offset>[
            Offset(0.12, 0.62),
            Offset(0.34, 0.58),
            Offset(0.58, 0.6),
            Offset(0.86, 0.66),
          ],
        ),
        _ritualStroke(
          toolId: 'wave',
          size: 18,
          points: const <Offset>[
            Offset(0.26, 0.34),
            Offset(0.34, 0.38),
            Offset(0.44, 0.36),
            Offset(0.54, 0.4),
            Offset(0.66, 0.36),
          ],
        ),
        ZenSandAction.stone(
          x: 0.3,
          y: 0.48,
          size: 30,
          rotation: -0.2,
          variant: 1,
        ),
        ZenSandAction.stone(
          x: 0.56,
          y: 0.34,
          size: 24,
          rotation: 0.18,
          variant: 5,
        ),
        ZenSandAction.stone(
          x: 0.72,
          y: 0.58,
          size: 34,
          rotation: -0.12,
          variant: 7,
        ),
      ];
    case 'water_path':
      return <ZenSandAction>[
        _ritualStroke(
          toolId: 'water',
          size: 28,
          colorValue: 0xFF3A7CA5,
          points: const <Offset>[
            Offset(0.18, 0.16),
            Offset(0.32, 0.26),
            Offset(0.48, 0.42),
            Offset(0.6, 0.58),
            Offset(0.72, 0.74),
          ],
        ),
        _ritualStroke(
          toolId: 'gravel',
          size: 22,
          points: const <Offset>[
            Offset(0.12, 0.26),
            Offset(0.28, 0.34),
            Offset(0.42, 0.5),
            Offset(0.54, 0.66),
            Offset(0.66, 0.82),
          ],
        ),
        _ritualStroke(
          toolId: 'gravel',
          size: 18,
          points: const <Offset>[
            Offset(0.3, 0.12),
            Offset(0.46, 0.2),
            Offset(0.6, 0.34),
            Offset(0.76, 0.48),
            Offset(0.88, 0.64),
          ],
        ),
        ZenSandAction.stone(
          x: 0.74,
          y: 0.24,
          size: 24,
          rotation: 0.18,
          variant: 3,
        ),
      ];
    case 'focus_furrows':
      return <ZenSandAction>[
        _ritualStroke(
          toolId: 'rake',
          size: 26,
          points: const <Offset>[
            Offset(0.18, 0.14),
            Offset(0.22, 0.34),
            Offset(0.18, 0.56),
            Offset(0.22, 0.84),
          ],
        ),
        _ritualStroke(
          toolId: 'rake',
          size: 24,
          points: const <Offset>[
            Offset(0.46, 0.12),
            Offset(0.5, 0.32),
            Offset(0.48, 0.56),
            Offset(0.52, 0.84),
          ],
        ),
        _ritualStroke(
          toolId: 'rake',
          size: 26,
          points: const <Offset>[
            Offset(0.74, 0.14),
            Offset(0.78, 0.36),
            Offset(0.74, 0.58),
            Offset(0.78, 0.86),
          ],
        ),
        _ritualStroke(
          toolId: 'finger',
          size: 18,
          points: const <Offset>[
            Offset(0.32, 0.22),
            Offset(0.44, 0.38),
            Offset(0.56, 0.52),
            Offset(0.68, 0.66),
          ],
        ),
        ZenSandAction.stone(
          x: 0.52,
          y: 0.42,
          size: 24,
          rotation: 0.12,
          variant: 4,
        ),
      ];
    default:
      return const <ZenSandAction>[];
  }
}

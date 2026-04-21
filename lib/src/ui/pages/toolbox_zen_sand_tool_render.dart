part of 'toolbox_zen_sand_tool.dart';

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
      currentColorValue: null,
    );
  }

  @override
  bool shouldRepaint(covariant _ZenScenePreviewPainter oldDelegate) {
    return oldDelegate.background != background;
  }
}

class _ZenRitualPreviewPainter extends CustomPainter {
  const _ZenRitualPreviewPainter({required this.preset});

  final _ZenRitualPresetSpec preset;

  @override
  void paint(Canvas canvas, Size size) {
    final background =
        _backgroundById[preset.backgroundId] ?? _backgrounds.first;
    _paintTraySurface(canvas, Offset.zero & size, background, cornerRadius: 18);
    _paintSandActions(
      canvas,
      size,
      background: background,
      actions: _buildZenRitualActions(preset.id),
      currentStroke: const <Offset>[],
      currentToolId: preset.toolId,
      currentBrushSize: preset.brushSize,
      currentColorValue: preset.colorValue,
    );
  }

  @override
  bool shouldRepaint(covariant _ZenRitualPreviewPainter oldDelegate) {
    return oldDelegate.preset != preset;
  }
}

class _ZenToolPreviewPainter extends CustomPainter {
  const _ZenToolPreviewPainter({
    required this.background,
    required this.tool,
    required this.brushSize,
    this.colorValue,
  });

  final _ZenBackgroundSpec background;
  final _ZenToolSpec tool;
  final double brushSize;
  final int? colorValue;

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
          colorValue: tool.supportsColor ? colorValue : null,
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
      currentColorValue: tool.supportsColor ? colorValue : null,
    );
  }

  @override
  bool shouldRepaint(covariant _ZenToolPreviewPainter oldDelegate) {
    return oldDelegate.background != background ||
        oldDelegate.tool != tool ||
        oldDelegate.brushSize != brushSize ||
        oldDelegate.colorValue != colorValue;
  }
}

class _ZenSurfacePainter extends CustomPainter {
  const _ZenSurfacePainter({
    required this.background,
    required this.viewportScale,
    required this.viewportOffset,
  });

  final _ZenBackgroundSpec background;
  final double viewportScale;
  final Offset viewportOffset;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(viewportOffset.dx, viewportOffset.dy);
    canvas.scale(viewportScale);
    _paintTraySurface(canvas, Offset.zero & size, background);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ZenSurfacePainter oldDelegate) {
    return oldDelegate.background != background ||
        oldDelegate.viewportScale != viewportScale ||
        oldDelegate.viewportOffset != viewportOffset;
  }
}

class _ZenSandPainter extends CustomPainter {
  const _ZenSandPainter({
    required this.background,
    required this.actions,
    required this.currentStroke,
    required this.currentToolId,
    required this.currentBrushSize,
    required this.currentColorValue,
    required this.viewportScale,
    required this.viewportOffset,
  });

  final _ZenBackgroundSpec background;
  final List<ZenSandAction> actions;
  final List<Offset> currentStroke;
  final String currentToolId;
  final double currentBrushSize;
  final int? currentColorValue;
  final double viewportScale;
  final Offset viewportOffset;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(viewportOffset.dx, viewportOffset.dy);
    canvas.scale(viewportScale);
    _paintSandActions(
      canvas,
      size,
      background: background,
      actions: actions,
      currentStroke: currentStroke,
      currentToolId: currentToolId,
      currentBrushSize: currentBrushSize,
      currentColorValue: currentColorValue,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ZenSandPainter oldDelegate) {
    return oldDelegate.background != background ||
        oldDelegate.actions != actions ||
        oldDelegate.currentStroke != currentStroke ||
        oldDelegate.currentToolId != currentToolId ||
        oldDelegate.currentBrushSize != currentBrushSize ||
        oldDelegate.currentColorValue != currentColorValue ||
        oldDelegate.viewportScale != viewportScale ||
        oldDelegate.viewportOffset != viewportOffset;
  }
}

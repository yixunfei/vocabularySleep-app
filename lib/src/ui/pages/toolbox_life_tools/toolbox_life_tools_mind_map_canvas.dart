part of '../toolbox_life_tools.dart';

class _MindMapNodePositionChange {
  const _MindMapNodePositionChange({
    required this.nodeId,
    required this.anchor,
  });

  final String nodeId;
  final Offset anchor;
}

Offset _clampMindMapAnchor(Offset anchor) {
  return Offset(
    anchor.dx.clamp(0.04, 0.96).toDouble(),
    anchor.dy.clamp(0.06, 0.94).toDouble(),
  );
}

class _MindMapCanvas extends StatelessWidget {
  const _MindMapCanvas({
    required this.nodes,
    required this.selectedId,
    required this.onSelect,
    this.boundaryKey,
    this.canvasKey = const ValueKey<String>('life_mind_map_canvas'),
    this.anchors = const <String, Offset>{},
    this.onMoveNode,
    this.snapToGrid = false,
    this.showGrid = false,
    this.forceManualLayout = false,
    this.gridSize = 24,
  });

  final GlobalKey? boundaryKey;
  final Key canvasKey;
  final List<_MindMapNode> nodes;
  final Map<String, Offset> anchors;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final ValueChanged<_MindMapNodePositionChange>? onMoveNode;
  final bool snapToGrid;
  final bool showGrid;
  final bool forceManualLayout;
  final double gridSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 340.0;
        final finiteHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : null;
        final manualHeight = finiteHeight ?? math.max(300.0, width * 0.72);
        final useManualLayout = forceManualLayout || anchors.isNotEmpty;
        final layout = _MindMapLayout.compute(
          nodes,
          width,
          anchors: anchors,
          forceManual: useManualLayout,
          preferredHeight: useManualLayout ? manualHeight : null,
        );
        final canvasSize = Size(width, layout.height);
        return RepaintBoundary(
          key: boundaryKey,
          child: Container(
            key: canvasKey,
            width: double.infinity,
            height: layout.height,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: <Widget>[
                  if (showGrid)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _MindMapGridPainter(
                          colorScheme: scheme,
                          gridSize: gridSize,
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MindMapLinksPainter(
                        nodes: nodes,
                        rects: layout.rects,
                        colorScheme: scheme,
                      ),
                    ),
                  ),
                  for (final node in nodes)
                    if (layout.rects[node.id] != null)
                      _MindMapNodeChip(
                        key: ValueKey<String>('life_mind_map_node_${node.id}'),
                        rect: layout.rects[node.id]!,
                        node: node,
                        selected: node.id == selectedId,
                        onTap: () => onSelect(node.id),
                        onDragCenter: onMoveNode == null
                            ? null
                            : (center) {
                                final anchor = _anchorFromCenter(
                                  rawCenter: center,
                                  nodeSize: layout.rects[node.id]!.size,
                                  canvasSize: canvasSize,
                                );
                                onMoveNode!(
                                  _MindMapNodePositionChange(
                                    nodeId: node.id,
                                    anchor: anchor,
                                  ),
                                );
                              },
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Offset _anchorFromCenter({
    required Size canvasSize,
    required Size nodeSize,
    required Offset rawCenter,
  }) {
    var center = _clampCenter(
      rawCenter,
      canvasSize: canvasSize,
      nodeSize: nodeSize,
    );
    if (snapToGrid && gridSize > 0) {
      center = _clampCenter(
        Offset(
          (center.dx / gridSize).round() * gridSize,
          (center.dy / gridSize).round() * gridSize,
        ),
        canvasSize: canvasSize,
        nodeSize: nodeSize,
      );
    }
    return _clampMindMapAnchor(
      Offset(center.dx / canvasSize.width, center.dy / canvasSize.height),
    );
  }

  Offset _clampCenter(
    Offset center, {
    required Size canvasSize,
    required Size nodeSize,
  }) {
    final halfWidth = nodeSize.width / 2;
    final halfHeight = nodeSize.height / 2;
    return Offset(
      center.dx
          .clamp(halfWidth + 8, canvasSize.width - halfWidth - 8)
          .toDouble(),
      center.dy
          .clamp(halfHeight + 8, canvasSize.height - halfHeight - 8)
          .toDouble(),
    );
  }
}

class _MindMapNodeChip extends StatefulWidget {
  const _MindMapNodeChip({
    super.key,
    required this.rect,
    required this.node,
    required this.selected,
    required this.onTap,
    this.onDragCenter,
  });

  final Rect rect;
  final _MindMapNode node;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<Offset>? onDragCenter;

  @override
  State<_MindMapNodeChip> createState() => _MindMapNodeChipState();
}

class _MindMapNodeChipState extends State<_MindMapNodeChip> {
  Offset? _dragStartCenter;
  Offset _dragDelta = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = widget.node.color.computeLuminance() > 0.45
        ? Colors.black
        : Colors.white;
    return Positioned(
      left: widget.rect.left,
      top: widget.rect.top,
      width: widget.rect.width,
      height: widget.rect.height,
      child: Semantics(
        button: true,
        selected: widget.selected,
        label: widget.node.title,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            onPanStart: widget.onDragCenter == null
                ? null
                : (_) {
                    _dragStartCenter = widget.rect.center;
                    _dragDelta = Offset.zero;
                    widget.onTap();
                  },
            onPanUpdate: widget.onDragCenter == null
                ? null
                : (details) {
                    final start = _dragStartCenter ?? widget.rect.center;
                    _dragDelta += details.delta;
                    widget.onDragCenter!(start + _dragDelta);
                  },
            onPanEnd: widget.onDragCenter == null ? null : (_) => _clearDrag(),
            onPanCancel: widget.onDragCenter == null ? null : _clearDrag,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: widget.node.color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.selected ? scheme.onSurface : Colors.white,
                  width: widget.selected ? 2.2 : 1.0,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: widget.node.color.withValues(
                      alpha: widget.selected ? 0.32 : 0.16,
                    ),
                    blurRadius: widget.selected ? 14 : 8,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.node.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _clearDrag() {
    _dragStartCenter = null;
    _dragDelta = Offset.zero;
  }
}

class _MindMapLayout {
  const _MindMapLayout({required this.rects, required this.height});

  static const double _nodeHeight = 48;

  final Map<String, Rect> rects;
  final double height;

  static _MindMapLayout compute(
    List<_MindMapNode> nodes,
    double width, {
    Map<String, Offset> anchors = const <String, Offset>{},
    bool forceManual = false,
    double? preferredHeight,
  }) {
    final autoLayout = _computeAuto(nodes, width);
    if (!forceManual && anchors.isEmpty) {
      return autoLayout;
    }

    final height = math.max(300.0, preferredHeight ?? autoLayout.height);
    final rects = <String, Rect>{};
    for (final node in nodes) {
      final autoRect = autoLayout.rects[node.id];
      final autoAnchor = autoRect == null
          ? const Offset(0.5, 0.5)
          : _clampMindMapAnchor(
              Offset(
                autoRect.center.dx / width,
                autoRect.center.dy / autoLayout.height,
              ),
            );
      final anchor = _clampMindMapAnchor(anchors[node.id] ?? autoAnchor);
      final nodeWidth = autoRect?.width ?? _nodeWidthFor(width);
      final rect = Rect.fromCenter(
        center: Offset(anchor.dx * width, anchor.dy * height),
        width: nodeWidth,
        height: _nodeHeight,
      );
      rects[node.id] = _clampRect(rect, width, height);
    }
    return _MindMapLayout(rects: rects, height: height);
  }

  static _MindMapLayout _computeAuto(List<_MindMapNode> nodes, double width) {
    final nodeWidth = _nodeWidthFor(width);
    const horizontalGap = 8.0;
    const verticalGap = 26.0;
    const levelGap = 38.0;
    const leftPad = 12.0;
    final usableWidth = math.max(nodeWidth, width - leftPad * 2);
    final perRow = math.max(
      1,
      ((usableWidth + horizontalGap) / (nodeWidth + horizontalGap)).floor(),
    );

    final depths = <String, int>{};
    int depthOf(_MindMapNode node) {
      final cached = depths[node.id];
      if (cached != null) {
        return cached;
      }
      if (node.parentId == null) {
        depths[node.id] = 0;
        return 0;
      }
      _MindMapNode? parent;
      for (final item in nodes) {
        if (item.id == node.parentId) {
          parent = item;
          break;
        }
      }
      final depth = parent == null ? 1 : depthOf(parent) + 1;
      depths[node.id] = depth;
      return depth;
    }

    final byDepth = <int, List<_MindMapNode>>{};
    for (final node in nodes) {
      byDepth.putIfAbsent(depthOf(node), () => <_MindMapNode>[]).add(node);
    }

    final rects = <String, Rect>{};
    var y = 28.0;
    final levels = byDepth.keys.toList()..sort();
    for (final depth in levels) {
      final levelNodes = byDepth[depth]!;
      final rows = (levelNodes.length / perRow).ceil();
      for (var index = 0; index < levelNodes.length; index += 1) {
        final row = index ~/ perRow;
        final col = index % perRow;
        final rowStart = row * perRow;
        final rowCount = math.min(perRow, levelNodes.length - rowStart);
        final rowWidth = rowCount * nodeWidth + (rowCount - 1) * horizontalGap;
        final startX = leftPad + (usableWidth - rowWidth) / 2;
        final x = startX + col * (nodeWidth + horizontalGap);
        rects[levelNodes[index].id] = Rect.fromLTWH(
          x,
          y + row * (_nodeHeight + verticalGap),
          nodeWidth,
          _nodeHeight,
        );
      }
      y += rows * _nodeHeight + math.max(0, rows - 1) * verticalGap + levelGap;
    }

    return _MindMapLayout(rects: rects, height: math.max(260.0, y + 8));
  }

  static double _nodeWidthFor(double width) {
    return math.min(128.0, math.max(96.0, width * 0.32));
  }

  static Rect _clampRect(Rect rect, double width, double height) {
    const inset = 8.0;
    final maxLeft = math.max(inset, width - rect.width - inset);
    final maxTop = math.max(inset, height - rect.height - inset);
    final left = rect.left.clamp(inset, maxLeft).toDouble();
    final top = rect.top.clamp(inset, maxTop).toDouble();
    return Rect.fromLTWH(left, top, rect.width, rect.height);
  }
}

class _MindMapGridPainter extends CustomPainter {
  const _MindMapGridPainter({
    required this.colorScheme,
    required this.gridSize,
  });

  final ColorScheme colorScheme;
  final double gridSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (gridSize <= 0) {
      return;
    }
    final paint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.22)
      ..strokeWidth = 1;
    for (var x = gridSize; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = gridSize; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MindMapGridPainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme ||
        oldDelegate.gridSize != gridSize;
  }
}

class _MindMapLinksPainter extends CustomPainter {
  const _MindMapLinksPainter({
    required this.nodes,
    required this.rects,
    required this.colorScheme,
  });

  final List<_MindMapNode> nodes;
  final Map<String, Rect> rects;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = colorScheme.outline.withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final node in nodes) {
      final parentId = node.parentId;
      if (parentId == null) {
        continue;
      }
      final parent = rects[parentId];
      final child = rects[node.id];
      if (parent == null || child == null) {
        continue;
      }
      final start = Offset(parent.center.dx, parent.bottom);
      final end = Offset(child.center.dx, child.top);
      final midY = (start.dy + end.dy) / 2;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(start.dx, midY, end.dx, midY, end.dx, end.dy);
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MindMapLinksPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.rects != rects ||
        oldDelegate.colorScheme != colorScheme;
  }
}

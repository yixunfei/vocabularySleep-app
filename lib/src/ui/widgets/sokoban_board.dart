import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../games/sokoban/sokoban_level.dart';

/// A single repaint boundary for the Sokoban board.
///
/// The board deliberately owns only presentation and pointer interpretation;
/// game rules remain in the page state and can therefore be tested separately.
class SokobanBoard extends StatelessWidget {
  const SokobanBoard({
    super.key,
    required this.level,
    required this.boxes,
    required this.player,
    required this.showRoute,
    required this.remainingSolution,
    required this.onMove,
  });

  final SokobanLevel level;
  final List<int> boxes;
  final int player;
  final bool showRoute;
  final List<SokobanPush> remainingSolution;
  final ValueChanged<SokobanDirection> onMove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 440.0;
        final boardSize = math.min(460.0, math.max(1.0, available));
        return Center(
          child: RepaintBoundary(
            child: SizedBox.square(
              dimension: boardSize,
              child: _SokobanBoardGestureSurface(
                level: level,
                boxes: boxes,
                player: player,
                showRoute: showRoute,
                remainingSolution: remainingSolution,
                colorScheme: colorScheme,
                onMove: onMove,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SokobanBoardGestureSurface extends StatefulWidget {
  const _SokobanBoardGestureSurface({
    required this.level,
    required this.boxes,
    required this.player,
    required this.showRoute,
    required this.remainingSolution,
    required this.colorScheme,
    required this.onMove,
  });

  final SokobanLevel level;
  final List<int> boxes;
  final int player;
  final bool showRoute;
  final List<SokobanPush> remainingSolution;
  final ColorScheme colorScheme;
  final ValueChanged<SokobanDirection> onMove;

  @override
  State<_SokobanBoardGestureSurface> createState() =>
      _SokobanBoardGestureSurfaceState();
}

class _SokobanBoardGestureSurfaceState
    extends State<_SokobanBoardGestureSurface> {
  Offset? _dragStart;
  Offset? _dragEnd;

  void _handleTap(Offset position, Size size) {
    final cell = _cellAt(position, size);
    if (cell == null) {
      return;
    }
    final playerRow = widget.player ~/ widget.level.columns;
    final playerColumn = widget.player % widget.level.columns;
    final rowDelta = cell.$1 - playerRow;
    final columnDelta = cell.$2 - playerColumn;
    if (rowDelta.abs() + columnDelta.abs() != 1) {
      return;
    }
    widget.onMove(_directionForDelta(rowDelta, columnDelta));
  }

  void _handlePanEnd() {
    final start = _dragStart;
    final end = _dragEnd;
    _dragStart = null;
    _dragEnd = null;
    if (start == null || end == null) {
      return;
    }
    final delta = end - start;
    if (delta.distance < 18) {
      return;
    }
    if (delta.dx.abs() > delta.dy.abs()) {
      widget.onMove(
        delta.dx > 0 ? SokobanDirection.right : SokobanDirection.left,
      );
    } else {
      widget.onMove(delta.dy > 0 ? SokobanDirection.down : SokobanDirection.up);
    }
  }

  (int, int)? _cellAt(Offset position, Size size) {
    final cellWidth = size.width / widget.level.columns;
    final cellHeight = size.height / widget.level.rows;
    if (cellWidth <= 0 || cellHeight <= 0) {
      return null;
    }
    final column = (position.dx / cellWidth).floor();
    final row = (position.dy / cellHeight).floor();
    if (row < 0 ||
        row >= widget.level.rows ||
        column < 0 ||
        column >= widget.level.columns) {
      return null;
    }
    return (row, column);
  }

  SokobanDirection _directionForDelta(int rowDelta, int columnDelta) {
    if (rowDelta < 0) {
      return SokobanDirection.up;
    }
    if (rowDelta > 0) {
      return SokobanDirection.down;
    }
    return columnDelta < 0 ? SokobanDirection.left : SokobanDirection.right;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          _handleTap(details.localPosition, renderBox.size);
        }
      },
      onPanStart: (details) {
        _dragStart = details.localPosition;
        _dragEnd = details.localPosition;
      },
      onPanUpdate: (details) {
        _dragEnd = details.localPosition;
      },
      onPanEnd: (_) => _handlePanEnd(),
      onPanCancel: () {
        _dragStart = null;
        _dragEnd = null;
      },
      child: CustomPaint(
        painter: _SokobanBoardPainter(
          level: widget.level,
          boxes: widget.boxes,
          player: widget.player,
          showRoute: widget.showRoute,
          remainingSolution: widget.remainingSolution,
          colorScheme: widget.colorScheme,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SokobanBoardPainter extends CustomPainter {
  _SokobanBoardPainter({
    required this.level,
    required this.boxes,
    required this.player,
    required this.showRoute,
    required this.remainingSolution,
    required this.colorScheme,
  }) : _floorPaint = Paint()..color = colorScheme.surfaceContainerLow,
       _wallPaint = Paint()..color = const Color(0xFF394556),
       _borderPaint = Paint()
         ..color = colorScheme.outlineVariant
         ..style = PaintingStyle.stroke,
       _goalPaint = Paint()
         ..color = const Color(0xFFD49A39)
         ..style = PaintingStyle.stroke,
       _routePaint = Paint()
         ..color = const Color(0xFF8A6CCF).withValues(alpha: 0.17),
       _goalDotPaint = Paint()..color = const Color(0xFFD49A39),
       _boxHighlightPaint = Paint()
         ..color = Colors.white.withValues(alpha: 0.5)
         ..style = PaintingStyle.stroke,
       _boxCenterPaint = Paint()..color = Colors.white,
       _playerPaint = Paint()..color = colorScheme.primary,
       _normalBoxPaint = Paint()..color = const Color(0xFFD1944B),
       _goalBoxPaint = Paint()..color = const Color(0xFF46A96B),
       _arrowStrokePaint = Paint()
         ..color = const Color(0xFF8A6CCF)
         ..style = PaintingStyle.stroke
         ..strokeCap = StrokeCap.round,
       _arrowFillPaint = Paint()..color = const Color(0xFF8A6CCF);

  final SokobanLevel level;
  final List<int> boxes;
  final int player;
  final bool showRoute;
  final List<SokobanPush> remainingSolution;
  final ColorScheme colorScheme;

  // These paints are reused for the whole board frame. Only their dimensions
  // change with the cell size, which avoids per-frame style allocation.
  final Paint _floorPaint;
  final Paint _wallPaint;
  final Paint _borderPaint;
  final Paint _goalPaint;
  final Paint _routePaint;
  final Paint _goalDotPaint;
  final Paint _boxHighlightPaint;
  final Paint _boxCenterPaint;
  final Paint _playerPaint;
  final Paint _normalBoxPaint;
  final Paint _goalBoxPaint;
  final Paint _arrowStrokePaint;
  final Paint _arrowFillPaint;

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / level.columns;
    final cellHeight = size.height / level.rows;
    final cell = math.min(cellWidth, cellHeight);
    if (cell <= 0) {
      return;
    }

    _prepareStrokeWidths(cell);
    final wallSet = level.walls;
    final goalSet = level.goals.toSet();
    final routeByCell = _routeByCell();
    _drawCells(
      canvas: canvas,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
      cell: cell,
      wallSet: wallSet,
      goalSet: goalSet,
      routeByCell: routeByCell,
    );
    _drawRouteArrows(
      canvas: canvas,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
      cell: cell,
      routeByCell: routeByCell,
      boxSet: boxes.toSet(),
    );
    _drawBoxes(
      canvas: canvas,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
      cell: cell,
      goalSet: goalSet,
    );
    _drawPlayer(
      canvas: canvas,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
      cell: cell,
    );
  }

  void _prepareStrokeWidths(double cell) {
    _borderPaint.strokeWidth = math.max(1.0, cell * 0.025);
    _goalPaint.strokeWidth = math.max(1.5, cell * 0.06);
    _boxHighlightPaint.strokeWidth = math.max(1.0, cell * 0.025);
    _arrowStrokePaint.strokeWidth = math.max(1.4, cell * 0.045);
  }

  Map<int, SokobanDirection> _routeByCell() {
    final routeByCell = <int, SokobanDirection>{};
    if (!showRoute) {
      return routeByCell;
    }
    for (final push in remainingSolution) {
      routeByCell.putIfAbsent(push.from, () => push.direction);
    }
    return routeByCell;
  }

  void _drawCells({
    required Canvas canvas,
    required double cellWidth,
    required double cellHeight,
    required double cell,
    required Set<int> wallSet,
    required Set<int> goalSet,
    required Map<int, SokobanDirection> routeByCell,
  }) {
    final gap = cell * 0.045;
    final radius = Radius.circular(cell * 0.13);
    for (var row = 0; row < level.rows; row += 1) {
      for (var column = 0; column < level.columns; column += 1) {
        final index = row * level.columns + column;
        final rect = Rect.fromLTWH(
          column * cellWidth + gap,
          row * cellHeight + gap,
          cellWidth - gap * 2,
          cellHeight - gap * 2,
        );
        final rounded = RRect.fromRectAndRadius(rect, radius);
        final isWall = wallSet.contains(index);
        canvas.drawRRect(rounded, isWall ? _wallPaint : _floorPaint);
        if (!isWall && routeByCell.containsKey(index)) {
          canvas.drawRRect(rounded.deflate(cell * 0.04), _routePaint);
        }
        if (goalSet.contains(index)) {
          canvas.drawCircle(rect.center, cell * 0.19, _goalPaint);
          canvas.drawCircle(rect.center, cell * 0.055, _goalDotPaint);
        }
        if (!isWall) {
          canvas.drawRRect(rounded, _borderPaint);
        }
      }
    }
  }

  void _drawRouteArrows({
    required Canvas canvas,
    required double cellWidth,
    required double cellHeight,
    required double cell,
    required Map<int, SokobanDirection> routeByCell,
    required Set<int> boxSet,
  }) {
    for (final entry in routeByCell.entries) {
      if (boxSet.contains(entry.key) || entry.key == player) {
        continue;
      }
      _drawArrow(
        canvas,
        _centerFor(entry.key, cellWidth, cellHeight),
        entry.value,
        cell,
        _arrowStrokePaint,
        _arrowFillPaint,
      );
    }
  }

  void _drawBoxes({
    required Canvas canvas,
    required double cellWidth,
    required double cellHeight,
    required double cell,
    required Set<int> goalSet,
  }) {
    for (final box in boxes) {
      final center = _centerFor(box, cellWidth, cellHeight);
      final boxRect = Rect.fromCenter(
        center: center,
        width: cell * 0.58,
        height: cell * 0.58,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(boxRect, Radius.circular(cell * 0.14)),
        goalSet.contains(box) ? _goalBoxPaint : _normalBoxPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          boxRect.deflate(cell * 0.08),
          Radius.circular(cell * 0.09),
        ),
        _boxHighlightPaint,
      );
      canvas.drawCircle(center, cell * 0.095, _boxCenterPaint);
    }
  }

  void _drawPlayer({
    required Canvas canvas,
    required double cellWidth,
    required double cellHeight,
    required double cell,
  }) {
    final playerCenter = _centerFor(player, cellWidth, cellHeight);
    canvas.drawCircle(
      playerCenter.translate(0, -cell * 0.12),
      cell * 0.13,
      _playerPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: playerCenter.translate(0, cell * 0.13),
          width: cell * 0.34,
          height: cell * 0.29,
        ),
        Radius.circular(cell * 0.1),
      ),
      _playerPaint,
    );
  }

  Offset _centerFor(int index, double cellWidth, double cellHeight) {
    final row = index ~/ level.columns;
    final column = index % level.columns;
    return Offset(
      column * cellWidth + cellWidth / 2,
      row * cellHeight + cellHeight / 2,
    );
  }

  void _drawArrow(
    Canvas canvas,
    Offset center,
    SokobanDirection direction,
    double cell,
    Paint strokePaint,
    Paint fillPaint,
  ) {
    final vector = Offset(
      direction.columnDelta.toDouble(),
      direction.rowDelta.toDouble(),
    );
    final unit = vector / math.max(1.0, vector.distance);
    final start = center - unit * (cell * 0.18);
    final end = center + unit * (cell * 0.22);
    canvas.drawLine(start, end, strokePaint);
    final perpendicular = Offset(-unit.dy, unit.dx);
    final tip = end + unit * (cell * 0.06);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        (end - unit * (cell * 0.12) + perpendicular * (cell * 0.1)).dx,
        (end - unit * (cell * 0.12) + perpendicular * (cell * 0.1)).dy,
      )
      ..lineTo(
        (end - unit * (cell * 0.12) - perpendicular * (cell * 0.1)).dx,
        (end - unit * (cell * 0.12) - perpendicular * (cell * 0.1)).dy,
      )
      ..close();
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _SokobanBoardPainter oldDelegate) {
    return !identical(oldDelegate.level, level) ||
        oldDelegate.player != player ||
        oldDelegate.showRoute != showRoute ||
        !listEquals(oldDelegate.boxes, boxes) ||
        !listEquals(oldDelegate.remainingSolution, remainingSolution) ||
        oldDelegate.colorScheme != colorScheme;
  }
}

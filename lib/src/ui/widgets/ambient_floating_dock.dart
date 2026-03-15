import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../../state/app_state.dart';
import 'ambient_floating_launcher.dart';

class AmbientFloatingDock extends StatefulWidget {
  const AmbientFloatingDock({
    super.key,
    required this.state,
    required this.i18n,
    required this.bottomClearance,
  });

  final AppState state;
  final AppI18n i18n;
  final double bottomClearance;

  @override
  State<AmbientFloatingDock> createState() => _AmbientFloatingDockState();
}

class _AmbientFloatingDockState extends State<AmbientFloatingDock> {
  static const double _edgeMargin = 16;
  static const double _topClearance = 96;

  final GlobalKey _layoutKey = GlobalKey();
  Offset? _normalizedPosition;
  Offset _dragAnchor = const Offset(
    AmbientFloatingLauncher.diameter / 2,
    AmbientFloatingLauncher.diameter / 2,
  );
  bool _dragging = false;

  Offset _configuredPosition() {
    final appearance = widget.state.config.appearance;
    return Offset(
      appearance.normalizedAmbientLauncherX,
      appearance.normalizedAmbientLauncherY,
    );
  }

  Rect _safeRect(Size size, EdgeInsets padding) {
    final minLeft = padding.left + _edgeMargin;
    final minTop = padding.top + _topClearance;
    final maxLeft = math.max(
      minLeft,
      size.width -
          padding.right -
          _edgeMargin -
          AmbientFloatingLauncher.diameter,
    );
    final maxTop = math.max(
      minTop,
      size.height -
          widget.bottomClearance -
          _edgeMargin -
          AmbientFloatingLauncher.diameter,
    );
    return Rect.fromLTWH(minLeft, minTop, maxLeft - minLeft, maxTop - minTop);
  }

  Offset _resolveOffset(Rect safeRect, Offset normalizedPosition) {
    return Offset(
      safeRect.left + safeRect.width * normalizedPosition.dx.clamp(0.0, 1.0),
      safeRect.top + safeRect.height * normalizedPosition.dy.clamp(0.0, 1.0),
    );
  }

  Offset _normalizeOffset(Rect safeRect, Offset topLeft) {
    final clampedLeft = topLeft.dx
        .clamp(safeRect.left, safeRect.right)
        .toDouble();
    final clampedTop = topLeft.dy
        .clamp(safeRect.top, safeRect.bottom)
        .toDouble();
    final normalizedX = safeRect.width <= 0
        ? 0.5
        : ((clampedLeft - safeRect.left) / safeRect.width).clamp(0.0, 1.0);
    final normalizedY = safeRect.height <= 0
        ? 0.5
        : ((clampedTop - safeRect.top) / safeRect.height).clamp(0.0, 1.0);
    return Offset(normalizedX, normalizedY);
  }

  void _persistNormalizedPosition(Offset position) {
    final appearance = widget.state.config.appearance;
    if ((appearance.normalizedAmbientLauncherX - position.dx).abs() < 0.001 &&
        (appearance.normalizedAmbientLauncherY - position.dy).abs() < 0.001) {
      return;
    }
    widget.state.updateConfig(
      widget.state.config.copyWith(
        appearance: appearance.copyWith(
          ambientLauncherX: position.dx,
          ambientLauncherY: position.dy,
        ),
      ),
    );
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    setState(() {
      _dragging = true;
      _dragAnchor = details.localPosition;
      _normalizedPosition ??= _configuredPosition();
    });
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    final renderBox =
        _layoutKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final safeRect = _safeRect(renderBox.size, MediaQuery.paddingOf(context));
    final localTopLeft =
        renderBox.globalToLocal(details.globalPosition) - _dragAnchor;
    setState(() {
      _normalizedPosition = _normalizeOffset(safeRect, localTopLeft);
    });
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    final position = _normalizedPosition ?? _configuredPosition();
    setState(() {
      _dragging = false;
      _normalizedPosition = position;
    });
    _persistNormalizedPosition(position);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final configuredPosition = _normalizedPosition ?? _configuredPosition();

    return LayoutBuilder(
      builder: (context, constraints) {
        final safeRect = _safeRect(constraints.biggest, padding);
        final offset = _resolveOffset(safeRect, configuredPosition);

        return Stack(
          key: _layoutKey,
          children: <Widget>[
            Positioned(
              left: offset.dx,
              top: offset.dy,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPressStart: _handleLongPressStart,
                onLongPressMoveUpdate: _handleLongPressMoveUpdate,
                onLongPressEnd: _handleLongPressEnd,
                child: AnimatedScale(
                  scale: _dragging ? 1.06 : 1.0,
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: _dragging ? 1.0 : 0.94,
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    child: AmbientFloatingLauncher(
                      state: widget.state,
                      i18n: widget.i18n,
                      enabled: !_dragging,
                      surfaceAlpha: _dragging ? 0.92 : 0.82,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

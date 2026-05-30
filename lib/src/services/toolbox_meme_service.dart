import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

enum ToolboxMemeFontFamily { sans, serif, monospace }

enum ToolboxMemeBubbleStyle { classic, panel, sticker }

enum ToolboxMemeTextAlignMode { left, center, right }

@immutable
class ToolboxMemeTextLayer {
  const ToolboxMemeTextLayer({
    required this.id,
    required this.text,
    required this.centerX,
    required this.centerY,
    this.scale = 1,
    this.fontScale = 0.09,
    this.paddingScale = 0.04,
    this.zIndex = 0,
    this.bubbleStyle = ToolboxMemeBubbleStyle.classic,
    this.fontFamily = ToolboxMemeFontFamily.sans,
    this.align = ToolboxMemeTextAlignMode.center,
    this.bold = true,
    this.italic = false,
    this.textColor = Colors.white,
    this.strokeColor = Colors.black,
    this.panelColor = const Color(0x94000000),
  });

  final String id;
  final String text;
  final double centerX;
  final double centerY;
  final double scale;
  final double fontScale;
  final double paddingScale;
  final int zIndex;
  final ToolboxMemeBubbleStyle bubbleStyle;
  final ToolboxMemeFontFamily fontFamily;
  final ToolboxMemeTextAlignMode align;
  final bool bold;
  final bool italic;
  final Color textColor;
  final Color strokeColor;
  final Color panelColor;

  ToolboxMemeTextLayer copyWith({
    String? id,
    String? text,
    double? centerX,
    double? centerY,
    double? scale,
    double? fontScale,
    double? paddingScale,
    int? zIndex,
    ToolboxMemeBubbleStyle? bubbleStyle,
    ToolboxMemeFontFamily? fontFamily,
    ToolboxMemeTextAlignMode? align,
    bool? bold,
    bool? italic,
    Color? textColor,
    Color? strokeColor,
    Color? panelColor,
  }) {
    return ToolboxMemeTextLayer(
      id: id ?? this.id,
      text: text ?? this.text,
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      scale: scale ?? this.scale,
      fontScale: fontScale ?? this.fontScale,
      paddingScale: paddingScale ?? this.paddingScale,
      zIndex: zIndex ?? this.zIndex,
      bubbleStyle: bubbleStyle ?? this.bubbleStyle,
      fontFamily: fontFamily ?? this.fontFamily,
      align: align ?? this.align,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      textColor: textColor ?? this.textColor,
      strokeColor: strokeColor ?? this.strokeColor,
      panelColor: panelColor ?? this.panelColor,
    );
  }
}

@immutable
class ToolboxMemeRenderRequest {
  const ToolboxMemeRenderRequest({
    required this.sourceImage,
    required this.layers,
  });

  final ui.Image sourceImage;
  final List<ToolboxMemeTextLayer> layers;
}

@immutable
class ToolboxMemeResolvedLayer {
  const ToolboxMemeResolvedLayer({
    required this.layer,
    required this.displayText,
    required this.fontSize,
    required this.contentInset,
    required this.paddingX,
    required this.paddingY,
    required this.borderRadius,
    required this.boxWidth,
    required this.boxHeight,
    required this.left,
    required this.top,
    required this.maxLines,
    required this.maxWidth,
    required this.textAlign,
    required this.fillStyle,
    required this.strokeStyle,
  });

  final ToolboxMemeTextLayer layer;
  final String displayText;
  final double fontSize;
  final double contentInset;
  final double paddingX;
  final double paddingY;
  final double borderRadius;
  final double boxWidth;
  final double boxHeight;
  final double left;
  final double top;
  final int maxLines;
  final double maxWidth;
  final TextAlign textAlign;
  final TextStyle fillStyle;
  final TextStyle strokeStyle;

  Rect get bounds => Rect.fromLTWH(left, top, boxWidth, boxHeight);

  bool get showPanel =>
      layer.bubbleStyle == ToolboxMemeBubbleStyle.panel ||
      layer.bubbleStyle == ToolboxMemeBubbleStyle.sticker;

  bool get showStroke => layer.bubbleStyle == ToolboxMemeBubbleStyle.classic;
}

class ToolboxMemeService {
  const ToolboxMemeService._();

  static List<ToolboxMemeTextLayer> buildDefaultLayers() {
    return const <ToolboxMemeTextLayer>[
      ToolboxMemeTextLayer(
        id: 'top',
        text: '',
        centerX: 0.5,
        centerY: 0.16,
        zIndex: 0,
        bubbleStyle: ToolboxMemeBubbleStyle.classic,
        align: ToolboxMemeTextAlignMode.center,
      ),
      ToolboxMemeTextLayer(
        id: 'bottom',
        text: '',
        centerX: 0.5,
        centerY: 0.84,
        zIndex: 1,
        bubbleStyle: ToolboxMemeBubbleStyle.classic,
        align: ToolboxMemeTextAlignMode.center,
      ),
      ToolboxMemeTextLayer(
        id: 'sticker',
        text: 'Sticker',
        centerX: 0.76,
        centerY: 0.74,
        scale: 0.86,
        zIndex: 2,
        bubbleStyle: ToolboxMemeBubbleStyle.sticker,
        align: ToolboxMemeTextAlignMode.center,
      ),
    ];
  }

  static List<ToolboxMemeResolvedLayer> resolveLayers(
    List<ToolboxMemeTextLayer> layers,
    Size canvasSize,
  ) {
    final visible = layers
        .where((layer) => layer.text.trim().isNotEmpty)
        .map((layer) => resolveLayer(layer, canvasSize))
        .toList(growable: false);
    visible.sort(
      (left, right) => left.layer.zIndex.compareTo(right.layer.zIndex),
    );
    return visible;
  }

  static ToolboxMemeResolvedLayer resolveLayer(
    ToolboxMemeTextLayer layer,
    Size canvasSize,
  ) {
    final shortestSide = canvasSize.shortestSide;
    final clampedScale = layer.scale.clamp(0.45, 3.2).toDouble();
    final fontSize = (shortestSide * layer.fontScale * clampedScale)
        .clamp(16.0, shortestSide * 0.26)
        .toDouble();
    final horizontalPadding = (shortestSide * layer.paddingScale * clampedScale)
        .clamp(10.0, shortestSide * 0.18)
        .toDouble();
    final verticalPadding = (horizontalPadding * 0.66)
        .clamp(8.0, 36.0)
        .toDouble();
    final text = _normalizeText(layer.text, layer.bubbleStyle);
    final maxLines = layer.bubbleStyle == ToolboxMemeBubbleStyle.classic
        ? 3
        : 4;
    final contentInset = layer.bubbleStyle == ToolboxMemeBubbleStyle.classic
        ? (fontSize * 0.12).clamp(3.0, 8.0).toDouble()
        : 0.0;
    final maxWidth = (canvasSize.width * 0.82)
        .clamp(48.0, canvasSize.width)
        .toDouble();
    final fillStyle = _buildFillStyle(layer, fontSize);
    final painter = _buildTextPainter(
      text: text,
      style: fillStyle,
      maxWidth: maxWidth,
      textAlign: _textAlign(layer.align),
      maxLines: maxLines,
    );
    final boxWidth = painter.width + horizontalPadding * 2 + contentInset * 2;
    final boxHeight = painter.height + verticalPadding * 2 + contentInset * 2;
    final centerX = (canvasSize.width * layer.centerX)
        .clamp(0.0, canvasSize.width)
        .toDouble();
    final centerY = (canvasSize.height * layer.centerY)
        .clamp(0.0, canvasSize.height)
        .toDouble();
    final left = (centerX - boxWidth / 2)
        .clamp(0.0, canvasSize.width - boxWidth)
        .toDouble();
    final top = (centerY - boxHeight / 2).clamp(
      0.0,
      canvasSize.height - boxHeight,
    );

    return ToolboxMemeResolvedLayer(
      layer: layer,
      displayText: text,
      fontSize: fontSize,
      contentInset: contentInset,
      paddingX: horizontalPadding,
      paddingY: verticalPadding,
      borderRadius: layer.bubbleStyle == ToolboxMemeBubbleStyle.sticker
          ? fontSize * 0.62
          : 18,
      boxWidth: boxWidth,
      boxHeight: boxHeight,
      left: left,
      top: top.toDouble(),
      maxLines: maxLines,
      maxWidth: maxWidth,
      textAlign: _textAlign(layer.align),
      fillStyle: fillStyle,
      strokeStyle: _buildStrokeStyle(layer, fontSize),
    );
  }

  static Future<Uint8List> renderPng(ToolboxMemeRenderRequest request) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final image = request.sourceImage;
    final size = Size(image.width.toDouble(), image.height.toDouble());
    paint(canvas, request, canvasSize: size);

    final picture = recorder.endRecording();
    final rendered = await picture.toImage(image.width, image.height);
    final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
    rendered.dispose();
    if (bytes == null) {
      throw StateError('Failed to encode meme image');
    }
    return bytes.buffer.asUint8List();
  }

  static void paint(
    Canvas canvas,
    ToolboxMemeRenderRequest request, {
    Size? canvasSize,
    String? selectedLayerId,
    Color selectionColor = const Color(0xFF3A86FF),
    bool drawSelection = false,
  }) {
    final image = request.sourceImage;
    final outputSize =
        canvasSize ?? Size(image.width.toDouble(), image.height.toDouble());
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & outputSize,
      Paint()..filterQuality = FilterQuality.high,
    );

    for (final resolved in resolveLayers(request.layers, outputSize)) {
      _paintResolvedLayer(canvas, resolved);
      if (drawSelection && resolved.layer.id == selectedLayerId) {
        final selectionRect = resolved.bounds.inflate(4);
        final selectionRRect = RRect.fromRectAndRadius(
          selectionRect,
          Radius.circular(resolved.borderRadius + 4),
        );
        canvas.drawRRect(
          selectionRRect,
          Paint()
            ..color = selectionColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4,
        );
      }
    }
  }

  static void _paintResolvedLayer(
    Canvas canvas,
    ToolboxMemeResolvedLayer resolved,
  ) {
    final rect = resolved.bounds;
    if (resolved.showPanel) {
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(resolved.borderRadius),
      );
      canvas.drawShadow(
        Path()..addRRect(rrect),
        Colors.black.withValues(alpha: 0.26),
        resolved.fontSize * 0.42,
        true,
      );
      canvas.drawRRect(rrect, Paint()..color = resolved.layer.panelColor);
    }

    final textMaxWidth =
        rect.width - resolved.paddingX * 2 - resolved.contentInset * 2;
    final painter = _buildTextPainter(
      text: resolved.displayText,
      style: resolved.fillStyle,
      maxWidth: textMaxWidth,
      textAlign: resolved.textAlign,
      maxLines: resolved.maxLines,
    );
    final strokePainter = _buildTextPainter(
      text: resolved.displayText,
      style: resolved.strokeStyle,
      maxWidth: textMaxWidth,
      textAlign: resolved.textAlign,
      maxLines: resolved.maxLines,
    );
    final offset = Offset(
      rect.left + resolved.paddingX + resolved.contentInset,
      rect.top + resolved.paddingY + resolved.contentInset,
    );
    if (resolved.showStroke) {
      strokePainter.paint(canvas, offset);
    }
    painter.paint(canvas, offset);
  }

  static TextPainter _buildTextPainter({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required TextAlign textAlign,
    required int maxLines,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    );
    painter.layout(maxWidth: maxWidth);
    return painter;
  }

  static TextStyle _buildFillStyle(
    ToolboxMemeTextLayer layer,
    double fontSize,
  ) {
    return TextStyle(
      color: layer.textColor,
      fontSize: fontSize,
      fontWeight: layer.bold ? FontWeight.w800 : FontWeight.w500,
      fontStyle: layer.italic ? FontStyle.italic : FontStyle.normal,
      letterSpacing: layer.bubbleStyle == ToolboxMemeBubbleStyle.classic
          ? 0.7
          : 0.18,
      height: 1.06,
      fontFamily: _fontFamily(layer.fontFamily),
    );
  }

  static TextStyle _buildStrokeStyle(
    ToolboxMemeTextLayer layer,
    double fontSize,
  ) {
    return _buildFillStyle(layer, fontSize).copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = (fontSize * 0.1).clamp(2.4, 7.0)
        ..color = layer.strokeColor,
    );
  }

  static TextAlign _textAlign(ToolboxMemeTextAlignMode align) {
    return switch (align) {
      ToolboxMemeTextAlignMode.left => TextAlign.left,
      ToolboxMemeTextAlignMode.center => TextAlign.center,
      ToolboxMemeTextAlignMode.right => TextAlign.right,
    };
  }

  static String? _fontFamily(ToolboxMemeFontFamily family) {
    return switch (family) {
      ToolboxMemeFontFamily.sans => null,
      ToolboxMemeFontFamily.serif => 'serif',
      ToolboxMemeFontFamily.monospace => 'monospace',
    };
  }

  static String _normalizeText(String input, ToolboxMemeBubbleStyle style) {
    final clean = input.trim();
    if (style != ToolboxMemeBubbleStyle.classic) {
      return clean;
    }
    final looksAscii = RegExp(r'^[\x00-\x7F\s]+$').hasMatch(clean);
    return looksAscii ? clean.toUpperCase() : clean;
  }
}

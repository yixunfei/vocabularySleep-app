import 'dart:math' as math;

import 'package:flutter/material.dart';

Color seededAccentColor(
  String seed, {
  required Color fallback,
  double saturation = 0.58,
  double value = 0.82,
}) {
  final normalized = seed.trim();
  if (normalized.isEmpty) return fallback;

  var hash = 0;
  for (final rune in normalized.runes) {
    hash = ((hash * 131) + rune) & 0x7FFFFFFF;
  }
  final hue = (hash % 360).toDouble();
  return HSVColor.fromAHSV(1, hue, saturation, value).toColor();
}

class EffectfulText extends StatefulWidget {
  const EffectfulText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
    this.softWrap = true,
    this.rainbowText = false,
    this.marqueeText = false,
    this.breathingEffect = false,
    this.flowingEffect = false,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;
  final TextAlign? textAlign;
  final bool softWrap;
  final bool rainbowText;
  final bool marqueeText;
  final bool breathingEffect;
  final bool flowingEffect;

  @override
  State<EffectfulText> createState() => _EffectfulTextState();
}

class _EffectfulTextState extends State<EffectfulText>
    with SingleTickerProviderStateMixin {
  static const Duration _animationDuration = Duration(milliseconds: 6200);
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _animationDuration,
  );

  bool get _needsAnimation =>
      widget.marqueeText || widget.breathingEffect || widget.flowingEffect;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant EffectfulText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marqueeText != widget.marqueeText ||
        oldWidget.breathingEffect != widget.breathingEffect ||
        oldWidget.flowingEffect != widget.flowingEffect) {
      _syncTicker();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncTicker() {
    if (_needsAnimation) {
      _controller.repeat();
      return;
    }
    _controller.stop();
    _controller.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.text.trim();
    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

    if (!_needsAnimation) {
      return _buildAnimatedContent(context, 0);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) =>
          _buildAnimatedContent(context, _controller.value),
    );
  }

  Widget _buildAnimatedContent(BuildContext context, double phase) {
    final baseStyle = widget.style ?? DefaultTextStyle.of(context).style;
    final textStyle = widget.rainbowText
        ? baseStyle.copyWith(color: Colors.white)
        : baseStyle;
    final useMarquee = widget.marqueeText && widget.text.length > 12;

    Widget child;
    if (useMarquee) {
      final repeated = '${widget.text}     ';
      final fontSize = textStyle.fontSize ?? 20;
      final offset = -phase * repeated.length * fontSize * 0.72;
      child = ClipRect(
        child: SizedBox(
          height: fontSize * 1.35,
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: 0,
            maxWidth: double.infinity,
            child: Transform.translate(
              offset: Offset(offset, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(repeated, style: textStyle, softWrap: false),
                  Text(repeated, style: textStyle, softWrap: false),
                  Text(repeated, style: textStyle, softWrap: false),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      child = Text(
        widget.text,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
        textAlign: widget.textAlign,
        softWrap: widget.softWrap,
        style: textStyle,
      );
    }

    if (widget.rainbowText) {
      child = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) {
          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const <Color>[
              Color(0xFFEF4444),
              Color(0xFFF59E0B),
              Color(0xFF10B981),
              Color(0xFF3B82F6),
              Color(0xFF8B5CF6),
            ],
            transform: widget.flowingEffect
                ? GradientRotation(phase * math.pi * 2)
                : null,
          ).createShader(bounds);
        },
        child: child,
      );
    }

    if (widget.flowingEffect && !widget.rainbowText) {
      final drift = math.sin(phase * math.pi * 2) * 3;
      child = Transform.translate(offset: Offset(drift, 0), child: child);
    }

    if (widget.breathingEffect) {
      final scale = 1 + math.sin(phase * math.pi * 2) * 0.02;
      child = Transform.scale(
        scale: scale,
        alignment: Alignment.centerLeft,
        child: child,
      );
    }

    return child;
  }
}

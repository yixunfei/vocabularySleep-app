import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/play_config.dart';
import '../theme/app_theme.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.appearance,
    required this.child,
  });

  final AppearanceConfig appearance;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final backgroundImagePath = appearance.backgroundImagePath.trim();
    final hasBackgroundImage =
        backgroundImagePath.isNotEmpty &&
        File(backgroundImagePath).existsSync();

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: tokens.mode == AppExperienceMode.sleep
          ? <Color>[tokens.canvas, tokens.surface, const Color(0xFF17324B)]
          : <Color>[
              tokens.canvas,
              tokens.surfaceStrong,
              const Color(0xFFEAF3FF),
            ],
    );

    final imageFit = switch (appearance.normalizedBackgroundImageMode) {
      'contain' => BoxFit.contain,
      'stretch' => BoxFit.fill,
      'top' => BoxFit.fitWidth,
      'tile' => BoxFit.none,
      _ => BoxFit.cover,
    };
    final effectiveImageOpacity = appearance.normalizedBackgroundImageOpacity
        .clamp(0.0, 0.8);
    final backgroundScrimAlpha = hasBackgroundImage
        ? (tokens.isDark
                  ? (0.10 + effectiveImageOpacity * 0.18)
                  : (0.18 + effectiveImageOpacity * 0.24))
              .clamp(0.0, 0.62)
        : 0.0;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
        Positioned(
          top: -60,
          right: -20,
          child: _GlowOrb(
            size: 220,
            color: tokens.accent.withValues(
              alpha: tokens.mode == AppExperienceMode.sleep ? 0.18 : 0.12,
            ),
          ),
        ),
        Positioned(
          bottom: -40,
          left: -30,
          child: _GlowOrb(
            size: 180,
            color: tokens.glow.withValues(alpha: 0.14),
          ),
        ),
        if (hasBackgroundImage)
          IgnorePointer(
            child: Opacity(
              opacity: effectiveImageOpacity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(backgroundImagePath)),
                    fit: imageFit,
                    alignment: appearance.normalizedBackgroundImageMode == 'top'
                        ? Alignment.topCenter
                        : Alignment.center,
                    repeat: appearance.normalizedBackgroundImageMode == 'tile'
                        ? ImageRepeat.repeat
                        : ImageRepeat.noRepeat,
                  ),
                ),
              ),
            ),
          ),
        if (backgroundScrimAlpha > 0)
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.canvas.withValues(alpha: backgroundScrimAlpha),
              ),
            ),
          ),
        child,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

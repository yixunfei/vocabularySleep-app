import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/play_config.dart';
import '../theme/app_theme.dart';

class AppBackground extends StatefulWidget {
  const AppBackground({
    super.key,
    required this.appearance,
    required this.child,
  });

  final AppearanceConfig appearance;
  final Widget child;

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> {
  FileImage? _backgroundImageProvider;
  ImageStream? _backgroundImageStream;
  ImageStreamListener? _backgroundImageListener;
  String _backgroundImagePath = '';
  bool _hasBackgroundImage = false;

  @override
  void initState() {
    super.initState();
    _syncBackgroundImage();
  }

  @override
  void didUpdateWidget(covariant AppBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousPath = oldWidget.appearance.backgroundImagePath.trim();
    final nextPath = widget.appearance.backgroundImagePath.trim();
    if (previousPath != nextPath) {
      _syncBackgroundImage();
    }
  }

  @override
  void dispose() {
    _clearBackgroundImageListener();
    super.dispose();
  }

  void _syncBackgroundImage() {
    final nextPath = widget.appearance.backgroundImagePath.trim();
    if (nextPath == _backgroundImagePath && _backgroundImageProvider != null) {
      return;
    }

    _backgroundImagePath = nextPath;
    _clearBackgroundImageListener();

    if (nextPath.isEmpty) {
      _backgroundImageProvider = null;
      if (_hasBackgroundImage) {
        setState(() {
          _hasBackgroundImage = false;
        });
      }
      return;
    }

    final provider = FileImage(File(nextPath));
    final stream = provider.resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      (imageInfo, synchronousCall) {
        if (!mounted || _backgroundImagePath != nextPath) {
          return;
        }
        _backgroundImageProvider = provider;
        if (_hasBackgroundImage) {
          return;
        }
        setState(() {
          _hasBackgroundImage = true;
        });
      },
      onError: (error, stackTrace) {
        if (!mounted || _backgroundImagePath != nextPath) {
          return;
        }
        _backgroundImageProvider = null;
        if (!_hasBackgroundImage) {
          return;
        }
        setState(() {
          _hasBackgroundImage = false;
        });
      },
    );

    _backgroundImageProvider = provider;
    _backgroundImageStream = stream;
    _backgroundImageListener = listener;
    stream.addListener(listener);

    if (_hasBackgroundImage) {
      setState(() {
        _hasBackgroundImage = false;
      });
    }
  }

  void _clearBackgroundImageListener() {
    final stream = _backgroundImageStream;
    final listener = _backgroundImageListener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _backgroundImageStream = null;
    _backgroundImageListener = null;
  }

  @override
  Widget build(BuildContext context) {
    final appearance = widget.appearance;
    final tokens = AppThemeTokens.of(context);
    final hasBackgroundImage =
        _hasBackgroundImage && _backgroundImageProvider != null;

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
        if (_backgroundImageProvider != null)
          IgnorePointer(
            child: Opacity(
              opacity: effectiveImageOpacity,
              child: SizedBox.expand(
                child: Image(
                  image: _backgroundImageProvider!,
                  fit: imageFit,
                  alignment: appearance.normalizedBackgroundImageMode == 'top'
                      ? Alignment.topCenter
                      : Alignment.center,
                  repeat: appearance.normalizedBackgroundImageMode == 'tile'
                      ? ImageRepeat.repeat
                      : ImageRepeat.noRepeat,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
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
        widget.child,
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

part of '../toolbox_life_tools.dart';

enum _ClockFlipStyle { classic, smooth, quick }

class _ClockFlipStyleSpec {
  const _ClockFlipStyleSpec({
    required this.labelKey,
    required this.duration,
    required this.curve,
    required this.perspective,
  });

  final String labelKey;
  final Duration duration;
  final Curve curve;
  final double perspective;

  String label(BuildContext context) {
    return _lifeI18nText(context, labelKey);
  }
}

const Map<_ClockFlipStyle, _ClockFlipStyleSpec> _clockFlipSpecs =
    <_ClockFlipStyle, _ClockFlipStyleSpec>{
      _ClockFlipStyle.classic: _ClockFlipStyleSpec(
        labelKey: 'inline.plan295.life.classic_flip.892bc25f0550',
        duration: Duration(milliseconds: 640),
        curve: Curves.easeInOutCubic,
        perspective: 0.0019,
      ),
      _ClockFlipStyle.smooth: _ClockFlipStyleSpec(
        labelKey: 'inline.plan295.life.smooth_page.abec263a6f41',
        duration: Duration(milliseconds: 780),
        curve: Curves.easeInOutSine,
        perspective: 0.0016,
      ),
      _ClockFlipStyle.quick: _ClockFlipStyleSpec(
        labelKey: 'inline.plan295.life.quick_flip.cbf4c283cd37',
        duration: Duration(milliseconds: 480),
        curve: Curves.fastOutSlowIn,
        perspective: 0.0022,
      ),
    };

const List<_LifeOption<_ClockFlipStyle>> _clockFlipOptions =
    <_LifeOption<_ClockFlipStyle>>[
      _LifeOption(
        value: _ClockFlipStyle.classic,
        labelKey: 'inline.plan295.life.classic_flip.892bc25f0550',
      ),
      _LifeOption(
        value: _ClockFlipStyle.smooth,
        labelKey: 'inline.plan295.life.smooth_page.abec263a6f41',
      ),
      _LifeOption(
        value: _ClockFlipStyle.quick,
        labelKey: 'inline.plan295.life.quick_flip.cbf4c283cd37',
      ),
    ];

_ClockFlipStyleSpec _clockFlipSpec(_ClockFlipStyle style) {
  return _clockFlipSpecs[style]!;
}

Duration _clockFlipDuration(_ClockFlipStyle style, bool preview) {
  final base = _clockFlipSpec(style).duration;
  if (!preview) {
    return base;
  }
  final previewMillis = (base.inMilliseconds * 0.78).round().clamp(360, 640);
  return Duration(milliseconds: previewMillis);
}

class _FlipNumberTile extends StatefulWidget {
  const _FlipNumberTile({
    required this.value,
    required this.tokens,
    required this.fontStyle,
    required this.fontSize,
    required this.radius,
    required this.preview,
    required this.flipStyle,
  });

  final String value;
  final _ClockThemeTokens tokens;
  final _ClockFontStyle fontStyle;
  final double fontSize;
  final double radius;
  final bool preview;
  final _ClockFlipStyle flipStyle;

  @override
  State<_FlipNumberTile> createState() => _FlipNumberTileState();
}

class _FlipNumberTileState extends State<_FlipNumberTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late String _fromValue = widget.value;
  late String _toValue = widget.value;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: _clockFlipDuration(widget.flipStyle, widget.preview),
        )..addStatusListener((status) {
          if (!mounted || status != AnimationStatus.completed) {
            return;
          }
          setState(() {
            _fromValue = _toValue;
            _isAnimating = false;
          });
        });
  }

  @override
  void didUpdateWidget(covariant _FlipNumberTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = _clockFlipDuration(widget.flipStyle, widget.preview);
    if (oldWidget.value == widget.value) {
      return;
    }
    setState(() {
      _fromValue = _isAnimating ? _toValue : oldWidget.value;
      _toValue = widget.value;
      _isAnimating = true;
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileSize = Size(constraints.maxWidth, constraints.maxHeight);
        if (!_isAnimating || _fromValue == _toValue) {
          return _ClockDigitCard(
            value: widget.value,
            tokens: widget.tokens,
            fontStyle: widget.fontStyle,
            fontSize: widget.fontSize,
            radius: widget.radius,
          );
        }

        final spec = _clockFlipSpec(widget.flipStyle);
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final raw = _controller.value;
            final flipProgress = spec.curve.transform(raw);
            final revealProgress = _phaseProgress(
              raw,
              start: 0.04,
              end: 0.94,
              curve: Curves.easeOutCubic,
            );
            final shadowProgress = _phaseProgress(
              raw,
              start: 0.0,
              end: 0.72,
              curve: Curves.easeInOutCubic,
            );
            final pageAngle = -math.pi * 0.5 * (1 - flipProgress);
            final pageOpacity = _phaseProgress(
              raw,
              start: 0.0,
              end: 0.16,
              curve: Curves.easeOutCubic,
            );
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                _ClockDigitCard(
                  value: _fromValue,
                  tokens: widget.tokens,
                  fontStyle: widget.fontStyle,
                  fontSize: widget.fontSize,
                  radius: widget.radius,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRect(
                      child: Transform(
                        alignment: Alignment.topCenter,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, spec.perspective)
                          ..rotateX(pageAngle),
                        child: Opacity(
                          opacity: pageOpacity,
                          child: _ClockDigitCard(
                            value: _toValue,
                            tokens: widget.tokens,
                            fontStyle: widget.fontStyle,
                            fontSize: widget.fontSize,
                            radius: widget.radius,
                            showDivider: false,
                            showHinges: false,
                            foreground: _ClockFlipPageOverlay(
                              highlightAlpha: 0.18 * (1 - revealProgress),
                              shadowAlpha:
                                  0.26 *
                                  math.sin(math.pi * revealProgress).abs(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        height:
                            tileSize.height * (0.16 + 0.38 * revealProgress),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Colors.black.withValues(
                                alpha: 0.2 * shadowProgress,
                              ),
                              Colors.black.withValues(
                                alpha: 0.08 * shadowProgress,
                              ),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

double _phaseProgress(
  double value, {
  required double start,
  required double end,
  required Curve curve,
}) {
  if (value <= start) {
    return 0;
  }
  if (value >= end) {
    return 1;
  }
  final clamped = (value - start) / (end - start);
  return curve.transform(clamped);
}

class _ClockDigitCard extends StatelessWidget {
  const _ClockDigitCard({
    required this.value,
    required this.tokens,
    required this.fontStyle,
    required this.fontSize,
    required this.radius,
    this.showValue = true,
    this.showDivider = true,
    this.showHinges = true,
    this.foreground,
  });

  final String value;
  final _ClockThemeTokens tokens;
  final _ClockFontStyle fontStyle;
  final double fontSize;
  final double radius;
  final bool showValue;
  final bool showDivider;
  final bool showHinges;
  final Widget? foreground;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: tokens.digit,
      fontSize: fontSize,
      fontWeight: _fontWeight(fontStyle),
      fontFamily: _fontFamily(fontStyle),
      letterSpacing: 0,
      height: 0.92,
    );
    return Container(
      decoration: BoxDecoration(
        color: tokens.panel,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Color.lerp(tokens.divider, tokens.digit, 0.08)!,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: tokens.shadow,
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (showDivider || showHinges)
              Column(
                children: <Widget>[
                  Expanded(
                    child: ColoredBox(
                      color: Color.lerp(tokens.panel, Colors.white, 0.08)!,
                    ),
                  ),
                  Expanded(
                    child: ColoredBox(
                      color: Color.lerp(tokens.panel, tokens.panelAlt, 0.36)!,
                    ),
                  ),
                ],
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color.lerp(tokens.panel, Colors.white, 0.04)!,
                      Color.lerp(tokens.panel, tokens.panelAlt, 0.18)!,
                    ],
                  ),
                ),
              ),
            if (showValue)
              Align(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value, maxLines: 1, style: textStyle),
                ),
              ),
            if (showDivider)
              Align(
                alignment: Alignment.center,
                child: Container(height: 1.6, color: tokens.divider),
              ),
            if (showHinges) ...<Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: _ClockHinge(color: tokens.divider),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: _ClockHinge(color: tokens.divider),
              ),
            ],
            if (foreground != null) foreground!,
          ],
        ),
      ),
    );
  }

  FontWeight _fontWeight(_ClockFontStyle style) {
    return switch (style) {
      _ClockFontStyle.rounded => FontWeight.w900,
      _ClockFontStyle.classic => FontWeight.w900,
      _ClockFontStyle.mono => FontWeight.w800,
      _ClockFontStyle.slim => FontWeight.w600,
    };
  }

  String? _fontFamily(_ClockFontStyle style) {
    return switch (style) {
      _ClockFontStyle.rounded => null,
      _ClockFontStyle.classic => 'Georgia',
      _ClockFontStyle.mono => 'monospace',
      _ClockFontStyle.slim => 'sans-serif',
    };
  }
}

class _ClockFlipPageOverlay extends StatelessWidget {
  const _ClockFlipPageOverlay({
    required this.highlightAlpha,
    required this.shadowAlpha,
  });

  final double highlightAlpha;
  final double shadowAlpha;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: highlightAlpha.clamp(0.0, 1.0)),
            Colors.transparent,
            Colors.black.withValues(alpha: shadowAlpha.clamp(0.0, 1.0)),
          ],
          stops: const <double>[0.0, 0.42, 1.0],
        ),
      ),
    );
  }
}

class _ClockHinge extends StatelessWidget {
  const _ClockHinge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 22,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

part of '../toolbox_life_tools.dart';

class _ScoreButton extends StatelessWidget {
  const _ScoreButton({
    required this.icon,
    required this.onTap,
    required this.color,
    this.disabled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = disabled
        ? color.withValues(alpha: 0.25)
        : color;
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: effectiveColor.withValues(alpha: 0.12),
          border: Border.all(color: effectiveColor.withValues(alpha: 0.35)),
        ),
        child: Icon(icon, color: effectiveColor, size: 28),
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final Color value;
  final ValueChanged<Color> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = compact ? 18.0 : 22.0;
    final hasCustom = !_teamColorPresets.any(
      (c) => c.toARGB32() == value.toARGB32(),
    );

    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: <Widget>[
        for (final c in _teamColorPresets)
          _buildSwatch(context, theme, c, c.toARGB32() == value.toARGB32(), size),
        _buildCustomSwatch(context, theme, hasCustom ? value : null, size),
      ],
    );
  }

  Widget _buildSwatch(
    BuildContext context,
    ThemeData theme,
    Color color,
    bool selected,
    double size,
  ) {
    return GestureDetector(
      onTap: () => onChanged(color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? theme.colorScheme.primary : Colors.transparent,
            width: selected ? 2.5 : 0,
          ),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: selected && !compact
            ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildCustomSwatch(
    BuildContext context,
    ThemeData theme,
    Color? customColor,
    double size,
  ) {
    final cc = customColor;
    final hasCustom = cc != null;
    final shadow = hasCustom
        ? <BoxShadow>[
            BoxShadow(
              color: cc.withValues(alpha: 0.4),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ]
        : null;
    final iconColor = hasCustom
        ? (cc.computeLuminance() > 0.5 ? Colors.black87 : Colors.white)
        : theme.colorScheme.outlineVariant;
    return GestureDetector(
      onTap: () => _showCustomColorDialog(context, cc ?? value).then(
        (c) {
          if (c != null) onChanged(c);
        },
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: hasCustom ? cc : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: hasCustom
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: hasCustom ? 2.5 : 1.5,
          ),
          boxShadow: shadow,
        ),
        child: Icon(
          hasCustom ? Icons.check_rounded : Icons.add_rounded,
          size: size * 0.65,
          color: iconColor,
        ),
      ),
    );
  }
}

Future<Color?> _showCustomColorDialog(BuildContext context, Color initial) {
  final hsl = HSLColor.fromColor(initial);
  double hue = hsl.hue;
  double saturation = hsl.saturation;
  double lightness = hsl.lightness;

  Color current() =>
      HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();

  return showDialog<Color>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final c = current();
          final brightness = ThemeData.estimateBrightnessForColor(c);
          return AlertDialog(
            title: Text(_lifeText(context, zh: '自定义颜色', en: 'Custom color')),
            content: SizedBox(
              width: 280,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                      style: TextStyle(
                        color: brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _hslSlider(
                    ctx,
                    setState,
                    _lifeText(context, zh: '色相', en: 'Hue'),
                    hue,
                    0,
                    360,
                    (v) => hue = v,
                  ),
                  _hslSlider(
                    ctx,
                    setState,
                    _lifeText(context, zh: '饱和度', en: 'Saturation'),
                    saturation,
                    0,
                    1,
                    (v) => saturation = v,
                  ),
                  _hslSlider(
                    ctx,
                    setState,
                    _lifeText(context, zh: '亮度', en: 'Lightness'),
                    lightness,
                    0,
                    1,
                    (v) => lightness = v,
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(_lifeText(context, zh: '取消', en: 'Cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(current()),
                child: Text(_lifeText(context, zh: '确定', en: 'Confirm')),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _hslSlider(
  BuildContext context,
  StateSetter setState,
  String label,
  double value,
  double min,
  double max,
  ValueChanged<double> onChanged,
) {
  return Row(
    children: <Widget>[
      SizedBox(
        width: 60,
        child: Text(label, style: Theme.of(context).textTheme.labelMedium),
      ),
      Expanded(
        child: Slider(
          value: value,
          min: min,
          max: max,
          onChanged: (v) {
            setState(() => onChanged(v));
          },
        ),
      ),
      SizedBox(
        width: 42,
        child: Text(
          max <= 1 ? '${(value * 100).round()}%' : '${value.round()}',
          style: Theme.of(context).textTheme.labelSmall,
          textAlign: TextAlign.end,
        ),
      ),
    ],
  );
}

class _FlipScore extends StatefulWidget {
  const _FlipScore({
    required this.score,
    required this.color,
    required this.vsync,
    this.fontSize = 56,
    this.cardColor,
    this.height = 90,
  });

  final int score;
  final Color color;
  final TickerProvider vsync;
  final double fontSize;
  final Color? cardColor;
  final double height;

  static const Color lightCardColor = Color(0xFFFFF8F0);

  @override
  State<_FlipScore> createState() => _FlipScoreState();
}

class _FlipScoreState extends State<_FlipScore>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _previous = 0;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _previous = widget.score;
    _controller = AnimationController(
      vsync: widget.vsync,
      duration: const Duration(milliseconds: 480),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            _previous = widget.score;
            _animating = false;
          });
        }
      });
  }

  @override
  void didUpdateWidget(covariant _FlipScore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score && !_animating) {
      _previous = oldWidget.score;
      _animating = true;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final showPrevious = _controller.value < 0.55;
        final displayScore = showPrevious ? _previous : widget.score;
        final t = _controller.value;

        final foldAngle = (Curves.easeInOutCubic.transform(
                  (t / 0.55).clamp(0.0, 1.0),
                )) *
            math.pi *
            0.98;
        final activeAngle = showPrevious ? foldAngle : 0.0;
        final shadowOpacity = (1.0 - (t - 0.5).abs() * 2.0).clamp(0.0, 1.0);

        final isLight = widget.cardColor != null;
        final cardBg = widget.cardColor ?? Colors.black.withValues(alpha: 0.85);
        final cardBorder = isLight
            ? Colors.grey.withValues(alpha: 0.3)
            : widget.color.withValues(alpha: 0.25);
        final textColor = isLight ? const Color(0xFF1A1A1A) : widget.color;
        final dividerColor = isLight
            ? Colors.grey.withValues(alpha: 0.25)
            : widget.color.withValues(alpha: 0.35);
        final hingeColor = isLight
            ? Colors.grey.withValues(alpha: 0.4)
            : widget.color.withValues(alpha: 0.5);
        final cardShadow = isLight
            ? Colors.black.withValues(alpha: 0.08)
            : widget.color.withValues(alpha: 0.18);
        final gradientTop = isLight
            ? Colors.black.withValues(alpha: 0.06 * shadowOpacity)
            : Colors.black.withValues(alpha: 0.35 * shadowOpacity);

        final textStyle = TextStyle(
          color: textColor,
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
          height: 0.9,
        );

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder, width: 1.5),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: cardShadow,
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Align(
                  alignment: Alignment.center,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.002)
                      ..rotateX(showPrevious ? -activeAngle : activeAngle),
                    child: Opacity(
                      opacity: showPrevious
                          ? (1.0 - t / 0.55).clamp(0.4, 1.0)
                          : ((t - 0.45) / 0.55).clamp(0.0, 1.0) * 0.6 + 0.4,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '$displayScore',
                            style: textStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: widget.height / 2,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[gradientTop, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(height: 1.5, color: dividerColor),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 5,
                    height: 16,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: hingeColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 5,
                    height: 16,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: hingeColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

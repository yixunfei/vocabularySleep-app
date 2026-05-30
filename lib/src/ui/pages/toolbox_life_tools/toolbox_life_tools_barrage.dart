part of '../toolbox_life_tools.dart';

enum _BarrageOrientation { landscape, portrait }

enum _BarrageMotion { still, scroll, flash, shake }

enum _BarrageFontStyle { rounded, mono, serif, compact }

enum _BarrageBackgroundMode { solid, gradient, spotlight }

class _BarrageConfig {
  const _BarrageConfig({
    required this.text,
    required this.fontSize,
    required this.speed,
    required this.textColor,
    required this.backgroundColor,
    required this.secondaryBackgroundColor,
    required this.orientation,
    required this.motion,
    required this.fontStyle,
    required this.backgroundMode,
    required this.bold,
  });

  final String text;
  final double fontSize;
  final double speed;
  final Color textColor;
  final Color backgroundColor;
  final Color secondaryBackgroundColor;
  final _BarrageOrientation orientation;
  final _BarrageMotion motion;
  final _BarrageFontStyle fontStyle;
  final _BarrageBackgroundMode backgroundMode;
  final bool bold;

  _BarrageConfig copyWith({
    String? text,
    double? fontSize,
    double? speed,
    Color? textColor,
    Color? backgroundColor,
    Color? secondaryBackgroundColor,
    _BarrageOrientation? orientation,
    _BarrageMotion? motion,
    _BarrageFontStyle? fontStyle,
    _BarrageBackgroundMode? backgroundMode,
    bool? bold,
  }) {
    return _BarrageConfig(
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      speed: speed ?? this.speed,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      secondaryBackgroundColor:
          secondaryBackgroundColor ?? this.secondaryBackgroundColor,
      orientation: orientation ?? this.orientation,
      motion: motion ?? this.motion,
      fontStyle: fontStyle ?? this.fontStyle,
      backgroundMode: backgroundMode ?? this.backgroundMode,
      bold: bold ?? this.bold,
    );
  }
}

const List<_LifeOption<_BarrageOrientation>> _barrageOrientationOptions =
    <_LifeOption<_BarrageOrientation>>[
      _LifeOption(
        value: _BarrageOrientation.landscape,
        labelKey: 'inline.plan295.life.landscape.e669e150f0b9',
      ),
      _LifeOption(
        value: _BarrageOrientation.portrait,
        labelKey: 'inline.plan295.life.portrait.c66aa09a292c',
      ),
    ];

const List<_LifeOption<_BarrageMotion>> _barrageMotionOptions =
    <_LifeOption<_BarrageMotion>>[
      _LifeOption(
        value: _BarrageMotion.still,
        labelKey: 'inline.plan295.life.still.05c1a3e01a9c',
      ),
      _LifeOption(
        value: _BarrageMotion.scroll,
        labelKey: 'inline.plan295.life.scroll.49c2c3013fb7',
      ),
      _LifeOption(
        value: _BarrageMotion.flash,
        labelKey: 'inline.plan295.life.flash.a481fa989277',
      ),
      _LifeOption(
        value: _BarrageMotion.shake,
        labelKey: 'inline.plan295.life.shake.58fc46e22813',
      ),
    ];

const List<_LifeOption<_BarrageFontStyle>> _barrageFontOptions =
    <_LifeOption<_BarrageFontStyle>>[
      _LifeOption(
        value: _BarrageFontStyle.rounded,
        labelKey: 'inline.plan295.life.rounded.467a787ced2f',
      ),
      _LifeOption(
        value: _BarrageFontStyle.mono,
        labelKey: 'inline.plan295.life.mono.6193ef478e21',
      ),
      _LifeOption(
        value: _BarrageFontStyle.serif,
        labelKey: 'inline.plan295.life.poster.bab0ae777f03',
      ),
      _LifeOption(
        value: _BarrageFontStyle.compact,
        labelKey: 'inline.plan295.life.compact.4ad0fccd6bf4',
      ),
    ];

const List<_LifeOption<_BarrageBackgroundMode>> _barrageBackgroundOptions =
    <_LifeOption<_BarrageBackgroundMode>>[
      _LifeOption(
        value: _BarrageBackgroundMode.solid,
        labelKey: 'inline.plan295.life.solid.ab6af9a81131',
      ),
      _LifeOption(
        value: _BarrageBackgroundMode.gradient,
        labelKey: 'inline.plan295.life.gradient.a0eca7ff048c',
      ),
      _LifeOption(
        value: _BarrageBackgroundMode.spotlight,
        labelKey: 'inline.plan295.life.spotlight.7e514c3f59f5',
      ),
    ];

const List<_LifeColorOption> _barrageTextColors = <_LifeColorOption>[
  _LifeColorOption(
    color: Colors.white,
    labelKey: 'inline.plan295.life.white.57bb2b2d89ca',
  ),
  _LifeColorOption(
    color: Color(0xFFFFE45E),
    labelKey: 'inline.plan295.life.yellow.d7182985d92a',
  ),
  _LifeColorOption(
    color: Color(0xFFFF4D8D),
    labelKey: 'inline.plan295.life.pink.b7bd3b21d347',
  ),
  _LifeColorOption(
    color: Color(0xFF5AF0FF),
    labelKey: 'inline.plan295.life.cyan.4455b90fad29',
  ),
  _LifeColorOption(
    color: Color(0xFF46FF88),
    labelKey: 'inline.plan295.life.green.b645407522f6',
  ),
  _LifeColorOption(
    color: Color(0xFF111111),
    labelKey: 'inline.plan295.life.black.d91732d1012f',
  ),
];

const List<_LifeColorOption> _barrageBackgroundColors = <_LifeColorOption>[
  _LifeColorOption(
    color: Colors.black,
    labelKey: 'inline.plan295.life.black.d91732d1012f',
  ),
  _LifeColorOption(
    color: Color(0xFF09243F),
    labelKey: 'inline.plan295.life.deep_blue.4524ee561be8',
  ),
  _LifeColorOption(
    color: Color(0xFF321042),
    labelKey: 'inline.plan295.life.violet.cdad5e1009e1',
  ),
  _LifeColorOption(
    color: Color(0xFF7A111D),
    labelKey: 'inline.plan297.human_tests.cognition.stroop.red.1e859a3d5f',
  ),
  _LifeColorOption(
    color: Color(0xFFFFF3A3),
    labelKey: 'inline.plan295.life.warm_yellow.b2567b7c1c49',
  ),
  _LifeColorOption(
    color: Colors.white,
    labelKey: 'inline.plan295.life.white.57bb2b2d89ca',
  ),
];

class _BarrageToolPage extends StatefulWidget {
  const _BarrageToolPage();

  @override
  State<_BarrageToolPage> createState() => _BarrageToolPageState();
}

class _BarrageToolPageState extends State<_BarrageToolPage> {
  final TextEditingController _controller = TextEditingController(text: '今晚加油');

  _BarrageConfig _config = const _BarrageConfig(
    text: '今晚加油',
    fontSize: 74,
    speed: 1.0,
    textColor: Color(0xFFFFE45E),
    backgroundColor: Colors.black,
    secondaryBackgroundColor: Color(0xFF09243F),
    orientation: _BarrageOrientation.landscape,
    motion: _BarrageMotion.scroll,
    fontStyle: _BarrageFontStyle.rounded,
    backgroundMode: _BarrageBackgroundMode.gradient,
    bold: true,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateConfig(_BarrageConfig config) {
    setState(() => _config = config);
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.handheld_barrage.eb37eeab9e11',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.configure_content_typography_speed_c.627e155aef47',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: _lifeI18nText(
              context,
              'inline.plan295.life.barrage_preview.74203bd23132',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.life.fullscreen_keeps_the_screen_awake_an.2ffe395a0d99',
            ),
          ),
          const SizedBox(height: 12),
          _LifePreviewFrame(
            child: AspectRatio(
              aspectRatio: _config.orientation == _BarrageOrientation.landscape
                  ? 16 / 9
                  : 9 / 16,
              child: _BarrageStage(config: _config, preview: true),
            ),
          ),
          const SizedBox(height: 16),
          _BarrageSettingsPanel(
            config: _config,
            controller: _controller,
            onChanged: _updateConfig,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                final text = _controller.text.trim();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    fullscreenDialog: true,
                    builder: (_) => _BarrageImmersivePage(
                      config: _config.copyWith(
                        text: text.isEmpty ? '...' : text,
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.show_barrage.352ca5559877',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarrageSettingsPanel extends StatelessWidget {
  const _BarrageSettingsPanel({
    required this.config,
    required this.controller,
    required this.onChanged,
  });

  final _BarrageConfig config;
  final TextEditingController controller;
  final ValueChanged<_BarrageConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.barrage_settings.5611134445c1',
      ),
      children: <Widget>[
        TextField(
          controller: controller,
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _lifeI18nText(
              context,
              'inline.plan295.life.barrage_text.aab6b02e7e08',
            ),
          ),
          onChanged: (value) => onChanged(config.copyWith(text: value)),
        ),
        const SizedBox(height: 14),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.font_size.f1403f714084',
          ),
          valueText: config.fontSize.round().toString(),
          value: config.fontSize,
          min: 28,
          max: 156,
          divisions: 32,
          onChanged: (value) => onChanged(config.copyWith(fontSize: value)),
        ),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.scroll_speed.9950ae3a912f',
          ),
          valueText: '${config.speed.toStringAsFixed(1)}x',
          value: config.speed,
          min: 0.4,
          max: 3.0,
          divisions: 26,
          onChanged: (value) => onChanged(config.copyWith(speed: value)),
        ),
        const SizedBox(height: 6),
        _LifeSegmentedField<_BarrageOrientation>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.display_mode.2d50ceb575c4',
          ),
          value: config.orientation,
          options: _barrageOrientationOptions,
          onChanged: (value) => onChanged(config.copyWith(orientation: value)),
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<_BarrageMotion>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.motion.a9861b2e7f86',
          ),
          value: config.motion,
          options: _barrageMotionOptions,
          onChanged: (value) => onChanged(config.copyWith(motion: value)),
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<_BarrageFontStyle>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.font_style.b0223210002e',
          ),
          value: config.fontStyle,
          options: _barrageFontOptions,
          onChanged: (value) => onChanged(config.copyWith(fontStyle: value)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: config.bold,
          title: Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.bold_text.e7ea04645233',
            ),
          ),
          onChanged: (value) => onChanged(config.copyWith(bold: value)),
        ),
        const SizedBox(height: 8),
        _LifeSegmentedField<_BarrageBackgroundMode>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.background.50f7c5422844',
          ),
          value: config.backgroundMode,
          options: _barrageBackgroundOptions,
          onChanged: (value) =>
              onChanged(config.copyWith(backgroundMode: value)),
        ),
        const SizedBox(height: 14),
        _LifeColorField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.text_color.f15dfed1504d',
          ),
          value: config.textColor,
          options: _barrageTextColors,
          onChanged: (value) => onChanged(config.copyWith(textColor: value)),
        ),
        const SizedBox(height: 14),
        _LifeColorField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.background_color.de7a28cc0124',
          ),
          value: config.backgroundColor,
          options: _barrageBackgroundColors,
          onChanged: (value) =>
              onChanged(config.copyWith(backgroundColor: value)),
        ),
        const SizedBox(height: 14),
        _LifeColorField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.secondary_color.7184edaa9dc2',
          ),
          value: config.secondaryBackgroundColor,
          options: _barrageBackgroundColors,
          onChanged: (value) =>
              onChanged(config.copyWith(secondaryBackgroundColor: value)),
        ),
      ],
    );
  }
}

class _BarrageImmersivePage extends StatefulWidget {
  const _BarrageImmersivePage({required this.config});

  final _BarrageConfig config;

  @override
  State<_BarrageImmersivePage> createState() => _BarrageImmersivePageState();
}

class _BarrageImmersivePageState extends State<_BarrageImmersivePage> {
  bool _showHud = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    if (widget.config.orientation == _BarrageOrientation.portrait) {
      unawaited(_enterLifePortraitImmersive(brightness: 1.0));
    } else {
      unawaited(_enterLifeLandscapeImmersive(brightness: 1.0));
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    unawaited(_exitLifeImmersive());
    super.dispose();
  }

  void _revealHud() {
    setState(() => _showHud = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showHud = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.config.backgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _revealHud,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: RepaintBoundary(
                child: _BarrageStage(config: widget.config),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              right: _showHud ? 16 : -58,
              top: 16,
              child: SafeArea(
                child: IconButton.filledTonal(
                  tooltip: _lifeI18nText(
                    context,
                    'inline.plan295.life.exit.e8b4f278b5e3',
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarrageStage extends StatefulWidget {
  const _BarrageStage({required this.config, this.preview = false});

  final _BarrageConfig config;
  final bool preview;

  @override
  State<_BarrageStage> createState() => _BarrageStageState();
}

class _BarrageStageState extends State<_BarrageStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durationForSpeed(widget.config.speed),
    );
    _syncController();
  }

  @override
  void didUpdateWidget(covariant _BarrageStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.speed != widget.config.speed ||
        oldWidget.config.motion != widget.config.motion ||
        oldWidget.preview != widget.preview) {
      _controller.duration = _durationForSpeed(widget.config.speed);
      _syncController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncController() {
    if (widget.preview || widget.config.motion == _BarrageMotion.still) {
      _controller.stop();
      _controller.value = 0;
      return;
    }
    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  Duration _durationForSpeed(double speed) {
    return Duration(milliseconds: (11000 / speed.clamp(0.4, 3.0)).round());
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _backgroundDecoration(widget.config),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final text = _effectiveText(widget.config.text);
          final displayFontSize = widget.preview
              ? math.min(widget.config.fontSize, constraints.maxHeight * 0.33)
              : widget.config.fontSize;
          final style = TextStyle(
            color: widget.config.textColor,
            fontSize: displayFontSize,
            fontWeight: widget.config.bold ? FontWeight.w900 : FontWeight.w600,
            fontFamily: _fontFamily(widget.config.fontStyle),
            fontStyle: widget.config.fontStyle == _BarrageFontStyle.serif
                ? FontStyle.italic
                : FontStyle.normal,
            letterSpacing: 0,
            height: 1.04,
            shadows: <Shadow>[
              Shadow(
                color: Colors.black.withValues(alpha: 0.36),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          );
          return ClipRect(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return _motionWrap(constraints: constraints, child: child!);
              },
              child: Center(
                child: _BarrageText(
                  text: text,
                  style: style,
                  scrolling: widget.config.motion == _BarrageMotion.scroll,
                  preview: widget.preview,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _motionWrap({
    required BoxConstraints constraints,
    required Widget child,
  }) {
    final value = _controller.value;
    final motion = widget.preview ? _BarrageMotion.still : widget.config.motion;
    return switch (motion) {
      _BarrageMotion.still => child,
      _BarrageMotion.scroll => Transform.translate(
        offset: Offset(constraints.maxWidth * (1.15 - value * 2.3), 0),
        child: child,
      ),
      _BarrageMotion.flash => Opacity(
        opacity: 0.28 + 0.72 * (0.5 + 0.5 * math.sin(value * math.pi * 12)),
        child: child,
      ),
      _BarrageMotion.shake => Transform.translate(
        offset: Offset(
          math.sin(value * math.pi * 34) * 7,
          math.cos(value * math.pi * 28) * 3,
        ),
        child: child,
      ),
    };
  }

  BoxDecoration _backgroundDecoration(_BarrageConfig config) {
    return switch (config.backgroundMode) {
      _BarrageBackgroundMode.solid => BoxDecoration(
        color: config.backgroundColor,
      ),
      _BarrageBackgroundMode.gradient => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            config.backgroundColor,
            config.secondaryBackgroundColor,
          ],
        ),
      ),
      _BarrageBackgroundMode.spotlight => BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.18, -0.24),
          radius: 1.2,
          colors: <Color>[
            Color.lerp(config.backgroundColor, Colors.white, 0.18)!,
            config.secondaryBackgroundColor,
            config.backgroundColor,
          ],
        ),
      ),
    };
  }

  String _fontFamily(_BarrageFontStyle style) {
    return switch (style) {
      _BarrageFontStyle.rounded => 'sans-serif',
      _BarrageFontStyle.mono => 'monospace',
      _BarrageFontStyle.serif => 'serif',
      _BarrageFontStyle.compact => 'sans-serif-condensed',
    };
  }

  String _effectiveText(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? '...' : trimmed;
  }
}

class _BarrageText extends StatelessWidget {
  const _BarrageText({
    required this.text,
    required this.style,
    required this.scrolling,
    required this.preview,
  });

  final String text;
  final TextStyle style;
  final bool scrolling;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final displayText = scrolling ? text.replaceAll('\n', '  ') : text;
    if (scrolling && !preview) {
      return Text(
        displayText,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        style: style,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(18),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          displayText,
          maxLines: scrolling ? 1 : 3,
          textAlign: TextAlign.center,
          softWrap: !scrolling,
          overflow: TextOverflow.visible,
          style: style,
        ),
      ),
    );
  }
}

part of '../toolbox_life_tools.dart';

enum _ScreenFillLightMode { steady, breathe }

class _ScreenFillLightToolPage extends StatefulWidget {
  const _ScreenFillLightToolPage();

  @override
  State<_ScreenFillLightToolPage> createState() =>
      _ScreenFillLightToolPageState();
}

class _ScreenFillLightToolPageState extends State<_ScreenFillLightToolPage> {
  Color _color = Colors.white;
  double _brightness = 1.0;
  double _warmth = 0;
  _ScreenFillLightMode _mode = _ScreenFillLightMode.steady;

  static const List<_LifeColorOption> _presets = <_LifeColorOption>[
    _LifeColorOption(
      color: Colors.white,
      labelKey: 'toolbox.life.screen_fill_light.preset.white',
    ),
    _LifeColorOption(
      color: Color(0xFFFFE8C2),
      labelKey: 'toolbox.life.screen_fill_light.preset.warm',
    ),
    _LifeColorOption(
      color: Color(0xFFDDEBFF),
      labelKey: 'toolbox.life.screen_fill_light.preset.cool',
    ),
    _LifeColorOption(
      color: Color(0xFFFFD1BD),
      labelKey: 'toolbox.life.screen_fill_light.preset.skin',
    ),
    _LifeColorOption(
      color: Color(0xFFFF4D4D),
      labelKey: 'toolbox.life.screen_fill_light.preset.red',
    ),
    _LifeColorOption(
      color: Color(0xFF34D399),
      labelKey: 'toolbox.life.screen_fill_light.preset.green',
    ),
    _LifeColorOption(
      color: Color(0xFF60A5FA),
      labelKey: 'toolbox.life.screen_fill_light.preset.blue',
    ),
  ];

  Color get _effectiveColor {
    final warmed = _warmth >= 0
        ? Color.lerp(_color, const Color(0xFFFFD08A), _warmth)!
        : Color.lerp(_color, const Color(0xFFD7E8FF), -_warmth)!;
    return Color.lerp(Colors.black, warmed, _brightness)!;
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'toolbox.life.screen_fill_light.title'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.life.screen_fill_light.subtitle',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LifeSettingsPanel(
            title: _lifeI18nText(
              context,
              'toolbox.life.screen_fill_light.stage_title',
            ),
            subtitle: _lifeI18nText(
              context,
              'toolbox.life.screen_fill_light.stage_subtitle',
            ),
            children: <Widget>[
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: _effectiveColor),
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            _lifeI18nText(
                              context,
                              'toolbox.life.screen_fill_light.preview_label',
                            ),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final mode in _ScreenFillLightMode.values)
                    ChoiceChip(
                      selected: _mode == mode,
                      label: Text(_modeLabel(context, mode)),
                      onSelected: (_) => setState(() => _mode = mode),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _LifeColorField(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.screen_fill_light.color',
                ),
                value: _color,
                options: _presets,
                onChanged: (value) => setState(() => _color = value),
              ),
              const SizedBox(height: 14),
              _LifeSliderField(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.screen_fill_light.brightness',
                ),
                valueText: '${(_brightness * 100).round()}%',
                value: _brightness,
                min: 0.1,
                max: 1,
                divisions: 18,
                onChanged: (value) => setState(() => _brightness = value),
              ),
              _LifeSliderField(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.screen_fill_light.temperature',
                ),
                valueText: _warmthLabel(context),
                value: _warmth,
                min: -1,
                max: 1,
                divisions: 20,
                onChanged: (value) => setState(() => _warmth = value),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _openFullscreen,
                icon: const Icon(Icons.fullscreen_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    'toolbox.life.screen_fill_light.open_fullscreen',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeI18nText(
              context,
              'toolbox.life.screen_fill_light.tips_title',
            ),
            subtitle: _lifeI18nText(
              context,
              'toolbox.life.screen_fill_light.tips_body',
            ),
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ToolboxMetricCard(
                    label: _lifeI18nText(
                      context,
                      'toolbox.life.screen_fill_light.metric_mode',
                    ),
                    value: _modeLabel(context, _mode),
                  ),
                  ToolboxMetricCard(
                    label: _lifeI18nText(
                      context,
                      'toolbox.life.screen_fill_light.metric_color',
                    ),
                    value:
                        '#${_effectiveColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                  ),
                  ToolboxMetricCard(
                    label: _lifeI18nText(
                      context,
                      'toolbox.life.screen_fill_light.metric_brightness',
                    ),
                    value: '${(_brightness * 100).round()}%',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _modeLabel(BuildContext context, _ScreenFillLightMode mode) {
    return _lifeI18nText(context, switch (mode) {
      _ScreenFillLightMode.steady =>
        'toolbox.life.screen_fill_light.mode.steady',
      _ScreenFillLightMode.breathe =>
        'toolbox.life.screen_fill_light.mode.breathe',
    });
  }

  String _warmthLabel(BuildContext context) {
    if (_warmth.abs() < 0.05) {
      return _lifeI18nText(
        context,
        'toolbox.life.screen_fill_light.temperature.neutral',
      );
    }
    return _lifeI18nText(
      context,
      _warmth > 0
          ? 'toolbox.life.screen_fill_light.temperature.warm'
          : 'toolbox.life.screen_fill_light.temperature.cool',
      params: <String, Object?>{'value': (_warmth.abs() * 100).round()},
    );
  }

  void _openFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ScreenFillLightFullscreenPage(
          color: _color,
          brightness: _brightness,
          warmth: _warmth,
          mode: _mode,
        ),
      ),
    );
  }
}

class _ScreenFillLightFullscreenPage extends StatefulWidget {
  const _ScreenFillLightFullscreenPage({
    required this.color,
    required this.brightness,
    required this.warmth,
    required this.mode,
  });

  final Color color;
  final double brightness;
  final double warmth;
  final _ScreenFillLightMode mode;

  @override
  State<_ScreenFillLightFullscreenPage> createState() =>
      _ScreenFillLightFullscreenPageState();
}

class _ScreenFillLightFullscreenPageState
    extends State<_ScreenFillLightFullscreenPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
      lowerBound: 0.86,
      upperBound: 1.0,
      value: 1.0,
    );
    if (widget.mode == _ScreenFillLightMode.breathe) {
      _controller.repeat(reverse: true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enterLifePortraitImmersive(brightness: widget.brightness);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _exitLifeImmersive();
    super.dispose();
  }

  Color get _baseColor {
    final warmed = widget.warmth >= 0
        ? Color.lerp(widget.color, const Color(0xFFFFD08A), widget.warmth)!
        : Color.lerp(widget.color, const Color(0xFFD7E8FF), -widget.warmth)!;
    return Color.lerp(Colors.black, warmed, widget.brightness)!;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final color = Color.lerp(Colors.black, _baseColor, _controller.value)!;
        return GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: Scaffold(
            backgroundColor: color,
            body: SafeArea(
              child: Stack(
                children: <Widget>[
                  const SizedBox.expand(),
                  AnimatedPositioned(
                    duration: AppDurations.quick,
                    curve: AppEasing.standard,
                    left: 16,
                    right: 16,
                    bottom: _showControls ? 18 : -96,
                    child: AnimatedOpacity(
                      duration: AppDurations.quick,
                      opacity: _showControls ? 1 : 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  _lifeI18nText(
                                    context,
                                    'toolbox.life.screen_fill_light.fullscreen_hint',
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.white),
                                ),
                              ),
                              IconButton.filledTonal(
                                tooltip: MaterialLocalizations.of(
                                  context,
                                ).closeButtonTooltip,
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

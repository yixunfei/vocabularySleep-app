part of '../toolbox_life_tools.dart';

enum _ClockThemePreset { ivory, night, graphite, ember, lagoon }

enum _ClockFontStyle { rounded, classic, mono, slim }

enum _ClockTimeFormat { hms24, hm24, hms12, hm12 }

enum _ClockBackgroundStyle { solid, soft, radial }

class _ClockStyleConfig {
  const _ClockStyleConfig({
    required this.themePreset,
    required this.fontStyle,
    required this.timeFormat,
    required this.flipStyle,
    required this.backgroundStyle,
    required this.fontScale,
    required this.cardRadius,
    required this.showDate,
    required this.showWeekday,
  });

  final _ClockThemePreset themePreset;
  final _ClockFontStyle fontStyle;
  final _ClockTimeFormat timeFormat;
  final _ClockFlipStyle flipStyle;
  final _ClockBackgroundStyle backgroundStyle;
  final double fontScale;
  final double cardRadius;
  final bool showDate;
  final bool showWeekday;

  bool get showSeconds {
    return timeFormat == _ClockTimeFormat.hms24 ||
        timeFormat == _ClockTimeFormat.hms12;
  }

  _ClockStyleConfig copyWith({
    _ClockThemePreset? themePreset,
    _ClockFontStyle? fontStyle,
    _ClockTimeFormat? timeFormat,
    _ClockFlipStyle? flipStyle,
    _ClockBackgroundStyle? backgroundStyle,
    double? fontScale,
    double? cardRadius,
    bool? showDate,
    bool? showWeekday,
  }) {
    return _ClockStyleConfig(
      themePreset: themePreset ?? this.themePreset,
      fontStyle: fontStyle ?? this.fontStyle,
      timeFormat: timeFormat ?? this.timeFormat,
      flipStyle: flipStyle ?? this.flipStyle,
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
      fontScale: fontScale ?? this.fontScale,
      cardRadius: cardRadius ?? this.cardRadius,
      showDate: showDate ?? this.showDate,
      showWeekday: showWeekday ?? this.showWeekday,
    );
  }
}

class _ClockThemeTokens {
  const _ClockThemeTokens({
    required this.nameKey,
    required this.background,
    required this.panel,
    required this.panelAlt,
    required this.digit,
    required this.muted,
    required this.divider,
    required this.shadow,
  });

  final String nameKey;
  final Color background;
  final Color panel;
  final Color panelAlt;
  final Color digit;
  final Color muted;
  final Color divider;
  final Color shadow;

  String name(BuildContext context) {
    return _lifeI18nText(context, nameKey);
  }
}

const Map<_ClockThemePreset, _ClockThemeTokens> _clockThemes =
    <_ClockThemePreset, _ClockThemeTokens>{
      _ClockThemePreset.ivory: _ClockThemeTokens(
        nameKey: 'inline.plan295.life.ivory_flip.d9c35948894d',
        background: Color(0xFFF7F4EE),
        panel: Color(0xFFFFFCF6),
        panelAlt: Color(0xFFF1ECE2),
        digit: Color(0xFF0D0C0A),
        muted: Color(0xFF746D61),
        divider: Color(0x1F1C1A16),
        shadow: Color(0x18000000),
      ),
      _ClockThemePreset.night: _ClockThemeTokens(
        nameKey: 'inline.plan295.life.night_clock.067c947eca90',
        background: Color(0xFF050608),
        panel: Color(0xFF15171C),
        panelAlt: Color(0xFF0E1014),
        digit: Color(0xFFF6F7FB),
        muted: Color(0xFFA8AEBB),
        divider: Color(0x40FFFFFF),
        shadow: Color(0x70000000),
      ),
      _ClockThemePreset.graphite: _ClockThemeTokens(
        nameKey: 'inline.plan295.life.graphite.0c212911ff16',
        background: Color(0xFF1B1F23),
        panel: Color(0xFFE7E1D7),
        panelAlt: Color(0xFFD6CDC0),
        digit: Color(0xFF111315),
        muted: Color(0xFFB8B2A9),
        divider: Color(0x26111315),
        shadow: Color(0x50000000),
      ),
      _ClockThemePreset.ember: _ClockThemeTokens(
        nameKey: 'inline.plan295.life.warm_ember.88d4fb8e9e64',
        background: Color(0xFF221512),
        panel: Color(0xFFF5D0A7),
        panelAlt: Color(0xFFE4B982),
        digit: Color(0xFF23120E),
        muted: Color(0xFFE7B18F),
        divider: Color(0x3823120E),
        shadow: Color(0x66000000),
      ),
      _ClockThemePreset.lagoon: _ClockThemeTokens(
        nameKey: 'inline.plan295.life.quiet_lagoon.dbd20e7d64b8',
        background: Color(0xFF09242F),
        panel: Color(0xFFE8F2EF),
        panelAlt: Color(0xFFC8DCD6),
        digit: Color(0xFF062029),
        muted: Color(0xFF9CC8C3),
        divider: Color(0x33062029),
        shadow: Color(0x60000000),
      ),
    };

const List<_LifeOption<_ClockThemePreset>> _clockThemeOptions =
    <_LifeOption<_ClockThemePreset>>[
      _LifeOption(
        value: _ClockThemePreset.ivory,
        labelKey: 'inline.plan295.life.ivory.56bc1d90ab23',
      ),
      _LifeOption(
        value: _ClockThemePreset.night,
        labelKey: 'inline.plan295.life.night.217935fe567a',
      ),
      _LifeOption(
        value: _ClockThemePreset.graphite,
        labelKey: 'inline.plan295.life.graphite.8dca072e3941',
      ),
      _LifeOption(
        value: _ClockThemePreset.ember,
        labelKey: 'inline.plan295.life.ember.53c5dc771822',
      ),
      _LifeOption(
        value: _ClockThemePreset.lagoon,
        labelKey: 'inline.plan295.life.lagoon.b8b42787f83c',
      ),
    ];

const List<_LifeOption<_ClockFontStyle>> _clockFontOptions =
    <_LifeOption<_ClockFontStyle>>[
      _LifeOption(
        value: _ClockFontStyle.rounded,
        labelKey: 'inline.plan295.life.rounded.467a787ced2f',
      ),
      _LifeOption(
        value: _ClockFontStyle.classic,
        labelKey: 'inline.ui.pages.toolbox_human_tests_action.classic_3e1072',
      ),
      _LifeOption(
        value: _ClockFontStyle.mono,
        labelKey: 'inline.plan295.life.mono.6193ef478e21',
      ),
      _LifeOption(
        value: _ClockFontStyle.slim,
        labelKey: 'inline.plan295.life.slim.7fa259041d60',
      ),
    ];

const List<_LifeOption<_ClockTimeFormat>> _clockFormatOptions =
    <_LifeOption<_ClockTimeFormat>>[
      _LifeOption(
        value: _ClockTimeFormat.hms24,
        labelKey: 'inline.plan295.life.24h_with_sec.2f1213d35118',
      ),
      _LifeOption(
        value: _ClockTimeFormat.hm24,
        labelKey: 'inline.plan295.life.24h.d2c297503418',
      ),
      _LifeOption(
        value: _ClockTimeFormat.hms12,
        labelKey: 'inline.plan295.life.12h_with_sec.eb472ceb77f8',
      ),
      _LifeOption(
        value: _ClockTimeFormat.hm12,
        labelKey: 'inline.plan295.life.12h.c63a572fa9a9',
      ),
    ];

const List<_LifeOption<_ClockBackgroundStyle>> _clockBackgroundOptions =
    <_LifeOption<_ClockBackgroundStyle>>[
      _LifeOption(
        value: _ClockBackgroundStyle.solid,
        labelKey: 'inline.plan295.life.solid.ab6af9a81131',
      ),
      _LifeOption(
        value: _ClockBackgroundStyle.soft,
        labelKey: 'inline.plan295.life.soft.d5fe26d4c3f6',
      ),
      _LifeOption(
        value: _ClockBackgroundStyle.radial,
        labelKey: 'inline.plan295.life.radial.a24cd5824cb2',
      ),
    ];

class _TimeScreenToolPage extends StatefulWidget {
  const _TimeScreenToolPage();

  @override
  State<_TimeScreenToolPage> createState() => _TimeScreenToolPageState();
}

class _TimeScreenToolPageState extends State<_TimeScreenToolPage> {
  _ClockStyleConfig _config = const _ClockStyleConfig(
    themePreset: _ClockThemePreset.ivory,
    fontStyle: _ClockFontStyle.rounded,
    timeFormat: _ClockTimeFormat.hms24,
    flipStyle: _ClockFlipStyle.classic,
    backgroundStyle: _ClockBackgroundStyle.solid,
    fontScale: 1.0,
    cardRadius: 22,
    showDate: true,
    showWeekday: true,
  );

  void _updateConfig(_ClockStyleConfig config) {
    setState(() => _config = config);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.time_screen.62f5d9ae9d5d',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.landscape_fullscreen_flip_clock_tap.0d10d0a6e90f',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: _lifeI18nText(
              context,
              'inline.plan295.life.clock_preview.5c18f911f120',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.life.fullscreen_keeps_the_screen_awake_br.ad13f949928a',
            ),
          ),
          const SizedBox(height: 12),
          _LifePreviewFrame(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _ClockStage(now: now, config: _config, preview: true),
            ),
          ),
          const SizedBox(height: 16),
          _ClockSettingsPanel(
            config: _config,
            onChanged: _updateConfig,
            compact: false,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    fullscreenDialog: true,
                    builder: (_) => _ClockImmersivePage(initialConfig: _config),
                  ),
                );
              },
              icon: const Icon(Icons.fullscreen_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.open_fullscreen_clock.007d3fa1ad62',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockSettingsPanel extends StatelessWidget {
  const _ClockSettingsPanel({
    required this.config,
    required this.onChanged,
    required this.compact,
  });

  final _ClockStyleConfig config;
  final ValueChanged<_ClockStyleConfig> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.clock_settings.9b3cc1d07d52',
      ),
      subtitle: compact
          ? _lifeI18nText(
              context,
              'inline.plan295.life.changes_apply_immediately_tap_empty.31c315ec21bf',
            )
          : null,
      children: <Widget>[
        _LifeSegmentedField<_ClockThemePreset>(
          label: _lifeI18nText(context, 'appearanceThemeTitle'),
          value: config.themePreset,
          options: _clockThemeOptions,
          onChanged: (value) => onChanged(config.copyWith(themePreset: value)),
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<_ClockFontStyle>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.font_style.2d97e13275d4',
          ),
          value: config.fontStyle,
          options: _clockFontOptions,
          onChanged: (value) => onChanged(config.copyWith(fontStyle: value)),
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<_ClockTimeFormat>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.time_format.da279813183a',
          ),
          value: config.timeFormat,
          options: _clockFormatOptions,
          onChanged: (value) => onChanged(config.copyWith(timeFormat: value)),
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<_ClockFlipStyle>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.flip_animation.e944f2c54001',
          ),
          value: config.flipStyle,
          options: _clockFlipOptions,
          onChanged: (value) => onChanged(config.copyWith(flipStyle: value)),
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<_ClockBackgroundStyle>(
          label: _lifeI18nText(context, 'appearanceBackgroundTitle'),
          value: config.backgroundStyle,
          options: _clockBackgroundOptions,
          onChanged: (value) =>
              onChanged(config.copyWith(backgroundStyle: value)),
        ),
        const SizedBox(height: 14),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.digit_size.6832c7b7bade',
          ),
          valueText: '${(config.fontScale * 100).round()}%',
          value: config.fontScale,
          min: 0.82,
          max: 1.38,
          divisions: 14,
          onChanged: (value) => onChanged(config.copyWith(fontScale: value)),
        ),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.card_radius.7b2651497a03',
          ),
          valueText: config.cardRadius.round().toString(),
          value: config.cardRadius,
          min: 6,
          max: 36,
          divisions: 15,
          onChanged: (value) => onChanged(config.copyWith(cardRadius: value)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: config.showDate,
          title: Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.show_date.af8164a6c9d2',
            ),
          ),
          onChanged: (value) => onChanged(config.copyWith(showDate: value)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: config.showWeekday,
          title: Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.show_weekday.d78253e7d478',
            ),
          ),
          onChanged: (value) => onChanged(config.copyWith(showWeekday: value)),
        ),
      ],
    );
  }
}

class _ClockImmersivePage extends StatefulWidget {
  const _ClockImmersivePage({required this.initialConfig});

  final _ClockStyleConfig initialConfig;

  @override
  State<_ClockImmersivePage> createState() => _ClockImmersivePageState();
}

class _ClockImmersivePageState extends State<_ClockImmersivePage> {
  late _ClockStyleConfig _config = widget.initialConfig;
  late Timer _timer;
  DateTime _now = DateTime.now();
  bool _showHud = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
    unawaited(_enterLifeLandscapeImmersive(brightness: 1.0));
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _timer.cancel();
    unawaited(_exitLifeImmersive());
    super.dispose();
  }

  void _revealHud() {
    setState(() => _showHud = true);
    _scheduleHideHud();
  }

  void _scheduleHideHud() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && Navigator.of(context).canPop()) {
        setState(() => _showHud = false);
      }
    });
  }

  void _openSettingsSheet() {
    _hideTimer?.cancel();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.82,
                  ),
                  child: SingleChildScrollView(
                    child: _ClockSettingsPanel(
                      config: _config,
                      compact: true,
                      onChanged: (value) {
                        setState(() => _config = value);
                        setSheetState(() {});
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(_scheduleHideHud);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: _clockThemes[_config.themePreset]!.background,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _revealHud,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: RepaintBoundary(
                  child: _ClockStage(now: _now, config: _config),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_showHud,
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        offset: _showHud ? Offset.zero : const Offset(1.45, 0),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 16, 16, 0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton.filledTonal(
                                tooltip: _lifeI18nText(
                                  context,
                                  'inline.plan295.life.settings.d2e7a37558b9',
                                ),
                                onPressed: _openSettingsSheet,
                                icon: const Icon(Icons.tune_rounded),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                tooltip: _lifeI18nText(
                                  context,
                                  'inline.plan295.life.exit.a5965eb7937a',
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                        ),
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
  }
}

class _ClockStage extends StatelessWidget {
  const _ClockStage({
    required this.now,
    required this.config,
    this.preview = false,
  });

  final DateTime now;
  final _ClockStyleConfig config;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final tokens = _clockThemes[config.themePreset]!;
    return DecoratedBox(
      decoration: _clockBackgroundDecoration(tokens, config.backgroundStyle),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = math.min(constraints.maxWidth, constraints.maxHeight);
          final stageSize = preview
              ? math.min(size * 0.92, constraints.maxWidth)
              : size * 0.94;
          return Center(
            child: SizedBox.square(
              dimension: stageSize,
              child: _ClockFace(now: now, config: config, preview: preview),
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _clockBackgroundDecoration(
    _ClockThemeTokens tokens,
    _ClockBackgroundStyle style,
  ) {
    return switch (style) {
      _ClockBackgroundStyle.solid => BoxDecoration(color: tokens.background),
      _ClockBackgroundStyle.soft => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[tokens.background, tokens.panelAlt],
        ),
      ),
      _ClockBackgroundStyle.radial => BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.18, -0.22),
          radius: 1.15,
          colors: <Color>[
            Color.lerp(tokens.background, tokens.panel, 0.24)!,
            tokens.background,
          ],
        ),
      ),
    };
  }
}

class _ClockFace extends StatelessWidget {
  const _ClockFace({
    required this.now,
    required this.config,
    required this.preview,
  });

  final DateTime now;
  final _ClockStyleConfig config;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final tokens = _clockThemes[config.themePreset]!;
    final values = _clockValues(now, config.timeFormat);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final tileGap = math.max(5.0, width * 0.03);
        final dateHeight = (config.showDate || config.showWeekday)
            ? width * 0.115
            : 0.0;
        final tileHeight = math.max(0.0, width - dateHeight - tileGap);
        final tileWidth =
            (width - tileGap * (values.parts.length - 1)) / values.parts.length;
        final fontSize =
            tileWidth *
            _fontSizeFactor(config.fontStyle, values.parts.length) *
            config.fontScale;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: tileHeight,
              child: Row(
                children: <Widget>[
                  for (var i = 0; i < values.parts.length; i += 1) ...<Widget>[
                    Expanded(
                      child: _FlipNumberTile(
                        value: values.parts[i],
                        tokens: tokens,
                        fontStyle: config.fontStyle,
                        fontSize: fontSize,
                        radius: config.cardRadius,
                        preview: preview,
                        flipStyle: config.flipStyle,
                      ),
                    ),
                    if (i != values.parts.length - 1) SizedBox(width: tileGap),
                  ],
                ],
              ),
            ),
            if (dateHeight > 0) ...<Widget>[
              SizedBox(height: tileGap),
              SizedBox(
                height: dateHeight,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _clockDateLabel(context, now, config),
                      maxLines: 1,
                      style: TextStyle(
                        color: tokens.muted,
                        fontSize: width * 0.052,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  double _fontSizeFactor(_ClockFontStyle style, int partCount) {
    final base = partCount >= 3 ? 0.48 : 0.56;
    return switch (style) {
      _ClockFontStyle.rounded => base,
      _ClockFontStyle.classic => base * 1.03,
      _ClockFontStyle.mono => base * 0.92,
      _ClockFontStyle.slim => base * 0.98,
    };
  }
}

class _ClockValues {
  const _ClockValues(this.parts);

  final List<String> parts;
}

_ClockValues _clockValues(DateTime now, _ClockTimeFormat format) {
  final is12 =
      format == _ClockTimeFormat.hms12 || format == _ClockTimeFormat.hm12;
  var hour = now.hour;
  if (is12) {
    hour = hour % 12;
    if (hour == 0) {
      hour = 12;
    }
  }
  final parts = <String>[
    hour.toString().padLeft(2, '0'),
    now.minute.toString().padLeft(2, '0'),
  ];
  if (format == _ClockTimeFormat.hms24 || format == _ClockTimeFormat.hms12) {
    parts.add(now.second.toString().padLeft(2, '0'));
  }
  return _ClockValues(parts);
}

String _clockDateLabel(
  BuildContext context,
  DateTime now,
  _ClockStyleConfig config,
) {
  final date = config.showDate
      ? '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}'
      : '';
  final weekday = config.showWeekday ? _weekdayName(context, now.weekday) : '';
  if (date.isEmpty) {
    return weekday;
  }
  if (weekday.isEmpty) {
    return date;
  }
  return '$date  $weekday';
}

String _weekdayName(BuildContext context, int weekday) {
  final key = switch (weekday) {
    DateTime.monday => 'life.time_screen.weekday.monday',
    DateTime.tuesday => 'life.time_screen.weekday.tuesday',
    DateTime.wednesday => 'life.time_screen.weekday.wednesday',
    DateTime.thursday => 'life.time_screen.weekday.thursday',
    DateTime.friday => 'life.time_screen.weekday.friday',
    DateTime.saturday => 'life.time_screen.weekday.saturday',
    _ => 'life.time_screen.weekday.sunday',
  };
  return _lifeI18nText(context, key);
}

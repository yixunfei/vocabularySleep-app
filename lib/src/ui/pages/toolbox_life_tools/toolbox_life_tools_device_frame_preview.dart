part of '../toolbox_life_tools.dart';

class _DeviceFramePreviewStage extends StatelessWidget {
  const _DeviceFramePreviewStage({
    required this.image,
    required this.preset,
    required this.background,
    required this.statusTone,
    required this.statusSettings,
    required this.showStatusBar,
    required this.showGlare,
    required this.canvasPadding,
    required this.screenFit,
  });

  final ui.Image? image;
  final _DeviceFramePreset preset;
  final _DeviceFrameBackground background;
  final _DeviceFrameStatusTone statusTone;
  final _DeviceFrameStatusSettings statusSettings;
  final bool showStatusBar;
  final bool showGlare;
  final double canvasPadding;
  final _DeviceFrameScreenFit screenFit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      key: const ValueKey<String>('life-device-frame-preview-stage'),
      aspectRatio: 4 / 5.35,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: _backgroundGradient(background),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.86),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.20),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.08),
                      ],
                      stops: const <double>[0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(canvasPadding),
                child: image == null
                    ? _DeviceFrameEmptyState(theme: theme)
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final sourceImage = image!;
                          final spec = preset == _DeviceFramePreset.clean
                              ? null
                              : _specForPreset(preset);
                          final previewAspect = spec?.canvasSize.width != null
                              ? spec!.canvasSize.width / spec.canvasSize.height
                              : sourceImage.width / sourceImage.height;
                          final widthByHeight =
                              constraints.maxHeight * previewAspect;
                          final targetWidth = math.min(
                            constraints.maxWidth,
                            math.min(widthByHeight, 360.0),
                          );

                          return Center(
                            child: preset == _DeviceFramePreset.clean
                                ? _DevicePosterCard(
                                    image: sourceImage,
                                    width: targetWidth,
                                    statusTone: statusTone,
                                    statusSettings: statusSettings,
                                    showStatusBar: showStatusBar,
                                    screenFit: screenFit,
                                  )
                                : _DeviceMockupWidget(
                                    image: sourceImage,
                                    width: targetWidth,
                                    spec: spec!,
                                    statusTone: statusTone,
                                    statusSettings: statusSettings,
                                    showStatusBar: showStatusBar,
                                    showGlare: showGlare,
                                    screenFit: screenFit,
                                  ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Gradient _backgroundGradient(_DeviceFrameBackground background) {
    return switch (background) {
      _DeviceFrameBackground.studio => const LinearGradient(
        colors: <Color>[
          Color(0xFFF7EFE6),
          Color(0xFFE6D6CA),
          Color(0xFFD5C0AF),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      _DeviceFrameBackground.aurora => const LinearGradient(
        colors: <Color>[
          Color(0xFFE8FFF7),
          Color(0xFFD2F6EA),
          Color(0xFFA6D5F4),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      _DeviceFrameBackground.midnight => const LinearGradient(
        colors: <Color>[
          Color(0xFF232A38),
          Color(0xFF121924),
          Color(0xFF080B11),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    };
  }
}

class _DeviceFrameEmptyState extends StatelessWidget {
  const _DeviceFrameEmptyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        key: const ValueKey<String>('life-device-frame-empty'),
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.add_photo_alternate_rounded,
            size: 34,
            color: Colors.white.withValues(alpha: 0.92),
          ),
          const SizedBox(height: 12),
          Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.pick_a_local_screenshot_first.b43b91026384',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.96),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.then_choose_the_mockup_backdrop_fit.be90f5795a76',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _DevicePosterCard extends StatelessWidget {
  const _DevicePosterCard({
    required this.image,
    required this.width,
    required this.statusTone,
    required this.statusSettings,
    required this.showStatusBar,
    required this.screenFit,
  });

  final ui.Image image;
  final double width;
  final _DeviceFrameStatusTone statusTone;
  final _DeviceFrameStatusSettings statusSettings;
  final bool showStatusBar;
  final _DeviceFrameScreenFit screenFit;

  @override
  Widget build(BuildContext context) {
    final screenAspect = image.width / image.height;
    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: screenAspect,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 36,
                offset: const Offset(0, 22),
              ),
            ],
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFFF6F2EE), Color(0xFFE5DBD3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  ColoredBox(
                    color: const Color(0xFF10151D),
                    child: RawImage(
                      image: image,
                      fit: _boxFitFor(screenFit),
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.54),
                      ),
                    ),
                  ),
                  if (showStatusBar)
                    _DeviceStatusBar(
                      tone: statusTone,
                      layout: _DeviceFrameStatusLayout.openTop,
                      settings: statusSettings,
                      topPadding: 12,
                      horizontalPadding: 14,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceMockupWidget extends StatelessWidget {
  const _DeviceMockupWidget({
    required this.image,
    required this.width,
    required this.spec,
    required this.statusTone,
    required this.statusSettings,
    required this.showStatusBar,
    required this.showGlare,
    required this.screenFit,
  });

  final ui.Image image;
  final double width;
  final _DeviceFrameSpec spec;
  final _DeviceFrameStatusTone statusTone;
  final _DeviceFrameStatusSettings statusSettings;
  final bool showStatusBar;
  final bool showGlare;
  final _DeviceFrameScreenFit screenFit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: spec.canvasSize.width / spec.canvasSize.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stageWidth = constraints.maxWidth;
            final stageHeight = constraints.maxHeight;
            final screenRect = Rect.fromLTWH(
              stageWidth * (spec.screenRect.left / spec.canvasSize.width),
              stageHeight * (spec.screenRect.top / spec.canvasSize.height),
              stageWidth * (spec.screenRect.width / spec.canvasSize.width),
              stageHeight * (spec.screenRect.height / spec.canvasSize.height),
            );
            final radius =
                stageWidth * (spec.screenRadius / spec.canvasSize.width);

            return Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned.fill(
                  child: Image.asset(
                    spec.shadowAssetPath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                Positioned.fromRect(
                  rect: screenRect,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        ColoredBox(
                          color: const Color(0xFF10151D),
                          child: RawImage(
                            image: image,
                            fit: _boxFitFor(screenFit),
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                        if (showStatusBar)
                          _DeviceStatusBar(
                            tone: statusTone,
                            layout: spec.statusLayout,
                            settings: statusSettings,
                            topPadding: spec.statusTopPadding,
                            horizontalPadding: spec.statusHorizontalPadding,
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Image.asset(
                    spec.frameAssetPath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                if (showGlare)
                  Positioned.fill(
                    child: Image.asset(
                      spec.glareAssetPath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

BoxFit _boxFitFor(_DeviceFrameScreenFit fit) {
  return switch (fit) {
    _DeviceFrameScreenFit.cover => BoxFit.cover,
    _DeviceFrameScreenFit.contain => BoxFit.contain,
  };
}

class _DeviceStatusBar extends StatelessWidget {
  const _DeviceStatusBar({
    required this.tone,
    required this.layout,
    required this.settings,
    required this.topPadding,
    required this.horizontalPadding,
  });

  final _DeviceFrameStatusTone tone;
  final _DeviceFrameStatusLayout layout;
  final _DeviceFrameStatusSettings settings;
  final double topPadding;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final foreground = tone == _DeviceFrameStatusTone.light
        ? Colors.white
        : const Color(0xFF11131A);
    final overlay = tone == _DeviceFrameStatusTone.light
        ? Colors.black.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.22);

    return Align(
      alignment: Alignment.topCenter,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[overlay, Colors.transparent],
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding,
              horizontalPadding,
              10,
            ),
            child: Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    settings.timeText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * 0.48,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: _DeviceStatusIndicators(
                        foreground: foreground,
                        settings: settings,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DeviceStatusIndicators extends StatelessWidget {
  const _DeviceStatusIndicators({
    required this.foreground,
    required this.settings,
  });

  final Color foreground;
  final _DeviceFrameStatusSettings settings;

  bool get _showNetworkText =>
      settings.networkType != _DeviceFrameNetworkType.none &&
      settings.networkType != _DeviceFrameNetworkType.wifiOnly;

  bool get _showCellularBars =>
      settings.networkType != _DeviceFrameNetworkType.none &&
      settings.networkType != _DeviceFrameNetworkType.wifiOnly;

  String get _networkLabel {
    return switch (settings.networkType) {
      _DeviceFrameNetworkType.none => '',
      _DeviceFrameNetworkType.edge => 'E',
      _DeviceFrameNetworkType.fourG => '4G',
      _DeviceFrameNetworkType.fiveG => '5G',
      _DeviceFrameNetworkType.lte => 'LTE',
      _DeviceFrameNetworkType.wifiOnly => 'Wi-Fi',
    };
  }

  @override
  Widget build(BuildContext context) {
    final batteryColor = _batteryStatusColor(settings, foreground);
    final children = <Widget>[
      if (_showCellularBars)
        _DeviceSignalGlyph(level: settings.signalLevel, color: foreground),
      if (_showNetworkText) const SizedBox(width: 3),
      if (_showNetworkText)
        Text(
          _networkLabel,
          style: TextStyle(
            color: foreground,
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      if (settings.showWifi) const SizedBox(width: 4),
      if (settings.showWifi)
        Opacity(
          opacity: 0.4 + (settings.wifiStrength / 3) * 0.6,
          child: Icon(Icons.wifi_rounded, size: 11.5, color: foreground),
        ),
      const SizedBox(width: 4),
      if (settings.showBatteryPercent)
        Text(
          '${settings.batteryPercent}%',
          style: TextStyle(
            color: batteryColor,
            fontSize: 8.8,
            fontWeight: FontWeight.w700,
          ),
        ),
      if (settings.showBatteryPercent) const SizedBox(width: 3),
      _DeviceBatteryGlyph(
        percent: settings.batteryPercent,
        charging: settings.charging,
        color: batteryColor,
      ),
    ];

    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  Color _batteryStatusColor(
    _DeviceFrameStatusSettings settings,
    Color foreground,
  ) {
    if (settings.charging) {
      return const Color(0xFF22C55E);
    }
    if (settings.batteryPercent < 15) {
      return const Color(0xFFEF4444);
    }
    if (settings.batteryPercent < 30) {
      return const Color(0xFFF59E0B);
    }
    return foreground;
  }
}

class _DeviceSignalGlyph extends StatelessWidget {
  const _DeviceSignalGlyph({required this.level, required this.color});

  final int level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 10.5,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: List<Widget>.generate(4, (index) {
          final barHeight = 2.6 + index * 1.8;
          final active = index < level;
          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 1),
            child: Container(
              width: 2,
              height: barHeight,
              decoration: BoxDecoration(
                color: active ? color : color.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DeviceBatteryGlyph extends StatelessWidget {
  const _DeviceBatteryGlyph({
    required this.percent,
    required this.charging,
    required this.color,
  });

  final int percent;
  final bool charging;
  final Color color;

  IconData get _icon {
    if (charging) {
      return Icons.battery_charging_full_rounded;
    }
    if (percent < 15) {
      return Icons.battery_alert_rounded;
    }
    if (percent < 30) {
      return Icons.battery_2_bar_rounded;
    }
    if (percent >= 90) {
      return Icons.battery_full_rounded;
    }
    if (percent >= 65) {
      return Icons.battery_5_bar_rounded;
    }
    if (percent >= 45) {
      return Icons.battery_4_bar_rounded;
    }
    if (percent >= 25) {
      return Icons.battery_3_bar_rounded;
    }
    if (percent >= 10) {
      return Icons.battery_2_bar_rounded;
    }
    return Icons.battery_1_bar_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Icon(_icon, size: 13.5, color: color);
  }
}

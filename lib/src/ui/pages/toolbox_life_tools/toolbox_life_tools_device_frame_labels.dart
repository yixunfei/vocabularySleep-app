part of '../toolbox_life_tools.dart';

String _deviceFramePresetLabel(
  BuildContext context,
  _DeviceFramePreset preset,
) {
  return switch (preset) {
    _DeviceFramePreset.clean => _lifeI18nText(
      context,
      'inline.plan295.life.clean_poster.7d0c9009a20f',
    ),
    _DeviceFramePreset.titanium => _lifeI18nText(
      context,
      'inline.plan295.life.titanium_island.cc96da6b5d71',
    ),
    _DeviceFramePreset.obsidian => _lifeI18nText(
      context,
      'inline.plan295.life.obsidian_island.d979f2c453f2',
    ),
    _DeviceFramePreset.graphite => _lifeI18nText(
      context,
      'inline.plan295.life.graphite_hole_punch.6a404cab7936',
    ),
    _DeviceFramePreset.frost => _lifeI18nText(
      context,
      'inline.plan295.life.frost_hole_punch.767828eb59af',
    ),
  };
}

String _deviceFrameScreenFitLabel(
  BuildContext context,
  _DeviceFrameScreenFit fit,
) {
  return switch (fit) {
    _DeviceFrameScreenFit.cover => _lifeI18nText(
      context,
      'inline.plan295.life.fill_screen.c130d99e73b9',
    ),
    _DeviceFrameScreenFit.contain => _lifeI18nText(
      context,
      'inline.plan295.life.fit_whole_image.889f3cf4dea8',
    ),
  };
}

String _deviceFrameNetworkTypeLabel(
  BuildContext context,
  _DeviceFrameNetworkType type,
) {
  return switch (type) {
    _DeviceFrameNetworkType.none => _lifeI18nText(
      context,
      'inline.plan295.life.no_text.6957581eab69',
    ),
    _DeviceFrameNetworkType.edge => 'E',
    _DeviceFrameNetworkType.fourG => '4G',
    _DeviceFrameNetworkType.fiveG => '5G',
    _DeviceFrameNetworkType.lte => 'LTE',
    _DeviceFrameNetworkType.wifiOnly => _lifeI18nText(
      context,
      'inline.plan295.life.wi_fi_only.0991304ffff5',
    ),
  };
}

String _deviceFrameBatteryStatusLabel(
  BuildContext context,
  _DeviceFrameStatusSettings settings,
) {
  if (settings.charging) {
    return _lifeI18nText(context, 'inline.plan295.life.charging.5f9c2df896d8');
  }
  if (settings.batteryPercent < 15) {
    return _lifeI18nText(
      context,
      'inline.plan295.life.insufficient.cf948d195a8f',
    );
  }
  if (settings.batteryPercent < 30) {
    return _lifeI18nText(context, 'inline.plan295.life.low_power.4dd02880a97b');
  }
  return _lifeI18nText(context, 'inline.plan295.life.normal.9bb1bde439bb');
}

part of '../toolbox_life_tools.dart';

String _deviceFramePresetLabel(
  BuildContext context,
  _DeviceFramePreset preset,
) {
  return switch (preset) {
    _DeviceFramePreset.clean => _lifeText(
      context,
      zh: '无壳海报',
      en: 'Clean poster',
    ),
    _DeviceFramePreset.titanium => _lifeText(
      context,
      zh: '钛金灵动岛',
      en: 'Titanium island',
    ),
    _DeviceFramePreset.obsidian => _lifeText(
      context,
      zh: '曜石灵动岛',
      en: 'Obsidian island',
    ),
    _DeviceFramePreset.graphite => _lifeText(
      context,
      zh: '石墨挖孔屏',
      en: 'Graphite hole-punch',
    ),
    _DeviceFramePreset.frost => _lifeText(
      context,
      zh: '冰霜银挖孔屏',
      en: 'Frost hole-punch',
    ),
  };
}

String _deviceFrameScreenFitLabel(
  BuildContext context,
  _DeviceFrameScreenFit fit,
) {
  return switch (fit) {
    _DeviceFrameScreenFit.cover => _lifeText(
      context,
      zh: '裁切填满',
      en: 'Fill screen',
    ),
    _DeviceFrameScreenFit.contain => _lifeText(
      context,
      zh: '完整显示',
      en: 'Fit whole image',
    ),
  };
}

String _deviceFrameNetworkTypeLabel(
  BuildContext context,
  _DeviceFrameNetworkType type,
) {
  return switch (type) {
    _DeviceFrameNetworkType.none => _lifeText(
      context,
      zh: '无网络字样',
      en: 'No text',
    ),
    _DeviceFrameNetworkType.edge => 'E',
    _DeviceFrameNetworkType.fourG => '4G',
    _DeviceFrameNetworkType.fiveG => '5G',
    _DeviceFrameNetworkType.lte => 'LTE',
    _DeviceFrameNetworkType.wifiOnly => _lifeText(
      context,
      zh: '仅 Wi-Fi',
      en: 'Wi-Fi only',
    ),
  };
}

String _deviceFrameBatteryStatusLabel(
  BuildContext context,
  _DeviceFrameStatusSettings settings,
) {
  if (settings.charging) {
    return _lifeText(context, zh: '充电中', en: 'Charging');
  }
  if (settings.batteryPercent < 15) {
    return _lifeText(context, zh: '电量不足', en: 'Insufficient');
  }
  if (settings.batteryPercent < 30) {
    return _lifeText(context, zh: '低电量', en: 'Low power');
  }
  return _lifeText(context, zh: '正常', en: 'Normal');
}

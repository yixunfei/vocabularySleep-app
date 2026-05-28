part of '../toolbox_life_tools.dart';

enum _DeviceFramePreset { clean, titanium, obsidian, graphite, frost }

enum _DeviceFrameBackground { studio, aurora, midnight }

enum _DeviceFrameStatusTone { light, dark }

enum _DeviceFrameStatusLayout { openTop, island, holePunch }

enum _DeviceFrameNetworkType { none, edge, fourG, fiveG, lte, wifiOnly }

enum _DeviceFrameScreenFit { cover, contain }

class _DeviceFrameSpec {
  const _DeviceFrameSpec({
    required this.frameAssetPath,
    required this.shadowAssetPath,
    required this.glareAssetPath,
    required this.canvasSize,
    required this.screenRect,
    required this.screenRadius,
    required this.statusLayout,
    required this.statusTopPadding,
    required this.statusHorizontalPadding,
  });

  final String frameAssetPath;
  final String shadowAssetPath;
  final String glareAssetPath;
  final Size canvasSize;
  final Rect screenRect;
  final double screenRadius;
  final _DeviceFrameStatusLayout statusLayout;
  final double statusTopPadding;
  final double statusHorizontalPadding;

  double get screenAspect => screenRect.width / screenRect.height;
}

class _DeviceFrameStatusSettings {
  const _DeviceFrameStatusSettings({
    required this.timeText,
    required this.batteryPercent,
    required this.showBatteryPercent,
    required this.charging,
    required this.signalLevel,
    required this.showWifi,
    required this.wifiStrength,
    required this.networkType,
  });

  final String timeText;
  final int batteryPercent;
  final bool showBatteryPercent;
  final bool charging;
  final int signalLevel;
  final bool showWifi;
  final int wifiStrength;
  final _DeviceFrameNetworkType networkType;
}

_DeviceFrameSpec _specForPreset(_DeviceFramePreset preset) {
  return switch (preset) {
    _DeviceFramePreset.clean => throw StateError('Clean preset has no shell.'),
    _DeviceFramePreset.titanium => const _DeviceFrameSpec(
      frameAssetPath: 'assets/toolbox/device_frames/iphone_titanium_frame.png',
      shadowAssetPath:
          'assets/toolbox/device_frames/iphone_titanium_shadow.png',
      glareAssetPath: 'assets/toolbox/device_frames/iphone_titanium_glare.png',
      canvasSize: Size(1400, 2880),
      screenRect: Rect.fromLTWH(144, 154, 1112, 2572),
      screenRadius: 132,
      statusLayout: _DeviceFrameStatusLayout.island,
      statusTopPadding: 14,
      statusHorizontalPadding: 20,
    ),
    _DeviceFramePreset.obsidian => const _DeviceFrameSpec(
      frameAssetPath: 'assets/toolbox/device_frames/iphone_obsidian_frame.png',
      shadowAssetPath:
          'assets/toolbox/device_frames/iphone_obsidian_shadow.png',
      glareAssetPath: 'assets/toolbox/device_frames/iphone_obsidian_glare.png',
      canvasSize: Size(1400, 2880),
      screenRect: Rect.fromLTWH(144, 154, 1112, 2572),
      screenRadius: 132,
      statusLayout: _DeviceFrameStatusLayout.island,
      statusTopPadding: 14,
      statusHorizontalPadding: 20,
    ),
    _DeviceFramePreset.graphite => const _DeviceFrameSpec(
      frameAssetPath: 'assets/toolbox/device_frames/android_graphite_frame.png',
      shadowAssetPath:
          'assets/toolbox/device_frames/android_graphite_shadow.png',
      glareAssetPath: 'assets/toolbox/device_frames/android_graphite_glare.png',
      canvasSize: Size(1400, 2880),
      screenRect: Rect.fromLTWH(158, 136, 1086, 2612),
      screenRadius: 116,
      statusLayout: _DeviceFrameStatusLayout.holePunch,
      statusTopPadding: 12,
      statusHorizontalPadding: 18,
    ),
    _DeviceFramePreset.frost => const _DeviceFrameSpec(
      frameAssetPath: 'assets/toolbox/device_frames/android_frost_frame.png',
      shadowAssetPath: 'assets/toolbox/device_frames/android_frost_shadow.png',
      glareAssetPath: 'assets/toolbox/device_frames/android_frost_glare.png',
      canvasSize: Size(1400, 2880),
      screenRect: Rect.fromLTWH(158, 136, 1086, 2612),
      screenRadius: 116,
      statusLayout: _DeviceFrameStatusLayout.holePunch,
      statusTopPadding: 12,
      statusHorizontalPadding: 18,
    ),
  };
}

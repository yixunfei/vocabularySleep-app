import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ToolboxAudioVolumeSnapshot {
  const ToolboxAudioVolumeSnapshot({
    required this.platformName,
    required this.currentRatio,
    required this.recommendedRatio,
    required this.canAutoApply,
    required this.fixedVolume,
    required this.isSupported,
    this.currentIndex,
    this.maxIndex,
    this.minIndex,
    this.currentDb,
    this.recommendedDb,
    this.nativeNeedsAdjustment,
    this.message,
    this.errorCode,
  });

  final String platformName;
  final double currentRatio;
  final double recommendedRatio;
  final bool canAutoApply;
  final bool fixedVolume;
  final bool isSupported;
  final int? currentIndex;
  final int? maxIndex;
  final int? minIndex;
  final double? currentDb;
  final double? recommendedDb;
  final bool? nativeNeedsAdjustment;
  final String? message;
  final String? errorCode;

  bool get needsAdjustment =>
      nativeNeedsAdjustment ??
      (isSupported &&
          !fixedVolume &&
          (currentRatio < recommendedRatio - 0.08 ||
              currentRatio > recommendedRatio + 0.08));

  factory ToolboxAudioVolumeSnapshot.fromMap(Map<Object?, Object?> map) {
    double readDouble(String key, {double fallback = 0}) {
      final value = map[key];
      if (value is num) {
        return value.toDouble();
      }
      return fallback;
    }

    int? readInt(String key) {
      final value = map[key];
      if (value is num) {
        return value.toInt();
      }
      return null;
    }

    return ToolboxAudioVolumeSnapshot(
      platformName: (map['platformName'] as String?)?.trim().isNotEmpty == true
          ? map['platformName']! as String
          : 'unknown',
      currentRatio: readDouble('currentRatio'),
      recommendedRatio: readDouble('recommendedRatio', fallback: 0.65),
      canAutoApply: map['canAutoApply'] == true,
      fixedVolume: map['fixedVolume'] == true,
      isSupported: map['isSupported'] != false,
      currentIndex: readInt('currentIndex'),
      maxIndex: readInt('maxIndex'),
      minIndex: readInt('minIndex'),
      currentDb: map['currentDb'] is num
          ? (map['currentDb'] as num).toDouble()
          : null,
      recommendedDb: map['recommendedDb'] is num
          ? (map['recommendedDb'] as num).toDouble()
          : null,
      nativeNeedsAdjustment: map['needsAdjustment'] is bool
          ? map['needsAdjustment'] as bool
          : null,
      message: (map['message'] as String?)?.trim().isNotEmpty == true
          ? map['message'] as String
          : null,
      errorCode: (map['errorCode'] as String?)?.trim().isNotEmpty == true
          ? map['errorCode'] as String
          : null,
    );
  }
}

class ToolboxAudioVolumeService {
  ToolboxAudioVolumeService._();

  static const MethodChannel _channel = MethodChannel(
    'vocabulary_sleep/system_audio',
  );

  static bool get isMobileSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<ToolboxAudioVolumeSnapshot> inspectPlaybackVolume({
    double recommendedRatio = 0.65,
  }) async {
    if (!isMobileSupported) {
      return ToolboxAudioVolumeSnapshot(
        platformName: defaultTargetPlatform.name,
        currentRatio: 0.0,
        recommendedRatio: recommendedRatio,
        canAutoApply: false,
        fixedVolume: false,
        isSupported: false,
        message: 'unsupported',
      );
    }
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'getPlaybackVolume',
      <String, Object?>{'recommendedRatio': recommendedRatio.clamp(0.0, 1.0)},
    );
    if (result == null) {
      return ToolboxAudioVolumeSnapshot(
        platformName: defaultTargetPlatform.name,
        currentRatio: 0.0,
        recommendedRatio: recommendedRatio,
        canAutoApply: false,
        fixedVolume: false,
        isSupported: false,
        message: 'empty_response',
      );
    }
    return ToolboxAudioVolumeSnapshot.fromMap(result);
  }

  static Future<ToolboxAudioVolumeSnapshot> applyRecommendedPlaybackVolume({
    double recommendedRatio = 0.65,
  }) async {
    if (!isMobileSupported) {
      return ToolboxAudioVolumeSnapshot(
        platformName: defaultTargetPlatform.name,
        currentRatio: 0.0,
        recommendedRatio: recommendedRatio,
        canAutoApply: false,
        fixedVolume: false,
        isSupported: false,
        message: 'unsupported',
      );
    }
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'setPlaybackVolume',
      <String, Object?>{'targetRatio': recommendedRatio.clamp(0.0, 1.0)},
    );
    if (result == null) {
      return ToolboxAudioVolumeSnapshot(
        platformName: defaultTargetPlatform.name,
        currentRatio: 0.0,
        recommendedRatio: recommendedRatio,
        canAutoApply: false,
        fixedVolume: false,
        isSupported: false,
        message: 'empty_response',
      );
    }
    return ToolboxAudioVolumeSnapshot.fromMap(result);
  }
}

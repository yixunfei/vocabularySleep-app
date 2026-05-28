import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ToolboxFakeCallSpec {
  const ToolboxFakeCallSpec({
    required this.callId,
    required this.triggerAt,
    required this.callerName,
    required this.callerNumber,
    required this.callerLocation,
    required this.callerTag,
    required this.ringtoneEnabled,
    required this.vibrationEnabled,
    required this.incomingBackgroundPath,
    required this.incomingBackgroundStyle,
    required this.inCallBackgroundPath,
    required this.inCallBackgroundStyle,
  });

  final int callId;
  final DateTime triggerAt;
  final String callerName;
  final String callerNumber;
  final String callerLocation;
  final String callerTag;
  final bool ringtoneEnabled;
  final bool vibrationEnabled;
  final String incomingBackgroundPath;
  final String incomingBackgroundStyle;
  final String inCallBackgroundPath;
  final String inCallBackgroundStyle;

  Map<String, Object?> toMethodArguments() {
    return <String, Object?>{
      'callId': callId,
      'triggerAtMillis': triggerAt.millisecondsSinceEpoch,
      'callerName': callerName.trim(),
      'callerNumber': callerNumber.trim(),
      'callerLocation': callerLocation.trim(),
      'callerTag': callerTag.trim(),
      'ringtoneEnabled': ringtoneEnabled,
      'vibrationEnabled': vibrationEnabled,
      'incomingBackgroundPath': incomingBackgroundPath.trim(),
      'incomingBackgroundStyle': incomingBackgroundStyle.trim(),
      'inCallBackgroundPath': inCallBackgroundPath.trim(),
      'inCallBackgroundStyle': inCallBackgroundStyle.trim(),
    };
  }
}

class ToolboxFakeCallCapability {
  const ToolboxFakeCallCapability({
    required this.nativeFullScreenSupported,
    required this.notificationsGranted,
    required this.notificationPermissionRequestable,
    required this.exactAlarmGranted,
    required this.exactAlarmSettingsAvailable,
  });

  final bool nativeFullScreenSupported;
  final bool notificationsGranted;
  final bool notificationPermissionRequestable;
  final bool exactAlarmGranted;
  final bool exactAlarmSettingsAvailable;

  bool get needsNotificationPermission =>
      notificationPermissionRequestable && !notificationsGranted;

  bool get needsExactAlarmPermission =>
      exactAlarmSettingsAvailable && !exactAlarmGranted;

  static const ToolboxFakeCallCapability fallback = ToolboxFakeCallCapability(
    nativeFullScreenSupported: false,
    notificationsGranted: true,
    notificationPermissionRequestable: false,
    exactAlarmGranted: true,
    exactAlarmSettingsAvailable: false,
  );
}

class ToolboxFakeCallScheduleResult {
  const ToolboxFakeCallScheduleResult({
    required this.nativeScheduled,
    this.errorCode,
  });

  final bool nativeScheduled;
  final String? errorCode;
}

abstract interface class ToolboxFakeCallService {
  Future<ToolboxFakeCallCapability> getCapability();

  Future<ToolboxFakeCallScheduleResult> scheduleFakeCall(
    ToolboxFakeCallSpec spec,
  );

  Future<void> cancelFakeCall(int callId);

  Future<bool> showFakeCallNow(ToolboxFakeCallSpec spec);

  Future<bool> requestNotificationPermission();

  Future<void> openExactAlarmSettings();
}

class PlatformToolboxFakeCallService implements ToolboxFakeCallService {
  PlatformToolboxFakeCallService();

  static const MethodChannel _channel = MethodChannel(
    'vocabulary_sleep/fake_call',
  );

  bool get _supportsCurrentPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<ToolboxFakeCallCapability> getCapability() async {
    if (!_supportsCurrentPlatform) {
      return ToolboxFakeCallCapability.fallback;
    }
    try {
      final response = await _channel
          .invokeMapMethod<String, Object?>('getFakeCallCapability')
          .timeout(const Duration(seconds: 2));
      return ToolboxFakeCallCapability(
        nativeFullScreenSupported:
            response?['nativeFullScreenSupported'] == true,
        notificationsGranted: response?['notificationsGranted'] == true,
        notificationPermissionRequestable:
            response?['notificationPermissionRequestable'] == true,
        exactAlarmGranted: response?['exactAlarmGranted'] == true,
        exactAlarmSettingsAvailable:
            response?['exactAlarmSettingsAvailable'] == true,
      );
    } on MissingPluginException {
      return ToolboxFakeCallCapability.fallback;
    } catch (_) {
      return const ToolboxFakeCallCapability(
        nativeFullScreenSupported: false,
        notificationsGranted: false,
        notificationPermissionRequestable: false,
        exactAlarmGranted: false,
        exactAlarmSettingsAvailable: false,
      );
    }
  }

  @override
  Future<ToolboxFakeCallScheduleResult> scheduleFakeCall(
    ToolboxFakeCallSpec spec,
  ) async {
    if (!_supportsCurrentPlatform) {
      return const ToolboxFakeCallScheduleResult(
        nativeScheduled: false,
        errorCode: 'unsupported',
      );
    }
    try {
      final response = await _channel
          .invokeMapMethod<String, Object?>(
            'scheduleFakeCall',
            spec.toMethodArguments(),
          )
          .timeout(const Duration(seconds: 2));
      return ToolboxFakeCallScheduleResult(
        nativeScheduled: response?['nativeScheduled'] == true,
        errorCode: response?['errorCode'] as String?,
      );
    } on MissingPluginException {
      return const ToolboxFakeCallScheduleResult(
        nativeScheduled: false,
        errorCode: 'unsupported',
      );
    } catch (_) {
      return const ToolboxFakeCallScheduleResult(
        nativeScheduled: false,
        errorCode: 'failed',
      );
    }
  }

  @override
  Future<void> cancelFakeCall(int callId) async {
    if (!_supportsCurrentPlatform) {
      return;
    }
    try {
      await _channel
          .invokeMethod<void>('cancelFakeCall', <String, Object?>{
            'callId': callId,
          })
          .timeout(const Duration(seconds: 2));
    } on MissingPluginException {
      // Unsupported platforms use the in-app fallback timer only.
    } catch (_) {
      // Best-effort cancellation.
    }
  }

  @override
  Future<bool> showFakeCallNow(ToolboxFakeCallSpec spec) async {
    if (!_supportsCurrentPlatform) {
      return false;
    }
    try {
      final shown = await _channel
          .invokeMethod<bool>('showFakeCallNow', spec.toMethodArguments())
          .timeout(const Duration(seconds: 2));
      return shown ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestNotificationPermission() async {
    if (!_supportsCurrentPlatform) {
      return true;
    }
    try {
      final granted = await _channel
          .invokeMethod<bool>('requestFakeCallNotificationPermission')
          .timeout(const Duration(seconds: 2));
      return granted ?? false;
    } on MissingPluginException {
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> openExactAlarmSettings() async {
    if (!_supportsCurrentPlatform) {
      return;
    }
    try {
      await _channel
          .invokeMethod<void>('openFakeCallExactAlarmSettings')
          .timeout(const Duration(seconds: 2));
    } on MissingPluginException {
      // Unsupported platforms silently ignore.
    } catch (_) {
      // Best-effort only.
    }
  }
}

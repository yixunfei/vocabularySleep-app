import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/services/reminder_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const reminderChannel = MethodChannel('vocabulary_sleep/reminder');
  const audioChannel = MethodChannel('xyz.luan/audioplayers');
  const audioEventsChannel = MethodChannel(
    'xyz.luan/audioplayers/events/focus_reminder',
  );
  const audioGlobalChannel = MethodChannel('xyz.luan/audioplayers.global');
  const audioGlobalEventsChannel = MethodChannel(
    'xyz.luan/audioplayers.global/events',
  );

  final nativeCalls = <MethodCall>[];
  final audioCalls = <MethodCall>[];

  setUp(() {
    nativeCalls.clear();
    audioCalls.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(reminderChannel, (call) async {
          nativeCalls.add(call);
          if (call.method == 'playReminder') {
            return true;
          }
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, (call) async {
          audioCalls.add(call);
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioEventsChannel, (call) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, (call) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          audioGlobalEventsChannel,
          (call) async => null,
        );
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(reminderChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioEventsChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalEventsChannel, null);
  });

  test(
    'forwards reminder play and stop through the native channel on android',
    () async {
      final service = PlatformReminderService();
      addTearDown(service.dispose);

      await service.play(
        haptic: true,
        sound: true,
        customSoundPath: '/tmp/custom_alert.mp3',
        duration: const Duration(seconds: 12),
      );
      await service.stop();

      expect(nativeCalls, isNotEmpty);
      final playCall = nativeCalls.firstWhere(
        (call) => call.method == 'playReminder',
      );
      expect(playCall.arguments, <String, Object>{
        'haptic': true,
        'sound': true,
        'durationMs': 10000,
        'customSoundPath': '/tmp/custom_alert.mp3',
      });
      expect(nativeCalls.any((call) => call.method == 'stopReminder'), isTrue);
      expect(
        audioCalls.where((call) {
          return call.method == 'setSourceBytes' ||
              call.method == 'setSourceUrl' ||
              call.method == 'resume';
        }),
        isEmpty,
      );
    },
  );
}

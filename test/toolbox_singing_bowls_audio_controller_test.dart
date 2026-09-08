import 'dart:async';
import 'dart:io';

import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/services/toolbox_audio_service.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_singing_bowls_audio_controller.dart';

class _FakeAudioPlatform extends AudioplayersPlatformInterface {
  final Map<String, StreamController<AudioEvent>> _events =
      <String, StreamController<AudioEvent>>{};
  int createCount = 0;
  int disposeCount = 0;
  int resumeCount = 0;

  @override
  Future<void> create(String playerId) async {
    createCount += 1;
    _events[playerId] = StreamController<AudioEvent>.broadcast();
  }

  @override
  Future<void> dispose(String playerId) async {
    disposeCount += 1;
    final events = _events.remove(playerId);
    await events?.close();
  }

  @override
  Stream<AudioEvent> getEventStream(String playerId) {
    return _events[playerId]!.stream;
  }

  @override
  Future<void> setSourceUrl(
    String playerId,
    String url, {
    bool? isLocal,
    String? mimeType,
  }) async {
    _emitPrepared(playerId);
  }

  @override
  Future<void> setSourceBytes(
    String playerId,
    Uint8List bytes, {
    String? mimeType,
  }) async {
    _emitPrepared(playerId);
  }

  void _emitPrepared(String playerId) {
    final events = _events[playerId];
    if (events == null || events.isClosed) {
      return;
    }
    events.add(
      const AudioEvent(eventType: AudioEventType.prepared, isPrepared: true),
    );
    events.add(
      const AudioEvent(
        eventType: AudioEventType.duration,
        duration: Duration(seconds: 10),
      ),
    );
  }

  @override
  Future<int?> getDuration(String playerId) async => 10000;

  @override
  Future<int?> getCurrentPosition(String playerId) async => 0;

  @override
  Future<void> pause(String playerId) async {}

  @override
  Future<void> resume(String playerId) async {
    resumeCount += 1;
  }

  @override
  Future<void> stop(String playerId) async {}

  @override
  Future<void> release(String playerId) async {}

  @override
  Future<void> seek(String playerId, Duration position) async {}

  @override
  Future<void> setAudioContext(
    String playerId,
    AudioContext audioContext,
  ) async {}

  @override
  Future<void> setPlayerMode(String playerId, PlayerMode playerMode) async {}

  @override
  Future<void> setPlaybackRate(String playerId, double playbackRate) async {}

  @override
  Future<void> setReleaseMode(String playerId, ReleaseMode releaseMode) async {}

  @override
  Future<void> setBalance(String playerId, double balance) async {}

  @override
  Future<void> setVolume(String playerId, double volume) async {}

  @override
  Future<void> emitLog(String playerId, String message) async {}

  @override
  Future<void> emitError(String playerId, String code, String message) async {}
}

class _FakeGlobalAudioPlatform extends GlobalAudioplayersPlatformInterface {
  @override
  Future<void> init() async {}

  @override
  Future<void> setGlobalAudioContext(AudioContext ctx) async {}

  @override
  Stream<GlobalAudioEvent> getGlobalEventStream() => const Stream.empty();

  @override
  Future<void> emitGlobalLog(String message) async {}

  @override
  Future<void> emitGlobalError(String code, String message) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late AudioplayersPlatformInterface originalAudioPlatform;
  late GlobalAudioplayersPlatformInterface originalGlobalPlatform;
  late _FakeAudioPlatform audioPlatform;
  late _FakeGlobalAudioPlatform globalPlatform;
  late Directory tempDirectory;

  setUp(() async {
    originalAudioPlatform = AudioplayersPlatformInterface.instance;
    originalGlobalPlatform = GlobalAudioplayersPlatformInterface.instance;
    audioPlatform = _FakeAudioPlatform();
    globalPlatform = _FakeGlobalAudioPlatform();
    AudioplayersPlatformInterface.instance = audioPlatform;
    GlobalAudioplayersPlatformInterface.instance = globalPlatform;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tempDirectory = await Directory.systemTemp.createTemp(
      'singing-bowl-controller-',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          pathProviderChannel,
          (call) async => tempDirectory.path,
        );
    ToolboxAudioBank.clearDomainCache('singing_bowl');
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    AudioplayersPlatformInterface.instance = originalAudioPlatform;
    GlobalAudioplayersPlatformInterface.instance = originalGlobalPlatform;
    debugDefaultTargetPlatformOverride = null;
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('latest tone request wins and player lifecycle stays ordered', () async {
    final controller = ToolboxSingingBowlsAudioController(
      variantIds: const <int>[0],
      maxVoicesPerVariant: 1,
    );
    addTearDown(controller.dispose);

    final first = controller.setTone(frequency: 396, style: 'crystal');
    final second = controller.setTone(frequency: 528, style: 'pure');

    expect(await first, isFalse);
    expect(await second, isTrue);
    expect(controller.hasReadyTone, isTrue);

    await controller.play(baseVolume: 0.7);
    await controller.stop();
    await controller.dispose();

    expect(controller.hasReadyTone, isFalse);
    expect(await controller.setTone(frequency: 639, style: 'deep'), isFalse);
  });

  test('burst strikes stay within the bounded native voice pool', () async {
    final controller = ToolboxSingingBowlsAudioController();
    addTearDown(controller.dispose);

    expect(await controller.setTone(frequency: 639, style: 'crystal'), isTrue);
    await Future.wait<void>(
      List<Future<void>>.generate(
        8,
        (_) => controller.play(baseVolume: 0.7),
        growable: false,
      ),
    );

    expect(audioPlatform.createCount, lessThanOrEqualTo(4));
    expect(audioPlatform.resumeCount, lessThanOrEqualTo(1));
    await controller.dispose();
    expect(audioPlatform.disposeCount, lessThanOrEqualTo(4));
  });
}

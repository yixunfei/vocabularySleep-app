import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/services/ambient_service.dart';
import 'package:vocabulary_sleep_app/src/services/cstcloud_resource_cache_service.dart';

class _FakeAmbientLoopPlayer implements AmbientLoopPlayer {
  _FakeAmbientLoopPlayer({required this.duration});

  final Duration? duration;
  final List<Source> sources = <Source>[];
  final List<ReleaseMode> releaseModes = <ReleaseMode>[];
  final List<double> volumes = <double>[];
  int resumeCalls = 0;
  int stopCalls = 0;
  int disposeCalls = 0;

  @override
  Future<void> setSource(Source source) async {
    sources.add(source);
  }

  @override
  Future<Duration?> getDuration() async => duration;

  @override
  Future<void> setReleaseMode(ReleaseMode releaseMode) async {
    releaseModes.add(releaseMode);
  }

  @override
  Future<void> setVolume(double volume) async {
    volumes.add(volume);
  }

  @override
  Future<void> resume() async {
    resumeCalls += 1;
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
  }
}

class _FakeAmbientCacheService extends CstCloudResourceCacheService {
  _FakeAmbientCacheService(this.file);

  final File file;

  @override
  Future<File> ensureFileDownloaded(
    String remoteKey, {
    String? cacheRelativePath,
    ResourceDownloadProgressCallback? onProgress,
  }) async {
    await file.parent.create(recursive: true);
    if (!await file.exists()) {
      await file.writeAsBytes(const <int>[1, 2, 3], flush: true);
    }
    final length = await file.length();
    onProgress?.call(
      ResourceDownloadProgress(receivedBytes: length, totalBytes: length),
    );
    return file;
  }
}

void main() {
  test(
    'seamless ambient loop alternates preloaded players before track end',
    () {
      fakeAsync((async) {
        final players = <_FakeAmbientLoopPlayer>[];
        final loop = SeamlessAmbientLoop(
          source: AssetSource('ambient/noise/white-noise.wav'),
          initialVolume: 0.6,
          overlap: const Duration(milliseconds: 200),
          fadeInterval: const Duration(milliseconds: 100),
          playerFactory: () {
            final player = _FakeAmbientLoopPlayer(
              duration: const Duration(seconds: 1),
            );
            players.add(player);
            return player;
          },
        );

        loop.start();
        async.flushMicrotasks();

        expect(players, hasLength(2));
        expect(players[0].resumeCalls, 1);
        expect(players[1].resumeCalls, 0);

        async.elapse(const Duration(milliseconds: 799));
        async.flushMicrotasks();
        expect(players[1].resumeCalls, 0);

        async.elapse(const Duration(milliseconds: 1));
        async.flushMicrotasks();
        expect(players[1].resumeCalls, 1);

        async.elapse(const Duration(milliseconds: 200));
        async.flushMicrotasks();
        expect(players[0].stopCalls, 1);

        async.elapse(const Duration(milliseconds: 800));
        async.flushMicrotasks();
        expect(players[0].resumeCalls, 2);
      });
    },
  );

  test('falls back to native loop when duration is unavailable', () async {
    final players = <_FakeAmbientLoopPlayer>[];
    final loop = SeamlessAmbientLoop(
      source: AssetSource('ambient/noise/white-noise.wav'),
      initialVolume: 0.5,
      playerFactory: () {
        final player = _FakeAmbientLoopPlayer(duration: null);
        players.add(player);
        return player;
      },
    );

    await loop.start();

    expect(players, hasLength(1));
    expect(players.single.releaseModes, contains(ReleaseMode.loop));
    expect(players.single.resumeCalls, 1);
  });

  test(
    'master switch stops playback without clearing selected sources',
    () async {
      final players = <_FakeAmbientLoopPlayer>[];
      final service = AmbientService(
        playerFactory: () {
          final player = _FakeAmbientLoopPlayer(
            duration: const Duration(seconds: 1),
          );
          players.add(player);
          return player;
        },
      );

      service.setSourceEnabled('noise_white', true);
      await service.syncPlayback();

      expect(service.isEnabled, isTrue);
      expect(players, hasLength(2));

      service.setEnabled(false);
      await service.syncPlayback();

      expect(service.isEnabled, isFalse);
      expect(
        service.sources
            .firstWhere((source) => source.id == 'noise_white')
            .enabled,
        isTrue,
      );
      expect(players.every((player) => player.disposeCalls == 1), isTrue);

      service.setEnabled(true);
      await service.syncPlayback();

      expect(players, hasLength(4));
    },
  );

  test('built-in ambient prefers cached S3 file when available', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'ambient_cache_test_',
    );
    addTearDown(() => tempDir.delete(recursive: true));
    final cachedFile = File('${tempDir.path}/ambient/noise/white-noise.wav');
    final players = <_FakeAmbientLoopPlayer>[];
    final service = AmbientService(
      resourceCache: _FakeAmbientCacheService(cachedFile),
      playerFactory: () {
        final player = _FakeAmbientLoopPlayer(
          duration: const Duration(seconds: 1),
        );
        players.add(player);
        return player;
      },
    );

    service.setSourceEnabled('noise_white', true);
    await service.syncPlayback();

    expect(players, hasLength(2));
    expect(players.first.sources.first, isA<DeviceFileSource>());
    expect(
      service.sources
          .firstWhere((source) => source.id == 'noise_white')
          .filePath,
      cachedFile.path,
    );
  });
}

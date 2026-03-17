import 'package:audioplayers/audioplayers.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/services/ambient_service.dart';

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
}

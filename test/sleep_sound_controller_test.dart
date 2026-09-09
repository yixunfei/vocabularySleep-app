import 'dart:async';
import 'dart:typed_data';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/sleep/sleep_sound_controller.dart';
import 'package:vocabulary_sleep_app/src/services/sleep/sleep_sound_player.dart';

class _Player implements SleepSoundPlayer {
  final ready = Completer<void>();
  int playCalls = 0;
  bool disposed = false;
  double? volume;
  @override
  Future<void> play(SleepSound sound, double volume) {
    playCalls++;
    this.volume = volume;
    return ready.future;
  }

  @override
  Future<void> setVolume(double volume) async {
    this.volume = volume;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  _replacementDeadlineTest();
  _preparationTests();
  _replacementTests();
  _durationAndLoopTests();
}

void _preparationTests() {
  test('player creation failure is visible and retryable', () async {
    final player = _Player()..ready.complete();
    var attempts = 0;
    final controller = SleepSoundController(
      playerFactory: () {
        if (attempts++ == 0) throw StateError('platform unavailable');
        return player;
      },
    );
    addTearDown(controller.dispose);
    await controller.play(SleepSound.brown);
    expect(controller.status, SleepSoundStatus.failed);
    await controller.play(SleepSound.brown);
    expect(controller.status, SleepSoundStatus.playing);
  });
  test('only reports playback after player preparation succeeds', () async {
    final player = _Player();
    final controller = SleepSoundController(playerFactory: () => player);
    addTearDown(controller.dispose);
    final playing = controller.play(SleepSound.brown);
    await Future<void>.delayed(Duration.zero);
    expect(controller.status, SleepSoundStatus.preparing);
    await controller.play(SleepSound.brown);
    expect(player.playCalls, 1);
    await controller.setVolume(0.1);
    player.ready.complete();
    await playing;
    expect(controller.status, SleepSoundStatus.playing);
    expect(player.volume, 0.1);
  });

  test('stop during preparation cannot be undone by a late start', () async {
    final player = _Player();
    final controller = SleepSoundController(playerFactory: () => player);
    addTearDown(controller.dispose);
    final playing = controller.play(SleepSound.brown);
    await Future<void>.delayed(Duration.zero);
    await controller.stop();
    player.ready.complete();
    await playing;
    expect(controller.status, SleepSoundStatus.silent);
    expect(player.disposed, isTrue);
  });
}

void _replacementTests() {
  test('a stale failure cannot replace a newer playing sound', () async {
    final first = _Player();
    final second = _Player();
    var calls = 0;
    final controller = SleepSoundController(
      playerFactory: () => calls++ == 0 ? first : second,
    );
    addTearDown(controller.dispose);
    final a = controller.play(SleepSound.brown);
    await Future<void>.delayed(Duration.zero);
    final b = controller.play(SleepSound.pink);
    await Future<void>.delayed(Duration.zero);
    second.ready.complete();
    await b;
    first.ready.completeError(StateError('old source failed'));
    await a;
    expect(controller.status, SleepSoundStatus.playing);
    expect(controller.sound, SleepSound.pink);
  });

  test('failure is retryable and has no playing status', () async {
    final first = _Player();
    final second = _Player();
    var calls = 0;
    final controller = SleepSoundController(
      playerFactory: () => calls++ == 0 ? first : second,
    );
    addTearDown(controller.dispose);
    final a = controller.play(SleepSound.pink);
    await Future<void>.delayed(Duration.zero);
    first.ready.completeError(StateError('audio unavailable'));
    await a;
    expect(controller.status, SleepSoundStatus.failed);
    expect(first.disposed, isTrue);
    final b = controller.play(SleepSound.pink);
    await Future<void>.delayed(Duration.zero);
    second.ready.complete();
    await b;
    expect(controller.status, SleepSoundStatus.playing);
  });
}

void _durationAndLoopTests() {
  test('sound stops after its selected duration without a visible page', () {
    fakeAsync((async) {
      final player = _Player()..ready.complete();
      final controller = SleepSoundController(playerFactory: () => player);
      controller.setMinutes(15);
      unawaited(controller.play(SleepSound.pink));
      async.flushMicrotasks();
      expect(controller.status, SleepSoundStatus.playing);
      async.elapse(const Duration(minutes: 15));
      expect(controller.status, SleepSoundStatus.silent);
      expect(player.disposed, isTrue);
      controller.dispose();
    });
  });

  test('background resume reconciles an expired stop time', () async {
    var now = DateTime(2026, 9, 9, 23);
    final player = _Player()..ready.complete();
    final controller = SleepSoundController(
      playerFactory: () => player,
      now: () => now,
    );
    addTearDown(controller.dispose);
    await controller.play(SleepSound.brown);
    now = now.add(const Duration(minutes: 40));
    controller.synchronize();
    expect(controller.status, SleepSoundStatus.silent);
  });

  test(
    'offline loops have valid bounded PCM with a continuous loop boundary',
    () {
      for (final sound in SleepSound.values) {
        final bytes = buildSleepNoise(sound);
        final data = bytes.buffer.asByteData();
        expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
        expect(bytes.length, 44 + 22050 * 8 * 2);
        // Adjacent samples at the loop seam should not make a loud transient.
        final first = data.getInt16(44, Endian.little);
        final last = data.getInt16(bytes.length - 2, Endian.little);
        expect((first - last).abs(), lessThan(6000));
      }
    },
  );
}

void _replacementDeadlineTest() {
  test(
    'old stop deadline cannot cancel a replacement preparing after resume',
    () async {
      var now = DateTime(2026, 9, 9, 23);
      final first = _Player()..ready.complete();
      final second = _Player();
      var attempts = 0;
      final controller = SleepSoundController(
        playerFactory: () => attempts++ == 0 ? first : second,
        now: () => now,
      );
      addTearDown(controller.dispose);
      await controller.play(SleepSound.brown);
      now = now.add(const Duration(minutes: 29));
      final replacement = controller.play(SleepSound.pink);
      await Future<void>.delayed(Duration.zero);
      now = now.add(const Duration(minutes: 2));
      controller.synchronize();
      expect(controller.status, SleepSoundStatus.preparing);
      second.ready.complete();
      await replacement;
      expect(controller.status, SleepSoundStatus.playing);
    },
  );
}

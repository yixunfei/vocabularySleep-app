import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../toolbox_audio_service.dart';
import 'sleep_sound_controller.dart';

class SleepLoopSoundPlayer implements SleepSoundPlayer {
  final ToolboxLoopController _loop = ToolboxLoopController();
  bool _disposed = false;
  static final Map<SleepSound, Future<Uint8List>> _sounds = {};

  @override
  Future<void> play(SleepSound sound, double volume) async {
    final pending = _sounds.putIfAbsent(
      sound,
      () => compute(buildSleepNoise, sound, debugLabel: 'sleep-noise'),
    );
    late final Uint8List bytes;
    try {
      bytes = await pending;
    } on Object {
      if (identical(_sounds[sound], pending)) _sounds.remove(sound);
      rethrow;
    }
    if (_disposed) return;
    await _loop.play(bytes, volume: volume);
  }

  @override
  Future<void> setVolume(double volume) async {
    if (!_disposed) await _loop.setVolume(volume);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _loop.dispose();
  }
}

/// A bounded offline loop, rendered away from the UI isolate on first use.
Uint8List buildSleepNoise(SleepSound sound) {
  const rate = 22050;
  const length = rate * 8;
  const overlap = rate ~/ 4;
  final random = math.Random(sound.index + 432);
  final samples = Float64List(length + overlap);
  var low = 0.0;
  var mid = 0.0;
  for (var i = 0; i < samples.length; i++) {
    final white = random.nextDouble() * 2 - 1;
    low = low * 0.985 + white * 0.015;
    mid = mid * 0.8 + white * 0.2;
    samples[i] = sound == SleepSound.brown
        ? low * 3.5
        : low * 1.5 + mid * 0.45 + white * 0.04;
  }
  // Blend the final overlap into the beginning, then loop at that boundary.
  for (var i = 0; i < overlap; i++) {
    final weight = (1 - math.cos(math.pi * i / overlap)) / 2;
    samples[i] = samples[length + i] * (1 - weight) + samples[i] * weight;
  }
  final bytes = ByteData(44 + length * 2);
  void tag(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      bytes.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  bytes.setUint32(4, bytes.lengthInBytes - 8, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, rate, Endian.little);
  bytes.setUint32(28, rate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  bytes.setUint32(40, length * 2, Endian.little);
  for (var i = 0; i < length; i++) {
    bytes.setInt16(
      44 + i * 2,
      (samples[i].clamp(-0.85, 0.85) * 32767).round(),
      Endian.little,
    );
  }
  return bytes.buffer.asUint8List();
}

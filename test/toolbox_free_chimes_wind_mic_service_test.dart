import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_free_chimes_wind_mic_service.dart';

void main() {
  test('wind mic analyzer lifts low-energy breeze above quiet floor', () {
    final analyzer = ToolboxFreeChimeWindMicAnalyzer();

    ToolboxFreeChimeWindMicSample? quiet;
    for (var frame = 0; frame < 10; frame += 1) {
      quiet = analyzer.analyzePcm16(_pcm16(_quietFrame(frame)));
    }

    ToolboxFreeChimeWindMicSample? breeze;
    for (var frame = 0; frame < 14; frame += 1) {
      breeze = analyzer.analyzePcm16(_pcm16(_breezeFrame(frame)));
    }

    expect(quiet, isNotNull);
    expect(breeze, isNotNull);
    expect(breeze!.level, greaterThan(quiet!.level + 0.02));
    expect(breeze.confidence, greaterThan(0.35));
    expect(breeze.isWindLike, isTrue);
  });

  test('wind mic analyzer reset clears confidence and level history', () {
    final analyzer = ToolboxFreeChimeWindMicAnalyzer();
    for (var frame = 0; frame < 12; frame += 1) {
      analyzer.analyzePcm16(_pcm16(_breezeFrame(frame)));
    }

    analyzer.reset();
    final sample = analyzer.analyzePcm16(_pcm16(_quietFrame(0)));

    expect(sample, isNotNull);
    expect(sample!.level, lessThan(0.04));
    expect(sample.confidence, lessThan(0.3));
  });
}

List<double> _quietFrame(int frame) {
  return List<double>.generate(2048, (index) {
    final phase = (frame * 2048 + index) / 16000;
    return math.sin(phase * math.pi * 2 * 120) * 0.0007;
  }, growable: false);
}

List<double> _breezeFrame(int frame) {
  return List<double>.generate(2048, (index) {
    final sampleIndex = frame * 2048 + index;
    final phase = sampleIndex / 16000;
    final slow = math.sin(phase * math.pi * 2 * 18) * 0.004;
    final texture =
        math.sin(sampleIndex * 0.37) * 0.003 +
        math.sin(sampleIndex * 0.073 + frame) * 0.002;
    final gust = (index % 257 < 19) ? 0.003 * (1 - (index % 19) / 19) : 0.0;
    return (slow + texture + gust).clamp(-0.018, 0.018).toDouble();
  }, growable: false);
}

Uint8List _pcm16(List<double> samples) {
  final bytes = ByteData(samples.length * 2);
  for (var index = 0; index < samples.length; index += 1) {
    final value = (samples[index].clamp(-1.0, 1.0) * 32767).round();
    bytes.setInt16(index * 2, value, Endian.little);
  }
  return bytes.buffer.asUint8List();
}

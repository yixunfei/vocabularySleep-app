import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/services/toolbox_audio_service.dart';

void main() {
  setUp(() {
    ToolboxAudioBank.clearDomainCache('singing_bowl');
  });

  test('singing bowl tone stays bounded and decays smoothly', () {
    final bytes = ToolboxAudioBank.singingBowlTone(
      frequency: 639,
      style: 'crystal',
      variant: 0,
    );
    final wav = _decodeWavPcm16(bytes);

    expect(wav.sampleRate, 24000);
    expect(wav.samples.length, greaterThan(24000));
    expect(wav.samples.length, lessThanOrEqualTo(24000 * 14));
    expect(wav.samples.every((sample) => sample.isFinite), isTrue);

    final peak = wav.samples.fold<double>(
      0,
      (current, sample) => math.max(current, sample.abs()),
    );
    expect(peak, lessThanOrEqualTo(0.95));

    final midStart = wav.samples.length ~/ 3;
    final midRms = _rms(
      wav.samples.sublist(midStart, midStart + wav.samples.length ~/ 8),
    );
    final tailRms = _rms(
      wav.samples.sublist(wav.samples.length - wav.samples.length ~/ 8),
    );
    expect(midRms, greaterThan(0.005));
    expect(tailRms, lessThan(midRms * 0.9));

    var largestStep = 0.0;
    for (var index = 1; index < wav.samples.length; index += 1) {
      largestStep = math.max(
        largestStep,
        (wav.samples[index] - wav.samples[index - 1]).abs(),
      );
    }
    expect(largestStep, lessThan(0.45));
  });

  test('async tone generation coalesces identical requests', () async {
    final results = await Future.wait(<Future<Uint8List>>[
      ToolboxAudioBank.singingBowlToneAsync(
        frequency: 432,
        style: 'deep',
        variant: 1,
      ),
      ToolboxAudioBank.singingBowlToneAsync(
        frequency: 432,
        style: 'deep',
        variant: 1,
      ),
    ]);

    expect(identical(results[0], results[1]), isTrue);
    expect(results[0].length, greaterThan(44));
    expect(
      identical(
        results[0],
        await ToolboxAudioBank.singingBowlToneAsync(
          frequency: 432,
          style: 'deep',
          variant: 1,
        ),
      ),
      isTrue,
    );
  });

  test('variants are deterministic but audibly distinct', () {
    final first = ToolboxAudioBank.singingBowlTone(
      frequency: 528,
      style: 'brass',
      variant: 0,
    );
    final firstAgain = ToolboxAudioBank.singingBowlTone(
      frequency: 528,
      style: 'brass',
      variant: 0,
    );
    final second = ToolboxAudioBank.singingBowlTone(
      frequency: 528,
      style: 'brass',
      variant: 1,
    );

    expect(first, equals(firstAgain));
    expect(first, isNot(equals(second)));
  });
}

({int sampleRate, List<double> samples}) _decodeWavPcm16(Uint8List bytes) {
  expect(bytes.length, greaterThanOrEqualTo(44));
  expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
  expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
  final data = ByteData.sublistView(bytes);
  final dataBytes = data.getUint32(40, Endian.little);
  expect(dataBytes + 44, bytes.length);
  final samples = List<double>.generate(dataBytes ~/ 2, (index) {
    return data.getInt16(44 + index * 2, Endian.little) / 32768.0;
  }, growable: false);
  return (sampleRate: data.getUint32(24, Endian.little), samples: samples);
}

double _rms(List<double> values) {
  if (values.isEmpty) {
    return 0;
  }
  var sum = 0.0;
  for (final value in values) {
    sum += value * value;
  }
  return math.sqrt(sum / values.length);
}

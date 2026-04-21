part of 'toolbox_audio_service.dart';

void _applySchroederReverb(
  List<double> samples, {
  required int sampleRate,
  required double amount,
}) {
  final mix = amount.clamp(0.0, 0.8).toDouble();
  if (mix <= 0.001) return;
  final input = List<double>.from(samples, growable: false);
  final combDelays = <int>[
    (sampleRate * 0.0297).round(),
    (sampleRate * 0.0371).round(),
    (sampleRate * 0.0411).round(),
    (sampleRate * 0.0437).round(),
  ];
  final allpassDelays = <int>[
    (sampleRate * 0.005).round(),
    (sampleRate * 0.0017).round(),
  ];
  final combFeedback = 0.74 + mix * 0.2;
  final allpassFeedback = 0.5;
  final wet = List<double>.filled(samples.length, 0);

  for (final delay in combDelays) {
    if (delay <= 1) continue;
    final buffer = List<double>.filled(delay, 0);
    var bufferIndex = 0;
    for (var i = 0; i < samples.length; i += 1) {
      final delayed = buffer[bufferIndex];
      final value = input[i] + delayed * combFeedback;
      buffer[bufferIndex] = value;
      wet[i] += delayed;
      bufferIndex += 1;
      if (bufferIndex >= delay) {
        bufferIndex = 0;
      }
    }
  }

  for (var i = 0; i < samples.length; i += 1) {
    wet[i] /= combDelays.length;
  }

  var processed = wet;
  for (final delay in allpassDelays) {
    if (delay <= 1) continue;
    final buffer = List<double>.filled(delay, 0);
    var bufferIndex = 0;
    final output = List<double>.filled(samples.length, 0);
    for (var i = 0; i < samples.length; i += 1) {
      final delayed = buffer[bufferIndex];
      final current = processed[i];
      final value = -allpassFeedback * current + delayed;
      buffer[bufferIndex] = current + delayed * allpassFeedback;
      output[i] = value;
      bufferIndex += 1;
      if (bufferIndex >= delay) {
        bufferIndex = 0;
      }
    }
    processed = output;
  }

  final wetMix = mix * 0.92;
  final dryMix = 1.0 - wetMix * 0.72;
  for (var i = 0; i < samples.length; i += 1) {
    samples[i] = input[i] * dryMix + processed[i] * wetMix;
  }
}

void _applyOnePoleLowPass(
  List<double> samples, {
  required int sampleRate,
  required double cutoffHz,
}) {
  final normalizedCutoff = cutoffHz.clamp(40.0, sampleRate * 0.45).toDouble();
  final rc = 1.0 / (2 * math.pi * normalizedCutoff);
  final dt = 1.0 / sampleRate;
  final alpha = (dt / (rc + dt)).clamp(0.0001, 1.0).toDouble();
  if (samples.isEmpty) return;
  var state = samples.first;
  for (var i = 0; i < samples.length; i += 1) {
    state += (samples[i] - state) * alpha;
    samples[i] = state;
  }
}

void _applyDcBlock(List<double> samples, {double pole = 0.995}) {
  if (samples.length < 2) return;
  final normalizedPole = pole.clamp(0.8, 0.9999).toDouble();
  var prevX = samples.first;
  var prevY = samples.first;
  for (var i = 1; i < samples.length; i += 1) {
    final x = samples[i];
    final y = x - prevX + normalizedPole * prevY;
    samples[i] = y;
    prevX = x;
    prevY = y;
  }
}

Uint8List _encodeWav(
  List<double> samples, {
  required int sampleRate,
  required double gain,
}) {
  var peak = 0.000001;
  for (final sample in samples) {
    peak = math.max(peak, sample.abs());
  }
  final normalization = gain / peak;

  final byteData = ByteData(44 + samples.length * 2);
  void writeString(int offset, String value) {
    for (var i = 0; i < value.length; i += 1) {
      byteData.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  writeString(0, 'RIFF');
  byteData.setUint32(4, 36 + samples.length * 2, Endian.little);
  writeString(8, 'WAVE');
  writeString(12, 'fmt ');
  byteData.setUint32(16, 16, Endian.little);
  byteData.setUint16(20, 1, Endian.little);
  byteData.setUint16(22, 1, Endian.little);
  byteData.setUint32(24, sampleRate, Endian.little);
  byteData.setUint32(28, sampleRate * 2, Endian.little);
  byteData.setUint16(32, 2, Endian.little);
  byteData.setUint16(34, 16, Endian.little);
  writeString(36, 'data');
  byteData.setUint32(40, samples.length * 2, Endian.little);

  var offset = 44;
  for (final sample in samples) {
    final normalized = (sample * normalization).clamp(-1.0, 1.0);
    byteData.setInt16(
      offset,
      (normalized * 32767).round().clamp(-32768, 32767),
      Endian.little,
    );
    offset += 2;
  }

  return byteData.buffer.asUint8List();
}

double _variantRandom({
  required int variant,
  required double seed,
  required int salt,
}) {
  final x =
      math.sin((variant + 1) * 17.231 + seed * 9.173 + salt * 13.97) *
      43758.5453;
  return x - x.floorToDouble();
}

double _smoothStep(double value) {
  final x = value.clamp(0.0, 1.0);
  return x * x * (3 - 2 * x);
}

double _softClip(double value) {
  final x = value.clamp(-3.0, 3.0);
  return x / (1 + x.abs());
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

class ToolboxFreeChimeWindMicSample {
  const ToolboxFreeChimeWindMicSample({
    required this.timestamp,
    required this.level,
    required this.rawLevel,
    required this.noiseFloor,
    required this.texture,
    required this.gust,
    required this.confidence,
  });

  final DateTime timestamp;
  final double level;
  final double rawLevel;
  final double noiseFloor;
  final double texture;
  final double gust;
  final double confidence;

  bool get isWindLike => confidence >= 0.24 && level >= 0.018;
}

class ToolboxFreeChimeWindMicAnalyzer {
  double _noiseFloor = 0;
  double _smoothedLevel = 0;
  double _confidence = 0;
  double _previousSample = 0;

  void reset() {
    _noiseFloor = 0;
    _smoothedLevel = 0;
    _confidence = 0;
    _previousSample = 0;
  }

  ToolboxFreeChimeWindMicSample? analyzePcm16(
    Uint8List chunk, {
    DateTime? timestamp,
  }) {
    final byteData = ByteData.sublistView(chunk);
    final sampleCount = byteData.lengthInBytes ~/ 2;
    if (sampleCount < 96) {
      return null;
    }

    var peak = 0.0;
    var sumSquares = 0.0;
    var sumAbs = 0.0;
    var diffAbs = 0.0;
    var previous = _previousSample;

    for (var index = 0; index < sampleCount; index += 1) {
      final sample = byteData.getInt16(index * 2, Endian.little) / 32768.0;
      final absValue = sample.abs();
      peak = math.max(peak, absValue);
      sumSquares += sample * sample;
      sumAbs += absValue;
      diffAbs += (sample - previous).abs();
      previous = sample;
    }
    _previousSample = previous;

    final rms = math.sqrt(sumSquares / sampleCount);
    final meanAbs = sumAbs / sampleCount;
    final rawLevel = math.max(_logLevel(rms, gain: 190), meanAbs * 7.2);
    final texture = (diffAbs / sampleCount * 58).clamp(0.0, 1.0).toDouble();
    final gust = _logLevel(peak, gain: 70);

    final floorTarget = _smoothedLevel > 0.05
        ? math.min(rawLevel, _noiseFloor + 0.012)
        : rawLevel;
    final floorSmoothing = _smoothedLevel > 0.05 ? 0.992 : 0.94;
    _noiseFloor =
        (_noiseFloor * floorSmoothing + floorTarget * (1 - floorSmoothing))
            .clamp(0.0, 0.42)
            .toDouble();

    final effectiveFloor = (_noiseFloor + 0.006).clamp(0.006, 0.56).toDouble();
    final aboveFloor = math.max(0.0, rawLevel - effectiveFloor);
    final breezeEnergy = (aboveFloor / 0.18).clamp(0.0, 1.0).toDouble();
    final textureEnergy = math
        .max(0.0, texture - effectiveFloor * 0.42)
        .clamp(0.0, 1.0)
        .toDouble();
    final gustEnergy = math
        .max(0.0, gust - effectiveFloor * 0.7)
        .clamp(0.0, 1.0)
        .toDouble();

    final windCandidate =
        (breezeEnergy * 0.7 + textureEnergy * 0.22 + gustEnergy * 0.08)
            .clamp(0.0, 1.0)
            .toDouble();
    final windLike =
        windCandidate >= 0.025 &&
        (aboveFloor >= 0.008 || textureEnergy >= 0.08 || gustEnergy >= 0.1);
    _confidence = (_confidence * 0.72 + (windLike ? 1.0 : 0.0) * 0.28)
        .clamp(0.0, 1.0)
        .toDouble();

    final confidenceGate = (0.42 + _confidence * 0.58).clamp(0.0, 1.0);
    final gatedLevel = windCandidate * confidenceGate;
    final smoothing = gatedLevel > _smoothedLevel ? 0.48 : 0.86;
    _smoothedLevel = (_smoothedLevel * smoothing + gatedLevel * (1 - smoothing))
        .clamp(0.0, 1.0)
        .toDouble();

    return ToolboxFreeChimeWindMicSample(
      timestamp: timestamp ?? DateTime.now(),
      level: _smoothedLevel,
      rawLevel: rawLevel.clamp(0.0, 1.0).toDouble(),
      noiseFloor: _noiseFloor,
      texture: texture,
      gust: gust,
      confidence: _confidence,
    );
  }

  static double _logLevel(double value, {required double gain}) {
    if (!value.isFinite || value <= 0) {
      return 0;
    }
    return (math.log(1 + value * gain) / math.log(1 + gain))
        .clamp(0.0, 1.0)
        .toDouble();
  }
}

class ToolboxFreeChimeWindMicService {
  ToolboxFreeChimeWindMicService({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  final ToolboxFreeChimeWindMicAnalyzer _analyzer =
      ToolboxFreeChimeWindMicAnalyzer();
  final StreamController<ToolboxFreeChimeWindMicSample> _samples =
      StreamController<ToolboxFreeChimeWindMicSample>.broadcast();

  StreamSubscription<Uint8List>? _pcmSubscription;
  bool _running = false;

  Stream<ToolboxFreeChimeWindMicSample> get samples => _samples.stream;
  bool get isRunning => _running;

  Future<bool> start() async {
    if (kIsWeb) {
      return false;
    }
    await stop();
    try {
      final granted = await _recorder.hasPermission();
      if (!granted) {
        return false;
      }
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
          streamBufferSize: 2048,
        ),
      );
      _analyzer.reset();
      _pcmSubscription = stream.listen(
        _handlePcmChunk,
        onError: (_, _) {
          unawaited(stop());
        },
        onDone: () {
          _running = false;
        },
        cancelOnError: false,
      );
      _running = true;
      return true;
    } catch (_) {
      await stop();
      return false;
    }
  }

  Future<void> stop() async {
    await _pcmSubscription?.cancel();
    _pcmSubscription = null;
    _running = false;
    _analyzer.reset();
    try {
      await _recorder.stop();
    } catch (_) {
      // Best-effort recorder cleanup.
    }
  }

  Future<void> dispose() async {
    await stop();
    await _samples.close();
    try {
      await _recorder.dispose();
    } catch (_) {
      // Best-effort recorder cleanup.
    }
  }

  void _handlePcmChunk(Uint8List chunk) {
    final sample = _analyzer.analyzePcm16(chunk);
    if (sample == null || _samples.isClosed) {
      return;
    }
    _samples.add(sample);
  }
}

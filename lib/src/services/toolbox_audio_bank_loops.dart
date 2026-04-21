part of 'toolbox_audio_service.dart';

Uint8List _buildSoothingLoop(String presetId) {
  final chords = switch (presetId) {
    'mist' => const <List<double>>[
      <double>[196.00, 293.66, 392.00],
      <double>[220.00, 293.66, 440.00],
      <double>[174.61, 261.63, 392.00],
      <double>[196.00, 293.66, 392.00],
    ],
    'harbor' => const <List<double>>[
      <double>[220.00, 329.63, 493.88],
      <double>[246.94, 369.99, 440.00],
      <double>[196.00, 293.66, 440.00],
      <double>[220.00, 329.63, 493.88],
    ],
    _ => const <List<double>>[
      <double>[174.61, 261.63, 392.00],
      <double>[196.00, 293.66, 440.00],
      <double>[220.00, 329.63, 493.88],
      <double>[174.61, 261.63, 392.00],
    ],
  };
  final brightness = switch (presetId) {
    'mist' => 0.18,
    'harbor' => 0.28,
    _ => 0.22,
  };
  return _buildPadLoop(chords: chords, brightness: brightness);
}

Uint8List _buildSoothingSceneLoop(String sceneId) {
  return switch (sceneId) {
    'motion' => _buildMotionLoop(),
    'harp_scene' => _buildHarpLoop(),
    'music_box' => _buildMusicBoxLoop(),
    _ => _buildSoothingLoop(sceneId),
  };
}

Uint8List _buildPadLoop({
  required List<List<double>> chords,
  required double brightness,
}) {
  const sampleRate = 22050;
  const chordDuration = 3.0;
  final totalDuration = chordDuration * chords.length;
  final totalSamples = (sampleRate * totalDuration).round();
  final samples = List<double>.filled(totalSamples, 0);

  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    final chordIndex = (t / chordDuration).floor().clamp(0, chords.length - 1);
    final chord = chords[chordIndex];
    final localT = t - chordIndex * chordDuration;
    final attack = (localT / 0.55).clamp(0.0, 1.0);
    final release = ((chordDuration - localT) / 0.95).clamp(0.0, 1.0);
    final envelope = _smoothStep(attack) * _smoothStep(release);
    final pulse = 0.9 + 0.1 * math.sin(math.pi * 2 * 0.15 * t);

    var value = 0.0;
    for (final note in chord) {
      value += math.sin(math.pi * 2 * note * t) * 0.24;
      value +=
          math.sin(math.pi * 2 * note * 2 * t + 0.35) *
          (0.08 + brightness * 0.07);
      value +=
          math.sin(math.pi * 2 * note * 3 * t + 1.2) *
          (0.03 + brightness * 0.04);
    }

    final globalFadeIn = (t / 0.8).clamp(0.0, 1.0);
    final globalFadeOut = ((totalDuration - t) / 0.8).clamp(0.0, 1.0);
    samples[i] =
        value *
        envelope *
        pulse *
        _smoothStep(globalFadeIn) *
        _smoothStep(globalFadeOut);
  }

  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.9);
}

Uint8List _buildMotionLoop() {
  const sampleRate = 24000;
  const durationSeconds = 8.0;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0);
  final pulseSpacing = 60 / 108;
  final chord = <double>[110.0, 220.0, 329.63];

  for (var i = 0; i < totalSamples; i += 1) {
    final t = i / sampleRate;
    var value = 0.0;
    for (final note in chord) {
      value += math.sin(math.pi * 2 * note * t) * 0.18;
      value += math.sin(math.pi * 2 * note * 2 * t + 0.18) * 0.08;
    }

    var pulse = 0.0;
    for (var beat = 0.0; beat < durationSeconds; beat += pulseSpacing) {
      final local = t - beat;
      if (local < 0 || local > 0.18) continue;
      pulse +=
          math.sin(math.pi * 2 * 74 * local) *
          (1 - math.exp(-80 * local)) *
          math.exp(-13 * local) *
          0.75;
    }

    final shimmer =
        math.sin(math.pi * 2 * 659.25 * t) *
        (0.04 + 0.02 * math.sin(math.pi * 2 * 0.5 * t));
    samples[i] = (value + pulse + shimmer) * 0.72;
  }
  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.9);
}

Uint8List _buildHarpLoop() {
  return _buildSequenceLoop(
    durationSeconds: 8,
    events: const <_LoopEvent>[
      _LoopEvent(0.0, 261.63, 1.9, 0.84, _LoopTimbre.pluck),
      _LoopEvent(0.35, 329.63, 1.8, 0.72, _LoopTimbre.pluck),
      _LoopEvent(0.7, 392.0, 1.9, 0.76, _LoopTimbre.pluck),
      _LoopEvent(1.1, 523.25, 1.8, 0.68, _LoopTimbre.pluck),
      _LoopEvent(2.0, 293.66, 1.8, 0.82, _LoopTimbre.pluck),
      _LoopEvent(2.35, 349.23, 1.8, 0.72, _LoopTimbre.pluck),
      _LoopEvent(2.7, 440.0, 1.9, 0.76, _LoopTimbre.pluck),
      _LoopEvent(3.05, 587.33, 1.8, 0.66, _LoopTimbre.pluck),
      _LoopEvent(4.0, 261.63, 1.9, 0.84, _LoopTimbre.pluck),
      _LoopEvent(4.35, 329.63, 1.8, 0.72, _LoopTimbre.pluck),
      _LoopEvent(4.7, 392.0, 1.9, 0.76, _LoopTimbre.pluck),
      _LoopEvent(5.1, 659.25, 1.9, 0.62, _LoopTimbre.pluck),
      _LoopEvent(6.0, 220.0, 1.8, 0.78, _LoopTimbre.pluck),
      _LoopEvent(6.35, 293.66, 1.8, 0.7, _LoopTimbre.pluck),
      _LoopEvent(6.7, 392.0, 1.9, 0.76, _LoopTimbre.pluck),
      _LoopEvent(7.05, 523.25, 1.8, 0.64, _LoopTimbre.pluck),
    ],
  );
}

Uint8List _buildMusicBoxLoop() {
  return _buildSequenceLoop(
    durationSeconds: 8,
    events: const <_LoopEvent>[
      _LoopEvent(0.0, 659.25, 1.2, 0.82, _LoopTimbre.bell),
      _LoopEvent(0.55, 783.99, 1.2, 0.74, _LoopTimbre.bell),
      _LoopEvent(1.1, 880.0, 1.15, 0.7, _LoopTimbre.bell),
      _LoopEvent(1.7, 783.99, 1.2, 0.7, _LoopTimbre.bell),
      _LoopEvent(2.25, 659.25, 1.25, 0.8, _LoopTimbre.bell),
      _LoopEvent(3.0, 587.33, 1.1, 0.74, _LoopTimbre.bell),
      _LoopEvent(3.55, 659.25, 1.2, 0.78, _LoopTimbre.bell),
      _LoopEvent(4.1, 783.99, 1.2, 0.72, _LoopTimbre.bell),
      _LoopEvent(4.7, 987.77, 1.15, 0.62, _LoopTimbre.bell),
      _LoopEvent(5.35, 880.0, 1.2, 0.68, _LoopTimbre.bell),
      _LoopEvent(6.0, 783.99, 1.2, 0.7, _LoopTimbre.bell),
      _LoopEvent(6.65, 659.25, 1.2, 0.78, _LoopTimbre.bell),
    ],
  );
}

Uint8List _buildSequenceLoop({
  required double durationSeconds,
  required List<_LoopEvent> events,
}) {
  const sampleRate = 24000;
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = List<double>.filled(totalSamples, 0);

  for (final event in events) {
    final startIndex = (event.startSeconds * sampleRate).round();
    final endIndex = ((event.startSeconds + event.durationSeconds) * sampleRate)
        .round();
    for (var i = startIndex; i < endIndex && i < totalSamples; i += 1) {
      final t = (i - startIndex) / sampleRate;
      final normalizedT = t / event.durationSeconds;
      final sample = switch (event.timbre) {
        _LoopTimbre.pluck => _pluckSample(
          frequency: event.frequency,
          t: t,
          normalizedT: normalizedT,
        ),
        _LoopTimbre.bell => _bellSample(
          frequency: event.frequency,
          t: t,
          normalizedT: normalizedT,
        ),
      };
      samples[i] += sample * event.volume;
    }
  }

  return _encodeWav(samples, sampleRate: sampleRate, gain: 0.92);
}

double _pluckSample({
  required double frequency,
  required double t,
  required double normalizedT,
}) {
  final envelope =
      (1 - math.exp(-34 * t)) *
      math.exp(-2.9 * t) *
      (1 - normalizedT).clamp(0.0, 1.0);
  var value = math.sin(math.pi * 2 * frequency * t) * 0.72;
  value += math.sin(math.pi * 2 * frequency * 2 * t + 0.4) * 0.22;
  value += math.sin(math.pi * 2 * frequency * 3.2 * t + 0.86) * 0.1;
  return value * envelope;
}

double _bellSample({
  required double frequency,
  required double t,
  required double normalizedT,
}) {
  final envelope =
      (1 - math.exp(-55 * t)) *
      math.exp(-3.6 * t) *
      (1 - normalizedT * 0.3).clamp(0.0, 1.0);
  var value = math.sin(math.pi * 2 * frequency * t) * 0.58;
  value += math.sin(math.pi * 2 * frequency * 2.76 * t + 0.2) * 0.24;
  value += math.sin(math.pi * 2 * frequency * 4.12 * t + 0.9) * 0.12;
  value += math.sin(math.pi * 2 * frequency * 5.43 * t + 1.8) * 0.06;
  return value * envelope;
}

class _LoopEvent {
  const _LoopEvent(
    this.startSeconds,
    this.frequency,
    this.durationSeconds,
    this.volume,
    this.timbre,
  );

  final double startSeconds;
  final double frequency;
  final double durationSeconds;
  final double volume;
  final _LoopTimbre timbre;
}

enum _LoopTimbre { pluck, bell }

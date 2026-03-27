import 'dart:math' as math;
import 'dart:typed_data';

class SoothingSceneAudio {
  const SoothingSceneAudio({
    required this.id,
    required this.bytes,
    required this.durationSeconds,
    required this.spectrumFrames,
  });

  final String id;
  final Uint8List bytes;
  final double durationSeconds;
  final List<List<double>> spectrumFrames;
}

class ToolboxSoothingAudioService {
  ToolboxSoothingAudioService._();

  static final Map<String, Future<SoothingSceneAudio>> _cache =
      <String, Future<SoothingSceneAudio>>{};

  static Future<SoothingSceneAudio> load(String sceneId) {
    return _cache.putIfAbsent(sceneId, () async => _buildScene(sceneId));
  }

  static Future<void> preload(Iterable<String> sceneIds) async {
    for (final sceneId in sceneIds) {
      await load(sceneId);
    }
  }

  static Future<SoothingSceneAudio> _buildScene(String sceneId) async {
    final render = switch (sceneId) {
      'study' => _ToolboxSoothingBuilders.buildStudyScene(),
      'sleep' => _ToolboxSoothingBuilders.buildSleepScene(),
      'jazz' => _ToolboxSoothingBuilders.buildJazzScene(),
      'piano' => _ToolboxSoothingBuilders.buildPianoScene(),
      'motion' => _ToolboxSoothingBuilders.buildMotionScene(),
      'harp' => _ToolboxSoothingBuilders.buildHarpScene(),
      'music_box' => _ToolboxSoothingBuilders.buildMusicBoxScene(),
      _ => _ToolboxSoothingBuilders.buildRelaxScene(),
    };
    final frames = _analyzeSpectrumFrames(
      render.samples,
      sampleRate: render.sampleRate,
    );
    final bytes = _encodeWav(
      render.samples,
      sampleRate: render.sampleRate,
      gain: render.gain,
    );
    return SoothingSceneAudio(
      id: sceneId,
      bytes: bytes,
      durationSeconds: render.durationSeconds,
      spectrumFrames: frames,
    );
  }

  static List<List<double>> _analyzeSpectrumFrames(
    List<double> samples, {
    required int sampleRate,
  }) {
    const windowSize = 2048;
    const hopSize = 768;
    const bands = <double>[90, 180, 360, 720, 1440, 2880];
    final frames = <List<double>>[];
    final maxima = List<double>.filled(bands.length, 0.000001);

    for (
      var start = 0;
      start + windowSize <= samples.length;
      start += hopSize
    ) {
      final frame = List<double>.filled(bands.length, 0);
      for (var i = 0; i < bands.length; i += 1) {
        final energy = _goertzelMagnitude(
          samples,
          start: start,
          size: windowSize,
          sampleRate: sampleRate,
          targetFrequency: bands[i],
        );
        frame[i] = energy;
        maxima[i] = math.max(maxima[i], energy);
      }
      frames.add(frame);
    }

    if (frames.isEmpty) {
      return const <List<double>>[
        <double>[0, 0, 0, 0, 0, 0],
      ];
    }

    return frames
        .map(
          (frame) => List<double>.generate(frame.length, (index) {
            final normalized = (frame[index] / maxima[index]).clamp(0.0, 1.0);
            return math.pow(normalized, 0.82).toDouble();
          }, growable: false),
        )
        .toList(growable: false);
  }

  static double _goertzelMagnitude(
    List<double> samples, {
    required int start,
    required int size,
    required int sampleRate,
    required double targetFrequency,
  }) {
    final omega = (2 * math.pi * targetFrequency) / sampleRate;
    final coeff = 2 * math.cos(omega);
    var s0 = 0.0;
    var s1 = 0.0;
    var s2 = 0.0;
    for (var i = 0; i < size; i += 1) {
      s0 = samples[start + i] + coeff * s1 - s2;
      s2 = s1;
      s1 = s0;
    }
    final power = s1 * s1 + s2 * s2 - coeff * s1 * s2;
    return power.abs();
  }

  static void _addPadProgression(
    List<double> samples, {
    required int sampleRate,
    required List<List<double>> chords,
    required double chordDuration,
    required double gain,
    required double brightness,
  }) {
    for (var i = 0; i < samples.length; i += 1) {
      final t = i / sampleRate;
      final chordIndex = (t / chordDuration).floor().clamp(
        0,
        chords.length - 1,
      );
      final chord = chords[chordIndex];
      final localT = t - chordIndex * chordDuration;
      final attack = _smoothStep((localT / 0.7).clamp(0.0, 1.0));
      final release = _smoothStep(
        ((chordDuration - localT) / 1.0).clamp(0.0, 1.0),
      );
      final envelope = attack * release;
      var value = 0.0;
      for (final note in chord) {
        value += math.sin(math.pi * 2 * note * t) * 0.24;
        value +=
            math.sin(math.pi * 2 * note * 2 * t + 0.2) *
            (0.08 + brightness * 0.07);
        value +=
            math.sin(math.pi * 2 * note * 3 * t + 0.95) *
            (0.03 + brightness * 0.04);
      }
      final pulse = 0.95 + 0.05 * math.sin(math.pi * 2 * 0.15 * t);
      samples[i] += value * envelope * pulse * gain;
    }
  }

  static void _addSubBassPulses(
    List<double> samples, {
    required int sampleRate,
    required List<_BassEvent> events,
  }) {
    for (final event in events) {
      final startIndex = (event.startSeconds * sampleRate).round();
      final length = (sampleRate * 0.42).round();
      for (var i = 0; i < length && startIndex + i < samples.length; i += 1) {
        final t = i / sampleRate;
        final envelope = (1 - math.exp(-40 * t)) * math.exp(-7.8 * t);
        var value = math.sin(math.pi * 2 * event.frequency * t) * 0.85;
        value += math.sin(math.pi * 2 * event.frequency * 2 * t + 0.1) * 0.16;
        samples[startIndex + i] += value * envelope * event.volume;
      }
    }
  }

  static void _addPercussion(
    List<double> samples, {
    required int sampleRate,
    required double bpm,
    required bool kick,
    required bool snare,
    required bool hat,
    double kickGain = 0.32,
    double snareGain = 0.12,
    double hatGain = 0.05,
  }) {
    final beat = 60 / bpm;
    for (var barT = 0.0; barT < samples.length / sampleRate; barT += beat) {
      final beatIndex = (barT / beat).round();
      if (kick && beatIndex.isEven) {
        _mixPercussionBuffer(
          samples,
          sampleRate: sampleRate,
          startSeconds: barT,
          buffer: _buildKickBuffer(sampleRate: sampleRate),
          gain: kickGain,
        );
      }
      if (snare && beatIndex.isOdd) {
        _mixPercussionBuffer(
          samples,
          sampleRate: sampleRate,
          startSeconds: barT,
          buffer: _buildSnareBuffer(sampleRate: sampleRate),
          gain: snareGain,
        );
      }
      if (hat) {
        _mixPercussionBuffer(
          samples,
          sampleRate: sampleRate,
          startSeconds: barT,
          buffer: _buildHatBuffer(sampleRate: sampleRate),
          gain: hatGain,
        );
        _mixPercussionBuffer(
          samples,
          sampleRate: sampleRate,
          startSeconds: barT + beat / 2,
          buffer: _buildHatBuffer(sampleRate: sampleRate),
          gain: hatGain * 0.82,
        );
      }
    }
  }

  static void _addBrushPercussion(
    List<double> samples, {
    required int sampleRate,
    required double bpm,
  }) {
    final beat = 60 / bpm;
    for (var barT = 0.0; barT < samples.length / sampleRate; barT += beat) {
      final beatIndex = (barT / beat).round();
      _mixPercussionBuffer(
        samples,
        sampleRate: sampleRate,
        startSeconds: barT,
        buffer: _buildBrushHatBuffer(sampleRate: sampleRate),
        gain: 0.05,
      );
      if (beatIndex.isOdd) {
        _mixPercussionBuffer(
          samples,
          sampleRate: sampleRate,
          startSeconds: barT,
          buffer: _buildBrushSnareBuffer(sampleRate: sampleRate),
          gain: 0.1,
        );
      }
    }
  }

  static void _addAirNoise(
    List<double> samples, {
    required int sampleRate,
    required double gain,
  }) {
    for (var i = 0; i < samples.length; i += 1) {
      final t = i / sampleRate;
      final slow = 0.6 + 0.4 * math.sin(math.pi * 2 * 0.07 * t);
      final noise =
          (math.sin(i * 12.9898) + math.cos(i * 78.233) + math.sin(i * 3.11)) *
          0.012;
      samples[i] += noise * slow * gain;
    }
  }

  static void _mixPercussionBuffer(
    List<double> samples, {
    required int sampleRate,
    required double startSeconds,
    required List<double> buffer,
    required double gain,
  }) {
    final startIndex = (startSeconds * sampleRate).round();
    for (
      var i = 0;
      i < buffer.length && startIndex + i < samples.length;
      i += 1
    ) {
      samples[startIndex + i] += buffer[i] * gain;
    }
  }

  static void _mixEventBuffers(
    List<double> samples, {
    required int sampleRate,
    required List<_NoteEvent> events,
    required List<double> Function({
      required double frequency,
      required double durationSeconds,
      required int sampleRate,
    })
    builder,
  }) {
    for (final event in events) {
      final buffer = builder(
        frequency: event.frequency,
        durationSeconds: event.durationSeconds,
        sampleRate: sampleRate,
      );
      final startIndex = (event.startSeconds * sampleRate).round();
      for (
        var i = 0;
        i < buffer.length && startIndex + i < samples.length;
        i += 1
      ) {
        samples[startIndex + i] += buffer[i] * event.volume;
      }
    }
  }

  static List<double> _buildPianoBuffer({
    required double frequency,
    required double durationSeconds,
    required int sampleRate,
  }) {
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final normalizedT = t / durationSeconds;
      final attack = 1 - math.exp(-58 * t);
      final decay = math.exp(-3.8 * t);
      final envelope =
          attack * decay * (1 - normalizedT * 0.25).clamp(0.0, 1.0);
      var value = math.sin(math.pi * 2 * frequency * t) * 0.58;
      value += math.sin(math.pi * 2 * frequency * 2 * t + 0.15) * 0.26;
      value += math.sin(math.pi * 2 * frequency * 3 * t + 0.42) * 0.12;
      samples[i] = value * envelope;
    }
    return samples;
  }

  static List<double> _buildPluckBuffer({
    required double frequency,
    required double durationSeconds,
    required int sampleRate,
  }) {
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final normalizedT = t / durationSeconds;
      final envelope =
          (1 - math.exp(-34 * t)) *
          math.exp(-2.9 * t) *
          (1 - normalizedT).clamp(0.0, 1.0);
      var value = math.sin(math.pi * 2 * frequency * t) * 0.72;
      value += math.sin(math.pi * 2 * frequency * 2 * t + 0.4) * 0.22;
      value += math.sin(math.pi * 2 * frequency * 3.2 * t + 0.86) * 0.1;
      samples[i] = value * envelope;
    }
    return samples;
  }

  static List<double> _buildBellBuffer({
    required double frequency,
    required double durationSeconds,
    required int sampleRate,
  }) {
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final normalizedT = t / durationSeconds;
      final envelope =
          (1 - math.exp(-55 * t)) *
          math.exp(-3.6 * t) *
          (1 - normalizedT * 0.3).clamp(0.0, 1.0);
      var value = math.sin(math.pi * 2 * frequency * t) * 0.58;
      value += math.sin(math.pi * 2 * frequency * 2.76 * t + 0.2) * 0.24;
      value += math.sin(math.pi * 2 * frequency * 4.12 * t + 0.9) * 0.12;
      samples[i] = value * envelope;
    }
    return samples;
  }

  static List<double> _buildKickBuffer({required int sampleRate}) {
    const durationSeconds = 0.22;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final freq = 94 - 52 * (t / durationSeconds);
      final envelope = (1 - math.exp(-70 * t)) * math.exp(-14 * t);
      samples[i] = math.sin(math.pi * 2 * freq * t) * envelope;
    }
    return samples;
  }

  static List<double> _buildSnareBuffer({required int sampleRate}) {
    const durationSeconds = 0.16;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final envelope = (1 - math.exp(-90 * t)) * math.exp(-24 * t);
      final noise =
          (math.sin(i * 12.9898) +
              math.cos(i * 78.233) +
              math.sin(i * 37.719)) *
          0.18;
      final tone = math.sin(math.pi * 2 * 220 * t) * 0.12;
      samples[i] = (noise + tone) * envelope;
    }
    return samples;
  }

  static List<double> _buildHatBuffer({required int sampleRate}) {
    const durationSeconds = 0.08;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final envelope = (1 - math.exp(-120 * t)) * math.exp(-50 * t);
      final noise =
          (math.sin(i * 12.9898) + math.cos(i * 78.233) + math.sin(i * 22.17)) *
          0.12;
      samples[i] = noise * envelope;
    }
    return samples;
  }

  static List<double> _buildBrushSnareBuffer({required int sampleRate}) {
    const durationSeconds = 0.2;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final envelope = (1 - math.exp(-60 * t)) * math.exp(-16 * t);
      final noise =
          (math.sin(i * 7.71) + math.cos(i * 13.23) + math.sin(i * 17.63)) *
          0.14;
      samples[i] = noise * envelope;
    }
    return samples;
  }

  static List<double> _buildBrushHatBuffer({required int sampleRate}) {
    const durationSeconds = 0.11;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final envelope = (1 - math.exp(-96 * t)) * math.exp(-28 * t);
      final noise =
          (math.sin(i * 5.23) + math.cos(i * 31.11) + math.sin(i * 44.77)) *
          0.08;
      samples[i] = noise * envelope;
    }
    return samples;
  }

  static Uint8List _encodeWav(
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

  static double _smoothStep(double value) {
    final x = value.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }
}

class _RenderedScene {
  const _RenderedScene({
    required this.samples,
    required this.sampleRate,
    required this.durationSeconds,
    required this.gain,
  });

  final List<double> samples;
  final int sampleRate;
  final double durationSeconds;
  final double gain;
}

class _NoteEvent {
  const _NoteEvent(
    this.startSeconds,
    this.frequency,
    this.durationSeconds,
    this.volume,
  );

  final double startSeconds;
  final double frequency;
  final double durationSeconds;
  final double volume;
}

class _BassEvent {
  const _BassEvent(this.startSeconds, this.frequency, this.volume);

  final double startSeconds;
  final double frequency;
  final double volume;
}

class _ToolboxSoothingBuilders {
  static _RenderedScene buildRelaxScene() {
    const sampleRate = 24000;
    const durationSeconds = 12.0;
    final samples = List<double>.filled(
      (sampleRate * durationSeconds).round(),
      0,
    );
    ToolboxSoothingAudioService._addPadProgression(
      samples,
      sampleRate: sampleRate,
      chords: const <List<double>>[
        <double>[174.61, 261.63, 392.0],
        <double>[196.0, 293.66, 440.0],
        <double>[164.81, 246.94, 392.0],
        <double>[196.0, 293.66, 392.0],
      ],
      chordDuration: 3,
      gain: 0.68,
      brightness: 0.18,
    );
    ToolboxSoothingAudioService._addSubBassPulses(
      samples,
      sampleRate: sampleRate,
      events: const <_BassEvent>[
        _BassEvent(0.0, 87.31, 0.24),
        _BassEvent(1.62, 87.31, 0.2),
        _BassEvent(3.0, 98.0, 0.24),
        _BassEvent(4.62, 98.0, 0.2),
        _BassEvent(6.0, 82.41, 0.22),
        _BassEvent(7.62, 82.41, 0.18),
        _BassEvent(9.0, 98.0, 0.22),
        _BassEvent(10.62, 98.0, 0.18),
      ],
    );
    ToolboxSoothingAudioService._addPercussion(
      samples,
      sampleRate: sampleRate,
      bpm: 72,
      kick: true,
      snare: false,
      hat: true,
      hatGain: 0.045,
      kickGain: 0.34,
    );
    ToolboxSoothingAudioService._mixEventBuffers(
      samples,
      sampleRate: sampleRate,
      events: const <_NoteEvent>[
        _NoteEvent(0.4, 392.0, 1.2, 0.18),
        _NoteEvent(1.2, 440.0, 1.15, 0.16),
        _NoteEvent(3.4, 493.88, 1.2, 0.16),
        _NoteEvent(4.1, 523.25, 1.1, 0.14),
        _NoteEvent(6.35, 392.0, 1.2, 0.16),
        _NoteEvent(7.1, 440.0, 1.1, 0.14),
        _NoteEvent(9.2, 493.88, 1.2, 0.16),
        _NoteEvent(10.0, 523.25, 1.1, 0.14),
      ],
      builder: ToolboxSoothingAudioService._buildPianoBuffer,
    );
    return _RenderedScene(
      samples: samples,
      sampleRate: sampleRate,
      durationSeconds: durationSeconds,
      gain: 0.92,
    );
  }

  static _RenderedScene buildStudyScene() {
    const sampleRate = 24000;
    const durationSeconds = 12.0;
    final samples = List<double>.filled(
      (sampleRate * durationSeconds).round(),
      0,
    );
    ToolboxSoothingAudioService._addPadProgression(
      samples,
      sampleRate: sampleRate,
      chords: const <List<double>>[
        <double>[196.0, 293.66, 440.0],
        <double>[220.0, 329.63, 493.88],
        <double>[174.61, 261.63, 392.0],
        <double>[196.0, 293.66, 440.0],
      ],
      chordDuration: 3,
      gain: 0.62,
      brightness: 0.24,
    );
    ToolboxSoothingAudioService._addPercussion(
      samples,
      sampleRate: sampleRate,
      bpm: 84,
      kick: true,
      snare: true,
      hat: true,
      hatGain: 0.06,
      kickGain: 0.32,
      snareGain: 0.12,
    );
    ToolboxSoothingAudioService._addSubBassPulses(
      samples,
      sampleRate: sampleRate,
      events: const <_BassEvent>[
        _BassEvent(0.0, 98.0, 0.24),
        _BassEvent(1.42, 98.0, 0.2),
        _BassEvent(3.0, 110.0, 0.24),
        _BassEvent(4.42, 110.0, 0.2),
        _BassEvent(6.0, 87.31, 0.22),
        _BassEvent(7.42, 87.31, 0.18),
        _BassEvent(9.0, 98.0, 0.22),
        _BassEvent(10.42, 98.0, 0.18),
      ],
    );
    ToolboxSoothingAudioService._mixEventBuffers(
      samples,
      sampleRate: sampleRate,
      events: const <_NoteEvent>[
        _NoteEvent(0.2, 440.0, 0.7, 0.14),
        _NoteEvent(0.6, 493.88, 0.7, 0.12),
        _NoteEvent(1.0, 587.33, 0.7, 0.12),
        _NoteEvent(1.4, 659.25, 0.7, 0.1),
        _NoteEvent(3.2, 493.88, 0.7, 0.14),
        _NoteEvent(3.6, 554.37, 0.7, 0.12),
        _NoteEvent(4.0, 659.25, 0.7, 0.12),
        _NoteEvent(4.4, 739.99, 0.7, 0.1),
        _NoteEvent(6.2, 392.0, 0.7, 0.14),
        _NoteEvent(6.6, 440.0, 0.7, 0.12),
        _NoteEvent(7.0, 493.88, 0.7, 0.12),
        _NoteEvent(7.4, 587.33, 0.7, 0.1),
        _NoteEvent(9.2, 440.0, 0.7, 0.14),
        _NoteEvent(9.6, 493.88, 0.7, 0.12),
        _NoteEvent(10.0, 587.33, 0.7, 0.12),
        _NoteEvent(10.4, 659.25, 0.7, 0.1),
      ],
      builder: ToolboxSoothingAudioService._buildPianoBuffer,
    );
    return _RenderedScene(
      samples: samples,
      sampleRate: sampleRate,
      durationSeconds: durationSeconds,
      gain: 0.94,
    );
  }

  static _RenderedScene buildSleepScene() {
    const sampleRate = 24000;
    const durationSeconds = 12.0;
    final samples = List<double>.filled(
      (sampleRate * durationSeconds).round(),
      0,
    );
    ToolboxSoothingAudioService._addPadProgression(
      samples,
      sampleRate: sampleRate,
      chords: const <List<double>>[
        <double>[130.81, 196.0, 261.63],
        <double>[146.83, 220.0, 293.66],
        <double>[123.47, 185.0, 246.94],
        <double>[130.81, 196.0, 261.63],
      ],
      chordDuration: 3,
      gain: 0.76,
      brightness: 0.1,
    );
    ToolboxSoothingAudioService._mixEventBuffers(
      samples,
      sampleRate: sampleRate,
      events: const <_NoteEvent>[
        _NoteEvent(1.1, 392.0, 2.6, 0.09),
        _NoteEvent(4.2, 349.23, 2.8, 0.08),
        _NoteEvent(7.0, 293.66, 2.8, 0.08),
        _NoteEvent(9.8, 261.63, 2.8, 0.08),
      ],
      builder: ToolboxSoothingAudioService._buildBellBuffer,
    );
    ToolboxSoothingAudioService._addAirNoise(
      samples,
      sampleRate: sampleRate,
      gain: 0.016,
    );
    return _RenderedScene(
      samples: samples,
      sampleRate: sampleRate,
      durationSeconds: durationSeconds,
      gain: 0.88,
    );
  }

  static _RenderedScene buildJazzScene() {
    const sampleRate = 24000;
    const durationSeconds = 12.0;
    final samples = List<double>.filled(
      (sampleRate * durationSeconds).round(),
      0,
    );
    ToolboxSoothingAudioService._addPadProgression(
      samples,
      sampleRate: sampleRate,
      chords: const <List<double>>[
        <double>[220.0, 277.18, 329.63, 392.0],
        <double>[246.94, 311.13, 369.99, 440.0],
        <double>[196.0, 246.94, 293.66, 349.23],
        <double>[207.65, 261.63, 329.63, 392.0],
      ],
      chordDuration: 3,
      gain: 0.42,
      brightness: 0.28,
    );
    ToolboxSoothingAudioService._addSubBassPulses(
      samples,
      sampleRate: sampleRate,
      events: const <_BassEvent>[
        _BassEvent(0.0, 55.0, 0.22),
        _BassEvent(0.75, 61.74, 0.18),
        _BassEvent(1.5, 65.41, 0.2),
        _BassEvent(2.25, 73.42, 0.18),
        _BassEvent(3.0, 61.74, 0.22),
        _BassEvent(3.75, 69.30, 0.18),
        _BassEvent(4.5, 73.42, 0.2),
        _BassEvent(5.25, 82.41, 0.18),
        _BassEvent(6.0, 49.0, 0.22),
        _BassEvent(6.75, 55.0, 0.18),
        _BassEvent(7.5, 61.74, 0.2),
        _BassEvent(8.25, 65.41, 0.18),
        _BassEvent(9.0, 51.91, 0.22),
        _BassEvent(9.75, 58.27, 0.18),
        _BassEvent(10.5, 65.41, 0.2),
        _BassEvent(11.25, 69.30, 0.18),
      ],
    );
    ToolboxSoothingAudioService._addBrushPercussion(
      samples,
      sampleRate: sampleRate,
      bpm: 82,
    );
    ToolboxSoothingAudioService._mixEventBuffers(
      samples,
      sampleRate: sampleRate,
      events: const <_NoteEvent>[
        _NoteEvent(0.18, 392.0, 0.9, 0.14),
        _NoteEvent(0.48, 493.88, 0.8, 0.12),
        _NoteEvent(1.18, 440.0, 0.9, 0.13),
        _NoteEvent(1.52, 587.33, 0.8, 0.11),
        _NoteEvent(3.18, 440.0, 0.9, 0.14),
        _NoteEvent(3.52, 554.37, 0.8, 0.12),
        _NoteEvent(4.18, 493.88, 0.9, 0.13),
        _NoteEvent(4.52, 659.25, 0.8, 0.11),
        _NoteEvent(6.18, 349.23, 0.9, 0.14),
        _NoteEvent(6.52, 440.0, 0.8, 0.12),
        _NoteEvent(7.18, 392.0, 0.9, 0.13),
        _NoteEvent(7.52, 523.25, 0.8, 0.11),
        _NoteEvent(9.18, 369.99, 0.9, 0.14),
        _NoteEvent(9.52, 466.16, 0.8, 0.12),
        _NoteEvent(10.18, 440.0, 0.9, 0.13),
        _NoteEvent(10.52, 587.33, 0.8, 0.11),
      ],
      builder: ToolboxSoothingAudioService._buildPianoBuffer,
    );
    return _RenderedScene(
      samples: samples,
      sampleRate: sampleRate,
      durationSeconds: durationSeconds,
      gain: 0.94,
    );
  }

  static _RenderedScene buildPianoScene() {
    const sampleRate = 24000;
    const durationSeconds = 12.0;
    final samples = List<double>.filled(
      (sampleRate * durationSeconds).round(),
      0,
    );
    ToolboxSoothingAudioService._addPadProgression(
      samples,
      sampleRate: sampleRate,
      chords: const <List<double>>[
        <double>[196.0, 293.66, 392.0],
        <double>[220.0, 329.63, 440.0],
        <double>[174.61, 261.63, 349.23],
        <double>[196.0, 293.66, 392.0],
      ],
      chordDuration: 3,
      gain: 0.34,
      brightness: 0.16,
    );
    ToolboxSoothingAudioService._mixEventBuffers(
      samples,
      sampleRate: sampleRate,
      events: const <_NoteEvent>[
        _NoteEvent(0.0, 392.0, 1.2, 0.22),
        _NoteEvent(0.45, 493.88, 1.05, 0.18),
        _NoteEvent(0.9, 587.33, 1.0, 0.16),
        _NoteEvent(1.35, 783.99, 1.0, 0.14),
        _NoteEvent(2.1, 659.25, 1.2, 0.2),
        _NoteEvent(2.7, 587.33, 1.1, 0.18),
        _NoteEvent(3.3, 440.0, 1.15, 0.2),
        _NoteEvent(3.75, 554.37, 1.0, 0.16),
        _NoteEvent(4.2, 659.25, 1.0, 0.14),
        _NoteEvent(4.65, 739.99, 1.0, 0.12),
        _NoteEvent(6.0, 349.23, 1.2, 0.22),
        _NoteEvent(6.45, 440.0, 1.05, 0.18),
        _NoteEvent(6.9, 523.25, 1.0, 0.16),
        _NoteEvent(7.35, 698.46, 1.0, 0.14),
        _NoteEvent(8.1, 587.33, 1.2, 0.2),
        _NoteEvent(8.7, 523.25, 1.1, 0.18),
        _NoteEvent(9.3, 392.0, 1.1, 0.2),
        _NoteEvent(9.75, 493.88, 1.0, 0.16),
        _NoteEvent(10.2, 587.33, 1.0, 0.14),
        _NoteEvent(10.65, 659.25, 1.0, 0.12),
      ],
      builder: ToolboxSoothingAudioService._buildPianoBuffer,
    );
    return _RenderedScene(
      samples: samples,
      sampleRate: sampleRate,
      durationSeconds: durationSeconds,
      gain: 0.92,
    );
  }

  static _RenderedScene buildMotionScene() {
    const sampleRate = 24000;
    const durationSeconds = 10.0;
    final samples = List<double>.filled(
      (sampleRate * durationSeconds).round(),
      0,
    );
    ToolboxSoothingAudioService._addPadProgression(
      samples,
      sampleRate: sampleRate,
      chords: const <List<double>>[
        <double>[110.0, 220.0, 329.63],
        <double>[123.47, 246.94, 369.99],
        <double>[130.81, 261.63, 392.0],
        <double>[146.83, 293.66, 440.0],
      ],
      chordDuration: 2.5,
      gain: 0.52,
      brightness: 0.32,
    );
    ToolboxSoothingAudioService._addPercussion(
      samples,
      sampleRate: sampleRate,
      bpm: 108,
      kick: true,
      snare: true,
      hat: true,
      kickGain: 0.44,
      snareGain: 0.14,
      hatGain: 0.07,
    );
    ToolboxSoothingAudioService._addSubBassPulses(
      samples,
      sampleRate: sampleRate,
      events: List<_BassEvent>.generate(
        18,
        (index) =>
            _BassEvent(index * (60 / 108), 82.41 + (index % 3) * 9, 0.18),
      ),
    );
    ToolboxSoothingAudioService._mixEventBuffers(
      samples,
      sampleRate: sampleRate,
      events: const <_NoteEvent>[
        _NoteEvent(0.5, 659.25, 0.7, 0.1),
        _NoteEvent(1.1, 783.99, 0.7, 0.1),
        _NoteEvent(2.9, 698.46, 0.7, 0.1),
        _NoteEvent(3.5, 880.0, 0.7, 0.1),
        _NoteEvent(5.3, 739.99, 0.7, 0.1),
        _NoteEvent(5.9, 987.77, 0.7, 0.1),
        _NoteEvent(7.7, 783.99, 0.7, 0.1),
        _NoteEvent(8.3, 1174.66, 0.7, 0.1),
      ],
      builder: ToolboxSoothingAudioService._buildBellBuffer,
    );
    return _RenderedScene(
      samples: samples,
      sampleRate: sampleRate,
      durationSeconds: durationSeconds,
      gain: 0.94,
    );
  }

  static _RenderedScene buildHarpScene() {
    const sampleRate = 24000;
    const durationSeconds = 10.0;
    final samples = List<double>.filled(
      (sampleRate * durationSeconds).round(),
      0,
    );
    ToolboxSoothingAudioService._mixEventBuffers(
      samples,
      sampleRate: sampleRate,
      events: const <_NoteEvent>[
        _NoteEvent(0.0, 261.63, 2.0, 0.82),
        _NoteEvent(0.35, 329.63, 1.8, 0.72),
        _NoteEvent(0.7, 392.0, 1.9, 0.76),
        _NoteEvent(1.1, 523.25, 1.8, 0.68),
        _NoteEvent(2.0, 293.66, 1.8, 0.82),
        _NoteEvent(2.35, 349.23, 1.8, 0.72),
        _NoteEvent(2.7, 440.0, 1.9, 0.76),
        _NoteEvent(3.05, 587.33, 1.8, 0.66),
        _NoteEvent(4.0, 261.63, 1.9, 0.84),
        _NoteEvent(4.35, 329.63, 1.8, 0.72),
        _NoteEvent(4.7, 392.0, 1.9, 0.76),
        _NoteEvent(5.1, 659.25, 1.9, 0.62),
        _NoteEvent(6.0, 220.0, 1.8, 0.78),
        _NoteEvent(6.35, 293.66, 1.8, 0.7),
        _NoteEvent(6.7, 392.0, 1.9, 0.76),
        _NoteEvent(7.05, 523.25, 1.8, 0.64),
        _NoteEvent(8.0, 261.63, 1.8, 0.76),
        _NoteEvent(8.35, 329.63, 1.8, 0.66),
      ],
      builder: ToolboxSoothingAudioService._buildPluckBuffer,
    );
    ToolboxSoothingAudioService._addPadProgression(
      samples,
      sampleRate: sampleRate,
      chords: const <List<double>>[
        <double>[174.61, 261.63, 392.0],
        <double>[196.0, 293.66, 440.0],
        <double>[164.81, 246.94, 392.0],
        <double>[174.61, 261.63, 392.0],
      ],
      chordDuration: 2.5,
      gain: 0.18,
      brightness: 0.18,
    );
    return _RenderedScene(
      samples: samples,
      sampleRate: sampleRate,
      durationSeconds: durationSeconds,
      gain: 0.94,
    );
  }

  static _RenderedScene buildMusicBoxScene() {
    const sampleRate = 24000;
    const durationSeconds = 10.0;
    final samples = List<double>.filled(
      (sampleRate * durationSeconds).round(),
      0,
    );
    ToolboxSoothingAudioService._mixEventBuffers(
      samples,
      sampleRate: sampleRate,
      events: const <_NoteEvent>[
        _NoteEvent(0.0, 659.25, 1.2, 0.82),
        _NoteEvent(0.55, 783.99, 1.2, 0.74),
        _NoteEvent(1.1, 880.0, 1.15, 0.7),
        _NoteEvent(1.7, 783.99, 1.2, 0.7),
        _NoteEvent(2.25, 659.25, 1.25, 0.8),
        _NoteEvent(3.0, 587.33, 1.1, 0.74),
        _NoteEvent(3.55, 659.25, 1.2, 0.78),
        _NoteEvent(4.1, 783.99, 1.2, 0.72),
        _NoteEvent(4.7, 987.77, 1.15, 0.62),
        _NoteEvent(5.35, 880.0, 1.2, 0.68),
        _NoteEvent(6.0, 783.99, 1.2, 0.7),
        _NoteEvent(6.65, 659.25, 1.2, 0.78),
        _NoteEvent(7.3, 587.33, 1.1, 0.7),
        _NoteEvent(7.85, 523.25, 1.15, 0.66),
        _NoteEvent(8.45, 659.25, 1.2, 0.74),
      ],
      builder: ToolboxSoothingAudioService._buildBellBuffer,
    );
    ToolboxSoothingAudioService._addAirNoise(
      samples,
      sampleRate: sampleRate,
      gain: 0.01,
    );
    return _RenderedScene(
      samples: samples,
      sampleRate: sampleRate,
      durationSeconds: durationSeconds,
      gain: 0.9,
    );
  }
}

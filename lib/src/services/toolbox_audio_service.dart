import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

final AudioContext _toolboxAudioContext = AudioContextConfig(
  focus: AudioContextConfigFocus.mixWithOthers,
).build();

class ToolboxLoopController {
  final AudioPlayer _player = AudioPlayer();
  bool _audioContextConfigured = false;
  Uint8List? _activeBytes;

  Future<void> _ensureAudioContext() async {
    if (_audioContextConfigured) return;
    await _player.setAudioContext(_toolboxAudioContext);
    _audioContextConfigured = true;
  }

  Future<void> play(Uint8List bytes, {double volume = 0.7}) async {
    await _ensureAudioContext();
    if (!identical(_activeBytes, bytes)) {
      await _player.setSourceBytes(bytes, mimeType: 'audio/wav');
      _activeBytes = bytes;
    }
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(volume.clamp(0.0, 1.0));
    await _player.resume();
  }

  Future<void> setVolume(double value) {
    return _player.setVolume(value.clamp(0.0, 1.0));
  }

  Future<void> stop() => _player.stop();

  Future<void> dispose() => _player.dispose();
}

class ToolboxEffectPlayer {
  ToolboxEffectPlayer(this.bytes, {this.maxPlayers = 6});

  final Uint8List bytes;
  final int maxPlayers;

  AudioPool? _pool;

  Future<AudioPool> _ensurePool() async {
    final existing = _pool;
    if (existing != null) return existing;
    final created = await AudioPool.create(
      source: BytesSource(bytes, mimeType: 'audio/wav'),
      maxPlayers: maxPlayers,
      minPlayers: math.min(2, maxPlayers),
      audioContext: _toolboxAudioContext,
    );
    _pool = created;
    return created;
  }

  Future<void> play({double volume = 1.0}) async {
    final pool = await _ensurePool();
    await pool.start(volume: volume.clamp(0.0, 1.0));
  }

  Future<void> dispose() async {
    final pool = _pool;
    _pool = null;
    if (pool != null) {
      await pool.dispose();
    }
  }
}

class ToolboxAudioBank {
  ToolboxAudioBank._();

  static final Map<String, Uint8List> _cache = <String, Uint8List>{};

  static Uint8List soothingLoop(String presetId) {
    return _cache.putIfAbsent(
      'soothing:$presetId',
      () => _buildSoothingLoop(presetId),
    );
  }

  static Uint8List soothingSceneLoop(String sceneId) {
    return _cache.putIfAbsent(
      'scene:$sceneId',
      () => _buildSoothingSceneLoop(sceneId),
    );
  }

  static Uint8List harpNote(double frequency) {
    final key = 'harp:${frequency.toStringAsFixed(2)}';
    return _cache.putIfAbsent(
      key,
      () => _buildPluckNote(frequency: frequency, durationSeconds: 2.2),
    );
  }

  static Uint8List metronomeClick({required bool accent}) {
    final key = accent ? 'metronome:accent' : 'metronome:regular';
    return _cache.putIfAbsent(
      key,
      () => _buildClick(
        accent ? 1560.0 : 1080.0,
        overtone: accent ? 1960.0 : 1420.0,
        durationSeconds: accent ? 0.11 : 0.085,
      ),
    );
  }

  static Uint8List woodfishClick() {
    return _cache.putIfAbsent('woodfish', _buildWoodfishClick);
  }

  static Uint8List _buildSoothingLoop(String presetId) {
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

  static Uint8List _buildSoothingSceneLoop(String sceneId) {
    return switch (sceneId) {
      'motion' => _buildMotionLoop(),
      'harp_scene' => _buildHarpLoop(),
      'music_box' => _buildMusicBoxLoop(),
      _ => _buildSoothingLoop(sceneId),
    };
  }

  static Uint8List _buildPadLoop({
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
      final chordIndex = (t / chordDuration).floor().clamp(
        0,
        chords.length - 1,
      );
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

  static Uint8List _buildPluckNote({
    required double frequency,
    required double durationSeconds,
  }) {
    const sampleRate = 24000;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final envelope =
          (1 - math.exp(-36 * t)) *
          math.exp(-2.8 * t) *
          (1 - t / durationSeconds);
      final vibrato = 1 + 0.0025 * math.sin(math.pi * 2 * 5.2 * t);
      final base = frequency * vibrato;
      var value = math.sin(math.pi * 2 * base * t) * 0.72;
      value += math.sin(math.pi * 2 * base * 2 * t + 0.4) * 0.24;
      value += math.sin(math.pi * 2 * base * 3 * t + 0.85) * 0.12;
      value += math.sin(math.pi * 2 * base * 4.8 * t + 1.3) * 0.05;
      samples[i] = value * envelope;
    }
    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.95);
  }

  static Uint8List _buildClick(
    double primaryFrequency, {
    required double overtone,
    required double durationSeconds,
  }) {
    const sampleRate = 24000;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final envelope = (1 - math.exp(-110 * t)) * math.exp(-38 * t);
      final noise = (math.sin(i * 12.9898) + math.cos(i * 78.233)) * 0.025;
      final value =
          math.sin(math.pi * 2 * primaryFrequency * t) * 0.7 +
          math.sin(math.pi * 2 * overtone * t + 0.3) * 0.24 +
          noise;
      samples[i] = value * envelope;
    }
    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.98);
  }

  static Uint8List _buildWoodfishClick() {
    const sampleRate = 24000;
    const durationSeconds = 0.26;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final attack = (1 - math.exp(-95 * t));
      final envelope = attack * math.exp(-11.5 * t);
      final resonance = math.sin(math.pi * 2 * 248 * t) * 0.64;
      final overtone = math.sin(math.pi * 2 * 516 * t + 0.28) * 0.24;
      final shell = math.sin(math.pi * 2 * 820 * t + 0.95) * 0.08;
      samples[i] = (resonance + overtone + shell) * envelope;
    }
    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.96);
  }

  static Uint8List _buildMotionLoop() {
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

  static Uint8List _buildHarpLoop() {
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

  static Uint8List _buildMusicBoxLoop() {
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

  static Uint8List _buildSequenceLoop({
    required double durationSeconds,
    required List<_LoopEvent> events,
  }) {
    const sampleRate = 24000;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);

    for (final event in events) {
      final startIndex = (event.startSeconds * sampleRate).round();
      final endIndex =
          ((event.startSeconds + event.durationSeconds) * sampleRate).round();
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

  static double _pluckSample({
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

  static double _bellSample({
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

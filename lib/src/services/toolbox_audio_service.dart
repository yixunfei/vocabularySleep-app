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

  Future<void> warmUp() async {
    await _ensurePool();
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

  static Uint8List harpNote(
    double frequency, {
    String style = 'silk',
    double reverb = 0.24,
  }) {
    final normalizedReverb = reverb.clamp(0.0, 0.8).toDouble();
    final key =
        'harp:${frequency.toStringAsFixed(2)}:$style:${normalizedReverb.toStringAsFixed(2)}';
    return _cache.putIfAbsent(
      key,
      () => _buildPluckNote(
        frequency: frequency,
        durationSeconds: 2.4,
        style: style,
        reverb: normalizedReverb,
      ),
    );
  }

  static Uint8List pianoNote(double frequency, {String style = 'concert'}) {
    final normalizedStyle = switch (style) {
      'bright' => 'bright',
      'felt' => 'felt',
      _ => 'concert',
    };
    final key = 'piano:${frequency.toStringAsFixed(2)}:$normalizedStyle';
    return _cache.putIfAbsent(
      key,
      () => _buildPianoNote(frequency, normalizedStyle),
    );
  }

  static Uint8List fluteNote(double frequency, {String style = 'airy'}) {
    final normalizedStyle = switch (style) {
      'lead' => 'lead',
      'alto' => 'alto',
      _ => 'airy',
    };
    final key = 'flute:${frequency.toStringAsFixed(2)}:$normalizedStyle';
    return _cache.putIfAbsent(
      key,
      () => _buildFluteNote(frequency, normalizedStyle),
    );
  }

  static Uint8List guitarNote(double frequency, {String style = 'steel'}) {
    final normalizedStyle = switch (style) {
      'nylon' => 'nylon',
      'ambient' => 'ambient',
      _ => 'steel',
    };
    final key = 'guitar:${frequency.toStringAsFixed(2)}:$normalizedStyle';
    return _cache.putIfAbsent(
      key,
      () => _buildPluckNote(
        frequency: frequency,
        durationSeconds: 2.1,
        style: normalizedStyle == 'ambient' ? 'glass' : normalizedStyle,
        reverb: switch (normalizedStyle) {
          'nylon' => 0.14,
          'ambient' => 0.28,
          _ => 0.16,
        },
      ),
    );
  }

  static Uint8List drumHit(String kind, {String kit = 'acoustic'}) {
    final normalizedKind = switch (kind) {
      'kick' => 'kick',
      'snare' => 'snare',
      'hihat' => 'hihat',
      'tom' => 'tom',
      _ => 'kick',
    };
    final normalizedKit = switch (kit) {
      'electro' => 'electro',
      'lofi' => 'lofi',
      _ => 'acoustic',
    };
    final key = 'drum:$normalizedKind:$normalizedKit';
    return _cache.putIfAbsent(
      key,
      () => _buildDrumHit(normalizedKind, normalizedKit),
    );
  }

  static Uint8List triangleHit({String style = 'orchestral'}) {
    final normalizedStyle = switch (style) {
      'soft' => 'soft',
      'bright' => 'bright',
      _ => 'orchestral',
    };
    final key = 'triangle:hit:$normalizedStyle';
    return _cache.putIfAbsent(key, () => _buildTriangleHit(normalizedStyle));
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
    required String style,
    required double reverb,
  }) {
    const sampleRate = 32000;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    final tone = _pluckTone(style);
    final delaySamples = math.max(18, (sampleRate / frequency).round());
    final ring = List<double>.generate(delaySamples, (i) {
      final phase = i / delaySamples;
      final noise =
          (math.sin((i + 1) * 12.9898 + frequency * 0.005) +
              math.cos((i + 1) * 78.233 + frequency * 0.0017)) *
          0.5;
      final brightMask = phase < tone.brightness ? 1.0 : 0.76;
      return noise * brightMask;
    });
    final bodyPhaseShift = frequency * 0.0003;
    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final env =
          (1 - math.exp(-tone.attack * t)) *
          math.exp(-tone.decay * t) *
          (1 - t / durationSeconds).clamp(0.0, 1.0);

      final idx = i % delaySamples;
      final next = (idx + 1) % delaySamples;
      final averaged = (ring[idx] + ring[next]) * 0.5;
      final lowpass = averaged * (0.86 + tone.brightness * 0.11);
      ring[idx] = lowpass * tone.feedback;
      final stringSample = ring[idx];

      final pickTransient =
          (math.sin(math.pi * 2 * frequency * 4.8 * t + bodyPhaseShift) * 0.55 +
              math.sin(math.pi * 2 * frequency * 7.4 * t + 0.65) * 0.45) *
          math.exp(-45 * t) *
          tone.transient;
      final bodyResonance =
          math.sin(math.pi * 2 * frequency * t) * 0.2 +
          math.sin(math.pi * 2 * frequency * 2.01 * t + 0.36) * 0.1 +
          math.sin(math.pi * 2 * frequency * 3.07 * t + 1.1) * 0.05;
      final shimmer =
          math.sin(math.pi * 2 * frequency * 5.2 * t + 0.7) *
          tone.shimmer *
          math.exp(-3.4 * t);

      final value =
          (stringSample +
              pickTransient +
              bodyResonance * tone.bodyMix +
              shimmer) *
          env;
      samples[i] = _softClip(value * 1.55);
    }
    _applySchroederReverb(samples, sampleRate: sampleRate, amount: reverb);
    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.92);
  }

  static Uint8List _buildPianoNote(double frequency, String style) {
    const sampleRate = 32000;
    const durationSeconds = 2.3;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    final detuneA = frequency * 0.9975;
    final detuneB = frequency * 1.0025;
    final harmonicMix = switch (style) {
      'bright' => 1.18,
      'felt' => 0.82,
      _ => 1.0,
    };
    final decayMul = switch (style) {
      'bright' => 1.08,
      'felt' => 0.82,
      _ => 1.0,
    };
    final hammerNoise = switch (style) {
      'bright' => 0.055,
      'felt' => 0.024,
      _ => 0.04,
    };

    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final env =
          (1 - math.exp(-130 * t)) *
          math.exp(-(3.6 * decayMul) * t) *
          (1 - t / durationSeconds).clamp(0.0, 1.0);
      final hammer =
          (math.sin((i + 1) * 12.9898) + math.cos((i + 1) * 78.233)) *
          hammerNoise *
          math.exp(-95 * t);
      var value = math.sin(math.pi * 2 * frequency * t) * 0.56;
      value += math.sin(math.pi * 2 * detuneA * t + 0.07) * 0.19;
      value += math.sin(math.pi * 2 * detuneB * t - 0.06) * 0.19;
      value +=
          math.sin(math.pi * 2 * frequency * 2 * t + 0.23) *
          (0.18 * harmonicMix);
      value +=
          math.sin(math.pi * 2 * frequency * 3 * t + 0.41) *
          (0.1 * harmonicMix);
      value +=
          math.sin(math.pi * 2 * frequency * 4.2 * t + 0.93) *
          (0.06 * harmonicMix);
      samples[i] = _softClip((value + hammer) * env * 1.42);
    }

    final reverb = switch (style) {
      'bright' => 0.09,
      'felt' => 0.15,
      _ => 0.12,
    };
    _applySchroederReverb(samples, sampleRate: sampleRate, amount: reverb);
    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.94);
  }

  static Uint8List _buildFluteNote(double frequency, String style) {
    const sampleRate = 32000;
    const durationSeconds = 1.9;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    final vibratoDepth = switch (style) {
      'lead' => 0.0034,
      'alto' => 0.0054,
      _ => 0.0042,
    };
    final noiseAmt = switch (style) {
      'lead' => 0.012,
      'alto' => 0.024,
      _ => 0.018,
    };
    final overtoneMul = switch (style) {
      'lead' => 1.2,
      'alto' => 0.82,
      _ => 1.0,
    };
    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final vibrato = 1 + vibratoDepth * math.sin(math.pi * 2 * 5.3 * t);
      final base = frequency * vibrato;
      final env =
          (1 - math.exp(-19 * t)) *
          math.exp(-1.7 * t) *
          (1 - t / durationSeconds).clamp(0.0, 1.0);
      final breathNoise =
          (math.sin((i + 1) * 23.17) + math.cos((i + 1) * 47.31)) *
          noiseAmt *
          math.exp(-2.4 * t);
      var value = math.sin(math.pi * 2 * base * t) * 0.75;
      value +=
          math.sin(math.pi * 2 * base * 2 * t + 0.12) * (0.18 * overtoneMul);
      value +=
          math.sin(math.pi * 2 * base * 3 * t + 0.35) * (0.07 * overtoneMul);
      samples[i] = _softClip((value + breathNoise) * env * 1.25);
    }
    final reverb = switch (style) {
      'lead' => 0.14,
      'alto' => 0.24,
      _ => 0.2,
    };
    _applySchroederReverb(samples, sampleRate: sampleRate, amount: reverb);
    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.92);
  }

  static Uint8List _buildDrumHit(String kind, String kit) {
    return switch (kind) {
      'snare' => _buildSnareHit(kit),
      'hihat' => _buildHiHatHit(kit),
      'tom' => _buildTomHit(kit),
      _ => _buildKickHit(kit),
    };
  }

  static Uint8List _buildKickHit(String kit) {
    const sampleRate = 24000;
    const durationSeconds = 0.42;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    final bodyMul = switch (kit) {
      'electro' => 1.22,
      'lofi' => 0.84,
      _ => 1.0,
    };
    final clickMul = switch (kit) {
      'electro' => 1.3,
      'lofi' => 0.7,
      _ => 1.0,
    };
    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final sweep = 108 - 62 * (t / durationSeconds).clamp(0.0, 1.0);
      final env = math.exp(-12.5 * t);
      final click = math.exp(-95 * t) * (0.08 * clickMul);
      final low = math.sin(math.pi * 2 * sweep * t) * (0.82 * bodyMul);
      samples[i] = _softClip((low + click) * env * 1.4);
    }
    if (kit == 'lofi') {
      _applySchroederReverb(samples, sampleRate: sampleRate, amount: 0.06);
    }
    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.98);
  }

  static Uint8List _buildSnareHit(String kit) {
    const sampleRate = 24000;
    const durationSeconds = 0.32;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    final toneMul = switch (kit) {
      'electro' => 0.86,
      'lofi' => 0.74,
      _ => 1.0,
    };
    final noiseMul = switch (kit) {
      'electro' => 1.18,
      'lofi' => 0.92,
      _ => 1.0,
    };
    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final env = math.exp(-19.5 * t);
      final tone =
          math.sin(math.pi * 2 * 184 * t) * (0.3 * toneMul) * math.exp(-14 * t);
      final noise =
          (math.sin((i + 1) * 91.7) + math.cos((i + 1) * 67.3)) *
          (0.34 * noiseMul);
      samples[i] = _softClip((tone + noise) * env);
    }
    if (kit == 'electro') {
      _applySchroederReverb(samples, sampleRate: sampleRate, amount: 0.08);
    }
    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.98);
  }

  static Uint8List _buildHiHatHit(String kit) {
    const sampleRate = 24000;
    const durationSeconds = 0.18;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    final noiseMul = switch (kit) {
      'electro' => 1.28,
      'lofi' => 0.82,
      _ => 1.0,
    };
    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final env = math.exp(-34 * t);
      final noise =
          (math.sin((i + 1) * 211.3) +
              math.sin((i + 1) * 139.7) +
              math.cos((i + 1) * 97.1)) *
          (0.22 * noiseMul);
      final metal =
          math.sin(math.pi * 2 * 6200 * t) * 0.07 +
          math.sin(math.pi * 2 * 7400 * t + 0.5) * 0.05;
      samples[i] = _softClip((noise + metal) * env);
    }
    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.98);
  }

  static Uint8List _buildTomHit(String kit) {
    const sampleRate = 24000;
    const durationSeconds = 0.38;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    final bodyMul = switch (kit) {
      'electro' => 1.14,
      'lofi' => 0.8,
      _ => 1.0,
    };
    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final env = math.exp(-11 * t);
      final fundamental = math.sin(math.pi * 2 * 136 * t) * (0.62 * bodyMul);
      final overtone = math.sin(math.pi * 2 * 272 * t + 0.2) * 0.2;
      final knock =
          (math.sin((i + 1) * 32.7) + math.cos((i + 1) * 53.2)) *
          0.06 *
          math.exp(-40 * t);
      samples[i] = _softClip((fundamental + overtone + knock) * env * 1.2);
    }
    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.98);
  }

  static Uint8List _buildTriangleHit(String style) {
    const sampleRate = 32000;
    const durationSeconds = 2.2;
    final totalSamples = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(totalSamples, 0);
    final highMul = switch (style) {
      'bright' => 1.22,
      'soft' => 0.74,
      _ => 1.0,
    };
    final decayMul = switch (style) {
      'bright' => 1.12,
      'soft' => 0.78,
      _ => 1.0,
    };
    for (var i = 0; i < totalSamples; i += 1) {
      final t = i / sampleRate;
      final env = (1 - math.exp(-110 * t)) * math.exp(-(2.5 * decayMul) * t);
      var value = math.sin(math.pi * 2 * 980 * t) * 0.52;
      value += math.sin(math.pi * 2 * 1365 * t + 0.34) * (0.3 * highMul);
      value += math.sin(math.pi * 2 * 1810 * t + 0.85) * (0.2 * highMul);
      value += math.sin(math.pi * 2 * 2480 * t + 1.32) * (0.1 * highMul);
      samples[i] = _softClip(value * env * 1.3);
    }
    final reverb = switch (style) {
      'bright' => 0.2,
      'soft' => 0.32,
      _ => 0.26,
    };
    _applySchroederReverb(samples, sampleRate: sampleRate, amount: reverb);
    return _encodeWav(samples, sampleRate: sampleRate, gain: 0.92);
  }

  static _HarpPluckTone _pluckTone(String style) {
    return switch (style) {
      'warm' => const _HarpPluckTone(
        attack: 36,
        decay: 2.0,
        feedback: 0.9935,
        brightness: 0.48,
        transient: 0.2,
        bodyMix: 0.95,
        shimmer: 0.018,
      ),
      'crystal' => const _HarpPluckTone(
        attack: 52,
        decay: 3.0,
        feedback: 0.9915,
        brightness: 0.78,
        transient: 0.36,
        bodyMix: 0.68,
        shimmer: 0.07,
      ),
      'bright' => const _HarpPluckTone(
        attack: 44,
        decay: 2.9,
        feedback: 0.9922,
        brightness: 0.66,
        transient: 0.28,
        bodyMix: 0.74,
        shimmer: 0.055,
      ),
      'nylon' => const _HarpPluckTone(
        attack: 34,
        decay: 2.3,
        feedback: 0.9932,
        brightness: 0.45,
        transient: 0.18,
        bodyMix: 0.9,
        shimmer: 0.015,
      ),
      'glass' => const _HarpPluckTone(
        attack: 56,
        decay: 3.3,
        feedback: 0.9908,
        brightness: 0.84,
        transient: 0.42,
        bodyMix: 0.58,
        shimmer: 0.085,
      ),
      'concert' => const _HarpPluckTone(
        attack: 38,
        decay: 2.7,
        feedback: 0.9933,
        brightness: 0.56,
        transient: 0.24,
        bodyMix: 0.88,
        shimmer: 0.028,
      ),
      'steel' => const _HarpPluckTone(
        attack: 46,
        decay: 2.8,
        feedback: 0.9924,
        brightness: 0.7,
        transient: 0.31,
        bodyMix: 0.76,
        shimmer: 0.048,
      ),
      _ => const _HarpPluckTone(
        attack: 40,
        decay: 2.5,
        feedback: 0.9927,
        brightness: 0.58,
        transient: 0.24,
        bodyMix: 0.82,
        shimmer: 0.036,
      ),
    };
  }

  static void _applySchroederReverb(
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

  static double _softClip(double value) {
    final x = value.clamp(-3.0, 3.0);
    return x / (1 + x.abs());
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

class _HarpPluckTone {
  const _HarpPluckTone({
    required this.attack,
    required this.decay,
    required this.feedback,
    required this.brightness,
    required this.transient,
    required this.bodyMix,
    required this.shimmer,
  });

  final double attack;
  final double decay;
  final double feedback;
  final double brightness;
  final double transient;
  final double bodyMix;
  final double shimmer;
}

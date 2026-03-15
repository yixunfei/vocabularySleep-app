import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract interface class ReminderService {
  Future<void> play({
    required bool haptic,
    required bool sound,
    String? customSoundPath,
    String? announcementText,
    String? announcementLanguageTag,
    Duration duration,
  });

  Future<void> stop();

  Future<void> dispose();
}

class PlatformReminderService implements ReminderService {
  PlatformReminderService();

  static const MethodChannel _channel = MethodChannel(
    'vocabulary_sleep/reminder',
  );
  static final Uint8List _toneBytes = _buildReminderToneBytes();

  final AudioPlayer _fallbackPlayer = AudioPlayer(playerId: 'focus_reminder');

  bool _fallbackConfigured = false;
  Timer? _fallbackStopTimer;
  Timer? _fallbackHapticTimer;
  bool _fallbackHapticPhase = false;

  @override
  Future<void> play({
    required bool haptic,
    required bool sound,
    String? customSoundPath,
    String? announcementText,
    String? announcementLanguageTag,
    Duration duration = const Duration(seconds: 10),
  }) async {
    if (!haptic && !sound) return;
    await stop();
    final safeDuration = Duration(
      milliseconds: duration.inMilliseconds.clamp(1000, 10000).toInt(),
    );

    final handled = await _tryNativeReminder(
      haptic: haptic,
      sound: sound,
      customSoundPath: customSoundPath,
      announcementText: announcementText,
      announcementLanguageTag: announcementLanguageTag,
      duration: safeDuration,
    );
    if (handled) return;

    _scheduleFallbackStop(safeDuration);
    if (haptic) {
      _startFallbackHaptics();
    }
    if (sound) {
      await _playFallbackTone(customSoundPath: customSoundPath);
    }
  }

  Future<bool> _tryNativeReminder({
    required bool haptic,
    required bool sound,
    required String? customSoundPath,
    required String? announcementText,
    required String? announcementLanguageTag,
    required Duration duration,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final handled = await _channel
          .invokeMethod<bool>('playReminder', <String, Object>{
            'haptic': haptic,
            'sound': sound,
            'durationMs': duration.inMilliseconds,
            if ((customSoundPath ?? '').trim().isNotEmpty)
              'customSoundPath': customSoundPath!.trim(),
            if ((announcementText ?? '').trim().isNotEmpty)
              'announcementText': announcementText!.trim(),
            if ((announcementLanguageTag ?? '').trim().isNotEmpty)
              'announcementLanguageTag': announcementLanguageTag!.trim(),
          });
      return handled ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  void _startFallbackHaptics() {
    _triggerFallbackHapticPulse();
    _fallbackHapticTimer = Timer.periodic(
      const Duration(milliseconds: 950),
      (_) => _triggerFallbackHapticPulse(),
    );
  }

  Future<void> _playFallbackTone({String? customSoundPath}) async {
    await _ensureFallbackConfigured();
    try {
      await _fallbackPlayer.stop();
      await _fallbackPlayer.setReleaseMode(ReleaseMode.loop);
      final normalizedPath = customSoundPath?.trim() ?? '';
      if (normalizedPath.isNotEmpty) {
        await _fallbackPlayer.play(
          DeviceFileSource(normalizedPath),
          volume: 1,
          ctx: _fallbackAudioContext,
        );
      } else {
        await _fallbackPlayer.play(
          BytesSource(_toneBytes),
          volume: 1,
          ctx: _fallbackAudioContext,
          mode: PlayerMode.lowLatency,
        );
      }
    } catch (_) {
      if ((customSoundPath ?? '').trim().isNotEmpty) {
        try {
          await _fallbackPlayer.stop();
          await _fallbackPlayer.play(
            BytesSource(_toneBytes),
            volume: 1,
            ctx: _fallbackAudioContext,
            mode: PlayerMode.lowLatency,
          );
          return;
        } catch (_) {}
      }
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {
        // Final no-op fallback.
      }
    }
  }

  void _triggerFallbackHapticPulse() {
    unawaited(_fireFallbackHaptic());
  }

  Future<void> _fireFallbackHaptic() async {
    try {
      if (_fallbackHapticPhase) {
        await HapticFeedback.vibrate();
      } else {
        await HapticFeedback.heavyImpact();
      }
      _fallbackHapticPhase = !_fallbackHapticPhase;
    } catch (_) {
      // Best-effort reminder fallback on unsupported devices.
    }
  }

  void _scheduleFallbackStop(Duration duration) {
    _fallbackStopTimer?.cancel();
    _fallbackStopTimer = Timer(duration, () {
      unawaited(stop());
    });
  }

  @override
  Future<void> stop() async {
    _fallbackStopTimer?.cancel();
    _fallbackStopTimer = null;
    _fallbackHapticTimer?.cancel();
    _fallbackHapticTimer = null;
    _fallbackHapticPhase = false;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _channel.invokeMethod<void>('stopReminder');
      } on MissingPluginException {
        // Fall through to local fallback cleanup.
      } catch (_) {
        // Best-effort stop.
      }
    }

    try {
      await _fallbackPlayer.stop();
    } catch (_) {
      // Ignore already-stopped fallback playback.
    }
  }

  Future<void> _ensureFallbackConfigured() async {
    if (_fallbackConfigured) return;
    await _fallbackPlayer.setReleaseMode(ReleaseMode.loop);
    await _fallbackPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    _fallbackConfigured = true;
  }

  static AudioContext get _fallbackAudioContext => AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: true,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.alarm,
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const <AVAudioSessionOptions>{AVAudioSessionOptions.duckOthers},
    ),
  );

  @override
  Future<void> dispose() async {
    await stop();
    await _fallbackPlayer.dispose();
  }

  static Uint8List _buildReminderToneBytes() {
    const sampleRate = 44100;
    const durationMs = 880;
    const attackMs = 24;
    const releaseMs = 160;
    const frequency = 880.0;
    final sampleCount = (sampleRate * durationMs / 1000).round();
    final byteCount = sampleCount * 2;
    final buffer = ByteData(44 + byteCount);

    void writeString(int offset, String value) {
      for (var index = 0; index < value.length; index++) {
        buffer.setUint8(offset + index, value.codeUnitAt(index));
      }
    }

    writeString(0, 'RIFF');
    buffer.setUint32(4, 36 + byteCount, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, 1, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little);
    buffer.setUint16(32, 2, Endian.little);
    buffer.setUint16(34, 16, Endian.little);
    writeString(36, 'data');
    buffer.setUint32(40, byteCount, Endian.little);

    final attackSamples = (sampleRate * attackMs / 1000).round();
    final releaseSamples = (sampleRate * releaseMs / 1000).round();
    final twoPi = math.pi * 2;

    for (var index = 0; index < sampleCount; index++) {
      final attackEnvelope = attackSamples <= 0
          ? 1.0
          : (index / attackSamples).clamp(0.0, 1.0);
      final releaseEnvelope = releaseSamples <= 0
          ? 1.0
          : ((sampleCount - index) / releaseSamples).clamp(0.0, 1.0);
      final envelope = math.min(attackEnvelope, releaseEnvelope);
      final sample =
          math.sin(twoPi * frequency * index / sampleRate) * envelope * 0.62;
      buffer.setInt16(44 + index * 2, (sample * 32767).round(), Endian.little);
    }

    return buffer.buffer.asUint8List();
  }
}

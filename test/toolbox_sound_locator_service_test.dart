import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/services/toolbox_sound_locator_service.dart';

void main() {
  group('SoundLocatorService', () {
    test('uses phone movement as the default mobile path', () {
      final profile = SoundLocatorDeviceProfile.forPcmStream(
        sampleRate: 48000,
        channelCount: 1,
      );

      expect(profile.engineMode, SoundLocatorEngineMode.mobileMove);
      expect(profile.supportsMobileMoveConfirmation, isTrue);
      expect(profile.supportsProfessionalLocalization, isFalse);
      expect(SoundLocatorService.odasProfile.recommended, isTrue);
      expect(
        SoundLocatorService.odasProfile.requirements.join(' '),
        contains('movement'),
      );
    });

    test('mono input reports activity without direction confidence', () {
      const service = SoundLocatorService();
      final profile = SoundLocatorDeviceProfile.forPcmStream(
        sampleRate: 44100,
        channelCount: 1,
      );
      final bytes = _sinePcm16(
        sampleRate: 44100,
        channelCount: 1,
        frames: 2048,
        lagSamples: 0,
      );

      final frame = service.analyzePcm16(
        pcmBytes: bytes,
        profile: profile,
        previousNoiseFloor: 0.004,
      );

      expect(frame.status, 'mono_direction_unavailable');
      expect(frame.profile.canEstimateDirection, isFalse);
      expect(
        frame.sources.single.confirmation,
        SoundLocatorConfirmation.unconfirmed,
      );
      expect(frame.sources.single.confidence, 0);
    });

    test('stereo TDOA estimates the expected side', () {
      const service = SoundLocatorService();
      final profile = SoundLocatorDeviceProfile.forPcmStream(
        sampleRate: 44100,
        channelCount: 2,
        micSpacingMeters: 0.12,
      );
      final bytes = _sinePcm16(
        sampleRate: 44100,
        channelCount: 2,
        frames: 4096,
        lagSamples: 5,
      );

      final frame = service.analyzePcm16(
        pcmBytes: bytes,
        profile: profile,
        previousNoiseFloor: 0.002,
      );

      expect(frame.status, 'stereo_fallback');
      expect(frame.primarySource, isNotNull);
      expect(frame.primarySource!.azimuthDegrees, greaterThan(10));
      expect(frame.primarySource!.confidence, greaterThan(0.35));
    });

    test('normalizes ODAS tracked sources as the professional frame path', () {
      const service = SoundLocatorService();
      const profile = SoundLocatorDeviceProfile(
        sampleRate: 48000,
        channelCount: 4,
        micSpacingMeters: 0.12,
        engineMode: SoundLocatorEngineMode.odasOptional,
        notes: <String>['Optional dedicated array evidence.'],
      );

      final frame = service.frameFromOdasSources(
        profile: profile,
        snrDb: 19,
        sources: const <SoundLocatorSource>[
          SoundLocatorSource(
            id: 'speaker-b',
            azimuthDegrees: -34,
            elevationDegrees: 12,
            distanceMeters: 2.4,
            level: 0.42,
            confidence: 0.64,
            snrDb: 14,
            reverbRisk: 0.3,
            confirmation: SoundLocatorConfirmation.tracking,
            label: 'Secondary',
          ),
          SoundLocatorSource(
            id: 'speaker-a',
            azimuthDegrees: 18,
            elevationDegrees: 8,
            distanceMeters: 1.8,
            level: 0.76,
            confidence: 0.88,
            snrDb: 19,
            reverbRisk: 0.22,
            confirmation: SoundLocatorConfirmation.locked,
            label: 'Primary',
          ),
        ],
      );

      expect(frame.status, 'odas_profile_insufficient');
      expect(frame.quality, SoundLocatorQuality.strong);
      expect(frame.sources.map((source) => source.id), <String>[
        'speaker-a',
        'speaker-b',
      ]);
    });

    test('movement samples converge without external microphones', () {
      const service = SoundLocatorService();
      final samples = <SoundLocatorAnchorSample>[
        SoundLocatorAnchorSample(
          id: 'sample-1',
          cue: SoundLocatorMoveCue.stay,
          level: 0.10,
          snrDb: 12,
          reverbRisk: 0.28,
          azimuthDegrees: null,
          timestamp: DateTime(2026, 5, 19, 10),
        ),
        SoundLocatorAnchorSample(
          id: 'sample-2',
          cue: SoundLocatorMoveCue.stepLeft,
          level: 0.06,
          snrDb: 9,
          reverbRisk: 0.34,
          azimuthDegrees: null,
          timestamp: DateTime(2026, 5, 19, 10, 1),
        ),
        SoundLocatorAnchorSample(
          id: 'sample-3',
          cue: SoundLocatorMoveCue.stepRight,
          level: 0.16,
          snrDb: 18,
          reverbRisk: 0.18,
          azimuthDegrees: null,
          timestamp: DateTime(2026, 5, 19, 10, 2),
        ),
        SoundLocatorAnchorSample(
          id: 'sample-4',
          cue: SoundLocatorMoveCue.stepForward,
          level: 0.20,
          snrDb: 21,
          reverbRisk: 0.12,
          azimuthDegrees: null,
          timestamp: DateTime(2026, 5, 19, 10, 3),
        ),
      ];

      final confirmation = service.confirmFromMovementSamples(samples);

      expect(confirmation.hasEnoughSamples, isTrue);
      expect(
        confirmation.confirmation,
        anyOf(
          SoundLocatorConfirmation.tracking,
          SoundLocatorConfirmation.locked,
        ),
      );
      expect(confirmation.confidence, greaterThan(0.58));
      expect(confirmation.recommendedCue, SoundLocatorMoveCue.stepBack);
    });
  });
}

Uint8List _sinePcm16({
  required int sampleRate,
  required int channelCount,
  required int frames,
  required int lagSamples,
}) {
  final data = ByteData(frames * channelCount * 2);
  const frequency = 1200.0;
  for (var frame = 0; frame < frames; frame += 1) {
    final left = math.sin(frame * frequency * 2 * math.pi / sampleRate) * 0.42;
    final right =
        math.sin((frame - lagSamples) * frequency * 2 * math.pi / sampleRate) *
        0.42;
    for (var channel = 0; channel < channelCount; channel += 1) {
      final value = channel == 0 ? left : right;
      data.setInt16(
        (frame * channelCount + channel) * 2,
        (value * 32767).round(),
        Endian.little,
      );
    }
  }
  return data.buffer.asUint8List();
}

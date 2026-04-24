import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/services/toolbox_zen_sand_sound_service.dart';

void main() {
  group('Zen sand sound regression', () {
    test('loop waveform stays continuously audible', () {
      const loopKinds = <ZenSandSoundKind>[
        ZenSandSoundKind.rake,
        ZenSandSoundKind.finger,
        ZenSandSoundKind.water,
        ZenSandSoundKind.shovel,
        ZenSandSoundKind.gravel,
        ZenSandSoundKind.smooth,
      ];

      for (final kind in loopKinds) {
        final snapshot = ZenSandSoundDebug.analyzeLoop(kind, brushSize: 32);
        expect(snapshot.sampleRate, 22050);
        expect(snapshot.durationMs, closeTo(4800, 1));
        expect(snapshot.rms, greaterThan(0.02), reason: kind.name);
        expect(snapshot.peak, lessThan(0.55), reason: kind.name);
        expect(snapshot.minWindowRms, greaterThan(0.006), reason: kind.name);
        expect(
          snapshot.zeroCrossingRate,
          greaterThan(0.045),
          reason: kind.name,
        );
        expect(
          snapshot.maxWindowRms / snapshot.minWindowRms,
          lessThan(8),
          reason: kind.name,
        );
        expect(snapshot.leadingQuietMs, lessThan(25), reason: kind.name);
        expect(snapshot.trailingQuietMs, lessThan(25), reason: kind.name);
        expect(snapshot.longestQuietMs, lessThan(25), reason: kind.name);
      }
    });

    test('impact waveform reaches audible body quickly', () {
      const impactKinds = <ZenSandSoundKind>[
        ZenSandSoundKind.rake,
        ZenSandSoundKind.finger,
        ZenSandSoundKind.water,
        ZenSandSoundKind.shovel,
        ZenSandSoundKind.gravel,
        ZenSandSoundKind.smooth,
        ZenSandSoundKind.stone,
      ];

      for (final kind in impactKinds) {
        final snapshot = ZenSandSoundDebug.analyzeImpact(
          kind,
          brushSize: 32,
          intensity: 0.52,
        );
        expect(snapshot.sampleRate, 22050);
        expect(snapshot.durationMs, greaterThan(90), reason: kind.name);
        expect(snapshot.rms, greaterThan(0.01), reason: kind.name);
        expect(snapshot.peak, greaterThan(0.05), reason: kind.name);
        expect(snapshot.leadingQuietMs, lessThan(25), reason: kind.name);
      }
    });

    test('loop motion follows sliding movement', () {
      final still = ToolboxZenSandSoundService.debugMotionIntensitySnapshot(
        kind: ZenSandSoundKind.rake,
        distance: 0,
        elapsedMs: 16,
        previousSpeed: 0,
        smoothedSpeed: 0,
      );
      expect(still.intensity, 0);

      final uniform = ToolboxZenSandSoundService.debugMotionIntensitySnapshot(
        kind: ZenSandSoundKind.rake,
        distance: 4,
        elapsedMs: 16,
        previousSpeed: 0.25,
        smoothedSpeed: 0.25,
      );
      final accelerating =
          ToolboxZenSandSoundService.debugMotionIntensitySnapshot(
            kind: ZenSandSoundKind.rake,
            distance: 14,
            elapsedMs: 16,
            previousSpeed: uniform.speed,
            smoothedSpeed: uniform.smoothedSpeed,
          );

      expect(uniform.intensity, greaterThan(0));
      expect(accelerating.intensity, greaterThan(uniform.intensity));
      expect(
        ToolboxZenSandSoundService.debugSoftLoopVolumeFor(
          ZenSandSoundKind.rake,
          brushSize: 32,
          intensity: still.intensity,
        ),
        0,
      );
      expect(
        ToolboxZenSandSoundService.debugSoftLoopVolumeFor(
          ZenSandSoundKind.rake,
          brushSize: 32,
          intensity: accelerating.intensity,
        ),
        lessThan(0.18),
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_free_chimes_controller.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_free_chimes_prefs_service.dart';

void main() {
  group('ToolboxFreeChimeController', () {
    test(
      'free mode maps gentle motion to soft layers and respects cooldown',
      () {
        final controller = ToolboxFreeChimeController();
        final mixes = <ToolboxFreeChimeLayerMix>[
          const ToolboxFreeChimeLayerMix(
            layer: ToolboxFreeChimeLayer.windChime,
            amount: 1,
          ),
          const ToolboxFreeChimeLayerMix(
            layer: ToolboxFreeChimeLayer.impact,
            amount: 1,
          ),
        ];
        final start = DateTime(2026, 6, 1, 12);

        final first = controller.evaluate(
          ToolboxFreeChimeMotionSample(timestamp: start, x: 1.4, y: 0, z: 0),
          mixes: mixes,
          sensitivity: 1,
        );
        final throttled = controller.evaluate(
          ToolboxFreeChimeMotionSample(
            timestamp: start.add(const Duration(milliseconds: 120)),
            x: 1.5,
            y: 0,
            z: 0,
          ),
          mixes: mixes,
          sensitivity: 1,
        );

        expect(first, isNotNull);
        expect(first!.band, ToolboxFreeChimeIntensityBand.gentle);
        expect(
          first.hits.map((hit) => hit.layer),
          contains(ToolboxFreeChimeLayer.windChime),
        );
        expect(first.hits.any((hit) => hit.layer.isRhythmic), isFalse);
        expect(throttled, isNull);
      },
    );

    test('default mix starts with wind chime only', () {
      final activeDefaults = ToolboxFreeChimeController.defaultMixes
          .where((mix) => mix.amount > 0.02)
          .toList(growable: false);

      expect(activeDefaults, hasLength(1));
      expect(activeDefaults.single.layer, ToolboxFreeChimeLayer.windChime);
    });

    test('playback limiter caps global active voices at three', () {
      final limiter = ToolboxFreeChimePlaybackLimiter(maxSlots: 3);

      expect(limiter.claim(5), 3);
      expect(limiter.activeSlots, 3);
      expect(limiter.claim(1), 0);

      limiter.release(2);

      expect(limiter.activeSlots, 1);
      expect(limiter.claim(2), 2);
      expect(limiter.activeSlots, 3);

      limiter.reset();

      expect(limiter.activeSlots, 0);
    });

    test('free mode responds to quick opposite swings as collisions', () {
      final controller = ToolboxFreeChimeController();
      final mixes = <ToolboxFreeChimeLayerMix>[
        const ToolboxFreeChimeLayerMix(
          layer: ToolboxFreeChimeLayer.windChime,
          amount: 1,
        ),
        const ToolboxFreeChimeLayerMix(
          layer: ToolboxFreeChimeLayer.impact,
          amount: 0.7,
        ),
      ];
      final start = DateTime(2026, 6, 1, 12);

      final first = controller.evaluate(
        ToolboxFreeChimeMotionSample(timestamp: start, x: 4, y: 0, z: 0),
        mixes: mixes,
        sensitivity: 1,
      );
      final flip = controller.evaluate(
        ToolboxFreeChimeMotionSample(
          timestamp: start.add(const Duration(milliseconds: 115)),
          x: -4.4,
          y: 0.2,
          z: 0,
        ),
        mixes: mixes,
        sensitivity: 1,
      );

      expect(first, isNotNull);
      expect(flip, isNotNull);
      expect(flip!.hits, isNotEmpty);
      expect(
        flip.hits.first.playbackRate,
        greaterThan(first!.hits.first.playbackRate),
      );
      expect(flip.hits.first.volume, greaterThan(first.hits.first.volume));
      expect(flip.hits.first.pan, lessThan(0));
    });

    test('free mode repeats wind chime hits on rapid direction changes', () {
      final controller = ToolboxFreeChimeController();
      final mixes = <ToolboxFreeChimeLayerMix>[
        const ToolboxFreeChimeLayerMix(
          layer: ToolboxFreeChimeLayer.windChime,
          amount: 1,
        ),
      ];
      final start = DateTime(2026, 6, 10, 12);

      final first = controller.evaluate(
        ToolboxFreeChimeMotionSample(timestamp: start, x: 3.8, y: 0, z: 0),
        mixes: mixes,
        sensitivity: 1,
      );
      final second = controller.evaluate(
        ToolboxFreeChimeMotionSample(
          timestamp: start.add(const Duration(milliseconds: 85)),
          x: -4.4,
          y: 0.1,
          z: 0,
        ),
        mixes: mixes,
        sensitivity: 1,
      );
      final third = controller.evaluate(
        ToolboxFreeChimeMotionSample(
          timestamp: start.add(const Duration(milliseconds: 170)),
          x: 4.6,
          y: -0.1,
          z: 0,
        ),
        mixes: mixes,
        sensitivity: 1,
      );

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(third, isNotNull);
      expect(
        second!.hits.first.playbackRate,
        greaterThan(first!.hits.first.playbackRate),
      );
      expect(third!.hits.first.volume, greaterThan(first.hits.first.volume));
    });

    test(
      'allegro mode triggers beats on direction changes and estimates tempo',
      () {
        final controller = ToolboxFreeChimeController();
        final mixes = <ToolboxFreeChimeLayerMix>[
          const ToolboxFreeChimeLayerMix(
            layer: ToolboxFreeChimeLayer.shaker,
            amount: 0.8,
          ),
          const ToolboxFreeChimeLayerMix(
            layer: ToolboxFreeChimeLayer.gongDrum,
            amount: 1,
          ),
          const ToolboxFreeChimeLayerMix(
            layer: ToolboxFreeChimeLayer.kuaiban,
            amount: 1,
          ),
          const ToolboxFreeChimeLayerMix(
            layer: ToolboxFreeChimeLayer.marble,
            amount: 0.9,
          ),
        ];
        final start = DateTime(2026, 6, 1, 12);

        final seedDirection = controller.evaluate(
          ToolboxFreeChimeMotionSample(timestamp: start, x: 4, y: 0, z: 0),
          mixes: mixes,
          sensitivity: 1,
          mode: ToolboxFreeChimePlayMode.allegro,
        );
        final firstFlip = controller.evaluate(
          ToolboxFreeChimeMotionSample(
            timestamp: start.add(const Duration(milliseconds: 300)),
            x: -4,
            y: 0,
            z: 0,
          ),
          mixes: mixes,
          sensitivity: 1,
          mode: ToolboxFreeChimePlayMode.allegro,
        );
        final secondFlip = controller.evaluate(
          ToolboxFreeChimeMotionSample(
            timestamp: start.add(const Duration(milliseconds: 550)),
            x: 4,
            y: 0,
            z: 0,
          ),
          mixes: mixes,
          sensitivity: 1,
          mode: ToolboxFreeChimePlayMode.allegro,
        );

        expect(seedDirection, isNull);
        expect(firstFlip, isNotNull);
        expect(firstFlip!.hits.any((hit) => hit.layer.isRhythmic), isTrue);
        expect(
          firstFlip.hits.map((hit) => hit.layer),
          contains(ToolboxFreeChimeLayer.kuaiban),
        );
        expect(firstFlip.tempoBpm, isNotNull);
        expect(secondFlip, isNotNull);
        expect(secondFlip!.tempoBpm, greaterThan(firstFlip.tempoBpm!));

        controller.resetTiming();
        final resetSeed = controller.evaluate(
          ToolboxFreeChimeMotionSample(
            timestamp: start.add(const Duration(seconds: 2)),
            x: 4,
            y: 0,
            z: 0,
          ),
          mixes: mixes,
          sensitivity: 1,
          mode: ToolboxFreeChimePlayMode.allegro,
        );
        final resetFlip = controller.evaluate(
          ToolboxFreeChimeMotionSample(
            timestamp: start.add(const Duration(milliseconds: 2300)),
            x: -4,
            y: 0,
            z: 0,
          ),
          mixes: mixes,
          sensitivity: 1,
          mode: ToolboxFreeChimePlayMode.allegro,
        );

        expect(resetSeed, isNull);
        expect(resetFlip, isNotNull);
        expect(resetFlip!.tempoBpm, 120);
      },
    );

    test('disabled mixes stay silent and strong hits are capped', () {
      final controller = ToolboxFreeChimeController();
      final start = DateTime(2026, 6, 1, 12);
      final disabledMixes = <ToolboxFreeChimeLayerMix>[
        const ToolboxFreeChimeLayerMix(
          layer: ToolboxFreeChimeLayer.windChime,
          amount: 0,
        ),
        const ToolboxFreeChimeLayerMix(
          layer: ToolboxFreeChimeLayer.kuaiban,
          amount: 0,
        ),
      ];

      final disabledTrigger = controller.evaluate(
        ToolboxFreeChimeMotionSample(timestamp: start, x: 9, y: 2, z: 1),
        mixes: disabledMixes,
        sensitivity: 1,
      );
      final disabledPreview = controller.preview(
        timestamp: start,
        intensity: 0.9,
        mixes: disabledMixes,
      );

      expect(disabledTrigger, isNull);
      expect(disabledPreview.hits, isEmpty);

      final strongMixes = <ToolboxFreeChimeLayerMix>[
        for (final layer in ToolboxFreeChimeLayer.values)
          ToolboxFreeChimeLayerMix(layer: layer, amount: 1),
      ];
      final strongTrigger = controller.evaluate(
        ToolboxFreeChimeMotionSample(
          timestamp: start.add(const Duration(seconds: 1)),
          x: 9,
          y: 3,
          z: 1,
        ),
        mixes: strongMixes,
        sensitivity: 1.2,
      );

      expect(strongTrigger, isNotNull);
      expect(strongTrigger!.band, ToolboxFreeChimeIntensityBand.strong);
      expect(strongTrigger.hits.length, lessThanOrEqualTo(4));
    });

    test('prefs state round-trips custom layer amounts', () {
      const state = FreeChimesPrefsState(
        customLayerAmounts: <ToolboxFreeChimeLayer, double>{
          ToolboxFreeChimeLayer.windChime: 0.82,
          ToolboxFreeChimeLayer.kuaiban: 0.24,
        },
      );

      final restored = FreeChimesPrefsState.fromJsonValue(state.toJson());

      expect(restored.hasCustomPreset, isTrue);
      expect(
        restored.customLayerAmounts[ToolboxFreeChimeLayer.windChime],
        0.82,
      );
      expect(restored.customLayerAmounts[ToolboxFreeChimeLayer.kuaiban], 0.24);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_free_chimes_controller.dart';

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
  });
}

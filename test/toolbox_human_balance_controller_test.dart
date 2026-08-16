import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_human_balance_controller.dart';

void main() {
  group('ToolboxHumanBalanceController', () {
    test('start gives the ball a bounded random impulse', () {
      final controller = ToolboxHumanBalanceController(random: math.Random(7));

      controller.start();

      expect(controller.state.running, isTrue);
      expect(controller.state.fallen, isFalse);
      expect(controller.state.initialImpulse, greaterThanOrEqualTo(0.08));
      expect(controller.state.initialImpulse, lessThanOrEqualTo(0.15));
      expect(
        math.sqrt(
          controller.state.vx * controller.state.vx +
              controller.state.vy * controller.state.vy,
        ),
        closeTo(controller.state.initialImpulse, 0.0001),
      );
    });

    test('tilt accelerates the ball and tracks max offset', () {
      final controller = ToolboxHumanBalanceController(random: math.Random(1))
        ..start();

      for (var i = 0; i < 30; i += 1) {
        controller.tick(dtSeconds: 1 / 60, tiltXDegrees: 25, tiltYDegrees: -10);
      }

      expect(controller.state.elapsedSeconds, closeTo(0.5, 0.001));
      expect(controller.state.currentOffset, greaterThan(0));
      expect(
        controller.state.maxOffset,
        greaterThanOrEqualTo(controller.state.currentOffset),
      );
      expect(controller.state.maxTiltMagnitude, greaterThan(0));
      expect(controller.state.maxTiltMagnitude, lessThanOrEqualTo(42));
    });

    test('falling off the platform ends the run', () {
      final controller = ToolboxHumanBalanceController(random: math.Random(3))
        ..start();

      for (var i = 0; i < 300 && controller.state.running; i += 1) {
        controller.tick(dtSeconds: 1 / 60, tiltXDegrees: 42, tiltYDegrees: 0);
      }

      expect(controller.state.fallen, isTrue);
      expect(controller.state.running, isFalse);
      expect(controller.state.maxOffset, greaterThan(1));
      expect(controller.state.elapsedSeconds, greaterThan(0));
    });

    test('sustained tilt caps ball speed', () {
      final controller = ToolboxHumanBalanceController(random: math.Random(9))
        ..start();

      for (var i = 0; i < 180 && controller.state.running; i += 1) {
        controller.tick(dtSeconds: 1 / 60, tiltXDegrees: 42, tiltYDegrees: 42);
        final speed = math.sqrt(
          controller.state.vx * controller.state.vx +
              controller.state.vy * controller.state.vy,
        );
        expect(
          speed,
          lessThanOrEqualTo(ToolboxHumanBalanceController.maxBallSpeed + 1e-9),
        );
      }
    });

    test('gravity conversion clamps tilt to the phone handhold limit', () {
      final tilt = ToolboxHumanBalanceController.tiltFromGravity(
        x: -20,
        y: 20,
        z: 1,
      );

      expect(tilt.xDegrees, lessThanOrEqualTo(42));
      expect(tilt.yDegrees, lessThanOrEqualTo(42));
      expect(tilt.magnitudeDegrees, greaterThan(0));
    });

    test('reset clears previous result', () {
      final controller = ToolboxHumanBalanceController(random: math.Random(5))
        ..start();
      controller.tick(dtSeconds: 0.1, tiltXDegrees: 20, tiltYDegrees: 0);

      controller.reset();

      expect(controller.state.elapsedSeconds, 0);
      expect(controller.state.maxOffset, 0);
      expect(controller.state.running, isFalse);
      expect(controller.state.fallen, isFalse);
    });
  });
}

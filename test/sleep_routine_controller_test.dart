import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/models/sleep_routine_template.dart';
import 'package:vocabulary_sleep_app/src/services/sleep/sleep_routine_controller.dart';

void main() {
  group('routine elapsed time', _elapsedTests);
  group('routine operations', _operationTests);
  group('routine owned timer', _timerTests);
}

void _elapsedTests() {
  test('missed callbacks advance across all elapsed steps', () {
    var now = DateTime(2026, 9, 9, 22);
    final controller = SleepRoutineController(
      now: () => now,
      automaticTick: false,
    )..start(_template([10, 20, 30]));
    now = now.add(const Duration(seconds: 35));
    controller.synchronize();
    expect(controller.value.currentStepIndex, 2);
    expect(controller.value.remainingSeconds, 25);
    now = now.add(const Duration(hours: 1));
    controller.synchronize();
    expect(controller.isCompleted, isTrue);
    expect(controller.value.isRunning, isFalse);
    expect(controller.value.remainingSeconds, 0);
    controller.dispose();
  });

  test('fractional elapsed time survives callbacks and pause', () {
    var now = DateTime(2026, 9, 9, 22);
    final controller = SleepRoutineController(
      now: () => now,
      automaticTick: false,
    )..start(_template([10]));
    now = now.add(const Duration(milliseconds: 1500));
    controller.pause();
    expect(controller.value.remainingSeconds, 9);
    now = now.add(const Duration(hours: 2));
    controller.resume();
    now = now.add(const Duration(milliseconds: 500));
    controller.synchronize();
    expect(controller.value.remainingSeconds, 8);
    expect(controller.value.isRunning, isTrue);
    controller.dispose();
  });

  test('backward clock changes never increase the remaining time', () {
    var now = DateTime(2026, 9, 9, 22);
    final controller = SleepRoutineController(
      now: () => now,
      automaticTick: false,
    )..start(_template([10]));
    now = now.add(const Duration(seconds: 3));
    controller.synchronize();
    now = now.subtract(const Duration(seconds: 2));
    controller.synchronize();
    expect(controller.value.remainingSeconds, 7);
    now = now.add(const Duration(seconds: 4));
    controller.synchronize();
    expect(controller.value.remainingSeconds, 5);
    controller.dispose();
  });

  test('zero and negative durations never strand a running routine', () {
    final controller = SleepRoutineController(automaticTick: false)
      ..start(_template([0, -1, 5]));
    expect(controller.value.currentStepIndex, 2);
    expect(controller.value.remainingSeconds, 5);
    controller.start(_template([0, 0]));
    expect(controller.isCompleted, isTrue);
    controller.start(_template([]));
    expect(controller.value.isRunning, isFalse);
    expect(controller.isCompleted, isFalse);
    controller.dispose();
  });
}

void _operationTests() {
  test(
    'advance while paused preserves the pause and completion is distinct',
    () {
      final controller = SleepRoutineController(automaticTick: false)
        ..start(_template([30, 40]));
      controller.pause();
      controller.advance();
      expect(controller.value.currentStepIndex, 1);
      expect(controller.value.isPaused, isTrue);
      expect(controller.value.remainingSeconds, 40);
      controller.advance();
      expect(controller.isCompleted, isTrue);
      controller.stop();
      expect(controller.isCompleted, isFalse);
      expect(controller.value.startedAt, isNull);
      controller.resume();
      expect(controller.value.isRunning, isFalse);
      controller.dispose();
    },
  );

  test('advancing a stale displayed step does not skip a second step', () {
    var now = DateTime(2026, 9, 9, 22);
    final controller = SleepRoutineController(
      now: () => now,
      automaticTick: false,
    )..start(_template([10, 20, 30]));
    now = now.add(const Duration(seconds: 12));
    controller.advance();
    expect(controller.value.currentStepIndex, 1);
    expect(controller.value.remainingSeconds, 18);
    controller.dispose();
  });

  test('editing active template safely resets and list edits are isolated', () {
    final template = _template([10, 20]);
    final controller = SleepRoutineController(automaticTick: false)
      ..start(template);
    template.steps.clear();
    expect(controller.activeTemplate!.steps.length, 2);
    expect(
      () => controller.activeTemplate!.steps.clear(),
      throwsUnsupportedError,
    );
    controller.selectTemplate(_template([10, 20]));
    expect(controller.value.isRunning, isTrue);
    controller.selectTemplate(_template([5]));
    expect(controller.value.isRunning, isFalse);
    expect(controller.value.currentStepIndex, 0);
    expect(controller.isCompleted, isFalse);
    controller.selectTemplate(null);
    expect(controller.value.activeTemplateId, isNull);
    controller.dispose();
  });
}

void _timerTests() {
  test(
    'only one timer exists across start, pause, resume, select and dispose',
    () {
      fakeAsync((async) {
        final now = DateTime(2026, 9, 9, 22);
        final controller = SleepRoutineController(
          now: () => now.add(async.elapsed),
        );
        controller.start(_template([60]));
        controller.start(_template([60]));
        expect(async.periodicTimerCount, 1);
        async.elapse(const Duration(seconds: 2));
        expect(controller.value.remainingSeconds, 58);
        controller.pause();
        expect(async.periodicTimerCount, 0);
        async.elapse(const Duration(hours: 1));
        controller.resume();
        controller.resume();
        expect(async.periodicTimerCount, 1);
        expect(controller.value.remainingSeconds, 58);
        controller.selectTemplate(_template([30], id: 'second'));
        expect(async.periodicTimerCount, 0);
        controller.start(_template([30]));
        controller.dispose();
        expect(async.periodicTimerCount, 0);
        async.elapse(const Duration(hours: 1));
      });
    },
  );

  test(
    'unchanged reconciliation emits no update, completion cancels its timer',
    () {
      fakeAsync((async) {
        final now = DateTime(2026, 9, 9, 22);
        final controller = SleepRoutineController(
          now: () => now.add(async.elapsed),
        )..start(_template([2]));
        var updates = 0;
        controller.addListener(() => updates += 1);
        controller.synchronize();
        controller.synchronize();
        expect(updates, 0);
        async.elapse(const Duration(seconds: 2));
        expect(updates, 2);
        expect(controller.isCompleted, isTrue);
        expect(async.periodicTimerCount, 0);
        async.elapse(const Duration(seconds: 5));
        expect(updates, 2);
        controller.dispose();
      });
    },
  );
}

SleepRoutineTemplate _template(List<int> durations, {String id = 'test'}) {
  return SleepRoutineTemplate(
    id: id,
    name: 'test template',
    totalMinutes: 1,
    steps: durations
        .map(
          (duration) => SleepRoutineStep(
            type: SleepRoutineStepType.bodyScan,
            label: 'test step',
            durationSeconds: duration,
          ),
        )
        .toList(),
    builtIn: false,
    updatedAt: DateTime(2026, 9, 9),
  );
}

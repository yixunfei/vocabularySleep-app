import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/models/sleep_daily_log.dart';
import 'package:vocabulary_sleep_app/src/models/sleep_support_session.dart';
import 'package:vocabulary_sleep_app/src/services/sleep/sleep_support_session_controller.dart';

void main() {
  group('night support paths', _pathTests);
  group('night support persistence', _persistenceTests);
  group('night support lifecycle', _lifecycleTests);
}

void _pathTests() {
  test('each intent immediately offers an action without a setup form', () {
    for (final intent in SleepSupportIntent.values) {
      final controller = _controller();
      expect(controller.start(intent), isTrue);
      expect(controller.state!.titleKey, isNotEmpty);
      expect(controller.state!.bodyKey, isNotEmpty);
      expect(controller.state!.choices, isNotEmpty);
      expect(controller.state!.hasEngaged, isFalse);
      controller.dispose();
    }
  });

  test('preparing for sleep reaches rest in two acknowledged actions', () {
    final controller = _controller()..start(SleepSupportIntent.prepareForSleep);
    controller.choose(SleepSupportChoice.continueGuide);
    expect(controller.state!.step, SleepSupportStep.softenBody);
    controller.choose(SleepSupportChoice.rest);
    expect(controller.state!.isResting, isTrue);
    expect(controller.state!.isFinished, isFalse);
    controller.resumeGuide();
    expect(controller.state!.isResting, isFalse);
    controller.dispose();
  });

  test('distress choices lead to their matching small action', () {
    const branches = {
      SleepSupportChoice.racingThoughts: SleepSupportStep.easeThoughts,
      SleepSupportChoice.bodyTension: SleepSupportStep.easeTension,
      SleepSupportChoice.temperature: SleepSupportStep.adjustTemperature,
    };
    for (final branch in branches.entries) {
      final controller = _controller()..start(SleepSupportIntent.distressed);
      controller.choose(branch.key);
      expect(controller.state!.step, branch.value);
      controller.changeMethod();
      expect(controller.state!.choices, contains(branch.key));
      controller.skip();
      expect(controller.state!.isResting, isTrue);
      controller.dispose();
    }
  });

  test('invalid choices cannot fabricate a return to bed', () {
    final controller = _controller()..start(SleepSupportIntent.nightWaking);
    controller.choose(SleepSupportChoice.returnedToBed);
    expect(controller.state!.returnedToBedAt, isNull);
    controller.choose(SleepSupportChoice.stillAwake);
    expect(controller.state!.step, SleepSupportStep.leaveBed);
    controller.choose(SleepSupportChoice.returnedToBed);
    expect(controller.state!.returnedToBedAt, isNull);
    controller.dispose();
  });

  test('an explicit returned-to-bed choice is distinct from sleepy', () async {
    var now = DateTime(2026, 9, 9, 2);
    final records = <SleepNightEvent>[];
    final controller = _controller(now: () => now, records: records)
      ..start(SleepSupportIntent.nightWaking);
    controller.choose(SleepSupportChoice.stillAwake);
    controller.choose(SleepSupportChoice.leftBed);
    expect(controller.state!.returnedToBedAt, isNull);
    now = now.add(const Duration(minutes: 7));
    controller.choose(SleepSupportChoice.returnedToBed);
    expect(controller.state!.isResting, isTrue);
    await controller.finish();
    expect(records.single.returnedToBedAt, now);
    expect(records.single.hasLeftBed, isTrue);
    expect(records.single.intent, SleepSupportIntent.nightWaking);
    final restored = SleepNightEvent.fromJsonValue(records.single.toJsonMap())!;
    expect(restored.hasLeftBed, isTrue);
    expect(restored.intent, SleepSupportIntent.nightWaking);
    expect(records.single.fellAsleepAgainAt, isNull);
    controller.dispose();
  });
}

void _persistenceTests() {
  test(
    'leaving immediately and preparing for bed do not count as awakenings',
    () async {
      final records = <SleepNightEvent>[];
      final controller = _controller(records: records)
        ..start(SleepSupportIntent.nightWaking);
      await controller.finish();
      expect(records, isEmpty);
      controller.start(SleepSupportIntent.prepareForSleep);
      controller.rest();
      await controller.finish();
      expect(records, isEmpty);
      controller.dispose();
    },
  );

  test(
    'rest does not save until explicit finish and does not imply sleep',
    () async {
      final records = <SleepNightEvent>[];
      final controller = _controller(records: records)
        ..start(SleepSupportIntent.nightWaking);
      controller.choose(SleepSupportChoice.sleepy);
      expect(records, isEmpty);
      await controller.finish();
      expect(records.single.startedAt, DateTime(2026, 9, 9, 2));
      expect(records.single.returnedToBedAt, isNull);
      expect(records.single.fellAsleepAgainAt, isNull);
      expect(records.single.guessedTrigger, isNull);
      controller.dispose();
    },
  );

  test('rapid and reentrant completion dispatch one write', () async {
    var calls = 0;
    final gate = Completer<void>();
    final controller = SleepSupportSessionController(
      saveEvent: (_) {
        calls += 1;
        return gate.future;
      },
    )..start(SleepSupportIntent.nightWaking);
    controller.rest();
    controller.addListener(() {
      if (controller.state!.isPersisting) controller.finish();
    });
    final first = controller.finish();
    final second = controller.finish();
    expect(identical(first, second), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
    gate.complete();
    expect(await first, isTrue);
    expect(await controller.finish(), isTrue);
    expect(calls, 1);
    controller.dispose();
  });

  test('failed writes retry the same record and final timestamp', () async {
    final attempts = <SleepNightEvent>[];
    var now = DateTime(2026, 9, 9, 23, 59);
    final controller = SleepSupportSessionController(
      now: () => now,
      saveEvent: (event) async {
        attempts.add(event);
        if (attempts.length == 1) throw StateError('storage unavailable');
      },
    )..start(SleepSupportIntent.nightWaking);
    controller.rest();
    now = DateTime(2026, 9, 10, 0, 1);
    expect(await controller.finish(), isFalse);
    expect(controller.state!.saveFailed, isTrue);
    expect(controller.start(SleepSupportIntent.distressed), isFalse);
    now = now.add(const Duration(minutes: 3));
    expect(await controller.retrySave(), isTrue);
    expect(identical(attempts.first, attempts.last), isTrue);
    expect(attempts.last.endedAt, DateTime(2026, 9, 10, 0, 1));
    expect(attempts.last.dateKey, '2026-09-09');
    expect(controller.state!.saveFailed, isFalse);
    controller.dispose();
  });
}

void _lifecycleTests() {
  test('reopening resumes the same session and step', () {
    final controller = _controller()..start(SleepSupportIntent.nightWaking);
    controller.choose(SleepSupportChoice.stillAwake);
    final id = controller.state!.id;
    expect(controller.start(SleepSupportIntent.nightWaking), isTrue);
    expect(controller.state!.id, id);
    expect(controller.state!.step, SleepSupportStep.leaveBed);
    expect(controller.start(SleepSupportIntent.distressed), isFalse);
    controller.discard();
    expect(controller.start(SleepSupportIntent.distressed), isTrue);
    controller.dispose();
  });

  test('independent completed sessions use independent identifiers', () async {
    final controller = _controller()..start(SleepSupportIntent.nightWaking);
    final firstId = controller.state!.id;
    controller.rest();
    await controller.finish();
    controller.start(SleepSupportIntent.nightWaking);
    expect(controller.state!.id, isNot(firstId));
    controller.dispose();
  });

  test(
    'disposing during a write permits storage without late notification',
    () async {
      final gate = Completer<void>();
      final controller = SleepSupportSessionController(
        saveEvent: (_) => gate.future,
      )..start(SleepSupportIntent.nightWaking);
      controller.rest();
      final result = controller.finish();
      controller.dispose();
      gate.complete();
      expect(await result, isTrue);
    },
  );

  test(
    'discard during an in-flight write cannot abandon its identity',
    () async {
      final gate = Completer<void>();
      final controller = SleepSupportSessionController(
        saveEvent: (_) => gate.future,
      )..start(SleepSupportIntent.nightWaking);
      controller.rest();
      final id = controller.state!.id;
      final result = controller.finish();
      controller.discard();
      expect(controller.state!.id, id);
      expect(controller.start(SleepSupportIntent.distressed), isFalse);
      gate.complete();
      await result;
      controller.dispose();
    },
  );
}

SleepSupportSessionController _controller({
  DateTime Function()? now,
  List<SleepNightEvent>? records,
}) {
  return SleepSupportSessionController(
    now: now ?? () => DateTime(2026, 9, 9, 2),
    saveEvent: (event) async => records?.add(event),
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/models/sleep_daily_log.dart';
import 'package:vocabulary_sleep_app/src/models/sleep_support_session.dart';
import 'package:vocabulary_sleep_app/src/services/sleep/sleep_support_session_controller.dart';

void main() {
  test('rest checkpoints an acknowledged night support event', () async {
    final records = <SleepNightEvent>[];
    final controller = SleepSupportSessionController(
      now: () => DateTime(2026, 9, 10, 1),
      saveEvent: (event) async => records.add(event),
    )..start(SleepSupportIntent.nightWaking);

    controller.rest();
    await Future<void>.delayed(Duration.zero);

    expect(records, hasLength(1));
    expect(records.single.id, controller.state!.id);
    expect(records.single.endedAt, isNotNull);
    expect(records.single.fellAsleepAgainAt, isNull);
    controller.dispose();
  });

  test('a previous-day session cannot be resumed as current guidance', () {
    var now = DateTime(2026, 9, 9, 23, 59);
    final controller = SleepSupportSessionController(
      now: () => now,
      saveEvent: (_) async {},
    )..start(SleepSupportIntent.nightWaking);
    final oldId = controller.state!.id;
    now = DateTime(2026, 9, 10, 0, 2);

    expect(controller.start(SleepSupportIntent.nightWaking), isTrue);
    expect(controller.state!.id, isNot(oldId));
    controller.dispose();
  });

  test('a failed write does not block a new support intent', () async {
    var fail = true;
    final controller = SleepSupportSessionController(
      saveEvent: (_) async {
        if (fail) throw StateError('offline');
      },
    )..start(SleepSupportIntent.nightWaking);
    controller.rest();
    await Future<void>.delayed(Duration.zero);
    expect(controller.state!.saveFailed, isTrue);

    expect(controller.start(SleepSupportIntent.distressed), isTrue);
    expect(controller.state!.intent, SleepSupportIntent.distressed);
    fail = false;
    expect(await controller.retrySave(), isTrue);
    controller.dispose();
  });
}

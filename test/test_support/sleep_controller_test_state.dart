import 'package:flutter/foundation.dart';
import 'package:vocabulary_sleep_app/src/models/sleep_daily_log.dart';
import 'package:vocabulary_sleep_app/src/services/sleep/sleep_routine_controller.dart';
import 'package:vocabulary_sleep_app/src/services/sleep/sleep_sound_controller.dart';
import 'package:vocabulary_sleep_app/src/services/sleep/sleep_support_session_controller.dart';

/// Controller dependencies for the general UI smoke fixture.
/// Dedicated sleep flow tests use the real AppState and settings repository.
mixin SleepControllerTestState on ChangeNotifier {
  void saveSleepNightEvent(SleepNightEvent event);

  final sleepRoutineController = SleepRoutineController(automaticTick: false);
  final sleepSoundController = SleepSoundController(
    playerFactory: () => throw StateError('Audio unavailable in smoke fixture'),
  );
  late final sleepSupportSessionController = SleepSupportSessionController(
    saveEvent: (event) async => saveSleepNightEvent(event),
  );

  @override
  void dispose() {
    sleepRoutineController.dispose();
    sleepSoundController.dispose();
    sleepSupportSessionController.dispose();
    super.dispose();
  }
}

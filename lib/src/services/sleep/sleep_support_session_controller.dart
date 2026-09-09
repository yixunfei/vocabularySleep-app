import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../models/sleep_daily_log.dart';
import '../../models/sleep_support_session.dart';

typedef SleepNightEventWriter = Future<void> Function(SleepNightEvent event);

/// Module-owned guide state. Navigating away leaves the guide resumable.
class SleepSupportSessionController extends ChangeNotifier {
  SleepSupportSessionController({
    required this._saveEvent,
    DateTime Function()? now,
    String Function()? idFactory,
  }) : _now = now ?? DateTime.now,
       _idFactory = idFactory ?? const Uuid().v4;

  final SleepNightEventWriter _saveEvent;
  final DateTime Function() _now;
  final String Function() _idFactory;
  SleepSupportSession? _state;
  SleepNightRescueMode _mode = SleepNightRescueMode.briefAwakening;
  SleepNightEvent? _pendingEvent;
  Future<bool>? _pendingSave;
  bool _disposed = false;

  SleepSupportSession? get state => _state;

  bool start(SleepSupportIntent intent, {SleepNightRescueMode? initialMode}) {
    if (_disposed) return false;
    final current = _state;
    if (current != null) {
      if (current.isPersisting || current.saveFailed) return false;
      if (!current.isFinished) return current.intent == intent;
    }
    _mode =
        initialMode ??
        (intent == SleepSupportIntent.distressed
            ? SleepNightRescueMode.bodyActivated
            : SleepNightRescueMode.briefAwakening);
    _pendingEvent = null;
    _pendingSave = null;
    _update(
      SleepSupportSession(
        id: _idFactory(),
        intent: intent,
        startedAt: _now(),
        step: _initialStep(intent, initialMode),
      ),
    );
    return true;
  }

  void choose(SleepSupportChoice choice) {
    final current = _state;
    if (!_canInteract || current == null || !current.choices.contains(choice)) {
      return;
    }
    switch (choice) {
      case SleepSupportChoice.continueGuide:
        _move(SleepSupportStep.softenBody);
      case SleepSupportChoice.stillAwake:
        _mode = SleepNightRescueMode.fullyAwake;
        _move(SleepSupportStep.leaveBed);
      case SleepSupportChoice.sleepy:
      case SleepSupportChoice.rest:
        rest();
      case SleepSupportChoice.racingThoughts:
        _mode = SleepNightRescueMode.racingThoughts;
        _move(SleepSupportStep.easeThoughts);
      case SleepSupportChoice.bodyTension:
        _mode = SleepNightRescueMode.bodyActivated;
        _move(SleepSupportStep.easeTension);
      case SleepSupportChoice.temperature:
        _mode = SleepNightRescueMode.temperatureDiscomfort;
        _move(SleepSupportStep.adjustTemperature);
      case SleepSupportChoice.leftBed:
        _update(
          current.copyWith(
            step: SleepSupportStep.awayFromBed,
            hasEngaged: true,
            hasLeftBed: true,
          ),
        );
      case SleepSupportChoice.returnedToBed:
        if (!current.hasLeftBed) return;
        _update(
          current.copyWith(
            hasEngaged: true,
            returnedToBedAt: _now(),
            isResting: true,
          ),
        );
    }
  }

  void skip() {
    if (!_canInteract) return;
    final next = switch (_state!.step) {
      SleepSupportStep.releaseDay => SleepSupportStep.softenBody,
      SleepSupportStep.wakingSettle => SleepSupportStep.chooseMethod,
      SleepSupportStep.distressSettle => SleepSupportStep.chooseMethod,
      _ => null,
    };
    if (next == null) {
      rest();
    } else {
      // Skipping alone does not attest that an action was performed.
      _update(_state!.copyWith(step: next, isResting: false));
    }
  }

  void changeMethod() {
    if (!_canInteract) return;
    _update(
      _state!.copyWith(step: SleepSupportStep.chooseMethod, isResting: false),
    );
  }

  void rest() {
    if (!_canInteract) return;
    _update(_state!.copyWith(hasEngaged: true, isResting: true));
  }

  void resumeGuide() {
    if (!_canInteract || !_state!.isResting) return;
    final current = _state!;
    final step = current.returnedToBedAt != null
        ? SleepSupportStep.wakingSettle
        : current.step;
    _update(current.copyWith(step: step, isResting: false));
  }

  /// Only an explicit end after an acknowledged action creates a night record.
  /// Preparing for bed is not a night awakening and must not inflate its count.
  Future<bool> finish() {
    if (_disposed || _state == null) return Future.value(false);
    if (_pendingSave != null) return _pendingSave!;
    final current = _state!;
    if (current.isSaved) return Future.value(true);
    if (current.saveFailed) return Future.value(false);
    if (current.isFinished) return Future.value(true);
    final ended = current.copyWith(isFinished: true, endedAt: _now());
    if (!ended.hasEngaged ||
        ended.intent == SleepSupportIntent.prepareForSleep) {
      _update(ended);
      return Future.value(true);
    }
    _pendingEvent = _eventFor(ended);
    _state = ended;
    return _persist();
  }

  Future<bool> retrySave() {
    if (_disposed || _state == null) return Future.value(false);
    if (_pendingSave != null) return _pendingSave!;
    if (!_state!.saveFailed || _pendingEvent == null) {
      return Future.value(_state!.isSaved);
    }
    return _persist();
  }

  void discard() {
    if (_disposed || _state?.isPersisting == true) return;
    _state = null;
    _pendingEvent = null;
    _pendingSave = null;
    notifyListeners();
  }

  Future<bool> _persist() {
    final event = _pendingEvent!;
    // Schedule storage after assigning the shared future, preventing reentrant
    // listeners and double taps from dispatching a second write.
    final future = Future<void>(() => _saveEvent(event)).then(
      (_) {
        if (!_disposed && _state?.id == event.id) {
          _pendingSave = null;
          _update(_state!.copyWith(isPersisting: false, isSaved: true));
        }
        return true;
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_disposed && _state?.id == event.id) {
          _pendingSave = null;
          _update(_state!.copyWith(isPersisting: false, saveFailed: true));
        }
        return false;
      },
    );
    _pendingSave = future;
    _update(_state!.copyWith(isPersisting: true, saveFailed: false));
    return future;
  }

  SleepNightEvent _eventFor(SleepSupportSession session) {
    final day = session.startedAt;
    final dateKey =
        '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    return SleepNightEvent(
      id: session.id,
      dateKey: dateKey,
      mode: _mode,
      intent: session.intent,
      hasLeftBed: session.hasLeftBed ? true : null,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      returnedToBedAt: session.returnedToBedAt,
    );
  }

  SleepSupportStep _initialStep(
    SleepSupportIntent intent,
    SleepNightRescueMode? mode,
  ) {
    if (intent == SleepSupportIntent.prepareForSleep) {
      return SleepSupportStep.releaseDay;
    }
    return switch (mode) {
      SleepNightRescueMode.racingThoughts => SleepSupportStep.easeThoughts,
      SleepNightRescueMode.bodyActivated => SleepSupportStep.easeTension,
      SleepNightRescueMode.temperatureDiscomfort =>
        SleepSupportStep.adjustTemperature,
      SleepNightRescueMode.fullyAwake => SleepSupportStep.leaveBed,
      _ =>
        intent == SleepSupportIntent.nightWaking
            ? SleepSupportStep.wakingSettle
            : SleepSupportStep.distressSettle,
    };
  }

  bool get _canInteract => !_disposed && _state != null && !_state!.isFinished;

  void _move(SleepSupportStep step) {
    _update(_state!.copyWith(step: step, hasEngaged: true, isResting: false));
  }

  void _update(SleepSupportSession next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

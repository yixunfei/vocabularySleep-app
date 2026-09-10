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
  final List<SleepNightEvent> _failedEvents = <SleepNightEvent>[];
  Future<bool>? _pendingSave;
  bool _disposed = false;

  SleepSupportSession? get state => _state;

  bool start(SleepSupportIntent intent, {SleepNightRescueMode? initialMode}) {
    if (_disposed) return false;
    final current = _state;
    if (current != null) {
      if (_isStale(current)) {
        // A session from a previous calendar day must never reappear as the
        // current night's guidance. Any checkpoint already written remains a
        // historical fact; an unfinished in-memory draft is simply dropped.
        _state = null;
        _pendingEvent = null;
      } else {
        // A failed write belongs to the previous attempt. Keep it retryable,
        // while allowing a tired user to start a fresh support flow immediately.
        if (current.saveFailed) {
          _rememberFailed(_pendingEvent);
          _state = null;
          _pendingEvent = null;
          _pendingSave = null;
        } else if (current.isPersisting) {
          return false;
        } else if (!current.isFinished) {
          return current.intent == intent;
        }
      }
    }
    _mode =
        initialMode ??
        (intent == SleepSupportIntent.distressed
            ? SleepNightRescueMode.bodyActivated
            : SleepNightRescueMode.briefAwakening);
    _pendingEvent = null;
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
    final next = _state!.copyWith(
      hasEngaged: true,
      isResting: true,
      endedAt: _now(),
    );
    _update(next);
    // Checkpoint the acknowledged support action before the user locks the
    // phone. The end time marks the support segment, never an inferred sleep
    // outcome. A later explicit finish only closes the UI session.
    if (next.intent != SleepSupportIntent.prepareForSleep) {
      final event = _eventFor(next);
      _pendingEvent = event;
      _persist(event);
    }
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
    final current = _state!;
    if (current.saveFailed) {
      // Surface the retry/leave actions instead of trapping the user in the
      // live guide after a checkpoint write failure.
      _update(current.copyWith(isFinished: true));
      return Future.value(false);
    }
    if (_pendingSave != null) {
      if (!current.isFinished) {
        _update(current.copyWith(isFinished: true));
      }
      return _pendingSave!;
    }
    if (current.isFinished) return Future.value(true);
    if (current.isSaved) {
      _update(current.copyWith(isFinished: true));
      return Future.value(true);
    }
    final ended = current.copyWith(isFinished: true, endedAt: _now());
    if (!ended.hasEngaged ||
        ended.intent == SleepSupportIntent.prepareForSleep) {
      _update(ended);
      return Future.value(true);
    }
    _pendingEvent = _eventFor(ended);
    _state = ended;
    return _persist(_pendingEvent!);
  }

  Future<bool> retrySave() {
    if (_disposed || _state == null) return Future.value(false);
    if (_pendingSave != null) return _pendingSave!;
    if (_state!.saveFailed && _pendingEvent != null) {
      return _persist(_pendingEvent!);
    }
    if (_failedEvents.isEmpty) {
      return Future.value(_state!.isSaved);
    }
    final event = _failedEvents.removeAt(0);
    return _persist(event);
  }

  void discard() {
    if (_disposed || _state?.isPersisting == true) return;
    _state = null;
    _pendingEvent = null;
    _pendingSave = null;
    notifyListeners();
  }

  Future<bool> _persist(SleepNightEvent event) {
    if (_pendingSave != null) {
      return _pendingSave!;
    }
    // Assign the shared future before notifying listeners, preventing
    // reentrant completion and double taps from dispatching a second write.
    final future = () async {
      try {
        // Keep persistence off the interaction stack so selecting a night
        // action remains immediate even when the repository is synchronous.
        await Future<void>(() => _saveEvent(event));
        _pendingSave = null;
        _removeFailed(event.id);
        if (!_disposed && _state?.id == event.id) {
          final next = _state!.copyWith(isPersisting: false, isSaved: true);
          _state = next;
          // A finished screen is about to be popped; avoid notifying a
          // listener that may dispose the controller during its callback.
          if (!next.isFinished) notifyListeners();
        }
        return true;
      } catch (_) {
        _pendingSave = null;
        if (!_disposed && _state?.id == event.id) {
          _rememberFailed(event);
          _update(_state!.copyWith(isPersisting: false, saveFailed: true));
        }
        return false;
      }
    }();
    _pendingSave = future;
    if (!_disposed && _state?.id == event.id) {
      _update(_state!.copyWith(isPersisting: true, saveFailed: false));
    }
    return future;
  }

  void _rememberFailed(SleepNightEvent? event) {
    if (event == null || _failedEvents.any((item) => item.id == event.id)) {
      return;
    }
    _failedEvents.add(event);
  }

  void _removeFailed(String? id) {
    _failedEvents.removeWhere((item) => item.id == id);
  }

  bool _isStale(SleepSupportSession session) {
    final started = session.startedAt;
    final current = _now();
    return started.year != current.year ||
        started.month != current.month ||
        started.day != current.day;
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

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/sleep_routine_template.dart';

/// Owns the routine clock independently from page and global app rebuilds.
class SleepRoutineController extends ChangeNotifier
    implements ValueListenable<SleepRoutineRunnerState> {
  SleepRoutineController({DateTime Function()? now, this._automaticTick = true})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final bool _automaticTick;
  SleepRoutineRunnerState _value = const SleepRoutineRunnerState();
  SleepRoutineTemplate? _activeTemplate;
  Duration _stepRemaining = Duration.zero;
  DateTime? _lastSynchronizedAt;
  Timer? _timer;
  int _tickerEpoch = 0;
  bool _isCompleted = false;
  bool _disposed = false;

  @override
  SleepRoutineRunnerState get value => _value;

  bool get isCompleted => _isCompleted;

  /// The running template is a snapshot, safe from list edits in the library.
  SleepRoutineTemplate? get activeTemplate => _activeTemplate;

  void selectTemplate(SleepRoutineTemplate? template) {
    if (_disposed || _sameTemplate(_activeTemplate, template)) return;
    _cancelTicker();
    _activeTemplate = template == null ? null : _snapshot(template);
    _lastSynchronizedAt = null;
    _stepRemaining = Duration.zero;
    _publish(SleepRoutineRunnerState(activeTemplateId: template?.id));
  }

  void start(SleepRoutineTemplate template) {
    if (_disposed) return;
    _cancelTicker();
    _activeTemplate = _snapshot(template);
    final now = _now();
    _lastSynchronizedAt = now;
    if (template.steps.isEmpty) {
      _stepRemaining = Duration.zero;
      _publish(SleepRoutineRunnerState(activeTemplateId: template.id));
      return;
    }
    _stepRemaining = _durationForStep(0);
    _publish(
      SleepRoutineRunnerState(
        activeTemplateId: template.id,
        remainingSeconds: _displaySeconds,
        isRunning: true,
        startedAt: now,
      ),
    );
    synchronize();
    _startTicker();
  }

  void pause() {
    if (_disposed || !_value.isRunning) return;
    synchronize();
    if (!_value.isRunning) return;
    _cancelTicker();
    _lastSynchronizedAt = null;
    _publish(_value.copyWith(isRunning: false, isPaused: true));
  }

  void resume() {
    if (_disposed || !_value.isPaused || _activeTemplate == null) return;
    _lastSynchronizedAt = _now();
    _publish(_value.copyWith(isRunning: true, isPaused: false));
    synchronize();
    _startTicker();
  }

  void advance() {
    if (_disposed || (!_value.isRunning && !_value.isPaused)) return;
    final displayedStep = _value.currentStepIndex;
    synchronize();
    if (_isCompleted || _value.currentStepIndex != displayedStep) return;
    final nextIndex = displayedStep + 1;
    if (nextIndex >= _activeTemplate!.steps.length) {
      _complete();
      return;
    }
    _stepRemaining = _durationForStep(nextIndex);
    _lastSynchronizedAt = _value.isRunning ? _now() : null;
    _publish(
      _value.copyWith(
        currentStepIndex: nextIndex,
        remainingSeconds: _displaySeconds,
      ),
    );
    synchronize();
  }

  void stop() {
    if (_disposed) return;
    _cancelTicker();
    _lastSynchronizedAt = null;
    _stepRemaining = Duration.zero;
    _publish(SleepRoutineRunnerState(activeTemplateId: _activeTemplate?.id));
  }

  /// Reconcile all elapsed time in one update, including multiple missed steps.
  void synchronize() {
    if (_disposed || !_value.isRunning || _activeTemplate == null) return;
    final now = _now();
    final last = _lastSynchronizedAt ?? now;
    // A backward wall-clock adjustment must not add time or double-count it.
    if (now.isBefore(last)) return;
    var elapsed = now.difference(last);
    _lastSynchronizedAt = now;
    var index = _value.currentStepIndex;
    while (elapsed >= _stepRemaining) {
      elapsed -= _stepRemaining;
      index += 1;
      if (index >= _activeTemplate!.steps.length) {
        _complete();
        return;
      }
      _stepRemaining = _durationForStep(index);
    }
    _stepRemaining -= elapsed;
    _publish(
      _value.copyWith(
        currentStepIndex: index,
        remainingSeconds: _displaySeconds,
      ),
    );
  }

  Duration _durationForStep(int index) {
    final seconds = _activeTemplate!.steps[index].durationSeconds;
    return Duration(seconds: seconds < 0 ? 0 : seconds);
  }

  int get _displaySeconds =>
      (_stepRemaining.inMicroseconds / Duration.microsecondsPerSecond).ceil();

  void _complete() {
    _cancelTicker();
    _lastSynchronizedAt = null;
    _stepRemaining = Duration.zero;
    _publish(
      _value.copyWith(
        currentStepIndex: _activeTemplate!.steps.length - 1,
        remainingSeconds: 0,
        isRunning: false,
        isPaused: false,
      ),
      completed: true,
    );
  }

  void _startTicker() {
    _cancelTicker();
    if (!_automaticTick || !_value.isRunning || _disposed) return;
    final epoch = _tickerEpoch;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (epoch == _tickerEpoch) synchronize();
    });
  }

  void _cancelTicker() {
    _tickerEpoch += 1;
    _timer?.cancel();
    _timer = null;
  }

  void _publish(SleepRoutineRunnerState next, {bool completed = false}) {
    final previous = _value;
    final changed =
        previous.activeTemplateId != next.activeTemplateId ||
        previous.currentStepIndex != next.currentStepIndex ||
        previous.remainingSeconds != next.remainingSeconds ||
        previous.isRunning != next.isRunning ||
        previous.isPaused != next.isPaused ||
        previous.startedAt != next.startedAt ||
        _isCompleted != completed;
    _value = next;
    _isCompleted = completed;
    if (changed && !_disposed) notifyListeners();
  }

  SleepRoutineTemplate _snapshot(SleepRoutineTemplate template) {
    return template.copyWith(
      steps: List<SleepRoutineStep>.unmodifiable(
        template.steps.map(
          (step) => step.copyWith(
            payload: step.payload == null
                ? null
                : Map<String, Object?>.unmodifiable(step.payload!),
          ),
        ),
      ),
    );
  }

  bool _sameTemplate(
    SleepRoutineTemplate? first,
    SleepRoutineTemplate? second,
  ) {
    if (first == null || second == null) return first == second;
    if (first.id != second.id ||
        first.name != second.name ||
        first.steps.length != second.steps.length) {
      return false;
    }
    for (var index = 0; index < first.steps.length; index += 1) {
      final a = first.steps[index];
      final b = second.steps[index];
      if (a.type != b.type ||
          a.label != b.label ||
          a.durationSeconds != b.durationSeconds ||
          !mapEquals(a.payload, b.payload)) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelTicker();
    super.dispose();
  }
}

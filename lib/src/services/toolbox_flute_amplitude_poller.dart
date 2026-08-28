import 'dart:async';

typedef ToolboxFluteAmplitudeReader<T extends Object> = Future<T?> Function();
typedef ToolboxFluteAmplitudeHandler<T extends Object> = void Function(T value);
typedef ToolboxFluteAmplitudeErrorHandler =
    void Function(Object error, StackTrace stackTrace);
typedef _ToolboxFluteAmplitudeCallbacks<T extends Object> = ({
  ToolboxFluteAmplitudeReader<T> read,
  ToolboxFluteAmplitudeHandler<T> onAmplitude,
  ToolboxFluteAmplitudeErrorHandler onError,
});

/// Polls microphone amplitude without overlapping platform calls.
final class ToolboxFluteAmplitudePoller<T extends Object> {
  ToolboxFluteAmplitudePoller({
    required ToolboxFluteAmplitudeReader<T> read,
    required ToolboxFluteAmplitudeHandler<T> onAmplitude,
    required ToolboxFluteAmplitudeErrorHandler onError,
    this.interval = const Duration(milliseconds: 50),
  }) : assert(interval > Duration.zero),
       _callbacks = (read: read, onAmplitude: onAmplitude, onError: onError);

  final _ToolboxFluteAmplitudeCallbacks<T> _callbacks;
  final Duration interval;

  Timer? _timer;
  bool _running = false;
  bool _pollInFlight = false;
  bool _disposed = false;
  int _generation = 0;

  void start() {
    if (_disposed || _running) {
      return;
    }
    _running = true;
    final generation = ++_generation;
    _timer = Timer.periodic(interval, (_) {
      unawaited(_poll(generation));
    });
  }

  void stop() {
    _running = false;
    _generation++;
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    stop();
  }

  Future<void> _poll(int generation) async {
    if (!_isActive(generation) || _pollInFlight) {
      return;
    }
    _pollInFlight = true;
    try {
      final amplitude = await _callbacks.read();
      if (amplitude != null && _isActive(generation)) {
        _callbacks.onAmplitude(amplitude);
      }
    } on Object catch (error, stackTrace) {
      if (_isActive(generation)) {
        _callbacks.onError(error, stackTrace);
      }
    } finally {
      _pollInFlight = false;
    }
  }

  bool _isActive(int generation) {
    return !_disposed && _running && generation == _generation;
  }
}

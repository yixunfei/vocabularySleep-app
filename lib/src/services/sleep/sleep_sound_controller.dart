import 'dart:async';

import 'package:flutter/foundation.dart';

enum SleepSound { brown, pink }

enum SleepSoundStatus { silent, preparing, playing, failed }

abstract interface class SleepSoundPlayer {
  Future<void> play(SleepSound sound, double volume);
  Future<void> setVolume(double volume);
  Future<void> dispose();
}

/// Owns only the sound explicitly started from sleep support.
class SleepSoundController extends ChangeNotifier {
  SleepSoundController({required this.playerFactory, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final SleepSoundPlayer Function() playerFactory;
  final DateTime Function() _now;
  SleepSoundPlayer? _player;
  Timer? _stopTimer;
  DateTime? _stopAt;
  int _generation = 0;
  bool _disposed = false;
  Future<void> _volumeWork = Future<void>.value();
  SleepSoundStatus _status = SleepSoundStatus.silent;
  SleepSound? _sound;
  double _volume = 0.18;
  int _minutes = 30;

  SleepSoundStatus get status => _status;
  SleepSound? get sound => _sound;
  double get volume => _volume;
  int get minutes => _minutes;

  Future<void> play(SleepSound sound) async {
    if (_disposed) return;
    if (_sound == sound && _status == SleepSoundStatus.preparing) return;
    final generation = ++_generation;
    final previous = _player;
    _player = null;
    _stopTimer?.cancel();
    _stopAt = null;
    _sound = sound;
    _status = SleepSoundStatus.preparing;
    notifyListeners();
    await _release(previous);
    if (!_isCurrent(generation)) return;
    SleepSoundPlayer? player;
    try {
      player = playerFactory();
      _player = player;
      await player.play(sound, _volume).timeout(const Duration(seconds: 15));
      if (!_isCurrent(generation)) {
        await _release(player);
        return;
      }
      await player.setVolume(_volume);
      if (!_isCurrent(generation)) return;
      _status = SleepSoundStatus.playing;
      _scheduleStop();
      notifyListeners();
    } on Object {
      await _release(player);
      if (!_isCurrent(generation)) return;
      _player = null;
      _status = SleepSoundStatus.failed;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    if (_disposed) return;
    ++_generation;
    _stopTimer?.cancel();
    _stopAt = null;
    final player = _player;
    _player = null;
    _status = SleepSoundStatus.silent;
    notifyListeners();
    await _release(player);
  }

  Future<void> setVolume(double value) {
    if (_disposed) return Future<void>.value();
    _volume = value.clamp(0.05, 0.35);
    notifyListeners();
    final player = _player;
    final generation = _generation;
    final volume = _volume;
    _volumeWork = _volumeWork.then((_) async {
      if (player == null || !_isCurrent(generation)) return;
      try {
        await player.setVolume(volume);
      } on Object {
        if (!_isCurrent(generation)) return;
        final stoppedGeneration = _generation + 1;
        await stop();
        if (!_isCurrent(stoppedGeneration)) return;
        _status = SleepSoundStatus.failed;
        notifyListeners();
      }
    });
    return _volumeWork;
  }

  void setMinutes(int minutes) {
    if (_disposed || !const [15, 30, 60].contains(minutes)) return;
    _minutes = minutes;
    if (_status == SleepSoundStatus.playing) _scheduleStop();
    notifyListeners();
  }

  void synchronize() {
    if (_disposed || _stopAt == null) return;
    if (!_now().isBefore(_stopAt!)) unawaited(stop());
  }

  void _scheduleStop() {
    _stopTimer?.cancel();
    _stopAt = _now().add(Duration(minutes: _minutes));
    _stopTimer = Timer(Duration(minutes: _minutes), () => unawaited(stop()));
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  Future<void> _release(SleepSoundPlayer? player) async {
    if (player == null) return;
    try {
      await player.dispose();
    } on Object {
      // Platform teardown may race a source preparation cancelled by the user.
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    ++_generation;
    _stopTimer?.cancel();
    unawaited(_release(_player));
    _player = null;
    super.dispose();
  }
}

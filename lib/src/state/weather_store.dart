import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/weather_snapshot.dart';
import '../services/app_log_service.dart';
import '../services/settings_service.dart';
import '../services/weather_service.dart';

class WeatherStore extends ChangeNotifier {
  WeatherStore({
    required SettingsService settings,
    required WeatherService weatherService,
    AppLogService? log,
    bool initialEnabled = false,
  }) : _settings = settings,
       _weatherService = weatherService,
       _log = log ?? AppLogService.instance,
       _enabled = initialEnabled;

  static const Duration _staleDuration = Duration(minutes: 30);

  final SettingsService _settings;
  final WeatherService _weatherService;
  final AppLogService _log;

  bool _enabled;
  WeatherSnapshot? _snapshot;
  bool _loading = false;

  bool get enabled => _enabled;

  WeatherSnapshot? get snapshot => _snapshot;

  bool get loading => _loading;

  void syncEnabledFromSettings() {
    final next = _settings.loadWeatherEnabled();
    if (_enabled == next) {
      return;
    }
    _enabled = next;
    notifyListeners();
  }

  void setEnabled(bool enabled) {
    if (_enabled == enabled) {
      return;
    }
    _enabled = enabled;
    _settings.saveWeatherEnabled(enabled);
    notifyListeners();
    if (enabled) {
      unawaited(refresh(force: true));
    }
  }

  bool isStale() {
    final current = _snapshot;
    if (current == null) {
      return true;
    }
    return DateTime.now().difference(current.fetchedAt) >= _staleDuration;
  }

  void refreshIfStale() {
    if (_loading || !isStale() || !_enabled) {
      return;
    }
    unawaited(refresh());
  }

  Future<void> refresh({bool force = false, bool bypassEnabled = false}) async {
    if (!bypassEnabled && !_enabled) {
      return;
    }
    await _refreshSnapshot(force: force);
  }

  Future<void> _refreshSnapshot({bool force = false}) async {
    if (_loading) {
      return;
    }
    if (!force && !isStale()) {
      return;
    }

    _loading = true;
    notifyListeners();
    try {
      _snapshot = await _weatherService.fetchCurrentWeather();
    } catch (error) {
      _log.w(
        'weather_store',
        'weather refresh failed',
        data: <String, Object?>{'error': '$error'},
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

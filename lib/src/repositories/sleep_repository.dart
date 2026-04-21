import 'dart:convert';

import '../models/sleep_daily_log.dart';
import '../models/sleep_plan.dart';
import '../models/sleep_profile.dart';
import '../models/sleep_routine_template.dart';
import 'settings_store_repository.dart';

abstract class SleepRepository {
  SleepProfile? loadSleepProfile();

  void saveSleepProfile(SleepProfile? profile);

  List<SleepDailyLog> loadSleepDailyLogs();

  void saveSleepDailyLogs(List<SleepDailyLog> logs);

  List<SleepNightEvent> loadSleepNightEvents();

  void saveSleepNightEvents(List<SleepNightEvent> events);

  List<SleepThoughtEntry> loadSleepThoughtEntries();

  void saveSleepThoughtEntries(List<SleepThoughtEntry> entries);

  SleepPlan? loadSleepCurrentPlan();

  void saveSleepCurrentPlan(SleepPlan? plan);

  List<SleepRoutineTemplate> loadSleepRoutineTemplates();

  void saveSleepRoutineTemplates(List<SleepRoutineTemplate> templates);

  String? loadSleepActiveRoutineTemplateId();

  void saveSleepActiveRoutineTemplateId(String? id);

  SleepDashboardState loadSleepDashboardState();

  void saveSleepDashboardState(SleepDashboardState state);

  SleepProgramProgress? loadSleepProgramProgress();

  void saveSleepProgramProgress(SleepProgramProgress? progress);
}

class SettingsStoreSleepRepository implements SleepRepository {
  const SettingsStoreSleepRepository(this._store);

  final SettingsStoreRepository _store;

  @override
  SleepProfile? loadSleepProfile() {
    return SleepProfile.fromJsonValue(_loadJsonValue('sleepProfile'));
  }

  @override
  void saveSleepProfile(SleepProfile? profile) {
    _saveJsonValue('sleepProfile', profile?.toJsonMap());
  }

  @override
  List<SleepDailyLog> loadSleepDailyLogs() {
    return _loadJsonList('sleepDailyLogs', SleepDailyLog.fromJsonValue);
  }

  @override
  void saveSleepDailyLogs(List<SleepDailyLog> logs) {
    _saveJsonValue(
      'sleepDailyLogs',
      logs.map((log) => log.toJsonMap()).toList(growable: false),
    );
  }

  @override
  List<SleepNightEvent> loadSleepNightEvents() {
    return _loadJsonList('sleepNightEvents', SleepNightEvent.fromJsonValue);
  }

  @override
  void saveSleepNightEvents(List<SleepNightEvent> events) {
    _saveJsonValue(
      'sleepNightEvents',
      events.map((event) => event.toJsonMap()).toList(growable: false),
    );
  }

  @override
  List<SleepThoughtEntry> loadSleepThoughtEntries() {
    return _loadJsonList(
      'sleepThoughtEntries',
      SleepThoughtEntry.fromJsonValue,
    );
  }

  @override
  void saveSleepThoughtEntries(List<SleepThoughtEntry> entries) {
    _saveJsonValue(
      'sleepThoughtEntries',
      entries.map((entry) => entry.toJsonMap()).toList(growable: false),
    );
  }

  @override
  SleepPlan? loadSleepCurrentPlan() {
    return SleepPlan.fromJsonValue(_loadJsonValue('sleepCurrentPlan'));
  }

  @override
  void saveSleepCurrentPlan(SleepPlan? plan) {
    _saveJsonValue('sleepCurrentPlan', plan?.toJsonMap());
  }

  @override
  List<SleepRoutineTemplate> loadSleepRoutineTemplates() {
    return _loadJsonList(
      'sleepRoutineTemplates',
      SleepRoutineTemplate.fromJsonValue,
    );
  }

  @override
  void saveSleepRoutineTemplates(List<SleepRoutineTemplate> templates) {
    _saveJsonValue(
      'sleepRoutineTemplates',
      templates.map((template) => template.toJsonMap()).toList(growable: false),
    );
  }

  @override
  String? loadSleepActiveRoutineTemplateId() {
    final raw = _store.getSetting('sleepActiveRoutineTemplateId');
    if (raw == null) {
      return null;
    }
    final normalized = raw.trim();
    return normalized.isEmpty ? null : normalized;
  }

  @override
  void saveSleepActiveRoutineTemplateId(String? id) {
    _store.setSetting('sleepActiveRoutineTemplateId', id?.trim() ?? '');
  }

  @override
  SleepDashboardState loadSleepDashboardState() {
    return SleepDashboardState.fromJsonValue(
      _loadJsonValue('sleepDashboardState'),
    );
  }

  @override
  void saveSleepDashboardState(SleepDashboardState state) {
    _saveJsonValue('sleepDashboardState', state.toJsonMap());
  }

  @override
  SleepProgramProgress? loadSleepProgramProgress() {
    return SleepProgramProgress.fromJsonValue(
      _loadJsonValue('sleepProgramProgress'),
    );
  }

  @override
  void saveSleepProgramProgress(SleepProgramProgress? progress) {
    _saveJsonValue('sleepProgramProgress', progress?.toJsonMap());
  }

  Object? _loadJsonValue(String key) {
    final raw = _store.getSetting(key);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  List<T> _loadJsonList<T>(String key, T? Function(Object?) decoder) {
    final decoded = _loadJsonValue(key);
    if (decoded is! List) {
      return <T>[];
    }
    return decoded.map(decoder).whereType<T>().toList(growable: false);
  }

  void _saveJsonValue(String key, Object? value) {
    if (value == null) {
      _store.setSetting(key, '');
      return;
    }
    _store.setSetting(key, jsonEncode(value));
  }
}

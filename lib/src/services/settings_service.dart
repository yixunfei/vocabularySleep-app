import 'dart:convert';

import '../models/ambient_preset.dart';
import '../models/app_home_tab.dart';
import '../models/focus_startup_tab.dart';
import '../models/play_config.dart';
import '../models/sleep_daily_log.dart';
import '../models/sleep_plan.dart';
import '../models/sleep_profile.dart';
import '../models/sleep_routine_template.dart';
import '../models/settings_dto.dart';
import '../models/study_startup_tab.dart';
import 'database_service.dart';

class SettingsService {
  const SettingsService(this._database);

  static const String uiLanguageSystem = 'system';
  static const String remotePrewarmCompletedKey =
      'remoteResourcePrewarmCompletedV1';

  final AppDatabaseService _database;

  PlayConfig loadPlayConfig() {
    final raw = _database.getSetting('playConfig');
    if (raw == null || raw.trim().isEmpty) return PlayConfig.defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return PlayConfig.fromJson(decoded.cast<String, Object?>());
      }
    } catch (_) {
      // ignore invalid JSON and fallback to defaults.
    }
    return PlayConfig.defaults;
  }

  void savePlayConfig(PlayConfig config) {
    _database.setSetting('playConfig', jsonEncode(config.toJson()));
  }

  String loadUiLanguage() {
    final raw = _database.getSetting('uiLanguage');
    if (raw == null) return uiLanguageSystem;
    final normalized = raw.trim();
    return normalized.isEmpty ? uiLanguageSystem : normalized;
  }

  void saveUiLanguage(String language) {
    final normalized = language.trim();
    _database.setSetting(
      'uiLanguage',
      normalized.isEmpty ? uiLanguageSystem : normalized,
    );
  }

  AppHomeTab loadStartupPage() {
    return AppHomeTabX.fromStorage(_database.getSetting('startupPage'));
  }

  void saveStartupPage(AppHomeTab page) {
    _database.setSetting('startupPage', page.storageValue);
  }

  FocusStartupTab loadFocusStartupTab() {
    return FocusStartupTabX.fromStorage(
      _database.getSetting('focusStartupTab'),
    );
  }

  void saveFocusStartupTab(FocusStartupTab tab) {
    _database.setSetting('focusStartupTab', tab.storageValue);
  }

  StudyStartupTab loadStudyStartupTab() {
    final stored = _database.getSetting('studyStartupTab');
    if (stored != null && stored.trim().isNotEmpty) {
      return StudyStartupTabX.fromStorage(stored);
    }
    final legacyStartup = _database.getSetting('startupPage');
    if ((legacyStartup ?? '').trim() == 'library') {
      return StudyStartupTab.library;
    }
    return StudyStartupTab.play;
  }

  void saveStudyStartupTab(StudyStartupTab tab) {
    _database.setSetting('studyStartupTab', tab.storageValue);
  }

  bool loadWeatherEnabled() {
    return _database.getSetting('weatherEnabled') == '1';
  }

  void saveWeatherEnabled(bool enabled) {
    _database.setSetting('weatherEnabled', enabled ? '1' : '0');
  }

  bool loadStartupTodoPromptEnabled() {
    final raw = _database.getSetting('startupTodoPromptEnabled');
    if (raw == null || raw.trim().isEmpty) {
      return true;
    }
    return raw.trim() == '1';
  }

  void saveStartupTodoPromptEnabled(bool enabled) {
    _database.setSetting('startupTodoPromptEnabled', enabled ? '1' : '0');
  }

  String? loadStartupTodoPromptSuppressedDate() {
    final raw = _database.getSetting('startupTodoPromptSuppressedDate');
    if (raw == null) {
      return null;
    }
    final normalized = raw.trim();
    return normalized.isEmpty ? null : normalized;
  }

  void saveStartupTodoPromptSuppressedDate(String? dateKey) {
    _database.setSetting(
      'startupTodoPromptSuppressedDate',
      dateKey?.trim() ?? '',
    );
  }

  TestModeState loadTestModeState() {
    final raw = _database.getSetting('testModeState');
    if (raw == null || raw.trim().isEmpty) {
      return TestModeState.defaults;
    }

    try {
      final decoded = jsonDecode(raw);
      return TestModeState.fromJsonValue(decoded);
    } catch (_) {
      // ignore and fallback.
    }

    return TestModeState.defaults;
  }

  void saveTestModeState(TestModeState state) {
    _database.setSetting('testModeState', jsonEncode(state.toJsonMap()));
  }

  PracticeDashboardState loadPracticeDashboard() {
    final raw = _database.getSetting('practiceDashboard');
    if (raw == null || raw.trim().isEmpty) {
      return PracticeDashboardState.defaults;
    }
    try {
      final decoded = jsonDecode(raw);
      return PracticeDashboardState.fromJsonValue(decoded);
    } catch (_) {
      // ignore and fallback.
    }
    return PracticeDashboardState.defaults;
  }

  void savePracticeDashboard(PracticeDashboardState data) {
    _database.setSetting('practiceDashboard', jsonEncode(data.toJsonMap()));
  }

  Set<String> loadRememberedWords() {
    final raw = _database.getSetting('rememberedWords');
    if (raw == null || raw.trim().isEmpty) {
      return <String>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <String>{};
      }
      return decoded
          .map((item) => '$item'.trim().toLowerCase())
          .where((item) => item.isNotEmpty)
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  void saveRememberedWords(Set<String> words) {
    final sorted = words.toList(growable: false)..sort();
    _database.setSetting('rememberedWords', jsonEncode(sorted));
  }

  Map<String, PlaybackProgressSnapshot> loadPlaybackProgressByWordbook() {
    final raw = _database.getSetting('playbackProgressByWordbook');
    if (raw == null || raw.trim().isEmpty) {
      return const <String, PlaybackProgressSnapshot>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const <String, PlaybackProgressSnapshot>{};
      }
      final output = <String, PlaybackProgressSnapshot>{};
      for (final entry in decoded.entries) {
        final path = '${entry.key}'.trim();
        if (path.isEmpty || entry.value is! Map) {
          continue;
        }
        output[path] = PlaybackProgressSnapshot.fromJsonMap(
          (entry.value as Map).cast<String, Object?>(),
        );
      }
      return output;
    } catch (_) {
      return const <String, PlaybackProgressSnapshot>{};
    }
  }

  void savePlaybackProgressByWordbook(
    Map<String, PlaybackProgressSnapshot> snapshots,
  ) {
    final keys = snapshots.keys.toList(growable: false)..sort();
    _database.setSetting(
      'playbackProgressByWordbook',
      jsonEncode(<String, Object?>{
        for (final key in keys) key: snapshots[key]!.toJsonMap(),
      }),
    );
  }

  List<AmbientPreset> loadAmbientPresets() {
    final raw = _database.getSetting('ambientPresets');
    if (raw == null || raw.trim().isEmpty) {
      return const <AmbientPreset>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <AmbientPreset>[];
      }
      return decoded
          .map(AmbientPreset.fromJsonValue)
          .whereType<AmbientPreset>()
          .toList(growable: false);
    } catch (_) {
      return const <AmbientPreset>[];
    }
  }

  void saveAmbientPresets(List<AmbientPreset> presets) {
    _database.setSetting(
      'ambientPresets',
      jsonEncode(
        presets.map((preset) => preset.toJson()).toList(growable: false),
      ),
    );
  }

  bool loadRemoteResourcePrewarmCompleted() {
    return _database.getSetting(remotePrewarmCompletedKey) == '1';
  }

  void saveRemoteResourcePrewarmCompleted(bool value) {
    _database.setSetting(remotePrewarmCompletedKey, value ? '1' : '0');
  }

  SleepProfile? loadSleepProfile() {
    final decoded = _loadJsonValue('sleepProfile');
    return SleepProfile.fromJsonValue(decoded);
  }

  void saveSleepProfile(SleepProfile? profile) {
    _saveJsonValue('sleepProfile', profile?.toJsonMap());
  }

  List<SleepDailyLog> loadSleepDailyLogs() {
    return _loadJsonList('sleepDailyLogs', SleepDailyLog.fromJsonValue);
  }

  void saveSleepDailyLogs(List<SleepDailyLog> logs) {
    _saveJsonValue(
      'sleepDailyLogs',
      logs.map((log) => log.toJsonMap()).toList(growable: false),
    );
  }

  List<SleepNightEvent> loadSleepNightEvents() {
    return _loadJsonList('sleepNightEvents', SleepNightEvent.fromJsonValue);
  }

  void saveSleepNightEvents(List<SleepNightEvent> events) {
    _saveJsonValue(
      'sleepNightEvents',
      events.map((event) => event.toJsonMap()).toList(growable: false),
    );
  }

  List<SleepThoughtEntry> loadSleepThoughtEntries() {
    return _loadJsonList(
      'sleepThoughtEntries',
      SleepThoughtEntry.fromJsonValue,
    );
  }

  void saveSleepThoughtEntries(List<SleepThoughtEntry> entries) {
    _saveJsonValue(
      'sleepThoughtEntries',
      entries.map((entry) => entry.toJsonMap()).toList(growable: false),
    );
  }

  SleepPlan? loadSleepCurrentPlan() {
    final decoded = _loadJsonValue('sleepCurrentPlan');
    return SleepPlan.fromJsonValue(decoded);
  }

  void saveSleepCurrentPlan(SleepPlan? plan) {
    _saveJsonValue('sleepCurrentPlan', plan?.toJsonMap());
  }

  List<SleepRoutineTemplate> loadSleepRoutineTemplates() {
    return _loadJsonList(
      'sleepRoutineTemplates',
      SleepRoutineTemplate.fromJsonValue,
    );
  }

  void saveSleepRoutineTemplates(List<SleepRoutineTemplate> templates) {
    _saveJsonValue(
      'sleepRoutineTemplates',
      templates
          .map((template) => template.toJsonMap())
          .toList(growable: false),
    );
  }

  String? loadSleepActiveRoutineTemplateId() {
    final raw = _database.getSetting('sleepActiveRoutineTemplateId');
    if (raw == null) {
      return null;
    }
    final normalized = raw.trim();
    return normalized.isEmpty ? null : normalized;
  }

  void saveSleepActiveRoutineTemplateId(String? id) {
    _database.setSetting('sleepActiveRoutineTemplateId', id?.trim() ?? '');
  }

  SleepDashboardState loadSleepDashboardState() {
    final decoded = _loadJsonValue('sleepDashboardState');
    return SleepDashboardState.fromJsonValue(decoded);
  }

  void saveSleepDashboardState(SleepDashboardState state) {
    _saveJsonValue('sleepDashboardState', state.toJsonMap());
  }

  SleepProgramProgress? loadSleepProgramProgress() {
    final decoded = _loadJsonValue('sleepProgramProgress');
    return SleepProgramProgress.fromJsonValue(decoded);
  }

  void saveSleepProgramProgress(SleepProgramProgress? progress) {
    _saveJsonValue('sleepProgramProgress', progress?.toJsonMap());
  }

  Object? _loadJsonValue(String key) {
    final raw = _database.getSetting(key);
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
      _database.setSetting(key, '');
      return;
    }
    _database.setSetting(key, jsonEncode(value));
  }
}

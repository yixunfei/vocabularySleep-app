import 'dart:convert';

import '../core/module_system/module_toggle_state.dart';
import '../models/ambient_preset.dart';
import '../models/app_home_tab.dart';
import '../models/focus_startup_tab.dart';
import '../models/play_config.dart';
import '../models/settings_dto.dart';
import '../models/study_startup_tab.dart';
import '../repositories/settings_store_repository.dart';
import 'database_service.dart';

class SettingsService {
  const SettingsService.fromRepository(this._store);

  factory SettingsService(AppDatabaseService database) {
    return SettingsService.fromRepository(
      DatabaseSettingsStoreRepository(database),
    );
  }

  static const String uiLanguageSystem = 'system';
  static const String remotePrewarmCompletedKey =
      'remoteResourcePrewarmCompletedV1';
  static const String moduleTogglesKey = 'module_toggles_v1';

  final SettingsStoreRepository _store;

  PlayConfig loadPlayConfig() {
    final raw = _store.getSetting('playConfig');
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
    _store.setSetting('playConfig', jsonEncode(config.toJson()));
  }

  String loadUiLanguage() {
    final raw = _store.getSetting('uiLanguage');
    if (raw == null) return uiLanguageSystem;
    final normalized = raw.trim();
    return normalized.isEmpty ? uiLanguageSystem : normalized;
  }

  void saveUiLanguage(String language) {
    final normalized = language.trim();
    _store.setSetting(
      'uiLanguage',
      normalized.isEmpty ? uiLanguageSystem : normalized,
    );
  }

  AppHomeTab loadStartupPage() {
    return AppHomeTabX.fromStorage(_store.getSetting('startupPage'));
  }

  void saveStartupPage(AppHomeTab page) {
    _store.setSetting('startupPage', page.storageValue);
  }

  FocusStartupTab loadFocusStartupTab() {
    return FocusStartupTabX.fromStorage(_store.getSetting('focusStartupTab'));
  }

  void saveFocusStartupTab(FocusStartupTab tab) {
    _store.setSetting('focusStartupTab', tab.storageValue);
  }

  StudyStartupTab loadStudyStartupTab() {
    final stored = _store.getSetting('studyStartupTab');
    if (stored != null && stored.trim().isNotEmpty) {
      return StudyStartupTabX.fromStorage(stored);
    }
    final legacyStartup = _store.getSetting('startupPage');
    if ((legacyStartup ?? '').trim() == 'library') {
      return StudyStartupTab.library;
    }
    return StudyStartupTab.play;
  }

  void saveStudyStartupTab(StudyStartupTab tab) {
    _store.setSetting('studyStartupTab', tab.storageValue);
  }

  bool loadWeatherEnabled() {
    return _store.getSetting('weatherEnabled') == '1';
  }

  void saveWeatherEnabled(bool enabled) {
    _store.setSetting('weatherEnabled', enabled ? '1' : '0');
  }

  bool loadStartupTodoPromptEnabled() {
    final raw = _store.getSetting('startupTodoPromptEnabled');
    if (raw == null || raw.trim().isEmpty) {
      return true;
    }
    return raw.trim() == '1';
  }

  void saveStartupTodoPromptEnabled(bool enabled) {
    _store.setSetting('startupTodoPromptEnabled', enabled ? '1' : '0');
  }

  String? loadStartupTodoPromptSuppressedDate() {
    final raw = _store.getSetting('startupTodoPromptSuppressedDate');
    if (raw == null) {
      return null;
    }
    final normalized = raw.trim();
    return normalized.isEmpty ? null : normalized;
  }

  void saveStartupTodoPromptSuppressedDate(String? dateKey) {
    _store.setSetting('startupTodoPromptSuppressedDate', dateKey?.trim() ?? '');
  }

  TestModeState loadTestModeState() {
    final raw = _store.getSetting('testModeState');
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
    _store.setSetting('testModeState', jsonEncode(state.toJsonMap()));
  }

  PracticeDashboardState loadPracticeDashboard() {
    final raw = _store.getSetting('practiceDashboard');
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
    _store.setSetting('practiceDashboard', jsonEncode(data.toJsonMap()));
  }

  Set<String> loadRememberedWords() {
    final raw = _store.getSetting('rememberedWords');
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
    _store.setSetting('rememberedWords', jsonEncode(sorted));
  }

  Set<String> loadStringSet(String key) {
    final raw = _store.getSetting(key);
    if (raw == null || raw.trim().isEmpty) {
      return <String>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <String>{};
      }
      return decoded
          .map((item) => '$item'.trim())
          .where((item) => item.isNotEmpty)
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  void saveStringSet(String key, Set<String> values) {
    final sorted =
        values
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
    _store.setSetting(key, jsonEncode(sorted));
  }

  Map<String, PlaybackProgressSnapshot> loadPlaybackProgressByWordbook() {
    final raw = _store.getSetting('playbackProgressByWordbook');
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
    _store.setSetting(
      'playbackProgressByWordbook',
      jsonEncode(<String, Object?>{
        for (final key in keys) key: snapshots[key]!.toJsonMap(),
      }),
    );
  }

  List<AmbientPreset> loadAmbientPresets() {
    final raw = _store.getSetting('ambientPresets');
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
    _store.setSetting(
      'ambientPresets',
      jsonEncode(
        presets.map((preset) => preset.toJson()).toList(growable: false),
      ),
    );
  }

  bool loadRemoteResourcePrewarmCompleted() {
    return _store.getSetting(remotePrewarmCompletedKey) == '1';
  }

  void saveRemoteResourcePrewarmCompleted(bool value) {
    _store.setSetting(remotePrewarmCompletedKey, value ? '1' : '0');
  }

  ModuleToggleState loadModuleToggleState() {
    final raw = _store.getSetting(moduleTogglesKey);
    if (raw == null || raw.trim().isEmpty) {
      return ModuleToggleState.defaults;
    }
    try {
      return ModuleToggleState.fromJsonValue(jsonDecode(raw));
    } catch (_) {
      return ModuleToggleState.defaults;
    }
  }

  void saveModuleToggleState(ModuleToggleState value) {
    _store.setSetting(moduleTogglesKey, jsonEncode(value.toJsonMap()));
  }
}

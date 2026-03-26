import 'dart:convert';

import '../models/app_home_tab.dart';
import '../models/focus_startup_tab.dart';
import '../models/play_config.dart';
import '../models/settings_dto.dart';
import 'database_service.dart';

class SettingsService {
  const SettingsService(this._database);

  static const String uiLanguageSystem = 'system';

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
}

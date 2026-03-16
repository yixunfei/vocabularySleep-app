import 'dart:convert';

import '../models/app_home_tab.dart';
import '../models/focus_startup_tab.dart';
import '../models/play_config.dart';
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

  Map<String, bool> loadTestModeState() {
    final raw = _database.getSetting('testModeState');
    if (raw == null || raw.trim().isEmpty) {
      return const <String, bool>{
        'enabled': false,
        'revealed': false,
        'hintRevealed': false,
      };
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return <String, bool>{
          'enabled': decoded['enabled'] as bool? ?? false,
          'revealed': decoded['revealed'] as bool? ?? false,
          'hintRevealed': decoded['hintRevealed'] as bool? ?? false,
        };
      }
    } catch (_) {
      // ignore and fallback.
    }

    return const <String, bool>{
      'enabled': false,
      'revealed': false,
      'hintRevealed': false,
    };
  }

  void saveTestModeState({
    required bool enabled,
    required bool revealed,
    required bool hintRevealed,
  }) {
    _database.setSetting(
      'testModeState',
      jsonEncode(<String, Object?>{
        'enabled': enabled,
        'revealed': revealed,
        'hintRevealed': hintRevealed,
      }),
    );
  }

  Map<String, Object?> loadPracticeDashboard() {
    final raw = _database.getSetting('practiceDashboard');
    if (raw == null || raw.trim().isEmpty) {
      return const <String, Object?>{
        'date': '',
        'todaySessions': 0,
        'todayReviewed': 0,
        'todayRemembered': 0,
        'totalSessions': 0,
        'totalReviewed': 0,
        'totalRemembered': 0,
        'lastSessionTitle': '',
        'rememberedWords': <Object?>[],
        'weakWords': <Object?>[],
      };
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.cast<String, Object?>();
      }
    } catch (_) {
      // ignore and fallback.
    }
    return const <String, Object?>{
      'date': '',
      'todaySessions': 0,
      'todayReviewed': 0,
      'todayRemembered': 0,
      'totalSessions': 0,
      'totalReviewed': 0,
      'totalRemembered': 0,
      'lastSessionTitle': '',
      'rememberedWords': <Object?>[],
      'weakWords': <Object?>[],
    };
  }

  void savePracticeDashboard(Map<String, Object?> data) {
    _database.setSetting('practiceDashboard', jsonEncode(data));
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
}

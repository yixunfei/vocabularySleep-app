import 'dart:convert';

import '../models/play_config.dart';
import 'database_service.dart';

class SettingsService {
  const SettingsService(this._database);

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

  String loadUiLanguage() => _database.getSetting('uiLanguage') ?? 'zh';

  void saveUiLanguage(String language) {
    _database.setSetting('uiLanguage', language);
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
}

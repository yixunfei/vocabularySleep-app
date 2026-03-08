import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/services/database_service.dart';
import 'package:vocabulary_sleep_app/src/services/settings_service.dart';
import 'package:vocabulary_sleep_app/src/services/wordbook_import_service.dart';

class _MemoryDatabaseService extends AppDatabaseService {
  _MemoryDatabaseService() : super(WordbookImportService());

  final Map<String, String> _settings = <String, String>{};

  @override
  String? getSetting(String key) => _settings[key];

  @override
  void setSetting(String key, String value) {
    _settings[key] = value;
  }
}

void main() {
  test('P1-2 test mode state persists through SettingsService', () {
    final database = _MemoryDatabaseService();
    final settings = SettingsService(database);

    expect(settings.loadTestModeState(), const <String, bool>{
      'enabled': false,
      'revealed': false,
      'hintRevealed': false,
    });

    settings.saveTestModeState(
      enabled: true,
      revealed: true,
      hintRevealed: false,
    );

    final restored = SettingsService(database).loadTestModeState();
    expect(restored, const <String, bool>{
      'enabled': true,
      'revealed': true,
      'hintRevealed': false,
    });
  });
}

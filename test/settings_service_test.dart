import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/app_home_tab.dart';
import 'package:vocabulary_sleep_app/src/models/focus_startup_tab.dart';
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

  test('startup page persists through SettingsService', () {
    final database = _MemoryDatabaseService();
    final settings = SettingsService(database);

    expect(settings.loadStartupPage(), AppHomeTab.play);

    settings.saveStartupPage(AppHomeTab.focus);

    final restored = SettingsService(database).loadStartupPage();
    expect(restored, AppHomeTab.focus);
  });

  test('focus startup section persists through SettingsService', () {
    final database = _MemoryDatabaseService();
    final settings = SettingsService(database);

    expect(settings.loadFocusStartupTab(), FocusStartupTab.todo);

    settings.saveFocusStartupTab(FocusStartupTab.timer);

    final restored = SettingsService(database).loadFocusStartupTab();
    expect(restored, FocusStartupTab.timer);
  });

  test('weather toggle persists through SettingsService', () {
    final database = _MemoryDatabaseService();
    final settings = SettingsService(database);

    expect(settings.loadWeatherEnabled(), isFalse);

    settings.saveWeatherEnabled(true);

    final restored = SettingsService(database).loadWeatherEnabled();
    expect(restored, isTrue);
  });

  test('startup todo prompt settings persist through SettingsService', () {
    final database = _MemoryDatabaseService();
    final settings = SettingsService(database);

    expect(settings.loadStartupTodoPromptEnabled(), isFalse);
    expect(settings.loadStartupTodoPromptSuppressedDate(), isNull);

    settings.saveStartupTodoPromptEnabled(true);
    settings.saveStartupTodoPromptSuppressedDate('2026-03-16');

    final restored = SettingsService(database);
    expect(restored.loadStartupTodoPromptEnabled(), isTrue);
    expect(restored.loadStartupTodoPromptSuppressedDate(), '2026-03-16');
  });

  test('remembered words persist through SettingsService', () {
    final database = _MemoryDatabaseService();
    final settings = SettingsService(database);

    expect(settings.loadRememberedWords(), isEmpty);

    settings.saveRememberedWords(<String>{'Alpha', 'beta'});

    final restored = SettingsService(database).loadRememberedWords();
    expect(restored, <String>{'alpha', 'beta'});
  });
}

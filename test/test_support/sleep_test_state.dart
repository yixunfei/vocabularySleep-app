import 'package:vocabulary_sleep_app/src/repositories/settings_store_repository.dart';
import 'package:vocabulary_sleep_app/src/repositories/sleep_repository.dart';
import 'package:vocabulary_sleep_app/src/services/database_service.dart';
import 'package:vocabulary_sleep_app/src/services/settings_service.dart';
import 'package:vocabulary_sleep_app/src/services/wordbook_import_service.dart';
import 'package:vocabulary_sleep_app/src/state/app_state.dart';

import 'app_state_test_doubles.dart';

class SleepTestSettings implements SettingsStoreRepository {
  final Map<String, String> values = {};
  String? failingKey;
  @override
  String? getSetting(String key) => values[key];
  @override
  void setSetting(String key, String value) {
    if (key == failingKey) throw StateError('storage unavailable');
    values[key] = value;
  }
}

AppState createSleepTestState(SleepTestSettings store) {
  final database = AppDatabaseService(WordbookImportService());
  final settings = SettingsService.fromRepository(store);
  return AppState(
    database: database,
    settings: settings,
    playback: TrackingPlaybackService(),
    ambient: StubAmbientService(),
    asr: StubAsrService(),
    focusService: StubFocusService(database, settings: settings),
    sleepRepository: SettingsStoreSleepRepository(store),
  );
}

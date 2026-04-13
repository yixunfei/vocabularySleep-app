import '../services/database_service.dart';

abstract class SettingsStoreRepository {
  String? getSetting(String key);

  void setSetting(String key, String value);
}

class DatabaseSettingsStoreRepository implements SettingsStoreRepository {
  const DatabaseSettingsStoreRepository(this._database);

  final AppDatabaseService _database;

  @override
  String? getSetting(String key) => _database.getSetting(key);

  @override
  void setSetting(String key, String value) => _database.setSetting(key, value);
}

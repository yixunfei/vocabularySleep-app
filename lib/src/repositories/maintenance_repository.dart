import '../services/database_service.dart';

abstract class MaintenanceRepository {
  Future<void> init();

  Future<void> resetUserData();

  Future<List<DatabaseBackupInfo>> listSafetyBackups({int limit});

  Future<void> deleteSafetyBackup(String backupPath);

  Future<String> getDefaultUserDataExportDirectoryPath();

  Future<void> restoreSafetyBackup(String backupPath);

  Future<String> createSafetyBackup({String reason});

  void dispose();
}

class DatabaseMaintenanceRepository implements MaintenanceRepository {
  DatabaseMaintenanceRepository(this._database);

  final AppDatabaseService _database;

  @override
  Future<void> init() => _database.init();

  @override
  Future<void> resetUserData() => _database.resetUserData();

  @override
  Future<List<DatabaseBackupInfo>> listSafetyBackups({int limit = 20}) {
    return _database.listSafetyBackups(limit: limit);
  }

  @override
  Future<void> deleteSafetyBackup(String backupPath) {
    return _database.deleteSafetyBackup(backupPath);
  }

  @override
  Future<String> getDefaultUserDataExportDirectoryPath() {
    return _database.getDefaultUserDataExportDirectoryPath();
  }

  @override
  Future<void> restoreSafetyBackup(String backupPath) {
    return _database.restoreSafetyBackup(backupPath);
  }

  @override
  Future<String> createSafetyBackup({String reason = 'manual'}) {
    return _database.createSafetyBackup(reason: reason);
  }

  @override
  void dispose() => _database.dispose();
}

import '../services/database_service.dart';

abstract class AmbientRepository {
  List<DownloadedAmbientSoundInfo> getDownloadedAmbientSounds();

  void insertDownloadedAmbientSound({
    required String soundId,
    required String remoteKey,
    required String relativePath,
    required String categoryKey,
    required String name,
    required String filePath,
  });

  void deleteDownloadedAmbientSound(String soundId);

  void updateDownloadedAmbientSoundAccess(String soundId);
}

class DatabaseAmbientRepository implements AmbientRepository {
  const DatabaseAmbientRepository(this._database);

  final AppDatabaseService _database;

  @override
  List<DownloadedAmbientSoundInfo> getDownloadedAmbientSounds() {
    return _database.getDownloadedAmbientSounds();
  }

  @override
  void insertDownloadedAmbientSound({
    required String soundId,
    required String remoteKey,
    required String relativePath,
    required String categoryKey,
    required String name,
    required String filePath,
  }) {
    _database.insertDownloadedAmbientSound(
      soundId: soundId,
      remoteKey: remoteKey,
      relativePath: relativePath,
      categoryKey: categoryKey,
      name: name,
      filePath: filePath,
    );
  }

  @override
  void deleteDownloadedAmbientSound(String soundId) {
    _database.deleteDownloadedAmbientSound(soundId);
  }

  @override
  void updateDownloadedAmbientSoundAccess(String soundId) {
    _database.updateDownloadedAmbientSoundAccess(soundId);
  }
}

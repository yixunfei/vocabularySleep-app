part of 'app_state.dart';

extension AppStateExportDomain on AppState {
  Future<List<DatabaseBackupInfo>> listDatabaseBackups() {
    return _maintenanceRepository.listSafetyBackups();
  }

  Future<bool> deleteDatabaseBackup(DatabaseBackupInfo backup) async {
    try {
      await _maintenanceRepository.deleteSafetyBackup(backup.path);
      if (_lastBackupPath == backup.path) {
        _lastBackupPath = null;
      }
      _notifyStateChanged();
      return true;
    } catch (error, stackTrace) {
      _log.e(
        'app_state',
        'delete backup failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'path': backup.path},
      );
      _setMessage(
        'errorInitFailed',
        params: <String, Object?>{'error': 'delete backup: $error'},
      );
      _notifyStateChanged();
      return false;
    }
  }

  Future<String> getDefaultUserDataExportDirectoryPath() async {
    return _maintenanceRepository.getDefaultUserDataExportDirectoryPath();
  }

  Future<String?> exportUserData({
    Iterable<UserDataExportSection>? sections,
    String? directoryPath,
    String? fileName,
  }) async {
    _setMessage('processing');
    return null;
  }

  Future<bool> restoreUserDataExport(String filePath) async {
    _setMessage('processing');
    return false;
  }

  PracticeReviewExportPayload buildPracticeReviewExportPayload({
    Iterable<PracticeSessionRecord>? records,
    Iterable<WordEntry>? wrongNotebookEntries,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) => _buildPracticeReviewExportPayloadImpl(
    records: records,
    wrongNotebookEntries: wrongNotebookEntries,
    metadata: metadata,
  );

  Future<String?> exportPracticeReviewData({
    required PracticeExportFormat format,
    String? directoryPath,
    String? fileName,
    Iterable<PracticeSessionRecord>? records,
    Iterable<WordEntry>? wrongNotebookEntries,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) => _exportPracticeReviewDataImpl(
    format: format,
    directoryPath: directoryPath,
    fileName: fileName,
    records: records,
    wrongNotebookEntries: wrongNotebookEntries,
    metadata: metadata,
  );

  PracticeWrongNotebookExportPayload buildPracticeWrongNotebookExportPayload({
    required Iterable<WordEntry> entries,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) => _buildPracticeWrongNotebookExportPayloadImpl(
    entries: entries,
    metadata: metadata,
  );

  Future<String?> exportPracticeWrongNotebookData({
    required Iterable<WordEntry> entries,
    required PracticeExportFormat format,
    String? directoryPath,
    String? fileName,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) => _exportPracticeWrongNotebookDataImpl(
    entries: entries,
    format: format,
    directoryPath: directoryPath,
    fileName: fileName,
    metadata: metadata,
  );

  Future<bool> restoreDatabaseBackup(DatabaseBackupInfo backup) async {
    _setBusy(
      true,
      messageKey: 'busyRestoringBackup',
      params: <String, Object?>{'name': backup.name},
    );
    try {
      await _createSafetyBackup(reason: 'before_restore');
      await stop();
      _focusService.stop(saveProgress: false);
      await _ambient.stopAll();
      await _maintenanceRepository.restoreSafetyBackup(backup.path);
      _message = null;
      _messageParams = const <String, Object?>{};
      await _reloadPersistentStateAfterDatabaseChange();
      _notifyStateChanged();
      return true;
    } catch (error, stackTrace) {
      _log.e(
        'app_state',
        'restore backup failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'path': backup.path},
      );
      _setMessage(
        'errorInitFailed',
        params: <String, Object?>{'error': 'restore backup: $error'},
      );
      _notifyStateChanged();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _createSafetyBackup({required String reason}) async {
    try {
      _lastBackupPath = await _maintenanceRepository.createSafetyBackup(
        reason: reason,
      );
    } catch (_) {
      _lastBackupPath = null;
    }
  }
}

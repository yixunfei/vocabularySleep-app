part of 'app_state.dart';

extension AppStateAmbientDomain on AppState {
  Future<void> saveAmbientPresetFromCurrentMix(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final entries = _ambient.sources
        .where((source) => source.enabled)
        .map(
          (source) => AmbientPresetEntry(
            sourceId: source.id,
            name: source.name,
            volume: source.volume,
            assetPath: source.assetPath,
            filePath: source.filePath,
            remoteUrl: source.remoteUrl,
            remoteKey: source.remoteKey,
            categoryKey: source.categoryKey,
            builtIn: source.isBuiltIn,
          ),
        )
        .toList(growable: false);
    if (entries.isEmpty) {
      return;
    }
    _ambientPresets = <AmbientPreset>[
      AmbientPreset(
        id: _uuid.v4(),
        name: trimmed,
        createdAt: DateTime.now(),
        masterVolume: _ambient.masterVolume,
        entries: entries,
      ),
      ..._ambientPresets,
    ];
    _settings.saveAmbientPresets(_ambientPresets);
    _notifyStateChanged();
  }

  Future<void> deleteAmbientPreset(String presetId) async {
    final filtered = _ambientPresets
        .where((preset) => preset.id != presetId)
        .toList(growable: false);
    if (filtered.length == _ambientPresets.length) {
      return;
    }
    _ambientPresets = filtered;
    _settings.saveAmbientPresets(_ambientPresets);
    _notifyStateChanged();
  }

  Future<void> applyAmbientPreset(String presetId) async {
    final preset = _ambientPresets
        .where((item) => item.id == presetId)
        .cast<AmbientPreset?>()
        .firstOrNull;
    if (preset == null) {
      return;
    }

    for (final entry in preset.entries) {
      final existing = _ambient.sources
          .where((source) => _ambientSourceMatchesPreset(source, entry))
          .cast<AmbientSource?>()
          .firstOrNull;
      if (existing != null) {
        continue;
      }
      if (_canMaterializeAmbientPresetEntry(entry)) {
        _ambient.addFileSourceWithMetadata(
          entry.filePath!,
          id: entry.sourceId,
          name: entry.name,
          categoryKey: entry.categoryKey,
          volume: entry.volume,
        );
      }
    }

    for (final source in _ambient.sources) {
      final matchingEntry = preset.entries
          .where((entry) => _ambientSourceMatchesPreset(source, entry))
          .cast<AmbientPresetEntry?>()
          .firstOrNull;
      if (matchingEntry != null) {
        _ambient.setSourceEnabled(source.id, true);
        _ambient.setSourceVolume(source.id, matchingEntry.volume);
      } else {
        _ambient.setSourceEnabled(source.id, false);
      }
    }

    _ambient.setEnabled(true);
    _ambient.setMasterVolume(preset.masterVolume);
    _scheduleAmbientSync();
    _notifyStateChanged();
  }

  Future<void> setAmbientMasterVolume(double value) async {
    _ambient.setMasterVolume(value);
    _scheduleAmbientSync();
    _notifyStateChanged();
  }

  Future<void> setAmbientEnabled(bool value) async {
    _ambient.setEnabled(value);
    _scheduleAmbientSync();
    _notifyStateChanged();
  }

  Future<void> setAmbientSourceEnabled(String sourceId, bool enabled) async {
    _ambient.setSourceEnabled(sourceId, enabled);
    _scheduleAmbientSync();
    _notifyStateChanged();
  }

  Future<void> setAmbientSourceVolume(String sourceId, double value) async {
    _ambient.setSourceVolume(sourceId, value);
    _scheduleAmbientSync();
    _notifyStateChanged();
  }

  Future<void> addAmbientFileSource() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: <String>['mp3', 'wav', 'ogg', 'm4a', 'flac'],
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    if (file.path == null || file.path!.trim().isEmpty) return;

    _ambient.addFileSource(file.path!, name: file.name);
    _scheduleAmbientSync();
    _notifyStateChanged();
  }

  Future<List<OnlineAmbientSoundOption>> fetchOnlineAmbientCatalog({
    bool forceRefresh = false,
  }) {
    return _onlineAmbientCatalogService.fetchCatalog(
      forceRefresh: forceRefresh,
    );
  }

  Future<Set<String>> fetchDownloadedOnlineAmbientRelativePaths() {
    return _onlineAmbientCatalogService.listDownloadedRelativePaths();
  }

  Future<String?> downloadOnlineAmbientSource(
    OnlineAmbientSoundOption option,
  ) async {
    return downloadOnlineAmbientSourceWithProgress(option, null);
  }

  Future<String?> downloadOnlineAmbientSourceWithProgress(
    OnlineAmbientSoundOption option,
    void Function(ResourceDownloadProgress progress)? onProgress,
  ) async {
    try {
      final path = await _onlineAmbientCatalogService
          .downloadToLocalWithProgress(option, onProgress);
      _ambient.addFileSourceWithMetadata(
        path,
        id: 'downloaded_${option.id}',
        name: option.name,
        categoryKey: option.categoryKey,
        volume: option.defaultVolume,
      );
      _ambientRepository.insertDownloadedAmbientSound(
        soundId: option.id,
        remoteKey: option.remoteKey,
        relativePath: option.relativePath,
        categoryKey: option.categoryKey,
        name: option.name,
        filePath: path,
      );
      _scheduleAmbientSync();
      _notifyStateChanged();
      return path;
    } catch (error, stackTrace) {
      _log.e(
        'app_state',
        'download online ambient failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'id': option.id,
          'name': option.name,
          'remoteKey': option.remoteKey,
        },
      );
      return null;
    }
  }

  Future<bool> deleteDownloadedOnlineAmbientSource(
    OnlineAmbientSoundOption option,
  ) async {
    try {
      final path = await _onlineAmbientCatalogService.localPathFor(option);
      await _onlineAmbientCatalogService.deleteLocal(option);
      _ambientRepository.deleteDownloadedAmbientSound(option.id);
      final matchingIds = _ambient.sources
          .where(
            (source) =>
                source.id == 'downloaded_${option.id}' ||
                (source.filePath?.trim() ?? '') == path.trim(),
          )
          .map((source) => source.id)
          .toList(growable: false);
      for (final sourceId in matchingIds) {
        _ambient.removeSource(sourceId);
      }
      _scheduleAmbientSync();
      _notifyStateChanged();
      return true;
    } catch (error, stackTrace) {
      _log.e(
        'app_state',
        'delete downloaded ambient failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'id': option.id,
          'name': option.name,
          'relativePath': option.relativePath,
        },
      );
      return false;
    }
  }

  bool _ambientSourceMatchesPreset(
    AmbientSource source,
    AmbientPresetEntry entry,
  ) {
    if (source.id == entry.sourceId) {
      return true;
    }
    final sourceFilePath = source.filePath?.trim();
    final entryFilePath = entry.filePath?.trim();
    if (sourceFilePath != null &&
        sourceFilePath.isNotEmpty &&
        sourceFilePath == entryFilePath) {
      return true;
    }
    final sourceAssetPath = source.assetPath?.trim();
    final entryAssetPath = entry.assetPath?.trim();
    if (sourceAssetPath != null &&
        sourceAssetPath.isNotEmpty &&
        sourceAssetPath == entryAssetPath) {
      return true;
    }
    final sourceRemoteUrl = source.remoteUrl?.trim();
    final entryRemoteUrl = entry.remoteUrl?.trim();
    return sourceRemoteUrl != null &&
        sourceRemoteUrl.isNotEmpty &&
        sourceRemoteUrl == entryRemoteUrl;
  }

  bool _canMaterializeAmbientPresetEntry(AmbientPresetEntry entry) {
    final path = entry.filePath?.trim();
    return path != null && path.isNotEmpty && File(path).existsSync();
  }

  Future<String?> pickBackgroundImageByPicker() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final file = picked.files.first;
    final path = file.path;
    if (path == null || path.trim().isEmpty) return null;
    return path;
  }

  Future<void> removeAmbientSource(String sourceId) async {
    _ambient.removeSource(sourceId);
    _scheduleAmbientSync();
    _notifyStateChanged();
  }

  /// Schedule a debounced ambient sync playback to avoid race conditions
  /// from multiple rapid state changes. This consolidates multiple rapid
  /// ambient state changes into a single sync call.
  void _scheduleAmbientSync() {
    _ambientSyncDebounceTimer?.cancel();
    _ambientSyncDebounceTimer = Timer(
      const Duration(milliseconds: 200),
      () async {
        await _ambient.syncPlayback();
      },
    );
  }

  /// Restore downloaded ambient sounds from database on app startup
  Future<void> _restoreDownloadedAmbientSounds() async {
    try {
      final downloadedSounds = _ambientRepository.getDownloadedAmbientSounds();
      for (final sound in downloadedSounds) {
        final file = File(sound.filePath);
        if (await file.exists()) {
          _ambient.addFileSourceWithMetadata(
            sound.filePath,
            id: 'downloaded_${sound.soundId}',
            name: sound.name,
            categoryKey: sound.categoryKey,
            volume: 0.5,
            enabled: false,
          );
          _ambientRepository.updateDownloadedAmbientSoundAccess(sound.soundId);
        } else {
          _ambientRepository.deleteDownloadedAmbientSound(sound.soundId);
        }
      }
      if (downloadedSounds.isNotEmpty) {
        _scheduleAmbientSync();
      }
    } catch (error, stackTrace) {
      _log.e(
        'app_state',
        'restore downloaded ambient sounds failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

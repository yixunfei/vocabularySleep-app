part of 'tts_service.dart';

extension TtsServiceCore on TtsService {
  Future<List<String>> getLocalVoices() async {
    final voices = await _loadLocalVoiceOptions();
    final names = <String>{};
    for (final voice in voices) {
      if (voice.name.isNotEmpty) {
        names.add(voice.name);
      }
    }
    final output = names.toList()..sort();
    return output;
  }

  Future<int> getApiCacheSizeBytes() async {
    final dir = await _getApiCacheDirectory();
    return _computeDirectoryBytes(dir);
  }

  Future<void> clearApiCache() async {
    final dir = await _getApiCacheDirectory();
    if (!await dir.exists()) {
      return;
    }
    await for (final entity in dir.list()) {
      if (entity is File) {
        await _runOp<void>(
          'api.cache.delete',
          () => entity.delete(),
          data: <String, Object?>{'path': entity.path},
          swallowError: true,
        );
      }
    }
  }

  Future<void> speak(
    String text,
    TtsConfig config, {
    bool preCacheOnly = false,
  }) async {
    final content = text.trim();
    if (content.isEmpty) return;
    try {
      if (config.provider == TtsProviderType.local) {
        // No pre-cache needed for local TTS
        if (!preCacheOnly) {
          await _speakByLocal(content, config);
        }
      } else {
        await _speakByApi(content, config, preCacheOnly: preCacheOnly);
      }
    } catch (error, stackTrace) {
      if (error is _ApiSpeakInterrupted) {
        return;
      }
      _log.e(
        'tts',
        'speak failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'provider': config.provider.name,
          'textPreview': _preview(content),
          'preCacheOnly': preCacheOnly,
        },
      );
      rethrow;
    }
  }

  Future<void> stop() async {
    _interruptApiRequest(reason: 'stop');
    await _runOp<dynamic>(
      'local.stop',
      () => _flutterTts.stop(),
      swallowError: true,
    );
    await _runOp<void>('api.stop', () => _apiPlayer.stop(), swallowError: true);
    _completeLocalSpeak();
    _completeApiSpeak(error: const _ApiSpeakInterrupted('stop'));
  }

  Future<void> pause(TtsProviderType provider) async {
    if (provider != TtsProviderType.local) {
      await _runOp<void>(
        'api.pause',
        () => _apiPlayer.pause(),
        swallowError: true,
      );
      return;
    }
    await _runOp<dynamic>(
      'local.pause(stop)',
      () => _flutterTts.stop(),
      swallowError: true,
    );
    _completeLocalSpeak();
  }

  Future<void> resume(TtsProviderType provider) async {
    if (provider != TtsProviderType.local) {
      await _runOp<void>(
        'api.resume',
        () => _apiPlayer.resume(),
        swallowError: true,
      );
      return;
    }
    // Local resume is handled by PlaybackService replaying current unit.
  }
}

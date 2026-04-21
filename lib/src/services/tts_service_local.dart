part of 'tts_service.dart';

extension TtsServiceLocal on TtsService {
  Future<void> _ensureLocalInitialized() async {
    if (_localInitialized) return;
    // Keep platform speak() returning immediately and coordinate completion in
    // Dart via callbacks, with Windows-specific polling only as a fallback.
    await _runOp<dynamic>(
      'local.awaitSpeakCompletion',
      () => _flutterTts.awaitSpeakCompletion(false),
      swallowError: true,
    );
    await _configureLocalAudioSession();
    _localInitialized = true;
  }

  Future<void> _configureLocalAudioSession() async {
    if (_localAudioConfigured) {
      return;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _runOp<void>(
        'local.setAudioAttributesForNavigation',
        () => _flutterTts.setAudioAttributesForNavigation(),
        swallowError: true,
      );
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _runOp<dynamic>(
        'local.setSharedInstance',
        () => _flutterTts.setSharedInstance(true),
        swallowError: true,
      );
      await _runOp<dynamic>(
        'local.setIosAudioCategory',
        () => _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          <IosTextToSpeechAudioCategoryOptions>[
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.spokenAudio,
        ),
        swallowError: true,
      );
    }

    _localAudioConfigured = true;
  }

  Future<void> _speakByLocal(String text, TtsConfig config) async {
    _log.i(
      'tts',
      'speakByLocal: BEGIN',
      data: <String, Object?>{
        'textPreview': _preview(text),
        'textLength': text.length,
        'language': config.language,
        'localVoice': config.localVoice,
        'speed': config.speed,
        'volume': config.volume,
        'platform': defaultTargetPlatform.toString(),
      },
    );
    await _ensureLocalInitialized();
    _interruptApiRequest(reason: 'switch_to_local');
    await _runOp<void>(
      'api.stop.beforeLocal',
      () => _apiPlayer.stop(),
      swallowError: true,
    );
    if (_localCompletionCompleter != null) {
      await _runOp<dynamic>(
        'local.stop.overlap',
        () => _flutterTts.stop(),
        swallowError: true,
      );
      _completeLocalSpeak();
    }

    await _runOp<dynamic>(
      'local.setSpeechRate',
      () => _flutterTts.setSpeechRate(config.speed.clamp(0.1, 2.0)),
      data: <String, Object?>{'value': config.speed.clamp(0.1, 2.0)},
      swallowError: true,
    );
    await _runOp<dynamic>(
      'local.setVolume',
      () => _flutterTts.setVolume(config.volume.clamp(0.0, 1.0)),
      data: <String, Object?>{'value': config.volume.clamp(0.0, 1.0)},
      swallowError: true,
    );
    await _runOp<dynamic>(
      'local.setPitch',
      () => _flutterTts.setPitch(1.0),
      data: const <String, Object?>{'value': 1.0},
      swallowError: true,
    );

    await _configureLocalVoiceAndLanguage(text, config);
    _log.i(
      'tts',
      'speakByLocal: voice/language configured',
      data: <String, Object?>{
        'textPreview': _preview(text),
        'lastLocalLanguage': _lastLocalLanguage,
        'lastLocalVoiceSignature': _lastLocalVoiceSignature,
      },
    );

    final completer = Completer<void>();
    _localCompletionCompleter = completer;

    // On Windows, prefer completion callbacks and keep polling as a fallback.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      _log.i(
        'tts',
        'local speak [win]: invoking platform speak',
        data: <String, Object?>{'textPreview': _preview(text)},
      );
      final result = await _runOp<dynamic>(
        'local.speak',
        () => _flutterTts.speak(text, focus: false),
        data: <String, Object?>{'textPreview': _preview(text)},
      );
      _log.i(
        'tts',
        'local speak [win]: platform returned',
        data: <String, Object?>{
          'textPreview': _preview(text),
          'result': '$result',
          'success': _isPlatformCallSuccess(result),
        },
      );
      if (!_isPlatformCallSuccess(result)) {
        _completeLocalSpeak(error: StateError('Local TTS failed to start.'));
        throw StateError('Local TTS failed to start.');
      }
      final pollFuture = _pollWindowsSpeakDone(text, completer);
      try {
        await _awaitLocalCompletion(
          completer,
          text,
          timeout: const Duration(seconds: 40),
        );
      } finally {
        await pollFuture;
      }
      return;
    }

    final requestFocus =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    _log.i(
      'tts',
      'local speak: invoking platform',
      data: <String, Object?>{
        'textPreview': _preview(text),
        'language': config.language,
        'localVoice': config.localVoice,
      },
    );
    final result = await _runOp<dynamic>(
      'local.speak',
      () => _flutterTts.speak(text, focus: requestFocus),
      data: <String, Object?>{'textPreview': _preview(text)},
    );
    _log.i(
      'tts',
      'local speak: platform returned',
      data: <String, Object?>{
        'textPreview': _preview(text),
        'result': '$result',
        'success': _isPlatformCallSuccess(result),
      },
    );
    if (!_isPlatformCallSuccess(result)) {
      _completeLocalSpeak(error: StateError('Local TTS failed to start.'));
      throw StateError('Local TTS failed to start.');
    }
    await _awaitLocalCompletion(
      completer,
      text,
      timeout: const Duration(seconds: 40),
    );
  }

  /// Windows-only: poll SAPI engine speaking status directly.
  /// Completion callbacks remain the primary signal; polling only fills the
  /// gap if the callback is delayed or lost.
  Future<void> _pollWindowsSpeakDone(
    String text,
    Completer<void> completion,
  ) async {
    const pollInterval = Duration(milliseconds: 80);
    const maxWait = Duration(seconds: 30);
    const maxConsecutiveErrors = 10;
    final stopwatch = Stopwatch()..start();

    // Initial delay: let SAPI begin rendering audio.
    _log.i(
      'tts',
      'pollWindowsSpeakDone: START (200ms initial delay)',
      data: <String, Object?>{'textPreview': _preview(text)},
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));

    var pollCount = 0;
    var consecutiveErrors = 0;
    while (!completion.isCompleted && stopwatch.elapsed < maxWait) {
      pollCount++;
      try {
        final dynamic stillRaw = await _flutterTts.isSpeaking;
        bool still;
        if (stillRaw is bool) {
          still = stillRaw;
        } else if (stillRaw is int) {
          still = stillRaw == 1;
        } else {
          throw StateError(
            'Unexpected isSpeaking type: ${stillRaw.runtimeType}',
          );
        }

        consecutiveErrors = 0; // Reset error count on success

        if (pollCount <= 5 || pollCount % 10 == 0) {
          _log.i(
            'tts',
            'pollWindowsSpeakDone: poll #$pollCount',
            data: <String, Object?>{
              'textPreview': _preview(text),
              'isSpeaking': still,
              'elapsedMs': stopwatch.elapsedMilliseconds,
            },
          );
        }
        if (!still) {
          _completeLocalSpeak();
          _log.i(
            'tts',
            'pollWindowsSpeakDone: DONE (poll #$pollCount)',
            data: <String, Object?>{
              'textPreview': _preview(text),
              'elapsedMs': stopwatch.elapsedMilliseconds,
            },
          );
          return;
        }
      } catch (e) {
        consecutiveErrors++;
        _log.w(
          'tts',
          'pollWindowsSpeakDone: poll error (consecutive: $consecutiveErrors)',
          data: <String, Object?>{
            'textPreview': _preview(text),
            'error': '$e',
            'pollCount': pollCount,
          },
        );

        // If too many consecutive errors, assume playback is done
        if (consecutiveErrors >= maxConsecutiveErrors) {
          _log.e(
            'tts',
            'pollWindowsSpeakDone: Too many consecutive errors, forcing completion',
            data: <String, Object?>{
              'textPreview': _preview(text),
              'errorCount': consecutiveErrors,
            },
          );
          await _runOp<dynamic>(
            'local.stop.consecutive_errors',
            () => _flutterTts.stop(),
            swallowError: true,
          );
          _completeLocalSpeak(
            error: StateError(
              'Windows local TTS status polling failed repeatedly.',
            ),
          );
          return;
        }
      }
      await Future<void>.delayed(pollInterval);
    }
    if (completion.isCompleted) {
      _log.i(
        'tts',
        'pollWindowsSpeakDone: completion already resolved by callback',
        data: <String, Object?>{
          'textPreview': _preview(text),
          'pollCount': pollCount,
          'elapsedMs': stopwatch.elapsedMilliseconds,
        },
      );
      return;
    }
    _log.e(
      'tts',
      'pollWindowsSpeakDone: TIMEOUT after $pollCount polls',
      data: <String, Object?>{'textPreview': _preview(text)},
    );
    _completeLocalSpeak(
      error: TimeoutException('Windows local TTS playback timeout.'),
    );
    unawaited(
      _runOp<dynamic>(
        'local.stop.pollTimeout',
        () => _flutterTts.stop(),
        swallowError: true,
      ),
    );
  }

  Future<void> _awaitLocalCompletion(
    Completer<void> completer,
    String text, {
    required Duration timeout,
  }) async {
    _log.i(
      'tts',
      'local speak: waiting for completion',
      data: <String, Object?>{
        'textPreview': _preview(text),
        'platform': defaultTargetPlatform.toString(),
      },
    );
    await completer.future.timeout(
      timeout,
      onTimeout: () {
        _log.e(
          'tts',
          'local speak timeout',
          data: <String, Object?>{'textPreview': _preview(text)},
        );
        _completeLocalSpeak(
          error: TimeoutException('Local TTS playback timeout.'),
        );
        unawaited(
          _runOp<dynamic>(
            'local.stop.timeout',
            () => _flutterTts.stop(),
            swallowError: true,
          ),
        );
        throw TimeoutException('Local TTS playback timeout.');
      },
    );
    _log.i(
      'tts',
      'local speak: completion resolved',
      data: <String, Object?>{'textPreview': _preview(text)},
    );
  }

  String? _normalizeLanguage(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value.toLowerCase() == 'auto') return null;
    final tag = value.replaceAll('_', '-').toLowerCase();
    if (tag == 'en') return 'en-US';
    if (tag == 'zh') return 'zh-CN';
    if (tag == 'ja') return 'ja-JP';
    if (tag == 'fr') return 'fr-FR';
    if (tag == 'de') return 'de-DE';
    if (tag == 'es') return 'es-ES';
    return value;
  }

  Future<void> _configureLocalVoiceAndLanguage(
    String text,
    TtsConfig config,
  ) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      await _configureWindowsLocalVoiceAndLanguage(text, config);
      return;
    }

    final language = _normalizeLanguage(config.language);
    if (language != null && language != _lastLocalLanguage) {
      final result = await _runOp<dynamic>(
        'local.setLanguage',
        () => _flutterTts.setLanguage(language),
        data: <String, Object?>{'value': language},
        swallowError: true,
      );
      if (_isPlatformCallSuccess(result)) {
        _lastLocalLanguage = language;
        _lastLocalVoiceSignature = 'lang:${_normalizedLocaleKey(language)}';
      }
    }

    final voice = config.localVoice.trim();
    if (voice.isNotEmpty) {
      final result = await _runOp<dynamic>(
        'local.setVoice',
        () => _flutterTts.setVoice(<String, String>{'name': voice}),
        data: <String, Object?>{'value': voice},
        swallowError: true,
      );
      if (_isPlatformCallSuccess(result)) {
        _lastLocalVoiceSignature = 'name:${voice.toLowerCase()}';
      }
    }
  }

  Future<void> _configureWindowsLocalVoiceAndLanguage(
    String text,
    TtsConfig config,
  ) async {
    final target = await _resolveWindowsLocalVoiceTarget(text, config);
    if (target == null) {
      return;
    }

    if (target.voice != null) {
      final voice = target.voice!;
      if (_lastLocalVoiceSignature == target.signature) {
        _lastLocalLanguage = voice.locale;
        return;
      }
      final result = await _runOp<dynamic>(
        'local.setVoice',
        () => _flutterTts.setVoice(voice.toPayload()),
        data: <String, Object?>{
          'value': voice.name,
          'locale': voice.locale,
          'reason': target.reason,
        },
        swallowError: true,
      );
      if (_isPlatformCallSuccess(result)) {
        _lastLocalVoiceSignature = target.signature;
        _lastLocalLanguage = voice.locale;
        _log.i(
          'tts',
          'windows local voice resolved',
          data: <String, Object?>{
            'voice': voice.name,
            'locale': voice.locale,
            'reason': target.reason,
            'textPreview': _preview(text),
          },
        );
        return;
      }
    }

    final language = target.language ?? target.voice?.locale;
    if (language == null || language == _lastLocalLanguage) {
      return;
    }
    final result = await _runOp<dynamic>(
      'local.setLanguage',
      () => _flutterTts.setLanguage(language),
      data: <String, Object?>{'value': language, 'reason': target.reason},
      swallowError: true,
    );
    if (_isPlatformCallSuccess(result)) {
      _lastLocalLanguage = language;
      _lastLocalVoiceSignature = 'lang:${_normalizedLocaleKey(language)}';
      _log.i(
        'tts',
        'windows local language fallback applied',
        data: <String, Object?>{
          'language': language,
          'reason': target.reason,
          'textPreview': _preview(text),
        },
      );
    }
  }

  Future<_ResolvedWindowsLocalVoiceTarget?> _resolveWindowsLocalVoiceTarget(
    String text,
    TtsConfig config,
  ) async {
    final preferredLanguage = _preferredWindowsLocalLanguage(text, config);
    final preferredVoiceName = config.localVoice.trim();
    final voices = await _loadLocalVoiceOptions();

    if (preferredVoiceName.isNotEmpty) {
      final matchedVoice = _pickVoiceByName(
        voices,
        preferredVoiceName,
        preferredLanguage: preferredLanguage,
      );
      if (matchedVoice != null) {
        return _ResolvedWindowsLocalVoiceTarget.voice(
          matchedVoice,
          reason: 'explicit_voice',
        );
      }
    }

    if (preferredLanguage != null) {
      final matchedByLanguage = _pickVoiceByLanguage(voices, preferredLanguage);
      if (matchedByLanguage != null) {
        return _ResolvedWindowsLocalVoiceTarget.voice(
          matchedByLanguage,
          reason: config.localVoice.trim().isEmpty
              ? 'auto_text_language'
              : 'explicit_language',
        );
      }
      return _ResolvedWindowsLocalVoiceTarget.language(
        preferredLanguage,
        reason: 'language_fallback',
      );
    }

    return null;
  }

  String? _preferredWindowsLocalLanguage(String text, TtsConfig config) {
    final configured = _normalizeLanguage(config.language);
    if (configured != null) {
      return configured;
    }
    return _inferWindowsTextLanguage(text);
  }

  String? _inferWindowsTextLanguage(String text) {
    var hanCount = 0;
    var kanaCount = 0;
    var latinCount = 0;

    for (final rune in text.runes) {
      if (_isKanaRune(rune)) {
        kanaCount += 1;
        continue;
      }
      if (_isHanRune(rune)) {
        hanCount += 1;
        continue;
      }
      if (_isLatinRune(rune)) {
        latinCount += 1;
      }
    }

    if (kanaCount > 0) {
      return 'ja-JP';
    }
    if (hanCount > 0 && hanCount >= latinCount) {
      return 'zh-CN';
    }
    if (latinCount > 0) {
      return 'en-US';
    }
    if (hanCount > 0) {
      return 'zh-CN';
    }
    return null;
  }

  Future<List<_LocalTtsVoice>> _loadLocalVoiceOptions() async {
    final cached = _cachedLocalVoices;
    if (cached != null) {
      return cached;
    }

    final pending = _localVoicesLoadFuture;
    if (pending != null) {
      return pending;
    }

    final future = _fetchLocalVoiceOptions();
    _localVoicesLoadFuture = future;
    try {
      final voices = await future;
      if (voices.isNotEmpty) {
        _cachedLocalVoices = voices;
      }
      return voices;
    } finally {
      if (identical(_localVoicesLoadFuture, future)) {
        _localVoicesLoadFuture = null;
      }
    }
  }

  Future<List<_LocalTtsVoice>> _fetchLocalVoiceOptions() async {
    final dynamic voicesRaw = await _runOp<dynamic>(
      'local.getVoices',
      () => _flutterTts.getVoices,
      swallowError: true,
    );
    if (voicesRaw is! List) {
      _log.w(
        'tts',
        'local.getVoices returned unexpected payload',
        data: <String, Object?>{
          'runtimeType': voicesRaw.runtimeType.toString(),
        },
      );
      return const <_LocalTtsVoice>[];
    }

    final unique = <String, _LocalTtsVoice>{};
    for (final rawVoice in voicesRaw) {
      final voice = _LocalTtsVoice.fromRaw(rawVoice);
      if (voice == null) {
        continue;
      }
      unique.putIfAbsent(voice.signature, () => voice);
    }

    final output = unique.values.toList()
      ..sort((left, right) {
        final localeCompare = left.localeKey.compareTo(right.localeKey);
        if (localeCompare != 0) {
          return localeCompare;
        }
        return left.name.toLowerCase().compareTo(right.name.toLowerCase());
      });
    return output;
  }

  _LocalTtsVoice? _pickVoiceByName(
    List<_LocalTtsVoice> voices,
    String preferredName, {
    String? preferredLanguage,
  }) {
    final nameKey = preferredName.trim().toLowerCase();
    if (nameKey.isEmpty) {
      return null;
    }
    final matches = voices
        .where(
          (voice) =>
              voice.name.toLowerCase() == nameKey &&
              voice.locale.trim().isNotEmpty,
        )
        .toList(growable: false);
    if (matches.isEmpty) {
      return null;
    }
    if (preferredLanguage != null) {
      final matchedByLanguage = _pickVoiceByLanguage(
        matches,
        preferredLanguage,
      );
      if (matchedByLanguage != null) {
        return matchedByLanguage;
      }
    }
    return matches.first;
  }

  _LocalTtsVoice? _pickVoiceByLanguage(
    List<_LocalTtsVoice> voices,
    String preferredLanguage,
  ) {
    if (voices.isEmpty) {
      return null;
    }
    final localeKey = _normalizedLocaleKey(preferredLanguage);
    for (final voice in voices) {
      if (voice.locale.trim().isEmpty) {
        continue;
      }
      if (voice.localeKey == localeKey) {
        return voice;
      }
    }
    final primaryLanguage = _primaryLanguageCode(preferredLanguage);
    for (final voice in voices) {
      if (voice.locale.trim().isEmpty) {
        continue;
      }
      if (voice.primaryLanguageCode == primaryLanguage) {
        return voice;
      }
    }
    return null;
  }

  bool _isPlatformCallSuccess(dynamic result) {
    if (result == null) return true;
    if (result is bool) return result;
    if (result is int) return result == 1;
    return true;
  }
}

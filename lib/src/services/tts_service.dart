import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/play_config.dart';
import 'audio_player_source_helper.dart';
import 'app_log_service.dart';

class TtsService {
  TtsService() {
    _flutterTts.setCompletionHandler(() {
      _log.i('tts', 'completionHandler fired');
      _completeLocalSpeak();
    });
    _flutterTts.setCancelHandler(() {
      _log.i('tts', 'cancelHandler fired');
      _completeLocalSpeak();
    });
    _flutterTts.setErrorHandler((message) {
      _log.e(
        'tts',
        'local error handler fired',
        data: <String, Object?>{'message': '$message'},
      );
      _completeLocalSpeak(error: StateError('Local TTS playback failed.'));
    });
    _flutterTts.setStartHandler(() {
      _log.i('tts', 'startHandler fired');
    });
  }

  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _apiPlayer = AudioPlayer();
  final AppLogService _log = AppLogService.instance;
  static const String _defaultApiEndpoint =
      'https://api.siliconflow.cn/v1/audio/speech';
  static const String _defaultApiModel = 'FunAudioLLM/CosyVoice2-0.5B';
  static const String _defaultApiVoice = 'alex';
  static const int _minApiCacheMb = 32;
  static const int _maxApiCacheMb = 2048;
  static final AudioContext _spokenAudioContext = AudioContext(
    android: const AudioContextAndroid(
      stayAwake: true,
      contentType: AndroidContentType.speech,
      usageType: AndroidUsageType.assistanceNavigationGuidance,
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const <AVAudioSessionOptions>{
        AVAudioSessionOptions.mixWithOthers,
      },
    ),
  );

  Completer<void>? _localCompletionCompleter;
  Completer<void>? _apiCompletionCompleter;
  int? _apiCompletionToken;
  http.Client? _activeApiClient;
  Directory? _apiCacheDirectory;
  bool _localInitialized = false;
  bool _localAudioConfigured = false;
  bool _apiAudioConfigured = false;
  List<_LocalTtsVoice>? _cachedLocalVoices;
  Future<List<_LocalTtsVoice>>? _localVoicesLoadFuture;
  String? _lastLocalLanguage;
  String? _lastLocalVoiceSignature;
  int _apiSpeakToken = 0;

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

  Future<void> _ensureApiAudioConfigured() async {
    if (_apiAudioConfigured) {
      return;
    }
    await _runOp<void>(
      'api.setAudioContext',
      () => _apiPlayer.setAudioContext(_spokenAudioContext),
      swallowError: true,
    );
    _apiAudioConfigured = true;
  }

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
    _completeApiSpeak(error: _ApiSpeakInterrupted('stop'));
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

  Future<void> _speakByApi(
    String text,
    TtsConfig config, {
    bool preCacheOnly = false,
  }) async {
    await _ensureApiAudioConfigured();
    final speakToken = ++_apiSpeakToken;
    final model = (config.model?.trim().isNotEmpty ?? false)
        ? config.model!.trim()
        : _defaultApiModel;
    final voice = config.remoteVoice.trim().isNotEmpty
        ? config.remoteVoice.trim()
        : _defaultApiVoice;
    final endpointPreview = config.provider == TtsProviderType.customApi
        ? (config.baseUrl?.trim().isEmpty ?? true)
              ? 'custom_api_missing_base_url'
              : _resolveApiEndpoint(config)
        : _defaultApiEndpoint;
    final cacheKey = _buildApiCacheKey(
      config: config,
      model: model,
      voice: voice,
      text: text,
    );
    final requestBody = <String, Object?>{
      'model': model,
      'input': text,
      'voice': '$model:$voice',
      'response_format': 'mp3',
      'speed': config.speed,
    };
    await _runOp<dynamic>(
      'local.stop.beforeApi',
      () => _flutterTts.stop(),
      swallowError: true,
    );
    await _runOp<void>(
      'api.stop.beforeApi',
      () => _apiPlayer.stop(),
      swallowError: true,
    );
    _activeApiClient?.close();

    final cachedFile = await _lookupApiCacheFile(cacheKey, config);
    if (cachedFile != null) {
      final cachedBytes = await _runOp<int>(
        'api.cache.length',
        () => cachedFile.length(),
        data: <String, Object?>{'path': cachedFile.path},
      );
      _throwIfApiInterrupted(speakToken, stage: 'before_cache_play');
      try {
        await _playApiSource(
          source: DeviceFileSource(cachedFile.path),
          config: config,
          speakToken: speakToken,
          bytes: cachedBytes ?? 0,
          sourceLabel: 'cache_file',
          endpoint: endpointPreview,
          model: model,
          voice: voice,
        );
        return;
      } catch (error, stackTrace) {
        if (error is _ApiSpeakInterrupted) {
          rethrow;
        }
        _log.w(
          'tts',
          'api cache playback failed, fallback to network',
          data: <String, Object?>{
            'path': cachedFile.path,
            'error': '$error',
            'stackTrace': '$stackTrace',
          },
        );
        await _runOp<void>(
          'api.cache.delete.invalid',
          () => cachedFile.delete(),
          data: <String, Object?>{'path': cachedFile.path},
          swallowError: true,
        );
      }
    }

    final apiKey = config.apiKey?.trim() ?? '';
    if (apiKey.isEmpty) {
      throw StateError('TTS API key is missing.');
    }
    if (config.provider == TtsProviderType.customApi &&
        (config.baseUrl == null || config.baseUrl!.trim().isEmpty)) {
      throw StateError('Custom API base URL is missing.');
    }

    final endpoint = _resolveApiEndpoint(config);
    final client = http.Client();
    _activeApiClient = client;

    final response = await _postApiSpeech(
      client: client,
      endpoint: endpoint,
      apiKey: apiKey,
      requestBody: requestBody,
      config: config,
      model: model,
      voice: voice,
      speakToken: speakToken,
    );
    _throwIfApiInterrupted(speakToken, stage: 'after_http');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'TTS API request failed: ${response.statusCode}, body=${_preview(response.body)}',
      );
    }
    final contentType = (response.headers['content-type'] ?? '')
        .toLowerCase()
        .trim();
    if (contentType.contains('application/json') ||
        contentType.contains('text/plain')) {
      throw StateError(
        'TTS API returned non-audio content-type: $contentType, body=${_preview(response.body)}',
      );
    }

    final audioBytes = response.bodyBytes;
    final cacheFile = await _writeApiCacheFile(
      cacheKey: cacheKey,
      bytes: audioBytes,
      config: config,
    );
    _throwIfApiInterrupted(speakToken, stage: 'before_play');

    try {
      await _playApiSource(
        source: cacheFile != null
            ? DeviceFileSource(cacheFile.path)
            : BytesSource(audioBytes),
        config: config,
        speakToken: speakToken,
        bytes: audioBytes.length,
        sourceLabel: cacheFile != null
            ? 'network_cached_file'
            : 'network_bytes',
        endpoint: endpoint,
        model: model,
        voice: voice,
      );
    } finally {
      if (identical(_activeApiClient, client)) {
        _activeApiClient = null;
      }
      client.close();
    }
  }

  Future<void> _playApiSource({
    required Source source,
    required TtsConfig config,
    required int speakToken,
    required int bytes,
    required String sourceLabel,
    required String endpoint,
    required String model,
    required String voice,
  }) async {
    final completer = Completer<void>();
    _apiCompletionCompleter = completer;
    _apiCompletionToken = speakToken;
    late final StreamSubscription<void> sub;
    sub = _apiPlayer.onPlayerComplete.listen((_) {
      if (_apiCompletionToken != speakToken) return;
      _completeApiSpeak();
      sub.cancel();
    });

    await _runOp<void>(
      'api.player.play',
      () => AudioPlayerSourceHelper.play(
        _apiPlayer,
        source,
        volume: config.volume.clamp(0.0, 1.0),
        tag: 'tts_audio',
        data: <String, Object?>{
          'speakToken': speakToken,
          'source': sourceLabel,
        },
      ),
      data: <String, Object?>{
        'speakToken': speakToken,
        'bytes': bytes,
        'volume': config.volume.clamp(0.0, 1.0),
        'source': sourceLabel,
      },
    );

    try {
      await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          _log.e(
            'tts',
            'api playback timeout',
            data: <String, Object?>{
              'speakToken': speakToken,
              'provider': config.provider.name,
              'endpoint': endpoint,
              'model': model,
              'voice': voice,
              'source': sourceLabel,
            },
          );
          unawaited(
            _runOp<void>(
              'api.stop.timeout',
              () => _apiPlayer.stop(),
              swallowError: true,
            ),
          );
          throw TimeoutException('API TTS playback timeout.');
        },
      );
    } finally {
      await sub.cancel();
      if (_apiCompletionToken == speakToken) {
        _completeApiSpeak();
      }
    }
  }

  bool _shouldUseApiCache(TtsConfig config) =>
      config.provider != TtsProviderType.local && config.enableApiCache;

  String _buildApiCacheKey({
    required TtsConfig config,
    required String model,
    required String voice,
    required String text,
  }) {
    final payload = jsonEncode(<String, Object?>{
      'provider': config.provider.name,
      'baseUrl': config.baseUrl?.trim() ?? '',
      'model': model,
      'voice': voice,
      'speed': config.speed,
      'text': text,
    });
    return sha256.convert(utf8.encode(payload)).toString();
  }

  Future<File?> _lookupApiCacheFile(String cacheKey, TtsConfig config) async {
    if (!_shouldUseApiCache(config)) {
      return null;
    }
    final dir = await _getApiCacheDirectory();
    final file = File(path.join(dir.path, '$cacheKey.mp3'));
    final exists = await _runOp<bool>(
      'api.cache.exists',
      () => file.exists(),
      data: <String, Object?>{'path': file.path},
      swallowError: true,
    );
    if (exists != true) {
      return null;
    }
    await _touchApiCacheFile(file);
    return file;
  }

  Future<File?> _writeApiCacheFile({
    required String cacheKey,
    required List<int> bytes,
    required TtsConfig config,
  }) async {
    if (!_shouldUseApiCache(config) || bytes.isEmpty) {
      return null;
    }
    final dir = await _getApiCacheDirectory();
    final file = File(path.join(dir.path, '$cacheKey.mp3'));
    final written = await _runOp<File>(
      'api.cache.write',
      () async {
        await file.writeAsBytes(bytes, flush: true);
        return file;
      },
      data: <String, Object?>{'path': file.path, 'bytes': bytes.length},
      swallowError: true,
    );
    if (written == null) {
      return null;
    }
    await _touchApiCacheFile(written);
    await _trimApiCacheIfNeeded(_normalizedApiCacheMb(config.maxApiCacheMb));
    return written;
  }

  Future<void> _touchApiCacheFile(File file) async {
    await _runOp<void>(
      'api.cache.touch',
      () => file.setLastModified(DateTime.now()),
      data: <String, Object?>{'path': file.path},
      swallowError: true,
    );
  }

  Future<Directory> _getApiCacheDirectory() async {
    final cached = _apiCacheDirectory;
    if (cached != null) {
      if (!await cached.exists()) {
        await cached.create(recursive: true);
      }
      return cached;
    }

    final root = await getApplicationSupportDirectory();
    final dir = Directory(path.join(root.path, 'tts_api_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _apiCacheDirectory = dir;
    return dir;
  }

  int _normalizedApiCacheMb(int value) =>
      value.clamp(_minApiCacheMb, _maxApiCacheMb).toInt();

  Future<int> _computeDirectoryBytes(Directory dir) async {
    var totalBytes = 0;
    if (!await dir.exists()) {
      return totalBytes;
    }
    await for (final entity in dir.list()) {
      if (entity is! File) {
        continue;
      }
      final stat = await _runOp<FileStat>(
        'api.cache.stat',
        () => entity.stat(),
        data: <String, Object?>{'path': entity.path},
        swallowError: true,
      );
      if (stat == null || stat.type != FileSystemEntityType.file) {
        continue;
      }
      totalBytes += stat.size;
    }
    return totalBytes;
  }

  Future<void> _trimApiCacheIfNeeded(int maxCacheMb) async {
    final dir = await _getApiCacheDirectory();
    final files = <({File file, FileStat stat})>[];
    var totalBytes = 0;

    await for (final entity in dir.list()) {
      if (entity is! File) {
        continue;
      }
      final stat = await _runOp<FileStat>(
        'api.cache.stat',
        () => entity.stat(),
        data: <String, Object?>{'path': entity.path},
        swallowError: true,
      );
      if (stat == null || stat.type != FileSystemEntityType.file) {
        continue;
      }
      totalBytes += stat.size;
      files.add((file: entity, stat: stat));
    }

    final maxBytes = _normalizedApiCacheMb(maxCacheMb) * 1024 * 1024;
    if (totalBytes <= maxBytes) {
      return;
    }

    files.sort(
      (left, right) => left.stat.modified.compareTo(right.stat.modified),
    );
    final targetBytes = totalBytes ~/ 2;
    var remainingBytes = totalBytes;
    for (final item in files) {
      if (remainingBytes <= targetBytes) {
        break;
      }
      await _runOp<void>(
        'api.cache.delete.trim',
        () => item.file.delete(),
        data: <String, Object?>{
          'path': item.file.path,
          'bytes': item.stat.size,
        },
        swallowError: true,
      );
      remainingBytes -= item.stat.size;
    }
  }

  String _resolveApiEndpoint(TtsConfig config) {
    if (config.provider == TtsProviderType.customApi) {
      final value = config.baseUrl?.trim() ?? '';
      if (value.isNotEmpty) {
        var normalized = value.replaceAll(RegExp(r'/+$'), '');
        if (normalized.toLowerCase().contains('/audio/speech')) {
          return normalized;
        }
        if (normalized.toLowerCase().endsWith('/v1')) {
          return '$normalized/audio/speech';
        }
        normalized = normalized.replaceAll(RegExp(r'/+$'), '');
        return '$normalized/v1/audio/speech';
      }
    }
    return _defaultApiEndpoint;
  }

  void _completeLocalSpeak({Object? error}) {
    final completer = _localCompletionCompleter;
    if (completer == null) return;
    if (!completer.isCompleted) {
      if (error == null) {
        completer.complete();
      } else {
        completer.completeError(error);
      }
    }
    _localCompletionCompleter = null;
  }

  void _completeApiSpeak({Object? error}) {
    final completer = _apiCompletionCompleter;
    if (completer == null) return;
    if (!completer.isCompleted) {
      if (error == null) {
        completer.complete();
      } else {
        completer.completeError(error);
      }
    }
    _apiCompletionCompleter = null;
    _apiCompletionToken = null;
  }

  void _interruptApiRequest({required String reason}) {
    _apiSpeakToken += 1;
    final client = _activeApiClient;
    _activeApiClient = null;
    if (client != null) {
      client.close();
    }
  }

  void _throwIfApiInterrupted(int speakToken, {required String stage}) {
    if (speakToken == _apiSpeakToken) return;
    throw _ApiSpeakInterrupted(stage);
  }

  bool _isApiSpeakTokenActive(int speakToken) => speakToken == _apiSpeakToken;

  Future<http.Response> _postApiSpeech({
    required http.Client client,
    required String endpoint,
    required String apiKey,
    required Map<String, Object?> requestBody,
    required TtsConfig config,
    required String model,
    required String voice,
    required int speakToken,
  }) async {
    final watch = Stopwatch()..start();
    final data = <String, Object?>{
      'provider': config.provider.name,
      'endpoint': endpoint,
      'model': model,
      'voice': voice,
      'speed': config.speed,
      'speakToken': speakToken,
    };
    try {
      final response = await client
          .post(
            Uri.parse(endpoint),
            headers: <String, String>{
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));
      return response;
    } catch (error, stackTrace) {
      final interrupted = !_isApiSpeakTokenActive(speakToken);
      if (interrupted) {
        throw const _ApiSpeakInterrupted('http_post_interrupted');
      }
      _log.e(
        'tts',
        'api.http.post.failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          ...data,
          'elapsedMs': watch.elapsedMilliseconds,
        },
      );
      rethrow;
    }
  }

  Future<T?> _runOp<T>(
    String operation,
    Future<T> Function() task, {
    Map<String, Object?> data = const <String, Object?>{},
    bool swallowError = false,
  }) async {
    final watch = Stopwatch()..start();
    try {
      final result = await task();
      final resultValue = _encodeResultValue(result);
      return result;
    } catch (error, stackTrace) {
      if (swallowError) {
        _log.w(
          'tts',
          '$operation.failed(swallowed)',
          data: <String, Object?>{
            ...data,
            'elapsedMs': watch.elapsedMilliseconds,
            'error': '$error',
          },
        );
        return null;
      }
      _log.e(
        'tts',
        '$operation.failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          ...data,
          'elapsedMs': watch.elapsedMilliseconds,
        },
      );
      rethrow;
    }
  }

  Object? _encodeResultValue(Object? value) {
    if (value == null || value is num || value is bool || value is String) {
      return value;
    }
    return value.runtimeType.toString();
  }

  String _preview(String text) {
    final compact = text.replaceAll('\n', ' ').trim();
    if (compact.length <= 96) return compact;
    return '${compact.substring(0, 96)}...';
  }
}

class _ApiSpeakInterrupted implements Exception {
  const _ApiSpeakInterrupted(this.reason);

  final String reason;

  @override
  String toString() => 'ApiSpeakInterrupted($reason)';
}

class _LocalTtsVoice {
  const _LocalTtsVoice({required this.name, required this.locale});

  final String name;
  final String locale;

  String get localeKey => _normalizedLocaleKey(locale);
  String get primaryLanguageCode => _primaryLanguageCode(locale);
  String get signature => '$localeKey::${name.toLowerCase()}';

  Map<String, String> toPayload() => <String, String>{
    'name': name,
    'locale': locale,
  };

  static _LocalTtsVoice? fromRaw(dynamic raw) {
    if (raw is Map) {
      final name = raw['name']?.toString().trim() ?? '';
      final locale = raw['locale']?.toString().trim() ?? '';
      if (name.isEmpty) {
        return null;
      }
      return _LocalTtsVoice(name: name, locale: locale);
    }
    final name = '$raw'.trim();
    if (name.isEmpty) {
      return null;
    }
    return _LocalTtsVoice(name: name, locale: '');
  }
}

class _ResolvedWindowsLocalVoiceTarget {
  const _ResolvedWindowsLocalVoiceTarget._({
    required this.reason,
    this.voice,
    this.language,
  });

  final String reason;
  final _LocalTtsVoice? voice;
  final String? language;

  String get signature => voice != null
      ? 'voice:${voice!.signature}'
      : 'lang:${_normalizedLocaleKey(language ?? '')}';

  factory _ResolvedWindowsLocalVoiceTarget.voice(
    _LocalTtsVoice voice, {
    required String reason,
  }) {
    return _ResolvedWindowsLocalVoiceTarget._(reason: reason, voice: voice);
  }

  factory _ResolvedWindowsLocalVoiceTarget.language(
    String language, {
    required String reason,
  }) {
    return _ResolvedWindowsLocalVoiceTarget._(
      reason: reason,
      language: language,
    );
  }
}

String _normalizedLocaleKey(String raw) =>
    raw.trim().replaceAll('_', '-').toLowerCase();

String _primaryLanguageCode(String raw) {
  final key = _normalizedLocaleKey(raw);
  if (key.isEmpty) {
    return '';
  }
  final separator = key.indexOf('-');
  if (separator < 0) {
    return key;
  }
  return key.substring(0, separator);
}

bool _isHanRune(int rune) =>
    (rune >= 0x4E00 && rune <= 0x9FFF) ||
    (rune >= 0x3400 && rune <= 0x4DBF) ||
    (rune >= 0xF900 && rune <= 0xFAFF);

bool _isKanaRune(int rune) =>
    (rune >= 0x3040 && rune <= 0x309F) || (rune >= 0x30A0 && rune <= 0x30FF);

bool _isLatinRune(int rune) =>
    (rune >= 0x0041 && rune <= 0x005A) || (rune >= 0x0061 && rune <= 0x007A);

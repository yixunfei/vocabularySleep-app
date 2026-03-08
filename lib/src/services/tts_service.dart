import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

import '../models/play_config.dart';
import 'app_log_service.dart';

class TtsService {
  TtsService() {
    _flutterTts.setCompletionHandler(() {
      _log.d('tts', 'local completion handler fired');
      _completeLocalSpeak();
    });
    _flutterTts.setCancelHandler(() {
      _log.d('tts', 'local cancel handler fired');
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
    _log.i('tts', 'service initialized');
  }

  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _apiPlayer = AudioPlayer();
  final AppLogService _log = AppLogService.instance;
  static const String _defaultApiEndpoint =
      'https://api.siliconflow.cn/v1/audio/speech';
  static const String _defaultApiModel = 'FunAudioLLM/CosyVoice2-0.5B';
  static const String _defaultApiVoice = 'alex';

  Completer<void>? _localCompletionCompleter;
  Completer<void>? _apiCompletionCompleter;
  int? _apiCompletionToken;
  http.Client? _activeApiClient;
  bool _localInitialized = false;
  String? _lastLocalLanguage;
  int _apiSpeakToken = 0;

  Future<void> _ensureLocalInitialized() async {
    if (_localInitialized) return;
    await _runOp<dynamic>(
      'local.awaitSpeakCompletion',
      () => _flutterTts.awaitSpeakCompletion(true),
      swallowError: true,
    );
    _localInitialized = true;
    _log.d('tts', 'local initialized');
  }

  Future<List<String>> getLocalVoices() async {
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
      return const <String>[];
    }

    final names = <String>{};
    for (final voice in voicesRaw) {
      if (voice is Map) {
        final value = voice['name']?.toString() ?? '';
        if (value.isNotEmpty) names.add(value);
      } else {
        final value = '$voice'.trim();
        if (value.isNotEmpty) names.add(value);
      }
    }
    final output = names.toList()..sort();
    _log.i(
      'tts',
      'local voices loaded',
      data: <String, Object?>{
        'count': output.length,
        'sample': output.take(8).join(', '),
      },
    );
    return output;
  }

  Future<void> speak(String text, TtsConfig config) async {
    final content = text.trim();
    if (content.isEmpty) return;
    _log.i(
      'tts',
      'speak requested',
      data: <String, Object?>{
        'provider': config.provider.name,
        'endpoint': _resolveApiEndpoint(config),
        'model': config.model,
        'activeVoice': config.activeVoice,
        'localVoice': config.localVoice,
        'remoteVoice': config.remoteVoice,
        'baseUrl': config.baseUrl,
        'language': config.language,
        'speed': config.speed,
        'volume': config.volume,
        'textPreview': _preview(content),
      },
    );

    try {
      if (config.provider == TtsProviderType.local) {
        await _speakByLocal(content, config);
      } else {
        await _speakByApi(content, config);
      }
      _log.i('tts', 'speak finished');
    } catch (error, stackTrace) {
      if (error is _ApiSpeakInterrupted) {
        _log.i(
          'tts',
          'speak interrupted',
          data: <String, Object?>{
            'provider': config.provider.name,
            'reason': error.reason,
            'textPreview': _preview(content),
          },
        );
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
        },
      );
      rethrow;
    }
  }

  Future<void> stop() async {
    _log.i('tts', 'stop requested');
    _interruptApiRequest(reason: 'stop');
    await _runOp<dynamic>(
      'local.stop',
      () => _flutterTts.stop(),
      swallowError: true,
    );
    await _runOp<void>('api.stop', () => _apiPlayer.stop(), swallowError: true);
    _completeLocalSpeak();
    _completeApiSpeak(error: _ApiSpeakInterrupted('stop'));
    _log.d('tts', 'stop done');
  }

  Future<void> pause(TtsProviderType provider) async {
    _log.i(
      'tts',
      'pause requested',
      data: <String, Object?>{'provider': provider.name},
    );
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
    _log.i(
      'tts',
      'resume requested',
      data: <String, Object?>{'provider': provider.name},
    );
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

    final skipVoiceAndLanguageConfig =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    if (skipVoiceAndLanguageConfig) {
      _log.w(
        'tts',
        'windows safe mode enabled, skip setLanguage/setVoice',
        data: <String, Object?>{
          'language': config.language,
          'voice': config.localVoice,
        },
      );
    } else {
      final language = _normalizeLanguage(config.language);
      if (language != null && language != _lastLocalLanguage) {
        await _runOp<dynamic>(
          'local.setLanguage',
          () => _flutterTts.setLanguage(language),
          data: <String, Object?>{'value': language},
          swallowError: true,
        );
        _lastLocalLanguage = language;
      }

      final voice = config.localVoice.trim();
      if (voice.isNotEmpty) {
        await _runOp<dynamic>(
          'local.setVoice',
          () => _flutterTts.setVoice(<String, String>{'name': voice}),
          data: <String, Object?>{'value': voice},
          swallowError: true,
        );
      }
    }

    final completer = Completer<void>();
    _localCompletionCompleter = completer;
    final result = await _runOp<dynamic>(
      'local.speak',
      () => _flutterTts.speak(text),
      data: <String, Object?>{'textPreview': _preview(text)},
    );
    if (!_isSpeakResultSuccess(result)) {
      _localCompletionCompleter = null;
      throw StateError('Local TTS failed to start.');
    }

    await completer.future.timeout(
      const Duration(seconds: 40),
      onTimeout: () {
        _log.e(
          'tts',
          'local speak timeout',
          data: <String, Object?>{'textPreview': _preview(text)},
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

  bool _isSpeakResultSuccess(dynamic result) {
    if (result == null) return true;
    if (result is bool) return result;
    if (result is int) return result == 1;
    return true;
  }

  Future<void> _speakByApi(String text, TtsConfig config) async {
    final speakToken = ++_apiSpeakToken;
    final apiKey = config.apiKey?.trim() ?? '';
    if (apiKey.isEmpty) {
      throw StateError('TTS API key is missing.');
    }
    if (config.provider == TtsProviderType.customApi &&
        (config.baseUrl == null || config.baseUrl!.trim().isEmpty)) {
      throw StateError('Custom API base URL is missing.');
    }

    final endpoint = _resolveApiEndpoint(config);
    final model = (config.model?.trim().isNotEmpty ?? false)
        ? config.model!.trim()
        : _defaultApiModel;
    final voice = config.remoteVoice.trim().isNotEmpty
        ? config.remoteVoice.trim()
        : _defaultApiVoice;
    final requestBody = <String, Object?>{
      'model': model,
      'input': text,
      'voice': '$model:$voice',
      'response_format': 'mp3',
      'speed': config.speed,
    };
    _log.i(
      'tts',
      'api speak start',
      data: <String, Object?>{
        'speakToken': speakToken,
        'provider': config.provider.name,
        'endpoint': endpoint,
        'model': model,
        'voice': voice,
        'textPreview': _preview(text),
      },
    );

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

    _log.i(
      'tts',
      'api response',
      data: <String, Object?>{
        'speakToken': speakToken,
        'statusCode': response.statusCode,
        'bytes': response.bodyBytes.length,
        'contentType': response.headers['content-type'],
      },
    );
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
    _throwIfApiInterrupted(speakToken, stage: 'before_play');

    final completer = Completer<void>();
    _apiCompletionCompleter = completer;
    _apiCompletionToken = speakToken;
    late final StreamSubscription<void> sub;
    sub = _apiPlayer.onPlayerComplete.listen((_) {
      _log.d('tts', 'api playback completed');
      if (_apiCompletionToken != speakToken) return;
      _completeApiSpeak();
      sub.cancel();
    });

    await _runOp<void>(
      'api.player.play',
      () => _apiPlayer.play(
        BytesSource(response.bodyBytes),
        volume: config.volume.clamp(0.0, 1.0),
      ),
      data: <String, Object?>{
        'speakToken': speakToken,
        'bytes': response.bodyBytes.length,
        'volume': config.volume.clamp(0.0, 1.0),
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
      if (identical(_activeApiClient, client)) {
        _activeApiClient = null;
      }
      client.close();
      await sub.cancel();
      if (_apiCompletionToken == speakToken) {
        _completeApiSpeak();
      }
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
      _log.d(
        'tts',
        'api request interrupted',
        data: <String, Object?>{'reason': reason},
      );
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
    _log.d('tts', 'api.http.post.start', data: data);
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
      _log.d(
        'tts',
        'api.http.post.done',
        data: <String, Object?>{
          ...data,
          'elapsedMs': watch.elapsedMilliseconds,
          'result': response.runtimeType.toString(),
        },
      );
      return response;
    } catch (error, stackTrace) {
      final interrupted = !_isApiSpeakTokenActive(speakToken);
      if (interrupted) {
        _log.i(
          'tts',
          'api.http.post.interrupted',
          data: <String, Object?>{
            ...data,
            'elapsedMs': watch.elapsedMilliseconds,
            'error': '$error',
          },
        );
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
    _log.d('tts', '$operation.start', data: data);
    try {
      final result = await task();
      final resultValue = _encodeResultValue(result);
      _log.d(
        'tts',
        '$operation.done',
        data: <String, Object?>{
          ...data,
          'elapsedMs': watch.elapsedMilliseconds,
          ...?resultValue == null
              ? null
              : <String, Object?>{'result': resultValue},
        },
      );
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

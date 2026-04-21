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

part 'tts_service_core.dart';
part 'tts_service_local.dart';
part 'tts_service_api.dart';
part 'tts_service_utils.dart';

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
}

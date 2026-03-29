import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_log_service.dart';

class AudioPlayerSourceHelper {
  AudioPlayerSourceHelper._();

  static final AppLogService _log = AppLogService.instance;
  static final AudioplayersPlatformInterface _platform =
      AudioplayersPlatformInterface.instance;
  static final _AudioPlayerBytesTempStore _bytesTempStore =
      _AudioPlayerBytesTempStore();
  static final Expando<_AudioPlayerDiagnostics> _diagnostics =
      Expando<_AudioPlayerDiagnostics>('audio_player_diagnostics');
  static final Expando<String> _diagnosticTags = Expando<String>(
    'audio_player_diagnostic_tag',
  );

  static Future<void> setSource(
    AudioPlayer player,
    Source source, {
    required String tag,
    Map<String, Object?> data = const <String, Object?>{},
  }) async {
    _ensureDiagnostics(player, tag);
    _log.d(
      tag,
      'setSource start',
      data: <String, Object?>{
        'playerId': player.playerId,
        'sourceType': source.runtimeType.toString(),
        ...data,
      },
    );
    switch (source) {
      case DeviceFileSource():
        await _setLocalFile(
          player,
          source.path,
          mimeType: source.mimeType,
          tag: tag,
          data: data,
        );
      case AssetSource():
        final cachePath = await player.audioCache.loadPath(source.path);
        await _setLocalFile(
          player,
          cachePath,
          mimeType: source.mimeType,
          tag: tag,
          data: <String, Object?>{...data, 'assetPath': source.path},
        );
      case UrlSource():
        await _attemptStrategies(
          tag: tag,
          data: <String, Object?>{
            ...data,
            'url': source.url,
            'mimeType': source.mimeType,
          },
          strategies: <_AudioSourceAttempt>[
            _AudioSourceAttempt(
              label: 'url_source',
              run: () =>
                  player.setSourceUrl(source.url, mimeType: source.mimeType),
            ),
          ],
        );
      case BytesSource():
        final payload = <String, Object?>{
          ...data,
          'bytes': source.bytes.length,
          'mimeType': source.mimeType,
        };
        final preferTempFile = _shouldPreferTempFileForBytesSource;
        await _attemptStrategies(
          tag: tag,
          data: payload,
          strategies: <_AudioSourceAttempt>[
            if (preferTempFile)
              _AudioSourceAttempt(
                label: 'desktop_temp_file',
                run: () => _setBytesViaTempFile(
                  player,
                  source.bytes,
                  mimeType: source.mimeType,
                  tag: tag,
                  data: payload,
                ),
              ),
            _AudioSourceAttempt(
              label: 'bytes_source',
              run: () => player.setSourceBytes(
                source.bytes,
                mimeType: source.mimeType,
              ),
            ),
            if (!preferTempFile)
              _AudioSourceAttempt(
                label: 'desktop_temp_file',
                run: () => _setBytesViaTempFile(
                  player,
                  source.bytes,
                  mimeType: source.mimeType,
                  tag: tag,
                  data: payload,
                ),
              ),
          ],
        );
      default:
        await player.setSource(source);
    }
    _log.d(
      tag,
      'setSource complete',
      data: <String, Object?>{
        'playerId': player.playerId,
        'sourceType': source.runtimeType.toString(),
        ...data,
      },
    );
  }

  static Future<void> play(
    AudioPlayer player,
    Source source, {
    required double volume,
    String tag = 'audio_player_source',
    AudioContext? ctx,
    PlayerMode? mode,
    Map<String, Object?> data = const <String, Object?>{},
  }) async {
    _ensureDiagnostics(player, tag);
    _log.d(
      tag,
      'play start',
      data: <String, Object?>{
        'playerId': player.playerId,
        'sourceType': source.runtimeType.toString(),
        'volume': volume.clamp(0.0, 1.0),
        if (mode != null) 'mode': mode.name,
        ...data,
      },
    );
    if (mode != null) {
      await player.setPlayerMode(mode);
    }
    if (ctx != null) {
      await player.setAudioContext(ctx);
    }
    await player.setVolume(volume.clamp(0.0, 1.0));
    await setSource(player, source, tag: tag, data: data);
    await player.resume();
    _log.d(
      tag,
      'play resume complete',
      data: <String, Object?>{
        'playerId': player.playerId,
        'sourceType': source.runtimeType.toString(),
        ...data,
      },
    );
  }

  static Future<Duration?> waitForDuration(
    AudioPlayer player, {
    required String tag,
    Map<String, Object?> data = const <String, Object?>{},
    Duration timeout = const Duration(seconds: 12),
    Duration pollInterval = const Duration(milliseconds: 120),
  }) async {
    _ensureDiagnostics(player, tag);
    final baseData = <String, Object?>{
      'playerId': player.playerId,
      'timeoutMs': timeout.inMilliseconds,
      'pollIntervalMs': pollInterval.inMilliseconds,
      ...data,
    };
    final immediate = await player.getDuration();
    if (_hasPositiveDuration(immediate)) {
      _log.d(
        tag,
        'waitForDuration immediate hit',
        data: <String, Object?>{
          ...baseData,
          'durationMs': immediate!.inMilliseconds,
        },
      );
      return immediate;
    }

    _log.d(tag, 'waitForDuration start', data: baseData);
    final completer = Completer<Duration?>();
    late final StreamSubscription<Duration> subscription;

    void complete(Duration? value, String reason) {
      if (completer.isCompleted) {
        return;
      }
      _log.d(
        tag,
        'waitForDuration resolved',
        data: <String, Object?>{
          ...baseData,
          'reason': reason,
          if (value != null) 'durationMs': value.inMilliseconds,
        },
      );
      completer.complete(value);
    }

    subscription = player.onDurationChanged.listen(
      (duration) {
        if (_hasPositiveDuration(duration)) {
          complete(duration, 'stream');
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (completer.isCompleted) {
          return;
        }
        _log.w(
          tag,
          'waitForDuration stream error',
          data: <String, Object?>{...baseData, 'error': '$error'},
        );
      },
    );

    final deadline = DateTime.now().add(timeout);
    try {
      while (!completer.isCompleted && DateTime.now().isBefore(deadline)) {
        final polled = await player.getDuration();
        if (_hasPositiveDuration(polled)) {
          complete(polled, 'poll');
          break;
        }
        await Future.any<void>(<Future<void>>[
          completer.future.then((_) {}),
          Future<void>.delayed(pollInterval),
        ]);
      }
      if (!completer.isCompleted) {
        _log.w(tag, 'waitForDuration timed out', data: baseData);
        completer.complete(null);
      }
      return await completer.future;
    } finally {
      await subscription.cancel();
    }
  }

  static bool get _useWindowsNonBlockingSourceSet =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  static bool get _canUseDesktopTempFile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static bool get _shouldPreferTempFileForBytesSource =>
      _canUseDesktopTempFile && defaultTargetPlatform == TargetPlatform.windows;

  static Future<void> _setLocalFile(
    AudioPlayer player,
    String path, {
    required String? mimeType,
    required String tag,
    required Map<String, Object?> data,
  }) async {
    final file = File(path).absolute;
    final exists = await file.exists();
    final size = exists ? await file.length() : 0;
    final payload = <String, Object?>{
      ...data,
      'path': file.path,
      'mimeType': mimeType,
      'exists': exists,
      'bytes': size,
    };
    if (!exists || size <= 0) {
      throw FileSystemException(
        'Audio source file missing or empty.',
        file.path,
      );
    }

    final hasNonAsciiPath = _hasNonAsciiCharacters(file.path);
    _log.d(
      tag,
      'setLocalFile path analysis',
      data: <String, Object?>{
        'path': file.path,
        'hasNonAsciiPath': hasNonAsciiPath,
        'useBytes': hasNonAsciiPath && _useWindowsNonBlockingSourceSet,
      },
    );

    final strategies = <_AudioSourceAttempt>[
      if (!hasNonAsciiPath) ...<_AudioSourceAttempt>[
        _AudioSourceAttempt(
          label: 'file_uri',
          run: () => _useWindowsNonBlockingSourceSet
              ? _setSourceUrlNonBlocking(
                  player,
                  file.uri.toString(),
                  mimeType: mimeType,
                  isLocal: true,
                )
              : player.setSourceUrl(file.uri.toString(), mimeType: mimeType),
        ),
        _AudioSourceAttempt(
          label: 'device_file',
          run: () => _useWindowsNonBlockingSourceSet
              ? _setSourceUrlNonBlocking(
                  player,
                  file.path,
                  mimeType: mimeType,
                  isLocal: true,
                )
              : player.setSourceDeviceFile(file.path, mimeType: mimeType),
        ),
      ] else ...<_AudioSourceAttempt>[
        _AudioSourceAttempt(
          label: 'desktop_bytes_non_ascii',
          run: () async {
            _log.d(
              tag,
              'using bytes strategy for non-ASCII path',
              data: <String, Object?>{'path': file.path},
            );
            final bytes = await file.readAsBytes();
            if (_useWindowsNonBlockingSourceSet) {
              await _setSourceBytesNonBlocking(
                player,
                bytes,
                mimeType: mimeType,
              );
            } else {
              await player.setSourceBytes(bytes, mimeType: mimeType);
            }
          },
        ),
      ],
      if (!hasNonAsciiPath)
        _AudioSourceAttempt(
          label: 'desktop_bytes',
          run: () async {
            final bytes = await file.readAsBytes();
            if (_useWindowsNonBlockingSourceSet) {
              await _setSourceBytesNonBlocking(
                player,
                bytes,
                mimeType: mimeType,
              );
            } else {
              await player.setSourceBytes(bytes, mimeType: mimeType);
            }
          },
        ),
    ];

    await _attemptStrategies(tag: tag, data: payload, strategies: strategies);
    if (_useWindowsNonBlockingSourceSet) {
      await _waitForPlayerPrepared(player, tag: tag, data: payload);
    }
  }

  static bool _hasNonAsciiCharacters(String path) {
    return path.codeUnits.any((code) => code > 127);
  }

  static Future<void> _setSourceUrlNonBlocking(
    AudioPlayer player,
    String url, {
    required bool isLocal,
    String? mimeType,
  }) async {
    try {
      await player.creatingCompleter.future;
      await _platform.setSourceUrl(
        player.playerId,
        url,
        isLocal: isLocal,
        mimeType: mimeType,
      );
    } on PlatformException catch (e) {
      _log.w(
        'audio_player_source',
        'setSourceUrl platform exception',
        data: <String, Object?>{
          'code': e.code,
          'message': e.message,
          'details': e.details,
        },
      );
      rethrow;
    }
  }

  static Future<void> _setSourceBytesNonBlocking(
    AudioPlayer player,
    List<int> bytes, {
    String? mimeType,
  }) async {
    try {
      await player.creatingCompleter.future;
      await _platform.setSourceBytes(
        player.playerId,
        Uint8List.fromList(bytes),
        mimeType: mimeType,
      );
    } on PlatformException catch (e) {
      _log.w(
        'audio_player_source',
        'setSourceBytes platform exception',
        data: <String, Object?>{
          'code': e.code,
          'message': e.message,
          'details': e.details,
        },
      );
      rethrow;
    }
  }

  static Future<void> _setBytesViaTempFile(
    AudioPlayer player,
    Uint8List bytes, {
    required String? mimeType,
    required String tag,
    required Map<String, Object?> data,
  }) async {
    if (!_canUseDesktopTempFile) {
      throw UnsupportedError(
        'Temporary file byte playback fallback is only supported on desktop.',
      );
    }

    final hintPath = _extractSourcePathHint(data);
    final tempPath = await _bytesTempStore.pathFor(
      bytes,
      mimeType: mimeType,
      hintPath: hintPath,
    );
    await _setLocalFile(
      player,
      tempPath,
      mimeType: mimeType,
      tag: tag,
      data: <String, Object?>{
        ...data,
        'hintPath': hintPath,
        'tempFilePath': tempPath,
      },
    );
  }

  static Future<void> _waitForPlayerPrepared(
    AudioPlayer player, {
    required String tag,
    required Map<String, Object?> data,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final payload = <String, Object?>{
      'playerId': player.playerId,
      'timeoutMs': timeout.inMilliseconds,
      ...data,
    };
    final immediateDuration = await player.getDuration();
    if (_hasPositiveDuration(immediateDuration)) {
      _log.d(
        tag,
        'player already prepared via duration',
        data: <String, Object?>{
          ...payload,
          'durationMs': immediateDuration!.inMilliseconds,
        },
      );
      return;
    }

    _log.d(tag, 'waiting for prepared event', data: payload);
    try {
      final result = await Future.any<Object?>(<Future<Object?>>[
        player.eventStream
            .where(
              (event) =>
                  event.eventType == AudioEventType.prepared &&
                  event.isPrepared == true,
            )
            .first
            .then<Object?>((_) => 'prepared'),
        player.onDurationChanged
            .firstWhere((duration) => duration.inMilliseconds > 0)
            .then<Object?>((duration) => duration),
      ]).timeout(timeout);
      _log.d(
        tag,
        'prepared wait complete',
        data: <String, Object?>{
          ...payload,
          'result': result is Duration ? 'duration' : '$result',
          if (result is Duration) 'durationMs': result.inMilliseconds,
        },
      );
    } on TimeoutException {
      _log.w(tag, 'prepared wait timed out', data: payload);
    }
  }

  static String? _extractSourcePathHint(Map<String, Object?> data) {
    const candidateKeys = <String>[
      'trackAssetPath',
      'assetPath',
      'filePath',
      'path',
      'sourcePath',
      'url',
    ];
    for (final key in candidateKeys) {
      final raw = data[key];
      if (raw is! String) {
        continue;
      }
      final value = raw.trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  @visibleForTesting
  static Future<String> debugTempFilePathForBytes(
    Uint8List bytes, {
    String? mimeType,
    Map<String, Object?> data = const <String, Object?>{},
  }) {
    return _bytesTempStore.pathFor(
      bytes,
      mimeType: mimeType,
      hintPath: _extractSourcePathHint(data),
    );
  }

  static bool _hasPositiveDuration(Duration? duration) {
    return duration != null && duration.inMilliseconds > 0;
  }

  static void _ensureDiagnostics(AudioPlayer player, String tag) {
    _diagnosticTags[player] = tag;
    if (_diagnostics[player] != null) {
      return;
    }
    _diagnostics[player] = _AudioPlayerDiagnostics(player, _log, () {
      return _diagnosticTags[player] ?? tag;
    });
  }

  static Future<void> _attemptStrategies({
    required String tag,
    required Map<String, Object?> data,
    required List<_AudioSourceAttempt> strategies,
  }) async {
    Object? lastError;
    StackTrace? lastStackTrace;
    for (var index = 0; index < strategies.length; index += 1) {
      final strategy = strategies[index];
      try {
        await strategy.run();
        _log.d(
          tag,
          index > 0
              ? 'audio source fallback strategy recovered playback'
              : 'audio source strategy succeeded',
          data: <String, Object?>{
            ...data,
            'strategy': strategy.label,
            'attempt': index + 1,
          },
        );
        return;
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
        _log.w(
          tag,
          'audio source strategy failed',
          data: <String, Object?>{
            ...data,
            'strategy': strategy.label,
            'attempt': index + 1,
            'error': '$error',
          },
        );
      }
    }

    _log.e(
      tag,
      'all audio source strategies failed',
      error: lastError,
      stackTrace: lastStackTrace,
      data: data,
    );
    if (lastError != null) {
      Error.throwWithStackTrace(lastError, lastStackTrace!);
    }
    throw StateError('No audio source strategy was available.');
  }
}

class _AudioSourceAttempt {
  const _AudioSourceAttempt({required this.label, required this.run});

  final String label;
  final Future<void> Function() run;
}

class _AudioPlayerDiagnostics {
  _AudioPlayerDiagnostics(this.player, this.log, this._tagProvider) {
    _attach();
  }

  final AudioPlayer player;
  final AppLogService log;
  final String Function() _tagProvider;
  bool _loggedFirstPosition = false;

  void _attach() {
    player.eventStream.listen(
      (event) {
        final tag = _tagProvider();
        switch (event.eventType) {
          case AudioEventType.prepared:
            log.d(
              tag,
              'player prepared event',
              data: <String, Object?>{
                'playerId': player.playerId,
                'isPrepared': event.isPrepared,
              },
            );
          case AudioEventType.duration:
            log.d(
              tag,
              'player duration event',
              data: <String, Object?>{
                'playerId': player.playerId,
                'durationMs': event.duration?.inMilliseconds,
              },
            );
          case AudioEventType.seekComplete:
            log.d(
              tag,
              'player seek complete event',
              data: <String, Object?>{'playerId': player.playerId},
            );
          case AudioEventType.complete:
            log.d(
              tag,
              'player complete event',
              data: <String, Object?>{'playerId': player.playerId},
            );
          case AudioEventType.log:
            log.d(
              tag,
              'player platform log',
              data: <String, Object?>{
                'playerId': player.playerId,
                'message': event.logMessage,
              },
            );
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        final tag = _tagProvider();
        log.e(
          tag,
          'player event stream error',
          error: error,
          stackTrace: stackTrace,
          data: <String, Object?>{'playerId': player.playerId},
        );
      },
    );
    player.onPlayerStateChanged.listen(
      (state) {
        final tag = _tagProvider();
        log.d(
          tag,
          'player state changed',
          data: <String, Object?>{
            'playerId': player.playerId,
            'state': state.name,
          },
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        final tag = _tagProvider();
        log.e(
          tag,
          'player state stream error',
          error: error,
          stackTrace: stackTrace,
          data: <String, Object?>{'playerId': player.playerId},
        );
      },
    );
    player.onPositionChanged.listen(
      (position) {
        if (_loggedFirstPosition || position.inMilliseconds <= 0) {
          return;
        }
        _loggedFirstPosition = true;
        final tag = _tagProvider();
        log.d(
          tag,
          'player position advanced',
          data: <String, Object?>{
            'playerId': player.playerId,
            'positionMs': position.inMilliseconds,
          },
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        final tag = _tagProvider();
        log.e(
          tag,
          'player position stream error',
          error: error,
          stackTrace: stackTrace,
          data: <String, Object?>{'playerId': player.playerId},
        );
      },
    );
  }
}

class _AudioPlayerBytesTempStore {
  final Map<String, Future<String>> _pathFutures = <String, Future<String>>{};

  Future<String> pathFor(
    Uint8List bytes, {
    String? mimeType,
    String? hintPath,
  }) {
    final extension = _resolveExtension(
      bytes: bytes,
      mimeType: mimeType,
      hintPath: hintPath,
    );
    final digest = sha1.convert(bytes).toString();
    final cacheKey = '$digest:$extension';
    final existing = _pathFutures[cacheKey];
    if (existing != null) {
      return existing;
    }

    final future = _writeBytes(bytes, digest: digest, extension: extension);
    _pathFutures[cacheKey] = future;
    return future.catchError((Object error) {
      _pathFutures.remove(cacheKey);
      throw error;
    });
  }

  Future<String> _writeBytes(
    Uint8List bytes, {
    required String digest,
    required String extension,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory(
      p.join(tempDir.path, 'audio_player_source_cache'),
    );
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    final file = File(p.join(cacheDir.path, '$digest$extension'));
    if (!await file.exists() || await file.length() != bytes.length) {
      await file.writeAsBytes(bytes, flush: true);
    }
    return file.path;
  }

  String _resolveExtension({
    required Uint8List bytes,
    required String? mimeType,
    required String? hintPath,
  }) {
    final hintExtension = _extensionFromHint(hintPath);
    if (hintExtension != null) {
      return hintExtension;
    }

    final mimeExtension = _extensionFromMimeType(mimeType);
    if (mimeExtension != null) {
      return mimeExtension;
    }

    return _extensionFromHeader(bytes) ?? '.bin';
  }

  String? _extensionFromHint(String? hintPath) {
    final normalized = hintPath?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final withoutQuery = normalized.split('?').first.split('#').first;
    final extension = p.extension(withoutQuery).trim().toLowerCase();
    if (extension.isEmpty || extension.length > 10) {
      return null;
    }
    return extension;
  }

  String? _extensionFromMimeType(String? mimeType) {
    final normalized = mimeType?.trim().toLowerCase();
    return switch (normalized) {
      'audio/wav' || 'audio/x-wav' || 'audio/wave' => '.wav',
      'audio/mpeg' || 'audio/mp3' => '.mp3',
      'audio/mp4' || 'audio/x-m4a' || 'audio/m4a' => '.m4a',
      'audio/aac' || 'audio/aacp' => '.aac',
      'audio/ogg' || 'application/ogg' => '.ogg',
      'audio/flac' => '.flac',
      'audio/webm' => '.webm',
      'audio/x-ms-wma' => '.wma',
      _ => null,
    };
  }

  String? _extensionFromHeader(Uint8List bytes) {
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x41 &&
        bytes[10] == 0x56 &&
        bytes[11] == 0x45) {
      return '.wav';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x4F &&
        bytes[1] == 0x67 &&
        bytes[2] == 0x67 &&
        bytes[3] == 0x53) {
      return '.ogg';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x66 &&
        bytes[1] == 0x4C &&
        bytes[2] == 0x61 &&
        bytes[3] == 0x43) {
      return '.flac';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0x49 &&
        bytes[1] == 0x44 &&
        bytes[2] == 0x33) {
      return '.mp3';
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) {
      return '.mp3';
    }
    if (bytes.length >= 8 &&
        bytes[4] == 0x66 &&
        bytes[5] == 0x74 &&
        bytes[6] == 0x79 &&
        bytes[7] == 0x70) {
      return '.m4a';
    }
    return null;
  }
}

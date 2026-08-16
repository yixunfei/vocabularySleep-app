import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kDebugMode;

import '../models/play_config.dart';
import '../models/word_entry.dart';
import 'app_log_service.dart';
import 'tts_service.dart';

typedef WordChangeCallback = void Function(int index, WordEntry word);
typedef UnitChangeCallback =
    void Function(int current, int total, PlayUnit unit);
typedef WordResolveCallback =
    FutureOr<WordEntry> Function(int index, WordEntry word);

class PlaybackPrepareCancelledException implements Exception {
  const PlaybackPrepareCancelledException();

  @override
  String toString() => 'Playback prepare was cancelled.';
}

class PlaybackService {
  PlaybackService(this._ttsService);

  static const int _maxWordPrecacheParallelRequests = 3;

  final TtsService _ttsService;
  final AppLogService _log = AppLogService.instance;

  bool _playLoop = false;
  bool _paused = false;
  bool _skipCurrentWord = false;
  bool _unitSpeakInProgress = false;
  bool _replayCurrentUnitAfterResume = false;
  PlayConfig _activeConfig = PlayConfig.defaults;
  TtsProviderType _activeSpeakProvider = TtsProviderType.local;
  int _runId = 0;
  PreparedPlaySession? _preparedSession;
  bool _disposed = false;

  bool get isPlaying => _playLoop;
  bool get isPaused => _paused;
  bool get isPrepared => _preparedSession != null;

  Future<List<String>> getLocalVoices() => _ttsService.getLocalVoices();
  Future<int> getApiTtsCacheSizeBytes() => _ttsService.getApiCacheSizeBytes();
  Future<void> clearApiTtsCache() => _ttsService.clearApiCache();

  void updateRuntimeConfig(PlayConfig config) {
    _ensureNotDisposed();
    _activeConfig = config;
  }

  /// Prepare playback without starting
  Future<PreparedPlaySession> preparePlay({
    required List<WordEntry> words,
    required int startIndex,
    required PlayConfig config,
    WordResolveCallback? resolveWord,
    WordChangeCallback? onWordChanged,
    UnitChangeCallback? onUnitChanged,
    VoidCallback? onFinished,
  }) async {
    _ensureNotDisposed();
    if (words.isEmpty) throw ArgumentError('Words list cannot be empty');
    _ttsService.validateForPlayback(config.tts);
    if (_playLoop) await stop();

    final runId = ++_runId;
    _activeConfig = config;

    final indices = _buildPlaybackIndices(
      wordCount: words.length,
      startIndex: startIndex,
      order: config.order,
    );

    final session = PreparedPlaySession(
      words: words,
      startIndex: startIndex,
      config: config,
      resolveWord: resolveWord,
      onWordChanged: onWordChanged,
      onUnitChanged: onUnitChanged,
      onFinished: onFinished,
      indices: indices,
      runId: runId,
    );

    _preparedSession = session;
    _log.i(
      'playback',
      'Playback prepared successfully',
      data: {'wordCount': words.length, 'queueCount': 0, 'runId': runId},
    );

    return session;
  }

  /// Start playback from prepared session
  Future<void> startPreparedPlay() async {
    _ensureNotDisposed();
    final session = _preparedSession;
    if (session == null) {
      _log.w('playback', 'No prepared session to start');
      return;
    }
    if (_playLoop) await stop();

    final runId = session.runId;
    _runId = runId;
    _activeConfig = session.config;
    _playLoop = true;
    _paused = false;
    _skipCurrentWord = false;
    _preparedSession = null; // Consume the session

    var completed = false;
    try {
      for (final index in session.indices) {
        if (!_isRunActive(runId)) break;
        await _waitIfPaused(runId);
        if (!_isRunActive(runId)) break;

        final sourceWord = session.words[index];
        var word = sourceWord;
        if (session.resolveWord != null) {
          try {
            word = await Future<WordEntry>.value(
              session.resolveWord!(index, sourceWord),
            );
          } catch (error, stackTrace) {
            _log.e(
              'playback',
              'resolve word failed',
              error: error,
              stackTrace: stackTrace,
              data: <String, Object?>{
                'wordId': sourceWord.id,
                'word': sourceWord.word,
                'index': index,
              },
            );
          }
        }

        session.onWordChanged?.call(index, word);
        await _playSingleWord(word, session.onUnitChanged, runId);
      }
      completed = runId == _runId;
    } finally {
      if (runId == _runId) {
        _playLoop = false;
        _paused = false;
        _skipCurrentWord = false;
        if (completed) {
          session.onFinished?.call();
        }
      }
    }
  }

  /// Original playWords method (backward compatible)
  Future<void> playWords({
    required List<WordEntry> words,
    required int startIndex,
    required PlayConfig config,
    WordResolveCallback? resolveWord,
    WordChangeCallback? onWordChanged,
    UnitChangeCallback? onUnitChanged,
    VoidCallback? onFinished,
  }) async {
    _ensureNotDisposed();
    if (words.isEmpty) return;
    _ttsService.validateForPlayback(config.tts);
    if (_playLoop) await stop();
    _preparedSession = null;
    final runId = ++_runId;
    _activeConfig = config;
    _playLoop = true;
    _paused = false;
    _skipCurrentWord = false;

    final indices = _buildPlaybackIndices(
      wordCount: words.length,
      startIndex: startIndex,
      order: config.order,
    );
    var completed = false;
    try {
      for (final index in indices) {
        if (!_isRunActive(runId)) break;
        await _waitIfPaused(runId);
        if (!_isRunActive(runId)) break;

        final sourceWord = words[index];
        var word = sourceWord;
        if (resolveWord != null) {
          try {
            word = await Future<WordEntry>.value(
              resolveWord(index, sourceWord),
            );
          } catch (error, stackTrace) {
            _log.e(
              'playback',
              'resolve word failed',
              error: error,
              stackTrace: stackTrace,
              data: <String, Object?>{
                'wordId': sourceWord.id,
                'word': sourceWord.word,
                'index': index,
              },
            );
          }
        }
        onWordChanged?.call(index, word);
        await _playSingleWord(word, onUnitChanged, runId);
      }
      completed = runId == _runId;
    } finally {
      if (runId == _runId) {
        _playLoop = false;
        _paused = false;
        _skipCurrentWord = false;
        if (completed) {
          onFinished?.call();
        }
      }
    }
  }

  Future<void> pause() async {
    _ensureNotDisposed();
    if (!_playLoop || _paused) return;
    _paused = true;
    final provider = _unitSpeakInProgress
        ? _activeSpeakProvider
        : _activeConfig.tts.provider;
    if (_unitSpeakInProgress) {
      _replayCurrentUnitAfterResume = true;
      // Interrupt in-flight unit (including remote HTTP fetch) so pause is immediate.
      await _ttsService.stop();
      return;
    }
    await _ttsService.pause(provider);
  }

  Future<void> resume() async {
    _ensureNotDisposed();
    if (!_playLoop || !_paused) return;
    final provider = _unitSpeakInProgress
        ? _activeSpeakProvider
        : _activeConfig.tts.provider;
    _paused = false;
    await _ttsService.resume(provider);
  }

  Future<void> stop() async {
    _runId += 1;
    _playLoop = false;
    _paused = false;
    _skipCurrentWord = false;
    _unitSpeakInProgress = false;
    _replayCurrentUnitAfterResume = false;
    _activeSpeakProvider = TtsProviderType.local;
    _preparedSession = null;
    await _ttsService.stop();
  }

  Future<void> skipCurrentWord() async {
    _ensureNotDisposed();
    if (!_playLoop) return;
    _skipCurrentWord = true;
    _replayCurrentUnitAfterResume = false;
    await _ttsService.stop();
  }

  Future<void> speakText(String text, PlayConfig config) async {
    _ensureNotDisposed();
    final content = text.trim();
    if (content.isEmpty) return;
    await _ttsService.speak(content, config.tts);
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await stop();
    await _ttsService.dispose();
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('PlaybackService has been disposed.');
    }
  }

  Future<void> _playSingleWord(
    WordEntry word,
    UnitChangeCallback? onUnitChanged,
    int runId,
  ) async {
    final config = _activeConfig;
    final queue = buildPlayQueue(word, config);
    if (kDebugMode) {
      _log.d(
        'playback',
        'play queue built',
        data: <String, Object?>{
          'word': word.word,
          'wordId': word.id,
          'queueLength': queue.length,
          'fieldCount': word.playbackFields.length,
          'fieldKeys': word.playbackFields.map((f) => f.key).toList(),
          'units': queue.map((u) => '${u.type}:${_preview(u.text)}').toList(),
        },
      );
    }
    await _precacheCurrentWordUnits(word, queue, runId);
    var i = 0;
    while (i < queue.length) {
      if (!_isRunActive(runId)) break;
      await _waitIfPaused(runId);
      if (!_isRunActive(runId)) break;
      if (_skipCurrentWord) {
        _skipCurrentWord = false;
        _replayCurrentUnitAfterResume = false;
        break;
      }

      final unit = queue[i];
      onUnitChanged?.call(i + 1, queue.length, unit);
      _unitSpeakInProgress = true;
      if (kDebugMode) {
        _log.d(
          'playback',
          'unit speak start',
          data: <String, Object?>{
            'word': word.word,
            'unitIndex': i + 1,
            'unitTotal': queue.length,
            'unitType': unit.type,
            'unitPreview': _preview(unit.text),
          },
        );
      }
      try {
        final ttsConfig = _activeConfig.tts;
        _activeSpeakProvider = ttsConfig.provider;
        await _ttsService.speak(unit.text, ttsConfig);
        if (kDebugMode) {
          _log.d(
            'playback',
            'unit speak done',
            data: <String, Object?>{
              'word': word.word,
              'unitIndex': i + 1,
              'unitType': unit.type,
            },
          );
        }
      } catch (error, stackTrace) {
        _log.e(
          'playback',
          'unit speak failed',
          error: error,
          stackTrace: stackTrace,
          data: <String, Object?>{
            'wordId': word.id,
            'word': word.word,
            'unitIndex': i + 1,
            'unitType': unit.type,
            'unitPreview': _preview(unit.text),
          },
        );
        if (error is TtsConfigurationException) {
          rethrow;
        }
        // Keep playing even if one unit fails.
      } finally {
        _unitSpeakInProgress = false;
      }

      if (_replayCurrentUnitAfterResume) {
        if (_paused) {
          continue;
        }
        _replayCurrentUnitAfterResume = false;
        continue;
      }
      _replayCurrentUnitAfterResume = false;

      final delayMs = _activeConfig.delayBetweenUnitsMs;
      if (delayMs > 0 && i < queue.length - 1) {
        await _waitDelayWithPause(Duration(milliseconds: delayMs), runId);
      }
      i += 1;
    }
    if (kDebugMode) {
      _log.d(
        'playback',
        'single word done',
        data: <String, Object?>{
          'word': word.word,
          'unitsPlayed': i,
          'queueLength': queue.length,
        },
      );
    }
  }

  String _preview(String text) {
    final compact = text.replaceAll('\n', ' ').trim();
    if (compact.length <= 72) return compact;
    return '${compact.substring(0, 72)}...';
  }

  bool _isRunActive(int runId) => _playLoop && runId == _runId;

  Future<void> _precacheCurrentWordUnits(
    WordEntry word,
    List<PlayUnit> queue,
    int runId,
  ) async {
    final ttsConfig = _activeConfig.tts;
    if (ttsConfig.provider == TtsProviderType.local ||
        !ttsConfig.enableApiCache ||
        queue.isEmpty) {
      return;
    }
    final seen = <String>{};
    final texts = <String>[];
    for (final unit in queue) {
      final text = unit.text.trim();
      if (text.isEmpty || !seen.add(text)) continue;
      texts.add(text);
    }
    if (texts.isEmpty) return;

    if (kDebugMode) {
      _log.d(
        'playback',
        'precache current word units',
        data: <String, Object?>{
          'word': word.word,
          'wordId': word.id,
          'unitCount': queue.length,
          'requestCount': texts.length,
        },
      );
    }

    for (
      var start = 0;
      start < texts.length;
      start += _maxWordPrecacheParallelRequests
    ) {
      if (!_isRunActive(runId)) return;
      await _waitIfPaused(runId);
      if (!_isRunActive(runId)) return;
      final end = math.min(
        start + _maxWordPrecacheParallelRequests,
        texts.length,
      );
      final batch = texts.sublist(start, end);
      await Future.wait(
        batch.map((text) async {
          try {
            await _ttsService.speak(text, ttsConfig, preCacheOnly: true);
          } catch (error, stackTrace) {
            _log.w(
              'playback',
              'precache current word unit failed',
              data: <String, Object?>{
                'word': word.word,
                'wordId': word.id,
                'unitPreview': _preview(text),
                'error': '$error',
                'stackTrace': '$stackTrace',
              },
            );
          }
        }),
      );
    }
  }

  Future<void> _waitIfPaused(int runId) async {
    while (_isRunActive(runId) && _paused) {
      await Future<void>.delayed(const Duration(milliseconds: 160));
    }
  }

  Future<void> _waitDelayWithPause(Duration duration, int runId) async {
    var remainingMs = duration.inMilliseconds;
    while (_isRunActive(runId) && remainingMs > 0) {
      await _waitIfPaused(runId);
      if (!_isRunActive(runId)) return;
      final step = math.min(remainingMs, 120);
      await Future<void>.delayed(Duration(milliseconds: step));
      remainingMs -= step;
    }
  }

  Iterable<int> _buildPlaybackIndices({
    required int wordCount,
    required int startIndex,
    required PlayOrder order,
  }) sync* {
    if (wordCount <= 0) {
      return;
    }
    final safeStart = startIndex.clamp(0, wordCount - 1).toInt();
    if (order != PlayOrder.random) {
      for (var index = safeStart; index < wordCount; index += 1) {
        yield index;
      }
      return;
    }
    final remaining = List<int>.generate(wordCount, (index) => index)
      ..remove(safeStart);
    yield safeStart;
    for (final index in shuffled(remaining)) {
      yield index;
    }
  }
}

/// Preloaded playback session data
class PreparedPlaySession {
  final List<WordEntry> words;
  final int startIndex;
  final PlayConfig config;
  final WordResolveCallback? resolveWord;
  final WordChangeCallback? onWordChanged;
  final UnitChangeCallback? onUnitChanged;
  final VoidCallback? onFinished;
  final Iterable<int> indices;
  final int runId;

  PreparedPlaySession({
    required this.words,
    required this.startIndex,
    required this.config,
    this.resolveWord,
    this.onWordChanged,
    this.onUnitChanged,
    this.onFinished,
    required this.indices,
    required this.runId,
  });
}

typedef VoidCallback = void Function();

import 'dart:async';
import 'dart:math' as math;

import '../models/play_config.dart';
import '../models/word_entry.dart';
import 'app_log_service.dart';
import 'tts_service.dart';

typedef WordChangeCallback = void Function(int index, WordEntry word);
typedef UnitChangeCallback =
    void Function(int current, int total, PlayUnit unit);
typedef WordResolveCallback =
    FutureOr<WordEntry> Function(int index, WordEntry word);

class PlaybackService {
  PlaybackService(this._ttsService);

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

  bool get isPlaying => _playLoop;
  bool get isPaused => _paused;
  bool get isPrepared => _preparedSession != null;

  Future<List<String>> getLocalVoices() => _ttsService.getLocalVoices();
  Future<int> getApiTtsCacheSizeBytes() => _ttsService.getApiCacheSizeBytes();
  Future<void> clearApiTtsCache() => _ttsService.clearApiCache();

  void updateRuntimeConfig(PlayConfig config) {
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
    if (words.isEmpty) throw ArgumentError('Words list cannot be empty');
    if (_playLoop) await stop();

    final runId = ++_runId;
    _activeConfig = config;

    // Build playback indices
    final indices = _buildPlaybackIndices(
      wordCount: words.length,
      startIndex: startIndex,
      order: config.order,
    );

    // Pre-resolve all words and prebuild play queues
    final resolvedWords = <WordEntry>[];
    final prebuiltQueues = <List<PlayUnit>>[];
    for (final index in indices) {
      final sourceWord = words[index];
      var word = sourceWord;
      if (resolveWord != null) {
        try {
          word = await Future<WordEntry>.value(resolveWord(index, sourceWord));
        } catch (error, stackTrace) {
          _log.e(
            'playback',
            'resolve word failed during prepare',
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

      // Prebuild play queue for this word
      resolvedWords.add(word);
      final queue = buildPlayQueue(word, config);
      prebuiltQueues.add(queue);

      // Pre-cache API TTS audio if needed
      if (config.tts.provider != TtsProviderType.local &&
          config.tts.enableApiCache) {
        for (final unit in queue) {
          try {
            // This will download and cache the audio without playing
            await _ttsService.speak(unit.text, config.tts, preCacheOnly: true);
          } catch (e) {
            _log.w(
              'playback',
              'Failed to pre-cache audio for unit: ${unit.type}',
              data: {
                'word': word.word,
                'text': unit.text,
                'error': e.toString(),
              },
            );
          }
        }
      }
    }

    final session = PreparedPlaySession(
      words: words,
      startIndex: startIndex,
      config: config,
      resolveWord: resolveWord,
      onWordChanged: onWordChanged,
      onUnitChanged: onUnitChanged,
      onFinished: onFinished,
      indices: indices,
      resolvedWords: resolvedWords,
      prebuiltQueues: prebuiltQueues,
      runId: runId,
    );

    _preparedSession = session;
    _log.i(
      'playback',
      'Playback prepared successfully',
      data: {
        'wordCount': words.length,
        'queueCount': prebuiltQueues.length,
        'runId': runId,
      },
    );

    return session;
  }

  /// Start playback from prepared session
  Future<void> startPreparedPlay() async {
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

    for (var i = 0; i < session.indices.length; i++) {
      if (!_isRunActive(runId)) break;
      await _waitIfPaused(runId);
      if (!_isRunActive(runId)) break;

      final index = session.indices[i];
      final word = session.resolvedWords[i];
      final queue = session.prebuiltQueues[i];

      session.onWordChanged?.call(index, word);
      await _playSingleWordWithQueue(word, queue, session.onUnitChanged, runId);
    }

    if (runId != _runId) {
      return;
    }
    _playLoop = false;
    _paused = false;
    _skipCurrentWord = false;
    session.onFinished?.call();
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
    if (words.isEmpty) return;
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
    for (final index in indices) {
      if (!_isRunActive(runId)) break;
      await _waitIfPaused(runId);
      if (!_isRunActive(runId)) break;

      final sourceWord = words[index];
      var word = sourceWord;
      if (resolveWord != null) {
        try {
          word = await Future<WordEntry>.value(resolveWord(index, sourceWord));
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

    if (runId != _runId) {
      return;
    }
    _playLoop = false;
    _paused = false;
    _skipCurrentWord = false;
    onFinished?.call();
  }

  Future<void> pause() async {
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
    if (!_playLoop) return;
    _skipCurrentWord = true;
    _replayCurrentUnitAfterResume = false;
    await _ttsService.stop();
  }

  Future<void> speakText(String text, PlayConfig config) async {
    final content = text.trim();
    if (content.isEmpty) return;
    await _ttsService.speak(content, config.tts);
  }

  Future<void> _playSingleWordWithQueue(
    WordEntry word,
    List<PlayUnit> queue,
    UnitChangeCallback? onUnitChanged,
    int runId,
  ) async {
    _log.i(
      'playback',
      'using prebuilt play queue',
      data: <String, Object?>{
        'word': word.word,
        'wordId': word.id,
        'queueLength': queue.length,
        'units': queue.map((u) => '${u.type}:${_preview(u.text)}').toList(),
      },
    );
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
      _log.i(
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
      try {
        final ttsConfig = _activeConfig.tts;
        _activeSpeakProvider = ttsConfig.provider;
        await _ttsService.speak(unit.text, ttsConfig);
        _log.i(
          'playback',
          'unit speak done',
          data: <String, Object?>{
            'word': word.word,
            'unitIndex': i + 1,
            'unitType': unit.type,
          },
        );
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
    _log.i(
      'playback',
      'single word done',
      data: <String, Object?>{
        'word': word.word,
        'unitsPlayed': i,
        'queueLength': queue.length,
      },
    );
  }

  Future<void> _playSingleWord(
    WordEntry word,
    UnitChangeCallback? onUnitChanged,
    int runId,
  ) async {
    final config = _activeConfig;
    final queue = buildPlayQueue(word, config);
    _log.i(
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
      _log.i(
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
      try {
        final ttsConfig = _activeConfig.tts;
        _activeSpeakProvider = ttsConfig.provider;
        await _ttsService.speak(unit.text, ttsConfig);
        _log.i(
          'playback',
          'unit speak done',
          data: <String, Object?>{
            'word': word.word,
            'unitIndex': i + 1,
            'unitType': unit.type,
          },
        );
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
    _log.i(
      'playback',
      'single word done',
      data: <String, Object?>{
        'word': word.word,
        'unitsPlayed': i,
        'queueLength': queue.length,
      },
    );
  }

  String _preview(String text) {
    final compact = text.replaceAll('\n', ' ').trim();
    if (compact.length <= 72) return compact;
    return '${compact.substring(0, 72)}...';
  }

  bool _isRunActive(int runId) => _playLoop && runId == _runId;

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

  List<int> _buildPlaybackIndices({
    required int wordCount,
    required int startIndex,
    required PlayOrder order,
  }) {
    final safeStart = startIndex.clamp(0, wordCount - 1);
    if (order != PlayOrder.random) {
      return List<int>.generate(
        wordCount - safeStart,
        (index) => index + safeStart,
      );
    }
    final remaining = List<int>.generate(wordCount, (index) => index)
      ..remove(safeStart);
    return <int>[safeStart, ...shuffled(remaining)];
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
  final List<int> indices;
  final List<WordEntry> resolvedWords;
  final List<List<PlayUnit>> prebuiltQueues;
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
    required this.resolvedWords,
    required this.prebuiltQueues,
    required this.runId,
  });
}

typedef VoidCallback = void Function();

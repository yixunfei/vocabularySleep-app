import 'dart:async';
import 'dart:math' as math;

import '../models/play_config.dart';
import '../models/word_entry.dart';
import 'app_log_service.dart';
import 'tts_service.dart';

typedef WordChangeCallback = void Function(int index, WordEntry word);
typedef UnitChangeCallback =
    void Function(int current, int total, PlayUnit unit);

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

  bool get isPlaying => _playLoop;
  bool get isPaused => _paused;

  Future<List<String>> getLocalVoices() => _ttsService.getLocalVoices();
  Future<int> getApiTtsCacheSizeBytes() => _ttsService.getApiCacheSizeBytes();
  Future<void> clearApiTtsCache() => _ttsService.clearApiCache();

  void updateRuntimeConfig(PlayConfig config) {
    _activeConfig = config;
    _log.d(
      'playback',
      'runtime config updated',
      data: <String, Object?>{
        'provider': config.tts.provider.name,
        'model': config.tts.model,
        'activeVoice': config.tts.activeVoice,
        'speed': config.tts.speed,
        'volume': config.tts.volume,
      },
    );
  }

  Future<void> playWords({
    required List<WordEntry> words,
    required int startIndex,
    required PlayConfig config,
    WordChangeCallback? onWordChanged,
    UnitChangeCallback? onUnitChanged,
    VoidCallback? onFinished,
  }) async {
    if (words.isEmpty) return;
    if (_playLoop) await stop();
    final runId = ++_runId;
    _activeConfig = config;
    _log.i(
      'playback',
      'playWords started',
      data: <String, Object?>{
        'words': words.length,
        'startIndex': startIndex,
        'order': config.order.name,
        'provider': config.tts.provider.name,
        'model': config.tts.model,
        'voice': config.tts.activeVoice,
        'speed': config.tts.speed,
        'volume': config.tts.volume,
      },
    );

    _playLoop = true;
    _paused = false;
    _skipCurrentWord = false;

    final indices = _buildPlaybackIndices(
      wordCount: words.length,
      startIndex: startIndex,
      order: config.order,
    );
    _log.d(
      'playback',
      'play order built',
      data: <String, Object?>{
        'totalIndices': indices.length,
        'firstIndex': indices.isEmpty ? null : indices.first,
      },
    );

    for (final index in indices) {
      if (!_isRunActive(runId)) break;
      await _waitIfPaused(runId);
      if (!_isRunActive(runId)) break;

      final word = words[index];
      _log.i(
        'playback',
        'play word',
        data: <String, Object?>{
          'index': index,
          'wordId': word.id,
          'word': word.word,
        },
      );
      onWordChanged?.call(index, word);
      await _playSingleWord(word, onUnitChanged, runId);
      _log.d(
        'playback',
        'word finished',
        data: <String, Object?>{
          'index': index,
          'wordId': word.id,
          'word': word.word,
        },
      );
    }

    if (runId != _runId) {
      _log.d(
        'playback',
        'playWords stale run completed',
        data: <String, Object?>{'runId': runId, 'activeRunId': _runId},
      );
      return;
    }
    _playLoop = false;
    _paused = false;
    _skipCurrentWord = false;
    _log.i('playback', 'playWords finished');
    onFinished?.call();
  }

  Future<void> pause() async {
    if (!_playLoop || _paused) return;
    _paused = true;
    final provider = _unitSpeakInProgress
        ? _activeSpeakProvider
        : _activeConfig.tts.provider;
    _log.i(
      'playback',
      'pause requested',
      data: <String, Object?>{
        'provider': provider.name,
        'unitSpeakInProgress': _unitSpeakInProgress,
      },
    );
    if (_unitSpeakInProgress) {
      _replayCurrentUnitAfterResume = true;
      // Interrupt in-flight unit (including remote HTTP fetch) so pause is immediate.
      await _ttsService.stop();
      _log.d(
        'playback',
        'pause interrupted in-flight unit',
        data: <String, Object?>{'provider': provider.name},
      );
      return;
    }
    await _ttsService.pause(provider);
    _log.d('playback', 'pause done');
  }

  Future<void> resume() async {
    if (!_playLoop || !_paused) return;
    final provider = _unitSpeakInProgress
        ? _activeSpeakProvider
        : _activeConfig.tts.provider;
    _log.i(
      'playback',
      'resume requested',
      data: <String, Object?>{'provider': provider.name},
    );
    _paused = false;
    await _ttsService.resume(provider);
    _log.d('playback', 'resume done');
  }

  Future<void> stop() async {
    _log.i('playback', 'stop requested');
    _runId += 1;
    _playLoop = false;
    _paused = false;
    _skipCurrentWord = false;
    _unitSpeakInProgress = false;
    _replayCurrentUnitAfterResume = false;
    _activeSpeakProvider = TtsProviderType.local;
    await _ttsService.stop();
    _log.d('playback', 'stop done');
  }

  Future<void> skipCurrentWord() async {
    if (!_playLoop) return;
    _log.i('playback', 'skip current word requested');
    _skipCurrentWord = true;
    _replayCurrentUnitAfterResume = false;
    await _ttsService.stop();
    _log.d('playback', 'skip current word done');
  }

  Future<void> speakText(String text, PlayConfig config) async {
    final content = text.trim();
    if (content.isEmpty) return;
    _log.i(
      'playback',
      'speak single text',
      data: <String, Object?>{
        'provider': config.tts.provider.name,
        'textPreview': _preview(content),
      },
    );
    await _ttsService.speak(content, config.tts);
    _log.d('playback', 'speak single text done');
  }

  Future<void> _playSingleWord(
    WordEntry word,
    UnitChangeCallback? onUnitChanged,
    int runId,
  ) async {
    final config = _activeConfig;
    final queue = buildPlayQueue(word, config);
    _log.d(
      'playback',
      'word queue ready',
      data: <String, Object?>{
        'wordId': word.id,
        'word': word.word,
        'units': queue.length,
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
      _log.d(
        'playback',
        'unit start',
        data: <String, Object?>{
          'wordId': word.id,
          'word': word.word,
          'unitIndex': i + 1,
          'unitTotal': queue.length,
          'unitType': unit.type,
          'unitPreview': _preview(unit.text),
        },
      );
      onUnitChanged?.call(i + 1, queue.length, unit);
      _unitSpeakInProgress = true;
      try {
        final ttsConfig = _activeConfig.tts;
        _activeSpeakProvider = ttsConfig.provider;
        await _ttsService.speak(unit.text, ttsConfig);
        _log.d(
          'playback',
          'unit done',
          data: <String, Object?>{
            'wordId': word.id,
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

typedef VoidCallback = void Function();

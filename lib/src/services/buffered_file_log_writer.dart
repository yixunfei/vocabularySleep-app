import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

typedef LogFileResolver = Future<File?> Function({bool forceRefresh});

class BufferedFileLogWriter {
  factory BufferedFileLogWriter({
    required LogFileResolver resolveFile,
    required bool Function() isDisabled,
    required bool Function(Object error) shouldDisable,
    required void Function(Object error) disable,
  }) =>
      BufferedFileLogWriter._(resolveFile, isDisabled, shouldDisable, disable);

  BufferedFileLogWriter._(
    this._resolveFile,
    this._isDisabled,
    this._shouldDisable,
    this._disable,
  );

  static const int maxRetainedLines = 1024;
  static const int maxRetainedCharacters = 1024 * 1024;
  static const int _maxBatchLines = 128;
  static const int _maxBatchCharacters = 256 * 1024;

  final LogFileResolver _resolveFile;
  final bool Function() _isDisabled;
  final bool Function(Object error) _shouldDisable;
  final void Function(Object error) _disable;
  final List<_BufferedLogLine> _pending = <_BufferedLogLine>[];

  Future<void>? _drainFuture;
  int _pendingCharacters = 0;
  int _activeLines = 0;
  int _activeCharacters = 0;
  int _generation = 0;
  int _droppedLines = 0;
  int _writeBatchCount = 0;
  int _maxObservedRetainedLines = 0;
  bool _reportedBackpressure = false;

  void add({required String level, required String line}) {
    if (_isDisabled()) {
      return;
    }
    final entry = _BufferedLogLine(level: level, line: line);
    while (_wouldExceedCapacity(entry)) {
      if (!_dropOldestEligibleLine(entry.level)) {
        _recordDroppedLine();
        return;
      }
    }
    _pending.add(entry);
    _pendingCharacters += entry.characterCount;
    final retainedLines = _pending.length + _activeLines;
    if (retainedLines > _maxObservedRetainedLines) {
      _maxObservedRetainedLines = retainedLines;
    }
    _scheduleDrain();
  }

  Future<void> flush() async {
    while (_pending.isNotEmpty || _activeLines > 0) {
      _scheduleDrain();
      final drain = _drainFuture;
      if (drain == null) {
        return;
      }
      await drain;
    }
  }

  void reset() {
    _generation += 1;
    _pending.clear();
    _pendingCharacters = 0;
    _activeLines = 0;
    _activeCharacters = 0;
    _droppedLines = 0;
    _writeBatchCount = 0;
    _maxObservedRetainedLines = 0;
    _reportedBackpressure = false;
  }

  int get retainedLineCount => _pending.length + _activeLines;

  int get droppedLineCount => _droppedLines;

  int get writeBatchCount => _writeBatchCount;

  int get maxObservedRetainedLines => _maxObservedRetainedLines;

  bool _wouldExceedCapacity(_BufferedLogLine entry) {
    return _pending.length + _activeLines >= maxRetainedLines ||
        _pendingCharacters + _activeCharacters + entry.characterCount >
            maxRetainedCharacters;
  }

  bool _dropOldestEligibleLine(String incomingLevel) {
    if (_pending.isEmpty) {
      return false;
    }
    final incomingPriority = _priority(incomingLevel);
    var index = _pending.indexWhere(
      (entry) => _priority(entry.level) < incomingPriority,
    );
    if (index < 0) {
      index = _pending.indexWhere(
        (entry) => _priority(entry.level) == incomingPriority,
      );
    }
    if (index < 0) {
      return false;
    }
    final removed = _pending.removeAt(index);
    _pendingCharacters -= removed.characterCount;
    _recordDroppedLine();
    return true;
  }

  int _priority(String level) {
    return switch (level) {
      'ERROR' => 2,
      'WARN' => 1,
      _ => 0,
    };
  }

  void _recordDroppedLine() {
    _droppedLines += 1;
    if (_reportedBackpressure) {
      return;
    }
    _reportedBackpressure = true;
    debugPrint(
      '[AppLogService] file log buffer reached its limit; dropping older lower-priority lines',
    );
  }

  void _scheduleDrain() {
    if (_drainFuture != null || _pending.isEmpty || _isDisabled()) {
      return;
    }
    final generation = _generation;
    final future = Future<void>.microtask(() => _drain(generation));
    _drainFuture = future;
    unawaited(
      future.whenComplete(() {
        if (!identical(_drainFuture, future)) {
          return;
        }
        _drainFuture = null;
        if (_pending.isNotEmpty && !_isDisabled()) {
          _scheduleDrain();
        }
      }),
    );
  }

  Future<void> _drain(int generation) async {
    while (generation == _generation && !_isDisabled() && _pending.isNotEmpty) {
      final batch = _takeBatch();
      try {
        await _appendBatch(batch, generation);
      } finally {
        _activeLines = 0;
        _activeCharacters = 0;
      }
    }
  }

  List<_BufferedLogLine> _takeBatch() {
    var count = 0;
    var characters = 0;
    while (count < _pending.length && count < _maxBatchLines) {
      final nextCharacters = _pending[count].characterCount;
      if (count > 0 && characters + nextCharacters > _maxBatchCharacters) {
        break;
      }
      characters += nextCharacters;
      count += 1;
    }
    final batch = _pending.sublist(0, count);
    _pending.removeRange(0, count);
    _pendingCharacters -= characters;
    _activeLines = count;
    _activeCharacters = characters;
    return batch;
  }

  Future<void> _appendBatch(
    List<_BufferedLogLine> batch,
    int generation,
  ) async {
    final content = '${batch.map((entry) => entry.line).join('\n')}\n';
    try {
      final file = await _resolveFile();
      if (file == null || generation != _generation) {
        return;
      }
      await _write(file, content, generation);
    } catch (writeError, writeStack) {
      if (generation != _generation) {
        return;
      }
      if (_shouldDisable(writeError)) {
        _disableAndClear(writeError);
        return;
      }
      await _retryBatch(content, generation, writeError, writeStack);
    }
  }

  Future<void> _retryBatch(
    String content,
    int generation,
    Object writeError,
    StackTrace writeStack,
  ) async {
    try {
      final recoveredFile = await _resolveFile(forceRefresh: true);
      if (recoveredFile == null || generation != _generation) {
        return;
      }
      await _write(recoveredFile, content, generation);
    } catch (recoveryError, recoveryStack) {
      if (generation != _generation) {
        return;
      }
      if (_shouldDisable(recoveryError)) {
        _disableAndClear(recoveryError);
        return;
      }
      debugPrint('[AppLogService] write failed: $writeError\n$writeStack');
      debugPrint(
        '[AppLogService] recovery failed: $recoveryError\n$recoveryStack',
      );
    }
  }

  Future<void> _write(File file, String content, int generation) async {
    await file.writeAsString(content, mode: FileMode.append, flush: false);
    if (generation == _generation) {
      _writeBatchCount += 1;
    }
  }

  void _disableAndClear(Object error) {
    _disable(error);
    _pending.clear();
    _pendingCharacters = 0;
  }
}

class _BufferedLogLine {
  const _BufferedLogLine({required this.level, required this.line});

  final String level;
  final String line;

  int get characterCount => line.length + 1;
}

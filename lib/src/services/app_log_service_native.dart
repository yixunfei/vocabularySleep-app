import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'buffered_file_log_writer.dart';

class AppLogService {
  AppLogService._() {
    _writer = BufferedFileLogWriter(
      resolveFile: _ensureWritableFile,
      isDisabled: () => _fileLoggingDisabled,
      shouldDisable: _shouldDisableFileLogging,
      disable: _disableFileLogging,
    );
  }

  static final AppLogService instance = AppLogService._();
  static const int _maxPersistedLineCharacters = 64 * 1024;

  File? _file;
  Future<void>? _initFuture;
  late final BufferedFileLogWriter _writer;
  bool _fileLoggingDisabled = false;
  String? _fileLoggingDisableReason;
  bool _reportedDisabledState = false;

  Future<void> init() {
    _initFuture ??= _init();
    return _initFuture!;
  }

  Future<void> _init() async {
    _file = await _prepareLogFile();
  }

  Future<String?> getLogFilePath() async {
    await init();
    return _file?.path;
  }

  void d(String tag, String message, {Map<String, Object?>? data}) {
    if (!kDebugMode) {
      return;
    }
    _write('DEBUG', tag, message, data: data);
  }

  void i(String tag, String message, {Map<String, Object?>? data}) {
    _write('INFO', tag, message, data: data);
  }

  void w(String tag, String message, {Map<String, Object?>? data}) {
    _write('WARN', tag, message, data: data);
  }

  void e(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) {
    _write(
      'ERROR',
      tag,
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  void _write(
    String level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) {
    final now = DateTime.now();
    final payload = <String, Object?>{
      'time': now.toIso8601String(),
      'level': level,
      'tag': tag,
      'message': message,
      if (data != null && data.isNotEmpty) 'data': data,
      if (error != null) 'error': '$error',
      if (stackTrace != null) 'stack': '$stackTrace',
    };
    final line = _encodeLogLine(payload);
    debugPrint(line);
    if (level != 'DEBUG') {
      _writer.add(level: level, line: line);
    }
  }

  String _encodeLogLine(Map<String, Object?> payload) {
    String line;
    try {
      line = jsonEncode(payload);
    } catch (error) {
      line = jsonEncode(<String, Object?>{
        'time': payload['time'],
        'level': payload['level'],
        'tag': payload['tag'],
        'message': payload['message'],
        'data': '${payload['data']}',
        'encodingError': '$error',
      });
    }
    if (line.length <= _maxPersistedLineCharacters) {
      return line;
    }
    return jsonEncode(<String, Object?>{
      'time': payload['time'],
      'level': payload['level'],
      'tag': payload['tag'],
      'message': _truncate('${payload['message']}', 4096),
      if (payload['error'] != null)
        'error': _truncate('${payload['error']}', 8192),
      if (payload['stack'] != null)
        'stack': _truncate('${payload['stack']}', 32768),
      'truncated': true,
      'originalCharacters': line.length,
    });
  }

  String _truncate(String value, int maxCharacters) {
    if (value.length <= maxCharacters) {
      return value;
    }
    return '${value.substring(0, maxCharacters)}...';
  }

  Future<File?> _prepareLogFile() async {
    if (_fileLoggingDisabled) {
      return null;
    }
    try {
      final supportDir = await getApplicationSupportDirectory();
      final logDir = Directory(p.join(supportDir.path, 'logs'));
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      final file = File(p.join(logDir.path, _logFileNameFor(DateTime.now())));
      if (!await file.exists()) {
        await file.create(recursive: true);
      }
      return file;
    } catch (error) {
      if (_shouldDisableFileLogging(error)) {
        _disableFileLogging(error);
        return null;
      }
      rethrow;
    }
  }

  Future<File?> _ensureWritableFile({bool forceRefresh = false}) async {
    if (_fileLoggingDisabled) {
      return null;
    }
    if (forceRefresh) {
      _file = null;
      _initFuture = null;
    }
    await init();
    if (_fileLoggingDisabled) {
      return null;
    }
    final current = _file;
    final expectedName = _logFileNameFor(DateTime.now());
    final needsRefresh =
        current == null ||
        p.basename(current.path) != expectedName ||
        !await current.parent.exists() ||
        !await current.exists();
    if (needsRefresh) {
      _file = await _prepareLogFile();
      _initFuture = Future<void>.value();
    }
    return _file;
  }

  String _logFileNameFor(DateTime time) {
    final day = time.toIso8601String().substring(0, 10);
    return 'app-$day.log';
  }

  @visibleForTesting
  Future<void> flushForTest() => _writer.flush();

  @visibleForTesting
  int get retainedFileLogLineCount => _writer.retainedLineCount;

  @visibleForTesting
  int get droppedFileLogLineCount => _writer.droppedLineCount;

  @visibleForTesting
  int get fileLogWriteBatchCount => _writer.writeBatchCount;

  @visibleForTesting
  int get maxObservedRetainedFileLogLines => _writer.maxObservedRetainedLines;

  @visibleForTesting
  int get maxRetainedFileLogLines => BufferedFileLogWriter.maxRetainedLines;

  @visibleForTesting
  bool get isFileLoggingDisabled => _fileLoggingDisabled;

  @visibleForTesting
  String? get fileLoggingDisableReason => _fileLoggingDisableReason;

  @visibleForTesting
  void resetForTest() {
    _writer.reset();
    _file = null;
    _initFuture = null;
    _fileLoggingDisabled = false;
    _fileLoggingDisableReason = null;
    _reportedDisabledState = false;
  }

  bool _shouldDisableFileLogging(Object error) {
    if (error is MissingPluginException) {
      return true;
    }
    if (error is PlatformException) {
      final message = '${error.message ?? ''}${error.details ?? ''}';
      if (message.contains('path_provider') ||
          message.contains('getApplicationSupportDirectory')) {
        return true;
      }
    }
    final message = '$error';
    return message.contains('plugins.flutter.io/path_provider') ||
        message.contains('getApplicationSupportDirectory') ||
        message.contains('Binding has not yet been initialized');
  }

  void _disableFileLogging(Object error) {
    _fileLoggingDisabled = true;
    _fileLoggingDisableReason = '$error';
    _file = null;
    _initFuture = Future<void>.value();
    if (_reportedDisabledState) {
      return;
    }
    _reportedDisabledState = true;
    debugPrint('[AppLogService] persistent file logging disabled: $error');
  }
}

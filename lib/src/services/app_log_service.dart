import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppLogService {
  AppLogService._();

  static final AppLogService instance = AppLogService._();

  File? _file;
  Future<void>? _initFuture;
  Future<void> _queue = Future<void>.value();
  bool _fileLoggingDisabled = false;
  String? _fileLoggingDisableReason;
  bool _reportedDisabledState = false;
  int _writeGeneration = 0;

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
    final line = jsonEncode(payload);
    debugPrint(line);
    final generation = _writeGeneration;

    _queue = _queue.then((_) async {
      if (_fileLoggingDisabled || _writeGeneration != generation) {
        return;
      }
      try {
        final file = await _ensureWritableFile();
        if (file == null || _writeGeneration != generation) {
          return;
        }
        await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
      } catch (writeError, writeStack) {
        if (_shouldDisableFileLogging(writeError)) {
          _disableFileLogging(writeError);
          return;
        }
        try {
          final recoveredFile = await _ensureWritableFile(forceRefresh: true);
          if (recoveredFile == null || _writeGeneration != generation) {
            return;
          }
          await recoveredFile.writeAsString(
            '$line\n',
            mode: FileMode.append,
            flush: true,
          );
        } catch (recoveryError, recoveryStack) {
          if (_shouldDisableFileLogging(recoveryError)) {
            _disableFileLogging(recoveryError);
            return;
          }
          debugPrint('[AppLogService] write failed: $writeError\n$writeStack');
          debugPrint(
            '[AppLogService] recovery failed: $recoveryError\n$recoveryStack',
          );
        }
      }
    });
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
  Future<void> flushForTest() => _queue;

  @visibleForTesting
  bool get isFileLoggingDisabled => _fileLoggingDisabled;

  @visibleForTesting
  String? get fileLoggingDisableReason => _fileLoggingDisableReason;

  @visibleForTesting
  void resetForTest() {
    _writeGeneration += 1;
    _file = null;
    _initFuture = null;
    _queue = Future<void>.value();
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
        message.contains('getApplicationSupportDirectory');
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

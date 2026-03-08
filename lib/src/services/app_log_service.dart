import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppLogService {
  AppLogService._();

  static final AppLogService instance = AppLogService._();

  File? _file;
  Future<void>? _initFuture;
  Future<void> _queue = Future<void>.value();

  Future<void> init() {
    _initFuture ??= _init();
    return _initFuture!;
  }

  Future<void> _init() async {
    final supportDir = await getApplicationSupportDirectory();
    final logDir = Directory(p.join(supportDir.path, 'logs'));
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    final day = DateTime.now().toIso8601String().substring(0, 10);
    _file = File(p.join(logDir.path, 'app-$day.log'));
    if (!await _file!.exists()) {
      await _file!.create(recursive: true);
    }
    i('logger', 'log file ready', data: <String, Object?>{'path': _file!.path});
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

    _queue = _queue.then((_) async {
      try {
        await init();
        final file = _file;
        if (file == null) return;
        await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
      } catch (writeError, writeStack) {
        debugPrint(
          '[AppLogService] write failed: $writeError\n$writeStack',
        );
      }
    });
  }
}

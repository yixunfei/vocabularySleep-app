import 'package:flutter/foundation.dart';

class AppLogService {
  AppLogService._();

  static final AppLogService instance = AppLogService._();

  Future<void> init() async {}
  Future<String?> getLogFilePath() async => null;

  void d(String tag, String message, {Map<String, Object?>? data}) {
    if (kDebugMode) _write('DEBUG', tag, message, data: data);
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
    debugPrint(
      <String, Object?>{
        'level': level,
        'tag': tag,
        'message': message,
        if (error != null) 'error': '$error',
        if (stackTrace != null) 'stack': '$stackTrace',
        if (data != null && data.isNotEmpty) 'data': data,
      }.toString(),
    );
  }

  Future<void> flushForTest() async {}
  int get retainedFileLogLineCount => 0;
  int get droppedFileLogLineCount => 0;
  int get fileLogWriteBatchCount => 0;
  int get maxObservedRetainedFileLogLines => 0;
  int get maxRetainedFileLogLines => 0;
  bool get isFileLoggingDisabled => true;
  String? get fileLoggingDisableReason => 'web-console-only';
  void resetForTest() {}
}

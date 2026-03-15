import 'package:flutter/services.dart';

class SystemSpeechCommandResult {
  const SystemSpeechCommandResult({
    required this.success,
    this.errorCode,
    this.errorMessage,
  });

  final bool success;
  final String? errorCode;
  final String? errorMessage;

  factory SystemSpeechCommandResult.fromMap(Map<Object?, Object?>? raw) {
    final map = raw ?? const <Object?, Object?>{};
    return SystemSpeechCommandResult(
      success: map['success'] as bool? ?? false,
      errorCode: _readString(map['errorCode']),
      errorMessage: _readString(map['errorMessage']),
    );
  }
}

class SystemSpeechRecognitionResult extends SystemSpeechCommandResult {
  const SystemSpeechRecognitionResult({
    required super.success,
    this.text,
    this.locale,
    super.errorCode,
    super.errorMessage,
  });

  final String? text;
  final String? locale;

  factory SystemSpeechRecognitionResult.fromMap(Map<Object?, Object?>? raw) {
    final map = raw ?? const <Object?, Object?>{};
    return SystemSpeechRecognitionResult(
      success: map['success'] as bool? ?? false,
      text: _readString(map['text']),
      locale: _readString(map['locale']),
      errorCode: _readString(map['errorCode']),
      errorMessage: _readString(map['errorMessage']),
    );
  }
}

abstract interface class SystemSpeechService {
  Future<SystemSpeechCommandResult> startListening({String? languageTag});

  Future<SystemSpeechRecognitionResult> stopListening();

  Future<void> cancelListening();

  Future<void> dispose();
}

class PlatformSystemSpeechService implements SystemSpeechService {
  const PlatformSystemSpeechService();

  static const MethodChannel _channel = MethodChannel(
    'vocabulary_sleep/system_speech',
  );

  @override
  Future<SystemSpeechCommandResult> startListening({
    String? languageTag,
  }) async {
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'startListening',
        <String, Object?>{
          if ((languageTag ?? '').trim().isNotEmpty)
            'languageTag': languageTag!.trim(),
        },
      );
      return SystemSpeechCommandResult.fromMap(raw);
    } on MissingPluginException {
      return const SystemSpeechCommandResult(
        success: false,
        errorCode: 'unsupported',
      );
    } catch (error) {
      return SystemSpeechCommandResult(
        success: false,
        errorCode: 'failed',
        errorMessage: '$error',
      );
    }
  }

  @override
  Future<SystemSpeechRecognitionResult> stopListening() async {
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'stopListening',
      );
      return SystemSpeechRecognitionResult.fromMap(raw);
    } on MissingPluginException {
      return const SystemSpeechRecognitionResult(
        success: false,
        errorCode: 'unsupported',
      );
    } catch (error) {
      return SystemSpeechRecognitionResult(
        success: false,
        errorCode: 'failed',
        errorMessage: '$error',
      );
    }
  }

  @override
  Future<void> cancelListening() async {
    try {
      await _channel.invokeMethod<void>('cancelListening');
    } on MissingPluginException {
      // Ignore on unsupported platforms.
    } catch (_) {
      // Best-effort cleanup.
    }
  }

  @override
  Future<void> dispose() => cancelListening();
}

String? _readString(Object? value) {
  final text = '$value'.trim();
  return text.isEmpty || text == 'null' ? null : text;
}

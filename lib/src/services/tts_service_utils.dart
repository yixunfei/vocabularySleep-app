part of 'tts_service.dart';

extension TtsServiceUtils on TtsService {
  Future<T?> _runOp<T>(
    String operation,
    Future<T> Function() task, {
    Map<String, Object?> data = const <String, Object?>{},
    bool swallowError = false,
  }) async {
    final watch = Stopwatch()..start();
    try {
      final result = await task();
      return result;
    } catch (error, stackTrace) {
      if (swallowError) {
        _log.w(
          'tts',
          '$operation.failed(swallowed)',
          data: <String, Object?>{
            ...data,
            'elapsedMs': watch.elapsedMilliseconds,
            'error': '$error',
          },
        );
        return null;
      }
      _log.e(
        'tts',
        '$operation.failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          ...data,
          'elapsedMs': watch.elapsedMilliseconds,
        },
      );
      rethrow;
    }
  }

  String _preview(String text) {
    final compact = text.replaceAll('\n', ' ').trim();
    if (compact.length <= 96) return compact;
    return '${compact.substring(0, 96)}...';
  }
}

class _ApiSpeakInterrupted implements Exception {
  const _ApiSpeakInterrupted(this.reason);

  final String reason;

  @override
  String toString() => 'ApiSpeakInterrupted($reason)';
}

class _LocalTtsVoice {
  const _LocalTtsVoice({required this.name, required this.locale});

  final String name;
  final String locale;

  String get localeKey => _normalizedLocaleKey(locale);
  String get primaryLanguageCode => _primaryLanguageCode(locale);
  String get signature => '$localeKey::${name.toLowerCase()}';

  Map<String, String> toPayload() => <String, String>{
    'name': name,
    'locale': locale,
  };

  static _LocalTtsVoice? fromRaw(dynamic raw) {
    if (raw is Map) {
      final name = raw['name']?.toString().trim() ?? '';
      final locale = raw['locale']?.toString().trim() ?? '';
      if (name.isEmpty) {
        return null;
      }
      return _LocalTtsVoice(name: name, locale: locale);
    }
    final name = '$raw'.trim();
    if (name.isEmpty) {
      return null;
    }
    return _LocalTtsVoice(name: name, locale: '');
  }
}

class _ResolvedWindowsLocalVoiceTarget {
  const _ResolvedWindowsLocalVoiceTarget._({
    required this.reason,
    this.voice,
    this.language,
  });

  final String reason;
  final _LocalTtsVoice? voice;
  final String? language;

  String get signature => voice != null
      ? 'voice:${voice!.signature}'
      : 'lang:${_normalizedLocaleKey(language ?? '')}';

  factory _ResolvedWindowsLocalVoiceTarget.voice(
    _LocalTtsVoice voice, {
    required String reason,
  }) {
    return _ResolvedWindowsLocalVoiceTarget._(reason: reason, voice: voice);
  }

  factory _ResolvedWindowsLocalVoiceTarget.language(
    String language, {
    required String reason,
  }) {
    return _ResolvedWindowsLocalVoiceTarget._(
      reason: reason,
      language: language,
    );
  }
}

String _normalizedLocaleKey(String raw) =>
    raw.trim().replaceAll('_', '-').toLowerCase();

String _primaryLanguageCode(String raw) {
  final key = _normalizedLocaleKey(raw);
  if (key.isEmpty) {
    return '';
  }
  final separator = key.indexOf('-');
  if (separator < 0) {
    return key;
  }
  return key.substring(0, separator);
}

bool _isHanRune(int rune) =>
    (rune >= 0x4E00 && rune <= 0x9FFF) ||
    (rune >= 0x3400 && rune <= 0x4DBF) ||
    (rune >= 0xF900 && rune <= 0xFAFF);

bool _isKanaRune(int rune) =>
    (rune >= 0x3040 && rune <= 0x309F) || (rune >= 0x30A0 && rune <= 0x30FF);

bool _isLatinRune(int rune) =>
    (rune >= 0x0041 && rune <= 0x005A) || (rune >= 0x0061 && rune <= 0x007A);

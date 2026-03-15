import '../i18n/app_i18n.dart';

const List<String> kAsrLanguagePresetOptions = <String>[
  'auto',
  'en-US',
  'en-GB',
  'zh-CN',
  'zh-TW',
  'ja-JP',
  'ko-KR',
  'de-DE',
  'fr-FR',
  'es-ES',
  'es-MX',
  'pt-BR',
  'it-IT',
  'ru-RU',
];

String normalizeAsrLanguageTag(String? raw, {bool emptyAsAuto = true}) {
  final value = (raw ?? '').trim().replaceAll('_', '-');
  final lower = value.toLowerCase();
  if (lower.isEmpty) {
    return emptyAsAuto ? 'auto' : '';
  }
  return switch (lower) {
    'auto' || 'system' => 'auto',
    'en' || 'en-us' => 'en-US',
    'en-gb' => 'en-GB',
    'zh' || 'zh-cn' || 'zh-hans' => 'zh-CN',
    'zh-tw' || 'zh-hk' || 'zh-hant' => 'zh-TW',
    'ja' || 'ja-jp' => 'ja-JP',
    'ko' || 'ko-kr' => 'ko-KR',
    'de' || 'de-de' => 'de-DE',
    'fr' || 'fr-fr' => 'fr-FR',
    'es' || 'es-es' => 'es-ES',
    'es-mx' => 'es-MX',
    'pt' || 'pt-br' => 'pt-BR',
    'it' || 'it-it' => 'it-IT',
    'ru' || 'ru-ru' => 'ru-RU',
    _ => _canonicalizeLocaleTag(value),
  };
}

String resolveAsrLanguageOption(String? raw) {
  final normalized = normalizeAsrLanguageTag(raw);
  return kAsrLanguagePresetOptions.contains(normalized) ? normalized : 'custom';
}

String asrLanguageLabel(AppI18n i18n, String? raw) {
  final normalized = normalizeAsrLanguageTag(raw);
  return switch (normalized) {
    'auto' => _systemDefaultLanguageLabel(i18n),
    'en-US' => 'English (US)',
    'en-GB' => 'English (UK)',
    'zh-CN' => '中文（简体）',
    'zh-TW' => '中文（繁体）',
    'ja-JP' => '日本語',
    'ko-KR' => '한국어',
    'de-DE' => 'Deutsch',
    'fr-FR' => 'Francais',
    'es-ES' => 'Espanol',
    'es-MX' => 'Espanol (MX)',
    'pt-BR' => 'Portugues (BR)',
    'it-IT' => 'Italiano',
    'ru-RU' => 'Русский',
    _ =>
      (raw ?? '').trim().isEmpty
          ? _systemDefaultLanguageLabel(i18n)
          : normalized,
  };
}

String normalizeOfflineAsrLanguage(
  String? raw, {
  bool englishOnlyModel = false,
}) {
  if (englishOnlyModel) {
    return 'en';
  }

  final normalized = normalizeAsrLanguageTag(raw);
  if (normalized == 'auto') {
    return 'en';
  }

  final baseLanguage = normalized.toLowerCase().split('-').first;
  if (baseLanguage.isEmpty) {
    return 'en';
  }
  return switch (baseLanguage) {
    'zh' ||
    'en' ||
    'ja' ||
    'ko' ||
    'de' ||
    'fr' ||
    'es' ||
    'pt' ||
    'it' ||
    'ru' => baseLanguage,
    _ => baseLanguage,
  };
}

String _canonicalizeLocaleTag(String raw) {
  final parts = raw
      .split('-')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return raw.trim();
  }
  if (parts.length == 1) {
    return parts.first.toLowerCase();
  }

  final normalized = <String>[parts.first.toLowerCase()];
  for (final part in parts.skip(1)) {
    if (part.length <= 3) {
      normalized.add(part.toUpperCase());
    } else {
      normalized.add(
        '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      );
    }
  }
  return normalized.join('-');
}

String _systemDefaultLanguageLabel(AppI18n i18n) {
  return switch (AppI18n.normalizeLanguageCode(i18n.languageCode)) {
    'zh' => '系统默认语言',
    'ja' => 'システム既定',
    'de' => 'Systemstandard',
    'fr' => 'Langue du systeme',
    'es' => 'Idioma del sistema',
    'ru' => 'Язык системы',
    _ => 'System default',
  };
}

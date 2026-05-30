import 'app_i18n_catalog.dart';

class AppI18n {
  AppI18n(this.languageCode);

  final String languageCode;

  static const List<String> supportedLanguages = <String>[
    'zh',
    'en',
    'ja',
    'de',
    'fr',
    'es',
    'ru',
  ];

  static final RegExp _templateTokenPattern = RegExp(
    r'\{([A-Za-z_][A-Za-z0-9_]*)\}|\$\{([^}]*)\}|\$([A-Za-z_][A-Za-z0-9_]*)',
  );

  static String normalizeLanguageCode(String code) {
    final lower = code.trim().toLowerCase();
    if (lower.startsWith('zh')) return 'zh';
    if (lower.startsWith('en')) return 'en';
    if (lower.startsWith('ja')) return 'ja';
    if (lower.startsWith('de')) return 'de';
    if (lower.startsWith('fr')) return 'fr';
    if (lower.startsWith('es')) return 'es';
    if (lower.startsWith('ru')) return 'ru';
    return 'en';
  }

  String languageName(String code) {
    return t('languageName.${normalizeLanguageCode(code)}');
  }

  String t(
    String key, {
    Map<String, Object?> params = const <String, Object?>{},
  }) {
    final lang = normalizeLanguageCode(languageCode);
    final value =
        AppI18nCatalog.lookup(lang, key) ??
        AppI18nCatalog.lookup('en', key) ??
        AppI18nCatalog.lookup('zh', key) ??
        _humanizeKey(key);
    return _applyParams(value, params);
  }

  String _applyParams(String template, Map<String, Object?> params) {
    if (params.isEmpty) {
      return template;
    }
    return template.replaceAllMapped(_templateTokenPattern, (match) {
      final key = match.group(1) ?? match.group(2) ?? match.group(3);
      if (key == null || !params.containsKey(key)) {
        return match.group(0) ?? '';
      }
      return '${params[key] ?? ''}';
    });
  }

  String _humanizeKey(String key) {
    final lastSegment = key.split('.').last;
    final withSpaces = lastSegment
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m.group(1)} ${m.group(2)}',
        );
    if (withSpaces.isEmpty) return key;
    return withSpaces[0].toUpperCase() + withSpaces.substring(1);
  }
}

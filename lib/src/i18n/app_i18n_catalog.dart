import 'dart:convert';

import 'package:flutter/services.dart';

class AppI18nCatalog {
  AppI18nCatalog._();

  static const List<String> _languages = <String>[
    'zh',
    'en',
    'ja',
    'de',
    'fr',
    'es',
    'ru',
  ];

  static const String _assetPrefix = 'lib/l10n/catalog';

  static Map<String, Map<String, String>> _tables =
      const <String, Map<String, String>>{};

  static bool get isLoaded => _tables.isNotEmpty;

  static Future<void> loadFromAssets({AssetBundle? bundle}) async {
    final assetBundle = bundle ?? rootBundle;
    final nextTables = <String, Map<String, String>>{};

    for (final language in _languages) {
      try {
        final raw = await assetBundle.loadString(
          '$_assetPrefix/app_texts_$language.json',
        );
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, Object?>) {
          continue;
        }
        nextTables[language] = <String, String>{
          for (final entry in decoded.entries)
            if (!entry.key.startsWith('@@') && entry.value is String)
              entry.key: entry.value! as String,
        };
      } on Object {
        // Keep AppI18n usable when assets are unavailable in tests or recovery.
      }
    }

    _tables = Map<String, Map<String, String>>.unmodifiable(
      nextTables.map(
        (language, table) =>
            MapEntry(language, Map<String, String>.unmodifiable(table)),
      ),
    );
  }

  static String? lookup(String languageCode, String key) {
    final value = _tables[languageCode]?[key];
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  static void installForTesting(Map<String, Map<String, String>> tables) {
    _tables = Map<String, Map<String, String>>.unmodifiable(
      tables.map(
        (language, table) =>
            MapEntry(language, Map<String, String>.unmodifiable(table)),
      ),
    );
  }

  static void resetForTesting() {
    _tables = const <String, Map<String, String>>{};
  }
}

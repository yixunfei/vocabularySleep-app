import 'package:csv/csv.dart';
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

  static const String _catalogAsset = 'lib/l10n/catalog/app_texts.csv';

  static Map<String, Map<String, String>> _tables =
      const <String, Map<String, String>>{};

  static bool get isLoaded => _tables.isNotEmpty;

  static Future<void> loadFromAssets({AssetBundle? bundle}) async {
    final assetBundle = bundle ?? rootBundle;
    final nextTables = <String, Map<String, String>>{
      for (final language in _languages) language: <String, String>{},
    };

    try {
      final raw = await assetBundle.loadString(_catalogAsset);
      final rows = csv.decode(raw);
      if (rows.isNotEmpty) {
        final header = rows.first
            .map((cell) => cell?.toString().trim() ?? '')
            .toList(growable: false);
        final keyIndex = header.indexOf('key');
        if (keyIndex >= 0) {
          final supportedLanguages = _languages.toSet();
          final languageIndexes = <String, int>{
            for (final (index, column) in header.indexed)
              if (supportedLanguages.contains(column)) column: index,
          };
          for (final row in rows.skip(1)) {
            if (row.length <= keyIndex) {
              continue;
            }
            final key = _csvCell(row, keyIndex).trim();
            if (key.isEmpty || key.startsWith('@@')) {
              continue;
            }
            for (final entry in languageIndexes.entries) {
              final value = _csvCell(row, entry.value);
              if (value.isNotEmpty) {
                nextTables[entry.key]![key] = value;
              }
            }
          }
        }
      }
    } on Object {
      // Keep AppI18n usable when assets are unavailable in tests or recovery.
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

  static String _csvCell(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) {
      return '';
    }
    final value = row[index];
    return value == null ? '' : value.toString();
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

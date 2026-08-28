import 'dart:convert';
import 'dart:isolate';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum AppI18nCatalogLoadStage { assetRead, parse }

final class AppI18nCatalogLoadException implements Exception {
  const AppI18nCatalogLoadException({
    required this.stage,
    required this.assetPath,
    required this.cause,
    required this.causeStackTrace,
  });

  final AppI18nCatalogLoadStage stage;
  final String assetPath;
  final Object cause;
  final StackTrace causeStackTrace;

  @override
  String toString() {
    return 'AppI18nCatalogLoadException('
        'stage: ${stage.name}, assetPath: $assetPath, cause: $cause)';
  }
}

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

  static const String assetPath = 'lib/l10n/catalog/app_texts.csv';

  static Map<String, Map<String, String>> _tables =
      const <String, Map<String, String>>{};

  static bool get isLoaded => _tables.isNotEmpty;

  static Future<void> loadFromAssets({AssetBundle? bundle}) async {
    final assetBundle = bundle ?? rootBundle;
    late final ByteData assetData;
    try {
      assetData = await assetBundle.load(assetPath);
    } on Object catch (error, stackTrace) {
      throw AppI18nCatalogLoadException(
        stage: AppI18nCatalogLoadStage.assetRead,
        assetPath: assetPath,
        cause: error,
        causeStackTrace: stackTrace,
      );
    }

    final bytes = assetData.buffer.asUint8List(
      assetData.offsetInBytes,
      assetData.lengthInBytes,
    );
    try {
      final nextTables = await compute(
        _parseCatalogInWorker,
        TransferableTypedData.fromList(<Uint8List>[bytes]),
        debugLabel: 'app-i18n-catalog-parse',
      );
      _tables = nextTables;
    } on Object catch (error, stackTrace) {
      throw AppI18nCatalogLoadException(
        stage: AppI18nCatalogLoadStage.parse,
        assetPath: assetPath,
        cause: error,
        causeStackTrace: stackTrace,
      );
    }
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

Map<String, Map<String, String>> _parseCatalogInWorker(
  TransferableTypedData encodedCatalog,
) {
  final bytes = encodedCatalog.materialize().asUint8List();
  final raw = utf8.decode(bytes, allowMalformed: false);
  if (raw.trim().isEmpty) {
    throw const FormatException('The i18n catalog is empty.');
  }

  final rows = csv.decode(raw);
  if (rows.isEmpty) {
    throw const FormatException('The i18n catalog has no rows.');
  }

  final header = rows.first
      .map((cell) => cell?.toString().trim() ?? '')
      .toList(growable: false);
  if (header.isNotEmpty && header.first.startsWith('\ufeff')) {
    header[0] = header.first.substring(1);
  }

  final requiredColumns = <String>['key', ...AppI18nCatalog._languages];
  final missingColumns = requiredColumns
      .where((column) => !header.contains(column))
      .toList(growable: false);
  if (missingColumns.isNotEmpty) {
    throw FormatException(
      'The i18n catalog is missing columns: ${missingColumns.join(', ')}.',
    );
  }

  final keyIndex = header.indexOf('key');
  final languageIndexes = <String, int>{
    for (final language in AppI18nCatalog._languages)
      language: header.indexOf(language),
  };
  final nextTables = <String, Map<String, String>>{
    for (final language in AppI18nCatalog._languages)
      language: <String, String>{},
  };
  var validKeyCount = 0;
  var translatedValueCount = 0;

  for (final row in rows.skip(1)) {
    final key = _csvCell(row, keyIndex).trim();
    if (key.isEmpty || key.startsWith('@@')) {
      continue;
    }
    validKeyCount++;
    for (final entry in languageIndexes.entries) {
      final value = _csvCell(row, entry.value);
      if (value.isEmpty) {
        continue;
      }
      nextTables[entry.key]![key] = value;
      translatedValueCount++;
    }
  }

  if (validKeyCount == 0 || translatedValueCount == 0) {
    throw const FormatException(
      'The i18n catalog has no usable translation entries.',
    );
  }
  return nextTables;
}

String _csvCell(List<dynamic> row, int index) {
  if (index < 0 || index >= row.length) {
    return '';
  }
  final value = row[index];
  return value == null ? '' : value.toString();
}

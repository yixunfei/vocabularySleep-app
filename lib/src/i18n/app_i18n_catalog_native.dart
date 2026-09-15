import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'app_i18n_catalog.dart';

Future<Map<String, Map<String, String>>> parseCatalogBytes(
  Uint8List bytes,
) async {
  final raw = utf8.decode(bytes, allowMalformed: false);
  return compute(_parseCatalogTextInWorker, raw);
}

Map<String, Map<String, String>> _parseCatalogTextInWorker(String raw) {
  return parseCatalogText(raw);
}

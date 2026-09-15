import 'dart:convert';
import 'dart:typed_data';

import 'app_i18n_catalog.dart';

Future<Map<String, Map<String, String>>> parseCatalogBytes(
  Uint8List bytes,
) async {
  return parseCatalogText(utf8.decode(bytes, allowMalformed: false));
}

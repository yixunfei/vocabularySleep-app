import 'dart:typed_data';

import 'app_i18n_catalog_web.dart'
    if (dart.library.io) 'app_i18n_catalog_native.dart'
    as platform;

Future<Map<String, Map<String, String>>> parseCatalogBytes(Uint8List bytes) {
  return platform.parseCatalogBytes(bytes);
}

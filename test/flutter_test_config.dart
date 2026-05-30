import 'dart:async';

import 'package:vocabulary_sleep_app/src/i18n/app_i18n_catalog.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await AppI18nCatalog.loadFromAssets();
  await testMain();
}

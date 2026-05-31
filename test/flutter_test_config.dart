import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/i18n/app_i18n_catalog.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await AppI18nCatalog.loadFromAssets();
  await testMain();
}

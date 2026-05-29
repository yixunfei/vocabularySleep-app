import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/i18n/app_i18n.dart';
import 'package:vocabulary_sleep_app/src/i18n/app_i18n_catalog.dart';

void main() {
  tearDown(AppI18nCatalog.resetForTesting);

  test('uses loaded JSON catalog before built-in maps', () {
    AppI18nCatalog.installForTesting(<String, Map<String, String>>{
      'en': <String, String>{'play': 'JSON Play'},
    });

    expect(AppI18n('en').t('play'), 'JSON Play');
  });

  test('falls back through catalog locales and keeps placeholders', () {
    AppI18nCatalog.installForTesting(<String, Map<String, String>>{
      'en': <String, String>{'greeting': 'Hello {name}'},
      'zh': <String, String>{'fallbackOnly': '备用 {name}'},
    });

    expect(
      AppI18n('ja').t('greeting', params: <String, Object?>{'name': 'Mina'}),
      'Hello Mina',
    );
    expect(
      AppI18n('de').t('fallbackOnly', params: <String, Object?>{'name': '阿鱼'}),
      '备用 阿鱼',
    );
  });
}

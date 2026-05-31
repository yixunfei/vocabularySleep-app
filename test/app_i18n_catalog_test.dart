import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/i18n/app_i18n.dart';
import 'package:vocabulary_sleep_app/src/i18n/app_i18n_catalog.dart';

void main() {
  tearDown(AppI18nCatalog.resetForTesting);

  test('reads text from the installed catalog table', () {
    AppI18nCatalog.installForTesting(<String, Map<String, String>>{
      'en': <String, String>{'screen.title': 'JSON title'},
    });

    expect(AppI18n('en').t('screen.title'), 'JSON title');
  });

  test('loads text from the single CSV catalog asset', () async {
    await AppI18nCatalog.loadFromAssets(
      bundle: _StringAssetBundle(<String, String>{
        'lib/l10n/catalog/app_texts.csv':
            'key,zh,en\n'
            'screen.title,标题,Title\n'
            'message.saved,"已保存 {count} 项","Saved {count} items"\n'
            'quoted,"带逗号, 和引号 ""x""","Comma, and quote ""x"""',
      }),
    );

    expect(AppI18n('zh').t('screen.title'), '标题');
    expect(
      AppI18n('en').t('message.saved', params: <String, Object?>{'count': 3}),
      'Saved 3 items',
    );
    expect(AppI18n('zh').t('quoted'), '带逗号, 和引号 "x"');
  });

  test('falls back from requested language to English then Chinese', () {
    AppI18nCatalog.installForTesting(<String, Map<String, String>>{
      'en': <String, String>{'englishOnly': 'English fallback'},
      'zh': <String, String>{'chineseOnly': '中文兜底'},
    });

    expect(AppI18n('ja').t('englishOnly'), 'English fallback');
    expect(AppI18n('de').t('chineseOnly'), '中文兜底');
  });

  test('substitutes named placeholders without source-text lookup', () {
    AppI18nCatalog.installForTesting(<String, Map<String, String>>{
      'en': <String, String>{'message.saved': 'Saved {count} items for {name}'},
    });

    expect(
      AppI18n('en').t(
        'message.saved',
        params: <String, Object?>{'count': 3, 'name': 'Mina'},
      ),
      'Saved 3 items for Mina',
    );
  });

  test('reset clears test catalog tables', () {
    AppI18nCatalog.installForTesting(<String, Map<String, String>>{
      'en': <String, String>{'temporary.key': 'Temporary'},
    });
    expect(AppI18n('en').t('temporary.key'), 'Temporary');

    AppI18nCatalog.resetForTesting();

    expect(AppI18n('en').t('temporary.key'), 'Key');
  });
}

class _StringAssetBundle extends CachingAssetBundle {
  _StringAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final value = assets[key];
    if (value == null) {
      throw StateError('Missing test asset: $key');
    }
    final bytes = Uint8List.fromList(utf8.encode(value));
    return ByteData.sublistView(bytes);
  }
}

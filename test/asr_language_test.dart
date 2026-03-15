import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/i18n/app_i18n.dart';
import 'package:vocabulary_sleep_app/src/utils/asr_language.dart';

void main() {
  group('ASR language helpers', () {
    test('normalizes short language codes to full locale tags', () {
      expect(normalizeAsrLanguageTag('en'), 'en-US');
      expect(normalizeAsrLanguageTag('zh'), 'zh-CN');
      expect(normalizeAsrLanguageTag('pt'), 'pt-BR');
      expect(normalizeAsrLanguageTag('ru'), 'ru-RU');
    });

    test('treats auto and system as system default', () {
      expect(normalizeAsrLanguageTag('auto'), 'auto');
      expect(normalizeAsrLanguageTag('system'), 'auto');
      expect(asrLanguageLabel(AppI18n('en'), 'auto'), 'System default');
    });

    test('keeps unsupported presets in custom mode', () {
      expect(resolveAsrLanguageOption('th-TH'), 'custom');
      expect(resolveAsrLanguageOption('en-US'), 'en-US');
    });

    test('forces english for english-only offline models', () {
      expect(
        normalizeOfflineAsrLanguage('zh-CN', englishOnlyModel: true),
        'en',
      );
      expect(normalizeOfflineAsrLanguage('es-MX'), 'es');
    });
  });
}

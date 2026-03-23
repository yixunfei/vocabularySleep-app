import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/language_detector.dart';

void main() {
  group('LanguageDetector', () {
    test('detects English text', () {
      expect(LanguageDetector.detectLanguage('Hello world'), 'en');
      expect(LanguageDetector.detectLanguage('This is a test'), 'en');
      expect(
        LanguageDetector.detectLanguage('The quick brown fox jumps over the lazy dog'),
        'en',
      );
    });

    test('detects Chinese text', () {
      expect(LanguageDetector.detectLanguage('你好世界'), 'zh');
      expect(LanguageDetector.detectLanguage('这是一个测试'), 'zh');
      expect(LanguageDetector.detectLanguage('中文测试文本'), 'zh');
    });

    test('detects Japanese text', () {
      expect(LanguageDetector.detectLanguage('こんにちは'), 'ja');
      expect(LanguageDetector.detectLanguage('これはテストです'), 'ja');
      expect(LanguageDetector.detectLanguage('ひらがなとカタカナ'), 'ja');
    });

    test('detects Russian text', () {
      expect(LanguageDetector.detectLanguage('Привет мир'), 'ru');
      expect(LanguageDetector.detectLanguage('Это тест'), 'ru');
      expect(LanguageDetector.detectLanguage('Русский текст'), 'ru');
    });

    test('detects German text', () {
      expect(LanguageDetector.detectLanguage('Hallo Welt'), 'de');
      expect(LanguageDetector.detectLanguage('Das ist ein Test'), 'de');
      expect(LanguageDetector.detectLanguage('Ich möchte Deutsch lernen'), 'de');
      expect(LanguageDetector.detectLanguage('Der die das und für'), 'de');
    });

    test('detects French text', () {
      expect(LanguageDetector.detectLanguage('Bonjour le monde'), 'fr');
      expect(LanguageDetector.detectLanguage('C\'est un test'), 'fr');
      expect(LanguageDetector.detectLanguage('Je suis étudiant'), 'fr');
      expect(LanguageDetector.detectLanguage('Le la les et pour'), 'fr');
    });

    test('detects Spanish text', () {
      expect(LanguageDetector.detectLanguage('Hola mundo'), 'es');
      expect(LanguageDetector.detectLanguage('Esto es una prueba'), 'es');
      expect(LanguageDetector.detectLanguage('¿Cómo estás?'), 'es');
      expect(LanguageDetector.detectLanguage('El la los y para'), 'es');
    });

    test('handles mixed language text', () {
      // 中英混合，中文占主导
      expect(LanguageDetector.detectLanguage('你好 Hello 世界'), 'zh');

      // 英文占主导
      expect(
        LanguageDetector.detectLanguage('Hello 你好 world test example'),
        'en',
      );
    });

    test('handles empty or whitespace text', () {
      expect(LanguageDetector.detectLanguage(''), 'en');
      expect(LanguageDetector.detectLanguage('   '), 'en');
      expect(LanguageDetector.detectLanguage('\n\t'), 'en');
    });

    test('handles numbers and punctuation', () {
      expect(LanguageDetector.detectLanguage('123 456'), 'en');
      expect(LanguageDetector.detectLanguage(r'!@#$%'), 'en');
    });

    test('gets correct language names', () {
      expect(LanguageDetector.getLanguageName('en'), 'English');
      expect(LanguageDetector.getLanguageName('zh'), '中文');
      expect(LanguageDetector.getLanguageName('ja'), '日本語');
      expect(LanguageDetector.getLanguageName('de'), 'Deutsch');
      expect(LanguageDetector.getLanguageName('fr'), 'Français');
      expect(LanguageDetector.getLanguageName('es'), 'Español');
      expect(LanguageDetector.getLanguageName('ru'), 'Русский');
    });

    test('recommends voice for language', () {
      final voices = [
        'en-US-Male',
        'en-GB-Female',
        'zh-CN-Male',
        'ja-JP-Female',
        'de-DE-Male',
      ];

      expect(
        LanguageDetector.recommendVoiceForLanguage('en', voices),
        'en-US-Male',
      );
      expect(
        LanguageDetector.recommendVoiceForLanguage('zh', voices),
        'zh-CN-Male',
      );
      expect(
        LanguageDetector.recommendVoiceForLanguage('ja', voices),
        'ja-JP-Female',
      );
      expect(
        LanguageDetector.recommendVoiceForLanguage('de', voices),
        'de-DE-Male',
      );
    });

    test('returns first voice when no match found', () {
      final voices = ['voice1', 'voice2', 'voice3'];
      expect(
        LanguageDetector.recommendVoiceForLanguage('unknown', voices),
        'voice1',
      );
    });

    test('handles empty voice list', () {
      expect(
        LanguageDetector.recommendVoiceForLanguage('en', []),
        '',
      );
    });
  });
}

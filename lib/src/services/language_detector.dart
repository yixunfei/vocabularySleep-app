/// 语言检测工具类
/// 用于自动检测文本的语言，以便为 TTS 选择合适的语音
class LanguageDetector {
  /// 检测文本的主要语言
  /// 返回 ISO 639-1 语言代码（如 'en', 'zh', 'ru', 'ja', 'de', 'fr', 'es'）
  static String detectLanguage(String text) {
    if (text.trim().isEmpty) return 'en';

    final cleanText = text.trim();

    // 统计各种字符类型
    int latinCount = 0;
    int cyrillicCount = 0;
    int cjkCount = 0;
    int hiraganaKatakanaCount = 0;
    int arabicCount = 0;
    int totalAlphaCount = 0;

    for (final rune in cleanText.runes) {
      // 拉丁字母 (A-Z, a-z, 带音标的字母)
      if ((rune >= 0x0041 && rune <= 0x005A) || // A-Z
          (rune >= 0x0061 && rune <= 0x007A) || // a-z
          (rune >= 0x00C0 && rune <= 0x00FF) || // Latin-1 Supplement
          (rune >= 0x0100 && rune <= 0x017F)) { // Latin Extended-A
        latinCount++;
        totalAlphaCount++;
      }
      // 西里尔字母 (俄语等)
      else if (rune >= 0x0400 && rune <= 0x04FF) {
        cyrillicCount++;
        totalAlphaCount++;
      }
      // CJK 统一表意文字 (中文)
      else if ((rune >= 0x4E00 && rune <= 0x9FFF) || // CJK Unified Ideographs
          (rune >= 0x3400 && rune <= 0x4DBF) || // CJK Extension A
          (rune >= 0x20000 && rune <= 0x2A6DF)) { // CJK Extension B
        cjkCount++;
        totalAlphaCount++;
      }
      // 平假名和片假名 (日语)
      else if ((rune >= 0x3040 && rune <= 0x309F) || // Hiragana
          (rune >= 0x30A0 && rune <= 0x30FF)) { // Katakana
        hiraganaKatakanaCount++;
        totalAlphaCount++;
      }
      // 阿拉伯字母
      else if (rune >= 0x0600 && rune <= 0x06FF) {
        arabicCount++;
        totalAlphaCount++;
      }
    }

    if (totalAlphaCount == 0) return 'en';

    // 计算各语言的占比
    final cyrillicRatio = cyrillicCount / totalAlphaCount;
    final cjkRatio = cjkCount / totalAlphaCount;
    final hiraganaKatakanaRatio = hiraganaKatakanaCount / totalAlphaCount;
    final arabicRatio = arabicCount / totalAlphaCount;

    // 如果西里尔字母占比超过 30%，判定为俄语
    if (cyrillicRatio > 0.3) return 'ru';

    // 如果日语假名占比超过 20%，判定为日语
    if (hiraganaKatakanaRatio > 0.2) return 'ja';

    // 如果 CJK 字符占比超过 30%，判定为中文
    if (cjkRatio > 0.3) return 'zh';

    // 如果阿拉伯字母占比超过 30%，判定为阿拉伯语
    if (arabicRatio > 0.3) return 'ar';

    // 拉丁字母为主，进一步细分
    if (latinCount > totalAlphaCount * 0.5) {
      return _detectLatinBasedLanguage(cleanText);
    }

    // 默认返回英语
    return 'en';
  }

  /// 检测基于拉丁字母的语言（英语、德语、法语、西班牙语等）
  static String _detectLatinBasedLanguage(String text) {
    final lowerText = text.toLowerCase();

    // 德语特征词和字符
    if (_containsGermanFeatures(lowerText)) return 'de';

    // 法语特征词和字符
    if (_containsFrenchFeatures(lowerText)) return 'fr';

    // 西班牙语特征词和字符
    if (_containsSpanishFeatures(lowerText)) return 'es';

    // 默认英语
    return 'en';
  }

  /// 检测德语特征
  static bool _containsGermanFeatures(String text) {
    // 德语特有字符
    if (text.contains(RegExp(r'[äöüß]'))) return true;

    // 德语常见词
    final germanWords = [
      'der', 'die', 'das', 'und', 'ist', 'nicht', 'mit', 'von',
      'auf', 'für', 'eine', 'einen', 'einem', 'einer', 'eines',
      'ich', 'du', 'er', 'sie', 'wir', 'ihr', 'werden', 'haben',
      'sein', 'hallo', 'welt', 'möchte', 'lernen',
    ];

    int matchCount = 0;
    for (final word in germanWords) {
      if (text.contains(RegExp(r'\b' + word + r'\b'))) {
        matchCount++;
        if (matchCount >= 2) return true;
      }
    }

    return false;
  }

  /// 检测法语特征
  static bool _containsFrenchFeatures(String text) {
    // 法语特有字符
    if (text.contains(RegExp(r'[àâæçéèêëïîôùûüÿœ]'))) return true;

    // 法语常见词
    final frenchWords = [
      'le', 'la', 'les', 'un', 'une', 'des', 'et', 'est', 'sont',
      'avec', 'pour', 'dans', 'sur', 'par', 'pas', 'plus', 'comme',
      'je', 'tu', 'il', 'elle', 'nous', 'vous', 'ils', 'elles',
      'avoir', 'être', 'faire', 'aller', 'pouvoir', 'vouloir',
      'bonjour', 'monde', 'suis', 'étudiant',
    ];

    int matchCount = 0;
    for (final word in frenchWords) {
      if (text.contains(RegExp(r'\b' + word + r'\b'))) {
        matchCount++;
        if (matchCount >= 2) return true;
      }
    }

    return false;
  }

  /// 检测西班牙语特征
  static bool _containsSpanishFeatures(String text) {
    // 西班牙语特有字符
    if (text.contains(RegExp(r'[áéíóúüñ¿¡]'))) return true;

    // 西班牙语常见词
    final spanishWords = [
      'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas',
      'y', 'es', 'son', 'está', 'están', 'con', 'para', 'por',
      'en', 'de', 'del', 'al', 'no', 'más', 'como', 'pero',
      'yo', 'tú', 'él', 'ella', 'nosotros', 'vosotros', 'ellos',
      'ser', 'estar', 'tener', 'hacer', 'poder', 'ir', 'ver',
      'hola', 'mundo', 'esto', 'una', 'prueba', 'cómo', 'estás',
    ];

    int matchCount = 0;
    for (final word in spanishWords) {
      if (text.contains(RegExp(r'\b' + word + r'\b'))) {
        matchCount++;
        if (matchCount >= 2) return true;
      }
    }

    return false;
  }

  /// 获取语言的本地化名称
  static String getLanguageName(String languageCode) {
    return switch (languageCode) {
      'en' => 'English',
      'zh' => '中文',
      'ja' => '日本語',
      'de' => 'Deutsch',
      'fr' => 'Français',
      'es' => 'Español',
      'ru' => 'Русский',
      'ar' => 'العربية',
      _ => languageCode,
    };
  }

  /// 为指定语言推荐 TTS 语音
  static String recommendVoiceForLanguage(
    String languageCode,
    List<String> availableVoices,
  ) {
    if (availableVoices.isEmpty) return '';

    // 根据语言代码匹配语音
    final patterns = _getVoicePatterns(languageCode);

    for (final pattern in patterns) {
      for (final voice in availableVoices) {
        if (voice.toLowerCase().contains(pattern)) {
          return voice;
        }
      }
    }

    // 如果没有匹配，返回第一个可用语音
    return availableVoices.first;
  }

  /// 获取语言对应的语音匹配模式
  static List<String> _getVoicePatterns(String languageCode) {
    return switch (languageCode) {
      'en' => ['en-', 'en_', 'english', 'us', 'gb', 'uk'],
      'zh' => ['zh-', 'zh_', 'chinese', 'cn', 'mandarin', 'cmn'],
      'ja' => ['ja-', 'ja_', 'japanese', 'jp'],
      'de' => ['de-', 'de_', 'german'],
      'fr' => ['fr-', 'fr_', 'french'],
      'es' => ['es-', 'es_', 'spanish'],
      'ru' => ['ru-', 'ru_', 'russian'],
      'ar' => ['ar-', 'ar_', 'arabic'],
      _ => [languageCode],
    };
  }
}

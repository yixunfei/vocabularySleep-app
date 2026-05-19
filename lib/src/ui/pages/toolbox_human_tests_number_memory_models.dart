part of 'toolbox_human_tests.dart';

enum _NumberMemoryDifficulty { beginner, intermediate, advanced, custom }

enum _NumberMemoryMode { digits, coloredDigits, multiTarget, equation }

class _NumberMemoryColorSpec {
  const _NumberMemoryColorSpec({
    required this.color,
    required this.zh,
    required this.en,
    required this.ja,
    required this.de,
    required this.fr,
    required this.es,
    required this.ru,
  });

  final Color color;
  final String zh;
  final String en;
  final String ja;
  final String de;
  final String fr;
  final String es;
  final String ru;

  String label(AppI18n i18n) =>
      pickUiText(i18n, zh: zh, en: en, ja: ja, de: de, fr: fr, es: es, ru: ru);

  String lowerLabel(AppI18n i18n) {
    final labelText = label(i18n);
    return AppI18n.normalizeLanguageCode(i18n.languageCode) == 'en'
        ? labelText.toLowerCase()
        : labelText;
  }
}

class _NumberMemoryToken {
  const _NumberMemoryToken({required this.text, required this.color});

  final String text;
  final _NumberMemoryColorSpec color;
}

class _NumberMemoryGroup {
  const _NumberMemoryGroup({
    required this.label,
    required this.value,
    required this.color,
    required this.target,
  });

  final String label;
  final String value;
  final _NumberMemoryColorSpec color;
  final bool target;
}

class _NumberMemoryRound {
  const _NumberMemoryRound({
    required this.mode,
    required this.answer,
    required this.displayText,
    required this.tokens,
    required this.groups,
    required this.targetZh,
    required this.targetEn,
    required this.targetJa,
    required this.targetDe,
    required this.targetFr,
    required this.targetEs,
    required this.targetRu,
    required this.inputZh,
    required this.inputEn,
    required this.inputJa,
    required this.inputDe,
    required this.inputFr,
    required this.inputEs,
    required this.inputRu,
    required this.sizeLabel,
    this.targetColor,
  });

  final _NumberMemoryMode mode;
  final String answer;
  final String displayText;
  final List<_NumberMemoryToken> tokens;
  final List<_NumberMemoryGroup> groups;
  final _NumberMemoryColorSpec? targetColor;
  final String targetZh;
  final String targetEn;
  final String targetJa;
  final String targetDe;
  final String targetFr;
  final String targetEs;
  final String targetRu;
  final String inputZh;
  final String inputEn;
  final String inputJa;
  final String inputDe;
  final String inputFr;
  final String inputEs;
  final String inputRu;
  final String sizeLabel;

  String targetText(AppI18n i18n) => pickUiText(
    i18n,
    zh: targetZh,
    en: targetEn,
    ja: targetJa,
    de: targetDe,
    fr: targetFr,
    es: targetEs,
    ru: targetRu,
  );

  String inputText(AppI18n i18n) => pickUiText(
    i18n,
    zh: inputZh,
    en: inputEn,
    ja: inputJa,
    de: inputDe,
    fr: inputFr,
    es: inputEs,
    ru: inputRu,
  );
}

class _NumberMemoryResult {
  const _NumberMemoryResult({
    required this.mode,
    required this.expected,
    required this.answer,
    required this.correct,
    required this.level,
    required this.sizeLabel,
    required this.dwellMs,
  });

  final _NumberMemoryMode mode;
  final String expected;
  final String answer;
  final bool correct;
  final int level;
  final String sizeLabel;
  final int dwellMs;
}

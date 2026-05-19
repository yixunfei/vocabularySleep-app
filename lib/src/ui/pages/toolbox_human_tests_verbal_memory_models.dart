part of 'toolbox_human_tests.dart';

enum _VerbalMemoryMode { words, numbers, arrows }

enum _VerbalMemoryDomain {
  fruits,
  environment,
  nature,
  food,
  travel,
  technology,
  home,
  office,
  weather,
  animals,
}

enum _VerbalMemoryArrowSet { four, eight }

enum _VerbalMemoryArrowDirection {
  upLeft,
  up,
  upRight,
  left,
  right,
  downLeft,
  down,
  downRight,
}

class _VerbalMemoryDomainSpec {
  const _VerbalMemoryDomainSpec({
    required this.domain,
    required this.zh,
    required this.en,
    required this.ja,
    required this.de,
    required this.fr,
    required this.es,
    required this.ru,
    required this.accent,
  });

  final _VerbalMemoryDomain domain;
  final String zh;
  final String en;
  final String ja;
  final String de;
  final String fr;
  final String es;
  final String ru;
  final Color accent;

  String label(AppI18n i18n) =>
      pickUiText(i18n, zh: zh, en: en, ja: ja, de: de, fr: fr, es: es, ru: ru);
}

class _VerbalMemoryWordSpec {
  const _VerbalMemoryWordSpec({
    required this.zh,
    required this.en,
    required this.ja,
    required this.de,
    required this.fr,
    required this.es,
    required this.ru,
    required this.domain,
  });

  final String zh;
  final String en;
  final String ja;
  final String de;
  final String fr;
  final String es;
  final String ru;
  final _VerbalMemoryDomain domain;

  String get key => '${domain.name}:$en';

  String label(AppI18n i18n) =>
      pickUiText(i18n, zh: zh, en: en, ja: ja, de: de, fr: fr, es: es, ru: ru);
}

class _VerbalMemoryArrowSpec {
  const _VerbalMemoryArrowSpec({
    required this.direction,
    required this.icon,
    required this.zh,
    required this.en,
    required this.ja,
    required this.de,
    required this.fr,
    required this.es,
    required this.ru,
    required this.symbol,
  });

  final _VerbalMemoryArrowDirection direction;
  final IconData icon;
  final String zh;
  final String en;
  final String ja;
  final String de;
  final String fr;
  final String es;
  final String ru;
  final String symbol;

  String label(AppI18n i18n) =>
      pickUiText(i18n, zh: zh, en: en, ja: ja, de: de, fr: fr, es: es, ru: ru);
}

class _VerbalMemoryRoundResult {
  const _VerbalMemoryRoundResult({
    required this.mode,
    required this.correct,
    required this.level,
    required this.sizeLabel,
    required this.stimulusLabel,
    required this.expectedLabel,
    required this.responseLabel,
    required this.detailLabel,
    required this.responseMs,
  });

  final _VerbalMemoryMode mode;
  final bool correct;
  final int level;
  final String sizeLabel;
  final String stimulusLabel;
  final String expectedLabel;
  final String responseLabel;
  final String detailLabel;
  final int responseMs;
}

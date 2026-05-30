part of 'toolbox_human_tests.dart';

enum _NumberMemoryDifficulty { beginner, intermediate, advanced, custom }

enum _NumberMemoryMode { digits, coloredDigits, multiTarget, equation }

class _NumberMemoryColorSpec {
  const _NumberMemoryColorSpec({required this.color, required this.labelKey});

  final Color color;
  final String labelKey;

  String label(AppI18n i18n) => i18n.t(labelKey);

  String lowerLabel(AppI18n i18n) {
    final labelText = label(i18n);
    return AppI18n.normalizeLanguageCode(i18n.languageCode) == 'en'
        ? labelText.toLowerCase()
        : labelText;
  }

  String get sizeToken {
    final parts = labelKey.split('.');
    return parts.length > 2 ? parts[parts.length - 2] : labelKey;
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
    required this.targetKey,
    required this.inputKey,
    required this.sizeLabel,
    this.targetGroupLabel,
    this.targetColor,
  });

  final _NumberMemoryMode mode;
  final String answer;
  final String displayText;
  final List<_NumberMemoryToken> tokens;
  final List<_NumberMemoryGroup> groups;
  final _NumberMemoryColorSpec? targetColor;
  final String targetKey;
  final String inputKey;
  final String? targetGroupLabel;
  final String sizeLabel;

  Map<String, Object?> _textParams(AppI18n i18n) => <String, Object?>{
    if (targetColor != null) 'color': targetColor!.label(i18n),
    if (targetColor != null) 'lowerColor': targetColor!.lowerLabel(i18n),
    if (targetGroupLabel != null) 'group': targetGroupLabel,
  };

  String targetText(AppI18n i18n) =>
      i18n.t(targetKey, params: _textParams(i18n));

  String inputText(AppI18n i18n) => i18n.t(inputKey, params: _textParams(i18n));
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

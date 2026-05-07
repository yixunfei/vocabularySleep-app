part of 'toolbox_human_tests.dart';

enum _NumberMemoryDifficulty { beginner, intermediate, advanced, custom }

enum _NumberMemoryMode { digits, coloredDigits, multiTarget, equation }

class _NumberMemoryColorSpec {
  const _NumberMemoryColorSpec({
    required this.color,
    required this.zh,
    required this.en,
  });

  final Color color;
  final String zh;
  final String en;
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
    required this.inputZh,
    required this.inputEn,
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
  final String inputZh;
  final String inputEn;
  final String sizeLabel;
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

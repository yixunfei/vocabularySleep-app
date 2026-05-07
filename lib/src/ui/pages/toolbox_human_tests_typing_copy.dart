part of 'toolbox_human_tests.dart';

String _typingModeLabel(AppI18n i18n, _TypingMode mode) {
  return switch (mode) {
    _TypingMode.classic => pickUiText(i18n, zh: '经典', en: 'Classic'),
    _TypingMode.sprint => pickUiText(i18n, zh: '冲刺', en: 'Sprint'),
    _TypingMode.precision => pickUiText(i18n, zh: '精准', en: 'Precision'),
    _TypingMode.blind => pickUiText(i18n, zh: '盲打', en: 'Blind'),
    _TypingMode.symbols => pickUiText(i18n, zh: '符号', en: 'Symbols'),
    _TypingMode.fixErrors => pickUiText(i18n, zh: '纠错', en: 'Fix errors'),
    _TypingMode.code => pickUiText(i18n, zh: '代码', en: 'Code'),
    _TypingMode.numbers => pickUiText(i18n, zh: '数字', en: 'Numbers'),
  };
}

String _typingModeHint(AppI18n i18n, _TypingMode mode) {
  return switch (mode) {
    _TypingMode.classic => pickUiText(
      i18n,
      zh: '完整输入当前语料，适合建立稳定基准。',
      en: 'Type the full passage to build a stable baseline.',
    ),
    _TypingMode.sprint => pickUiText(
      i18n,
      zh: '更强调速度，报告会突出净 WPM、峰值和节奏波动。',
      en: 'Speed-focused mode with net WPM, peak speed, and rhythm feedback.',
    ),
    _TypingMode.precision => pickUiText(
      i18n,
      zh: '必须完全一致才完成，适合练准确率。',
      en: 'Requires an exact match before completion.',
    ),
    _TypingMode.blind => pickUiText(
      i18n,
      zh: '输入内容会被隐藏，训练肌肉记忆和回退控制。',
      en: 'Your typed text is hidden to train muscle memory and control.',
    ),
    _TypingMode.symbols => pickUiText(
      i18n,
      zh: '加入符号和数字，训练真实键盘切换。',
      en: 'Adds symbols and numbers for real keyboard switching.',
    ),
    _TypingMode.fixErrors => pickUiText(
      i18n,
      zh: '上方会给出带错位的提示，请输入修正后的内容。',
      en: 'Shows a disrupted prompt; type the corrected version.',
    ),
    _TypingMode.code => pickUiText(
      i18n,
      zh: '输入短代码片段，关注括号、缩进、大小写和标点。',
      en: 'Type a short code snippet with brackets, indentation, case, and punctuation.',
    ),
    _TypingMode.numbers => pickUiText(
      i18n,
      zh: '输入数字、时间、百分比和编号，训练非连续文字。',
      en: 'Type numbers, time, percentages, and IDs instead of prose.',
    ),
  };
}

String _typingLanguageLabel(AppI18n i18n, _TypingLanguage language) {
  return switch (language) {
    _TypingLanguage.zh => pickUiText(i18n, zh: '中文', en: 'Chinese'),
    _TypingLanguage.en => pickUiText(i18n, zh: '英文', en: 'English'),
    _TypingLanguage.mixed => pickUiText(i18n, zh: '混合', en: 'Mixed'),
    _TypingLanguage.ja => pickUiText(i18n, zh: '日文', en: 'Japanese'),
    _TypingLanguage.es => pickUiText(i18n, zh: '西语', en: 'Spanish'),
  };
}

String _typingTopicLabel(AppI18n i18n, _TypingTopic topic) {
  return switch (topic) {
    _TypingTopic.all => pickUiText(i18n, zh: '全部', en: 'All'),
    _TypingTopic.focus => pickUiText(i18n, zh: '专注', en: 'Focus'),
    _TypingTopic.sleep => pickUiText(i18n, zh: '睡眠', en: 'Sleep'),
    _TypingTopic.tech => pickUiText(i18n, zh: '技术', en: 'Tech'),
    _TypingTopic.story => pickUiText(i18n, zh: '短文', en: 'Story'),
    _TypingTopic.vocabulary => pickUiText(i18n, zh: '词汇', en: 'Vocabulary'),
    _TypingTopic.travel => pickUiText(i18n, zh: '旅行', en: 'Travel'),
  };
}

String _typingLengthLabel(AppI18n i18n, _TypingLength length) {
  return switch (length) {
    _TypingLength.short => pickUiText(i18n, zh: '短句', en: 'Short'),
    _TypingLength.standard => pickUiText(i18n, zh: '标准', en: 'Standard'),
    _TypingLength.long => pickUiText(i18n, zh: '长段', en: 'Long'),
  };
}

String _typingGrade(AppI18n i18n, _TypingReport report) {
  if (report.accuracy >= 98 &&
      report.netWpm >= 60 &&
      report.consistencyScore >= 80) {
    return pickUiText(i18n, zh: '专业级', en: 'Professional');
  }
  if (report.accuracy >= 96 && report.netWpm >= 44) {
    return pickUiText(i18n, zh: '稳定熟练', en: 'Skilled');
  }
  if (report.accuracy >= 92 && report.consistencyScore >= 65) {
    return pickUiText(i18n, zh: '基础稳定', en: 'Stable');
  }
  return pickUiText(i18n, zh: '需要放慢', en: 'Slow down');
}

String _typingAdvice(AppI18n i18n, _TypingReport report) {
  final symbolIssues =
      (report.issueBreakdown[_TypingIssue.punctuation] ?? 0) +
      (report.issueBreakdown[_TypingIssue.number] ?? 0);
  if (report.accuracy < 90) {
    return pickUiText(
      i18n,
      zh: '先把速度降下来，连续两轮保持 95% 以上准确率后再冲刺。',
      en: 'Slow down first; sprint again after two rounds above 95% accuracy.',
    );
  }
  if (report.consistencyScore < 65 || report.longPauses >= 2) {
    return pickUiText(
      i18n,
      zh: '节奏波动偏大。下一轮用短句冲刺，专注连续输入，不急着修饰速度。',
      en: 'Rhythm is uneven. Use a short Sprint round next and focus on continuous flow.',
    );
  }
  if (symbolIssues >= math.max(2, report.errorCount * 0.35)) {
    return pickUiText(
      i18n,
      zh: '符号或数字是主要弱点，建议切换符号或数字模式做专项练习。',
      en: 'Symbols or numbers are the main weak point. Switch to Symbols or Numbers.',
    );
  }
  if (report.backspaceCount > report.targetLength * 0.16) {
    return pickUiText(
      i18n,
      zh: '回退偏多，下一轮可以练盲打或精准模式，减少犹豫。',
      en: 'Backspaces are high. Try Blind or Precision mode to reduce hesitation.',
    );
  }
  if (report.netWpm < 35) {
    return pickUiText(
      i18n,
      zh: '准确率不错，下一轮用冲刺模式拉高连续节奏。',
      en: 'Accuracy is good. Use Sprint mode next to raise cadence.',
    );
  }
  return pickUiText(
    i18n,
    zh: '速度、准确率和节奏比较均衡，可以切换代码或混合语料增加真实难度。',
    en: 'Speed, accuracy, and rhythm are balanced. Try Code or Mixed content for realism.',
  );
}

_TypingMode _typingSuggestedMode(_TypingReport report) {
  final symbolIssues =
      (report.issueBreakdown[_TypingIssue.punctuation] ?? 0) +
      (report.issueBreakdown[_TypingIssue.number] ?? 0);
  if (report.accuracy < 92) {
    return _TypingMode.precision;
  }
  if (symbolIssues >= 2) {
    return _TypingMode.symbols;
  }
  if (report.backspaceCount > report.targetLength * 0.16) {
    return _TypingMode.blind;
  }
  if (report.netWpm < 35 || report.consistencyScore < 70) {
    return _TypingMode.sprint;
  }
  return report.mode == _TypingMode.code
      ? _TypingMode.numbers
      : _TypingMode.code;
}

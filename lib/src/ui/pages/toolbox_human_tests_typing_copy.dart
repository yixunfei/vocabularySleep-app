part of 'toolbox_human_tests.dart';

String _typingModeLabel(AppI18n i18n, _TypingMode mode) {
  return switch (mode) {
    _TypingMode.classic => pickUiText(
      i18n,
      zh: '经典',
      en: 'Classic',
      ja: 'クラシック',
      de: 'Classic',
      fr: 'Classique',
      es: 'Clásico',
      ru: 'Классика',
    ),
    _TypingMode.sprint => pickUiText(
      i18n,
      zh: '冲刺',
      en: 'Sprint',
      ja: 'Sprint',
      de: 'Sprint',
      fr: 'Sprint',
      es: 'Sprint',
      ru: 'Спринт',
    ),
    _TypingMode.precision => pickUiText(
      i18n,
      zh: '精准',
      en: 'Precision',
      ja: 'Precision',
      de: 'Precision',
      fr: 'Précision',
      es: 'Precisión',
      ru: 'точность',
    ),
    _TypingMode.blind => pickUiText(
      i18n,
      zh: '盲打',
      en: 'Blind',
      ja: 'ブラインド',
      de: 'Blind',
      fr: 'Aveugle',
      es: 'Ciego',
      ru: 'слепой',
    ),
    _TypingMode.symbols => pickUiText(
      i18n,
      zh: '符号',
      en: 'Symbols',
      ja: 'Symbols',
      de: 'Symbols',
      fr: 'Symboles',
      es: 'Símbolos',
      ru: 'Символы',
    ),
    _TypingMode.fixErrors => pickUiText(
      i18n,
      zh: '纠错',
      en: 'Fix errors',
      ja: 'Fix errors',
      de: 'Fix errors',
      fr: 'Correction des erreurs',
      es: 'Corregir errores',
      ru: 'Исправить ошибки',
    ),
    _TypingMode.code => pickUiText(
      i18n,
      zh: '代码',
      en: 'Code',
      ja: 'Code',
      de: 'Code',
      fr: 'Code',
      es: 'Código',
      ru: 'Код',
    ),
    _TypingMode.numbers => pickUiText(
      i18n,
      zh: '数字',
      en: 'Numbers',
      ja: 'Numbers',
      de: 'Numbers',
      fr: 'Nombres',
      es: 'Números',
      ru: 'Числа',
    ),
  };
}

String _typingModeHint(AppI18n i18n, _TypingMode mode) {
  return switch (mode) {
    _TypingMode.classic => pickUiText(
      i18n,
      zh: '完整输入当前语料，适合建立稳定基准。',
      en: 'Type the full passage to build a stable baseline.',
      ja: 'Type the full passage to build a stable baseline.',
      de: 'Type the full passage to build a stable baseline.',
      fr: 'Tapez le passage complet pour construire une base stable.',
      es: 'Escriba el pasaje completo para construir una base de referencia estable.',
      ru: 'Введите полный проход, чтобы построить стабильный базовый уровень.',
    ),
    _TypingMode.sprint => pickUiText(
      i18n,
      zh: '更强调速度，报告会突出净 WPM、峰值和节奏波动。',
      en: 'Speed-focused mode with net WPM, peak speed, and rhythm feedback.',
      ja: 'Speed-focused mode with net WPM, peak speed, and rhythm feedback.',
      de: 'Speed-focused mode with net WPM, peak speed, and rhythm feedback.',
      fr: 'Mode axé sur la vitesse avec net WPM, vitesse de pointe et retour de rythme.',
      es: 'Modo centrado en la velocidad con WPM neto, velocidad máxima y retroalimentación del ritmo.',
      ru: 'Скоростной режим с чистой WPM, пиковой скоростью и обратной связью с ритмом.',
    ),
    _TypingMode.precision => pickUiText(
      i18n,
      zh: '必须完全一致才完成，适合练准确率。',
      en: 'Requires an exact match before completion.',
      ja: 'Requires an exact match before completion.',
      de: 'Requires an exact match before completion.',
      fr: 'Nécessite une correspondance exacte avant l\'achèvement.',
      es: 'Requiere una coincidencia exacta antes de la terminación.',
      ru: 'Требуется точный матч до завершения.',
    ),
    _TypingMode.blind => pickUiText(
      i18n,
      zh: '输入内容会被隐藏，训练肌肉记忆和回退控制。',
      en: 'Your typed text is hidden to train muscle memory and control.',
      ja: 'Your typed text is hidden to train muscle memory and control.',
      de: 'Your typed text is hidden to train muscle memory and control.',
      fr: 'Votre texte tapé est caché pour former la mémoire musculaire et le contrôle.',
      es: 'Su texto escrito está oculto para entrenar la memoria y el control muscular.',
      ru: 'Ваш напечатанный текст скрыт для тренировки мышечной памяти и контроля.',
    ),
    _TypingMode.symbols => pickUiText(
      i18n,
      zh: '加入符号和数字，训练真实键盘切换。',
      en: 'Adds symbols and numbers for real keyboard switching.',
      ja: '実際のキーボード切り替えのためのシンボルと数字を追加します。',
      de: 'Adds symbols and numbers for real keyboard switching.',
      fr: 'Adds symbols and numbers for real keyboard switching.',
      es: 'Añade símbolos y números para el cambio de teclado real.',
      ru: 'Добавляет символы и цифры для реального переключения клавиатуры.',
    ),
    _TypingMode.fixErrors => pickUiText(
      i18n,
      zh: '上方会给出带错位的提示，请输入修正后的内容。',
      en: 'Shows a disrupted prompt; type the corrected version.',
      ja: 'Shows a disrupted prompt; type the corrected version.',
      de: 'Shows a disrupted prompt; type the corrected version.',
      fr: 'Affiche une invite perturbée; tapez la version corrigée.',
      es: 'Muestra un aviso interrumpido; escriba la versión corregida.',
      ru: 'Показывает нарушенную подсказку; введите исправленную версию.',
    ),
    _TypingMode.code => pickUiText(
      i18n,
      zh: '输入带格式的短句，关注括号、缩进、大小写和标点。',
      en: 'Type a formatted short passage with brackets, indentation, case, and punctuation.',
      ja: 'Type a formatted short passage with brackets, indentation, case, and punctuation.',
      de: 'Type a formatted short passage with brackets, indentation, case, and punctuation.',
      fr: 'Tapez un court passage formaté avec les crochets, l\'indentation, le boîtier et la ponctuation.',
      es: 'Escribe un pasaje corto formateado con corchetes, indentación, caso y puntuación.',
      ru: 'Введите отформатированный короткий проход с скобками, углублением, корпусом и пунктуацией.',
    ),
    _TypingMode.numbers => pickUiText(
      i18n,
      zh: '输入数字、时间、百分比和编号，训练非连续文字。',
      en: 'Type numbers, time, percentages, and IDs instead of prose.',
      ja: 'Type numbers, time, percentages, and IDs instead of prose.',
      de: 'Type numbers, time, percentages, and IDs instead of prose.',
      fr: 'Tapez les numéros, le temps, les pourcentages et les ID au lieu de la prose.',
      es: 'Escriba números, tiempo, porcentajes e identificaciones en lugar de prosa.',
      ru: 'Типовые номера, время, проценты и идентификаторы вместо прозы.',
    ),
  };
}

String _typingLanguageLabel(AppI18n i18n, _TypingLanguage language) {
  return switch (language) {
    _TypingLanguage.zh => pickUiText(
      i18n,
      zh: '中文',
      en: 'Chinese',
      ja: 'CHINESE',
      de: 'Chinese',
      fr: 'Chinois',
      es: 'Chino',
      ru: 'китайский',
    ),
    _TypingLanguage.en => pickUiText(
      i18n,
      zh: '英文',
      en: 'English',
      ja: 'English',
      de: 'English',
      fr: 'changements climatiques',
      es: 'Inglés',
      ru: 'английский',
    ),
    _TypingLanguage.mixed => pickUiText(
      i18n,
      zh: '混合',
      en: 'Mixed',
      ja: 'Mixed',
      de: 'Mixed',
      fr: 'Mélange',
      es: 'Mezcla',
      ru: 'смешанный',
    ),
    _TypingLanguage.ja => pickUiText(
      i18n,
      zh: '日文',
      en: 'Japanese',
      ja: 'Japanese',
      de: 'Japanese',
      fr: 'Japonais',
      es: 'japonés',
      ru: 'японский',
    ),
    _TypingLanguage.es => pickUiText(
      i18n,
      zh: '西语',
      en: 'Spanish',
      ja: 'Spanish',
      de: 'Spanish',
      fr: 'Espagnol',
      es: 'Español',
      ru: 'испанский',
    ),
  };
}

String _typingTopicLabel(AppI18n i18n, _TypingTopic topic) {
  return switch (topic) {
    _TypingTopic.all => pickUiText(
      i18n,
      zh: '全部',
      en: 'All',
      ja: 'すべて',
      de: 'All',
      fr: 'All',
      es: 'Todos',
      ru: 'Все',
    ),
    _TypingTopic.focus => pickUiText(
      i18n,
      zh: '专注',
      en: 'Focus',
      ja: 'Focus',
      de: 'Focus',
      fr: 'Objectif',
      es: 'Focus',
      ru: 'Фокус',
    ),
    _TypingTopic.sleep => pickUiText(
      i18n,
      zh: '睡眠',
      en: 'Sleep',
      ja: 'Sleep',
      de: 'Sleep',
      fr: 'Sommeil',
      es: 'Duerme',
      ru: 'спать',
    ),
    _TypingTopic.tech => pickUiText(
      i18n,
      zh: '日常',
      en: 'Everyday',
      ja: '日常',
      de: 'Alltag',
      fr: 'Quotidien',
      es: 'Diario',
      ru: 'Повседневное',
    ),
    _TypingTopic.story => pickUiText(
      i18n,
      zh: '短文',
      en: 'Story',
      ja: 'Story',
      de: 'Story',
      fr: 'Histoire',
      es: 'Historia',
      ru: 'История',
    ),
    _TypingTopic.vocabulary => pickUiText(
      i18n,
      zh: '词汇',
      en: 'Vocabulary',
      ja: 'Vocabulary',
      de: 'Vocabulary',
      fr: 'Vocabulaire',
      es: 'Vocabulario',
      ru: 'словарь',
    ),
    _TypingTopic.travel => pickUiText(
      i18n,
      zh: '旅行',
      en: 'Travel',
      ja: 'Travel',
      de: 'Travel',
      fr: 'Voyages',
      es: 'Viajes',
      ru: 'Путешествие',
    ),
  };
}

String _typingLengthLabel(AppI18n i18n, _TypingLength length) {
  return switch (length) {
    _TypingLength.short => pickUiText(
      i18n,
      zh: '短句',
      en: 'Short',
      ja: 'Short',
      de: 'Short',
      fr: 'Court',
      es: 'Corto',
      ru: 'короткий',
    ),
    _TypingLength.standard => pickUiText(
      i18n,
      zh: '标准',
      en: 'Standard',
      ja: 'Standard',
      de: 'Standard',
      fr: 'Norme',
      es: 'Estándar',
      ru: 'Стандарт',
    ),
    _TypingLength.long => pickUiText(
      i18n,
      zh: '长段',
      en: 'Long',
      ja: 'Long',
      de: 'Long',
      fr: 'Longue',
      es: 'Largo',
      ru: 'длинный',
    ),
  };
}

String _typingGrade(AppI18n i18n, _TypingReport report) {
  if (report.accuracy >= 98 &&
      report.netWpm >= 60 &&
      report.consistencyScore >= 80) {
    return pickUiText(
      i18n,
      zh: '专业级',
      en: 'Professional',
      ja: 'Professional',
      de: 'Professional',
      fr: 'Professionnel',
      es: 'Cuadro orgánico',
      ru: 'Профессиональный',
    );
  }
  if (report.accuracy >= 96 && report.netWpm >= 44) {
    return pickUiText(
      i18n,
      zh: '稳定熟练',
      en: 'Skilled',
      ja: 'Skilled',
      de: 'Skilled',
      fr: 'Compétence',
      es: 'Habilidad',
      ru: 'квалифицированный',
    );
  }
  if (report.accuracy >= 92 && report.consistencyScore >= 65) {
    return pickUiText(
      i18n,
      zh: '基础稳定',
      en: 'Stable',
      ja: 'Stable',
      de: 'Stable',
      fr: 'Stable',
      es: 'Stable',
      ru: 'стабильный',
    );
  }
  return pickUiText(
    i18n,
    zh: '需要放慢',
    en: 'Slow down',
    ja: 'Slow down',
    de: 'Slow down',
    fr: 'Ralentir',
    es: 'Despacio.',
    ru: 'Помедленнее',
  );
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
      ja: 'Slow down first; sprint again after two rounds above 95% accuracy.',
      de: 'Slow down first; sprint again after two rounds above 95% accuracy.',
      fr: 'Ralentissez d\'abord ; sprintez encore après deux tours au-dessus de 95 %.',
      es: 'Despacio primero; sprint de nuevo después de dos rondas sobre la precisión del 95%.',
      ru: 'Сначала помедленнее, после двух раундов спринт снова выше 95% точности.',
    );
  }
  if (report.consistencyScore < 65 || report.longPauses >= 2) {
    return pickUiText(
      i18n,
      zh: '节奏波动偏大。下一轮用短句冲刺，专注连续输入，不急着提速。',
      en: 'Rhythm is uneven. Use a short Sprint round next and focus on continuous flow.',
      ja: 'Rhythm is uneven. Use a short Sprint round next and focus on continuous flow.',
      de: 'Rhythm is uneven. Use a short Sprint round next and focus on continuous flow.',
      fr: 'Le rythme est inégal. Utilisez un court tour de Sprint et concentrez-vous sur le flux continu.',
      es: 'Rhythm es desigual. Use un corto Sprint redondo siguiente y concéntrese en flujo continuo.',
      ru: 'Ритм неравномерный. Используйте короткий Sprint и сосредоточьтесь на непрерывном потоке.',
    );
  }
  if (symbolIssues >= math.max(2, report.errorCount * 0.35)) {
    return pickUiText(
      i18n,
      zh: '符号或数字是主要弱项，可以切到符号或数字模式单独练。',
      en: 'Symbols or numbers are the main weak point. Switch to Symbols or Numbers.',
      ja: 'Symbols or numbers are the main weak point. Switch to Symbols or Numbers.',
      de: 'Symbols or numbers are the main weak point. Switch to Symbols or Numbers.',
      fr: 'Les symboles ou les nombres sont le principal point faible. Passez aux symboles ou numéros.',
      es: 'Los símbolos o números son el punto débil principal. Cambiar a símbolos o números.',
      ru: 'Символы или цифры являются основным слабым местом. Переключитесь на символы или цифры.',
    );
  }
  if (report.backspaceCount > report.targetLength * 0.16) {
    return pickUiText(
      i18n,
      zh: '回退偏多，下一轮可以练盲打或精准模式，减少犹豫。',
      en: 'Backspaces are high. Try Blind or Precision mode to reduce hesitation.',
      ja: 'バックスペースが高い。 ブラインドまたはプレシジョンモードを試して、躊躇を減らしましょう。',
      de: 'Backspaces are high. Try Blind or Precision mode to reduce hesitation.',
      fr: 'Les backspaces sont hauts. Essayez le mode Blind ou Precision pour réduire les hésitations.',
      es: 'Los backspaces son altos. Pruebe el modo Ciego o Precisión para reducir la vacilación.',
      ru: 'Задние пространства высокие. Попробуйте слепой или точный режим, чтобы уменьшить колебания.',
    );
  }
  if (report.netWpm < 35) {
    return pickUiText(
      i18n,
      zh: '准确率不错，下一轮用冲刺模式拉高连续节奏。',
      en: 'Accuracy is good. Use Sprint mode next to raise cadence.',
      ja: '精度は良いです。次のスプリントモードを使用してケイデンスを上げます。',
      de: 'Accuracy is good. Use Sprint mode next to raise cadence.',
      fr: 'Accuracy is good. Use Sprint mode next to raise cadence.',
      es: 'La precisión es buena. Utilice el modo Sprint al lado para aumentar la cadencia.',
      ru: 'Точность хорошая. Используйте режим Sprint рядом, чтобы повысить каденцию.',
    );
  }
  return pickUiText(
    i18n,
    zh: '速度、准确率和节奏比较均衡，可以切换格式或混合语料增加真实难度。',
    en: 'Speed, accuracy, and rhythm are balanced. Try Format or Mixed content for a more realistic challenge.',
    ja: 'Speed, accuracy, and rhythm are balanced. Try Format or Mixed content for a more realistic challenge.',
    de: 'Speed, accuracy, and rhythm are balanced. Try Format or Mixed content for a more realistic challenge.',
    fr: 'Vitesse, précision et rythme sont équilibrés. Essayez Format ou contenu mixte pour un défi plus réaliste.',
    es: 'La velocidad, la precisión y el ritmo son equilibrados. Pruebe formato o contenido mixto para un reto más realista.',
    ru: 'Скорость, точность и ритм сбалансированы. Попробуйте формат или смешанный контент для более реалистичной задачи.',
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

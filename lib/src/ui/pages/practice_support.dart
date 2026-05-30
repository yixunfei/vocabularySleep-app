import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../../models/practice_question_type.dart';
import '../../models/word_entry.dart';
import '../ui_copy.dart';

const List<String> practiceWeakReasonIds = <String>[
  'recall',
  'meaning',
  'pronunciation',
  'spelling',
];

String practiceWeakReasonLabel(AppI18n i18n, String reasonId) {
  return switch (reasonId.trim()) {
    'meaning' => i18n.t('fieldMeaning'),
    'pronunciation' => i18n.t(
      'inline.ui.pages.practice_support.pronunciation_47a756',
    ),
    'spelling' => i18n.t('spellingLabel'),
    _ => i18n.t('inline.ui.pages.practice_support.recall_4e1a00'),
  };
}

IconData practiceWeakReasonIcon(String reasonId) {
  return switch (reasonId.trim()) {
    'meaning' => Icons.menu_book_rounded,
    'pronunciation' => Icons.graphic_eq_rounded,
    'spelling' => Icons.spellcheck_rounded,
    _ => Icons.psychology_alt_outlined,
  };
}

String formatPracticeDateTime(AppI18n i18n, DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return i18n.t(
    'inline.ui.pages.practice_support.month_day_hour_minute_59dd3a',
    params: <String, Object?>{
      'month': month,
      'day': day,
      'hour': hour,
      'minute': minute,
    },
  );
}

String practiceQuestionTypeLabel(
  AppI18n i18n,
  PracticeQuestionType questionType,
) {
  return switch (questionType) {
    PracticeQuestionType.flashcard => i18n.t(
      'inline.ui.pages.practice_support.flashcard_53c373',
    ),
    PracticeQuestionType.meaningChoice => i18n.t(
      'inline.ui.pages.practice_support.meaning_choice_9d17f5',
    ),
    PracticeQuestionType.spelling => i18n.t('spellingLabel'),
    PracticeQuestionType.mixed => i18n.t(
      'inline.plan295.daily_choice.mixed.2c9888bab620',
    ),
  };
}

IconData practiceQuestionTypeIcon(PracticeQuestionType questionType) {
  return switch (questionType) {
    PracticeQuestionType.flashcard => Icons.style_rounded,
    PracticeQuestionType.meaningChoice => Icons.rule_rounded,
    PracticeQuestionType.spelling => Icons.keyboard_alt_rounded,
    PracticeQuestionType.mixed => Icons.shuffle_rounded,
  };
}

String practiceMeaningText(WordEntry entry) {
  return entry.displayMeaning.trim();
}

String normalizePracticeAnswer(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fff]+'), '');
}

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
    'meaning' => pickUiText(i18n, zh: '词义模糊', en: 'Meaning'),
    'pronunciation' => pickUiText(i18n, zh: '发音不稳', en: 'Pronunciation'),
    'spelling' => pickUiText(i18n, zh: '拼写不稳', en: 'Spelling'),
    _ => pickUiText(i18n, zh: '想不起来', en: 'Recall'),
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
  return pickUiText(
    i18n,
    zh: '$month/$day $hour:$minute',
    en: '$month/$day $hour:$minute',
  );
}

String practiceQuestionTypeLabel(
  AppI18n i18n,
  PracticeQuestionType questionType,
) {
  return switch (questionType) {
    PracticeQuestionType.flashcard => pickUiText(
      i18n,
      zh: '自评卡片',
      en: 'Flashcard',
    ),
    PracticeQuestionType.meaningChoice => pickUiText(
      i18n,
      zh: '词义选择',
      en: 'Meaning choice',
    ),
    PracticeQuestionType.spelling => pickUiText(
      i18n,
      zh: '拼写输入',
      en: 'Spelling',
    ),
    PracticeQuestionType.mixed => pickUiText(i18n, zh: '混合题型', en: 'Mixed'),
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
  final directMeaning = entry.meaning?.trim() ?? '';
  if (directMeaning.isNotEmpty) {
    return directMeaning;
  }
  for (final field in entry.fields) {
    if (field.key == 'meaning') {
      final text = field.asText().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
  }
  return '';
}

String normalizePracticeAnswer(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fff]+'), '');
}

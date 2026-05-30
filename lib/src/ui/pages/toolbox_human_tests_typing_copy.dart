part of 'toolbox_human_tests.dart';

String _typingModeLabel(AppI18n i18n, _TypingMode mode) {
  return switch (mode) {
    _TypingMode.classic => i18n.t(
      'inline.ui.pages.toolbox_human_tests_action.classic_3e1072',
    ),
    _TypingMode.sprint => i18n.t(
      'inline.ui.pages.toolbox_human_tests_reaction.sprint_a70236',
    ),
    _TypingMode.precision => i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.precision_a740af',
    ),
    _TypingMode.blind => i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.blind_335c31',
    ),
    _TypingMode.symbols => i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.symbols_89fa93',
    ),
    _TypingMode.fixErrors => i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.fix_errors_7e8d8e',
    ),
    _TypingMode.code => i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.code_b47a07',
    ),
    _TypingMode.numbers => i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.numbers_7ef41c',
    ),
  };
}

String _typingModeHint(AppI18n i18n, _TypingMode mode) {
  return switch (mode) {
    _TypingMode.classic => i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.type_the_full_passage_to_build_a_stable_baseline_dc25ec',
    ),
    _TypingMode.sprint => i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.speed_focused_mode_with_net_wpm_peak_speed_and_rhythm_fe_e0dfa9',
    ),
    _TypingMode.precision => i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.requires_an_exact_match_before_completion_6e980f',
    ),
    _TypingMode.blind => i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.your_typed_text_is_hidden_to_train_muscle_memory_and_con_c22c70',
    ),
    _TypingMode.symbols => i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.adds_symbols_and_numbers_for_real_keyboard_switching_d59c3b',
    ),
    _TypingMode.fixErrors => i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.shows_a_disrupted_prompt_type_the_corrected_version_95ab76',
    ),
    _TypingMode.code => i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.type_a_formatted_short_passage_with_brackets_indentation_a29688',
    ),
    _TypingMode.numbers => i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.type_numbers_time_percentages_and_ids_instead_of_prose_446eb5',
    ),
  };
}

String _typingLanguageLabel(AppI18n i18n, _TypingLanguage language) {
  return switch (language) {
    _TypingLanguage.zh => i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.chinese_7d55e9',
    ),
    _TypingLanguage.en => i18n.t('inline.plan295.life.english.0f5a12198399'),
    _TypingLanguage.mixed => i18n.t(
      'inline.ui.pages.practice_support.mixed_fba1b6',
    ),
    _TypingLanguage.ja => i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.japanese_050b5d',
    ),
    _TypingLanguage.es => i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.spanish_ae08ca',
    ),
  };
}

String _typingTopicLabel(AppI18n i18n, _TypingTopic topic) {
  return switch (topic) {
    _TypingTopic.all => i18n.t('all'),
    _TypingTopic.focus => i18n.t('ambientCategoryFocus'),
    _TypingTopic.sleep => i18n.t('toolbox.hub.section.sleep.title'),
    _TypingTopic.tech => i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.everyday_a3f226',
    ),
    _TypingTopic.story => i18n.t('fieldStory'),
    _TypingTopic.vocabulary => i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.vocabulary_995068',
    ),
    _TypingTopic.travel => i18n.t('toolbox.sleep.log.travel'),
  };
}

String _typingLengthLabel(AppI18n i18n, _TypingLength length) {
  return switch (length) {
    _TypingLength.short => i18n.t('inline.plan295.life.short.6b4c0a54fccb'),
    _TypingLength.standard => i18n.t(
      'inline.ui.pages.toolbox_human_tests_bimanual.standard_b9acb5',
    ),
    _TypingLength.long => i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.long_93b159',
    ),
  };
}

String _typingGrade(AppI18n i18n, _TypingReport report) {
  if (report.accuracy >= 98 &&
      report.netWpm >= 60 &&
      report.consistencyScore >= 80) {
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.professional_78820c',
    );
  }
  if (report.accuracy >= 96 && report.netWpm >= 44) {
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.skilled_9978dc',
    );
  }
  if (report.accuracy >= 92 && report.consistencyScore >= 65) {
    return i18n.t('toolbox.sleep.rhythm.stable');
  }
  return i18n.t(
    'inline.ui.pages.toolbox_human_tests_typing_copy.slow_down_caff84',
  );
}

String _typingAdvice(AppI18n i18n, _TypingReport report) {
  final symbolIssues =
      (report.issueBreakdown[_TypingIssue.punctuation] ?? 0) +
      (report.issueBreakdown[_TypingIssue.number] ?? 0);
  if (report.accuracy < 90) {
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.slow_down_first_sprint_again_after_two_rounds_above_95_a_c9dc1c',
    );
  }
  if (report.consistencyScore < 65 || report.longPauses >= 2) {
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.rhythm_is_uneven_use_a_short_sprint_round_next_and_focus_de7a25',
    );
  }
  if (symbolIssues >= math.max(2, report.errorCount * 0.35)) {
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.symbols_or_numbers_are_the_main_weak_point_switch_to_sym_8664e3',
    );
  }
  if (report.backspaceCount > report.targetLength * 0.16) {
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.backspaces_are_high_try_blind_or_precision_mode_to_reduc_a19eee',
    );
  }
  if (report.netWpm < 35) {
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_typing_copy.accuracy_is_good_use_sprint_mode_next_to_raise_cadence_678571',
    );
  }
  return i18n.t(
    'inline.ui.pages.toolbox_human_tests_typing_copy.speed_accuracy_and_rhythm_are_balanced_try_format_or_mix_dc8a60',
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

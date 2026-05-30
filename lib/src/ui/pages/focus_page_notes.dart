part of 'focus_page.dart';

String _mergeRecognizedNoteContent(String current, String recognized) {
  final next = recognized.trim();
  if (next.isEmpty) {
    return current.trim();
  }
  final existing = current.trimRight();
  if (existing.isEmpty) {
    return next;
  }
  if (existing.endsWith('\n')) {
    return '$existing$next';
  }
  return '$existing\n$next';
}

String? _noteSpeechLanguageTag(AppState state) {
  final normalized = normalizeAsrLanguageTag(state.config.voiceInput.language);
  if (normalized == 'auto') {
    return null;
  }
  return normalized;
}

String _noteSpeechLanguageLabel(AppI18n i18n, String? languageTag) {
  return asrLanguageLabel(i18n, languageTag);
}

String _noteSpeechHelperText(
  AppI18n i18n,
  _NoteVoiceInputState voiceState,
  String? languageTag,
  VoiceInputProviderType provider,
) {
  final languageLabel = _noteSpeechLanguageLabel(i18n, languageTag);
  return switch (voiceState) {
    _NoteVoiceInputState.starting => i18n.t(
      'inline.ui.pages.focus_page_notes.opening_system_speech_recognition_please_wait_094428',
    ),
    _NoteVoiceInputState.listening => i18n.t(
      'inline.ui.pages.focus_page_notes.system_dictation_is_active_finish_in_the_system_panel_th_3d9db8',
    ),
    _NoteVoiceInputState.finishing => i18n.t(
      'inline.ui.pages.focus_page_notes.finalizing_the_transcript_and_inserting_it_into_the_note_7217e0',
    ),
    _NoteVoiceInputState.idle => i18n.t(
      'inline.ui.pages.focus_page_notes.use_system_speech_recognition_to_append_text_directly_to_47f989',
      params: <String, Object?>{'languageLabel': languageLabel},
    ),
  };
}

String _noteSpeechErrorText(
  AppI18n i18n,
  String? errorCode,
  String? errorMessage,
) {
  final fallback = errorMessage?.trim();
  return switch ((errorCode ?? '').trim()) {
    'permission_denied' => i18n.t(
      'inline.ui.pages.focus_page_notes.speech_permission_is_not_granted_please_allow_microphone_84829a',
    ),
    'busy' => i18n.t(
      'inline.ui.pages.focus_page_notes.system_speech_recognition_is_busy_please_try_again_short_41b142',
    ),
    'no_match' => i18n.t(
      'inline.ui.pages.focus_page_notes.no_usable_transcript_was_captured_please_try_again_b549a2',
    ),
    'language_not_supported' => i18n.t(
      'inline.ui.pages.focus_page_notes.the_selected_recognition_language_is_not_supported_try_t_0c606c',
    ),
    'not_listening' => i18n.t(
      'inline.ui.pages.focus_page_notes.there_is_no_active_system_dictation_session_cc87c2',
    ),
    'unsupported' || 'unavailable' => i18n.t(
      'inline.ui.pages.focus_page_notes.no_system_speech_recognizer_or_dictation_panel_is_availa_0d58b6',
    ),
    'cancelled' => i18n.t(
      'inline.ui.pages.focus_page_notes.system_dictation_was_cancelled_54c54d',
    ),
    _ =>
      fallback?.isNotEmpty == true
          ? fallback!
          : i18n.t(
              'inline.ui.pages.focus_page_notes.system_speech_recognition_failed_please_try_again_1fb11a',
            ),
  };
}

String _noteVoiceInputErrorText(
  AppI18n i18n,
  String? errorKey,
  Map<String, Object?> errorParams,
) {
  final key = (errorKey ?? '').trim();
  if (key.isEmpty) {
    return i18n.t(
      'inline.ui.pages.focus_page_notes.voice_input_failed_please_try_again_9ce064',
    );
  }
  try {
    return i18n.t(key, params: errorParams);
  } catch (_) {
    return key;
  }
}

String _noteVoiceRecorderErrorText(AppI18n i18n) {
  return i18n.t(
    'inline.ui.pages.focus_page_notes.unable_to_start_the_voice_input_recorder_please_check_mi_4cdbe5',
  );
}

String _noteSystemSpeechFallbackText(AppI18n i18n) {
  return i18n.t(
    'inline.ui.pages.focus_page_notes.system_speech_recognition_is_unavailable_here_so_the_app_eaefeb',
  );
}

String _noteVoiceRecordingHelperText(
  AppI18n i18n,
  _NoteVoiceInputState voiceState,
  String? languageTag,
  VoiceInputProviderType provider,
) {
  final languageLabel = _noteSpeechLanguageLabel(i18n, languageTag);
  final providerLabel = voiceInputProviderLabel(i18n, provider);
  return switch (voiceState) {
    _NoteVoiceInputState.starting => i18n.t(
      'inline.ui.pages.focus_page_notes.preparing_the_voice_input_recorder_please_wait_aefb52',
    ),
    _NoteVoiceInputState.listening => i18n.t(
      'inline.ui.pages.focus_page_notes.voice_input_recording_is_active_tap_again_to_finish_and_950275',
    ),
    _NoteVoiceInputState.finishing => i18n.t(
      'inline.ui.pages.focus_page_notes.transcribing_the_voice_input_and_inserting_it_into_the_n_693043',
    ),
    _NoteVoiceInputState.idle => i18n.t(
      'inline.ui.pages.focus_page_notes.use_providerlabel_to_append_speech_text_directly_to_the_220bf5',
      params: <String, Object?>{
        'languageLabel': languageLabel,
        'providerLabel': providerLabel,
      },
    ),
  };
}

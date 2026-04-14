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
    _NoteVoiceInputState.starting => pickUiText(
      i18n,
      zh: '正在调用系统语音识别，请稍候。',
      en: 'Opening system speech recognition. Please wait.',
    ),
    _NoteVoiceInputState.listening => pickUiText(
      i18n,
      zh: '系统听写已开始，完成后再点一次即可写入笔记。',
      en: 'System dictation is active. Finish in the system panel, then tap again to insert the text.',
    ),
    _NoteVoiceInputState.finishing => pickUiText(
      i18n,
      zh: '正在整理识别文本并写入笔记。',
      en: 'Finalizing the transcript and inserting it into the note.',
    ),
    _NoteVoiceInputState.idle => pickUiText(
      i18n,
      zh: '使用系统语音识别直接转成笔记文本，当前语言：$languageLabel。',
      en: 'Use system speech recognition to append text directly to the note. Language: $languageLabel.',
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
    'permission_denied' => pickUiText(
      i18n,
      zh: '系统语音权限未开启，请允许麦克风与语音识别权限后重试。',
      en: 'Speech permission is not granted. Please allow microphone and speech recognition access.',
    ),
    'busy' => pickUiText(
      i18n,
      zh: '系统语音识别当前正忙，请稍后再试。',
      en: 'System speech recognition is busy. Please try again shortly.',
    ),
    'no_match' => pickUiText(
      i18n,
      zh: '没有识别到可用文本，请再说一次。',
      en: 'No usable transcript was captured. Please try again.',
    ),
    'language_not_supported' => pickUiText(
      i18n,
      zh: '当前语音识别语言不受系统支持，请更换语言代码。',
      en: 'The selected recognition language is not supported. Try the system default language or a full locale such as en-US or zh-CN.',
    ),
    'not_listening' => pickUiText(
      i18n,
      zh: '当前没有进行中的系统听写。',
      en: 'There is no active system dictation session.',
    ),
    'unsupported' || 'unavailable' => pickUiText(
      i18n,
      zh: '当前设备暂不支持系统语音识别。',
      en: 'No system speech recognizer or dictation panel is available on this device.',
    ),
    'cancelled' => pickUiText(
      i18n,
      zh: '系统听写已取消。',
      en: 'System dictation was cancelled.',
    ),
    _ =>
      fallback?.isNotEmpty == true
          ? fallback!
          : pickUiText(
              i18n,
              zh: '系统语音识别失败，请稍后重试。',
              en: 'System speech recognition failed. Please try again.',
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
    return pickUiText(
      i18n,
      zh: '语音输入失败，请稍后重试。',
      en: 'Voice input failed. Please try again.',
    );
  }
  try {
    return i18n.t(key, params: errorParams);
  } catch (_) {
    return key;
  }
}

String _noteVoiceRecorderErrorText(AppI18n i18n) {
  return pickUiText(
    i18n,
    zh: '无法启动语音输入录音，请检查麦克风权限后重试。',
    en: 'Unable to start the voice input recorder. Please check microphone permission and try again.',
  );
}

String _noteSystemSpeechFallbackText(AppI18n i18n) {
  return pickUiText(
    i18n,
    zh: '当前系统语音识别不可用，已自动切换为应用内语音转写。',
    en: 'System speech recognition is unavailable here, so the app switched to built-in voice transcription.',
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
    _NoteVoiceInputState.starting => pickUiText(
      i18n,
      zh: '正在准备语音输入录音，请稍候。',
      en: 'Preparing the voice input recorder. Please wait.',
    ),
    _NoteVoiceInputState.listening => pickUiText(
      i18n,
      zh: '语音输入录音中，再点一次即可结束并转写到笔记。',
      en: 'Voice input recording is active. Tap again to finish and transcribe the note.',
    ),
    _NoteVoiceInputState.finishing => pickUiText(
      i18n,
      zh: '正在转写语音输入并写入笔记。',
      en: 'Transcribing the voice input and inserting it into the note.',
    ),
    _NoteVoiceInputState.idle => pickUiText(
      i18n,
      zh: '使用$providerLabel将语音内容追加到笔记正文。当前语言：$languageLabel。',
      en: 'Use $providerLabel to append speech text directly to the note. Language: $languageLabel.',
    ),
  };
}

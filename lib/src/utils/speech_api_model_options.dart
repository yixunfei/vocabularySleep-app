import '../i18n/app_i18n.dart';

class SpeechApiModelOption {
  const SpeechApiModelOption({
    required this.value,
    this.isFree = false,
    this.isCustom = false,
  });

  final String value;
  final bool isFree;
  final bool isCustom;
}

const String kDefaultSpeechApiModel = 'FunAudioLLM/SenseVoiceSmall';

const List<SpeechApiModelOption> kSpeechApiModelPresets =
    <SpeechApiModelOption>[
      SpeechApiModelOption(value: 'TeleAI/TeleSpeechASR', isFree: true),
      SpeechApiModelOption(value: 'FunAudioLLM/SenseVoiceSmall', isFree: true),
      SpeechApiModelOption(value: 'fnlp/MOSS-TTSD-v0.5'),
      SpeechApiModelOption(value: 'FunAudioLLM/CosyVoice2-0.5B'),
      SpeechApiModelOption(value: 'IndexTeam/IndexTTS-2'),
    ];

String normalizeSpeechApiModelValue(String? raw) {
  final value = (raw ?? '').trim();
  return value.isEmpty ? kDefaultSpeechApiModel : value;
}

List<SpeechApiModelOption> resolveSpeechApiModelOptions(String? raw) {
  final selectedValue = normalizeSpeechApiModelValue(raw);
  final options = List<SpeechApiModelOption>.from(kSpeechApiModelPresets);
  final alreadyIncluded = options.any(
    (option) => option.value == selectedValue,
  );
  if (!alreadyIncluded) {
    options.insert(
      0,
      SpeechApiModelOption(value: selectedValue, isCustom: true),
    );
  }
  return options;
}

String speechApiModelOptionLabel(AppI18n i18n, SpeechApiModelOption option) {
  final locale = AppI18n.normalizeLanguageCode(i18n.languageCode);
  final freeText = switch (locale) {
    'zh' => '免费',
    'ja' => '無料',
    'de' => 'Kostenlos',
    'fr' => 'Gratuit',
    'es' => 'Gratis',
    'ru' => 'Бесплатно',
    _ => 'Free',
  };
  final currentText = switch (locale) {
    'zh' => '当前配置',
    'ja' => '現在の設定',
    'de' => 'Aktuell',
    'fr' => 'Actuel',
    'es' => 'Actual',
    'ru' => 'Текущий',
    _ => 'Current',
  };
  if (option.isCustom) {
    return '$currentText: ${option.value}';
  }
  if (option.isFree) {
    return '${option.value} ($freeText)';
  }
  return option.value;
}

String speechApiModelHelperText(AppI18n i18n) {
  return switch (AppI18n.normalizeLanguageCode(i18n.languageCode)) {
    'zh' =>
      'TeleAI/TeleSpeechASR 与 FunAudioLLM/SenseVoiceSmall 为免费模型；其余选项需由当前服务端支持对应识别接口。',
    'ja' =>
      'TeleAI/TeleSpeechASR と FunAudioLLM/SenseVoiceSmall は無料モデルです。その他の項目は、現在のサービス側で対応する認識 API をサポートしている必要があります。',
    'de' =>
      'TeleAI/TeleSpeechASR und FunAudioLLM/SenseVoiceSmall sind kostenlos. Die restlichen Optionen setzen voraus, dass Ihr aktueller Dienst die jeweilige Erkennungs-API unterstützt.',
    'fr' =>
      'TeleAI/TeleSpeechASR et FunAudioLLM/SenseVoiceSmall sont gratuits. Les autres options exigent que votre service actuel prenne en charge l’API de reconnaissance correspondante.',
    'es' =>
      'TeleAI/TeleSpeechASR y FunAudioLLM/SenseVoiceSmall son modelos gratuitos. Las demas opciones requieren que el servicio actual admita la API de reconocimiento correspondiente.',
    'ru' =>
      'TeleAI/TeleSpeechASR и FunAudioLLM/SenseVoiceSmall бесплатны. Для остальных вариантов текущий сервис должен поддерживать соответствующий API распознавания.',
    _ =>
      'TeleAI/TeleSpeechASR and FunAudioLLM/SenseVoiceSmall are free models. The other options require backend support for the matching recognition API.',
  };
}

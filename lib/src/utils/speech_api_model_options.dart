import '../i18n/app_i18n.dart';
import '../models/play_config.dart';
import 'asr_language.dart';

enum SpeechModelSource { preset, fetched, current }

class SpeechApiModelOption {
  const SpeechApiModelOption({
    required this.value,
    this.displayName,
    this.providerLabelKey,
    this.voiceIds = const <String>[],
    this.languageCodes = const <String>[],
    this.isFree = false,
    this.isCustom = false,
    this.isFetched = false,
    this.isRecommended = false,
  });

  final String value;
  final String? displayName;
  final String? providerLabelKey;
  final List<String> voiceIds;
  final List<String> languageCodes;
  final bool isFree;
  final bool isCustom;
  final bool isFetched;
  final bool isRecommended;

  SpeechApiModelOption copyWith({
    String? displayName,
    String? providerLabelKey,
    List<String>? voiceIds,
    List<String>? languageCodes,
    bool? isFree,
    bool? isCustom,
    bool? isFetched,
    bool? isRecommended,
  }) {
    return SpeechApiModelOption(
      value: value,
      displayName: displayName ?? this.displayName,
      providerLabelKey: providerLabelKey ?? this.providerLabelKey,
      voiceIds: voiceIds ?? this.voiceIds,
      languageCodes: languageCodes ?? this.languageCodes,
      isFree: isFree ?? this.isFree,
      isCustom: isCustom ?? this.isCustom,
      isFetched: isFetched ?? this.isFetched,
      isRecommended: isRecommended ?? this.isRecommended,
    );
  }
}

class SpeechApiVoiceOption {
  const SpeechApiVoiceOption({
    required this.value,
    required this.labelKey,
    this.languageCodes = const <String>[],
  });

  final String value;
  final String labelKey;
  final List<String> languageCodes;
}

const String kDefaultSpeechApiModel = 'FunAudioLLM/SenseVoiceSmall';
const String kDefaultTtsApiModel = 'FunAudioLLM/CosyVoice2-0.5B';
const String kDefaultTtsApiVoice = 'alex';
const String kDefaultAliyunTtsModel = 'qwen3-tts-instruct-flash';
const String kDefaultAliyunTtsVoice = 'Cherry';
const String kDefaultAliyunAsrModel = 'qwen3-asr-flash';
const String kDefaultDoubaoTtsModel = 'volcano_tts';
const String kDefaultDoubaoTtsVoice = 'zh_female_wanwanxiaohe_moon_bigtts';
const String kDefaultDoubaoAsrModel = 'doubao-seed-1-6-flash';
const String kAliyunQwenTtsEndpoint =
    'https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation';
const String kAliyunCosyVoiceTtsEndpoint =
    'https://dashscope.aliyuncs.com/api/v1/services/audio/tts/SpeechSynthesizer';

const List<String> kSpeechApiLanguages = <String>[
  'auto',
  'zh-CN',
  'en-US',
  'ja-JP',
  'ko-KR',
  'de-DE',
  'fr-FR',
  'es-ES',
  'ru-RU',
];

const List<String> _aliyunQwenTtsVoices = <String>[
  'Cherry',
  'Chelsie',
  'Ethan',
  'Serena',
];

const List<String> _aliyunCosyVoiceV3Voices = <String>[
  'longanyang',
  'longanhuan',
  'longhuhu_v3',
  'longpaopao_v3',
  'longjielidou_v3',
  'longxian_v3',
  'longling_v3',
  'longshanshan_v3',
  'longanlang_v3',
  'longanwen_v3',
];

const List<String> _aliyunCosyVoiceV2Voices = <String>[
  'longxiaochun_v2',
  'longxiaoxia_v2',
  'longxiaobai_v2',
  'longxiaocheng_v2',
  'longwan_v2',
  'longyingmu',
  'longhuhu',
  'longanran',
  'longanchong',
];

const List<String> _aliyunCosyVoiceLegacyVoices = <String>[
  'longxiaochun',
  'longxiaoxia',
  'longxiaocheng',
  'longxiaobai',
];

const List<String> _doubaoBigTtsVoices = <String>[
  'zh_female_wanwanxiaohe_moon_bigtts',
  'zh_female_xinlingjitang_moon_bigtts',
  'zh_female_tianmeixiaoyuan_moon_bigtts',
  'zh_male_shaonianzixin_moon_bigtts',
  'zh_male_yangguangqingnian_moon_bigtts',
  'en_female_amanda_mars_bigtts',
  'en_male_adam_mars_bigtts',
];

const List<String> _doubaoLegacyStreamingVoices = <String>[
  'BV001_streaming',
  'BV002_streaming',
  'BV700_streaming',
  'BV701_streaming',
];

const List<String> _siliconFlowVoices = <String>[
  'alex',
  'anna',
  'bella',
  'benjamin',
  'charles',
  'claire',
  'david',
  'diana',
];

const List<SpeechApiModelOption> kSpeechApiModelPresets =
    <SpeechApiModelOption>[
      SpeechApiModelOption(
        value: 'TeleAI/TeleSpeechASR',
        languageCodes: kSpeechApiLanguages,
      ),
      SpeechApiModelOption(
        value: 'FunAudioLLM/SenseVoiceSmall',
        isRecommended: true,
        languageCodes: kSpeechApiLanguages,
      ),
      SpeechApiModelOption(
        value: 'fnlp/MOSS-TTSD-v0.5',
        voiceIds: _siliconFlowVoices,
        languageCodes: kSpeechApiLanguages,
      ),
      SpeechApiModelOption(
        value: 'FunAudioLLM/CosyVoice2-0.5B',
        voiceIds: _siliconFlowVoices,
        languageCodes: kSpeechApiLanguages,
      ),
      SpeechApiModelOption(
        value: 'IndexTeam/IndexTTS-2',
        voiceIds: _siliconFlowVoices,
        languageCodes: kSpeechApiLanguages,
      ),
    ];

const List<SpeechApiModelOption> _aliyunTtsModels = <SpeechApiModelOption>[
  SpeechApiModelOption(
    value: kDefaultAliyunTtsModel,
    displayName: 'Qwen3 TTS Instruct Flash',
    voiceIds: _aliyunQwenTtsVoices,
    languageCodes: kSpeechApiLanguages,
    isRecommended: true,
  ),
  SpeechApiModelOption(
    value: 'qwen3-tts-flash',
    displayName: 'Qwen3 TTS Flash',
    voiceIds: _aliyunQwenTtsVoices,
    languageCodes: kSpeechApiLanguages,
  ),
  SpeechApiModelOption(
    value: 'qwen-tts-latest',
    displayName: 'Qwen TTS Latest',
    voiceIds: _aliyunQwenTtsVoices,
    languageCodes: kSpeechApiLanguages,
  ),
  SpeechApiModelOption(
    value: 'qwen-tts-v1',
    displayName: 'Qwen TTS V1',
    voiceIds: _aliyunQwenTtsVoices,
    languageCodes: kSpeechApiLanguages,
  ),
  SpeechApiModelOption(
    value: 'cosyvoice-v3-flash',
    displayName: 'CosyVoice V3 Flash',
    voiceIds: _aliyunCosyVoiceV3Voices,
    languageCodes: <String>['auto', 'zh-CN', 'en-US'],
  ),
  SpeechApiModelOption(
    value: 'cosyvoice-v3-plus',
    displayName: 'CosyVoice V3 Plus',
    voiceIds: _aliyunCosyVoiceV3Voices,
    languageCodes: <String>['auto', 'zh-CN', 'en-US'],
  ),
  SpeechApiModelOption(
    value: 'cosyvoice-v2',
    displayName: 'CosyVoice V2',
    voiceIds: _aliyunCosyVoiceV2Voices,
    languageCodes: kSpeechApiLanguages,
  ),
];

const List<SpeechApiModelOption> _doubaoTtsModels = <SpeechApiModelOption>[
  SpeechApiModelOption(
    value: kDefaultDoubaoTtsModel,
    displayName: 'Volcano TTS',
    voiceIds: _doubaoBigTtsVoices,
    languageCodes: <String>['auto', 'zh-CN', 'en-US'],
    isRecommended: true,
  ),
  SpeechApiModelOption(
    value: 'volcano_tts_legacy_streaming',
    displayName: 'Volcano TTS Legacy Streaming',
    voiceIds: _doubaoLegacyStreamingVoices,
    languageCodes: <String>['auto', 'zh-CN', 'en-US'],
  ),
];

const List<SpeechApiModelOption> _aliyunAsrModels = <SpeechApiModelOption>[
  SpeechApiModelOption(
    value: kDefaultAliyunAsrModel,
    displayName: 'Qwen3 ASR Flash',
    languageCodes: kSpeechApiLanguages,
    isRecommended: true,
  ),
  SpeechApiModelOption(
    value: 'qwen3-asr-plus',
    displayName: 'Qwen3 ASR Plus',
    languageCodes: kSpeechApiLanguages,
  ),
  SpeechApiModelOption(
    value: 'paraformer-v2',
    displayName: 'Paraformer V2',
    languageCodes: kSpeechApiLanguages,
  ),
];

const List<SpeechApiModelOption> _doubaoAsrModels = <SpeechApiModelOption>[
  SpeechApiModelOption(
    value: kDefaultDoubaoAsrModel,
    displayName: 'Doubao Seed 1.6 Flash',
    languageCodes: kSpeechApiLanguages,
    isRecommended: true,
  ),
  SpeechApiModelOption(
    value: 'doubao-1-5-vision-pro',
    displayName: 'Doubao 1.5 Vision Pro',
    languageCodes: kSpeechApiLanguages,
  ),
];

const List<SpeechApiVoiceOption> _knownVoiceOptions = <SpeechApiVoiceOption>[
  SpeechApiVoiceOption(
    value: 'alex',
    labelKey: 'speech.remote.voice.alex',
    languageCodes: kSpeechApiLanguages,
  ),
  SpeechApiVoiceOption(
    value: 'anna',
    labelKey: 'speech.remote.voice.anna',
    languageCodes: kSpeechApiLanguages,
  ),
  SpeechApiVoiceOption(
    value: 'bella',
    labelKey: 'speech.remote.voice.bella',
    languageCodes: kSpeechApiLanguages,
  ),
  SpeechApiVoiceOption(
    value: 'benjamin',
    labelKey: 'speech.remote.voice.benjamin',
    languageCodes: kSpeechApiLanguages,
  ),
  SpeechApiVoiceOption(
    value: 'charles',
    labelKey: 'speech.remote.voice.charles',
    languageCodes: kSpeechApiLanguages,
  ),
  SpeechApiVoiceOption(
    value: 'claire',
    labelKey: 'speech.remote.voice.claire',
    languageCodes: kSpeechApiLanguages,
  ),
  SpeechApiVoiceOption(
    value: 'david',
    labelKey: 'speech.remote.voice.david',
    languageCodes: kSpeechApiLanguages,
  ),
  SpeechApiVoiceOption(
    value: 'diana',
    labelKey: 'speech.remote.voice.diana',
    languageCodes: kSpeechApiLanguages,
  ),
  SpeechApiVoiceOption(
    value: 'Cherry',
    labelKey: 'speech.remote.voice.cherry',
    languageCodes: kSpeechApiLanguages,
  ),
  SpeechApiVoiceOption(
    value: 'Chelsie',
    labelKey: 'speech.remote.voice.chelsie',
    languageCodes: kSpeechApiLanguages,
  ),
  SpeechApiVoiceOption(
    value: 'Ethan',
    labelKey: 'speech.remote.voice.ethan',
    languageCodes: kSpeechApiLanguages,
  ),
  SpeechApiVoiceOption(
    value: 'Serena',
    labelKey: 'speech.remote.voice.serena',
    languageCodes: kSpeechApiLanguages,
  ),
  SpeechApiVoiceOption(
    value: 'BV001_streaming',
    labelKey: 'speech.remote.voice.doubao_bv001',
    languageCodes: <String>['zh-CN'],
  ),
  SpeechApiVoiceOption(
    value: 'BV002_streaming',
    labelKey: 'speech.remote.voice.doubao_bv002',
    languageCodes: <String>['zh-CN'],
  ),
  SpeechApiVoiceOption(
    value: 'BV700_streaming',
    labelKey: 'speech.remote.voice.doubao_bv700',
    languageCodes: <String>['zh-CN'],
  ),
  SpeechApiVoiceOption(
    value: 'BV701_streaming',
    labelKey: 'speech.remote.voice.doubao_bv701',
    languageCodes: <String>['zh-CN'],
  ),
  SpeechApiVoiceOption(
    value: 'zh_female_wanwanxiaohe_moon_bigtts',
    labelKey: 'speech.remote.voice.doubao_wanwan',
    languageCodes: <String>['zh-CN'],
  ),
  SpeechApiVoiceOption(
    value: 'zh_female_xinlingjitang_moon_bigtts',
    labelKey: 'speech.remote.voice.doubao_xinling',
    languageCodes: <String>['zh-CN'],
  ),
  SpeechApiVoiceOption(
    value: 'zh_female_tianmeixiaoyuan_moon_bigtts',
    labelKey: 'speech.remote.voice.doubao_tianmei',
    languageCodes: <String>['zh-CN'],
  ),
  SpeechApiVoiceOption(
    value: 'zh_male_shaonianzixin_moon_bigtts',
    labelKey: 'speech.remote.voice.doubao_shaonian',
    languageCodes: <String>['zh-CN'],
  ),
  SpeechApiVoiceOption(
    value: 'zh_male_yangguangqingnian_moon_bigtts',
    labelKey: 'speech.remote.voice.doubao_yangguang',
    languageCodes: <String>['zh-CN'],
  ),
  SpeechApiVoiceOption(
    value: 'en_female_amanda_mars_bigtts',
    labelKey: 'speech.remote.voice.doubao_amanda',
    languageCodes: <String>['en-US'],
  ),
  SpeechApiVoiceOption(
    value: 'en_male_adam_mars_bigtts',
    labelKey: 'speech.remote.voice.doubao_adam',
    languageCodes: <String>['en-US'],
  ),
];

String normalizeSpeechApiModelValue(
  String? raw, {
  AsrProviderType provider = AsrProviderType.api,
}) {
  final value = (raw ?? '').trim();
  if (value.isNotEmpty) return value;
  return defaultAsrModelForProvider(provider);
}

String defaultAsrModelForProvider(AsrProviderType provider) {
  return switch (provider) {
    AsrProviderType.aliyunBailian => kDefaultAliyunAsrModel,
    AsrProviderType.doubao => kDefaultDoubaoAsrModel,
    _ => kDefaultSpeechApiModel,
  };
}

String defaultTtsModelForProvider(TtsProviderType provider) {
  return switch (provider) {
    TtsProviderType.aliyunBailian => kDefaultAliyunTtsModel,
    TtsProviderType.doubao => kDefaultDoubaoTtsModel,
    _ => kDefaultTtsApiModel,
  };
}

String defaultTtsVoiceForProvider(TtsProviderType provider) {
  return switch (provider) {
    TtsProviderType.aliyunBailian => kDefaultAliyunTtsVoice,
    TtsProviderType.doubao => kDefaultDoubaoTtsVoice,
    _ => kDefaultTtsApiVoice,
  };
}

bool isAliyunCosyVoiceTtsModel(String model) {
  return model.trim().toLowerCase().contains('cosyvoice');
}

String defaultAliyunTtsEndpointForModel(String model) {
  return isAliyunCosyVoiceTtsModel(model)
      ? kAliyunCosyVoiceTtsEndpoint
      : kAliyunQwenTtsEndpoint;
}

List<String> defaultTtsVoicesForModel({
  required TtsProviderType provider,
  required String model,
}) {
  if (provider == TtsProviderType.aliyunBailian) {
    return aliyunTtsVoicesForModel(model);
  }
  return defaultTtsVoicesForProvider(provider);
}

String defaultTtsVoiceForModel({
  required TtsProviderType provider,
  required String model,
}) {
  final voices = defaultTtsVoicesForModel(provider: provider, model: model);
  return voices.isEmpty ? defaultTtsVoiceForProvider(provider) : voices.first;
}

bool isRemoteTtsProvider(TtsProviderType provider) =>
    provider != TtsProviderType.local;

bool isAsrApiProvider(AsrProviderType provider) {
  return switch (provider) {
    AsrProviderType.api ||
    AsrProviderType.aliyunBailian ||
    AsrProviderType.doubao ||
    AsrProviderType.customApi => true,
    _ => false,
  };
}

bool ttsProviderNeedsBaseUrl(TtsProviderType provider) =>
    provider == TtsProviderType.customApi;

bool asrProviderNeedsBaseUrl(AsrProviderType provider) =>
    provider == AsrProviderType.customApi;

bool ttsProviderNeedsAppId(TtsProviderType provider) =>
    provider == TtsProviderType.doubao;

bool ttsProviderCanFetchModels(TtsProviderType provider) {
  return switch (provider) {
    TtsProviderType.api ||
    TtsProviderType.aliyunBailian ||
    TtsProviderType.customApi => true,
    _ => false,
  };
}

bool asrProviderCanFetchModels(AsrProviderType provider) {
  return switch (provider) {
    AsrProviderType.api ||
    AsrProviderType.aliyunBailian ||
    AsrProviderType.doubao ||
    AsrProviderType.customApi => true,
    _ => false,
  };
}

List<SpeechApiModelOption> resolveSpeechApiModelOptions(String? raw) {
  return resolveAsrApiModelOptions(
    provider: AsrProviderType.api,
    selectedModel: raw,
  );
}

List<SpeechApiModelOption> resolveAsrApiModelOptions({
  required AsrProviderType provider,
  required String? selectedModel,
  Iterable<String> fetchedModelIds = const <String>[],
}) {
  final selectedValue = normalizeSpeechApiModelValue(
    selectedModel,
    provider: provider,
  );
  final presets = switch (provider) {
    AsrProviderType.aliyunBailian => _aliyunAsrModels,
    AsrProviderType.doubao => _doubaoAsrModels,
    _ => kSpeechApiModelPresets,
  };
  return _mergeModelOptions(
    presets: presets,
    selectedValue: selectedValue,
    fetchedModelIds: fetchedModelIds,
    fallbackLanguages: kSpeechApiLanguages,
  );
}

List<SpeechApiModelOption> resolveTtsApiModelOptions({
  required TtsProviderType provider,
  required String? selectedModel,
  Iterable<String> fetchedModelIds = const <String>[],
}) {
  final selectedValue = (selectedModel ?? '').trim().isEmpty
      ? defaultTtsModelForProvider(provider)
      : selectedModel!.trim();
  final presets = switch (provider) {
    TtsProviderType.aliyunBailian => _aliyunTtsModels,
    TtsProviderType.doubao => _doubaoTtsModels,
    _ =>
      kSpeechApiModelPresets
          .where((option) => option.voiceIds.isNotEmpty)
          .toList(growable: false),
  };
  final fallbackVoices = defaultTtsVoicesForProvider(provider);
  return _mergeModelOptions(
    presets: presets,
    selectedValue: selectedValue,
    fetchedModelIds: fetchedModelIds,
    fallbackVoices: fallbackVoices,
    fallbackLanguages: kSpeechApiLanguages,
    fallbackVoicesForValue: (model) =>
        defaultTtsVoicesForModel(provider: provider, model: model),
    fallbackLanguagesForValue: (model) =>
        ttsLanguagesForModel(provider: provider, model: model),
  );
}

List<SpeechApiModelOption> _mergeModelOptions({
  required List<SpeechApiModelOption> presets,
  required String selectedValue,
  required Iterable<String> fetchedModelIds,
  List<String> fallbackVoices = const <String>[],
  List<String> fallbackLanguages = const <String>[],
  List<String> Function(String model)? fallbackVoicesForValue,
  List<String> Function(String model)? fallbackLanguagesForValue,
}) {
  final output = <SpeechApiModelOption>[];
  void addOption(SpeechApiModelOption option) {
    final value = option.value.trim();
    if (value.isEmpty || output.any((item) => item.value == value)) {
      return;
    }
    output.add(option);
  }

  for (final option in presets) {
    addOption(option);
  }
  for (final raw in fetchedModelIds) {
    final value = raw.trim();
    if (value.isEmpty) continue;
    addOption(
      SpeechApiModelOption(
        value: value,
        isFetched: true,
        voiceIds: fallbackVoicesForValue?.call(value) ?? fallbackVoices,
        languageCodes:
            fallbackLanguagesForValue?.call(value) ?? fallbackLanguages,
      ),
    );
  }
  if (selectedValue.trim().isNotEmpty &&
      !output.any((option) => option.value == selectedValue)) {
    output.insert(
      0,
      SpeechApiModelOption(
        value: selectedValue,
        isCustom: true,
        voiceIds: fallbackVoicesForValue?.call(selectedValue) ?? fallbackVoices,
        languageCodes:
            fallbackLanguagesForValue?.call(selectedValue) ?? fallbackLanguages,
      ),
    );
  }
  if (output.isEmpty) {
    output.add(
      SpeechApiModelOption(
        value: selectedValue,
        isCustom: true,
        voiceIds: fallbackVoicesForValue?.call(selectedValue) ?? fallbackVoices,
        languageCodes:
            fallbackLanguagesForValue?.call(selectedValue) ?? fallbackLanguages,
      ),
    );
  }
  return output;
}

List<String> defaultTtsVoicesForProvider(TtsProviderType provider) {
  return switch (provider) {
    TtsProviderType.aliyunBailian => _aliyunQwenTtsVoices,
    TtsProviderType.doubao => _doubaoBigTtsVoices,
    _ => _siliconFlowVoices,
  };
}

List<String> aliyunTtsVoicesForModel(String model) {
  final lower = model.trim().toLowerCase();
  if (!isAliyunCosyVoiceTtsModel(lower)) {
    return _aliyunQwenTtsVoices;
  }
  if (lower.contains('v2')) {
    return _aliyunCosyVoiceV2Voices;
  }
  if (lower.contains('v3')) {
    return _aliyunCosyVoiceV3Voices;
  }
  return _aliyunCosyVoiceLegacyVoices;
}

List<String> ttsLanguagesForModel({
  required TtsProviderType provider,
  required String model,
}) {
  final lower = model.trim().toLowerCase();
  if (provider == TtsProviderType.aliyunBailian &&
      isAliyunCosyVoiceTtsModel(lower) &&
      lower.contains('v3')) {
    return const <String>['auto', 'zh-CN', 'en-US'];
  }
  if (provider == TtsProviderType.doubao) {
    return const <String>['auto', 'zh-CN', 'en-US'];
  }
  return kSpeechApiLanguages;
}

List<String> resolveTtsVoiceOptions({
  required TtsProviderType provider,
  required String? selectedModel,
  required String selectedVoice,
  String selectedLanguage = 'auto',
  Iterable<String> savedVoices = const <String>[],
  Iterable<String> fetchedModelIds = const <String>[],
  bool includeSavedVoices = true,
  bool includeSelectedVoice = true,
}) {
  final modelOptions = resolveTtsApiModelOptions(
    provider: provider,
    selectedModel: selectedModel,
    fetchedModelIds: fetchedModelIds,
  );
  final model = modelOptions.firstWhere(
    (option) => option.value == ((selectedModel ?? '').trim()),
    orElse: () => modelOptions.first,
  );
  final output = <String>[];
  void add(String raw) {
    final value = raw.trim();
    if (value.isEmpty || output.contains(value)) return;
    if (!_voiceSupportsModel(provider, model.value, value)) return;
    if (!_voiceSupportsLanguage(value, selectedLanguage)) return;
    output.add(value);
  }

  for (final voice in model.voiceIds) {
    add(voice);
  }
  if (output.isEmpty) {
    for (final voice in defaultTtsVoicesForProvider(provider)) {
      add(voice);
    }
  }
  if (includeSavedVoices) {
    for (final voice in savedVoices) {
      add(voice);
    }
  }
  if (includeSelectedVoice &&
      _voiceSupportsLanguage(selectedVoice, selectedLanguage)) {
    add(selectedVoice);
  }
  if (output.isEmpty) {
    add(defaultTtsVoiceForModel(provider: provider, model: model.value));
  }
  return output;
}

bool _voiceSupportsModel(TtsProviderType provider, String model, String voice) {
  if (provider == TtsProviderType.customApi) return true;
  final voices = defaultTtsVoicesForModel(provider: provider, model: model);
  if (voices.isEmpty) return true;
  final normalized = voice.trim().toLowerCase();
  return voices.any((item) => item.toLowerCase() == normalized);
}

bool _voiceSupportsLanguage(String voice, String language) {
  final normalizedLanguage = normalizeAsrLanguageTag(language);
  if (normalizedLanguage == 'auto') return true;
  for (final option in _knownVoiceOptions) {
    if (option.value.toLowerCase() == voice.trim().toLowerCase()) {
      if (option.languageCodes.isEmpty) return true;
      return option.languageCodes
          .map(normalizeAsrLanguageTag)
          .contains(normalizedLanguage);
    }
  }
  return true;
}

SpeechApiModelOption? ttsModelOptionForValue({
  required TtsProviderType provider,
  required String model,
  Iterable<String> fetchedModelIds = const <String>[],
}) {
  final options = resolveTtsApiModelOptions(
    provider: provider,
    selectedModel: model,
    fetchedModelIds: fetchedModelIds,
  );
  for (final option in options) {
    if (option.value == model.trim()) return option;
  }
  return options.isEmpty ? null : options.first;
}

String selectTtsLanguageForModel({
  required TtsProviderType provider,
  required String model,
  required String currentLanguage,
  Iterable<String> fetchedModelIds = const <String>[],
}) {
  final option = ttsModelOptionForValue(
    provider: provider,
    model: model,
    fetchedModelIds: fetchedModelIds,
  );
  final languages = resolveSpeechLanguageOptions(
    modelLanguages: option?.languageCodes ?? kSpeechApiLanguages,
    selectedLanguage: currentLanguage,
    includeSelectedLanguage: false,
  );
  final normalizedCurrent = normalizeAsrLanguageTag(currentLanguage);
  if (languages.contains(normalizedCurrent)) return normalizedCurrent;
  return languages.isEmpty ? 'auto' : languages.first;
}

String selectTtsVoiceForModelLanguage({
  required TtsProviderType provider,
  required String model,
  required String currentVoice,
  required String language,
  Iterable<String> savedVoices = const <String>[],
  Iterable<String> fetchedModelIds = const <String>[],
  bool includeSavedVoices = true,
  bool includeCurrentVoice = true,
}) {
  final voices = resolveTtsVoiceOptions(
    provider: provider,
    selectedModel: model,
    selectedVoice: currentVoice,
    selectedLanguage: language,
    savedVoices: savedVoices,
    fetchedModelIds: fetchedModelIds,
    includeSavedVoices: includeSavedVoices,
    includeSelectedVoice: includeCurrentVoice,
  );
  final normalizedCurrent = currentVoice.trim();
  if (voices.contains(normalizedCurrent)) return normalizedCurrent;
  return voices.isEmpty
      ? defaultTtsVoiceForModel(provider: provider, model: model)
      : voices.first;
}

List<String> filterTtsModelIdsForProvider(
  TtsProviderType provider,
  Iterable<String> modelIds,
) {
  final output = <String>[];
  for (final raw in modelIds) {
    final value = raw.trim();
    if (value.isEmpty || output.contains(value)) continue;
    if (_looksLikeTtsModel(provider, value)) {
      output.add(value);
    }
  }
  return output;
}

bool _looksLikeTtsModel(TtsProviderType provider, String modelId) {
  final lower = modelId.toLowerCase();
  if (lower.contains('asr') ||
      lower.contains('whisper') ||
      lower.contains('sensevoice') ||
      lower.contains('transcription')) {
    return false;
  }
  if (provider == TtsProviderType.aliyunBailian) {
    return lower.contains('tts') || lower.contains('cosyvoice');
  }
  if (provider == TtsProviderType.doubao) {
    return lower.contains('tts') || lower.contains('speech');
  }
  return lower.contains('tts') ||
      lower.contains('cosyvoice') ||
      lower.contains('speech') ||
      lower.contains('voice');
}

List<String> resolveSpeechLanguageOptions({
  required List<String> modelLanguages,
  required String selectedLanguage,
  bool includeSelectedLanguage = true,
}) {
  final output = <String>[];
  void add(String raw) {
    final value = normalizeAsrLanguageTag(raw);
    if (value.isEmpty || output.contains(value)) return;
    output.add(value);
  }

  for (final language
      in modelLanguages.isEmpty ? kSpeechApiLanguages : modelLanguages) {
    add(language);
  }
  if (includeSelectedLanguage) {
    add(selectedLanguage);
  }
  if (output.isEmpty) add('auto');
  return output;
}

String speechApiModelOptionLabel(AppI18n i18n, SpeechApiModelOption option) {
  final label = option.displayName?.trim().isNotEmpty == true
      ? option.displayName!.trim()
      : option.value;
  final badges = <String>[];
  if (option.isRecommended) {
    badges.add(i18n.t('speech.remote.badge.recommended'));
  }
  if (option.isFetched) badges.add(i18n.t('speech.remote.badge.fetched'));
  if (option.isCustom) badges.add(i18n.t('speech.remote.badge.current'));
  if (badges.isEmpty) return label;
  return '$label (${badges.join(', ')})';
}

String speechApiModelHelperText(
  AppI18n i18n, {
  AsrProviderType? asrProvider,
  TtsProviderType? ttsProvider,
}) {
  if (ttsProvider != null) {
    return switch (ttsProvider) {
      TtsProviderType.aliyunBailian => i18n.t(
        'speech.remote.tts.helper.aliyun',
      ),
      TtsProviderType.doubao => i18n.t('speech.remote.tts.helper.doubao'),
      TtsProviderType.customApi => i18n.t('speech.remote.tts.helper.custom'),
      _ => i18n.t('speech.remote.tts.helper.siliconflow'),
    };
  }
  return switch (asrProvider) {
    AsrProviderType.aliyunBailian => i18n.t('speech.remote.asr.helper.aliyun'),
    AsrProviderType.doubao => i18n.t('speech.remote.asr.helper.doubao'),
    AsrProviderType.customApi => i18n.t('speech.remote.asr.helper.custom'),
    _ => i18n.t('speech.remote.asr.helper.siliconflow'),
  };
}

String speechApiVoiceOptionLabel(
  AppI18n i18n, {
  required TtsProviderType provider,
  required String voice,
}) {
  final normalized = voice.trim();
  if (normalized.isEmpty) return i18n.t('defaultVoice');
  for (final option in _knownVoiceOptions) {
    if (option.value.toLowerCase() == normalized.toLowerCase()) {
      return i18n.t(option.labelKey, params: <String, Object?>{'id': voice});
    }
  }
  return normalized;
}

String speechApiLanguageLabel(AppI18n i18n, String code) {
  return asrLanguageLabel(i18n, code);
}

String defaultTtsEndpointForProvider(TtsProviderType provider) {
  return switch (provider) {
    TtsProviderType.aliyunBailian => kAliyunQwenTtsEndpoint,
    TtsProviderType.doubao => 'https://openspeech.bytedance.com/api/v1/tts',
    _ => 'https://api.siliconflow.cn/v1/audio/speech',
  };
}

String defaultAsrEndpointForProvider(AsrProviderType provider) {
  return switch (provider) {
    AsrProviderType.aliyunBailian =>
      'https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation',
    AsrProviderType.doubao =>
      'https://ark.cn-beijing.volces.com/api/v3/responses',
    _ => 'https://api.siliconflow.cn/v1/audio/transcriptions',
  };
}

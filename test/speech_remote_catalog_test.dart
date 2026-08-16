import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/services/speech_remote_model_service.dart';
import 'package:vocabulary_sleep_app/src/utils/speech_api_model_options.dart';

void main() {
  group('speech remote catalog', () {
    test('resolves provider defaults for TTS and ASR', () {
      expect(
        defaultTtsModelForProvider(TtsProviderType.aliyunBailian),
        'qwen3-tts-instruct-flash',
      );
      expect(
        defaultTtsVoiceForProvider(TtsProviderType.doubao),
        'zh_female_wanwanxiaohe_moon_bigtts',
      );
      expect(
        defaultAsrModelForProvider(AsrProviderType.aliyunBailian),
        'qwen3-asr-flash',
      );
      expect(
        const VoiceInputConfig(
          provider: VoiceInputProviderType.doubao,
          language: 'auto',
          model: 'doubao-seed-1-6-flash',
        ).recordingProvider,
        AsrProviderType.doubao,
      );
    });

    test('model options merge fetched and current custom values', () {
      final options = resolveAsrApiModelOptions(
        provider: AsrProviderType.aliyunBailian,
        selectedModel: 'custom-asr-model',
        fetchedModelIds: const <String>['qwen3-asr-flash', 'fetched-model'],
      );

      expect(options.first.value, 'custom-asr-model');
      expect(options.first.isCustom, isTrue);
      expect(options.map((option) => option.value), contains('fetched-model'));
      expect(
        options
            .firstWhere((option) => option.value == 'fetched-model')
            .isFetched,
        isTrue,
      );
    });

    test('TTS voice options follow provider model presets', () {
      final aliyunModels = resolveTtsApiModelOptions(
        provider: TtsProviderType.aliyunBailian,
        selectedModel: 'qwen3-tts-instruct-flash',
      );
      final aliyunVoices = resolveTtsVoiceOptions(
        provider: TtsProviderType.aliyunBailian,
        selectedModel: 'qwen3-tts-instruct-flash',
        selectedVoice: '',
      );
      final doubaoVoices = resolveTtsVoiceOptions(
        provider: TtsProviderType.doubao,
        selectedModel: 'volcano_tts',
        selectedVoice: '',
      );

      expect(aliyunModels.first.languageCodes, contains('ja-JP'));
      expect(aliyunModels.first.languageCodes, contains('de-DE'));
      expect(aliyunVoices, contains('Cherry'));
      expect(doubaoVoices, contains('zh_female_wanwanxiaohe_moon_bigtts'));
    });

    test('Aliyun TTS endpoint and voices follow model family', () {
      expect(
        defaultAliyunTtsEndpointForModel('qwen3-tts-instruct-flash'),
        kAliyunQwenTtsEndpoint,
      );
      expect(
        defaultAliyunTtsEndpointForModel('cosyvoice-v3-flash'),
        kAliyunCosyVoiceTtsEndpoint,
      );
      expect(isAliyunCosyVoiceTtsModel('cosyvoice-v3-flash'), isTrue);
      expect(isAliyunCosyVoiceTtsModel('qwen3-tts-instruct-flash'), isFalse);

      final cosyV3Voices = resolveTtsVoiceOptions(
        provider: TtsProviderType.aliyunBailian,
        selectedModel: 'cosyvoice-v3-flash',
        selectedVoice: 'Cherry',
        selectedLanguage: 'zh-CN',
        savedVoices: const <String>['Cherry'],
      );
      final cosyV2Voices = resolveTtsVoiceOptions(
        provider: TtsProviderType.aliyunBailian,
        selectedModel: 'cosyvoice-v2',
        selectedVoice: 'longanyang',
        selectedLanguage: 'zh-CN',
      );

      expect(cosyV3Voices, contains('longanyang'));
      expect(cosyV3Voices, isNot(contains('Cherry')));
      expect(cosyV2Voices, contains('longxiaochun_v2'));
      expect(cosyV2Voices, isNot(contains('longanyang')));
    });

    test('TTS model changes reset unsupported language and voice', () {
      final language = selectTtsLanguageForModel(
        provider: TtsProviderType.aliyunBailian,
        model: 'cosyvoice-v3-flash',
        currentLanguage: 'ja-JP',
      );
      final voice = selectTtsVoiceForModelLanguage(
        provider: TtsProviderType.aliyunBailian,
        model: 'cosyvoice-v3-flash',
        currentVoice: 'Cherry',
        language: language,
        savedVoices: const <String>['Cherry'],
      );

      expect(language, 'auto');
      expect(voice, 'longanyang');
    });

    test('TTS model fetch results are filtered to speech models', () {
      final filtered = filterTtsModelIdsForProvider(
        TtsProviderType.aliyunBailian,
        const <String>[
          'qwen-max',
          'qwen3-asr-flash',
          'qwen3-tts-instruct-flash',
          'cosyvoice-v3-flash',
        ],
      );

      expect(filtered, <String>[
        'qwen3-tts-instruct-flash',
        'cosyvoice-v3-flash',
      ]);
    });

    test('TTS voice options follow selected language', () {
      final zhVoices = resolveTtsVoiceOptions(
        provider: TtsProviderType.doubao,
        selectedModel: 'volcano_tts',
        selectedVoice: '',
        selectedLanguage: 'zh-CN',
      );
      final enVoices = resolveTtsVoiceOptions(
        provider: TtsProviderType.doubao,
        selectedModel: 'volcano_tts',
        selectedVoice: '',
        selectedLanguage: 'en-US',
      );

      expect(zhVoices, contains('zh_female_wanwanxiaohe_moon_bigtts'));
      expect(zhVoices, isNot(contains('en_female_amanda_mars_bigtts')));
      expect(enVoices, contains('en_female_amanda_mars_bigtts'));
      expect(enVoices, isNot(contains('zh_female_wanwanxiaohe_moon_bigtts')));
    });

    test('parses common model list response shapes', () {
      final ids = parseSpeechRemoteModelIds(<String, Object?>{
        'data': <Object?>[
          <String, Object?>{'id': 'model-a'},
          <String, Object?>{'model': 'model-b'},
          <String, Object?>{'model_name': 'model-c'},
        ],
      });

      expect(ids, <String>['model-a', 'model-b', 'model-c']);
    });

    test('TTS app id survives JSON round trip', () {
      final config = PlayConfig.defaults.copyWith(
        tts: PlayConfig.defaults.tts.copyWith(
          provider: TtsProviderType.doubao,
          appId: 'app-id',
          apiKey: 'token',
          model: 'volcano_tts',
          remoteVoice: 'zh_female_wanwanxiaohe_moon_bigtts',
          stylePrompt: 'gentle bedtime review',
        ),
      );

      final restored = PlayConfig.fromJson(config.toJson());

      expect(restored.tts.provider, TtsProviderType.doubao);
      expect(restored.tts.appId, 'app-id');
      expect(restored.tts.apiKey, 'token');
      expect(restored.tts.stylePrompt, 'gentle bedtime review');
    });
  });
}

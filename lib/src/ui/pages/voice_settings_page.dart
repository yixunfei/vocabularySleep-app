import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/play_config.dart';
import '../../state/app_state.dart';
import '../widgets/section_header.dart';

class VoiceSettingsPage extends StatefulWidget {
  const VoiceSettingsPage({super.key});

  @override
  State<VoiceSettingsPage> createState() => _VoiceSettingsPageState();
}

class _VoiceSettingsPageState extends State<VoiceSettingsPage> {
  static const List<_TtsApiModelOption> _apiModels = <_TtsApiModelOption>[
    _TtsApiModelOption(
      id: 'FunAudioLLM/CosyVoice2-0.5B',
      name: 'CosyVoice2-0.5B',
      voices: <String>[
        'alex',
        'anna',
        'bella',
        'benjamin',
        'charles',
        'claire',
        'david',
        'diana',
      ],
    ),
    _TtsApiModelOption(
      id: 'fnlp/MOSS-TTSD-v0.5',
      name: 'MOSS-TTSD-v0.5',
      voices: <String>[
        'alex',
        'anna',
        'bella',
        'benjamin',
        'charles',
        'claire',
        'david',
        'diana',
      ],
    ),
    _TtsApiModelOption(
      id: 'fishaudio/fish-speech-1.4',
      name: 'FishSpeech-1.4',
      voices: <String>['anna', 'bella', 'maru', 'risuke'],
    ),
  ];
  static const Map<String, Map<String, String>>
  _pageTexts = <String, Map<String, String>>{
    'en': <String, String>{
      'pageTitle': 'Voice settings',
      'providerSubtitle':
          'Complete both local and remote TTS configuration paths.',
      'systemDefault': 'System default',
      'activeVoice': 'Current voice: {voice}',
      'modelLabel': 'Model: {model}',
      'customVoiceId': 'Custom voice ID',
      'previewTitle': 'Live preview',
      'previewSubtitle':
          'Preview pronunciation immediately after adjusting settings.',
      'previewWord': 'Preview word: {word}',
      'previewUnavailable': 'No word available for preview',
      'previewAction': 'Preview current setup',
      'tuningTitle': 'Speech tuning',
      'tuningSubtitle': 'Adjust speed and volume for your listening scene.',
      'speedLabel': 'Speed: {value}%',
      'volumeLabel': 'Volume: {value}%',
      'cacheTitle': 'API voice cache',
      'cacheSubtitle':
          'Reuse downloaded remote audio locally to reduce repeated API calls.',
      'cacheEnabled': 'Enable local API voice cache',
      'cacheSize': 'Current cache: {size}',
      'cacheMaxLabel': 'Max cache size: {value} MB',
      'cacheClear': 'Clear voice cache',
      'cacheClearDone': 'Voice cache cleared',
      'remoteTip':
          'Remote TTS requires API key; custom API also requires base URL.',
    },
    'zh': <String, String>{
      'pageTitle': '语音设置',
      'providerSubtitle': '补全本地与远程 TTS 的完整配置路径。',
      'systemDefault': '系统默认',
      'activeVoice': '当前音色：{voice}',
      'modelLabel': '模型：{model}',
      'customVoiceId': '自定义音色 ID',
      'previewTitle': '即时试听',
      'previewSubtitle': '调整设置后可立即试听当前发音效果。',
      'previewWord': '试听词：{word}',
      'previewUnavailable': '当前没有可试听的单词',
      'previewAction': '试听当前配置',
      'tuningTitle': '播报参数',
      'tuningSubtitle': '按场景调整语速和音量。',
      'speedLabel': '语速：{value}%',
      'volumeLabel': '音量：{value}%',
      'cacheTitle': 'API 语音缓存',
      'cacheSubtitle': '将远程返回的语音缓存在本地，减少重复请求与等待。',
      'cacheEnabled': '启用 API 语音本地缓存',
      'cacheSize': '当前缓存：{size}',
      'cacheMaxLabel': '最大缓存容量：{value} MB',
      'cacheClear': '一键清空语音缓存',
      'cacheClearDone': '语音缓存已清空',
      'remoteTip': '远程 TTS 需要 API Key，自定义 API 还需要 Base URL。',
    },
    'ja': <String, String>{
      'pageTitle': '音声設定',
      'providerSubtitle': 'ローカルとリモート TTS の設定をまとめて調整します。',
      'systemDefault': 'システム既定',
      'activeVoice': '現在の音声：{voice}',
      'modelLabel': 'モデル：{model}',
      'customVoiceId': 'カスタム音声 ID',
      'previewTitle': 'すぐに試聴',
      'previewSubtitle': '設定を変えたらすぐに現在の読み上げを確認できます。',
      'previewWord': '試聴単語：{word}',
      'previewUnavailable': '試聴できる単語がありません',
      'previewAction': '現在の設定で試聴',
      'tuningTitle': '読み上げ調整',
      'tuningSubtitle': '速度と音量をシーンに合わせて調整します。',
      'speedLabel': '速度：{value}%',
      'volumeLabel': '音量：{value}%',
      'remoteTip': 'リモート TTS には API キーが必要です。カスタム API では Base URL も必要です。',
    },
    'de': <String, String>{
      'pageTitle': 'Spracheinstellungen',
      'providerSubtitle':
          'Lokale und entfernte TTS-Konfiguration an einem Ort.',
      'systemDefault': 'Systemstandard',
      'activeVoice': 'Aktive Stimme: {voice}',
      'modelLabel': 'Modell: {model}',
      'customVoiceId': 'Benutzerdefinierte Stimmen-ID',
      'previewTitle': 'Sofortprobe',
      'previewSubtitle': 'Prüfe die Aussprache sofort nach jeder Änderung.',
      'previewWord': 'Vorschauwort: {word}',
      'previewUnavailable': 'Kein Wort für die Vorschau verfügbar',
      'previewAction': 'Aktuelle Konfiguration anhören',
      'tuningTitle': 'Sprachabstimmung',
      'tuningSubtitle': 'Passe Tempo und Lautstärke an deine Nutzung an.',
      'speedLabel': 'Geschwindigkeit: {value}%',
      'volumeLabel': 'Lautstärke: {value}%',
      'remoteTip':
          'Remote-TTS benötigt einen API-Schlüssel; benutzerdefinierte APIs zusätzlich eine Base-URL.',
    },
    'fr': <String, String>{
      'pageTitle': 'Paramètres vocaux',
      'providerSubtitle':
          'Regroupe la configuration TTS locale et distante au même endroit.',
      'systemDefault': 'Valeur système',
      'activeVoice': 'Voix actuelle : {voice}',
      'modelLabel': 'Modèle : {model}',
      'customVoiceId': 'ID de voix personnalisée',
      'previewTitle': 'Aperçu instantané',
      'previewSubtitle':
          'Écoute immédiatement la prononciation après chaque réglage.',
      'previewWord': 'Mot d\'aperçu : {word}',
      'previewUnavailable': 'Aucun mot disponible pour l\'aperçu',
      'previewAction': 'Tester la configuration actuelle',
      'tuningTitle': 'Réglage vocal',
      'tuningSubtitle': 'Ajuste la vitesse et le volume selon ton usage.',
      'speedLabel': 'Vitesse : {value}%',
      'volumeLabel': 'Volume : {value}%',
      'remoteTip':
          'Le TTS distant nécessite une clé API ; l\'API personnalisée demande aussi une URL de base.',
    },
    'es': <String, String>{
      'pageTitle': 'Ajustes de voz',
      'providerSubtitle':
          'Reúne la configuración TTS local y remota en un solo lugar.',
      'systemDefault': 'Predeterminado del sistema',
      'activeVoice': 'Voz actual: {voice}',
      'modelLabel': 'Modelo: {model}',
      'customVoiceId': 'ID de voz personalizada',
      'previewTitle': 'Vista previa inmediata',
      'previewSubtitle':
          'Escucha la pronunciación al instante después de cada ajuste.',
      'previewWord': 'Palabra de prueba: {word}',
      'previewUnavailable': 'No hay palabras disponibles para la vista previa',
      'previewAction': 'Probar configuración actual',
      'tuningTitle': 'Ajuste de voz',
      'tuningSubtitle': 'Ajusta velocidad y volumen según tu uso.',
      'speedLabel': 'Velocidad: {value}%',
      'volumeLabel': 'Volumen: {value}%',
      'remoteTip':
          'El TTS remoto necesita clave API; la API personalizada también requiere URL base.',
    },
    'ru': <String, String>{
      'pageTitle': 'Настройки голоса',
      'providerSubtitle':
          'Собирает локальные и удалённые настройки TTS в одном месте.',
      'systemDefault': 'Системный вариант',
      'activeVoice': 'Текущий голос: {voice}',
      'modelLabel': 'Модель: {model}',
      'customVoiceId': 'ID пользовательского голоса',
      'previewTitle': 'Мгновенное прослушивание',
      'previewSubtitle':
          'Сразу проверьте произношение после изменения настроек.',
      'previewWord': 'Слово для прослушивания: {word}',
      'previewUnavailable': 'Нет слова для прослушивания',
      'previewAction': 'Проверить текущую настройку',
      'tuningTitle': 'Параметры речи',
      'tuningSubtitle':
          'Подстройте скорость и громкость под свой сценарий использования.',
      'speedLabel': 'Скорость: {value}%',
      'volumeLabel': 'Громкость: {value}%',
      'remoteTip':
          'Для удалённого TTS нужен API-ключ; для пользовательского API также нужен базовый URL.',
    },
  };
  static const Map<String, Map<String, String>> _voiceProfileTexts =
      <String, Map<String, String>>{
        'en': <String, String>{
          'alex': 'Alex · calm male',
          'anna': 'Anna · warm female',
          'bella': 'Bella · bright female',
          'benjamin': 'Benjamin · deep male',
          'charles': 'Charles · clear male',
          'claire': 'Claire · gentle female',
          'david': 'David · warm male',
          'diana': 'Diana · crisp female',
          'maru': 'Maru · relaxed Japanese',
          'risuke': 'Risuke · lively Japanese',
        },
        'zh': <String, String>{
          'alex': 'Alex · 沉稳男声',
          'anna': 'Anna · 温柔女声',
          'bella': 'Bella · 明亮女声',
          'benjamin': 'Benjamin · 低沉男声',
          'charles': 'Charles · 清晰男声',
          'claire': 'Claire · 柔和女声',
          'david': 'David · 温暖男声',
          'diana': 'Diana · 清脆女声',
          'maru': 'Maru · 放松日语声线',
          'risuke': 'Risuke · 活力日语声线',
        },
        'ja': <String, String>{
          'alex': 'Alex・落ち着いた男性音声',
          'anna': 'Anna・やわらかな女性音声',
          'bella': 'Bella・明るい女性音声',
          'benjamin': 'Benjamin・低めの男性音声',
          'charles': 'Charles・明瞭な男性音声',
          'claire': 'Claire・穏やかな女性音声',
          'david': 'David・温かみのある男性音声',
          'diana': 'Diana・軽やかな女性音声',
          'maru': 'Maru・リラックスした日本語音声',
          'risuke': 'Risuke・元気な日本語音声',
        },
        'de': <String, String>{
          'alex': 'Alex · ruhige Männerstimme',
          'anna': 'Anna · warme Frauenstimme',
          'bella': 'Bella · helle Frauenstimme',
          'benjamin': 'Benjamin · tiefe Männerstimme',
          'charles': 'Charles · klare Männerstimme',
          'claire': 'Claire · sanfte Frauenstimme',
          'david': 'David · warme Männerstimme',
          'diana': 'Diana · frische Frauenstimme',
          'maru': 'Maru · entspannte japanische Stimme',
          'risuke': 'Risuke · lebhafte japanische Stimme',
        },
        'fr': <String, String>{
          'alex': 'Alex · voix masculine posée',
          'anna': 'Anna · voix féminine chaleureuse',
          'bella': 'Bella · voix féminine lumineuse',
          'benjamin': 'Benjamin · voix masculine grave',
          'charles': 'Charles · voix masculine claire',
          'claire': 'Claire · voix féminine douce',
          'david': 'David · voix masculine chaleureuse',
          'diana': 'Diana · voix féminine vive',
          'maru': 'Maru · voix japonaise détendue',
          'risuke': 'Risuke · voix japonaise énergique',
        },
        'es': <String, String>{
          'alex': 'Alex · voz masculina serena',
          'anna': 'Anna · voz femenina cálida',
          'bella': 'Bella · voz femenina brillante',
          'benjamin': 'Benjamin · voz masculina profunda',
          'charles': 'Charles · voz masculina clara',
          'claire': 'Claire · voz femenina suave',
          'david': 'David · voz masculina cálida',
          'diana': 'Diana · voz femenina nítida',
          'maru': 'Maru · voz japonesa relajada',
          'risuke': 'Risuke · voz japonesa enérgica',
        },
        'ru': <String, String>{
          'alex': 'Alex · спокойный мужской голос',
          'anna': 'Anna · тёплый женский голос',
          'bella': 'Bella · яркий женский голос',
          'benjamin': 'Benjamin · глубокий мужской голос',
          'charles': 'Charles · чёткий мужской голос',
          'claire': 'Claire · мягкий женский голос',
          'david': 'David · тёплый мужской голос',
          'diana': 'Diana · звонкий женский голос',
          'maru': 'Maru · расслабленный японский голос',
          'risuke': 'Risuke · энергичный японский голос',
        },
      };

  List<String> _localVoices = const <String>[];
  bool _loadingLocalVoices = false;
  int _apiCacheBytes = 0;
  bool _loadingApiCache = false;
  bool _clearingApiCache = false;

  @override
  void initState() {
    super.initState();
    _loadLocalVoices();
    _loadApiCacheSize();
  }

  Future<void> _loadLocalVoices() async {
    setState(() {
      _loadingLocalVoices = true;
    });
    final voices = await context.read<AppState>().fetchLocalTtsVoices();
    if (!mounted) return;
    setState(() {
      _loadingLocalVoices = false;
      _localVoices = voices;
    });
  }

  Future<void> _loadApiCacheSize() async {
    setState(() {
      _loadingApiCache = true;
    });
    final bytes = await context.read<AppState>().getApiTtsCacheSizeBytes();
    if (!mounted) return;
    setState(() {
      _loadingApiCache = false;
      _apiCacheBytes = bytes;
    });
  }

  _TtsApiModelOption _resolveApiTtsModel(String? id) {
    final resolvedId = id?.trim() ?? '';
    for (final model in _apiModels) {
      if (model.id == resolvedId) return model;
    }
    return _apiModels.first;
  }

  List<String> _resolveRemoteVoiceOptions(TtsConfig tts) {
    final modelVoices = _resolveApiTtsModel(tts.model).voices;
    final merged = <String>[];
    void addItem(String raw) {
      final value = raw.trim();
      if (value.isEmpty) return;
      if (!merged.contains(value)) merged.add(value);
    }

    for (final item in modelVoices) {
      addItem(item);
    }
    for (final item in tts.normalizedRemoteVoiceTypes) {
      addItem(item);
    }
    addItem(tts.remoteVoice);
    if (merged.isEmpty) {
      addItem('alex');
    }
    return merged;
  }

  String _voiceUiText(
    AppI18n i18n,
    String key, {
    Map<String, Object?> params = const <String, Object?>{},
  }) {
    final language = AppI18n.normalizeLanguageCode(i18n.languageCode);
    var value = _pageTexts[language]?[key] ?? _pageTexts['en']?[key] ?? key;
    for (final entry in params.entries) {
      value = value.replaceAll('{${entry.key}}', '${entry.value ?? ''}');
    }
    return value;
  }

  String _localizedVoiceLabel(AppI18n i18n, String raw) {
    final value = raw.trim();
    if (value.isEmpty) return _voiceUiText(i18n, 'systemDefault');
    final language = AppI18n.normalizeLanguageCode(i18n.languageCode);
    return _voiceProfileTexts[language]?[value.toLowerCase()] ??
        _voiceProfileTexts['en']?[value.toLowerCase()] ??
        value;
  }

  String _formatCacheSize(int bytes) {
    if (bytes <= 0) return '0 MB';
    final megaBytes = bytes / (1024 * 1024);
    if (megaBytes < 0.1) {
      return '${(bytes / 1024).round()} KB';
    }
    return '${megaBytes.toStringAsFixed(megaBytes >= 10 ? 0 : 1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final config = state.config;
    final tts = config.tts;
    final speedPercent = (tts.speed * 100).round();
    final volumePercent = (tts.volume * 100).round();
    final activeVoice = tts.activeVoice.trim().isEmpty
        ? _voiceUiText(i18n, 'systemDefault')
        : _localizedVoiceLabel(i18n, tts.activeVoice.trim());
    final previewWord = state.currentWord?.word.trim() ?? '';
    final canPreview = previewWord.isNotEmpty;
    final provider = tts.provider;
    final isRemote = provider != TtsProviderType.local;
    final isPresetApi = provider == TtsProviderType.api;
    final isCustomApi = provider == TtsProviderType.customApi;
    final currentModel = _resolveApiTtsModel(tts.model);
    final remoteVoiceOptions = _resolveRemoteVoiceOptions(tts);
    final selectedLocalVoice = _localVoices.isEmpty
        ? tts.localVoice.trim()
        : _localVoices.contains(tts.localVoice.trim())
        ? tts.localVoice.trim()
        : '';
    final selectedRemoteVoice =
        remoteVoiceOptions.contains(tts.remoteVoice.trim())
        ? tts.remoteVoice.trim()
        : remoteVoiceOptions.first;

    return Scaffold(
      appBar: AppBar(title: Text(_voiceUiText(i18n, 'pageTitle'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SectionHeader(
                    title: i18n.t('ttsProvider'),
                    subtitle: _voiceUiText(i18n, 'providerSubtitle'),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<TtsProviderType>(
                    initialValue: provider,
                    decoration: InputDecoration(
                      labelText: i18n.t('ttsProvider'),
                    ),
                    items: <DropdownMenuItem<TtsProviderType>>[
                      DropdownMenuItem(
                        value: TtsProviderType.local,
                        child: Text(i18n.t('local')),
                      ),
                      DropdownMenuItem(
                        value: TtsProviderType.api,
                        child: Text(i18n.t('siliconFlowApi')),
                      ),
                      DropdownMenuItem(
                        value: TtsProviderType.customApi,
                        child: Text(i18n.t('customApi')),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      if (value == TtsProviderType.local) {
                        final localVoice = _localVoices.isEmpty
                            ? tts.localVoice.trim()
                            : _localVoices.contains(tts.localVoice.trim())
                            ? tts.localVoice.trim()
                            : '';
                        state.updateConfig(
                          config.copyWith(
                            tts: tts.copyWith(
                              provider: value,
                              voice: localVoice,
                              localVoice: localVoice,
                              language: 'auto',
                            ),
                          ),
                        );
                        return;
                      }

                      if (value == TtsProviderType.api) {
                        final model = _resolveApiTtsModel(tts.model);
                        final options = model.voices;
                        final remoteVoice = options.contains(tts.remoteVoice)
                            ? tts.remoteVoice
                            : options.first;
                        state.updateConfig(
                          config.copyWith(
                            tts: tts.copyWith(
                              provider: value,
                              model: model.id,
                              voice: remoteVoice,
                              remoteVoice: remoteVoice,
                              remoteVoiceTypes: <String>[remoteVoice],
                              language: 'auto',
                            ),
                          ),
                        );
                        return;
                      }

                      final fallbackModel = (tts.model ?? '').trim().isNotEmpty
                          ? tts.model!.trim()
                          : _resolveApiTtsModel(null).id;
                      final options = _resolveApiTtsModel(fallbackModel).voices;
                      final remoteVoice = tts.remoteVoice.trim().isNotEmpty
                          ? tts.remoteVoice.trim()
                          : (options.isEmpty ? 'alex' : options.first);
                      state.updateConfig(
                        config.copyWith(
                          tts: tts.copyWith(
                            provider: value,
                            model: fallbackModel,
                            voice: remoteVoice,
                            remoteVoice: remoteVoice,
                            remoteVoiceTypes: <String>[remoteVoice],
                            language: 'auto',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _voiceUiText(
                      i18n,
                      'activeVoice',
                      params: <String, Object?>{'voice': activeVoice},
                    ),
                  ),
                  if ((tts.model ?? '').trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      _voiceUiText(
                        i18n,
                        'modelLabel',
                        params: <String, Object?>{'model': tts.model},
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (provider == TtsProviderType.local) ...<Widget>[
                    DropdownButtonFormField<String>(
                      initialValue: selectedLocalVoice,
                      decoration: InputDecoration(labelText: i18n.t('voice')),
                      items: <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(
                          value: '',
                          child: Text(i18n.t('defaultVoice')),
                        ),
                        if (selectedLocalVoice.isNotEmpty &&
                            !_localVoices.contains(selectedLocalVoice))
                          DropdownMenuItem<String>(
                            value: selectedLocalVoice,
                            child: Text(
                              _localizedVoiceLabel(i18n, selectedLocalVoice),
                            ),
                          ),
                        ..._localVoices.map(
                          (voice) => DropdownMenuItem<String>(
                            value: voice,
                            child: Text(_localizedVoiceLabel(i18n, voice)),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        state.updateConfig(
                          config.copyWith(
                            tts: tts.copyWith(
                              voice: value,
                              localVoice: value,
                              language: 'auto',
                            ),
                          ),
                        );
                      },
                    ),
                    if (_loadingLocalVoices) ...<Widget>[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                    if (!_loadingLocalVoices &&
                        _localVoices.isEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        i18n.t('localVoicesNotFound'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ] else ...<Widget>[
                    if (isPresetApi) ...<Widget>[
                      DropdownButtonFormField<String>(
                        initialValue: currentModel.id,
                        decoration: InputDecoration(
                          labelText: i18n.t('ttsModel'),
                        ),
                        items: _apiModels
                            .map(
                              (model) => DropdownMenuItem<String>(
                                value: model.id,
                                child: Text(model.name),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) return;
                          final model = _resolveApiTtsModel(value);
                          final nextVoice =
                              model.voices.contains(tts.remoteVoice.trim())
                              ? tts.remoteVoice.trim()
                              : model.voices.first;
                          state.updateConfig(
                            config.copyWith(
                              tts: tts.copyWith(
                                model: model.id,
                                voice: nextVoice,
                                remoteVoice: nextVoice,
                                remoteVoiceTypes: <String>[nextVoice],
                                language: 'auto',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    DropdownButtonFormField<String>(
                      initialValue: selectedRemoteVoice,
                      decoration: InputDecoration(labelText: i18n.t('voice')),
                      items: remoteVoiceOptions
                          .map(
                            (voice) => DropdownMenuItem<String>(
                              value: voice,
                              child: Text(_localizedVoiceLabel(i18n, voice)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        state.updateConfig(
                          config.copyWith(
                            tts: tts.copyWith(
                              voice: value,
                              remoteVoice: value,
                              remoteVoiceTypes: <String>[value],
                              language: 'auto',
                            ),
                          ),
                        );
                      },
                    ),
                    if (isCustomApi) ...<Widget>[
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: tts.model ?? '',
                        decoration: InputDecoration(
                          labelText: i18n.t('ttsModel'),
                          hintText: i18n.t('ttsModelIdHint'),
                        ),
                        onChanged: (value) {
                          state.updateConfig(
                            config.copyWith(
                              tts: tts.copyWith(model: value.trim()),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: tts.baseUrl ?? '',
                        decoration: InputDecoration(
                          labelText: i18n.t('ttsApiBaseUrl'),
                        ),
                        onChanged: (value) {
                          state.updateConfig(
                            config.copyWith(
                              tts: tts.copyWith(baseUrl: value.trim()),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: tts.remoteVoice,
                        decoration: InputDecoration(
                          labelText: _voiceUiText(i18n, 'customVoiceId'),
                        ),
                        onChanged: (value) {
                          final next = value.trim();
                          state.updateConfig(
                            config.copyWith(
                              tts: tts.copyWith(
                                voice: next,
                                remoteVoice: next,
                                remoteVoiceTypes: <String>[next],
                                language: 'auto',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: tts.apiKey ?? '',
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: i18n.t('ttsApiKey'),
                      ),
                      onChanged: (value) {
                        state.updateConfig(
                          config.copyWith(
                            tts: tts.copyWith(apiKey: value.trim()),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SectionHeader(
                    title: _voiceUiText(i18n, 'previewTitle'),
                    subtitle: _voiceUiText(i18n, 'previewSubtitle'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    canPreview
                        ? _voiceUiText(
                            i18n,
                            'previewWord',
                            params: <String, Object?>{'word': previewWord},
                          )
                        : _voiceUiText(i18n, 'previewUnavailable'),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: canPreview
                        ? () => state.previewPronunciation(previewWord)
                        : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(_voiceUiText(i18n, 'previewAction')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SectionHeader(
                    title: _voiceUiText(i18n, 'tuningTitle'),
                    subtitle: _voiceUiText(i18n, 'tuningSubtitle'),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _voiceUiText(
                      i18n,
                      'speedLabel',
                      params: <String, Object?>{'value': speedPercent},
                    ),
                  ),
                  Slider(
                    min: 0.5,
                    max: 1.5,
                    divisions: 10,
                    value: tts.speed.clamp(0.5, 1.5),
                    onChanged: (value) {
                      state.updateConfig(
                        config.copyWith(tts: tts.copyWith(speed: value)),
                      );
                    },
                  ),
                  Text(
                    _voiceUiText(
                      i18n,
                      'volumeLabel',
                      params: <String, Object?>{'value': volumePercent},
                    ),
                  ),
                  Slider(
                    min: 0,
                    max: 1,
                    value: tts.volume.clamp(0.0, 1.0),
                    onChanged: (value) {
                      state.updateConfig(
                        config.copyWith(tts: tts.copyWith(volume: value)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (isRemote) ...<Widget>[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SectionHeader(
                      title: _voiceUiText(i18n, 'cacheTitle'),
                      subtitle: _voiceUiText(i18n, 'cacheSubtitle'),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_voiceUiText(i18n, 'cacheEnabled')),
                      subtitle: Text(
                        _voiceUiText(
                          i18n,
                          'cacheSize',
                          params: <String, Object?>{
                            'size': _loadingApiCache
                                ? '...'
                                : _formatCacheSize(_apiCacheBytes),
                          },
                        ),
                      ),
                      value: tts.enableApiCache,
                      onChanged: (value) {
                        state.updateConfig(
                          config.copyWith(
                            tts: tts.copyWith(enableApiCache: value),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _voiceUiText(
                        i18n,
                        'cacheMaxLabel',
                        params: <String, Object?>{
                          'value': tts.maxApiCacheMb.clamp(32, 2048).toInt(),
                        },
                      ),
                    ),
                    Slider(
                      min: 32,
                      max: 512,
                      divisions: 15,
                      value: tts.maxApiCacheMb.clamp(32, 512).toDouble(),
                      label:
                          '${tts.maxApiCacheMb.clamp(32, 512).toInt()} MB',
                      onChanged: (value) {
                        state.updateConfig(
                          config.copyWith(
                            tts: tts.copyWith(maxApiCacheMb: value.round()),
                          ),
                        );
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: _clearingApiCache
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final clearDoneText = _voiceUiText(
                                  i18n,
                                  'cacheClearDone',
                                );
                                setState(() {
                                  _clearingApiCache = true;
                                });
                                try {
                                  await state.clearApiTtsCache();
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(content: Text(clearDoneText)),
                                  );
                                  await _loadApiCacheSize();
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _clearingApiCache = false;
                                    });
                                  }
                                }
                              },
                        icon: _clearingApiCache
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cleaning_services_rounded),
                        label: Text(_voiceUiText(i18n, 'cacheClear')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (isRemote) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _voiceUiText(i18n, 'remoteTip'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _TtsApiModelOption {
  const _TtsApiModelOption({
    required this.id,
    required this.name,
    required this.voices,
  });

  final String id;
  final String name;
  final List<String> voices;
}

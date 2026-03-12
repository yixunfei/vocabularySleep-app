import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/play_config.dart';
import '../../state/app_state.dart';
import '../ui_copy.dart';
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

  List<String> _localVoices = const <String>[];
  bool _loadingLocalVoices = false;

  @override
  void initState() {
    super.initState();
    _loadLocalVoices();
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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final config = state.config;
    final tts = config.tts;
    final speedPercent = (tts.speed * 100).round();
    final volumePercent = (tts.volume * 100).round();
    final activeVoice = tts.activeVoice.trim().isEmpty
        ? pickUiText(i18n, zh: '系统默认', en: 'System default')
        : tts.activeVoice.trim();
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
      appBar: AppBar(
        title: Text(pickUiText(i18n, zh: '语音设置', en: 'Voice settings')),
      ),
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
                    subtitle: pickUiText(
                      i18n,
                      zh: '补齐本地与远程 TTS 的完整配置路径。',
                      en: 'Complete both local and remote TTS configuration paths.',
                    ),
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
                    pickUiText(
                      i18n,
                      zh: '当前语音：$activeVoice',
                      en: 'Active voice: $activeVoice',
                    ),
                  ),
                  if ((tts.model ?? '').trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      pickUiText(
                        i18n,
                        zh: '模型：${tts.model}',
                        en: 'Model: ${tts.model}',
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
                            child: Text(selectedLocalVoice),
                          ),
                        ..._localVoices.map(
                          (voice) => DropdownMenuItem<String>(
                            value: voice,
                            child: Text(voice),
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
                              child: Text(voice),
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
                          labelText: pickUiText(
                            i18n,
                            zh: '自定义音色 ID',
                            en: 'Custom voice ID',
                          ),
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
                    title: pickUiText(i18n, zh: '即时试听', en: 'Live preview'),
                    subtitle: pickUiText(
                      i18n,
                      zh: '修改参数后可立即试听当前单词发音。',
                      en: 'Preview pronunciation immediately after adjusting settings.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    canPreview
                        ? pickUiText(
                            i18n,
                            zh: '试听词：$previewWord',
                            en: 'Preview word: $previewWord',
                          )
                        : pickUiText(
                            i18n,
                            zh: '当前没有可试听的单词',
                            en: 'No word available for preview',
                          ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: canPreview
                        ? () => state.previewPronunciation(previewWord)
                        : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      pickUiText(
                        i18n,
                        zh: '试听当前配置',
                        en: 'Preview current setup',
                      ),
                    ),
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
                    title: pickUiText(i18n, zh: '播报参数', en: 'Speech tuning'),
                    subtitle: pickUiText(
                      i18n,
                      zh: '按场景调整语速和音量。',
                      en: 'Adjust speed and volume for your listening scene.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '语速：$speedPercent%',
                      en: 'Speed: $speedPercent%',
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
                    pickUiText(
                      i18n,
                      zh: '音量：$volumePercent%',
                      en: 'Volume: $volumePercent%',
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
            const SizedBox(height: 12),
            Text(
              pickUiText(
                i18n,
                zh: '远程 TTS 需要 API Key，自定义 API 还需要 Base URL。',
                en: 'Remote TTS requires API key; custom API also requires base URL.',
              ),
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

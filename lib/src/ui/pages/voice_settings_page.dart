import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/app_i18n.dart';
import '../../models/play_config.dart';
import '../../services/speech_remote_model_service.dart';
import '../../state/app_state_provider.dart';
import '../../utils/speech_api_model_options.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';

class VoiceSettingsPage extends ConsumerStatefulWidget {
  const VoiceSettingsPage({super.key});

  @override
  ConsumerState<VoiceSettingsPage> createState() => _VoiceSettingsPageState();
}

class _VoiceSettingsPageState extends ConsumerState<VoiceSettingsPage> {
  final SpeechRemoteModelService _modelService =
      const SpeechRemoteModelService();
  final ScrollController _scrollController = ScrollController();

  List<String> _localVoices = const <String>[];
  List<String> _fetchedTtsModels = const <String>[];
  bool _loadingLocalVoices = false;
  bool _loadingApiCache = false;
  bool _loadingTtsModels = false;
  bool _clearingApiCache = false;
  int _apiCacheBytes = 0;
  String? _ttsModelFetchError;

  @override
  void initState() {
    super.initState();
    _loadLocalVoices();
    _loadApiCacheSize();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalVoices() async {
    setState(() {
      _loadingLocalVoices = true;
    });
    final voices = await ref.read(appStateProvider).fetchLocalTtsVoices();
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
    final bytes = await ref.read(appStateProvider).getApiTtsCacheSizeBytes();
    if (!mounted) return;
    setState(() {
      _loadingApiCache = false;
      _apiCacheBytes = bytes;
    });
  }

  Future<void> _refreshRemoteModels(TtsConfig tts) async {
    if (_loadingTtsModels || !ttsProviderCanFetchModels(tts.provider)) {
      return;
    }
    setState(() {
      _loadingTtsModels = true;
      _ttsModelFetchError = null;
    });
    try {
      final models = await _modelService.fetchTtsModelIds(tts);
      if (!mounted) return;
      setState(() {
        _fetchedTtsModels = models;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _ttsModelFetchError = '$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingTtsModels = false;
        });
      }
    }
  }

  String _formatCacheSize(int bytes) {
    if (bytes <= 0) return '0 MB';
    final megaBytes = bytes / (1024 * 1024);
    if (megaBytes < 0.1) {
      return '${(bytes / 1024).round()} KB';
    }
    return '${megaBytes.toStringAsFixed(megaBytes >= 10 ? 0 : 1)} MB';
  }

  String _activeVoiceLabel(AppI18n i18n, TtsConfig tts) {
    final active = tts.activeVoice.trim();
    if (active.isEmpty) return i18n.t('defaultVoice');
    if (tts.provider == TtsProviderType.local) return active;
    return speechApiVoiceOptionLabel(
      i18n,
      provider: tts.provider,
      voice: active,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    final config = state.config;
    final tts = config.tts;
    final provider = tts.provider;
    final isRemote = isRemoteTtsProvider(provider);
    final canFetchModels = ttsProviderCanFetchModels(provider);
    final selectedModel = (tts.model ?? '').trim().isEmpty
        ? defaultTtsModelForProvider(provider)
        : tts.model!.trim();
    final modelOptions = isRemote
        ? resolveTtsApiModelOptions(
            provider: provider,
            selectedModel: selectedModel,
            fetchedModelIds: _fetchedTtsModels,
          )
        : const <SpeechApiModelOption>[];
    final selectedModelOption = modelOptions.isEmpty
        ? null
        : modelOptions.firstWhere(
            (option) => option.value == selectedModel,
            orElse: () => modelOptions.first,
          );
    final languageOptions = resolveSpeechLanguageOptions(
      modelLanguages: selectedModelOption?.languageCodes ?? kSpeechApiLanguages,
      selectedLanguage: tts.language,
      includeSelectedLanguage: false,
    );
    final selectedLanguage = languageOptions.contains(tts.language)
        ? tts.language
        : languageOptions.first;
    final voiceOptions = isRemote
        ? resolveTtsVoiceOptions(
            provider: provider,
            selectedModel: selectedModel,
            selectedVoice: tts.remoteVoice,
            selectedLanguage: selectedLanguage,
            savedVoices: tts.normalizedRemoteVoiceTypes,
            fetchedModelIds: _fetchedTtsModels,
          )
        : const <String>[];
    final selectedRemoteVoice = voiceOptions.contains(tts.remoteVoice.trim())
        ? tts.remoteVoice.trim()
        : (voiceOptions.isEmpty
              ? defaultTtsVoiceForModel(
                  provider: provider,
                  model: selectedModel,
                )
              : voiceOptions.first);
    final selectedLocalVoice =
        _localVoices.isEmpty || _localVoices.contains(tts.localVoice.trim())
        ? tts.localVoice.trim()
        : '';
    final speedPercent = (tts.speed * 100).round();
    final volumePercent = (tts.volume * 100).round();
    final previewWord = state.currentWord?.word.trim() ?? '';
    final canPreview = previewWord.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(i18n.t('speech.tts.settings.page_title'))),
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: ListView(
          controller: _scrollController,
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
                      subtitle: i18n.t('speech.tts.settings.provider_subtitle'),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<TtsProviderType>(
                      initialValue: provider,
                      decoration: InputDecoration(
                        labelText: i18n.t('ttsProvider'),
                      ),
                      items: TtsProviderType.values
                          .map(
                            (item) => DropdownMenuItem<TtsProviderType>(
                              value: item,
                              child: Text(ttsProviderLabel(i18n, item)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        _handleProviderChanged(value, config, tts);
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      i18n.t(
                        'speech.tts.settings.active_voice',
                        params: <String, Object?>{
                          'voice': _activeVoiceLabel(i18n, tts),
                        },
                      ),
                    ),
                    if ((tts.model ?? '').trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        i18n.t(
                          'speech.tts.settings.active_model',
                          params: <String, Object?>{'model': tts.model},
                        ),
                      ),
                    ],
                    if (isRemote) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        _remoteTip(i18n, provider),
                        style: Theme.of(context).textTheme.bodySmall,
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
                      title: isRemote
                          ? i18n.t('speech.tts.settings.remote_config_title')
                          : i18n.t('speech.tts.settings.local_voice_title'),
                      subtitle: isRemote
                          ? i18n.t('speech.tts.settings.remote_config_subtitle')
                          : i18n.t('speech.tts.settings.local_voice_subtitle'),
                    ),
                    const SizedBox(height: 14),
                    if (!isRemote)
                      _buildLocalVoiceControls(
                        context: context,
                        i18n: i18n,
                        config: config,
                        tts: tts,
                        selectedLocalVoice: selectedLocalVoice,
                      )
                    else
                      _buildRemoteVoiceControls(
                        context: context,
                        i18n: i18n,
                        config: config,
                        tts: tts,
                        modelOptions: modelOptions,
                        selectedModel: selectedModel,
                        canFetchModels: canFetchModels,
                        languageOptions: languageOptions,
                        selectedLanguage: selectedLanguage,
                        voiceOptions: voiceOptions,
                        selectedRemoteVoice: selectedRemoteVoice,
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
                      title: i18n.t('speech.tts.settings.preview_title'),
                      subtitle: i18n.t('speech.tts.settings.preview_subtitle'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      canPreview
                          ? i18n.t(
                              'speech.tts.settings.preview_word',
                              params: <String, Object?>{'word': previewWord},
                            )
                          : i18n.t('speech.tts.settings.preview_unavailable'),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: canPreview
                          ? () => state.previewPronunciation(previewWord)
                          : null,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(i18n.t('speech.tts.settings.preview_action')),
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
                      title: i18n.t('speech.tts.settings.tuning_title'),
                      subtitle: i18n.t('speech.tts.settings.tuning_subtitle'),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      i18n.t(
                        'speech.tts.settings.speed_label',
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
                      i18n.t(
                        'speech.tts.settings.volume_label',
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
                        title: i18n.t('speech.tts.settings.cache_title'),
                        subtitle: i18n.t('speech.tts.settings.cache_subtitle'),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          i18n.t('speech.tts.settings.cache_enabled'),
                        ),
                        subtitle: Text(
                          i18n.t(
                            'speech.tts.settings.cache_size',
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
                        i18n.t(
                          'speech.tts.settings.cache_max_label',
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
                        label: '${tts.maxApiCacheMb.clamp(32, 512).toInt()} MB',
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
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final clearDoneText = i18n.t(
                                    'speech.tts.settings.cache_clear_done',
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
                          label: Text(
                            i18n.t('speech.tts.settings.cache_clear'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                i18n.t('speech.tts.settings.remote_config_footer'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocalVoiceControls({
    required BuildContext context,
    required AppI18n i18n,
    required PlayConfig config,
    required TtsConfig tts,
    required String selectedLocalVoice,
  }) {
    final state = ref.read(appStateProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DropdownButtonFormField<String>(
          key: ValueKey<String>('tts-local-voice-$selectedLocalVoice'),
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
              (voice) =>
                  DropdownMenuItem<String>(value: voice, child: Text(voice)),
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
        if (!_loadingLocalVoices && _localVoices.isEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            i18n.t('localVoicesNotFound'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _buildRemoteVoiceControls({
    required BuildContext context,
    required AppI18n i18n,
    required PlayConfig config,
    required TtsConfig tts,
    required List<SpeechApiModelOption> modelOptions,
    required String selectedModel,
    required bool canFetchModels,
    required List<String> languageOptions,
    required String selectedLanguage,
    required List<String> voiceOptions,
    required String selectedRemoteVoice,
  }) {
    final state = ref.read(appStateProvider);
    final provider = tts.provider;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DropdownButtonFormField<String>(
          key: ValueKey<String>('tts-model-${provider.name}-$selectedModel'),
          initialValue: selectedModel,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: i18n.t('ttsModel'),
            suffixIcon: canFetchModels
                ? IconButton(
                    onPressed: _loadingTtsModels
                        ? null
                        : () => _refreshRemoteModels(tts),
                    icon: _loadingTtsModels
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                    tooltip: i18n.t('speech.remote.model.refresh'),
                  )
                : null,
          ),
          items: modelOptions
              .map(
                (model) => DropdownMenuItem<String>(
                  value: model.value,
                  child: Text(
                    speechApiModelOptionLabel(i18n, model),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value == null || value.trim().isEmpty) return;
            final nextModel = value.trim();
            final nextLanguage = selectTtsLanguageForModel(
              provider: provider,
              model: nextModel,
              currentLanguage: tts.language,
              fetchedModelIds: _fetchedTtsModels,
            );
            final nextVoice = selectTtsVoiceForModelLanguage(
              provider: provider,
              model: nextModel,
              currentVoice: tts.remoteVoice,
              language: nextLanguage,
              savedVoices: tts.normalizedRemoteVoiceTypes,
              fetchedModelIds: _fetchedTtsModels,
              includeSavedVoices: false,
            );
            state.updateConfig(
              config.copyWith(
                tts: tts.copyWith(
                  model: nextModel,
                  language: nextLanguage,
                  voice: nextVoice,
                  remoteVoice: nextVoice,
                  remoteVoiceTypes: <String>[nextVoice],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          speechApiModelHelperText(i18n, ttsProvider: provider),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if ((_ttsModelFetchError ?? '').trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            i18n.t(
              'speech.remote.model.fetch_failed',
              params: <String, Object?>{'error': _ttsModelFetchError},
            ),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
          ),
        ],
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          key: ValueKey<String>(
            'tts-language-${provider.name}-$selectedModel-$selectedLanguage',
          ),
          initialValue: selectedLanguage,
          decoration: InputDecoration(
            labelText: i18n.t('speech.remote.language_label'),
          ),
          items: languageOptions
              .map(
                (code) => DropdownMenuItem<String>(
                  value: code,
                  child: Text(speechApiLanguageLabel(i18n, code)),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value == null || value.trim().isEmpty) return;
            final nextLanguage = value.trim();
            final nextVoice = selectTtsVoiceForModelLanguage(
              provider: provider,
              model: selectedModel,
              currentVoice: tts.remoteVoice,
              language: nextLanguage,
              savedVoices: tts.normalizedRemoteVoiceTypes,
              fetchedModelIds: _fetchedTtsModels,
            );
            state.updateConfig(
              config.copyWith(
                tts: tts.copyWith(
                  language: nextLanguage,
                  voice: nextVoice,
                  remoteVoice: nextVoice,
                  remoteVoiceTypes: <String>[nextVoice],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          key: ValueKey<String>(
            'tts-voice-${provider.name}-$selectedModel-$selectedLanguage-$selectedRemoteVoice',
          ),
          initialValue: selectedRemoteVoice,
          isExpanded: true,
          decoration: InputDecoration(labelText: i18n.t('voice')),
          items: voiceOptions
              .map(
                (voice) => DropdownMenuItem<String>(
                  value: voice,
                  child: Text(
                    speechApiVoiceOptionLabel(
                      i18n,
                      provider: provider,
                      voice: voice,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
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
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            key: const ValueKey<String>('tts-import-model-voices'),
            onPressed: voiceOptions.isEmpty
                ? null
                : () {
                    final imported = _importModelVoices(
                      config: config,
                      tts: tts,
                      model: selectedModel,
                      language: selectedLanguage,
                      voices: voiceOptions,
                    );
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      SnackBar(
                        content: Text(
                          i18n.t(
                            'speech.tts.settings.import_voices_done',
                            params: <String, Object?>{'count': imported},
                          ),
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.library_add_check_rounded),
            label: Text(i18n.t('speech.tts.settings.import_model_voices')),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        Text(
          i18n.t('speech.tts.settings.credentials_title'),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (provider == TtsProviderType.customApi) ...<Widget>[
          TextFormField(
            key: ValueKey<String>(
              'tts-custom-model-${provider.name}-${tts.model ?? ''}',
            ),
            initialValue: tts.model ?? '',
            decoration: InputDecoration(
              labelText: i18n.t('ttsModel'),
              hintText: i18n.t('ttsModelIdHint'),
            ),
            onChanged: (value) {
              state.updateConfig(
                config.copyWith(tts: tts.copyWith(model: value.trim())),
              );
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: ValueKey<String>(
              'tts-base-url-${provider.name}-${tts.baseUrl ?? ''}',
            ),
            initialValue: tts.baseUrl ?? '',
            decoration: InputDecoration(labelText: i18n.t('ttsApiBaseUrl')),
            onChanged: (value) {
              state.updateConfig(
                config.copyWith(tts: tts.copyWith(baseUrl: value.trim())),
              );
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: ValueKey<String>(
              'tts-custom-voice-${provider.name}-${tts.remoteVoice}',
            ),
            initialValue: tts.remoteVoice,
            decoration: InputDecoration(
              labelText: i18n.t('speech.remote.custom_voice_id'),
            ),
            onChanged: (value) {
              final next = value.trim();
              state.updateConfig(
                config.copyWith(
                  tts: tts.copyWith(
                    voice: next,
                    remoteVoice: next,
                    remoteVoiceTypes: <String>[next],
                  ),
                ),
              );
            },
          ),
        ],
        if (ttsProviderNeedsAppId(provider)) ...<Widget>[
          TextFormField(
            key: ValueKey<String>(
              'tts-app-id-${provider.name}-${tts.appId ?? ''}',
            ),
            initialValue: tts.appId ?? '',
            decoration: InputDecoration(
              labelText: i18n.t('speech.remote.app_id'),
            ),
            onChanged: (value) {
              state.updateConfig(
                config.copyWith(tts: tts.copyWith(appId: value.trim())),
              );
            },
          ),
        ],
        if (provider == TtsProviderType.customApi ||
            ttsProviderNeedsAppId(provider))
          const SizedBox(height: 10),
        TextFormField(
          key: ValueKey<String>(
            'tts-api-key-${provider.name}-${tts.apiKey ?? ''}',
          ),
          initialValue: tts.apiKey ?? '',
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          decoration: InputDecoration(labelText: i18n.t('ttsApiKey')),
          onChanged: (value) {
            state.updateConfig(
              config.copyWith(tts: tts.copyWith(apiKey: value.trim())),
            );
          },
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        Text(
          i18n.t('speech.tts.settings.style_prompt_title'),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        TextFormField(
          key: ValueKey<String>(
            'tts-style-prompt-${provider.name}-${tts.stylePrompt ?? ''}',
          ),
          initialValue: tts.stylePrompt ?? '',
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: i18n.t('speech.tts.settings.style_prompt_label'),
            helperText: i18n.t('speech.tts.settings.style_prompt_helper'),
          ),
          onChanged: (value) {
            state.updateConfig(
              config.copyWith(
                tts: tts.copyWith(
                  stylePrompt: value.trim().isEmpty ? null : value.trim(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _handleProviderChanged(
    TtsProviderType nextProvider,
    PlayConfig config,
    TtsConfig tts,
  ) {
    final state = ref.read(appStateProvider);
    setState(() {
      _fetchedTtsModels = const <String>[];
      _ttsModelFetchError = null;
    });
    if (nextProvider == TtsProviderType.local) {
      final localVoice = _localVoices.isEmpty
          ? tts.localVoice.trim()
          : _localVoices.contains(tts.localVoice.trim())
          ? tts.localVoice.trim()
          : '';
      state.updateConfig(
        config.copyWith(
          tts: tts.copyWith(
            provider: nextProvider,
            voice: localVoice,
            localVoice: localVoice,
            model: null,
            apiKey: null,
            baseUrl: null,
            appId: null,
            language: 'auto',
          ),
        ),
      );
      return;
    }

    final currentModel = (tts.model ?? '').trim();
    final model =
        nextProvider == TtsProviderType.customApi && currentModel.isNotEmpty
        ? currentModel
        : defaultTtsModelForProvider(nextProvider);
    final language = selectTtsLanguageForModel(
      provider: nextProvider,
      model: model,
      currentLanguage: 'auto',
    );
    final remoteVoice = selectTtsVoiceForModelLanguage(
      provider: nextProvider,
      model: model,
      currentVoice: '',
      language: language,
      savedVoices: tts.normalizedRemoteVoiceTypes,
    );
    state.updateConfig(
      config.copyWith(
        tts: tts.copyWith(
          provider: nextProvider,
          model: model,
          voice: remoteVoice,
          remoteVoice: remoteVoice,
          remoteVoiceTypes: <String>[remoteVoice],
          language: language,
          apiKey: null,
          baseUrl: nextProvider == TtsProviderType.customApi
              ? tts.baseUrl
              : null,
          appId: nextProvider == TtsProviderType.doubao ? tts.appId : null,
        ),
      ),
    );
  }

  int _importModelVoices({
    required PlayConfig config,
    required TtsConfig tts,
    required String model,
    required String language,
    required List<String> voices,
  }) {
    final state = ref.read(appStateProvider);
    final imported = <String>[];
    void addVoice(String raw) {
      final value = raw.trim();
      if (value.isEmpty || imported.contains(value)) return;
      imported.add(value);
    }

    for (final voice in voices) {
      addVoice(voice);
    }
    for (final voice in defaultTtsVoicesForModel(
      provider: tts.provider,
      model: model,
    )) {
      addVoice(voice);
    }
    final nextVoice = selectTtsVoiceForModelLanguage(
      provider: tts.provider,
      model: model,
      currentVoice: tts.remoteVoice,
      language: language,
      savedVoices: imported,
      fetchedModelIds: _fetchedTtsModels,
    );
    state.updateConfig(
      config.copyWith(
        tts: tts.copyWith(
          model: model,
          language: language,
          voice: nextVoice,
          remoteVoice: nextVoice,
          remoteVoiceTypes: imported.isEmpty ? <String>[nextVoice] : imported,
        ),
      ),
    );
    return imported.length;
  }

  String _remoteTip(AppI18n i18n, TtsProviderType provider) {
    return switch (provider) {
      TtsProviderType.doubao => i18n.t('speech.tts.settings.remote_tip_doubao'),
      TtsProviderType.customApi => i18n.t(
        'speech.tts.settings.remote_tip_custom',
      ),
      _ => i18n.t('speech.tts.settings.remote_tip'),
    };
  }
}

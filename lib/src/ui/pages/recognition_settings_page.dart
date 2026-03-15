import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/play_config.dart';
import '../../services/asr_service.dart';
import '../../state/app_state.dart';
import '../../utils/asr_language.dart';
import '../modal_helpers.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';

class RecognitionSettingsPage extends StatefulWidget {
  const RecognitionSettingsPage({super.key});

  @override
  State<RecognitionSettingsPage> createState() =>
      _RecognitionSettingsPageState();
}

class _RecognitionSettingsPageState extends State<RecognitionSettingsPage> {
  static const List<AsrProviderType> _multiEngineCandidates = <AsrProviderType>[
    AsrProviderType.offline,
    AsrProviderType.offlineSmall,
    AsrProviderType.localSimilarity,
  ];

  static const List<AsrProviderType> _multiEngineDefaultOrder =
      <AsrProviderType>[
        AsrProviderType.offline,
        AsrProviderType.localSimilarity,
      ];

  static const List<PronScoringMethod> _scoringCandidates = <PronScoringMethod>[
    PronScoringMethod.sslEmbedding,
    PronScoringMethod.gop,
    PronScoringMethod.forcedAlignmentPer,
    PronScoringMethod.ppgPosterior,
  ];

  static const List<AsrProviderType> _managedOfflineProviders =
      <AsrProviderType>[AsrProviderType.offline, AsrProviderType.offlineSmall];

  static const Map<AsrProviderType, String> _asrOfflineModelSizeHints =
      <AsrProviderType, String>{
        AsrProviderType.offline: '~150 MB',
        AsrProviderType.offlineSmall: '~250 MB',
      };

  static const Map<PronScoringMethod, String> _asrScoringPackSizeHints =
      <PronScoringMethod, String>{
        PronScoringMethod.sslEmbedding: '~42 MB',
        PronScoringMethod.gop: '~28 MB',
        PronScoringMethod.forcedAlignmentPer: '~56 MB',
        PronScoringMethod.ppgPosterior: '~64 MB',
      };

  final Map<AsrProviderType, AsrOfflineModelStatus> _offlineStatuses =
      <AsrProviderType, AsrOfflineModelStatus>{};
  final Map<PronScoringMethod, PronScoringPackStatus> _scoringPackStatuses =
      <PronScoringMethod, PronScoringPackStatus>{};

  final Set<AsrProviderType> _offlineBusyProviders = <AsrProviderType>{};
  final Set<PronScoringMethod> _scoringBusyMethods = <PronScoringMethod>{};

  AsrProviderType? _offlineActionProvider;
  AsrProgress? _offlineActionProgress;
  String? _offlineActionError;

  PronScoringMethod? _scoringActionMethod;
  AsrProgress? _scoringActionProgress;
  String? _scoringActionError;

  bool _loadingPackages = false;

  @override
  void initState() {
    super.initState();
    _refreshPackageStatuses();
  }

  Future<void> _refreshPackageStatuses() async {
    if (_loadingPackages) return;
    setState(() {
      _loadingPackages = true;
    });
    final state = context.read<AppState>();
    final offlineResults = <AsrProviderType, AsrOfflineModelStatus>{};
    final scoringResults = <PronScoringMethod, PronScoringPackStatus>{};

    try {
      for (final provider in _managedOfflineProviders) {
        offlineResults[provider] = await state.getAsrOfflineModelStatus(
          provider,
        );
      }
      for (final method in _scoringCandidates) {
        scoringResults[method] = await state.getPronScoringPackStatus(method);
      }
      if (!mounted) return;
      setState(() {
        _offlineStatuses
          ..clear()
          ..addAll(offlineResults);
        _scoringPackStatuses
          ..clear()
          ..addAll(scoringResults);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingPackages = false;
        });
      }
    }
  }

  Future<void> _performOfflineModelAction(
    AsrProviderType provider, {
    required bool install,
  }) async {
    final state = context.read<AppState>();
    if (install) {
      final confirmed = await _confirmOfflineModelInstall(provider);
      if (!confirmed) return;
    }
    setState(() {
      _offlineBusyProviders.add(provider);
      _offlineActionProvider = provider;
      _offlineActionProgress = null;
      _offlineActionError = null;
    });

    try {
      if (install) {
        await state.prepareAsrOfflineModel(
          provider,
          onProgress: (progress) {
            if (!mounted) return;
            setState(() {
              _offlineActionProvider = provider;
              _offlineActionProgress = progress;
            });
          },
        );
      } else {
        await state.removeAsrOfflineModel(provider);
      }
      final refreshed = await state.getAsrOfflineModelStatus(provider);
      if (!mounted) return;
      setState(() {
        _offlineStatuses[provider] = refreshed;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _offlineActionError = '$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _offlineBusyProviders.remove(provider);
          if (_offlineActionProvider == provider) {
            _offlineActionProgress = null;
          }
        });
      }
    }
  }

  Future<void> _performScoringPackAction(
    PronScoringMethod method, {
    required bool install,
  }) async {
    final state = context.read<AppState>();
    if (install) {
      final confirmed = await _confirmScoringPackInstall(method);
      if (!confirmed) return;
    }
    setState(() {
      _scoringBusyMethods.add(method);
      _scoringActionMethod = method;
      _scoringActionProgress = null;
      _scoringActionError = null;
    });

    try {
      if (install) {
        await state.preparePronScoringPack(
          method,
          onProgress: (progress) {
            if (!mounted) return;
            setState(() {
              _scoringActionMethod = method;
              _scoringActionProgress = progress;
            });
          },
        );
      } else {
        await state.removePronScoringPack(method);
      }

      final refreshed = await state.getPronScoringPackStatus(method);
      if (!mounted) return;
      setState(() {
        _scoringPackStatuses[method] = refreshed;
      });

      final config = state.config;
      final asr = config.asr;
      if (!refreshed.installed && asr.scoringMethods.contains(method)) {
        final nextMethods = List<PronScoringMethod>.from(asr.scoringMethods)
          ..remove(method);
        if (nextMethods.isEmpty) {
          for (final candidate in _scoringCandidates) {
            final candidateStatus = _scoringPackStatuses[candidate];
            if (candidateStatus?.installed == true) {
              nextMethods.add(candidate);
              break;
            }
          }
        }
        state.updateConfig(
          config.copyWith(asr: asr.copyWith(scoringMethods: nextMethods)),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _scoringActionError = '$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _scoringBusyMethods.remove(method);
          if (_scoringActionMethod == method) {
            _scoringActionProgress = null;
          }
        });
      }
    }
  }

  Future<bool> _confirmOfflineModelInstall(AsrProviderType provider) {
    final state = context.read<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final sizeText = _resolveOfflineSizeText(provider);
    return showConfirmDialog(
      context: context,
      title: pickUiText(
        i18n,
        zh: '下载离线识别包',
        en: 'Download offline ASR package',
      ),
      message: pickUiText(
        i18n,
        zh: '${asrProviderLabel(i18n, provider)} 约 $sizeText，初始化下载可能需要一些时间。确认后开始下载，请耐心等待。',
        en: '${asrProviderLabel(i18n, provider)} is about $sizeText. Download and initialization may take some time. Continue and please wait patiently.',
      ),
      confirmText: pickUiText(i18n, zh: '下载', en: 'Download'),
    );
  }

  Future<bool> _confirmScoringPackInstall(PronScoringMethod method) {
    final state = context.read<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final sizeText = _resolveScoringSizeText(method);
    return showConfirmDialog(
      context: context,
      title: pickUiText(i18n, zh: '下载评分包', en: 'Download scoring pack'),
      message: pickUiText(
        i18n,
        zh: '${_scoringMethodLabel(i18n, method)} 约 $sizeText，初始化下载可能需要一些时间。确认后开始下载，请耐心等待。',
        en: '${_scoringMethodLabel(i18n, method)} is about $sizeText. Download and initialization may take some time. Continue and please wait patiently.',
      ),
      confirmText: pickUiText(i18n, zh: '下载', en: 'Download'),
    );
  }

  bool _isLocalAsrProvider(AsrProviderType provider) {
    return switch (provider) {
      AsrProviderType.offline ||
      AsrProviderType.offlineSmall ||
      AsrProviderType.localSimilarity ||
      AsrProviderType.multiEngine => true,
      _ => false,
    };
  }

  bool _shouldConfirmLocalAsrSwitch(
    AsrProviderType current,
    AsrProviderType next,
  ) {
    if (current == next) {
      return false;
    }
    return !_isLocalAsrProvider(current) && _isLocalAsrProvider(next);
  }

  Future<bool> _confirmLocalAsrSwitch(AsrProviderType provider) {
    final state = context.read<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    return showConfirmDialog(
      context: context,
      title: pickUiText(
        i18n,
        zh: '切换到本地识别？',
        en: 'Switch to local recognition?',
      ),
      message: pickUiText(
        i18n,
        zh: '推荐优先使用 API 识别以保证准确率，API 免费，只需要注册即可。如果你仍想使用本地识别，也可以继续切换到 ${asrProviderLabel(i18n, provider)}。',
        en: 'API recognition is recommended for better accuracy, and the API tier is free with a simple signup. You can still continue if you prefer ${asrProviderLabel(i18n, provider)}.',
      ),
      confirmText: pickUiText(i18n, zh: '仍然切换', en: 'Switch anyway'),
    );
  }

  Future<void> _handleAsrProviderChanged(
    AsrProviderType value,
    PlayConfig config,
    AsrConfig asr,
  ) async {
    if (_shouldConfirmLocalAsrSwitch(asr.provider, value)) {
      final confirmed = await _confirmLocalAsrSwitch(value);
      if (!confirmed || !mounted) {
        return;
      }
    }

    final nextEngineOrder = value == AsrProviderType.multiEngine
        ? _sanitizeMultiEngineOrder(
            asr.engineOrder.isEmpty
                ? asr.normalizedEngineOrder
                : asr.engineOrder,
          )
        : asr.engineOrder;

    context.read<AppState>().updateConfig(
      config.copyWith(
        asr: asr.copyWith(provider: value, engineOrder: nextEngineOrder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final config = state.config;
    final asr = config.asr;
    final languageOptions = List<String>.from(kAsrLanguagePresetOptions);
    final language = normalizeAsrLanguageTag(asr.language);
    if (!languageOptions.contains(language)) {
      languageOptions.add(language);
    }

    final selectedEngines = asr.provider == AsrProviderType.multiEngine
        ? _sanitizeMultiEngineOrder(
            asr.engineOrder.isEmpty
                ? asr.normalizedEngineOrder
                : asr.engineOrder,
          )
        : <AsrProviderType>[asr.provider];
    final selectedScoringMethods = asr.normalizedScoringMethods;
    final usesApi =
        asr.provider == AsrProviderType.api ||
        asr.provider == AsrProviderType.customApi;
    final usesCustomApi = asr.provider == AsrProviderType.customApi;

    return Scaffold(
      appBar: AppBar(
        title: Text(pickUiText(i18n, zh: '识别与跟读', en: 'Recognition settings')),
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
                    title: pickUiText(i18n, zh: 'ASR 开关', en: 'ASR switch'),
                    subtitle: pickUiText(
                      i18n,
                      zh: '跟读练习会根据这个开关启用识别能力。',
                      en: 'Follow-along practice uses this switch as the recognition gate.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      pickUiText(
                        i18n,
                        zh: '启用跟读识别',
                        en: 'Enable ASR follow-along',
                      ),
                    ),
                    value: asr.enabled,
                    onChanged: (value) {
                      state.updateConfig(
                        config.copyWith(asr: asr.copyWith(enabled: value)),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<AsrProviderType>(
                    initialValue: asr.provider,
                    decoration: InputDecoration(
                      labelText: i18n.t('asrProvider'),
                    ),
                    items: AsrProviderType.values
                        .map(
                          (provider) => DropdownMenuItem<AsrProviderType>(
                            value: provider,
                            child: Text(asrProviderLabel(i18n, provider)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) async {
                      if (value == null) return;
                      await _handleAsrProviderChanged(value, config, asr);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _providerHint(i18n, asr.provider),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (asr.provider == AsrProviderType.multiEngine) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      pickUiText(
                        i18n,
                        zh: '多引擎处理链',
                        en: 'Multi-engine pipeline',
                      ),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pickUiText(
                        i18n,
                        zh: '仅支持离线识别和 MFCC + DTW（本地相似度），不调用远程 API。',
                        en: 'Offline recognizers and MFCC + DTW only. No remote API.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    for (final engine in _multiEngineCandidates)
                      CheckboxListTile.adaptive(
                        value: selectedEngines.contains(engine),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(_engineLabel(i18n, engine)),
                        onChanged: (checked) {
                          final next = _toggleEngine(
                            selectedEngines,
                            engine,
                            checked ?? false,
                          );
                          state.updateConfig(
                            config.copyWith(
                              asr: asr.copyWith(engineOrder: next),
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
                    title: pickUiText(
                      i18n,
                      zh: '识别参数',
                      en: 'Recognition tuning',
                    ),
                    subtitle: pickUiText(
                      i18n,
                      zh: '控制语言、远程接口和诊断选项。',
                      en: 'Tune language, API fields, and diagnostics.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: language,
                    decoration: InputDecoration(
                      labelText: pickUiText(
                        i18n,
                        zh: '识别语言',
                        en: 'Recognition language',
                      ),
                    ),
                    items: languageOptions
                        .map(
                          (code) => DropdownMenuItem<String>(
                            value: code,
                            child: Text(_languageLabel(i18n, code)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null || value.trim().isEmpty) return;
                      state.updateConfig(
                        config.copyWith(asr: asr.copyWith(language: value)),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '快速笔记的系统语音听写会复用这里的识别语言设置。',
                      en: 'Quick note system dictation reuses this setting. Prefer System default or a full locale such as en-US or zh-CN.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (usesCustomApi) ...<Widget>[
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: asr.baseUrl ?? '',
                      decoration: InputDecoration(
                        labelText: i18n.t('asrApiBaseUrl'),
                      ),
                      onChanged: (value) {
                        state.updateConfig(
                          config.copyWith(
                            asr: asr.copyWith(baseUrl: value.trim()),
                          ),
                        );
                      },
                    ),
                  ],
                  if (usesApi) ...<Widget>[
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: asr.model,
                      decoration: InputDecoration(
                        labelText: i18n.t('asrModel'),
                      ),
                      onChanged: (value) {
                        state.updateConfig(
                          config.copyWith(
                            asr: asr.copyWith(model: value.trim()),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: asr.apiKey ?? '',
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: i18n.t('asrApiKey'),
                      ),
                      onChanged: (value) {
                        state.updateConfig(
                          config.copyWith(
                            asr: asr.copyWith(apiKey: value.trim()),
                          ),
                        );
                      },
                    ),
                  ],
                  if (asr.provider == AsrProviderType.multiEngine) ...<Widget>[
                    const SizedBox(height: 14),
                    Text(
                      i18n.t('asrScoringMethods'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      i18n.t('asrScoringMethodsHint'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    for (final method in _scoringCandidates)
                      Builder(
                        builder: (context) {
                          final status = _scoringPackStatuses[method];
                          final installed = status?.installed ?? false;
                          return CheckboxListTile.adaptive(
                            value:
                                selectedScoringMethods.contains(method) &&
                                installed,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(_scoringMethodLabel(i18n, method)),
                            subtitle: installed
                                ? null
                                : Text(i18n.t('asrScoringPackInstallFirst')),
                            onChanged: installed
                                ? (checked) {
                                    final next = _toggleScoringMethod(
                                      selectedScoringMethods,
                                      method,
                                      checked ?? false,
                                    );
                                    state.updateConfig(
                                      config.copyWith(
                                        asr: asr.copyWith(scoringMethods: next),
                                      ),
                                    );
                                  }
                                : null,
                          );
                        },
                      ),
                  ],
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      pickUiText(
                        i18n,
                        zh: '保留识别中间音频',
                        en: 'Keep recognition debug audio',
                      ),
                    ),
                    subtitle: Text(
                      pickUiText(
                        i18n,
                        zh: '用于比较与排查，日常使用建议关闭。',
                        en: 'Useful for diagnostics; keep off for daily use.',
                      ),
                    ),
                    value: asr.dumpRecognitionAudioArtifacts,
                    onChanged: (value) {
                      state.updateConfig(
                        config.copyWith(
                          asr: asr.copyWith(
                            dumpRecognitionAudioArtifacts: value,
                          ),
                        ),
                      );
                    },
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
                    title: i18n.t('asrOfflineModelManager'),
                    subtitle: pickUiText(
                      i18n,
                      zh: '离线模型和评分包可在这里下载与删除。',
                      en: 'Manage offline models and scoring packs here.',
                    ),
                  ),
                  if (_loadingPackages) ...<Widget>[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  const SizedBox(height: 12),
                  for (final provider in _managedOfflineProviders)
                    _PackageRow(
                      title: asrProviderLabel(i18n, provider),
                      installed: _offlineStatuses[provider]?.installed ?? false,
                      busy: _offlineBusyProviders.contains(provider),
                      onDownload: () =>
                          _performOfflineModelAction(provider, install: true),
                      onRemove: () =>
                          _performOfflineModelAction(provider, install: false),
                      downloadLabel: i18n.t('download'),
                      removeLabel: i18n.t('delete'),
                      busyLabel: i18n.t('processing'),
                      installedLabel: i18n.t(
                        'asrModelInstalled',
                        params: <String, Object?>{
                          'size': _resolveOfflineSizeText(provider),
                        },
                      ),
                      notInstalledLabel: i18n.t(
                        'asrModelNotInstalled',
                        params: <String, Object?>{
                          'size': _resolveOfflineSizeText(provider),
                        },
                      ),
                    ),
                  if (_offlineActionProvider != null &&
                      _offlineActionProgress != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      '${asrProviderLabel(i18n, _offlineActionProvider!)} - ${i18n.t(_offlineActionProgress!.messageKey, params: _offlineActionProgress!.messageParams)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: _offlineActionProgress!.progress,
                    ),
                  ],
                  if ((_offlineActionError ?? '')
                      .trim()
                      .isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      _offlineActionError ?? '',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    i18n.t('asrScoringPackManager'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final method in _scoringCandidates)
                    _PackageRow(
                      title: _scoringMethodLabel(i18n, method),
                      installed:
                          _scoringPackStatuses[method]?.installed ?? false,
                      busy: _scoringBusyMethods.contains(method),
                      onDownload: () =>
                          _performScoringPackAction(method, install: true),
                      onRemove: () =>
                          _performScoringPackAction(method, install: false),
                      downloadLabel: i18n.t('download'),
                      removeLabel: i18n.t('delete'),
                      busyLabel: i18n.t('processing'),
                      installedLabel: i18n.t(
                        'asrModelInstalled',
                        params: <String, Object?>{
                          'size': _resolveScoringSizeText(method),
                        },
                      ),
                      notInstalledLabel: i18n.t(
                        'asrModelNotInstalled',
                        params: <String, Object?>{
                          'size': _resolveScoringSizeText(method),
                        },
                      ),
                    ),
                  if (_scoringActionMethod != null &&
                      _scoringActionProgress != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      '${_scoringMethodLabel(i18n, _scoringActionMethod!)} - ${i18n.t(_scoringActionProgress!.messageKey, params: _scoringActionProgress!.messageParams)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: _scoringActionProgress!.progress,
                    ),
                  ],
                  if ((_scoringActionError ?? '')
                      .trim()
                      .isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      _scoringActionError ?? '',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _providerHint(AppI18n i18n, AsrProviderType provider) {
    return switch (provider) {
      AsrProviderType.localSimilarity => i18n.t('asrLocalSimilarityHint'),
      AsrProviderType.multiEngine => pickUiText(
        i18n,
        zh: '多引擎仅用于本地离线识别链路，不调用远程 API。',
        en: 'Multi-engine is offline-only and does not call remote API.',
      ),
      _ => pickUiText(
        i18n,
        zh: '你可以在练习页直接使用当前引擎配置。',
        en: 'This engine selection will be used directly in practice pages.',
      ),
    };
  }

  String _engineLabel(AppI18n i18n, AsrProviderType provider) {
    if (provider == AsrProviderType.localSimilarity) {
      return pickUiText(
        i18n,
        zh: 'MFCC + DTW（本地相似度）',
        en: 'MFCC + DTW (Local similarity)',
      );
    }
    return asrProviderLabel(i18n, provider);
  }

  String _scoringMethodLabel(AppI18n i18n, PronScoringMethod method) {
    return switch (method) {
      PronScoringMethod.sslEmbedding => i18n.t('scorerSslEmbedding'),
      PronScoringMethod.gop => i18n.t('scorerGop'),
      PronScoringMethod.forcedAlignmentPer => i18n.t(
        'scorerForcedAlignmentPer',
      ),
      PronScoringMethod.ppgPosterior => i18n.t('scorerPpgPosterior'),
    };
  }

  List<AsrProviderType> _sanitizeMultiEngineOrder(
    List<AsrProviderType> source,
  ) {
    final normalized = <AsrProviderType>[];
    for (final engine in _multiEngineCandidates) {
      if (source.contains(engine)) {
        normalized.add(engine);
      }
    }
    if (normalized.isEmpty) {
      normalized.addAll(_multiEngineDefaultOrder);
    }
    return normalized;
  }

  List<AsrProviderType> _toggleEngine(
    List<AsrProviderType> selected,
    AsrProviderType candidate,
    bool enabled,
  ) {
    final next = List<AsrProviderType>.from(selected);
    if (enabled) {
      if (!next.contains(candidate)) {
        next.add(candidate);
      }
    } else {
      if (next.length <= 1) {
        return next;
      }
      next.remove(candidate);
    }
    return _sanitizeMultiEngineOrder(next);
  }

  List<PronScoringMethod> _toggleScoringMethod(
    List<PronScoringMethod> selected,
    PronScoringMethod method,
    bool enabled,
  ) {
    final next = List<PronScoringMethod>.from(selected);
    if (enabled) {
      if (!next.contains(method)) {
        next.add(method);
      }
    } else {
      next.remove(method);
    }
    if (next.isEmpty) {
      next.add(method);
    }
    return next;
  }

  String _languageLabel(AppI18n i18n, String code) {
    return asrLanguageLabel(i18n, code);
  }

  String _resolveOfflineSizeText(AsrProviderType provider) {
    final status = _offlineStatuses[provider];
    if (status != null && status.installed && status.bytes > 0) {
      return _formatStorageSize(status.bytes);
    }
    return _asrOfflineModelSizeHints[provider] ?? '~150 MB';
  }

  String _resolveScoringSizeText(PronScoringMethod method) {
    final status = _scoringPackStatuses[method];
    if (status != null && status.installed && status.bytes > 0) {
      return _formatStorageSize(status.bytes);
    }
    return _asrScoringPackSizeHints[method] ?? '~32 MB';
  }

  String _formatStorageSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex += 1;
    }
    final digits = value >= 10 || unitIndex == 0 ? 0 : 1;
    return '${value.toStringAsFixed(digits)} ${units[unitIndex]}';
  }
}

class _PackageRow extends StatelessWidget {
  const _PackageRow({
    required this.title,
    required this.installed,
    required this.busy,
    required this.onDownload,
    required this.onRemove,
    required this.downloadLabel,
    required this.removeLabel,
    required this.busyLabel,
    required this.installedLabel,
    required this.notInstalledLabel,
  });

  final String title;
  final bool installed;
  final bool busy;
  final VoidCallback onDownload;
  final VoidCallback onRemove;
  final String downloadLabel;
  final String removeLabel;
  final String busyLabel;
  final String installedLabel;
  final String notInstalledLabel;

  @override
  Widget build(BuildContext context) {
    final hint = installed ? installedLabel : notInstalledLabel;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(hint, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: busy ? null : onDownload,
            child: Text(busy ? busyLabel : downloadLabel),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: (!installed || busy) ? null : onRemove,
            child: Text(removeLabel),
          ),
        ],
      ),
    );
  }
}

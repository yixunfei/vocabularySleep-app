import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/play_config.dart';
import '../../state/app_state.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';

class RecognitionSettingsPage extends StatelessWidget {
  const RecognitionSettingsPage({super.key});

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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final config = state.config;
    final asr = config.asr;
    final languageOptions = <String>['en', 'zh', 'ja', 'de', 'fr', 'es'];
    final language = asr.language.trim().isEmpty ? 'en' : asr.language.trim();
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
                    onChanged: (value) {
                      if (value == null) return;
                      final nextEngineOrder =
                          value == AsrProviderType.multiEngine
                          ? _sanitizeMultiEngineOrder(
                              asr.engineOrder.isEmpty
                                  ? asr.normalizedEngineOrder
                                  : asr.engineOrder,
                            )
                          : asr.engineOrder;
                      state.updateConfig(
                        config.copyWith(
                          asr: asr.copyWith(
                            provider: value,
                            engineOrder: nextEngineOrder,
                          ),
                        ),
                      );
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
                      CheckboxListTile.adaptive(
                        value: selectedScoringMethods.contains(method),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(_scoringMethodLabel(i18n, method)),
                        onChanged: (checked) {
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
    final normalized = code.trim().toLowerCase();
    final isKnown = AppI18n.supportedLanguages.contains(normalized);
    if (isKnown) {
      return '${i18n.languageName(normalized)} ($normalized)';
    }
    return normalized;
  }
}

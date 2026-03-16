import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/play_config.dart';
import '../../services/asr_service.dart';
import '../../state/app_state.dart';
import '../../utils/asr_language.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';

class VoiceInputSettingsPage extends StatefulWidget {
  const VoiceInputSettingsPage({super.key});

  @override
  State<VoiceInputSettingsPage> createState() => _VoiceInputSettingsPageState();
}

class _VoiceInputSettingsPageState extends State<VoiceInputSettingsPage> {
  static const String _offlineModelSizeHint = '~150 MB';

  AsrOfflineModelStatus? _offlineStatus;
  bool _offlineBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshOfflineStatus();
    });
  }

  Future<void> _refreshOfflineStatus() async {
    final status = await context
        .read<AppState>()
        .getVoiceInputOfflineModelStatus();
    if (!mounted) return;
    setState(() {
      _offlineStatus = status;
    });
  }

  Future<void> _handleOfflineAction({required bool install}) async {
    setState(() {
      _offlineBusy = true;
    });
    try {
      final state = context.read<AppState>();
      if (install) {
        await state.prepareVoiceInputOfflineModel();
      } else {
        await state.removeVoiceInputOfflineModel();
      }
      await _refreshOfflineStatus();
    } catch (error) {
      if (!mounted) return;
      final i18n = AppI18n(context.read<AppState>().uiLanguage);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            pickUiText(
              i18n,
              zh: '语音输入离线模型操作失败：$error',
              en: 'Voice input offline model action failed: $error',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _offlineBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final config = state.config;
    final voiceInput = config.voiceInput;
    final language = normalizeAsrLanguageTag(voiceInput.language);
    final languageOptions = <String>[
      ...kAsrLanguagePresetOptions,
      if (!kAsrLanguagePresetOptions.contains(language)) language,
    ];
    final offlineInstalled = _offlineStatus?.installed ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(pickUiText(i18n, zh: '语音输入设置', en: 'Voice input settings')),
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
                    title: pickUiText(i18n, zh: '输入引擎', en: 'Input engine'),
                    subtitle: pickUiText(
                      i18n,
                      zh: '快速笔记的语音输入与跟读识别分开设置，互不影响。',
                      en: 'Quick-note voice input is configured separately from follow-along recognition.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<VoiceInputProviderType>(
                    initialValue: voiceInput.provider,
                    decoration: InputDecoration(
                      labelText: pickUiText(
                        i18n,
                        zh: '语音输入方式',
                        en: 'Voice input provider',
                      ),
                    ),
                    items: VoiceInputProviderType.values
                        .map(
                          (provider) =>
                              DropdownMenuItem<VoiceInputProviderType>(
                                value: provider,
                                child: Text(
                                  voiceInputProviderLabel(i18n, provider),
                                ),
                              ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      state.updateConfig(
                        config.copyWith(
                          voiceInput: voiceInput.copyWith(provider: value),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _providerHint(i18n, voiceInput.provider),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    title: pickUiText(i18n, zh: '输入语言', en: 'Input language'),
                    subtitle: pickUiText(
                      i18n,
                      zh: '建议优先使用系统默认或完整语言区域码，例如 zh-CN、en-US。',
                      en: 'Prefer the system default or a full locale tag such as zh-CN or en-US.',
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
                            child: Text(asrLanguageLabel(i18n, code)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null || value.trim().isEmpty) return;
                      state.updateConfig(
                        config.copyWith(
                          voiceInput: voiceInput.copyWith(language: value),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (voiceInput.provider == VoiceInputProviderType.api) ...<Widget>[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SectionHeader(
                      title: pickUiText(i18n, zh: 'API 参数', en: 'API fields'),
                      subtitle: pickUiText(
                        i18n,
                        zh: 'API 模式用于语音输入转写，不会影响跟读评分链路。',
                        en: 'These API fields are used only for voice-input transcription.',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      initialValue: voiceInput.model,
                      decoration: InputDecoration(
                        labelText: i18n.t('asrModel'),
                      ),
                      onChanged: (value) {
                        state.updateConfig(
                          config.copyWith(
                            voiceInput: voiceInput.copyWith(
                              model: value.trim(),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: voiceInput.apiKey ?? '',
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: i18n.t('asrApiKey'),
                      ),
                      onChanged: (value) {
                        state.updateConfig(
                          config.copyWith(
                            voiceInput: voiceInput.copyWith(
                              apiKey: value.trim(),
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
          if (voiceInput.provider ==
              VoiceInputProviderType.offline) ...<Widget>[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SectionHeader(
                      title: pickUiText(i18n, zh: '离线模型', en: 'Offline model'),
                      subtitle: pickUiText(
                        i18n,
                        zh: '首次使用离线语音输入前需要下载模型包。',
                        en: 'Download the offline package before using offline voice input for the first time.',
                      ),
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        pickUiText(
                          i18n,
                          zh: '离线引擎包',
                          en: 'Offline engine package',
                        ),
                      ),
                      subtitle: Text(
                        offlineInstalled
                            ? pickUiText(
                                i18n,
                                zh: '已安装，可直接用于语音输入。',
                                en: 'Installed and ready for voice input.',
                              )
                            : i18n.t(
                                'asrModelNotInstalled',
                                params: const <String, Object?>{
                                  'size': _offlineModelSizeHint,
                                },
                              ),
                      ),
                      trailing: _offlineBusy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : FilledButton.tonal(
                              onPressed: () => _handleOfflineAction(
                                install: !offlineInstalled,
                              ),
                              child: Text(
                                pickUiText(
                                  i18n,
                                  zh: offlineInstalled ? '移除' : '下载',
                                  en: offlineInstalled ? 'Remove' : 'Download',
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (voiceInput.provider == VoiceInputProviderType.system) ...<Widget>[
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
                        zh: '系统语音识别',
                        en: 'System speech recognition',
                      ),
                      subtitle: pickUiText(
                        i18n,
                        zh: 'Android 使用 SpeechRecognizer / RecognizerIntent，iOS 使用 SFSpeechRecognizer。',
                        en: 'Android uses SpeechRecognizer / RecognizerIntent, and iOS uses SFSpeechRecognizer.',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pickUiText(
                        i18n,
                        zh: '该模式直接调用系统语音识别能力，适合快速输入短笔记。',
                        en: 'This mode uses the platform recognizer directly and is ideal for fast short-note input.',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _providerHint(AppI18n i18n, VoiceInputProviderType provider) {
    return switch (provider) {
      VoiceInputProviderType.api => pickUiText(
        i18n,
        zh: '使用远程 API 转写，识别质量更高，但需要网络与 API Key。',
        en: 'Uses a remote API for transcription. Higher quality, but requires network access and an API key.',
      ),
      VoiceInputProviderType.offline => pickUiText(
        i18n,
        zh: '在设备本地完成语音输入转写，首次需要下载离线模型。',
        en: 'Transcribes voice input locally on-device and needs a one-time offline model download.',
      ),
      VoiceInputProviderType.system => pickUiText(
        i18n,
        zh: '直接调用系统听写能力，适合快速输入，但体验依赖系统面板与设备实现。',
        en: 'Uses built-in system dictation. Great for quick input, but the experience depends on the device implementation.',
      ),
    };
  }
}

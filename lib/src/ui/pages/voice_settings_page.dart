import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/play_config.dart';
import '../../state/app_state.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';

class VoiceSettingsPage extends StatelessWidget {
  const VoiceSettingsPage({super.key});

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
                    title: pickUiText(i18n, zh: 'TTS 提供方', en: 'TTS provider'),
                    subtitle: pickUiText(
                      i18n,
                      zh: '统一展示提供方名称，不再直接暴露枚举值。',
                      en: 'Provider names are mapped for a consistent UI copy.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<TtsProviderType>(
                    initialValue: tts.provider,
                    decoration: InputDecoration(
                      labelText: pickUiText(
                        i18n,
                        zh: '语音来源',
                        en: 'Voice source',
                      ),
                    ),
                    items: TtsProviderType.values
                        .map(
                          (provider) => DropdownMenuItem<TtsProviderType>(
                            value: provider,
                            child: Text(ttsProviderLabel(i18n, provider)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      state.updateConfig(
                        config.copyWith(tts: tts.copyWith(provider: value)),
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
                  if ((tts.model ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      pickUiText(
                        i18n,
                        zh: '模型：${tts.model}',
                        en: 'Model: ${tts.model}',
                      ),
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
                      zh: '修改参数后可立即试听当前词发音。',
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
        ],
      ),
    );
  }
}

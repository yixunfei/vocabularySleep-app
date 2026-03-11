import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../state/app_state.dart';
import '../theme/app_theme.dart';
import '../ui_copy.dart';
import '../widgets/page_header.dart';
import '../widgets/setting_tile.dart';
import 'appearance_studio_page.dart';
import 'language_settings_page.dart';
import 'playback_advanced_page.dart';
import 'recognition_settings_page.dart';
import 'voice_settings_page.dart';

class SettingsHomePage extends StatelessWidget {
  const SettingsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final config = state.config;
    final appearance = config.appearance;
    final mode = experienceModeFromAppearance(appearance);
    final asrStatus = config.asr.enabled
        ? pickUiText(i18n, zh: '已启用', en: 'Enabled')
        : pickUiText(i18n, zh: '已关闭', en: 'Disabled');

    return Scaffold(
      appBar: AppBar(
        title: Text(pickUiText(i18n, zh: '设置中心', en: 'Settings center')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          PageHeader(
            eyebrow: pickUiText(i18n, zh: '设置', en: 'Settings'),
            title: pickUiText(i18n, zh: '统一配置中心', en: 'Unified settings'),
            subtitle: pickUiText(
              i18n,
              zh: '把播放、语音、识别和外观分层管理，避免回到旧工作台。',
              en: 'Manage playback, voice, recognition, and appearance in dedicated pages.',
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickUiText(i18n, zh: '当前配置摘要', en: 'Current summary'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '播放：${playOrderLabel(i18n, config.order)} · ${config.showText ? '显示文本' : '隐藏文本'}',
                      en: 'Playback: ${playOrderLabel(i18n, config.order)} · ${config.showText ? 'Text On' : 'Text Off'}',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '语音：${ttsProviderLabel(i18n, config.tts.provider)}',
                      en: 'Voice: ${ttsProviderLabel(i18n, config.tts.provider)}',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '识别：$asrStatus · ${asrProviderLabel(i18n, config.asr.provider)}',
                      en: 'Recognition: $asrStatus · ${asrProviderLabel(i18n, config.asr.provider)}',
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
                  Text(
                    pickUiText(i18n, zh: '体验模式', en: 'Experience mode'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pickUiText(
                      i18n,
                      zh: 'Sleep 更安静，Focus 更强调信息效率。',
                      en: 'Sleep keeps visuals calm; Focus favors information density.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<AppExperienceMode>(
                    segments: AppExperienceMode.values
                        .map(
                          (item) => ButtonSegment<AppExperienceMode>(
                            value: item,
                            label: Text(experienceModeTitle(i18n, item)),
                          ),
                        )
                        .toList(growable: false),
                    selected: <AppExperienceMode>{mode},
                    onSelectionChanged: (selection) {
                      final nextAppearance = applyExperienceMode(
                        appearance,
                        selection.first,
                      );
                      state.updateConfig(
                        config.copyWith(appearance: nextAppearance),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SettingTile(
            icon: Icons.play_circle_outline_rounded,
            title: pickUiText(i18n, zh: '播放高级设置', en: 'Playback advanced'),
            subtitle: pickUiText(
              i18n,
              zh: '播放顺序、文本可见性与节奏参数。',
              en: 'Order, text visibility, and pacing settings.',
            ),
            trailing: Text(
              playOrderLabel(i18n, config.order),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            onTap: () => _open(context, const PlaybackAdvancedPage()),
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.record_voice_over_rounded,
            title: pickUiText(i18n, zh: '语音设置', en: 'Voice settings'),
            subtitle: pickUiText(
              i18n,
              zh: 'TTS 提供方、语速和音量。',
              en: 'TTS provider, speed, and volume.',
            ),
            trailing: Text(
              ttsProviderLabel(i18n, config.tts.provider),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            onTap: () => _open(context, const VoiceSettingsPage()),
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.hearing_rounded,
            title: pickUiText(i18n, zh: '识别与练习', en: 'Recognition'),
            subtitle: pickUiText(
              i18n,
              zh: 'ASR 开关、识别引擎和练习相关设置。',
              en: 'ASR switch, engine, and practice recognition options.',
            ),
            trailing: Text(
              '$asrStatus · ${asrProviderLabel(i18n, config.asr.provider)}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            onTap: () => _open(context, const RecognitionSettingsPage()),
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.palette_outlined,
            title: pickUiText(i18n, zh: '外观工作室', en: 'Appearance studio'),
            subtitle: pickUiText(
              i18n,
              zh: '布局密度、背景与面板风格。',
              en: 'Layout density, background, and panel style.',
            ),
            onTap: () => _open(context, const AppearanceStudioPage()),
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.language_rounded,
            title: pickUiText(i18n, zh: '语言与通用', en: 'Language'),
            subtitle: pickUiText(
              i18n,
              zh: '界面语言与显示偏好。',
              en: 'Interface language and display preferences.',
            ),
            trailing: Text(
              i18n.languageName(state.uiLanguage),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            onTap: () => _open(context, const LanguageSettingsPage()),
          ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, Widget page) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

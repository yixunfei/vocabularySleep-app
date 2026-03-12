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
        ? pickUiText(
            i18n,
            zh: '已启用',
            en: 'Enabled',
            ja: '有効',
            de: 'Aktiv',
            fr: 'Activé',
            es: 'Activado',
            ru: 'Включено',
          )
        : pickUiText(
            i18n,
            zh: '已关闭',
            en: 'Disabled',
            ja: '無効',
            de: 'Aus',
            fr: 'Désactivé',
            es: 'Desactivado',
            ru: 'Выключено',
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          pickUiText(
            i18n,
            zh: '设置中心',
            en: 'Settings center',
            ja: '設定センター',
            de: 'Einstellungszentrale',
            fr: 'Centre des réglages',
            es: 'Centro de ajustes',
            ru: 'Центр настроек',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          PageHeader(
            eyebrow: pickUiText(
              i18n,
              zh: '设置',
              en: 'Settings',
              ja: '設定',
              de: 'Einstellungen',
              fr: 'Réglages',
              es: 'Ajustes',
              ru: 'Настройки',
            ),
            title: pickUiText(
              i18n,
              zh: '统一配置中心',
              en: 'Unified settings',
              ja: '統合設定ハブ',
              de: 'Zentrale Einstellungen',
              fr: 'Réglages unifiés',
              es: 'Ajustes unificados',
              ru: 'Единый центр настроек',
            ),
            subtitle: pickUiText(
              i18n,
              zh: '把播放、语音、识别和外观分别放到独立页面，减少来回切换。',
              en: 'Manage playback, voice, recognition, and appearance in dedicated pages.',
              ja: '再生・音声・認識・外観を専用ページでまとめて管理します。',
              de: 'Verwalte Wiedergabe, Stimme, Erkennung und Design auf eigenen Seiten.',
              fr: 'Gérez lecture, voix, reconnaissance et apparence dans des pages dédiées.',
              es: 'Gestiona reproducción, voz, reconocimiento y apariencia en páginas dedicadas.',
              ru: 'Управляйте воспроизведением, голосом, распознаванием и внешним видом на отдельных страницах.',
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
                    pickUiText(
                      i18n,
                      zh: '当前配置摘要',
                      en: 'Current summary',
                      ja: '現在の概要',
                      de: 'Aktuelle Zusammenfassung',
                      fr: 'Résumé actuel',
                      es: 'Resumen actual',
                      ru: 'Текущее состояние',
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '播放: ${playOrderLabel(i18n, config.order)} · ${config.showText ? '显示文本' : '隐藏文本'}',
                      en: 'Playback: ${playOrderLabel(i18n, config.order)} · ${config.showText ? 'Text On' : 'Text Off'}',
                      ja: '再生: ${playOrderLabel(i18n, config.order)} · ${config.showText ? 'テキスト表示' : 'テキスト非表示'}',
                      de: 'Wiedergabe: ${playOrderLabel(i18n, config.order)} · ${config.showText ? 'Text an' : 'Text aus'}',
                      fr: 'Lecture : ${playOrderLabel(i18n, config.order)} · ${config.showText ? 'Texte visible' : 'Texte masqué'}',
                      es: 'Reproducción: ${playOrderLabel(i18n, config.order)} · ${config.showText ? 'Texto visible' : 'Texto oculto'}',
                      ru: 'Воспроизведение: ${playOrderLabel(i18n, config.order)} · ${config.showText ? 'Текст включён' : 'Текст скрыт'}',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '语音: ${ttsProviderLabel(i18n, config.tts.provider)}',
                      en: 'Voice: ${ttsProviderLabel(i18n, config.tts.provider)}',
                      ja: '音声: ${ttsProviderLabel(i18n, config.tts.provider)}',
                      de: 'Stimme: ${ttsProviderLabel(i18n, config.tts.provider)}',
                      fr: 'Voix : ${ttsProviderLabel(i18n, config.tts.provider)}',
                      es: 'Voz: ${ttsProviderLabel(i18n, config.tts.provider)}',
                      ru: 'Голос: ${ttsProviderLabel(i18n, config.tts.provider)}',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '识别: $asrStatus · ${asrProviderLabel(i18n, config.asr.provider)}',
                      en: 'Recognition: $asrStatus · ${asrProviderLabel(i18n, config.asr.provider)}',
                      ja: '認識: $asrStatus · ${asrProviderLabel(i18n, config.asr.provider)}',
                      de: 'Erkennung: $asrStatus · ${asrProviderLabel(i18n, config.asr.provider)}',
                      fr: 'Reconnaissance : $asrStatus · ${asrProviderLabel(i18n, config.asr.provider)}',
                      es: 'Reconocimiento: $asrStatus · ${asrProviderLabel(i18n, config.asr.provider)}',
                      ru: 'Распознавание: $asrStatus · ${asrProviderLabel(i18n, config.asr.provider)}',
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
                    pickUiText(
                      i18n,
                      zh: '体验模式',
                      en: 'Experience mode',
                      ja: '体験モード',
                      de: 'Erlebnismodus',
                      fr: 'Mode d’expérience',
                      es: 'Modo de experiencia',
                      ru: 'Режим использования',
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pickUiText(
                      i18n,
                      zh: 'Sleep 更安静，Focus 更强调信息密度。',
                      en: 'Sleep keeps visuals calm; Focus favors information density.',
                      ja: 'Sleep は落ち着いた表示、Focus は情報密度を重視します。',
                      de: 'Sleep bleibt ruhig, Focus setzt auf mehr Informationsdichte.',
                      fr: 'Sleep garde une ambiance calme ; Focus privilégie la densité d’information.',
                      es: 'Sleep mantiene una vista calmada; Focus prioriza la densidad de información.',
                      ru: 'Sleep делает интерфейс спокойнее, а Focus повышает плотность информации.',
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
            title: pickUiText(
              i18n,
              zh: '播放高级设置',
              en: 'Playback advanced',
              ja: '再生の詳細設定',
              de: 'Erweiterte Wiedergabe',
              fr: 'Lecture avancée',
              es: 'Reproducción avanzada',
              ru: 'Расширенное воспроизведение',
            ),
            subtitle: pickUiText(
              i18n,
              zh: '播放顺序、文本可见性与节奏参数。',
              en: 'Order, text visibility, and pacing settings.',
              ja: '再生順序、テキスト表示、テンポを調整します。',
              de: 'Reihenfolge, Textsichtbarkeit und Tempo anpassen.',
              fr: 'Réglez l’ordre, la visibilité du texte et le rythme.',
              es: 'Ajusta el orden, la visibilidad del texto y el ritmo.',
              ru: 'Настройте порядок, видимость текста и темп воспроизведения.',
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
            title: pickUiText(
              i18n,
              zh: '语音设置',
              en: 'Voice settings',
              ja: '音声設定',
              de: 'Stimmeinstellungen',
              fr: 'Réglages vocaux',
              es: 'Ajustes de voz',
              ru: 'Настройки голоса',
            ),
            subtitle: pickUiText(
              i18n,
              zh: 'TTS 提供方、语速和音量。',
              en: 'TTS provider, speed, and volume.',
              ja: 'TTS プロバイダー、速度、音量を調整します。',
              de: 'TTS-Anbieter, Geschwindigkeit und Lautstärke.',
              fr: 'Choisissez le fournisseur TTS, la vitesse et le volume.',
              es: 'Proveedor TTS, velocidad y volumen.',
              ru: 'Провайдер TTS, скорость и громкость.',
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
            title: pickUiText(
              i18n,
              zh: '识别与练习',
              en: 'Recognition',
              ja: '認識と練習',
              de: 'Erkennung',
              fr: 'Reconnaissance',
              es: 'Reconocimiento',
              ru: 'Распознавание',
            ),
            subtitle: pickUiText(
              i18n,
              zh: 'ASR 开关、引擎和练习相关配置。',
              en: 'ASR switch, engine, and practice recognition options.',
              ja: 'ASR のオンオフ、エンジン、練習関連設定です。',
              de: 'ASR-Schalter, Engine und Übungsoptionen.',
              fr: 'Activation ASR, moteur et options d’entraînement.',
              es: 'Interruptor ASR, motor y opciones de práctica.',
              ru: 'Переключатель ASR, движок и параметры тренировки.',
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
            title: pickUiText(
              i18n,
              zh: '外观工作室',
              en: 'Appearance studio',
              ja: '外観スタジオ',
              de: 'Design-Studio',
              fr: 'Studio d’apparence',
              es: 'Estudio de apariencia',
              ru: 'Студия оформления',
            ),
            subtitle: pickUiText(
              i18n,
              zh: '布局密度、背景和面板风格。',
              en: 'Layout density, background, and panel style.',
              ja: 'レイアウト密度、背景、パネルスタイルを調整します。',
              de: 'Layoutdichte, Hintergrund und Panel-Stil.',
              fr: 'Densité de mise en page, arrière-plan et style des panneaux.',
              es: 'Densidad, fondo y estilo de paneles.',
              ru: 'Плотность интерфейса, фон и стиль панелей.',
            ),
            onTap: () => _open(context, const AppearanceStudioPage()),
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.language_rounded,
            title: pickUiText(
              i18n,
              zh: '语言与通用',
              en: 'Language',
              ja: '言語と一般',
              de: 'Sprache',
              fr: 'Langue',
              es: 'Idioma',
              ru: 'Язык',
            ),
            subtitle: pickUiText(
              i18n,
              zh: '界面语言与显示偏好。',
              en: 'Interface language and display preferences.',
              ja: '表示言語と表示設定を管理します。',
              de: 'Oberflächensprache und Anzeigeeinstellungen.',
              fr: 'Langue de l’interface et préférences d’affichage.',
              es: 'Idioma de la interfaz y preferencias visuales.',
              ru: 'Язык интерфейса и параметры отображения.',
            ),
            trailing: Text(
              state.uiLanguageFollowsSystem
                  ? pickUiText(
                      i18n,
                      zh: '跟随系统',
                      en: 'Follow system',
                      ja: 'システムに従う',
                      de: 'Systemsprache folgen',
                      fr: 'Suivre le système',
                      es: 'Seguir al sistema',
                      ru: 'Следовать системе',
                    )
                  : i18n.languageName(state.uiLanguage),
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

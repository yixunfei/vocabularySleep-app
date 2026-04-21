import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/app_i18n.dart';
import '../../models/app_home_tab.dart';
import '../../models/focus_startup_tab.dart';
import '../../models/study_startup_tab.dart';
import '../../services/settings_service.dart';
import '../../state/app_state_provider.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';

class LanguageSettingsPage extends ConsumerWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    final currentLanguageName = i18n.languageName(state.uiLanguage);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          pickUiText(
            i18n,
            zh: '语言与通用',
            en: 'Language settings',
            ja: '言語設定',
            de: 'Spracheinstellungen',
            fr: 'Parametres de langue',
            es: 'Ajustes de idioma',
            ru: 'Настройки языка',
          ),
        ),
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
                    title: pickUiText(
                      i18n,
                      zh: '界面语言',
                      en: 'Interface language',
                      ja: '表示言語',
                      de: 'Oberflachensprache',
                      fr: 'Langue de l interface',
                      es: 'Idioma de la interfaz',
                      ru: 'Язык интерфейса',
                    ),
                    subtitle: pickUiText(
                      i18n,
                      zh: '立即生效，覆盖导航、设置和练习页面。',
                      en: 'Applies immediately across navigation and settings.',
                      ja: 'ナビゲーションや設定画面を含め、すぐに反映されます。',
                      de: 'Wird sofort in Navigation und Einstellungen angewendet.',
                      fr: 'S applique immediatement a la navigation et aux reglages.',
                      es: 'Se aplica de inmediato en navegacion y ajustes.',
                      ru: 'Применяется сразу во всей навигации и настройках.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: state.uiLanguageSelection,
                    decoration: InputDecoration(
                      labelText: pickUiText(
                        i18n,
                        zh: '语言',
                        en: 'Language',
                        ja: '言語',
                        de: 'Sprache',
                        fr: 'Langue',
                        es: 'Idioma',
                        ru: 'Язык',
                      ),
                    ),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: SettingsService.uiLanguageSystem,
                        child: Text(
                          pickUiText(
                            i18n,
                            zh: '跟随系统',
                            en: 'Follow system',
                            ja: 'システムに従う',
                            de: 'Systemsprache folgen',
                            fr: 'Suivre le systeme',
                            es: 'Seguir al sistema',
                            ru: 'Следовать системе',
                          ),
                        ),
                      ),
                      ...AppI18n.supportedLanguages.map(
                        (code) => DropdownMenuItem<String>(
                          value: code,
                          child: Text(i18n.languageName(code)),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null || value.trim().isEmpty) return;
                      if (value == SettingsService.uiLanguageSystem) {
                        state.setUiLanguageFollowSystem();
                        return;
                      }
                      state.setUiLanguage(value);
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    state.uiLanguageFollowsSystem
                        ? pickUiText(
                            i18n,
                            zh: '当前正在跟随系统语言：$currentLanguageName',
                            en: 'Currently following system language: $currentLanguageName',
                            ja: '現在はシステム言語に従っています: $currentLanguageName',
                            de: 'Aktuell wird die Systemsprache verwendet: $currentLanguageName',
                            fr: 'Langue systeme actuellement utilisee : $currentLanguageName',
                            es: 'Actualmente sigue el idioma del sistema: $currentLanguageName',
                            ru: 'Сейчас используется язык системы: $currentLanguageName',
                          )
                        : pickUiText(
                            i18n,
                            zh: '当前已固定为手动语言：$currentLanguageName',
                            en: 'Manual language is fixed to: $currentLanguageName',
                            ja: '現在は手動で次の言語に固定されています: $currentLanguageName',
                            de: 'Manuell ausgewahlte Sprache: $currentLanguageName',
                            fr: 'Langue manuelle actuellement definie : $currentLanguageName',
                            es: 'Idioma manual fijado actualmente: $currentLanguageName',
                            ru: 'Сейчас вручную выбран язык: $currentLanguageName',
                          ),
                    style: Theme.of(context).textTheme.bodySmall,
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
                    title: pickUiText(i18n, zh: '天气概览', en: 'Weather glance'),
                    subtitle: pickUiText(
                      i18n,
                      zh: '在播放页右上角显示当前城市级天气，不申请定位权限。',
                      en: 'Show approximate city weather on the Play page without requesting GPS permission.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: state.weatherEnabled,
                    title: Text(
                      pickUiText(i18n, zh: '显示天气', en: 'Show weather'),
                    ),
                    subtitle: Text(
                      state.weatherEnabled
                          ? pickUiText(
                              i18n,
                              zh: '已启用，点击天气图标可查看详情并刷新。',
                              en: 'Enabled. Tap the weather icon for details or refresh.',
                            )
                          : pickUiText(
                              i18n,
                              zh: '关闭后不会发起城市与天气请求。',
                              en: 'When off, the app skips city and weather requests.',
                            ),
                    ),
                    onChanged: state.setWeatherEnabled,
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
                    title: pickUiText(i18n, zh: '启动主页', en: 'Startup page'),
                    subtitle: pickUiText(
                      i18n,
                      zh: '设置应用启动后默认打开的主页面。',
                      en: 'Choose which main tab opens after the app launches.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<AppHomeTab>(
                    initialValue: state.startupPage,
                    decoration: InputDecoration(
                      labelText: pickUiText(
                        i18n,
                        zh: '默认页面',
                        en: 'Default page',
                      ),
                    ),
                    items: AppHomeTab.values
                        .map(
                          (tab) => DropdownMenuItem<AppHomeTab>(
                            value: tab,
                            child: Text(appHomeTabLabel(i18n, tab)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      state.setStartupPage(value);
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '当前默认进入：${appHomeTabLabel(i18n, state.startupPage)}',
                      en: 'Current startup tab: ${appHomeTabLabel(i18n, state.startupPage)}',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (state.startupPage == AppHomeTab.study) ...<Widget>[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<StudyStartupTab>(
                      initialValue: state.studyStartupTab,
                      decoration: InputDecoration(
                        labelText: pickUiText(
                          i18n,
                          zh: '学习页默认子页',
                          en: 'Study default section',
                        ),
                      ),
                      items: StudyStartupTab.values
                          .map(
                            (tab) => DropdownMenuItem<StudyStartupTab>(
                              value: tab,
                              child: Text(studyStartupTabLabel(i18n, tab)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        state.setStudyStartupTab(value);
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pickUiText(
                        i18n,
                        zh: '当启动页为学习时，将优先打开：${studyStartupTabLabel(i18n, state.studyStartupTab)}',
                        en: 'When Study is the startup page, it will open ${studyStartupTabLabel(i18n, state.studyStartupTab)} first.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (state.startupPage == AppHomeTab.focus) ...<Widget>[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<FocusStartupTab>(
                      initialValue: state.focusStartupTab,
                      decoration: InputDecoration(
                        labelText: pickUiText(
                          i18n,
                          zh: '专注默认子页签',
                          en: 'Focus default section',
                        ),
                      ),
                      items: FocusStartupTab.values
                          .map(
                            (tab) => DropdownMenuItem<FocusStartupTab>(
                              value: tab,
                              child: Text(focusStartupTabLabel(i18n, tab)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        state.setFocusStartupTab(value);
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pickUiText(
                        i18n,
                        zh: '当主入口为专注/放松时，将优先打开：${focusStartupTabLabel(i18n, state.focusStartupTab)}',
                        en: 'When Focus is the startup page, it will open ${focusStartupTabLabel(i18n, state.focusStartupTab)} first.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
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
}

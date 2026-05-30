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
          i18n.t(
            'inline.ui.pages.language_settings_page.language_settings_93b127',
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
                    title: i18n.t(
                      'inline.ui.pages.language_settings_page.interface_language_6f4732',
                    ),
                    subtitle: i18n.t(
                      'inline.ui.pages.language_settings_page.applies_immediately_across_navigation_and_settings_2fb1f7',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: state.uiLanguageSelection,
                    decoration: InputDecoration(labelText: i18n.t('language')),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: SettingsService.uiLanguageSystem,
                        child: Text(
                          i18n.t(
                            'inline.ui.pages.language_settings_page.follow_system_ef2221',
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
                        ? i18n.t(
                            'inline.ui.pages.language_settings_page.currently_following_system_language_currentlanguagename_c8b46b',
                            params: <String, Object?>{
                              'currentLanguageName': currentLanguageName,
                            },
                          )
                        : i18n.t(
                            'inline.ui.pages.language_settings_page.manual_language_is_fixed_to_currentlanguagename_e6aac4',
                            params: <String, Object?>{
                              'currentLanguageName': currentLanguageName,
                            },
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
                    title: i18n.t(
                      'inline.ui.pages.language_settings_page.weather_glance_d36e35',
                    ),
                    subtitle: i18n.t(
                      'inline.ui.pages.language_settings_page.show_approximate_city_weather_on_the_play_page_without_r_6a934a',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: state.weatherEnabled,
                    title: Text(
                      i18n.t(
                        'inline.ui.pages.language_settings_page.show_weather_b2a20b',
                      ),
                    ),
                    subtitle: Text(
                      state.weatherEnabled
                          ? i18n.t(
                              'inline.ui.pages.language_settings_page.enabled_tap_the_weather_icon_for_details_or_refresh_989e91',
                            )
                          : i18n.t(
                              'inline.ui.pages.language_settings_page.when_off_the_app_skips_city_and_weather_requests_93bf84',
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
                    title: i18n.t(
                      'inline.ui.pages.language_settings_page.startup_page_2f0ef5',
                    ),
                    subtitle: i18n.t(
                      'inline.ui.pages.language_settings_page.choose_which_main_tab_opens_after_the_app_launches_94fbec',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<AppHomeTab>(
                    initialValue: state.startupPage,
                    decoration: InputDecoration(
                      labelText: i18n.t(
                        'inline.ui.pages.language_settings_page.default_page_28fa07',
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
                    i18n.t(
                      'inline.ui.pages.language_settings_page.current_startup_tab_apphometablabel_i18n_state_startuppa_3dfb72',
                      params: <String, Object?>{
                        'appHomeTabLabelStartupPage': appHomeTabLabel(
                          i18n,
                          state.startupPage,
                        ),
                      },
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (state.startupPage == AppHomeTab.study) ...<Widget>[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<StudyStartupTab>(
                      initialValue: state.studyStartupTab,
                      decoration: InputDecoration(
                        labelText: i18n.t(
                          'inline.ui.pages.language_settings_page.study_default_section_5f732c',
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
                      i18n.t(
                        'inline.ui.pages.language_settings_page.when_study_is_the_startup_page_it_will_open_studystartup_6c240e',
                        params: <String, Object?>{
                          'studyStartupTabLabelStudyStartupTab':
                              studyStartupTabLabel(i18n, state.studyStartupTab),
                        },
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (state.startupPage == AppHomeTab.focus) ...<Widget>[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<FocusStartupTab>(
                      initialValue: state.focusStartupTab,
                      decoration: InputDecoration(
                        labelText: i18n.t(
                          'inline.ui.pages.language_settings_page.focus_default_section_ec0f69',
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
                      i18n.t(
                        'inline.ui.pages.language_settings_page.when_focus_is_the_startup_page_it_will_open_focusstartup_fb217c',
                        params: <String, Object?>{
                          'focusStartupTabLabelFocusStartupTab':
                              focusStartupTabLabel(i18n, state.focusStartupTab),
                        },
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

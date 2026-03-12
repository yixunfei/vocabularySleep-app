import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../services/settings_service.dart';
import '../../state/app_state.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final currentLanguageName = i18n.languageName(state.uiLanguage);

    return Scaffold(
      appBar: AppBar(
        title: Text(pickUiText(i18n, zh: '语言与通用', en: 'Language settings')),
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
                    ),
                    subtitle: pickUiText(
                      i18n,
                      zh: '立即生效，覆盖导航、设置和练习页文案。',
                      en: 'Applies immediately across navigation and settings.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: state.uiLanguageSelection,
                    decoration: InputDecoration(
                      labelText: pickUiText(i18n, zh: '语言', en: 'Language'),
                    ),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: SettingsService.uiLanguageSystem,
                        child: Text(
                          pickUiText(i18n, zh: '跟随系统', en: 'Follow system'),
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
                          )
                        : pickUiText(
                            i18n,
                            zh: '当前已固定为手动语言：$currentLanguageName',
                            en: 'Manual language is fixed to: $currentLanguageName',
                          ),
                    style: Theme.of(context).textTheme.bodySmall,
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

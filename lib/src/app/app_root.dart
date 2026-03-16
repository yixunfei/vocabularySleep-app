import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../i18n/app_i18n.dart';
import '../state/app_state.dart';
import '../ui/app_shell.dart';
import '../ui/theme/app_theme.dart';

class VocabularySleepApp extends StatelessWidget {
  const VocabularySleepApp({super.key});

  static final List<Locale> _supportedLocales = AppI18n.supportedLanguages
      .map((code) => Locale(code))
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final i18n = AppI18n(state.uiLanguage);
        return MaterialApp(
          title: i18n.t('appTitle'),
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(state.config.appearance),
          locale: Locale(state.uiLanguage),
          supportedLocales: _supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AppShell(),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../i18n/app_i18n.dart';
import '../models/play_config.dart';
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
    final uiLanguage = context.select<AppState, String>(
      (state) => state.uiLanguage,
    );
    final appearance = context.select<AppState, AppearanceConfig>(
      (state) => state.config.appearance,
    );
    final i18n = AppI18n(uiLanguage);
    return MaterialApp(
      title: i18n.t('appTitle'),
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(appearance),
      locale: Locale(uiLanguage),
      supportedLocales: _supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppShell(),
    );
  }
}

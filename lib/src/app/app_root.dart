import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/app_i18n.dart';
import '../models/play_config.dart';
import '../state/app_state_provider.dart';
import '../ui/app_shell.dart';
import '../ui/theme/app_theme.dart';

class VocabularySleepApp extends ConsumerWidget {
  const VocabularySleepApp({super.key});

  static final List<Locale> _supportedLocales = AppI18n.supportedLanguages
      .map((code) => Locale(code))
      .toList(growable: false);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rootState = ref.watch(
      appStateProvider.select(
        (state) =>
            (uiLanguage: state.uiLanguage, appearance: state.config.appearance),
      ),
    );
    final uiLanguage = rootState.uiLanguage;
    final AppearanceConfig appearance = rootState.appearance;
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

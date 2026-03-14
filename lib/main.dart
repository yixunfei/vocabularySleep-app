import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'src/i18n/app_i18n.dart';
import 'src/services/ambient_service.dart';
import 'src/services/app_log_service.dart';
import 'src/services/asr_service.dart';
import 'src/services/database_service.dart';
import 'src/services/focus_service.dart';
import 'src/services/playback_service.dart';
import 'src/services/reminder_service.dart';
import 'src/services/settings_service.dart';
import 'src/services/tts_service.dart';
import 'src/services/wordbook_import_service.dart';
import 'src/state/app_state.dart';
import 'src/ui/app_shell.dart';
import 'src/ui/theme/app_theme.dart';

void main() {
  final logger = AppLogService.instance;

  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      unawaited(logger.init());

      FlutterError.onError = (FlutterErrorDetails details) {
        if (_isKnownBenignFrameworkIssue(details.exception)) {
          logger.w(
            'flutter',
            'ignored known framework issue',
            data: <String, Object?>{'error': '${details.exception}'},
          );
          return;
        }
        logger.e(
          'flutter',
          'uncaught Flutter framework error',
          error: details.exception,
          stackTrace: details.stack,
        );
        FlutterError.presentError(details);
      };

      PlatformDispatcher.instance.onError =
          (Object error, StackTrace stackTrace) {
            if (_isKnownBenignFrameworkIssue(error)) {
              logger.w(
                'platform',
                'ignored known platform issue',
                data: <String, Object?>{'error': '$error'},
              );
              return true;
            }
            logger.e(
              'platform',
              'uncaught platform error',
              error: error,
              stackTrace: stackTrace,
            );
            return false;
          };

      _runApp();
    },
    (Object error, StackTrace stackTrace) {
      if (_isKnownBenignFrameworkIssue(error)) {
        logger.w(
          'zone',
          'ignored known zone issue',
          data: <String, Object?>{'error': '$error'},
        );
        return;
      }
      logger.e(
        'zone',
        'uncaught zone error',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}

bool _isKnownBenignFrameworkIssue(Object error) {
  final message = '$error';
  return message.contains(
        'Attempted to send a key down event when no keys are in keysPressed',
      ) ||
      message.contains('Unable to parse JSON message:\nThe document is empty.');
}

void _runApp() {
  final importer = WordbookImportService();
  final database = AppDatabaseService(importer);
  final settings = SettingsService(database);
  final tts = TtsService();
  final playback = PlaybackService(tts);
  final ambient = AmbientService();
  final asr = AsrService();
  final reminder = PlatformReminderService();
  final focusService = FocusService(
    database,
    settings: settings,
    ambient: ambient,
    reminder: reminder,
    tts: tts,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>(
          create: (_) => AppState(
            database: database,
            settings: settings,
            playback: playback,
            ambient: ambient,
            asr: asr,
            focusService: focusService,
          ),
        ),
      ],
      child: const VocabularySleepApp(),
    ),
  );
}

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

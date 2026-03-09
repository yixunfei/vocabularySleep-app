import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/i18n/app_i18n.dart';
import 'src/services/ambient_service.dart';
import 'src/services/app_log_service.dart';
import 'src/services/asr_service.dart';
import 'src/services/database_service.dart';
import 'src/services/playback_service.dart';
import 'src/services/settings_service.dart';
import 'src/services/tts_service.dart';
import 'src/services/wordbook_import_service.dart';
import 'src/state/app_state.dart';
import 'src/ui/home_page.dart';
import 'src/ui/legacy_style.dart';

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
          ),
        ),
      ],
      child: const VocabularySleepApp(),
    ),
  );
}

class VocabularySleepApp extends StatelessWidget {
  const VocabularySleepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final i18n = AppI18n(state.uiLanguage);
        return MaterialApp(
          title: i18n.t('appTitle'),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: LegacyStyle.primary,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.transparent,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
            ),
            tabBarTheme: TabBarThemeData(
              labelColor: LegacyStyle.primary,
              unselectedLabelColor: LegacyStyle.textSecondary,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: LegacyStyle.primary.withValues(alpha: 0.1),
              ),
            ),
            dividerColor: LegacyStyle.border,
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                elevation: 0,
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: BorderSide(color: LegacyStyle.border, width: 1.15),
              ),
            ),
            chipTheme: ChipThemeData(
              selectedColor: LegacyStyle.primary.withValues(alpha: 0.16),
              side: BorderSide(color: LegacyStyle.border, width: 1.1),
            ),
            listTileTheme: const ListTileThemeData(
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minVerticalPadding: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
            ),
            cardTheme: CardThemeData(
              color: LegacyStyle.surface.withValues(alpha: 0.92),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: LegacyStyle.border, width: 1.1),
              ),
            ),
            scrollbarTheme: ScrollbarThemeData(
              thumbColor: WidgetStatePropertyAll(
                LegacyStyle.primary.withValues(alpha: 0.5),
              ),
              trackColor: WidgetStatePropertyAll(
                LegacyStyle.primary.withValues(alpha: 0.1),
              ),
              trackBorderColor: WidgetStatePropertyAll(Colors.transparent),
              radius: const Radius.circular(10),
              thickness: const WidgetStatePropertyAll(10),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: LegacyStyle.surface.withValues(alpha: 0.9),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: LegacyStyle.border, width: 1.1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: LegacyStyle.border, width: 1.1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: LegacyStyle.primary, width: 1.6),
              ),
            ),
          ),
          home: const HomePage(),
        );
      },
    );
  }
}

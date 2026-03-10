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

TextStyle? _scaleTextStyle(TextStyle? style, double scale) {
  if (style == null) return null;
  final baseSize = style.fontSize;
  if (baseSize == null) return style;
  return style.copyWith(fontSize: baseSize * scale);
}

TextTheme _scaleTextTheme(TextTheme base, double scale) {
  return base.copyWith(
    displayLarge: _scaleTextStyle(base.displayLarge, scale),
    displayMedium: _scaleTextStyle(base.displayMedium, scale),
    displaySmall: _scaleTextStyle(base.displaySmall, scale),
    headlineLarge: _scaleTextStyle(base.headlineLarge, scale),
    headlineMedium: _scaleTextStyle(base.headlineMedium, scale),
    headlineSmall: _scaleTextStyle(base.headlineSmall, scale),
    titleLarge: _scaleTextStyle(base.titleLarge, scale),
    titleMedium: _scaleTextStyle(base.titleMedium, scale),
    titleSmall: _scaleTextStyle(base.titleSmall, scale),
    bodyLarge: _scaleTextStyle(base.bodyLarge, scale),
    bodyMedium: _scaleTextStyle(base.bodyMedium, scale),
    bodySmall: _scaleTextStyle(base.bodySmall, scale),
    labelLarge: _scaleTextStyle(base.labelLarge, scale),
    labelMedium: _scaleTextStyle(base.labelMedium, scale),
    labelSmall: _scaleTextStyle(base.labelSmall, scale),
  );
}

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
        LegacyStyle.applyAppearance(state.config.appearance);
        final i18n = AppI18n(state.uiLanguage);
        final appearance = state.config.appearance;
        final compact = appearance.compactLayout;
        final inputVerticalPadding = compact ? 14.0 : 18.0;
        final buttonVerticalPadding = compact ? 10.0 : 14.0;
        final fontScale = appearance.normalizedFontScale;
        final titleWeight = LegacyStyle.titleFontWeight;
        final bodyWeight = LegacyStyle.bodyFontWeight;

        final baseTheme = ThemeData(
          useMaterial3: true,
          visualDensity: compact
              ? VisualDensity.compact
              : VisualDensity.standard,
          colorScheme: ColorScheme.fromSeed(
            seedColor: LegacyStyle.primary,
            brightness: LegacyStyle.isDark ? Brightness.dark : Brightness.light,
          ),
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: AppBarTheme(
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
              minimumSize: Size(0, compact ? 42 : 46),
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: buttonVerticalPadding,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(compact ? 12 : 14),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              minimumSize: Size(0, compact ? 40 : 44),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(compact ? 12 : 14),
              ),
              side: BorderSide(color: LegacyStyle.border, width: 1.15),
            ),
          ),
          chipTheme: ChipThemeData(
            selectedColor: LegacyStyle.primary.withValues(alpha: 0.16),
            side: BorderSide(color: LegacyStyle.border, width: 1.1),
          ),
          listTileTheme: ListTileThemeData(
            contentPadding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 14,
              vertical: compact ? 6 : 8,
            ),
            minVerticalPadding: compact ? 6 : 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(compact ? 12 : 14),
              ),
            ),
          ),
          cardTheme: CardThemeData(
            color: LegacyStyle.surface.withValues(alpha: 0.92),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(compact ? 14 : 16),
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
            thickness: WidgetStatePropertyAll(compact ? 8 : 10),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: LegacyStyle.surface.withValues(alpha: 0.9),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: inputVerticalPadding,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(compact ? 12 : 14),
              borderSide: BorderSide(color: LegacyStyle.border, width: 1.1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(compact ? 12 : 14),
              borderSide: BorderSide(color: LegacyStyle.border, width: 1.1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(compact ? 12 : 14),
              borderSide: BorderSide(color: LegacyStyle.primary, width: 1.6),
            ),
          ),
        );

        final themedTextBase = baseTheme.textTheme.apply(
          fontFamily: LegacyStyle.fontFamily,
          bodyColor: LegacyStyle.textPrimary,
          displayColor: LegacyStyle.textPrimary,
        );
        final scaledText = _scaleTextTheme(themedTextBase, fontScale);
        final themedText = scaledText.copyWith(
          titleLarge: scaledText.titleLarge?.copyWith(fontWeight: titleWeight),
          titleMedium: scaledText.titleMedium?.copyWith(
            fontWeight: titleWeight,
          ),
          titleSmall: scaledText.titleSmall?.copyWith(fontWeight: titleWeight),
          headlineSmall: scaledText.headlineSmall?.copyWith(
            fontWeight: titleWeight,
          ),
          headlineMedium: scaledText.headlineMedium?.copyWith(
            fontWeight: titleWeight,
          ),
          bodyLarge: scaledText.bodyLarge?.copyWith(fontWeight: bodyWeight),
          bodyMedium: scaledText.bodyMedium?.copyWith(fontWeight: bodyWeight),
          bodySmall: scaledText.bodySmall?.copyWith(fontWeight: bodyWeight),
        );
        return MaterialApp(
          title: i18n.t('appTitle'),
          debugShowCheckedModeBanner: false,
          theme: baseTheme.copyWith(
            textTheme: themedText,
            primaryTextTheme: themedText,
          ),
          home: const HomePage(),
        );
      },
    );
  }
}

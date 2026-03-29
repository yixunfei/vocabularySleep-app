import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../services/ambient_service.dart';
import '../services/asr_service.dart';
import '../services/built_in_wordbook_source.dart';
import '../services/cstcloud_resource_cache_service.dart';
import '../services/cstcloud_resource_prewarm_service.dart';
import '../services/database_service.dart';
import '../services/focus_service.dart';
import '../services/playback_service.dart';
import '../services/reminder_service.dart';
import '../services/settings_service.dart';
import '../services/todo_reminder_service.dart';
import '../services/tts_service.dart';
import '../services/wordbook_import_service.dart';
import '../state/app_state.dart';

/// Centralizes long-lived services so app startup wiring stays in one place.
class AppDependencies {
  AppDependencies._({
    required this.database,
    required this.cstCloudResourceCache,
    required this.cstCloudResourcePrewarm,
    required this.settings,
    required this.playback,
    required this.ambient,
    required this.asr,
    required this.focusService,
  });

  final AppDatabaseService database;
  final CstCloudResourceCacheService cstCloudResourceCache;
  final CstCloudResourcePrewarmService cstCloudResourcePrewarm;
  final SettingsService settings;
  final PlaybackService playback;
  final AmbientService ambient;
  final AsrService asr;
  final FocusService focusService;

  factory AppDependencies.create() {
    final importer = WordbookImportService();
    final cstCloudResourceCache = CstCloudResourceCacheService();
    final cstCloudResourcePrewarm = CstCloudResourcePrewarmService(
      cstCloudResourceCache,
    );
    final database = AppDatabaseService(
      importer,
      builtInWordbookSource: CstCloudBuiltInWordbookSource(
        cstCloudResourceCache,
        fallback: const AssetBuiltInWordbookSource(),
      ),
    );
    final settings = SettingsService(database);
    final tts = TtsService();
    final playback = PlaybackService(tts);
    final ambient = AmbientService(resourceCache: cstCloudResourceCache);
    final asr = AsrService();
    final reminder = PlatformReminderService();
    final todoReminder = PlatformTodoReminderService();
    final focusService = FocusService(
      database,
      settings: settings,
      ambient: ambient,
      reminder: reminder,
      todoReminder: todoReminder,
      tts: tts,
    );

    return AppDependencies._(
      database: database,
      cstCloudResourceCache: cstCloudResourceCache,
      cstCloudResourcePrewarm: cstCloudResourcePrewarm,
      settings: settings,
      playback: playback,
      ambient: ambient,
      asr: asr,
      focusService: focusService,
    );
  }

  Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        Provider<CstCloudResourceCacheService>.value(
          value: cstCloudResourceCache,
        ),
        ChangeNotifierProvider<AppState>(
          create: (_) => AppState(
            database: database,
            settings: settings,
            playback: playback,
            ambient: ambient,
            asr: asr,
            focusService: focusService,
            remoteResourcePrewarm: cstCloudResourcePrewarm,
          ),
        ),
      ],
      child: child,
    );
  }
}

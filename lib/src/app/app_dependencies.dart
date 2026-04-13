import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Override;
import 'package:provider/provider.dart';

import '../repositories/repositories.dart';
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
import '../state/app_state_provider.dart';

/// Centralizes long-lived services so app startup wiring stays in one place.
class AppDependencies {
  AppDependencies._({
    required this.database,
    required this.settingsStoreRepository,
    required this.wordbookRepository,
    required this.practiceRepository,
    required this.ambientRepository,
    required this.focusRepository,
    required this.cstCloudResourceCache,
    required this.cstCloudResourcePrewarm,
    required this.settings,
    required this.playback,
    required this.ambient,
    required this.asr,
    required this.focusService,
    required this.appState,
  });

  final AppDatabaseService database;
  final SettingsStoreRepository settingsStoreRepository;
  final WordbookRepository wordbookRepository;
  final PracticeRepository practiceRepository;
  final AmbientRepository ambientRepository;
  final FocusRepository focusRepository;
  final CstCloudResourceCacheService cstCloudResourceCache;
  final CstCloudResourcePrewarmService cstCloudResourcePrewarm;
  final SettingsService settings;
  final PlaybackService playback;
  final AmbientService ambient;
  final AsrService asr;
  final FocusService focusService;
  final AppState appState;

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
    final settingsStoreRepository = DatabaseSettingsStoreRepository(database);
    final settings = SettingsService.fromRepository(settingsStoreRepository);
    final wordbookRepository = DatabaseWordbookRepository(database);
    final practiceRepository = DatabasePracticeRepository(database);
    final ambientRepository = DatabaseAmbientRepository(database);
    final focusRepository = DatabaseFocusRepository(database);
    final tts = TtsService();
    final playback = PlaybackService(tts);
    final ambient = AmbientService(resourceCache: cstCloudResourceCache);
    final asr = AsrService();
    final reminder = PlatformReminderService();
    final todoReminder = PlatformTodoReminderService();
    final focusService = FocusService(
      database,
      repository: focusRepository,
      settings: settings,
      ambient: ambient,
      reminder: reminder,
      todoReminder: todoReminder,
      tts: tts,
    );
    final appState = AppState(
      database: database,
      settings: settings,
      playback: playback,
      ambient: ambient,
      asr: asr,
      focusService: focusService,
      wordbookRepository: wordbookRepository,
      practiceRepository: practiceRepository,
      ambientRepository: ambientRepository,
      remoteResourcePrewarm: cstCloudResourcePrewarm,
    );

    return AppDependencies._(
      database: database,
      settingsStoreRepository: settingsStoreRepository,
      wordbookRepository: wordbookRepository,
      practiceRepository: practiceRepository,
      ambientRepository: ambientRepository,
      focusRepository: focusRepository,
      cstCloudResourceCache: cstCloudResourceCache,
      cstCloudResourcePrewarm: cstCloudResourcePrewarm,
      settings: settings,
      playback: playback,
      ambient: ambient,
      asr: asr,
      focusService: focusService,
      appState: appState,
    );
  }

  List<Override> get riverpodOverrides => <Override>[
    appStateProvider.overrideWith((ref) => appState),
    cstCloudResourceCacheProvider.overrideWithValue(cstCloudResourceCache),
  ];

  Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        Provider<CstCloudResourceCacheService>.value(
          value: cstCloudResourceCache,
        ),
        ChangeNotifierProvider<AppState>.value(value: appState),
      ],
      child: child,
    );
  }
}

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/app_home_tab.dart';
import 'package:vocabulary_sleep_app/src/models/focus_startup_tab.dart';
import 'package:vocabulary_sleep_app/src/models/settings_dto.dart';
import 'package:vocabulary_sleep_app/src/models/weather_snapshot.dart';
import 'package:vocabulary_sleep_app/src/models/word_entry.dart';
import 'package:vocabulary_sleep_app/src/models/word_field.dart';
import 'package:vocabulary_sleep_app/src/models/word_memory_progress.dart';
import 'package:vocabulary_sleep_app/src/models/wordbook.dart';
import 'package:vocabulary_sleep_app/src/services/app_log_service.dart';
import 'package:vocabulary_sleep_app/src/services/database_service.dart';
import 'package:vocabulary_sleep_app/src/services/settings_service.dart';
import 'package:vocabulary_sleep_app/src/services/weather_service.dart';
import 'package:vocabulary_sleep_app/src/services/wordbook_import_service.dart';
import 'package:vocabulary_sleep_app/src/state/app_state.dart';
import 'test_support/app_state_test_doubles.dart';

class _MemoryDatabaseService extends AppDatabaseService {
  _MemoryDatabaseService({
    this.wordbooks = const <Wordbook>[],
    Map<int, List<WordEntry>>? wordsByWordbookId,
  }) : _wordsByWordbookId = wordsByWordbookId ?? <int, List<WordEntry>>{},
       super(WordbookImportService());

  final List<Wordbook> wordbooks;
  final Map<int, List<WordEntry>> _wordsByWordbookId;
  final Map<String, String> _settings = <String, String>{};
  int initCalls = 0;

  @override
  Future<void> init() async {
    initCalls += 1;
  }

  @override
  String? getSetting(String key) => _settings[key];

  @override
  void setSetting(String key, String value) {
    _settings[key] = value;
  }

  @override
  List<Wordbook> getWordbooks() => List<Wordbook>.from(wordbooks);

  @override
  List<WordEntry> getWords(
    int wordbookId, {
    int limit = 100000,
    int offset = 0,
  }) {
    final words = _wordsByWordbookId[wordbookId] ?? const <WordEntry>[];
    return words.skip(offset).take(limit).toList(growable: false);
  }

  @override
  Map<int, WordMemoryProgress> getWordMemoryProgressByWordIds(
    Iterable<int> wordIds,
  ) {
    return const <int, WordMemoryProgress>{};
  }

  @override
  List<DownloadedAmbientSoundInfo> getDownloadedAmbientSounds() {
    return const <DownloadedAmbientSoundInfo>[];
  }

  @override
  List<String> getWordTexts(
    int wordbookId, {
    int limit = 100000,
    int offset = 0,
  }) {
    final words = _wordsByWordbookId[wordbookId] ?? const <WordEntry>[];
    return words
        .skip(offset)
        .take(limit)
        .map((item) => item.word)
        .toList(growable: false);
  }
}

class _FakeWeatherService extends WeatherService {
  int fetchCount = 0;

  @override
  Future<WeatherSnapshot> fetchCurrentWeather() async {
    fetchCount += 1;
    return WeatherSnapshot(
      city: 'Init City $fetchCount',
      countryCode: 'CN',
      temperatureCelsius: 20,
      apparentTemperatureCelsius: 19,
      windSpeedKph: 2,
      weatherCode: 1,
      isDay: true,
      fetchedAt: DateTime.now(),
      forecastDays: <WeatherForecastDay>[
        WeatherForecastDay(
          date: DateTime.now(),
          weatherCode: 1,
          maxTemperatureCelsius: 23,
          minTemperatureCelsius: 15,
        ),
      ],
    );
  }
}

WordEntry _word(int id, String word) {
  return WordEntry(
    id: id,
    wordbookId: 3,
    word: word,
    fields: const <WordFieldItem>[],
  );
}

String _dateKey(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('app_state_init_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          return tempDir.path;
        });
    AppLogService.instance.resetForTest();
  });

  tearDown(() async {
    await AppLogService.instance.flushForTest();
    AppLogService.instance.resetForTest();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'init restores startup settings and selects the primary wordbook',
    () async {
      final database = _MemoryDatabaseService(
        wordbooks: <Wordbook>[
          Wordbook(
            id: 1,
            name: 'Task',
            path: 'builtin:task',
            wordCount: 1,
            createdAt: DateTime(2026, 3, 16),
          ),
          Wordbook(
            id: 2,
            name: 'Favorites',
            path: 'builtin:favorites',
            wordCount: 1,
            createdAt: DateTime(2026, 3, 16),
          ),
          Wordbook(
            id: 3,
            name: 'Core',
            path: 'custom:core',
            wordCount: 2,
            createdAt: DateTime(2026, 3, 16),
          ),
        ],
        wordsByWordbookId: <int, List<WordEntry>>{
          1: <WordEntry>[_word(11, 'Plan')],
          2: <WordEntry>[_word(12, 'Star')],
          3: <WordEntry>[_word(1, 'Alpha'), _word(2, 'Beta')],
        },
      );
      final settings = SettingsService(database);
      final playback = TrackingPlaybackService();
      final focus = StubFocusService(database, settings: settings);
      final weather = _FakeWeatherService();

      settings.saveStartupPage(AppHomeTab.focus);
      settings.saveFocusStartupTab(FocusStartupTab.timer);
      settings.saveWeatherEnabled(true);
      settings.saveStartupTodoPromptEnabled(true);
      settings.saveStartupTodoPromptSuppressedDate(_dateKey(DateTime.now()));
      settings.saveRememberedWords(<String>{'Alpha'});
      settings.saveTestModeState(
        const TestModeState(enabled: true, revealed: true, hintRevealed: false),
      );

      final state = AppState(
        database: database,
        settings: settings,
        playback: playback,
        ambient: StubAmbientService(),
        asr: StubAsrService(),
        focusService: focus,
        weatherService: weather,
      );

      await state.init();
      await pumpEventQueue();

      expect(database.initCalls, 1);
      expect(focus.initCalls, 1);
      expect(playback.updateCalls, 1);
      expect(playback.lastConfig, isNotNull);
      expect(state.initialized, isTrue);
      expect(state.startupPage, AppHomeTab.focus);
      expect(state.focusStartupTab, FocusStartupTab.timer);
      expect(state.weatherEnabled, isTrue);
      expect(state.startupTodoPromptEnabled, isTrue);
      expect(state.shouldShowStartupTodoPromptToday, isFalse);
      expect(state.testModeEnabled, isTrue);
      expect(state.testModeRevealed, isTrue);
      expect(state.testModeHintRevealed, isFalse);
      expect(state.selectedWordbook?.id, 3);
      expect(
        state.words.map((item) => item.word).toList(growable: false),
        <String>['Alpha', 'Beta'],
      );
      expect(state.currentWord?.word, 'Alpha');
      expect(state.favorites, <String>{'Star'});
      expect(state.taskWords, <String>{'Plan'});
      expect(
        state.recentRememberedWordEntries
            .map((item) => item.word)
            .toList(growable: false),
        <String>['Alpha'],
      );
      expect(weather.fetchCount, 1);
      expect(state.weatherSnapshot?.city, 'Init City 1');
    },
  );

  test('resetUserData auto-initializes database before reset flow', () async {
    final database = AppDatabaseService(WordbookImportService());
    final settings = SettingsService(database);
    final state = AppState(
      database: database,
      settings: settings,
      playback: TrackingPlaybackService(),
      ambient: StubAmbientService(),
      asr: StubAsrService(),
      focusService: StubFocusService(database, settings: settings),
    );
    addTearDown(database.dispose);

    final success = await state.resetUserData();

    expect(success, isTrue);
    expect(state.error, isNull);
    expect(state.lastBackupPath, isNotNull);
    expect(await File(state.lastBackupPath!).exists(), isTrue);
    expect(
      database.getWordbooks().map((item) => item.path).toSet(),
      containsAll(<String>{'builtin:favorites', 'builtin:task'}),
    );
  });

  test(
    'init restores last playback progress for the selected wordbook',
    () async {
      final database = AppDatabaseService(WordbookImportService());
      await database.init();
      addTearDown(database.dispose);

      await database.importWordbook(
        sourcePath: 'custom:test_playback_progress_restore',
        name: 'Playback restore test',
        entries: const <WordEntryPayload>[
          WordEntryPayload(
            word: 'Alpha',
            fields: <WordFieldItem>[
              WordFieldItem(key: 'meaning', label: 'Meaning', value: 'First'),
            ],
            rawContent: 'First',
          ),
          WordEntryPayload(
            word: 'Bravo',
            fields: <WordFieldItem>[
              WordFieldItem(key: 'meaning', label: 'Meaning', value: 'Second'),
            ],
            rawContent: 'Second',
          ),
        ],
      );

      final initialSettings = SettingsService(database);
      final initialState = AppState(
        database: database,
        settings: initialSettings,
        playback: TrackingPlaybackService(),
        ambient: StubAmbientService(),
        asr: StubAsrService(),
        focusService: StubFocusService(database, settings: initialSettings),
      );
      await initialState.init();
      initialState.selectWordEntry(initialState.words.last);
      initialState.rememberPlaybackProgress(initialState.words.last);

      final restoredSettings = SettingsService(database);
      final restoredState = AppState(
        database: database,
        settings: restoredSettings,
        playback: TrackingPlaybackService(),
        ambient: StubAmbientService(),
        asr: StubAsrService(),
        focusService: StubFocusService(database, settings: restoredSettings),
      );

      await restoredState.init();

      expect(
        restoredState.selectedWordbook?.path,
        'custom:test_playback_progress_restore',
      );
      expect(restoredState.currentWord?.word, 'Bravo');
    },
  );

  test(
    'init resets stale practice day counters but keeps totals and cursors',
    () async {
      final database = _MemoryDatabaseService();
      final settings = SettingsService(database);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      settings.savePracticeDashboard(
        PracticeDashboardState(
          date: _dateKey(yesterday),
          todaySessions: 3,
          todayReviewed: 12,
          todayRemembered: 8,
          totalSessions: 7,
          totalReviewed: 28,
          totalRemembered: 19,
          lastSessionTitle: 'Yesterday sprint',
          rememberedWords: const <String>['Alpha'],
          weakWords: const <String>['Beta'],
          launchCursors: const <String, int>{'practice:warmup': 2},
          trackedEntries: const <PracticeTrackedEntrySnapshot>[
            PracticeTrackedEntrySnapshot(
              id: 2,
              wordbookId: 1,
              word: 'Beta',
              meaning: 'Second letter',
              rawContent: '',
            ),
          ],
        ),
      );

      final state = AppState(
        database: database,
        settings: settings,
        playback: TrackingPlaybackService(),
        ambient: StubAmbientService(),
        asr: StubAsrService(),
        focusService: StubFocusService(database, settings: settings),
      );

      await state.init();

      expect(state.practiceTodaySessions, 0);
      expect(state.practiceTodayReviewed, 0);
      expect(state.practiceTodayRemembered, 0);
      expect(state.practiceTotalSessions, 7);
      expect(state.practiceTotalReviewed, 28);
      expect(state.practiceTotalRemembered, 19);
      expect(state.practiceLastSessionTitle, 'Yesterday sprint');
      expect(state.practiceRememberedWords, <String>['Alpha']);
      expect(state.practiceWeakWords, <String>['Beta']);
      expect(
        state.practiceWrongNotebookEntries
            .map((item) => item.word)
            .toList(growable: false),
        <String>['Beta'],
      );

      final restoredDashboard = settings.loadPracticeDashboard();
      expect(restoredDashboard.date, _dateKey(DateTime.now()));
      expect(restoredDashboard.todaySessions, 0);
      expect(restoredDashboard.todayReviewed, 0);
      expect(restoredDashboard.todayRemembered, 0);
      expect(
        restoredDashboard.launchCursors,
        containsPair('practice:warmup', 2),
      );
      expect(restoredDashboard.trackedEntries, hasLength(1));
    },
  );
}

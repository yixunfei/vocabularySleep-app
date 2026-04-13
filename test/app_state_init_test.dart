import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

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
  List<WordEntry> getWordsLite(
    int wordbookId, {
    int limit = 100000,
    int offset = 0,
  }) {
    return getWords(wordbookId, limit: limit, offset: offset)
        .map(
          (entry) => entry.copyWith(
            fields: const <WordFieldItem>[],
            rawContent: entry.summaryMeaningText,
          ),
        )
        .toList(growable: false);
  }

  @override
  WordEntry? hydrateWordEntry(WordEntry entry) {
    final words = _wordsByWordbookId[entry.wordbookId] ?? const <WordEntry>[];
    for (final candidate in words) {
      if (candidate.sameEntryAs(entry)) {
        return candidate;
      }
    }
    return null;
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
      expect(state.favorites, <String>{'word:Star'});
      expect(state.taskWords, <String>{'word:Plan'});
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
      await initialState.selectWordEntry(initialState.words.last);
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
    'init restores playback progress by standard identity when headwords repeat',
    () async {
      final database = AppDatabaseService(WordbookImportService());
      await database.init();
      addTearDown(database.dispose);

      await database.importWordbook(
        sourcePath: 'custom:test_playback_progress_standard_identity',
        name: 'Playback identity restore test',
        entries: const <WordEntryPayload>[
          WordEntryPayload(
            word: 'set',
            fields: <WordFieldItem>[
              WordFieldItem(key: 'meaning', label: 'Meaning', value: '放置'),
            ],
            rawContent: '放置',
            entryUid: 'set-put',
            primaryGloss: '放置',
            schemaVersion: 'wordbook.v1',
          ),
          WordEntryPayload(
            word: 'set',
            fields: <WordFieldItem>[
              WordFieldItem(key: 'meaning', label: 'Meaning', value: '集合'),
            ],
            rawContent: '集合',
            entryUid: 'set-collection',
            primaryGloss: '集合',
            schemaVersion: 'wordbook.v1',
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
      final targetEntry = initialState.words.last;
      await initialState.selectWordEntry(targetEntry);
      initialState.rememberPlaybackProgress(targetEntry);

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

      expect(restoredState.words, hasLength(2));
      expect(restoredState.currentWord?.entryUid, 'set-collection');
      expect(restoredState.currentWord?.primaryGloss, '集合');
    },
  );

  test(
    'selectWordEntry hydrates full fields for deferred large wordbooks',
    () async {
      final database = AppDatabaseService(WordbookImportService());
      await database.init();
      addTearDown(database.dispose);

      await database.importWordbook(
        sourcePath: 'custom:test_large_wordbook_hydration',
        name: 'Large hydration test',
        entries: const <WordEntryPayload>[
          WordEntryPayload(
            word: 'a',
            fields: <WordFieldItem>[
              WordFieldItem(
                key: 'meaning',
                label: 'Meaning',
                value: '不定冠词，用于可数单数名词前',
              ),
              WordFieldItem(
                key: 'meanings_zh',
                label: 'Chinese meanings',
                value: <String>['不定冠词，用于可数单数名词前', '英文字母表中的第一个字母'],
              ),
              WordFieldItem(
                key: 'parts_of_speech',
                label: 'Parts of speech',
                value: <Map<String, Object?>>[
                  <String, Object?>{
                    'pos': 'article',
                    'zh': <String>['不定冠词，用于可数单数名词前'],
                  },
                ],
              ),
              WordFieldItem(
                key: 'pronunciations',
                label: 'Pronunciations',
                value: <Map<String, Object?>>[
                  <String, Object?>{
                    'ipa': '/eɪ/',
                    'tags': <String>['US'],
                  },
                ],
              ),
              WordFieldItem(
                key: 'frequency_rank',
                label: 'Frequency rank',
                value: 5,
              ),
            ],
            rawContent: '不定冠词，用于可数单数名词前',
            entryUid: 'large-book-a',
            primaryGloss: '不定冠词，用于可数单数名词前',
            schemaVersion: 'wordbook.v1',
          ),
        ],
      );

      final wordbook = database.getWordbooks().firstWhere(
        (item) => item.path == 'custom:test_large_wordbook_hydration',
      );
      final sqlite = sqlite3.open(database.dbPath);
      addTearDown(sqlite.dispose);
      sqlite.execute(
        'UPDATE wordbooks SET word_count = 2000 WHERE id = ?',
        <Object?>[wordbook.id],
      );

      final settings = SettingsService(database);
      final state = AppState(
        database: database,
        settings: settings,
        playback: TrackingPlaybackService(),
        ambient: StubAmbientService(),
        asr: StubAsrService(),
        focusService: StubFocusService(database, settings: settings),
      );
      await state.init();
      addTearDown(state.dispose);

      final largeWordbook = state.wordbooks.firstWhere(
        (item) => item.path == 'custom:test_large_wordbook_hydration',
      );
      await state.selectWordbook(largeWordbook);

      expect(state.selectedWordbookLoaded, isFalse);
      final lite = state.getVisibleWordsPage(limit: 1).single;
      expect(
        lite.fields.map((field) => field.key).toList(growable: false),
        contains('meaning'),
      );

      await state.selectWordEntry(lite);

      final current = state.currentWord;
      expect(current, isNotNull);
      expect(
        current!.fields.map((field) => field.key).toList(growable: false),
        containsAll(<String>[
          'meaning',
          'meanings_zh',
          'parts_of_speech',
          'pronunciations',
          'frequency_rank',
        ]),
      );
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

  test(
    'playCurrentWordbook loads deferred large wordbook first and plays only on the next tap',
    () async {
      final database = _MemoryDatabaseService(
        wordbooks: <Wordbook>[
          Wordbook(
            id: 3,
            name: 'Core',
            path: 'custom:core',
            wordCount: 2,
            createdAt: DateTime(2026, 4, 13),
          ),
          Wordbook(
            id: 4,
            name: 'Large',
            path: 'custom:large',
            wordCount: 2500,
            createdAt: DateTime(2026, 4, 13),
          ),
        ],
        wordsByWordbookId: <int, List<WordEntry>>{
          3: <WordEntry>[_word(1, 'Alpha'), _word(2, 'Beta')],
          4: <WordEntry>[
            _word(41, 'Gamma').copyWith(wordbookId: 4, meaning: 'third'),
            _word(42, 'Delta').copyWith(wordbookId: 4, meaning: 'fourth'),
          ],
        },
      );
      final settings = SettingsService(database);
      final playback = TrackingPlaybackService();
      final state = AppState(
        database: database,
        settings: settings,
        playback: playback,
        ambient: StubAmbientService(),
        asr: StubAsrService(),
        focusService: StubFocusService(database, settings: settings),
      );

      await state.init();

      final largeWordbook = state.wordbooks.firstWhere((item) => item.id == 4);
      await state.selectWordbook(largeWordbook);

      expect(state.selectedWordbook?.id, 4);
      expect(state.selectedWordbookRequiresOnDemandLoad, isTrue);
      expect(state.selectedWordbookLoaded, isFalse);
      expect(state.currentWord, isNull);
      expect(state.words, isEmpty);

      await state.playCurrentWordbook();

      expect(playback.playWordsCalls, 0);
      expect(state.selectedWordbookLoaded, isTrue);
      expect(state.selectedWordbookRequiresOnDemandLoad, isFalse);
      expect(state.currentWord?.word, 'Gamma');
      expect(
        state.words.map((item) => item.word).toList(growable: false),
        <String>['Gamma', 'Delta'],
      );

      await state.playCurrentWordbook();

      expect(playback.playWordsCalls, 1);
    },
  );
}

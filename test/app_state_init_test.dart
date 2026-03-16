import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/app_home_tab.dart';
import 'package:vocabulary_sleep_app/src/models/focus_startup_tab.dart';
import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/models/weather_snapshot.dart';
import 'package:vocabulary_sleep_app/src/models/word_entry.dart';
import 'package:vocabulary_sleep_app/src/models/word_field.dart';
import 'package:vocabulary_sleep_app/src/models/word_memory_progress.dart';
import 'package:vocabulary_sleep_app/src/models/wordbook.dart';
import 'package:vocabulary_sleep_app/src/services/ambient_service.dart';
import 'package:vocabulary_sleep_app/src/services/app_log_service.dart';
import 'package:vocabulary_sleep_app/src/services/asr_service.dart';
import 'package:vocabulary_sleep_app/src/services/database_service.dart';
import 'package:vocabulary_sleep_app/src/services/focus_service.dart';
import 'package:vocabulary_sleep_app/src/services/playback_service.dart';
import 'package:vocabulary_sleep_app/src/services/settings_service.dart';
import 'package:vocabulary_sleep_app/src/services/weather_service.dart';
import 'package:vocabulary_sleep_app/src/services/wordbook_import_service.dart';
import 'package:vocabulary_sleep_app/src/state/app_state.dart';

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
}

class _FakePlaybackService implements PlaybackService {
  int updateCalls = 0;
  PlayConfig? lastConfig;

  @override
  void updateRuntimeConfig(PlayConfig config) {
    updateCalls += 1;
    lastConfig = config;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeAmbientService implements AmbientService {
  @override
  List<AmbientSource> get sources => const <AmbientSource>[];

  @override
  double get masterVolume => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeAsrService implements AsrService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeFocusService implements FocusService {
  int initCalls = 0;

  @override
  Future<void> init() async {
    initCalls += 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
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
      final playback = _FakePlaybackService();
      final focus = _FakeFocusService();
      final weather = _FakeWeatherService();

      settings.saveStartupPage(AppHomeTab.focus);
      settings.saveFocusStartupTab(FocusStartupTab.timer);
      settings.saveWeatherEnabled(true);
      settings.saveStartupTodoPromptEnabled(true);
      settings.saveStartupTodoPromptSuppressedDate(_dateKey(DateTime.now()));
      settings.saveRememberedWords(<String>{'Alpha'});
      settings.saveTestModeState(
        enabled: true,
        revealed: true,
        hintRevealed: false,
      );

      final state = AppState(
        database: database,
        settings: settings,
        playback: playback,
        ambient: _FakeAmbientService(),
        asr: _FakeAsrService(),
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

  test(
    'init resets stale practice day counters but keeps totals and cursors',
    () async {
      final database = _MemoryDatabaseService();
      final settings = SettingsService(database);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      settings.savePracticeDashboard(<String, Object?>{
        'date': _dateKey(yesterday),
        'todaySessions': 3,
        'todayReviewed': 12,
        'todayRemembered': 8,
        'totalSessions': 7,
        'totalReviewed': 28,
        'totalRemembered': 19,
        'lastSessionTitle': 'Yesterday sprint',
        'rememberedWords': <String>['Alpha'],
        'weakWords': <String>['Beta'],
        'launchCursors': <String, int>{'practice:warmup': 2},
      });

      final state = AppState(
        database: database,
        settings: settings,
        playback: _FakePlaybackService(),
        ambient: _FakeAmbientService(),
        asr: _FakeAsrService(),
        focusService: _FakeFocusService(),
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

      final restoredDashboard = settings.loadPracticeDashboard();
      expect(restoredDashboard['date'], _dateKey(DateTime.now()));
      expect(restoredDashboard['todaySessions'], 0);
      expect(restoredDashboard['todayReviewed'], 0);
      expect(restoredDashboard['todayRemembered'], 0);
      expect(
        restoredDashboard['launchCursors'],
        containsPair('practice:warmup', 2),
      );
    },
  );
}

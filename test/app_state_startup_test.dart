import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/models/todo_item.dart';
import 'package:vocabulary_sleep_app/src/models/weather_snapshot.dart';
import 'package:vocabulary_sleep_app/src/models/word_entry.dart';
import 'package:vocabulary_sleep_app/src/models/word_field.dart';
import 'package:vocabulary_sleep_app/src/models/word_memory_progress.dart';
import 'package:vocabulary_sleep_app/src/services/ambient_service.dart';
import 'package:vocabulary_sleep_app/src/services/asr_service.dart';
import 'package:vocabulary_sleep_app/src/services/daily_quote_service.dart';
import 'package:vocabulary_sleep_app/src/services/database_service.dart';
import 'package:vocabulary_sleep_app/src/services/focus_service.dart';
import 'package:vocabulary_sleep_app/src/services/playback_service.dart';
import 'package:vocabulary_sleep_app/src/services/settings_service.dart';
import 'package:vocabulary_sleep_app/src/services/weather_service.dart';
import 'package:vocabulary_sleep_app/src/services/wordbook_import_service.dart';
import 'package:vocabulary_sleep_app/src/state/app_state.dart';

class _MemoryDatabaseService extends AppDatabaseService {
  _MemoryDatabaseService() : super(WordbookImportService());

  final Map<String, String> _settings = <String, String>{};
  final Map<int, WordMemoryProgress> progressByWordId =
      <int, WordMemoryProgress>{};

  @override
  String? getSetting(String key) => _settings[key];

  @override
  void setSetting(String key, String value) {
    _settings[key] = value;
  }

  @override
  Map<int, WordMemoryProgress> getWordMemoryProgressByWordIds(
    Iterable<int> wordIds,
  ) {
    return <int, WordMemoryProgress>{
      for (final wordId in wordIds)
        if (progressByWordId.containsKey(wordId))
          wordId: progressByWordId[wordId]!,
    };
  }

  @override
  void upsertWordMemoryProgress(WordMemoryProgress progress) {
    progressByWordId[progress.wordId] = progress;
  }
}

class _FakePlaybackService implements PlaybackService {
  @override
  void updateRuntimeConfig(PlayConfig config) {}

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
  _FakeFocusService({this.todos = const <TodoItem>[]});

  final List<TodoItem> todos;

  @override
  List<TodoItem> getTodos() => todos;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeWeatherService extends WeatherService {
  _FakeWeatherService();

  int fetchCount = 0;

  @override
  Future<WeatherSnapshot> fetchCurrentWeather() async {
    fetchCount += 1;
    return WeatherSnapshot(
      city: 'Test City $fetchCount',
      countryCode: 'CN',
      temperatureCelsius: 21,
      apparentTemperatureCelsius: 20,
      windSpeedKph: 3,
      weatherCode: 1,
      isDay: true,
      fetchedAt: DateTime.now(),
      forecastDays: <WeatherForecastDay>[
        WeatherForecastDay(
          date: DateTime.now(),
          weatherCode: 1,
          maxTemperatureCelsius: 24,
          minTemperatureCelsius: 16,
        ),
      ],
    );
  }
}

class _FakeDailyQuoteService extends DailyQuoteService {
  _FakeDailyQuoteService();

  int fetchCount = 0;

  @override
  Future<String> fetchQuote() async {
    fetchCount += 1;
    return 'Quote $fetchCount';
  }
}

WordEntry _word(String value, {int? id}) {
  return WordEntry(
    id: id,
    wordbookId: 1,
    word: value,
    fields: const <WordFieldItem>[],
  );
}

AppState _createState({
  _MemoryDatabaseService? database,
  _FakeFocusService? focusService,
  _FakeWeatherService? weatherService,
  _FakeDailyQuoteService? dailyQuoteService,
}) {
  final resolvedDatabase = database ?? _MemoryDatabaseService();
  return AppState(
    database: resolvedDatabase,
    settings: SettingsService(resolvedDatabase),
    playback: _FakePlaybackService(),
    ambient: _FakeAmbientService(),
    asr: _FakeAsrService(),
    focusService: focusService ?? _FakeFocusService(),
    weatherService: weatherService,
    dailyQuoteService: dailyQuoteService,
  );
}

String _todayKey() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('todayActiveTodos keeps only active todos due today', () {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final focus = _FakeFocusService(
      todos: <TodoItem>[
        TodoItem(
          content: 'today active',
          dueAt: startOfToday.add(const Duration(hours: 9)),
        ),
        TodoItem(
          content: 'already due today',
          dueAt: startOfToday.add(const Duration(minutes: 30)),
        ),
        TodoItem(
          content: 'tomorrow',
          dueAt: startOfToday.add(const Duration(days: 1, hours: 2)),
        ),
        TodoItem(content: 'no due date'),
        TodoItem(
          content: 'completed today',
          dueAt: startOfToday.add(const Duration(hours: 10)),
          completed: true,
        ),
        TodoItem(
          content: 'deferred today',
          dueAt: startOfToday.add(const Duration(hours: 11)),
          deferred: true,
        ),
      ],
    );

    final state = _createState(focusService: focus);

    expect(
      state.todayActiveTodos
          .map((item) => item.content)
          .toList(growable: false),
      <String>['today active', 'already due today'],
    );
  });

  test(
    'startup prompt content caches daily quote and weather until forced',
    () async {
      final weather = _FakeWeatherService();
      final quote = _FakeDailyQuoteService();
      final state = _createState(
        weatherService: weather,
        dailyQuoteService: quote,
      );

      await state.refreshStartupTodoPromptContent();
      expect(quote.fetchCount, 1);
      expect(weather.fetchCount, 1);
      expect(state.startupDailyQuote, 'Quote 1');
      expect(state.weatherSnapshot?.city, 'Test City 1');

      await state.refreshStartupTodoPromptContent();
      expect(quote.fetchCount, 1);
      expect(weather.fetchCount, 1);

      await state.refreshStartupTodoPromptContent(force: true);
      expect(quote.fetchCount, 2);
      expect(weather.fetchCount, 2);
      expect(state.startupDailyQuote, 'Quote 2');
      expect(state.weatherSnapshot?.city, 'Test City 2');
    },
  );

  test('startup todo prompt suppression persists for today', () {
    final database = _MemoryDatabaseService();
    final settings = SettingsService(database);
    final state = _createState(database: database);

    expect(state.startupTodoPromptEnabled, isFalse);
    expect(state.shouldShowStartupTodoPromptToday, isFalse);

    state.setStartupTodoPromptEnabled(true);
    expect(state.startupTodoPromptEnabled, isTrue);
    expect(state.shouldShowStartupTodoPromptToday, isTrue);
    expect(settings.loadStartupTodoPromptEnabled(), isTrue);

    state.suppressStartupTodoPromptForToday();
    expect(state.shouldShowStartupTodoPromptToday, isFalse);
    expect(settings.loadStartupTodoPromptSuppressedDate(), _todayKey());
  });

  test(
    'weather refresh honors toggle, cache freshness, and force reload',
    () async {
      final weather = _FakeWeatherService();
      final state = _createState(weatherService: weather);

      await state.refreshWeather();
      expect(weather.fetchCount, 0);

      state.setWeatherEnabled(true);
      await pumpEventQueue();
      expect(state.weatherEnabled, isTrue);
      expect(weather.fetchCount, 1);
      expect(state.weatherSnapshot?.city, 'Test City 1');

      await state.refreshWeather();
      expect(weather.fetchCount, 1);

      await state.refreshWeather(force: true);
      expect(weather.fetchCount, 2);
      expect(state.weatherSnapshot?.city, 'Test City 2');
    },
  );

  test('recordPracticeSession feeds memory lanes and remembered status', () {
    final database = _MemoryDatabaseService();
    final settings = SettingsService(database);
    final state = _createState(database: database);

    state.recordPracticeSession(
      title: 'Memory lane',
      total: 2,
      remembered: 1,
      rememberedWords: <String>['Alpha'],
      weakWords: <String>['Bravo'],
      rememberedEntries: <WordEntry>[_word('Alpha', id: 1)],
      weakEntries: <WordEntry>[_word('Bravo', id: 2)],
    );

    expect(
      state.recentRememberedWordEntries
          .map((item) => item.word)
          .toList(growable: false),
      <String>['Alpha'],
    );
    expect(
      state.recentWeakWordEntries
          .map((item) => item.word)
          .toList(growable: false),
      <String>['Bravo'],
    );
    expect(settings.loadRememberedWords(), <String>{'alpha'});
    expect(database.progressByWordId[1]?.timesPlayed, 1);
    expect(database.progressByWordId[1]?.timesCorrect, 1);
    expect(database.progressByWordId[2]?.timesPlayed, 1);
    expect(database.progressByWordId[2]?.timesCorrect, 0);

    final dashboard = settings.loadPracticeDashboard();
    expect(dashboard.lastSessionTitle, 'Memory lane');
    expect(dashboard.rememberedWords, <String>['Alpha']);
    expect(dashboard.weakWords, <String>['Bravo']);
  });
}

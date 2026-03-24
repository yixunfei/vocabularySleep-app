import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/word_entry.dart';
import 'package:vocabulary_sleep_app/src/models/word_field.dart';
import 'package:vocabulary_sleep_app/src/models/word_memory_progress.dart';
import 'package:vocabulary_sleep_app/src/services/database_service.dart';
import 'package:vocabulary_sleep_app/src/services/settings_service.dart';
import 'package:vocabulary_sleep_app/src/services/wordbook_import_service.dart';
import 'package:vocabulary_sleep_app/src/state/app_state.dart';
import 'test_support/app_state_test_doubles.dart';

class _MemoryDatabaseService extends AppDatabaseService {
  _MemoryDatabaseService() : super(WordbookImportService());

  final Map<String, String> _settings = <String, String>{};
  final Map<int, WordMemoryProgress> _progressByWordId =
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
    final output = <int, WordMemoryProgress>{};
    for (final wordId in wordIds) {
      final progress = _progressByWordId[wordId];
      if (progress != null) {
        output[wordId] = progress;
      }
    }
    return output;
  }

  @override
  void upsertWordMemoryProgress(WordMemoryProgress progress) {
    _progressByWordId[progress.wordId] = progress;
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('recordPracticeSession keeps practice lists writable-safe', () {
    final database = _MemoryDatabaseService();
    final settings = SettingsService(database);
    final state = AppState(
      database: database,
      settings: settings,
      playback: TrackingPlaybackService(),
      ambient: StubAmbientService(),
      asr: StubAsrService(),
      focusService: StubFocusService(database, settings: settings),
    );

    expect(
      () => state.recordPracticeSession(
        title: 'Memory sync',
        total: 2,
        remembered: 1,
        rememberedWords: <String>['alpha'],
        weakWords: <String>['bravo'],
        rememberedEntries: <WordEntry>[_word('alpha')],
        weakEntries: <WordEntry>[_word('bravo')],
      ),
      returnsNormally,
    );

    expect(state.practiceTodaySessions, 1);
    expect(state.practiceTodayReviewed, 2);
    expect(state.practiceTodayRemembered, 1);
    expect(state.practiceRememberedWords, <String>['alpha']);
    expect(state.practiceWeakWords, <String>['bravo']);
  });

  test('beginPracticeBatch advances cursor and honors anchor words', () {
    final database = _MemoryDatabaseService();
    final settings = SettingsService(database);
    final state = AppState(
      database: database,
      settings: settings,
      playback: TrackingPlaybackService(),
      ambient: StubAmbientService(),
      asr: StubAsrService(),
      focusService: StubFocusService(database, settings: settings),
    );
    final words = <WordEntry>[_word('alpha'), _word('bravo'), _word('charlie')];

    final firstBatch = state.beginPracticeBatch(
      cursorKey: 'practice:warmup',
      sourceWords: words,
      batchSize: 2,
    );
    expect(
      firstBatch.map((item) => item.word).toList(growable: false),
      <String>['alpha', 'bravo'],
    );

    final secondBatch = state.beginPracticeBatch(
      cursorKey: 'practice:warmup',
      sourceWords: words,
      batchSize: 2,
    );
    expect(
      secondBatch.map((item) => item.word).toList(growable: false),
      <String>['charlie', 'alpha'],
    );

    final anchoredBatch = state.beginPracticeBatch(
      cursorKey: 'practice:warmup',
      sourceWords: words,
      batchSize: 1,
      anchorWord: words[1],
    );
    expect(
      anchoredBatch.map((item) => item.word).toList(growable: false),
      <String>['bravo'],
    );

    final nextBatch = state.beginPracticeBatch(
      cursorKey: 'practice:warmup',
      sourceWords: words,
      batchSize: 1,
    );
    expect(nextBatch.map((item) => item.word).toList(growable: false), <String>[
      'charlie',
    ]);

    final dashboard = settings.loadPracticeDashboard();
    expect(dashboard.launchCursors, containsPair('practice:warmup', 0));
  });

  test(
    'beginPracticeBatch can rotate full rounds with custom cursor advance',
    () {
      final database = _MemoryDatabaseService();
      final settings = SettingsService(database);
      final state = AppState(
        database: database,
        settings: settings,
        playback: TrackingPlaybackService(),
        ambient: StubAmbientService(),
        asr: StubAsrService(),
        focusService: StubFocusService(database, settings: settings),
      );
      final words = <WordEntry>[
        _word('alpha'),
        _word('bravo'),
        _word('charlie'),
      ];

      final firstRound = state.beginPracticeBatch(
        cursorKey: 'practice:scope-full',
        sourceWords: words,
        batchSize: words.length,
        cursorAdvance: 1,
      );
      expect(
        firstRound.map((item) => item.word).toList(growable: false),
        <String>['alpha', 'bravo', 'charlie'],
      );

      final secondRound = state.beginPracticeBatch(
        cursorKey: 'practice:scope-full',
        sourceWords: words,
        batchSize: words.length,
        cursorAdvance: 1,
      );
      expect(
        secondRound.map((item) => item.word).toList(growable: false),
        <String>['bravo', 'charlie', 'alpha'],
      );

      final thirdRound = state.beginPracticeBatch(
        cursorKey: 'practice:scope-full',
        sourceWords: words,
        batchSize: words.length,
        cursorAdvance: 1,
      );
      expect(
        thirdRound.map((item) => item.word).toList(growable: false),
        <String>['charlie', 'alpha', 'bravo'],
      );

      final dashboard = settings.loadPracticeDashboard();
      expect(dashboard.launchCursors, containsPair('practice:scope-full', 0));
    },
  );

  test(
    'wrong notebook keeps weak words in stored order and supports cleanup',
    () {
      final database = _MemoryDatabaseService();
      final settings = SettingsService(database);
      final state = AppState(
        database: database,
        settings: settings,
        playback: TrackingPlaybackService(),
        ambient: StubAmbientService(),
        asr: StubAsrService(),
        focusService: StubFocusService(database, settings: settings),
      );

      state.recordPracticeSession(
        title: 'Round 1',
        total: 2,
        remembered: 1,
        rememberedWords: const <String>['charlie'],
        weakWords: const <String>['bravo'],
        rememberedEntries: <WordEntry>[_word('charlie', id: 3)],
        weakEntries: <WordEntry>[_word('bravo', id: 2)],
        weakReasonIdsByWord: const <String, List<String>>{
          'bravo': <String>['meaning'],
        },
      );
      state.recordPracticeSession(
        title: 'Round 2',
        total: 2,
        remembered: 1,
        rememberedWords: const <String>['charlie'],
        weakWords: const <String>['alpha'],
        rememberedEntries: <WordEntry>[_word('charlie', id: 3)],
        weakEntries: <WordEntry>[_word('alpha', id: 1)],
        weakReasonIdsByWord: const <String, List<String>>{
          'alpha': <String>['spelling', 'meaning'],
        },
      );

      expect(
        state.practiceWrongNotebookEntries.map((item) => item.word).toList(),
        <String>['alpha', 'bravo'],
      );
      expect(state.practiceWeakReasonsForWord(_word('alpha', id: 1)), <String>[
        'spelling',
        'meaning',
      ]);
      expect(state.practiceSessionHistory.first.title, 'Round 2');
      expect(state.practiceSessionHistory.first.weakReasonCounts, <String, int>{
        'spelling': 1,
        'meaning': 1,
      });

      expect(state.dismissPracticeWeakWord(_word('alpha', id: 1)), isTrue);
      expect(
        state.practiceWrongNotebookEntries.map((item) => item.word).toList(),
        <String>['bravo'],
      );
      expect(state.practiceWeakReasonsForWord(_word('alpha', id: 1)), isEmpty);

      final removed = state.clearPracticeWeakWords();
      expect(removed, 1);
      expect(state.practiceWrongNotebookEntries, isEmpty);

      final dashboard = settings.loadPracticeDashboard();
      expect(dashboard.weakWords, isEmpty);
    },
  );
}

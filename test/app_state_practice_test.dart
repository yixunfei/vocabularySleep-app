import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/settings_dto.dart';
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

  test(
    'recordPracticeAnswer persists weak notebook and counters immediately',
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
      final alpha = _word('alpha', id: 1);
      final bravo = _word('bravo', id: 2);

      state.startPracticeSession(title: 'Live session');
      state.recordPracticeAnswer(
        entry: alpha,
        remembered: false,
        weakReasonIds: const <String>['meaning'],
      );
      state.recordPracticeAnswer(entry: bravo, remembered: true);
      state.finishPracticeSession(
        title: 'Live session',
        total: 2,
        remembered: 1,
        weakReasonIdsByWord: const <String, List<String>>{
          'alpha': <String>['meaning'],
        },
      );

      expect(state.practiceTodaySessions, 1);
      expect(state.practiceTodayReviewed, 2);
      expect(state.practiceTodayRemembered, 1);
      expect(
        state.practiceWrongNotebookEntries.map((item) => item.word).toList(),
        <String>['alpha'],
      );
      expect(state.practiceWeakReasonsForWord(alpha), <String>['meaning']);
      expect(state.practiceSessionHistory.first.title, 'Live session');
    },
  );

  test('recordPracticeAnswer keeps tracked practice snapshot lightweight', () {
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
    const entry = WordEntry(
      id: 9,
      wordbookId: 1,
      word: 'anchor',
      entryUid: 'anchor-entry',
      primaryGloss: '固定',
      rawContent: '这是一段不该跟着每题答题一起反复落盘的大块原始内容。',
      fields: <WordFieldItem>[
        WordFieldItem(key: 'meaning', label: 'Meaning', value: '固定'),
        WordFieldItem(key: 'example', label: 'Example', value: 'drop anchor'),
      ],
    );

    state.startPracticeSession(title: 'Snapshot');
    state.recordPracticeAnswer(
      entry: entry,
      remembered: false,
      weakReasonIds: const <String>['meaning'],
    );

    final dashboard = settings.loadPracticeDashboard();
    expect(dashboard.trackedEntries, hasLength(1));
    expect(dashboard.trackedEntries.first.word, 'anchor');
    expect(dashboard.trackedEntries.first.meaning, '固定');
    expect(dashboard.trackedEntries.first.fields, isEmpty);
    expect(dashboard.trackedEntries.first.rawContent, isEmpty);
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

  test('practice round settings persist and preview the saved cursor', () {
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

    state.updatePracticeRoundSettings(
      source: PracticeRoundSource.wrongNotebook,
      startMode: PracticeRoundStartMode.resumeCursor,
      roundSize: 2,
      shuffle: true,
      collapsed: false,
    );
    state.beginPracticeBatch(
      cursorKey: 'practice:round:test',
      sourceWords: words,
      batchSize: 2,
      cursorAdvance: 2,
    );

    expect(
      state.previewPracticeBatchStartIndex(
        cursorKey: 'practice:round:test',
        sourceWords: words,
      ),
      2,
    );

    final dashboard = settings.loadPracticeDashboard();
    expect(dashboard.roundSettings.source, PracticeRoundSource.wrongNotebook);
    expect(
      dashboard.roundSettings.startMode,
      PracticeRoundStartMode.resumeCursor,
    );
    expect(dashboard.roundSettings.roundSize, 2);
    expect(dashboard.roundSettings.shuffle, isTrue);
    expect(dashboard.roundSettings.collapsed, isFalse);
  });

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

  test(
    'wrong notebook keeps duplicate headwords distinct when tracked entries have stable identity',
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

      const setPut = WordEntry(
        id: 11,
        wordbookId: 1,
        word: 'set',
        entryUid: 'set-put',
        primaryGloss: '放置',
        fields: <WordFieldItem>[
          WordFieldItem(key: 'meaning', label: 'Meaning', value: '放置'),
        ],
        rawContent: '放置',
      );
      const setCollection = WordEntry(
        id: 12,
        wordbookId: 1,
        word: 'set',
        entryUid: 'set-collection',
        primaryGloss: '集合',
        fields: <WordFieldItem>[
          WordFieldItem(key: 'meaning', label: 'Meaning', value: '集合'),
        ],
        rawContent: '集合',
      );

      state.recordPracticeSession(
        title: 'Identity round',
        total: 2,
        remembered: 0,
        rememberedWords: const <String>[],
        weakWords: const <String>['set', 'set'],
        weakEntries: const <WordEntry>[setPut, setCollection],
        weakReasonIdsByWord: const <String, List<String>>{
          'set': <String>['meaning'],
        },
      );

      final wrongNotebook = state.practiceWrongNotebookEntries;
      expect(wrongNotebook, hasLength(2));
      expect(
        wrongNotebook.map((entry) => entry.entryUid).toList(growable: false),
        <String?>['set-put', 'set-collection'],
      );
    },
  );
}

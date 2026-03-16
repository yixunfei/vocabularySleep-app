import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/models/word_entry.dart';
import 'package:vocabulary_sleep_app/src/models/word_field.dart';
import 'package:vocabulary_sleep_app/src/services/ambient_service.dart';
import 'package:vocabulary_sleep_app/src/services/asr_service.dart';
import 'package:vocabulary_sleep_app/src/services/database_service.dart';
import 'package:vocabulary_sleep_app/src/services/focus_service.dart';
import 'package:vocabulary_sleep_app/src/services/playback_service.dart';
import 'package:vocabulary_sleep_app/src/services/settings_service.dart';
import 'package:vocabulary_sleep_app/src/services/wordbook_import_service.dart';
import 'package:vocabulary_sleep_app/src/state/app_state.dart';

class _MemoryDatabaseService extends AppDatabaseService {
  _MemoryDatabaseService() : super(WordbookImportService());

  final Map<String, String> _settings = <String, String>{};

  @override
  String? getSetting(String key) => _settings[key];

  @override
  void setSetting(String key, String value) {
    _settings[key] = value;
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
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

WordEntry _word(String value) {
  return WordEntry(wordbookId: 1, word: value, fields: const <WordFieldItem>[]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('recordPracticeSession keeps practice lists writable-safe', () {
    final database = _MemoryDatabaseService();
    final settings = SettingsService(database);
    final state = AppState(
      database: database,
      settings: settings,
      playback: _FakePlaybackService(),
      ambient: _FakeAmbientService(),
      asr: _FakeAsrService(),
      focusService: _FakeFocusService(),
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
      playback: _FakePlaybackService(),
      ambient: _FakeAmbientService(),
      asr: _FakeAsrService(),
      focusService: _FakeFocusService(),
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
    expect(dashboard['launchCursors'], containsPair('practice:warmup', 0));
  });
}

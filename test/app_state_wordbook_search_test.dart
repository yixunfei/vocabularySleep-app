import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/word_entry.dart';
import 'package:vocabulary_sleep_app/src/models/word_field.dart';
import 'package:vocabulary_sleep_app/src/models/wordbook.dart';
import 'package:vocabulary_sleep_app/src/repositories/wordbook_repository.dart';
import 'package:vocabulary_sleep_app/src/services/database_service.dart';
import 'package:vocabulary_sleep_app/src/services/settings_service.dart';
import 'package:vocabulary_sleep_app/src/services/wordbook_import_service.dart';
import 'package:vocabulary_sleep_app/src/services/wordbook_query_worker.dart';
import 'package:vocabulary_sleep_app/src/state/app_state.dart';

import 'test_support/app_state_test_doubles.dart';

class _ControllableSearchRepository extends DatabaseWordbookRepository {
  _ControllableSearchRepository(super.database);

  final List<Wordbook> testWordbooks = <Wordbook>[
    Wordbook(
      id: 71,
      name: 'Large search one',
      path: 'custom:large_search_one',
      wordCount: 2000,
      createdAt: DateTime(2026, 8, 26),
    ),
    Wordbook(
      id: 72,
      name: 'Large search two',
      path: 'custom:large_search_two',
      wordCount: 2000,
      createdAt: DateTime(2026, 8, 26),
    ),
  ];
  final Map<String, Completer<WordbookSearchResult>> requests =
      <String, Completer<WordbookSearchResult>>{};
  int activeRequests = 0;
  int maxActiveRequests = 0;

  String requestKey(int wordbookId, String query) => '$wordbookId|$query';

  @override
  List<Wordbook> getWordbooks() => testWordbooks;

  @override
  Future<WordbookSearchResult> searchWordsLiteAsync(
    int wordbookId, {
    required String query,
    required String mode,
    int limit = 100000,
  }) {
    final request = Completer<WordbookSearchResult>();
    requests[requestKey(wordbookId, query)] = request;
    activeRequests += 1;
    if (activeRequests > maxActiveRequests) {
      maxActiveRequests = activeRequests;
    }
    return request.future.whenComplete(() {
      activeRequests -= 1;
    });
  }
}

WordEntry _word(int id, int wordbookId, String word) {
  return WordEntry(
    id: id,
    wordbookId: wordbookId,
    word: word,
    fields: const <WordFieldItem>[],
  );
}

Future<void> _waitForRequest(
  _ControllableSearchRepository repository,
  String key,
) async {
  for (var attempt = 0; attempt < 20; attempt += 1) {
    if (repository.requests.containsKey(key)) {
      return;
    }
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for search request $key');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  late Directory tempDirectory;
  late AppDatabaseService database;
  late _ControllableSearchRepository repository;
  late AppState state;
  var stateDisposed = false;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'wordbook_search_state_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          pathProviderChannel,
          (_) async => tempDirectory.path,
        );
    database = AppDatabaseService(WordbookImportService());
    await database.init();
    repository = _ControllableSearchRepository(database);
    final settings = SettingsService(database);
    state = AppState(
      database: database,
      settings: settings,
      wordbookRepository: repository,
      playback: TrackingPlaybackService(),
      ambient: StubAmbientService(),
      asr: StubAsrService(),
      focusService: StubFocusService(database, settings: settings),
    );
    stateDisposed = false;
    await state.init();
  });

  tearDown(() async {
    if (!stateDisposed) {
      state.dispose();
    }
    database.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    await tempDirectory.delete(recursive: true);
  });

  test(
    'serializes workers, commits latest query, and releases snapshot',
    () async {
      final selected = state.selectedWordbook!;
      final alphaKey = repository.requestKey(selected.id, 'Alpha');
      final betaKey = repository.requestKey(selected.id, 'Beta');

      final firstSearch = state.setSearchQuery('Alpha');
      final secondSearch = state.setSearchQuery('Beta');
      expect(state.wordbookSearchInProgress, isTrue);
      expect(repository.requests, contains(alphaKey));
      expect(repository.requests, isNot(contains(betaKey)));

      repository.requests[alphaKey]!.complete(
        WordbookSearchResult(
          entries: <WordEntry>[_word(7101, selected.id, 'Alpha')],
          totalCount: 1,
        ),
      );
      await _waitForRequest(repository, betaKey);
      repository.requests[betaKey]!.complete(
        WordbookSearchResult(
          entries: <WordEntry>[_word(7102, selected.id, 'Beta')],
          totalCount: 1,
        ),
      );
      await Future.wait(<Future<void>>[firstSearch, secondSearch]);

      expect(state.wordbookSearchInProgress, isFalse);
      expect(state.visibleWords.map((item) => item.word), <String>['Beta']);
      expect(state.visibleWordCount, 1);
      expect(repository.maxActiveRequests, 1);

      final completedSnapshot = state.visibleWords;
      final completedRevision = state.wordbookSearchRevision;
      await state.setSearchQuery('');
      expect(state.wordbookSearchInProgress, isFalse);
      expect(state.visibleWords, isEmpty);
      expect(state.visibleWords, isNot(same(completedSnapshot)));
      expect(state.wordbookSearchRevision, greaterThan(completedRevision));
    },
  );

  test('switching wordbooks discards the previous search result', () async {
    final firstBook = state.wordbooks.first;
    final secondBook = state.wordbooks.last;
    final firstKey = repository.requestKey(firstBook.id, 'Alpha');
    final secondKey = repository.requestKey(secondBook.id, 'Alpha');

    final firstSearch = state.setSearchQuery('Alpha');
    final switchWordbook = state.selectWordbook(secondBook);
    expect(repository.requests, contains(firstKey));
    expect(repository.requests, isNot(contains(secondKey)));

    repository.requests[firstKey]!.complete(
      WordbookSearchResult(
        entries: <WordEntry>[_word(7101, firstBook.id, 'Alpha one')],
        totalCount: 1,
      ),
    );
    await _waitForRequest(repository, secondKey);
    repository.requests[secondKey]!.complete(
      WordbookSearchResult(
        entries: <WordEntry>[_word(7201, secondBook.id, 'Alpha two')],
        totalCount: 1,
      ),
    );
    await Future.wait(<Future<void>>[firstSearch, switchWordbook]);

    expect(state.selectedWordbook?.id, secondBook.id);
    expect(state.visibleWords.map((item) => item.word), <String>['Alpha two']);
    expect(repository.maxActiveRequests, 1);
  });

  test('disposing ignores an in-flight search result', () async {
    final selected = state.selectedWordbook!;
    final requestKey = repository.requestKey(selected.id, 'Alpha');
    final search = state.setSearchQuery('Alpha');

    state.dispose();
    stateDisposed = true;
    repository.requests[requestKey]!.complete(
      WordbookSearchResult(
        entries: <WordEntry>[_word(7101, selected.id, 'Alpha')],
        totalCount: 1,
      ),
    );

    await search;
    expect(repository.activeRequests, 0);
    expect(state.wordbookSearchInProgress, isFalse);
  });
}

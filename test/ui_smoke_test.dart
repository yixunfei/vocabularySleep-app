import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:vocabulary_sleep_app/src/i18n/app_i18n.dart';
import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/models/word_entry.dart';
import 'package:vocabulary_sleep_app/src/models/word_field.dart';
import 'package:vocabulary_sleep_app/src/models/wordbook.dart';
import 'package:vocabulary_sleep_app/src/services/asr_service.dart';
import 'package:vocabulary_sleep_app/src/state/app_state.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/appearance_studio_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/data_management_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/library_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/recognition_settings_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/voice_settings_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/wordbook_management_page.dart';
import 'package:vocabulary_sleep_app/src/ui/theme/app_theme.dart';
import 'package:vocabulary_sleep_app/src/ui/widgets/setting_tile.dart';
import 'package:vocabulary_sleep_app/src/ui/widgets/word_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UI smoke', () {
    testWidgets('voice settings shows TTS provider controls', (tester) async {
      final state = _FakeAppState.sample(uiLanguage: 'en');
      await _pumpPage(tester, state: state, child: const VoiceSettingsPage());

      expect(find.textContaining('TTS'), findsWidgets);
      expect(find.byType(DropdownButtonFormField<TtsProviderType>), findsOne);
    });

    testWidgets('recognition settings shows offline package section', (
      tester,
    ) async {
      final state = _FakeAppState.sample(uiLanguage: 'en');
      await _pumpPage(
        tester,
        state: state,
        child: const RecognitionSettingsPage(),
      );

      expect(find.textContaining('ASR'), findsWidgets);
      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('library page keeps index entry visible', (tester) async {
      final state = _FakeAppState.sample(uiLanguage: 'en');
      await _pumpPage(tester, state: state, child: const LibraryPage());

      expect(find.text('Open index'), findsOneWidget);
    });

    testWidgets(
      'setting tile keeps chevron aligned with title on narrow width',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 720));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(PlayConfig.defaults.appearance),
            home: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  SettingTile(
                    icon: Icons.tune_rounded,
                    title: 'Settings hub',
                    subtitle: 'Language, playback, voice, and appearance',
                    onTap: _noop,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final titleRect = tester.getRect(find.text('Settings hub'));
        final subtitleRect = tester.getRect(
          find.text('Language, playback, voice, and appearance'),
        );
        final chevronRect = tester.getRect(
          find.byIcon(Icons.chevron_right_rounded),
        );

        expect((chevronRect.top - titleRect.top).abs(), lessThan(18));
        expect(chevronRect.bottom, lessThan(subtitleRect.bottom));
      },
    );

    testWidgets('library page uses wrapped index preview on narrow width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final words = <WordEntry>[
        const WordEntry(
          wordbookId: 1,
          word: 'Alpha',
          fields: <WordFieldItem>[],
        ),
        const WordEntry(
          wordbookId: 1,
          word: 'Bravo',
          fields: <WordFieldItem>[],
        ),
        const WordEntry(
          wordbookId: 1,
          word: 'Charlie',
          fields: <WordFieldItem>[],
        ),
        const WordEntry(
          wordbookId: 1,
          word: 'Delta',
          fields: <WordFieldItem>[],
        ),
        const WordEntry(wordbookId: 1, word: 'Echo', fields: <WordFieldItem>[]),
        const WordEntry(
          wordbookId: 1,
          word: 'Foxtrot',
          fields: <WordFieldItem>[],
        ),
        const WordEntry(wordbookId: 1, word: 'Golf', fields: <WordFieldItem>[]),
        const WordEntry(
          wordbookId: 1,
          word: 'Hotel',
          fields: <WordFieldItem>[],
        ),
        const WordEntry(
          wordbookId: 1,
          word: 'India',
          fields: <WordFieldItem>[],
        ),
        const WordEntry(
          wordbookId: 1,
          word: 'Juliet',
          fields: <WordFieldItem>[],
        ),
        const WordEntry(wordbookId: 1, word: 'Kilo', fields: <WordFieldItem>[]),
        const WordEntry(wordbookId: 1, word: 'Lima', fields: <WordFieldItem>[]),
        const WordEntry(wordbookId: 1, word: 'Mike', fields: <WordFieldItem>[]),
      ];

      await _pumpPage(
        tester,
        state: _FakeAppState.sample(words: words, uiLanguage: 'en'),
        child: const LibraryPage(),
      );

      expect(find.text('All letters'), findsOneWidget);
      expect(find.text('More...'), findsNothing);

      final horizontalScrollViews = tester
          .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .where((widget) => widget.scrollDirection == Axis.horizontal)
          .length;
      expect(horizontalScrollViews, 1);
    });

    testWidgets('appearance studio shows translated controls in Chinese', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpPage(
        tester,
        state: _FakeAppState.sample(),
        child: const AppearanceStudioPage(),
      );

      expect(find.text('\u5b57\u4f53\u6392\u7248'), findsOneWidget);
      expect(find.text('\u91cd\u7f6e'), findsOneWidget);
      expect(find.text('\u7cfb\u7edf\u5b57\u4f53'), findsOneWidget);
      expect(find.text('Typography'), findsNothing);
      expect(find.text('Reset'), findsNothing);
      expect(find.text('System'), findsNothing);
    });

    testWidgets('library index jump scrolls lazy list to target word', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final words = List<WordEntry>.generate(26, (index) {
        final letter = String.fromCharCode(65 + index);
        final name = switch (letter) {
          'A' => 'Alpha',
          'B' => 'Bravo',
          'C' => 'Charlie',
          'D' => 'Delta',
          'E' => 'Echo',
          'F' => 'Foxtrot',
          'G' => 'Golf',
          'H' => 'Hotel',
          'I' => 'India',
          'J' => 'Juliet',
          'K' => 'Kilo',
          'L' => 'Lima',
          'M' => 'Mike',
          'N' => 'November',
          'O' => 'Oscar',
          'P' => 'Papa',
          'Q' => 'Quebec',
          'R' => 'Romeo',
          'S' => 'Sierra',
          'T' => 'Tango',
          'U' => 'Uniform',
          'V' => 'Victor',
          'W' => 'Whiskey',
          'X' => 'Xray',
          'Y' => 'Yankee',
          _ => 'Zulu',
        };
        return WordEntry(
          wordbookId: 1,
          word: '$name $index',
          meaning: 'Item $index',
          fields: const <WordFieldItem>[],
        );
      });

      await _pumpPage(
        tester,
        state: _FakeAppState.sample(words: words, uiLanguage: 'en'),
        child: const LibraryPage(),
      );

      await tester.tap(find.text('Open index'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Z').last);
      await tester.pumpAndSettle();

      expect(find.text('Zulu 25'), findsOneWidget);
    });

    testWidgets('data management page wires delete user data action', (
      tester,
    ) async {
      final state = _FakeAppState.sample(uiLanguage: 'en');
      await _pumpPage(tester, state: state, child: const DataManagementPage());

      await tester.tap(find.text('Delete user data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(state.resetUserDataCalled, true);
    });

    testWidgets('wordbook management shows quick actions and opens editor', (
      tester,
    ) async {
      final customBook = Wordbook(
        id: 7,
        name: 'Custom Pack',
        path: 'custom_pack',
        wordCount: 3,
        createdAt: null,
      );
      final words = <WordEntry>[
        const WordEntry(
          wordbookId: 7,
          word: 'Aurora',
          meaning: 'Dawn light',
          fields: <WordFieldItem>[],
        ),
        const WordEntry(
          wordbookId: 7,
          word: 'Borealis',
          meaning: 'Northern lights',
          fields: <WordFieldItem>[],
        ),
      ];
      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        words: words,
        selectedWordbook: customBook,
        wordbooks: <Wordbook>[customBook],
      );

      await _pumpPage(
        tester,
        state: state,
        child: const WordbookManagementPage(),
      );

      expect(find.text('New wordbook'), findsOneWidget);
      expect(find.text('Import wordbook'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Rename'), findsOneWidget);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Custom Pack'), findsWidgets);
      expect(find.text('Add word'), findsWidgets);
      expect(find.text('Aurora'), findsOneWidget);
    });

    testWidgets('wordbook management rename and import delegate to state', (
      tester,
    ) async {
      final customBook = Wordbook(
        id: 8,
        name: 'Starter Pack',
        path: 'custom_starter',
        wordCount: 1,
        createdAt: null,
      );
      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        selectedWordbook: customBook,
        wordbooks: <Wordbook>[customBook],
      );

      await _pumpPage(
        tester,
        state: state,
        child: const WordbookManagementPage(),
      );

      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Renamed Pack');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(state.renamedWordbookName, 'Renamed Pack');

      await tester.tap(find.text('Import wordbook'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Imported Pack');
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();

      expect(state.importedWordbookName, 'Imported Pack');
    });

    testWidgets('word card renders visible appearance effects', (tester) async {
      final appearance = PlayConfig.defaults.appearance.copyWith(
        rainbowText: true,
        marqueeText: true,
        breathingEffect: true,
        flowingEffect: true,
        fieldGradientAccent: true,
        fieldGlow: true,
        randomEntryColors: true,
      );
      final entry = WordEntry(
        wordbookId: 1,
        word: 'ExtraordinaryConstellationJourney',
        fields: const <WordFieldItem>[
          WordFieldItem(
            key: 'meaning',
            label: 'Meaning',
            value: 'A long sample meaning',
          ),
          WordFieldItem(
            key: 'etymology',
            label: 'Etymology',
            value: 'Layered roots and history',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(appearance),
          home: Scaffold(
            body: WordCard(word: entry, i18n: AppI18n('en')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ShaderMask), findsWidgets);
      expect(find.byType(ClipRect), findsWidgets);
    });
  });
}

void _noop() {}

Future<void> _pumpPage(
  WidgetTester tester, {
  required _FakeAppState state,
  required Widget child,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: MaterialApp(
        theme: buildAppTheme(state.config.appearance),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeAppState extends ChangeNotifier implements AppState {
  _FakeAppState({
    required PlayConfig config,
    required String uiLanguage,
    required Wordbook selectedWordbook,
    required List<Wordbook> wordbooks,
    required List<WordEntry> visibleWords,
    required List<String> localVoices,
  }) : _config = config,
       _uiLanguage = uiLanguage,
       _selectedWordbook = selectedWordbook,
       _wordbooks = wordbooks,
       _visibleWords = visibleWords,
       _localVoices = localVoices;

  factory _FakeAppState.sample({
    List<WordEntry>? words,
    String uiLanguage = 'zh',
    PlayConfig? config,
    Wordbook? selectedWordbook,
    List<Wordbook>? wordbooks,
  }) {
    final visibleWords =
        words ??
        const <WordEntry>[
          WordEntry(wordbookId: 1, word: 'Alpha', fields: <WordFieldItem>[]),
          WordEntry(wordbookId: 1, word: 'Beta', fields: <WordFieldItem>[]),
          WordEntry(wordbookId: 1, word: 'Gamma', fields: <WordFieldItem>[]),
        ];
    final resolvedSelectedWordbook =
        selectedWordbook ??
        Wordbook(
          id: 1,
          name: 'Default wordbook',
          path: 'builtin:sample',
          wordCount: visibleWords.length,
          createdAt: null,
        );
    final resolvedWordbooks = wordbooks ?? <Wordbook>[resolvedSelectedWordbook];
    return _FakeAppState(
      config: config ?? PlayConfig.defaults,
      uiLanguage: uiLanguage,
      selectedWordbook: resolvedSelectedWordbook,
      wordbooks: resolvedWordbooks,
      visibleWords: visibleWords,
      localVoices: const <String>['alex', 'anna'],
    ).._currentWord = visibleWords.firstOrNull;
  }

  PlayConfig _config;
  final String _uiLanguage;
  Wordbook? _selectedWordbook;
  List<Wordbook> _wordbooks;
  final List<WordEntry> _visibleWords;
  WordEntry? _currentWord;
  String? _lastBackupPath;
  final List<String> _localVoices;
  String _searchQuery = '';
  SearchMode _searchMode = SearchMode.all;
  bool resetUserDataCalled = false;
  String? createdWordbookName;
  String? renamedWordbookName;
  String? importedWordbookName;
  final Set<String> _favorites = <String>{};
  final Set<String> _taskWords = <String>{};
  final Map<AsrProviderType, AsrOfflineModelStatus> _offlineStatuses =
      <AsrProviderType, AsrOfflineModelStatus>{
        AsrProviderType.offline: const AsrOfflineModelStatus(
          provider: AsrProviderType.offline,
          installed: true,
          bytes: 150 * 1024 * 1024,
        ),
        AsrProviderType.offlineSmall: const AsrOfflineModelStatus(
          provider: AsrProviderType.offlineSmall,
          installed: false,
          bytes: 0,
        ),
      };
  final Map<PronScoringMethod, PronScoringPackStatus> _scoringStatuses =
      <PronScoringMethod, PronScoringPackStatus>{
        PronScoringMethod.sslEmbedding: const PronScoringPackStatus(
          method: PronScoringMethod.sslEmbedding,
          installed: true,
          bytes: 42 * 1024 * 1024,
        ),
        PronScoringMethod.gop: const PronScoringPackStatus(
          method: PronScoringMethod.gop,
          installed: false,
          bytes: 0,
        ),
        PronScoringMethod.forcedAlignmentPer: const PronScoringPackStatus(
          method: PronScoringMethod.forcedAlignmentPer,
          installed: false,
          bytes: 0,
        ),
        PronScoringMethod.ppgPosterior: const PronScoringPackStatus(
          method: PronScoringMethod.ppgPosterior,
          installed: false,
          bytes: 0,
        ),
      };

  @override
  PlayConfig get config => _config;

  @override
  WordEntry? get currentWord => _currentWord ?? _visibleWords.firstOrNull;

  @override
  Set<String> get favorites => _favorites;

  @override
  String? get lastBackupPath => _lastBackupPath;

  @override
  SearchMode get searchMode => _searchMode;

  @override
  String get searchQuery => _searchQuery;

  @override
  Wordbook? get selectedWordbook => _selectedWordbook;

  @override
  Set<String> get taskWords => _taskWords;

  @override
  String get uiLanguage => _uiLanguage;

  @override
  List<WordEntry> get words => _visibleWords;

  @override
  List<WordEntry> get visibleWords => _visibleWords;

  @override
  List<Wordbook> get wordbooks => _wordbooks;

  @override
  Future<List<String>> fetchLocalTtsVoices() async => _localVoices;

  @override
  Future<AsrOfflineModelStatus> getAsrOfflineModelStatus(
    AsrProviderType provider,
  ) async {
    return _offlineStatuses[provider] ??
        AsrOfflineModelStatus(provider: provider, installed: false, bytes: 0);
  }

  @override
  Future<PronScoringPackStatus> getPronScoringPackStatus(
    PronScoringMethod method,
  ) async {
    return _scoringStatuses[method] ??
        PronScoringPackStatus(method: method, installed: false, bytes: 0);
  }

  @override
  bool jumpByInitial(String initial) {
    final index = AppState.findJumpIndexByInitial(_visibleWords, initial);
    if (index < 0) return false;
    _currentWord = _visibleWords[index];
    notifyListeners();
    return true;
  }

  @override
  bool jumpByPrefix(String rawPrefix) {
    final index = AppState.findJumpIndexByPrefix(_visibleWords, rawPrefix);
    if (index < 0) return false;
    _currentWord = _visibleWords[index];
    notifyListeners();
    return true;
  }

  @override
  Future<void> prepareAsrOfflineModel(
    AsrProviderType provider, {
    AsrProgressCallback? onProgress,
  }) async {}

  @override
  Future<void> preparePronScoringPack(
    PronScoringMethod method, {
    AsrProgressCallback? onProgress,
  }) async {}

  @override
  Future<void> previewPronunciation(String word) async {}

  @override
  Future<void> removeAsrOfflineModel(AsrProviderType provider) async {}

  @override
  Future<void> removePronScoringPack(PronScoringMethod method) async {}

  @override
  Future<bool> resetUserData() async {
    resetUserDataCalled = true;
    _lastBackupPath = '/tmp/vocabulary_reset_backup.db';
    notifyListeners();
    return true;
  }

  @override
  Future<void> createWordbook(String name) async {
    createdWordbookName = name;
    final nextWordbook = Wordbook(
      id: _wordbooks.length + 100,
      name: name,
      path: 'custom_${_wordbooks.length + 100}',
      wordCount: 0,
      createdAt: null,
    );
    _wordbooks = <Wordbook>[..._wordbooks, nextWordbook];
    _selectedWordbook = nextWordbook;
    notifyListeners();
  }

  @override
  Future<void> deleteWord(WordEntry word) async {
    _visibleWords.removeWhere((item) => item.word == word.word);
    notifyListeners();
  }

  @override
  Future<void> deleteWordbook(Wordbook wordbook) async {
    _wordbooks = _wordbooks.where((item) => item.id != wordbook.id).toList();
    if (_selectedWordbook?.id == wordbook.id) {
      _selectedWordbook = _wordbooks.firstOrNull;
    }
    notifyListeners();
  }

  @override
  Future<void> importWordbookByPicker({
    Future<String?> Function(String suggestedName)? requestName,
  }) async {
    importedWordbookName =
        await requestName?.call('imported_wordbook') ?? 'imported_wordbook';
    notifyListeners();
  }

  @override
  Future<void> mergeWordbooks({
    required int sourceWordbookId,
    required int targetWordbookId,
    required bool deleteSourceAfterMerge,
  }) async {}

  @override
  Future<void> renameWordbook(Wordbook wordbook, String newName) async {
    renamedWordbookName = newName;
    _wordbooks = _wordbooks
        .map(
          (item) => item.id != wordbook.id
              ? item
              : Wordbook(
                  id: item.id,
                  name: newName,
                  path: item.path,
                  wordCount: item.wordCount,
                  createdAt: item.createdAt,
                ),
        )
        .toList(growable: false);
    if (_selectedWordbook?.id == wordbook.id) {
      _selectedWordbook = _wordbooks
          .where((item) => item.id == wordbook.id)
          .cast<Wordbook?>()
          .firstOrNull;
    }
    notifyListeners();
  }

  @override
  void selectWordEntry(WordEntry entry) {
    _currentWord = entry;
    notifyListeners();
  }

  @override
  Future<void> selectWordbook(
    Wordbook? wordbook, {
    String? focusWord,
    int? focusWordId,
  }) async {
    if (wordbook == null) return;
    _selectedWordbook = wordbook;
    if (!_wordbooks.any((book) => book.id == wordbook.id)) {
      _wordbooks = <Wordbook>[..._wordbooks, wordbook];
    }
    notifyListeners();
  }

  @override
  void setSearchMode(SearchMode mode) {
    _searchMode = mode;
    notifyListeners();
  }

  @override
  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  @override
  Future<void> toggleFavorite(WordEntry word) async {}

  @override
  Future<void> toggleTaskWord(WordEntry word) async {}

  @override
  void updateConfig(PlayConfig config) {
    _config = config;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

extension<T> on List<T> {
  T? get firstOrNull => this.isEmpty ? null : first;
}

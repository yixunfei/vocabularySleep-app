import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:vocabulary_sleep_app/src/i18n/app_i18n.dart';
import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/models/todo_item.dart';
import 'package:vocabulary_sleep_app/src/models/tomato_timer.dart';
import 'package:vocabulary_sleep_app/src/models/word_entry.dart';
import 'package:vocabulary_sleep_app/src/models/word_field.dart';
import 'package:vocabulary_sleep_app/src/models/wordbook.dart';
import 'package:vocabulary_sleep_app/src/services/ambient_service.dart';
import 'package:vocabulary_sleep_app/src/services/asr_service.dart';
import 'package:vocabulary_sleep_app/src/services/database_service.dart';
import 'package:vocabulary_sleep_app/src/services/focus_service.dart';
import 'package:vocabulary_sleep_app/src/state/app_state.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/appearance_studio_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/data_management_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/follow_along_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/focus_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/library_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/language_settings_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/practice_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/practice_session_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/recognition_settings_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/voice_settings_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/wordbook_management_page.dart';
import 'package:vocabulary_sleep_app/src/ui/theme/app_theme.dart';
import 'package:vocabulary_sleep_app/src/ui/ui_copy.dart';
import 'package:vocabulary_sleep_app/src/ui/widgets/ambient_floating_launcher.dart';
import 'package:vocabulary_sleep_app/src/ui/widgets/focus_lock_overlay.dart';
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

    testWidgets(
      'follow along keeps a safe provider when Windows loads local ASR config',
      (tester) async {
        final config = PlayConfig.defaults.copyWith(
          asr: PlayConfig.defaults.asr.copyWith(
            provider: AsrProviderType.multiEngine,
          ),
        );
        final state = _FakeAppState.sample(uiLanguage: 'en', config: config);
        const word = WordEntry(
          wordbookId: 1,
          word: 'Echo',
          fields: <WordFieldItem>[],
        );

        await _pumpPage(
          tester,
          state: state,
          child: const FollowAlongPage(word: word),
        );

        final expectedProvider =
            !kIsWeb && defaultTargetPlatform == TargetPlatform.windows
            ? asrProviderLabel(AppI18n('en'), AsrProviderType.api)
            : asrProviderLabel(AppI18n('en'), AsrProviderType.multiEngine);

        expect(find.textContaining(expectedProvider), findsWidgets);
      },
    );

    testWidgets('voice settings localizes preset voice labels in Japanese', (
      tester,
    ) async {
      final config = PlayConfig.defaults.copyWith(
        tts: PlayConfig.defaults.tts.copyWith(
          provider: TtsProviderType.api,
          model: 'FunAudioLLM/CosyVoice2-0.5B',
          voice: 'alex',
          remoteVoice: 'alex',
          remoteVoiceTypes: const <String>['alex'],
        ),
      );
      final state = _FakeAppState.sample(uiLanguage: 'ja', config: config);
      await _pumpPage(tester, state: state, child: const VoiceSettingsPage());

      expect(find.text('音声設定'), findsOneWidget);
      expect(find.textContaining('現在の音声：Alex'), findsOneWidget);
      expect(find.text('Voice settings'), findsNothing);
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

    testWidgets('recognition settings confirms before switching to local ASR', (
      tester,
    ) async {
      final state = _FakeAppState.sample(uiLanguage: 'en');
      await _pumpPage(
        tester,
        state: state,
        child: const RecognitionSettingsPage(),
      );

      final providerField = find.byType(DropdownButtonFormField<AsrProviderType>);

      await tester.tap(providerField.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Offline (Whisper Base)').last);
      await tester.pumpAndSettle();

      expect(find.text('Switch to local recognition?'), findsOneWidget);
      expect(
        find.textContaining('API recognition is recommended for better accuracy'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(state.config.asr.provider, AsrProviderType.api);

      await tester.tap(providerField.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Offline (Whisper Base)').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Switch anyway'));
      await tester.pumpAndSettle();
      expect(state.config.asr.provider, AsrProviderType.offline);
    });

    testWidgets('library page keeps prefix jump entry visible', (tester) async {
      final state = _FakeAppState.sample(uiLanguage: 'en');
      await _pumpPage(tester, state: state, child: const LibraryPage());

      expect(find.text('Prefix jump'), findsOneWidget);
      expect(find.text('Open index'), findsNothing);
    });

    testWidgets('library page hides alphabet index for non-Latin words', (
      tester,
    ) async {
      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        words: const <WordEntry>[
          WordEntry(wordbookId: 1, word: '睡眠', fields: <WordFieldItem>[]),
          WordEntry(wordbookId: 1, word: '专注', fields: <WordFieldItem>[]),
          WordEntry(wordbookId: 1, word: '放松', fields: <WordFieldItem>[]),
        ],
      );
      await _pumpPage(tester, state: state, child: const LibraryPage());

      expect(find.text('Prefix jump'), findsOneWidget);
      expect(find.text('Open index'), findsNothing);
      expect(find.text('All letters'), findsNothing);
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

    testWidgets('library page keeps prefix jump tools on narrow width', (
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

      expect(find.text('Prefix jump'), findsOneWidget);
      expect(find.text('Open index'), findsNothing);
      expect(find.text('All letters'), findsNothing);

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

    testWidgets('language settings includes Russian localization option', (
      tester,
    ) async {
      final state = _FakeAppState.sample(uiLanguage: 'ru');
      await _pumpPage(
        tester,
        state: state,
        child: const LanguageSettingsPage(),
      );

      expect(find.text('Настройки языка'), findsOneWidget);
      expect(find.text('Русский'), findsWidgets);
      expect(find.text('Language settings'), findsNothing);
    });

    testWidgets('focus page opens and closes notes drawer from side rail', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        focusService: _FakeFocusService.sample(),
      );
      await _pumpPage(tester, state: state, child: const FocusPage());

      await tester.tap(find.text('Tasks & Notes').first);
      await tester.pumpAndSettle();

      final drawerFinder = find.byKey(const ValueKey<String>('notes-drawer'));
      final handleFinder = find.byKey(
        const ValueKey<String>('notes-drawer-handle'),
      );
      final addTaskButtonFinder = find.text('Add task');

      final collapsedLeft = tester.getTopLeft(drawerFinder).dx;
      final collapsedHandleLeft = tester.getTopLeft(handleFinder).dx;
      final addTaskButtonRight = tester.getTopRight(addTaskButtonFinder).dx;
      expect(addTaskButtonRight, lessThan(collapsedHandleLeft - 4));

      await tester.tap(handleFinder);
      await tester.pumpAndSettle();

      final expandedLeft = tester.getTopLeft(drawerFinder).dx;
      expect(expandedLeft, lessThan(collapsedLeft - 100));

      await tester.drag(drawerFinder, const Offset(260, 0));
      await tester.pumpAndSettle();

      final collapsedAgainLeft = tester.getTopLeft(drawerFinder).dx;
      expect(collapsedAgainLeft, greaterThan(expandedLeft + 100));
    });

    testWidgets('focus page opens todo details editor and saves rich todo', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final focusService = _FakeFocusService.sample();
      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        focusService: focusService,
      );
      await _pumpPage(tester, state: state, child: const FocusPage());

      await tester.tap(find.text('Tasks & Notes').first);
      await tester.pumpAndSettle();

      final addTaskButton = find.widgetWithText(TextButton, 'Add task');
      await tester.ensureVisible(addTaskButton);
      await tester.tap(addTaskButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey<String>('todo-title-field')),
        'Write bilingual release notes',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('todo-category-field')),
        'Review',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('todo-note-field')),
        'Capture UI polish and localization updates.',
      );
      await tester.tap(find.text('High'));
      final saveButton = find.byKey(const ValueKey<String>('todo-save-button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        focusService.getTodos().any(
          (todo) =>
              todo.content == 'Write bilingual release notes' &&
              todo.category == 'Review' &&
              todo.note == 'Capture UI polish and localization updates.' &&
              todo.priority == 2,
        ),
        isTrue,
      );
      expect(
        find.byKey(const ValueKey<String>('todo-title-field')),
        findsNothing,
      );
    });

    testWidgets('focus page supports deferred todo status and filter', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final focusService = _FakeFocusService.sample();
      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        focusService: focusService,
      );
      await _pumpPage(tester, state: state, child: const FocusPage());

      await tester.tap(find.text('Tasks & Notes').first);
      await tester.pumpAndSettle();

      final addTaskButton = find.widgetWithText(TextButton, 'Add task');
      await tester.ensureVisible(addTaskButton);
      await tester.tap(addTaskButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey<String>('todo-title-field')),
        'Park backlog cleanup',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('todo-status-deferred')),
      );
      final saveButton = find.byKey(const ValueKey<String>('todo-save-button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        focusService.getTodos().any(
          (todo) => todo.content == 'Park backlog cleanup' && todo.isDeferred,
        ),
        isTrue,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('todo-filter-deferred')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Park backlog cleanup'), findsOneWidget);
      expect(find.text('Prepare review notes'), findsNothing);
    });

    testWidgets('focus page quick notes support voice input', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final focusService = _FakeFocusService.sample();
      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        focusService: focusService,
        asrRecordingPath: 'temp-note.wav',
        asrStoppedRecordingPath: 'temp-note.wav',
        asrTranscriptionResult: const AsrResult(
          success: true,
          text: 'Capture release review highlights',
        ),
      );
      await _pumpPage(tester, state: state, child: const FocusPage());

      await tester.tap(find.text('Tasks & Notes').first);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('notes-drawer-handle')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.note_add_rounded).last);
      await tester.pumpAndSettle();

      final voiceButton = find.byKey(
        const ValueKey<String>('note-voice-input-button'),
      );
      await tester.tap(voiceButton);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: voiceButton,
          matching: find.text('Tap to stop recording'),
        ),
        findsOneWidget,
      );

      await tester.tap(voiceButton);
      await tester.pumpAndSettle();

      final titleField = tester.widget<TextField>(
        find.byKey(const ValueKey<String>('note-title-field')),
      );
      final contentField = tester.widget<TextField>(
        find.byKey(const ValueKey<String>('note-content-field')),
      );
      expect(titleField.controller?.text ?? '', isEmpty);
      expect(
        contentField.controller?.text ?? '',
        'Capture release review highlights',
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        focusService.getNotes().any(
          (note) =>
              note.title.isNotEmpty &&
              note.content == 'Capture release review highlights',
        ),
        isTrue,
      );
    });

    testWidgets('focus page keeps timer stepper stable on narrow width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        focusService: _FakeFocusService.sample(),
      );
      await _pumpPage(tester, state: state, child: const FocusPage());

      expect(tester.takeException(), isNull);
      expect(find.text('Timer'), findsOneWidget);
    });

    testWidgets('focus page keeps duration pickers wheel only', (tester) async {
      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        focusService: _FakeFocusService.sample(),
      );
      await _pumpPage(tester, state: state, child: const FocusPage());

      expect(find.text('Wheel picker'), findsNWidgets(2));
      expect(find.byType(ChoiceChip), findsNothing);
    });

    testWidgets('app shell opens ambient sheet from global launcher', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        focusService: _FakeFocusService.sample(),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
            theme: buildAppTheme(state.config.appearance),
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AmbientFloatingLauncher(
                    state: state,
                    i18n: AppI18n('en'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('global-ambient-launcher')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('global-ambient-launcher')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('ambient-sheet')),
        findsOneWidget,
      );
    });

    testWidgets('focus page filters active and completed todos', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        focusService: _FakeFocusService.sample(),
      );
      await _pumpPage(tester, state: state, child: const FocusPage());

      await tester.tap(find.text('Tasks & Notes').first);
      await tester.pumpAndSettle();

      expect(find.text('Prepare review notes'), findsOneWidget);
      expect(find.text('Ship focus page polish'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('todo-filter-completed')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('todo-filter-completed')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ship focus page polish'), findsOneWidget);
      expect(find.text('Prepare review notes'), findsNothing);

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('todo-filter-active')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('todo-filter-active')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prepare review notes'), findsOneWidget);
      expect(find.text('Ship focus page polish'), findsNothing);
    });

    testWidgets('focus page toggles compact todo metrics on narrow width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        focusService: _FakeFocusService.sample(),
      );
      await _pumpPage(tester, state: state, child: const FocusPage());

      await tester.tap(find.text('Tasks & Notes').first);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('todo-metric-card-active')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('todo-metrics-toggle')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('todo-metric-card-active')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('todo-metric-card-completed')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('focus page groups todos in plan view and toggles list view', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final tomorrowStart = todayStart.add(const Duration(days: 1));
      final focusService = _FakeFocusService(
        todos: <TodoItem>[
          TodoItem(
            id: 1,
            content: 'Rescue overdue draft',
            priority: 2,
            dueAt: todayStart.subtract(const Duration(hours: 2)),
          ),
          TodoItem(
            id: 2,
            content: 'Ship today summary',
            dueAt: todayStart.add(const Duration(hours: 10)),
          ),
          TodoItem(
            id: 3,
            content: 'Prepare next review',
            dueAt: tomorrowStart.add(const Duration(hours: 9)),
          ),
          const TodoItem(id: 4, content: 'Inbox capture'),
          const TodoItem(id: 5, content: 'Closed loop', completed: true),
        ],
      );
      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        focusService: focusService,
      );

      await _pumpPage(tester, state: state, child: const FocusPage());

      await tester.tap(find.text('Tasks & Notes').first);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('todo-plan-overdue')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('todo-plan-today')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('todo-plan-upcoming')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('todo-plan-inbox')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('todo-plan-completed')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('todo-view-list')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('todo-view-list')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('todo-plan-overdue')),
        findsNothing,
      );
      expect(find.text('Rescue overdue draft'), findsOneWidget);
      expect(find.text('Ship today summary'), findsOneWidget);
    });

    testWidgets('focus lock overlay renders when focus is locked', (
      tester,
    ) async {
      final focusService = _FakeFocusService(
        lockScreenActive: true,
        state: const TomatoTimerState(
          phase: TomatoTimerPhase.focus,
          currentRound: 1,
          remainingSeconds: 10 * 60,
          totalSeconds: 25 * 60,
        ),
      );
      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        focusService: focusService,
      );

      await _pumpPage(tester, state: state, child: const FocusLockOverlay());

      expect(find.text('Focusing'), findsOneWidget);
      expect(find.text('Long press to exit focus'), findsOneWidget);
    });

    testWidgets('library prefix jump scrolls lazy list to target word', (
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

      await tester.tap(find.text('Prefix jump'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Zu');
      await tester.tap(find.text('OK'));
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

    testWidgets('data management page wires restore backup action', (
      tester,
    ) async {
      final backup = DatabaseBackupInfo(
        name: 'vocabulary_manual_2026-03-12T10-00-00.db',
        path: '/tmp/vocabulary_manual_2026-03-12T10-00-00.db',
        reason: 'manual',
        modifiedAt: DateTime(2026, 3, 12, 10),
        sizeBytes: 2048,
      );
      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        backups: <DatabaseBackupInfo>[backup],
      );
      await _pumpPage(tester, state: state, child: const DataManagementPage());

      await tester.scrollUntilVisible(
        find.text('Restore backup'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Restore this backup'), findsOneWidget);

      await tester.tap(find.text('Restore this backup'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();

      expect(state.restoredBackupPath, backup.path);
    });

    testWidgets('data management page wires export user data action', (
      tester,
    ) async {
      final state = _FakeAppState.sample(uiLanguage: 'en');
      await _pumpPage(tester, state: state, child: const DataManagementPage());

      await tester.tap(find.text('Export user data'));
      await tester.pumpAndSettle();

      expect(
        state.exportedUserDataPath,
        '/tmp/vocabulary_user_data_export.json',
      );
    });

    testWidgets('data management page wires delete backup action', (
      tester,
    ) async {
      final backup = DatabaseBackupInfo(
        name: 'vocabulary_manual_2026-03-12T10-00-00.db',
        path: '/tmp/vocabulary_manual_2026-03-12T10-00-00.db',
        reason: 'manual',
        modifiedAt: DateTime(2026, 3, 12, 10),
        sizeBytes: 2048,
      );
      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        backups: <DatabaseBackupInfo>[backup],
      );
      await _pumpPage(tester, state: state, child: const DataManagementPage());

      await tester.scrollUntilVisible(
        find.text('Restore backup'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(state.deletedBackupPath, backup.path);
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
      expect(find.text('Download online wordbooks'), findsOneWidget);
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
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Imported Pack');
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();

      expect(state.importedWordbookName, 'Imported Pack');
    });

    testWidgets('wordbook management allows deleting removable built-ins', (
      tester,
    ) async {
      final builtinBook = Wordbook(
        id: 9,
        name: 'Built-in Pack',
        path: 'builtin:dict:starter',
        wordCount: 12,
        createdAt: null,
      );
      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        selectedWordbook: builtinBook,
        wordbooks: <Wordbook>[builtinBook],
      );

      await _pumpPage(
        tester,
        state: state,
        child: const WordbookManagementPage(),
      );

      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(state.wordbooks, isEmpty);
    });

    testWidgets('practice page shows quick start and stats badges', (
      tester,
    ) async {
      final state = _FakeAppState.sample(uiLanguage: 'en');
      await _pumpPage(tester, state: state, child: const PracticePage());

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('practice-memory-card')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('practice-memory-card')),
        findsOneWidget,
      );
      expect(find.text('Memory lanes'), findsOneWidget);
      expect(find.text('Remembered today'), findsOneWidget);
      expect(find.text('Recovery queue'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Quick start'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Quick start'), findsOneWidget);
      expect(find.text('7-word warmup'), findsOneWidget);
      expect(find.text('Shuffle sprint'), findsOneWidget);
    });

    testWidgets('practice page shows clean Chinese labels', (tester) async {
      final state = _FakeAppState.sample(uiLanguage: 'zh');
      await _pumpPage(tester, state: state, child: const PracticePage());

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('practice-memory-card')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('\u8bb0\u5fc6\u8f68\u9053'), findsOneWidget);
      expect(find.text('\u4eca\u65e5\u5df2\u8bb0\u4f4f'), findsOneWidget);
      expect(find.text('\u6062\u590d\u961f\u5217'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('\u5feb\u901f\u5f00\u59cb'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('\u5feb\u901f\u5f00\u59cb'), findsOneWidget);
      expect(find.text('\u5f53\u524d\u8bcd\u901f\u7ec3'), findsWidgets);
      expect(find.textContaining('\u8930\u64b3'), findsNothing);
    });

    testWidgets('practice session result uses clean Chinese labels', (
      tester,
    ) async {
      final state = _FakeAppState.sample(uiLanguage: 'zh');
      const words = <WordEntry>[
        WordEntry(
          wordbookId: 1,
          word: 'alpha',
          fields: <WordFieldItem>[
            WordFieldItem(key: 'meaning', label: '含义', value: '开始'),
          ],
        ),
      ];

      await _pumpPage(
        tester,
        state: state,
        child: const PracticeSessionPage(title: '测试练习', words: words),
      );

      expect(find.text('\u663e\u793a\u63d0\u793a'), findsOneWidget);
      expect(find.text('\u6ca1\u8bb0\u4f4f'), findsOneWidget);

      await tester.tap(find.text('\u8bb0\u4f4f\u4e86'));
      await tester.pumpAndSettle();

      expect(find.text('\u5df2\u8bb0\u4f4f\u5355\u8bcd'), findsOneWidget);
      expect(find.text('\u590d\u4e60\u5df2\u8bb0\u4f4f'), findsOneWidget);
      expect(find.textContaining('\u5bb8\u8336'), findsNothing);
    });

    testWidgets('practice session can auto-add missed words to task list', (
      tester,
    ) async {
      final state = _FakeAppState.sample(uiLanguage: 'en');
      const words = <WordEntry>[
        WordEntry(wordbookId: 1, word: 'alpha', fields: <WordFieldItem>[]),
        WordEntry(wordbookId: 1, word: 'bravo', fields: <WordFieldItem>[]),
      ];

      await _pumpPage(
        tester,
        state: state,
        child: const PracticeSessionPage(title: 'Task sync', words: words),
      );

      expect(state.taskWords, isEmpty);

      await tester.tap(find.text('Not yet'));
      await tester.pumpAndSettle();
      expect(state.taskWords, isEmpty);

      await tester.tap(
        find.byKey(const ValueKey<String>('practice-auto-task-switch')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Not yet'));
      await tester.pumpAndSettle();

      expect(state.taskWords.contains('alpha'), isFalse);
      expect(state.taskWords.contains('bravo'), isTrue);
    });

    test('online wordbook catalog parses repo html payload', () {
      const html =
          '<script data-target="react-app.embeddedData">'
          '{"payload":{"codeViewRepoRoute":{"tree":{"items":['
          '{"name":"中英_12000.json","path":"中英_12000.json","contentType":"file"},'
          '{"name":"notes.txt","path":"notes.txt","contentType":"file"},'
          '{"name":"英法_12000.json","path":"英法_12000.json","contentType":"file"}'
          ']}}}}</script>';

      final entries = GitHubWordbookCatalog.parseRepositoryHtml(html);

      expect(entries.map((item) => item.fileName), <String>[
        '中英_12000.json',
        '英法_12000.json',
      ]);
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
    required List<DatabaseBackupInfo> backups,
    required FocusService focusService,
    required List<AmbientSource> ambientSources,
    required double ambientMasterVolume,
    required String? asrRecordingPath,
    required String? asrStoppedRecordingPath,
    required AsrResult asrTranscriptionResult,
  }) : _config = config,
       _uiLanguage = uiLanguage,
       _uiLanguageFollowsSystem = false,
       _selectedWordbook = selectedWordbook,
       _wordbooks = wordbooks,
       _visibleWords = visibleWords,
       _localVoices = localVoices,
       _backups = backups,
       _focusService = focusService,
       _ambientSources = ambientSources,
       _ambientMasterVolume = ambientMasterVolume,
       _asrRecordingPath = asrRecordingPath,
       _asrStoppedRecordingPath = asrStoppedRecordingPath,
       _asrTranscriptionResult = asrTranscriptionResult;

  factory _FakeAppState.sample({
    List<WordEntry>? words,
    String uiLanguage = 'zh',
    PlayConfig? config,
    Wordbook? selectedWordbook,
    List<Wordbook>? wordbooks,
    List<DatabaseBackupInfo>? backups,
    FocusService? focusService,
    List<AmbientSource>? ambientSources,
    String? asrRecordingPath,
    String? asrStoppedRecordingPath,
    AsrResult? asrTranscriptionResult,
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
      backups: backups ?? const <DatabaseBackupInfo>[],
      focusService: focusService ?? _FakeFocusService.sample(),
      ambientSources:
          ambientSources ??
          const <AmbientSource>[
            AmbientSource(
              id: 'rain_soft',
              name: 'Soft Rain',
              assetPath: 'assets/audio/rain.mp3',
            ),
          ],
      ambientMasterVolume: 0.55,
      asrRecordingPath: asrRecordingPath,
      asrStoppedRecordingPath: asrStoppedRecordingPath,
      asrTranscriptionResult:
          asrTranscriptionResult ??
          const AsrResult(success: false, error: 'recognitionFailed'),
    ).._currentWord = visibleWords.firstOrNull;
  }

  PlayConfig _config;
  String _uiLanguage;
  bool _uiLanguageFollowsSystem;
  Wordbook? _selectedWordbook;
  List<Wordbook> _wordbooks;
  final List<WordEntry> _visibleWords;
  WordEntry? _currentWord;
  String? _lastBackupPath;
  final List<String> _localVoices;
  final List<DatabaseBackupInfo> _backups;
  final FocusService _focusService;
  List<AmbientSource> _ambientSources;
  double _ambientMasterVolume;
  final String? _asrRecordingPath;
  final String? _asrStoppedRecordingPath;
  final AsrResult _asrTranscriptionResult;
  String _searchQuery = '';
  SearchMode _searchMode = SearchMode.all;
  bool resetUserDataCalled = false;
  String? restoredBackupPath;
  String? deletedBackupPath;
  String? exportedUserDataPath;
  String? createdWordbookName;
  String? renamedWordbookName;
  String? importedWordbookName;
  String? importedWordbookFilePath;
  final int _practiceTodaySessions = 2;
  final int _practiceTodayReviewed = 9;
  final int _practiceTodayRemembered = 7;
  final int _practiceTotalSessions = 6;
  final int _practiceTotalReviewed = 28;
  final int _practiceTotalRemembered = 22;
  final String _practiceLastSessionTitle = 'Scope sprint';
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
  List<AmbientSource> get ambientSources => _ambientSources;

  @override
  double get ambientMasterVolume => _ambientMasterVolume;

  @override
  WordEntry? get currentWord => _currentWord ?? _visibleWords.firstOrNull;

  @override
  bool get isPlaying => false;

  @override
  Set<String> get favorites => _favorites;

  @override
  FocusService get focusService => _focusService;

  @override
  String? get lastBackupPath => _lastBackupPath;

  @override
  String get practiceLastSessionTitle => _practiceLastSessionTitle;

  @override
  List<String> get practiceRememberedWords => recentRememberedWordEntries
      .map((entry) => entry.word)
      .toList(growable: false);

  @override
  int get practiceTodayReviewed => _practiceTodayReviewed;

  @override
  int get practiceTodayRemembered => _practiceTodayRemembered;

  @override
  int get practiceTodaySessions => _practiceTodaySessions;

  @override
  double get practiceTodayAccuracy => _practiceTodayReviewed == 0
      ? 0
      : _practiceTodayRemembered / _practiceTodayReviewed;

  @override
  double get practiceTotalAccuracy => _practiceTotalReviewed == 0
      ? 0
      : _practiceTotalRemembered / _practiceTotalReviewed;

  @override
  int get practiceTotalRemembered => _practiceTotalRemembered;

  @override
  int get practiceTotalReviewed => _practiceTotalReviewed;

  @override
  int get practiceTotalSessions => _practiceTotalSessions;

  @override
  List<WordEntry> get recentRememberedWordEntries =>
      _visibleWords.length < 3 ? _visibleWords : _visibleWords.sublist(1, 3);

  @override
  List<WordEntry> get recentWeakWordEntries =>
      _visibleWords.length < 2 ? _visibleWords : _visibleWords.sublist(0, 2);

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
  bool get uiLanguageFollowsSystem => _uiLanguageFollowsSystem;

  @override
  String get uiLanguageSelection =>
      _uiLanguageFollowsSystem ? 'system' : _uiLanguage;

  @override
  List<WordEntry> get words => _visibleWords;

  @override
  List<WordEntry> get visibleWords => _visibleWords;

  @override
  List<Wordbook> get wordbooks => _wordbooks;

  @override
  bool requiresWordbookLoadConfirmation(Wordbook wordbook) => false;

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
  Future<String?> startAsrRecording({AsrProviderType? provider}) async =>
      _asrRecordingPath;

  @override
  Future<String?> stopAsrRecording() async =>
      _asrStoppedRecordingPath ?? _asrRecordingPath;

  @override
  Future<void> cancelAsrRecording() async {}

  @override
  void stopAsrProcessing() {}

  @override
  Future<AsrResult> transcribeRecording(
    String audioPath, {
    String? expectedText,
    AsrProviderType? provider,
    AsrProgressCallback? onProgress,
  }) async {
    onProgress?.call(
      const AsrProgress(
        stage: 'decoding',
        messageKey: 'asrProgressDecoding',
        progress: 1,
      ),
    );
    return _asrTranscriptionResult;
  }

  @override
  Future<void> previewPronunciation(String word) async {}

  @override
  Future<void> addAmbientFileSource() async {}

  @override
  Future<void> removeAsrOfflineModel(AsrProviderType provider) async {}

  @override
  Future<void> removePronScoringPack(PronScoringMethod method) async {}

  @override
  Future<void> removeAmbientSource(String sourceId) async {
    _ambientSources = _ambientSources
        .where((source) => source.id != sourceId)
        .toList(growable: false);
    notifyListeners();
  }

  @override
  Future<void> setAmbientMasterVolume(double value) async {
    _ambientMasterVolume = value;
    notifyListeners();
  }

  @override
  Future<void> setAmbientSourceEnabled(String sourceId, bool enabled) async {
    _ambientSources = _ambientSources
        .map(
          (source) => source.id == sourceId
              ? source.copyWith(enabled: enabled)
              : source,
        )
        .toList(growable: false);
    notifyListeners();
  }

  @override
  Future<void> setAmbientSourceVolume(String sourceId, double value) async {
    _ambientSources = _ambientSources
        .map(
          (source) =>
              source.id == sourceId ? source.copyWith(volume: value) : source,
        )
        .toList(growable: false);
    notifyListeners();
  }

  @override
  Future<bool> resetUserData() async {
    resetUserDataCalled = true;
    _lastBackupPath = '/tmp/vocabulary_reset_backup.db';
    notifyListeners();
    return true;
  }

  @override
  Future<List<DatabaseBackupInfo>> listDatabaseBackups() async => _backups;

  @override
  Future<bool> deleteDatabaseBackup(DatabaseBackupInfo backup) async {
    deletedBackupPath = backup.path;
    notifyListeners();
    return true;
  }

  @override
  Future<String?> exportUserData() async {
    exportedUserDataPath = '/tmp/vocabulary_user_data_export.json';
    notifyListeners();
    return exportedUserDataPath;
  }

  @override
  Future<bool> restoreDatabaseBackup(DatabaseBackupInfo backup) async {
    restoredBackupPath = backup.path;
    _lastBackupPath = '/tmp/vocabulary_before_restore_backup.db';
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
  Future<void> importWordbookFile(String filePath, String name) async {
    importedWordbookFilePath = filePath;
    importedWordbookName = name;
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
  Future<void> toggleTaskWord(WordEntry word) async {
    if (_taskWords.contains(word.word)) {
      _taskWords.remove(word.word);
    } else {
      _taskWords.add(word.word);
    }
    notifyListeners();
  }

  @override
  void recordPracticeSession({
    required String title,
    required int total,
    required int remembered,
    required List<String> rememberedWords,
    required List<String> weakWords,
  }) {}

  @override
  void setUiLanguage(String language) {
    _uiLanguage = AppI18n.normalizeLanguageCode(language);
    _uiLanguageFollowsSystem = false;
    notifyListeners();
  }

  @override
  void setUiLanguageFollowSystem() {
    _uiLanguageFollowsSystem = true;
    notifyListeners();
  }

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

class _FakeFocusService extends ChangeNotifier implements FocusService {
  _FakeFocusService({
    TomatoTimerConfig? config,
    TomatoTimerState? state,
    List<TodoItem>? todos,
    List<PlanNote>? notes,
    bool lockScreenActive = false,
    bool reminderAcknowledgementPending = false,
    TomatoTimerPhase? pendingReminderPhase,
  }) : _config = config ?? const TomatoTimerConfig(workspaceSplitRatio: 0.42),
       _state =
           state ??
           const TomatoTimerState(
             phase: TomatoTimerPhase.focus,
             currentRound: 1,
             remainingSeconds: 20 * 60,
             totalSeconds: 25 * 60,
           ),
       _todos = List<TodoItem>.from(
         todos ??
             const <TodoItem>[
               TodoItem(id: 1, content: 'Prepare review notes'),
               TodoItem(
                 id: 2,
                 content: 'Ship focus page polish',
                 completed: true,
               ),
             ],
       ),
       _lockScreenActive = lockScreenActive,
       _reminderAcknowledgementPending = reminderAcknowledgementPending,
       _pendingReminderPhase = pendingReminderPhase,
       _notes = List<PlanNote>.from(
         notes ??
             const <PlanNote>[
               PlanNote(
                 id: 1,
                 title: 'Plan recap',
                 content: 'Open the drawer to inspect note details.',
               ),
               PlanNote(
                 id: 2,
                 title: 'Voice cue',
                 content: 'Keep the end reminder short and calm.',
               ),
             ],
       );

  factory _FakeFocusService.sample() => _FakeFocusService();

  TomatoTimerConfig _config;
  TomatoTimerState _state;
  bool _lockScreenActive;
  bool _reminderAcknowledgementPending;
  TomatoTimerPhase? _pendingReminderPhase;
  final List<TodoItem> _todos;
  final List<PlanNote> _notes;

  @override
  TomatoTimerConfig get config => _config;

  @override
  bool get initialized => true;

  @override
  bool get lockScreenActive => _lockScreenActive;

  @override
  bool get reminderAcknowledgementPending => _reminderAcknowledgementPending;

  @override
  TomatoTimerPhase? get pendingReminderPhase => _pendingReminderPhase;

  @override
  TomatoTimerState get state => _state;

  @override
  void setLockScreenActive(bool value) {
    _lockScreenActive = value;
    notifyListeners();
  }

  @override
  Future<void> acknowledgeReminder() async {
    _reminderAcknowledgementPending = false;
    _pendingReminderPhase = null;
    notifyListeners();
  }

  @override
  void addNote(String title, String? content, String? color) {
    _notes.add(
      PlanNote(
        id: (_notes.lastOrNull?.id ?? 0) + 1,
        title: title,
        content: content,
        color: color,
      ),
    );
    notifyListeners();
  }

  @override
  void addTodo(
    String content, {
    int priority = 1,
    String? category,
    String? note,
    String? color,
    DateTime? dueAt,
    bool alarmEnabled = false,
  }) {
    _todos.add(
      TodoItem(
        id: (_todos.lastOrNull?.id ?? 0) + 1,
        content: content,
        priority: priority,
        category: category,
        note: note,
        color: color,
        dueAt: dueAt,
        alarmEnabled: alarmEnabled,
      ),
    );
    notifyListeners();
  }

  @override
  void advanceToNextPhase() {
    _state = const TomatoTimerState();
    notifyListeners();
  }

  @override
  void clearCompletedTodos() {
    _todos.removeWhere((todo) => todo.completed);
    notifyListeners();
  }

  @override
  void deleteNote(int id) {
    _notes.removeWhere((note) => note.id == id);
    notifyListeners();
  }

  @override
  void deleteNotes(List<int> ids) {
    _notes.removeWhere((note) => ids.contains(note.id));
    notifyListeners();
  }

  @override
  void deleteTodo(int id) {
    _todos.removeWhere((todo) => todo.id == id);
    notifyListeners();
  }

  @override
  List<PlanNote> getNotes() => List<PlanNote>.unmodifiable(_notes);

  @override
  int getTodayFocusMinutes() => 45;

  @override
  int getTodayRoundsCompleted() => 2;

  @override
  int getTodaySessionMinutes() => 60;

  @override
  List<TodoItem> getTodos() => List<TodoItem>.unmodifiable(_todos);

  @override
  Future<void> init() async {}

  @override
  void pause() {
    _state = _state.copyWith(isPaused: true);
    notifyListeners();
  }

  @override
  void reorderNotes(List<PlanNote> orderedNotes) {
    _notes
      ..clear()
      ..addAll(orderedNotes);
    notifyListeners();
  }

  @override
  void reorderTodos(List<TodoItem> orderedTodos) {
    _todos
      ..clear()
      ..addAll(orderedTodos);
    notifyListeners();
  }

  @override
  void resume() {
    _state = _state.copyWith(isPaused: false);
    notifyListeners();
  }

  @override
  void saveConfig(TomatoTimerConfig config) {
    _config = config;
    notifyListeners();
  }

  @override
  void saveTodo(TodoItem item) {
    final normalized = item.copyWith(
      deferred: item.completed ? false : item.deferred,
      completedAt: item.completed ? item.completedAt : null,
    );
    final index = _todos.indexWhere((todo) => todo.id == item.id);
    if (index >= 0) {
      _todos[index] = normalized;
    } else {
      _todos.add(
        normalized.copyWith(id: (_todos.lastOrNull?.id ?? 0) + 1),
      );
    }
    notifyListeners();
  }

  @override
  void saveReminderConfig(TimerReminderConfig reminder) {
    _config = _config.copyWith(reminder: reminder);
    notifyListeners();
  }

  @override
  void saveWorkspaceSplitRatio(double ratio) {
    _config = _config.copyWith(workspaceSplitRatio: ratio);
    notifyListeners();
  }

  @override
  void setCallbacks({
    void Function(TomatoTimerState p1)? onTick,
    void Function(TomatoTimerPhase p1, int p2)? onPhaseComplete,
  }) {}

  @override
  void skip() {
    _state = _state.copyWith(
      remainingSeconds: (_state.remainingSeconds - 60).clamp(
        0,
        _state.totalSeconds,
      ),
    );
    notifyListeners();
  }

  @override
  void start({
    int? focusDurationSeconds,
    int? breakDurationSeconds,
    int? focusMinutes,
    int? breakMinutes,
    int? rounds,
  }) {
    final nextFocusSeconds =
        focusDurationSeconds ??
        (focusMinutes != null
            ? focusMinutes * 60
            : _config.focusDurationSeconds);
    _config = _config.copyWith(
      focusDurationSeconds: nextFocusSeconds,
      breakDurationSeconds:
          breakDurationSeconds ??
          (breakMinutes != null
              ? breakMinutes * 60
              : _config.breakDurationSeconds),
      rounds: rounds,
    );
    _state = TomatoTimerState(
      phase: TomatoTimerPhase.focus,
      currentRound: 1,
      remainingSeconds: nextFocusSeconds,
      totalSeconds: nextFocusSeconds,
    );
    notifyListeners();
  }

  @override
  void stop({bool saveProgress = true}) {
    _state = const TomatoTimerState();
    notifyListeners();
  }

  @override
  void toggleTodo(int id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index < 0) return;
    final current = _todos[index];
    final nextCompleted = !current.completed;
    _todos[index] = current.copyWith(
      completed: nextCompleted,
      deferred: false,
      completedAt: nextCompleted ? DateTime(2026, 3, 14) : null,
    );
    notifyListeners();
  }

  @override
  void updateNote(PlanNote note) {
    final index = _notes.indexWhere((item) => item.id == note.id);
    if (index < 0) return;
    _notes[index] = note;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

extension<T> on List<T> {
  T? get firstOrNull => this.isEmpty ? null : first;

  T? get lastOrNull => this.isEmpty ? null : last;
}

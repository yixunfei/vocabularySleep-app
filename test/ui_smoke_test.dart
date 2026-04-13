import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:vocabulary_sleep_app/src/i18n/app_i18n.dart';
import 'package:vocabulary_sleep_app/src/models/ambient_preset.dart';
import 'package:vocabulary_sleep_app/src/models/app_home_tab.dart';
import 'package:vocabulary_sleep_app/src/models/focus_startup_tab.dart';
import 'package:vocabulary_sleep_app/src/models/export_dto.dart';
import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/models/practice_export_format.dart';
import 'package:vocabulary_sleep_app/src/models/practice_question_type.dart';
import 'package:vocabulary_sleep_app/src/models/practice_session_record.dart';
import 'package:vocabulary_sleep_app/src/models/settings_dto.dart';
import 'package:vocabulary_sleep_app/src/models/sleep_daily_log.dart';
import 'package:vocabulary_sleep_app/src/models/sleep_plan.dart';
import 'package:vocabulary_sleep_app/src/models/sleep_profile.dart';
import 'package:vocabulary_sleep_app/src/models/sleep_routine_template.dart';
import 'package:vocabulary_sleep_app/src/models/study_startup_tab.dart';
import 'package:vocabulary_sleep_app/src/models/todo_item.dart';
import 'package:vocabulary_sleep_app/src/models/tomato_timer.dart';
import 'package:vocabulary_sleep_app/src/models/user_data_export.dart';
import 'package:vocabulary_sleep_app/src/models/weather_snapshot.dart';
import 'package:vocabulary_sleep_app/src/models/word_entry.dart';
import 'package:vocabulary_sleep_app/src/models/word_field.dart';
import 'package:vocabulary_sleep_app/src/models/word_memory_progress.dart';
import 'package:vocabulary_sleep_app/src/models/wordbook.dart';
import 'package:vocabulary_sleep_app/src/services/ambient_service.dart';
import 'package:vocabulary_sleep_app/src/services/asr_service.dart';
import 'package:vocabulary_sleep_app/src/services/cstcloud_resource_cache_service.dart';
import 'package:vocabulary_sleep_app/src/services/database_service.dart';
import 'package:vocabulary_sleep_app/src/services/focus_service.dart';
import 'package:vocabulary_sleep_app/src/services/online_ambient_catalog_service.dart';
import 'package:vocabulary_sleep_app/src/services/todo_reminder_service.dart';
import 'package:vocabulary_sleep_app/src/state/app_state.dart';
import 'package:vocabulary_sleep_app/src/ui/app_shell.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/appearance_studio_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/data_management_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/follow_along_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/focus_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/library_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/language_settings_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/play_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/practice_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/practice_notebook_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/practice_review_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/practice_session_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/recognition_settings_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_soothing_music/runtime_store.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_soothing_music_v2_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/voice_settings_page.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/wordbook_management_page.dart';
import 'package:vocabulary_sleep_app/src/ui/sheets/ambient_sheet.dart';
import 'package:vocabulary_sleep_app/src/ui/theme/app_theme.dart';
import 'package:vocabulary_sleep_app/src/ui/ui_copy.dart';
import 'package:vocabulary_sleep_app/src/ui/widgets/ambient_floating_dock.dart';
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

    testWidgets('voice settings shows API cache controls and clears cache', (
      tester,
    ) async {
      final config = PlayConfig.defaults.copyWith(
        tts: PlayConfig.defaults.tts.copyWith(
          provider: TtsProviderType.api,
          enableApiCache: true,
        ),
      );
      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        config: config,
        apiTtsCacheBytes: 5 * 1024 * 1024,
      );
      await _pumpPage(tester, state: state, child: const VoiceSettingsPage());

      await tester.scrollUntilVisible(
        find.text('API voice cache'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('API voice cache'), findsOneWidget);
      expect(find.textContaining('Current cache:'), findsOneWidget);

      await tester.tap(find.text('Clear voice cache'));
      await tester.pumpAndSettle();

      expect(state.clearedApiTtsCache, isTrue);
      expect(find.textContaining('0 MB'), findsWidgets);
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

      final providerField = find.byType(
        DropdownButtonFormField<AsrProviderType>,
      );

      await tester.tap(providerField.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Offline (Whisper Base)').last);
      await tester.pumpAndSettle();

      expect(find.text('Switch to local recognition?'), findsOneWidget);
      expect(
        find.textContaining(
          'API recognition is recommended for better accuracy',
        ),
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
          WordEntry(wordbookId: 1, word: '鐫＄湢', fields: <WordFieldItem>[]),
          WordEntry(wordbookId: 1, word: '涓撴敞', fields: <WordFieldItem>[]),
          WordEntry(wordbookId: 1, word: '鏀炬澗', fields: <WordFieldItem>[]),
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

    testWidgets(
      'language settings hides focus subtab option when startup page has no child tab',
      (tester) async {
        final state = _FakeAppState.sample(
          uiLanguage: 'en',
          startupPage: AppHomeTab.practice,
        );
        await _pumpPage(
          tester,
          state: state,
          child: const LanguageSettingsPage(),
        );

        expect(find.text('Focus default section'), findsNothing);
        expect(find.text('Study default section'), findsNothing);
      },
    );

    testWidgets(
      'language settings shows study subtab option for study startup',
      (tester) async {
        final state = _FakeAppState.sample(
          uiLanguage: 'en',
          startupPage: AppHomeTab.study,
          studyStartupTab: StudyStartupTab.library,
        );
        await _pumpPage(
          tester,
          state: state,
          child: const LanguageSettingsPage(),
        );

        expect(find.text('Study default section'), findsOneWidget);
        expect(
          find.textContaining('When Study is the startup page'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'language settings shows focus subtab option for focus startup',
      (tester) async {
        final state = _FakeAppState.sample(
          uiLanguage: 'en',
          startupPage: AppHomeTab.focus,
          focusStartupTab: FocusStartupTab.todo,
        );
        await _pumpPage(
          tester,
          state: state,
          child: const LanguageSettingsPage(),
        );

        expect(find.text('Focus default section'), findsOneWidget);
        expect(
          find.textContaining('When Focus is the startup page'),
          findsOneWidget,
        );
      },
    );

    testWidgets('app shell blocks exit dialog while focus lock is active', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        focusService: _FakeFocusService(lockScreenActive: true),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
            theme: buildAppTheme(state.config.appearance),
            home: const AppShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Exit app?'), findsNothing);
      expect(find.textContaining('Focus lock is active.'), findsOneWidget);
    });

    testWidgets('app shell still shows exit dialog when focus lock is off', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        focusService: _FakeFocusService(lockScreenActive: false),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
            theme: buildAppTheme(state.config.appearance),
            home: const AppShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Exit app?'), findsOneWidget);
      expect(find.textContaining('Focus lock is active.'), findsNothing);
    });

    testWidgets('app shell opens the configured startup tab after init', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        startupPage: AppHomeTab.focus,
        focusService: _FakeFocusService.sample(),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
            theme: buildAppTheme(state.config.appearance),
            home: const AppShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('focus-workspace-tab')),
        findsOneWidget,
      );
    });

    testWidgets('app shell respects configured focus startup section', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        startupPage: AppHomeTab.focus,
        focusStartupTab: FocusStartupTab.timer,
        focusService: _FakeFocusService.sample(),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
            theme: buildAppTheme(state.config.appearance),
            home: const AppShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('focus-timer-tab')),
        findsOneWidget,
      );
    });

    testWidgets('app shell shows startup todo prompt when enabled', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        startupTodoPromptEnabled: true,
        startupDailyQuote: 'Stay curious.',
        weatherSnapshot: WeatherSnapshot(
          city: 'Shanghai',
          countryCode: 'CN',
          temperatureCelsius: 18.4,
          apparentTemperatureCelsius: 17.8,
          windSpeedKph: 6.0,
          weatherCode: 1,
          isDay: true,
          fetchedAt: DateTime(2026, 3, 16, 8),
          forecastDays: <WeatherForecastDay>[
            WeatherForecastDay(
              date: DateTime(2026, 3, 16),
              weatherCode: 1,
              maxTemperatureCelsius: 22,
              minTemperatureCelsius: 14,
            ),
            WeatherForecastDay(
              date: DateTime(2026, 3, 17),
              weatherCode: 3,
              maxTemperatureCelsius: 20,
              minTemperatureCelsius: 13,
            ),
          ],
        ),
        todayActiveTodos: <TodoItem>[
          TodoItem(
            content: 'Review today tasks',
            dueAt: DateTime(2026, 3, 16, 9, 0),
            alarmEnabled: true,
          ),
        ],
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
            theme: buildAppTheme(state.config.appearance),
            home: const AppShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('startup-todo-prompt-dialog')),
        findsOneWidget,
      );
      expect(find.text('Review today tasks'), findsOneWidget);
      expect(find.text('Stay curious.'), findsOneWidget);
      expect(find.text('Shanghai, CN'), findsOneWidget);
    });

    testWidgets('startup todo prompt can be muted for today', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        startupTodoPromptEnabled: true,
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
            theme: buildAppTheme(state.config.appearance),
            home: const AppShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('startup-todo-prompt-dont-show')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('startup-todo-prompt-close')),
      );
      await tester.pumpAndSettle();

      expect(state.startupPromptSuppressedToday, isTrue);
    });

    testWidgets('play page shows weather badge when enabled', (tester) async {
      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        weatherEnabled: true,
        weatherSnapshot: WeatherSnapshot(
          city: 'Shanghai',
          countryCode: 'CN',
          temperatureCelsius: 18.4,
          apparentTemperatureCelsius: 17.8,
          windSpeedKph: 6.0,
          weatherCode: 1,
          isDay: true,
          fetchedAt: DateTime(2026, 3, 15, 10),
        ),
      );
      await _pumpPage(
        tester,
        state: state,
        child: PlayPage(onOpenPractice: () {}, onOpenLibrary: () {}),
      );

      expect(
        find.byKey(const ValueKey<String>('play-weather-badge')),
        findsOne,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('play-weather-badge')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Shanghai, CN'), findsOneWidget);
      expect(find.textContaining('18'), findsWidgets);
    });

    testWidgets('ambient sheet opens online ambient catalog actions', (
      tester,
    ) async {
      final state = _FakeAppState.sample(uiLanguage: 'en');
      await _pumpPage(
        tester,
        state: state,
        child: Scaffold(
          body: AmbientSheet(state: state, i18n: AppI18n('en')),
        ),
      );

      await tester.tap(find.text('Catalog'));
      await tester.pumpAndSettle();

      expect(find.text('Ambient sound catalog'), findsOneWidget);
      expect(find.text('Play online'), findsNothing);

      await tester.pump();
      final downloadFinder = find
          .widgetWithText(FilledButton, 'Download')
          .first;
      expect(downloadFinder, findsOneWidget);
      await tester.ensureVisible(downloadFinder);
      await tester.pumpAndSettle();
      await tester.tap(downloadFinder);
      await tester.pumpAndSettle();
      expect(state.downloadedOnlineAmbientId, isNotNull);
      final deleteFinder = find.widgetWithText(OutlinedButton, 'Delete').first;
      expect(deleteFinder, findsOneWidget);
      await tester.ensureVisible(deleteFinder);
      await tester.pumpAndSettle();

      await tester.tap(deleteFinder);
      await tester.pumpAndSettle();
      expect(state.deletedDownloadedOnlineAmbientId, isNotNull);
    });

    testWidgets('toolbox page shows aggregated local tools', (tester) async {
      final state = _FakeAppState.sample(uiLanguage: 'en');
      await _pumpPage(tester, state: state, child: const ToolboxPage());

      expect(find.text('Multi-tool toolbox'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Soothing music'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Soothing music'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Schulte grid'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Schulte grid'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Daily decision'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Daily decision'), findsOneWidget);
    });

    testWidgets('toolbox page opens schulte grid and advances target', (
      tester,
    ) async {
      final state = _FakeAppState.sample(uiLanguage: 'en');
      await _pumpPage(tester, state: state, child: const ToolboxPage());

      final schulteCard = find
          .ancestor(
            of: find.text('Schulte grid'),
            matching: find.byType(InkWell),
          )
          .first;

      await tester.scrollUntilVisible(
        find.text('Schulte grid'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(schulteCard);
      await tester.pumpAndSettle();
      await tester.tap(schulteCard, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Board size'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      await tester.tap(find.text('1').first);
      await tester.pumpAndSettle();

      expect(find.text('2'), findsWidgets);
    });

    testWidgets('soothing music page shows extended modes', (tester) async {
      final state = _FakeAppState.sample(uiLanguage: 'en');
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
            theme: buildAppTheme(state.config.appearance),
            home: const SoothingMusicV2Page(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Soothing music'), findsWidgets);
      expect(find.text('Relax'), findsOneWidget);
      expect(find.text('Study'), findsWidgets);
      expect(find.text('Motion'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Music Box').first,
        240,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Music Box'), findsWidgets);
    });

    testWidgets('soothing music page keeps compact mobile layout readable', (
      tester,
    ) async {
      final state = _FakeAppState.sample(uiLanguage: 'en');
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
            theme: buildAppTheme(state.config.appearance),
            home: const SoothingMusicV2Page(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Modes'), findsOneWidget);
      expect(find.text('专注底色'), findsWidgets);
      expect(find.text('Study'), findsWidgets);
    });

    testWidgets(
      'soothing music arrangement sheet saves a template and shows playback state',
      (tester) async {
        final state = _FakeAppState.sample(uiLanguage: 'en');
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ChangeNotifierProvider<AppState>.value(
            value: state,
            child: MaterialApp(
              theme: buildAppTheme(state.config.appearance),
              home: const SoothingMusicV2Page(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Playback settings'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Edit arrangement'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Arrangement'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save current'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Wind Down Mix');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          SoothingMusicRuntimeStore.arrangementTemplates.any(
            (template) => template.name == 'Wind Down Mix',
          ),
          isTrue,
        );
        expect(
          SoothingMusicRuntimeStore.activeArrangementTemplateId,
          isNotNull,
        );
        final hasPlaybackState =
            find.byIcon(Icons.pause_rounded).evaluate().isNotEmpty ||
            find.byIcon(Icons.play_arrow_rounded).evaluate().isNotEmpty ||
            find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
        expect(hasPlaybackState, isTrue);
      },
    );

    testWidgets('focus page opens notes in a bottom sheet on phones', (
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

      expect(find.byKey(const ValueKey<String>('todo-editor-entry')), findsOne);
      expect(find.text('Quick add a task'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('notes-drawer')), findsNothing);
      expect(find.byKey(const ValueKey<String>('notes-sheet')), findsNothing);

      final notesButton = find.byKey(
        const ValueKey<String>('todo-notes-sheet-button'),
      );
      await tester.ensureVisible(notesButton);
      await tester.tap(notesButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('notes-sheet')), findsOneWidget);
      expect(find.text('Plan recap'), findsOneWidget);
    });

    testWidgets(
      'focus page keeps the notes drawer interaction on wide layouts',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 844));
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
        final todoEntryFinder = find.byKey(
          const ValueKey<String>('todo-editor-entry'),
        );

        final collapsedLeft = tester.getTopLeft(drawerFinder).dx;
        final collapsedHandleLeft = tester.getTopLeft(handleFinder).dx;
        final todoEntryRight = tester.getTopRight(todoEntryFinder).dx;
        expect(collapsedHandleLeft, greaterThan(todoEntryRight));

        await tester.tap(handleFinder);
        await tester.pumpAndSettle();

        final expandedLeft = tester.getTopLeft(drawerFinder).dx;
        expect(expandedLeft, lessThan(collapsedLeft - 100));

        await tester.drag(drawerFinder, const Offset(260, 0));
        await tester.pumpAndSettle();

        final collapsedAgainLeft = tester.getTopLeft(drawerFinder).dx;
        expect(collapsedAgainLeft, greaterThan(expandedLeft + 100));
      },
    );

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

      final todoEntry = find.byKey(const ValueKey<String>('todo-editor-entry'));
      await tester.ensureVisible(todoEntry);
      await tester.tap(todoEntry, warnIfMissed: false);
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

      final todoEntry = find.byKey(const ValueKey<String>('todo-editor-entry'));
      await tester.ensureVisible(todoEntry);
      await tester.tap(todoEntry, warnIfMissed: false);
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

      await _selectTodoMenuOption(
        tester,
        menuKey: const ValueKey<String>('todo-filter-menu'),
        optionKey: const ValueKey<String>('todo-filter-deferred'),
      );

      expect(find.text('Park backlog cleanup'), findsOneWidget);
      expect(find.text('Prepare review notes'), findsNothing);
    });

    testWidgets('focus page quick notes support voice input', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const systemSpeechChannel = MethodChannel(
        'vocabulary_sleep/system_speech',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(systemSpeechChannel, (call) async {
            switch (call.method) {
              case 'startListening':
                return <String, Object?>{'success': true, 'errorCode': null};
              case 'stopListening':
                return <String, Object?>{
                  'success': true,
                  'text': 'Capture release review highlights',
                  'locale': 'en',
                  'errorCode': null,
                };
              case 'cancelListening':
                return null;
            }
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(systemSpeechChannel, null);
      });

      final focusService = _FakeFocusService.sample();
      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        focusService: focusService,
      );
      await _pumpPage(tester, state: state, child: const FocusPage());

      await tester.tap(find.text('Tasks & Notes').first);
      await tester.pumpAndSettle();

      final notesButton = find.byKey(
        const ValueKey<String>('todo-notes-sheet-button'),
      );
      await tester.ensureVisible(notesButton);
      await tester.tap(notesButton, warnIfMissed: false);
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
          matching: find.text('Tap to stop dictation'),
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

    testWidgets('focus page quick notes allow repeated system voice input', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const systemSpeechChannel = MethodChannel(
        'vocabulary_sleep/system_speech',
      );
      var stopCallCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(systemSpeechChannel, (call) async {
            switch (call.method) {
              case 'startListening':
                return <String, Object?>{'success': true, 'errorCode': null};
              case 'stopListening':
                stopCallCount += 1;
                return <String, Object?>{
                  'success': true,
                  'text': stopCallCount == 1
                      ? 'Capture release review highlights'
                      : 'List rollout follow-up items',
                  'locale': 'en',
                  'errorCode': null,
                };
              case 'cancelListening':
                return null;
            }
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(systemSpeechChannel, null);
      });

      final focusService = _FakeFocusService.sample();
      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        focusService: focusService,
      );
      await _pumpPage(tester, state: state, child: const FocusPage());

      await tester.tap(find.text('Tasks & Notes').first);
      await tester.pumpAndSettle();

      final notesButton = find.byKey(
        const ValueKey<String>('todo-notes-sheet-button'),
      );
      await tester.ensureVisible(notesButton);
      await tester.tap(notesButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.note_add_rounded).last);
      await tester.pumpAndSettle();

      final voiceButton = find.byKey(
        const ValueKey<String>('note-voice-input-button'),
      );
      await tester.tap(voiceButton);
      await tester.pumpAndSettle();
      await tester.tap(voiceButton);
      await tester.pumpAndSettle();

      await tester.tap(voiceButton);
      await tester.pumpAndSettle();
      await tester.tap(voiceButton);
      await tester.pumpAndSettle();

      final contentField = tester.widget<TextField>(
        find.byKey(const ValueKey<String>('note-content-field')),
      );
      expect(
        contentField.controller?.text ?? '',
        'Capture release review highlights\nList rollout follow-up items',
      );
      expect(
        find.text(
          'No system speech recognizer or dictation panel is available on this device.',
        ),
        findsNothing,
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
        focusStartupTab: FocusStartupTab.timer,
        focusService: _FakeFocusService.sample(),
      );
      await _pumpPage(tester, state: state, child: const FocusPage());

      expect(find.text('Wheel picker'), findsNWidgets(2));
      expect(find.byType(ChoiceChip), findsNothing);
    });

    testWidgets(
      'ambient floating dock opens sheet and persists drag position',
      (tester) async {
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
                body: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: AmbientFloatingDock(
                        state: state,
                        i18n: AppI18n('en'),
                        bottomClearance: 120,
                      ),
                    ),
                  ],
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

        Navigator.of(
          tester.element(find.byKey(const ValueKey<String>('ambient-sheet'))),
        ).pop();
        await tester.pumpAndSettle();

        final launcherFinder = find.byKey(
          const ValueKey<String>('global-ambient-launcher'),
        );
        final beforeDragCenter = tester.getCenter(launcherFinder);
        final gesture = await tester.startGesture(beforeDragCenter);
        await tester.pump(const Duration(milliseconds: 900));
        await gesture.moveBy(const Offset(-120, 90));
        await tester.pump(const Duration(milliseconds: 32));
        await gesture.up();
        await tester.pumpAndSettle();

        final afterDragCenter = tester.getCenter(launcherFinder);
        expect(afterDragCenter.dx, lessThan(beforeDragCenter.dx - 60));
        expect(afterDragCenter.dy, greaterThan(beforeDragCenter.dy + 40));
        expect(
          state.config.appearance.normalizedAmbientLauncherX,
          lessThan(PlayConfig.defaults.appearance.normalizedAmbientLauncherX),
        );
        expect(
          state.config.appearance.normalizedAmbientLauncherY,
          greaterThan(
            PlayConfig.defaults.appearance.normalizedAmbientLauncherY,
          ),
        );
      },
    );

    testWidgets('focus page filters active and completed todos', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        focusStartupTab: FocusStartupTab.timer,
        focusService: _FakeFocusService.sample(),
      );
      await _pumpPage(tester, state: state, child: const FocusPage());

      await tester.tap(find.text('Tasks & Notes').first);
      await tester.pumpAndSettle();

      expect(find.text('Prepare review notes'), findsOneWidget);
      expect(find.text('Ship focus page polish'), findsOneWidget);

      await _selectTodoMenuOption(
        tester,
        menuKey: const ValueKey<String>('todo-filter-menu'),
        optionKey: const ValueKey<String>('todo-filter-completed'),
      );

      expect(find.text('Ship focus page polish'), findsOneWidget);
      expect(find.text('Prepare review notes'), findsNothing);

      await _selectTodoMenuOption(
        tester,
        menuKey: const ValueKey<String>('todo-filter-menu'),
        optionKey: const ValueKey<String>('todo-filter-active'),
      );

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

      expect(find.text('Due today'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey<String>('todo-metrics-toggle')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Due today'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('focus page keeps todo workspace readable on compact height', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        focusService: _FakeFocusService.sample(),
      );
      await _pumpPage(tester, state: state, child: const FocusPage());

      await tester.tap(find.text('Tasks & Notes').first);
      await tester.pumpAndSettle();

      final todoEntry = find.byKey(const ValueKey<String>('todo-editor-entry'));
      final firstTodo = find.text('Prepare review notes');

      expect(todoEntry, findsOneWidget);
      expect(firstTodo, findsOneWidget);
      expect(tester.getRect(todoEntry).bottom, lessThan(640));
      expect(tester.getRect(firstTodo).top, lessThan(640));
      expect(tester.takeException(), isNull);
    });

    testWidgets('pending todo action opens detail editor in focus page', (
      tester,
    ) async {
      final focusService = _FakeFocusService.sample();
      final targetTodo = focusService.getTodos().first;
      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        focusService: focusService,
      );
      focusService._pendingTodoReminderAction = TodoReminderLaunchAction(
        todoId: targetTodo.id!,
        type: TodoReminderActionType.detail,
      );

      await _pumpPage(tester, state: state, child: const FocusPage());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('todo-title-field')),
        findsOneWidget,
      );
      expect(find.text(targetTodo.content), findsWidgets);
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

      expect(find.text('Rescue overdue draft'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('todo-plan-overdue')),
        findsNothing,
      );

      await _selectTodoMenuOption(
        tester,
        menuKey: const ValueKey<String>('todo-view-menu'),
        optionKey: const ValueKey<String>('todo-view-plan'),
      );

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
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -320));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('todo-plan-inbox')),
        findsOneWidget,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -320));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('todo-plan-completed')),
        findsOneWidget,
      );

      await _selectTodoMenuOption(
        tester,
        menuKey: const ValueKey<String>('todo-view-menu'),
        optionKey: const ValueKey<String>('todo-view-list'),
      );

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

    testWidgets('focus page disables sheet drag for timer wheel picker', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        focusStartupTab: FocusStartupTab.timer,
        focusService: _FakeFocusService.sample(),
      );
      await _pumpPage(tester, state: state, child: const FocusPage());

      final wheelPicker = find.text('Wheel picker').first;
      await tester.ensureVisible(wheelPicker);
      await tester.tap(wheelPicker, warnIfMissed: false);
      await tester.pumpAndSettle();

      final bottomSheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
      expect(bottomSheet.enableDrag, isFalse);
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

    testWidgets('data management page wires export task wordbook action', (
      tester,
    ) async {
      final state = _FakeAppState.sample(uiLanguage: 'en');
      await _pumpPage(tester, state: state, child: const DataManagementPage());

      await tester.tap(find.text('Export task wordbook'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'task_bundle');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(state.exportedTaskWordbookName, 'task_bundle');
    });

    testWidgets(
      'data management page explains import and restore flows are offline',
      (tester) async {
        final state = _FakeAppState.sample(uiLanguage: 'en');
        await _pumpPage(
          tester,
          state: state,
          child: const DataManagementPage(),
        );

        expect(find.text('Current status'), findsOneWidget);
        expect(find.textContaining('temporarily offline'), findsOneWidget);
      },
    );

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

      expect(
        find.byKey(const ValueKey<String>('practice-round-setup-card')),
        findsOneWidget,
      );
      expect(find.text('Round setup'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('practice-round-toggle')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Practice source'), findsOneWidget);
      expect(find.text('Words per round'), findsOneWidget);

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
        find.byKey(const ValueKey<String>('practice-wrong-notebook-card')),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('practice-wrong-notebook-card')),
        findsOneWidget,
      );
      expect(find.text('Wrong notebook'), findsOneWidget);

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
        find.byKey(const ValueKey<String>('practice-wrong-notebook-card')),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('\u9519\u9898\u672c'), findsOneWidget);

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
            WordFieldItem(key: 'meaning', label: '鍚箟', value: '寮€濮�'),
          ],
        ),
      ];

      await _pumpPage(
        tester,
        state: state,
        child: const PracticeSessionPage(title: '娴嬭瘯缁冧範', words: words),
      );

      expect(find.text('\u663e\u793a\u63d0\u793a'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('\u6ca1\u8bb0\u4f4f'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('\u6ca1\u8bb0\u4f4f'), findsOneWidget);

      await tester.tap(find.text('\u8bb0\u4f4f\u4e86'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u5b8c\u6210\u8fd9\u4e00\u8f6e'));
      await tester.pumpAndSettle();

      expect(find.text('\u5df2\u8bb0\u4f4f\u5355\u8bcd'), findsOneWidget);
      expect(find.text('\u590d\u4e60\u5df2\u8bb0\u4f4f'), findsOneWidget);
      expect(find.textContaining('\u5bb8\u8336'), findsNothing);
    });

    testWidgets('practice session keeps answer feedback inline on windows', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        final state = _FakeAppState.sample(uiLanguage: 'en');
        const words = <WordEntry>[
          WordEntry(wordbookId: 1, word: 'alpha', fields: <WordFieldItem>[]),
        ];

        await _pumpPage(
          tester,
          state: state,
          child: const PracticeSessionPage(
            title: 'Windows feedback',
            words: words,
          ),
        );

        await tester.scrollUntilVisible(
          find.text('Remembered'),
          220,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Remembered'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(
          find.byKey(const ValueKey<String>('practice-answer-feedback-card')),
          findsOneWidget,
        );
        expect(find.text('Finish round'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
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

      await tester.scrollUntilVisible(
        find.text('Not yet'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Not yet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next word'));
      await tester.pumpAndSettle();
      expect(state.taskWords, isEmpty);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('practice-session-settings-toggle')),
        -220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('practice-session-settings-toggle')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('practice-answer-feedback-switch')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('practice-auto-task-switch')),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Not yet'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Not yet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish round'));
      await tester.pumpAndSettle();

      expect(state.taskWords.contains('word:alpha'), isFalse);
      expect(state.taskWords.contains('word:bravo'), isTrue);
    });

    testWidgets('practice session updates practice stats and memory lanes', (
      tester,
    ) async {
      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        practiceTodaySessions: 0,
        practiceTodayReviewed: 0,
        practiceTodayRemembered: 0,
        practiceTotalSessions: 0,
        practiceTotalReviewed: 0,
        practiceTotalRemembered: 0,
        practiceLastSessionTitle: '',
        recentRememberedEntries: const <WordEntry>[],
        recentWeakEntries: const <WordEntry>[],
      );
      const words = <WordEntry>[
        WordEntry(wordbookId: 1, word: 'alpha', fields: <WordFieldItem>[]),
        WordEntry(wordbookId: 1, word: 'bravo', fields: <WordFieldItem>[]),
      ];

      await _pumpPage(
        tester,
        state: state,
        child: const PracticeSessionPage(title: 'Memory sync', words: words),
      );

      await tester.scrollUntilVisible(
        find.text('Remembered'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remembered'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next word'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not yet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish round'));
      await tester.pumpAndSettle();

      expect(state.practiceTodaySessions, 1);
      expect(state.practiceTodayReviewed, 2);
      expect(state.practiceTodayRemembered, 1);
      expect(state.practiceLastSessionTitle, 'Memory sync');
      expect(
        state.recentRememberedWordEntries.map((entry) => entry.word).toList(),
        <String>['alpha'],
      );
      expect(
        state.recentWeakWordEntries.map((entry) => entry.word).toList(),
        <String>['bravo'],
      );
    });

    testWidgets('practice session supports meaning choice mode', (
      tester,
    ) async {
      final state = _FakeAppState.sample(uiLanguage: 'en');
      const words = <WordEntry>[
        WordEntry(
          wordbookId: 1,
          word: 'alpha',
          meaning: 'first',
          fields: <WordFieldItem>[],
        ),
        WordEntry(
          wordbookId: 1,
          word: 'bravo',
          meaning: 'second',
          fields: <WordFieldItem>[],
        ),
        WordEntry(
          wordbookId: 1,
          word: 'charlie',
          meaning: 'third',
          fields: <WordFieldItem>[],
        ),
      ];

      await _pumpPage(
        tester,
        state: state,
        child: const PracticeSessionPage(title: 'Meaning mode', words: words),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('practice-session-settings-toggle')),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ChoiceChip, 'Meaning choice'), findsOneWidget);
    });

    testWidgets('practice session marks wrong meaning choice as weak', (
      tester,
    ) async {
      final state = _FakeAppState.sample(uiLanguage: 'en');
      const words = <WordEntry>[
        WordEntry(
          wordbookId: 1,
          word: 'alpha',
          meaning: 'first',
          fields: <WordFieldItem>[],
        ),
        WordEntry(
          wordbookId: 1,
          word: 'bravo',
          meaning: 'second',
          fields: <WordFieldItem>[],
        ),
        WordEntry(
          wordbookId: 1,
          word: 'charlie',
          meaning: 'third',
          fields: <WordFieldItem>[],
        ),
      ];

      await _pumpPage(
        tester,
        state: state,
        child: const PracticeSessionPage(
          title: 'Meaning feedback',
          words: words,
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('practice-session-settings-toggle')),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.widgetWithText(ChoiceChip, 'Meaning choice'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Meaning choice'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('second').first,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('second').first);
      await tester.pumpAndSettle();

      expect(find.text('Not quite. Correct answer: first'), findsOneWidget);
      expect(find.text('Continue as weak'), findsOneWidget);
    });

    testWidgets('wrong notebook supports search and reason filter', (
      tester,
    ) async {
      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        recentWeakEntries: const <WordEntry>[
          WordEntry(wordbookId: 1, word: 'alpha', meaning: 'first'),
          WordEntry(wordbookId: 1, word: 'bravo', meaning: 'second'),
        ],
      );
      state._practiceWeakReasonsByWord['alpha'] = <String>['meaning'];
      state._practiceWeakReasonsByWord['bravo'] = <String>['spelling'];

      await _pumpPage(
        tester,
        state: state,
        child: const PracticeNotebookPage(),
      );

      await tester.enterText(find.byType(TextField).first, 'alp');
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('alpha'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('alpha'), findsOneWidget);
      expect(find.text('bravo'), findsNothing);

      await tester.fling(
        find.byType(Scrollable).first,
        const Offset(0, 800),
        1000,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('All reasons'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Meaning'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('alpha'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('alpha'), findsOneWidget);
      expect(find.text('bravo'), findsNothing);
    });

    testWidgets('practice review page supports time range filtering', (
      tester,
    ) async {
      final state = _FakeAppState.sample(uiLanguage: 'en');
      state._practiceSessionHistory = <PracticeSessionRecord>[
        PracticeSessionRecord(
          title: 'Today sprint',
          practicedAt: DateTime.now(),
          total: 10,
          remembered: 7,
          weakReasonCounts: const <String, int>{'recall': 2},
        ),
        PracticeSessionRecord(
          title: 'Old sprint',
          practicedAt: DateTime.now().subtract(const Duration(days: 40)),
          total: 10,
          remembered: 4,
          weakReasonCounts: const <String, int>{'meaning': 3},
        ),
      ];

      await _pumpPage(tester, state: state, child: const PracticeReviewPage());

      await tester.scrollUntilVisible(
        find.text('Today sprint'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Today sprint'), findsOneWidget);
      expect(find.text('Old sprint'), findsNothing);

      await tester.fling(
        find.byType(Scrollable).first,
        const Offset(0, 1000),
        1000,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Today sprint'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Today sprint'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Old sprint'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Old sprint'), findsOneWidget);
    });

    testWidgets('practice review page shows interactive trend card', (
      tester,
    ) async {
      final state = _FakeAppState.sample(uiLanguage: 'en');
      state._practiceSessionHistory = <PracticeSessionRecord>[
        PracticeSessionRecord(
          title: 'Round 1',
          practicedAt: DateTime.now(),
          total: 8,
          remembered: 6,
        ),
        PracticeSessionRecord(
          title: 'Round 2',
          practicedAt: DateTime.now().subtract(const Duration(days: 1)),
          total: 10,
          remembered: 4,
        ),
      ];

      await _pumpPage(tester, state: state, child: const PracticeReviewPage());

      expect(
        find.byKey(const ValueKey<String>('practice-trend-card')),
        findsOneWidget,
      );
      expect(find.text('Trend card'), findsOneWidget);
      expect(find.text('Accuracy'), findsWidgets);
      expect(find.text('Reviewed'), findsWidgets);
      expect(find.text('Weak'), findsWidgets);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
    });

    testWidgets('wrong notebook exports current filtered results', (
      tester,
    ) async {
      final state = _FakeAppState.sample(
        uiLanguage: 'en',
        recentWeakEntries: const <WordEntry>[
          WordEntry(wordbookId: 1, word: 'alpha', meaning: 'first'),
          WordEntry(wordbookId: 1, word: 'bravo', meaning: 'second'),
        ],
      );

      await _pumpPage(
        tester,
        state: state,
        child: const PracticeNotebookPage(),
      );

      await tester.enterText(find.byType(TextField).first, 'alp');
      await tester.pumpAndSettle();

      await tester.fling(
        find.byType(Scrollable).first,
        const Offset(0, -800),
        1000,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Export filtered (JSON)'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).last,
        'filtered_wrong_notebook.json',
      );
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();

      expect(
        state.exportedWrongNotebookPath,
        contains('filtered_wrong_notebook.json'),
      );
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

Future<void> _selectTodoMenuOption(
  WidgetTester tester, {
  required ValueKey<String> menuKey,
  required ValueKey<String> optionKey,
}) async {
  await tester.tap(find.byKey(menuKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(optionKey).last);
  await tester.pumpAndSettle();
}

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

class _FakeAppState extends ChangeNotifier
    with WidgetsBindingObserver
    implements AppState {
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
    required List<OnlineAmbientSoundOption> onlineAmbientCatalog,
    required double ambientMasterVolume,
    required String? asrRecordingPath,
    required String? asrStoppedRecordingPath,
    required AsrResult asrTranscriptionResult,
    required int apiTtsCacheBytes,
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
       _onlineAmbientCatalog = onlineAmbientCatalog,
       _ambientMasterVolume = ambientMasterVolume,
       _asrRecordingPath = asrRecordingPath,
       _asrStoppedRecordingPath = asrStoppedRecordingPath,
       _asrTranscriptionResult = asrTranscriptionResult,
       _apiTtsCacheBytes = apiTtsCacheBytes;

  factory _FakeAppState.sample({
    List<WordEntry>? words,
    String uiLanguage = 'zh',
    PlayConfig? config,
    Wordbook? selectedWordbook,
    List<Wordbook>? wordbooks,
    List<DatabaseBackupInfo>? backups,
    FocusService? focusService,
    List<AmbientSource>? ambientSources,
    List<OnlineAmbientSoundOption>? onlineAmbientCatalog,
    bool ambientEnabled = true,
    AppHomeTab startupPage = AppHomeTab.study,
    StudyStartupTab studyStartupTab = StudyStartupTab.play,
    FocusStartupTab focusStartupTab = FocusStartupTab.todo,
    bool weatherEnabled = false,
    WeatherSnapshot? weatherSnapshot,
    bool weatherLoading = false,
    bool startupTodoPromptEnabled = false,
    String? startupDailyQuote,
    bool startupDailyQuoteLoading = false,
    List<TodoItem>? todayActiveTodos,
    String? asrRecordingPath,
    String? asrStoppedRecordingPath,
    AsrResult? asrTranscriptionResult,
    int apiTtsCacheBytes = 0,
    int practiceTodaySessions = 2,
    int practiceTodayReviewed = 9,
    int practiceTodayRemembered = 7,
    int practiceTotalSessions = 6,
    int practiceTotalReviewed = 28,
    int practiceTotalRemembered = 22,
    String practiceLastSessionTitle = 'Scope sprint',
    List<WordEntry>? recentRememberedEntries,
    List<WordEntry>? recentWeakEntries,
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
        onlineAmbientCatalog:
            onlineAmbientCatalog ??
            const <OnlineAmbientSoundOption>[
              OnlineAmbientSoundOption(
                id: 'ambient_nature_forest-birds',
                name: 'Forest Birds',
                categoryKey: 'ambientCategoryNature',
                relativePath: 'nature/forest-birds.mp3',
                remoteKey: 'ambient/moodist/nature/forest-birds.mp3',
                defaultVolume: 0.42,
              ),
              OnlineAmbientSoundOption(
                id: 'ambient_rain_window-rain',
                name: 'Window Rain',
                categoryKey: 'ambientCategoryRain',
                relativePath: 'rain/window-rain.mp3',
                remoteKey: 'ambient/moodist/rain/window-rain.mp3',
                defaultVolume: 0.38,
              ),
            ],
        ambientMasterVolume: 0.55,
        asrRecordingPath: asrRecordingPath,
        asrStoppedRecordingPath: asrStoppedRecordingPath,
        asrTranscriptionResult:
            asrTranscriptionResult ??
            const AsrResult(success: false, error: 'recognitionFailed'),
        apiTtsCacheBytes: apiTtsCacheBytes,
      )
      .._startupPage = startupPage
      .._studyStartupTab = studyStartupTab
      .._focusStartupTab = focusStartupTab
      .._ambientEnabled = ambientEnabled
      .._weatherEnabled = weatherEnabled
      .._weatherSnapshot = weatherSnapshot
      .._weatherLoading = weatherLoading
      .._startupTodoPromptEnabled = startupTodoPromptEnabled
      .._startupDailyQuote = startupDailyQuote
      .._startupDailyQuoteLoading = startupDailyQuoteLoading
      .._todayActiveTodos = List<TodoItem>.from(
        todayActiveTodos ?? <TodoItem>[],
      )
      .._currentWord = visibleWords.firstOrNull
      .._practiceTodaySessions = practiceTodaySessions
      .._practiceTodayReviewed = practiceTodayReviewed
      .._practiceTodayRemembered = practiceTodayRemembered
      .._practiceTotalSessions = practiceTotalSessions
      .._practiceTotalReviewed = practiceTotalReviewed
      .._practiceTotalRemembered = practiceTotalRemembered
      .._practiceLastSessionTitle = practiceLastSessionTitle
      .._recentRememberedEntries = List<WordEntry>.from(
        recentRememberedEntries ??
            (visibleWords.length < 3
                ? visibleWords
                : visibleWords.sublist(1, 3)),
      )
      .._recentWeakEntries = List<WordEntry>.from(
        recentWeakEntries ??
            (visibleWords.length < 2
                ? visibleWords
                : visibleWords.sublist(0, 2)),
      );
  }

  PlayConfig _config;
  String _uiLanguage;
  bool _uiLanguageFollowsSystem;
  Wordbook? _selectedWordbook;
  List<Wordbook> _wordbooks;
  final List<WordEntry> _visibleWords;
  WordEntry? _currentWord;
  int _currentWordIndex = 0;
  String? _lastBackupPath;
  final List<String> _localVoices;
  final List<DatabaseBackupInfo> _backups;
  final FocusService _focusService;
  List<AmbientSource> _ambientSources;
  final List<OnlineAmbientSoundOption> _onlineAmbientCatalog;
  List<AmbientPreset> _ambientPresets = <AmbientPreset>[];
  bool _ambientEnabled = true;
  double _ambientMasterVolume;
  final String? _asrRecordingPath;
  final String? _asrStoppedRecordingPath;
  final AsrResult _asrTranscriptionResult;
  int _apiTtsCacheBytes;
  bool _isPlaying = false;
  bool _isPaused = false;
  int _currentUnit = 0;
  int _totalUnits = 0;
  PlayUnit? _activeUnit;
  int? _playingWordbookId;
  String? _playingWordbookName;
  String? _playingWord;
  AppHomeTab _startupPage = AppHomeTab.study;
  StudyStartupTab _studyStartupTab = StudyStartupTab.play;
  FocusStartupTab _focusStartupTab = FocusStartupTab.todo;
  bool _weatherEnabled = false;
  WeatherSnapshot? _weatherSnapshot;
  bool _weatherLoading = false;
  bool _startupTodoPromptEnabled = false;
  String? _startupDailyQuote;
  bool _startupDailyQuoteLoading = false;
  List<TodoItem> _todayActiveTodos = <TodoItem>[];
  bool _sleepLoading = false;
  SleepProfile? _sleepProfile;
  SleepPlan? _sleepCurrentPlan;
  SleepDashboardState _sleepDashboardState = const SleepDashboardState();
  SleepAssessmentDraftState _sleepAssessmentDraft =
      const SleepAssessmentDraftState();
  SleepRoutineRunnerState _sleepRoutineRunnerState =
      const SleepRoutineRunnerState();
  SleepNightRescueState _sleepNightRescueState = const SleepNightRescueState();
  List<SleepDailyLog> _sleepDailyLogs = <SleepDailyLog>[];
  List<SleepNightEvent> _sleepNightEvents = <SleepNightEvent>[];
  List<SleepThoughtEntry> _sleepThoughtEntries = <SleepThoughtEntry>[];
  List<SleepRoutineTemplate> _sleepRoutineTemplates =
      SleepRoutineTemplate.builtInDefaults();
  SleepProgramProgress? _sleepProgramProgress;
  String _searchQuery = '';
  SearchMode _searchMode = SearchMode.all;
  bool _testModeEnabled = false;
  bool _testModeRevealed = false;
  bool _testModeHintRevealed = false;
  bool resetUserDataCalled = false;
  bool clearedApiTtsCache = false;
  String? restoredBackupPath;
  String? deletedBackupPath;
  String? exportedUserDataPath;
  String? exportedUserDataDirectoryPath;
  String? exportedUserDataFileName;
  Set<UserDataExportSection>? exportedUserDataSections;
  String? exportedTaskWordbookName;
  String? exportedPracticeReviewPath;
  String? exportedWrongNotebookPath;
  String? downloadedOnlineAmbientId;
  String? deletedDownloadedOnlineAmbientId;
  final Set<String> _downloadedOnlineAmbientRelativePaths = <String>{};
  String? createdWordbookName;
  String? renamedWordbookName;
  String? importedWordbookName;
  String? importedWordbookFilePath;
  int _practiceTodaySessions = 2;
  int _practiceTodayReviewed = 9;
  int _practiceTodayRemembered = 7;
  int _practiceTotalSessions = 6;
  int _practiceTotalReviewed = 28;
  int _practiceTotalRemembered = 22;
  String _practiceLastSessionTitle = 'Scope sprint';
  List<WordEntry> _recentRememberedEntries = <WordEntry>[];
  List<WordEntry> _recentWeakEntries = <WordEntry>[];
  final Map<String, List<String>> _practiceWeakReasonsByWord =
      <String, List<String>>{};
  List<PracticeSessionRecord> _practiceSessionHistory = <PracticeSessionRecord>[
    PracticeSessionRecord(
      title: 'Scope sprint',
      practicedAt: DateTime(2026, 3, 20, 9, 30),
      total: 8,
      remembered: 6,
      weakReasonCounts: const <String, int>{'recall': 1, 'meaning': 1},
    ),
  ];
  bool _practiceAutoAddWeakWordsToTask = false;
  bool _practiceAutoPlayPronunciation = false;
  bool _practiceShowHintsByDefault = false;
  bool _practiceShowAnswerFeedbackDialog = true;
  PracticeQuestionType _practiceDefaultQuestionType =
      PracticeQuestionType.flashcard;
  PracticeRoundSettings _practiceRoundSettings = PracticeRoundSettings.defaults;
  final Map<String, int> _practiceLaunchCursors = <String, int>{};
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
  bool get ambientEnabled => _ambientEnabled;

  @override
  double get ambientMasterVolume => _ambientMasterVolume;

  @override
  List<AmbientPreset> get ambientPresets =>
      List<AmbientPreset>.unmodifiable(_ambientPresets);

  @override
  bool get busy => false;

  @override
  String? get busyMessage => null;

  @override
  String? get busyMessageKey => null;

  @override
  String? get busyDetail => null;

  @override
  double? get busyProgress => null;

  @override
  bool get wordbookImportActive => false;

  @override
  String get wordbookImportName => '';

  @override
  int get wordbookImportProcessedEntries => 0;

  @override
  int? get wordbookImportTotalEntries => null;

  @override
  double? get wordbookImportProgress => null;

  @override
  WordEntry? get currentWord => _currentWord ?? _visibleWords.firstOrNull;

  @override
  int get currentWordIndex => _currentWordIndex;

  @override
  bool get isPlaying => _isPlaying;

  @override
  bool get isPaused => _isPaused;

  @override
  int get currentUnit => _currentUnit;

  @override
  int get totalUnits => _totalUnits;

  @override
  PlayUnit? get activeUnit => _activeUnit;

  @override
  int? get playingWordbookId => _playingWordbookId;

  @override
  String? get playingWordbookName => _playingWordbookName;

  @override
  String? get playingWord => _playingWord;

  @override
  bool get isPlayingDifferentWordbook =>
      _isPlaying &&
      _playingWordbookId != null &&
      _selectedWordbook?.id != _playingWordbookId;

  @override
  Set<String> get favorites => _favorites;

  @override
  FocusService get focusService => _focusService;

  @override
  String? get error => null;

  @override
  Future<void> init() async {}

  @override
  Future<void> loadSleepAssistantData() async {}

  @override
  bool get initializing => false;

  @override
  bool get initialized => true;

  @override
  bool get selectedWordbookLoaded => _selectedWordbook != null;

  @override
  bool get selectedWordbookRequiresOnDemandLoad => false;

  @override
  String? get lastBackupPath => _lastBackupPath;

  @override
  bool get remotePrewarmActive => false;

  @override
  bool get remotePrewarmCompleted => false;

  @override
  bool get remotePrewarmFailed => false;

  @override
  int get remotePrewarmCompletedCount => 0;

  @override
  int get remotePrewarmTotalCount => 0;

  @override
  String get remotePrewarmCurrentLabel => '';

  @override
  double get remotePrewarmProgress => 0;

  @override
  bool get sleepLoading => _sleepLoading;

  @override
  SleepProfile? get sleepProfile => _sleepProfile;

  @override
  SleepPlan? get sleepCurrentPlan => _sleepCurrentPlan;

  @override
  SleepDashboardState get sleepDashboardState => _sleepDashboardState;

  @override
  SleepAssessmentDraftState get sleepAssessmentDraft => _sleepAssessmentDraft;

  @override
  SleepRoutineRunnerState get sleepRoutineRunnerState =>
      _sleepRoutineRunnerState;

  @override
  SleepNightRescueState get sleepNightRescueState => _sleepNightRescueState;

  @override
  List<SleepDailyLog> get sleepDailyLogs =>
      List<SleepDailyLog>.unmodifiable(_sleepDailyLogs);

  @override
  List<SleepNightEvent> get sleepNightEvents =>
      List<SleepNightEvent>.unmodifiable(_sleepNightEvents);

  @override
  List<SleepThoughtEntry> get sleepThoughtEntries =>
      List<SleepThoughtEntry>.unmodifiable(_sleepThoughtEntries);

  @override
  List<SleepRoutineTemplate> get sleepRoutineTemplates =>
      List<SleepRoutineTemplate>.unmodifiable(_sleepRoutineTemplates);

  @override
  SleepProgramProgress? get sleepProgramProgress => _sleepProgramProgress;

  @override
  SleepDailyLog? get latestSleepDailyLog => _sleepDailyLogs.firstOrNull;

  @override
  SleepRoutineTemplate? get activeSleepRoutineTemplate {
    final activeTemplateId = _sleepRoutineRunnerState.activeTemplateId;
    if (activeTemplateId != null) {
      return _sleepRoutineTemplates
          .where((template) => template.id == activeTemplateId)
          .cast<SleepRoutineTemplate?>()
          .firstOrNull;
    }
    return _sleepRoutineTemplates.firstOrNull;
  }

  @override
  SleepRoutineStep? get currentSleepRoutineStep {
    final template = activeSleepRoutineTemplate;
    final index = _sleepRoutineRunnerState.currentStepIndex;
    if (template == null || index < 0 || index >= template.steps.length) {
      return null;
    }
    return template.steps[index];
  }

  @override
  double get sleepRoutineProgress {
    final template = activeSleepRoutineTemplate;
    if (template == null || template.steps.isEmpty) {
      return 0;
    }
    return ((_sleepRoutineRunnerState.currentStepIndex + 1) /
            template.steps.length)
        .clamp(0.0, 1.0);
  }

  @override
  String get practiceLastSessionTitle => _practiceLastSessionTitle;

  @override
  List<String> get practiceRememberedWords => recentRememberedWordEntries
      .map((entry) => entry.word)
      .toList(growable: false);

  @override
  List<String> get practiceWeakWords =>
      recentWeakWordEntries.map((entry) => entry.word).toList(growable: false);

  @override
  bool get practiceAutoAddWeakWordsToTask => _practiceAutoAddWeakWordsToTask;

  @override
  bool get practiceAutoPlayPronunciation => _practiceAutoPlayPronunciation;

  @override
  bool get practiceShowHintsByDefault => _practiceShowHintsByDefault;

  @override
  bool get practiceShowAnswerFeedbackDialog =>
      _practiceShowAnswerFeedbackDialog;

  @override
  List<PracticeSessionRecord> get practiceSessionHistory =>
      List<PracticeSessionRecord>.unmodifiable(_practiceSessionHistory);

  @override
  int? get pendingTodoReminderLaunchId => null;

  @override
  PracticeQuestionType get practiceDefaultQuestionType =>
      _practiceDefaultQuestionType;

  @override
  PracticeRoundSettings get practiceRoundSettings => _practiceRoundSettings;

  @override
  List<WordEntry> get practiceWrongNotebookEntries =>
      List<WordEntry>.unmodifiable(_recentWeakEntries);

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
      List<WordEntry>.unmodifiable(_recentRememberedEntries);

  @override
  List<WordEntry> get recentWeakWordEntries =>
      List<WordEntry>.unmodifiable(_recentWeakEntries);

  @override
  WordMemoryProgress? memoryProgressForWordEntry(WordEntry entry) => null;

  @override
  List<String> practiceWeakReasonsForWord(WordEntry entry) {
    return List<String>.unmodifiable(
      _practiceWeakReasonsByWord[entry.word.trim().toLowerCase()] ??
          const <String>[],
    );
  }

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
  AppHomeTab get startupPage => _startupPage;

  @override
  FocusStartupTab get focusStartupTab => _focusStartupTab;

  @override
  StudyStartupTab get studyStartupTab => _studyStartupTab;

  @override
  bool get weatherEnabled => _weatherEnabled;

  @override
  WeatherSnapshot? get weatherSnapshot => _weatherSnapshot;

  @override
  bool get weatherLoading => _weatherLoading;

  @override
  String get uiLanguageSelection =>
      _uiLanguageFollowsSystem ? 'system' : _uiLanguage;

  @override
  bool get testModeEnabled => _testModeEnabled;

  @override
  bool get testModeRevealed => _testModeRevealed;

  @override
  bool get testModeHintRevealed => _testModeHintRevealed;

  @override
  bool get startupTodoPromptEnabled => _startupTodoPromptEnabled;

  @override
  bool get shouldShowStartupTodoPromptToday => _startupTodoPromptEnabled;

  @override
  String? get startupDailyQuote => _startupDailyQuote;

  @override
  bool get startupDailyQuoteLoading => _startupDailyQuoteLoading;

  @override
  List<TodoItem> get todayActiveTodos =>
      List<TodoItem>.unmodifiable(_todayActiveTodos);

  bool startupPromptSuppressedToday = false;

  @override
  int? consumePendingTodoReminderLaunchId() => null;

  @override
  void setStudyStartupTab(StudyStartupTab tab) {
    _studyStartupTab = tab;
    notifyListeners();
  }

  @override
  List<WordEntry> get words => _visibleWords;

  @override
  List<WordEntry> get visibleWords => _visibleWords;

  @override
  int get visibleWordCount => _visibleWords.length;

  @override
  List<WordEntry> getVisibleWordsPage({required int limit, int offset = 0}) {
    final start = offset.clamp(0, _visibleWords.length).toInt();
    final end = (start + limit).clamp(start, _visibleWords.length).toInt();
    return _visibleWords.sublist(start, end);
  }

  @override
  int? findVisibleWordOffsetByPrefix(String prefix) {
    final index = AppState.findJumpIndexByPrefix(_visibleWords, prefix);
    return index < 0 ? null : index;
  }

  @override
  int? findVisibleWordOffsetByInitial(String initial) {
    final index = AppState.findJumpIndexByInitial(_visibleWords, initial);
    return index < 0 ? null : index;
  }

  @override
  int? findVisibleWordOffsetForEntry(WordEntry entry) {
    final index = _visibleWords.indexWhere(
      (item) => item.word == entry.word && item.wordbookId == entry.wordbookId,
    );
    return index < 0 ? null : index;
  }

  @override
  List<Wordbook> get wordbooks => _wordbooks;

  @override
  bool requiresWordbookLoadConfirmation(Wordbook wordbook) => false;

  @override
  Future<List<String>> fetchLocalTtsVoices() async => _localVoices;

  @override
  Future<int> getApiTtsCacheSizeBytes() async => _apiTtsCacheBytes;

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
  Future<void> play() async {
    _isPlaying = true;
    _isPaused = false;
    _playingWordbookId = _selectedWordbook?.id;
    _playingWordbookName = _selectedWordbook?.name;
    _playingWord = currentWord?.word;
    _totalUnits = _visibleWords.length;
    _currentUnit = _visibleWords.isEmpty ? 0 : (_currentWordIndex + 1);
    notifyListeners();
  }

  @override
  Future<void> preparePlay() async {
    _isPlaying = false;
    _isPaused = true;
    _playingWordbookId = _selectedWordbook?.id;
    _playingWordbookName = _selectedWordbook?.name;
    _playingWord = currentWord?.word;
    _currentUnit = 0;
    _totalUnits = _visibleWords.length;
    notifyListeners();
  }

  @override
  Future<void> startPreparedPlay() => play();

  @override
  Future<void> pauseOrResume() async {
    if (!_isPlaying) {
      await play();
      return;
    }
    _isPaused = !_isPaused;
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    _isPaused = false;
    _currentUnit = 0;
    _totalUnits = 0;
    _activeUnit = null;
    _playingWordbookId = null;
    _playingWordbookName = null;
    _playingWord = null;
    notifyListeners();
  }

  @override
  Future<void> skipCurrentWord() => playNextWord();

  @override
  Future<void> playPreviousWord() async {
    await movePlaybackPreviousWord();
    await play();
  }

  @override
  Future<void> playNextWord() async {
    await movePlaybackNextWord();
    await play();
  }

  @override
  Future<void> jumpToPlayingWordbook() async {
    final playingWordbookId = _playingWordbookId;
    if (playingWordbookId == null) {
      return;
    }
    final match = _wordbooks
        .where((item) => item.id == playingWordbookId)
        .cast<Wordbook?>()
        .firstOrNull;
    if (match == null) {
      return;
    }
    _selectedWordbook = match;
    notifyListeners();
  }

  @override
  Future<void> playCurrentWordbook() => play();

  @override
  Future<void> movePlaybackPreviousWord() async {
    if (_visibleWords.isEmpty) {
      return;
    }
    selectWordIndex((_currentWordIndex - 1).clamp(0, _visibleWords.length - 1));
  }

  @override
  Future<void> movePlaybackNextWord() async {
    if (_visibleWords.isEmpty) {
      return;
    }
    selectWordIndex((_currentWordIndex + 1).clamp(0, _visibleWords.length - 1));
  }

  @override
  void rememberPlaybackProgress([WordEntry? entry]) {}

  @override
  bool restorePlaybackProgressForSelectedWordbook() => false;

  @override
  void clearMessage() {}

  @override
  Future<void> clearApiTtsCache() async {
    clearedApiTtsCache = true;
    _apiTtsCacheBytes = 0;
    notifyListeners();
  }

  @override
  void saveSleepProfile(SleepProfile profile) {
    _sleepProfile = profile;
    notifyListeners();
  }

  @override
  void updateSleepAssessmentDraft(SleepAssessmentDraftState draft) {
    _sleepAssessmentDraft = draft;
    notifyListeners();
  }

  @override
  void saveSleepDailyLog(SleepDailyLog log) {
    final updated = List<SleepDailyLog>.from(_sleepDailyLogs);
    final index = updated.indexWhere((item) => item.dateKey == log.dateKey);
    if (index >= 0) {
      updated[index] = log;
    } else {
      updated.insert(0, log);
    }
    _sleepDailyLogs = updated;
    notifyListeners();
  }

  @override
  void saveSleepNightEvent(SleepNightEvent event) {
    _sleepNightEvents = <SleepNightEvent>[event, ..._sleepNightEvents];
    notifyListeners();
  }

  @override
  void saveSleepThoughtEntry(SleepThoughtEntry entry) {
    _sleepThoughtEntries = <SleepThoughtEntry>[entry, ..._sleepThoughtEntries];
    notifyListeners();
  }

  @override
  SleepDailyLog? sleepDailyLogByDateKey(String dateKey) {
    return _sleepDailyLogs
        .where((item) => item.dateKey == dateKey)
        .cast<SleepDailyLog?>()
        .firstOrNull;
  }

  @override
  void setSleepActiveRoutineTemplate(String templateId) {
    _sleepRoutineRunnerState = _sleepRoutineRunnerState.copyWith(
      activeTemplateId: templateId,
    );
    notifyListeners();
  }

  @override
  void replaceSleepRoutineTemplates(List<SleepRoutineTemplate> templates) {
    _sleepRoutineTemplates = List<SleepRoutineTemplate>.from(templates);
    notifyListeners();
  }

  @override
  void saveSleepRoutineTemplate(SleepRoutineTemplate template) {
    final updated = List<SleepRoutineTemplate>.from(_sleepRoutineTemplates);
    final index = updated.indexWhere((item) => item.id == template.id);
    if (index >= 0) {
      updated[index] = template;
    } else {
      updated.insert(0, template);
    }
    _sleepRoutineTemplates = updated;
    notifyListeners();
  }

  @override
  void deleteSleepRoutineTemplate(String templateId) {
    _sleepRoutineTemplates = _sleepRoutineTemplates
        .where((template) => template.id != templateId)
        .toList(growable: false);
    if (_sleepRoutineRunnerState.activeTemplateId == templateId) {
      _sleepRoutineRunnerState = _sleepRoutineRunnerState.copyWith(
        activeTemplateId: null,
        currentStepIndex: 0,
        remainingSeconds: 0,
        isRunning: false,
        isPaused: false,
        startedAt: null,
      );
    }
    notifyListeners();
  }

  @override
  void startSleepRoutine([String? templateId]) {
    final requestedTemplateId = templateId ?? activeSleepRoutineTemplate?.id;
    final template =
        _sleepRoutineTemplates
            .where((item) => item.id == requestedTemplateId)
            .cast<SleepRoutineTemplate?>()
            .firstOrNull ??
        activeSleepRoutineTemplate;
    if (template == null) {
      return;
    }
    _sleepRoutineRunnerState = SleepRoutineRunnerState(
      activeTemplateId: template.id,
      currentStepIndex: 0,
      remainingSeconds: template.steps.firstOrNull?.durationSeconds ?? 0,
      isRunning: true,
      isPaused: false,
      startedAt: DateTime(2026, 3, 30, 22),
    );
    notifyListeners();
  }

  @override
  void pauseSleepRoutine() {
    _sleepRoutineRunnerState = _sleepRoutineRunnerState.copyWith(
      isPaused: true,
      isRunning: true,
    );
    notifyListeners();
  }

  @override
  void resumeSleepRoutine() {
    _sleepRoutineRunnerState = _sleepRoutineRunnerState.copyWith(
      isPaused: false,
      isRunning: true,
    );
    notifyListeners();
  }

  @override
  void advanceSleepRoutine() {
    final template = activeSleepRoutineTemplate;
    if (template == null || template.steps.isEmpty) {
      stopSleepRoutine();
      return;
    }
    final nextIndex = _sleepRoutineRunnerState.currentStepIndex + 1;
    if (nextIndex >= template.steps.length) {
      stopSleepRoutine();
      return;
    }
    _sleepRoutineRunnerState = _sleepRoutineRunnerState.copyWith(
      currentStepIndex: nextIndex,
      remainingSeconds: template.steps[nextIndex].durationSeconds,
      isRunning: true,
      isPaused: false,
    );
    notifyListeners();
  }

  @override
  void tickSleepRoutine() {
    if (!_sleepRoutineRunnerState.isRunning ||
        _sleepRoutineRunnerState.isPaused) {
      return;
    }
    final remaining = _sleepRoutineRunnerState.remainingSeconds;
    if (remaining <= 1) {
      advanceSleepRoutine();
      return;
    }
    _sleepRoutineRunnerState = _sleepRoutineRunnerState.copyWith(
      remainingSeconds: remaining - 1,
    );
    notifyListeners();
  }

  @override
  void stopSleepRoutine() {
    _sleepRoutineRunnerState = const SleepRoutineRunnerState();
    notifyListeners();
  }

  @override
  void setSleepCurrentPlan(SleepPlan? plan) {
    _sleepCurrentPlan = plan;
    notifyListeners();
  }

  @override
  void updateSleepDashboardState(SleepDashboardState state) {
    _sleepDashboardState = state;
    notifyListeners();
  }

  @override
  void startSleepProgram(SleepProgramType type) {
    _sleepProgramProgress = SleepProgramProgress(
      programType: type,
      startedAt: DateTime(2026, 3, 30),
      currentDay: 1,
      completedDays: <int>{},
      isCompleted: false,
    );
    notifyListeners();
  }

  @override
  void completeSleepProgramDay(int day) {
    final progress = _sleepProgramProgress;
    if (progress == null) {
      return;
    }
    final completedDays = Set<int>.from(progress.completedDays)..add(day);
    _sleepProgramProgress = progress.copyWith(
      currentDay: day + 1,
      completedDays: completedDays,
      isCompleted: completedDays.length >= 7,
    );
    notifyListeners();
  }

  @override
  void startSleepNightRescue(SleepNightRescueMode mode) {
    _sleepNightRescueState = SleepNightRescueState(
      mode: mode,
      startedAt: DateTime(2026, 3, 30, 2),
    );
    notifyListeners();
  }

  @override
  void finishSleepNightRescue({
    String? suggestedAction,
    bool hasLeftBed = false,
  }) {
    _sleepNightRescueState = _sleepNightRescueState.copyWith(
      mode: null,
      startedAt: null,
      suggestedAction: suggestedAction,
      hasLeftBed: hasLeftBed,
    );
    notifyListeners();
  }

  @override
  Future<void> addAmbientFileSource() async {}

  @override
  Future<String?> downloadOnlineAmbientSource(
    OnlineAmbientSoundOption option,
  ) async {
    return downloadOnlineAmbientSourceWithProgress(option, null);
  }

  @override
  Future<String?> downloadOnlineAmbientSourceWithProgress(
    OnlineAmbientSoundOption option,
    void Function(ResourceDownloadProgress progress)? onProgress,
  ) async {
    downloadedOnlineAmbientId = option.id;
    _downloadedOnlineAmbientRelativePaths.add(option.relativePath);
    final path = '/tmp/${option.id}.mp3';
    _ambientSources = <AmbientSource>[
      ..._ambientSources,
      AmbientSource(
        id: 'downloaded_${option.id}',
        name: option.name,
        filePath: path,
        enabled: true,
        volume: option.defaultVolume,
        categoryKey: option.categoryKey,
      ),
    ];
    notifyListeners();
    return path;
  }

  @override
  Future<bool> deleteDownloadedOnlineAmbientSource(
    OnlineAmbientSoundOption option,
  ) async {
    deletedDownloadedOnlineAmbientId = option.id;
    _downloadedOnlineAmbientRelativePaths.remove(option.relativePath);
    _ambientSources = _ambientSources
        .where((source) => source.id != 'downloaded_${option.id}')
        .toList(growable: false);
    notifyListeners();
    return true;
  }

  @override
  Future<Set<String>> fetchDownloadedOnlineAmbientRelativePaths() async =>
      Set<String>.from(_downloadedOnlineAmbientRelativePaths);

  @override
  Future<List<OnlineAmbientSoundOption>> fetchOnlineAmbientCatalog({
    bool forceRefresh = false,
  }) async {
    return List<OnlineAmbientSoundOption>.from(_onlineAmbientCatalog);
  }

  @override
  Future<String?> pickBackgroundImageByPicker() async => null;

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
  Future<void> saveAmbientPresetFromCurrentMix(String name) async {
    _ambientPresets = <AmbientPreset>[
      AmbientPreset(
        id: 'preset_${_ambientPresets.length + 1}',
        name: name,
        createdAt: DateTime(2026, 3, 30, 9),
        masterVolume: _ambientMasterVolume,
        entries: _ambientSources
            .where((source) => source.enabled)
            .map(
              (source) => AmbientPresetEntry(
                sourceId: source.id,
                name: source.name,
                volume: source.volume,
                assetPath: source.assetPath,
                filePath: source.filePath,
                remoteUrl: source.remoteUrl,
                remoteKey: source.remoteKey,
                categoryKey: source.categoryKey,
                builtIn: source.builtIn,
              ),
            )
            .toList(growable: false),
      ),
      ..._ambientPresets,
    ];
    notifyListeners();
  }

  @override
  Future<void> applyAmbientPreset(String presetId) async {
    final preset = _ambientPresets
        .where((item) => item.id == presetId)
        .cast<AmbientPreset?>()
        .firstOrNull;
    if (preset == null) {
      return;
    }
    _ambientMasterVolume = preset.masterVolume;
    _ambientSources = preset.entries
        .map(
          (entry) => AmbientSource(
            id: entry.sourceId,
            name: entry.name,
            assetPath: entry.assetPath,
            filePath: entry.filePath,
            remoteUrl: entry.remoteUrl,
            remoteKey: entry.remoteKey,
            categoryKey: entry.categoryKey,
            builtIn: entry.builtIn,
            enabled: true,
            volume: entry.volume,
          ),
        )
        .toList(growable: false);
    _ambientEnabled = _ambientSources.isNotEmpty;
    notifyListeners();
  }

  @override
  Future<void> deleteAmbientPreset(String presetId) async {
    _ambientPresets = _ambientPresets
        .where((preset) => preset.id != presetId)
        .toList(growable: false);
    notifyListeners();
  }

  @override
  Future<void> setAmbientMasterVolume(double value) async {
    _ambientMasterVolume = value;
    notifyListeners();
  }

  @override
  Future<void> setAmbientEnabled(bool value) async {
    _ambientEnabled = value;
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
  Future<String> getDefaultUserDataExportDirectoryPath() async =>
      '/tmp/vocabulary_exports';

  @override
  Future<String?> exportUserData({
    Iterable<UserDataExportSection>? sections,
    String? directoryPath,
    String? fileName,
  }) async {
    exportedUserDataSections = sections?.toSet();
    exportedUserDataDirectoryPath = directoryPath ?? '/tmp/vocabulary_exports';
    exportedUserDataFileName = fileName ?? 'vocabulary_user_data_export.json';
    final resolvedFileName = exportedUserDataFileName!.endsWith('.json')
        ? exportedUserDataFileName!
        : '${exportedUserDataFileName!}.json';
    exportedUserDataPath =
        '${exportedUserDataDirectoryPath!}/$resolvedFileName';
    notifyListeners();
    return exportedUserDataPath;
  }

  @override
  PracticeReviewExportPayload buildPracticeReviewExportPayload({
    Iterable<PracticeSessionRecord>? records,
    Iterable<WordEntry>? wrongNotebookEntries,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    final resolvedHistory = (records ?? _practiceSessionHistory).toList(
      growable: false,
    );
    final resolvedNotebook = (wrongNotebookEntries ?? _recentWeakEntries)
        .toList(growable: false);
    return PracticeReviewExportPayload(
      exportedAt: DateTime(2026, 3, 24),
      summary: const PracticeReviewExportSummary(
        todaySessions: 0,
        todayReviewed: 0,
        todayRemembered: 0,
        totalSessions: 0,
        totalReviewed: 0,
        totalRemembered: 0,
        todayAccuracy: 0,
        totalAccuracy: 0,
        lastSessionTitle: '',
        defaultQuestionType: 'flashcard',
      ),
      metadata: metadata,
      sessionHistory: resolvedHistory,
      wrongNotebook: resolvedNotebook
          .map(
            (entry) => PracticeExportWordEntry(
              id: entry.id,
              wordbookId: entry.wordbookId,
              word: entry.word,
              meaning: entry.meaning ?? '',
              reasons: const <String>[],
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<String?> exportPracticeReviewData({
    required PracticeExportFormat format,
    String? directoryPath,
    String? fileName,
    Iterable<PracticeSessionRecord>? records,
    Iterable<WordEntry>? wrongNotebookEntries,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {
    final resolvedName = fileName ?? 'practice_review.${format.extension}';
    exportedPracticeReviewPath =
        '${directoryPath ?? '/tmp/vocabulary_exports'}/$resolvedName';
    notifyListeners();
    return exportedPracticeReviewPath;
  }

  @override
  PracticeWrongNotebookExportPayload buildPracticeWrongNotebookExportPayload({
    required Iterable<WordEntry> entries,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    final resolvedEntries = entries.toList(growable: false);
    return PracticeWrongNotebookExportPayload(
      exportedAt: DateTime(2026, 3, 24),
      count: resolvedEntries.length,
      metadata: metadata,
      entries: resolvedEntries
          .map(
            (entry) => PracticeExportWordEntry(
              id: entry.id,
              wordbookId: entry.wordbookId,
              word: entry.word,
              meaning: entry.meaning ?? '',
              reasons: const <String>[],
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<String?> exportPracticeWrongNotebookData({
    required Iterable<WordEntry> entries,
    required PracticeExportFormat format,
    String? directoryPath,
    String? fileName,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {
    final resolvedName = fileName ?? 'wrong_notebook.${format.extension}';
    exportedWrongNotebookPath =
        '${directoryPath ?? '/tmp/vocabulary_exports'}/$resolvedName';
    notifyListeners();
    return exportedWrongNotebookPath;
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
  Future<bool> saveWord({
    WordEntry? original,
    required String word,
    required List<WordFieldItem> fields,
    String rawContent = '',
  }) async {
    final normalized = word.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final nextEntry = WordEntry(
      id: original?.id,
      wordbookId: _selectedWordbook?.id ?? 1,
      word: normalized,
      fields: fields,
      rawContent: rawContent,
    );
    if (original == null) {
      _visibleWords.add(nextEntry);
      _currentWordIndex = _visibleWords.length - 1;
    } else {
      final index = _visibleWords.indexWhere(
        (item) => item.word == original.word,
      );
      if (index >= 0) {
        _visibleWords[index] = nextEntry;
        _currentWordIndex = index;
      } else {
        _visibleWords.add(nextEntry);
        _currentWordIndex = _visibleWords.length - 1;
      }
    }
    _currentWord = nextEntry;
    notifyListeners();
    return true;
  }

  @override
  Future<void> importLegacyDatabaseByPicker() async {}

  @override
  Future<int> importWordsBatch(List<WordEntryPayload> payloads) async {
    var imported = 0;
    for (final payload in payloads) {
      final normalized = payload.word.trim();
      if (normalized.isEmpty) {
        continue;
      }
      _visibleWords.add(
        WordEntry(
          wordbookId: _selectedWordbook?.id ?? 1,
          word: normalized,
          fields: payload.fields,
          rawContent: payload.rawContent,
        ),
      );
      imported += 1;
    }
    if (imported > 0) {
      notifyListeners();
    }
    return imported;
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
  Future<void> clearTaskWordbook() async {
    if (_taskWords.isEmpty) {
      return;
    }
    _taskWords.clear();
    notifyListeners();
  }

  @override
  Future<void> exportTaskWordbook(String name) async {
    exportedTaskWordbookName = name;
  }

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
  Future<void> selectWordEntry(WordEntry entry) async {
    _currentWord = entry;
    final index = _visibleWords.indexWhere((item) => item.word == entry.word);
    if (index >= 0) {
      _currentWordIndex = index;
    }
    notifyListeners();
  }

  @override
  void selectWordIndex(int index) {
    if (_visibleWords.isEmpty) {
      _currentWord = null;
      _currentWordIndex = 0;
      notifyListeners();
      return;
    }
    final normalized = index.clamp(0, _visibleWords.length - 1);
    _currentWordIndex = normalized;
    _currentWord = _visibleWords[normalized];
    notifyListeners();
  }

  @override
  void selectWordByText(String word) {
    final index = _visibleWords.indexWhere((item) => item.word == word);
    if (index >= 0) {
      selectWordIndex(index);
    }
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
  Future<void> toggleFavorite(WordEntry word) async {
    final key = word.collectionReferenceKey;
    if (_favorites.contains(key)) {
      _favorites.remove(key);
    } else {
      _favorites.add(key);
    }
    notifyListeners();
  }

  @override
  Future<void> toggleTaskWord(WordEntry word) async {
    final key = word.collectionReferenceKey;
    if (_taskWords.contains(key)) {
      _taskWords.remove(key);
    } else {
      _taskWords.add(key);
    }
    notifyListeners();
  }

  @override
  bool isFavoriteEntry(WordEntry entry) {
    return _favorites.contains(entry.collectionReferenceKey);
  }

  @override
  bool isTaskEntry(WordEntry entry) {
    return _taskWords.contains(entry.collectionReferenceKey);
  }

  @override
  Future<bool> restoreUserDataExport(String filePath) async {
    return false;
  }

  @override
  void recordPracticeSession({
    required String title,
    required int total,
    required int remembered,
    required List<String> rememberedWords,
    required List<String> weakWords,
    List<WordEntry>? rememberedEntries,
    List<WordEntry>? weakEntries,
    Map<String, List<String>> weakReasonIdsByWord =
        const <String, List<String>>{},
  }) {
    _practiceTodaySessions += 1;
    _practiceTodayReviewed += total;
    _practiceTodayRemembered += remembered;
    _practiceTotalSessions += 1;
    _practiceTotalReviewed += total;
    _practiceTotalRemembered += remembered;
    _practiceLastSessionTitle = title;
    _recentRememberedEntries = _resolvePracticeEntries(
      rememberedWords,
      preferredEntries: rememberedEntries,
    );
    _recentWeakEntries = _resolvePracticeEntries(
      weakWords,
      preferredEntries: weakEntries,
    );
    _practiceWeakReasonsByWord
      ..clear()
      ..addAll(weakReasonIdsByWord);
    _practiceSessionHistory = <PracticeSessionRecord>[
      PracticeSessionRecord(
        title: title,
        practicedAt: DateTime(2026, 3, 20, 10, 0),
        total: total,
        remembered: remembered,
      ),
      ..._practiceSessionHistory,
    ];
    notifyListeners();
  }

  @override
  void startPracticeSession({required String title}) {
    _practiceTodaySessions += 1;
    _practiceTotalSessions += 1;
    _practiceLastSessionTitle = title;
    notifyListeners();
  }

  @override
  void recordPracticeAnswer({
    required WordEntry entry,
    required bool remembered,
    List<String> weakReasonIds = const <String>[],
    bool addToWrongNotebook = true,
    String? sessionTitle,
  }) {
    _practiceTodayReviewed += 1;
    _practiceTotalReviewed += 1;
    if (remembered) {
      _practiceTodayRemembered += 1;
      _practiceTotalRemembered += 1;
      if (_recentRememberedEntries.every((item) => !_isSameWord(item, entry))) {
        _recentRememberedEntries = <WordEntry>[
          entry,
          ..._recentRememberedEntries,
        ];
      }
      _recentWeakEntries = _recentWeakEntries
          .where((item) => !_isSameWord(item, entry))
          .toList(growable: false);
      _practiceWeakReasonsByWord.remove(_reasonKey(entry));
    } else {
      if (addToWrongNotebook &&
          _recentWeakEntries.every((item) => !_isSameWord(item, entry))) {
        _recentWeakEntries = <WordEntry>[entry, ..._recentWeakEntries];
      }
      if (addToWrongNotebook) {
        _practiceWeakReasonsByWord[_reasonKey(entry)] = weakReasonIds.isEmpty
            ? const <String>['recall']
            : List<String>.from(weakReasonIds, growable: false);
      }
    }
    notifyListeners();
  }

  @override
  void finishPracticeSession({
    required String title,
    required int total,
    required int remembered,
    Map<String, List<String>> weakReasonIdsByWord =
        const <String, List<String>>{},
  }) {
    _practiceLastSessionTitle = title;
    _practiceSessionHistory = <PracticeSessionRecord>[
      PracticeSessionRecord(
        title: title,
        practicedAt: DateTime(2026, 3, 24, 9, 0),
        total: total,
        remembered: remembered,
        weakReasonCounts: <String, int>{
          for (final entry in weakReasonIdsByWord.values.expand((item) => item))
            entry: weakReasonIdsByWord.values
                .expand((item) => item)
                .where((item) => item == entry)
                .length,
        },
      ),
      ..._practiceSessionHistory,
    ];
    notifyListeners();
  }

  @override
  List<WordEntry> beginPracticeBatch({
    required String cursorKey,
    required List<WordEntry> sourceWords,
    required int batchSize,
    WordEntry? anchorWord,
    int? cursorAdvance,
  }) {
    if (sourceWords.isEmpty || batchSize <= 0) {
      return const <WordEntry>[];
    }
    final trimmedKey = cursorKey.trim();
    final anchorIndex = anchorWord == null
        ? -1
        : sourceWords.indexWhere((entry) => _isSameWord(entry, anchorWord));
    final startIndex = anchorIndex >= 0
        ? anchorIndex
        : (_practiceLaunchCursors[trimmedKey] ?? 0) % sourceWords.length;
    final safeBatchSize = batchSize.clamp(1, sourceWords.length);
    final output = <WordEntry>[];
    for (var offset = 0; offset < safeBatchSize; offset += 1) {
      output.add(sourceWords[(startIndex + offset) % sourceWords.length]);
    }
    if (trimmedKey.isNotEmpty) {
      _practiceLaunchCursors[trimmedKey] =
          (startIndex + (cursorAdvance ?? safeBatchSize)) % sourceWords.length;
    }
    return output;
  }

  @override
  void updatePracticeRoundSettings({
    PracticeRoundSource? source,
    PracticeRoundStartMode? startMode,
    int? roundSize,
    bool? shuffle,
    bool? collapsed,
  }) {
    _practiceRoundSettings = _practiceRoundSettings.copyWith(
      source: source,
      startMode: startMode,
      roundSize: roundSize,
      shuffle: shuffle,
      collapsed: collapsed,
    );
    notifyListeners();
  }

  @override
  int previewPracticeBatchStartIndex({
    required String cursorKey,
    required List<WordEntry> sourceWords,
    PracticeRoundStartMode? startMode,
    WordEntry? anchorWord,
  }) {
    if (sourceWords.isEmpty) {
      return 0;
    }
    final resolvedStartMode = startMode ?? _practiceRoundSettings.startMode;
    return switch (resolvedStartMode) {
      PracticeRoundStartMode.fromStart => 0,
      PracticeRoundStartMode.currentWord =>
        sourceWords
            .indexWhere(
              (entry) => _isSameWord(entry, anchorWord ?? sourceWords.first),
            )
            .clamp(0, sourceWords.length - 1),
      PracticeRoundStartMode.resumeCursor =>
        (_practiceLaunchCursors[cursorKey.trim()] ?? 0) % sourceWords.length,
    };
  }

  @override
  void updatePracticeSessionPreferences({
    bool? autoAddWeakWordsToTask,
    bool? autoPlayPronunciation,
    bool? showHintsByDefault,
    bool? showAnswerFeedbackDialog,
    PracticeQuestionType? defaultQuestionType,
  }) {
    if (autoAddWeakWordsToTask != null) {
      _practiceAutoAddWeakWordsToTask = autoAddWeakWordsToTask;
    }
    if (autoPlayPronunciation != null) {
      _practiceAutoPlayPronunciation = autoPlayPronunciation;
    }
    if (showHintsByDefault != null) {
      _practiceShowHintsByDefault = showHintsByDefault;
    }
    if (showAnswerFeedbackDialog != null) {
      _practiceShowAnswerFeedbackDialog = showAnswerFeedbackDialog;
    }
    if (defaultQuestionType != null) {
      _practiceDefaultQuestionType = defaultQuestionType;
    }
    notifyListeners();
  }

  @override
  bool dismissPracticeWeakWord(WordEntry entry) {
    final previousLength = _recentWeakEntries.length;
    _recentWeakEntries = _recentWeakEntries
        .where((item) => item.word != entry.word)
        .toList(growable: false);
    _practiceWeakReasonsByWord.remove(entry.word.trim().toLowerCase());
    if (previousLength == _recentWeakEntries.length) {
      return false;
    }
    notifyListeners();
    return true;
  }

  @override
  int dismissPracticeWeakWords(Iterable<WordEntry> entries) {
    final keys = entries.map((item) => item.word).toSet();
    final previousLength = _recentWeakEntries.length;
    _recentWeakEntries = _recentWeakEntries
        .where((item) => !keys.contains(item.word))
        .toList(growable: false);
    _practiceWeakReasonsByWord.removeWhere((key, _) => keys.contains(key));
    final removed = previousLength - _recentWeakEntries.length;
    if (removed > 0) {
      notifyListeners();
    }
    return removed;
  }

  @override
  Future<int> addPracticeWordsToTask(Iterable<WordEntry> entries) async {
    var added = 0;
    for (final entry in entries) {
      if (_taskWords.add(entry.word)) {
        added += 1;
      }
    }
    if (added > 0) {
      notifyListeners();
    }
    return added;
  }

  @override
  Future<int> addPracticeWordsToFavorites(Iterable<WordEntry> entries) async {
    var added = 0;
    for (final entry in entries) {
      if (_favorites.add(entry.word)) {
        added += 1;
      }
    }
    if (added > 0) {
      notifyListeners();
    }
    return added;
  }

  @override
  int clearPracticeWeakWords({bool masteredOnly = false}) {
    final removed = _recentWeakEntries.length;
    _recentWeakEntries = <WordEntry>[];
    _practiceWeakReasonsByWord.clear();
    if (removed > 0) {
      notifyListeners();
    }
    return removed;
  }

  List<WordEntry> _resolvePracticeEntries(
    List<String> trackedWords, {
    List<WordEntry>? preferredEntries,
  }) {
    if (preferredEntries != null && preferredEntries.isNotEmpty) {
      return List<WordEntry>.from(preferredEntries);
    }
    if (trackedWords.isEmpty) {
      return const <WordEntry>[];
    }

    final byWord = <String, WordEntry>{
      for (final entry in _visibleWords) entry.word.toLowerCase(): entry,
    };
    return trackedWords
        .map((word) => byWord[word.toLowerCase()])
        .whereType<WordEntry>()
        .toList(growable: false);
  }

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
  void setStartupPage(AppHomeTab page) {
    _startupPage = page;
    notifyListeners();
  }

  @override
  void setFocusStartupTab(FocusStartupTab tab) {
    _focusStartupTab = tab;
    notifyListeners();
  }

  @override
  void setWeatherEnabled(bool enabled) {
    _weatherEnabled = enabled;
    notifyListeners();
  }

  @override
  void setStartupTodoPromptEnabled(bool enabled) {
    _startupTodoPromptEnabled = enabled;
    notifyListeners();
  }

  @override
  void suppressStartupTodoPromptForToday() {
    startupPromptSuppressedToday = true;
    _startupTodoPromptEnabled = false;
    notifyListeners();
  }

  @override
  Future<void> refreshWeather({bool force = false}) async {
    _weatherLoading = true;
    notifyListeners();
    _weatherLoading = false;
    notifyListeners();
  }

  @override
  Future<void> refreshStartupTodoPromptContent({bool force = false}) async {}

  @override
  void refreshWeatherIfStale() {}

  @override
  void setTestModeEnabled(bool enabled) {
    _testModeEnabled = enabled;
    notifyListeners();
  }

  @override
  void toggleTestModeReveal() {
    _testModeRevealed = !_testModeRevealed;
    notifyListeners();
  }

  @override
  void toggleTestModeHint() {
    _testModeHintRevealed = !_testModeHintRevealed;
    notifyListeners();
  }

  @override
  void resetTestModeProgress() {
    _testModeRevealed = false;
    _testModeHintRevealed = false;
    notifyListeners();
  }

  @override
  void updateConfig(PlayConfig config) {
    _config = config;
    notifyListeners();
  }

  @override
  Future<String?> startVoiceInputRecording({bool forceRecorder = false}) async {
    return _asrRecordingPath;
  }

  @override
  Future<String?> stopVoiceInputRecording() async {
    return _asrStoppedRecordingPath ?? _asrRecordingPath;
  }

  @override
  Future<void> cancelVoiceInputRecording() async {}

  @override
  void stopVoiceInputProcessing() {}

  @override
  Future<AsrResult> transcribeVoiceInputRecording(
    String audioPath, {
    AsrProgressCallback? onProgress,
  }) async {
    return transcribeRecording(audioPath, onProgress: onProgress);
  }

  @override
  Future<AsrOfflineModelStatus> getVoiceInputOfflineModelStatus() async {
    return getAsrOfflineModelStatus(AsrProviderType.offline);
  }

  @override
  Future<void> prepareVoiceInputOfflineModel({
    AsrProgressCallback? onProgress,
  }) async {}

  @override
  Future<void> removeVoiceInputOfflineModel() async {}

  @override
  Future<void> ensureRemoteResourcePrewarmOnDemand() async {}

  @override
  Future<void> refreshBuiltInWordbookCatalog() async {}

  @override
  PronunciationComparison comparePronunciation(
    String expected,
    String recognized,
  ) {
    return AppState.comparePronunciationTexts(
      expected: expected,
      recognized: recognized,
    );
  }

  bool _isSameWord(WordEntry left, WordEntry right) {
    final leftId = left.id;
    final rightId = right.id;
    if (leftId != null && rightId != null) {
      return leftId == rightId;
    }
    return left.wordbookId == right.wordbookId && left.word == right.word;
  }

  String _reasonKey(WordEntry entry) => entry.word.trim().toLowerCase();
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
       ) {
    _timerListenable = ValueNotifier<TomatoTimerState>(_state);
  }

  factory _FakeFocusService.sample() => _FakeFocusService();

  TomatoTimerConfig _config;
  TomatoTimerState _state;
  bool _lockScreenActive;
  bool _reminderAcknowledgementPending;
  TomatoTimerPhase? _pendingReminderPhase;
  TodoReminderLaunchAction? _pendingTodoReminderAction;
  final List<TodoItem> _todos;
  final List<PlanNote> _notes;
  late final ValueNotifier<TomatoTimerState> _timerListenable;
  final ValueNotifier<int> _viewRevision = ValueNotifier<int>(0);

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
  ValueListenable<TomatoTimerState> get timerListenable => _timerListenable;

  @override
  ValueListenable<int> get viewRevision => _viewRevision;

  void _publishTimerState() {
    _timerListenable.value = _state;
    notifyListeners();
  }

  void _publishViewState() {
    _viewRevision.value += 1;
    notifyListeners();
  }

  void _publishAll() {
    _timerListenable.value = _state;
    _viewRevision.value += 1;
    notifyListeners();
  }

  @override
  void setLockScreenActive(bool value) {
    _lockScreenActive = value;
    _publishViewState();
  }

  @override
  Future<void> acknowledgeReminder() async {
    _reminderAcknowledgementPending = false;
    _pendingReminderPhase = null;
    _publishViewState();
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
    bool syncToSystemCalendar = true,
    bool systemCalendarNotificationEnabled = true,
    int systemCalendarNotificationMinutesBefore = 0,
    bool systemCalendarAlarmEnabled = false,
    int systemCalendarAlarmMinutesBefore = 10,
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
        syncToSystemCalendar: syncToSystemCalendar,
        systemCalendarNotificationEnabled: systemCalendarNotificationEnabled,
        systemCalendarNotificationMinutesBefore:
            systemCalendarNotificationMinutesBefore,
        systemCalendarAlarmEnabled: systemCalendarAlarmEnabled,
        systemCalendarAlarmMinutesBefore: systemCalendarAlarmMinutesBefore,
      ),
    );
    _publishViewState();
  }

  @override
  void advanceToNextPhase() {
    _state = const TomatoTimerState();
    _publishTimerState();
  }

  @override
  void clearCompletedTodos() {
    _todos.removeWhere((todo) => todo.completed);
    _publishViewState();
  }

  @override
  void deleteNote(int id) {
    _notes.removeWhere((note) => note.id == id);
    _publishViewState();
  }

  @override
  void deleteNotes(List<int> ids) {
    _notes.removeWhere((note) => ids.contains(note.id));
    _publishViewState();
  }

  @override
  void deleteTodo(int id) {
    _todos.removeWhere((todo) => todo.id == id);
    _publishViewState();
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
  Future<int?> consumePendingTodoReminderLaunchId() async => null;

  @override
  Future<TodoReminderLaunchAction?> consumePendingTodoReminderAction() async {
    final pending = _pendingTodoReminderAction;
    _pendingTodoReminderAction = null;
    return pending;
  }

  @override
  Future<TodoReminderCapability> getTodoReminderCapability() async {
    return const TodoReminderCapability(
      notificationsGranted: true,
      notificationPermissionRequestable: false,
      exactAlarmGranted: true,
      exactAlarmSettingsAvailable: false,
    );
  }

  @override
  Future<bool> requestTodoReminderNotificationPermission() async => true;

  @override
  Future<void> openTodoReminderExactAlarmSettings() async {}

  @override
  void completeTodo(int id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index < 0) return;
    final current = _todos[index];
    _todos[index] = current.copyWith(
      completed: true,
      deferred: false,
      completedAt: DateTime(2026, 3, 14),
    );
    _publishViewState();
  }

  @override
  void snoozeTodoReminder(int id, Duration duration) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index < 0) return;
    final current = _todos[index];
    _todos[index] = current.copyWith(
      dueAt: DateTime(2026, 3, 14).add(duration),
      alarmEnabled: true,
    );
    _publishViewState();
  }

  @override
  void pause() {
    _state = _state.copyWith(isPaused: true);
    _publishTimerState();
  }

  @override
  void pauseOrResume() {
    if (_state.isPaused) {
      resume();
      return;
    }
    pause();
  }

  @override
  void reorderNotes(List<PlanNote> orderedNotes) {
    _notes
      ..clear()
      ..addAll(orderedNotes);
    _publishViewState();
  }

  @override
  void reorderTodos(List<TodoItem> orderedTodos) {
    _todos
      ..clear()
      ..addAll(orderedTodos);
    _publishViewState();
  }

  @override
  void resume() {
    _state = _state.copyWith(isPaused: false);
    _publishTimerState();
  }

  @override
  void saveConfig(TomatoTimerConfig config) {
    _config = config;
    _publishViewState();
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
      _todos.add(normalized.copyWith(id: (_todos.lastOrNull?.id ?? 0) + 1));
    }
    _publishViewState();
  }

  @override
  void updateTodo(TodoItem item) {
    saveTodo(item);
  }

  @override
  void saveReminderConfig(TimerReminderConfig reminder) {
    _config = _config.copyWith(reminder: reminder);
    _publishViewState();
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
    _publishTimerState();
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
    _publishAll();
  }

  @override
  void stop({bool saveProgress = true}) {
    _state = const TomatoTimerState();
    _publishAll();
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
    _publishViewState();
  }

  @override
  void updateNote(PlanNote note) {
    final index = _notes.indexWhere((item) => item.id == note.id);
    if (index < 0) return;
    _notes[index] = note;
    _publishViewState();
  }

  @override
  List<TomatoTimerRecord> getTimerRecords({int limit = 30}) {
    return const <TomatoTimerRecord>[];
  }
}

extension<T> on List<T> {
  T? get firstOrNull => this.isEmpty ? null : first;

  T? get lastOrNull => this.isEmpty ? null : last;
}

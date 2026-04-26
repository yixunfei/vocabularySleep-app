import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/i18n/app_i18n.dart';
import 'package:vocabulary_sleep_app/src/models/weather_snapshot.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_cook_service.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_eat_library_store.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_eat_support.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_recipe_library.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_storage.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_widgets.dart';

void main() {
  DailyChoiceOption eatOption({
    required String id,
    required String title,
    String categoryId = 'lunch',
    String? contextId = 'pot',
    List<String> contextIds = const <String>['pot'],
    List<String> materials = const <String>[],
    List<String> steps = const <String>['Step 1'],
    List<String> notes = const <String>[],
    List<String> tags = const <String>[],
  }) {
    return ensureEatOptionAttributes(
      DailyChoiceOption(
        id: id,
        moduleId: DailyChoiceModuleId.eat.storageValue,
        categoryId: categoryId,
        contextId: contextId,
        contextIds: contextIds,
        titleZh: title,
        titleEn: title,
        subtitleZh: '$title summary',
        subtitleEn: '$title summary',
        detailsZh: '$title full detail',
        detailsEn: '$title full detail',
        materialsZh: materials,
        materialsEn: materials,
        stepsZh: steps,
        stepsEn: steps,
        notesZh: notes,
        notesEn: notes,
        tagsZh: tags,
        tagsEn: tags,
      ),
    );
  }

  Future<void> pumpEatHub(
    WidgetTester tester, {
    required _FakeCookService cookService,
    required _FakeEatLibraryStore libraryStore,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DailyChoiceHub(
                    storage: _FakeStorageService(),
                    cookService: cookService,
                    eatLibraryStore: libraryStore,
                    weatherStateOverride: DailyChoiceHubWeatherState(
                      weatherEnabled: false,
                      weatherLoading: false,
                      weatherSnapshot: WeatherSnapshot(
                        city: 'Test',
                        countryCode: 'CN',
                        temperatureCelsius: 22,
                        apparentTemperatureCelsius: 22,
                        windSpeedKph: 0,
                        weatherCode: 1,
                        isDay: true,
                        fetchedAt: DateTime(2026, 4, 25, 17, 0),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> pumpUntilVisible(
    WidgetTester tester,
    Finder finder, {
    int maxTicks = 40,
    Duration step = const Duration(milliseconds: 100),
  }) async {
    for (var index = 0; index < maxTicks; index += 1) {
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      await tester.pump(step);
    }
  }

  testWidgets(
    'DailyChoiceHub eat page stays interactive with lightweight install and lazy details',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final options = <DailyChoiceOption>[
        eatOption(
          id: 'tomato_egg',
          title: 'Tomato Egg',
          materials: const <String>['tomato', 'egg'],
          steps: const <String>['Beat the egg', 'Cook tomato and egg'],
          tags: const <String>['home style'],
        ),
        eatOption(
          id: 'mushroom_soup',
          title: 'Mushroom Soup',
          materials: const <String>['mushroom', 'tofu'],
          steps: const <String>['Boil soup base', 'Simmer mushroom and tofu'],
          tags: const <String>['soup'],
        ),
        eatOption(
          id: 'cilantro_beef',
          title: 'Cilantro Beef',
          materials: const <String>['cilantro', 'beef'],
          steps: const <String>['Slice beef', 'Stir fry with cilantro'],
          tags: const <String>['stir fry'],
        ),
      ];
      final result = DailyChoiceCookLoadResult(
        options: options,
        source: DailyChoiceCookDataSource.remote,
        localLibraryCount: options.length,
        referenceTitles: const <String>['Test reference'],
        updatedAt: DateTime(2026, 4, 25, 16, 30),
      );
      final document = DailyChoiceRecipeLibraryDocument(
        libraryId: DailyChoiceRecipeLibraryDocument.defaultLibraryId,
        libraryVersion: '2026-04-25',
        schemaId: DailyChoiceRecipeLibraryDocument.defaultSchemaId,
        schemaVersion: DailyChoiceRecipeLibraryDocument.defaultSchemaVersion,
        generatedAt: result.updatedAt,
        referenceTitles: result.referenceTitles,
        stats: <String, Object?>{'recipeCount': options.length},
        recipes: options,
      );
      final cookService = _FakeCookService(result, document);
      final libraryStore = _FakeEatLibraryStore(document);

      await pumpEatHub(
        tester,
        cookService: cookService,
        libraryStore: libraryStore,
      );
      await pumpUntilVisible(tester, find.text('Load recipe library'));

      expect(find.text('Load recipe library'), findsOneWidget);

      await tester.tap(find.text('Load recipe library'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Advanced settings'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Advanced settings')).dy,
        lessThan(tester.getTopLeft(find.text('Randomize')).dy),
      );
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Expand'));
      await tester.tap(find.text('Expand'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.first, 'tomato, egg, tofu');
      await tester.tap(find.text('Add ingredient'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(InputChip), findsNWidgets(3));

      await tester.enterText(textFields.at(1), 'cilantro');
      await tester.tap(find.text('Add avoid'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(InputChip), findsNWidgets(4));

      await tester.ensureVisible(find.text('Randomize'));
      await tester.tap(find.text('Randomize'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Stop'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('Details'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Materials'), findsOneWidget);
      expect(find.text('Steps'), findsOneWidget);
      expect(find.textContaining('full detail'), findsOneWidget);
      expect(libraryStore.detailRequests, isNotEmpty);

      Navigator.of(tester.element(find.text('Materials'))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Manage'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Search recipe name'), findsOneWidget);
      final managerSheet = find.byType(DraggableScrollableSheet).first;
      await tester.tap(
        find.descendant(of: managerSheet, matching: find.text('Add recipe')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Save'), findsOneWidget);
      expect(tester.takeException(), isNull);

      Navigator.of(tester.element(find.text('Save'))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(
        find
            .descendant(of: managerSheet, matching: find.byType(TextField))
            .first,
        'mushroom',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.ensureVisible(
        find.descendant(
          of: managerSheet,
          matching: find.text('Built-in items'),
        ),
      );
      await tester.tap(
        find.descendant(
          of: managerSheet,
          matching: find.text('Built-in items'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.descendant(of: managerSheet, matching: find.text('Mushroom Soup')),
        findsWidgets,
      );
      expect(
        find.descendant(of: managerSheet, matching: find.text('Tomato Egg')),
        findsNothing,
      );

      await tester.tap(
        find.descendant(of: managerSheet, matching: find.text('Adjust')).first,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Save'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.descendant(
          of: managerSheet,
          matching: find.text('Restore original'),
        ),
        findsWidgets,
      );

      await tester.tap(
        find
            .descendant(of: managerSheet, matching: find.text('Mushroom Soup'))
            .first,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Mushroom Soup'), findsWidgets);
      expect(find.text('Materials'), findsOneWidget);
      expect(find.textContaining('Mushroom Soup full detail'), findsOneWidget);
      expect(libraryStore.detailRequests, contains('mushroom_soup'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('eat recipe editor tolerates duplicated all context entries', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () {
                  unawaited(
                    showDailyChoiceEditorSheet(
                      context: context,
                      i18n: AppI18n('en'),
                      accent: Colors.orange,
                      moduleId: DailyChoiceModuleId.eat.storageValue,
                      categories: mealCategories,
                      initialCategoryId: 'lunch',
                      contexts: <DailyChoiceCategory>[
                        cookToolCategories.first,
                        ...cookToolCategories,
                      ],
                      initialContextId: 'all',
                      contextLabelZh: '厨具',
                      contextLabelEn: 'Tool',
                    ),
                  );
                },
                child: const Text('Open editor'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open editor'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('All tools'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FakeStorageService extends DailyChoiceStorageService {
  @override
  Future<DailyChoiceCustomState> load() async => DailyChoiceCustomState.empty;

  @override
  Future<void> save(DailyChoiceCustomState state) async {}
}

class _FakeCookService extends DailyChoiceCookService {
  _FakeCookService(this.result, this.document);

  final DailyChoiceCookLoadResult result;
  final DailyChoiceRecipeLibraryDocument document;

  @override
  Future<DailyChoiceCookLoadResult?> loadBundled() async => result;

  @override
  Future<DailyChoiceCookLoadResult?> loadCached() async => null;

  @override
  Future<bool> shouldRefreshRemote() async => false;

  @override
  Future<DailyChoiceCookLoadResult> refresh() async => result;

  @override
  Future<DailyChoiceRecipeLibraryDocument?>
  exportBundledLibraryDocument() async {
    return document;
  }
}

class _FakeEatLibraryStore extends DailyChoiceEatLibraryStore {
  _FakeEatLibraryStore(this.document);

  final DailyChoiceRecipeLibraryDocument document;
  final List<String> detailRequests = <String>[];
  bool _installed = false;

  List<DailyChoiceOption> get _options =>
      document.recipes.map(ensureEatOptionAttributes).toList(growable: false);

  @override
  Future<DailyChoiceEatLibraryStatus> inspectStatus() async {
    if (!_installed) {
      return const DailyChoiceEatLibraryStatus.empty();
    }
    return DailyChoiceEatLibraryStatus(
      hasInstalledLibrary: true,
      recipeCount: _options.length,
      localLibraryCount: _options.length,
      referenceTitles: document.referenceTitles,
      libraryId: document.libraryId,
      libraryVersion: document.libraryVersion,
      schemaId: document.schemaId,
      schemaVersion: document.schemaVersion,
      source: DailyChoiceCookDataSource.remote,
      installedAt: document.generatedAt,
      updatedAt: document.generatedAt,
    );
  }

  @override
  Future<DailyChoiceEatLibraryStatus> installLibrary() async {
    _installed = true;
    return inspectStatus();
  }

  @override
  Future<List<DailyChoiceOption>> loadBuiltInSummaries() async {
    if (!_installed) {
      return const <DailyChoiceOption>[];
    }
    return List<DailyChoiceOption>.unmodifiable(
      _options.map(
        (option) => ensureEatOptionAttributes(
          option.copyWith(
            detailsZh: '',
            detailsEn: '',
            materialsZh: const <String>[],
            materialsEn: const <String>[],
            stepsZh: const <String>[],
            stepsEn: const <String>[],
            notesZh: const <String>[],
            notesEn: const <String>[],
          ),
        ),
      ),
    );
  }

  @override
  Future<DailyChoiceOption?> loadBuiltInDetail(String recipeId) async {
    detailRequests.add(recipeId);
    for (final option in _options) {
      if (option.id == recipeId) {
        return option;
      }
    }
    return null;
  }

  @override
  Future<void> close() async {}
}

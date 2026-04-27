import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_cook_service.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_eat_library_store.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_eat_support.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_recipe_library.dart';

void main() {
  DailyChoiceOption eatOption({
    required String id,
    required String title,
    required List<String> materials,
    List<String> steps = const <String>['步骤 1'],
    List<String> tags = const <String>[],
    String categoryId = 'lunch',
    String contextId = 'pot',
    List<String> contextIds = const <String>['pot'],
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
        subtitleZh: '$title 简介',
        subtitleEn: '$title subtitle',
        detailsZh: '$title 详情',
        detailsEn: '$title details',
        materialsZh: materials,
        materialsEn: materials,
        stepsZh: steps,
        stepsEn: steps,
        notesZh: const <String>['厨房提示'],
        notesEn: const <String>['Kitchen note'],
        tagsZh: tags,
        tagsEn: tags,
      ),
    );
  }

  test(
    'DailyChoiceEatLibraryStore installs v2-only SQLite and lazy loads details',
    () async {
      final options = <DailyChoiceOption>[
        eatOption(
          id: 'library_tomato_egg',
          title: '番茄鸡蛋',
          materials: const <String>['番茄', '鸡蛋'],
        ),
        eatOption(
          id: 'cook_csv_tofu_soup',
          title: '豆腐汤',
          materials: const <String>['豆腐', '香菇'],
          tags: const <String>['汤'],
          categoryId: 'dinner',
        ),
      ];
      final updatedAt = DateTime(2026, 4, 27, 10, 54);
      final document = DailyChoiceRecipeLibraryDocument(
        libraryId: DailyChoiceRecipeLibraryDocument.defaultLibraryId,
        libraryVersion: '2026-04-25',
        schemaId: 'vocabulary_sleep.daily_choice.recipe_library.v2',
        schemaVersion: 2,
        generatedAt: updatedAt,
        stats: <String, Object?>{
          'bookRecipeCount': 1,
          'cookRecipeCount': 1,
          'dedupedRecipeCount': options.length,
        },
        recipes: options,
      );
      final tempDirectory = await Directory.systemTemp.createTemp(
        'daily_choice_eat_library_store_test_',
      );

      final store = DailyChoiceEatLibraryStore(
        supportDirectoryProvider: () async => tempDirectory,
        remoteDatabaseInstaller: (targetFile) async {
          await _writeV2LibraryDatabase(
            targetFile,
            document,
            updatedAt: updatedAt,
          );
          return updatedAt;
        },
      );
      addTearDown(() async {
        await store.close();
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final installedStatus = await store.installLibrary();
      expect(installedStatus.hasInstalledLibrary, isTrue);
      expect(installedStatus.recipeCount, options.length);
      expect(installedStatus.localLibraryCount, 1);
      expect(installedStatus.cookRecipeCount, 1);
      expect(installedStatus.schemaVersion, 2);
      expect(installedStatus.source, DailyChoiceCookDataSource.remote);
      expect(installedStatus.updatedAt, updatedAt);

      final summaries = await store.loadBuiltInSummaries();
      expect(summaries, hasLength(options.length));
      expect(summaries.map((item) => item.id), contains('cook_csv_tofu_soup'));
      final summary = summaries.firstWhere(
        (item) => item.id == 'cook_csv_tofu_soup',
      );
      expect(summary.detailsZh, isEmpty);
      expect(summary.materialsZh, isEmpty);
      expect(summary.stepsZh, isEmpty);
      expect(summary.categoryId, 'dinner');
      expect(summary.contextIds, contains('pot'));
      expect(summary.attributeValues(eatAttributeIngredient), contains('tofu'));

      final detail = await store.loadBuiltInDetail('cook_csv_tofu_soup');
      expect(detail, isNotNull);
      expect(detail!.detailsZh, contains('豆腐汤'));
      expect(detail.materialsZh, containsAll(<String>['豆腐', '香菇']));
      expect(detail.stepsZh, isNotEmpty);
      expect(detail.categoryId, 'dinner');
    },
  );

  test(
    'DailyChoiceEatLibraryStore queries v2 summaries through SQL indexes',
    () async {
      final options = <DailyChoiceOption>[
        eatOption(
          id: 'cilantro_soup',
          title: '番茄香菜豆腐汤',
          materials: const <String>['番茄', '豆腐', '香菜'],
        ),
        eatOption(
          id: 'mushroom_soup',
          title: '香菇白菜汤',
          materials: const <String>['香菇', '白菜'],
        ),
        eatOption(
          id: 'beef_stir_fry',
          title: '土豆牛肉炒',
          materials: const <String>['土豆', '牛肉'],
        ),
        eatOption(
          id: 'oven_dessert',
          title: '烤布丁',
          materials: const <String>['牛奶', '鸡蛋'],
          categoryId: 'tea',
          contextId: 'oven',
          contextIds: const <String>['oven'],
        ),
        eatOption(id: 'ribs', title: '红烧排骨', materials: const <String>['排骨']),
        eatOption(
          id: 'pork',
          title: '猪肉炒豆角',
          materials: const <String>['猪肉', '豆角'],
        ),
        eatOption(
          id: 'peanut',
          title: '花生拌菠菜',
          materials: const <String>['花生', '菠菜'],
        ),
        eatOption(
          id: 'walnut',
          title: '核桃拌黄瓜',
          materials: const <String>['核桃', '黄瓜'],
        ),
      ];
      final updatedAt = DateTime(2026, 4, 27, 14, 20);
      final document = DailyChoiceRecipeLibraryDocument(
        libraryId: DailyChoiceRecipeLibraryDocument.defaultLibraryId,
        libraryVersion: '2026-04-27',
        schemaId: 'vocabulary_sleep.daily_choice.recipe_library.v2',
        schemaVersion: 2,
        generatedAt: updatedAt,
        stats: <String, Object?>{
          'bookRecipeCount': options.length,
          'cookRecipeCount': 0,
          'dedupedRecipeCount': options.length,
        },
        recipes: options,
      );
      final tempDirectory = await Directory.systemTemp.createTemp(
        'daily_choice_eat_library_store_test_',
      );
      final store = DailyChoiceEatLibraryStore(
        supportDirectoryProvider: () async => tempDirectory,
        remoteDatabaseInstaller: (targetFile) async {
          await _writeV2LibraryDatabase(
            targetFile,
            document,
            updatedAt: updatedAt,
          );
          return updatedAt;
        },
      );
      addTearDown(() async {
        await store.close();
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });
      await store.installLibrary();

      final traitFilters = <String, Set<String>>{
        eatAttributeType: <String>{'soup'},
        eatAttributeProfile: <String>{eatProfileVegetarian},
      };
      final soupResult = await store.queryBuiltInSummaries(
        DailyChoiceEatLibraryQuery(
          mealId: 'lunch',
          toolId: 'pot',
          selectedTraitFilters: traitFilters,
          customExcludedIngredients: const <String>['香菜'],
          limit: 5,
        ),
      );
      expect(soupResult.totalCount, 1);
      expect(soupResult.options.map((item) => item.id), <String>[
        'mushroom_soup',
      ]);
      expect(soupResult.randomCandidateIds, <String>['mushroom_soup']);
      expect(soupResult.options.single.detailsZh, isEmpty);

      final firstPage = await store.queryBuiltInSummaries(
        const DailyChoiceEatLibraryQuery(
          mealId: 'all',
          toolId: 'pot',
          limit: 3,
        ),
      );
      expect(firstPage.totalCount, 7);
      expect(firstPage.options, hasLength(3));
      expect(firstPage.hasMore, isTrue);
      expect(firstPage.options.every((item) => item.detailsZh.isEmpty), isTrue);

      final searchResult = await store.queryBuiltInSummaries(
        const DailyChoiceEatLibraryQuery(
          mealId: 'all',
          toolId: 'pot',
          searchText: '香菇',
          limit: 20,
        ),
      );
      expect(searchResult.totalCount, 1);
      expect(searchResult.options.map((item) => item.id), <String>[
        'mushroom_soup',
      ]);
      expect(searchResult.randomCandidateIds, <String>['mushroom_soup']);

      final pivotQuery = const DailyChoiceEatLibraryQuery(
        mealId: 'all',
        toolId: 'pot',
        limit: 3,
      );
      final pivotPick = await store.pickBuiltInRandomSummary(
        pivotQuery,
        pivotKey: 5,
      );
      expect(firstPage.options.map((item) => item.id), isNot(contains('ribs')));
      expect(pivotPick?.id, 'ribs');
      expect(pivotPick?.detailsZh, isEmpty);

      final wrappedPick = await store.pickBuiltInRandomSummary(
        pivotQuery,
        pivotKey: 99,
      );
      expect(wrappedPick?.id, 'cilantro_soup');

      final ribsResult = await store.queryBuiltInSummaries(
        const DailyChoiceEatLibraryQuery(
          mealId: 'all',
          toolId: 'pot',
          availableIngredients: <String>['排骨'],
          preferAvailableIngredients: true,
          limit: 20,
        ),
      );
      expect(ribsResult.randomCandidateIds, <String>['ribs']);
      expect(ribsResult.randomCandidateIds, isNot(contains('pork')));
      final ribsPick = await store.pickBuiltInRandomSummary(
        const DailyChoiceEatLibraryQuery(
          mealId: 'all',
          toolId: 'pot',
          availableIngredients: <String>['排骨'],
          preferAvailableIngredients: true,
          limit: 1,
        ),
        pivotKey: 1,
      );
      expect(ribsPick?.id, 'ribs');

      final noPeanutOrNut = await store.queryBuiltInSummaries(
        const DailyChoiceEatLibraryQuery(
          mealId: 'all',
          toolId: 'pot',
          excludedContains: <String>{eatContainsPeanutNut},
          limit: 20,
        ),
      );
      final noPeanutOrNutIds = noPeanutOrNut.options
          .map((item) => item.id)
          .toList(growable: false);
      expect(noPeanutOrNut.totalCount, 5);
      expect(noPeanutOrNutIds, containsAll(<String>['ribs', 'pork']));
      expect(noPeanutOrNutIds, isNot(contains('peanut')));
      expect(noPeanutOrNutIds, isNot(contains('walnut')));
    },
  );

  test(
    'DailyChoiceEatLibraryStore installs remote SQLite summaries and lazy loads details',
    () async {
      final options = <DailyChoiceOption>[
        eatOption(
          id: 'tomato_egg',
          title: '番茄鸡蛋',
          materials: const <String>['番茄', '鸡蛋'],
        ),
        eatOption(
          id: 'tofu_soup',
          title: '豆腐汤',
          materials: const <String>['豆腐', '香菇'],
          tags: const <String>['汤'],
        ),
      ];
      final updatedAt = DateTime(2026, 4, 25, 15, 30);
      final document = DailyChoiceRecipeLibraryDocument(
        libraryId: DailyChoiceRecipeLibraryDocument.defaultLibraryId,
        libraryVersion: '2026-04-25',
        schemaId: DailyChoiceRecipeLibraryDocument.defaultSchemaId,
        schemaVersion: DailyChoiceRecipeLibraryDocument.defaultSchemaVersion,
        generatedAt: updatedAt,
        referenceTitles: const <String>['测试参考资料'],
        stats: <String, Object?>{'recipeCount': options.length},
        recipes: options,
      );
      final tempDirectory = await Directory.systemTemp.createTemp(
        'daily_choice_eat_library_store_test_',
      );
      final legacyCacheFile = File(
        p.join(tempDirectory.path, 'toolbox_daily_choice_recipe_library.json'),
      );
      final legacyCookCacheFile = File(
        p.join(tempDirectory.path, 'toolbox_daily_choice_cook_recipe.csv'),
      );
      await legacyCacheFile.writeAsString('legacy');
      await legacyCookCacheFile.writeAsString('legacy');

      final store = DailyChoiceEatLibraryStore(
        supportDirectoryProvider: () async => tempDirectory,
        remoteDatabaseInstaller: (targetFile) async {
          await _writeLibraryDatabase(
            targetFile,
            document,
            updatedAt: updatedAt,
          );
          return updatedAt;
        },
      );
      addTearDown(() async {
        await store.close();
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final initialStatus = await store.inspectStatus();
      expect(initialStatus.hasInstalledLibrary, isFalse);
      expect(initialStatus.recipeCount, 0);

      final installedStatus = await store.installLibrary();
      expect(installedStatus.hasInstalledLibrary, isTrue);
      expect(installedStatus.recipeCount, options.length);
      expect(installedStatus.referenceTitles, contains('测试参考资料'));
      expect(installedStatus.source, DailyChoiceCookDataSource.remote);
      expect(installedStatus.updatedAt, updatedAt);
      expect(installedStatus.errorMessage, isNull);

      final summaries = await store.loadBuiltInSummaries();
      expect(summaries, hasLength(options.length));
      expect(summaries.first.detailsZh, isEmpty);
      expect(summaries.first.materialsZh, isEmpty);
      expect(summaries.first.stepsZh, isEmpty);
      expect(
        summaries.first.attributeValues(eatAttributeIngredient),
        isNotEmpty,
      );

      final detail = await store.loadBuiltInDetail('tomato_egg');
      expect(detail, isNotNull);
      expect(detail!.detailsZh, contains('番茄鸡蛋'));
      expect(detail.materialsZh, containsAll(<String>['番茄', '鸡蛋']));
      expect(detail.stepsZh, isNotEmpty);

      expect(await legacyCacheFile.exists(), isFalse);
      expect(await legacyCookCacheFile.exists(), isFalse);
    },
  );

  test(
    'DailyChoiceEatLibraryStore keeps installed SQLite when remote refresh fails',
    () async {
      final updatedAt = DateTime(2026, 4, 25, 15, 30);
      final document = DailyChoiceRecipeLibraryDocument(
        libraryId: DailyChoiceRecipeLibraryDocument.defaultLibraryId,
        libraryVersion: '2026-04-25',
        schemaId: DailyChoiceRecipeLibraryDocument.defaultSchemaId,
        schemaVersion: DailyChoiceRecipeLibraryDocument.defaultSchemaVersion,
        generatedAt: updatedAt,
        stats: const <String, Object?>{'recipeCount': 1},
        recipes: <DailyChoiceOption>[
          eatOption(
            id: 'stable_recipe',
            title: 'Stable Recipe',
            materials: const <String>['tofu'],
          ),
        ],
      );
      final tempDirectory = await Directory.systemTemp.createTemp(
        'daily_choice_eat_library_store_test_',
      );
      final databaseFile = File(
        p.join(tempDirectory.path, 'toolbox_daily_choice_recipes.db'),
      );
      final candidateFile = File('${databaseFile.path}.remote');
      final legacyCacheFile = File(
        p.join(tempDirectory.path, 'toolbox_daily_choice_recipe_library.json'),
      );
      final legacyCookCacheFile = File(
        p.join(tempDirectory.path, 'toolbox_daily_choice_cook_recipe.csv'),
      );

      final installStore = DailyChoiceEatLibraryStore(
        supportDirectoryProvider: () async => tempDirectory,
        remoteDatabaseInstaller: (targetFile) async {
          await _writeLibraryDatabase(
            targetFile,
            document,
            updatedAt: updatedAt,
          );
          return updatedAt;
        },
      );
      final failingStore = DailyChoiceEatLibraryStore(
        supportDirectoryProvider: () async => tempDirectory,
        remoteDatabaseInstaller: (targetFile) async {
          await targetFile.writeAsString('partial remote db');
          throw StateError('s3 unavailable');
        },
      );
      addTearDown(() async {
        await installStore.close();
        await failingStore.close();
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final installedStatus = await installStore.installLibrary();
      expect(installedStatus.hasInstalledLibrary, isTrue);
      await installStore.close();
      await legacyCacheFile.writeAsString('legacy');
      await legacyCookCacheFile.writeAsString('legacy');

      final failedStatus = await failingStore.installLibrary();
      expect(failedStatus.hasInstalledLibrary, isTrue);
      expect(failedStatus.recipeCount, 1);
      expect(failedStatus.errorMessage, contains('s3 unavailable'));
      expect(await databaseFile.exists(), isTrue);
      expect(await candidateFile.exists(), isFalse);
      expect(await legacyCacheFile.exists(), isFalse);
      expect(await legacyCookCacheFile.exists(), isFalse);

      final summaries = await failingStore.loadBuiltInSummaries();
      expect(summaries, hasLength(1));
      expect(summaries.single.id, 'stable_recipe');
    },
  );

  test(
    'DailyChoiceEatLibraryStore does not install bundled JSON fallback on first remote failure',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'daily_choice_eat_library_store_test_',
      );
      final databaseFile = File(
        p.join(tempDirectory.path, 'toolbox_daily_choice_recipes.db'),
      );
      final candidateFile = File('${databaseFile.path}.remote');
      final legacyCacheFile = File(
        p.join(tempDirectory.path, 'toolbox_daily_choice_recipe_library.json'),
      );
      final legacyCookCacheFile = File(
        p.join(tempDirectory.path, 'toolbox_daily_choice_cook_recipe.csv'),
      );
      await legacyCacheFile.writeAsString('legacy');
      await legacyCookCacheFile.writeAsString('legacy');

      final store = DailyChoiceEatLibraryStore(
        supportDirectoryProvider: () async => tempDirectory,
        remoteDatabaseInstaller: (targetFile) async {
          await targetFile.writeAsString('partial remote db');
          throw StateError('s3 unavailable');
        },
      );
      addTearDown(() async {
        await store.close();
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final status = await store.installLibrary();
      expect(status.hasInstalledLibrary, isFalse);
      expect(status.recipeCount, 0);
      expect(status.errorMessage, contains('s3 unavailable'));
      expect(await databaseFile.exists(), isFalse);
      expect(await candidateFile.exists(), isFalse);
      expect(await legacyCacheFile.exists(), isFalse);
      expect(await legacyCookCacheFile.exists(), isFalse);
    },
  );
}

Future<void> _writeV2LibraryDatabase(
  File file,
  DailyChoiceRecipeLibraryDocument document, {
  required DateTime updatedAt,
}) async {
  await file.parent.create(recursive: true);
  final db = sqlite3.open(file.path);
  try {
    db.execute('PRAGMA foreign_keys = ON;');
    db.execute('PRAGMA user_version = 2;');
    db.execute('''
      CREATE TABLE daily_choice_recipe_schema_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    db.execute('''
      CREATE TABLE daily_choice_recipe_sets (
        set_id TEXT PRIMARY KEY,
        recipe_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
    db.execute('''
      CREATE TABLE daily_choice_recipes (
        recipe_id TEXT PRIMARY KEY,
        primary_set_id TEXT NOT NULL,
        title_zh TEXT NOT NULL,
        title_en TEXT NOT NULL,
        primary_meal_id TEXT NOT NULL,
        primary_tool_id TEXT,
        sort_key TEXT NOT NULL,
        random_key INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'active',
        is_available INTEGER NOT NULL DEFAULT 1
      )
    ''');
    db.execute('''
      CREATE TABLE daily_choice_recipe_summaries (
        recipe_id TEXT PRIMARY KEY,
        subtitle_zh TEXT NOT NULL DEFAULT '',
        subtitle_en TEXT NOT NULL DEFAULT '',
        tags_zh_json TEXT NOT NULL DEFAULT '[]',
        tags_en_json TEXT NOT NULL DEFAULT '[]',
        summary_attributes_json TEXT NOT NULL DEFAULT '{}'
      )
    ''');
    db.execute('''
      CREATE TABLE daily_choice_recipe_details (
        recipe_id TEXT PRIMARY KEY,
        details_zh TEXT NOT NULL DEFAULT '',
        details_en TEXT NOT NULL DEFAULT '',
        materials_zh_json TEXT NOT NULL DEFAULT '[]',
        materials_en_json TEXT NOT NULL DEFAULT '[]',
        steps_zh_json TEXT NOT NULL DEFAULT '[]',
        steps_en_json TEXT NOT NULL DEFAULT '[]',
        notes_zh_json TEXT NOT NULL DEFAULT '[]',
        notes_en_json TEXT NOT NULL DEFAULT '[]',
        raw_payload_json TEXT NOT NULL DEFAULT '{}'
      )
    ''');
    db.execute('''
      CREATE TABLE daily_choice_recipe_filter_index (
        recipe_id TEXT NOT NULL,
        set_id TEXT NOT NULL,
        term_group TEXT NOT NULL,
        term_value TEXT NOT NULL,
        confidence INTEGER NOT NULL DEFAULT 100,
        source_kind TEXT NOT NULL DEFAULT 'generated',
        PRIMARY KEY (recipe_id, term_group, term_value, set_id)
      )
    ''');
    db.execute('''
      CREATE TABLE daily_choice_recipe_ingredient_index (
        recipe_id TEXT NOT NULL,
        set_id TEXT NOT NULL,
        token_kind TEXT NOT NULL,
        token_value TEXT NOT NULL,
        display_text TEXT NOT NULL DEFAULT '',
        source_text TEXT NOT NULL DEFAULT '',
        match_level INTEGER NOT NULL DEFAULT 80,
        is_primary INTEGER NOT NULL DEFAULT 0,
        source_kind TEXT NOT NULL DEFAULT 'generated',
        PRIMARY KEY (recipe_id, token_kind, token_value, set_id)
      )
    ''');
    db.execute('''
      CREATE TABLE daily_choice_recipe_search_text (
        recipe_id TEXT PRIMARY KEY,
        search_title TEXT NOT NULL,
        search_materials TEXT NOT NULL DEFAULT '',
        search_tags TEXT NOT NULL DEFAULT '',
        search_all TEXT NOT NULL
      )
    ''');

    final setCounts = <String, int>{'book_library': 0, 'cook_csv': 0};
    for (final option in document.recipes) {
      final setId = option.id.startsWith('cook_csv_')
          ? 'cook_csv'
          : 'book_library';
      setCounts[setId] = (setCounts[setId] ?? 0) + 1;
    }
    for (final entry in setCounts.entries) {
      db.execute(
        '''
        INSERT INTO daily_choice_recipe_sets (set_id, recipe_count)
        VALUES (?, ?)
        ''',
        <Object?>[entry.key, entry.value],
      );
    }

    final metaInsert = db.prepare('''
      INSERT INTO daily_choice_recipe_schema_meta (key, value)
      VALUES (?, ?)
    ''');
    try {
      final metaEntries = <String, String>{
        'schema_id': document.schemaId,
        'schema_version': '${document.schemaVersion}',
        'library_id': document.libraryId,
        'library_version': document.libraryVersion,
        'generated_at': updatedAt.toIso8601String(),
      };
      for (final entry in metaEntries.entries) {
        metaInsert.execute(<Object?>[entry.key, entry.value]);
      }
    } finally {
      metaInsert.dispose();
    }

    final recipeInsert = db.prepare('''
      INSERT INTO daily_choice_recipes (
        recipe_id,
        primary_set_id,
        title_zh,
        title_en,
        primary_meal_id,
        primary_tool_id,
        sort_key,
        random_key,
        status,
        is_available
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'active', 1)
    ''');
    final summaryInsert = db.prepare('''
      INSERT INTO daily_choice_recipe_summaries (
        recipe_id,
        subtitle_zh,
        subtitle_en,
        tags_zh_json,
        tags_en_json,
        summary_attributes_json
      ) VALUES (?, ?, ?, ?, ?, ?)
    ''');
    final detailInsert = db.prepare('''
      INSERT INTO daily_choice_recipe_details (
        recipe_id,
        details_zh,
        details_en,
        materials_zh_json,
        materials_en_json,
        steps_zh_json,
        steps_en_json,
        notes_zh_json,
        notes_en_json,
        raw_payload_json
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');
    final filterIndexInsert = db.prepare('''
      INSERT OR IGNORE INTO daily_choice_recipe_filter_index (
        recipe_id,
        set_id,
        term_group,
        term_value,
        confidence,
        source_kind
      ) VALUES (?, ?, ?, ?, 100, 'generated')
    ''');
    final ingredientIndexInsert = db.prepare('''
      INSERT OR IGNORE INTO daily_choice_recipe_ingredient_index (
        recipe_id,
        set_id,
        token_kind,
        token_value,
        display_text,
        source_text,
        match_level,
        is_primary,
        source_kind
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'generated')
    ''');
    final searchTextInsert = db.prepare('''
      INSERT INTO daily_choice_recipe_search_text (
        recipe_id,
        search_title,
        search_materials,
        search_tags,
        search_all
      ) VALUES (?, ?, ?, ?, ?)
    ''');

    try {
      var randomKey = 0;
      for (final rawOption in document.recipes) {
        final option = ensureEatOptionAttributes(rawOption);
        final setId = option.id.startsWith('cook_csv_')
            ? 'cook_csv'
            : 'book_library';
        randomKey += 1;
        recipeInsert.execute(<Object?>[
          option.id,
          setId,
          option.titleZh,
          option.titleEn,
          option.categoryId,
          option.contextId,
          '${option.categoryId}|${option.contextId ?? ''}|${option.titleZh}',
          randomKey,
        ]);
        summaryInsert.execute(<Object?>[
          option.id,
          option.subtitleZh,
          option.subtitleEn,
          jsonEncode(option.tagsZh),
          jsonEncode(option.tagsEn),
          jsonEncode(option.attributes),
        ]);
        detailInsert.execute(<Object?>[
          option.id,
          option.detailsZh,
          option.detailsEn,
          jsonEncode(option.materialsZh),
          jsonEncode(option.materialsEn),
          jsonEncode(option.stepsZh),
          jsonEncode(option.stepsEn),
          jsonEncode(option.notesZh),
          jsonEncode(option.notesEn),
          jsonEncode(option.toJson()),
        ]);
        final searchTitle = _searchText(option);
        final searchMaterials = option.materialsZh.join(' ').toLowerCase();
        final searchTags = option.tagsZh.join(' ').toLowerCase();
        searchTextInsert.execute(<Object?>[
          option.id,
          searchTitle,
          searchMaterials,
          searchTags,
          <String>[
            searchTitle,
            searchMaterials,
            searchTags,
            option.stepsZh.join(' ').toLowerCase(),
            option.notesZh.join(' ').toLowerCase(),
          ].join(' ').trim(),
        ]);
        for (final term in _v2FilterTerms(option)) {
          filterIndexInsert.execute(<Object?>[
            option.id,
            setId,
            term.key,
            term.value,
          ]);
        }
        for (final rawToken in _v2RawIngredientTokens(option.materialsZh)) {
          ingredientIndexInsert.execute(<Object?>[
            option.id,
            setId,
            'raw',
            rawToken,
            rawToken,
            rawToken,
            100,
            0,
          ]);
        }
        final canonicalTokens = option.attributeValues(eatAttributeIngredient);
        for (var index = 0; index < canonicalTokens.length; index += 1) {
          final token = canonicalTokens[index];
          ingredientIndexInsert.execute(<Object?>[
            option.id,
            setId,
            'canonical',
            token,
            token,
            '',
            90,
            index == 0 ? 1 : 0,
          ]);
          final family = _v2IngredientFamilyToken(token);
          if (family != null) {
            ingredientIndexInsert.execute(<Object?>[
              option.id,
              setId,
              'family',
              family,
              family,
              token,
              45,
              0,
            ]);
          }
        }
      }
    } finally {
      recipeInsert.dispose();
      summaryInsert.dispose();
      detailInsert.dispose();
      filterIndexInsert.dispose();
      ingredientIndexInsert.dispose();
      searchTextInsert.dispose();
    }
  } finally {
    db.dispose();
  }
}

List<MapEntry<String, String>> _v2FilterTerms(DailyChoiceOption option) {
  final terms = <MapEntry<String, String>>[];
  final seen = <String>{};

  void addTerm(String group, String? value) {
    final normalizedGroup = group.trim();
    final normalizedValue = (value ?? '').trim();
    if (normalizedGroup.isEmpty || normalizedValue.isEmpty) {
      return;
    }
    final key = '$normalizedGroup\t$normalizedValue';
    if (seen.add(key)) {
      terms.add(MapEntry<String, String>(normalizedGroup, normalizedValue));
    }
  }

  addTerm(eatAttributeMeal, option.categoryId);
  addTerm(eatAttributeTool, option.contextId);
  for (final toolId in option.contextIds) {
    addTerm(eatAttributeTool, toolId);
  }
  for (final entry in option.attributes.entries) {
    for (final value in entry.value) {
      addTerm(entry.key, value);
    }
  }
  return List<MapEntry<String, String>>.unmodifiable(terms);
}

List<String> _v2RawIngredientTokens(Iterable<String> materials) {
  final seen = <String>{};
  final result = <String>[];
  for (final material in materials) {
    final normalized = material.trim();
    if (normalized.length > 1 && seen.add(normalized)) {
      result.add(normalized);
    }
  }
  return List<String>.unmodifiable(result);
}

String? _v2IngredientFamilyToken(String token) {
  if (<String>{'排骨', '猪肉', 'pork'}.contains(token)) {
    return 'pork';
  }
  if (<String>{'花生', 'peanut', '坚果', 'nut'}.contains(token)) {
    return 'nut';
  }
  return null;
}

Future<void> _writeLibraryDatabase(
  File file,
  DailyChoiceRecipeLibraryDocument document, {
  required DateTime updatedAt,
}) async {
  await file.parent.create(recursive: true);
  final db = sqlite3.open(file.path);
  try {
    db.execute('PRAGMA foreign_keys = ON;');
    db.execute('DROP TABLE IF EXISTS daily_choice_eat_recipe_index_terms;');
    db.execute('DROP TABLE IF EXISTS daily_choice_eat_recipe_details;');
    db.execute('DROP TABLE IF EXISTS daily_choice_eat_recipe_summaries;');
    db.execute('DROP TABLE IF EXISTS daily_choice_eat_recipe_meta;');
    db.execute('PRAGMA user_version = 1;');
    db.execute('''
      CREATE TABLE IF NOT EXISTS daily_choice_eat_recipe_summaries (
        id TEXT PRIMARY KEY,
        module_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        context_id TEXT,
        context_ids_json TEXT NOT NULL,
        title_zh TEXT NOT NULL,
        title_en TEXT NOT NULL,
        subtitle_zh TEXT NOT NULL,
        subtitle_en TEXT NOT NULL,
        tags_zh_json TEXT NOT NULL,
        tags_en_json TEXT NOT NULL,
        attributes_json TEXT NOT NULL,
        source_label TEXT,
        source_url TEXT,
        search_title TEXT NOT NULL,
        sort_key TEXT NOT NULL
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS daily_choice_eat_recipe_details (
        recipe_id TEXT PRIMARY KEY,
        details_zh TEXT NOT NULL,
        details_en TEXT NOT NULL,
        materials_zh_json TEXT NOT NULL,
        materials_en_json TEXT NOT NULL,
        steps_zh_json TEXT NOT NULL,
        steps_en_json TEXT NOT NULL,
        notes_zh_json TEXT NOT NULL,
        notes_en_json TEXT NOT NULL,
        references_json TEXT NOT NULL,
        FOREIGN KEY (recipe_id) REFERENCES daily_choice_eat_recipe_summaries(id) ON DELETE CASCADE
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS daily_choice_eat_recipe_index_terms (
        recipe_id TEXT NOT NULL,
        term_group TEXT NOT NULL,
        term_value TEXT NOT NULL,
        PRIMARY KEY (recipe_id, term_group, term_value),
        FOREIGN KEY (recipe_id) REFERENCES daily_choice_eat_recipe_summaries(id) ON DELETE CASCADE
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS daily_choice_eat_recipe_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    final summaryInsert = db.prepare('''
      INSERT INTO daily_choice_eat_recipe_summaries (
        id,
        module_id,
        category_id,
        context_id,
        context_ids_json,
        title_zh,
        title_en,
        subtitle_zh,
        subtitle_en,
        tags_zh_json,
        tags_en_json,
        attributes_json,
        source_label,
        source_url,
        search_title,
        sort_key
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');
    final detailInsert = db.prepare('''
      INSERT INTO daily_choice_eat_recipe_details (
        recipe_id,
        details_zh,
        details_en,
        materials_zh_json,
        materials_en_json,
        steps_zh_json,
        steps_en_json,
        notes_zh_json,
        notes_en_json,
        references_json
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');
    final indexInsert = db.prepare('''
      INSERT OR IGNORE INTO daily_choice_eat_recipe_index_terms (
        recipe_id,
        term_group,
        term_value
      ) VALUES (?, ?, ?)
    ''');

    try {
      for (final rawOption in document.recipes) {
        final option = ensureEatOptionAttributes(rawOption);
        summaryInsert.execute(<Object?>[
          option.id,
          option.moduleId,
          option.categoryId,
          option.contextId,
          jsonEncode(option.contextIds),
          option.titleZh,
          option.titleEn,
          option.subtitleZh,
          option.subtitleEn,
          jsonEncode(option.tagsZh),
          jsonEncode(option.tagsEn),
          jsonEncode(option.attributes),
          option.sourceLabel,
          option.sourceUrl,
          _searchText(option),
          '${option.categoryId}|${option.contextId ?? ''}|${option.titleZh}',
        ]);
        detailInsert.execute(<Object?>[
          option.id,
          option.detailsZh,
          option.detailsEn,
          jsonEncode(option.materialsZh),
          jsonEncode(option.materialsEn),
          jsonEncode(option.stepsZh),
          jsonEncode(option.stepsEn),
          jsonEncode(option.notesZh),
          jsonEncode(option.notesEn),
          jsonEncode(
            option.references
                .map((item) => item.toJson())
                .toList(growable: false),
          ),
        ]);
        for (final term in _indexTerms(option)) {
          indexInsert.execute(<Object?>[option.id, term.$1, term.$2]);
        }
      }
    } finally {
      summaryInsert.dispose();
      detailInsert.dispose();
      indexInsert.dispose();
    }

    final metaInsert = db.prepare('''
      INSERT INTO daily_choice_eat_recipe_meta (key, value)
      VALUES (?, ?)
    ''');
    try {
      final metaEntries = <String, String>{
        'library_id': document.libraryId,
        'library_version': document.libraryVersion,
        'schema_id': document.schemaId,
        'schema_version': '${document.schemaVersion}',
        'reference_titles_json': jsonEncode(document.referenceTitles),
        'local_library_count': '${document.recipes.length}',
        'cook_recipe_count': '0',
        'install_source': DailyChoiceCookDataSource.remote.name,
        'installed_at': updatedAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'error_message': '',
      };
      for (final entry in metaEntries.entries) {
        metaInsert.execute(<Object?>[entry.key, entry.value]);
      }
    } finally {
      metaInsert.dispose();
    }
  } finally {
    db.dispose();
  }
}

Iterable<(String, String)> _indexTerms(DailyChoiceOption option) sync* {
  yield ('meal', option.categoryId);
  if (option.contextId != null && option.contextId!.trim().isNotEmpty) {
    yield ('tool', option.contextId!.trim());
  }
  for (final contextId in option.contextIds) {
    final normalized = contextId.trim();
    if (normalized.isNotEmpty) {
      yield ('tool', normalized);
    }
  }
  for (final entry in option.attributes.entries) {
    for (final value in entry.value) {
      final normalized = value.trim();
      if (normalized.isNotEmpty) {
        yield (entry.key, normalized);
      }
    }
  }
}

String _searchText(DailyChoiceOption option) {
  return <String>[
    option.id,
    option.titleZh,
    option.titleEn,
    option.subtitleZh,
    option.subtitleEn,
    ...option.tagsZh,
    ...option.tagsEn,
  ].join(' ').trim().toLowerCase();
}

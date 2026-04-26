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

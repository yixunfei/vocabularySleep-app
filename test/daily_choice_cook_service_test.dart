import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_cook_service.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_eat_support.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_recipe_library.dart';

void main() {
  DailyChoiceOption eatOption({
    required String id,
    required String title,
    String categoryId = 'lunch',
    String? contextId,
    List<String> contextIds = const <String>[],
    List<String> materials = const <String>[],
    List<String> steps = const <String>['步骤 1'],
    List<String> notes = const <String>[],
    List<String> tags = const <String>[],
    List<DailyChoiceReferenceLink> references =
        const <DailyChoiceReferenceLink>[],
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
        detailsZh: '$title 详细说明',
        detailsEn: '$title details',
        materialsZh: materials,
        materialsEn: materials,
        stepsZh: steps,
        stepsEn: steps,
        notesZh: notes,
        notesEn: notes,
        tagsZh: tags,
        tagsEn: tags,
        references: references,
      ),
    );
  }

  test(
    'parse cook csv into eat options with overlapping meal and tool metadata',
    () {
      const sampleCsv = '''
name,stuff,bv,difficulty,tags,methods,tools,
微波炉版鸡蛋羹,鸡蛋,BV1TEST001,简单,早餐,微波加热,微波炉,
电饭煲版广式腊肠煲饭,腊肠、米,BV1TEST002,简单,广式,煲,电饭煲,
空气炸锅酸奶蛋糕,鸡蛋,BV1TEST003,简单,甜点,烤,空气炸锅,
电饭煲版广式腊肠煲饭,腊肠、米,BV1TEST002,简单,广式,煲,电饭煲,
''';

      final options = parseDailyChoiceCookOptions(sampleCsv);

      expect(options, hasLength(3));

      final breakfast = options.firstWhere((item) => item.titleZh == '微波炉版鸡蛋羹');
      expect(breakfast.categoryId, 'breakfast');
      expect(eatMatchesMeal(breakfast, 'breakfast'), isTrue);
      expect(eatMatchesTool(breakfast, 'microwave'), isTrue);
      expect(breakfast.contextIds, contains('microwave'));
      expect(breakfast.stepsZh, isNotEmpty);
      expect(breakfast.references, isNotEmpty);

      final lunch = options.firstWhere((item) => item.titleZh == '电饭煲版广式腊肠煲饭');
      expect(lunch.categoryId, 'lunch');
      expect(eatMatchesMeal(lunch, 'lunch'), isTrue);
      expect(eatMatchesMeal(lunch, 'dinner'), isTrue);
      expect(eatMatchesTool(lunch, 'rice_cooker'), isTrue);
      expect(
        lunch.attributeValues(eatAttributeMeal),
        containsAll(<String>['lunch', 'dinner']),
      );
      expect(lunch.tagsZh, contains('电饭煲'));

      final tea = options.firstWhere((item) => item.titleZh == '空气炸锅酸奶蛋糕');
      expect(tea.categoryId, 'tea');
      expect(eatMatchesMeal(tea, 'tea'), isTrue);
      expect(eatMatchesMeal(tea, 'lunch'), isFalse);
      expect(tea.contextIds, contains('air_fryer'));
      expect(tea.notesZh, isNotEmpty);
    },
  );

  test(
    'chooseBestMatchedEatOptions narrows candidates to strongest ingredient matches',
    () {
      final tomatoEgg = eatOption(
        id: 'tomato_egg',
        title: '番茄炒蛋',
        materials: const <String>['番茄', '鸡蛋'],
        tags: const <String>['家常'],
      );
      final potatoBeef = eatOption(
        id: 'potato_beef',
        title: '土豆炖牛肉',
        materials: const <String>['土豆', '牛肉', '洋葱'],
        tags: const <String>['炖'],
      );
      final cucumber = eatOption(
        id: 'cucumber',
        title: '拍黄瓜',
        categoryId: 'tea',
        materials: const <String>['黄瓜', '蒜'],
        tags: const <String>['凉拌'],
      );

      final best = chooseBestMatchedEatOptions(
        <DailyChoiceOption>[tomatoEgg, potatoBeef, cucumber],
        const <String>['牛肉', '土豆'],
      );

      expect(best.map((item) => item.id), <String>['potato_beef']);
      expect(
        eatIngredientMatchCount(potatoBeef, const <String>['牛肉', '土豆']),
        2,
      );
      expect(
        eatIngredientMatchRatio(potatoBeef, const <String>['牛肉', '土豆']),
        greaterThan(0.3),
      );
    },
  );

  test(
    'mergeEatOptionCollections dedupes recipe titles and preserves merged metadata',
    () {
      final sourceA = eatOption(
        id: 'soup_a',
        title: '番茄牛肉汤',
        categoryId: 'lunch',
        contextId: 'pot',
        contextIds: const <String>['pot'],
        materials: const <String>['番茄', '牛肉'],
        steps: const <String>['切配', '炖煮'],
        references: const <DailyChoiceReferenceLink>[
          DailyChoiceReferenceLink(
            labelZh: '来源 A',
            labelEn: 'Source A',
            url: 'https://example.com/a',
          ),
        ],
      );
      final sourceB = eatOption(
        id: 'soup_b',
        title: '番茄牛肉汤',
        categoryId: 'dinner',
        contextId: 'rice_cooker',
        contextIds: const <String>['rice_cooker'],
        materials: const <String>['番茄', '牛肉', '洋葱'],
        steps: const <String>['切配', '煸香', '炖煮'],
        notes: const <String>['出锅前再补盐'],
        references: const <DailyChoiceReferenceLink>[
          DailyChoiceReferenceLink(
            labelZh: '来源 B',
            labelEn: 'Source B',
            url: 'https://example.com/b',
          ),
        ],
      );

      final merged = mergeEatOptionCollections(<DailyChoiceOption>[
        sourceA,
        sourceB,
      ]);

      expect(merged, hasLength(1));
      final option = merged.single;
      expect(option.titleZh, '番茄牛肉汤');
      expect(eatMatchesMeal(option, 'lunch'), isTrue);
      expect(eatMatchesMeal(option, 'dinner'), isTrue);
      expect(eatMatchesTool(option, 'pot'), isTrue);
      expect(eatMatchesTool(option, 'rice_cooker'), isTrue);
      expect(option.stepsZh, hasLength(3));
      expect(option.notesZh, contains('出锅前再补盐'));
      expect(
        option.references.map((item) => item.url),
        containsAll(<String>['https://example.com/a', 'https://example.com/b']),
      );
    },
  );

  test(
    'loadBundled caches parsed recipe library within the service instance',
    () async {
      final libraryDocument = DailyChoiceRecipeLibraryDocument(
        libraryId: DailyChoiceRecipeLibraryDocument.defaultLibraryId,
        libraryVersion: '2026-04-25',
        schemaId: DailyChoiceRecipeLibraryDocument.defaultSchemaId,
        schemaVersion: DailyChoiceRecipeLibraryDocument.defaultSchemaVersion,
        recipes: <DailyChoiceOption>[
          eatOption(
            id: 'cached_recipe',
            title: '番茄鸡蛋',
            materials: const <String>['番茄', '鸡蛋'],
          ),
        ],
        referenceTitles: const <String>['测试资料'],
      );
      final bundle = _CountingAssetBundle(jsonEncode(libraryDocument.toJson()));
      final service = DailyChoiceCookService(bundle: bundle);

      final first = await service.loadBundled();
      final second = await service.loadBundled();

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(first!.options.single.id, 'cached_recipe');
      expect(second!.options.single.id, 'cached_recipe');
      expect(bundle.loadStringCount, 1);
    },
  );
}

class _CountingAssetBundle extends CachingAssetBundle {
  _CountingAssetBundle(this.recipeLibraryJson);

  final String recipeLibraryJson;
  int loadStringCount = 0;

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key != 'assets/toolbox/daily_choice/recipe_library.json') {
      throw StateError('Unexpected asset key: $key');
    }
    loadStringCount += 1;
    return recipeLibraryJson;
  }

  @override
  Future<ByteData> load(String key) {
    throw UnimplementedError('ByteData loading is not needed in this test.');
  }
}

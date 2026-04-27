import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_eat_catalog.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_eat_support.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart';

void main() {
  DailyChoiceOption eatOption({
    required String id,
    required String title,
    String categoryId = 'lunch',
    String? contextId = 'pot',
    List<String> contextIds = const <String>['pot'],
    List<String> materials = const <String>[],
    List<String> steps = const <String>['步骤 1'],
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
        subtitleZh: '$title 简介',
        subtitleEn: '$title subtitle',
        detailsZh: '$title 详情',
        detailsEn: '$title details',
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

  Map<String, Set<String>> emptyTraitFilters() {
    return <String, Set<String>>{
      eatAttributeType: <String>{},
      eatAttributeProfile: <String>{},
    };
  }

  test('catalog filter applies tool, trait, and custom avoid filters', () {
    final cilantroSoup = eatOption(
      id: 'cilantro_soup',
      title: '番茄豆腐汤',
      materials: const <String>['番茄', '豆腐', '香菜'],
      tags: const <String>['家常'],
    );
    final mushroomSoup = eatOption(
      id: 'mushroom_soup',
      title: '香菇白菜汤',
      materials: const <String>['香菇', '白菜'],
      tags: const <String>['清淡'],
    );
    final beefStirFry = eatOption(
      id: 'beef_stir_fry',
      title: '土豆牛肉炒',
      materials: const <String>['土豆', '牛肉'],
      tags: const <String>['快炒'],
    );
    final ovenDessert = eatOption(
      id: 'oven_dessert',
      title: '烤布丁',
      categoryId: 'tea',
      contextId: 'oven',
      contextIds: const <String>['oven'],
      materials: const <String>['牛奶', '鸡蛋'],
      tags: const <String>['甜点'],
    );

    final catalog = DailyChoiceEatCatalog.fromOptions(<DailyChoiceOption>[
      cilantroSoup,
      mushroomSoup,
      beefStirFry,
      ovenDessert,
    ]);

    final traitFilters = emptyTraitFilters();
    traitFilters[eatAttributeType] = <String>{'soup'};
    traitFilters[eatAttributeProfile] = <String>{eatProfileVegetarian};

    final result = catalog.filter(
      mealId: 'lunch',
      toolId: 'pot',
      selectedTraitFilters: traitFilters,
      excludedContains: const <String>{},
      customExcludedIngredients: const <String>['香菜'],
    );

    expect(result.eligibleOptions.map((item) => item.id), <String>[
      'mushroom_soup',
    ]);
    expect(result.randomPool.map((item) => item.id), <String>['mushroom_soup']);
  });

  test(
    'ingredient priority keeps a varied random pool instead of one exact hit',
    () {
      final exact = eatOption(
        id: 'exact',
        title: '番茄鸡蛋豆腐汤',
        materials: const <String>['番茄', '鸡蛋', '豆腐'],
      );
      final strong = eatOption(
        id: 'strong',
        title: '番茄鸡蛋炒面',
        materials: const <String>['番茄', '鸡蛋', '面条'],
        tags: const <String>['快炒'],
      );
      final broad = eatOption(
        id: 'broad',
        title: '豆腐牛肉煲',
        materials: const <String>['豆腐', '牛肉'],
        tags: const <String>['炖煮'],
      );
      final miss = eatOption(
        id: 'miss',
        title: '拍黄瓜',
        materials: const <String>['黄瓜', '蒜'],
        tags: const <String>['凉拌'],
      );

      final catalog = DailyChoiceEatCatalog.fromOptions(<DailyChoiceOption>[
        exact,
        strong,
        broad,
        miss,
      ]);

      final result = catalog.filter(
        mealId: 'lunch',
        toolId: 'pot',
        selectedTraitFilters: emptyTraitFilters(),
        excludedContains: const <String>{},
        availableIngredients: const <String>['番茄', '鸡蛋', '豆腐'],
        preferAvailableIngredients: true,
      );

      expect(result.eligibleOptions, hasLength(4));
      expect(
        result.ingredientPriority.stage,
        DailyChoiceEatIngredientMatchStage.exact,
      );
      expect(result.ingredientPriority.bestIngredientMatchCount, 3);
      expect(result.ingredientPriority.broadenedForVariety, isTrue);
      expect(result.randomPool.map((item) => item.id), <String>[
        'exact',
        'strong',
        'broad',
      ]);
    },
  );

  test(
    'ingredient normalization extracts multiple tokens from compact phrases',
    () {
      expect(
        normalizeEatIngredientInputs(const <String>['番茄鸡蛋豆腐汤']),
        containsAll(<String>['tomato', 'egg', 'tofu']),
      );
      expect(
        normalizeEatIngredientInputs(const <String>['土豆牛肉炒']),
        containsAll(<String>['potato', 'beef']),
      );
      expect(
        normalizeEatIngredientInputs(const <String>['鱼腥草']),
        isNot(contains('seafood')),
      );
      expect(
        normalizeEatIngredientInputs(const <String>['鱼腥草']),
        contains('houttuynia'),
      );
      expect(normalizeEatIngredientInputs(const <String>['排骨']), <String>[
        '排骨',
      ]);
      expect(
        normalizeEatIngredientInputs(const <String>['排骨']),
        isNot(contains('pork')),
      );
    },
  );

  test('meal all and grouped avoids keep filters precise', () {
    final ribs = eatOption(
      id: 'ribs',
      title: '红烧排骨',
      materials: const <String>['排骨'],
    );
    final pork = eatOption(
      id: 'pork',
      title: '猪肉炒豆角',
      materials: const <String>['猪肉', '豆角'],
    );
    final peanut = eatOption(
      id: 'peanut',
      title: '花生拌菠菜',
      materials: const <String>['花生', '菠菜'],
    );
    final walnut = eatOption(
      id: 'walnut',
      title: '核桃拌菜',
      materials: const <String>['核桃', '黄瓜'],
    );
    final catalog = DailyChoiceEatCatalog.fromOptions(<DailyChoiceOption>[
      ribs,
      pork,
      peanut,
      walnut,
    ]);

    final allMeals = catalog.filter(
      mealId: 'all',
      toolId: 'pot',
      selectedTraitFilters: emptyTraitFilters(),
      excludedContains: const <String>{},
    );
    expect(allMeals.eligibleOptions.map((item) => item.id), <String>[
      'ribs',
      'pork',
      'peanut',
      'walnut',
    ]);

    final ribsOnly = catalog.filter(
      mealId: 'all',
      toolId: 'pot',
      selectedTraitFilters: emptyTraitFilters(),
      excludedContains: const <String>{},
      availableIngredients: const <String>['排骨'],
      preferAvailableIngredients: true,
    );
    expect(ribsOnly.randomPool.map((item) => item.id), <String>['ribs']);

    final noPeanutOrNut = catalog.filter(
      mealId: 'all',
      toolId: 'pot',
      selectedTraitFilters: emptyTraitFilters(),
      excludedContains: const <String>{eatContainsPeanutNut},
    );
    expect(noPeanutOrNut.eligibleOptions.map((item) => item.id), <String>[
      'ribs',
      'pork',
    ]);
  });

  test('catalog filter can restrict random pool to a custom recipe set', () {
    final tomatoEgg = eatOption(
      id: 'tomato_egg',
      title: '番茄鸡蛋',
      materials: const <String>['番茄', '鸡蛋'],
    );
    final tofuSoup = eatOption(
      id: 'tofu_soup',
      title: '豆腐汤',
      materials: const <String>['豆腐', '香菇'],
      tags: const <String>['汤'],
    );
    final beefPotato = eatOption(
      id: 'beef_potato',
      title: '土豆牛肉',
      materials: const <String>['土豆', '牛肉'],
    );
    final catalog = DailyChoiceEatCatalog.fromOptions(<DailyChoiceOption>[
      tomatoEgg,
      tofuSoup,
      beefPotato,
    ]);

    final result = catalog.filter(
      mealId: 'lunch',
      toolId: 'pot',
      selectedTraitFilters: emptyTraitFilters(),
      excludedContains: const <String>{},
      allowedOptionIds: const <String>['tofu_soup', 'missing'],
    );

    expect(result.eligibleOptions.map((item) => item.id), <String>[
      'tofu_soup',
    ]);
    expect(result.randomPool.map((item) => item.id), <String>['tofu_soup']);
  });
}

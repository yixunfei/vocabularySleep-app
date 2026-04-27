import 'dart:math' as math;

import 'daily_choice_models.dart';

const String eatAttributeMeal = 'meal';
const String eatAttributeType = 'type';
const String eatAttributeProfile = 'profile';
const String eatAttributeDiet = 'diet';
const String eatAttributeContains = 'contains';
const String eatAttributeIngredient = 'ingredient';
const String eatAttributeTool = 'tool';

const String eatProfileVegetarian = 'vegetarian';
const String eatProfileMeatBased = 'meat_based';
const String eatProfileMixed = 'mixed';
const String eatProfileStaple = 'staple';
const String eatProfileDessert = 'dessert';

const String eatDietHalalFriendly = 'halal_friendly';
const String eatDietVegetarianFriendly = 'vegetarian_friendly';
const String eatDietVeganFriendly = 'vegan_friendly';
const String eatContainsPeanutNut = 'peanut_nut';

const Set<String> _eatRequiredAttributeKeys = <String>{
  eatAttributeMeal,
  eatAttributeType,
  eatAttributeProfile,
  eatAttributeContains,
  eatAttributeIngredient,
};

const Map<String, String> _eatCanonicalLabelZhMap = <String, String>{
  'chicken': '鸡肉',
  'duck': '鸭肉',
  'pork': '猪肉',
  'beef': '牛肉',
  'mutton': '羊肉',
  'seafood': '海鲜',
  'egg': '鸡蛋',
  'milk': '牛奶',
  'dairy': '奶制品',
  'gluten': '麸质面食',
  'soy': '大豆制品',
  'peanut': '花生',
  'nut': '坚果',
  'sesame': '芝麻',
  'spicy': '辣味',
  'alcohol': '酒精',
  'tomato': '番茄',
  'potato': '土豆',
  'onion': '洋葱',
  'garlic': '蒜',
  'ginger': '姜',
  'scallion': '葱',
  'cilantro': '香菜',
  'houttuynia': '鱼腥草',
  'rice': '米饭',
  'tofu': '豆腐',
  'mushroom': '菌菇',
  'cabbage': '白菜',
  'cucumber': '黄瓜',
  'pepper': '椒类',
  'eggplant': '茄子',
  'carrot': '胡萝卜',
  'broccoli': '西蓝花',
  'corn': '玉米',
  'spinach': '菠菜',
};

const Map<String, List<String>> _eatIngredientCanonicalMap =
    <String, List<String>>{
      'chicken': <String>['鸡肉', '鸡丁', '鸡丝', '鸡腿', '鸡翅', '鸡胸', '鸡块', '乌鸡'],
      'duck': <String>['鸭肉', '鸭腿', '鸭胸', '烤鸭'],
      'pork': <String>['猪肉', '五花肉', '肉末', '肉馅'],
      'beef': <String>['牛肉', '牛腩', '牛柳', '肥牛', '牛排'],
      'mutton': <String>['羊肉', '羊排'],
      'seafood': <String>[
        '鱼',
        '虾',
        '蟹',
        '鱿鱼',
        '鲜贝',
        '干贝',
        '海参',
        '海米',
        '章鱼',
        '金枪鱼',
      ],
      'egg': <String>['鸡蛋', '蛋', '皮蛋', '松花蛋'],
      'milk': <String>['牛奶', '鲜奶', '纯牛奶'],
      'dairy': <String>['奶油', '奶酪', '乳酪', '黄油', '酸奶', '淡奶油', '奶粉'],
      'gluten': <String>['面粉', '面包', '吐司', '面条', '意面', '挂面', '馄饨皮', '饺子皮'],
      'soy': <String>['豆腐', '豆腐干', '豆腐皮', '腐竹', '黄豆', '酱油', '豆瓣'],
      'peanut': <String>['花生', '花生仁', '花生酱'],
      'nut': <String>['松仁', '核桃', '腰果', '杏仁', '板栗', '栗子', '开心果', '榛子'],
      'sesame': <String>['芝麻', '麻酱', '香油'],
      'spicy': <String>['辣椒', '泡椒', '辣油', '辣酱', '花椒'],
      'alcohol': <String>['料酒', '黄酒', '啤酒', '白酒', '米酒', '绍酒', '葡萄酒', '红酒'],
      'tomato': <String>['番茄', '西红柿'],
      'potato': <String>['土豆', '马铃薯'],
      'onion': <String>['洋葱'],
      'garlic': <String>['蒜', '大蒜', '蒜瓣', '蒜末', '蒜片'],
      'ginger': <String>['姜', '姜片', '姜末', '泡姜'],
      'scallion': <String>['葱', '葱花', '香葱', '青葱'],
      'cilantro': <String>['香菜', '芫荽'],
      'houttuynia': <String>['鱼腥草'],
      'rice': <String>['米饭', '米', '糯米', '紫米'],
      'tofu': <String>['豆腐', '千叶豆腐', '豆腐干'],
      'mushroom': <String>['香菇', '蘑菇', '口蘑', '平菇', '金针菇', '鸡腿菇'],
      'cabbage': <String>['白菜', '包心菜', '卷心菜', '圆白菜'],
      'cucumber': <String>['黄瓜'],
      'pepper': <String>['青椒', '红椒', '彩椒', '尖椒'],
      'eggplant': <String>['茄子'],
      'carrot': <String>['胡萝卜'],
      'broccoli': <String>['西蓝花', '西兰花'],
      'corn': <String>['玉米'],
      'spinach': <String>['菠菜'],
    };

const Map<String, String> _eatIngredientSpecificOverrideMap = <String, String>{
  '豆腐': 'tofu',
  '千叶豆腐': 'tofu',
  '豆腐干': 'tofu',
  '牛奶': 'milk',
  '鲜奶': 'milk',
  '纯牛奶': 'milk',
  '鸡蛋': 'egg',
  '蛋': 'egg',
};

const Map<String, List<String>> _eatContainsKeywordMap = <String, List<String>>{
  'pork': <String>[
    '猪肉',
    '里脊',
    '排骨',
    '猪蹄',
    '猪肚',
    '腊肉',
    '腊肠',
    '火腿',
    '午餐肉',
    '培根',
    '猪油',
    '肉末',
  ],
  'beef': <String>['牛肉', '牛腩', '牛柳', '肥牛', '牛排'],
  'mutton': <String>['羊肉', '羊排'],
  'seafood': <String>['鱼', '虾', '蟹', '鱿鱼', '鲜贝', '干贝', '海参', '海米', '章鱼', '金枪鱼'],
  'egg': <String>['鸡蛋', '蛋', '皮蛋', '松花蛋'],
  'milk': <String>['牛奶', '鲜奶', '纯牛奶'],
  'dairy': <String>['牛奶', '奶油', '奶酪', '乳酪', '黄油', '酸奶', '淡奶油', '奶粉'],
  'gluten': <String>['面粉', '面包', '吐司', '面条', '意面', '挂面', '馄饨皮', '饺子皮'],
  'soy': <String>['豆腐', '豆腐干', '豆腐皮', '腐竹', '黄豆', '酱油', '豆瓣'],
  'peanut': <String>['花生', '花生仁', '花生酱'],
  'nut': <String>['松仁', '核桃', '腰果', '杏仁', '板栗', '栗子', '开心果', '榛子'],
  'sesame': <String>['芝麻', '麻酱', '香油'],
  'spicy': <String>['辣椒', '泡椒', '辣油', '辣酱', '花椒'],
  'alcohol': <String>['料酒', '黄酒', '啤酒', '白酒', '米酒', '绍酒', '葡萄酒', '红酒'],
  'cilantro': <String>['香菜', '芫荽'],
  'houttuynia': <String>['鱼腥草'],
};

const Map<String, List<String>> _eatTypeKeywordMap = <String, List<String>>{
  'cold_dish': <String>['凉拌', '拌', '沙拉', '冷盘', '泡菜'],
  'soup': <String>['汤', '羹'],
  'stir_fry': <String>['炒', '爆', '煸', '熘'],
  'braise': <String>['红烧', '烧', '卤', '焖'],
  'stew': <String>['炖', '煮', '煲'],
  'steam': <String>['蒸'],
  'pan_fry': <String>['煎', '锅贴'],
  'deep_fry': <String>['炸', '酥'],
  'bake': <String>['烤', '焗', '蛋糕', '吐司'],
  'rice': <String>['炒饭', '焖饭', '米饭', '粥', '拌饭', '抓饭', '饭团', '盖饭', '蛋包饭', '煲仔饭'],
  'noodle': <String>['面条', '意面', '意粉', '通心粉', '拉面', '刀削面', '挂面', '米粉', '河粉'],
  'dessert': <String>['蛋糕', '布丁', '甜品', '点心', '八宝饭', '慕斯', '奶冻', '冰淇淋', '甜点'],
};

const Map<String, String> _eatTypeFromMethodMap = <String, String>{
  '炒': 'stir_fry',
  '煎': 'pan_fry',
  '炸': 'deep_fry',
  '烤': 'bake',
  '焗': 'bake',
  '蒸': 'steam',
  '煮': 'soup',
  '炖': 'stew',
  '煲': 'stew',
  '拌': 'cold_dish',
  '烧': 'braise',
  '焖': 'braise',
};

List<String> eatMealIds(DailyChoiceOption option) {
  final values = option.attributeValues(eatAttributeMeal);
  return values.isEmpty ? <String>[option.categoryId] : values;
}

List<String> eatContainsExpandedTokens(String token) {
  final normalized = token.trim();
  if (normalized == eatContainsPeanutNut) {
    return const <String>['peanut', 'nut'];
  }
  return normalized.isEmpty ? const <String>[] : <String>[normalized];
}

List<String> eatIngredientKeywords(DailyChoiceOption option) {
  final storedValues = option.attributeValues(eatAttributeIngredient);
  if (storedValues.isNotEmpty) {
    final preparedValues = _prepareStoredIngredientTokens(storedValues);
    if (preparedValues.isNotEmpty &&
        !_shouldNormalizeStoredIngredientTokens(preparedValues)) {
      return preparedValues;
    }
    final normalizedValues = normalizeEatIngredientInputs(preparedValues);
    if (normalizedValues.isNotEmpty) {
      return normalizedValues;
    }
  }
  return normalizeEatIngredientInputs(<String>[
    option.titleZh,
    ...option.materialsZh,
    ...option.tagsZh,
    ...option.notesZh,
  ]);
}

List<String> _prepareStoredIngredientTokens(Iterable<String> rawValues) {
  return _dedupeStrings(
    rawValues
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map(
          (item) => _eatIngredientCanonicalMap.containsKey(item.toLowerCase())
              ? item.toLowerCase()
              : item,
        )
        .toList(growable: false),
  );
}

bool _shouldNormalizeStoredIngredientTokens(List<String> values) {
  for (final value in values) {
    if (_eatIngredientCanonicalMap.containsKey(value)) {
      continue;
    }
    if (_eatIngredientSpecificOverrideMap.containsKey(value)) {
      return true;
    }
    for (final aliases in _eatIngredientCanonicalMap.values) {
      if (aliases.contains(value)) {
        return true;
      }
      if (aliases.any((alias) => alias.length >= 2 && value.contains(alias))) {
        return true;
      }
    }
  }
  return false;
}

bool eatMatchesMeal(DailyChoiceOption option, String mealId) {
  return eatMealIds(option).contains(mealId);
}

String? guessEatToolIdFromTitle(String title) {
  if (title.contains('电饭煲')) {
    return 'rice_cooker';
  }
  if (title.contains('微波')) {
    return 'microwave';
  }
  if (title.contains('空气炸锅')) {
    return 'air_fryer';
  }
  if (title.contains('烤箱') || title.contains('烘烤')) {
    return 'oven';
  }
  return null;
}

bool eatMatchesTool(DailyChoiceOption option, String toolId) {
  if (toolId == 'all') {
    return true;
  }
  if (option.contextIds.contains(toolId)) {
    return true;
  }
  if (option.contextId == toolId) {
    return true;
  }
  final attributeTools = option.attributeValues(eatAttributeTool);
  if (attributeTools.contains(toolId)) {
    return true;
  }
  return guessEatToolIdFromTitle(option.titleZh) == toolId;
}

bool isEatOptionAttributeReady(DailyChoiceOption option) {
  if (option.moduleId != DailyChoiceModuleId.eat.storageValue) {
    return true;
  }
  if (!option.attributes.keys.toSet().containsAll(_eatRequiredAttributeKeys)) {
    return false;
  }
  final mealIds = option.attributeValues(eatAttributeMeal);
  if (mealIds.isEmpty || !mealIds.contains(option.categoryId)) {
    return false;
  }
  final ingredientKeywords = option.attributeValues(eatAttributeIngredient);
  if (ingredientKeywords.isEmpty) {
    return false;
  }
  final expectedTools = <String>{
    ...option.contextIds,
    if (option.contextId != null && option.contextId!.isNotEmpty)
      option.contextId!,
  };
  if (expectedTools.isEmpty) {
    return true;
  }
  final attributeTools = option.attributeValues(eatAttributeTool).toSet();
  return attributeTools.containsAll(expectedTools);
}

DailyChoiceOption ensureEatOptionAttributes(DailyChoiceOption option) {
  if (option.moduleId != DailyChoiceModuleId.eat.storageValue) {
    return option;
  }
  if (isEatOptionAttributeReady(option)) {
    return option;
  }

  final inferred = buildEatAttributes(
    title: option.titleZh,
    materials: option.materialsZh,
    notes: option.notesZh,
    tags: <String>[
      ...option.tagsZh,
      ...option.tagsEn,
      option.subtitleZh,
      option.subtitleEn,
    ],
    tools: <String>[
      ...option.contextIds,
      if (option.contextId != null) option.contextId!,
    ],
    primaryMealId: option.categoryId,
  );

  final mergedAttributes = <String, List<String>>{};
  final keys = <String>{...option.attributes.keys, ...inferred.keys};
  for (final key in keys) {
    var values = _dedupeStrings(<String>[
      ...option.attributeValues(key),
      ...?inferred[key],
    ]);
    if (key == eatAttributeIngredient) {
      values = normalizeEatIngredientInputs(values);
    }
    if (values.isNotEmpty) {
      mergedAttributes[key] = values;
    }
  }

  final mealIds = _dedupeStrings(<String>[
    option.categoryId,
    ...mergedAttributes[eatAttributeMeal] ?? const <String>[],
  ]);
  if (mealIds.isNotEmpty) {
    mergedAttributes[eatAttributeMeal] = mealIds;
  }

  final contextIds = _dedupeStrings(<String>[
    ...option.contextIds,
    if (option.contextId != null) option.contextId!,
    ...mergedAttributes[eatAttributeTool] ?? const <String>[],
  ]);
  if (contextIds.isNotEmpty) {
    mergedAttributes[eatAttributeTool] = contextIds;
  }

  return option.copyWith(
    categoryId: mealIds.isEmpty ? option.categoryId : mealIds.first,
    contextId: contextIds.isEmpty ? option.contextId : contextIds.first,
    contextIds: contextIds,
    attributes: mergedAttributes,
  );
}

Map<String, List<String>> buildEatAttributes({
  required String title,
  required List<String> materials,
  List<String> notes = const <String>[],
  List<String> tags = const <String>[],
  List<String> methods = const <String>[],
  List<String> tools = const <String>[],
  String? primaryMealId,
}) {
  final keywords = normalizeEatIngredientInputs(<String>[
    title,
    ...materials,
    ...notes,
    ...tags,
    ...methods,
  ]);
  final contains = _collectEatContains(title, materials, notes, tags, methods);
  final types = _collectEatTypes(title, tags, methods);
  final profiles = _collectEatProfiles(types, keywords, contains);
  final meals = _collectEatMeals(
    title: title,
    types: types,
    notes: notes,
    primaryMealId: primaryMealId,
  );
  final normalizedTools = _dedupeStrings(
    tools
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false),
  );

  return <String, List<String>>{
    eatAttributeMeal: meals,
    eatAttributeType: types,
    eatAttributeProfile: profiles,
    eatAttributeContains: contains,
    eatAttributeIngredient: keywords,
    if (normalizedTools.isNotEmpty) eatAttributeTool: normalizedTools,
  };
}

DailyChoiceOption mergeEatOptions(
  DailyChoiceOption left,
  DailyChoiceOption right,
) {
  final normalizedLeft = ensureEatOptionAttributes(left);
  final normalizedRight = ensureEatOptionAttributes(right);
  final richer =
      _eatOptionQuality(normalizedLeft) >= _eatOptionQuality(normalizedRight)
      ? normalizedLeft
      : normalizedRight;
  final secondary = identical(richer, normalizedLeft)
      ? normalizedRight
      : normalizedLeft;

  final mergedAttributes = <String, List<String>>{...richer.attributes};
  for (final entry in secondary.attributes.entries) {
    var values = _dedupeStrings(<String>[
      ...mergedAttributes[entry.key] ?? const <String>[],
      ...entry.value,
    ]);
    if (entry.key == eatAttributeIngredient) {
      values = normalizeEatIngredientInputs(values);
    }
    mergedAttributes[entry.key] = values;
  }

  final mergedContextIds = _dedupeStrings(<String>[
    ...richer.contextIds,
    ...secondary.contextIds,
    if (richer.contextId != null) richer.contextId!,
    if (secondary.contextId != null) secondary.contextId!,
  ]);
  if (mergedContextIds.isNotEmpty) {
    mergedAttributes[eatAttributeTool] = mergedContextIds;
  }

  final mergedMealIds = _dedupeStrings(<String>[
    ...eatMealIds(normalizedLeft),
    ...eatMealIds(normalizedRight),
  ]);
  if (mergedMealIds.isNotEmpty) {
    mergedAttributes[eatAttributeMeal] = mergedMealIds;
  }

  return ensureEatOptionAttributes(
    richer.copyWith(
      categoryId: mergedMealIds.isEmpty
          ? richer.categoryId
          : mergedMealIds.first,
      contextId: mergedContextIds.isEmpty
          ? richer.contextId
          : mergedContextIds.first,
      contextIds: mergedContextIds,
      subtitleZh: _preferLonger(richer.subtitleZh, secondary.subtitleZh),
      subtitleEn: _preferLonger(richer.subtitleEn, secondary.subtitleEn),
      detailsZh: _preferLonger(richer.detailsZh, secondary.detailsZh),
      detailsEn: _preferLonger(richer.detailsEn, secondary.detailsEn),
      materialsZh: _preferLongerList(richer.materialsZh, secondary.materialsZh),
      materialsEn: _preferLongerList(richer.materialsEn, secondary.materialsEn),
      stepsZh: _preferLongerList(richer.stepsZh, secondary.stepsZh),
      stepsEn: _preferLongerList(richer.stepsEn, secondary.stepsEn),
      notesZh: _dedupeStrings(<String>[
        ...richer.notesZh,
        ...secondary.notesZh,
      ]),
      notesEn: _dedupeStrings(<String>[
        ...richer.notesEn,
        ...secondary.notesEn,
      ]),
      tagsZh: _dedupeStrings(<String>[...richer.tagsZh, ...secondary.tagsZh]),
      tagsEn: _dedupeStrings(<String>[...richer.tagsEn, ...secondary.tagsEn]),
      sourceLabel: richer.sourceLabel ?? secondary.sourceLabel,
      sourceUrl: richer.sourceUrl ?? secondary.sourceUrl,
      references: _mergeReferenceLists(richer.references, secondary.references),
      attributes: mergedAttributes,
    ),
  );
}

List<DailyChoiceOption> mergeEatOptionCollections(
  Iterable<DailyChoiceOption> options,
) {
  final merged = <String, DailyChoiceOption>{};
  for (final rawOption in options) {
    final option = ensureEatOptionAttributes(rawOption);
    final key = _eatOptionDedupeKey(option);
    final existing = merged[key];
    merged[key] = existing == null ? option : mergeEatOptions(existing, option);
  }
  final values = merged.values.toList(growable: false)
    ..sort((left, right) {
      final mealCompare = _mealSortOrder(
        left.categoryId,
      ).compareTo(_mealSortOrder(right.categoryId));
      if (mealCompare != 0) {
        return mealCompare;
      }
      final toolCompare = (left.contextId ?? '').compareTo(
        right.contextId ?? '',
      );
      if (toolCompare != 0) {
        return toolCompare;
      }
      return left.titleZh.compareTo(right.titleZh);
    });
  return List<DailyChoiceOption>.unmodifiable(values);
}

List<String> normalizeEatIngredientInputs(Iterable<String> rawValues) {
  final values = <String>[];
  for (final rawValue in rawValues) {
    for (final token in _splitIngredientInputTokens(rawValue)) {
      values.addAll(_normalizeEatIngredientTokenValues(token));
    }
  }
  return _dedupeStrings(values);
}

String eatTokenLabelZh(String token) {
  return _eatCanonicalLabelZhMap[token] ?? token;
}

enum DailyChoiceEatIngredientMatchStage { none, exact, strong, broad }

class DailyChoiceEatIngredientPriorityResult {
  const DailyChoiceEatIngredientPriorityResult({
    required this.options,
    required this.normalizedAvailableIngredients,
    required this.stage,
    required this.bestIngredientMatchCount,
    required this.exactMatchCount,
    required this.strongMatchCount,
    required this.relatedMatchCount,
    required this.broadenedForVariety,
  });

  const DailyChoiceEatIngredientPriorityResult.empty()
    : options = const <DailyChoiceOption>[],
      normalizedAvailableIngredients = const <String>[],
      stage = DailyChoiceEatIngredientMatchStage.none,
      bestIngredientMatchCount = 0,
      exactMatchCount = 0,
      strongMatchCount = 0,
      relatedMatchCount = 0,
      broadenedForVariety = false;

  final List<DailyChoiceOption> options;
  final List<String> normalizedAvailableIngredients;
  final DailyChoiceEatIngredientMatchStage stage;
  final int bestIngredientMatchCount;
  final int exactMatchCount;
  final int strongMatchCount;
  final int relatedMatchCount;
  final bool broadenedForVariety;

  bool get hasMatchedCandidates =>
      options.isNotEmpty && bestIngredientMatchCount > 0;
}

int eatIngredientMatchCount(
  DailyChoiceOption option,
  Iterable<String> availableIngredients,
) {
  final available = normalizeEatIngredientInputs(availableIngredients).toSet();
  if (available.isEmpty) {
    return 0;
  }
  return eatIngredientKeywords(
    option,
  ).where((item) => available.contains(item)).length;
}

double eatIngredientMatchRatio(
  DailyChoiceOption option,
  Iterable<String> availableIngredients,
) {
  final keywords = eatIngredientKeywords(option);
  if (keywords.isEmpty) {
    return 0;
  }
  return eatIngredientMatchCount(option, availableIngredients) /
      keywords.length;
}

DailyChoiceEatIngredientPriorityResult chooseIngredientPrioritizedEatOptions(
  Iterable<DailyChoiceOption> options,
  Iterable<String> availableIngredients, {
  int minPoolSize = 8,
  int maxPoolSize = 36,
}) {
  final normalizedAvailable = normalizeEatIngredientInputs(
    availableIngredients,
  );
  final candidateList = options.toList(growable: false);
  if (candidateList.isEmpty || normalizedAvailable.isEmpty) {
    return DailyChoiceEatIngredientPriorityResult(
      options: candidateList,
      normalizedAvailableIngredients: normalizedAvailable,
      stage: DailyChoiceEatIngredientMatchStage.none,
      bestIngredientMatchCount: 0,
      exactMatchCount: 0,
      strongMatchCount: 0,
      relatedMatchCount: 0,
      broadenedForVariety: false,
    );
  }

  final availableSet = normalizedAvailable.toSet();
  final strongThreshold = normalizedAvailable.length <= 2
      ? 1
      : math.max(2, (normalizedAvailable.length * 0.6).ceil());
  final scored = <_EatIngredientScore>[];

  for (final option in candidateList) {
    final keywordSet = eatIngredientKeywords(option).toSet();
    if (keywordSet.isEmpty) {
      continue;
    }
    final matchCount = keywordSet.intersection(availableSet).length;
    if (matchCount <= 0) {
      continue;
    }
    final availableCoverage = matchCount / normalizedAvailable.length;
    final recipeCoverage = matchCount / keywordSet.length;
    final unionCount = keywordSet.union(availableSet).length;
    final similarity = unionCount <= 0 ? 0.0 : matchCount / unionCount;
    scored.add(
      _EatIngredientScore(
        option: option,
        matchCount: matchCount,
        availableCoverage: availableCoverage,
        recipeCoverage: recipeCoverage,
        similarity: similarity,
      ),
    );
  }

  if (scored.isEmpty) {
    return DailyChoiceEatIngredientPriorityResult(
      options: candidateList,
      normalizedAvailableIngredients: normalizedAvailable,
      stage: DailyChoiceEatIngredientMatchStage.none,
      bestIngredientMatchCount: 0,
      exactMatchCount: 0,
      strongMatchCount: 0,
      relatedMatchCount: 0,
      broadenedForVariety: false,
    );
  }

  scored.sort(_compareEatIngredientScore);
  final exactMatches = scored
      .where((item) => item.matchCount >= normalizedAvailable.length)
      .toList(growable: false);
  final strongMatches = scored
      .where((item) => item.matchCount >= strongThreshold)
      .toList(growable: false);
  final relatedMatches = scored.toList(growable: false);

  late final DailyChoiceEatIngredientMatchStage stage;
  late final List<_EatIngredientScore> primaryMatches;
  if (exactMatches.isNotEmpty) {
    stage = DailyChoiceEatIngredientMatchStage.exact;
    primaryMatches = exactMatches;
  } else if (strongMatches.isNotEmpty) {
    stage = DailyChoiceEatIngredientMatchStage.strong;
    primaryMatches = strongMatches;
  } else {
    stage = DailyChoiceEatIngredientMatchStage.broad;
    primaryMatches = relatedMatches;
  }

  final selected = <_EatIngredientScore>[];
  final seen = <String>{};
  for (final item in primaryMatches) {
    if (seen.add(item.option.id)) {
      selected.add(item);
    }
  }

  if (selected.length < minPoolSize) {
    for (final item in relatedMatches) {
      if (!seen.add(item.option.id)) {
        continue;
      }
      selected.add(item);
      if (selected.length >= minPoolSize || selected.length >= maxPoolSize) {
        break;
      }
    }
  } else if (selected.length > maxPoolSize) {
    selected.removeRange(maxPoolSize, selected.length);
  }

  final optionsForRandom = selected
      .map((item) => item.option)
      .toList(growable: false);
  return DailyChoiceEatIngredientPriorityResult(
    options: optionsForRandom,
    normalizedAvailableIngredients: normalizedAvailable,
    stage: stage,
    bestIngredientMatchCount: scored.first.matchCount,
    exactMatchCount: exactMatches.length,
    strongMatchCount: strongMatches.length,
    relatedMatchCount: relatedMatches.length,
    broadenedForVariety: selected.length > primaryMatches.length,
  );
}

List<DailyChoiceOption> chooseBestMatchedEatOptions(
  Iterable<DailyChoiceOption> options,
  Iterable<String> availableIngredients,
) {
  return chooseIngredientPrioritizedEatOptions(
    options,
    availableIngredients,
  ).options;
}

List<DailyChoiceReferenceLink> _mergeReferenceLists(
  List<DailyChoiceReferenceLink> first,
  List<DailyChoiceReferenceLink> second,
) {
  final merged = <DailyChoiceReferenceLink>[];
  final seen = <String>{};
  for (final item in <DailyChoiceReferenceLink>[...first, ...second]) {
    if (seen.add(item.url)) {
      merged.add(item);
    }
  }
  return merged;
}

List<String> _collectEatContains(
  String title,
  List<String> materials,
  List<String> notes,
  List<String> tags,
  List<String> methods,
) {
  final haystack = <String>[
    title,
    ...materials,
    ...notes,
    ...tags,
    ...methods,
  ].join(' ');
  final values = <String>[];
  for (final entry in _eatContainsKeywordMap.entries) {
    if (entry.value.any(haystack.contains)) {
      values.add(entry.key);
    }
  }
  return _dedupeStrings(values);
}

List<String> _collectEatTypes(
  String title,
  List<String> tags,
  List<String> methods,
) {
  final haystack = <String>[title, ...tags].join(' ');
  final values = <String>[];
  for (final entry in _eatTypeKeywordMap.entries) {
    if (entry.value.any(haystack.contains)) {
      values.add(entry.key);
    }
  }
  for (final method in methods) {
    final mapped = _eatTypeFromMethodMap[method.trim()];
    if (mapped != null) {
      values.add(mapped);
    }
  }
  return _dedupeStrings(values);
}

List<String> _collectEatProfiles(
  List<String> types,
  List<String> keywords,
  List<String> contains,
) {
  final values = <String>[];
  final hasAnimalProtein =
      contains.any(
        (item) =>
            item == 'pork' ||
            item == 'beef' ||
            item == 'mutton' ||
            item == 'chicken' ||
            item == 'duck' ||
            item == 'seafood',
      ) ||
      keywords.any(
        (item) =>
            item == 'pork' ||
            item == 'beef' ||
            item == 'mutton' ||
            item == 'chicken' ||
            item == 'duck' ||
            item == 'seafood',
      );
  final hasPlantOrEgg = keywords.any(
    (item) =>
        item == 'egg' ||
        item == 'tofu' ||
        item == 'mushroom' ||
        item == 'tomato' ||
        item == 'potato' ||
        item == 'cabbage' ||
        item == 'cucumber' ||
        item == 'pepper' ||
        item == 'eggplant' ||
        item == 'carrot' ||
        item == 'broccoli' ||
        item == 'corn' ||
        item == 'spinach',
  );
  if (!hasAnimalProtein) {
    values.add(eatProfileVegetarian);
  } else {
    values.add(eatProfileMeatBased);
  }
  if (hasAnimalProtein && hasPlantOrEgg) {
    values.add(eatProfileMixed);
  }
  if (types.contains('rice') || types.contains('noodle')) {
    values.add(eatProfileStaple);
  }
  if (types.contains('dessert')) {
    values.add(eatProfileDessert);
  }
  return _dedupeStrings(values);
}

List<String> _collectEatMeals({
  required String title,
  required List<String> types,
  required List<String> notes,
  required String? primaryMealId,
}) {
  final haystack = <String>[title, ...notes].join(' ');
  final values = <String>[];
  if (primaryMealId != null && primaryMealId.isNotEmpty) {
    values.add(primaryMealId);
  }
  if (haystack.contains('早餐') ||
      haystack.contains('早饭') ||
      haystack.contains('吐司') ||
      haystack.contains('燕麦') ||
      haystack.contains('蛋包饭') ||
      haystack.contains('粥')) {
    values.add('breakfast');
  }
  if (haystack.contains('下午茶') ||
      haystack.contains('甜品') ||
      haystack.contains('点心') ||
      types.contains('dessert')) {
    values.add('tea');
  }
  if (haystack.contains('夜宵') || haystack.contains('夜食')) {
    values.add('night');
  }
  if (types.any(
    (item) =>
        item == 'rice' ||
        item == 'noodle' ||
        item == 'soup' ||
        item == 'stir_fry' ||
        item == 'braise' ||
        item == 'stew' ||
        item == 'steam',
  )) {
    values.addAll(const <String>['lunch', 'dinner']);
  }
  if (values.isEmpty) {
    values.addAll(const <String>['lunch', 'dinner']);
  } else if (values.contains('lunch') && !values.contains('dinner')) {
    values.add('dinner');
  } else if (values.contains('dinner') && !values.contains('lunch')) {
    values.add('lunch');
  }
  return _dedupeStrings(values);
}

List<String> _splitIngredientInputTokens(String raw) {
  if (raw.trim().isEmpty) {
    return const <String>[];
  }
  return raw
      .split(RegExp(r'[\n\r、，,；;|/]+|\s+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<String> _normalizeEatIngredientTokenValues(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return const <String>[];
  }
  final specific = _eatIngredientSpecificOverrideMap[value];
  if (specific != null) {
    return <String>[specific];
  }
  final exactMatches = <String>[];
  for (final entry in _eatIngredientCanonicalMap.entries) {
    if (entry.key == value.toLowerCase()) {
      exactMatches.add(entry.key);
    }
    for (final alias in entry.value) {
      if (value == alias) {
        exactMatches.add(entry.key);
      }
    }
  }
  if (exactMatches.isNotEmpty) {
    return _dedupeStrings(exactMatches);
  }

  final containedMatches = _containedCanonicalIngredientTokens(value);
  if (containedMatches.isNotEmpty) {
    return containedMatches;
  }

  final cleaned = _cleanUnknownIngredientToken(value);
  if (cleaned.isEmpty) {
    return const <String>[];
  }
  final cleanedSpecific = _eatIngredientSpecificOverrideMap[cleaned];
  if (cleanedSpecific != null) {
    return <String>[cleanedSpecific];
  }
  final cleanedExactMatches = <String>[];
  for (final entry in _eatIngredientCanonicalMap.entries) {
    if (entry.key == cleaned.toLowerCase()) {
      cleanedExactMatches.add(entry.key);
    }
    for (final alias in entry.value) {
      if (cleaned == alias) {
        cleanedExactMatches.add(entry.key);
      }
    }
  }
  if (cleanedExactMatches.isNotEmpty) {
    return _dedupeStrings(cleanedExactMatches);
  }
  final cleanedContainedMatches = _containedCanonicalIngredientTokens(cleaned);
  if (cleanedContainedMatches.isNotEmpty) {
    return cleanedContainedMatches;
  }
  return <String>[cleaned];
}

List<String> _containedCanonicalIngredientTokens(String value) {
  final matches = <String>[];
  for (final entry in _eatIngredientCanonicalMap.entries) {
    for (final alias in entry.value) {
      final specific = _eatIngredientSpecificOverrideMap[alias];
      if (specific != null && specific != entry.key) {
        continue;
      }
      if (alias.length >= 2 && value.contains(alias)) {
        matches.add(entry.key);
        break;
      }
    }
  }
  return _dedupeStrings(matches);
}

String _cleanUnknownIngredientToken(String raw) {
  var value = raw.trim();
  value = value.replaceAll(RegExp(r'（[^）]*）|\([^)]*\)'), '');
  value = value.replaceAll(RegExp(r'[0-9０-９一二三四五六七八九十百千两半]+'), '');
  for (final noise in <String>[
    '适量',
    '少许',
    '少量',
    '各',
    '切片',
    '切丝',
    '切丁',
    '切段',
    '切末',
    '洗净',
    '去皮',
    '去蒂',
    '去核',
    '焯水',
    '沥干',
    '毫升',
    '升',
    '克',
    '公斤',
    '斤',
    '匙',
    '勺',
    '杯',
    '碗',
    '个',
    '只',
    '根',
    '片',
    '块',
    '条',
    '朵',
    '枚',
    '张',
    'ml',
    'mL',
    'g',
    'kg',
  ]) {
    value = value.replaceAll(noise, '');
  }
  value = value.replaceAll(RegExp(r'[A-Za-z]+'), '');
  value = value.replaceAll(RegExp(r'[、，,；;。.．\s]+'), '');
  return value.trim();
}

String _eatOptionDedupeKey(DailyChoiceOption option) {
  final title = option.titleZh.isNotEmpty ? option.titleZh : option.titleEn;
  return title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fa5]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

int _mealSortOrder(String mealId) {
  return switch (mealId) {
    'breakfast' => 0,
    'lunch' => 1,
    'dinner' => 2,
    'tea' => 3,
    'night' => 4,
    _ => 99,
  };
}

int _eatOptionQuality(DailyChoiceOption option) {
  return option.materialsZh.length * 2 +
      option.stepsZh.length * 3 +
      option.notesZh.length +
      option.tagsZh.length +
      (option.detailsZh.length ~/ 18);
}

class _EatIngredientScore {
  const _EatIngredientScore({
    required this.option,
    required this.matchCount,
    required this.availableCoverage,
    required this.recipeCoverage,
    required this.similarity,
  });

  final DailyChoiceOption option;
  final int matchCount;
  final double availableCoverage;
  final double recipeCoverage;
  final double similarity;
}

int _compareEatIngredientScore(
  _EatIngredientScore left,
  _EatIngredientScore right,
) {
  final matchCompare = right.matchCount.compareTo(left.matchCount);
  if (matchCompare != 0) {
    return matchCompare;
  }
  final availableCompare = right.availableCoverage.compareTo(
    left.availableCoverage,
  );
  if (availableCompare != 0) {
    return availableCompare;
  }
  final recipeCompare = right.recipeCoverage.compareTo(left.recipeCoverage);
  if (recipeCompare != 0) {
    return recipeCompare;
  }
  final similarityCompare = right.similarity.compareTo(left.similarity);
  if (similarityCompare != 0) {
    return similarityCompare;
  }
  return left.option.titleZh.compareTo(right.option.titleZh);
}

String _preferLonger(String left, String right) {
  return left.length >= right.length ? left : right;
}

List<String> _preferLongerList(List<String> left, List<String> right) {
  if (left.length == right.length) {
    return left.isNotEmpty ? left : right;
  }
  return left.length > right.length ? left : right;
}

List<String> _dedupeStrings(List<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final normalized = value.trim();
    if (normalized.isEmpty || !seen.add(normalized)) {
      continue;
    }
    result.add(normalized);
  }
  return result;
}

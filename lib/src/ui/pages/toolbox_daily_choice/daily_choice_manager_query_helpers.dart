part of 'daily_choice_widgets.dart';

String _resolveManagerEditorCategoryId({
  required List<DailyChoiceCategory> categories,
  required DailyChoiceOption? option,
  required String selectedCategoryId,
}) {
  final categoryIds = categories.map((item) => item.id).toSet();
  final candidates = <String?>[option?.categoryId, selectedCategoryId];
  for (final candidate in candidates) {
    if (candidate != null &&
        candidate != 'all' &&
        categoryIds.contains(candidate)) {
      return candidate;
    }
  }
  return categories.isEmpty ? selectedCategoryId : categories.first.id;
}

String? _resolveManagerEditorContextId({
  required List<DailyChoiceCategory> contexts,
  required DailyChoiceOption? option,
  required String? selectedContextId,
}) {
  if (contexts.isEmpty) {
    return null;
  }
  final contextIds = contexts.map((item) => item.id).toSet();
  final candidates = <String?>[
    option?.contextId,
    ...?option?.contextIds,
    selectedContextId,
  ];
  for (final candidate in candidates) {
    if (candidate != null &&
        candidate != 'all' &&
        contextIds.contains(candidate)) {
      return candidate;
    }
  }
  return contexts.first.id;
}

String _builtInSectionSubtitle(
  AppI18n i18n, {
  required bool builtInExpanded,
  required int total,
  required int visible,
  bool loading = false,
  String? errorMessage,
  bool isWearModule = false,
}) {
  if (!builtInExpanded) {
    return pickUiText(
      i18n,
      zh: isWearModule ? '展开后按当前搜索和筛选查看内置参考搭配。' : '展开后按当前搜索和筛选查看内置菜谱。',
      en: 'Expand to show built-ins using the current search and filters.',
    );
  }
  if (loading && visible == 0) {
    return pickUiText(
      i18n,
      zh: isWearModule ? '正在按当前筛选读取内置参考搭配。' : '正在按当前筛选读取内置菜谱。',
      en: 'Loading built-ins for the current filters.',
    );
  }
  if (errorMessage != null) {
    return pickUiText(
      i18n,
      zh: isWearModule ? '读取内置参考搭配时遇到问题，可稍后重试。' : '读取内置菜谱时遇到问题，可稍后重试。',
      en: 'Built-ins could not be loaded. Try again later.',
    );
  }
  return pickUiText(
    i18n,
    zh: total > visible
        ? isWearModule
              ? '已显示 $visible / $total 条；搜索和筛选仍作用于完整参考搭配库。'
              : '已显示 $visible / $total 条；搜索和筛选仍作用于完整菜谱库。'
        : isWearModule
        ? '可把内置搭配当模板，调整后另存为自己的真实衣柜搭配。'
        : '可隐藏不喜欢的条目，也可在原菜谱上做个人调整或另存为个人食谱。',
    en: total > visible
        ? 'Showing $visible of $total; search and filters still cover the full library.'
        : 'Hide unwanted items, save adjustments, or copy a built-in as your own ${isWearModule ? 'outfit' : 'recipe'}.',
  );
}

String _managerBuiltInSqlQueryKey({
  required String cacheKey,
  required int offset,
  required int limit,
}) {
  return '$cacheKey\u0001$offset\u0001$limit';
}

DailyChoiceEatLibraryQuery _managerEatBuiltInLibraryQuery({
  required String categoryId,
  required String? contextId,
  required String searchQuery,
  required Map<String, String> traitFilters,
  required Set<String>? selectedCollectionOptionIds,
  required int limit,
  required int offset,
}) {
  return DailyChoiceEatLibraryQuery(
    mealId: categoryId,
    toolId: contextId ?? 'all',
    searchText: searchQuery,
    selectedTraitFilters: <String, Set<String>>{
      for (final entry in traitFilters.entries)
        if (entry.value != 'all') entry.key: <String>{entry.value},
    },
    allowedOptionIds: selectedCollectionOptionIds,
    limit: limit,
    offset: offset,
  );
}

String _managerBuiltInFilterCacheKey({
  required String moduleId,
  required String categoryId,
  required String? contextId,
  required String searchQuery,
  required Map<String, String> traitFilters,
  required String selectedCollectionId,
  required Set<String>? selectedCollectionOptionIds,
}) {
  final traitKey =
      traitFilters.entries
          .map((entry) => '${entry.key}:${entry.value}')
          .toList(growable: false)
        ..sort();
  final collectionIds =
      (selectedCollectionOptionIds?.toList(growable: false) ?? <String>[])
        ..sort();
  return <String>[
    moduleId,
    categoryId,
    contextId ?? '',
    selectedCollectionId,
    collectionIds.join('|'),
    searchQuery.trim().toLowerCase(),
    traitKey.join('|'),
  ].join('\u0001');
}

String _managerDescription(
  AppI18n i18n, {
  required bool isEatModule,
  required bool isWearModule,
}) {
  return pickUiText(
    i18n,
    zh: isWearModule
        ? '内置条目适合作为参考模板；个人衣柜会保存在本机，并可按性别参考、年龄阶段、风格、版型和样式类型管理。'
        : (isEatModule
              ? '不喜欢会先确认再隐藏内置菜；个人调整会覆盖原菜谱参与随机；个人食谱保存在本机并参与高级筛选。'
              : '删除内置条目会把它加入“不喜欢”隐藏列表；自定义条目会保存在本机。'),
    en: isWearModule
        ? 'Built-ins are reference templates. Your wardrobe stays local and can be managed by gender reference, age stage, style, silhouette, and key pieces.'
        : (isEatModule
              ? 'Disliked built-ins are hidden, personal adjustments override built-ins, and personal recipes stay local for filtering and random picks.'
              : 'Deleting a built-in item hides it. Custom items are saved locally.'),
  );
}

String _emptyCustomHint(
  AppI18n i18n, {
  required bool isEatModule,
  required bool isWearModule,
}) {
  return pickUiText(
    i18n,
    zh: isEatModule
        ? '当前筛选下还没有个人食谱。可以补上你常做、爱吃、想长期保存的菜。'
        : (isWearModule
              ? '当前筛选下还没有个人衣柜搭配。可以从真实衣柜新建一套，也可以把内置参考另存后改成自己的单品。'
              : '当前筛选下还没有自定义条目。可以补上自己的搭配、地点或行动。'),
    en: isEatModule
        ? 'No personal recipes in this filter yet. Add the dishes you actually make or want to keep.'
        : (isWearModule
              ? 'No personal wardrobe outfits in this filter yet.'
              : 'No custom items in this filter yet.'),
  );
}

String _emptyBuiltInHint(AppI18n i18n, {required bool isWearModule}) {
  return pickUiText(
    i18n,
    zh: isWearModule
        ? '当前筛选下没有内置参考搭配。可以放宽气温、场景、性别年龄或风格筛选，也可以直接新建自己的衣柜搭配。'
        : '当前筛选下没有内置菜谱，换一个分类或上下文试试。',
    en: isWearModule
        ? 'No built-in reference outfits match this filter.'
        : 'No built-in recipes match this filter.',
  );
}

List<String> _managerChips(
  AppI18n i18n,
  DailyChoiceOption item, {
  required bool isEatModule,
  required bool isWearModule,
}) {
  if (isWearModule) {
    return wearTraitLabels(i18n, item.attributes, limit: 5);
  }
  if (isEatModule) {
    return eatTraitLabels(i18n, item.attributes, limit: 5);
  }
  return const <String>[];
}

bool _matchesManagerFilters(
  DailyChoiceOption option,
  String moduleId,
  String categoryId,
  String? contextId, {
  Map<String, String> traitFilters = const <String, String>{},
  String searchQuery = '',
}) {
  final normalizedQuery = searchQuery.trim().toLowerCase();
  if (normalizedQuery.isNotEmpty) {
    final haystack =
        '${option.titleZh} ${option.titleEn} ${option.subtitleZh} ${option.subtitleEn}'
            .toLowerCase();
    if (!haystack.contains(normalizedQuery)) {
      return false;
    }
  }

  final matchesCategory = categoryId == 'all'
      ? true
      : moduleId == DailyChoiceModuleId.eat.storageValue
      ? eatMatchesMeal(option, categoryId)
      : option.categoryId == categoryId;
  if (!matchesCategory) {
    return false;
  }

  if (contextId != null && contextId != 'all') {
    final matchesContext = moduleId == DailyChoiceModuleId.eat.storageValue
        ? eatMatchesTool(option, contextId)
        : option.contextIds.contains(contextId) ||
              option.contextId == contextId ||
              _guessFallbackContextId(option.titleZh) == contextId;
    if (!matchesContext) {
      return false;
    }
  }

  for (final entry in traitFilters.entries) {
    if (entry.value == 'all') {
      continue;
    }
    if (!option.attributeValues(entry.key).contains(entry.value)) {
      return false;
    }
  }
  return true;
}

String? _guessFallbackContextId(String title) {
  return guessEatToolIdFromTitle(title);
}

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
  bool isActivityModule = false,
}) {
  if (!builtInExpanded) {
    return i18n.t(
      _managerModuleKey(
        wearKey: 'toolbox.daily_choice.manager.builtin.subtitle.collapsed.wear',
        activityKey:
            'toolbox.daily_choice.manager.builtin.subtitle.collapsed.activity',
        eatKey: 'toolbox.daily_choice.manager.builtin.subtitle.collapsed.eat',
        isWearModule: isWearModule,
        isActivityModule: isActivityModule,
      ),
    );
  }
  if (loading && visible == 0) {
    return i18n.t(
      _managerModuleKey(
        wearKey: 'toolbox.daily_choice.manager.builtin.subtitle.loading.wear',
        activityKey:
            'toolbox.daily_choice.manager.builtin.subtitle.loading.activity',
        eatKey: 'toolbox.daily_choice.manager.builtin.subtitle.loading.eat',
        isWearModule: isWearModule,
        isActivityModule: isActivityModule,
      ),
    );
  }
  if (errorMessage != null) {
    return i18n.t(
      _managerModuleKey(
        wearKey: 'toolbox.daily_choice.manager.builtin.subtitle.error.wear',
        activityKey:
            'toolbox.daily_choice.manager.builtin.subtitle.error.activity',
        eatKey: 'toolbox.daily_choice.manager.builtin.subtitle.error.eat',
        isWearModule: isWearModule,
        isActivityModule: isActivityModule,
      ),
    );
  }
  if (total > visible) {
    return i18n.t(
      _managerModuleKey(
        wearKey: 'toolbox.daily_choice.manager.builtin.subtitle.partial.wear',
        activityKey:
            'toolbox.daily_choice.manager.builtin.subtitle.partial.activity',
        eatKey: 'toolbox.daily_choice.manager.builtin.subtitle.partial.eat',
        isWearModule: isWearModule,
        isActivityModule: isActivityModule,
      ),
      params: <String, Object?>{
        'visible': visible,
        'total': total,
      },
    );
  }
  return i18n.t(
    _managerModuleKey(
      wearKey: 'toolbox.daily_choice.manager.builtin.subtitle.ready.wear',
      activityKey:
          'toolbox.daily_choice.manager.builtin.subtitle.ready.activity',
      eatKey: 'toolbox.daily_choice.manager.builtin.subtitle.ready.eat',
      isWearModule: isWearModule,
      isActivityModule: isActivityModule,
    ),
  );
}

String _managerModuleKey({
  required String wearKey,
  required String activityKey,
  required String eatKey,
  String? defaultKey,
  required bool isWearModule,
  bool isActivityModule = false,
}) {
  if (isWearModule) {
    return wearKey;
  }
  if (isActivityModule) {
    return activityKey;
  }
  return defaultKey ?? eatKey;
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
  bool isActivityModule = false,
}) {
  return i18n.t(
    _managerModuleKey(
      wearKey: 'toolbox.daily_choice.manager.description.wear',
      activityKey: 'toolbox.daily_choice.manager.description.activity',
      eatKey: 'toolbox.daily_choice.manager.description.eat',
      defaultKey: 'toolbox.daily_choice.manager.description.default',
      isWearModule: isWearModule,
      isActivityModule: isActivityModule,
    ),
  );
}

String _emptyCustomHint(
  AppI18n i18n, {
  required bool isEatModule,
  required bool isWearModule,
  bool isActivityModule = false,
}) {
  return i18n.t(
    isEatModule
        ? 'toolbox.daily_choice.manager.custom.empty.eat'
        : _managerModuleKey(
            wearKey: 'toolbox.daily_choice.manager.custom.empty.wear',
            activityKey: 'toolbox.daily_choice.manager.custom.empty.activity',
            eatKey: 'toolbox.daily_choice.manager.custom.empty.default',
            isWearModule: isWearModule,
            isActivityModule: isActivityModule,
          ),
  );
}

String _emptyBuiltInHint(
  AppI18n i18n, {
  required bool isWearModule,
  bool isActivityModule = false,
}) {
  return i18n.t(
    _managerModuleKey(
      wearKey: 'toolbox.daily_choice.manager.builtin.empty.wear',
      activityKey: 'toolbox.daily_choice.manager.builtin.empty.activity',
      eatKey: 'toolbox.daily_choice.manager.builtin.empty.eat',
      isWearModule: isWearModule,
      isActivityModule: isActivityModule,
    ),
  );
}

List<String> _managerChips(
  AppI18n i18n,
  DailyChoiceOption item, {
  required bool isEatModule,
  required bool isWearModule,
  bool isActivityModule = false,
}) {
  if (isWearModule) {
    return wearTraitLabels(i18n, item.attributes, limit: 5);
  }
  if (isEatModule) {
    return eatTraitLabels(i18n, item.attributes, limit: 5);
  }
  if (isActivityModule) {
    return item.tags(i18n).take(5).toList(growable: false);
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
        '${option.titleZh} ${option.titleEn} ${option.subtitleZh} ${option.subtitleEn} '
                '${option.detailsZh} ${option.detailsEn} '
                '${option.tagsZh.join(' ')} ${option.tagsEn.join(' ')}'
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

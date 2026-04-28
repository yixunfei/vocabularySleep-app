part of 'daily_choice_widgets.dart';

typedef DailyChoiceSaveAsCustomEditor =
    Future<DailyChoiceEditorResult?> Function(
      DailyChoiceOption option, {
      required List<DailyChoiceEatCollection> eatCollections,
      required Set<String> initialEatCollectionIds,
      required List<DailyChoiceWearCollection> wearCollections,
      required Set<String> initialWearCollectionIds,
    });

Future<void> showDailyChoiceManagerSheet({
  required BuildContext context,
  required AppI18n i18n,
  required Color accent,
  required String moduleId,
  required List<DailyChoiceOption> builtInOptions,
  required DailyChoiceCustomState state,
  required ValueChanged<DailyChoiceCustomState> onStateChanged,
  required List<DailyChoiceCategory> categories,
  required String initialCategoryId,
  List<DailyChoiceCategory> contexts = const <DailyChoiceCategory>[],
  String? initialContextId,
  String contextLabelZh = '场景',
  String contextLabelEn = 'Scene',
  DailyChoiceEatLibraryStore? eatLibraryStore,
  Future<void> Function(DailyChoiceOption option)? onInspectOption,
  Future<DailyChoiceOption?> Function(DailyChoiceOption option)?
  onAdjustBuiltInOption,
  DailyChoiceSaveAsCustomEditor? onSaveBuiltInAsCustom,
  List<DailyChoiceWearCollection> wearCollections =
      const <DailyChoiceWearCollection>[],
}) async {
  var localState = state
      .withDefaultEatCollections()
      .withDefaultWearCollections();
  final filterCategories = categories.any((item) => item.id == 'all')
      ? categories
      : <DailyChoiceCategory>[
          const DailyChoiceCategory(
            id: 'all',
            icon: Icons.grid_view_rounded,
            titleZh: '全部',
            titleEn: 'All',
            subtitleZh: '不过滤分类',
            subtitleEn: 'All categories',
          ),
          ...categories,
        ];
  final filterContexts = contexts.any((item) => item.id == 'all')
      ? contexts
      : <DailyChoiceCategory>[
          DailyChoiceCategory(
            id: 'all',
            icon: Icons.tune_rounded,
            titleZh: '全部',
            titleEn: 'All',
            subtitleZh: '不过滤$contextLabelZh',
            subtitleEn: 'All $contextLabelEn',
          ),
          ...contexts,
        ];
  var selectedCategoryId =
      filterCategories.any((item) => item.id == initialCategoryId)
      ? initialCategoryId
      : filterCategories.first.id;
  var selectedContextId =
      initialContextId ??
      (filterContexts.isEmpty ? null : filterContexts.first.id);
  var searchQuery = '';
  var searchDraft = '';
  var filtersExpanded = false;
  var collectionsExpanded = true;
  var customExpanded = true;
  var adjustedExpanded = true;
  final isEatModule = moduleId == DailyChoiceModuleId.eat.storageValue;
  final isWearModule = moduleId == DailyChoiceModuleId.wear.storageValue;
  var builtInExpanded = !isEatModule;
  var collectionNameDraft = '';
  var collectionInputVersion = 0;
  var selectedCollectionId = 'all';
  var wearCollectionNameDraft = '';
  var wearCollectionInputVersion = 0;
  var selectedWearCollectionId = 'all';
  var builtInVisibleLimit = _managerInitialBuiltInLimit(isEatModule);
  var builtInSqlActiveKey = '';
  var builtInSqlLoadingKey = '';
  var builtInSqlOptions = const <DailyChoiceOption>[];
  var builtInSqlTotal = 0;
  String? builtInSqlError;
  var builtInSqlFailedKey = '';
  var managerSheetClosed = false;
  final managerTraitGroups = isWearModule
      ? wearManagerTraitGroups
      : (isEatModule ? eatManagerTraitGroups : const <DailyChoiceTraitGroup>[]);
  final selectedTraitFilters = <String, String>{
    for (final group in managerTraitGroups) group.id: 'all',
  };
  var builtInFilterCacheKey = '';
  List<DailyChoiceOption> builtInFilterCache = const <DailyChoiceOption>[];
  final managerBusyActionKeys = <String>{};
  final managerActionErrorByOptionId = <String, String>{};
  var builtInAutoLoadKey = '';
  String? managerProcessingMessage;

  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void publish(DailyChoiceCustomState next) {
              localState = next
                  .withDefaultEatCollections()
                  .withDefaultWearCollections();
              onStateChanged(localState);
              setSheetState(() {});
            }

            Future<void> publishWithProcessing(
              DailyChoiceCustomState next,
              String message,
            ) async {
              if (managerSheetClosed) {
                return;
              }
              setSheetState(() {
                managerProcessingMessage = message;
              });
              await WidgetsBinding.instance.endOfFrame;
              if (managerSheetClosed) {
                return;
              }
              publish(next);
              if (managerSheetClosed) {
                return;
              }
              setSheetState(() {
                managerProcessingMessage = null;
              });
            }

            void resetBuiltInPaging() {
              builtInVisibleLimit = _managerInitialBuiltInLimit(isEatModule);
              builtInAutoLoadKey = '';
              builtInSqlFailedKey = '';
            }

            void commitSearchQuery(String value) {
              final next = value.trim();
              searchDraft = next;
              if (searchQuery == next) {
                return;
              }
              setSheetState(() {
                searchQuery = next;
                resetBuiltInPaging();
              });
            }

            void requestBuiltInSqlPage({
              required String filterKey,
              required String key,
              required DailyChoiceEatLibraryQuery query,
            }) {
              if (builtInSqlActiveKey == key || builtInSqlLoadingKey == key) {
                return;
              }
              builtInSqlLoadingKey = key;
              builtInSqlFailedKey = '';
              builtInSqlError = null;
              unawaited(() async {
                try {
                  final result = await eatLibraryStore!.queryBuiltInSummaries(
                    query,
                  );
                  if (managerSheetClosed || builtInSqlLoadingKey != key) {
                    return;
                  }
                  setSheetState(() {
                    final shouldReplace =
                        query.offset <= 0 || builtInSqlActiveKey != filterKey;
                    final mergedOptions = shouldReplace
                        ? result.options
                        : <DailyChoiceOption>[
                            ...builtInSqlOptions,
                            for (final option in result.options)
                              if (!builtInSqlOptions.any(
                                (item) => item.id == option.id,
                              ))
                                option,
                          ];
                    builtInSqlActiveKey = filterKey;
                    builtInSqlLoadingKey = '';
                    builtInSqlOptions = List<DailyChoiceOption>.unmodifiable(
                      mergedOptions,
                    );
                    builtInSqlTotal = result.totalCount;
                    builtInSqlError = null;
                  });
                } catch (error) {
                  if (managerSheetClosed || builtInSqlLoadingKey != key) {
                    return;
                  }
                  setSheetState(() {
                    builtInSqlActiveKey = filterKey;
                    builtInSqlLoadingKey = '';
                    builtInSqlFailedKey = key;
                    if (query.offset <= 0) {
                      builtInSqlOptions = const <DailyChoiceOption>[];
                      builtInSqlTotal = 0;
                    }
                    builtInSqlError = '$error';
                  });
                }
              }());
            }

            final adjustedById = <String, DailyChoiceOption>{
              for (final item in localState.adjustedBuiltInOptions.where(
                (item) => item.moduleId == moduleId,
              ))
                item.id: item,
            };
            final selectedCollection =
                isEatModule && selectedCollectionId != 'all'
                ? localState.eatCollectionById(selectedCollectionId)
                : null;
            if (selectedCollectionId != 'all' && selectedCollection == null) {
              selectedCollectionId = 'all';
            }
            final selectedCollectionOptionIds = selectedCollection?.optionIds
                .toSet();
            DailyChoiceWearCollection? selectedWearCollection =
                selectedWearCollectionId == 'all'
                ? null
                : localState.wearCollectionById(selectedWearCollectionId);
            if (selectedWearCollection == null) {
              selectedWearCollectionId = 'all';
            }
            final selectedWearCollectionOptionIds = selectedWearCollection
                ?.optionIds
                .toSet();
            final userWearCollections = localState.wearCollections
                .where(
                  (collection) => !isBuiltInWearCollectionId(collection.id),
                )
                .toList(growable: false);
            bool matchesCollection(DailyChoiceOption item) {
              if (isEatModule) {
                return selectedCollectionOptionIds == null ||
                    selectedCollectionOptionIds.contains(item.id);
              }
              if (isWearModule) {
                return selectedWearCollectionOptionIds == null ||
                    selectedWearCollectionOptionIds.contains(item.id);
              }
              return true;
            }

            final customItems = localState.customOptions
                .where((item) => item.moduleId == moduleId)
                .where(matchesCollection)
                .where(
                  (item) => _matchesManagerFilters(
                    item,
                    moduleId,
                    selectedCategoryId,
                    selectedContextId,
                    traitFilters: selectedTraitFilters,
                    searchQuery: searchQuery,
                  ),
                )
                .toList(growable: false);
            final adjustedItems = adjustedById.values
                .where(matchesCollection)
                .where(
                  (item) => _matchesManagerFilters(
                    item,
                    moduleId,
                    selectedCategoryId,
                    selectedContextId,
                    traitFilters: selectedTraitFilters,
                    searchQuery: searchQuery,
                  ),
                )
                .toList(growable: false);
            final canUseSqlBuiltIns = isEatModule && eatLibraryStore != null;
            final activeCollectionId = isWearModule
                ? selectedWearCollectionId
                : selectedCollectionId;
            final activeCollectionOptionIds = isWearModule
                ? selectedWearCollectionOptionIds
                : selectedCollectionOptionIds;
            final nextBuiltInFilterCacheKey = _managerBuiltInFilterCacheKey(
              moduleId: moduleId,
              categoryId: selectedCategoryId,
              contextId: selectedContextId,
              searchQuery: searchQuery,
              traitFilters: selectedTraitFilters,
              selectedCollectionId: activeCollectionId,
              selectedCollectionOptionIds: activeCollectionOptionIds,
            );
            late final List<DailyChoiceOption> allVisibleBuiltIns;
            late final int builtInTotalCount;
            var builtInSqlLoading = false;
            if (!builtInExpanded) {
              allVisibleBuiltIns = const <DailyChoiceOption>[];
              builtInTotalCount = 0;
            } else if (canUseSqlBuiltIns) {
              final activeSqlMatchesCurrentFilter =
                  builtInSqlActiveKey == nextBuiltInFilterCacheKey;
              final loadedCount = activeSqlMatchesCurrentFilter
                  ? builtInSqlOptions.length
                  : 0;
              final knownTotal = activeSqlMatchesCurrentFilter
                  ? builtInSqlTotal
                  : 0;
              final nextPageOffset = loadedCount == 0 ? 0 : loadedCount;
              final nextPageLimit = _managerBuiltInPageSize(isEatModule);
              final nextPageSqlKey = _managerBuiltInSqlQueryKey(
                cacheKey: nextBuiltInFilterCacheKey,
                offset: nextPageOffset,
                limit: nextPageLimit,
              );
              final needsInitialPage =
                  loadedCount == 0 &&
                  builtInSqlFailedKey != nextPageSqlKey &&
                  !builtInSqlLoadingKey.startsWith(
                    '$nextBuiltInFilterCacheKey\u0001',
                  );
              final needsNextPage =
                  activeSqlMatchesCurrentFilter &&
                  knownTotal > loadedCount &&
                  builtInVisibleLimit > loadedCount &&
                  builtInSqlFailedKey != nextPageSqlKey &&
                  !builtInSqlLoadingKey.startsWith(
                    '$nextBuiltInFilterCacheKey\u0001',
                  );
              if (needsInitialPage || needsNextPage) {
                requestBuiltInSqlPage(
                  filterKey: nextBuiltInFilterCacheKey,
                  key: nextPageSqlKey,
                  query: _managerEatBuiltInLibraryQuery(
                    categoryId: selectedCategoryId,
                    contextId: selectedContextId,
                    searchQuery: searchQuery,
                    traitFilters: selectedTraitFilters,
                    selectedCollectionOptionIds: selectedCollectionOptionIds,
                    limit: nextPageLimit,
                    offset: nextPageOffset,
                  ),
                );
              }
              builtInSqlLoading = builtInSqlLoadingKey.startsWith(
                '$nextBuiltInFilterCacheKey\u0001',
              );
              allVisibleBuiltIns = activeSqlMatchesCurrentFilter
                  ? builtInSqlOptions
                  : const <DailyChoiceOption>[];
              builtInTotalCount = activeSqlMatchesCurrentFilter
                  ? builtInSqlTotal
                  : 0;
            } else {
              if (nextBuiltInFilterCacheKey != builtInFilterCacheKey) {
                builtInFilterCache = builtInOptions
                    .where(matchesCollection)
                    .where(
                      (item) => _matchesManagerFilters(
                        adjustedById[item.id] ?? item,
                        moduleId,
                        selectedCategoryId,
                        selectedContextId,
                        traitFilters: selectedTraitFilters,
                        searchQuery: searchQuery,
                      ),
                    )
                    .toList(growable: false);
                builtInFilterCacheKey = nextBuiltInFilterCacheKey;
              }
              allVisibleBuiltIns = builtInFilterCache;
              builtInTotalCount = allVisibleBuiltIns.length;
            }
            final visibleBuiltIns = canUseSqlBuiltIns
                ? allVisibleBuiltIns
                : allVisibleBuiltIns
                      .take(builtInVisibleLimit)
                      .toList(growable: false);
            final hidden = localState.hiddenBuiltInIds;
            final theme = Theme.of(context);
            final activeFilterCount =
                (searchQuery.trim().isNotEmpty ? 1 : 0) +
                (selectedCategoryId == 'all' ? 0 : 1) +
                ((selectedContextId == null || selectedContextId == 'all')
                    ? 0
                    : 1) +
                selectedTraitFilters.values
                    .where((value) => value != 'all')
                    .length;

            bool actionBusy(String actionId, DailyChoiceOption option) {
              return managerBusyActionKeys.contains(
                _managerActionKey(actionId, option.id),
              );
            }

            bool itemBusy(DailyChoiceOption option) {
              return _managerDetailActionIds.any(
                (actionId) => actionBusy(actionId, option),
              );
            }

            String? itemBusyMessage(DailyChoiceOption option) {
              for (final actionId in _managerDetailActionIds) {
                if (actionBusy(actionId, option)) {
                  return _managerActionLoadingText(i18n, actionId);
                }
              }
              return null;
            }

            Future<T?> runBuiltInItemAction<T>({
              required DailyChoiceOption option,
              required String actionId,
              required Future<T?> Function() action,
            }) async {
              final key = _managerActionKey(actionId, option.id);
              if (managerBusyActionKeys.contains(key)) {
                return null;
              }
              setSheetState(() {
                managerBusyActionKeys.add(key);
                managerActionErrorByOptionId.remove(option.id);
              });
              try {
                return await action();
              } catch (error) {
                if (!managerSheetClosed) {
                  setSheetState(() {
                    managerActionErrorByOptionId[option.id] =
                        _managerActionErrorText(i18n, actionId, error);
                  });
                }
                return null;
              } finally {
                if (!managerSheetClosed) {
                  setSheetState(() {
                    managerBusyActionKeys.remove(key);
                  });
                }
              }
            }

            Future<void> openEditor([DailyChoiceOption? option]) async {
              final editorCategories = filterCategories
                  .where((item) => item.id != 'all')
                  .toList(growable: false);
              final editorContexts = filterContexts
                  .where((item) => item.id != 'all')
                  .toList(growable: false);
              final editorInitialCategoryId = _resolveManagerEditorCategoryId(
                categories: editorCategories,
                option: option,
                selectedCategoryId: selectedCategoryId,
              );
              final editorInitialContextId = _resolveManagerEditorContextId(
                contexts: editorContexts,
                option: option,
                selectedContextId: selectedContextId,
              );
              final editorResult = await showDailyChoiceEditorSheet(
                context: context,
                i18n: i18n,
                accent: accent,
                moduleId: moduleId,
                categories: editorCategories,
                initialCategoryId: editorInitialCategoryId,
                contexts: editorContexts,
                initialContextId: editorInitialContextId,
                contextLabelZh: contextLabelZh,
                contextLabelEn: contextLabelEn,
                option: option,
                eatCollections: isEatModule
                    ? localState.eatCollections
                    : const <DailyChoiceEatCollection>[],
                initialEatCollectionIds: isEatModule
                    ? _managerInitialEatCollectionIds(
                        collections: localState.eatCollections,
                        option: option,
                        selectedCollection: selectedCollection,
                        defaultFavoriteWhenEmpty: option == null,
                      )
                    : const <String>{},
                wearCollections: isWearModule
                    ? userWearCollections
                    : const <DailyChoiceWearCollection>[],
                initialWearCollectionIds: isWearModule
                    ? _managerInitialWearCollectionIds(
                        collections: userWearCollections,
                        option: option,
                        selectedCollection: selectedWearCollection,
                        defaultFavoriteWhenEmpty: option == null,
                      )
                    : const <String>{},
              );
              if (editorResult == null) {
                return;
              }
              final result = editorResult.option;
              var nextState = localState.upsertCustom(result);
              if (isEatModule) {
                nextState = nextState.setOptionEatCollections(
                  optionId: result.id,
                  collectionIds: editorResult.eatCollectionIds,
                );
              }
              if (isWearModule) {
                nextState = nextState.setOptionWearCollections(
                  optionId: result.id,
                  collectionIds: editorResult.wearCollectionIds,
                );
              }
              await publishWithProcessing(
                nextState,
                pickUiText(i18n, zh: '正在保存修改...', en: 'Saving changes...'),
              );
            }

            Future<void> inspectBuiltInOption(DailyChoiceOption option) async {
              if (onInspectOption == null) {
                return;
              }
              await runBuiltInItemAction<bool>(
                option: option,
                actionId: _managerActionInspect,
                action: () async {
                  await onInspectOption(option);
                  return true;
                },
              );
            }

            Future<void> openAdjustmentEditor(DailyChoiceOption option) async {
              if (onAdjustBuiltInOption == null) {
                return;
              }
              final result = await runBuiltInItemAction<DailyChoiceOption>(
                option: option,
                actionId: _managerActionAdjust,
                action: () => onAdjustBuiltInOption(option),
              );
              if (result == null) {
                return;
              }
              await publishWithProcessing(
                localState.upsertAdjustedBuiltIn(result),
                pickUiText(i18n, zh: '正在保存个人调整...', en: 'Saving adjustment...'),
              );
            }

            Future<void> saveBuiltInAsCustom(DailyChoiceOption option) async {
              if (onSaveBuiltInAsCustom == null) {
                return;
              }
              final editorResult =
                  await runBuiltInItemAction<DailyChoiceEditorResult>(
                    option: option,
                    actionId: _managerActionSaveAs,
                    action: () => onSaveBuiltInAsCustom(
                      option,
                      eatCollections: isEatModule
                          ? localState.eatCollections
                          : const <DailyChoiceEatCollection>[],
                      initialEatCollectionIds: isEatModule
                          ? _managerInitialEatCollectionIds(
                              collections: localState.eatCollections,
                              option: option,
                              selectedCollection: selectedCollection,
                              defaultFavoriteWhenEmpty: true,
                            )
                          : const <String>{},
                      wearCollections: isWearModule
                          ? userWearCollections
                          : const <DailyChoiceWearCollection>[],
                      initialWearCollectionIds: isWearModule
                          ? _managerInitialWearCollectionIds(
                              collections: userWearCollections,
                              option: option,
                              selectedCollection: selectedWearCollection,
                              defaultFavoriteWhenEmpty: true,
                            )
                          : const <String>{},
                    ),
                  );
              if (editorResult == null) {
                return;
              }
              final result = editorResult.option;
              var nextState = localState.upsertCustom(result);
              if (isEatModule) {
                nextState = nextState.setOptionEatCollections(
                  optionId: result.id,
                  collectionIds: editorResult.eatCollectionIds,
                );
              }
              if (isWearModule) {
                nextState = nextState.setOptionWearCollections(
                  optionId: result.id,
                  collectionIds: editorResult.wearCollectionIds,
                );
              }
              await publishWithProcessing(
                nextState,
                pickUiText(i18n, zh: '正在保存副本...', en: 'Saving copy...'),
              );
            }

            Future<void> addOptionToCollections({
              required String optionId,
              required Set<String> collectionIds,
            }) async {
              if (collectionIds.isEmpty) {
                return;
              }
              var nextState = localState;
              for (final collectionId in collectionIds) {
                nextState = nextState.addOptionToEatCollection(
                  collectionId: collectionId,
                  optionId: optionId,
                );
              }
              await publishWithProcessing(
                nextState,
                pickUiText(i18n, zh: '正在加入食谱集...', en: 'Adding to sets...'),
              );
            }

            Future<void> addOptionToWearCollections({
              required String optionId,
              required Set<String> collectionIds,
            }) async {
              if (collectionIds.isEmpty) {
                return;
              }
              var nextState = localState;
              for (final collectionId in collectionIds) {
                nextState = nextState.addOptionToWearCollection(
                  collectionId: collectionId,
                  optionId: optionId,
                );
              }
              await publishWithProcessing(
                nextState,
                pickUiText(i18n, zh: '正在加入衣橱...', en: 'Adding to wardrobe...'),
              );
            }

            Future<void> toggleBuiltInHidden({
              required DailyChoiceOption option,
              required bool isHidden,
            }) async {
              if (isHidden) {
                await publishWithProcessing(
                  localState.restoreBuiltIn(option.id),
                  pickUiText(
                    i18n,
                    zh: isWearModule ? '正在恢复搭配...' : '正在恢复菜谱...',
                    en: isWearModule
                        ? 'Restoring outfit...'
                        : 'Restoring recipe...',
                  ),
                );
                return;
              }
              final confirmed = await _confirmHideBuiltInRecipe(
                context: context,
                i18n: i18n,
                option: option,
                isWearModule: isWearModule,
              );
              if (confirmed != true) {
                return;
              }
              await publishWithProcessing(
                localState.hideBuiltIn(option.id),
                pickUiText(
                  i18n,
                  zh: '正在加入不喜欢...',
                  en: isWearModule ? 'Hiding outfit...' : 'Hiding recipe...',
                ),
              );
            }

            void createCollection() {
              final title = collectionNameDraft.trim();
              if (title.isEmpty) {
                return;
              }
              final collection = DailyChoiceEatCollection(
                id: 'eat_collection_${DateTime.now().microsecondsSinceEpoch}',
                titleZh: title,
                titleEn: title,
              );
              collectionNameDraft = '';
              collectionInputVersion += 1;
              selectedCollectionId = collection.id;
              resetBuiltInPaging();
              publish(localState.upsertEatCollection(collection));
            }

            void createWearCollection() {
              final title = wearCollectionNameDraft.trim();
              if (title.isEmpty) {
                return;
              }
              final collection = DailyChoiceWearCollection(
                id: 'wear_collection_${DateTime.now().microsecondsSinceEpoch}',
                titleZh: title,
                titleEn: title,
              );
              wearCollectionNameDraft = '';
              wearCollectionInputVersion += 1;
              selectedWearCollectionId = collection.id;
              resetBuiltInPaging();
              publish(localState.upsertWearCollection(collection));
            }

            void showManagerMessage({required String zh, required String en}) {
              if (managerSheetClosed) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(pickUiText(i18n, zh: zh, en: en)),
                ),
              );
            }

            Future<void> renameSelectedCollection() async {
              final collection = localState.eatCollectionById(
                selectedCollectionId,
              );
              if (collection == null ||
                  collection.id == dailyChoiceFavoriteEatCollectionId) {
                return;
              }
              final title = await _promptEatCollectionName(
                context: context,
                i18n: i18n,
                accent: accent,
                initialTitle: collection.title(i18n),
              );
              if (title == null || title.trim().isEmpty) {
                return;
              }
              await publishWithProcessing(
                localState.upsertEatCollection(
                  collection.copyWith(
                    titleZh: title.trim(),
                    titleEn: title.trim(),
                  ),
                ),
                pickUiText(
                  i18n,
                  zh: '正在重命名食谱集...',
                  en: 'Renaming recipe set...',
                ),
              );
            }

            Future<void> deleteSelectedCollection() async {
              final collection = localState.eatCollectionById(
                selectedCollectionId,
              );
              if (collection == null ||
                  collection.id == dailyChoiceFavoriteEatCollectionId) {
                return;
              }
              final confirmed = await _confirmDeleteEatCollection(
                context: context,
                i18n: i18n,
                collection: collection,
              );
              if (confirmed != true) {
                return;
              }
              selectedCollectionId = 'all';
              resetBuiltInPaging();
              await publishWithProcessing(
                localState.deleteEatCollection(collection.id),
                pickUiText(
                  i18n,
                  zh: '正在删除食谱集...',
                  en: 'Deleting recipe set...',
                ),
              );
            }

            Future<void> renameSelectedWearCollection() async {
              final collection = localState.wearCollectionById(
                selectedWearCollectionId,
              );
              if (collection == null ||
                  isProtectedWearCollectionId(collection.id)) {
                return;
              }
              final title = await _promptWearCollectionName(
                context: context,
                i18n: i18n,
                accent: accent,
                initialTitle: collection.title(i18n),
              );
              if (title == null || title.trim().isEmpty) {
                return;
              }
              await publishWithProcessing(
                localState.upsertWearCollection(
                  collection.copyWith(
                    titleZh: title.trim(),
                    titleEn: title.trim(),
                  ),
                ),
                pickUiText(i18n, zh: '正在重命名衣橱...', en: 'Renaming wardrobe...'),
              );
            }

            Future<void> deleteSelectedWearCollection() async {
              final collection = localState.wearCollectionById(
                selectedWearCollectionId,
              );
              if (collection == null ||
                  isProtectedWearCollectionId(collection.id)) {
                return;
              }
              final confirmed = await _confirmDeleteWearCollection(
                context: context,
                i18n: i18n,
                collection: collection,
              );
              if (confirmed != true) {
                return;
              }
              selectedWearCollectionId = 'all';
              resetBuiltInPaging();
              await publishWithProcessing(
                localState.deleteWearCollection(collection.id),
                pickUiText(i18n, zh: '正在删除衣橱...', en: 'Deleting wardrobe...'),
              );
            }

            Future<void> exportSelectedCollection() async {
              final collection = localState.eatCollectionById(
                selectedCollectionId,
              );
              if (collection == null) {
                showManagerMessage(
                  zh: '请先选择一个个人食谱集。',
                  en: 'Choose a personal recipe set first.',
                );
                return;
              }
              try {
                final payload = _buildEatCollectionExportPackage(
                  state: localState,
                  collection: collection,
                );
                final encoded = const JsonEncoder.withIndent(
                  '  ',
                ).convert(payload);
                final fileName =
                    '${_safeEatCollectionExportFileName(collection.title(i18n))}.daily-choice-recipes.json';
                final path = await FilePicker.platform.saveFile(
                  dialogTitle: pickUiText(
                    i18n,
                    zh: '导出食谱集',
                    en: 'Export recipe set',
                  ),
                  fileName: fileName,
                  type: FileType.custom,
                  allowedExtensions: const <String>['json'],
                  bytes: Uint8List.fromList(utf8.encode(encoded)),
                  lockParentWindow: true,
                );
                if (path == null) {
                  return;
                }
                showManagerMessage(zh: '食谱集已导出。', en: 'Recipe set exported.');
              } catch (error) {
                showManagerMessage(
                  zh: '导出失败：$error',
                  en: 'Export failed: $error',
                );
              }
            }

            Future<void> importCollections() async {
              try {
                final result = await FilePicker.platform.pickFiles(
                  dialogTitle: pickUiText(
                    i18n,
                    zh: '导入食谱集',
                    en: 'Import recipe set',
                  ),
                  type: FileType.custom,
                  allowedExtensions: const <String>['json'],
                  withData: true,
                  lockParentWindow: true,
                );
                if (result == null || result.files.isEmpty) {
                  return;
                }
                final bytes = result.files.single.bytes;
                if (bytes == null || bytes.isEmpty) {
                  throw const FormatException(
                    'Selected recipe set file could not be read.',
                  );
                }
                final decoded = jsonDecode(utf8.decode(bytes));
                if (decoded is! Map) {
                  throw const FormatException('Invalid recipe set package.');
                }
                final imported = _importEatCollectionExportPackage(
                  state: localState,
                  payload: decoded.cast<String, Object?>(),
                );
                selectedCollectionId = imported.selectedCollectionId;
                resetBuiltInPaging();
                await publishWithProcessing(
                  imported.state,
                  pickUiText(
                    i18n,
                    zh: '正在导入食谱集...',
                    en: 'Importing recipe set...',
                  ),
                );
                showManagerMessage(
                  zh: '已导入 ${imported.collectionCount} 个食谱集。',
                  en: '${imported.collectionCount} recipe set(s) imported.',
                );
              } catch (error) {
                showManagerMessage(
                  zh: '导入失败：$error',
                  en: 'Import failed: $error',
                );
              }
            }

            Future<void> exportSelectedWearCollection() async {
              final collection = localState.wearCollectionById(
                selectedWearCollectionId,
              );
              if (collection == null) {
                showManagerMessage(
                  zh: '请先选择一个衣橱。',
                  en: 'Choose a wardrobe first.',
                );
                return;
              }
              try {
                final payload = _buildWearCollectionExportPackage(
                  state: localState,
                  collection: collection,
                );
                final encoded = const JsonEncoder.withIndent(
                  '  ',
                ).convert(payload);
                final fileName =
                    '${_safeWearCollectionExportFileName(collection.title(i18n))}.daily-choice-wardrobe.json';
                final path = await FilePicker.platform.saveFile(
                  dialogTitle: pickUiText(
                    i18n,
                    zh: '导出衣橱',
                    en: 'Export wardrobe',
                  ),
                  fileName: fileName,
                  type: FileType.custom,
                  allowedExtensions: const <String>['json'],
                  bytes: Uint8List.fromList(utf8.encode(encoded)),
                  lockParentWindow: true,
                );
                if (path == null) {
                  return;
                }
                showManagerMessage(zh: '衣橱已导出。', en: 'Wardrobe exported.');
              } catch (error) {
                showManagerMessage(
                  zh: '导出失败：$error',
                  en: 'Export failed: $error',
                );
              }
            }

            Future<void> importWearCollections() async {
              try {
                final result = await FilePicker.platform.pickFiles(
                  dialogTitle: pickUiText(
                    i18n,
                    zh: '导入衣橱',
                    en: 'Import wardrobe',
                  ),
                  type: FileType.custom,
                  allowedExtensions: const <String>['json'],
                  withData: true,
                  lockParentWindow: true,
                );
                if (result == null || result.files.isEmpty) {
                  return;
                }
                final bytes = result.files.single.bytes;
                if (bytes == null || bytes.isEmpty) {
                  throw const FormatException(
                    'Selected wardrobe file could not be read.',
                  );
                }
                final decoded = jsonDecode(utf8.decode(bytes));
                if (decoded is! Map) {
                  throw const FormatException('Invalid wardrobe package.');
                }
                final imported = _importWearCollectionExportPackage(
                  state: localState,
                  payload: decoded.cast<String, Object?>(),
                );
                selectedWearCollectionId = imported.selectedCollectionId;
                resetBuiltInPaging();
                await publishWithProcessing(
                  imported.state,
                  pickUiText(
                    i18n,
                    zh: '正在导入衣橱...',
                    en: 'Importing wardrobe...',
                  ),
                );
                showManagerMessage(
                  zh: '已导入 ${imported.collectionCount} 个衣橱。',
                  en: '${imported.collectionCount} wardrobe(s) imported.',
                );
              } catch (error) {
                showManagerMessage(
                  zh: '导入失败：$error',
                  en: 'Import failed: $error',
                );
              }
            }

            bool maybeAutoLoadBuiltInsFromMetrics(ScrollMetrics metrics) {
              if (!builtInExpanded ||
                  builtInSqlLoading ||
                  builtInTotalCount <= visibleBuiltIns.length) {
                return false;
              }
              if (metrics.axis != Axis.vertical || metrics.extentAfter > 420) {
                return false;
              }
              final key =
                  '$nextBuiltInFilterCacheKey\u0001${visibleBuiltIns.length}\u0001$builtInTotalCount';
              if (builtInAutoLoadKey == key) {
                return false;
              }
              setSheetState(() {
                builtInAutoLoadKey = key;
                builtInVisibleLimit += _managerBuiltInPageSize(isEatModule);
              });
              return false;
            }

            bool maybeAutoLoadBuiltIns(ScrollNotification notification) {
              return maybeAutoLoadBuiltInsFromMetrics(notification.metrics);
            }

            void scheduleBuiltInAutoLoadCheck(
              ScrollController scrollController,
            ) {
              if (!builtInExpanded ||
                  builtInSqlLoading ||
                  builtInTotalCount <= visibleBuiltIns.length) {
                return;
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (managerSheetClosed || !scrollController.hasClients) {
                  return;
                }
                maybeAutoLoadBuiltInsFromMetrics(scrollController.position);
              });
            }

            return SafeArea(
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.82,
                minChildSize: 0.48,
                maxChildSize: 0.94,
                builder: (context, controller) {
                  scheduleBuiltInAutoLoadCheck(controller);
                  return Stack(
                    children: <Widget>[
                      NotificationListener<ScrollNotification>(
                        onNotification: maybeAutoLoadBuiltIns,
                        child: ListView(
                          controller: controller,
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 88),
                          children: <Widget>[
                            Text(
                              pickUiText(
                                i18n,
                                zh: '自定义管理',
                                en: 'Custom manager',
                              ),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _managerDescription(
                                i18n,
                                isEatModule: isEatModule,
                                isWearModule: isWearModule,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (isEatModule) ...<Widget>[
                              ToolboxSurfaceCard(
                                padding: const EdgeInsets.all(12),
                                borderColor: accent.withValues(alpha: 0.14),
                                shadowOpacity: 0.02,
                                child: _ManagerSearchField(
                                  i18n: i18n,
                                  initialText: searchDraft,
                                  labelZh: '搜索菜品名称',
                                  labelEn: 'Search recipe name',
                                  hintZh: '按菜名、简介关键词快速筛选',
                                  hintEn: 'Search by recipe title or summary',
                                  onDraftChanged: (value) {
                                    searchDraft = value;
                                  },
                                  onCommitted: commitSearchQuery,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _ManagerExpandableSection(
                                title: pickUiText(
                                  i18n,
                                  zh: '我的食谱集',
                                  en: 'My recipe sets',
                                ),
                                subtitle: selectedCollection == null
                                    ? pickUiText(
                                        i18n,
                                        zh: '可把常做菜、减脂餐、待尝试等集合成独立随机池。',
                                        en: 'Group favorites, weekday meals, or recipes to try into separate pools.',
                                      )
                                    : pickUiText(
                                        i18n,
                                        zh: '当前只看「${selectedCollection.title(i18n)}」。',
                                        en: 'Showing "${selectedCollection.title(i18n)}" only.',
                                      ),
                                accent: accent,
                                expanded: collectionsExpanded,
                                countLabel:
                                    '${localState.eatCollections.length}',
                                onToggle: () {
                                  setSheetState(() {
                                    collectionsExpanded = !collectionsExpanded;
                                  });
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    TextFormField(
                                      key: ValueKey<String>(
                                        'eat-collection-input-$collectionInputVersion',
                                      ),
                                      initialValue: collectionNameDraft,
                                      onChanged: (value) {
                                        collectionNameDraft = value;
                                      },
                                      onFieldSubmitted: (_) =>
                                          createCollection(),
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(
                                          Icons.bookmark_add_rounded,
                                        ),
                                        labelText: pickUiText(
                                          i18n,
                                          zh: '新建食谱集',
                                          en: 'New recipe set',
                                        ),
                                        hintText: pickUiText(
                                          i18n,
                                          zh: '例如：一周晚餐、低油清淡、想试试',
                                          en: 'For example: Weeknight dinners',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: FilledButton.icon(
                                        onPressed: createCollection,
                                        icon: const Icon(Icons.add_rounded),
                                        label: Text(
                                          pickUiText(
                                            i18n,
                                            zh: '创建食谱集',
                                            en: 'Create set',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            key: ValueKey<String>(
                                              'eat-collection-scope-$selectedCollectionId',
                                            ),
                                            initialValue: selectedCollectionId,
                                            isExpanded: true,
                                            decoration: InputDecoration(
                                              prefixIcon: const Icon(
                                                Icons.filter_list_rounded,
                                              ),
                                              labelText: pickUiText(
                                                i18n,
                                                zh: '当前随机范围',
                                                en: 'Random pool',
                                              ),
                                            ),
                                            items: <DropdownMenuItem<String>>[
                                              DropdownMenuItem<String>(
                                                value: 'all',
                                                child: Text(
                                                  pickUiText(
                                                    i18n,
                                                    zh: '内置菜谱',
                                                    en: 'Built-in recipes',
                                                  ),
                                                ),
                                              ),
                                              ...localState.eatCollections.map(
                                                (
                                                  collection,
                                                ) => DropdownMenuItem<String>(
                                                  value: collection.id,
                                                  child: Text(
                                                    '${collection.title(i18n)} · ${collection.optionIds.length}',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              if (value == null) {
                                                return;
                                              }
                                              setSheetState(() {
                                                selectedCollectionId = value;
                                                resetBuiltInPaging();
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Tooltip(
                                          message: pickUiText(
                                            i18n,
                                            zh: '重命名食谱集',
                                            en: 'Rename set',
                                          ),
                                          child: IconButton.filledTonal(
                                            onPressed:
                                                selectedCollection == null ||
                                                    selectedCollection.id ==
                                                        dailyChoiceFavoriteEatCollectionId
                                                ? null
                                                : renameSelectedCollection,
                                            icon: const Icon(
                                              Icons.drive_file_rename_outline,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Tooltip(
                                          message: pickUiText(
                                            i18n,
                                            zh: '删除食谱集',
                                            en: 'Delete set',
                                          ),
                                          child: IconButton.filledTonal(
                                            onPressed:
                                                selectedCollection == null ||
                                                    selectedCollection.id ==
                                                        dailyChoiceFavoriteEatCollectionId
                                                ? null
                                                : deleteSelectedCollection,
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: <Widget>[
                                        OutlinedButton.icon(
                                          onPressed: selectedCollection == null
                                              ? null
                                              : exportSelectedCollection,
                                          icon: const Icon(
                                            Icons.ios_share_rounded,
                                          ),
                                          label: Text(
                                            pickUiText(
                                              i18n,
                                              zh: '导出当前',
                                              en: 'Export current',
                                            ),
                                          ),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: importCollections,
                                          icon: const Icon(
                                            Icons.file_upload_outlined,
                                          ),
                                          label: Text(
                                            pickUiText(
                                              i18n,
                                              zh: '导入分享包',
                                              en: 'Import package',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (isWearModule) ...<Widget>[
                              ToolboxSurfaceCard(
                                padding: const EdgeInsets.all(12),
                                borderColor: accent.withValues(alpha: 0.14),
                                shadowOpacity: 0.02,
                                child: _ManagerSearchField(
                                  i18n: i18n,
                                  initialText: searchDraft,
                                  labelZh: '搜索搭配或单品',
                                  labelEn: 'Search outfit or piece',
                                  hintZh: '按搭配名称、真实单品、场景关键词筛选',
                                  hintEn:
                                      'Search by outfit, piece, or scene keyword',
                                  onDraftChanged: (value) {
                                    searchDraft = value;
                                  },
                                  onCommitted: commitSearchQuery,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _ManagerExpandableSection(
                                title: pickUiText(
                                  i18n,
                                  zh: '衣柜集合',
                                  en: 'Wardrobes',
                                ),
                                subtitle: selectedWearCollection == null
                                    ? pickUiText(
                                        i18n,
                                        zh: '把真实会穿的通勤、周末、运动、雨天组合整理成独立衣柜。内置衣柜只做参考，你的衣柜才是日常随机的核心。',
                                        en: 'Group real commute, weekend, active, or rainy-day outfits into wardrobes. Built-ins are references; your wardrobe is the daily core.',
                                      )
                                    : pickUiText(
                                        i18n,
                                        zh: '当前只看「${selectedWearCollection.title(i18n)}」。',
                                        en: 'Showing "${selectedWearCollection.title(i18n)}" only.',
                                      ),
                                accent: accent,
                                expanded: collectionsExpanded,
                                countLabel:
                                    '${localState.wearCollections.length}',
                                onToggle: () {
                                  setSheetState(() {
                                    collectionsExpanded = !collectionsExpanded;
                                  });
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    TextFormField(
                                      key: ValueKey<String>(
                                        'wear-collection-input-$wearCollectionInputVersion',
                                      ),
                                      initialValue: wearCollectionNameDraft,
                                      onChanged: (value) {
                                        wearCollectionNameDraft = value;
                                      },
                                      onFieldSubmitted: (_) =>
                                          createWearCollection(),
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(
                                          Icons.checkroom_rounded,
                                        ),
                                        labelText: pickUiText(
                                          i18n,
                                          zh: '新建我的衣柜',
                                          en: 'New wardrobe',
                                        ),
                                        hintText: pickUiText(
                                          i18n,
                                          zh: '例如：日常通勤、周末休闲、运动穿搭',
                                          en: 'For example: Daily commute, Weekend casual',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: FilledButton.icon(
                                        onPressed: createWearCollection,
                                        icon: const Icon(Icons.add_rounded),
                                        label: Text(
                                          pickUiText(
                                            i18n,
                                            zh: '创建我的衣柜',
                                            en: 'Create wardrobe',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            key: ValueKey<String>(
                                              'wear-collection-scope-$selectedWearCollectionId',
                                            ),
                                            initialValue:
                                                selectedWearCollectionId,
                                            isExpanded: true,
                                            decoration: InputDecoration(
                                              prefixIcon: const Icon(
                                                Icons.filter_list_rounded,
                                              ),
                                              labelText: pickUiText(
                                                i18n,
                                                zh: '当前随机范围',
                                                en: 'Random pool',
                                              ),
                                            ),
                                            items: <DropdownMenuItem<String>>[
                                              DropdownMenuItem<String>(
                                                value: 'all',
                                                child: Text(
                                                  pickUiText(
                                                    i18n,
                                                    zh: '全部衣柜',
                                                    en: 'All wardrobes',
                                                  ),
                                                ),
                                              ),
                                              ...localState.wearCollections.map(
                                                (
                                                  collection,
                                                ) => DropdownMenuItem<String>(
                                                  value: collection.id,
                                                  child: Text(
                                                    '${collection.title(i18n)} · ${collection.optionIds.length}',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              if (value == null) {
                                                return;
                                              }
                                              setSheetState(() {
                                                selectedWearCollectionId =
                                                    value;
                                                resetBuiltInPaging();
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Tooltip(
                                          message: pickUiText(
                                            i18n,
                                            zh: '重命名衣橱',
                                            en: 'Rename wardrobe',
                                          ),
                                          child: IconButton.filledTonal(
                                            onPressed:
                                                selectedWearCollection ==
                                                        null ||
                                                    isProtectedWearCollectionId(
                                                      selectedWearCollection.id,
                                                    )
                                                ? null
                                                : renameSelectedWearCollection,
                                            icon: const Icon(
                                              Icons.drive_file_rename_outline,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Tooltip(
                                          message: pickUiText(
                                            i18n,
                                            zh: '删除衣橱',
                                            en: 'Delete wardrobe',
                                          ),
                                          child: IconButton.filledTonal(
                                            onPressed:
                                                selectedWearCollection ==
                                                        null ||
                                                    isProtectedWearCollectionId(
                                                      selectedWearCollection.id,
                                                    )
                                                ? null
                                                : deleteSelectedWearCollection,
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: <Widget>[
                                        OutlinedButton.icon(
                                          onPressed:
                                              selectedWearCollection == null
                                              ? null
                                              : exportSelectedWearCollection,
                                          icon: const Icon(
                                            Icons.ios_share_rounded,
                                          ),
                                          label: Text(
                                            pickUiText(
                                              i18n,
                                              zh: '导出当前',
                                              en: 'Export current',
                                            ),
                                          ),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: importWearCollections,
                                          icon: const Icon(
                                            Icons.file_upload_outlined,
                                          ),
                                          label: Text(
                                            pickUiText(
                                              i18n,
                                              zh: '导入分享包',
                                              en: 'Import package',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            _ManagerExpandableSection(
                              title: pickUiText(
                                i18n,
                                zh: '筛选条件',
                                en: 'Filters',
                              ),
                              subtitle: activeFilterCount <= 0
                                  ? pickUiText(
                                      i18n,
                                      zh: isWearModule
                                          ? '当前显示全部范围。可以按性别参考、年龄阶段、风格和版型逐步缩小。'
                                          : '当前显示全部范围，可折叠收起。',
                                      en: 'Showing the full range for now.',
                                    )
                                  : pickUiText(
                                      i18n,
                                      zh: '已启用 $activeFilterCount 项筛选。',
                                      en: '$activeFilterCount filters enabled.',
                                    ),
                              accent: accent,
                              expanded: filtersExpanded,
                              countLabel: activeFilterCount <= 0
                                  ? pickUiText(i18n, zh: '默认', en: 'Default')
                                  : pickUiText(
                                      i18n,
                                      zh: '$activeFilterCount 项',
                                      en: '$activeFilterCount active',
                                    ),
                              onToggle: () {
                                setSheetState(() {
                                  filtersExpanded = !filtersExpanded;
                                });
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  DailyChoiceCategorySelector(
                                    i18n: i18n,
                                    title: pickUiText(
                                      i18n,
                                      zh: '只看这个分类',
                                      en: 'Filter by category',
                                    ),
                                    categories: filterCategories,
                                    selectedId: selectedCategoryId,
                                    accent: accent,
                                    compactUnselected: true,
                                    onSelected: (value) {
                                      setSheetState(() {
                                        selectedCategoryId = value;
                                        resetBuiltInPaging();
                                      });
                                    },
                                  ),
                                  if (filterContexts.isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 12),
                                    DailyChoiceCategorySelector(
                                      i18n: i18n,
                                      title: pickUiText(
                                        i18n,
                                        zh: '只看这个$contextLabelZh',
                                        en: 'Filter by $contextLabelEn',
                                      ),
                                      categories: filterContexts,
                                      selectedId:
                                          selectedContextId ??
                                          filterContexts.first.id,
                                      accent: accent,
                                      compactUnselected: true,
                                      onSelected: (value) {
                                        setSheetState(() {
                                          selectedContextId = value;
                                          resetBuiltInPaging();
                                        });
                                      },
                                    ),
                                  ],
                                  if (managerTraitGroups
                                      .isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 12),
                                    for (final group
                                        in managerTraitGroups) ...<Widget>[
                                      _ManagerTraitFilterSection(
                                        i18n: i18n,
                                        accent: accent,
                                        group: group,
                                        selectedId:
                                            selectedTraitFilters[group.id] ??
                                            'all',
                                        onSelected: (value) {
                                          setSheetState(() {
                                            selectedTraitFilters[group.id] =
                                                value;
                                            resetBuiltInPaging();
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () => openEditor(),
                              icon: const Icon(Icons.add_rounded),
                              label: Text(
                                pickUiText(
                                  i18n,
                                  zh: isEatModule
                                      ? '新增个人食谱'
                                      : (isWearModule ? '新建我的衣柜搭配' : '新增'),
                                  en: isEatModule
                                      ? 'Add recipe'
                                      : (isWearModule
                                            ? 'Add wardrobe outfit'
                                            : 'Add'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _ManagerExpandableSection(
                              title: pickUiText(
                                i18n,
                                zh: '我的自定义',
                                en: 'My custom items',
                              ),
                              subtitle: pickUiText(
                                i18n,
                                zh: isWearModule
                                    ? '这些是你基于真实衣柜保存的搭配，可编辑、删除，也会直接参与随机。'
                                    : '完全属于你的新增条目，可直接编辑和删除。',
                                en: isWearModule
                                    ? 'These outfits come from your real wardrobe and can be edited, removed, and used in random picks.'
                                    : 'Your own saved items that can be edited or removed.',
                              ),
                              accent: accent,
                              expanded: customExpanded,
                              countLabel: '${customItems.length}',
                              onToggle: () {
                                setSheetState(() {
                                  customExpanded = !customExpanded;
                                });
                              },
                              child: customItems.isEmpty
                                  ? _ManagerHint(
                                      text: _emptyCustomHint(
                                        i18n,
                                        isEatModule: isEatModule,
                                        isWearModule: isWearModule,
                                      ),
                                    )
                                  : Column(
                                      children: customItems
                                          .map(
                                            (item) => _ManagerTile(
                                              title: item.title(i18n),
                                              subtitle: item.subtitle(i18n),
                                              accent: accent,
                                              leading: Icons.edit_note_rounded,
                                              onTap: onInspectOption == null
                                                  ? null
                                                  : () => onInspectOption(item),
                                              chips: _managerChips(
                                                i18n,
                                                item,
                                                isEatModule: isEatModule,
                                                isWearModule: isWearModule,
                                              ),
                                              actions: <Widget>[
                                                TextButton.icon(
                                                  onPressed: () =>
                                                      openEditor(item),
                                                  icon: const Icon(
                                                    Icons.edit_rounded,
                                                  ),
                                                  label: Text(
                                                    pickUiText(
                                                      i18n,
                                                      zh: '编辑',
                                                      en: 'Edit',
                                                    ),
                                                  ),
                                                ),
                                                if (isEatModule)
                                                  ..._managerCollectionActions(
                                                    context: context,
                                                    i18n: i18n,
                                                    collections: localState
                                                        .eatCollections,
                                                    selectedCollection:
                                                        selectedCollection,
                                                    optionId: item.id,
                                                    onAddMultiple:
                                                        (collectionIds) {
                                                          unawaited(
                                                            addOptionToCollections(
                                                              optionId: item.id,
                                                              collectionIds:
                                                                  collectionIds,
                                                            ),
                                                          );
                                                        },
                                                    onRemove: (collectionId) {
                                                      unawaited(
                                                        publishWithProcessing(
                                                          localState
                                                              .removeOptionFromEatCollection(
                                                                collectionId:
                                                                    collectionId,
                                                                optionId:
                                                                    item.id,
                                                              ),
                                                          pickUiText(
                                                            i18n,
                                                            zh: '正在移出食谱集...',
                                                            en: 'Removing from set...',
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                if (isWearModule)
                                                  ..._managerWearCollectionActions(
                                                    context: context,
                                                    i18n: i18n,
                                                    collections:
                                                        userWearCollections,
                                                    selectedCollection:
                                                        selectedWearCollection,
                                                    optionId: item.id,
                                                    onAddMultiple: (collectionIds) {
                                                      unawaited(
                                                        addOptionToWearCollections(
                                                          optionId: item.id,
                                                          collectionIds:
                                                              collectionIds,
                                                        ),
                                                      );
                                                    },
                                                    onRemove: (collectionId) {
                                                      unawaited(
                                                        publishWithProcessing(
                                                          localState
                                                              .removeOptionFromWearCollection(
                                                                collectionId:
                                                                    collectionId,
                                                                optionId:
                                                                    item.id,
                                                              ),
                                                          pickUiText(
                                                            i18n,
                                                            zh: '正在移出衣橱...',
                                                            en: 'Removing from wardrobe...',
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                TextButton.icon(
                                                  onPressed: () {
                                                    publish(
                                                      localState.deleteCustom(
                                                        item.id,
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons
                                                        .delete_outline_rounded,
                                                  ),
                                                  label: Text(
                                                    pickUiText(
                                                      i18n,
                                                      zh: '删除',
                                                      en: 'Delete',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                          .toList(growable: false),
                                    ),
                            ),
                            if (isEatModule || isWearModule)
                              _ManagerExpandableSection(
                                title: pickUiText(
                                  i18n,
                                  zh: isWearModule ? '我的穿搭调整' : '我的调整',
                                  en: 'My adjustments',
                                ),
                                subtitle: pickUiText(
                                  i18n,
                                  zh: isWearModule
                                      ? '基于内置搭配保存的个人版本，会直接参与随机与筛选。'
                                      : '基于内置菜谱保存的个人口味版本，会直接参与随机与筛选。',
                                  en: isWearModule
                                      ? 'Your personal overrides of built-in outfits.'
                                      : 'Your personal overrides of built-in recipes.',
                                ),
                                accent: accent,
                                expanded: adjustedExpanded,
                                countLabel: '${adjustedItems.length}',
                                onToggle: () {
                                  setSheetState(() {
                                    adjustedExpanded = !adjustedExpanded;
                                  });
                                },
                                child: adjustedItems.isEmpty
                                    ? _ManagerHint(
                                        text: pickUiText(
                                          i18n,
                                          zh: isWearModule
                                              ? '当前筛选下还没有保存过穿搭调整。点开内置搭配即可基于原方案做个人化微调。'
                                              : '当前筛选下还没有保存过个人调整。点开内置菜即可基于原菜谱做个人化微调。',
                                          en: 'No personal adjustments in this filter yet.',
                                        ),
                                      )
                                    : Column(
                                        children: adjustedItems
                                            .map((item) {
                                              final busy = itemBusy(item);
                                              final loadingMessage =
                                                  itemBusyMessage(item);
                                              return _ManagerTile(
                                                title: item.title(i18n),
                                                subtitle: item.subtitle(i18n),
                                                accent: accent,
                                                leading:
                                                    hidden.contains(item.id)
                                                    ? Icons
                                                          .visibility_off_rounded
                                                    : Icons.tune_rounded,
                                                onTap:
                                                    onInspectOption == null ||
                                                        busy
                                                    ? null
                                                    : () =>
                                                          inspectBuiltInOption(
                                                            item,
                                                          ),
                                                statusMessage:
                                                    loadingMessage ??
                                                    managerActionErrorByOptionId[item
                                                        .id],
                                                statusIsLoading:
                                                    loadingMessage != null,
                                                statusIsError:
                                                    loadingMessage == null &&
                                                    managerActionErrorByOptionId
                                                        .containsKey(item.id),
                                                chips: <String>[
                                                  pickUiText(
                                                    i18n,
                                                    zh: '已调整',
                                                    en: 'Adjusted',
                                                  ),
                                                  if (hidden.contains(item.id))
                                                    pickUiText(
                                                      i18n,
                                                      zh: '已隐藏',
                                                      en: 'Hidden',
                                                    ),
                                                  ..._managerChips(
                                                    i18n,
                                                    item,
                                                    isEatModule: isEatModule,
                                                    isWearModule: isWearModule,
                                                  ),
                                                ],
                                                actions: <Widget>[
                                                  if (onAdjustBuiltInOption !=
                                                      null)
                                                    _managerAsyncActionButton(
                                                      i18n: i18n,
                                                      icon: Icons.tune_rounded,
                                                      labelZh: '继续调整',
                                                      labelEn: 'Adjust',
                                                      loading: actionBusy(
                                                        _managerActionAdjust,
                                                        item,
                                                      ),
                                                      enabled: !busy,
                                                      onPressed: () =>
                                                          openAdjustmentEditor(
                                                            item,
                                                          ),
                                                    ),
                                                  if (onSaveBuiltInAsCustom !=
                                                      null)
                                                    _managerAsyncActionButton(
                                                      i18n: i18n,
                                                      icon: Icons.copy_rounded,
                                                      labelZh: '另存',
                                                      labelEn: 'Save as',
                                                      loading: actionBusy(
                                                        _managerActionSaveAs,
                                                        item,
                                                      ),
                                                      enabled: !busy,
                                                      onPressed: () =>
                                                          saveBuiltInAsCustom(
                                                            item,
                                                          ),
                                                    ),
                                                  if (isEatModule)
                                                    ..._managerCollectionActions(
                                                      context: context,
                                                      i18n: i18n,
                                                      collections: localState
                                                          .eatCollections,
                                                      selectedCollection:
                                                          selectedCollection,
                                                      optionId: item.id,
                                                      onAddMultiple: (collectionIds) {
                                                        unawaited(
                                                          addOptionToCollections(
                                                            optionId: item.id,
                                                            collectionIds:
                                                                collectionIds,
                                                          ),
                                                        );
                                                      },
                                                      onRemove: (collectionId) {
                                                        unawaited(
                                                          publishWithProcessing(
                                                            localState
                                                                .removeOptionFromEatCollection(
                                                                  collectionId:
                                                                      collectionId,
                                                                  optionId:
                                                                      item.id,
                                                                ),
                                                            pickUiText(
                                                              i18n,
                                                              zh: '正在移出食谱集...',
                                                              en: 'Removing from set...',
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  if (isWearModule)
                                                    ..._managerWearCollectionActions(
                                                      context: context,
                                                      i18n: i18n,
                                                      collections:
                                                          userWearCollections,
                                                      selectedCollection:
                                                          selectedWearCollection,
                                                      optionId: item.id,
                                                      onAddMultiple: (collectionIds) {
                                                        unawaited(
                                                          addOptionToWearCollections(
                                                            optionId: item.id,
                                                            collectionIds:
                                                                collectionIds,
                                                          ),
                                                        );
                                                      },
                                                      onRemove: (collectionId) {
                                                        unawaited(
                                                          publishWithProcessing(
                                                            localState
                                                                .removeOptionFromWearCollection(
                                                                  collectionId:
                                                                      collectionId,
                                                                  optionId:
                                                                      item.id,
                                                                ),
                                                            pickUiText(
                                                              i18n,
                                                              zh: '正在移出衣橱...',
                                                              en: 'Removing from wardrobe...',
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  TextButton.icon(
                                                    onPressed: busy
                                                        ? null
                                                        : () {
                                                            publish(
                                                              localState
                                                                  .restoreAdjustedBuiltIn(
                                                                    item.id,
                                                                  ),
                                                            );
                                                          },
                                                    icon: const Icon(
                                                      Icons.restart_alt_rounded,
                                                    ),
                                                    label: Text(
                                                      pickUiText(
                                                        i18n,
                                                        zh: isWearModule
                                                            ? '恢复原样'
                                                            : '恢复原味',
                                                        en: 'Restore original',
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            })
                                            .toList(growable: false),
                                      ),
                              ),
                            _ManagerExpandableSection(
                              title: pickUiText(
                                i18n,
                                zh: isWearModule ? '内置参考搭配' : '内置菜谱浏览',
                                en: isWearModule
                                    ? 'Built-in references'
                                    : 'Built-in browser',
                              ),
                              subtitle: _builtInSectionSubtitle(
                                i18n,
                                builtInExpanded: builtInExpanded,
                                total: builtInTotalCount,
                                visible: visibleBuiltIns.length,
                                loading: builtInSqlLoading,
                                errorMessage: builtInSqlError,
                                isWearModule: isWearModule,
                              ),
                              accent: accent,
                              expanded: builtInExpanded,
                              countLabel: builtInExpanded
                                  ? (builtInSqlLoading && builtInTotalCount == 0
                                        ? pickUiText(
                                            i18n,
                                            zh: '加载中',
                                            en: 'Loading',
                                          )
                                        : '$builtInTotalCount')
                                  : pickUiText(i18n, zh: '展开', en: 'Open'),
                              onToggle: () {
                                setSheetState(() {
                                  builtInExpanded = !builtInExpanded;
                                  if (builtInExpanded) {
                                    resetBuiltInPaging();
                                  }
                                });
                              },
                              child:
                                  builtInSqlLoading && visibleBuiltIns.isEmpty
                                  ? _ManagerHint(
                                      text: pickUiText(
                                        i18n,
                                        zh: isWearModule
                                            ? '正在读取内置搭配...'
                                            : '正在读取内置菜谱...',
                                        en: isWearModule
                                            ? 'Loading built-in outfits...'
                                            : 'Loading built-in recipes...',
                                      ),
                                    )
                                  : builtInSqlError != null &&
                                        visibleBuiltIns.isEmpty
                                  ? _ManagerHint(
                                      text: pickUiText(
                                        i18n,
                                        zh: isWearModule
                                            ? '读取内置搭配失败：$builtInSqlError'
                                            : '读取内置菜谱失败：$builtInSqlError',
                                        en: isWearModule
                                            ? 'Failed to load built-in outfits: $builtInSqlError'
                                            : 'Failed to load built-in recipes: $builtInSqlError',
                                      ),
                                    )
                                  : visibleBuiltIns.isEmpty
                                  ? _ManagerHint(
                                      text: _emptyBuiltInHint(
                                        i18n,
                                        isWearModule: isWearModule,
                                      ),
                                    )
                                  : Column(
                                      children: <Widget>[
                                        ...visibleBuiltIns.map((baseItem) {
                                          final displayItem =
                                              adjustedById[baseItem.id] ??
                                              baseItem;
                                          final isHidden = hidden.contains(
                                            baseItem.id,
                                          );
                                          final hasAdjustment = adjustedById
                                              .containsKey(baseItem.id);
                                          final busy = itemBusy(displayItem);
                                          final loadingMessage =
                                              itemBusyMessage(displayItem);
                                          return _ManagerTile(
                                            title: displayItem.title(i18n),
                                            subtitle: isHidden
                                                ? pickUiText(
                                                    i18n,
                                                    zh: isWearModule
                                                        ? '这套搭配当前已加入不喜欢列表。'
                                                        : '这道菜当前已加入不喜欢列表。',
                                                    en: 'This item is hidden right now.',
                                                  )
                                                : displayItem.subtitle(i18n),
                                            accent: accent,
                                            leading: isHidden
                                                ? Icons.visibility_off_rounded
                                                : Icons.dataset_rounded,
                                            onTap:
                                                onInspectOption == null || busy
                                                ? null
                                                : () => inspectBuiltInOption(
                                                    displayItem,
                                                  ),
                                            statusMessage:
                                                loadingMessage ??
                                                managerActionErrorByOptionId[displayItem
                                                    .id],
                                            statusIsLoading:
                                                loadingMessage != null,
                                            statusIsError:
                                                loadingMessage == null &&
                                                managerActionErrorByOptionId
                                                    .containsKey(
                                                      displayItem.id,
                                                    ),
                                            chips: <String>[
                                              if (hasAdjustment)
                                                pickUiText(
                                                  i18n,
                                                  zh: '已调整',
                                                  en: 'Adjusted',
                                                ),
                                              if (isHidden)
                                                pickUiText(
                                                  i18n,
                                                  zh: '已隐藏',
                                                  en: 'Hidden',
                                                ),
                                              ..._managerChips(
                                                i18n,
                                                displayItem,
                                                isEatModule: isEatModule,
                                                isWearModule: isWearModule,
                                              ),
                                            ],
                                            actions: <Widget>[
                                              if (onAdjustBuiltInOption != null)
                                                _managerAsyncActionButton(
                                                  i18n: i18n,
                                                  icon: Icons.tune_rounded,
                                                  labelZh: hasAdjustment
                                                      ? '继续调整'
                                                      : '个人调整',
                                                  labelEn: hasAdjustment
                                                      ? 'Adjust more'
                                                      : 'Adjust',
                                                  loading: actionBusy(
                                                    _managerActionAdjust,
                                                    displayItem,
                                                  ),
                                                  enabled: !busy,
                                                  onPressed: () =>
                                                      openAdjustmentEditor(
                                                        displayItem,
                                                      ),
                                                ),
                                              if (onSaveBuiltInAsCustom != null)
                                                _managerAsyncActionButton(
                                                  i18n: i18n,
                                                  icon: Icons.copy_rounded,
                                                  labelZh: '另存',
                                                  labelEn: 'Save as',
                                                  loading: actionBusy(
                                                    _managerActionSaveAs,
                                                    displayItem,
                                                  ),
                                                  enabled: !busy,
                                                  onPressed: () =>
                                                      saveBuiltInAsCustom(
                                                        displayItem,
                                                      ),
                                                ),
                                              if (isEatModule)
                                                ..._managerCollectionActions(
                                                  context: context,
                                                  i18n: i18n,
                                                  collections:
                                                      localState.eatCollections,
                                                  selectedCollection:
                                                      selectedCollection,
                                                  optionId: baseItem.id,
                                                  onAddMultiple:
                                                      (collectionIds) {
                                                        unawaited(
                                                          addOptionToCollections(
                                                            optionId:
                                                                baseItem.id,
                                                            collectionIds:
                                                                collectionIds,
                                                          ),
                                                        );
                                                      },
                                                  onRemove: (collectionId) {
                                                    unawaited(
                                                      publishWithProcessing(
                                                        localState
                                                            .removeOptionFromEatCollection(
                                                              collectionId:
                                                                  collectionId,
                                                              optionId:
                                                                  baseItem.id,
                                                            ),
                                                        pickUiText(
                                                          i18n,
                                                          zh: '正在移出食谱集...',
                                                          en: 'Removing from set...',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              if (isWearModule)
                                                ..._managerWearCollectionActions(
                                                  context: context,
                                                  i18n: i18n,
                                                  collections:
                                                      userWearCollections,
                                                  selectedCollection:
                                                      selectedWearCollection,
                                                  optionId: baseItem.id,
                                                  onAddMultiple: (collectionIds) {
                                                    unawaited(
                                                      addOptionToWearCollections(
                                                        optionId: baseItem.id,
                                                        collectionIds:
                                                            collectionIds,
                                                      ),
                                                    );
                                                  },
                                                  onRemove: (collectionId) {
                                                    unawaited(
                                                      publishWithProcessing(
                                                        localState
                                                            .removeOptionFromWearCollection(
                                                              collectionId:
                                                                  collectionId,
                                                              optionId:
                                                                  baseItem.id,
                                                            ),
                                                        pickUiText(
                                                          i18n,
                                                          zh: '正在移出衣橱...',
                                                          en: 'Removing from wardrobe...',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              if (hasAdjustment)
                                                TextButton.icon(
                                                  onPressed: busy
                                                      ? null
                                                      : () {
                                                          publish(
                                                            localState
                                                                .restoreAdjustedBuiltIn(
                                                                  baseItem.id,
                                                                ),
                                                          );
                                                        },
                                                  icon: const Icon(
                                                    Icons.restart_alt_rounded,
                                                  ),
                                                  label: Text(
                                                    pickUiText(
                                                      i18n,
                                                      zh: '恢复原味',
                                                      en: 'Restore original',
                                                    ),
                                                  ),
                                                ),
                                              TextButton.icon(
                                                onPressed: busy
                                                    ? null
                                                    : () {
                                                        unawaited(
                                                          toggleBuiltInHidden(
                                                            option: displayItem,
                                                            isHidden: isHidden,
                                                          ),
                                                        );
                                                      },
                                                icon: Icon(
                                                  isHidden
                                                      ? Icons.restore_rounded
                                                      : Icons
                                                            .remove_circle_outline_rounded,
                                                ),
                                                label: Text(
                                                  isHidden
                                                      ? pickUiText(
                                                          i18n,
                                                          zh: '恢复',
                                                          en: 'Restore',
                                                        )
                                                      : pickUiText(
                                                          i18n,
                                                          zh: '不喜欢',
                                                          en: 'Hide',
                                                        ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }),
                                        if (builtInTotalCount >
                                            visibleBuiltIns.length) ...<Widget>[
                                          const SizedBox(height: 10),
                                          _ManagerHint(
                                            text: builtInSqlLoading
                                                ? pickUiText(
                                                    i18n,
                                                    zh: isWearModule
                                                        ? '正在加载更多内置搭配...'
                                                        : '正在加载更多内置菜谱...',
                                                    en: isWearModule
                                                        ? 'Loading more built-in outfits...'
                                                        : 'Loading more built-in recipes...',
                                                  )
                                                : pickUiText(
                                                    i18n,
                                                    zh: '还有 ${builtInTotalCount - visibleBuiltIns.length} 条待加载。',
                                                    en: '${builtInTotalCount - visibleBuiltIns.length} more ${isWearModule ? 'outfits' : 'recipes'} are ready to load.',
                                                  ),
                                          ),
                                        ],
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 12,
                        child: FloatingActionButton.small(
                          heroTag: null,
                          tooltip: pickUiText(
                            i18n,
                            zh: '回到页首',
                            en: 'Back to top',
                          ),
                          backgroundColor: accent,
                          foregroundColor: theme.colorScheme.onPrimary,
                          onPressed: () {
                            if (!controller.hasClients) {
                              return;
                            }
                            controller.animateTo(
                              0,
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOutCubic,
                            );
                          },
                          child: const Icon(Icons.vertical_align_top_rounded),
                        ),
                      ),
                      if (managerProcessingMessage != null)
                        Positioned.fill(
                          child: _ManagerProcessingOverlay(
                            message: managerProcessingMessage!,
                            accent: accent,
                          ),
                        ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  } finally {
    managerSheetClosed = true;
    collectionNameDraft = '';
  }
}

Set<String> _managerInitialEatCollectionIds({
  required List<DailyChoiceEatCollection> collections,
  required DailyChoiceOption? option,
  required DailyChoiceEatCollection? selectedCollection,
  required bool defaultFavoriteWhenEmpty,
}) {
  final ids = <String>{};
  final optionId = option?.id.trim();
  if (optionId != null && optionId.isNotEmpty) {
    for (final collection in collections) {
      if (collection.containsOption(optionId)) {
        ids.add(collection.id);
      }
    }
  }
  if (selectedCollection != null) {
    ids.add(selectedCollection.id);
  }
  if (ids.isEmpty &&
      defaultFavoriteWhenEmpty &&
      collections.any(
        (item) => item.id == dailyChoiceFavoriteEatCollectionId,
      )) {
    ids.add(dailyChoiceFavoriteEatCollectionId);
  }
  return ids;
}

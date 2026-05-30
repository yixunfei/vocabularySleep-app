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
  String contextLabelKey = 'toolbox.daily_choice.editor.field.scene',
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
      .withDefaultWearCollections()
      .withDefaultActivityCollections();
  final filterCategories = categories.any((item) => item.id == 'all')
      ? categories
      : <DailyChoiceCategory>[
          const DailyChoiceCategory(
            id: 'all',
            icon: Icons.grid_view_rounded,
            titleKey: 'all',
            subtitleKey:
                'inline.plan295.daily_choice.all_categories.131fcb0d370f',
          ),
          ...categories,
        ];
  final filterContexts = contexts.any((item) => item.id == 'all')
      ? contexts
      : <DailyChoiceCategory>[
          DailyChoiceCategory(
            id: 'all',
            icon: Icons.tune_rounded,
            titleKey: 'all',
            subtitleKey: 'inline.plan295.daily_choice.all_scenes.bb6705527faa',
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
  final isActivityModule =
      moduleId == DailyChoiceModuleId.activity.storageValue;
  var builtInExpanded = !isEatModule;
  var collectionNameDraft = '';
  var collectionInputVersion = 0;
  var selectedCollectionId = 'all';
  var wearCollectionNameDraft = '';
  var wearCollectionInputVersion = 0;
  var selectedWearCollectionId = 'all';
  var activityCollectionNameDraft = '';
  var activityCollectionInputVersion = 0;
  var selectedActivityCollectionId = 'all';
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
                  .withDefaultWearCollections()
                  .withDefaultActivityCollections();
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
            DailyChoiceActivityCollection? selectedActivityCollection =
                selectedActivityCollectionId == 'all'
                ? null
                : localState.activityCollectionById(
                    selectedActivityCollectionId,
                  );
            if (selectedActivityCollection == null) {
              selectedActivityCollectionId = 'all';
            }
            final selectedActivityCollectionOptionIds =
                selectedActivityCollection?.optionIds.toSet();
            bool matchesCollection(DailyChoiceOption item) {
              if (isEatModule) {
                return selectedCollectionOptionIds == null ||
                    selectedCollectionOptionIds.contains(item.id);
              }
              if (isWearModule) {
                return selectedWearCollectionOptionIds == null ||
                    selectedWearCollectionOptionIds.contains(item.id);
              }
              if (isActivityModule) {
                return selectedActivityCollectionOptionIds == null ||
                    selectedActivityCollectionOptionIds.contains(item.id);
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
                : (isActivityModule
                      ? selectedActivityCollectionId
                      : selectedCollectionId);
            final activeCollectionOptionIds = isWearModule
                ? selectedWearCollectionOptionIds
                : (isActivityModule
                      ? selectedActivityCollectionOptionIds
                      : selectedCollectionOptionIds);
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
                contextLabelKey: contextLabelKey,
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
                activityCollections: isActivityModule
                    ? localState.activityCollections
                    : const <DailyChoiceActivityCollection>[],
                initialActivityCollectionIds: isActivityModule
                    ? _managerInitialActivityCollectionIds(
                        collections: localState.activityCollections,
                        option: option,
                        selectedCollection: selectedActivityCollection,
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
              if (isActivityModule) {
                nextState = nextState.setOptionActivityCollections(
                  optionId: result.id,
                  collectionIds: editorResult.activityCollectionIds,
                );
              }
              await publishWithProcessing(
                nextState,
                i18n.t(
                  'inline.plan295.daily_choice.saving_changes.6b31e6a1bfcd',
                ),
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
                i18n.t(
                  'inline.plan295.daily_choice.saving_adjustment.ccf711d2c0d7',
                ),
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
              if (isActivityModule) {
                nextState = nextState.setOptionActivityCollections(
                  optionId: result.id,
                  collectionIds: editorResult.activityCollectionIds,
                );
              }
              await publishWithProcessing(
                nextState,
                i18n.t(
                  'inline.ui.pages.toolbox_daily_choice.daily_choice_manager_sheet.saving_copy_2718fa',
                ),
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
                i18n.t(
                  'inline.plan295.daily_choice.adding_to_sets.0003df24782e',
                ),
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
                i18n.t(
                  'inline.plan295.daily_choice.adding_to_wardrobe.be64cad101f7',
                ),
              );
            }

            Future<void> addOptionToActivityCollections({
              required String optionId,
              required Set<String> collectionIds,
            }) async {
              if (collectionIds.isEmpty) {
                return;
              }
              var nextState = localState;
              for (final collectionId in collectionIds) {
                nextState = nextState.addOptionToActivityCollection(
                  collectionId: collectionId,
                  optionId: optionId,
                );
              }
              await publishWithProcessing(
                nextState,
                i18n.t(
                  'inline.plan295.daily_choice.adding_to_action_set.2fddd1a5e0de',
                ),
              );
            }

            Future<void> toggleBuiltInHidden({
              required DailyChoiceOption option,
              required bool isHidden,
            }) async {
              if (isHidden) {
                await publishWithProcessing(
                  localState.restoreBuiltIn(option.id),
                  i18n.t(
                    _managerModuleKey(
                      wearKey: 'inline.plan295.daily_choice.restoring_outfit.ae04744e159f',
                      activityKey:
                          'inline.plan295.daily_choice.restoring_action.18747f1d0c5e',
                      eatKey:
                          'inline.plan295.daily_choice.restoring_recipe.afef6f1e4252',
                      isWearModule: isWearModule,
                      isActivityModule: isActivityModule,
                    ),
                  ),
                );
                return;
              }
              final confirmed = await _confirmHideBuiltInRecipe(
                context: context,
                i18n: i18n,
                option: option,
                isWearModule: isWearModule,
                isActivityModule: isActivityModule,
              );
              if (confirmed != true) {
                return;
              }
              await publishWithProcessing(
                localState.hideBuiltIn(option.id),
                i18n.t(
                  _managerModuleKey(
                    wearKey: 'toolbox.daily_choice.manager.hiding.wear',
                    activityKey: 'toolbox.daily_choice.manager.hiding.activity',
                    eatKey: 'toolbox.daily_choice.manager.hiding.eat',
                    isWearModule: isWearModule,
                    isActivityModule: isActivityModule,
                  ),
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

            void createActivityCollection() {
              final title = activityCollectionNameDraft.trim();
              if (title.isEmpty) {
                return;
              }
              final collection = DailyChoiceActivityCollection(
                id: 'activity_collection_${DateTime.now().microsecondsSinceEpoch}',
                titleZh: title,
                titleEn: title,
              );
              activityCollectionNameDraft = '';
              activityCollectionInputVersion += 1;
              selectedActivityCollectionId = collection.id;
              resetBuiltInPaging();
              publish(localState.upsertActivityCollection(collection));
            }

            void showManagerMessageKey(
              String key, {
              Map<String, Object?> params = const <String, Object?>{},
            }) {
              if (managerSheetClosed) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(i18n.t(key, params: params)),
                ),
              );
            }

            String managerErrorText(Object error) {
              if (error is FormatException && error.message.isNotEmpty) {
                return error.message;
              }
              return '$error';
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
                i18n.t(
                  'inline.plan295.daily_choice.renaming_recipe_set.8540dd2a12a9',
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
                i18n.t(
                  'inline.plan295.daily_choice.deleting_recipe_set.25a1235dce57',
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
                i18n.t(
                  'inline.plan295.daily_choice.renaming_wardrobe.df4d2349957d',
                ),
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
                i18n.t(
                  'inline.plan295.daily_choice.deleting_wardrobe.b05e694d025a',
                ),
              );
            }

            Future<void> renameSelectedActivityCollection() async {
              final collection = localState.activityCollectionById(
                selectedActivityCollectionId,
              );
              if (collection == null ||
                  collection.id == dailyChoiceFavoriteActivityCollectionId) {
                return;
              }
              final title = await _promptActivityCollectionName(
                context: context,
                i18n: i18n,
                accent: accent,
                initialTitle: collection.title(i18n),
              );
              if (title == null || title.trim().isEmpty) {
                return;
              }
              await publishWithProcessing(
                localState.upsertActivityCollection(
                  collection.copyWith(
                    titleZh: title.trim(),
                    titleEn: title.trim(),
                  ),
                ),
                i18n.t(
                  'inline.plan295.daily_choice.renaming_action_set.ffa51f85515c',
                ),
              );
            }

            Future<void> deleteSelectedActivityCollection() async {
              final collection = localState.activityCollectionById(
                selectedActivityCollectionId,
              );
              if (collection == null ||
                  collection.id == dailyChoiceFavoriteActivityCollectionId) {
                return;
              }
              final confirmed = await _confirmDeleteActivityCollection(
                context: context,
                i18n: i18n,
                collection: collection,
              );
              if (confirmed != true) {
                return;
              }
              selectedActivityCollectionId = 'all';
              resetBuiltInPaging();
              await publishWithProcessing(
                localState.deleteActivityCollection(collection.id),
                i18n.t(
                  'inline.plan295.daily_choice.deleting_action_set.95504d256566',
                ),
              );
            }

            Future<void> exportSelectedCollection() async {
              final collection = localState.eatCollectionById(
                selectedCollectionId,
              );
              if (collection == null) {
                showManagerMessageKey(
                  'toolbox.daily_choice.manager.message.choose_recipe_set',
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
                  dialogTitle: i18n.t(
                    'inline.plan295.daily_choice.export_recipe_set.6ac97d14a6e6',
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
                showManagerMessageKey(
                  'toolbox.daily_choice.manager.message.recipe_set_exported',
                );
              } catch (error) {
                showManagerMessageKey(
                  'toolbox.daily_choice.manager.message.export_failed',
                  params: <String, Object?>{'error': managerErrorText(error)},
                );
              }
            }

            Future<void> importCollections() async {
              try {
                final result = await FilePicker.platform.pickFiles(
                  dialogTitle: i18n.t(
                    'inline.plan295.daily_choice.import_recipe_set.72d93596e42c',
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
                  throw FormatException(
                    i18n.t(
                      'toolbox.daily_choice.manager.error.selected_recipe_set_unreadable',
                    ),
                  );
                }
                final decoded = jsonDecode(utf8.decode(bytes));
                if (decoded is! Map) {
                  throw FormatException(
                    i18n.t(
                      'toolbox.daily_choice.manager.error.invalid_recipe_set_package',
                    ),
                  );
                }
                final imported = _importEatCollectionExportPackage(
                  state: localState,
                  payload: decoded.cast<String, Object?>(),
                );
                selectedCollectionId = imported.selectedCollectionId;
                resetBuiltInPaging();
                await publishWithProcessing(
                  imported.state,
                  i18n.t(
                    'inline.plan295.daily_choice.importing_recipe_set.6f8da96d9e76',
                  ),
                );
                showManagerMessageKey(
                  'toolbox.daily_choice.manager.message.recipe_sets_imported',
                  params: <String, Object?>{
                    'count': imported.collectionCount,
                  },
                );
              } catch (error) {
                showManagerMessageKey(
                  'toolbox.daily_choice.manager.message.import_failed',
                  params: <String, Object?>{'error': managerErrorText(error)},
                );
              }
            }

            Future<void> exportSelectedWearCollection() async {
              final collection = localState.wearCollectionById(
                selectedWearCollectionId,
              );
              if (collection == null) {
                showManagerMessageKey(
                  'toolbox.daily_choice.manager.message.choose_wardrobe',
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
                  dialogTitle: i18n.t(
                    'inline.plan295.daily_choice.export_wardrobe.1f5808318d56',
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
                showManagerMessageKey(
                  'toolbox.daily_choice.manager.message.wardrobe_exported',
                );
              } catch (error) {
                showManagerMessageKey(
                  'toolbox.daily_choice.manager.message.export_failed',
                  params: <String, Object?>{'error': managerErrorText(error)},
                );
              }
            }

            Future<void> importWearCollections() async {
              try {
                final result = await FilePicker.platform.pickFiles(
                  dialogTitle: i18n.t(
                    'inline.plan295.daily_choice.import_wardrobe.43478a32fe5a',
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
                  throw FormatException(
                    i18n.t(
                      'toolbox.daily_choice.manager.error.selected_wardrobe_unreadable',
                    ),
                  );
                }
                final decoded = jsonDecode(utf8.decode(bytes));
                if (decoded is! Map) {
                  throw FormatException(
                    i18n.t(
                      'toolbox.daily_choice.manager.error.invalid_wardrobe_package',
                    ),
                  );
                }
                final imported = _importWearCollectionExportPackage(
                  state: localState,
                  payload: decoded.cast<String, Object?>(),
                );
                selectedWearCollectionId = imported.selectedCollectionId;
                resetBuiltInPaging();
                await publishWithProcessing(
                  imported.state,
                  i18n.t(
                    'inline.plan295.daily_choice.importing_wardrobe.3de4a72c1023',
                  ),
                );
                showManagerMessageKey(
                  'toolbox.daily_choice.manager.message.wardrobes_imported',
                  params: <String, Object?>{
                    'count': imported.collectionCount,
                  },
                );
              } catch (error) {
                showManagerMessageKey(
                  'toolbox.daily_choice.manager.message.import_failed',
                  params: <String, Object?>{'error': managerErrorText(error)},
                );
              }
            }

            Future<void> exportSelectedActivityCollection() async {
              final collection = localState.activityCollectionById(
                selectedActivityCollectionId,
              );
              if (collection == null) {
                showManagerMessageKey(
                  'toolbox.daily_choice.manager.message.choose_action_set',
                );
                return;
              }
              try {
                final payload = _buildActivityCollectionExportPackage(
                  state: localState,
                  collection: collection,
                );
                final encoded = const JsonEncoder.withIndent(
                  '  ',
                ).convert(payload);
                final fileName =
                    '${_safeActivityCollectionExportFileName(collection.title(i18n))}.daily-choice-actions.json';
                final path = await FilePicker.platform.saveFile(
                  dialogTitle: i18n.t(
                    'inline.plan295.daily_choice.export_action_set.88daa28606df',
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
                showManagerMessageKey(
                  'toolbox.daily_choice.manager.message.action_set_exported',
                );
              } catch (error) {
                showManagerMessageKey(
                  'toolbox.daily_choice.manager.message.export_failed',
                  params: <String, Object?>{'error': managerErrorText(error)},
                );
              }
            }

            Future<void> importActivityCollections() async {
              try {
                final result = await FilePicker.platform.pickFiles(
                  dialogTitle: i18n.t(
                    'inline.plan295.daily_choice.import_action_set.0f57666dd30c',
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
                  throw FormatException(
                    i18n.t(
                      'toolbox.daily_choice.manager.error.selected_action_set_unreadable',
                    ),
                  );
                }
                final decoded = jsonDecode(utf8.decode(bytes));
                if (decoded is! Map) {
                  throw FormatException(
                    i18n.t(
                      'toolbox.daily_choice.manager.error.invalid_action_set_package',
                    ),
                  );
                }
                final imported = _importActivityCollectionExportPackage(
                  state: localState,
                  payload: decoded.cast<String, Object?>(),
                );
                selectedActivityCollectionId = imported.selectedCollectionId;
                resetBuiltInPaging();
                await publishWithProcessing(
                  imported.state,
                  i18n.t(
                    'inline.plan295.daily_choice.importing_action_set.275b09a3bb36',
                  ),
                );
                showManagerMessageKey(
                  'toolbox.daily_choice.manager.message.action_sets_imported',
                  params: <String, Object?>{
                    'count': imported.collectionCount,
                  },
                );
              } catch (error) {
                showManagerMessageKey(
                  'toolbox.daily_choice.manager.message.import_failed',
                  params: <String, Object?>{'error': managerErrorText(error)},
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
                              i18n.t(
                                'inline.plan295.daily_choice.custom_manager.ce004bd01099',
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
                                isActivityModule: isActivityModule,
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
                                  labelKey:
                                      'inline.plan295.daily_choice.search_recipe_name.ff52c0f776fa',
                                  hintKey:
                                      'inline.plan295.daily_choice.search_by_recipe_title_or_summary.618aff37de48',
                                  onDraftChanged: (value) {
                                    searchDraft = value;
                                  },
                                  onCommitted: commitSearchQuery,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _ManagerExpandableSection(
                                title: i18n.t(
                                  'inline.plan295.daily_choice.my_recipe_sets.074738053515',
                                ),
                                subtitle: selectedCollection == null
                                    ? i18n.t(
                                        'inline.plan295.daily_choice.group_favorites_weekday_meals_or_rec.b73ee5980321',
                                      )
                                    : i18n.t(
                                        'inline.plan295.daily_choice.showing_selectedcollection_title_i18.7636930244a9',
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
                                        labelText: i18n.t(
                                          'inline.plan295.daily_choice.new_recipe_set.165492496a7b',
                                        ),
                                        hintText: i18n.t(
                                          'inline.plan295.daily_choice.for_example_weeknight_dinners.f668034ef5ff',
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
                                          i18n.t(
                                            'inline.plan295.daily_choice.create_set.3d6943ec3a4a',
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
                                              labelText: i18n.t(
                                                'inline.plan295.daily_choice.random_pool.579f7405953a',
                                              ),
                                            ),
                                            items: <DropdownMenuItem<String>>[
                                              DropdownMenuItem<String>(
                                                value: 'all',
                                                child: Text(
                                                  i18n.t(
                                                    'inline.plan295.daily_choice.built_in_recipes.b6a38d84379c',
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
                                          message: i18n.t(
                                            'inline.plan295.daily_choice.rename_set.e67b5a3dc805',
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
                                          message: i18n.t(
                                            'inline.plan295.daily_choice.delete_set.772c5db1ee85',
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
                                            i18n.t(
                                              'inline.ui.pages.toolbox_daily_choice.daily_choice_manager_sheet.export_current_22a596',
                                            ),
                                          ),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: importCollections,
                                          icon: const Icon(
                                            Icons.file_upload_outlined,
                                          ),
                                          label: Text(
                                            i18n.t(
                                              'inline.plan295.daily_choice.import_package.32fea453f6d4',
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
                                  labelKey:
                                      'inline.plan295.daily_choice.search_outfit_or_piece.8e220a0c64e4',
                                  hintKey:
                                      'inline.plan295.daily_choice.search_by_outfit_piece_or_scene_keyw.eb8130da51a5',
                                  onDraftChanged: (value) {
                                    searchDraft = value;
                                  },
                                  onCommitted: commitSearchQuery,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _ManagerExpandableSection(
                                title: i18n.t(
                                  'inline.plan295.daily_choice.wardrobes.8316dfe0d138',
                                ),
                                subtitle: selectedWearCollection == null
                                    ? i18n.t(
                                        'inline.plan295.daily_choice.group_real_commute_weekend_active_or.ab0ebaa3cb5a',
                                      )
                                    : i18n.t(
                                        'inline.plan295.daily_choice.showing_selectedwearcollection_title.e6f91512e431',
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
                                        labelText: i18n.t(
                                          'inline.plan295.daily_choice.new_wardrobe.f5a77203272d',
                                        ),
                                        hintText: i18n.t(
                                          'inline.plan295.daily_choice.for_example_daily_commute_weekend_ca.ee62208b9276',
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
                                          i18n.t(
                                            'inline.plan295.daily_choice.create_wardrobe.f86cfd51ae9f',
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
                                              labelText: i18n.t(
                                                'inline.plan295.daily_choice.random_pool.579f7405953a',
                                              ),
                                            ),
                                            items: <DropdownMenuItem<String>>[
                                              DropdownMenuItem<String>(
                                                value: 'all',
                                                child: Text(
                                                  i18n.t(
                                                    'inline.plan295.daily_choice.all_wardrobes.679aed291107',
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
                                          message: i18n.t(
                                            'inline.plan295.daily_choice.rename_wardrobe.2b833f19423b',
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
                                          message: i18n.t(
                                            'inline.plan295.daily_choice.delete_wardrobe.0b37ec4b04f6',
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
                                            i18n.t(
                                              'inline.ui.pages.toolbox_daily_choice.daily_choice_manager_sheet.export_current_22a596',
                                            ),
                                          ),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: importWearCollections,
                                          icon: const Icon(
                                            Icons.file_upload_outlined,
                                          ),
                                          label: Text(
                                            i18n.t(
                                              'inline.plan295.daily_choice.import_package.32fea453f6d4',
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
                            if (isActivityModule) ...<Widget>[
                              ToolboxSurfaceCard(
                                padding: const EdgeInsets.all(12),
                                borderColor: accent.withValues(alpha: 0.14),
                                shadowOpacity: 0.02,
                                child: _ManagerSearchField(
                                  i18n: i18n,
                                  initialText: searchDraft,
                                  labelKey:
                                      'inline.plan295.daily_choice.search_action.95c3014264e8',
                                  hintKey:
                                      'inline.plan295.daily_choice.search_by_action_trigger_or_tag.87a61ae5c938',
                                  onDraftChanged: (value) {
                                    searchDraft = value;
                                  },
                                  onCommitted: commitSearchQuery,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _ManagerExpandableSection(
                                title: i18n.t(
                                  'inline.plan295.daily_choice.action_sets.847daea911f1',
                                ),
                                subtitle: selectedActivityCollection == null
                                    ? i18n.t(
                                        'inline.plan295.daily_choice.group_focus_resets_quick_outings_tid.78e20379f540',
                                      )
                                    : i18n.t(
                                        'inline.plan295.daily_choice.showing_selectedactivitycollection_t.873ce359d318',
                                      ),
                                accent: accent,
                                expanded: collectionsExpanded,
                                countLabel:
                                    '${localState.activityCollections.length}',
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
                                        'activity-collection-input-$activityCollectionInputVersion',
                                      ),
                                      initialValue: activityCollectionNameDraft,
                                      onChanged: (value) {
                                        activityCollectionNameDraft = value;
                                      },
                                      onFieldSubmitted: (_) =>
                                          createActivityCollection(),
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(
                                          Icons.playlist_add_check_rounded,
                                        ),
                                        labelText: i18n.t(
                                          'inline.plan295.daily_choice.new_action_set.10e5a49dd740',
                                        ),
                                        hintText: i18n.t(
                                          'inline.plan295.daily_choice.for_example_focus_reset_after_meal_w.4cfe0f799b56',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: FilledButton.icon(
                                        onPressed: createActivityCollection,
                                        icon: const Icon(Icons.add_rounded),
                                        label: Text(
                                          i18n.t(
                                            'inline.plan295.daily_choice.create_action_set.949f06efbfd5',
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
                                              'activity-collection-scope-$selectedActivityCollectionId',
                                            ),
                                            initialValue:
                                                selectedActivityCollectionId,
                                            isExpanded: true,
                                            decoration: InputDecoration(
                                              prefixIcon: const Icon(
                                                Icons.filter_list_rounded,
                                              ),
                                              labelText: i18n.t(
                                                'inline.plan295.daily_choice.random_pool.579f7405953a',
                                              ),
                                            ),
                                            items: <DropdownMenuItem<String>>[
                                              DropdownMenuItem<String>(
                                                value: 'all',
                                                child: Text(
                                                  i18n.t(
                                                    'inline.plan295.daily_choice.built_in_actions.e9cc78aca202',
                                                  ),
                                                ),
                                              ),
                                              ...localState.activityCollections.map(
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
                                                selectedActivityCollectionId =
                                                    value;
                                                resetBuiltInPaging();
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Tooltip(
                                          message: i18n.t(
                                            'inline.plan295.daily_choice.rename_action_set.887cc121bed7',
                                          ),
                                          child: IconButton.filledTonal(
                                            onPressed:
                                                selectedActivityCollection ==
                                                        null ||
                                                    selectedActivityCollection
                                                            .id ==
                                                        dailyChoiceFavoriteActivityCollectionId
                                                ? null
                                                : renameSelectedActivityCollection,
                                            icon: const Icon(
                                              Icons.drive_file_rename_outline,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Tooltip(
                                          message: i18n.t(
                                            'inline.plan295.daily_choice.delete_action_set.39de31daffa6',
                                          ),
                                          child: IconButton.filledTonal(
                                            onPressed:
                                                selectedActivityCollection ==
                                                        null ||
                                                    selectedActivityCollection
                                                            .id ==
                                                        dailyChoiceFavoriteActivityCollectionId
                                                ? null
                                                : deleteSelectedActivityCollection,
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
                                              selectedActivityCollection == null
                                              ? null
                                              : exportSelectedActivityCollection,
                                          icon: const Icon(
                                            Icons.ios_share_rounded,
                                          ),
                                          label: Text(
                                            i18n.t(
                                              'inline.ui.pages.toolbox_daily_choice.daily_choice_manager_sheet.export_current_22a596',
                                            ),
                                          ),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: importActivityCollections,
                                          icon: const Icon(
                                            Icons.file_upload_outlined,
                                          ),
                                          label: Text(
                                            i18n.t(
                                              'inline.plan295.daily_choice.import_package.32fea453f6d4',
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
                              title: i18n.t(
                                'inline.plan295.daily_choice.filters.055e12bcd2a4',
                              ),
                              subtitle: activeFilterCount <= 0
                                  ? i18n.t(
                                      _managerModuleKey(
                                        wearKey:
                                            'toolbox.daily_choice.manager.filters.empty.wear',
                                        activityKey:
                                            'toolbox.daily_choice.manager.filters.empty.activity',
                                        eatKey:
                                            'toolbox.daily_choice.manager.filters.empty.default',
                                        isWearModule: isWearModule,
                                        isActivityModule: isActivityModule,
                                      ),
                                    )
                                  : i18n.t(
                                      'inline.plan295.daily_choice.activefiltercount_filters_enabled.6b3651f7782c',
                                    ),
                              accent: accent,
                              expanded: filtersExpanded,
                              countLabel: activeFilterCount <= 0
                                  ? i18n.t('todoNoColor')
                                  : i18n.t(
                                      'inline.plan295.daily_choice.activefiltercount_active.721b68d05f03',
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
                                    title: i18n.t(
                                      'inline.plan295.daily_choice.filter_by_category.9f8cbe196273',
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
                                      title: i18n.t(
                                        'inline.plan295.daily_choice.filter_by_contextlabelen.301714535181',
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
                                i18n.t(
                                  isEatModule
                                      ? 'inline.plan295.daily_choice.add_recipe.342dfa0d76b3'
                                      : _managerModuleKey(
                                          wearKey:
                                              'inline.plan295.daily_choice.add_wardrobe_outfit.8015c1f80a7e',
                                          activityKey:
                                              'inline.plan295.daily_choice.add_action.ce9409a9a47b',
                                          eatKey: 'addTodo',
                                          isWearModule: isWearModule,
                                          isActivityModule: isActivityModule,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _ManagerExpandableSection(
                              title: i18n.t(
                                'inline.plan295.daily_choice.my_custom_items.1846e12c954b',
                              ),
                              subtitle: i18n.t(
                                _managerModuleKey(
                                  wearKey:
                                      'toolbox.daily_choice.manager.custom.subtitle.wear',
                                  activityKey:
                                      'toolbox.daily_choice.manager.custom.subtitle.activity',
                                  eatKey:
                                      'toolbox.daily_choice.manager.custom.subtitle.default',
                                  isWearModule: isWearModule,
                                  isActivityModule: isActivityModule,
                                ),
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
                                        isActivityModule: isActivityModule,
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
                                                isActivityModule:
                                                    isActivityModule,
                                              ),
                                              actions: <Widget>[
                                                TextButton.icon(
                                                  onPressed: () =>
                                                      openEditor(item),
                                                  icon: const Icon(
                                                    Icons.edit_rounded,
                                                  ),
                                                  label: Text(i18n.t('edit')),
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
                                                          i18n.t(
                                                            'inline.plan295.daily_choice.removing_from_set.fd8a8a031c50',
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
                                                          i18n.t(
                                                            'inline.plan295.daily_choice.removing_from_wardrobe.145955652981',
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                if (isActivityModule)
                                                  ..._managerActivityCollectionActions(
                                                    context: context,
                                                    i18n: i18n,
                                                    collections: localState
                                                        .activityCollections,
                                                    selectedCollection:
                                                        selectedActivityCollection,
                                                    optionId: item.id,
                                                    onAddMultiple: (collectionIds) {
                                                      unawaited(
                                                        addOptionToActivityCollections(
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
                                                              .removeOptionFromActivityCollection(
                                                                collectionId:
                                                                    collectionId,
                                                                optionId:
                                                                    item.id,
                                                              ),
                                                          i18n.t(
                                                            'inline.plan295.daily_choice.removing_from_action_set.ae4d94dac663',
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
                                                  label: Text(i18n.t('delete')),
                                                ),
                                              ],
                                            ),
                                          )
                                          .toList(growable: false),
                                    ),
                            ),
                            if (isEatModule || isWearModule)
                              _ManagerExpandableSection(
                                title: i18n.t(
                                  isWearModule
                                      ? 'inline.plan295.daily_choice.my_adjustments.1e2d81198552'
                                      : 'toolbox.daily_choice.manager.adjustments.title.eat',
                                ),
                                subtitle: isWearModule
                                    ? i18n.t(
                                        'inline.plan295.daily_choice.your_personal_overrides_of_built_in.6dc6b648c7a9',
                                      )
                                    : i18n.t(
                                        'inline.plan295.daily_choice.your_personal_overrides_of_built_in.7f6a30f69cf4',
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
                                        text: i18n.t(
                                          isWearModule
                                              ? 'inline.plan295.daily_choice.no_personal_adjustments_in_this_filt.ec7ed074e071'
                                              : 'toolbox.daily_choice.manager.adjustments.empty.eat',
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
                                                  i18n.t(
                                                    'inline.ui.pages.toolbox_daily_choice.daily_choice_manager_sheet.adjusted_321dc4',
                                                  ),
                                                  if (hidden.contains(item.id))
                                                    i18n.t(
                                                      'inline.plan295.daily_choice.hidden.1a09896173ce',
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
                                                      labelKey:
                                                          'inline.plan295.daily_choice.adjust.1cf952b0e1c0',
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
                                                      labelKey:
                                                          'inline.plan295.daily_choice.save_as.ccb638e1d5f7',
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
                                                            i18n.t(
                                                              'inline.plan295.daily_choice.removing_from_set.fd8a8a031c50',
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
                                                            i18n.t(
                                                              'inline.plan295.daily_choice.removing_from_wardrobe.145955652981',
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
                                                      i18n.t(
                                                        isWearModule
                                                            ? 'inline.plan295.daily_choice.restore_original.517272ccd104'
                                                            : 'inline.plan295.daily_choice.restore_original.e5b6d6ca69f7',
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
                              title: i18n.t(
                                _managerModuleKey(
                                  wearKey:
                                      'inline.plan295.daily_choice.built_in_references.491678ac4b76',
                                  activityKey:
                                      'inline.plan295.daily_choice.built_in_actions.7612ba3a0b2b',
                                  eatKey:
                                      'inline.plan295.daily_choice.built_in_browser.399635bf6bc7',
                                  isWearModule: isWearModule,
                                  isActivityModule: isActivityModule,
                                ),
                              ),
                              subtitle: _builtInSectionSubtitle(
                                i18n,
                                builtInExpanded: builtInExpanded,
                                total: builtInTotalCount,
                                visible: visibleBuiltIns.length,
                                loading: builtInSqlLoading,
                                errorMessage: builtInSqlError,
                                isWearModule: isWearModule,
                                isActivityModule: isActivityModule,
                              ),
                              accent: accent,
                              expanded: builtInExpanded,
                              countLabel: builtInExpanded
                                  ? (builtInSqlLoading && builtInTotalCount == 0
                                        ? i18n.t(
                                            'inline.ui.pages.toolbox_daily_choice.daily_choice_eat_module.loading_8285c7',
                                          )
                                        : '$builtInTotalCount')
                                  : i18n.t(
                                      'inline.plan295.daily_choice.open.7b12e1b2a34e',
                                    ),
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
                                      text: i18n.t(
                                        _managerModuleKey(
                                          wearKey:
                                              'inline.plan295.daily_choice.loading_built_in_outfits.aeb0c77b12f6',
                                          activityKey:
                                              'inline.plan295.daily_choice.loading_built_in_actions.63de11b2d980',
                                          eatKey:
                                              'inline.plan295.daily_choice.loading_built_in_recipes.6c05be75cf9a',
                                          isWearModule: isWearModule,
                                          isActivityModule: isActivityModule,
                                        ),
                                      ),
                                    )
                                  : builtInSqlError != null &&
                                        visibleBuiltIns.isEmpty
                                  ? _ManagerHint(
                                      text: i18n.t(
                                        _managerModuleKey(
                                          wearKey:
                                              'inline.plan295.daily_choice.failed_to_load_built_in_outfits_buil.73d7f4c8e795',
                                          activityKey:
                                              'inline.plan295.daily_choice.failed_to_load_built_in_actions_buil.da34536227fd',
                                          eatKey:
                                              'inline.plan295.daily_choice.failed_to_load_built_in_recipes_buil.a07db9081867',
                                          isWearModule: isWearModule,
                                          isActivityModule: isActivityModule,
                                        ),
                                        params: <String, Object?>{
                                          'builtInSqlError': builtInSqlError,
                                        },
                                      ),
                                    )
                                  : visibleBuiltIns.isEmpty
                                  ? _ManagerHint(
                                      text: _emptyBuiltInHint(
                                        i18n,
                                        isWearModule: isWearModule,
                                        isActivityModule: isActivityModule,
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
                                                ? i18n.t(
                                                    _managerModuleKey(
                                                      wearKey:
                                                          'toolbox.daily_choice.manager.hidden.subtitle.wear',
                                                      activityKey:
                                                          'toolbox.daily_choice.manager.hidden.subtitle.activity',
                                                      eatKey:
                                                          'toolbox.daily_choice.manager.hidden.subtitle.eat',
                                                      isWearModule:
                                                          isWearModule,
                                                      isActivityModule:
                                                          isActivityModule,
                                                    ),
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
                                                i18n.t(
                                                  'inline.ui.pages.toolbox_daily_choice.daily_choice_manager_sheet.adjusted_321dc4',
                                                ),
                                              if (isHidden)
                                                i18n.t(
                                                  'inline.plan295.daily_choice.hidden.1a09896173ce',
                                                ),
                                              ..._managerChips(
                                                i18n,
                                                displayItem,
                                                isEatModule: isEatModule,
                                                isWearModule: isWearModule,
                                                isActivityModule:
                                                    isActivityModule,
                                              ),
                                            ],
                                            actions: <Widget>[
                                              if (onAdjustBuiltInOption != null)
                                                _managerAsyncActionButton(
                                                  i18n: i18n,
                                                  icon: Icons.tune_rounded,
                                                  labelKey:
                                                      'inline.plan295.daily_choice.adjust.1cf952b0e1c0',
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
                                                  labelKey:
                                                      'inline.plan295.daily_choice.save_as.ccb638e1d5f7',
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
                                                        i18n.t(
                                                          'inline.plan295.daily_choice.removing_from_set.fd8a8a031c50',
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
                                                        i18n.t(
                                                          'inline.plan295.daily_choice.removing_from_wardrobe.145955652981',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              if (isActivityModule)
                                                ..._managerActivityCollectionActions(
                                                  context: context,
                                                  i18n: i18n,
                                                  collections: localState
                                                      .activityCollections,
                                                  selectedCollection:
                                                      selectedActivityCollection,
                                                  optionId: baseItem.id,
                                                  onAddMultiple: (collectionIds) {
                                                    unawaited(
                                                      addOptionToActivityCollections(
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
                                                            .removeOptionFromActivityCollection(
                                                              collectionId:
                                                                  collectionId,
                                                              optionId:
                                                                  baseItem.id,
                                                            ),
                                                        i18n.t(
                                                          'inline.plan295.daily_choice.removing_from_action_set.ae4d94dac663',
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
                                                    i18n.t(
                                                      'inline.plan295.daily_choice.restore_original.e5b6d6ca69f7',
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
                                                      ? i18n.t(
                                                          'toolbox.hub.edit.restore_action',
                                                        )
                                                      : i18n.t(
                                                          'inline.plan295.daily_choice.hide.bd89cbfb20f9',
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
                                                ? i18n.t(
                                                    _managerModuleKey(
                                                      wearKey:
                                                          'inline.plan295.daily_choice.loading_more_built_in_outfits.77e6ee77262b',
                                                      activityKey:
                                                          'inline.plan295.daily_choice.loading_more_built_in_actions.c3e321de4e1a',
                                                      eatKey:
                                                          'inline.plan295.daily_choice.loading_more_built_in_recipes.0315887276c0',
                                                      isWearModule:
                                                          isWearModule,
                                                      isActivityModule:
                                                          isActivityModule,
                                                    ),
                                                  )
                                                : i18n.t(
                                                    'inline.plan296.ui.pages.toolbox.daily.choice.daily.choice.manager.sheet.more_are_ready_to_load.a79fa6572b',
                                                    params: <String, Object?>{
                                                      'length':
                                                          builtInTotalCount -
                                                          visibleBuiltIns
                                                              .length,
                                                      'p1': isWearModule
                                                          ? 'outfits'
                                                          : (isActivityModule
                                                                ? 'actions'
                                                                : 'recipes'),
                                                    },
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
                          tooltip: i18n.t(
                            'inline.plan295.daily_choice.back_to_top.344567060476',
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

part of 'daily_choice_widgets.dart';

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
  Future<DailyChoiceOption?> Function(DailyChoiceOption option)?
  onSaveBuiltInAsCustom,
}) async {
  var localState = state.withDefaultEatCollections();
  final filterCategories = <DailyChoiceCategory>[
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
  var builtInVisibleLimit = _managerInitialBuiltInLimit(isEatModule);
  var builtInSqlActiveKey = '';
  var builtInSqlLoadingKey = '';
  var builtInSqlOptions = const <DailyChoiceOption>[];
  var builtInSqlTotal = 0;
  String? builtInSqlError;
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
              localState = next.withDefaultEatCollections();
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
              required String key,
              required DailyChoiceEatLibraryQuery query,
            }) {
              if (builtInSqlActiveKey == key || builtInSqlLoadingKey == key) {
                return;
              }
              builtInSqlLoadingKey = key;
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
                    builtInSqlActiveKey = key;
                    builtInSqlLoadingKey = '';
                    builtInSqlOptions = result.options;
                    builtInSqlTotal = result.totalCount;
                    builtInSqlError = null;
                  });
                } catch (error) {
                  if (managerSheetClosed || builtInSqlLoadingKey != key) {
                    return;
                  }
                  setSheetState(() {
                    builtInSqlActiveKey = key;
                    builtInSqlLoadingKey = '';
                    builtInSqlOptions = const <DailyChoiceOption>[];
                    builtInSqlTotal = 0;
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
            bool matchesCollection(DailyChoiceOption item) {
              return selectedCollectionOptionIds == null ||
                  selectedCollectionOptionIds.contains(item.id);
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
            final nextBuiltInFilterCacheKey = _managerBuiltInFilterCacheKey(
              moduleId: moduleId,
              categoryId: selectedCategoryId,
              contextId: selectedContextId,
              searchQuery: searchQuery,
              traitFilters: selectedTraitFilters,
              selectedCollectionId: selectedCollectionId,
              selectedCollectionOptionIds: selectedCollectionOptionIds,
            );
            late final List<DailyChoiceOption> allVisibleBuiltIns;
            late final int builtInTotalCount;
            var builtInSqlLoading = false;
            if (!builtInExpanded) {
              allVisibleBuiltIns = const <DailyChoiceOption>[];
              builtInTotalCount = 0;
            } else if (canUseSqlBuiltIns) {
              final sqlKey = _managerBuiltInSqlQueryKey(
                cacheKey: nextBuiltInFilterCacheKey,
                visibleLimit: builtInVisibleLimit,
              );
              requestBuiltInSqlPage(
                key: sqlKey,
                query: _managerEatBuiltInLibraryQuery(
                  categoryId: selectedCategoryId,
                  contextId: selectedContextId,
                  searchQuery: searchQuery,
                  traitFilters: selectedTraitFilters,
                  selectedCollectionOptionIds: selectedCollectionOptionIds,
                  limit: builtInVisibleLimit,
                ),
              );
              builtInSqlLoading = builtInSqlLoadingKey == sqlKey;
              final activeSqlMatchesCurrentFilter = builtInSqlActiveKey
                  .startsWith('$nextBuiltInFilterCacheKey\u0001');
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
              final result = await showDailyChoiceEditorSheet(
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
              );
              if (result == null) {
                return;
              }
              var nextState = localState.upsertCustom(result);
              if (selectedCollection != null) {
                nextState = nextState.addOptionToEatCollection(
                  collectionId: selectedCollection.id,
                  optionId: result.id,
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
              final result = await runBuiltInItemAction<DailyChoiceOption>(
                option: option,
                actionId: _managerActionSaveAs,
                action: () => onSaveBuiltInAsCustom(option),
              );
              if (result == null) {
                return;
              }
              var nextState = localState.upsertCustom(result);
              if (selectedCollection != null) {
                nextState = nextState.addOptionToEatCollection(
                  collectionId: selectedCollection.id,
                  optionId: result.id,
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

            Future<void> toggleBuiltInHidden({
              required DailyChoiceOption option,
              required bool isHidden,
            }) async {
              if (isHidden) {
                await publishWithProcessing(
                  localState.restoreBuiltIn(option.id),
                  pickUiText(i18n, zh: '正在恢复菜谱...', en: 'Restoring recipe...'),
                );
                return;
              }
              final confirmed = await _confirmHideBuiltInRecipe(
                context: context,
                i18n: i18n,
                option: option,
              );
              if (confirmed != true) {
                return;
              }
              await publishWithProcessing(
                localState.hideBuiltIn(option.id),
                pickUiText(i18n, zh: '正在加入不喜欢...', en: 'Hiding recipe...'),
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
                            _ManagerExpandableSection(
                              title: pickUiText(
                                i18n,
                                zh: '筛选条件',
                                en: 'Filters',
                              ),
                              subtitle: activeFilterCount <= 0
                                  ? pickUiText(
                                      i18n,
                                      zh: '当前显示全部范围，可折叠收起。',
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
                                      : (isWearModule ? '新增个人衣橱搭配' : '新增'),
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
                                zh: '完全属于你的新增条目，可直接编辑和删除。',
                                en: 'Your own saved items that can be edited or removed.',
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
                                                ..._managerCollectionActions(
                                                  context: context,
                                                  i18n: i18n,
                                                  collections:
                                                      localState.eatCollections,
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
                                                              optionId: item.id,
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
                            if (isEatModule)
                              _ManagerExpandableSection(
                                title: pickUiText(
                                  i18n,
                                  zh: '我的调整',
                                  en: 'My adjustments',
                                ),
                                subtitle: pickUiText(
                                  i18n,
                                  zh: '基于内置菜谱保存的个人口味版本，会直接参与随机与筛选。',
                                  en: 'Your personal overrides of built-in recipes.',
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
                                          zh: '当前筛选下还没有保存过个人调整。点开内置菜即可基于原菜谱做个人化微调。',
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
                                                        zh: '恢复原味',
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
                                zh: '内置菜谱浏览',
                                en: 'Built-in browser',
                              ),
                              subtitle: _builtInSectionSubtitle(
                                i18n,
                                builtInExpanded: builtInExpanded,
                                total: builtInTotalCount,
                                visible: visibleBuiltIns.length,
                                loading: builtInSqlLoading,
                                errorMessage: builtInSqlError,
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
                                        zh: '正在读取内置菜谱...',
                                        en: 'Loading built-in recipes...',
                                      ),
                                    )
                                  : builtInSqlError != null &&
                                        visibleBuiltIns.isEmpty
                                  ? _ManagerHint(
                                      text: pickUiText(
                                        i18n,
                                        zh: '读取内置菜谱失败：$builtInSqlError',
                                        en: 'Failed to load built-in recipes: $builtInSqlError',
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
                                                    zh: '这道菜当前已加入不喜欢列表。',
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
                                              ..._managerCollectionActions(
                                                context: context,
                                                i18n: i18n,
                                                collections:
                                                    localState.eatCollections,
                                                selectedCollection:
                                                    selectedCollection,
                                                optionId: baseItem.id,
                                                onAddMultiple: (collectionIds) {
                                                  unawaited(
                                                    addOptionToCollections(
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
                                                    zh: '正在加载更多内置菜谱...',
                                                    en: 'Loading more built-in recipes...',
                                                  )
                                                : pickUiText(
                                                    i18n,
                                                    zh: '还有 ${builtInTotalCount - visibleBuiltIns.length} 条待加载。',
                                                    en: '${builtInTotalCount - visibleBuiltIns.length} more recipes are ready to load.',
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
}) {
  if (!builtInExpanded) {
    return pickUiText(
      i18n,
      zh: '展开后按当前搜索和筛选查看内置菜谱。',
      en: 'Expand to show built-ins using the current search and filters.',
    );
  }
  if (loading && visible == 0) {
    return pickUiText(
      i18n,
      zh: '正在按当前筛选读取内置菜谱。',
      en: 'Loading built-ins for the current filters.',
    );
  }
  if (errorMessage != null) {
    return pickUiText(
      i18n,
      zh: '读取内置菜谱时遇到问题，可稍后重试。',
      en: 'Built-ins could not be loaded. Try again later.',
    );
  }
  return pickUiText(
    i18n,
    zh: total > visible
        ? '已显示 $visible / $total 条；搜索和筛选仍作用于完整菜谱库。'
        : '可隐藏不喜欢的条目，也可在原菜谱上做个人调整或另存为个人食谱。',
    en: total > visible
        ? 'Showing $visible of $total; search and filters still cover the full library.'
        : 'Hide unwanted items, save adjustments, or copy a built-in as your own recipe.',
  );
}

String _managerBuiltInSqlQueryKey({
  required String cacheKey,
  required int visibleLimit,
}) {
  return '$cacheKey\u0001$visibleLimit';
}

DailyChoiceEatLibraryQuery _managerEatBuiltInLibraryQuery({
  required String categoryId,
  required String? contextId,
  required String searchQuery,
  required Map<String, String> traitFilters,
  required Set<String>? selectedCollectionOptionIds,
  required int limit,
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
        ? '删除内置条目会把它加入“不喜欢”隐藏列表；自定义穿搭会保存在本机，并可按风格、版型和样式类型管理。'
        : (isEatModule
              ? '不喜欢会先确认再隐藏内置菜；个人调整会覆盖原菜谱参与随机；个人食谱保存在本机并参与高级筛选。'
              : '删除内置条目会把它加入“不喜欢”隐藏列表；自定义条目会保存在本机。'),
    en: isWearModule
        ? 'Deleting a built-in item hides it. Custom outfits stay local and can be managed by style, silhouette, and key pieces.'
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
              ? '当前筛选下还没有个人衣橱搭配。可以按风格、版型和样式类型补上你真的会穿的组合。'
              : '当前筛选下还没有自定义条目。可以补上自己的搭配、地点或行动。'),
    en: isEatModule
        ? 'No personal recipes in this filter yet. Add the dishes you actually make or want to keep.'
        : (isWearModule
              ? 'No saved wardrobe outfits in this filter yet.'
              : 'No custom items in this filter yet.'),
  );
}

String _emptyBuiltInHint(AppI18n i18n, {required bool isWearModule}) {
  return pickUiText(
    i18n,
    zh: isWearModule
        ? '当前筛选下没有内置穿搭，换一个气温、场景或特征标签试试。'
        : '当前筛选下没有内置菜谱，换一个分类或上下文试试。',
    en: isWearModule
        ? 'No built-in outfits match this filter.'
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

class _ManagerSearchField extends StatefulWidget {
  const _ManagerSearchField({
    required this.i18n,
    required this.initialText,
    required this.onDraftChanged,
    required this.onCommitted,
  });

  final AppI18n i18n;
  final String initialText;
  final ValueChanged<String> onDraftChanged;
  final ValueChanged<String> onCommitted;

  @override
  State<_ManagerSearchField> createState() => _ManagerSearchFieldState();
}

class _ManagerSearchFieldState extends State<_ManagerSearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  var _lastCommittedText = '';

  @override
  void initState() {
    super.initState();
    _lastCommittedText = widget.initialText;
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _ManagerSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != oldWidget.initialText &&
        widget.initialText != _controller.text &&
        !_focusNode.hasFocus) {
      _controller.text = widget.initialText;
      _lastCommittedText = widget.initialText;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus) {
      _commit();
    }
  }

  void _commit() {
    final next = _controller.text.trim();
    if (next == _lastCommittedText.trim()) {
      return;
    }
    _lastCommittedText = next;
    widget.onCommitted(next);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        constraints: const BoxConstraints(minHeight: 48),
        prefixIcon: const Icon(Icons.search_rounded),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 42,
          minHeight: 42,
        ),
        labelText: pickUiText(
          widget.i18n,
          zh: '搜索菜品名称',
          en: 'Search recipe name',
        ),
        hintText: pickUiText(
          widget.i18n,
          zh: '按菜名、简介关键词快速筛选',
          en: 'Search by recipe title or summary',
        ),
      ),
      onChanged: widget.onDraftChanged,
      onSubmitted: (_) {
        _commit();
        _focusNode.unfocus();
      },
      onTapOutside: (_) => _focusNode.unfocus(),
    );
  }
}

class _ManagerExpandableSection extends StatelessWidget {
  const _ManagerExpandableSection({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.expanded,
    required this.onToggle,
    required this.child,
    this.countLabel,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final String? countLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ToolboxSurfaceCard(
        padding: const EdgeInsets.all(14),
        borderColor: accent.withValues(alpha: 0.14),
        shadowOpacity: 0.03,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            InkWell(
              borderRadius: BorderRadius.circular(
                ToolboxUiTokens.sectionPanelRadius,
              ),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (countLabel != null) ...<Widget>[
                      const SizedBox(width: 8),
                      ToolboxInfoPill(
                        text: countLabel!,
                        accent: accent,
                        backgroundColor: theme.colorScheme.surfaceContainerLow,
                      ),
                    ],
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: AppDurations.quick,
                      curve: AppEasing.standard,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: expanded ? 0.16 : 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Icon(
                        expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: accent,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (expanded) ...<Widget>[const SizedBox(height: 12), child],
          ],
        ),
      ),
    );
  }
}

class _ManagerHint extends StatelessWidget {
  const _ManagerHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.35,
      ),
    );
  }
}

class _ManagerTraitFilterSection extends StatelessWidget {
  const _ManagerTraitFilterSection({
    required this.i18n,
    required this.accent,
    required this.group,
    required this.selectedId,
    required this.onSelected,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoiceTraitGroup group;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          pickUiText(
            i18n,
            zh: '只看这个${group.titleZh}',
            en: 'Filter by ${group.titleEn}',
          ),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          group.subtitle(i18n),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            ToolboxSelectablePill(
              selected: selectedId == 'all',
              tint: accent,
              onTap: () => onSelected('all'),
              leading: const Icon(Icons.grid_view_rounded, size: 18),
              showLabel: selectedId == 'all',
              tooltip: pickUiText(i18n, zh: '全部', en: 'All'),
              padding: selectedId == 'all'
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                  : const EdgeInsets.all(12),
              label: Text(pickUiText(i18n, zh: '全部', en: 'All')),
            ),
            ...group.options.map((option) {
              final selected = selectedId == option.id;
              return ToolboxSelectablePill(
                selected: selected,
                tint: accent,
                onTap: () => onSelected(option.id),
                leading: Icon(option.icon, size: 18),
                showLabel: selected,
                tooltip: option.title(i18n),
                padding: selected
                    ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                    : const EdgeInsets.all(12),
                label: Text(option.title(i18n)),
              );
            }),
          ],
        ),
      ],
    );
  }
}

class _ManagerTile extends StatelessWidget {
  const _ManagerTile({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.leading,
    required this.actions,
    this.chips = const <String>[],
    this.statusMessage,
    this.statusIsLoading = false,
    this.statusIsError = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData leading;
  final List<Widget> actions;
  final List<String> chips;
  final String? statusMessage;
  final bool statusIsLoading;
  final bool statusIsError;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ToolboxSurfaceCard(
        padding: EdgeInsets.zero,
        borderColor: accent.withValues(alpha: 0.14),
        shadowOpacity: 0.03,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(
              ToolboxUiTokens.sectionPanelRadius,
            ),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(leading, color: accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.3,
                              ),
                            ),
                            if (chips.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: chips
                                    .map(
                                      (chip) => ToolboxInfoPill(
                                        text: chip,
                                        accent: accent,
                                        backgroundColor: theme
                                            .colorScheme
                                            .surfaceContainerLow,
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ],
                            if (statusMessage != null) ...<Widget>[
                              const SizedBox(height: 8),
                              _ManagerTileStatus(
                                message: statusMessage!,
                                accent: accent,
                                isLoading: statusIsLoading,
                                isError: statusIsError,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (actions.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: actions),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ManagerTileStatus extends StatelessWidget {
  const _ManagerTileStatus({
    required this.message,
    required this.accent,
    required this.isLoading,
    required this.isError,
  });

  final String message;
  final Color accent;
  final bool isLoading;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError ? theme.colorScheme.error : accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isError
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.42)
            : accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: accent),
            )
          else
            Icon(
              isError ? Icons.error_outline_rounded : Icons.info_outline,
              size: 16,
              color: color,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isError ? theme.colorScheme.onErrorContainer : color,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagerProcessingOverlay extends StatelessWidget {
  const _ManagerProcessingOverlay({
    required this.message,
    required this.accent,
  });

  final String message;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.scrim.withValues(alpha: 0.18),
      child: Center(
        child: ToolboxSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          borderColor: accent.withValues(alpha: 0.18),
          shadowOpacity: 0.08,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
              ),
              const SizedBox(width: 10),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int _managerInitialBuiltInLimit(bool isEatModule) => isEatModule ? 80 : 120;

int _managerBuiltInPageSize(bool isEatModule) => isEatModule ? 80 : 120;

const _managerActionInspect = 'inspect';
const _managerActionAdjust = 'adjust';
const _managerActionSaveAs = 'save_as';
const _managerDetailActionIds = <String>[
  _managerActionInspect,
  _managerActionAdjust,
  _managerActionSaveAs,
];

String _managerActionKey(String actionId, String optionId) {
  return '$actionId\u0001$optionId';
}

String _managerActionLoadingText(AppI18n i18n, String actionId) {
  return switch (actionId) {
    _managerActionInspect => pickUiText(
      i18n,
      zh: '正在读取菜谱详情...',
      en: 'Loading recipe details...',
    ),
    _managerActionAdjust => pickUiText(
      i18n,
      zh: '正在准备个人调整...',
      en: 'Preparing adjustment...',
    ),
    _managerActionSaveAs => pickUiText(
      i18n,
      zh: '正在准备另存副本...',
      en: 'Preparing a copy...',
    ),
    _ => pickUiText(i18n, zh: '正在处理...', en: 'Working...'),
  };
}

String _managerActionErrorText(AppI18n i18n, String actionId, Object error) {
  return switch (actionId) {
    _managerActionInspect => pickUiText(
      i18n,
      zh: '详情读取失败：$error',
      en: 'Details could not be loaded: $error',
    ),
    _managerActionAdjust => pickUiText(
      i18n,
      zh: '个人调整准备失败：$error',
      en: 'Adjustment could not be prepared: $error',
    ),
    _managerActionSaveAs => pickUiText(
      i18n,
      zh: '另存前读取失败：$error',
      en: 'Copy could not be prepared: $error',
    ),
    _ => pickUiText(i18n, zh: '操作失败：$error', en: 'Action failed: $error'),
  };
}

Widget _managerAsyncActionButton({
  required AppI18n i18n,
  required IconData icon,
  required String labelZh,
  required String labelEn,
  required bool loading,
  required bool enabled,
  required VoidCallback onPressed,
}) {
  return TextButton.icon(
    onPressed: enabled ? onPressed : null,
    icon: loading
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon),
    label: Text(pickUiText(i18n, zh: labelZh, en: labelEn)),
  );
}

List<Widget> _managerCollectionActions({
  required BuildContext context,
  required AppI18n i18n,
  required List<DailyChoiceEatCollection> collections,
  required DailyChoiceEatCollection? selectedCollection,
  required String optionId,
  required ValueChanged<Set<String>> onAddMultiple,
  required ValueChanged<String> onRemove,
}) {
  if (collections.isEmpty) {
    return const <Widget>[];
  }
  final actions = <Widget>[
    TextButton.icon(
      onPressed: () async {
        final selectedIds = await _showEatCollectionPicker(
          context: context,
          i18n: i18n,
          collections: collections,
          optionId: optionId,
        );
        if (selectedIds == null || selectedIds.isEmpty) {
          return;
        }
        onAddMultiple(selectedIds);
      },
      icon: const Icon(Icons.favorite_border_rounded),
      label: Text(pickUiText(i18n, zh: '喜欢/加入', en: 'Like / add')),
    ),
  ];
  if (selectedCollection != null &&
      selectedCollection.containsOption(optionId)) {
    actions.add(
      TextButton.icon(
        onPressed: () => onRemove(selectedCollection.id),
        icon: const Icon(Icons.playlist_remove_rounded),
        label: Text(pickUiText(i18n, zh: '移出当前集合', en: 'Remove from set')),
      ),
    );
  }
  return actions;
}

Future<Set<String>?> _showEatCollectionPicker({
  required BuildContext context,
  required AppI18n i18n,
  required List<DailyChoiceEatCollection> collections,
  required String optionId,
}) {
  final initialSelected = <String>{
    dailyChoiceFavoriteEatCollectionId,
    for (final collection in collections)
      if (collection.containsOption(optionId)) collection.id,
  };
  return showDialog<Set<String>>(
    context: context,
    builder: (context) {
      final selectedIds = initialSelected.toSet();
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(pickUiText(i18n, zh: '喜欢/加入', en: 'Like / add')),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: collections
                      .map(
                        (collection) => CheckboxListTile(
                          value: selectedIds.contains(collection.id),
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == true) {
                                selectedIds.add(collection.id);
                              } else {
                                selectedIds.remove(collection.id);
                              }
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(collection.title(i18n)),
                          subtitle: Text(
                            pickUiText(
                              i18n,
                              zh: '${collection.optionIds.length} 道菜',
                              en: '${collection.optionIds.length} recipes',
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(pickUiText(i18n, zh: '取消', en: 'Cancel')),
              ),
              FilledButton.icon(
                onPressed: selectedIds.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(selectedIds),
                icon: const Icon(Icons.check_rounded),
                label: Text(pickUiText(i18n, zh: '确认加入', en: 'Add')),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<String?> _promptEatCollectionName({
  required BuildContext context,
  required AppI18n i18n,
  required Color accent,
  required String initialTitle,
}) async {
  final controller = TextEditingController(text: initialTitle);
  try {
    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(pickUiText(i18n, zh: '重命名食谱集', en: 'Rename set')),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.bookmarks_rounded),
              labelText: pickUiText(i18n, zh: '食谱集名称', en: 'Set name'),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: accent),
              ),
            ),
            onSubmitted: (value) {
              final title = value.trim();
              if (title.isNotEmpty) {
                Navigator.of(context).pop(title);
              }
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(pickUiText(i18n, zh: '取消', en: 'Cancel')),
            ),
            FilledButton.icon(
              onPressed: () {
                final title = controller.text.trim();
                if (title.isNotEmpty) {
                  Navigator.of(context).pop(title);
                }
              },
              icon: const Icon(Icons.check_rounded),
              label: Text(pickUiText(i18n, zh: '保存', en: 'Save')),
            ),
          ],
        );
      },
    );
  } finally {
    controller.dispose();
  }
}

Future<bool?> _confirmDeleteEatCollection({
  required BuildContext context,
  required AppI18n i18n,
  required DailyChoiceEatCollection collection,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(pickUiText(i18n, zh: '删除食谱集？', en: 'Delete recipe set?')),
        content: Text(
          pickUiText(
            i18n,
            zh: '「${collection.title(i18n)}」只会删除这个集合，不会删除集合里的个人菜谱或内置菜谱。',
            en: '"${collection.title(i18n)}" will be removed as a set. Recipes inside it will not be deleted.',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(pickUiText(i18n, zh: '取消', en: 'Cancel')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(pickUiText(i18n, zh: '删除', en: 'Delete')),
          ),
        ],
      );
    },
  );
}

const _eatCollectionExportFormat =
    'vocabulary_sleep_daily_choice_eat_collection';
const _eatCollectionExportFormatVersion = 1;

Map<String, Object?> _buildEatCollectionExportPackage({
  required DailyChoiceCustomState state,
  required DailyChoiceEatCollection collection,
}) {
  final optionIds = collection.optionIds.toSet();
  final customOptions = state.customOptions
      .where(
        (option) =>
            option.moduleId == DailyChoiceModuleId.eat.storageValue &&
            optionIds.contains(option.id),
      )
      .map((option) => option.toJson())
      .toList(growable: false);
  final adjustedBuiltIns = state.adjustedBuiltInOptions
      .where(
        (option) =>
            option.moduleId == DailyChoiceModuleId.eat.storageValue &&
            optionIds.contains(option.id),
      )
      .map((option) => option.toJson())
      .toList(growable: false);
  return <String, Object?>{
    'format': _eatCollectionExportFormat,
    'formatVersion': _eatCollectionExportFormatVersion,
    'exportedAt': DateTime.now().toIso8601String(),
    'collections': <Object?>[collection.toJson()],
    'customOptions': customOptions,
    'adjustedBuiltInOptions': adjustedBuiltIns,
  };
}

_EatCollectionImportResult _importEatCollectionExportPackage({
  required DailyChoiceCustomState state,
  required Map<String, Object?> payload,
}) {
  if (payload['format'] != _eatCollectionExportFormat) {
    throw const FormatException('Unsupported recipe set package.');
  }
  if (payload['formatVersion'] != _eatCollectionExportFormatVersion) {
    throw const FormatException('Unsupported recipe set package version.');
  }
  final collections = _eatCollectionJsonList(payload['collections'])
      .map(DailyChoiceEatCollection.fromJson)
      .where((collection) {
        return collection.id.trim().isNotEmpty ||
            collection.titleZh.trim().isNotEmpty ||
            collection.titleEn.trim().isNotEmpty;
      })
      .toList(growable: false);
  if (collections.isEmpty) {
    throw const FormatException('Recipe set package has no collections.');
  }

  var next = state.withDefaultEatCollections();
  final existingCustomIds = next.customOptions.map((item) => item.id).toSet();
  final importedOptionIdByOriginalId = <String, String>{};
  var uniqueSeed = DateTime.now().microsecondsSinceEpoch;
  var customCount = 0;
  var adjustedCount = 0;

  for (final raw in _eatCollectionJsonList(payload['customOptions'])) {
    final option = DailyChoiceOption.fromJson(
      raw,
    ).copyWith(moduleId: DailyChoiceModuleId.eat.storageValue, custom: true);
    final originalId = option.id.trim();
    if (originalId.isEmpty) {
      continue;
    }
    var nextId = originalId;
    if (existingCustomIds.contains(nextId)) {
      nextId = 'custom_eat_import_${uniqueSeed++}';
    }
    importedOptionIdByOriginalId[originalId] = nextId;
    existingCustomIds.add(nextId);
    next = next.upsertCustom(
      ensureEatOptionAttributes(option.copyWith(id: nextId, custom: true)),
    );
    customCount += 1;
  }

  for (final raw in _eatCollectionJsonList(payload['adjustedBuiltInOptions'])) {
    final option = DailyChoiceOption.fromJson(
      raw,
    ).copyWith(moduleId: DailyChoiceModuleId.eat.storageValue, custom: false);
    if (option.id.trim().isEmpty) {
      continue;
    }
    next = next.upsertAdjustedBuiltIn(ensureEatOptionAttributes(option));
    adjustedCount += 1;
  }

  var importedCollectionCount = 0;
  var selectedCollectionId = 'all';
  for (final collection in collections) {
    final fallbackTitle = collection.titleZh.trim().isNotEmpty
        ? collection.titleZh.trim()
        : collection.titleEn.trim();
    if (fallbackTitle.isEmpty) {
      continue;
    }
    final collectionId = 'eat_collection_import_${uniqueSeed++}';
    final optionIds = collection.optionIds
        .map((id) => importedOptionIdByOriginalId[id] ?? id)
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
    next = next.upsertEatCollection(
      collection.copyWith(
        id: collectionId,
        titleZh: collection.titleZh.trim().isEmpty
            ? fallbackTitle
            : collection.titleZh.trim(),
        titleEn: collection.titleEn.trim().isEmpty
            ? fallbackTitle
            : collection.titleEn.trim(),
        optionIds: optionIds,
      ),
    );
    selectedCollectionId = collectionId;
    importedCollectionCount += 1;
  }

  if (importedCollectionCount == 0) {
    throw const FormatException('Recipe set package has no valid collections.');
  }
  return _EatCollectionImportResult(
    state: next,
    selectedCollectionId: selectedCollectionId,
    collectionCount: importedCollectionCount,
    customCount: customCount,
    adjustedCount: adjustedCount,
  );
}

List<Map<String, Object?>> _eatCollectionJsonList(Object? raw) {
  if (raw is! List) {
    return const <Map<String, Object?>>[];
  }
  return raw
      .whereType<Map>()
      .map((item) => item.cast<String, Object?>())
      .toList(growable: false);
}

String _safeEatCollectionExportFileName(String title) {
  final normalized = title.trim().replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
  if (normalized.isEmpty) {
    return 'daily_choice_recipe_set';
  }
  return normalized.length > 40 ? normalized.substring(0, 40) : normalized;
}

class _EatCollectionImportResult {
  const _EatCollectionImportResult({
    required this.state,
    required this.selectedCollectionId,
    required this.collectionCount,
    required this.customCount,
    required this.adjustedCount,
  });

  final DailyChoiceCustomState state;
  final String selectedCollectionId;
  final int collectionCount;
  final int customCount;
  final int adjustedCount;
}

Future<bool?> _confirmHideBuiltInRecipe({
  required BuildContext context,
  required AppI18n i18n,
  required DailyChoiceOption option,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(pickUiText(i18n, zh: '确认不喜欢？', en: 'Hide this recipe?')),
        content: Text(
          pickUiText(
            i18n,
            zh: '「${option.title(i18n)}」会从随机候选中隐藏，之后仍可在管理页恢复。',
            en: '"${option.title(i18n)}" will be hidden from random picks. You can restore it later in Manage.',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(pickUiText(i18n, zh: '取消', en: 'Cancel')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.remove_circle_outline_rounded),
            label: Text(pickUiText(i18n, zh: '确认不喜欢', en: 'Hide')),
          ),
        ],
      );
    },
  );
}

List<String> _splitLines(String raw) {
  return raw
      .split(RegExp(r'[\n\r]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<String> _splitTags(String raw) {
  return raw
      .split(RegExp(r'[、，,\s]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList(growable: false);
}

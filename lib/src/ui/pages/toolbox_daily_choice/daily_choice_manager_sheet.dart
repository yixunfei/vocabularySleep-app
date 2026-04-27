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
  var localState = state;
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
  var managerStateVersion = 0;
  var builtInFilterCacheKey = '';
  List<DailyChoiceOption> builtInFilterCache = const <DailyChoiceOption>[];

  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void publish(DailyChoiceCustomState next) {
              localState = next;
              managerStateVersion += 1;
              onStateChanged(next);
              setSheetState(() {});
            }

            void resetBuiltInPaging() {
              builtInVisibleLimit = _managerInitialBuiltInLimit(isEatModule);
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
              stateVersion: managerStateVersion,
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
              allVisibleBuiltIns = builtInSqlActiveKey == sqlKey
                  ? builtInSqlOptions
                  : const <DailyChoiceOption>[];
              builtInTotalCount = builtInSqlActiveKey == sqlKey
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
              publish(nextState);
            }

            Future<void> openAdjustmentEditor(DailyChoiceOption option) async {
              if (onAdjustBuiltInOption == null) {
                return;
              }
              final result = await onAdjustBuiltInOption(option);
              if (result == null) {
                return;
              }
              publish(localState.upsertAdjustedBuiltIn(result));
            }

            Future<void> saveBuiltInAsCustom(DailyChoiceOption option) async {
              if (onSaveBuiltInAsCustom == null) {
                return;
              }
              final result = await onSaveBuiltInAsCustom(option);
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
              publish(nextState);
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

            return SafeArea(
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.82,
                minChildSize: 0.48,
                maxChildSize: 0.94,
                builder: (context, controller) {
                  return ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                    children: <Widget>[
                      Text(
                        pickUiText(i18n, zh: '自定义管理', en: 'Custom manager'),
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
                          child: TextField(
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search_rounded),
                              labelText: pickUiText(
                                i18n,
                                zh: '搜索菜品名称',
                                en: 'Search recipe name',
                              ),
                              hintText: pickUiText(
                                i18n,
                                zh: '按菜名、简介关键词快速筛选',
                                en: 'Search by recipe title or summary',
                              ),
                            ),
                            onChanged: (value) {
                              setSheetState(() {
                                searchQuery = value.trim();
                                resetBuiltInPaging();
                              });
                            },
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
                          countLabel: '${localState.eatCollections.length}',
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
                                onFieldSubmitted: (_) => createCollection(),
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
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  ToolboxSelectablePill(
                                    selected: selectedCollectionId == 'all',
                                    tint: accent,
                                    onTap: () {
                                      setSheetState(() {
                                        selectedCollectionId = 'all';
                                        resetBuiltInPaging();
                                      });
                                    },
                                    leading: const Icon(
                                      Icons.all_inclusive_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      pickUiText(
                                        i18n,
                                        zh: '全部菜谱',
                                        en: 'All recipes',
                                      ),
                                    ),
                                  ),
                                  ...localState.eatCollections.map(
                                    (collection) => ToolboxSelectablePill(
                                      selected:
                                          selectedCollectionId == collection.id,
                                      tint: accent,
                                      onTap: () {
                                        setSheetState(() {
                                          selectedCollectionId = collection.id;
                                          resetBuiltInPaging();
                                        });
                                      },
                                      leading: const Icon(
                                        Icons.bookmarks_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        '${collection.title(i18n)} · ${collection.optionIds.length}',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (localState
                                  .eatCollections
                                  .isNotEmpty) ...<Widget>[
                                const SizedBox(height: 12),
                                Column(
                                  children: localState.eatCollections
                                      .map(
                                        (collection) => _ManagerTile(
                                          title: collection.title(i18n),
                                          subtitle: pickUiText(
                                            i18n,
                                            zh: '${collection.optionIds.length} 道菜',
                                            en: '${collection.optionIds.length} recipes',
                                          ),
                                          accent: accent,
                                          leading: Icons.bookmarks_rounded,
                                          chips:
                                              selectedCollectionId ==
                                                  collection.id
                                              ? <String>[
                                                  pickUiText(
                                                    i18n,
                                                    zh: '当前范围',
                                                    en: 'Active',
                                                  ),
                                                ]
                                              : const <String>[],
                                          actions: <Widget>[
                                            TextButton.icon(
                                              onPressed: () {
                                                setSheetState(() {
                                                  selectedCollectionId =
                                                      selectedCollectionId ==
                                                          collection.id
                                                      ? 'all'
                                                      : collection.id;
                                                  resetBuiltInPaging();
                                                });
                                              },
                                              icon: const Icon(
                                                Icons.filter_list_rounded,
                                              ),
                                              label: Text(
                                                selectedCollectionId ==
                                                        collection.id
                                                    ? pickUiText(
                                                        i18n,
                                                        zh: '取消只看',
                                                        en: 'Show all',
                                                      )
                                                    : pickUiText(
                                                        i18n,
                                                        zh: '只看',
                                                        en: 'Filter',
                                                      ),
                                              ),
                                            ),
                                            TextButton.icon(
                                              onPressed: () {
                                                if (selectedCollectionId ==
                                                    collection.id) {
                                                  selectedCollectionId = 'all';
                                                }
                                                resetBuiltInPaging();
                                                publish(
                                                  localState
                                                      .deleteEatCollection(
                                                        collection.id,
                                                      ),
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.delete_outline_rounded,
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
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _ManagerExpandableSection(
                        title: pickUiText(i18n, zh: '筛选条件', en: 'Filters'),
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
                                onSelected: (value) {
                                  setSheetState(() {
                                    selectedContextId = value;
                                    resetBuiltInPaging();
                                  });
                                },
                              ),
                            ],
                            if (managerTraitGroups.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 12),
                              for (final group
                                  in managerTraitGroups) ...<Widget>[
                                _ManagerTraitFilterSection(
                                  i18n: i18n,
                                  accent: accent,
                                  group: group,
                                  selectedId:
                                      selectedTraitFilters[group.id] ?? 'all',
                                  onSelected: (value) {
                                    setSheetState(() {
                                      selectedTraitFilters[group.id] = value;
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
                                            onPressed: () => openEditor(item),
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
                                            i18n: i18n,
                                            collections:
                                                localState.eatCollections,
                                            selectedCollection:
                                                selectedCollection,
                                            optionId: item.id,
                                            onAdd: (collectionId) {
                                              publish(
                                                localState
                                                    .addOptionToEatCollection(
                                                      collectionId:
                                                          collectionId,
                                                      optionId: item.id,
                                                    ),
                                              );
                                            },
                                            onRemove: (collectionId) {
                                              publish(
                                                localState
                                                    .removeOptionFromEatCollection(
                                                      collectionId:
                                                          collectionId,
                                                      optionId: item.id,
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
                                              Icons.delete_outline_rounded,
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
                                      .map(
                                        (item) => _ManagerTile(
                                          title: item.title(i18n),
                                          subtitle: item.subtitle(i18n),
                                          accent: accent,
                                          leading: hidden.contains(item.id)
                                              ? Icons.visibility_off_rounded
                                              : Icons.tune_rounded,
                                          onTap: onInspectOption == null
                                              ? null
                                              : () => onInspectOption(item),
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
                                            if (onAdjustBuiltInOption != null)
                                              TextButton.icon(
                                                onPressed: () =>
                                                    openAdjustmentEditor(item),
                                                icon: const Icon(
                                                  Icons.tune_rounded,
                                                ),
                                                label: Text(
                                                  pickUiText(
                                                    i18n,
                                                    zh: '继续调整',
                                                    en: 'Adjust',
                                                  ),
                                                ),
                                              ),
                                            if (onSaveBuiltInAsCustom != null)
                                              TextButton.icon(
                                                onPressed: () =>
                                                    saveBuiltInAsCustom(item),
                                                icon: const Icon(
                                                  Icons.copy_rounded,
                                                ),
                                                label: Text(
                                                  pickUiText(
                                                    i18n,
                                                    zh: '另存',
                                                    en: 'Save as',
                                                  ),
                                                ),
                                              ),
                                            ..._managerCollectionActions(
                                              i18n: i18n,
                                              collections:
                                                  localState.eatCollections,
                                              selectedCollection:
                                                  selectedCollection,
                                              optionId: item.id,
                                              onAdd: (collectionId) {
                                                publish(
                                                  localState
                                                      .addOptionToEatCollection(
                                                        collectionId:
                                                            collectionId,
                                                        optionId: item.id,
                                                      ),
                                                );
                                              },
                                              onRemove: (collectionId) {
                                                publish(
                                                  localState
                                                      .removeOptionFromEatCollection(
                                                        collectionId:
                                                            collectionId,
                                                        optionId: item.id,
                                                      ),
                                                );
                                              },
                                            ),
                                            TextButton.icon(
                                              onPressed: () {
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
                                        ),
                                      )
                                      .toList(growable: false),
                                ),
                        ),
                      _ManagerExpandableSection(
                        title: pickUiText(
                          i18n,
                          zh: '内置条目',
                          en: 'Built-in items',
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
                                  ? pickUiText(i18n, zh: '加载中', en: 'Loading')
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
                        child: builtInSqlLoading && visibleBuiltIns.isEmpty
                            ? _ManagerHint(
                                text: pickUiText(
                                  i18n,
                                  zh: '正在读取内置菜谱...',
                                  en: 'Loading built-in recipes...',
                                ),
                              )
                            : builtInSqlError != null && visibleBuiltIns.isEmpty
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
                                        adjustedById[baseItem.id] ?? baseItem;
                                    final isHidden = hidden.contains(
                                      baseItem.id,
                                    );
                                    final hasAdjustment = adjustedById
                                        .containsKey(baseItem.id);
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
                                      onTap: onInspectOption == null
                                          ? null
                                          : () => onInspectOption(displayItem),
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
                                          TextButton.icon(
                                            onPressed: () =>
                                                openAdjustmentEditor(
                                                  displayItem,
                                                ),
                                            icon: const Icon(
                                              Icons.tune_rounded,
                                            ),
                                            label: Text(
                                              pickUiText(
                                                i18n,
                                                zh: hasAdjustment
                                                    ? '继续调整'
                                                    : '个人调整',
                                                en: hasAdjustment
                                                    ? 'Adjust more'
                                                    : 'Adjust',
                                              ),
                                            ),
                                          ),
                                        if (onSaveBuiltInAsCustom != null)
                                          TextButton.icon(
                                            onPressed: () =>
                                                saveBuiltInAsCustom(
                                                  displayItem,
                                                ),
                                            icon: const Icon(
                                              Icons.copy_rounded,
                                            ),
                                            label: Text(
                                              pickUiText(
                                                i18n,
                                                zh: '另存',
                                                en: 'Save as',
                                              ),
                                            ),
                                          ),
                                        ..._managerCollectionActions(
                                          i18n: i18n,
                                          collections:
                                              localState.eatCollections,
                                          selectedCollection:
                                              selectedCollection,
                                          optionId: baseItem.id,
                                          onAdd: (collectionId) {
                                            publish(
                                              localState
                                                  .addOptionToEatCollection(
                                                    collectionId: collectionId,
                                                    optionId: baseItem.id,
                                                  ),
                                            );
                                          },
                                          onRemove: (collectionId) {
                                            publish(
                                              localState
                                                  .removeOptionFromEatCollection(
                                                    collectionId: collectionId,
                                                    optionId: baseItem.id,
                                                  ),
                                            );
                                          },
                                        ),
                                        if (hasAdjustment)
                                          TextButton.icon(
                                            onPressed: () {
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
                                          onPressed: () {
                                            publish(
                                              isHidden
                                                  ? localState.restoreBuiltIn(
                                                      baseItem.id,
                                                    )
                                                  : localState.hideBuiltIn(
                                                      baseItem.id,
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
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        setSheetState(() {
                                          builtInVisibleLimit +=
                                              _managerBuiltInPageSize(
                                                isEatModule,
                                              );
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.expand_more_rounded,
                                      ),
                                      label: Text(
                                        pickUiText(
                                          i18n,
                                          zh: '继续加载 ${_managerNextPageCount(builtInTotalCount, visibleBuiltIns.length, isEatModule)} 条',
                                          en: 'Load ${_managerNextPageCount(builtInTotalCount, visibleBuiltIns.length, isEatModule)} more',
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
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
  required int stateVersion,
}) {
  final traitKey =
      traitFilters.entries
          .map((entry) => '${entry.key}:${entry.value}')
          .toList(growable: false)
        ..sort();
  return <String>[
    '$stateVersion',
    moduleId,
    categoryId,
    contextId ?? '',
    selectedCollectionId,
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
              ? '不喜欢会隐藏内置菜；个人调整会覆盖原菜谱参与随机；个人食谱保存在本机并参与高级筛选。'
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
        : '当前筛选下没有内置条目，换一个分类或上下文试试。',
    en: isWearModule
        ? 'No built-in outfits match this filter.'
        : 'No built-in items match this filter.',
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
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
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
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ToolboxSelectablePill(
              selected: selectedId == 'all',
              tint: accent,
              onTap: () => onSelected('all'),
              leading: const Icon(Icons.grid_view_rounded, size: 18),
              label: Text(pickUiText(i18n, zh: '全部', en: 'All')),
            ),
            ...group.options.map(
              (option) => ToolboxSelectablePill(
                selected: selectedId == option.id,
                tint: accent,
                onTap: () => onSelected(option.id),
                leading: Icon(option.icon, size: 18),
                label: Text(option.title(i18n)),
              ),
            ),
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
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData leading;
  final List<Widget> actions;
  final List<String> chips;
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

int _managerInitialBuiltInLimit(bool isEatModule) => isEatModule ? 80 : 120;

int _managerBuiltInPageSize(bool isEatModule) => isEatModule ? 80 : 120;

int _managerNextPageCount(int total, int visible, bool isEatModule) {
  final remaining = total - visible;
  if (remaining <= 0) {
    return 0;
  }
  final pageSize = _managerBuiltInPageSize(isEatModule);
  return remaining < pageSize ? remaining : pageSize;
}

List<Widget> _managerCollectionActions({
  required AppI18n i18n,
  required List<DailyChoiceEatCollection> collections,
  required DailyChoiceEatCollection? selectedCollection,
  required String optionId,
  required ValueChanged<String> onAdd,
  required ValueChanged<String> onRemove,
}) {
  if (collections.isEmpty) {
    return const <Widget>[];
  }
  if (selectedCollection != null &&
      selectedCollection.containsOption(optionId)) {
    return <Widget>[
      TextButton.icon(
        onPressed: () => onRemove(selectedCollection.id),
        icon: const Icon(Icons.playlist_remove_rounded),
        label: Text(pickUiText(i18n, zh: '移出集合', en: 'Remove from set')),
      ),
    ];
  }
  final availableCollections = collections
      .where((collection) => !collection.containsOption(optionId))
      .toList(growable: false);
  if (availableCollections.isEmpty) {
    return const <Widget>[];
  }
  return <Widget>[
    PopupMenuButton<String>(
      tooltip: pickUiText(i18n, zh: '加入食谱集', en: 'Add to set'),
      onSelected: onAdd,
      itemBuilder: (context) {
        return availableCollections
            .map(
              (collection) => PopupMenuItem<String>(
                value: collection.id,
                child: Text(collection.title(i18n)),
              ),
            )
            .toList(growable: false);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.playlist_add_rounded, size: 18),
            const SizedBox(width: 6),
            Text(pickUiText(i18n, zh: '加入集合', en: 'Add to set')),
          ],
        ),
      ),
    ),
  ];
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

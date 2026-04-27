part of 'daily_choice_hub.dart';

class _EatChoiceModule extends StatefulWidget {
  const _EatChoiceModule({
    super.key,
    required this.i18n,
    required this.accent,
    required this.libraryStore,
    required this.libraryStatus,
    required this.libraryLoading,
    required this.libraryInstalling,
    required this.onInstallLibrary,
    required this.catalog,
    required this.rawBuiltInOptions,
    required this.builtInOptions,
    required this.customState,
    required this.onStateChanged,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoiceEatLibraryStore libraryStore;
  final DailyChoiceEatLibraryStatus libraryStatus;
  final bool libraryLoading;
  final bool libraryInstalling;
  final Future<void> Function() onInstallLibrary;
  final DailyChoiceEatCatalog catalog;
  final List<DailyChoiceOption> rawBuiltInOptions;
  final List<DailyChoiceOption> builtInOptions;
  final DailyChoiceCustomState customState;
  final ValueChanged<DailyChoiceCustomState> onStateChanged;

  @override
  State<_EatChoiceModule> createState() => _EatChoiceModuleState();
}

class _EatChoiceModuleState extends State<_EatChoiceModule> {
  String _mealId = 'all';
  String _toolId = 'all';
  String _collectionId = 'all';
  bool _libraryStatusExpanded = false;
  bool _advancedExpanded = false;
  bool _preferAvailableIngredients = false;
  late final TextEditingController _ingredientInputController;
  late final TextEditingController _customAvoidInputController;
  late DailyChoiceEatCatalogFilterResult _filterResult;
  final Map<String, Set<String>> _selectedTraitFilters = <String, Set<String>>{
    eatAttributeType: <String>{},
    eatAttributeProfile: <String>{},
  };
  final Set<String> _excludedContains = <String>{};
  final List<String> _availableIngredients = <String>[];
  final List<String> _customExcludedIngredients = <String>[];
  bool _openingDetail = false;

  @override
  void initState() {
    super.initState();
    _ingredientInputController = TextEditingController();
    _customAvoidInputController = TextEditingController();
    _filterResult = _buildFilterResult();
  }

  @override
  void didUpdateWidget(covariant _EatChoiceModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    var shouldRebuildFilter = !identical(oldWidget.catalog, widget.catalog);
    var shouldResetCollection = false;
    final selectedCollectionStillExists =
        _collectionId == 'all' ||
        widget.customState.eatCollectionById(_collectionId) != null;
    if (!selectedCollectionStillExists) {
      shouldResetCollection = true;
      shouldRebuildFilter = true;
    } else if (_collectionId != 'all' &&
        !identical(
          oldWidget.customState.eatCollections,
          widget.customState.eatCollections,
        )) {
      shouldRebuildFilter = true;
    }
    if (shouldRebuildFilter) {
      setState(() {
        if (shouldResetCollection) {
          _collectionId = 'all';
        }
        _filterResult = _buildFilterResult();
      });
    }
  }

  @override
  void dispose() {
    _ingredientInputController.dispose();
    _customAvoidInputController.dispose();
    super.dispose();
  }

  bool get _hasAdvancedFilters {
    if (_preferAvailableIngredients && _availableIngredients.isNotEmpty) {
      return true;
    }
    if (_customExcludedIngredients.isNotEmpty) {
      return true;
    }
    if (_excludedContains.isNotEmpty) {
      return true;
    }
    return _selectedTraitFilters.values.any((values) => values.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final category = eatMealFilterCategories.firstWhere(
      (item) => item.id == _mealId,
    );
    final tool = cookToolCategories.firstWhere((item) => item.id == _toolId);
    final selectedCollection = _selectedCollection;
    final eatCollections = widget.customState
        .withDefaultEatCollections()
        .eatCollections;
    final eligible = _filterResult.eligibleOptions;
    final displayed = _filterResult.randomPool;
    final showLibraryPanel =
        !widget.libraryStatus.hasInstalledLibrary ||
        widget.libraryLoading ||
        widget.libraryInstalling ||
        widget.libraryStatus.errorMessage != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DailyChoiceCategorySelector(
          i18n: widget.i18n,
          title: pickUiText(widget.i18n, zh: '选择餐段', en: 'Meal moment'),
          categories: eatMealFilterCategories,
          selectedId: _mealId,
          accent: widget.accent,
          onSelected: (value) => _applyFilterUpdate(() {
            _mealId = value;
          }),
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        DailyChoiceCategorySelector(
          i18n: widget.i18n,
          title: pickUiText(widget.i18n, zh: '选择厨具', en: 'Cooking tool'),
          categories: cookToolCategories,
          selectedId: _toolId,
          accent: widget.accent,
          onSelected: (value) => _applyFilterUpdate(() {
            _toolId = value;
          }),
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        _EatCollectionSelectorPanel(
          i18n: widget.i18n,
          accent: widget.accent,
          selectedCollectionId: _collectionId,
          collections: eatCollections,
          onSelected: (value) {
            _applyFilterUpdate(() {
              _collectionId = value;
            });
          },
        ),
        if (showLibraryPanel) ...<Widget>[
          const SizedBox(height: ToolboxUiTokens.cardSpacing),
          _EatLibraryStatusPanel(
            i18n: widget.i18n,
            accent: widget.accent,
            libraryStatus: widget.libraryStatus,
            libraryLoading: widget.libraryLoading,
            libraryInstalling: widget.libraryInstalling,
            onInstallLibrary: widget.onInstallLibrary,
            candidateCount: displayed.length,
            expanded: _libraryStatusExpanded,
            onToggleExpanded: () {
              setState(() {
                _libraryStatusExpanded = !_libraryStatusExpanded;
              });
            },
          ),
        ],
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        _EatAdvancedSettingsPanel(
          i18n: widget.i18n,
          accent: widget.accent,
          expanded: _advancedExpanded,
          preferAvailableIngredients: _preferAvailableIngredients,
          ingredientInputController: _ingredientInputController,
          availableIngredients: _availableIngredients,
          customAvoidInputController: _customAvoidInputController,
          customExcludedIngredients: _customExcludedIngredients,
          selectedTraitFilters: _selectedTraitFilters,
          excludedContains: _excludedContains,
          onExpandedChanged: () {
            _applyFilterUpdate(() {
              _advancedExpanded = !_advancedExpanded;
            });
          },
          onPreferIngredientsChanged: (value) {
            _applyFilterUpdate(() {
              _preferAvailableIngredients = value;
            });
          },
          onAddAvailableIngredients: _addAvailableIngredients,
          onRemoveAvailableIngredient: _removeAvailableIngredient,
          onAddCustomAvoids: _addCustomAvoids,
          onRemoveCustomAvoid: _removeCustomAvoid,
          onToggleTrait: _toggleTraitFilter,
          onToggleContains: _toggleContainsFilter,
          onClearAll: _clearAdvancedFilters,
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        DailyChoiceRandomPanel(
          i18n: widget.i18n,
          accent: widget.accent,
          title: pickUiText(
            widget.i18n,
            zh: _toolId == 'all'
                ? '${category.titleZh}吃什么'
                : '${tool.titleZh} · ${category.titleZh}吃什么',
            en: _toolId == 'all'
                ? 'What for ${category.titleEn.toLowerCase()}'
                : '${tool.titleEn} · ${category.titleEn}',
          ),
          subtitle: _buildRandomPanelSubtitle(
            category,
            tool,
            eligible,
            displayed,
            selectedCollection,
          ),
          options: displayed,
          emptyText: pickUiText(
            widget.i18n,
            zh: selectedCollection != null
                ? '这个食谱集在当前筛选下没有可选菜品。可以放宽筛选、向集合加入菜谱，或切回内置菜谱。'
                : (_hasAdvancedFilters
                      ? '当前筛选条件有点严，没有找到合适菜品。可以放宽高级设置、换厨具，或在管理里新增你的个人菜谱。'
                      : (_toolId == 'all'
                            ? '这个餐段已经没有可选菜品，可以在管理里恢复内置菜或新增个人食谱。'
                            : '这个餐段和厨具组合下暂时没有菜品，可以换一个厨具、恢复隐藏菜，或补充你的个人食谱。')),
            en: selectedCollection != null
                ? 'This recipe set has no dishes under the current filters. Relax filters, add recipes to the set, or switch back to built-in recipes.'
                : (_hasAdvancedFilters
                      ? 'The current filters are too strict. Relax advanced settings, switch tools, or add your own recipe in Manage.'
                      : (_toolId == 'all'
                            ? 'No dishes left for this meal. Restore built-ins or add a personal recipe in Manage.'
                            : 'No dishes match this meal and tool yet. Try another tool, restore hidden dishes, or add a personal recipe.')),
          ),
          onDetail: (option) => unawaited(_openOptionDetail(option)),
          onGuide: () => unawaited(_openGuide()),
          onManage: () => unawaited(_openManager()),
        ),
      ],
    );
  }

  DailyChoiceEatCollection? get _selectedCollection {
    if (_collectionId == 'all') {
      return null;
    }
    return widget.customState.eatCollectionById(_collectionId);
  }

  DailyChoiceEatCatalogFilterResult _buildFilterResult() {
    final collection = _selectedCollection;
    return widget.catalog.filter(
      mealId: _mealId,
      toolId: _toolId,
      selectedTraitFilters: _selectedTraitFilters,
      excludedContains: _excludedContains,
      customExcludedIngredients: _customExcludedIngredients,
      availableIngredients: _availableIngredients,
      preferAvailableIngredients: _preferAvailableIngredients,
      allowedOptionIds: collection?.optionIds,
    );
  }

  String _buildRandomPanelSubtitle(
    DailyChoiceCategory category,
    DailyChoiceCategory tool,
    List<DailyChoiceOption> eligible,
    List<DailyChoiceOption> displayed,
    DailyChoiceEatCollection? selectedCollection,
  ) {
    String withCollection(String text) {
      if (selectedCollection == null) {
        return text;
      }
      return '${selectedCollection.title(widget.i18n)} · $text';
    }

    if (_preferAvailableIngredients && _availableIngredients.isNotEmpty) {
      final ingredientSummary = _availableIngredients
          .take(4)
          .map(eatTokenLabelZh)
          .join('、');
      final priority = _filterResult.ingredientPriority;
      return withCollection(
        pickUiText(
          widget.i18n,
          zh: switch (priority.stage) {
            DailyChoiceEatIngredientMatchStage.exact =>
              priority.broadenedForVariety
                  ? '已先按全命中食材收口，再补入高重叠候选保持随机性。当前食材：$ingredientSummary。'
                  : '已按全命中食材优先。当前食材：$ingredientSummary。',
            DailyChoiceEatIngredientMatchStage.strong =>
              '没有找到全命中菜谱，已按高重叠食材优先。当前食材：$ingredientSummary。',
            DailyChoiceEatIngredientMatchStage.broad =>
              '没有高重叠命中，已保留至少命中 1 项材料的相关菜谱。当前食材：$ingredientSummary。',
            DailyChoiceEatIngredientMatchStage.none =>
              '暂时没有命中现有食材，仍保留当前筛选范围内的完整候选。当前食材：$ingredientSummary。',
          },
          en: switch (priority.stage) {
            DailyChoiceEatIngredientMatchStage.exact =>
              priority.broadenedForVariety
                  ? 'Exact ingredient matches lead the pool, then strong overlaps are added for variety.'
                  : 'Exact ingredient matches lead the pool.',
            DailyChoiceEatIngredientMatchStage.strong =>
              'No exact match yet, so the pool prefers strong ingredient overlaps.',
            DailyChoiceEatIngredientMatchStage.broad =>
              'No strong overlap yet, so the pool keeps recipes that match at least one ingredient.',
            DailyChoiceEatIngredientMatchStage.none =>
              'No ingredient hit yet, so the full filtered pool stays available.',
          },
        ),
      );
    }
    if (_toolId == 'all') {
      return withCollection(category.subtitle(widget.i18n));
    }
    return withCollection(
      pickUiText(
        widget.i18n,
        zh: '${tool.subtitleZh}。${category.subtitleZh}',
        en: '${tool.subtitleEn}. ${category.subtitleEn}',
      ),
    );
  }

  void _applyFilterUpdate(VoidCallback update) {
    setState(() {
      update();
      _filterResult = _buildFilterResult();
    });
  }

  void _toggleTraitFilter(String groupId, String optionId) {
    _applyFilterUpdate(() {
      final values = _selectedTraitFilters[groupId] ?? <String>{};
      if (values.contains(optionId)) {
        values.remove(optionId);
      } else {
        values.add(optionId);
      }
      _selectedTraitFilters[groupId] = values;
    });
  }

  void _toggleContainsFilter(String optionId) {
    _applyFilterUpdate(() {
      if (_excludedContains.contains(optionId)) {
        _excludedContains.remove(optionId);
      } else {
        _excludedContains.add(optionId);
      }
    });
  }

  void _clearAdvancedFilters() {
    _applyFilterUpdate(() {
      _preferAvailableIngredients = false;
      _ingredientInputController.clear();
      _customAvoidInputController.clear();
      _availableIngredients.clear();
      _customExcludedIngredients.clear();
      for (final key in _selectedTraitFilters.keys.toList(growable: false)) {
        _selectedTraitFilters[key] = <String>{};
      }
      _excludedContains.clear();
    });
  }

  void _addAvailableIngredients() {
    final nextTokens = normalizeEatIngredientInputs(<String>[
      _ingredientInputController.text,
    ]);
    if (nextTokens.isEmpty) {
      return;
    }
    _applyFilterUpdate(() {
      for (final token in nextTokens) {
        if (!_availableIngredients.contains(token)) {
          _availableIngredients.add(token);
        }
      }
      _ingredientInputController.clear();
    });
  }

  void _removeAvailableIngredient(String token) {
    _applyFilterUpdate(() {
      _availableIngredients.remove(token);
    });
  }

  void _addCustomAvoids() {
    final nextTokens = normalizeEatIngredientInputs(<String>[
      _customAvoidInputController.text,
    ]);
    if (nextTokens.isEmpty) {
      return;
    }
    _applyFilterUpdate(() {
      for (final token in nextTokens) {
        if (!_customExcludedIngredients.contains(token)) {
          _customExcludedIngredients.add(token);
        }
      }
      _customAvoidInputController.clear();
    });
  }

  void _removeCustomAvoid(String token) {
    _applyFilterUpdate(() {
      _customExcludedIngredients.remove(token);
    });
  }

  Future<void> _openGuide() async {
    await showDailyChoiceGuideSheet(
      context: context,
      i18n: widget.i18n,
      accent: widget.accent,
      title: pickUiText(widget.i18n, zh: '做菜之前', en: 'Before cooking'),
      modules: buildCookingGuideModules(widget.libraryStatus.referenceTitles),
    );
  }

  Future<void> _openManager() async {
    await showDailyChoiceManagerSheet(
      context: context,
      i18n: widget.i18n,
      accent: widget.accent,
      moduleId: 'eat',
      builtInOptions: widget.rawBuiltInOptions,
      state: widget.customState,
      onStateChanged: widget.onStateChanged,
      categories: mealCategories,
      initialCategoryId: _mealId,
      contexts: cookToolCategories,
      initialContextId: _toolId,
      contextLabelZh: '厨具',
      contextLabelEn: 'Tool',
      eatLibraryStore: widget.libraryStore,
      onInspectOption: (option) =>
          _openOptionDetail(option, reportErrors: false),
      onAdjustBuiltInOption: _openAdjustmentEditor,
      onSaveBuiltInAsCustom: _openSaveAsCustomEditor,
    );
  }

  Future<void> _openOptionDetail(
    DailyChoiceOption option, {
    bool reportErrors = true,
  }) async {
    if (_openingDetail) {
      return;
    }
    setState(() {
      _openingDetail = true;
    });
    try {
      final resolved = await _resolveDetailOption(option);
      if (!mounted) {
        return;
      }
      await showDailyChoiceDetailSheet(
        context: context,
        i18n: widget.i18n,
        accent: widget.accent,
        option: resolved,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      if (reportErrors) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pickUiText(
                widget.i18n,
                zh: '读取菜谱详情失败：$error',
                en: 'Failed to load recipe details: $error',
              ),
            ),
          ),
        );
      }
      if (!reportErrors) {
        rethrow;
      }
    } finally {
      if (mounted) {
        setState(() {
          _openingDetail = false;
        });
      }
    }
  }

  Future<DailyChoiceOption> _resolveDetailOption(
    DailyChoiceOption option,
  ) async {
    final alreadyDetailed =
        option.custom ||
        option.detailsZh.trim().isNotEmpty ||
        option.stepsZh.isNotEmpty ||
        option.materialsZh.isNotEmpty;
    if (alreadyDetailed) {
      return option;
    }

    final shouldLoadBuiltInDetail =
        option.moduleId == DailyChoiceModuleId.eat.storageValue &&
        !option.custom &&
        widget.libraryStatus.hasInstalledLibrary &&
        option.id.trim().isNotEmpty;
    if (!shouldLoadBuiltInDetail) {
      return option;
    }
    return await widget.libraryStore.loadBuiltInDetail(option.id) ?? option;
  }

  Future<DailyChoiceOption?> _openAdjustmentEditor(
    DailyChoiceOption option,
  ) async {
    final resolved = await _resolveDetailOption(option);
    if (!mounted) {
      return null;
    }
    return showDailyChoiceEditorSheet(
      context: context,
      i18n: widget.i18n,
      accent: widget.accent,
      moduleId: 'eat',
      categories: mealCategories,
      initialCategoryId: resolved.categoryId,
      contexts: cookToolCategories,
      initialContextId: resolved.contextId,
      contextLabelZh: '厨具',
      contextLabelEn: 'Tool',
      option: resolved,
    );
  }

  Future<DailyChoiceOption?> _openSaveAsCustomEditor(
    DailyChoiceOption option,
  ) async {
    final resolved = await _resolveDetailOption(option);
    if (!mounted) {
      return null;
    }
    return showDailyChoiceEditorSheet(
      context: context,
      i18n: widget.i18n,
      accent: widget.accent,
      moduleId: 'eat',
      categories: mealCategories,
      initialCategoryId: resolved.categoryId,
      contexts: cookToolCategories,
      initialContextId: resolved.contextId,
      contextLabelZh: '厨具',
      contextLabelEn: 'Tool',
      option: resolved,
      forceNewId: true,
    );
  }
}

class _EatLibraryStatusPanel extends StatelessWidget {
  const _EatLibraryStatusPanel({
    required this.i18n,
    required this.accent,
    required this.libraryStatus,
    required this.libraryLoading,
    required this.libraryInstalling,
    required this.onInstallLibrary,
    required this.candidateCount,
    required this.expanded,
    required this.onToggleExpanded,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoiceEatLibraryStatus libraryStatus;
  final bool libraryLoading;
  final bool libraryInstalling;
  final Future<void> Function() onInstallLibrary;
  final int candidateCount;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasInstalledLibrary = libraryStatus.hasInstalledLibrary;
    final busy = libraryLoading || libraryInstalling;
    final updatedAt = libraryStatus.updatedAt ?? libraryStatus.installedAt;
    final updatedLabel = updatedAt == null
        ? null
        : '${updatedAt.year}-${updatedAt.month.toString().padLeft(2, '0')}-${updatedAt.day.toString().padLeft(2, '0')} ${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')}';
    final compactStatusLabel = libraryLoading
        ? pickUiText(i18n, zh: '加载中', en: 'Loading')
        : !hasInstalledLibrary
        ? pickUiText(i18n, zh: '尚未加载', en: 'Not installed')
        : libraryInstalling
        ? pickUiText(i18n, zh: '加载中', en: 'Loading')
        : pickUiText(i18n, zh: '已就绪', en: 'Ready');

    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(14),
      radius: ToolboxUiTokens.sectionPanelRadius,
      borderColor: accent.withValues(alpha: 0.18),
      shadowColor: accent,
      shadowOpacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  pickUiText(i18n, zh: '资源准备', en: 'Recipe resources'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ToolboxInfoPill(
                text: compactStatusLabel,
                accent: accent,
                backgroundColor: accent.withValues(alpha: 0.12),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: pickUiText(
                  i18n,
                  zh: expanded ? '收起' : '展开',
                  en: expanded ? 'Collapse' : 'Expand',
                ),
                onPressed: onToggleExpanded,
                icon: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
              ),
            ],
          ),
          if (hasInstalledLibrary) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ToolboxInfoPill(
                  text: pickUiText(
                    i18n,
                    zh: '总库 ${libraryStatus.recipeCount}',
                    en: 'Total ${libraryStatus.recipeCount}',
                  ),
                  accent: accent,
                  backgroundColor: theme.colorScheme.surfaceContainerLow,
                ),
                ToolboxInfoPill(
                  text: pickUiText(
                    i18n,
                    zh: '当前池 $candidateCount',
                    en: 'Pool $candidateCount',
                  ),
                  accent: accent,
                  backgroundColor: theme.colorScheme.surfaceContainerLow,
                ),
              ],
            ),
          ],
          if (!hasInstalledLibrary) ...<Widget>[
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: busy ? null : () => unawaited(onInstallLibrary()),
              icon: Icon(
                busy
                    ? Icons.hourglass_top_rounded
                    : Icons.cloud_download_rounded,
              ),
              label: Text(
                pickUiText(
                  i18n,
                  zh: busy ? '正在加载菜谱库…' : '点击加载菜谱库',
                  en: libraryInstalling
                      ? 'Loading recipe library…'
                      : libraryLoading
                      ? 'Reading recipe library…'
                      : 'Load recipe library',
                ),
              ),
            ),
          ],
          if (expanded) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              pickUiText(
                i18n,
                zh: hasInstalledLibrary
                    ? '当前页面只保留摘要和筛选索引，完整做法在点开详情时再读取。'
                    : '首次使用时会从远端资源库下载菜谱库到本地，之后直接读取本机 SQLite。',
                en: hasInstalledLibrary
                    ? 'This page keeps only summaries and filter indexes. Full recipe details are loaded on demand.'
                    : 'The first install downloads the recipe library from the remote resource store and keeps it locally for later use.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            if (updatedLabel != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                pickUiText(
                  i18n,
                  zh: '最近更新 $updatedLabel',
                  en: 'Updated $updatedLabel',
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
          if (busy) ...<Widget>[
            const SizedBox(height: 10),
            LinearProgressIndicator(
              color: accent,
              minHeight: 4,
              borderRadius: BorderRadius.circular(999),
            ),
          ],
          if (libraryStatus.errorMessage != null && expanded) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              pickUiText(
                i18n,
                zh: '最近一次同步有异常，当前会继续使用本地可用菜谱库。',
                en: 'The latest sync reported an error. The page will keep using the local library that is already available.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              libraryStatus.errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EatCollectionSelectorPanel extends StatelessWidget {
  const _EatCollectionSelectorPanel({
    required this.i18n,
    required this.accent,
    required this.selectedCollectionId,
    required this.collections,
    required this.onSelected,
  });

  final AppI18n i18n;
  final Color accent;
  final String selectedCollectionId;
  final List<DailyChoiceEatCollection> collections;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(12),
      radius: ToolboxUiTokens.sectionPanelRadius,
      borderColor: accent.withValues(alpha: 0.14),
      shadowOpacity: 0.03,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            pickUiText(i18n, zh: '食谱集', en: 'Recipe set'),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxSelectablePill(
                selected: selectedCollectionId == 'all',
                tint: accent,
                onTap: () => onSelected('all'),
                leading: const Icon(Icons.all_inclusive_rounded, size: 18),
                label: Text(
                  pickUiText(i18n, zh: '内置菜谱', en: 'Built-in recipes'),
                ),
              ),
              ...collections.map(
                (collection) => ToolboxSelectablePill(
                  selected: selectedCollectionId == collection.id,
                  tint: accent,
                  onTap: () => onSelected(collection.id),
                  leading: const Icon(Icons.bookmarks_rounded, size: 18),
                  label: Text(
                    '${collection.title(i18n)} · ${collection.optionIds.length}',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EatAdvancedSettingsPanel extends StatelessWidget {
  const _EatAdvancedSettingsPanel({
    required this.i18n,
    required this.accent,
    required this.expanded,
    required this.preferAvailableIngredients,
    required this.ingredientInputController,
    required this.availableIngredients,
    required this.customAvoidInputController,
    required this.customExcludedIngredients,
    required this.selectedTraitFilters,
    required this.excludedContains,
    required this.onExpandedChanged,
    required this.onPreferIngredientsChanged,
    required this.onAddAvailableIngredients,
    required this.onRemoveAvailableIngredient,
    required this.onAddCustomAvoids,
    required this.onRemoveCustomAvoid,
    required this.onToggleTrait,
    required this.onToggleContains,
    required this.onClearAll,
  });

  final AppI18n i18n;
  final Color accent;
  final bool expanded;
  final bool preferAvailableIngredients;
  final TextEditingController ingredientInputController;
  final List<String> availableIngredients;
  final TextEditingController customAvoidInputController;
  final List<String> customExcludedIngredients;
  final Map<String, Set<String>> selectedTraitFilters;
  final Set<String> excludedContains;
  final VoidCallback onExpandedChanged;
  final ValueChanged<bool> onPreferIngredientsChanged;
  final VoidCallback onAddAvailableIngredients;
  final ValueChanged<String> onRemoveAvailableIngredient;
  final VoidCallback onAddCustomAvoids;
  final ValueChanged<String> onRemoveCustomAvoid;
  final void Function(String groupId, String optionId) onToggleTrait;
  final ValueChanged<String> onToggleContains;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasActiveFilters =
        preferAvailableIngredients ||
        availableIngredients.isNotEmpty ||
        customExcludedIngredients.isNotEmpty ||
        excludedContains.isNotEmpty ||
        selectedTraitFilters.values.any((values) => values.isNotEmpty);
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(16),
      radius: ToolboxUiTokens.sectionPanelRadius,
      borderColor: accent.withValues(alpha: 0.18),
      shadowColor: accent,
      shadowOpacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pickUiText(i18n, zh: '高级设置', en: 'Advanced settings'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pickUiText(
                        i18n,
                        zh: '可以按现有材料、荤素结构和常见排除项把菜谱库进一步收口，并支持把食材与排除项拆成可增删的列表。',
                        en: 'Refine the recipe pool by available ingredients, profile, and common avoid filters with editable token lists.',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  if (hasActiveFilters)
                    TextButton.icon(
                      onPressed: onClearAll,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text(pickUiText(i18n, zh: '清空', en: 'Reset')),
                    ),
                  TextButton.icon(
                    onPressed: onExpandedChanged,
                    icon: Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                    ),
                    label: Text(
                      pickUiText(
                        i18n,
                        zh: expanded ? '收起' : '展开',
                        en: expanded ? 'Collapse' : 'Expand',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (expanded) ...<Widget>[
            const SizedBox(height: 14),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: preferAvailableIngredients,
              activeThumbColor: accent,
              activeTrackColor: accent.withValues(alpha: 0.32),
              onChanged: onPreferIngredientsChanged,
              title: Text(
                pickUiText(
                  i18n,
                  zh: '已有材料优先匹配',
                  en: 'Prioritize my ingredients',
                ),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                pickUiText(
                  i18n,
                  zh: '系统会先找全命中，再找高重叠，最后保留至少命中一项材料的相关菜谱，避免随机池被压成只剩一道菜。',
                  en: 'The system tries exact matches first, then strong overlaps, then recipes that hit at least one ingredient to avoid collapsing to a single result.',
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _EatEditableTokenSection(
              i18n: i18n,
              accent: accent,
              title: pickUiText(
                i18n,
                zh: '当前已有材料',
                en: 'Available ingredients',
              ),
              subtitle: pickUiText(
                i18n,
                zh: '支持一次输入多个食材，添加后会变成可删除的标签。匹配时会先看全交集，再看高重叠，最后保留相关合集。',
                en: 'Add multiple ingredients at once. Matching prefers exact overlap first, then strong overlap, then broader related recipes.',
              ),
              controller: ingredientInputController,
              chips: availableIngredients,
              emptyHint: pickUiText(
                i18n,
                zh: '例如：鸡蛋、番茄、豆腐、土豆',
                en: 'For example: egg, tomato, tofu, potato',
              ),
              prefixIcon: Icons.inventory_2_rounded,
              addLabel: pickUiText(i18n, zh: '添加食材', en: 'Add ingredient'),
              onSubmitted: onAddAvailableIngredients,
              onDeleted: onRemoveAvailableIngredient,
            ),
            const SizedBox(height: 14),
            for (final group in eatTraitGroups) ...<Widget>[
              _EatAdvancedChipSection(
                i18n: i18n,
                accent: accent,
                title: group.title(i18n),
                subtitle: group.subtitle(i18n),
                options: group.options,
                selectedIds: selectedTraitFilters[group.id] ?? const <String>{},
                onToggle: (optionId) => onToggleTrait(group.id, optionId),
              ),
              const SizedBox(height: 14),
            ],
            _EatAdvancedChipSection(
              i18n: i18n,
              accent: accent,
              title: pickUiText(i18n, zh: '排除项', en: 'Exclude'),
              subtitle: pickUiText(
                i18n,
                zh: '用于快速排除常见忌口与过敏原；命中后该菜会被移出当前候选。',
                en: 'Quickly exclude common avoid items and allergens from the current pool.',
              ),
              options: eatContainsTraitGroup.options,
              selectedIds: excludedContains,
              onToggle: onToggleContains,
            ),
            const SizedBox(height: 14),
            _EatEditableTokenSection(
              i18n: i18n,
              accent: accent,
              title: pickUiText(i18n, zh: '自定义忌口 / 调料', en: 'Custom avoids'),
              subtitle: pickUiText(
                i18n,
                zh: '适合补充香菜、鱼腥草、蒜、姜、葱等个性化忌口。会同时检查常见忌口标签和食材关键词。',
                en: 'Use this for personal avoid items such as cilantro, houttuynia, garlic, ginger, or scallion.',
              ),
              controller: customAvoidInputController,
              chips: customExcludedIngredients,
              emptyHint: pickUiText(
                i18n,
                zh: '例如：香菜、鱼腥草、蒜',
                en: 'For example: cilantro, houttuynia, garlic',
              ),
              prefixIcon: Icons.do_not_touch_rounded,
              addLabel: pickUiText(i18n, zh: '添加忌口', en: 'Add avoid'),
              onSubmitted: onAddCustomAvoids,
              onDeleted: onRemoveCustomAvoid,
            ),
          ],
        ],
      ),
    );
  }
}

class _EatEditableTokenSection extends StatelessWidget {
  const _EatEditableTokenSection({
    required this.i18n,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.chips,
    required this.emptyHint,
    required this.prefixIcon,
    required this.addLabel,
    required this.onSubmitted,
    required this.onDeleted,
  });

  final AppI18n i18n;
  final Color accent;
  final String title;
  final String subtitle;
  final TextEditingController controller;
  final List<String> chips;
  final String emptyHint;
  final IconData prefixIcon;
  final String addLabel;
  final VoidCallback onSubmitted;
  final ValueChanged<String> onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurfaceVariant,
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
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 1,
                onSubmitted: (_) => onSubmitted(),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  constraints: const BoxConstraints(minHeight: 48),
                  hintText: emptyHint,
                  prefixIcon: Icon(prefixIcon),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 42,
                    minHeight: 42,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onSubmitted,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(addLabel),
            ),
          ],
        ),
        if (chips.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips
                .map(
                  (token) => InputChip(
                    label: Text(eatTokenLabelZh(token)),
                    onDeleted: () => onDeleted(token),
                    deleteIcon: const Icon(Icons.close_rounded, size: 18),
                    selected: true,
                    selectedColor: accent.withValues(alpha: 0.14),
                    side: BorderSide(color: accent.withValues(alpha: 0.22)),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class _EatAdvancedChipSection extends StatelessWidget {
  const _EatAdvancedChipSection({
    required this.i18n,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selectedIds,
    required this.onToggle,
  });

  final AppI18n i18n;
  final Color accent;
  final String title;
  final String subtitle;
  final List<DailyChoiceTraitOption> options;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurfaceVariant,
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
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map(
                (option) => ToolboxSelectablePill(
                  selected: selectedIds.contains(option.id),
                  tint: accent,
                  onTap: () => onToggle(option.id),
                  leading: Icon(option.icon, size: 18),
                  label: Text(option.title(i18n)),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

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

  String _categoryTitle(DailyChoiceCategory category, String languageCode) =>
      category.title(AppI18n(languageCode));
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
          title: widget.i18n.t(
            'inline.plan295.daily_choice.meal_moment.832b046100f9',
          ),
          categories: eatMealFilterCategories,
          selectedId: _mealId,
          accent: widget.accent,
          compactUnselected: true,
          onSelected: (value) => _applyFilterUpdate(() {
            _mealId = value;
          }),
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        DailyChoiceCategorySelector(
          i18n: widget.i18n,
          title: widget.i18n.t(
            'inline.plan295.daily_choice.cooking_tool.52c5e0e7a6b9',
          ),
          categories: cookToolCategories,
          selectedId: _toolId,
          accent: widget.accent,
          compactUnselected: true,
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
          title: _toolId == 'all'
              ? widget.i18n.t(
                  'inline.plan295.daily_choice.what_for_category_titleen_tolowercas.4b9f52de36d4',
                  params: <String, Object?>{
                    'category.titleZh': _categoryTitle(category, 'zh'),
                    'category.titleEn.toLowerCase()':
                        _categoryTitle(category, 'en').toLowerCase(),
                  },
                )
              : widget.i18n.t(
                  'inline.plan295.daily_choice.tool_titleen_category_titleen.ca8660c39c29',
                  params: <String, Object?>{
                    'tool.titleZh': _categoryTitle(tool, 'zh'),
                    'category.titleZh': _categoryTitle(category, 'zh'),
                    'tool.titleEn': _categoryTitle(tool, 'en'),
                    'category.titleEn': _categoryTitle(category, 'en'),
                  },
                ),
          subtitle: _buildRandomPanelSubtitle(
            category,
            tool,
            eligible,
            displayed,
            selectedCollection,
          ),
          options: displayed,
          emptyText: widget.i18n.t(
            selectedCollection != null
                ? 'inline.plan295.daily_choice.this_recipe_set_has_no_dishes_under.da5889d1de1b'
                : (_hasAdvancedFilters
                      ? 'inline.plan295.daily_choice.the_current_filters_are_too_strict_r.265c9cfc3b47'
                      : (_toolId == 'all'
                            ? 'inline.plan295.daily_choice.no_dishes_left_for_this_meal_restore.ceb324d91ac2'
                            : 'inline.plan295.daily_choice.no_dishes_match_this_meal_and_tool_y.0d50a6b8b6c0')),
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
        widget.i18n.t(
          switch (priority.stage) {
            DailyChoiceEatIngredientMatchStage.exact =>
              priority.broadenedForVariety
                  ? 'inline.plan295.daily_choice.exact_ingredient_matches_lead_the_po.6f5398af9222'
                  : 'inline.plan295.daily_choice.exact_ingredient_matches_lead_the_po.503206b0115c',
            DailyChoiceEatIngredientMatchStage.strong =>
              'inline.plan295.daily_choice.no_exact_match_yet_so_the_pool_prefe.493be8d1e1d1',
            DailyChoiceEatIngredientMatchStage.broad =>
              'inline.plan295.daily_choice.no_strong_overlap_yet_so_the_pool_ke.ba302e738567',
            DailyChoiceEatIngredientMatchStage.none =>
              'inline.plan295.daily_choice.no_ingredient_hit_yet_so_the_full_fi.fb50bf11239e',
          },
          params: <String, Object?>{'ingredientSummary': ingredientSummary},
        ),
      );
    }
    if (_toolId == 'all') {
      return withCollection(category.subtitle(widget.i18n));
    }
    return withCollection(
      widget.i18n.t(
        'inline.ui.pages.toolbox_daily_choice.daily_choice_eat_module.tool_subtitleen_category_subtitleen_79a0d9',
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
      title: widget.i18n.t(
        'inline.plan295.daily_choice.before_cooking.bb81becab0e3',
      ),
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
      contextLabelKey: 'toolbox.daily_choice.editor.field.tool',
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
              widget.i18n.t(
                'inline.plan295.daily_choice.failed_to_load_recipe_details_error.d9f10a742c37',
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
    final result = await showDailyChoiceEditorSheet(
      context: context,
      i18n: widget.i18n,
      accent: widget.accent,
      moduleId: 'eat',
      categories: mealCategories,
      initialCategoryId: resolved.categoryId,
      contexts: cookToolCategories,
      initialContextId: resolved.contextId,
      contextLabelKey: 'toolbox.daily_choice.editor.field.tool',
      option: resolved,
    );
    return result?.option;
  }

  Future<DailyChoiceEditorResult?> _openSaveAsCustomEditor(
    DailyChoiceOption option, {
    required List<DailyChoiceEatCollection> eatCollections,
    required Set<String> initialEatCollectionIds,
    required List<DailyChoiceWearCollection> wearCollections,
    required Set<String> initialWearCollectionIds,
  }) async {
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
      contextLabelKey: 'toolbox.daily_choice.editor.field.tool',
      option: resolved,
      forceNewId: true,
      eatCollections: eatCollections,
      initialEatCollectionIds: initialEatCollectionIds,
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
        ? i18n.t(
            'inline.ui.pages.toolbox_daily_choice.daily_choice_eat_module.loading_8285c7',
          )
        : !hasInstalledLibrary
        ? i18n.t('inline.plan295.daily_choice.not_installed.37e25c2c84db')
        : libraryInstalling
        ? i18n.t(
            'inline.ui.pages.toolbox_daily_choice.daily_choice_eat_module.loading_8285c7',
          )
        : i18n.t('timerIdle');

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
                  i18n.t(
                    'inline.plan295.daily_choice.recipe_library.5c3dec496681',
                  ),
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
                tooltip: expanded
                    ? i18n.t(
                        'inline.plan295.daily_choice.collapse.ad0db950964e',
                      )
                    : i18n.t(
                        'inline.ui.widgets.word_detail_sections.expand_70ba34',
                      ),
                onPressed: onToggleExpanded,
                style: IconButton.styleFrom(
                  backgroundColor: accent.withValues(alpha: 0.1),
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withValues(alpha: 0.24)),
                ),
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
                  text: i18n.t(
                    'inline.plan295.daily_choice.total_librarystatus_recipecount.895006c8f6e8',
                  ),
                  accent: accent,
                  backgroundColor: theme.colorScheme.surfaceContainerLow,
                ),
                ToolboxInfoPill(
                  text: i18n.t(
                    'inline.plan295.daily_choice.pool_candidatecount.2886b3be61e9',
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
                i18n.t(
                  libraryInstalling
                      ? 'toolbox.daily_choice.eat.library.loading'
                      : libraryLoading
                      ? 'toolbox.daily_choice.eat.library.reading'
                      : 'toolbox.daily_choice.eat.library.load',
                ),
              ),
            ),
          ],
          if (expanded) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              hasInstalledLibrary
                  ? i18n.t(
                      'inline.plan295.daily_choice.recipe_summaries_are_ready_full_inst.17390655c83b',
                    )
                  : i18n.t(
                      'inline.plan295.daily_choice.prepare_the_recipe_library_once_futu.5f752dc78182',
                    ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            if (updatedLabel != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                i18n.t(
                  'inline.plan295.daily_choice.updated_updatedlabel.6e0ba6c7f960',
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
              i18n.t(
                'inline.plan295.daily_choice.the_latest_sync_reported_an_error_th.cfb5d0abc743',
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
            i18n.t(
              'inline.ui.pages.toolbox_daily_choice.daily_choice_eat_module.recipe_set_f58eb6',
            ),
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
                  i18n.t(
                    'inline.plan295.daily_choice.built_in_recipes.b6a38d84379c',
                  ),
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
                      i18n.t(
                        'inline.ui.pages.toolbox_daily_choice.daily_choice_eat_module.advanced_settings_e4bcf4',
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      i18n.t(
                        'inline.plan295.daily_choice.refine_the_recipe_pool_by_available.27c5b39b0a90',
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
                      label: Text(
                        i18n.t(
                          'inline.plan295.daily_choice.reset.7b99f32b7636',
                        ),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: onExpandedChanged,
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      backgroundColor: accent.withValues(alpha: 0.1),
                      side: BorderSide(color: accent.withValues(alpha: 0.24)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    icon: Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                    ),
                    label: Text(
                      expanded
                          ? i18n.t(
                              'inline.plan295.daily_choice.collapse.ad0db950964e',
                            )
                          : i18n.t(
                              'inline.ui.widgets.word_detail_sections.expand_70ba34',
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
                i18n.t(
                  'inline.plan295.daily_choice.prioritize_my_ingredients.a3571716cead',
                ),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                i18n.t(
                  'inline.plan295.daily_choice.the_system_tries_exact_matches_first.b276b9b64fd2',
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
              title: i18n.t(
                'inline.plan295.daily_choice.available_ingredients.02b32cd2b57d',
              ),
              subtitle: i18n.t(
                'inline.plan295.daily_choice.add_multiple_ingredients_at_once_mat.11dc9f94fa40',
              ),
              controller: ingredientInputController,
              chips: availableIngredients,
              emptyHint: i18n.t(
                'inline.plan295.daily_choice.for_example_egg_tomato_tofu_potato.bf554e3fc05e',
              ),
              prefixIcon: Icons.inventory_2_rounded,
              addLabel: i18n.t(
                'inline.plan295.daily_choice.add_ingredient.0034c5724a06',
              ),
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
              title: i18n.t('inline.plan295.daily_choice.exclude.eacf33047005'),
              subtitle: i18n.t(
                'inline.plan295.daily_choice.quickly_exclude_common_avoid_items_a.981b3318d565',
              ),
              options: eatContainsTraitGroup.options,
              selectedIds: excludedContains,
              onToggle: onToggleContains,
            ),
            const SizedBox(height: 14),
            _EatEditableTokenSection(
              i18n: i18n,
              accent: accent,
              title: i18n.t(
                'inline.plan295.daily_choice.custom_avoids.dfef4079c28f',
              ),
              subtitle: i18n.t(
                'inline.plan295.daily_choice.use_this_for_personal_avoid_items_su.a718b51e072c',
              ),
              controller: customAvoidInputController,
              chips: customExcludedIngredients,
              emptyHint: i18n.t(
                'inline.plan295.daily_choice.for_example_cilantro_houttuynia_garl.3b22507a8679',
              ),
              prefixIcon: Icons.do_not_touch_rounded,
              addLabel: i18n.t(
                'inline.plan295.daily_choice.add_avoid.17070976b76e',
              ),
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
          spacing: 6,
          runSpacing: 6,
          children: options
              .map((option) {
                final selected = selectedIds.contains(option.id);
                return ToolboxSelectablePill(
                  selected: selected,
                  tint: accent,
                  onTap: () => onToggle(option.id),
                  leading: Icon(option.icon, size: 18),
                  showLabel: selected,
                  tooltip: option.title(i18n),
                  padding: selected
                      ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                      : const EdgeInsets.all(12),
                  label: Text(option.title(i18n)),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

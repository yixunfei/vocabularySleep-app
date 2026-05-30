part of 'daily_choice_hub.dart';

class _WearChoiceModule extends StatefulWidget {
  const _WearChoiceModule({
    super.key,
    required this.i18n,
    required this.accent,
    required this.options,
    required this.builtInOptions,
    required this.customState,
    required this.onStateChanged,
    required this.weatherEnabled,
    required this.weatherLoading,
    required this.weatherSnapshot,
    required this.libraryStatus,
    required this.libraryLoading,
    required this.libraryInstalling,
    required this.onInstallLibrary,
    required this.wearCollections,
    this.onInspectOption,
    this.onAdjustBuiltInOption,
    this.onSaveBuiltInAsCustom,
  });
  final AppI18n i18n;
  final Color accent;
  final List<DailyChoiceOption> options;
  final List<DailyChoiceOption> builtInOptions;
  final DailyChoiceCustomState customState;
  final ValueChanged<DailyChoiceCustomState> onStateChanged;
  final bool weatherEnabled;
  final bool weatherLoading;
  final WeatherSnapshot? weatherSnapshot;
  final DailyChoiceWearLibraryStatus libraryStatus;
  final bool libraryLoading;
  final bool libraryInstalling;
  final Future<void> Function() onInstallLibrary;
  final List<DailyChoiceWearCollection> wearCollections;
  final Future<void> Function(DailyChoiceOption option)? onInspectOption;
  final Future<DailyChoiceOption?> Function(DailyChoiceOption option)?
  onAdjustBuiltInOption;
  final DailyChoiceSaveAsCustomEditor? onSaveBuiltInAsCustom;
  @override
  State<_WearChoiceModule> createState() => _WearChoiceModuleState();
}

class _WearChoiceModuleState extends State<_WearChoiceModule> {
  String _temperatureId = 'all';
  String _sceneId = 'all';
  String _collectionId = dailyChoiceFavoriteWearCollectionId;
  bool _temperatureManuallyEdited = false;
  bool _libraryStatusExpanded = false;
  bool _advancedExpanded = false;
  bool _builtInCollectionsExpanded = false;
  bool _advisorOpen = false;
  String _advisorToolId = 'audit';
  String _advisorColorId = 'black';
  String _advisorLayerId = 'mild';
  String _advisorSceneId = 'commute';
  Set<String> _advisorCheckedIds = <String>{};
  _WearWeatherSuggestion? _weatherSuggestion;
  late Map<String, Set<String>> _selectedTraitFilters;

  @override
  void initState() {
    super.initState();
    _selectedTraitFilters = <String, Set<String>>{
      for (final group in wearTraitGroups) group.id: <String>{},
    };
    _syncWeatherSuggestion(initial: true);
  }

  @override
  void didUpdateWidget(covariant _WearChoiceModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedCollectionStillExists =
        _collectionId == 'all' ||
        widget.wearCollections.any((item) => item.id == _collectionId);
    if (!selectedCollectionStillExists) {
      _collectionId = 'all';
    }
    if (oldWidget.weatherEnabled != widget.weatherEnabled ||
        oldWidget.weatherLoading != widget.weatherLoading ||
        oldWidget.weatherSnapshot != widget.weatherSnapshot) {
      _syncWeatherSuggestion();
    }
  }

  void _syncWeatherSuggestion({bool initial = false}) {
    final next = (widget.weatherEnabled || widget.weatherSnapshot != null)
        ? _buildWearWeatherSuggestion(widget.weatherSnapshot)
        : null;
    final previousSuggestedId = _weatherSuggestion?.temperatureId;
    if (initial) {
      _weatherSuggestion = next;
      if (next != null && _temperatureId == 'all') {
        _temperatureId = next.temperatureId;
      }
      return;
    }
    final shouldApplySuggested =
        next != null &&
        (_temperatureId == 'all' ||
            !_temperatureManuallyEdited ||
            _temperatureId == previousSuggestedId);
    setState(() {
      _weatherSuggestion = next;
      if (next == null) {
        if (!_temperatureManuallyEdited ||
            _temperatureId == previousSuggestedId) {
          _temperatureId = 'all';
          _temperatureManuallyEdited = false;
        }
        return;
      }
      if (shouldApplySuggested) {
        _temperatureId = next.temperatureId;
        _temperatureManuallyEdited = false;
      } else if (_temperatureId == next.temperatureId) {
        _temperatureManuallyEdited = false;
      }
    });
  }

  void _handleTemperatureSelected(String value) {
    setState(() {
      _temperatureId = value;
      _temperatureManuallyEdited =
          value != 'all' &&
          (_weatherSuggestion == null ||
              value != _weatherSuggestion!.temperatureId);
    });
  }

  void _restoreWeatherSuggestion() {
    final suggestion = _weatherSuggestion;
    if (suggestion == null) {
      return;
    }
    setState(() {
      _temperatureId = suggestion.temperatureId;
      _temperatureManuallyEdited = false;
    });
  }

  List<DailyChoiceOption> _applyTraitFilters(List<DailyChoiceOption> options) {
    final active = _selectedTraitFilters.entries
        .where((entry) => entry.value.isNotEmpty)
        .toList(growable: false);
    if (active.isEmpty) {
      return options;
    }
    return options
        .where((option) {
          for (final filter in active) {
            final values = option.attributeValues(filter.key).toSet();
            if (filter.value.every((v) => !values.contains(v))) {
              return false;
            }
          }
          return true;
        })
        .toList(growable: false);
  }

  int get _activeTraitFilterCount =>
      _selectedTraitFilters.values.where((set) => set.isNotEmpty).length;

  @override
  Widget build(BuildContext context) {
    final tempFiltered = _temperatureId == 'all'
        ? widget.options
        : widget.options
              .where((item) => item.categoryId == _temperatureId)
              .toList(growable: false);
    final exact = _sceneId == 'all'
        ? tempFiltered
        : tempFiltered
              .where((item) => _matchesWearScene(item, _sceneId))
              .toList(growable: false);
    final filtered = switch (exact.length) {
      >= 2 => exact,
      1 => <DailyChoiceOption>[
        ...exact,
        ...tempFiltered.where((item) => !_matchesWearScene(item, _sceneId)),
      ],
      _ => tempFiltered,
    };
    final collection = _selectedCollection;
    final filteredByCollection = collection == null
        ? filtered
        : filtered
              .where((item) => collection.containsOption(item.id))
              .toList(growable: false);
    final traitFiltered = _applyTraitFilters(filteredByCollection);
    final temperature = wearTemperatureFilterCategories.firstWhere(
      (item) => item.id == _temperatureId,
    );
    final scene = wearSceneFilterCategories.firstWhere(
      (item) => item.id == _sceneId,
    );
    final suggestion = _weatherSuggestion;
    final usingWeatherSuggestion =
        suggestion != null &&
        _temperatureId == suggestion.temperatureId &&
        !_temperatureManuallyEdited;
    final showRainShortcut =
        suggestion != null && suggestion.suggestRainScene && _sceneId != 'rain';
    final baseSubtitle = _temperatureId == 'all' && _sceneId == 'all'
        ? collection == null
              ? widget.i18n.t(
                  'inline.plan295.daily_choice.browsing_all_wardrobes_built_ins_are.569122525c2c',
                )
              : widget.i18n.t(
                  'inline.plan295.daily_choice.random_picks_now_come_from_this_ward.bbdfd79c6a80',
                )
        : (exact.isEmpty && tempFiltered.isNotEmpty
              ? widget.i18n.t(
                  'inline.plan295.daily_choice.no_exact_scene_match_yet_randomizing.2caac60ab788',
                )
              : (exact.length == 1 && tempFiltered.length > 1
                    ? widget.i18n.t(
                        'inline.plan295.daily_choice.this_scene_has_only_one_exact_match.b6cbf82eedd7',
                      )
                    : (_temperatureManuallyEdited && suggestion != null
                          ? widget.i18n.t(
                              'inline.plan295.daily_choice.manual_selection_temperature_titleen.645fc37db6a4',
                            )
                          : scene.subtitle(widget.i18n))));
    final filterNote = _activeTraitFilterCount > 0
        ? widget.i18n.t(
            'inline.plan295.daily_choice.activetraitfiltercount_advanced_filt.d8fbf6fd3e2f',
          )
        : '';
    final panelSubtitle = '$baseSubtitle$filterNote';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _WearWeatherPanel(
          i18n: widget.i18n,
          accent: widget.accent,
          weatherEnabled: widget.weatherEnabled,
          weatherLoading: widget.weatherLoading,
          suggestion: suggestion,
          usingSuggestedTemperature: usingWeatherSuggestion,
          onRestoreSuggestedTemperature: _restoreWeatherSuggestion,
          onSwitchToRainScene: showRainShortcut
              ? () => setState(() => _sceneId = 'rain')
              : null,
        ),
        if (!widget.libraryStatus.hasInstalledLibrary ||
            widget.libraryLoading ||
            widget.libraryInstalling ||
            widget.libraryStatus.errorMessage != null) ...<Widget>[
          const SizedBox(height: ToolboxUiTokens.cardSpacing),
          _WearLibraryStatusPanel(
            i18n: widget.i18n,
            accent: widget.accent,
            libraryStatus: widget.libraryStatus,
            libraryLoading: widget.libraryLoading,
            libraryInstalling: widget.libraryInstalling,
            onInstallLibrary: widget.onInstallLibrary,
            candidateCount: filtered.length,
            expanded: _libraryStatusExpanded,
            onToggleExpanded: () {
              setState(() {
                _libraryStatusExpanded = !_libraryStatusExpanded;
              });
            },
          ),
        ],
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        _WearAdvisorPanel(
          i18n: widget.i18n,
          accent: widget.accent,
          expanded: _advisorOpen,
          selectedToolId: _advisorToolId,
          selectedColorId: _advisorColorId,
          selectedLayerId: _advisorLayerId,
          selectedSceneId: _advisorSceneId,
          checkedIds: _advisorCheckedIds,
          onToggleExpanded: () {
            setState(() {
              _advisorOpen = !_advisorOpen;
            });
          },
          onToolSelected: (value) {
            setState(() {
              _advisorToolId = value;
              _advisorOpen = true;
            });
          },
          onColorSelected: (value) {
            setState(() => _advisorColorId = value);
          },
          onLayerSelected: (value) {
            setState(() => _advisorLayerId = value);
          },
          onSceneSelected: (value) {
            setState(() => _advisorSceneId = value);
          },
          onCheckToggled: (value) {
            setState(() {
              final next = <String>{..._advisorCheckedIds};
              if (!next.add(value)) {
                next.remove(value);
              }
              _advisorCheckedIds = next;
            });
          },
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        DailyChoiceCategorySelector(
          i18n: widget.i18n,
          title: widget.i18n.t(
            'inline.plan295.daily_choice.temperature.2cc4112c1a72',
          ),
          categories: wearTemperatureFilterCategories,
          selectedId: _temperatureId,
          accent: widget.accent,
          compactUnselected: true,
          onSelected: _handleTemperatureSelected,
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        DailyChoiceCategorySelector(
          i18n: widget.i18n,
          title: widget.i18n.t(
            'inline.plan295.daily_choice.scene.6f88551df562',
          ),
          categories: wearSceneFilterCategories,
          selectedId: _sceneId,
          accent: widget.accent,
          compactUnselected: true,
          onSelected: (value) => setState(() => _sceneId = value),
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        _WearCollectionSelectorPanel(
          i18n: widget.i18n,
          accent: widget.accent,
          selectedCollectionId: _collectionId,
          collections: widget.wearCollections,
          builtInExpanded:
              _builtInCollectionsExpanded ||
              isBuiltInWearCollectionId(_collectionId),
          onToggleBuiltInExpanded: () {
            setState(() {
              _builtInCollectionsExpanded = !_builtInCollectionsExpanded;
            });
          },
          onSelected: (value) => setState(() => _collectionId = value),
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        _WearAdvancedSettingsPanel(
          i18n: widget.i18n,
          accent: widget.accent,
          expanded: _advancedExpanded,
          selectedFilters: _selectedTraitFilters,
          onToggleExpanded: () {
            setState(() => _advancedExpanded = !_advancedExpanded);
          },
          onToggleTrait: (groupId, optionId) {
            setState(() {
              final values = _selectedTraitFilters[groupId] ?? <String>{};
              if (values.contains(optionId)) {
                values.remove(optionId);
              } else {
                values.add(optionId);
              }
              _selectedTraitFilters[groupId] = values;
            });
          },
          onReset: () {
            setState(() {
              _selectedTraitFilters = <String, Set<String>>{
                for (final group in wearTraitGroups) group.id: <String>{},
              };
            });
          },
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        DailyChoiceRandomPanel(
          i18n: widget.i18n,
          accent: widget.accent,
          title: widget.i18n.t(
            'inline.ui.pages.toolbox_daily_choice.daily_choice_wear_module.temperature_titleen_scene_titleen_5fc52d',
          ),
          subtitle: panelSubtitle,
          options: traitFiltered,
          emptyText: collection != null
              ? widget.i18n.t(
                  'inline.plan295.daily_choice.this_wardrobe_has_no_matching_outfit.0da182c24691',
                )
              : widget.i18n.t(
                  'inline.plan295.daily_choice.no_matching_outfits_yet_use_built_in.5074618037d3',
                ),
          onDetail: (option) =>
              widget.onInspectOption?.call(option) ??
              showDailyChoiceDetailSheet(
                context: context,
                i18n: widget.i18n,
                accent: widget.accent,
                option: option,
              ),
          onGuide: () => showDailyChoiceGuideSheet(
            context: context,
            i18n: widget.i18n,
            accent: widget.accent,
            title: widget.i18n.t(
              'inline.plan295.daily_choice.outfit_guide.fe4e609752d1',
            ),
            modules: wearGuideModules,
          ),
          onManage: () => showDailyChoiceManagerSheet(
            context: context,
            i18n: widget.i18n,
            accent: widget.accent,
            moduleId: 'wear',
            builtInOptions: widget.builtInOptions,
            state: widget.customState,
            onStateChanged: widget.onStateChanged,
            categories: wearTemperatureFilterCategories,
            initialCategoryId: _temperatureId,
            contexts: wearSceneFilterCategories,
            initialContextId: _sceneId,
            wearCollections: widget.wearCollections,
            onInspectOption: widget.onInspectOption,
            onAdjustBuiltInOption: widget.onAdjustBuiltInOption,
            onSaveBuiltInAsCustom: widget.onSaveBuiltInAsCustom,
          ),
        ),
      ],
    );
  }

  DailyChoiceWearCollection? get _selectedCollection {
    if (_collectionId == 'all') {
      return null;
    }
    for (final collection in widget.wearCollections) {
      if (collection.id == _collectionId) {
        return collection;
      }
    }
    return null;
  }
}

bool _matchesWearScene(DailyChoiceOption option, String sceneId) {
  return option.contextId == sceneId || option.contextIds.contains(sceneId);
}

class _WearAdvisorPanel extends StatelessWidget {
  const _WearAdvisorPanel({
    required this.i18n,
    required this.accent,
    required this.expanded,
    required this.selectedToolId,
    required this.selectedColorId,
    required this.selectedLayerId,
    required this.selectedSceneId,
    required this.checkedIds,
    required this.onToggleExpanded,
    required this.onToolSelected,
    required this.onColorSelected,
    required this.onLayerSelected,
    required this.onSceneSelected,
    required this.onCheckToggled,
  });

  final AppI18n i18n;
  final Color accent;
  final bool expanded;
  final String selectedToolId;
  final String selectedColorId;
  final String selectedLayerId;
  final String selectedSceneId;
  final Set<String> checkedIds;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String> onToolSelected;
  final ValueChanged<String> onColorSelected;
  final ValueChanged<String> onLayerSelected;
  final ValueChanged<String> onSceneSelected;
  final ValueChanged<String> onCheckToggled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(12),
      radius: ToolboxUiTokens.sectionPanelRadius,
      borderColor: accent.withValues(alpha: expanded ? 0.24 : 0.16),
      shadowColor: accent,
      shadowOpacity: expanded ? 0.08 : 0.03,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            borderRadius: BorderRadius.circular(
              ToolboxUiTokens.sectionPanelRadius,
            ),
            onTap: onToggleExpanded,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.fact_check_rounded,
                      color: accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          i18n.t(
                            'inline.plan295.daily_choice.outfit_check.6ae7ea008203',
                          ),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          i18n.t(
                            'inline.plan295.daily_choice.check_proportion_color_layers_and_sc.dbd6a08dee4c',
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: accent,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _wearAdvisorTools
                  .map(
                    (tool) => FilterChip(
                      selected: selectedToolId == tool.id,
                      showCheckmark: false,
                      avatar: Icon(tool.icon, size: 16),
                      label: Text(tool.title(i18n)),
                      selectedColor: accent.withValues(alpha: 0.16),
                      onSelected: (_) => onToolSelected(tool.id),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            _buildSelectedTool(context),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedTool(BuildContext context) {
    return switch (selectedToolId) {
      'color' => _WearAdvisorColorTool(
        i18n: i18n,
        accent: accent,
        selectedColorId: selectedColorId,
        onSelected: onColorSelected,
      ),
      'layer' => _WearAdvisorLayerTool(
        i18n: i18n,
        accent: accent,
        selectedLayerId: selectedLayerId,
        onSelected: onLayerSelected,
      ),
      'scene' => _WearAdvisorSceneTool(
        i18n: i18n,
        accent: accent,
        selectedSceneId: selectedSceneId,
        onSelected: onSceneSelected,
      ),
      _ => _WearAdvisorAuditTool(
        i18n: i18n,
        accent: accent,
        checkedIds: checkedIds,
        onToggle: onCheckToggled,
      ),
    };
  }
}

class _WearAdvisorAuditTool extends StatelessWidget {
  const _WearAdvisorAuditTool({
    required this.i18n,
    required this.accent,
    required this.checkedIds,
    required this.onToggle,
  });

  final AppI18n i18n;
  final Color accent;
  final Set<String> checkedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _wearAdvisorAuditChecks.length;
    final checked = checkedIds.length.clamp(0, total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          i18n.t('inline.plan295.daily_choice.30_second_check.323ea2d1d63a'),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: total == 0 ? 0 : checked / total,
          color: accent,
          minHeight: 4,
          borderRadius: BorderRadius.circular(999),
        ),
        const SizedBox(height: 8),
        Text(
          i18n.t(
            'inline.plan295.daily_choice.checked_total_passed_if_fewer_than_4.5ca16f184329',
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        for (final item in _wearAdvisorAuditChecks)
          _WearAdvisorCheckRow(
            i18n: i18n,
            accent: accent,
            item: item,
            checked: checkedIds.contains(item.id),
            onTap: () => onToggle(item.id),
          ),
        const SizedBox(height: 10),
        _WearAdvisorBulletSection(
          i18n: i18n,
          icon: Icons.auto_fix_high_rounded,
          titleKey: 'daily_choice.wear.advisor.quick_fixes.title',
          itemKeys: const <String>[
            'daily_choice.wear.advisor.quick_fixes.too_formal',
            'daily_choice.wear.advisor.quick_fixes.too_loose',
            'daily_choice.wear.advisor.quick_fixes.too_dull',
            'daily_choice.wear.advisor.quick_fixes.unstable_weather',
          ],
        ),
      ],
    );
  }
}

class _WearAdvisorCheckRow extends StatelessWidget {
  const _WearAdvisorCheckRow({
    required this.i18n,
    required this.accent,
    required this.item,
    required this.checked,
    required this.onTap,
  });

  final AppI18n i18n;
  final Color accent;
  final _WearAdvisorCheck item;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: checked
                ? accent.withValues(alpha: 0.12)
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: checked
                  ? accent.withValues(alpha: 0.30)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                checked
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: checked ? accent : theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title(i18n),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.body(i18n),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WearAdvisorColorTool extends StatelessWidget {
  const _WearAdvisorColorTool({
    required this.i18n,
    required this.accent,
    required this.selectedColorId,
    required this.onSelected,
  });

  final AppI18n i18n;
  final Color accent;
  final String selectedColorId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final advice = _wearColorAdvices.firstWhere(
      (item) => item.id == selectedColorId,
      orElse: () => _wearColorAdvices.first,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _WearAdvisorChoiceWrap(
          i18n: i18n,
          accent: accent,
          items: _wearColorAdvices,
          selectedId: selectedColorId,
          onSelected: onSelected,
        ),
        const SizedBox(height: 10),
        _WearAdvisorBulletSection(
          i18n: i18n,
          icon: Icons.palette_rounded,
          titleKey: 'daily_choice.wear.advisor.color.good_pairings',
          itemKeys: advice.pairKeys,
        ),
        const SizedBox(height: 8),
        _WearAdvisorBulletSection(
          i18n: i18n,
          icon: Icons.block_rounded,
          titleKey: 'daily_choice.wear.advisor.color.use_carefully',
          itemKeys: advice.avoidKeys,
        ),
      ],
    );
  }
}

class _WearAdvisorLayerTool extends StatelessWidget {
  const _WearAdvisorLayerTool({
    required this.i18n,
    required this.accent,
    required this.selectedLayerId,
    required this.onSelected,
  });

  final AppI18n i18n;
  final Color accent;
  final String selectedLayerId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final formula = _wearLayerFormulas.firstWhere(
      (item) => item.id == selectedLayerId,
      orElse: () => _wearLayerFormulas.first,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _WearAdvisorChoiceWrap(
          i18n: i18n,
          accent: accent,
          items: _wearLayerFormulas,
          selectedId: selectedLayerId,
          onSelected: onSelected,
        ),
        const SizedBox(height: 10),
        _WearAdvisorBulletSection(
          i18n: i18n,
          icon: Icons.layers_rounded,
          titleKey: 'daily_choice.wear.advisor.layer.formula',
          itemKeys: formula.formulaKeys,
        ),
        const SizedBox(height: 8),
        _WearAdvisorBulletSection(
          i18n: i18n,
          icon: Icons.rule_rounded,
          titleKey: 'daily_choice.wear.advisor.layer.checks',
          itemKeys: formula.checkKeys,
        ),
      ],
    );
  }
}

class _WearAdvisorSceneTool extends StatelessWidget {
  const _WearAdvisorSceneTool({
    required this.i18n,
    required this.accent,
    required this.selectedSceneId,
    required this.onSelected,
  });

  final AppI18n i18n;
  final Color accent;
  final String selectedSceneId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scene = _wearSceneAdvices.firstWhere(
      (item) => item.id == selectedSceneId,
      orElse: () => _wearSceneAdvices.first,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _WearAdvisorChoiceWrap(
          i18n: i18n,
          accent: accent,
          items: _wearSceneAdvices,
          selectedId: selectedSceneId,
          onSelected: onSelected,
        ),
        const SizedBox(height: 10),
        _WearAdvisorBulletSection(
          i18n: i18n,
          icon: Icons.flag_rounded,
          titleKey: 'daily_choice.wear.advisor.scene.first_priority',
          itemKeys: scene.priorityKeys,
        ),
        const SizedBox(height: 8),
        _WearAdvisorBulletSection(
          i18n: i18n,
          icon: Icons.warning_amber_rounded,
          titleKey: 'daily_choice.wear.advisor.scene.common_misses',
          itemKeys: scene.avoidKeys,
        ),
      ],
    );
  }
}

class _WearAdvisorChoiceWrap<T extends _WearAdvisorChoice>
    extends StatelessWidget {
  const _WearAdvisorChoiceWrap({
    required this.i18n,
    required this.accent,
    required this.items,
    required this.selectedId,
    required this.onSelected,
  });

  final AppI18n i18n;
  final Color accent;
  final List<T> items;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => FilterChip(
              selected: selectedId == item.id,
              showCheckmark: false,
              avatar: Icon(item.icon, size: 16),
              label: Text(item.title(i18n)),
              selectedColor: accent.withValues(alpha: 0.16),
              onSelected: (_) => onSelected(item.id),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _WearAdvisorBulletSection extends StatelessWidget {
  const _WearAdvisorBulletSection({
    required this.i18n,
    required this.icon,
    required this.titleKey,
    required this.itemKeys,
  });

  final AppI18n i18n;
  final IconData icon;
  final String titleKey;
  final List<String> itemKeys;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.48),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 17, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                i18n.t(titleKey),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final itemKey in itemKeys)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('• '),
                  Expanded(
                    child: Text(
                      i18n.t(itemKey),
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

abstract class _WearAdvisorChoice {
  const _WearAdvisorChoice();
  String get id;
  IconData get icon;
  String title(AppI18n i18n);
}

class _WearAdvisorTool extends _WearAdvisorChoice {
  const _WearAdvisorTool({
    required this.id,
    required this.icon,
    required this.titleKey,
  });

  @override
  final String id;
  @override
  final IconData icon;
  final String titleKey;

  @override
  String title(AppI18n i18n) => i18n.t(titleKey);
}

class _WearAdvisorCheck {
  const _WearAdvisorCheck({
    required this.id,
    required this.titleKey,
    required this.bodyKey,
  });

  final String id;
  final String titleKey;
  final String bodyKey;

  String title(AppI18n i18n) => i18n.t(titleKey);
  String body(AppI18n i18n) => i18n.t(bodyKey);
}

class _WearColorAdvice extends _WearAdvisorTool {
  const _WearColorAdvice({
    required super.id,
    required super.icon,
    required super.titleKey,
    required this.pairKeys,
    required this.avoidKeys,
  });

  final List<String> pairKeys;
  final List<String> avoidKeys;
}

class _WearLayerFormula extends _WearAdvisorTool {
  const _WearLayerFormula({
    required super.id,
    required super.icon,
    required super.titleKey,
    required this.formulaKeys,
    required this.checkKeys,
  });

  final List<String> formulaKeys;
  final List<String> checkKeys;
}

class _WearSceneAdvice extends _WearAdvisorTool {
  const _WearSceneAdvice({
    required super.id,
    required super.icon,
    required super.titleKey,
    required this.priorityKeys,
    required this.avoidKeys,
  });

  final List<String> priorityKeys;
  final List<String> avoidKeys;
}

const List<_WearAdvisorTool> _wearAdvisorTools = <_WearAdvisorTool>[
  _WearAdvisorTool(
    id: 'audit',
    icon: Icons.fact_check_rounded,
    titleKey: 'daily_choice.wear.advisor.tool.audit',
  ),
  _WearAdvisorTool(
    id: 'color',
    icon: Icons.palette_rounded,
    titleKey: 'daily_choice.wear.advisor.tool.color',
  ),
  _WearAdvisorTool(
    id: 'layer',
    icon: Icons.layers_rounded,
    titleKey: 'daily_choice.wear.advisor.tool.layer',
  ),
  _WearAdvisorTool(
    id: 'scene',
    icon: Icons.event_available_rounded,
    titleKey: 'daily_choice.wear.advisor.tool.scene',
  ),
];

const List<_WearAdvisorCheck> _wearAdvisorAuditChecks = <_WearAdvisorCheck>[
  _WearAdvisorCheck(
    id: 'temperature',
    titleKey: 'daily_choice.wear.advisor.audit.temperature.title',
    bodyKey: 'daily_choice.wear.advisor.audit.temperature.body',
  ),
  _WearAdvisorCheck(
    id: 'movement',
    titleKey: 'daily_choice.wear.advisor.audit.movement.title',
    bodyKey: 'daily_choice.wear.advisor.audit.movement.body',
  ),
  _WearAdvisorCheck(
    id: 'scene',
    titleKey: 'daily_choice.wear.advisor.audit.scene.title',
    bodyKey: 'daily_choice.wear.advisor.audit.scene.body',
  ),
  _WearAdvisorCheck(
    id: 'proportion',
    titleKey: 'daily_choice.wear.advisor.audit.proportion.title',
    bodyKey: 'daily_choice.wear.advisor.audit.proportion.body',
  ),
  _WearAdvisorCheck(
    id: 'shoes_bag',
    titleKey: 'daily_choice.wear.advisor.audit.shoes_bag.title',
    bodyKey: 'daily_choice.wear.advisor.audit.shoes_bag.body',
  ),
  _WearAdvisorCheck(
    id: 'care',
    titleKey: 'daily_choice.wear.advisor.audit.care.title',
    bodyKey: 'daily_choice.wear.advisor.audit.care.body',
  ),
];

const List<_WearColorAdvice> _wearColorAdvices = <_WearColorAdvice>[
  _WearColorAdvice(
    id: 'black',
    icon: Icons.contrast_rounded,
    titleKey: 'daily_choice.wear.advisor.color.black.title',
    pairKeys: <String>[
      'daily_choice.wear.advisor.color.black.pair_1',
      'daily_choice.wear.advisor.color.black.pair_2',
      'daily_choice.wear.advisor.color.black.pair_3',
    ],
    avoidKeys: <String>[
      'daily_choice.wear.advisor.color.black.avoid_1',
      'daily_choice.wear.advisor.color.black.avoid_2',
    ],
  ),
  _WearColorAdvice(
    id: 'white',
    icon: Icons.light_mode_rounded,
    titleKey: 'daily_choice.wear.advisor.color.white.title',
    pairKeys: <String>[
      'daily_choice.wear.advisor.color.white.pair_1',
      'daily_choice.wear.advisor.color.white.pair_2',
      'daily_choice.wear.advisor.color.white.pair_3',
    ],
    avoidKeys: <String>[
      'daily_choice.wear.advisor.color.white.avoid_1',
      'daily_choice.wear.advisor.color.white.avoid_2',
    ],
  ),
  _WearColorAdvice(
    id: 'navy',
    icon: Icons.water_rounded,
    titleKey: 'daily_choice.wear.advisor.color.navy.title',
    pairKeys: <String>[
      'daily_choice.wear.advisor.color.navy.pair_1',
      'daily_choice.wear.advisor.color.navy.pair_2',
      'daily_choice.wear.advisor.color.navy.pair_3',
    ],
    avoidKeys: <String>[
      'daily_choice.wear.advisor.color.navy.avoid_1',
      'daily_choice.wear.advisor.color.navy.avoid_2',
    ],
  ),
  _WearColorAdvice(
    id: 'khaki',
    icon: Icons.tonality_rounded,
    titleKey: 'daily_choice.wear.advisor.color.khaki.title',
    pairKeys: <String>[
      'daily_choice.wear.advisor.color.khaki.pair_1',
      'daily_choice.wear.advisor.color.khaki.pair_2',
      'daily_choice.wear.advisor.color.khaki.pair_3',
    ],
    avoidKeys: <String>[
      'daily_choice.wear.advisor.color.khaki.avoid_1',
      'daily_choice.wear.advisor.color.khaki.avoid_2',
    ],
  ),
  _WearColorAdvice(
    id: 'accent',
    icon: Icons.color_lens_rounded,
    titleKey: 'daily_choice.wear.advisor.color.accent.title',
    pairKeys: <String>[
      'daily_choice.wear.advisor.color.accent.pair_1',
      'daily_choice.wear.advisor.color.accent.pair_2',
      'daily_choice.wear.advisor.color.accent.pair_3',
    ],
    avoidKeys: <String>[
      'daily_choice.wear.advisor.color.accent.avoid_1',
      'daily_choice.wear.advisor.color.accent.avoid_2',
    ],
  ),
];

const List<_WearLayerFormula> _wearLayerFormulas = <_WearLayerFormula>[
  _WearLayerFormula(
    id: 'hot',
    icon: Icons.wb_sunny_rounded,
    titleKey: 'daily_choice.wear.advisor.layer.hot.title',
    formulaKeys: <String>[
      'daily_choice.wear.advisor.layer.hot.formula_1',
      'daily_choice.wear.advisor.layer.hot.formula_2',
    ],
    checkKeys: <String>[
      'daily_choice.wear.advisor.layer.hot.check_1',
      'daily_choice.wear.advisor.layer.hot.check_2',
    ],
  ),
  _WearLayerFormula(
    id: 'mild',
    icon: Icons.filter_drama_rounded,
    titleKey: 'daily_choice.wear.advisor.layer.mild.title',
    formulaKeys: <String>[
      'daily_choice.wear.advisor.layer.mild.formula_1',
      'daily_choice.wear.advisor.layer.mild.formula_2',
    ],
    checkKeys: <String>[
      'daily_choice.wear.advisor.layer.mild.check_1',
      'daily_choice.wear.advisor.layer.mild.check_2',
    ],
  ),
  _WearLayerFormula(
    id: 'cold',
    icon: Icons.ac_unit_rounded,
    titleKey: 'daily_choice.wear.advisor.layer.cold.title',
    formulaKeys: <String>[
      'daily_choice.wear.advisor.layer.cold.formula_1',
      'daily_choice.wear.advisor.layer.cold.formula_2',
    ],
    checkKeys: <String>[
      'daily_choice.wear.advisor.layer.cold.check_1',
      'daily_choice.wear.advisor.layer.cold.check_2',
    ],
  ),
  _WearLayerFormula(
    id: 'rain',
    icon: Icons.umbrella_rounded,
    titleKey: 'daily_choice.wear.advisor.layer.rain.title',
    formulaKeys: <String>[
      'daily_choice.wear.advisor.layer.rain.formula_1',
      'daily_choice.wear.advisor.layer.rain.formula_2',
    ],
    checkKeys: <String>[
      'daily_choice.wear.advisor.layer.rain.check_1',
      'daily_choice.wear.advisor.layer.rain.check_2',
    ],
  ),
];

const List<_WearSceneAdvice> _wearSceneAdvices = <_WearSceneAdvice>[
  _WearSceneAdvice(
    id: 'commute',
    icon: Icons.work_rounded,
    titleKey: 'daily_choice.wear.advisor.scene.commute.title',
    priorityKeys: <String>[
      'daily_choice.wear.advisor.scene.commute.priority_1',
      'daily_choice.wear.advisor.scene.commute.priority_2',
    ],
    avoidKeys: <String>[
      'daily_choice.wear.advisor.scene.commute.avoid_1',
      'daily_choice.wear.advisor.scene.commute.avoid_2',
      'daily_choice.wear.advisor.scene.commute.avoid_3',
    ],
  ),
  _WearSceneAdvice(
    id: 'business',
    icon: Icons.business_center_rounded,
    titleKey: 'daily_choice.wear.advisor.scene.business.title',
    priorityKeys: <String>[
      'daily_choice.wear.advisor.scene.business.priority_1',
      'daily_choice.wear.advisor.scene.business.priority_2',
    ],
    avoidKeys: <String>[
      'daily_choice.wear.advisor.scene.business.avoid_1',
      'daily_choice.wear.advisor.scene.business.avoid_2',
      'daily_choice.wear.advisor.scene.business.avoid_3',
    ],
  ),
  _WearSceneAdvice(
    id: 'date',
    icon: Icons.favorite_rounded,
    titleKey: 'daily_choice.wear.advisor.scene.date.title',
    priorityKeys: <String>[
      'daily_choice.wear.advisor.scene.date.priority_1',
      'daily_choice.wear.advisor.scene.date.priority_2',
    ],
    avoidKeys: <String>[
      'daily_choice.wear.advisor.scene.date.avoid_1',
      'daily_choice.wear.advisor.scene.date.avoid_2',
    ],
  ),
  _WearSceneAdvice(
    id: 'exercise',
    icon: Icons.directions_run_rounded,
    titleKey: 'daily_choice.wear.advisor.scene.exercise.title',
    priorityKeys: <String>[
      'daily_choice.wear.advisor.scene.exercise.priority_1',
      'daily_choice.wear.advisor.scene.exercise.priority_2',
    ],
    avoidKeys: <String>[
      'daily_choice.wear.advisor.scene.exercise.avoid_1',
      'daily_choice.wear.advisor.scene.exercise.avoid_2',
    ],
  ),
  _WearSceneAdvice(
    id: 'rain',
    icon: Icons.umbrella_rounded,
    titleKey: 'daily_choice.wear.advisor.scene.rain.title',
    priorityKeys: <String>[
      'daily_choice.wear.advisor.scene.rain.priority_1',
      'daily_choice.wear.advisor.scene.rain.priority_2',
    ],
    avoidKeys: <String>[
      'daily_choice.wear.advisor.scene.rain.avoid_1',
      'daily_choice.wear.advisor.scene.rain.avoid_2',
      'daily_choice.wear.advisor.scene.rain.avoid_3',
    ],
  ),
];

class _WearWeatherPanel extends StatelessWidget {
  const _WearWeatherPanel({
    required this.i18n,
    required this.accent,
    required this.weatherEnabled,
    required this.weatherLoading,
    required this.suggestion,
    required this.usingSuggestedTemperature,
    required this.onRestoreSuggestedTemperature,
    required this.onSwitchToRainScene,
  });

  final AppI18n i18n;
  final Color accent;
  final bool weatherEnabled;
  final bool weatherLoading;
  final _WearWeatherSuggestion? suggestion;
  final bool usingSuggestedTemperature;
  final VoidCallback onRestoreSuggestedTemperature;
  final VoidCallback? onSwitchToRainScene;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestion = this.suggestion;
    if (suggestion == null) {
      return ToolboxSurfaceCard(
        padding: const EdgeInsets.all(16),
        radius: ToolboxUiTokens.sectionPanelRadius,
        borderColor: accent.withValues(alpha: 0.18),
        shadowColor: accent,
        shadowOpacity: 0.04,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              weatherLoading ? Icons.cloud_sync_rounded : Icons.tune_rounded,
              color: accent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    i18n.t(
                      'inline.ui.pages.toolbox_daily_choice.daily_choice_wear_module.weather_suggestion_727ad3',
                    ),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weatherLoading
                        ? i18n.t(
                            'inline.plan295.daily_choice.loading_weather_a_suitable_temperatu.f26f894528ec',
                          )
                        : weatherEnabled
                        ? i18n.t(
                            'inline.plan295.daily_choice.waiting_for_global_weather_data_the.c3d0ea11819f',
                          )
                        : i18n.t(
                            'inline.plan295.daily_choice.showing_all_temperatures_for_now_if.e4468a625592',
                          ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final snapshot = suggestion.snapshot;
    final weatherLabel = weatherCodeLabel(
      i18n,
      snapshot.weatherCode,
      isDay: snapshot.isDay,
    );
    final recommendedTemperature = _wearTemperatureCategory(
      suggestion.temperatureId,
    );
    final notes = suggestion.notes(i18n);
    final highLow =
        snapshot.todayMaxTemperatureCelsius != null &&
            snapshot.todayMinTemperatureCelsius != null
        ? '${snapshot.todayMinTemperatureCelsius!.round()}°C ~ ${snapshot.todayMaxTemperatureCelsius!.round()}°C'
        : i18n.t('inline.plan295.daily_choice.no_high_low_yet.d5eb46277c71');

    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(16),
      radius: ToolboxUiTokens.sectionPanelRadius,
      borderColor: accent.withValues(alpha: 0.18),
      shadowColor: accent,
      shadowOpacity: 0.06,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  weatherCodeIcon(snapshot.weatherCode, isDay: snapshot.isDay),
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      i18n.t(
                        'inline.ui.pages.toolbox_daily_choice.daily_choice_wear_module.weather_suggestion_727ad3',
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${snapshot.city} · $weatherLabel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (weatherLoading)
                ToolboxInfoPill(
                  text: i18n.t(
                    'inline.plan295.daily_choice.refreshing.7a82b4defcd1',
                  ),
                  accent: accent,
                  backgroundColor: theme.colorScheme.surfaceContainerLow,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxInfoPill(
                text: i18n.t(
                  'inline.plan295.daily_choice.snapshot_temperaturecelsius_round_c.b812c43c7215',
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: i18n.t(
                  'inline.plan295.daily_choice.feels_snapshot_apparenttemperaturece.3782d2ebb643',
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: i18n.t(
                  'inline.plan295.daily_choice.high_low_highlow.14a0357434f6',
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: i18n.t(
                  'inline.plan295.daily_choice.suggest_recommendedtemperature_title.9edbb2638d54',
                ),
                accent: accent,
                backgroundColor: usingSuggestedTemperature
                    ? accent.withValues(alpha: 0.14)
                    : theme.colorScheme.surfaceContainerLow,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            suggestion.summary(i18n),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.42),
          ),
          if (notes.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            for (final note in notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '• ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        note,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.4,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (!usingSuggestedTemperature ||
              onSwitchToRainScene != null) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                if (!usingSuggestedTemperature)
                  OutlinedButton.icon(
                    onPressed: onRestoreSuggestedTemperature,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      i18n.t(
                        'inline.plan295.daily_choice.use_suggestion.3d39fe797dc7',
                      ),
                    ),
                  ),
                if (onSwitchToRainScene != null)
                  OutlinedButton.icon(
                    onPressed: onSwitchToRainScene,
                    icon: const Icon(Icons.umbrella_rounded),
                    label: Text(
                      i18n.t(
                        'inline.plan295.daily_choice.switch_to_rain.d907ae33a5d3',
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WearWeatherSuggestion {
  const _WearWeatherSuggestion({
    required this.snapshot,
    required this.temperatureId,
    required this.apparentTemperature,
    required this.noteKeys,
    required this.noteParams,
    required this.suggestRainScene,
  });

  final WeatherSnapshot snapshot;
  final String temperatureId;
  final int apparentTemperature;
  final List<String> noteKeys;
  final Map<String, Map<String, Object?>> noteParams;
  final bool suggestRainScene;

  String summary(AppI18n i18n) => i18n.t(
    'daily_choice.wear.weather.suggestion.summary',
    params: <String, Object?>{
      'temperature': apparentTemperature,
      'category': _wearTemperatureCategory(temperatureId).title(i18n),
    },
  );

  List<String> notes(AppI18n i18n) => noteKeys
      .map((key) => i18n.t(key, params: noteParams[key] ?? const {}))
      .toList(growable: false);
}

_WearWeatherSuggestion? _buildWearWeatherSuggestion(WeatherSnapshot? snapshot) {
  if (snapshot == null) {
    return null;
  }
  final apparent = snapshot.apparentTemperatureCelsius;
  final temperatureId = _wearTemperatureIdFor(apparent);
  final range =
      ((snapshot.todayMaxTemperatureCelsius ?? apparent) -
              (snapshot.todayMinTemperatureCelsius ?? apparent))
          .abs();
  final rainy = _wearWeatherCodesRain.contains(snapshot.weatherCode);
  final snowy = _wearWeatherCodesSnow.contains(snapshot.weatherCode);
  final windy = snapshot.windSpeedKph >= 24;
  final noteKeys = <String>[];
  final noteParams = <String, Map<String, Object?>>{};
  if (range >= 8) {
    const key = 'daily_choice.wear.weather.note.temperature_swing';
    noteKeys.add(key);
    noteParams[key] = <String, Object?>{'range': range.round()};
  }
  if (rainy) {
    noteKeys.add('daily_choice.wear.weather.note.rain');
  }
  if (snowy) {
    noteKeys.add('daily_choice.wear.weather.note.snow');
  }
  if (windy) {
    const key = 'daily_choice.wear.weather.note.wind';
    noteKeys.add(key);
    noteParams[key] = <String, Object?>{'speed': snapshot.windSpeedKph.round()};
  }
  if (apparent >= 30) {
    noteKeys.add('daily_choice.wear.weather.note.heat');
  } else if (apparent <= 5) {
    noteKeys.add('daily_choice.wear.weather.note.cold');
  }
  return _WearWeatherSuggestion(
    snapshot: snapshot,
    temperatureId: temperatureId,
    apparentTemperature: apparent.round(),
    noteKeys: noteKeys,
    noteParams: noteParams,
    suggestRainScene: rainy,
  );
}

const Set<int> _wearWeatherCodesRain = <int>{
  51,
  53,
  55,
  56,
  57,
  61,
  63,
  65,
  66,
  67,
  80,
  81,
  82,
  95,
  96,
  99,
};

const Set<int> _wearWeatherCodesSnow = <int>{71, 73, 75, 77, 85, 86};

String _wearTemperatureIdFor(double feelsLikeCelsius) {
  if (feelsLikeCelsius < 0) {
    return 'freezing';
  }
  if (feelsLikeCelsius < 10) {
    return 'cold';
  }
  if (feelsLikeCelsius < 15) {
    return 'cool';
  }
  if (feelsLikeCelsius < 25) {
    return 'mild';
  }
  if (feelsLikeCelsius < 30) {
    return 'warm';
  }
  if (feelsLikeCelsius < 35) {
    return 'hot';
  }
  return 'extreme_hot';
}

DailyChoiceCategory _wearTemperatureCategory(String id) {
  return temperatureCategories.firstWhere(
    (item) => item.id == id,
    orElse: () => temperatureCategories.first,
  );
}

class _WearCollectionSelectorPanel extends StatelessWidget {
  const _WearCollectionSelectorPanel({
    required this.i18n,
    required this.accent,
    required this.selectedCollectionId,
    required this.collections,
    required this.builtInExpanded,
    required this.onToggleBuiltInExpanded,
    required this.onSelected,
  });

  final AppI18n i18n;
  final Color accent;
  final String selectedCollectionId;
  final List<DailyChoiceWearCollection> collections;
  final bool builtInExpanded;
  final VoidCallback onToggleBuiltInExpanded;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final builtInCollections = collections
        .where((collection) => isBuiltInWearCollectionId(collection.id))
        .toList(growable: false);
    final userCollections = collections
        .where((collection) => !isBuiltInWearCollectionId(collection.id))
        .toList(growable: false);
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(12),
      radius: ToolboxUiTokens.sectionPanelRadius,
      borderColor: accent.withValues(alpha: 0.14),
      shadowOpacity: 0.03,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            i18n.t('inline.plan295.daily_choice.my_wardrobe.4ffd2eddbe7f'),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            i18n.t(
              'inline.plan295.daily_choice.prioritize_outfits_you_actually_own.693bfe2029df',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          if (userCollections.isEmpty)
            Text(
              i18n.t(
                'inline.plan295.daily_choice.no_personal_wardrobe_yet_add_a_real.ee7bfe2dc3b6',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: userCollections
                  .map(
                    (collection) => ToolboxSelectablePill(
                      selected: selectedCollectionId == collection.id,
                      tint: accent,
                      onTap: () => onSelected(collection.id),
                      leading: const Icon(Icons.checkroom_rounded, size: 18),
                      label: Text(
                        '${collection.title(i18n)} · ${collection.optionIds.length}',
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          const SizedBox(height: 10),
          ToolboxSelectablePill(
            selected: selectedCollectionId == 'all',
            tint: accent,
            onTap: () => onSelected('all'),
            leading: const Icon(Icons.all_inclusive_rounded, size: 18),
            label: Text(
              i18n.t(
                'inline.ui.pages.toolbox_daily_choice.daily_choice_wear_module.all_available_b723ec',
              ),
            ),
          ),
          if (builtInCollections.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onToggleBuiltInExpanded,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.inventory_2_rounded, size: 18, color: accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        i18n.t(
                          'inline.ui.pages.toolbox_daily_choice.daily_choice_wear_module.built_in_references_01087c',
                        ),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    ToolboxInfoPill(
                      text: '${builtInCollections.length}',
                      accent: accent,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      builtInExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: accent,
                    ),
                  ],
                ),
              ),
            ),
            if (builtInExpanded) ...<Widget>[
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: builtInCollections
                    .map(
                      (collection) => ToolboxSelectablePill(
                        selected: selectedCollectionId == collection.id,
                        tint: accent,
                        onTap: () => onSelected(collection.id),
                        leading: const Icon(
                          Icons.inventory_2_rounded,
                          size: 18,
                        ),
                        label: Text(collection.title(i18n)),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _WearAdvancedSettingsPanel extends StatelessWidget {
  const _WearAdvancedSettingsPanel({
    required this.i18n,
    required this.accent,
    required this.expanded,
    required this.selectedFilters,
    required this.onToggleExpanded,
    required this.onToggleTrait,
    required this.onReset,
  });

  final AppI18n i18n;
  final Color accent;
  final bool expanded;
  final Map<String, Set<String>> selectedFilters;
  final VoidCallback onToggleExpanded;
  final void Function(String groupId, String optionId) onToggleTrait;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeCount = selectedFilters.values
        .where((set) => set.isNotEmpty)
        .length;
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(14),
      radius: ToolboxUiTokens.sectionPanelRadius,
      borderColor: accent.withValues(alpha: 0.18),
      shadowColor: accent,
      shadowOpacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            borderRadius: BorderRadius.circular(
              ToolboxUiTokens.sectionPanelRadius,
            ),
            onTap: onToggleExpanded,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          i18n.t(
                            'inline.plan295.daily_choice.advanced_filters.356ca34887f6',
                          ),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activeCount > 0
                              ? i18n.t(
                                  'inline.plan295.daily_choice.activecount_filter_s_enabled.39fb4a8c5390',
                                )
                              : i18n.t(
                                  'inline.plan295.daily_choice.narrow_by_gender_reference_age_stage.9aa91a3903e5',
                                ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (activeCount > 0)
                    ToolboxInfoPill(
                      text: i18n.t(
                        'inline.plan295.daily_choice.activecount_active.ff742077cc87',
                      ),
                      accent: accent,
                      backgroundColor: theme.colorScheme.surfaceContainerLow,
                    ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: AppDurations.quick,
                    curve: AppEasing.standard,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: expanded ? 0.16 : 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withValues(alpha: 0.28)),
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
          if (expanded) ...<Widget>[
            const SizedBox(height: 12),
            for (final group in wearTraitGroups) ...<Widget>[
              _WearAdvancedChipSection(
                i18n: i18n,
                accent: accent,
                group: group,
                selectedIds: selectedFilters[group.id] ?? <String>{},
                onToggle: (optionId) => onToggleTrait(group.id, optionId),
              ),
              const SizedBox(height: 12),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: activeCount > 0 ? onReset : null,
                icon: const Icon(Icons.clear_all_rounded),
                label: Text(
                  i18n.t(
                    'inline.plan295.daily_choice.reset_all_filters.9fc1c34bf733',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WearAdvancedChipSection extends StatelessWidget {
  const _WearAdvancedChipSection({
    required this.i18n,
    required this.accent,
    required this.group,
    required this.selectedIds,
    required this.onToggle,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoiceTraitGroup group;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(group.icon, size: 18, color: accent),
            const SizedBox(width: 6),
            Text(
              group.title(i18n),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
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
          children: group.options
              .map(
                (option) => FilterChip(
                  selected: selectedIds.contains(option.id),
                  label: Text(option.title(i18n)),
                  avatar: Icon(option.icon, size: 16),
                  showCheckmark: false,
                  selectedColor: accent.withValues(alpha: 0.16),
                  onSelected: (_) => onToggle(option.id),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _WearLibraryStatusPanel extends StatelessWidget {
  const _WearLibraryStatusPanel({
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
  final DailyChoiceWearLibraryStatus libraryStatus;
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
                    'inline.plan295.daily_choice.outfit_reference.d19c5e75d27a',
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
          if (hasInstalledLibrary && !busy) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ToolboxInfoPill(
                  text: i18n.t(
                    'inline.plan295.daily_choice.total_librarystatus_outfitcount.b65025c2ec8f',
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
                      ? 'daily_choice.wear.library.loading'
                      : libraryLoading
                      ? 'daily_choice.wear.library.reading'
                      : 'daily_choice.wear.library.download',
                ),
              ),
            ),
          ],
          if (expanded) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              hasInstalledLibrary
                  ? i18n.t(
                      'inline.plan295.daily_choice.built_in_references_are_ready_use_th.7e6e14bcbfb3',
                    )
                  : i18n.t(
                      'inline.plan295.daily_choice.download_the_built_in_reference_once.a89851978b7a',
                    ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
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
                'inline.plan295.daily_choice.the_latest_sync_reported_an_error_th.8e0b62c698cf',
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

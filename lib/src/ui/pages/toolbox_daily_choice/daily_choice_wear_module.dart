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
        ? pickUiText(
            widget.i18n,
            zh: collection == null
                ? '当前浏览全部衣柜。内置数据适合参考，真正好用的结果会来自你逐步整理出的个人衣柜。'
                : '当前只从这个衣柜里抽取。放进来的都应该是你真实拥有、愿意反复穿的组合。',
            en: collection == null
                ? 'Browsing all wardrobes. Built-ins are references; the best results come from your own saved wardrobe.'
                : 'Random picks now come from this wardrobe only, ideally from outfits you actually own and repeat.',
          )
        : (exact.isEmpty && tempFiltered.isNotEmpty
              ? pickUiText(
                  widget.i18n,
                  zh: '当前场景暂无精确项，先从同温度搭配里随机。',
                  en: 'No exact scene match yet; randomizing from the same temperature.',
                )
              : (exact.length == 1 && tempFiltered.length > 1
                    ? pickUiText(
                        widget.i18n,
                        zh: '当前场景条目较少，已混入同温度稳妥备选，让随机更有变化。',
                        en: 'This scene has only one exact match, so same-temperature backups are mixed in for more variety.',
                      )
                    : (_temperatureManuallyEdited && suggestion != null
                          ? pickUiText(
                              widget.i18n,
                              zh: '当前为手动选择：${temperature.titleZh}。天气默认建议是 ${_wearTemperatureCategory(suggestion.temperatureId).titleZh}。',
                              en: 'Manual selection: ${temperature.titleEn}. Weather suggests ${_wearTemperatureCategory(suggestion.temperatureId).titleEn}.',
                            )
                          : scene.subtitle(widget.i18n))));
    final filterNote = _activeTraitFilterCount > 0
        ? pickUiText(
            widget.i18n,
            zh: ' 已应用 $_activeTraitFilterCount 项高级筛选。',
            en: ' $_activeTraitFilterCount advanced filter(s) applied.',
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
          title: pickUiText(widget.i18n, zh: '选择气温', en: 'Temperature'),
          categories: wearTemperatureFilterCategories,
          selectedId: _temperatureId,
          accent: widget.accent,
          compactUnselected: true,
          onSelected: _handleTemperatureSelected,
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        DailyChoiceCategorySelector(
          i18n: widget.i18n,
          title: pickUiText(widget.i18n, zh: '选择场景', en: 'Scene'),
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
          title: pickUiText(
            widget.i18n,
            zh: '${temperature.titleZh} · ${scene.titleZh}',
            en: '${temperature.titleEn} · ${scene.titleEn}',
          ),
          subtitle: panelSubtitle,
          options: traitFiltered,
          emptyText: pickUiText(
            widget.i18n,
            zh: collection != null
                ? '这个衣柜在当前筛选下没有可选搭配。可以放宽筛选，或把你真实会穿的组合加入这个衣柜。'
                : '当前没有命中的搭配。可以先参考内置衣柜，也可以在管理里新建自己的真实衣柜搭配。',
            en: collection != null
                ? 'This wardrobe has no matching outfits. Relax filters or add a real outfit you would actually wear.'
                : 'No matching outfits yet. Use built-ins as references, or add your own wardrobe outfit in Manage.',
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
            title: pickUiText(widget.i18n, zh: '穿搭指南与衣橱方法', en: 'Outfit guide'),
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
                          pickUiText(i18n, zh: '评估建议', en: 'Outfit check'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pickUiText(
                            i18n,
                            zh: '出门前检查比例、颜色、层级和场景，不遮挡主页面。',
                            en: 'Check proportion, color, layers, and scene without covering the page.',
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
          pickUiText(i18n, zh: '出门前 30 秒', en: '30-second check'),
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
          pickUiText(
            i18n,
            zh: '已通过 $checked / $total 项；少于 4 项时先调整，不急着出门。',
            en: '$checked / $total passed. If fewer than 4 pass, adjust before leaving.',
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
          titleZh: '临门修正',
          titleEn: 'Quick fixes',
          itemsZh: const <String>[
            '太正式：先换鞋或包，让整体松一点。',
            '太松散：加腰线、换利落下装或收窄鞋口。',
            '太暗沉：把亮点放在脸部附近，不要全身加色。',
            '天气不稳：多带薄外层，比临时硬扛更舒服。',
          ],
          itemsEn: const <String>[
            'Too formal: change shoes or bag first.',
            'Too loose: define waist, clean up bottoms, or narrow the shoe line.',
            'Too dull: lift color near the face instead of adding color everywhere.',
            'Unstable weather: carry a thin layer instead of forcing the outfit.',
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
          titleZh: '推荐搭配',
          titleEn: 'Good pairings',
          itemsZh: advice.pairZh,
          itemsEn: advice.pairEn,
        ),
        const SizedBox(height: 8),
        _WearAdvisorBulletSection(
          i18n: i18n,
          icon: Icons.block_rounded,
          titleZh: '谨慎避雷',
          titleEn: 'Use carefully',
          itemsZh: advice.avoidZh,
          itemsEn: advice.avoidEn,
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
          titleZh: '层级公式',
          titleEn: 'Layer formula',
          itemsZh: formula.formulaZh,
          itemsEn: formula.formulaEn,
        ),
        const SizedBox(height: 8),
        _WearAdvisorBulletSection(
          i18n: i18n,
          icon: Icons.rule_rounded,
          titleZh: '检查点',
          titleEn: 'Checks',
          itemsZh: formula.checkZh,
          itemsEn: formula.checkEn,
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
          titleZh: '第一优先级',
          titleEn: 'First priority',
          itemsZh: scene.priorityZh,
          itemsEn: scene.priorityEn,
        ),
        const SizedBox(height: 8),
        _WearAdvisorBulletSection(
          i18n: i18n,
          icon: Icons.warning_amber_rounded,
          titleZh: '常见失误',
          titleEn: 'Common misses',
          itemsZh: scene.avoidZh,
          itemsEn: scene.avoidEn,
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
    required this.titleZh,
    required this.titleEn,
    required this.itemsZh,
    required this.itemsEn,
  });

  final AppI18n i18n;
  final IconData icon;
  final String titleZh;
  final String titleEn;
  final List<String> itemsZh;
  final List<String> itemsEn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = AppI18n.normalizeLanguageCode(i18n.languageCode) == 'zh'
        ? itemsZh
        : itemsEn;
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
                pickUiText(i18n, zh: titleZh, en: titleEn),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('• '),
                  Expanded(
                    child: Text(
                      item,
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
    required this.titleZh,
    required this.titleEn,
  });

  @override
  final String id;
  @override
  final IconData icon;
  final String titleZh;
  final String titleEn;

  @override
  String title(AppI18n i18n) => pickUiText(i18n, zh: titleZh, en: titleEn);
}

class _WearAdvisorCheck {
  const _WearAdvisorCheck({
    required this.id,
    required this.titleZh,
    required this.titleEn,
    required this.bodyZh,
    required this.bodyEn,
  });

  final String id;
  final String titleZh;
  final String titleEn;
  final String bodyZh;
  final String bodyEn;

  String title(AppI18n i18n) => pickUiText(i18n, zh: titleZh, en: titleEn);
  String body(AppI18n i18n) => pickUiText(i18n, zh: bodyZh, en: bodyEn);
}

class _WearColorAdvice extends _WearAdvisorTool {
  const _WearColorAdvice({
    required super.id,
    required super.icon,
    required super.titleZh,
    required super.titleEn,
    required this.pairZh,
    required this.pairEn,
    required this.avoidZh,
    required this.avoidEn,
  });

  final List<String> pairZh;
  final List<String> pairEn;
  final List<String> avoidZh;
  final List<String> avoidEn;
}

class _WearLayerFormula extends _WearAdvisorTool {
  const _WearLayerFormula({
    required super.id,
    required super.icon,
    required super.titleZh,
    required super.titleEn,
    required this.formulaZh,
    required this.formulaEn,
    required this.checkZh,
    required this.checkEn,
  });

  final List<String> formulaZh;
  final List<String> formulaEn;
  final List<String> checkZh;
  final List<String> checkEn;
}

class _WearSceneAdvice extends _WearAdvisorTool {
  const _WearSceneAdvice({
    required super.id,
    required super.icon,
    required super.titleZh,
    required super.titleEn,
    required this.priorityZh,
    required this.priorityEn,
    required this.avoidZh,
    required this.avoidEn,
  });

  final List<String> priorityZh;
  final List<String> priorityEn;
  final List<String> avoidZh;
  final List<String> avoidEn;
}

const List<_WearAdvisorTool> _wearAdvisorTools = <_WearAdvisorTool>[
  _WearAdvisorTool(
    id: 'audit',
    icon: Icons.fact_check_rounded,
    titleZh: '评估',
    titleEn: 'Check',
  ),
  _WearAdvisorTool(
    id: 'color',
    icon: Icons.palette_rounded,
    titleZh: '颜色',
    titleEn: 'Color',
  ),
  _WearAdvisorTool(
    id: 'layer',
    icon: Icons.layers_rounded,
    titleZh: '层级',
    titleEn: 'Layers',
  ),
  _WearAdvisorTool(
    id: 'scene',
    icon: Icons.event_available_rounded,
    titleZh: '场景',
    titleEn: 'Scene',
  ),
];

const List<_WearAdvisorCheck> _wearAdvisorAuditChecks = <_WearAdvisorCheck>[
  _WearAdvisorCheck(
    id: 'temperature',
    titleZh: '温度与体感',
    titleEn: 'Temperature',
    bodyZh: '确认体感、风、雨、空调房和室内外温差，不只看气温数字。',
    bodyEn:
        'Check feels-like temperature, wind, rain, AC, and indoor-outdoor swing.',
  ),
  _WearAdvisorCheck(
    id: 'movement',
    titleZh: '行动自由',
    titleEn: 'Movement',
    bodyZh: '坐下、走路、抬手都不需要分心照顾衣服。',
    bodyEn:
        'Sitting, walking, and raising arms should not need constant fixing.',
  ),
  _WearAdvisorCheck(
    id: 'scene',
    titleZh: '场景合适',
    titleEn: 'Scene fit',
    bodyZh: '不比今天角色更用力，也不要让重要场合显得敷衍。',
    bodyEn:
        'Do not overdress for the role, but do not underplay important scenes.',
  ),
  _WearAdvisorCheck(
    id: 'proportion',
    titleZh: '比例收口',
    titleEn: 'Proportion',
    bodyZh: '上下量感有分工，腰线、裤长或鞋口至少有一个清楚收口。',
    bodyEn:
        'Top and bottom share volume; waist, hem, or shoe line has a clear finish.',
  ),
  _WearAdvisorCheck(
    id: 'shoes_bag',
    titleZh: '鞋包统一',
    titleEn: 'Shoes and bag',
    bodyZh: '鞋底安全，包的大小够用，金属色和皮革语气不打架。',
    bodyEn:
        'Soles are safe, bag size works, and metals or leather tones do not clash.',
  ),
  _WearAdvisorCheck(
    id: 'care',
    titleZh: '维护与细节',
    titleEn: 'Care details',
    bodyZh: '易皱、沾毛、防晒、保暖、备用干物和洗护限制都已考虑。',
    bodyEn:
        'Wrinkles, lint, sun, warmth, dry backup, and care limits are accounted for.',
  ),
];

const List<_WearColorAdvice> _wearColorAdvices = <_WearColorAdvice>[
  _WearColorAdvice(
    id: 'black',
    icon: Icons.contrast_rounded,
    titleZh: '黑色单品',
    titleEn: 'Black',
    pairZh: <String>['配白、灰、牛仔蓝最稳。', '加米色或浅卡其会更柔和。', '想提气色，把亮点放在上半身或配饰。'],
    pairEn: <String>[
      'White, grey, and denim blue are safest.',
      'Beige or light khaki softens the look.',
      'Place accents near the upper body or accessories.',
    ],
    avoidZh: <String>['全黑时注意材质层次，否则容易闷。', '黑色贴脸可能显沉，可靠领口或配饰提亮。'],
    avoidEn: <String>[
      'All black needs texture or it can feel flat.',
      'Black near the face can feel heavy; lift it with neckline or accessories.',
    ],
  ),
  _WearColorAdvice(
    id: 'white',
    icon: Icons.light_mode_rounded,
    titleZh: '白色单品',
    titleEn: 'White',
    pairZh: <String>['配海军蓝、灰、卡其会干净。', '白上衣适合承接彩色小配饰。', '白裤装更适合挺括或有厚度的面料。'],
    pairEn: <String>[
      'Navy, grey, and khaki keep it clean.',
      'White tops support small colorful accents.',
      'White bottoms work better in structured fabrics.',
    ],
    avoidZh: <String>['薄白下装容易透，先看光线和内搭。', '大面积白色雨天、通勤挤车要谨慎。'],
    avoidEn: <String>[
      'Thin white bottoms can be sheer; check light and underlayers.',
      'Large white areas need care on rainy or crowded commutes.',
    ],
  ),
  _WearColorAdvice(
    id: 'navy',
    icon: Icons.water_rounded,
    titleZh: '海军蓝',
    titleEn: 'Navy',
    pairZh: <String>['配白、浅灰、牛仔蓝有通勤感。', '配棕色皮鞋或腰带会更稳重。', '想休闲时加条纹、帆布或小白鞋。'],
    pairEn: <String>[
      'White, light grey, and denim feel work-ready.',
      'Brown leather shoes or belt add steadiness.',
      'Stripes, canvas, or white sneakers make it casual.',
    ],
    avoidZh: <String>['避免和过暗黑色混在一起看不出层次。', '正式场景里少用过亮荧光色破坏克制感。'],
    avoidEn: <String>[
      'Avoid mixing with very dark black without contrast.',
      'Keep neon accents away from formal navy looks.',
    ],
  ),
  _WearColorAdvice(
    id: 'khaki',
    icon: Icons.tonality_rounded,
    titleZh: '卡其米色',
    titleEn: 'Khaki',
    pairZh: <String>['配白、海军蓝、黑色最省心。', '同色系可用深浅差做层次。', '加棕色、金色配件会更温和。'],
    pairEn: <String>[
      'White, navy, and black are easy anchors.',
      'Use light-dark shifts within the same family.',
      'Brown or gold accessories soften it.',
    ],
    avoidZh: <String>['全身米色要避开肤色太近的问题。', '软塌面料过多会显得没精神。'],
    avoidEn: <String>[
      'All beige can wash you out if too close to skin tone.',
      'Too many limp fabrics can look tired.',
    ],
  ),
  _WearColorAdvice(
    id: 'accent',
    icon: Icons.color_lens_rounded,
    titleZh: '彩色亮点',
    titleEn: 'Accent',
    pairZh: <String>['一次只保留一个主亮点。', '把彩色放在围巾、包、鞋或上衣小面积。', '用黑白灰、海军蓝或牛仔稳定它。'],
    pairEn: <String>[
      'Keep one main accent at a time.',
      'Use color on scarf, bag, shoes, or a small top area.',
      'Anchor it with black, white, grey, navy, or denim.',
    ],
    avoidZh: <String>['不要多个高饱和彩色平均分布。', '靠近脸的颜色先看气色，不只看流行。'],
    avoidEn: <String>[
      'Avoid several loud colors in equal weight.',
      'Near-face color should flatter you, not only follow trends.',
    ],
  ),
];

const List<_WearLayerFormula> _wearLayerFormulas = <_WearLayerFormula>[
  _WearLayerFormula(
    id: 'hot',
    icon: Icons.wb_sunny_rounded,
    titleZh: '炎热',
    titleEn: 'Hot',
    formulaZh: <String>['透气单层 + 防晒部件 + 易走鞋。', '材质优先棉麻、天丝、薄针织或速干。'],
    formulaEn: <String>[
      'Breathable single layer + sun protection + walkable shoes.',
      'Prefer cotton-linen, Tencel, thin knit, or quick-dry fabrics.',
    ],
    checkZh: <String>['浅色不等于凉快，透气和不贴身更重要。', '空调房准备薄外层，不要靠厚面料硬扛。'],
    checkEn: <String>[
      'Light color is not enough; airflow and non-clingy fit matter.',
      'Carry a thin layer for AC instead of wearing heavy fabric.',
    ],
  ),
  _WearLayerFormula(
    id: 'mild',
    icon: Icons.filter_drama_rounded,
    titleZh: '温和',
    titleEn: 'Mild',
    formulaZh: <String>['基础内层 + 轻外套 / 衬衫外穿 + 利落鞋。', '把亮点放在颜色、鞋包或一件配饰。'],
    formulaEn: <String>[
      'Base layer + light jacket or overshirt + clean shoes.',
      'Put the accent on color, shoes, bag, or one accessory.',
    ],
    checkZh: <String>['早晚温差大时外层要能塞包或拿在手里。', '裤长和鞋口决定整套是否清爽。'],
    checkEn: <String>[
      'If mornings and evenings swing, the outer layer must pack or carry easily.',
      'Hem and shoe line decide whether it feels clean.',
    ],
  ),
  _WearLayerFormula(
    id: 'cold',
    icon: Icons.ac_unit_rounded,
    titleZh: '冷天',
    titleEn: 'Cold',
    formulaZh: <String>['排汗内层 + 保暖中层 + 挡风外层。', '颈部、手部、脚踝和鞋底要一起看。'],
    formulaEn: <String>[
      'Moisture-managing base + warm mid-layer + wind-blocking outer.',
      'Check neck, hands, ankles, and sole grip together.',
    ],
    checkZh: <String>['不要只堆厚外套，中层空气层更重要。', '室内久坐时外层要容易脱。'],
    checkEn: <String>[
      'Do not rely only on a thick coat; the mid-layer air gap matters.',
      'Outerwear should come off easily for long indoor sitting.',
    ],
  ),
  _WearLayerFormula(
    id: 'rain',
    icon: Icons.umbrella_rounded,
    titleZh: '雨天',
    titleEn: 'Rain',
    formulaZh: <String>['快干内层 + 防泼外层 + 防滑鞋。', '裤脚不拖地，包里留备用干物。'],
    formulaEn: <String>[
      'Quick-dry layer + water-repellent shell + grippy shoes.',
      'Keep hems off the ground and pack dry backup items.',
    ],
    checkZh: <String>['长裙、阔裤和浅色麂皮雨天都要谨慎。', '伞、帽子、包口和鞋面一起防水。'],
    checkEn: <String>[
      'Long skirts, wide pants, and light suede need caution in rain.',
      'Umbrella, hat, bag opening, and shoe upper all need weather control.',
    ],
  ),
];

const List<_WearSceneAdvice> _wearSceneAdvices = <_WearSceneAdvice>[
  _WearSceneAdvice(
    id: 'commute',
    icon: Icons.work_rounded,
    titleZh: '通勤',
    titleEn: 'Commute',
    priorityZh: <String>['耐坐、耐走、耐空调。', '颜色和轮廓先稳，亮点小面积。'],
    priorityEn: <String>[
      'Survive sitting, walking, and AC.',
      'Keep color and shape stable; use small accents.',
    ],
    avoidZh: <String>['鞋太难走。', '外套太容易皱。', '包容量不够导致手上东西太多。'],
    avoidEn: <String>[
      'Shoes that cannot walk.',
      'Jackets that wrinkle too easily.',
      'Bags too small for the day.',
    ],
  ),
  _WearSceneAdvice(
    id: 'business',
    icon: Icons.business_center_rounded,
    titleZh: '正式',
    titleEn: 'Business',
    priorityZh: <String>['肩线、裤线、鞋面干净。', '颜色少一点，材质挺一点。'],
    priorityEn: <String>[
      'Clean shoulder line, trouser line, and shoes.',
      'Use fewer colors and more structure.',
    ],
    avoidZh: <String>['图案过多。', '面料过软塌。', '配饰声音太大或太抢。'],
    avoidEn: <String>[
      'Too many patterns.',
      'Fabric too limp.',
      'Accessories that are noisy or distracting.',
    ],
  ),
  _WearSceneAdvice(
    id: 'date',
    icon: Icons.favorite_rounded,
    titleZh: '约会',
    titleEn: 'Date',
    priorityZh: <String>['舒服、亲近、一个记忆点。', '脸部附近可以更柔和或更提气色。'],
    priorityEn: <String>[
      'Comfort, approachability, and one memorable point.',
      'Near-face color can be softer or more flattering.',
    ],
    avoidZh: <String>['为了拍照牺牲行动。', '香水、配饰或鞋过度用力。'],
    avoidEn: <String>[
      'Sacrificing movement for photos.',
      'Overdoing fragrance, accessories, or shoes.',
    ],
  ),
  _WearSceneAdvice(
    id: 'exercise',
    icon: Icons.directions_run_rounded,
    titleZh: '运动',
    titleEn: 'Exercise',
    priorityZh: <String>['排汗、活动范围、鞋底支撑。', '外层要能快速穿脱。'],
    priorityEn: <String>[
      'Sweat control, movement range, and sole support.',
      'Outer layer should go on and off quickly.',
    ],
    avoidZh: <String>['棉厚卫衣长时间贴身。', '裤腰或肩背影响动作。'],
    avoidEn: <String>[
      'Heavy cotton staying wet against skin.',
      'Waistband or shoulders restricting movement.',
    ],
  ),
  _WearSceneAdvice(
    id: 'rain',
    icon: Icons.umbrella_rounded,
    titleZh: '雨天',
    titleEn: 'Rain',
    priorityZh: <String>['防滑、快干、不拖地。', '包口、鞋面、裤脚先处理。'],
    priorityEn: <String>[
      'Grip, quick-dry, and no dragging hems.',
      'Handle bag opening, shoe upper, and hems first.',
    ],
    avoidZh: <String>['长裤堆脚面。', '浅色绒面鞋。', '需要双手一直整理的外套。'],
    avoidEn: <String>[
      'Pants pooling on shoes.',
      'Light suede shoes.',
      'Outerwear that needs constant fixing.',
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
                    pickUiText(i18n, zh: '天气建议', en: 'Weather suggestion'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weatherLoading
                        ? pickUiText(
                            i18n,
                            zh: '正在读取当前天气，读取完成后会默认推荐合适的气温档位。',
                            en: 'Loading weather. A suitable temperature band will be selected by default when ready.',
                          )
                        : pickUiText(
                            i18n,
                            zh: weatherEnabled
                                ? '正在等待全局天气数据，当前先查看全部气温，你也可以手动改档位。'
                                : '当前先查看全部气温；若启动天气提醒已读取天气，这里会自动用于穿搭建议。',
                            en: weatherEnabled
                                ? 'Waiting for global weather data. The module shows all temperatures for now, and you can adjust it manually.'
                                : 'Showing all temperatures for now. If startup weather has loaded, it will be used here automatically.',
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
        : pickUiText(i18n, zh: '暂无高低温', en: 'No high-low yet');

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
                      pickUiText(i18n, zh: '天气建议', en: 'Weather suggestion'),
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
                  text: pickUiText(i18n, zh: '更新中', en: 'Refreshing'),
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
                text: pickUiText(
                  i18n,
                  zh: '当前 ${snapshot.temperatureCelsius.round()}°C',
                  en: '${snapshot.temperatureCelsius.round()}°C now',
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: pickUiText(
                  i18n,
                  zh: '体感 ${snapshot.apparentTemperatureCelsius.round()}°C',
                  en: 'Feels ${snapshot.apparentTemperatureCelsius.round()}°C',
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: pickUiText(
                  i18n,
                  zh: '高低温 $highLow',
                  en: 'High-low $highLow',
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: pickUiText(
                  i18n,
                  zh: '推荐 ${recommendedTemperature.titleZh}',
                  en: 'Suggest ${recommendedTemperature.titleEn}',
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
                      pickUiText(i18n, zh: '恢复天气推荐', en: 'Use suggestion'),
                    ),
                  ),
                if (onSwitchToRainScene != null)
                  OutlinedButton.icon(
                    onPressed: onSwitchToRainScene,
                    icon: const Icon(Icons.umbrella_rounded),
                    label: Text(
                      pickUiText(i18n, zh: '切到雨天场景', en: 'Switch to rain'),
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
    required this.summaryZh,
    required this.summaryEn,
    required this.notesZh,
    required this.notesEn,
    required this.suggestRainScene,
  });

  final WeatherSnapshot snapshot;
  final String temperatureId;
  final String summaryZh;
  final String summaryEn;
  final List<String> notesZh;
  final List<String> notesEn;
  final bool suggestRainScene;

  String summary(AppI18n i18n) =>
      pickUiText(i18n, zh: summaryZh, en: summaryEn);

  List<String> notes(AppI18n i18n) {
    if (AppI18n.normalizeLanguageCode(i18n.languageCode) == 'zh') {
      return notesZh;
    }
    return notesEn.isEmpty ? notesZh : notesEn;
  }
}

_WearWeatherSuggestion? _buildWearWeatherSuggestion(WeatherSnapshot? snapshot) {
  if (snapshot == null) {
    return null;
  }
  final apparent = snapshot.apparentTemperatureCelsius;
  final temperatureId = _wearTemperatureIdFor(apparent);
  final recommended = _wearTemperatureCategory(temperatureId);
  final range =
      ((snapshot.todayMaxTemperatureCelsius ?? apparent) -
              (snapshot.todayMinTemperatureCelsius ?? apparent))
          .abs();
  final rainy = _wearWeatherCodesRain.contains(snapshot.weatherCode);
  final snowy = _wearWeatherCodesSnow.contains(snapshot.weatherCode);
  final windy = snapshot.windSpeedKph >= 24;
  final notesZh = <String>[];
  final notesEn = <String>[];
  if (range >= 8) {
    notesZh.add('今天温差 ${range.round()}°C，优先选可穿脱的外层。');
    notesEn.add(
      'The temperature swing is ${range.round()}°C today, so keep the outer layer easy to remove.',
    );
  }
  if (rainy) {
    notesZh.add('当前有降水，鞋底防滑、面料快干会更稳妥。');
    notesEn.add(
      'There is precipitation, so grippy soles and quick-dry fabrics are safer.',
    );
  }
  if (snowy) {
    notesZh.add('当前有降雪，保暖和抓地力要优先于轻薄造型。');
    notesEn.add(
      'Snow is expected, so warmth and traction matter more than light styling.',
    );
  }
  if (windy) {
    notesZh.add('风速约 ${snapshot.windSpeedKph.round()} km/h，尽量带一层防风外搭。');
    notesEn.add(
      'Wind is around ${snapshot.windSpeedKph.round()} km/h, so add a wind-blocking layer.',
    );
  }
  if (apparent >= 30) {
    notesZh.add('高温时段尽量减少暴晒，补水和防晒都别省。');
    notesEn.add(
      'During high heat, limit sun exposure and keep hydration plus sun protection in place.',
    );
  } else if (apparent <= 5) {
    notesZh.add('低温里别只顾上半身，颈部、手部和脚踝也要一起保暖。');
    notesEn.add(
      'In low temperatures, keep the neck, hands, and ankles warm too.',
    );
  }
  return _WearWeatherSuggestion(
    snapshot: snapshot,
    temperatureId: temperatureId,
    summaryZh: '根据当前体感 ${apparent.round()}°C，默认推荐“${recommended.titleZh}”档位。',
    summaryEn:
        'Based on a feels-like temperature of ${apparent.round()}°C, the default suggestion is ${recommended.titleEn}.',
    notesZh: notesZh,
    notesEn: notesEn,
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
            pickUiText(i18n, zh: '我的衣柜', en: 'My wardrobe'),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pickUiText(
              i18n,
              zh: '优先从你真实拥有、愿意反复穿的搭配里随机。',
              en: 'Prioritize outfits you actually own and repeat.',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          if (userCollections.isEmpty)
            Text(
              pickUiText(
                i18n,
                zh: '还没有自己的衣柜。先在管理里新建一套真实搭配，随机会更有用。',
                en: 'No personal wardrobe yet. Add a real outfit in Manage to make random picks useful.',
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
            label: Text(pickUiText(i18n, zh: '全部可用', en: 'All available')),
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
                        pickUiText(i18n, zh: '内置参考', en: 'Built-in references'),
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
                          pickUiText(i18n, zh: '高级筛选', en: 'Advanced filters'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activeCount > 0
                              ? pickUiText(
                                  i18n,
                                  zh: '已启用 $activeCount 项筛选',
                                  en: '$activeCount filter(s) enabled',
                                )
                              : pickUiText(
                                  i18n,
                                  zh: '按性别参考、年龄阶段、风格、版型和面料缩小范围',
                                  en: 'Narrow by gender reference, age stage, style, silhouette, and fabric',
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
                      text: pickUiText(
                        i18n,
                        zh: '$activeCount 项',
                        en: '$activeCount active',
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
                  pickUiText(i18n, zh: '重置全部筛选', en: 'Reset all filters'),
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
                  pickUiText(i18n, zh: '穿搭参考库', en: 'Outfit reference'),
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
                  text: pickUiText(
                    i18n,
                    zh: '总库 ${libraryStatus.outfitCount}',
                    en: 'Total ${libraryStatus.outfitCount}',
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
                  zh: busy ? '正在加载穿搭参考…' : '下载内置参考衣柜',
                  en: libraryInstalling
                      ? 'Loading outfit references…'
                      : libraryLoading
                      ? 'Reading outfit references…'
                      : 'Download built-in reference',
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
                    ? '内置参考已就绪。你可以先借它找方向，再把真正适合自己的组合另存到我的衣柜。'
                    : '首次使用可下载内置参考衣柜；之后建议把自己的真实搭配逐步录入。',
                en: hasInstalledLibrary
                    ? 'Built-in references are ready. Use them for direction, then save your real outfits into your wardrobe.'
                    : 'Download the built-in reference once, then gradually add your real outfits.',
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
              pickUiText(
                i18n,
                zh: '最近一次同步有异常，当前会继续使用本地可用穿搭库。',
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

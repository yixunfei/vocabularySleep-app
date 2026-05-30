part of 'daily_choice_hub.dart';

class _PlaceChoiceModule extends StatefulWidget {
  const _PlaceChoiceModule({
    super.key,
    required this.i18n,
    required this.accent,
    required this.options,
    required this.builtInOptions,
    required this.customState,
    required this.onStateChanged,
    required this.libraryStatus,
    required this.libraryLoading,
    required this.libraryInstalling,
    required this.onInstallLibrary,
    this.onInspectOption,
    this.onAdjustBuiltInOption,
    this.onSaveBuiltInAsCustom,
    required this.placeMapSettings,
    required this.onPlaceMapSettingsChanged,
    required this.onSaveOsmPlace,
  });

  final AppI18n i18n;
  final Color accent;
  final List<DailyChoiceOption> options;
  final List<DailyChoiceOption> builtInOptions;
  final DailyChoiceCustomState customState;
  final ValueChanged<DailyChoiceCustomState> onStateChanged;
  final DailyChoicePlaceLibraryStatus libraryStatus;
  final bool libraryLoading;
  final bool libraryInstalling;
  final Future<void> Function() onInstallLibrary;
  final Future<void> Function(DailyChoiceOption option)? onInspectOption;
  final Future<DailyChoiceOption?> Function(DailyChoiceOption option)?
  onAdjustBuiltInOption;
  final DailyChoiceSaveAsCustomEditor? onSaveBuiltInAsCustom;
  final DailyChoicePlaceMapSettings placeMapSettings;
  final ValueChanged<DailyChoicePlaceMapSettings> onPlaceMapSettingsChanged;
  final Future<DailyChoiceOption> Function(DailyChoiceOsmPlace place)
  onSaveOsmPlace;

  @override
  State<_PlaceChoiceModule> createState() => _PlaceChoiceModuleState();
}

class _PlaceChoiceModuleState extends State<_PlaceChoiceModule> {
  String _placeId = 'outside';
  String _sceneId = allPlaceSceneCategory.id;
  bool _libraryStatusExpanded = false;

  String _categoryTitle(DailyChoiceCategory category, String languageCode) =>
      category.title(AppI18n(languageCode));

  @override
  Widget build(BuildContext context) {
    final hasInstalledLibrary = widget.libraryStatus.hasInstalledLibrary;
    final busy = widget.libraryInstalling || widget.libraryLoading;
    final sceneFilters = <DailyChoiceCategory>[
      allPlaceSceneCategory,
      ...placeSceneCategories,
    ];
    final inDistance = widget.options
        .where((item) => item.categoryId == _placeId)
        .toList(growable: false);
    final filtered = _sceneId == allPlaceSceneCategory.id
        ? inDistance
        : inDistance
              .where((item) => _matchesPlaceScene(item, _sceneId))
              .toList(growable: false);
    final category = placeCategories.firstWhere((item) => item.id == _placeId);
    final scene = sceneFilters.firstWhere((item) => item.id == _sceneId);
    final sceneCoverageCount = placeSceneCategories
        .where(
          (item) =>
              inDistance.any((option) => _matchesPlaceScene(option, item.id)),
        )
        .length;
    final subtitle = _sceneId == allPlaceSceneCategory.id
        ? widget.i18n.t(
            'inline.plan295.daily_choice.category_subtitleen_then_randomize_a.ef4bd170b52d',
            params: <String, Object?>{
              'categorySubtitleEn': category.subtitle(AppI18n('en')),
            },
          )
        : widget.i18n.t(
            'inline.plan295.daily_choice.scene_subtitleen_filtered_length_can.4eddf714a17c',
            params: <String, Object?>{
              'filtered': filtered.length,
              'sceneSubtitleEn': scene.subtitle(AppI18n('en')),
            },
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DailyChoiceCategorySelector(
          i18n: widget.i18n,
          title: widget.i18n.t(
            'inline.plan295.daily_choice.distance.818a920ab3e8',
          ),
          categories: placeCategories,
          selectedId: _placeId,
          accent: widget.accent,
          compactUnselected: true,
          onSelected: (value) => setState(() => _placeId = value),
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        DailyChoiceCategorySelector(
          i18n: widget.i18n,
          title: widget.i18n.t(
            'inline.plan295.daily_choice.scene.6f88551df562',
          ),
          categories: sceneFilters,
          selectedId: _sceneId,
          accent: widget.accent,
          compactUnselected: true,
          onSelected: (value) => setState(() => _sceneId = value),
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        _PlaceChoiceStatusPanel(
          i18n: widget.i18n,
          accent: widget.accent,
          selectedDistance: category,
          selectedScene: scene,
          usingAllScenes: _sceneId == allPlaceSceneCategory.id,
          distanceCount: inDistance.length,
          candidateCount: filtered.length,
          sceneCoverageCount: sceneCoverageCount,
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        _PlaceLibraryStatusPanel(
          i18n: widget.i18n,
          accent: widget.accent,
          libraryStatus: widget.libraryStatus,
          busy: busy,
          libraryInstalling: widget.libraryInstalling,
          libraryLoading: widget.libraryLoading,
          hasInstalledLibrary: hasInstalledLibrary,
          expanded: _libraryStatusExpanded,
          onInstallLibrary: widget.onInstallLibrary,
          onToggleExpanded: () =>
              setState(() => _libraryStatusExpanded = !_libraryStatusExpanded),
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        DailyChoicePlaceMapPanel(
          i18n: widget.i18n,
          accent: widget.accent,
          settings: widget.placeMapSettings,
          onSettingsChanged: widget.onPlaceMapSettingsChanged,
          onSavePlace: widget.onSaveOsmPlace,
          activeDistanceCategory: category,
          activeSceneCategory: scene,
          savedOptionIds: widget.customState.customOptions
              .where(
                (item) =>
                    item.moduleId == DailyChoiceModuleId.go.storageValue &&
                    item.id.startsWith('go_osm_'),
              )
              .map((item) => item.id)
              .toSet(),
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        DailyChoiceRandomPanel(
          i18n: widget.i18n,
          accent: widget.accent,
          title: _sceneId == allPlaceSceneCategory.id
              ? widget.i18n.t(
                  'inline.plan295.daily_choice.where_to_go.5e249f9e8d96',
                  params: <String, Object?>{
                    'category.titleZh': _categoryTitle(category, 'zh'),
                  },
                )
              : widget.i18n.t(
                  'inline.plan295.daily_choice.category_titleen_scene_titleen.9cb81855c227',
                  params: <String, Object?>{
                    'categoryTitleEn': _categoryTitle(category, 'en'),
                    'sceneTitleEn': _categoryTitle(scene, 'en'),
                    'category.titleZh': _categoryTitle(category, 'zh'),
                    'scene.titleZh': _categoryTitle(scene, 'zh'),
                    'category.titleEn': _categoryTitle(category, 'en'),
                    'scene.titleEn': _categoryTitle(scene, 'en'),
                  },
                ),
          subtitle: subtitle,
          options: filtered,
          emptyText: _sceneId == allPlaceSceneCategory.id
              ? widget.i18n.t(
                  'inline.plan295.daily_choice.no_destinations_are_available_in_thi.c62002961f05',
                )
              : widget.i18n.t(
                  'inline.plan295.daily_choice.no_destinations_match_this_distance.974e4f6c0b8b',
                ),
          onDetail: (option) {
            final handler = widget.onInspectOption;
            if (handler != null) {
              unawaited(handler(option));
              return;
            }
            showDailyChoiceDetailSheet(
              context: context,
              i18n: widget.i18n,
              accent: widget.accent,
              option: option,
            );
          },
          onGuide: () => showDailyChoiceGuideSheet(
            context: context,
            i18n: widget.i18n,
            accent: widget.accent,
            title: widget.i18n.t(
              'inline.ui.pages.toolbox_daily_choice.daily_choice_modules.going_out_guide_136dac',
            ),
            modules: placeGuideModules,
          ),
          onManage: () => showDailyChoiceManagerSheet(
            context: context,
            i18n: widget.i18n,
            accent: widget.accent,
            moduleId: 'go',
            builtInOptions: widget.builtInOptions,
            state: widget.customState,
            onStateChanged: widget.onStateChanged,
            categories: placeCategories,
            initialCategoryId: _placeId,
            contexts: placeSceneCategories,
            initialContextId: _sceneId == allPlaceSceneCategory.id
                ? placeSceneCategories.first.id
                : _sceneId,
            contextLabelKey: 'toolbox.daily_choice.editor.field.scene',
            onInspectOption: widget.onInspectOption,
            onAdjustBuiltInOption: widget.onAdjustBuiltInOption,
            onSaveBuiltInAsCustom: widget.onSaveBuiltInAsCustom,
          ),
        ),
      ],
    );
  }
}

class _PlaceChoiceStatusPanel extends StatelessWidget {
  const _PlaceChoiceStatusPanel({
    required this.i18n,
    required this.accent,
    required this.selectedDistance,
    required this.selectedScene,
    required this.usingAllScenes,
    required this.distanceCount,
    required this.candidateCount,
    required this.sceneCoverageCount,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoiceCategory selectedDistance;
  final DailyChoiceCategory selectedScene;
  final bool usingAllScenes;
  final int distanceCount;
  final int candidateCount;
  final int sceneCoverageCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = usingAllScenes
        ? i18n.t(
            'inline.plan295.daily_choice.the_current_selecteddistance_titleen.c289a8372f20',
            params: <String, Object?>{
              'distanceCount': distanceCount,
              'sceneCoverageCount': sceneCoverageCount,
              'selectedDistanceTitleEn': selectedDistance.title(AppI18n('en')),
            },
          )
        : candidateCount == 0
        ? i18n.t(
            'inline.plan295.daily_choice.there_are_no_candidates_for_selected.02201253e526',
            params: <String, Object?>{
              'selectedDistanceTitleEn': selectedDistance.title(AppI18n('en')),
              'selectedSceneTitleEn': selectedScene.title(AppI18n('en')),
            },
          )
        : i18n.t(
            'inline.plan295.daily_choice.the_current_selecteddistance_titleen.c5724f7be4ad',
            params: <String, Object?>{
              'candidateCount': candidateCount,
              'selectedDistanceTitleEn': selectedDistance.title(AppI18n('en')),
              'selectedSceneTitleEn': selectedScene.title(AppI18n('en')),
            },
          );
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(16),
      radius: ToolboxUiTokens.sectionPanelRadius,
      borderColor: accent.withValues(alpha: 0.18),
      shadowColor: accent,
      shadowOpacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxInfoPill(
                text: i18n.t(
                  'inline.plan295.daily_choice.distance_selecteddistance_titleen.d2dae2086fe7',
                  params: <String, Object?>{
                    'selectedDistanceTitleEn': selectedDistance.title(
                      AppI18n('en'),
                    ),
                  },
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: usingAllScenes
                    ? i18n.t(
                        'inline.plan295.daily_choice.scene_all.ace6a6f998cb',
                      )
                    : i18n.t(
                        'inline.plan295.daily_choice.scene_selectedscene_titleen.36a46f133169',
                        params: <String, Object?>{
                          'selectedSceneTitleEn': selectedScene.title(
                            AppI18n('en'),
                          ),
                          'selectedScene.titleZh': selectedScene.title(
                            AppI18n('zh'),
                          ),
                          'selectedScene.titleEn': selectedScene.title(
                            AppI18n('en'),
                          ),
                        },
                      ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: i18n.t(
                  'inline.plan295.daily_choice.distancecount_in_this_tier.70a0d57ac81e',
                  params: <String, Object?>{'distanceCount': distanceCount},
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: i18n.t(
                  'inline.plan295.daily_choice.candidatecount_candidates.fa6ad8b2a1d1',
                  params: <String, Object?>{'candidateCount': candidateCount},
                ),
                accent: accent,
                backgroundColor: candidateCount == 0
                    ? theme.colorScheme.errorContainer
                    : theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: i18n.t(
                  'inline.plan295.daily_choice.scenecoveragecount_covered_scenes.bd3688135666',
                  params: <String, Object?>{
                    'sceneCoverageCount': sceneCoverageCount,
                  },
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.42),
          ),
        ],
      ),
    );
  }
}

bool _matchesPlaceScene(DailyChoiceOption option, String sceneId) {
  if (option.contextId == sceneId) {
    return true;
  }
  return option.contextIds.contains(sceneId);
}

class _ActivityChoiceModule extends StatefulWidget {
  const _ActivityChoiceModule({
    super.key,
    required this.i18n,
    required this.accent,
    required this.options,
    required this.builtInOptions,
    required this.customState,
    required this.onStateChanged,
    required this.libraryStatus,
    required this.libraryLoading,
    required this.libraryInstalling,
    required this.onInstallLibrary,
    required this.activityCollections,
    this.onInspectOption,
  });

  final AppI18n i18n;
  final Color accent;
  final List<DailyChoiceOption> options;
  final List<DailyChoiceOption> builtInOptions;
  final DailyChoiceCustomState customState;
  final ValueChanged<DailyChoiceCustomState> onStateChanged;
  final DailyChoiceActivityLibraryStatus libraryStatus;
  final bool libraryLoading;
  final bool libraryInstalling;
  final Future<void> Function() onInstallLibrary;
  final List<DailyChoiceActivityCollection> activityCollections;
  final Future<void> Function(DailyChoiceOption option)? onInspectOption;

  @override
  State<_ActivityChoiceModule> createState() => _ActivityChoiceModuleState();
}

class _ActivityChoiceModuleState extends State<_ActivityChoiceModule> {
  String _activityId = randomActivityCategory.id;
  String _collectionId = 'all';
  bool _libraryStatusExpanded = false;

  String _categoryTitle(DailyChoiceCategory category, String languageCode) =>
      category.title(AppI18n(languageCode));

  @override
  Widget build(BuildContext context) {
    final categories = <DailyChoiceCategory>[
      randomActivityCategory,
      ...activityCategories,
    ];
    final filtered = _activityId == randomActivityCategory.id
        ? _optionsForCollection(widget.options)
        : _optionsForCollection(widget.options)
              .where((item) => item.categoryId == _activityId)
              .toList(growable: false);
    final category = categories.firstWhere((item) => item.id == _activityId);
    final selectedCollection = _activityCollectionById(_collectionId);
    if (_collectionId != 'all' && selectedCollection == null) {
      _collectionId = 'all';
    }
    final collectionTitle = selectedCollection?.title(widget.i18n);
    final busy = widget.libraryLoading || widget.libraryInstalling;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DailyChoiceCategorySelector(
          i18n: widget.i18n,
          title: widget.i18n.t(
            'inline.plan295.daily_choice.direction.4a540ce8efd7',
          ),
          categories: categories,
          selectedId: _activityId,
          accent: widget.accent,
          compactUnselected: true,
          onSelected: (value) => setState(() => _activityId = value),
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        _ActivityCollectionSelector(
          i18n: widget.i18n,
          accent: widget.accent,
          collections: widget.activityCollections,
          selectedId: _collectionId,
          onChanged: (value) => setState(() => _collectionId = value),
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        _ActivityLibraryStatusPanel(
          i18n: widget.i18n,
          accent: widget.accent,
          status: widget.libraryStatus,
          busy: busy,
          installing: widget.libraryInstalling,
          loading: widget.libraryLoading,
          expanded: _libraryStatusExpanded,
          onInstallLibrary: widget.onInstallLibrary,
          onToggleExpanded: () =>
              setState(() => _libraryStatusExpanded = !_libraryStatusExpanded),
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        DailyChoiceRandomPanel(
          i18n: widget.i18n,
          accent: widget.accent,
          title: _activityId == randomActivityCategory.id
              ? widget.i18n.t(
                  'inline.plan295.daily_choice.what_to_do_today.ddf9c6a572e4',
                )
              : widget.i18n.t(
                  'inline.plan295.daily_choice.what_to_do.f2157bc059ce',
                  params: <String, Object?>{
                    'category.titleZh': _categoryTitle(category, 'zh'),
                  },
                ),
          subtitle: collectionTitle == null
              ? category.subtitle(widget.i18n)
              : widget.i18n.t(
                  'inline.plan295.daily_choice.category_subtitleen_current_set_coll.912e0bcfb629',
                  params: <String, Object?>{
                    'categorySubtitleEn': category.subtitle(AppI18n('en')),
                    'collectionTitle': collectionTitle,
                  },
                ),
          options: filtered,
          emptyText: widget.libraryStatus.hasInstalledLibrary
              ? widget.i18n.t(
                  'inline.plan295.daily_choice.no_actions_match_this_direction_or_s.0774932d65af',
                )
              : widget.i18n.t(
                  'inline.plan295.daily_choice.the_built_in_action_library_is_not_i.3f25a0601cf6',
                ),
          onDetail: (option) {
            final handler = widget.onInspectOption;
            if (handler != null) {
              unawaited(handler(option));
              return;
            }
            showDailyChoiceDetailSheet(
              context: context,
              i18n: widget.i18n,
              accent: widget.accent,
              option: option,
            );
          },
          onGuide: () => showDailyChoiceGuideSheet(
            context: context,
            i18n: widget.i18n,
            accent: widget.accent,
            title: widget.i18n.t(
              'inline.plan295.daily_choice.action_guide.d5fd9e8501dd',
            ),
            modules: activityGuideModules,
          ),
          onManage: () => showDailyChoiceManagerSheet(
            context: context,
            i18n: widget.i18n,
            accent: widget.accent,
            moduleId: 'activity',
            builtInOptions: widget.builtInOptions,
            state: widget.customState,
            onStateChanged: widget.onStateChanged,
            categories: activityCategories,
            initialCategoryId: _activityId == randomActivityCategory.id
                ? activityCategories.first.id
                : _activityId,
            onInspectOption: widget.onInspectOption,
          ),
        ),
      ],
    );
  }

  List<DailyChoiceOption> _optionsForCollection(
    List<DailyChoiceOption> options,
  ) {
    if (_collectionId == 'all') {
      return options;
    }
    final collection = _activityCollectionById(_collectionId);
    if (collection == null) {
      return options;
    }
    final allowedIds = collection.optionIds.toSet();
    return options
        .where((item) => allowedIds.contains(item.id))
        .toList(growable: false);
  }

  DailyChoiceActivityCollection? _activityCollectionById(String collectionId) {
    if (collectionId == 'all') {
      return null;
    }
    for (final collection in widget.activityCollections) {
      if (collection.id == collectionId) {
        return collection;
      }
    }
    return null;
  }
}

class _ActivityCollectionSelector extends StatelessWidget {
  const _ActivityCollectionSelector({
    required this.i18n,
    required this.accent,
    required this.collections,
    required this.selectedId,
    required this.onChanged,
  });

  final AppI18n i18n;
  final Color accent;
  final List<DailyChoiceActivityCollection> collections;
  final String selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final validSelectedId =
        selectedId == 'all' || collections.any((item) => item.id == selectedId)
        ? selectedId
        : 'all';
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(14),
      radius: ToolboxUiTokens.sectionPanelRadius,
      borderColor: accent.withValues(alpha: 0.14),
      shadowOpacity: 0.03,
      child: DropdownButtonFormField<String>(
        initialValue: validSelectedId,
        isExpanded: true,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.playlist_add_check_rounded),
          labelText: i18n.t(
            'inline.plan295.daily_choice.action_set.4eac820898d7',
          ),
          helperText: i18n.t(
            'inline.plan295.daily_choice.random_picks_draw_from_this_set_buil.dfd771915846',
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
          ...collections.map(
            (collection) => DropdownMenuItem<String>(
              value: collection.id,
              child: Text(
                '${collection.title(i18n)} · ${collection.optionIds.length}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}

class _ActivityLibraryStatusPanel extends StatelessWidget {
  const _ActivityLibraryStatusPanel({
    required this.i18n,
    required this.accent,
    required this.status,
    required this.busy,
    required this.installing,
    required this.loading,
    required this.expanded,
    required this.onInstallLibrary,
    required this.onToggleExpanded,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoiceActivityLibraryStatus status;
  final bool busy;
  final bool installing;
  final bool loading;
  final bool expanded;
  final Future<void> Function() onInstallLibrary;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLibrary = status.hasInstalledLibrary;
    final summary = hasLibrary
        ? i18n.t(
            'inline.plan295.daily_choice.status_actioncount_actions_installed.c084e467eb6d',
            params: <String, Object?>{'statusActionCount': status.actionCount},
          )
        : i18n.t(
            'inline.plan295.daily_choice.the_built_in_action_library_is_not_i.3f5ad1b8bbae',
          );
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(16),
      radius: ToolboxUiTokens.sectionPanelRadius,
      borderColor: accent.withValues(alpha: 0.18),
      shadowOpacity: 0.04,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                hasLibrary
                    ? Icons.download_done_rounded
                    : Icons.cloud_download_rounded,
                color: accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  i18n.t(
                    'inline.plan295.daily_choice.action_library.b4c8dd87e57e',
                  ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ToolboxInfoPill(
                text: busy
                    ? i18n.t('inline.plan295.daily_choice.busy.6345fdb4e3c5')
                    : (hasLibrary
                          ? i18n.t(
                              'inline.ui.pages.toolbox_daily_choice.daily_choice_modules.installed_6cb9dc',
                            )
                          : i18n.t(
                              'inline.plan295.daily_choice.missing.d6912d025db4',
                            )),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          if (status.errorMessage != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              i18n.t(
                'inline.ui.pages.toolbox_daily_choice.daily_choice_modules.last_sync_failed_status_errormessage_9b18da',
                params: <String, Object?>{
                  'statusErrorMessage': status.errorMessage,
                },
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.icon(
                onPressed: busy ? null : () => unawaited(onInstallLibrary()),
                icon: installing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_download_rounded),
                label: Text(
                  hasLibrary
                      ? i18n.t(
                          'inline.plan295.daily_choice.refresh_library.f433214488f9',
                        )
                      : i18n.t(
                          'inline.plan295.daily_choice.install_library.d88a56daf26d',
                        ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onToggleExpanded,
                icon: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
                label: Text(
                  expanded
                      ? i18n.t('inline.plan295.daily_choice.less.137e0473fd42')
                      : i18n.t(
                          'inline.plan295.daily_choice.details.05f67dd50434',
                        ),
                ),
              ),
            ],
          ),
          if (loading && !installing) ...<Widget>[
            const SizedBox(height: 10),
            LinearProgressIndicator(color: accent),
          ],
          if (expanded) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              i18n.t(
                'inline.plan295.daily_choice.the_remote_json_is_downloaded_and_in.dac96638cdec',
              ),
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

class _PlaceLibraryStatusPanel extends StatelessWidget {
  const _PlaceLibraryStatusPanel({
    required this.i18n,
    required this.accent,
    required this.libraryStatus,
    required this.busy,
    required this.libraryInstalling,
    required this.libraryLoading,
    required this.hasInstalledLibrary,
    required this.expanded,
    required this.onInstallLibrary,
    required this.onToggleExpanded,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoicePlaceLibraryStatus libraryStatus;
  final bool busy;
  final bool libraryInstalling;
  final bool libraryLoading;
  final bool hasInstalledLibrary;
  final bool expanded;
  final Future<void> Function() onInstallLibrary;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(16),
      radius: ToolboxUiTokens.sectionPanelRadius,
      borderColor: accent.withValues(alpha: 0.18),
      shadowColor: accent,
      shadowOpacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: onToggleExpanded,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: <Widget>[
                Icon(
                  hasInstalledLibrary
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_download_rounded,
                  size: 18,
                  color: accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasInstalledLibrary
                        ? i18n.t(
                            'inline.plan295.daily_choice.place_library_ready_librarystatus_pl.765c1a239cbf',
                            params: <String, Object?>{
                              'libraryStatusPlaceCount':
                                  libraryStatus.placeCount,
                              'libraryStatus.placeCount':
                                  libraryStatus.placeCount,
                            },
                          )
                        : i18n.t(
                            'inline.plan295.daily_choice.place_library_not_downloaded.74e85c249713',
                          ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
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
                      ? 'inline.plan295.daily_choice.loading_place_library.5e033de9127f'
                      : libraryLoading
                      ? 'toolbox.daily_choice.place.library.reading'
                      : 'toolbox.daily_choice.place.library.download',
                ),
              ),
            ),
          ],
          if (expanded) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              hasInstalledLibrary
                  ? i18n.t(
                      'inline.plan295.daily_choice.the_built_in_place_library_is_ready.70ec927fd18e',
                    )
                  : i18n.t(
                      'inline.plan295.daily_choice.download_the_built_in_place_library.65065fa43c46',
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
                'inline.plan295.daily_choice.the_latest_sync_reported_an_error_th.05179246d34b',
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

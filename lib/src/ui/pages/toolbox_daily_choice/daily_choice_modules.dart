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
  });

  final AppI18n i18n;
  final Color accent;
  final List<DailyChoiceOption> options;
  final List<DailyChoiceOption> builtInOptions;
  final DailyChoiceCustomState customState;
  final ValueChanged<DailyChoiceCustomState> onStateChanged;

  @override
  State<_PlaceChoiceModule> createState() => _PlaceChoiceModuleState();
}

class _PlaceChoiceModuleState extends State<_PlaceChoiceModule> {
  String _placeId = 'outside';
  String _sceneId = allPlaceSceneCategory.id;

  @override
  Widget build(BuildContext context) {
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
        ? pickUiText(
            widget.i18n,
            zh: '${category.subtitleZh}，再从整组地点里随机一个方向。',
            en: '${category.subtitleEn}, then randomize across the whole set.',
          )
        : pickUiText(
            widget.i18n,
            zh: '${scene.subtitleZh}；当前 $filtered.length 个候选。',
            en: '${scene.subtitleEn}. $filtered.length candidates right now.',
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DailyChoiceCategorySelector(
          i18n: widget.i18n,
          title: pickUiText(widget.i18n, zh: '选择距离', en: 'Distance'),
          categories: placeCategories,
          selectedId: _placeId,
          accent: widget.accent,
          compactUnselected: true,
          onSelected: (value) => setState(() => _placeId = value),
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        DailyChoiceCategorySelector(
          i18n: widget.i18n,
          title: pickUiText(widget.i18n, zh: '选择场景', en: 'Scene'),
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
        DailyChoiceRandomPanel(
          i18n: widget.i18n,
          accent: widget.accent,
          title: pickUiText(
            widget.i18n,
            zh: _sceneId == allPlaceSceneCategory.id
                ? '${category.titleZh}去哪里'
                : '${category.titleZh} · ${scene.titleZh}',
            en: _sceneId == allPlaceSceneCategory.id
                ? 'Where to go'
                : '${category.titleEn} · ${scene.titleEn}',
          ),
          subtitle: subtitle,
          options: filtered,
          emptyText: pickUiText(
            widget.i18n,
            zh: _sceneId == allPlaceSceneCategory.id
                ? '这个距离下暂时没有可用地点，可以在管理里恢复隐藏条目或新增你常去的地点。'
                : '这个距离和场景组合下暂时没有地点，可换一个场景，或在管理里补充你自己的常去点。',
            en: _sceneId == allPlaceSceneCategory.id
                ? 'No destinations are available in this distance tier right now. Restore hidden items or add your own frequent places.'
                : 'No destinations match this distance and scene yet. Try another scene or add your own place in Manage.',
          ),
          onDetail: (option) => showDailyChoiceDetailSheet(
            context: context,
            i18n: widget.i18n,
            accent: widget.accent,
            option: option,
          ),
          onGuide: () => showDailyChoiceGuideSheet(
            context: context,
            i18n: widget.i18n,
            accent: widget.accent,
            title: pickUiText(widget.i18n, zh: '出行指南', en: 'Going out guide'),
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
            contextLabelZh: '场景',
            contextLabelEn: 'Scene',
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
        ? pickUiText(
            i18n,
            zh: '当前按“${selectedDistance.titleZh}”收口，共有 $distanceCount 个地点，覆盖 $sceneCoverageCount 个场景。先定距离再随机，比较适合只想立刻出门、不想再做第二层判断的时候。',
            en: 'The current ${selectedDistance.titleEn} tier contains $distanceCount places across $sceneCoverageCount scenes. Distance-first randomizing works well when you just want to get moving.',
          )
        : candidateCount == 0
        ? pickUiText(
            i18n,
            zh: '当前按“${selectedDistance.titleZh} × ${selectedScene.titleZh}”筛选还没有候选，可切换场景，或在管理里补充你的私藏地点。',
            en: 'There are no candidates for ${selectedDistance.titleEn} × ${selectedScene.titleEn} yet. Switch the scene or add your own place in Manage.',
          )
        : pickUiText(
            i18n,
            zh: '当前按“${selectedDistance.titleZh} × ${selectedScene.titleZh}”筛到 $candidateCount 个候选。详情页会给出地图搜索词，数据结构也为粗略定位和开放地理数据扩展留好了口子。',
            en: 'The current ${selectedDistance.titleEn} × ${selectedScene.titleEn} filter gives $candidateCount candidates. Details include a map query, and the data model already leaves room for coarse location and open geo data later.',
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
                text: pickUiText(
                  i18n,
                  zh: '当前距离 ${selectedDistance.titleZh}',
                  en: 'Distance ${selectedDistance.titleEn}',
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: pickUiText(
                  i18n,
                  zh: usingAllScenes
                      ? '场景 全部'
                      : '当前场景 ${selectedScene.titleZh}',
                  en: usingAllScenes
                      ? 'Scene All'
                      : 'Scene ${selectedScene.titleEn}',
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: pickUiText(
                  i18n,
                  zh: '$distanceCount 个距离内地点',
                  en: '$distanceCount in this tier',
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: pickUiText(
                  i18n,
                  zh: '$candidateCount 个当前候选',
                  en: '$candidateCount candidates',
                ),
                accent: accent,
                backgroundColor: candidateCount == 0
                    ? theme.colorScheme.errorContainer
                    : theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: pickUiText(
                  i18n,
                  zh: '$sceneCoverageCount 个覆盖场景',
                  en: '$sceneCoverageCount covered scenes',
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
  });

  final AppI18n i18n;
  final Color accent;
  final List<DailyChoiceOption> options;
  final List<DailyChoiceOption> builtInOptions;
  final DailyChoiceCustomState customState;
  final ValueChanged<DailyChoiceCustomState> onStateChanged;

  @override
  State<_ActivityChoiceModule> createState() => _ActivityChoiceModuleState();
}

class _ActivityChoiceModuleState extends State<_ActivityChoiceModule> {
  String _activityId = randomActivityCategory.id;

  @override
  Widget build(BuildContext context) {
    final categories = <DailyChoiceCategory>[
      randomActivityCategory,
      ...activityCategories,
    ];
    final filtered = _activityId == randomActivityCategory.id
        ? widget.options
        : widget.options
              .where((item) => item.categoryId == _activityId)
              .toList(growable: false);
    final category = categories.firstWhere((item) => item.id == _activityId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DailyChoiceCategorySelector(
          i18n: widget.i18n,
          title: pickUiText(widget.i18n, zh: '选择方向', en: 'Direction'),
          categories: categories,
          selectedId: _activityId,
          accent: widget.accent,
          compactUnselected: true,
          onSelected: (value) => setState(() => _activityId = value),
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        DailyChoiceRandomPanel(
          i18n: widget.i18n,
          accent: widget.accent,
          title: pickUiText(
            widget.i18n,
            zh: _activityId == randomActivityCategory.id
                ? '今天干什么'
                : '${category.titleZh}做什么',
            en: _activityId == randomActivityCategory.id
                ? 'What to do today'
                : 'What to do',
          ),
          subtitle: category.subtitle(widget.i18n),
          options: filtered,
          emptyText: pickUiText(
            widget.i18n,
            zh: '这个方向还没有行动条目。可以新增自己的低阻力动作。',
            en: 'No actions here yet. Add your own low-friction action.',
          ),
          onDetail: (option) => showDailyChoiceDetailSheet(
            context: context,
            i18n: widget.i18n,
            accent: widget.accent,
            option: option,
          ),
          onGuide: () => showDailyChoiceGuideSheet(
            context: context,
            i18n: widget.i18n,
            accent: widget.accent,
            title: pickUiText(widget.i18n, zh: '行动指南', en: 'Action guide'),
            entries: activityGuideEntries,
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
          ),
        ),
      ],
    );
  }
}

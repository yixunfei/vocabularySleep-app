part of 'daily_choice_widgets.dart';

Future<void> showDailyChoiceGuideSheet({
  required BuildContext context,
  required AppI18n i18n,
  required Color accent,
  required String title,
  List<DailyChoiceGuideEntry> entries = const <DailyChoiceGuideEntry>[],
  List<DailyChoiceGuideModule> modules = const <DailyChoiceGuideModule>[],
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      final guideModules = modules.isNotEmpty
          ? modules
          : <DailyChoiceGuideModule>[
              DailyChoiceGuideModule(
                id: 'default',
                titleZh: title,
                titleEn: title,
                subtitleZh: '按顺序看就能快速上手',
                subtitleEn: 'A quick practical guide',
                entries: entries,
              ),
            ];
      var selectedModuleId = guideModules.first.id;
      return SafeArea(
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            final selectedModule = guideModules.firstWhere(
              (item) => item.id == selectedModuleId,
              orElse: () => guideModules.first,
            );
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.78,
              minChildSize: 0.42,
              maxChildSize: 0.94,
              builder: (context, controller) {
                return ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pickUiText(
                        i18n,
                        zh: '先选一个模块看，再往下读对应说明，会比一口气塞满全部信息更好消化。',
                        en: 'Pick one guide module first and then read the matching notes below.',
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (guideModules.length > 1) ...<Widget>[
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: guideModules
                            .map(
                              (module) => _GuideModuleCard(
                                i18n: i18n,
                                accent: accent,
                                module: module,
                                selected: selectedModuleId == module.id,
                                onTap: () {
                                  setSheetState(() {
                                    selectedModuleId = module.id;
                                  });
                                },
                              ),
                            )
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      selectedModule.title(i18n),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectedModule.subtitle(i18n),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final entry in selectedModule.entries) ...<Widget>[
                      _GuideEntryCard(i18n: i18n, accent: accent, entry: entry),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            );
          },
        ),
      );
    },
  );
}

Future<void> showDailyChoiceDetailSheet({
  required BuildContext context,
  required AppI18n i18n,
  required Color accent,
  required DailyChoiceOption option,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      final materials = option.materials(i18n);
      final steps = option.steps(i18n);
      final notes = option.notes(i18n);
      final tags = option.tags(i18n);
      final eatTraitDetails =
          option.moduleId == DailyChoiceModuleId.eat.storageValue
          ? eatTraitLines(i18n, option)
          : const <String>[];
      final wearTraitDetails =
          option.moduleId == DailyChoiceModuleId.wear.storageValue
          ? wearTraitLines(i18n, option)
          : const <String>[];
      final notesTitle = option.moduleId == DailyChoiceModuleId.eat.storageValue
          ? pickUiText(i18n, zh: '关键提示', en: 'Kitchen notes')
          : pickUiText(i18n, zh: '关键提示', en: 'Notes');
      final goMapQuery = option.moduleId == DailyChoiceModuleId.go.storageValue
          ? _dailyChoiceGoMapQuery(option, i18n)
          : null;

      return SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          minChildSize: 0.42,
          maxChildSize: 0.94,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
              children: <Widget>[
                Text(
                  option.title(i18n),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  option.details(i18n),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
                if (tags.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags
                        .map(
                          (tag) => ToolboxInfoPill(
                            text: tag,
                            accent: accent,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerLow,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
                const SizedBox(height: 18),
                if (eatTraitDetails.isNotEmpty) ...<Widget>[
                  _DetailBlock(
                    title: pickUiText(i18n, zh: '菜品画像', en: 'Dish profile'),
                    children: eatTraitDetails,
                    accent: accent,
                  ),
                  if (materials.isNotEmpty) const SizedBox(height: 12),
                ],
                if (wearTraitDetails.isNotEmpty) ...<Widget>[
                  _DetailBlock(
                    title: pickUiText(i18n, zh: '风格画像', en: 'Outfit profile'),
                    children: wearTraitDetails,
                    accent: accent,
                  ),
                  if (materials.isNotEmpty) const SizedBox(height: 12),
                ],
                if (materials.isNotEmpty)
                  _DetailBlock(
                    title: pickUiText(i18n, zh: '材料 / 条件', en: 'Materials'),
                    children: materials,
                    accent: accent,
                  ),
                if (steps.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  _DetailBlock(
                    title: pickUiText(i18n, zh: '制作 / 执行方法', en: 'Steps'),
                    children: steps,
                    numbered: true,
                    accent: accent,
                  ),
                ],
                if (notes.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  _DetailBlock(
                    title: notesTitle,
                    children: notes,
                    accent: accent,
                  ),
                ],
                if (option.moduleId ==
                    DailyChoiceModuleId.go.storageValue) ...<Widget>[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: goMapQuery ?? option.title(i18n)),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              pickUiText(
                                i18n,
                                zh: '已复制地图搜索词',
                                en: 'Map search query copied',
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.content_copy_rounded),
                    label: Text(
                      pickUiText(i18n, zh: '复制地图搜索词', en: 'Copy map query'),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      );
    },
  );
}

String _dailyChoiceGoMapQuery(DailyChoiceOption option, AppI18n i18n) {
  for (final item in option.materials(i18n)) {
    if (item.startsWith('地图搜索词：')) {
      return item.substring('地图搜索词：'.length).trim();
    }
    if (item.startsWith('Map query: ')) {
      return item.substring('Map query: '.length).trim();
    }
  }
  return option.title(i18n);
}

class _GuideModuleCard extends StatelessWidget {
  const _GuideModuleCard({
    required this.i18n,
    required this.accent,
    required this.module,
    required this.selected,
    required this.onTap,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoiceGuideModule module;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 148,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: 0.12)
                  : theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: accent.withValues(alpha: selected ? 0.42 : 0.14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(module.icon, color: accent),
                const SizedBox(height: 10),
                Text(
                  module.title(i18n),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  module.subtitle(i18n),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideEntryCard extends StatelessWidget {
  const _GuideEntryCard({
    required this.i18n,
    required this.accent,
    required this.entry,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoiceGuideEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: accent.withValues(alpha: 0.18),
      shadowOpacity: 0.04,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(entry.icon, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  entry.title(i18n),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  entry.body(i18n),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.title,
    required this.children,
    required this.accent,
    this.numbered = false,
  });

  final String title;
  final List<String> children;
  final Color accent;
  final bool numbered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: accent.withValues(alpha: 0.18),
      shadowOpacity: 0.04,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < children.length; index += 1)
            Padding(
              padding: EdgeInsets.only(
                bottom: index == children.length - 1 ? 0 : 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    numbered ? '${index + 1}. ' : '• ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      children[index],
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.42),
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

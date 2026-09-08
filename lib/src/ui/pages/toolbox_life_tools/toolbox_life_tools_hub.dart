part of '../toolbox_life_tools.dart';

class LifeToolsHubPage extends StatefulWidget {
  const LifeToolsHubPage({
    super.key,
    this.advancedCalculatorEngineFactory,
    this.advancedCalculatorSessionStoreFactory,
  });

  final ToolboxCalculatorEngine Function()? advancedCalculatorEngineFactory;
  final ToolboxCalculatorSessionStore Function()?
  advancedCalculatorSessionStoreFactory;

  @override
  State<LifeToolsHubPage> createState() => _LifeToolsHubPageState();
}

class _LifeToolsHubPageState extends State<LifeToolsHubPage> {
  String _query = '';
  final Set<String> _expandedCategories = <String>{};
  final List<String> _quickAccessIds = <String>[];
  _LifeTool? _activeTool;

  static const _categoryOrder = <String>[
    'display',
    'system',
    'measure',
    'image',
    'web',
    'text',
    'study',
    'calc',
  ];

  static const _categoryMeta = <String, _CategoryMeta>{
    'display': _CategoryMeta(
      color: Color(0xFF3D7EC5),
      icon: Icons.tv_rounded,
      labelKey: 'toolbox.life.hub.category.display.label',
      descKey: 'toolbox.life.hub.category.display.desc',
    ),
    'system': _CategoryMeta(
      color: Color(0xFFD4784A),
      icon: Icons.settings_suggest_rounded,
      labelKey: 'toolbox.life.hub.category.system.label',
      descKey: 'toolbox.life.hub.category.system.desc',
    ),
    'measure': _CategoryMeta(
      color: Color(0xFF537D6B),
      icon: Icons.explore_rounded,
      labelKey: 'toolbox.life.hub.category.measure.label',
      descKey: 'toolbox.life.hub.category.measure.desc',
    ),
    'image': _CategoryMeta(
      color: Color(0xFF7B6EC5),
      icon: Icons.image_rounded,
      labelKey: 'toolbox.life.hub.category.image.label',
      descKey: 'toolbox.life.hub.category.image.desc',
    ),
    'web': _CategoryMeta(
      color: Color(0xFF0C9E98),
      icon: Icons.language_rounded,
      labelKey: 'toolbox.life.hub.category.web.label',
      descKey: 'toolbox.life.hub.category.web.desc',
    ),
    'text': _CategoryMeta(
      color: Color(0xFF6B5D93),
      icon: Icons.text_fields_rounded,
      labelKey: 'toolbox.life.hub.category.text.label',
      descKey: 'toolbox.life.hub.category.text.desc',
    ),
    'study': _CategoryMeta(
      color: Color(0xFF4B8C66),
      icon: Icons.school_rounded,
      labelKey: 'toolbox.life.hub.category.study.label',
      descKey: 'toolbox.life.hub.category.study.desc',
    ),
    'calc': _CategoryMeta(
      color: Color(0xFFCD4B5E),
      icon: Icons.calculate_rounded,
      labelKey: 'toolbox.life.hub.category.calc.label',
      descKey: 'toolbox.life.hub.category.calc.desc',
    ),
  };

  String _localizedToolSearchText(_LifeTool tool) {
    return <String>[
      tool.id,
      _lifeI18nText(context, tool.titleKey),
      _lifeI18nText(context, tool.summaryKey),
    ].join(' ').toLowerCase();
  }

  List<_LifeTool> get _filteredTools {
    return _lifeTools
        .where((tool) {
          if (_query.trim().isEmpty) return true;
          final q = _query.toLowerCase();
          return _localizedToolSearchText(tool).contains(q);
        })
        .toList(growable: false);
  }

  Map<String, List<_LifeTool>> _groupedTools() {
    final map = <String, List<_LifeTool>>{};
    for (final tool in _filteredTools) {
      map.putIfAbsent(tool.category, () => []).add(tool);
    }
    return map;
  }

  bool get _allExpanded {
    final grouped = _groupedTools();
    return grouped.keys.every((c) => _expandedCategories.contains(c));
  }

  List<_LifeTool> get _quickAccessTools {
    final byId = <String, _LifeTool>{
      for (final tool in _lifeTools) tool.id: tool,
    };
    return _quickAccessIds
        .map((id) => byId[id])
        .whereType<_LifeTool>()
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
  }

  void _toggleAll() {
    setState(() {
      if (_allExpanded) {
        _expandedCategories.clear();
      } else {
        _expandedCategories.addAll(_groupedTools().keys);
      }
    });
  }

  void _addToQuickAccess(String toolId) {
    if (_quickAccessIds.contains(toolId)) return;
    setState(() => _quickAccessIds.add(toolId));
  }

  void _removeFromQuickAccess(String toolId) {
    setState(() => _quickAccessIds.remove(toolId));
  }

  void _showAddQuickAccessSheet() {
    final available = _lifeTools
        .where((t) => !_quickAccessIds.contains(t.id))
        .toList(growable: false);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Column(
              children: <Widget>[
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      sheetContext,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _lifeI18nText(
                      sheetContext,
                      'inline.plan294.life_hub.add_quick_tool_881c5f49',
                    ),
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: available.isEmpty
                      ? Center(
                          child: Text(
                            _lifeI18nText(
                              sheetContext,
                              'inline.plan294.life_hub.all_tools_added_f2375380',
                            ),
                            style: Theme.of(sheetContext).textTheme.bodyLarge,
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: available.length,
                          itemBuilder: (_, index) {
                            final tool = available[index];
                            final meta = _categoryMeta[tool.category]!;
                            return ListTile(
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: meta.color.withValues(alpha: 0.12),
                                ),
                                child: Icon(
                                  tool.icon,
                                  color: meta.color,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                _lifeI18nText(sheetContext, tool.titleKey),
                              ),
                              subtitle: Text(
                                _lifeI18nText(sheetContext, tool.summaryKey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                _addToQuickAccess(tool.id);
                                Navigator.pop(sheetContext);
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildQuickAccessBar(BuildContext context) {
    final quickTools = _quickAccessTools;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              _lifeI18nText(
                context,
                'inline.plan294.life_hub.quick_access_8882fa92',
              ),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            if (quickTools.isNotEmpty)
              Text(
                _lifeI18nText(
                  context,
                  'inline.plan294.life_hub.long_press_to_remove_c175edd4',
                ),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: quickTools.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _AddQuickAccessButton(onTap: _showAddQuickAccessSheet);
              }
              final tool = quickTools[index - 1];
              final meta = _categoryMeta[tool.category]!;
              return _QuickAccessChip(
                tool: tool,
                accent: meta.color,
                onTap: () => _openTool(tool),
                onLongPress: () => _confirmRemoveQuickAccess(tool),
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmRemoveQuickAccess(_LifeTool tool) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _lifeI18nText(
              dialogContext,
              'inline.plan294.life_hub.remove_quick_access_62d3bd88',
            ),
          ),
          content: Text(
            _lifeI18nText(
              dialogContext,
              'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.hub.remove_from_quick_access.c39e2e9b07',
              params: <String, Object?>{
                'title': _lifeI18nText(dialogContext, tool.titleKey),
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(_lifeI18nText(dialogContext, 'cancel')),
            ),
            TextButton(
              onPressed: () {
                _removeFromQuickAccess(tool.id);
                Navigator.pop(dialogContext);
              },
              child: Text(
                _lifeI18nText(
                  dialogContext,
                  'inline.ui.pages.practice_notebook_page.remove_2837f7',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTool = _activeTool;
    if (activeTool != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            return;
          }
          const BackIntentConsumedNotification().dispatch(context);
          _closeTool();
        },
        child: ToolboxEmbeddedNavigation(
          onBack: _closeTool,
          child: KeyedSubtree(
            key: ValueKey<String>('life_tool_${activeTool.id}'),
            child: _buildToolPage(activeTool),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final grouped = _groupedTools();
    final isSearching = _query.trim().isNotEmpty;

    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan294.life_hub.life_tools_292cc56d',
      ),
      subtitle: _lifeI18nText(
        context,
        'toolbox.life.hub.subtitle',
        params: <String, Object?>{
          'length': _lifeTools.length,
          'categories': _categoryMeta.length,
        },
      ),
      appBarActions: <Widget>[
        IconButton(
          tooltip: _lifeI18nText(
            context,
            'toolbox.life.source_references.title',
          ),
          onPressed: () => _showLifeSourceReferencesSheet(context),
          icon: const Icon(Icons.help_outline_rounded),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: _lifeI18nText(
              context,
              'inline.plan294.life_hub.overview_451aa8b2',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan294.life_hub.search_by_keyword_or_expand_category_drawers_to__0a37b578',
            ),
            trailing: grouped.isNotEmpty && !isSearching
                ? TextButton.icon(
                    onPressed: _toggleAll,
                    icon: Icon(
                      _allExpanded
                          ? Icons.unfold_less_rounded
                          : Icons.unfold_more_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _allExpanded
                          ? _lifeI18nText(
                              context,
                              'inline.plan294.life_hub.collapse_all_ad827378',
                            )
                          : _lifeI18nText(
                              context,
                              'inline.plan294.life_hub.expand_all_a71926cb',
                            ),
                      style: theme.textTheme.labelMedium,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey<String>('life_tools_search_field'),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              border: const OutlineInputBorder(),
              labelText: _lifeI18nText(
                context,
                'inline.plan294.life_hub.search_tools_fe1669f3',
              ),
              suffixIcon: isSearching
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => setState(() => _query = ''),
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 14),
          if (!isSearching) _buildQuickAccessBar(context),
          const SizedBox(height: 14),
          if (_filteredTools.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  children: <Widget>[
                    Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _lifeI18nText(
                        context,
                        'inline.plan294.life_hub.no_matching_tools_cd217d95',
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._categoryOrder.where((c) => grouped.containsKey(c)).map((
              category,
            ) {
              final tools = grouped[category]!;
              final meta = _categoryMeta[category]!;
              final expanded = _expandedCategories.contains(category);
              return _CategoryDrawer(
                category: category,
                tools: tools,
                meta: meta,
                isExpanded: expanded,
                forceExpand: isSearching,
                onToggle: () => setState(() {
                  if (expanded) {
                    _expandedCategories.remove(category);
                  } else {
                    _expandedCategories.add(category);
                  }
                }),
                onToolTap: _openTool,
              );
            }),
        ],
      ),
    );
  }

  void _openTool(_LifeTool tool) {
    setState(() {
      _activeTool = tool;
    });
  }

  void _closeTool() {
    setState(() {
      _activeTool = null;
    });
  }

  Widget _buildToolPage(_LifeTool tool) {
    return switch (tool.id) {
      'time_screen' => const _TimeScreenToolPage(),
      'barrage' => const _BarrageToolPage(),
      'screen_fill_light' => const _ScreenFillLightToolPage(),
      'ruler' => const _RulerToolPage(),
      'scoreboard' => const _ScoreboardToolPage(),
      'color_helper' => const _ColorHelperToolPage(),
      'wallpaper_helper' => const _WallpaperHelperToolPage(),
      'postal_code' => const _PostalLookupToolPage(),
      'reverse_image' => const _ReverseImageToolPage(),
      'garbage' => const _GarbageSortingToolPage(),
      'relatives' => const _RelativesToolPage(),
      'mind_map' => const _MindMapToolPage(),
      'timeline_periodic' => const _TimelinePeriodicToolPage(),
      'compass' => const _CompassToolPage(),
      'level' => const _LevelToolPage(),
      'vibration' => const _VibrationToolPage(),
      'speedometer' => const _SpeedometerToolPage(),
      'magnifier' => const _MagnifierToolPage(),
      'light_meter' => const _LightMeterToolPage(),
      'phone_monitor' => const _PhoneMonitorToolPage(),
      'distance_meter' => const _DistanceMeterToolPage(),
      'device_frame' => const _DeviceFrameToolPage(),
      'gif_maker' => const _GifMakerToolPage(),
      'archive_tool' => const _ArchiveToolPage(),
      'notify_me' => const _NotifyMeToolPage(),
      'fake_call' => const _FakeCallToolPage(),
      'id_photo' => const _IdPhotoToolPage(),
      'sup_sub' => const _NumberMarksPage(),
      'meme_maker' => const _MemeMakerToolPage(),
      'advanced_calculator' => _AdvancedCalculatorToolPage(
        engineFactory: widget.advancedCalculatorEngineFactory,
        sessionStoreFactory: widget.advancedCalculatorSessionStoreFactory,
      ),
      'bio_clock' => const _BioClockToolPage(),
      'text_count' ||
      'text_encoding' ||
      'unit_converter' ||
      'work_worth' ||
      'city_compare' ||
      'offer_select' ||
      'mortgage' ||
      'date_calculator' ||
      'world_clock' ||
      'bmi' ||
      'short_link' ||
      'qr' ||
      'image_transform' ||
      'image_to_web' => _LifeUtilityToolPage(tool: tool),
      _ => _LifeToolInfoPage(tool: tool),
    };
  }
}

class _CategoryMeta {
  const _CategoryMeta({
    required this.color,
    required this.icon,
    required this.labelKey,
    required this.descKey,
  });

  final Color color;
  final IconData icon;
  final String labelKey;
  final String descKey;
}

class _AddQuickAccessButton extends StatelessWidget {
  const _AddQuickAccessButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 1.5,
            ),
            color: colorScheme.surfaceContainerLow.withValues(alpha: 0.4),
          ),
          child: Icon(
            Icons.add_rounded,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _QuickAccessChip extends StatelessWidget {
  const _QuickAccessChip({
    required this.tool,
    required this.accent,
    required this.onTap,
    required this.onLongPress,
  });

  final _LifeTool tool;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: accent.withValues(alpha: 0.08),
            border: Border.all(color: accent.withValues(alpha: 0.20)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(tool.icon, color: accent, size: 20),
              const SizedBox(width: 6),
              Text(
                _lifeI18nText(context, tool.titleKey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryDrawer extends StatefulWidget {
  const _CategoryDrawer({
    required this.category,
    required this.tools,
    required this.meta,
    required this.isExpanded,
    required this.forceExpand,
    required this.onToggle,
    required this.onToolTap,
  });

  final String category;
  final List<_LifeTool> tools;
  final _CategoryMeta meta;
  final bool isExpanded;
  final bool forceExpand;
  final VoidCallback onToggle;
  final ValueChanged<_LifeTool> onToolTap;

  @override
  State<_CategoryDrawer> createState() => _CategoryDrawerState();
}

class _CategoryDrawerState extends State<_CategoryDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _accentController;
  late final Animation<double> _accentWidth;

  @override
  void initState() {
    super.initState();
    _accentController = AnimationController(
      duration: AppDurations.expand,
      vsync: this,
      value: widget.isExpanded || widget.forceExpand ? 1 : 0,
    );
    _accentWidth = Tween<double>(begin: 0, end: 4).animate(
      CurvedAnimation(parent: _accentController, curve: AppEasing.standard),
    );
  }

  @override
  void didUpdateWidget(covariant _CategoryDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = widget.isExpanded || widget.forceExpand;
    if (target) {
      _accentController.forward();
    } else {
      _accentController.reverse();
    }
  }

  @override
  void dispose() {
    _accentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final meta = widget.meta;
    final effectiveExpanded = widget.forceExpand || widget.isExpanded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AnimatedBuilder(
        animation: _accentController,
        builder: (context, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: widget.forceExpand ? null : widget.onToggle,
                  child: AnimatedContainer(
                    duration: AppDurations.standard,
                    curve: AppEasing.standard,
                    padding: const EdgeInsets.all(0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: effectiveExpanded
                          ? meta.color.withValues(alpha: 0.06)
                          : colorScheme.surfaceContainerLow.withValues(
                              alpha: 0.4,
                            ),
                      border: Border.all(
                        color: effectiveExpanded
                            ? meta.color.withValues(alpha: 0.28)
                            : colorScheme.outlineVariant.withValues(
                                alpha: 0.10,
                              ),
                      ),
                      boxShadow: effectiveExpanded
                          ? <BoxShadow>[
                              BoxShadow(
                                color: meta.color.withValues(alpha: 0.10),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Container(
                            width: _accentWidth.value,
                            decoration: BoxDecoration(
                              color: meta.color.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.horizontal(
                                left: const Radius.circular(14),
                                right: Radius.circular(
                                  _accentWidth.value > 2 ? 2 : 0,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                12,
                                14,
                                12,
                              ),
                              child: Row(
                                children: <Widget>[
                                  AnimatedContainer(
                                    duration: AppDurations.standard,
                                    curve: AppEasing.standard,
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(11),
                                      color: meta.color.withValues(
                                        alpha: effectiveExpanded ? 0.22 : 0.10,
                                      ),
                                    ),
                                    child: Icon(
                                      meta.icon,
                                      color: meta.color,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Flexible(
                                              child: Text(
                                                _lifeI18nText(
                                                  context,
                                                  meta.labelKey,
                                                ),
                                                style: theme
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            AnimatedContainer(
                                              duration: AppDurations.standard,
                                              curve: AppEasing.standard,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                color: effectiveExpanded
                                                    ? meta.color.withValues(
                                                        alpha: 0.16,
                                                      )
                                                    : colorScheme
                                                          .surfaceContainerHighest
                                                          .withValues(
                                                            alpha: 0.6,
                                                          ),
                                              ),
                                              child: Text(
                                                '${widget.tools.length}',
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: effectiveExpanded
                                                          ? meta.color
                                                          : colorScheme
                                                                .onSurfaceVariant,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          _lifeI18nText(context, meta.descKey),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!widget.forceExpand) ...[
                                    const SizedBox(width: 8),
                                    AnimatedScale(
                                      duration: AppDurations.standard,
                                      curve: AppEasing.standard,
                                      scale: effectiveExpanded ? 1 : 0.85,
                                      child: AnimatedRotation(
                                        duration: AppDurations.standard,
                                        curve: AppEasing.standard,
                                        turns: effectiveExpanded ? 0.5 : 0,
                                        child: AnimatedContainer(
                                          duration: AppDurations.standard,
                                          curve: AppEasing.standard,
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: effectiveExpanded
                                                ? meta.color.withValues(
                                                    alpha: 0.12,
                                                  )
                                                : colorScheme
                                                      .surfaceContainerHighest
                                                      .withValues(alpha: 0.5),
                                          ),
                                          child: Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 20,
                                            color: effectiveExpanded
                                                ? meta.color
                                                : colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedCrossFade(
                duration: AppDurations.expand,
                sizeCurve: AppEasing.standard,
                crossFadeState: effectiveExpanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Padding(
                  padding: const EdgeInsets.only(top: 8, left: 14, right: 4),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: meta.color.withValues(alpha: 0.035),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: meta.color.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isExpandedWidth = AppWidthBreakpoints.tierFor(
                            constraints.maxWidth,
                          ).isExpanded;
                          final columns = isExpandedWidth ? 2 : 1;
                          const spacing = 10.0;
                          final cardWidth =
                              (constraints.maxWidth - spacing * (columns - 1)) /
                              columns;
                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: widget.tools
                                .map((tool) {
                                  return SizedBox(
                                    width: cardWidth,
                                    child: _ToolDrawerCard(
                                      tool: tool,
                                      accent: meta.color,
                                      onTap: () => widget.onToolTap(tool),
                                    ),
                                  );
                                })
                                .toList(growable: false),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ToolDrawerCard extends StatefulWidget {
  const _ToolDrawerCard({
    required this.tool,
    required this.accent,
    required this.onTap,
  });

  final _LifeTool tool;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_ToolDrawerCard> createState() => _ToolDrawerCardState();
}

class _ToolDrawerCardState extends State<_ToolDrawerCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tool = widget.tool;
    final accent = widget.accent;

    return AnimatedScale(
      scale: _pressed ? 0.975 : 1,
      duration: AppDurations.quick,
      curve: AppEasing.snappy,
      child: Card(
        key: ValueKey<String>('life_tool_card_${tool.id}'),
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onHighlightChanged: (value) {
            if (_pressed == value) return;
            setState(() => _pressed = value);
          },
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppDurations.standard,
            curve: AppEasing.standard,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _pressed
                  ? accent.withValues(alpha: 0.08)
                  : colorScheme.surfaceContainerLow.withValues(alpha: 0.55),
              border: Border.all(
                color: _pressed
                    ? accent.withValues(alpha: 0.30)
                    : colorScheme.outlineVariant.withValues(alpha: 0.10),
              ),
              boxShadow: _pressed
                  ? <BoxShadow>[
                      BoxShadow(
                        color: accent.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: <Widget>[
                AnimatedContainer(
                  duration: AppDurations.standard,
                  curve: AppEasing.standard,
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: accent.withValues(alpha: _pressed ? 0.22 : 0.10),
                  ),
                  child: Icon(tool.icon, color: accent, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _lifeI18nText(context, tool.titleKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _lifeI18nText(context, tool.summaryKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  duration: AppDurations.quick,
                  curve: AppEasing.gentle,
                  opacity: _pressed ? 1 : 0.38,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: accent,
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

void _showLifeSourceReferencesSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final colorScheme = Theme.of(sheetContext).colorScheme;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.42,
        maxChildSize: 0.94,
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: DecoratedBox(
              decoration: BoxDecoration(color: colorScheme.surface),
              child: _LifeSourceReferencesSheet(
                scrollController: scrollController,
              ),
            ),
          );
        },
      );
    },
  );
}

class _LifeSourceReferencesSheet extends StatelessWidget {
  const _LifeSourceReferencesSheet({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Column(
        children: <Widget>[
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.secondaryContainer.withValues(
                      alpha: 0.72,
                    ),
                  ),
                  child: Icon(
                    Icons.help_outline_rounded,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _lifeI18nText(
                          context,
                          'toolbox.life.source_references.title',
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _lifeI18nText(
                          context,
                          'toolbox.life.source_references.subtitle',
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: const _LifeSourceReferencesContent(
                key: ValueKey<String>('life-source-references-page'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LifeSourceReferencesContent extends StatelessWidget {
  const _LifeSourceReferencesContent({super.key});

  List<_LifeTool> get _toolsWithSources {
    return _lifeTools
        .where((tool) => tool.sources.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final tools = _toolsWithSources;
    final sourceCount = tools.fold<int>(
      0,
      (sum, tool) => sum + tool.sources.length,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _LifeSettingsPanel(
          title: _lifeI18nText(
            context,
            'toolbox.life.source_references.overview',
          ),
          subtitle: _lifeI18nText(
            context,
            'toolbox.life.source_references.overview_subtitle',
          ),
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ToolboxMetricCard(
                  label: _lifeI18nText(
                    context,
                    'toolbox.life.source_references.metric_tools',
                  ),
                  value: '${tools.length}',
                ),
                ToolboxMetricCard(
                  label: _lifeI18nText(
                    context,
                    'toolbox.life.source_references.metric_links',
                  ),
                  value: '$sourceCount',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _LifeSourceBoundaryNote(
              text: _lifeI18nText(
                context,
                'toolbox.life.source_references.boundary_note',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SectionHeader(
          title: _lifeI18nText(
            context,
            'toolbox.life.source_references.grouped_title',
          ),
        ),
        const SizedBox(height: 8),
        for (final tool in tools) ...<Widget>[
          _LifeSourceGroup(tool: tool),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _LifeSourceBoundaryNote extends StatelessWidget {
  const _LifeSourceBoundaryNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.info_outline_rounded,
            color: theme.colorScheme.onSecondaryContainer,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LifeSourceGroup extends StatelessWidget {
  const _LifeSourceGroup({required this.tool});

  final _LifeTool tool;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final meta = _LifeToolsHubPageState._categoryMeta[tool.category]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: meta.color.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: meta.color.withValues(alpha: 0.12),
                ),
                child: Icon(tool.icon, color: meta.color, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _lifeI18nText(context, tool.titleKey),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _lifeI18nText(context, meta.labelKey),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: meta.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: meta.color.withValues(alpha: 0.10),
                ),
                child: Text(
                  '${tool.sources.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: meta.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < tool.sources.length; index += 1) ...[
            _LifeSourceLinkTile(
              key: ValueKey<String>('life_source_${tool.id}_$index'),
              source: tool.sources[index],
            ),
            if (index != tool.sources.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _LifeSourceLinkTile extends StatelessWidget {
  const _LifeSourceLinkTile({super.key, required this.source});

  final _LifeToolSource source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openExternal(context, source.url),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.65),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.link_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      source.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      source.url,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: _lifeI18nText(
                  context,
                  'toolbox.life.source_references.open_link',
                ),
                child: Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LifeToolInfoPage extends StatelessWidget {
  const _LifeToolInfoPage({required this.tool});

  final _LifeTool tool;

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(context, tool.titleKey),
      subtitle: _lifeI18nText(context, tool.summaryKey),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              _lifeI18nText(
                context,
                'inline.plan294.life_hub.this_tool_provides_public_resource_links_and_inf_ddb547a1',
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (tool.sources.isNotEmpty) ...<Widget>[
            Card(
              child: ListTile(
                leading: const Icon(Icons.travel_explore_rounded),
                title: Text(
                  _lifeI18nText(
                    context,
                    'toolbox.life.source_references.title',
                  ),
                ),
                subtitle: Text(
                  _lifeI18nText(
                    context,
                    'toolbox.life.source_references.summary',
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showLifeSourceReferencesSheet(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _openExternal(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _lifeI18nText(
            context,
            'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.hub.unable_to_open_link.fd0fc474f3',
            params: <String, Object?>{'url': url},
          ),
        ),
      ),
    );
  }
}

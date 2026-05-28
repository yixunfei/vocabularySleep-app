part of '../toolbox_life_tools.dart';

class LifeToolsHubPage extends StatefulWidget {
  const LifeToolsHubPage({super.key});

  @override
  State<LifeToolsHubPage> createState() => _LifeToolsHubPageState();
}

class _LifeToolsHubPageState extends State<LifeToolsHubPage> {
  String _query = '';
  final Set<String> _expandedCategories = <String>{};
  final List<String> _quickAccessIds = <String>[];

  static const _categoryOrder = <String>[
    'display',
    'device',
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
      labelZh: '屏幕展示',
      labelEn: 'Screen & Display',
      descZh: '时钟、弹幕、记分与全屏信息展示',
      descEn: 'Clock, barrage, scoreboard, and fullscreen displays',
    ),
    'device': _CategoryMeta(
      color: Color(0xFFD4784A),
      icon: Icons.smartphone_rounded,
      labelZh: '设备工坊',
      labelEn: 'Device Lab',
      descZh: '传感器、水平仪、震动与来电模拟',
      descEn: 'Sensors, level, vibration, and call simulation',
    ),
    'image': _CategoryMeta(
      color: Color(0xFF7B6EC5),
      icon: Icons.image_rounded,
      labelZh: '图像创作',
      labelEn: 'Image Studio',
      descZh: '取色、压缩、带壳截图与表情包制作',
      descEn: 'Color picker, compression, framing, and meme maker',
    ),
    'web': _CategoryMeta(
      color: Color(0xFF0C9E98),
      icon: Icons.language_rounded,
      labelZh: '网络百宝箱',
      labelEn: 'Web Toolkit',
      descZh: '壁纸、邮编、搜图、短链与二维码',
      descEn: 'Wallpaper, postal lookup, reverse search, short links, and QR',
    ),
    'text': _CategoryMeta(
      color: Color(0xFF6B5D93),
      icon: Icons.text_fields_rounded,
      labelZh: '文本编辑',
      labelEn: 'Text Editor',
      descZh: '字数统计、格式转换、思维导图与数字标号',
      descEn: 'Word count, format transform, mind map, and number marks',
    ),
    'study': _CategoryMeta(
      color: Color(0xFF4B8C66),
      icon: Icons.school_rounded,
      labelZh: '学习助手',
      labelEn: 'Study Aid',
      descZh: '历史年表、元素周期表与 AI 面试练习',
      descEn: 'Timeline, periodic table, and AI interview practice',
    ),
    'calc': _CategoryMeta(
      color: Color(0xFFCD4B5E),
      icon: Icons.calculate_rounded,
      labelZh: '生活计算',
      labelEn: 'Life Calculator',
      descZh: '单位换算、薪资对比、房贷、BMI 与日期推算',
      descEn: 'Unit converter, salary compare, mortgage, BMI, and date calc',
    ),
  };

  List<_LifeTool> get _filteredTools {
    return _lifeTools.where((tool) {
      if (_query.trim().isEmpty) return true;
      final q = _query.toLowerCase();
      return tool.titleZh.toLowerCase().contains(q) ||
          tool.titleEn.toLowerCase().contains(q) ||
          tool.summaryZh.toLowerCase().contains(q) ||
          tool.summaryEn.toLowerCase().contains(q);
    }).toList(growable: false);
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
    final byId = <String, _LifeTool>{
      for (final tool in _lifeTools) tool.id: tool,
    };
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
          builder: (_, scrollController) {
            return Column(
              children: <Widget>[
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(sheetContext)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _lifeText(
                      sheetContext,
                      zh: '添加快捷工具',
                      en: 'Add quick tool',
                    ),
                    style:
                        Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: available.isEmpty
                      ? Center(
                          child: Text(
                            _lifeText(
                              sheetContext,
                              zh: '所有工具已添加',
                              en: 'All tools added',
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
                                _lifeText(
                                  sheetContext,
                                  zh: tool.titleZh,
                                  en: tool.titleEn,
                                ),
                              ),
                              subtitle: Text(
                                _lifeText(
                                  sheetContext,
                                  zh: tool.summaryZh,
                                  en: tool.summaryEn,
                                ),
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
              _lifeText(context, zh: '快捷入口', en: 'Quick access'),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            if (quickTools.isNotEmpty)
              Text(
                _lifeText(
                  context,
                  zh: '长按图标可删除',
                  en: 'Long press to remove',
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
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _AddQuickAccessButton(
                  onTap: _showAddQuickAccessSheet,
                );
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
            _lifeText(
              dialogContext,
              zh: '移除快捷入口',
              en: 'Remove quick access',
            ),
          ),
          content: Text(
            _lifeText(
              dialogContext,
              zh: '确定要将「${tool.titleZh}」从快捷入口移除吗？',
              en: 'Remove "${tool.titleEn}" from quick access?',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                _lifeText(dialogContext, zh: '取消', en: 'Cancel'),
              ),
            ),
            TextButton(
              onPressed: () {
                _removeFromQuickAccess(tool.id);
                Navigator.pop(dialogContext);
              },
              child: Text(
                _lifeText(dialogContext, zh: '移除', en: 'Remove'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = _groupedTools();
    final isSearching = _query.trim().isNotEmpty;

    return ToolboxToolPage(
      title: _lifeText(context, zh: '生活实用', en: 'Life tools'),
      subtitle: _lifeText(
        context,
        zh: '${_lifeTools.length} 个独立功能入口，一期优先落地可本地实现能力，并补全公开资源来源说明。',
        en: '${_lifeTools.length} standalone entries with local-first phase-1 implementations and source attributions.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: _lifeText(context, zh: '功能总览', en: 'Overview'),
            subtitle: _lifeText(
              context,
              zh: '可按关键词搜索，或展开分类抽屉浏览全部工具。',
              en: 'Search by keyword or expand category drawers to browse all tools.',
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
                          ? _lifeText(context, zh: '全部收起', en: 'Collapse all')
                          : _lifeText(context, zh: '全部展开', en: 'Expand all'),
                      style: theme.textTheme.labelMedium,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              border: const OutlineInputBorder(),
              labelText: _lifeText(context, zh: '搜索工具', en: 'Search tools'),
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
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _lifeText(
                        context,
                        zh: '未找到匹配的工具',
                        en: 'No matching tools',
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
            ..._categoryOrder
                .where((c) => grouped.containsKey(c))
                .map((category) {
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => switch (tool.id) {
          'time_screen' => const _TimeScreenToolPage(),
          'barrage' => const _BarrageToolPage(),
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
          'device_frame' => const _DeviceFrameToolPage(),
          'notify_me' => const _NotifyMeToolPage(),
          'fake_call' => const _FakeCallToolPage(),
          'id_photo' => const _IdPhotoToolPage(),
          'ai_interview' => const _AiInterviewToolPage(),
          'sup_sub' => const _NumberMarksPage(),
          'meme_maker' => const _MemeMakerToolPage(),
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
          'image_to_web' =>
            _LifeUtilityToolPage(tool: tool),
          _ => _LifeToolInfoPage(tool: tool),
        },
      ),
    );
  }
}

class _CategoryMeta {
  const _CategoryMeta({
    required this.color,
    required this.icon,
    required this.labelZh,
    required this.labelEn,
    required this.descZh,
    required this.descEn,
  });

  final Color color;
  final IconData icon;
  final String labelZh;
  final String labelEn;
  final String descZh;
  final String descEn;
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
            border: Border.all(
              color: accent.withValues(alpha: 0.20),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(tool.icon, color: accent, size: 20),
              const SizedBox(width: 6),
              Text(
                _lifeText(context, zh: tool.titleZh, en: tool.titleEn),
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
                          : colorScheme.surfaceContainerLow
                              .withValues(alpha: 0.4),
                      border: Border.all(
                        color: effectiveExpanded
                            ? meta.color.withValues(alpha: 0.28)
                            : colorScheme.outlineVariant
                                .withValues(alpha: 0.10),
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
                                      borderRadius:
                                          BorderRadius.circular(11),
                                      color: meta.color.withValues(
                                        alpha:
                                            effectiveExpanded ? 0.22 : 0.10,
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
                                                _lifeText(
                                                  context,
                                                  zh: meta.labelZh,
                                                  en: meta.labelEn,
                                                ),
                                                style: theme
                                                    .textTheme.titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            AnimatedContainer(
                                              duration:
                                                  AppDurations.standard,
                                              curve: AppEasing.standard,
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  999,
                                                ),
                                                color: effectiveExpanded
                                                    ? meta.color
                                                        .withValues(
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
                                                    .textTheme.labelSmall
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
                                          _lifeText(
                                            context,
                                            zh: meta.descZh,
                                            en: meta.descEn,
                                          ),
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
                                        turns:
                                            effectiveExpanded ? 0.5 : 0,
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
                                                    .withValues(
                                                      alpha: 0.5,
                                                    ),
                                          ),
                                          child: Icon(
                                            Icons
                                                .keyboard_arrow_down_rounded,
                                            size: 20,
                                            color: effectiveExpanded
                                                ? meta.color
                                                : colorScheme
                                                    .onSurfaceVariant,
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
                  padding: const EdgeInsets.only(
                    top: 10,
                    left: 6,
                    right: 6,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isExpandedWidth =
                          AppWidthBreakpoints.tierFor(constraints.maxWidth)
                              .isExpanded;
                      final columns = isExpandedWidth ? 2 : 1;
                      const spacing = 10.0;
                      final cardWidth =
                          (constraints.maxWidth - spacing * (columns - 1)) /
                              columns;
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: widget.tools.map((tool) {
                          return SizedBox(
                            width: cardWidth,
                            child: _ToolDrawerCard(
                              tool: tool,
                              accent: meta.color,
                              onTap: () => widget.onToolTap(tool),
                            ),
                          );
                        }).toList(growable: false),
                      );
                    },
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
      child: Material(
        color: Colors.transparent,
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
                    color: accent.withValues(
                      alpha: _pressed ? 0.22 : 0.10,
                    ),
                  ),
                  child: Icon(
                    tool.icon,
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
                        _lifeText(
                          context,
                          zh: tool.titleZh,
                          en: tool.titleEn,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _lifeText(
                          context,
                          zh: tool.summaryZh,
                          en: tool.summaryEn,
                        ),
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

class _LifeToolInfoPage extends StatelessWidget {
  const _LifeToolInfoPage({required this.tool});

  final _LifeTool tool;

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeText(context, zh: tool.titleZh, en: tool.titleEn),
      subtitle: _lifeText(context, zh: tool.summaryZh, en: tool.summaryEn),
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
              _lifeText(
                context,
                zh: '一期版本已创建独立入口。该功能当前以稳定入口和资源桥接为主，后续会继续补充更完整的本地实现。',
                en: 'Phase-1 provides an independent entry. This tool currently focuses on stable access and resource bridging, and will be extended with deeper local implementation.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (tool.sources.isNotEmpty) ...<Widget>[
            SectionHeader(
              title: _lifeText(
                context,
                zh: '来源与版权说明',
                en: 'Sources and attribution',
              ),
            ),
            const SizedBox(height: 8),
            for (final source in tool.sources)
              Card(
                child: ListTile(
                  title: Text(source.name),
                  subtitle: Text(
                    source.copyrightNote.isEmpty
                        ? source.url
                        : '${source.url}\n${source.copyrightNote}',
                  ),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  onTap: () => _openExternal(context, source.url),
                ),
              ),
            const SizedBox(height: 6),
            Text(
              _lifeText(
                context,
                zh: '版权和使用权请以来源网站政策及原作者声明为准。',
                en: 'Copyright and usage rights follow each source website policy and original author statement.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
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
      SnackBar(content: Text('无法打开链接: $url')),
    );
  }
}

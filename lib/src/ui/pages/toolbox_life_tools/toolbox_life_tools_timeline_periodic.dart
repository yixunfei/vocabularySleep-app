part of '../toolbox_life_tools.dart';

class _TimelinePeriodicToolPage extends StatefulWidget {
  const _TimelinePeriodicToolPage();

  @override
  State<_TimelinePeriodicToolPage> createState() =>
      _TimelinePeriodicToolPageState();
}

class _TimelinePeriodicToolPageState extends State<_TimelinePeriodicToolPage> {
  final TransformationController _timelineTransform =
      TransformationController();
  final TransformationController _elementTransform = TransformationController();

  String _view = 'timeline';
  String _timelineRange = 'all';
  String _timelineCategory = 'all';
  String _timelineMode = 'story';
  String _elementCategory = 'all';
  String _elementState = 'all';
  _TimelineFact _selectedTimeline = _timelineFacts.first;
  _ElementFact _selectedElement = _elementFacts.first;

  @override
  void dispose() {
    _timelineTransform.dispose();
    _elementTransform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeText(
        context,
        zh: '历史年表/元素周期表',
        en: 'Timeline and periodic table',
      ),
      subtitle: _lifeText(
        context,
        zh: '按可信资料整理的宏观历史轴与 118 元素动态表。',
        en: 'Consensus timeline anchors and a dynamic 118-element table.',
      ),
      child: Column(
        key: const ValueKey<String>('timeline-periodic-page'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildViewSwitch(context),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _view == 'timeline'
                ? _buildTimelineView(context)
                : _buildElementView(context),
          ),
          const SizedBox(height: 14),
          _buildSourcesPanel(context),
        ],
      ),
    );
  }

  Widget _buildViewSwitch(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        ChoiceChip(
          selected: _view == 'timeline',
          avatar: const Icon(Icons.view_timeline_rounded, size: 18),
          label: Text(_lifeText(context, zh: '历史年表', en: 'Timeline')),
          onSelected: (_) => setState(() => _view = 'timeline'),
        ),
        ChoiceChip(
          selected: _view == 'elements',
          avatar: const Icon(Icons.grid_view_rounded, size: 18),
          label: Text(_lifeText(context, zh: '元素周期表', en: 'Elements')),
          onSelected: (_) => setState(() => _view = 'elements'),
        ),
      ],
    );
  }

  Widget _buildTimelineView(BuildContext context) {
    final visibleFacts = _visibleTimelineFacts;
    final window = _timelineWindow(_timelineRange);
    final backdrop = _timelineBackdropFor(_selectedTimeline.category);
    return Column(
      key: const ValueKey<String>('timeline-view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeText(context, zh: '节点', en: 'Events'),
              value: '${visibleFacts.length}',
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '跨度', en: 'Span'),
              value: _timelineRangeLabel(context, _timelineRange),
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '来源', en: 'Sources'),
              value: '${_timelinePeriodicSources.length}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _LifeSettingsPanel(
          title: _lifeText(context, zh: '年表筛选', en: 'Timeline filters'),
          subtitle: _lifeText(
            context,
            zh: '时间采用对数轴，近现代节点会自然拉开。',
            en: 'A logarithmic time axis keeps recent events readable.',
          ),
          children: <Widget>[
            _LifeSegmentedField<String>(
              label: _lifeText(context, zh: '时间范围', en: 'Time range'),
              value: _timelineRange,
              options: const <_LifeOption<String>>[
                _LifeOption(value: 'all', labelZh: '全部', labelEn: 'All'),
                _LifeOption(value: 'earth', labelZh: '地球', labelEn: 'Earth'),
                _LifeOption(value: 'human', labelZh: '人类', labelEn: 'Human'),
                _LifeOption(
                  value: 'civilization',
                  labelZh: '文明',
                  labelEn: 'Civilization',
                ),
                _LifeOption(value: 'modern', labelZh: '近现代', labelEn: 'Modern'),
              ],
              onChanged: (value) {
                setState(() {
                  _timelineRange = value;
                  final next = _visibleTimelineFacts;
                  if (!next.contains(_selectedTimeline) && next.isNotEmpty) {
                    _selectedTimeline = next.first;
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            _LifeSegmentedField<String>(
              label: _lifeText(context, zh: '主题', en: 'Theme'),
              value: _timelineCategory,
              options: const <_LifeOption<String>>[
                _LifeOption(value: 'all', labelZh: '全部', labelEn: 'All'),
                _LifeOption(value: 'cosmic', labelZh: '宇宙', labelEn: 'Cosmic'),
                _LifeOption(value: 'earth', labelZh: '地球', labelEn: 'Earth'),
                _LifeOption(value: 'human', labelZh: '人类', labelEn: 'Human'),
                _LifeOption(
                  value: 'civilization',
                  labelZh: '文明',
                  labelEn: 'Civilization',
                ),
                _LifeOption(
                  value: 'science',
                  labelZh: '科学',
                  labelEn: 'Science',
                ),
                _LifeOption(value: 'modern', labelZh: '近现代', labelEn: 'Modern'),
              ],
              onChanged: (value) {
                setState(() {
                  _timelineCategory = value;
                  final next = _visibleTimelineFacts;
                  if (!next.contains(_selectedTimeline) && next.isNotEmpty) {
                    _selectedTimeline = next.first;
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            _LifeSegmentedField<String>(
              label: _lifeText(context, zh: '浏览方式', en: 'View mode'),
              value: _timelineMode,
              options: const <_LifeOption<String>>[
                _LifeOption(value: 'story', labelZh: '纵向故事轴', labelEn: 'Story'),
                _LifeOption(value: 'map', labelZh: '全景地图轴', labelEn: 'Map'),
              ],
              onChanged: (value) => setState(() => _timelineMode = value),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const ValueKey<String>('timeline-immersive-open'),
                onPressed: visibleFacts.isEmpty
                    ? null
                    : () => _openTimelineImmersive(context, visibleFacts),
                icon: const Icon(Icons.fullscreen_rounded),
                label: Text(_lifeText(context, zh: '沉浸全屏', en: 'Immersive')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (visibleFacts.isEmpty)
          _TimelineEmptyState()
        else if (_timelineMode == 'story')
          _TimelineStoryStage(
            facts: visibleFacts,
            selected: _selectedTimeline,
            backdrop: backdrop,
            onSelected: (fact) => setState(() => _selectedTimeline = fact),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final stageWidth = math.max(
                constraints.maxWidth * 4.8,
                window.id == 'all' ? 2800.0 : 1900.0,
              );
              return _TimelineViewport(
                facts: visibleFacts,
                window: window,
                width: stageWidth,
                selected: _selectedTimeline,
                backdrop: backdrop,
                controller: _timelineTransform,
                onReset: () => _timelineTransform.value = Matrix4.identity(),
                onFullscreen: () =>
                    _openTimelineImmersive(context, visibleFacts),
                onSelected: (fact) => setState(() => _selectedTimeline = fact),
              );
            },
          ),
        const SizedBox(height: 12),
        _TimelineFactCard(fact: _selectedTimeline),
      ],
    );
  }

  Widget _buildElementView(BuildContext context) {
    final visibleElements = _visibleElementFacts;
    return Column(
      key: const ValueKey<String>('element-view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeText(context, zh: '元素', en: 'Elements'),
              value: '${_elementFacts.length}',
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '当前显示', en: 'Visible'),
              value: '${visibleElements.length}',
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '数据', en: 'Data'),
              value: 'PubChem',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _LifeSettingsPanel(
          title: _lifeText(context, zh: '元素筛选', en: 'Element filters'),
          subtitle: _lifeText(
            context,
            zh: '分类来自 PubChem group block；原子量按来源表展示。',
            en: 'Group blocks come from PubChem; atomic masses follow the source table.',
          ),
          children: <Widget>[
            _LifeSegmentedField<String>(
              label: _lifeText(context, zh: '族块', en: 'Group block'),
              value: _elementCategory,
              options: _elementCategoryOptions,
              onChanged: (value) => setState(() => _elementCategory = value),
            ),
            const SizedBox(height: 12),
            _LifeSegmentedField<String>(
              label: _lifeText(context, zh: '状态', en: 'State'),
              value: _elementState,
              options: const <_LifeOption<String>>[
                _LifeOption(value: 'all', labelZh: '全部', labelEn: 'All'),
                _LifeOption(value: 'solid', labelZh: '固体', labelEn: 'Solid'),
                _LifeOption(value: 'liquid', labelZh: '液体', labelEn: 'Liquid'),
                _LifeOption(value: 'gas', labelZh: '气体', labelEn: 'Gas'),
                _LifeOption(
                  value: 'expected',
                  labelZh: '预测',
                  labelEn: 'Expected',
                ),
              ],
              onChanged: (value) => setState(() => _elementState = value),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _PeriodicViewport(
          selected: _selectedElement,
          visibleElements: visibleElements,
          controller: _elementTransform,
          onReset: () => _elementTransform.value = Matrix4.identity(),
          onSelected: (element) => setState(() => _selectedElement = element),
        ),
        const SizedBox(height: 12),
        _ElementFactCard(element: _selectedElement),
        const SizedBox(height: 10),
        _ElementLegend(),
      ],
    );
  }

  Widget _buildSourcesPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '资料来源', en: 'Sources'),
      subtitle: _lifeText(
        context,
        zh: '本模块只内置共识性节点和可核验元素数据。',
        en: 'This module embeds consensus anchors and verifiable element data.',
      ),
      children: <Widget>[
        for (final source in _timelinePeriodicSources)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new_rounded),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Text(source.name, overflow: TextOverflow.ellipsis),
              ),
              onPressed: () => _openExternal(context, source.url),
            ),
          ),
      ],
    );
  }

  List<_TimelineFact> get _visibleTimelineFacts {
    final window = _timelineWindow(_timelineRange);
    return _timelineFacts
        .where(
          (fact) =>
              fact.yearsBeforePresent <= window.maxYearsBeforePresent &&
              fact.yearsBeforePresent >= window.minYearsBeforePresent,
        )
        .where(
          (fact) =>
              _timelineCategory == 'all' || fact.category == _timelineCategory,
        )
        .toList(growable: false);
  }

  List<_ElementFact> get _visibleElementFacts {
    return _elementFacts
        .where((element) {
          final categoryOk =
              _elementCategory == 'all' ||
              element.groupBlock == _elementCategory;
          final stateOk =
              _elementState == 'all' ||
              _elementStateKey(element) == _elementState;
          return categoryOk && stateOk;
        })
        .toList(growable: false);
  }

  void _openTimelineImmersive(
    BuildContext context,
    List<_TimelineFact> visibleFacts,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _TimelineImmersivePage(
          facts: visibleFacts,
          initialSelected: _selectedTimeline,
          rangeLabel: _timelineRangeLabel(context, _timelineRange),
        ),
      ),
    );
  }
}

class _TimelineWindow {
  const _TimelineWindow({
    required this.id,
    required this.minYearsBeforePresent,
    required this.maxYearsBeforePresent,
  });

  final String id;
  final double minYearsBeforePresent;
  final double maxYearsBeforePresent;
}

class _TimelineEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.manage_search_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _lifeText(
                context,
                zh: '当前筛选下暂无节点，请切换时间范围或主题。',
                en: 'No events match these filters. Try another range or theme.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStoryStage extends StatelessWidget {
  const _TimelineStoryStage({
    required this.facts,
    required this.selected,
    required this.backdrop,
    required this.onSelected,
    this.immersive = false,
  });

  final List<_TimelineFact> facts;
  final _TimelineFact selected;
  final _TimelineBackdropAsset backdrop;
  final ValueChanged<_TimelineFact> onSelected;
  final bool immersive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey<String>('history-timeline-stage'),
      decoration: BoxDecoration(
        color: immersive
            ? Colors.black.withValues(alpha: 0.32)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: immersive
              ? Colors.white.withValues(alpha: 0.18)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _TimelineStoryHeader(
            selected: selected,
            backdrop: backdrop,
            eventCount: facts.length,
            immersive: immersive,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
            child: Column(
              children: <Widget>[
                for (var index = 0; index < facts.length; index += 1)
                  _TimelineStoryTile(
                    fact: facts[index],
                    selected: facts[index].id == selected.id,
                    isFirst: index == 0,
                    isLast: index == facts.length - 1,
                    immersive: immersive,
                    onTap: () => onSelected(facts[index]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStoryHeader extends StatelessWidget {
  const _TimelineStoryHeader({
    required this.selected,
    required this.backdrop,
    required this.eventCount,
    required this.immersive,
  });

  final _TimelineFact selected;
  final _TimelineBackdropAsset backdrop;
  final int eventCount;
  final bool immersive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _timelineCategoryColor(selected.category);
    return SizedBox(
      height: immersive ? 270 : 220,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _TimelineBackdrop(asset: backdrop, darken: immersive ? 0.58 : 0.42),
          Padding(
            padding: EdgeInsets.fromLTRB(18, immersive ? 24 : 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _TimelinePeriodicPill(
                      color: color,
                      label: _timelineCategoryLabel(context, selected.category),
                    ),
                    _TimelinePeriodicPill(
                      color: theme.colorScheme.primary,
                      label: _lifeText(
                        context,
                        zh: '$eventCount 个节点',
                        en: '$eventCount events',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _lifeText(
                    context,
                    zh: selected.displayZh,
                    en: selected.displayEn,
                  ),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _lifeText(
                    context,
                    zh: selected.titleZh,
                    en: selected.titleEn,
                  ),
                  maxLines: immersive ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (immersive
                              ? theme.textTheme.headlineSmall
                              : theme.textTheme.titleLarge)
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            height: 1.08,
                          ),
                ),
                const SizedBox(height: 8),
                Text(
                  _lifeText(
                    context,
                    zh: selected.detailZh,
                    en: selected.detailEn,
                  ),
                  maxLines: immersive ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Tooltip(
              message: backdrop.credit,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      backdrop.sourceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStoryTile extends StatelessWidget {
  const _TimelineStoryTile({
    required this.fact,
    required this.selected,
    required this.isFirst,
    required this.isLast,
    required this.immersive,
    required this.onTap,
  });

  final _TimelineFact fact;
  final bool selected;
  final bool isFirst;
  final bool isLast;
  final bool immersive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _timelineCategoryColor(fact.category);
    final surface = immersive
        ? Colors.white.withValues(alpha: selected ? 0.14 : 0.08)
        : Color.lerp(theme.colorScheme.surface, color, selected ? 0.12 : 0.04)!;
    final borderColor = selected
        ? color
        : immersive
        ? Colors.white.withValues(alpha: 0.16)
        : theme.colorScheme.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 34,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst
                        ? Colors.transparent
                        : color.withValues(alpha: 0.26),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: selected ? 16 : 11,
                  height: selected ? 16 : 11,
                  decoration: BoxDecoration(
                    color: selected ? color : theme.colorScheme.surface,
                    border: Border.all(color: color, width: selected ? 3 : 2),
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      if (selected)
                        BoxShadow(
                          color: color.withValues(alpha: 0.32),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : color.withValues(alpha: 0.26),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: borderColor,
                        width: selected ? 1.8 : 1,
                      ),
                      boxShadow: <BoxShadow>[
                        if (selected && !immersive)
                          BoxShadow(
                            color: color.withValues(alpha: 0.14),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            Text(
                              _lifeText(
                                context,
                                zh: fact.displayZh,
                                en: fact.displayEn,
                              ),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            _TimelinePeriodicPill(
                              color: color,
                              label: _timelineCategoryLabel(
                                context,
                                fact.category,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _lifeText(
                            context,
                            zh: fact.titleZh,
                            en: fact.titleEn,
                          ),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _lifeText(
                            context,
                            zh: fact.detailZh,
                            en: fact.detailEn,
                          ),
                          maxLines: selected || immersive ? 4 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.28,
                            color: immersive
                                ? Colors.white.withValues(alpha: 0.82)
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () =>
                                _openExternal(context, fact.sourceUrl),
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: Text(fact.sourceName),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineBackdrop extends StatelessWidget {
  const _TimelineBackdrop({required this.asset, required this.darken});

  final _TimelineBackdropAsset asset;
  final double darken;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _TimelineRemoteBackdrop(asset: asset),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Colors.black.withValues(alpha: darken * 0.72),
                Colors.black.withValues(alpha: darken),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineRemoteBackdrop extends StatefulWidget {
  const _TimelineRemoteBackdrop({required this.asset});

  final _TimelineBackdropAsset asset;

  @override
  State<_TimelineRemoteBackdrop> createState() =>
      _TimelineRemoteBackdropState();
}

class _TimelineRemoteBackdropState extends State<_TimelineRemoteBackdrop> {
  static final Map<String, Uint8List?> _cache = <String, Uint8List?>{};
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _TimelineRemoteBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.imageUrl != widget.asset.imageUrl) {
      _bytes = null;
      _failed = false;
      _load();
    }
  }

  Future<void> _load() async {
    final url = widget.asset.imageUrl;
    if (_cache.containsKey(url)) {
      if (!mounted) return;
      setState(() {
        _bytes = _cache[url];
        _failed = _bytes == null;
      });
      return;
    }

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _cache[url] = response.bodyBytes;
      } else {
        _cache[url] = null;
      }
    } on Object {
      _cache[url] = null;
    }

    if (!mounted) return;
    setState(() {
      _bytes = _cache[url];
      _failed = _bytes == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (_failed || bytes == null) {
      return _TimelineFallbackBackdrop(asset: widget.asset);
    }
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
    );
  }
}

class _TimelineFallbackBackdrop extends StatelessWidget {
  const _TimelineFallbackBackdrop({required this.asset});

  final _TimelineBackdropAsset asset;

  @override
  Widget build(BuildContext context) {
    final color = _timelineCategoryColor(asset.category);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.lerp(Colors.black, color, 0.38)!,
            Color.lerp(Colors.black, color, 0.16)!,
            Colors.black,
          ],
        ),
      ),
    );
  }
}

class _TimelineImmersivePage extends StatefulWidget {
  const _TimelineImmersivePage({
    required this.facts,
    required this.initialSelected,
    required this.rangeLabel,
  });

  final List<_TimelineFact> facts;
  final _TimelineFact initialSelected;
  final String rangeLabel;

  @override
  State<_TimelineImmersivePage> createState() => _TimelineImmersivePageState();
}

class _TimelineImmersivePageState extends State<_TimelineImmersivePage> {
  late _TimelineFact _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelected;
    unawaited(
      _enterLifeImmersive(orientations: _lifeAllOrientations, brightness: 0.9),
    );
  }

  @override
  void dispose() {
    unawaited(_exitLifeImmersive());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backdrop = _timelineBackdropFor(_selected.category);
    return Theme(
      data: ThemeData.dark(useMaterial3: true),
      child: Scaffold(
        key: const ValueKey<String>('timeline-immersive-page'),
        backgroundColor: Colors.black,
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: _TimelineBackdrop(asset: backdrop, darken: 0.74),
            ),
            SafeArea(
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _lifeText(
                                    context,
                                    zh: '沉浸历史年表',
                                    en: 'Immersive timeline',
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.rangeLabel} · ${widget.facts.length} ${_lifeText(context, zh: '个节点', en: 'events')}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.74,
                                        ),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            key: const ValueKey<String>(
                              'timeline-immersive-close',
                            ),
                            tooltip: _lifeText(
                              context,
                              zh: '退出全屏',
                              en: 'Exit fullscreen',
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_fullscreen_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                      child: _TimelineStoryStage(
                        facts: widget.facts,
                        selected: _selected,
                        backdrop: backdrop,
                        immersive: true,
                        onSelected: (fact) => setState(() => _selected = fact),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineViewport extends StatelessWidget {
  const _TimelineViewport({
    required this.facts,
    required this.window,
    required this.width,
    required this.selected,
    required this.backdrop,
    required this.controller,
    required this.onReset,
    required this.onFullscreen,
    required this.onSelected,
  });

  final List<_TimelineFact> facts;
  final _TimelineWindow window;
  final double width;
  final _TimelineFact selected;
  final _TimelineBackdropAsset backdrop;
  final TransformationController controller;
  final VoidCallback onReset;
  final VoidCallback onFullscreen;
  final ValueChanged<_TimelineFact> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey<String>('history-timeline-stage'),
      height: 560,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: _TimelineBackdrop(asset: backdrop, darken: 0.55),
          ),
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: controller,
              constrained: false,
              minScale: 0.55,
              maxScale: 4.2,
              boundaryMargin: const EdgeInsets.symmetric(
                horizontal: 720,
                vertical: 180,
              ),
              child: SizedBox(
                width: width,
                height: 560,
                child: _TimelineStage(
                  facts: facts,
                  window: window,
                  selected: selected,
                  onSelected: onSelected,
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton.filledTonal(
                  tooltip: _lifeText(context, zh: '沉浸全屏', en: 'Immersive'),
                  onPressed: onFullscreen,
                  icon: const Icon(Icons.fullscreen_rounded),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: _lifeText(context, zh: '重置视图', en: 'Reset view'),
                  onPressed: onReset,
                  icon: const Icon(Icons.center_focus_strong_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStage extends StatelessWidget {
  const _TimelineStage({
    required this.facts,
    required this.window,
    required this.selected,
    required this.onSelected,
  });

  final List<_TimelineFact> facts;
  final _TimelineWindow window;
  final _TimelineFact selected;
  final ValueChanged<_TimelineFact> onSelected;

  @override
  Widget build(BuildContext context) {
    const leftPad = 88.0;
    const rightPad = 120.0;
    const topPad = 62.0;
    const laneHeight = 72.0;
    const markerWidth = 184.0;
    final lanes = _timelineLanes(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final usableWidth = constraints.maxWidth - leftPad - rightPad;
        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(
                painter: _TimelineAxisPainter(
                  window: window,
                  lanes: lanes,
                  leftPad: leftPad,
                  rightPad: rightPad,
                  topPad: topPad,
                  laneHeight: laneHeight,
                  textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  lineColor: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            for (final fact in facts)
              Positioned(
                left:
                    (leftPad +
                            _timelineX(
                              fact.yearsBeforePresent,
                              window,
                              usableWidth,
                            ) -
                            markerWidth / 2)
                        .clamp(12.0, constraints.maxWidth - markerWidth - 12),
                top:
                    topPad +
                    lanes.indexOf(fact.category).clamp(0, lanes.length - 1) *
                        laneHeight +
                    8,
                width: markerWidth,
                child: _TimelineMarker(
                  fact: fact,
                  selected: fact.id == selected.id,
                  onTap: () => onSelected(fact),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TimelineAxisPainter extends CustomPainter {
  const _TimelineAxisPainter({
    required this.window,
    required this.lanes,
    required this.leftPad,
    required this.rightPad,
    required this.topPad,
    required this.laneHeight,
    required this.textColor,
    required this.lineColor,
  });

  final _TimelineWindow window;
  final List<String> lanes;
  final double leftPad;
  final double rightPad;
  final double topPad;
  final double laneHeight;
  final Color textColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final usableWidth = size.width - leftPad - rightPad;
    final axisY = topPad + lanes.length * laneHeight + 30;

    for (var index = 0; index < lanes.length; index += 1) {
      final y = topPad + index * laneHeight + 28;
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width - rightPad, y),
        paint,
      );
      _paintText(
        canvas,
        _timelineCategoryShort(lanes[index]),
        Offset(12, y - 8),
        12,
      );
    }

    canvas.drawLine(
      Offset(leftPad, axisY),
      Offset(size.width - rightPad, axisY),
      paint..strokeWidth = 1.4,
    );

    for (final tick in _timelineTicks(window)) {
      final x = leftPad + _timelineX(tick, window, usableWidth);
      canvas.drawLine(Offset(x, axisY - 6), Offset(x, axisY + 6), paint);
      _paintText(
        canvas,
        _compactYearsBeforePresent(tick),
        Offset(x - 28, axisY + 12),
        11,
      );
    }
  }

  void _paintText(Canvas canvas, String text, Offset offset, double size) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontSize: size,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 74);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _TimelineAxisPainter oldDelegate) {
    return oldDelegate.window != window ||
        oldDelegate.lanes != lanes ||
        oldDelegate.textColor != textColor ||
        oldDelegate.lineColor != lineColor;
  }
}

class _TimelineMarker extends StatelessWidget {
  const _TimelineMarker({
    required this.fact,
    required this.selected,
    required this.onTap,
  });

  final _TimelineFact fact;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _timelineCategoryColor(fact.category);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Color.lerp(
              theme.colorScheme.surface,
              color,
              selected ? 0.18 : 0.08,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.35),
              width: selected ? 2 : 1,
            ),
            boxShadow: <BoxShadow>[
              if (selected)
                BoxShadow(
                  color: color.withValues(alpha: 0.20),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _lifeText(context, zh: fact.displayZh, en: fact.displayEn),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _lifeText(context, zh: fact.titleZh, en: fact.titleEn),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineFactCard extends StatelessWidget {
  const _TimelineFactCard({required this.fact});

  final _TimelineFact fact;

  @override
  Widget build(BuildContext context) {
    final color = _timelineCategoryColor(fact.category);
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: fact.titleZh, en: fact.titleEn),
      subtitle:
          '${_lifeText(context, zh: fact.displayZh, en: fact.displayEn)} · ${_timelineCategoryLabel(context, fact.category)}',
      children: <Widget>[
        Text(_lifeText(context, zh: fact.detailZh, en: fact.detailEn)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _TimelinePeriodicPill(
              color: color,
              label: _timelineCategoryLabel(context, fact.category),
            ),
            OutlinedButton.icon(
              onPressed: () => _openExternal(context, fact.sourceUrl),
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(fact.sourceName),
            ),
          ],
        ),
      ],
    );
  }
}

class _PeriodicViewport extends StatelessWidget {
  const _PeriodicViewport({
    required this.selected,
    required this.visibleElements,
    required this.controller,
    required this.onReset,
    required this.onSelected,
  });

  final _ElementFact selected;
  final List<_ElementFact> visibleElements;
  final TransformationController controller;
  final VoidCallback onReset;
  final ValueChanged<_ElementFact> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const cell = 62.0;
    const gap = 6.0;
    const width = 18 * cell + 17 * gap;
    const height = 9 * cell + 8 * gap;
    final visibleIds = visibleElements
        .map((element) => element.atomicNumber)
        .toSet();

    return Container(
      key: const ValueKey<String>('periodic-table-stage'),
      height: 430,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.38,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: controller,
              constrained: false,
              minScale: 0.62,
              maxScale: 2.6,
              boundaryMargin: const EdgeInsets.symmetric(
                horizontal: 420,
                vertical: 150,
              ),
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  children: <Widget>[
                    for (final element in _elementFacts)
                      Positioned(
                        left: (element.displayColumn - 1) * (cell + gap),
                        top: (element.displayRow - 1) * (cell + gap),
                        width: cell,
                        height: cell,
                        child: _ElementTile(
                          element: element,
                          muted: !visibleIds.contains(element.atomicNumber),
                          selected:
                              selected.atomicNumber == element.atomicNumber,
                          onTap: () => onSelected(element),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: IconButton.filledTonal(
              tooltip: _lifeText(context, zh: '重置视图', en: 'Reset view'),
              onPressed: onReset,
              icon: const Icon(Icons.center_focus_strong_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _ElementTile extends StatelessWidget {
  const _ElementTile({
    required this.element,
    required this.muted,
    required this.selected,
    required this.onTap,
  });

  final _ElementFact element;
  final bool muted;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _elementBlockColor(element.groupBlock);
    return Opacity(
      opacity: muted ? 0.24 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Color.lerp(
                theme.colorScheme.surface,
                color,
                selected ? 0.26 : 0.14,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? color : color.withValues(alpha: 0.45),
                width: selected ? 2 : 1,
              ),
              boxShadow: <BoxShadow>[
                if (selected)
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${element.atomicNumber}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        element.symbol,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  element.nameEn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(height: 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ElementFactCard extends StatelessWidget {
  const _ElementFactCard({required this.element});

  final _ElementFact element;

  @override
  Widget build(BuildContext context) {
    final color = _elementBlockColor(element.groupBlock);
    return _LifeSettingsPanel(
      title: '${element.symbol} · ${element.nameEn}',
      subtitle: _lifeText(
        context,
        zh: '原子序数 ${element.atomicNumber} · 第 ${element.period} 周期 · 第 ${element.group} 族',
        en: 'Atomic number ${element.atomicNumber} · Period ${element.period} · Group ${element.group}',
      ),
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _TimelinePeriodicPill(color: color, label: element.groupBlock),
            _TimelinePeriodicPill(
              color: Theme.of(context).colorScheme.secondary,
              label: _elementStateLabel(context, element),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ElementInfoRow(
          label: _lifeText(context, zh: '相对原子质量', en: 'Atomic mass'),
          value: element.atomicMass,
        ),
        _ElementInfoRow(
          label: _lifeText(context, zh: '电负性', en: 'Electronegativity'),
          value: element.electronegativity.isEmpty
              ? _lifeText(context, zh: '未列出', en: 'Not listed')
              : element.electronegativity,
        ),
        _ElementInfoRow(
          label: _lifeText(context, zh: '电子排布', en: 'Configuration'),
          value: element.electronConfiguration,
        ),
        _ElementInfoRow(
          label: _lifeText(context, zh: '发现年份', en: 'Discovered'),
          value: element.yearDiscovered,
        ),
      ],
    );
  }
}

class _ElementInfoRow extends StatelessWidget {
  const _ElementInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 118,
            child: Text(label, style: theme.textTheme.labelLarge),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class _ElementLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final blocks =
        _elementFacts.map((element) => element.groupBlock).toSet().toList()
          ..sort();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final block in blocks)
          _TimelinePeriodicPill(color: _elementBlockColor(block), label: block),
      ],
    );
  }
}

class _TimelinePeriodicPill extends StatelessWidget {
  const _TimelinePeriodicPill({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: Color.lerp(theme.colorScheme.onSurface, color, 0.62),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

List<_LifeOption<String>> get _elementCategoryOptions {
  final blocks =
      _elementFacts.map((element) => element.groupBlock).toSet().toList()
        ..sort();
  return <_LifeOption<String>>[
    const _LifeOption(value: 'all', labelZh: '全部', labelEn: 'All'),
    for (final block in blocks)
      _LifeOption(value: block, labelZh: block, labelEn: block),
  ];
}

_TimelineBackdropAsset _timelineBackdropFor(String category) {
  return _timelineBackdropAssets.firstWhere(
    (asset) => asset.category == category,
    orElse: () => _timelineBackdropAssets.first,
  );
}

_TimelineWindow _timelineWindow(String range) {
  return switch (range) {
    'earth' => const _TimelineWindow(
      id: 'earth',
      minYearsBeforePresent: 0,
      maxYearsBeforePresent: 4600000000,
    ),
    'human' => const _TimelineWindow(
      id: 'human',
      minYearsBeforePresent: 0,
      maxYearsBeforePresent: 3200000,
    ),
    'civilization' => const _TimelineWindow(
      id: 'civilization',
      minYearsBeforePresent: 0,
      maxYearsBeforePresent: 14000,
    ),
    'modern' => const _TimelineWindow(
      id: 'modern',
      minYearsBeforePresent: 0,
      maxYearsBeforePresent: 420,
    ),
    _ => const _TimelineWindow(
      id: 'all',
      minYearsBeforePresent: 0,
      maxYearsBeforePresent: 13800000000,
    ),
  };
}

double _timelineX(
  double yearsBeforePresent,
  _TimelineWindow window,
  double width,
) {
  final minLog = math.log(window.minYearsBeforePresent + 1);
  final maxLog = math.log(window.maxYearsBeforePresent + 1);
  final valueLog = math.log(yearsBeforePresent + 1);
  final ratio = ((maxLog - valueLog) / (maxLog - minLog)).clamp(0.0, 1.0);
  return ratio.toDouble() * width;
}

List<double> _timelineTicks(_TimelineWindow window) {
  return switch (window.id) {
    'modern' => const <double>[400, 300, 200, 100, 50, 10, 0],
    'civilization' => const <double>[12000, 5000, 3000, 1000, 500, 100, 0],
    'human' => const <double>[3000000, 1000000, 300000, 100000, 10000, 1000, 0],
    'earth' => const <double>[
      4500000000,
      3500000000,
      2500000000,
      1000000000,
      500000000,
      100000000,
      0,
    ],
    _ => const <double>[
      13800000000,
      4500000000,
      1000000000,
      100000000,
      1000000,
      10000,
      0,
    ],
  };
}

List<String> _timelineLanes(BuildContext context) {
  return const <String>[
    'cosmic',
    'earth',
    'human',
    'civilization',
    'science',
    'modern',
  ];
}

String _timelineRangeLabel(BuildContext context, String range) {
  return switch (range) {
    'earth' => _lifeText(context, zh: '地球以来', en: 'Earth'),
    'human' => _lifeText(context, zh: '人类尺度', en: 'Human'),
    'civilization' => _lifeText(context, zh: '文明尺度', en: 'Civilization'),
    'modern' => _lifeText(context, zh: '近现代', en: 'Modern'),
    _ => _lifeText(context, zh: '宇宙尺度', en: 'All'),
  };
}

String _timelineCategoryLabel(BuildContext context, String category) {
  return switch (category) {
    'cosmic' => _lifeText(context, zh: '宇宙', en: 'Cosmic'),
    'earth' => _lifeText(context, zh: '地球', en: 'Earth'),
    'human' => _lifeText(context, zh: '人类', en: 'Human'),
    'civilization' => _lifeText(context, zh: '文明', en: 'Civilization'),
    'science' => _lifeText(context, zh: '科学', en: 'Science'),
    'modern' => _lifeText(context, zh: '近现代', en: 'Modern'),
    _ => category,
  };
}

String _timelineCategoryShort(String category) {
  return switch (category) {
    'cosmic' => 'Cosmic',
    'earth' => 'Earth',
    'human' => 'Human',
    'civilization' => 'Civil',
    'science' => 'Sci',
    'modern' => 'Modern',
    _ => category,
  };
}

Color _timelineCategoryColor(String category) {
  return switch (category) {
    'cosmic' => const Color(0xFF5470C6),
    'earth' => const Color(0xFF3A9B7A),
    'human' => const Color(0xFFC77D3A),
    'civilization' => const Color(0xFFB05A78),
    'science' => const Color(0xFF7E63B6),
    'modern' => const Color(0xFF3E8AA7),
    _ => const Color(0xFF6B7280),
  };
}

String _compactYearsBeforePresent(double value) {
  if (value <= 0) {
    return 'Now';
  }
  if (value >= 1000000000) {
    return '${(value / 1000000000).toStringAsFixed(value >= 10000000000 ? 1 : 0)}B';
  }
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
  }
  return value.toStringAsFixed(0);
}

String _elementStateKey(_ElementFact element) {
  final state = element.standardState.toLowerCase();
  if (state.contains('expected')) {
    return 'expected';
  }
  if (state.contains('liquid')) {
    return 'liquid';
  }
  if (state.contains('gas')) {
    return 'gas';
  }
  return 'solid';
}

String _elementStateLabel(BuildContext context, _ElementFact element) {
  return switch (_elementStateKey(element)) {
    'liquid' => _lifeText(context, zh: '液体', en: 'Liquid'),
    'gas' => _lifeText(context, zh: '气体', en: 'Gas'),
    'expected' => _lifeText(context, zh: '预测状态', en: 'Expected state'),
    _ => _lifeText(context, zh: '固体', en: 'Solid'),
  };
}

Color _elementBlockColor(String block) {
  return switch (block) {
    'Alkali metal' => const Color(0xFFD86F45),
    'Alkaline earth metal' => const Color(0xFFD5A23A),
    'Transition metal' => const Color(0xFF4F86C6),
    'Post-transition metal' => const Color(0xFF69966D),
    'Metalloid' => const Color(0xFF8C8E43),
    'Nonmetal' => const Color(0xFF43A69A),
    'Halogen' => const Color(0xFF9B6ED0),
    'Noble gas' => const Color(0xFF6C7BD9),
    'Lanthanide' => const Color(0xFFC06B9A),
    'Actinide' => const Color(0xFFA9625C),
    _ => const Color(0xFF6B7280),
  };
}

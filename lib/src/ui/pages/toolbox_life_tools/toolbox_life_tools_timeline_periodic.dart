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
  final TextEditingController _timelineSearchController =
      TextEditingController();
  final TextEditingController _elementSearchController =
      TextEditingController();

  String _view = 'timeline';
  String _timelineCollection = 'general';
  String _timelineRange = 'all';
  String _timelineCategory = 'all';
  String _timelineMode = 'story';
  String _timelineSearch = '';
  String _elementMode = 'overview';
  String _elementCategory = 'all';
  String _elementState = 'all';
  String _elementSearch = '';
  late _TimelineFact _selectedTimeline;
  late _ElementFact _selectedElement;

  @override
  void initState() {
    super.initState();
    _selectedTimeline = _firstTimelineFact('general');
    _selectedElement = _elementFacts.first;
  }

  @override
  void dispose() {
    _timelineTransform.dispose();
    _elementTransform.dispose();
    _timelineSearchController.dispose();
    _elementSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.timeline_and_periodic_table.a8ffb824aa25',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.consensus_timeline_anchors_and_a_dyn.50984080c376',
      ),
      child: Column(
        key: const ValueKey<String>('timeline-periodic-page'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildViewSwitch(context),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _view == 'timeline'
                ? _buildTimelineView(context)
                : _buildElementView(context),
          ),
          const SizedBox(height: 14),
          const _TimelineSourcesPanel(sources: _timelinePeriodicSources),
        ],
      ),
    );
  }

  Widget _buildViewSwitch(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.life.timeline.overview_title'),
      subtitle: _lifeI18nText(context, 'toolbox.life.timeline.overview_body'),
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ChoiceChip(
              selected: _view == 'timeline',
              avatar: const Icon(Icons.view_timeline_rounded, size: 18),
              label: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.timeline.cad2ba3451bc',
                ),
              ),
              onSelected: (_) => setState(() => _view = 'timeline'),
            ),
            ChoiceChip(
              selected: _view == 'elements',
              avatar: const Icon(Icons.grid_view_rounded, size: 18),
              label: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.elements.97f277a13835',
                ),
              ),
              onSelected: (_) => setState(() => _view = 'elements'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineView(BuildContext context) {
    final visibleFacts = _visibleTimelineFacts(context);
    return Column(
      key: const ValueKey<String>('timeline-view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _TimelineMetricRow(
          eventCount: visibleFacts.length,
          rangeLabel: _timelineRangeLabel(context, _timelineRange),
        ),
        const SizedBox(height: 12),
        _buildTimelineFilters(context, visibleFacts),
        const SizedBox(height: 12),
        if (visibleFacts.isEmpty)
          const _TimelineEmptyState()
        else if (_timelineMode == 'story')
          _TimelineStoryStage(
            facts: visibleFacts,
            selected: _selectedTimeline,
            onSelected: (fact) => setState(() => _selectedTimeline = fact),
          )
        else
          _TimelineMapStage(
            facts: visibleFacts,
            window: _timelineWindow(_timelineRange),
            selected: _selectedTimeline,
            controller: _timelineTransform,
            onSelected: (fact) => setState(() => _selectedTimeline = fact),
            onReset: _resetTimelineTransform,
            onFullscreen: () => _openTimelineFullscreen(context, visibleFacts),
          ),
        if (visibleFacts.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _TimelineFactCard(fact: _selectedTimeline),
        ],
      ],
    );
  }

  Widget _buildTimelineFilters(
    BuildContext context,
    List<_TimelineFact> visibleFacts,
  ) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.timeline_filters.3c402383b010',
      ),
      subtitle: _lifeI18nText(context, 'toolbox.life.timeline.source_note'),
      children: <Widget>[
        TextField(
          key: const ValueKey<String>('timeline-search-field'),
          controller: _timelineSearchController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            labelText: _lifeI18nText(context, 'toolbox.life.timeline.search'),
            hintText: _lifeI18nText(
              context,
              'toolbox.life.timeline.search_hint',
            ),
            suffixIcon: _timelineSearch.isEmpty
                ? null
                : IconButton(
                    tooltip: _lifeI18nText(
                      context,
                      'toolbox.life.timeline.clear_search',
                    ),
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: _clearTimelineSearch,
                  ),
          ),
          onChanged: (value) {
            setState(() {
              _timelineSearch = value;
              _ensureSelectedTimelineVisible(context);
            });
          },
        ),
        const SizedBox(height: 12),
        _LifeSegmentedField<String>(
          label: _lifeI18nText(
            context,
            'toolbox.life.timeline.collection.label',
          ),
          value: _timelineCollection,
          options: const <_LifeOption<String>>[
            _LifeOption(
              value: 'general',
              labelKey: 'toolbox.life.timeline.collection.general',
            ),
            _LifeOption(
              value: 'china_overview',
              labelKey: 'toolbox.life.timeline.collection.china_overview',
            ),
          ],
          onChanged: (value) {
            setState(() {
              _timelineCollection = value;
              _timelineCategory = 'all';
              _timelineRange = 'all';
              _ensureSelectedTimelineVisible(context);
            });
          },
        ),
        const SizedBox(height: 12),
        _LifeSegmentedField<String>(
          label: _lifeI18nText(
            context,
            'inline.ui.pages.practice_review_page.time_range_2b3399',
          ),
          value: _timelineRange,
          options: const <_LifeOption<String>>[
            _LifeOption(
              value: 'all',
              labelKey: 'toolbox.life.timeline.all_periods',
            ),
            _LifeOption(
              value: 'earth',
              labelKey: 'inline.plan295.life.earth.e77b1debf5ac',
            ),
            _LifeOption(
              value: 'human',
              labelKey: 'inline.plan295.life.human.7ac93bc8501f',
            ),
            _LifeOption(
              value: 'civilization',
              labelKey: 'inline.plan295.life.civilization.b553343bf1f6',
            ),
            _LifeOption(
              value: 'modern',
              labelKey: 'inline.plan295.life.modern.0eb29c68f83b',
            ),
          ],
          onChanged: (value) {
            setState(() {
              _timelineRange = value;
              _ensureSelectedTimelineVisible(context);
            });
          },
        ),
        const SizedBox(height: 12),
        _LifeSegmentedField<String>(
          label: _lifeI18nText(context, 'toolbox.life.timeline.all_topics'),
          value: _timelineCategory,
          options: const <_LifeOption<String>>[
            _LifeOption(
              value: 'all',
              labelKey: 'toolbox.life.timeline.all_topics',
            ),
            _LifeOption(
              value: 'cosmic',
              labelKey: 'inline.plan295.life.cosmic.9faf20d9169e',
            ),
            _LifeOption(
              value: 'earth',
              labelKey: 'inline.plan295.life.earth.e77b1debf5ac',
            ),
            _LifeOption(
              value: 'human',
              labelKey: 'inline.plan295.life.human.7ac93bc8501f',
            ),
            _LifeOption(
              value: 'civilization',
              labelKey: 'inline.plan295.life.civilization.b553343bf1f6',
            ),
            _LifeOption(
              value: 'science',
              labelKey: 'ref.toolbox.sleep.assist.scienceCard',
            ),
            _LifeOption(
              value: 'modern',
              labelKey: 'inline.plan295.life.modern.0eb29c68f83b',
            ),
          ],
          onChanged: (value) {
            setState(() {
              _timelineCategory = value;
              _ensureSelectedTimelineVisible(context);
            });
          },
        ),
        const SizedBox(height: 12),
        _LifeSegmentedField<String>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.view_mode.742241a6e6c8',
          ),
          value: _timelineMode,
          options: const <_LifeOption<String>>[
            _LifeOption(
              value: 'story',
              labelKey: 'toolbox.life.timeline.story_mode',
            ),
            _LifeOption(
              value: 'map',
              labelKey: 'toolbox.life.timeline.map_mode',
            ),
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
                : () => _openTimelineFullscreen(context, visibleFacts),
            icon: const Icon(Icons.fullscreen_rounded),
            label: Text(
              _lifeI18nText(context, 'toolbox.life.timeline.fullscreen'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildElementView(BuildContext context) {
    final visibleElements = _visibleElementFacts(context);
    return Column(
      key: const ValueKey<String>('element-view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _PeriodicMetricRow(visibleCount: visibleElements.length),
        const SizedBox(height: 12),
        _buildElementFilters(context),
        const SizedBox(height: 12),
        _PeriodicTableStage(
          selected: _selectedElement,
          visibleElements: visibleElements,
          detailed: _elementMode == 'details',
          controller: _elementTransform,
          onSelected: (element) => setState(() => _selectedElement = element),
          onReset: _resetElementTransform,
          onFullscreen: () => _openPeriodicFullscreen(context),
        ),
        const SizedBox(height: 12),
        _ElementFactCard(element: _selectedElement),
        const SizedBox(height: 12),
        const _ElementLegend(),
      ],
    );
  }

  Widget _buildElementFilters(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.life.periodic.overview_title'),
      subtitle: _lifeI18nText(context, 'toolbox.life.periodic.data_note'),
      children: <Widget>[
        TextField(
          key: const ValueKey<String>('periodic-search-field'),
          controller: _elementSearchController,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            labelText: _lifeI18nText(context, 'toolbox.life.periodic.search'),
            hintText: _lifeI18nText(
              context,
              'toolbox.life.periodic.search_hint',
            ),
            suffixIcon: _elementSearch.isEmpty
                ? null
                : IconButton(
                    tooltip: _lifeI18nText(
                      context,
                      'toolbox.life.periodic.clear_search',
                    ),
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: _clearElementSearch,
                  ),
          ),
          onChanged: (value) {
            setState(() {
              _elementSearch = value;
              _ensureSelectedElementVisible(context);
            });
          },
        ),
        const SizedBox(height: 12),
        _LifeSegmentedField<String>(
          label: _lifeI18nText(context, 'toolbox.life.periodic.overview_mode'),
          value: _elementMode,
          options: const <_LifeOption<String>>[
            _LifeOption(
              value: 'overview',
              labelKey: 'toolbox.life.periodic.overview_mode',
            ),
            _LifeOption(
              value: 'details',
              labelKey: 'toolbox.life.periodic.detail_mode',
            ),
          ],
          onChanged: (value) => setState(() => _elementMode = value),
        ),
        const SizedBox(height: 12),
        _LifeSegmentedField<String>(
          label: _lifeI18nText(context, 'toolbox.life.element.block.label'),
          value: _elementCategory,
          options: _elementCategoryOptions,
          onChanged: (value) => setState(() => _elementCategory = value),
        ),
        const SizedBox(height: 12),
        _LifeSegmentedField<String>(
          label: _lifeI18nText(context, 'toolbox.life.periodic.state'),
          value: _elementState,
          options: const <_LifeOption<String>>[
            _LifeOption(
              value: 'all',
              labelKey: 'toolbox.life.timeline.all_topics',
            ),
            _LifeOption(
              value: 'solid',
              labelKey: 'inline.plan295.life.solid.edf5c04808b9',
            ),
            _LifeOption(
              value: 'liquid',
              labelKey: 'inline.plan295.life.liquid.faca6f8190f7',
            ),
            _LifeOption(
              value: 'gas',
              labelKey: 'inline.plan295.life.gas.26a1b9794e2a',
            ),
            _LifeOption(
              value: 'expected',
              labelKey: 'inline.plan295.life.expected.46e4595f7ecd',
            ),
          ],
          onChanged: (value) => setState(() => _elementState = value),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const ValueKey<String>('periodic-fullscreen-open'),
            onPressed: () => _openPeriodicFullscreen(context),
            icon: const Icon(Icons.fullscreen_rounded),
            label: Text(
              _lifeI18nText(context, 'toolbox.life.timeline.fullscreen'),
            ),
          ),
        ),
      ],
    );
  }

  List<_TimelineFact> _visibleTimelineFacts(BuildContext context) {
    final window = _timelineWindow(_timelineRange);
    final query = _timelineSearch.trim().toLowerCase();
    return _timelineFacts
        .where((fact) => fact.collection == _timelineCollection)
        .where(
          (fact) =>
              fact.yearsBeforePresent >= window.minYearsBeforePresent &&
              fact.yearsBeforePresent <= window.maxYearsBeforePresent,
        )
        .where(
          (fact) =>
              _timelineCategory == 'all' || fact.category == _timelineCategory,
        )
        .where((fact) {
          if (query.isEmpty) return true;
          final text = <String>[
            fact.id,
            _lifeI18nText(context, fact.displayKey),
            _lifeI18nText(context, fact.titleKey),
            _lifeI18nText(context, fact.detailKey),
          ].join(' ').toLowerCase();
          return text.contains(query);
        })
        .toList(growable: false);
  }

  List<_ElementFact> _visibleElementFacts(BuildContext context) {
    final query = _elementSearch.trim().toLowerCase();
    return _elementFacts
        .where((element) {
          final categoryOk =
              _elementCategory == 'all' ||
              element.groupBlock == _elementCategory;
          final stateOk =
              _elementState == 'all' ||
              _elementStateKey(element) == _elementState;
          if (!categoryOk || !stateOk) return false;
          if (query.isEmpty) return true;
          final text = <String>[
            element.atomicNumber.toString(),
            element.symbol,
            element.nameEn,
            _lifeI18nText(context, element.nameKey),
          ].join(' ').toLowerCase();
          return text.contains(query);
        })
        .toList(growable: false);
  }

  List<_LifeOption<String>> get _elementCategoryOptions {
    final blocks = <String, String>{};
    for (final element in _elementFacts) {
      blocks.putIfAbsent(element.groupBlock, () => element.groupBlockKey);
    }
    return <_LifeOption<String>>[
      const _LifeOption(
        value: 'all',
        labelKey: 'toolbox.life.timeline.all_topics',
      ),
      for (final entry in blocks.entries)
        _LifeOption(value: entry.key, labelKey: entry.value),
    ];
  }

  void _ensureSelectedTimelineVisible(BuildContext context) {
    final visible = _visibleTimelineFacts(context);
    if (visible.isNotEmpty &&
        !visible.any(
          (fact) =>
              _timelineFactKey(fact) == _timelineFactKey(_selectedTimeline),
        )) {
      _selectedTimeline = visible.first;
    }
  }

  void _ensureSelectedElementVisible(BuildContext context) {
    final visible = _visibleElementFacts(context);
    if (visible.isNotEmpty &&
        !visible.any(
          (element) => element.atomicNumber == _selectedElement.atomicNumber,
        )) {
      _selectedElement = visible.first;
    }
  }

  void _clearTimelineSearch() {
    _timelineSearchController.clear();
    setState(() {
      _timelineSearch = '';
    });
  }

  void _clearElementSearch() {
    _elementSearchController.clear();
    setState(() {
      _elementSearch = '';
    });
  }

  void _resetTimelineTransform() {
    _timelineTransform.value = Matrix4.identity();
  }

  void _resetElementTransform() {
    _elementTransform.value = Matrix4.identity();
  }

  void _openTimelineFullscreen(
    BuildContext context,
    List<_TimelineFact> facts,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _TimelineImmersivePage(
          facts: facts,
          initialSelected: _selectedTimeline,
          initialMode: _timelineMode,
          rangeLabel: _timelineRangeLabel(context, _timelineRange),
        ),
      ),
    );
  }

  void _openPeriodicFullscreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PeriodicFullscreenPage(
          selected: _selectedElement,
          visibleElements: _visibleElementFacts(context),
        ),
      ),
    );
  }
}

_TimelineFact _firstTimelineFact(String collection) {
  return _timelineFacts.firstWhere(
    (fact) => fact.collection == collection,
    orElse: () => _timelineFacts.first,
  );
}

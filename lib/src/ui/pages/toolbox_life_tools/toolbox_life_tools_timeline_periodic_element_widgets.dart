part of '../toolbox_life_tools.dart';

class _PeriodicMetricRow extends StatelessWidget {
  const _PeriodicMetricRow({required this.visibleCount});

  final int visibleCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        ToolboxMetricCard(
          label: _lifeI18nText(context, 'toolbox.life.periodic.all_elements'),
          value: '118',
        ),
        ToolboxMetricCard(
          label: _lifeI18nText(
            context,
            'toolbox.life.periodic.filtered_elements',
            params: <String, Object?>{'count': visibleCount},
          ),
          value: '$visibleCount',
        ),
      ],
    );
  }
}

class _PeriodicTableStage extends StatelessWidget {
  const _PeriodicTableStage({
    required this.selected,
    required this.visibleElements,
    required this.detailed,
    required this.controller,
    required this.onSelected,
    required this.onReset,
    required this.onFullscreen,
    this.showFullscreen = true,
  });

  final _ElementFact selected;
  final List<_ElementFact> visibleElements;
  final bool detailed;
  final TransformationController controller;
  final ValueChanged<_ElementFact> onSelected;
  final VoidCallback onReset;
  final VoidCallback onFullscreen;
  final bool showFullscreen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey<String>('periodic-table-stage'),
      width: double.infinity,
      height: detailed ? 510 : 430,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.34,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          Expanded(
            child: detailed
                ? _DetailedPeriodicGrid(
                    selected: selected,
                    visibleElements: visibleElements,
                    controller: controller,
                    onSelected: onSelected,
                  )
                : _OverviewPeriodicGrid(
                    selected: selected,
                    visibleElements: visibleElements,
                    onSelected: onSelected,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                IconButton.filledTonal(
                  tooltip: _lifeI18nText(
                    context,
                    'toolbox.life.timeline.reset_view',
                  ),
                  onPressed: onReset,
                  icon: const Icon(Icons.center_focus_strong_rounded),
                ),
                if (showFullscreen) ...<Widget>[
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: _lifeI18nText(
                      context,
                      'toolbox.life.timeline.fullscreen',
                    ),
                    onPressed: onFullscreen,
                    icon: const Icon(Icons.fullscreen_rounded),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewPeriodicGrid extends StatelessWidget {
  const _OverviewPeriodicGrid({
    required this.selected,
    required this.visibleElements,
    required this.onSelected,
  });

  final _ElementFact selected;
  final List<_ElementFact> visibleElements;
  final ValueChanged<_ElementFact> onSelected;

  @override
  Widget build(BuildContext context) {
    final visibleIds = visibleElements
        .map((element) => element.atomicNumber)
        .toSet();
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 6.0;
        const gap = 2.0;
        final cellWidth =
            ((constraints.maxWidth - horizontalPadding * 2 - gap * 17) / 18)
                .clamp(14.0, 44.0)
                .toDouble();
        final cellHeight = (cellWidth * 1.62).clamp(31.0, 43.0).toDouble();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            horizontalPadding,
            10,
            horizontalPadding,
            0,
          ),
          child: _PeriodicGrid(
            cellWidth: cellWidth,
            cellHeight: cellHeight,
            gap: gap,
            compact: true,
            selected: selected,
            visibleIds: visibleIds,
            onSelected: onSelected,
          ),
        );
      },
    );
  }
}

class _DetailedPeriodicGrid extends StatelessWidget {
  const _DetailedPeriodicGrid({
    required this.selected,
    required this.visibleElements,
    required this.controller,
    required this.onSelected,
  });

  final _ElementFact selected;
  final List<_ElementFact> visibleElements;
  final TransformationController controller;
  final ValueChanged<_ElementFact> onSelected;

  @override
  Widget build(BuildContext context) {
    final visibleIds = visibleElements
        .map((element) => element.atomicNumber)
        .toSet();
    const cellWidth = 62.0;
    const cellHeight = 66.0;
    const gap = 4.0;
    const gridWidth = cellWidth * 18 + gap * 17;
    const gridHeight = cellHeight * 9 + gap * 8;
    return InteractiveViewer(
      transformationController: controller,
      constrained: false,
      minScale: 0.62,
      maxScale: 3.2,
      boundaryMargin: const EdgeInsets.all(180),
      child: SizedBox(
        width: gridWidth,
        height: gridHeight,
        child: _PeriodicGrid(
          cellWidth: cellWidth,
          cellHeight: cellHeight,
          gap: gap,
          compact: false,
          selected: selected,
          visibleIds: visibleIds,
          onSelected: onSelected,
        ),
      ),
    );
  }
}

class _PeriodicGrid extends StatelessWidget {
  const _PeriodicGrid({
    required this.cellWidth,
    required this.cellHeight,
    required this.gap,
    required this.compact,
    required this.selected,
    required this.visibleIds,
    required this.onSelected,
  });

  final double cellWidth;
  final double cellHeight;
  final double gap;
  final bool compact;
  final _ElementFact selected;
  final Set<int> visibleIds;
  final ValueChanged<_ElementFact> onSelected;

  @override
  Widget build(BuildContext context) {
    final elementsByPosition = <int, _ElementFact>{};
    for (final element in _elementFacts) {
      final index = (element.displayRow - 1) * 18 + element.displayColumn - 1;
      elementsByPosition[index] = element;
    }
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      primary: false,
      itemCount: 18 * 9,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 18,
        mainAxisExtent: cellHeight,
        crossAxisSpacing: gap,
        mainAxisSpacing: gap,
      ),
      itemBuilder: (context, index) {
        final element = elementsByPosition[index];
        return SizedBox(
          width: cellWidth,
          height: cellHeight,
          child: _ElementTile(
            element: element,
            compact: compact,
            muted:
                element != null && !visibleIds.contains(element.atomicNumber),
            selected: element?.atomicNumber == selected.atomicNumber,
            onTap: element == null ? null : () => onSelected(element),
          ),
        );
      },
    );
  }
}

class _ElementTile extends StatelessWidget {
  const _ElementTile({
    required this.element,
    required this.compact,
    required this.muted,
    required this.selected,
    required this.onTap,
  });

  final _ElementFact? element;
  final bool compact;
  final bool muted;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fact = element;
    if (fact == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(compact ? 4 : 8),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.24),
          ),
        ),
      );
    }
    final blockColor = _elementBlockColor(fact.groupBlock);
    final name = _lifeI18nText(context, fact.nameKey);
    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(compact ? 2 : 5),
      decoration: BoxDecoration(
        color: Color.lerp(
          theme.colorScheme.surface,
          blockColor,
          selected ? 0.28 : 0.13,
        ),
        borderRadius: BorderRadius.circular(compact ? 4 : 9),
        border: Border.all(
          color: selected ? blockColor : blockColor.withValues(alpha: 0.48),
          width: selected ? (compact ? 1.5 : 2) : 1,
        ),
        boxShadow: <BoxShadow>[
          if (selected)
            BoxShadow(
              color: blockColor.withValues(alpha: 0.28),
              blurRadius: compact ? 5 : 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${fact.atomicNumber}',
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: compact ? 6.5 : null,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  fact.symbol,
                  style:
                      (compact
                              ? theme.textTheme.labelLarge
                              : theme.textTheme.titleLarge)
                          ?.copyWith(
                            fontSize: compact ? 11 : null,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                ),
              ),
            ),
          ),
          if (!compact)
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                height: 1,
              ),
            ),
        ],
      ),
    );
    return Opacity(
      opacity: muted ? 0.28 : 1,
      child: Tooltip(
        message: '$name · ${fact.symbol} · ${fact.atomicNumber}',
        waitDuration: const Duration(milliseconds: 350),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(compact ? 4 : 9),
            onTap: onTap,
            child: tile,
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
      title: '${element.symbol} · ${_lifeI18nText(context, element.nameKey)}',
      subtitle: _lifeI18nText(
        context,
        'toolbox.life.periodic.period_group',
        params: <String, Object?>{
          'period': element.period,
          'group': element.group,
        },
      ),
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _TimelinePeriodicPill(
              color: color,
              label: _lifeI18nText(context, element.groupBlockKey),
            ),
            _TimelinePeriodicPill(
              color: Theme.of(context).colorScheme.secondary,
              label: _elementStateLabel(context, element),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ElementInfoRow(
          label: _lifeI18nText(context, 'toolbox.life.periodic.atomic_number'),
          value: '${element.atomicNumber}',
        ),
        _ElementInfoRow(
          label: _lifeI18nText(context, 'toolbox.life.periodic.atomic_mass'),
          value: _elementValue(context, element.atomicMass),
        ),
        _ElementInfoRow(
          label: _lifeI18nText(context, 'toolbox.life.periodic.state'),
          value: _elementValue(
            context,
            element.standardState,
            fallback: _elementStateLabel(context, element),
          ),
        ),
        _ElementInfoRow(
          label: _lifeI18nText(context, 'toolbox.life.periodic.discovery'),
          value: _elementValue(context, element.yearDiscovered),
        ),
        _ElementInfoRow(
          label: _lifeI18nText(context, 'toolbox.life.periodic.configuration'),
          value: _elementValue(context, element.electronConfiguration),
        ),
        _ElementInfoRow(
          label: _lifeI18nText(
            context,
            'toolbox.life.periodic.electronegativity',
          ),
          value: _elementValue(
            context,
            element.electronegativity,
            notApplicable: element.groupBlock == 'Noble gas',
          ),
        ),
        _ElementInfoRow(
          label: _lifeI18nText(context, 'toolbox.life.periodic.atomic_radius'),
          value: _elementValueWithUnit(
            context,
            element.atomicRadius,
            'toolbox.life.periodic.units.pm',
          ),
        ),
        _ElementInfoRow(
          label: _lifeI18nText(
            context,
            'toolbox.life.periodic.ionization_energy',
          ),
          value: _elementValueWithUnit(
            context,
            element.ionizationEnergy,
            'toolbox.life.periodic.units.ev',
          ),
        ),
        _ElementInfoRow(
          label: _lifeI18nText(
            context,
            'toolbox.life.periodic.electron_affinity',
          ),
          value: _elementValueWithUnit(
            context,
            element.electronAffinity,
            'toolbox.life.periodic.units.ev',
          ),
        ),
        _ElementInfoRow(
          label: _lifeI18nText(
            context,
            'toolbox.life.periodic.oxidation_states',
          ),
          value: _elementValue(context, element.oxidationStates),
        ),
        _ElementInfoRow(
          label: _lifeI18nText(context, 'toolbox.life.periodic.melting_point'),
          value: _elementValueWithUnit(
            context,
            element.meltingPoint,
            'toolbox.life.periodic.units.kelvin',
          ),
        ),
        _ElementInfoRow(
          label: _lifeI18nText(context, 'toolbox.life.periodic.boiling_point'),
          value: _elementValueWithUnit(
            context,
            element.boilingPoint,
            'toolbox.life.periodic.units.kelvin',
          ),
        ),
        _ElementInfoRow(
          label: _lifeI18nText(context, 'toolbox.life.periodic.density'),
          value: _elementValueWithUnit(
            context,
            element.density,
            'toolbox.life.periodic.units.g_cm3',
          ),
        ),
      ],
    );
  }
}

String _elementValue(
  BuildContext context,
  String raw, {
  String? fallback,
  bool notApplicable = false,
}) {
  final value = raw.trim();
  if (value.isNotEmpty) return value;
  if (fallback != null && fallback.trim().isNotEmpty) return fallback;
  return _lifeI18nText(
    context,
    notApplicable
        ? 'toolbox.life.periodic.not_applicable'
        : 'toolbox.life.periodic.unavailable',
  );
}

String _elementValueWithUnit(BuildContext context, String raw, String unitKey) {
  final value = _elementValue(context, raw);
  final unavailable = _lifeI18nText(
    context,
    'toolbox.life.periodic.unavailable',
  );
  if (value == unavailable) return value;
  return '$value ${_lifeI18nText(context, unitKey)}';
}

class _ElementInfoRow extends StatelessWidget {
  const _ElementInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 420;
        final content = narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  SelectableText(value),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 132,
                    child: Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(child: SelectableText(value)),
                ],
              );
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.55,
                  ),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: content,
            ),
          ),
        );
      },
    );
  }
}

class _ElementLegend extends StatelessWidget {
  const _ElementLegend();

  @override
  Widget build(BuildContext context) {
    final blocks = <String, String>{};
    for (final element in _elementFacts) {
      blocks[element.groupBlock] = element.groupBlockKey;
    }
    final entries = blocks.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final entry in entries)
          _TimelinePeriodicPill(
            color: _elementBlockColor(entry.key),
            label: _lifeI18nText(context, entry.value),
          ),
      ],
    );
  }
}

class _PeriodicFullscreenPage extends StatefulWidget {
  const _PeriodicFullscreenPage({
    required this.selected,
    required this.visibleElements,
  });

  final _ElementFact selected;
  final List<_ElementFact> visibleElements;

  @override
  State<_PeriodicFullscreenPage> createState() =>
      _PeriodicFullscreenPageState();
}

class _PeriodicFullscreenPageState extends State<_PeriodicFullscreenPage> {
  late _ElementFact _selected;
  late final List<_ElementFact> _visibleElements;
  final TransformationController _controller = TransformationController();

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
    _visibleElements = widget.visibleElements;
    unawaited(
      _enterLifeImmersive(orientations: _lifeAllOrientations, brightness: 0.92),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    unawaited(_exitLifeImmersive());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(useMaterial3: true),
      child: Scaffold(
        key: const ValueKey<String>('periodic-fullscreen-page'),
        backgroundColor: Colors.black,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _lifeI18nText(
                          context,
                          'toolbox.life.periodic.overview_title',
                        ),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton.filledTonal(
                      key: const ValueKey<String>('periodic-fullscreen-close'),
                      tooltip: _lifeI18nText(
                        context,
                        'toolbox.life.timeline.reset_view',
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_fullscreen_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _PeriodicTableStage(
                  selected: _selected,
                  visibleElements: _visibleElements,
                  detailed: true,
                  controller: _controller,
                  onSelected: (element) => setState(() => _selected = element),
                  onReset: () => _controller.value = Matrix4.identity(),
                  onFullscreen: () {},
                  showFullscreen: false,
                ),
                const SizedBox(height: 12),
                _ElementFactCard(element: _selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _elementStateKey(_ElementFact element) {
  final state = element.standardState.toLowerCase();
  if (state.contains('expected')) return 'expected';
  if (state.contains('liquid')) return 'liquid';
  if (state.contains('gas')) return 'gas';
  return 'solid';
}

String _elementStateLabel(BuildContext context, _ElementFact element) {
  return switch (_elementStateKey(element)) {
    'liquid' => _lifeI18nText(
      context,
      'inline.plan295.life.liquid.faca6f8190f7',
    ),
    'gas' => _lifeI18nText(context, 'inline.plan295.life.gas.26a1b9794e2a'),
    'expected' => _lifeI18nText(
      context,
      'inline.plan295.life.expected_state.68e191e25b5b',
    ),
    _ => _lifeI18nText(context, 'inline.plan295.life.solid.edf5c04808b9'),
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

part of '../toolbox_life_tools.dart';

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

String _timelineFactKey(_TimelineFact fact) => '${fact.collection}:${fact.id}';

class _TimelineMetricRow extends StatelessWidget {
  const _TimelineMetricRow({
    required this.eventCount,
    required this.rangeLabel,
  });

  final int eventCount;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        ToolboxMetricCard(
          label: _lifeI18nText(
            context,
            'toolbox.life.timeline.results',
            params: <String, Object?>{'count': eventCount},
          ),
          value: '$eventCount',
        ),
        ToolboxMetricCard(
          label: _lifeI18nText(
            context,
            'toolbox.life.timeline.collection.label',
          ),
          value: rangeLabel,
        ),
      ],
    );
  }
}

class _TimelineEmptyState extends StatelessWidget {
  const _TimelineEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.manage_search_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _lifeI18nText(context, 'toolbox.life.timeline.no_results'),
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
    required this.onSelected,
    this.immersive = false,
  });

  final List<_TimelineFact> facts;
  final _TimelineFact selected;
  final ValueChanged<_TimelineFact> onSelected;
  final bool immersive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedFact =
        facts.any(
          (fact) => _timelineFactKey(fact) == _timelineFactKey(selected),
        )
        ? selected
        : facts.first;
    return Container(
      key: const ValueKey<String>('history-timeline-stage'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: immersive
            ? Colors.white.withValues(alpha: 0.05)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(20),
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
            selected: selectedFact,
            eventCount: facts.length,
            immersive: immersive,
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: immersive ? 300 : 260,
              maxHeight: immersive ? 560 : 620,
            ),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
              primary: false,
              itemCount: facts.length,
              itemBuilder: (context, index) {
                final fact = facts[index];
                return _TimelineStoryTile(
                  fact: fact,
                  selected:
                      _timelineFactKey(fact) == _timelineFactKey(selectedFact),
                  isFirst: index == 0,
                  isLast: index == facts.length - 1,
                  immersive: immersive,
                  onTap: () => onSelected(fact),
                );
              },
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
    required this.eventCount,
    required this.immersive,
  });

  final _TimelineFact selected;
  final int eventCount;
  final bool immersive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _timelineCategoryColor(selected.category);
    final hasImage = selected.imageAsset != null;
    return Container(
      constraints: BoxConstraints(minHeight: hasImage ? 170 : 150),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: immersive
            ? Colors.black.withValues(alpha: 0.22)
            : Color.lerp(theme.colorScheme.surfaceContainerHigh, color, 0.08),
        border: Border(
          bottom: BorderSide(
            color: immersive
                ? Colors.white.withValues(alpha: 0.16)
                : theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Stack(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: hasImage ? 116 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    _TimelinePeriodicPill(
                      color: color,
                      label: _timelineCategoryLabel(context, selected.category),
                    ),
                    _TimelinePeriodicPill(
                      color: theme.colorScheme.primary,
                      label: _lifeI18nText(
                        context,
                        'toolbox.life.timeline.results',
                        params: <String, Object?>{'count': eventCount},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _lifeI18nText(context, selected.displayKey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _lifeI18nText(context, selected.titleKey),
                  maxLines: immersive ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (immersive
                              ? theme.textTheme.headlineSmall
                              : theme.textTheme.titleLarge)
                          ?.copyWith(fontWeight: FontWeight.w900, height: 1.08),
                ),
              ],
            ),
          ),
          if (hasImage)
            Positioned(
              top: 0,
              right: 0,
              width: 100,
              height: 116,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  selected.imageAsset!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _TimelineFactImageError(immersive: immersive),
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
        ? Colors.white.withValues(alpha: selected ? 0.13 : 0.06)
        : Color.lerp(theme.colorScheme.surface, color, selected ? 0.12 : 0.035);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 14,
            top: isFirst ? 18 : 0,
            bottom: isLast ? 22 : 0,
            child: Container(
              width: 2,
              color: immersive
                  ? Colors.white.withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.28),
            ),
          ),
          Positioned(
            left: 7,
            top: 12,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 16 : 14,
              height: selected ? 16 : 14,
              decoration: BoxDecoration(
                color: selected ? color : theme.colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: selected ? 3 : 2),
                boxShadow: <BoxShadow>[
                  if (selected)
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? color
                          : immersive
                          ? Colors.white.withValues(alpha: 0.14)
                          : theme.colorScheme.outlineVariant,
                      width: selected ? 1.8 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 8,
                        runSpacing: 5,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text(
                            _lifeI18nText(context, fact.displayKey),
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
                      const SizedBox(height: 7),
                      Text(
                        _lifeI18nText(context, fact.titleKey),
                        maxLines: selected ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                          color: immersive ? Colors.white : null,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _lifeI18nText(context, fact.detailKey),
                        maxLines: selected ? 4 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.28,
                          color: immersive
                              ? Colors.white.withValues(alpha: 0.78)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (selected && fact.imageAsset != null) ...<Widget>[
                        const SizedBox(height: 10),
                        _TimelineFactImagePreview(
                          fact: fact,
                          immersive: immersive,
                        ),
                      ],
                    ],
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

class _TimelineFactImagePreview extends StatelessWidget {
  const _TimelineFactImagePreview({
    required this.fact,
    required this.immersive,
  });

  final _TimelineFact fact;
  final bool immersive;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 8,
        child: Image.asset(
          fact.imageAsset!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _TimelineFactImageError(immersive: immersive),
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
      title: _lifeI18nText(context, fact.titleKey),
      subtitle:
          '${_lifeI18nText(context, fact.displayKey)} · ${_timelineCategoryLabel(context, fact.category)}',
      children: <Widget>[
        Text(_lifeI18nText(context, fact.detailKey)),
        if (fact.imageAsset != null) ...<Widget>[
          const SizedBox(height: 14),
          _TimelineFactImageBlock(fact: fact),
        ],
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
            if (fact.sourceUrl.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => _openExternal(context, fact.sourceUrl),
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(_lifeI18nText(context, fact.sourceNameKey)),
              ),
          ],
        ),
      ],
    );
  }
}

class _TimelineFactImageBlock extends StatelessWidget {
  const _TimelineFactImageBlock({required this.fact});

  final _TimelineFact fact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(
              fact.imageAsset!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const _TimelineFactImageError(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Icon(
              Icons.photo_library_outlined,
              size: 17,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            Text(
              _lifeI18nText(context, 'toolbox.life.timeline.image.attribution'),
              style: theme.textTheme.bodySmall,
            ),
            Text(
              _lifeI18nText(context, 'toolbox.life.timeline.source.met'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton.icon(
              onPressed: () => _openExternal(
                context,
                'https://www.metmuseum.org/hubs/open-access',
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(
                _lifeI18nText(
                  context,
                  'toolbox.life.timeline.image.open_source',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimelineFactImageError extends StatelessWidget {
  const _TimelineFactImageError({this.immersive = false});

  final bool immersive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: immersive
          ? Colors.white.withValues(alpha: 0.08)
          : theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.broken_image_outlined,
            color: immersive
                ? Colors.white.withValues(alpha: 0.72)
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 6),
          Text(
            _lifeI18nText(context, 'toolbox.life.timeline.image.unavailable'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: immersive ? Colors.white.withValues(alpha: 0.72) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineSourcesPanel extends StatelessWidget {
  const _TimelineSourcesPanel({required this.sources});

  final List<_LifeToolSource> sources;

  @override
  Widget build(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.life.timeline.sources'),
      subtitle: _lifeI18nText(context, 'toolbox.life.timeline.source_note'),
      children: <Widget>[
        for (var index = 0; index < sources.length; index += 1) ...<Widget>[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new_rounded),
              onPressed: sources[index].url.isEmpty
                  ? null
                  : () => _openExternal(context, sources[index].url),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  sources[index].name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          if (index != sources.length - 1) const SizedBox(height: 8),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelMedium?.copyWith(
          color: Color.lerp(theme.colorScheme.onSurface, color, 0.64),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

const List<String> _timelineLanes = <String>[
  'cosmic',
  'earth',
  'human',
  'civilization',
  'science',
  'modern',
];

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
  final valueLog = math.log(
    yearsBeforePresent.clamp(
          window.minYearsBeforePresent,
          window.maxYearsBeforePresent,
        ) +
        1,
  );
  final denominator = maxLog - minLog;
  if (denominator <= 0) return width;
  return ((maxLog - valueLog) / denominator).clamp(0.0, 1.0) * width;
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

String _timelineRangeLabel(BuildContext context, String range) {
  return switch (range) {
    'earth' => _lifeI18nText(context, 'inline.plan295.life.earth.6df570a637a2'),
    'human' => _lifeI18nText(context, 'inline.plan295.life.human.a1b92326ad0f'),
    'civilization' => _lifeI18nText(
      context,
      'inline.plan295.life.civilization.45ac9d02e075',
    ),
    'modern' => _lifeI18nText(
      context,
      'inline.plan295.life.modern.0eb29c68f83b',
    ),
    _ => _lifeI18nText(context, 'inline.plan295.life.all.9a806456c3db'),
  };
}

String _timelineCategoryLabel(BuildContext context, String category) {
  return switch (category) {
    'cosmic' => _lifeI18nText(
      context,
      'inline.plan295.life.cosmic.9faf20d9169e',
    ),
    'earth' => _lifeI18nText(context, 'inline.plan295.life.earth.e77b1debf5ac'),
    'human' => _lifeI18nText(context, 'inline.plan295.life.human.7ac93bc8501f'),
    'civilization' => _lifeI18nText(
      context,
      'inline.plan295.life.civilization.b553343bf1f6',
    ),
    'science' => _lifeI18nText(context, 'ref.toolbox.sleep.assist.scienceCard'),
    'modern' => _lifeI18nText(
      context,
      'inline.plan295.life.modern.0eb29c68f83b',
    ),
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
  if (value <= 0) return '0';
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

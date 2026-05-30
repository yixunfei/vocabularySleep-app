part of '../toolbox_life_tools.dart';

class _WorldClockToolPage extends StatefulWidget {
  const _WorldClockToolPage();

  @override
  State<_WorldClockToolPage> createState() => _WorldClockToolPageState();
}

class _WorldClockToolPageState extends State<_WorldClockToolPage> {
  final ToolboxWorldClockService _service = const ToolboxWorldClockService();
  final TextEditingController _queryController = TextEditingController();
  late Set<String> _pinnedCityIds;
  late DateTime _utcNow;
  Timer? _timer;
  bool _businessHoursOnly = false;
  String _region = 'all';

  @override
  void initState() {
    super.initState();
    _utcNow = DateTime.now().toUtc();
    _pinnedCityIds = _service
        .defaultPinnedCities()
        .map((city) => city.id)
        .toSet();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _utcNow = DateTime.now().toUtc());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  String get _query => _queryController.text.trim();

  List<ToolboxWorldClockCity> get _filteredCities {
    final cities = _service.searchCities(
      _query,
      utcNow: _utcNow,
      businessHoursOnly: _businessHoursOnly,
    );
    if (_region == 'all') {
      return cities;
    }
    return cities
        .where((city) => city.regionEn == _region)
        .toList(growable: false);
  }

  List<ToolboxWorldClockSnapshot> get _pinnedSnapshots {
    return _pinnedCityIds
        .map(
          (id) =>
              _service.snapshotForCity(_service.cityById(id), utcNow: _utcNow),
        )
        .toList(growable: false)
      ..sort((a, b) => a.localTime.compareTo(b.localTime));
  }

  List<String> get _regions {
    final values =
        ToolboxWorldClockService.cities
            .map((city) => city.regionEn)
            .toSet()
            .toList()
          ..sort();
    return <String>['all', ...values];
  }

  @override
  Widget build(BuildContext context) {
    final filteredSnapshots = _filteredCities
        .map((city) => _service.snapshotForCity(city, utcNow: _utcNow))
        .toList(growable: false);
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.world_clock.8c72a17e8d79',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.check_current_time_local_difference.e2f74ff27472',
      ),
      child: Column(
        key: const ValueKey<String>('life-world-clock-page'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _WorldClockHero(
            utcNow: _utcNow,
            pinnedCount: _pinnedCityIds.length,
            businessOpenCount: filteredSnapshots
                .where((snapshot) => snapshot.isBusinessHours)
                .length,
          ),
          const SizedBox(height: 14),
          _filtersPanel(context),
          const SizedBox(height: 12),
          _PinnedWorldClocksPanel(
            snapshots: _pinnedSnapshots,
            onUnpin: (id) => setState(() => _pinnedCityIds.remove(id)),
          ),
          const SizedBox(height: 12),
          _WorldClockResultsPanel(
            snapshots: filteredSnapshots,
            pinnedCityIds: _pinnedCityIds,
            onTogglePinned: _togglePinned,
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeI18nText(
              context,
              'inline.plan295.life.boundary.b72c98dd2a1f',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.life.uses_built_in_common_cities_and_basi.ca8812c434a2',
            ),
            children: <Widget>[
              Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.no_network_request_or_location_uploa.1dec2ab0339c',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filtersPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.find_a_city.6dda086b6207',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.search_by_city_country_airport_hint.fcad6fc705e1',
      ),
      children: <Widget>[
        TextField(
          key: const ValueKey<String>('life-world-clock-search'),
          controller: _queryController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: _lifeI18nText(
                      context,
                      'inline.plan295.life.clear_search.afdf6389103c',
                    ),
                    onPressed: () {
                      _queryController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
            labelText: _lifeI18nText(
              context,
              'inline.plan295.life.city_or_country.b004d6e3e852',
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilterChip(
              key: const ValueKey<String>('life-world-clock-business-filter'),
              selected: _businessHoursOnly,
              avatar: const Icon(Icons.work_outline_rounded, size: 18),
              label: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.business_hours_now.916721469825',
                ),
              ),
              onSelected: (value) => setState(() => _businessHoursOnly = value),
            ),
            for (final region in _regions)
              ChoiceChip(
                selected: _region == region,
                label: Text(_regionLabel(context, region)),
                onSelected: (_) => setState(() => _region = region),
              ),
          ],
        ),
      ],
    );
  }

  String _regionLabel(BuildContext context, String region) {
    if (region == 'all') {
      return _lifeI18nText(
        context,
        'inline.plan295.life.all_regions.c95eb6e0156f',
      );
    }
    final match = ToolboxWorldClockService.cities.firstWhere(
      (city) => city.regionEn == region,
      orElse: () => ToolboxWorldClockService.cities.first,
    );
    return match.regionLabel(Localizations.localeOf(context).languageCode);
  }

  void _togglePinned(String id) {
    setState(() {
      if (_pinnedCityIds.contains(id)) {
        if (_pinnedCityIds.length > 1) {
          _pinnedCityIds.remove(id);
        }
        return;
      }
      _pinnedCityIds.add(id);
    });
  }
}

class _WorldClockHero extends StatelessWidget {
  const _WorldClockHero({
    required this.utcNow,
    required this.pinnedCount,
    required this.businessOpenCount,
  });

  final DateTime utcNow;
  final int pinnedCount;
  final int businessOpenCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localNow = DateTime.now();
    final localOffset = DateTime.now().timeZoneOffset.inMinutes;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF123447), Color(0xFF2F604F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF123447).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.public_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _lifeI18nText(
                        context,
                        'inline.plan295.life.local_time.a53e57e80438',
                      ),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ToolboxWorldClockService.formatDate(localNow),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                ToolboxWorldClockService.formatOffset(localOffset),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            ToolboxWorldClockService.formatTime(localNow),
            style: theme.textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_lifeI18nText(context, 'inline.plan295.life.utc_time.282387cfabc7')} ${ToolboxWorldClockService.formatTime(utcNow)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _WorldClockHeroPill(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.pinned.ca214f5a2ecd',
                ),
                value: '$pinnedCount',
              ),
              _WorldClockHeroPill(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.open_now.1fdbe663a06b',
                ),
                value: '$businessOpenCount',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorldClockHeroPill extends StatelessWidget {
  const _WorldClockHeroPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedWorldClocksPanel extends StatelessWidget {
  const _PinnedWorldClocksPanel({
    required this.snapshots,
    required this.onUnpin,
  });

  final List<ToolboxWorldClockSnapshot> snapshots;
  final ValueChanged<String> onUnpin;

  @override
  Widget build(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.pinned_clocks.27501daa7cac',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.sorted_by_local_time_for_quick_day_s.ef82ef26c931',
      ),
      children: <Widget>[
        for (final snapshot in snapshots) ...<Widget>[
          _WorldClockCityTile(
            snapshot: snapshot,
            pinned: true,
            compact: true,
            onTogglePinned: () => onUnpin(snapshot.city.id),
          ),
          if (snapshot != snapshots.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _WorldClockResultsPanel extends StatelessWidget {
  const _WorldClockResultsPanel({
    required this.snapshots,
    required this.pinnedCityIds,
    required this.onTogglePinned,
  });

  final List<ToolboxWorldClockSnapshot> snapshots;
  final Set<String> pinnedCityIds;
  final ValueChanged<String> onTogglePinned;

  @override
  Widget build(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.city_list.f7a5ef854f96',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.world.clock.cities_match_the_current_filters.fe05b6b405',
        params: <String, Object?>{'length': snapshots.length},
      ),
      children: <Widget>[
        if (snapshots.isEmpty)
          Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.no_matching_city_try_clearing_search.cac93f829feb',
            ),
          )
        else
          for (final snapshot in snapshots) ...<Widget>[
            _WorldClockCityTile(
              snapshot: snapshot,
              pinned: pinnedCityIds.contains(snapshot.city.id),
              onTogglePinned: () => onTogglePinned(snapshot.city.id),
            ),
            if (snapshot != snapshots.last) const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _WorldClockCityTile extends StatelessWidget {
  const _WorldClockCityTile({
    required this.snapshot,
    required this.pinned,
    required this.onTogglePinned,
    this.compact = false,
  });

  final ToolboxWorldClockSnapshot snapshot;
  final bool pinned;
  final VoidCallback onTogglePinned;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final statusColor = _periodColor(snapshot.period);
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: compact ? 0.46 : 0.58,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: snapshot.isBusinessHours
              ? statusColor.withValues(alpha: 0.62)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        snapshot.city.cityLabel(locale),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _WorldClockStatusPill(
                      label: _periodLabel(context, snapshot.period),
                      color: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${snapshot.city.countryLabel(locale)} · ${snapshot.city.regionLabel(locale)} · ${snapshot.offsetLabel}${snapshot.isDst ? ' DST' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
                if (!compact) ...<Widget>[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _WorldClockInfoChip(
                        label: _lifeI18nText(
                          context,
                          'inline.plan295.life.local_diff.5b989005a681',
                        ),
                        value: _differenceLabel(context, snapshot),
                      ),
                      _WorldClockInfoChip(
                        label: _lifeI18nText(
                          context,
                          'inline.plan295.life.date.34223a7b8531',
                        ),
                        value: _dayShiftLabel(context, snapshot.dayShift),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                ToolboxWorldClockService.formatTime(snapshot.localTime),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (!compact)
                Text(
                  ToolboxWorldClockService.formatDate(snapshot.localTime),
                  style: theme.textTheme.bodySmall,
                ),
              IconButton(
                tooltip: pinned
                    ? _lifeI18nText(
                        context,
                        'inline.plan295.life.unpin.dcc8cc39eb3e',
                      )
                    : _lifeI18nText(
                        context,
                        'inline.plan295.life.pin_city.3d808c7f483f',
                      ),
                onPressed: onTogglePinned,
                icon: Icon(
                  pinned ? Icons.star_rounded : Icons.star_border_rounded,
                  color: pinned ? const Color(0xFFE2A94B) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _periodColor(ToolboxWorldClockPeriod period) {
    return switch (period) {
      ToolboxWorldClockPeriod.businessHours => const Color(0xFF3F9E72),
      ToolboxWorldClockPeriod.earlyMorning => const Color(0xFF6A96D8),
      ToolboxWorldClockPeriod.evening => const Color(0xFFC98A3D),
      ToolboxWorldClockPeriod.night => const Color(0xFF6E6D9A),
      ToolboxWorldClockPeriod.weekend => const Color(0xFF8D77C8),
    };
  }

  static String _periodLabel(
    BuildContext context,
    ToolboxWorldClockPeriod period,
  ) {
    return switch (period) {
      ToolboxWorldClockPeriod.businessHours => _lifeI18nText(
        context,
        'inline.plan295.life.business.b6ddd7c93b0c',
      ),
      ToolboxWorldClockPeriod.earlyMorning => _lifeI18nText(
        context,
        'inline.plan295.life.morning.070973083b20',
      ),
      ToolboxWorldClockPeriod.evening => _lifeI18nText(
        context,
        'inline.plan295.life.evening.c0c0733d1477',
      ),
      ToolboxWorldClockPeriod.night => _lifeI18nText(
        context,
        'inline.plan295.life.night.53265923b309',
      ),
      ToolboxWorldClockPeriod.weekend => _lifeI18nText(
        context,
        'inline.plan295.life.weekend.5197393b58df',
      ),
    };
  }

  static String _differenceLabel(
    BuildContext context,
    ToolboxWorldClockSnapshot snapshot,
  ) {
    final minutes = snapshot.differenceFromDeviceMinutes;
    if (minutes == 0) {
      return _lifeI18nText(
        context,
        'inline.plan295.life.same_zone.6343714c8b95',
      );
    }
    final sign = minutes > 0 ? '+' : '-';
    final absMinutes = minutes.abs();
    final hours = absMinutes ~/ 60;
    final mins = absMinutes % 60;
    final minutePart = mins == 0 ? '' : ' ${mins}m';
    return '$sign${hours}h$minutePart';
  }

  static String _dayShiftLabel(BuildContext context, int dayShift) {
    if (dayShift == 0) {
      return _lifeI18nText(context, 'inline.ui.app_shell.today_23dc4e');
    }
    if (dayShift == 1) {
      return _lifeI18nText(context, 'inline.ui.app_shell.tomorrow_08dc97');
    }
    if (dayShift == -1) {
      return _lifeI18nText(
        context,
        'inline.plan295.life.yesterday.fc45d33ddec9',
      );
    }
    return dayShift > 0
        ? _lifeI18nText(
            context,
            'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.world.clock.days.a1d8e337fe',
            params: <String, Object?>{'dayShift': dayShift},
          )
        : _lifeI18nText(
            context,
            'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.world.clock.days.f9d76126a1',
            params: <String, Object?>{'dayShift': dayShift},
          );
  }
}

class _WorldClockStatusPill extends StatelessWidget {
  const _WorldClockStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WorldClockInfoChip extends StatelessWidget {
  const _WorldClockInfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

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
      title: _lifeText(context, zh: '世界时钟', en: 'World clock'),
      subtitle: _lifeText(
        context,
        zh: '常用城市当前时间、本地时差、办公时段与昼夜状态速查。',
        en: 'Check current time, local difference, business hours, and day state across common cities.',
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
            title: _lifeText(context, zh: '使用边界', en: 'Boundary'),
            subtitle: _lifeText(
              context,
              zh: '内置常见城市与基础夏令时规则，适合当前时间速查；政策变化、历史时间和极端切换边界请以系统时区或权威时区库为准。',
              en: 'Uses built-in common cities and basic daylight-saving rules for current-time lookup; policy changes, historical dates, and edge transitions should be checked with system time zones or an authoritative timezone database.',
            ),
            children: <Widget>[
              Text(
                _lifeText(
                  context,
                  zh: '无需网络请求，不上传位置信息；本地时差按当前设备时区与城市 UTC 偏移计算。',
                  en: 'No network request or location upload; local difference is calculated from the current device timezone and each city UTC offset.',
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
      title: _lifeText(context, zh: '查找城市', en: 'Find a city'),
      subtitle: _lifeText(
        context,
        zh: '搜索城市、国家、机场缩写或按地区缩小范围。',
        en: 'Search by city, country, airport hint, or narrow by region.',
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
                    tooltip: _lifeText(context, zh: '清空搜索', en: 'Clear search'),
                    onPressed: () {
                      _queryController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
            labelText: _lifeText(context, zh: '城市或国家', en: 'City or country'),
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
                _lifeText(context, zh: '仅看办公时间', en: 'Business hours now'),
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
      return _lifeText(context, zh: '全部地区', en: 'All regions');
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
                      _lifeText(context, zh: '本地时间', en: 'Local time'),
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
            '${_lifeText(context, zh: 'UTC 时间', en: 'UTC time')} ${ToolboxWorldClockService.formatTime(utcNow)}',
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
                label: _lifeText(context, zh: '收藏城市', en: 'Pinned'),
                value: '$pinnedCount',
              ),
              _WorldClockHeroPill(
                label: _lifeText(context, zh: '办公中', en: 'Open now'),
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
      title: _lifeText(context, zh: '收藏时钟', en: 'Pinned clocks'),
      subtitle: _lifeText(
        context,
        zh: '按当地时间排序，适合快速判断今天/明天和是否还能联系。',
        en: 'Sorted by local time for quick day-shift and contact timing checks.',
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
      title: _lifeText(context, zh: '城市列表', en: 'City list'),
      subtitle: _lifeText(
        context,
        zh: '${snapshots.length} 个城市符合当前条件。',
        en: '${snapshots.length} cities match the current filters.',
      ),
      children: <Widget>[
        if (snapshots.isEmpty)
          Text(
            _lifeText(
              context,
              zh: '没有匹配城市，试试清空搜索或关闭办公时间筛选。',
              en: 'No matching city. Try clearing search or turning off the business-hours filter.',
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
                        label: _lifeText(context, zh: '本地时差', en: 'Local diff'),
                        value: _differenceLabel(context, snapshot),
                      ),
                      _WorldClockInfoChip(
                        label: _lifeText(context, zh: '日期', en: 'Date'),
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
                    ? _lifeText(context, zh: '取消收藏', en: 'Unpin')
                    : _lifeText(context, zh: '收藏城市', en: 'Pin city'),
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
      ToolboxWorldClockPeriod.businessHours => _lifeText(
        context,
        zh: '办公中',
        en: 'Business',
      ),
      ToolboxWorldClockPeriod.earlyMorning => _lifeText(
        context,
        zh: '清晨',
        en: 'Morning',
      ),
      ToolboxWorldClockPeriod.evening => _lifeText(
        context,
        zh: '夜间前',
        en: 'Evening',
      ),
      ToolboxWorldClockPeriod.night => _lifeText(
        context,
        zh: '夜间',
        en: 'Night',
      ),
      ToolboxWorldClockPeriod.weekend => _lifeText(
        context,
        zh: '周末',
        en: 'Weekend',
      ),
    };
  }

  static String _differenceLabel(
    BuildContext context,
    ToolboxWorldClockSnapshot snapshot,
  ) {
    final minutes = snapshot.differenceFromDeviceMinutes;
    if (minutes == 0) {
      return _lifeText(context, zh: '同一时区', en: 'Same zone');
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
      return _lifeText(context, zh: '今天', en: 'Today');
    }
    if (dayShift == 1) {
      return _lifeText(context, zh: '明天', en: 'Tomorrow');
    }
    if (dayShift == -1) {
      return _lifeText(context, zh: '昨天', en: 'Yesterday');
    }
    return dayShift > 0
        ? _lifeText(context, zh: '+$dayShift 天', en: '+$dayShift days')
        : _lifeText(context, zh: '$dayShift 天', en: '$dayShift days');
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

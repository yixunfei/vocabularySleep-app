part of 'daily_choice_hub.dart';

class DailyChoicePlaceMapPanel extends StatefulWidget {
  const DailyChoicePlaceMapPanel({
    super.key,
    required this.i18n,
    required this.accent,
    required this.settings,
    required this.onSettingsChanged,
    required this.onSavePlace,
    required this.savedOptionIds,
    this.locationProvider = const DailyChoiceDeviceLocationProvider(),
    DailyChoiceOverpassClient? overpassClient,
  }) : _overpassClient = overpassClient;

  final AppI18n i18n;
  final Color accent;
  final DailyChoicePlaceMapSettings settings;
  final ValueChanged<DailyChoicePlaceMapSettings> onSettingsChanged;
  final Future<DailyChoiceOption> Function(DailyChoiceOsmPlace place)
  onSavePlace;
  final Set<String> savedOptionIds;
  final DailyChoiceLocationProvider locationProvider;
  final DailyChoiceOverpassClient? _overpassClient;

  @override
  State<DailyChoicePlaceMapPanel> createState() =>
      _DailyChoicePlaceMapPanelState();
}

class _DailyChoicePlaceMapPanelState extends State<DailyChoicePlaceMapPanel> {
  static const List<int> _radiusChoices = <int>[500, 1000, 1500, 3000, 5000];

  late final DailyChoiceOverpassClient _overpassClient =
      widget._overpassClient ?? DailyChoiceOverpassClient();
  late final bool _ownsOverpassClient = widget._overpassClient == null;

  bool _expanded = false;
  bool _loading = false;
  String? _errorMessage;
  DailyChoiceGeoPoint? _queryCenter;
  bool _lastQueryUsedApproximateLocation = true;
  List<DailyChoiceOsmPlace> _places = const <DailyChoiceOsmPlace>[];
  final Set<String> _savingIds = <String>{};
  final Set<String> _locallySavedIds = <String>{};

  @override
  void dispose() {
    if (_ownsOverpassClient) {
      _overpassClient.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = widget.settings;
    final hasConsent = settings.consentGranted;
    final savedIds = <String>{...widget.savedOptionIds, ..._locallySavedIds};
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(16),
      radius: ToolboxUiTokens.sectionPanelRadius,
      borderColor: widget.accent.withValues(alpha: 0.18),
      shadowColor: widget.accent,
      shadowOpacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: <Widget>[
                Icon(Icons.map_rounded, size: 18, color: widget.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pickUiText(
                      widget.i18n,
                      zh: hasConsent ? '周边地图已启用' : '周边地图（可选扩展）',
                      en: hasConsent
                          ? 'Nearby map enabled'
                          : 'Nearby map (optional)',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ToolboxInfoPill(
                  text: pickUiText(
                    widget.i18n,
                    zh: settings.useApproximateLocation ? '模糊位置' : '精确定位',
                    en: settings.useApproximateLocation
                        ? 'Approximate'
                        : 'Precise',
                  ),
                  accent: widget.accent,
                  backgroundColor: theme.colorScheme.surfaceContainerLow,
                ),
                const SizedBox(width: 6),
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          if (_expanded) ...<Widget>[
            const SizedBox(height: 12),
            if (!hasConsent)
              _PlaceMapConsentPrompt(
                i18n: widget.i18n,
                accent: widget.accent,
                onAccept: _acceptConsent,
              )
            else ...<Widget>[
              _PlaceMapPrivacyNotice(
                i18n: widget.i18n,
                accent: widget.accent,
                useApproximateLocation: settings.useApproximateLocation,
                onApproximateChanged: (value) => widget.onSettingsChanged(
                  settings.copyWith(useApproximateLocation: value),
                ),
              ),
              const SizedBox(height: 12),
              _PlaceMapRadiusSelector(
                i18n: widget.i18n,
                accent: widget.accent,
                radiusChoices: _radiusChoices,
                selectedRadius: settings.normalizedRadiusMeters,
                onSelected: (value) => widget.onSettingsChanged(
                  settings.copyWith(radiusMeters: value),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: _loading ? null : _queryNearbyPlaces,
                    icon: Icon(
                      _loading
                          ? Icons.hourglass_top_rounded
                          : Icons.near_me_rounded,
                    ),
                    label: Text(
                      pickUiText(
                        widget.i18n,
                        zh: _loading ? '正在获取周边...' : '获取周边场所',
                        en: _loading
                            ? 'Finding places...'
                            : 'Find nearby places',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _places.isEmpty && _queryCenter == null
                        ? null
                        : () => setState(() {
                            _places = const <DailyChoiceOsmPlace>[];
                            _queryCenter = null;
                            _errorMessage = null;
                          }),
                    icon: const Icon(Icons.cleaning_services_rounded),
                    label: Text(
                      pickUiText(widget.i18n, zh: '清空结果', en: 'Clear'),
                    ),
                  ),
                ],
              ),
              if (_loading) ...<Widget>[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  color: widget.accent,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(999),
                ),
              ],
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: 12),
                _PlaceMapInlineMessage(
                  icon: Icons.warning_amber_rounded,
                  color: theme.colorScheme.error,
                  text: _errorMessage!,
                ),
              ],
              if (_queryCenter != null) ...<Widget>[
                const SizedBox(height: 12),
                _PlaceMapPreview(
                  accent: widget.accent,
                  center: _queryCenter!,
                  places: _places,
                  radiusMeters: settings.normalizedRadiusMeters,
                  usedApproximateLocation: _lastQueryUsedApproximateLocation,
                ),
              ],
              const SizedBox(height: 12),
              _PlaceMapResultList(
                i18n: widget.i18n,
                accent: widget.accent,
                places: _places,
                savedIds: savedIds,
                savingIds: _savingIds,
                onSavePlace: _savePlace,
              ),
              const SizedBox(height: 10),
              Text(
                pickUiText(
                  widget.i18n,
                  zh: '地图与场所数据来自 OpenStreetMap/Overpass；本功能只按你的点击查询当前半径，不会批量下载地图瓦片。',
                  en: 'Map and place data come from OpenStreetMap/Overpass. This feature queries the current radius only when you tap; it does not bulk-download map tiles.',
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _acceptConsent() {
    widget.onSettingsChanged(
      widget.settings.copyWith(
        consentGranted: true,
        useApproximateLocation: true,
        radiusMeters: DailyChoicePlaceMapSettings.defaultRadiusMeters,
      ),
    );
  }

  Future<void> _queryNearbyPlaces() async {
    if (_loading) {
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final settings = widget.settings;
    final location = await widget.locationProvider.readCurrentLocation(
      useApproximateLocation: settings.useApproximateLocation,
    );
    if (!mounted) {
      return;
    }
    if (!location.hasPoint) {
      setState(() {
        _loading = false;
        _errorMessage = _locationErrorText(location);
      });
      return;
    }
    try {
      final places = await _overpassClient.fetchNearbyPlaces(
        center: location.point!,
        radiusMeters: settings.normalizedRadiusMeters,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _queryCenter = location.point;
        _lastQueryUsedApproximateLocation = location.usedApproximateLocation;
        _places = places;
        _loading = false;
        if (places.isEmpty) {
          _errorMessage = pickUiText(
            widget.i18n,
            zh: '当前半径内没有找到可用场所。可以扩大范围，或稍后再试。',
            en: 'No usable places were found in this radius. Try a larger range or come back later.',
          );
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = pickUiText(
          widget.i18n,
          zh: '周边场所查询失败。OpenStreetMap 公共服务可能繁忙，请稍后再试。',
          en: 'Nearby place lookup failed. The public OpenStreetMap service may be busy; try again later.',
        );
      });
    }
  }

  String _locationErrorText(DailyChoiceLocationReadResult result) {
    return switch (result.status) {
      DailyChoiceLocationReadStatus.serviceDisabled => pickUiText(
        widget.i18n,
        zh: '系统定位服务未开启。开启定位后再获取周边场所。',
        en: 'System location services are disabled. Enable location services and try again.',
      ),
      DailyChoiceLocationReadStatus.permissionDenied => pickUiText(
        widget.i18n,
        zh: '你尚未授予定位权限。授权后才能按当前位置查询周边场所。',
        en: 'Location permission was not granted. Grant it to search near your current position.',
      ),
      DailyChoiceLocationReadStatus.permissionDeniedForever => pickUiText(
        widget.i18n,
        zh: '定位权限已被系统设为拒绝。请到系统设置中为本 App 开启定位权限。',
        en: 'Location permission is blocked. Enable it for this app in system settings.',
      ),
      DailyChoiceLocationReadStatus.failed => pickUiText(
        widget.i18n,
        zh: '读取定位失败：${result.message ?? ''}',
        en: 'Could not read location: ${result.message ?? ''}',
      ),
      DailyChoiceLocationReadStatus.ready => '',
    };
  }

  Future<void> _savePlace(DailyChoiceOsmPlace place) async {
    if (_savingIds.contains(place.id)) {
      return;
    }
    setState(() {
      _savingIds.add(place.id);
      _errorMessage = null;
    });
    try {
      final saved = await widget.onSavePlace(place);
      if (!mounted) {
        return;
      }
      setState(() {
        _locallySavedIds.add(saved.id);
        _savingIds.remove(place.id);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _savingIds.remove(place.id);
        _errorMessage = pickUiText(
          widget.i18n,
          zh: '保存场所失败，请稍后再试。',
          en: 'Could not save this place. Try again later.',
        );
      });
    }
  }
}

class _PlaceMapConsentPrompt extends StatelessWidget {
  const _PlaceMapConsentPrompt({
    required this.i18n,
    required this.accent,
    required this.onAccept,
  });

  final AppI18n i18n;
  final Color accent;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          pickUiText(
            i18n,
            zh: '启用后，App 会在你点击查询时读取当前位置，用来计算附近半径、距离排序和真实场所候选。默认使用模糊位置；你也可以切换为精确定位。',
            en: 'When enabled, the app reads your location only when you tap search. It uses it to calculate radius, distance order, and real nearby place candidates. Approximate location is used by default; precise location is optional.',
          ),
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.42),
        ),
        const SizedBox(height: 10),
        _PlaceMapInlineMessage(
          icon: Icons.privacy_tip_rounded,
          color: accent,
          text: pickUiText(
            i18n,
            zh: '查询会把本次查询中心和半径发送给 OpenStreetMap/Overpass。我们不会收集、上传到自有服务或出售你的定位数据；保存场所时也不会保存你的 GPS 坐标。',
            en: 'Lookup sends this query center and radius to OpenStreetMap/Overpass. We do not collect, upload to our own service, or sell your location data; your GPS coordinates are not saved when you save a place.',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onAccept,
          icon: const Icon(Icons.check_circle_rounded),
          label: Text(
            pickUiText(i18n, zh: '同意并启用周边地图', en: 'Agree and enable map'),
          ),
        ),
      ],
    );
  }
}

class _PlaceMapPrivacyNotice extends StatelessWidget {
  const _PlaceMapPrivacyNotice({
    required this.i18n,
    required this.accent,
    required this.useApproximateLocation,
    required this.onApproximateChanged,
  });

  final AppI18n i18n;
  final Color accent;
  final bool useApproximateLocation;
  final ValueChanged<bool> onApproximateChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(ToolboxUiTokens.sectionPanelRadius),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.location_searching_rounded, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pickUiText(
                      i18n,
                      zh: '位置只用于当前半径查询，并作为查询中心发给 OpenStreetMap/Overpass。模糊位置会把坐标归到约 500 米网格，适合日常找方向；精确定位适合步行距离更敏感的场景。',
                      en: 'Location is used only for this radius lookup and is sent as the query center to OpenStreetMap/Overpass. Approximate mode snaps coordinates to an about 500 m grid; precise mode is better when walking distance matters.',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    pickUiText(
                      i18n,
                      zh: '使用模糊位置',
                      en: 'Use approximate location',
                    ),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Switch(
                  value: useApproximateLocation,
                  onChanged: onApproximateChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceMapRadiusSelector extends StatelessWidget {
  const _PlaceMapRadiusSelector({
    required this.i18n,
    required this.accent,
    required this.radiusChoices,
    required this.selectedRadius,
    required this.onSelected,
  });

  final AppI18n i18n;
  final Color accent;
  final List<int> radiusChoices;
  final int selectedRadius;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          pickUiText(i18n, zh: '查询范围', en: 'Search radius'),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: radiusChoices
              .map((radius) {
                final selected = radius == selectedRadius;
                return ToolboxSelectablePill(
                  selected: selected,
                  tint: accent,
                  onTap: () => onSelected(radius),
                  leading: const Icon(
                    Icons.radio_button_checked_rounded,
                    size: 16,
                  ),
                  label: Text(
                    radius < 1000
                        ? '${radius}m'
                        : '${(radius / 1000).toStringAsFixed(1)}km',
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _PlaceMapPreview extends StatelessWidget {
  const _PlaceMapPreview({
    required this.accent,
    required this.center,
    required this.places,
    required this.radiusMeters,
    required this.usedApproximateLocation,
  });

  final Color accent;
  final DailyChoiceGeoPoint center;
  final List<DailyChoiceOsmPlace> places;
  final int radiusMeters;
  final bool usedApproximateLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapCenter = LatLng(center.latitude, center.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(ToolboxUiTokens.sectionPanelRadius),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: mapCenter,
            initialZoom: _zoomForRadius(radiusMeters),
            interactionOptions: const InteractionOptions(
              flags:
                  InteractiveFlag.drag |
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: <Widget>[
            TileLayer(
              urlTemplate: dailyChoicePlaceMapTileUrlTemplate,
              userAgentPackageName: 'vocabulary_sleep_app',
            ),
            MarkerLayer(
              markers: <Marker>[
                Marker(
                  width: 42,
                  height: 42,
                  point: mapCenter,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        toolboxPanelShadow(
                          accent,
                          opacity: 0.24,
                          blurRadius: 18,
                          offsetY: 6,
                        ),
                      ],
                    ),
                    child: Icon(
                      usedApproximateLocation
                          ? Icons.blur_circular_rounded
                          : Icons.my_location_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                ...places
                    .take(24)
                    .map(
                      (place) => Marker(
                        width: 34,
                        height: 34,
                        point: LatLng(place.latitude, place.longitude),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accent.withValues(alpha: 0.7),
                            ),
                          ),
                          child: Icon(
                            Icons.place_rounded,
                            color: accent,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
            const RichAttributionWidget(
              attributions: <SourceAttribution>[
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _zoomForRadius(int radiusMeters) {
    if (radiusMeters <= 500) {
      return 16;
    }
    if (radiusMeters <= 1000) {
      return 15;
    }
    if (radiusMeters <= 1500) {
      return 14;
    }
    if (radiusMeters <= 3000) {
      return 13;
    }
    return 12;
  }
}

class _PlaceMapResultList extends StatelessWidget {
  const _PlaceMapResultList({
    required this.i18n,
    required this.accent,
    required this.places,
    required this.savedIds,
    required this.savingIds,
    required this.onSavePlace,
  });

  final AppI18n i18n;
  final Color accent;
  final List<DailyChoiceOsmPlace> places;
  final Set<String> savedIds;
  final Set<String> savingIds;
  final Future<void> Function(DailyChoiceOsmPlace place) onSavePlace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (places.isEmpty) {
      return Text(
        pickUiText(
          i18n,
          zh: '获取周边后，地图中的场所会显示在这里，可一键加入你的场所清单。',
          en: 'After lookup, nearby map places appear here and can be saved into your place list.',
        ),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.35,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          pickUiText(
            i18n,
            zh: '周边场所（${places.length}）',
            en: 'Nearby places (${places.length})',
          ),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ...places.take(20).map((place) {
          final saved = savedIds.contains(place.id);
          final saving = savingIds.contains(place.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(
                  ToolboxUiTokens.sectionPanelRadius,
                ),
                border: Border.all(color: accent.withValues(alpha: 0.14)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.place_rounded, color: accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            place.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pickUiText(
                              i18n,
                              zh: '${place.kindZh} · 约 ${dailyChoiceDistanceLabelZh(place.distanceMeters)}',
                              en: '${place.kindEn} · about ${dailyChoiceDistanceLabelEn(place.distanceMeters)}',
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: saved || saving
                          ? null
                          : () => unawaited(onSavePlace(place)),
                      icon: Icon(
                        saved
                            ? Icons.check_circle_rounded
                            : (saving
                                  ? Icons.hourglass_top_rounded
                                  : Icons.bookmark_add_rounded),
                      ),
                      label: Text(
                        pickUiText(
                          i18n,
                          zh: saved ? '已保存' : (saving ? '保存中' : '保存'),
                          en: saved ? 'Saved' : (saving ? 'Saving' : 'Save'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _PlaceMapInlineMessage extends StatelessWidget {
  const _PlaceMapInlineMessage({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ToolboxUiTokens.sectionPanelRadius),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

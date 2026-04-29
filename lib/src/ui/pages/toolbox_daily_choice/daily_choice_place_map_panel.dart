part of 'daily_choice_hub.dart';

class DailyChoicePlaceMapPanel extends StatefulWidget {
  const DailyChoicePlaceMapPanel({
    super.key,
    required this.i18n,
    required this.accent,
    required this.settings,
    required this.onSettingsChanged,
    required this.onSavePlace,
    required this.activeDistanceCategory,
    required this.activeSceneCategory,
    required this.savedOptionIds,
    this.locationProvider = const DailyChoiceDeviceLocationProvider(),
    this.coarseLocationProvider = const DailyChoiceIpCoarseLocationProvider(),
    DailyChoiceOverpassClient? overpassClient,
  }) : _overpassClient = overpassClient;

  final AppI18n i18n;
  final Color accent;
  final DailyChoicePlaceMapSettings settings;
  final ValueChanged<DailyChoicePlaceMapSettings> onSettingsChanged;
  final Future<DailyChoiceOption> Function(DailyChoiceOsmPlace place)
  onSavePlace;
  final DailyChoiceCategory activeDistanceCategory;
  final DailyChoiceCategory activeSceneCategory;
  final Set<String> savedOptionIds;
  final DailyChoiceLocationProvider locationProvider;
  final DailyChoiceCoarseLocationProvider coarseLocationProvider;
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
  DailyChoiceLocationReadSource _lastQueryLocationSource =
      DailyChoiceLocationReadSource.device;
  String? _lastQueryAreaLabel;
  int _lastQueryRadiusMeters = DailyChoicePlaceMapSettings.defaultRadiusMeters;
  List<DailyChoiceOsmPlace> _places = const <DailyChoiceOsmPlace>[];
  final Set<String> _savingIds = <String>{};
  final Set<String> _locallySavedIds = <String>{};
  final Set<String> _openingMapIds = <String>{};
  bool _focusCurrentFilters = true;
  String? _focusedPlaceId;
  int _mapCacheGeneration = 0;
  final math.Random _random = math.Random();

  @override
  void didUpdateWidget(covariant DailyChoicePlaceMapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeDistanceCategory.id !=
            widget.activeDistanceCategory.id ||
        oldWidget.activeSceneCategory.id != widget.activeSceneCategory.id) {
      _focusedPlaceId = null;
    }
  }

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
    final tileProvider = dailyChoiceResolveMapTileProvider(
      settings.tileProviderId,
    );
    final visiblePlaces = _visiblePlaces(_places);
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
              _PlaceMapFilterPanel(
                i18n: widget.i18n,
                accent: widget.accent,
                activeDistanceCategory: widget.activeDistanceCategory,
                activeSceneCategory: widget.activeSceneCategory,
                focusCurrentFilters: _focusCurrentFilters,
                totalCount: _places.length,
                visibleCount: visiblePlaces.length,
                onFocusChanged: (value) => setState(() {
                  _focusCurrentFilters = value;
                  _focusedPlaceId = null;
                }),
              ),
              const SizedBox(height: 12),
              _PlaceMapResourcePanel(
                i18n: widget.i18n,
                accent: widget.accent,
                settings: settings,
                selectedProvider: tileProvider,
                onSettingsChanged: widget.onSettingsChanged,
                onCacheCleared: () => setState(() {
                  _mapCacheGeneration++;
                }),
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
                    onPressed: _loading ? null : _queryCoarseRangePlaces,
                    icon: const Icon(Icons.public_rounded),
                    label: Text(
                      pickUiText(
                        widget.i18n,
                        zh: 'IP 粗略范围',
                        en: 'IP coarse area',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: visiblePlaces.isEmpty
                        ? null
                        : () => _pickRandomNearbyPlace(visiblePlaces),
                    icon: const Icon(Icons.shuffle_rounded),
                    label: Text(
                      pickUiText(
                        widget.i18n,
                        zh: '随机周边地点',
                        en: 'Random nearby place',
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
                            _lastQueryAreaLabel = null;
                            _lastQueryLocationSource =
                                DailyChoiceLocationReadSource.device;
                            _lastQueryRadiusMeters =
                                DailyChoicePlaceMapSettings.defaultRadiusMeters;
                            _focusedPlaceId = null;
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
                  i18n: widget.i18n,
                  accent: widget.accent,
                  settings: settings,
                  tileProvider: tileProvider,
                  center: _queryCenter!,
                  places: visiblePlaces,
                  totalPlaceCount: _places.length,
                  radiusMeters: _lastQueryRadiusMeters,
                  usedApproximateLocation: _lastQueryUsedApproximateLocation,
                  locationSource: _lastQueryLocationSource,
                  areaLabel: _lastQueryAreaLabel,
                  focusedPlaceId: _focusedPlaceId,
                  cacheGeneration: _mapCacheGeneration,
                  onPlaceFocused: (placeId) => setState(() {
                    _focusedPlaceId = placeId;
                  }),
                  onFullscreen: () => _openFullscreenMap(
                    tileProvider: tileProvider,
                    places: visiblePlaces,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _PlaceMapResultList(
                i18n: widget.i18n,
                accent: widget.accent,
                places: visiblePlaces,
                totalPlaceCount: _places.length,
                savedIds: savedIds,
                savingIds: _savingIds,
                openingMapIds: _openingMapIds,
                selectedPlaceId: _focusedPlaceId,
                filterActive: _focusCurrentFilters,
                onSelectPlace: (placeId) => setState(() {
                  _focusedPlaceId = placeId;
                }),
                onOpenInMap: _openPlaceInDeviceMap,
                onSavePlace: _savePlace,
              ),
              const SizedBox(height: 10),
              Text(
                pickUiText(
                  widget.i18n,
                  zh: '地图瓦片和场所数据按需查询；App 没有中间服务器收集或留存你的定位信息，也不会批量下载地图瓦片。IP 粗略范围只使用网络出口估算城市级中心点，不请求 GPS。',
                  en: 'Map tiles and place data are queried on demand. The app does not collect or store your location through an intermediary server, and it does not bulk-download map tiles. IP coarse area only estimates a city-level center from the network exit and does not request GPS.',
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

  List<DailyChoiceOsmPlace> _visiblePlaces(List<DailyChoiceOsmPlace> places) {
    if (!_focusCurrentFilters) {
      return places;
    }
    return places
        .where((place) {
          if (place.categoryId != widget.activeDistanceCategory.id) {
            return false;
          }
          if (widget.activeSceneCategory.id == allPlaceSceneCategory.id) {
            return true;
          }
          return place.sceneId == widget.activeSceneCategory.id;
        })
        .toList(growable: false);
  }

  void _pickRandomNearbyPlace(List<DailyChoiceOsmPlace> visiblePlaces) {
    if (visiblePlaces.isEmpty) {
      return;
    }
    var pool = visiblePlaces;
    final currentId = _focusedPlaceId;
    if (currentId != null && visiblePlaces.length > 1) {
      pool = visiblePlaces
          .where((place) => place.id != currentId)
          .toList(growable: false);
    }
    final picked = pool[_random.nextInt(pool.length)];
    setState(() {
      _focusedPlaceId = picked.id;
    });
  }

  Future<void> _openFullscreenMap({
    required DailyChoiceMapTileProviderSpec tileProvider,
    required List<DailyChoiceOsmPlace> places,
  }) async {
    final center = _queryCenter;
    if (center == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _PlaceMapFullscreenPage(
          i18n: widget.i18n,
          accent: widget.accent,
          settings: widget.settings,
          tileProvider: tileProvider,
          center: center,
          places: places,
          totalPlaceCount: _places.length,
          radiusMeters: _lastQueryRadiusMeters,
          usedApproximateLocation: _lastQueryUsedApproximateLocation,
          locationSource: _lastQueryLocationSource,
          areaLabel: _lastQueryAreaLabel,
          initialFocusedPlaceId: _focusedPlaceId,
          cacheGeneration: _mapCacheGeneration,
          onPlaceFocused: (placeId) {
            if (!mounted) {
              return;
            }
            setState(() {
              _focusedPlaceId = placeId;
            });
          },
        ),
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
      if (_shouldPromptLocationSettings(location.status)) {
        unawaited(_promptLocationSettings(location.status));
      }
      return;
    }
    await _queryPlacesFromResolvedLocation(
      location: location,
      radiusMeters: settings.normalizedRadiusMeters,
      focusCurrentFilters: true,
      emptyMessageZh: '当前半径内没有找到可用场所。可以扩大范围，或稍后再试。',
      emptyMessageEn:
          'No usable places were found in this radius. Try a larger range or come back later.',
      failureMessageZh: '周边场所查询失败。OpenStreetMap 公共服务可能繁忙，请稍后再试。',
      failureMessageEn:
          'Nearby place lookup failed. The public OpenStreetMap service may be busy; try again later.',
    );
  }

  Future<void> _queryCoarseRangePlaces() async {
    if (_loading) {
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final location = await widget.coarseLocationProvider.readCoarseLocation();
    if (!mounted) {
      return;
    }
    if (!location.hasPoint) {
      setState(() {
        _loading = false;
        _errorMessage = _coarseLocationErrorText(location);
      });
      return;
    }
    await _queryPlacesFromResolvedLocation(
      location: location,
      radiusMeters: DailyChoicePlaceMapSettings.coarseRangeRadiusMeters,
      focusCurrentFilters: false,
      emptyMessageZh: 'IP 粗略范围内没有找到可用场所。可以稍后再试，或改用设备定位查询。',
      emptyMessageEn:
          'No usable places were found in the IP coarse area. Try again later or use device location.',
      failureMessageZh: 'IP 粗略范围场所查询失败。公共地图服务可能繁忙，请稍后再试。',
      failureMessageEn:
          'IP coarse area lookup failed. The public map service may be busy; try again later.',
    );
  }

  Future<void> _queryPlacesFromResolvedLocation({
    required DailyChoiceLocationReadResult location,
    required int radiusMeters,
    required bool focusCurrentFilters,
    required String emptyMessageZh,
    required String emptyMessageEn,
    required String failureMessageZh,
    required String failureMessageEn,
  }) async {
    try {
      final places = await _overpassClient.fetchNearbyPlaces(
        center: location.point!,
        radiusMeters: radiusMeters,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _queryCenter = location.point;
        _lastQueryUsedApproximateLocation = location.usedApproximateLocation;
        _lastQueryLocationSource = location.source;
        _lastQueryAreaLabel = location.areaLabel;
        _lastQueryRadiusMeters = radiusMeters;
        _focusCurrentFilters = focusCurrentFilters;
        _places = places;
        _focusedPlaceId = places.isEmpty ? null : places.first.id;
        _loading = false;
        if (places.isEmpty) {
          _errorMessage = pickUiText(
            widget.i18n,
            zh: emptyMessageZh,
            en: emptyMessageEn,
          );
        } else {
          _errorMessage = null;
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
          zh: failureMessageZh,
          en: failureMessageEn,
        );
      });
    }
  }

  bool _shouldPromptLocationSettings(DailyChoiceLocationReadStatus status) {
    return status == DailyChoiceLocationReadStatus.serviceDisabled ||
        status == DailyChoiceLocationReadStatus.permissionDeniedForever;
  }

  Future<void> _promptLocationSettings(
    DailyChoiceLocationReadStatus status,
  ) async {
    if (!mounted) {
      return;
    }
    final appSettings =
        status == DailyChoiceLocationReadStatus.permissionDeniedForever;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          pickUiText(
            widget.i18n,
            zh: appSettings ? '打开 App 定位权限' : '打开系统定位服务',
            en: appSettings
                ? 'Open app location permission'
                : 'Open location settings',
          ),
        ),
        content: Text(
          pickUiText(
            widget.i18n,
            zh: appSettings
                ? '系统已阻止本 App 使用定位。打开设置后，请为本 App 允许定位权限，再返回查询周边场所。'
                : '系统定位服务尚未开启。打开设置后，请开启定位/GPS，再返回查询周边场所。',
            en: appSettings
                ? 'The system is blocking location for this app. Open settings, allow location permission, then return to find nearby places.'
                : 'System location services are off. Open settings, enable location/GPS, then return to find nearby places.',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(pickUiText(widget.i18n, zh: '稍后', en: 'Later')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              pickUiText(widget.i18n, zh: '打开设置', en: 'Open settings'),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    if (appSettings) {
      await dailyChoiceOpenAppSettings();
    } else {
      await dailyChoiceOpenLocationSettings();
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

  String _coarseLocationErrorText(DailyChoiceLocationReadResult result) {
    return pickUiText(
      widget.i18n,
      zh: '无法通过网络获取 IP 粗略范围：${result.message ?? '请稍后再试'}',
      en: 'Could not read an IP coarse area: ${result.message ?? 'try again later'}',
    );
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

  Future<void> _openPlaceInDeviceMap(DailyChoiceOsmPlace place) async {
    if (_openingMapIds.contains(place.id)) {
      return;
    }
    setState(() {
      _openingMapIds.add(place.id);
      _errorMessage = null;
    });
    try {
      for (final uri in dailyChoiceExternalMapUris(place)) {
        try {
          final opened = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (opened) {
            if (!mounted) {
              return;
            }
            setState(() {
              _openingMapIds.remove(place.id);
            });
            return;
          }
        } catch (_) {
          // Try the next URI; device map app support varies by platform.
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _openingMapIds.remove(place.id);
        _errorMessage = pickUiText(
          widget.i18n,
          zh: '没有找到可用的地图应用或网页入口，请稍后再试。',
          en: 'No available map app or web map entry was found. Try again later.',
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _openingMapIds.remove(place.id);
        _errorMessage = pickUiText(
          widget.i18n,
          zh: '拉起地图应用失败，请稍后再试。',
          en: 'Could not open the map app. Try again later.',
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
            zh: '查询只在你点击时由设备按需发起。App 没有中间服务器收集、留存或转卖你的定位数据；保存场所时也不会保存你的 GPS 坐标。',
            en: 'Lookup starts from your device only when you tap. The app does not collect, store, or sell your location through an intermediary server; your GPS coordinates are not saved when you save a place.',
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
                      zh: '位置只用于当前半径查询、距离排序和地图打开。App 不经中间服务器收集位置；模糊位置会把坐标归到约 500 米网格。也可以使用 IP 粗略范围，不请求 GPS，只按网络出口估算城市级位置。',
                      en: 'Location is used only for this radius lookup, distance sorting, and opening maps. The app does not collect it through an intermediary server. Approximate mode snaps coordinates to an about 500 m grid. IP coarse area does not request GPS and only estimates a city-level center from the network exit.',
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

class _PlaceMapFilterPanel extends StatelessWidget {
  const _PlaceMapFilterPanel({
    required this.i18n,
    required this.accent,
    required this.activeDistanceCategory,
    required this.activeSceneCategory,
    required this.focusCurrentFilters,
    required this.totalCount,
    required this.visibleCount,
    required this.onFocusChanged,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoiceCategory activeDistanceCategory;
  final DailyChoiceCategory activeSceneCategory;
  final bool focusCurrentFilters;
  final int totalCount;
  final int visibleCount;
  final ValueChanged<bool> onFocusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sceneTitle = activeSceneCategory.title(i18n);
    final distanceTitle = activeDistanceCategory.title(i18n);
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
                Icon(Icons.filter_alt_rounded, color: accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pickUiText(
                      i18n,
                      zh: '地图结果会与当前「去哪儿」筛选联动：$distanceTitle · $sceneTitle。',
                      en: 'Map results can follow the current Where to go filters: $distanceTitle · $sceneTitle.',
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
                      zh: totalCount == 0
                          ? '仅显示当前筛选'
                          : '当前筛选 $visibleCount / 全部 $totalCount',
                      en: totalCount == 0
                          ? 'Show current filters only'
                          : 'Current filters $visibleCount / all $totalCount',
                    ),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Switch(value: focusCurrentFilters, onChanged: onFocusChanged),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceMapResourcePanel extends StatefulWidget {
  const _PlaceMapResourcePanel({
    required this.i18n,
    required this.accent,
    required this.settings,
    required this.selectedProvider,
    required this.onSettingsChanged,
    required this.onCacheCleared,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoicePlaceMapSettings settings;
  final DailyChoiceMapTileProviderSpec selectedProvider;
  final ValueChanged<DailyChoicePlaceMapSettings> onSettingsChanged;
  final VoidCallback onCacheCleared;

  @override
  State<_PlaceMapResourcePanel> createState() => _PlaceMapResourcePanelState();
}

class _PlaceMapResourcePanelState extends State<_PlaceMapResourcePanel> {
  late Future<int> _cacheSizeFuture = dailyChoicePlaceMapCacheSizeBytes();
  bool _clearingCache = false;
  String? _cacheError;

  @override
  void didUpdateWidget(covariant _PlaceMapResourcePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.cacheTiles != widget.settings.cacheTiles) {
      _refreshCacheSize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultProvider = dailyChoiceResolveMapTileProvider(
      DailyChoicePlaceMapSettings.defaultTileProviderId,
    );
    final fallbackProviders = dailyChoicePlaceMapTileProviders
        .where((provider) => provider.id != defaultProvider.id)
        .toList(growable: false);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(ToolboxUiTokens.sectionPanelRadius),
        border: Border.all(color: widget.accent.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.layers_rounded, color: widget.accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pickUiText(
                      widget.i18n,
                      zh: '地图瓦片按视野动态加载；本地缓存只保存你看过的瓦片，不做区域批量下载。',
                      en: 'Tiles load on demand for the visible area; local cache only stores tiles you have viewed and does not bulk-download regions.',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              pickUiText(widget.i18n, zh: '地图源', en: 'Tile source'),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[_providerPill(defaultProvider)],
            ),
            const SizedBox(height: 10),
            Text(
              pickUiText(
                widget.i18n,
                zh: '其他备用源通常需要国际网络环境；当前默认优先使用 OSM HOT。',
                en: 'Other fallback sources usually require access to the international network; OSM HOT is the default.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: fallbackProviders
                  .map(_providerPill)
                  .toList(growable: false),
            ),
            const SizedBox(height: 8),
            Text(
              pickUiText(
                widget.i18n,
                zh: widget.selectedProvider.descriptionZh,
                en: widget.selectedProvider.descriptionEn,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            if (widget.selectedProvider.requiresConservativeUse) ...<Widget>[
              const SizedBox(height: 8),
              _PlaceMapInlineMessage(
                icon: Icons.policy_rounded,
                color: widget.selectedProvider.usesOsmPublicTileServer
                    ? theme.colorScheme.error
                    : widget.accent,
                text: pickUiText(
                  widget.i18n,
                  zh: widget.selectedProvider.usesOsmPublicTileServer
                      ? '这是 OpenStreetMap 官方公共瓦片源，可能触发公共服务限流或超时；建议只在需要核对标准样式时使用。'
                      : '这是 OSM 社区公共瓦片源，App 会按视野加载并缓存已看过的瓦片；请避免批量预下载。连接不稳定时可切换其他源。',
                  en: widget.selectedProvider.usesOsmPublicTileServer
                      ? 'This is the official OpenStreetMap public tile server and may be rate-limited or time out; use it only when the standard style is needed.'
                      : 'This is an OSM community public tile source. The app loads visible tiles on demand and caches viewed tiles; avoid bulk downloading and switch sources if the connection is unstable.',
                ),
              ),
            ],
            const SizedBox(height: 10),
            _PlaceMapSwitchRow(
              title: pickUiText(
                widget.i18n,
                zh: '本地缓存看过的瓦片',
                en: 'Cache viewed tiles',
              ),
              subtitle: pickUiText(
                widget.i18n,
                zh: '减少重复加载和弱网下的白屏；可随时清空。',
                en: 'Reduces repeated loading and blank tiles on weak networks; can be cleared anytime.',
              ),
              value: widget.settings.cacheTiles,
              onChanged: (value) => widget.onSettingsChanged(
                widget.settings.copyWith(cacheTiles: value),
              ),
            ),
            const SizedBox(height: 8),
            _PlaceMapSwitchRow(
              title: pickUiText(
                widget.i18n,
                zh: '结果变化后自动贴合地图',
                en: 'Auto-fit results',
              ),
              subtitle: pickUiText(
                widget.i18n,
                zh: '查询或切换筛选后，地图自动回到能看清当前位置和候选点的视野。',
                en: 'After lookup or filter changes, the map returns to a view that includes your center and candidates.',
              ),
              value: widget.settings.autoFitResults,
              onChanged: (value) => widget.onSettingsChanged(
                widget.settings.copyWith(autoFitResults: value),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: FutureBuilder<int>(
                    future: _cacheSizeFuture,
                    builder: (context, snapshot) {
                      final label = widget.settings.cacheTiles
                          ? (snapshot.hasData
                                ? dailyChoiceFormatBytes(snapshot.data!)
                                : pickUiText(
                                    widget.i18n,
                                    zh: '计算中',
                                    en: 'Checking',
                                  ))
                          : pickUiText(widget.i18n, zh: '未启用', en: 'Disabled');
                      return Text(
                        pickUiText(
                          widget.i18n,
                          zh: '瓦片缓存：$label',
                          en: 'Tile cache: $label',
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.settings.cacheTiles && !_clearingCache
                      ? _clearCache
                      : null,
                  icon: Icon(
                    _clearingCache
                        ? Icons.hourglass_top_rounded
                        : Icons.delete_sweep_rounded,
                  ),
                  label: Text(
                    pickUiText(
                      widget.i18n,
                      zh: _clearingCache ? '清理中' : '清空',
                      en: _clearingCache ? 'Clearing' : 'Clear',
                    ),
                  ),
                ),
              ],
            ),
            if (_cacheError != null) ...<Widget>[
              const SizedBox(height: 8),
              _PlaceMapInlineMessage(
                icon: Icons.warning_amber_rounded,
                color: theme.colorScheme.error,
                text: _cacheError!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _providerPill(DailyChoiceMapTileProviderSpec provider) {
    final selected = provider.id == widget.selectedProvider.id;
    return ToolboxSelectablePill(
      selected: selected,
      tint: widget.accent,
      onTap: () => widget.onSettingsChanged(
        widget.settings.copyWith(tileProviderId: provider.id),
      ),
      leading: Icon(
        provider.requiresConservativeUse
            ? Icons.public_rounded
            : Icons.map_rounded,
        size: 16,
      ),
      label: Text(
        pickUiText(widget.i18n, zh: provider.titleZh, en: provider.titleEn),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    );
  }

  void _refreshCacheSize() {
    setState(() {
      _cacheSizeFuture = dailyChoicePlaceMapCacheSizeBytes();
    });
  }

  Future<void> _clearCache() async {
    if (_clearingCache) {
      return;
    }
    setState(() {
      _clearingCache = true;
      _cacheError = null;
    });
    try {
      await dailyChoiceClearPlaceMapCache();
      if (!mounted) {
        return;
      }
      widget.onCacheCleared();
      setState(() {
        _cacheSizeFuture = Future<int>.value(0);
        _clearingCache = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _clearingCache = false;
        _cacheError = pickUiText(
          widget.i18n,
          zh: '清空地图缓存失败，请稍后再试。',
          en: 'Could not clear the map cache. Try again later.',
        );
        _cacheSizeFuture = dailyChoicePlaceMapCacheSizeBytes();
      });
    }
  }
}

class _PlaceMapSwitchRow extends StatelessWidget {
  const _PlaceMapSwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _PlaceMapPreview extends StatelessWidget {
  const _PlaceMapPreview({
    required this.i18n,
    required this.accent,
    required this.settings,
    required this.tileProvider,
    required this.center,
    required this.places,
    required this.totalPlaceCount,
    required this.radiusMeters,
    required this.usedApproximateLocation,
    required this.locationSource,
    required this.areaLabel,
    required this.focusedPlaceId,
    required this.cacheGeneration,
    required this.onPlaceFocused,
    required this.onFullscreen,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoicePlaceMapSettings settings;
  final DailyChoiceMapTileProviderSpec tileProvider;
  final DailyChoiceGeoPoint center;
  final List<DailyChoiceOsmPlace> places;
  final int totalPlaceCount;
  final int radiusMeters;
  final bool usedApproximateLocation;
  final DailyChoiceLocationReadSource locationSource;
  final String? areaLabel;
  final String? focusedPlaceId;
  final int cacheGeneration;
  final ValueChanged<String> onPlaceFocused;
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ToolboxUiTokens.sectionPanelRadius),
      child: SizedBox(
        height: 260,
        child: _PlaceMapCanvas(
          i18n: i18n,
          accent: accent,
          settings: settings,
          tileProvider: tileProvider,
          center: center,
          places: places,
          totalPlaceCount: totalPlaceCount,
          radiusMeters: radiusMeters,
          usedApproximateLocation: usedApproximateLocation,
          locationSource: locationSource,
          areaLabel: areaLabel,
          focusedPlaceId: focusedPlaceId,
          cacheGeneration: cacheGeneration,
          fullscreen: false,
          onPlaceFocused: onPlaceFocused,
          onFullscreen: onFullscreen,
        ),
      ),
    );
  }
}

class _PlaceMapFullscreenPage extends StatefulWidget {
  const _PlaceMapFullscreenPage({
    required this.i18n,
    required this.accent,
    required this.settings,
    required this.tileProvider,
    required this.center,
    required this.places,
    required this.totalPlaceCount,
    required this.radiusMeters,
    required this.usedApproximateLocation,
    required this.locationSource,
    required this.areaLabel,
    required this.initialFocusedPlaceId,
    required this.cacheGeneration,
    required this.onPlaceFocused,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoicePlaceMapSettings settings;
  final DailyChoiceMapTileProviderSpec tileProvider;
  final DailyChoiceGeoPoint center;
  final List<DailyChoiceOsmPlace> places;
  final int totalPlaceCount;
  final int radiusMeters;
  final bool usedApproximateLocation;
  final DailyChoiceLocationReadSource locationSource;
  final String? areaLabel;
  final String? initialFocusedPlaceId;
  final int cacheGeneration;
  final ValueChanged<String> onPlaceFocused;

  @override
  State<_PlaceMapFullscreenPage> createState() =>
      _PlaceMapFullscreenPageState();
}

class _PlaceMapFullscreenPageState extends State<_PlaceMapFullscreenPage> {
  late String? _focusedPlaceId = widget.initialFocusedPlaceId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pickUiText(widget.i18n, zh: '周边地图', en: 'Nearby map')),
      ),
      body: SafeArea(
        child: _PlaceMapCanvas(
          i18n: widget.i18n,
          accent: widget.accent,
          settings: widget.settings,
          tileProvider: widget.tileProvider,
          center: widget.center,
          places: widget.places,
          totalPlaceCount: widget.totalPlaceCount,
          radiusMeters: widget.radiusMeters,
          usedApproximateLocation: widget.usedApproximateLocation,
          locationSource: widget.locationSource,
          areaLabel: widget.areaLabel,
          focusedPlaceId: _focusedPlaceId,
          cacheGeneration: widget.cacheGeneration,
          fullscreen: true,
          onPlaceFocused: (placeId) {
            setState(() => _focusedPlaceId = placeId);
            widget.onPlaceFocused(placeId);
          },
        ),
      ),
    );
  }
}

class _PlaceMapCanvas extends StatefulWidget {
  const _PlaceMapCanvas({
    required this.i18n,
    required this.accent,
    required this.settings,
    required this.tileProvider,
    required this.center,
    required this.places,
    required this.totalPlaceCount,
    required this.radiusMeters,
    required this.usedApproximateLocation,
    required this.locationSource,
    required this.areaLabel,
    required this.focusedPlaceId,
    required this.cacheGeneration,
    required this.fullscreen,
    required this.onPlaceFocused,
    this.onFullscreen,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoicePlaceMapSettings settings;
  final DailyChoiceMapTileProviderSpec tileProvider;
  final DailyChoiceGeoPoint center;
  final List<DailyChoiceOsmPlace> places;
  final int totalPlaceCount;
  final int radiusMeters;
  final bool usedApproximateLocation;
  final DailyChoiceLocationReadSource locationSource;
  final String? areaLabel;
  final String? focusedPlaceId;
  final int cacheGeneration;
  final bool fullscreen;
  final ValueChanged<String> onPlaceFocused;
  final VoidCallback? onFullscreen;

  @override
  State<_PlaceMapCanvas> createState() => _PlaceMapCanvasState();
}

class _PlaceMapCanvasState extends State<_PlaceMapCanvas> {
  late final MapController _mapController = MapController();
  late Future<MapCachingProvider> _cachingProviderFuture =
      dailyChoiceCreatePlaceMapCachingProvider(
        cacheTiles: widget.settings.cacheTiles,
      );
  bool _mapReady = false;
  int _tileErrorCount = 0;

  LatLng get _mapCenter =>
      LatLng(widget.center.latitude, widget.center.longitude);

  @override
  void didUpdateWidget(covariant _PlaceMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.cacheTiles != widget.settings.cacheTiles ||
        oldWidget.cacheGeneration != widget.cacheGeneration) {
      _cachingProviderFuture = dailyChoiceCreatePlaceMapCachingProvider(
        cacheTiles: widget.settings.cacheTiles,
      );
    }
    if (oldWidget.tileProvider.id != widget.tileProvider.id) {
      _tileErrorCount = 0;
    }
    final focusChanged =
        oldWidget.focusedPlaceId != widget.focusedPlaceId &&
        widget.focusedPlaceId != null;
    if (_mapReady && focusChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _moveToFocusedPlace();
        }
      });
    } else if (_mapReady &&
        widget.settings.autoFitResults &&
        _shouldAutoFit(oldWidget)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fitResults();
        }
      });
    }
  }

  bool _shouldAutoFit(_PlaceMapCanvas oldWidget) {
    if (oldWidget.radiusMeters != widget.radiusMeters ||
        oldWidget.settings.autoFitResults != widget.settings.autoFitResults ||
        oldWidget.center.latitude != widget.center.latitude ||
        oldWidget.center.longitude != widget.center.longitude) {
      return true;
    }
    if (oldWidget.places.length != widget.places.length) {
      return true;
    }
    for (var index = 0; index < widget.places.length; index++) {
      if (oldWidget.places[index].id != widget.places[index].id) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<MapCachingProvider>(
      future: _cachingProviderFuture,
      builder: (context, snapshot) {
        final cachingProvider = snapshot.data;
        if (cachingProvider == null && widget.settings.cacheTiles) {
          return _PlaceMapLoadingSurface(
            i18n: widget.i18n,
            accent: widget.accent,
          );
        }
        final resolvedCachingProvider =
            cachingProvider ?? const DisabledMapCachingProvider();
        return Stack(
          children: <Widget>[
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _mapCenter,
                initialZoom: _zoomForRadius(widget.radiusMeters),
                minZoom: widget.tileProvider.minZoom,
                maxZoom: widget.tileProvider.maxZoom,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
                onMapReady: () {
                  _mapReady = true;
                  if (widget.settings.autoFitResults) {
                    _fitResults();
                  }
                },
                interactionOptions: const InteractionOptions(
                  flags:
                      InteractiveFlag.drag |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.doubleTapZoom |
                      InteractiveFlag.scrollWheelZoom,
                ),
              ),
              children: <Widget>[
                TileLayer(
                  key: ValueKey<String>(
                    '${widget.tileProvider.id}-${widget.settings.cacheTiles}-${widget.cacheGeneration}',
                  ),
                  urlTemplate: widget.tileProvider.urlTemplate,
                  subdomains: widget.tileProvider.subdomains,
                  userAgentPackageName: dailyChoicePlaceMapUserAgentPackageName,
                  minZoom: widget.tileProvider.minZoom,
                  maxZoom: widget.tileProvider.maxZoom,
                  retinaMode: false,
                  panBuffer: 0,
                  keepBuffer: 1,
                  tileDisplay: const TileDisplay.fadeIn(
                    duration: Duration(milliseconds: 180),
                  ),
                  tileProvider: NetworkTileProvider(
                    cachingProvider: resolvedCachingProvider,
                    silenceExceptions: true,
                    abortObsoleteRequests: true,
                  ),
                  errorTileCallback: (_, _, _) {
                    if (!mounted || _tileErrorCount >= 99) {
                      return;
                    }
                    setState(() => _tileErrorCount++);
                  },
                ),
                CircleLayer(
                  circles: <CircleMarker>[
                    CircleMarker(
                      point: _mapCenter,
                      radius: widget.radiusMeters.toDouble(),
                      useRadiusInMeter: true,
                      color: widget.accent.withValues(alpha: 0.10),
                      borderColor: widget.accent.withValues(alpha: 0.40),
                      borderStrokeWidth: 1.4,
                    ),
                  ],
                ),
                MarkerLayer(markers: _markers(theme)),
                RichAttributionWidget(
                  attributions: <SourceAttribution>[
                    TextSourceAttribution(
                      widget.tileProvider.attribution,
                      onTap: null,
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _PlaceMapControls(
                i18n: widget.i18n,
                accent: widget.accent,
                onZoomIn: () => _zoomBy(1),
                onZoomOut: () => _zoomBy(-1),
                onFit: _fitResults,
                onCenter: () => _mapController.move(
                  _mapCenter,
                  _zoomForRadius(widget.radiusMeters),
                ),
              ),
            ),
            if (!widget.fullscreen && widget.onFullscreen != null)
              Positioned(
                top: 8,
                left: 8,
                child: _PlaceMapToolSurface(
                  accent: widget.accent,
                  child: _PlaceMapToolButton(
                    tooltip: pickUiText(
                      widget.i18n,
                      zh: '全屏查看',
                      en: 'Fullscreen',
                    ),
                    icon: Icons.fullscreen_rounded,
                    onPressed: widget.onFullscreen!,
                  ),
                ),
              ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: _PlaceMapStatusOverlay(
                i18n: widget.i18n,
                accent: widget.accent,
                visibleCount: widget.places.length,
                totalCount: widget.totalPlaceCount,
                tileProvider: widget.tileProvider,
                tileErrorCount: _tileErrorCount,
                cacheEnabled: widget.settings.cacheTiles,
                locationSource: widget.locationSource,
                areaLabel: widget.areaLabel,
              ),
            ),
          ],
        );
      },
    );
  }

  List<Marker> _markers(ThemeData theme) {
    return <Marker>[
      Marker(
        width: 46,
        height: 46,
        point: _mapCenter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.accent,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              toolboxPanelShadow(
                widget.accent,
                opacity: 0.24,
                blurRadius: 18,
                offsetY: 6,
              ),
            ],
          ),
          child: Icon(
            widget.usedApproximateLocation
                ? Icons.blur_circular_rounded
                : Icons.my_location_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
      ...widget.places.take(40).map((place) {
        final selected = place.id == widget.focusedPlaceId;
        return Marker(
          width: selected ? 44 : 36,
          height: selected ? 44 : 36,
          point: LatLng(place.latitude, place.longitude),
          child: GestureDetector(
            onTap: () {
              widget.onPlaceFocused(place.id);
              _mapController.move(
                LatLng(place.latitude, place.longitude),
                math.max(_mapController.camera.zoom, 15.0),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: selected ? widget.accent : theme.colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? Colors.white
                      : widget.accent.withValues(alpha: 0.72),
                  width: selected ? 2 : 1,
                ),
                boxShadow: selected
                    ? <BoxShadow>[
                        toolboxPanelShadow(
                          widget.accent,
                          opacity: 0.24,
                          blurRadius: 16,
                          offsetY: 5,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.place_rounded,
                color: selected ? Colors.white : widget.accent,
                size: selected ? 22 : 18,
              ),
            ),
          ),
        );
      }),
    ];
  }

  void _zoomBy(double delta) {
    if (!_mapReady) {
      return;
    }
    final camera = _mapController.camera;
    final nextZoom = (camera.zoom + delta)
        .clamp(widget.tileProvider.minZoom, widget.tileProvider.maxZoom)
        .toDouble();
    _mapController.move(camera.center, nextZoom);
  }

  void _fitResults() {
    if (!_mapReady) {
      return;
    }
    final points = <LatLng>[
      _mapCenter,
      ...widget.places
          .take(40)
          .map((place) => LatLng(place.latitude, place.longitude)),
    ];
    if (points.length <= 1) {
      _mapController.move(_mapCenter, _zoomForRadius(widget.radiusMeters));
      return;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: EdgeInsets.all(widget.fullscreen ? 72 : 44),
        maxZoom: 16,
        minZoom: widget.tileProvider.minZoom,
      ),
    );
  }

  void _moveToFocusedPlace() {
    final focusedId = widget.focusedPlaceId;
    if (!_mapReady || focusedId == null) {
      return;
    }
    for (final place in widget.places) {
      if (place.id == focusedId) {
        _mapController.move(
          LatLng(place.latitude, place.longitude),
          math.max(_mapController.camera.zoom, 15.0),
        );
        return;
      }
    }
  }
}

class _PlaceMapLoadingSurface extends StatelessWidget {
  const _PlaceMapLoadingSurface({required this.i18n, required this.accent});

  final AppI18n i18n;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerLow,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(color: accent),
            const SizedBox(height: 10),
            Text(
              pickUiText(i18n, zh: '正在准备地图资源', en: 'Preparing map resources'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceMapControls extends StatelessWidget {
  const _PlaceMapControls({
    required this.i18n,
    required this.accent,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFit,
    required this.onCenter,
  });

  final AppI18n i18n;
  final Color accent;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFit;
  final VoidCallback onCenter;

  @override
  Widget build(BuildContext context) {
    return _PlaceMapToolSurface(
      accent: accent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _PlaceMapToolButton(
            tooltip: pickUiText(i18n, zh: '放大', en: 'Zoom in'),
            icon: Icons.add_rounded,
            onPressed: onZoomIn,
          ),
          _PlaceMapToolButton(
            tooltip: pickUiText(i18n, zh: '缩小', en: 'Zoom out'),
            icon: Icons.remove_rounded,
            onPressed: onZoomOut,
          ),
          _PlaceMapToolButton(
            tooltip: pickUiText(i18n, zh: '贴合结果', en: 'Fit results'),
            icon: Icons.fit_screen_rounded,
            onPressed: onFit,
          ),
          _PlaceMapToolButton(
            tooltip: pickUiText(i18n, zh: '回到定位中心', en: 'Center location'),
            icon: Icons.my_location_rounded,
            onPressed: onCenter,
          ),
        ],
      ),
    );
  }
}

class _PlaceMapToolSurface extends StatelessWidget {
  const _PlaceMapToolSurface({required this.accent, required this.child});

  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: child,
      ),
    );
  }
}

class _PlaceMapToolButton extends StatelessWidget {
  const _PlaceMapToolButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 42,
        height: 42,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _PlaceMapStatusOverlay extends StatelessWidget {
  const _PlaceMapStatusOverlay({
    required this.i18n,
    required this.accent,
    required this.visibleCount,
    required this.totalCount,
    required this.tileProvider,
    required this.tileErrorCount,
    required this.cacheEnabled,
    required this.locationSource,
    required this.areaLabel,
  });

  final AppI18n i18n;
  final Color accent;
  final int visibleCount;
  final int totalCount;
  final DailyChoiceMapTileProviderSpec tileProvider;
  final int tileErrorCount;
  final bool cacheEnabled;
  final DailyChoiceLocationReadSource locationSource;
  final String? areaLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _PlaceMapMiniPill(
              icon: Icons.place_rounded,
              text: pickUiText(
                i18n,
                zh: totalCount == visibleCount
                    ? '$visibleCount 个地点'
                    : '$visibleCount / $totalCount 个地点',
                en: totalCount == visibleCount
                    ? '$visibleCount places'
                    : '$visibleCount / $totalCount places',
              ),
              accent: accent,
            ),
            _PlaceMapMiniPill(
              icon: Icons.layers_rounded,
              text: pickUiText(
                i18n,
                zh: tileProvider.titleZh,
                en: tileProvider.titleEn,
              ),
              accent: accent,
            ),
            _PlaceMapMiniPill(
              icon: locationSource == DailyChoiceLocationReadSource.ipCoarse
                  ? Icons.public_rounded
                  : Icons.location_searching_rounded,
              text: pickUiText(
                i18n,
                zh: locationSource == DailyChoiceLocationReadSource.ipCoarse
                    ? (areaLabel == null || areaLabel!.isEmpty
                          ? 'IP 粗略范围'
                          : 'IP 粗略：$areaLabel')
                    : '设备定位',
                en: locationSource == DailyChoiceLocationReadSource.ipCoarse
                    ? (areaLabel == null || areaLabel!.isEmpty
                          ? 'IP coarse area'
                          : 'IP coarse: $areaLabel')
                    : 'Device location',
              ),
              accent: accent,
            ),
            _PlaceMapMiniPill(
              icon: cacheEnabled
                  ? Icons.offline_pin_rounded
                  : Icons.cloud_queue_rounded,
              text: pickUiText(
                i18n,
                zh: cacheEnabled ? '缓存开启' : '仅在线',
                en: cacheEnabled ? 'Cache on' : 'Online only',
              ),
              accent: accent,
            ),
            if (tileErrorCount > 0)
              _PlaceMapMiniPill(
                icon: Icons.warning_amber_rounded,
                text: pickUiText(
                  i18n,
                  zh: '瓦片重试 $tileErrorCount',
                  en: 'Tile retries $tileErrorCount',
                ),
                accent: theme.colorScheme.error,
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaceMapMiniPill extends StatelessWidget {
  const _PlaceMapMiniPill({
    required this.icon,
    required this.text,
    required this.accent,
  });

  final IconData icon;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: accent),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
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

class _PlaceMapResultList extends StatelessWidget {
  const _PlaceMapResultList({
    required this.i18n,
    required this.accent,
    required this.places,
    required this.totalPlaceCount,
    required this.savedIds,
    required this.savingIds,
    required this.openingMapIds,
    required this.selectedPlaceId,
    required this.filterActive,
    required this.onSelectPlace,
    required this.onOpenInMap,
    required this.onSavePlace,
  });

  final AppI18n i18n;
  final Color accent;
  final List<DailyChoiceOsmPlace> places;
  final int totalPlaceCount;
  final Set<String> savedIds;
  final Set<String> savingIds;
  final Set<String> openingMapIds;
  final String? selectedPlaceId;
  final bool filterActive;
  final ValueChanged<String> onSelectPlace;
  final Future<void> Function(DailyChoiceOsmPlace place) onOpenInMap;
  final Future<void> Function(DailyChoiceOsmPlace place) onSavePlace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (places.isEmpty) {
      return Text(
        pickUiText(
          i18n,
          zh: totalPlaceCount > 0 && filterActive
              ? '当前「去哪儿」筛选下没有匹配的周边场所，可关闭筛选联动查看全部结果。'
              : '获取周边后，地图中的场所会显示在这里，可一键加入你的场所清单。',
          en: totalPlaceCount > 0 && filterActive
              ? 'No nearby places match the current Where to go filters. Turn off filter focus to view all results.'
              : 'After lookup, nearby map places appear here and can be saved into your place list.',
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
            zh: totalPlaceCount == places.length
                ? '周边场所（${places.length}）'
                : '当前筛选场所（${places.length} / $totalPlaceCount）',
            en: totalPlaceCount == places.length
                ? 'Nearby places (${places.length})'
                : 'Filtered places (${places.length} / $totalPlaceCount)',
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
          final openingMap = openingMapIds.contains(place.id);
          final selected = place.id == selectedPlaceId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(
                ToolboxUiTokens.sectionPanelRadius,
              ),
              onTap: () => onSelectPlace(place.id),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: 0.08)
                      : theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(
                    ToolboxUiTokens.sectionPanelRadius,
                  ),
                  border: Border.all(
                    color: selected
                        ? accent.withValues(alpha: 0.46)
                        : accent.withValues(alpha: 0.14),
                  ),
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
                      Tooltip(
                        message: pickUiText(
                          i18n,
                          zh: '打开地图 App',
                          en: 'Open in map app',
                        ),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: IconButton(
                            onPressed: openingMap
                                ? null
                                : () => unawaited(onOpenInMap(place)),
                            icon: Icon(
                              openingMap
                                  ? Icons.hourglass_top_rounded
                                  : Icons.map_rounded,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
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

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
                    hasConsent
                        ? widget.i18n.t(
                            'inline.plan295.daily_choice.nearby_map_enabled.e2a00215d3fb',
                          )
                        : widget.i18n.t(
                            'inline.plan295.daily_choice.nearby_map_optional.f4aaf25e7822',
                          ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ToolboxInfoPill(
                  text: settings.useApproximateLocation
                      ? widget.i18n.t(
                          'inline.plan295.daily_choice.approximate.94b122a7ed0b',
                        )
                      : widget.i18n.t(
                          'inline.plan295.daily_choice.precise.bdf841ceed51',
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
                      _loading
                          ? widget.i18n.t(
                              'inline.plan295.daily_choice.finding_places.a1427b168b70',
                            )
                          : widget.i18n.t(
                              'inline.plan295.daily_choice.find_nearby_places.10f5966c6db0',
                            ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _queryCoarseRangePlaces,
                    icon: const Icon(Icons.public_rounded),
                    label: Text(
                      widget.i18n.t(
                        'inline.plan295.daily_choice.ip_coarse_area.7365112560c5',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: visiblePlaces.isEmpty
                        ? null
                        : () => _pickRandomNearbyPlace(visiblePlaces),
                    icon: const Icon(Icons.shuffle_rounded),
                    label: Text(
                      widget.i18n.t(
                        'inline.plan295.daily_choice.random_nearby_place.7f525631055e',
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
                      widget.i18n.t(
                        'inline.plan295.daily_choice.clear.701f52dfdbc2',
                      ),
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
                widget.i18n.t(
                  'inline.plan295.daily_choice.map_tiles_and_place_data_are_queried.6e1da86cd76c',
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
      emptyMessageKey: 'daily_choice.place.map.empty.nearby',
      failureMessageKey: 'daily_choice.place.map.lookup_failed.nearby',
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
      emptyMessageKey: 'daily_choice.place.map.empty.coarse',
      failureMessageKey: 'daily_choice.place.map.lookup_failed.coarse',
    );
  }

  Future<void> _queryPlacesFromResolvedLocation({
    required DailyChoiceLocationReadResult location,
    required int radiusMeters,
    required bool focusCurrentFilters,
    required String emptyMessageKey,
    required String failureMessageKey,
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
          _errorMessage = widget.i18n.t(emptyMessageKey);
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
        _errorMessage = widget.i18n.t(failureMessageKey);
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
          appSettings
              ? widget.i18n.t(
                  'inline.plan295.daily_choice.open_app_location_permission.740c859c351e',
                )
              : widget.i18n.t(
                  'inline.plan295.daily_choice.open_location_settings.7f62b585b954',
                ),
        ),
        content: Text(
          appSettings
              ? widget.i18n.t(
                  'inline.plan295.daily_choice.the_system_is_blocking_location_for.5617e3076c9a',
                )
              : widget.i18n.t(
                  'inline.plan295.daily_choice.system_location_services_are_off_ope.a89250038894',
                ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              widget.i18n.t(
                'inline.ui.pages.toolbox_daily_choice.daily_choice_place_map_panel.later_b5566f',
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              widget.i18n.t(
                'inline.ui.pages.help_center_page.open_settings_6ca4f9',
              ),
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
      DailyChoiceLocationReadStatus.serviceDisabled => widget.i18n.t(
        'inline.plan295.daily_choice.system_location_services_are_disable.8d619d3b0361',
      ),
      DailyChoiceLocationReadStatus.permissionDenied => widget.i18n.t(
        'inline.plan295.daily_choice.location_permission_was_not_granted.24d7ab146470',
      ),
      DailyChoiceLocationReadStatus.permissionDeniedForever => widget.i18n.t(
        'inline.plan295.daily_choice.location_permission_is_blocked_enabl.d917bbd44e1f',
      ),
      DailyChoiceLocationReadStatus.failed => widget.i18n.t(
        'daily_choice.place.location_read_failed',
        params: <String, Object?>{
          'message': _localizedLocationDiagnostic(result.message),
        },
      ),
      DailyChoiceLocationReadStatus.ready => '',
    };
  }

  String _coarseLocationErrorText(DailyChoiceLocationReadResult result) {
    return widget.i18n.t(
      'daily_choice.place.ip_coarse_read_failed',
      params: <String, Object?>{
        'message': _localizedLocationDiagnostic(
          result.message,
          fallbackKey: 'daily_choice.place.location_diagnostic.try_again_later',
        ),
      },
    );
  }

  String _localizedLocationDiagnostic(
    String? message, {
    String fallbackKey = '',
  }) {
    final trimmed = message?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return fallbackKey.isEmpty ? '' : widget.i18n.t(fallbackKey);
    }
    final httpMatch = RegExp(
      r'^IP coarse location failed \((\d+)\)\.$',
    ).firstMatch(trimmed);
    if (httpMatch != null) {
      final statusCode = httpMatch.group(1) ?? '';
      return widget.i18n.t(
        'daily_choice.place.location_diagnostic.ip_failed',
        params: <String, Object?>{'statusCode': statusCode},
      );
    }
    return switch (trimmed) {
      'Location services are disabled.' => widget.i18n.t(
        'daily_choice.place.location_diagnostic.services_disabled',
      ),
      'Location permission was denied.' => widget.i18n.t(
        'daily_choice.place.location_diagnostic.permission_denied',
      ),
      'Location permission is permanently denied.' => widget.i18n.t(
        'daily_choice.place.location_diagnostic.permission_denied_forever',
      ),
      'IP coarse location returned an unexpected response.' => widget.i18n.t(
        'daily_choice.place.location_diagnostic.ip_unexpected_response',
      ),
      'IP coarse location did not include coordinates.' => widget.i18n.t(
        'daily_choice.place.location_diagnostic.ip_missing_coordinates',
      ),
      _ => trimmed,
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
        _errorMessage = widget.i18n.t(
          'inline.plan295.daily_choice.could_not_save_this_place_try_again.06bea2776075',
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
        _errorMessage = widget.i18n.t(
          'inline.plan295.daily_choice.no_available_map_app_or_web_map_entr.200727240925',
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _openingMapIds.remove(place.id);
        _errorMessage = widget.i18n.t(
          'inline.plan295.daily_choice.could_not_open_the_map_app_try_again.d3a96332a6ce',
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
          i18n.t(
            'inline.plan295.daily_choice.when_enabled_the_app_reads_your_loca.b43a464fb7c0',
          ),
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.42),
        ),
        const SizedBox(height: 10),
        _PlaceMapInlineMessage(
          icon: Icons.privacy_tip_rounded,
          color: accent,
          text: i18n.t(
            'inline.plan295.daily_choice.lookup_starts_from_your_device_only.3ae7a022da68',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onAccept,
          icon: const Icon(Icons.check_circle_rounded),
          label: Text(
            i18n.t(
              'inline.plan295.daily_choice.agree_and_enable_map.ec73e79b9911',
            ),
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
                    i18n.t(
                      'inline.plan295.daily_choice.location_is_used_only_for_this_radiu.aa6f24f4d72f',
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
                    i18n.t(
                      'inline.plan295.daily_choice.use_approximate_location.a919c7870ea7',
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
          i18n.t('inline.plan295.daily_choice.search_radius.fd89d672a970'),
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
                    i18n.t(
                      'inline.plan295.daily_choice.map_results_can_follow_the_current_w.5bb5586e60d5',
                      params: <String, Object?>{
                        'distanceTitle': distanceTitle,
                        'sceneTitle': sceneTitle,
                      },
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
                    totalCount == 0
                        ? i18n.t(
                            'inline.plan295.daily_choice.show_current_filters_only.e51533b5aa97',
                          )
                        : i18n.t(
                            'inline.plan295.daily_choice.current_filters_visiblecount_all_tot.07783e0f8a44',
                            params: <String, Object?>{
                              'visibleCount': visibleCount,
                              'totalCount': totalCount,
                            },
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
                    widget.i18n.t(
                      'inline.plan295.daily_choice.tiles_load_on_demand_for_the_visible.6623dfab72e4',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.i18n.t(
                'inline.plan295.daily_choice.tile_source.20d609cf66f9',
              ),
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
              widget.i18n.t(
                'inline.plan295.daily_choice.other_fallback_sources_usually_requi.d16fe4b1ad95',
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
              widget.i18n.t(widget.selectedProvider.descriptionKey),
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
                text: widget.selectedProvider.usesOsmPublicTileServer
                    ? widget.i18n.t(
                        'inline.plan295.daily_choice.this_is_the_official_openstreetmap_p.548ffae9b223',
                      )
                    : widget.i18n.t(
                        'inline.plan295.daily_choice.this_is_an_osm_community_public_tile.aa7475333a43',
                      ),
              ),
            ],
            const SizedBox(height: 10),
            _PlaceMapSwitchRow(
              title: widget.i18n.t(
                'inline.plan295.daily_choice.cache_viewed_tiles.1ac505c8bfbf',
              ),
              subtitle: widget.i18n.t(
                'inline.plan295.daily_choice.reduces_repeated_loading_and_blank_t.8ba486ddcf69',
              ),
              value: widget.settings.cacheTiles,
              onChanged: (value) => widget.onSettingsChanged(
                widget.settings.copyWith(cacheTiles: value),
              ),
            ),
            const SizedBox(height: 8),
            _PlaceMapSwitchRow(
              title: widget.i18n.t(
                'inline.plan295.daily_choice.auto_fit_results.41a8fb16ad7f',
              ),
              subtitle: widget.i18n.t(
                'inline.plan295.daily_choice.after_lookup_or_filter_changes_the_m.e69f21fc7a88',
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
                                : widget.i18n.t(
                                    'inline.plan295.daily_choice.checking.c60614838eaf',
                                  ))
                          : widget.i18n.t(
                              'inline.plan295.daily_choice.disabled.51ce114130f0',
                            );
                      return Text(
                        widget.i18n.t(
                          'inline.ui.pages.toolbox_daily_choice.daily_choice_place_map_panel.tile_cache_label_91a99d',
                          params: <String, Object?>{'label': label},
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
                    _clearingCache
                        ? widget.i18n.t(
                            'inline.plan295.daily_choice.clearing.bdb431f3231f',
                          )
                        : widget.i18n.t(
                            'inline.plan294.zen_sand.clear_ea17218b',
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
      label: Text(widget.i18n.t(provider.titleKey)),
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
        _cacheError = widget.i18n.t(
          'inline.plan295.daily_choice.could_not_clear_the_map_cache_try_ag.a08a5fc2a884',
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
        title: Text(
          widget.i18n.t('inline.plan295.daily_choice.nearby_map.983ec028b5e4'),
        ),
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
                    tooltip: widget.i18n.t(
                      'inline.plan295.daily_choice.fullscreen.d9ff7c0308b7',
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
              i18n.t(
                'inline.plan295.daily_choice.preparing_map_resources.e027e61f7dc6',
              ),
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
            tooltip: i18n.t(
              'inline.ui.pages.toolbox_daily_choice.daily_choice_place_map_panel.zoom_in_9c7778',
            ),
            icon: Icons.add_rounded,
            onPressed: onZoomIn,
          ),
          _PlaceMapToolButton(
            tooltip: i18n.t(
              'inline.plan295.daily_choice.zoom_out.bf354c0e0864',
            ),
            icon: Icons.remove_rounded,
            onPressed: onZoomOut,
          ),
          _PlaceMapToolButton(
            tooltip: i18n.t(
              'inline.plan295.daily_choice.fit_results.ada09913a44f',
            ),
            icon: Icons.fit_screen_rounded,
            onPressed: onFit,
          ),
          _PlaceMapToolButton(
            tooltip: i18n.t(
              'inline.plan295.daily_choice.center_location.20de0f8612e6',
            ),
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
              text: totalCount == visibleCount
                  ? i18n.t(
                      'inline.plan295.daily_choice.visiblecount_places.8546b2e7c659',
                      params: <String, Object?>{'visibleCount': visibleCount},
                    )
                  : i18n.t(
                      'inline.plan295.daily_choice.visiblecount_totalcount_places.c6ab7ec30dd3',
                      params: <String, Object?>{
                        'visibleCount': visibleCount,
                        'totalCount': totalCount,
                      },
                    ),
              accent: accent,
            ),
            _PlaceMapMiniPill(
              icon: Icons.layers_rounded,
              text: i18n.t(tileProvider.titleKey),
              accent: accent,
            ),
            _PlaceMapMiniPill(
              icon: locationSource == DailyChoiceLocationReadSource.ipCoarse
                  ? Icons.public_rounded
                  : Icons.location_searching_rounded,
              text: _locationSourceLabel(
                i18n,
                locationSource: locationSource,
                areaLabel: areaLabel,
              ),
              accent: accent,
            ),
            _PlaceMapMiniPill(
              icon: cacheEnabled
                  ? Icons.storage_rounded
                  : Icons.cloud_queue_rounded,
              text: cacheEnabled
                  ? i18n.t('inline.plan295.daily_choice.cache_on.faf6afd21de4')
                  : i18n.t(
                      'inline.plan295.daily_choice.online_only.3077b2708c14',
                    ),
              accent: accent,
            ),
            if (tileErrorCount > 0)
              _PlaceMapMiniPill(
                icon: Icons.warning_amber_rounded,
                text: i18n.t(
                  'inline.ui.pages.toolbox_daily_choice.daily_choice_place_map_panel.tile_retries_tileerrorcount_49449b',
                  params: <String, Object?>{'tileErrorCount': tileErrorCount},
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

String _locationSourceLabel(
  AppI18n i18n, {
  required DailyChoiceLocationReadSource locationSource,
  required String? areaLabel,
}) {
  if (locationSource != DailyChoiceLocationReadSource.ipCoarse) {
    return i18n.t('daily_choice.place.map.location.device');
  }
  final area = areaLabel?.trim();
  if (area == null || area.isEmpty) {
    return i18n.t('daily_choice.place.map.location.ip_coarse_area');
  }
  return i18n.t(
    'daily_choice.place.map.location.ip_coarse_area_named',
    params: <String, Object?>{'area': area},
  );
}

String _saveButtonKey({required bool saved, required bool saving}) {
  if (saved) {
    return 'daily_choice.place.map.saved';
  }
  if (saving) {
    return 'daily_choice.place.map.saving';
  }
  return 'daily_choice.place.map.save';
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
        totalPlaceCount > 0 && filterActive
            ? i18n.t(
                'inline.plan295.daily_choice.no_nearby_places_match_the_current_w.57b2d19b6049',
              )
            : i18n.t(
                'inline.plan295.daily_choice.after_lookup_nearby_map_places_appea.84b5c46aa43b',
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
          totalPlaceCount == places.length
              ? i18n.t(
                  'inline.plan295.daily_choice.nearby_places_places_length.7bca5e141f5a',
                  params: <String, Object?>{
                    'places': places.length,
                    'places.length': places.length,
                  },
                )
              : i18n.t(
                  'inline.plan295.daily_choice.filtered_places_places_length_totalp.cae3c013d3c7',
                  params: <String, Object?>{
                    'places': places.length,
                    'places.length': places.length,
                    'totalPlaceCount': totalPlaceCount,
                  },
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
                              i18n.t(
                                'inline.plan295.daily_choice.place_kinden_about_dailychoicedistan.950e9d6994e3',
                                params: <String, Object?>{
                                  'dailyChoiceDistanceLabelEnPlaceDistanceMeters':
                                      dailyChoiceDistanceLabelEn(
                                        place.distanceMeters,
                                      ),
                                  'placeKindEn': place.kindEn,
                                },
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
                        message: i18n.t(
                          'inline.plan295.daily_choice.open_in_map_app.41bd6c48156f',
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
                          i18n.t(_saveButtonKey(saved: saved, saving: saving)),
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

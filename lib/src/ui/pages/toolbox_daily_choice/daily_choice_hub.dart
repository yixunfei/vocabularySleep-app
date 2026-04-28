import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../i18n/app_i18n.dart';
import '../../../models/weather_snapshot.dart';
import '../../../state/app_state_provider.dart';
import '../../motion/app_motion.dart';
import '../../ui_copy.dart';
import '../toolbox/toolbox_ui_components.dart';
import '../toolbox/toolbox_ui_tokens.dart';
import 'daily_choice_cook_service.dart';
import 'daily_choice_decision_content.dart';
import 'daily_choice_decision_engine.dart';
import 'daily_choice_eat_catalog.dart';
import 'daily_choice_eat_library_store.dart';
import 'daily_choice_eat_support.dart';
import 'daily_choice_models.dart';
import 'daily_choice_seed_data.dart';
import 'daily_choice_storage.dart';
import 'daily_choice_wear_library_store.dart';
import 'daily_choice_widgets.dart';

part 'daily_choice_eat_module.dart';
part 'daily_choice_modules.dart';
part 'daily_choice_wear_module.dart';
part 'daily_choice_decision_assistant.dart';

class DailyChoiceHubWeatherState {
  const DailyChoiceHubWeatherState({
    required this.weatherEnabled,
    required this.weatherLoading,
    this.weatherSnapshot,
  });

  final bool weatherEnabled;
  final bool weatherLoading;
  final WeatherSnapshot? weatherSnapshot;
}

class DailyChoiceHub extends ConsumerStatefulWidget {
  const DailyChoiceHub({
    super.key,
    this.storage,
    this.cookService,
    this.eatLibraryStore,
    this.weatherStateOverride,
  });

  final DailyChoiceStorageService? storage;
  final DailyChoiceCookService? cookService;
  final DailyChoiceEatLibraryStore? eatLibraryStore;
  final DailyChoiceHubWeatherState? weatherStateOverride;

  @override
  ConsumerState<DailyChoiceHub> createState() => _DailyChoiceHubState();
}

class _DailyChoiceHubState extends ConsumerState<DailyChoiceHub> {
  late final DailyChoiceStorageService _storage =
      widget.storage ?? const DailyChoiceStorageService();
  late final DailyChoiceCookService _cookService =
      widget.cookService ?? DailyChoiceCookService();
  late final DailyChoiceEatLibraryStore _eatLibraryStore =
      widget.eatLibraryStore ??
      DailyChoiceEatLibraryStore(cookService: _cookService);
  late final bool _ownsEatLibraryStore = widget.eatLibraryStore == null;
  late final List<DailyChoiceOption> _staticSeedOptions =
      buildDailyChoiceStaticSeedOptions();
  DailyChoiceCustomState _customState = DailyChoiceCustomState.empty;
  DailyChoiceEatLibraryStatus _eatLibraryStatus =
      const DailyChoiceEatLibraryStatus.empty();
  List<DailyChoiceOption> _eatRawBuiltInOptions = const <DailyChoiceOption>[];
  List<DailyChoiceOption> _eatBuiltInOptions = const <DailyChoiceOption>[];
  List<DailyChoiceOption> _eatVisibleOptions = const <DailyChoiceOption>[];
  late DailyChoiceEatCatalog _eatCatalog = DailyChoiceEatCatalog.fromOptions(
    _eatVisibleOptions,
  );
  String _selectedModuleId = 'eat';
  bool _customStateLoaded = false;
  bool _eatLibraryLoaded = false;
  bool _eatLibraryLoading = false;
  bool _eatLibraryInstalling = false;

  late final DailyChoiceWearLibraryStore _wearLibraryStore =
      DailyChoiceWearLibraryStore();
  DailyChoiceWearLibraryStatus _wearLibraryStatus =
      const DailyChoiceWearLibraryStatus.empty();
  List<DailyChoiceOption> _wearRawBuiltInOptions = const <DailyChoiceOption>[];
  List<DailyChoiceOption> _wearBuiltInOptions = const <DailyChoiceOption>[];
  bool _wearLibraryLoaded = false;
  bool _wearLibraryLoading = false;
  bool _wearLibraryInstalling = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_selectedModuleId == DailyChoiceModuleId.eat.storageValue) {
        unawaited(_ensureEatLibraryLoaded());
      } else if (_selectedModuleId == DailyChoiceModuleId.wear.storageValue) {
        _refreshWeatherForWearIfNeeded();
        unawaited(_ensureWearLibraryLoaded());
      }
    });
  }

  Future<void> _initialize() async {
    await _loadCustomState();
  }

  void _refreshWeatherForWearIfNeeded() {
    if (widget.weatherStateOverride != null) {
      return;
    }
    final appState = ref.read(appStateProvider);
    if (appState.weatherEnabled) {
      appState.refreshWeatherIfStale();
    }
  }

  Future<void> _loadCustomState() async {
    final loaded = (await _storage.load())
        .withDefaultEatCollections()
        .withDefaultWearCollections();
    if (!mounted) {
      return;
    }
    setState(() {
      _customState = loaded;
      _rebuildEatState(customState: loaded);
      _customStateLoaded = true;
    });
  }

  Future<void> _ensureEatLibraryLoaded() async {
    if (_eatLibraryLoaded || _eatLibraryLoading || _eatLibraryInstalling) {
      return;
    }
    if (mounted) {
      setState(() {
        _eatLibraryLoading = true;
      });
    }
    try {
      final status = await _eatLibraryStore.inspectStatus();
      if (!mounted) {
        return;
      }
      setState(() {
        _eatLibraryStatus = status;
      });
      final builtInOptions = status.hasInstalledLibrary
          ? await _eatLibraryStore.loadBuiltInSummaries()
          : const <DailyChoiceOption>[];
      if (!mounted) {
        return;
      }
      setState(() {
        _eatLibraryStatus = status;
        _rebuildEatState(builtInOptions: builtInOptions);
        _eatLibraryLoaded = true;
        _eatLibraryLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _eatLibraryStatus = DailyChoiceEatLibraryStatus(
          hasInstalledLibrary: false,
          errorMessage: '$error',
        );
        _rebuildEatState(builtInOptions: const <DailyChoiceOption>[]);
        _eatLibraryLoaded = true;
        _eatLibraryLoading = false;
      });
    }
  }

  Future<void> _installEatLibrary() async {
    if (_eatLibraryInstalling || _eatLibraryLoading) {
      return;
    }
    setState(() {
      _eatLibraryInstalling = true;
      _eatLibraryLoaded = false;
    });
    try {
      final status = await _eatLibraryStore.installLibrary();
      final builtInOptions = await _eatLibraryStore.loadBuiltInSummaries();
      if (!mounted) {
        return;
      }
      setState(() {
        _eatLibraryStatus = status;
        _rebuildEatState(builtInOptions: builtInOptions);
        _eatLibraryLoaded = true;
        _eatLibraryInstalling = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _eatLibraryStatus = _eatLibraryStatus.copyWith(errorMessage: '$error');
        _eatLibraryLoaded = true;
        _eatLibraryInstalling = false;
      });
    }
  }

  Future<void> _ensureWearLibraryLoaded() async {
    if (_wearLibraryLoaded || _wearLibraryLoading || _wearLibraryInstalling) {
      return;
    }
    if (mounted) {
      setState(() {
        _wearLibraryLoading = true;
      });
    }
    try {
      final status = await _wearLibraryStore.inspectStatus();
      if (!mounted) {
        return;
      }
      final builtInOptions = status.hasInstalledLibrary
          ? await _wearLibraryStore.loadBuiltInSummaries()
          : const <DailyChoiceOption>[];
      if (!mounted) {
        return;
      }
      setState(() {
        _wearLibraryStatus = status;
        _rebuildWearState(builtInOptions: builtInOptions);
        _wearLibraryLoaded = true;
        _wearLibraryLoading = false;
      });
      if (builtInOptions.isNotEmpty) {
        final nextState = _populateBuiltInWearCollections(
          _customState,
          builtInOptions,
        );
        if (nextState != null && mounted) {
          _setCustomState(nextState);
        }
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _wearLibraryStatus = DailyChoiceWearLibraryStatus(
          hasInstalledLibrary: false,
          errorMessage: '$error',
        );
        _rebuildWearState(builtInOptions: const <DailyChoiceOption>[]);
        _wearLibraryLoaded = true;
        _wearLibraryLoading = false;
      });
    }
  }

  DailyChoiceCustomState? _populateBuiltInWearCollections(
    DailyChoiceCustomState currentState,
    List<DailyChoiceOption> builtInOptions,
  ) {
    var next = currentState;
    var anyChanged = false;
    for (final builtIn in wearBuiltInCollections) {
      final sceneId = sceneByBuiltInWearCollectionId[builtIn.id];
      if (sceneId == null) {
        continue;
      }
      final existing = next.wearCollectionById(builtIn.id);
      final optionIds = builtInOptions
          .where((item) => _matchesWearScene(item, sceneId))
          .map((item) => item.id)
          .toList(growable: false);
      if (existing == null) {
        next = next.upsertWearCollection(
          builtIn.copyWith(optionIds: optionIds),
        );
        anyChanged = true;
      } else if (!_sameStringList(existing.optionIds, optionIds)) {
        next = next.upsertWearCollection(
          existing.copyWith(
            titleZh: builtIn.titleZh,
            titleEn: builtIn.titleEn,
            optionIds: optionIds,
          ),
        );
        anyChanged = true;
      } else if (existing.titleZh != builtIn.titleZh ||
          existing.titleEn != builtIn.titleEn) {
        next = next.upsertWearCollection(
          existing.copyWith(titleZh: builtIn.titleZh, titleEn: builtIn.titleEn),
        );
        anyChanged = true;
      }
    }
    return anyChanged ? next : null;
  }

  Future<void> _installWearLibrary() async {
    if (_wearLibraryInstalling || _wearLibraryLoading) {
      return;
    }
    setState(() {
      _wearLibraryInstalling = true;
      _wearLibraryLoaded = false;
    });
    try {
      final status = await _wearLibraryStore.installLibrary();
      final builtInOptions = await _wearLibraryStore.loadBuiltInSummaries();
      if (!mounted) {
        return;
      }
      setState(() {
        _wearLibraryStatus = status;
        _rebuildWearState(builtInOptions: builtInOptions);
        _wearLibraryLoaded = true;
        _wearLibraryInstalling = false;
      });
      if (builtInOptions.isNotEmpty) {
        final nextState = _populateBuiltInWearCollections(
          _customState,
          builtInOptions,
        );
        if (nextState != null && mounted) {
          _setCustomState(nextState);
        }
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _wearLibraryStatus = _wearLibraryStatus.copyWith(
          errorMessage: '$error',
        );
        _wearLibraryLoaded = true;
        _wearLibraryInstalling = false;
      });
    }
  }

  void _setCustomState(DailyChoiceCustomState next) {
    final normalizedNext = next
        .withDefaultEatCollections()
        .withDefaultWearCollections();
    final shouldRebuildEatState = !_sameEatCatalogInputs(
      _customState,
      normalizedNext,
    );
    final shouldRebuildWearState = !_sameWearCatalogInputs(
      _customState,
      normalizedNext,
    );
    setState(() {
      _customState = normalizedNext;
      if (shouldRebuildEatState) {
        _rebuildEatState(customState: normalizedNext);
      }
      if (shouldRebuildWearState) {
        _rebuildWearState(customState: normalizedNext);
      }
    });
    unawaited(_storage.save(normalizedNext));
  }

  List<DailyChoiceOption> _builtInFor(String moduleId) {
    if (moduleId == DailyChoiceModuleId.eat.storageValue) {
      return _eatBuiltInOptions;
    }
    if (moduleId == DailyChoiceModuleId.wear.storageValue) {
      return _wearBuiltInOptions;
    }
    return _staticSeedOptions
        .where((item) => item.moduleId == moduleId)
        .toList(growable: false);
  }

  List<DailyChoiceOption> _optionsFor(String moduleId) {
    if (moduleId == DailyChoiceModuleId.eat.storageValue) {
      return _eatVisibleOptions;
    }
    final hidden = _customState.hiddenBuiltInIds;
    final builtIns = _builtInFor(moduleId);
    return <DailyChoiceOption>[
      ...builtIns.where((item) => !hidden.contains(item.id)),
      ..._customState.customOptions.where((item) => item.moduleId == moduleId),
    ];
  }

  void _rebuildEatState({
    List<DailyChoiceOption>? builtInOptions,
    DailyChoiceCustomState? customState,
  }) {
    final resolvedCustomState = customState ?? _customState;
    _eatRawBuiltInOptions = builtInOptions ?? _eatRawBuiltInOptions;
    _eatBuiltInOptions = _applyBuiltInAdjustments(
      _eatRawBuiltInOptions,
      resolvedCustomState,
    );
    _eatVisibleOptions = _buildEatVisibleOptions(
      _eatBuiltInOptions,
      resolvedCustomState,
    );
    _eatCatalog = DailyChoiceEatCatalog.fromOptions(_eatVisibleOptions);
  }

  List<DailyChoiceOption> _applyBuiltInAdjustments(
    List<DailyChoiceOption> builtInOptions,
    DailyChoiceCustomState customState,
  ) {
    if (customState.adjustedBuiltInOptions.isEmpty) {
      return List<DailyChoiceOption>.unmodifiable(builtInOptions);
    }
    final adjustedById = <String, DailyChoiceOption>{
      for (final item in customState.adjustedBuiltInOptions.where(
        (item) => item.moduleId == DailyChoiceModuleId.eat.storageValue,
      ))
        item.id: item,
    };
    return List<DailyChoiceOption>.unmodifiable(
      builtInOptions.map((item) {
        final adjusted = adjustedById[item.id];
        return adjusted == null ? item : ensureEatOptionAttributes(adjusted);
      }),
    );
  }

  List<DailyChoiceOption> _buildEatVisibleOptions(
    List<DailyChoiceOption> builtInOptions,
    DailyChoiceCustomState customState,
  ) {
    final hidden = customState.hiddenBuiltInIds;
    return List<DailyChoiceOption>.unmodifiable(<DailyChoiceOption>[
      ...builtInOptions.where((item) => !hidden.contains(item.id)),
      ...customState.customOptions
          .where(
            (item) => item.moduleId == DailyChoiceModuleId.eat.storageValue,
          )
          .map(ensureEatOptionAttributes),
    ]);
  }

  void _rebuildWearState({
    List<DailyChoiceOption>? builtInOptions,
    DailyChoiceCustomState? customState,
  }) {
    final resolvedCustomState = customState ?? _customState;
    _wearRawBuiltInOptions = builtInOptions ?? _wearRawBuiltInOptions;
    _wearBuiltInOptions = _applyWearBuiltInAdjustments(
      _wearRawBuiltInOptions,
      resolvedCustomState,
    );
  }

  List<DailyChoiceOption> _applyWearBuiltInAdjustments(
    List<DailyChoiceOption> builtInOptions,
    DailyChoiceCustomState customState,
  ) {
    if (customState.adjustedBuiltInOptions.isEmpty) {
      return List<DailyChoiceOption>.unmodifiable(builtInOptions);
    }
    final adjustedById = <String, DailyChoiceOption>{
      for (final item in customState.adjustedBuiltInOptions.where(
        (item) => item.moduleId == DailyChoiceModuleId.wear.storageValue,
      ))
        item.id: item,
    };
    if (adjustedById.isEmpty) {
      return List<DailyChoiceOption>.unmodifiable(builtInOptions);
    }
    return List<DailyChoiceOption>.unmodifiable(
      builtInOptions.map((item) => adjustedById[item.id] ?? item),
    );
  }

  Future<DailyChoiceOption?> _resolveWearDetail(
    DailyChoiceOption option,
  ) async {
    if (option.detailsZh.isNotEmpty || option.materialsZh.isNotEmpty) {
      return option;
    }
    if (!_wearLibraryStatus.hasInstalledLibrary) {
      return null;
    }
    return _wearLibraryStore.loadBuiltInDetail(option.id);
  }

  Future<DailyChoiceOption?> _openWearAdjustmentEditor(
    DailyChoiceOption option,
  ) async {
    final detail = await _resolveWearDetail(option);
    if (detail == null) {
      return null;
    }
    if (!mounted) {
      return null;
    }
    final result = await showDailyChoiceEditorSheet(
      context: context,
      i18n: AppI18n(Localizations.localeOf(context).languageCode),
      accent: dailyChoiceModuleConfigs
          .firstWhere((item) => item.id == 'wear')
          .accent,
      moduleId: 'wear',
      categories: temperatureCategories,
      initialCategoryId: detail.categoryId,
      contexts: wearSceneCategories,
      initialContextId: detail.contextId,
      option: detail,
    );
    return result?.option;
  }

  Future<DailyChoiceEditorResult?> _openWearSaveAsCustomEditor(
    DailyChoiceOption option, {
    required List<DailyChoiceEatCollection> eatCollections,
    required Set<String> initialEatCollectionIds,
    required List<DailyChoiceWearCollection> wearCollections,
    required Set<String> initialWearCollectionIds,
  }) async {
    final detail = await _resolveWearDetail(option);
    if (detail == null) {
      return null;
    }
    if (!mounted) {
      return null;
    }
    return showDailyChoiceEditorSheet(
      context: context,
      i18n: AppI18n(Localizations.localeOf(context).languageCode),
      accent: dailyChoiceModuleConfigs
          .firstWhere((item) => item.id == 'wear')
          .accent,
      moduleId: 'wear',
      categories: temperatureCategories,
      initialCategoryId: detail.categoryId,
      contexts: wearSceneCategories,
      initialContextId: detail.contextId,
      option: detail,
      forceNewId: true,
      wearCollections: wearCollections,
      initialWearCollectionIds: initialWearCollectionIds,
    );
  }

  Future<void> _openWearInspectOption(DailyChoiceOption option) async {
    final detail = await _resolveWearDetail(option);
    if (detail == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    await showDailyChoiceDetailSheet(
      context: context,
      i18n: AppI18n(Localizations.localeOf(context).languageCode),
      accent: dailyChoiceModuleConfigs
          .firstWhere((item) => item.id == 'wear')
          .accent,
      option: detail,
    );
  }

  @override
  void dispose() {
    if (_ownsEatLibraryStore) {
      unawaited(_eatLibraryStore.close());
    }
    unawaited(_wearLibraryStore.close());
    super.dispose();
  }

  DailyChoiceModuleConfig get _selectedModule {
    return dailyChoiceModuleConfigs.firstWhere(
      (item) => item.id == _selectedModuleId,
      orElse: () => dailyChoiceModuleConfigs.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final weatherState = widget.weatherStateOverride;
    final appState = weatherState == null ? ref.watch(appStateProvider) : null;
    final module = _selectedModule;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DailyChoiceModuleSwitcher(
          i18n: i18n,
          modules: dailyChoiceModuleConfigs,
          selectedId: _selectedModuleId,
          onSelected: (value) {
            setState(() {
              _selectedModuleId = value;
            });
            if (value == DailyChoiceModuleId.eat.storageValue) {
              unawaited(_ensureEatLibraryLoaded());
            } else if (value == DailyChoiceModuleId.wear.storageValue) {
              _refreshWeatherForWearIfNeeded();
              unawaited(_ensureWearLibraryLoaded());
            }
          },
        ),
        const SizedBox(height: ToolboxUiTokens.sectionSpacing),
        if (!_customStateLoaded)
          LinearProgressIndicator(color: module.accent)
        else
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: _buildSelectedModule(
              i18n,
              module,
              weatherEnabled:
                  weatherState?.weatherEnabled ?? appState!.weatherEnabled,
              weatherLoading:
                  weatherState?.weatherLoading ?? appState!.weatherLoading,
              weatherSnapshot:
                  weatherState?.weatherSnapshot ?? appState!.weatherSnapshot,
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedModule(
    AppI18n i18n,
    DailyChoiceModuleConfig module, {
    required bool weatherEnabled,
    required bool weatherLoading,
    required WeatherSnapshot? weatherSnapshot,
  }) {
    return switch (_selectedModuleId) {
      'eat' => _EatChoiceModule(
        key: const ValueKey<String>('eat'),
        i18n: i18n,
        accent: module.accent,
        libraryStore: _eatLibraryStore,
        libraryStatus: _eatLibraryStatus,
        libraryLoading: _eatLibraryLoading,
        libraryInstalling: _eatLibraryInstalling,
        onInstallLibrary: _installEatLibrary,
        catalog: _eatCatalog,
        rawBuiltInOptions: _eatRawBuiltInOptions,
        builtInOptions: _builtInFor('eat'),
        customState: _customState,
        onStateChanged: _setCustomState,
      ),
      'wear' => _WearChoiceModule(
        key: const ValueKey<String>('wear'),
        i18n: i18n,
        accent: module.accent,
        options: _optionsFor('wear'),
        builtInOptions: _builtInFor('wear'),
        customState: _customState,
        onStateChanged: _setCustomState,
        weatherEnabled: weatherEnabled,
        weatherLoading: weatherLoading,
        weatherSnapshot: weatherSnapshot,
        libraryStatus: _wearLibraryStatus,
        libraryLoading: _wearLibraryLoading,
        libraryInstalling: _wearLibraryInstalling,
        onInstallLibrary: _installWearLibrary,
        wearCollections: _customState.wearCollections,
        onInspectOption: _openWearInspectOption,
        onAdjustBuiltInOption: _openWearAdjustmentEditor,
        onSaveBuiltInAsCustom: _openWearSaveAsCustomEditor,
      ),
      'go' => _PlaceChoiceModule(
        key: const ValueKey<String>('go'),
        i18n: i18n,
        accent: module.accent,
        options: _optionsFor('go'),
        builtInOptions: _builtInFor('go'),
        customState: _customState,
        onStateChanged: _setCustomState,
      ),
      'activity' => _ActivityChoiceModule(
        key: const ValueKey<String>('activity'),
        i18n: i18n,
        accent: module.accent,
        options: _optionsFor('activity'),
        builtInOptions: _builtInFor('activity'),
        customState: _customState,
        onStateChanged: _setCustomState,
      ),
      _ => _DecisionAssistantModule(
        key: const ValueKey<String>('assistant'),
        i18n: i18n,
        accent: module.accent,
      ),
    };
  }
}

bool _sameEatCatalogInputs(
  DailyChoiceCustomState previous,
  DailyChoiceCustomState next,
) {
  return identical(previous.hiddenBuiltInIds, next.hiddenBuiltInIds) &&
      identical(previous.customOptions, next.customOptions) &&
      identical(previous.adjustedBuiltInOptions, next.adjustedBuiltInOptions);
}

bool _sameWearCatalogInputs(
  DailyChoiceCustomState previous,
  DailyChoiceCustomState next,
) {
  return identical(
    previous.adjustedBuiltInOptions,
    next.adjustedBuiltInOptions,
  );
}

bool _sameStringList(List<String> a, List<String> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  final setA = a.toSet();
  final setB = b.toSet();
  if (setA.length != setB.length) {
    return false;
  }
  return setA.containsAll(setB);
}

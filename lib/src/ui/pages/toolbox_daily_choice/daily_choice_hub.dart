import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../i18n/app_i18n.dart';
import '../../../models/weather_snapshot.dart';
import '../../../state/app_state_provider.dart';
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
  bool _eatLibraryInstalling = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await Future.wait(<Future<void>>[
      _loadCustomState(),
      _initializeEatLibrary(),
    ]);
  }

  Future<void> _loadCustomState() async {
    final loaded = await _storage.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _customState = loaded;
      _rebuildEatState(customState: loaded);
      _customStateLoaded = true;
    });
  }

  Future<void> _initializeEatLibrary() async {
    try {
      final status = await _eatLibraryStore.inspectStatus();
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
      });
    }
  }

  Future<void> _installEatLibrary() async {
    if (_eatLibraryInstalling) {
      return;
    }
    setState(() {
      _eatLibraryInstalling = true;
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

  void _setCustomState(DailyChoiceCustomState next) {
    final shouldRebuildEatState = !_sameEatCatalogInputs(_customState, next);
    setState(() {
      _customState = next;
      if (shouldRebuildEatState) {
        _rebuildEatState(customState: next);
      }
    });
    unawaited(_storage.save(next));
  }

  List<DailyChoiceOption> _builtInFor(String moduleId) {
    if (moduleId == DailyChoiceModuleId.eat.storageValue) {
      return _eatBuiltInOptions;
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
      for (final item in customState.adjustedBuiltInOptions) item.id: item,
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

  @override
  void dispose() {
    if (_ownsEatLibraryStore) {
      unawaited(_eatLibraryStore.close());
    }
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
          },
        ),
        const SizedBox(height: ToolboxUiTokens.sectionSpacing),
        if (!_customStateLoaded || !_eatLibraryLoaded)
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

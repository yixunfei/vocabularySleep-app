part of 'daily_choice_hub.dart';

class _WearChoiceModule extends StatefulWidget {
  const _WearChoiceModule({
    super.key,
    required this.i18n,
    required this.accent,
    required this.options,
    required this.builtInOptions,
    required this.customState,
    required this.onStateChanged,
    required this.weatherEnabled,
    required this.weatherLoading,
    required this.weatherSnapshot,
  });
  final AppI18n i18n;
  final Color accent;
  final List<DailyChoiceOption> options;
  final List<DailyChoiceOption> builtInOptions;
  final DailyChoiceCustomState customState;
  final ValueChanged<DailyChoiceCustomState> onStateChanged;
  final bool weatherEnabled;
  final bool weatherLoading;
  final WeatherSnapshot? weatherSnapshot;
  @override
  State<_WearChoiceModule> createState() => _WearChoiceModuleState();
}

class _WearChoiceModuleState extends State<_WearChoiceModule> {
  String _temperatureId = 'mild';
  String _sceneId = 'commute';
  bool _temperatureManuallyEdited = false;
  _WearWeatherSuggestion? _weatherSuggestion;

  @override
  void initState() {
    super.initState();
    _syncWeatherSuggestion(initial: true);
  }

  @override
  void didUpdateWidget(covariant _WearChoiceModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weatherEnabled != widget.weatherEnabled ||
        oldWidget.weatherLoading != widget.weatherLoading ||
        oldWidget.weatherSnapshot != widget.weatherSnapshot) {
      _syncWeatherSuggestion();
    }
  }

  void _syncWeatherSuggestion({bool initial = false}) {
    final next = _buildWearWeatherSuggestion(widget.weatherSnapshot);
    final previousSuggestedId = _weatherSuggestion?.temperatureId;
    if (initial) {
      _weatherSuggestion = next;
      if (next != null) {
        _temperatureId = next.temperatureId;
      }
      return;
    }
    final shouldApplySuggested =
        next != null &&
        (!_temperatureManuallyEdited || _temperatureId == previousSuggestedId);
    setState(() {
      _weatherSuggestion = next;
      if (next == null) {
        return;
      }
      if (shouldApplySuggested) {
        _temperatureId = next.temperatureId;
        _temperatureManuallyEdited = false;
      } else if (_temperatureId == next.temperatureId) {
        _temperatureManuallyEdited = false;
      }
    });
  }

  void _handleTemperatureSelected(String value) {
    setState(() {
      _temperatureId = value;
      _temperatureManuallyEdited =
          _weatherSuggestion == null ||
          value != _weatherSuggestion!.temperatureId;
    });
  }

  void _restoreWeatherSuggestion() {
    final suggestion = _weatherSuggestion;
    if (suggestion == null) {
      return;
    }
    setState(() {
      _temperatureId = suggestion.temperatureId;
      _temperatureManuallyEdited = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final exact = widget.options
        .where(
          (item) =>
              item.categoryId == _temperatureId && item.contextId == _sceneId,
        )
        .toList(growable: false);
    final sameTemp = widget.options
        .where((item) => item.categoryId == _temperatureId)
        .toList(growable: false);
    final filtered = switch (exact.length) {
      >= 2 => exact,
      1 => <DailyChoiceOption>[
        ...exact,
        ...sameTemp.where((item) => item.contextId != _sceneId),
      ],
      _ => sameTemp,
    };
    final temperature = temperatureCategories.firstWhere(
      (item) => item.id == _temperatureId,
    );
    final scene = wearSceneCategories.firstWhere((item) => item.id == _sceneId);
    final suggestion = _weatherSuggestion;
    final usingWeatherSuggestion =
        suggestion != null &&
        _temperatureId == suggestion.temperatureId &&
        !_temperatureManuallyEdited;
    final showRainShortcut =
        suggestion != null && suggestion.suggestRainScene && _sceneId != 'rain';
    final panelSubtitle = exact.isEmpty && sameTemp.isNotEmpty
        ? pickUiText(
            widget.i18n,
            zh: '当前场景暂无精确项，先从同温度搭配里随机。',
            en: 'No exact scene match yet; randomizing from the same temperature.',
          )
        : (exact.length == 1 && sameTemp.length > 1
              ? pickUiText(
                  widget.i18n,
                  zh: '当前场景条目较少，已混入同温度稳妥备选，让随机更有变化。',
                  en: 'This scene has only one exact match, so same-temperature backups are mixed in for more variety.',
                )
              : (_temperatureManuallyEdited && suggestion != null
                    ? pickUiText(
                        widget.i18n,
                        zh: '当前为手动选择：${temperature.titleZh}。天气默认建议是 ${_wearTemperatureCategory(suggestion.temperatureId).titleZh}。',
                        en: 'Manual selection: ${temperature.titleEn}. Weather suggests ${_wearTemperatureCategory(suggestion.temperatureId).titleEn}.',
                      )
                    : scene.subtitle(widget.i18n)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _WearWeatherPanel(
          i18n: widget.i18n,
          accent: widget.accent,
          weatherEnabled: widget.weatherEnabled,
          weatherLoading: widget.weatherLoading,
          suggestion: suggestion,
          usingSuggestedTemperature: usingWeatherSuggestion,
          onRestoreSuggestedTemperature: _restoreWeatherSuggestion,
          onSwitchToRainScene: showRainShortcut
              ? () => setState(() => _sceneId = 'rain')
              : null,
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        DailyChoiceCategorySelector(
          i18n: widget.i18n,
          title: pickUiText(widget.i18n, zh: '选择气温', en: 'Temperature'),
          categories: temperatureCategories,
          selectedId: _temperatureId,
          accent: widget.accent,
          compactUnselected: true,
          onSelected: _handleTemperatureSelected,
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        DailyChoiceCategorySelector(
          i18n: widget.i18n,
          title: pickUiText(widget.i18n, zh: '选择场景', en: 'Scene'),
          categories: wearSceneCategories,
          selectedId: _sceneId,
          accent: widget.accent,
          compactUnselected: true,
          onSelected: (value) => setState(() => _sceneId = value),
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        DailyChoiceRandomPanel(
          i18n: widget.i18n,
          accent: widget.accent,
          title: pickUiText(
            widget.i18n,
            zh: '${temperature.titleZh} · ${scene.titleZh}',
            en: '${temperature.titleEn} · ${scene.titleEn}',
          ),
          subtitle: panelSubtitle,
          options: filtered,
          emptyText: pickUiText(
            widget.i18n,
            zh: '这个温度还没有穿搭，可以在管理里新增自己的衣橱搭配。',
            en: 'No outfits for this temperature yet. Add your wardrobe version in Manage.',
          ),
          onDetail: (option) => showDailyChoiceDetailSheet(
            context: context,
            i18n: widget.i18n,
            accent: widget.accent,
            option: option,
          ),
          onGuide: () => showDailyChoiceGuideSheet(
            context: context,
            i18n: widget.i18n,
            accent: widget.accent,
            title: pickUiText(widget.i18n, zh: '穿搭指南与衣橱方法', en: 'Outfit guide'),
            modules: wearGuideModules,
          ),
          onManage: () => showDailyChoiceManagerSheet(
            context: context,
            i18n: widget.i18n,
            accent: widget.accent,
            moduleId: 'wear',
            builtInOptions: widget.builtInOptions,
            state: widget.customState,
            onStateChanged: widget.onStateChanged,
            categories: temperatureCategories,
            initialCategoryId: _temperatureId,
            contexts: wearSceneCategories,
            initialContextId: _sceneId,
          ),
        ),
      ],
    );
  }
}

class _WearWeatherPanel extends StatelessWidget {
  const _WearWeatherPanel({
    required this.i18n,
    required this.accent,
    required this.weatherEnabled,
    required this.weatherLoading,
    required this.suggestion,
    required this.usingSuggestedTemperature,
    required this.onRestoreSuggestedTemperature,
    required this.onSwitchToRainScene,
  });

  final AppI18n i18n;
  final Color accent;
  final bool weatherEnabled;
  final bool weatherLoading;
  final _WearWeatherSuggestion? suggestion;
  final bool usingSuggestedTemperature;
  final VoidCallback onRestoreSuggestedTemperature;
  final VoidCallback? onSwitchToRainScene;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestion = this.suggestion;
    if (!weatherEnabled || suggestion == null) {
      return ToolboxSurfaceCard(
        padding: const EdgeInsets.all(16),
        radius: ToolboxUiTokens.sectionPanelRadius,
        borderColor: accent.withValues(alpha: 0.18),
        shadowColor: accent,
        shadowOpacity: 0.04,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              weatherLoading ? Icons.cloud_sync_rounded : Icons.tune_rounded,
              color: accent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickUiText(i18n, zh: '天气建议', en: 'Weather suggestion'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weatherLoading
                        ? pickUiText(
                            i18n,
                            zh: '正在读取当前天气，读取完成后会默认推荐合适的气温档位。',
                            en: 'Loading weather. A suitable temperature band will be selected by default when ready.',
                          )
                        : pickUiText(
                            i18n,
                            zh: weatherEnabled
                                ? '暂时没有可用天气数据，先默认从“温和”开始，你也可以手动改档位。'
                                : '天气接口当前未启用，先默认从“温和”开始，你也可以手动改档位。',
                            en: weatherEnabled
                                ? 'Weather is unavailable right now, so the module starts from Mild and you can adjust it manually.'
                                : 'Weather is disabled right now, so the module starts from Mild and you can adjust it manually.',
                          ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final snapshot = suggestion.snapshot;
    final weatherLabel = weatherCodeLabel(
      i18n,
      snapshot.weatherCode,
      isDay: snapshot.isDay,
    );
    final recommendedTemperature = _wearTemperatureCategory(
      suggestion.temperatureId,
    );
    final notes = suggestion.notes(i18n);
    final highLow =
        snapshot.todayMaxTemperatureCelsius != null &&
            snapshot.todayMinTemperatureCelsius != null
        ? '${snapshot.todayMinTemperatureCelsius!.round()}°C ~ ${snapshot.todayMaxTemperatureCelsius!.round()}°C'
        : pickUiText(i18n, zh: '暂无高低温', en: 'No high-low yet');

    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(16),
      radius: ToolboxUiTokens.sectionPanelRadius,
      borderColor: accent.withValues(alpha: 0.18),
      shadowColor: accent,
      shadowOpacity: 0.06,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  weatherCodeIcon(snapshot.weatherCode, isDay: snapshot.isDay),
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pickUiText(i18n, zh: '天气建议', en: 'Weather suggestion'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${snapshot.city} · $weatherLabel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (weatherLoading)
                ToolboxInfoPill(
                  text: pickUiText(i18n, zh: '更新中', en: 'Refreshing'),
                  accent: accent,
                  backgroundColor: theme.colorScheme.surfaceContainerLow,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxInfoPill(
                text: pickUiText(
                  i18n,
                  zh: '当前 ${snapshot.temperatureCelsius.round()}°C',
                  en: '${snapshot.temperatureCelsius.round()}°C now',
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: pickUiText(
                  i18n,
                  zh: '体感 ${snapshot.apparentTemperatureCelsius.round()}°C',
                  en: 'Feels ${snapshot.apparentTemperatureCelsius.round()}°C',
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: pickUiText(
                  i18n,
                  zh: '高低温 $highLow',
                  en: 'High-low $highLow',
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: pickUiText(
                  i18n,
                  zh: '推荐 ${recommendedTemperature.titleZh}',
                  en: 'Suggest ${recommendedTemperature.titleEn}',
                ),
                accent: accent,
                backgroundColor: usingSuggestedTemperature
                    ? accent.withValues(alpha: 0.14)
                    : theme.colorScheme.surfaceContainerLow,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            suggestion.summary(i18n),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.42),
          ),
          if (notes.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            for (final note in notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '• ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        note,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.4,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (!usingSuggestedTemperature ||
              onSwitchToRainScene != null) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                if (!usingSuggestedTemperature)
                  OutlinedButton.icon(
                    onPressed: onRestoreSuggestedTemperature,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      pickUiText(i18n, zh: '恢复天气推荐', en: 'Use suggestion'),
                    ),
                  ),
                if (onSwitchToRainScene != null)
                  OutlinedButton.icon(
                    onPressed: onSwitchToRainScene,
                    icon: const Icon(Icons.umbrella_rounded),
                    label: Text(
                      pickUiText(i18n, zh: '切到雨天场景', en: 'Switch to rain'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WearWeatherSuggestion {
  const _WearWeatherSuggestion({
    required this.snapshot,
    required this.temperatureId,
    required this.summaryZh,
    required this.summaryEn,
    required this.notesZh,
    required this.notesEn,
    required this.suggestRainScene,
  });

  final WeatherSnapshot snapshot;
  final String temperatureId;
  final String summaryZh;
  final String summaryEn;
  final List<String> notesZh;
  final List<String> notesEn;
  final bool suggestRainScene;

  String summary(AppI18n i18n) =>
      pickUiText(i18n, zh: summaryZh, en: summaryEn);

  List<String> notes(AppI18n i18n) {
    if (AppI18n.normalizeLanguageCode(i18n.languageCode) == 'zh') {
      return notesZh;
    }
    return notesEn.isEmpty ? notesZh : notesEn;
  }
}

_WearWeatherSuggestion? _buildWearWeatherSuggestion(WeatherSnapshot? snapshot) {
  if (snapshot == null) {
    return null;
  }
  final apparent = snapshot.apparentTemperatureCelsius;
  final temperatureId = _wearTemperatureIdFor(apparent);
  final recommended = _wearTemperatureCategory(temperatureId);
  final range =
      ((snapshot.todayMaxTemperatureCelsius ?? apparent) -
              (snapshot.todayMinTemperatureCelsius ?? apparent))
          .abs();
  final rainy = _wearWeatherCodesRain.contains(snapshot.weatherCode);
  final snowy = _wearWeatherCodesSnow.contains(snapshot.weatherCode);
  final windy = snapshot.windSpeedKph >= 24;
  final notesZh = <String>[];
  final notesEn = <String>[];
  if (range >= 8) {
    notesZh.add('今天温差 ${range.round()}°C，优先选可穿脱的外层。');
    notesEn.add(
      'The temperature swing is ${range.round()}°C today, so keep the outer layer easy to remove.',
    );
  }
  if (rainy) {
    notesZh.add('当前有降水，鞋底防滑、面料快干会更稳妥。');
    notesEn.add(
      'There is precipitation, so grippy soles and quick-dry fabrics are safer.',
    );
  }
  if (snowy) {
    notesZh.add('当前有降雪，保暖和抓地力要优先于轻薄造型。');
    notesEn.add(
      'Snow is expected, so warmth and traction matter more than light styling.',
    );
  }
  if (windy) {
    notesZh.add('风速约 ${snapshot.windSpeedKph.round()} km/h，尽量带一层防风外搭。');
    notesEn.add(
      'Wind is around ${snapshot.windSpeedKph.round()} km/h, so add a wind-blocking layer.',
    );
  }
  if (apparent >= 30) {
    notesZh.add('高温时段尽量减少暴晒，补水和防晒都别省。');
    notesEn.add(
      'During high heat, limit sun exposure and keep hydration plus sun protection in place.',
    );
  } else if (apparent <= 5) {
    notesZh.add('低温里别只顾上半身，颈部、手部和脚踝也要一起保暖。');
    notesEn.add(
      'In low temperatures, keep the neck, hands, and ankles warm too.',
    );
  }
  return _WearWeatherSuggestion(
    snapshot: snapshot,
    temperatureId: temperatureId,
    summaryZh: '根据当前体感 ${apparent.round()}°C，默认推荐“${recommended.titleZh}”档位。',
    summaryEn:
        'Based on a feels-like temperature of ${apparent.round()}°C, the default suggestion is ${recommended.titleEn}.',
    notesZh: notesZh,
    notesEn: notesEn,
    suggestRainScene: rainy,
  );
}

const Set<int> _wearWeatherCodesRain = <int>{
  51,
  53,
  55,
  56,
  57,
  61,
  63,
  65,
  66,
  67,
  80,
  81,
  82,
  95,
  96,
  99,
};

const Set<int> _wearWeatherCodesSnow = <int>{71, 73, 75, 77, 85, 86};

String _wearTemperatureIdFor(double feelsLikeCelsius) {
  if (feelsLikeCelsius < 0) {
    return 'freezing';
  }
  if (feelsLikeCelsius < 10) {
    return 'cold';
  }
  if (feelsLikeCelsius < 15) {
    return 'cool';
  }
  if (feelsLikeCelsius < 25) {
    return 'mild';
  }
  if (feelsLikeCelsius < 30) {
    return 'warm';
  }
  if (feelsLikeCelsius < 35) {
    return 'hot';
  }
  return 'extreme_hot';
}

DailyChoiceCategory _wearTemperatureCategory(String id) {
  return temperatureCategories.firstWhere(
    (item) => item.id == id,
    orElse: () => temperatureCategories.first,
  );
}
